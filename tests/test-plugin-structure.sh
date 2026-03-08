#!/bin/bash
# Tests for plugin manifest structure and skill definitions
# Validates that all plugins conform to expected structure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

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
echo -e "${YELLOW}=== Plugin Structure Validation ===${NC}"
echo ""

PLUGINS=("cdk-core" "cdk-docs" "cdk-gemini" "cdk-security" "cdk-notifications")

# --- Marketplace manifest ---
echo "Marketplace manifest:"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

assert_pass "marketplace.json exists" "[[ -f '$MARKETPLACE' ]]"
assert_pass "marketplace.json is valid JSON" "jq empty '$MARKETPLACE' 2>/dev/null"
assert_pass "Has 'name' field" "jq -e '.name' '$MARKETPLACE' >/dev/null 2>&1"
assert_pass "Has 'owner' field" "jq -e '.owner.name' '$MARKETPLACE' >/dev/null 2>&1"
assert_pass "Lists 5 plugins" "[[ \$(jq '.plugins | length' '$MARKETPLACE') -eq 5 ]]"

# Verify all plugins are listed
for plugin in "${PLUGINS[@]}"; do
    assert_pass "Lists plugin: $plugin" \
        "jq -e '.plugins[] | select(.name == \"$plugin\")' '$MARKETPLACE' >/dev/null 2>&1"
done

# --- Individual plugin manifests ---
echo ""
echo "Plugin manifests (plugin.json):"

for plugin in "${PLUGINS[@]}"; do
    MANIFEST="$PLUGINS_DIR/$plugin/.claude-plugin/plugin.json"

    assert_pass "$plugin: plugin.json exists" "[[ -f '$MANIFEST' ]]"
    assert_pass "$plugin: valid JSON" "jq empty '$MANIFEST' 2>/dev/null"
    assert_pass "$plugin: has 'name' field" "jq -e '.name' '$MANIFEST' >/dev/null 2>&1"
    assert_pass "$plugin: has 'version' field" "jq -e '.version' '$MANIFEST' >/dev/null 2>&1"
    assert_pass "$plugin: has 'description' field" "jq -e '.description' '$MANIFEST' >/dev/null 2>&1"

    # Version format check (semver)
    TOTAL=$((TOTAL + 1))
    VERSION=$(jq -r '.version' "$MANIFEST")
    if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "  ${GREEN}PASS${NC} $plugin: version '$VERSION' is valid semver"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} $plugin: version '$VERSION' is not valid semver"
        FAILED=$((FAILED + 1))
    fi

    # Cross-check name matches marketplace
    TOTAL=$((TOTAL + 1))
    MANIFEST_NAME=$(jq -r '.name' "$MANIFEST")
    if [[ "$MANIFEST_NAME" == "$plugin" ]]; then
        echo -e "  ${GREEN}PASS${NC} $plugin: name matches marketplace entry"
        PASSED=$((PASSED + 1))
    else
        echo -e "  ${RED}FAIL${NC} $plugin: manifest name '$MANIFEST_NAME' != '$plugin'"
        FAILED=$((FAILED + 1))
    fi
done

# --- Skill structure ---
echo ""
echo "Skill definitions (SKILL.md):"

# Plugins with skills
declare -A EXPECTED_SKILLS
EXPECTED_SKILLS[cdk-core]="code-review full-context refactor handoff"
EXPECTED_SKILLS[cdk-docs]="scaffold create-docs update-docs"
EXPECTED_SKILLS[cdk-gemini]="consult"

for plugin in cdk-core cdk-docs cdk-gemini; do
    for skill in ${EXPECTED_SKILLS[$plugin]}; do
        SKILL_FILE="$PLUGINS_DIR/$plugin/skills/$skill/SKILL.md"

        assert_pass "$plugin/$skill: SKILL.md exists" "[[ -f '$SKILL_FILE' ]]"

        # Check for frontmatter (starts with ---)
        TOTAL=$((TOTAL + 1))
        if head -1 "$SKILL_FILE" | grep -q '^---'; then
            echo -e "  ${GREEN}PASS${NC} $plugin/$skill: has YAML frontmatter"
            PASSED=$((PASSED + 1))
        else
            echo -e "  ${RED}FAIL${NC} $plugin/$skill: missing YAML frontmatter"
            FAILED=$((FAILED + 1))
        fi

        # Check frontmatter has name field
        TOTAL=$((TOTAL + 1))
        if grep -q '^name:' "$SKILL_FILE"; then
            echo -e "  ${GREEN}PASS${NC} $plugin/$skill: frontmatter has 'name' field"
            PASSED=$((PASSED + 1))
        else
            echo -e "  ${RED}FAIL${NC} $plugin/$skill: frontmatter missing 'name' field"
            FAILED=$((FAILED + 1))
        fi

        # Check frontmatter has description field
        TOTAL=$((TOTAL + 1))
        if grep -q '^description:' "$SKILL_FILE"; then
            echo -e "  ${GREEN}PASS${NC} $plugin/$skill: frontmatter has 'description' field"
            PASSED=$((PASSED + 1))
        else
            echo -e "  ${RED}FAIL${NC} $plugin/$skill: frontmatter missing 'description' field"
            FAILED=$((FAILED + 1))
        fi
    done
done

# --- Hook structure ---
echo ""
echo "Hook definitions (hooks.json):"

# Plugins with hooks
HOOK_PLUGINS=("cdk-gemini" "cdk-security" "cdk-notifications")

for plugin in "${HOOK_PLUGINS[@]}"; do
    HOOKS_FILE="$PLUGINS_DIR/$plugin/hooks/hooks.json"

    assert_pass "$plugin: hooks.json exists" "[[ -f '$HOOKS_FILE' ]]"
    assert_pass "$plugin: hooks.json is valid JSON" "jq empty '$HOOKS_FILE' 2>/dev/null"
    assert_pass "$plugin: has 'hooks' key" "jq -e '.hooks' '$HOOKS_FILE' >/dev/null 2>&1"

    # Verify referenced scripts exist
    TOTAL=$((TOTAL + 1))
    SCRIPTS_VALID=true
    CMDS=$(jq -r '.. | objects | select(.command?) | .command' "$HOOKS_FILE" 2>/dev/null || true)
    IFS=$'\n'
    for cmd in $CMDS; do
        [[ -z "$cmd" ]] && continue
        # Replace ${CLAUDE_PLUGIN_ROOT} with actual path
        RESOLVED=$(echo "$cmd" | sed "s|\${CLAUDE_PLUGIN_ROOT}|$PLUGINS_DIR/$plugin|g")
        SCRIPT_PATH=$(echo "$RESOLVED" | awk '{print $1}')
        if [[ ! -f "$SCRIPT_PATH" ]]; then
            echo -e "  ${RED}FAIL${NC} $plugin: referenced script not found: $SCRIPT_PATH"
            SCRIPTS_VALID=false
            break
        fi
    done
    unset IFS

    if $SCRIPTS_VALID; then
        echo -e "  ${GREEN}PASS${NC} $plugin: all referenced scripts exist"
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

# --- Plugins without skills should NOT have skills/ dir with SKILL.md ---
echo ""
echo "Negative checks:"
assert_pass "cdk-security: no skills directory" "[[ ! -d '$PLUGINS_DIR/cdk-security/skills' ]]"
assert_pass "cdk-notifications: no skills directory" "[[ ! -d '$PLUGINS_DIR/cdk-notifications/skills' ]]"

# --- Script executability ---
echo ""
echo "Script permissions:"
SCRIPTS=(
    "plugins/cdk-security/scripts/mcp-security-scan.sh"
    "plugins/cdk-gemini/scripts/gemini-context-injector.sh"
    "plugins/cdk-notifications/scripts/notify.sh"
)
for script in "${SCRIPTS[@]}"; do
    FULL_PATH="$REPO_ROOT/$script"
    assert_pass "$script is executable" "[[ -x '$FULL_PATH' ]]"
done

echo ""
echo -e "Plugin structure: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, $TOTAL total"
echo ""

echo "STRUCTURE_PASSED=$PASSED"
echo "STRUCTURE_FAILED=$FAILED"
echo "STRUCTURE_TOTAL=$TOTAL"

[[ "$FAILED" -eq 0 ]] || exit 1
