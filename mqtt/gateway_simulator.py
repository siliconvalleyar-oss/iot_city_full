#!/usr/bin/env python3
"""
IoT City — Simulador de Gateway MQTT
Simula múltiples gateways Raspberry Pi publicando datos
"""
import json
import random
import time
import signal
import sys
from pathlib import Path

try:
    import paho.mqtt.client as mqtt
    MQTT_OK = True
except ImportError:
    MQTT_OK = False

RUNNING = True

def handler(s, f):
    global RUNNING
    RUNNING = False

signal.signal(signal.SIGINT, handler)
signal.signal(signal.SIGTERM, handler)

TOPICS = {
    "device_telemetry": "iot/city/device/{id}/telemetry",
    "gateway_metrics": "iot/city/gateway/{id}/metrics",
    "network_event": "iot/city/events",
    "alarm": "iot/city/alarms",
}

class MockGateway:
    """Gateway Raspberry Pi simulado."""

    def __init__(self, gw_id: str, zone: str, device_ids: list):
        self.id = gw_id
        self.zone = zone
        self.devices = device_ids
        self.cycles = 0
        self.client = None
        self.connected = False

    def connect(self, host="localhost", port=1883):
        if not MQTT_OK:
            return False
        try:
            self.client = mqtt.Client(client_id=f"gw-{self.id}")
            self.client.on_connect = lambda c, u, f, rc: setattr(self, 'connected', rc == 0)
            self.client.connect(host, port, 60)
            self.client.loop_start()
            time.sleep(0.5)
            return self.connected
        except Exception as e:
            print(f"  GW-{self.id}: MQTT no disponible ({e})")
            return False

    def publish(self, topic, payload):
        if self.client and self.connected:
            try:
                self.client.publish(topic, json.dumps(payload), qos=0)
            except Exception:
                pass

    def run_cycle(self, devices_data: dict):
        self.cycles += 1

        # Telemetría de cada dispositivo
        for dev_id in self.devices:
            if dev_id not in devices_data:
                continue
            dev = devices_data[dev_id].copy()
            dev["gateway"] = self.id
            dev["zone"] = self.zone
            dev["ts"] = time.time()
            dev["signal_noise_ratio"] = round(random.uniform(10, 30), 1)
            dev["lqi"] = random.randint(100, 255)  # Link Quality Indicator

            topic = TOPICS["device_telemetry"].format(id=dev_id)
            self.publish(topic, dev)

        # Métricas del gateway
        active = sum(1 for d in self.devices if devices_data.get(d, {}).get("active", True))
        powered = sum(1 for d in self.devices if devices_data.get(d, {}).get("powered", True))
        total_w = sum(devices_data.get(d, {}).get("consumption", 0) for d in self.devices if devices_data.get(d, {}).get("powered", True))

        metrics = {
            "gateway_id": self.id,
            "zone": self.zone,
            "cycle": self.cycles,
            "ts": time.time(),
            "devices_managed": len(self.devices),
            "devices_active": active,
            "devices_powered": powered,
            "total_power_w": round(total_w, 1),
            "uptime_s": self.cycles * 2,
            "cpu_temp": round(random.uniform(45, 75), 1),
            "free_memory_mb": round(random.uniform(200, 500), 0),
            "rssi": round(random.uniform(-70, -40), 1),
        }

        topic = TOPICS["gateway_metrics"].format(id=self.id)
        self.publish(topic, metrics)

        if self.cycles % 30 == 0:
            print(f"  GW-{self.id} ({self.zone}): {active}/{len(self.devices)} activos | {round(total_w,1)}W | ciclo {self.cycles}")

    def disconnect(self):
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()


def main():
    DATA_FILE = Path(__file__).parent.parent / "data" / "devices.json"
    if not DATA_FILE.exists():
        print("Esperando datos del backend...")
        for _ in range(30):
            if DATA_FILE.exists():
                break
            time.sleep(1)
        if not DATA_FILE.exists():
            print("No hay datos — iniciá el backend primero")
            return

    devices_data = json.loads(DATA_FILE.read_text())
    dev_ids = list(devices_data.keys())

    # Dividir dispositivos entre 3 gateways (zonas)
    chunk = len(dev_ids) // 3 or 1
    gateways = [
        MockGateway("GW_NORTE", "zona-norte", dev_ids[:chunk]),
        MockGateway("GW_CENTRO", "zona-centro", dev_ids[chunk:chunk*2]),
        MockGateway("GW_SUR", "zona-sur", dev_ids[chunk*2:]),
    ]

    print("=" * 50)
    print("  🌐 IoT City — Gateway MQTT Simulator")
    print("=" * 50)

    # Conectar gateways
    for gw in gateways:
        ok = gw.connect()
        status = "✅ conectado" if ok else "⚠️  sin MQTT"
        print(f"  GW-{gw.id}: {len(gw.devices)} dispositivos — {status}")

    print("\n  Publicando telemetría cada 2s...\n")

    while RUNNING:
        # Recargar datos actualizados
        try:
            devices_data = json.loads(DATA_FILE.read_text())
        except Exception:
            pass

        for gw in gateways:
            gw.run_cycle(devices_data)

        time.sleep(2)

    for gw in gateways:
        gw.disconnect()

    print("\n  Gateway simulator detenido.")


if __name__ == "__main__":
    main()
