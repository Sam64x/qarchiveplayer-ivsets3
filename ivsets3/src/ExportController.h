#pragma once

#include <QObject>
#include <QDateTime>
#include <QStringList>
#include <QList>
#include <QVector>
#include <QJsonArray>
#include <QJsonObject>
#include <QQueue>
#include <QHash>
#include <QSet>
#include <QUrl>
#include <QFutureWatcher>
#include <QPointer>
#include <QMutex>
#include <optional>
#include <atomic>
#include <memory>
#include <chrono>

#include <QObject>

class StreamingRemuxer;
struct ChunkState;

class WebSocketClient;
class QTimer;

struct ExportFilePattern {
    QString   directory;
    QString   cameraId;
    QDateTime fromLocal;
    QDateTime toLocal;
    QString   extension;
};

struct PrimitivePoint {
    double xNorm {0.0};
    double yNorm {0.0};
};

enum class PrimitiveType {
    Line,
    Rectangle,
    Text
};

struct PrimitiveShape {
    PrimitiveType      type {PrimitiveType::Line};
    QVector<PrimitivePoint> points;
    QString            text;
    QString            color;
    int                thicknessPx {0};
    int                fontSizePx {0};
};

struct PrimitiveEvent {
    qint64                timeUtcMs {0};
    QVector<PrimitiveShape> shapes;
};

class ExportController : public QObject
{
    Q_OBJECT
public:
    explicit ExportController(const QUrl& wsUrl, QObject* parent = nullptr);
    explicit ExportController(QObject* parent = nullptr);
    ~ExportController() override;

    struct PipelineSettings {
        int r = 128;
        int g = 128;
        int b = 128;
        int brightness = 50;
        int contrast = 50;
        int saturation = 50;
    };

    enum Status { Idle = 0, Uploading = 1, Done = 2, Error = 3 };
    Q_ENUM(Status)

    Q_PROPERTY(bool   exporting           READ exporting           NOTIFY exportingChanged)
    Q_PROPERTY(int    exportProgress      READ exportProgress      NOTIFY exportProgressChanged)
    Q_PROPERTY(Status status              READ status              NOTIFY statusChanged)
    Q_PROPERTY(qint64 exportedSizeBytes   READ exportedSizeBytes   NOTIFY exportedSizeBytesChanged)
    Q_PROPERTY(bool   exportPrimitives    READ exportPrimitives    WRITE setExportPrimitives    NOTIFY exportPrimitivesChanged)
    Q_PROPERTY(bool   exportCameraInformation READ exportCameraInformation WRITE setExportCameraInformation NOTIFY exportCameraInformationChanged)
    Q_PROPERTY(bool   exportImagePipeline READ exportImagePipeline WRITE setExportImagePipeline NOTIFY exportImagePipelineChanged)
    Q_PROPERTY(int    maxChunkDurationMinutes READ maxChunkDurationMinutes WRITE setMaxChunkDurationMinutes NOTIFY maxChunkDurationMinutesChanged)
    Q_PROPERTY(qint64 maxChunkFileSizeBytes   READ maxChunkFileSizeBytes   WRITE setMaxChunkFileSizeBytes   NOTIFY maxChunkFileSizeBytesChanged)
    Q_PROPERTY(WebSocketClient* client    READ client              WRITE setClient          NOTIFY clientChanged)
    Q_PROPERTY(QObject* imagePipeline READ imagePipeline WRITE setImagePipeline NOTIFY imagePipelineChanged)
    Q_PROPERTY(QString firstFramePreview  READ firstFramePreview   NOTIFY firstFramePreviewChanged)

    Q_INVOKABLE void setImagePipeline(QObject* pipeline)
    {
        if (m_pipeline == pipeline)
            return;
        m_pipeline = pipeline;
        emit imagePipelineChanged();
    }

    Q_INVOKABLE void connectToServer();
    Q_INVOKABLE void startExportVideo(const QString& cameraId,
                                      const QDateTime& fromLocalTime,
                                      const QDateTime& toLocalTime,
                                      const QString& archiveId,
                                      const QString& outputPath,
                                      const QString& format);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void onExportProgress(int v);

    bool   exporting()      const { return m_active.load(std::memory_order_acquire); }
    int    exportProgress() const { return m_exportProgress; }
    Status status()         const { return m_exportStatus; }
    bool   exportPrimitives() const { return m_exportPrimitives; }
    bool   exportCameraInformation() const { return m_exportCameraInformation; }
    bool   exportImagePipeline() const { return m_exportImagePipeline; }
    WebSocketClient* client() const { return m_client; }
    void setClient(WebSocketClient* c);
    QObject* imagePipeline() const { return m_pipeline.data(); }
    int maxChunkDurationMinutes() const { return m_maxChunkDurationMinutes; }
    Q_INVOKABLE void setMaxChunkDurationMinutes(int minutes);
    qint64 maxChunkFileSizeBytes() const { return m_maxChunkFileSizeBytes; }
    Q_INVOKABLE void setMaxChunkFileSizeBytes(qint64 bytes);
    Q_INVOKABLE void setExportPrimitives(bool enabled);
    Q_INVOKABLE void setExportCameraInformation(bool enabled);
    Q_INVOKABLE void setExportImagePipeline(bool enabled);
    QString firstFramePreview() const { return m_firstFramePreview; }
    qint64 exportedSizeBytes() const { return m_exportedSizeBytes; }

public slots:
    void onExportFinished(bool ok, const QString& err);
    void onMuxProgress(int pct, quint64 genId);
    void onMuxFinished(bool ok, const QString& err, quint64 genId);
    void onPreviewReady();

signals:
    void clientChanged();
    void imagePipelineChanged();
    void exportProgressChanged(int percent);
    void statusChanged(Status status);
    void exportingChanged(bool exporting);
    void exportPrimitivesChanged();
    void exportCameraInformationChanged();
    void exportImagePipelineChanged();
    void finished(bool ok, const QString& error);
    void exportedSizeBytesChanged(qint64 bytes);
    void maxChunkDurationMinutesChanged(int minutes);
    void maxChunkFileSizeBytesChanged(qint64 bytes);
    void firstFramePreviewChanged();

private slots:
    void onTextMessage(const QString& msg);
    void onBinaryMessage(const QByteArray& bin);

private:
    struct ChunkState {
        int       index {1};
        QDateTime startUtc;
        QDateTime endUtc;
        qint64    durationMs {0};
        qint64    sizeBytes {0};

        bool active() const { return startUtc.isValid(); }
    };

    struct ChunkRemuxContext {
        int         chunkIndex {0};
        QString     targetPath;
        QStringList segments;
    };

    struct ClosingRemuxContext {
        std::shared_ptr<StreamingRemuxer> remuxer;
        bool writeOut {false};
        ChunkState chunkState;
        QString chunkPath;
    };

    struct PreviewResult {
        QString dataUri;
        quint64 generationId {0};
    };

    struct SegmentMeta {
        int       index {-1};
        QDateTime startUtc;
        QString   atIso;
        int       retryCount {0};

        bool isValid() const { return index >= 0 && startUtc.isValid(); }
    };

    struct InflightSegmentInfo {
        QDateTime sentAtUtc;
        QString atIso;
        int retryCount {0};
    };

    enum class ChunkMode {
        SingleFile,
        ByDuration,
        BySize,
        Mixed
    };

    void start(const QString& cameraId,
               const QDateTime& fromUtc,
               const QDateTime& toUtc,
               const QString& archiveId,
               const QString& outputPath);

    void resetState();

    bool handleTextMessage(const QJsonObject& root);

    void requestSegmentsMeta();
    void fetchNextExportSegment();
    void enqueueSegmentRequest(const SegmentMeta& meta);

    void stopClientReconnects();
    void stopConsumerThread();
    void cancelRemuxerAsync(const std::shared_ptr<StreamingRemuxer>& remuxer);

    static QString   toIsoUtcMs(const QDateTime& dt);
    static QDateTime parseIsoUtc(const QString& s);
    static QString   tokenToString(const QJsonValue& v);

    void setExportedSizeBytes(qint64 bytes);
    QString buildChunkTargetPath(const QDateTime& startUtc,
                                 const QDateTime& endUtc,
                                 int chunkIndex) const;
    QString createTempSegmentFile(const QByteArray& data) const;
    bool appendSegment(const QByteArray& data, const SegmentMeta& meta);
    bool looksLikeMetadataResponse(const QJsonObject& root) const;
    qint64 estimateSegmentDurationMs(const SegmentMeta& meta) const;
    QDateTime earliestMetadataTime(const QJsonObject& root) const;
    void appendMetadataForExport(const QJsonObject& root);
    void buildPrimitiveEventsFromMetadata();
    bool writeSidecarMetadataJson(const QString& chunkPath,
                                  const ChunkState& chunk,
                                  const QDateTime& endUtc);
    bool shouldStartNewChunk(const ChunkState& chunk,
                             qint64 segmentDurationMs,
                             qint64 segmentBytes) const;
    bool openNewChunk(const QDateTime& segmentStartUtc);
    void maybeFinishExport();
    bool canFinishExport() const;
    void discardCurrentChunk();
    void finalizeChunk(bool writeOut = true);
    void postRemuxFinalizeChunk(const ClosingRemuxContext& ctx);
    void clearChunkState();
    void updateProgressByDuration(qint64 appendedDurationMs);
    void maybeUpdatePreview(const QByteArray& segment);
    void resetControllerState();
    void checkInflightTimeouts();

    void updateMuxProgress(int pct);

    struct ControllerState;
    ControllerState& controllerState();

    int combinedProgressForState(const ControllerState& st) const;

private:
    WebSocketClient* m_client {nullptr};
    bool m_clientConnected {false};
    bool m_pendingSegmentsRequest {false};
    bool m_exportPrimitives {false};
    bool m_exportCameraInformation {false};
    bool m_exportImagePipeline {false};

    QString   m_cameraId;
    QString   m_archiveId;
    QDateTime m_fromUtc;
    QDateTime m_toUtc;
    QString   m_outputPath;
    int       m_fps {0};

    QPointer<QObject> m_pipeline;

    std::atomic<bool> m_active {false};
    int    m_inflight {0};
    int    m_maxInflight {4};
    QHash<int, InflightSegmentInfo> m_inflightSegments;
    QTimer* m_inflightTimer {nullptr};

    int    m_exportProgress {0};
    int    m_lastLoggedExportPercent {-1};
    Status m_exportStatus {Idle};

    QString     m_nextPageToken;
    QString     m_lastSentToken;

    QStringList     m_segmentTimes;
    QSet<QString>   m_segmentTimesSet;
    int             m_total {0};
    int             m_index {0};
    QQueue<SegmentMeta> m_pendingSegments;
    QQueue<SegmentMeta> m_retrySegments;
    qint64 m_rawMetadataCount {0};
    QJsonArray m_rawMetadataSample;
    QVector<PrimitiveEvent> m_primitiveEvents;
    bool m_primitiveEventsDirty {false};

    enum class Phase { Collecting, Writing, Finished };
    Phase m_phase { Phase::Collecting };
    bool  m_segmentsComplete {false};

    QUrl m_wsUrl;

    int    m_maxChunkDurationMinutes {0};
    qint64 m_maxChunkFileSizeBytes {0};

    QDateTime m_firstFrameUtc;
    qint64    m_lastQueuedPtsMs {-1};
    QString   m_firstFramePreview;
    QFuture<PreviewResult> m_previewFuture;
    QFutureWatcher<PreviewResult>* m_previewWatcher {nullptr};
    qint64    m_exportedSizeBytes {0};
    quint64   m_exportGenerationId {0};
    bool      m_finishEmitted {false};

    std::optional<PipelineSettings> m_exportPipelineSettings;

    ExportFilePattern m_pattern;
    QString           m_finalOutputPath;

    QStringList m_currentChunkSegments;
    ChunkMode   m_chunkMode {ChunkMode::SingleFile};
    ChunkState  m_chunkState;
    qint64      m_chunkLimitMs {0};
    qint64      m_chunkLimitBytes {0};
    qint64      m_processedDurationMs {0};
    qint64      m_totalDurationMs {0};
    int         m_processedSegments {0};
    QString     m_currentChunkPath;
    bool        m_chunkClosing {false};
    std::chrono::steady_clock::time_point m_lastMuxProgressEmit;

    QQueue<ClosingRemuxContext> m_closingRemuxers;

    std::unique_ptr<ControllerState> m_state;
    mutable QMutex m_stateMutex;
    bool m_stopConsumerPending {false};
};
