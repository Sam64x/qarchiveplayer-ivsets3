#pragma once

#include <QObject>
#include <QDateTime>
#include <QMetaObject>
#include <QUrl>
#include <QVector>

class ExportController;
class WebSocketClient;

class ExportConnectionProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* wsUrlService READ wsUrlService WRITE setWsUrlService NOTIFY wsUrlServiceChanged)
public:
    struct ExportRequest {
        QString cameraId;
        QDateTime fromLocal;
        QDateTime toLocal;
        QString archiveId;
        QString outputPath;
        QString format;
        int maxChunkDurationMinutes {0};
        qint64 maxChunkFileSizeBytes {0};
        bool exportPrimitives {false};
        bool exportCameraInformation {false};
        bool exportImagePipeline {false};
        QObject* imagePipeline {nullptr};
    };

    explicit ExportConnectionProvider(QObject* parent = nullptr);

    QObject* wsUrlService() const;
    void setWsUrlService(QObject* service);

    void ensureWsUrlService(QObject* contextObject);
    void requestExport(const ExportRequest& request, int modelRow);

signals:
    void wsUrlServiceChanged();
    void exportControllerReady(int modelRow, ExportController* controller, WebSocketClient* client);

private slots:
    void handleWsUrlReady();

private:
    struct PendingExport {
        ExportRequest request;
        int modelRow {-1};
    };

    QUrl resolveWsUrl() const;
    void requestWsUrlRefresh();
    void startExport(const ExportRequest& request, int modelRow, const QUrl& wsUrl);

    QObject* m_wsUrlService {nullptr};
    QVector<PendingExport> m_pendingExports;
    QMetaObject::Connection m_wsUrlConnection;
};
