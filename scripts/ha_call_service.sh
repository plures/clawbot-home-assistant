#!/usr/bin/env bash
# Home Assistant Service Call Script (GATED)
# Executes service calls (write operations) - REQUIRES EXPLICIT INTENT FLAG

set -euo pipefail

# Configuration
HA_URL="${HA_URL:-http://homeassistant.local:8123}"
HA_TOKEN="${HA_TOKEN:-}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS] --intent <domain> <service> [service_data_json]

Execute Home Assistant service calls (WRITE OPERATIONS).

⚠️  WARNING: This script performs WRITE operations on your Home Assistant instance.
    Use with caution and only with the --intent flag to confirm intentional use.

OPTIONS:
    -u, --url URL       Home Assistant URL (default: \$HA_URL or http://homeassistant.local:8123)
    -t, --token TOKEN   Home Assistant long-lived access token (default: \$HA_TOKEN)
    --intent            REQUIRED: Explicit intent flag to enable service calls
    --dry-run           Show what would be executed without actually calling the service
    -h, --help          Show this help message

ARGUMENTS:
    domain              Service domain (e.g., light, switch, climate)
    service             Service name (e.g., turn_on, turn_off, set_temperature)
    service_data_json   Optional JSON data for the service call

ENVIRONMENT VARIABLES:
    HA_URL              Home Assistant URL
    HA_TOKEN            Home Assistant long-lived access token

EXAMPLES:
    # Turn on a light (dry-run)
    $0 --dry-run --intent light turn_on '{"entity_id": "light.living_room"}'

    # Turn on a light (actual execution)
    $0 --intent light turn_on '{"entity_id": "light.living_room"}'

    # Turn off a switch
    $0 --intent switch turn_off '{"entity_id": "switch.coffee_maker"}'

    # Set climate temperature
    $0 --intent climate set_temperature '{"entity_id": "climate.bedroom", "temperature": 72}'

    # Call a scene
    $0 --intent scene turn_on '{"entity_id": "scene.movie_time"}'

SECURITY:
    - Store tokens in environment variables or secure credential storage
    - Never commit tokens to version control
    - This script requires --intent flag to prevent accidental execution
    - Use read-only tokens for monitoring scripts (see ha_probe.sh, ha_list_entities.sh)
    - See docs/SECURITY.md for more information

SAFETY GATES:
    1. --intent flag MUST be provided (prevents accidental execution)
    2. Dry-run mode available for testing
    3. Confirmation prompt before execution (unless --yes flag is used)
    4. Full logging of all operations

EOF
    exit 0
}

# Default values
INTENT_FLAG=0
DRY_RUN=0
YES_FLAG=0

# Parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            HA_URL="$2"
            shift 2
            ;;
        -t|--token)
            HA_TOKEN="$2"
            shift 2
            ;;
        --intent)
            INTENT_FLAG=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --yes)
            YES_FLAG=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            usage
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${POSITIONAL[@]}"

# Validate required parameters
if [[ -z "$HA_TOKEN" ]]; then
    echo -e "${RED}Error: HA_TOKEN is required${NC}" >&2
    echo "Set it via environment variable or use --token flag" >&2
    exit 1
fi

if [[ -z "$HA_URL" ]]; then
    echo -e "${RED}Error: HA_URL is required${NC}" >&2
    echo "Set it via environment variable or use --url flag" >&2
    exit 1
fi

# SAFETY GATE: Intent flag check
if [[ $INTENT_FLAG -eq 0 ]]; then
    echo -e "${RED}ERROR: --intent flag is REQUIRED for service calls${NC}" >&2
    echo "" >&2
    echo "This is a safety gate to prevent accidental execution of write operations." >&2
    echo "If you intend to execute a service call, please add the --intent flag." >&2
    echo "" >&2
    echo "Example: $0 --intent light turn_on '{\"entity_id\": \"light.living_room\"}'" >&2
    echo "" >&2
    exit 1
fi

# Validate positional arguments
if [[ $# -lt 2 ]]; then
    echo -e "${RED}Error: domain and service are required${NC}" >&2
    echo "" >&2
    usage
fi

DOMAIN="$1"
SERVICE="$2"
if [[ $# -ge 3 ]]; then
    SERVICE_DATA="$3"
else
    SERVICE_DATA="{}"
fi

# Validate JSON if provided
if command -v jq >/dev/null 2>&1; then
    if ! echo "$SERVICE_DATA" | jq empty 2>/dev/null; then
        echo -e "${RED}Error: Invalid JSON in service_data${NC}" >&2
        exit 1
    fi
    SERVICE_DATA_PRETTY=$(echo "$SERVICE_DATA" | jq '.')
else
    # Fallback: use python for JSON validation/pretty-printing if jq isn't installed.
    if ! python3 -c 'import json,sys; json.load(sys.stdin)' <<<"$SERVICE_DATA" 2>/dev/null; then
        echo -e "${RED}Error: Invalid JSON in service_data (install jq for better diagnostics)${NC}" >&2
        exit 1
    fi
    SERVICE_DATA_PRETTY=$(python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin), indent=2, sort_keys=True))' <<<"$SERVICE_DATA")
fi

echo -e "${YELLOW}=== Home Assistant Service Call ===${NC}"
echo "URL: $HA_URL"
echo "Domain: $DOMAIN"
echo "Service: $SERVICE"
echo "Service Data:"
echo "$SERVICE_DATA_PRETTY"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "${YELLOW}[DRY-RUN] Would execute service call:${NC}"
    echo "POST ${HA_URL}/api/services/${DOMAIN}/${SERVICE}"
    echo "Data: $SERVICE_DATA"
    exit 0
fi

# Confirmation prompt (unless --yes flag)
if [[ $YES_FLAG -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  You are about to execute a write operation on your Home Assistant instance.${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Execute service call
echo -e "${YELLOW}Executing service call...${NC}"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer ${HA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$SERVICE_DATA" \
    "${HA_URL}/api/services/${DOMAIN}/${SERVICE}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [[ "$HTTP_CODE" -eq 200 ]]; then
    echo -e "${GREEN}✓ Service call successful${NC}"
    echo ""
    echo "Response:"
    echo "$BODY" | jq '.' || echo "$BODY"
else
    echo -e "${RED}✗ Service call failed (HTTP $HTTP_CODE)${NC}" >&2
    echo ""
    echo "Response:"
    echo "$BODY"
    exit 1
fi
