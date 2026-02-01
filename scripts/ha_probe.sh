#!/usr/bin/env bash
# Home Assistant Probe Script
# Tests connectivity and retrieves basic configuration and version info

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

Probe Home Assistant instance for connectivity, version, and config info.

OPTIONS:
    -u, --url URL       Home Assistant URL (default: \$HA_URL or http://homeassistant.local:8123)
    -t, --token TOKEN   Home Assistant long-lived access token (default: \$HA_TOKEN)
    -h, --help          Show this help message

ENVIRONMENT VARIABLES:
    HA_URL              Home Assistant URL
    HA_TOKEN            Home Assistant long-lived access token

EXAMPLES:
    # Using environment variables
    export HA_URL="http://192.168.1.100:8123"
    export HA_TOKEN="your-long-lived-token"
    $0

    # Using command line arguments
    $0 -u http://192.168.1.100:8123 -t your-long-lived-token

SECURITY:
    - Store tokens in environment variables or secure credential storage
    - Never commit tokens to version control
    - Use read-only tokens when possible
    - See docs/SECURITY.md for more information

EOF
    exit 0
}

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

echo -e "${YELLOW}=== Home Assistant Probe ===${NC}"
echo "URL: $HA_URL"
echo ""

# Function to make API calls
api_call() {
    local endpoint="$1"
    local url="${HA_URL}${endpoint}"
    
    curl -s -f -X GET \
        -H "Authorization: Bearer ${HA_TOKEN}" \
        -H "Content-Type: application/json" \
        "$url" || return 1
}

# Test connectivity
echo -e "${YELLOW}Testing connectivity...${NC}"
if api_call "/api/" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection successful${NC}"
else
    echo -e "${RED}✗ Connection failed${NC}" >&2
    echo "Please check your HA_URL and HA_TOKEN" >&2
    exit 1
fi
echo ""

# Get API status
echo -e "${YELLOW}API Status:${NC}"
api_call "/api/" | jq '.' || echo "Failed to parse API response"
echo ""

# Get config
echo -e "${YELLOW}Configuration:${NC}"
api_call "/api/config" | jq '{
    location_name: .location_name,
    latitude: .latitude,
    longitude: .longitude,
    elevation: .elevation,
    unit_system: .unit_system,
    time_zone: .time_zone,
    version: .version,
    components: .components | length
}' || echo "Failed to parse config response"
echo ""

# Get full version info
echo -e "${YELLOW}Version Information:${NC}"
api_call "/api/config" | jq '{
    version: .version,
    config_dir: .config_dir,
    safe_mode: .safe_mode
}' || echo "Failed to parse version response"
echo ""

echo -e "${GREEN}=== Probe Complete ===${NC}"
