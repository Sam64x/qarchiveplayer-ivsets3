#pragma once

#include <QObject>
#include <QDateTime>
#include <QMetaObject>
#include <QUrl>
#include <QVector>

#include "ExportListModel.h"

class ExportController;

class ExportManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ExportListModel* activeExportsModel READ activeExportsModel CONSTANT)
    Q_PROPERTY(bool showExportsPanel READ showExportsPanel NOTIFY showExportsPanelChanged)
public:
    explicit ExportManager(QObject* parent = nullptr);

    ExportListModel* activeExportsModel() const;
    bool showExportsPanel() const;

    void setAppInfo(QObject* appInfo);

    Q_INVOKABLE void startExport(const QString& cameraId,
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
                                 QObject* imagePipeline);
    Q_INVOKABLE void removeExport(int index);

signals:
    void showExportsPanelChanged();

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
        int modelRow {-1};
        int maxChunkDurationMinutes {0};
        qint64 maxChunkFileSizeBytes {0};
        bool exportPrimitives {false};
        bool exportCameraInformation {false};
        bool exportImagePipeline {false};
        QObject* imagePipeline {nullptr};
    };

    QUrl resolveWsUrl() const;

    void setShowExportsPanel(bool show);
    void updatePreview(ExportController* controller);
    void updateSizeBytes(ExportController* controller);

    ExportListModel* m_model {nullptr};
    bool m_showExportsPanel {false};
    QObject* m_appInfo {nullptr};
    QVector<PendingExport> m_pendingExports;
    QMetaObject::Connection m_wsUrlConnection;
};
