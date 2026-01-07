#pragma once

#include <QVariantMap>
#include <QVariantList>
#include <QQuickItem>
#include <QObject>
#include <QFile>
#include <iv_core.h>
#include <QJsonArray>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <iv_mem2.h>
#include "iv_mjson2.h"
#include "iv_stable.h"
#include <iv_threads.h>
#include "iv_threads_pool.h"
#include <iv_cs.h>
#include "iv_tasks_noncritical.h"
#include "iv_mem3.h"
#include <iv_ewriter.h>
#include <iv_ws.h>
#include <QDateTime>
class IVCustomSets: public QObject
{
  Q_OBJECT
  //Q_DISABLE_COPY(IVCustomSets)

  Q_PROPERTY(QString currentUser READ getCurrentUser WRITE setCurrentUser NOTIFY currentUserChanged)

public:




  IVCustomSets(QObject* parent = 0);
  ~IVCustomSets();
  //  Q_INVOKABLE QString getZone(QString setName);
    QString _camsString;
    void setCurrentUser(QString val);
    QString getCurrentUser();
    QString _currentUser;
    QString _csServer;
    QString lastEventTime;

    QVariantMap _mapsAnalogy;
    QString _evtTime;
    QString eventsFilter;

private:
    profile_t _onDataPr;
    profile_t _ipProfile;
    profile_t _onResultPr;
    QJsonArray bindingCamsArr;
  int _t;
  QString _appPath;
  profile_t _camsUpdateProfile;
  bool isNeedWs;
  void getIps();

  static void on_track_client_info(const void* udata, const param_t* p);
  static void on_track_events(const void* udata, const param_t* p);
  static void oncmd(const void* udata, const param_t* p);
    void* zu = 0;
    static void events_updater_thousand(void* thread, void* udata);
public slots:
  QVariantList getBindingCameras(QString key2);
  void initMap();
  void deinitMap();
  void getMapsFromFile();
  QString getSetPreset(QString presetNumber);
  QJsonObject getTypePreset(QString type,QString propertyName,QString propertyType,QVariant value);
  int deleteSet(QString setName);
  int deleteSet2(QString setName,QString setId);
  QString getZoneTypes();
  QString getZone(QString setName);
  QString getZone2(QString setName,QString setId);
  QString getZone(QString setName,bool isLocal);
  QString getZonesRemote(QString setName);
  QString getZonesLocal(QString setName);
  QString getZonesCommon(QString setName,QString setId);
  QStringList getLocalSetsList();
  QStringList getRemoteSetsList();
  QVariantList getSetsList();
  QString getCameras();
  QString getMapsList();
  void getEvents();



  void saveOnServer(QString user,QString folder,QString fileName,QString data);
  void saveOnServer2(QString data);
  void deleteOnServer2(QString setid);
  void saveSet(QString setName,QString newSetName,QString setJson);
  void saveSet2(QString setName,QString setId,QString newSetName,QString setJson);
  void initWs();
  //int syncSets();


signals:
  void currentUserChanged(QString userName);
  void eventMapChanged(QString mapName,QString key2);

};
