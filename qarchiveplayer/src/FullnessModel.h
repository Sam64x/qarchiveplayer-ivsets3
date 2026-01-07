#pragma once
#include <QAbstractListModel>
#include <QDateTime>
#include <QVector>
#include <QFutureWatcher>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QtConcurrent>

struct FullnessItem {
    QDateTime s;
    QDateTime f;
    QString color1;
};

class FullnessModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(double dateCheckSum READ dateCheckSum NOTIFY dateCheckSumChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    enum Roles { SRole=Qt::UserRole+1, FRole, Color1Role };
    explicit FullnessModel(QObject* parent=nullptr);
    int rowCount(const QModelIndex& parent=QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int,QByteArray> roleNames() const override;
    bool ready() const;
    double dateCheckSum() const;
    Q_INVOKABLE void updateFromJson(const QString& json, int view, double prevSum);
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void clear();
signals:
    void readyChanged();
    void dateCheckSumChanged();
    void countChanged();
private:
    QVector<FullnessItem> m_items;
    bool m_ready=false;
    double m_sum=0.0;
    QFutureWatcher<QPair<double,QVector<FullnessItem>>> m_watcher;
};
