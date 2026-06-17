# IoT City — Qt Desktop Client

Cliente de escritorio para el sistema IoT City, construido con C++17 y Qt (5.15+ / 6.x).

## Requisitos

- Qt 5.15+ o Qt 6.x con módulos: Core, Widgets, Network, WebSockets, Charts
- CMake 3.16+
- Compilador C++17 (GCC 9+, Clang 10+, MSVC 2019+)

## Compilar

```bash
mkdir build && cd build
cmake ..
cmake --build .
./iot_qt
```

## Rama `qt`

Esta rama contiene exclusivamente el proyecto de escritorio Qt.
El backend FastAPI y la app Flutter están en las ramas `web` y `flt` respectivamente.

## Conexión

Por defecto se conecta a `http://ms7851.local:5062/api`.  
Se puede configurar host/puerto desde el menú **File > Configure Host** (Ctrl+H) o en tiempo de ejecución.
