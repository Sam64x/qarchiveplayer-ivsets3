#include "IVCustomSets.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QTextStream>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

#include "iv_stable.h"
#include "iv_threads_pool.h"
#include "iv_tasks_noncritical.h"
#include <iv_ewriter.h>

constexpr auto server_sets = "server_sets";
constexpr auto customset_cams = "customset_cams";
constexpr auto customset_sets_maps = "customset_sets_maps";
constexpr auto customset_fact_list = "customset_fact_list";
constexpr auto customset_groups_remote = "customset_groups_remote";
constexpr auto customset_groups_sets_remote = "customset_groups_sets_remote";

constexpr auto set_added_on_server = "set_added_on_server";
constexpr auto set_removed_on_server = "set_removed_on_server";
constexpr auto only_sets_update = "only_sets_update";

constexpr auto camsParams = "{"
                            "\"type\":\"camera\","
                            "\"params\":{"
                            "\"key2\":{\"type\":\"var\",\"value\":[\"\"]},"
                            "\"running\":{\"type\":\"var\",\"value\":[true]}"
                            "}}";
constexpr auto mapsParams ="{"
                         " \"type\":\"MapViewer\","
                         " \"params\": {\"jsonDataFileName\":{\"type\":\"var\",\"value\":[\"\"]}}"
                         "}";

QString getSetsPath() {
    static const QString path = QDir(QCoreApplication::applicationDirPath()).filePath("databases/new_sets/sets");
    return path;
}
QString getOtherPath() {
    static const QString path = QDir(QCoreApplication::applicationDirPath()).filePath("databases/new_sets/other");
    return path;
}

IVCustomSets* IVCustomSets::instance()
{
    static IVCustomSets inst;
    return &inst;
}

IVCustomSets::IVCustomSets(QObject* parent)
    : QObject(parent)
{
    St2_FUNCT_St2(23544);

    callback_t clientInfoCallback = {this, on_track_client_info};
    // callback_t eventsCallback = {this, on_track_events};
    callback_t eventsCallback = {this, onresult};

    iv::core::profile_open(_onDataPr,"trackWsServerCmd",0,__FILE__,__LINE__);
    iv::core::profile_open(_onResultPr,"trackWsServerData",&eventsCallback,__FILE__,__LINE__);
    iv::core::profile_open(_ipProfile,"track_users_gui_client", &clientInfoCallback, __FILE__, __LINE__);
    iv::core::profile_open(_camsUpdateProfile,"needCamsUpdate",0,__FILE__, __LINE__);

    _zu = 0;

    if (_ipProfile) {
        param_t pr_cmd[] = {
            {PARAM_PCHAR, "cmd",      "current_user_get"},
            {PARAM_PCHAR, "session_id","sets3"},
            {PARAM_PVOID, "owner",    this},
            {0,0,0}
        };
        iv::core::profile_data(_ipProfile, pr_cmd);
    }
}

IVCustomSets::~IVCustomSets()
{
    if(_zu) {
        iv::tasks::noncritical::remove(_zu);
    }
    _zu = 0;

    if (_camsUpdateProfile) {
        iv::core::profile_close(_camsUpdateProfile);
        _camsUpdateProfile = nullptr;
    }
    if (_onDataPr) {
        iv::core::profile_close(_onDataPr);
        _onDataPr = nullptr;
    }
    if (_ipProfile) {
        iv::core::profile_close(_ipProfile);
        _ipProfile = nullptr;
    }
    if (_onResultPr) {
        iv::core::profile_close(_onResultPr);
        _onResultPr = nullptr;
    }
}

void IVCustomSets::on_track_client_info(const void* udata, const param_t* p)
{
    IVCustomSets* _this = (IVCustomSets*)udata;
    if(!_this)
        return;
    const char* login = nullptr;
    const char* ip = nullptr;
    iv_int64 login_hash = 0;
    const char* cmd = nullptr;
    param_t* user = nullptr;
    int32_t auth_on = 1;

    for (each_param(p))
    {
        param_start;
        param_get_pchar(cmd);
        param_get_config(user);
        param_get_int32(auth_on);
    }

    if ((cmd != nullptr) || (user == nullptr))
        return;

    for (each_param(user))
    {
        param_start;
        param_get_pchar(login);
        param_get_pchar(ip);
        param_get_int64(login_hash);
    }

    if (login) {
        _this->setCurrentUser(login);
        _this->setSourcesReady(false);

        iv::threads::pool::execute("custom_cams", general_cameras_updater, _this);
        iv::threads::pool::execute("custom_maps", general_maps_updater, _this);
        iv::threads::pool::execute("custom_sets", general_server_sets_updater, _this);
        iv::threads::pool::execute("custom_fact_list", general_fact_list_updater, _this);
        iv::threads::pool::execute("custom_group_set_list", general_custom_group_set_list_updater, _this);
        iv::threads::pool::execute("custom_group_list", general_custom_group_list_updater, _this);
    }
}

void IVCustomSets::events_updater_thousand(void *thread, void *udata)
{
    St2_FUNCT_St2(5230);
    Q_UNUSED(thread);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if(_this) {
        _this->getEvents();
    }
}
void IVCustomSets::initMap()
{
    getMapsFromFile();
    if(!_zu)
        _zu=iv::tasks::noncritical::add2("events_updater",events_updater_thousand,this,5000,1);

    //qDebug()<<"eventMapChanged";
    //emit eventMapChanged("План 5.json","cam_11.49");
}

void IVCustomSets::deinitMap()
{
    if(_zu)iv::tasks::noncritical::remove(_zu);
    _zu = 0;
    _lastEventTime = "";

}

void IVCustomSets::getMapsFromFile()
{
    QDir newSetsDir;
    if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
    newSetsDir.cd("databases");
    QFile file(QString(newSetsDir.absolutePath() + QDir::separator() + "maps_analogy"));
    file.open(QFile::ReadOnly);
   // qDebug()<< "Open file:"<< file.fileName();
    const QJsonArray groupsArr = QJsonDocument::fromJson(file.readAll()).array();
    file.close();

    for (const auto& i : groupsArr)
    {
        QJsonObject obj = i.toObject();
        QString _mapName = obj.value("mapName").toString();
        QVariant _key2s =obj.value("key2").toVariant();
        _mapsAnalogy[_mapName] = _key2s;
    }

}

void IVCustomSets::on_track_events(const void* udata, const param_t* p)
{
    IVCustomSets* _this = (IVCustomSets*)udata;
    if(!_this)
        return;
    St2_FUNCT_St2(1446);
    int32_t code = 0;
    const char* user_msg = nullptr;
    void* owner = nullptr;
    void* owner_data = nullptr;
    char* json = nullptr;
    char* result = nullptr;
    char* method = nullptr;
    for (each_param(p)) {
        param_start;
        param_get_int32(code);
        param_get_pchar(user_msg);
        param_get_pchar(result);
        param_get_pchar(json);
         param_get_pchar(method);
        param_get_pvoid(owner);
        param_get_pvoid(owner_data);
    }

    // qDebug()<< "on_track_events" << method;
    St2(9046)
    if(owner != 0 && owner ==udata && owner_data != 0)
    {

//qDebug()<< "on_track_events222" << json << method ;
        St2(2326)
        if (json != 0 )
        {
            St2(3522);
            myajl_val _json = mjson_parse(json);
            if(_json)
            {
                // recurseParseJson(_json);
                if((*_json).IsArray())
                {
                    int elemCount = (*_json).GetNumElems();
                    for(int i1= 0; i1<elemCount;i1++)
                    {
                        myajl_val rows = (*_json)[i1]("rows");
                        if(rows && (*rows).IsArray())
                        {
                            int elemCount2 = (*rows).GetNumElems();
                            for(int i2=0;i2<elemCount2;i2++)
                            {
                                char* evtKey2 = (*rows)[i2]("evtdevkey2");
                                //qDebug()<< "evtdevkey2 = "<<evtKey2;
                                char* evtTime = (*rows)[i2]("evttime");
                                bool isFoundKey2 = false;
                                const auto mapsKeys = _this->_mapsAnalogy.keys();
                                foreach (QString key, mapsKeys)
                                {
                                    //qDebug()<< "FOUND IN" << key;
                                    QVariant _values = _this->_mapsAnalogy.value(key);
                                    const QJsonArray camsArray = _values.toJsonArray();
                                    //qDebug()<< "FOUND IN SIZE" << camsArray.size();
                                    for(const auto& i2: camsArray)
                                    {
                                        QString __key2 = i2.toString();
                                        //qDebug()<< "FOUND TO" << __key2;
                                        QByteArray tKey2 = __key2.toUtf8();
                                        char* cKey2 = tKey2.data();
                                        //qDebug()<< "FOUND ALL" <<cKey2<< evtKey2;
                                        if(!evtKey2)
                                            continue;
                                        if(!strcmp(cKey2,evtKey2))
                                        {
                                            _this->_lastEventTime = evtTime;
                                            //qDebug()<<"LAST TIME = "<< evtKey2 << cKey2 << _this->lastEventTime;
                                            emit _this->eventMapChanged(key,cKey2);
                                            isFoundKey2 = true;
                                            //CrushhhMsg("wadawdawd");
                                            //break;
                                        }
                                    }
                                    if(isFoundKey2)
                                    {
                                        //break;
                                    }

                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

void IVCustomSets::getEvents()
{
    St2_FUNCT_St2(3456);
    ::iv::ws::call_interrupt _iv_ws_call_interrupt;
    ::iv::ewriter::call get_events(_iv_ws_call_interrupt, 200000);
    // QDateTime dt2 = QDateTime::currentDateTime();

    if(_lastEventTime.isEmpty())
    {
        //time.setTimeSpec(Qt::UTC);
        QString localTime = QDateTime::currentDateTimeUtc().toString("yyyy-MM-dd hh:mm:ss.zzz");
        _lastEventTime = localTime;
        //qDebug()<<"LAST EVENT TIME = " << localTime;
        //CrushhhMsg("sefsdf");
    }
    QString sss = "{\n"
    "\"cmd\":\"select\",\n"
    "\"params\":"
    "{\n"
    "\"func\":\"select_events_full\",\n"
    "\"language\":\"russian\",\n"
    "\"page_size\":10,\n"
    "\"order_by\":"
    "[\n"
    "{\n"
    " \"col\":\"evttime\",\n"
    " \"order\":\"asc\" \n"
    "},\n"
    "{\n"
    "\"col\":\"evtid\",\n"
    "\"order\":\"asc\" \n"
    "}\n"
    "],\n"
    "\"filter\":"
    "{\n"
    " \"group\":"
    "[\n"
    "{\n"
    " \"col\":\"evttime\",\n"
    "\"op\":\">\",\n"
    "\"val\":\""+_lastEventTime+"\"\n"
    "},\n"
    "{\n"
    "\"col\":\"evttypeid\",\n"
    "\"op\":\"=\",\n"
    "\"val\":"
    "[\n"
    "20001,\n"
    "20008,\n"
    "20009,\n"
    "20010,\n"
    "20015,\n"
    "20016,\n"
    "20017,\n"
    "20018,\n"
    "20019,\n"
    "20020,\n"
    "20021,\n"
    "20022,\n"
    "20024,\n"
    "20025,\n"
    "20026,\n"
    "20027,\n"
    "20028,\n"
    "20030,\n"
    "20034,\n"
    "20035,\n"
    "20072,\n"
    "20074,\n"
    "20075,\n"
    "20076,\n"
    "20078,\n"
    "20080,\n"
    "20081,\n"
    "20084,\n"
    "20101,\n"
    "20103,\n"
    "20120,\n"
    "20122\n "
    "]\n"
    "}\n"
    "],\n"
    "\"op\":\"and\"\n"
    "}\n"
    "}\n"
    "}";

    QByteArray ccc = sss.toUtf8();
    char* uuu = ccc.data();

    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1(uuu);
    jConfig->Add("cmd","ewriter:exec");


    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);
    //qDebug()<< "NEW FILTER = " << _cmd;
    int timeout = 10;
    int is_local = 0;
    param_t p2[] =
    {
        {PARAM_PCHAR, "cmd", _cmd},
        {PARAM_PINT32,"timeout", &timeout},
        {PARAM_PVOID, "owner", this},
        {PARAM_PVOID, "owner_data", this},
        {PARAM_PINT32,"is_local",&is_local},
        {0, 0, 0}
    };
    iv::core::profile_data(_onDataPr,p2);
}

QString IVCustomSets::getCurrentUser() const
{
    return _currentUser;
}
void IVCustomSets::setCurrentUser(const QString &val)
{
    if (_currentUser != val) {
        _currentUser = val;
        emit currentUserChanged();
    }
}

bool IVCustomSets::sourcesReady() const
{
    return _sourcesReady;
}
void IVCustomSets::setSourcesReady(bool value)
{
    QMutexLocker locker(&sourcesReadyMutex);

    if (_sourcesReady != value) {
        _sourcesReady = value;
        emit sourcesReadyChanged();
    }
}

QString IVCustomSets::getZonesCommon(const QString& setId)
{
    St2_FUNCT_St2(3787);
    auto localSetsFile = getFilePath(getSetsPath(), QStringLiteral("sets"));
    QString result {"{}"};
    if (!localSetsFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        return result;
    }
    QByteArray ba = localSetsFile.readAll();
    localSetsFile.close();

    myajl_val setsData = mjson_parse1(ba.data());
    if ((*setsData).IsArray()) {
        for (int i = 0; i < (*setsData).GetNumElems(); i++) {
            const auto itemSetId = QString(static_cast<char*>((*setsData)[i]("setId")));
            if (itemSetId == setId) {
                char* setString = mjson_generate1((*setsData)[i]);
                result = setString;
                mjson_string_free(setString);
                break;
            }
        }
    }
    mjson_free(setsData);
    return result;
}

void IVCustomSets::saveSet2(const QString& setJson)
{
    St2_FUNCT_St2(4876);
    saveOnServer2(setJson);
}

QString _savedSetId;
void IVCustomSets::saveOnServer2(const QString& setJsonString)
{
    St2_FUNCT_St2(455778);
    QJsonParseError parseError;
    QJsonDocument setDoc = QJsonDocument::fromJson(setJsonString.toUtf8(), &parseError);
    if (!setDoc.isObject()) {
        qDebug() << "SAVE SET ON SERVER ERROR PARSE SET:" << parseError.errorString();
        return;
    }
    QJsonObject setJson = setDoc.object();
    if (!setJson.contains("setId")) {
        qDebug() << "setId not found in input JSON";
        return;
    }

    bool isNewSet = true;
    auto localSetsFile = getFilePath(getSetsPath(), QStringLiteral("sets"));
    if (localSetsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray localData = localSetsFile.readAll();
        QJsonDocument localSetsDoc = QJsonDocument::fromJson(localData, &parseError);
        if (localSetsDoc.isArray()) {
            const auto setId = setJson["setId"].toString();
            _savedSetId = setId;
            const auto setsArray = localSetsDoc.array();
            for (const QJsonValue& item : setsArray) {
                if (item.isObject()) {
                    QJsonObject obj = item.toObject();
                    if (obj.contains("setId") && obj["setId"].toString() == setId) {
                        isNewSet = false;
                        break;
                    }
                }
            }
        }
    }

    if (isNewSet) {
        setJson.remove("setId");
    }

    if (setJson.contains("zones") && setJson["zones"].isArray()) {
        QJsonArray zonesArray = setJson["zones"].toArray();
        for (int i = 0; i < zonesArray.size(); ++i) {
            if (!zonesArray[i].isObject()) {
                continue;
            }
            QJsonObject zoneObj = zonesArray[i].toObject();
            if (!zoneObj.contains("type") || !zoneObj.contains("params")) {
                continue;
            }

            QString type = zoneObj["type"].toString();
            QJsonObject params = zoneObj["params"].toObject();

            QJsonObject newParams;
            newParams["key1"] = params["key1"];

            if (type == "camera") {
                if (params.contains("key2") && params["key2"].isObject()) {
                    QJsonObject key2Obj = params["key2"].toObject();
                    if (key2Obj.contains("value") && key2Obj["value"].isArray()) {
                        QJsonArray valueArr = key2Obj["value"].toArray();
                        if (!valueArr.isEmpty() && valueArr[0].isString()) {
                            newParams["key2"] = valueArr[0].toString();
                        }
                    }
                }
            } else if (type == "map") {
                if (params.contains("jsonDataFileName") && params["jsonDataFileName"].isObject()) {
                    QJsonObject jsonDataFileObj = params["jsonDataFileName"].toObject();
                    if (jsonDataFileObj.contains("value") && jsonDataFileObj["value"].isArray()) {
                        QJsonArray valueArr = jsonDataFileObj["value"].toArray();
                        if (!valueArr.isEmpty() && valueArr[0].isString()) {
                            newParams["key2"] = valueArr[0].toString();
                        }
                    }
                }
            }

            zoneObj["params"] = newParams;
            zonesArray[i] = zoneObj;
        }
        setJson["zones"] = zonesArray;
    }

    const QString modifiedSetJsonStr = QJsonDocument(setJson).toJson(QJsonDocument::Compact);
    QJsonObject jConfig;
    jConfig["cmd"] = "sets_api:save_set";
    jConfig["params"] = modifiedSetJsonStr;

    int timeout = 10;
    int is_local = 0;

    const auto cmdStr = QJsonDocument(jConfig).toJson(QJsonDocument::Compact);
    param_t p[] = {
        {PARAM_PCHAR, "cmd", cmdStr.data()},
        {PARAM_PINT32, "timeout", &timeout},
        {PARAM_PVOID, "owner", this},
        {PARAM_PVOID, "owner_data", set_added_on_server},
        {PARAM_PINT32, "is_local", &is_local},
        {0, 0, 0}
    };

    iv::core::profile_data(_onDataPr, p);
}

void IVCustomSets::deleteSet2(const QString& setId)
{
    St2_FUNCT_St2(62634);
    deleteOnServer2(setId);
}

QString _removedSetId;
void IVCustomSets::deleteOnServer2(const QString& setId)
{
    St2_FUNCT_St2(46778)
    _removedSetId = setId;
    /*
 {
    "method": "sets_api:del_set",
    "params": {
        "setId": "{b8f7041b-ca8c-43b0-8ee9-92dadd2661fa}"
    }
}
*/
    myajl_val params = mjson_parse1("{}");
    params->Add("setId", setId.toUtf8().data());

    myajl_val jConfig = mjson_parse1("{}");
    jConfig->Add("cmd","sets_api:del_set");
    jConfig->Add("params",params);

    char* cmd = mjson_generate1(jConfig);
    int timeout = 10;
    int is_local = 0;
    if (cmd) {
        param_t p[] =
        {
            {PARAM_PCHAR, "cmd", cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", this},
            {PARAM_PVOID, "owner_data", set_removed_on_server},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
        iv::core::profile_data(_onDataPr,p);
        mjson_string_free(cmd);
    }
    else {
        qDebug()<< "delete to server cmd error";
    }
    mjson_free(jConfig);
}

void IVCustomSets::updateSourcesReady(const QString& sourceType)
{
    if (sourceType == server_sets) {
        _setsUpdated = true;
    }
    else if (sourceType == customset_cams) {
        _camerasUpdated = true;
    }
    else if (sourceType == customset_sets_maps) {
        _mapsUpdated = true;
    }
    else if (sourceType == customset_fact_list) {
        _factListUpdated = true;
    }
    else if (sourceType == customset_groups_remote) {
        _customGroupsUpdated = true;
    }
    else if (sourceType == customset_groups_sets_remote) {
        _customGroupsSetsUpdated = true;
    }
    const auto isAllSourcesReady = _setsUpdated && _camerasUpdated && _mapsUpdated
                                   && _factListUpdated && _customGroupsUpdated && _customGroupsSetsUpdated;

    if (isAllSourcesReady) {
        _setsUpdated = false;
        _camerasUpdated = false;
        _mapsUpdated = false;
        _factListUpdated = false;
        _customGroupsUpdated = false;
        _customGroupsSetsUpdated = false;
        setSourcesReady(true);
    }
}

QFile IVCustomSets::getFilePath(const QString& pathToFolder, const QString& fileName) {
    QDir fileFolder(pathToFolder);
    if (!fileFolder.exists()) {
        fileFolder.mkpath(".");
    }
    return {fileFolder.absoluteFilePath(fileName)};
}

void IVCustomSets::save_server_sets(char* jsonString)
{
    St2_FUNCT_St2(45678);
    if (!jsonString) {
        return;
    }

    auto localSetsFile = getFilePath(getSetsPath(), QStringLiteral("sets"));
    if (localSetsFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        myajl_val json = mjson_parse(jsonString);
        if (!json || !(*json).IsArray() || (*json).size() <= 0) {
            mjson_free(json);
            return;
        }

        myajl_val setsObject = (*json)[0];
        if (setsObject == NULL || !(*setsObject).IsObject()) {
            return;
        }

        myajl_val setsJson = (*setsObject)("sets");
        if (setsJson == NULL || !(*setsJson).IsArray()) {
            return;
        }

        for (int setIndex = 0; setIndex < (*setsJson).GetNumElems(); setIndex++) {
            myajl_val setJson = (*setsJson)[setIndex];
            if (setJson == NULL) {
                continue;
            }

            myajl_val zonesJson = (*setJson)("zones");
            if (zonesJson == NULL || !(*zonesJson).IsArray()) {
                continue;
            }

            for (int zoneIndex = 0; zoneIndex < (*zonesJson).GetNumElems(); zoneIndex++) {
                myajl_val params = (*zonesJson)[zoneIndex]("params");
                if (params == NULL) {
                    continue;
                }

                QString type = static_cast<char*>((*zonesJson)[zoneIndex]("type"));
                char* key1 = (*params)("key1");
                char* key2 = (*params)("key2");

                if (QString(key2).endsWith(".json")) {
                    type = "map";
                }

                if (!key2 || !strcmp(key2, "null")) {
                    myajl_val emptyParams = mjson_parse("{}");
                    (*zonesJson)[zoneIndex]("params") = emptyParams;
                    (*zonesJson)[zoneIndex].Add("type","empty");
                    mjson_free(emptyParams);
                    continue;
                }

                if (type == "camera") {
                    myajl_val constParams = mjson_parse(camsParams);
                    if (constParams != NULL) {
                        (*constParams)("params").Add("key1",key1);
                        (*constParams)("params")("key2")("value")[0] = key2;
                        (*zonesJson)[zoneIndex]("params") = (*constParams)("params");
                    }
                }
                else if (type == "map") {
                    myajl_val constParams = mjson_parse(mapsParams);
                    if (constParams != NULL) {
                        (*constParams).Add("key1",key1);
                        (*constParams)("params")("jsonDataFileName")("value")[0] = key2;
                        (*zonesJson)[zoneIndex]("params") = (*constParams)("params");
                    }
                }
            }
        }

        char* tempStr = mjson_generate1(setsJson);
        //qDebug()<< "convert set = "<<tempStr;
        localSetsFile.write(tempStr);
        localSetsFile.close();
        mjson_string_free(tempStr);

        mjson_free(json);
    }
}

void IVCustomSets::save_cameras(char* json)
{
    St2_FUNCT_St2(45678);
    static const auto camerasFolderPath = QDir(QCoreApplication::applicationDirPath()).filePath("databases/new_sets/cameras");
    auto file = getFilePath(camerasFolderPath, QStringLiteral("cameras"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(json);
        file.close();
    }
}

void IVCustomSets::save_maps(char* json)
{
    St2_FUNCT_St2(45678);
    if (!json) {
        return;
    }
    static const auto mapsFolderPath = QDir(QCoreApplication::applicationDirPath()).filePath("databases/new_sets/maps");
    auto file = getFilePath(mapsFolderPath, QStringLiteral("maps"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(json);
        file.close();
    }
}

void IVCustomSets::save_fact_list(char* json)
{
    St2_FUNCT_St2(45678);
    if (!json) {
        return;
    }
    auto file = getFilePath(getOtherPath(), QStringLiteral("fact_list"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(json);
        file.close();
    }
}

void IVCustomSets::save_groups_list(char* jsonString)
{
    St2_FUNCT_St2(45678);
    auto file = getFilePath(getOtherPath(), QStringLiteral("groups_list"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (!jsonString) {
            file.write("[]");
            return;
        }
        myajl_val json = mjson_parse(jsonString);
        myajl_val groupsArray = mjson_parse("[]");
        if (json && (*json).IsArray()) {
            for (int i = 0; i < (*json).GetNumElems(); i++) {
                myajl_val rows = (*json)[i]("rows");
                if (rows && (*rows).IsArray()) {
                    for (int j = 0; j < (*rows).GetNumElems(); j++) {
                        char* groupName = (*rows)[j]("csgname");
                        char* groupId = (*rows)[j]("csgid");
                        char* groupParentId = (*rows)[j]("csgparentid");
                        char* groupColor = (*rows)[j]("csgcolor");

                        myajl_val customGroupObject = mjson_parse("{}");
                        (*customGroupObject).Add("groupName",groupName);
                        (*customGroupObject).Add("groupId",groupId);
                        (*customGroupObject).Add("groupParentId",groupParentId);
                        (*customGroupObject).Add("groupColor",groupColor);
                        (*groupsArray).Add(customGroupObject);
                    }
                }
            }
            char* tempStr = mjson_generate1(groupsArray);
            if(tempStr) {
                file.write(tempStr);
            }
            mjson_string_free(tempStr);
        }
        mjson_free(groupsArray);
    }
}

void IVCustomSets::save_groups_sets(char* jsonString)
{
    St2_FUNCT_St2(45678);
    auto file = getFilePath(getOtherPath(), QStringLiteral("groups_list_sets"));
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if(!jsonString) {
            file.write("[]");
            return;
        }

        myajl_val json = mjson_parse(jsonString);
        myajl_val groupsArray = mjson_parse("[]");
        if (json && (*json).IsArray()) {
            for(int i = 0; i < (*json).GetNumElems(); i++) {
                myajl_val rows = (*json)[i]("rows");
                if (rows && (*rows).IsArray()) {
                    for (int j = 0; j < (*rows).GetNumElems(); j++) {
                        char* groupId = (*rows)[j]("sgssetgroupid");
                        char* setId = (*rows)[j]("sgssetid");

                        myajl_val groupSetObject = mjson_parse("{}");
                        (*groupSetObject).Add("groupId",groupId);
                        (*groupSetObject).Add("sgssetid",setId);
                        (*groupsArray).Add(groupSetObject);
                    }
                }
            }
            char* tempStr = mjson_generate1(groupsArray);
            if (tempStr) {
                file.write(tempStr);
            }
            mjson_string_free(tempStr);
        }
        mjson_free(groupsArray);
    }
}

void IVCustomSets::server_sets_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(5465);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"server_sets_updater this is nullptr";
        return;
    }

    int timeout = 10;
    int is_local = 0;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", "{\"cmd\":\"sets_api:get_sets\",\"params\":{}}"},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data", only_sets_update},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p);
}

void IVCustomSets::general_server_sets_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(5465);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"server_sets_updater this is nullptr";
        return;
    }

    int timeout = 10;
    int is_local = 0;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", "{\"cmd\":\"sets_api:get_sets\",\"params\":{}}"},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data", server_sets},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p);
}

void IVCustomSets::general_cameras_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(556);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"cameras_updater this is nullptr";
        return;
    }
    constexpr auto cmd = "{\"cmd\":\"camera:list\",\"params\":{\"info\": true,\"profiles\": true,\"positions\":false,\"page\":1,\"page_size\":4000}}";
    int timeout = 10;
    int is_local = 0;
    param_t p2[] =
        {
            {PARAM_PCHAR, "cmd", cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data", customset_cams},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p2);
}
void IVCustomSets::general_maps_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(5565);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"maps_updater this is nullptr";
        return;
    }
    int timeout = 10;
    int is_local = 0;

    constexpr auto cmd = "{\"cmd\":\"config_api:dir_info\",\"params\":{\"folder\": \"databases/mapData\"}}";
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data",  customset_sets_maps},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p);
}
void IVCustomSets::general_fact_list_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(256);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"fact_list_updater this is nullptr";
        return;
    }
    int timeout = 10;
    int is_local = 0;
    constexpr auto cmd = "{\"cmd\":\"listener_pinger:get_down_servers\",\"params\":{\"server_ip\": \"string\",\"direct_access\": 1,\"version\":\"v1\"}}";
    param_t p2[] =
        {
            {PARAM_PCHAR, "cmd", cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data", customset_fact_list},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p2);
}
void IVCustomSets::general_custom_group_list_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(756);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"custom_group_list_updater this is nullptr";
        return;
    }
    myajl_val params = mjson_parse1("{}");
    params->Add("alias","conf");
    params->Add("table","camerasetgroup");
    params->Add("instruction","select");
    params->Add("conditions","[]");

    myajl_val jConfig = mjson_parse1("{}");
    jConfig->Add("cmd","config:db");
    jConfig->Add("params",params);
    char* cmd = mjson_generate1(jConfig);

    int timeout = 10;
    int is_local = 0;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data",  customset_groups_remote},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p);
    mjson_string_free(cmd);
    mjson_free(jConfig);
}
void IVCustomSets::general_custom_group_set_list_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(756);
    IVCustomSets* _this = (IVCustomSets*)udata;
    if (!_this) {
        qDebug()<<"custom_group_set_list_updater this is nullptr";
        return;
    }
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config:db");
    params->Add("alias","conf");
    params->Add("table","camerasetgroup2cameraset");
    params->Add("instruction","select");
    params->Add("conditions","[]");
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);

    int timeout = 10;
    int is_local = 0;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", _this},
            {PARAM_PVOID, "owner_data",  customset_groups_sets_remote},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_this->_onDataPr,p);
    mjson_string_free(_cmd);
    mjson_free(jConfig);
}

void IVCustomSets::onresult(const void* udata, const param_t* p)
{
    on_track_events(udata, p);
    St2_FUNCT_St2(23446);
    // IVCustomSets* _this = (IVCustomSets*)udata;
    // if (!_this) {
    //     return;
    // }
    int32_t code = 0;
    const char* user_msg = nullptr;
    void* owner = nullptr;
    void* owner_data = nullptr;
    char* json = nullptr;

    for (each_param(p)) {
        param_start;
        param_get_int32(code);
        param_get_pchar(user_msg);
        param_get_pchar(json);
        param_get_pvoid(owner);
        param_get_pvoid(owner_data);
    }

    St2(3546)
    if (owner != 0 && owner_data != 0) {
        if ((owner != udata) || (owner_data == nullptr)) {
            return;
        }

        St2(3526)
        if (json != 0 ) {
            St2(3522)
            if (code < 0) {
                return;
            }
            char* cmd_type = (char*)owner_data;

            if (!strcmp(cmd_type, server_sets)) {
                IVCustomSets::instance()->save_server_sets(json);
                IVCustomSets::instance()->updateSourcesReady(server_sets);
            }
            else if (!strcmp(cmd_type,customset_cams)) {
                IVCustomSets::instance()->save_cameras(json);
                IVCustomSets::instance()->updateSourcesReady(customset_cams);
            }
            else if (!strcmp(cmd_type,customset_sets_maps)) {
                IVCustomSets::instance()->save_maps(json);
                IVCustomSets::instance()->updateSourcesReady(customset_sets_maps);
            }
            else if (!strcmp(cmd_type,customset_fact_list)) {
                IVCustomSets::instance()->save_fact_list(json);
                IVCustomSets::instance()->updateSourcesReady(customset_fact_list);
            }
            else if (!strcmp(cmd_type,customset_groups_remote)) {
                IVCustomSets::instance()->save_groups_list(json);
                IVCustomSets::instance()->updateSourcesReady(customset_groups_remote);
            }
            else if (!strcmp(cmd_type,customset_groups_sets_remote)) {
                IVCustomSets::instance()->save_groups_sets(json);
                IVCustomSets::instance()->updateSourcesReady(customset_groups_sets_remote);
            }
            else if (!strcmp(cmd_type, set_added_on_server)) {
                myajl_val savedSetJson = mjson_parse(json);
                auto savedSet = (*savedSetJson)[0]("sets")[0];
                if (savedSet.IsObject()) {
                    const auto savedSetId = static_cast<char*>(savedSet("setId"));
                    const auto savedSetName = static_cast<char*>(savedSet("setName"));
                    emit IVCustomSets::instance()->newSetSavedWithId(_savedSetId, savedSetId, savedSetName);
                }
                iv::threads::pool::execute(only_sets_update, server_sets_updater, IVCustomSets::instance());
            }
            else if (!strcmp(cmd_type, set_removed_on_server)) {
                emit IVCustomSets::instance()->setRemoved(_removedSetId);
                iv::threads::pool::execute(only_sets_update, server_sets_updater, IVCustomSets::instance());
            }
            else if (!strcmp(cmd_type, only_sets_update)) {
                IVCustomSets::instance()->save_server_sets(json);
                emit IVCustomSets::instance()->setsUpdated();
            }
        }
    }
}

QString IVCustomSets::getZoneTypes()
{
    St2_FUNCT_St2(32512);
    QString _sepa(QDir::separator());
    QString pp = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"zone_types";
    QFile file(pp);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        // qDebug()<<"zone_types is not defined" << pp;
        return "[]";
    }
    //QTextStream in(&file);
    QString line;
    line = file.readAll();
    file.close();
    return line;
}

int IVCustomSets::deleteSet(QString setName)
{
    St2_FUNCT_St2(628734);
    QStringList localSets;
    QStringList remoteSets;
    //  qDebug()<<"DELETE SET SETNAME = " << setName;
    localSets = getLocalSetsList();
    remoteSets = getRemoteSetsList();
    QByteArray setNameBa = setName.toUtf8();
    char* oldSetName = setNameBa.data();
    // bool isSetFound = false;
    // foreach(QString set, localSets)
    // {
    //     if(set == setName)
    //     {
    // isSetFound = true;
    // }
    // }

    QString _sepa(QDir::separator());
    QString localPath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
    QDir localDir(localPath+_sepa);
    if(!localDir.exists(localPath))
    {
        localDir.mkpath(localPath);
    }
    localPath=localDir.absolutePath()+_sepa+"local_sets";
    QFile localSetsFile(localPath);
    if(localSetsFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        //        QTextStream in(&localSetsFile);
        //        in.setCodec("UTF-8");
        //        QString text;
        //        text = in.readAll();

        QByteArray ba = localSetsFile.readAll();
        char* data = ba.data();
        localSetsFile.close();
        myajl_val jConfig = 0;
        jConfig = mjson_parse1(data);
        //  qDebug()<<"DELETE SET LOCAL SET FILE OPENED = " << setName;
        if((*jConfig).IsArray())
        {
            int jSize = (*jConfig).GetNumElems();
            for(int i1 = 0;i1<jSize;i1++)
            {

                char* _setName = (*jConfig)[i1]("setName");
                if(!strcmp(_setName,oldSetName))
                {
                    //  qDebug()<<"DELETE SET LOCAL SET FOUND = " << _setName;
                    (*jConfig).Remove(i1);
                    char* newSets = mjson_generate1(jConfig);
                    //  qDebug()<<"DELETE SET LOCAL SET NEW = " << newSets;
                    if(localSetsFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
                    {
                        //                        QTextStream out(&localSetsFile);
                        //                        out.setCodec("UTF-8");
                        //                        out.setGenerateByteOrderMark(false);
                        //                        out << newSets;
                        localSetsFile.write(newSets);
                        saveOnServer(_currentUser,"local_sets","local_sets",newSets);
                        mjson_string_free(newSets);
                        localSetsFile.close();
                        break;
                    }
                    else
                    {
                        // QString errMsg = localSetsFile.errorString();
                        // qDebug()<< "deleteSet : File is not opened = " << errMsg ;
                    }
                }
            }
            mjson_free(jConfig);
        }
    }
    else
    {
        // QString errMsg = localSetsFile.errorString();
        // qDebug()<< "deleteSet : File is not opened = " << errMsg ;
    }
    return 0;
}

void IVCustomSets::saveSet( QString setName,QString newSetName, QString setJson)
{
    St2_FUNCT_St2(4276);
    QStringList localSets;
    QStringList remoteSets;

    localSets = getLocalSetsList();
    remoteSets = getRemoteSetsList();
    QByteArray setNameBa = setName.toUtf8();
    char* oldSetName = setNameBa.data();
    QByteArray setDataBa = setJson.toUtf8();
    char* setData = setDataBa.data();
    bool isSetFoundLocal = false;
    bool isSetFoundRemote = false;
    bool isNewSetNameFoundInSavedSets = false;
    if(newSetName.isEmpty())
    {
        newSetName = setName;
    }
    foreach(QString set, localSets)
    {
        if(set == newSetName)
        {
            isSetFoundLocal = true;
        }
    }
    foreach(QString set, remoteSets)
    {
        if(set == newSetName)
        {
            isSetFoundRemote = true;
        }
    }
    if(isSetFoundRemote)
    {
        if(setName == newSetName)
        {
            //qDebug()<<"NEW SET NAME IS FOUND IN REMOTE SETS, RENAME SET";
            return;
        }
    }
    if(isSetFoundLocal)
    {
        if(setName != newSetName)
        {
            //qDebug()<<"NEW SET NAME IS FOUND IN local SETS, RENAME SET";
            return;
        }
    }
    QString _sepa(QDir::separator());
    QString localPath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
    QDir localDir(localPath+_sepa);

    if(!localDir.exists(localPath))
    {
        localDir.mkpath(localPath);
    }
    localPath = localDir.absolutePath()+_sepa+"local_sets";
    // qDebug()<<"SAVE SET PATH ="<<localPath;
    QFile localSetsFile(localPath);
    if(localSetsFile.open(QIODevice::ReadWrite | QIODevice::Text))
    {
        //qDebug()<<"SAVE SET FILE OPENED";
        //        QTextStream in(&localSetsFile);
        //        in.setCodec("UTF-8");
        //        QString text;
        // text = localSetsFile.readAll();
        QByteArray ba = localSetsFile.readAll();
        localSetsFile.close();
        char* data = ba.data();
        myajl_val jConfig = 0;
        jConfig = mjson_parse1(data);
        St2(56547);
        if((*jConfig).IsEmpty())
        {
            char* awdawdd = mjson_generate1(jConfig);
            //qDebug()<< "ПОЧЕМУ ТО ПУСТОЙ JSON" << awdawdd;
            mjson_string_free(awdawdd);
            mjson_free(jConfig);

            jConfig = mjson_parse1("[]");
        }
        St2(56546);
        if(!(*jConfig).IsArray())
        {
            mjson_free(jConfig);
            jConfig = mjson_parse1("[]");
        }
        if((*jConfig).IsArray())
        {

            int jSize = (*jConfig).GetNumElems();
            bool isSetFound = false;
            myajl_val setNewData = 0;
            setNewData = mjson_parse1(setData);
            //qDebug()<<"NEW SET DATA = "<<setData;
            St2(56545);
            for(int i1 = 0;i1<jSize;i1++)
            {

                char* _setName = (*jConfig)[i1]("setName");
                if(!strcmp(_setName,oldSetName))
                {
                    isSetFound = true;
                    (*jConfig).Remove(i1);
                    (*jConfig).Add(setNewData);
                    St2(56544);
                    char* newSets = mjson_generate1(jConfig);
                    // qDebug()<<"NEW SET DATA2 = "<<newSets;

                    if(localSetsFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
                    {
                        //                        QTextStream out(&localSetsFile);
                        //                        out.setCodec("UTF-8");
                        //out.setGenerateByteOrderMark(false);
                        //out << newSets;
                        saveOnServer(_currentUser,"local_sets","local_sets",newSets);
                        localSetsFile.write(newSets);
                        mjson_string_free(newSets);
                        localSetsFile.close();
                        break;
                    }
                    else
                    {
                        // qDebug()<<"FILE local_sets not opened===================";
                    }
                }
            }
            if(!isSetFound)
            {
                St2(56543);
                if(localSetsFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
                {
                    (*jConfig).Add(setNewData);
                    //(*jConfig).Add()
                    char* newSets = mjson_generate1(jConfig);
                    //                    QTextStream out(&localSetsFile);
                    //                    out.setCodec("UTF-8");
                    //                    out.setGenerateByteOrderMark(false);
                    //                    out << newSets;
                    saveOnServer(_currentUser,"local_sets","local_sets",newSets);
                    localSetsFile.write(newSets);
                    mjson_string_free(newSets);
                    localSetsFile.close();
                }
            }
        }
        else
        {
            //qDebug()<<"JSON IS NOT ARRAY";
        }
        mjson_free(jConfig);
    }
    else
    {
        // QString errMsg = localSetsFile.errorString();
        // qDebug()<< "saveSet : File is not opened = " << errMsg ;
    }
}

void IVCustomSets::saveOnServer(QString user, QString folder, QString fileName, QString data)
{
    St2_FUNCT_St2(455778);
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config_api:export_settings");

    QByteArray userBa = _currentUser.toUtf8();
    char* _user = userBa.data();
    QByteArray folderBa = folder.toUtf8();
    char* _folder = folderBa.data();
    QByteArray fileNameBa = fileName.toUtf8();
    char* _fileName = fileNameBa.data();
    QByteArray dataBa = data.toUtf8();
    char* _data = dataBa.data();
    params->Add("folder",_folder);
    params->Add("filename",_fileName);
    params->Add("user",_user);
    params->Add("json",_data);
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);


    //QString cmd__ = "{\"cmd\":\"config_api:export_settings\",\"params\":{\"filename\": \""+fileName+"\",\"folder\": \""+folder+"\",\"user\": \""+user+"\",\"json\":\""+data+"\"}}";
    int timeout = 10;
    int is_local = 0;
    //    QByteArray b1 = cmd__.toUtf8();
    //    char* _cmd = b1.data();
    //  qDebug()<<"cmd = "<< _cmd;
    if(_cmd)
    {
        param_t p[] =
            {
                {PARAM_PCHAR, "cmd", _cmd},
                {PARAM_PINT32,"timeout", &timeout},
                {PARAM_PVOID, "owner", this},
                {PARAM_PVOID, "owner_data",  this},
                {PARAM_PINT32,"is_local",&is_local},
                {0, 0, 0}
            };
        iv::core::profile_data(_onDataPr,p);
        mjson_string_free(_cmd);
    }
    else
    {
        // qDebug()<< "save to server cmd error";
    }
    mjson_free(jConfig);
}

QStringList IVCustomSets::getLocalSetsList()
{
    St2_FUNCT_St2(3221);
    QStringList resutl;
    QString _sepa(QDir::separator());
    QString localPath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
    QDir localDir(localPath+_sepa);
    if(!localDir.exists(localPath))
    {
        localDir.mkpath(localPath);
    }
    localPath+=_sepa+"local_sets";
    QFile localSetsFile(localPath);

    if (localSetsFile.open(QIODevice::ReadWrite | QIODevice::Text))
    {
        // QTextStream in(&localSetsFile);
        // in.setCodec("UTF-8");
        // QString text;
        // text = localSetsFile.readAll();
        QByteArray ba = localSetsFile.readAll();
        char* data = ba.data();
        myajl_val jConfig = 0;
        localSetsFile.close();
        jConfig = mjson_parse1(data);
        if((*jConfig).IsArray())
        {
            int jSize = (*jConfig).GetNumElems();
            for(int i = 0;i<jSize;i++)
            {

                char* _setName = (*jConfig)[i]("setName");
                resutl.append(_setName);
            }
        }
        mjson_free(jConfig);
    }
    else
    {
        // QString errMsg = localSetsFile.errorString();
        // qDebug()<< "getLocalSetsList : File is not opened = " << errMsg ;
    }


    return resutl;
}

QStringList IVCustomSets::getRemoteSetsList()
{
    St2_FUNCT_St2(32287);

    QStringList resutl;
    QString _sepa(QDir::separator());
    QString remotePath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"remote_sets";
    QDir remoteDir(remotePath+_sepa);
    if(!remoteDir.exists(remotePath))
    {
        remoteDir.mkpath(remotePath);
    }
    remotePath+=_sepa+"remote_sets";
    QFile remoteSetsFile(remotePath);

    if(remoteSetsFile.open(QIODevice::ReadWrite | QIODevice::Text))
    {
        //        QTextStream in(&remoteSetsFile);
        //        in.setCodec("UTF-8");
        //        QString text;
        //        text = in.readAll();
        QByteArray ba = remoteSetsFile.readAll();
        char* data = ba.data();
        myajl_val jConfig = 0;
        jConfig = mjson_parse1(data);
        if((*jConfig).IsArray())
        {
            int jSize = (*jConfig).GetNumElems();
            for(int i = 0;i<jSize;i++)
            {

                char* _setName = (*jConfig)[i]("setName");
                resutl.append(_setName);
            }
        }
        mjson_free(jConfig);
    }
    else
    {
        // QString errMsg = remoteSetsFile.errorString();
        // qDebug()<< "getLocalSetsList : File is not opened = " << errMsg ;
    }
    return resutl;
}

QString IVCustomSets::getZone(QString setName)
{
    St2_FUNCT_St2(3243);
    QString result = "{}";

    QString temp = getZonesLocal(setName);
    if(temp.isEmpty())
    {
        temp = getZonesRemote(setName);
    }
    if(!temp.isEmpty())
    {
        result = temp;
    }
    return result;
}

QString IVCustomSets::getZonesRemote(QString setName)
{
    St2_FUNCT_St2(3279);
    QString result;
    QString _sepa(QDir::separator());
    QString remotePath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"remote_sets";
    QDir remoteDir(remotePath+_sepa);
    if(!remoteDir.exists(remotePath))
    {
        remoteDir.mkpath(remotePath);
    }
    remotePath=remoteDir.absolutePath()+_sepa+"remote_sets";
    QFile remoteSetFile(remotePath);

    if (!remoteSetFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        // qDebug()<<"getZonesRemote error open file " << remotePath;
        return "{}";
    }
    //    QTextStream in(&remoteSetFile);
    //    in.setCodec("UTF-8");
    //    QString text;
    //    text = in.readAll();
    QByteArray ba = remoteSetFile.readAll();
    char* data = ba.data();
    myajl_val setsData = 0;
    setsData = mjson_parse1(data);
    remoteSetFile.close();
    if((*setsData).IsArray())
    {
        int jSize = (*setsData).GetNumElems();
        for(int i = 0;i<jSize;i++)
        {

            char* _setName = (*setsData)[i]("setName");
            QByteArray setNameBa = setName.toUtf8();
            char* setNameC = setNameBa.data();
            if(!strcmp(setNameC,_setName))
            {
                char* setString = mjson_generate1((*setsData)[i]);
                result = setString;
                mjson_string_free(setString);
            }
        }
    }
    mjson_free(setsData);

    return result;
}

QString IVCustomSets::getZonesLocal(QString setName)
{
    St2_FUNCT_St2(3278);
    QString result;
    QString _sepa(QDir::separator());
    QString localPath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
    QDir localDir(localPath+_sepa);
    if(!localDir.exists(localPath))
    {
        localDir.mkpath(localPath);
    }
    localPath=localDir.absolutePath()+_sepa+"local_sets";
    QFile localSetFile(localPath);

    if (!localSetFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        //  qDebug()<<"getZonesLocal error open file " << localPath;
        return "{}";
    }
    //    QTextStream in(&localSetFile);
    //    in.setCodec("UTF-8");
    //    QString text;
    //    St2(34578)
    //    text = in.readAll();
    QByteArray ba = localSetFile.readAll();
    char* data = ba.data();
    myajl_val setsData = 0;
    localSetFile.close();
    setsData = mjson_parse1(data);
    St2(34278);
    if((*setsData).IsArray())
    {
        int jSize = (*setsData).GetNumElems();
        St2(34538)
            for(int i = 0;i<jSize;i++)
        {

            myajl_val _setName = (*setsData)[i]("setName");
            char* __setN = _setName->GetSafeString();
            // qDebug()<<"get local zones setname = " << setName << __setN;
            QByteArray setNameBa = setName.toUtf8();
            char* setNameC = setNameBa.data();
            if(!strcmp(setNameC,__setN))
            {
                // qDebug()<<"get local zones setname2 = " << setName;
                char* setString = mjson_generate1((*setsData)[i]);
                result = setString;
                mjson_string_free(setString);
                //  qDebug()<<"get local zones setname3 = " << setName;
            }
            // qDebug()<<"get local zones setname4 = " << setName;
        }
    }
    St2(14578)
        mjson_free(setsData);
    return result;
}

QVariantList IVCustomSets::getSetsList()
{
    St2_FUNCT_St2(76287);

    QVariantList result;
    QString _sepa(QDir::separator());
    QString remotePath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"sets";
    QDir remoteDir(remotePath+_sepa);
    if(!remoteDir.exists(remotePath))
    {
        remoteDir.mkpath(remotePath);
    }
    remotePath+=_sepa+"sets";
    QFile remoteSetsFile(remotePath);

    if(remoteSetsFile.open(QIODevice::ReadWrite | QIODevice::Text))
    {
        QByteArray ba = remoteSetsFile.readAll();
        char* data = ba.data();
        myajl_val jConfig = 0;
        jConfig = mjson_parse1(data);
        if((*jConfig).IsArray())
        {
            int jSize = (*jConfig).GetNumElems();
            for(int i = 0;i<jSize;i++)
            {

                char* _setName = (*jConfig)[i]("setName");
                char* _setId = (*jConfig)[i]("setId");
                int _isUser = (*jConfig)[i]("isuser");
                QJsonObject set;
                set["setName"] = _setName;
                set["setId"] = _setId;
                set["isuser"] = _isUser;
                result.append(set);
            }
        }
        mjson_free(jConfig);
    }
    else
    {
        // QString errMsg = remoteSetsFile.errorString();
        // qDebug()<< "getSetsList : File is not opened = " << errMsg ;
    }
    return result;
}

QString IVCustomSets::getCameras()
{
    St2_FUNCT_St2(32265);
    QString _result = "[]";
    QString _sepa(QDir::separator());
    QString camerasPath = QCoreApplication::applicationDirPath() + _sepa+"databases"+_sepa+"new_sets"+_sepa+"cams"+_sepa+"cameras";
    QFile camerasFile(camerasPath);
    if (camerasFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        //        QTextStream in(&camerasFile);
        //        in.setCodec("UTF-8");
        //        in.setGenerateByteOrderMark(false);
        _result = camerasFile.readAll();
        if(_result.isEmpty())
        {
            _result = "[]";
        }
        camerasFile.close();
    }
    else
    {
        // QString errMsg = camerasFile.errorString();
        // qDebug()<< "getLocalSetsList : File is not opened = " << errMsg ;
    }
    return _result;
}
