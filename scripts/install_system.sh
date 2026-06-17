#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  IoT City Platform — Script de Instalación Completa
#  Uso: chmod +x install_system.sh && ./install_system.sh
# ═══════════════════════════════════════════════════════════════

set -e

# ── Colores ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ── Helpers ──
log()     { echo -e "${CYAN}[IOT]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERR]${NC}  $1" >&2; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}"; }

# ── Variables ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"
SIMULATOR_DIR="$PROJECT_DIR/simulator"
DATA_DIR="$PROJECT_DIR/data"
ASSETS_DIR="$PROJECT_DIR/assets/icons"
LOG_DIR="$PROJECT_DIR/logs"
VENV_DIR="$PROJECT_DIR/venv"
PORT=5062                      # Puerto configurable para el servidor web/API

# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║    IOT CITY — INSTALADOR v1.0        ║"
echo "  ║    Red Inteligente Zigbee + MQTT      ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"
# ─────────────────────────────────────────────

section "1. Verificando sistema"

# OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    log "Sistema: $NAME $VERSION_ID"
else
    warn "No se pudo detectar el OS"
fi

# Arquitectura
ARCH=$(uname -m)
log "Arquitectura: $ARCH"

# Root check
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    warn "Se recomienda ejecutar como root o con sudo para instalar paquetes del sistema"
fi

# ─────────────────────────────────────────────
section "2. Actualizando paquetes"

if command -v apt-get &>/dev/null; then
    log "Actualizando apt..."
    sudo apt-get update -qq || warn "No se pudo actualizar apt"
    
    log "Instalando dependencias del sistema..."
    sudo apt-get install -y -qq \
        python3 python3-pip python3-venv python3-dev \
        g++ gcc build-essential \
        curl wget git \
        mosquitto mosquitto-clients \
        libssl-dev \
        net-tools lsof \
        2>/dev/null || warn "Algunos paquetes no pudieron instalarse"
    ok "Paquetes del sistema instalados"

elif command -v yum &>/dev/null; then
    sudo yum install -y python3 python3-pip gcc-c++ mosquitto curl wget
    ok "Paquetes instalados (yum)"
    
elif command -v brew &>/dev/null; then
    brew install python3 mosquitto gcc curl
    ok "Paquetes instalados (homebrew)"
else
    warn "Gestor de paquetes no reconocido — instalando manualmente puede ser necesario"
fi

# ─────────────────────────────────────────────
section "3. Verificando versiones"

# Python
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1 | cut -d' ' -f2)
    ok "Python: $PY_VER"
else
    err "Python3 no encontrado. Instalalo con: sudo apt install python3"
fi

# g++
if command -v g++ &>/dev/null; then
    GPP_VER=$(g++ --version | head -1)
    ok "G++: $GPP_VER"
else
    warn "g++ no encontrado (el simulador C++ no estará disponible)"
fi

# mosquitto
if command -v mosquitto &>/dev/null; then
    MOSQ_VER=$(mosquitto -v 2>&1 | head -1 || echo "unknown")
    ok "Mosquitto: instalado"
else
    warn "Mosquitto no encontrado — MQTT no estará disponible"
fi

# ─────────────────────────────────────────────
section "4. Creando estructura del proyecto"

mkdir -p "$DATA_DIR"
mkdir -p "$ASSETS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKEND_DIR"
mkdir -p "$SIMULATOR_DIR"
mkdir -p "$PROJECT_DIR/frontend"
mkdir -p "$PROJECT_DIR/mqtt"

ok "Estructura creada en: $PROJECT_DIR"

# ─────────────────────────────────────────────
section "5. Entorno virtual Python"

if [ ! -d "$VENV_DIR" ]; then
    log "Creando entorno virtual..."
    python3 -m venv "$VENV_DIR"
    ok "Entorno virtual creado"
else
    ok "Entorno virtual ya existe"
fi

# Activar venv
source "$VENV_DIR/bin/activate"

# Actualizar pip
log "Actualizando pip..."
pip install --upgrade pip -q

# ─────────────────────────────────────────────
section "6. Instalando dependencias Python"

log "Instalando paquetes del backend..."
pip install -q \
    fastapi==0.111.0 \
    "uvicorn[standard]==0.30.0" \
    "paho-mqtt==1.6.1" \
    "pydantic==2.7.0" \
    python-multipart==0.0.9 \
    websockets==12.0

ok "Dependencias Python instaladas"

# ─────────────────────────────────────────────
section "7. Configurando Mosquitto MQTT"

MQTT_CONF="/etc/mosquitto/conf.d/iot-city.conf"

if command -v mosquitto &>/dev/null; then
    log "Configurando Mosquitto..."
    
    sudo tee "$MQTT_CONF" > /dev/null 2>/dev/null << 'EOF' || true
# IoT City - Mosquitto config
listener 1883
allow_anonymous true
log_type all
log_dest file /var/log/mosquitto/iot-city.log
max_connections 100
keepalive_interval 60
EOF

    # Crear directorio de logs
    sudo mkdir -p /var/log/mosquitto
    sudo chown mosquitto: /var/log/mosquitto 2>/dev/null || true

    # Iniciar/restart Mosquitto
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable mosquitto 2>/dev/null || true
        sudo systemctl restart mosquitto 2>/dev/null && ok "Mosquitto iniciado" || warn "No se pudo iniciar Mosquitto vía systemctl"
    else
        sudo mosquitto -c /etc/mosquitto/mosquitto.conf -d 2>/dev/null && ok "Mosquitto iniciado (daemon)" || warn "No se pudo iniciar Mosquitto"
    fi
else
    warn "Mosquitto no disponible — MQTT funcionará en modo offline"
fi

# ─────────────────────────────────────────────
section "8. Creando iconos de dispositivos"

# SVG icons
create_svg_icon() {
    local name="$1"
    local content="$2"
    echo "$content" > "$ASSETS_DIR/${name}.svg"
}

create_svg_icon "lamp" '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#FFD700"><circle cx="12" cy="9" r="5" fill="#FFD700"/><rect x="11" y="14" width="2" height="4" fill="#888"/><rect x="9" y="18" width="6" height="1.5" rx="0.5" fill="#666"/></svg>'

create_svg_icon "traffic" '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect x="7" y="2" width="10" height="20" rx="2" fill="#333"/><circle cx="12" cy="7" r="3" fill="#ff3344"/><circle cx="12" cy="12" r="3" fill="#ffaa00"/><circle cx="12" cy="17" r="3" fill="#00ff88"/></svg>'

create_svg_icon "sensor" '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#00d4ff" stroke-width="1.5"><circle cx="12" cy="12" r="3" fill="#00d4ff"/><path d="M8 8a6 6 0 0 0 0 8"/><path d="M16 8a6 6 0 0 1 0 8"/><path d="M5 5a10 10 0 0 0 0 14"/><path d="M19 5a10 10 0 0 1 0 14"/></svg>'

create_svg_icon "camera" '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#888"><rect x="2" y="7" width="16" height="12" rx="2"/><circle cx="10" cy="13" r="3" fill="#333"/><path d="M18 10l4-2v8l-4-2z" fill="#666"/></svg>'

create_svg_icon "gateway" '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect x="2" y="8" width="20" height="10" rx="2" fill="#1a3a6b" stroke="#0080ff" stroke-width="1"/><circle cx="6" cy="13" r="2" fill="#00ff88"/><rect x="10" y="11" width="8" height="2" rx="1" fill="#0080ff"/><rect x="10" y="15" width="5" height="2" rx="1" fill="#0080ff" opacity="0.5"/></svg>'

ok "Íconos SVG creados en $ASSETS_DIR"

# ─────────────────────────────────────────────
section "9. Archivo .env"

cat > "$PROJECT_DIR/.env" << EOF
# IoT City Configuration
PORT=${PORT}
HOST=0.0.0.0
MQTT_HOST=localhost
MQTT_PORT=1883
DEBUG=false
LOG_LEVEL=info
EOF

ok "Archivo .env creado"

# ─────────────────────────────────────────────
section "10. Verificación final"

log "Verificando instalación..."

# Python
python3 -c "import fastapi, uvicorn, paho.mqtt.client as mqtt; print('OK')" 2>/dev/null && \
    ok "Módulos Python: ✓" || warn "Algunos módulos Python faltan"

# Ports
if command -v lsof &>/dev/null; then
    if lsof -Pi :${PORT} -sTCP:LISTEN -t &>/dev/null; then
        warn "Puerto ${PORT} ya está en uso"
    else
        ok "Puerto ${PORT}: libre"
    fi
fi

# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║       INSTALACIÓN COMPLETADA         ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${CYAN}Para iniciar el sistema:${NC}"
echo -e "  ${BOLD}./scripts/control_system.sh start${NC}"
echo ""
echo -e "  ${CYAN}Acceder en:${NC}"
echo -e "  ${BOLD}http://localhost:${PORT}${NC}"
echo ""
echo -e "  ${CYAN}Documentación API:${NC}"
echo -e "  ${BOLD}http://localhost:${PORT}/api/docs${NC}"
echo ""
