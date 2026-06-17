# IoT City Full

Sistema de monitoreo urbano con red mesh Zigbee.  
Backend FastAPI + App Flutter + Cliente Qt Desktop.

```
/home/optimus/Documentos/src/flutter_src/iot_city/
├── iot_city_web/          # Backend Python + Frontend Web
├── iot_city_flt/          # App Flutter (móvil)
├── iot_qt/                # Cliente Qt Desktop (C++17)
├── .gitignore
└── README.md
```

---

## iot_city_web/ — Backend + Frontend Web

Servidor FastAPI con simulación de red mesh Zigbee, WebSocket en tiempo real y dashboard interactivo.

```bash
cd iot_city_web

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

---

## iot_city_flt/ — App Flutter

Dashboard móvil con métricas urbanas, gráficos interactivos y mapa de dispositivos.

```bash
cd iot_city_flt
flutter pub get
flutter run
```

### Configuración

Host y puerto configurables desde la app (Settings).  
Por defecto `ms7851.local:5062`.

---

## iot_qt/ — Cliente Qt Desktop

Cliente de escritorio C++17 con Qt 5.15+ / 6.x.

```bash
cd iot_qt
mkdir build && cd build
cmake ..
cmake --build .
./iot_city_qt
```

Host/puerto configurables desde **File > Configure Host** (Ctrl+H).

---

## Repositorio

```bash
git clone https://github.com/siliconvalleyar-oss/iot_city_full.git
cd iot_city_full
```
