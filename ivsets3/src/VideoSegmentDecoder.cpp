#include "VideoSegmentDecoder.h"

#include <QDebug>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>
#include <libavutil/pixfmt.h>
#include <libavutil/log.h>
}

namespace {

struct MemIO {
    const uint8_t* data = nullptr;
    int64_t size = 0;
    int64_t pos  = 0;
};

int mem_read(void* opaque, uint8_t* buf, int buf_size)
{
    MemIO* m = static_cast<MemIO*>(opaque);
    const int64_t left = m->size - m->pos;
    if (left <= 0) return AVERROR_EOF;
    const int toCopy = static_cast<int>(std::min<int64_t>(buf_size, left));
    std::memcpy(buf, m->data + m->pos, size_t(toCopy));
    m->pos += toCopy;
    return toCopy;
}

int64_t mem_seek(void* opaque, int64_t offset, int whence)
{
    MemIO* m = static_cast<MemIO*>(opaque);
    if (whence == AVSEEK_SIZE) return m->size;

    int64_t newpos = 0;
    switch (whence) {
    case SEEK_SET: newpos = offset;           break;
    case SEEK_CUR: newpos = m->pos + offset;  break;
    case SEEK_END: newpos = m->size + offset; break;
    default:       return -1;
    }
    if (newpos < 0 || newpos > m->size) return -1;
    m->pos = newpos;
    return m->pos;
}

inline int safe_w(const AVFrame* f) { return f ? std::max(0, f->width)  : 0; }
inline int safe_h(const AVFrame* f) { return f ? std::max(0, f->height) : 0; }

static int swsMatrixFromAV(enum AVColorSpace spc, int w, int h)
{
    switch (spc) {
    case AVCOL_SPC_BT709:       return SWS_CS_ITU709;
    case AVCOL_SPC_BT470BG:
    case AVCOL_SPC_SMPTE170M:   return SWS_CS_ITU601;
    case AVCOL_SPC_SMPTE240M:   return SWS_CS_SMPTE240M;
    default:
        return (h > 576 || w > 1024) ? SWS_CS_ITU709 : SWS_CS_ITU601;
    }
}

static AVPixelFormat normalizeYuvjFormat(AVPixelFormat fmt, int& srcRange)
{
    switch (fmt) {
    case AV_PIX_FMT_YUVJ420P: srcRange = 1; return AV_PIX_FMT_YUV420P;
    case AV_PIX_FMT_YUVJ422P: srcRange = 1; return AV_PIX_FMT_YUV422P;
    case AV_PIX_FMT_YUVJ444P: srcRange = 1; return AV_PIX_FMT_YUV444P;
#if LIBAVUTIL_VERSION_INT >= AV_VERSION_INT(57, 28, 100)
    case AV_PIX_FMT_YUVJ411P: srcRange = 1; return AV_PIX_FMT_YUV411P;
#endif
    default: return fmt;
    }
}

static void packYuv420pToNv12(const AVFrame* src, QByteArray& yOut, QByteArray& uvOut)
{
    const int w  = safe_w(src);
    const int h  = safe_h(src);
    const int cw = (w + 1) / 2;
    const int ch = (h + 1) / 2;

    yOut.resize(w * h);
    uvOut.resize((w * h) / 2);

    const uint8_t* srcY = src->data[0];
    const int sY = src->linesize[0];
    for (int j = 0; j < h; ++j) {
        std::memcpy(yOut.data() + j * w, srcY + j * sY, size_t(w));
    }

    const uint8_t* srcU = src->data[1];
    const uint8_t* srcV = src->data[2];
    const int sU = src->linesize[1];
    const int sV = src->linesize[2];

    for (int j = 0; j < ch; ++j) {
        const uint8_t* ru = srcU + j * sU;
        const uint8_t* rv = srcV + j * sV;
        uint8_t* dst = reinterpret_cast<uint8_t*>(uvOut.data()) + j * w;
        for (int i = 0; i < cw; ++i) {
            dst[2 * i + 0] = ru[i];
            dst[2 * i + 1] = rv[i];
        }
    }
}

static void filteredFfmpegLogCallback(void* ptr, int level, const char* fmt, va_list vl)
{
    if (level > av_log_get_level())
        return;

    if (fmt) {
        if (std::strstr(fmt, "sps_id") && std::strstr(fmt, "out of range"))
            return;

        if (std::strstr(fmt, "Error decoding the extradata"))
            return;

        if (std::strstr(fmt, "not enough frames to estimate rate") &&
            std::strstr(fmt, "probesize"))
            return;

        if (std::strstr(fmt, "non-existing SPS") &&
            std::strstr(fmt, "buffering period"))
            return;

        if (std::strstr(fmt, "missing picture in access unit"))
            return;

        if (std::strstr(fmt, "no frame!"))
            return;
    }

    av_log_default_callback(ptr, level, fmt, vl);
}

static void initFfmpegLogFiltering()
{
    static bool initialized = false;
    if (!initialized) {
        initialized = true;
        av_log_set_callback(filteredFfmpegLogCallback);
    }
}

}

struct VideoSegmentDecoder::FfCtx {
    AVFormatContext* fmt = nullptr;
    AVIOContext*     avio = nullptr;
    AVCodecContext*  dec  = nullptr;
    AVFrame*         frm  = nullptr;
    AVPacket*        pkt  = nullptr;
    SwsContext*      sws  = nullptr;

    uint8_t*  avioBuffer = nullptr;
    int       avioBufferSize = 256 * 1024;

    int       videoStream = -1;
    AVRational timeBase {1, 1000};

    MemIO     mem;

    int           swsW = 0, swsH = 0;
    AVPixelFormat swsSrcFmt = AV_PIX_FMT_NONE;
    int           swsSrcRange = 0;

    QByteArray dstY;
    QByteArray dstUV;

    FfCtx() {}
};

VideoSegmentDecoder::VideoSegmentDecoder(QObject* parent)
    : QObject(parent)
{
    initFfmpegLogFiltering();

    Nv12Frame::registerMetaType();
    qRegisterMetaType<QVector<Nv12Frame>>("QVector<Nv12Frame>");

    m_tick.setTimerType(Qt::CoarseTimer);
    m_tick.setSingleShot(false);
    m_tick.setInterval(0);
    connect(&m_tick, &QTimer::timeout, this, &VideoSegmentDecoder::processTick);
}


QVector<VideoSegmentDecoder::DecodedNv12> VideoSegmentDecoder::decodeSegmentNV12(const QByteArray& segment)
{
    QVector<DecodedNv12> out;
    if (segment.isEmpty()) {
        return out;
    }

    m_abortRequested.store(false);

    AVFormatContext* fmt = avformat_alloc_context();
    AVIOContext* avio = nullptr;
    AVCodecContext* dec = nullptr;
    AVFrame* frm = nullptr;
    AVPacket* pkt = nullptr;

    SwsContext* sws = nullptr;
    int swsW = 0, swsH = 0;
    AVPixelFormat swsSrcFmt = AV_PIX_FMT_NONE;
    int swsSrcRange = 0;

    uint8_t* avioBuffer = nullptr;
    const int avioBufferSize = 256 * 1024;

    int videoStream = -1;
    AVRational timeBase {1, 1000};

    bool aborted = false;

    AVIOInterruptCB intCb;
    intCb.callback = [](void *opaque) -> int {
        VideoSegmentDecoder *decoder = static_cast<VideoSegmentDecoder*>(opaque);
        return decoder->shouldAbort() ? 1 : 0;
    };
    intCb.opaque = this;
    fmt->interrupt_callback = intCb;

    MemIO mem{ reinterpret_cast<const uint8_t*>(segment.constData()), segment.size(), 0 };

    auto ensureSws = [&](const AVFrame* src) -> bool {
        int srcRange = (src->color_range == AVCOL_RANGE_JPEG) ? 1 : 0;
        AVPixelFormat srcFmt = static_cast<AVPixelFormat>(src->format);
        srcFmt = normalizeYuvjFormat(srcFmt, srcRange);
        const int w = safe_w(src), h = safe_h(src);
        if (!sws || swsW != w || swsH != h || swsSrcFmt != srcFmt || swsSrcRange != srcRange) {
            SwsContext* ctx = sws_getCachedContext(
                sws, w, h, srcFmt,
                w, h, AV_PIX_FMT_NV12,
                SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
                );
            if (!ctx) return false;
            sws = ctx; swsW = w; swsH = h; swsSrcFmt = srcFmt; swsSrcRange = srcRange;
            const int cs = swsMatrixFromAV(static_cast<AVColorSpace>(src->colorspace), w, h);
            const int* coefs = sws_getCoefficients(cs);
            const int dstRange = 0;
            sws_setColorspaceDetails(sws, coefs, srcRange, coefs, dstRange, 0, 1<<16, 1<<16);
        }
        return true;
    };

    double firstPtsMs = std::numeric_limits<double>::quiet_NaN();
    auto relativePtsMs = [&](const AVFrame* f) -> qint64 {
        int64_t raw = (f->best_effort_timestamp != AV_NOPTS_VALUE) ? f->best_effort_timestamp : f->pts;
        const double ms = (raw == AV_NOPTS_VALUE) ? 0.0 : (raw * av_q2d(timeBase) * 1000.0);
        if (std::isnan(firstPtsMs)) firstPtsMs = ms;
        double rel = ms - firstPtsMs;
        if (rel < 0) rel = 0.0;
        return qint64(std::llround(rel));
    };

    do {
        avioBuffer = static_cast<uint8_t*>(av_malloc(size_t(avioBufferSize)));
        if (!avioBuffer) break;

        avio = avio_alloc_context(avioBuffer, avioBufferSize, 0, &mem, &mem_read, nullptr, &mem_seek);
        if (!avio) {
            av_freep(&avioBuffer);
            break;
        }
        avioBuffer = nullptr;
        avio->seekable = AVIO_SEEKABLE_NORMAL;

        fmt->pb = avio;
        fmt->flags |= AVFMT_FLAG_CUSTOM_IO;

        AVDictionary* fmtOpts = nullptr;
        av_dict_set(&fmtOpts, "probesize",       "512k", 0);
        av_dict_set(&fmtOpts, "analyzeduration", "4M",   0);

        const AVInputFormat* ts = av_find_input_format("mpegts");
        if (avformat_open_input(&fmt, nullptr, ts, &fmtOpts) < 0) { av_dict_free(&fmtOpts); break; }
        av_dict_free(&fmtOpts);

        if (avformat_find_stream_info(fmt, nullptr) < 0) break;

        videoStream = av_find_best_stream(fmt, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
        if (videoStream < 0) break;

        AVStream* st = fmt->streams[videoStream];
        timeBase = st->time_base;

        const AVCodec* codec = avcodec_find_decoder(st->codecpar->codec_id);
        if (!codec) break;

        dec = avcodec_alloc_context3(codec);
        if (!dec) break;
        if (avcodec_parameters_to_context(dec, st->codecpar) < 0) break;

        if (dec->codec_id == AV_CODEC_ID_H264 && dec->extradata && dec->extradata_size >= 4) {
            const uint8_t* ed = dec->extradata;
            if (ed[0]==0 && ed[1]==0 && ed[2]==0 && ed[3]==1) {
                av_freep(&dec->extradata);
                dec->extradata_size = 0;
            }
        }

        dec->flags2      |= AV_CODEC_FLAG2_FAST;
        dec->thread_type  = FF_THREAD_FRAME | FF_THREAD_SLICE;
        dec->thread_count = 0;

        if (avcodec_open2(dec, codec, nullptr) < 0) break;

        frm = av_frame_alloc();
        pkt = av_packet_alloc();
        if (!frm || !pkt) break;

        while (!shouldAbort() && av_read_frame(fmt, pkt) >= 0) {
            if (pkt->stream_index != videoStream) {
                av_packet_unref(pkt);
                continue;
            }
            if (avcodec_send_packet(dec, pkt) < 0) {
                av_packet_unref(pkt);
                continue;
            }
            while (!shouldAbort()) {
                int ret = avcodec_receive_frame(dec, frm);
                if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
                if (ret < 0) { av_frame_unref(frm); break; }

                const qint64 rel = relativePtsMs(frm);

                DecodedNv12 dn;
                int dummyRange = (frm->color_range == AVCOL_RANGE_JPEG) ? 1 : 0;
                AVPixelFormat srcFmt = normalizeYuvjFormat(static_cast<AVPixelFormat>(frm->format), dummyRange);

                if (srcFmt == AV_PIX_FMT_NV12) {
                    Nv12Frame nv = makeNv12FromAVFrame(frm);
                    if (nv.isValid()) {
                        dn.frame = nv;
                        dn.ptsMs = rel;
                        dn.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                        out.push_back(dn);
                    }
                } else if (srcFmt == AV_PIX_FMT_YUV420P) {
                    const int w = safe_w(frm), h = safe_h(frm);
                    if (w > 0 && h > 0) {
                        QByteArray y, uv;
                        packYuv420pToNv12(frm, y, uv);
                        Nv12Frame nv(w, h, y, uv);
                        if (nv.isValid()) {
                            dn.frame = nv;
                            dn.ptsMs = rel;
                            dn.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                            out.push_back(dn);
                        }
                    }
                } else {
                    if (ensureSws(frm)) {
                        const int w = safe_w(frm), h = safe_h(frm);
                        const int uvStride = ((w + 1) / 2) * 2;
                        const int h2 = (h + 1) / 2;

                        QByteArray y(w * h, Qt::Uninitialized);
                        QByteArray uv(uvStride * h2, Qt::Uninitialized);

                        const uint8_t* srcData[4] = { frm->data[0], frm->data[1], frm->data[2], frm->data[3] };
                        const int      srcStride[4] = { frm->linesize[0], frm->linesize[1], frm->linesize[2], frm->linesize[3] };

                        uint8_t* dstData[3] = {
                            reinterpret_cast<uint8_t*>(y.data()),
                            reinterpret_cast<uint8_t*>(uv.data()),
                            nullptr
                        };
                        int dstStride[3] = { w, uvStride, 0 };

                        const int scaled = sws_scale(sws, srcData, srcStride, 0, h, dstData, dstStride);
                        if (scaled > 0) {
                            Nv12Frame nv(w, h, y, uv);
                            if (nv.isValid()) {
                                dn.frame = nv;
                                dn.ptsMs = rel;
                                dn.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                                out.push_back(dn);
                            }
                        }
                    }
                }
                av_frame_unref(frm);
            }
            av_packet_unref(pkt);
            if (shouldAbort()) { aborted = true; break; }
        }

        if (!shouldAbort()) {
            avcodec_send_packet(dec, nullptr);
            while (true) {
                if (shouldAbort()) { aborted = true; break; }
                int ret = avcodec_receive_frame(dec, frm);
                if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
                if (ret < 0) { av_frame_unref(frm); break; }

                const qint64 rel = relativePtsMs(frm);

                DecodedNv12 dn;
                int dummyRange = (frm->color_range == AVCOL_RANGE_JPEG) ? 1 : 0;
                AVPixelFormat srcFmt = normalizeYuvjFormat(static_cast<AVPixelFormat>(frm->format), dummyRange);

                if (srcFmt == AV_PIX_FMT_NV12) {
                    Nv12Frame nv = makeNv12FromAVFrame(frm);
                    if (nv.isValid()) {
                        dn.frame = nv;
                        dn.ptsMs = rel;
                        dn.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                        out.push_back(dn);
                    }
                } else if (srcFmt == AV_PIX_FMT_YUV420P) {
                    const int w = safe_w(frm), h = safe_h(frm);
                    if (w > 0 && h > 0) {
                        QByteArray y, uv;
                        packYuv420pToNv12(frm, y, uv);
                        Nv12Frame nv(w, h, y, uv);
                        if (nv.isValid()) {
                            dn.frame = nv;
                            dn.ptsMs = rel;
                            dn.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                            out.push_back(dn);
                        }
                    }
                } else {
                    if (ensureSws(frm)) {
                        const int w = safe_w(frm), h = safe_h(frm);
                        const int uvStride = ((w + 1) / 2) * 2;
                        const int h2 = (h + 1) / 2;

                        QByteArray y(w * h, Qt::Uninitialized);
                        QByteArray uv(uvStride * h2, Qt::Uninitialized);

                        const uint8_t* srcData[4] = { frm->data[0], frm->data[1], frm->data[2], frm->data[3] };
                        const int      srcStride[4] = { frm->linesize[0], frm->linesize[1], frm->linesize[2], frm->linesize[3] };

                        uint8_t* dstData[3] = {
                            reinterpret_cast<uint8_t*>(y.data()),
                            reinterpret_cast<uint8_t*>(uv.data()),
                            nullptr
                        };
                        int dstStride[3] = { w, uvStride, 0 };

                        const int scaled = sws_scale(sws, srcData, srcStride, 0, h, dstData, dstStride);
                        if (scaled > 0) {
                            Nv12Frame nv(w, h, y, uv);
                            if (nv.isValid()) {
                                dn.frame = nv;
                                dn.ptsMs = rel;
                                dn.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                                out.push_back(dn);
                            }
                        }
                    }
                }
                av_frame_unref(frm);
            }
        }
    } while (false);

    if (pkt)  av_packet_free(&pkt);
    if (frm)  av_frame_free(&frm);
    if (dec)  avcodec_free_context(&dec);
    if (fmt)  avformat_close_input(&fmt);
    if (avio) avio_context_free(&avio);
    else if (avioBuffer) av_freep(&avioBuffer);
    if (sws)  sws_freeContext(sws);

    qint64 last = -1;
    for (int i = 0; i < out.size(); ++i) {
        if (out[i].ptsMs < 0) out[i].ptsMs = 0;
        if (out[i].ptsMs < last) out[i].ptsMs = last;
        out[i].tsUtc = QDateTime::fromMSecsSinceEpoch(out[i].ptsMs, Qt::UTC);
        last = out[i].ptsMs;
    }

    if (shouldAbort()) {
        out.clear();
    }

    return out;
}

VideoSegmentDecoder::DecodedNv12 VideoSegmentDecoder::decodeFirstFrameNV12(const QByteArray& segment)
{
    DecodedNv12 res{ Nv12Frame(), QDateTime(), 0 };
    if (segment.isEmpty()) return res;

    m_abortRequested.store(false);

    AVFormatContext* fmt = avformat_alloc_context();
    AVIOContext* avio = nullptr;
    AVCodecContext* dec = nullptr;
    AVFrame* frm = nullptr;
    AVPacket* pkt = nullptr;
    SwsContext* sws = nullptr;

    uint8_t* avioBuffer = nullptr;
    const int avioBufferSize = 256 * 1024;

    int videoStream = -1;
    AVRational timeBase {1, 1000};

    MemIO mem;
    mem.data = reinterpret_cast<const uint8_t*>(segment.constData());
    mem.size = segment.size();

    int swsW = 0, swsH = 0;
    AVPixelFormat swsSrcFmt = AV_PIX_FMT_NONE;
    int swsSrcRange = 0;

    AVDictionary* fmtOpts = nullptr;
    av_dict_set(&fmtOpts, "probesize",       "512k", 0);
    av_dict_set(&fmtOpts, "analyzeduration", "4M",   0);
    av_dict_set(&fmtOpts, "fpsprobesize",    "16",   0);

    AVIOInterruptCB intCb;
    intCb.callback = [](void *opaque) -> int {
        VideoSegmentDecoder *decoder = static_cast<VideoSegmentDecoder*>(opaque);
        return decoder->shouldAbort() ? 1 : 0;
    };
    intCb.opaque = this;
    fmt->interrupt_callback = intCb;

    double firstPtsMs = std::numeric_limits<double>::quiet_NaN();

    auto ensureSws = [&](const AVFrame* src) -> bool {
        int srcRange = (src->color_range == AVCOL_RANGE_JPEG) ? 1 : 0;
        AVPixelFormat srcFmt = static_cast<AVPixelFormat>(src->format);
        srcFmt = normalizeYuvjFormat(srcFmt, srcRange);
        const int w = safe_w(src), h = safe_h(src);
        if (!sws || swsW != w || swsH != h || swsSrcFmt != srcFmt || swsSrcRange != srcRange) {
            SwsContext* ctx = sws_getCachedContext(
                sws, w, h, srcFmt,
                w, h, AV_PIX_FMT_NV12,
                SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
                );
            if (!ctx) return false;
            sws = ctx; swsW = w; swsH = h; swsSrcFmt = srcFmt; swsSrcRange = srcRange;
            const int cs = swsMatrixFromAV(static_cast<AVColorSpace>(src->colorspace), w, h);
            const int* coefs = sws_getCoefficients(cs);
            const int dstRange = 0;
            sws_setColorspaceDetails(sws, coefs, srcRange, coefs, dstRange, 0, 1<<16, 1<<16);
        }
        return true;
    };

    auto relativePtsMs = [&](const AVFrame* f) -> qint64 {
        int64_t raw = (f->best_effort_timestamp != AV_NOPTS_VALUE) ? f->best_effort_timestamp : f->pts;
        const double ms = (raw == AV_NOPTS_VALUE) ? 0.0 : (raw * av_q2d(timeBase) * 1000.0);
        if (std::isnan(firstPtsMs)) firstPtsMs = ms;
        double rel = ms - firstPtsMs;
        if (rel < 0) rel = 0.0;
        qint64 pts = qint64(std::llround(rel));
        if (pts < 0) pts = 0;
        return pts;
    };

    bool got = false;

    do {
        avioBuffer = static_cast<uint8_t*>(av_malloc(size_t(avioBufferSize)));
        if (!avioBuffer) break;

        avio = avio_alloc_context(avioBuffer, avioBufferSize, 0, &mem, &mem_read, nullptr, &mem_seek);
        if (!avio) {
            av_freep(&avioBuffer);
            break;
        }
        avioBuffer = nullptr;
        avio->seekable = AVIO_SEEKABLE_NORMAL;

        fmt->pb = avio;
        fmt->flags |= AVFMT_FLAG_CUSTOM_IO;

        const AVInputFormat* ts = av_find_input_format("mpegts");
        if (avformat_open_input(&fmt, nullptr, ts, &fmtOpts) < 0) break;
        if (avformat_find_stream_info(fmt, nullptr) < 0) break;

        int vIdx = av_find_best_stream(fmt, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
        if (vIdx < 0) break;
        videoStream = vIdx;

        AVStream* st = fmt->streams[videoStream];
        timeBase = st->time_base;

        const AVCodec* codec = avcodec_find_decoder(st->codecpar->codec_id);
        if (!codec) break;

        dec = avcodec_alloc_context3(codec);
        if (!dec) break;
        if (avcodec_parameters_to_context(dec, st->codecpar) < 0) break;

        if (dec->codec_id == AV_CODEC_ID_H264 && dec->extradata && dec->extradata_size >= 4) {
            const uint8_t* ed = dec->extradata;
            if (ed[0]==0 && ed[1]==0 && ed[2]==0 && ed[3]==1) {
                av_freep(&dec->extradata);
                dec->extradata_size = 0;
            }
        }

        dec->flags2      |= AV_CODEC_FLAG2_FAST;
        dec->thread_type = FF_THREAD_FRAME | FF_THREAD_SLICE;
        dec->thread_count = 0;

        if (avcodec_open2(dec, codec, nullptr) < 0) break;

        frm = av_frame_alloc();
        pkt = av_packet_alloc();
        if (!frm || !pkt) break;

        while (!shouldAbort() && av_read_frame(fmt, pkt) >= 0) {
            if (pkt->stream_index != videoStream) {
                av_packet_unref(pkt);
                continue;
            }
            if (avcodec_send_packet(dec, pkt) < 0) {
                av_packet_unref(pkt);
                continue;
            }
            while (!shouldAbort()) {
                int ret = avcodec_receive_frame(dec, frm);
                if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
                if (ret < 0) { av_frame_unref(frm); break; }

                const qint64 rel = relativePtsMs(frm);

                Nv12Frame outNv;
                int dummyRange = (frm->color_range == AVCOL_RANGE_JPEG) ? 1 : 0;
                AVPixelFormat srcFmt = normalizeYuvjFormat(static_cast<AVPixelFormat>(frm->format), dummyRange);

                if (srcFmt == AV_PIX_FMT_NV12) {
                    const int w = safe_w(frm), h = safe_h(frm);
                    if (w > 0 && h > 0) {
                        outNv = makeNv12FromAVFrame(frm);
                    }
                } else if (srcFmt == AV_PIX_FMT_YUV420P) {
                    const int w = safe_w(frm), h = safe_h(frm);
                    if (w > 0 && h > 0) {
                        QByteArray y, uv;
                        packYuv420pToNv12(frm, y, uv);
                        outNv = Nv12Frame(w, h, y, uv);
                    }
                } else {
                    if (ensureSws(frm)) {
                        const int w = safe_w(frm), h = safe_h(frm);
                        const int uvStride = ((w + 1) / 2) * 2;
                        const int h2 = (h + 1) / 2;

                        QByteArray y(w * h, Qt::Uninitialized);
                        QByteArray uv(uvStride * h2, Qt::Uninitialized);

                        const uint8_t* srcData[4] = { frm->data[0], frm->data[1], frm->data[2], frm->data[3] };
                        const int      srcStride[4] = { frm->linesize[0], frm->linesize[1], frm->linesize[2], frm->linesize[3] };

                        uint8_t* dstData[3] = {
                            reinterpret_cast<uint8_t*>(y.data()),
                            reinterpret_cast<uint8_t*>(uv.data()),
                            nullptr
                        };
                        int dstStride[3] = { w, uvStride, 0 };

                        const int scaled = sws_scale(sws, srcData, srcStride, 0, h, dstData, dstStride);
                        if (scaled > 0) {
                            outNv = Nv12Frame(w, h, y, uv);
                        }
                    }
                }

                if (outNv.isValid()) {
                    res.frame = outNv;
                    res.ptsMs = rel;
                    res.tsUtc = QDateTime::fromMSecsSinceEpoch(rel, Qt::UTC);
                    got = true;
                    av_frame_unref(frm);
                    break;
                }

                av_frame_unref(frm);
            }
            av_packet_unref(pkt);
            if (got || shouldAbort()) break;
        }
    } while (false);

    if (pkt)  av_packet_free(&pkt);
    if (frm)  av_frame_free(&frm);
    if (dec)  avcodec_free_context(&dec);
    if (fmt)  avformat_close_input(&fmt);
    if (avio) avio_context_free(&avio);
    else if (avioBuffer) av_freep(&avioBuffer);
    if (sws)  sws_freeContext(sws);
    av_dict_free(&fmtOpts);

    if (shouldAbort()) {
        res = DecodedNv12{ Nv12Frame(), QDateTime(), 0 };
    }

    return res;
}

void VideoSegmentDecoder::decodeSegmentRealtime(QByteArray bin, QObject* requester,
                                                int budgetFrames, int budgetMs)
{
    if (m_tick.isActive())
        m_tick.stop();

    ++m_generation;
    closeAll();
    resetAsync();

    m_bin.swap(bin);
    m_requester    = requester;
    m_budgetFrames = std::max(1, budgetFrames);
    m_budgetMs     = std::max(1, budgetMs);

    if (!ensureOpen()) {
        emit decodeFinished(m_requester);
        closeAll();
        return;
    }

    m_tick.start();
}

void VideoSegmentDecoder::processTick()
{
    if (!m_ff || !m_ff->fmt) {
        m_tick.stop();
        emit decodeFinished(m_requester);
        closeAll();
        return;
    }

    const qint64 t0 = QDateTime::currentMSecsSinceEpoch();
    int produced = 0;

    while (produced < m_budgetFrames &&
           (QDateTime::currentMSecsSinceEpoch() - t0) < m_budgetMs)
    {
        if (receiveOneFrame()) {
            ++produced;
            continue;
        }

        if (readOnePacket()) {
            continue;
        }

        if (drainDecoder()) {
            finalizeBatch();
            m_tick.stop();
            emit decodeFinished(m_requester);
            closeAll();
            return;
        } else {
            break;
        }
    }

    finalizeBatch();
}

bool VideoSegmentDecoder::ensureOpen()
{
    if (m_bin.isEmpty()) return false;

    m_ff = new FfCtx();

    m_ff->mem.data = reinterpret_cast<const uint8_t*>(m_bin.constData());
    m_ff->mem.size = m_bin.size();

    m_ff->fmt = avformat_alloc_context();
    if (!m_ff->fmt) return false;

    m_ff->avioBuffer = static_cast<uint8_t*>(av_malloc(size_t(m_ff->avioBufferSize)));
    if (!m_ff->avioBuffer) return false;

    m_ff->avio = avio_alloc_context(m_ff->avioBuffer, m_ff->avioBufferSize, 0, &m_ff->mem, &mem_read, nullptr, &mem_seek);
    if (!m_ff->avio) {
        av_freep(&m_ff->avioBuffer);
        return false;
    }
    m_ff->avioBuffer = nullptr;
    m_ff->avio->seekable = AVIO_SEEKABLE_NORMAL;

    m_ff->fmt->pb = m_ff->avio;
    m_ff->fmt->flags |= AVFMT_FLAG_CUSTOM_IO;

    auto* ts = av_find_input_format("mpegts");
    if (avformat_open_input(&m_ff->fmt, nullptr, ts, nullptr) < 0) return false;
    if (avformat_find_stream_info(m_ff->fmt, nullptr) < 0) return false;

    int vIdx = av_find_best_stream(m_ff->fmt, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
    if (vIdx < 0) return false;
    m_ff->videoStream = vIdx;

    AVStream* st = m_ff->fmt->streams[m_ff->videoStream];
    m_ff->timeBase = st->time_base;

    const AVCodec* codec = avcodec_find_decoder(st->codecpar->codec_id);
    if (!codec) return false;

    m_ff->dec = avcodec_alloc_context3(codec);
    if (!m_ff->dec) return false;
    if (avcodec_parameters_to_context(m_ff->dec, st->codecpar) < 0) return false;

    if (m_ff->dec->codec_id == AV_CODEC_ID_H264 && m_ff->dec->extradata && m_ff->dec->extradata_size >= 4) {
        const uint8_t* ed = m_ff->dec->extradata;
        const bool looksAnnexB = (ed[0]==0 && ed[1]==0 && ed[2]==0 && ed[3]==1);
        if (looksAnnexB) {
            av_freep(&m_ff->dec->extradata);
            m_ff->dec->extradata_size = 0;
        }
    }

    m_ff->dec->thread_count = 0;
    m_ff->dec->thread_type  = FF_THREAD_FRAME | FF_THREAD_SLICE;
    m_ff->dec->flags2      |= AV_CODEC_FLAG2_FAST;

    if (avcodec_open2(m_ff->dec, codec, nullptr) < 0) return false;

    m_ff->frm = av_frame_alloc();
    m_ff->pkt = av_packet_alloc();
    if (!m_ff->frm || !m_ff->pkt) return false;

    m_batch.clear();
    m_batch.reserve(32);
    m_firstPtsMs = qQNaN();
    m_lastPtsMs  = -1;
    m_batchStartUtc = QDateTime();

    return true;
}

bool VideoSegmentDecoder::readOnePacket()
{
    if (!m_ff || !m_ff->fmt || !m_ff->pkt) return false;

    int r = av_read_frame(m_ff->fmt, m_ff->pkt);
    if (r < 0) {
        return false;
    }

    if (m_ff->pkt->stream_index == m_ff->videoStream) {
        avcodec_send_packet(m_ff->dec, m_ff->pkt);
    }

    av_packet_unref(m_ff->pkt);
    return true;
}

qint64 VideoSegmentDecoder::framePtsMs(void* avFramePtr) const
{
    AVFrame* f = static_cast<AVFrame*>(avFramePtr);
    int64_t raw = (f->best_effort_timestamp != AV_NOPTS_VALUE) ? f->best_effort_timestamp : f->pts;
    const double ms = (raw == AV_NOPTS_VALUE) ? 0.0 : (raw * av_q2d(m_ff->timeBase) * 1000.0);
    if (std::isnan(m_firstPtsMs)) {
        const_cast<VideoSegmentDecoder*>(this)->m_firstPtsMs = ms;
    }
    double rel = ms - m_firstPtsMs;
    if (rel < 0) rel = 0.0;

    qint64 pts = qint64(std::llround(rel));
    if (pts < 0) pts = 0;
    if (pts < m_lastPtsMs) pts = m_lastPtsMs;
    return pts;
}

Nv12Frame VideoSegmentDecoder::makeNv12FromAVFrame(void* avFramePtr)
{
    AVFrame* f = static_cast<AVFrame*>(avFramePtr);
    const int w = f ? std::max(0, f->width) : 0;
    const int h = f ? std::max(0, f->height) : 0;
    if (w <= 0 || h <= 0) return Nv12Frame();

    QByteArray y(w * h, Qt::Uninitialized);
    QByteArray uv((w * h) / 2, Qt::Uninitialized);

    const uint8_t* srcY  = f->data[0];
    const int      sY    = f->linesize[0];
    for (int j = 0; j < h; ++j)
        std::memcpy(y.data() + j * w, srcY + j * sY, size_t(w));

    const uint8_t* srcUV = f->data[1];
    const int      sUV   = f->linesize[1];
    const int h2 = (h + 1) / 2;
    for (int j = 0; j < h2; ++j)
        std::memcpy(uv.data() + j * w, srcUV + j * sUV, size_t(w));

    return Nv12Frame(w, h, y, uv);
}

void VideoSegmentDecoder::packYuv420pToNv12(void* avFramePtr, QByteArray& yOut, QByteArray& uvOut)
{
    const AVFrame* src = static_cast<const AVFrame*>(avFramePtr);
    ::packYuv420pToNv12(src, yOut, uvOut);
}

bool VideoSegmentDecoder::convertAnyToNV12(void* avFramePtr, Nv12Frame& out)
{
    AVFrame* f = static_cast<AVFrame*>(avFramePtr);

    int srcRange = (f->color_range == AVCOL_RANGE_JPEG) ? 1 : 0;
    AVPixelFormat srcFmt = static_cast<AVPixelFormat>(f->format);
    if (srcFmt == AV_PIX_FMT_NV12) {
        out = makeNv12FromAVFrame(f);
        return out.isValid();
    }

    srcFmt = normalizeYuvjFormat(srcFmt, srcRange);

    if (srcFmt == AV_PIX_FMT_YUV420P) {
        const int w = safe_w(f), h = safe_h(f);
        if (w <= 0 || h <= 0) return false;
        m_ff->dstY.resize(w*h);
        m_ff->dstUV.resize((w*h)/2);
        packYuv420pToNv12(f, m_ff->dstY, m_ff->dstUV);
        out = Nv12Frame(w, h, m_ff->dstY, m_ff->dstUV);
        return out.isValid();
    }

    const int w = safe_w(f), h = safe_h(f);
    if (!m_ff->sws || m_ff->swsW != w || m_ff->swsH != h || m_ff->swsSrcFmt != srcFmt || m_ff->swsSrcRange != srcRange) {
        SwsContext* ctx = sws_getCachedContext(
            m_ff->sws, w, h, srcFmt,
            w, h, AV_PIX_FMT_NV12,
            SWS_FAST_BILINEAR, nullptr, nullptr, nullptr
            );
        if (!ctx) return false;
        m_ff->sws = ctx; m_ff->swsW = w; m_ff->swsH = h; m_ff->swsSrcFmt = srcFmt; m_ff->swsSrcRange = srcRange;

        const int cs = swsMatrixFromAV(static_cast<AVColorSpace>(f->colorspace), w, h);
        const int* coefs = sws_getCoefficients(cs);
        const int dstRange = 0;
        sws_setColorspaceDetails(m_ff->sws, coefs, srcRange, coefs, dstRange, 0, 1<<16, 1<<16);
    }

    m_ff->dstY.resize(w*h);
    m_ff->dstUV.resize((w*h)/2);

    const uint8_t* srcData[4] = { f->data[0], f->data[1], f->data[2], f->data[3] };
    const int      srcStride[4]= { f->linesize[0], f->linesize[1], f->linesize[2], f->linesize[3] };

    uint8_t* dstData[3]   = { reinterpret_cast<uint8_t*>(m_ff->dstY.data()),
                           reinterpret_cast<uint8_t*>(m_ff->dstUV.data()),
                           nullptr };
    int      dstStride[3] = { w, w, 0 };

    const int scaled = sws_scale(m_ff->sws, srcData, srcStride, 0, h, dstData, dstStride);
    if (scaled <= 0) return false;

    out = Nv12Frame(w, h, m_ff->dstY, m_ff->dstUV);
    return out.isValid();
}

bool VideoSegmentDecoder::receiveOneFrame()
{
    if (!m_ff || !m_ff->dec || !m_ff->frm) return false;

    const int ret = avcodec_receive_frame(m_ff->dec, m_ff->frm);
    if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) return false;
    if (ret < 0) return false;

    Nv12Frame nv;
    if (!convertAnyToNV12(m_ff->frm, nv)) {
        av_frame_unref(m_ff->frm);
        return false;
    }

    const qint64 pts = framePtsMs(m_ff->frm);
    m_lastPtsMs = pts;

    const QDateTime ts = QDateTime::fromMSecsSinceEpoch(pts, Qt::UTC);
    if (!m_batchStartUtc.isValid())
        m_batchStartUtc = ts;

    emit decodedFrame(m_requester, nv, ts);
    m_batch.append(nv);

    av_frame_unref(m_ff->frm);
    return true;
}

bool VideoSegmentDecoder::drainDecoder()
{
    if (!m_ff || !m_ff->dec) return true;
    avcodec_send_packet(m_ff->dec, nullptr);
    while (true) {
        const int ret = avcodec_receive_frame(m_ff->dec, m_ff->frm);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
        if (ret < 0) break;

        Nv12Frame nv;
        if (convertAnyToNV12(m_ff->frm, nv)) {
            const qint64 pts = framePtsMs(m_ff->frm);
            m_lastPtsMs = pts;
            const QDateTime ts = QDateTime::fromMSecsSinceEpoch(pts, Qt::UTC);
            if (!m_batchStartUtc.isValid())
                m_batchStartUtc = ts;

            emit decodedFrame(m_requester, nv, ts);
            m_batch.append(nv);
        }
        av_frame_unref(m_ff->frm);
    }
    return true;
}

void VideoSegmentDecoder::finalizeBatch()
{
    if (m_batch.isEmpty()) return;
    QVector<Nv12Frame> tmp;
    tmp.reserve(m_batch.size());
    for (int i = 0; i < m_batch.size(); ++i) tmp.append(m_batch[i]);
    emit decodedBatch(m_requester, tmp, m_batchStartUtc.isValid() ? m_batchStartUtc : QDateTime::fromMSecsSinceEpoch(0, Qt::UTC));
    m_batch.clear();
    m_batchStartUtc = QDateTime();
}

void VideoSegmentDecoder::closeAll()
{
    if (m_tick.isActive())
        m_tick.stop();

    if (!m_ff) return;

    if (m_ff->pkt)  { av_packet_free(&m_ff->pkt);  m_ff->pkt  = nullptr; }
    if (m_ff->frm)  { av_frame_free(&m_ff->frm);   m_ff->frm  = nullptr; }
    if (m_ff->dec)  { avcodec_free_context(&m_ff->dec); m_ff->dec = nullptr; }
    if (m_ff->fmt)  { avformat_close_input(&m_ff->fmt); m_ff->fmt = nullptr; }
    if (m_ff->avio) { avio_context_free(&m_ff->avio);   m_ff->avio = nullptr; }
    else if (m_ff->avioBuffer) { av_freep(&m_ff->avioBuffer); }
    m_ff->avioBuffer = nullptr;

    if (m_ff->sws)  { sws_freeContext(m_ff->sws); m_ff->sws = nullptr; }
    m_ff->swsW = m_ff->swsH = 0; m_ff->swsSrcFmt = AV_PIX_FMT_NONE; m_ff->swsSrcRange = 0;

    m_ff->dstY.clear();
    m_ff->dstUV.clear();

    delete m_ff; m_ff = nullptr;
}

void VideoSegmentDecoder::resetAsync()
{
    m_bin.clear();
    m_requester = nullptr;
    m_budgetFrames = 8;
    m_budgetMs = 10;
    m_firstPtsMs = qQNaN();
    m_lastPtsMs = -1;
    m_batch.clear();
    m_batchStartUtc = QDateTime();
}

bool VideoSegmentDecoder::shouldAbort() const
{
    return m_abortRequested.load() ||
        (m_cancelToken && m_cancelToken->load());
}
