# SKILL: Implementation
**Phase:** 3 of 6
**Prerequisite artifact:** `engagements/{customer}/design.md` (status: APPROVED)
**Output artifact:** `engagements/{customer}/impl-summary.md`
**Evaluation output:** `engagements/{customer}/evaluation/implementation-evaluation.json`

---

## Purpose

Build exactly what the Design artifact specifies — no more, no less. Every component created must trace to a design decision. Every Apex class must have a corresponding test class written in the same session.

You are not making architectural decisions in this phase. If you encounter something the design did not cover, stop and surface it rather than deciding unilaterally.

All Salesforce operations use Headless 360 MCP tools exclusively. Never use Bash or the sf CLI for org operations.

---

## Before You Start

1. Read `engagements/{customer}/memory/core-memory.md`
2. Read `engagements/{customer}/design.md` in full — this is your specification
3. Read `knowledge/naming-conventions.md`
4. Read `knowledge/security-baseline.md`
5. Read `knowledge/governor-limits.md`
6. Load the trigger handler framework reference before writing any Apex:
   - `skills/implementation/references/apex/trigger-handler-base.md` — the base class all trigger handlers must extend
7. **Cloud-Specific Context:** Check `core-memory.md` for the cloud(s) in scope. Load the relevant cloud primer(s) before writing any code — API names, object schemas, and platform constraints are cloud-specific:
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
   Load all cloud primers that apply — do not guess API names without reading the primer first.
8. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first, then read any documents marked as relevant to Implementation (API specs, integration credentials docs, naming convention overrides, data migration mappings).
9. Confirm the target sandbox org alias with the user before any deployment
9. Append to `workflow-memory.md`: session start, target org, components to build per design
10. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files (e.g., an Apex method signature, LWC API, platform behaviour), use `WebSearch` before making an assumption. Prefer results from `trailhead.salesforce.com`, `developer.salesforce.com`, and `github.com/trailheadapps`. Do not guess — search first.

---

## Step 1 — Metadata Scaffolding

Deploy all declarative metadata first — objects, fields, validation rules, permission sets. Code deploys depend on metadata existing first.

For each new custom object or field from the design:

**Tool:** `mcp__salesforce__deploy_metadata` (checkOnly: true first, then full deploy after user approval)

Validation deploy first:
```
checkOnly: true
Metadata: CustomObject / CustomField
Target org: {sandbox alias}
```

Present the validation result to the user. Only proceed with full deploy on explicit approval.

After successful deploy, verify:

**Tool:** `mcp__salesforce__run_soql_query`
```sql
SELECT QualifiedApiName, Label
FROM EntityDefinition
WHERE QualifiedApiName = '{ObjectAPIName}'
```

---

## Step 2 — Apex Trigger Implementation

For every Apex trigger in the design, follow this exact pattern — no exceptions.

### Trigger body (one trigger per object, no logic in trigger)

```apex
trigger {ObjectName}Trigger on {ObjectName} (before insert, before update, ...) {
    new {ObjectName}TriggerHandler().run();
}
```

### Handler class (extends TriggerHandler)

- Reference `skills/implementation/references/apex/trigger-handler-base.md` for the base class API
- Reference `skills/implementation/references/apex/account-trigger-handler.md` for the implementation pattern
- Override only the context methods your logic needs (`beforeInsert`, `afterInsert`, etc.)
- Handler delegates to a Service class — no business logic in the handler

```apex
public with sharing class {ObjectName}TriggerHandler extends TriggerHandler {
    @TestVisible
    private List<{ObjectName}> triggerNew;
    private Map<Id, {ObjectName}> triggerMapNew;
    private List<{ObjectName}> triggerOld;

    public {ObjectName}TriggerHandler() {
        this.triggerNew = ({ObjectName}[]) Trigger.new;
        this.triggerMapNew = (Map<Id, {ObjectName}>) Trigger.newMap;
        this.triggerOld = ({ObjectName}[]) Trigger.old;
    }

    public override void beforeInsert() {
        {ObjectName}Service.handleBeforeInsert(this.triggerNew);
    }
    // ... other context methods as needed
}
```

### Service class

- All DML and SOQL in the service class, not the handler
- Enforce FLS using `Security.stripInaccessible()` per the design's FLS enforcement decision
- Reference `skills/implementation/references/apex/metadata-trigger-handler.md` for the metadata-driven pattern when the design calls for it

### Bulkification rules (from `knowledge/governor-limits.md`)

- Never query inside a loop
- Never DML inside a loop
- Collect IDs in Sets, query once, process in Maps
- Reference `skills/implementation/references/apex/account-trigger-handler.md` for the bulk collection pattern

---

## Step 3 — Async Apex Implementation

For each Batch, Queueable, Future, or Scheduled class in the design:

**Batch Apex** — reference `skills/implementation/references/apex/batch-apex-recipes.md`:
- Implement `Database.Batchable<SObject>`
- `start()` returns `Database.QueryLocator` (not an Iterable unless required)
- `execute()` processes 200 records by default — never assume small batches
- `finish()` handles completion notification and chaining if required
- Implement `Database.Stateful` only when accumulating results across batches

**Queueable** — reference `skills/implementation/references/apex/queueable-recipes.md`:
- Use for single async operation or chaining (max 5 levels of chaining)
- Prefer over `@future` when you need object parameter support or chaining

**Future methods** — reference `skills/implementation/references/apex/at-future-recipes.md`:
- Use only for callouts from trigger context or simple fire-and-forget
- Parameters must be primitive types only

**Scheduled Apex** — reference `skills/implementation/references/apex/scheduled-apex-recipes.md`:
- Implement `Schedulable`
- `execute()` should be thin — instantiate and enqueue a Batch or Queueable
- Never put business logic directly in the scheduled class

---

## Step 4 — Platform Events Implementation

For any Platform Event integration in the design — reference `skills/implementation/references/apex/platform-events-recipes.md`:

- Publisher: use `EventBus.publish()` and check `Database.SaveResult` for errors
- Subscriber: Flow subscription (preferred) or Apex trigger on the event object
- Error handling: Publish failures are silent unless you inspect the SaveResult — always check

---

## Step 5 — Integration Implementation

For each integration in the design:

**Tool:** `mcp__salesforce__run_soql_query`

Verify Named Credential exists:
```sql
SELECT DeveloperName, Endpoint
FROM NamedCredential
WHERE DeveloperName = '{CredentialName}'
```

If missing, stop and tell the user — Named Credentials must be configured before callout code is deployed.

**HTTP callout pattern** — reference `skills/implementation/references/integration/callout-recipes.md`:
- Use `Named Credentials` for all external endpoints — never hardcode URLs or credentials
- Reference `skills/implementation/references/integration/named-credential-recipes.md` for the Named Credential usage pattern
- Reference `skills/implementation/references/integration/api-service-recipes.md` for the service class abstraction pattern
- All callouts must be in classes implementing `HttpCalloutMock` in tests

---

## Step 6 — LWC Implementation

For each LWC component in the design:

**Tool:** `mcp__salesforce__guide_lwc_development`
**Tool:** `mcp__salesforce__create_lwc_component_from_prd`

Wire service pattern — reference `skills/implementation/references/lwc/lwc-wire-service.md`:
- Use `@wire` with LDS adapters (`getRecord`, `getFieldValue`, etc.) for record-bound data
- Use `@wire` with Apex for read-only data that requires server logic
- Reference `skills/implementation/references/lwc/apex-wire-method-to-property.md` for the wired Apex pattern

Imperative Apex: call from `connectedCallback` or event handlers only — not in `renderedCallback`.

---

## Step 7 — Deploy to Sandbox

**Tool:** `mcp__salesforce__deploy_metadata` (checkOnly: true first)

Run a validation deploy of all components:
```
checkOnly: true
All components from this implementation
Target org: {sandbox alias}
```

Present the validation result — show any errors. Only proceed with full deploy on explicit user approval.

**Tool:** `mcp__salesforce__assign_permission_set`

After deploy, assign new permission sets to test users as specified in the design.

---

## Step 8 — Write Implementation Summary Artifact

Write `engagements/{customer}/impl-summary.md`:

```markdown
# Implementation Summary — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Org:** {org alias}
**Design artifact:** engagements/{customer}/design.md

## Summary
[2-3 sentences: what was built, any deviations from design and why]

## Components Deployed

### Metadata
| Component | API Name | Type | Status |
|---|---|---|---|

### Apex Classes
| Class | Type | Test Class | Coverage % |
|---|---|---|---|

### LWC Components
| Component | Target | Data Access | Status |
|---|---|---|---|

### Flows
| Flow | Type | Status |
|---|---|---|

## Design Deviations
[Any cases where implementation differed from design, with justification]

## Known Issues
[Anything that did not deploy cleanly, with workarounds applied]

## Open Questions
[Anything that must be resolved before Testing begins]

## Evaluation
- Score: N/100
- Gate: PASS | FAIL
- Blocking findings: [list or "None"]
```

---

## Step 9 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/implementation-evaluation.json`
3. Run memory consolidation:
   - Promote durable learnings to `core-memory.md` (patterns that worked, deployment issues, workarounds)
   - Clear `workflow-memory.md` back to empty template
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Implementation complete for {Customer Name}**
Artifact: engagements/{customer}/impl-summary.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of what was built and any deviations}

Open questions requiring your input before Testing begins:
{numbered list}

Please respond:
- APPROVED — to proceed to Phase 4: Testing
- REVISE: [your feedback] — to revise this implementation
```

---

## References

### Apex Patterns
- `skills/implementation/references/apex/trigger-handler-base.md` — TriggerHandler base class (always load before writing triggers)
- `skills/implementation/references/apex/account-trigger-handler.md` — trigger handler implementation pattern
- `skills/implementation/references/apex/metadata-trigger-handler.md` — metadata-driven trigger handler for config-based routing
- `skills/implementation/references/apex/batch-apex-recipes.md` — Batch Apex pattern
- `skills/implementation/references/apex/queueable-recipes.md` — Queueable pattern
- `skills/implementation/references/apex/at-future-recipes.md` — @future method pattern
- `skills/implementation/references/apex/scheduled-apex-recipes.md` — Schedulable pattern
- `skills/implementation/references/apex/platform-events-recipes.md` — Platform Event publish/subscribe pattern

### Integration Patterns
- `skills/implementation/references/integration/callout-recipes.md` — HTTP callout pattern
- `skills/implementation/references/integration/named-credential-recipes.md` — Named Credential usage
- `skills/implementation/references/integration/api-service-recipes.md` — service class abstraction for integrations

### LWC Patterns
- `skills/implementation/references/lwc/lwc-wire-service.md` — wire service and picklist values pattern
- `skills/implementation/references/lwc/apex-wire-method-to-property.md` — wired Apex method pattern

### Knowledge Base
- `knowledge/naming-conventions.md` — all API names must comply
- `knowledge/security-baseline.md` — FLS, sharing, CRUD enforcement
- `knowledge/governor-limits.md` — bulkification and limit compliance
