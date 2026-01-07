#pragma once
#include <QAbstractListModel>
#include <QDateTime>
#include <QVector>

class EventsModel;
struct ProjectedEvent {
    double s;
    double f;
    QDateTime startDate;
    int v;
    QString color;
    QString comment;
    int type;
    bool visible;
};

class EventsProjectionModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QObject* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QDateTime startDate READ startDate WRITE setStartDate NOTIFY startDateChanged)
    Q_PROPERTY(QDateTime endDate READ endDate WRITE setEndDate NOTIFY endDateChanged)
    Q_PROPERTY(int viewWidth READ viewWidth WRITE setViewWidth NOTIFY viewWidthChanged)
    Q_PROPERTY(int minPx READ minPx WRITE setMinPx NOTIFY minPxChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
public:
    enum Roles { SRole=Qt::UserRole+1, FRole, StartDateRole, VRole, ColorRole, CommentRole, TypeRole, VisibleRole };
    explicit EventsProjectionModel(QObject* parent=nullptr);
    int rowCount(const QModelIndex& parent=QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int,QByteArray> roleNames() const override;
    QObject* source() const;
    void setSource(QObject* src);
    QDateTime startDate() const;
    void setStartDate(const QDateTime& dt);
    QDateTime endDate() const;
    void setEndDate(const QDateTime& dt);
    int viewWidth() const;
    void setViewWidth(int w);
    int minPx() const;
    void setMinPx(int p);
    Q_INVOKABLE void project();
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void clear();
signals:
    void sourceChanged();
    void startDateChanged();
    void endDateChanged();
    void viewWidthChanged();
    void minPxChanged();
    void countChanged();
private:
    QVector<ProjectedEvent> m_items;
    EventsModel* m_src=nullptr;
    QDateTime m_start;
    QDateTime m_end;
    int m_viewWidth=0;
    int m_minPx=1;
};
