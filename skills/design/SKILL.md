# SKILL: Design
**Phase:** 2 of 6
**Prerequisite artifact:** `engagements/{customer}/discovery.md` (status: APPROVED)
**Output artifact:** `engagements/{customer}/design.md`
**Evaluation output:** `engagements/{customer}/evaluation/design-evaluation.json`

---

## Purpose

Produce a complete technical design that a developer can implement without ambiguity. Every architectural decision made in this phase must be backed by a Well-Architected citation or a decision guide recommendation from the references in this skill.

You are not building anything in this phase. You are designing, deciding, and documenting — so that Implementation has no open questions.

All Salesforce operations use Headless 360 MCP tools exclusively. Never use Bash or the sf CLI for org operations.

---

## Before You Start

1. Read `engagements/{customer}/memory/core-memory.md` — load org constraints and customer preferences
2. Read `engagements/{customer}/discovery.md` in full — every design decision must trace to a discovery finding or requirement
3. Read `knowledge/naming-conventions.md`
4. Read `knowledge/security-baseline.md`
5. Read the relevant Well-Architected references for the scope of this engagement:
   - `skills/design/references/wa-framework/overview.md` — always
   - `skills/design/references/wa-framework/secure.md` — always (security is non-negotiable)
   - `skills/design/references/wa-framework/reliable.md` — for any automation or integration work
   - `skills/design/references/wa-framework/composable.md` — for any LWC or integration work
6. For automation decisions, read the relevant decision guide:
   - `skills/design/references/decision-guides/record-triggered.md` — record-triggered automation
   - `skills/design/references/decision-guides/async-processing.md` — async/background work
   - `skills/design/references/decision-guides/event-driven.md` — platform events and CDC
   - `skills/design/references/decision-guides/data-integration.md` — integration patterns
7. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first, then read any documents marked as relevant to Design (requirements specs, approved SOW, integration API docs, data migration specs, UI mockups).
   Also read `knowledge/sdd-template.md` — this is the GDC standard Solution Design Document structure. Every section of the `design.md` artifact must correspond to a section of the SDD. If the engagement requires a client-deliverable SDD Word document, the `design.md` is the source of truth that maps 1:1 to the SDD layers.
8. **Cloud-Specific Context:** Check `core-memory.md` for the cloud(s) in scope. If the engagement is on a specific cloud, additionally load the relevant cloud primer:
   - Sales Cloud → `knowledge/clouds/sales-cloud/*.md`
   - Service Cloud → `knowledge/clouds/service-cloud/*.md`
   - Experience Cloud → `knowledge/clouds/experience-cloud/*.md`
   - Consumer Goods Cloud → `knowledge/clouds/consumer-goods-cloud/*.md`
   - Life Sciences Cloud → `knowledge/clouds/life-sciences-cloud/*.md`
   - Financial Services Cloud → `knowledge/clouds/financial-services-cloud/*.md`
   - Health Cloud → `knowledge/clouds/health-cloud/*.md`
   - Revenue Cloud → `knowledge/clouds/revenue-cloud/*.md`
   - Automotive Cloud → `knowledge/clouds/automotive-cloud/*.md`
   - Manufacturing Cloud → `knowledge/clouds/manufacturing-cloud/*.md`
   Load all cloud primers that apply — engagements often span multiple clouds.
9. Confirm the org alias with the user before running any queries
10. Append to `workflow-memory.md`: session start, phase, key discovery findings driving design
11. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files or cloud primers (e.g., exact field API name, version-specific behaviour, pattern not in the WA tools), use `WebSearch` before making an assumption. Prefer results from `trailhead.salesforce.com`, `help.salesforce.com`, `developer.salesforce.com`, and `github.com/trailheadapps`. Do not guess — search first.

---

## Step 1 — Data Model Design

For each object in scope from the discovery requirements:

**Tool:** `mcp__salesforce__run_soql_query`

Check existing object definition:
```sql
SELECT QualifiedApiName, Label, ExternalSharingModel, InternalSharingModel
FROM EntityDefinition
WHERE QualifiedApiName = '{ObjectAPIName}'
```

For each object, design:
- New custom fields needed (API name per `knowledge/naming-conventions.md`, type, required flag, description)
- New custom objects needed (API name, label, sharing model)
- Lookup/Master-Detail relationships (document parent-child, cascade delete implications)
- Record types (if business process variance requires them)
- Validation rules (name, error condition, error message, active on deploy)

Apply Well-Architected guidance:
- Refer to `skills/design/references/wa-framework/reliable.md` for data integrity decisions
- Sharing model must be validated against `knowledge/security-baseline.md` — no Public Read/Write on sensitive objects

---

## Step 2 — Automation Design

For each automation requirement from discovery, select the correct approach using the decision guides.

**Decision hierarchy (declarative before code):**
1. Standard Salesforce feature (validation rule, formula, rollup summary) — use if sufficient
2. Flow (record-triggered, screen, scheduled, auto-launched) — use for all business logic where possible
3. Apex (trigger handler + service layer) — use only when Flow cannot satisfy the requirement

For each automation, document:
```
Automation: [Name per naming-conventions.md]
Type: Record-Triggered Flow | Screen Flow | Scheduled Flow | Apex Trigger | Batch | Queueable | Platform Event
Trigger: [Object, event, conditions]
Logic: [Step-by-step what it does]
Bulkification: [How it handles 200+ records — required for any Apex]
Governor limit exposure: [Which limits it consumes — refer to knowledge/governor-limits.md]
Error handling: [What happens on failure]
Decision guide citation: [Which reference justifies this choice]
```

For any Apex automation, the design must specify:
- One trigger per object (trigger body calls handler only — no logic in trigger)
- Handler class extends `TriggerHandler` base (see `skills/design/references/wa-tools/adaptable-separation-of-concerns.md`)
- Service class for business logic, separate from the handler
- Test class required, 90%+ coverage target

For Flow design, refer to `skills/design/references/decision-guides/record-triggered.md` for bulkification and loop-avoidance patterns.

---

## Step 3 — Integration Design

For each integration requirement:

**Tool:** `mcp__salesforce__run_soql_query`

Check existing Named Credentials:
```sql
SELECT DeveloperName, Endpoint, PrincipalType
FROM NamedCredential
ORDER BY DeveloperName
```

For each integration, document:
```
Integration: [Name]
Direction: Inbound | Outbound | Bidirectional
Protocol: REST | SOAP | Platform Event | CDC | Bulk API
Authentication: Named Credential | OAuth | Basic (flag if Basic)
Trigger: [What initiates the integration]
Error handling: [Retry strategy, dead-letter handling]
Governor limit exposure: [API call budgets, callout limits]
Decision guide citation: [Which reference justifies this choice]
```

Refer to `skills/design/references/decision-guides/data-integration.md` and `skills/design/references/decision-guides/event-driven.md`.

For async/background integrations, refer to `skills/design/references/decision-guides/async-processing.md`.

---

## Step 4 — Security Design

For each object and integration in scope:

**Tool:** `mcp__salesforce__run_soql_query`

Check profiles in use:
```sql
SELECT Name FROM Profile WHERE UserType = 'Standard' ORDER BY Name
```

Design:
- Which profiles need access to each new object/field (read, edit, create, delete)
- Which permission sets to create or extend
- OWD for each new object (must comply with `knowledge/security-baseline.md`)
- Sharing rules if OWD is Private but broader access is needed
- CRUD/FLS enforcement requirement for every Apex class that touches data

Refer to `skills/design/references/wa-framework/secure.md` and `skills/design/references/wa-tools/trusted-organizational-security.md`.

All new Apex classes must enforce FLS. Design must specify whether to use `WITH SECURITY_ENFORCED`, `Security.stripInaccessible()`, or `CanTheUser` utility pattern.

---

## Step 5 — LWC and UI Design

For each UI requirement:

**Tool:** `mcp__salesforce__guide_lwc_development`

For each component, document:
```
Component: [API name per naming-conventions.md]
Target: [Record page / App page / Flow screen / Experience site]
Data access: Wire (LDS) | Apex imperative | Apex wire
Parent-child: [Component hierarchy if composite]
Events: [Custom events fired and handled]
Accessibility: [ARIA requirements per wa-tools/trusted-accessibility.md]
```

Refer to `skills/design/references/wa-framework/engaging.md` for UX design principles.

Prefer `@wire` with LDS adapters over imperative Apex calls where the data is record-bound. Use imperative calls only when wire is insufficient (complex filtering, mutations).

---

## Step 6 — Write Design Artifact

Write `engagements/{customer}/design.md`. Every architectural claim must cite a reference.

```markdown
# Design — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Org:** {org alias}
**Discovery artifact:** engagements/{customer}/discovery.md

## Summary
[2-3 sentences: what is being built, key architectural decisions made, well-architected alignment]

## Data Model

### New / Modified Objects
| Object API Name | Label | OWD | Notes |
|---|---|---|---|

### New / Modified Fields
| Object | Field API Name | Type | Required | Description |
|---|---|---|---|---|

### Validation Rules
| Object | Rule Name | Condition | Error Message |
|---|---|---|---|

## Automation Design

### [Automation Name]
- **Type:** {type}
- **Trigger:** {trigger}
- **Logic:** {step-by-step}
- **Bulkification:** {approach}
- **Error handling:** {approach}
- **Citation:** {reference file}

[Repeat per automation]

## Integration Design

### [Integration Name]
- **Direction:** {direction}
- **Protocol:** {protocol}
- **Authentication:** {method}
- **Error handling:** {approach}
- **Citation:** {reference file}

[Repeat per integration]

## Security Design
- Permission sets to create/extend: [list]
- OWD decisions per object: [table]
- FLS enforcement approach: [method chosen]
- Sharing rules: [list or "None required"]

## LWC Components

### [Component Name]
- **Target:** {target}
- **Data access:** {method}
- **Events:** {list}

[Repeat per component]

## Open Questions
[Numbered list requiring human input before Implementation begins]

## Evaluation
- Score: N/100
- Gate: PASS | FAIL
- Blocking findings: [list or "None"]
```

---

## Step 7 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/design-evaluation.json`
3. Run memory consolidation:
   - Promote durable learnings to `core-memory.md` (architectural decisions, patterns chosen)
   - Clear `workflow-memory.md` back to empty template
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Design complete for {Customer Name}**
Artifact: engagements/{customer}/design.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of architecture and key decisions}

Open questions requiring your input before Implementation begins:
{numbered list}

Please respond:
- APPROVED — to proceed to Phase 3: Implementation
- REVISE: [your feedback] — to revise this design
```

---

## References

### Well-Architected Framework
- `skills/design/references/wa-framework/overview.md` — framework overview, always load
- `skills/design/references/wa-framework/secure.md` — security pillar
- `skills/design/references/wa-framework/reliable.md` — reliability and data integrity
- `skills/design/references/wa-framework/composable.md` — composability and reuse
- `skills/design/references/wa-framework/automated.md` — automation design
- `skills/design/references/wa-framework/engaging.md` — UX and UI design

### Well-Architected Tools
- `skills/design/references/wa-tools/trusted-organizational-security.md` — org security patterns
- `skills/design/references/wa-tools/trusted-data-security.md` — data security patterns
- `skills/design/references/wa-tools/easy-maintainability.md` — code maintainability
- `skills/design/references/wa-tools/adaptable-separation-of-concerns.md` — separation of concerns

### Decision Guides
- `skills/design/references/decision-guides/record-triggered.md` — when/how to use record-triggered flows
- `skills/design/references/decision-guides/async-processing.md` — async automation selection
- `skills/design/references/decision-guides/event-driven.md` — platform events and CDC
- `skills/design/references/decision-guides/data-integration.md` — integration pattern selection
- `skills/design/references/decision-guides/build-forms.md` — screen flow vs LWC decisions

### Knowledge Base
- `knowledge/naming-conventions.md` — all API names must comply
- `knowledge/security-baseline.md` — minimum security standards
- `knowledge/governor-limits.md` — design must stay within governor limits
