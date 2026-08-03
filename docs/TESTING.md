# Testing — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

> Estado actual: **no hay tests automatizados** (prioridad alta en `TODO.md`). Este documento define la estrategia y el plan.

---

## 1. Objetivo

Alcanzar cobertura funcional de las piezas críticas y evitar regresiones en los bugs ya identificados:

1. Ingesta MQTT (bug `main.py:172-173`).
2. Contrato de serialización de 3 bytes con firmware (`SERIALIZATION.md`).
3. Modelo de consumo `NodeEnergyModel` (unidades, fracciones, conservación de energía).
4. Algoritmos de optimización (límites, saturaciones, histogramas).
5. API REST y WebSocket del backend.
6. Scripts de sistema (validación de entrada, batch CSV).

---

## 2. Stack recomendado

- **pytest** (tests de Python) + `pytest-asyncio` (endpoints async).
- **httpx / TestClient** de FastAPI para API e integración.
- Playwright para e2e del frontend (dashboard y mapa) — opcional en CI.
- Sin dependencias pesadas: el código es Python puro (stdlib), los tests también.

```bash
pip install pytest pytest-asyncio httpx
```

---

## 3. Pirámide de tests

### 3.1 Unitarios (rápidos, sin red)

| Módulo | Qué probar |
|---|---|
| `analytics/metrics_engine.py` | `compute_instant_power_mW` con configs límite (duty 0.02/1.0, interval 0.5/60, agg 1/8); que `frac_tx + frac_rx + frac_sleep` ≈ 1; estados `powered=False` (0 W) e `active=False` (deep sleep). **Bug conocido:** fracciones >1 cuando `t_tx + t_rx > t_cycle` — test que falle para forzar fix |
| `energy/optimizer.py` | `AdaptiveDutyCycler` (saturación en 0.02/0.50); `DynamicTXPowerController` (thresholds de RSSI); `PacketAggregator` (`overhead_reduction_pct` con agg=1 → **debería ser 0**, hoy reporta 100); `AdaptiveIntervalController` (clamp 0.5–60) |
| Serialización | Round-trip `from_firmware_bytes(to_firmware_bytes(cfg))` con tolerancia; **test del layout de bits B2[3:2]** que falla hoy (bug `SERIALIZATION.md`) |
| `backend/city_generator.py` | Cada patrón genera N routers + M end devices con semilla reproducible; mesh conecta cada nodo a ≤2 routers |

### 3.2 Integración (FastAPI TestClient)

- CRUD `/api/devices` (create/409 duplicado/delete limpia referencias).
- `toggle` / `power` (power off fuerza active=False).
- `simulate/blackout` y `restore`.
- `/api/dashboard/*`: `summary`, `zones`, `node/{id}`, `optimization/recommendations`.
- WebSocket `/ws`: recibe `init`, procesa `toggle`/`move` (usar `TestClient.websocket_connect`).
- **Test de MQTT:** simular `on_message` con topic `iot/city/device/RTR_001/telemetry` y verificar que `DEVICES["RTR_001"]` se actualiza — **falla hoy** (bug de índice).

### 3.3 E2E (opcional)

- Cargar `frontend/index.html` con Playwright: verificar 23 nodos renderizados, drag de un nodo dispara WS `move`, botón blackout enciende estados grises.
- Dashboard: KPIs se actualizan vía WS.

---

## 4. Fixtures y datos

- Usar `data/devices.json` de demo (generado por `city_generator`) o fixtures de 3-5 nodos mínimos para tests rápidos.
- Semilla fija para tests deterministas (el código actual usa `random` sin semilla — **ver `LEARNINGS.md`**).
- No tocar `data/` real en tests: usar `tmp_path` y redirigir `DATA_FILE`.

---

## 5. CI

```yaml
# .github/workflows/test.yml (roadmap)
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - run: pip install -r backend/requirements.txt pytest pytest-asyncio httpx
      - run: pytest -q
```

---

## 6. Métricas de éxito

- `pytest` verde en CI.
- Tests que **fallan hoy** (MQTT, serialización B2, fracciones de energía, `overhead_reduction_pct`) y pasan tras el fix: documentarlos en `CORRECTIONS.md`/`CHANGELOG.md`.
- Cobertura objetivo: ≥70% en `analytics/` y `energy/`, ≥50% en `backend/`.
