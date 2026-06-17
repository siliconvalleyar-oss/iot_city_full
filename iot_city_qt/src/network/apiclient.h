#ifndef APICLIENT_H
#define APICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <functional>

class ApiClient : public QObject {
    Q_OBJECT
public:
    explicit ApiClient(QObject *parent = nullptr);
    void setHost(const QString &host, int port = 5062);
    QString baseUrl() const;
    QString wsUrl() const;

    using JsonCb = std::function<void(const QJsonDocument &)>;
    using ErrCb = std::function<void(const QString &)>;

    void getDevices(JsonCb ok, ErrCb err);
    void createDevice(const QJsonObject &dev, JsonCb ok, ErrCb err);
    void deleteDevice(const QString &id, JsonCb ok, ErrCb err);
    void toggleDevice(const QString &id, JsonCb ok, ErrCb err);
    void togglePower(const QString &id, JsonCb ok, ErrCb err);
    void getMetrics(JsonCb ok, ErrCb err);
    void getMesh(JsonCb ok, ErrCb err);
    void simulateBlackout(JsonCb ok, ErrCb err);
    void simulateRestore(JsonCb ok, ErrCb err);
    void getDashboardSummary(JsonCb ok, ErrCb err);
    void getDashboardTimeseries(int n, JsonCb ok, ErrCb err);
    void getDashboardTraffic(JsonCb ok, ErrCb err);
    void getDashboardZones(JsonCb ok, ErrCb err);

signals:
    void hostChanged();

private:
    void doGet(const QString &path, JsonCb ok, ErrCb err);
    void doPost(const QString &path, const QJsonObject &body, JsonCb ok, ErrCb err);
    QNetworkAccessManager *m_nam;
    QString m_host = "ms7851.local";
    int m_port = 5062;
};

#endif
