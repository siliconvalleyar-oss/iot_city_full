# Contributing — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

Guía para contribuir al proyecto. El repo `iot_city_full` tiene 3 proyectos en ramas separadas: `web` (este), `flt` (Flutter) y `qt` (Qt).

---

## 1. Ramas

| Rama | Proyecto |
|---|---|
| `web` | IoT City Web (FastAPI + Canvas + Chart.js) |
| `flt` | IoT City Flutter (app móvil) |
| `qt` | IoT City Qt (C++) |
| `main` | Estructura general (subdirectorios) |

**Regla:** no mezclar cambios entre ramas de proyectos distintos.

## 2. Flujo de contribución

```bash
# 1. Crear rama desde web
git checkout web
git checkout -b web/feature/mi-cambio

# 2. Trabajar, commitar con mensaje claro
git add <archivos>
git commit -m "fix: descripción concisa del cambio"

# 3. Taggear y pushear (cada push con su tag)
git tag -a v1.1.0 -m "IoT City web v1.1.0: <resumen>"
git push origin web/feature/mi-cambio --tags
```

## 3. Convenciones de commits

- Formato: `tipo: descripción` (tipo ∈ `fix`, `feat`, `docs`, `chore`, `refactor`, `test`).
- En español o inglés consistente dentro del mensaje.
- Un commit por cambio lógico.
- Actualizar `docs/CHANGELOG.md` con cada cambio relevante.

## 4. Estándares de código

- Python 3.12+, sin numpy/pandas en analytics/energy.
- Seguir convenciones de `DEVELOPMENT.md`.
- No versionar runtime (`data/`, `logs/`, `.env`).
- Validar sintaxis: `python3 -m compileall backend simulator mqtt analytics energy`.

## 5. Antes de enviar un cambio

- [ ] Verificar que no rompe arranque (`./scripts/control_system.sh start`).
- [ ] Correr `compileall` (o tests cuando existan, ver `TESTING.md`).
- [ ] Actualizar docs afectadas y `CHANGELOG.md`.
- [ ] Bump `VERSION` si corresponde.
- [ ] Documentar bugs conocidos en `LEARNINGS.md` si aplica.

## 6. Reportar issues

Incluir: paso a paso, salida esperada vs real, logs relevantes (`logs/backend.log`), rama y tag.

## 7. Áreas que necesitan ayuda

- Fix MQTT (`main.py:172-173`).
- Tests unitarios (ver `TESTING.md`).
- Refactor de `backend/main.py`.
- Autenticación JWT (v1.1.0).
- Reescribir `docs/GLOSSARY.md` para IoT City (actualmente contiene un glosario de otro proyecto).
