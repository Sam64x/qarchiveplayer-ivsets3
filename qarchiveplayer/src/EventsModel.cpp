#include "EventsModel.h"
#include <QSet>
#include <limits>

static QDateTime parseIso(const QString& s){ return QDateTime::fromString(s, Qt::ISODate); }

EventsModel::EventsModel(QObject* parent):QAbstractListModel(parent){
    connect(&m_watcher,&QFutureWatcher<QPair<double,QVector<EventItem>>>::finished,this,[this](){
        auto res=m_watcher.result();
        double sum=res.first;
        auto vec=res.second;
        beginResetModel();
        m_items = vec;
        endResetModel();
        emit countChanged();
        m_sum=sum;
        emit dateCheckSumChanged();
        m_ready=true;
        emit readyChanged();
    });
}

int EventsModel::rowCount(const QModelIndex& parent) const {
    if(parent.isValid()) return 0;
    return m_items.size();
}

QVariant EventsModel::data(const QModelIndex& index, int role) const{
    if(!index.isValid()||index.row()<0||index.row()>=m_items.size()) return {};
    const auto& it=m_items.at(index.row());
    switch(role){
    case SRole: return it.s;
    case FRole: return it.f;
    case VRole: return it.v;
    case ColorRole: return it.color;
    case CommentRole: return it.comment;
    case TypeRole: return it.type;
    case VisibleRole: return it.visible;
    }
    return {};
}

QHash<int,QByteArray> EventsModel::roleNames() const{
    return {
        {SRole,"s"},
        {FRole,"f"},
        {VRole,"v"},
        {ColorRole,"color"},
        {CommentRole,"comment"},
        {TypeRole,"type"},
        {VisibleRole,"visible"}
    };
}

bool EventsModel::ready() const{ return m_ready; }
double EventsModel::dateCheckSum() const{ return m_sum; }

void EventsModel::updateFromJson(const QString& json, const QVariantList& filter, int, double){
    m_ready=false; emit readyChanged();
    auto future=QtConcurrent::run([json,filter]()->QPair<double,QVector<EventItem>>{
        QPair<double,QVector<EventItem>> out; out.first=0.0;
        if(json.isEmpty()) return out;
        QJsonParseError perr; QJsonDocument doc=QJsonDocument::fromJson(json.toUtf8(),&perr);
        if(perr.error!=QJsonParseError::NoError||!doc.isArray()) return out;
        QSet<int> allow; for(const auto& v: filter) allow.insert(v.toInt());
        const QJsonArray arr=doc.array();
        out.second.reserve(arr.size());
        double sum=0.0;
        for(int j=0;j<arr.size();++j){
            const QJsonObject o=arr.at(j).toObject();
            int typeId=o.value("typeid").toString().toInt();
            if(!allow.isEmpty() && !allow.contains(typeId)) continue;
            QDateTime s=parseIso(o.value("s").toString());
            QDateTime f=parseIso(o.value("f").toString());
            int gid=QString::fromUtf8(o.value("typeid").toString().toUtf8()).leftRef(1).toInt();
            QString color=(gid==2)?QStringLiteral("red"):QStringLiteral("#05f7ff");
            sum += (s.toMSecsSinceEpoch()/30000.0)*(j+1);
            out.second.push_back(EventItem{ s,f,100,color,o.value("comment").toString(),typeId,true });
        }
        out.first=sum;
        return out;
    });
    m_watcher.setFuture(future);
}

QVariantMap EventsModel::get(int row) const{
    QVariantMap m;
    if(row<0 || row>=m_items.size()) return m;
    const auto& it=m_items.at(row);
    m.insert("s", it.s);
    m.insert("f", it.f);
    m.insert("v", it.v);
    m.insert("color", it.color);
    m.insert("comment", it.comment);
    m.insert("type", it.type);
    m.insert("visible", it.visible);
    return m;
}

void EventsModel::clear(){
    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
    if(!m_ready){ m_ready=true; emit readyChanged(); }
}

qint64 EventsModel::leftEventTime(qint64 currentMs, int evtType) const{
    if(m_items.isEmpty()) return -1;
    bool isFound=false;
    qint64 resTime=std::numeric_limits<qint64>::min();
    for(const EventItem& it : m_items){
        qint64 eTime=it.s.toMSecsSinceEpoch();
        int eTypeGroup=it.type/10000;
        if(evtType<0 || eTypeGroup==evtType){
            if(eTime<currentMs && eTime>resTime){
                resTime=eTime;
                isFound=true;
            }
        }
    }
    if(!isFound) return -1;
    return resTime;
}

qint64 EventsModel::rightEventTime(qint64 currentMs, int evtType) const{
    if(m_items.isEmpty()) return -1;
    bool isFound=false;
    qint64 resTime=std::numeric_limits<qint64>::max();
    for(const EventItem& it : m_items){
        qint64 eTime=it.s.toMSecsSinceEpoch();
        int eTypeGroup=it.type/10000;
        if(evtType<0 || eTypeGroup==evtType){
            if(eTime>currentMs && eTime<resTime){
                resTime=eTime;
                isFound=true;
            }
        }
    }
    if(!isFound) return -1;
    return resTime;
}
