#include "EventsProjectionModel.h"
#include "EventsModel.h"
#include <QtMath>

static inline double clamp01(double x){ return x<0.0?0.0:(x>1.0?1.0:x); }

EventsProjectionModel::EventsProjectionModel(QObject* parent):QAbstractListModel(parent){}

int EventsProjectionModel::rowCount(const QModelIndex& parent) const{
    if(parent.isValid()) return 0;
    return m_items.size();
}

QVariant EventsProjectionModel::data(const QModelIndex& index, int role) const{
    if(!index.isValid()||index.row()<0||index.row()>=m_items.size()) return {};
    const auto& it=m_items.at(index.row());
    switch(role){
    case SRole: return it.s;
    case FRole: return it.f;
    case StartDateRole: return it.startDate;
    case VRole: return it.v;
    case ColorRole: return it.color;
    case CommentRole: return it.comment;
    case TypeRole: return it.type;
    case VisibleRole: return it.visible;
    }
    return {};
}

QHash<int,QByteArray> EventsProjectionModel::roleNames() const{
    return {
        {SRole,"s"},
        {FRole,"f"},
        {StartDateRole,"startDate"},
        {VRole,"v"},
        {ColorRole,"color"},
        {CommentRole,"comment"},
        {TypeRole,"type"},
        {VisibleRole,"visible"}
    };
}

QObject* EventsProjectionModel::source() const{ return m_src; }
void EventsProjectionModel::setSource(QObject* src){ if(m_src==(EventsModel*)src) return; m_src=(EventsModel*)src; emit sourceChanged(); }
QDateTime EventsProjectionModel::startDate() const{ return m_start; }
void EventsProjectionModel::setStartDate(const QDateTime& dt){ if(m_start==dt) return; m_start=dt; emit startDateChanged(); }
QDateTime EventsProjectionModel::endDate() const{ return m_end; }
void EventsProjectionModel::setEndDate(const QDateTime& dt){ if(m_end==dt) return; m_end=dt; emit endDateChanged(); }
int EventsProjectionModel::viewWidth() const{ return m_viewWidth; }
void EventsProjectionModel::setViewWidth(int w){ if(m_viewWidth==w) return; m_viewWidth=w; emit viewWidthChanged(); }
int EventsProjectionModel::minPx() const{ return m_minPx; }
void EventsProjectionModel::setMinPx(int p){ if(m_minPx==p) return; m_minPx=p; emit minPxChanged(); }

void EventsProjectionModel::project(){
    if(!m_src){ beginResetModel(); m_items.clear(); endResetModel(); emit countChanged(); return; }
    qint64 t0=m_start.toMSecsSinceEpoch();
    qint64 t1=m_end.toMSecsSinceEpoch();
    qint64 span=t1-t0;
    if(span<=0){ beginResetModel(); m_items.clear(); endResetModel(); emit countChanged(); return; }
    QVector<ProjectedEvent> out; out.reserve(m_src->rowCount());
    for(int i=0;i<m_src->rowCount();++i){
        QModelIndex sIdx=m_src->index(i,0);
        QDateTime s=m_src->data(sIdx,EventsModel::SRole).toDateTime();
        QDateTime f=m_src->data(sIdx,EventsModel::FRole).toDateTime();
        qint64 vs=qMax<qint64>(s.toMSecsSinceEpoch(), t0);
        qint64 vf=qMin<qint64>(f.toMSecsSinceEpoch(), t1);
        if(vf<=vs) continue;
        double ps=(vs-t0)/(double)span;
        double pf=(vf-t0)/(double)span;
        if(m_viewWidth>0 && m_minPx>0){
            double px=(pf-ps)*m_viewWidth;
            if(px>0.0 && px<m_minPx) continue;
        }
        ProjectedEvent pe;
        pe.s=clamp01(ps);
        pe.f=clamp01(pf);
        pe.startDate=s;
        pe.v=m_src->data(sIdx,EventsModel::VRole).toInt();
        pe.color=m_src->data(sIdx,EventsModel::ColorRole).toString();
        pe.comment=m_src->data(sIdx,EventsModel::CommentRole).toString();
        pe.type=m_src->data(sIdx,EventsModel::TypeRole).toInt();
        pe.visible=m_src->data(sIdx,EventsModel::VisibleRole).toBool();
        out.push_back(std::move(pe));
    }
    beginResetModel();
    m_items=std::move(out);
    endResetModel();
    emit countChanged();
}

QVariantMap EventsProjectionModel::get(int row) const{
    QVariantMap m;
    if(row<0 || row>=m_items.size()) return m;
    const auto& it=m_items.at(row);
    m.insert("s", it.s);
    m.insert("f", it.f);
    m.insert("startDate", it.startDate);
    m.insert("v", it.v);
    m.insert("color", it.color);
    m.insert("comment", it.comment);
    m.insert("type", it.type);
    m.insert("visible", it.visible);
    return m;
}

void EventsProjectionModel::clear(){
    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
}
