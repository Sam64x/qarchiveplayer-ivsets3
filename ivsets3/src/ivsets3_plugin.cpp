#include "ivsets3_plugin.h"
#include "iv_core.h"
#include "IVCustomSets.h"
#include "archive/IVMainArea.h"
#include "archive/IVArchSource.h"
#include "archive/filter/treemodel.h"
#include "archive/filter/treeitem.h"
#include "sourceTree.h"
#include "IVSetsManager.h"
#include "IVZonesModel.h"

#include <QObject>
#include <QFile>
#include <QDir>
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


void initTypes()
{
    St2_FUNCT_St2(42);


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
        // qDebug()<< "saveSet : File is not opened = " << errMsg ;
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
    initTypes();
    return 0;
}

static QObject* IVSetsManagerProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return IVSetsManager::instance();
}

static QObject* IVCustomSetsProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return IVCustomSets::instance();
}

void IVSets3Plugin::registerTypes(const char* uri) {
  // т.к вызывается один раз, то решил инициализацию autoloader добавить сюда
  ::iv::autoloader::qml::helper<10 * 1024> autoloader(pre_dll_init);
  Q_UNUSED(autoloader);
  qmlRegisterSingletonType<IVCustomSets>(uri, 1, 0, "IVCustomSets", IVCustomSetsProvider);

  qmlRegisterType<SourceTree>(uri, 1, 0, "SourceTree");

  qRegisterMetaType<TreeItem*>("TreeItem");
  qRegisterMetaType<IVArchSource*>("IVArchSource");
  qmlRegisterType<TreeModel>(uri, 1, 0, "TreeModel");
  qmlRegisterType<IVMainArea>(uri, 1, 0, "IVMainArea");

  qmlRegisterSingletonType<IVSetsManager>(uri, 1, 0, "IVSetsManager", IVSetsManagerProvider);
  qmlRegisterUncreatableType<IVSet>(uri, 1, 0, "IVSet", "IVSet enum access");
  qRegisterMetaType<IVSet*>();
  qRegisterMetaType<IVZone*>();
  qmlRegisterType<IVZonesModel>(uri, 1, 0, "IVZonesModel");
}
