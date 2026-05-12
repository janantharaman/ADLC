# Salesforce Development System for Cursor IDE

This directory contains the complete Salesforce development expert system for Cursor IDE, built with Skills-First architecture and comprehensive foundation rules.

## What's Been Implemented

### ✅ Phase 1: Apex Developer Skill + Foundation Rules
### ✅ Phase 1.5: NotebookLM Integration + Solution Architect Skill
### ✅ Phase 1.6: Agent Astro - Intelligent Orchestrator ⭐ 🆕

## Structure

```
.cursor/
├── rules/                                      # Foundation rules (always active)
│   ├── 00-salesforce-foundation.md            # Core Salesforce knowledge
│   ├── 01-salesforce-naming-conventions.md    # Naming standards
│   ├── 02-salesforce-security-baseline.md     # Security requirements
│   ├── 03-salesforce-testing-standards.md     # Testing standards (75%+ coverage)
│   ├── 04-salesforce-automation-decision-guide.md  # Flow vs Apex decisions
│   ├── 05-lwc-development-standards.md        # LWC best practices
│   └── 06-salesforce-architecture-principles.md    # Well-Architected Framework (architect.salesforce.com)
│
├── skills/
│   ├── astro/                                 # ⭐ AGENT ASTRO - PRIMARY INTERFACE (🆕)
│   │   ├── SKILL.md                           # Intelligent orchestrator persona
│   │   └── README.md                          # Usage documentation
│   │
│   ├── _shared/                               # Shared patterns for all skills
│   │   └── notebooklm-knowledge.md            # NotebookLM integration pattern
│   │
│   ├── apex-developer/                        # Apex Developer skill (✨ enhanced with NotebookLM)
│   │   ├── SKILL.md                           # Expert Apex developer persona
│   │   ├── README.md                          # Usage documentation
│   │   ├── references/                        # Reference materials
│   │   │   ├── trigger-framework-pattern.md   # Complete trigger pattern
│   │   │   ├── bulkification-examples.md      # Before/after examples
│   │   │   └── governor-limits-reference.md   # Limits quick reference
│   │   └── scripts/                           # Utility scripts
│   │       └── analyze-apex-complexity.sh     # Code analysis tool
│   │
│   ├── solution-architect/                    # Solution Architect skill
│   │   ├── SKILL.md                           # Expert architect persona (NotebookLM-first)
│   │   └── README.md                          # Usage documentation
│   │
│   └── architecture-references/               # Architecture patterns (from architect.salesforce.com)
│       ├── README.md                          # Architecture catalog
│       ├── well-architected-24-patterns.md    # All 24 Well-Architected patterns
│       └── session-security-patterns.md       # Session security patterns (7 detailed)
│
└── README.md                                  # This file
```

## Foundation Rules (Always Active)

These rules apply automatically to ALL Salesforce development work in Cursor IDE:

### 1. Salesforce Foundation (00)
**File**: `.cursor/rules/00-salesforce-foundation.md`

**Covers**:
- Platform architecture (multi-tenant, org types)
- Core data model (objects, relationships, field types)
- Automation hierarchy (declarative vs programmatic)
- Order of execution (critical for triggers)
- Security model (CRUD, FLS, sharing)
- Governor limits (per-transaction limits)
- Development lifecycle (SFDX, source control)
- API & integration patterns

**Key Points**:
- 150 SOQL queries per transaction
- 10,000 DML rows per transaction
- Always bulkify code (handle 200+ records)
- Use `with sharing` by default

### 2. Naming Conventions (01)
**File**: `.cursor/rules/01-salesforce-naming-conventions.md`

**Covers**:
- Custom objects: `PascalCase` (e.g., `Invoice__c`)
- Custom fields: `PascalCase_With_Underscores` (e.g., `Total_Amount__c`)
- Apex classes: `PascalCase` + type suffix (e.g., `AccountService`, `AccountTriggerHandler`)
- Triggers: `ObjectNameTrigger` (e.g., `AccountTrigger`)
- LWC components: `camelCase` folder, `kebab-case` in HTML
- Variables: `camelCase`, Constants: `UPPER_CASE`
- Boolean fields: `Is_`, `Has_`, `Can_` prefixes

**Quick Reference**:
```
Custom Object:    Invoice__c
Custom Field:     Total_Amount__c
Apex Class:       AccountService.cls
Trigger:          AccountTrigger.trigger
LWC Component:    accountList/
Method:           processAccounts()
Constant:         MAX_RECORDS
```

### 3. Security Baseline (02)
**File**: `.cursor/rules/02-salesforce-security-baseline.md`

**Covers**:
- Layered security model (Org → Object → Field → Record)
- CRUD/FLS enforcement in Apex
- Sharing keywords (`with sharing`, `without sharing`, `inherited sharing`)
- SOQL injection prevention (use bind variables)
- XSS prevention (escape output)
- Named Credentials for external auth
- Data encryption (Shield, Classic)

**Critical Rules**:
- Always use `with sharing` unless explicitly needed
- Check CRUD before DML: `Schema.sObjectType.Account.isCreateable()`
- Use `WITH SECURITY_ENFORCED` in SOQL
- Never concatenate user input into SOQL (use bind variables)
- Use Named Credentials (never hardcode credentials)

### 4. Testing Standards (03)
**File**: `.cursor/rules/03-salesforce-testing-standards.md`

**Covers**:
- 75% code coverage minimum (Salesforce requirement)
- Test data factory pattern
- Testing triggers (before/after, all events)
- Testing bulk scenarios (200+ records)
- Testing async Apex (@future, Queueable, Batch, Scheduled)
- Testing callouts (mock HTTP responses)
- Jest tests for LWC

**Critical Rules**:
- NEVER use `@isTest(SeeAllData=true)`
- Always test with 200+ records
- Use `Test.startTest()` and `Test.stopTest()` for async
- Use test data factories (not inline test data)
- Write meaningful assertions with messages

**Test Structure**:
```apex
@isTest
private class AccountServiceTest {
    @TestSetup
    static void setupTestData() {
        TestDataFactory.insertAccounts(200);
    }

    @isTest
    static void testBulkProcessing() {
        // Given
        List<Account> accounts = [SELECT Id FROM Account];

        // When
        Test.startTest();
        AccountService.processAccounts(accounts);
        Test.stopTest();

        // Then
        System.assertEquals(200, accounts.size(), 'Should process all accounts');
    }
}
```

### 5. Automation Decision Guide (04)
**File**: `.cursor/rules/04-salesforce-automation-decision-guide.md`

**Covers**:
- Flow vs Apex decision matrix
- Flow types (Record-Triggered, Screen, Scheduled, Autolaunched)
- When to use Flows (declarative automation)
- When to use Apex (complex logic, bulk, performance)
- Migration path (Workflow/Process Builder → Flows)
- Multi-org considerations

**Decision Matrix**:
```
Simple field update → Flow (Fast Field Update)
Create related records → Flow (After Save)
Complex multi-object logic → Apex Trigger
Process 50,000 records → Batch Apex
External callout → Queueable Apex / @future
Scheduled automation → Scheduled Flow (simple) or Apex (complex)
User-facing wizard → Screen Flow
```

### 6. LWC Development Standards (05)
**File**: `.cursor/rules/05-lwc-development-standards.md`

**Covers**:
- When to create custom LWC (vs standard components)
- Component structure and naming
- HTML best practices (Lightning base components)
- JavaScript best practices (const/let, arrow functions, getters)
- Data access patterns (@wire, imperative Apex)
- Caching and performance (lazy loading, debouncing)
- Component communication (parent-child, pub-sub)
- Error handling and lifecycle hooks
- Styling (SLDS classes, design tokens)
- Accessibility (ARIA, keyboard navigation)
- Testing (Jest)

**Key Patterns**:
```javascript
// @api - Public properties
@api recordId;

// @wire - Data from Salesforce
@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
account;

// Getters - Computed values
get hasAccounts() {
    return this.accounts && this.accounts.length > 0;
}

// Event dispatch - Child to parent
this.dispatchEvent(new CustomEvent('select', {
    detail: { recordId: selectedId }
}));
```

### 7. Salesforce Architecture Principles (06) 🆕
**File**: `.cursor/rules/06-salesforce-architecture-principles.md`

**Source**: https://architect.salesforce.com/

**Covers**:
- **Salesforce Well-Architected Framework**:
  - 🛡️ TRUSTED: Security, privacy, performance
  - 🎯 EASY: User experience, developer experience
  - 🔄 ADAPTABLE: Flexibility, scalability, composability
- **Architectural Design Patterns**:
  - Data management (MDM, archival, data skew)
  - Integration patterns (Request-Reply, Fire-and-Forget, Batch Sync)
  - Scalability patterns (tiered storage, async processing)
  - Security patterns (layered security, least privilege)
- **Domain-Specific Architecture**:
  - Sales Cloud (Lead-to-Cash process)
  - Service Cloud (Case management, multi-channel)
  - Experience Cloud (B2B/B2C commerce)
- **Performance Optimization**:
  - Query optimization (skinny tables, platform cache)
  - Integration performance (Bulk API 2.0, Composite APIs)
- **Monitoring and Observability**:
  - Key metrics, monitoring tools

**Well-Architected Framework Pillars**:
```
Every architectural decision must balance:

TRUSTED (Security & Performance)
  ✓ Encrypt sensitive data
  ✓ Implement least privilege
  ✓ Response time < 2 seconds
  ✓ Support concurrent users

EASY (Simplicity & Usability)
  ✓ Intuitive UI (minimize clicks)
  ✓ Maintainable code
  ✓ Follow SLDS standards
  ✓ Comprehensive documentation

ADAPTABLE (Flexibility & Scale)
  ✓ Configurable without code
  ✓ Support millions of records
  ✓ Modular, loosely coupled
  ✓ Handle changing requirements
```

**Integration Patterns**:
```
Request-Reply:        Real-time sync API calls
Fire-and-Forget:      Platform Events for decoupling
Batch Sync:           Nightly data synchronization
Remote Call-In:       External systems → Salesforce API
UI Update:            Real-time UI updates via Streaming API
```

**Scalability Patterns**:
```
Hot Data (0-6 months)     → Standard Objects
Warm Data (6-24 months)   → Standard Objects (indexed)
Cold Data (24+ months)    → Big Objects
Frozen Data (5+ years)    → External Storage
```

## Layer 4: Methodology (Always Active, Cross-Cutting) 🆕

Layer 4 provides methodology and quality standards that apply across ALL work.

**Location**: `.cursor/rules/layer-4-methodology/`

### 4a. SPSM Framework
**File**: `layer-4-methodology/04a-spsm-framework.md`

**Salesforce Professional Services Methodology**:
- 5 Stages: Prepare, Design, Deliver, Deploy, Govern
- 3 Swimlanes: Value Realization, Solution, Manage
- Core Values: Business outcomes first, Collaboration, Adoption

**Applies to**: All project planning and execution

### 4b. Well-Architected Framework
**File**: Rule 06 (`06-salesforce-architecture-principles.md`)

**Three Pillars**:
- **Trusted**: Security, compliance, reliability
- **Easy**: User experience, simplicity, maintainability
- **Adaptable**: Scalability, flexibility, resilience

**24 Proven Patterns** across all pillars

### 4c. Configuration-First Principle
**File**: `layer-4-methodology/04c-configuration-first-principle.md`

**Decision Framework** (evaluate in THIS order):
1. Can Flow solve this? ✅
2. Can Validation Rule solve this? ✅
3. Can Formula Field solve this? ✅
4. Can Approval Process solve this? ✅
5. Must use custom code? ❌ (only if all above are NO)

**Why**: Easier maintenance, no test coverage, faster development, less technical debt

### 4d. Production-Quality & Plan-First
**File**: `layer-4-methodology/04d-production-quality-and-plan-first.md`

**Golden Rule**: NEVER implement directly. ALWAYS plan → review → approve → implement.

**Quality Standards**:
- Tested, Professional, Secure, Scalable, Documented
- Error Handling, Maintainable
- Reflects Salesforce brand reputation

**Enforced by**: Agent Astro (non-negotiable)

---

## Layer 3.5: Project Context (Dynamic, Optional) 🆕

Layer 3.5 provides project-specific context that automatically switches between projects.

**Purpose**: Give all skills project-specific knowledge (requirements, architecture, team, constraints)

**Location**: `.cursor/rules/07-active-project-context.md`

**Generation**: Via `generate-project-context.py` tool

### How It Works

```
Project Markdown File (e.g., "PROJECT: E-Commerce_Order_Management_System.md")
         ↓
   generate-project-context.py
         ↓
Rule File: 07-active-project-context.md (auto-loaded via alwaysApply: true)
         ↓
Astro & All Skills (project context available automatically)
```

### Activate Project Context

```bash
# Generate from project file
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: E-Commerce_Order_Management_System.md"

# Project context now active in all conversations!
```

### Switch Projects

```bash
# Switch to different project
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: Customer_Support_Portal.md" \
  --force

# New project context immediately active
```

### Deactivate (Generic Mode)

```bash
# Work without project-specific context
python .cursor/tools/generate-project-context.py --deactivate

# Foundation rules (Layer 1) remain active
```

### Example: Developer with Project Context

**Morning** - Working on E-Commerce Order Management:
- Layer 1: Foundation ✅
- Layer 2: Apex + LWC skills ✅
- **Layer 3.5: E-Commerce project** ✅ ← PROJECT-SPECIFIC
  - "Order API must support 100k requests/day"
  - "Use Stripe for payments (NOT PayPal)"
  - "Integrate with SAP for inventory"
- Layer 4: Methodology ✅

**Afternoon** - Switch to Customer Support Portal:
- Layer 1: Same ✅
- Layer 2: Same ✅
- **Layer 3.5: Customer Support project** ✅ ← SWITCHED!
  - "Support 10k cases/month, 95% SLA"
  - "Integrate with Zendesk"
  - "Einstein chatbot for FAQs"
- Layer 4: Same ✅

**Key Insight**: Only Layer 3.5 changes. Everything else is reusable!

### Composability Principle

```
Same Developer + Different Projects:
Morning:   Apex Dev + Project A context
Afternoon: Apex Dev + Project B context

Same Project + Different Developers:
Feature 1: Apex Dev + Project A
Feature 2: LWC Dev + Project A
Feature 3: Architect + Project A
```

**See Also**:
- `.cursor/tools/README.md` - Generator tool documentation
- `.cursor/rules/layer-3-dynamic/README.md` - Project context patterns
- `claude-plans/LAYER_3.5_IMPLEMENTATION_PLAN.md` - Implementation details

---

## ⭐ Agent Astro: Your Intelligent Guide (NEW)

### Overview
**Agent Astro** is the intelligent orchestrator that serves as your **primary interface** for Salesforce development. Named after Salesforce's beloved mascot, Astro provides a friendly, approachable way to build production-quality solutions.

### Why Use Astro?
- ✅ **No skill selection needed**: Just describe what you want
- ✅ **Intelligent routing**: Astro invokes the right expert(s) automatically
- ✅ **Plan-first workflow**: Always creates plan → gets approval → implements
- ✅ **Quality enforced**: Production-ready solutions, no shortcuts
- ✅ **Coordination handled**: Manages multiple experts for complex tasks

### Quick Start
```bash
/astro "your requirement here"
```

**Examples**:
```bash
/astro "Prevent duplicate Account names"
/astro "Design a customer portal"
/astro "Build discount approval workflow"
/astro "JIRA-1234"
/astro "@requirements.md"
```

### What Astro Does
1. **Analyzes** your requirement (natural language, Jira, MD files)
2. **Asks** clarifying questions
3. **Creates** detailed plan
4. **Waits** for your approval 🔒 (non-negotiable)
5. **Coordinates** appropriate expert skills
6. **Delivers** production-quality solution

### Astro Routes To:
| Task Type | Expert Skill | Example |
|-----------|-------------|---------|
| Architecture/Design | `/architect` | "Design customer portal" |
| Backend Development | `/apex-dev` | "Create trigger for Accounts" |
| Complex (Both) | `/architect` → `/apex-dev` | "Build order system" |

**Coming Soon**: `/admin`, `/lwc-dev`, `/qa`, `/pm`

### Plan-First Philosophy 🔒
**Non-negotiable**: Astro ALWAYS creates a plan and gets your approval before implementing.

**Why?**
- Ensures production quality
- You stay in control
- Saves time by avoiding rework
- Protects Salesforce brand reputation

**Workflow**:
```
Requirement → Analyze → Question → Plan → YOUR APPROVAL → Implement → Deliver
```

### Astro vs. Direct Skills

**Use `/astro` (Recommended for most users)**:
- Not sure which expert to use
- Want guidance on best approach
- Want plan-first workflow enforced
- Complex requirement needing coordination

**Use skills directly (For experts)**:
- Know exactly what you need
- Quick, targeted change
- Want to skip orchestration

---

## 🆕 NotebookLM Integration

### Overview
The system now features **dynamic knowledge retrieval** from NotebookLM notebooks containing Well-Architected patterns, accessibility standards, and security patterns.

**Approach**: NotebookLM-First (with fallback)
```
Try: Query NotebookLM for latest patterns
  ↓
If unavailable: Use built-in foundation rules
  ↓
Result: Expert guidance EITHER WAY (no dependency)
```

### Available Knowledge
**Notebook**: Salesforce Well-Architected: Accessibility & Testing
- Accessibility Data Entry Pattern (multi-device, translations, testing)
- Accessibility Navigation Pattern (keyboard, ARIA, visual cues)
- Session Security Patterns (MFA, SSO, threat detection)
- Anti-patterns to avoid

### Shared Pattern
**File**: `.cursor/skills/_shared/notebooklm-knowledge.md`

All skills can query NotebookLM using this reusable pattern. Future skills (LWC Developer, QA Engineer) will leverage the same approach.

## Skills

### 1. Apex Developer Skill ✨ (Enhanced with NotebookLM)

#### Usage
In Cursor IDE, invoke the skill:
```
/apex-dev
```

Then provide your Apex development task:
```
"Create a trigger to prevent Account deletion if it has open Opportunities"
"Implement a batch job to process 100K Account records"
"Build a REST API endpoint for Order management"
"Create an accessible form with multi-language support" (🆕 uses NotebookLM)
```

#### What It Provides
- Expert Apex developer persona (10+ years experience)
- Trigger handler framework with bulkification
- Service layer and selector patterns
- Governor limits optimization
- Security best practices (CRUD/FLS)
- Testing patterns (75%+ coverage)
- Async Apex patterns (@future, Queueable, Batch)
- 🆕 **NotebookLM Integration**: Queries for accessibility and security patterns when needed

### Reference Materials
- **trigger-framework-pattern.md**: Complete implementation with base class, handler, service layer
- **bulkification-examples.md**: 6 detailed before/after examples showing proper bulkification
- **governor-limits-reference.md**: Comprehensive tables of all Salesforce limits

#### Reference Materials
- **trigger-framework-pattern.md**: Complete implementation with base class, handler, service layer
- **bulkification-examples.md**: 6 detailed before/after examples showing proper bulkification
- **governor-limits-reference.md**: Comprehensive tables of all Salesforce limits

#### Utility Script
```bash
# Analyze Apex code complexity
./.cursor/skills/apex-developer/scripts/analyze-apex-complexity.sh force-app
```

This script:
- Installs PMD if not present
- Analyzes all Apex code for complexity, security, and performance
- Checks for anti-patterns (SOQL in loops, DML in loops, hardcoded IDs)
- Provides recommendations

---

### 2. Solution Architect Skill 🆕 (NotebookLM-First)

#### Usage
In Cursor IDE, invoke the skill:
```
/architect
```

Then provide your architectural design task:
```
"Design a high-volume case management system for 100K+ cases per month"
"Review this B2B commerce portal architecture"
"Design accessible customer onboarding that meets WCAG 2.1 AA"
"Design real-time integration with external ERP for order sync"
```

#### What It Provides
- Expert Salesforce Solution Architect persona (12+ years experience)
- **Well-Architected Framework expertise**: TRUSTED, EASY, ADAPTABLE pillars
- **NotebookLM-First approach**: Queries for latest patterns, falls back to built-in knowledge
- Architectural decision-making with trade-off analysis
- Pattern selection from Well-Architected catalog (24 patterns)
- Accessibility compliance design
- Security architecture (authentication, authorization, compliance)
- Scalability patterns (high volume, growth planning)
- Integration architecture (APIs, events, middleware)
- Implementation roadmap with phased approach

#### When It Queries NotebookLM
- Every architectural decision (accessibility, security, scalability)
- Before proposing solution design
- When validating against anti-patterns
- When defining testing strategy

#### Fallback Strategy
If NotebookLM unavailable:
- Uses built-in Well-Architected knowledge (rule 06)
- Uses accessibility guidance (rule 05)
- Uses security patterns (rule 02)
- References architecture patterns (24 documented patterns)
- **Result**: Expert guidance regardless of NotebookLM access

#### Output Format
- Architecture proposal with Well-Architected analysis
- NotebookLM patterns applied (or foundation rules if unavailable)
- Trade-offs and decisions documented
- Anti-patterns validated against
- Implementation sequence with risks/mitigations

## How It Works

### Foundation Rules (Always Active)
All rules in `.cursor/rules/` are configured with `alwaysApply: true` in their YAML frontmatter. This means:
- They're automatically loaded for every Cursor session
- They provide baseline knowledge across all interactions
- They guide all code generation and suggestions

### Skills (Explicitly Invoked)
Skills in `.cursor/skills/` are invoked explicitly with slash commands (e.g., `/apex-dev`):
- Provides specialized expert persona
- Deep domain expertise for specific roles
- References to detailed patterns and examples
- Delegation guidance to other roles

### Example Workflow
```
1. User asks: "Create a trigger to update related Contacts"

2. Foundation Rules provide:
   - Trigger naming convention (AccountTrigger)
   - Security requirements (with sharing, CRUD/FLS)
   - Testing requirements (75% coverage, bulk testing)
   - Bulkification requirements (handle 200+ records)

3. User invokes: /apex-dev

4. Apex Developer Skill provides:
   - Trigger handler pattern
   - Bulkified service layer implementation
   - Test class with 200+ records
   - Governor limit considerations
   - Best practices specific to triggers

5. Result: Production-ready code following all standards
```

---

## Next Steps

### Phase 2: Additional Skills (In Progress)
1. **LWC Developer** (`/lwc-dev`) - Lightning Web Components specialist (will use NotebookLM pattern)
2. ✅ **Solution Architect** (`/architect`) - COMPLETE
3. **QA Engineer** (`/qa`) - Test planning and automation (will use NotebookLM pattern)
4. **Program Manager** (`/pm`) - SPSM methodology, project coordination

### Phase 3: MCP Server Integration
- Configure Salesforce MCP server for real-time org metadata access
- Enable SOQL queries, test coverage checks, deployment tools

### Phase 4: Company-Specific Customization
- Add company-specific coding standards
- Incorporate team conventions
- Add industry-specific patterns

## Testing the System

### Test the Foundation Rules
1. Open any file in Cursor
2. Ask: "How should I name a custom field for total amount?"
3. Verify response follows naming convention rule

### Test the Apex Developer Skill
1. Invoke: `/apex-dev`
2. Ask: "Create a trigger to prevent Account deletion with open Opportunities"
3. Verify response includes:
   - Trigger handler pattern
   - Bulkified logic
   - Test class with 200+ records
   - CRUD/FLS checks

### Test Agent Astro ⭐ 🆕
1. Invoke: `/astro`
2. Say: "Prevent duplicate Account names"
3. Verify Astro:
   - Analyzes requirement
   - Creates plan (Validation Rule)
   - Waits for your approval
   - Delivers setup guide
4. Try complex: `/astro "Design and build customer portal"`
5. Verify Astro coordinates `/architect` then `/apex-dev`

### Test the Solution Architect Skill
1. Invoke: `/architect`
2. Ask: "Design a customer portal with accessibility compliance"
3. Verify response includes:
   - Well-Architected analysis (TRUSTED, EASY, ADAPTABLE)
   - NotebookLM patterns applied (or foundation rules if unavailable)
   - Accessibility patterns for data entry and navigation
   - Trade-offs documented
   - Implementation roadmap

### Run Code Analysis
```bash
cd /Users/ronit.mukherjee/projects/cursor_workflow_orchestartion

# Analyze Apex code
./.cursor/skills/apex-developer/scripts/analyze-apex-complexity.sh force-app
```

## Resources

### Created Files
- **7 Foundation Rules** (132KB total): Always-active Salesforce knowledge
- **3 Skills** (Astro Orchestrator + Apex Developer + Solution Architect): Intelligent coordination and expert implementation
- **3 Architecture References** (109KB total): Well-Architected patterns from architect.salesforce.com
- **1 Shared Pattern** (NotebookLM integration): Reusable for all skills
- **1 Code Analysis Script**: Automated quality checks

### Documentation Generated
- Main README (this file - updated for Agent Astro)
- Agent Astro README (new - primary interface guide)
- Apex Developer README (updated with NotebookLM capabilities)
- Solution Architect README
- NotebookLM Integration Summary
- Shared NotebookLM Knowledge Pattern
- Architecture References README
- Implementation Summary
- Complete reference materials with code examples

### Total Knowledge Base
- **~320KB+ of curated Salesforce expertise**
- **20 comprehensive documents** (includes Agent Astro files)
- **12,000+ lines of architectural guidance**
- **Built from official Salesforce documentation**:
  - **architect.salesforce.com** - Well-Architected Framework, accessibility patterns, session security
  - **NotebookLM** - Dynamic pattern retrieval (when available)
  - **Salesforce Astro Mascot** - Inspiration for friendly, approachable orchestration
  - Architect Standards Document (PDF)
  - LWC Best Practices (PDF)
  - Salesforce Developer Documentation
  - Trailhead best practices

## Benefits

### For Developers
- **Consistent code quality**: All code follows Salesforce best practices
- **Faster development**: Expert patterns and examples at your fingertips
- **Learning resource**: Comprehensive reference materials
- **Reduced errors**: Automated checks for common anti-patterns

### For Teams
- **Standardized approach**: Everyone follows same conventions
- **Knowledge sharing**: Documented best practices
- **Easier onboarding**: New developers learn correct patterns
- **Code review efficiency**: Standards are documented and enforced

### For Projects
- **Production-ready code**: Security, testing, performance built-in
- **Maintainability**: Consistent naming, structure, documentation
- **Scalability**: Bulkification and governor limit awareness
- **Compliance**: Security and testing standards met

## Available Skills

### Primary Interface ⭐
- **`/astro`** - Agent Astro (Intelligent Orchestrator) 🆕
  - **RECOMMENDED**: Start here for most tasks
  - Analyzes requirements and routes intelligently
  - Enforces plan-first workflow
  - Coordinates multiple experts

### Expert Skills (Direct Invocation)
- `/apex-dev` - Apex Developer (backend logic, triggers, batch jobs)
- `/architect` - Solution Architect (Well-Architected design, patterns, decisions)

### Coming Soon:
- `/admin` - Admin Configurator (Flows, Validation Rules, Formulas)
- `/lwc-dev` - LWC Developer (Lightning Web Components)
- `/qa` - QA Engineer (Test planning and automation)
- `/pm` - Program Manager (SPSM methodology)

## Getting Started

### For Most Users (Recommended) ⭐
**Use Agent Astro** - Your intelligent guide:
```
/astro "what you want to build"
```

Astro will:
- Understand your requirement
- Ask clarifying questions
- Create a plan for your approval
- Coordinate the right experts
- Deliver production-quality solution

### For Expert Users
**Use skills directly** when you know exactly what you need:
```
/architect "design request"
/apex-dev "implementation request"
```

## Support

For questions or issues:
1. **Start with Astro**: `/astro "your question"` - Astro will route appropriately
2. Check the reference materials in `.cursor/skills/*/references/`
3. Review the foundation rules in `.cursor/rules/`
4. Check NotebookLM integration guide in `.cursor/skills/_shared/notebooklm-knowledge.md`
5. Consult official Salesforce documentation
6. Invoke specific skills: `/astro`, `/apex-dev`, or `/architect`

## License

This system is built on official Salesforce documentation and best practices. Use it to build amazing Salesforce applications!
