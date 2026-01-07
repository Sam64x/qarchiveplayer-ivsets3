#ifndef QPREVIEWER_H
#define QPREVIEWER_H

#include <QQmlApplicationEngine>
#include <QDebug>
#include <QDateTime>
#include <QThreadPool>
#include <QImage>

#include "iv_autoloader.h"
#include <iv_log3.h>
#include <iv_core.h>
#include <iv_stable.h>
#include <QQuickImageProvider>

#define QARC_FUNC(id) St2_FUNCT_St2(id + __COUNTER__)
#define QARC_METKA(id) St2(id + __COUNTER__)
#define QARC_MODULE_QARCHIVEPLAYER    7500

class ColorImageProvider : public QQuickImageProvider
{
public:
    ColorImageProvider(): QQuickImageProvider(QQuickImageProvider::Image) {
        LOGD_TRACE("====================== ColorImageProvider");
    }

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        QImage image;// (rsrcid);
        LOGD_TRACE("====================== requestImage");
        LOGD_TRACE("====================== id=%s", id.toStdString().c_str());
          //QMap<QString, QByteArray>::iterator i = cache.find(id);
          //if (i != cache.end() && i.key() == id)
          //{
            //QString& img = i.value();
            //QByteArray ba = QByteArray::fromBase64(img.toUtf8());
        std::string format = "jpeg";
        //image.loadFromData((const uchar*)data.data, data.size, format.c_str());
            image.loadFromData(QByteArray::fromBase64(id.toUtf8()));
          //}
          QImage result;

          LOGD_TRACE("====================== requestedSize.isValid()=%d", requestedSize.isValid());

          if (requestedSize.isValid()) {
            result = image.scaled(requestedSize, Qt::KeepAspectRatio);
          }
          else {
            result = image;
          }
          *size = result.size();
          LOGD_TRACE("====================== *size=%d", *size);
          return result;
    }

    /*std::string ColorImageProvider::get(const QString& id)
    {
      //const QByteArray &img = cache[id];
      qDebug() << "============ GET _img.length = " << _img.length();
      if (_img.isEmpty())
        return "";
      return _img.toBase64().toStdString();
    }

    void ColorImageProvider::set(const QString& id, const std::string& img)
    {
      _img = QByteArray::fromBase64(QByteArray(img.c_str()));
      qDebug() << "============ set _img.length = " << _img.length();
      //cache[id] = ba;
    }

    void ColorImageProvider::set(const QString& id, const char* img, size_t size)
    {
      //_img = QByteArray::fromBase64(QByteArray(img, (int)size));
      _img = QByteArray(img, (int)size);
      qDebug() << "============ set _img.length = " << _img.length();
      //cache[id] = ba;
    }*/
private:
    QByteArray _img;
};

//extern ColorImageProvider* g_images;

#endif // QPREVIEWER_H_H
