#!/bin/bash
# Tests for cdk-notifications hook script
# Validates script argument handling, file resolution, and OS detection logic
# Note: Actual audio playback is NOT tested (no audio in CI/web sessions)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_SCRIPT="$REPO_ROOT/plugins/cdk-notifications/scripts/notify.sh"
PLUGIN_DIR="$REPO_ROOT/plugins/cdk-notifications"

export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"

PASSED=0
FAILED=0
TOTAL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert_pass() {
    local test_name="$1"
    local condition="$2"
    TOTAL=$((TOTAL + 1))
    if eval "$condition"; then
        echo -e "  ${GREEN}PASS${NC} $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} $test_name"
        FAILED=$((FAILED + 1))
    fi
}

echo ""
echo -e "${YELLOW}=== cdk-notifications Hook Tests ===${NC}"
echo ""

# --- Sound files exist ---
echo "Sound file assets:"
assert_pass "complete.wav exists" "[[ -f '$PLUGIN_DIR/sounds/complete.wav' ]]"
assert_pass "input-needed.wav exists" "[[ -f '$PLUGIN_DIR/sounds/input-needed.wav' ]]"

# Check WAV file validity (starts with RIFF header)
assert_pass "complete.wav has RIFF header" "head -c 4 '$PLUGIN_DIR/sounds/complete.wav' | grep -q 'RIFF'"
assert_pass "input-needed.wav has RIFF header" "head -c 4 '$PLUGIN_DIR/sounds/input-needed.wav' | grep -q 'RIFF'"

# --- Argument validation ---
echo ""
echo "Argument handling:"

# No arguments should fail with exit 1
TOTAL=$((TOTAL + 1))
EXIT_CODE=0
bash "$HOOK_SCRIPT" 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 1 ]]; then
    echo -e "  ${GREEN}PASS${NC} No arguments exits with code 1"
    PASSED=$((PASSED + 1))
else
    echo -e "  ${RED}FAIL${NC} No arguments should exit 1, got $EXIT_CODE"
    FAILED=$((FAILED + 1))
fi

# Invalid argument should fail with exit 1
TOTAL=$((TOTAL + 1))
EXIT_CODE=0
bash "$HOOK_SCRIPT" "invalid" 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 1 ]]; then
    echo -e "  ${GREEN}PASS${NC} Invalid argument exits with code 1"
    PASSED=$((PASSED + 1))
else
    echo -e "  ${RED}FAIL${NC} Invalid argument should exit 1, got $EXIT_CODE"
    FAILED=$((FAILED + 1))
fi

# Valid arguments should exit 0 (even if no audio player is found)
TOTAL=$((TOTAL + 1))
EXIT_CODE=0
bash "$HOOK_SCRIPT" "input" 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo -e "  ${GREEN}PASS${NC} 'input' argument exits with code 0"
    PASSED=$((PASSED + 1))
else
    echo -e "  ${RED}FAIL${NC} 'input' should exit 0, got $EXIT_CODE"
    FAILED=$((FAILED + 1))
fi

TOTAL=$((TOTAL + 1))
EXIT_CODE=0
bash "$HOOK_SCRIPT" "complete" 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo -e "  ${GREEN}PASS${NC} 'complete' argument exits with code 0"
    PASSED=$((PASSED + 1))
else
    echo -e "  ${RED}FAIL${NC} 'complete' should exit 0, got $EXIT_CODE"
    FAILED=$((FAILED + 1))
fi

# --- Usage message ---
echo ""
echo "Usage output:"
TOTAL=$((TOTAL + 1))
USAGE_OUTPUT=$(bash "$HOOK_SCRIPT" 2>&1 || true)
if echo "$USAGE_OUTPUT" | grep -q "Usage:"; then
    echo -e "  ${GREEN}PASS${NC} Shows usage message on no arguments"
    PASSED=$((PASSED + 1))
else
    echo -e "  ${RED}FAIL${NC} Should show usage message"
    FAILED=$((FAILED + 1))
fi

# --- CLAUDE_PLUGIN_ROOT fallback ---
echo ""
echo "Plugin root resolution:"
TOTAL=$((TOTAL + 1))
# Unset CLAUDE_PLUGIN_ROOT and run from script's directory — should still resolve
unset CLAUDE_PLUGIN_ROOT
EXIT_CODE=0
bash "$HOOK_SCRIPT" "complete" 2>/dev/null || EXIT_CODE=$?
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo -e "  ${GREEN}PASS${NC} Falls back to script-relative path when CLAUDE_PLUGIN_ROOT unset"
    PASSED=$((PASSED + 1))
else
    echo -e "  ${RED}FAIL${NC} Should work without CLAUDE_PLUGIN_ROOT, got exit $EXIT_CODE"
    FAILED=$((FAILED + 1))
fi
export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"

echo ""
echo -e "Notifications hook: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, $TOTAL total"
echo ""

echo "NOTIFICATIONS_PASSED=$PASSED"
echo "NOTIFICATIONS_FAILED=$FAILED"
echo "NOTIFICATIONS_TOTAL=$TOTAL"

[[ "$FAILED" -eq 0 ]] || exit 1
