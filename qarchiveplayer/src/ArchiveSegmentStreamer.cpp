#include "ArchiveSegmentStreamer.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFileInfo>
#include <QFile>
#include <QDir>
#include <QCoreApplication>
#include <QRegularExpression>
#include <QDebug>
#include <QtConcurrent/QtConcurrentRun>
#include <QStandardPaths>
#include <QSet>
#include <QSettings>
#include <QDate>
#include <QElapsedTimer>
#include <limits>
#include <iterator>
#include <utility>

static QSet<qint64> s_failedSegments;

static inline QString fmtLocalHMSms(const QDateTime &utc)
{
    return utc.toLocalTime().toString("HH:mm:ss.zzz");
}

static QString archiveTimeKey(const QString& cameraId, const QString& archiveId)
{
    return QStringLiteral("ArchiveSegmentStreamer/%1/%2/lastTimeUtc")
        .arg(cameraId, archiveId);
}

static QSettings makeSettings()
{
    const QString path =
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
        + "/archive_times.ini";
    return QSettings(path, QSettings::IniFormat);
}

QDateTime ArchiveSegmentStreamer::loadLastArchiveTime(const QString& cameraId,
                                                      const QString& archiveId)
{
    QSettings s = makeSettings();
    const QString key = archiveTimeKey(cameraId, archiveId);
    const QString iso = s.value(key).toString();
    if (iso.isEmpty())
        return QDateTime();
    QDateTime utc = ArchiveSegmentStreamer::parseIsoUtc(iso);
    return utc.isValid() ? utc.toUTC() : QDateTime();
}

void ArchiveSegmentStreamer::saveLastArchiveTime(const QString& cameraId,
                                                 const QString& archiveId,
                                                 const QDateTime& utc)
{
    if (!utc.isValid())
        return;
    QSettings s = makeSettings();
    const QString key = archiveTimeKey(cameraId, archiveId);
    s.setValue(key, ArchiveSegmentStreamer::toIsoUtcMs(utc));
    s.sync();
}
QString ArchiveSegmentStreamer::toLocalHMSms(const QDateTime& utc)
{
    return fmtLocalHMSms(utc);
}

QString ArchiveSegmentStreamer::toIsoUtcMs(const QDateTime& dt)
{
    return dt.toUTC().toString("yyyy-MM-dd'T'HH:mm:ss.zzz'Z'");
}

QDateTime ArchiveSegmentStreamer::parseIsoUtc(const QString& s)
{
    return QDateTime::fromString(s, Qt::ISODateWithMs).toUTC();
}

void ArchiveSegmentStreamer::init(const QString& cameraId, const QString& archiveId)
{
    QDateTime savedUtc = loadLastArchiveTime(cameraId, archiveId);

    QDateTime atLocal;
    if (savedUtc.isValid()) {
        atLocal = savedUtc.toLocalTime();
    } else {
        atLocal = QDateTime::currentDateTime().addSecs(-5 * 60);
    }

    requestPreviewAt(cameraId, atLocal, archiveId);
}

void ArchiveSegmentStreamer::setClient(WebSocketClient* client)
{
    if (m_client == client) return;
    if (m_client) {
        disconnect(m_client, nullptr, this, nullptr);
    }
    m_client = client;
    if (m_client) {
        connect(m_client, &WebSocketClient::connected,
                this, &ArchiveSegmentStreamer::onConnected, Qt::QueuedConnection);
        connect(m_client, &WebSocketClient::disconnected,
                this, &ArchiveSegmentStreamer::onDisconnected, Qt::QueuedConnection);
        connect(m_client, &WebSocketClient::textMessageReceived,
                this, &ArchiveSegmentStreamer::onTextMessage, Qt::QueuedConnection);
        connect(m_client, &WebSocketClient::binaryMessageReceived,
                this, &ArchiveSegmentStreamer::onBinaryMessage, Qt::QueuedConnection);
    }
    emit clientChanged();
}

void ArchiveSegmentStreamer::setCameraName(const QString& id)
{
    if (id == m_cameraId) return;
    m_cameraId = id;
    emit cameraNameChanged(m_cameraId);
    maybeAutoInit();
}

void ArchiveSegmentStreamer::setArchiveId(const QString& id)
{
    if (id == m_archiveId) return;
    m_archiveId = id;
    emit archiveIdChanged(m_archiveId);
    maybeAutoInit();
}

void ArchiveSegmentStreamer::setAutoInitOnConnect(bool v)
{
    if (m_autoInitOnConnect == v) return;
    m_autoInitOnConnect = v;
    emit autoInitOnConnectChanged(v);
    if (v) maybeAutoInit();
}

void ArchiveSegmentStreamer::setReinitOnReconnect(bool v)
{
    if (m_reinitOnReconnect == v) return;
    m_reinitOnReconnect = v;
    emit reinitOnReconnectChanged(v);
}

void ArchiveSegmentStreamer::setDrawPrimitives(bool v)
{
    if (m_drawPrimitives == v) return;
    m_drawPrimitives = v;
    emit drawPrimitivesChanged(v);

    if (!m_drawPrimitives) {
        m_primitivesTimeline.clear();
        if (!m_currentPrimitives.isEmpty()) {
            m_currentPrimitives.clear();
            emit primitivesChanged();
        }
    }
}


void ArchiveSegmentStreamer::setExternalClock(bool v)
{
    if (m_externalClock == v) return;
    m_externalClock = v;
    emit externalClockChanged(v);

    // В режиме внешних тиков кадры выбираются снаружи (мастер-таймлайн в QML),
    // поэтому внутренний кадровый таймер должен быть выключен.
    if (m_externalClock) {
        if (m_playbackTimer.isActive())
            m_playbackTimer.stop();
    } else {
        m_externalClockAtUtc = QDateTime();
        m_lastExternalSyncMs = 0;

        if (m_running && !m_paused && m_mode == Mode::Realtime && !qFuzzyCompare(m_playbackSpeed, 0.0)) {
            applyTimerInterval();
            if (!m_playbackTimer.isActive())
                m_playbackTimer.start();
        }
    }
}

QDateTime ArchiveSegmentStreamer::effectiveAnchorUtc() const
{
    if (m_externalClock && m_externalClockAtUtc.isValid())
        return m_externalClockAtUtc;
    return m_currentAtUtc;
}


ArchiveSegmentStreamer::ArchiveSegmentStreamer(WebSocketClient* client, QObject* parent) : ArchiveSegmentStreamer(parent)
{
    setClient(client);
}

ArchiveSegmentStreamer::ArchiveSegmentStreamer(QObject* parent)
    : QObject(parent)
{
    Nv12Frame::registerMetaType();

    m_pool.setMaxThreadCount(qMax(1, qMin(2, QThread::idealThreadCount()-1)));
    m_pool.setExpiryTimeout(-1);

    class LowPriInit : public QRunnable {
    public:
        void run() override { QThread::currentThread()->setPriority(QThread::LowPriority); }
    };
    m_pool.start(new LowPriInit());
    m_pool.waitForDone();

    m_frames.setMaxDurationMs(m_bufMaxDurationMs);
    m_frames.setMaxFrames(m_bufMaxFrames);
    m_frames.setMaxBytes(m_bufMaxBytes);
    m_frames.setDropFromFront(signDirection() >= 0);

    connect(&m_decodeWatcher, &QFutureWatcher<QVector<Nv12Frame>>::finished,
            this, &ArchiveSegmentStreamer::onDecodeFinished);
    connect(&m_previewDecodeWatcher, &QFutureWatcher<QVector<Nv12Frame>>::finished,
            this, &ArchiveSegmentStreamer::onPreviewDecodeFinished);

    connect(&m_playbackTimer, &QTimer::timeout, this, &ArchiveSegmentStreamer::onPlaybackTimeout);
    m_playbackTimer.setTimerType(Qt::PreciseTimer);
    m_playbackTimer.setSingleShot(false);

    connect(&m_gopPacerTimer, &QTimer::timeout, this, &ArchiveSegmentStreamer::onGopPacerTick);
    m_gopPacerTimer.setTimerType(Qt::CoarseTimer);
    m_gopPacerTimer.setInterval(40);
    m_gopPacerTimer.stop();

    connect(&m_parseWatcher, SIGNAL(finished()), this, SLOT(onParseSegmentsFinished()));

    m_reevaluateTimer.setSingleShot(true);
    m_reevaluateTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_reevaluateTimer, &QTimer::timeout, this, [this]() {
        this->reevaluateSegmentsWindow();
    });

    m_requestWindowTimer.setSingleShot(true);
    m_requestWindowTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_requestWindowTimer, &QTimer::timeout, this, [this]() {
        if (!m_hasPendingWindowRequest)
            return;
        const Window pending = m_pendingWindowRequest;
        m_hasPendingWindowRequest = false;
        requestSegmentsWindow(pending);
    });

    m_perfDiagnostics = (qEnvironmentVariableIntValue("ARCHIVE_STREAMER_DIAG") > 0);
    if (m_perfDiagnostics) {
        m_perfLogTimer.start();
        m_perfStats.decodeSamples.reserve(120);
        m_perfStats.parseSamples.reserve(120);
    }
}


void ArchiveSegmentStreamer::setBufferMaxDurationMs(qint64 ms)
{
    m_bufMaxDurationMs = std::max<qint64>(0, ms);
    m_frames.setMaxDurationMs(m_bufMaxDurationMs);
    pruneDecodedToFrameBuffer();
}

void ArchiveSegmentStreamer::setBufferMaxFrames(int frames)
{
    m_bufMaxFrames = std::max(0, frames);
    m_frames.setMaxFrames(m_bufMaxFrames);
    pruneDecodedToFrameBuffer();
}

void ArchiveSegmentStreamer::setBufferMaxBytes(qint64 bytes)
{
    m_bufMaxBytes = std::max<qint64>(0, bytes);
    m_frames.setMaxBytes(m_bufMaxBytes);
    pruneDecodedToFrameBuffer();
}

int ArchiveSegmentStreamer::signDirection() const
{
    if (m_playbackSpeed > 0.0) return +1;
    if (m_playbackSpeed < 0.0) return -1;
    return 0;
}

bool ArchiveSegmentStreamer::networkAllowedRealtime() const
{
    return m_running && m_mode == Mode::Realtime && !m_paused && signDirection() != 0;
}

ArchiveSegmentStreamer::Window
ArchiveSegmentStreamer::computeTargetWindow(const QDateTime& centerUtc, double speed) const
{
    const double absSpd = std::abs(speed);
    const int baseSec = 16;
    const double factor = std::max(0.75, std::min(3.75, 0.75 + 0.75 * (absSpd < 1e-6 ? 1.0 : absSpd)));
    const qint64 spanMs = qint64(double(baseSec) * factor * 1000.0);

    double rightFrac = (absSpd < 1e-6) ? 0.5 : (speed > 0.0 ? 0.7 : 0.3);
    const qint64 rightMs = qint64(double(spanMs) * rightFrac);
    const qint64 leftMs  = spanMs - rightMs;

    Window w;
    w.fromUtc = centerUtc.addMSecs(-leftMs);
    w.toUtc   = centerUtc.addMSecs( rightMs);
    return w;
}

void ArchiveSegmentStreamer::scheduleReevaluate(int delayMs)
{
    if (!m_running || m_mode != Mode::Realtime)
        return;
    if (delayMs <= 0)
        delayMs = 1;
    m_reevaluateTimer.start(delayMs);
}

void ArchiveSegmentStreamer::scheduleSegmentsWindowRequest(const Window& w, int delayMs)
{
    if (!w.isValid())
        return;
    if (delayMs <= 0)
        delayMs = 1;
    m_pendingWindowRequest = w;
    m_hasPendingWindowRequest = true;
    m_requestWindowTimer.start(delayMs);
}

void ArchiveSegmentStreamer::reevaluateSegmentsWindow()
{
    if (!m_running || m_mode != Mode::Realtime) return;

    const QDateTime anchorUtc = effectiveAnchorUtc();
    const Window target = computeTargetWindow(anchorUtc, m_playbackSpeed);
    if (!target.isValid()) return;

    qint64& lastWinReqAt = m_lastWinReqAt;
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();

    if (m_segmentsListInflight) {
        const int staleMs = 1500;
        if (nowMs - lastWinReqAt > staleMs) {
            m_segmentsListInflight = false;
            ++m_parseGeneration;
        } else {
            scheduleReevaluate(60);
            return;
        }
    }

    bool needRequest = false;

    if (!m_segmentsWindowRequested.isValid()) {
        needRequest = true;
    } else {
        const qint64 lastW = m_segmentsWindowRequested.widthMs();
        const qint64 targetW = target.widthMs();

        const qint64 leftMargin  = m_segmentsWindowRequested.fromUtc.msecsTo(anchorUtc);
        const qint64 rightMargin = anchorUtc.msecsTo(m_segmentsWindowRequested.toUtc);

        if (leftMargin < lastW / 4 || rightMargin < lastW / 4) {
            needRequest = true;
        } else if (std::llabs(targetW - lastW) > std::max<qint64>(500, lastW / 3)) {
            needRequest = true;
        } else if (m_segmentsWindowRequested.fromUtc != target.fromUtc ||
                   m_segmentsWindowRequested.toUtc   != target.toUtc) {
            needRequest = true;
        }
    }

    if (!needRequest) return;

    qint64& throttleMarkMs = m_throttleMarkMs;
    const int minGapMs = 140;
    if (nowMs - throttleMarkMs < minGapMs) {
        const int delay = std::max(10, int(minGapMs - (nowMs - throttleMarkMs)));
        scheduleReevaluate(delay);
        return;
    }

    requestSegmentsWindow(target);
    m_segmentsListInflight = true;
    m_segmentsWindowRequested = target;
    lastWinReqAt = nowMs;
    throttleMarkMs = nowMs;
}

void ArchiveSegmentStreamer::requestSegmentsWindow(const Window& w)
{
    if (!m_client || !w.isValid()) return;

    if (m_segmentsListInflight) {
        scheduleSegmentsWindowRequest(w, 80);
        return;
    }

    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const int minGapMs = 120;
    if (now - m_lastWindowReqMs < minGapMs) {
        const int delay = std::max(10, int(minGapMs - (now - m_lastWindowReqMs)));
        scheduleSegmentsWindowRequest(w, delay);
        return;
    }

    if (m_segmentsWindowRequested.isValid()) {
        const qint64 padMs = 800;
        const QDateTime curFrom = m_segmentsWindowRequested.fromUtc.addMSecs(-padMs);
        const QDateTime curTo   = m_segmentsWindowRequested.toUtc.addMSecs(+padMs);
        if (w.fromUtc >= curFrom && w.toUtc <= curTo) {
            return;
        }
    }

    if (m_segmentsWindowRequested.isValid() &&
        m_segmentsWindowRequested.fromUtc == w.fromUtc &&
        m_segmentsWindowRequested.toUtc   == w.toUtc) {
        return;
    }

    QJsonObject query{
        {"camera_id",  m_cameraId},
        {"archive_id", m_archiveId},
        {"from",       toIsoUtcMs(w.fromUtc)},
        {"to",         toIsoUtcMs(w.toUtc)}
    };
    m_client->sendRequest(QJsonObject{{"segments", query}});
    m_segmentsListInflight = true;
    m_segmentsWindowRequested = w;
    m_lastWindowReqMs = now;
}

void ArchiveSegmentStreamer::integrateSegmentsList(const QVector<QDateTime>& keysUtc)
{
    QVector<qint64> ms;
    ms.reserve(keysUtc.size());
    for (const QDateTime& dt : keysUtc) {
        if (dt.isValid())
            ms.append(toEpochMs(dt.toUTC()));
    }
    if (ms.isEmpty())
        return;

    std::sort(ms.begin(), ms.end());
    ms.erase(std::unique(ms.begin(), ms.end()), ms.end());

    for (qint64 v : ms)
        m_knownKfMs.insert(v);
    for (int i = 0; i + 1 < ms.size(); ++i) {
        const qint64 a = ms[i];
        const qint64 b = ms[i + 1];
        if (b > a) m_nextKfMs[a] = b;
    }

    const int dir = signDirection();
    if (dir == 0) return;

    qint64 anchorMs = 0;
    if      (m_currentAtUtc.isValid()) anchorMs = toEpochMs(m_currentAtUtc);
    else if (m_previewSegmentAtUtc.isValid()) anchorMs = toEpochMs(m_previewSegmentAtUtc);
    else if (m_previewAtUtc.isValid()) anchorMs = toEpochMs(m_previewAtUtc);
    else                               anchorMs = ms.first();

    QVector<qint64> local;
    local.reserve(ms.size());
    for (qint64 v : std::as_const(ms))
        local.push_back(v);
    std::sort(local.begin(), local.end());

    int center = int(std::lower_bound(local.begin(), local.end(), anchorMs) - local.begin());
    if (center > 0 && (center >= local.size() ||
        std::llabs(local[center - 1] - anchorMs) < std::llabs(local[center] - anchorMs)))
        center -= 1;
    center = qBound(0, center, local.size() - 1);

    const int backCount  = 6;
    const int aheadCount = 18;

    m_plannedKfQueue.clear();
    if (dir > 0) {
        const int start = center;
        const int stop  = qMin<int>(local.size(), center + aheadCount + 1);
        for (int i = start; i < stop; ++i) {
            const qint64 k = local[i];
            if (m_decodedKfMs.contains(k) || m_requestedKfMs.contains(k) || s_failedSegments.contains(k)) continue;
            m_plannedKfQueue.enqueue(k);
        }
    } else {
        const int start = qMax(0, center - backCount);
        for (int i = center; i >= start; --i) {
            const qint64 k = local[i];
            if (m_decodedKfMs.contains(k) || m_requestedKfMs.contains(k) || s_failedSegments.contains(k)) continue;
            m_plannedKfQueue.enqueue(k);
        }
    }

    if (m_pendingStepDir != 0 && m_pendingStepAnchorUtc.isValid()) {
        const qint64 aMs = toEpochMs(m_pendingStepAnchorUtc);
        qint64 stepKey = (m_pendingStepDir > 0) ? findNextKnownKeyAfter(aMs)
                                                : findPrevKnownKeyBefore(aMs);
        while (stepKey != 0 && s_failedSegments.contains(stepKey)) {
            stepKey = (m_pendingStepDir > 0) ? findNextKnownKeyAfter(stepKey)
                                             : findPrevKnownKeyBefore(stepKey);
        }
        if (stepKey != 0 && !m_decodedKfMs.contains(stepKey) &&
            !m_requestedKfMs.contains(stepKey) && !s_failedSegments.contains(stepKey)) {
            QQueue<qint64> reordered;
            reordered.enqueue(stepKey);
            while (!m_plannedKfQueue.isEmpty()) {
                const qint64 v = m_plannedKfQueue.dequeue();
                if (v != stepKey) reordered.enqueue(v);
            }
            m_plannedKfQueue.swap(reordered);
        }
    }

    const qint64 keepBeforeMs = std::max<qint64>(60 * 1000, m_bufMaxDurationMs * 6);
    const qint64 keepAfterMs  = keepBeforeMs;
    const qint64 minKeep = anchorMs - keepBeforeMs;
    const qint64 maxKeep = anchorMs + keepAfterMs;

    {
        std::set<qint64> pruned;
        for (qint64 v : m_knownKfMs) {
            if (v >= minKeep && v <= maxKeep) pruned.insert(v);
        }
        m_knownKfMs.swap(pruned);
    }
    {
        QMap<qint64,qint64> pruned;
        for (auto it = m_nextKfMs.constBegin(); it != m_nextKfMs.constEnd(); ++it) {
            const qint64 a = it.key();
            const qint64 b = it.value();
            if (a >= minKeep && a <= maxKeep && b >= minKeep && b <= maxKeep)
                pruned.insert(a, b);
        }
        m_nextKfMs.swap(pruned);
    }
    {
        QSet<qint64> pr;
        for (auto it = m_requestedKfMs.constBegin(); it != m_requestedKfMs.constEnd(); ++it) {
            const qint64 v = *it;
            if (v >= minKeep && v <= maxKeep) pr.insert(v);
        }
        m_requestedKfMs.swap(pr);
    }
    {
        QSet<qint64> pf;
        for (auto it = s_failedSegments.constBegin(); it != s_failedSegments.constEnd(); ++it) {
            const qint64 v = *it;
            if (v >= minKeep && v <= maxKeep) pf.insert(v);
        }
        s_failedSegments.swap(pf);
    }

    pruneDecodedToFrameBuffer();
    pumpNextSegmentRequest();
}

qint64 ArchiveSegmentStreamer::bufferAheadDurationMs() const
{
    const int n = m_frames.size();
    if (n <= 0) return 0;

    const QDateTime nowTs = (m_currentFrameIndex >= 0 && m_currentFrameIndex < n)
                                ? m_frames.timeAt(m_currentFrameIndex)
                                : m_frames.timeAt(std::max(0, std::min(m_currentFrameIndex, n-1)));
    if (!nowTs.isValid()) return 0;

    if (signDirection() >= 0) {
        const QDateTime last = m_frames.timeAt(n-1);
        if (!last.isValid()) return 0;
        return nowTs.msecsTo(last);
    } else {
        const QDateTime first = m_frames.timeAt(0);
        if (!first.isValid()) return 0;
        return first.msecsTo(nowTs);
    }
}

int ArchiveSegmentStreamer::computeGopPaceMs() const
{
    const qint64 ahead = bufferAheadDurationMs();
    if (ahead <= 0) return m_minGopPaceMs;
    if (ahead < m_lowWaterAheadMs) return m_minGopPaceMs;
    if (ahead >= m_targetAheadMs) return m_maxGopPaceMs;
    const double t = double(ahead - m_lowWaterAheadMs) / double(std::max<qint64>(1, m_targetAheadMs - m_lowWaterAheadMs));
    const double ms = double(m_minGopPaceMs) * (1.0 - t) + double(m_maxGopPaceMs) * t;
    return std::max(m_minGopPaceMs, std::min(m_maxGopPaceMs, int(ms + 0.5)));
}

void ArchiveSegmentStreamer::pumpNextSegmentRequest()
{
    if (!m_gopPacerTimer.isActive() && m_running && m_mode == Mode::Realtime) {
        m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
    }
}

void ArchiveSegmentStreamer::sendSegmentAndMetadataRequest(const QJsonObject& segQuery)
{
    if (!m_client)
        return;

    m_lastSegmentSendMs = QDateTime::currentMSecsSinceEpoch();
    m_client->sendRequest(QJsonObject{{"segment", segQuery}});

    if (m_drawPrimitives) {
        m_client->sendRequest(QJsonObject{{"metadata", segQuery}});
    }
}

void ArchiveSegmentStreamer::requestSegmentAtUtc(const QDateTime& atUtc)
{
    if (!m_client || !atUtc.isValid()) return;
    if (!networkAllowedRealtime()) return;

    QJsonObject segQuery{
        {"camera_id",  m_cameraId},
        {"archive_id", m_archiveId},
        {"at",         toIsoUtcMs(atUtc.toUTC())}
    };
    sendSegmentAndMetadataRequest(segQuery);
}

void ArchiveSegmentStreamer::requestSegmentAtUtcForced(const QDateTime& atUtc)
{
    if (!m_client || !atUtc.isValid()) return;

    QJsonObject segQuery{
        {"camera_id",  m_cameraId},
        {"archive_id", m_archiveId},
        {"at",         toIsoUtcMs(atUtc.toUTC())}
    };
    sendSegmentAndMetadataRequest(segQuery);
}

void ArchiveSegmentStreamer::onGopPacerTick()
{
    if (!m_running || m_mode != Mode::Realtime) return;

    const int pace = computeGopPaceMs();
    if (m_gopPacerTimer.interval() != pace) m_gopPacerTimer.setInterval(pace);

    if (!networkAllowedRealtime()) return;

    if (bufferAheadDurationMs() >= m_targetAheadMs) return;

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();

    if (m_segmentInflight) {
        const int staleMs = 1500;
        if (m_lastSegmentSendMs != 0 && nowMs - m_lastSegmentSendMs <= staleMs) return;


        m_segmentInflight = false;
        if (m_lastRequestedAtMs != 0) {
            m_requestedKfMs.remove(m_lastRequestedAtMs);
            s_failedSegments.insert(m_lastRequestedAtMs);
            m_lastRequestedAtMs = 0;
        }
        ++m_queueGeneration;
    }

    if (m_plannedKfQueue.isEmpty()) {
        if (!m_segmentsListInflight) {
            reevaluateSegmentsWindow();
            if (!m_segmentsListInflight) {
                Window w = computeTargetWindow(effectiveAnchorUtc(), m_playbackSpeed);
                if (w.isValid()) requestSegmentsWindow(w);
            }
        }
        return;
    }

    while (!m_plannedKfQueue.isEmpty()) {
        const qint64 ms = m_plannedKfQueue.dequeue();
        if (s_failedSegments.contains(ms)) continue;
        if (m_decodedKfMs.contains(ms) || m_requestedKfMs.contains(ms)) continue;

        m_requestedKfMs.insert(ms);
        m_lastRequestedAtMs = ms;
        m_inflightGeneration = m_queueGeneration;
        m_inflightAtMs = ms;

        requestSegmentAtUtc(fromEpochMs(ms));
        m_segmentInflight = true;
        break;
    }

    maybeLogPerfSnapshot("gop_pacer");
}

void ArchiveSegmentStreamer::updateCurrentFPS(int sampleWindow)
{
    const double rawFps = m_frames.calcSourceFPS(sampleWindow);
    const double alpha = 0.18;
    double filteredFps = rawFps;
    if (m_sourceFPS > 0.0 && rawFps > 0.0)
        filteredFps = alpha * rawFps + (1.0 - alpha) * m_sourceFPS;
    if (filteredFps < 0.0) filteredFps = 0.0;

    if (!qFuzzyCompare(filteredFps, m_sourceFPS)) {
        m_sourceFPS = filteredFps;
        const double effFps = (m_paused ? 0.0 : std::abs(m_playbackSpeed) * m_sourceFPS);
        const double effRounded = std::floor(effFps * 100.0 + 0.5) / 100.0;
        if (!qFuzzyCompare(effRounded, m_currentFPS)) {
            m_currentFPS = effRounded;
            emit currentFPSChanged(m_currentFPS);
        }
        applyTimerInterval();
    }
}

void ArchiveSegmentStreamer::applyTimerInterval()
{
    if (m_externalClock) {
        if (m_playbackTimer.isActive())
            m_playbackTimer.stop();
        return;
    }

    if (m_paused || !m_running || qFuzzyCompare(m_playbackSpeed, 0.0)) {
        if (m_playbackTimer.isActive())
            m_playbackTimer.stop();
        return;
    }

    int baseIntervalMs = 40;
    if (m_sourceFPS > 0.0) {
        const double ideal = 1000.0 / m_sourceFPS;
        baseIntervalMs = int(ideal + 0.5);
    }

    const double spd = std::max(0.001, std::abs(m_playbackSpeed));
    const int desiredMs = std::max(1, int(double(baseIntervalMs) / spd));

    static qint64 lastChangeMs = 0;
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();

    if (!m_playbackTimer.isActive()) {
        m_playbackTimer.start(desiredMs);
        lastChangeMs = nowMs;
        return;
    }

    const int currentMs = m_playbackTimer.interval();
    const int delta     = desiredMs - currentMs;
    const int absDelta  = std::abs(delta);
    const double rel    = (currentMs > 0) ? double(absDelta) / double(currentMs) : 1.0;

    if (absDelta <= 1 || rel < 0.05)
        return;

    if (nowMs - lastChangeMs < 60)
        return;

    const int step = (delta > 0 ? +1 : -1) * std::min(5, absDelta);
    const int newInterval = std::max(1, currentMs + step);

    m_playbackTimer.setInterval(newInterval);
    lastChangeMs = nowMs;
}

void ArchiveSegmentStreamer::updateTimeStrings(const QDateTime& tsUtc, bool throttled)
{
    if (!tsUtc.isValid())
        return;

    const qint64 nowMs = tsUtc.toMSecsSinceEpoch();
    const qint64 minUiUpdateGapMs = 33;
    if (throttled && m_lastTimeUiUpdateMs != 0 &&
        std::llabs(nowMs - m_lastTimeUiUpdateMs) < minUiUpdateGapMs) {
        const QString date = tsUtc.toLocalTime().toString("dd.MM.yyyy");
        if (date != m_currentDateStr) {
            m_currentDateStr = date;
            emit currentDateChanged(m_currentDateStr);
        }
        return;
    }

    const QString timeStr = toLocalHMSms(tsUtc);
    if (timeStr != m_currentTimeStr) {
        m_currentTimeStr = timeStr;
        emit currentTimeChanged(m_currentTimeStr);
    }
    const QString dateStr = tsUtc.toLocalTime().toString("dd.MM.yyyy");
    if (dateStr != m_currentDateStr) {
        m_currentDateStr = dateStr;
        emit currentDateChanged(m_currentDateStr);
    }
    m_lastTimeUiUpdateMs = nowMs;
}

void ArchiveSegmentStreamer::delayStart(const QString& cameraId,
                                        const QDateTime& atLocalTime,
                                        const QString& archiveId)
{
    if (cameraId.isEmpty() || archiveId.isEmpty() || !atLocalTime.isValid())
        return;

    m_delayCameraId   = cameraId;
    m_delayArchiveId  = archiveId;
    m_delayAtLocalTime= atLocalTime;
    m_delayAutoplay   = !m_paused;

    ++m_delayTokenCounter;
    const quint64 token = m_delayTokenCounter;

    QObject::disconnect(m_delayConn);
    if (m_delayGuardTimer.isActive()) m_delayGuardTimer.stop();

    if (!m_delayDebounceTimer.parent()) m_delayDebounceTimer.setParent(this);
    m_delayDebounceTimer.setSingleShot(true);
    m_delayDebounceTimer.setTimerType(Qt::CoarseTimer);
    const int debounceMs = (m_running && m_mode == Mode::Realtime) ? 30 : 120;

    QObject::disconnect(m_delayConn);
    QObject::connect(&m_delayDebounceTimer, &QTimer::timeout, this, [this, token]() {
        this->performDelayStart(token);
    });
    m_delayDebounceTimer.start(debounceMs);
}

void ArchiveSegmentStreamer::performDelayStart(quint64 token)
{
    if (token != m_delayTokenCounter)
        return;

    const QString   cameraId    = m_delayCameraId;
    const QString   archiveId   = m_delayArchiveId;
    const QDateTime atLocalTime = m_delayAtLocalTime;
    const bool      shouldAutoplay = m_delayAutoplay;

    if (m_running && m_mode == Mode::Realtime) {
        QObject::disconnect(m_delayConn);
        if (m_delayGuardTimer.isActive()) m_delayGuardTimer.stop();
        startStreamAt(cameraId, atLocalTime, archiveId);
        return;
    }

    stopStream();
    requestPreviewAt(cameraId, atLocalTime, archiveId);

    if (!shouldAutoplay)
        return;

    if (m_mode == Mode::Preview && m_previewAtUtc.isValid() &&
        !m_previewInflight && !m_frames.isEmpty()) {
        startStreamAt(cameraId, atLocalTime, archiveId);
        return;
    }

    const int gen = m_queueGeneration;

    QObject::disconnect(m_delayConn);
    m_delayConn = QObject::connect(this, &ArchiveSegmentStreamer::frameReadyNv12, this,
                                   [this, cameraId, atLocalTime, archiveId, token, gen]() {
                                       if (token != m_delayTokenCounter) return;
                                       if (gen   != m_queueGeneration)  return;
                                       if (m_mode != Mode::Preview)     return;
                                       QObject::disconnect(m_delayConn);
                                       if (m_delayGuardTimer.isActive()) m_delayGuardTimer.stop();
                                       startStreamAt(cameraId, atLocalTime, archiveId);
                                   });

    if (!m_delayGuardTimer.parent()) m_delayGuardTimer.setParent(this);
    m_delayGuardTimer.setSingleShot(true);
    m_delayGuardTimer.setTimerType(Qt::CoarseTimer);
    QObject::connect(&m_delayGuardTimer, &QTimer::timeout, this,
                     [this, cameraId, atLocalTime, archiveId, token, gen]() {
                         if (token != m_delayTokenCounter) return;
                         QObject::disconnect(m_delayConn);
                         startStreamAt(cameraId, atLocalTime, archiveId);
                     });
    m_delayGuardTimer.start(1500);
}

void ArchiveSegmentStreamer::startStreamAt(const QString& cameraId,
                                           const QDateTime& atLocalTime,
                                           const QString& archiveId)
{
    if (!m_client || !atLocalTime.isValid() || cameraId.isEmpty() || archiveId.isEmpty())
        return;

    const QDateTime atUtc = atLocalTime.toUTC();

    const bool wasRealtime = (m_running && m_mode == Mode::Realtime);

    const bool sameSource        = (cameraId == m_cameraId && archiveId == m_archiveId);
    const bool havePreviewBuffer = (m_frames.size() > 0 && m_previewAtUtc.isValid());

    const bool reusePreview      = (sameSource && havePreviewBuffer && !wasRealtime);

    if (!sameSource) {
        m_cameraId  = cameraId;  emit cameraNameChanged(m_cameraId);
        m_archiveId = archiveId;
    }

    m_mode    = Mode::Realtime;
    m_running = true;
    m_frames.setDropFromFront(signDirection() >= 0);

    if (m_perfDiagnostics) {
        m_perfStats = PerfStats{};
        m_perfStats.decodeSamples.reserve(120);
        m_perfStats.parseSamples.reserve(120);
        m_perfLogTimer.restart();
        m_lastPerfLogMs = 0;
    }

    if (m_playbackTimer.isActive()) m_playbackTimer.stop();
    if (m_gopPacerTimer.isActive()) m_gopPacerTimer.stop();
    m_reevaluateTimer.stop();
    m_requestWindowTimer.stop();
    m_hasPendingWindowRequest = false;

    if (m_fullDecodeCancel) m_fullDecodeCancel->store(true);
    if (m_previewDecodeCancel) m_previewDecodeCancel->store(true);
    clearPendingDecodes();

    if (m_parseWatcher.isRunning())         { m_parseWatcher.cancel();         m_parseWatcher.setFuture(QFuture<QVector<QDateTime>>()); }
    if (m_decodeWatcher.isRunning())        { m_decodeWatcher.cancel();        m_decodeWatcher.setFuture(QFuture<QVector<Nv12Frame>>()); }
    if (m_previewDecodeWatcher.isRunning()) { m_previewDecodeWatcher.cancel(); m_previewDecodeWatcher.setFuture(QFuture<QVector<Nv12Frame>>()); }

    ++m_queueGeneration;
    ++m_parseGeneration;

    m_plannedKfQueue.clear();
    m_requestedKfMs.clear();
    if (reusePreview) {
        const qint64 anchorMs = toEpochMs(atUtc);
        const qint64 keepBeforeMs = 90 * 1000;
        const qint64 keepAfterMs  = 90 * 1000;
        const qint64 minKeep = anchorMs - keepBeforeMs;
        const qint64 maxKeep = anchorMs + keepAfterMs;

        {
            std::set<qint64> pruned;
            for (qint64 v : m_knownKfMs) {
                if (v >= minKeep && v <= maxKeep) pruned.insert(v);
            }
            m_knownKfMs.swap(pruned);
        }
        {
            QMap<qint64,qint64> pruned;
            for (auto it = m_nextKfMs.constBegin(); it != m_nextKfMs.constEnd(); ++it) {
                const qint64 a = it.key();
                const qint64 b = it.value();
                if (a >= minKeep && a <= maxKeep && b >= minKeep && b <= maxKeep)
                    pruned.insert(a, b);
            }
            m_nextKfMs.swap(pruned);
        }
        {
            QSet<qint64> pruned;
            for (qint64 v : std::as_const(m_decodedKfMs)) {
                if (v >= minKeep && v <= maxKeep) pruned.insert(v);
            }
            m_decodedKfMs.swap(pruned);
        }
    } else {
        m_decodedKfMs.clear();
        m_knownKfMs.clear();
        m_nextKfMs.clear();
    }

    m_segmentsWindowRequested = Window();
    m_segmentsListInflight = false;
    m_segmentInflight     = false;
    m_lastRequestedAtMs   = 0;
    m_lastSegmentSendMs   = 0;

    m_previewInflight = false;
    m_pendingStepDir = 0;
    m_pendingStepAnchorUtc = QDateTime();

    if (!reusePreview) {
        m_frames.clear();
        m_currentFrameIndex = 0;
        m_currentTimeStr.clear(); emit currentTimeChanged(m_currentTimeStr);
        m_currentDateStr.clear(); emit currentDateChanged(m_currentDateStr);
        m_previewAtUtc = QDateTime();
        m_previewSegmentAtUtc = QDateTime();
    }

    m_paused = false; emit pausedChanged(false);

    m_currentAtUtc = atUtc;
    saveLastArchiveTime(m_cameraId, m_archiveId, atUtc);
    updatePrimitivesForTime(m_currentAtUtc);

    if (!reusePreview) {
        const qint64 atMs = toEpochMs(atUtc);
        if (atMs != 0 && !m_segmentInflight) {
            m_inflightGeneration = m_queueGeneration;
            m_inflightAtMs = atMs;
            m_requestedKfMs.insert(atMs);
            m_lastRequestedAtMs = atMs;
            requestSegmentAtUtcForced(atUtc);
            m_segmentInflight = true;
        }
    } else {
        if (m_frames.size() > 0) {
            int idx = m_frames.nearestIndexGE(m_currentAtUtc);
            if (idx > 0) {
                QDateTime t_ge = m_frames.timeAt(idx);
                QDateTime t_le = m_frames.timeAt(idx - 1);
                qint64 d_ge = t_ge.isValid() ? std::llabs(toEpochMs(t_ge) - toEpochMs(m_currentAtUtc)) : LLONG_MAX;
                qint64 d_le = t_le.isValid() ? std::llabs(toEpochMs(t_le) - toEpochMs(m_currentAtUtc)) : LLONG_MAX;
                if (d_le < d_ge) idx -= 1;
            }
            idx = std::clamp(idx, 0, std::max(0, m_frames.size() - 1));
            if (idx != m_currentFrameIndex) {
                m_currentFrameIndex = idx;
            }
            const QDateTime ts = m_frames.timeAt(idx);
            if (ts.isValid()) {
                m_currentAtUtc = ts;
                emit frameReadyNv12(m_frames.at(idx), ts);
                updatePrimitivesForTime(ts);

                updateTimeStrings(ts, false);

                m_previewAtUtc = ts;
                m_previewSegmentAtUtc = ts;

                const qint64 key = toEpochMs(ts);
                if (key != 0 && !m_segmentInflight &&
                    !m_requestedKfMs.contains(key) &&
                    !m_decodedKfMs.contains(key) &&
                    !s_failedSegments.contains(key)) {
                    m_inflightGeneration = m_queueGeneration;
                    m_inflightAtMs = key;
                    m_requestedKfMs.insert(key);
                    requestSegmentAtUtcForced(ts);
                    m_segmentInflight = true;
                }
            }
        }
    }
    Window w = computeTargetWindow(effectiveAnchorUtc(), m_playbackSpeed);
    if (w.isValid()) requestSegmentsWindow(w);

    if (!m_gopPacerTimer.isActive()) m_gopPacerTimer.start(qMax(1, computeGopPaceMs()));
    updateCurrentFPS();
    applyTimerInterval();
    if (!m_externalClock && !m_playbackTimer.isActive()) m_playbackTimer.start();
}

void ArchiveSegmentStreamer::stopStream()
{
    if (!m_cameraId.isEmpty() &&
        !m_archiveId.isEmpty() &&
        m_currentAtUtc.isValid())
    {
        saveLastArchiveTime(m_cameraId, m_archiveId, m_currentAtUtc);
    }
    m_running = false;
    m_paused  = true;
    emit pausedChanged(true);

    m_playbackTimer.stop();
    m_gopPacerTimer.stop();
    m_reevaluateTimer.stop();
    m_requestWindowTimer.stop();
    m_hasPendingWindowRequest = false;

    if (m_fullDecodeCancel) m_fullDecodeCancel->store(true);
    if (m_previewDecodeCancel) m_previewDecodeCancel->store(true);
    clearPendingDecodes();

    if (m_parseWatcher.isRunning())   m_parseWatcher.cancel();
    if (m_decodeWatcher.isRunning())  m_decodeWatcher.cancel();
    if (m_previewDecodeWatcher.isRunning()) m_previewDecodeWatcher.cancel();

    m_decodeWatcher.setFuture(QFuture<QVector<Nv12Frame>>());
    m_previewDecodeWatcher.setFuture(QFuture<QVector<Nv12Frame>>());

    m_mode = Mode::None;
    m_plannedKfQueue.clear();
    m_requestedKfMs.clear();
    m_decodedKfMs.clear();
    m_knownKfMs.clear();
    m_nextKfMs.clear();

    m_segmentInflight = false;
    m_segmentsListInflight = false;
    m_segmentsWindowRequested = Window();
    m_lastRequestedAtMs = 0;
    m_previewInflight = false;

    if (!m_currentPrimitives.isEmpty()) {
        m_currentPrimitives.clear();
        emit primitivesChanged();
    }

    m_frames.clear();
    updateCurrentFPS();
}

void ArchiveSegmentStreamer::pauseStream()
{
    if (!m_paused) {
        m_paused = true;
        emit pausedChanged(true);
        m_playbackTimer.stop();
        m_gopPacerTimer.stop();
        updateCurrentFPS();
    }
}

void ArchiveSegmentStreamer::resumeStream()
{
    if (m_paused) {
        m_paused = false; emit pausedChanged(false);
        updateCurrentFPS();
        applyTimerInterval();
        if (!m_externalClock) {
            if (!m_playbackTimer.isActive()) m_playbackTimer.start();
        }
        if (m_mode == Mode::Realtime) {
            if (!m_gopPacerTimer.isActive()) m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
        }
    }
}

void ArchiveSegmentStreamer::setPlaybackSpeed(double speed)
{
    if (qFuzzyCompare(speed, m_playbackSpeed))
        return;

    const double old = m_playbackSpeed;
    m_playbackSpeed = speed;
    emit playbackSpeedChanged(m_playbackSpeed);

    const bool newDropFromFront = (signDirection() >= 0);

    // IMPORTANT:
    // FrameBuffer::setDropFromFront() enforces caps immediately.
    // When the playback direction flips, enforcing caps from the *new* side may evict the currently displayed
    // edge frame (usually the newest) and cause an apparent jump (often ~GOP length).
    // We pin the current timestamp, run one enforcement from the side opposite to the pinned frame, then flip
    // the drop side without trimming, and finally restore the index by timestamp.
    if (m_mode == Mode::Realtime && m_running) {
        const bool signFlip = ((old > 0.0) != (speed > 0.0)) &&
                              (!qFuzzyCompare(old, 0.0) || !qFuzzyCompare(speed, 0.0));
        const double ratio = (std::abs(old) < 1e-6)
                                 ? std::abs(speed)
                                 : (std::abs(speed) / std::max(1e-6, std::abs(old)));
        const bool bigChange = (ratio >= 1.5) || (ratio <= (1.0 / 1.5));

        if (signFlip) {
            const int n0 = m_frames.size();
            if (n0 > 1) {
                const int cur0 = std::clamp(m_currentFrameIndex, 0, n0 - 1);
                const QDateTime pinned = m_frames.timeAt(cur0);

                // Choose trimming side so that we drop frames far from the pinned frame first.
                // If pinned is closer to the tail -> drop oldest (front). If closer to the head -> drop newest (back).
                const bool trimFromFront = (cur0 >= (n0 / 2));

                m_frames.setDropFromFront(trimFromFront);             // enforce caps once
                m_frames.setDropFromFrontNoEnforce(newDropFromFront); // flip direction without extra trimming

                // Restore current index by time (prefer <= pinned to avoid jumping forward)
                if (pinned.isValid()) {
                    const int n1 = m_frames.size();
                    if (n1 > 0) {
                        int idx1 = m_frames.nearestIndexGE(pinned);
                        if (idx1 >= n1) idx1 = n1 - 1;
                        if (idx1 > 0) {
                            const QDateTime t = m_frames.timeAt(idx1);
                            if (t.isValid() && t > pinned)
                                idx1 -= 1;
                        }
                        idx1 = std::clamp(idx1, 0, n1 - 1);
                        if (idx1 != m_currentFrameIndex) {
                            m_currentFrameIndex = idx1;
                        }
                    }
                }
            } else {
                m_frames.setDropFromFront(newDropFromFront);
            }
        } else {
            m_frames.setDropFromFront(newDropFromFront);
        }

        // Existing realtime housekeeping when speed changes significantly
        if (signFlip || bigChange) {
            ++m_queueGeneration;

            qint64 anchorMs = 0;
            if      (m_currentAtUtc.isValid()) anchorMs = toEpochMs(m_currentAtUtc);
            else if (m_previewAtUtc.isValid()) anchorMs = toEpochMs(m_previewAtUtc);
            const qint64 keepBeforeMs = 90 * 1000;
            const qint64 keepAfterMs  = 90 * 1000;
            const qint64 minKeep = anchorMs - keepBeforeMs;
            const qint64 maxKeep = anchorMs + keepAfterMs;

            {
                std::set<qint64> pruned;
                for (qint64 v : m_knownKfMs) {
                    if (v >= minKeep && v <= maxKeep) pruned.insert(v);
                }
                m_knownKfMs.swap(pruned);
            }
            {
                QMap<qint64,qint64> pruned;
                for (auto it = m_nextKfMs.constBegin(); it != m_nextKfMs.constEnd(); ++it) {
                    const qint64 a = it.key();
                    const qint64 b = it.value();
                    if (a >= minKeep && a <= maxKeep && b >= minKeep && b <= maxKeep)
                        pruned.insert(a, b);
                }
                m_nextKfMs.swap(pruned);
            }

            m_plannedKfQueue.clear();
            reevaluateSegmentsWindow();

            if (!m_gopPacerTimer.isActive())
                m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
            else
                m_gopPacerTimer.setInterval(std::max(1, computeGopPaceMs()));
        }
    } else {
        m_frames.setDropFromFront(newDropFromFront);
    }

    updateCurrentFPS();

    // After direction changes, frames may have been trimmed while decoded cache stays stale.
    pruneDecodedToFrameBuffer();

    if (!m_paused) {
        if (m_externalClock) {
            m_playbackTimer.stop();
        } else if (qFuzzyCompare(speed, 0.0)) {
            m_playbackTimer.stop();
        } else {
            applyTimerInterval();
            if (!m_playbackTimer.isActive())
                m_playbackTimer.start();
        }
    }

    if (m_mode == Mode::Realtime && m_running) {
        const bool signFlip = ((old > 0.0) != (speed > 0.0)) &&
                              (!qFuzzyCompare(old, 0.0) || !qFuzzyCompare(speed, 0.0));
        const double ratio = (std::abs(old) < 1e-6)
                                 ? std::abs(speed)
                                 : (std::abs(speed) / std::max(1e-6, std::abs(old)));
        const bool bigChange = (ratio >= 1.5) || (ratio <= (1.0 / 1.5));

        if (signFlip || bigChange) {
            ++m_queueGeneration;

            qint64 anchorMs = 0;
            if      (m_currentAtUtc.isValid()) anchorMs = toEpochMs(m_currentAtUtc);
            else if (m_previewAtUtc.isValid()) anchorMs = toEpochMs(m_previewAtUtc);
            const qint64 keepBeforeMs = 90 * 1000;
            const qint64 keepAfterMs  = 90 * 1000;
            const qint64 minKeep = anchorMs - keepBeforeMs;
            const qint64 maxKeep = anchorMs + keepAfterMs;

            {
                std::set<qint64> pruned;
                for (qint64 v : m_knownKfMs) {
                    if (v >= minKeep && v <= maxKeep) pruned.insert(v);
                }
                m_knownKfMs.swap(pruned);
            }
            {
                QMap<qint64,qint64> pruned;
                for (auto it = m_nextKfMs.constBegin(); it != m_nextKfMs.constEnd(); ++it) {
                    const qint64 a = it.key();
                    const qint64 b = it.value();
                    if (a >= minKeep && a <= maxKeep && b >= minKeep && b <= maxKeep)
                        pruned.insert(a, b);
                }
                m_nextKfMs.swap(pruned);
            }

            m_plannedKfQueue.clear();
            reevaluateSegmentsWindow();

            if (!m_gopPacerTimer.isActive())
                m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
            else
                m_gopPacerTimer.setInterval(std::max(1, computeGopPaceMs()));
        }
    }

    if (m_running && !m_paused && m_frames.size() > 0) {
        const int safeIdx = std::clamp(m_currentFrameIndex, 0, m_frames.size() - 1);
        const QDateTime ts = m_frames.timeAt(safeIdx);
        if (ts.isValid()) {
            m_currentAtUtc = ts;
            emit frameReadyNv12(m_frames.at(safeIdx), ts);
            updatePrimitivesForTime(ts);
        }
    }
}

void ArchiveSegmentStreamer::externalSync(const QDateTime& atLocalTime)
{
    if (!m_externalClock)
        return;

    if (!m_running || m_mode != Mode::Realtime)
        return;

    if (!atLocalTime.isValid())
        return;

    m_externalClockAtUtc = atLocalTime.toUTC();

    const int n = m_frames.size();
    if (n > 0) {
        int idx = m_frames.nearestIndexGE(m_externalClockAtUtc);
        if (idx >= n) idx = n - 1;

        if (idx > 0) {
            const QDateTime t = m_frames.timeAt(idx);
            if (t.isValid() && t > m_externalClockAtUtc)
                idx -= 1;
        }

        idx = std::clamp(idx, 0, n - 1);

        if (idx != m_currentFrameIndex) {
            m_currentFrameIndex = idx;
        }

        const QDateTime ts = m_frames.timeAt(m_currentFrameIndex);
        if (ts.isValid()) {
            m_currentAtUtc = ts;
            emit frameReadyNv12(m_frames.at(m_currentFrameIndex), ts);
            updateTimeStrings(ts, false);
            updatePrimitivesForTime(ts);
        }
    }

    if (m_paused)
        return;

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    static const qint64 kMinUpkeepMs = 80;
    if (m_lastExternalSyncMs != 0 && (nowMs - m_lastExternalSyncMs) < kMinUpkeepMs)
        return;
    m_lastExternalSyncMs = nowMs;

    reevaluateSegmentsWindow();
    if (!m_segmentInflight && m_plannedKfQueue.isEmpty() && !m_segmentsListInflight) {
        Window w = computeTargetWindow(effectiveAnchorUtc(), m_playbackSpeed);
        if (w.isValid())
            requestSegmentsWindow(w);
    }

    if (!m_gopPacerTimer.isActive())
        m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
}

void ArchiveSegmentStreamer::onPlaybackTimeout()
{
    if (!m_running || m_paused) return;
    if (m_externalClock) return;

    const int n = m_frames.size();
    if (n <= 0) return;

    int idx = m_currentFrameIndex;
    if (idx < 0) idx = 0;
    if (idx >= n) idx = n - 1;

    if (m_playbackSpeed > 0.0) {
        if (idx + 1 < n) idx += 1;
    } else if (m_playbackSpeed < 0.0) {
        if (idx - 1 >= 0) idx -= 1;
    }

    if (idx != m_currentFrameIndex) {
        m_currentFrameIndex = idx;
    }

    const QDateTime ts = m_frames.timeAt(m_currentFrameIndex);
    if (ts.isValid()) {
        m_currentAtUtc = ts;
        emit frameReadyNv12(m_frames.at(m_currentFrameIndex), ts);
        updateTimeStrings(ts, true);
        updatePrimitivesForTime(ts);
    }

    if (m_mode == Mode::Realtime) {
        reevaluateSegmentsWindow();
        if (!m_segmentInflight && m_plannedKfQueue.isEmpty() && !m_segmentsListInflight) {
            Window w = computeTargetWindow(effectiveAnchorUtc(), m_playbackSpeed);
            if (w.isValid()) requestSegmentsWindow(w);
        }
        if (!m_gopPacerTimer.isActive())
            m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
    }
}

void ArchiveSegmentStreamer::onConnected()
{
    if (!m_wsOpen) { m_wsOpen = true; emit wsOpenChanged(m_wsOpen); }
    maybeAutoInit();

    if (!m_running) return;
    if (m_mode == Mode::Realtime && m_currentAtUtc.isValid()) {
        if (!networkAllowedRealtime()) return;
        if (!m_gopPacerTimer.isActive()) m_gopPacerTimer.start(std::max(1, computeGopPaceMs()));
    }
}

void ArchiveSegmentStreamer::onDisconnected()
{
    if (m_wsOpen) { m_wsOpen = false; emit wsOpenChanged(m_wsOpen); }
    if (m_reinitOnReconnect) {
        m_autoInitDone = false;
    }
}

void ArchiveSegmentStreamer::maybeAutoInit()
{
    if (!m_autoInitOnConnect) return;
    if (!m_wsOpen) return;
    if (m_cameraId.isEmpty() || m_archiveId.isEmpty()) return;

    if (m_running || m_mode != Mode::None) return;

    if (m_autoInitDone) return;

    if (!m_autoInitDebounce.parent())
        m_autoInitDebounce.setParent(this);
    m_autoInitDebounce.setSingleShot(true);
    m_autoInitDebounce.setTimerType(Qt::CoarseTimer);
    m_autoInitDebounce.stop();

    QObject::disconnect(&m_autoInitDebounce, nullptr, this, nullptr);
    connect(&m_autoInitDebounce, &QTimer::timeout, this, [this]() {
        if (!m_wsOpen) return;
        if (m_cameraId.isEmpty() || m_archiveId.isEmpty()) return;
        this->init(m_cameraId, m_archiveId);
        m_autoInitDone = true;
    });
    m_autoInitDebounce.start(0);
}

void ArchiveSegmentStreamer::parseSegmentsAsync(const QJsonArray& arr)
{
    const int myGen = ++m_parseGeneration;
    Q_UNUSED(myGen);

    if (m_parseWatcher.isRunning())
        m_parseWatcher.cancel();

    if (m_perfDiagnostics)
        m_parseTimer.start();

    auto fut = QtConcurrent::run(&m_pool, [arr]() -> QVector<QDateTime> {
        QVector<QDateTime> keys;
        keys.reserve(arr.size());
        for (int i = 0; i < arr.size(); ++i) {
            const QString s = arr.at(i).toString();
            const QDateTime dt = QDateTime::fromString(s, Qt::ISODateWithMs).toUTC();
            if (dt.isValid()) keys.append(dt);
        }
        return keys;
    });
    m_parseWatcher.setFuture(fut);
}

bool ArchiveSegmentStreamer::tryHandleMetadataMessage(const QJsonValue& dataVal)
{
    if (!m_drawPrimitives)
        return false;

    if (!dataVal.isArray())
        return false;

    const QJsonArray outer = dataVal.toArray();
    if (outer.isEmpty())
        return false;

    const bool looksLikeMetadata = outer.first().isArray() || outer.first().isObject();
    if (!looksLikeMetadata)
        return false;

    static const double coordMax = 65535.0;
    QMap<qint64, QVariantList> parsedTimeline;

    auto normalizePoint = [](const QJsonObject& obj) {
        QVariantMap p;
        const double x = obj.value("x").toDouble();
        const double y = obj.value("y").toDouble();
        p.insert("x", qBound(0.0, x / coordMax, 1.0));
        p.insert("y", qBound(0.0, y / coordMax, 1.0));
        return p;
    };

    auto appendLineLike = [&](const QJsonArray& ptsArr, const QString& color, double thickness, QVariantList& prims) {
        if (ptsArr.size() < 2)
            return;

        QVariantList pts;
        pts.reserve(ptsArr.size());
        for (const QJsonValue& pv : ptsArr)
            pts.push_back(normalizePoint(pv.toObject()));

        QVariantMap prim;
        prim.insert("points", pts);
        prim.insert("color", color.isEmpty() ? QStringLiteral("#FFFF0000") : color);
        prim.insert("thickness", thickness <= 0.0 ? 2 : thickness);
        prims.push_back(prim);
    };

    auto appendRectangle = [&](const QJsonObject& rectObj, QVariantList& prims) {
        const QJsonArray ptsArr = rectObj.value("points").toArray();
        if (ptsArr.size() < 2)
            return;

        const QJsonObject p1 = ptsArr.at(0).toObject();
        const QJsonObject p2 = ptsArr.at(1).toObject();

        const double x1 = qBound(0.0, p1.value("x").toDouble(), coordMax);
        const double y1 = qBound(0.0, p1.value("y").toDouble(), coordMax);
        const double x2 = qBound(0.0, p2.value("x").toDouble(), coordMax);
        const double y2 = qBound(0.0, p2.value("y").toDouble(), coordMax);

        const double left   = std::min(x1, x2);
        const double right  = std::max(x1, x2);
        const double top    = std::min(y1, y2);
        const double bottom = std::max(y1, y2);

        QVariantList pts;
        pts.reserve(5);
        pts.push_back(normalizePoint(QJsonObject{{"x", left},  {"y", top   }}));
        pts.push_back(normalizePoint(QJsonObject{{"x", right}, {"y", top   }}));
        pts.push_back(normalizePoint(QJsonObject{{"x", right}, {"y", bottom}}));
        pts.push_back(normalizePoint(QJsonObject{{"x", left},  {"y", bottom}}));
        pts.push_back(normalizePoint(QJsonObject{{"x", left},  {"y", top   }}));

        QVariantMap prim;
        prim.insert("points", pts);
        prim.insert("color", rectObj.value("border_color").toString("#FFFF0000"));
        prim.insert("thickness", rectObj.value("thickness").toInt(2));
        prims.push_back(prim);
    };

    auto consumeObject = [&](const QJsonObject& obj, QVariantList& prims) {
        const QString detectorName = obj.value("detector_name").toString();
        if (detectorName == QLatin1String("PTZServer1"))
            return;
        const QJsonArray objects = obj.value("objects").toArray();
        for (const QJsonValue& v : objects) {
            const QJsonObject o = v.toObject();

            const QJsonObject line = o.value("line").toObject();
            if (!line.isEmpty()) {
                appendLineLike(line.value("points").toArray(),
                               line.value("border_color").toString(),
                               line.value("thickness").toDouble(),
                               prims);
            }

            const QJsonObject rect = o.value("rectangle").toObject();
            if (!rect.isEmpty())
                appendRectangle(rect, prims);
        }
    };

    auto parseTimestamp = [](const QJsonObject& obj) -> QDateTime {
        const QString tStr = obj.value("time").toString();
        QDateTime dt = QDateTime::fromString(tStr, Qt::ISODateWithMs).toUTC();
        if (!dt.isValid())
            dt = QDateTime::fromString(tStr, "yyyy-MM-dd'T'HH:mm:ss.zzz'Z'").toUTC();
        return dt;
    };

    auto flushEntry = [&](const QDateTime& tsUtc, QVariantList&& prims) {
        if (!tsUtc.isValid() || prims.isEmpty())
            return;
        parsedTimeline.insert(toEpochMs(tsUtc), prims);
    };

    for (const QJsonValue& v : outer) {
        if (v.isArray()) {
            const QJsonArray inner = v.toArray();
            QVariantList prims;
            QDateTime ts;
            for (const QJsonValue& iv : inner) {
                if (!iv.isObject())
                    continue;
                const QJsonObject obj = iv.toObject();
                if (!ts.isValid())
                    ts = parseTimestamp(obj);
                consumeObject(obj, prims);
            }
            flushEntry(ts, std::move(prims));
        } else if (v.isObject()) {
            const QJsonObject obj = v.toObject();
            QVariantList prims;
            consumeObject(obj, prims);
            flushEntry(parseTimestamp(obj), std::move(prims));
        }
    }

    if (parsedTimeline.isEmpty())
        return false;

    for (auto it = parsedTimeline.constBegin(); it != parsedTimeline.constEnd(); ++it)
        m_primitivesTimeline.insert(it.key(), it.value());

    const QDateTime anchor = m_currentAtUtc.isValid() ? m_currentAtUtc : m_previewAtUtc;
    updatePrimitivesForTime(anchor);
    return true;
}

void ArchiveSegmentStreamer::prunePrimitiveTimeline(qint64 anchorMs)
{
    const qint64 keepPastMs = anchorMs - 120000;
    const qint64 keepFutureMs = anchorMs + 180000;

    while (!m_primitivesTimeline.isEmpty()) {
        auto it = m_primitivesTimeline.begin();
        if (it.key() < keepPastMs)
            m_primitivesTimeline.erase(it);
        else
            break;
    }

    while (!m_primitivesTimeline.isEmpty()) {
        auto it = std::prev(m_primitivesTimeline.end());
        if (it.key() > keepFutureMs)
            m_primitivesTimeline.erase(it);
        else
            break;
    }

    const int maxEntries = 512;
    while (m_primitivesTimeline.size() > maxEntries)
        m_primitivesTimeline.erase(m_primitivesTimeline.begin());
}

void ArchiveSegmentStreamer::pruneDecodedToFrameBuffer()
{
    if (m_decodedKfMs.isEmpty())
        return;

    const QDateTime firstTs = m_frames.firstTime();
    const QDateTime lastTs = m_frames.lastTime();

    if (!firstTs.isValid() || !lastTs.isValid() || m_frames.isEmpty()) {
        m_decodedKfMs.clear();
        return;
    }

    const qint64 firstMs = toEpochMs(firstTs);
    const qint64 lastMs = toEpochMs(lastTs);
    if (firstMs == 0 || lastMs == 0) {
        m_decodedKfMs.clear();
        return;
    }

    const qint64 marginMs = std::max<qint64>(m_defaultGopMs * 2, 2000);
    const qint64 lo = firstMs - marginMs;
    const qint64 hi = lastMs + marginMs;

    QSet<qint64> pruned;
    for (auto it = m_decodedKfMs.constBegin(); it != m_decodedKfMs.constEnd(); ++it) {
        const qint64 v = *it;
        if (v >= lo && v <= hi)
            pruned.insert(v);
    }
    m_decodedKfMs.swap(pruned);
}

void ArchiveSegmentStreamer::updatePrimitivesForTime(const QDateTime& utc)
{
    if (!m_drawPrimitives)
        return;

    if (!utc.isValid()) {
        if (!m_currentPrimitives.isEmpty()) {
            m_currentPrimitives.clear();
            emit primitivesChanged();
        }
        return;
    }

    const qint64 anchorMs = toEpochMs(utc);
    prunePrimitiveTimeline(anchorMs);

    QVariantList selected;
    if (!m_primitivesTimeline.isEmpty()) {
        auto it = m_primitivesTimeline.upperBound(anchorMs);
        if (it != m_primitivesTimeline.begin()) {
            --it;
            selected = it.value();
        }
    }

    if (selected != m_currentPrimitives) {
        m_currentPrimitives = selected;
        emit primitivesChanged();
    }
}

void ArchiveSegmentStreamer::onTextMessage(const QString& msg)
{
    QJsonParseError e;
    const QJsonDocument doc = QJsonDocument::fromJson(msg.toUtf8(), &e);
    if (e.error != QJsonParseError::NoError || !doc.isObject()) return;
    const QJsonObject o = doc.object();

    if (o.value("type").toString() == QLatin1String("info")) {
        const QJsonObject d = o.value("data").toObject();
        const QString timeStr = d.value("time").toString();
        QDateTime tsUtc = QDateTime::fromString(timeStr, "yyyy.MM.dd HH:mm:ss.zzz");
        tsUtc.setTimeSpec(Qt::UTC);
        const QString newDate = tsUtc.toLocalTime().toString("dd.MM.yyyy");
        if (newDate != m_currentDateStr) { m_currentDateStr = newDate; emit currentDateChanged(m_currentDateStr); }
        const int w = d.value("width").toInt();
        const int h = d.value("height").toInt();
        const QString res = QString("%1×%2").arg(w).arg(h);
        if (res != m_cameraResolution) { m_cameraResolution = res; emit cameraResolutionChanged(m_cameraResolution); }
        return;
    }

    if (o.value("status") == QLatin1String("error")) {
        qint64 badKeyMs = 0;

        if (m_previewInflight) {
            m_previewInflight = false;
            if (m_previewSegmentAtUtc.isValid())
                badKeyMs = toEpochMs(m_previewSegmentAtUtc);
            else if (m_previewAtUtc.isValid())
                badKeyMs = toEpochMs(m_previewAtUtc);
        }

        if (m_segmentInflight) {
            m_segmentInflight = false;
            if (m_lastRequestedAtMs != 0)
                badKeyMs = m_lastRequestedAtMs;
            else if (m_inflightAtMs != 0)
                badKeyMs = m_inflightAtMs;
        }

        if (badKeyMs != 0) {
            s_failedSegments.insert(badKeyMs);
            m_requestedKfMs.remove(badKeyMs);
            if (badKeyMs == m_lastRequestedAtMs) m_lastRequestedAtMs = 0;
        }

        if (m_mode == Mode::Preview) {
            while (!m_plannedKfQueue.isEmpty()) {
                const qint64 next = m_plannedKfQueue.dequeue();
                if (s_failedSegments.contains(next)) continue;
                m_previewSegmentAtUtc = fromEpochMs(next);
                QJsonObject segQuery{
                    {"camera_id",  m_cameraId},
                    {"archive_id", m_archiveId},
                    {"at",         toIsoUtcMs(m_previewSegmentAtUtc)}
                };
                sendSegmentAndMetadataRequest(segQuery);
                m_previewInflight = true;
                m_inflightGeneration = m_queueGeneration;
                m_inflightAtMs = next;
                m_requestedKfMs.insert(next);
                m_lastRequestedAtMs = next;
                break;
            }
        } else if (m_mode == Mode::Realtime) {
            pumpNextSegmentRequest();
        }
        return;
    }

    if (o.value("status") != QLatin1String("ok")) return;
    if (!o.contains("data")) return;

    const QJsonValue dataVal = o.value("data");

    if (tryHandleMetadataMessage(dataVal))
        return;

    if (m_mode == Mode::Preview) {
        QJsonArray arr;
        if (dataVal.isArray()) {
            arr = dataVal.toArray();
        } else if (dataVal.isObject()) {
            const QJsonObject dataObj = dataVal.toObject();
            if (dataObj.contains("segments") && dataObj.value("segments").isArray())
                arr = dataObj.value("segments").toArray();
        }

        auto shouldAcceptSegmentsPreview = [this](const QJsonArray& a)->bool {
            if (a.isEmpty()) return false;
            QDateTime minUtc, maxUtc;
            for (const auto& v: a) {
                const QDateTime dt = QDateTime::fromString(v.toString(), Qt::ISODateWithMs).toUTC();
                if (!dt.isValid()) continue;
                if (!minUtc.isValid() || dt < minUtc) minUtc = dt;
                if (!maxUtc.isValid() || dt > maxUtc) maxUtc = dt;
            }
            if (!minUtc.isValid() || !maxUtc.isValid()) return false;
            if (!m_previewAtUtc.isValid()) return true;
            return !(m_previewAtUtc < minUtc.addMSecs(-2000) || m_previewAtUtc > maxUtc.addMSecs(+2000));
        };

        if (!arr.isEmpty() && shouldAcceptSegmentsPreview(arr)) {
            QVector<QDateTime> keys;
            keys.reserve(arr.size());
            for (int i = 0; i < arr.size(); ++i) {
                const QDateTime dt = QDateTime::fromString(arr.at(i).toString(), Qt::ISODateWithMs).toUTC();
                if (dt.isValid()) keys.append(dt);
            }
            if (!keys.isEmpty()) {
                std::sort(keys.begin(), keys.end());
                integrateSegmentsList(keys);

                const qint64 anchor = toEpochMs(m_previewAtUtc);
                int best = 0;
                qint64 bestDist = std::numeric_limits<qint64>::max();
                for (int i = 0; i < keys.size(); ++i) {
                    const qint64 d = std::llabs(toEpochMs(keys[i]) - anchor);
                    if (d < bestDist) { bestDist = d; best = i; }
                }
                const QDateTime chosen = keys[qBound(0, best, keys.size() - 1)];

                m_plannedKfQueue.clear();
                if (best - 1 >= 0 && !s_failedSegments.contains(toEpochMs(keys[best - 1])))
                    m_plannedKfQueue.enqueue(toEpochMs(keys[best - 1]));
                if (best + 1 < keys.size() && !s_failedSegments.contains(toEpochMs(keys[best + 1])))
                    m_plannedKfQueue.enqueue(toEpochMs(keys[best + 1]));

                m_previewSegmentAtUtc = chosen;

                const qint64 chosenMs = toEpochMs(chosen);
                if (m_decodedKfMs.contains(chosenMs) || m_requestedKfMs.contains(chosenMs) ||
                    s_failedSegments.contains(chosenMs)) {
                    m_segmentsListInflight = false;
                    return;
                }
                QJsonObject segQuery{
                    {"camera_id",  m_cameraId},
                    {"archive_id", m_archiveId},
                    {"at",         toIsoUtcMs(chosen)}
                };
                sendSegmentAndMetadataRequest(segQuery);
                m_previewInflight = true;

                m_inflightGeneration = m_queueGeneration;
                m_inflightAtMs       = chosenMs;
                m_requestedKfMs.insert(chosenMs);
                m_lastRequestedAtMs  = chosenMs;

                m_segmentsListInflight = false;
                return;
            }
        }

        if (m_previewSegmentAtUtc.isValid() && !m_previewInflight) {
            const qint64 key = toEpochMs(m_previewSegmentAtUtc);
            if (!s_failedSegments.contains(key) &&
                !m_requestedKfMs.contains(key) &&
                !m_decodedKfMs.contains(key)) {
                QJsonObject segQuery{
                    {"camera_id",  m_cameraId},
                    {"archive_id", m_archiveId},
                    {"at",         toIsoUtcMs(m_previewSegmentAtUtc)}
                };
                sendSegmentAndMetadataRequest(segQuery);
                m_previewInflight = true;
                m_inflightGeneration = m_queueGeneration;
                m_inflightAtMs = key;
                m_requestedKfMs.insert(key);
                m_lastRequestedAtMs = key;
            }
        }
        return;
    }

    if (dataVal.isArray()) {
        const QJsonArray arr = dataVal.toArray();

        auto shouldAcceptSegments = [this](const QJsonArray& arr)->bool {
            if (arr.isEmpty()) return false;
            QDateTime minUtc, maxUtc;
            for (const auto& v: arr) {
                const QDateTime dt = QDateTime::fromString(v.toString(), Qt::ISODateWithMs).toUTC();
                if (!dt.isValid()) continue;
                if (!minUtc.isValid() || dt < minUtc) minUtc = dt;
                if (!maxUtc.isValid() || dt > maxUtc) maxUtc = dt;
            }
            if (!minUtc.isValid() || !maxUtc.isValid()) return false;
            const QDateTime cur = m_currentAtUtc.isValid() ? m_currentAtUtc : m_previewAtUtc;
            if (!cur.isValid()) return true;
            return !(cur < minUtc.addMSecs(-2000) || cur > maxUtc.addMSecs(+2000));
        };

        if (shouldAcceptSegments(arr)) {
            parseSegmentsAsync(arr);
        }
        return;
    }

    if (dataVal.isObject()) {
        const QJsonObject dataObj = dataVal.toObject();
        if (dataObj.contains("segments") && dataObj.value("segments").isArray()) {
            const QJsonArray arr = dataObj.value("segments").toArray();

            auto shouldAcceptSegments = [this](const QJsonArray& arr)->bool {
                if (arr.isEmpty()) return false;
                QDateTime minUtc, maxUtc;
                for (const auto& v: arr) {
                    const QDateTime dt = QDateTime::fromString(v.toString(), Qt::ISODateWithMs).toUTC();
                    if (!dt.isValid()) continue;
                    if (!minUtc.isValid() || dt < minUtc) minUtc = dt;
                    if (!maxUtc.isValid() || dt > maxUtc) maxUtc = dt;
                }
                if (!minUtc.isValid() || !maxUtc.isValid()) return false;
                const QDateTime cur = m_currentAtUtc.isValid() ? m_currentAtUtc : m_previewAtUtc;
                if (!cur.isValid()) return true;
                return !(cur < minUtc.addMSecs(-2000) || cur > maxUtc.addMSecs(+2000));
            };

            if (shouldAcceptSegments(arr)) {
                parseSegmentsAsync(arr);
            }
            return;
        }
    }

}

void ArchiveSegmentStreamer::clearPendingDecodes()
{
    m_hasPendingFull = false;
    m_pendingFullBin.clear();
    m_pendingFullJob = DecodeJobKey{};

    m_hasPendingPreview = false;
    m_pendingPreviewBin.clear();
    m_pendingPreviewKeyMs = 0;
}

void ArchiveSegmentStreamer::startFullDecodeOrQueue(QByteArray&& bin, int generation, qint64 atMs)
{
    DecodeJobKey job;
    job.seq = ++m_fullDecodeSeq;
    job.generation = generation;
    job.atMs = atMs;

    if (m_decodeWatcher.isRunning()) {
        if (m_fullDecodeCancel) m_fullDecodeCancel->store(true);
        m_pendingFullBin = std::move(bin);
        m_pendingFullJob = job;
        m_hasPendingFull = true;
        return;
    }

    m_fullDecodeJob = job;
    m_fullDecodeCancel = std::make_shared<std::atomic_bool>(false);
    const auto cancel = m_fullDecodeCancel;
    if (m_perfDiagnostics)
        m_fullDecodeTimer.start();

    QFuture<QVector<Nv12Frame>> fut = QtConcurrent::run(&m_pool, [bin = std::move(bin), cancel]() mutable {
        if (cancel && cancel->load()) return QVector<Nv12Frame>{};

        VideoSegmentDecoder dec;
        const QVector<VideoSegmentDecoder::DecodedNv12> decoded = dec.decodeSegmentNV12(bin);

        if (cancel && cancel->load()) return QVector<Nv12Frame>{};

        QVector<Nv12Frame> frames;
        frames.reserve(decoded.size());
        for (const auto& nv : decoded)
            frames.append(nv.frame);

        if (cancel && cancel->load()) return QVector<Nv12Frame>{};
        return frames;
    });

    m_decodeWatcher.setFuture(fut);
}

void ArchiveSegmentStreamer::startPreviewDecodeOrQueue(QByteArray&& bin, qint64 keyMs)
{
    DecodeJobKey job;
    job.seq = ++m_previewDecodeSeq;
    job.generation = m_queueGeneration;
    job.atMs = keyMs;

    if (m_previewDecodeWatcher.isRunning()) {
        if (m_previewDecodeCancel) m_previewDecodeCancel->store(true);
        m_pendingPreviewBin = std::move(bin);
        m_pendingPreviewKeyMs = keyMs;
        m_hasPendingPreview = true;
        return;
    }

    m_previewDecodeJob = job;
    m_previewDecodeCancel = std::make_shared<std::atomic_bool>(false);
    const auto cancel = m_previewDecodeCancel;

    QFuture<QVector<Nv12Frame>> fut = QtConcurrent::run(&m_pool, [bin = std::move(bin), cancel]() mutable {
        if (cancel && cancel->load()) return QVector<Nv12Frame>{};

        VideoSegmentDecoder dec;
        const VideoSegmentDecoder::DecodedNv12 first = dec.decodeFirstFrameNV12(bin);

        if (cancel && cancel->load()) return QVector<Nv12Frame>{};

        QVector<Nv12Frame> frames;
        if (first.frame.isValid())
            frames.append(first.frame);
        return frames;
    });

    m_previewDecodeWatcher.setFuture(fut);
}

void ArchiveSegmentStreamer::onBinaryMessage(const QByteArray& bin)
{
    if (!m_previewInflight && !m_segmentInflight)
        return;

    if (m_previewInflight) {
        if (m_mode != Mode::Preview) {
            m_previewInflight = false;
            return;
        }

        const qint64 keyMs = m_previewSegmentAtUtc.isValid()
                                 ? toEpochMs(m_previewSegmentAtUtc)
                                 : (m_previewAtUtc.isValid() ? toEpochMs(m_previewAtUtc) : m_inflightAtMs);
        startPreviewDecodeOrQueue(QByteArray(bin), keyMs);

        m_previewInflight = false;
        m_segmentInflight = true;

        if (keyMs != 0) {
            m_inflightGeneration = m_queueGeneration;
            m_inflightAtMs = keyMs;
            m_requestedKfMs.insert(keyMs);
            m_lastRequestedAtMs = keyMs;
        }

        startFullDecodeOrQueue(QByteArray(bin), m_inflightGeneration, m_inflightAtMs);
        return;
    }

    startFullDecodeOrQueue(QByteArray(bin), m_inflightGeneration, m_inflightAtMs);
}

void ArchiveSegmentStreamer::requestPreviewAt(const QString& cameraId,
                                              const QDateTime& atLocalTime,
                                              const QString& archiveId)
{
    if (!m_client || cameraId.isEmpty() || archiveId.isEmpty() || !atLocalTime.isValid())
        return;

    m_mode    = Mode::Preview;
    m_paused  = true;
    m_running = true;
    m_reevaluateTimer.stop();
    m_requestWindowTimer.stop();
    m_hasPendingWindowRequest = false;

    if (m_perfDiagnostics) {
        m_perfStats = PerfStats{};
        m_perfStats.decodeSamples.reserve(120);
        m_perfStats.parseSamples.reserve(120);
        m_perfLogTimer.restart();
        m_lastPerfLogMs = 0;
    }

    ++m_queueGeneration;
    ++m_parseGeneration;

    if (m_fullDecodeCancel) m_fullDecodeCancel->store(true);
    if (m_previewDecodeCancel) m_previewDecodeCancel->store(true);
    clearPendingDecodes();

    m_cameraId  = cameraId;
    m_archiveId = archiveId;
    emit cameraNameChanged(m_cameraId);

    m_previewAtUtc   = atLocalTime.toUTC();
    m_previewSegmentAtUtc = m_previewAtUtc;
    saveLastArchiveTime(m_cameraId, m_archiveId, m_previewAtUtc);
    m_currentAtUtc   = QDateTime();
    m_currentTimeStr.clear();
    m_currentDateStr.clear();
    updateTimeStrings(m_previewAtUtc, false);
    updatePrimitivesForTime(m_previewAtUtc);

    m_pendingStepDir       = 0;
    m_pendingStepAnchorUtc = QDateTime();
    m_plannedKfQueue.clear();
    m_requestedKfMs.clear();
    m_decodedKfMs.clear();
    m_knownKfMs.clear();
    m_nextKfMs.clear();

    m_segmentsWindowRequested = Window();
    m_segmentsListInflight = false;
    m_segmentInflight     = false;
    m_lastRequestedAtMs   = 0;

    m_inflightAtMs       = 0;
    m_inflightGeneration = m_queueGeneration;
    m_previewInflight    = false;

    m_frames.clear();
    m_currentFrameIndex = 0;

    const qint64 span = std::max<qint64>(8000, m_defaultGopMs * 4);
    QDateTime fromUtc = m_previewAtUtc.addMSecs(-span);
    QDateTime toUtc   = m_previewAtUtc.addMSecs(+span);
    QJsonObject query{
        {"camera_id",  m_cameraId},
        {"archive_id", m_archiveId},
        {"from",       toIsoUtcMs(fromUtc)},
        {"to",         toIsoUtcMs(toUtc)}
    };
    m_client->sendRequest(QJsonObject{{"segments", query}});
    m_segmentsListInflight = true;
}

bool ArchiveSegmentStreamer::stepOne(int dir)
{
    if (dir == 0)
        return false;

    const int n = m_frames.size();
    if (n > 0) {
        int target = m_currentFrameIndex + (dir > 0 ? 1 : -1);
        if (target >= 0 && target < n) {
            return stepToIndex(target);
        }
    }

    QDateTime anchor;
    if (m_currentAtUtc.isValid()) {
        anchor = m_currentAtUtc;
    } else if (n > 0) {
        anchor = (dir > 0 ? m_frames.timeAt(n - 1) : m_frames.timeAt(0));
    } else if (m_previewAtUtc.isValid()) {
        anchor = m_previewAtUtc;
    } else {
        anchor = QDateTime::currentDateTimeUtc();
    }

    m_pendingStepDir       = dir;
    m_pendingStepAnchorUtc = anchor;

    if (m_segmentInflight) {
        return true;
    }

    const qint64 aMs = toEpochMs(anchor);
    qint64 keyMs = (dir > 0 ? findNextKnownKeyAfter(aMs) : findPrevKnownKeyBefore(aMs));
    while (keyMs != 0 && s_failedSegments.contains(keyMs)) {
        keyMs = (dir > 0 ? findNextKnownKeyAfter(keyMs) : findPrevKnownKeyBefore(keyMs));
    }

    if (keyMs != 0) {
        if (!m_decodedKfMs.contains(keyMs) &&
            !m_requestedKfMs.contains(keyMs) &&
            !s_failedSegments.contains(keyMs))
        {
            m_inflightGeneration = m_queueGeneration;
            m_inflightAtMs = keyMs;
            m_requestedKfMs.insert(keyMs);
            if (m_previewInflight)
                m_previewInflight = false;
            requestSegmentAtUtcForced(fromEpochMs(keyMs));
            m_segmentInflight = true;
        }
        return true;
    }

    const qint64 span = std::max<qint64>(4000, m_defaultGopMs * 2);
    Window w;
    w.fromUtc = fromEpochMs(aMs - span);
    w.toUtc   = fromEpochMs(aMs + span);
    requestSegmentsWindow(w);
    return true;
}


bool ArchiveSegmentStreamer::stepFrameLeft()
{
    return stepOne(-1);
}

bool ArchiveSegmentStreamer::stepFrameRight()
{
    return stepOne(+1);
}


void ArchiveSegmentStreamer::appendDecodedGop(const QDateTime& gopStartUtc,
                                              QVector<Nv12Frame>&& frames)
{
    if (!gopStartUtc.isValid() || frames.isEmpty())
        return;

    m_frames.setDropFromFront(signDirection() >= 0);

    const qint64 startMs = toEpochMs(gopStartUtc);
    qint64 endMs = 0;
    auto it = m_nextKfMs.constFind(startMs);
    if (it != m_nextKfMs.constEnd() && it.value() > startMs) {
        endMs = it.value();
    } else {
        const double fps = (m_sourceFPS > 1e-6 ? m_sourceFPS : 25.0);
        const qint64 approx = startMs + qint64((1000.0 / std::max(1.0, fps)) * frames.size());
        endMs = std::max(startMs + 1, approx);
    }

    qint64 writeFrom = startMs;
    qint64 writeTo   = endMs;

    if (!m_paused) {
        const QDateTime firstTs = m_frames.firstTime();
        const QDateTime lastTs  = m_frames.lastTime();
        const int dir = signDirection();
        if (dir >= 0) {
            if (lastTs.isValid())
                writeFrom = std::max(writeFrom, toEpochMs(lastTs) + 1);
        } else {
            if (firstTs.isValid())
                writeTo = std::min(writeTo, toEpochMs(firstTs));
        }
    }
    if (writeFrom >= writeTo)
        return;

    const qint64 spanMs = writeTo - writeFrom;
    const int inCount = frames.size();
    const qint64 stepMs = std::max<qint64>(1, spanMs / std::max(1, inCount));

    QVector<QDateTime> ts;
    ts.reserve(inCount);

    qint64 t = writeFrom;
    int outCount = 0;
    for (int i = 0; i < inCount; ++i) {
        if (t >= writeTo)
            break;
        ts.append(QDateTime::fromMSecsSinceEpoch(t, Qt::UTC));
        ++outCount;
        const qint64 next = t + stepMs;
        t = (next >= writeTo ? writeTo - 1 : next);
    }
    if (outCount <= 0)
        return;

    QVector<Nv12Frame> batch;
    batch.reserve(outCount);
    for (int i = 0; i < outCount; ++i)
        batch.append(std::move(frames[i]));

    m_frames.appendBatch(std::move(batch), ts);
    pruneDecodedToFrameBuffer();

    if (m_currentAtUtc.isValid()) {
        const int ge = m_frames.nearestIndexGE(m_currentAtUtc);
        int best = ge;
        if (ge > 0) {
            const QDateTime t_ge = m_frames.timeAt(ge);
            const QDateTime t_le = m_frames.timeAt(ge - 1);
            const qint64 d_ge = t_ge.isValid() ? std::llabs(toEpochMs(t_ge) - toEpochMs(m_currentAtUtc))
                                               : std::numeric_limits<qint64>::max();
            const qint64 d_le = t_le.isValid() ? std::llabs(toEpochMs(t_le) - toEpochMs(m_currentAtUtc))
                                               : std::numeric_limits<qint64>::max();
            if (d_le < d_ge)
                best = ge - 1;
        }
        if (best >= 0) {
            m_currentFrameIndex = best;
        }
    }

    if (m_pendingStepDir != 0 && m_pendingStepAnchorUtc.isValid()) {
        const int dir = (m_pendingStepDir > 0 ? +1 : -1);
        const QDateTime anchor = m_pendingStepAnchorUtc;

        int idx = m_frames.nearestIndexGE(anchor);
        if (dir < 0) {
            idx = (idx > 0 ? idx - 1 : -1);
        } else {
            if (idx < m_frames.size() && m_frames.timeAt(idx) <= anchor)
                idx++;
        }

        if (idx >= 0 && idx < m_frames.size()) {
            stepToIndex(idx);
            m_pendingStepDir = 0;
            m_pendingStepAnchorUtc = QDateTime();
        }
    }

    if (m_mode != Mode::Preview) {
        const int n = m_frames.size();
        if (n > 0) {
            const int safeIdx = std::clamp(m_currentFrameIndex, 0, n - 1);
            const QDateTime nowTs = m_frames.timeAt(safeIdx);
            if (nowTs.isValid()) {
                m_currentAtUtc = nowTs;
                emit frameReadyNv12(m_frames.at(safeIdx), nowTs);
                updatePrimitivesForTime(nowTs);

                const QString tstr = toLocalHMSms(nowTs);
                if (tstr != m_currentTimeStr) {
                    m_currentTimeStr = tstr;
                    emit currentTimeChanged(m_currentTimeStr);
                }
                const QString dstr = nowTs.toLocalTime().toString("dd.MM.yyyy");
                if (dstr != m_currentDateStr) {
                    m_currentDateStr = dstr;
                    emit currentDateChanged(m_currentDateStr);
                }
            }
        }
    }

    updateCurrentFPS();
    applyTimerInterval();
}

void ArchiveSegmentStreamer::onParseSegmentsFinished()
{
    if (!m_parseWatcher.isFinished())
        return;
    QVector<QDateTime> keys = m_parseWatcher.result();
    m_segmentsListInflight = false;
    if (m_perfDiagnostics && m_parseTimer.isValid())
        recordParseSample(m_parseTimer.elapsed());
    if (!keys.isEmpty()) {
        integrateSegmentsList(keys);
    }
    if (m_mode == Mode::Realtime) {
        reevaluateSegmentsWindow();
    }

    if (m_mode == Mode::Preview && !m_segmentInflight) {
        qint64 anchorMs = 0;
        if (m_currentAtUtc.isValid()) {
            anchorMs = toEpochMs(m_currentAtUtc);
        } else if (m_previewSegmentAtUtc.isValid()) {
            anchorMs = toEpochMs(m_previewSegmentAtUtc);
        } else if (m_previewAtUtc.isValid()) {
            anchorMs = toEpochMs(m_previewAtUtc);
        }
        if (anchorMs != 0) {
            qint64 key = findPrevKnownKeyBefore(anchorMs + 1);
            if (key != 0 &&
                !m_decodedKfMs.contains(key) &&
                !m_requestedKfMs.contains(key) &&
                !s_failedSegments.contains(key))
            {
                m_inflightGeneration = m_queueGeneration;
                m_inflightAtMs = key;
                m_requestedKfMs.insert(key);
                requestSegmentAtUtcForced(fromEpochMs(key));
                m_segmentInflight = true;
                return;
            }
        }
    }

    maybeLogPerfSnapshot("segments_parse");
}


void ArchiveSegmentStreamer::onDecodeFinished()
{
    if (!m_decodeWatcher.isFinished())
        return;
    const DecodeJobKey job = m_fullDecodeJob;
    const auto cancel = m_fullDecodeCancel;

    QVector<Nv12Frame> frames;
    if (!m_decodeWatcher.future().isCanceled())
        frames = m_decodeWatcher.result();

    if (m_perfDiagnostics && m_fullDecodeTimer.isValid())
        recordDecodeSample(m_fullDecodeTimer.elapsed());

    const bool dropped = (cancel && cancel->load())
                         || m_decodeWatcher.future().isCanceled()
                         || (job.generation != m_queueGeneration)
                         || (job.atMs == 0);

    m_segmentInflight = false;

    if (dropped) {
        if (job.atMs != 0)
            m_requestedKfMs.remove(job.atMs);
    } else if (frames.isEmpty()) {
        handleSegmentDecodeFailure(job.atMs);
    } else {
        appendDecodedGop(fromEpochMs(job.atMs), std::move(frames));
        m_requestedKfMs.remove(job.atMs);
        m_decodedKfMs.insert(job.atMs);

        if (m_mode == Mode::Preview) {
            if (!m_segmentInflight) {
                qint64 anchorMs = 0;
                if (m_currentAtUtc.isValid()) {
                    anchorMs = toEpochMs(m_currentAtUtc);
                } else if (m_previewSegmentAtUtc.isValid()) {
                    anchorMs = toEpochMs(m_previewSegmentAtUtc);
                } else if (m_previewAtUtc.isValid()) {
                    anchorMs = toEpochMs(m_previewAtUtc);
                }

                auto haveOrRequest = [&](int direction) -> bool {
                    const int want = (direction > 0 ? 3 : 1);
                    int have = 0;
                    qint64 last = anchorMs;
                    qint64 firstMissing = 0;

                    for (int i = 0; i < want; ++i) {
                        const qint64 k = (direction > 0)
                                             ? findNextKnownKeyAfter(last)
                                             : findPrevKnownKeyBefore(last);
                        if (k == 0) {
                            firstMissing = 0;
                            break;
                        }
                        if (!m_decodedKfMs.contains(k) &&
                            !m_requestedKfMs.contains(k) &&
                            !s_failedSegments.contains(k))
                        {
                            firstMissing = k;
                            break;
                        }
                        have++;
                        last = k;
                    }

                    if (firstMissing != 0) {
                        m_inflightGeneration = m_queueGeneration;
                        m_inflightAtMs = firstMissing;
                        m_requestedKfMs.insert(firstMissing);
                        requestSegmentAtUtcForced(fromEpochMs(firstMissing));
                        m_segmentInflight = true;
                        return true;
                    }

                    if (have < want && !m_segmentsListInflight) {
                        const qint64 span = std::max<qint64>(8000, m_defaultGopMs * 4);
                        Window w;
                        w.fromUtc = fromEpochMs(anchorMs - span);
                        w.toUtc   = fromEpochMs(anchorMs + span);
                        requestSegmentsWindow(w);
                        m_segmentsListInflight = true;
                    }
                    return false;
                };

                if (m_pendingStepDir < 0) {
                    if (!haveOrRequest(-1))
                        haveOrRequest(+1);
                } else {
                    if (!haveOrRequest(+1))
                        haveOrRequest(-1);
                }
            }
        } else if (m_mode == Mode::Realtime) {
            reevaluateSegmentsWindow();
            if (!m_segmentInflight && m_plannedKfQueue.isEmpty() && !m_segmentsListInflight) {
                const Window w = computeTargetWindow(effectiveAnchorUtc(), m_playbackSpeed);
                if (w.isValid())
                    requestSegmentsWindow(w);
            }
            pumpNextSegmentRequest();
        }
    }

    if (!m_segmentInflight && m_hasPendingFull) {
        QByteArray nextBin = std::move(m_pendingFullBin);
        const DecodeJobKey nextJob = m_pendingFullJob;
        m_hasPendingFull = false;
        m_pendingFullBin.clear();
        m_pendingFullJob = DecodeJobKey{};

        m_segmentInflight = true;
        startFullDecodeOrQueue(std::move(nextBin), nextJob.generation, nextJob.atMs);
    } else {
        pumpNextSegmentRequest();
    }

    maybeLogPerfSnapshot("decode_finish");
}

void ArchiveSegmentStreamer::onPreviewDecodeFinished()
{
    if (!m_previewDecodeWatcher.isFinished())
        return;

    const auto cancel = m_previewDecodeCancel;
    const bool dropped = (m_mode != Mode::Preview)
                         || (cancel && cancel->load())
                         || m_previewDecodeWatcher.future().isCanceled();

    QVector<Nv12Frame> frames;
    if (!dropped)
        frames = m_previewDecodeWatcher.result();

    m_previewInflight = false;

    const QDateTime tsUtc = m_previewSegmentAtUtc.isValid()
                                ? m_previewSegmentAtUtc
                                : (m_previewAtUtc.isValid() ? m_previewAtUtc : QDateTime::currentDateTimeUtc());

    if (!dropped && !frames.isEmpty() && frames.first().isValid()) {
        const Nv12Frame& f = frames.first();
        m_frames.clear();
        m_frames.appendBatch(QVector<Nv12Frame>{f}, QVector<QDateTime>{tsUtc});
        m_currentFrameIndex = 0;
        m_currentAtUtc = tsUtc;
        emit frameReadyNv12(f, tsUtc);
        updatePrimitivesForTime(m_previewAtUtc.isValid() ? m_previewAtUtc : tsUtc);
    } else {
        if (tsUtc.isValid()) {
            m_currentAtUtc = tsUtc;
            updatePrimitivesForTime(m_previewAtUtc.isValid() ? m_previewAtUtc : tsUtc);
        }
    }

    if (m_hasPendingPreview) {
        QByteArray nextBin = std::move(m_pendingPreviewBin);
        const qint64 nextKey = m_pendingPreviewKeyMs;
        m_hasPendingPreview = false;
        m_pendingPreviewBin.clear();
        m_pendingPreviewKeyMs = 0;
        startPreviewDecodeOrQueue(std::move(nextBin), nextKey);
        return;
    }

    const qint64 key = m_previewSegmentAtUtc.isValid() ? toEpochMs(m_previewSegmentAtUtc) : 0;
    if (key != 0 && !m_previewInflight && !m_segmentInflight &&
        !m_requestedKfMs.contains(key) && !m_decodedKfMs.contains(key) && !s_failedSegments.contains(key))
    {
        m_inflightGeneration = m_queueGeneration;
        m_inflightAtMs = key;
        m_requestedKfMs.insert(key);
        requestSegmentAtUtcForced(m_previewSegmentAtUtc);
        m_segmentInflight = true;
    } else if (key != 0 && s_failedSegments.contains(key)) {
        while (!m_plannedKfQueue.isEmpty()) {
            const qint64 next = m_plannedKfQueue.dequeue();
            if (s_failedSegments.contains(next)) continue;
            m_inflightGeneration = m_queueGeneration;
            m_inflightAtMs = next;
            m_requestedKfMs.insert(next);
            requestSegmentAtUtcForced(fromEpochMs(next));
            m_segmentInflight = true;
            break;
        }
    }
}

bool ArchiveSegmentStreamer::stepToIndex(int idx)
{
    const int n = m_frames.size();
    if (n <= 0) return false;
    if (idx < 0) idx = 0;
    if (idx >= n) idx = n - 1;
    if (idx == m_currentFrameIndex) {
        const QDateTime ts = m_frames.timeAt(idx);
        if (ts.isValid()) {
            emit frameReadyNv12(m_frames.at(idx), ts);
            updatePrimitivesForTime(ts);
        }
        return false;
    }

    const int prevIdx = m_currentFrameIndex;

    m_currentFrameIndex = idx;

    const QDateTime ts = m_frames.timeAt(m_currentFrameIndex);
    if (ts.isValid()) {
        m_currentAtUtc = ts;
        emit frameReadyNv12(m_frames.at(m_currentFrameIndex), ts);
        updatePrimitivesForTime(ts);

        updateTimeStrings(ts, false);
    }

    if (m_mode == Mode::Preview && !m_segmentInflight) {
        const int dir = (m_currentFrameIndex > prevIdx ? +1 : -1);
        const qint64 nowMs = (ts.isValid() ? toEpochMs(ts) : 0);
        if (nowMs != 0) {
            const qint64 gopStart = findPrevKnownKeyBefore(nowMs + 1);
            qint64 neighborKey = 0;
            if (gopStart != 0) {
                neighborKey = (dir > 0) ? findNextKnownKeyAfter(gopStart)
                                        : findPrevKnownKeyBefore(gopStart);
            }
            if (neighborKey == 0 && !m_segmentsListInflight) {
                const qint64 span = std::max<qint64>(8000, m_defaultGopMs * 4);
                Window w;
                w.fromUtc = fromEpochMs(nowMs - span);
                w.toUtc   = fromEpochMs(nowMs + span);
                requestSegmentsWindow(w);
                m_segmentsListInflight = true;
            } else if (neighborKey != 0 &&
                       !m_decodedKfMs.contains(neighborKey) &&
                       !m_requestedKfMs.contains(neighborKey) &&
                       !s_failedSegments.contains(neighborKey)) {
                m_inflightGeneration = m_queueGeneration;
                m_inflightAtMs = neighborKey;
                m_requestedKfMs.insert(neighborKey);
                requestSegmentAtUtcForced(fromEpochMs(neighborKey));
                m_segmentInflight = true;
            }
        }
    }

    return true;
}

void ArchiveSegmentStreamer::handleSegmentDecodeFailure(qint64 atMs)
{
    if (atMs != 0) {
        s_failedSegments.insert(atMs);
        m_requestedKfMs.remove(atMs);
        if (m_lastRequestedAtMs == atMs)
            m_lastRequestedAtMs = 0;
        if (m_inflightAtMs == atMs)
            m_inflightAtMs = 0;
    }

    if (m_mode == Mode::Preview) {
        while (!m_plannedKfQueue.isEmpty()) {
            const qint64 next = m_plannedKfQueue.dequeue();
            if (s_failedSegments.contains(next))
                continue;
            if (m_requestedKfMs.contains(next))
                continue;

            m_inflightGeneration = m_queueGeneration;
            m_inflightAtMs = next;
            m_requestedKfMs.insert(next);
            m_lastRequestedAtMs = next;
            requestSegmentAtUtcForced(fromEpochMs(next));
            m_segmentInflight = true;
            return;
        }
    } else if (m_mode == Mode::Realtime) {
        pumpNextSegmentRequest();
    }
}

qint64 ArchiveSegmentStreamer::findNextKnownKeyAfter(qint64 ms) const
{
    auto it = m_knownKfMs.upper_bound(ms);
    return (it == m_knownKfMs.end()) ? 0 : *it;
}

qint64 ArchiveSegmentStreamer::findPrevKnownKeyBefore(qint64 ms) const
{
    auto it = m_knownKfMs.lower_bound(ms);
    if (it == m_knownKfMs.begin())
        return 0;
    --it;
    return *it;
}

qint64 ArchiveSegmentStreamer::computeGopEndMsForKey(qint64 keyMs, qint64 anchorMs) const
{
    qint64 next = findNextKnownKeyAfter(keyMs);
    if (next == 0 || next > anchorMs) next = anchorMs;
    if (next <= keyMs) next = keyMs + 1;
    return next;
}

void ArchiveSegmentStreamer::recordDecodeSample(qint64 elapsedMs)
{
    if (elapsedMs < 0)
        return;
    m_perfStats.decodeCount += 1;
    m_perfStats.decodeTotalMs += elapsedMs;
    m_perfStats.decodeMaxMs = std::max(m_perfStats.decodeMaxMs, elapsedMs);
    if (m_perfStats.decodeSamples.size() >= 120)
        m_perfStats.decodeSamples.remove(0);
    m_perfStats.decodeSamples.push_back(elapsedMs);
}

void ArchiveSegmentStreamer::recordParseSample(qint64 elapsedMs)
{
    if (elapsedMs < 0)
        return;
    m_perfStats.parseCount += 1;
    m_perfStats.parseTotalMs += elapsedMs;
    m_perfStats.parseMaxMs = std::max(m_perfStats.parseMaxMs, elapsedMs);
    if (m_perfStats.parseSamples.size() >= 120)
        m_perfStats.parseSamples.remove(0);
    m_perfStats.parseSamples.push_back(elapsedMs);
}

void ArchiveSegmentStreamer::maybeLogPerfSnapshot(const char* reason)
{
    if (!m_perfDiagnostics)
        return;
    if (!m_perfLogTimer.isValid())
        m_perfLogTimer.start();
    const qint64 nowMs = m_perfLogTimer.elapsed();
    const qint64 minGapMs = 2000;
    if (nowMs - m_lastPerfLogMs < minGapMs)
        return;
    m_lastPerfLogMs = nowMs;

    auto percentile = [](QVector<qint64> samples, double p) -> qint64 {
        if (samples.isEmpty())
            return 0;
        std::sort(samples.begin(), samples.end());
        const int idx = std::clamp(int(std::ceil(p * samples.size())) - 1, 0, samples.size() - 1);
        return samples[idx];
    };

    const qint64 decodeAvg = (m_perfStats.decodeCount > 0)
                                 ? (m_perfStats.decodeTotalMs / m_perfStats.decodeCount)
                                 : 0;
    const qint64 parseAvg = (m_perfStats.parseCount > 0)
                                ? (m_perfStats.parseTotalMs / m_perfStats.parseCount)
                                : 0;

    const qint64 decodeP95 = percentile(m_perfStats.decodeSamples, 0.95);
    const qint64 parseP95 = percentile(m_perfStats.parseSamples, 0.95);

    qInfo().noquote()
        << "ArchiveSegmentStreamer perf"
        << "reason=" << reason
        << "decode(ms avg/p95/max)=" << decodeAvg << "/" << decodeP95 << "/" << m_perfStats.decodeMaxMs
        << "parse(ms avg/p95/max)=" << parseAvg << "/" << parseP95 << "/" << m_perfStats.parseMaxMs
        << "frames=" << m_frames.size()
        << "frameBytes=" << m_frames.bytes()
        << "planned=" << m_plannedKfQueue.size()
        << "requested=" << m_requestedKfMs.size()
        << "decoded=" << m_decodedKfMs.size()
        << "known=" << m_knownKfMs.size()
        << "primitives=" << m_primitivesTimeline.size()
        << "segmentInflight=" << (m_segmentInflight ? 1 : 0)
        << "segmentsListInflight=" << (m_segmentsListInflight ? 1 : 0);
}

static QString safeName(const QString& s) {
    static const QRegularExpression bad(R"([<>:"/\\|?*\x00-\x1F])");
    QString out = s; return out.replace(bad, "_").simplified();
}

static QString ensureExtension(const QString& path, const char* ext)
{
    QFileInfo fi(path);
    if (fi.suffix().isEmpty())
        return fi.absolutePath() + "/" + fi.completeBaseName() + "." + ext;
    return fi.absoluteFilePath();
}

QString ArchiveSegmentStreamer::uniqueFilePath(const QString &desiredPath)
{
    QFileInfo fi(desiredPath);
    const QString dir  = fi.absolutePath();
    const QString base = fi.completeBaseName();
    const QString ext  = fi.suffix().isEmpty() ? QStringLiteral("jpg") : fi.suffix();

    QString candidate = QDir(dir).filePath(base + "." + ext);
    if (!QFileInfo::exists(candidate)) return candidate;

    for (int i = 1; i < 10000; ++i) {
        QString cand = QDir(dir).filePath(QString("%1_%2.%3").arg(base).arg(i).arg(ext));
        if (!QFileInfo::exists(cand)) return cand;
    }
    return candidate;
}

bool ArchiveSegmentStreamer::screenshot(const QString& pathOrDir, int quality)
{
    if (m_frames.size() <= 0) { emit screenshotSaved(pathOrDir, false, "Нет кадров"); return false; }

    const int idx = std::max(0, std::min(m_currentFrameIndex, m_frames.size()-1));
    const Nv12Frame fr = m_frames.at(idx);
    if (!fr.isValid()) { emit screenshotSaved(pathOrDir, false, "Пустой кадр"); return false; }

    QImage img;
    if (m_pipeline) {
        img = m_pipeline->toImage(fr);
    } else {
        ImagePipeline tmp;
        img = tmp.toImage(fr);
    }

    const QDateTime ts = m_frames.timeAt(idx);
    const QString tsStr = (ts.isValid() ? ts : QDateTime::currentDateTimeUtc())
                              .toLocalTime()
                              .toString("yyyy-MM-dd'T'HH_mm_ss");
    const QString baseFileName = safeName(QString("%1_%2.jpg")
                                              .arg(m_cameraId.isEmpty() ? "camera" : m_cameraId, tsStr));

    QString outPath;

    const QString dateSubdir = QDate::currentDate().toString("yyyy-MM-dd");

    if (pathOrDir.trimmed().isEmpty()) {
        QString baseDir;
#ifdef Q_OS_WIN
        baseDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
#else
        baseDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
#endif
        if (baseDir.isEmpty())
            baseDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);

        const QString targetDir = QDir(baseDir).filePath(dateSubdir);
        QDir().mkpath(targetDir);

        outPath = QDir(targetDir).filePath(baseFileName);
    }
    else {
        QFileInfo fi(pathOrDir);
        const bool treatAsDir = fi.isDir() || (!fi.exists() && fi.suffix().isEmpty());

        if (treatAsDir) {
            const QString targetDir = QDir(fi.absoluteFilePath()).filePath(dateSubdir);
            QDir().mkpath(targetDir);
            outPath = QDir(targetDir).filePath(baseFileName);
        } else {
            outPath = ensureExtension(fi.absoluteFilePath(), "jpg");
            QDir(fi.absolutePath()).mkpath(".");
        }
    }

    outPath = uniqueFilePath(outPath);

    const bool ok = img.save(outPath, "JPG", quality);
    if (ok) {
        qDebug() << "screenshot saved dir:" << outPath;
    } else {
        qDebug() << "screenshot save failed path:" << outPath;
    }
    emit screenshotSaved(outPath, ok, ok ? QString() : QStringLiteral("Ошибка сохранения"));
    return ok;
}
