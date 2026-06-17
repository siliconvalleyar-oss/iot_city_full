#!/usr/bin/env python3
"""
IoT City — Patch del Backend Principal
Integra el Dashboard API al main.py existente.

Este archivo extiende main.py:
  - Monta el router /api/dashboard
  - Inicia el tick de métricas en background
  - Agrega endpoint /dashboard para el HTML
  - Mantiene compatibilidad 100% con el sistema existente
"""

import asyncio
import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BASE_DIR))

# ── Patch sobre main.py existente ──
# Este módulo se importa desde main.py con:
#   from backend.dashboard_patch import apply_patch
#   apply_patch(app, DEVICES)

def apply_patch(app, devices_ref: dict, background_tasks_ref: list):
    """
    Aplica el patch al app FastAPI existente.

    Params:
        app              — instancia FastAPI de main.py
        devices_ref      — dict global de dispositivos (se pasa por referencia)
        background_tasks — lista de corrutinas a iniciar en startup
    """
    from fastapi.responses import FileResponse
    from fastapi.staticfiles import StaticFiles

    # ── Importar módulos de dashboard ──
    try:
        from dashboard.api import router as dashboard_router, init_dashboard, dashboard_tick
        from analytics.metrics_engine import MetricsEngine
        from energy.optimizer import EnergyOptimizer
    except ImportError as e:
        print(f"⚠️  Dashboard no disponible: {e}")
        return False

    # ── Montar router ──
    app.include_router(dashboard_router)
    print("✅ Dashboard API montada en /api/dashboard")

    # ── Servir HTML del dashboard ──
    dashboard_html = BASE_DIR / "dashboard" / "index.html"

    @app.get("/dashboard")
    async def serve_dashboard():
        if dashboard_html.exists():
            return FileResponse(str(dashboard_html))
        return {"error": "Dashboard HTML no encontrado"}

    # ── Inicializar motor de métricas ──
    metrics, optimizer = init_dashboard(devices_ref)
    print(f"📊 Motor de métricas inicializado: {len(metrics.nodes)} nodos")

    # ── Task de actualización continua ──
    async def metrics_loop():
        """Loop que actualiza métricas cada 2 segundos."""
        while True:
            await asyncio.sleep(2)
            try:
                await dashboard_tick(devices_ref)
            except Exception as ex:
                print(f"⚠️  Error en metrics_loop: {ex}")

    background_tasks_ref.append(metrics_loop)
    return True
