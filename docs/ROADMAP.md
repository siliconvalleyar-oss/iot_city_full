# Roadmap — IoT City Web

**Última actualización:** 2026-08-02
**Fuente:** extraído de `TODO.md` (documento único de referencia para planificación).

---

## Próximas tareas (corto plazo)

### Prioridad alta
- [ ] **Fix puerto ocupado**: error `[Errno 98] Address already in use` al iniciar backend. Revisar cierre limpio de uvicorn y el PID del reloader.
- [ ] **Fix MQTT**: parseo de `did` (`backend/main.py:172-173`, debe ser `parts[3]`) y `asyncio.get_event_loop()` en thread de paho.
- [ ] **Fix contrato de 3 bytes**: alinear `sleep_mode` en bits [3:2] entre `energy/optimizer.py` y `firmware_snippets/iot_city_node.h` (ver `SERIALIZATION.md`).
- [ ] **Persistencia SQLite**: migrar de JSON para integridad y consultas.
- [ ] **Autenticación JWT**: proteger `/api/admin/*` y escrituras.
- [ ] **Tests unitarios**: ver `TESTING.md`.

### Prioridad media
- [ ] **Unificar estado de configuración**: `MetricsEngine.nodes` y `EnergyOptimizer.node_configs` deben ser una sola fuente de verdad.
- [ ] **Alertas configurables**: email/webhook.
- [ ] **Exportación de datos**: CSV/PDF de métricas y logs.
- [ ] **Limitar snapshots de métricas** en `data/metrics/` (hoy se acumulan hasta 100 conservados en memoria + disco).
- [ ] **Zoom automático** en el mapa.
- [ ] **Más paletas** / modo oscuro adicional.

### Prioridad baja
- [ ] CLI avanzado para scripts.
- [ ] Gráficos de área en dashboard.
- [ ] Documentar endpoints individualmente.

---

## v1.1.0 — Dashboard Flutter + Persistencia

- [ ] App Flutter con dashboard moderno conectado al backend (rama `flt`).
- [ ] SQLite para datos persistentes.
- [ ] Autenticación JWT.

## v1.2.0 — Modo Producción

- [ ] PostgreSQL (alternativa a SQLite).
- [ ] Redis para caché de métricas.
- [ ] Rate limiting en API.
- [ ] SSL/TLS para WebSocket y API.
- [ ] Monitoreo con Prometheus + Grafana.
- [ ] CI/CD (GitHub Actions).

## v1.3.0 — IoT Real

- [ ] Soporte hardware real MRF24J40 + ATmega.
- [ ] Firmware completo para nodos reales.
- [ ] OTA updates para firmware.
- [ ] MQTT nativo con broker dedicado.

## v2.0.0 — Smart City

- [ ] Machine Learning para predicción de consumo.
- [ ] Gemelos digitales de la ciudad.
- [ ] Integración GIS (GeoJSON, mapas reales).
- [ ] APIs abiertas para desarrolladores.
- [ ] Dashboard público con métricas agregadas.

---

## Deuda técnica transversal

- Refactorizar `backend/main.py` en módulos (708 líneas).
- Estandarizar naming ES/EN.
- Type hints completos.
- Async file I/O.
- Constantes para magic strings.
- Logging estructurado (JSON).
- Estandarizar formato de respuestas API.
