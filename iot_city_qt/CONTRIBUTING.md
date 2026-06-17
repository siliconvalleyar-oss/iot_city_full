# IoT City Qt — Contributing

## Convenciones

- **C++17** con estilo moderno (auto, lambdas, smart pointers donde aplica)
- **Qt 5.15+ / 6.x** con API estable (evitar deprecated)
- **Indentación**: 4 espacios, sin tabs
- **Nombres**: `camelCase` para métodos/vars, `PascalCase` para clases
- **Modelos**: Structs con `static fromJson()` y métodos de utilidad inline
- **Async**: Callbacks `JsonCb`/`ErrCb` para ApiClient, señales Qt para eventos

## Estructura

```
src/
├── main.cpp              # Entry point (splash + app)
├── mainwindow.*          # Main window, menus, signal wiring
├── models/               # Data structs
├── network/              # REST + WebSocket clients
├── widgets/              # UI components
└── utils/                # Settings, helpers
```

## Pull Requests

1. Usar ramas descriptivas (`fix/toggle-click`, `feat/dashboard-traffic`)
2. Compilar sin warnings
3. Verificar con `make -C build` que linkea correctamente
4. Documentar cambios en `TODO.md`

## Debug

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
make -C build -j$(nproc)
QT_LOGGING_RULES="qt.network*=true" ./build/iot_qt
```
