---
name: scaffold
description: Set up 3-tier documentation structure and CDK standards in a target project
---

# /scaffold

*Sets up the CDK 3-tier documentation system in your project. Handles CLAUDE.md safely (append-only for existing files) and creates the full docs/ structure from templates.*

## Important Safety Rules

1. **NEVER overwrite an existing CLAUDE.md** — only append the CDK standards section
2. **Always ask before overwriting** any existing documentation file
3. **Use the Write tool** to create files in the target project
4. **Read templates** from this skill's `templates/` directory (relative to SKILL.md)

## Execution

User provided context: "$ARGUMENTS"

### Step 1: Assess the Target Project

1. **Check for existing CLAUDE.md** in the project root:
   - Read `./CLAUDE.md` (the project's file, not the CDK's)
   - Note whether it exists and what content it has

2. **Check for existing docs/ structure**:
   - Look for `docs/`, `docs/ai-context/`, `docs/open-issues/`, `docs/specs/`
   - Note which files already exist

3. **Check for existing MCP-ASSISTANT-RULES.md** in the project root

4. **Summarize findings** to the user before proceeding

### Step 2: Handle CLAUDE.md (Special — Never Overwrite)

Read the CDK standards template from `templates/cdk-claude-section.md` (bundled with this skill).

#### If CLAUDE.md does NOT exist:
1. Read the full CLAUDE.md template from `templates/CLAUDE.md`
2. Show the user a summary of what will be created
3. Create `./CLAUDE.md` using the full template
4. Tell the user to customize the placeholder sections (Project Overview, Project Structure) for their project

#### If CLAUDE.md EXISTS:
1. Read the existing `./CLAUDE.md`
2. Check if it already contains a `## CDK Development Standards` section

   **If CDK section already exists:**
   - Show the user the current CDK section vs the latest template
   - Ask if they want to update it with the latest version
   - If yes, replace the existing `## CDK Development Standards` section (and everything after it that was part of the CDK section) with the new template content

   **If no CDK section exists:**
   - Show the user what will be appended (a brief summary, not the full content)
   - Read `templates/cdk-claude-section.md`
   - Append the CDK standards section to the end of the existing CLAUDE.md
   - Confirm what was added

### Step 3: Create Documentation Structure

Create the following directory structure if it doesn't exist:
```
docs/
├── ai-context/
│   ├── project-structure.md
│   ├── docs-overview.md
│   ├── system-integration.md
│   ├── deployment-infrastructure.md
│   └── handoff.md
├── open-issues/
│   └── example-api-performance-issue.md
├── specs/
│   └── example-api-integration-spec.md
│   └── example-feature-specification.md
├── CONTEXT-tier2-component.md
├── CONTEXT-tier3-feature.md
└── MCP-ASSISTANT-RULES.md          (placed in project root, not docs/)
```

For each template file:
1. Read the template from `templates/` directory
2. Check if the target file already exists in the project
3. **If it exists**: Ask the user whether to skip, overwrite, or show a diff
4. **If it doesn't exist**: Create it using the Write tool
5. Place `MCP-ASSISTANT-RULES.md` in the **project root**, not in docs/

### Step 4: Create Tier Templates

Copy the tier template files so users have reference examples:
- `docs/CONTEXT-tier2-component.md` — Template for component-level documentation
- `docs/CONTEXT-tier3-feature.md` — Template for feature-specific documentation

These are reference templates. Users copy and customize them when adding documentation for their own components and features.

### Step 5: Summary

Provide a summary of everything that was created or modified:

```markdown
## Scaffold Complete

### CLAUDE.md
- [Created new / Appended CDK standards section / Updated existing CDK section / Skipped (already up to date)]

### Documentation Structure Created
- docs/ai-context/project-structure.md [Created / Already existed - skipped]
- docs/ai-context/docs-overview.md [Created / Already existed - skipped]
- docs/ai-context/system-integration.md [Created / Already existed - skipped]
- docs/ai-context/deployment-infrastructure.md [Created / Already existed - skipped]
- docs/ai-context/handoff.md [Created / Already existed - skipped]
- docs/open-issues/example-api-performance-issue.md [Created / Already existed - skipped]
- docs/specs/example-api-integration-spec.md [Created / Already existed - skipped]
- docs/specs/example-feature-specification.md [Created / Already existed - skipped]
- docs/CONTEXT-tier2-component.md [Created / Already existed - skipped]
- docs/CONTEXT-tier3-feature.md [Created / Already existed - skipped]
- MCP-ASSISTANT-RULES.md [Created / Already existed - skipped]

### Next Steps
1. **Customize CLAUDE.md** — Fill in the project-specific sections (Project Overview, Project Structure)
2. **Customize MCP-ASSISTANT-RULES.md** — Add your project's specific context and standards
3. **Fill in project-structure.md** — Document your actual technology stack and file tree
4. **Fill in docs-overview.md** — Update with your actual documentation files and tiers
5. **Create component docs** — Copy CONTEXT-tier2-component.md template for each major component
6. **Create feature docs** — Copy CONTEXT-tier3-feature.md template for feature-specific documentation
```

### Error Handling

- **Template not found**: If a template file can't be read from the skill's templates/ directory, inform the user and skip that file
- **Write permission denied**: Inform the user about the permission issue
- **Partial completion**: If the process is interrupted, the summary should reflect what was and wasn't completed
