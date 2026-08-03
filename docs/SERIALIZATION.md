# Serialization — IoT City Web

**Versión:** 1.0.0
**Última actualización:** 2026-08-02

Documenta el contrato de serialización entre el backend Python, los simuladores y el firmware del nodo (MRF24J40 + ATmega328P/2560).

---

## 1. Configuración de nodo en 3 bytes

La configuración optimizada de un nodo se transmite en **exactamente 3 bytes** entre el backend (`energy/optimizer.py` → `NodeConfig.to_firmware_bytes()`) y el firmware (`firmware_snippets/iot_city_node.h` → `config_to_bytes()`).

### Layout de bits (según firmware)

```
B0: [7:6] = tx_power_level (2 bits)   → 0=máx, 1=medio, 2=bajo
    [5:0] = duty_cycle × 63           (6 bits, resolución 1/63)
B1: [7:0] = tx_interval_s × 10        (uint8, resolución 0.1 s, satura a 25.5 s)
B2: [7:4] = aggregation_size (4 bits) → 1–8
    [3:2] = sleep_mode (2 bits)
    [1:0] = reservado
```

| Campo | Bits | Rango | Resolución |
|---|---|---|---|
| `tx_power_level` | B0[7:6] | 0–2 | 1 |
| `duty_cycle` | B0[5:0] | 0–1 | 1/63 ≈ 0.016 |
| `tx_interval_s` | B1[7:0] | 0–25.5 s | 0.1 s |
| `aggregation_size` | B2[7:4] | 1–8 | 1 |
| `sleep_mode` | B2[3:2] | 0–3 | 1 |

### ⚠️ Bug de interoperabilidad (crítico)

El backend **no sigue este layout**. En `energy/optimizer.py`:

```python
b2 = (agg_q << 4) | sleep_q          # sleep_mode en bits [1:0] ← INCORRECTO
...
sleep = (b2 & 0x03)                   # lee bits [1:0] ← INCORRECTO
```

Mientras el firmware (`iot_city_node.h:214,223`) usa:

```c
raw->b2 = (agg_q << 4) | (slp_q << 2);  // sleep_mode en bits [3:2]
sleep_q = (raw->b2 >> 2) & 0x03;
```

**Consecuencia:** cualquier configuración con `sleep_mode != none` serializada por el backend se decodifica corrupta en el nodo (y viceversa). **Corrección pendiente** (ver `LEARNINGS.md` §7 y `TODO.md`).

### Round-trip

`from_firmware_bytes(to_firmware_bytes(cfg))` debería reconstruir `cfg` con tolerancia ≤ 1/63 para `duty_cycle` y ≤ 0.1 s para `tx_interval_s`. El test de humo en `scripts/install_analytics.sh` verifica que `to_firmware_bytes()` devuelve exactamente 3 bytes.

---

## 2. Telemetría de nodo (NodeTelemetry, 8 bytes packed)

Estructura C packed en `iot_city_node.h`:

| Campo | Tamaño |
|---|---|
| `node_id` | 2 bytes |
| `power_raw` | 2 bytes (ADC, placeholder `512`) |
| `rssi` | 1 byte |
| `lqi` | 1 byte |
| `flags` | 1 byte: `[7:6]=tx_lvl`, `[5:4]=sleep_mode`, `[3]=active` |
| `seq` | 1 byte (dedup) |

Frame agregado (`AggregatedFrame`): `msg_type` (0xA1) + `count` + muestras de 8 B, máx. 66 bytes (payload 802.15.4 de 102 B con overhead de 15 B).

---

## 3. Devices en disco (JSON)

`data/devices.json` es un mapa `{ "id": { ...device } }`. **⚠️ Ojo con la pérdida de campos:** `simulator/mesh_simulator.py` (`get_state()`, líneas 80-95) escribe un subconjunto que **omite** `street`, `icon`, `color`, `end_devices`, `cameras`. Tras unos ciclos del simulador, el archivo queda con esquema degradado.

```json
{
  "RTR_001": { "id": "RTR_001", "device_type": "router", "x": 120.0, "y": 300.0, ... }
}
```

---

## 4. Límites de intervalo (inconsistencia transversal)

| Contexto | Máximo de `tx_interval_s` |
|---|---|
| `AdaptiveIntervalController.MAX_INTERVAL_S` | 60.0 s |
| `metrics_engine` `interval_increase` | 30 s (cap) |
| Serialización uint8 (×10) | 25.5 s |
| Algoritmo firmware | 25.0 s |

Por encima de 25.5 s el valor **se trunca** al serializar — los límites deben unificarse.
