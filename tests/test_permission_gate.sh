#!/usr/bin/env bash
# Test suite for permission gating in ha_call_service.sh

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup
export HA_URL="http://test.local:8123"
export HA_TOKEN="test-token"
SCRIPT_PATH="$REPO_ROOT/scripts/ha_call_service.sh"
PROBE_SCRIPT="$REPO_ROOT/scripts/ha_probe.sh"
LIST_SCRIPT="$REPO_ROOT/scripts/ha_list_entities.sh"

echo "=================================="
echo "Permission Gate Test Suite"
echo "=================================="
echo ""

# Helper functions
pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

fail_test() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo "  Expected: $2"
    echo "  Got: $3"
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 1: Service call WITHOUT --intent flag should FAIL
echo "Test 1: Service call without --intent flag should be rejected"
run_test
OUTPUT=$($SCRIPT_PATH light turn_on 2>&1 || true)
if echo "$OUTPUT" | grep -q "ERROR: --intent flag is REQUIRED"; then
    pass_test "Service call rejected without --intent flag"
else
    fail_test "Service call rejected without --intent flag" \
        "ERROR: --intent flag is REQUIRED" \
        "$OUTPUT"
fi
echo ""

# Test 2: Service call WITH --intent flag should pass validation (dry-run)
echo "Test 2: Service call with --intent flag should pass validation in dry-run"
run_test
OUTPUT=$($SCRIPT_PATH --dry-run --intent light turn_on 2>&1 || true)
if echo "$OUTPUT" | grep -q "DRY-RUN"; then
    pass_test "Service call accepted with --intent flag in dry-run mode"
else
    fail_test "Service call accepted with --intent flag in dry-run mode" \
        "DRY-RUN" \
        "$OUTPUT"
fi
echo ""

# Test 3: Dry-run mode should NOT execute actual calls
echo "Test 3: Dry-run mode should show what would execute without executing"
run_test
OUTPUT=$($SCRIPT_PATH --dry-run --intent light turn_on '{"entity_id": "light.test"}' 2>&1 || true)
if echo "$OUTPUT" | grep -q "Would execute service call" && \
   echo "$OUTPUT" | grep -q "POST.*light/turn_on"; then
    pass_test "Dry-run mode shows execution plan without executing"
else
    fail_test "Dry-run mode shows execution plan" \
        "Would execute service call & POST" \
        "$OUTPUT"
fi
echo ""

# Test 4: Missing HA_TOKEN should fail before permission check
echo "Test 4: Missing HA_TOKEN should fail with clear error"
run_test
unset HA_TOKEN
OUTPUT=$($SCRIPT_PATH --dry-run --intent light turn_on 2>&1 || true)
export HA_TOKEN="test-token"
if echo "$OUTPUT" | grep -q "HA_TOKEN is required"; then
    pass_test "Missing HA_TOKEN fails with clear error"
else
    fail_test "Missing HA_TOKEN fails with clear error" \
        "HA_TOKEN is required" \
        "$OUTPUT"
fi
echo ""

# Test 5: Help flag should work without --intent
echo "Test 5: Help flag should work without --intent requirement"
run_test
OUTPUT=$($SCRIPT_PATH --help 2>&1 || true)
if echo "$OUTPUT" | grep -q "Usage:"; then
    pass_test "Help flag works without --intent requirement"
else
    fail_test "Help flag works without --intent" \
        "Usage:" \
        "$OUTPUT"
fi
echo ""

# Test 6: Intent flag without arguments should show usage
echo "Test 6: Intent flag with missing arguments should show usage"
run_test
OUTPUT=$($SCRIPT_PATH --intent 2>&1 || true)
if echo "$OUTPUT" | grep -q "domain and service are required"; then
    pass_test "Missing arguments shows usage even with --intent"
else
    fail_test "Missing arguments shows usage" \
        "domain and service are required" \
        "$OUTPUT"
fi
echo ""

# Test 7: Read-only scripts should work without any gating
echo "Test 7: Read-only probe script should work without gating"
run_test
# Note: This will fail to connect but shouldn't be blocked by permission gates
OUTPUT=$($PROBE_SCRIPT 2>&1 || true)
if echo "$OUTPUT" | grep -q "Testing connectivity" || echo "$OUTPUT" | grep -q "Connection failed"; then
    pass_test "Read-only probe script runs without permission gates"
else
    fail_test "Read-only probe script runs without gates" \
        "Testing connectivity or Connection failed" \
        "$OUTPUT"
fi
echo ""

# Test 8: Read-only list script should work without any gating
echo "Test 8: Read-only list entities script should work without gating"
run_test
OUTPUT=$($LIST_SCRIPT 2>&1 || true)
if echo "$OUTPUT" | grep -q "Home Assistant Entities" || echo "$OUTPUT" | grep -q "Failed to retrieve"; then
    pass_test "Read-only list entities script runs without permission gates"
else
    fail_test "Read-only list entities script runs without gates" \
        "Home Assistant Entities or Failed to retrieve" \
        "$OUTPUT"
fi
echo ""

# Summary
echo "=================================="
echo "Test Summary"
echo "=================================="
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
