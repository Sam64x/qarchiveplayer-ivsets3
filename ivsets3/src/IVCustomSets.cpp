#include "IVCustomSets.h"

const char* camsParams1 = "{\"type\":\"camera\",\"qml_path\":\"qtplugins/iv/viewers/viewer/IVViewer.qml\",\"params\":{\"key2\":{\"type\":\"var\",\"value\":[\"\"]},\"running\":{\"type\":\"var\",\"value\":[true]}}}";
const char* mapsParams1 ="{"
                        " \"type\":\"MapViewer\","
                        " \"qml_path\":\"qtplugins/iv/mapviewer/QMapViewer.qml\","
                        " \"params\": {\"jsonDataFileName\":{\"type\":\"var\",\"value\":[\"\"]}}"
                        "}";



void IVCustomSets::getIps()
{
    St2_FUNCT_St2(5688);
    QString dirPath =  QCoreApplication::applicationDirPath();
    QFile file( dirPath+"/client_settings.json");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&file);
        QString line ="";
        while (!in.atEnd()) {
           line.append( in.readLine());
        }
        QByteArray ba = line.toUtf8();
        char* myconf =ba.data();
       // qDebug()<<"act server line = " << line;
        myajl_val jConfig = 0;
        jConfig = mjson_parse(myconf);
        myajl_val res_servers=0;
        myajl_val cs_servers=0;
        if((*jConfig).IsObject())
        {
           //  qDebug()<<"act server line2 = " << line;
            res_servers = (*jConfig)("reserved_servers");
            cs_servers = (*jConfig)("servers");
            if(cs_servers)
            {
                int jSize = (*cs_servers).GetNumElems();
                St2(2457);
                myajl_val ipsss = 0;
                if(jSize>0)
                {
                    ipsss=   (*cs_servers)[0];
                    if(ipsss)
                    {
                        _csServer = (*ipsss)("ip").GetString();
                    }
                }
            }
//            if(res_servers)
//            {
//                // qDebug()<<"act server line = 3" << line;
//                int jSize = (*res_servers).GetNumElems();
//                St2(2457);
//                myajl_val ipsss = 0;
//                for(int i = 0;i<jSize;i++)
//                {
//                    ipsss=   (*res_servers)[i];
//                    if(ipsss)
//                    {
//                        // qDebug()<<"act server line = 4" << line;
//                        //_activeServer = ips;
//                        _ipList.push_back((*ipsss)("ip").GetString());
//                    }
//                }
//            }
        }
        mjson_free(jConfig);
    }
    else
    {
       // qDebug()<<"SEMANTICA FILE NOT OPENED!!!-----------------------------------------------------------------------------";
    }

   // _ipList
}
IVCustomSets::IVCustomSets(QObject* parent)
{
    St2_FUNCT_St2(23544);
     Q_UNUSED(parent);
    _appPath = QCoreApplication::applicationDirPath();
    getIps();
    _onDataPr = 0;
    _ipProfile = 0;
    _camsUpdateProfile = 0;
    if(!_camsUpdateProfile)
    {
        iv::core::profile_open(_camsUpdateProfile,"needCamsUpdate",0,__FILE__, __LINE__);
    }
    isNeedWs = false;
    zu = 0;
}
IVCustomSets::~IVCustomSets()
{
//    profile_t _onDataPr;
//    profile_t _ipProfile;
//    profile_t _onResultPr;

    if(zu)iv::tasks::noncritical::remove(zu);
    zu = 0;

    if(_camsUpdateProfile)
    {
        iv::core::profile_close(_camsUpdateProfile);
        _camsUpdateProfile = 0;
    }
    if(_onDataPr)
    {
        iv::core::profile_close(_onDataPr);
        _onDataPr = 0;
    }
    if(_ipProfile)
    {
        iv::core::profile_close(_ipProfile);
        _ipProfile = 0;
    }


}
void IVCustomSets::oncmd(const void* udata, const param_t* p)
{
     St2_FUNCT_St2(35206)
    int32_t code = 0;
    const char* user_msg = nullptr;
    char* _this = (char*)udata;
   // qDebug()<<"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq JSON1 = " ;
//    if(!strcmp(_this,"35"))
//    {
//        qDebug()<<"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 35";
//    }
//    else
//    {
//        return;
//    }
   // qDebug()<<"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq JSON2 = " ;
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

    if ((owner != udata) || (owner_data == nullptr))
        return;
   // qDebug()<<"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq JSON3 = " ;
    if (json != 0)
    {
       // qDebug()<<"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq JSON = " << json;
    }
}

void IVCustomSets::events_updater_thousand(void *thread, void *udata)
{
    St2_FUNCT_St2(5230);
    Q_UNUSED(thread);
    IVCustomSets* _ivEvtReserver = (IVCustomSets*)udata;
    if(_ivEvtReserver)
    {
        _ivEvtReserver->getEvents();
    }
}
void IVCustomSets::initMap()
{
    getMapsFromFile();
    if(!zu)
        zu=iv::tasks::noncritical::add2("events_updater",events_updater_thousand,this,5000,1);

    //qDebug()<<"eventMapChanged";
    //emit eventMapChanged("План 5.json","cam_11.49");
}

void IVCustomSets::deinitMap()
{
    if(zu)iv::tasks::noncritical::remove(zu);
    zu = 0;
    lastEventTime = "";

}

void IVCustomSets::getMapsFromFile()
{
    QDir newSetsDir;
    if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
    newSetsDir.cd("databases");
    QFile file(QString(newSetsDir.absolutePath() + QDir::separator() + "maps_analogy"));
    file.open(QFile::ReadOnly);
   // qDebug()<< "Open file:"<< file.fileName();
    QJsonArray groupsArr = QJsonDocument::fromJson(file.readAll()).array();
    file.close();

    for (auto i : groupsArr)
    {
        QJsonObject obj = i.toObject();
        QString _mapName = obj.value("mapName").toString();
        QVariant _key2s =obj.value("key2").toVariant();
        _mapsAnalogy[_mapName] = _key2s;
    }

}
QString IVCustomSets::getSetPreset(QString presetNumber)
{
    St2_FUNCT_St2(45983);
    QString result = "";
    return result;

}
QJsonObject IVCustomSets::getTypePreset(QString type, QString propertyName, QString propertyType, QVariant value)
{
    St2_FUNCT_St2(45983);
    QJsonObject result;
    QString _sepa(QDir::separator());
    QString remotePath = _appPath + _sepa+"databases";
    QDir remoteDir(remotePath+_sepa);
    remotePath=remoteDir.absolutePath()+_sepa+"zone_types";
    QFile typePresetFile(remotePath);
    QByteArray typeBa = type.toUtf8();
    char* _type = typeBa.data();
    QByteArray propNameBa = type.toUtf8();
    char* _propName = propNameBa.data();
    QByteArray valueBa = type.toUtf8();
    char* _value = valueBa.data();

    if (typePresetFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {

//        QTextStream in(&typePresetFile);
//        in.setCodec("UTF-8");
//        QString text;
//        text = in.readAll();
        QByteArray ba = typePresetFile.readAll();
        char* data = ba.data();
        myajl_val setsData = 0;
        setsData = mjson_parse1(data);
        bool isPresetFound = false;
        if((*setsData).IsArray())
        {
            int jSize = (*setsData).GetNumElems();
            for(int i = 0;i<jSize;i++)
            {
                char* typePreset = (*setsData)[i]("type");
                if(!strcmp(typePreset,"camera"))
                {
                    if(!strcmp(_type,"camera"))
                    {
                        isPresetFound = true;
                        myajl_val preset = (*setsData)[i];
                        myajl_val presetValue = 0;
                        if(!propertyName.isEmpty())
                        {
                            presetValue = (*preset)("params")("key2")("value");
                            QString qvalue = value.toString();
                            QByteArray valueBa = qvalue.toUtf8();
                            char* _value = valueBa.data();
                            (*presetValue)[0]=_value;
                        }

                        char* presetStr = mjson_generate1(preset);
                       // qDebug()<<"PRESET Camera= "<<presetStr;
                        QJsonDocument doc = QJsonDocument::fromJson(presetStr);
                        result = doc.object();
                        mjson_string_free(presetStr);
                    }
                }
                if(!strcmp(typePreset,"MapViewer"))
                {
                    if(!strcmp(_type,"map"))
                    {
                        isPresetFound = true;
                        myajl_val preset = (*setsData)[i];
                        myajl_val presetValue = 0;
                        if(!propertyName.isEmpty())
                        {
                            presetValue = (*preset)("params")("jsonDataFileName")("value");
                            QString qvalue = value.toString();
                            QByteArray valueBa = qvalue.toUtf8();
                            char* _value = valueBa.data();
                            (*presetValue)[0]=_value;
                        }

                        char* presetStr = mjson_generate1(preset);
                      //  qDebug()<<"PRESET MapViewer= "<<presetStr;
                        QJsonDocument doc = QJsonDocument::fromJson(presetStr);
                        result = doc.object();
                        mjson_string_free(presetStr);
                    }
                }
                if(!strcmp(typePreset,"client_settings"))
                {
                    if(!strcmp(_type,"client_settings"))
                    {
                        isPresetFound = true;
                        myajl_val preset = (*setsData)[i];
                        myajl_val presetValue = 0;
                        char* presetStr = mjson_generate1(preset);
                      //  qDebug()<<"PRESET MapViewer= "<<presetStr;
                        QJsonDocument doc = QJsonDocument::fromJson(presetStr);
                        result = doc.object();
                        mjson_string_free(presetStr);
                    }
                }
            }
        }
        mjson_free(setsData);
    }
    else
    {
        QString errMsg = typePresetFile.errorString();
        // qDebug()<< "getTypePreset : File is not opened = " << errMsg ;
    }


    return result;

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
    bool isSetFound = false;
    foreach(QString set, localSets)
    {
        if(set == setName)
        {
            isSetFound = true;
        }
    }

    QString _sepa(QDir::separator());
    QString localPath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
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
                        QString errMsg = localSetsFile.errorString();
                        // qDebug()<< "deleteSet : File is not opened = " << errMsg ;
                    }
                }
            }
            mjson_free(jConfig);
        }
    }
    else
    {
        QString errMsg = localSetsFile.errorString();
        // qDebug()<< "deleteSet : File is not opened = " << errMsg ;
    }
    return 0;
}
int IVCustomSets::deleteSet2(QString setName, QString setId)
{
    St2_FUNCT_St2(62634);
    QStringList commonSets;
    QString result;
    QString _sepa(QDir::separator());
    QString remotePath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"sets";
    QDir remoteDir(remotePath+_sepa);
    if(!remoteDir.exists(remotePath))
    {
        remoteDir.mkpath(remotePath);
    }
    remotePath=remoteDir.absolutePath()+_sepa+"sets";
    QFile remoteSetFile(remotePath);

    QByteArray setNameBa = setName.toUtf8();
    char* oldSetName = setNameBa.data();
    QByteArray setIdBa = setId.toUtf8();
    char* setIdc = setIdBa.data();
    bool isSetFound = false;
    if(remoteSetFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
//        QTextStream in(&localSetsFile);
//        in.setCodec("UTF-8");
//        QString text;
//        text = in.readAll();

        QByteArray ba = remoteSetFile.readAll();
        char* data = ba.data();
        remoteSetFile.close();
        myajl_val jConfig = 0;
        jConfig = mjson_parse1(data);
        //qDebug()<<"DELETE SET LOCAL SET FILE OPENED = " << setName;
        if((*jConfig).IsArray())
        {
            int jSize = (*jConfig).GetNumElems();
            for(int i1 = 0;i1<jSize;i1++)
            {

                char* _setName = (*jConfig)[i1]("setName");
                char* _setId = (*jConfig)[i1]("setId");
                if(!strcmp(_setName,oldSetName) && !strcmp(_setId,setIdc))
                {
                    //qDebug()<<"DELETE SET LOCAL SET FOUND = " << _setName;
                    (*jConfig).Remove(i1);
                    char* newSets = mjson_generate1(jConfig);
                  //  qDebug()<<"DELETE SET LOCAL SET NEW = " << newSets;
                    if(remoteSetFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
                    {
//                        QTextStream out(&localSetsFile);
//                        out.setCodec("UTF-8");
//                        out.setGenerateByteOrderMark(false);
//                        out << newSets;
                        remoteSetFile.write(newSets);
                        deleteOnServer2(setId);
                        mjson_string_free(newSets);
                        remoteSetFile.close();
                        break;
                    }
                    else
                    {
                        QString errMsg = remoteSetFile.errorString();
                        // qDebug()<< "deleteSet : File is not opened = " << errMsg ;
                    }
                }
            }
            mjson_free(jConfig);
        }
    }
    else
    {
        QString errMsg = remoteSetFile.errorString();
        // qDebug()<< "deleteSet : File is not opened = " << errMsg ;
    }
    return 0;
}
QString IVCustomSets::getZoneTypes()
{
    St2_FUNCT_St2(32512);
    QString _sepa(QDir::separator());
    QString pp = _appPath + _sepa+"databases"+_sepa+"zone_types";
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
QString IVCustomSets::getZonesLocal(QString setName)
{
    St2_FUNCT_St2(3278);
    QString result;
    QString _sepa(QDir::separator());
    QString localPath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
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
QString IVCustomSets::getZonesRemote(QString setName)
{
    St2_FUNCT_St2(3279);
    QString result;
    QString _sepa(QDir::separator());
    QString remotePath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"remote_sets";
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
QString IVCustomSets::getZonesCommon(QString setName,QString setId)
{
    St2_FUNCT_St2(3787);
    QString result;
    QString _sepa(QDir::separator());
    QString remotePath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"sets";
    QDir remoteDir(remotePath+_sepa);
    if(!remoteDir.exists(remotePath))
    {
        remoteDir.mkpath(remotePath);
    }
    remotePath=remoteDir.absolutePath()+_sepa+"sets";
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
        bool isFromIdFound = false;
        for(int i = 0;i<jSize;i++)
        {

            char* _setName = (*setsData)[i]("setName");
            char* _setId = (*setsData)[i]("setId");
            //qDebug()<<"getZonesCommon  " << _setName << _setId;
            QByteArray setNameBa = setName.toUtf8();
            char* setNameC = setNameBa.data();
            QByteArray setIdBa = setId.toUtf8();
            char* setIdC = setIdBa.data();
            if(!strcmp(setNameC,_setName) && !strcmp(setIdC,_setId))
            {
                //qDebug()<<"getZonesCommon FOUUUUUUUND  " << _setName << _setId;
                char* setString = mjson_generate1((*setsData)[i]);
                // qDebug()<<"getZonesCommon FOUUUUUUUND2222  " << setString;
                result = setString;
                mjson_string_free(setString);
                isFromIdFound = true;
                break;
            }
        }
        if(!isFromIdFound)
        {
            for(int i = 0;i<jSize;i++)
            {

                char* _setName = (*setsData)[i]("setName");
                QByteArray setNameBa = setName.toUtf8();
                char* setNameC = setNameBa.data();
                QByteArray setIdBa = setId.toUtf8();
                char* setIdC = setIdBa.data();
                if(!strcmp(setNameC,_setName) )
                {
                   // qDebug()<<"getZonesCommon FOUUUUUUUND  " << _setName ;
                    char* setString = mjson_generate1((*setsData)[i]);
                   //  qDebug()<<"getZonesCommon FOUUUUUUUND2222  " << setString;
                    result = setString;
                    mjson_string_free(setString);
                    isFromIdFound = true;
                    break;
                }
            }
        }
    }
    mjson_free(setsData);
    //qDebug()<<"getZonesCommon RETURN " <<result;
    return result;
}
QString IVCustomSets::getZone2(QString setName,QString setId)
{
    St2_FUNCT_St2(3243);
    QString result = "{}";
    //qDebug()<< "getZone2" << setName << setId;
    result = getZonesCommon(setName,setId);

    return result;
}
QString IVCustomSets::getZone(QString setName,bool isLocal)
{
    St2_FUNCT_St2(3232);
    QString result = "{}";
    QString temp;
    if(isLocal)
    {
        temp = getZonesLocal(setName);
    }
    else
    {
        temp = getZonesRemote(setName);
    }
    if(!temp.isEmpty())
    {
        result = temp;
    }
    return result;
}
QString IVCustomSets::getMapsList()
{
    St2_FUNCT_St2(322);

    QString _sepa(QDir::separator());
    QString pp = _appPath + _sepa+"databases"+_sepa+"mapData";
    QDir dd(_appPath + _sepa+"databases"+_sepa+"mapData"+_sepa);
   // qDebug()<<"sepa = " <<_sepa;
   // qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    QStringList files = dd.entryList(QDir::Files);
    QString _retData = "[";
   // qDebug()<<"list sets size"<<files.size();
    myajl_val myajl_item = mjson_parse1("[]");
    foreach(QString filename, files) {
      //  qDebug()<<filename;
        QByteArray ba = filename.toUtf8();
        char* data = ba.data();

       myajl_item->Add(data);
    }
    char* _data = mjson_generate1(myajl_item);
    QString data = _data;
   // qDebug()<<"get maps list = "<<data;
    mjson_string_free(_data);
    mjson_free(myajl_item);
    return data;
}

void IVCustomSets::on_track_events(const void* udata, const param_t* p)
{
    IVCustomSets* _this = (IVCustomSets*)udata;
    if(!_this)
        return;
    St2_FUNCT_St2(1446);
    //qDebug()<< "on_track_events";
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

    St2(9046)
    if(owner != 0 && owner ==udata && owner_data != 0)
    {

//qDebug()<< "on_track_events222" << json << method ;
        St2(2326)
        if (json != 0 )
        {
            St2(3522);
            //qDebug()<<"AAAAAAA" << json;
            myajl_val _json = mjson_parse(json);
            if(_json)
            {
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
                                foreach (QString key, _this->_mapsAnalogy.keys())
                                {
                                    //qDebug()<< "FOUND IN" << key;
                                    QVariant _values = _this->_mapsAnalogy.value(key);
                                    QJsonArray camsArray = _values.toJsonArray();
                                    //qDebug()<< "FOUND IN SIZE" << camsArray.size();
                                    for(auto i2:camsArray)
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
                                            _this->lastEventTime = evtTime;
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
    QDateTime dt2 = QDateTime::currentDateTime();
    int tt =  dt2.utcOffset()/3600;

    if(lastEventTime.isEmpty())
    {
        //time.setTimeSpec(Qt::UTC);
        QString localTime = QDateTime::currentDateTimeUtc().toString("yyyy-MM-dd hh:mm:ss.zzz");
        lastEventTime = localTime;
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
    "\"val\":\""+lastEventTime+"\"\n"
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
QString IVCustomSets::getCurrentUser()
{
    return _currentUser;
}
void IVCustomSets::setCurrentUser(QString val)
{
   // qDebug()<< "setCurrentUser1" << _currentUser << val << this;
    if (_currentUser != val)
    {
        _currentUser = val;
       // qDebug()<< "setCurrentUser2" << _currentUser << val << this;
        emit currentUserChanged(_currentUser);
    }
}
QStringList IVCustomSets::getLocalSetsList()
{
    St2_FUNCT_St2(3221);
    QStringList resutl;
    QString _sepa(QDir::separator());
    QString localPath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
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
        QString errMsg = localSetsFile.errorString();
        // qDebug()<< "getLocalSetsList : File is not opened = " << errMsg ;
    }


    return resutl;
}
QStringList IVCustomSets::getRemoteSetsList()
{
    St2_FUNCT_St2(32287);

    QStringList resutl;
    QString _sepa(QDir::separator());
    QString remotePath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"remote_sets";
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
        QString errMsg = remoteSetsFile.errorString();
        // qDebug()<< "getLocalSetsList : File is not opened = " << errMsg ;
    }
    return resutl;
}
QVariantList IVCustomSets::getSetsList()
{
    St2_FUNCT_St2(76287);

    QVariantList result;
    QString _sepa(QDir::separator());
    QString remotePath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"sets";
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
        QString errMsg = remoteSetsFile.errorString();
        // qDebug()<< "getSetsList : File is not opened = " << errMsg ;
    }
    return result;
}
QString IVCustomSets::getCameras()
{
    St2_FUNCT_St2(32265);
    QString _result = "[]";
    QString _sepa(QDir::separator());
    QString camerasPath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"cams"+_sepa+"cameras";
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
        QString errMsg = camerasFile.errorString();
        // qDebug()<< "getLocalSetsList : File is not opened = " << errMsg ;
    }
    return _result;
}
QVariantList IVCustomSets::getBindingCameras(QString key2)
{
    St2_FUNCT_St2(32265);
    QVariantList _result;
    if(bindingCamsArr.empty())
    {
        QDir newSetsDir;
        if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
        newSetsDir.cd("databases");
        QFile file(QString(newSetsDir.absolutePath() + QDir::separator() + "cams_binding"));
        file.open(QFile::ReadOnly);
        bindingCamsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();
    }
    for (auto i : bindingCamsArr)
    {
        QJsonObject obj = i.toObject();
        QString _key2 = obj.value("key2").toString();
        if(key2 == _key2)
        {
            QJsonArray cams = obj.value("cams").toArray();
            _result = cams.toVariantList();
        }

    }
    return _result;
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
    QByteArray newSetNameBa = newSetName.toUtf8();
    char* newSetName_ = newSetNameBa.data();
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
    QString localPath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"local_sets";
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
        QString errMsg = localSetsFile.errorString();
        // qDebug()<< "saveSet : File is not opened = " << errMsg ;
    }
}
void IVCustomSets::saveSet2(QString setName, QString setId, QString newSetName, QString setJson)
{
    St2_FUNCT_St2(4876);

    QByteArray setNameBa = setName.toUtf8();
    char* oldSetName = setNameBa.data();

    QByteArray newSetNameBa = newSetName.toUtf8();
    char* newSetName_ = newSetNameBa.data();

    QByteArray setDataBa = setJson.toUtf8();
    char* setData = setDataBa.data();

    QByteArray setIdBa = setId.toUtf8();
    char* setIdC = setIdBa.data();

    QString _sepa(QDir::separator());
    QString localPath = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"sets";
    QDir localDir(localPath+_sepa);
    if(!localDir.exists(localPath))
    {
        localDir.mkpath(localPath);
    }
    localPath = localDir.absolutePath()+_sepa+"sets";
    QFile localSetsFile(localPath);

    if(localSetsFile.open(QIODevice::ReadWrite | QIODevice::Text))
    {
        QByteArray ba = localSetsFile.readAll();
        localSetsFile.close();


        char* data = ba.data();
        myajl_val jConfig = 0;
        jConfig = mjson_parse1(data);

        if((*jConfig).IsEmpty())
        {
            mjson_free(jConfig);
            jConfig = mjson_parse1("[]");
        }

        if(!(*jConfig).IsArray())
        {
            mjson_free(jConfig);
            jConfig = mjson_parse1("[]");
        }

        if((*jConfig).IsArray())
        {
            int jSize = (*jConfig).GetNumElems();

            bool isServerSet = false;
            int foundIndex = -1;

            // Определяем тип набора
            for(int i1 = 0; i1 < jSize; i1++)
            {
                char* _setName = (*jConfig)[i1]("setName");
                char* _setId = (*jConfig)[i1]("setId");
                int _isUser = (*jConfig)[i1]("isuser");

                // qDebug() << "Set" << i1 << ":" << _setName << "id:" << _setId << "isuser:" << _isUser;

                if(!strcmp(_setName, oldSetName) && !strcmp(_setId, setIdC))
                {
                    foundIndex = i1;
                    if(_isUser == 0)
                    {
                        isServerSet = true;
                        // qDebug() << "→ Found ORIGINAL SERVER set at index" << foundIndex;
                    }
                    else
                    {
                        // qDebug() << "→ Found LOCAL set (or copy) at index" << foundIndex;
                    }
                    break;
                }
            }

            myajl_val setNewData = mjson_parse1(setData);
            if(!setNewData) {
                // qDebug() << "Failed to parse setJson!";
                mjson_free(jConfig);
                return;
            }
            if(!(*setNewData).IsObject()) {
                // qDebug() << "setNewData is not an object!";
                mjson_free(jConfig);
                return;
            }
            // qDebug() << "setNewData parsed successfully";

            if(isServerSet && foundIndex != -1)
            {
                (*setNewData)("isuser") = 1; // Помечаем как локальный
                // qDebug() << "Set isuser to 1";

                (*setNewData)("setName") = newSetName_;
                // qDebug() << "  New name:" << newSetName;

                QString newSetId = QString("%1_copy_%2").arg(setId).arg(QDateTime::currentMSecsSinceEpoch());
                QByteArray newSetIdBa = newSetId.toUtf8();
                char* newSetIdC = newSetIdBa.data();
                (*setNewData)("setId") = newSetIdC;
                // qDebug() << "  New ID for copy:" << newSetId;

                char* finalCopyData = mjson_generate1(setNewData);
                // qDebug() << "Final copy data:" << finalCopyData;
                mjson_string_free(finalCopyData);

                (*jConfig).Add(setNewData);
                // qDebug() << "→ Copy ADDED to config";

                // qDebug() << "Config now has" << (*jConfig).GetNumElems() << "sets (was" << jSize << ")";
            }
            else if(foundIndex != -1)
            {
                if(setName != newSetName)
                {
                    (*setNewData)("setName") = newSetName_;
                }

                (*jConfig)[foundIndex] = setNewData;
            }
            else
            {
                (*jConfig).Add(setNewData);
            }

            char* newSets = mjson_generate1(jConfig);
            // qDebug() << "New config to save:" << newSets;

            if(QString(newSets).contains(newSetName)) {
                // qDebug() << "New config contains copy '" << newSetName << "'";
            } else {
                // qDebug() << "New config does NOT contain copy '" << newSetName << "'";
            }

            if(localSetsFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
            {
                int bytesWritten = localSetsFile.write(newSets);
                localSetsFile.close();
                // qDebug() << "→ File saved, bytes written:" << bytesWritten;

                QFile checkFile(localPath);
                if(checkFile.open(QIODevice::ReadOnly)) {
                    QByteArray savedContent = checkFile.readAll();
                    checkFile.close();
                    if(savedContent.contains(newSetName.toUtf8())) {
                        // qDebug() << "File contains copy after save!";
                    } else {
                        // qDebug() << "File does NOT contain copy after save!";
                    }
                }

                if(!isServerSet)
                {
                    saveOnServer2(setJson);
                }
                else
                {
                    // qDebug() << "→ Skipping server send (server set copy)";
                }

                mjson_string_free(newSets);
            }
            else
            {
                // qDebug() << "Could not open file for writing";
            }
        }
        mjson_free(jConfig);
    }
    else
    {
        QString errMsg = localSetsFile.errorString();
        // qDebug()<< "saveSet : File is not opened = " << errMsg ;
    }
}
void IVCustomSets::on_track_client_info(const void* udata, const param_t* p)
{
    IVCustomSets* _this = (IVCustomSets*)udata;
    if(!_this)
        return;
    const char* login = NULL;
    const char* token = NULL;
    iv_int64 login_hash = 0;
    iv_int64 password_time_hash = 0;
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
      param_get_int64(login_hash);
    }
    if(login)
    {
        QString _login = login;
        _this->setCurrentUser(_login);
        //emit _this->currentUserChanged(_login);
        // qDebug()<<"CUSTOM_SET USER CHANGED = " << _this->_currentUser;
    }
}
void IVCustomSets::initWs()
{
    St2_FUNCT_St2(9867)
    isNeedWs = true;
    callback_t cb = {this,on_track_client_info};
    callback_t cb2 = {this,on_track_events};
    iv::core::profile_open(_onDataPr,"trackWsServerCmd",0,__FILE__,__LINE__);
    iv::core::profile_open(_onResultPr,"trackWsServerData",&cb2,__FILE__,__LINE__);
    iv::core::profile_open(_ipProfile,"track_users_gui_client", &cb, __FILE__, __LINE__);
    if(_ipProfile)
    {
        param_t pr_cmd[] = {
          {PARAM_PCHAR, "cmd",      "current_user_get"},
          {PARAM_PCHAR, "session_id","sets3"},
          {PARAM_PVOID, "owner",    this},
          {0,0,0}
        };
        iv::core::profile_data(_ipProfile, pr_cmd);
    }
}
void IVCustomSets::saveOnServer(QString user, QString folder, QString fileName, QString data)
{
    St2_FUNCT_St2(455778);
    if(!isNeedWs)
    {
        //CrushhhMsg("WS NOT INITED");
        // qDebug()<< "WS NOT INITED!!!!!!!!!";
        //return "WS NOT INITED!!!!!!!!!";
    }
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
void IVCustomSets::saveOnServer2(QString data)
{
    St2_FUNCT_St2(455778);
    if(!isNeedWs)
    {
        //CrushhhMsg("WS NOT INITED");
        // qDebug()<< "WS NOT INITED!!!!!!!!!";
        //return "WS NOT INITED!!!!!!!!!";
    }
    //распарсить тут набор
    myajl_val jSet = 0;
    QByteArray bSet = data.toUtf8();
    char* cSet = bSet.data();
    //qDebug()<< "saveOnServer2 ==========" << cSet << data;
    jSet = mjson_parse1(cSet);
    char* newData =0;
    if(jSet)
    {
        if((*jSet).IsObject())
        {
            myajl_val zones = 0;
            zones =(*jSet)("zones");
            if(zones)
            {
                if((*zones).IsArray())
                {
                    int zonesSize = (*zones).GetNumElems();
                    for(int i1=0;i1<zonesSize;i1++)
                    {
                        char* _type = (*zones)[i1]("type");

                        myajl_val params = (*zones)[i1]("params");
                        char* key1 = (*params)("key1");

                        myajl_val newParams = 0;
                        newParams = mjson_parse1("{}");
                        if(!strcmp(_type,"camera"))
                        {
                            char* key2 = (*params)("key2")("value")[0];
                            newParams->Add("key1",key1);
                            newParams->Add("key2",key2);
                        }
                        else if(!strcmp(_type,"map"))
                        {
                            char* key2 = (*params)("jsonDataFileName")("value")[0];
                            newParams->Add("key1",key1);
                            newParams->Add("key2",key2);
                        }
                        else
                        {
                            // qDebug()<<"saveonserver2 undefined type";
                        }
                        (*zones)[i1]("params") = newParams;
                    }
                    newData = mjson_generate1(jSet);
                }
            }
        }
    }
    else
    {
        // qDebug()<< "SAVE SET ON SERVER ERROR PARSE SET";
        return;
    }
    //распарсить тут набор






    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","sets_api:save_set");


    QByteArray dataBa = data.toUtf8();
    char* _data = dataBa.data();
    params->Add("json",_data);
    jConfig->Add("params",newData);
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
        //qDebug()<< "save to server cmd error";
    }
    mjson_free(jConfig);
}
void IVCustomSets::deleteOnServer2(QString setid)
{
    St2_FUNCT_St2(46778)
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","sets_api:del_set");


    /*
 {
    "method": "sets_api:del_set",
    "params": {
        "setId": "{b8f7041b-ca8c-43b0-8ee9-92dadd2661fa}"
    }
}
*/

    QByteArray dataBa = setid.toUtf8();
    char* _data = dataBa.data();
    params->Add("setId",_data);
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);


    //QString cmd__ = "{\"cmd\":\"config_api:export_settings\",\"params\":{\"filename\": \""+fileName+"\",\"folder\": \""+folder+"\",\"user\": \""+user+"\",\"json\":\""+data+"\"}}";
    int timeout = 10;
    int is_local = 0;
//    QByteArray b1 = cmd__.toUtf8();
//    char* _cmd = b1.data();
    //qDebug()<<"delete cmd = "<< _cmd;
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
        qDebug()<< "save to server cmd error";
    }
    mjson_free(jConfig);
}
// int IVCustomSets::syncSets()
// {





//     return 0;
// }
