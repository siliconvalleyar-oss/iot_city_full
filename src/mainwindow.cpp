#include "mainwindow.h"
#include "widgets/devicedialog.h"
#include "utils/settings.h"
#include <QMenuBar>
#include <QMenu>
#include <QInputDialog>
#include <QMessageBox>
#include <QJsonArray>
#include <QSplitter>
#include <QStatusBar>
#include <QTimer>
#include <QLabel>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QTabWidget>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    m_api = new ApiClient(this);
    auto &s = Settings::instance();
    m_api->setHost(s.host(), s.port());
    m_ws = new WebSocketClient(this);

    setupUI();
    setupMenu();

    connect(m_ws, &WebSocketClient::messageReceived, this, &MainWindow::onWsMessage);
    connect(m_ws, &WebSocketClient::connected, this, [this]() { statusBar()->showMessage("WS Connected", 3000); });
    connect(m_ws, &WebSocketClient::disconnected, this, [this]() { statusBar()->showMessage("WS Disconnected", 3000); });
    connect(m_ws, &WebSocketClient::errorOccurred, this, [this](const QString &e) { statusBar()->showMessage("WS Error: " + e, 5000); });

    connectWebSocket();
    QTimer::singleShot(500, this, &MainWindow::refreshAll);
    m_logPanel->addLog(QJsonObject{{"event","app_started"},{"host", m_api->baseUrl()}});
}

MainWindow::~MainWindow() {}

void MainWindow::setupMenu() {
    auto *fileMenu = menuBar()->addMenu("&File");
    fileMenu->addAction("Configure Host...", this, &MainWindow::onConfigureHost, QKeySequence("Ctrl+H"));
    fileMenu->addSeparator();
    fileMenu->addAction("E&xit", this, &QWidget::close, QKeySequence("Ctrl+Q"));

    auto *devMenu = menuBar()->addMenu("&Device");
    devMenu->addAction("&Add Device...", this, &MainWindow::onAddDevice, QKeySequence("Ctrl+N"));
    devMenu->addAction("&Refresh Devices", this, &MainWindow::refreshAll, QKeySequence("Ctrl+R"));

    auto *simMenu = menuBar()->addMenu("&Simulate");
    simMenu->addAction("&Blackout", this, &MainWindow::onBlackout, QKeySequence("Ctrl+B"));
    simMenu->addAction("&Restore Power", this, &MainWindow::onRestore, QKeySequence("Ctrl+Shift+R"));

    auto *viewMenu = menuBar()->addMenu("&View");
    viewMenu->addAction("Toggle &Mesh", m_map, &MapWidget::setShowMesh, QKeySequence("Ctrl+M"));
    viewMenu->addAction("Toggle &Labels", m_map, &MapWidget::setShowLabels, QKeySequence("Ctrl+L"));
    viewMenu->addAction("Toggle C&overage", m_map, &MapWidget::setShowCoverage, QKeySequence("Ctrl+O"));
    viewMenu->addSeparator();
    viewMenu->addAction("Zoom &In", m_map, &MapWidget::zoomIn, QKeySequence("Ctrl++"));
    viewMenu->addAction("Zoom &Out", m_map, &MapWidget::zoomOut, QKeySequence("Ctrl+-"));
    viewMenu->addAction("&Reset View", m_map, &MapWidget::resetView, QKeySequence("Ctrl+0"));
}

void MainWindow::setupUI() {
    setWindowTitle("IoT City - Desktop Monitor");
    resize(1280, 800);
    setStyleSheet("QMainWindow { background: #040c18; } QMenuBar { background: #0a1428; color: #c8d8f0; } QMenuBar::item:selected { background: #1a3a6b; } QMenu { background: #0a1428; color: #c8d8f0; border: 1px solid #1a3a6b; } QMenu::item:selected { background: #1a3a6b; }");

    auto *central = new QWidget(this);
    auto *mainLay = new QVBoxLayout(central);
    mainLay->setContentsMargins(0,0,0,0);

    m_tabs = new QTabWidget;
    m_tabs->setStyleSheet("QTabWidget::pane { border: 1px solid #1a3a6b; background: #0a1428; } QTabBar::tab { background: #0a1428; color: #c8d8f0; padding: 8px 20px; border: 1px solid #1a3a6b; border-bottom: none; border-top-left-radius: 4px; border-top-right-radius: 4px; } QTabBar::tab:selected { background: #1a3a6b; }");

    auto *mapTab = new QWidget;
    auto *mapLay = new QHBoxLayout(mapTab);
    auto *mapSplitter = new QSplitter(Qt::Horizontal);
    m_map = new MapWidget;
    m_devicePanel = new DevicePanel;
    mapSplitter->addWidget(m_map);
    mapSplitter->addWidget(m_devicePanel);
    mapSplitter->setStretchFactor(0, 3);
    mapSplitter->setStretchFactor(1, 1);
    mapLay->addWidget(mapSplitter);
    m_tabs->addTab(mapTab, "Map");

    m_dashboard = new DashboardWidget(m_api);
    m_tabs->addTab(m_dashboard, "Dashboard");

    m_logPanel = new LogPanel;
    m_tabs->addTab(m_logPanel, "Logs");

    mainLay->addWidget(m_tabs);
    setCentralWidget(central);

    connect(m_map, &MapWidget::deviceSelected, this, &MainWindow::onDeviceSelected);
    connect(m_devicePanel, &DevicePanel::toggleRequested, this, &MainWindow::onToggleDevice);
    connect(m_devicePanel, &DevicePanel::powerRequested, this, &MainWindow::onPowerDevice);
    connect(m_devicePanel, &DevicePanel::deleteRequested, this, &MainWindow::onDeleteDevice);
}

void MainWindow::connectWebSocket() {
    m_ws->connectToServer(m_api->wsUrl());
}

void MainWindow::refreshAll() {
    m_api->getDevices([this](const QJsonDocument &doc){ onDevicesReceived(doc); }, [this](const QString &e){
        statusBar()->showMessage("Error fetching devices: " + e, 5000);
    });
}

void MainWindow::onDevicesReceived(const QJsonDocument &doc) {
    m_devices.clear();
    QJsonArray arr = doc.object().value("devices").toArray();
    if (arr.isEmpty()) arr = doc.array();
    for (const auto &v : arr) {
        Device dev = Device::fromJson(v.toObject());
        m_devices[dev.id] = dev;
    }
    m_map->setDevices(m_devices);
    statusBar()->showMessage(QString("Devices: %1").arg(m_devices.size()), 3000);
}

void MainWindow::updateDeviceFromJson(const QJsonObject &obj) {
    Device dev = Device::fromJson(obj);
    m_devices[dev.id] = dev;
    m_map->updateDevice(dev);
    if (dev.id == m_map->selectedDevice()) m_devicePanel->showDevice(dev);
}

void MainWindow::onWsMessage(const QJsonObject &msg) {
    m_logPanel->addLog(msg);
    QString type = msg["type"].toString();
    if (type == "device_update" || type == "device_status") {
        updateDeviceFromJson(msg["device"].toObject());
    } else if (type == "device_added") {
        updateDeviceFromJson(msg["device"].toObject());
    } else if (type == "device_removed") {
        m_map->removeDevice(msg["device_id"].toString());
        m_devices.remove(msg["device_id"].toString());
        if (m_map->selectedDevice() == msg["device_id"].toString()) m_devicePanel->clear();
    } else if (type == "simulation") {
        statusBar()->showMessage("Simulation: " + msg["event"].toString(), 5000);
        if (msg["event"].toString().contains("restore", Qt::CaseInsensitive)) refreshAll();
    }
}

void MainWindow::onDeviceSelected(const QString &id) {
    if (!id.isEmpty() && m_devices.contains(id)) m_devicePanel->showDevice(m_devices[id]);
    else m_devicePanel->clear();
}

void MainWindow::onToggleDevice(const QString &id) {
    m_api->toggleDevice(id, [this](const QJsonDocument &){ refreshAll(); }, [this](const QString &e){ statusBar()->showMessage("Toggle error: " + e, 5000); });
}
void MainWindow::onPowerDevice(const QString &id) {
    m_api->togglePower(id, [this](const QJsonDocument &){ refreshAll(); }, [this](const QString &e){ statusBar()->showMessage("Power error: " + e, 5000); });
}
void MainWindow::onDeleteDevice(const QString &id) {
    if (QMessageBox::question(this, "Delete Device", "Delete " + id + "?") == QMessageBox::Yes)
        m_api->deleteDevice(id, [this](const QJsonDocument &){ refreshAll(); }, [this](const QString &e){ statusBar()->showMessage("Delete error: " + e, 5000); });
}
void MainWindow::onAddDevice() {
    DeviceDialog dlg(this);
    if (dlg.exec() == QDialog::Accepted)
        m_api->createDevice(dlg.deviceData(), [this](const QJsonDocument &doc){ updateDeviceFromJson(doc.object()); }, [this](const QString &e){ statusBar()->showMessage("Create error: " + e, 5000); });
}
void MainWindow::onBlackout() {
    m_api->simulateBlackout([this](const QJsonDocument &){ statusBar()->showMessage("Blackout simulated", 5000); refreshAll(); }, [this](const QString &e){ statusBar()->showMessage("Blackout error: " + e, 5000); });
}
void MainWindow::onRestore() {
    m_api->simulateRestore([this](const QJsonDocument &){ statusBar()->showMessage("Power restored", 5000); refreshAll(); }, [this](const QString &e){ statusBar()->showMessage("Restore error: " + e, 5000); });
}
void MainWindow::onConfigureHost() {
    auto &s = Settings::instance();
    bool ok;
    QString host = QInputDialog::getText(this, "Configure Host", "Host:", QLineEdit::Normal, s.host(), &ok);
    if (!ok) return;
    int port = QInputDialog::getInt(this, "Configure Port", "Port:", s.port(), 1, 65535, 1, &ok);
    if (!ok) return;
    s.setHost(host);
    s.setPort(port);
    m_api->setHost(host, port);
    m_ws->disconnectFromServer();
    connectWebSocket();
    refreshAll();
    statusBar()->showMessage(QString("Connected to %1:%2").arg(host).arg(port), 5000);
}
