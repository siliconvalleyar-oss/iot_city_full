# IoT City — Deploy

## Entorno Local

### Backend

```bash
cd iot_city_web
python3 -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt
./scripts/install_system.sh
./scripts/control_system.sh start
```

El backend queda en `http://localhost:5062`.

### Qt Desktop Client

```bash
cd iot_qt
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(nproc)
sudo make install   # Opcional
```

## Producción

### Build Release Estático

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC=ON
cmake --build .
```

### AppImage (Linux)

```bash
# Usando linuxdeployqt
~/linuxdeployqt/build/tools/linuxdeployqt/linuxdeployqt build/iot_qt -appimage
```

## Dependencias

- Qt 5.15+ o 6.x: `apt install qtbase5-dev qtwebsockets5-dev qtcharts5-dev`
- CMake 3.16+
- GCC 9+/Clang 10+

## Configuración

Host y puerto configurables desde la UI (**File > Configure Host**) o directo en `~/.config/IoT-City/iot-city-qt.conf`.
