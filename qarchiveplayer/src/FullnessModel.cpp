#include "FullnessModel.h"
static QDateTime parseIso(const QString& s){ return QDateTime::fromString(s, Qt::ISODate); }
static QString hex2(int v){ QString s=QString::number(qBound(0, v, 255),16); if(s.size()<2) s.prepend('0'); return s; }

FullnessModel::FullnessModel(QObject* parent):QAbstractListModel(parent){
    connect(&m_watcher,&QFutureWatcher<QPair<double,QVector<FullnessItem>>>::finished,this,[this](){
        auto res=m_watcher.result();
        double sum=res.first;
        auto vec=res.second;
        beginResetModel();
        m_items=std::move(vec);
        endResetModel();
        emit countChanged();
        m_sum=sum;
        emit dateCheckSumChanged();
        m_ready=true;
        emit readyChanged();
    });
}

int FullnessModel::rowCount(const QModelIndex& parent) const{
    if(parent.isValid()) return 0;
    return m_items.size();
}

QVariant FullnessModel::data(const QModelIndex& index, int role) const{
    if(!index.isValid()||index.row()<0||index.row()>=m_items.size()) return {};
    const auto& it=m_items.at(index.row());
    switch(role){
    case SRole: return it.s;
    case FRole: return it.f;
    case Color1Role: return it.color1;
    }
    return {};
}

QHash<int,QByteArray> FullnessModel::roleNames() const{
    return {
        {SRole,"s"},
        {FRole,"f"},
        {Color1Role,"color1"}
    };
}

bool FullnessModel::ready() const{ return m_ready; }
double FullnessModel::dateCheckSum() const{ return m_sum; }

void FullnessModel::updateFromJson(const QString& json, int view, double){
    m_ready=false; emit readyChanged();
    auto future=QtConcurrent::run([json,view]()->QPair<double,QVector<FullnessItem>>{
        QPair<double,QVector<FullnessItem>> out; out.first=0.0;
        if(json.isEmpty()) return out;
        QJsonParseError perr; QJsonDocument doc=QJsonDocument::fromJson(json.toUtf8(),&perr);
        if(perr.error!=QJsonParseError::NoError) return out;
        QVector<FullnessItem> vec;
        double sum=0.0;
        static const QStringList colorType={ "006699","1c871a","a86d19","a4b304" };
        if(doc.isArray()){
            QJsonArray a=doc.array();
            if(view==0){
                for(int j=1;j<a.size();++j){
                    QDateTime s=parseIso(a.at(j-1).toObject().value("d").toString());
                    QDateTime f=parseIso(a.at(j).toObject().value("d").toString());
                    int arc=a.at(j).toObject().value("colorType").toInt();
                    double v=a.at(j-1).toObject().value("v").toDouble();
                    int op=int(std::sqrt(qMax(0.0, v/100.0))*255.0);
                    QString c="#"+hex2(op)+colorType.value(arc);
                    if(j==1 || j==a.size()-1 || j==(a.size()/2)) sum += s.toMSecsSinceEpoch()/3000.0;
                    vec.push_back({s,f,c});
                }
            } else if(view==1 || view==2){
                int tz=QDateTime::currentDateTime().offsetFromUtc()/60;
                for(int j=1;j<a.size();++j){
                    QDateTime s=parseIso(a.at(j-1).toObject().value("d").toString()).addSecs(-tz*60);
                    QDateTime f=parseIso(a.at(j).toObject().value("d").toString()).addSecs(-tz*60);
                    int arc=a.at(j).toObject().value("colorType").toInt();
                    double v=a.at(j-1).toObject().value("v").toDouble();
                    int op=int(std::sqrt(qMax(0.0, v/100.0))*255.0);
                    QString c="#"+hex2(op)+colorType.value(arc);
                    if(j==1 || j==a.size()-1 || j==(a.size()/2)) sum += s.toMSecsSinceEpoch()/3000.0;
                    vec.push_back({s,f,c});
                }
            } else {
                for(int j=0;j<a.size();++j){
                    QJsonArray r=a.at(j).toArray();
                    int arc=r.at(0).toInt();
                    QString sStr=r.at(1).toString();
                    QString fStr=r.at(2).toString();
                    QString ss=sStr, ff=fStr;
                    int cnt=0; QString ms;
                    for(int i=0;i<ss.size();++i){ if(cnt==3) ms+=ss.at(i); if(ss.at(i)==':') cnt++; }
                    QDateTime s=parseIso(sStr).addMSecs(ms.toInt());
                    cnt=0; ms.clear();
                    for(int i=0;i<ff.size();++i){ if(cnt==3) ms+=ff.at(i); if(ff.at(i)==':') cnt++; }
                    QDateTime f=parseIso(fStr).addMSecs(ms.toInt());
                    if(j==0 || j==a.size()-1 || j==(a.size()/2)) sum += s.toMSecsSinceEpoch()/3000.0;
                    QString c="#"+colorType.value(arc);
                    vec.push_back({s,f,c});
                }
            }
        }
        out.first=sum; out.second=std::move(vec);
        return out;
    });
    m_watcher.setFuture(future);
}

QVariantMap FullnessModel::get(int row) const{
    QVariantMap m;
    if(row<0 || row>=m_items.size()) return m;
    const auto& it=m_items.at(row);
    m.insert("s", it.s);
    m.insert("f", it.f);
    m.insert("color1", it.color1);
    return m;
}

void FullnessModel::clear(){
    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
    if(!m_ready){ m_ready=true; emit readyChanged(); }
}
