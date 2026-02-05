#pragma once

#include <QObject>
#include <QDateTime>
#include <QHash>
#include <QPointer>
#include <QTimer>
#include <QVector>

class ArchiveSegmentStreamer;

class PlaybackCoordinator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
    Q_PROPERTY(QDateTime masterTime READ masterTime WRITE setMasterTime NOTIFY masterTimeChanged)

public:
    explicit PlaybackCoordinator(QObject* parent = nullptr);

    double playbackSpeed() const { return m_playbackSpeed; }
    void setPlaybackSpeed(double speed);

    bool paused() const { return m_paused; }

    QDateTime masterTime() const { return m_masterTime; }
    Q_INVOKABLE void setMasterTime(const QDateTime& dt);

    Q_INVOKABLE void setStreamers(const QVariantList& streamers);
    Q_INVOKABLE void pause();
    Q_INVOKABLE void resume();
    Q_INVOKABLE void step(int dir);
    Q_INVOKABLE void syncTo(const QDateTime& atLocalTime);

signals:
    void playbackSpeedChanged(double);
    void pausedChanged(bool);
    void masterTimeChanged(const QDateTime&);

private:
    void updateExternalClock(bool enabled);
    void startTimer();
    void stopTimer();
    void handlePrimaryFrame(const QDateTime& tsUtc);
    void recoverStalledStreamers(qint64 nowMs);
    ArchiveSegmentStreamer* primaryStreamer() const;
    QVector<ArchiveSegmentStreamer*> validStreamers() const;

    QVector<QPointer<ArchiveSegmentStreamer>> m_streamers;
    QTimer m_masterTimer;
    QDateTime m_masterTime;
    qint64 m_lastTickMs {0};
    qint64 m_lastSyncMs {0};
    double m_playbackSpeed {1.0};
    bool m_paused {true};
    int m_pendingStepDir {0};
    QMetaObject::Connection m_stepConn;
    QVector<QMetaObject::Connection> m_frameReadyConns;
    QHash<ArchiveSegmentStreamer*, qint64> m_lastFrameReadyMs;
    QHash<ArchiveSegmentStreamer*, qint64> m_lastRecoveryMs;
};
