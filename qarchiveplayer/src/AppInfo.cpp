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
#include <QtConcurrent/QtConcurrentRun>

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
    connect(&m_wsUrlWatcher, &QFutureWatcher<QString>::finished, this, [this]() {
        if (!m_wsUrlWatcher.isFinished())
            return;
        const int token = m_wsUrlWatcher.property("token").toInt();
        if (token != m_wsUrlToken)
            return;
        const QString response = m_wsUrlWatcher.result();
        // qInfo() << "AppInfo: net source response" << response;
        const QString primarySnapshot = m_primaryIp.isEmpty() ? m_ip : m_primaryIp;
        const QString subAddressIp = extractSubAddressIp(response, primarySnapshot);
        if (!subAddressIp.isEmpty()) {
            // qInfo() << "AppInfo: using subordinate archive ip" << subAddressIp;
            setActiveIp(subAddressIp);
        } else {
            // qInfo() << "AppInfo: subordinate archive ip not found, reverting to primary" << primarySnapshot;
            setActiveIp(primarySnapshot);
        }
        m_wsUrlInFlightKey2.clear();
        if (!m_wsUrlPendingKey2.isEmpty()) {
            const QString nextKey2 = m_wsUrlPendingKey2;
            m_wsUrlPendingKey2.clear();
            refreshWsUrlForKey2(nextKey2);
        }
    });

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
    const auto keys = m_wsIpByKey2.keys();
    for (const auto& key : keys) {
        requestWsUrlForKey2(key);
    }
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
    const auto keys = m_wsIpByKey2.keys();
    for (const auto& key : keys) {
        updateWsUrlForKey2(key, m_wsIpByKey2.value(key));
    }
}

void AppInfo::setWsPath(const QString& path)
{
    const QString np = normalizePath(path);
    if (np == m_wsPath) return;
    m_wsPath = np;
    emit wsPathChanged();
    recomputeWsUrl();
    const auto keys = m_wsIpByKey2.keys();
    for (const auto& key : keys) {
        updateWsUrlForKey2(key, m_wsIpByKey2.value(key));
    }
}

void AppInfo::recomputeWsUrl()
{
    const QString newUrl = buildWsUrlForIp(m_ip);
    if (newUrl != m_wsUrl) {
        m_wsUrl = newUrl;
        emit wsUrlChanged();
    }
}

QString AppInfo::buildWsUrlForIp(const QString& ip) const
{
    if (ip.isEmpty())
        return {};

    return QStringLiteral("ws://%1:%2%3")
        .arg(ip)
        .arg(m_wsPort)
        .arg(m_wsPath);
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
        // qInfo() << "AppInfo: archive key2 is empty, using primary ip" << m_primaryIp;
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
        // qInfo() << "AppInfo: key2 is empty, using primary ip" << m_primaryIp;
        setActiveIp(m_primaryIp);
        return;
    }

    const QString callIp = m_primaryIp.isEmpty() ? wsCallIp() : m_primaryIp;
    if (callIp.isEmpty()) {
        // qWarning() << "AppInfo: no IP available to query net source";
        setActiveIp(m_primaryIp);
        return;
    }

    if (m_wsUrlWatcher.isRunning()) {
        if (m_wsUrlInFlightKey2 == key2)
            return;
        m_wsUrlPendingKey2 = key2;
        return;
    }

    startWsUrlLookup(key2, callIp);
}

QString AppInfo::wsUrlForKey2(const QString& key2) const
{
    if (key2.isEmpty())
        return m_wsUrl;

    return m_wsUrlByKey2.value(key2);
}

QStringList AppInfo::wsIpsForKey2(const QString& key2) const
{
    return m_wsIpsByKey2.value(key2);
}

void AppInfo::selectWsIpForKey2(const QString& key2, const QString& ip)
{
    const QString normalizedKey2 = key2.trimmed();
    const QString trimmedIp = ip.trimmed();
    if (normalizedKey2.isEmpty() || trimmedIp.isEmpty())
        return;

    m_wsIpOverrideByKey2.insert(normalizedKey2, trimmedIp);
    updateWsUrlForKey2(normalizedKey2, trimmedIp);
}

void AppInfo::clearWsIpOverrideForKey2(const QString& key2)
{
    const QString normalizedKey2 = key2.trimmed();
    if (normalizedKey2.isEmpty())
        return;

    if (m_wsIpOverrideByKey2.remove(normalizedKey2) > 0) {
        requestWsUrlForKey2(normalizedKey2);
    }
}

void AppInfo::requestWsUrlForKey2(const QString& key2)
{
    const QString normalizedKey2 = key2.trimmed();
    const QString primarySnapshot = m_primaryIp.isEmpty() ? m_ip : m_primaryIp;
    const QString overrideIp = m_wsIpOverrideByKey2.value(normalizedKey2);
    if (!overrideIp.isEmpty()) {
        updateWsUrlForKey2(normalizedKey2, overrideIp);
        return;
    }
    if (normalizedKey2.isEmpty()) {
        updateWsUrlForKey2(normalizedKey2, primarySnapshot);
        return;
    }

    const QString callIp = m_primaryIp.isEmpty() ? wsCallIp() : m_primaryIp;
    if (callIp.isEmpty()) {
        updateWsUrlForKey2(normalizedKey2, primarySnapshot);
        return;
    }

    const int token = ++m_wsUrlLookupToken;
    m_wsUrlTokenByKey2.insert(normalizedKey2, token);

    if (auto existing = m_wsUrlWatchers.take(normalizedKey2)) {
        existing->deleteLater();
    }

    auto watcher = new QFutureWatcher<QString>(this);
    watcher->setProperty("key2", normalizedKey2);
    watcher->setProperty("token", token);
    m_wsUrlWatchers.insert(normalizedKey2, watcher);

    connect(watcher, &QFutureWatcher<QString>::finished, this, [this, watcher]() {
        if (!watcher->isFinished())
            return;
        const QString key2 = watcher->property("key2").toString();
        const int token = watcher->property("token").toInt();
        if (m_wsUrlTokenByKey2.value(key2) != token) {
            watcher->deleteLater();
            return;
        }

        const QString response = watcher->result();
        qDebug() << "AppInfo: app_info_status response" << response;
        const QStringList ips = extractArchiveIps(response);
        if (!ips.isEmpty()) {
            m_wsIpsByKey2.insert(key2, ips);
            emit wsIpsForKey2Changed(key2, ips);
        }
        const QString primarySnapshot = m_primaryIp.isEmpty() ? m_ip : m_primaryIp;
        const QString subAddressIp = extractSubAddressIp(response, primarySnapshot);
        const QString selectedIp = subAddressIp.isEmpty() ? primarySnapshot : subAddressIp;
        updateWsUrlForKey2(key2, selectedIp);
        m_wsUrlWatchers.remove(key2);
        watcher->deleteLater();
    });

    auto fut = QtConcurrent::run([callIp, normalizedKey2]() -> QString {
        const std::string params = QString("{\"key2\":\"%1\"}").arg(normalizedKey2).toStdString();
        iv::ws_ws ws_zna_ip;
        std::future<std::string> ft_zna_ip =
            ws_zna_ip.call(callIp.toStdString(), "arc_info_status:get_net_source", params, "", NULL);
        ft_zna_ip.wait();
        return QString::fromStdString(ft_zna_ip.get());
    });
    watcher->setFuture(fut);
}

void AppInfo::updateWsUrlForKey2(const QString& key2, const QString& ip)
{
    const QString newUrl = buildWsUrlForIp(ip);
    if (newUrl.isEmpty()) {
        if (m_wsUrlByKey2.contains(key2)) {
            m_wsUrlByKey2.remove(key2);
            m_wsIpByKey2.remove(key2);
            emit wsUrlForKey2Changed(key2, QString());
        }
        return;
    }

    m_wsIpByKey2.insert(key2, ip);
    if (m_wsUrlByKey2.value(key2) != newUrl) {
        m_wsUrlByKey2.insert(key2, newUrl);
        emit wsUrlForKey2Changed(key2, newUrl);
    }
}

void AppInfo::startWsUrlLookup(const QString& key2, const QString& callIp)
{
    m_wsUrlInFlightKey2 = key2;
    const int token = ++m_wsUrlToken;
    m_wsUrlWatcher.setProperty("token", token);
    // qInfo() << "AppInfo: requesting net source for key2" << key2 << "via ip" << callIp;
    auto fut = QtConcurrent::run([callIp, key2]() -> QString {
        const std::string params = QString("{\"key2\":\"%1\"}").arg(key2).toStdString();
        iv::ws_ws ws_zna_ip;
        std::future<std::string> ft_zna_ip =
            ws_zna_ip.call(callIp.toStdString(), "arc_info_status:get_net_source", params, "", NULL);
        ft_zna_ip.wait();
        return QString::fromStdString(ft_zna_ip.get());
    });
    m_wsUrlWatcher.setFuture(fut);
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
        // qWarning() << "AppInfo: can't open cache db" << m_cacheDbPath << db.lastError().text();
        return {};
    }

    QSqlQuery q(db);
    q.prepare(QStringLiteral("SELECT stgvalue FROM settings WHERE stgname = :name"));
    q.bindValue(QStringLiteral(":name"), key);

    if (!q.exec()) {
        // qWarning() << "AppInfo: query failed for" << key << q.lastError().text();
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
        // qWarning() << "AppInfo: failed to parse net source response" << err.errorString();
        return {};
    }

    QJsonArray results;
    if (doc.isObject()) {
        results = doc.object().value(QStringLiteral("result")).toArray();
    } else if (doc.isArray()) {
        results = doc.array();
    } else {
        // qWarning() << "AppInfo: unexpected net source response format";
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

QStringList AppInfo::extractArchiveIps(const QString& response) const
{
    if (response.isEmpty())
        return {};

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(response.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError)
        return {};

    QJsonArray results;
    if (doc.isObject()) {
        results = doc.object().value(QStringLiteral("result")).toArray();
    } else if (doc.isArray()) {
        results = doc.array();
    } else {
        return {};
    }

    QStringList ips;
    for (const auto& resultVal : results) {
        const auto resArray = resultVal.toObject().value(QStringLiteral("res")).toArray();
        for (const auto& resVal : resArray) {
            const auto addresses = resVal.toObject().value(QStringLiteral("address")).toArray();
            for (const auto& addressVal : addresses) {
                const QString ip = addressVal.toObject().value(QStringLiteral("ip")).toString();
                if (!ip.isEmpty() && !ips.contains(ip))
                    ips.append(ip);
            }
        }
    }

    return ips;
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
