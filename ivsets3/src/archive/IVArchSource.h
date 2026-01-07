#pragma once

#include "iv_common.h"
#include <QDebug>
#include <QObject>
#include <QObjectList>
#include <QVariantList>
#include <QString>
#include <QJsonArray>
#include <QJsonObject>
#include <QDateTime>
#include <QThread>
#include <QDateTime>

class IVArchSource : public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(int scale READ scale WRITE setScale NOTIFY scaleChanged)
    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QJsonArray events READ events WRITE setEvents NOTIFY eventsChanged)
    Q_PROPERTY(QJsonArray bookmarks READ bookmarks WRITE setBookmarks NOTIFY bookmarksChanged)
    Q_PROPERTY(QJsonArray fullness READ fullness WRITE setFullness NOTIFY fullnessChanged)
    Q_PROPERTY(QPair<QDateTime, QDateTime> interval READ interval WRITE setInterval NOTIFY intervalChanged)

    IVArchSource(QString newName, QObject* parent = 0);
    ~IVArchSource();

public slots:
    int scale();
    void setScale(int);

    QString name();
    void setName(QString);

    bool visible();
    void setVisible(bool);

    QJsonArray events();
    void setEvents(QJsonArray);

    QJsonArray bookmarks();
    void setBookmarks(QJsonArray);

    QJsonArray fullness();
    void setFullness(QJsonArray);

    QPair<QDateTime, QDateTime> interval();
    void setInterval(QPair<QDateTime, QDateTime>);
    void setInterval(QString, QString);

    void requestFullness();
    static void responseFullness(const void*, const param_t*);

signals:
    void scaleChanged();
    void nameChanged();
    void visibleChanged();
    void eventsChanged();
    void bookmarksChanged();
    void fullnessChanged();
    void intervalChanged();

private:
    int _scale;
    QPair<QDateTime, QDateTime> _interval;
    bool _visible;
    QString _name;
    QJsonArray _events;
    QJsonArray _bookmarks;
    QJsonArray _fullness;
};
