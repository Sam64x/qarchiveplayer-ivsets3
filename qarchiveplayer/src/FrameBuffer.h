#pragma once

#include <QVector>
#include <QDateTime>
#include <QReadWriteLock>
#include <algorithm>
#include <utility>
#include <limits>
#include "Nv12Frame.h"

/**
 * Thread-safe time-sorted buffer of decoded NV12 frames.
 *
 * Caps:
 *  - maxFrames      : hard limit by count
 *  - maxDurationMs  : hard limit by time span (first..last)
 *  - maxBytes       : hard limit by estimated raw payload bytes (Y+UV)
 *
 * Notes:
 *  - For forward playback (append at back) setDropFromFront(true) to evict oldest frames.
 *  - For reverse playback (prepend/insert at front) setDropFromFront(false) to evict newest frames.
 */
class FrameBuffer
{
public:
    FrameBuffer() = default;

    void clear() {
        QWriteLocker lk(&m_lock);
        m_ts.clear();
        m_frames.clear();
        m_totalBytes = 0;
        // release container capacity on hard reset (stream restart / mode switch)
        m_ts.squeeze();
        m_frames.squeeze();
    }

    void shrinkToFit() {
        QWriteLocker lk(&m_lock);
        m_ts.squeeze();
        m_frames.squeeze();
    }

    void setDropFromFront(bool front) {
        QWriteLocker lk(&m_lock);
        m_dropFromFront = front;
        enforceCapsUnlocked();
    }

    // Switch eviction direction without immediate trimming.
    // Useful when caller wants to preserve the currently displayed frame while changing direction:
    // run one cap enforcement from a chosen side first, then only flip the drop side.
    void setDropFromFrontNoEnforce(bool front) {
        QWriteLocker lk(&m_lock);
        m_dropFromFront = front;
    }

    void setCapacityHint(int capacity) {
        if (capacity <= 0) return;
        QWriteLocker lk(&m_lock);
        m_ts.reserve(capacity);
        m_frames.reserve(capacity);
    }

    void setMaxFrames(int maxFrames) {
        QWriteLocker lk(&m_lock);
        m_maxFrames = std::max(0, maxFrames);
        enforceCapsUnlocked();
    }

    void setMaxDurationMs(qint64 maxDurationMs) {
        QWriteLocker lk(&m_lock);
        m_maxDurationMs = std::max<qint64>(0, maxDurationMs);
        enforceCapsUnlocked();
    }

    void setMaxBytes(qint64 maxBytes) {
        QWriteLocker lk(&m_lock);
        m_maxBytes = std::max<qint64>(0, maxBytes);
        enforceCapsUnlocked();
    }

    int size() const {
        QReadLocker lk(&m_lock);
        return m_frames.size();
    }

    bool isEmpty() const {
        QReadLocker lk(&m_lock);
        return m_frames.isEmpty();
    }

    qint64 bytes() const {
        QReadLocker lk(&m_lock);
        return m_totalBytes;
    }

    Nv12Frame at(int index) const {
        QReadLocker lk(&m_lock);
        if (index < 0 || index >= m_frames.size()) return Nv12Frame();
        return m_frames[index];
    }

    QDateTime timeAt(int index) const {
        QReadLocker lk(&m_lock);
        if (index < 0 || index >= m_ts.size()) return QDateTime();
        return m_ts[index];
    }

    QDateTime firstTime() const {
        QReadLocker lk(&m_lock);
        return m_ts.isEmpty() ? QDateTime() : m_ts.first();
    }

    QDateTime lastTime() const {
        QReadLocker lk(&m_lock);
        return m_ts.isEmpty() ? QDateTime() : m_ts.last();
    }

    void append(const Nv12Frame& fr, const QDateTime& tsUtc)
    {
        if (!tsUtc.isValid() || !fr.isValid()) return;

        const qint64 incomingBytes = frameBytes(fr);

        QWriteLocker lk(&m_lock);
        ensureRoomForBytesUnlocked(incomingBytes);

        if (m_ts.isEmpty()) {
            m_ts.push_back(tsUtc);
            m_frames.push_back(fr);
            m_totalBytes += incomingBytes;
            enforceCapsUnlocked();
            return;
        }

        const QDateTime& lastTs = m_ts.last();
        if (tsUtc > lastTs) {
            m_ts.push_back(tsUtc);
            m_frames.push_back(fr);
            m_totalBytes += incomingBytes;
            enforceCapsUnlocked();
            return;
        }

        if (tsUtc == lastTs) {
            m_totalBytes -= frameBytes(m_frames.last());
            m_frames.last() = fr;
            m_totalBytes += incomingBytes;
            enforceCapsUnlocked();
            return;
        }

        const int pos = lowerBoundUnlocked(tsUtc);
        if (pos < m_ts.size() && m_ts[pos] == tsUtc) {
            m_totalBytes -= frameBytes(m_frames[pos]);
            m_frames[pos] = fr;
            m_totalBytes += incomingBytes;
        } else {
            m_ts.insert(pos, tsUtc);
            m_frames.insert(pos, fr);
            m_totalBytes += incomingBytes;
        }
        enforceCapsUnlocked();
    }
    void append(Nv12Frame&& fr, const QDateTime& tsUtc)
    {
        if (!tsUtc.isValid() || !fr.isValid()) return;

        const qint64 incomingBytes = frameBytes(fr);

        QWriteLocker lk(&m_lock);
        ensureRoomForBytesUnlocked(incomingBytes);

        if (m_ts.isEmpty()) {
            m_ts.push_back(tsUtc);
            m_frames.push_back(std::move(fr));
            m_totalBytes += incomingBytes;
            enforceCapsUnlocked();
            return;
        }

        const QDateTime& lastTs = m_ts.last();
        if (tsUtc > lastTs) {
            m_ts.push_back(tsUtc);
            m_frames.push_back(std::move(fr));
            m_totalBytes += incomingBytes;
            enforceCapsUnlocked();
            return;
        }

        if (tsUtc == lastTs) {
            m_totalBytes -= frameBytes(m_frames.last());
            m_frames.last() = std::move(fr);
            m_totalBytes += incomingBytes;
            enforceCapsUnlocked();
            return;
        }

        const int pos = lowerBoundUnlocked(tsUtc);
        if (pos < m_ts.size() && m_ts[pos] == tsUtc) {
            m_totalBytes -= frameBytes(m_frames[pos]);
            m_frames[pos] = std::move(fr);
            m_totalBytes += incomingBytes;
        } else {
            m_ts.insert(pos, tsUtc);
            m_frames.insert(pos, std::move(fr));
            m_totalBytes += incomingBytes;
        }
        enforceCapsUnlocked();
    }

    void appendBatch(const QVector<Nv12Frame>& frames, const QVector<QDateTime>& timestampsUtc)
    {
        const int n = frames.size();
        if (n == 0 || n != timestampsUtc.size()) return;

        qint64 incomingBytes = 0;
        for (int i = 0; i < n; ++i) incomingBytes += frameBytes(frames[i]);

        QWriteLocker lk(&m_lock);

        ensureRoomForBytesUnlocked(incomingBytes);

        const int reserveTo = (m_maxFrames > 0)
                ? std::min(m_ts.size() + n, m_maxFrames + 16)
                : (m_ts.size() + n);
        m_ts.reserve(reserveTo);
        m_frames.reserve(reserveTo);

        bool nonDecreasing = true;
        for (int i = 1; i < n; ++i) {
            if (timestampsUtc[i] < timestampsUtc[i - 1]) { nonDecreasing = false; break; }
        }

        if (m_ts.isEmpty()) {
            if (nonDecreasing) {
                for (int i = 0; i < n; ++i) {
                    const QDateTime& ts = timestampsUtc[i];
                    const Nv12Frame& fr = frames[i];
                    if (!ts.isValid() || !fr.isValid()) continue;
                    const qint64 b = frameBytes(fr);
                    if (!m_ts.isEmpty() && ts == m_ts.last()) {
                        m_totalBytes -= frameBytes(m_frames.last());
                        m_frames.last() = fr;
                        m_totalBytes += b;
                    } else {
                        m_ts.push_back(ts);
                        m_frames.push_back(fr);
                        m_totalBytes += b;
                    }
                }
                enforceCapsUnlocked();
                return;
            }
        } else {
            if (nonDecreasing && timestampsUtc.first() >= m_ts.last()) {
                for (int i = 0; i < n; ++i) {
                    const QDateTime& ts = timestampsUtc[i];
                    const Nv12Frame& fr = frames[i];
                    if (!ts.isValid() || !fr.isValid()) continue;
                    const qint64 b = frameBytes(fr);
                    if (!m_ts.isEmpty() && ts == m_ts.last()) {
                        m_totalBytes -= frameBytes(m_frames.last());
                        m_frames.last() = fr;
                        m_totalBytes += b;
                    } else {
                        m_ts.push_back(ts);
                        m_frames.push_back(fr);
                        m_totalBytes += b;
                    }
                }
                enforceCapsUnlocked();
                return;
            }
        }

        for (int i = 0; i < n; ++i) {
            const QDateTime& ts = timestampsUtc[i];
            const Nv12Frame& fr = frames[i];
            if (!ts.isValid() || !fr.isValid()) continue;
            const qint64 b = frameBytes(fr);

            const int pos = lowerBoundUnlocked(ts);
            if (pos < m_ts.size() && m_ts[pos] == ts) {
                m_totalBytes -= frameBytes(m_frames[pos]);
                m_frames[pos] = fr;
                m_totalBytes += b;
            } else {
                m_ts.insert(pos, ts);
                m_frames.insert(pos, fr);
                m_totalBytes += b;
            }
        }
        enforceCapsUnlocked();
    }
    void appendBatch(QVector<Nv12Frame>&& frames, const QVector<QDateTime>& timestampsUtc)
    {
        const int n = frames.size();
        if (n == 0 || n != timestampsUtc.size()) return;

        qint64 incomingBytes = 0;
        for (int i = 0; i < n; ++i) incomingBytes += frameBytes(frames[i]);

        QWriteLocker lk(&m_lock);

        ensureRoomForBytesUnlocked(incomingBytes);

        const int reserveTo = (m_maxFrames > 0)
                ? std::min(m_ts.size() + n, m_maxFrames + 16)
                : (m_ts.size() + n);
        m_ts.reserve(reserveTo);
        m_frames.reserve(reserveTo);

        bool nonDecreasing = true;
        for (int i = 1; i < n; ++i) {
            if (timestampsUtc[i] < timestampsUtc[i - 1]) { nonDecreasing = false; break; }
        }

        if (m_ts.isEmpty()) {
            if (nonDecreasing) {
                for (int i = 0; i < n; ++i) {
                    const QDateTime& ts = timestampsUtc[i];
                    Nv12Frame& fr = frames[i];
                    if (!ts.isValid() || !fr.isValid()) continue;
                    const qint64 b = frameBytes(fr);
                    if (!m_ts.isEmpty() && ts == m_ts.last()) {
                        m_totalBytes -= frameBytes(m_frames.last());
                        m_frames.last() = std::move(fr);
                        m_totalBytes += b;
                    } else {
                        m_ts.push_back(ts);
                        m_frames.push_back(std::move(fr));
                        m_totalBytes += b;
                    }
                }
                enforceCapsUnlocked();
                return;
            }
        } else {
            if (nonDecreasing && timestampsUtc.first() >= m_ts.last()) {
                for (int i = 0; i < n; ++i) {
                    const QDateTime& ts = timestampsUtc[i];
                    Nv12Frame& fr = frames[i];
                    if (!ts.isValid() || !fr.isValid()) continue;
                    const qint64 b = frameBytes(fr);
                    if (!m_ts.isEmpty() && ts == m_ts.last()) {
                        m_totalBytes -= frameBytes(m_frames.last());
                        m_frames.last() = std::move(fr);
                        m_totalBytes += b;
                    } else {
                        m_ts.push_back(ts);
                        m_frames.push_back(std::move(fr));
                        m_totalBytes += b;
                    }
                }
                enforceCapsUnlocked();
                return;
            }
        }

        for (int i = 0; i < n; ++i) {
            const QDateTime& ts = timestampsUtc[i];
            Nv12Frame& fr = frames[i];
            if (!ts.isValid() || !fr.isValid()) continue;
            const qint64 b = frameBytes(fr);

            const int pos = lowerBoundUnlocked(ts);
            if (pos < m_ts.size() && m_ts[pos] == ts) {
                m_totalBytes -= frameBytes(m_frames[pos]);
                m_frames[pos] = std::move(fr);
                m_totalBytes += b;
            } else {
                m_ts.insert(pos, ts);
                m_frames.insert(pos, std::move(fr));
                m_totalBytes += b;
            }
        }
        enforceCapsUnlocked();
    }

    int nearestIndexLE(const QDateTime& target) const
    {
        QReadLocker lk(&m_lock);
        if (m_ts.isEmpty()) return -1;
        const int pos = lowerBoundUnlocked(target);
        if (pos < m_ts.size() && m_ts[pos] == target) return pos;
        return pos - 1;
    }

    int nearestIndexGE(const QDateTime& target) const
    {
        QReadLocker lk(&m_lock);
        if (m_ts.isEmpty()) return -1;
        const int pos = lowerBoundUnlocked(target);
        if (pos >= m_ts.size()) return -1;
        return pos;
    }
    double calcSourceFPS(int sampleWindow) const
    {
        QReadLocker lk(&m_lock);
        const int n = m_ts.size();
        if (n < 2) return 0.0;

        const int span = std::min(std::max(1, sampleWindow), n - 1);
        const int start = n - 1 - span;
        const qint64 totalMs = m_ts[start].msecsTo(m_ts.last());
        if (totalMs <= 0) return 0.0;

        return double(span) * 1000.0 / double(totalMs);
    }

private:
    static inline qint64 frameBytes(const Nv12Frame& fr) {
        return (fr.isValid() ? (qint64(fr.yBytes()) + qint64(fr.uvBytes())) : 0);
    }

    int lowerBoundUnlocked(const QDateTime& t) const
    {
        int l = 0, r = m_ts.size();
        while (l < r) {
            const int mid = (l + r) >> 1;
            if (m_ts[mid] < t) l = mid + 1;
            else r = mid;
        }
        return l;
    }

    int upperBoundUnlocked(const QDateTime& t) const
    {
        int l = 0, r = m_ts.size();
        while (l < r) {
            const int mid = (l + r) >> 1;
            if (!(t < m_ts[mid])) l = mid + 1; // m_ts[mid] <= t
            else r = mid;
        }
        return l;
    }

    void removePrefixUnlocked(int count)
    {
        if (count <= 0) return;
        const int n = m_frames.size();
        if (count >= n) {
            m_ts.clear();
            m_frames.clear();
            m_totalBytes = 0;
            return;
        }
        for (int i = 0; i < count; ++i) m_totalBytes -= frameBytes(m_frames[i]);
        m_ts.remove(0, count);
        m_frames.remove(0, count);
    }

    void removeSuffixUnlocked(int count)
    {
        if (count <= 0) return;
        const int n = m_frames.size();
        if (count >= n) {
            m_ts.clear();
            m_frames.clear();
            m_totalBytes = 0;
            return;
        }
        const int start = n - count;
        for (int i = start; i < n; ++i) m_totalBytes -= frameBytes(m_frames[i]);
        m_ts.remove(start, count);
        m_frames.remove(start, count);
    }

    void ensureRoomForBytesUnlocked(qint64 incomingBytes)
    {
        if (m_maxBytes <= 0 || incomingBytes <= 0) return;
        if (m_frames.isEmpty()) return;

        // Keep at least one frame (for UI / continuity).
        qint64 need = (m_totalBytes + incomingBytes) - m_maxBytes;
        if (need <= 0) return;

        const int n = m_frames.size();
        int dropCount = 0;

        if (m_dropFromFront) {
            while (dropCount < n - 1 && need > 0) {
                need -= frameBytes(m_frames[dropCount]);
                ++dropCount;
            }
            removePrefixUnlocked(dropCount);
        } else {
            while (dropCount < n - 1 && need > 0) {
                need -= frameBytes(m_frames[n - 1 - dropCount]);
                ++dropCount;
            }
            removeSuffixUnlocked(dropCount);
        }
    }

    void enforceCapsUnlocked()
    {
        if (m_maxFrames > 0 && m_frames.size() > m_maxFrames) {
            const int excess = m_frames.size() - m_maxFrames;
            if (m_dropFromFront) removePrefixUnlocked(excess);
            else                 removeSuffixUnlocked(excess);
        }

        // 2) Hard cap by time span (drop in one shot using binary search)
        if (m_maxDurationMs > 0 && m_ts.size() > 1) {
            const QDateTime first = m_ts.first();
            const QDateTime last  = m_ts.last();
            const qint64 span = first.msecsTo(last);

            if (span > m_maxDurationMs) {
                if (m_dropFromFront) {
                    // keep [last - maxDuration, last]
                    const QDateTime cutoff = last.addMSecs(-m_maxDurationMs);
                    int idx = lowerBoundUnlocked(cutoff);
                    // Keep at least one
                    idx = std::min(idx, m_ts.size() - 1);
                    if (idx > 0) removePrefixUnlocked(idx);
                } else {
                    // keep [first, first + maxDuration]
                    const QDateTime cutoff = first.addMSecs(m_maxDurationMs);
                    int keep = upperBoundUnlocked(cutoff);
                    keep = std::max(1, std::min(keep, m_ts.size()));
                    const int excessBack = m_ts.size() - keep;
                    if (excessBack > 0) removeSuffixUnlocked(excessBack);
                }
            }
        }

        // 3) Hard cap by bytes (drop in chunks)
        if (m_maxBytes > 0 && m_totalBytes > m_maxBytes && m_frames.size() > 1) {
            while (m_totalBytes > m_maxBytes && m_frames.size() > 1) {
                const int n = m_frames.size();
                const qint64 avg = std::max<qint64>(1, m_totalBytes / std::max(1, n));
                const qint64 over = m_totalBytes - m_maxBytes;
                int drop = int((over + avg - 1) / avg) + 1;
                drop = std::clamp(drop, 1, n - 1);

                if (m_dropFromFront) removePrefixUnlocked(drop);
                else                 removeSuffixUnlocked(drop);
            }
        }

        // Safety clamp (never go negative)
        if (m_totalBytes < 0) m_totalBytes = 0;
    }

private:
    mutable QReadWriteLock m_lock;
    QVector<QDateTime> m_ts;
    QVector<Nv12Frame> m_frames;

    int m_maxFrames = 0;
    qint64 m_maxDurationMs = 0;
    qint64 m_maxBytes = 0;
    qint64 m_totalBytes = 0;
    bool m_dropFromFront = true;
};
