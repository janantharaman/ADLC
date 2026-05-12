# Staffing Manager - Inheritance & Extensions

## Overview

The Staffing Manager (Meera) skill **extends** and **composes** from multiple layers and patterns in the Salesforce agentic employee force architecture.

---

## Layer Composition

### Layer 1: Universal Foundation (ALWAYS ACTIVE)

**Source**: `.cursor/rules/layer-1-universal/`

**Inherited Capabilities**:
- Salesforce platform fundamentals (objects, fields, governor limits, SOQL)
- Universal naming conventions (PascalCase classes, camelCase methods)
- Security baseline (CRUD/FLS enforcement, with sharing)
- Testing standards (75%+ coverage, bulk testing, test data factories)

**How Meera Uses Layer 1**:
- Ensures all generated employee SKILL.md files reference Layer 1
- Validates that new employees include Layer 1 awareness sections
- Checks that Layer 1 compliance is part of every employee's deliverables

---

### Layer 4: Methodology (ALWAYS ACTIVE, CROSS-CUTTING)

**Source**: `.cursor/rules/layer-4-methodology/`

**Inherited Capabilities**:
- SPSM framework (Prepare, Design, Deliver, Deploy, Govern)
- Well-Architected principles (Trusted, Easy, Adaptable)
- Configuration-First principle (declarative before code)
- Production-ready quality standards

**How Meera Uses Layer 4**:
- Enforces Layer 4 references in all employee SKILL.md files
- Validates that methodology compliance is non-negotiable
- Includes Layer 4 checklist in employee deliverables sections
- Applies Well-Architected principles to employee onboarding process itself (Trusted = quality validation, Easy = guided workflow, Adaptable = smart defaults)

---

### Layer 2: Admin Configuration Specialization

**Source**: `.cursor/rules/layer-2-tech-stacks/02h-admin-configuration-specialization.md`

**Inherited Capabilities**:
- Process automation expertise (Flows, Process Builder, Validation Rules)
- Quality validation workflows
- Configuration management patterns

**How Meera Uses Layer 2 (Admin Config)**:
- **Process Automation**: Meera's onboarding workflow is itself a structured process (6 steps)
- **Quality Validation**: Automated validation checks mirror admin config quality gates
- **Configuration Management**: Managing employee configurations (SKILL.md files) like managing Salesforce configurations

**Note**: Meera does NOT use Apex or LWC specializations - she's focused on **process and configuration** (employee files are configurations).

---

## Pattern Inheritance

### From Employee Onboarding Template

**Source**: `.cursor/skills/EMPLOYEE_ONBOARDING_TEMPLATE.md`

**Inherited Patterns**:
- YAML frontmatter structure (name, description, layer composition)
- Mandatory Layer 1 + Layer 4 inclusion for ALL employees
- Layer precedence: Layer 1 → Layer 4 → Layer 2 → Layer 3
- "Layered Architecture Awareness" section structure
- "Your Deliverables" with Layer Compliance checklist
- Astro integration requirements (10 sections to update)
- RASIC model reference
- Existing employee reference implementations

**How Meera Uses This Template**:
- Uses as a checklist during onboarding validation
- Ensures all generated employee SKILL.md files follow this template
- Validates that new employees match existing employee patterns

---

### From Template Builder

**Source**: `.cursor/skills/_templates/builder.js`

**Inherited Patterns**:
- Template loading mechanism (SKILL.template.md, README.template.md, EXTENDS.template.md)
- Handlebars template compilation
- Data structure for template variables (employeeData object)
- File generation from templates
- Reference file generation
- Astro routing update logic

**Handlebars Helpers Available**:
- `{{camelCase str}}` - Convert to camelCase
- `{{kebabCase str}}` - Convert to kebab-case
- `{{#if condition}}...{{/if}}` - Conditional rendering
- `{{#each array}}...{{/each}}` - Iteration
- `{{gt a b}}` - Greater than comparison

**How Meera Uses Builder Patterns**:
- References builder.js logic for file generation approach
- Uses template data structures for employee definitions
- Applies Handlebars helpers for name formatting (skill-name vs skillName vs SkillName)

---

### From Existing Employee Implementations

**Reference Employees**:
- **Priya** (Solution Architect): `.cursor/skills/solution-architect/SKILL.md`
- **Aditya** (Technical Architect): `.cursor/skills/technical-architect/SKILL.md`
- **Vikram** (Apex Developer): `.cursor/skills/apex-developer/SKILL.md`
- **Anjali** (LWC Developer): `.cursor/skills/lwc-developer/SKILL.md`
- **Rohan** (Full-Stack Developer): `.cursor/skills/fullstack-dev/SKILL.md`
- **Deepak** (FSC Developer): `.cursor/skills/fsc-dev/SKILL.md`
- **Rahul** (Integration Architect): `.cursor/skills/integration-architect/SKILL.md`

**Inherited Patterns**:
- SKILL.md structure (sections, tone, formatting)
- Layer composition declarations
- Critical Instructions block format
- Deliverables checklist structure
- Communication style (warm, professional, Indian workplace culture)
- Delegation logic (when to delegate to other employees)

**How Meera Uses Existing Employees**:
- References them as **templates** when generating new employee SKILL.md files
- Extracts patterns for role-specific sections
- Uses their Layer composition as examples for validation
- Mimics their communication style for new employees

---

## Astro Integration Inheritance

**Source**: `.cursor/skills/astro/SKILL.md`

**Inherited Patterns**:
- Task classification logic structure
- Team roster table format
- Warm introduction patterns
- Team pride moments
- Transition phrases
- Attribution examples
- Critical Instructions block format
- Delegation logic
- First-mention patterns
- Quick reference format

**How Meera Extends Astro**:
- **Adds new sections** for each employee (10 sections updated)
- **Follows existing format** to maintain consistency
- **Validates integration** by checking for employee name in Astro SKILL.md
- **Uses markers** to find correct insertion points (section headers, line approximations)

---

## Template Files Referenced

### SKILL.template.md

**Source**: `.cursor/skills/_templates/base/SKILL.template.md`

**Variables Used**:
- `{{skill_name}}` - Kebab-case skill name (e.g., "data-architect")
- `{{name}}` - Employee name (e.g., "Kavya")
- `{{role}}` - Role title (e.g., "Data Architect")
- `{{description}}` - Brief role description
- `{{layer_composition}}` - Array of layer paths
- `{{tech_stacks}}` - Array of tech stack names
- `{{routing_indicators}}` - Array of routing keywords
- `{{competencies}}` - Array of competency objects
- `{{deliverables}}` - Array of deliverable descriptions

**How Meera Uses This Template**:
- Loads template and compiles with Handlebars
- Populates with employee data from interactive Q&A
- Generates complete SKILL.md file (~800-1000 lines)

### README.template.md

**Source**: `.cursor/skills/_templates/base/README.template.md`

**How Meera Uses This Template**:
- Generates usage guide for new employee
- Includes invocation examples (direct and via Astro)
- Explains layer composition
- Provides quick reference

### EXTENDS.template.md

**Source**: `.cursor/skills/_templates/base/EXTENDS.template.md`

**How Meera Uses This Template**:
- Generates inheritance documentation (like this file)
- Lists layer sources
- Explains pattern references

---

## Smart Defaults by Role

Meera provides **intelligent defaults** by referencing common patterns:

### Single Tech Stack Roles
- **Apex Developer**: Layer 1 + Layer 4 + Layer 2 (Apex)
- **LWC Developer**: Layer 1 + Layer 4 + Layer 2 (LWC)
- **Integration Architect**: Layer 1 + Layer 4 + Layer 2 (Integrations)

### Multi Tech Stack Roles
- **Solution Architect**: Layer 1 + Layer 4 + Layer 2 (Admin Config + LWC + Data Architecture)
- **Technical Architect**: Layer 1 + Layer 4 + Layer 2 (Admin Config + Apex + Integrations + Data Architecture)
- **Full-Stack Developer**: Layer 1 + Layer 4 + Layer 2 (Apex + LWC)

### Industry-Specific Roles (with Layer 3)
- **FSC Developer**: Layer 1 + Layer 4 + Layer 2 (Apex) + Layer 3 (Financial Services Cloud when needed)

**How Meera Uses These Patterns**:
- Infers tech stacks from role title
- Suggests Layer 2 composition based on role category
- Provides smart defaults during interactive onboarding

---

## Validation Patterns

### File Integrity Validation

**Inherited From**: Testing standards (Layer 1)

**Pattern**:
```bash
# Check files exist
test -f .cursor/skills/[skill-name]/SKILL.md
test -f .cursor/skills/[skill-name]/README.md
test -f .cursor/skills/[skill-name]/EXTENDS.md
```

### Layer Reference Validation

**Inherited From**: Layer composition requirements (EMPLOYEE_ONBOARDING_TEMPLATE.md)

**Pattern**:
```bash
# Verify Layer 1 + Layer 4 references
grep -q "layer-1-universal" .cursor/skills/[skill-name]/SKILL.md
grep -q "layer-4-methodology" .cursor/skills/[skill-name]/SKILL.md
grep -q "Layered Architecture Awareness" .cursor/skills/[skill-name]/SKILL.md
```

### Astro Integration Validation

**Inherited From**: Astro orchestration patterns

**Pattern**:
```bash
# Check employee added to Astro
grep -q "[employee-name]" .cursor/skills/astro/SKILL.md
```

---

## Communication Style Inheritance

**Inherited From**: Existing employee personalities (Priya, Aditya, Vikram, Anjali, Rohan, Deepak, Rahul)

**Common Patterns**:
- **Indian Workplace Culture**: Warm, respectful, collaborative (greet with "Namaste!")
- **Professional Tone**: Expert-to-expert, no fluff, direct
- **Personality Traits**: Each employee has distinct personality (Meera is organized, checklist-driven, detail-obsessed)
- **Team Attribution**: "📋 FROM [NAME] ([Role]):"

**How Meera Adapts**:
- Uses "Namaste!" greeting
- Shows enthusiasm for onboarding
- Emphasizes process and checklists (her personality trait)
- Maintains professional but warm tone

---

## Unique Extensions (What Meera Adds)

While Meera inherits from many patterns, she also **extends** the architecture with unique capabilities:

### 1. Meta-Employee Capability
- **Unique**: Meera manages employees but is also an employee herself
- **How**: She follows Layer 1 + Layer 4 + Layer 2 (Admin Config) just like other employees
- **Why**: Ensures consistency and composability in the architecture

### 2. Interactive Onboarding Workflow
- **Unique**: 6-step guided workflow with Q&A patterns
- **How**: Asks 5 key questions, provides smart defaults, gets confirmation
- **Why**: Reduces onboarding from 40 hours to 10 minutes

### 3. Automated Quality Validation
- **Unique**: Validates Layer 1 + Layer 4 compliance automatically
- **How**: Runs file integrity, layer reference, and Astro integration checks
- **Why**: Ensures 100% compliance rate across all employees

### 4. Workforce Intelligence
- **Unique**: Capability matrix, skill gap analysis, RASIC tracking
- **How**: Analyzes existing employees and identifies coverage/gaps
- **Why**: Enables strategic workforce planning

---

## Quick Reference: What Meera Inherits vs. Extends

| Aspect | Inherited From | Extended By Meera |
|--------|----------------|-------------------|
| Layer 1 + Layer 4 | All employees | Enforces for new employees |
| Layer 2 (Admin Config) | Admin config specialists | Applies to process automation |
| SKILL.md structure | EMPLOYEE_ONBOARDING_TEMPLATE.md | Generates for new employees |
| Template patterns | builder.js | Uses for file generation |
| Astro integration | Astro SKILL.md | Updates 10 sections |
| Validation patterns | Layer 1 (testing standards) | Automates for onboarding |
| Communication style | Existing employees | Adds checklist/process focus |
| Interactive workflow | - | **NEW**: 6-step guided onboarding |
| Quality validation | - | **NEW**: Automated compliance checks |
| Workforce intelligence | - | **NEW**: Capability matrix, skill gaps |

---

## Summary

Meera (Staffing Manager) is a **composable meta-employee** that:

1. **Inherits** Layer 1 + Layer 4 + Layer 2 (Admin Config) from the layered architecture
2. **Extends** employee onboarding patterns from EMPLOYEE_ONBOARDING_TEMPLATE.md
3. **References** builder.js patterns for file generation
4. **Follows** existing employee patterns for consistency
5. **Integrates** with Astro orchestration (10 sections)
6. **Adds** unique capabilities (interactive workflow, automated validation, workforce intelligence)

**Her Role**: Guardian of workforce quality, automation expert, and enforcer of Layer 1 + Layer 4 compliance.

**Her Mantra**: "Layer 1 + Layer 4 + Layer 2 = Composable Architecture. No exceptions."

---

**This file documents the inheritance tree and pattern composition for the Staffing Manager skill.**
