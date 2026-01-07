#include <QSettings>
#include <QStandardPaths>
#include "ImagePipeline.h"
#include <type_traits>
#include <cmath>
#include <algorithm>

template <class T, class = void> struct has_yStride   : std::false_type {};
template <class T> struct has_yStride<T, std::void_t<decltype(std::declval<const T&>().yStride())>> : std::true_type {};

template <class T, class = void> struct has_uvStride  : std::false_type {};
template <class T> struct has_uvStride<T, std::void_t<decltype(std::declval<const T&>().uvStride())>> : std::true_type {};

template <class T, class = void> struct has_strideY   : std::false_type {};
template <class T> struct has_strideY<T, std::void_t<decltype(std::declval<const T&>().strideY())>> : std::true_type {};

template <class T, class = void> struct has_strideUV  : std::false_type {};
template <class T> struct has_strideUV<T, std::void_t<decltype(std::declval<const T&>().strideUV())>> : std::true_type {};

template <class T>
static inline int getYStride(const T& f) {
    if constexpr (has_yStride<T>::value)         return f.yStride();
    else if constexpr (has_strideY<T>::value)    return f.strideY();
    else                                         return f.width();
}
template <class T>
static inline int getUVStride(const T& f) {
    if constexpr (has_uvStride<T>::value)        return f.uvStride();
    else if constexpr (has_strideUV<T>::value)   return f.strideUV();
    else                                         return f.width();
}

template <class PlaneT>
static inline const uchar* planePtr(const PlaneT& p) {
    if constexpr (std::is_same_v<std::decay_t<PlaneT>, QByteArray>) {
        return reinterpret_cast<const uchar*>(p.constData());
    } else {
        return reinterpret_cast<const uchar*>(p);
    }
}

template <class Apply>
static QImage nv12ToRgb888_Templ(const Nv12Frame& f, Apply&& apply)
{
    const int W = f.width();
    const int H = f.height();
    if (W <= 0 || H <= 0) return QImage();

    const int yStride  = getYStride(f);
    const int uvStride = getUVStride(f);

    const uchar* Yp  = planePtr(f.yPlane());
    const uchar* UVp = planePtr(f.uvPlane());

    QImage out(W, H, QImage::Format_RGB888);
    if (out.isNull()) return out;

    for (int y = 0; y < H; ++y) {
        uchar* dst = out.scanLine(y);
        const uchar* yRow  = Yp  + y * yStride;
        const uchar* uvRow = UVp + (y >> 1) * uvStride;

        int x = 0;
        for (; x + 1 < W; x += 2) {
            const int Y0 = int(yRow[x+0]);
            const int Y1 = int(yRow[x+1]);

            const int uIdx = (x >> 1) * 2;
            const int U = int(uvRow[uIdx+0]) - 128;
            const int V = int(uvRow[uIdx+1]) - 128;

            auto yuv2rgb = [](int Y, int Uc, int Vc, int& r, int& g, int& b) {
                const int C = Y - 16;
                const int D = Uc;
                const int E = Vc;
                int Rt = (298*C + 409*E + 128) >> 8;
                int Gt = (298*C - 100*D - 208*E + 128) >> 8;
                int Bt = (298*C + 516*D + 128) >> 8;
                r = std::max(0, std::min(255, Rt));
                g = std::max(0, std::min(255, Gt));
                b = std::max(0, std::min(255, Bt));
            };

            int r,g,b;

            yuv2rgb(Y0, U, V, r,g,b);
            apply(r,g,b);
            uchar* d0 = dst + 3*x;
            d0[0] = uchar(r); d0[1] = uchar(g); d0[2] = uchar(b);

            yuv2rgb(Y1, U, V, r,g,b);
            apply(r,g,b);
            uchar* d1 = d0 + 3;
            d1[0] = uchar(r); d1[1] = uchar(g); d1[2] = uchar(b);
        }
        if (x < W) {
            const int Y0 = int(yRow[x]);
            const int uIdx = (x >> 1) * 2;
            const int U = int(uvRow[uIdx+0]) - 128;
            const int V = int(uvRow[uIdx+1]) - 128;

            int r,g,b;
            const int C = Y0 - 16;
            const int D = U;
            const int E = V;
            int Rt = (298*C + 409*E + 128) >> 8;
            int Gt = (298*C - 100*D - 208*E + 128) >> 8;
            int Bt = (298*C + 516*D + 128) >> 8;
            r = std::max(0, std::min(255, Rt));
            g = std::max(0, std::min(255, Gt));
            b = std::max(0, std::min(255, Bt));
            apply(r,g,b);
            uchar* d0 = dst + 3*x;
            d0[0] = uchar(r); d0[1] = uchar(g); d0[2] = uchar(b);
        }
    }
    return out;
}

QString ImagePipeline::settingsPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
    + "/image_pipeline.ini";
}

QString ImagePipeline::settingsGroupFor(const QString& cameraId)
{
    if (cameraId.isEmpty())
        return QStringLiteral("ImagePipeline/__global__");
    return QStringLiteral("ImagePipeline/%1").arg(cameraId);
}

void ImagePipeline::loadSettings(const QString& cameraId)
{
    QSettings s(settingsPath(), QSettings::IniFormat);
    s.beginGroup(settingsGroupFor(cameraId));
    ImagePipeline::Settings st;
    st.r          = s.value("r",          128).toInt();
    st.g          = s.value("g",          128).toInt();
    st.b          = s.value("b",          128).toInt();
    st.brightness = s.value("brightness",  50).toInt();
    st.contrast   = s.value("contrast",    50).toInt();
    st.saturation = s.value("saturation",  50).toInt();
    s.endGroup();
    m_s = sanitize(st);
}

void ImagePipeline::saveSettings(const QString& cameraId) const
{
    QSettings s(settingsPath(), QSettings::IniFormat);
    s.beginGroup(settingsGroupFor(cameraId));
    s.setValue("r",          m_s.r);
    s.setValue("g",          m_s.g);
    s.setValue("b",          m_s.b);
    s.setValue("brightness", m_s.brightness);
    s.setValue("contrast",   m_s.contrast);
    s.setValue("saturation", m_s.saturation);
    s.endGroup();
    s.sync();
}

void ImagePipeline::loadSettings() { loadSettings(m_cameraId); }
void ImagePipeline::saveSettings() const { saveSettings(m_cameraId); }

QImage ImagePipeline::nv12ToRgb888(
    const Nv12Frame& f,
    const std::function<void(int&,int&,int&)>& apply)
{
    return nv12ToRgb888_Templ(f, [&](int& r,int& g,int& b){ apply(const_cast<int&>(r),const_cast<int&>(g),const_cast<int&>(b)); });
}

void ImagePipeline::applyColorControls(int& r, int& g, int& b, const Settings& s)
{
    const double gainR = s.r / 128.0;
    const double gainG = s.g / 128.0;
    const double gainB = s.b / 128.0;

    double R = std::max(0.0, std::min(255.0, r * gainR));
    double G = std::max(0.0, std::min(255.0, g * gainG));
    double B = std::max(0.0, std::min(255.0, b * gainB));

    const double br = (s.brightness - 50) / 50.0;
    const double ct = (s.contrast   / 50.0);
    const double st = (s.saturation / 50.0);

    const double Y = 0.299*R + 0.587*G + 0.114*B;
    double U = -0.147*R - 0.289*G + 0.436*B;
    double V =  0.615*R - 0.515*G - 0.100*B;

    U *= st;
    V *= st;

    double Rt = Y + 1.140*V;
    double Gt = Y - 0.395*U - 0.581*V;
    double Bt = Y + 2.032*U;

    Rt = (Rt - 128.0)*ct + 128.0 + 255.0*br;
    Gt = (Gt - 128.0)*ct + 128.0 + 255.0*br;
    Bt = (Bt - 128.0)*ct + 128.0 + 255.0*br;

    r = std::max(0, std::min(255, int(std::lround(Rt))));
    g = std::max(0, std::min(255, int(std::lround(Gt))));
    b = std::max(0, std::min(255, int(std::lround(Bt))));
}

QImage ImagePipeline::toImage(const Nv12Frame& f) const
{
    const Settings s = m_s;
    return nv12ToRgb888_Templ(f, [&](int& r,int& g,int& b){ applyColorControls(r,g,b,s); });
}

QImage ImagePipeline::toImage(const Nv12Frame& f, const Settings& s) const
{
    const Settings ss = sanitize(s);
    return nv12ToRgb888_Templ(f, [&](int& r,int& g,int& b){ applyColorControls(r,g,b,ss); });
}

void ImagePipeline::setCameraId(const QString& id)
{
    if (m_cameraId == id)
        return;
    m_cameraId = id;
    loadSettings(m_cameraId);
    emit settingsChanged();
    emit cameraIdChanged();
}

void ImagePipeline::setRgbR(int v)       { int nv = clamp255(v); if (m_s.r != nv) { m_s.r = nv; saveSettings(m_cameraId); emit settingsChanged(); } }
void ImagePipeline::setRgbG(int v)       { int nv = clamp255(v); if (m_s.g != nv) { m_s.g = nv; saveSettings(m_cameraId); emit settingsChanged(); } }
void ImagePipeline::setRgbB(int v)       { int nv = clamp255(v); if (m_s.b != nv) { m_s.b = nv; saveSettings(m_cameraId); emit settingsChanged(); } }
void ImagePipeline::setBrightness(int v) { int nv = clamp100(v); if (m_s.brightness != nv) { m_s.brightness = nv; saveSettings(m_cameraId); emit settingsChanged(); } }
void ImagePipeline::setContrast(int v)   { int nv = clamp100(v); if (m_s.contrast   != nv) { m_s.contrast   = nv; saveSettings(m_cameraId); emit settingsChanged(); } }
void ImagePipeline::setSaturation(int v) { int nv = clamp100(v); if (m_s.saturation != nv) { m_s.saturation = nv; saveSettings(m_cameraId); emit settingsChanged(); } }
