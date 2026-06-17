#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  IoT City — Agregar Dispositivo desde CLI
#  Uso: ./add_device.sh ID X Y TIPO CALLE
#
#  Ejemplo:
#    ./add_device.sh LAMP_001 120 300 router "Av. Mitre"
#    ./add_device.sh SENSOR_05 400 200 end_device "Calle Belgrano"
# ═══════════════════════════════════════════════════════════════

PORT=5062

set -e

# ── Colores ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

log()  { echo -e "${CYAN}[IOT]${NC} $1"; }
ok()   { echo -e "${GREEN}[ ✓ ]${NC} $1"; }
err()  { echo -e "${RED}[ ✗ ]${NC} $1" >&2; exit 1; }
warn() { echo -e "${YELLOW}[ ! ]${NC} $1"; }

# ── Constantes ──
API_BASE="http://localhost:${PORT}/api"

# ── Ayuda ──
usage() {
    echo -e "${BOLD}Uso:${NC} $0 ID X Y TIPO CALLE [ICON] [COLOR]"
    echo ""
    echo -e "${BOLD}Parámetros:${NC}"
    echo "  ID      — Identificador único (ej: LAMP_001)"
    echo "  X       — Coordenada X en el mapa (0-800)"
    echo "  Y       — Coordenada Y en el mapa (0-600)"
    echo "  TIPO    — router | end_device"
    echo "  CALLE   — Nombre de la calle (entre comillas si tiene espacios)"
    echo "  ICON    — lamp | traffic | sensor | camera | gateway | sign  (opcional)"
    echo "  COLOR   — Color hex ej: #FFD700  (opcional)"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo "  $0 LAMP_001 120 300 router \"Av. Mitre\""
    echo "  $0 SENSOR_02 400 200 end_device \"Calle Belgrano\" sensor #00BFFF"
    echo "  $0 TRF_001 550 350 router \"Av. Corrientes\" traffic #FF6600"
    echo ""
    echo -e "${BOLD}Batch (múltiples):${NC}"
    echo "  $0 --batch archivo.csv"
    echo ""
    echo -e "${BOLD}Listar:${NC}"
    echo "  $0 --list"
    echo ""
    echo -e "${BOLD}Eliminar:${NC}"
    echo "  $0 --delete DEVICE_ID"
}

# ─────────────────────────────────────────────
check_api() {
    if ! curl -s --connect-timeout 3 "$API_BASE/metrics" >/dev/null 2>&1; then
        err "No se puede conectar a $API_BASE\n   Asegurate de que el backend esté corriendo:\n   ./control_system.sh start"
    fi
}

# ─────────────────────────────────────────────
add_device() {
    local ID="$1"
    local X="$2"
    local Y="$3"
    local TIPO="$4"
    local CALLE="$5"
    local ICON="${6:-lamp}"
    local COLOR="${7:-#FFD700}"

    # Validaciones
    [ -z "$ID" ]    && err "ID requerido"
    [ -z "$X" ]     && err "Coordenada X requerida"
    [ -z "$Y" ]     && err "Coordenada Y requerida"
    [ -z "$TIPO" ]  && err "Tipo requerido (router|end_device)"
    [ -z "$CALLE" ] && err "Calle requerida"

    # Validar tipo
    if [[ "$TIPO" != "router" && "$TIPO" != "end_device" ]]; then
        err "Tipo inválido: '$TIPO'. Debe ser 'router' o 'end_device'"
    fi

    # Validar coordenadas
    if ! [[ "$X" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        err "X debe ser un número: '$X'"
    fi
    if ! [[ "$Y" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        err "Y debe ser un número: '$Y'"
    fi

    # Validar ícono
    local VALID_ICONS="lamp traffic sensor camera gateway sign"
    if ! echo "$VALID_ICONS" | grep -qw "$ICON"; then
        warn "Ícono '$ICON' no reconocido — usando 'lamp'"
        ICON="lamp"
    fi

    check_api

    log "Agregando dispositivo..."
    echo ""
    echo -e "  ID:     ${BOLD}$ID${NC}"
    echo -e "  Tipo:   $TIPO"
    echo -e "  Pos:    X=$X, Y=$Y"
    echo -e "  Calle:  $CALLE"
    echo -e "  Ícono:  $ICON"
    echo -e "  Color:  $COLOR"
    echo ""

    # Payload JSON
    local PAYLOAD
    PAYLOAD=$(cat <<EOF
{
  "id": "$ID",
  "x": $X,
  "y": $Y,
  "street": "$CALLE",
  "device_type": "$TIPO",
  "icon": "$ICON",
  "color": "$COLOR"
}
EOF
)

    # POST a la API
    local RESPONSE
    local HTTP_CODE

    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        "$API_BASE/devices" 2>&1)

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -n -1)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        ok "Dispositivo $ID agregado exitosamente"
        echo ""
        echo "  Respuesta del servidor:"
        echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
        echo ""
        echo -e "  Ver en: ${BOLD}http://localhost:${PORT}${NC}"
    elif [ "$HTTP_CODE" = "409" ]; then
        err "El dispositivo '$ID' ya existe. Usá un ID diferente."
    else
        err "Error HTTP $HTTP_CODE al agregar dispositivo:\n$BODY"
    fi
}

# ─────────────────────────────────────────────
list_devices() {
    check_api
    log "Listando dispositivos..."
    echo ""

    local RESPONSE
    RESPONSE=$(curl -s "$API_BASE/devices")

    if command -v python3 &>/dev/null; then
        echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
devices = data.get('devices', [])
print(f'  Total: {len(devices)} dispositivos\n')
print(f'  {\"ID\":<20} {\"Tipo\":<12} {\"X\":>5} {\"Y\":>5}  {\"Estado\":<12}  Calle')
print('  ' + '-'*80)
for d in sorted(devices, key=lambda x: x['id']):
    estado = 'ACTIVO' if d.get('active') and d.get('powered') else ('SIN TENSIÓN' if not d.get('powered') else 'APAGADO')
    print(f'  {d[\"id\"]:<20} {d[\"device_type\"]:<12} {int(d[\"x\"]):>5} {int(d[\"y\"]):>5}  {estado:<12}  {d[\"street\"]}')
"
    else
        echo "$RESPONSE"
    fi
}

# ─────────────────────────────────────────────
delete_device() {
    local ID="$1"
    [ -z "$ID" ] && err "ID requerido para eliminar"

    check_api

    read -r -p "¿Eliminar $ID? [s/N] " confirm
    [[ "$confirm" =~ ^[sS]$ ]] || { log "Cancelado"; exit 0; }

    local HTTP_CODE
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X DELETE "$API_BASE/devices/$ID")

    if [ "$HTTP_CODE" = "200" ]; then
        ok "Dispositivo $ID eliminado"
    elif [ "$HTTP_CODE" = "404" ]; then
        err "Dispositivo '$ID' no encontrado"
    else
        err "Error HTTP $HTTP_CODE"
    fi
}

# ─────────────────────────────────────────────
batch_add() {
    local FILE="$1"
    [ -z "$FILE" ] && err "Archivo CSV requerido"
    [ ! -f "$FILE" ] && err "Archivo no encontrado: $FILE"

    log "Cargando dispositivos desde $FILE..."
    echo ""

    local SUCCESS=0
    local FAIL=0
    local LINE_NUM=0

    while IFS=',' read -r ID X Y TIPO CALLE ICON COLOR || [ -n "$ID" ]; do
        LINE_NUM=$((LINE_NUM + 1))

        # Saltar línea de encabezado y líneas vacías
        [[ "$ID" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$ID" ]] && continue
        [[ "$ID" == "ID" || "$ID" == "id" ]] && continue

        # Limpiar espacios
        ID=$(echo "$ID" | tr -d ' ')
        X=$(echo "$X" | tr -d ' ')
        Y=$(echo "$Y" | tr -d ' ')
        TIPO=$(echo "$TIPO" | tr -d ' ')
        CALLE=$(echo "$CALLE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        ICON=$(echo "${ICON:-lamp}" | tr -d ' ')
        COLOR=$(echo "${COLOR:-#FFD700}" | tr -d ' ')

        echo -n "  [L$LINE_NUM] $ID... "

        if curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"id\":\"$ID\",\"x\":$X,\"y\":$Y,\"street\":\"$CALLE\",\"device_type\":\"$TIPO\",\"icon\":\"$ICON\",\"color\":\"$COLOR\"}" \
            "$API_BASE/devices" >/dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            FAIL=$((FAIL + 1))
        fi

    done < "$FILE"

    echo ""
    ok "Batch completado: $SUCCESS OK, $FAIL errores"
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────

case "${1:-}" in
    --help|-h)
        usage
        ;;
    --list|-l)
        list_devices
        ;;
    --delete|-d)
        delete_device "$2"
        ;;
    --batch|-b)
        batch_add "$2"
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        # Modo normal: add_device ID X Y TIPO CALLE [ICON] [COLOR]
        if [ $# -lt 5 ]; then
            err "Parámetros insuficientes\n\nUso: $0 ID X Y TIPO CALLE [ICON] [COLOR]\n\nEjemplo:\n  $0 LAMP_001 120 300 router \"Av. Mitre\""
        fi
        add_device "$1" "$2" "$3" "$4" "$5" "${6:-lamp}" "${7:-#FFD700}"
        ;;
esac
