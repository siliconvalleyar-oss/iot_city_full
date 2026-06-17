# IoT City Flutter — Plan de Trabajo

> **Versión:** 1.0.0
> **Última actualización:** Junio 2026

---

## Completado (v1.0.0)

- [x] Proyecto Flutter creado con configuración base
- [x] Sistema de 20 paletas de colores (Black Flame default)
- [x] Modelos de datos (Revenue, Sales, Metrics, Activities)
- [x] Mock data service con generación de datos dinámicos
- [x] DashboardProvider con ChangeNotifier
- [x] ThemeProvider para cambio de paleta
- [x] Revenue line chart (fl_chart)
- [x] Sales bar chart (fl_chart)
- [x] Custom circular gauge widget (CustomPainter)
- [x] KPI metric cards con animaciones
- [x] Activity selector cards
- [x] Time filter (Day/Week/Month/Semester)
- [x] Dashboard screen completa con layout responsive
- [x] Animaciones de entrada (fade + slide)
- [x] Sección de billing estimado
- [x] Métricas detalladas por actividad
- [x] Documentación: README, ARCHITECTURE, API, DEPLOY, TODO, CONTRIBUTING
- [x] Análisis estático sin errores

---

## Próximas Tareas

### Prioridad Alta

- [ ] **Conexión WebSocket real** con backend IoT City (`192.168.1.41:5062`)
- [ ] **Conexión API REST** para datos reales de dispositivos y métricas
- [ ] **Autenticación JWT** para endpoints seguros
- [ ] **Pantalla de Settings** con configuración de API
- [ ] **Persistencia de paleta seleccionada** (SharedPreferences)
- [ ] **Tests unitarios** para providers y servicios

### Prioridad Media

- [ ] **Pantalla Analytics** con históricos y comparativas
- [ ] **Gráfico de dona** para distribución de revenue
- [ ] **Modo oscuro/claro** toggle
- [ ] **Soporte multi-idioma** (ES/EN)
- [ ] **Responsive design** mejorado para tablets
- [ ] **Exportación de reportes** (PDF/CSV)

### Prioridad Baja

- [ ] **Pantalla de login**
- [ ] **Notificaciones push**
- [ ] **Widgets de home screen** (Android)
- [ ] **Soporte offline** con caché local
- [ ] **Tema claro** adicional

---

## Roadmap

### v1.1.0 — Backend Integration
- [ ] WebSocket para datos en tiempo real
- [ ] API REST para métricas reales
- [ ] Modo offline con datos cacheados
- [ ] Pantalla de configuración de conexión

### v1.2.0 — Analytics
- [ ] Históricos con selección de rango
- [ ] Comparativa entre períodos
- [ ] Predicciones con datos históricos
- [ ] Exportación de reportes

### v1.3.0 — Producción
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Pruebas de rendimiento
- [ ] Pantalla de login/registro
- [ ] Publicación en stores

### v2.0.0 — Smart City
- [ ] Mapa interactivo de ciudad
- [ ] Gestión de dispositivos en tiempo real
- [ ] Alertas y notificaciones
- [ ] Dashboard público compartible

---

## Issues Conocidos

- [ ] El gauge circular no se redimensiona correctamente en pantallas muy pequeñas
- [ ] Las animaciones pueden saltar en dispositivos de gama baja
- [ ] No hay manejo de errores de red (mock data siempre disponible)
- [ ] La tabla de nodos no está implementada (pendiente v1.1)

---

## Deuda Técnica

- [ ] Extraer DashboardScreen en widgets más pequeños
- [ ] Agregar type hints completos en todos los métodos
- [ ] Migrar a Riverpod para mejor testabilidad
- [ ] Agregar logging estructurado
- [ ] Documentar todos los métodos públicos
