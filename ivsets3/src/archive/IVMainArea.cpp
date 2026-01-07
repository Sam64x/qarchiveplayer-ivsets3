#include "IVMainArea.h"
#include <iv_core.h>
#include <QDebug>

static const char* myOwner = "custom_new_arc_window";
static profile_t eventsReqPr;
static profile_t eventsResPr;

void IVMainArea::responseEvents(const void* udata, const param_t* p)
{
    St2_FUNCT_St2(100);
    int32_t code = 0;
    const char* user_msg = nullptr;
    void* owner = nullptr;
    void* owner_data = nullptr;
    const char* json = nullptr;
    for (each_param(p)) {
        param_start;
        param_get_int32(code);
        param_get_pchar(user_msg);
        param_get_pchar(json);
        param_get_pvoid(owner);
        param_get_pvoid(owner_data);
    }
    if (owner != nullptr && owner_data != nullptr)
    {
        if ((owner != udata)) return;
        IVMainArea* ctx = (IVMainArea*)owner;
        if ((char*)owner_data == myOwner)
        {
            if (json != nullptr && json != "Timeout")
            {
                QJsonDocument doc = QJsonDocument::fromJson(json);
                QJsonArray events = doc.array()[0].toObject().value("rows").toArray();
                qDebug() << "Получено" << events.size() << "событий";
                ctx->setEventsToSources(events);
            }
        }
    }
}

void IVMainArea::requestEvents()
{
    St2_FUNCT_St2(200);
    if (!_start.isValid() || !_end.isValid() || _sources.length() == 0)
    {
        _events = QJsonArray();
        _bookmarks = QJsonArray();
        emit eventsChanged();
        emit bookmarksChanged();
        return;
    }

    {
        _filter.insert("op", "and");
        QJsonArray group;

        QJsonObject startObj;
        startObj.insert("col", "evttime");
        startObj.insert("op", ">=");
        startObj.insert("val", _start.toString("yyyy-MM-dd hh:mm:ss.zzz"));
        group.append(startObj);

        QJsonObject endObj;
        endObj.insert("col", "evttime");
        endObj.insert("op", "<=");
        endObj.insert("val", _end.toString("yyyy-MM-dd hh:mm:ss.zzz"));
        group.append(endObj);

        QJsonObject camsObj;
        QJsonArray camsGroup;
        camsObj.insert("op","or");
        for (auto cam : _sources){
            QJsonObject camObj;
            camObj.insert("col", "evtdevkey2");
            camObj.insert("op", "=");
            camObj.insert("val", cam->name());
            camsGroup.append(camObj);
        }
        camsObj.insert("group", camsGroup);
        group.append(camsObj);

        if (eventsGroup.length() > 0){
            QJsonObject eventsObj;
            QJsonArray eventsArr;
            eventsObj.insert("col", "evttypeid");
            eventsObj.insert("op", includeEventsMode ? "=" : "!=");
            for (auto ev : eventsGroup){
                qint64 id = ev.toLongLong();
                eventsArr.push_back(id);
            }
            eventsObj.insert("val", eventsArr);
            group.append(eventsObj);
        }
        _filter.insert("group", group);
    }
    //QByteArray docBArr = QJsonDocument(_filter).toJson(QJsonDocument::Compact);
    //qDebug() << "Filter is" << docBArr.toStdString().c_str();

    QJsonObject cmd_js;
    cmd_js.insert("cmd", "ewr_pg:get_events");

    QJsonObject params_js;
    params_js.insert("page_size", 0);
    params_js.insert("index_page", 0);

    QJsonArray camsGroup;
    for (auto cam : _sources){
        camsGroup.append(cam->name());
    }
    QDateTime s = _start.toUTC();
    QDateTime e = _end.toUTC();
    params_js.insert("key2", camsGroup);
    params_js.insert("t_start", s.toString("yyyy-MM-dd hh:mm:ss.zzz"));
    params_js.insert("t_end", e.toString("yyyy-MM-dd hh:mm:ss.zzz"));

    params_js.insert("fields", QJsonArray({"evttypeid","evttime", "evtdevkey2", "ettname", "evtid", "evtcomment"}));

    QJsonArray eventsArr;
    for (auto ev : eventsGroup){
        qint64 id = ev.toLongLong();
        eventsArr.push_back(id);
    }
    params_js.insert("typeid", eventsArr);
    cmd_js.insert("params", params_js);

    QByteArray docBArr2 = QJsonDocument(cmd_js).toJson(QJsonDocument::Indented);
    if (!docBArr2.isEmpty())
    {
        int timeout = 2;
        int is_local = 0;
        char* _cmd = docBArr2.data();
        param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", this},
            {PARAM_PVOID, "owner_data", myOwner},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
        //qDebug() << "requestEvents cmd" << _cmd;
        iv::core::profile_data(eventsReqPr, p);
    }
}

void IVMainArea::updateEventsGroup(bool mode, QStringList events)
{
    St2_FUNCT_St2(300);
    qDebug() << "IVMainArea::updateEventsGroup";
    includeEventsMode = mode;
    eventsGroup = events;
    requestEvents();
}

void IVMainArea::setIntervalToSources()
{
    St2_FUNCT_St2(400);
    if (!start().isValid() || start().isNull()) return;
    if (!end().isValid()|| end().isNull()) return;
    for (auto i : _sources) {
        if (i->interval() != QPair(start(),end())){
            i->setInterval(QPair(start(), end()));
        }
    }
}

void IVMainArea::setEventsToSources(QJsonArray evts)
{
    St2_FUNCT_St2(500);
    _events = QJsonArray();
    _bookmarks = QJsonArray();
    for (auto evt : evts)
    {
        QJsonObject event, evtObj = evt.toObject();
        QString format = "yyyy-MM-dd hh:mm:ss.zzz";
        QDateTime startTime = QDateTime::fromString(evtObj.value("evttime").toString(), format);
        startTime.addSecs(QDateTime::currentDateTime().offsetFromUtc());
        int timeDuration = 60;
        int64_t allMS = _end.toMSecsSinceEpoch() - _start.toMSecsSinceEpoch();
        int64_t startMS = startTime.toMSecsSinceEpoch() - _start.toMSecsSinceEpoch();
        double startPos = (double)startMS/allMS;
        double endPos = (double)(startMS+timeDuration*1000)/allMS;

        event.insert("startPos", startPos);
        event.insert("endPos", endPos);
        event.insert("endTime", startTime.addSecs(timeDuration).toString(format));
        event.insert("startTime", startTime.toString(format));
        event.insert("source", evtObj.value("evtdevkey2").toString());
        if (evtObj.contains("evtcomment")) event.insert("comment", evtObj.value("evtcomment").toString());
        event.insert("typeName", evtObj.value("ettname").toString());

        long long typeId = evtObj.value("evttypeid").toVariant().toLongLong();
        QVector<long long> bmTypes{60047, 60046, 60045, 60044};
        qDebug() << "Event" << event;
        if (bmTypes.contains(typeId)) _bookmarks.append(event);
        else _events.append(event);
    }
    emit eventsChanged();
    emit bookmarksChanged();
    for (auto i : _sources)
    {
        QJsonArray srcEvt, srcBm;
        for (auto j : _events) {
            QJsonObject obj = j.toObject();
            if (obj.value("source").toString() == i->name())
                srcEvt.append(obj);
        }
        for (auto j : _bookmarks) {
            QJsonObject obj = j.toObject();
            if (obj.value("source").toString() == i->name())
                srcBm.append(obj);
        }
        i->setEvents(srcEvt);
        i->setBookmarks(srcBm);
    }
}

void IVMainArea::getCamsList()
{
    St2_FUNCT_St2(600);
    QString camsPath, sep(QDir::separator());
    camsPath += QCoreApplication::applicationDirPath()+sep+"databases"+sep+"new_sets"+sep+"cams";
    QDir dd(camsPath);
    if (!dd.exists(camsPath)) return;

    camsPath = dd.absolutePath()+sep+"cameras";
    QFile file(camsPath);
    if (file.open(QIODevice::ReadOnly)){
        QJsonDocument jsonDoc = QJsonDocument::fromJson(file.readAll());
        QJsonArray camsArr = jsonDoc.array();
        for (auto i : camsArr){
            _allSourcesList.push_back(i.toString());
        }
        emit allSourcesListChanged();
    }
}

IVMainArea::IVMainArea(QObject* parent) :
    QObject(parent)
{
    St2_FUNCT_St2(700);
    QDateTime date = QDateTime::currentDateTime();
    setEnd(date);
    setStart(date.addSecs(-3600));
    getCamsList();

    eventsReqPr = nullptr;
    eventsResPr = nullptr;
    callback_t cb = {this, responseEvents};
    iv::core::profile_open(eventsReqPr, "trackWsServerCmd", 0, __FILE__, __LINE__);
    iv::core::profile_open(eventsResPr, "trackWsServerData", &cb, __FILE__, __LINE__);
}
IVMainArea::~IVMainArea()
{
    St2_FUNCT_St2(800);
    if (eventsReqPr) {
        iv::core::profile_close(eventsReqPr);
        eventsReqPr = nullptr;
    }
    if (eventsResPr) {
        iv::core::profile_close(eventsResPr);
        eventsResPr = nullptr;
    }
}

// setters/getters
const QList<QObject*> IVMainArea::sourcesAsObj() const
{
    St2_FUNCT_St2(900);
    QObjectList res;
    res.reserve(_sources.count());
    for (auto i : _sources) res.append(i);
    return res;
}
void IVMainArea::addSources(QStringList names) {
    St2_FUNCT_St2(1000);
    bool updated = false;
    for (auto newSource : names)
    {
        bool finded = false;
        for (auto src : _sources) {
            if (src->name() == newSource) {
                finded = true;
                break;
            }
        }
        if (!finded) {
            _sources.push_back(new IVArchSource(newSource, this));
            updated = true;
        }
    }
    if (updated) {
        emit sourcesChanged();
        setIntervalToSources();
        requestEvents();
    }
}

void IVMainArea::removeSources(QStringList names)
{
    St2_FUNCT_St2(1100);
    bool updated = false;
    for (auto delSrc : names)
    {
        for (auto src : _sources) {
            if (src->name() == delSrc) {
                _sources.removeOne(src);
                delete src;
                updated = true;
                break;
            }
        }
    }
    if (updated) {
        emit sourcesChanged();
        setIntervalToSources();
        requestEvents();
    }
}

void IVMainArea::moveSource(int from, int to)
{
    St2_FUNCT_St2(1200);
    _sources.move(from, to);
    emit sourcesChanged();
}

QStringList IVMainArea::allSourcesList(){return _allSourcesList;}

QJsonArray IVMainArea::events() {return _events;}

QJsonArray IVMainArea::bookmarks() {return _bookmarks;}

QDateTime IVMainArea::start() {return _start;}
void IVMainArea::setStart(QDateTime n) {
    St2_FUNCT_St2(1300);
    _start = n;
    emit startChanged();
    setIntervalToSources();
    requestEvents();
}

QDateTime IVMainArea::end() {return _end;}

void IVMainArea::setInterval(QDateTime s, QDateTime e)
{
    St2_FUNCT_St2(1400);
    _start = s;
    _end = e;
    emit startChanged();
    emit endChanged();
    setIntervalToSources();
    requestEvents();
}
void IVMainArea::setEnd(QDateTime n) {
    St2_FUNCT_St2(1500);
    _end = n;
    emit endChanged();
    setIntervalToSources();
    requestEvents();
}
