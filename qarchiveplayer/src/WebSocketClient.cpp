#include "WebSocketClient.h"

#include <QDebug>
#include <QMetaType>
#include <QMetaObject>
#include <QWebSocketProtocol>

static QString displayUrl(const QUrl& u)
{
    return u.toDisplayString(QUrl::FullyDecoded | QUrl::RemovePassword);
}

static QString stateToString(QAbstractSocket::SocketState s)
{
    switch (s) {
    case QAbstractSocket::UnconnectedState: return QStringLiteral("Unconnected");
    case QAbstractSocket::HostLookupState:  return QStringLiteral("HostLookup");
    case QAbstractSocket::ConnectingState:  return QStringLiteral("Connecting");
    case QAbstractSocket::ConnectedState:   return QStringLiteral("Connected");
    case QAbstractSocket::BoundState:       return QStringLiteral("Bound");
    case QAbstractSocket::ClosingState:     return QStringLiteral("Closing");
    case QAbstractSocket::ListeningState:   return QStringLiteral("Listening");
    }
    return QStringLiteral("Unknown");
}

WebSocketClientWorker::WebSocketClientWorker(QObject* parent)
    : QObject(parent)
{
}

void WebSocketClientWorker::init()
{
    if (m_socket) return;
    m_socket = new QWebSocket();
    m_socket->setParent(this);
    m_timer = new QTimer(this);
    m_timer->setSingleShot(false);
    m_timer->setInterval(m_reconnectIntervalMs);

    connect(m_timer, SIGNAL(timeout()), this, SLOT(tryReconnect()));
    connect(m_socket, SIGNAL(connected()), this, SLOT(onConnected()));
    connect(m_socket, SIGNAL(disconnected()), this, SLOT(onDisconnected()));
    connect(m_socket, SIGNAL(textMessageReceived(QString)), this, SLOT(onText(QString)));
    connect(m_socket, SIGNAL(binaryMessageReceived(QByteArray)), this, SLOT(onBinary(QByteArray)));
    connect(m_socket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(onError(QAbstractSocket::SocketError)));
    connect(m_socket, SIGNAL(stateChanged(QAbstractSocket::SocketState)), this, SLOT(onStateChanged(QAbstractSocket::SocketState)));
}

void WebSocketClientWorker::setUrl(const QUrl& u)
{
    if (!m_socket) { m_url = u; return; }
    const bool becameEmpty = u.isEmpty() && !m_url.isEmpty();
    const bool changed = (u != m_url);
    m_url = u;

    if (becameEmpty) {
        m_userClose = true;
        if (m_timer) m_timer->stop();
        if (m_socket->state() != QAbstractSocket::UnconnectedState) {
            qInfo().noquote() << "[WS] Closing connection because URL was cleared";
            m_socket->close();
        }
        return;
    }

    if (changed && !m_url.isEmpty()) {
        m_userClose = false;
        if (m_timer) m_timer->stop();
        switch (m_socket->state()) {
        case QAbstractSocket::ConnectedState:
        case QAbstractSocket::ConnectingState:
            qInfo().noquote() << "[WS] Switching endpoint, reconnecting to" << displayUrl(m_url);
            m_socket->close();
            QTimer::singleShot(0, this, [this]() {
                if (m_socket && !m_url.isEmpty())
                    m_socket->open(m_url);
            });
            break;
        default:
            qInfo().noquote() << "[WS] Endpoint set to" << displayUrl(m_url) << "- opening connection";
            m_socket->open(m_url);
            break;
        }
    }
}

void WebSocketClientWorker::setAutoReconnectEnabled(bool en)
{
    m_autoReconnect = en;
    if (!en && m_timer) m_timer->stop();
}

void WebSocketClientWorker::setReconnectIntervalMs(int ms)
{
    if (ms < 1000) ms = 1000;
    m_reconnectIntervalMs = ms;
    if (m_timer) m_timer->setInterval(m_reconnectIntervalMs);
}

void WebSocketClientWorker::connectToServer()
{
    if (!m_socket) return;
    if (m_url.isEmpty()) return;
    m_userClose = false;
    if (m_socket->state() == QAbstractSocket::ConnectedState || m_socket->state() == QAbstractSocket::ConnectingState) return;
    if (m_timer) m_timer->stop();
    qInfo().noquote() << "[WS] Connecting to" << displayUrl(m_url);
    m_socket->open(m_url);
}

void WebSocketClientWorker::close()
{
    if (!m_socket) return;
    m_userClose = true;
    if (m_timer) m_timer->stop();
    qInfo().noquote() << "[WS] Closing connection to" << displayUrl(m_socket->requestUrl().isEmpty() ? m_url : m_socket->requestUrl());
    m_socket->close();
}

void WebSocketClientWorker::sendRequest(const QJsonObject& req)
{
    if (!m_socket) return;
    if (m_socket->state() != QAbstractSocket::ConnectedState) return;
    const QString payload = QString::fromUtf8(QJsonDocument(req).toJson(QJsonDocument::Compact));
    m_socket->sendTextMessage(payload);
}

void WebSocketClientWorker::shutdown()
{
    if (m_timer) m_timer->stop();
    if (m_socket) m_socket->close();
}

void WebSocketClientWorker::tryReconnect()
{
    if (!m_socket) return;
    if (!m_autoReconnect || m_userClose) { if (m_timer) m_timer->stop(); return; }
    const auto st = m_socket->state();
    if (st == QAbstractSocket::ConnectedState) { if (m_timer) m_timer->stop(); return; }
    if (st == QAbstractSocket::ConnectingState) return;
    if (m_url.isEmpty()) return;
    qInfo().noquote() << "[WS] Reconnecting to" << displayUrl(m_url);
    m_socket->open(m_url);
}

void WebSocketClientWorker::onConnected()
{
    if (m_timer) m_timer->stop();
    m_userClose = false;
    const QUrl used = m_socket->requestUrl().isEmpty() ? m_url : m_socket->requestUrl();
    qInfo().noquote() << "[WS] Connected to" << displayUrl(used);
    emit connected();
}

void WebSocketClientWorker::onDisconnected()
{
    const QUrl used = m_socket->requestUrl().isEmpty() ? m_url : m_socket->requestUrl();
    const int code = static_cast<int>(m_socket->closeCode());
    const QString reason = m_socket->closeReason();
    qInfo().noquote() << "[WS] Disconnected from" << displayUrl(used) << "(code" << code << "," << (reason.isEmpty() ? QStringLiteral("no reason") : reason) << ")";
    emit disconnected();
    if (!m_userClose && m_autoReconnect && m_timer) {
        qInfo().noquote() << "[WS] Auto-reconnect in" << m_reconnectIntervalMs << "ms";
        m_timer->start();
    }
}

void WebSocketClientWorker::onError(QAbstractSocket::SocketError e)
{
    qWarning().noquote() << "[WS] Socket error" << e << "-" << (m_socket ? m_socket->errorString() : QStringLiteral("unknown error"))
    << "at" << displayUrl(m_socket && !m_socket->requestUrl().isEmpty() ? m_socket->requestUrl() : m_url);
    emit errorOccurred(e);
    if (!m_userClose && m_autoReconnect && m_socket && m_socket->state() != QAbstractSocket::ConnectedState && m_timer) {
        qInfo().noquote() << "[WS] Auto-reconnect in" << m_reconnectIntervalMs << "ms";
        m_timer->start();
    }
}

void WebSocketClientWorker::onText(const QString& s)
{
    Q_UNUSED(s);
    emit textMessageReceived(s);
}

void WebSocketClientWorker::onBinary(const QByteArray& b)       { emit binaryMessageReceived(b); }

void WebSocketClientWorker::onStateChanged(QAbstractSocket::SocketState s)
{
    if (s == QAbstractSocket::ConnectingState) {
        qInfo().noquote() << "[WS] State:" << stateToString(s) << "to" << displayUrl(m_url);
    } else if (s == QAbstractSocket::ClosingState) {
        qInfo().noquote() << "[WS] State:" << stateToString(s) << "from" << displayUrl(m_socket && !m_socket->requestUrl().isEmpty() ? m_socket->requestUrl() : m_url);
    }
    emit stateChanged(s);
}

void WebSocketClient::setUrl(const QUrl &url)
{
    if (m_url == url) return;
    m_url = url;
    emit urlChanged(m_url);

    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "setUrl", Qt::QueuedConnection, Q_ARG(QUrl, m_url));
        if (m_autoConnect && !m_url.isEmpty())
            QMetaObject::invokeMethod(m_worker, "connectToServer", Qt::QueuedConnection);
    }
}

WebSocketClient::WebSocketClient(const QUrl &url, QObject *parent)
    : WebSocketClient(parent)
{
    m_url = url;
}

WebSocketClient::WebSocketClient(QObject *parent)
    : QObject(parent)
{
    qRegisterMetaType<QAbstractSocket::SocketError>("QAbstractSocket::SocketError");
    qRegisterMetaType<QAbstractSocket::SocketState>("QAbstractSocket::SocketState");
}

WebSocketClient::~WebSocketClient()
{
    stopWorkerThread();
}

void WebSocketClient::classBegin() { }

void WebSocketClient::componentComplete()
{
    m_qmlCompleted = true;
    startWorkerThread();
    connectIfReady();
}

void WebSocketClient::startWorkerThread()
{
    if (m_thread) return;
    m_thread = new QThread(this);
    m_worker = new WebSocketClientWorker();
    m_worker->moveToThread(m_thread);

    connect(m_thread, SIGNAL(finished()), m_worker, SLOT(deleteLater()));
    connect(m_worker, SIGNAL(connected()), this, SIGNAL(connected()), Qt::QueuedConnection);
    connect(m_worker, SIGNAL(disconnected()), this, SIGNAL(disconnected()), Qt::QueuedConnection);
    connect(m_worker, SIGNAL(errorOccurred(QAbstractSocket::SocketError)), this, SIGNAL(errorOccurred(QAbstractSocket::SocketError)), Qt::QueuedConnection);
    connect(m_worker, SIGNAL(textMessageReceived(QString)), this, SIGNAL(textMessageReceived(QString)), Qt::QueuedConnection);
    connect(m_worker, SIGNAL(binaryMessageReceived(QByteArray)), this, SIGNAL(binaryMessageReceived(QByteArray)), Qt::QueuedConnection);
    connect(m_worker, SIGNAL(stateChanged(QAbstractSocket::SocketState)), this, SIGNAL(stateChanged(QAbstractSocket::SocketState)), Qt::QueuedConnection);

    m_thread->start();
    QMetaObject::invokeMethod(m_worker, "init", Qt::QueuedConnection);
    applyInitialStateToWorker();
}

void WebSocketClient::stopWorkerThread()
{
    if (!m_thread) return;
    if (m_worker) QMetaObject::invokeMethod(m_worker, "shutdown", Qt::BlockingQueuedConnection);
    m_thread->quit();
    m_thread->wait();
    m_worker = nullptr;
    m_thread = nullptr;
}

void WebSocketClient::applyInitialStateToWorker()
{
    if (!m_worker) return;
    QMetaObject::invokeMethod(m_worker, "setUrl", Qt::QueuedConnection, Q_ARG(QUrl, m_url));
    QMetaObject::invokeMethod(m_worker, "setAutoReconnectEnabled", Qt::QueuedConnection, Q_ARG(bool, m_autoReconnectEnabled));
    QMetaObject::invokeMethod(m_worker, "setReconnectIntervalMs", Qt::QueuedConnection, Q_ARG(int, m_reconnectIntervalMs));
}

void WebSocketClient::connectIfReady()
{
    if (!m_worker) return;
    if (!m_autoConnect) return;
    if (m_url.isEmpty()) return;
    QMetaObject::invokeMethod(m_worker, "connectToServer", Qt::QueuedConnection);
}

void WebSocketClient::connectToServer()
{
    if (m_worker) QMetaObject::invokeMethod(m_worker, "connectToServer", Qt::QueuedConnection);
}

void WebSocketClient::close()
{
    if (m_worker) QMetaObject::invokeMethod(m_worker, "close", Qt::QueuedConnection);
}

void WebSocketClient::sendRequest(const QJsonObject &request)
{
    if (m_worker) QMetaObject::invokeMethod(m_worker, "sendRequest", Qt::QueuedConnection, Q_ARG(QJsonObject, request));
}

void WebSocketClient::setAutoReconnectEnabled(bool enabled)
{
    if (m_autoReconnectEnabled == enabled) return;
    m_autoReconnectEnabled = enabled;
    emit autoReconnectEnabledChanged(enabled);
    if (m_worker) QMetaObject::invokeMethod(m_worker, "setAutoReconnectEnabled", Qt::QueuedConnection, Q_ARG(bool, enabled));
}

void WebSocketClient::setReconnectIntervalSeconds(int seconds)
{
    if (seconds < 1) seconds = 1;
    const int newMs = seconds * 1000;
    if (m_reconnectIntervalMs == newMs) return;
    m_reconnectIntervalMs = newMs;
    emit reconnectIntervalChanged(seconds);
    if (m_worker) QMetaObject::invokeMethod(m_worker, "setReconnectIntervalMs", Qt::QueuedConnection, Q_ARG(int, m_reconnectIntervalMs));
}

void WebSocketClient::setAutoConnect(bool v)
{
    if (m_autoConnect == v) return;
    m_autoConnect = v;
    emit autoConnectChanged(v);
    if (v) connectIfReady();
}
