#pragma once

#include <QtQml>
#include <QObjectList>
#include <QVector>
#include <QJsonArray>
#include <QJsonObject>
#include <QDateTime>
#include <QThread>
#include <iv_stable.h>
//#include "iv_ewriter.h"
#include "IVArchSource.h"

class IVMainArea: public QObject
{
    Q_OBJECT
public:
    Q_PROPERTY(QStringList allSourcesList READ allSourcesList NOTIFY allSourcesListChanged)

    Q_PROPERTY(QList<QObject*> sources READ sourcesAsObj NOTIFY sourcesChanged)

    Q_PROPERTY(QJsonArray events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QJsonArray bookmarks READ bookmarks NOTIFY bookmarksChanged)

    Q_PROPERTY(QDateTime start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(QDateTime end READ end WRITE setEnd NOTIFY endChanged)

    QJsonObject _filter;
    QJsonArray eventsArr;
    void requestEvents();
    static void responseEvents(const void*, const param_t*);
    bool includeEventsMode;
    QStringList eventsGroup;
    Q_INVOKABLE void updateEventsGroup(bool, QStringList);

    void setIntervalToSources();
    void setEventsToSources(QJsonArray);

    void getCamsList();
    IVMainArea(QObject* parent = 0);
    ~IVMainArea();

public slots:
    const QList<QObject*> sourcesAsObj() const;
    Q_INVOKABLE void addSources(QStringList);
    Q_INVOKABLE void removeSources(QStringList);
    Q_INVOKABLE void moveSource(int, int);

    QStringList allSourcesList();

    QJsonArray events();
    QJsonArray bookmarks();

    QDateTime start();
    QDateTime end();
    Q_INVOKABLE void setInterval(QDateTime, QDateTime);
    void setStart(QDateTime);
    void setEnd(QDateTime);

signals:
    void sourcesChanged();
    void eventsChanged();
    void bookmarksChanged();
    void startChanged();
    void endChanged();
    void allSourcesListChanged();

private:
    QStringList _allSourcesList;
    QList<IVArchSource*> _sources;

    QJsonArray _events;
    QJsonArray _bookmarks;

    QDateTime _start;
    QDateTime _end;
};
