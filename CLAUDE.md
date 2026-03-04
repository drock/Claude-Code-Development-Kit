# Claude Code Development Kit

## Project Structure — Plugin Marketplace Architecture

**CRITICAL:** This repository is a *private plugin marketplace* that distributes modular plugins for Claude Code. The `plugins/` directory contains 5 independent plugins that users install via the Claude Code plugin system.

### Plugin directories (distributed to target projects)
- `plugins/cdk-core/` — Core multi-agent workflow skills (code review, refactoring, context gathering, session handoff)
- `plugins/cdk-docs/` — Documentation scaffolding and generation (scaffold, create-docs, update-docs)
- `plugins/cdk-gemini/` — Gemini MCP integration (consultation skill + context injection hook)
- `plugins/cdk-security/` — MCP security scanning hook (prevents secret exposure to external services)
- `plugins/cdk-notifications/` — Audio notification hooks (task completion, input needed)

### Marketplace manifest
- `.claude-plugin/marketplace.json` — Catalog listing all 5 plugins for the Claude Code plugin system

### CDK-internal files (for working on THIS repository)
- `.claude/commands/` — Slash commands for CDK development only
- `.claude/hooks/` — Hooks that run during CDK development sessions
- `.claude/settings.json` — Claude Code settings for CDK development

### Plugin anatomy
Each plugin follows this structure:
```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (name, description, version)
├── skills/                  # Skills (SKILL.md files) — optional
│   └── <skill-name>/
│       └── SKILL.md         # Skill definition with frontmatter
├── hooks/                   # Hook definitions — optional
│   └── hooks.json           # Declarative hook configuration
├── scripts/                 # Hook shell scripts — optional
└── <assets>/                # Plugin-specific assets (config, sounds, templates)
```

**Do NOT move plugin files into `.claude/`.** The `plugins/` directory and `.claude-plugin/` manifest are the distribution mechanism. The `.claude/` directory is only for CDK development configuration.

## Changelog & Release Process

This project uses [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

### Maintaining the Changelog
When completing work that introduces user-facing changes, add an entry to the `[Unreleased]` section of `CHANGELOG.md` before committing. Use the appropriate category:
- **Added** — new features or capabilities
- **Changed** — changes to existing functionality
- **Fixed** — bug fixes
- **Improved** — enhancements to existing features (non-breaking)
- **Removed** — removed features or capabilities

**Consolidate entries:** Before adding a new entry, review existing `[Unreleased]` entries. If your change supersedes, revises, or reverts a previous unreleased entry, **update or replace** that entry instead of adding a new one. The `[Unreleased]` section represents the cumulative delta from the last release — end users never see intermediate states. For example, if an unreleased entry says "Changed button color from blue to red" and you now change it to black, update the entry to "Changed button color from blue to black" (or remove it entirely if it returns to the original state).

Skip changelog entries for: internal refactors with no user-visible effect, test-only changes, CI/tooling changes, and documentation-only updates (unless documenting a new feature).

### Creating Releases
Releases are handled by a manually-triggered GitHub Actions workflow (`.github/workflows/release.yml`), triggered from the GitHub UI: **Actions → Release → Run workflow**.

The workflow:
1. Validates that `[Unreleased]` has content
2. Determines the new version (auto-detect from headings, bump keyword, or explicit version)
3. Updates CHANGELOG.md (moves unreleased entries to a versioned section) and README badge via shell scripts
4. Commits, tags (`vX.Y.Z`), and pushes to `main`
5. Creates a GitHub Release with extracted release notes

No API keys or external services are required — the workflow uses only bash/awk for file updates.

Do not create releases, tags, or version bumps manually. Always use the workflow.

### Version Bump Rules (SemVer)
- **patch** (e.g., 2.1.0 → 2.1.1): bug fixes only
- **minor** (e.g., 2.1.0 → 2.2.0): new features, no breaking changes
- **major** (e.g., 2.1.0 → 3.0.0): breaking changes
