#include "dashboardwidget.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QtCharts/QBarSet>
#include <QtCharts/QBarCategoryAxis>
#include <QtCharts/QValueAxis>
#include <QtCharts/QPieSeries>
#include <QtCharts/QtCharts>
#include <QTimer>

QT_CHARTS_USE_NAMESPACE

DashboardWidget::DashboardWidget(ApiClient *api, QWidget *parent) : QWidget(parent), m_api(api) {
    setupUI();
    auto *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &DashboardWidget::refreshData);
    timer->start(5000);
}

void DashboardWidget::setupUI() {
    auto *mainLay = new QVBoxLayout(this);
    auto *kpiGroup = new QGroupBox("Global KPIs");
    auto *kpiGrid = new QGridLayout(kpiGroup);
    QString kpiSS = "QLabel { color: #0af; font-size: 22px; font-weight: bold; }";

    m_totalDevices = new QLabel("--"); m_totalDevices->setStyleSheet(kpiSS);
    m_activeDevices = new QLabel("--"); m_activeDevices->setStyleSheet(kpiSS);
    m_totalPower = new QLabel("--"); m_totalPower->setStyleSheet(kpiSS);
    m_avgHealth = new QLabel("--"); m_avgHealth->setStyleSheet(kpiSS);
    m_uptime = new QLabel("--"); m_uptime->setStyleSheet(kpiSS);

    kpiGrid->addWidget(new QLabel("Total Devices:"), 0, 0);
    kpiGrid->addWidget(m_totalDevices, 0, 1);
    kpiGrid->addWidget(new QLabel("Active:"), 0, 2);
    kpiGrid->addWidget(m_activeDevices, 0, 3);
    kpiGrid->addWidget(new QLabel("Total Power:"), 0, 4);
    kpiGrid->addWidget(m_totalPower, 0, 5);
    kpiGrid->addWidget(new QLabel("Network Health:"), 1, 0);
    kpiGrid->addWidget(m_avgHealth, 1, 1);
    kpiGrid->addWidget(new QLabel("Uptime:"), 1, 2);
    kpiGrid->addWidget(m_uptime, 1, 3);
    mainLay->addWidget(kpiGroup);

    auto *chartsLay = new QHBoxLayout;
    m_seriesChart = new QChart;
    m_seriesChart->setTitle("Consumption (mW)");
    m_seriesChart->setTheme(QChart::ChartThemeDark);
    m_seriesChart->legend()->hide();
    m_seriesLine = new QLineSeries;
    m_seriesChart->addSeries(m_seriesLine);
    auto *axisX = new QDateTimeAxis; axisX->setFormat("hh:mm"); m_seriesChart->addAxis(axisX, Qt::AlignBottom); m_seriesLine->attachAxis(axisX);
    auto *axisY = new QValueAxis; axisY->setLabelFormat("%.1f"); m_seriesChart->addAxis(axisY, Qt::AlignLeft); m_seriesLine->attachAxis(axisY);
    m_seriesView = new QChartView(m_seriesChart); m_seriesView->setRenderHint(QPainter::Antialiasing);

    m_zonesChart = new QChart;
    m_zonesChart->setTitle("Consumption by Zone");
    m_zonesChart->setTheme(QChart::ChartThemeDark);
    m_zonesChart->legend()->hide();
    m_zonesView = new QChartView(m_zonesChart); m_zonesView->setRenderHint(QPainter::Antialiasing);

    m_trafficChart = new QChart;
    m_trafficChart->setTitle("Traffic (pps)");
    m_trafficChart->setTheme(QChart::ChartThemeDark);
    m_trafficView = new QChartView(m_trafficChart); m_trafficView->setRenderHint(QPainter::Antialiasing);

    chartsLay->addWidget(m_seriesView, 2);
    chartsLay->addWidget(m_zonesView, 1);
    chartsLay->addWidget(m_trafficView, 1);
    mainLay->addLayout(chartsLay);

    setStyleSheet("QGroupBox { color: #0af; font-weight: bold; border: 1px solid #1a3a6b; border-radius: 4px; margin-top: 1ex; padding: 10px; } "
                  "QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 5px; } "
                  "QWidget { background: #0a1428; }");
}

void DashboardWidget::refreshData() {
    m_api->getMetrics([this](const QJsonDocument &doc){ updateKPIs(doc.object()); }, [](const QString &){});
    m_api->getDashboardSummary([this](const QJsonDocument &doc){
        auto o = doc.object();
        if (o.contains("uptime_s")) m_uptime->setText(QString::number(o["uptime_s"].toDouble(), 'f', 0) + "s");
    }, [](const QString &){});
    m_api->getDashboardTimeseries(120, [this](const QJsonDocument &doc){ updateTimeseries(doc.object()); }, [](const QString &){});
    m_api->getDashboardZones([this](const QJsonDocument &doc){ updateZones(doc.object()); }, [](const QString &){});
    m_api->getDashboardTraffic([this](const QJsonDocument &doc){ updateTraffic(doc.object()); }, [](const QString &){});
}

void DashboardWidget::updateKPIs(const QJsonObject &m) {
    m_totalDevices->setText(QString::number(m["total_devices"].toInt()));
    m_activeDevices->setText(QString::number(m["active"].toInt()));
    m_totalPower->setText(QString::number(m["total_consumption_w"].toDouble(), 'f', 2) + " W");
    m_avgHealth->setText(QString::number(m["network_health"].toDouble(), 'f', 1) + "%");
}

void DashboardWidget::updateTimeseries(const QJsonObject &data) {
    m_seriesLine->clear();
    QJsonArray arr = data["timeseries"].toArray();
    for (const auto &v : arr) {
        auto o = v.toObject();
        m_seriesLine->append(o["ts"].toDouble(), o["total_power_mW"].toDouble());
    }
}

void DashboardWidget::updateZones(const QJsonObject &data) {
    m_zonesChart->removeAllSeries();
    auto *bset = new QBarSet("Zones");
    QStringList categories;
    QJsonObject zones = data["zones"].toObject();
    for (auto it = zones.begin(); it != zones.end(); ++it) {
        auto zo = it.value().toObject();
        *bset << zo["total_power_mW"].toDouble();
        categories << zo["zone"].toString();
    }
    auto *series = new QBarSeries;
    series->append(bset);
    m_zonesChart->addSeries(series);
    auto *axisX = new QBarCategoryAxis; axisX->append(categories);
    auto *axisY = new QValueAxis; axisY->setLabelFormat("%.1f");
    m_zonesChart->addAxis(axisX, Qt::AlignBottom); series->attachAxis(axisX);
    m_zonesChart->addAxis(axisY, Qt::AlignLeft); series->attachAxis(axisY);
}

void DashboardWidget::updateTraffic(const QJsonObject &data) {
    m_trafficChart->removeAllSeries();
    auto *pie = new QPieSeries;
    QJsonObject traffic = data["traffic"].toObject();
    for (auto it = traffic.begin(); it != traffic.end(); ++it) {
        auto to = it.value().toObject();
        pie->append(to["node_id"].toString(), to["tx_rate_pps"].toDouble());
    }
    m_trafficChart->addSeries(pie);
}
