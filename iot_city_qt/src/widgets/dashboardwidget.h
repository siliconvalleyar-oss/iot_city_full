#ifndef DASHBOARDWIDGET_H
#define DASHBOARDWIDGET_H

#include <QWidget>
#include <QLabel>
#include <QJsonObject>
#include <QJsonArray>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtCharts/QBarSeries>
#include <QtCharts/QPieSeries>
#include <QtCharts/QChart>
#include "network/apiclient.h"

QT_CHARTS_USE_NAMESPACE

class DashboardWidget : public QWidget {
    Q_OBJECT
public:
    explicit DashboardWidget(ApiClient *api, QWidget *parent = nullptr);

public slots:
    void refreshData();

private:
    void setupUI();
    void updateKPIs(const QJsonObject &metrics);
    void updateTimeseries(const QJsonObject &data);
    void updateZones(const QJsonObject &data);
    void updateTraffic(const QJsonObject &data);

    ApiClient *m_api;

    QLabel *m_totalDevices, *m_activeDevices, *m_totalPower, *m_avgHealth, *m_uptime;
    QChartView *m_seriesView, *m_zonesView, *m_trafficView;
    QChart *m_seriesChart, *m_zonesChart, *m_trafficChart;
    QLineSeries *m_seriesLine;
};

#endif
