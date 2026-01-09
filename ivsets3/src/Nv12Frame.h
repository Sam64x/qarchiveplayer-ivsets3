#pragma once

#include <QSize>
#include <QByteArray>
#include <QMetaType>
#include <QVector>
#include <QtGlobal>
#include <cstring>

class Nv12Frame
{
public:
    Nv12Frame() = default;
    ~Nv12Frame() = default;

    Nv12Frame(const Nv12Frame&) = default;
    Nv12Frame(Nv12Frame&&) noexcept = default;
    Nv12Frame& operator=(const Nv12Frame&) = default;
    Nv12Frame& operator=(Nv12Frame&&) noexcept = default;

    Nv12Frame(int w, int h, const QByteArray& y, const QByteArray& uv)
        : m_size(w, h), m_y(y), m_uv(uv)
    { normalize(); }

    Nv12Frame(int w, int h, QByteArray&& y, QByteArray&& uv) noexcept
        : m_size(w, h), m_y(std::move(y)), m_uv(std::move(uv))
    { normalize(); }

    static Nv12Frame fromPlanes(int w, int h,
                                const uchar* y,  int strideY,
                                const uchar* uv, int strideUV)
    {
        Nv12Frame out;
        if (w <= 0 || h <= 0 || !y || !uv) return out;

        const int yRowBytes  = w;
        const int uvRowBytes = uvRowBytesForWidth(w);

        const int yBytes  = w * h;
        const int uvRows  = h / 2;
        const int uvBytes = uvRowBytes * uvRows;

        QByteArray yDense(yBytes,  Qt::Uninitialized);
        QByteArray uvDense(uvBytes, Qt::Uninitialized);

        const int sy = strideY;
        const bool yNeg = (sy < 0);
        const uchar* srcY = yNeg ? (y + (h - 1) * size_t(-sy)) : y;
        const int stepY = yNeg ? -sy : sy;
        for (int j = 0; j < h; ++j)
            std::memcpy(yDense.data() + j * yRowBytes, srcY + j * stepY, size_t(yRowBytes));

        const int suv = strideUV;
        const bool uvNeg = (suv < 0);
        const uchar* srcUV = uvNeg ? (uv + (uvRows - 1) * size_t(-suv)) : uv;
        const int stepUV = uvNeg ? -suv : suv;
        for (int j = 0; j < uvRows; ++j)
            std::memcpy(uvDense.data() + j * uvRowBytes, srcUV + j * stepUV, size_t(uvRowBytes));

        out.m_size = QSize(w, h);
        out.m_y    = std::move(yDense);
        out.m_uv   = std::move(uvDense);
        out.normalize();
        return out;
    }

    bool isValid() const {
        if (m_size.width() <= 0 || m_size.height() <= 0) return false;
        if (m_y.isEmpty() || m_uv.isEmpty()) return false;
        const int expectedUv = uvRowBytesForWidth(m_size.width()) * uvRowsForHeight(m_size.height());
        return (m_y.size() == m_size.width() * m_size.height()) && (m_uv.size() == expectedUv);
    }

    void clear() { m_size = QSize(); m_y.clear(); m_uv.clear(); }

    bool normalize() {
        if (!isValid()) { clear(); return false; }
        return true;
    }

    QSize size()  const { return m_size; }
    int   width() const { return m_size.width(); }
    int   height()const { return m_size.height(); }

    const QByteArray& yPlane()  const { return m_y; }
    const QByteArray& uvPlane() const { return m_uv; }

    const uchar* yData()  const { return reinterpret_cast<const uchar*>(m_y.constData()); }
    const uchar* uvData() const { return reinterpret_cast<const uchar*>(m_uv.constData()); }

    int strideY()  const { return width(); }
    int strideUV() const { return uvRowBytes(); }

    int yBytes()  const { return m_y.size(); }
    int uvBytes() const { return m_uv.size(); }

    int  uvRowBytes() const { return uvRowBytesForWidth(width()); }
    static int uvRowBytesForWidth(int w) { return (w > 0 ? ((w + 1) / 2) * 2 : 0); }
    static int uvRowsForHeight(int h) { return (h > 0 ? (h + 1) / 2 : 0); }
    static void registerMetaType();

private:
    QSize      m_size;
    QByteArray m_y;
    QByteArray m_uv;
};

Q_DECLARE_METATYPE(Nv12Frame)
Q_DECLARE_METATYPE(QVector<Nv12Frame>)
Q_DECLARE_TYPEINFO(Nv12Frame, Q_MOVABLE_TYPE);
