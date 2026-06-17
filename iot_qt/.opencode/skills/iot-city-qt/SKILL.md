# IoT City Qt — Skill

## Comandos útiles

```bash
# Compilar
mkdir -p build && cd build && cmake .. && cmake --build . -j$(nproc)

# Ejecutar
./build/iot_city_qt
```

## Estructura

- `src/models/` — structs Device, DashboardSummary, etc.
- `src/network/` — ApiClient (REST), WebSocketClient (WS)
- `src/widgets/` — MapWidget, DashboardWidget, DevicePanel, DeviceDialog, LogPanel
- `src/utils/` — Settings (QSettings persistente)

## Convenciones

- Usar `Device::fromJson()` para parsear dispositivos
- Usar `ApiClient` con lambdas `JsonCb`/`ErrCb` para llamadas asíncronas
- WebSocket auto-reconnect cada 5s
- Estilo oscuro cyberpunk: fondo `#040c18`, texto `#c8d8f0`, acento `#0af`
