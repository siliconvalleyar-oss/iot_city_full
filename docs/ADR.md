# ADR — Architecture Decision Records — IoT City Web

**Última actualización:** 2026-08-02

Registro de decisiones de arquitectura. Cada ADR captura el contexto, la decisión y las consecuencias.

---

## ADR-001 — Backend monolítico FastAPI en un solo archivo

**Estado:** Aceptada (con deuda)
**Fecha:** 2026-06

### Contexto
El sistema requiere API REST, WebSocket, MQTT y simulación de red integrados con estado en memoria.

### Decisión
Concentrar todo en `backend/main.py` (~708 líneas): app FastAPI + WebSocket + paho-mqtt + `simulate_network` en background.

### Consecuencias
- **Pros:** arranque simple, estado compartido directo (`DEVICES`).
- **Contras:** deuda técnica alta; difícil de testear y mantener. Refactor pendiente (ver `ROADMAP.md`).

---

## ADR-002 — Extensión del dashboard vía "patch" en startup

**Estado:** Aceptada (provisional)
**Fecha:** 2026-06

### Contexto
El dashboard energético (analytics + energy + dashboard) se desarrolló como extensión sobre el backend sin reescribir `main.py`.

### Decisión
`backend/dashboard_patch.py` se aplica en el startup (`on_event`) y monta el router `/api/dashboard` + lanza `metrics_loop`.

### Consecuencias
- **Pros:** integración no invasiva; degradación silenciosa si faltan módulos.
- **Contras:** acoplamiento en el startup (deprecado en FastAPI 0.111+), estado huérfano tras `admin_reset`.

---

## ADR-003 — Estado en memoria + persistencia JSON

**Estado:** Aceptada (migrar a SQLite en v1.1.0)
**Fecha:** 2026-06

### Contexto
Necesidad de persistencia simple y lectura/escritura manual de dispositivos.

### Decisión
`DEVICES` en memoria, persistido a `data/devices.json` en cada mutación (escrituras síncronas, sin locks).

### Consecuencias
- **Pros:** simple, depurable, portable.
- **Contras:** no atómico, múltiples escritores concurrentes pueden pisarse/corromper el archivo (ver `LEARNINGS.md`).

---

## ADR-004 — Dos motores de configuración paralelos (métricas vs optimizador)

**Estado:** ⚠️ Aceptada por accidente — requiere corrección
**Fecha:** 2026-06

### Contexto
`MetricsEngine` y `EnergyOptimizer` mantienen cada uno su configuración de nodos.

### Decisión
No se decidió explícitamente: cada módulo inicializa su propio estado con `random` independiente, y la API aplica optimización sobre uno mientras las recomendaciones leen del otro.

### Consecuencias
- Divergencia real entre lo recomendado y lo aplicado.
- **Acción:** unificar en una sola fuente de verdad (prioridad media, `ROADMAP.md`).

---

## ADR-005 — Contrato de serialización de 3 bytes con el firmware

**Estado:** ⚠️ Aceptada con bug de interoperabilidad
**Fecha:** 2026-06

### Contexto
Configuración del nodo transmitida en 3 bytes para eficiencia (802.15.4).

### Decisión
Layout documentado en `SERIALIZATION.md`: `sleep_mode` en bits [3:2] de B2 según firmware.

### Consecuencias
- El backend (`energy/optimizer.py:84,99`) usa bits [1:0] → **incompatible** con el firmware (`iot_city_node.h:214,223`).
- **Acción:** alinear ambos lados (prioridad alta).

---

## ADR-006 — "5 algoritmos" de optimización, 4 implementados en Python

**Estado:** Aceptada con gap
**Fecha:** 2026-06

### Contexto
La documentación promete 5 algoritmos de optimización energética.

### Decisión
Se implementaron 4 en Python (`energy/optimizer.py`); **Sleep Mode Scheduling** solo existe en firmware (`sleep_ms`).

### Consecuencias
- Gap entre docs y código. **Acción:** implementar el 5º en Python o corregir la documentación.

---

## ADR-007 — MQTT como canal de telemetría (actualmente no funcional)

**Estado:** ⚠️ Revisar — roto
**Fecha:** 2026-06

### Contexto
Los simuladores publican telemetría a `iot/city/#`; el backend debe consumirla.

### Decisión
Suscribirse a `iot/city/#` y actualizar `DEVICES` desde `on_message` en el thread de paho.

### Consecuencias
- Bug de índice (`did = parts[2]`) + `asyncio.get_event_loop()` en thread ajeno → canal muerto (`LEARNINGS.md` §2).
- La sincronización real hoy es el archivo compartido. **Acción:** arreglar (prioridad alta).
