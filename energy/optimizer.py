#!/usr/bin/env python3
"""
IoT City — Algoritmos de Optimización Energética
Implementa estrategias adaptativas para red MRF24J40 / IEEE 802.15.4

Estrategias implementadas:
  1. Duty Cycling Adaptativo     — ajusta ciclo activo/sleep por carga
  2. TX Power Control Dinámico   — reduce potencia si el enlace es bueno
  3. Agregación de Paquetes      — combina múltiples mensajes
  4. Ajuste de Intervalo         — modifica frecuencia según backpressure
  5. Sleep Mode Scheduling       — coordina sleep entre vecinos
"""

import math
import random
import statistics
import time
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Tuple


# ─────────────────────────────────────────────────────────────────
# ESTRUCTURAS DE DATOS
# ─────────────────────────────────────────────────────────────────

@dataclass
class LinkQuality:
    """Calidad de enlace 802.15.4 entre dos nodos."""
    node_a: str
    node_b: str
    rssi_dBm: float = -70.0       # Señal recibida
    lqi: int = 150                 # Link Quality Indicator (0-255)
    per: float = 0.01             # Packet Error Rate
    snr_dB: float = 15.0          # Signal-to-Noise Ratio
    distance_m: float = 50.0      # Distancia estimada
    last_update: float = field(default_factory=time.time)

    @property
    def quality_score(self) -> float:
        """Score 0-1 de calidad del enlace."""
        rssi_score = max(0, (self.rssi_dBm + 100) / 70)  # -100..-30 → 0..1
        lqi_score = self.lqi / 255
        per_score = 1 - min(1, self.per * 10)
        return round((rssi_score + lqi_score + per_score) / 3, 3)

    @property
    def min_tx_power_needed(self) -> int:
        """Nivel mínimo de TX power para mantener el enlace (0=max, 2=min)."""
        if self.rssi_dBm > -60:
            return 2   # Señal fuerte → mínima potencia
        elif self.rssi_dBm > -75:
            return 1   # Señal media
        else:
            return 0   # Señal débil → máxima potencia


@dataclass
class NodeConfig:
    """Configuración operativa de un nodo."""
    node_id: str
    tx_power_level: int = 0         # 0=+0dBm, 1=-10dBm, 2=-20dBm
    duty_cycle: float = 0.20        # Fracción activo vs sleep
    tx_interval_s: float = 1.0      # Segundos entre transmisiones
    aggregation_size: int = 1       # Paquetes a agregar antes de enviar
    sleep_mode: str = "power_save"  # power_save | deep_sleep | none
    rx_window_ms: float = 5.0       # Ventana de recepción (ms)
    beacon_order: int = 6           # BO en 802.15.4 (determina beacon interval)
    superframe_order: int = 4       # SO en 802.15.4

    def to_firmware_bytes(self) -> bytes:
        """
        Serializa configuración en formato compacto para enviar al nodo.
        Formato: [tx_pwr:2b][duty:6b][interval:8b][agg:4b][sleep:2b] = 3 bytes
        (economiza payload 802.15.4 vs JSON)
        """
        duty_q = int(self.duty_cycle * 63) & 0x3F
        interval_q = min(255, int(self.tx_interval_s * 10)) & 0xFF
        agg_q = min(15, self.aggregation_size) & 0x0F
        sleep_modes = {"none": 0, "power_save": 1, "deep_sleep": 2}
        sleep_q = sleep_modes.get(self.sleep_mode, 1) & 0x03

        b0 = ((self.tx_power_level & 0x03) << 6) | duty_q
        b1 = interval_q
        b2 = (agg_q << 4) | sleep_q

        return bytes([b0, b1, b2])

    @classmethod
    def from_firmware_bytes(cls, node_id: str, data: bytes) -> "NodeConfig":
        """Deserializa configuración recibida desde firmware."""
        if len(data) < 3:
            return cls(node_id=node_id)

        b0, b1, b2 = data[0], data[1], data[2]
        tx_pwr = (b0 >> 6) & 0x03
        duty_q = b0 & 0x3F
        interval_q = b1
        agg_q = (b2 >> 4) & 0x0F
        sleep_q = b2 & 0x03

        sleep_modes = {0: "none", 1: "power_save", 2: "deep_sleep"}

        return cls(
            node_id=node_id,
            tx_power_level=tx_pwr,
            duty_cycle=duty_q / 63.0,
            tx_interval_s=interval_q / 10.0,
            aggregation_size=agg_q,
            sleep_mode=sleep_modes.get(sleep_q, "power_save"),
        )


# ─────────────────────────────────────────────────────────────────
# ALGORITMO 1: DUTY CYCLING ADAPTATIVO
# ─────────────────────────────────────────────────────────────────

class AdaptiveDutyCycler:
    """
    Ajusta el duty cycle de cada nodo basado en:
    - Carga de tráfico observada
    - Número de vecinos activos
    - Nivel de batería (si disponible)

    Inspirado en S-MAC / T-MAC adaptativo para 802.15.4

    Pseudocódigo firmware (C/C++):
      void adaptDutyCycle() {
        float load = getTxQueueDepth() / MAX_QUEUE;
        if (load > THRESHOLD_HIGH) duty = min(DUTY_MAX, duty * 1.5);
        else if (load < THRESHOLD_LOW) duty = max(DUTY_MIN, duty * 0.8);
        setWakeupTimer(duty * CYCLE_PERIOD_MS);
      }
    """

    DUTY_MIN = 0.02   # 2% mínimo
    DUTY_MAX = 0.50   # 50% máximo
    LOAD_HIGH = 0.70  # umbral carga alta
    LOAD_LOW  = 0.20  # umbral carga baja

    def __init__(self):
        self.node_configs: Dict[str, NodeConfig] = {}
        self.queue_depths: Dict[str, float] = {}
        self.neighbor_counts: Dict[str, int] = {}
        self.adjustment_log: List[Dict] = []

    def update_load(self, node_id: str, queue_depth: float,
                    max_queue: int = 10, neighbor_count: int = 2):
        """Actualiza métricas de carga para un nodo."""
        self.queue_depths[node_id] = queue_depth / max_queue
        self.neighbor_counts[node_id] = neighbor_count

    def compute_optimal_duty(self, node_id: str,
                              current_duty: float) -> Tuple[float, str]:
        """
        Calcula duty cycle óptimo.
        Retorna (nuevo_duty, razón_del_cambio)
        """
        load = self.queue_depths.get(node_id, 0.3)
        neighbors = self.neighbor_counts.get(node_id, 2)

        # Factor de coordinación con vecinos
        # (evitar que todos duerman al mismo tiempo)
        neighbor_factor = 1.0 + (neighbors * 0.05)

        new_duty = current_duty

        if load > self.LOAD_HIGH:
            # Tráfico alto → aumentar duty cycle
            new_duty = min(self.DUTY_MAX, current_duty * 1.5 * neighbor_factor)
            reason = f"carga_alta({load:.0%})"
        elif load < self.LOAD_LOW:
            # Tráfico bajo → reducir duty cycle (ahorrar energía)
            new_duty = max(self.DUTY_MIN, current_duty * 0.75)
            reason = f"carga_baja({load:.0%})"
        else:
            # Ajuste fino hacia objetivo
            target = self.LOAD_LOW + load * (self.DUTY_MAX - self.DUTY_MIN)
            new_duty = current_duty + (target - current_duty) * 0.1
            reason = f"ajuste_fino({load:.0%})"

        new_duty = round(max(self.DUTY_MIN, min(self.DUTY_MAX, new_duty)), 4)

        if abs(new_duty - current_duty) > 0.005:
            self.adjustment_log.append({
                "ts": time.time(), "node": node_id,
                "old": current_duty, "new": new_duty, "reason": reason
            })
            if len(self.adjustment_log) > 500:
                self.adjustment_log.pop(0)

        return new_duty, reason

    def run_cycle(self, configs: Dict[str, NodeConfig],
                  network_state: Dict) -> Dict[str, NodeConfig]:
        """Ejecuta un ciclo de optimización para todos los nodos."""
        updated = {}
        for nid, cfg in configs.items():
            dev = network_state.get(nid, {})
            # Simular carga basada en estado del dispositivo
            load = random.uniform(0.1, 0.8) if dev.get("active") else 0.0
            neighbors = len(dev.get("connected_to", []))
            self.update_load(nid, load * 10, neighbor_count=max(1, neighbors))

            new_duty, reason = self.compute_optimal_duty(nid, cfg.duty_cycle)
            if new_duty != cfg.duty_cycle:
                cfg.duty_cycle = new_duty
                updated[nid] = cfg

        return updated


# ─────────────────────────────────────────────────────────────────
# ALGORITMO 2: TX POWER CONTROL DINÁMICO
# ─────────────────────────────────────────────────────────────────

class DynamicTXPowerController:
    """
    Ajusta potencia de TX del MRF24J40 basado en calidad del enlace.

    MRF24J40 soporta 32 niveles de potencia (RFCON3 register).
    Usamos 3 niveles simplificados: 0dBm / -10dBm / -20dBm

    Pseudocódigo firmware:
      void updateTXPower(uint8_t lqi, int8_t rssi) {
        if (rssi > -60 && lqi > 200) setTXPower(TX_LOW);    // -20dBm
        else if (rssi > -75 && lqi > 150) setTXPower(TX_MID); // -10dBm
        else setTXPower(TX_MAX);                               // 0dBm
        // Registrar en RFCON3: 0x00=max, 0x40=-5dB, 0x80=-10dB, 0xC0=-15dB
      }
    """

    # Márgenes de link budget (dB)
    MARGIN_AGGRESSIVE = 10  # Reducir agresivamente si hay margen
    MARGIN_CONSERVATIVE = 5

    def __init__(self):
        self.link_quality: Dict[Tuple[str, str], LinkQuality] = {}
        self.tx_history: Dict[str, List] = {}

    def update_link(self, node_a: str, node_b: str,
                    rssi: float, lqi: int, per: float = 0.01):
        """Actualiza métricas de enlace entre dos nodos."""
        key = (min(node_a, node_b), max(node_a, node_b))
        self.link_quality[key] = LinkQuality(
            node_a=node_a, node_b=node_b,
            rssi_dBm=rssi, lqi=lqi, per=per,
            snr_dB=rssi + 100  # estimación simple
        )

    def get_optimal_tx_power(self, node_id: str,
                              neighbor_ids: List[str]) -> Tuple[int, Dict]:
        """
        Determina el nivel de TX power óptimo para alcanzar todos los vecinos.
        Retorna (nivel_0_2, detalle_de_enlaces)
        """
        if not neighbor_ids:
            return 0, {}  # Sin vecinos → máxima potencia por seguridad

        worst_quality = 1.0
        details = {}

        for neighbor in neighbor_ids:
            key = (min(node_id, neighbor), max(node_id, neighbor))
            lq = self.link_quality.get(key)

            if lq:
                quality = lq.quality_score
                worst_quality = min(worst_quality, quality)
                details[neighbor] = {
                    "rssi": lq.rssi_dBm,
                    "lqi": lq.lqi,
                    "quality": quality,
                    "min_power_needed": lq.min_tx_power_needed,
                }
            else:
                # Sin datos → asumir calidad media
                worst_quality = min(worst_quality, 0.5)
                details[neighbor] = {"quality": 0.5, "min_power_needed": 1}

        # El nivel de TX es el máximo necesario entre todos los vecinos
        # (para alcanzar al más lejano/débil)
        max_power_needed = max(
            (d["min_power_needed"] for d in details.values()), default=0
        )

        # Aplicar margen de seguridad
        if worst_quality > 0.8 and max_power_needed > 0:
            # Buena señal → reducir un nivel
            optimal = max(0, max_power_needed - 1)
        else:
            optimal = max_power_needed

        return optimal, details

    def simulate_link_updates(self, devices: Dict) -> None:
        """Simula actualización de métricas de enlace (modo demo)."""
        dev_list = list(devices.items())
        for i, (nid, dev) in enumerate(dev_list):
            for neighbor_id in dev.get("connected_to", []):
                if not dev.get("powered", True):
                    continue
                neighbor = devices.get(neighbor_id, {})
                dist = math.sqrt(
                    (dev.get("x", 0) - neighbor.get("x", 0))**2 +
                    (dev.get("y", 0) - neighbor.get("y", 0))**2
                )
                # Modelo de propagación simplificado
                rssi = -40 - (dist * 0.3) + random.gauss(0, 3)
                lqi = max(0, min(255, int(255 - dist * 1.5)))
                per = max(0.001, min(0.5, dist / 500))
                self.update_link(nid, neighbor_id, rssi, lqi, per)


# ─────────────────────────────────────────────────────────────────
# ALGORITMO 3: AGREGACIÓN DE PAQUETES
# ─────────────────────────────────────────────────────────────────

class PacketAggregator:
    """
    Agrega múltiples paquetes pequeños en uno mayor para reducir
    overhead de radio (preámbulo, ACK, backoff CSMA-CA).

    Overhead por paquete 802.15.4:
      - Preámbulo: 4 bytes
      - SFD: 1 byte
      - PHY header: 1 byte
      - MAC header: ~9 bytes
      - Total overhead: ~15 bytes por paquete

    Con agregación de N paquetes: overhead/paquete = 15/N bytes

    Pseudocódigo firmware:
      typedef struct { uint8_t node_id; uint16_t power; int8_t rssi; } Telemetry;
      Telemetry buffer[MAX_AGG];
      uint8_t buf_count = 0;

      void addToBuffer(Telemetry t) {
        buffer[buf_count++] = t;
        if (buf_count >= AGG_SIZE || timeoutExpired()) flushBuffer();
      }

      void flushBuffer() {
        uint8_t payload[MAX_AGG * sizeof(Telemetry) + 2];
        payload[0] = MSG_AGGREGATED;
        payload[1] = buf_count;
        memcpy(&payload[2], buffer, buf_count * sizeof(Telemetry));
        MRF24J40_Send(payload, sizeof(payload));
        buf_count = 0;
      }
    """

    # Parámetros de formato de paquete 802.15.4
    OVERHEAD_BYTES = 15      # Header 802.15.4
    ACK_BYTES = 11           # ACK frame
    CSMA_OVERHEAD_ms = 3.0   # Backoff promedio CSMA-CA
    BITRATE_kbps = 250       # 802.15.4 @ 2.4GHz

    # Payload por muestra (bytes) — formato compacto
    SAMPLE_BYTES = 8   # [node_id:2][power_mW:2][lqi:1][rssi:1][flags:2]

    def __init__(self):
        self.pending: Dict[str, List[Dict]] = {}
        self.agg_size_config: Dict[str, int] = {}
        self.stats: Dict[str, Dict] = {}

    def compute_overhead_ratio(self, agg_size: int) -> Dict:
        """
        Calcula la reducción de overhead con agregación.
        """
        # Sin agregación
        single_total = self.OVERHEAD_BYTES + self.SAMPLE_BYTES
        single_efficiency = self.SAMPLE_BYTES / single_total

        # Con agregación
        agg_payload = self.SAMPLE_BYTES * agg_size
        agg_total = self.OVERHEAD_BYTES + agg_payload
        agg_efficiency = agg_payload / agg_total

        # Tiempo en aire (ms)
        t_air_single = (single_total * 8 / self.BITRATE_kbps)
        t_air_agg = (agg_total * 8 / self.BITRATE_kbps)
        t_saved_per_sample = (
            (t_air_single + self.CSMA_OVERHEAD_ms) -
            (t_air_agg / agg_size + self.CSMA_OVERHEAD_ms / agg_size)
        )

        # Ahorro energético estimado (radio en TX)
        # MRF24J40 TX @ +0dBm ≈ 23mA, 3.3V = 75.9mW
        power_tx_mW = 75.9
        energy_saved_mJ_per_sample = power_tx_mW * t_saved_per_sample / 1000

        return {
            "agg_size": agg_size,
            "overhead_reduction_pct": round((1 - single_efficiency / agg_efficiency) * 100 * -1 + 100, 1),
            "efficiency_single": round(single_efficiency * 100, 1),
            "efficiency_agg": round(agg_efficiency * 100, 1),
            "improvement_pct": round((agg_efficiency / single_efficiency - 1) * 100, 1),
            "t_air_single_ms": round(t_air_single, 3),
            "t_air_agg_ms": round(t_air_agg, 3),
            "t_saved_per_sample_ms": round(t_saved_per_sample, 3),
            "energy_saved_mJ_per_sample": round(energy_saved_mJ_per_sample, 4),
        }

    def optimal_agg_size(self, tx_rate_pps: float,
                          max_latency_s: float = 5.0,
                          max_payload_bytes: int = 100) -> int:
        """
        Calcula tamaño óptimo de agregación dado:
        - tx_rate_pps: tasa de generación de muestras
        - max_latency_s: latencia máxima aceptable
        - max_payload_bytes: límite de payload 802.15.4
        """
        max_by_latency = max(1, int(tx_rate_pps * max_latency_s))
        max_by_payload = max(1, (max_payload_bytes - self.OVERHEAD_BYTES) // self.SAMPLE_BYTES)
        return min(max_by_latency, max_by_payload, 8)  # máx 8 en práctica

    def add_sample(self, node_id: str, sample: Dict) -> Optional[List[Dict]]:
        """
        Agrega muestra al buffer. Si se llena → retorna lote para enviar.
        """
        if node_id not in self.pending:
            self.pending[node_id] = []
        self.pending[node_id].append(sample)

        agg_size = self.agg_size_config.get(node_id, 3)

        if len(self.pending[node_id]) >= agg_size:
            batch = self.pending.pop(node_id)
            return batch

        return None

    def get_analysis(self) -> Dict:
        """Análisis comparativo de tamaños de agregación."""
        return {
            "agg_comparison": [
                self.compute_overhead_ratio(n) for n in [1, 2, 3, 4, 6, 8]
            ],
            "recommendation": "Usar agregación de 3-4 paquetes es óptimo "
                              "para balancear latencia vs eficiencia energética"
        }


# ─────────────────────────────────────────────────────────────────
# ALGORITMO 4: AJUSTE DE INTERVALO ADAPTATIVO
# ─────────────────────────────────────────────────────────────────

class AdaptiveIntervalController:
    """
    Ajusta el intervalo de transmisión de cada nodo basado en:
    - Backpressure del gateway (buffer lleno)
    - Variabilidad de los datos (si no cambia, no enviar)
    - Hora del día / evento programado

    Pseudocódigo firmware:
      void adaptInterval() {
        float delta = abs(lastValue - currentValue) / lastValue;
        if (delta < CHANGE_THRESHOLD) {        // datos estables
          interval = min(MAX_INTERVAL, interval * BACKOFF_FACTOR);
        } else {                                // datos cambiaron
          interval = max(MIN_INTERVAL, interval * SPEEDUP_FACTOR);
        }
        if (gatewayBusy()) interval *= 1.5;    // backpressure
      }
    """

    MIN_INTERVAL_S = 0.5
    MAX_INTERVAL_S = 60.0
    CHANGE_THRESHOLD = 0.05   # 5% cambio mínimo para enviar inmediato
    BACKOFF_FACTOR = 1.5
    SPEEDUP_FACTOR = 0.7

    def __init__(self):
        self.last_values: Dict[str, float] = {}
        self.intervals: Dict[str, float] = {}
        self.gateway_busy: bool = False

    def update(self, node_id: str, value: float,
               current_interval: float) -> Tuple[float, str]:
        """
        Calcula nuevo intervalo de transmisión.
        Retorna (nuevo_intervalo, razón)
        """
        last = self.last_values.get(node_id, value)
        change = abs(value - last) / max(abs(last), 0.001)

        new_interval = current_interval

        if change < self.CHANGE_THRESHOLD:
            # Datos estables → aumentar intervalo (ahorrar energía)
            new_interval = min(self.MAX_INTERVAL_S,
                               current_interval * self.BACKOFF_FACTOR)
            reason = f"estable(Δ={change:.1%})"
        else:
            # Datos cambiaron → reducir intervalo (más resolución)
            new_interval = max(self.MIN_INTERVAL_S,
                               current_interval * self.SPEEDUP_FACTOR)
            reason = f"cambio(Δ={change:.1%})"

        if self.gateway_busy:
            new_interval = min(self.MAX_INTERVAL_S, new_interval * 1.5)
            reason += "+backpressure"

        self.last_values[node_id] = value
        self.intervals[node_id] = new_interval

        return round(new_interval, 2), reason


# ─────────────────────────────────────────────────────────────────
# ORQUESTADOR DE OPTIMIZACIÓN
# ─────────────────────────────────────────────────────────────────

class EnergyOptimizer:
    """
    Orquesta todos los algoritmos de optimización.
    Produce recomendaciones y las aplica a los nodos.
    """

    def __init__(self):
        self.duty_cycler = AdaptiveDutyCycler()
        self.tx_controller = DynamicTXPowerController()
        self.aggregator = PacketAggregator()
        self.interval_ctrl = AdaptiveIntervalController()

        self.node_configs: Dict[str, NodeConfig] = {}
        self.optimization_history: List[Dict] = []
        self.enabled = True

    def init_nodes(self, devices: Dict):
        """Inicializa configuración para todos los nodos."""
        for nid, dev in devices.items():
            if nid not in self.node_configs:
                self.node_configs[nid] = NodeConfig(
                    node_id=nid,
                    tx_power_level=random.choice([0, 1]),
                    duty_cycle=random.uniform(0.1, 0.3),
                    tx_interval_s=random.uniform(1.0, 5.0),
                    aggregation_size=random.choice([1, 2, 3]),
                )

    def run_optimization_cycle(self, devices: Dict) -> Dict:
        """
        Ejecuta un ciclo completo de optimización.
        Retorna configuraciones actualizadas + ahorro estimado.
        """
        if not self.enabled:
            return {}

        self.tx_controller.simulate_link_updates(devices)
        updated_configs = {}
        total_saving_mW = 0

        for nid, cfg in self.node_configs.items():
            dev = devices.get(nid, {})
            if not dev.get("powered", True):
                continue

            old_power = self._estimate_power(cfg)

            # 1. Duty cycle adaptativo
            new_duty, duty_reason = self.duty_cycler.compute_optimal_duty(
                nid, cfg.duty_cycle
            )
            cfg.duty_cycle = new_duty

            # 2. TX Power dinámico
            neighbors = dev.get("connected_to", [])
            optimal_tx, link_details = self.tx_controller.get_optimal_tx_power(
                nid, neighbors
            )
            cfg.tx_power_level = optimal_tx

            # 3. Tamaño de agregación óptimo
            tx_rate = 1.0 / max(cfg.tx_interval_s, 0.1)
            cfg.aggregation_size = self.aggregator.optimal_agg_size(tx_rate)

            # 4. Intervalo adaptativo (simulado con valor de consumo)
            power_val = old_power + random.gauss(0, 2)
            new_interval, int_reason = self.interval_ctrl.update(
                nid, power_val, cfg.tx_interval_s
            )
            cfg.tx_interval_s = new_interval

            new_power = self._estimate_power(cfg)
            saving = old_power - new_power
            total_saving_mW += saving

            if abs(saving) > 0.5:
                updated_configs[nid] = {
                    "config": asdict(cfg),
                    "saving_mW": round(saving, 2),
                    "saving_pct": round(saving / max(old_power, 0.1) * 100, 1),
                    "duty_reason": duty_reason,
                    "interval_reason": int_reason,
                    "tx_power": optimal_tx,
                    "link_quality": {k: v.get("quality", 0)
                                     for k, v in link_details.items()},
                }

        result = {
            "ts": time.time(),
            "nodes_optimized": len(updated_configs),
            "total_saving_mW": round(total_saving_mW, 2),
            "total_saving_W": round(total_saving_mW / 1000, 4),
            "updated": updated_configs,
        }

        self.optimization_history.append(result)
        if len(self.optimization_history) > 200:
            self.optimization_history.pop(0)

        return result

    def _estimate_power(self, cfg: NodeConfig) -> float:
        """Estimación rápida de consumo de un nodo (mW)."""
        from analytics.metrics_engine import NodeEnergyModel
        model = NodeEnergyModel(cfg.node_id)
        model.tx_power_level = cfg.tx_power_level
        model.duty_cycle = cfg.duty_cycle
        model.tx_interval_s = cfg.tx_interval_s
        model.aggregation_ratio = max(1, cfg.aggregation_size)
        return model.compute_instant_power_mW()["power_mW"]

    def get_recommendations(self, devices: Dict) -> List[Dict]:
        """Genera lista de recomendaciones priorizadas."""
        recs = []
        for nid, cfg in self.node_configs.items():
            dev = devices.get(nid, {})
            if not dev.get("powered", True):
                continue

            power = self._estimate_power(cfg)
            issues = []

            if cfg.tx_power_level == 0 and len(dev.get("connected_to", [])) > 0:
                issues.append({
                    "type": "tx_power",
                    "severity": "medium",
                    "msg": "TX al máximo — posible reducir potencia",
                    "action": "tx_power_reduce",
                    "saving_est_pct": 15,
                })

            if cfg.aggregation_size == 1:
                issues.append({
                    "type": "aggregation",
                    "severity": "high",
                    "msg": "Sin agregación de paquetes",
                    "action": "aggregation_enable",
                    "saving_est_pct": 20,
                })

            if cfg.duty_cycle > 0.35:
                issues.append({
                    "type": "duty_cycle",
                    "severity": "medium",
                    "msg": f"Duty cycle alto ({cfg.duty_cycle:.0%})",
                    "action": "duty_cycle_reduce",
                    "saving_est_pct": 25,
                })

            if cfg.tx_interval_s < 1.0:
                issues.append({
                    "type": "interval",
                    "severity": "low",
                    "msg": "Intervalo de TX muy frecuente",
                    "action": "interval_increase",
                    "saving_est_pct": 10,
                })

            if issues:
                recs.append({
                    "node_id": nid,
                    "zone": dev.get("street", ""),
                    "current_power_mW": round(power, 2),
                    "issues": issues,
                    "max_saving_pct": max(i["saving_est_pct"] for i in issues),
                })

        return sorted(recs, key=lambda r: r["max_saving_pct"], reverse=True)

    def get_aggregation_analysis(self) -> Dict:
        return self.aggregator.get_analysis()

    def get_optimization_history(self, last_n: int = 50) -> List[Dict]:
        return self.optimization_history[-last_n:]


# Instancia global
optimizer = EnergyOptimizer()
