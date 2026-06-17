#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTabWidget>
#include <QMap>
#include <QJsonObject>
#include <QListWidget>
#include "network/apiclient.h"
#include "network/websocketclient.h"
#include "widgets/mapwidget.h"
#include "widgets/dashboardwidget.h"
#include "widgets/devicepanel.h"
#include "widgets/logpanel.h"
#include "models/device.h"

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

private slots:
    void onDevicesReceived(const QJsonDocument &doc);
    void onWsMessage(const QJsonObject &msg);
    void onDeviceSelected(const QString &id);
    void onToggleDevice(const QString &id);
    void onPowerDevice(const QString &id);
    void onDeleteDevice(const QString &id);
    void onAddDevice();
    void onBlackout();
    void onRestore();
    void onConfigureHost();
    void connectWebSocket();

private:
    void setupMenu();
    void setupUI();
    void updateDeviceFromJson(const QJsonObject &obj);
    void refreshAll();

    ApiClient *m_api;
    WebSocketClient *m_ws;
    QTabWidget *m_tabs;
    MapWidget *m_map;
    DashboardWidget *m_dashboard;
    DevicePanel *m_devicePanel;
    LogPanel *m_logPanel;
    QListWidget *m_deviceList;
    QMap<QString, Device> m_devices;
};

#endif
