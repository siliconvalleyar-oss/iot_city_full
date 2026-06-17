# 🔌 IoT City Flutter — API Reference

> **Base URL:** `http://<host>:5062/api`  
> **WebSocket:** `ws://<host>:5062/api/dashboard/ws`  
> **Formato:** JSON

---

## 📡 Dashboard Endpoints

### GET /dashboard/summary

Resumen global del sistema energético.

**Response:**
```json
{
  "timestamp": 1781592000,
  "uptime_s": 36000,
  "total_nodes": 20,
  "total_power_mW": 1250.5,
  "total_power_W": 1.2505,
  "total_energy_mWh": 450.25,
  "estimated_daily_Wh": 30.01,
  "avg_efficiency_score": 72.5,
  "top_consumers": [["RTR_001", 85.3], ["RTR_005", 78.1]],
  "zones": ["zona-norte", "zona-centro", "zona-sur"]
}
```

### GET /dashboard/zones

Métricas agregadas por zona geográfica.

**Response:**
```json
{
  "zones": {
    "zona-norte": {
      "zone": "zona-norte",
      "node_count": 7,
      "total_power_mW": 420.5,
      "avg_power_per_node_mW": 60.07,
      "total_energy_mWh": 150.2,
      "active_nodes": 6,
      "total_packets_tx": 12500,
      "avg_efficiency_score": 74.2
    }
  }
}
```

### GET /dashboard/timeseries/global

Serie temporal de potencia total de la red.

**Query params:** `last_n` (default: 300)

**Response:**
```json
{
  "timeseries": [
    {
      "ts": 1781592000,
      "dt": "2026-06-16T10:00:00",
      "total_power_mW": 1250.5,
      "total_power_W": 1.2505,
      "active_nodes": 18,
      "total_nodes": 20
    }
  ]
}
```

### GET /dashboard/timeseries/{node_id}

Serie temporal de un nodo específico.

**Query params:** `last_n` (default: 300)

**Response:**
```json
{
  "node_id": "RTR_001",
  "timeseries": [
    {
      "ts": 1781592000,
      "dt": "2026-06-16T10:00:00",
      "power_mW": 75.3,
      "current_mA": 22.8,
      "packets_tx": 3,
      "sleep_frac": 0.85
    }
  ]
}
```

### GET /dashboard/node/{node_id}

Detalle completo de un nodo.

**Response:**
```json
{
  "node_id": "RTR_001",
  "zone": "zona-norte",
  "config": {
    "tx_power_level": 1,
    "duty_cycle": 0.15,
    "tx_interval_s": 2.0,
    "aggregation_size": 3
  },
  "instant": {
    "power_mW": 45.2,
    "current_mA": 13.7,
    "radio_mA": 11.2,
    "mcu_mA": 2.5,
    "frac_tx": 0.02,
    "frac_rx": 0.03,
    "frac_sleep": 0.95
  },
  "stats_5min": {
    "avg_power_mW": 44.8,
    "peak_power_mW": 78.2,
    "total_energy_mWh": 3.73,
    "efficiency_score": 85.3
  }
}
```

### GET /dashboard/traffic

Tráfico de datos por nodo.

**Response:**
```json
{
  "traffic": {
    "RTR_001": {
      "node_id": "RTR_001",
      "zone": "zona-norte",
      "tx_rate_pps": 2.5,
      "total_tx": 15000,
      "total_rx": 18500,
      "link_utilization": 25.0
    }
  }
}
```

### GET /dashboard/heatmap

Datos para mapa de calor de consumo.

**Response:**
```json
{
  "heatmap": [
    {
      "node_id": "RTR_001",
      "x": 150,
      "y": 120,
      "power_mW": 45.2,
      "intensity": 0.45,
      "efficiency": 85.3,
      "zone": "zona-norte"
    }
  ]
}
```

### GET /dashboard/optimization/recommendations

Recomendaciones de optimización priorizadas.

**Response:**
```json
{
  "recommendations": [
    {
      "node_id": "RTR_003",
      "zone": "Av. Mitre",
      "current_power_mW": 72.3,
      "issues": [
        {
          "type": "aggregation",
          "severity": "high",
          "msg": "Sin agregación de paquetes",
          "action": "aggregation_enable",
          "saving_est_pct": 20
        }
      ],
      "max_saving_pct": 20
    }
  ]
}
```

### POST /dashboard/optimization/apply/{node_id}/{strategy}

Aplica estrategia de optimización.

**Estrategias:** `duty_cycle_reduce`, `tx_power_reduce`, `interval_increase`, `aggregation_enable`, `full_optimize`, `reset_defaults`

**Response:**
```json
{
  "node_id": "RTR_003",
  "strategy": "aggregation_enable",
  "before_mW": 72.3,
  "after_mW": 57.8,
  "saving_mW": 14.5,
  "saving_pct": 20.1
}
```

### WS /dashboard/ws

WebSocket para actualizaciones en tiempo real.

**Mensaje inicial:**
```json
{
  "type": "init",
  "summary": { "...summary data..." },
  "zones": { "...zones data..." },
  "timeseries": ["...array of samples..."]
}
```

**Tick de actualización (cada ~2s):**
```json
{
  "type": "dashboard_tick",
  "global": { "...global snapshot..." },
  "zones": { "...zones data..." },
  "summary": { "...summary..." },
  "optimization": { "...opt result (optional)..." }
}
```

---

## 🔧 IoT City API (Backend)

### Dispositivos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/devices` | Listar todos los dispositivos |
| GET | `/devices/{id}` | Obtener dispositivo |
| POST | `/devices` | Crear dispositivo |
| PATCH | `/devices/{id}` | Actualizar dispositivo |
| DELETE | `/devices/{id}` | Eliminar dispositivo |
| POST | `/devices/{id}/toggle` | ON/OFF |
| POST | `/devices/{id}/power` | Cortar/restaurar tensión |

### Simulación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/simulate/blackout` | Simular corte total |
| POST | `/simulate/restore` | Restaurar red |
| POST | `/simulate/fail/{id}` | Simular fallo de nodo |

### Sistema

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/metrics` | Métricas globales |
| GET | `/mesh` | Topología de red |
| GET | `/logs` | Log de eventos |
| GET | `/admin/settings` | Configuraciones |
| PUT | `/admin/settings` | Actualizar config |

---

## 📐 Modelos de Datos

### DashboardSummary (Mock)

```dart
class DashboardSummary {
  final double totalRevenue;            // $28,450
  final double totalSales;              // $24,200
  final double salesTarget;             // $35,000
  final int successfulTransactions;     // 342
  final int totalTransactions;          // 400
  final double returningCustomerRate;   // 0.68
  final double salesProgress;           // 0.81
  final List<RevenuePoint> revenuePoints;
  final List<SalesData> salesData;
  final List<CircularMetric> circularMetrics;
  final List<ActivityMetrics> activities;
}
```

### RevenuePoint

```dart
class RevenuePoint {
  final String label;       // 'Mon', 'Tue', etc.
  final double value;       // Revenue amount
  final bool isHighlighted; // Highlight last entries
}
```

### CircularMetric

```dart
class CircularMetric {
  final String label;
  final double value;      // Current value
  final double maxValue;   // Maximum (usually 100)
  final String unit;       // '%'
  final ColorType colorType; // success, info, alert, etc.
}
```

---

## 🔒 Autenticación (Futuro)

Actualmente la API no requiere autenticación. Próximamente:
- JWT tokens para endpoints admin
- API keys para integraciones externas
- Rate limiting por IP
