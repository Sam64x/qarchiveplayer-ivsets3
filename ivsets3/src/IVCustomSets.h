#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QJsonArray>
#include <QFile>
#include <QMutex>

#include <iv_core.h>

class IVCustomSets: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString currentUser READ getCurrentUser WRITE setCurrentUser NOTIFY currentUserChanged)
    Q_PROPERTY(bool sourcesReady READ sourcesReady NOTIFY sourcesReadyChanged)

public:
    static IVCustomSets* instance();
    ~IVCustomSets();

    QString getCurrentUser() const;
    void setCurrentUser(const QString& val);

    bool sourcesReady() const;
    void setSourcesReady(bool value);

    // ?? for what?
    Q_INVOKABLE void initMap();
    Q_INVOKABLE void deinitMap();
    Q_INVOKABLE void getMapsFromFile();
    void getEvents();
    // ??

    Q_INVOKABLE QString getZonesCommon(const QString& setId);
    Q_INVOKABLE void saveSet2(const QString& setJsonString);
    void saveOnServer2(const QString& data);
    Q_INVOKABLE void deleteSet2(const QString& setId);
    void deleteOnServer2(const QString& setId);

    void updateSourcesReady(const QString& sourceType);

    profile_t _onDataPr {nullptr};
    profile_t _ipProfile {nullptr};
    profile_t _camsUpdateProfile {nullptr};
    profile_t _onResultPr {nullptr};

    QString _lastEventTime;
    QVariantMap _mapsAnalogy;

    //------ old client code. remove when removing old code
    Q_INVOKABLE QString getZoneTypes();
    Q_INVOKABLE int deleteSet(QString setName);
    Q_INVOKABLE void saveSet(QString setName,QString newSetName,QString setJson);
    void saveOnServer(QString user,QString folder,QString fileName,QString data);
    QStringList getLocalSetsList();
    QStringList getRemoteSetsList();

    Q_INVOKABLE QString getZone(QString setName);
    QString getZonesRemote(QString setName);
    QString getZonesLocal(QString setName);

    Q_INVOKABLE QVariantList getSetsList();
    Q_INVOKABLE QString getCameras();
    //------

signals:
    void currentUserChanged();
    void eventMapChanged(QString mapName,QString key2);
    void sourcesReadyChanged();
    void setsUpdated();
    void newSetSavedWithId(const QString& previousSetId,
                           const QString& newSetId,
                           const QString& newSetName);
    void setRemoved(const QString& setId);

private:
    IVCustomSets(QObject* parent = nullptr);

    static void on_track_events(const void* udata, const param_t* p);
    static void events_updater_thousand(void* thread, void* udata);

    static void on_track_client_info(const void* udata, const param_t* p);
    static void server_sets_updater(void *thread, void *udata);
    static void general_server_sets_updater(void *thread, void *udata);
    static void general_cameras_updater(void *thread, void *udata);
    static void general_maps_updater(void *thread, void *udata);
    static void general_fact_list_updater(void *thread, void *udata);
    static void general_custom_group_list_updater(void *thread, void *udata);
    static void general_custom_group_set_list_updater(void *thread, void *udata);
    static void onresult(const void* udata, const param_t* p);

    static QFile getFilePath(const QString& pathToFolder, const QString& fileName);

    QString _currentUser;
    QJsonArray _bindingCamsArr;
    int _t;
    void* _zu = 0;

    bool _sourcesReady = false;
    QMutex sourcesReadyMutex;

    void save_server_sets(char* json);
    void save_cameras(char* json);
    void save_maps(char* json);
    void save_fact_list(char* json);
    void save_groups_list(char* json);
    void save_groups_sets(char* json);

    bool _setsUpdated {false};
    bool _camerasUpdated {false};
    bool _mapsUpdated {false};
    bool _factListUpdated {false};
    bool _customGroupsUpdated {false};
    bool _customGroupsSetsUpdated {false};
};
