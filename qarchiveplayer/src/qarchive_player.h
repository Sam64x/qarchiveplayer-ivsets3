#ifndef QARCHIVE_PLAYER_H
#define QARCHIVE_PLAYER_H

#include <QQmlApplicationEngine>
#include <QDebug>
#include <QDateTime>
#include <QThreadPool>
#include <QImage>
#include <QFutureWatcher>

#include "iv_autoloader.h"
#include <iv_log3.h>
#include <iv_core.h>
#include <iv_stable.h>

#include <iv_mjson.h>
#include "external_listener_pinger.h"
#include <iv_ewriter.h>
//#include <iv_ewriter_no_std.h>
#include <iv_ws.h>
#include "iv_cs.h"
#include "QJsonDocument"
#include "QJsonObject"
#include "QJsonArray"

#define QARC_FUNC(id) St2_FUNCT_St2(id + __COUNTER__)
#define QARC_METKA(id) St2(id + __COUNTER__)
#define QARC_MODULE_QARCHIVEPLAYER    7500

#define MAX_ARCH_TYPE 3
//      0 - звук
//      1 - низкое качество (видео/видео+звук)
//      2 - высокое качество (видео/видео+звук)
//      3 - неизвестный тип (или ошибка обработки)

class ArchivePlayer: public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE void createExprogressWindow();
    Q_INVOKABLE void setScale(int value);
    Q_INVOKABLE void dt(quint64 t);
    Q_INVOKABLE QString dt_minutes(quint64 t);
    Q_INVOKABLE QString dt_10min_hours(quint64 t);
    Q_INVOKABLE QString u64_to_qstr_time( quint64 q_time_av);
    Q_INVOKABLE qint64 u64_time_now();
    Q_INVOKABLE QString dt_weeks(quint64 t);

    Q_PROPERTY(QDateTime currentDate READ currentDate WRITE setCurrentDate NOTIFY currentDateChanged)
    QDateTime _currentDate;
    QDateTime currentDate(){return _currentDate;}
    void setCurrentDate(QDateTime date){_currentDate = date;}
    Q_SIGNAL void currentDateChanged();

    // события по архиву
    Q_INVOKABLE void getEvents(QDateTime start, QDateTime finish, quint64 skipTime, QString key2,int scale);
    Q_INVOKABLE QString getEventsStr()const;
    Q_SIGNAL void evJsonChanged();
    QVariantList evtVals;
    QVariantList evtNames;
    Q_INVOKABLE QVariant getAllEvTypes();
    Q_INVOKABLE QVariant getEvtDescription(quint64 val);
    
    bool _ev_thread_isRunning = false;
    bool stop_evThread = false;
    int _newEvents_isSupported = -1;
    std::thread _ev_thread;

    QString _eventsStr;
    uint64_t _skipTime;
    QDateTime startEvtTime;
    QDateTime finishEvtTime;

    // заполненность архива
    Q_INVOKABLE void getFullness(QDateTime start, QDateTime finish, QString key2, int scale);
    Q_INVOKABLE QString getFnJson()const;
    void audioFullnessReq(QDateTime start, QDateTime finish, QString key2);
    void videoFullnessReq(QDateTime start, QDateTime finish, QString key2, int scale);
    static void arcVideo_PD_res(const void* udata, const param_t* p);
    static void arcAudio_PD_res(const void* udata, const param_t* p);
    void setFnJson(const QString &);
    void setEventsStr(const QString &);
    Q_SIGNAL void fnJsonChanged();
    int archType;
    QString fnJson;

    // превью по архиву
    Q_INVOKABLE void start_thread(QString key2 , qint64 left_bound, qint64 right_bound, int count_preview );
    Q_INVOKABLE void start_thread2(QString key2 , qint64 frame_time, qreal x, qreal y );
    Q_INVOKABLE void stop_thread();
    Q_SIGNAL void drawPreviewQML123(
            QString url,
            qint64 time,
            qint8 status,
            qint64 left_bound,
            qint64 right_bound
            );
    Q_SIGNAL void drawPreviewQML(
            qreal qr_mouse_x_av,
            qreal qr_mouse_y_av,
            QString qs_provider_param_lv
            );
    void* _thread_get_data_cache;
    QString _key2;
    std::thread _t;
    std::mutex cs;
    bool _succes=false;
    bool _finish_thread=false;
    int _count_preview=0;

public:
    ArchivePlayer();
    ~ArchivePlayer();
    qint64 _left_bound;
    qint64 _right_bound;
    qreal _coordX;
    qreal _coordY;
    qreal _x;
    qreal _y;
    qint64 _frame_time;

    Q_PROPERTY(bool isNewStrip READ getIsNewStrip WRITE setIsNewStrip)
    bool isNewStrip = false;
    bool getIsNewStrip(){return isNewStrip;}
    void setIsNewStrip(bool b);
    int scale;
    void getIps();
    std::vector<std::string> _ipList;
    //QString _clientName;
    QString _csServer;
    QString _Key2;

    QDateTime _startDate;
    QDateTime _endDate;
    bool _threadEnd;

private:
    struct EventsRequestParams {
        QDateTime start;
        QDateTime finish;
        quint64 skipTime = 0;
        QString key2;
        int scale = 0;
    };

    struct FullnessRequestParams {
        QDateTime start;
        QDateTime finish;
        QString key2;
        int scale = 0;
    };

    void GenFilter(iv::ewriter::filter & fl,std::vector<int64_t> vals,QString tBegin,QString tEnd);
    profile_t _track_windows_command;
    void* _eventsTask = 0;
    std::string common_filter = "{\"group\":[{\"col\":\"evttime\",\"val\":\"%s\",\"op\":\">\"},{\"col\":\"evttime\",\"val\":\"%s\",\"op\":\"<\"},{\"col\":\"evtgroupid\",\"op\":\"=\",\"val\":[2,6]}],\"op\":\"and\"}";

    void startEventsFuture(const EventsRequestParams& params);
    void startFullnessFuture(const FullnessRequestParams& params);
    void executeEventsRequest(const EventsRequestParams& params);
    void executeFullnessRequest(const FullnessRequestParams& params);
    void handleEventsFinished();
    void handleFullnessFinished();

    QFutureWatcher<void> m_eventsWatcher;
    QFutureWatcher<void> m_fullnessWatcher;
    bool m_hasPendingEvents = false;
    EventsRequestParams m_pendingEvents;
    bool m_hasPendingFullness = false;
    FullnessRequestParams m_pendingFullness;
};

#endif // QARCHIVE_PLAYER_H
