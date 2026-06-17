#include "apiclient.h"
#include <QNetworkRequest>
#include <QUrlQuery>

ApiClient::ApiClient(QObject *parent) : QObject(parent), m_nam(new QNetworkAccessManager(this)) {}

void ApiClient::setHost(const QString &host, int port) { m_host = host; m_port = port; emit hostChanged(); }
QString ApiClient::baseUrl() const { return QString("http://%1:%2/api").arg(m_host).arg(m_port); }
QString ApiClient::wsUrl() const { return QString("ws://%1:%2/ws").arg(m_host).arg(m_port); }

void ApiClient::doGet(const QString &path, JsonCb ok, ErrCb err) {
    auto *reply = m_nam->get(QNetworkRequest(QUrl(baseUrl() + path)));
    connect(reply, &QNetworkReply::finished, this, [reply, ok, err]() {
        if (reply->error() == QNetworkReply::NoError) { if (ok) ok(QJsonDocument::fromJson(reply->readAll())); }
        else { if (err) err(reply->errorString()); }
        reply->deleteLater();
    });
}

void ApiClient::doPost(const QString &path, const QJsonObject &body, JsonCb ok, ErrCb err) {
    auto req = QNetworkRequest(QUrl(baseUrl() + path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    auto *reply = m_nam->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [reply, ok, err]() {
        if (reply->error() == QNetworkReply::NoError) { if (ok) ok(QJsonDocument::fromJson(reply->readAll())); }
        else { if (err) err(reply->errorString()); }
        reply->deleteLater();
    });
}

#define IMPL_GET(name, path) void ApiClient::name(JsonCb ok, ErrCb err) { doGet(path, ok, err); }
#define IMPL_POST(name, path) void ApiClient::name(JsonCb ok, ErrCb err) { doPost(path, {}, ok, err); }

IMPL_GET(getDevices, "/devices")
IMPL_GET(getMetrics, "/metrics")
IMPL_GET(getMesh, "/mesh")
IMPL_GET(getDashboardSummary, "/dashboard/summary")
void ApiClient::getDashboardTimeseries(int n, JsonCb ok, ErrCb err) { doGet(QString("/dashboard/timeseries/global?last_n=%1").arg(n), ok, err); }
IMPL_GET(getDashboardTraffic, "/dashboard/traffic")
IMPL_GET(getDashboardZones, "/dashboard/zones")
IMPL_POST(simulateBlackout, "/simulate/blackout")
IMPL_POST(simulateRestore, "/simulate/restore")

void ApiClient::createDevice(const QJsonObject &dev, JsonCb ok, ErrCb err) { doPost("/devices", dev, ok, err); }
void ApiClient::deleteDevice(const QString &id, JsonCb ok, ErrCb err) {
    auto *reply = m_nam->deleteResource(QNetworkRequest(QUrl(baseUrl() + "/devices/" + id)));
    connect(reply, &QNetworkReply::finished, this, [reply, ok, err]() {
        if (reply->error() == QNetworkReply::NoError) { if (ok) ok(QJsonDocument::fromJson(reply->readAll())); }
        else { if (err) err(reply->errorString()); }
        reply->deleteLater();
    });
}
void ApiClient::toggleDevice(const QString &id, JsonCb ok, ErrCb err) { doPost("/devices/" + id + "/toggle", {}, ok, err); }
void ApiClient::togglePower(const QString &id, JsonCb ok, ErrCb err) { doPost("/devices/" + id + "/power", {}, ok, err); }
