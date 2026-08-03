# LEARNINGS — IoT City Web

**Versión:** 1.0.0
**Fecha:** 2026-08-02
**Propósito:** Lecciones aprendidas del análisis de código y documentación. Documento vivo para no repetir errores y orientar el trabajo futuro.

---

## 1. Arquitectura en una frase

Monolito FastAPI con estado en memoria, WebSocket para tiempo real, MQTT "decorativo" y una extensión de análisis energético "parcheada" (`dashboard_patch.py`) que convive con un motor de métricas y un optimizador en paralelo.

## 2. Hallazgos críticos (bugs reales)

### MQTT no funcional (doble bug) — CORREGIDO en v1.1.1
- `backend/main.py`: `did = parts[2]` extraía `"device"` en vez del id real (`parts[3]`). Toda la ingesta MQTT era código muerto.
- `backend/main.py`: `asyncio.get_event_loop()` dentro del thread de paho lanzaba `RuntimeError` en Python 3.12.
- **Fix:** `parts[3]` + captura del loop en `setup_mqtt()` (main thread).
- Consecuencia histórica: los simuladores publicaban a `iot/city/device/{id}/telemetry` pero el backend los ignoraba en silencio.

### Tres fuentes de verdad para el mismo dominio
`backend/simulate_network`, `simulator/mesh_simulator.py` y `mqtt/gateway_simulator.py` mutan/publican el mismo `devices.json` con reglas distintas. El simulador mesh además:
- Solía escribir con `get_state()` omitiendo `street`, `icon`, `color`, `end_devices`, `cameras` → destruía el esquema. **CORREGIDO en v1.1.1** (conserva el dict original).
- Nunca relee el archivo → revierte cambios hechos desde el frontend. **Pendiente.**

### Configuración duplicada y divergente — CORREGIDO en v1.1.1
`MetricsEngine.nodes[id]` y `EnergyOptimizer.node_configs[id]` mantenían la misma configuración por separado, inicializada con aleatorios distintos. Aplicar optimización en uno no se reflejaba en el otro. **Fix:** `EnergyOptimizer.sync_to_metrics()` + sincronización en `dashboard/api.py` (ciclo, apply, apply_all, PATCH).

### Contrato de firmware de 3 bytes roto — CORREGIDO en v1.1.1
El `sleep_mode` se serializaba en bits [1:0] en `energy/optimizer.py` pero el firmware lo espera en bits [3:2] (`firmware_snippets/iot_city_node.h`). Cualquier config con sleep != none se corrompía. **Fix:** alineado a bits [3:2] con round-trip verificado.

### El "5º algoritmo" no existe
La documentación anuncia 5 algoritmos pero `energy/optimizer.py` solo implementa 4. **Sleep Mode Scheduling** solo existe en firmware.

## 3. Modelo energético vs datasheet MRF24J40 (DS39776C)

| Constante | Código | Datasheet | Veredicto |
|---|---|---|---|
| TX 0 dBm | 23.0 mA | 23 mA | ✅ exacto |
| RX | 19.7 mA | 19 mA | ⚠️ +3.7% |
| Sleep | 0.002 mA | 2 µA | ✅ exacto |
| "32 niveles TX (RFCON3)" | — | solo 4 niveles (2 bits TXPWR) | ❌ incorrecto |
| Sensibilidad | −101 dBm | −95 dBm | ⚠️ optimista |

## 4. Seguridad (documentada en TODO pero pendiente)

- CORS `*` + `allow_credentials=True` (`backend/main.py:107-113`).
- Endpoints `/api/admin/*` sin autenticación; `/api/admin/broadcast` inyecta mensajes arbitrarios a todos los WS.
- Path traversal en `/api/icons/upload` (`backend/main.py:445-452`).
- XSS por `innerHTML` sin escapar en `frontend/index.html` (IDs y calles de usuario).

## 5. Bugs en scripts (deploy/CI)

- `scripts/clean_reinstall.sh:15-16`: `PROJECT_ROOT` apunta a `scripts/` en vez de la raíz.
- `scripts/fix_iot_paho_error.sh:114-115`: reinicio con ruta relativa desde `backend/` → error 127.
- `scripts/merge_extension.sh:203`: `export PROJECT_DIR` después de usarse.
- `scripts/add_device.sh:234-237`: el batch cuenta rechazos HTTP (400/409/422) como OK.
- `mosquitto -v` (install_system.sh:115) no es la bandera de versión real.
- `fix_iot_paho_error.sh` y `clean_reinstall.sh` instalan paho-mqtt sin pin → puede caer a 2.x con API distinta.

## 6. Reglas operativas aprendidas

1. **No versionar runtime**: `data/`, `logs/`, `*.pid`, `.env`, `__pycache__` NO van a git (ver `.gitignore`).
2. **Un solo canal de sincronización**: elegir MQTT o archivo compartido, no ambos sin locks.
3. **Cada pusheo lleva su tag** (convención `v1.0.N`): mantener `VERSION` sincronizado.
4. **La documentación del README está desactualizada**: omite `dashboard/`, `analytics/`, `energy/`.
5. **No mezclar proyectos**: `docs/GLOSSARY.md` que llegó aquí pertenece a un CAD/DXF Viewer (otra rama/repo) y debe reescribirse o retirarse.
6. **Snapshots de métricas se acumulan sin límite** en `data/metrics/` (TODO.md); ahora ignorados por git.

## 7. Recomendaciones prioritarias (para evitar regresiones)

1. ✅ Arreglado el parseo MQTT (`parts[3]`) y la referencia al event loop (v1.1.1).
2. ✅ Unificada la fuente de verdad de configuración de nodos (`sync_to_metrics`, v1.1.1).
3. ✅ Sincronizado el bit layout del contrato de 3 bytes con el firmware (v1.1.1).
4. Reescribir `docs/GLOSSARY.md` para IoT City o eliminarlo. → ✅ Hecho en v1.1.0.
5. Añadir tests unitarios (ver `docs/TESTING.md` cuando exista). **Pendiente.**
6. El simulador mesh no relee `devices.json` (revierte cambios del frontend). **Pendiente.**
