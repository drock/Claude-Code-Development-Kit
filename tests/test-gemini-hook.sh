#!/bin/bash
# Tests for cdk-gemini context injector hook
# Validates that the hook correctly injects project context into new Gemini sessions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_SCRIPT="$REPO_ROOT/plugins/cdk-gemini/scripts/gemini-context-injector.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
TEST_PROJECT="$REPO_ROOT/test-project"

# Export environment variables the hook expects
export CLAUDE_PROJECT_DIR="$TEST_PROJECT"

PASSED=0
FAILED=0
TOTAL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_hook() {
    local input_json="$1"
    local output
    local exit_code=0
    output=$(echo "$input_json" | bash "$HOOK_SCRIPT" 2>&1) || exit_code=$?
    echo "$output"
    return $exit_code
}

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
echo -e "${YELLOW}=== cdk-gemini Context Injector Tests ===${NC}"
echo ""

# --- New session: should inject context files ---
echo "New session (no session_id) — should inject context files:"

OUTPUT=$(run_hook "$(cat "$FIXTURES_DIR/gemini-new-session.json")")

# Check that project-structure.md path is in the output
assert_pass "Injects project-structure.md path" \
    "echo '$OUTPUT' | jq -e '.tool_input.attached_files[]' 2>/dev/null | grep -q 'project-structure.md'"

# Check that MCP-ASSISTANT-RULES.md path is in the output
assert_pass "Injects MCP-ASSISTANT-RULES.md path" \
    "echo '$OUTPUT' | jq -e '.tool_input.attached_files[]' 2>/dev/null | grep -q 'MCP-ASSISTANT-RULES.md'"

# Check the output is valid JSON with tool_input
assert_pass "Output is valid JSON with tool_input" \
    "echo '$OUTPUT' | jq -e '.tool_input' >/dev/null 2>&1"

# --- Existing session: should pass through ---
echo ""
echo "Existing session (has session_id) — should pass through:"

OUTPUT=$(run_hook "$(cat "$FIXTURES_DIR/gemini-existing-session.json")")

assert_pass "Returns continue:true for existing session" \
    "echo '$OUTPUT' | jq -e '.continue == true' >/dev/null 2>&1"

# --- Non-Gemini tool: should pass through ---
echo ""
echo "Non-Gemini tool — should pass through:"

OUTPUT=$(run_hook "$(cat "$FIXTURES_DIR/gemini-non-gemini-tool.json")")

assert_pass "Returns continue:true for non-Gemini tool" \
    "echo '$OUTPUT' | jq -e '.continue == true' >/dev/null 2>&1"

# --- Files already attached: should skip ---
echo ""
echo "Files already attached — should skip re-injection:"

# Build fixture with real paths
PROJECT_STRUCTURE="$TEST_PROJECT/docs/ai-context/project-structure.md"
MCP_RULES="$TEST_PROJECT/MCP-ASSISTANT-RULES.md"
INPUT_JSON=$(jq --arg ps "$PROJECT_STRUCTURE" --arg mr "$MCP_RULES" \
    '.tool_input.attached_files = [$ps, $mr]' \
    "$FIXTURES_DIR/gemini-files-already-attached.json")

OUTPUT=$(run_hook "$INPUT_JSON")

assert_pass "Returns continue:true when files already attached" \
    "echo '$OUTPUT' | jq -e '.continue == true' >/dev/null 2>&1"

# --- Missing context files: should handle gracefully ---
echo ""
echo "Missing context files — graceful handling:"

# Temporarily rename files to simulate missing
mv "$TEST_PROJECT/docs/ai-context/project-structure.md" "$TEST_PROJECT/docs/ai-context/project-structure.md.bak"
mv "$TEST_PROJECT/MCP-ASSISTANT-RULES.md" "$TEST_PROJECT/MCP-ASSISTANT-RULES.md.bak"

OUTPUT=$(run_hook "$(cat "$FIXTURES_DIR/gemini-new-session.json")")

assert_pass "Returns continue:true when both context files missing" \
    "echo '$OUTPUT' | jq -e '.continue == true' >/dev/null 2>&1"

# Restore one file
mv "$TEST_PROJECT/docs/ai-context/project-structure.md.bak" "$TEST_PROJECT/docs/ai-context/project-structure.md"

OUTPUT=$(run_hook "$(cat "$FIXTURES_DIR/gemini-new-session.json")")

assert_pass "Injects only available file when one is missing" \
    "echo '$OUTPUT' | jq -e '.tool_input.attached_files[]' 2>/dev/null | grep -q 'project-structure.md'"

# Restore second file
mv "$TEST_PROJECT/MCP-ASSISTANT-RULES.md.bak" "$TEST_PROJECT/MCP-ASSISTANT-RULES.md"

# --- Log file check ---
echo ""
echo "Logging:"
TOTAL=$((TOTAL + 1))
if [[ -f "$TEST_PROJECT/.claude/logs/context-injection.log" ]]; then
    line_count=$(wc -l < "$TEST_PROJECT/.claude/logs/context-injection.log")
    if [[ "$line_count" -gt 0 ]]; then
        echo -e "  ${GREEN}PASS${NC} Log file created with $line_count entries"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} Log file is empty"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "  ${RED}FAIL${NC} Log file not created"
    FAILED=$((FAILED + 1))
fi

# Clean up
rm -f "$TEST_PROJECT/.claude/logs/context-injection.log"

echo ""
echo -e "Gemini hook: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, $TOTAL total"
echo ""

echo "GEMINI_PASSED=$PASSED"
echo "GEMINI_FAILED=$FAILED"
echo "GEMINI_TOTAL=$TOTAL"

[[ "$FAILED" -eq 0 ]] || exit 1
