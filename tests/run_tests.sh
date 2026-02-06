#!/usr/bin/env bash
# Test runner for Home Assistant OpenClaw skill

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================="
echo "Home Assistant Skill Test Runner"
echo "=================================="
echo ""

# Run all test scripts
TOTAL_TESTS=0
FAILED_TESTS=0

for test_script in "$SCRIPT_DIR"/test_*.sh; do
    if [ -f "$test_script" ]; then
        echo "Running: $(basename "$test_script")"
        echo "----------------------------------"
        if bash "$test_script"; then
            echo ""
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo -e "${RED}Test script failed: $(basename "$test_script")${NC}"
            echo ""
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    fi
done

# Summary
echo "=================================="
echo "Overall Test Summary"
echo "=================================="
echo "Test scripts run: $TOTAL_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All test scripts passed!${NC}"
    exit 0
else
    echo -e "${RED}Failed test scripts: $FAILED_TESTS${NC}"
    exit 1
fi
