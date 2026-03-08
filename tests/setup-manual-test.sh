#!/bin/bash
# Setup script for manual plugin testing
#
# This script "installs" plugins into the test-project/ by creating the
# .claude/plugins/ directory structure that Claude Code expects when plugins
# are installed with --scope project.
#
# After running this script, you can open test-project/ as a separate Claude
# Code project to manually test the skills and hooks.
#
# Usage:
#   ./tests/setup-manual-test.sh           # Install all plugins
#   ./tests/setup-manual-test.sh cdk-core  # Install specific plugin
#   ./tests/setup-manual-test.sh --clean   # Remove installed plugins

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_PROJECT="$REPO_ROOT/test-project"
PLUGINS_DIR="$REPO_ROOT/plugins"
TARGET_PLUGINS_DIR="$TEST_PROJECT/.claude/plugins"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PLUGINS=("cdk-core" "cdk-docs" "cdk-gemini" "cdk-security" "cdk-notifications")

clean_plugins() {
    echo -e "${YELLOW}Cleaning installed plugins from test-project/...${NC}"
    rm -rf "$TARGET_PLUGINS_DIR"
    echo -e "${GREEN}Done.${NC}"
}

install_plugin() {
    local plugin_name="$1"
    local source_dir="$PLUGINS_DIR/$plugin_name"
    local target_dir="$TARGET_PLUGINS_DIR/$plugin_name"

    if [[ ! -d "$source_dir" ]]; then
        echo -e "${RED}Plugin not found: $plugin_name${NC}"
        return 1
    fi

    echo -e "  Installing ${BOLD}$plugin_name${NC}..."

    # Create the target directory
    mkdir -p "$target_dir"

    # Symlink the plugin content (simulates how Claude Code installs plugins)
    # We use symlinks so edits to plugin source are immediately reflected
    ln -sfn "$source_dir/.claude-plugin" "$target_dir/.claude-plugin"
    [[ -d "$source_dir/skills" ]] && ln -sfn "$source_dir/skills" "$target_dir/skills"
    [[ -d "$source_dir/hooks" ]] && ln -sfn "$source_dir/hooks" "$target_dir/hooks"
    [[ -d "$source_dir/scripts" ]] && ln -sfn "$source_dir/scripts" "$target_dir/scripts"
    [[ -d "$source_dir/config" ]] && ln -sfn "$source_dir/config" "$target_dir/config"
    [[ -d "$source_dir/sounds" ]] && ln -sfn "$source_dir/sounds" "$target_dir/sounds"

    echo -e "  ${GREEN}✓${NC} $plugin_name installed (symlinked)"
}

# Parse arguments
if [[ "${1:-}" == "--clean" ]]; then
    clean_plugins
    exit 0
fi

INSTALL_PLUGINS=()
if [[ $# -gt 0 ]]; then
    INSTALL_PLUGINS=("$@")
else
    INSTALL_PLUGINS=("${PLUGINS[@]}")
fi

echo ""
echo -e "${BOLD}Setting up manual plugin testing in test-project/${NC}"
echo ""

# Ensure test-project exists
if [[ ! -d "$TEST_PROJECT" ]]; then
    echo -e "${RED}test-project/ not found. Run from the repository root.${NC}"
    exit 1
fi

# Create plugins directory
mkdir -p "$TARGET_PLUGINS_DIR"

# Install requested plugins
for plugin in "${INSTALL_PLUGINS[@]}"; do
    install_plugin "$plugin"
done

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "To test manually:"
echo ""
echo "  1. Open test-project/ as a Claude Code project:"
echo "     cd test-project && claude"
echo ""
echo "  2. Try the installed skills:"
echo "     /cdk-core:code-review src/app.js"
echo "     /cdk-docs:scaffold"
echo "     /cdk-gemini:consult How should I structure this API?"
echo ""
echo "  3. Hooks run automatically:"
echo "     - cdk-security: scans all MCP tool calls for secrets"
echo "     - cdk-gemini: injects context into new Gemini sessions"
echo "     - cdk-notifications: plays sounds on task events"
echo ""
echo "  Note: Plugin symlinks point to the source plugins/ directory,"
echo "  so any edits you make to the plugins will be immediately reflected."
echo ""
