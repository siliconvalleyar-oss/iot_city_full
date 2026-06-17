# IoT City Web — Plan de Trabajo y Roadmap

> **Última actualización:** Junio 2026
> **Próximo hito:** v1.1.0

---

## Completado (v1.0.0)

- [x] Backend FastAPI con API REST completa
- [x] WebSocket en tiempo real para actualizaciones
- [x] Mapa interactivo Canvas 2D con drag & drop
- [x] Simulador de red mesh Zigbee (enrutamiento BFS)
- [x] Simulador de gateways MQTT (3 zonas)
- [x] Motor de métricas energéticas NodeEnergyModel
- [x] 5 algoritmos de optimización energética
- [x] Dashboard energético con Chart.js (6 pestañas)
- [x] Heatmap de consumo sobre vista ciudad
- [x] Scripts de instalación y control
- [x] Gestión de paletas de colores (5 temas)
- [x] Firmware snippets C/C++ para nodo MRF24J40
- [x] Soporte Docker Compose
- [x] Documentación: README, ARCHITECTURE, DEPLOY

---

## Próximas Tareas (Corto Plazo)

### Prioridad Alta

- [ ] **Fix puerto ocupado**: Error `[Errno 98] Address already in use` al iniciar backend. Revisar cierre limpio de uvicorn.
- [ ] **Persistencia SQLite**: Migrar de JSON a SQLite para mejor integridad y consultas
- [ ] **Autenticación**: Sistema de login (JWT) para endpoints de admin
- [ ] **Swagger completo**: Documentación interactiva completa de todos los endpoints
- [ ] **Tests unitarios**: Tests para backend, simulador y dashboard

### Prioridad Media

- [ ] **Exportación de datos**: CSV/PDF de métricas y logs
- [ ] **Alertas configurables**: Notificaciones por email/webhook
- [ ] **Modo oscuro adicional**: Más paletas de colores configurables
- [ ] **Zoom automático**: Ajuste automático del mapa según dispositivos

### Prioridad Baja

- [ ] **CLI avanzado**: Comandos adicionales para scripts
- [ ] **Gráficos de área**: Más tipos de visualización en dashboard
- [ ] **Documentación de API**: Endpoints documentados individualmente

---

## Roadmap (Mediano Plazo)

### v1.1.0 — Dashboard Flutter + Persistencia

- [ ] App Flutter con dashboard moderno conectado al backend
- [ ] SQLite para datos persistentes
- [ ] Autenticación JWT

### v1.2.0 — Modo Producción

- [ ] PostgreSQL (alternativa a SQLite)
- [ ] Redis para caché de métricas
- [ ] Rate limiting en API
- [ ] SSL/TLS para WebSocket y API
- [ ] Monitoreo con Prometheus + Grafana
- [ ] CI/CD pipeline (GitHub Actions)

### v1.3.0 — IoT Real

- [ ] Soporte hardware real MRF24J40 + ATmega
- [ ] Firmware completo para nodos reales
- [ ] OTA updates para firmware
- [ ] MQTT nativo con broker dedicado

### v2.0.0 — Smart City

- [ ] Machine Learning para predicción de consumo
- [ ] Gemelos digitales de la ciudad
- [ ] GIS integración (GeoJSON, mapas reales)
- [ ] APIs abiertas para desarrolladores
- [ ] Dashboard público con métricas agregadas

---

## Issues Conocidos

### Backend
- [ ] `dashboard_patch.py` puede fallar si no se inicializa correctamente
- [ ] Los snapshots de métricas se acumulan sin límite en `data/metrics/`
- [ ] No hay límite de conexiones WebSocket simultáneas
- [ ] Puerto 5062 puede quedar ocupado tras cierre abrupto

### Dashboard
- [ ] El heatmap no se redimensiona correctamente en pantallas pequeñas
- [ ] La tabla de nodos no actualiza automáticamente los valores de potencia
- [ ] Los gráficos pueden parpadear al actualizar con muchos datos

### Simulador
- [ ] El simulador no detecta automáticamente cambios en `devices.json`
- [ ] Los fallos aleatorios no tienen límite máximo por ciclo

### Seguridad
- [ ] CORS permite todos los orígenes (`*`)
- [ ] No hay autenticación en endpoints de admin
- [ ] Las contraseñas/configuraciones están en texto plano

---

## Deuda Técnica

- [ ] Refactorizar `backend/main.py` en módulos más pequeños
- [ ] Estandarizar naming de variables (mezcla ES/EN)
- [ ] Agregar type hints completos en todo el código
- [ ] Migrar a async todas las operaciones de archivo
- [ ] Crear constantes para magic strings y números
- [ ] Agregar logging estructurado (JSON)
- [ ] Estandarizar formato de respuestas API
