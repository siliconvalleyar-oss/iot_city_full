# IoT City — Qt Desktop Client

Cliente de escritorio para el sistema IoT City, construido con C++17 y Qt (5.15+ / 6.x).

## Requisitos

- Qt 5.15+ o Qt 6.x con módulos: Core, Widgets, Network, WebSockets, Charts
- CMake 3.16+ (o qmake para el `.pro`)
- Compilador C++17 (GCC 9+, Clang 10+, MSVC 2019+)

## Compilar (CMake)

```bash
mkdir build && cd build
cmake ..
cmake --build . -j$(nproc)
./iot_qt
```

## Compilar (QMake)

```bash
mkdir build && cd build
qmake ../iot_qt.pro
make -j$(nproc)
./iot_qt
```

## Conexión

Por defecto se conecta a `http://192.168.1.41:5062/api`.  
Configurable desde **File > Configure Host** (Ctrl+H).

## Estructura

```
iot_qt/
├── assets/              # Recursos (icon.png)
├── src/
│   ├── main.cpp         # Entry point + splash screen
│   ├── mainwindow.*     # Ventana principal
│   ├── models/          # Device, DashboardMetrics
│   ├── network/         # ApiClient (REST), WebSocketClient
│   ├── widgets/         # MapWidget, DashboardWidget, DevicePanel, etc.
│   └── utils/           # Settings (QSettings)
├── CMakeLists.txt       # Build CMake
├── iot_qt.pro           # Build QMake
├── resources.qrc        # Recursos Qt
└── *.md                 # Documentación
```

## Documentación

| Archivo | Descripción |
|---------|-------------|
| `ARCHITECTURE.md` | Arquitectura del sistema y componentes |
| `API.md` | Endpoints del backend FastAPI |
| `DEPLOY.md` | Despliegue en producción |
| `TODO.md` | Roadmap y tareas pendientes |
| `CONTRIBUTING.md` | Guía para contribuir |
