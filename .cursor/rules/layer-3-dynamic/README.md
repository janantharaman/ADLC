# Layer 3 Dynamic & Layer 3.5 Project Context

This directory is reserved for dynamically generated context rules.

## Layer Architecture Overview

```
Layer 1: Universal Foundation (00-06.md)
         ↓
Layer 2: Tech Stack Specialization (skill-specific)
         ↓
Layer 3: Industry Context (FUTURE - dynamically generated)
         ↓
Layer 3.5: Project Context (07-active-project-context.md)
         ↓
Layer 4: Methodology (layer-4-methodology/*.md)
```

## Layer 3.5: Project Context

**Purpose**: Provide project-specific context (requirements, architecture, team, constraints) to all skills.

**Location**: `.cursor/rules/07-active-project-context.md`

**Generation**: Via `generate-project-context.py` tool

**Pattern**:
- Generated from project documentation (markdown files)
- Contains condensed project information
- Auto-loaded via `alwaysApply: true` frontmatter
- Dynamically switches between projects

### When Layer 3.5 Applies

Layer 3.5 (Project Context) is **active** when:
- `07-active-project-context.md` file exists in `.cursor/rules/`
- File contains proper frontmatter with `alwaysApply: true`
- Claude Code automatically loads it in all conversations

Layer 3.5 is **inactive** when:
- File doesn't exist (generic development mode)
- User runs `generate-project-context.py --deactivate`

### Example: Developer with Project Context

```
Morning: Working on E-Commerce Order Management
├─ Layer 1: Salesforce Foundation (✅ always active)
├─ Layer 2: Apex + LWC skills (✅ skill-specific)
├─ Layer 3.5: E-Commerce project context (✅ active)
└─ Layer 4: SPSM + Well-Architected (✅ always active)

Developer sees:
- Foundation rules (governor limits, security, testing)
- Tech stack patterns (Apex triggers, LWC lifecycle)
- PROJECT-SPECIFIC: "Order API must support 100k requests/day"
- PROJECT-SPECIFIC: "Use Stripe for payments (NOT PayPal)"
- Methodology (SPSM, Configuration-First, Quality standards)

Afternoon: Switch to Customer Support Portal
├─ Layer 1: Same ✅
├─ Layer 2: Same ✅
├─ Layer 3.5: Customer Support project context (✅ switched)
└─ Layer 4: Same ✅

Developer sees:
- Same foundation rules
- Same tech stack patterns
- PROJECT-SPECIFIC: "Support 10k cases/month, 95% SLA"
- PROJECT-SPECIFIC: "Integrate with Zendesk"
- Same methodology
```

**Key Insight**: Only Layer 3.5 changes. Everything else is reusable!

### Switching Projects

```bash
# Activate Project A
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: E-Commerce_Order_Management_System.md"

# Work on Project A...

# Switch to Project B
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: Customer_Support_Portal.md" \
  --force

# Work on Project B...

# Deactivate (generic mode)
python .cursor/tools/generate-project-context.py --deactivate
```

### How Skills Use Project Context

Skills DON'T need code changes. Project context is available automatically:

**Astro Discovery Phase**:
```
User: "Build discount approval workflow"

Astro (internal):
1. Check org via Salesforce MCP
2. Reference foundation rules (Layer 1)
3. Reference project context (Layer 3.5) ← Automatic!
4. Apply methodology (Layer 4)

Astro (to user):
"I've analyzed your request.

📋 PROJECT CONTEXT:
- Project: E-Commerce Order Management System
- Key requirement: Discounts >20% require manager approval
(From 07-active-project-context.md)

🔍 ORG VALIDATION:
✓ Opportunity object exists
✓ Discount__c field found

[Proceeds with clarifying questions...]"
```

**Apex Developer**:
```
User: "Create order REST API"

Apex Dev (internal):
1. Check project context: "Order API must support 100k requests/day"
2. Apply foundation rules: Bulkification, security
3. Apply tech patterns: REST controller, service layer
4. Apply methodology: Configuration-first check first

Apex Dev (to user):
"Based on project requirements (100k requests/day), I'll design for:
- Batch API support (handle 200 records per call)
- Async processing for heavy operations
- Response caching with Redis (per project architecture)
- Integration with SAP for inventory (per project spec)
..."
```

### Rule File Format

```yaml
---
alwaysApply: true
projectFile: "PROJECT: MyProject.md"
generatedAt: "2026-03-02T14:51:31.567157"
version: "1.0"
layer: 3.5
type: project-context
projectName: "My Project Name"
---

# Active Project Context (Layer 3.5)

## Project Overview
- **Project**: My Project Name
- **Status**: Active Development
- **Team**: Developer 1, Developer 2

## Requirements Summary
[Key requirements extracted from project file]

## Architecture Decisions
[Key architectural choices]

## Current Sprint/Phase
[Active work items]

---

## When This Context Applies
[Footer with instructions]
```

## Layer 3: Industry Context (FUTURE)

**Status**: Not yet implemented

**Purpose**: Provide industry-wide patterns (FSC, Health Cloud, etc.)

**Planned Location**: `layer-3-{industry}.md` (e.g., `layer-3-fsc.md`)

**Generation**: Via NotebookLM integration (future phase)

**Difference from Layer 3.5**:
- **Layer 3**: Industry patterns (applies to ALL projects in that industry)
- **Layer 3.5**: Project specifics (applies to THIS project only)

Example:
```
Financial Services Developer:
├─ Layer 3: FSC patterns (loan origination, KYC, compliance) ← Industry-wide
├─ Layer 3.5: Wealth Management Portal project ← Project-specific
```

## Composability Principle

The layered system allows mixing and matching:

```
Same Developer + Different Projects:
Morning:   Dev + FSC (Layer 3) + Project A (Layer 3.5)
Afternoon: Dev + FSC (Layer 3) + Project B (Layer 3.5)

Same Project + Different Developers:
Feature 1: Apex Dev + FSC + Project A
Feature 2: LWC Dev + FSC + Project A
Feature 3: Architect + FSC + Project A
```

**Key Benefits**:
- ✅ Reusable layers (no duplication)
- ✅ Dynamic switching (no retraining)
- ✅ Composable expertise (mix and match)
- ✅ Context isolation (no cross-project leakage)

## Troubleshooting

**Issue**: "Project context not loaded"
- Check: Does `07-active-project-context.md` exist?
- Check: Does frontmatter have `alwaysApply: true`?
- Run: `python .cursor/tools/generate-project-context.py --validate`

**Issue**: "Wrong project context active"
- Solution: Regenerate with correct project file
- Use `--force` flag to overwrite

**Issue**: "Want to work without project context"
- Solution: `python .cursor/tools/generate-project-context.py --deactivate`
- Foundation rules (Layer 1) remain active

## See Also

- `.cursor/tools/README.md` for generator tool documentation
- `claude-plans/LAYER_3.5_IMPLEMENTATION_PLAN.md` for implementation details
- `claude-plans/LAYERED_ARCHITECTURE_PLAN.md` for overall architecture
