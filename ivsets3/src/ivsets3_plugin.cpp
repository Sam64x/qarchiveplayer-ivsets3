#include "ivsets3_plugin.h"
#include "iv_core.h"
#include "IVCustomSets.h"
#include "archive/IVMainArea.h"
#include "archive/IVArchSource.h"
#include "archive/filter/treemodel.h"
#include "archive/filter/treeitem.h"
#include "sourceTree.h"
#include "ExportManager.h"

#include <QObject>
#include <QFile>
#include <QDir>
#include <QQmlEngine>
#include <QJSEngine>
#include <qqml.h>
#include <iv_mem2.h>
#include <iv_autoloader.h>
#include <iv_log3.h>
#include <iv_users_client.h>
#include <fstream>
#include <string>
#include <iostream>
#include <iv_version.h>
#include <QDebug>
#include <QString>
#include <iv_cs.h>
#include "iv_mjson2.h"
#include "iv_stable.h"
#include <iv_threads.h>
#include "iv_threads_pool.h"
#include <iv_ewriter.h>
#include <iv_ws.h>
IVGETMODULEFUNC
    IVLOGFUNC
        IVSTABLEFUNC(533)
    IVMEMORYFUNC(534)
    IVCSFUNC
    IVWSFUNC
    IVCOREFUNC
    IVMJSONFUNC;
IVEWRITERCLIENTFUNC
    IVEWRITERFUNC
        IVUSERSCLIENTFUNC;
const char* myOwner = "customsets";
profile_t _onDataPr;
profile_t _onResultPr;
profile_t _ipProfile;
profile_t _camsUpdateProfile;
QString _ip;
QString _currentUser;
const char* cmd1 = "cams";
const char* cmd2 = "sets";
myajl_val _cameras_Array;
myajl_val _sets_localArray;
myajl_val _sets_serverArray;

const char* camsParams = "{\"type\":\"camera\",\"qml_path\":\"qtplugins/iv/viewers/viewer/IVViewer.qml\",\"params\":{\"key2\":{\"type\":\"var\",\"value\":[\"\"]},\"running\":{\"type\":\"var\",\"value\":[true]}}}";
const char* mapsParams ="{"
                         " \"type\":\"MapViewer\","
                         " \"qml_path\":\"qtplugins/iv/mapviewer/QMapViewer.qml\","
                         " \"params\": {\"jsonDataFileName\":{\"type\":\"var\",\"value\":[\"\"]}}"
                         "}";
QString _preset3 = "[{\"x\":1,\"y\":1,\"dx\":4,\"dy\":4},{\"x\":4,\"y\":1,\"dx\":4,\"dy\":4},{\"x\":1,\"y\":4,\"dx\":2,\"dy\":2},{\"x\":3,\"y\":4,\"dx\":2,\"dy\":2},{\"x\":5,\"y\":4,\"dx\":2,\"dy\":2},{\"x\":7,\"y\":4,\"dx\":2,\"dy\":2},{\"x\":1,\"y\":8,\"dx\":2,\"dy\":2},{\"x\":3,\"y\":8,\"dx\":2,\"dy\":2},{\"x\":5,\"y\":8,\"dx\":2,\"dy\":2},{\"x\":7,\"y\":8,\"dx\":2,\"dy\":2}]";

namespace {
QObject* exportManagerProvider(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(scriptEngine);
    auto* exportManager = new ExportManager(engine);
    QObject* appInfo = engine->property("appInfo").value<QObject*>();
    if (!appInfo && engine->rootContext()) {
        const QVariant contextProperty = engine->rootContext()->contextProperty("appInfo");
        if (contextProperty.canConvert<QObject*>())
            appInfo = contextProperty.value<QObject*>();
    }
    if (appInfo)
        exportManager->setAppInfo(appInfo);
    return exportManager;
}
} // namespace
void save_sets(QString type,char* json)
{
    St2_FUNCT_St2(322);
    QString _appPath = QCoreApplication::applicationDirPath();
    QString _sepa(QDir::separator());
    QString pp = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+type;
    QDir dd(_appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+type+_sepa);
    //  qDebug()<<"sepa = " <<_sepa;
    //  qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp=dd.absolutePath()+_sepa+type;
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        //   qDebug()<<"SAVE SETS---------------------------------------------------------------";
        //   qDebug()<< "File sets is open" << type << json;
        QString tempp = "[]";
        QByteArray ba = tempp.toUtf8();
        if(!json)
        {
            file.write("");
        }
        else
        {
            myajl_val _json = mjson_parse(json);
            if(_json)
            {
                if((*_json).IsArray())
                {
                    int elemCount = (*_json).GetNumElems();
                    for(int i1= 0; i1<elemCount;i1++)
                    {
                        char* commJson = mjson_generate1((*_json)[i1]);
                        if(commJson)
                        {
                            file.write(commJson);

                        }
                        else
                        {
                            file.write("");
                        }
                        mjson_string_free(commJson);
                    }
                }
            }
            mjson_free(_json);

        }
        file.close();
    }
    //
}
void save_sets_remote(QString type,char* json)
{
    St2_FUNCT_St2(322);
    QString _appPath = QCoreApplication::applicationDirPath();
    QString _sepa(QDir::separator());
    QString pp = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+type;
    QDir dd(_appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+type+_sepa);
    // qDebug()<<"sepa = " <<_sepa;
    // qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp=dd.absolutePath()+_sepa+type;
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        //  qDebug()<<"SAVE SETS---------------------------------------------------------------";
        //  qDebug()<< "File sets is open" << type << json;
        QString tempp = "[]";
        QByteArray ba = tempp.toUtf8();
        if(!json)
        {
            file.write("");
        }
        else
        {
            myajl_val _json = mjson_parse(json);
            myajl_val _setsArray = mjson_parse("[]");
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
                                myajl_val _setsObject = mjson_parse("{}");
                                char* _setName = (*rows)[i2]("cstname");
                                char* _setid = (*rows)[i2]("cstid");
                                int _gridType = (*rows)[i2]("cstgrid");
                                int _xRatio = (*rows)[i2]("cstx_ratio");
                                int _yRatio = (*rows)[i2]("csty_ratio");
                                if(!_xRatio || _xRatio==0)
                                {
                                    _xRatio = 16;
                                    _yRatio = 9;
                                }
                                (*_setsObject).Add("setName",_setName);
                                (*_setsObject).Add("cstId",_setid);
                                (*_setsObject).Add("grid_type",-1);
                                (*_setsObject).Add("aspectX",_xRatio);
                                (*_setsObject).Add("aspectY",_yRatio);
                                //_setsObject->Add("zones",);
                                myajl_val zones = mjson_parse("[]");
                                char* _positions = (*rows)[i2]("cstpositions");
                                if(_positions)
                                {
                                    myajl_val _zones = mjson_parse(_positions);
                                    if(zones && (*zones).IsArray())
                                    {
                                        int elemCount3 = (*_zones).GetNumElems();
                                        bool isOnce = false;
                                        int _cols = 0;//(*_zones)[i3]("cols");
                                        int _rows = 0;//(*_zones)[i3]("rows");
                                        for(int i3=0;i3<elemCount3;i3++)
                                        {

                                            myajl_val zone = mjson_parse("{}");
                                            int _x = (*_zones)[i3]("x");
                                            int _y = (*_zones)[i3]("y");
                                            int _dx = (*_zones)[i3]("dx");
                                            int _dy = (*_zones)[i3]("dy");
                                            char* _key2 = (*_zones)[i3]("key2");
                                            //qDebug()<<"KEY2 IN SET = " << _key2;

                                            int _colsMax = (*_zones)[i3]("cols");
                                            int _rowsMax = (*_zones)[i3]("rows");
                                            if(_colsMax>_cols)
                                            {
                                                _cols = _colsMax;
                                            }
                                            if(_rowsMax>_rows)
                                            {
                                                _rows = _rowsMax;
                                            }

                                            (*zone).Add("x",_x);
                                            (*zone).Add("y",_y);
                                            (*zone).Add("dx",_dx);
                                            (*zone).Add("dy",_dy);
                                            (*zone).Add("type","camera");
                                            if(!_key2 || !strcmp(_key2,"null"))
                                            {
                                                myajl_val __params = mjson_parse("{}");
                                                (*zone).Add("params",__params);
                                                (*zone).Add("qml_path","");
                                            }
                                            else
                                            {
                                                (*zone).Add("qml_path","qtplugins/iv/viewers/viewer/IVViewer.qml");
                                                QString __key2 = _key2;
                                                QString _params = "{\"key2\": {\"type\":\"var\",\"value\": [\""+__key2+"\"]},\"running\": {\"type\":\"var\",\"value\": [true]}}";
                                                QByteArray ba = _params.toUtf8();
                                                char* ttt = ba.data();
                                                myajl_val __params = mjson_parse(ttt);
                                                if(!__params)
                                                {
                                                    qDebug()<< "PARAMS NOT PARSE";
                                                }
                                                char* ttempStr = mjson_generate1(__params);
                                                //qDebug()<<"PARAMS = " << ttempStr <<" del "<< ba.data();
                                                (*zone).Add("params",__params);
                                                mjson_string_free(ttempStr);
                                            }
                                            zones->Add(zone);
                                            (*_setsObject).Add("zones",zones);
                                        }
                                        if(!isOnce)
                                        {
                                            (*_setsObject).Add("cols",_cols);
                                            (*_setsObject).Add("rows",_rows);
                                            isOnce = true;
                                        }
                                    }
                                }
                                (*_setsArray).Add(_setsObject);
                            }
                        }
                    }
                    char* tempStr = mjson_generate1(_setsArray);
                    if(tempStr)
                    {
                        file.write(tempStr);
                    }
                    mjson_string_free(tempStr);
                }
            }
            mjson_free(_setsArray);
        }
        file.close();
    }
}
void save_cameras(char* json)
{
    St2_FUNCT_St2(45678);
    //qDebug()<<"SAVE CAMERAS---------------------------------------------------------------";
    char* dataArray = json;//mjson_generate1(_cameras_Array);
    QString _sepa(QDir::separator());
    QDir d;
    QString pp;
    if(!json)
    {
        return;
    }
    pp+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"new_sets"+_sepa+"cameras";
    QDir dd(pp);
    //  qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp =  dd.absolutePath()+_sepa+"cameras";
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        //   qDebug()<<"SAVE CAMERAS3333333333333---------------------------------------------------------------";
        //  qDebug()<< "File cams is open";
        file.write(dataArray);
        file.close();
    }
    //mjson_string_free(dataArray);
}
void save_maps(char* json)
{
    St2_FUNCT_St2(45678);
    //qDebug()<<"SAVE CAMERAS---------------------------------------------------------------";
    char* dataArray = json;//mjson_generate1(_cameras_Array);
    QString _sepa(QDir::separator());
    QDir d;
    QString pp;
    if(!json)
    {
        return;
    }
    pp+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"new_sets"+_sepa+"maps";
    QDir dd(pp);
    // qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp =  dd.absolutePath()+_sepa+"maps";
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        // qDebug()<<"SAVE maps3333333333333---------------------------------------------------------------" << dataArray;
        // qDebug()<< "File cams is open";
        file.write(dataArray);
        file.close();
    }
    //mjson_string_free(dataArray);
}
void save_server_sets(char* json)
{
    St2_FUNCT_St2(45678);
    //qDebug()<<"SAVE save_server_sets---------------------------------------------------------------" << json;
    char* dataArray = json;//mjson_generate1(_cameras_Array);
    QString _sepa(QDir::separator());
    QDir d;
    QString pp;
    if(!json)
    {
        return;
    }
    pp+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"new_sets"+_sepa+"sets";
    QDir dd(pp);
    // qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp =  dd.absolutePath()+_sepa+"sets";
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        // qDebug()<<"SAVE sets_new---------------------------------------------------------------" << dataArray;
        qDebug()<< "File sets_new is open" <<json ;
        myajl_val _json = mjson_parse(json);
        //myajl_val _setsArray = mjson_parse("[]");
        if(_json)
        {
            if((*_json).IsArray())
            {
                if((*_json).size()>0)
                {
                    myajl_val _setsObject = (*_json)[0];
                    if(_setsObject != NULL)
                    {
                        if((*_setsObject).IsObject())
                        {
                            myajl_val _sets = (*_setsObject)("sets");
                            if(_sets != NULL)
                            {
                                if((*_sets).IsArray())
                                {
                                    int _setsSize = (*_sets).GetNumElems();
                                    for(int i1=0;i1<_setsSize;i1++)
                                    {
                                        myajl_val _set = (*_sets)[i1];
                                        if(_set != NULL)
                                        {
                                            myajl_val _zones = (*_set)("zones");
                                            if(_zones != NULL)
                                            {
                                                if((*_zones).IsArray())
                                                {
                                                    int _zonesSize = (*_zones).GetNumElems();
                                                    for(int i2=0;i2<_zonesSize;i2++)
                                                    {
                                                        myajl_val _params = (*_zones)[i2]("params");
                                                        char* _type = (*_zones)[i2]("type");
                                                        QString __type = "";
                                                        if(!_type)
                                                        {
                                                            __type = "camera";
                                                        }
                                                        else
                                                        {
                                                            __type = _type;
                                                        }

                                                        if(_params!=NULL)
                                                        {
                                                            char* _key1 = (*_params)("key1");
                                                            char* _key2 = (*_params)("key2");
                                                            //qDebug()<< "CONVERT KEY1 = " << _key1;
                                                            if(!_key2 || !strcmp(_key2,"null"))
                                                            {
                                                                //qDebug()<< "PARAMS NOT PARSE";
                                                                myajl_val __params = mjson_parse("{}");
                                                                (*_zones)[i2]("params") = __params;
                                                                (*_zones)[i2].Add("type","empty");
                                                                //(*_zones)[i2]("params",__params);
                                                                (*_zones)[i2].Add("qml_path","");
                                                            }
                                                            else
                                                            {
                                                                if(__type == "camera")
                                                                {
                                                                    myajl_val _constParams = mjson_parse(camsParams);
                                                                    if(_constParams != NULL)
                                                                    {
                                                                        (*_constParams)("params").Add("key1",_key1);
                                                                        (*_constParams)("params")("key2")("value")[0] = _key2;
                                                                        (*_zones)[i2].Add("type","camera");
                                                                        (*_zones)[i2].Add("qml_path","qtplugins/iv/viewers/viewer/IVViewer.qml");
                                                                        (*_zones)[i2]("params") = (*_constParams)("params");
                                                                    }
                                                                }
                                                                else if(__type == "map")
                                                                {
                                                                    myajl_val _constParams = mjson_parse(mapsParams);
                                                                    if(_constParams != NULL)
                                                                    {
                                                                        (*_constParams).Add("key1",_key1);
                                                                        (*_constParams)("params")("jsonDataFileName")("value")[0] = _key2;
                                                                        (*_zones)[i2].Add("type","map");
                                                                        (*_zones)[i2].Add("qml_path","qtplugins/iv/mapviewer/QMapViewer.qml");
                                                                        (*_zones)[i2]("params") = (*_constParams)("params");
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    //qDebug()<< "PARSE TYPE ERROR IN SERVER SETS";
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

                            char* tempStr = mjson_generate1(_sets);
                            //qDebug()<< "convert set = "<<tempStr;
                            file.write(tempStr);
                            file.close();
                            mjson_string_free(tempStr);
                        }
                    }
                }
            }
            //            char* tempStr = mjson_generate1(_json);
            //            file.write(tempStr);
            //            file.close();
            //            mjson_string_free(tempStr);
        }
        mjson_free(_json);
    }
}
void save_fact_list(char* json)
{
    St2_FUNCT_St2(45678);
    //qDebug()<<"SAVE CAMERAS---------------------------------------------------------------";
    char* dataArray = json;//mjson_generate1(_cameras_Array);
    QString _sepa(QDir::separator());
    QDir d;
    QString pp;
    if(!json)
    {
        return;
    }
    pp+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"new_sets"+_sepa+"other";
    QDir dd(pp);
    // qDebug()<<dd.absolutePath();
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp =  dd.absolutePath()+_sepa+"fact_list";
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        // qDebug()<<"SAVE CAMERAS3333333333333---------------------------------------------------------------";
        // qDebug()<< "File cams is open";
        file.write(dataArray);
        file.close();
    }
    //mjson_string_free(dataArray);
}
void save_groups_list(char* json)
{
    St2_FUNCT_St2(45678);
    //qDebug()<<"SAVE CAMERAS---------------------------------------------------------------";
    QString _appPath = QCoreApplication::applicationDirPath();
    QString _sepa(QDir::separator());
    QString pp = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"other";
    QDir dd(_appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"other"+_sepa);
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp=dd.absolutePath()+_sepa+"groups_list";
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        // qDebug()<<"save_groups_list";
        //  qDebug()<< "File sets is open"  << json;
        QString tempp = "[]";
        QByteArray ba = tempp.toUtf8();
        if(!json)
        {
            file.write("[]");
        }
        else
        {
            myajl_val _json = mjson_parse(json);
            myajl_val _setsArray = mjson_parse("[]");
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
                                myajl_val _setsObject = mjson_parse("{}");
                                char* _setName = (*rows)[i2]("csgname");
                                char* _setid = (*rows)[i2]("csgid");
                                char* _setParentid = (*rows)[i2]("csgparentid");

                                (*_setsObject).Add("groupName",_setName);
                                (*_setsObject).Add("groupId",_setid);
                                (*_setsObject).Add("groupParentId",_setParentid);
                                (*_setsArray).Add(_setsObject);
                            }
                        }
                    }
                    char* tempStr = mjson_generate1(_setsArray);
                    if(tempStr)
                    {
                        file.write(tempStr);
                    }
                    mjson_string_free(tempStr);
                }
            }
            mjson_free(_setsArray);
        }
        file.close();
    }
}
void save_groups_sets(char* json)
{
    St2_FUNCT_St2(45678);
    //qDebug()<<"SAVE CAMERAS---------------------------------------------------------------";
    QString _appPath = QCoreApplication::applicationDirPath();
    QString _sepa(QDir::separator());
    QString pp = _appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"other";
    QDir dd(_appPath + _sepa+"databases"+_sepa+"new_sets"+_sepa+"other"+_sepa);
    if(!dd.exists(pp))
    {
        dd.mkpath(pp);
    }
    pp=dd.absolutePath()+_sepa+"groups_list_sets";
    QFile file(pp);
    if(file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        // qDebug()<<"groups_list_sets";
        //  qDebug()<< "File sets is open"  << json;
        QString tempp = "[]";
        QByteArray ba = tempp.toUtf8();
        if(!json)
        {
            file.write("[]");
        }
        else
        {
            myajl_val _json = mjson_parse(json);
            myajl_val _setsArray = mjson_parse("[]");
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
                                myajl_val _setsObject = mjson_parse("{}");
                                char* _setName = (*rows)[i2]("sgssetgroupid");
                                char* _setid = (*rows)[i2]("sgssetid");
                                (*_setsObject).Add("groupId",_setName);
                                (*_setsObject).Add("sgssetid",_setid);
                                (*_setsArray).Add(_setsObject);
                            }
                        }
                    }
                    char* tempStr = mjson_generate1(_setsArray);
                    if(tempStr)
                    {
                        file.write(tempStr);
                    }
                    mjson_string_free(tempStr);
                }
            }
            mjson_free(_setsArray);
        }
        file.close();
    }
}
void oncmd(const void* udata, const param_t* p)
{
    St2_FUNCT_St2(35206)
    int32_t code = 0;
    const char* user_msg = nullptr;
    char* _this = (char*)udata;
    if(!strcmp(_this,"35"))
    {
        // qDebug()<<"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 35";
    }
    else
    {
        return;
    }
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
    if (json != 0)
    {
        // myajl_val jConfig = 0;
        // jConfig = mjson_parse(json);
    }
}

void onresult(const void* udata, const param_t* p)
{
    St2_FUNCT_St2(23446);
    int32_t code = 0;
    const char* user_msg = nullptr;
    char* _this = (char*)udata;
    //qDebug()<<"AAAAAACCCCCCCCCCCCCCCC==========1 "<<_this;
    if(strcmp("customsets",_this))
    {
        return;
    }
    // qDebug()<<"AAAAAACCCCCCCCCCCCCCCC==========2 "<<_this;
    //qDebug()<<"WS REQUEST !!!!!!";
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
        if(owner != 0 && owner_data != 0)
    {
        if ((owner != udata) || (owner_data == nullptr))
        {
            return;
        }

        St2(3526)
            if (json != 0 )
        {
            St2(3522)
            //qDebug()<<"ow = "<<owner;
            //qDebug()<<"ud= "<<code;
            //qDebug()<<"JSON = "<<json << "method"<<(char*)owner_data;
            if(code<0)
                return;
            char* cmd_type = (char*)owner_data;
            St2(2522)
                if(!strcmp(cmd_type,"customset_cams"))
            {
                St2(2521);

                qDebug() << "JSON = " << json;
                save_cameras(json);
            }
            else if(!strcmp(cmd_type,"customset_sets_remote"))
            {
                // qDebug()<<"AAAAAAAAAAAAAAAAA = customset_sets" << json;
                // qDebug()<<"AAAAAAAAAAAAAAAAA = customset_sets2";
                //save_sets_remote("remote_sets",json);
            }
            else if(!strcmp(cmd_type,"customset_sets_local"))
            {
                save_sets("local_sets",json);
            }
            else if(!strcmp(cmd_type,"customset_fact_list"))
            {
                save_fact_list(json);
            }
            else if(!strcmp(cmd_type,"customset_groups_remote"))
            {
                save_groups_list(json);
            }
            else if(!strcmp(cmd_type,"customset_groups_sets_remote"))
            {
                save_groups_sets(json);
            }
            else if(!strcmp(cmd_type,"customset_sets_maps"))
            {
                save_maps(json);
            }
            else if(!strcmp(cmd_type,"server_sets"))
            {
                save_server_sets(json);
            }
            else
            {

            }
        }
    }
}

void custom_group_list_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(756);
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config:db");
    QByteArray ba = _currentUser.toUtf8();
    char* currUs = ba.data();
    params->Add("alias","conf");
    params->Add("table","camerasetgroup");
    params->Add("instruction","select");
    params->Add("conditions","[]");
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);

    int timeout = 10;
    int is_local = 0;
    // qDebug()<<"cmd remote = "<< _cmd;
    // qDebug()<<"cmd remote2 = ";
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data",  "customset_groups_remote"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p);
    mjson_string_free(_cmd);
    mjson_free(jConfig);
}
void custom_group_set_list_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(756);
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config:db");
    QByteArray ba = _currentUser.toUtf8();
    char* currUs = ba.data();
    params->Add("alias","conf");
    params->Add("table","camerasetgroup2cameraset");
    params->Add("instruction","select");
    params->Add("conditions","[]");
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);

    int timeout = 10;
    int is_local = 0;
    //qDebug()<<"cmd remote = "<< _cmd;
    // qDebug()<<"cmd remote2 = ";
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data",  "customset_groups_sets_remote"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p);
    mjson_string_free(_cmd);
    mjson_free(jConfig);
}
void fact_list_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(256);
    //{"server_ip": "string","direct_access": 1,"version": "v1"}
    QString cmd__ = "{\"cmd\":\"listener_pinger:get_down_servers\",\"params\":{\"server_ip\": \"string\",\"direct_access\": 1,\"version\":\"v1\"}}";
    int timeout = 10;
    int is_local = 0;
    QByteArray b = cmd__.toUtf8();
    char* _cmd = b.data();
    //qDebug()<<"cmd = "<< _cmd;
    param_t p2[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data", "customset_fact_list"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p2);
}
void cameras_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(556);
    QString cmd__ = "{\"cmd\":\"camera:list\",\"params\":{\"info\": true,\"profiles\": true,\"positions\":false,\"page\":1,\"page_size\":4000}}";
    QString cmd2__ = "{\"cmd\":\"cams_read\",\"value\":true}}";
    int timeout = 10;
    int is_local = 0;
    QByteArray b = cmd__.toUtf8();
    char* _cmd = b.data();
    QByteArray b2 = cmd2__.toUtf8();
    char* _cmd2 = b.data();
    //qDebug()<<"camera cmd = "<< _cmd;
    param_t p2[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data", "customset_cams"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p2);
}
void local_sets_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(5565);
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config_api:import_settings");
    QByteArray ba = _currentUser.toUtf8();
    char* currUs = ba.data();
    params->Add("folder","local_sets");
    params->Add("filename","local_sets");
    params->Add("user",currUs);
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);
    //QString cmd__ = "{\"cmd\":\"config_api:import_settings\",\"params\":{\"filename\": \"local_sets\",\"folder\": \"local_sets\",\"user\": \""+_currentUser+"\"}}";
    int timeout = 10;
    int is_local = 0;
    //    QByteArray b1 = cmd__.toUtf8();
    //    char* _cmd = b1.data();
    //qDebug()<<"cmd local = "<< _cmd;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data",  "customset_sets_local"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p);
    mjson_string_free(_cmd);
    mjson_free(jConfig);
}
void maps_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(5565);
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config_api:dir_info");
    QByteArray ba = _currentUser.toUtf8();
    char* currUs = ba.data();
    params->Add("folder","databases/mapData");
    //params->Add("filename","local_sets");
    //params->Add("user",currUs);
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);
    //QString cmd__ = "{\"cmd\":\"config_api:dir_info\",\"params\":{\"folder\": \"databases/mapData\"}}";
    int timeout = 10;
    int is_local = 0;
    //    QByteArray b1 = cmd__.toUtf8();
    //    char* _cmd = b1.data();
    // qDebug()<<"cmd local = "<< _cmd;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data",  "customset_sets_maps"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p);
    mjson_string_free(_cmd);
    mjson_free(jConfig);
}
void remote_sets_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(556);
    myajl_val jConfig = 0;
    myajl_val params = 0;
    jConfig = mjson_parse1("{}");
    params = mjson_parse1("{}");
    jConfig->Add("cmd","config:db");
    QByteArray ba = _currentUser.toUtf8();
    char* currUs = ba.data();
    params->Add("alias","conf");
    params->Add("table","cameraset");
    params->Add("instruction","select");
    params->Add("conditions","[]");
    jConfig->Add("params",params);
    char* _cmd = mjson_generate1(jConfig);

    int timeout = 10;
    int is_local = 0;
    // qDebug()<<"cmd remote = "<< _cmd;
    //qDebug()<<"cmd remote2 = ";
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data",  "customset_sets_remote"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p);
    mjson_string_free(_cmd);
    mjson_free(jConfig);
}
void server_sets_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(5465);

    QString cmd__ = "{\"cmd\":\"sets_api:get_sets\",\"params\":{}}";
    int timeout = 10;
    int is_local = 0;
    QByteArray b1 = cmd__.toUtf8();
    char* _cmd = b1.data();
    qDebug()<<"cmd local = "<< _cmd;
    param_t p[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", myOwner},
            {PARAM_PVOID, "owner_data",  "server_sets"},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
    iv::core::profile_data(_onDataPr,p);
}
void on_track_client_info(const void* udata, const param_t* p)
{
    //IVCustomSets* _this = (IVCustomSets*)udata;
    // if(!_this)
    //     return;
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
        _currentUser = login;
        //qDebug()<< "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb = _currentUser CHANGED2 = " <<_currentUser;
        iv::threads::pool::execute("custom_cams",cameras_updater,0);
        iv::threads::pool::execute("custom_maps",maps_updater,0);
        //iv::threads::pool::execute("custom_sets",local_sets_updater,0);
        iv::threads::pool::execute("custom_sets",server_sets_updater,0);
        //iv::threads::pool::execute("custom_old_sets",remote_sets_updater,0);
        iv::threads::pool::execute("custom_fact_list",fact_list_updater,0);
        iv::threads::pool::execute("custom_group_set_list",custom_group_set_list_updater,0);
        iv::threads::pool::execute("custom_group_list",custom_group_list_updater,0);
    }
}

void initTypes()
{
    St2_FUNCT_St2(42);
    // qDebug()<<"INIT TYPES 2";
    //_cameras_Array = mjson_parse("[]");
    //_sets_localArray = mjson_parse("[]");
    //_sets_serverArray = mjson_parse("[]");
    // _appPath = QCoreApplication::applicationDirPath();
    _onDataPr = nullptr;
    _onResultPr = nullptr;
    callback_t cb111 = {myOwner,onresult};
    callback_t cb4 = {myOwner,on_track_client_info};
    iv::core::profile_open(_onDataPr,"trackWsServerCmd",0,__FILE__,__LINE__);
    iv::core::profile_open(_onResultPr,"trackWsServerData",&cb111,__FILE__,__LINE__);
    iv::core::profile_open(_ipProfile,"track_users_gui_client", &cb4, __FILE__, __LINE__);
    iv::core::profile_open(_camsUpdateProfile,"needCamsUpdate",0,__FILE__, __LINE__);

    if(_ipProfile)
    {
        param_t pr_cmd[] = {
            {PARAM_PCHAR, "cmd",      "current_user_get"},
            {PARAM_PCHAR, "session_id","sets3"},
            {PARAM_PVOID, "owner", "45"},
            {PARAM_PVOID, "owner_data", "45"},
            {0,0,0}
        };
        iv::core::profile_data(_ipProfile, pr_cmd);
    }

    //    iv::threads::pool::execute("custom_cams",cameras_updater,0);
    //    iv::threads::pool::execute("custom_sets",local_sets_updater,0);
    //    iv::threads::pool::execute("custom_old_sets",remote_sets_updater,0);


    QString _sepa(QDir::separator());
    QDir d;
    QString pp;
    QString pp2;
    QString pp3;
    QString pp4;
    pp+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"zone_types";
    pp2+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"zone_pressets";
    pp3+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"maps_analogy";
    pp4+=QCoreApplication::applicationDirPath()+_sepa+"databases"+_sepa+"cams_binding";
    //qDebug()<<pp;
    QFile file(pp);
    QFile file2(pp2);
    QFile file3(pp3);
    QFile file4(pp4);
    if(!file4.exists())
    {
        if(file4.open(QIODevice::WriteOnly | QIODevice::Text))
        {
            //qDebug()<< "File types is open";
            QTextStream out(&file4);
            out.setCodec("UTF-8");
            QString camType = "[{\"key2\":\"cam_key2\",\"cams\":[\"cam_key2\"]}]";
            QByteArray ba = camType.toUtf8();
            char* data = ba.data();
            myajl_val myajl_item = mjson_parse1(data);
            char* _data = mjson_generate1(myajl_item);
            out << _data;
            //qDebug()<<_data << "bbbbbbbbbbbbbbbbbbbbbbbbbbbbb ==========";
            file4.close();
            mjson_string_free(_data);
            mjson_free(myajl_item);
        }
    }
    if(!file3.exists())
    {
        if(file3.open(QIODevice::WriteOnly | QIODevice::Text))
        {
            //qDebug()<< "File types is open";
            QTextStream out(&file3);
            out.setCodec("UTF-8");
            QString camType = "[{\"mapName\":\"mapName\",\"key2\":[\"205\"]}]";


            QByteArray ba = camType.toUtf8();
            char* data = ba.data();
            myajl_val myajl_item = mjson_parse1(data);
            char* _data = mjson_generate1(myajl_item);
            out << _data;
            //qDebug()<<_data << "bbbbbbbbbbbbbbbbbbbbbbbbbbbbb ==========";
            file3.close();
            mjson_string_free(_data);
            mjson_free(myajl_item);
        }
    }

    if(file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        //qDebug()<< "File types is open";
        QTextStream out(&file);
        out.setCodec("UTF-8");
        QString camType = "[{\"type\":\"camera\",\"qml_path\":\"qtplugins/iv/viewers/viewer/IVViewer.qml\",\"params\":{\"key2\":{\"type\":\"var\",\"value\":[\"\"]},\"running\":{\"type\":\"var\",\"value\":[true]}}},{\"type\":\"semantica\",\"qml_path\":\"qtplugins/iv/semantica/IVSemanticaWindow.qml\",\"params\":{}}"
                          " ,{\"type\":\"client_settings\","
                          " \"qml_path\":\"qtplugins/iv/comcomp/IVSettingsTab.qml\","
                          " \"params\": {}"
                          "},"
                          "{"
                          " \"type\":\"MapViewer\","
                          " \"qml_path\":\"qtplugins/iv/mapviewer/QMapViewer.qml\","
                          " \"params\": {\"jsonDataFileName\":{\"type\":\"var\",\"value\":[\"\"]}}"
                          "}"
                          "]";

        QByteArray ba = camType.toUtf8();
        char* data = ba.data();
        myajl_val myajl_item = mjson_parse1(data);
        char* _data = mjson_generate1(myajl_item);
        out << _data;
        //qDebug()<<_data << "bbbbbbbbbbbbbbbbbbbbbbbbbbbbb ==========";
        file.close();
        mjson_string_free(_data);
        mjson_free(myajl_item);
    }
    else
    {
        QString errMsg = file.errorString();
        qDebug()<< "saveSet : File is not opened = " << errMsg ;
    }















}
boointernal int pre_dll_init(const param_t* p) {
    //функция инициализации autoloader, stable и т.д
    IVGETMODULEFUNCINIT(p);
    IVSTABLEINIT( p );
    IVLOGINIT("qtplugins.iv.sets.sets3",p);
    IVCSINIT(p);
    IVCOREINIT;
    IVWSINIT(p);
    IVMJSONINIT();
    IVEWRITERCLIENTINIT(p);
    IVEWRITERINIT(p);
    IVMEMORYINIT( p );
    IVUSERSCLIENTINIT(p);
    qDebug()<<"INIT TYPES";
    initTypes();
    return 0;
}
void IVSets3Plugin::registerTypes(const char* uri) {
    // т.к вызывается один раз, то решил инициализацию autoloader добавить сюда
    ::iv::autoloader::qml::helper<10 * 1024> autoloader(pre_dll_init);
    Q_UNUSED(autoloader);
        //qDebug()<<"AAAAAAAAAAAAAAAAAAAVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV---------------------------";
    qmlRegisterType<IVCustomSets>(uri, 1, 0, "IVCustomSets");

    qRegisterMetaType<SourceTree*>("SourceTree");
    qmlRegisterType<SourceTree>(uri, 1, 0, "IVTree");

    qRegisterMetaType<TreeItem*>("TreeItem");
    qRegisterMetaType<IVArchSource*>("IVArchSource");
    qmlRegisterType<TreeModel>(uri, 1, 0, "TreeModel");
    qmlRegisterType<IVMainArea>(uri, 1, 0, "IVMainArea");

    qmlRegisterSingletonType<ExportManager>(uri, 1, 0, "ExportManager",
                                            exportManagerProvider);
}
//реализуем данную функцию для отписки от всех зависимостей(core, log-1 и т.д)
booexport bool pre_dll_free(const char*)
{
    //    profile_t _onDataPr;
    //    profile_t _onResultPr;
    //    profile_t _ipProfile;
    //    profile_t _camsUpdateProfile;
    if(_ipProfile)
    {
        iv::core::profile_close(_ipProfile);
        _ipProfile = nullptr;
    }
    if(_camsUpdateProfile)
    {
        iv::core::profile_close(_camsUpdateProfile);
        _camsUpdateProfile = nullptr;
    }
    if(_onDataPr)
    {
        iv::core::profile_close(_onDataPr);
        _onDataPr = nullptr;
    }
    if(_onResultPr)
    {
        iv::core::profile_close(_onResultPr);
        _onResultPr = nullptr;
    }
    return true;
}
