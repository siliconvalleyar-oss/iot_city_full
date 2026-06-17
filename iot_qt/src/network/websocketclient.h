#ifndef WEBSOCKETCLIENT_H
#define WEBSOCKETCLIENT_H

#include <QObject>
#include <QWebSocket>
#include <QTimer>
#include <QJsonDocument>
#include <QJsonObject>

class WebSocketClient : public QObject {
    Q_OBJECT
public:
    explicit WebSocketClient(QObject *parent = nullptr);
    void connectToServer(const QString &url);
    void disconnectFromServer();
    void sendMessage(const QJsonObject &msg);
    bool isConnected() const;

signals:
    void connected();
    void disconnected();
    void messageReceived(const QJsonObject &msg);
    void errorOccurred(const QString &error);

private slots:
    void onConnected();
    void onDisconnected();
    void onTextMessageReceived(const QString &message);
    void onError(QAbstractSocket::SocketError error);
    void onReconnectTimer();

private:
    QWebSocket *m_socket;
    QTimer *m_reconnectTimer;
    QString m_url;
    bool m_intentionalDisconnect = false;
};

#endif
