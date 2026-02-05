#include "ExportManager.h"

#include "ExportController.h"
#include "ImagePipeline.h"
#include "WebSocketClient.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>
#include <QUrl>
#include <QQuickItem>

namespace {
constexpr int kRestartStatus = 4;

QString formatTimeText(const QDateTime& fromLocal, const QDateTime& toLocal)
{
    const bool isSameDay = fromLocal.date() == toLocal.date();
    const QString toFormat = isSameDay ? QStringLiteral("HH:mm:ss")
                                       : QStringLiteral("dd.MM.yyyy HH:mm:ss");
    return fromLocal.toString("dd.MM.yyyy HH:mm:ss") + QStringLiteral(" - ")
           + toLocal.toString(toFormat);
}

QDateTime parseIsoDateTime(const QString& value)
{
    if (value.isEmpty())
        return {};
    QDateTime parsed = QDateTime::fromString(value, Qt::ISODateWithMs);
    if (!parsed.isValid())
        parsed = QDateTime::fromString(value, Qt::ISODate);
    return parsed;
}
} // namespace

ExportManager::ExportManager(QObject* parent)
    : QObject(parent)
    , m_model(new ExportListModel(this))
{
    loadCache();
}

ExportListModel* ExportManager::activeExportsModel() const
{
    return m_model;
}

void ExportManager::startExport(const QString& cameraId,
                                const QDateTime& fromLocal,
                                const QDateTime& toLocal,
                                const QString& archiveId,
                                const QString& outputPath,
                                const QString& format,
                                int maxChunkDurationMinutes,
                                qint64 maxChunkFileSizeBytes,
                                bool exportPrimitives,
                                bool exportCameraInformation,
                                bool exportImagePipeline,
                                ImagePipeline* imagePipeline,
                                const QString& wsUrl)
{
    auto* client = new WebSocketClient(this);
    client->startWorkerThread();
    if (!wsUrl.isEmpty()) {
        client->setUrl(static_cast<QUrl>(wsUrl));
    }

    auto* controller = new ExportController(this);
    controller->setClient(client);
    controller->setImagePipeline(imagePipeline);
    controller->setMaxChunkDurationMinutes(maxChunkDurationMinutes);
    controller->setMaxChunkFileSizeBytes(maxChunkFileSizeBytes);
    controller->setExportPrimitives(exportPrimitives);
    controller->setExportCameraInformation(exportCameraInformation);
    controller->setExportImagePipeline(exportImagePipeline);

    const QString timeText = formatTimeText(fromLocal, toLocal);

    ExportListModel::Item item;
    item.controller = controller;
    item.client = client;
    item.cacheId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    item.path = outputPath;
    item.cameraName = cameraId;
    item.timeText = timeText;
    item.exportDate = QDate::currentDate().toString("dd.MM.yyyy");
    item.fromLocal = fromLocal;
    item.toLocal = toLocal;
    item.archiveId = archiveId;
    item.format = format;
    item.maxChunkDurationMinutes = maxChunkDurationMinutes;
    item.maxChunkFileSizeBytes = maxChunkFileSizeBytes;
    item.exportPrimitives = exportPrimitives;
    item.exportCameraInformation = exportCameraInformation;
    item.exportImagePipeline = exportImagePipeline;
    item.wsUrl = wsUrl;
    item.status = ExportController::Status::Uploading;
    item.progress = controller->exportProgress();
    item.preview = controller->firstFramePreview();
    item.sizeBytes = controller->exportedSizeBytes();

    m_model->addItem(item);

    attachControllerHandlers(controller, client);
    saveCache();
    startControllerExport(controller, cameraId, fromLocal, toLocal, archiveId, outputPath, format);
}

void ExportManager::restartExport(int index)
{
    if (!m_model || index < 0 || index >= m_model->rowCount())
        return;

    const auto* sourceItem = m_model->itemAt(index);
    if (!sourceItem)
        return;
    if (sourceItem->status != kRestartStatus)
        return;
    if (!sourceItem->fromLocal.isValid() || !sourceItem->toLocal.isValid())
        return;

    auto* client = new WebSocketClient(this);
    client->startWorkerThread();
    if (!sourceItem->wsUrl.isEmpty()) {
        client->setUrl(static_cast<QUrl>(sourceItem->wsUrl));
    }

    auto* controller = new ExportController(this);
    controller->setClient(client);
    controller->setMaxChunkDurationMinutes(sourceItem->maxChunkDurationMinutes);
    controller->setMaxChunkFileSizeBytes(sourceItem->maxChunkFileSizeBytes);
    controller->setExportPrimitives(sourceItem->exportPrimitives);
    controller->setExportCameraInformation(sourceItem->exportCameraInformation);
    controller->setExportImagePipeline(sourceItem->exportImagePipeline);

    ExportListModel::Item item = *sourceItem;
    item.controller = controller;
    item.client = client;
    item.exportDate = QDate::currentDate().toString("dd.MM.yyyy");
    item.status = ExportController::Status::Uploading;
    item.progress = controller->exportProgress();
    item.preview.clear();
    item.sizeBytes = 0;

    m_model->replaceItem(index, item);

    attachControllerHandlers(controller, client);
    saveCache();
    startControllerExport(controller,
                          item.cameraName,
                          item.fromLocal,
                          item.toLocal,
                          item.archiveId,
                          item.path,
                          item.format);
}

void ExportManager::removeExport(int index)
{
    if (!m_model || index < 0 || index >= m_model->rowCount())
        return;

    QModelIndex modelIndex = m_model->index(index, 0);
    auto controller = qobject_cast<ExportController*>(m_model->data(modelIndex, ExportListModel::ControllerRole).value<QObject*>());
    auto client = qobject_cast<WebSocketClient*>(m_model->data(modelIndex, ExportListModel::ClientRole).value<QObject*>());

    if (controller)
        controller->cancel();
    if (controller)
        controller->deleteLater();
    if (client)
        client->deleteLater();

    m_model->removeItem(index);
    saveCache();

}

void ExportManager::loadCache()
{
    const QString path = cachePath();
    if (path.isEmpty() || !QFileInfo::exists(path))
        return;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;

    const auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isArray())
        return;

    const QJsonArray entries = doc.array();
    for (const auto& value : entries) {
        if (!value.isObject())
            continue;
        const QJsonObject obj = value.toObject();
        ExportListModel::Item item;
        item.cacheId = obj.value(QStringLiteral("id")).toString();
        if (item.cacheId.isEmpty())
            item.cacheId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        item.path = obj.value(QStringLiteral("output_path")).toString();
        item.cameraName = obj.value(QStringLiteral("camera_id")).toString();
        item.timeText = obj.value(QStringLiteral("time_text")).toString();
        item.exportDate = obj.value(QStringLiteral("export_date")).toString();
        item.fromLocal = parseIsoDateTime(obj.value(QStringLiteral("from_local")).toString());
        item.toLocal = parseIsoDateTime(obj.value(QStringLiteral("to_local")).toString());
        item.archiveId = obj.value(QStringLiteral("archive_id")).toString();
        item.format = obj.value(QStringLiteral("format")).toString();
        item.maxChunkDurationMinutes = obj.value(QStringLiteral("max_chunk_duration_minutes")).toInt();
        item.maxChunkFileSizeBytes = static_cast<qint64>(obj.value(QStringLiteral("max_chunk_file_size_bytes")).toDouble());
        item.exportPrimitives = obj.value(QStringLiteral("export_primitives")).toBool();
        item.exportCameraInformation = obj.value(QStringLiteral("export_camera_information")).toBool();
        item.exportImagePipeline = obj.value(QStringLiteral("export_image_pipeline")).toBool();
        item.wsUrl = obj.value(QStringLiteral("ws_url")).toString();
        item.status = obj.value(QStringLiteral("status")).toInt();
        if (item.status == static_cast<int>(ExportController::Status::Uploading) ||
            item.status == kRestartStatus) {
            item.status = kRestartStatus;
        }
        item.progress = obj.value(QStringLiteral("progress")).toInt();
        item.preview = obj.value(QStringLiteral("preview")).toString();
        item.sizeBytes = static_cast<qint64>(obj.value(QStringLiteral("size_bytes")).toDouble());
        if (item.timeText.isEmpty() && item.fromLocal.isValid() && item.toLocal.isValid()) {
            item.timeText = formatTimeText(item.fromLocal, item.toLocal);
        }
        if (item.exportDate.isEmpty()) {
            item.exportDate = QDate::currentDate().toString("dd.MM.yyyy");
        }
        m_model->appendItem(item);
    }
}

void ExportManager::saveCache() const
{
    const QString path = cachePath();
    if (path.isEmpty())
        return;

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;

    QJsonArray entries;
    const auto items = m_model->items();
    for (const auto& item : items) {
        QJsonObject obj;
        obj.insert(QStringLiteral("id"), item.cacheId);
        obj.insert(QStringLiteral("camera_id"), item.cameraName);
        obj.insert(QStringLiteral("archive_id"), item.archiveId);
        obj.insert(QStringLiteral("output_path"), item.path);
        obj.insert(QStringLiteral("format"), item.format);
        obj.insert(QStringLiteral("from_local"), item.fromLocal.toString(Qt::ISODateWithMs));
        obj.insert(QStringLiteral("to_local"), item.toLocal.toString(Qt::ISODateWithMs));
        obj.insert(QStringLiteral("time_text"), item.timeText);
        obj.insert(QStringLiteral("export_date"), item.exportDate);
        obj.insert(QStringLiteral("max_chunk_duration_minutes"), item.maxChunkDurationMinutes);
        obj.insert(QStringLiteral("max_chunk_file_size_bytes"),
                   QJsonValue::fromVariant(item.maxChunkFileSizeBytes));
        obj.insert(QStringLiteral("export_primitives"), item.exportPrimitives);
        obj.insert(QStringLiteral("export_camera_information"), item.exportCameraInformation);
        obj.insert(QStringLiteral("export_image_pipeline"), item.exportImagePipeline);
        obj.insert(QStringLiteral("ws_url"), item.wsUrl);

        const auto controller = item.controller;
        int status = controller ? static_cast<int>(controller->status()) : item.status;
        if (controller && status == static_cast<int>(ExportController::Status::Idle)) {
            status = item.status;
        }
        const int progress = controller ? controller->exportProgress() : item.progress;
        const QString preview = controller ? controller->firstFramePreview() : item.preview;
        const qint64 sizeBytes = controller ? controller->exportedSizeBytes() : item.sizeBytes;

        obj.insert(QStringLiteral("status"), status);
        obj.insert(QStringLiteral("progress"), progress);
        obj.insert(QStringLiteral("preview"), preview);
        obj.insert(QStringLiteral("size_bytes"), QJsonValue::fromVariant(sizeBytes));

        entries.append(obj);
    }

    const QJsonDocument doc(entries);
    file.write(doc.toJson(QJsonDocument::Compact));
    file.commit();
}

QString ExportManager::cachePath() const
{
    const QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    if (dirPath.isEmpty())
        return {};
    QDir dir(dirPath);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }
    return dir.filePath(QStringLiteral("export_history_cache.json"));
}

void ExportManager::attachControllerHandlers(ExportController* controller, WebSocketClient* client)
{
    connect(controller, &ExportController::firstFramePreviewChanged, this, [this, controller]() {
        updatePreview(controller);
    });
    connect(controller, &ExportController::exportedSizeBytesChanged, this, [this, controller](qint64) {
        updateSizeBytes(controller);
    });
    connect(controller, &ExportController::finished, this, [this, controller, client]() {
        const int row = m_model->indexOfController(controller);
        if (row >= 0) {
            m_model->updateCompletion(row,
                                      controller->status(),
                                      controller->exportProgress(),
                                      controller->firstFramePreview(),
                                      controller->exportedSizeBytes());
        }
        saveCache();
        controller->deleteLater();
        if (client)
            client->deleteLater();
    });
}

void ExportManager::startControllerExport(ExportController* controller,
                                          const QString& cameraId,
                                          const QDateTime& fromLocal,
                                          const QDateTime& toLocal,
                                          const QString& archiveId,
                                          const QString& outputPath,
                                          const QString& format)
{
    controller->startExportVideo(cameraId, fromLocal, toLocal, archiveId, outputPath, format);
}

void ExportManager::updatePreview(ExportController* controller)
{
    const int row = m_model->indexOfController(controller);
    if (row < 0)
        return;

    m_model->updatePreview(row, controller->firstFramePreview());
    saveCache();
}

void ExportManager::updateSizeBytes(ExportController* controller)
{
    const int row = m_model->indexOfController(controller);
    if (row < 0)
        return;

    m_model->updateSizeBytes(row, controller->exportedSizeBytes());
    saveCache();
}

QQuickItem* ExportManager::commonTimeline() const
{
    return m_commonTimeline;
}

void ExportManager::setCommonTimeline(QQuickItem* value)
{
    if (m_commonTimeline != value) {
        m_commonTimeline = value;
        emit commonTimelineChanged();
    }
}

QString ExportManager::archiveId() const
{
    return m_archiveId;
}

void ExportManager::setArchiveId(const QString& value)
{
    if (m_archiveId != value) {
        m_archiveId = value;
        emit archiveIdChanged();
    }
}
