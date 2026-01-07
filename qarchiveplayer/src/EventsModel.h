#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QVector>
#include <QFutureWatcher>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QHash>
#include <QtConcurrent/QtConcurrentRun>

struct EventItem {
    QDateTime s;
    QDateTime f;
    int v;
    QString color;
    QString comment;
    int type;
    bool visible;
};

struct EventIndex {
    qint64 startMs;
    int index;
};

class EventsModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(double dateCheckSum READ dateCheckSum NOTIFY dateCheckSumChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    enum Roles { SRole=Qt::UserRole+1, FRole, VRole, ColorRole, CommentRole, TypeRole, VisibleRole };
    explicit EventsModel(QObject* parent=nullptr);
    int rowCount(const QModelIndex& parent=QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int,QByteArray> roleNames() const override;
    bool ready() const;
    double dateCheckSum() const;

    Q_INVOKABLE void updateFromJson(const QString& json, const QVariantList& filter, int view, double prevSum);
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void clear();

    Q_INVOKABLE qint64 leftEventTime(qint64 currentMs, int evtType) const;
    Q_INVOKABLE qint64 rightEventTime(qint64 currentMs, int evtType) const;

signals:
    void readyChanged();
    void dateCheckSumChanged();
    void countChanged();
private:
    QVector<EventItem> m_items;
    QVector<EventIndex> m_sortedAll;
    QHash<int, QVector<EventIndex>> m_groupIndex;
    bool m_ready=false;
    double m_sum=0.0;
    QFutureWatcher<QPair<double,QVector<EventItem>>> m_watcher;

    void rebuildIndices();
    int findPrevIndex(qint64 currentMs, int evtType) const;
    int findNextIndex(qint64 currentMs, int evtType) const;
};
