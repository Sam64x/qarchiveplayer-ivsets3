#include "ExportManager.h"

#include "ExportConnectionProvider.h"
#include "ExportController.h"
#include "WebSocketClient.h"


ExportManager::ExportManager(QObject* parent)
    : QObject(parent)
    , m_model(new ExportListModel(this))
    , m_connectionProvider(new ExportConnectionProvider(this))
{
    connect(m_connectionProvider,
            &ExportConnectionProvider::exportControllerReady,
            this,
            &ExportManager::handleExportControllerReady);
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
    m_appInfo = appInfo;
    if (m_connectionProvider)
        m_connectionProvider->setWsUrlService(appInfo);
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
    const bool isSameDay = fromLocal.date() == toLocal.date();
    const QString toFormat = isSameDay ? QStringLiteral("HH:mm:ss")
                                       : QStringLiteral("dd.MM.yyyy HH:mm:ss");
    const QString timeText = fromLocal.toString("dd.MM.yyyy HH:mm:ss")
                             + QStringLiteral(" - ") + toLocal.toString(toFormat);
    ExportListModel::Item item;
    item.path = outputPath;
    item.cameraName = cameraId;
    item.timeText = timeText;
    item.status = ExportController::Status::Uploading;
    item.progress = 0;
    const int modelRow = m_model->addItem(item);
    setShowExportsPanel(true);

    if (m_connectionProvider)
        m_connectionProvider->ensureWsUrlService(this);

    if (!m_connectionProvider)
        return;

    ExportConnectionProvider::ExportRequest request;
    request.cameraId = cameraId;
    request.fromLocal = fromLocal;
    request.toLocal = toLocal;
    request.archiveId = archiveId;
    request.outputPath = outputPath;
    request.format = format;
    request.maxChunkDurationMinutes = maxChunkDurationMinutes;
    request.maxChunkFileSizeBytes = maxChunkFileSizeBytes;
    request.exportPrimitives = exportPrimitives;
    request.exportCameraInformation = exportCameraInformation;
    request.exportImagePipeline = exportImagePipeline;
    request.imagePipeline = imagePipeline;
    m_connectionProvider->requestExport(request, modelRow);
}

void ExportManager::handleExportControllerReady(int modelRow,
                                                ExportController* controller,
                                                WebSocketClient* client)
{
    if (!controller)
        return;

    if (modelRow >= 0)
        m_model->updateController(modelRow, controller, client);

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
