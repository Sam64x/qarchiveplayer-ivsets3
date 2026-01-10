#pragma once

#include <QObject>
#include <QDateTime>
#include "ExportConnectionProvider.h"
#include "ExportListModel.h"

class ExportController;
class WebSocketClient;

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
    void handleExportControllerReady(int modelRow, ExportController* controller, WebSocketClient* client);

private:
    void setShowExportsPanel(bool show);
    void updatePreview(ExportController* controller);
    void updateSizeBytes(ExportController* controller);

    ExportListModel* m_model {nullptr};
    ExportConnectionProvider* m_connectionProvider {nullptr};
    bool m_showExportsPanel {false};
    QObject* m_appInfo {nullptr};
};
