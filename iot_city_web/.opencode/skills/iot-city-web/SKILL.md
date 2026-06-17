# IoT City Web — Skill

## Comandos útiles

```bash
# Iniciar sistema completo
./scripts/control_system.sh start

# Ver estado
./scripts/control_system.sh status

# Detener
./scripts/control_system.sh stop

# Ver logs
cat logs/backend.log
```

## Estructura

- `backend/main.py` — FastAPI (puerto 5062)
- `dashboard/api.py` — Dashboard REST + WS endpoints
- `dashboard/index.html` — Dashboard SPA con Chart.js (6 pestañas)
- `frontend/index.html` — Mapa interactivo Canvas 2D
- `analytics/metrics_engine.py` — Motor de métricas energéticas
- `energy/optimizer.py` — 4 algoritmos de optimización
- `simulator/` — Simulador de red mesh Zigbee
- `scripts/control_system.sh` — Script de control
- `data/` — Datos persistentes (devices.json, métricas)

## Convenciones

- FastAPI con WebSocket en `/ws`
- Dashboard API en `/api/dashboard/*`
- Dispositivos: endpoint `/api/devices` devuelve `{"devices": [...]}`
- CSRF: CORS permite todos los orígenes (`*`)
- Paletas de colores vía `/api/admin/palettes`
- MQTT Mosquitto necesario para simulación de gateways
- Entorno virtual Python en `venv/`
