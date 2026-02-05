#include "qarchive_player.h"
#include "qpreviewer.h"

#include <sstream>
#include <chrono>
#include <thread>
#include <memory>
#include <QtConcurrent/QtConcurrentRun>
#include <QMutex>
#include <QMutexLocker>

#include <QBuffer>
#include <QFile>
#include <QDir>
#include <QString>
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QLoggingCategory>
#include <QThread>
#include "QJsonDocument"
#include "QJsonObject"
#include "QJsonArray"

#include <iv_tasks_noncritical.h>
#include <iv_threads_pool.h>
#include "iv_cs.h"
#include <iv_arc_frame_cash.h>
#include "iv_mjson2.h"
//#include <../qarchiveplayer/include/iv_ewriter.h>
#include <iv_ewriter.h>

void get_frame_on_time_cb2(const void* owner, const void* owner_data, param_t* p);
void get_cache_data2(void* udata);

static const char* myOwnerVideo = "customarcVideo";
static const char* myOwnerAudio = "customarcAudio";

static profile_t _arcVideo_PD = nullptr;
static profile_t _arcVideo_PD_result = nullptr;

static profile_t _arcAudio_PD = nullptr;
static profile_t _arcAudio_PD_result = nullptr;

Q_LOGGING_CATEGORY(lcArchivePlayerInit, "archive.player.init")

namespace {
QThreadPool& archivePlayerPool()
{
    static QThreadPool pool;
    static std::once_flag once;
    std::call_once(once, []() {
        const int ideal = QThread::idealThreadCount();
        const int maxThreads = qMax(1, qMin(2, ideal > 1 ? ideal - 1 : ideal));
        pool.setMaxThreadCount(maxThreads);
        pool.setExpiryTimeout(-1);
    });
    return pool;
}

ArchiveInitData loadArchiveInitData()
{
    St2_FUNCT_St2(5688);
    ArchiveInitData data;
    QElapsedTimer totalTimer;
    totalTimer.start();

    QString dirPath = QCoreApplication::applicationDirPath();
    QFile file(dirPath + "/client_settings.json");
    QElapsedTimer fileTimer;
    fileTimer.start();
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        QString line;
        while (!in.atEnd()) {
            line.append(in.readLine());
        }
        QByteArray ba = line.toUtf8();
        char* myconf = ba.data();
        myajl_val jConfig = mjson_parse(myconf);
        if (jConfig && (*jConfig).IsObject()) {
            myajl_val res_servers = (*jConfig)("reserved_servers");
            myajl_val cs_servers = (*jConfig)("servers");
            if (cs_servers) {
                int jSize = (*cs_servers).GetNumElems();
                if (jSize > 0) {
                    myajl_val ipsss = (*cs_servers)[0];
                    if (ipsss) {
                        data.csServer = (*ipsss)("ip").GetString();
                    }
                }
            }
            if (res_servers) {
                int jSize = (*res_servers).GetNumElems();
                for (int i = 0; i < jSize; i++) {
                    myajl_val ipsss = (*res_servers)[i];
                    if (ipsss) {
                        data.ipList.push_back((*ipsss)("ip").GetString());
                    }
                }
            }
        }
        if (jConfig)
            mjson_free(jConfig);
    }
    // qCDebug(lcArchivePlayerInit)
    //     << "client_settings.json read elapsedMs" << fileTimer.elapsed();

    ::iv::ws::call_interrupt _iv_ws_call_interrupt;
    std::vector<iv::ewriter::table::eventtype> evttypes;
    iv::ewriter::call cl(_iv_ws_call_interrupt, 20000000);
    QElapsedTimer evtTimer;
    evtTimer.start();
    cl.eventtypes_list(evttypes);
    // qCDebug(lcArchivePlayerInit)
    //     << "eventtypes_list elapsedMs" << evtTimer.elapsed()
    //     << "size" << static_cast<int>(evttypes.size());
    for (const auto& evt : evttypes) {
        quint64 id = evt.id;
        QString name = evt.name.c_str();
        if ((id >= 20000 && id < 30000) || id == 60044 || id == 60045 || id == 60046 || id == 60047) {
            data.evtVals.append(id);
            data.evtNames.append(name);
        }
    }

    // qCDebug(lcArchivePlayerInit)
    //     << "loadArchiveInitData total elapsedMs" << totalTimer.elapsed();
    return data;
}

QFuture<ArchiveInitData> sharedArchiveInitFuture()
{
    static QMutex mutex;
    static QFuture<ArchiveInitData> future;
    static bool started = false;

    QMutexLocker locker(&mutex);
    if (!started) {
        future = QtConcurrent::run(&archivePlayerPool(), loadArchiveInitData);
        started = true;
    }
    return future;
}
} // namespace

void ArchivePlayer::getIps()
{
    St2_FUNCT_St2(5688);
    QString dirPath = QCoreApplication::applicationDirPath();
    QFile file(dirPath + "/client_settings.json");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        int a = 5;
        a--;
        QTextStream in(&file);
        QString line = "";
        while (!in.atEnd()) {
            line.append(in.readLine());
        }
        QByteArray ba = line.toUtf8();
        char* myconf = ba.data();
        // qDebug()<<"act server line = " << line;
        myajl_val jConfig = 0;
        jConfig = mjson_parse(myconf);
        myajl_val res_servers = 0;
        myajl_val cs_servers = 0;
        if ((*jConfig).IsObject())
        {
            //  qDebug()<<"act server line2 = " << line;
            res_servers = (*jConfig)("reserved_servers");
            cs_servers = (*jConfig)("servers");
            if (cs_servers)
            {
                int jSize = (*cs_servers).GetNumElems();
                St2(2457);
                myajl_val ipsss = 0;
                if (jSize > 0)
                {
                    ipsss = (*cs_servers)[0];
                    if (ipsss)
                    {
                        _csServer = (*ipsss)("ip").GetString();
                    }
                }
            }
            if (res_servers)
            {
                // qDebug()<<"act server line = 3" << line;
                int jSize = (*res_servers).GetNumElems();
                St2(2457);
                myajl_val ipsss = 0;
                for (int i = 0; i < jSize; i++)
                {
                    ipsss = (*res_servers)[i];
                    if (ipsss)
                    {
                        // qDebug()<<"act server line = 4" << line;
                        //_activeServer = ips;
                        _ipList.push_back((*ipsss)("ip").GetString());
                    }
                }
            }
        }
        mjson_free(jConfig);
    }
    else
    {
        //qDebug()<<"ARCHIVE client_settings.json FILE NOT OPENED!!!-----------------------------------------------------------------------------";
    }

    // _ipList
}

void ArchivePlayer::getFullness(QDateTime start, QDateTime finish, QString key2, int scale)
{
        St2_FUNCT_St2(556);
        FullnessRequestParams params{ start, finish, key2, scale };
        if (m_fullnessWatcher.isRunning()) {
                m_pendingFullness = params;
                m_hasPendingFullness = true;
                return;
        }
        startFullnessFuture(params);
}

void ArchivePlayer::startFullnessFuture(const FullnessRequestParams& params)
{
        auto future = QtConcurrent::run(&archivePlayerPool(), [this, params]() {
                executeFullnessRequest(params);
        });
        m_fullnessWatcher.setFuture(future);
}

void ArchivePlayer::executeFullnessRequest(const FullnessRequestParams& params)
{
        videoFullnessReq(params.start, params.finish, params.key2, params.scale);
}

void ArchivePlayer::handleFullnessFinished()
{
        if (m_hasPendingFullness) {
                auto params = m_pendingFullness;
                m_hasPendingFullness = false;
                startFullnessFuture(params);
        }
}

void ArchivePlayer::startArchiveInit()
{
    if (m_initWatcher.isRunning())
        return;
    m_initElapsed.restart();
    // qCDebug(lcArchivePlayerInit)
    //     << "startArchiveInit guiThread"
    //     << (QThread::currentThread() == qApp->thread());
    m_initWatcher.setFuture(sharedArchiveInitFuture());
}

void ArchivePlayer::handleInitFinished()
{
    if (!m_initWatcher.isFinished())
        return;
    // qCDebug(lcArchivePlayerInit)
    //     << "init finished elapsedMs" << m_initElapsed.elapsed()
    //     << "guiThread" << (QThread::currentThread() == qApp->thread());
    applyInitData(m_initWatcher.result());
}

void ArchivePlayer::applyInitData(const ArchiveInitData& data)
{
    _ipList = data.ipList;
    _csServer = data.csServer;
    evtVals = data.evtVals;
    evtNames = data.evtNames;
}
void ArchivePlayer::setFnJson(const QString& newJson) {
    St2_FUNCT_St2(890);
    fnJson = newJson;
}
QString ArchivePlayer::getFnJson()const {
    St2_FUNCT_St2(889);
    return fnJson;
}

void ArchivePlayer::audioFullnessReq(QDateTime start, QDateTime finish, QString key2) {
    QString sStr_ = start.toString("yyyy.MM.dd hh:mm:ss");
    QString fStr_ = finish.toString("yyyy.MM.dd hh:mm:ss");
    myajl_val js_path = ExLisPin::getKey2Path(key2.toUtf8().data());
    char* ip = NULL;
    if (js_path->IsEmpty()) LOGD_TRACE("<%pp> check_archive js_path->IsEmpty()", this);

    iv_uint32 i1, cnt = js_path->GetNumElems();

    if (!cnt || cnt > 4)
        mjson_free(js_path);

    for (i1 = 0; i1 < cnt; i1++) {
        myajl_val v = (*js_path)[i1];
        ip = (*v)("ip").GetString();
        if (!ip)break;
    }
    QString qStr_ip = QString::fromUtf8(ip);
    mjson_free(js_path);
    QString cmd_loc = "{"
        "\"cmd\":\"archive:pass\","
        "\"ip\": \"" + qStr_ip + "\",\n"
        "\"params\":"
        "{"
        "\"key1\": \"\","
        "\"key2\": \"" + key2 + "\","
        "\"key3\": \"\","
        "\"key4\": \"\","
        "\"begin\": \"" + sStr_ + "\","
        "\"end\": \"" + fStr_ + "\","
        "\"view\": \"interv\"," // [not_full_key, interv, progr]
        "\"longer\": 5,"
        "\"type\": \"audio\""
        "}"
        "}";
    int timeout = 5;
    int is_local = 0;
    char* cmd_ = cmd_loc.toUtf8().data();
    // QByteArray cmdBytes = cmd_loc.toUtf8(); // сохраняем объект
    // char* cmd_ = cmdBytes.data();
    // std::string cmdStr = cmd_loc.toStdString();
    // char* cmd_ = const_cast<char*>(cmdStr.c_str());
    param_t p[] =
    {
        {PARAM_PCHAR, "cmd", cmd_},
        {PARAM_PINT32,"timeout", &timeout},
        {PARAM_PVOID, "owner", this},
        {PARAM_PVOID, "owner_data", myOwnerAudio},
        {PARAM_PINT32,"is_local",&is_local},
        {0, 0, 0}
    };
    iv::core::profile_data(_arcAudio_PD, p);
}
void ArchivePlayer::arcAudio_PD_res(const void* udata, const param_t* p)
{
    St2_FUNCT_St2(234461);

    // ДОБАВИТЬ ПРОВЕРКУ В НАЧАЛЕ
    if (udata == nullptr) return;

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
        if (owner != udata) return;

        St2(34451);

        if ((char*)owner_data == myOwnerAudio)
        {
            St2(34461);

            if (json != nullptr && json != QStringLiteral("Timeout")){
                St2(34481);
                ArchivePlayer* parc = (ArchivePlayer*)owner;
                if (!parc->m_alive.load()) {
                    return;
                }

                QString currFnJs = parc->getFnJson();
                QJsonArray obj;
                QJsonDocument doc = QJsonDocument::fromJson(json);
                if (!doc.isNull() && doc.isArray())
                {
                    obj = doc.array();
                    QJsonObject obj2 = obj[0].toObject();
                    if (obj2.contains("res")) {
                        QJsonArray fill_arr = obj2["res"].toArray();
                        if (fill_arr.count() > 0) {
                            for (int i = 0; i < fill_arr.count(); i++) {
                                QJsonArray val = fill_arr[i].toArray();
                                val[0] = 0;
                                // qDebug() << "ArchivePlayer::arcAudio_PD_res val" << val;
                                fill_arr[i] = val;
                            }
                            doc.setArray(fill_arr);
                            QString dataToString(doc.toJson());
                            parc->setFnJson(dataToString);
                            emit parc->fnJsonChanged();
                            return;
                        }
                    }
                }
            }
        }
    }
}

void ArchivePlayer::videoFullnessReq(QDateTime start, QDateTime finish, QString key2, int scale) {
    QString startStr = "";
    QString finishStr = "";
    QString cmd__ = "";
    _startDate = start;
    _endDate = finish;
    myajl_val js_path = ExLisPin::getKey2Path(key2.toUtf8().data());
    char* ip = NULL;
    if (js_path->IsEmpty()) LOGD_TRACE("<%pp> check_archive js_path->IsEmpty()", this);

    iv_uint32 i1, cnt = js_path->GetNumElems();

    if (!cnt || cnt > 4)
        mjson_free(js_path);

    for (i1 = 0; i1 < cnt; i1++) {
        myajl_val v = (*js_path)[i1];
        ip = (*v)("ip").GetString();
        if (!ip)break;
    }
    QString qStr_ip = QString::fromUtf8(ip);
    mjson_free(js_path);
    // Дальше запрос заполненности по текущему масштабу
    switch (scale) {
    case 0:
        //qDebug()<<"ArchivePlayer::getFullness YEAR SCALE";
        startStr = start.toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{\"cmd\":\"archive:pass_graph4\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":{\"key1\": \"\","
            "\"key2\": \"" + key2 + "\","
            "\"key3\": \"\","
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\"}"
            "}";
        break;
    case 1:
        //qDebug()<<"ArchivePlayer::getFullness MONTH SCALE";
        startStr = start.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{"
            "\"cmd\":\"archive:pass_graph_by_corn\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key2\": \"" + key2 + "\","
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"value\": \"week\""
            "}"
            "}";
        break;
    case 2:
        //qDebug()<<"ArchivePlayer::getFullness WEEK SCALE";
        startStr = start.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toUTC().toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{"
            "\"cmd\":\"archive:pass_graph_by_corn\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key2\": \"" + key2 + "\","
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"value\": \"day\""
            "}"
            "}";
        break;
    case 3:
        //qDebug()<<"ArchivePlayer::getFullness DAY SCALE";
        startStr = start.toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toString("yyyy.MM.dd hh:mm:ss");
        //qDebug()<<startStr << finishStr;
        cmd__ = "{"
            "\"cmd\":\"archive:intervals\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key1\": \"\","
            "\"key2\": \"" + key2 + "\","
            "\"key3\": \"\","
            "\"key4\": \"\","
            "\"cam_id\": 0,"
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"longer\": 3600,"
            "\"type\": \"video\""
            "}"
            "}";
        break;
    case 4:
        //qDebug()<<"ArchivePlayer::getFullness HOUR SCALE";
        startStr = start.toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{"
            "\"cmd\":\"archive:intervals\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key1\": \"\","
            "\"key2\": \"" + key2 + "\","
            "\"key3\": \"\","
            "\"key4\": \"\","
            "\"cam_id\": 0,"
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"longer\": 30,"
            "\"type\": \"video\""
            "}"
            "}";
        break;
    case 5:
        //qDebug()<<"ArchivePlayer::getFullness 30 MIN SCALE";
        startStr = start.toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{"
            "\"cmd\":\"archive:intervals\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key1\": \"\","
            "\"key2\": \"" + key2 + "\","
            "\"key3\": \"\","
            "\"key4\": \"\","
            "\"cam_id\": 0,"
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"longer\": 15,"
            "\"type\": \"video\""
            "}"
            "}";
        break;
    case 6:
        //qDebug()<<"ArchivePlayer::getFullness 10 MIN SCALE";
        startStr = start.toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{"
            "\"cmd\":\"archive:intervals\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key1\": \"\","
            "\"key2\": \"" + key2 + "\","
            "\"key3\": \"\","
            "\"key4\": \"\","
            "\"cam_id\": 0,"
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"longer\": 5,"
            "\"type\": \"video\""
            "}"
            "}";
        break;
    case 7:
        //qDebug()<<"ArchivePlayer::getFullness MINUTE SCALE";
        startStr = start.toString("yyyy.MM.dd hh:mm:ss");
        finishStr = finish.toString("yyyy.MM.dd hh:mm:ss");
        cmd__ = "{"
            "\"cmd\":\"archive:intervals\","
            "\"ip\": \"" + qStr_ip + "\",\n"
            "\"params\":"
            "{"
            "\"key1\": \"\","
            "\"key2\": \"" + key2 + "\","
            "\"key3\": \"\","
            "\"key4\": \"\","
            "\"cam_id\": 0,"
            "\"begin\": \"" + startStr + "\","
            "\"end\": \"" + finishStr + "\","
            "\"longer\": 1,"
            "\"type\": \"video\""
            "}"
            "}";
        break;
    }
    if (cmd__ != "")
    {
        int timeout = 2;
        int is_local = 0;
        QByteArray b = cmd__.toUtf8();
        char* _cmd = b.data();
        param_t p2[] =
        {
            {PARAM_PCHAR, "cmd", _cmd},
            {PARAM_PINT32,"timeout", &timeout},
            {PARAM_PVOID, "owner", this},
            {PARAM_PVOID, "owner_data", myOwnerVideo},
            {PARAM_PINT32,"is_local",&is_local},
            {0, 0, 0}
        };
        iv::core::profile_data(_arcVideo_PD, p2);
    }
}
void ArchivePlayer::arcVideo_PD_res(const void* udata, const param_t* p)
{
    if (udata == nullptr) return;

    St2_FUNCT_St2(23446);
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
        if ((owner != udata) || (owner_data == nullptr))
            return;

        St2(3445);

        ArchivePlayer* parc = static_cast<ArchivePlayer*>(owner);
        if (parc == nullptr || !parc->m_alive.load()) {
            return;
        }

        if ((char*)owner_data == myOwnerVideo)
        {
            St2(3446);
            if (json != nullptr && json != QStringLiteral("Timeout"))
            {
                St2(3448);
                QJsonArray obj;
                QJsonDocument doc = QJsonDocument::fromJson(json);
                if (!doc.isNull())
                {
                    if (doc.isArray())
                    {
                        obj = doc.array();
                        QJsonArray fill_arr;
                        // если ответ на pass_graph4 или pass_graph_by_corn
                        if (obj[0].toArray()[0].toObject().contains("fill")) {
                            if (parc->archType >= MAX_ARCH_TYPE || parc->archType < 0) {
                                QDateTime currDT_1 = parc->currentDate().addSecs(-300);
                                QDateTime currDT_2 = parc->currentDate().addSecs(300);
                                //qDebug()<< "1) Масштаб Год-Неделя, но качество неизвестно, запрашиваем...";
                                //qDebug()<< "1)" << currDT_1.toString("yyyy-MM-dd hh:mm:ss") << currDT_2.toString("yyyy-MM-dd hh:mm:ss") << parc->_Key2;
                                parc->videoFullnessReq(currDT_1, currDT_2, parc->_Key2, 3);
                                return;
                            }
                            fill_arr = obj[0].toArray()[0].toObject()["fill"].toArray();
                            for (int i = 0; i < fill_arr.count(); i++) {
                                QJsonObject val = fill_arr[i].toObject();
                                val.insert("colorType", parc->archType);
                                fill_arr[i] = val;
                            }
                        }
                        // если ответ на intervals
                        else if (obj[0].toObject().contains("res")) {
                            fill_arr = obj[0].toObject()["res"].toArray();
                            for (int i = 0; i < fill_arr.size(); i++) {
                                QJsonArray val = fill_arr[i].toArray();
                                int val_0 = val[0].toVariant().toInt();
                                if (val_0 > 60) val[0] = 2;
                                else if (val_0 > 2 && val_0 <= 60) val[0] = 1;
                                else val[0] = val_0;
                                fill_arr[i] = val;

                                //тут обновим значение качества(типа) архива
                                if (parc->archType >= MAX_ARCH_TYPE || parc->archType < 0) {
                                    //qDebug()<< "2) Масштаб Неделя-Минута, но качество неизвестно, устанавливаем из ответа";
                                    //qDebug()<< "2)" << val[0].toInt();
                                    parc->archType = val[0].toInt();
                                }
                            }
                        }
                        else {
                            parc->setFnJson("");
                            emit parc->fnJsonChanged();
                            return;
                        }

                        if (fill_arr.size() == 0) {
                            parc->audioFullnessReq(parc->_startDate, parc->_endDate, parc->_Key2);
                            return;
                        }
                        doc.setArray(fill_arr);
                        QString dataToString(doc.toJson());
                        parc->setFnJson(dataToString);
                        emit parc->fnJsonChanged();
                        return;
                    }
                }
            }
            parc->setFnJson("");
            emit parc->fnJsonChanged();
            return;
        }
    }
}
uint64_t addEvents(std::vector<::iv::ewriter::table::eventt>* events, std::string* _res, uint64_t skipTime) {
    uint64_t var = 0;
    if (events->size() > 0) {
        int firstSkipable = 1;
        for (size_t i = 0; i < events->size(); i++) {
            QString startTimeStr = events->at(i).time.c_str();
            QDateTime startTime = QDateTime::fromString(startTimeStr, "yyyy-MM-dd hh:mm:ss.zzz");
            if (i > 0) {
                QDateTime nextTime = QDateTime::fromString(events->at(i - firstSkipable).time.c_str(), "yyyy-MM-dd hh:mm:ss.zzz");
                if (nextTime.toMSecsSinceEpoch() - skipTime < startTime.toMSecsSinceEpoch()) {
                    firstSkipable++;
                    continue;
                }
                else firstSkipable = 1;
            }
            startTime.setTimeSpec(Qt::UTC);
            startTime = startTime.toLocalTime();
            // std::string sTimeStr = startTime.toString("yyyy-MM-dd hh:mm:ss.zzz").toUtf8().data();
            std::string sTimeStr = startTime.toString("yyyy-MM-dd hh:mm:ss.zzz").toStdString();

            uint64_t startId = events->at(i).id;
            uint64_t startTypeId = events->at(i).ttypeid;

            QString stopTimeStr = events->at(i).time.c_str();
            QDateTime stopTime = QDateTime::fromString(stopTimeStr, "yyyy-MM-dd hh:mm:ss.zzz");
            bool foundStopId = false;
            for (size_t j = 0; j < events->size(); j++) {
                if (events->at(j).id == startId + 1 && events->at(j).ttypeid == startTypeId + 1) {
                    foundStopId = true;
                    stopTimeStr = events->at(j).time.c_str();
                    stopTime = QDateTime::fromString(stopTimeStr, "yyyy-MM-dd hh:mm:ss.zzz");
                    break;
                }
            }
            if (!foundStopId) stopTime = stopTime.addSecs(4);

            stopTime.setTimeSpec(Qt::UTC);
            stopTime = stopTime.toLocalTime();
            std::string fTimeStr = stopTime.toString("yyyy-MM-dd hh:mm:ss.zzz").toUtf8().data();

            events->at(i).ttype_str.erase(std::remove(events->at(i).ttype_str.begin(), events->at(i).ttype_str.end(), '\\'), events->at(i).ttype_str.end());
            events->at(i).ttype_str.erase(std::remove(events->at(i).ttype_str.begin(), events->at(i).ttype_str.end(), '\"'), events->at(i).ttype_str.end());
            std::string _row = "{\"comment\":\"" + events->at(i).ttype_str + "\",\"typeid\":\"" + std::to_string(events->at(i).ttypeid) + "\",\"s\":\"" + sTimeStr + "\",\"f\":\"" + fTimeStr + "\"";

            _row.append("},");
            _res->append(_row);
            var++;
        }
    }
    return var;
}

void eventsThread(void* data)
{
    St2_FUNCT_St2(2017);
    ArchivePlayer* _this = (ArchivePlayer*)data;

    if (!_this || _this->_threadEnd || !_this->m_alive.load()) {
        return;
    }

    St2(230055);
    ////
    _this->cs.lock();
    _this->_ev_thread_isRunning = true;
    if (_this->stop_evThread) {
        _this->_ev_thread_isRunning = false;
        // qDebug() << "Exit events thread";
        _this->cs.unlock();
        return;
    }
    std::vector<std::string> ipList = _this->_ipList;
    QDateTime startTime = _this->startEvtTime;
    QDateTime endTime = _this->finishEvtTime;
    QString key2 = _this->_Key2;
    uint64_t skipTime = _this->_skipTime;
    std::list<QVariant> evtTypesList = _this->evtVals.toStdList();
    _this->cs.unlock();
    ////

    iv::ws::call_interrupt intr;
    iv::ewriter::call cl(intr, 20000);
    std::vector<::iv::ewriter::table::eventt> events;
    int page_size = 1000;
    events.reserve(page_size);

    std::vector<iv::ewriter::table::eventtype> evtVals;
    int rv = cl.eventtypes_list(evtVals);
    ////
    _this->cs.lock();
    if (evtVals.size() == 0 || _this->stop_evThread) {
        _this->_ev_thread_isRunning = false;
        // qDebug() << "Exit events thread or evtVals list is empty";
        _this->cs.unlock();
        return;
    }
    _this->cs.unlock();
    ////

    // формируем фильтр
    iv::ewriter::filter fl("and");

    // добавляем фильтрацию по времени
    QString _tBeg = startTime.toUTC().toString("yyyy-MM-dd hh:mm:ss.zzz");
    QString _tEnd = endTime.toUTC().toString("yyyy-MM-dd hh:mm:ss.zzz");
    fl.add_time_from_to(_tBeg.toStdString(), _tEnd.toStdString());

    /*
    // добавляем фильтрацию по айди
    std::vector<int64_t> vals;
    for (auto _event : evtVals) {
        if (_event.groupid == 6 || _event.groupid == 2)
        {
            vals.push_back(_event.id);
        }
    };
    fl.group.push_back(iv::ewriter::filter("evttypeid", "=", vals));
    */

    // Создаем массив для фильтра по типам отображаемых событий
    std::vector<int64_t> evtTypesVector;
    for (auto const& i : evtTypesList) {
        evtTypesVector.push_back(i.toLongLong());
    }
    fl.group.push_back(iv::ewriter::filter("evttypeid", "=", evtTypesVector));

    // добавляем фильтрацию по кей2
    std::string c_key2 = key2.toStdString();
    fl.group.push_back(iv::ewriter::filter("evtdevkey2", "=", c_key2.c_str()));

    iv_int64 last_event_id = 0;
    std::string last_event_time;
    int event_list_res = -1;

    St2(23000);
    event_list_res = cl.events_list(fl, events, page_size, true);
    if (event_list_res < 0) {
        for (int i = 0; i < ipList.size(); i++) {
            event_list_res = cl.events_list(fl, events, page_size, true, last_event_id, last_event_time);
            if (event_list_res >= 0) {
                // qDebug() << "EVENTS FROM IP =" << ipList[i].c_str() << " RESULT = " << event_list_res;
                break;
            }
        }
    }
    if (event_list_res == -3) {
        _this->cs.lock();
        _this->_ev_thread_isRunning = false;
        // qDebug() << "Exit events thread lost connection";
        _this->cs.unlock();
        return;
    }

    St2(23001);
    std::string _res = "[";
    uint64_t eventsCount = 0;
    eventsCount += addEvents(&events, &_res, skipTime);

    bool all_rows_get = false;
    while (!all_rows_get && event_list_res == iv::ws::RC_SUCCESS)
    {
        ////
        _this->cs.lock();
        if (_this->stop_evThread) {
            _this->_ev_thread_isRunning = false;
            // qDebug() << "Exit events thread";
            _this->cs.unlock();
            return;
        }
        _this->cs.unlock();
        ////
        if (last_event_time.empty()) {
            if (events.size() < page_size) {
                all_rows_get = true;
                break;
            }
            iv::ewriter::table::eventt& evt = events[events.size() - 1];
            last_event_id = evt.id;
            last_event_time = evt.time;
        }
        events.clear();
        fl.set_time_from(true, last_event_id, last_event_time);
        event_list_res = cl.events_list(fl, events, page_size, true, last_event_id, last_event_time);
        if (event_list_res == iv::ws::RC_SUCCESS) {
            eventsCount += addEvents(&events, &_res, skipTime);
        }
    }

    St2(23002);
    if (_res.size() > 1) _res = _res.substr(0, _res.size() - 1);
    _res.append("]");
    QString __res = _res.c_str();

    ////
    _this->cs.lock();
    if (_this->stop_evThread) {
        _this->_ev_thread_isRunning = false;
        // qDebug() << "Exit events thread";
        _this->cs.unlock();
        return;
    }
    _this->setEventsStr(__res);
    _this->_ev_thread_isRunning = false;
    emit _this->evJsonChanged();
    _this->cs.unlock();
    ////
    // qDebug() << "events count" << eventsCount;
    // qDebug() << "Exit events thread";
    return;
}
void threadVoid(void* data)
{
    St2_FUNCT_St2(56742);
    // qDebug() << "STARTING EVENTS THREAD";
    ArchivePlayer* ctx = (ArchivePlayer*)data;

    // ДОБАВИТЬ ПРОВЕРКУ
    if (!ctx || ctx->_Key2 == "" || ctx->_threadEnd || !ctx->m_alive.load()) {
        return;
    }

    ////
    ctx->cs.lock();
    ctx->_ev_thread_isRunning = true;
    // const char* key2 = ctx->_Key2.toUtf8().data();
    iv_uint64 t1 = (ctx->startEvtTime.toMSecsSinceEpoch() * 1000);
    iv_uint64 t2 = (ctx->finishEvtTime.toMSecsSinceEpoch() * 1000);
    std::list<QVariant> evtTypesList = ctx->evtVals.toStdList();
    if (evtTypesList.size() == 0 || ctx->stop_evThread) {
        ctx->_ev_thread_isRunning = false;
        // qDebug() << "EXITING EVENTS THREAD or eventTypes list is empty";
        ctx->cs.unlock();
        return;
    }
    ctx->cs.unlock();
    ////

    // Создаем массив для фильтра по типам отображаемых событий
    std::vector<uint64_t> evtTypesVector;
    for (auto const& i : evtTypesList) {
        evtTypesVector.push_back(i.toULongLong());
    }
    uint64_t* evtTypesArray = &evtTypesVector[0];
    evtTypesList.clear();
    std::string key2Str = ctx->_Key2.toStdString();
    std::shared_ptr<BandEvents> evt_band = std::make_shared<BandEvents>(t1, t2, evtTypesVector.size(), evtTypesArray, key2Str.c_str());
    // std::shared_ptr<BandEvents> evt_band = std::make_shared<BandEvents>(t1, t2, evtTypesVector.size(), evtTypesArray, key2);

    iv_uint64 t_evt;
    iv_uint32 type_evt;
    std::vector<std::string> _list_events;
    QDateTime tt;
    QString comment;
    std::string type, sTimeStr, fTimeStr;
    QJsonArray json;
    QJsonObject obj;

    while (evt_band->isSupported() == -1) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    if (evt_band->isSupported() == 0) {
        // qDebug() << "evt_band->isSupported() == 0";
        evt_band.reset();
        ctx->cs.lock();
        ctx->_newEvents_isSupported = 0;
        ctx->_ev_thread_isRunning = false;
        ctx->cs.unlock();
        // qDebug() << "EXITING EVENTS THREAD isSupported = 0";
        return;
    }
    ctx->cs.lock();
    ctx->_newEvents_isSupported = 1;
    ctx->cs.unlock();

    while (evt_band->getStatus() == 1) {
        ////
        ctx->cs.lock();
        if (ctx->stop_evThread) {
            ctx->_ev_thread_isRunning = false;
            // qDebug() << "EXITING EVENTS THREAD";
            ctx->cs.unlock();
            return;
        }
        ctx->cs.unlock();
        ////
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    iv_uint32 cnt_ev = evt_band->getCountEvent();


    for (iv_uint32 i = 0; i < cnt_ev; i++) {
        ////
        ctx->cs.lock();
        if (ctx->stop_evThread) {
            ctx->_ev_thread_isRunning = false;
            // qDebug() << "EXITING EVENTS THREAD";
            ctx->cs.unlock();
            return;
        }
        ctx->cs.unlock();
        ////
        evt_band->setIndexEvent(i);  //вначале устанавливаем индекс события
        t_evt = evt_band->getEventime64();
        type_evt = evt_band->getEventtypeid();
        tt = QDateTime::fromMSecsSinceEpoch((t_evt / 1000));
        sTimeStr = tt.toString("yyyy-MM-dd hh:mm:ss.z").toUtf8().data();
        tt = tt.addSecs(4);
        fTimeStr = tt.toString("yyyy-MM-dd hh:mm:ss.z").toUtf8().data();
        type = std::to_string(type_evt);

        ctx->cs.lock();
        comment = ctx->getEvtDescription(type_evt).toString();
        ctx->cs.unlock();

        obj.insert("comment", comment);
        obj.insert("typeid", type.c_str());
        obj.insert("s", sTimeStr.c_str());
        obj.insert("f", fTimeStr.c_str());
        json.append(obj);
    }
    iv_int32 ret = evt_band->getRightEvent();
    while (evt_band->getStatus() == 1) {
        ////
        ctx->cs.lock();
        if (ctx->stop_evThread) {
            ctx->_ev_thread_isRunning = false;
            // qDebug() << "EXITING EVENTS THREAD";
            ctx->cs.unlock();
            return;
        }
        ctx->cs.unlock();
        ////
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    t_evt = evt_band->getRightEventime64();
    type_evt = evt_band->getRightEventtypeid();

    tt = QDateTime::fromMSecsSinceEpoch((t_evt / 1000));
    sTimeStr = tt.toString("yyyy-MM-dd hh:mm:ss.z").toUtf8().data();
    tt = tt.addSecs(4);
    fTimeStr = tt.toString("yyyy-MM-dd hh:mm:ss.z").toUtf8().data();
    type = std::to_string(type_evt);

    ctx->cs.lock();
    comment = ctx->getEvtDescription(type_evt).toString();
    ctx->cs.unlock();

    obj.insert("comm", comment);
    obj.insert("typeid", type.c_str());
    obj.insert("s", sTimeStr.c_str());
    obj.insert("f", fTimeStr.c_str());
    json.append(obj);

    iv_int32 ret2 = evt_band->getLeftEvent();
    while (evt_band->getStatus() == 1) {
        ////
        ctx->cs.lock();
        if (ctx->stop_evThread) {
            ctx->_ev_thread_isRunning = false;
            // qDebug() << "EXITING EVENTS THREAD";
            ctx->cs.unlock();
            return;
        }
        ctx->cs.unlock();
        ////
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    t_evt = evt_band->getLeftEventime64();
    type_evt = evt_band->getLeftEventtypeid();
    //comm = evt_band->getEventtype_str();
    tt = QDateTime::fromMSecsSinceEpoch((t_evt / 1000));
    sTimeStr = tt.toString("yyyy-MM-dd hh:mm:ss.z").toUtf8().data();
    tt = tt.addSecs(4);
    fTimeStr = tt.toString("yyyy-MM-dd hh:mm:ss.z").toUtf8().data();
    type = std::to_string(type_evt);
    ctx->cs.lock();
    comment = ctx->getEvtDescription(type_evt).toString();
    ctx->cs.unlock();

    obj.insert("comm", comment);
    obj.insert("typeid", type.c_str());
    obj.insert("s", sTimeStr.c_str());
    obj.insert("f", fTimeStr.c_str());
    json.push_front(obj);

    // Формируем json строку событий
    QJsonDocument j_doc(json);
    ////
    ctx->cs.lock();
    if (ctx->stop_evThread) {
        ctx->_ev_thread_isRunning = false;
        // qDebug() << "EXITING EVENTS THREAD";
        ctx->cs.unlock();
        return;
    }
    ctx->setEventsStr(j_doc.toJson());
    ctx->_ev_thread_isRunning = false;
    emit ctx->evJsonChanged();
    ctx->cs.unlock();
    ////
    // qDebug() << "EXITING EVENTS THREAD";
}

void ArchivePlayer::getEvents(QDateTime start, QDateTime finish, quint64 skipTime, QString key2, int scale)
{
        St2_FUNCT_St2(23465);
        EventsRequestParams params{ start, finish, skipTime, key2, scale };
        if (m_eventsWatcher.isRunning()) {
                m_pendingEvents = params;
                m_hasPendingEvents = true;
                return;
        }
        startEventsFuture(params);
}

void ArchivePlayer::startEventsFuture(const EventsRequestParams& params)
{
        auto future = QtConcurrent::run(&archivePlayerPool(), [this, params]() {
                executeEventsRequest(params);
        });
        m_eventsWatcher.setFuture(future);
}

void ArchivePlayer::handleEventsFinished()
{
        if (m_hasPendingEvents) {
                auto params = m_pendingEvents;
                m_hasPendingEvents = false;
                startEventsFuture(params);
        }
}

void ArchivePlayer::executeEventsRequest(const EventsRequestParams& params)
{
        // qDebug() << "ArchivePlayer::getEvents()";
        _Key2 = params.key2;
        this->scale = params.scale;
        startEvtTime = params.start;
        finishEvtTime = params.finish;
        _skipTime = params.skipTime;

        bool threadIsRunning;
        cs.lock();
        threadIsRunning = _ev_thread_isRunning;
        cs.unlock();
        if (threadIsRunning) {
                // qDebug() << "EventsThread is run, wait for end threads";
                cs.lock();
                stop_evThread = true;
                cs.unlock();
                bool exit = !threadIsRunning;
                while (!exit) {
                        cs.lock();
                        threadIsRunning = _ev_thread_isRunning;
                        cs.unlock();
                        std::this_thread::sleep_for(std::chrono::milliseconds(200));
                        exit = !threadIsRunning;
                }
        }
        if (_threadEnd) return;
        else {
                cs.lock();
                stop_evThread = false;
                cs.unlock();
        }
        // qDebug() << "Skip event when time between them more" << _skipTime << "ms";

        if (!m_alive.load()) {//????
            return;
        }

        if (_newEvents_isSupported < 0) {
                threadVoid(this);
                if (_newEvents_isSupported < 0 || _newEvents_isSupported) return;
        }

        if (_ev_thread.joinable()) {
            // _stopEventThread = true;
            _ev_thread.join();
            // _stopEventThread = false;
        }

        if (_newEvents_isSupported) {
                _ev_thread = std::thread(threadVoid, this);
                // _ev_thread.detach();
        }
        else {
                _ev_thread = std::thread(eventsThread, this);
                // _ev_thread.detach();
        }
}
void ArchivePlayer::setEventsStr(const QString& newJson) {
    St2_FUNCT_St2(890);
    //    std::ostringstream ss;
    //    ss << std::this_thread::get_id();
    //    std::string idstr = ss.str();
    //    qDebug()<< "ArchivePlayer::setEventsStr" << "thread id" << QString::fromStdString(idstr);
    _eventsStr = newJson;
}
QString ArchivePlayer::getEventsStr()const {
    St2_FUNCT_St2(8829);
    //qDebug()<<"getEventsStr = " << _eventsStr;
    return _eventsStr;
}

void ArchivePlayer::setIsNewStrip(bool b) {
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
    isNewStrip = b;
    if (b) {
        QElapsedTimer timer;
        timer.start();
        archType = MAX_ARCH_TYPE;
        _threadEnd = false;
        if (_arcVideo_PD != nullptr) {
            iv::core::profile_close(_arcVideo_PD);
            _arcVideo_PD = nullptr;
        }
        if (_arcVideo_PD_result != nullptr) {
            iv::core::profile_close(_arcVideo_PD_result);
            _arcVideo_PD_result = nullptr;
        }
        callback_t cb111 = { this,arcVideo_PD_res };
        iv::core::profile_open(_arcVideo_PD, "trackWsServerCmd", 0, __FILE__, __LINE__);
        iv::core::profile_open(_arcVideo_PD_result, "trackWsServerData", &cb111, __FILE__, __LINE__);

        if (_arcAudio_PD != nullptr) {
            iv::core::profile_close(_arcAudio_PD);
            _arcAudio_PD = nullptr;
        }
        if (_arcAudio_PD_result != nullptr) {
            iv::core::profile_close(_arcAudio_PD_result);
            _arcAudio_PD_result = nullptr;
        }
        callback_t cb222 = { this,arcAudio_PD_res };
        iv::core::profile_open(_arcAudio_PD, "trackWsServerCmd", 0, __FILE__, __LINE__);
        iv::core::profile_open(_arcAudio_PD_result, "trackWsServerData", &cb222, __FILE__, __LINE__);

        startArchiveInit();
        // qCDebug(lcArchivePlayerInit)
        //     << "setIsNewStrip init elapsedMs" << timer.elapsed()
        //     << "guiThread" << (QThread::currentThread() == qApp->thread());
    }
}


QVariant ArchivePlayer::getEvtDescription(quint64 val) {
    for (int i = 0; i < evtVals.size(); i++) {
        if (evtVals.at(i) == val) {
            return evtNames.at(i);
        }
    }
    return "";
}

ArchivePlayer::ArchivePlayer()
{
        QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
        _left_bound = 0;
        _right_bound = 0;
        _x = 0.0;
        _y = 0.0;
        iv_core_profile_open(_track_windows_command, "track_windows_command_qml");
        // qCDebug(lcArchivePlayerInit)
        //     << "ArchivePlayer ctor guiThread"
        //     << (QThread::currentThread() == qApp->thread());
        connect(&m_eventsWatcher, &QFutureWatcher<void>::finished, this, &ArchivePlayer::handleEventsFinished);
        connect(&m_fullnessWatcher, &QFutureWatcher<void>::finished, this, &ArchivePlayer::handleFullnessFinished);
        connect(&m_initWatcher, &QFutureWatcher<ArchiveInitData>::finished, this, &ArchivePlayer::handleInitFinished);
}
ArchivePlayer::~ArchivePlayer()
{
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);

    m_alive = false;

    _threadEnd = true;
    stop_thread();
    if (m_eventsWatcher.isRunning()) {
            m_eventsWatcher.waitForFinished();
    }
    if (m_fullnessWatcher.isRunning()) {
            m_fullnessWatcher.waitForFinished();
    }
    if (_track_windows_command)
    {
            iv_core_profile_close(_track_windows_command);
            _track_windows_command = nullptr;
    }

    if (_ev_thread.joinable()) {
        // _stopEventThread = true;
        _ev_thread.join();
    }

    if (_arcVideo_PD)
    {
        iv::core::profile_close(_arcVideo_PD);
        _arcVideo_PD = nullptr;
    }
    if (_arcAudio_PD)
    {
        iv::core::profile_close(_arcAudio_PD);
        _arcAudio_PD = nullptr;
    }
    if (_arcVideo_PD_result)
    {
        iv::core::profile_close(_arcVideo_PD_result);
        _arcVideo_PD_result = nullptr;
    }
    if (_arcAudio_PD_result)
    {
        iv::core::profile_close(_arcAudio_PD_result);
        _arcAudio_PD_result = nullptr;
    }
    if (isNewStrip) {
        bool threadIsRunning = false;
        cs.lock();
        threadIsRunning = _ev_thread_isRunning;
        cs.unlock();
        if (threadIsRunning) {
            // qDebug() << "EventsThread is run, wait for end threads";
            cs.lock();
            stop_evThread = true;
            cs.unlock();
            std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        }
        cs.lock();
        threadIsRunning = _ev_thread_isRunning;
        cs.unlock();
    }
}

void ArchivePlayer::createExprogressWindow()
{
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
    int isSimpleClosing = 1;

    char* wnd_properties = (char*)malloc(2048);
    memset(wnd_properties, 0, 2048);

    sprintf(wnd_properties,
        "{"
        "\n \"qml\" : \"%s\","
        "\n \"unique\" : \"%s\","
        "\n \"sender\" : \"%s\","
        "\n \"cmd\" : \"%s\","
        "\n \"topmost\" : true,"
        "\n \"isSimpleClosing\" : true"
        "\n }",
        "/qtplugins/iv/exprogress/Exprogress.qml", "exprogress.window.", "WindowsCreator", "windows:add");

    param_t p[] = {
        {PARAM_PCHAR, "properties", wnd_properties},
        {PARAM_PCHAR, "cmd", "windows:add"},
        //{PARAM_PCHAR, "qml", "/qtplugins/iv/exprogress/Exprogress.qml"},
        //{PARAM_PCHAR, "unique", "exprogress.window."},
        //{PARAM_PCHAR, "sender", "WindowsCreator"},
        //{PARAM_PINT32,"isSimpleClosing", &isSimpleClosing},
        {0,0,0}
    };
    iv_core_profile_data(_track_windows_command, p);

    if (wnd_properties)
    {
        free(wnd_properties);
        wnd_properties = NULL;
    }
    //iv_core_profile_open(_track_windows_command, "track_windows_command_qml");
}

void ArchivePlayer::start_thread2(QString key2, qint64 frame_time, qreal x, qreal y)
{
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
    stop_thread();
    _key2 = key2;
    cs.lock();
    _frame_time = frame_time * 1000;
    _x = x;
    _y = y;
    cs.unlock();
    _succes = false;
    //qDebug() << "start_thread2 _key2 = " << _key2;
    LOGD_TRACE("start_thread2 _key2 = %lld", _key2.toUtf8().data());

    // _t = std::thread(get_cache_data2, this);
    _thread = std::make_unique<QThread>();
    auto threadFunc = [this]() {
        get_cache_data2(this);
    };
    connect(_thread.get(), &QThread::started, threadFunc);
    connect(_thread.get(), &QThread::finished, _thread.get(), &QThread::deleteLater);
    _thread->start();
}
void ArchivePlayer::stop_thread()
{
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
    LOGD_TRACE("stop_thread {");
    if (_thread && _thread->isRunning())
    {
        cs.lock();
        _finish_thread = true;
        cs.unlock();

        _thread->quit();
        _thread->wait();
        _thread.release()->deleteLater();

        //_finish_thread = false;
        _left_bound = 0;
        _right_bound = 0;
        //_key2 = "";
        _succes = false;
        _count_preview = 0;
    }
    LOGD_TRACE("stop_thread }");
}

void get_cache_data2(void* udata)
{
    LOGD_TRACE("get_cache_data2 {");
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
    if (!udata)
    {
        LOGD_TRACE("get_cache_data2 }");
        return;
    }

    ArchivePlayer* ctx = (ArchivePlayer*)udata;
    if (!ctx || !ctx->m_alive.load()) {
        return;
    }

    QString key2Copy;
    {
        std::lock_guard<std::mutex> lock(ctx->cs);
        key2Copy = ctx->_key2;
    }
    QByteArray barr_key2 = key2Copy.toUtf8();
    // QByteArray barr_key2 = ctx->_key2.toUtf8();
    ctx->cs.lock();
    qint64 time = ctx->_frame_time;
    ctx->cs.unlock();
    bool finish = false;
    ctx->_succes = false;

    LOGD_TRACE("get_cache_data2 ::iv::arc_frame_cash::get_frame_on_time_client2 before key2=%s %pp time=%lld", barr_key2.data(), ctx, time);
    ::iv::arc_frame_cash::get_frame_on_time_client2(barr_key2.data(), time, 1, ctx, ctx, get_frame_on_time_cb2);
    LOGD_TRACE("get_cache_data2 ::iv::arc_frame_cash::get_frame_on_time_client2 after key2=%s %pp time=%lld", barr_key2.data(), ctx, time);

    do {
        ctx->cs.lock();
        finish = ctx->_finish_thread;
        if (ctx->_finish_thread)
            ctx->_finish_thread = false;
        ctx->cs.unlock();

        if (finish)
        {
            break;
        }
    } while (!ctx->_succes);

    LOGD_TRACE("get_cache_data2 }");
}

void get_frame_on_time_cb2(const void* owner, const void* owner_data, param_t* p)
{
    QARC_FUNC(QARC_MODULE_QARCHIVEPLAYER);
    LOGD_TRACE("get_frame_on_time_cb2 {");

    ArchivePlayer* parc = (ArchivePlayer*)owner;

    if (!parc || !parc->m_alive.load()) {
        LOGD_TRACE("get_frame_on_time_cb2: object dead or null");
        return;
    }

    const char* json = NULL;
    param_t* pframe = NULL;
    char* status = NULL;
    uint64_t time = 0;
    buffer_t data = { 0 };
    FILE* file = NULL;
    QImage image;
    qint8 error_status = 1;
    qreal x = 0;
    qreal y = 0;

    for (each_param(p))
    {
        param_start;
        param_get_param(pframe, "frame");
        param_get_uint64(time);
        param_get_pchar(status);
    }

    for (each_param(pframe))
    {
        param_start;
        param_get_buffer(data);
    }

    if (json)
    {
        LOGD_TRACE("<%pp> get_frame_on_time_cb2 json = %s", parc, json);
    }

    if (pframe)
    {
        parc->cs.lock();

        x = parc->_x;
        y = parc->_y;

        QString image2 = "";
        if (data.size > 0)
        {
            std::string format = "jpeg";
            image.loadFromData((const uchar*)data.data, data.size, format.c_str());
            QByteArray bArray;
            QBuffer buffer(&bArray);
            buffer.open(QIODevice::WriteOnly);
            bool retval = image.save(&buffer, "JPEG");
            image2.append("image://previewer/");
            image2.append(QString::fromLatin1(bArray.toBase64().data()));
            buffer.close();
            //qDebug() << "image2="<<image2.length();
        }
        parc->cs.unlock();

        emit parc->drawPreviewQML
        (
            (qreal)x,
            (qreal)y,
            image2
        );
    }
    else
    {
        QString image2 = "";
        error_status = -1;

        parc->cs.lock();
        x = parc->_x;
        y = parc->_y;
        parc->cs.unlock();

        //qDebug() << "image2__="<<image2.length();
        emit parc->drawPreviewQML
        (
            (qreal)x,
            (qreal)y,
            image2
        );
    }
    parc->_succes = true;
    LOGD_TRACE("get_frame_on_time_cb2 }");
}
