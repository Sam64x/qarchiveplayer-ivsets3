#pragma once

#include <QObject>
#include <QDateTime>

#include "ExportListModel.h"

class ExportController;
class ImagePipeline;
class QQuickItem;

class ExportManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ExportListModel* activeExportsModel READ activeExportsModel CONSTANT)

    //для возможности выгрузки из списка источников
    Q_PROPERTY(QQuickItem* commonTimeline READ commonTimeline WRITE setCommonTimeline NOTIFY commonTimelineChanged)
    Q_PROPERTY(QString archiveId READ archiveId WRITE setArchiveId NOTIFY archiveIdChanged)

public:
    explicit ExportManager(QObject* parent = nullptr);

    ExportListModel* activeExportsModel() const;

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
                                 ImagePipeline* imagePipeline,
                                 const QString& wsUrl);
    Q_INVOKABLE void restartExport(int index);
    Q_INVOKABLE void removeExport(int index);

    QQuickItem* commonTimeline() const;
    void setCommonTimeline(QQuickItem* value);

    QString archiveId() const;
    void setArchiveId(const QString& value);

signals:
    void commonTimelineChanged();
    void archiveIdChanged();

private:
    void loadCache();
    void saveCache() const;
    QString cachePath() const;
    void attachControllerHandlers(ExportController* controller, WebSocketClient* client);
    void startControllerExport(ExportController* controller,
                               const QString& cameraId,
                               const QDateTime& fromLocal,
                               const QDateTime& toLocal,
                               const QString& archiveId,
                               const QString& outputPath,
                               const QString& format);
    void updatePreview(ExportController* controller);
    void updateSizeBytes(ExportController* controller);

    ExportListModel* m_model {nullptr};

    QQuickItem* m_commonTimeline {nullptr};
    QString m_archiveId;
};
