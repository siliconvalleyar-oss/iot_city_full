#include "dashboardwidget.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QJsonArray>
#include <QtCharts/QBarSet>
#include <QtCharts/QBarCategoryAxis>
#include <QtCharts/QValueAxis>
#include <QtCharts/QPieSeries>
#include <QtCharts/QPieSlice>
#include <QDateTimeAxis>

DashboardWidget::DashboardWidget(ApiClient *api, QWidget *parent) : QWidget(parent), m_api(api) {
    setupUI();
    auto *timer = new QTimer(this);
    timer->setInterval(m_trafficInterval * 1000);
    connect(timer, &QTimer::timeout, this, &DashboardWidget::refreshData);
    timer->start();
}

void DashboardWidget::setupUI() {
    auto *mainLay = new QVBoxLayout(this);

    auto *kpiGroup = new QGroupBox("Global KPIs");
    auto *kpiGrid = new QGridLayout(kpiGroup);
    m_totalDevices = new QLabel("--"), m_activeDevices = new QLabel("--");
    m_totalPower = new QLabel("--"), m_avgHealth = new QLabel("--");
    m_networkLoad = new QLabel("--"), m_uptime = new QLabel("--");
    QString kpiSS = "QLabel { color: #0af; font-size: 22px; font-weight: bold; }";
    m_totalDevices->setStyleSheet(kpiSS);
    m_activeDevices->setStyleSheet(kpiSS);
    m_totalPower->setStyleSheet(kpiSS);
    m_avgHealth->setStyleSheet(kpiSS);
    m_networkLoad->setStyleSheet(kpiSS);
    m_uptime->setStyleSheet(kpiSS);
    kpiGrid->addWidget(new QLabel("Total Devices:"), 0, 0);
    kpiGrid->addWidget(m_totalDevices, 0, 1);
    kpiGrid->addWidget(new QLabel("Active:"), 0, 2);
    kpiGrid->addWidget(m_activeDevices, 0, 3);
    kpiGrid->addWidget(new QLabel("Total Power:"), 0, 4);
    kpiGrid->addWidget(m_totalPower, 0, 5);
    kpiGrid->addWidget(new QLabel("Avg Health:"), 1, 0);
    kpiGrid->addWidget(m_avgHealth, 1, 1);
    kpiGrid->addWidget(new QLabel("Network Load:"), 1, 2);
    kpiGrid->addWidget(m_networkLoad, 1, 3);
    kpiGrid->addWidget(new QLabel("Uptime:"), 1, 4);
    kpiGrid->addWidget(m_uptime, 1, 5);
    mainLay->addWidget(kpiGroup);

    auto *chartsLay = new QHBoxLayout;
    m_seriesChart = new QChart;
    m_seriesChart->setTitle("Consumption (W)");
    m_seriesChart->setTheme(QChart::ChartThemeDark);
    m_seriesChart->legend()->hide();
    m_seriesLine = new QLineSeries;
    m_seriesChart->addSeries(m_seriesLine);
    auto *axisX = new QDateTimeAxis; axisX->setFormat("hh:mm"); axisX->setTitleText("Time"); m_seriesChart->addAxis(axisX, Qt::AlignBottom); m_seriesLine->attachAxis(axisX);
    auto *axisY = new QValueAxis; axisY->setTitleText("W"); axisY->setLabelFormat("%d"); m_seriesChart->addAxis(axisY, Qt::AlignLeft); m_seriesLine->attachAxis(axisY);
    m_seriesView = new QChartView(m_seriesChart); m_seriesView->setRenderHint(QPainter::Antialiasing);

    m_zonesChart = new QChart;
    m_zonesChart->setTitle("Consumption by Zone");
    m_zonesChart->setTheme(QChart::ChartThemeDark);
    m_zonesChart->legend()->hide();
    m_zonesBarSeries = new QBarSeries;
    m_zonesChart->addSeries(m_zonesBarSeries);
    auto *axisZone = new QBarCategoryAxis; m_zonesChart->addAxis(axisZone, Qt::AlignBottom); m_zonesBarSeries->attachAxis(axisZone);
    auto *axisZoneY = new QValueAxis; axisZoneY->setLabelFormat("%d"); m_zonesChart->addAxis(axisZoneY, Qt::AlignLeft); m_zonesBarSeries->attachAxis(axisZoneY);
    m_zonesView = new QChartView(m_zonesChart); m_zonesView->setRenderHint(QPainter::Antialiasing);

    m_trafficChart = new QChart;
    m_trafficChart->setTitle("Traffic Distribution");
    m_trafficChart->setTheme(QChart::ChartThemeDark);
    m_trafficPie = new QPieSeries;
    m_trafficChart->addSeries(m_trafficPie);
    m_trafficView = new QChartView(m_trafficChart); m_trafficView->setRenderHint(QPainter::Antialiasing);

    chartsLay->addWidget(m_seriesView, 2);
    chartsLay->addWidget(m_zonesView, 1);
    chartsLay->addWidget(m_trafficView, 1);
    mainLay->addLayout(chartsLay);

    setStyleSheet("QGroupBox { color: #0af; font-weight: bold; border: 1px solid #1a3a6b; border-radius: 4px; margin-top: 1ex; padding: 10px; } "
                  "QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 5px; } "
                  "QWidget { background: #0a1428; }");
}

void DashboardWidget::setTrafficInterval(int seconds) { m_trafficInterval = seconds; }

void DashboardWidget::refreshData() {
    m_api->getDashboardSummary([this](const QJsonDocument &doc){ updateKPIs(doc.object()); }, [](const QString &){});
    m_api->getDashboardTimeseries(120, [this](const QJsonDocument &doc){ updateTimeseries(doc.array()); }, [](const QString &){});
    m_api->getDashboardZones([this](const QJsonDocument &doc){ updateZones(doc.array()); }, [](const QString &){});
    m_api->getDashboardTraffic([this](const QJsonDocument &doc){ updateTraffic(doc.object()); }, [](const QString &){});
}

void DashboardWidget::updateKPIs(const QJsonObject &s) {
    m_totalDevices->setText(QString::number(s["total_devices"].toInt()));
    m_activeDevices->setText(QString::number(s["active_devices"].toInt()));
    m_totalPower->setText(QString::number(s["total_power"].toDouble(), 'f', 1) + " W");
    m_avgHealth->setText(QString::number(s["avg_health"].toDouble(), 'f', 1) + "%");
    m_networkLoad->setText(QString::number(s["network_load"].toDouble() * 100, 'f', 1) + "%");
    m_uptime->setText(s["uptime"].toString());
}

void DashboardWidget::updateTimeseries(const QJsonArray &data) {
    m_seriesLine->clear();
    for (const auto &v : data) {
        auto obj = v.toObject();
        m_seriesLine->append(obj["ts"].toDouble(), obj["value"].toDouble());
    }
}

void DashboardWidget::updateZones(const QJsonArray &zones) {
    m_zonesChart->removeAllSeries();
    auto *bset = new QBarSet("Zones");
    QStringList categories;
    for (const auto &z : zones) {
        auto obj = z.toObject();
        *bset << obj["consumption"].toDouble();
        categories << obj["name"].toString();
    }
    auto *series = new QBarSeries;
    series->append(bset);
    m_zonesChart->addSeries(series);
    auto *axis = qobject_cast<QBarCategoryAxis*>(m_zonesChart->axes(Qt::Horizontal).first());
    if (axis) { axis->clear(); axis->append(categories); }
    series->attachAxis(axis);
    series->attachAxis(m_zonesChart->axes(Qt::Vertical).first());
}

void DashboardWidget::updateTraffic(const QJsonObject &traffic) {
    m_trafficPie->clear();
    for (auto it = traffic.begin(); it != traffic.end(); ++it)
        m_trafficPie->append(it.key(), it.value().toDouble());
}
