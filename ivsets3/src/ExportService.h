#pragma once

#include <QDateTime>
#include <QMetaObject>
#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVector>

class ExportController;
class ExportManager;

class ExportService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QObject* appInfo READ appInfo WRITE setAppInfo NOTIFY appInfoChanged)
    Q_PROPERTY(ExportManager* exportManager READ exportManager WRITE setExportManager NOTIFY exportManagerChanged)
public:
    enum Status {
        Idle = 0,
        Queued = 1,
        Connecting = 2,
        Running = 3,
        Failed = 4
    };
    Q_ENUM(Status)

    explicit ExportService(QObject* parent = nullptr);

    Status status() const;
    QString lastError() const;

    QObject* appInfo() const;
    void setAppInfo(QObject* appInfo);

    ExportManager* exportManager() const;
    void setExportManager(ExportManager* manager);

    Q_INVOKABLE bool startExport(const QString& cameraId,
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
                                 QObject* imagePipeline,
                                 const QUrl& wsUrl);

signals:
    void statusChanged(ExportService::Status status);
    void lastErrorChanged(const QString& error);
    void appInfoChanged(QObject* appInfo);
    void exportManagerChanged(ExportManager* manager);

private slots:
    void handleWsUrlReady();

private:
    struct PendingExport {
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
        QPointer<QObject> imagePipeline;
        QUrl wsUrl;
    };

    bool validateExport(const PendingExport& pending, QString* error) const;
    QUrl resolveWsUrl(const PendingExport& pending) const;
    QUrl resolveWsUrl() const;
    ExportController* startExportInternal(const PendingExport& pending, const QUrl& wsUrl);
    void attachController(ExportController* controller);
    void setStatus(Status status);
    void setLastError(const QString& error);

    Status m_status {Idle};
    QString m_lastError;
    QPointer<QObject> m_appInfo;
    QPointer<ExportManager> m_exportManager;
    QVector<PendingExport> m_pendingExports;
    QPointer<ExportController> m_currentController;
    QMetaObject::Connection m_wsUrlConnection;
};
