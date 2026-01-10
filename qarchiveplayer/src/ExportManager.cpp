#include "ExportManager.h"

#include "AppInfo.h"
#include "ExportController.h"
#include "ImagePipeline.h"
#include "WebSocketClient.h"

#include <QUrl>

ExportManager::ExportManager(QObject* parent)
    : QObject(parent)
    , m_model(new ExportListModel(this))
{
}

ExportListModel* ExportManager::activeExportsModel() const
{
    return m_model;
}

void ExportManager::setAppInfo(AppInfo* appInfo)
{
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
                               ImagePipeline* imagePipeline)
{
    auto* client = new WebSocketClient(this);
    client->startWorkerThread();
    if (m_appInfo) {
        client->setUrl(QUrl(m_appInfo->wsUrl()));
    }

    auto* controller = new ExportController(this);
    controller->setClient(client);
    controller->setImagePipeline(imagePipeline);
    controller->setMaxChunkDurationMinutes(maxChunkDurationMinutes);
    controller->setMaxChunkFileSizeBytes(maxChunkFileSizeBytes);
    controller->setExportPrimitives(exportPrimitives);
    controller->setExportCameraInformation(exportCameraInformation);
    controller->setExportImagePipeline(exportImagePipeline);

    const bool isSameDay = fromLocal.date() == toLocal.date();
    const QString toFormat = isSameDay ? QStringLiteral("HH:mm:ss")
                                       : QStringLiteral("dd.MM.yyyy HH:mm:ss");
    const QString timeText = fromLocal.toString("dd.MM.yyyy HH:mm:ss")
        + QStringLiteral(" - ") + toLocal.toString(toFormat);

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
