#include "ExportController.h"
#include "WebSocketClient.h"
#include "ImagePipeline.h"
#include "VideoSegmentDecoder.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QFileInfo>
#include <QFile>
#include <QDir>
#include <QDate>
#include <QDebug>
#include <QBuffer>
#include <QFuture>
#include <QImage>
#include <QStringList>
#include <QtGlobal>
#include <QTemporaryFile>
#include <QVector>
#include <QtConcurrent/QtConcurrentRun>
#include <QMutex>
#include <QPointer>
#include <QMutexLocker>
#include <QTimer>
#include <QSaveFile>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <utility>
#include <deque>
#include <condition_variable>
#include <mutex>
#include <chrono>
#include <memory>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libavutil/error.h>
#include <libavutil/log.h>
}

class StreamingRemuxer;

struct ExportController::ControllerState {
    std::shared_ptr<StreamingRemuxer> remuxer;
    int dataProgress {0};
    int muxProgress {0};
    bool finalized {false};
    int receivedSegments {0};
    quint64 generationId {0};
};

namespace {

constexpr int kMaxRawMetadataEntries = 200;
constexpr int kInflightTimeoutSeconds = 10;
constexpr int kInflightCheckIntervalMs = 1500;
constexpr int kMaxSegmentRetries = 3;

static QString sanitizeFileComponent(const QString& value)
{
    QString result;
    result.reserve(value.size());
    const QString invalid = QStringLiteral("\\/:*?\"<>|");

    for (const QChar ch : value) {
        if (ch.unicode() < 0x20)
            continue;
        if (invalid.contains(ch)) {
            result.append(QLatin1Char('_'));
            continue;
        }
        result.append(ch);
    }

    result = result.trimmed();
    if (result.isEmpty())
        result = QStringLiteral("camera");
    return result;
}

static QString formatTimeForFileName(const QDateTime& dt)
{
    if (!dt.isValid())
        return QStringLiteral("unknown");
    return dt.toLocalTime().toString(QStringLiteral("yyyy-MM-dd'T'HH_mm_ss"));
}

static QString buildFileBaseName(const ExportFilePattern& pattern, int chunkIndex)
{
    const QString camera = sanitizeFileComponent(pattern.cameraId);
    const QString from   = formatTimeForFileName(pattern.fromLocal);
    const QString to     = formatTimeForFileName(pattern.toLocal);

    if (chunkIndex < 1)
        chunkIndex = 1;

    return QStringLiteral("%1 [%2 - %3] %4")
        .arg(camera, from, to, QString::number(chunkIndex));
}

static QString buildFilePath(const ExportFilePattern& pattern, int chunkIndex)
{
    if (pattern.directory.isEmpty())
        return QString();

    QString extension = pattern.extension.trimmed();
    if (extension.isEmpty())
        extension = QStringLiteral(".mkv");
    else if (!extension.startsWith(QLatin1Char('.')))
        extension.prepend(QLatin1Char('.'));

    QDir dir(pattern.directory);
    return dir.filePath(buildFileBaseName(pattern, chunkIndex) + extension);
}

static QString ffmpegErrorString(int errnum)
{
    char buf[AV_ERROR_MAX_STRING_SIZE] = {0};
    av_strerror(errnum, buf, sizeof(buf));
    return QString::fromUtf8(buf);
}

static void filteredAvLogCallback(void* ptr, int level, const char* fmt, va_list vl)
{
    char line[1024];
    int printPrefix = 1;
    va_list vlCopy;
    va_copy(vlCopy, vl);
    av_log_format_line(ptr, level, fmt, vlCopy, line, sizeof(line), &printPrefix);
    va_end(vlCopy);

    if ((strstr(line, "Packet corrupt") != nullptr) ||
        (strstr(line, "out of order") != nullptr) ||
        (strstr(line, "sps_id") != nullptr && strstr(line, "out of range") != nullptr) ||
        (strstr(line, "Error decoding the extradata") != nullptr) ||
        (strstr(line, "[mpegts") != nullptr && strstr(line, "] .") != nullptr)) {
        return;
    }

    va_list vlForward;
    va_copy(vlForward, vl);
    av_log_default_callback(ptr, level, fmt, vlForward);
    va_end(vlForward);
}

static void initFfmpegLogFiltering()
{
    static std::once_flag once;
    std::call_once(once, []() {
        av_log_set_callback(filteredAvLogCallback);
    });
}

static QString ensureUniqueFilePath(const QString& path)
{
    if (path.isEmpty())
        return path;

    QFileInfo info(path);
    QDir dir = info.dir();

    const QString fileName = info.fileName();
    const int lastDot = fileName.lastIndexOf(QLatin1Char('.'));
    const QString baseName = lastDot > 0 ? fileName.left(lastDot) : fileName;
    const QString ext = lastDot > 0 ? fileName.mid(lastDot + 1) : QString();

    QString candidate = dir.filePath(fileName);
    int index = 0;

    while (QFileInfo::exists(candidate)) {
        ++index;
        const QString withIndex = ext.isEmpty()
                                      ? QStringLiteral("%1_%2").arg(baseName, QString::number(index))
                                      : QStringLiteral("%1_%2.%3").arg(baseName, QString::number(index), ext);
        candidate = dir.filePath(withIndex);
    }

    return candidate;
}

static QString primitiveTypeToString(PrimitiveType type)
{
    switch (type) {
    case PrimitiveType::Line:
        return QStringLiteral("line");
    case PrimitiveType::Rectangle:
        return QStringLiteral("rectangle");
    case PrimitiveType::Text:
        return QStringLiteral("text");
    }
    return QStringLiteral("unknown");
}

static QJsonObject imagePipelineSettingsToJson(const ImagePipeline::Settings& s)
{
    return QJsonObject{
        {QStringLiteral("r"), s.r},
        {QStringLiteral("g"), s.g},
        {QStringLiteral("b"), s.b},
        {QStringLiteral("brightness"), s.brightness},
        {QStringLiteral("contrast"), s.contrast},
        {QStringLiteral("saturation"), s.saturation}
    };
}

} // namespace

class SegmentStreamBuffer {
public:
    explicit SegmentStreamBuffer(size_t limitBytes = 128 * 1024 * 1024)
        : m_limit(limitBytes)
    {
    }

    void pushSegment(const QByteArray& data)
    {
        if (data.isEmpty())
            return;

        {
            std::lock_guard<std::mutex> lock(m_mutex);
            if (m_abort || m_eof)
                return;

            m_queue.push_back(data);
            m_size += static_cast<size_t>(data.size());
        }
        m_cond.notify_all();
    }

    void setEof()
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_eof = true;
        m_cond.notify_all();
    }

    void abort()
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_abort = true;
        m_cond.notify_all();
    }

    bool aborted() const
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_abort;
    }

    qint64 bufferedSize() const
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        return static_cast<qint64>(m_size);
    }

    bool isFull() const
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_size >= m_limit;
    }

    int read(uint8_t* buf, int bufSize)
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        m_cond.wait(lock, [&]() { return m_abort || !m_queue.empty() || m_eof; });

        if (m_abort)
            return AVERROR_EOF;

        if (m_queue.empty() && m_eof)
            return AVERROR_EOF;

        QByteArray& front = m_queue.front();
        const int bytesLeft = front.size() - m_offset;
        const int toCopy = qMin(bufSize, bytesLeft);
        memcpy(buf, front.constData() + m_offset, static_cast<size_t>(toCopy));
        m_offset += toCopy;

        if (m_offset >= front.size()) {
            m_size -= static_cast<size_t>(front.size());
            m_queue.pop_front();
            m_offset = 0;
            m_cond.notify_all();
        }
        return toCopy;
    }

private:
    std::deque<QByteArray> m_queue;
    size_t m_limit {0};
    size_t m_size {0};
    int m_offset {0};
    bool m_eof {false};
    bool m_abort {false};
    mutable std::mutex m_mutex;
    mutable std::condition_variable m_cond;
};

class StreamingRemuxer
{
public:
    struct Config {
        QString outputPath;
        qint64 totalDurationMs {0};
        quint64 generationId {0};
    };

    StreamingRemuxer(const Config& cfg, ExportController* controller)
        : m_config(cfg)
        , m_controller(controller)
    {
    }

    ~StreamingRemuxer()
    {
        cancel();
    }

    SegmentStreamBuffer* buffer() { return &m_buffer; }

    void start()
    {
        m_future = QtConcurrent::run([this]() { run(); });
    }

    void finalize()
    {
        m_buffer.setEof();
    }

    void waitFinished()
    {
        if (m_future.isRunning())
            m_future.waitForFinished();
    }

    void cancel()
    {
        bool expected = false;
        if (!m_stopped.compare_exchange_strong(expected, true))
            return;

        m_buffer.abort();
        if (m_future.isRunning())
            m_future.waitForFinished();
    }

    void cancelNonBlocking()
    {
        bool expected = false;
        if (!m_stopped.compare_exchange_strong(expected, true))
            return;

        m_buffer.abort();
        if (m_future.isRunning()) {
            auto futureCopy = m_future;
            QtConcurrent::run([futureCopy]() mutable {
                futureCopy.waitForFinished();
            });
        }
    }

private:
    struct StreamState {
        bool    started {false};
        int64_t nextDts {0};
        int64_t nextPts {0};
        int64_t defaultDuration {1};
    };

    static int readPacket(void* opaque, uint8_t* buf, int bufSize)
    {
        auto* self = static_cast<StreamingRemuxer*>(opaque);
        return self->m_buffer.read(buf, bufSize);
    }

    void notifyProgress(int pct)
    {
        QPointer<ExportController> c = m_controller;
        if (!c)
            return;
        const quint64 gen = m_config.generationId;
        QMetaObject::invokeMethod(
            c,
            [c, pct, gen]() {
                if (!c)
                    return;
                c->onMuxProgress(pct, gen);
            },
            Qt::QueuedConnection);
    }

    void notifyFinished(bool ok, const QString& error)
    {
        QPointer<ExportController> c = m_controller;
        if (!c)
            return;
        const quint64 gen = m_config.generationId;
        QMetaObject::invokeMethod(
            c,
            [c, ok, error, gen]() {
                if (!c)
                    return;
                c->onMuxFinished(ok, error, gen);
            },
            Qt::QueuedConnection);
    }

    void notifyCancelled()
    {
        notifyFinished(false, QStringLiteral("Отменено"));
    }

    int64_t guessDefaultDuration(AVStream* inStream, AVStream* outStream)
    {
        int64_t d = 0;

        if (inStream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            AVRational fr = inStream->avg_frame_rate.num > 0 && inStream->avg_frame_rate.den > 0
                                ? inStream->avg_frame_rate
                                : inStream->r_frame_rate;
            if (fr.num > 0 && fr.den > 0) {
                AVRational invFr{ fr.den, fr.num };
                d = av_rescale_q(1, invFr, outStream->time_base);
            }
        } else if (inStream->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            if (inStream->codecpar->sample_rate > 0 &&
                inStream->codecpar->frame_size > 0) {
                AVRational sr{1, inStream->codecpar->sample_rate};
                d = av_rescale_q(inStream->codecpar->frame_size, sr, outStream->time_base);
            }
        }

        if (d <= 0)
            d = 1;
        return d;
    }

    void run()
    {
        AVFormatContext* inFmt = avformat_alloc_context();
        AVFormatContext* outFmt = nullptr;
        AVIOContext* avioCtx = nullptr;
        AVPacket* packet = av_packet_alloc();
        unsigned char* ioBuf = nullptr;
        bool ok = false;
        QString error;

        auto cleanup = [&]() {
            if (inFmt) {
                avformat_close_input(&inFmt);
                inFmt = nullptr;
            }
            if (outFmt) {
                if (!(outFmt->oformat->flags & AVFMT_NOFILE) && outFmt->pb)
                    avio_closep(&outFmt->pb);
                avformat_free_context(outFmt);
                outFmt = nullptr;
            }
            if (avioCtx) {
                avio_context_free(&avioCtx);
                avioCtx = nullptr;
            }
            if (packet) {
                av_packet_free(&packet);
                packet = nullptr;
            }
        };

        if (!inFmt) {
            error = QStringLiteral("Не удалось создать входной контекст");
            cleanup();
            notifyFinished(false, error);
            return;
        }

        initFfmpegLogFiltering();

        ioBuf = static_cast<unsigned char*>(av_malloc(64 * 1024));
        if (!ioBuf) {
            error = QStringLiteral("Не удалось выделить память для IO");
            cleanup();
            notifyFinished(false, error);
            return;
        }

        avioCtx = avio_alloc_context(ioBuf, 64 * 1024, 0, this, &StreamingRemuxer::readPacket, nullptr, nullptr);
        if (!avioCtx) {
            av_free(ioBuf);
            ioBuf = nullptr;
            error = QStringLiteral("Не удалось создать AVIOContext");
            cleanup();
            notifyFinished(false, error);
            return;
        }

        inFmt->pb = avioCtx;
        inFmt->flags |= AVFMT_FLAG_CUSTOM_IO | AVFMT_FLAG_GENPTS;
        inFmt->probesize = 512 * 1024;
        inFmt->max_analyze_duration = 1 * AV_TIME_BASE;

        const AVInputFormat* inFormat = av_find_input_format("mpegts");
        if (!inFormat) {
            error = QStringLiteral("Не удалось найти формат mpegts");
            cleanup();
            notifyFinished(false, error);
            return;
        }

        AVDictionary* fmtOpts = nullptr;
        av_dict_set(&fmtOpts, "probesize", "512k", 0);
        av_dict_set(&fmtOpts, "analyzeduration", "1000000", 0);

        int ret = avformat_open_input(&inFmt, nullptr, inFormat, &fmtOpts);
        av_dict_free(&fmtOpts);

        if (ret < 0) {
            error = QStringLiteral("Не удалось открыть входной поток: %1").arg(ffmpegErrorString(ret));
            cleanup();
            notifyFinished(false, error);
            return;
        }

        ret = avformat_find_stream_info(inFmt, nullptr);
        if (ret < 0) {
            error = QStringLiteral("Не удалось получить информацию о потоках: %1").arg(ffmpegErrorString(ret));
            cleanup();
            notifyFinished(false, error);
            return;
        }

        {
            const QByteArray outPathUtf8 = m_config.outputPath.toUtf8();
            ret = avformat_alloc_output_context2(&outFmt,
                                                 nullptr,
                                                 nullptr,
                                                 outPathUtf8.constData());
        }

        if (ret < 0 || !outFmt) {
            error = QStringLiteral("Не удалось создать выходной контекст: %1").arg(ffmpegErrorString(ret));
            cleanup();
            notifyFinished(false, error);
            return;
        }

        QVector<int> streamMapping(inFmt->nb_streams, -1);
        int outIndex = 0;
        int videoOutIndex = -1;

        for (unsigned int i = 0; i < inFmt->nb_streams; ++i) {
            AVStream* inStream = inFmt->streams[i];
            const AVMediaType mt = inStream->codecpar->codec_type;
            if (mt != AVMEDIA_TYPE_AUDIO &&
                mt != AVMEDIA_TYPE_VIDEO &&
                mt != AVMEDIA_TYPE_SUBTITLE)
                continue;

            AVStream* outStream = avformat_new_stream(outFmt, nullptr);
            if (!outStream) {
                error = QStringLiteral("Не удалось создать выходной поток");
                cleanup();
                notifyFinished(false, error);
                return;
            }

            streamMapping[i] = outIndex++;
            ret = avcodec_parameters_copy(outStream->codecpar, inStream->codecpar);
            if (ret < 0) {
                error = QStringLiteral("Не удалось скопировать параметры кодека: %1").arg(ffmpegErrorString(ret));
                cleanup();
                notifyFinished(false, error);
                return;
            }

            outStream->codecpar->codec_tag = 0;
            outStream->time_base = inStream->time_base;

            if (mt == AVMEDIA_TYPE_VIDEO && videoOutIndex < 0)
                videoOutIndex = streamMapping[i];
        }

        if (outIndex == 0) {
            error = QStringLiteral("Нет совместимых потоков для ремукса");
            cleanup();
            notifyFinished(false, error);
            return;
        }

        if (!(outFmt->oformat->flags & AVFMT_NOFILE)) {
            ret = avio_open(&outFmt->pb,
                            m_config.outputPath.toUtf8().constData(),
                            AVIO_FLAG_WRITE);
            if (ret < 0) {
                error = QStringLiteral("Не удалось открыть файл: %1").arg(ffmpegErrorString(ret));
                cleanup();
                notifyFinished(false, error);
                return;
            }
        }

        AVDictionary* muxOpts = nullptr;
        const char* ofName = outFmt->oformat ? outFmt->oformat->name : nullptr;
        if (ofName && (!qstrcmp(ofName, "mov") || !qstrcmp(ofName, "mp4"))) {
            av_dict_set(&muxOpts, "movflags", "faststart+frag_keyframe+empty_moov", 0);
        }

        ret = avformat_write_header(outFmt, muxOpts ? &muxOpts : nullptr);
        av_dict_free(&muxOpts);

        if (ret < 0) {
            error = QStringLiteral("Не удалось записать заголовок: %1").arg(ffmpegErrorString(ret));
            cleanup();
            notifyFinished(false, error);
            return;
        }

        QVector<StreamState> streamStates(outFmt->nb_streams);
        for (unsigned int i = 0; i < inFmt->nb_streams; ++i) {
            const int mapped = streamMapping.value(int(i), -1);
            if (mapped < 0)
                continue;

            AVStream* inStream = inFmt->streams[i];
            AVStream* outStream = outFmt->streams[mapped];
            StreamState& st = streamStates[mapped];
            st.defaultDuration = guessDefaultDuration(inStream, outStream);
            if (st.defaultDuration <= 0)
                st.defaultDuration = 1;
        }

        int writeErrorCount = 0;
        const int maxWriteErrorLogs = 10;

        while (true) {
            if (m_stopped.load(std::memory_order_acquire) || m_buffer.aborted()) {
                cleanup();
                notifyCancelled();
                return;
            }

            int retRead = av_read_frame(inFmt, packet);
            if (retRead == AVERROR_EOF)
                break;
            if (retRead == AVERROR(EAGAIN)) {
                QThread::msleep(5);
                continue;
            }
            if (retRead < 0) {
                qWarning() << "Read frame error" << ffmpegErrorString(retRead);
                break;
            }

            const int outStreamIndex = (packet->stream_index < (int)streamMapping.size())
                                           ? streamMapping[packet->stream_index]
                                           : -1;
            if (outStreamIndex < 0) {
                av_packet_unref(packet);
                continue;
            }

            AVStream* inStream = inFmt->streams[packet->stream_index];
            AVStream* outStream = outFmt->streams[outStreamIndex];

            av_packet_rescale_ts(packet, inStream->time_base, outStream->time_base);
            packet->stream_index = outStreamIndex;
            packet->pos = -1;

            StreamState& st = streamStates[outStreamIndex];

            if (!st.started) {
                st.started = true;
                st.nextDts = 0;
                st.nextPts = 0;
            }

            int64_t duration = packet->duration;
            if (duration <= 0)
                duration = st.defaultDuration;
            if (duration <= 0)
                duration = 1;

            packet->dts = st.nextDts;
            packet->pts = st.nextPts;
            if (packet->pts < packet->dts)
                packet->pts = packet->dts;
            packet->duration = duration;

            st.nextDts += duration;
            st.nextPts += duration;

            int retWrite = av_interleaved_write_frame(outFmt, packet);
            if (retWrite < 0) {
                if (m_buffer.aborted() || m_stopped.load(std::memory_order_acquire)) {
                    av_packet_unref(packet);
                    cleanup();
                    notifyCancelled();
                    return;
                }

                if (writeErrorCount < maxWriteErrorLogs) {
                    qWarning() << "Remux write error" << ffmpegErrorString(retWrite) << "— skipping packet";
                } else if (writeErrorCount == maxWriteErrorLogs) {
                    qWarning() << "Remux write error: too many errors, further messages suppressed";
                }
                ++writeErrorCount;

                av_packet_unref(packet);
                continue;
            }

            if (outStreamIndex == videoOutIndex && m_config.totalDurationMs > 0) {
                const int64_t curMs = av_rescale_q(packet->pts,
                                                   outStream->time_base,
                                                   AVRational{1, 1000});
                const int pct = qBound(
                    0,
                    int((curMs * 100) / qMax<qint64>(1, m_config.totalDurationMs)),
                    100);
                notifyProgress(pct);
            }

            av_packet_unref(packet);
        }

        int retTrailer = av_write_trailer(outFmt);
        if (retTrailer < 0)
            qWarning() << "Trailer write error" << ffmpegErrorString(retTrailer);

        ok = true;
        cleanup();
        notifyProgress(100);
        notifyFinished(ok, error);
    }

    Config m_config;
    QPointer<ExportController> m_controller {nullptr};
    SegmentStreamBuffer m_buffer;
    QFuture<void> m_future;
    std::atomic_bool m_stopped {false};
};

ExportController::ControllerState& ExportController::controllerState()
{
    if (!m_state)
        m_state = std::make_unique<ControllerState>();
    return *m_state;
}

void ExportController::resetControllerState()
{
    QMutexLocker locker(&m_stateMutex);
    m_state = std::make_unique<ControllerState>();
}

int ExportController::combinedProgressForState(const ControllerState& st) const
{
    const int combined = st.dataProgress + (st.muxProgress * 5) / 100;
    return combined > 99 ? 99 : combined;
}

void ExportController::updateMuxProgress(int pct)
{
    int combined = 0;
    const int clamped = qBound(0, pct, 100);
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        st.muxProgress = clamped;
        combined = combinedProgressForState(st);
    }

    const auto now = std::chrono::steady_clock::now();
    constexpr auto minInterval = std::chrono::milliseconds(150);

    if (combined < 100 &&
        m_lastMuxProgressEmit.time_since_epoch().count() > 0 &&
        now - m_lastMuxProgressEmit < minInterval &&
        combined <= exportProgress()) {
        return;
    }

    if (combined != exportProgress()) {
        m_lastMuxProgressEmit = now;
        onExportProgress(combined);
    }
}

void ExportController::onMuxProgress(int pct, quint64 genId)
{
    if (!exporting() || genId != m_exportGenerationId)
        return;

    updateMuxProgress(pct);
}

void ExportController::onMuxFinished(bool ok, const QString& err, quint64 genId)
{
    if (!exporting() || genId != m_exportGenerationId)
        return;

    std::optional<ClosingRemuxContext> ctx;
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        st.remuxer.reset();
        st.finalized = false;

        if (!m_closingRemuxers.isEmpty())
            ctx = m_closingRemuxers.dequeue();
    }

    if (!ok) {
        m_chunkClosing = false;
        onExportFinished(false, err);
        return;
    }

    if (ctx.has_value()) {
        postRemuxFinalizeChunk(*ctx);
        return;
    }

    m_chunkClosing = false;
    maybeFinishExport();
}

ExportController::ExportController(QObject* parent)
    : QObject(parent)
{
    m_previewWatcher = new QFutureWatcher<PreviewResult>(this);
    connect(m_previewWatcher, &QFutureWatcher<PreviewResult>::finished,
            this, &ExportController::onPreviewReady);
    m_inflightTimer = new QTimer(this);
    m_inflightTimer->setInterval(kInflightCheckIntervalMs);
    connect(m_inflightTimer, &QTimer::timeout,
            this, &ExportController::checkInflightTimeouts);
    resetControllerState();
}

ExportController::~ExportController()
{
    cancel();
}

ExportController::ExportController(const QUrl& wsUrl, QObject* parent)
    : ExportController(parent)
{
    setClient(new WebSocketClient(wsUrl, this));
}

void ExportController::setClient(WebSocketClient* c)
{
    if (m_client == c)
        return;

    if (m_client)
        disconnect(m_client, nullptr, this, nullptr);

    m_client = c;
    m_clientConnected = false;
    m_pendingSegmentsRequest = false;

    if (m_client) {
        connect(m_client, &WebSocketClient::textMessageReceived,
                this, &ExportController::onTextMessage);
        connect(m_client, &WebSocketClient::binaryMessageReceived,
                this, &ExportController::onBinaryMessage);
        connect(m_client, &WebSocketClient::connected,
                this, [this]() {
                    m_clientConnected = true;
                    m_pendingSegmentsRequest = false;
                    if (exporting())
                        requestSegmentsMeta();
                });
        connect(m_client, &WebSocketClient::disconnected,
                this, [this]() {
                    m_clientConnected = false;
                    if (!exporting() && m_client)
                        m_client->setAutoReconnectEnabled(false);
                });

        emit clientChanged();
    }
}

void ExportController::setExportPrimitives(bool enabled)
{
    if (m_exportPrimitives == enabled)
        return;

    m_exportPrimitives = enabled;
    emit exportPrimitivesChanged();
}

void ExportController::setExportCameraInformation(bool enabled)
{
    if (m_exportCameraInformation == enabled)
        return;

    m_exportCameraInformation = enabled;
    emit exportCameraInformationChanged();
}

void ExportController::setExportImagePipeline(bool enabled)
{
    if (m_exportImagePipeline == enabled)
        return;

    m_exportImagePipeline = enabled;
    emit exportImagePipelineChanged();
}

void ExportController::setMaxChunkDurationMinutes(int minutes)
{
    if (minutes < 0)
        minutes = 0;

    if (m_maxChunkDurationMinutes == minutes)
        return;

    m_maxChunkDurationMinutes = minutes;
    emit maxChunkDurationMinutesChanged(m_maxChunkDurationMinutes);
}

void ExportController::setMaxChunkFileSizeBytes(qint64 megabytes)
{
    if (megabytes < 0)
        megabytes = 0;

    const qint64 bytes = megabytes > 0 ? megabytes * 1024 * 1024 : 0;

    if (m_maxChunkFileSizeBytes == bytes)
        return;

    m_maxChunkFileSizeBytes = bytes;
    emit maxChunkFileSizeBytesChanged(m_maxChunkFileSizeBytes);
}

void ExportController::connectToServer()
{
    if (m_client)
        m_client->connectToServer();
}

void ExportController::onExportProgress(int v)
{
    int clamped = qBound(0, v, 100);
    if (clamped < m_exportProgress)
        clamped = m_exportProgress;

    if (clamped == m_exportProgress)
        return;

    m_exportProgress = clamped;
    emit exportProgressChanged(m_exportProgress);
}


void ExportController::startExportVideo(const QString& cameraId,
                                        const QDateTime& fromLocalTime,
                                        const QDateTime& toLocalTime,
                                        const QString& archiveId,
                                        const QString& outputPath,
                                        const QString& format)
{
    stopConsumerThread();

    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        if (st.remuxer) {
            auto remuxer = st.remuxer;
            st.remuxer.reset();
            cancelRemuxerAsync(remuxer);
        }
    }

    resetState();

    if (m_client) {
        m_client->setAutoReconnectEnabled(true);
        m_client->setAutoConnect(true);
        m_clientConnected = false;
    }

    m_chunkLimitMs = 0;
    m_chunkLimitBytes = 0;

    m_pattern = {};
    m_pattern.cameraId = cameraId;
    m_pattern.fromLocal = fromLocalTime;
    m_pattern.toLocal   = toLocalTime;

    QFileInfo fi(outputPath);
    QString requestedSuffix = format.trimmed();
    if (requestedSuffix.isEmpty())
        requestedSuffix = fi.completeSuffix().trimmed();
    if (requestedSuffix.isEmpty())
        requestedSuffix = QStringLiteral("mp4");
    m_pattern.extension = requestedSuffix;

    QString finalOutputPath;

    {
        QString baseDirPath;

        if (outputPath.endsWith(QLatin1Char('/')) ||
            outputPath.endsWith(QLatin1Char('\\')) ||
            fi.suffix().isEmpty()) {
            baseDirPath = fi.absoluteFilePath();
        } else {
            baseDirPath = fi.absolutePath();
        }

        if (baseDirPath.isEmpty())
            baseDirPath = QDir::currentPath();

        QDir baseDir(baseDirPath);
        if (!baseDir.exists()) {
            if (!baseDir.mkpath(QStringLiteral("."))) {
                const QString err =
                    QStringLiteral("Can't create a directory: %1").arg(baseDirPath);
                onExportFinished(false, err);
                return;
            }
        }

        const QString dateDirName =
            QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));

        if (!baseDir.mkpath(dateDirName)) {
            const QString err =
                QStringLiteral("Can't create a directory: %1")
                    .arg(baseDir.filePath(dateDirName));
            onExportFinished(false, err);
            return;
        }

        if (!baseDir.cd(dateDirName)) {
            const QString err =
                QStringLiteral("Can't reach a directory: %1")
                    .arg(baseDir.filePath(dateDirName));
            onExportFinished(false, err);
            return;
        }

        m_pattern.directory = baseDir.absolutePath();
        finalOutputPath = ensureUniqueFilePath(buildFilePath(m_pattern, 1));
        if (finalOutputPath.isEmpty()) {
            const QString err = QStringLiteral("Can't perform file name");
            onExportFinished(false, err);
            return;
        }
    }

    m_finalOutputPath = finalOutputPath;
    m_firstFramePreview.clear();
    emit firstFramePreviewChanged();

    start(cameraId,
          fromLocalTime.toUTC(),
          toLocalTime.toUTC(),
          archiveId,
          finalOutputPath);
}

void ExportController::cancel()
{
    const bool wasActive = exporting();
    m_active.store(false, std::memory_order_release);
    m_inflight = 0;
    m_inflightSegments.clear();
    if (m_inflightTimer)
        m_inflightTimer->stop();

    std::shared_ptr<StreamingRemuxer> remuxer;
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        remuxer = st.remuxer;
    }

    cancelRemuxerAsync(remuxer);

    stopClientReconnects();

    if (wasActive)
        onExportFinished(false, QStringLiteral("Отменено"));
}

void ExportController::start(const QString& cameraId,
                             const QDateTime& fromUtc,
                             const QDateTime& toUtc,
                             const QString& archiveId,
                             const QString& outputPath)
{
    ++m_exportGenerationId;
    m_finishEmitted = false;

    m_cameraId   = cameraId;
    m_archiveId  = archiveId;
    m_fromUtc    = fromUtc;
    m_toUtc      = toUtc;
    m_totalDurationMs = qMax<qint64>(0, m_fromUtc.msecsTo(m_toUtc));
    m_outputPath = outputPath;
    m_fps        = 0;
    m_firstFrameUtc = QDateTime();
    m_lastQueuedPtsMs = -1;
    setExportedSizeBytes(0);
    m_exportPipelineSettings.reset();

    if (m_exportImagePipeline) {
        if (m_pipeline) {
            m_exportPipelineSettings = m_pipeline->snapshot();
        } else {
            ImagePipeline fallback;
            if (!m_cameraId.isEmpty())
                fallback.setCameraId(m_cameraId);
            m_exportPipelineSettings = fallback.snapshot();
        }
    }

    m_active.store(true, std::memory_order_release);
    m_inflight = 0;
    m_inflightSegments.clear();
    if (m_inflightTimer)
        m_inflightTimer->start();

    m_pendingSegmentsRequest = false;

    m_exportStatus = Uploading;
    m_exportProgress = 0;
    m_lastLoggedExportPercent = -1;
    m_phase = Phase::Collecting;
    m_segmentsComplete = false;

    emit exportingChanged(true);
    emit statusChanged(m_exportStatus);
    emit exportProgressChanged(m_exportProgress);

    m_segmentTimes.clear();
    m_segmentTimesSet.clear();
    m_rawMetadataCount = 0;
    m_rawMetadataSample = QJsonArray();
    m_primitiveEvents.clear();
    m_primitiveEventsDirty = false;
    m_nextPageToken.clear();
    m_lastSentToken.clear();
    m_total = 0;
    m_index = 0;
    m_pendingSegments.clear();
    m_retrySegments.clear();

    m_chunkState = ChunkState{};
    m_chunkLimitMs = m_maxChunkDurationMinutes > 0
                         ? qint64(m_maxChunkDurationMinutes) * 60 * 1000
                         : 0;
    m_chunkLimitBytes = m_maxChunkFileSizeBytes > 0 ? m_maxChunkFileSizeBytes : 0;
    if (m_chunkLimitMs > 0 && m_chunkLimitBytes > 0)
        m_chunkMode = ChunkMode::Mixed;
    else if (m_chunkLimitMs > 0)
        m_chunkMode = ChunkMode::ByDuration;
    else if (m_chunkLimitBytes > 0)
        m_chunkMode = ChunkMode::BySize;
    else
        m_chunkMode = ChunkMode::SingleFile;

    m_chunkClosing = false;
    m_currentChunkPath.clear();
    m_processedDurationMs = 0;
    m_processedSegments = 0;

    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        st.dataProgress = 0;
        st.muxProgress = 0;
        st.receivedSegments = 0;
        st.finalized = false;
        st.generationId = m_exportGenerationId;
        st.remuxer.reset();
    }

    if (m_client)
        m_client->connectToServer();

    requestSegmentsMeta();
}

void ExportController::resetState()
{
    m_active.store(false, std::memory_order_release);
    m_inflight = 0;
    m_inflightSegments.clear();
    if (m_inflightTimer)
        m_inflightTimer->stop();

    m_exportStatus = Idle;
    m_exportProgress = 0;
    m_lastLoggedExportPercent = -1;
    m_phase = Phase::Finished;
    m_segmentsComplete = false;
    m_finishEmitted = false;
    setExportedSizeBytes(0);
    m_exportPipelineSettings.reset();

    m_cameraId.clear();
    m_archiveId.clear();
    m_fromUtc = QDateTime();
    m_toUtc   = QDateTime();
    m_outputPath.clear();
    m_fps = 0;

    m_nextPageToken.clear();
    m_lastSentToken.clear();
    m_segmentTimes.clear();
    m_segmentTimesSet.clear();
    m_rawMetadataCount = 0;
    m_rawMetadataSample = QJsonArray();
    m_primitiveEvents.clear();
    m_primitiveEventsDirty = false;
    m_total = 0;
    m_index = 0;
    m_firstFrameUtc = QDateTime();
    m_lastQueuedPtsMs = -1;
    m_firstFramePreview.clear();
    emit firstFramePreviewChanged();

    m_pendingSegments.clear();
    m_retrySegments.clear();
    m_segmentsComplete = false;

    m_chunkState = ChunkState{};
    m_chunkLimitMs = 0;
    m_chunkLimitBytes = 0;
    m_chunkClosing = false;
    m_lastMuxProgressEmit = {};
    m_currentChunkPath.clear();
    m_processedDurationMs = 0;
    m_totalDurationMs = 0;
    m_processedSegments = 0;
    m_pendingSegmentsRequest = false;
    m_currentChunkSegments.clear();

    while (!m_closingRemuxers.isEmpty()) {
        auto ctx = m_closingRemuxers.dequeue();
        cancelRemuxerAsync(ctx.remuxer);
    }
    m_closingRemuxers.clear();

    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        st.dataProgress = 0;
        st.muxProgress = 0;
        st.receivedSegments = 0;
        st.finalized = false;
        if (st.remuxer) {
            auto remuxer = st.remuxer;
            st.remuxer.reset();
            cancelRemuxerAsync(remuxer);
        }
    }
}

QString ExportController::toIsoUtcMs(const QDateTime &dt)
{
    return dt.toUTC().toString("yyyy-MM-dd'T'HH:mm:ss.zzz'Z'");
}

QDateTime ExportController::parseIsoUtc(const QString &s)
{
    return QDateTime::fromString(s, Qt::ISODateWithMs).toUTC();
}

QString ExportController::tokenToString(const QJsonValue& v)
{
    if (v.isString()) {
        const QString s = v.toString().trimmed();
        if (s.compare(QStringLiteral("null"), Qt::CaseInsensitive) == 0)
            return QString();
        return s;
    }

    if (v.isDouble()) {
        const double d = v.toDouble();
        const quint64 u = static_cast<quint64>(d);
        return QString::number(u);
    }

    if (v.isNull() || v.isUndefined())
        return QString();

    const QString s = v.toVariant().toString().trimmed();
    if (s.compare(QStringLiteral("null"), Qt::CaseInsensitive) == 0)
        return QString();

    return s;
}

bool ExportController::looksLikeMetadataResponse(const QJsonObject& root) const
{
    const QJsonValue dataVal = root.value(QStringLiteral("data"));
    if (!dataVal.isArray())
        return false;

    const QJsonArray dataArr = dataVal.toArray();
    for (const QJsonValue& outerVal : dataArr) {
        if (outerVal.isArray()) {
            const QJsonArray packetArr = outerVal.toArray();
            for (const QJsonValue& itemVal : packetArr) {
                if (!itemVal.isObject())
                    continue;
                const QJsonObject obj = itemVal.toObject();
                if (obj.contains(QStringLiteral("detector_name")) &&
                    obj.value(QStringLiteral("objects")).isArray()) {
                    return true;
                }
            }
        } else if (outerVal.isObject()) {
            const QJsonObject obj = outerVal.toObject();
            if (obj.contains(QStringLiteral("detector_name")) &&
                obj.value(QStringLiteral("objects")).isArray()) {
                return true;
            }
        }
    }

    return false;
}

QDateTime ExportController::earliestMetadataTime(const QJsonObject& root) const
{
    const QJsonValue dataVal = root.value(QStringLiteral("data"));
    if (!dataVal.isArray())
        return QDateTime();

    const QJsonArray dataArr = dataVal.toArray();
    QDateTime earliest;

    for (const QJsonValue& outerVal : dataArr) {
        if (!outerVal.isArray())
            continue;

        const QJsonArray packetArr = outerVal.toArray();
        for (const QJsonValue& itemVal : packetArr) {
            if (!itemVal.isObject())
                continue;

            const QJsonObject obj = itemVal.toObject();
            const QString timeStr = obj.value(QStringLiteral("time")).toString();
            const QDateTime dt = QDateTime::fromString(timeStr, Qt::ISODateWithMs).toUTC();
            if (!dt.isValid())
                continue;

            if (!earliest.isValid() || dt < earliest)
                earliest = dt;
        }
    }

    return earliest;
}

void ExportController::appendMetadataForExport(const QJsonObject& root)
{
    if (!m_exportPrimitives)
        return;

    auto normalizePoint = [](const QJsonObject& obj) {
        constexpr double coordMax = 65535.0;
        PrimitivePoint pt;
        const double x = obj.value(QStringLiteral("x")).toDouble();
        const double y = obj.value(QStringLiteral("y")).toDouble();
        pt.xNorm = qBound(0.0, x, coordMax) / coordMax;
        pt.yNorm = qBound(0.0, y, coordMax) / coordMax;
        return pt;
    };

    auto appendFromObject = [&](const QJsonObject& obj) {
        const QString timeStr = obj.value(QStringLiteral("time")).toString();
        const QDateTime utc = QDateTime::fromString(timeStr, Qt::ISODateWithMs).toUTC();
        if (!utc.isValid())
            return;

        PrimitiveEvent evt;
        evt.timeUtcMs = utc.toMSecsSinceEpoch();

        const QJsonArray objects = obj.value(QStringLiteral("objects")).toArray();
        for (const QJsonValue& primVal : objects) {
            if (!primVal.isObject())
                continue;

            const QJsonObject primObj = primVal.toObject();

            const QJsonObject textObj = primObj.value(QStringLiteral("text")).toObject();
            if (!textObj.isEmpty()) {
                PrimitiveShape shape;
                shape.type = PrimitiveType::Text;
                shape.text = textObj.value(QStringLiteral("text"))
                                 .toString(textObj.value(QStringLiteral("value")).toString());
                shape.color = textObj.value(QStringLiteral("text_color"))
                                  .toString(textObj.value(QStringLiteral("color"))
                                                .toString(QStringLiteral("#FFFFFFFF")));
                shape.fontSizePx = textObj.value(QStringLiteral("font_size")).toInt(0);
                evt.shapes.append(shape);
            }

            const QJsonObject lineObj = primObj.value(QStringLiteral("line")).toObject();
            if (!lineObj.isEmpty()) {
                PrimitiveShape shape;
                shape.type = PrimitiveType::Line;
                shape.color = lineObj.value(QStringLiteral("border_color"))
                                  .toString(QStringLiteral("#FFFF0000"));
                shape.thicknessPx = lineObj.value(QStringLiteral("thickness")).toInt(2);
                if (shape.thicknessPx <= 0)
                    shape.thicknessPx = 2;

                const QJsonArray points = lineObj.value(QStringLiteral("points")).toArray();
                for (const QJsonValue& ptVal : points) {
                    if (!ptVal.isObject())
                        continue;
                    shape.points.append(normalizePoint(ptVal.toObject()));
                }

                if (!shape.points.isEmpty())
                    evt.shapes.append(shape);
            }

            const QJsonObject rectObj = primObj.value(QStringLiteral("rectangle")).toObject();
            if (!rectObj.isEmpty()) {
                PrimitiveShape shape;
                shape.type = PrimitiveType::Rectangle;
                shape.color = rectObj.value(QStringLiteral("border_color"))
                                  .toString(QStringLiteral("#FFFF0000"));
                shape.thicknessPx = rectObj.value(QStringLiteral("thickness")).toInt(2);
                if (shape.thicknessPx <= 0)
                    shape.thicknessPx = 2;

                const QJsonArray points = rectObj.value(QStringLiteral("points")).toArray();
                for (const QJsonValue& ptVal : points) {
                    if (!ptVal.isObject())
                        continue;
                    shape.points.append(normalizePoint(ptVal.toObject()));
                }

                if (!shape.points.isEmpty())
                    evt.shapes.append(shape);
            }
        }

        if (!evt.shapes.isEmpty()) {
            m_primitiveEvents.append(evt);
            m_primitiveEventsDirty = true;
        }
    };

    const QJsonArray dataArr = root.value(QStringLiteral("data")).toArray();
    for (const QJsonValue& outerVal : dataArr) {
        if (outerVal.isArray()) {
            const QJsonArray packetArr = outerVal.toArray();
            for (const QJsonValue& itemVal : packetArr) {
                if (!itemVal.isObject())
                    continue;
                appendFromObject(itemVal.toObject());
            }
        } else if (outerVal.isObject()) {
            appendFromObject(outerVal.toObject());
        }
    }
}

void ExportController::buildPrimitiveEventsFromMetadata()
{
    if (!m_primitiveEventsDirty)
        return;

    m_primitiveEventsDirty = false;

    std::sort(m_primitiveEvents.begin(),
              m_primitiveEvents.end(),
              [](const PrimitiveEvent& a, const PrimitiveEvent& b) {
                  return a.timeUtcMs < b.timeUtcMs;
              });
}

bool ExportController::writeSidecarMetadataJson(const QString& chunkPath,
                                                const ChunkState& chunk,
                                                const QDateTime& endUtc)
{
    if (chunkPath.isEmpty())
        return false;

    QJsonObject root;
    root.insert(QStringLiteral("file_path"), chunkPath);
    root.insert(QStringLiteral("chunk_index"), chunk.index);
    root.insert(QStringLiteral("camera_id"), m_cameraId);
    root.insert(QStringLiteral("archive_id"), m_archiveId);
    root.insert(QStringLiteral("from_utc"), toIsoUtcMs(m_fromUtc));
    root.insert(QStringLiteral("to_utc"), toIsoUtcMs(m_toUtc));
    root.insert(QStringLiteral("chunk_start_utc"),
                chunk.startUtc.isValid() ? toIsoUtcMs(chunk.startUtc) : QString());
    root.insert(QStringLiteral("chunk_end_utc"),
                endUtc.isValid() ? toIsoUtcMs(endUtc) : QString());
    root.insert(QStringLiteral("duration_ms"), QJsonValue::fromVariant(chunk.durationMs));
    root.insert(QStringLiteral("size_bytes"), QJsonValue::fromVariant(chunk.sizeBytes));

    root.insert(QStringLiteral("export_flags"),
                QJsonObject{
                    {QStringLiteral("primitives"), m_exportPrimitives},
                    {QStringLiteral("camera_information"), m_exportCameraInformation},
                    {QStringLiteral("image_pipeline"), m_exportImagePipeline}
                });

    if (m_exportImagePipeline) {
        if (m_exportPipelineSettings.has_value()) {
            root.insert(QStringLiteral("image_pipeline_settings"),
                        imagePipelineSettingsToJson(*m_exportPipelineSettings));
        } else {
            root.insert(QStringLiteral("image_pipeline_settings"), QJsonValue::Null);
        }
    }

    if (m_exportPrimitives && m_rawMetadataCount > 0) {
        if (m_rawMetadataCount <= kMaxRawMetadataEntries) {
            root.insert(QStringLiteral("raw_metadata"), m_rawMetadataSample);
        } else {
            root.insert(QStringLiteral("raw_metadata_count"), m_rawMetadataCount);
        }
    }

    if (m_exportCameraInformation) {
        QJsonObject cameraInfo{
            {QStringLiteral("camera_id"), m_cameraId},
            {QStringLiteral("archive_id"), m_archiveId}
        };
        if (m_fps > 0)
            cameraInfo.insert(QStringLiteral("fps"), m_fps);
        if (m_firstFrameUtc.isValid())
            cameraInfo.insert(QStringLiteral("first_frame_utc"), toIsoUtcMs(m_firstFrameUtc));
        root.insert(QStringLiteral("camera_information"), cameraInfo);
    }

    const QString metaPath = chunkPath + QStringLiteral(".json");
    QSaveFile file(metaPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;

    auto writeAll = [&file](const QByteArray& payload) {
        return file.write(payload) == payload.size();
    };

    const QJsonDocument baseDoc(root);
    QByteArray basePayload = baseDoc.toJson(QJsonDocument::Compact);

    if (!m_exportPrimitives) {
        if (!writeAll(basePayload))
            return false;
        return file.commit();
    }

    if (basePayload == "{}") {
        if (!writeAll(QByteArrayLiteral("{\"primitives\":[")))
            return false;
    } else {
        if (!basePayload.endsWith('}'))
            return false;
        basePayload.chop(1);
        if (!writeAll(basePayload))
            return false;
        if (!writeAll(QByteArrayLiteral(",\"primitives\":[")))
            return false;
    }

    const bool filterRange = chunk.startUtc.isValid() && endUtc.isValid();
    const qint64 startMs = filterRange ? chunk.startUtc.toMSecsSinceEpoch() : 0;
    const qint64 endMs = filterRange ? endUtc.toMSecsSinceEpoch() : 0;
    bool first = true;

    for (const PrimitiveEvent& evt : std::as_const(m_primitiveEvents)) {
        if (filterRange && (evt.timeUtcMs < startMs || evt.timeUtcMs > endMs))
            continue;

        QJsonArray shapesArray;
        for (const PrimitiveShape& shape : evt.shapes) {
            QJsonArray pointsArray;
            for (const PrimitivePoint& pt : shape.points) {
                pointsArray.append(QJsonObject{
                    {QStringLiteral("x"), pt.xNorm},
                    {QStringLiteral("y"), pt.yNorm}
                });
            }

            shapesArray.append(QJsonObject{
                {QStringLiteral("type"), primitiveTypeToString(shape.type)},
                {QStringLiteral("color"), shape.color},
                {QStringLiteral("thickness_px"), shape.thicknessPx},
                {QStringLiteral("font_size_px"), shape.fontSizePx},
                {QStringLiteral("points"), pointsArray},
                {QStringLiteral("text"), shape.text}
            });
        }

        QJsonObject evtObj{
            {QStringLiteral("time_utc_ms"), QJsonValue::fromVariant(evt.timeUtcMs)},
            {QStringLiteral("shapes"), shapesArray}
        };

        const QByteArray evtPayload = QJsonDocument(evtObj).toJson(QJsonDocument::Compact);
        if (!first) {
            if (!writeAll(QByteArrayLiteral(",")))
                return false;
        }
        if (!writeAll(evtPayload))
            return false;
        first = false;
    }

    if (!writeAll(QByteArrayLiteral("]}")))
        return false;

    return file.commit();
}

void ExportController::setExportedSizeBytes(qint64 bytes)
{
    if (bytes < 0)
        bytes = 0;
    if (m_exportedSizeBytes == bytes)
        return;

    m_exportedSizeBytes = bytes;
    emit exportedSizeBytesChanged(m_exportedSizeBytes);
}

QString ExportController::buildChunkTargetPath(const QDateTime& startUtc,
                                               const QDateTime& endUtc,
                                               int chunkIndex) const
{
    ExportFilePattern pattern = m_pattern;
    pattern.fromLocal = startUtc.toLocalTime();
    pattern.toLocal = endUtc.toLocalTime();
    return ensureUniqueFilePath(buildFilePath(pattern, chunkIndex));
}

bool ExportController::shouldStartNewChunk(const ChunkState& chunk,
                                           qint64 segDurMs,
                                           qint64 segBytes) const
{
    Q_UNUSED(segDurMs);
    Q_UNUSED(segBytes);

    if (!chunk.active())
        return false;

    const qint64 durationLimit = m_chunkLimitMs;
    const qint64 sizeLimit     = m_chunkLimitBytes;

    switch (m_chunkMode) {
    case ChunkMode::SingleFile:
        return false;

    case ChunkMode::ByDuration:
        if (durationLimit <= 0)
            return false;
        // Режем, как только накопленная длительность чанка
        // достигла или превысила лимит.
        return chunk.durationMs >= durationLimit;

    case ChunkMode::BySize:
        if (sizeLimit <= 0)
            return false;
        return chunk.sizeBytes >= sizeLimit;

    case ChunkMode::Mixed: {
        bool cutByDuration = false;
        bool cutBySize     = false;

        if (durationLimit > 0)
            cutByDuration = (chunk.durationMs >= durationLimit);

        if (sizeLimit > 0)
            cutBySize = (chunk.sizeBytes >= sizeLimit);

        return cutByDuration || cutBySize;
    }
    }

    return false;
}

bool ExportController::openNewChunk(const QDateTime& segmentStartUtc)
{
    m_chunkState.startUtc = segmentStartUtc.isValid() ? segmentStartUtc : m_fromUtc;
    m_chunkState.endUtc = QDateTime();
    m_chunkState.durationMs = 0;
    m_chunkState.sizeBytes = 0;

    QMutexLocker locker(&m_stateMutex);
    ControllerState& st = controllerState();
    if (st.remuxer) {
        auto remuxer = st.remuxer;
        st.remuxer.reset();
        cancelRemuxerAsync(remuxer);
    }

    QDateTime initialEndUtc = m_chunkState.startUtc;
    if (!initialEndUtc.isValid())
        initialEndUtc = m_toUtc;

    m_currentChunkPath = buildChunkTargetPath(m_chunkState.startUtc,
                                              initialEndUtc,
                                              m_chunkState.index);

    StreamingRemuxer::Config cfg;
    cfg.outputPath = m_currentChunkPath;
    cfg.totalDurationMs = m_chunkLimitMs > 0 ? m_chunkLimitMs : m_totalDurationMs;
    cfg.generationId = m_exportGenerationId;
    st.finalized = false;
    st.remuxer = std::make_shared<StreamingRemuxer>(cfg, this);
    st.remuxer->start();
    return true;
}

QString ExportController::createTempSegmentFile(const QByteArray& data) const
{
    QTemporaryFile tmp(QDir::temp().filePath(QStringLiteral("qarchive_segmentXXXXXX.mp4")));
    tmp.setAutoRemove(false);

    if (!tmp.open())
        return QString();

    if (tmp.write(data) != data.size())
        return QString();

    tmp.flush();
    return tmp.fileName();
}

void ExportController::maybeUpdatePreview(const QByteArray& segment)
{
    if (!m_firstFramePreview.isEmpty() || segment.isEmpty() || !m_previewWatcher)
        return;

    if (m_previewWatcher->isRunning())
        return;

    const QString cameraId = m_cameraId;
    std::optional<ImagePipeline::Settings> pipelineSettings;
    if (m_pipeline)
        pipelineSettings = m_pipeline->snapshot();

    const quint64 generationId = m_exportGenerationId;
    m_previewFuture = QtConcurrent::run([segment, cameraId, pipelineSettings, generationId]() -> PreviewResult {
        PreviewResult result;
        result.generationId = generationId;

        if (segment.isEmpty())
            return result;

        VideoSegmentDecoder decoder;
        const auto first = decoder.decodeFirstFrameNV12(segment);
        if (!first.frame.isValid())
            return result;

        ImagePipeline pipeline;
        if (!cameraId.isEmpty())
            pipeline.setCameraId(cameraId);
        if (pipelineSettings.has_value())
            pipeline.setFromSnapshot(*pipelineSettings);

        const QImage img = pipeline.toImage(first.frame);
        if (img.isNull())
            return result;

        QByteArray bytes;
        QBuffer buf(&bytes);
        buf.open(QIODevice::WriteOnly);
        const bool ok = img.save(&buf, "JPEG");
        buf.close();

        if (!ok || bytes.isEmpty())
            return result;

        result.dataUri =
            QStringLiteral("data:image/jpeg;base64,%1")
                .arg(QString::fromLatin1(bytes.toBase64()));
        return result;
    });

    m_previewWatcher->setFuture(m_previewFuture);
}

void ExportController::onPreviewReady()
{
    if (!m_previewWatcher)
        return;

    const PreviewResult result = m_previewWatcher->result();

    if (result.generationId != m_exportGenerationId)
        return;

    if (!m_firstFramePreview.isEmpty())
        return;

    if (result.dataUri.isEmpty())
        return;

    m_firstFramePreview = result.dataUri;
    emit firstFramePreviewChanged();
}

bool ExportController::appendSegment(const QByteArray& data, const SegmentMeta& meta)
{
    const qint64 bytes      = data.size();
    const qint64 durationMs = estimateSegmentDurationMs(meta);

    if (!m_chunkState.active()) {
        if (!openNewChunk(meta.startUtc))
            return false;
    }

    StreamingRemuxer* remuxer = nullptr;
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        remuxer = st.remuxer.get();
    }

    if (remuxer)
        remuxer->buffer()->pushSegment(data);
    m_chunkState.durationMs += durationMs;
    m_chunkState.sizeBytes  += bytes;

    if (meta.startUtc.isValid() && durationMs > 0)
        m_chunkState.endUtc = meta.startUtc.addMSecs(durationMs);
    else if (durationMs > 0 && m_chunkState.startUtc.isValid())
        m_chunkState.endUtc = m_chunkState.startUtc.addMSecs(m_chunkState.durationMs);

    updateProgressByDuration(durationMs);

    if (shouldStartNewChunk(m_chunkState, durationMs, bytes)) {
        finalizeChunk(true);
        clearChunkState();
        ++m_chunkState.index;
    }

    return true;
}


qint64 ExportController::estimateSegmentDurationMs(const SegmentMeta& meta) const
{
    if (!meta.startUtc.isValid())
        return 0;

    QDateTime nextStart;
    const int nextIdx = meta.index + 1;
    if (nextIdx < m_total)
        nextStart = parseIsoUtc(m_segmentTimes.value(nextIdx));
    else
        nextStart = m_toUtc;

    qint64 durationMs = 0;
    if (nextStart.isValid())
        durationMs = meta.startUtc.msecsTo(nextStart);

    if (durationMs <= 0 && m_totalDurationMs > 0 && m_total > 0)
        durationMs = m_totalDurationMs / m_total;

    return durationMs > 0 ? durationMs : 0;
}

bool ExportController::canFinishExport() const
{
    return m_inflight == 0 &&
           m_segmentsComplete &&
           m_pendingSegments.isEmpty() &&
           m_retrySegments.isEmpty() &&
           m_closingRemuxers.isEmpty();
}

void ExportController::maybeFinishExport()
{
    if (!exporting() || !canFinishExport())
        return;

    bool hasRemuxer = false;
    {
        QMutexLocker locker(&m_stateMutex);
        hasRemuxer = static_cast<bool>(controllerState().remuxer);
    }

    if (hasRemuxer) {
        finalizeChunk(true);
        return;
    }

    onExportFinished(true, QString());
}

void ExportController::discardCurrentChunk()
{
    m_chunkState.durationMs = 0;
    m_chunkState.sizeBytes = 0;
}

void ExportController::finalizeChunk(bool writeOut)
{
    if (m_exportPrimitives && m_primitiveEventsDirty)
        buildPrimitiveEventsFromMetadata();

    ClosingRemuxContext ctx;
    bool enqueueContext = false;

    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        if (!st.remuxer)
            return;

        if (writeOut) {
            if (!st.finalized) {
                st.finalized = true;
                m_chunkClosing = true;
                ctx.remuxer = st.remuxer;
                ctx.writeOut = true;
                ctx.chunkState = m_chunkState;
                ctx.chunkPath = m_currentChunkPath;
                enqueueContext = true;
                st.remuxer->finalize();
                st.remuxer.reset();
            }
        } else {
            ctx.remuxer = st.remuxer;
            ctx.writeOut = false;
            ctx.chunkState = m_chunkState;
            ctx.chunkPath = m_currentChunkPath;
            enqueueContext = true;
            st.remuxer->cancelNonBlocking();
            st.remuxer.reset();
        }
    }

    if (enqueueContext)
        m_closingRemuxers.enqueue(ctx);
}

void ExportController::postRemuxFinalizeChunk(const ClosingRemuxContext& ctx)
{
    const ChunkState chunk = ctx.chunkState;
    QString chunkPath = ctx.chunkPath;

    if (!ctx.writeOut) {
        m_chunkClosing = false;
        maybeFinishExport();
        return;
    }

    if (chunk.sizeBytes <= 0 || chunk.durationMs <= 0) {
        if (!chunkPath.isEmpty())
            QFile::remove(chunkPath);
        m_chunkClosing = false;
        return;
    }

    QDateTime endUtc = chunk.endUtc;
    if (!endUtc.isValid() && chunk.startUtc.isValid() && chunk.durationMs > 0) {
        endUtc = chunk.startUtc.addMSecs(chunk.durationMs);
    }

    if (chunk.startUtc.isValid()) {
        if (!endUtc.isValid() && chunk.durationMs > 0)
            endUtc = chunk.startUtc.addMSecs(chunk.durationMs);
        if (!endUtc.isValid())
            endUtc = chunk.startUtc.isValid() ? chunk.startUtc : m_toUtc;

        const QString desiredPath = buildChunkTargetPath(chunk.startUtc, endUtc, chunk.index);
        if (!desiredPath.isEmpty() && desiredPath != chunkPath) {
            QFile::remove(desiredPath);
            QFile::rename(chunkPath, desiredPath);
            chunkPath = desiredPath;
        }
    }

    const bool needsMetadata = m_exportImagePipeline || m_exportPrimitives || m_exportCameraInformation;
    if (needsMetadata && !chunkPath.isEmpty()) {
        updateMuxProgress(95);
        if (!writeSidecarMetadataJson(chunkPath, chunk, endUtc)) {
            const QString metaPath = chunkPath + QStringLiteral(".json");
            qWarning() << "[Export] Failed to write metadata JSON" << metaPath;
            m_chunkClosing = false;
            onExportFinished(false,
                             QStringLiteral("Failed to write metadata JSON: %1")
                                 .arg(metaPath));
            return;
        }
    }

    m_chunkClosing = false;
    updateMuxProgress(100);
    maybeFinishExport();
}

void ExportController::clearChunkState()
{
    const int currentIndex = m_chunkState.index;
    m_chunkState = ChunkState{};
    m_chunkState.index = currentIndex;
    m_currentChunkPath.clear();
    m_chunkClosing = false;
}

void ExportController::updateProgressByDuration(qint64 appendedDurationMs)
{
    if (m_totalDurationMs <= 0)
        return;
    const double ratio = double(appendedDurationMs) / double(m_totalDurationMs);
    int combined = 0;
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        st.dataProgress = qBound(0, st.dataProgress + int(ratio * 95.0), 95);
        combined = combinedProgressForState(st);
    }
    onExportProgress(combined);
}

void ExportController::onTextMessage(const QString& msg)
{
    QJsonParseError e;
    const auto doc = QJsonDocument::fromJson(msg.toUtf8(), &e);
    if (e.error != QJsonParseError::NoError || !doc.isObject())
        return;

    handleTextMessage(doc.object());
}

bool ExportController::handleTextMessage(const QJsonObject& root)
{
    if (!exporting())
        return false;

    m_pendingSegmentsRequest = false;

    if (looksLikeMetadataResponse(root)) {
        ++m_rawMetadataCount;
        if (m_rawMetadataSample.size() >= kMaxRawMetadataEntries)
            m_rawMetadataSample.removeAt(0);
        m_rawMetadataSample.append(root);
        appendMetadataForExport(root);
        return true;
    }

    QJsonArray arr;
    QString nextPage;
    bool looksSegments = false;

    if (root.value(QStringLiteral("segments")).isArray()) {
        looksSegments = true;
        arr = root.value(QStringLiteral("segments")).toArray();
        nextPage = tokenToString(root.value(QStringLiteral("next_page")));
    }

    if (!looksSegments) {
        if (root.value(QStringLiteral("data")).isArray()) {
            looksSegments = true;
            arr = root.value(QStringLiteral("data")).toArray();
            nextPage = tokenToString(root.value(QStringLiteral("next_page")));
        } else if (root.value(QStringLiteral("data")).isObject()) {
            const QJsonObject d = root.value(QStringLiteral("data")).toObject();
            if (d.contains(QStringLiteral("segments"))) {
                looksSegments = true;
                arr = d.value(QStringLiteral("segments")).toArray();
                nextPage = tokenToString(d.value(QStringLiteral("next_page")));
            }
        } else if (root.value(QStringLiteral("type")).toString() ==
                   QLatin1String("segments")) {
            looksSegments = true;
        }
    }

    if (!looksSegments)
        return false;

    auto addSegmentTime = [this](const QString& at) {
        if (at.isEmpty())
            return;
        if (m_segmentTimesSet.contains(at))
            return;
        m_segmentTimesSet.insert(at);
        m_segmentTimes.push_back(at);
    };

    for (const auto& v : std::as_const(arr)) {
        if (v.isString()) {
            const QString ts = v.toString();
            addSegmentTime(ts);
        } else if (v.isObject()) {
            const QJsonObject so = v.toObject();
            QString at = so.value(QStringLiteral("at")).toString();
            if (at.isEmpty())
                at = so.value(QStringLiteral("time")).toString();
            if (at.isEmpty())
                at = so.value(QStringLiteral("start")).toString();
            addSegmentTime(at);
        }
    }

    const bool hasNext = !nextPage.isEmpty();
    const bool loopDetected =
        hasNext && !m_lastSentToken.isEmpty() && (nextPage == m_lastSentToken);

    m_total = m_segmentTimes.size();

    if (hasNext && !loopDetected) {
        m_nextPageToken = nextPage;
        requestSegmentsMeta();

        if (m_total > m_index)
            fetchNextExportSegment();

        return true;
    }

    m_nextPageToken.clear();
    m_lastSentToken.clear();
    m_segmentsComplete = true;
    m_total = m_segmentTimes.size();

    if (m_total == 0) {
        m_active.store(false, std::memory_order_release);
        onExportFinished(false, QStringLiteral("Empty segment list"));
        return true;
    }

    if (m_total > m_index)
        fetchNextExportSegment();

    return true;
}

void ExportController::requestSegmentsMeta()
{
    if (!exporting() || !m_client)
        return;

    if (m_pendingSegmentsRequest)
        return;

    QJsonObject q{{QStringLiteral("camera_id"), m_cameraId},
                  {QStringLiteral("archive_id"), m_archiveId},
                  {QStringLiteral("from"), toIsoUtcMs(m_fromUtc)},
                  {QStringLiteral("to"), toIsoUtcMs(m_toUtc)}};

    if (!m_nextPageToken.isEmpty()) {
        q.insert(QStringLiteral("page_token"), m_nextPageToken);
        m_lastSentToken = m_nextPageToken;
    } else {
        m_lastSentToken.clear();
    }

    m_pendingSegmentsRequest = true;
    m_lastSentToken = m_nextPageToken;
    m_client->sendRequest(QJsonObject{{QStringLiteral("segments"), q}});
}

void ExportController::enqueueSegmentRequest(const SegmentMeta& meta)
{
    if (!m_client || !exporting())
        return;

    SegmentMeta requestMeta = meta;
    if (requestMeta.atIso.isEmpty() && requestMeta.startUtc.isValid())
        requestMeta.atIso = toIsoUtcMs(requestMeta.startUtc);

    if (requestMeta.atIso.isEmpty())
        return;

    m_pendingSegments.enqueue(requestMeta);
    ++m_inflight;
    m_inflightSegments.insert(requestMeta.index,
                              InflightSegmentInfo{
                                  QDateTime::currentDateTimeUtc(),
                                  requestMeta.atIso,
                                  requestMeta.retryCount
                              });

    QJsonObject q{
        {QStringLiteral("camera_id"),  m_cameraId},
        {QStringLiteral("archive_id"), m_archiveId},
        {QStringLiteral("at"),         requestMeta.atIso}
    };

    m_client->sendRequest(QJsonObject{{QStringLiteral("segment"), q}});
    if (m_exportPrimitives)
        m_client->sendRequest(QJsonObject{{QStringLiteral("metadata"), q}});
}

void ExportController::fetchNextExportSegment()
{
    if (!m_client || !exporting())
        return;

    SegmentStreamBuffer* buffer = nullptr;
    bool bufferThrottled = false;
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        if (st.remuxer)
            buffer = st.remuxer->buffer();
    }

    if (buffer && buffer->isFull())
        bufferThrottled = true;

    if (m_index >= m_total && m_retrySegments.isEmpty()) {
        if (!m_segmentsComplete || m_inflight > 0)
            return;
        m_phase = Phase::Writing;
        return;
    }

    while (!bufferThrottled && m_inflight < m_maxInflight &&
           (!m_retrySegments.isEmpty() || m_index < m_total)) {
        SegmentMeta meta;
        if (!m_retrySegments.isEmpty()) {
            meta = m_retrySegments.dequeue();
        } else {
            const QString atIso = m_segmentTimes[m_index];
            meta.index = m_index;
            meta.atIso = atIso;
            meta.startUtc = parseIsoUtc(atIso);
            meta.retryCount = 0;
            ++m_index;
        }

        enqueueSegmentRequest(meta);

        if (buffer && buffer->isFull())
            bufferThrottled = true;
    }

    if (bufferThrottled) {
        QPointer<ExportController> self(this);
        QTimer::singleShot(50, this, [self]() {
            if (!self)
                return;
            self->fetchNextExportSegment();
        });
    }
}

void ExportController::checkInflightTimeouts()
{
    if (!exporting())
        return;

    const QDateTime now = QDateTime::currentDateTimeUtc();
    QSet<int> expiredIndices;
    QQueue<SegmentMeta> retrySegments;

    for (auto it = m_inflightSegments.begin(); it != m_inflightSegments.end(); ) {
        const InflightSegmentInfo& info = it.value();
        const qint64 ageSec = info.sentAtUtc.secsTo(now);
        if (ageSec > kInflightTimeoutSeconds) {
            if (info.retryCount < kMaxSegmentRetries) {
                SegmentMeta meta;
                meta.index = it.key();
                meta.atIso = info.atIso;
                meta.startUtc = parseIsoUtc(info.atIso);
                meta.retryCount = info.retryCount + 1;
                retrySegments.enqueue(meta);
                qWarning() << "[Export] segment timeout, retry"
                           << "camera" << m_cameraId
                           << "segment" << info.atIso
                           << "retry" << meta.retryCount
                           << "age_sec" << ageSec;
            } else {
                qWarning() << "[Export] segment timeout, giving up"
                           << "camera" << m_cameraId
                           << "segment" << info.atIso
                           << "retries" << info.retryCount
                           << "age_sec" << ageSec;
            }
            expiredIndices.insert(it.key());
            if (m_inflight > 0)
                --m_inflight;
            it = m_inflightSegments.erase(it);
            continue;
        }
        ++it;
    }

    if (expiredIndices.isEmpty())
        return;

    if (!m_pendingSegments.isEmpty()) {
        QQueue<SegmentMeta> remaining;
        while (!m_pendingSegments.isEmpty()) {
            SegmentMeta meta = m_pendingSegments.dequeue();
            if (!expiredIndices.contains(meta.index))
                remaining.enqueue(meta);
        }
        m_pendingSegments = remaining;
    }

    if (!retrySegments.isEmpty()) {
        QQueue<SegmentMeta> combined;
        while (!retrySegments.isEmpty())
            combined.enqueue(retrySegments.dequeue());
        while (!m_retrySegments.isEmpty())
            combined.enqueue(m_retrySegments.dequeue());
        m_retrySegments = combined;
    }

    fetchNextExportSegment();
}

void ExportController::cancelRemuxerAsync(const std::shared_ptr<StreamingRemuxer>& remuxer)
{
    if (!remuxer)
        return;

    remuxer->cancelNonBlocking();
}

void ExportController::stopClientReconnects()
{
    if (!m_client)
        return;

    m_client->setAutoReconnectEnabled(false);
    m_client->close();
    m_clientConnected = false;
}

void ExportController::stopConsumerThread()
{
    m_active.store(false, std::memory_order_release);
    if (m_stopConsumerPending)
        return;

    if (!m_stateMutex.tryLock()) {
        m_stopConsumerPending = true;
        QTimer::singleShot(0, this, [this]() {
            m_stopConsumerPending = false;
            stopConsumerThread();
        });
        return;
    }

    QMutexLocker locker(&m_stateMutex, QMutexLocker::AdoptLock);
    ControllerState& st = controllerState();
    if (st.remuxer) {
        auto remuxer = st.remuxer;
        st.remuxer.reset();
        cancelRemuxerAsync(remuxer);
    }
}

void ExportController::onBinaryMessage(const QByteArray& bin)
{
    if (!exporting())
        return;

    if (m_inflight > 0)
        --m_inflight;

    SegmentMeta meta;
    const bool haveMeta = !m_pendingSegments.isEmpty();
    if (haveMeta) {
        meta = m_pendingSegments.dequeue();
        m_inflightSegments.remove(meta.index);
    }

    if (bin.isEmpty()) {
        fetchNextExportSegment();
        return;
    }

    maybeUpdatePreview(bin);

    if (!appendSegment(bin, meta))
        return;

    int combined = exportProgress();
    {
        QMutexLocker locker(&m_stateMutex);
        ControllerState& st = controllerState();
        st.receivedSegments++;

        if (m_total > 0) {
            const qint64 scaled = qint64(st.receivedSegments) * 95;
            st.dataProgress = qBound(0, int(scaled / qMax(1, m_total)), 95);
        }
        combined = combinedProgressForState(st);
    }

    setExportedSizeBytes(m_exportedSizeBytes + bin.size());

    onExportProgress(combined);

    fetchNextExportSegment();

    if (m_index >= m_total &&
        m_segmentsComplete &&
        m_pendingSegments.isEmpty() &&
        m_inflight == 0) {
        finalizeChunk(true);
    }
}

void ExportController::onExportFinished(bool ok, const QString& err)
{
    const bool wasActive = m_active.exchange(false, std::memory_order_acq_rel);
    if (m_finishEmitted)
        return;

    if (!wasActive && m_exportStatus != Uploading)
        return;

    m_finishEmitted = true;

    if (ok) {
        if (m_exportProgress < 100) {
            m_exportProgress = 100;
            emit exportProgressChanged(100);
        }
        m_exportStatus = Done;
    } else {
        m_exportStatus = Error;
        qWarning() << "[Export] failed:" << err;
        setExportedSizeBytes(0);
    }
    emit statusChanged(m_exportStatus);
    emit exportingChanged(false);
    emit finished(ok, err);

    stopConsumerThread();
    stopClientReconnects();

    m_inflight = 0;
    m_inflightSegments.clear();
    if (m_inflightTimer)
        m_inflightTimer->stop();

    QStringList().swap(m_segmentTimes);
    m_segmentTimesSet.clear();
    QJsonArray().swap(m_rawMetadataSample);
    QVector<PrimitiveEvent>().swap(m_primitiveEvents);
    QQueue<SegmentMeta>().swap(m_pendingSegments);
    QQueue<SegmentMeta>().swap(m_retrySegments);
    QStringList().swap(m_currentChunkSegments);
    m_rawMetadataCount = 0;
    m_primitiveEventsDirty = false;
}
