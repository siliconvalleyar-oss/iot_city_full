#!/usr/bin/env python3
"""
IoT City — API de Dashboard y Analytics
Extiende el backend principal con endpoints de métricas energéticas,
series temporales, optimización y heatmaps.

Se monta en el mismo FastAPI como router en /api/dashboard
"""

import asyncio
import json
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# Agregar ruta padre para importar módulos del proyecto
BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BASE_DIR))

from analytics.metrics_engine import MetricsEngine, WINDOW_SHORT, WINDOW_MEDIUM, WINDOW_LONG
from energy.optimizer import EnergyOptimizer, NodeConfig

# ─────────────────────────────────────────────────────────────────
# ROUTER FASTAPI
# ─────────────────────────────────────────────────────────────────

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

# Instancias (se comparten con main.py vía import)
metrics: Optional[MetricsEngine] = None
optimizer: Optional[EnergyOptimizer] = None
_dashboard_ws: List[WebSocket] = []


def init_dashboard(devices: Dict):
    """Inicializa motor de métricas y optimizador con los dispositivos actuales."""
    global metrics, optimizer

    metrics = MetricsEngine()
    optimizer = EnergyOptimizer()
    optimizer.init_nodes(devices)

    return metrics, optimizer


async def dashboard_tick(devices: Dict):
    """
    Loop de actualización del dashboard (llamar desde main.py cada 2s).
    Actualiza métricas + optimizaciones + difunde a WebSockets.
    """
    global metrics, optimizer

    if not metrics:
        init_dashboard(devices)

    # Tick de métricas
    global_snap = metrics.tick_all(devices)

    # Ciclo de optimización (cada 10 ticks)
    opt_result = None
    if int(time.time()) % 10 == 0:
        opt_result = optimizer.run_optimization_cycle(devices)

    # Persistir snapshot periódicamente (cada 60s)
    if int(time.time()) % 60 == 0:
        metrics.persist_snapshot()

    # Difundir a WebSockets del dashboard
    if _dashboard_ws:
        msg = {
            "type": "dashboard_tick",
            "global": global_snap,
            "zones": metrics.get_zone_metrics(),
            "summary": metrics.get_summary(),
        }
        if opt_result:
            msg["optimization"] = opt_result

        dead = []
        for ws in _dashboard_ws:
            try:
                await ws.send_json(msg)
            except Exception:
                dead.append(ws)
        for ws in dead:
            _dashboard_ws.remove(ws)


# ─────────────────────────────────────────────────────────────────
# ENDPOINTS
# ─────────────────────────────────────────────────────────────────

@router.get("/summary")
async def get_summary():
    """Resumen global del sistema energético."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    return metrics.get_summary()


@router.get("/zones")
async def get_zones():
    """Métricas agregadas por zona geográfica."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    return {"zones": metrics.get_zone_metrics()}


@router.get("/heatmap")
async def get_heatmap():
    """Datos para heatmap de consumo en el mapa."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    return {"heatmap": metrics.get_heatmap_data()}


@router.get("/timeseries/global")
async def get_global_timeseries(last_n: int = 300):
    """Serie temporal de potencia total de la red."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    return {"timeseries": metrics.get_global_timeseries(last_n)}


@router.get("/timeseries/{node_id}")
async def get_node_timeseries(node_id: str, last_n: int = 300):
    """Serie temporal de un nodo específico."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    data = metrics.get_node_timeseries(node_id, last_n)
    if not data:
        raise HTTPException(404, f"Nodo {node_id} sin datos")
    return {"node_id": node_id, "timeseries": data}


@router.get("/node/{node_id}")
async def get_node_detail(node_id: str):
    """Detalle completo de métricas de un nodo."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    detail = metrics.get_node_detail(node_id)
    if not detail:
        raise HTTPException(404, f"Nodo {node_id} no encontrado")
    return detail


@router.get("/traffic")
async def get_traffic():
    """Tráfico de datos por nodo."""
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    return {"traffic": metrics.get_network_traffic()}


# ── Optimización ──

@router.get("/optimization/recommendations")
async def get_recommendations():
    """Lista de recomendaciones de optimización priorizadas."""
    if not optimizer or not metrics:
        raise HTTPException(503, "Optimizador no inicializado")

    data_file = BASE_DIR / "data" / "devices.json"
    devices = json.loads(data_file.read_text()) if data_file.exists() else {}
    recs = optimizer.get_recommendations(devices)
    return {"recommendations": recs, "count": len(recs)}


@router.post("/optimization/apply/{node_id}/{strategy}")
async def apply_optimization(node_id: str, strategy: str):
    """
    Aplica una estrategia de optimización a un nodo.

    Estrategias disponibles:
    - duty_cycle_reduce
    - tx_power_reduce
    - interval_increase
    - aggregation_enable
    - full_optimize
    - reset_defaults
    """
    if not metrics:
        raise HTTPException(503, "Motor de métricas no inicializado")
    result = metrics.apply_optimization(node_id, strategy)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result


@router.post("/optimization/apply_all")
async def apply_all_recommendations():
    """Aplica la optimización más impactante a todos los nodos con problemas."""
    if not optimizer or not metrics:
        raise HTTPException(503, "Optimizador no inicializado")

    data_file = BASE_DIR / "data" / "devices.json"
    devices = json.loads(data_file.read_text()) if data_file.exists() else {}
    recs = optimizer.get_recommendations(devices)

    applied = []
    for rec in recs:
        nid = rec["node_id"]
        # Aplicar la acción más impactante
        best_issue = max(rec["issues"], key=lambda i: i["saving_est_pct"])
        result = metrics.apply_optimization(nid, best_issue["action"])
        applied.append(result)

    total_saving = sum(r.get("saving_mW", 0) for r in applied)
    return {
        "applied": len(applied),
        "results": applied,
        "total_saving_mW": round(total_saving, 2),
        "total_saving_W": round(total_saving / 1000, 4),
    }


@router.get("/optimization/history")
async def get_optimization_history(last_n: int = 50):
    """Historial de ciclos de optimización."""
    if not optimizer:
        raise HTTPException(503, "Optimizador no inicializado")
    return {"history": optimizer.get_optimization_history(last_n)}


@router.get("/optimization/aggregation-analysis")
async def get_aggregation_analysis():
    """Análisis comparativo de estrategias de agregación de paquetes."""
    if not optimizer:
        raise HTTPException(503, "Optimizador no inicializado")
    return optimizer.get_aggregation_analysis()


@router.get("/node/{node_id}/config")
async def get_node_config(node_id: str):
    """Configuración actual de optimización de un nodo."""
    if not optimizer:
        raise HTTPException(503, "Optimizador no inicializado")
    cfg = optimizer.node_configs.get(node_id)
    if not cfg:
        raise HTTPException(404, f"Nodo {node_id} sin configuración")
    from dataclasses import asdict
    return {"node_id": node_id, "config": asdict(cfg),
            "firmware_bytes": list(cfg.to_firmware_bytes())}


class NodeConfigUpdate(BaseModel):
    tx_power_level: Optional[int] = None
    duty_cycle: Optional[float] = None
    tx_interval_s: Optional[float] = None
    aggregation_size: Optional[int] = None
    sleep_mode: Optional[str] = None


@router.patch("/node/{node_id}/config")
async def update_node_config(node_id: str, update: NodeConfigUpdate):
    """Actualiza configuración de optimización de un nodo manualmente."""
    if not optimizer:
        raise HTTPException(503, "Optimizador no inicializado")

    if node_id not in optimizer.node_configs:
        optimizer.node_configs[node_id] = NodeConfig(node_id=node_id)

    cfg = optimizer.node_configs[node_id]
    changes = update.dict(exclude_none=True)

    for key, val in changes.items():
        setattr(cfg, key, val)

    from dataclasses import asdict
    return {
        "node_id": node_id,
        "config": asdict(cfg),
        "firmware_bytes": list(cfg.to_firmware_bytes()),
        "applied": changes,
    }


# ── WebSocket del dashboard ──

@router.websocket("/ws")
async def dashboard_websocket(ws: WebSocket):
    """WebSocket para actualizaciones en tiempo real del dashboard."""
    await ws.accept()
    _dashboard_ws.append(ws)

    try:
        # Enviar estado inicial
        if metrics:
            await ws.send_json({
                "type": "init",
                "summary": metrics.get_summary(),
                "zones": metrics.get_zone_metrics(),
                "timeseries": metrics.get_global_timeseries(60),
            })

        while True:
            data = await ws.receive_json()
            if data.get("type") == "ping":
                await ws.send_json({"type": "pong", "ts": time.time()})

    except WebSocketDisconnect:
        _dashboard_ws.remove(ws)
