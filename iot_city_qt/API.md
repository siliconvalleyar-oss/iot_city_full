# IoT City — API Reference

Backend FastAPI corriendo en `http://<host>:5062/api`

## Dispositivos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/devices` | Listar todos los dispositivos |
| GET | `/api/devices/{id}` | Detalle de un dispositivo |
| POST | `/api/devices` | Crear dispositivo |
| PATCH | `/api/devices/{id}` | Actualizar dispositivo |
| DELETE | `/api/devices/{id}` | Eliminar dispositivo |
| POST | `/api/devices/{id}/toggle` | Cambiar estado active/inactive |
| POST | `/api/devices/{id}/power` | Cambiar powered on/off |

## Métricas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/metrics` | Métricas globales (total, powered, active, consumo, health) |
| GET | `/api/mesh` | Topología de red mesh (links + nodos) |
| GET | `/api/logs` | Logs del sistema |

## Dashboard

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/dashboard/summary` | Resumen energético global |
| GET | `/api/dashboard/timeseries/global?last_n=N` | Serie temporal de potencia |
| GET | `/api/dashboard/zones` | Métricas por zona |
| GET | `/api/dashboard/traffic` | Tráfico de red por nodo |
| GET | `/api/dashboard/heatmap` | Heatmap de consumo |
| GET | `/api/dashboard/node/{id}` | Detalle de métricas de un nodo |

## Simulación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/simulate/blackout` | Apagar toda la red |
| POST | `/api/simulate/restore` | Restaurar toda la red |
| POST | `/api/simulate/fail/{id}` | Simular caída de un nodo |

## WebSocket

| Ruta | Descripción |
|------|-------------|
| `ws://<host>:5062/ws` | Eventos en tiempo real (device_update, device_added, device_removed, simulation, blackout, restore) |
| `ws://<host>:5062/api/dashboard/ws` | Ticks del dashboard cada 2s |

## Formato Dispositivo

```json
{
  "id": "RTR_001",
  "device_type": "router",
  "x": 86,
  "y": 29,
  "active": true,
  "powered": true,
  "level": 65.9,
  "consumption": 10.0,
  "signal": -57.8,
  "icon": "lamp",
  "color": "#FFD700",
  "connected_to": ["RTR_007", "RTR_004"],
  "packets_sent": 291,
  "packets_received": 324,
  "last_seen": 1781672378.4
}
```
