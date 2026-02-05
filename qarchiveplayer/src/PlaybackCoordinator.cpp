#include "PlaybackCoordinator.h"

#include "ArchiveSegmentStreamer.h"

#include <QtGlobal>

PlaybackCoordinator::PlaybackCoordinator(QObject* parent)
    : QObject(parent)
{
    m_masterTimer.setTimerType(Qt::PreciseTimer);
    m_masterTimer.setInterval(40);
    m_masterTimer.setSingleShot(false);
    connect(&m_masterTimer, &QTimer::timeout, this, [this]() {
        if (m_paused)
            return;
        if (!m_masterTime.isValid())
            m_masterTime = QDateTime::currentDateTime();

        const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
        if (m_lastTickMs == 0)
            m_lastTickMs = nowMs;
        const qint64 dt = nowMs - m_lastTickMs;
        m_lastTickMs = nowMs;

        if (dt > 0 && !qFuzzyIsNull(m_playbackSpeed)) {
            m_masterTime = m_masterTime.addMSecs(qint64(double(dt) * m_playbackSpeed));
            emit masterTimeChanged(m_masterTime);
            syncTo(m_masterTime);
        }
        recoverStalledStreamers(nowMs);
    });
}

void PlaybackCoordinator::setStreamers(const QVariantList& streamers)
{
    m_streamers.clear();
    for (const QMetaObject::Connection& conn : std::as_const(m_frameReadyConns))
        QObject::disconnect(conn);
    m_frameReadyConns.clear();
    m_lastFrameReadyMs.clear();
    m_lastRecoveryMs.clear();
    m_streamers.reserve(streamers.size());
    for (const QVariant& v : streamers) {
        auto* streamer = qobject_cast<ArchiveSegmentStreamer*>(v.value<QObject*>());
        if (streamer) {
            m_streamers.push_back(streamer);
            const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
            m_lastFrameReadyMs.insert(streamer, nowMs);
            m_frameReadyConns.push_back(QObject::connect(
                streamer, &ArchiveSegmentStreamer::frameReadyNv12, this,
                [this, streamer](const Nv12Frame&, const QDateTime&) {
                    m_lastFrameReadyMs.insert(streamer, QDateTime::currentMSecsSinceEpoch());
                },
                Qt::QueuedConnection));
        }
    }
}

void PlaybackCoordinator::setPlaybackSpeed(double speed)
{
    if (qFuzzyCompare(m_playbackSpeed, speed))
        return;
    m_playbackSpeed = speed;
    emit playbackSpeedChanged(m_playbackSpeed);
    for (ArchiveSegmentStreamer* streamer : validStreamers()) {
        streamer->setPlaybackSpeed(m_playbackSpeed);
    }
}

void PlaybackCoordinator::setMasterTime(const QDateTime& dt)
{
    if (!dt.isValid())
        return;
    if (m_masterTime.isValid() && m_masterTime == dt)
        return;
    m_masterTime = dt;
    m_lastSyncMs = 0;
    emit masterTimeChanged(m_masterTime);
}

void PlaybackCoordinator::pause()
{
    if (m_paused)
        return;
    m_paused = true;
    emit pausedChanged(true);
    stopTimer();
    updateExternalClock(false);
    for (ArchiveSegmentStreamer* streamer : validStreamers())
        streamer->pauseStream();
}

void PlaybackCoordinator::resume()
{
    if (!m_paused)
        return;
    m_paused = false;
    emit pausedChanged(false);
    updateExternalClock(true);
    for (ArchiveSegmentStreamer* streamer : validStreamers())
        streamer->resumeStream();
    startTimer();
}

void PlaybackCoordinator::step(int dir)
{
    ArchiveSegmentStreamer* primary = primaryStreamer();
    if (!primary || dir == 0)
        return;

    stopTimer();
    updateExternalClock(false);
    m_pendingStepDir = dir;

    QObject::disconnect(m_stepConn);
    m_stepConn = QObject::connect(primary, &ArchiveSegmentStreamer::frameReadyNv12, this,
                                  [this](const Nv12Frame&, const QDateTime& tsUtc) {
                                      this->handlePrimaryFrame(tsUtc);
                                  },
                                  Qt::QueuedConnection);

    if (dir < 0)
        primary->stepFrameLeft();
    else
        primary->stepFrameRight();
}

void PlaybackCoordinator::syncTo(const QDateTime& atLocalTime)
{
    if (!atLocalTime.isValid())
        return;
    const qint64 targetMs = atLocalTime.toMSecsSinceEpoch();
    if (targetMs == m_lastSyncMs)
        return;
    m_lastSyncMs = targetMs;
    for (ArchiveSegmentStreamer* streamer : validStreamers())
        streamer->externalSync(atLocalTime);
}

void PlaybackCoordinator::updateExternalClock(bool enabled)
{
    for (ArchiveSegmentStreamer* streamer : validStreamers())
        streamer->setExternalClock(enabled);
}

void PlaybackCoordinator::startTimer()
{
    m_lastTickMs = 0;
    if (!m_masterTimer.isActive())
        m_masterTimer.start();
}

void PlaybackCoordinator::stopTimer()
{
    if (m_masterTimer.isActive())
        m_masterTimer.stop();
    m_lastTickMs = 0;
}

void PlaybackCoordinator::handlePrimaryFrame(const QDateTime& tsUtc)
{
    QObject::disconnect(m_stepConn);
    m_pendingStepDir = 0;
    if (tsUtc.isValid()) {
        m_masterTime = tsUtc.toLocalTime();
        emit masterTimeChanged(m_masterTime);
        for (ArchiveSegmentStreamer* streamer : validStreamers()) {
            if (streamer == primaryStreamer())
                continue;
            const qint64 frameMs = streamer->currentFrameTimeMs();
            if (frameMs == 0 || frameMs != tsUtc.toMSecsSinceEpoch()) {
                streamer->requestPreviewAt(streamer->cameraName(), tsUtc.toLocalTime(), streamer->archiveId());
            }
        }
    }
    updateExternalClock(true);
    if (!m_paused)
        startTimer();
}

void PlaybackCoordinator::recoverStalledStreamers(qint64 nowMs)
{
    if (m_paused || !m_masterTime.isValid())
        return;

    static const qint64 kStallThresholdMs = 4000;
    static const qint64 kRecoveryCooldownMs = 6000;

    for (ArchiveSegmentStreamer* streamer : validStreamers()) {
        if (!streamer)
            continue;
        const auto state = streamer->state();
        if (state != ArchiveSegmentStreamer::StreamState::Realtime &&
            state != ArchiveSegmentStreamer::StreamState::Syncing) {
            continue;
        }
        const qint64 lastFrameMs = m_lastFrameReadyMs.value(streamer, 0);
        if (lastFrameMs != 0 && (nowMs - lastFrameMs) < kStallThresholdMs)
            continue;
        const qint64 lastRecoverMs = m_lastRecoveryMs.value(streamer, 0);
        if (lastRecoverMs != 0 && (nowMs - lastRecoverMs) < kRecoveryCooldownMs)
            continue;

        m_lastRecoveryMs.insert(streamer, nowMs);
        streamer->startStreamAt(streamer->cameraName(), m_masterTime, streamer->archiveId());
        streamer->setPlaybackSpeed(m_playbackSpeed);
        streamer->externalSync(m_masterTime);
    }
}

ArchiveSegmentStreamer* PlaybackCoordinator::primaryStreamer() const
{
    for (const QPointer<ArchiveSegmentStreamer>& streamer : m_streamers) {
        if (streamer)
            return streamer;
    }
    return nullptr;
}

QVector<ArchiveSegmentStreamer*> PlaybackCoordinator::validStreamers() const
{
    QVector<ArchiveSegmentStreamer*> out;
    out.reserve(m_streamers.size());
    for (const QPointer<ArchiveSegmentStreamer>& streamer : m_streamers) {
        if (streamer)
            out.push_back(streamer);
    }
    return out;
}
