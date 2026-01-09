#pragma once

#include <QObject>
#include <QWebSocket>
#include <QJsonObject>
#include <QJsonDocument>
#include <QUrl>
#include <QTimer>
#include <QAbstractSocket>
#include <QThread>
#include <QQmlParserStatus>

class WebSocketClientWorker : public QObject
{
    Q_OBJECT
public:
    explicit WebSocketClientWorker(QObject* parent = nullptr);

public slots:
    void init();
    void setUrl(const QUrl& u);
    void setAutoReconnectEnabled(bool en);
    void setReconnectIntervalMs(int ms);
    void connectToServer();
    void close();
    void sendRequest(const QJsonObject& req);
    void shutdown();
    void tryReconnect();

signals:
    void connected();
    void disconnected();
    void errorOccurred(QAbstractSocket::SocketError);
    void textMessageReceived(const QString&);
    void binaryMessageReceived(const QByteArray&);
    void stateChanged(QAbstractSocket::SocketState);

private slots:
    void onConnected();
    void onDisconnected();
    void onError(QAbstractSocket::SocketError e);
    void onText(const QString& s);
    void onBinary(const QByteArray& b);
    void onStateChanged(QAbstractSocket::SocketState s);

private:
    QWebSocket* m_socket { nullptr };
    QTimer* m_timer { nullptr };
    QUrl m_url;
    bool m_autoReconnect { true };
    bool m_userClose { false };
    int m_reconnectIntervalMs { 5000 };
};

class WebSocketClient : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(bool autoReconnectEnabled READ autoReconnectEnabled WRITE setAutoReconnectEnabled NOTIFY autoReconnectEnabledChanged)
    Q_PROPERTY(int reconnectIntervalSeconds READ reconnectIntervalSeconds WRITE setReconnectIntervalSeconds NOTIFY reconnectIntervalChanged)
    Q_PROPERTY(bool autoConnect READ autoConnect WRITE setAutoConnect NOTIFY autoConnectChanged)

public:
    explicit WebSocketClient(QObject *parent = nullptr);
    explicit WebSocketClient(const QUrl &url, QObject *parent = nullptr);
    ~WebSocketClient() override;

    Q_INVOKABLE void connectToServer();
    Q_INVOKABLE void close();
    Q_INVOKABLE void sendRequest(const QJsonObject &obj);

    Q_INVOKABLE void startWorkerThread();
    Q_INVOKABLE void stopWorkerThread();

    QUrl url() const noexcept { return m_url; }
    void setUrl(const QUrl &url);

    bool autoReconnectEnabled() const noexcept { return m_autoReconnectEnabled; }
    void setAutoReconnectEnabled(bool enabled);

    int reconnectIntervalSeconds() const noexcept { return m_reconnectIntervalMs / 1000; }
    void setReconnectIntervalSeconds(int seconds);

    bool autoConnect() const noexcept { return m_autoConnect; }
    void setAutoConnect(bool v);

signals:
    void urlChanged(const QUrl &url);
    void connected();
    void disconnected();
    void errorOccurred(QAbstractSocket::SocketError error);
    void textMessageReceived(const QString &message);
    void binaryMessageReceived(const QByteArray &message);
    void autoReconnectEnabledChanged(bool enabled);
    void reconnectIntervalChanged(int seconds);
    void stateChanged(QAbstractSocket::SocketState state);
    void autoConnectChanged(bool v);

public:
    void classBegin() override;
    void componentComplete() override;

private:
    void applyInitialStateToWorker();
    void connectIfReady();

private:
    QUrl m_url;
    int m_reconnectIntervalMs { 5000 };
    bool m_autoReconnectEnabled { true };
    bool m_qmlCompleted { false };
    bool m_autoConnect { true };

    QThread* m_thread { nullptr };
    WebSocketClientWorker* m_worker { nullptr };
};
