#ifndef DEVICE_H
#define DEVICE_H

#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include <QList>
#include <QColor>

struct Device {
    QString id, deviceType, icon, color, street;
    double x = 0, y = 0, level = 100, consumption = 0, signal = 0, lastSeen = 0;
    bool active = true, powered = true;
    int packetsSent = 0, packetsReceived = 0;
    QList<QString> connectedTo, endDevices;

    static Device fromJson(const QJsonObject &obj) {
        Device d;
        d.id = obj["id"].toString();
        d.deviceType = obj["device_type"].toString();
        d.icon = obj["icon"].toString("lamp");
        d.color = obj["color"].toString("#FFD700");
        d.street = obj["street"].toString();
        d.x = obj["x"].toDouble();
        d.y = obj["y"].toDouble();
        d.level = obj["level"].toDouble(100);
        d.consumption = obj["consumption"].toDouble();
        d.signal = obj["signal"].toDouble();
        d.active = obj["active"].toBool(true);
        d.powered = obj["powered"].toBool(true);
        d.packetsSent = obj["packets_sent"].toInt();
        d.packetsReceived = obj["packets_received"].toInt();
        d.lastSeen = obj["last_seen"].toDouble();
        for (const auto &v : obj["connected_to"].toArray()) d.connectedTo.append(v.toString());
        for (const auto &v : obj["end_devices"].toArray()) d.endDevices.append(v.toString());
        return d;
    }

    QColor statusColor() const {
        if (!powered) return QColor("#556688");
        if (!active) return QColor("#ff3344");
        if (level < 50) return QColor("#ffaa00");
        return QColor("#00ff88");
    }

    QString statusLabel() const {
        if (!powered) return "Sin tensión";
        if (!active) return "Apagado";
        if (level < 50) return "Alerta";
        return "Activo";
    }

    bool isRouter() const { return deviceType == "router"; }
    bool isEndDevice() const { return deviceType == "end_device"; }
    bool isCamera() const { return deviceType == "camera"; }
};

struct NetworkMetrics {
    int totalDevices = 0, powered = 0, unpowered = 0, active = 0, inactive = 0;
    int routers = 0, endDevices = 0, cameras = 0;
    double totalConsumptionW = 0, networkHealth = 0, timestamp = 0;

    static NetworkMetrics fromJson(const QJsonObject &obj) {
        NetworkMetrics m;
        m.totalDevices = obj["total_devices"].toInt();
        m.powered = obj["powered"].toInt();
        m.unpowered = obj["unpowered"].toInt();
        m.active = obj["active"].toInt();
        m.inactive = obj["inactive"].toInt();
        m.routers = obj["routers"].toInt();
        m.endDevices = obj["end_devices"].toInt();
        m.cameras = obj["cameras"].toInt();
        m.totalConsumptionW = obj["total_consumption_w"].toDouble();
        m.networkHealth = obj["network_health"].toDouble();
        m.timestamp = obj["timestamp"].toDouble();
        return m;
    }
};

struct LogEntry {
    QString timestamp, eventType, deviceId, detail;
    static LogEntry fromJson(const QJsonObject &o) {
        return {o["timestamp"].toString(), o["event_type"].toString(), o["device_id"].toString(), o["detail"].toString()};
    }
};

#endif
