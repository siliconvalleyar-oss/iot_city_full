# IoT City Flutter — Skill

## Comandos útiles

```bash
# Compilar APK
flutter build apk --release

# Ejecutar en dispositivo
flutter run

# Análisis estático
flutter analyze

# Limpiar
flutter clean
```

## Estructura

- `lib/models/` — Modelos de datos (Revenue, Sales, Metrics, Activities)
- `lib/providers/` — DashboardProvider, ThemeProvider (ChangeNotifier)
- `lib/screens/` — DashboardScreen
- `lib/widgets/` — RevenueChart, SalesChart, CircularGauge, MetricCard, ActivityCard
- `lib/services/` — Mock data service
- `lib/theme/` — 20 paletas de colores
- `android/` — Configuración Android

## Convenciones

- Provider + ChangeNotifier para estado global
- fl_chart para gráficos
- CustomPainter para gauge circular
- 20 paletas de color predefinidas (Black Flame default)
- Conexión al backend en `192.168.1.41:5062` (pendiente implementar)
- Mock data por defecto hasta integrar API real
