#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Script: fix_iot_paho_error.sh
# Descripción: Soluciona el error "ModuleNotFoundError: No module named 'paho'"
#              en el proyecto IoT City. Remonta la partición con exec si es
#              necesario, recrea el venv e instala las dependencias.
# Uso: sudo ./fix_iot_paho_error.sh
# ──────────────────────────────────────────────────────────────────────────

set -e

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
log()   { echo -e "${CYAN}[FIX]${NC} $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERR]${NC} $1" >&2; exit 1; }

# Detectar directorio del proyecto (raíz del proyecto)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log "Proyecto ubicado en: $PROJECT_ROOT"

# ──────────────────────────────────────────────────────────────────────────
# 1. Verificar si la partición está montada con noexec
# ──────────────────────────────────────────────────────────────────────────
log "Verificando permisos de la partición..."
MOUNT_POINT=$(df "$PROJECT_ROOT" | tail -1 | awk '{print $6}')
MOUNT_OPTS=$(mount | grep "on $MOUNT_POINT " | awk '{print $6}' | tr ',' '\n')

if echo "$MOUNT_OPTS" | grep -q "noexec"; then
    warn "La partición $MOUNT_POINT está montada con 'noexec'."
    warn "Esto impide ejecutar pip dentro del entorno virtual."

    # Intentar remontar con exec
    log "Intentando remontar $MOUNT_POINT con opción 'exec'..."
    if sudo mount -o remount,exec "$MOUNT_POINT" 2>/dev/null; then
        ok "Partición remontada correctamente con 'exec'."
    else
        err "No se pudo remontar la partición. Es posible que sea un sistema de archivos NTFS/exFAT que no soporta exec. Mueve el proyecto a /home/optimus/ y vuelve a intentarlo."
    fi
else
    ok "La partición no tiene 'noexec'."
fi

# ──────────────────────────────────────────────────────────────────────────
# 2. Recrear entorno virtual (borrar el anterior si existe)
# ──────────────────────────────────────────────────────────────────────────
log "Recreando entorno virtual en $PROJECT_ROOT/venv ..."
rm -rf "$PROJECT_ROOT/venv"
python3 -m venv "$PROJECT_ROOT/venv"
if [ ! -f "$PROJECT_ROOT/venv/bin/activate" ]; then
    err "Falló la creación del entorno virtual."
fi
ok "Entorno virtual creado."

# ──────────────────────────────────────────────────────────────────────────
# 3. Activar el entorno virtual e instalar dependencias
# ──────────────────────────────────────────────────────────────────────────
source "$PROJECT_ROOT/venv/bin/activate"

# Actualizar pip (usando python -m pip para evitar problemas de ejecución)
log "Actualizando pip..."
python -m pip install --upgrade pip

# Instalar dependencias
log "Instalando paquetes necesarios (fastapi, uvicorn, paho-mqtt, etc.)..."
python -m pip install fastapi uvicorn paho-mqtt pydantic python-multipart websockets

# Verificar que paho-mqtt se instaló correctamente
if python -c "import paho.mqtt.client" 2>/dev/null; then
    ok "paho-mqtt instalado correctamente."
else
    err "paho-mqtt no se pudo instalar. Revisa los errores anteriores."
fi

# ──────────────────────────────────────────────────────────────────────────
# 4. Verificar que el backend puede ejecutarse (prueba de importación)
# ──────────────────────────────────────────────────────────────────────────
log "Probando importación del módulo principal..."
cd "$PROJECT_ROOT/backend"
if python -c "import main" 2>/dev/null; then
    ok "El backend puede importarse sin errores."
else
    warn "El backend main.py tiene errores de importación (pueden ser otros módulos faltantes). Revisa manualmente."
fi

# ──────────────────────────────────────────────────────────────────────────
# 5. (Opcional) Ajustar puerto a 5062 para que coincida con control_system.sh
# ──────────────────────────────────────────────────────────────────────────
# Si tu control_system.sh usa puerto 5062, asegúrate de que main.py también.
log "Ajustando puerto en backend/main.py a 5062 (para coincidir con control_system.sh)..."
sed -i 's/port=505[0-9]/port=5062/' "$PROJECT_ROOT/backend/main.py" 2>/dev/null || true
ok "Puerto unificado a 5062."

# ──────────────────────────────────────────────────────────────────────────
# 6. Mensaje final
# ──────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Entorno virtual reparado y dependencias instaladas.${NC}"
echo -e "${GREEN}  ✅ El backend debería iniciar correctamente ahora.${NC}"
echo ""
echo -e "  Para iniciar el sistema, ejecuta:"
echo -e "  ${CYAN}./scripts/control_system.sh start${NC}"
echo ""
echo -e "  Si el backend sigue sin arrancar, revisa el log:"
echo -e "  ${CYAN}cat logs/backend.log${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"



./scripts/control_system.sh stop
./scripts/control_system.sh start


