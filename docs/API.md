# API — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02
**Base URL:** `http://localhost:5062`

Todas las respuestas son JSON. Los errores usan la convención estándar HTTP con detalle en `detail`.

---

## Índice

- [Autenticación](#autenticación)
- [WebSocket](#websocket)
- [Dispositivos](#dispositivos)
- [Simulación](#simulación)
- [Métricas y Red](#métricas-y-red)
- [Íconos](#íconos)
- [Admin](#admin)
- [Dashboard `/api/dashboard/*`](#dashboard)
- [MQTT](#mqtt)

---

## Autenticación

> **Estado actual (v1.0.x): NO hay autenticación.** CORS permite todos los orígenes (`*`).
> Los endpoints de admin son accesibles sin credenciales. Ver `SECURITY.md`.

---

## WebSocket

### `/ws` — Mapa interactivo

```
ws://localhost:5062/ws
```

**Recibidos (server → client):**

| Tipo | Contenido |
|---|---|
| `init` | `{ devices, metrics, logs }` estado completo inicial |
| `network_update` | `{ devices, metrics }` broadcast cada ~3 s |
| `device_update` | `{ device, log? }` un dispositivo modificado |
| `device_added` | `{ device, log }` |
| `device_removed` | `{ device_id, log }` |
| `blackout` | `{ affected }` |
| `restore` | `{ devices, log }` |
| `system_reset` | `{ devices, log }` |
| `settings_update` | `{ settings, palettes }` |
| `pong` | respuesta a `ping` |

**Enviados (client → server):**

| Tipo | Contenido |
|---|---|
| `ping` | → responde `pong` |
| `toggle` | `{ device_id }` conmuta ON/OFF |
| `move` | `{ device_id, x, y }` arrastre en el mapa |

### `/api/dashboard/ws` — Dashboard energético

```
ws://localhost:5062/api/dashboard/ws
```

| Tipo | Contenido |
|---|---|
| `init` | `{ summary, zones, timeseries }` |
| `dashboard_tick` | `{ global, zones, summary, optimization? }` cada ~2 s |
| `pong` | respuesta a `ping` |

---

## Dispositivos

### `GET /api/devices`

Lista todos los dispositivos.

```json
{ "count": 23, "devices": [ { "id": "RTR_001", ... } ] }
```

### `GET /api/devices/{id}`

Detalle de un dispositivo. `404` si no existe.

### `POST /api/devices`

Crea un dispositivo. Calcula conexión a los 2 routers más cercanos. Publica en MQTT `iot/city/device/{id}/status` y hace broadcast `device_added`.

**Body:**
```json
{
  "id": "LAMP_010",
  "x": 150,
  "y": 100,
  "street": "Av. Mitre",
  "device_type": "router",
  "icon": "lamp",
  "color": "#FFD700"
}
```

**Respuesta:** `201` con el device creado (incluye `connected_to`, `end_devices`, `last_seen`, `signal`, `packets_*`, `consumption`, `level`, `active`, `powered`). `409` si el `id` ya existe.

### `PATCH /api/devices/{id}`

Actualiza campos. Campos válidos: `powered`, `active`, `level`, `icon`, `color`, `street`. Publica en MQTT `iot/city/device/{id}/update`.

### `DELETE /api/devices/{id}`

Elimina y limpia referencias `connected_to`/`end_devices` en otros nodos.

### `POST /api/devices/{id}/toggle`

Conmuta `active` (ON/OFF lógico).

### `POST /api/devices/{id}/power`

Conmuta `powered` (tensión). Si se apaga, fuerza `active=False`.

---

## Simulación

| Método | Endpoint | Descripción |
|---|---|---|
| POST | `/api/simulate/blackout` | Apaga toda la red. ⚠️ El parámetro `area` se ignora en v1.0.x |
| POST | `/api/simulate/restore` | Restaura toda la red |
| POST | `/api/simulate/fail/{id}` | Simula fallo del nodo |

---

## Métricas y Red

### `GET /api/metrics`

Métricas globales: total, powered, active, consumo, salud.

### `GET /api/logs?limit=50`

Últimos `limit` eventos del log en memoria (máx. 500).

### `GET /api/mesh`

Topología mesh: `links` con `source`, `target`, `strength`, `active`.

---

## Íconos

| Método | Endpoint | Descripción |
|---|---|---|
| POST | `/api/icons/upload` | Sube SVG/PNG a `assets/icons/` (multipart, campo `file`) |
| GET | `/api/icons` | Lista íconos disponibles |

---

## Admin

> ⚠️ Sin autenticación (ver `SECURITY.md`).

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/admin/settings` | Devuelve `SETTINGS` |
| PUT | `/api/admin/settings` | Actualiza settings (sin validar) |
| GET | `/api/admin/palettes` | Paletas built-in + custom |
| POST | `/api/admin/palettes` | Guarda paleta custom |
| DELETE | `/api/admin/palettes/{name}` | Borra paleta custom |
| POST | `/api/admin/reset` | Regenera ciudad (`pattern`, `seed`) |
| GET | `/api/admin/patterns` | Patrones disponibles |
| POST | `/api/admin/regenerate` | Regenera con el mismo patrón/semilla |
| GET | `/api/admin/export` | Exporta devices + settings |
| POST | `/api/admin/broadcast` | Inyecta un mensaje arbitrario a todos los WS |

---

## Dashboard

Prefijo: `/api/dashboard`. Instalado vía `backend/dashboard_patch.py` en el startup.

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/summary` | Resumen global energético |
| GET | `/zones` | Métricas por zona (Norte/Centro/Sur cíclico) |
| GET | `/heatmap` | Datos para heatmap de consumo |
| GET | `/timeseries/global?last_n=300` | Serie temporal de potencia total |
| GET | `/timeseries/{node_id}` | Serie temporal de un nodo |
| GET | `/node/{node_id}` | Detalle completo del nodo |
| GET | `/traffic` | Tráfico por nodo |
| GET | `/optimization/recommendations` | Recomendaciones priorizadas |
| POST | `/optimization/apply/{node_id}/{strategy}` | Aplica estrategia sobre el modelo de métricas |
| POST | `/optimization/apply_all` | Aplica la mejor acción a todos los nodos |
| GET | `/optimization/history` | Historial de ciclos |
| GET | `/optimization/aggregation-analysis` | Análisis comparativo de agregación |
| GET | `/node/{node_id}/config` | Configuración del nodo + bytes de firmware |
| PATCH | `/node/{node_id}/config` | Actualiza `NodeConfig` manualmente |

**Estrategias de optimización válidas:**
`duty_cycle_reduce`, `tx_power_reduce`, `interval_increase`, `aggregation_enable`, `full_optimize`, `reset_defaults`.

---

## MQTT

Broker: `localhost:1883` (Mosquitto). Cliente: `iot-city-backend`.

| Tema | Publicador | Uso actual |
|---|---|---|
| `iot/city/device/{id}/status` | backend | Al crear device |
| `iot/city/device/{id}/update` | backend | Al actualizar device |
| `iot/city/device/{id}/telemetry` | simuladores | ⚠️ Publicado pero **no procesado** (bug: `main.py:172-173`) |
| `iot/city/gateway/metrics` | mesh_simulator | Nadie lo consume |
| `iot/city/gateway/{id}/metrics` | gateway_simulator | Nadie lo consume |
| `iot/city/events` | — | Definido, nunca publicado |
| `iot/city/alarms` | — | Definido, nunca publicado |

---

## Notas de compatibilidad

- La doc interactiva (Swagger) está en `/api/docs`.
- Puerto y host configurables vía `.env` (`PORT`, `HOST`, `MQTT_HOST`, `MQTT_PORT`).
- `backend/main.py` usa `uvicorn.run(..., reload=True)`; el proceso real lanzado por `scripts/control_system.sh` es el reloader padre.
