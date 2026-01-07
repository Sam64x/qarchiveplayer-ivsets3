#pragma once

#include <QObject>
#include <QByteArray>
#include <QVector>
#include <QDateTime>
#include <QTimer>
#include <QtGlobal>
#include <atomic>
#include <memory>

#include "Nv12Frame.h"

class VideoSegmentDecoder : public QObject
{
    Q_OBJECT
public:
    struct DecodedNv12 {
        Nv12Frame frame;
        QDateTime tsUtc;
        qint64    ptsMs;
    };

    explicit VideoSegmentDecoder(QObject* parent = nullptr);

    QVector<DecodedNv12> decodeSegmentNV12(const QByteArray& segment);
    DecodedNv12 decodeFirstFrameNV12(const QByteArray& segment);
    void requestAbort() { m_abortRequested.store(true); }
    void setCancelToken(const std::shared_ptr<std::atomic_bool>& token) { m_cancelToken = token; }

public slots:
    void decodeSegmentRealtime(QByteArray bin, QObject* requester,
                               int budgetFrames = 8, int budgetMs = 10);

signals:
    void decodedFrame(QObject* requester, Nv12Frame frame, QDateTime tsUtc);
    void decodedBatch(QObject* requester, QVector<Nv12Frame> frames, QDateTime gopStartUtc);
    void decodeFinished(QObject* requester);

private slots:
    void processTick();

private:
    struct FfCtx;

    bool  ensureOpen();
    bool  readOnePacket();
    bool  receiveOneFrame();
    bool  drainDecoder();
    void  closeAll();
    void  resetAsync();
    bool  shouldAbort() const;

    Nv12Frame makeNv12FromAVFrame(void* avFramePtr);
    bool      convertAnyToNV12(void* avFramePtr, Nv12Frame& out);
    void      packYuv420pToNv12(void* avFramePtr, QByteArray& yOut, QByteArray& uvOut);

    qint64    framePtsMs(void* avFramePtr) const;
    void      finalizeBatch();

private:
    QByteArray   m_bin;
    QObject*     m_requester {nullptr};
    std::atomic_bool m_abortRequested{false};
    std::shared_ptr<std::atomic_bool> m_cancelToken;

    int          m_budgetFrames {8};
    int          m_budgetMs     {10};

    QTimer       m_tick;

    FfCtx*       m_ff {nullptr};

    double       m_firstPtsMs { qQNaN() };
    qint64       m_lastPtsMs  { -1 };

    QVector<Nv12Frame> m_batch;
    QDateTime          m_batchStartUtc;
    int          m_generation {0};
};
