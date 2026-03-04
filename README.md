# Claude Code Development Kit

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Changelog](https://img.shields.io/badge/changelog-v2.3.1-orange.svg)](CHANGELOG.md)

An integrated system that transforms Claude Code into an orchestrated development environment through automated documentation management, multi-agent workflows, and external AI expertise.

> **Related**: Check out [Freigeist](https://www.freigeist.dev) - upcoming AI coding platform for complex projects!

## Why Claude Code?

Claude Code's Sub-Agents enable this highly automated, integrated approach. While other AI tools can likely use the documentation structure (see FAQ) and some commands, only Claude Code can currently orchestrate parallel agents and use this Development Kit to its full potential.

## Why This Kit?

> *Ever tried to build a large project with AI assistance, only to watch it struggle as your codebase grows?*

Claude Code's output quality directly depends on what it knows about your project. As AI-assisted development scales, three critical challenges emerge:

---

### Challenge 1: Context Management

**The Problem:**
```
Loses track of your architecture patterns and design decisions
Forgets your coding standards and team conventions
No guidance on where to find the right context in large codebases
```

**The Solution:**
**Automated context delivery** through two integrated systems:
- **3-tier documentation system** - Auto-loads the right docs at the right time
- **Plugin skills with sub-agents** - Orchestrates specialized agents that already know your project
- Result: No manual context loading, consistent knowledge across all agents

---

### Challenge 2: AI Reliability

**The Problem:**
```
Outdated library documentation
Hallucinated API methods
Inconsistent architectural decisions
```

**The Solution:**
**"Four eyes principle"** through MCP integration:

| Service | Purpose | Benefit |
|---------|---------|---------|
| **Context7** | Real-time library docs | Current APIs, not training data |
| **Gemini** | Architecture consultation | Cross-validation & best practices |

*Result: Fewer errors, better code, current standards*

---

### Challenge 3: Automation Without Complexity

**The Problem:**
```
Manual context loading for every session
Repetitive command sequences
No feedback when tasks complete
```

**The Solution:**
**Intelligent automation** through hooks and skills:
- Automatic updates of documentation through plugin skills
- Context injection for Gemini MCP calls via hooks
- CLAUDE.md auto-injected into all sessions and sub-agents by Claude Code
- Audio notifications for task completion (optional)
- One-command workflows for complex tasks

---

### The Result

> **Claude Code transforms from a helpful tool into a reliable development partner that remembers your project context, validates its own work, and handles the tedious stuff automatically.**


[![Demo-Video auf YouTube](https://img.youtube.com/vi/kChalBbMs4g/0.jpg)](https://youtu.be/kChalBbMs4g)



## Quick Start

### Prerequisites

- **Required**: [Claude Code](https://github.com/anthropics/claude-code)
- **Recommended**: MCP servers like [Context7](https://github.com/upstash/context7) and [Gemini Assistant](https://github.com/peterkrueck/mcp-gemini-assistant)

#### Platform Support

- **Windows**: Not fully supported (has reported bugs - use at your own risk)

### Installation

The CDK is distributed as a **private plugin marketplace** with 5 modular plugins. Install only what you need, at the scope you prefer.

#### Step 1: Add the Marketplace

```bash
/plugin marketplace add drock/Claude-Code-Development-Kit
```

#### Step 2: Install Plugins

Choose the plugins you need and the installation scope:

```bash
# Core workflow skills (recommended for all projects)
/plugin install cdk-core@cdk --scope project

# Documentation system (recommended for all projects)
/plugin install cdk-docs@cdk --scope project

# Security scanning for MCP calls (recommended)
/plugin install cdk-security@cdk --scope project

# Gemini MCP integration (if you use Gemini Assistant MCP)
/plugin install cdk-gemini@cdk --scope user

# Audio notifications (personal preference)
/plugin install cdk-notifications@cdk --scope user
```

**Scope options:**
- `--scope project` — Shared with your team via `.claude/plugins/`
- `--scope user` — Personal, applies to all your projects
- `--scope local` — Personal, only for the current project

#### Step 3: Scaffold Documentation (Once per Project)

```bash
/cdk-docs:scaffold
```

This sets up the 3-tier documentation structure in your project:
- **Safely handles CLAUDE.md** — appends CDK standards to an existing file (never overwrites)
- Creates `docs/ai-context/` with foundational templates
- Creates `MCP-ASSISTANT-RULES.md` template
- Provides tier 2/3 CONTEXT.md templates for your components

#### Local Development (For CDK Contributors)

Test plugins locally without installing from the marketplace:

```bash
claude --plugin-dir ./plugins/cdk-core
```

### Post-Installation Setup

1. **Customize your AI context**:
   - Edit `CLAUDE.md` with your project standards
   - Update `docs/ai-context/project-structure.md` with your tech stack

2. **Install MCP servers** (if using cdk-gemini):
   - Follow the links provided in the prerequisites
   - Configure in your Claude Code settings

3. **Test your installation**:
   ```bash
   claude
   /cdk-core:full-context "analyze my project structure"
   ```

## Plugins

### cdk-core — Core Workflow Skills

Multi-agent development workflow skills for code review, refactoring, context gathering, and session handoff.

| Skill | Invocation | Description |
|-------|-----------|-------------|
| Code Review | `/cdk-core:code-review` | Multi-agent code review surfacing critical, high-impact findings |
| Full Context | `/cdk-core:full-context` | Adaptive context gathering and comprehensive analysis |
| Refactor | `/cdk-core:refactor` | Intelligent code restructuring with multi-agent analysis |
| Handoff | `/cdk-core:handoff` | Preserve context between development sessions |

### cdk-docs — Documentation System

Documentation scaffolding and generation using the 3-tier documentation architecture.

| Skill | Invocation | Description |
|-------|-----------|-------------|
| Scaffold | `/cdk-docs:scaffold` | Set up 3-tier docs structure in your project |
| Create Docs | `/cdk-docs:create-docs` | Generate contextual documentation for components/features |
| Update Docs | `/cdk-docs:update-docs` | Synchronize documentation with code changes |

### cdk-gemini — Gemini MCP Integration

Deep Gemini consultation with persistent sessions and automatic context injection.

| Skill | Invocation | Description |
|-------|-----------|-------------|
| Consult | `/cdk-gemini:consult` | Deep iterative Gemini consultation for complex problems |

**Hooks:** Automatically injects `project-structure.md` and `MCP-ASSISTANT-RULES.md` into new Gemini sessions.

### cdk-security — MCP Security Scanning

Prevents accidental exposure of secrets and credentials to external MCP services. No skills — hooks only.

**Hooks:** Scans all `mcp__` tool calls for API keys, passwords, tokens, and private keys before they reach external services. Blocks the call if sensitive data is detected.

### cdk-notifications — Audio Notifications

Cross-platform audio notifications for task completion and input needed. No skills — hooks only.

**Hooks:** Plays pleasant sounds when Claude needs input or completes a task. Supports macOS (afplay), Linux (PulseAudio, ALSA, PipeWire), and Windows (PowerShell).

## Terminology

- **CLAUDE.md** - Master context files containing project-specific AI instructions, coding standards, and integration patterns
- **CONTEXT.md** - Component and feature-level documentation files (Tier 2 and Tier 3) that provide specific implementation details and patterns
- **MCP (Model Context Protocol)** - Standard for integrating external AI services with Claude Code
- **Sub-agents** - Specialized AI agents spawned by Claude Code to work on specific aspects of a task in parallel
- **3-Tier Documentation** - Hierarchical organization (Foundation/Component/Feature) that minimizes maintenance while maximizing AI effectiveness
- **Auto-loading** - Automatic inclusion of relevant documentation when skills execute
- **Hooks** - Shell scripts that execute at specific points in Claude Code's lifecycle for security, automation, and UX enhancements
- **Plugin** - A Claude Code extension providing skills, hooks, or both

## Architecture

### Integrated Intelligence Loop

```
                        CLAUDE CODE
                   ┌─────────────────┐
                   │                 │
                   │     SKILLS      │
                   │                 │
                   └────────┬────────┘
                  Multi-agent│orchestration
                   Parallel │execution
                   Dynamic  │scaling
                           ╱│╲
                          ╱ │ ╲
          Routes agents  ╱  │  ╲  Leverages
          to right docs ╱   │   ╲ expertise
                       ╱    │    ╲
                      ▼     │     ▼
         ┌─────────────────┐│┌─────────────────┐
         │                 │││                 │
         │  DOCUMENTATION  │││  MCP SERVERS   │
         │                 │││                 │
         └─────────────────┘│└─────────────────┘
          3-tier structure  │  Context7 + Gemini
          Auto-loading      │  Real-time updates
          Context routing   │  AI consultation
                      ╲     │     ╱
                       ╲    │    ╱
        Provides project╲   │   ╱ Enhances with
        context for      ╲  │  ╱  current best
        consultation      ╲ │ ╱   practices
                           ╲│╱
                            ▼
                    Integrated Workflow
```

### Auto-Loading Mechanism

Every skill execution automatically loads critical documentation:

```
@/CLAUDE.md                              # Master AI context and coding standards
@/docs/ai-context/project-structure.md   # Complete technology stack and file tree
@/docs/ai-context/docs-overview.md       # Documentation routing map
```

Claude Code automatically injects CLAUDE.md into all sessions (CLI and web), including sub-agents spawned via the Task tool. This means any context, conventions, or instructions in CLAUDE.md are available to every agent without needing a hook.

This ensures:
- Consistent AI behavior across all sessions and sub-agents
- Zero manual context management at any level

### Component Integration

**Skills <-> Documentation**
- Skills determine which documentation tiers to load based on task complexity
- Documentation structure guides agent spawning patterns
- Skills update documentation to maintain current context

**Skills <-> MCP Servers**
- Context7 provides up-to-date library documentation
- Gemini offers architectural consultation for complex problems
- Integration happens seamlessly within skill workflows

**Documentation <-> MCP Servers**
- Project structure and MCP assistant rules auto-attach to Gemini consultations
- Ensures external AI understands specific architecture and coding standards
- Makes all recommendations project-relevant and standards-compliant

### Hooks Integration

The kit includes battle-tested hooks distributed across plugins:

- **cdk-security** — Prevents accidental exposure of secrets when using MCP servers
- **cdk-gemini** — Automatically includes project structure in Gemini consultations
- **cdk-notifications** — Provides non-blocking audio feedback for task completion and input requests

These hooks integrate seamlessly with the skill and MCP server workflows, providing:
- Pre-execution security checks for all external AI calls
- Automatic context enhancement for external AI consultations
- Developer awareness through pleasant, non-blocking audio notifications

## Common Tasks

### Starting New Feature Development

```bash
/cdk-core:full-context "implement user authentication across backend and frontend"
```

The system:
1. Auto-loads project documentation
2. Spawns specialized agents (security, backend, frontend)
3. Consults Context7 for authentication framework documentation
4. Asks Gemini 2.5 pro for feedback and improvement suggestions
5. Provides comprehensive analysis and implementation plan

### Code Review with Multiple Perspectives

```bash
/cdk-core:code-review "review authentication implementation"
```

Multiple agents analyze:
- Security vulnerabilities
- Performance implications
- Architectural alignment
- Integration impacts

### Maintaining Documentation Currency

```bash
/cdk-docs:update-docs "document authentication changes"
```

Automatically:
- Updates affected CONTEXT.md files across all tiers
- Keeps project-structure.md and docs-overview.md up-to-date
- Maintains context for future AI sessions
- Ensures documentation matches implementation

## Creating Your Project Structure

After running `/cdk-docs:scaffold`, add your own project-specific documentation:

```
your-project/
├── CLAUDE.md                  # Master AI context (Tier 1) — CDK standards appended
├── MCP-ASSISTANT-RULES.md     # MCP coding standards (if using Gemini)
├── docs/
│   ├── ai-context/            # Foundation documentation (Tier 1)
│   │   ├── docs-overview.md   # Documentation routing map
│   │   ├── project-structure.md # Technology stack and file tree
│   │   ├── system-integration.md # Cross-component patterns
│   │   ├── deployment-infrastructure.md # Infrastructure context
│   │   └── handoff.md        # Session continuity
│   ├── open-issues/           # Issue tracking templates
│   ├── specs/                 # Feature specifications
│   ├── CONTEXT-tier2-component.md  # Component documentation template
│   └── CONTEXT-tier3-feature.md    # Feature documentation template
├── backend/
│   ├── **CONTEXT.md**         # Backend context (Tier 2) — create this
│   └── src/api/
│       └── **CONTEXT.md**     # API context (Tier 3) — create this
└── frontend/
    ├── **CONTEXT.md**         # Frontend context (Tier 2) — create this
    └── src/components/
        └── **CONTEXT.md**     # Components context (Tier 3) — create this
```

The scaffold provides templates for CONTEXT.md files:
- `docs/CONTEXT-tier2-component.md` - Use as template for component-level docs
- `docs/CONTEXT-tier3-feature.md` - Use as template for feature-level docs

## Configuration

The kit is designed for adaptation:

- **Skills** - Plugin skills can be extended or customized
- **Documentation** - Adjust tier structure for your architecture
- **MCP Integration** - Add additional servers for specialized expertise
- **Hooks** - Each hook plugin can be installed independently
- **MCP Assistant Rules** - Customize `MCP-ASSISTANT-RULES.md` for project-specific standards

## Best Practices

1. **Let documentation guide development** - The 3-tier structure reflects natural boundaries
2. **Update documentation immediately** - Use `/cdk-docs:update-docs` after significant changes
3. **Trust the auto-loading** - Avoid manual context management
4. **Scale complexity naturally** - Simple tasks stay simple, complex tasks get sophisticated analysis

## Documentation

- [Changelog](CHANGELOG.md) - Version history and migration guides

## Contributing

The kit represents one approach to AI-assisted development. Contributions and adaptations are welcome.

## Upgrading from v2.x

v3.0.0 replaces the template-based installer (`install.sh`/`setup.sh`) with a plugin marketplace. To upgrade:

1. **Add the marketplace**: `/plugin marketplace add drock/Claude-Code-Development-Kit`
2. **Install plugins**: See the Installation section above
3. **Your existing CLAUDE.md and docs/ are preserved** — the scaffold skill appends CDK standards rather than overwriting
4. **Update skill invocations**: Commands change from `/command-name` to `/plugin:skill` (e.g., `/code-review` becomes `/cdk-core:code-review`)
5. **Remove old files**: Delete `.claude/commands/` (CDK commands), `.claude/hooks/` (CDK hooks), and the old `settings.json` hook entries — these are now handled by plugins

## FAQ

**Q: Can I use this with other AI coding tools like Cursor, Cline, or Gemini CLI?**

**A:** Partially. The documentation structure works with any tool (rename CLAUDE.md to match your tool's convention). However, skills are highly optimized for sub-agent usage and hooks are Claude Code-specific. Other tools would need significant adaptation of the orchestration features.

**Q: How much will this cost in tokens?**

**A:** This framework uses tokens heavily due to comprehensive context loading and sub-agent usage. I strongly recommend a Claude Code Max 20x subscription over pay-per-token API usage. The Claude 4 Opus model currently performs best for complex instruction following.

**Q: Can I use other coding consultant MCPs like Zen instead for Gemini Consultation?**

**A:** While technically possible, the templates and hooks are specifically configured and optimized for my Gemini MCP server (available through the link provided in prerequisites). Using alternative coding consultant MCPs would require adjusting the skill templates and hook configurations.

**Q: Can I use this framework with an existing project?**

**A:** Yes! Run `/cdk-docs:scaffold` in your project. It safely appends CDK standards to your existing CLAUDE.md without overwriting, and creates the documentation structure alongside your existing files. To get started with an existing codebase, use Claude Code with sub-agents to understand your project and create the initial project-structure.md:

```
"Read and understand the project_structure.md template in docs/ai-context/project_structure.md. Your task is to fill out this template with our project's details. For this send out sub agents in parallel across the whole code base. Once the sub agents get back, ultrathink and create the markdown file."
```

After creating the project structure, use the documentation generation skill:

```
/cdk-docs:create-docs "[your-main-component-path]/CONTEXT.md"
```

**Q: Can I install only some plugins?**

**A:** Yes, that's the whole point! Each plugin is independent. Install `cdk-core` for just the workflow skills, `cdk-security` for just the MCP security scanning, or any combination you prefer.

**Q: What's the difference between project and user scope?**

**A:** Project scope (`--scope project`) stores the plugin config in `.claude/plugins/` so it's shared with your team via git. User scope (`--scope user`) stores it in your personal `~/.claude/` config so it applies to all your projects. Use project scope for team-shared tools and user scope for personal preferences.

## Connect

Feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/peterkrueck/) if you have questions, need clarification, or wish to provide feedback.
