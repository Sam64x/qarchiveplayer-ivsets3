#include "qarchiveplayer_plugin.h"
#include "treemodel.h"
#include "treeitem.h"

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJSEngine>

// WebSocketClient
#include "WebSocketClient.h"
#include "ArchiveSegmentStreamer.h"
#include "PlaybackCoordinator.h"
#include "VideoItem.h"
#include "ExportController.h"
#include "ExportManager.h"
#include "ImagePipeline.h"
#include "AppInfo.h"
#include "PrimitiveOverlay.h"

// EventModels
#include "EventsModel.h"
#include "FullnessModel.h"
#include "EventsProjectionModel.h"
#include "FullnessProjectionModel.h"

#include <QUrl>
#include <QFile>
#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariant>

//IVBOOLDOG

#include <qqml.h>
#include <iv_autoloader.h>
#include <iv_log3.h>
#include "iv_version.h"
#include <iv_stable.h>
#include "qpreviewer.h"
#include <iv_mjson.h>
#include "iv_cs.h"
#include <iv_ewriter_no_std.h>
#include <iv_ws.h>
#define SAFE_DELETE4( p ) { if( ( p ) ) delete ( p ); ( p ) = NULL; }



IVMJSONFUNC
    IVGETMODULEFUNC
        IVWSFUNC
            IVLOGFUNC
                IVCSFUNC
                    IVEWRITERCLIENTFUNC
                        IVEWRITERFUNC
                            IVSTABLEFUNC(169)
    IVCOREFUNC;
IVMEMORYFUNC(444)
IVVERSION
    INIT_FUNCT_LIS_PIN;

//boointernal Log* _log = 0;

ColorImageProvider* g_images = NULL;

namespace {
QObject* exportManagerProvider(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(scriptEngine);
    auto exportManager = new ExportManager(engine);
    return exportManager;
}
} // namespace

boointernal int pre_dll_init(const param_t* p)
{
    //функция инициализации autoloader, stable и т.д
    // IVBOOLDOGINIT(p);
    IVGETMODULEFUNCINIT(p);
    IVLOGINIT("qtplugins.iv.viewers.archiveplayer", p);
    IVCSINIT(p);
    IVMJSONINIT();
    IVWSINIT(p);
    IVSTABLEINIT(p);
    IVEWRITERCLIENTINIT(p);
    IVEWRITERINIT(p);
    IVCOREINIT;
    IVMEMORYINIT( p );
    ExLisPin::initialize();
    return 0;
}
void QarchiveplayerPlugin::registerTypes(const char *uri)
{
    Q_UNUSED(uri);
    ::iv::autoloader::qml::helper< 10 * 1024 > autoloader(pre_dll_init);
    Q_UNUSED(autoloader);
    qmlRegisterType<ArchivePlayer>(uri, 1, 0, "ArchivePlayer");
    qmlRegisterType<TreeModel>(uri, 1, 0, "FilterModel");
    qRegisterMetaType<TreeItem*>("TreeItem");

    qmlRegisterType<WebSocketClient>(uri, 1, 0, "WebSocketClient");
    qmlRegisterType<ImagePipeline>(uri, 1, 0, "ImagePipeline");
    qmlRegisterType<ArchiveSegmentStreamer>(uri, 1, 0, "ArchiveSegmentStreamer");
    qmlRegisterType<PlaybackCoordinator>(uri, 1, 0, "PlaybackCoordinator");
    qmlRegisterType<ExportController>(uri, 1, 0, "ExportController");
    qmlRegisterType<VideoItem>(uri, 1, 0, "VideoItem");
    qmlRegisterType<PrimitiveOverlay>(uri, 1, 0, "PrimitiveOverlay");
    qmlRegisterSingletonType<ExportManager>(uri, 1, 0, "ExportManager", exportManagerProvider);

    qmlRegisterType<EventsModel>(uri,1,0,"EventsModel");
    qmlRegisterType<FullnessModel>(uri,1,0,"FullnessModel");
    qmlRegisterType<EventsProjectionModel>(uri,1,0,"EventsProjectionModel");
    qmlRegisterType<FullnessProjectionModel>(uri,1,0,"FullnessProjectionModel");

    //_log = ::iv::log::init("qtviewer");
}

void QarchiveplayerPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(uri);

    engine->addImageProvider("previewer", new ColorImageProvider);

    auto appInfo = new AppInfo(engine);
    engine->rootContext()->setContextProperty("appInfo", appInfo);
    engine->setProperty("appInfo", QVariant::fromValue(appInfo));
}

//реализуем данную функцию для отписки от всех зависимостей(core, log-1 и т.д)
booexport bool pre_dll_free(const char*)
{
    //ch220527
    //if ( NULL != _log )
    //SAFE_DELETE4( _log );
    //e
    return true;
}
