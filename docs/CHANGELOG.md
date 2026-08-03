# Changelog — IoT City Web

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/). Las versiones se publican con tags git `vX.Y.Z` (cada push con su tag).

---

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
