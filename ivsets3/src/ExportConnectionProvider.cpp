#include "ExportConnectionProvider.h"

#include "ExportController.h"
#include "WebSocketClient.h"

#include <QDebug>
#include <QQmlContext>
#include <QQmlEngine>
#include <QTimer>
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

ExportConnectionProvider::ExportConnectionProvider(QObject* parent)
    : QObject(parent)
{
}

QObject* ExportConnectionProvider::wsUrlService() const
{
    return m_wsUrlService;
}

void ExportConnectionProvider::setWsUrlService(QObject* service)
{
    if (m_wsUrlService == service)
        return;

    if (m_wsUrlService && m_wsUrlConnection) {
        QObject::disconnect(m_wsUrlConnection);
        m_wsUrlConnection = QMetaObject::Connection();
    }

    m_wsUrlService = service;
    emit wsUrlServiceChanged();
}

void ExportConnectionProvider::ensureWsUrlService(QObject* contextObject)
{
    if (m_wsUrlService)
        return;

    QObject* appInfo = resolveAppInfo(contextObject);
    if (appInfo)
        setWsUrlService(appInfo);
}

void ExportConnectionProvider::requestExport(const ExportRequest& request, int modelRow)
{
    const QUrl wsUrl = resolveWsUrl();
    if (wsUrl.isEmpty() || !wsUrl.isValid()) {
        qWarning() << "[Export] missing wsUrl; waiting for wsUrlService update.";
        PendingExport pending {request, modelRow};
        m_pendingExports.push_back(pending);
        if (m_wsUrlService && !m_wsUrlConnection) {
            m_wsUrlConnection = QObject::connect(
                m_wsUrlService,
                SIGNAL(wsUrlChanged()),
                this,
                SLOT(handleWsUrlReady()));
        }
        requestWsUrlRefresh();
        return;
    }

    startExport(request, modelRow, wsUrl);
}

void ExportConnectionProvider::handleWsUrlReady()
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

    for (const PendingExport& item : pending)
        startExport(item.request, item.modelRow, wsUrl);
}

QUrl ExportConnectionProvider::resolveWsUrl() const
{
    if (!m_wsUrlService)
        return {};

    const QVariant wsUrlValue = m_wsUrlService->property("wsUrl");
    if (wsUrlValue.canConvert<QUrl>())
        return wsUrlValue.toUrl();

    return QUrl(wsUrlValue.toString());
}

void ExportConnectionProvider::requestWsUrlRefresh()
{
    if (!m_wsUrlService)
        return;

    const QString key2 = m_wsUrlService->property("archiveKey2").toString();
    if (key2.isEmpty())
        return;

    QMetaObject::invokeMethod(
        m_wsUrlService,
        "refreshWsUrlForKey2",
        Qt::QueuedConnection,
        Q_ARG(QString, key2));
}

void ExportConnectionProvider::startExport(const ExportRequest& request, int modelRow, const QUrl& wsUrl)
{
    QTimer::singleShot(0, this, [this, request, modelRow, wsUrl]() {
        auto* client = new WebSocketClient(this);
        client->startWorkerThread();
        client->setUrl(wsUrl);

        auto* controller = new ExportController(this);
        controller->setClient(client);
        controller->setImagePipeline(request.imagePipeline);
        controller->setMaxChunkDurationMinutes(request.maxChunkDurationMinutes);
        controller->setMaxChunkFileSizeBytes(request.maxChunkFileSizeBytes);
        controller->setExportPrimitives(request.exportPrimitives);
        controller->setExportCameraInformation(request.exportCameraInformation);
        controller->setExportImagePipeline(request.exportImagePipeline);

        emit exportControllerReady(modelRow, controller, client);

        QMetaObject::invokeMethod(controller,
                                  "startExportVideo",
                                  Qt::QueuedConnection,
                                  Q_ARG(QString, request.cameraId),
                                  Q_ARG(QDateTime, request.fromLocal),
                                  Q_ARG(QDateTime, request.toLocal),
                                  Q_ARG(QString, request.archiveId),
                                  Q_ARG(QString, request.outputPath),
                                  Q_ARG(QString, request.format));
    });
}
