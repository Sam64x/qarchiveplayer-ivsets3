#include "VideoItem.h"

#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLFramebufferObject>
#include <QOpenGLShaderProgram>
#include <QMutexLocker>
#include <QDateTime>
#include <QDebug>
#include <cstring>

#ifndef GL_RG8
#define GL_RG8 0x822B
#endif
#ifndef GL_RG
#define GL_RG 0x8227
#endif
#ifndef GL_R8
#define GL_R8 0x8229
#endif
#ifndef GL_RED
#define GL_RED 0x1903
#endif
#ifndef GL_LUMINANCE
#define GL_LUMINANCE 0x1909
#endif
#ifndef GL_LUMINANCE_ALPHA
#define GL_LUMINANCE_ALPHA 0x190A
#endif
#ifndef GL_PIXEL_UNPACK_BUFFER
#define GL_PIXEL_UNPACK_BUFFER 0x88EC
#endif
#ifndef GL_STREAM_DRAW
#define GL_STREAM_DRAW 0x88E0
#endif


class VideoItemRenderer : public QQuickFramebufferObject::Renderer
{
public:
    VideoItemRenderer() { initGeometry(); }
    ~VideoItemRenderer() override
    {
        QOpenGLFunctions* f = QOpenGLContext::currentContext()
        ? QOpenGLContext::currentContext()->functions()
        : nullptr;
        if (f) {
            if (m_texY)  f->glDeleteTextures(1, &m_texY);
            if (m_texUV) f->glDeleteTextures(1, &m_texUV);
            if (m_pboY[0] || m_pboY[1])  f->glDeleteBuffers(2, m_pboY);
            if (m_pboUV[0] || m_pboUV[1]) f->glDeleteBuffers(2, m_pboUV);
        }
        delete m_progPacked;
        m_progPacked = nullptr;
    }

    QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override
    {
        QOpenGLFramebufferObjectFormat fmt;
        fmt.setAttachment(QOpenGLFramebufferObject::NoAttachment);
        fmt.setTextureTarget(GL_TEXTURE_2D);
        fmt.setSamples(0);
        return new QOpenGLFramebufferObject(size, fmt);
    }

    void synchronize(QQuickFramebufferObject* item) override
    {
        auto* vi = static_cast<VideoItem*>(item);

        Nv12Frame f;
        if (vi->takePendingNv12(f)) {
            m_nextNv12    = f;
            m_haveNewNv12 = f.isValid();
            if (f.isValid()) {
                m_videoSize = QSize(f.width(), f.height());
            }
        }

        vi->getColorParams(m_rMul, m_gMul, m_bMul, m_brightness, m_contrast, m_saturation);

        m_fillMode = vi->takeFillMode();
        m_orientationDeg = vi->takeOrientation();

        if (!m_progPacked)
            initProgram();
    }

    void render() override
    {
        QOpenGLFunctions* f = QOpenGLContext::currentContext()->functions();

        if (!m_unpackSet) {
            f->glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            m_unpackSet = true;
        }

        const QSize fbSize = framebufferObject()->size();
        f->glViewport(0, 0, fbSize.width(), fbSize.height());

        if (m_lastFbSize != fbSize ||
            m_lastVideoSize != effectiveVideoSize() ||
            m_lastFillMode != m_fillMode ||
            m_lastOrientationDeg != m_orientationDeg)
        {
            updateGeometry(fbSize);
            m_lastFbSize         = fbSize;
            m_lastVideoSize      = effectiveVideoSize();
            m_lastFillMode       = m_fillMode;
            m_lastOrientationDeg = m_orientationDeg;
        }

        if (m_haveNewNv12) {
            uploadNV12(f, m_nextNv12);
            m_nextNv12 = Nv12Frame();
            m_haveNewNv12 = false;
        }

        if (m_progPacked && m_texY && m_texUV) {
            drawPacked(f);
        } else {
            f->glClearColor(0.f, 0.f, 0.f, 1.f);
            f->glClear(GL_COLOR_BUFFER_BIT);
        }

        f->glActiveTexture(GL_TEXTURE0);
        f->glBindTexture(GL_TEXTURE_2D, 0);
        if (m_usePbo) f->glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
    }

private:
    void detectFormatsAndPbo()
    {
        QOpenGLContext* ctx = QOpenGLContext::currentContext();
        const bool isES = ctx && ctx->isOpenGLES();
        int maj = 0, min = 0;
        if (ctx) { maj = ctx->format().majorVersion(); min = ctx->format().minorVersion(); }

        m_useRG  = (!isES) || (isES && maj >= 3);
        m_useRed = (!isES) || (isES && maj >= 3);

        m_usePbo = (!isES && maj >= 2) || (isES && maj >= 3);
    }

    void initProgram()
    {
        detectFormatsAndPbo();

        QOpenGLContext* ctx = QOpenGLContext::currentContext();
        const bool isES = ctx && ctx->isOpenGLES();

        QByteArray vs;
        if (isES) {
            vs += "#version 100\n";
        } else {
            vs += "#version 120\n";
        }
        vs += "attribute vec2 aPos;\n";
        vs += "attribute vec2 aTex;\n";
        vs += "varying vec2 vTex;\n";
        vs += "void main(){ vTex=aTex; gl_Position=vec4(aPos,0.0,1.0); }\n";

        QByteArray fs;
        if (isES) {
            fs += "#version 100\n";
            fs += "precision mediump float;\n";
        } else {
            fs += "#version 120\n";
        }
        fs += "uniform sampler2D uTexY;\n";
        fs += "uniform sampler2D uTexUV;\n";
        fs += "uniform float u_rMul,u_gMul,u_bMul;\n";
        fs += "uniform float u_brightness,u_contrast,u_saturation;\n";
        fs += "varying vec2 vTex;\n";
        fs += "void main(){\n";
        fs += "  float y = texture2D(uTexY, vTex).r;\n";
        if (m_useRG) {
            fs += "  vec2 uv = texture2D(uTexUV, vTex).rg - vec2(0.5, 0.5);\n";
        } else {
            fs += "  vec4 uvTex = texture2D(uTexUV, vTex);\n";
            fs += "  vec2 uv = vec2(uvTex.r - 0.5, uvTex.a - 0.5);\n";
        }
        fs += "  float u = uv.x;\n";
        fs += "  float v = uv.y;\n";
        fs += "  float r = y + 1.402 * v;\n";
        fs += "  float g = y - 0.344136 * u - 0.714136 * v;\n";
        fs += "  float b = y + 1.772 * u;\n";
        fs += "  vec3 rgb = vec3(r,g,b) * vec3(u_rMul, u_gMul, u_bMul);\n";
        fs += "  float lum = dot(rgb, vec3(0.299,0.587,0.114));\n";
        fs += "  rgb = mix(vec3(lum), rgb, u_saturation);\n";
        fs += "  rgb = (rgb - 0.5) * u_contrast + 0.5;\n";
        fs += "  rgb += vec3(u_brightness);\n";
        fs += "  rgb = clamp(rgb, 0.0, 1.0);\n";
        fs += "  gl_FragColor = vec4(rgb, 1.0);\n";
        fs += "}\n";

        m_progPacked = new QOpenGLShaderProgram();
        if (!m_progPacked->addShaderFromSourceCode(QOpenGLShader::Vertex,   vs))
            qWarning() << "VideoItem VS error:" << m_progPacked->log();
        if (!m_progPacked->addShaderFromSourceCode(QOpenGLShader::Fragment, fs))
            qWarning() << "VideoItem FS error:" << m_progPacked->log();
        if (!m_progPacked->link())
            qWarning() << "VideoItem link error:" << m_progPacked->log();

        m_locPos = m_progPacked->attributeLocation("aPos");
        m_locTc  = m_progPacked->attributeLocation("aTex");
        m_locY   = m_progPacked->uniformLocation("uTexY");
        m_locUV  = m_progPacked->uniformLocation("uTexUV");
        m_loc_rMul = m_progPacked->uniformLocation("u_rMul");
        m_loc_gMul = m_progPacked->uniformLocation("u_gMul");
        m_loc_bMul = m_progPacked->uniformLocation("u_bMul");
        m_loc_brightness = m_progPacked->uniformLocation("u_brightness");
        m_loc_contrast   = m_progPacked->uniformLocation("u_contrast");
        m_loc_saturation = m_progPacked->uniformLocation("u_saturation");
    }

    void initGeometry()
    {
        setVerticesRect(-1.f, -1.f, 1.f, 1.f);
        setTexcoordsForRotation(0);
    }

    void setVerticesRect(float x0, float y0, float x1, float y1)
    {
        m_vertices[0]=x0; m_vertices[1]=y0;
        m_vertices[2]=x1; m_vertices[3]=y0;
        m_vertices[4]=x0; m_vertices[5]=y1;
        m_vertices[6]=x1; m_vertices[7]=y1;
    }

    void setTexcoords(float s0,float t0,float s1,float t1,float s2,float t2,float s3,float t3)
    {
        m_texcoords[0]=s0; m_texcoords[1]=t0;
        m_texcoords[2]=s1; m_texcoords[3]=t1;
        m_texcoords[4]=s2; m_texcoords[5]=t2;
        m_texcoords[6]=s3; m_texcoords[7]=t3;
    }

    void setTexcoordsForRotation(int deg)
    {
        switch ((deg % 360 + 360) % 360) {
        default:
        case 0:
            setTexcoords(0.f,1.f, 1.f,1.f, 0.f,0.f, 1.f,0.f);
            break;
        case 90:
            setTexcoords(0.f,0.f, 0.f,1.f, 1.f,0.f, 1.f,1.f);
            break;
        case 180:
            setTexcoords(1.f,0.f, 0.f,0.f, 1.f,1.f, 0.f,1.f);
            break;
        case 270:
            setTexcoords(1.f,1.f, 1.f,0.f, 0.f,1.f, 0.f,0.f);
            break;
        }
    }

    QSize effectiveVideoSize() const
    {
        if ((m_orientationDeg % 180) != 0)
            return QSize(m_videoSize.height(), m_videoSize.width());
        return m_videoSize;
    }

    void updateGeometry(const QSize& fbSize)
    {
        const QSize vsz = effectiveVideoSize();
        if (vsz.isEmpty() || fbSize.isEmpty()) {
            setVerticesRect(-1.f, -1.f, 1.f, 1.f);
        } else {
            const float vw = float(vsz.width());
            const float vh = float(vsz.height());
            const float rw = float(fbSize.width());
            const float rh = float(fbSize.height());

            const float videoAspect = vw / vh;
            const float fbAspect    = rw / rh;

            float sx = 1.f, sy = 1.f;
            if (m_fillMode == VideoItem::Fit) {
                if (fbAspect > videoAspect) {
                    sx = videoAspect / fbAspect;
                    sy = 1.f;
                } else {
                    sx = 1.f;
                    sy = fbAspect / videoAspect;
                }
            } else {
                if (fbAspect > videoAspect) {
                    sx = 1.f;
                    sy = fbAspect / videoAspect;
                } else {
                    sx = videoAspect / fbAspect;
                    sy = 1.f;
                }
            }
            setVerticesRect(-sx, -sy, +sx, +sy);
        }

        setTexcoordsForRotation(m_orientationDeg);
    }

    void ensureTex(QOpenGLFunctions* f, GLuint &tex)
    {
        if (!tex) {
            f->glGenTextures(1, &tex);
            f->glBindTexture(GL_TEXTURE_2D, tex);
            f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            f->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
    }

    void ensurePbo(QOpenGLFunctions* f, GLuint (&ids)[2])
    {
        if (!m_usePbo) return;
        if (ids[0] == 0 && ids[1] == 0) {
            f->glGenBuffers(2, ids);
        }
    }

    void uploadNV12(QOpenGLFunctions* f, const Nv12Frame &fr)
    {
        const int w  = fr.width();
        const int h  = fr.height();
        if (w <= 0 || h <= 0) return;

        const int w2 = (w + 1) / 2;
        const int h2 = (h + 1) / 2;

        ensureTex(f, m_texY);
        f->glActiveTexture(GL_TEXTURE0);
        f->glBindTexture(GL_TEXTURE_2D, m_texY);

        const int sizeY = w * h;

        if (m_usePbo) {
            ensurePbo(f, m_pboY);
            m_pboIndexY = (m_pboIndexY + 1) & 1;
            const GLuint pbo = m_pboY[m_pboIndexY];
            f->glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
            f->glBufferData(GL_PIXEL_UNPACK_BUFFER, sizeY, fr.yPlane().constData(), GL_STREAM_DRAW);

            if (m_texYSize != QSize(w, h)) {
                m_texYSize = QSize(w, h);
                if (m_useRed) {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, w, h, 0, GL_RED, GL_UNSIGNED_BYTE, nullptr);
                } else {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, nullptr);
                }
            } else {
                if (m_useRed) {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_RED, GL_UNSIGNED_BYTE, nullptr);
                } else {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_LUMINANCE, GL_UNSIGNED_BYTE, nullptr);
                }
            }
            f->glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
        } else {
            if (m_texYSize != QSize(w, h)) {
                m_texYSize = QSize(w, h);
                if (m_useRed) {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, w, h, 0, GL_RED, GL_UNSIGNED_BYTE, fr.yPlane().constData());
                } else {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, fr.yPlane().constData());
                }
            } else {
                if (m_useRed) {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_RED, GL_UNSIGNED_BYTE, fr.yPlane().constData());
                } else {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_LUMINANCE, GL_UNSIGNED_BYTE, fr.yPlane().constData());
                }
            }
        }

        ensureTex(f, m_texUV);
        f->glActiveTexture(GL_TEXTURE1);
        f->glBindTexture(GL_TEXTURE_2D, m_texUV);

        const int sizeUV = w2 * h2 * 2;

        if (m_usePbo) {
            ensurePbo(f, m_pboUV);
            m_pboIndexUV = (m_pboIndexUV + 1) & 1;
            const GLuint pbo = m_pboUV[m_pboIndexUV];
            f->glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
            f->glBufferData(GL_PIXEL_UNPACK_BUFFER, sizeUV, fr.uvPlane().constData(), GL_STREAM_DRAW);

            if (m_texUVSize != QSize(w2, h2)) {
                m_texUVSize = QSize(w2, h2);
                if (m_useRG) {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_RG8, w2, h2, 0, GL_RG, GL_UNSIGNED_BYTE, nullptr);
                } else {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, w2, h2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, nullptr);
                }
            } else {
                if (m_useRG) {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w2, h2, GL_RG, GL_UNSIGNED_BYTE, nullptr);
                } else {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w2, h2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, nullptr);
                }
            }
            f->glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
        } else {
            const void* uv = fr.uvPlane().constData();
            if (m_texUVSize != QSize(w2, h2)) {
                m_texUVSize = QSize(w2, h2);
                if (m_useRG) {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_RG8, w2, h2, 0, GL_RG, GL_UNSIGNED_BYTE, uv);
                } else {
                    f->glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, w2, h2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uv);
                }
            } else {
                if (m_useRG) {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w2, h2, GL_RG, GL_UNSIGNED_BYTE, uv);
                } else {
                    f->glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w2, h2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uv);
                }
            }
        }
    }

    void drawPacked(QOpenGLFunctions* f)
    {
        m_progPacked->bind();

        m_progPacked->enableAttributeArray(m_locPos);
        m_progPacked->enableAttributeArray(m_locTc);
        m_progPacked->setAttributeArray(m_locPos, GL_FLOAT, m_vertices, 2);
        m_progPacked->setAttributeArray(m_locTc,  GL_FLOAT, m_texcoords, 2);

        f->glActiveTexture(GL_TEXTURE0);
        f->glBindTexture(GL_TEXTURE_2D, m_texY);
        m_progPacked->setUniformValue(m_locY, 0);

        f->glActiveTexture(GL_TEXTURE1);
        f->glBindTexture(GL_TEXTURE_2D, m_texUV);
        m_progPacked->setUniformValue(m_locUV, 1);

        m_progPacked->setUniformValue(m_loc_rMul, m_rMul);
        m_progPacked->setUniformValue(m_loc_gMul, m_gMul);
        m_progPacked->setUniformValue(m_loc_bMul, m_bMul);
        m_progPacked->setUniformValue(m_loc_brightness, m_brightness);
        m_progPacked->setUniformValue(m_loc_contrast,   m_contrast);
        m_progPacked->setUniformValue(m_loc_saturation, m_saturation);

        f->glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        m_progPacked->disableAttributeArray(m_locPos);
        m_progPacked->disableAttributeArray(m_locTc);
        m_progPacked->release();
    }

private:
    QOpenGLShaderProgram* m_progPacked {nullptr};

    int m_locPos {-1}, m_locTc {-1};
    int m_locY {-1}, m_locUV {-1};
    int m_loc_rMul {-1}, m_loc_gMul {-1}, m_loc_bMul {-1};
    int m_loc_brightness {-1}, m_loc_contrast {-1}, m_loc_saturation {-1};

    GLuint m_texY  {0};
    GLuint m_texUV {0};
    QSize  m_texYSize;
    QSize  m_texUVSize;

    bool   m_usePbo {false};
    GLuint m_pboY[2]  {0,0};
    GLuint m_pboUV[2] {0,0};
    int    m_pboIndexY  {-1};
    int    m_pboIndexUV {-1};

    bool   m_unpackSet {false};

    Nv12Frame m_nextNv12;
    bool      m_haveNewNv12 {false};

    QSize    m_videoSize;
    QSize    m_lastVideoSize;
    QSize    m_lastFbSize;
    float    m_vertices[8]  { -1,-1, 1,-1, -1,1, 1,1 };
    float    m_texcoords[8] {  0,1,  1,1,  0,0, 1,0 };
    int      m_orientationDeg {0};
    int      m_lastOrientationDeg { -1 };
    VideoItem::FillMode m_fillMode { VideoItem::Fit };
    VideoItem::FillMode m_lastFillMode { VideoItem::Fit };

    float m_rMul {1.0f};
    float m_gMul {1.0f};
    float m_bMul {1.0f};
    float m_brightness {0.0f};
    float m_contrast   {1.0f};
    float m_saturation {1.0f};

    bool m_useRG  {false};
    bool m_useRed {false};
};


VideoItem::VideoItem()
{
    Nv12Frame::registerMetaType();
}

VideoItem::~VideoItem() = default;

QQuickFramebufferObject::Renderer* VideoItem::createRenderer() const
{
    return new VideoItemRenderer();
}

void VideoItem::presentNv12Frame(const Nv12Frame& frame, const QDateTime& ts)
{
    onFrameReadyNv12(frame, ts);
}

void VideoItem::onFrameReadyNv12(const Nv12Frame& frame, const QDateTime& ts)
{
    {
        QMutexLocker l(&m_mutex);
        m_pendingNv12    = frame;
        m_hasPendingNv12 = frame.isValid();
        m_pendingTs      = ts;
    }
    update();
}


void VideoItem::setRgbR(int v)       { v = qBound(0, v, 255); if (m_rgbR != v)       { m_rgbR = v;       emit colorControlsChanged(); update(); } }
void VideoItem::setRgbG(int v)       { v = qBound(0, v, 255); if (m_rgbG != v)       { m_rgbG = v;       emit colorControlsChanged(); update(); } }
void VideoItem::setRgbB(int v)       { v = qBound(0, v, 255); if (m_rgbB != v)       { m_rgbB = v;       emit colorControlsChanged(); update(); } }
void VideoItem::setBrightness(int v) { v = qBound(0, v, 100); if (m_brightness != v) { m_brightness = v; emit colorControlsChanged(); update(); } }
void VideoItem::setContrast(int v)   { v = qBound(0, v, 100); if (m_contrast   != v) { m_contrast   = v; emit colorControlsChanged(); update(); } }
void VideoItem::setSaturation(int v) { v = qBound(0, v, 100); if (m_saturation != v) { m_saturation = v; emit colorControlsChanged(); update(); } }

void VideoItem::setSource(QObject* src)
{
    if (m_source == src) return;

    if (m_source && m_connNv12) QObject::disconnect(m_connNv12);

    m_source = src;
    m_connNv12 = QMetaObject::Connection();

    if (m_source) {
        m_connNv12 = QObject::connect(
            m_source, SIGNAL(frameReadyNv12(Nv12Frame,QDateTime)),
            this,     SLOT(onFrameReadyNv12(Nv12Frame,QDateTime)),
            Qt::QueuedConnection);

        syncColorsFromSource(m_source);
    }

    emit sourceChanged();
    update();
}

void VideoItem::setPipeline(QObject* p)
{
    if (m_pipeline == p) return;

    if (m_pipeline && m_connPipeline) QObject::disconnect(m_connPipeline);

    m_pipeline = p;
    m_connPipeline = QMetaObject::Connection();

    if (m_pipeline) {
        m_connPipeline = QObject::connect(
            m_pipeline, SIGNAL(settingsChanged()),
            this,       SLOT(onPipelineSettingsChanged()),
            Qt::QueuedConnection);

        syncColorsFromPipeline(m_pipeline);
    }

    emit pipelineChanged();
    update();
}

void VideoItem::setFillMode(VideoItem::FillMode m)
{
    if (m_fillMode == m) return;
    m_fillMode = m;
    emit fillModeChanged();
    update();
}

void VideoItem::setOrientation(int degrees)
{
    int d = degrees % 360; if (d < 0) d += 360;
    if (d==0 || d==90 || d==180 || d==270) {
        if (m_orientationDeg != d) {
            m_orientationDeg = d;
            emit orientationChanged();
            update();
        }
    } else {
        int r = ( (d + 45) / 90 ) * 90;
        if (r == 360) r = 0;
        if (m_orientationDeg != r) {
            m_orientationDeg = r;
            emit orientationChanged();
            update();
        }
    }
}

void VideoItem::onPipelineSettingsChanged()
{
    syncColorsFromPipeline(m_pipeline);
    update();
}

bool VideoItem::takePendingNv12(Nv12Frame& out)
{
    QMutexLocker l(&m_mutex);
    if (!m_hasPendingNv12) return false;
    out = m_pendingNv12;
    m_hasPendingNv12 = false;
    m_lastTs = m_pendingTs;
    return true;
}

static inline float _gain(int v)       { return float(v) / 128.0f; }
static inline float _brightness(int v) { return (float(v) - 50.0f) / 50.0f; }
static inline float _scale01(int v)    { return float(v) / 50.0f; }

void VideoItem::getColorParams(float& rMul, float& gMul, float& bMul,
                               float& brightness, float& contrast, float& saturation) const
{
    QMutexLocker l(&m_mutex);
    rMul       = _gain(m_rgbR);
    gMul       = _gain(m_rgbG);
    bMul       = _gain(m_rgbB);
    brightness = _brightness(m_brightness);
    contrast   = _scale01(m_contrast);
    saturation = _scale01(m_saturation);
}


void VideoItem::syncColorsFromSource(QObject* src)
{
    if (!src) return;
    QVariant v;
    v = src->property("rgbR");       if (v.isValid()) setRgbR(v.toInt());
    v = src->property("rgbG");       if (v.isValid()) setRgbG(v.toInt());
    v = src->property("rgbB");       if (v.isValid()) setRgbB(v.toInt());
    v = src->property("brightness"); if (v.isValid()) setBrightness(v.toInt());
    v = src->property("contrast");   if (v.isValid()) setContrast(v.toInt());
    v = src->property("saturation"); if (v.isValid()) setSaturation(v.toInt());
}

void VideoItem::syncColorsFromPipeline(QObject* p)
{
    if (!p) return;
    QVariant v;
    v = p->property("rgbR");       if (v.isValid()) setRgbR(v.toInt());
    v = p->property("rgbG");       if (v.isValid()) setRgbG(v.toInt());
    v = p->property("rgbB");       if (v.isValid()) setRgbB(v.toInt());
    v = p->property("brightness"); if (v.isValid()) setBrightness(v.toInt());
    v = p->property("contrast");   if (v.isValid()) setContrast(v.toInt());
    v = p->property("saturation"); if (v.isValid()) setSaturation(v.toInt());
}
