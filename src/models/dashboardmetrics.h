#ifndef DASHBOARDMETRICS_H
#define DASHBOARDMETRICS_H

#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include <QList>
#include <QPair>

struct DashboardSummary {
    double totalPowerMW = 0; int activeNodes = 0, totalNodes = 0, unpowered = 0;
    double totalEnergyMWh = 0, avgEfficiencyScore = 0, estimatedDailyWh = 0, uptimeS = 0;
    QList<QPair<QString, double>> topConsumers;
    QList<QString> zones;

    static DashboardSummary fromJson(const QJsonObject &obj) {
        DashboardSummary s;
        s.totalPowerMW = obj["total_power_mW"].toDouble();
        s.activeNodes = obj["active_nodes"].toInt();
        s.totalNodes = obj["total_nodes"].toInt();
        s.unpowered = obj["unpowered"].toInt();
        s.totalEnergyMWh = obj["total_energy_mWh"].toDouble();
        s.avgEfficiencyScore = obj["avg_efficiency_score"].toDouble();
        s.estimatedDailyWh = obj["estimated_daily_Wh"].toDouble();
        s.uptimeS = obj["uptime_s"].toDouble();
        for (const auto &tc : obj["top_consumers"].toArray()) {
            auto arr = tc.toArray();
            if (arr.size() >= 2) s.topConsumers.append({arr[0].toString(), arr[1].toDouble()});
        }
        for (const auto &z : obj["zones"].toArray()) s.zones.append(z.toString());
        return s;
    }
};

struct ZoneMetrics {
    QString zone; int nodeCount = 0, totalPacketsTx = 0;
    double totalPowerMW = 0, totalEnergyMWh = 0, avgEfficiencyScore = 0;
    static ZoneMetrics fromJson(const QJsonObject &obj) {
        ZoneMetrics z;
        z.zone = obj["zone"].toString();
        z.nodeCount = obj["node_count"].toInt();
        z.totalPowerMW = obj["total_power_mW"].toDouble();
        z.totalEnergyMWh = obj["total_energy_mWh"].toDouble();
        z.totalPacketsTx = obj["total_packets_tx"].toInt();
        z.avgEfficiencyScore = obj["avg_efficiency_score"].toDouble();
        return z;
    }
};

struct TimeSample { double ts = 0, totalPowerMW = 0; };
struct TrafficNode { QString nodeId, zone; double txRatePps = 0; int totalTx = 0; };
struct HeatmapNode { QString nodeId; double x = 0, y = 0, powerMW = 0; };

#endif
