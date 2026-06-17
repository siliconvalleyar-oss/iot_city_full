#include "websocketclient.h"

WebSocketClient::WebSocketClient(QObject *parent) : QObject(parent) {
    m_socket = new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this);
    m_reconnectTimer = new QTimer(this);
    m_reconnectTimer->setInterval(5000);
    m_reconnectTimer->setSingleShot(true);

    connect(m_socket, &QWebSocket::connected, this, &WebSocketClient::onConnected);
    connect(m_socket, &QWebSocket::disconnected, this, &WebSocketClient::onDisconnected);
    connect(m_socket, &QWebSocket::textMessageReceived, this, &WebSocketClient::onTextMessageReceived);
#if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
    connect(m_socket, &QWebSocket::errorOccurred, this, &WebSocketClient::onError);
#else
    connect(m_socket, QOverload<QAbstractSocket::SocketError>::of(&QWebSocket::error), this, &WebSocketClient::onError);
#endif
    connect(m_reconnectTimer, &QTimer::timeout, this, &WebSocketClient::onReconnectTimer);
}

void WebSocketClient::connectToServer(const QString &url) { m_url = url; m_intentionalDisconnect = false; m_socket->open(QUrl(url)); }
void WebSocketClient::disconnectFromServer() { m_intentionalDisconnect = true; m_reconnectTimer->stop(); m_socket->close(); }
void WebSocketClient::sendMessage(const QJsonObject &msg) {
    if (m_socket->state() == QAbstractSocket::ConnectedState)
        m_socket->sendTextMessage(QJsonDocument(msg).toJson(QJsonDocument::Compact));
}
bool WebSocketClient::isConnected() const { return m_socket->state() == QAbstractSocket::ConnectedState; }

void WebSocketClient::onConnected() { emit connected(); m_reconnectTimer->stop(); }
void WebSocketClient::onDisconnected() { emit disconnected(); if (!m_intentionalDisconnect) m_reconnectTimer->start(); }
void WebSocketClient::onTextMessageReceived(const QString &message) {
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    if (doc.isObject()) emit messageReceived(doc.object());
}
void WebSocketClient::onError(QAbstractSocket::SocketError) { emit errorOccurred(m_socket->errorString()); }
void WebSocketClient::onReconnectTimer() { if (!m_url.isEmpty()) m_socket->open(QUrl(m_url)); }
