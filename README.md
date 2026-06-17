# IoT City Full — Monorepo

Sistema de monitoreo urbano con red mesh Zigbee. Backend FastAPI + App Flutter.

---

## Ramas

| Rama | Contenido |
|------|-----------|
| `main` | Este README (visión general del monorepo) |
| `web` | Backend Python + frontend web: `iot_city_web/` |
| `flt` | App Flutter: `iot_city_flt/` |

---

## Rama `web` — Backend + Frontend Web

Servidor FastAPI con simulación de red mesh Zigbee, WebSocket en tiempo real y dashboard interactivo.

```bash
git checkout web

# Instalar e iniciar
chmod +x scripts/install_system.sh
./scripts/install_system.sh
./scripts/control_system.sh start

# Abrir en navegador
http://localhost:5062
```

### API REST

| Endpoint | Descripción |
|----------|-------------|
| `GET /api/devices` | Listar dispositivos |
| `GET /api/metrics` | Métricas globales |
| `GET /api/mesh` | Topología de red |
| `WS /ws` | WebSocket tiempo real |

Documentación interactiva: `http://localhost:5062/api/docs`

### Scripts principales

| Script | Uso |
|--------|-----|
| `scripts/control_system.sh` | `start/stop/restart/status/logs` |
| `scripts/add_device.sh` | Agregar/quitar dispositivos |
| `scripts/install_system.sh` | Instalación completa |

---

## Rama `flt` — App Flutter

Dashboard móvil con métricas urbanas, gráficos interactivos y mapa de dispositivos.

```bash
git checkout flt

# Dependencias
flutter pub get

# Desarrollo
flutter run

# Producción
flutter build apk --release
```

### Configuración de conexión

Host y puerto configurables desde la app (Settings). Por defecto `ms7851.local:5062`.

### Widgets principales

| Widget | Archivo | Descripción |
|--------|---------|-------------|
| `DashboardScreen` | `lib/screens/dashboard_screen.dart` | KPIs + gráficos + mapa |
| `CityMapPainter` | `lib/widgets/map/city_map_painter.dart` | Mapa mesh con CustomPainter |
| `DeviceMap` | `lib/widgets/map/device_map.dart` | Mapa interactivo zoom/pan |
| `ApiService` | `lib/services/api_service.dart` | Cliente REST |
| `WebSocketService` | `lib/services/websocket_service.dart` | WS con auto-reconnect |

---

## Repositorio

```bash
git clone https://github.com/siliconvalleyar-oss/iot_city_full.git
cd iot_city_full
```
