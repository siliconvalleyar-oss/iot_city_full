# Data Model — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

Documenta los modelos de datos persistidos y en memoria del sistema.

---

## 1. Dispositivo (`device`)

Representa un nodo de la red (router, end_device o cámara). Viven como **dicts** de Python en `DEVICES` (`backend/main.py`) y se persisten en `data/devices.json` (clave = `id`).

| Campo | Tipo | Descripción | Fuente |
|---|---|---|---|
| `id` | `string` | Identificador único (ej. `RTR_001`) | generador / POST |
| `x`, `y` | `float` | Posición en mapa (área 800×500) | generador / POST |
| `street` | `string` | Calle/avenida | generador / POST |
| `device_type` | `string` | `router` \| `end_device` \| `camera` | generador / POST |
| `active` | `bool` | ON/OFF lógico (luminaria) | runtime / toggle |
| `powered` | `bool` | Tensión eléctrica presente | runtime / power |
| `level` | `float` | Nivel de luz/batería (0–100) | generador / simulación |
| `consumption` | `float` | Consumo en W (simulado) | generador / simulación |
| `signal` | `float` | RSSI en dBm (−100..−30) | generador / simulación |
| `connected_to` | `array[string]` | IDs de routers vecinos en la mesh | `_compute_mesh` |
| `end_devices` | `array[string]` | End devices asociados (solo routers) | `_compute_mesh` |
| `cameras` | `array[string]` | Cámaras adyacentes (**solo** si `_add_cameras` las creó) | `city_generator._add_cameras` |
| `last_seen` | `float\|null` | Timestamp epoch de última telemetría | runtime |
| `packets_sent` | `int` | Paquetes TX acumulados | simulación |
| `packets_received` | `int` | Paquetes RX acumulados | simulación |
| `icon` | `string` | Ícono SVG (`lamp`, `traffic`, `sensor`, `camera`, `router`) | generador / POST |
| `color` | `string` | Color hex (ej. `#FFD700`) | generador / POST |

> ⚠️ **Inconsistencia conocida:** los devices creados por `POST /api/devices` siempre tienen `icon`/`color`; los de `city_generator` también los tienen desde v1.0.0, pero `mesh_simulator.get_state()` **omite** `street`, `icon`, `color`, `end_devices`, `cameras` al escribir — ver `SERIALIZATION.md` y `LEARNINGS.md`.

**Ejemplo:**
```json
{
  "id": "RTR_001",
  "x": 120.0, "y": 300.0,
  "street": "Av. Mitre",
  "device_type": "router",
  "active": true,
  "powered": true,
  "level": 92.4,
  "consumption": 118.2,
  "icon": "router",
  "color": "#FFD700",
  "connected_to": ["RTR_003", "RTR_005"],
  "end_devices": ["END_001"],
  "cameras": ["CAM_001"],
  "last_seen": 1785725092.95,
  "signal": -48.3,
  "packets_sent": 847,
  "packets_received": 512
}
```

---

## 2. Persistencia en disco

| Archivo | Formato | Contenido |
|---|---|---|
| `data/devices.json` | JSON | Mapa `{ "id": device }` de todos los dispositivos |
| `data/settings.json` | JSON | Configuraciones del sistema (`SETTINGS`) |
| `data/metrics/snapshot_<ts>.json` | JSON | Snapshots históricos de métricas (últimos 100 conservados) |
| `data/timeseries/` | JSON | Series temporales (reservado; actualmente vacío) |

### Escritores concurrentes (⚠️ riesgo)

`data/devices.json` es escrito por **varias fuentes sin locks ni escritura atómica**:

- `backend/main.py` — en cada mutación REST/WS y en `simulate_network` (~cada 3 s).
- `simulator/mesh_simulator.py` — cada ~10 s, **con un subconjunto de campos** (destruye esquema).
- Los directorios `data/`, `logs/` son generados automáticamente y **no se versionan** (ver `.gitignore`).

---

## 3. Telemetría MQTT

### `iot/city/device/{id}/telemetry`

Payload del `mesh_simulator` (`get_state()`):
```json
{ "id": "RTR_001", "device_type": "router", "x": 120.0, "y": 300.0,
  "active": true, "powered": true, "level": 92.4, "consumption": 118.2,
  "signal": -48.3, "connected_to": ["RTR_003", "RTR_005"],
  "packets_sent": 847, "packets_received": 512, "last_seen": 1785725092.95 }
```
Puede incluir `"event": "node_failure"` en ciclos de fallo.

Payload del `gateway_simulator` (añade campos):
```json
{ "...device...", "gateway": "GW_NORTE", "zone": "zona-norte",
  "ts": 1785725092.95, "signal_noise_ratio": 18.4, "lqi": 220 }
```
> ⚠️ Ambos simuladores publican en el **mismo topic** con **esquemas distintos**.

### `iot/city/gateway/{id}/metrics`

```json
{ "gateway_id": "GW_NORTE", "zone": "zona-norte", "cycle": 100, "ts": 1785725092.95,
  "devices_managed": 8, "devices_active": 8, "devices_powered": 8,
  "total_power_w": 642.0, "uptime_s": 200,
  "cpu_temp": 61.4, "free_memory_mb": 341.0, "rssi": -55.0 }
```

---

## 4. Modelo de consumo (`NodeEnergyModel`)

Estado por nodo (en `analytics/metrics_engine.py`):

| Campo | Tipo | Descripción |
|---|---|---|
| `tx_power_level` | `int` | 0=máx, 1=medio, 2=bajo |
| `duty_cycle` | `float` | 0–1, fracción de tiempo activo |
| `tx_interval_s` | `float` | Intervalo entre transmisiones |
| `packets_per_interval` | `int` | Paquetes por intervalo |
| `aggregation_ratio` | `float` | Factor de agregación |
| `power_history` / `tx_history` / `sleep_history` | `deque(maxlen=3600)` | Históricos circulares |
| `total_energy_mWh` | `float` | Energía acumulada |
| `uptime_s` | `float` | Tiempo de operación |

**Constantes de hardware** (datasheet MRF24J40 DS39776C + ATmega328P):

| Corriente | Valor |
|---|---|
| TX máx (0 dBm) | 23.0 mA |
| TX medio (−10 dBm) | 15.0 mA |
| TX bajo (−20 dBm) | 8.5 mA |
| RX | 19.7 mA |
| Idle radio | 2.4 mA |
| Sleep radio | 0.002 mA |
| MCU activo | 4.0 mA |
| MCU idle | 0.7 mA |
| MCU power save | 0.12 mA |
| MCU deep sleep | 0.005 mA |
| Tensión | 3.3 V |

---

## 5. Configuración de nodo (`NodeConfig`)

Vive en `energy/optimizer.py`. Es el estado que los 4 algoritmos optimizan.

| Campo | Rango/Default |
|---|---|
| `tx_power_level` | 0 / 1 / 2 |
| `duty_cycle` | 0.02–0.50 (default 0.20) |
| `tx_interval_s` | 0.5–60.0 (default 1.0) |
| `aggregation_size` | 1–8 (default 1) |
| `sleep_mode` | `none` / `idle` / `power_save` / `power_down` |
| `rx_window_ms` | 5.0 (sin uso real) |
| `beacon_order` | 6 (sin uso real) |
| `superframe_order` | 4 (sin uso real) |

Serialización a firmware: ver `SERIALIZATION.md`.
