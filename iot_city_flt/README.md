# 🌆 IoT City Flutter — Modern Urban Dashboard

> **Versión:** 1.0.0  
> **Stack:** Flutter 3.44+ / Dart 3.12+ / fl_chart / Provider  
> **Plataforma:** Android 16.0+ / iOS / Web

---

## 📋 Descripción

Aplicación Flutter que presenta un dashboard moderno y profesional con métricas urbanas, gráficos interactivos y paleta de colores personalizable. Diseñada como interfaz para la plataforma IoT City.

### Características

- **4 KPIs principales**: Revenue, Sales, Transactions, Return Rate
- **Gráficos interactivos**: Líneas (Revenue), Barras (Total Sales)
- **Gauges circulares**: Transaction Rate, Customer Rate, Sales Target
- **Filtros temporales**: Day, Week, Month, Semester
- **Actividades seleccionables**: Yoga, Running, Cycling
- **Métricas detalladas**: Duración, calorías, velocidad, frecuencia cardíaca
- **20 paletas de colores**: Tema oscuro personalizable
- **Animaciones suaves**: Transiciones y micro-interacciones
- **Responsive**: Adaptable a diferentes tamaños de pantalla

---

## 🚀 Inicio Rápido

```bash
# 1. Clonar
git clone <repo-url> iot_city_flt
cd iot_city_flt

# 2. Obtener dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo
flutter run

# 4. Build para producción
flutter build apk --release   # Android
flutter build ios --release   # iOS
flutter build web             # Web
```

---

## 📱 Capturas de Pantalla

```
┌──────────────────────────────────────────────────────┐
│  ● IoT CITY  Dashboard                    [🎨] [⚙️]  │
│  [Day] [Week] [Month] [Semester]                      │
├──────────────────────────────────────────────────────┤
│  ┌────────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐│
│  │ Revenue    │ │ Sales    │ │ Transact │ │ Return ││
│  │ $28.5K     │ │ $24.2K   │ │ 85.5%    │ │ 68%    ││
│  └────────────┘ └──────────┘ └──────────┘ └────────┘│
├──────────────────────────────────────────────────────┤
│  ┌────────────────────┐ ┌────────────────────────┐   │
│  │ REVENUE (line)     │ │ TOTAL SALES (bar)      │   │
│  │ 📈 $28,450         │ │ 📊 $24,200             │   │
│  └────────────────────┘ └────────────────────────┘   │
├──────────────────────────────────────────────────────┤
│  PERFORMANCE METRICS                    [REAL-TIME]  │
│  ┌──────┐  ┌──────┐  ┌──────┐                        │
│  │ 85.5%│  │ 68%  │  │ 81%  │                        │
│  │Success│  │Return│  │Target│                        │
│  └──────┘  └──────┘  └──────┘                        │
├──────────────────────────────────────────────────────┤
│  ACTIVITIES              [🏋️]                        │
│  [🧘 Yoga] [🏃 Running] [🚴 Cycling]                  │
│  ┌──────────────────────────────────────────────────┐│
│  │ YOGA METRICS                                     ││
│  │ ⏱ 45 min  🔥 320 cal  💨 — BPM  ❤️ 98 bpm    ││
│  └──────────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────────┐│
│  │ 📄 ESTIMATED BILLING         ▲ +22.0%            ││
│  │ $32,717                       vs previous period ││
│  └──────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────┘
```

---

## 🗂️ Estructura del Proyecto

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp + providers
├── config/
│   ├── palettes.dart                  # 20 color paletas
│   ├── theme.dart                     # ThemeData configuration
│   └── constants.dart                 # App constants
├── models/
│   └── dashboard_metrics.dart         # Data models
├── services/
│   └── mock_data_service.dart         # Mock data generator
├── providers/
│   ├── dashboard_provider.dart        # Dashboard state
│   └── theme_provider.dart            # Theme/palette state
├── screens/
│   └── dashboard_screen.dart          # Main dashboard
└── widgets/
    ├── charts/
    │   ├── line_chart_widget.dart      # Revenue line chart
    │   ├── bar_chart_widget.dart       # Sales bar chart
    │   └── circular_gauge_widget.dart # Circular gauges
    ├── cards/
    │   ├── metric_card.dart           # KPI metric card
    │   └── activity_card.dart         # Activity selector
    └── filters/
        └── time_filter.dart           # Time period filter
```

---

## 🎨 Paletas de Colores

| # | Nombre | Descripción |
|---|--------|-------------|
| 1 | Sunset Orange | Cálido, energético |
| 2 | Teal Breeze | Moderno, profesional |
| 3 | Gray Steel | Minimalista, industrial |
| 4 | Brown Earth | Natural, orgánico |
| 5 | Ocean Blue | Clásico, fresco |
| 6 | Pink Blossom | Suave, vibrante |
| 7 | Purple Mist | Creativo, sofisticado |
| 8 | **Black Flame** (default) | Audaz, minimalista |
| 9 | Navy Mirage | Corporativo, elegante |
| 10 | Golden Leaf | Cálido, lujoso |
| 11 | Rust Autumn | Terroso, acogedor |
| 12 | Ice Sky | Frío, tecnológico |
| 13 | Rosewood | Oscuro, refinado |
| 14 | Emerald Forest | Natural, vibrante |
| 15 | Sand Dune | Cálido, neutro |
| 16 | Lavender Dream | Suave, etéreo |
| 17 | Copper Glow | Metálico, brillante |
| 18 | Skyline Gray | Urbano, moderno |
| 19 | Berry Punch | Intenso, divertido |
| 20 | Mint Fresh | Fresco, limpio |

---

## 🔌 Integración con Backend

La app está preparada para conectarse al backend IoT City vía API REST y WebSocket:

```dart
// Configurar en lib/config/constants.dart
const String baseUrl = 'http://<host>:5062/api';
const String wsUrl = 'ws://<host>:5062/api/dashboard/ws';

// Endpoints disponibles
GET  /dashboard/summary
GET  /dashboard/zones
GET  /dashboard/timeseries/global
WS   /dashboard/ws
```

---

## 📦 Dependencias

```yaml
flutter: 3.44+
dart: 3.12+
fl_chart: ^0.70.2     # Gráficos
provider: ^6.1.2      # Estado
google_fonts: ^6.2.1  # Tipografía
intl: ^0.20.2         # Formateo
http: ^1.3.0          # API calls
web_socket_channel: ^3.0.2  # Tiempo real
shimmer: ^3.0.0       # Loading
```

---

## 📄 Licencia

MIT
