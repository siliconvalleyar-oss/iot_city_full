# Development — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

Guía de desarrollo local. Para despliegue en producción ver `DEPLOY.md`.

---

## 1. Requisitos

- Python 3.12+ (el repo usa sintaxis 3.10+).
- pip / venv.
- Mosquitto (opcional, para MQTT).

## 2. Setup

```bash
# 1. Entorno virtual
python3 -m venv venv
source venv/bin/activate

# 2. Dependencias
pip install --upgrade pip
pip install -r backend/requirements.txt

# 3. (Opcional) Mosquitto
sudo apt install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto && sudo systemctl start mosquitto

# 4. Iniciar backend
cd backend && python3 main.py
```

Backend en `http://localhost:5062`. Docs interactivas en `/api/docs`.

## 3. Componentes y cómo ejecutarlos

| Componente | Comando | Notas |
|---|---|---|
| Backend + frontend | `cd backend && python3 main.py` | Sirve mapa + API + WS |
| Dashboard | incluido en backend | `/dashboard` vía `dashboard_patch.py` |
| Simulador mesh | `python3 simulator/mesh_simulator.py` | Publica MQTT; escribe `devices.json` (⚠️ degrada esquema) |
| Gateway simulator | `python3 mqtt/gateway_simulator.py` | 3 gateways; publica telemetría MQTT |

O todo junto:
```bash
./scripts/control_system.sh start
./scripts/control_system.sh status
```

## 4. Estructura

```
backend/            FastAPI: main.py (REST+WS+MQTT), city_generator.py, dashboard_patch.py
dashboard/          api.py (router /api/dashboard) + index.html (Chart.js)
frontend/           index.html — mapa Canvas 2D
simulator/          mesh_simulator.py
mqtt/               gateway_simulator.py
analytics/          metrics_engine.py (NodeEnergyModel, MetricsEngine)
energy/             optimizer.py (4 algoritmos + EnergyOptimizer)
firmware_snippets/  iot_city_node.h (firmware nodo MRF24J40+ATmega)
scripts/            instalación, control, CLI
data/               runtime (no versionado)
```

## 5. Convenciones de código

- **Python 3.12**, type hints recomendados (deuda: agregarlos).
- **Naming:** mezcla ES/EN actual (deuda); preferir inglés en código nuevo.
- **No** usar numpy/pandas en `analytics/`/`energy/` (stdlib puro).
- **paho-mqtt 1.6.1** — API v1. No subir a 2.x sin migrar callbacks.
- Comentarios en español en docs; en código seguir el estilo existente.
- No commitear `data/`, `logs/`, `.env`, `__pycache__` (ver `.gitignore`).

## 6. Workflow git

- Ramas por feature/proyecto: `web`, `flt`, `qt`, `main`.
- Cada push debe llevar su tag (`vX.Y.Z`); `VERSION` sincronizado.
- Mantener `docs/CHANGELOG.md` al día.

## 7. Lint / tests

- No hay linter configurado aún. Correr `python3 -m compileall backend simulator mqtt analytics energy` para validar sintaxis.
- Tests: plan en `TESTING.md` (pendiente de implementar).

## 8. Trampas conocidas

- El backend se mantiene "vivo" por su **propia** simulación interna, independiente de los simuladores externos.
- `mesh_simulator` pisa los cambios del frontend (nunca relee `devices.json`).
- MQTT del backend no procesa telemetría (bug `main.py:172-173`). Ver `LEARNINGS.md`.
