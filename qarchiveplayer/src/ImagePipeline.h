#pragma once

#include <QObject>
#include <QImage>
#include <algorithm>
#include <functional>
#include "Nv12Frame.h"

class ImagePipeline : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rgbR       READ rgbR       WRITE setRgbR       NOTIFY settingsChanged)
    Q_PROPERTY(int rgbG       READ rgbG       WRITE setRgbG       NOTIFY settingsChanged)
    Q_PROPERTY(int rgbB       READ rgbB       WRITE setRgbB       NOTIFY settingsChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY settingsChanged)
    Q_PROPERTY(int contrast   READ contrast   WRITE setContrast   NOTIFY settingsChanged)
    Q_PROPERTY(int saturation READ saturation WRITE setSaturation NOTIFY settingsChanged)
    Q_PROPERTY(QString cameraId READ cameraId WRITE setCameraId NOTIFY cameraIdChanged)

public:
    struct Settings {
        int r = 128;
        int g = 128;
        int b = 128;
        int brightness = 50;
        int contrast   = 50;
        int saturation = 50;
    };

    explicit ImagePipeline(QObject* parent = nullptr) : QObject(parent)
    {
        loadSettings();
    }

    QString cameraId() const { return m_cameraId; }
    void setCameraId(const QString& id);

    void setRgbR(int v);
    void setRgbG(int v);
    void setRgbB(int v);
    void setBrightness(int v);
    void setContrast(int v);
    void setSaturation(int v);

    int rgbR()       const { return m_s.r; }
    int rgbG()       const { return m_s.g; }
    int rgbB()       const { return m_s.b; }
    int brightness() const { return m_s.brightness; }
    int contrast()   const { return m_s.contrast; }
    int saturation() const { return m_s.saturation; }

    Settings snapshot() const { return m_s; }
    void setFromSnapshot(const Settings& s) { m_s = sanitize(s); emit settingsChanged(); }

    QImage toImage(const Nv12Frame& f) const;
    QImage toImage(const Nv12Frame& f, const Settings& s) const;

signals:
    void settingsChanged();
    void cameraIdChanged();

private:
    static int clamp255(int v) { return std::max(0, std::min(255, v)); }
    static int clamp100(int v) { return std::max(0, std::min(100, v)); }

    static Settings sanitize(const Settings& in) {
        Settings s = in;
        s.r = clamp255(s.r); s.g = clamp255(s.g); s.b = clamp255(s.b);
        s.brightness = clamp100(s.brightness);
        s.contrast   = clamp100(s.contrast);
        s.saturation = clamp100(s.saturation);
        return s;
    }

    static void applyColorControls(int& r, int& g, int& b, const Settings& s);

    static QImage nv12ToRgb888(const Nv12Frame& f, const std::function<void(int&,int&,int&)>& apply);
    static QString settingsPath();
    static QString settingsGroup();

    void loadSettings();
    void saveSettings() const;

    QString m_cameraId;
    static QString settingsGroupFor(const QString& cameraId);
    void loadSettings(const QString& cameraId);
    void saveSettings(const QString& cameraId) const;

private:
    Settings m_s;
};
