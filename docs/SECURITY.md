# Security — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

> ⚠️ **Estado: v1.0.x NO es seguro para producción.** Este documento lista los riesgos conocidos y las medidas de mitigación pendientes (roadmap v1.1.0/v1.2.0).

---

## 1. Riesgos activos (confirmados en código)

### 1.1 CORS abierto + credenciales
`backend/main.py:107-113`:
```python
app.add_middleware(CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, ...)
```
`allow_origins=["*"]` + `allow_credentials=True` es una combinación que los navegadores rechazan para requests con credenciales y **abre la API a cualquier origen**.

**Prioridad:** alta. **Fix:** restringir orígenes y no combinar con credenciales.

### 1.2 Endpoints de admin sin autenticación
`/api/admin/*` (`main.py:569-678`) es accesible sin credenciales. Especialmente peligroso:

- `POST /api/admin/broadcast` — inyecta **mensajes arbitrarios a todos los clientes WebSocket**.
- `PUT /api/admin/settings` — acepta `dict` arbitrario sin validación.
- `POST /api/admin/reset` / `regenerate` — regenera la ciudad.
- `DELETE /api/admin/palettes/{name}` — borra paletas.

**Prioridad:** alta. **Fix:** autenticación JWT (roadmap v1.1.0) y rate limiting.

### 1.3 Path traversal en subida de íconos
`backend/main.py:445-452`:
```python
dest = icons_dir / file.filename
```
Si `file.filename` contiene `..` o es una ruta absoluta, se puede escribir fuera de `assets/icons/`.

**Prioridad:** alta. **Fix:** usar `os.path.basename()` y validar extensión.

### 1.4 XSS por innerHTML sin escapar
`frontend/index.html` inyecta IDs y calles de usuario con `innerHTML` en:
- Tooltip (1635-1643), panel de detalle (1682-1739), chips (1675-1680), lista de dispositivos (1865-1879) y log (1969-1973).

Como los IDs los escribe el usuario (POST `/api/devices`), es un **vector de inyección real**.

**Prioridad:** alta. **Fix:** escapar siempre (`textContent` o función `escapeHtml`).

### 1.5 Mosquitto sin autenticación
`scripts/install_system.sh:177` configura `allow_anonymous true` en `/etc/mosquitto/conf.d/iot-city.conf`.

**Prioridad:** media. **Fix:** credenciales MQTT y TLS (roadmap v1.2.0).

---

## 2. Riesgos menores / deuda

| Riesgo | Ubicación |
|---|---|
| `JSON.parse` sin try/catch en WS (`onmessage`) | `frontend/index.html:2019` |
| Sin rate limiting en la API | global |
| Sin límite de conexiones WebSocket simultáneas | `backend/main.py` |
| `reload=True` en uvicorn (no recomendado en producción) | `backend/main.py:708` |
| MQTT `qos=0` sin retención ni backpressure | simuladores |

---

## 3. Posturas y principios

1. **Datos de usuario** deben tratarse como no confiables en TODO el stack (backend, frontend, firmware).
2. **Nunca** commitear secretos: `.env`, `*.pem`, `*.key` están en `.gitignore`.
3. La API de admin y de escritura **deberían** requerir autenticación antes de v1.1.0.
4. En despliegue real detrás de reverse proxy (Nginx), forzar HTTPS para `wss://` y terminar TLS en el proxy.

---

## 4. Checklist para v1.1.0 (autenticación)

- [ ] Implementar JWT (`fastapi` + `python-jose` + `passlib`).
- [ ] Proteger `/api/admin/*` y escrituras (`POST/PATCH/DELETE`).
- [ ] Restringir CORS a orígenes conocidos.
- [ ] Sanear path de `/api/icons/upload`.
- [ ] Escapar HTML en `frontend/index.html`.
- [ ] Rate limiting (roadmap v1.2.0 si no alcanza).
