#include "IVArchSource.h"
#include <QJsonDocument>
#include "iv_core.h"

static profile_t _onDataPr;
static profile_t _onResultPr;

IVArchSource::IVArchSource(QString newName, QObject* parent) :
    QObject(parent)
{
    setName(newName);
    setVisible(true);
    _onDataPr = nullptr;
    _onResultPr = nullptr;
    callback_t cb111 = {this, responseFullness};
    iv::core::profile_open(_onDataPr, "trackWsServerCmd", 0, __FILE__, __LINE__);
    iv::core::profile_open(_onResultPr, "trackWsServerData", &cb111, __FILE__, __LINE__);
}

IVArchSource::~IVArchSource()
{
    if (_onDataPr) {
        iv::core::profile_close(_onDataPr);
        _onDataPr = nullptr;
    }
    if (_onResultPr) {
        iv::core::profile_close(_onResultPr);
        _onResultPr = nullptr;
    }
}

// setters/getters
int IVArchSource::scale() {return _scale;}
void IVArchSource::setScale(int n) {
    _scale = n;
    emit scaleChanged();
}

QString IVArchSource::name() {return _name;}
void IVArchSource::setName(QString n) {
    _name = n;
    emit nameChanged();
}

bool IVArchSource::visible() {return _visible;}
void IVArchSource::setVisible(bool n) {
    _visible = n;
    emit visibleChanged();
}

QJsonArray IVArchSource::events() {return _events;}
void IVArchSource::setEvents(QJsonArray n) {
    _events = n;
    emit eventsChanged();
}

QJsonArray IVArchSource::bookmarks() {return _bookmarks;}
void IVArchSource::setBookmarks(QJsonArray n) {
    _bookmarks = n;
    emit bookmarksChanged();
}

QJsonArray IVArchSource::fullness() {return _fullness;}
void IVArchSource::setFullness(QJsonArray n) {
    _fullness = n;
    emit fullnessChanged();
}

QPair<QDateTime, QDateTime> IVArchSource::interval() {return _interval;}
void IVArchSource::setInterval(QString s, QString e)
{
    QString format = "yyyy-MM-dd hh:mm:ss.zzz";
    QDateTime sT = QDateTime::fromString(s, format);
    QDateTime eT = QDateTime::fromString(s, format);
    setInterval(QPair(sT, eT));
}
void IVArchSource::setInterval(QPair<QDateTime, QDateTime> p)
{
    _interval = p;
    emit intervalChanged();
    requestFullness();
}

void IVArchSource::requestFullness()
{
    //sendRequest(start, finish, name());
    QString startStr= interval().first.toString("yyyy.MM.dd hh:mm:ss");
    QString finishStr = interval().second.toString("yyyy.MM.dd hh:mm:ss");
    QString cmd = "";
    // Дальше запрос заполненности по текущему масштабу
    switch (scale()) {
    case 7:
        //qDebug()<<"ArchivePlayer::getFullness YEAR SCALE";
        cmd = "{\"cmd\":\"archive:pass_graph4\","
                "\"params\":{\"key1\": \"\","
                "\"key2\": \""+name()+"\","
                "\"key3\": \"\","
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\"}"
                "}";
        break;
    case 6:
        //qDebug()<<"ArchivePlayer::getFullness MONTH SCALE";
        startStr = interval().first.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        finishStr = interval().second.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        cmd = "{"
                "\"cmd\":\"archive:pass_graph_by_corn\","
                "\"params\":"
                "{"
                "\"key2\": \""+name()+"\","
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"value\": \"week\""
                "}"
                "}";
        break;
    case 5:
        //qDebug()<<"ArchivePlayer::getFullness WEEK SCALE";
        startStr = interval().first.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        finishStr = interval().second.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        cmd = "{"
                "\"cmd\":\"archive:pass_graph_by_corn\","
                "\"params\":"
                "{"
                "\"key2\": \""+name()+"\","
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"value\": \"day\""
                "}"
                "}";
        break;
    case 4:
        //qDebug()<<"ArchivePlayer::getFullness DAY SCALE";
        startStr = interval().first.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        finishStr = interval().second.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        //qDebug()<<startStr << finishStr;
        cmd = "{"
                "\"cmd\":\"archive:intervals\","
                "\"params\":"
                "{"
                "\"key1\": \"\","
                "\"key2\": \""+name()+"\","
                "\"key3\": \"\","
                "\"key4\": \"\","
                "\"cam_id\": 0,"
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"longer\": 3600,"
                "\"type\": \"\""
                "}"
                "}";
        break;
    case 3:
        //qDebug()<<"ArchivePlayer::getFullness HOUR SCALE";
        cmd = "{"
                "\"cmd\":\"archive:intervals\","
                "\"params\":"
                "{"
                "\"key1\": \"\","
                "\"key2\": \""+name()+"\","
                "\"key3\": \"\","
                "\"key4\": \"\","
                "\"cam_id\": 0,"
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"longer\": 30,"
                "\"type\": \"\""
                "}"
                "}";
        break;
    case 2:
        //qDebug()<<"ArchivePlayer::getFullness 30 MIN SCALE";
        cmd = "{"
                "\"cmd\":\"archive:intervals\","
                "\"params\":"
                "{"
                "\"key1\": \"\","
                "\"key2\": \""+name()+"\","
                "\"key3\": \"\","
                "\"key4\": \"\","
                "\"cam_id\": 0,"
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"longer\": 15,"
                "\"type\": \"\""
                "}"
                "}";
        break;
    case 1:
        //qDebug()<<"ArchivePlayer::getFullness 10 MIN SCALE";
        cmd = "{"
                "\"cmd\":\"archive:intervals\","
                "\"params\":"
                "{"
                "\"key1\": \"\","
                "\"key2\": \""+name()+"\","
                "\"key3\": \"\","
                "\"key4\": \"\","
                "\"cam_id\": 0,"
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"longer\": 5,"
                "\"type\": \"\""
                "}"
                "}";
        break;
    case 0:
        //qDebug()<<"ArchivePlayer::getFullness MINUTE SCALE";
        cmd = "{"
                "\"cmd\":\"archive:intervals\","
                "\"params\":"
                "{"
                "\"key1\": \"\","
                "\"key2\": \""+name()+"\","
                "\"key3\": \"\","
                "\"key4\": \"\","
                "\"cam_id\": 0,"
                "\"begin\": \""+startStr+"\","
                "\"end\": \""+finishStr+"\","
                "\"longer\": 1,"
                "\"type\": \"\""
                "}"
                "}";
        break;
    }
    if (cmd != "")
    {
        int timeout = 2;
        int is_local = 0;
        char* _cmd = cmd.toUtf8().data();
        const char* _myOwner = (char*)this;
        param_t p2[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", this},
            {PARAM_PVOID, "owner_data", _myOwner},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
        // qDebug() << "requestFullness" << name() << _cmd;
        iv::core::profile_data(_onDataPr, p2);
    }
}
void IVArchSource::responseFullness(const void* udata, const param_t* p)
{
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
        if ((owner != udata) || (owner_data == nullptr)) return;
        IVArchSource* ctx = (IVArchSource*)owner;
        if ((char*)owner_data == (char*)owner)
        {
            if (json != nullptr && json != "Timeout")
            {
                QJsonArray newFullness;
                QJsonArray obj;
                QJsonDocument doc = QJsonDocument::fromJson(json);
                if (!doc.isNull())
                {
                    if (doc.isArray())
                    {
                        obj = doc.array();
                        QJsonArray fill_arr;

                        if (obj[0].toArray()[0].toObject().contains("fill")){
                            fill_arr = obj[0].toArray()[0].toObject()["fill"].toArray();
                        }
                        else if (obj[0].toObject().contains("res")){
                            fill_arr = obj[0].toObject()["res"].toArray();
                        }
                        else {
                            ctx->setFullness(newFullness);
                            return;
                        }
                        uint64_t allMS = ctx->_interval.second.toMSecsSinceEpoch() - ctx->_interval.first.toMSecsSinceEpoch();
                        for (auto i : fill_arr) {
                            QJsonObject val;
                            QString f = "yyyy.MM.dd hh:mm:ss:zzz";
                            uint64_t startAbs = QDateTime::fromString(i.toArray()[1].toString(), f).toMSecsSinceEpoch();
                            startAbs -= ctx->_interval.first.toMSecsSinceEpoch();

                            uint64_t endAbs = QDateTime::fromString(i.toArray()[2].toString(), f).toMSecsSinceEpoch();
                            endAbs -= ctx->_interval.first.toMSecsSinceEpoch();

                            val.insert("startPos", double(startAbs)/allMS);
                            val.insert("endPos", endAbs >= allMS ? 1 : double(endAbs)/allMS);
                            newFullness.append(val);
                        }
                    }
                    ctx->setFullness(newFullness);
                }
            }
        }
    }
}

