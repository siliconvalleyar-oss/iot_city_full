#!/usr/bin/env python3
"""
IoT City Platform - Backend API
FastAPI + WebSocket + MQTT Integration
Port: 5062
"""

import asyncio
import json
import random
import time
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import paho.mqtt.client as mqtt
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from city_generator import generate_city, list_patterns

# ─────────────────────────────────────────────
# MODELOS
# ─────────────────────────────────────────────

class DeviceCreate(BaseModel):
    id: str
    x: float
    y: float
    street: str
    device_type: str = "router"  # router | end_device | camera
    icon: str = "lamp"
    color: str = "#FFD700"

class DeviceUpdate(BaseModel):
    powered: Optional[bool] = None
    active: Optional[bool] = None
    level: Optional[float] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    street: Optional[str] = None

class NetworkEvent(BaseModel):
    event_type: str  # fail | restore | toggle | update
    device_id: str
    data: Optional[Dict] = None

# ─────────────────────────────────────────────
# ESTADO GLOBAL
# ─────────────────────────────────────────────

BASE_DIR = Path(__file__).parent.parent
DATA_FILE = BASE_DIR / "data" / "devices.json"
DATA_FILE.parent.mkdir(exist_ok=True)

def load_devices():
    if DATA_FILE.exists():
        return json.loads(DATA_FILE.read_text())
    return generate_demo_city()

def save_devices(devices):
    DATA_FILE.write_text(json.dumps(devices, indent=2))

_CURRENT_PATTERN = "random"
_CURRENT_SEED: int | None = None

def generate_demo_city(pattern: str = "random", seed: int | None = None) -> dict:
    """Genera una ciudad procedural usando el patrón indicado.

    Args:
        pattern: ring, grid, linear, star, spiral, random, double_ring, cluster
        seed: Semilla para reproducibilidad. None = aleatoria.
    """
    global _CURRENT_PATTERN, _CURRENT_SEED
    _CURRENT_PATTERN = pattern
    if seed is not None:
        _CURRENT_SEED = seed
    else:
        _CURRENT_SEED = random.randint(0, 999999)

    devices = generate_city(pattern, _CURRENT_SEED)
    save_devices(devices)
    return devices

# Estado global
DEVICES: Dict[str, Any] = load_devices()
CONNECTED_WS: List[WebSocket] = []
MQTT_CLIENT: Optional[mqtt.Client] = None
NETWORK_LOG: List[Dict] = []

# ─────────────────────────────────────────────
# FASTAPI APP
# ─────────────────────────────────────────────

app = FastAPI(
    title="IoT City Platform",
    description="Plataforma de gestión de luminarias inteligentes y dispositivos urbanos",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir frontend
FRONTEND_PATH = BASE_DIR / "frontend"
ASSETS_PATH = BASE_DIR / "assets"
ASSETS_PATH.mkdir(parents=True, exist_ok=True)
(ASSETS_PATH / "icons").mkdir(exist_ok=True)

if FRONTEND_PATH.exists():
    app.mount("/assets", StaticFiles(directory=str(ASSETS_PATH)), name="assets")

# ─────────────────────────────────────────────
# WEBSOCKET MANAGER
# ─────────────────────────────────────────────

async def broadcast(message: Dict):
    """Enviar mensaje a todos los clientes WebSocket."""
    dead = []
    for ws in CONNECTED_WS:
        try:
            await ws.send_json(message)
        except Exception:
            dead.append(ws)
    for ws in dead:
        CONNECTED_WS.remove(ws)

def log_event(event_type: str, device_id: str, detail: str = ""):
    entry = {
        "timestamp": datetime.now().isoformat(),
        "event_type": event_type,
        "device_id": device_id,
        "detail": detail
    }
    NETWORK_LOG.append(entry)
    if len(NETWORK_LOG) > 500:
        NETWORK_LOG.pop(0)
    return entry

# ─────────────────────────────────────────────
# MQTT
# ─────────────────────────────────────────────

def setup_mqtt():
    global MQTT_CLIENT
    try:
        client = mqtt.Client(client_id="iot-city-backend")

        def on_connect(c, userdata, flags, rc):
            if rc == 0:
                print("✅ MQTT conectado")
                c.subscribe("iot/city/#")
            else:
                print(f"⚠️  MQTT error rc={rc}")

        def on_message(c, userdata, msg):
            try:
                payload = json.loads(msg.payload.decode())
                topic = msg.topic
                if "device/" in topic:
                    parts = topic.split("/")
                    did = parts[2] if len(parts) > 2 else None
                    if did and did in DEVICES:
                        DEVICES[did].update(payload)
                        DEVICES[did]["last_seen"] = time.time()
                        save_devices(DEVICES)
                        asyncio.run_coroutine_threadsafe(
                            broadcast({"type": "device_update", "device": DEVICES[did]}),
                            asyncio.get_event_loop()
                        )
            except Exception as e:
                print(f"MQTT msg error: {e}")

        client.on_connect = on_connect
        client.on_message = on_message
        client.connect("localhost", 1883, 60)
        client.loop_start()
        MQTT_CLIENT = client
        return client
    except Exception as e:
        print(f"⚠️  MQTT no disponible: {e}")
        return None

# ─────────────────────────────────────────────
# SIMULACIÓN DE RED
# ─────────────────────────────────────────────

async def simulate_network():
    """Simula actividad de red Zigbee en tiempo real."""
    while True:
        await asyncio.sleep(3)
        for did, dev in DEVICES.items():
            if not dev.get("powered", True):
                continue

            # Fluctuación de consumo
            dev["consumption"] = round(
                dev["consumption"] * random.uniform(0.95, 1.05), 1
            )
            # Fluctuación de señal
            dev["signal"] = round(
                max(-100, min(-30, dev["signal"] + random.uniform(-2, 2))), 1
            )
            # Paquetes
            dev["packets_sent"] += random.randint(0, 5)
            dev["packets_received"] += random.randint(0, 5)
            dev["last_seen"] = time.time()

        save_devices(DEVICES)
        metrics = get_metrics()
        await broadcast({
            "type": "network_update",
            "devices": DEVICES,
            "metrics": metrics
        })

def get_metrics():
    devs = list(DEVICES.values())
    total = len(devs)
    powered = sum(1 for d in devs if d.get("powered", True))
    active = sum(1 for d in devs if d.get("active", True))
    total_consumption = round(sum(d.get("consumption", 0) for d in devs if d.get("powered", True)), 1)
    routers = sum(1 for d in devs if d.get("device_type") == "router")
    end_devs = sum(1 for d in devs if d.get("device_type") == "end_device")
    cameras = sum(1 for d in devs if d.get("device_type") == "camera")
    return {
        "total_devices": total,
        "powered": powered,
        "unpowered": total - powered,
        "active": active,
        "inactive": total - active,
        "routers": routers,
        "end_devices": end_devs,
        "cameras": cameras,
        "total_consumption_w": total_consumption,
        "network_health": round((powered / total * 100) if total else 0, 1),
        "timestamp": time.time()
    }

# ─────────────────────────────────────────────
# ENDPOINTS REST
# ─────────────────────────────────────────────

@app.get("/")
async def root():
    index = FRONTEND_PATH / "index.html"
    if index.exists():
        return FileResponse(str(index))
    return {"status": "IoT City API running", "docs": "/api/docs"}

@app.get("/api/devices")
async def get_devices():
    return {"devices": list(DEVICES.values()), "count": len(DEVICES)}

@app.get("/api/devices/{device_id}")
async def get_device(device_id: str):
    if device_id not in DEVICES:
        raise HTTPException(404, f"Dispositivo {device_id} no encontrado")
    return DEVICES[device_id]

@app.post("/api/devices")
async def create_device(device: DeviceCreate):
    if device.id in DEVICES:
        raise HTTPException(409, f"Dispositivo {device.id} ya existe")

    new_dev = {
        "id": device.id,
        "x": device.x,
        "y": device.y,
        "street": device.street,
        "device_type": device.device_type,
        "active": True,
        "powered": True,
        "level": 100.0,
        "consumption": random.uniform(30, 100),
        "icon": device.icon,
        "color": device.color,
        "connected_to": [],
        "end_devices": [],
        "last_seen": time.time(),
        "signal": round(random.uniform(-70, -40), 1),
        "packets_sent": 0,
        "packets_received": 0,
    }

    # Calcular conexiones automáticas
    distances = []
    for did, dev in DEVICES.items():
        dist = ((new_dev["x"] - dev["x"])**2 + (new_dev["y"] - dev["y"])**2)**0.5
        distances.append((dist, did))
    distances.sort()
    routers = [d for _, d in distances if DEVICES[d]["device_type"] == "router"]
    new_dev["connected_to"] = routers[:2]

    DEVICES[device.id] = new_dev
    save_devices(DEVICES)

    entry = log_event("device_added", device.id, f"Tipo: {device.device_type}")
    await broadcast({"type": "device_added", "device": new_dev, "log": entry})

    if MQTT_CLIENT:
        MQTT_CLIENT.publish(f"iot/city/device/{device.id}/status", json.dumps({"status": "new", "device": new_dev}))

    return new_dev

@app.patch("/api/devices/{device_id}")
async def update_device(device_id: str, update: DeviceUpdate):
    if device_id not in DEVICES:
        raise HTTPException(404, f"Dispositivo {device_id} no encontrado")

    dev = DEVICES[device_id]
    changes = update.dict(exclude_none=True)
    dev.update(changes)
    dev["last_seen"] = time.time()
    save_devices(DEVICES)

    entry = log_event("device_updated", device_id, str(changes))
    await broadcast({"type": "device_update", "device": dev, "log": entry})

    if MQTT_CLIENT:
        MQTT_CLIENT.publish(f"iot/city/device/{device_id}/update", json.dumps(changes))

    return dev

@app.delete("/api/devices/{device_id}")
async def delete_device(device_id: str):
    if device_id not in DEVICES:
        raise HTTPException(404, f"Dispositivo {device_id} no encontrado")

    del DEVICES[device_id]
    # Limpiar referencias
    for dev in DEVICES.values():
        dev["connected_to"] = [d for d in dev.get("connected_to", []) if d != device_id]
        dev["end_devices"] = [d for d in dev.get("end_devices", []) if d != device_id]

    save_devices(DEVICES)
    entry = log_event("device_removed", device_id)
    await broadcast({"type": "device_removed", "device_id": device_id, "log": entry})
    return {"deleted": device_id}

@app.post("/api/devices/{device_id}/toggle")
async def toggle_device(device_id: str):
    if device_id not in DEVICES:
        raise HTTPException(404, f"Dispositivo {device_id} no encontrado")
    dev = DEVICES[device_id]
    dev["active"] = not dev.get("active", True)
    dev["last_seen"] = time.time()
    save_devices(DEVICES)
    entry = log_event("device_toggled", device_id, f"active={dev['active']}")
    await broadcast({"type": "device_update", "device": dev, "log": entry})
    return dev

@app.post("/api/devices/{device_id}/power")
async def toggle_power(device_id: str):
    if device_id not in DEVICES:
        raise HTTPException(404, f"Dispositivo {device_id} no encontrado")
    dev = DEVICES[device_id]
    dev["powered"] = not dev.get("powered", True)
    if not dev["powered"]:
        dev["active"] = False
    dev["last_seen"] = time.time()
    save_devices(DEVICES)
    entry = log_event("power_event", device_id, f"powered={dev['powered']}")
    await broadcast({"type": "device_update", "device": dev, "log": entry})
    return dev

@app.post("/api/simulate/blackout")
async def simulate_blackout(area: Dict = None):
    """Simula corte de energía en área o total."""
    affected = []
    for did, dev in DEVICES.items():
        dev["powered"] = False
        dev["active"] = False
        affected.append(did)
    save_devices(DEVICES)
    entry = log_event("blackout", "ALL", f"Afectados: {len(affected)}")
    await broadcast({"type": "blackout", "affected": affected, "log": entry})
    return {"affected": len(affected)}

@app.post("/api/simulate/restore")
async def simulate_restore():
    """Restaura energía en toda la red."""
    for dev in DEVICES.values():
        dev["powered"] = True
        dev["active"] = True
    save_devices(DEVICES)
    entry = log_event("restore", "ALL", "Red restaurada")
    await broadcast({"type": "restore", "devices": DEVICES, "log": entry})
    return {"restored": len(DEVICES)}

@app.post("/api/simulate/fail/{device_id}")
async def simulate_fail(device_id: str):
    """Simula caída de nodo."""
    if device_id not in DEVICES:
        raise HTTPException(404)
    dev = DEVICES[device_id]
    dev["powered"] = False
    dev["active"] = False
    save_devices(DEVICES)
    entry = log_event("node_failure", device_id)
    await broadcast({"type": "device_update", "device": dev, "log": entry})
    return dev

@app.get("/api/metrics")
async def metrics():
    return get_metrics()

@app.get("/api/logs")
async def get_logs(limit: int = 100):
    return {"logs": NETWORK_LOG[-limit:], "total": len(NETWORK_LOG)}

@app.get("/api/mesh")
async def get_mesh():
    """Retorna la topología de red mesh."""
    links = []
    seen = set()
    for did, dev in DEVICES.items():
        if not dev.get("powered", True):
            continue
        for neighbor in dev.get("connected_to", []):
            link_key = tuple(sorted([did, neighbor]))
            if link_key not in seen and neighbor in DEVICES:
                seen.add(link_key)
                n_dev = DEVICES[neighbor]
                strength = 1.0 if (dev.get("powered") and n_dev.get("powered")) else 0.0
                links.append({
                    "source": did,
                    "target": neighbor,
                    "strength": strength,
                    "active": dev.get("active", True) and n_dev.get("active", True)
                })
    return {"links": links, "nodes": list(DEVICES.values())}

@app.post("/api/icons/upload")
async def upload_icon(file: UploadFile = File(...)):
    """Sube nuevo ícono SVG/PNG."""
    icons_dir = ASSETS_PATH / "icons"
    icons_dir.mkdir(exist_ok=True)
    dest = icons_dir / file.filename
    dest.write_bytes(await file.read())
    return {"icon": file.filename, "path": f"/assets/icons/{file.filename}"}

@app.get("/api/icons")
async def list_icons():
    icons_dir = ASSETS_PATH / "icons"
    icons_dir.mkdir(exist_ok=True)
    icons = [f.name for f in icons_dir.iterdir() if f.suffix in [".svg", ".png", ".webp"]]
    return {"icons": icons}

# ─────────────────────────────────────────────
# WEBSOCKET
# ─────────────────────────────────────────────

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    CONNECTED_WS.append(ws)

    # Enviar estado inicial
    await ws.send_json({
        "type": "init",
        "devices": DEVICES,
        "metrics": get_metrics(),
        "logs": NETWORK_LOG[-50:]
    })

    try:
        while True:
            data = await ws.receive_json()
            msg_type = data.get("type")

            if msg_type == "ping":
                await ws.send_json({"type": "pong", "ts": time.time()})

            elif msg_type == "toggle":
                did = data.get("device_id")
                if did in DEVICES:
                    DEVICES[did]["active"] = not DEVICES[did].get("active", True)
                    save_devices(DEVICES)
                    await broadcast({"type": "device_update", "device": DEVICES[did]})

            elif msg_type == "move":
                did = data.get("device_id")
                if did in DEVICES:
                    DEVICES[did]["x"] = data.get("x", DEVICES[did]["x"])
                    DEVICES[did]["y"] = data.get("y", DEVICES[did]["y"])
                    save_devices(DEVICES)
                    await broadcast({"type": "device_update", "device": DEVICES[did]})

    except WebSocketDisconnect:
        CONNECTED_WS.remove(ws)

# ─────────────────────────────────────────────
# ADMIN SETTINGS
# ─────────────────────────────────────────────

SETTINGS_FILE = BASE_DIR / "data" / "settings.json"

DEFAULT_SETTINGS = {
    "palette": "cyberpunk",
    "mqtt_host": "localhost",
    "mqtt_port": 1883,
    "sim_interval": 3,
    "zoom_default": 1,
}

def load_settings():
    if SETTINGS_FILE.exists():
        try:
            return json.loads(SETTINGS_FILE.read_text())
        except Exception:
            pass
    return dict(DEFAULT_SETTINGS)

def save_settings(settings):
    SETTINGS_FILE.write_text(json.dumps(settings, indent=2))

SETTINGS = load_settings()

PALETTES = {
    "cyberpunk": {
        "bg": "#050d1a", "bg2": "#0a1628", "bg3": "#0f1f3d",
        "panel": "#091428", "border": "#1a3a6b", "border2": "#2a5aa0",
        "accent": "#00d4ff", "accent2": "#0080ff",
        "green": "#00ff88", "amber": "#ffaa00", "red": "#ff3344",
        "gray": "#556688", "text": "#c8d8f0", "text2": "#7090b0",
    },
    "neon": {
        "bg": "#0a0015", "bg2": "#120022", "bg3": "#1f0038",
        "panel": "#0f001f", "border": "#3a006b", "border2": "#5a00a0",
        "accent": "#ff00ff", "accent2": "#cc00ff",
        "green": "#00ff88", "amber": "#ffaa00", "red": "#ff3344",
        "gray": "#664488", "text": "#e0c8f0", "text2": "#9070b0",
    },
    "nature": {
        "bg": "#0a1a0a", "bg2": "#0f220f", "bg3": "#1a3a1a",
        "panel": "#0d1f0d", "border": "#2a5a2a", "border2": "#3a8a3a",
        "accent": "#44ff88", "accent2": "#22cc66",
        "green": "#00ff88", "amber": "#ffaa00", "red": "#ff3344",
        "gray": "#557755", "text": "#c8e0c8", "text2": "#70a070",
    },
    "ocean": {
        "bg": "#001520", "bg2": "#002030", "bg3": "#003550",
        "panel": "#001a28", "border": "#004466", "border2": "#0077aa",
        "accent": "#00ddff", "accent2": "#0099cc",
        "green": "#00ff88", "amber": "#ffaa00", "red": "#ff3344",
        "gray": "#336688", "text": "#c0ddee", "text2": "#6090b0",
    },
    "sunset": {
        "bg": "#1a0a05", "bg2": "#2a1008", "bg3": "#3a1a0f",
        "panel": "#220d06", "border": "#5a2a1a", "border2": "#8a4a2a",
        "accent": "#ff8844", "accent2": "#ff6633",
        "green": "#44cc66", "amber": "#ffaa00", "red": "#ff3344",
        "gray": "#886655", "text": "#f0d8c0", "text2": "#b09070",
    },
}

@app.get("/api/admin/settings")
async def get_settings():
    return SETTINGS

@app.put("/api/admin/settings")
async def update_settings(data: dict):
    SETTINGS.update(data)
    save_settings(SETTINGS)
    await broadcast({"type": "settings_update", "settings": SETTINGS, "palettes": PALETTES})
    return SETTINGS

@app.get("/api/admin/palettes")
async def get_palettes():
    custom = SETTINGS.get("custom_palettes", {})
    merged = dict(PALETTES)
    merged.update(custom)
    return merged

PALETTE_KEYS = ["bg", "bg2", "bg3", "panel", "border", "border2", "accent", "accent2", "green", "amber", "red", "gray", "text", "text2"]

@app.post("/api/admin/palettes")
async def save_palette(data: dict):
    name = data.get("name", "").strip().lower().replace(" ", "-")
    colors = data.get("colors", {})
    if not name or len(name) < 2:
        return {"error": "Nombre muy corto"}, 400
    if not all(k in PALETTE_KEYS for k in colors):
        return {"error": "Faltan colores"}, 400
    custom = SETTINGS.setdefault("custom_palettes", {})
    custom[name] = colors
    save_settings(SETTINGS)
    merged = dict(PALETTES)
    merged.update(custom)
    await broadcast({"type": "settings_update", "settings": SETTINGS, "palettes": merged})
    return {"status": "saved", "name": name}

@app.delete("/api/admin/palettes/{name}")
async def delete_palette(name: str):
    custom = SETTINGS.get("custom_palettes", {})
    if name in custom:
        del custom[name]
        save_settings(SETTINGS)
    merged = dict(PALETTES)
    merged.update(custom)
    if SETTINGS.get("palette") == name:
        SETTINGS["palette"] = "cyberpunk"
        save_settings(SETTINGS)
    await broadcast({"type": "settings_update", "settings": SETTINGS, "palettes": merged})
    return {"status": "deleted", "name": name}

@app.post("/api/admin/reset")
async def admin_reset(pattern: str = "random", seed: int | None = None):
    """Reinicia la ciudad con un patrón procedural.

    Args:
        pattern: ring, grid, linear, star, spiral, random, double_ring, cluster
        seed: Semilla opcional para reproducir una misma ciudad
    """
    global DEVICES
    new_devices = generate_demo_city(pattern, seed)
    DEVICES.clear()
    DEVICES.update(new_devices)
    save_devices(DEVICES)
    entry = log_event("system_reset", "ADMIN", f"Patrón: {pattern}, seed: {_CURRENT_SEED}")
    await broadcast({"type": "system_reset", "devices": DEVICES, "log": entry})
    return {
        "status": "reset",
        "count": len(DEVICES),
        "pattern": _CURRENT_PATTERN,
        "seed": _CURRENT_SEED,
    }

@app.get("/api/admin/patterns")
async def get_patterns():
    """Lista los patrones de ciudad disponibles."""
    return {
        "patterns": list_patterns(),
        "current": {
            "pattern": _CURRENT_PATTERN,
            "seed": _CURRENT_SEED,
        }
    }

@app.post("/api/admin/regenerate")
async def admin_regenerate():
    """Regenera la misma ciudad (mismo patrón y semilla) para probar reproducibilidad."""
    global DEVICES
    new_devices = generate_demo_city(_CURRENT_PATTERN, _CURRENT_SEED)
    DEVICES.clear()
    DEVICES.update(new_devices)
    save_devices(DEVICES)
    entry = log_event("system_regenerate", "ADMIN", f"Patrón: {_CURRENT_PATTERN}, seed: {_CURRENT_SEED}")
    await broadcast({"type": "system_reset", "devices": DEVICES, "log": entry})
    return {
        "status": "regenerated",
        "count": len(DEVICES),
        "pattern": _CURRENT_PATTERN,
        "seed": _CURRENT_SEED,
    }

@app.get("/api/admin/export")
async def admin_export():
    return {"devices": DEVICES, "settings": SETTINGS, "exported_at": datetime.now().isoformat()}

@app.post("/api/admin/broadcast")
async def admin_broadcast(data: dict):
    msg_type = data.get("type", "admin_notification")
    payload = data.get("payload", {})
    await broadcast({"type": msg_type, **payload})
    return {"sent": True}

# ─────────────────────────────────────────────
# STARTUP
# ─────────────────────────────────────────────

@app.on_event("startup")
async def startup():
    setup_mqtt()
    asyncio.create_task(simulate_network())

    # ── Integración Dashboard de Energía ──
    try:
        import sys as _sys
        _sys.path.insert(0, str(BASE_DIR))
        from backend.dashboard_patch import apply_patch
        _bg_tasks = []
        if apply_patch(app, DEVICES, _bg_tasks):
            for task_fn in _bg_tasks:
                asyncio.create_task(task_fn())
    except Exception as _e:
        print(f"⚠️  Dashboard patch: {_e}")

    print("🚀 IoT City Backend en http://localhost:5062")
    print(f"📡 Dispositivos: {len(DEVICES)}")
    print("📊 Dashboard:    http://localhost:5062/dashboard")
    print("📚 API Docs:     http://localhost:5062/api/docs")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=5062, reload=True)
