#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Script: clean_reinstall.sh
# Descripción: Limpia completamente el proyecto (cachés, logs, venv) y reinstala
# Uso: chmod +x clean_reinstall.sh && sudo ./clean_reinstall.sh
# ──────────────────────────────────────────────────────────────────────────

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
log() { echo -e "${CYAN}[CLEAN]${NC} $1"; }
ok() { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

log "Limpiando proyecto en: $PROJECT_ROOT"

# ──────────────────────────────────────────────────────────────────────────
# 1. Eliminar cachés de Python
# ──────────────────────────────────────────────────────────────────────────
log "Eliminando __pycache__ y archivos .pyc..."
find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$PROJECT_ROOT" -type f -name "*.pyc" -delete 2>/dev/null || true
ok "Cachés de Python eliminados"

# ──────────────────────────────────────────────────────────────────────────
# 2. Limpiar logs
# ──────────────────────────────────────────────────────────────────────────
log "Limpiando logs..."
rm -rf "$PROJECT_ROOT/logs/"*.log 2>/dev/null || true
rm -rf "$PROJECT_ROOT/logs/"*.pid 2>/dev/null || true
ok "Logs limpiados"

# ──────────────────────────────────────────────────────────────────────────
# 3. Limpiar métricas antiguas (opcional, comenta si quieres conservar)
# ──────────────────────────────────────────────────────────────────────────
read -p "¿Eliminar métricas antiguas (datos históricos)? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    rm -rf "$PROJECT_ROOT/data/metrics/"*.json 2>/dev/null || true
    ok "Métricas eliminadas"
else
    warn "Métricas conservadas"
fi

# ──────────────────────────────────────────────────────────────────────────
# 4. Eliminar entorno virtual
# ──────────────────────────────────────────────────────────────────────────
log "Eliminando entorno virtual venv..."
rm -rf "$PROJECT_ROOT/venv"
ok "Entorno virtual eliminado"

# ──────────────────────────────────────────────────────────────────────────
# 5. Recrear entorno virtual e instalar dependencias
# ──────────────────────────────────────────────────────────────────────────
log "Recreando entorno virtual..."
python3 -m venv "$PROJECT_ROOT/venv"
source "$PROJECT_ROOT/venv/bin/activate"

log "Actualizando pip..."
python -m pip install --upgrade pip

log "Instalando dependencias desde requirements.txt..."
if [ -f "$PROJECT_ROOT/backend/requirements.txt" ]; then
    python -m pip install -r "$PROJECT_ROOT/backend/requirements.txt"
else
    python -m pip install fastapi uvicorn paho-mqtt pydantic python-multipart websockets
fi

# Verificar instalación
if python -c "import paho.mqtt.client" 2>/dev/null; then
    ok "paho-mqtt instalado correctamente"
else
    warn "paho-mqtt no se instaló correctamente"
fi

# ──────────────────────────────────────────────────────────────────────────
# 6. Recrear archivo devices.json (opcional, datos demo frescos)
# ──────────────────────────────────────────────────────────────────────────
read -p "¿Reiniciar base de datos de dispositivos (perderás datos personalizados)? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    rm -f "$PROJECT_ROOT/data/devices.json"
    ok "Base de datos de dispositivos reiniciada (se generará demo al iniciar)"
else
    warn "Base de datos conservada"
fi

# ──────────────────────────────────────────────────────────────────────────
# 7. Asegurar permisos de ejecución para scripts
# ──────────────────────────────────────────────────────────────────────────
log "Ajustando permisos de scripts..."
chmod +x "$PROJECT_ROOT/scripts/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_ROOT/fix_iot_paho_error.sh" 2>/dev/null || true
ok "Permisos ajustados"

# ──────────────────────────────────────────────────────────────────────────
# 8. Mensaje final
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Limpieza y reinstalación completada.${NC}"
echo ""
echo -e "  Para iniciar el sistema:"
echo -e "  ${CYAN}./scripts/control_system.sh start${NC}"
echo ""
echo -e "  Para asegurar que la partición tiene permisos de ejecución:"
echo -e "  ${CYAN}sudo mount -o remount,exec /media/optimus/FILES${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

