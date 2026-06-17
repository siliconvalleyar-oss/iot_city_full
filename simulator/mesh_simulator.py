#!/usr/bin/env python3
"""
IoT City - Simulador de Red Zigbee Mesh
Simula gateways Raspberry Pi publicando datos vía MQTT
"""

import json
import math
import random
import signal
import sys
import time
from pathlib import Path
from typing import Dict, List

try:
    import paho.mqtt.client as mqtt
    MQTT_AVAILABLE = True
except ImportError:
    MQTT_AVAILABLE = False
    print("⚠️  paho-mqtt no disponible, simulando sin MQTT")

DATA_FILE = Path(__file__).parent.parent / "data" / "devices.json"
RUNNING = True

def signal_handler(sig, frame):
    global RUNNING
    print("\n🛑 Simulador detenido")
    RUNNING = False
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


class ZigbeeNode:
    """Simula un nodo Zigbee en la red mesh."""

    def __init__(self, device_data: Dict):
        self.id = device_data["id"]
        self.device_type = device_data.get("device_type", "router")
        self.x = device_data.get("x", 0)
        self.y = device_data.get("y", 0)
        self.active = device_data.get("active", True)
        self.powered = device_data.get("powered", True)
        self.level = device_data.get("level", 100.0)
        self.consumption = device_data.get("consumption", 50.0)
        self.signal = device_data.get("signal", -60.0)
        self.connected_to = device_data.get("connected_to", [])
        self.packets_sent = 0
        self.packets_received = 0
        self.fail_probability = 0.001  # 0.1% por ciclo

    def simulate_tick(self) -> Dict:
        """Simula un ciclo de la red."""
        if not self.powered:
            return self.get_state()

        # Fallo aleatorio (muy raro)
        if random.random() < self.fail_probability:
            self.powered = False
            self.active = False
            return {"event": "node_failure", **self.get_state()}

        # Fluctuaciones normales
        self.consumption = max(10, self.consumption * random.uniform(0.97, 1.03))
        self.signal = max(-100, min(-30, self.signal + random.uniform(-1, 1)))
        self.level = max(0, min(100, self.level + random.uniform(-0.5, 0.5)))

        # Simular tráfico
        if self.device_type == "router":
            self.packets_sent += random.randint(1, 10)
            self.packets_received += random.randint(1, 10)
        else:
            self.packets_sent += random.randint(0, 3)
            self.packets_received += random.randint(0, 3)

        return self.get_state()

    def get_state(self) -> Dict:
        return {
            "id": self.id,
            "device_type": self.device_type,
            "x": self.x,
            "y": self.y,
            "active": self.active,
            "powered": self.powered,
            "level": round(self.level, 1),
            "consumption": round(self.consumption, 1),
            "signal": round(self.signal, 1),
            "connected_to": self.connected_to,
            "packets_sent": self.packets_sent,
            "packets_received": self.packets_received,
            "last_seen": time.time()
        }


class MeshNetwork:
    """Simula la red mesh Zigbee completa."""

    def __init__(self, devices_data: Dict):
        self.nodes: Dict[str, ZigbeeNode] = {}
        self.routes: List[Dict] = []
        self.packet_queue: List[Dict] = []

        for did, data in devices_data.items():
            self.nodes[did] = ZigbeeNode(data)

        print(f"🌐 Red mesh inicializada: {len(self.nodes)} nodos")
        self._compute_routes()

    def _compute_routes(self):
        """Calcula rutas óptimas en la red mesh."""
        self.routes = []
        seen = set()
        for nid, node in self.nodes.items():
            for neighbor_id in node.connected_to:
                key = tuple(sorted([nid, neighbor_id]))
                if key not in seen and neighbor_id in self.nodes:
                    seen.add(key)
                    n = self.nodes[neighbor_id]
                    dist = math.sqrt((node.x - n.x)**2 + (node.y - n.y)**2)
                    self.routes.append({
                        "from": nid,
                        "to": neighbor_id,
                        "distance": round(dist, 1),
                        "active": True
                    })

    def simulate_packet_routing(self, source_id: str, dest_id: str) -> List[str]:
        """Simula enrutamiento de paquete por la red."""
        if source_id not in self.nodes or dest_id not in self.nodes:
            return []

        # BFS simple
        visited = {source_id}
        queue = [[source_id]]

        while queue:
            path = queue.pop(0)
            current = path[-1]

            if current == dest_id:
                return path

            node = self.nodes[current]
            for neighbor in node.connected_to:
                if neighbor not in visited and neighbor in self.nodes:
                    n = self.nodes[neighbor]
                    if n.powered and n.device_type == "router":
                        visited.add(neighbor)
                        queue.append(path + [neighbor])

        return []  # Sin ruta disponible

    def tick(self) -> List[Dict]:
        """Ejecuta un ciclo de simulación."""
        updates = []
        for nid, node in self.nodes.items():
            state = node.simulate_tick()
            if "event" in state:
                print(f"⚡ FALLO: {nid}")
            updates.append(state)

        # Actualizar rutas según estado de nodos
        for route in self.routes:
            from_node = self.nodes.get(route["from"])
            to_node = self.nodes.get(route["to"])
            route["active"] = (
                from_node and from_node.powered and
                to_node and to_node.powered
            )

        return updates


class Gateway:
    """Simula un gateway Raspberry Pi publicando a MQTT."""

    def __init__(self, gateway_id: str, mqtt_client, network: MeshNetwork):
        self.id = gateway_id
        self.mqtt = mqtt_client
        self.network = network
        self.cycles = 0

    def publish_cycle(self):
        """Publica telemetría de todos los nodos."""
        if not self.mqtt:
            return

        updates = self.network.tick()
        self.cycles += 1

        for state in updates:
            topic = f"iot/city/device/{state['id']}/telemetry"
            try:
                self.mqtt.publish(topic, json.dumps(state), qos=0, retain=False)
            except Exception:
                pass

        # Publicar métricas de red
        active = sum(1 for n in self.network.nodes.values() if n.active)
        powered = sum(1 for n in self.network.nodes.values() if n.powered)
        total_power = sum(n.consumption for n in self.network.nodes.values() if n.powered)

        metrics = {
            "gateway_id": self.id,
            "cycle": self.cycles,
            "timestamp": time.time(),
            "total_nodes": len(self.network.nodes),
            "active_nodes": active,
            "powered_nodes": powered,
            "total_power_w": round(total_power, 1),
            "routes": len(self.network.routes),
            "active_routes": sum(1 for r in self.network.routes if r["active"])
        }

        try:
            self.mqtt.publish("iot/city/gateway/metrics", json.dumps(metrics), qos=0)
        except Exception:
            pass

        if self.cycles % 10 == 0:
            print(f"📡 GW-{self.id} | Ciclo {self.cycles} | "
                  f"Nodos: {active}/{len(self.network.nodes)} activos | "
                  f"Potencia: {round(total_power, 1)}W")


def main():
    global RUNNING

    print("="*50)
    print("  🌆 IoT City - Simulador Zigbee Mesh")
    print("="*50)

    # Cargar dispositivos
    if not DATA_FILE.exists():
        print(f"❌ No se encontró {DATA_FILE}")
        print("   Ejecuta el backend primero para generar los datos")
        sys.exit(1)

    devices_data = json.loads(DATA_FILE.read_text())
    print(f"📂 Dispositivos cargados: {len(devices_data)}")

    # Inicializar red
    network = MeshNetwork(devices_data)

    # Conectar MQTT
    mqtt_client = None
    if MQTT_AVAILABLE:
        try:
            mqtt_client = mqtt.Client(client_id=f"gw-simulator-{int(time.time())}")
            mqtt_client.connect("localhost", 1883, 60)
            mqtt_client.loop_start()
            print("✅ MQTT conectado a localhost:1883")
        except Exception as e:
            print(f"⚠️  MQTT no disponible: {e}")
            mqtt_client = None

    # Crear gateway
    gw = Gateway("GW_001", mqtt_client, network)

    print("\n🔄 Iniciando simulación... (Ctrl+C para detener)\n")

    while RUNNING:
        gw.publish_cycle()

        # Simular eventos aleatorios
        r = random.random()
        if r < 0.002:  # 0.2% probabilidad por ciclo
            nodes = list(network.nodes.values())
            target = random.choice(nodes)
            target.powered = False
            target.active = False
            print(f"⚡ EVENTO: Fallo eléctrico en {target.id}")

        elif r < 0.004:
            nodes = [n for n in network.nodes.values() if not n.powered]
            if nodes:
                target = random.choice(nodes)
                target.powered = True
                target.active = True
                print(f"✅ EVENTO: Restauración de {target.id}")

        # Actualizar datos en disco periódicamente
        if gw.cycles % 5 == 0:
            updated = {}
            for nid, node in network.nodes.items():
                updated[nid] = node.get_state()
            try:
                DATA_FILE.write_text(json.dumps(updated, indent=2))
            except Exception:
                pass

        time.sleep(2)

    if mqtt_client:
        mqtt_client.loop_stop()
        mqtt_client.disconnect()

    print("✅ Simulador detenido limpiamente")


if __name__ == "__main__":
    main()
