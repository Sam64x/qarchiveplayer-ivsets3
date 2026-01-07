#include "AppInfo.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QUrl>

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>
#include <QStandardPaths>

#include "ws.h"
#include <future>
#include <string>

AppInfo::AppInfo(QObject* parent)
    : QObject(parent)
{
    const QString dir = QCoreApplication::applicationDirPath();
    m_settingsDir      = dir;
    m_settingsFilePath = QDir(dir).filePath(QStringLiteral("client_settings.json"));

    m_cacheDbPath = QDir(dir).filePath(QStringLiteral("caches/caches.db"));
    m_cacheDir   = QFileInfo(m_cacheDbPath).absolutePath();

    m_reloadDebounce.setSingleShot(true);
    m_reloadDebounce.setInterval(100);
    connect(&m_reloadDebounce, &QTimer::timeout, this, &AppInfo::doReloadDebounced);

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &AppInfo::onFileChanged);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &AppInfo::onDirChanged);

    ensureWatching();
    reloadSettings();
    loadCacheValues();
    recomputeWsUrl();
}

QString AppInfo::appDir() const
{
    return QCoreApplication::applicationDirPath();
}

void AppInfo::setSettingsFilePath(const QString& path)
{
    const QString newPath = QDir::cleanPath(path);
    if (newPath == m_settingsFilePath)
        return;

    m_settingsFilePath = newPath;
    m_settingsDir       = QFileInfo(m_settingsFilePath).absolutePath();
    emit settingsFilePathChanged();

    ensureWatching();
    reloadSettings();
}

void AppInfo::ensureWatching()
{
    for (const auto& f : m_watcher.files()) m_watcher.removePath(f);
    for (const auto& d : m_watcher.directories()) m_watcher.removePath(d);

    if (!m_settingsDir.isEmpty() && QFileInfo::exists(m_settingsDir))
        m_watcher.addPath(m_settingsDir);

    if (!m_cacheDir.isEmpty() && QFileInfo::exists(m_cacheDir))
        m_watcher.addPath(m_cacheDir);

    if (QFileInfo::exists(m_settingsFilePath))
        m_watcher.addPath(m_settingsFilePath);

    if (!m_cacheDbPath.isEmpty() && QFileInfo::exists(m_cacheDbPath))
        m_watcher.addPath(m_cacheDbPath);
}

void AppInfo::reloadSettings()
{
    updateIp(readIpFromFile(m_settingsFilePath));

    if (QFileInfo::exists(m_settingsFilePath)) {
        const auto files = m_watcher.files();
        if (!files.contains(m_settingsFilePath))
            m_watcher.addPath(m_settingsFilePath);
    }
}

QString AppInfo::readIpFromFile(const QString& path) const
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};

    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return {};

    const auto root    = doc.object();
    const auto servers = root.value(QStringLiteral("servers")).toArray();
    if (servers.isEmpty())
        return {};

    return servers.first().toObject().value(QStringLiteral("ip")).toString();
}

void AppInfo::updateIp(const QString& newIp)
{
    if (newIp == m_primaryIp && newIp == m_ip)
        return;

    m_primaryIp = newIp;
    setActiveIp(newIp);
    refreshActiveArchiveIp();
}

void AppInfo::setActiveIp(const QString& newIp)
{
    if (newIp == m_ip)
        return;

    m_ip = newIp;
    emit ipChanged();
    recomputeWsUrl();
}

void AppInfo::onFileChanged(const QString& path)
{
    if (path == m_settingsFilePath) {
        m_reloadDebounce.start();
        return;
    }

    if (path == m_cacheDbPath) {
        ensureWatching();
        loadCacheValues();
        return;
    }
}

void AppInfo::onDirChanged(const QString& path)
{
    ensureWatching();

    if (path == m_settingsDir) {
        m_reloadDebounce.start();
    } else if (path == m_cacheDir) {
        reloadCacheDb();
    }
}

void AppInfo::doReloadDebounced()
{
    reloadSettings();
}

static inline QString ensureLeadingSlash(const QString& p) {
    if (p.isEmpty() || p.startsWith('/')) return p;
    return QString('/') + p;
}
static inline QString ensureTrailingSlash(const QString& p) {
    if (p.endsWith('/')) return p;
    return p + '/';
}

QString AppInfo::normalizePath(const QString& path)
{
    return ensureTrailingSlash(ensureLeadingSlash(path));
}

void AppInfo::setWsPort(int port)
{
    if (port == m_wsPort) return;
    m_wsPort = port;
    emit wsPortChanged();
    recomputeWsUrl();
}

void AppInfo::setWsPath(const QString& path)
{
    const QString np = normalizePath(path);
    if (np == m_wsPath) return;
    m_wsPath = np;
    emit wsPathChanged();
    recomputeWsUrl();
}

void AppInfo::recomputeWsUrl()
{
    QString newUrl;
    if (!m_ip.isEmpty()) {
        newUrl = QStringLiteral("ws://%1:%2%3")
        .arg(m_ip)
            .arg(m_wsPort)
            .arg(m_wsPath);
    }
    if (newUrl != m_wsUrl) {
        m_wsUrl = newUrl;
        emit wsUrlChanged();
    }
}

QString AppInfo::wsCallIp() const
{
    if (!m_wsUrl.isEmpty()) {
        const QUrl url(m_wsUrl);
        if (!url.host().isEmpty())
            return url.host();
    }

    if (!m_ip.isEmpty())
        return m_ip;

    return m_primaryIp;
}

void AppInfo::setArchiveKey2(const QString& key2)
{
    if (key2 == m_archiveKey2)
        return;

    m_archiveKey2 = key2;
    emit archiveKey2Changed();
    refreshActiveArchiveIp();
}

void AppInfo::refreshActiveArchiveIp()
{
    if (m_archiveKey2.isEmpty()) {
        qInfo() << "AppInfo: archive key2 is empty, using primary ip" << m_primaryIp;
        setActiveIp(m_primaryIp);
        return;
    }

    refreshWsUrlForKey2(m_archiveKey2);
}

void AppInfo::refreshWsUrlForKey2(const QString& key2)
{
    if (m_primaryIp.isEmpty())
        m_primaryIp = m_ip;

    if (key2.isEmpty()) {
        qInfo() << "AppInfo: key2 is empty, using primary ip" << m_primaryIp;
        setActiveIp(m_primaryIp);
        return;
    }

    const QString callIp = m_primaryIp.isEmpty() ? wsCallIp() : m_primaryIp;
    if (callIp.isEmpty()) {
        qWarning() << "AppInfo: no IP available to query net source";
        setActiveIp(m_primaryIp);
        return;
    }

    const std::string params = QString("{\"key2\":\"%1\"}").arg(key2).toStdString();

    iv::ws_ws ws_zna_ip;
    qInfo() << "AppInfo: requesting net source for key2" << key2 << "via ip" << callIp;
    std::future<std::string> ft_zna_ip = ws_zna_ip.call(callIp.toStdString(), "arc_info_status:get_net_source", params, "", NULL);

    ft_zna_ip.wait();
    const QString ws_zna_ip_res = QString::fromStdString(ft_zna_ip.get());

    qInfo() << "AppInfo: net source response" << ws_zna_ip_res;

    const QString subAddressIp = extractSubAddressIp(ws_zna_ip_res, m_primaryIp);
    if (!subAddressIp.isEmpty()) {
        qInfo() << "AppInfo: using subordinate archive ip" << subAddressIp;
        setActiveIp(subAddressIp);
    } else {
        qInfo() << "AppInfo: subordinate archive ip not found, reverting to primary" << m_primaryIp;
        setActiveIp(m_primaryIp);
    }
}

void AppInfo::reloadCacheDb()
{
    loadCacheValues();
}

QString AppInfo::readCacheValue(const QString& key)
{
    if (m_cacheDbPath.isEmpty() || !QFileInfo::exists(m_cacheDbPath))
        return {};

    static const char* kConnName = "AppInfoCacheConn";
    QSqlDatabase db;
    if (QSqlDatabase::contains(kConnName))
        db = QSqlDatabase::database(kConnName);
    else {
        db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), kConnName);
        db.setDatabaseName(m_cacheDbPath);
    }

    if (!db.isOpen() && !db.open()) {
        qWarning() << "AppInfo: can't open cache db" << m_cacheDbPath << db.lastError().text();
        return {};
    }

    QSqlQuery q(db);
    q.prepare(QStringLiteral("SELECT stgvalue FROM settings WHERE stgname = :name"));
    q.bindValue(QStringLiteral(":name"), key);

    if (!q.exec()) {
        qWarning() << "AppInfo: query failed for" << key << q.lastError().text();
        return {};
    }

    if (!q.next())
        return {};

    const QString raw = q.value(0).toString();
    return decodeCacheJson(raw);
}

QString AppInfo::decodeCacheJson(const QString& raw) const
{
    if (raw.isEmpty())
        return {};

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(raw.toUtf8(), &err);

    if (err.error == QJsonParseError::NoError && doc.isObject()) {
        const QJsonObject obj = doc.object();
        const QString platformVal = pickPlatformValue(obj);
        return normalizeFilePath(platformVal);
    }

    if (err.error == QJsonParseError::NoError && doc.isArray()) {
        const auto arr = doc.array();
        for (const QJsonValue& v : arr) {
            if (v.isString())
                return normalizeFilePath(v.toString());
        }
        return {};
    }

    QString v = raw.trimmed();
    if (v.size() >= 2 && v.startsWith('"') && v.endsWith('"'))
        v = v.mid(1, v.size() - 2);

    return normalizeFilePath(v);
}

QString AppInfo::extractSubAddressIp(const QString& response, const QString& primaryIp) const
{
    if (response.isEmpty())
        return {};

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(response.toUtf8(), &err);

    if (err.error != QJsonParseError::NoError) {
        qWarning() << "AppInfo: failed to parse net source response" << err.errorString();
        return {};
    }

    QJsonArray results;
    if (doc.isObject()) {
        results = doc.object().value(QStringLiteral("result")).toArray();
    } else if (doc.isArray()) {
        results = doc.array();
    } else {
        qWarning() << "AppInfo: unexpected net source response format";
        return {};
    }

    for (const auto& resultVal : results) {
        const auto resArray = resultVal.toObject().value(QStringLiteral("res")).toArray();
        for (const auto& resVal : resArray) {
            const auto resObj   = resVal.toObject();
            const bool writeNow = resObj.value(QStringLiteral("write_now")).toBool();
            if (!writeNow)
                continue;

            const auto addresses = resObj.value(QStringLiteral("address")).toArray();
            if (addresses.size() <= 1)
                continue;

            bool     afterPrimary = false;
            QString  candidate;
            for (const auto& addressVal : addresses) {
                const QString ip = addressVal.toObject().value(QStringLiteral("ip")).toString();
                if (ip == primaryIp) {
                    afterPrimary = true;
                    continue;
                }

                if (afterPrimary && !ip.isEmpty())
                    return ip;

                if (!afterPrimary && candidate.isEmpty() && !ip.isEmpty())
                    candidate = ip;
            }

            if (afterPrimary && !candidate.isEmpty())
                return candidate;
        }
    }

    return {};
}

QString AppInfo::pickPlatformValue(const QJsonObject& obj) const
{
#if defined(Q_OS_WIN)
    static const char* platformKeys[] = { "windows", "win", "win32" };
#elif defined(Q_OS_LINUX)
    static const char* platformKeys[] = { "linux", "lnx" };
#else
    static const char* platformKeys[] = { "value" };
#endif

    for (const char* k : platformKeys) {
        const auto it = obj.find(QLatin1String(k));
        if (it != obj.end() && it.value().isString())
            return it.value().toString();
    }

    if (obj.contains(QStringLiteral("value")) && obj.value(QStringLiteral("value")).isString())
        return obj.value(QStringLiteral("value")).toString();

    for (auto it = obj.begin(); it != obj.end(); ++it) {
        if (it.value().isString())
            return it.value().toString();
    }

    return {};
}

QString AppInfo::normalizeFilePath(const QString& path) const
{
    if (path.isEmpty())
        return {};

    QString p = QDir::fromNativeSeparators(path).trimmed();
    if (p == "." || p == "./" || p == ".\\")
        return QCoreApplication::applicationDirPath();

    if (p.startsWith("./") || p.startsWith("../") || p.startsWith("."))
        p = QDir(QCoreApplication::applicationDirPath()).absoluteFilePath(p);

    return p;
}

void AppInfo::loadCacheValues()
{
    const QString exportDir   = readCacheValue(QStringLiteral("export.save_directory"));
    const QString snapshotDir = readCacheValue(QStringLiteral("qml.snapshot.save_directory"));

    QString defaultExportDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QString effectiveExportDir = exportDir.isEmpty() ? defaultExportDir : exportDir;
    if (effectiveExportDir.isEmpty())
        effectiveExportDir = QDir::homePath();

    if (effectiveExportDir != m_exportSaveDirectory) {
        m_exportSaveDirectory = effectiveExportDir;
        emit exportSaveDirectoryChanged();
    }
    if (snapshotDir != m_snapshotSaveDirectory) {
        m_snapshotSaveDirectory = snapshotDir;
        emit snapshotSaveDirectoryChanged();
    }
}




