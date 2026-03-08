#!/bin/bash
# Tests for cdk-security MCP security scanning hook
# Validates that the hook correctly blocks/allows MCP calls based on content

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_SCRIPT="$REPO_ROOT/plugins/cdk-security/scripts/mcp-security-scan.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
TEST_PROJECT="$REPO_ROOT/test-project"

# Export environment variables the hook expects
export CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/cdk-security"
export CLAUDE_PROJECT_DIR="$TEST_PROJECT"

PASSED=0
FAILED=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert_exit_code() {
    local test_name="$1"
    local expected_exit="$2"
    local input_file="$3"
    local actual_exit=0
    TOTAL=$((TOTAL + 1))

    local output
    output=$(bash "$HOOK_SCRIPT" < "$input_file" 2>&1) || actual_exit=$?

    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        echo -e "  ${GREEN}PASS${NC} $test_name (exit=$actual_exit)"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} $test_name"
        echo -e "       Expected exit=$expected_exit, got exit=$actual_exit"
        [[ -n "$output" ]] && echo -e "       Output: ${output:0:200}"
        FAILED=$((FAILED + 1))
    fi
}

assert_output_contains() {
    local test_name="$1"
    local expected_pattern="$2"
    local input_file="$3"
    local actual_exit=0
    TOTAL=$((TOTAL + 1))

    local output
    output=$(bash "$HOOK_SCRIPT" < "$input_file" 2>&1) || actual_exit=$?

    if echo "$output" | grep -q "$expected_pattern"; then
        echo -e "  ${GREEN}PASS${NC} $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} $test_name"
        echo -e "       Expected output to contain: $expected_pattern"
        echo -e "       Got: ${output:0:200}"
        FAILED=$((FAILED + 1))
    fi
}

assert_exit_code_from_stdin() {
    local test_name="$1"
    local expected_exit="$2"
    local input_json="$3"
    local actual_exit=0
    TOTAL=$((TOTAL + 1))

    local output
    output=$(echo "$input_json" | bash "$HOOK_SCRIPT" 2>&1) || actual_exit=$?

    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        echo -e "  ${GREEN}PASS${NC} $test_name (exit=$actual_exit)"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} $test_name"
        echo -e "       Expected exit=$expected_exit, got exit=$actual_exit"
        [[ -n "$output" ]] && echo -e "       Output: ${output:0:200}"
        FAILED=$((FAILED + 1))
    fi
}

echo ""
echo -e "${YELLOW}=== cdk-security Hook Tests ===${NC}"
echo ""

# --- Clean input tests ---
echo "Clean inputs (should ALLOW — exit 0):"
assert_exit_code "Clean code context and description" 0 "$FIXTURES_DIR/security-clean-input.json"

# --- API key detection tests ---
echo ""
echo "API key detection (should BLOCK — exit 2):"
assert_exit_code "OpenAI-style API key in code_context" 2 "$FIXTURES_DIR/security-api-key-in-context.json"
assert_exit_code "AWS access key in code_context" 2 "$FIXTURES_DIR/security-aws-key-in-context.json"
assert_exit_code "GitHub PAT in code_context" 2 "$FIXTURES_DIR/security-github-token-in-context.json"

# --- Credential detection tests ---
echo ""
echo "Credential detection (should BLOCK — exit 2):"
assert_exit_code "Password in problem_description" 2 "$FIXTURES_DIR/security-password-in-description.json"

# --- Whitelisted patterns ---
echo ""
echo "Whitelisted patterns (should ALLOW — exit 0):"
assert_exit_code "Whitelisted postgres://user:password@localhost" 0 "$FIXTURES_DIR/security-whitelisted-input.json"

# --- Sensitive file detection ---
echo ""
echo "Sensitive file detection (should BLOCK — exit 2):"
# Create a temporary .env file for this test
TEMP_ENV="$TEST_PROJECT/.env"
cp "$FIXTURES_DIR/mock-env-file" "$TEMP_ENV"
# Build the fixture with the real path
TEMP_FIXTURE=$(mktemp)
jq --arg envfile "$TEMP_ENV" '.tool_input.attached_files = [$envfile]' \
    "$FIXTURES_DIR/security-sensitive-file.json" > "$TEMP_FIXTURE"
assert_exit_code "Attached .env file with secrets" 2 "$TEMP_FIXTURE"
rm -f "$TEMP_ENV" "$TEMP_FIXTURE"

# --- Command injection detection ---
echo ""
echo "Command injection detection (should BLOCK — exit 2):"
assert_exit_code "Injection in Context7 libraryId" 2 "$FIXTURES_DIR/security-injection-library-id.json"

# --- Inline tests for edge cases ---
echo ""
echo "Edge cases:"

# Anthropic API key pattern
assert_exit_code_from_stdin "Anthropic API key (sk-ant-api)" 2 '{
  "tool_name": "mcp__gemini__consult_gemini",
  "tool_input": {
    "code_context": "ANTHROPIC_KEY=sk-ant-api03-abcdefghijklmnopqrstuvwxyz",
    "problem_description": "",
    "attached_files": []
  }
}'

# Private key detection
assert_exit_code_from_stdin "RSA private key header" 2 '{
  "tool_name": "mcp__gemini__consult_gemini",
  "tool_input": {
    "code_context": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAK...",
    "problem_description": "",
    "attached_files": []
  }
}'

# Bearer token
assert_exit_code_from_stdin "JWT Bearer token" 2 '{
  "tool_name": "mcp__gemini__consult_gemini",
  "tool_input": {
    "code_context": "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U",
    "problem_description": "",
    "attached_files": []
  }
}'

# Safe placeholder (should allow)
assert_exit_code_from_stdin "Safe placeholder API_KEY=YOUR_API_KEY" 0 '{
  "tool_name": "mcp__gemini__consult_gemini",
  "tool_input": {
    "code_context": "api_key=YOUR_API_KEY",
    "problem_description": "",
    "attached_files": []
  }
}'

# Context7 libraryName injection
assert_exit_code_from_stdin "Injection in Context7 libraryName" 2 '{
  "tool_name": "mcp__context7__resolve-library-id",
  "tool_input": {
    "libraryName": "react && cat /etc/passwd",
    "code_context": "",
    "problem_description": "",
    "attached_files": []
  }
}'

# Block output contains expected message
echo ""
echo "Block message validation:"
assert_output_contains "Block message mentions 'Security Alert'" "Security Alert" "$FIXTURES_DIR/security-api-key-in-context.json"

# --- Log file check ---
echo ""
echo "Logging:"
TOTAL=$((TOTAL + 1))
if [[ -f "$TEST_PROJECT/.claude/logs/security-scan.log" ]]; then
    local_lines=$(wc -l < "$TEST_PROJECT/.claude/logs/security-scan.log")
    if [[ "$local_lines" -gt 0 ]]; then
        echo -e "  ${GREEN}PASS${NC} Log file created with $local_lines entries"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} Log file is empty"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "  ${RED}FAIL${NC} Log file not created at $TEST_PROJECT/.claude/logs/security-scan.log"
    FAILED=$((FAILED + 1))
fi

# Clean up logs
rm -f "$TEST_PROJECT/.claude/logs/security-scan.log"

echo ""
echo -e "Security hook: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, $TOTAL total"
echo ""

# Return results for the runner
echo "SECURITY_PASSED=$PASSED"
echo "SECURITY_FAILED=$FAILED"
echo "SECURITY_TOTAL=$TOTAL"

[[ "$FAILED" -eq 0 ]] || exit 1
