#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  IoT City Platform — Control del Sistema
#  Uso: ./control_system.sh {start|stop|restart|status|logs}
# ═══════════════════════════════════════════════════════════════
PORT=5062 

set -e

# ── Variables ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"
SIMULATOR_DIR="$PROJECT_DIR/simulator"
LOG_DIR="$PROJECT_DIR/logs"
VENV_DIR="$PROJECT_DIR/venv"
PID_DIR="$PROJECT_DIR/logs"

BACKEND_PID="$PID_DIR/backend.pid"
SIMULATOR_PID="$PID_DIR/simulator.pid"

# ── Colores ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

log()  { echo -e "${CYAN}[IOT]${NC} $1"; }
ok()   { echo -e "${GREEN}[ ✓ ]${NC} $1"; }
err()  { echo -e "${RED}[ ✗ ]${NC} $1"; }
warn() { echo -e "${YELLOW}[ ! ]${NC} $1"; }

mkdir -p "$LOG_DIR"

# ─────────────────────────────────────────────
print_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "  ┌─────────────────────────────────────┐"
    echo "  │  IoT City — Control del Sistema     │"
    echo "  └─────────────────────────────────────┘"
    echo -e "${NC}"
}

# ─────────────────────────────────────────────
is_running() {
    local pidfile="$1"
    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

stop_service() {
    local name="$1"
    local pidfile="$2"

    if [ -f "$pidfile" ]; then
        local pid
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            log "Deteniendo $name (PID $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 1
            # Force kill si sigue corriendo
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null || true
            fi
            ok "$name detenido"
        else
            warn "$name no estaba corriendo"
        fi
        rm -f "$pidfile"
    else
        warn "No se encontró PID para $name"
    fi
}

start_mosquitto() {
    log "Verificando Mosquitto MQTT..."
    if command -v mosquitto &>/dev/null; then
        # Verificar si ya está corriendo
        if pgrep -x mosquitto >/dev/null 2>&1; then
            ok "Mosquitto ya está corriendo"
            return 0
        fi

        if command -v systemctl &>/dev/null; then
            sudo systemctl start mosquitto 2>/dev/null && ok "Mosquitto iniciado (systemd)" || {
                # Intentar manualmente
                mosquitto -d 2>/dev/null && ok "Mosquitto iniciado (daemon)" || warn "No se pudo iniciar Mosquitto"
            }
        else
            mosquitto -d 2>/dev/null && ok "Mosquitto iniciado" || warn "Mosquitto no disponible"
        fi
    else
        warn "Mosquitto no instalado — MQTT funcionará en modo simulado"
    fi
}

stop_mosquitto() {
    if command -v systemctl &>/dev/null; then
        sudo systemctl stop mosquitto 2>/dev/null || true
    fi
    pkill -x mosquitto 2>/dev/null || true
}

# ─────────────────────────────────────────────
start() {
    print_banner
    log "Iniciando IoT City Platform..."

    # Activar virtualenv
    if [ -d "$VENV_DIR" ]; then
        source "$VENV_DIR/bin/activate"
        ok "Entorno virtual activado"
    else
        warn "Entorno virtual no encontrado — creando uno automáticamente..."
        python3 -m venv "$VENV_DIR" 2>/dev/null || {
            err "No se pudo crear el entorno virtual. Ejecuta: ./install_system.sh"
            exit 1
        }
        source "$VENV_DIR/bin/activate"
        warn "Instalando dependencias (esto tomará un momento)..."
        python -m pip install --upgrade pip -q
        python -m pip install fastapi uvicorn paho-mqtt pydantic python-multipart websockets -q
        ok "Entorno virtual creado y dependencias instaladas"
    fi

    # 1. MQTT
    start_mosquitto
    sleep 1

    # 2. Backend
    if is_running "$BACKEND_PID"; then
        warn "Backend ya está corriendo (PID $(cat "$BACKEND_PID"))"
    else
        log "Iniciando Backend (puerto ${PORT})..."
        cd "$BACKEND_DIR"

        nohup python3 main.py \
            > "$LOG_DIR/backend.log" 2>&1 &
        echo $! > "$BACKEND_PID"
        sleep 2

        if is_running "$BACKEND_PID"; then
            ok "Backend iniciado (PID $(cat "$BACKEND_PID"))"
        else
            err "Backend no pudo iniciarse — ver $LOG_DIR/backend.log"
            cat "$LOG_DIR/backend.log" | tail -20
            exit 1
        fi
    fi

    # 3. Simulador
    if is_running "$SIMULATOR_PID"; then
        warn "Simulador ya está corriendo"
    else
        log "Iniciando Simulador Zigbee..."
        cd "$SIMULATOR_DIR"

        nohup python3 mesh_simulator.py \
            > "$LOG_DIR/simulator.log" 2>&1 &
        echo $! > "$SIMULATOR_PID"
        sleep 1

        if is_running "$SIMULATOR_PID"; then
            ok "Simulador iniciado (PID $(cat "$SIMULATOR_PID"))"
        else
            warn "Simulador no pudo iniciarse — ver $LOG_DIR/simulator.log"
        fi
    fi

    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Sistema IoT City corriendo!${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "  🌐 Frontend:  ${BOLD}http://localhost:${PORT}${NC}"
    echo -e "  📚 API Docs:  ${BOLD}http://localhost:${PORT}/api/docs${NC}"
    echo -e "  📡 MQTT:      ${BOLD}localhost:1883${NC}"
    echo ""
    echo -e "  Logs en: ${LOG_DIR}/"
    echo ""
}

# ─────────────────────────────────────────────
stop() {
    print_banner
    log "Deteniendo IoT City Platform..."

    stop_service "Simulador" "$SIMULATOR_PID"
    stop_service "Backend"   "$BACKEND_PID"

    # También matar por puerto si quedan procesos huerfanos
    if command -v lsof &>/dev/null; then
        PID_5062=$(lsof -ti:${PORT} 2>/dev/null || true)
        if [ -n "$PID_5062" ]; then
            log "Matando proceso en puerto ${PORT} (PID $PID_5062)..."
            kill "$PID_5062" 2>/dev/null || true
        fi
    fi

    echo ""
    ok "Sistema detenido"
    echo ""
}

# ─────────────────────────────────────────────
status() {
    print_banner
    echo "  Estado de servicios:"
    echo ""

    # Backend
    if is_running "$BACKEND_PID"; then
        echo -e "  Backend     ${GREEN}● CORRIENDO${NC}  (PID $(cat "$BACKEND_PID"))"
    else
        echo -e "  Backend     ${RED}● DETENIDO${NC}"
    fi

    # Simulador
    if is_running "$SIMULATOR_PID"; then
        echo -e "  Simulador   ${GREEN}● CORRIENDO${NC}  (PID $(cat "$SIMULATOR_PID"))"
    else
        echo -e "  Simulador   ${RED}● DETENIDO${NC}"
    fi

    # Mosquitto
    if pgrep -x mosquitto >/dev/null 2>&1; then
        echo -e "  MQTT        ${GREEN}● CORRIENDO${NC}"
    else
        echo -e "  MQTT        ${YELLOW}● NO DISPONIBLE${NC}"
    fi

    # Puerto
    echo ""
    if command -v lsof &>/dev/null && lsof -Pi :${PORT} -sTCP:LISTEN -t &>/dev/null; then
        echo -e "  Puerto ${PORT} ${GREEN}● ESCUCHANDO${NC}"
    else
        echo -e "  Puerto ${PORT} ${RED}● LIBRE (sistema no iniciado)${NC}"
    fi

    # Dispositivos
    if [ -f "$PROJECT_DIR/data/devices.json" ]; then
        NDEVS=$(python3 -c "import json; d=json.load(open('$PROJECT_DIR/data/devices.json')); print(len(d))" 2>/dev/null || echo "?")
        echo -e "  Dispositivos: ${BOLD}$NDEVS${NC} en base de datos"
    fi

    echo ""
}

# ─────────────────────────────────────────────
logs() {
    local service="${2:-backend}"
    local logfile="$LOG_DIR/${service}.log"
    if [ -f "$logfile" ]; then
        echo -e "${CYAN}── Log: $logfile ──${NC}"
        tail -f "$logfile"
    else
        err "Log no encontrado: $logfile"
        echo "  Disponibles: backend, simulator"
    fi
}

# ─────────────────────────────────────────────
case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; sleep 2; start ;;
    status)  status ;;
    logs)    logs "$@" ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs [backend|simulator]}"
        echo ""
        echo "  start    — Inicia todos los servicios"
        echo "  stop     — Detiene todos los servicios"
        echo "  restart  — Reinicia todo"
        echo "  status   — Muestra estado actual"
        echo "  logs     — Sigue logs en tiempo real"
        exit 1
        ;;
esac
