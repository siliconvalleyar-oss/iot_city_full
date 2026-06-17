# 🌆 IoT City — Plataforma de Red Inteligente Zigbee

Sistema completo de gestión de luminarias y dispositivos urbanos con red mesh Zigbee simulada, backend FastAPI, WebSocket en tiempo real e interfaz de mapa interactivo.

---

## 🚀 Inicio Rápido

```bash
# 1. Instalar todo
chmod +x scripts/install_system.sh
./scripts/install_system.sh

# 2. Iniciar el sistema
chmod +x scripts/control_system.sh scripts/add_device.sh
./scripts/control_system.sh start

# 3. Abrir en el navegador
http://localhost:5062
```

---

## 📁 Estructura

```
iot-city/
├── backend/
│   └── main.py              # FastAPI + WebSocket + MQTT
├── frontend/
│   └── index.html           # Mapa interactivo (Canvas 2D)
├── simulator/
│   └── mesh_simulator.py    # Simulador de red Zigbee
├── mqtt/
│   └── gateway_simulator.py # Gateways Raspberry Pi simulados
├── assets/
│   └── icons/               # Íconos SVG de dispositivos
├── scripts/
│   ├── install_system.sh    # Instalación completa
│   ├── control_system.sh    # Control start/stop/restart
│   └── add_device.sh        # Agregar dispositivos por CLI
├── data/
│   └── devices.json         # Base de datos de dispositivos
└── logs/
    ├── backend.log
    └── simulator.log
```

---

## 🎮 Uso de Scripts

### Control del sistema

```bash
./scripts/control_system.sh start    # Inicia todo
./scripts/control_system.sh stop     # Detiene todo
./scripts/control_system.sh restart  # Reinicia todo
./scripts/control_system.sh status   # Muestra estado
./scripts/control_system.sh logs     # Ve logs del backend
./scripts/control_system.sh logs simulator  # Logs del simulador
```

### Agregar dispositivos

```bash
# Sintaxis básica
./scripts/add_device.sh ID X Y TIPO CALLE

# Ejemplos
./scripts/add_device.sh LAMP_001 120 300 router "Av. Mitre"
./scripts/add_device.sh SENSOR_05 400 200 end_device "Calle Belgrano"
./scripts/add_device.sh TRF_001 550 350 router "Av. Corrientes" traffic "#FF6600"

# Listar todos
./scripts/add_device.sh --list

# Eliminar
./scripts/add_device.sh --delete LAMP_001

# Batch desde CSV
./scripts/add_device.sh --batch mis_dispositivos.csv
```

**Formato CSV para batch:**
```csv
ID,X,Y,TIPO,CALLE,ICON,COLOR
LAMP_010,150,100,router,Av. Mitre,lamp,#FFD700
SENSOR_01,300,200,end_device,Calle Sur,sensor,#00BFFF
```

---

## 🌐 API REST

Base URL: `http://localhost:5062/api`

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /devices | Listar todos los dispositivos |
| GET | /devices/{id} | Obtener dispositivo |
| POST | /devices | Crear dispositivo |
| PATCH | /devices/{id} | Actualizar dispositivo |
| DELETE | /devices/{id} | Eliminar dispositivo |
| POST | /devices/{id}/toggle | ON/OFF |
| POST | /devices/{id}/power | Cortar/restaurar tensión |
| GET | /metrics | Métricas globales |
| GET | /mesh | Topología de red |
| GET | /logs | Log de eventos |
| POST | /simulate/blackout | Simular corte total |
| POST | /simulate/restore | Restaurar red |
| POST | /simulate/fail/{id} | Simular fallo de nodo |
| POST | /icons/upload | Subir ícono personalizado |
| GET | /icons | Listar íconos disponibles |

**Documentación interactiva:** `http://localhost:5062/api/docs`

---

## 📡 WebSocket

Conectar a `ws://localhost:5062/ws`

**Mensajes recibidos del servidor:**
```json
{ "type": "init", "devices": {...}, "metrics": {...} }
{ "type": "network_update", "devices": {...}, "metrics": {...} }
{ "type": "device_update", "device": {...}, "log": {...} }
{ "type": "device_added", "device": {...} }
{ "type": "device_removed", "device_id": "..." }
{ "type": "blackout", "affected": [...] }
```

**Mensajes enviados al servidor:**
```json
{ "type": "ping" }
{ "type": "toggle", "device_id": "LAMP_001" }
{ "type": "move", "device_id": "LAMP_001", "x": 200, "y": 300 }
```

---

## 🗺️ Interfaz del Mapa

| Acción | Descripción |
|--------|-------------|
| Click en dispositivo | Ver detalles en panel derecho |
| Drag dispositivo | Mover en el mapa |
| Scroll | Zoom in/out |
| Drag vacío | Desplazar mapa |
| Botón + | Agregar nuevo dispositivo |
| ⚡ Corte | Simular blackout total |
| ✓ Restaurar | Restaurar toda la red |

**Indicadores visuales:**
- 🟢 Verde — Activo y con tensión
- 🔴 Rojo — Apagado (sin energía lógica)
- 🟡 Amber — Alerta (nivel < 50%)
- ⚫ Gris — Sin tensión eléctrica

---

## 🔧 Configuración

Editar `.env` en la raíz del proyecto:

```bash
PORT=5062
HOST=0.0.0.0
MQTT_HOST=localhost
MQTT_PORT=1883
DEBUG=false
```

---

## 🐳 Docker (opcional)

```bash
docker compose up
```

**docker-compose.yml:**
```yaml
version: '3.8'
services:
  mqtt:
    image: eclipse-mosquitto:2
    ports: ["1883:1883"]

  backend:
    build: ./backend
    ports: ["5062:5062"]
    depends_on: [mqtt]
    volumes:
      - ./data:/app/data
      - ./frontend:/app/frontend
      - ./assets:/app/assets
```

---

## 📋 Requisitos

- Ubuntu/Debian 20.04+
- Python 3.9+
- pip / venv
- Mosquitto (opcional para MQTT)
- 512MB RAM mínimo
- Puerto 5062 libre

---

## 🐛 Solución de Problemas

**Puerto 5062 ocupado:**
```bash
lsof -ti:5062 | xargs kill
```

**Backend no inicia:**
```bash
cat logs/backend.log
# Verificar: cd backend && python3 main.py
```

**MQTT no conecta:**
```bash
sudo systemctl status mosquitto
sudo systemctl restart mosquitto
# Prueba: mosquitto_sub -h localhost -t 'iot/#' -v
```

**Sin datos en el mapa:**
```bash
curl http://localhost:5062/api/devices
# El backend genera ciudad demo automáticamente al iniciar
```
