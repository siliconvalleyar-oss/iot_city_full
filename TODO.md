# 📋 IoT City — Plan de Trabajo y Roadmap

> **Última actualización:** Junio 2026  
> **Próximo hito:** v1.1.0 — Dashboard Flutter y persistencia SQL

---

## ✅ Completado (v1.0.0)

- [x] Backend FastAPI con API REST completa
- [x] WebSocket en tiempo real para actualizaciones
- [x] Mapa interactivo Canvas 2D con drag & drop
- [x] Simulador de red mesh Zigbee (enrutamiento BFS)
- [x] Simulador de gateways MQTT (3 zonas)
- [x] Motor de métricas energéticas NodeEnergyModel
- [x] 5 algoritmos de optimización energética
- [x] Dashboard energético con Chart.js
- [x] Heatmap de consumo sobre vista ciudad
- [x] Scripts de instalación y control
- [x] Gestión de paletas de colores (5 temas)
- [x] Firmware snippets C/C++ para nodo MRF24J40
- [x] Soporte Docker Compose
- [x] Documentación: README, ARCHITECTURE, DEPLOY

---

## 🔜 Próximas Tareas (Corto Plazo)

### Prioridad Alta

- [ ] **Persistencia SQLite**: Migrar de JSON a SQLite para mejor integridad y consultas
- [ ] **Autenticación**: Sistema de login (JWT) para endpoints de admin
- [ ] **Swagger completo**: Documentación interactiva completa de todos los endpoints
- [ ] **Tests unitarios**: Tests para backend, simulador y dashboard
- [ ] **i18n**: Soporte multi-idioma (ES/EN/PT)

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

## 🚀 Roadmap (Mediano Plazo)

### v1.1.0 — Dashboard Flutter

- [ ] Aplicación Flutter (`iot_city_flt`) con:
  - Dashboard moderno con fondo oscuro/gradiente
  - Gráficos de líneas, barras y gauges circulares
  - Paneles de Revenue, Total Sales, Transacciones, Customer Rate
  - Filtros por día/semana/mes/semestre
  - Animaciones suaves
  - Paletas de colores (20 opciones)
- [ ] Compatibilidad con Android 16.0
- [ ] Integración con backend existente vía API

### v1.2.0 — Modo Producción

- [ ] **Base de datos PostgreSQL** (alternativa a SQLite)
- [ ] **Redis** para caché de métricas
- [ ] **Rate limiting** en API
- [ ] **SSL/TLS** para WebSocket y API
- [ ] **Monitoreo** con Prometheus + Grafana
- [ ] **CI/CD** pipeline (GitHub Actions)

### v1.3.0 — IoT Real

- [ ] **Soporte hardware real** MRF24J40 + ATmega
- [ ] **Firmware completo** para nodos reales
- [ ] **OTA updates** para firmware
- [ ] **Dashboard móvil** (Flutter)
- [ ] **MQTT nativo** con broker dedicado

### v2.0.0 — Smart City

- [ ] **Machine Learning** para predicción de consumo
- [ ] **Gemelos digitales** de la ciudad
- [ ] **GIS integración** (GeoJSON, mapas reales)
- [ ] **APIs abiertas** para desarrolladores
- [ ] **Dashboard público** con métricas agregadas

---

## 🐛 Issues Conocidos

### Backend
- [ ] `dashboard_patch.py` puede fallar si no se inicializa correctamente
- [ ] Los snapshots de métricas se acumulan sin límite en `data/metrics/`
- [ ] No hay límite de conexiones WebSocket simultáneas

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

## 📚 Deuda Técnica

- [ ] Refactorizar `backend/main.py` en módulos más pequeños
- [ ] Estandarizar naming de variables (mezcla ES/EN)
- [ ] Agregar type hints completos en todo el código
- [ ] Migrar a async todas las operaciones de archivo
- [ ] Crear constantes para magic strings y números
- [ ] Agregar logging estructurado (JSON)
- [ ] Estandarizar formato de respuestas API

---

## 📊 Métricas de Progreso

| Componente | Estado | Cobertura | Prioridad |
|------------|--------|-----------|-----------|
| Backend API | ✅ 100% | — | — |
| WebSocket | ✅ 100% | — | — |
| Mapa Interactivo | ✅ 100% | — | — |
| Simulador Mesh | ✅ 95% | — | Media |
| Gateway MQTT | ✅ 90% | — | Media |
| Metrics Engine | ✅ 85% | — | Alta |
| Energy Optimizer | ✅ 80% | — | Alta |
| Dashboard | ✅ 75% | — | Alta |
| Tests | ❌ 0% | 0% | Alta |
| Documentación | ✅ 70% | — | Media |
| Docker | ✅ 80% | — | Baja |
| Seguridad | ❌ 10% | — | Alta |
