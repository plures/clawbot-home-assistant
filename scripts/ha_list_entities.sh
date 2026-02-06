#!/usr/bin/env bash
# Home Assistant List Entities Script
# Lists all entities and their current states

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
Usage: $0 [OPTIONS]

List all entities and their current states from Home Assistant.

OPTIONS:
    -u, --url URL       Home Assistant URL (default: \$HA_URL or http://homeassistant.local:8123)
    -t, --token TOKEN   Home Assistant long-lived access token (default: \$HA_TOKEN)
    -d, --domain DOMAIN Filter by domain (e.g., light, switch, sensor)
    -f, --format FORMAT Output format: json, table, compact (default: table)
    -h, --help          Show this help message

ENVIRONMENT VARIABLES:
    HA_URL              Home Assistant URL
    HA_TOKEN            Home Assistant long-lived access token

EXAMPLES:
    # List all entities
    $0

    # List only lights
    $0 --domain light

    # List all sensors in JSON format
    $0 -d sensor -f json

    # List all entities in compact format
    $0 -f compact

SECURITY:
    - Store tokens in environment variables or secure credential storage
    - Never commit tokens to version control
    - See docs/SECURITY.md for more information

EOF
    exit 0
}

# Default values
DOMAIN=""
FORMAT="table"

# Parse arguments
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
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            usage
            ;;
    esac
done

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

# Function to make API calls
api_call() {
    local endpoint="$1"
    local url="${HA_URL}${endpoint}"
    
    curl -s -f -X GET \
        -H "Authorization: Bearer ${HA_TOKEN}" \
        -H "Content-Type: application/json" \
        "$url" || return 1
}

echo -e "${YELLOW}=== Home Assistant Entities ===${NC}"
echo "URL: $HA_URL"
if [[ -n "$DOMAIN" ]]; then
    echo "Domain filter: $DOMAIN"
fi
echo ""

# Get states
STATES=$(api_call "/api/states")

if [[ $? -ne 0 ]]; then
    echo -e "${RED}✗ Failed to retrieve states${NC}" >&2
    exit 1
fi

# Apply domain filter if specified
if [[ -n "$DOMAIN" ]]; then
    STATES=$(echo "$STATES" | jq --arg domain "$DOMAIN" '[.[] | select(.entity_id | startswith($domain + "."))]')
fi

# Output based on format
case "$FORMAT" in
    json)
        echo "$STATES" | jq '.'
        ;;
    compact)
        echo "$STATES" | jq -r '.[] | "\(.entity_id): \(.state)"' | sort
        ;;
    table)
        echo -e "${GREEN}Entity ID${NC}\t\t\t\t${GREEN}State${NC}\t${GREEN}Last Changed${NC}"
        echo "────────────────────────────────────────────────────────────────────────"
        echo "$STATES" | jq -r '.[] | "\(.entity_id)\t\(.state)\t\(.last_changed)"' | sort | column -t -s $'\t'
        ;;
    *)
        echo -e "${RED}Error: Invalid format '$FORMAT'. Use json, table, or compact${NC}" >&2
        exit 1
        ;;
esac

# Show summary
echo ""
TOTAL=$(echo "$STATES" | jq 'length')
echo -e "${GREEN}Total entities: $TOTAL${NC}"

# Show breakdown by domain
echo ""
echo -e "${YELLOW}Breakdown by domain:${NC}"
echo "$STATES" | jq -r '.[].entity_id' | cut -d'.' -f1 | sort | uniq -c | sort -rn
