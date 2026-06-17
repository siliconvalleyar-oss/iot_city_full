#!/usr/bin/env python3
"""
Generador procedural de ciudades IoT.

Produce una topología con 8 routers y 12 end devices (20 total)
en diferentes patrones geométricos dentro de un área de 800×500 px.

Cada generador usa random.Random(seed) para ser reproducible.
"""

import math
import random
from typing import Callable, Dict, List, Tuple

# ─────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────

STREETS = [
    "Av. Mitre", "Av. San Martín", "Calle Belgrano",
    "Av. Rivadavia", "Calle Sarmiento", "Av. Roca",
    "Calle Moreno", "Av. Corrientes", "Calle Italia",
    "Av. 9 de Julio", "Calle Florida", "Av. Libertador",
]

CENTER = (400, 250)
NUM_ROUTERS = 8
NUM_END = 12


# ─────────────────────────────────────────────
# UTILIDADES COMPARTIDAS
# ─────────────────────────────────────────────

def _make_router(rng: random.Random, did: str, x: float, y: float) -> dict:
    return {
        "id": did,
        "x": round(x, 1), "y": round(y, 1),
        "street": rng.choice(STREETS),
        "device_type": "router",
        "active": True,
        "powered": True,
        "level": round(rng.uniform(70, 100), 1),
        "consumption": round(rng.uniform(50, 150), 1),
        "icon": "router",
        "color": "#FFD700",
        "connected_to": [],
        "end_devices": [],
        "last_seen": None,  # Se asigna en runtime
        "signal": round(rng.uniform(-60, -40), 1),
        "packets_sent": rng.randint(100, 1000),
        "packets_received": rng.randint(100, 1000),
    }


def _make_end_device(rng: random.Random, did: str, x: float, y: float) -> dict:
    return {
        "id": did,
        "x": round(x, 1), "y": round(y, 1),
        "street": rng.choice(STREETS),
        "device_type": "end_device",
        "active": True,
        "powered": True,
        "level": round(rng.uniform(60, 100), 1),
        "consumption": round(rng.uniform(20, 80), 1),
        "icon": "lamp",
        "color": "#00BFFF",
        "connected_to": [],
        "end_devices": [],
        "last_seen": None,
        "signal": round(rng.uniform(-80, -50), 1),
        "packets_sent": rng.randint(10, 200),
        "packets_received": rng.randint(10, 200),
    }


def _make_camera(rng: random.Random, did: str, x: float, y: float) -> dict:
    return {
        "id": did,
        "x": round(x, 1), "y": round(y, 1),
        "street": rng.choice(STREETS),
        "device_type": "camera",
        "active": True,
        "powered": True,
        "level": round(rng.uniform(70, 100), 1),
        "consumption": round(rng.uniform(10, 35), 1),
        "icon": "camera",
        "color": "#FF6B6B",
        "connected_to": [],
        "end_devices": [],
        "last_seen": None,
        "signal": round(rng.uniform(-70, -45), 1),
        "packets_sent": rng.randint(200, 1500),
        "packets_received": rng.randint(50, 500),
    }


def _compute_mesh(devices: dict) -> None:
    """Calcula conexiones mesh: cada dispositivo se conecta a los 2 routers más cercanos."""
    dev_list = list(devices.values())
    for dev in dev_list:
        distances = []
        for other in dev_list:
            if other["id"] == dev["id"]:
                continue
            dist = math.hypot(dev["x"] - other["x"], dev["y"] - other["y"])
            distances.append((dist, other["id"]))
        distances.sort()
        routers = [d for _, d in distances if devices[d]["device_type"] == "router"]
        dev["connected_to"] = routers[:2] if len(routers) >= 2 else routers

    for did, dev in devices.items():
        if dev["device_type"] == "end_device" and dev.get("connected_to"):
            router_id = dev["connected_to"][0]
            if router_id in devices:
                devices[router_id]["end_devices"].append(did)


def _scatter(rng: random.Random, center_x: float, center_y: float,
             radius: float, n: int, jitter: float = 0.0) -> List[Tuple[float, float]]:
    """Genera n puntos uniformemente distribuidos en un círculo, con RNG propio."""
    points = []
    for i in range(n):
        angle = 2 * math.pi * i / n + rng.uniform(-0.05, 0.05)
        r = radius * (0.85 + rng.uniform(-jitter, jitter))
        x = center_x + r * math.cos(angle)
        y = center_y + r * math.sin(angle)
        points.append((x, y))
    return points


# ─────────────────────────────────────────────
# PATRONES DE CIUDAD
# ─────────────────────────────────────────────

def _add_cameras(rng: random.Random, devices: dict, num_cameras: int = 3) -> None:
    """Agrega cámaras de vigilancia en posiciones estratégicas.
    Las cámaras se colocan cerca de los routers (esquinas/avenidas principales).
    """
    routers = [(d["id"], d["x"], d["y"]) for d in devices.values() if d["device_type"] == "router"]
    if not routers:
        return
    existing_ids = set(devices.keys())
    cam_idx = 1
    while len([d for d in devices.values() if d["device_type"] == "camera"]) < num_cameras:
        rid, rx, ry = rng.choice(routers)
        angle = rng.uniform(0, 2 * math.pi)
        dist = rng.uniform(40, 100)
        cx = max(10, min(790, rx + dist * math.cos(angle)))
        cy = max(10, min(490, ry + dist * math.sin(angle)))
        cam_id = f"CAM_{cam_idx:03d}"
        while cam_id in existing_ids:
            cam_idx += 1
            cam_id = f"CAM_{cam_idx:03d}"
        devices[cam_id] = _make_camera(rng, cam_id, cx, cy)
        existing_ids.add(cam_id)
        cam_idx += 1

    # Reconectar mesh: las cámaras se conectan al router más cercano
    for dev in devices.values():
        if dev["device_type"] == "camera":
            distances = []
            for other in devices.values():
                if other["id"] == dev["id"] or other["device_type"] != "router":
                    continue
                dist = math.hypot(dev["x"] - other["x"], dev["y"] - other["y"])
                distances.append((dist, other["id"]))
            distances.sort()
            dev["connected_to"] = [d[1] for d in distances[:1]]
            # Registrar la cámara en el router
            if dev["connected_to"]:
                router_id = dev["connected_to"][0]
                if router_id in devices and "cameras" not in devices[router_id]:
                    devices[router_id]["cameras"] = []
                if router_id in devices:
                    devices[router_id]["cameras"].append(dev["id"])


def _set_last_seen(devices: dict) -> None:
    import time
    ts = time.time()
    for dev in devices.values():
        dev["last_seen"] = ts


def generate_ring(seed: int = 0) -> dict:
    """Anillos concéntricos."""
    rng = random.Random(seed)
    devices = {}

    for i, (x, y) in enumerate(_scatter(rng, CENTER[0], CENTER[1], 200, NUM_ROUTERS, jitter=0.08)):
        devices[f"RTR_{i+1:03d}"] = _make_router(rng, f"RTR_{i+1:03d}", x, y)

    for i, (x, y) in enumerate(_scatter(rng, CENTER[0], CENTER[1], 110, NUM_END, jitter=0.12)):
        devices[f"END_{i+1:03d}"] = _make_end_device(rng, f"END_{i+1:03d}", x, y)

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_grid(seed: int = 0) -> dict:
    """Cuadrícula 3×3 con manzanas."""
    rng = random.Random(seed)
    devices = {}
    cx, cy = CENTER
    spacing = 160

    grid_positions = [
        (cx - spacing, cy - spacing),
        (cx, cy - spacing),
        (cx + spacing, cy - spacing),
        (cx - spacing, cy),
        (cx + spacing, cy),
        (cx - spacing, cy + spacing),
        (cx, cy + spacing),
        (cx + spacing, cy + spacing),
    ]
    for i, (x, y) in enumerate(grid_positions):
        devices[f"RTR_{i+1:03d}"] = _make_router(
            rng, f"RTR_{i+1:03d}",
            x + rng.uniform(-15, 15),
            y + rng.uniform(-15, 15),
        )

    end_positions = [
        (cx, cy),
        (cx - 30, cy - 30),
        (cx + 30, cy + 30),
        (cx - spacing / 2, cy - spacing / 2),
        (cx + spacing / 2, cy - spacing / 2),
        (cx - spacing / 2, cy + spacing / 2),
        (cx + spacing / 2, cy + spacing / 2),
        (cx - spacing, cy),
        (cx + spacing, cy),
        (cx, cy + spacing),
        (cx - spacing * 0.75, cy + spacing * 0.75),
        (cx + spacing * 0.75, cy - spacing * 0.75),
    ]
    for i, (x, y) in enumerate(end_positions):
        devices[f"END_{i+1:03d}"] = _make_end_device(
            rng, f"END_{i+1:03d}",
            x + rng.uniform(-10, 10),
            y + rng.uniform(-10, 10),
        )

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_linear(seed: int = 0) -> dict:
    """Ciudad lineal a lo largo de una avenida central."""
    rng = random.Random(seed)
    devices = {}
    cx, cy = CENTER

    for i in range(NUM_ROUTERS):
        x = 100 + i * (600 / (NUM_ROUTERS - 1))
        y = cy + rng.uniform(-40, 40)
        devices[f"RTR_{i+1:03d}"] = _make_router(rng, f"RTR_{i+1:03d}", x, y)

    for i in range(NUM_END):
        side = 1 if i % 2 == 0 else -1
        offset = 70 + (i // 2) * 25
        x = 130 + i * (540 / (NUM_END - 1))
        y = cy + side * offset + rng.uniform(-15, 15)
        devices[f"END_{i+1:03d}"] = _make_end_device(rng, f"END_{i+1:03d}", x, y)

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_star(seed: int = 0) -> dict:
    """Estrella: routers en círculo interno, end devices en radios externos."""
    rng = random.Random(seed)
    devices = {}
    cx, cy = CENTER

    for i, (x, y) in enumerate(_scatter(rng, cx, cy, 90, NUM_ROUTERS, jitter=0.1)):
        devices[f"RTR_{i+1:03d}"] = _make_router(rng, f"RTR_{i+1:03d}", x, y)

    for i in range(NUM_END):
        angle = 2 * math.pi * i / NUM_END + math.pi / NUM_END
        r = 210 * (0.85 + rng.uniform(-0.1, 0.1))
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        devices[f"END_{i+1:03d}"] = _make_end_device(rng, f"END_{i+1:03d}", x, y)

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_spiral(seed: int = 0) -> dict:
    """Espiral logarítmica."""
    rng = random.Random(seed)
    devices = {}
    cx, cy = CENTER

    total = NUM_ROUTERS + NUM_END
    for i in range(total):
        t = i / total
        r = 30 + t * 220
        angle = t * 4 * math.pi + rng.uniform(-0.08, 0.08)
        x = cx + r * math.cos(angle) + rng.uniform(-10, 10)
        y = cy + r * math.sin(angle) + rng.uniform(-10, 10)

        if i < NUM_ROUTERS:
            did = f"RTR_{i+1:03d}"
            dev = _make_router(rng, did, x, y)
            dev["consumption"] = round(rng.uniform(50 + i * 5, 100 + i * 8), 1)
        else:
            did = f"END_{i - NUM_ROUTERS + 1:03d}"
            dev = _make_end_device(rng, did, x, y)
        devices[did] = dev

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_random(seed: int = 0) -> dict:
    """Distribución aleatoria con separación mínima entre routers."""
    rng = random.Random(seed)
    devices = {}

    router_positions: List[Tuple[float, float]] = []
    min_dist = 140
    attempts = 0
    while len(router_positions) < NUM_ROUTERS and attempts < 200:
        x = rng.uniform(80, 720)
        y = rng.uniform(50, 450)
        ok = True
        for ex, ey in router_positions:
            if math.hypot(x - ex, y - ey) < min_dist:
                ok = False
                break
        if ok:
            router_positions.append((x, y))
        attempts += 1

    while len(router_positions) < NUM_ROUTERS:
        router_positions.append((rng.uniform(80, 720), rng.uniform(50, 450)))

    for i, (x, y) in enumerate(router_positions):
        devices[f"RTR_{i+1:03d}"] = _make_router(rng, f"RTR_{i+1:03d}", x, y)

    for i in range(NUM_END):
        router_idx = rng.randint(0, NUM_ROUTERS - 1)
        rx, ry = router_positions[router_idx]
        angle = rng.uniform(0, 2 * math.pi)
        dist = rng.uniform(40, 130)
        x = rx + dist * math.cos(angle)
        y = ry + dist * math.sin(angle)
        devices[f"END_{i+1:03d}"] = _make_end_device(
            rng, f"END_{i+1:03d}",
            max(10, min(790, x)),
            max(10, min(490, y)),
        )

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_double_ring(seed: int = 0) -> dict:
    """Dos anillos que se intersectan — forma de 8."""
    rng = random.Random(seed)
    devices = {}
    cx, cy = CENTER
    offset_x = 130
    left_center = (cx - offset_x, cy)
    right_center = (cx + offset_x, cy)

    for i in range(4):
        angle = 2 * math.pi * i / 4 + rng.uniform(-0.05, 0.05)
        r = 140 * (0.9 + rng.uniform(-0.05, 0.05))
        x = left_center[0] + r * math.cos(angle)
        y = left_center[1] + r * math.sin(angle)
        devices[f"RTR_{i+1:03d}"] = _make_router(rng, f"RTR_{i+1:03d}", x, y)

    for i in range(4, 8):
        angle = 2 * math.pi * (i - 4) / 4 + rng.uniform(-0.05, 0.05)
        r = 140 * (0.9 + rng.uniform(-0.05, 0.05))
        x = right_center[0] + r * math.cos(angle)
        y = right_center[1] + r * math.sin(angle)
        devices[f"RTR_{i+1:03d}"] = _make_router(rng, f"RTR_{i+1:03d}", x, y)

    for i in range(6):
        angle = 2 * math.pi * i / 6 + rng.uniform(-0.1, 0.1)
        r = 75 * (0.85 + rng.uniform(-0.08, 0.08))
        x = left_center[0] + r * math.cos(angle)
        y = left_center[1] + r * math.sin(angle)
        devices[f"END_{i+1:03d}"] = _make_end_device(rng, f"END_{i+1:03d}", x, y)

    for i in range(6, 12):
        angle = 2 * math.pi * (i - 6) / 6 + rng.uniform(-0.1, 0.1)
        r = 75 * (0.85 + rng.uniform(-0.08, 0.08))
        x = right_center[0] + r * math.cos(angle)
        y = right_center[1] + r * math.sin(angle)
        devices[f"END_{i+1:03d}"] = _make_end_device(rng, f"END_{i+1:03d}", x, y)

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


def generate_cluster(seed: int = 0) -> dict:
    """Tres barrios separados (8 routers, 12 end devices)."""
    rng = random.Random(seed)
    devices = {}

    # 3 clusters con 3, 3, 2 routers respectivamente = 8 routers total
    clusters = [
        (200, 150),   # Noroeste — 3 routers
        (600, 150),   # Noreste — 3 routers
        (400, 400),   # Sur — 2 routers
    ]
    routers_per_cluster = [3, 3, 2]

    router_idx = 0
    for ci, (ccx, ccy) in enumerate(clusters):
        n = routers_per_cluster[ci]
        for _ in range(n):
            angle = rng.uniform(0, 2 * math.pi)
            dist = rng.uniform(30, 80)
            x = ccx + dist * math.cos(angle)
            y = ccy + dist * math.sin(angle)
            router_idx += 1
            devices[f"RTR_{router_idx:03d}"] = _make_router(
                rng, f"RTR_{router_idx:03d}", x, y,
            )

    # End devices: 4 en cada cluster = 12 total
    end_idx = 0
    for ci, (ccx, ccy) in enumerate(clusters):
        for _ in range(4):
            angle = rng.uniform(0, 2 * math.pi)
            dist = rng.uniform(50, 130)
            x = ccx + dist * math.cos(angle)
            y = ccy + dist * math.sin(angle)
            end_idx += 1
            devices[f"END_{end_idx:03d}"] = _make_end_device(
                rng, f"END_{end_idx:03d}",
                max(10, min(790, x)),
                max(10, min(490, y)),
            )

    _compute_mesh(devices)
    _add_cameras(rng, devices, 3)
    _set_last_seen(devices)
    return devices


# ─────────────────────────────────────────────
# REGISTRO DE GENERADORES
# ─────────────────────────────────────────────

PATTERNS: Dict[str, Callable[[int], dict]] = {
    "ring": generate_ring,
    "grid": generate_grid,
    "linear": generate_linear,
    "star": generate_star,
    "spiral": generate_spiral,
    "random": generate_random,
    "double_ring": generate_double_ring,
    "cluster": generate_cluster,
}

PATTERN_DESCRIPTIONS: Dict[str, str] = {
    "ring": "Anillos concéntricos — routers en anillo exterior, end devices en anillo interior",
    "grid": "Cuadrícula 3×3 — routers en intersecciones, end devices en manzanas",
    "linear": "Ciudad lineal — routers a lo largo de una avenida, end devices a los costados",
    "star": "Estrella radial — routers en círculo interno, end devices en radios externos",
    "spiral": "Espiral logarítmica — todos los dispositivos en una curva en espiral",
    "random": "Distribución aleatoria con separación mínima entre routers",
    "double_ring": "Dos anillos intersectados — forma de 8 con dos centros",
    "cluster": "Tres barrios separados — clusters Noroeste, Noreste y Sur",
}


def generate_city(pattern: str = "random", seed: int | None = None) -> dict:
    """Genera una ciudad usando el patrón indicado.

    Args:
        pattern: Nombre del patrón.
        seed: Semilla aleatoria. Si es None, se genera una semilla aleatoria.

    Returns:
        Dict con los dispositivos generados.
    """
    if seed is None:
        seed = random.randint(0, 999999)

    generator = PATTERNS.get(pattern)
    if generator is None:
        print(f"⚠️  Patrón '{pattern}' no encontrado, usando 'ring'")
        generator = PATTERNS["ring"]

    return generator(seed)


def list_patterns() -> List[dict]:
    """Retorna la lista de patrones disponibles."""
    return [
        {"name": name, "description": PATTERN_DESCRIPTIONS.get(name, "")}
        for name in sorted(PATTERNS.keys())
    ]
