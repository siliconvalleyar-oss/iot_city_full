# 🏗️ IoT City — Arquitectura del Sistema

> **Versión:** 1.0.0  
> **Última actualización:** Junio 2026  
> **Stack:** Python 3.12+ / FastAPI / WebSocket / MQTT / Chart.js

---

## 📐 Visión General

IoT City es una plataforma de gestión de luminarias inteligentes y dispositivos urbanos con red mesh Zigbee simulada. El sistema integra un backend en tiempo real, simulación de red, análisis energético y un dashboard interactivo.

```
┌─────────────────────────────────────────────────────────┐
│                    IoT City Platform                     │
├─────────────────────────────────────────────────────────┤
│  Frontend (Mapa Interactivo + Dashboard Energético)      │
│  ┌──────────────────────┐  ┌──────────────────────────┐  │
│  │  Canvas 2D Map       │  │  Chart.js Dashboard      │  │
│  │  - Dispositivos      │  │  - KPIs & Métricas       │  │
│  │  - Red Mesh          │  │  - Heatmaps              │  │
│  │  - Drag & Drop       │  │  - Optimización          │  │
│  └──────────┬───────────┘  └───────────┬──────────────┘  │
│             │                          │                  │
│             └──────────┬───────────────┘                  │
│                        │ HTTP / WS                       │
├────────────────────────┼─────────────────────────────────┤
│  Backend (FastAPI :5062)                                 │
│  ┌──────────────────────────────────────────────────┐    │
│  │  REST API   │  WebSocket   │  MQTT Client        │    │
│  │  /api/*     │  /ws         │  iot/city/#         │    │
│  ├──────────────────────────────────────────────────┤    │
│  │  Gestión Dispositivos │ Métricas │ Logs │ Admin  │    │
│  ├──────────────────────────────────────────────────┤    │
│  │  Dashboard Patch (API Ext)                       │    │
│  │  - Series Temporales  - Zonas  - Heatmaps       │    │
│  │  - Optimización       - Tráfico - Config Nodos  │    │
│  └──────────────────┬───────────────────────────────┘    │
│                     │                                    │
├─────────────────────┼────────────────────────────────────┤
│  Capa de Simulación                                      │
│  ┌──────────────────┴──────────────┐  ┌──────────────┐   │
│  │  Simulador Red Mesh Zigbee     │  │  Gateway MQTT │   │
│  │  - Nodos Router / End Device   │  │  - 3 Gateways │   │
│  │  - Enrutamiento BFS            │  │  - Zonas      │   │
│  │  - Fallos / Restauraciones     │  │  - Telemetría │   │
│  └─────────────────────────────────┘  └──────────────┘   │
│                                                            │
│  Capa de Análisis y Optimización                           │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │  Metrics Engine      │  │  Energy Optimizer        │   │
│  │  - Consumo por nodo  │  │  - Duty Cycling Adapt.   │   │
│  │  - Series temporales │  │  - TX Power Control      │   │
│  │  - Eficiencia        │  │  - Agregación Paquetes   │   │
│  │  - Heatmap           │  │  - Intervalo Adaptativo  │   │
│  └──────────────────────┘  └──────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

---

## 🧩 Componentes Principales

### 1. Backend (`backend/`)

**Tecnología:** FastAPI + Uvicorn + WebSockets + Paho-MQTT

| Archivo | Propósito |
|---------|-----------|
| `main.py` | Servidor principal: API REST, WebSocket, simulación de red |
| `dashboard_patch.py` | Endpoints adicionales para el dashboard energético |
| `requirements.txt` | Dependencias Python |

**Endpoints API:**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Sirve frontend mapa interactivo |
| GET/POST | `/api/devices` | Listar / Crear dispositivos |
| GET/PATCH/DELETE | `/api/devices/{id}` | CRUD dispositivo |
| POST | `/api/devices/{id}/toggle` | ON/OFF dispositivo |
| POST | `/api/devices/{id}/power` | Cortar/restaurar tensión |
| GET | `/api/metrics` | Métricas globales de red |
| GET | `/api/mesh` | Topología de red mesh |
| GET | `/api/logs` | Log de eventos |
| POST | `/api/simulate/blackout` | Simular corte total |
| POST | `/api/simulate/restore` | Restaurar red |
| POST | `/api/simulate/fail/{id}` | Simular fallo de nodo |
| GET | `/api/admin/settings` | Configuraciones |
| GET/POST/DELETE | `/api/admin/palettes` | Gestión de paletas |
| POST | `/api/admin/reset` | Reiniciar a demo |
| GET | `/api/admin/export` | Exportar datos |
| POST | `/api/admin/broadcast` | Broadcast a WebSockets |
| GET/POST | `/api/icons` | Gestión de íconos |

**Endpoints Dashboard (`/api/dashboard`):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/summary` | Resumen global energético |
| GET | `/zones` | Métricas por zona |
| GET | `/heatmap` | Datos para heatmap |
| GET | `/timeseries/global` | Serie temporal global |
| GET | `/timeseries/{node_id}` | Serie temporal por nodo |
| GET | `/node/{node_id}` | Detalle completo nodo |
| GET | `/traffic` | Tráfico por nodo |
| GET | `/optimization/recommendations` | Recomendaciones |
| POST | `/optimization/apply/{id}/{strategy}` | Aplicar optimización |
| POST | `/optimization/apply_all` | Aplicar todas |
| GET | `/optimization/history` | Historial de optimización |
| GET/PATCH | `/node/{node_id}/config` | Configuración nodo |
| WS | `/ws` | WebSocket tiempo real |

---

### 2. Frontend (`frontend/`)

**Tecnología:** HTML5 Canvas 2D + JavaScript vanilla

- Mapa interactivo de ciudad con dispositivos
- Indicadores visuales de estado (verde=activo, rojo=apagado, amber=alerta, gris=sin tensión)
- Drag & drop de dispositivos
- Zoom y desplazamiento
- Panel lateral de detalles

### 3. Dashboard (`dashboard/`)

**Tecnología:** HTML5 + Chart.js 4.4.1 + WebSocket

Páginas:
- **Overview:** KPIs, serie temporal de potencia, consumo por zona, top consumidores
- **Zonas:** Métricas por zona geográfica (Norte, Centro, Sur)
- **Tráfico:** Tráfico TX por nodo, distribución, análisis de agregación
- **Heatmap:** Mapa de calor de consumo energético sobre vista ciudad
- **Optimización:** Recomendaciones, historial, estrategias implementadas
- **Nodos:** Tabla completa con filtros y modal de detalle

---

### 4. Simulador (`simulator/`)

**Tecnología:** Python 3.12+

| Archivo | Propósito |
|---------|-----------|
| `mesh_simulator.py` | Simula red Zigbee completa con enrutamiento BFS |

**Características:**
- Nodos router y end_device con comportamiento realista
- Enrutamiento de paquetes por BFS
- Fallos aleatorios (0.1% por ciclo)
- Fluctuaciones de consumo, señal y paquetes
- Publicación MQTT de telemetría

### 5. Gateway MQTT (`mqtt/`)

| Archivo | Propósito |
|---------|-----------|
| `gateway_simulator.py` | Simula 3 gateways Raspberry Pi (Norte, Centro, Sur) |

**Características:**
- Telemetría por dispositivo (RSSI, LQI, consumo)
- Métricas de gateway (CPU temp, memoria, uptime)
- Publicación periódica cada 2s

---

### 6. Analytics (`analytics/`)

**Tecnología:** Python puro, modelo matemático de consumo MRF24J40

| Archivo | Propósito |
|---------|-----------|
| `metrics_engine.py` | Motor de métricas energéticas y series temporales |

**Modelo de consumo NodeEnergyModel:**
- Basado en datasheet MRF24J40 (Microchip DS39776)
- Corriente TX: 23mA (0dBm) / 15mA (-10dBm) / 8.5mA (-20dBm)
- Corriente RX: 19.7mA
- Sleep: 0.002mA (deep sleep)
- MCU ATmega328P: 4.0mA activo / 0.005mA deep sleep

**Ventanas de análisis:** 60s / 300s / 3600s

### 7. Energy Optimizer (`energy/`)

**Tecnología:** Python puro, 5 algoritmos de optimización

| Archivo | Propósito |
|---------|-----------|
| `optimizer.py` | Algoritmos de optimización energética |

**Algoritmos:**
1. **Duty Cycling Adaptativo** (S-MAC inspired)
2. **TX Power Control Dinámico** (basado en RSSI/LQI)
3. **Agregación de Paquetes** (frame batching 802.15.4)
4. **Intervalo Adaptativo** (delta-compression)
5. **Sleep Mode Scheduling** (coordinado por red)

### 8. Firmware Snippets (`firmware_snippets/`)

| Archivo | Propósito |
|---------|-----------|
| `iot_city_node.h` | C/C++ header con implementación embebida |

Implementa los 5 algoritmos para correr en nodo MRF24J40 + ATmega328P/2560.
Configuración serializada en solo 3 bytes para transmisión eficiente.

---

## 🔄 Flujo de Datos

```
Sensor/Actuador                    Gateway                     Backend
┌──────────┐    802.15.4     ┌──────────────┐    MQTT     ┌──────────────┐
│ Nodo Zigbee ├──────────────►│ Raspberry Pi ├────────────►│ FastAPI      │
│ MRF24J40   │    Mesh       │ (Gateway)    │  iot/city/  │ :5062        │
│ ATmega328P │◄──────────────┤              │◄────────────┤              │
└──────────┘                 └──────┬───────┘             └──────┬───────┘
                                    │                           │
                                    │                    ┌──────▼───────┐
                                    │                    │ WebSocket    │
                                    │                    │ :5062/ws     │
                                    │                    └──────┬───────┘
                                    │                           │
                           ┌────────▼────────┐         ┌───────▼────────┐
                           │ Metrics Engine  │         │ Dashboard      │
                           │ + Optimizer     │         │ Chart.js       │
                           └─────────────────┘         └────────────────┘
```

---

## 🗄️ Almacenamiento

| Archivo | Formato | Propósito |
|---------|---------|-----------|
| `data/devices.json` | JSON | Base de datos de dispositivos |
| `data/settings.json` | JSON | Configuraciones del sistema |
| `data/metrics/snapshot_*.json` | JSON | Snapshots históricos de métricas |
| `data/timeseries/` | JSON | Series temporales (futuro) |
| `logs/backend.log` | Texto | Logs del backend |
| `logs/simulator.log` | Texto | Logs del simulador |

---

## 🧪 Skills / .opencode

El directorio `.opencode/skills/iot-city/` contiene skills personalizados para el agente Codebuff/OpenCode. Está preparado para recibir definiciones de skills que automaticen tareas comunes del proyecto.

---

## 🔐 Puertos

| Puerto | Servicio |
|--------|----------|
| 5062 | Backend FastAPI + Frontend |
| 1883 | MQTT (Mosquitto) |

---

## 📦 Dependencias Principales

**Python:**
- fastapi==0.111.0
- uvicorn[standard]==0.30.0
- paho-mqtt==1.6.1
- pydantic==2.7.0
- python-multipart==0.0.9
- websockets==12.0

**Frontend:**
- Chart.js 4.4.1 (CDN)

---

## 🔄 Integración Continua

Ver `scripts/` para:
- `install_system.sh` — Instalación completa
- `control_system.sh` — start/stop/restart/status/logs
- `add_device.sh` — CLI para gestión de dispositivos
- `clean_reinstall.sh` — Reinstalación limpia
- `install_analytics.sh` — Instalación de dependencias de analytics
