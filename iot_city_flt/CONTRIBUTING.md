# 🤝 Contribuyendo a IoT City Flutter

Gracias por tu interés en contribuir al proyecto. Estas son las pautas para mantener un desarrollo ordenado y de calidad.

---

## 🛠️ Setup de Desarrollo

```bash
# 1. Fork y clonar
git clone https://github.com/tu-usuario/iot_city_flt.git
cd iot_city_flt

# 2. Obtener dependencias
flutter pub get

# 3. Verificar que todo funciona
flutter analyze
flutter test
flutter run
```

---

## 📐 Estándares de Código

### Dart / Flutter

- Seguir las convenciones de [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Usar `flutter analyze` antes de commitear
- Mantener 0 warnings y 0 errores
- Usar `const` siempre que sea posible
- Nombrar archivos en `snake_case.dart`
- Nombrar clases en `PascalCase`
- Nombrar métodos/variables en `camelCase`

### Estructura de Archivos

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Widget raíz
├── config/                      # Configuración global
├── models/                      # Modelos de datos
├── services/                    # Servicios (API, mock)
├── providers/                   # State management
├── screens/                     # Pantallas completas
└── widgets/                     # Widgets reutilizables
    ├── charts/                  # Widgets de gráficos
    ├── cards/                   # Widgets de tarjetas
    └── filters/                 # Widgets de filtros
```

### Commits

Usar [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: agregar nuevo gráfico de dona
fix: corregir animación de gauge circular
docs: actualizar README con capturas
refactor: extraer KPI row en widget separado
test: agregar tests para DashboardProvider
chore: actualizar dependencias
```

### Pull Requests

1. Crear branch con nombre descriptivo: `feat/dona-chart`, `fix/gauge-animation`
2. Mantener PRs pequeños y enfocados
3. Incluir screenshot si hay cambios visuales
4. Asegurar que `flutter analyze` y `flutter test` pasen
5. Solicitar review de al menos un contributor

---

## 🧪 Tests

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Escribir Tests

- Tests unitarios para providers y servicios
- Widget tests para componentes visuales
- Integration tests para flujos completos

---

## 🎨 Guía de Estilo Visual

### Paletas

- Usar colores del sistema de paletas (`lib/config/palettes.dart`)
- No hardcodear colores en widgets
- Preferir `palette.accent`, `palette.text2`, etc.

### Tipografía

- Usar `fontFamily: 'monospace'` para valores numéricos
- Usar tamaños: 9px (labels), 11px (body), 22px (KPIs)
- Letter spacing: 1-2px para uppercase labels

### Espaciado

- Padding cards: 16px
- Gap entre cards: 10-12px
- Padding contenido: 20px
- Border radius: 12px (cards), 8px (botones)

---

## 📄 Proceso de Release

1. Actualizar `version` en `pubspec.yaml`
2. Ejecutar `flutter analyze && flutter test`
3. Actualizar `CHANGELOG.md`
4. Commit: `chore: release v1.0.0`
5. Tag: `git tag v1.0.0`
6. Push: `git push --tags`

---

## 📬 Contacto

Para preguntas o sugerencias, abrir un issue en GitHub.
