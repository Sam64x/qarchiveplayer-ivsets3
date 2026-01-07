#pragma once

#include <QObject>
#include <QTimer>
#include <QDateTime>
#include <QVector>
#include <QByteArray>
#include <QQueue>
#include <QSet>
#include <QMap>
#include <QImage>
#include <QDir>
#include <QRegularExpression>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QFutureWatcher>
#include <QThreadPool>
#include <QVariant>
#include <QElapsedTimer>
#include <atomic>
#include <limits>
#include <algorithm>
#include <cmath>
#include <memory>
#include <set>

#include "WebSocketClient.h"
#include "VideoSegmentDecoder.h"
#include "Nv12Frame.h"
#include "FrameBuffer.h"
#include "ImagePipeline.h"

class ArchiveSegmentStreamer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(WebSocketClient* client READ client WRITE setClient NOTIFY clientChanged)
    Q_PROPERTY(ImagePipeline* imagePipeline READ imagePipeline WRITE setImagePipeline NOTIFY imagePipelineChanged)
    Q_PROPERTY(QString cameraName READ cameraName WRITE setCameraName NOTIFY cameraNameChanged)
    Q_PROPERTY(QString archiveId READ archiveId WRITE setArchiveId NOTIFY archiveIdChanged)
    Q_PROPERTY(bool autoInitOnConnect READ autoInitOnConnect WRITE setAutoInitOnConnect NOTIFY autoInitOnConnectChanged)
    Q_PROPERTY(bool reinitOnReconnect READ reinitOnReconnect WRITE setReinitOnReconnect NOTIFY reinitOnReconnectChanged)
    Q_PROPERTY(bool    paused            READ paused           NOTIFY pausedChanged)
    Q_PROPERTY(double  playbackSpeed     READ playbackSpeed    WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(QString currentTime       READ currentTime      NOTIFY currentTimeChanged)
    Q_PROPERTY(QString currentDate       READ currentDate      NOTIFY currentDateChanged)
    Q_PROPERTY(double  currentFPS        READ currentFPS       NOTIFY currentFPSChanged)
    Q_PROPERTY(QString cameraResolution  READ cameraResolution NOTIFY cameraResolutionChanged)
    Q_PROPERTY(bool wsOpen READ wsOpen NOTIFY wsOpenChanged)
    Q_PROPERTY(QVariantList currentPrimitives READ currentPrimitives NOTIFY primitivesChanged)
    Q_PROPERTY(bool drawPrimitives READ drawPrimitives WRITE setDrawPrimitives NOTIFY drawPrimitivesChanged)
    Q_PROPERTY(bool externalClock READ externalClock WRITE setExternalClock NOTIFY externalClockChanged)

public:
    explicit ArchiveSegmentStreamer(WebSocketClient* client, QObject* parent=nullptr);
    explicit ArchiveSegmentStreamer(QObject* parent=nullptr);

    Q_INVOKABLE void setImagePipeline(ImagePipeline* pipeline) { if (m_pipeline == pipeline) return; m_pipeline = pipeline; emit imagePipelineChanged(); }
    Q_INVOKABLE void delayStart(const QString& cameraId,
                                const QDateTime& atLocalTime,
                                const QString& archiveId);
    Q_INVOKABLE void startStreamAt(const QString& cameraId,
                                   const QDateTime& atLocalTime,
                                   const QString& archiveId);
    Q_INVOKABLE void stopStream();
    Q_INVOKABLE void pauseStream();
    Q_INVOKABLE void resumeStream();
    Q_INVOKABLE void setPlaybackSpeed(double speed);
    Q_INVOKABLE void init(const QString& cameraId, const QString& archiveId);
    Q_INVOKABLE void requestPreviewAt(const QString& cameraId,
                                      const QDateTime& atLocalTime,
                                      const QString& archiveId);
    Q_INVOKABLE bool screenshot(const QString& pathOrDir = "", int quality = 90);
    Q_INVOKABLE void setBufferMaxDurationMs(qint64 ms);
    Q_INVOKABLE void setBufferMaxFrames(int frames);
    Q_INVOKABLE void setBufferMaxBytes(qint64 bytes);
    Q_INVOKABLE bool stepFrameLeft();
    Q_INVOKABLE bool stepFrameRight();
    // Для режима синхронизации набора камер: внешний мастер-таймер в QML вызывает этот метод.
    Q_INVOKABLE void externalSync(const QDateTime& atLocalTime);

    WebSocketClient* client() const { return m_client; }
    void setClient(WebSocketClient* c);
    ImagePipeline* imagePipeline() const { return m_pipeline; }

    bool wsOpen() const { return m_wsOpen; }
    bool    paused() const             { return m_paused; }
    double  playbackSpeed() const      { return m_playbackSpeed; }
    QString currentTime() const        { return m_currentTimeStr; }
    QString currentDate() const        { return m_currentDateStr; }
    QString cameraName() const         { return m_cameraId; }
    QString archiveId() const          { return m_archiveId; }
    QString cameraResolution() const   { return m_cameraResolution; }
    double  currentFPS() const         { return m_currentFPS; }
    QVariantList currentPrimitives() const { return m_currentPrimitives; }
    bool drawPrimitives() const { return m_drawPrimitives; }

    void setCameraName(const QString& id);
    void setArchiveId(const QString& id);
    bool autoInitOnConnect() const { return m_autoInitOnConnect; }
    void setAutoInitOnConnect(bool v);
    bool reinitOnReconnect() const { return m_reinitOnReconnect; }
    void setReinitOnReconnect(bool v);
    void setDrawPrimitives(bool v);
    bool externalClock() const { return m_externalClock; }
    void setExternalClock(bool v);

signals:
    void clientChanged();
    void imagePipelineChanged();
    void frameReadyNv12(const Nv12Frame& frame, const QDateTime& tsUtc);
    void pausedChanged(bool);
    void playbackSpeedChanged(double);
    void currentTimeChanged(const QString&);
    void currentDateChanged(const QString&);
    void currentFPSChanged(double);
    void cameraNameChanged(const QString&);
    void archiveIdChanged(const QString&);
    void cameraResolutionChanged(const QString&);
    void wsOpenChanged(bool);
    void autoInitOnConnectChanged(bool);
    void reinitOnReconnectChanged(bool);
    void screenshotSaved(const QString& path, bool ok, const QString& error);
    void primitivesChanged();
    void drawPrimitivesChanged(bool);
    void externalClockChanged(bool);

public slots:
    void onTextMessage(const QString& msg);
    void onBinaryMessage(const QByteArray& bin);
    void onConnected();
    void onDisconnected();

private slots:
    void onPlaybackTimeout();
    void onGopPacerTick();
    void onParseSegmentsFinished();
    void onDecodeFinished();
    void onPreviewDecodeFinished();

private:
    void sendSegmentAndMetadataRequest(const QJsonObject& segQuery);
    bool tryHandleMetadataMessage(const QJsonValue& dataVal);
    void updatePrimitivesForTime(const QDateTime& utc);
    void prunePrimitiveTimeline(qint64 anchorMs);

    enum class Mode { None, Preview, Realtime };

    struct Window {
        QDateTime fromUtc;
        QDateTime toUtc;
        bool isValid() const { return fromUtc.isValid() && toUtc.isValid() && fromUtc <= toUtc; }
        qint64 widthMs() const { return isValid() ? fromUtc.msecsTo(toUtc) : 0; }
    };

    static QString   toIsoUtcMs(const QDateTime& dt);
    static QDateTime parseIsoUtc(const QString& s);
    static QString   toLocalHMSms(const QDateTime& utc);
    static QString   uniqueFilePath(const QString& desiredPath);
    static qint64    toEpochMs(const QDateTime& utc) { return utc.toMSecsSinceEpoch(); }
    static QDateTime fromEpochMs(qint64 ms) { return QDateTime::fromMSecsSinceEpoch(ms, Qt::UTC); }

    static QDateTime loadLastArchiveTime(const QString& cameraId,
                                         const QString& archiveId);
    static void saveLastArchiveTime(const QString& cameraId,
                                    const QString& archiveId,
                                    const QDateTime& utc);

    int   signDirection() const;
    bool  networkAllowedRealtime() const;
    void  maybeAutoInit();
    QDateTime effectiveAnchorUtc() const;
    void  reevaluateSegmentsWindow();
    Window computeTargetWindow(const QDateTime& centerUtc, double speed) const;
    void  requestSegmentsWindow(const Window& w);
    void  integrateSegmentsList(const QVector<QDateTime>& keysUtc);
    void  pumpNextSegmentRequest();
    void  requestSegmentAtUtc(const QDateTime& atUtc);
    void  requestSegmentAtUtcForced(const QDateTime& atUtc);
    // Single-flight decode with "latest-wins" coalescing (prevents task queue buildup)
    void  startFullDecodeOrQueue(QByteArray&& bin, int generation, qint64 atMs);
    void  startPreviewDecodeOrQueue(QByteArray&& bin, qint64 keyMs);
    void  clearPendingDecodes();
    void  appendDecodedGop(const QDateTime& gopStartUtc,
                          QVector<Nv12Frame>&& frames);
    void  updateTimeStrings(const QDateTime& tsUtc, bool throttled);
    void  updateCurrentFPS(int sampleWindow = 120);
    void  applyTimerInterval();
    qint64 bufferAheadDurationMs() const;
    int    computeGopPaceMs() const;
    void   parseSegmentsAsync(const QJsonArray& arr);
    bool   stepOne(int dir);
    bool   stepToIndex(int idx);
    void   handleSegmentDecodeFailure(qint64 atMs);
    qint64 findNextKnownKeyAfter(qint64 ms) const;
    qint64 findPrevKnownKeyBefore(qint64 ms) const;
    qint64 computeGopEndMsForKey(qint64 keyMs, qint64 anchorMs) const;
    void   pruneDecodedToFrameBuffer();
    void   performDelayStart(quint64 token);
    void   scheduleReevaluate(int delayMs);
    void   scheduleSegmentsWindowRequest(const Window& w, int delayMs);
    void   maybeLogPerfSnapshot(const char* reason);
    void   recordDecodeSample(qint64 elapsedMs);
    void   recordParseSample(qint64 elapsedMs);

private:
    WebSocketClient* m_client {nullptr};
    QString   m_cameraId;
    QString   m_archiveId;
    QString   m_cameraResolution;
    QVariantList m_currentPrimitives;
    QMap<qint64, QVariantList> m_primitivesTimeline;

    bool m_wsOpen = false;
    bool m_autoInitOnConnect { true };
    bool m_reinitOnReconnect { true };
    bool m_autoInitDone { false };
    bool m_drawPrimitives { true };
    QTimer m_autoInitDebounce;

    Mode      m_mode {Mode::None};
    bool      m_running {false};
    bool      m_paused  {true};
    bool      m_externalClock {false};
    QDateTime m_externalClockAtUtc;
    qint64    m_lastExternalSyncMs {0};

    double    m_playbackSpeed {1.0};
    QTimer    m_playbackTimer;
    QTimer    m_gopPacerTimer;

    FrameBuffer   m_frames;
    ImagePipeline* m_pipeline {nullptr};

    QString m_currentTimeStr;
    QString m_currentDateStr;

    double  m_sourceFPS  {0.0};
    double  m_currentFPS {0.0};

    int     m_currentFrameIndex {0};
    Window    m_segmentsWindowRequested;
    bool      m_segmentsListInflight {false};

    std::set<qint64>    m_knownKfMs;
    QMap<qint64,qint64> m_nextKfMs;
    QQueue<qint64>      m_plannedKfQueue;
    QSet<qint64>        m_requestedKfMs;
    QSet<qint64>        m_decodedKfMs;

    bool      m_segmentInflight {false};
    qint64    m_lastRequestedAtMs {0};
    qint64    m_lastSegmentSendMs {0};
    int       m_queueGeneration {0};
    int       m_inflightGeneration {0};
    qint64    m_inflightAtMs {0};
    QDateTime m_currentAtUtc;
    bool      m_previewInflight {false};
    QDateTime m_previewAtUtc;
    QDateTime m_previewSegmentAtUtc;
    qint64    m_defaultGopMs {1000};
    qint64    m_bufMaxDurationMs { 20 * 1000 };
    int       m_bufMaxFrames     { 5400 };
    qint64    m_bufMaxBytes      { 512ll * 1024 * 1024 }; // raw NV12 payload cap
    qint64    m_lowWaterAheadMs   { 1500 };
    qint64    m_targetAheadMs     { 4000 };
    int       m_minGopPaceMs      { 10 };
    int       m_maxGopPaceMs      { 80 };

    QThreadPool m_pool;
    QFutureWatcher<QVector<QDateTime>> m_parseWatcher;
    int m_parseGeneration {0};
    QFutureWatcher<QVector<Nv12Frame>> m_decodeWatcher;
    QFutureWatcher<QVector<Nv12Frame>> m_previewDecodeWatcher;
    struct DecodeJobKey {
        quint64 seq {0};
        int     generation {0};
        qint64  atMs {0};
    };

    quint64 m_fullDecodeSeq {0};
    std::shared_ptr<std::atomic_bool> m_fullDecodeCancel;
    DecodeJobKey m_fullDecodeJob;
    QByteArray   m_pendingFullBin;
    DecodeJobKey m_pendingFullJob;
    bool         m_hasPendingFull {false};

    quint64 m_previewDecodeSeq {0};
    std::shared_ptr<std::atomic_bool> m_previewDecodeCancel;
    DecodeJobKey m_previewDecodeJob;
    QByteArray   m_pendingPreviewBin;
    qint64       m_pendingPreviewKeyMs {0};
    bool         m_hasPendingPreview {false};
    qint64    m_lastWinReqAt {0};
    qint64    m_throttleMarkMs {0};
    qint64    m_lastWindowReqMs {0};
    qint64    m_lastTimeUiUpdateMs {0};
    int       m_pendingStepDir {0};
    QDateTime m_pendingStepAnchorUtc;
    QTimer m_delayDebounceTimer;
    QTimer m_delayGuardTimer;
    QTimer m_reevaluateTimer;
    QTimer m_requestWindowTimer;
    Window m_pendingWindowRequest;
    bool m_hasPendingWindowRequest {false};
    QMetaObject::Connection m_delayConn;
    quint64 m_delayTokenCounter = 0;
    QString m_delayCameraId;
    QString m_delayArchiveId;
    QDateTime m_delayAtLocalTime;
    bool m_delayAutoplay = false;

    struct PerfStats {
        qint64 decodeCount {0};
        qint64 decodeTotalMs {0};
        qint64 decodeMaxMs {0};
        QVector<qint64> decodeSamples;
        qint64 parseCount {0};
        qint64 parseTotalMs {0};
        qint64 parseMaxMs {0};
        QVector<qint64> parseSamples;
    };

    PerfStats m_perfStats;
    bool m_perfDiagnostics {false};
    QElapsedTimer m_perfLogTimer;
    qint64 m_lastPerfLogMs {0};
    QElapsedTimer m_fullDecodeTimer;
    QElapsedTimer m_parseTimer;
};
