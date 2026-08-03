# Changelog — IoT City Web

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/). Las versiones se publican con tags git `vX.Y.Z` (cada push con su tag).

---

## [1.2.0] — 2026-08-03

### Añadido
- Skills de agente instaladas vía `skills` CLI en `.agents/skills/` (canonical) con symlinks en `.opencode/skills/` y `.claude/skills/`: `mattpocock/skills` (refactor, docs, git, TDD, debugging, code review), `anthropics/skills` (`doc-coauthoring`) y `obra/superpowers` (`using-git-worktrees`, `finishing-a-development-branch`). Lockfile `skills-lock.json` para reproducibilidad.

## [1.1.1] — 2026-08-03

### Corregido
- **MQTT ingesta** (`backend/main.py`): parseo del device id (`parts[3]` en vez de `parts[2]`) y captura del event loop en el main thread para los callbacks de paho. La telemetría de los simuladores ya se procesa.
- **Contrato de 3 bytes** (`energy/optimizer.py`): `sleep_mode` alineado a bits [3:2] de B2, compatible con `firmware_snippets/iot_city_node.h` (ver `SERIALIZATION.md`).
- **Pérdida de esquema en `devices.json`** (`simulator/mesh_simulator.py`): `get_state()` conserva `street`, `icon`, `color`, `end_devices`, `cameras` y demás campos originales; ya no degrada el archivo al persistir.
- **Configuración divergente metrics/optimizer**: nueva `EnergyOptimizer.sync_to_metrics()` y sincronización en `dashboard/api.py` (ciclo de optimización, `apply`, `apply_all`, PATCH config). Una sola fuente de verdad efectiva.

## [1.1.0] — 2026-08-03

### Añadido
- Documentación núcleo en `docs/`: `API.md`, `DATA_MODEL.md`, `SERIALIZATION.md`, `SECURITY.md`, `TESTING.md`, `CHANGELOG.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `DEVELOPMENT.md`, `CONTRIBUTING.md`, `ADR.md`.
- `docs/GLOSSARY.md` reescrito para IoT City (reemplaza el glosario de otro proyecto CAD/DXF).
- Rama `web_with_skill`.

## [1.0.1] — 2026-08-02

### Añadido
- `docs/LEARNINGS.md`: lecciones del análisis de código y hallazgos críticos (MQTT roto, doble fuente de verdad, contrato de 3 bytes, etc.).

## [1.0.0] — 2026-08-02

### Añadido
- Documentación movida a `docs/` (`ARCHITECTURE.md`, `DEPLOY.md`, `TODO.md`).
- Archivo `VERSION` con el número de versión del proyecto.
- `.gitignore` reconfigurado: `data/`, `logs/`, `*.pid`, `.env`, `node_modules/`, artefactos Python/IDE.

### Repositorio
- Rama `web` con tags `v1.0.0`, `v1.0.1` en `iot_city_full`.

---

## Línea base (v1.0.0 funcional — antes de tags)

Entregado como "IoT City Web" con:

- Backend FastAPI: API REST, WebSocket `/ws`, integración MQTT (no funcional en la práctica).
- Mapa interactivo Canvas 2D (drag & drop, zoom, pan).
- Simulador de red mesh Zigbee (BFS, fallos, fluctuaciones).
- Simulador de 3 gateways MQTT (Norte/Centro/Sur).
- Dashboard energético Chart.js (6 pestañas) + extensión `dashboard_patch.py`.
- Motor de métricas `NodeEnergyModel` (datasheet MRF24J40).
- 4 algoritmos de optimización (el 5º solo en firmware).
- Generador procedural de ciudades (8 patrones).
- Scripts de instalación/control/CLI y Docker Compose.

---

## Historial de la rama (commits previos a tags)

| Commit | Descripción |
|---|---|
| `4e73fa1` | update web branch: SKILL.md and TODO.md |
| `8ad99a4` | actualizar rama web |

---

## Próximo hito

Ver `ROADMAP.md` → v1.1.0 (Dashboard Flutter + Persistencia SQLite + Autenticación JWT).
