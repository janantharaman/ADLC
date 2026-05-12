# Cursor Workflow Orchestration Tools

This directory contains tools for managing the layered architecture system.

## Available Tools

### generate-project-context.py

Generate Layer 3.5 (Project Context) rule files from project documentation.

**Purpose**: Converts project markdown files into rule files that Claude Code automatically loads, providing project-specific context to all skills.

**Usage**:

```bash
# Generate project context from markdown file
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: E-Commerce_Order_Management_System.md"

# Generate with custom output path
python .cursor/tools/generate-project-context.py \
  --input="my-project.md" \
  --output=".cursor/rules/07-active-project-context.md"

# Deactivate project context (switch to generic mode)
python .cursor/tools/generate-project-context.py --deactivate

# Force regeneration (overwrite existing)
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: MyProject.md" \
  --force

# Validate existing rule file
python .cursor/tools/generate-project-context.py --validate
```

**How It Works**:

1. **Parses** project markdown file (supports standard markdown and Program Manager Mode format)
2. **Extracts** key sections (requirements, architecture, team, phases)
3. **Generates** rule file with `alwaysApply: true` frontmatter
4. **Claude Code** automatically loads the rule in all conversations
5. **Skills** receive project context implicitly via the rule system

**Features**:

- ✅ Automatic section extraction (H1/H2 headings, ALL CAPS sections, PHASE patterns)
- ✅ Metadata detection (project name, status, team members)
- ✅ Content condensation (extracts key points, limits to important sections)
- ✅ Proper YAML frontmatter generation
- ✅ Validation checks
- ✅ Error handling

**Project Context Flow**:

```
Project Markdown File (44 KB)
         ↓
   generate-project-context.py
         ↓
Rule File: 07-active-project-context.md (1-2 KB, condensed)
         ↓
Claude Code (auto-loads via alwaysApply: true)
         ↓
Astro & All Skills (project context available)
```

**Example Output**:

```yaml
---
alwaysApply: true
projectFile: "PROJECT: E-Commerce_Order_Management_System.md"
generatedAt: "2026-03-02T14:51:31.567157"
version: "1.0"
layer: 3.5
type: project-context
projectName: "E-Commerce Order Management System"
---

# Active Project Context (Layer 3.5)

## Project Overview
- **Project**: E-Commerce Order Management System
- **Status**: Active Development
- **Team**: Backend Dev 1, Backend Dev 2, Frontend Dev 1

[Key sections extracted and condensed]
```

**Switching Projects**:

To switch from one project to another:

```bash
# Currently: Project A active
# Switch to Project B:
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: Customer_Support_Portal.md" \
  --force

# The --force flag replaces the existing 07-active-project-context.md
# New project context immediately active in next conversation
```

**Deactivating Project Context**:

To work in generic development mode (no project-specific context):

```bash
python .cursor/tools/generate-project-context.py --deactivate

# This removes 07-active-project-context.md
# Foundation rules (00-06.md) remain active
# Skills work with industry patterns and org metadata only
```

**Troubleshooting**:

**Issue**: "Extracted 0 sections"
- **Cause**: File format not recognized
- **Solution**: Ensure file uses either:
  - Standard markdown headings (# H1, ## H2)
  - ALL CAPS section headers
  - PHASE X: patterns

**Issue**: "Project name: Unknown Project"
- **Cause**: PROJECT: pattern not found
- **Solution**: Add "PROJECT: YourProjectName" somewhere in the file

**Issue**: "Output file already exists"
- **Solution**: Use `--force` flag to overwrite

**Issue**: "Rule file not loading in Claude Code"
- **Solution**: Verify frontmatter contains `alwaysApply: true`
- Run: `python .cursor/tools/generate-project-context.py --validate`

## Best Practices

1. **Keep project files updated**: Regenerate rule when project documentation changes
2. **Use descriptive project names**: Helps with context identification
3. **Include key sections**: Requirements, Architecture, Team, Sprint/Phase info
4. **Deactivate when not needed**: Switch to generic mode for non-project work
5. **Validate after generation**: Run `--validate` to ensure proper format

## Future Enhancements

- [ ] Support for multiple source formats (Jira, Confluence, NotebookLM)
- [ ] Interactive mode (prompts for project selection)
- [ ] Project registry (manage multiple projects)
- [ ] Auto-refresh (detect file changes and regenerate)
- [ ] Rich metadata extraction (go-live dates, stakeholders, dependencies)

## See Also

- [Layer 3.5 Implementation Plan](../../claude-plans/LAYER_3.5_IMPLEMENTATION_PLAN.md)
- [Layered Architecture Plan](../../claude-plans/LAYERED_ARCHITECTURE_PLAN.md)
- `.cursor/rules/layer-3-dynamic/README.md` for project context patterns
