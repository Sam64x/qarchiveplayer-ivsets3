#pragma once

#include <QObject>
#include <QString>
#include <QFileSystemWatcher>
#include <QFutureWatcher>
#include <QTimer>

class AppInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appDir READ appDir CONSTANT)

    Q_PROPERTY(QString settingsFilePath READ settingsFilePath WRITE setSettingsFilePath NOTIFY settingsFilePathChanged)
    Q_PROPERTY(QString ip READ ip NOTIFY ipChanged)

    Q_PROPERTY(int wsPort READ wsPort WRITE setWsPort NOTIFY wsPortChanged)
    Q_PROPERTY(QString wsPath READ wsPath WRITE setWsPath NOTIFY wsPathChanged)
    Q_PROPERTY(QString wsUrl READ wsUrl NOTIFY wsUrlChanged)

    Q_PROPERTY(QString archiveKey2 READ archiveKey2 WRITE setArchiveKey2 NOTIFY archiveKey2Changed)

    Q_PROPERTY(QString exportSaveDirectory READ exportSaveDirectory NOTIFY exportSaveDirectoryChanged)
    Q_PROPERTY(QString snapshotSaveDirectory READ snapshotSaveDirectory NOTIFY snapshotSaveDirectoryChanged)

public:
    explicit AppInfo(QObject* parent = nullptr);

    QString appDir() const;

    QString settingsFilePath() const { return m_settingsFilePath; }
    void setSettingsFilePath(const QString& path);

    QString ip() const { return m_ip; }

    int wsPort() const { return m_wsPort; }
    void setWsPort(int port);

    QString wsPath() const { return m_wsPath; }
    void setWsPath(const QString& path);

    QString wsUrl() const { return m_wsUrl; }

    QString archiveKey2() const { return m_archiveKey2; }
    void setArchiveKey2(const QString& key2);

    QString exportSaveDirectory() const { return m_exportSaveDirectory; }
    QString snapshotSaveDirectory() const { return m_snapshotSaveDirectory; }

    Q_INVOKABLE void reloadSettings();
    Q_INVOKABLE void reloadCacheDb();
    Q_INVOKABLE void refreshWsUrlForKey2(const QString& key2);

signals:
    void ipChanged();
    void settingsFilePathChanged();
    void wsPortChanged();
    void wsPathChanged();
    void wsUrlChanged();

    void archiveKey2Changed();

    void exportSaveDirectoryChanged();
    void snapshotSaveDirectoryChanged();

private slots:
    void onFileChanged(const QString& path);
    void onDirChanged(const QString& path);
    void doReloadDebounced();
    void handleNetSourceReady();

private:
    QString readIpFromFile(const QString& path) const;
    void updateIp(const QString& newIp);
    void setActiveIp(const QString& newIp);
    void ensureWatching();
    void recomputeWsUrl();
    static QString normalizePath(const QString& path);

    void loadCacheValues();
    QString readCacheValue(const QString& key);

    QString decodeCacheJson(const QString& raw) const;
    QString pickPlatformValue(const QJsonObject& obj) const;
    QString normalizeFilePath(const QString& path) const;
    QString extractSubAddressIp(const QString& response, const QString& primaryIp) const;
    QString wsCallIp() const;
    void refreshActiveArchiveIp();

private:
    QFileSystemWatcher m_watcher;
    QTimer             m_reloadDebounce;
    QFutureWatcher<QString> m_netSourceWatcher;
    QString            m_ip;
    QString            m_primaryIp;
    QString            m_archiveKey2;
    QString            m_settingsFilePath;
    QString            m_settingsDir;
    QString            m_cacheDir;

    int     m_wsPort   = 3000;
    QString m_wsPath   = QStringLiteral("/archive_api/");
    QString m_wsUrl;

    QString m_cacheDbPath;
    QString m_exportSaveDirectory;
    QString m_snapshotSaveDirectory;
    QString m_pendingKey2;
    QString m_inflightKey2;
};
