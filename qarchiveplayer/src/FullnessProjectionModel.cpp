#include "FullnessProjectionModel.h"
#include "FullnessModel.h"
#include <QtMath>

static inline double clamp01(double x){ return x<0.0?0.0:(x>1.0?1.0:x); }

FullnessProjectionModel::FullnessProjectionModel(QObject* parent):QAbstractListModel(parent){}

int FullnessProjectionModel::rowCount(const QModelIndex& parent) const{
    if(parent.isValid()) return 0;
    return m_items.size();
}

QVariant FullnessProjectionModel::data(const QModelIndex& index, int role) const{
    if(!index.isValid()||index.row()<0||index.row()>=m_items.size()) return {};
    const auto& it=m_items.at(index.row());
    switch(role){
    case SRole: return it.s;
    case FRole: return it.f;
    case Color1Role: return it.color1;
    }
    return {};
}

QHash<int,QByteArray> FullnessProjectionModel::roleNames() const{
    return {
        {SRole,"s"},
        {FRole,"f"},
        {Color1Role,"color1"}
    };
}

QObject* FullnessProjectionModel::source() const{ return m_src; }
void FullnessProjectionModel::setSource(QObject* src){ if(m_src==(FullnessModel*)src) return; m_src=(FullnessModel*)src; emit sourceChanged(); }
QDateTime FullnessProjectionModel::startDate() const{ return m_start; }
void FullnessProjectionModel::setStartDate(const QDateTime& dt){ if(m_start==dt) return; m_start=dt; emit startDateChanged(); }
QDateTime FullnessProjectionModel::endDate() const{ return m_end; }
void FullnessProjectionModel::setEndDate(const QDateTime& dt){ if(m_end==dt) return; m_end=dt; emit endDateChanged(); }
int FullnessProjectionModel::viewWidth() const{ return m_viewWidth; }
void FullnessProjectionModel::setViewWidth(int w){ if(m_viewWidth==w) return; m_viewWidth=w; emit viewWidthChanged(); }
int FullnessProjectionModel::minPx() const{ return m_minPx; }
void FullnessProjectionModel::setMinPx(int p){ if(m_minPx==p) return; m_minPx=p; emit minPxChanged(); }
bool FullnessProjectionModel::clampNow() const{ return m_clampNow; }
void FullnessProjectionModel::setClampNow(bool on){ if(m_clampNow==on) return; m_clampNow=on; emit clampNowChanged(); }

void FullnessProjectionModel::project(){
    if(!m_src){ beginResetModel(); m_items.clear(); endResetModel(); emit countChanged(); return; }
    qint64 t0=m_start.toMSecsSinceEpoch();
    qint64 t1=m_end.toMSecsSinceEpoch();
    qint64 span=t1-t0;
    if(span<=0){ beginResetModel(); m_items.clear(); endResetModel(); emit countChanged(); return; }
    qint64 now=QDateTime::currentDateTime().toMSecsSinceEpoch();
    QVector<ProjectedFullness> out; out.reserve(m_src->rowCount());
    for(int i=0;i<m_src->rowCount();++i){
        QModelIndex idx=m_src->index(i,0);
        QDateTime s=m_src->data(idx,FullnessModel::SRole).toDateTime();
        QDateTime f=m_src->data(idx,FullnessModel::FRole).toDateTime();
        qint64 vs=qMax<qint64>(s.toMSecsSinceEpoch(), t0);
        qint64 vf=qMin<qint64>(f.toMSecsSinceEpoch(), t1);
        if(m_clampNow) vf=qMin<qint64>(vf, now);
        if(vf<=vs) continue;
        double ps=(vs-t0)/(double)span;
        double pf=(vf-t0)/(double)span;
        if(m_viewWidth>0 && m_minPx>0){
            double px=(pf-ps)*m_viewWidth;
            if(px>0.0 && px<m_minPx) continue;
        }
        ProjectedFullness pfv; pfv.s=clamp01(ps); pfv.f=clamp01(pf); pfv.color1=m_src->data(idx,FullnessModel::Color1Role).toString();
        out.push_back(std::move(pfv));
    }
    beginResetModel();
    m_items=std::move(out);
    endResetModel();
    emit countChanged();
}

QVariantMap FullnessProjectionModel::get(int row) const{
    QVariantMap m;
    if(row<0 || row>=m_items.size()) return m;
    const auto& it=m_items.at(row);
    m.insert("s", it.s);
    m.insert("f", it.f);
    m.insert("color1", it.color1);
    return m;
}

void FullnessProjectionModel::clear(){
    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
}
