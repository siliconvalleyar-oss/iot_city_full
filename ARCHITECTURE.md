# 🏗️ IoT City Flutter — Arquitectura

> **Versión:** 1.0.0  
> **Stack:** Flutter 3.44+ / Provider / fl_chart

---

## 📐 Visión General

```
┌─────────────────────────────────────────────────────────┐
│                    IoT City Flutter App                   │
├─────────────────────────────────────────────────────────┤
│  UI Layer (Screens + Widgets)                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │  DashboardScreen                                  │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │    │
│  │  │ KPI Row  │ │ Charts   │ │ Gauges           │  │    │
│  │  │ (4 cards)│ │ Row      │ │ Row (3 circular) │  │    │
│  │  └──────────┘ └──────────┘ └──────────────────┘  │    │
│  │  ┌──────────────────┐ ┌──────────────────────┐   │    │
│  │  │ Activities       │ │ Billing Section      │   │    │
│  │  └──────────────────┘ └──────────────────────┘   │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  Widget Layer                                             │
│  ┌──────────────────────────────────────────────────┐    │
│  │  Charts      │  Cards        │  Filters          │    │
│  │  - LineChart │  - MetricCard │  - TimeFilter     │    │
│  │  - BarChart  │  - Activity   │                   │    │
│  │  - Gauge     │    Card       │                   │    │
│  └──────────────┴──────────────┴───────────────────┘    │
│                                                          │
│  State Layer (Provider)                                   │
│  ┌────────────────────┐ ┌─────────────────────────────┐  │
│  │ DashboardProvider  │ │ ThemeProvider               │  │
│  │ - Summary data     │ │ - Current palette           │  │
│  │ - Active filter    │ │ - Palette switching         │  │
│  │ - Selected activity│ │ - 20 palettes available     │  │
│  └────────────────────┘ └─────────────────────────────┘  │
│                                                          │
│  Service Layer                                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │  MockDataService (singleton)                     │    │
│  │  - generateSummary(filter) → DashboardSummary    │    │
│  │  - Future: ApiService + WebSocketService         │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  Model Layer                                              │
│  ┌──────────────────────────────────────────────────┐    │
│  │  RevenuePoint │ SalesData │ CircularMetric      │    │
│  │  ActivityMetrics │ DashboardSummary              │    │
│  │  ColorType │ IconType                            │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  Config Layer                                             │
│  ┌─────────────────┐ ┌────────────┐ ┌───────────────┐  │
│  │  palettes.dart  │ │ theme.dart │ │ constants.dart │  │
│  │  (20 palettes)  │ │ (ThemeData)│ │ (API, layout)  │  │
│  └─────────────────┘ └────────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🧩 Flujo de Datos

```
User Action                    Provider                      UI Update
───────┬─────────           ──────┬───────                ──────┬──────
       │                          │                             │
  Select Filter ──────────────► DashboardProvider               │
  (Day/Week/                     .setFilter()                   │
   Month/Semester)                .loadData()                   │
                                  │                             │
                            MockDataService                     │
                              .generateSummary()                │
                                  │                             │
                              ◄── returns ──                   │
                            DashboardSummary                    │
                                  │                             │
                             notifyListeners() ─────────────►   │
                                                          Dashboard
                                                          re-builds
                                                              │
  Tap Activity ─────────────► DashboardProvider                 │
                               .toggleActivity()               │
                                  │                             │
                             notifyListeners() ─────────────►   │
                                                          ActivityCard
                                                          updates
                                                              │
  Palette Picker ───────────► ThemeProvider                    │
                               .setPalette()                   │
                                  │                             │
                             notifyListeners() ─────────────►   │
                                                          Theme rebuilt
                                                          with new colors
```

---

## 🗺️ Navegación (Futuro)

```
Main (App)
│
├── DashboardScreen (default)
│   ├── KPI Cards Row
│   ├── Charts Row (Line + Bar)
│   ├── Gauges Row (3 circular)
│   ├── Activities Selection
│   └── Billing Summary
│
├── AnalyticsScreen (futuro)
│   ├── Historical Trends
│   └── Comparison Charts
│
├── SettingsScreen (futuro)
│   ├── Palette Selector
│   └── API Configuration
│
└── ActivitiesScreen (futuro)
    └── Detailed Activity Log
```

---

## 🎨 Sistema de Paletas

Cada paleta define 11 colores:

| Variable | Propósito |
|----------|-----------|
| `bg` | Fondo principal |
| `bg2` | Fondo secundario (gradiente) |
| `bg3` | Fondo terciario (hover, estados) |
| `panel` | Fondo de paneles/tarjetas |
| `border` | Bordes y separadores |
| `accent` | Color principal de acento |
| `accent2` | Acento secundario (botones, active) |
| `green` | Éxito, positivo |
| `amber` | Advertencia, medio |
| `red` | Error, alerta |
| `purple` | Información, alternativo |
| `text` | Texto principal |
| `text2` | Texto secundario (subtítulos) |
| `cardBg` | Fondo de tarjeta |
| `cardBorder` | Borde de tarjeta |

---

## 🔄 Ciclo de Actualización

1. **App init**: `DashboardProvider` carga datos mock con filtro `Week`
2. **Filter change**: Regenera datos para el período seleccionado con animación
3. **Activity toggle**: Actualiza estado local sin recargar datos
4. **Palette switch**: Cambia colores en toda la app vía `ThemeProvider`
5. **Transiciones**: Animaciones fade + slide en cards, duración 400ms en gráficos

---

## 📐 Patrones de Diseño

- **Provider** para manejo de estado (ChangeNotifier)
- **Singleton** para MockDataService
- **Composición de widgets** (widgets pequeños reutilizables)
- **Separación de responsabilidades**: config / models / services / providers / screens / widgets
- **Animaciones implícitas** (AnimatedContainer, AnimatedBuilder)
- **CustomPainter** para gráficos circulares gauge
