#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  IoT City — Instalador de Extensión Analytics + Energía
#  Uso: ./install_analytics.sh [--project-dir /ruta/al/proyecto]
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'
R='\033[0;31m'; N='\033[0m'; BOLD='\033[1m'
log()  { echo -e "${C}[ANA]${N} $1"; }
ok()   { echo -e "${G}[ ✓ ]${N} $1"; }
warn() { echo -e "${Y}[ ! ]${N} $1"; }
err()  { echo -e "${R}[ ✗ ]${N} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(dirname "$SCRIPT_DIR")}"

# Detectar proyecto
[ -f "$PROJECT_DIR/backend/main.py" ] || err "Proyecto no encontrado en: $PROJECT_DIR"
log "Proyecto: $PROJECT_DIR"

# Activar venv si existe
[ -d "$PROJECT_DIR/venv" ] && source "$PROJECT_DIR/venv/bin/activate"

echo ""
echo -e "${BOLD}${C}━━━ IoT City Analytics Extension Installer ━━━${N}"
echo ""

# 1. Verificar Python 3.7+
PY_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
PY_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
[ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 7 ] \
    && ok "Python ${PY_MAJOR}.${PY_MINOR} OK" \
    || err "Python 3.7+ requerido"

# 2. Verificar stdlib disponible
python3 -c "import statistics, dataclasses, collections, math, pathlib" \
    && ok "Stdlib Python OK" \
    || err "Stdlib Python incompleta"

# 3. Verificar FastAPI
python3 -c "import fastapi" && ok "FastAPI OK" \
    || err "FastAPI no instalado — ejecutá install_system.sh"

# 4. Crear directorios
for dir in analytics energy dashboard firmware_snippets data/metrics data/timeseries; do
    mkdir -p "$PROJECT_DIR/$dir"
done
ok "Directorios creados"

# 5. __init__.py
for pkg in analytics energy dashboard backend; do
    f="$PROJECT_DIR/$pkg/__init__.py"
    [ -f "$f" ] || echo "# IoT City — $pkg" > "$f"
done
ok "__init__.py creados"

# 6. Verificar archivos de extensión
REQUIRED_EXT=(
    "analytics/metrics_engine.py"
    "energy/optimizer.py"
    "dashboard/api.py"
    "dashboard/index.html"
    "backend/dashboard_patch.py"
)

missing=0
for f in "${REQUIRED_EXT[@]}"; do
    if [ ! -f "$PROJECT_DIR/$f" ]; then
        warn "Falta: $f"
        missing=$((missing + 1))
    else
        ok "OK: $f"
    fi
done

[ "$missing" -gt 0 ] && warn "$missing archivos de extensión faltan — descargalos del paquete"

# 7. Tests rápidos
cd "$PROJECT_DIR"
log "Ejecutando tests..."
python3 -c "
import sys; sys.path.insert(0, '.')
from analytics.metrics_engine import MetricsEngine, NodeEnergyModel
from energy.optimizer import EnergyOptimizer, NodeConfig, PacketAggregator
m = MetricsEngine()
s = m.ingest('T1', active=True, powered=True)
assert s['power_mW'] >= 0
n = NodeEnergyModel('T1')
b = n.compute_instant_power_mW()
assert b['power_mW'] > 0
cfg = NodeConfig(node_id='T1')
fb = cfg.to_firmware_bytes()
assert len(fb) == 3
agg = PacketAggregator()
r = agg.compute_overhead_ratio(4)
assert r['improvement_pct'] > 0
print('PASS')
" && ok "Tests pasados" || warn "Tests con errores — ver output"

echo ""
echo -e "${BOLD}${G}✓ Instalación completada${N}"
echo ""
echo "  Reiniciar sistema: ./scripts/control_system.sh restart"
echo "  Dashboard:         http://localhost:5062/dashboard"
echo ""
