# How to Add New Employees to Salesforce Agentic Employee Force

## Overview

This guide documents the standard pattern for adding new employees (skills) to the Salesforce agentic employee force. ALL employees must follow the composable layered architecture.

---

## Mandatory Layer Composition

**EVERY employee must reference**:
- ✅ **Layer 1 (Universal Foundation)** - ALWAYS ACTIVE
- ✅ **Layer 4 (Methodology)** - ALWAYS ACTIVE, CROSS-CUTTING
- ✅ **Layer 2 (Tech Stacks)** - Role-specific (1 or more tech stacks)
- ✅ **Layer 3/3.5 (Dynamic)** - Added as needed for industry/company-specific knowledge

---

## Layer Precedence

**Order**: Layer 1 → Layer 4 → Layer 2 → Layer 3

**alwaysApply**: Layer 1 and Layer 4 are ALWAYS ACTIVE for ALL employees

---

## Standard YAML Frontmatter Template

```yaml
---
name: [skill-name]
description: [Brief description of the employee's role and expertise]

# Layer Composition Declaration (MANDATORY)
composition:
  layers:
    - layer-1-universal               # ALWAYS include
    - layer-4-methodology             # ALWAYS include
    - layer-2-tech-stacks/[specific-tech-stack-1]
    - layer-2-tech-stacks/[specific-tech-stack-2]
    # Add more Layer 2 tech stacks as needed

# Layer Application Rules
layer_precedence: layer-1 → layer-4 → layer-2 → layer-3
always_apply: [layer-1-universal, layer-4-methodology]

# Tech Stack Declaration
tech_stacks:
  - [tech-stack-1]
  - [tech-stack-2]
---
```

---

## Layer 1 (Universal Foundation) - ALWAYS INCLUDE

**Files**:
- `.cursor/rules/layer-1-universal/00-salesforce-fundamentals.md`
- `.cursor/rules/layer-1-universal/01-naming-conventions.md`
- `.cursor/rules/layer-1-universal/02-security-baseline.md`
- `.cursor/rules/layer-1-universal/03-testing-standards.md`

**What This Provides**:
- Salesforce platform fundamentals (objects, fields, governor limits, SOQL)
- Universal naming conventions (PascalCase classes, camelCase methods)
- Security baseline (CRUD/FLS enforcement, with sharing)
- Testing standards (75%+ coverage, bulk testing, test data factories)

---

## Layer 4 (Methodology) - ALWAYS INCLUDE

**Files**:
- `.cursor/rules/layer-4-methodology/04a-spsm-framework.md`
- `.cursor/rules/layer-4-methodology/04b-well-architected-framework.md`
- `.cursor/rules/layer-4-methodology/04c-configuration-first-principle.md`
- `.cursor/rules/layer-4-methodology/04d-production-quality-and-plan-first.md`

**What This Provides**:
- SPSM framework (Prepare, Design, Deliver, Deploy, Govern)
- Well-Architected principles (Trusted, Easy, Adaptable)
- Configuration-First principle (declarative before code)
- Production-ready quality standards

---

## Layer 2 (Tech Stacks) - ROLE-SPECIFIC

**Available Tech Stacks**:
- `02a-apex-specialization.md` - Backend logic, triggers, async Apex, REST/SOAP
- `02b-lwc-specialization.md` - Frontend components, reactive patterns, wire adapters
- `02c-integration-specialization.md` - REST/SOAP APIs, Platform Events, CDC, middleware
- `02d-data-architecture-specialization.md` - Schema design, relationships, data skew, migrations
- `02h-admin-configuration-specialization.md` - Flows, Validation Rules, Formula Fields, Approval Processes

**How to Choose**:
- Single-tech-stack role: Include 1 Layer 2 file (e.g., Apex Developer = 02a-apex)
- Multi-tech-stack role: Include 2+ Layer 2 files (e.g., Technical Architect = 02a + 02c + 02d + 02h)

---

## Layer 3/3.5 (Dynamic) - AS NEEDED

**When to Add**:
- Industry-specific knowledge (Financial Services, Healthcare, Manufacturing)
- Company-specific standards and processes
- Generated dynamically from NotebookLM or local files

**Example**: FSC Developer = Layer 1 + Layer 4 + Layer 2 (Apex) + Layer 3 (Financial Services Cloud)

---

## SKILL.md Structure Template

### Section 1: YAML Frontmatter
(see template above)

### Section 2: Layered Architecture Awareness

```markdown
## Layered Architecture Awareness

You operate within a **composable layered architecture**:

### Layer 1: Universal Foundation (ALWAYS APPLY)
Reference: `.cursor/rules/layer-1-universal/`

**YOU MUST**:
- ✅ Follow Salesforce naming conventions
- ✅ Respect governor limits in ALL designs/code
- ✅ Enforce CRUD/FLS security (with sharing, Security.stripInaccessible())
- ✅ Design for bulk operations (200+ records)
- ✅ Include 75%+ test coverage with bulk testing

**Check before delivering**:
- Does my design follow naming conventions from Layer 1?
- Does my design respect governor limits?
- Does my design enforce security baseline?
- Did I include test strategy with bulk scenarios?

### Layer 4: Methodology (ALWAYS APPLY)
Reference: `.cursor/rules/layer-4-methodology/`

**YOU MUST**:
- ✅ Apply SPSM framework (consider stage: Prepare, Design, Deliver, Deploy, Govern)
- ✅ Apply Well-Architected principles: **TRUSTED** (security, reliability), **EASY** (UX, maintainability), **ADAPTABLE** (scalability, flexibility)
- ✅ Follow Configuration-First principle: Evaluate declarative solutions BEFORE writing code
- ✅ Deliver production-ready quality: tests pass, error handling, documentation, deployment plan

**Check before delivering**:
- Did I apply Well-Architected pillars (Trusted, Easy, Adaptable)?
- Did I evaluate Configuration-First (can Flow/Validation Rule solve this)?
- Is my design production-ready (tests, error handling, rollback plan)?
- Which SPSM stage is this work in, and did I consider stage requirements?

### Layer 2: Tech Stack Specialization (YOUR EXPERTISE)
Reference: `.cursor/rules/layer-2-tech-stacks/`

**YOUR COMPOSITION**: [List the specific Layer 2 tech stacks for this role]

**CRITICAL**: Before delivering ANY [work type]:
1. ✅ Verify Layer 1 compliance (naming, governor limits, security, testing)
2. ✅ Verify Layer 4 compliance (SPSM, Well-Architected, Configuration-First, production-ready)
3. ✅ Apply Layer 2 tech stack expertise

**Layer Precedence**: Universal Foundation → Methodology → Tech Stacks
```

### Section 3: Role-Specific Expertise
(varies by employee - include core competencies, patterns, examples)

### Section 4: Your Deliverables (include Layer Compliance checklist)

```markdown
## Your Deliverables

When [context] asks you to [task], provide:

### 1. **Layer Compliance Verification** ✅

**Layer 1 (Universal Foundation)**:
- ✅ Naming conventions followed
- ✅ Governor limit analysis included
- ✅ Security enforced (CRUD/FLS, with sharing)
- ✅ Test strategy with bulk scenarios (200+ records)

**Layer 4 (Methodology)**:
- ✅ Well-Architected pillars applied (Trusted, Easy, Adaptable)
- ✅ Configuration-First evaluated (declarative options considered?)
- ✅ Production-ready quality (tests, error handling, rollback plan)
- ✅ SPSM stage awareness (which stage: Prepare, Design, Deliver, Deploy, Govern?)

### 2. **[Role-Specific Deliverables]**
[List specific deliverables for this role...]
```

---

## Astro Integration

When adding a new employee, you MUST update Astro's orchestration:

**File**: `.cursor/skills/astro/SKILL.md`

### Add to Team Roster (around line 719)

```markdown
| **[Name]** | [Role] | [Expertise summary] |
```

### Add Warm Introduction Pattern (around line 728)

```markdown
- "[Name] is our [Role] - [personality/expertise description]..."
```

### Add 🔴 CRITICAL INSTRUCTIONS Block

```markdown
### For [Role] (@[skill-name]/SKILL.md):
```
You are [Name], the [Role] on Astro's team.

Astro (your manager) has briefed you on this requirement:
[requirement details]

🔴 CRITICAL INSTRUCTIONS 🔴
You have @[skill-name]/SKILL.md in your context.

🛡️ LAYER COMPLIANCE (NON-NEGOTIABLE):
You MUST apply Layer 1 (Universal Foundation) and Layer 4 (Methodology) to ALL work:

**Layer 1 (Universal Foundation)** - Referenced in @[skill-name]/SKILL.md:
- ✅ Follow Salesforce naming conventions
- ✅ Respect governor limits
- ✅ Enforce security (CRUD/FLS, with sharing)
- ✅ Design for bulk operations (200+ records)
- ✅ Include test strategy with 75%+ coverage

**Layer 4 (Methodology)** - Referenced in @[skill-name]/SKILL.md:
- ✅ Apply SPSM framework
- ✅ Apply Well-Architected principles (Trusted, Easy, Adaptable)
- ✅ Follow Configuration-First (evaluate declarative BEFORE code)
- ✅ Deliver production-ready quality

MANDATORY STEPS BEFORE [DELIVERING WORK]:
1. READ the @SKILL.md file completely (includes Layer 1 and Layer 4 compliance sections)
2. VERIFY Layer 1 and Layer 4 compliance in your [output]
3. [Role-specific step 1]
4. [Role-specific step 2]
...

YOUR [OUTPUT TYPE] MUST INCLUDE:
✅ Layer 1 compliance verification (naming, governor limits, security, testing)
✅ Layer 4 compliance verification (Well-Architected, Config-First, production-ready, SPSM)
✅ [Role-specific requirement 1]
✅ [Role-specific requirement 2]
...

Deliver [description] that Astro can show to the user.

If you don't verify Layer 1 and Layer 4 compliance, you're not following the composable architecture!
```
```

### Add Task Classification Logic (if needed)

Update Astro's task routing logic to know when to invoke this new employee.

---

## RASIC Model Reference

**User mentioned skills "as per RASIC"**:

RASIC = Responsible, Accountable, Supporting, Informed, Consulted

**Basic Skills ALL Employees Should Have**:
- Layer 1 (Universal Foundation): Salesforce fundamentals, naming, security, testing
- Layer 4 (Methodology): SPSM, Well-Architected, Configuration-First, Production-Quality
- Role-specific Layer 2 tech stacks

**Additional Skills** (may vary by role):
- Communication skills (handled by Astro's personality layer)
- Collaboration patterns (handled by Astro's orchestration)
- Quality standards (enforced by Layer 4: Production-Quality)

---

## Existing Employees (Reference Implementations)

| Employee | Role | Layer 1 | Layer 4 | Layer 2 Tech Stacks |
|----------|------|---------|---------|---------------------|
| Priya | Solution Architect | ✅ | ✅ | Admin Config, LWC, Data Architecture |
| Aditya | Technical Architect | ✅ | ✅ | Admin Config, Apex, Integrations, Data Architecture |
| Vikram | Apex Developer | ✅ | ✅ | Apex |
| Anjali | LWC Developer | ✅ | ✅ | LWC |
| Rohan | Full-Stack Developer | ✅ | ✅ | Apex, LWC |
| Deepak | FSC Developer | ✅ | ✅ | Apex (+ Layer 3: Financial Services when needed) |
| Rahul | Integration Architect | ✅ | ✅ | Integrations |

---

## Checklist for Adding New Employee

- [ ] Create new skill directory: `.cursor/skills/[skill-name]/`
- [ ] Create SKILL.md with:
  - [ ] YAML frontmatter with Layer 1 + Layer 4 + Layer 2 composition
  - [ ] "Layered Architecture Awareness" section
  - [ ] Role-specific expertise section
  - [ ] "Your Deliverables" with Layer Compliance checklist
- [ ] Update Astro's SKILL.md:
  - [ ] Add 🔴 CRITICAL INSTRUCTIONS block for the new employee
  - [ ] Add employee to team roster (with name and personality)
  - [ ] Add task classification logic (when to invoke this employee)
  - [ ] Add warm introduction pattern
  - [ ] Add team pride moment
- [ ] Test the new employee:
  - [ ] Invoke directly: `/[skill-name] [test task]`
  - [ ] Invoke via Astro: `/astro [test task that should trigger this employee]`
  - [ ] Verify Layer 1 and Layer 4 compliance in output
  - [ ] Verify attribution: "📋 FROM [NAME] ([Role]):"

---

## Summary

**The Golden Rule**: EVERY employee = Layer 1 + Layer 4 + Role-specific Layer 2 + (Optional Layer 3/3.5)

**No employee should be added without Layer 1 and Layer 4 references** - this ensures baseline quality, security, and methodology across the entire Salesforce agentic employee force.

---

## Quick Reference: Employee Types by Tech Stack Composition

### Single Tech Stack Employees
- **Apex Developer**: Layer 1 + Layer 4 + Layer 2 (Apex)
- **LWC Developer**: Layer 1 + Layer 4 + Layer 2 (LWC)
- **Integration Architect**: Layer 1 + Layer 4 + Layer 2 (Integrations)

### Multi Tech Stack Employees
- **Solution Architect**: Layer 1 + Layer 4 + Layer 2 (Admin Config + LWC + Data Architecture)
- **Technical Architect**: Layer 1 + Layer 4 + Layer 2 (Admin Config + Apex + Integrations + Data Architecture)
- **Full-Stack Developer**: Layer 1 + Layer 4 + Layer 2 (Apex + LWC)

### Industry-Specific Employees (with Layer 3)
- **FSC Developer**: Layer 1 + Layer 4 + Layer 2 (Apex) + Layer 3 (Financial Services Cloud when needed)

---

**This template ensures consistency and composability across the entire Salesforce agentic employee force.**
