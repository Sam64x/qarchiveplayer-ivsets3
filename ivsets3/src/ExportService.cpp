#include "ExportService.h"

#include "ExportController.h"
#include "ExportManager.h"

#include <QMetaObject>
#include <QQmlContext>
#include <QQmlEngine>
#include <QVariant>

namespace {
QObject* resolveAppInfo(QObject* contextObject)
{
    if (!contextObject)
        return nullptr;

    auto* engine = qmlEngine(contextObject);
    if (!engine) {
        engine = qobject_cast<QQmlEngine*>(contextObject->parent());
    }
    if (!engine) {
        if (auto* context = QQmlEngine::contextForObject(contextObject))
            engine = context->engine();
    }
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

ExportService::ExportService(QObject* parent)
    : QObject(parent)
{
}

ExportService::Status ExportService::status() const
{
    return m_status;
}

QString ExportService::lastError() const
{
    return m_lastError;
}

QObject* ExportService::appInfo() const
{
    return m_appInfo;
}

void ExportService::setAppInfo(QObject* appInfo)
{
    if (m_appInfo == appInfo)
        return;
    if (m_appInfo && m_wsUrlConnection)
        QObject::disconnect(m_wsUrlConnection);
    m_appInfo = appInfo;
    emit appInfoChanged(m_appInfo);
}

ExportManager* ExportService::exportManager() const
{
    return m_exportManager;
}

void ExportService::setExportManager(ExportManager* manager)
{
    if (m_exportManager == manager)
        return;
    m_exportManager = manager;
    emit exportManagerChanged(m_exportManager);
}

bool ExportService::startExport(const QString& cameraId,
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

    QString validationError;
    if (!validateExport(pending, &validationError)) {
        setLastError(validationError);
        setStatus(Failed);
        return false;
    }

    setLastError(QString());
    setStatus(Queued);

    if (!m_appInfo)
        m_appInfo = resolveAppInfo(this);
    if (!m_appInfo) {
        setLastError(QStringLiteral("AppInfo is not available."));
        setStatus(Failed);
        return false;
    }

    if (!m_exportManager) {
        if (auto* engine = qmlEngine(this)) {
            QObject* managerObj = engine->property("exportManager").value<QObject*>();
            m_exportManager = qobject_cast<ExportManager*>(managerObj);
        }
    }

    if (!m_exportManager) {
        setLastError(QStringLiteral("ExportManager is not available."));
        setStatus(Failed);
        return false;
    }

    const QUrl wsUrl = resolveWsUrl();
    if (wsUrl.isEmpty() || !wsUrl.isValid()) {
        m_pendingExports.push_back(pending);
        setStatus(Connecting);
        if (!m_wsUrlConnection) {
            m_wsUrlConnection = QObject::connect(
                m_appInfo,
                SIGNAL(wsUrlChanged()),
                this,
                SLOT(handleWsUrlReady()));
        }
        const QString key2 = m_appInfo->property("archiveKey2").toString();
        QMetaObject::invokeMethod(
            m_appInfo,
            "refreshWsUrlForKey2",
            Qt::QueuedConnection,
            Q_ARG(QString, key2));
        return true;
    }

    setStatus(Connecting);
    ExportController* controller = startExportInternal(pending, wsUrl);
    if (!controller) {
        setLastError(QStringLiteral("Failed to start export."));
        setStatus(Failed);
        return false;
    }

    attachController(controller);
    return true;
}

void ExportService::handleWsUrlReady()
{
    const QUrl wsUrl = resolveWsUrl();
    if (wsUrl.isEmpty() || !wsUrl.isValid())
        return;

    if (m_wsUrlConnection) {
        QObject::disconnect(m_wsUrlConnection);
        m_wsUrlConnection = QMetaObject::Connection();
    }

    QVector<PendingExport> pending = std::move(m_pendingExports);
    m_pendingExports.clear();
    setStatus(Connecting);

    for (const PendingExport& item : pending) {
        ExportController* controller = startExportInternal(item, wsUrl);
        if (!controller) {
            setLastError(QStringLiteral("Failed to start export."));
            setStatus(Failed);
            return;
        }
        attachController(controller);
    }
}

bool ExportService::validateExport(const PendingExport& pending, QString* error) const
{
    if (pending.cameraId.isEmpty() || pending.archiveId.isEmpty()) {
        if (error)
            *error = QStringLiteral("Camera or archive identifier is missing.");
        return false;
    }

    if (!pending.fromLocal.isValid() || !pending.toLocal.isValid() || pending.fromLocal >= pending.toLocal) {
        if (error)
            *error = QStringLiteral("Invalid export time range.");
        return false;
    }

    if (pending.outputPath.trimmed().isEmpty()) {
        if (error)
            *error = QStringLiteral("Output path is missing.");
        return false;
    }

    if (pending.format.trimmed().isEmpty()) {
        if (error)
            *error = QStringLiteral("Export format is missing.");
        return false;
    }

    if (pending.exportImagePipeline && pending.imagePipeline.isNull()) {
        if (error)
            *error = QStringLiteral("Image pipeline is not available.");
        return false;
    }

    return true;
}

QUrl ExportService::resolveWsUrl() const
{
    if (!m_appInfo)
        return {};

    const QVariant wsUrlValue = m_appInfo->property("wsUrl");
    if (wsUrlValue.canConvert<QUrl>())
        return wsUrlValue.toUrl();

    return QUrl(wsUrlValue.toString());
}

ExportController* ExportService::startExportInternal(const PendingExport& pending, const QUrl& wsUrl)
{
    if (!m_exportManager)
        return nullptr;

    return m_exportManager->startExport(pending.cameraId,
                                        pending.fromLocal,
                                        pending.toLocal,
                                        pending.archiveId,
                                        pending.outputPath,
                                        pending.format,
                                        pending.maxChunkDurationMinutes,
                                        pending.maxChunkFileSizeBytes,
                                        pending.exportPrimitives,
                                        pending.exportCameraInformation,
                                        pending.exportImagePipeline,
                                        pending.imagePipeline,
                                        wsUrl);
}

void ExportService::attachController(ExportController* controller)
{
    if (!controller)
        return;

    m_currentController = controller;

    connect(controller, &ExportController::statusChanged, this, [this, controller](ExportController::Status status) {
        if (m_currentController != controller)
            return;
        if (status == ExportController::Status::Uploading)
            setStatus(Running);
    });

    connect(controller, &ExportController::finished, this, [this, controller](bool ok, const QString& error) {
        if (m_currentController != controller)
            return;
        if (!ok) {
            setLastError(error.isEmpty() ? QStringLiteral("Export failed.") : error);
            setStatus(Failed);
        } else {
            setStatus(Idle);
        }
    });
}

void ExportService::setStatus(Status status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged(m_status);
}

void ExportService::setLastError(const QString& error)
{
    if (m_lastError == error)
        return;
    m_lastError = error;
    emit lastErrorChanged(m_lastError);
}
