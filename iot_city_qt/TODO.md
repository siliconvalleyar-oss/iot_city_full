# IoT City Qt — TODO

> Roadmap para escalar el cliente de escritorio.

## Prioridad Alta

- [ ] **Toggle/Power arreglar 500 del backend** — El endpoint `POST /api/devices/{id}/toggle` devuelve Internal Server Error. Revisar el broadcast WebSocket en el backend.
- [ ] **Soporte multi-idioma** — Internacionalización con `QTranslator` + archivos `.ts` (es/en).
- [ ] **Persistencia de posición** — Guardar y restaurar posición de dispositivos arrastrados en el mapa.
- [ ] **Autenticación** — Login screen + token JWT para comunicación con el backend.

## Prioridad Media

- [ ] **Firmware OTA** — Panel para subir firmware a dispositivos via backend.
- [ ] **Reportes PDF** — Exportar dashboard a PDF con `QPrinter`.
- [ ] **Modo offline** — Cachear última respuesta del backend y operar sin conexión.
- [ ] **Notificaciones desktop** — Alertas vía `QSystemTrayIcon` cuando un nodo cae.
- [ ] **Historial de logs** — Filtros por tipo de evento, búsqueda, exportar CSV.
- [ ] **Tema oscuro/claro** — Selector de paleta sincronizado con el backend.
- [ ] **Zoom automático** — Fit mapa al tamaño de la ventana, mantener relación 800x600.

## Prioridad Baja

- [ ] **Tests unitarios** — Qt Test framework para models, network y widgets.
- [ ] **CI/CD** — GitHub Actions: build en Ubuntu, Windows, macOS.
- [ ] **AppImage / .deb** — Empaquetado para distribución Linux.
- [ ] **Instalador Windows** — NSIS o WiX para distribuir en Windows.
- [ ] **Soporte Qt6 Charts** — Probar y asegurar compatibilidad total con Qt 6.x.
- [ ] **Animaciones UI** — Transiciones suaves entre tabs, fade en device panel.
- [ ] **Shortcuts personalizables** — Diálogo de configuración de atajos de teclado.

## Bugs Conocidos

- [ ] Toggle/Power: backend retorna 500 (ver prioridad alta)
- [ ] Labels en mapa: emoji icons pueden no renderizar si falta fuente emoji en el sistema
- [ ] Dashboard zones/traffic: si el backend no tiene datos, el chart se muestra vacío sin feedback

## Ideas Futuras

- [ ] Editor visual de la ciudad (agregar/quitar calles, zonas)
- [ ] Simulación de condiciones climáticas y su efecto en la red
- [ ] Integración MQTT directa (sin backend) para baja latencia
- [ ] Dashboard con gráficos 3D (OpenGL/Qt3D)
- [ ] Soporte para múltiples backend (cambiar entre servidores)
- [ ] Plugin system para widgets personalizados
