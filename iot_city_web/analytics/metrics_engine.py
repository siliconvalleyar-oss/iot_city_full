#!/usr/bin/env python3
"""
IoT City — Motor de Métricas y Series Temporales
Recolecta, almacena y analiza métricas energéticas de la red MRF24J40

Arquitectura:
  Nodos 802.15.4 → Gateway (MQTT) → MetricsEngine → TimeSeries DB (JSON rotativo)
                                                    ↓
                                             API Dashboard
"""

import json
import math
import random
import statistics
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ─────────────────────────────────────────────────────────────────
# CONSTANTES FÍSICAS MRF24J40 / ATmega
# ─────────────────────────────────────────────────────────────────

# Corriente típica MRF24J40 (datasheet Microchip DS39776)
MRF24J40_CURRENT_mA = {
    "tx_max":    23.0,   # TX a +0 dBm
    "tx_mid":    15.0,   # TX a -10 dBm
    "tx_low":     8.5,   # TX a -20 dBm (modo ahorro)
    "rx":        19.7,   # RX normal
    "idle":       2.4,   # Idle con oscilador activo
    "sleep":      0.002, # Deep sleep
}

# MCU típico (ATmega328P a 8MHz, 3.3V)
MCU_CURRENT_mA = {
    "active":    4.0,
    "idle":      0.7,
    "power_save": 0.12,
    "deep_sleep": 0.005,
}

VOLTAGE_V = 3.3

# Ventanas de análisis (segundos)
WINDOW_SHORT   = 60      # 1 min
WINDOW_MEDIUM  = 300     # 5 min
WINDOW_LONG    = 3600    # 1 hora

BASE_DIR = Path(__file__).parent.parent
METRICS_DIR = BASE_DIR / "data" / "metrics"
TIMESERIES_DIR = BASE_DIR / "data" / "timeseries"
METRICS_DIR.mkdir(parents=True, exist_ok=True)
TIMESERIES_DIR.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────
# MODELO DE CONSUMO POR NODO
# ─────────────────────────────────────────────────────────────────

class NodeEnergyModel:
    """
    Calcula consumo energético de un nodo basado en su estado operativo.
    Modela el ciclo real de un nodo MRF24J40 + ATmega.

    Ciclo típico de un nodo router (cada 500ms):
      - 2ms   TX (envío beacon/datos)
      - 5ms   RX (escucha canal)
      - 493ms Sleep
    """

    def __init__(self, node_id: str, node_type: str = "router"):
        self.node_id = node_id
        self.node_type = node_type
        self.tx_power_level = 0      # 0=max, 1=mid, 2=low
        self.duty_cycle = 1.0        # 0.0-1.0 (fracción del tiempo activo)
        self.tx_interval_s = 1.0     # intervalo entre transmisiones
        self.packets_per_interval = 1
        self.aggregation_ratio = 1.0  # >1 = paquetes agregados

        # Histórico circular (últimas 3600 muestras = 1 hora a 1Hz)
        self.power_history: deque = deque(maxlen=3600)
        self.tx_history: deque = deque(maxlen=3600)
        self.sleep_history: deque = deque(maxlen=3600)

        # Acumuladores
        self.total_energy_mWh = 0.0
        self.total_packets_tx = 0
        self.total_packets_rx = 0
        self.total_sleep_time_s = 0.0
        self.uptime_s = 0
        self.last_update = time.time()

    def compute_instant_power_mW(self) -> Dict:
        """
        Calcula potencia instantánea (mW) según estado actual del ciclo.
        Retorna breakdown detallado para análisis.
        """
        # Determinar corriente radio
        tx_key = ["tx_max", "tx_mid", "tx_low"][self.tx_power_level]
        i_tx = MRF24J40_CURRENT_mA[tx_key]
        i_rx = MRF24J40_CURRENT_mA["rx"]
        i_sleep_radio = MRF24J40_CURRENT_mA["sleep"]

        # Corriente MCU según duty cycle
        i_mcu_active = MCU_CURRENT_mA["active"]
        i_mcu_sleep = MCU_CURRENT_mA["power_save"]

        # Tiempos por ciclo (ms) — modelo realista 802.15.4
        t_cycle_ms = self.tx_interval_s * 1000
        t_tx_ms = 2.0 * self.packets_per_interval / self.aggregation_ratio
        t_rx_ms = 5.0 * self.duty_cycle
        t_sleep_ms = max(0, t_cycle_ms - t_tx_ms - t_rx_ms)

        # Carga promedio por ciclo
        frac_tx    = t_tx_ms / t_cycle_ms
        frac_rx    = t_rx_ms / t_cycle_ms
        frac_sleep = t_sleep_ms / t_cycle_ms

        # Corriente promedio ponderada
        i_radio_avg = (i_tx * frac_tx + i_rx * frac_rx +
                       i_sleep_radio * frac_sleep)
        i_mcu_avg   = (i_mcu_active * (frac_tx + frac_rx) +
                       i_mcu_sleep * frac_sleep)

        i_total = i_radio_avg + i_mcu_avg
        power_mW = i_total * VOLTAGE_V

        return {
            "power_mW": round(power_mW, 3),
            "current_mA": round(i_total, 3),
            "radio_mA": round(i_radio_avg, 3),
            "mcu_mA": round(i_mcu_avg, 3),
            "frac_tx": round(frac_tx, 4),
            "frac_rx": round(frac_rx, 4),
            "frac_sleep": round(frac_sleep, 4),
            "tx_power_level": self.tx_power_level,
            "duty_cycle": self.duty_cycle,
            "tx_interval_s": self.tx_interval_s,
        }

    def tick(self, active: bool = True, powered: bool = True,
             packets_tx: int = None, packets_rx: int = None) -> Dict:
        """Avanza un ciclo de medición (llamar cada segundo)."""
        now = time.time()
        dt = now - self.last_update
        self.last_update = now
        self.uptime_s += dt

        if not powered:
            sample = {
                "ts": now,
                "power_mW": 0.0,
                "current_mA": 0.0,
                "state": "off",
                "packets_tx": 0,
                "packets_rx": 0,
            }
            self.power_history.append(sample)
            return sample

        breakdown = self.compute_instant_power_mW()
        power_mW = breakdown["power_mW"] if active else (
            MRF24J40_CURRENT_mA["sleep"] + MCU_CURRENT_mA["deep_sleep"]
        ) * VOLTAGE_V

        # Energía acumulada (mWh)
        self.total_energy_mWh += power_mW * (dt / 3600)

        # Paquetes simulados si no se proveen
        if packets_tx is None:
            packets_tx = random.randint(0, 3) if active else 0
        if packets_rx is None:
            packets_rx = random.randint(0, 5) if active else 0

        self.total_packets_tx += packets_tx
        self.total_packets_rx += packets_rx

        sleep_frac = breakdown["frac_sleep"]
        self.total_sleep_time_s += dt * sleep_frac

        sample = {
            "ts": now,
            "power_mW": round(power_mW, 3),
            "current_mA": breakdown["current_mA"],
            "radio_mA": breakdown["radio_mA"],
            "mcu_mA": breakdown["mcu_mA"],
            "frac_tx": breakdown["frac_tx"],
            "frac_rx": breakdown["frac_rx"],
            "frac_sleep": breakdown["frac_sleep"],
            "state": "active" if active else "idle",
            "packets_tx": packets_tx,
            "packets_rx": packets_rx,
            "tx_power_level": self.tx_power_level,
        }

        self.power_history.append(sample)
        self.tx_history.append({"ts": now, "count": packets_tx})
        self.sleep_history.append({"ts": now, "frac": sleep_frac})

        return sample

    def get_stats(self, window_s: int = WINDOW_MEDIUM) -> Dict:
        """Estadísticas en ventana de tiempo."""
        now = time.time()
        cutoff = now - window_s
        relevant = [s for s in self.power_history if s["ts"] >= cutoff]

        if not relevant:
            return {}

        powers = [s["power_mW"] for s in relevant]
        tx_counts = [s.get("packets_tx", 0) for s in relevant]
        sleep_fracs = [s.get("frac_sleep", 0) for s in relevant]

        avg_power = statistics.mean(powers) if powers else 0
        peak_power = max(powers) if powers else 0

        return {
            "node_id": self.node_id,
            "window_s": window_s,
            "samples": len(relevant),
            "avg_power_mW": round(avg_power, 2),
            "peak_power_mW": round(peak_power, 2),
            "min_power_mW": round(min(powers), 2) if powers else 0,
            "std_power_mW": round(statistics.stdev(powers), 2) if len(powers) > 1 else 0,
            "total_energy_mWh": round(self.total_energy_mWh, 4),
            "energy_window_mWh": round(avg_power * window_s / 3600, 4),
            "total_packets_tx": self.total_packets_tx,
            "total_packets_rx": self.total_packets_rx,
            "tx_rate_pps": round(sum(tx_counts) / max(window_s, 1), 3),
            "avg_sleep_frac": round(statistics.mean(sleep_fracs), 3) if sleep_fracs else 0,
            "uptime_s": round(self.uptime_s, 1),
            "efficiency_score": self._compute_efficiency(),
        }

    def _compute_efficiency(self) -> float:
        """Score 0-100 de eficiencia energética del nodo."""
        score = 100.0

        # Penalizar alta potencia de TX innecesaria
        if self.tx_power_level == 0:
            score -= 20

        # Premiar alto sleep ratio
        if self.power_history:
            recent = list(self.power_history)[-60:]
            avg_sleep = statistics.mean(s.get("frac_sleep", 0) for s in recent)
            score += avg_sleep * 30

        # Premiar agregación de paquetes
        if self.aggregation_ratio > 1:
            score += min(15, self.aggregation_ratio * 5)

        # Penalizar intervalos muy cortos
        if self.tx_interval_s < 0.5:
            score -= 15

        return round(max(0, min(100, score)), 1)

    def get_timeseries(self, last_n: int = 300) -> List[Dict]:
        """Retorna últimas N muestras para graficado."""
        samples = list(self.power_history)[-last_n:]
        return [
            {
                "ts": s["ts"],
                "dt": datetime.fromtimestamp(s["ts"]).isoformat(),
                "power_mW": s["power_mW"],
                "current_mA": s.get("current_mA", 0),
                "packets_tx": s.get("packets_tx", 0),
                "sleep_frac": s.get("frac_sleep", 0),
            }
            for s in samples
        ]


# ─────────────────────────────────────────────────────────────────
# MOTOR DE MÉTRICAS GLOBAL
# ─────────────────────────────────────────────────────────────────

class MetricsEngine:
    """
    Centraliza métricas de todos los nodos.
    Persiste series temporales y expone API para el dashboard.
    """

    def __init__(self):
        self.nodes: Dict[str, NodeEnergyModel] = {}
        self.zone_map: Dict[str, str] = {}       # node_id → zone
        self.network_events: deque = deque(maxlen=1000)
        self.global_history: deque = deque(maxlen=3600)
        self.start_time = time.time()

        # Caché de métricas por zona
        self._zone_cache: Dict[str, Dict] = {}
        self._cache_ts = 0

        # Cargar dispositivos existentes
        self._init_from_devices()

    def _init_from_devices(self):
        """Inicializa modelos desde devices.json existente."""
        data_file = BASE_DIR / "data" / "devices.json"
        if not data_file.exists():
            return

        devices = json.loads(data_file.read_text())
        zones = ["zona-norte", "zona-centro", "zona-sur"]

        for i, (did, dev) in enumerate(devices.items()):
            model = NodeEnergyModel(did, dev.get("device_type", "router"))

            # Simular configuración variada para demo
            model.tx_power_level = random.choice([0, 1, 2])
            model.duty_cycle = random.uniform(0.05, 0.3)
            model.tx_interval_s = random.uniform(0.5, 5.0)
            model.aggregation_ratio = random.uniform(1.0, 3.0)

            self.nodes[did] = model
            self.zone_map[did] = zones[i % 3]

    def register_node(self, node_id: str, node_type: str = "router",
                      zone: str = "zona-centro"):
        """Registra un nuevo nodo en el motor."""
        if node_id not in self.nodes:
            self.nodes[node_id] = NodeEnergyModel(node_id, node_type)
            self.zone_map[node_id] = zone

    def ingest(self, node_id: str, active: bool = True,
               powered: bool = True, **kwargs) -> Optional[Dict]:
        """
        Ingesta una muestra de telemetría de un nodo.
        Llamado por el MQTT handler o simulador.
        """
        if node_id not in self.nodes:
            self.register_node(node_id)

        model = self.nodes[node_id]
        sample = model.tick(active=active, powered=powered, **kwargs)
        return sample

    def tick_all(self, devices_state: Dict) -> Dict:
        """Procesa todos los nodos en paralelo (llamar cada segundo)."""
        now = time.time()
        total_power = 0.0
        active_count = 0
        results = {}

        for nid, model in self.nodes.items():
            dev = devices_state.get(nid, {})
            active = dev.get("active", True)
            powered = dev.get("powered", True)

            sample = model.tick(active=active, powered=powered)
            total_power += sample.get("power_mW", 0)
            if active and powered:
                active_count += 1
            results[nid] = sample

        # Snapshot global
        global_snap = {
            "ts": now,
            "dt": datetime.fromtimestamp(now).isoformat(),
            "total_power_mW": round(total_power, 2),
            "total_power_W": round(total_power / 1000, 4),
            "active_nodes": active_count,
            "total_nodes": len(self.nodes),
        }
        self.global_history.append(global_snap)
        self._cache_ts = 0  # Invalidar caché de zonas

        return global_snap

    def get_zone_metrics(self) -> Dict[str, Dict]:
        """Métricas agregadas por zona geográfica."""
        if time.time() - self._cache_ts < 10:
            return self._zone_cache

        zone_data: Dict[str, Dict] = defaultdict(lambda: {
            "nodes": [], "total_power_mW": 0, "avg_power_mW": 0,
            "active": 0, "inactive": 0, "total_tx": 0, "total_rx": 0,
            "avg_efficiency": 0, "energy_mWh": 0,
        })

        for nid, model in self.nodes.items():
            zone = self.zone_map.get(nid, "zona-sin-asignar")
            stats = model.get_stats(WINDOW_MEDIUM)
            if not stats:
                continue

            z = zone_data[zone]
            z["nodes"].append(nid)
            z["total_power_mW"] += stats.get("avg_power_mW", 0)
            z["energy_mWh"] += stats.get("total_energy_mWh", 0)
            z["total_tx"] += stats.get("total_packets_tx", 0)
            z["total_rx"] += stats.get("total_packets_rx", 0)
            z["avg_efficiency"] += stats.get("efficiency_score", 0)

            if stats.get("samples", 0) > 0:
                z["active"] += 1
            else:
                z["inactive"] += 1

        # Calcular promedios
        result = {}
        for zone, z in zone_data.items():
            n = len(z["nodes"]) or 1
            result[zone] = {
                "zone": zone,
                "node_count": len(z["nodes"]),
                "node_ids": z["nodes"],
                "total_power_mW": round(z["total_power_mW"], 2),
                "total_power_W": round(z["total_power_mW"] / 1000, 4),
                "avg_power_per_node_mW": round(z["total_power_mW"] / n, 2),
                "total_energy_mWh": round(z["energy_mWh"], 4),
                "active_nodes": z["active"],
                "inactive_nodes": z["inactive"],
                "total_packets_tx": z["total_tx"],
                "total_packets_rx": z["total_rx"],
                "avg_efficiency_score": round(z["avg_efficiency"] / n, 1),
            }

        self._zone_cache = result
        self._cache_ts = time.time()
        return result

    def get_network_traffic(self) -> Dict:
        """Tráfico de datos por nodo (últimos 5 min)."""
        traffic = {}
        for nid, model in self.nodes.items():
            stats = model.get_stats(WINDOW_MEDIUM)
            traffic[nid] = {
                "node_id": nid,
                "zone": self.zone_map.get(nid),
                "tx_rate_pps": stats.get("tx_rate_pps", 0),
                "total_tx": stats.get("total_packets_tx", 0),
                "total_rx": stats.get("total_packets_rx", 0),
                "link_utilization": min(100, stats.get("tx_rate_pps", 0) * 10),
            }
        return traffic

    def get_heatmap_data(self) -> List[Dict]:
        """
        Datos para heatmap de consumo en el mapa de ciudad.
        Combina posición del dispositivo con consumo.
        """
        data_file = BASE_DIR / "data" / "devices.json"
        if not data_file.exists():
            return []

        devices = json.loads(data_file.read_text())
        heatmap = []

        for nid, model in self.nodes.items():
            dev = devices.get(nid, {})
            stats = model.get_stats(WINDOW_SHORT)
            if not stats or not dev:
                continue

            heatmap.append({
                "node_id": nid,
                "x": dev.get("x", 0),
                "y": dev.get("y", 0),
                "power_mW": stats.get("avg_power_mW", 0),
                "intensity": min(1.0, stats.get("avg_power_mW", 0) / 100),
                "efficiency": stats.get("efficiency_score", 0),
                "zone": self.zone_map.get(nid, ""),
            })

        return heatmap

    def get_global_timeseries(self, last_n: int = 300) -> List[Dict]:
        """Serie temporal de potencia total de la red."""
        return list(self.global_history)[-last_n:]

    def get_node_timeseries(self, node_id: str, last_n: int = 300) -> List[Dict]:
        """Serie temporal de un nodo específico."""
        if node_id not in self.nodes:
            return []
        return self.nodes[node_id].get_timeseries(last_n)

    def get_node_detail(self, node_id: str) -> Optional[Dict]:
        """Detalle completo de un nodo."""
        if node_id not in self.nodes:
            return None
        model = self.nodes[node_id]
        stats_short = model.get_stats(WINDOW_SHORT)
        stats_medium = model.get_stats(WINDOW_MEDIUM)
        stats_long = model.get_stats(WINDOW_LONG)
        breakdown = model.compute_instant_power_mW()

        return {
            "node_id": node_id,
            "zone": self.zone_map.get(node_id),
            "node_type": model.node_type,
            "config": {
                "tx_power_level": model.tx_power_level,
                "duty_cycle": model.duty_cycle,
                "tx_interval_s": model.tx_interval_s,
                "aggregation_ratio": model.aggregation_ratio,
            },
            "instant": breakdown,
            "stats_1min": stats_short,
            "stats_5min": stats_medium,
            "stats_1h": stats_long,
            "uptime_s": model.uptime_s,
        }

    def get_summary(self) -> Dict:
        """Resumen global del sistema."""
        all_stats = [m.get_stats(WINDOW_MEDIUM) for m in self.nodes.values()]
        all_stats = [s for s in all_stats if s]

        if not all_stats:
            return {}

        total_power = sum(s.get("avg_power_mW", 0) for s in all_stats)
        total_energy = sum(s.get("total_energy_mWh", 0) for s in all_stats)
        avg_efficiency = statistics.mean(s.get("efficiency_score", 0) for s in all_stats)

        # Top consumidores
        sorted_by_power = sorted(
            [(s["node_id"], s.get("avg_power_mW", 0)) for s in all_stats],
            key=lambda x: x[1], reverse=True
        )

        return {
            "timestamp": time.time(),
            "uptime_s": time.time() - self.start_time,
            "total_nodes": len(self.nodes),
            "total_power_mW": round(total_power, 2),
            "total_power_W": round(total_power / 1000, 4),
            "total_energy_mWh": round(total_energy, 4),
            "estimated_daily_Wh": round(total_power * 24 / 1000, 2),
            "avg_efficiency_score": round(avg_efficiency, 1),
            "top_consumers": sorted_by_power[:5],
            "zones": list(self.get_zone_metrics().keys()),
        }

    def apply_optimization(self, node_id: str, strategy: str) -> Dict:
        """
        Aplica una estrategia de optimización a un nodo.
        Retorna configuración nueva + ahorro estimado.
        """
        if node_id not in self.nodes:
            return {"error": "nodo no encontrado"}

        model = self.nodes[node_id]
        before = model.compute_instant_power_mW()

        if strategy == "duty_cycle_reduce":
            model.duty_cycle = max(0.05, model.duty_cycle * 0.7)
        elif strategy == "tx_power_reduce":
            model.tx_power_level = min(2, model.tx_power_level + 1)
        elif strategy == "interval_increase":
            model.tx_interval_s = min(30, model.tx_interval_s * 2)
        elif strategy == "aggregation_enable":
            model.aggregation_ratio = max(2.0, model.aggregation_ratio * 1.5)
        elif strategy == "full_optimize":
            model.tx_power_level = 2
            model.duty_cycle = max(0.05, model.duty_cycle * 0.5)
            model.tx_interval_s = min(10, model.tx_interval_s * 2)
            model.aggregation_ratio = max(3.0, model.aggregation_ratio * 2)
        elif strategy == "reset_defaults":
            model.tx_power_level = 0
            model.duty_cycle = 0.2
            model.tx_interval_s = 1.0
            model.aggregation_ratio = 1.0
        else:
            return {"error": f"estrategia desconocida: {strategy}"}

        after = model.compute_instant_power_mW()
        saving_pct = ((before["power_mW"] - after["power_mW"]) /
                      max(before["power_mW"], 0.001) * 100)

        return {
            "node_id": node_id,
            "strategy": strategy,
            "before_mW": before["power_mW"],
            "after_mW": after["power_mW"],
            "saving_mW": round(before["power_mW"] - after["power_mW"], 3),
            "saving_pct": round(saving_pct, 1),
            "new_config": {
                "tx_power_level": model.tx_power_level,
                "duty_cycle": model.duty_cycle,
                "tx_interval_s": model.tx_interval_s,
                "aggregation_ratio": model.aggregation_ratio,
            }
        }

    def persist_snapshot(self):
        """Persiste snapshot actual a disco (llamar periódicamente)."""
        snap = {
            "ts": time.time(),
            "dt": datetime.now().isoformat(),
            "summary": self.get_summary(),
            "zones": self.get_zone_metrics(),
        }
        snap_file = METRICS_DIR / f"snapshot_{int(time.time())}.json"
        # Mantener solo últimos 100 snapshots
        existing = sorted(METRICS_DIR.glob("snapshot_*.json"))
        if len(existing) >= 100:
            existing[0].unlink()
        snap_file.write_text(json.dumps(snap, indent=2))


# Instancia global del motor (singleton)
engine = MetricsEngine()
