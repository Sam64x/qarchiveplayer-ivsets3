#include "ExportManager.h"

#include "ExportController.h"
#include "WebSocketClient.h"

#include <QUrl>
#include <QVariant>
#include <QQmlContext>
#include <QQmlEngine>
#include <QMetaObject>
#include <utility>

namespace {
QObject* resolveAppInfo(QObject* contextObject)
{
    if (!contextObject)
        return nullptr;

    auto* engine = qmlEngine(contextObject);
    if (!engine)
        return nullptr;

    QObject* appInfo = engine->property("appInfo").value<QObject*>();
    if (appInfo)
        return appInfo;

    QQmlContext* rootContext = engine->rootContext();
    if (!rootContext)
        return nullptr;

    QVariant contextProperty = rootContext->contextProperty("appInfo");
    if (contextProperty.canConvert<QObject*>())
        return contextProperty.value<QObject*>();

    return nullptr;
}
} // namespace

ExportManager::ExportManager(QObject* parent)
    : QObject(parent)
    , m_model(new ExportListModel(this))
{
}

ExportListModel* ExportManager::activeExportsModel() const
{
    return m_model;
}

bool ExportManager::showExportsPanel() const
{
    return m_showExportsPanel;
}

void ExportManager::setAppInfo(QObject* appInfo)
{
    if (m_appInfo == appInfo)
        return;
    if (m_appInfo && m_wsUrlConnection)
        QObject::disconnect(m_wsUrlConnection);
    m_appInfo = appInfo;
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
                               QObject* imagePipeline)
{
    if (!m_appInfo)
        m_appInfo = resolveAppInfo(this);

    const bool isSameDay = fromLocal.date() == toLocal.date();
    const QString toFormat = isSameDay ? QStringLiteral("HH:mm:ss")
                                       : QStringLiteral("dd.MM.yyyy HH:mm:ss");
    const QString timeText = fromLocal.toString("dd.MM.yyyy HH:mm:ss")
        + QStringLiteral(" - ") + toLocal.toString(toFormat);

    const QUrl wsUrl = resolveWsUrl();
    if (wsUrl.isEmpty() || !wsUrl.isValid()) {
        qWarning() << "[Export] missing wsUrl; waiting for AppInfo update.";
        PendingExport pending;
        pending.cameraId = cameraId;
        pending.fromLocal = fromLocal;
        pending.toLocal = toLocal;
        pending.archiveId = archiveId;
        pending.outputPath = outputPath;
        pending.format = format;
        pending.maxChunkDurationMinutes = maxChunkDurationMinutes;
        pending.maxChunkFileSizeBytes = maxChunkFileSizeBytes;
        pending.exportPrimitives = exportPrimitives;
        pending.exportCameraInformation = exportCameraInformation;
        pending.exportImagePipeline = exportImagePipeline;
        pending.imagePipeline = imagePipeline;
        m_pendingExports.push_back(pending);
        if (m_appInfo && !m_wsUrlConnection) {
            m_wsUrlConnection = QObject::connect(
                m_appInfo,
                SIGNAL(wsUrlChanged()),
                this,
                SLOT(handleWsUrlReady()));
        }
        if (m_appInfo) {
            const QString key2 = m_appInfo->property("archiveKey2").toString();
            QMetaObject::invokeMethod(m_appInfo, "refreshWsUrlForKey2", Q_ARG(QString, key2));
        }
        return;
    }

    auto* client = new WebSocketClient(this);
    client->startWorkerThread();
    client->setUrl(wsUrl);

    auto* controller = new ExportController(this);
    controller->setClient(client);
    controller->setImagePipeline(imagePipeline);
    controller->setMaxChunkDurationMinutes(maxChunkDurationMinutes);
    controller->setMaxChunkFileSizeBytes(maxChunkFileSizeBytes);
    controller->setExportPrimitives(exportPrimitives);
    controller->setExportCameraInformation(exportCameraInformation);
    controller->setExportImagePipeline(exportImagePipeline);

    ExportListModel::Item item;
    item.controller = controller;
    item.client = client;
    item.path = outputPath;
    item.cameraName = cameraId;
    item.timeText = timeText;
    item.status = ExportController::Status::Uploading;
    item.progress = controller->exportProgress();
    item.preview = controller->firstFramePreview();
    item.sizeBytes = controller->exportedSizeBytes();

    m_model->addItem(item);

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
        controller->deleteLater();
        if (client)
            client->deleteLater();
    });

    controller->startExportVideo(cameraId, fromLocal, toLocal, archiveId, outputPath, format);
    setShowExportsPanel(true);
}

void ExportManager::handleWsUrlReady()
{
    const QUrl wsUrl = resolveWsUrl();
    if (wsUrl.isEmpty() || !wsUrl.isValid())
        return;

    QVector<PendingExport> pending = std::move(m_pendingExports);
    m_pendingExports.clear();
    if (m_wsUrlConnection) {
        QObject::disconnect(m_wsUrlConnection);
        m_wsUrlConnection = QMetaObject::Connection();
    }

    for (const PendingExport& item : pending) {
        startExport(item.cameraId,
                    item.fromLocal,
                    item.toLocal,
                    item.archiveId,
                    item.outputPath,
                    item.format,
                    item.maxChunkDurationMinutes,
                    item.maxChunkFileSizeBytes,
                    item.exportPrimitives,
                    item.exportCameraInformation,
                    item.exportImagePipeline,
                    item.imagePipeline);
    }
}

QUrl ExportManager::resolveWsUrl() const
{
    if (!m_appInfo)
        return {};

    const QVariant wsUrlValue = m_appInfo->property("wsUrl");
    if (wsUrlValue.canConvert<QUrl>())
        return wsUrlValue.toUrl();

    return QUrl(wsUrlValue.toString());
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

    if (m_model->rowCount() == 0)
        setShowExportsPanel(false);
}

void ExportManager::setShowExportsPanel(bool show)
{
    if (m_showExportsPanel == show)
        return;
    m_showExportsPanel = show;
    emit showExportsPanelChanged();
}

void ExportManager::updatePreview(ExportController* controller)
{
    const int row = m_model->indexOfController(controller);
    if (row < 0)
        return;

    m_model->updatePreview(row, controller->firstFramePreview());
}

void ExportManager::updateSizeBytes(ExportController* controller)
{
    const int row = m_model->indexOfController(controller);
    if (row < 0)
        return;

    m_model->updateSizeBytes(row, controller->exportedSizeBytes());
}
