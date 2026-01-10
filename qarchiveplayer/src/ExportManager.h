#pragma once

#include <QObject>
#include <QDateTime>

#include "ExportListModel.h"

class AppInfo;
class ExportController;
class ImagePipeline;

class ExportManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ExportListModel* activeExportsModel READ activeExportsModel CONSTANT)
public:
    explicit ExportManager(QObject* parent = nullptr);

    ExportListModel* activeExportsModel() const;

    void setAppInfo(AppInfo* appInfo);

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
                                 ImagePipeline* imagePipeline);
    Q_INVOKABLE void removeExport(int index);

private:
    void updatePreview(ExportController* controller);
    void updateSizeBytes(ExportController* controller);

    ExportListModel* m_model {nullptr};
    AppInfo* m_appInfo {nullptr};
};
