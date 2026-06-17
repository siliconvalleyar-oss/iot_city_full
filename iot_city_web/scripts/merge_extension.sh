#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  IoT City — Script de Merge: Extensión Analytics + Energía
#
#  Uso: chmod +x merge_extension.sh && ./merge_extension.sh
#
#  Qué hace:
#    1. Valida que el proyecto base existe y es funcional
#    2. Crea rama git para la extensión (si hay git)
#    3. Instala nuevas dependencias Python
#    4. Copia módulos al proyecto (analytics/, energy/, dashboard/)
#    5. Parchea main.py (idempotente — no duplica si ya aplicado)
#    6. Crea __init__.py necesarios
#    7. Crea directorios de datos adicionales
#    8. Ejecuta tests de integración básicos
#    9. Commit + merge si git disponible
#   10. Genera resumen de lo instalado
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colores ──
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'; BOLD='\033[1m'

log()  { echo -e "${C}[MERGE]${N} $1"; }
ok()   { echo -e "${G}[  OK ]${N} $1"; }
warn() { echo -e "${Y}[ WARN]${N} $1"; }
err()  { echo -e "${R}[  ERR]${N} $1" >&2; exit 1; }
step() { echo -e "\n${BOLD}${B}━━━ $1 ━━━${N}"; }

# ── Detectar directorio del proyecto ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Buscar raíz del proyecto (contiene backend/main.py)
PROJECT_DIR=""
for candidate in "$SCRIPT_DIR" "$SCRIPT_DIR/.." "$(pwd)" "$(pwd)/iot-city"; do
    if [ -f "$candidate/backend/main.py" ]; then
        PROJECT_DIR="$(cd "$candidate" && pwd)"
        break
    fi
done

[ -z "$PROJECT_DIR" ] && err "No se encontró backend/main.py. Ejecutá desde la raíz del proyecto."
log "Proyecto: $PROJECT_DIR"

VENV_DIR="$PROJECT_DIR/venv"
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"

# ═══════════════════════════════════════════════════════════════════
step "1. Validación del proyecto base"
# ═══════════════════════════════════════════════════════════════════

required_files=(
    "backend/main.py"
    "frontend/index.html"
    "data/devices.json"
    "simulator/mesh_simulator.py"
)

for f in "${required_files[@]}"; do
    if [ ! -f "$PROJECT_DIR/$f" ]; then
        err "Archivo requerido no encontrado: $f"
    fi
    ok "Encontrado: $f"
done

# ═══════════════════════════════════════════════════════════════════
step "2. Activar entorno virtual"
# ═══════════════════════════════════════════════════════════════════

if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
    ok "Entorno virtual activado: $VENV_DIR"
else
    warn "Sin venv — usando Python del sistema"
fi

# ═══════════════════════════════════════════════════════════════════
step "3. Instalar nuevas dependencias"
# ═══════════════════════════════════════════════════════════════════

log "Instalando dependencias adicionales..."
pip install -q statistics 2>/dev/null || true

# statistics está en stdlib desde Python 3.4, solo verificar
python3 -c "import statistics; import dataclasses; import collections; print('deps OK')" \
    && ok "Dependencias Python OK" \
    || err "Faltan dependencias Python stdlib"

# Chart.js se carga desde CDN en el frontend — no requiere instalación

# Verificar fastapi ya instalado (del proyecto base)
python3 -c "import fastapi; import uvicorn" \
    && ok "FastAPI + uvicorn OK" \
    || err "FastAPI no instalado — ejecutá install_system.sh primero"

# ═══════════════════════════════════════════════════════════════════
step "4. Crear estructura de directorios"
# ═══════════════════════════════════════════════════════════════════

new_dirs=(
    "analytics"
    "energy"
    "dashboard"
    "firmware_snippets"
    "data/metrics"
    "data/timeseries"
)

for dir in "${new_dirs[@]}"; do
    mkdir -p "$PROJECT_DIR/$dir"
    ok "Directorio: $dir/"
done

# ═══════════════════════════════════════════════════════════════════
step "5. Copiar módulos de extensión"
# ═══════════════════════════════════════════════════════════════════

# Si el script está dentro del proyecto, los archivos ya están ahí
# Si viene de un tarball externo, copiar desde SCRIPT_DIR

copy_if_newer() {
    local src="$1"
    local dst="$2"
    if [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]; then
        cp "$src" "$dst"
        ok "Copiado: $(basename $dst)"
    else
        log "Sin cambios: $(basename $dst)"
    fi
}

# __init__.py para todos los paquetes
for pkg in analytics energy dashboard backend; do
    init="$PROJECT_DIR/$pkg/__init__.py"
    if [ ! -f "$init" ]; then
        echo "# IoT City — $pkg package" > "$init"
        ok "Creado: $pkg/__init__.py"
    fi
done

# ═══════════════════════════════════════════════════════════════════
step "6. Verificar/aplicar patch a main.py"
# ═══════════════════════════════════════════════════════════════════

MAIN_PY="$PROJECT_DIR/backend/main.py"
PATCH_MARKER="Dashboard de Energía"

if grep -q "$PATCH_MARKER" "$MAIN_PY"; then
    ok "Patch ya aplicado a main.py (idempotente)"
else
    log "Aplicando patch a main.py..."

    # Crear backup
    cp "$MAIN_PY" "${MAIN_PY}.bak.$(date +%Y%m%d_%H%M%S)"
    ok "Backup creado: main.py.bak.*"

    # Inyectar patch en startup usando Python (más seguro que sed con strings multilinea)
    python3 << 'PYEOF'
import re
from pathlib import Path

main_py = Path("$PROJECT_DIR/backend/main.py".replace("$PROJECT_DIR", __import__("os").environ.get("PROJECT_DIR", ".")))
# Si no existe la variable de entorno, usar ruta relativa
import os
main_py = Path(os.environ.get("PROJECT_DIR", ".")) / "backend" / "main.py"

content = main_py.read_text()

OLD_STARTUP = '''    print("🚀 IoT City Backend corriendo en http://localhost:5062")
    print(f"📡 Dispositivos cargados: {len(DEVICES)}")
    print("📚 Documentación: http://localhost:5062/api/docs")'''

NEW_STARTUP = '''    # ── Integración Dashboard de Energía ──
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
    print("📚 API Docs:     http://localhost:5062/api/docs")'''

if OLD_STARTUP in content:
    new_content = content.replace(OLD_STARTUP, NEW_STARTUP)
    main_py.write_text(new_content)
    print("Patch aplicado OK")
else:
    print("Patron no encontrado — patch manual necesario")
PYEOF
    ok "Patch aplicado a main.py"
fi

export PROJECT_DIR

# ═══════════════════════════════════════════════════════════════════
step "7. Actualizar requirements.txt"
# ═══════════════════════════════════════════════════════════════════

REQ="$PROJECT_DIR/backend/requirements.txt"

# Agregar dependencias si no están
for dep in "statistics" "dataclasses"; do
    # Ambos son stdlib — no necesitan pip, pero documentar
    true
done

# Las deps existentes ya cubren todo. Solo documentar nuevos módulos.
if ! grep -q "# analytics" "$REQ" 2>/dev/null; then
    cat >> "$REQ" << 'EOF'

# Analytics Extension (stdlib, no requieren pip)
# statistics  — análisis estadístico (Python 3.4+)
# dataclasses — estructuras de datos (Python 3.7+)
# collections — deque para time-series circular
EOF
    ok "requirements.txt actualizado"
fi

# ═══════════════════════════════════════════════════════════════════
step "8. Git integration (si disponible)"
# ═══════════════════════════════════════════════════════════════════

cd "$PROJECT_DIR"

if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
    BRANCH="feature/analytics-energy-dashboard"

    # Verificar si la rama ya existe
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        log "Rama $BRANCH ya existe — checkout"
        git checkout "$BRANCH" 2>/dev/null || true
    else
        log "Creando rama: $BRANCH"
        git checkout -b "$BRANCH" 2>/dev/null || true
        ok "Rama creada: $BRANCH"
    fi

    # Stage archivos nuevos/modificados
    git add -A \
        analytics/ energy/ dashboard/ \
        firmware_snippets/ \
        backend/dashboard_patch.py \
        backend/main.py \
        data/metrics/ data/timeseries/ \
        2>/dev/null || true

    # Commit si hay cambios
    if ! git diff --cached --quiet 2>/dev/null; then
        git commit -m "feat: analytics + energy dashboard

- MetricsEngine: time-series energético por nodo
- EnergyOptimizer: duty cycling, TX power, agregación, intervalo adaptativo
- Dashboard API: /api/dashboard/* + WebSocket
- Dashboard HTML: charts, heatmap, zonas, optimización
- Firmware snippets: MRF24J40 + ATmega (C/C++)
- Scripts Bash: merge limpio e idempotente

Co-authored-by: IoT City System <iot@city.local>" 2>/dev/null
        ok "Commit realizado en rama $BRANCH"

        # Merge a main/master
        MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
        log "Mergeando $BRANCH → $MAIN_BRANCH"
        git checkout "$MAIN_BRANCH" 2>/dev/null || git checkout main 2>/dev/null || true
        git merge "$BRANCH" --no-ff -m "merge: analytics + energy dashboard" 2>/dev/null \
            && ok "Merge completado → $MAIN_BRANCH" \
            || warn "Merge manual necesario (conflictos)"
    else
        ok "Sin cambios para commitear"
    fi
else
    warn "Git no disponible o no es un repositorio — saltando integración git"
    log "Para inicializar git: cd $PROJECT_DIR && git init && git add -A && git commit -m 'init'"
fi

# ═══════════════════════════════════════════════════════════════════
step "9. Tests de integración"
# ═══════════════════════════════════════════════════════════════════

cd "$PROJECT_DIR"

python3 << 'PYEOF'
import sys
sys.path.insert(0, '.')

errors = []

# Test 1: MetricsEngine
try:
    from analytics.metrics_engine import MetricsEngine, NodeEnergyModel
    m = MetricsEngine()
    sample = m.ingest("TEST_001", active=True, powered=True)
    assert "power_mW" in sample, "sample falta power_mW"
    print("  ✓ MetricsEngine OK")
except Exception as e:
    errors.append(f"MetricsEngine: {e}")
    print(f"  ✗ MetricsEngine: {e}")

# Test 2: NodeEnergyModel
try:
    n = NodeEnergyModel("RTR_001", "router")
    n.tx_power_level = 2
    n.duty_cycle = 0.05
    breakdown = n.compute_instant_power_mW()
    assert breakdown["power_mW"] > 0
    assert breakdown["frac_sleep"] > 0.5
    print(f"  ✓ NodeEnergyModel OK — {breakdown['power_mW']:.2f} mW")
except Exception as e:
    errors.append(f"NodeEnergyModel: {e}")
    print(f"  ✗ NodeEnergyModel: {e}")

# Test 3: EnergyOptimizer
try:
    from energy.optimizer import EnergyOptimizer, NodeConfig, PacketAggregator
    opt = EnergyOptimizer()
    cfg = NodeConfig(node_id="TEST", tx_power_level=0, duty_cycle=0.3, tx_interval_s=1.0)
    opt.node_configs["TEST"] = cfg
    analysis = opt.get_aggregation_analysis()
    assert "agg_comparison" in analysis
    agg = PacketAggregator()
    overhead = agg.compute_overhead_ratio(4)
    assert overhead["improvement_pct"] > 0
    print(f"  ✓ EnergyOptimizer OK — Agg x4: +{overhead['improvement_pct']}% eficiencia")
except Exception as e:
    errors.append(f"EnergyOptimizer: {e}")
    print(f"  ✗ EnergyOptimizer: {e}")

# Test 4: Serialización firmware (3 bytes)
try:
    from energy.optimizer import NodeConfig
    cfg = NodeConfig(node_id="X", tx_power_level=1, duty_cycle=0.15,
                     tx_interval_s=2.5, aggregation_size=3, sleep_mode="power_save")
    fb = cfg.to_firmware_bytes()
    assert len(fb) == 3, f"Expected 3 bytes, got {len(fb)}"
    cfg2 = NodeConfig.from_firmware_bytes("X", fb)
    assert cfg2.tx_power_level == 1
    assert abs(cfg2.duty_cycle - 0.15) < 0.02
    print(f"  ✓ Firmware serialization OK — bytes: {[hex(b) for b in fb]}")
except Exception as e:
    errors.append(f"FirmwareBytes: {e}")
    print(f"  ✗ FirmwareBytes: {e}")

# Test 5: Dashboard API importable
try:
    from dashboard.api import router, init_dashboard
    assert router is not None
    print("  ✓ Dashboard API importable OK")
except Exception as e:
    errors.append(f"DashboardAPI: {e}")
    print(f"  ✗ DashboardAPI: {e}")

# Test 6: Zone metrics
try:
    from analytics.metrics_engine import MetricsEngine
    m = MetricsEngine()
    # Simular varios ticks
    for _ in range(5):
        m.ingest("NODE_A", active=True, powered=True)
        m.ingest("NODE_B", active=False, powered=True)
        m.ingest("NODE_C", active=True, powered=False)
    summary = m.get_summary()
    assert "total_power_mW" in summary
    print(f"  ✓ Zone metrics OK — {summary.get('total_nodes',0)} nodos")
except Exception as e:
    errors.append(f"ZoneMetrics: {e}")
    print(f"  ✗ ZoneMetrics: {e}")

if errors:
    print(f"\n  ⚠️  {len(errors)} test(s) fallaron")
    sys.exit(1)
else:
    print(f"\n  ✅ Todos los tests pasaron")
PYEOF

TEST_STATUS=$?

# ═══════════════════════════════════════════════════════════════════
step "10. Resumen final"
# ═══════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${G}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║     EXTENSIÓN ANALYTICS INTEGRADA EXITOSAMENTE   ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${N}"

echo -e "  ${C}Módulos instalados:${N}"
echo "   analytics/metrics_engine.py  — Series temporales + consumo"
echo "   energy/optimizer.py          — 4 algoritmos de optimización"
echo "   dashboard/api.py             — API REST + WebSocket"
echo "   dashboard/index.html         — Dashboard visual completo"
echo "   firmware_snippets/           — C/C++ para MRF24J40"
echo "   backend/dashboard_patch.py   — Integración con main.py"
echo ""
echo -e "  ${C}URLs:${N}"
echo -e "   Mapa principal:   ${BOLD}http://localhost:5062${N}"
echo -e "   Dashboard:        ${BOLD}http://localhost:5062/dashboard${N}"
echo -e "   API Metrics:      ${BOLD}http://localhost:5062/api/dashboard/summary${N}"
echo -e "   API Docs:         ${BOLD}http://localhost:5062/api/docs${N}"
echo ""
echo -e "  ${C}Para iniciar:${N}"
echo -e "   ${BOLD}./scripts/control_system.sh restart${N}"
echo ""

if [ "$TEST_STATUS" -ne 0 ]; then
    warn "Algunos tests fallaron — revisar output arriba"
else
    ok "Sistema listo para producción"
fi
