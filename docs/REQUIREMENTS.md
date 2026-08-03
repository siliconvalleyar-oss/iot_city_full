# Requirements — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

Requisitos funcionales (RF) y no funcionales (RNF) del sistema. Fuente de trazabilidad para `TODO.md`/`ROADMAP.md`.

---

## 1. Requisitos funcionales

### RF-1 Gestión de dispositivos
- RF-1.1 El sistema debe permitir crear, listar, consultar, actualizar y eliminar dispositivos vía API REST (`/api/devices`).
- RF-1.2 Al crear un dispositivo, se debe calcular su conexión a los 2 routers más cercanos de la mesh.
- RF-1.3 Al eliminar un dispositivo, se deben limpiar sus referencias en `connected_to`/`end_devices` de otros nodos.
- RF-1.4 El `id` debe ser único; duplicados → `409`.

### RF-2 Control de estado
- RF-2.1 `toggle` conmuta el estado lógico ON/OFF (`active`).
- RF-2.2 `power` conmuta la tensión (`powered`); apagar tensión fuerza `active=False`.
- RF-2.3 Los cambios deben persistirse y difundirse por WebSocket.

### RF-3 Simulación
- RF-3.1 Blackout total, restauración y fallo de nodo individual vía `/api/simulate/*`.
- RF-3.2 El simulador mesh debe fluctuar consumo, señal y paquetes y publicar telemetría MQTT.

### RF-4 Visualización
- RF-4.1 Mapa interactivo Canvas 2D con drag & drop, zoom y pan.
- RF-4.2 Indicadores de color de estado (verde=activo, rojo=apagado, ámbar=nivel<50%, gris=sin tensión).
- RF-4.3 Dashboard energético con KPIs, series temporales, heatmap, tráfico, zonas y optimización.

### RF-5 Análisis energético
- RF-5.1 `NodeEnergyModel` debe calcular consumo instantáneo según corrientes del MRF24J40 (TX/RX/sleep) y MCU.
- RF-5.2 Ventanas de análisis de 60s / 300s / 3600s.
- RF-5.3 5 algoritmos de optimización (Duty Cycling, TX Power, Agregación, Intervalo, Sleep Scheduling).
- RF-5.4 Generar recomendaciones y aplicar estrategias por nodo.

### RF-6 Persistencia
- RF-6.1 Persistir dispositivos en `data/devices.json`.
- RF-6.2 Generar ciudad demo automáticamente si no hay datos.
- RF-6.3 Snapshots históricos de métricas.

---

## 2. Requisitos no funcionales

| ID | Categoría | Requisito |
|---|---|---|
| RNF-1 | Rendimiento | Broadcast WS de estado completo cada ~3 s; tick de dashboard cada ~2 s |
| RNF-2 | Concurrencia | Estado en memoria compartido (DEVICES) — **sin locks hoy** (riesgo) |
| RNF-3 | Seguridad | ⚠️ CORS abierto, admin sin auth, XSS, path traversal — ver `SECURITY.md` |
| RNF-4 | Portabilidad | Python 3.12+, FastAPI, puro stdlib en analytics/energy |
| RNF-5 | Disponibilidad | Backend en puerto 5062; Mosquitto opcional en 1883 |
| RNF-6 | Mantenibilidad | `main.py` monolítico (708 líneas) — refactor pendiente |
| RNF-7 | Testing | No hay tests hoy; objetivo ≥70% en analytics/energy (ver `TESTING.md`) |

---

## 3. Restricciones

- Hardware objetivo del nodo: MRF24J40 + ATmega328P/2560 @ 3.3 V.
- Firmware serializa configuración en 3 bytes (`SERIALIZATION.md`).
- MQTT vía paho-mqtt **1.6.1** (API v1; no actualizar a 2.x sin migrar callbacks).
- Chart.js 4.4.1 vía CDN (requiere red en runtime para el dashboard).

---

## 4. Fuera de alcance (v1.0.x)

- Autenticación (v1.1.0).
- Persistencia SQLite/PostgreSQL (v1.1.0/v1.2.0).
- Hardware real (v1.3.0).
- ML / GIS / APIs abiertas (v2.0.0).
