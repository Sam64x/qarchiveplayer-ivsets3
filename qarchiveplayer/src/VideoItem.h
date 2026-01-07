#pragma once

#include <QQuickFramebufferObject>
#include <QMutex>
#include <QDateTime>
#include <QPointer>
#include <QVariant>
#include "Nv12Frame.h"

class ImagePipeline;

class VideoItem : public QQuickFramebufferObject
{
    Q_OBJECT

    Q_PROPERTY(int rgbR       READ rgbR       WRITE setRgbR       NOTIFY colorControlsChanged)
    Q_PROPERTY(int rgbG       READ rgbG       WRITE setRgbG       NOTIFY colorControlsChanged)
    Q_PROPERTY(int rgbB       READ rgbB       WRITE setRgbB       NOTIFY colorControlsChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY colorControlsChanged)
    Q_PROPERTY(int contrast   READ contrast   WRITE setContrast   NOTIFY colorControlsChanged)
    Q_PROPERTY(int saturation READ saturation WRITE setSaturation NOTIFY colorControlsChanged)

    Q_PROPERTY(QObject* source   READ source   WRITE setSource   NOTIFY sourceChanged)
    Q_PROPERTY(QObject* pipeline READ pipeline WRITE setPipeline NOTIFY pipelineChanged)

    Q_PROPERTY(FillMode fillMode READ fillMode WRITE setFillMode NOTIFY fillModeChanged)
    Q_PROPERTY(int orientation READ orientation WRITE setOrientation NOTIFY orientationChanged)

public:
    enum FillMode { Fit = 0, Fill = 1 };
    Q_ENUM(FillMode)

    VideoItem();
    ~VideoItem() override;

    QQuickFramebufferObject::Renderer* createRenderer() const override;

    Q_INVOKABLE void presentNv12Frame(const Nv12Frame& frame, const QDateTime& ts = QDateTime());

    int rgbR() const       { return m_rgbR; }
    int rgbG() const       { return m_rgbG; }
    int rgbB() const       { return m_rgbB; }
    int brightness() const { return m_brightness; }
    int contrast() const   { return m_contrast; }
    int saturation() const { return m_saturation; }

    QObject* source()   const { return m_source; }
    QObject* pipeline() const { return m_pipeline; }

    FillMode fillMode() const { return m_fillMode; }
    int      orientation() const { return m_orientationDeg; }

signals:
    void colorControlsChanged();
    void sourceChanged();
    void pipelineChanged();
    void fillModeChanged();
    void orientationChanged();

public slots:
    void setRgbR(int v);
    void setRgbG(int v);
    void setRgbB(int v);
    void setBrightness(int v);
    void setContrast(int v);
    void setSaturation(int v);

    void setSource(QObject* src);
    void setPipeline(QObject* p);

    void setFillMode(FillMode m);
    void setOrientation(int degrees);

    void onFrameReadyNv12(const Nv12Frame& frame, const QDateTime& tsUtc);

private slots:
    void onPipelineSettingsChanged();

public:
    bool takePendingNv12(Nv12Frame& out);
    void getColorParams(float& rMul, float& gMul, float& bMul,
                        float& brightness, float& contrast, float& saturation) const;
    FillMode takeFillMode() const { return m_fillMode; }
    int      takeOrientation() const { return m_orientationDeg; }

private:
    void syncColorsFromSource(QObject* src);
    void syncColorsFromPipeline(QObject* p);

private:
    mutable QMutex m_mutex;
    Nv12Frame  m_pendingNv12;
    bool       m_hasPendingNv12 {false};
    QDateTime  m_pendingTs;
    QDateTime  m_lastTs;

    int m_rgbR = 128;
    int m_rgbG = 128;
    int m_rgbB = 128;
    int m_brightness = 50;
    int m_contrast = 50;
    int m_saturation = 50;

    FillMode m_fillMode { Fit };
    int      m_orientationDeg { 0 };

    QPointer<QObject> m_source;
    QPointer<QObject> m_pipeline;

    QMetaObject::Connection m_connNv12;
    QMetaObject::Connection m_connPipeline;
};
