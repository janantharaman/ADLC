# ADLC — Agent-Assisted Delivery Lifecycle
**GDC Professional Services | Salesforce Delivery Framework**

ADLC is a Claude Code–powered delivery framework for Salesforce professional services engagements. It guides architects, developers, and QA engineers through structured delivery phases — from Discovery to Deployment — using AI-assisted tooling, a grounded knowledge base, and enforced human approval gates.

---

## How It Works

ADLC runs inside [Claude Code](https://claude.ai/code) (the CLI). When you open this repository in Claude Code, `CLAUDE.md` is automatically loaded as the agent's system instructions. From there, you start an engagement with a simple command:

```
Start ADLC for [Customer Name]
```

The agent:
1. Creates an engagement folder under `engagements/{customer}/`
2. Runs each delivery phase in sequence, reading the previous phase's artifact before starting
3. Writes a markdown artifact at the end of every phase
4. Stops at `[WAITING_FOR_APPROVAL]` — it will not advance until you respond `APPROVED`
5. Maintains memory across sessions via `core-memory.md` and `workflow-memory.md`

All Salesforce org operations go through **Headless 360** (`@salesforce/mcp`) — no direct CLI or REST calls.

---

## Repository Structure

```
/CLAUDE.md                          ← Agent runtime instructions (always loaded by Claude Code)
/.mcp.json                          ← Headless 360 MCP server config — update with your org alias
/README.md                          ← This file

/skills/                            ← Phase-specific procedural knowledge
  pre-sales/SKILL.md                ← Phase 0: scoping, SOW inputs, effort estimation
  discovery/SKILL.md                ← Phase 1: org health baseline, security audit, gap analysis
  design/SKILL.md                   ← Phase 2: solution design, data model, automation design
  implementation/SKILL.md           ← Phase 3: build guidance, code review, metadata deployment
  testing/SKILL.md                  ← Phase 4: test planning, Apex test execution, agent testing
  deployment/SKILL.md               ← Phase 5: go-live checklist, cutover, hypercare
  retrofit/SKILL.md                 ← Out-of-band: technical debt remediation, migration patterns
  {phase}/references/               ← Supporting reference docs per phase

/knowledge/                         ← Grounded reference knowledge base (platform-wide)
  naming-conventions.md             ← Salesforce naming standards — loaded at every phase
  security-baseline.md              ← Security and Well-Architected baseline — loaded for D/D/I/Dep
  governor-limits.md                ← Apex and platform limits — loaded for Implementation + Testing
  sdd-template.md                   ← Solution Design Document template
  omnistudio.md                     ← OmniStudio platform reference (720 lines, Apex Hours series)
  agentforce/                       ← Agentforce platform (8 files — see below)
  clouds/                           ← Industry cloud knowledge (11 clouds, 84 files)
    {cloud-name}/
      overview.md                   ← What it is, when to use it, license types, feature domains
      data-model.md                 ← Objects, fields, relationships, SOQL patterns, load order
      security-model.md             ← OWD defaults, sharing rules, permission sets, platform security
      automation-patterns.md        ← Flows, Apex, invocable actions, platform events, OmniStudio
      gotchas.md                    ← Known issues, deployment traps, undocumented behaviours
      api-reference.md              ← SOQL patterns, REST/SOAP endpoints, Apex class signatures
      implementation-guide.md       ← Step-by-step setup, prerequisites, activation sequences
      metadata-tooling.md           ← Metadata types, package.xml patterns, CI/CD considerations

/engagements/                       ← Per-customer engagement artifacts
  _template/                        ← Blank engagement folder structure (copy to start new engagement)
  {customer-name}/
    discovery.md                    ← Phase 1 artifact (DRAFT → APPROVED)
    design.md                       ← Phase 2 artifact
    impl-summary.md                 ← Phase 3 artifact
    testing.md                      ← Phase 4 artifact
    deployment.md                   ← Phase 5 artifact
    evaluation/                     ← Phase gate evaluation JSON files
    memory/
      core-memory.md                ← Permanent org facts — persists across sessions
      workflow-memory.md            ← Running session log — cleared after each phase gate
      daily-memory.md               ← One-line entry per completed phase
    docs/
      index.md                      ← Customer document index (always read first)
      *.pdf / *.md                  ← Customer-provided reference documents
```

---

## Delivery Phases

### Full Pipeline
For new implementations or changes affecting more than 3 objects or 5 user stories.

| Phase | Artifact | Gate |
|---|---|---|
| 0 — Pre-Sales *(optional)* | `pre-sales.md` | WAITING_FOR_APPROVAL |
| 1 — Discovery | `discovery.md` | WAITING_FOR_APPROVAL |
| 2 — Design | `design.md` | WAITING_FOR_APPROVAL |
| 3 — Implementation | `impl-summary.md` | WAITING_FOR_APPROVAL |
| 4 — Testing | `testing.md` | WAITING_FOR_APPROVAL |
| 5 — Deployment | `deployment.md` | — |

Each phase reads the previous phase's artifact before starting. The agent will not advance past a gate without an explicit `APPROVED` response.

### Quick Delivery
For bounded changes: single user stories, minor config extensions, bug fixes with known root cause.

```
Task 1: Assess    → [WAITING_FOR_APPROVAL]
Task 2: Implement → [WAITING_FOR_APPROVAL]
Task 3: Verify
Task 4: Document
```

Quick Delivery criteria — **all must be true:** change is additive; ≤3 objects and ≤2 automation paths affected; no integration endpoints affected; Discovery and Design artifacts already exist.

---

## Knowledge Base

### Generic / Cross-Cloud (`knowledge/`)

| File | Content |
|---|---|
| `naming-conventions.md` | Object, field, class, LWC, flow naming standards |
| `security-baseline.md` | OWD defaults, CRUD/FLS, sharing, permission set patterns |
| `governor-limits.md` | SOQL, DML, CPU, heap, callout limits with Apex patterns |
| `sdd-template.md` | Solution Design Document template |
| `omnistudio.md` | OmniScript, FlexCard, DataRaptor, Integration Procedure, IDX Workbench |

### Agentforce Platform (`knowledge/agentforce/`) — 8 files

Full coverage of the Agentforce developer platform, scoped to the Agentblazer Champion → Innovator → Legend curriculum:

| File | Content |
|---|---|
| `overview.md` | Platform architecture, agent types, Trust Layer, Einstein Requests, badge curriculum map |
| `data-model.md` | Metadata types (Bot, BotVersion, GenAiFunction, GenAiPlugin, GenAiPlannerBundle, AiAuthoringBundle, AiEvaluationDefinition), Lightning Types schema, Citations data model |
| `security-model.md` | Einstein Trust Layer components, agent user setup, permission requirements, BYOLLM security |
| `automation-patterns.md` | Invocable actions, Models API Apex, Agent Script syntax, Lightning Types, multi-agent orchestration, Citations pattern |
| `gotchas.md` | 16 documented gotchas including topics→subagents rename (April 2026), Python SDK variable limits, LLM test quota consumption |
| `api-reference.md` | Agent API REST (3 endpoints), Models API full Apex class reference, Testing Connect API, Citations Apex classes, Python SDK class reference |
| `implementation-guide.md` | Agentblazer learning progression, 5-phase build guide, Agentforce DX 9-step CLI workflow, mobile SDK setup |
| `metadata-tooling.md` | All 7 metadata types with XML samples, YAML spec field reference, full package.xml template, deployment order, CI/CD considerations |

### Industry Clouds (`knowledge/clouds/`) — 11 clouds, 84 files

Each cloud has 8 standard files: `overview`, `data-model`, `security-model`, `automation-patterns`, `gotchas`, `api-reference`, `implementation-guide`, `metadata-tooling`.

| Cloud | Source | Key Content |
|---|---|---|
| Financial Services Cloud | FSC Dev Guide (1396p, Spring '26) | FinancialDeal family, BranchUnit, Referral API, Compliant Data Sharing, IndustriesSettings 35-feature activation |
| Experience Cloud | Communities Guide (818p, Spring '26) | Site templates, guest user security, CMS, Aura/LWC in Experience, metadata deployment |
| Health Cloud | Health Cloud Dev Guide (2300p, Spring '26) | 34 feature domains, FHIR R4/HL7, OmniStudio Assessments, FSL Home Health, 16 invocable actions |
| Service Cloud | Service Cloud Dev Guide (1374p) + 17 supplemental PDFs | Chat, Omni-Channel, CTI, Entitlements, Voice, Knowledge, Embedded Service, Mobile SDK |
| Sales Cloud | Sales Cloud Basics (603p, Spring '26) | Opportunity management, forecasting, CPQ basics, Einstein Sales |
| Manufacturing Cloud | Mfg Cloud Dev Guide (605p, Spring '26) | Account-based forecasting, rebates, warranty management |
| Revenue Cloud | Revenue Lifecycle Mgmt Dev Guide (2373p, Spring '26) | CPQ, billing, revenue recognition, subscription management |
| Automotive Cloud | Automotive Cloud Dev Guide (425p, Spring '26) | Vehicle records, dealer management, warranty, driver 360 |
| Telecommunications Cloud | CME Dev Guide (2822p, Spring '26) | B2B + B2C Telco, product catalog, order management |
| Life Sciences Cloud | LSC Dev Guide (1869p, Spring '26) | 4 engagement domains (Clinical/Customer/Patient/MedTech), FHIR R4, Business APIs |
| Consumer Goods Cloud | CGC Dev Guide (1840p, Spring '26) | cgcloud + cgc_sync namespaces, Retail Execution, TPM, Sync Management, RE_Order Apex, orderExtensionUtils LWC |

See `knowledge-map.html` for a visual index of all grounded knowledge files.

---

## Memory System

The agent maintains three memory files per engagement:

| File | Purpose | Lifecycle |
|---|---|---|
| `core-memory.md` | Permanent org facts: trigger patterns, naming conventions, known tool failures, customer preferences | Written after each phase gate approval; never auto-cleared |
| `workflow-memory.md` | Running session log: tool results, decisions, workarounds, observations | Appended continuously during a session; cleared after memory consolidation |
| `daily-memory.md` | One-line log: date, phase completed, key outcome | Appended after each phase gate approval; never cleared |

**Memory consolidation** happens after every phase gate approval: the agent reads `workflow-memory.md`, promotes durable learnings to `core-memory.md`, then resets `workflow-memory.md`.

When resuming an engagement in a new session, always read `core-memory.md` first — it contains everything the agent needs to pick up where it left off.

---

## Skills

Each `skills/{phase}/SKILL.md` is the procedural specification for that phase. The agent reads it at the start of the phase and follows it exactly.

| Skill | Covers |
|---|---|
| `pre-sales` | Scoping, effort estimation, SOW inputs, risk identification |
| `discovery` | Org health baseline (objects, Apex, flows, LWC, security), gap analysis, open questions |
| `design` | Solution architecture, data model decisions, automation design, security model |
| `implementation` | Build sequencing, code review checklists, metadata deployment, governor limit guidance |
| `testing` | Test planning, Apex test execution, Agentforce agent testing, UAT coordination |
| `deployment` | Go-live checklist, cutover plan, rollback procedure, hypercare monitoring |
| `retrofit` | Technical debt assessment, migration patterns, refactoring guidance |

---

## Setup

### Prerequisites
- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) v2.x installed
- [Headless 360](https://www.npmjs.com/package/@salesforce/mcp) (`@salesforce/mcp`) installed: `npm install -g @salesforce/mcp`
- A Salesforce org authenticated via `sf org login web --alias YOUR_ORG_ALIAS`

### Configure Your Org

Edit `.mcp.json` and replace `YOUR_ORG_ALIAS` with your authenticated org alias:

```json
{
  "mcpServers": {
    "salesforce": {
      "command": "npx",
      "args": ["@salesforce/mcp", "--orgs", "YOUR_ORG_ALIAS", "--toolsets", "all"]
    }
  }
}
```

### Start an Engagement

Open this repository in Claude Code and run:

```
Start ADLC for [Customer Name]
```

To resume:

```
Continue [Customer Name] engagement
```

---

## Evaluation Rubric

Every phase gate is scored out of 100:

| Category | Points |
|---|---|
| Structure & Completeness | 15 |
| Safety & Security | 15 |
| Deterministic Logic | 20 |
| Requirements Coverage | 20 |
| Well-Architected Alignment | 10 |
| Action / Tool Configuration | 10 |
| Deployment Readiness | 10 |

Score ≥ 80: PASS. Score 60–79: issues flagged, user decides. Score < 60: FAIL — must revise before advancing.

Results written to `engagements/{customer}/evaluation/{phase}-evaluation.json`.

---

*ADLC for Salesforce — GDC Professional Services — v2 — Spring 2026*
