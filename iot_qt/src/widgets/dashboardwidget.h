#ifndef DASHBOARDWIDGET_H
#define DASHBOARDWIDGET_H

#include <QWidget>
#include <QLabel>
#include <QMap>
#include <QJsonObject>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtCharts/QBarSeries>
#include <QtCharts/QPieSeries>
#include <QtCharts/QChart>
#include "network/apiclient.h"

class DashboardWidget : public QWidget {
    Q_OBJECT
public:
    explicit DashboardWidget(ApiClient *api, QWidget *parent = nullptr);

public slots:
    void refreshData();
    void setTrafficInterval(int seconds);

private:
    void setupUI();
    void updateKPIs(const QJsonObject &summary);
    void updateTimeseries(const QJsonArray &data);
    void updateZones(const QJsonArray &zones);
    void updateTraffic(const QJsonObject &traffic);

    ApiClient *m_api;

    QLabel *m_totalDevices, *m_activeDevices, *m_totalPower, *m_avgHealth, *m_networkLoad, *m_uptime;
    QChartView *m_seriesView, *m_zonesView, *m_trafficView;
    QChart *m_seriesChart, *m_zonesChart, *m_trafficChart;
    QLineSeries *m_seriesLine;
    QBarSeries *m_zonesBarSeries;
    QPieSeries *m_trafficPie;
    int m_trafficInterval = 30;
};

#endif
