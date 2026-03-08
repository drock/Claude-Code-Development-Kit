#!/bin/bash
# CDK Plugin Test Runner
# Runs all plugin test suites and reports aggregate results
#
# Usage:
#   ./tests/run-tests.sh              # Run all tests
#   ./tests/run-tests.sh security     # Run only security tests
#   ./tests/run-tests.sh gemini       # Run only gemini tests
#   ./tests/run-tests.sh notifications # Run only notifications tests
#   ./tests/run-tests.sh structure    # Run only structure validation

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_TESTS=0
SUITES_PASSED=0
SUITES_FAILED=0
SUITE_FILTER="${1:-all}"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     CDK Plugin Test Suite Runner         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# Check dependencies
for cmd in jq bash; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}ERROR: Required command '$cmd' not found${NC}"
        exit 1
    fi
done

run_suite() {
    local suite_name="$1"
    local script="$2"

    if [[ "$SUITE_FILTER" != "all" && "$SUITE_FILTER" != "$suite_name" ]]; then
        return
    fi

    echo -e "${BOLD}Running: $suite_name${NC}"
    echo "─────────────────────────────────────────"

    local exit_code=0
    local output
    output=$(bash "$script" 2>&1) || exit_code=$?

    # Print the output (skip the VARNAME=value lines at the end)
    echo "$output" | grep -v '^[A-Z_]*_PASSED=' | grep -v '^[A-Z_]*_FAILED=' | grep -v '^[A-Z_]*_TOTAL='

    # Extract results from output
    local suite_passed suite_failed suite_total
    suite_passed=$(echo "$output" | grep '_PASSED=' | tail -1 | cut -d= -f2)
    suite_failed=$(echo "$output" | grep '_FAILED=' | tail -1 | cut -d= -f2)
    suite_total=$(echo "$output" | grep '_TOTAL=' | tail -1 | cut -d= -f2)

    TOTAL_PASSED=$((TOTAL_PASSED + ${suite_passed:-0}))
    TOTAL_FAILED=$((TOTAL_FAILED + ${suite_failed:-0}))
    TOTAL_TESTS=$((TOTAL_TESTS + ${suite_total:-0}))

    if [[ "$exit_code" -eq 0 ]]; then
        SUITES_PASSED=$((SUITES_PASSED + 1))
    else
        SUITES_FAILED=$((SUITES_FAILED + 1))
    fi
}

# Run test suites
run_suite "structure"     "$SCRIPT_DIR/test-plugin-structure.sh"
run_suite "security"      "$SCRIPT_DIR/test-security-hook.sh"
run_suite "gemini"        "$SCRIPT_DIR/test-gemini-hook.sh"
run_suite "notifications" "$SCRIPT_DIR/test-notifications-hook.sh"

# Aggregate results
TOTAL_SUITES=$((SUITES_PASSED + SUITES_FAILED))

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}Aggregate Results${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  Test suites: ${GREEN}$SUITES_PASSED passed${NC}, ${RED}$SUITES_FAILED failed${NC}, $TOTAL_SUITES total"
echo -e "  Tests:       ${GREEN}$TOTAL_PASSED passed${NC}, ${RED}$TOTAL_FAILED failed${NC}, $TOTAL_TESTS total"
echo ""

if [[ "$TOTAL_FAILED" -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}$TOTAL_FAILED test(s) failed.${NC}"
    exit 1
fi
