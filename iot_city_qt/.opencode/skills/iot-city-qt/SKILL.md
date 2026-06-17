# IoT City Qt — Skill

## Comandos útiles

```bash
# Compilar (desde iot_city_qt/)
cmake -S . -B build && make -j$(nproc) -C build

# Ejecutar
./build/iot_qt
```

## Estructura

- `src/models/` — structs Device, DashboardMetrics, etc.
- `src/network/` — ApiClient (REST), WebSocketClient (WS)
- `src/widgets/` — MapWidget, DashboardWidget, DevicePanel, DeviceDialog, LogPanel
- `src/utils/` — Settings (QSettings persistente)
- `resources.qrc` — Recursos embebidos (icon.png)

## Convenciones

- Usar `Device::fromJson()` para parsear dispositivos
- Usar `ApiClient` con lambdas `JsonCb`/`ErrCb` para llamadas asíncronas
- WebSocket auto-reconnect cada 5s
- Estilo oscuro cyberpunk: fondo `#040c18`, texto `#c8d8f0`, acento `#0af`
- Icono y splash con `:/assets/icon.png` via QRC
- `CMakeLists.txt` debe incluir `${RESOURCES}` en `add_executable`
- Qt5 (5.15.13): usar `QOverload<QAbstractSocket::SocketError>::of(&QWebSocket::error)` para error signal
- Dashboard: field names del backend (`total_nodes`, `total_power_mW`, etc.)
- Backend default: `192.168.1.41:5062`
