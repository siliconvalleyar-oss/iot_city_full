# IoT City — Architecture

## Vista General

```
┌─────────────┐     HTTP/WS      ┌──────────────┐
│  Qt Desktop  │ ◄──────────────► │  FastAPI      │
│  (iot_qt)    │                  │  Backend      │
└─────────────┘                   │  (iot_city_web)│
                                  └──────┬───────┘
                                         │
                                  ┌──────┴───────┐
                                  │  Simulador    │
                                  │  Red Mesh     │
                                  └──────────────┘
```

## Componentes del Qt Client

### src/main.cpp
- Punto de entrada. Crea QApplication, muestra splash screen (3s), luego MainWindow.

### src/mainwindow.h/.cpp
- Ventana principal con QTabWidget de 3 pestañas: **Map**, **Dashboard**, **Logs**.
- MenuBar: File (Configure Host, Exit), Device (Add, Refresh), Simulate (Blackout, Restore), View (toggles).
- Conecta WebSocket y refresca dispositivos al inicio.

### src/models/
- **device.h** — `Device` struct con `fromJson`, `statusColor()`, `statusLabel()`, `isRouter()`, etc.
- **dashboardmetrics.h** — `DashboardSummary`, `ZoneMetrics`, `TimeSample`, `TrafficNode`.

### src/network/
- **apiclient.h/.cpp** — `ApiClient` con 12+ endpoints REST usando `QNetworkAccessManager`. Callbacks asíncronos `JsonCb`/`ErrCb`.
- **websocketclient.h/.cpp** — `WebSocketClient` con auto-reconnect cada 5s.

### src/widgets/
- **mapwidget.h/.cpp** — Mapa interactivo 800x600 con QPainter. Dispositivos como círculos + emoji, conexiones mesh, coverage rings, zoom/pan/drag.
- **dashboardwidget.h/.cpp** — KPIs globales + charts: línea (consumo), barras (zonas), dona (tráfico). Refresca cada 5s.
- **devicepanel.h/.cpp** — Panel lateral con detalle del dispositivo seleccionado. Botones Toggle/Power/Delete.
- **devicedialog.h/.cpp** — Diálogo para agregar/editar dispositivo.
- **logpanel.h/.cpp** — Logs en tiempo real desde WebSocket.

### src/utils/
- **settings.h/.cpp** — `Settings` singleton con `QSettings` persistente (host, port).

## Flujo de Datos

1. **Startup**: MainWindow → ApiClient::getDevices() → backend → onDevicesReceived() → MapWidget::setDevices()
2. **Tiempo real**: WebSocket → onWsMessage() → updateDeviceFromJson() → MapWidget::updateDevice()
3. **Dashboard**: Timer cada 5s → refreshData() → 4 llamadas REST → updateKPIs/Timeseries/Zones/Traffic
4. **Interacción**: Click mapa → deviceSelected → DevicePanel::showDevice() → botones → ApiClient POST
