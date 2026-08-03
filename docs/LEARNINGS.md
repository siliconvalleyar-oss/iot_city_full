# LEARNINGS — IoT City Web

**Versión:** 1.0.0
**Fecha:** 2026-08-02
**Propósito:** Lecciones aprendidas del análisis de código y documentación. Documento vivo para no repetir errores y orientar el trabajo futuro.

---

## 1. Arquitectura en una frase

Monolito FastAPI con estado en memoria, WebSocket para tiempo real, MQTT "decorativo" y una extensión de análisis energético "parcheada" (`dashboard_patch.py`) que convive con un motor de métricas y un optimizador en paralelo.

## 2. Hallazgos críticos (bugs reales)

### MQTT no funcional (doble bug)
- `backend/main.py:172-173`: `did = parts[2]` extrae `"device"` en vez del id real (`parts[3]`). Todo el path de ingesta MQTT es código muerto.
- `backend/main.py:178-181`: `asyncio.get_event_loop()` dentro del thread de paho lanza `RuntimeError` en Python 3.12. Debe guardarse la referencia al loop del main thread.
- Consecuencia: los simuladores publican a `iot/city/device/{id}/telemetry` pero el backend los ignora en silencio. La única sincronización real es el archivo compartido `data/devices.json`.

### Tres fuentes de verdad para el mismo dominio
`backend/simulate_network`, `simulator/mesh_simulator.py` y `mqtt/gateway_simulator.py` mutan/publican el mismo `devices.json` con reglas distintas. El simulador mesh además:
- Escribe con `get_state()` que **omite** `street`, `icon`, `color`, `end_devices`, `cameras` → destruye el esquema (`simulator/mesh_simulator.py:80-95`).
- Nunca relee el archivo → revierte cambios hechos desde el frontend.

### Configuración duplicada y divergente
`MetricsEngine.nodes[id]` y `EnergyOptimizer.node_configs[id]` mantienen la misma configuración por separado, inicializada con aleatorios distintos. Aplicar optimización en uno no se refleja en el otro (`analytics/metrics_engine.py:541-590` vs `energy/optimizer.py:526`).

### Contrato de firmware de 3 bytes roto
El `sleep_mode` se serializa en bits [1:0] en `energy/optimizer.py:84,99` pero el firmware lo espera en bits [3:2] (`firmware_snippets/iot_city_node.h:214,223`). Cualquier config con sleep != none se corrompe.

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

1. Arreglar el parseo MQTT (`parts[3]`) y el loop reference.
2. Hacer una sola fuente de verdad de configuración de nodos.
3. Sincronizar el bit layout del contrato de 3 bytes con el firmware.
4. Reescribir `docs/GLOSSARY.md` para IoT City o eliminarlo.
5. Añadir tests unitarios (ver `docs/TESTING.md` cuando exista).
