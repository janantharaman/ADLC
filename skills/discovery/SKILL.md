# SKILL: Discovery
**Phase:** 1 of 6
**Prerequisite artifact:** `engagements/{customer}/pre-sales.md` (status: APPROVED)
**Output artifact:** `engagements/{customer}/discovery.md`
**Evaluation output:** `engagements/{customer}/evaluation/discovery-evaluation.json`

---

## Purpose

Produce a complete picture of the customer's current Salesforce org state and a structured requirements document grounded in that reality. This phase replaces days of manual SOQL investigation with a systematic, tool-driven analysis.

You are not designing anything in this phase. You are observing, documenting, and grounding requirements in what the org actually contains.

All Salesforce operations use Headless 360 MCP tools exclusively. Never use Bash or the sf CLI for org operations.

---

## Before You Start

1. Read `engagements/{customer}/memory/core-memory.md` — load any known org constraints, preferences, or patterns
2. Read `engagements/{customer}/pre-sales.md` — extract the requirements list, sizing assumptions, and any flagged gaps
3. Read `knowledge/naming-conventions.md`
4. Read `knowledge/security-baseline.md`
5. Read `knowledge/governor-limits.md`
6. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first, then read any documents marked as relevant to Discovery (existing architecture diagrams, data model ERDs, current system documentation, integration specs).
   Also read `knowledge/sdd-template.md` sections **Introduction** and **Current State (As-Is)** — the `discovery.md` artifact populates these SDD sections. Structure findings to directly feed the SDD: client background, project motives, scope (people/process/technology), business model, current-state process maps, current-state system architecture, and conceptual data model.
7. **Cloud-Specific Context:** If the engagement cloud is known (from pre-sales or user input), additionally load the relevant cloud primer before starting org investigation — it will guide what to look for:
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
   If the cloud is not yet known, proceed with discovery and load the matching primer(s) after Step 1 identifies the installed packages and objects.
8. Confirm the org alias with the user before running any queries
9. Append to `workflow-memory.md`: session start, phase, org alias, pre-sales requirements count
10. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files or cloud primers (e.g., exact object API name, feature behaviour, governor limit value), use `WebSearch` before making an assumption. Prefer results from `trailhead.salesforce.com`, `help.salesforce.com`, `developer.salesforce.com`, and `github.com/trailheadapps`. Do not guess — search first.

If `pre-sales.md` does not exist or is not APPROVED, stop and tell the user:
"Pre-Sales artifact is required before Discovery can begin. Please complete Phase 0 first."

---

## Step 1 — Org Health Baseline

Work through each category below using the specified Headless 360 tool. Append key findings to `workflow-memory.md` as you go.

### 1a. Object and Field Inventory

**Tool:** `mcp__salesforce__retrieve_metadata`

Retrieve metadata for all custom objects to get a complete picture of object structure, fields, relationships, validation rules, and page layouts in one call:

```
Retrieve type: CustomObject
Members: * (all custom objects)
```

From the retrieved metadata, extract per object:
- API name, label, description
- Custom fields (name, type, description, required flag)
- Validation rules (name, active, error message)
- Record types
- Whether the object has triggers (you will confirm in 1b)

Flag any object with no description — this is a documentation gap.

### 1b. Apex Classes and Triggers

**Tool:** `mcp__salesforce__retrieve_metadata`

Retrieve all Apex classes:
```
Retrieve type: ApexClass
Members: *
```

Retrieve all Apex triggers:
```
Retrieve type: ApexTrigger
Members: *
```

From the retrieved metadata, note:
- Class names, whether each has a corresponding test class, naming pattern (handler, service, batch, scheduler)
- Trigger name and object — flag any trigger that contains logic directly rather than delegating to a handler class
- Scheduled Apex — note what is scheduled and how frequently
- Batch classes — note what data they process

**Tool:** `mcp__salesforce__run_code_analyzer`

Run the code analyser to surface security issues, bulkification violations, and anti-patterns:
```
Run code analyzer on all Apex classes and triggers
```

Record all HIGH and CRITICAL findings — these become implementation risks.

### 1c. LWC Components

**Tool:** `mcp__salesforce__retrieve_metadata`

Retrieve all Lightning Web Components:
```
Retrieve type: LightningComponentBundle
Members: *
```

From the retrieved metadata, note:
- Component name, target pages/apps where it is exposed (targets in the metadata)
- Whether it uses `@wire` adapters (Lightning Data Service) or Apex calls
- Any components with `isExposed: true` — these are user-facing

Also retrieve Aura components (legacy):
```
Retrieve type: AuraDefinitionBundle
Members: *
```

Flag any Aura components that could be candidates for LWC migration.

### 1d. Automation Inventory

**Tool:** `mcp__salesforce__retrieve_metadata`

Retrieve all Flows:
```
Retrieve type: Flow
Members: *
```

From the retrieved metadata, note:
- Flow API name, process type (Record-Triggered, Screen, Scheduled, Auto-launched), status (Active/Inactive)
- Any active Process Builder flows (ProcessType = Workflow) — flag each for migration to Flow
- Any active Workflow Rules — flag each for migration to Flow
- Screen flows exposed in the org (which objects, which record pages)

### 1e. Prompt Templates

**Tool:** `mcp__salesforce__retrieve_metadata`

Retrieve all Prompt Templates:
```
Retrieve type: PromptTemplate
Members: *
```

From the retrieved metadata, note:
- Template name, type (Sales Email, Field Generation, Flex, etc.)
- Which object it operates on
- Status (Active/Draft)
- Whether it uses Grounding (connected to org data)

If no Prompt Templates exist, note this — it may indicate Agentforce/Einstein features have not yet been adopted.

### 1f. Agentforce Agents, Topics, and Actions

**Tool:** `mcp__salesforce__retrieve_metadata`

Retrieve Agentforce Agents (GenAiPlanner = topics container, BotDefinition = agent):
```
Retrieve type: BotDefinition
Members: *
```

Retrieve Agentforce Topics (GenAiPlanner):
```
Retrieve type: GenAiPlanner
Members: *
```

Retrieve Agentforce Actions (GenAiPlugin):
```
Retrieve type: GenAiPlugin
Members: *
```

From the retrieved metadata, note:
- Agent names, channels they are deployed on (Experience Site, Service Console, etc.), status
- Topics per agent — names, descriptions, what they handle
- Actions per topic — type (Flow, Apex, Prompt Template, Standard), what they invoke
- Whether actions have valid backing targets (the Flow/Apex class/Prompt Template they call must exist)

**Tool:** `mcp__salesforce__run_soql_query`

Check agent test coverage:
```sql
SELECT Id, DeveloperName, MasterLabel, Status
FROM BotDefinition
ORDER BY MasterLabel
```

Agentforce / Einstein license assignments:
```sql
SELECT PermissionSet.Name, COUNT(Id) AssignedCount
FROM PermissionSetAssignment
WHERE PermissionSet.Name LIKE '%Agentforce%'
   OR PermissionSet.Name LIKE '%Einstein%'
   OR PermissionSet.Name LIKE '%Agent%'
GROUP BY PermissionSet.Name
```

### 1g. Apex Code Quality

**Tool:** `mcp__salesforce__run_code_analyzer`

Run the code analyser against all Apex:
```
Run code analyzer on all Apex classes and triggers
```

Record all HIGH and CRITICAL findings — these become implementation risks.

### 1h. User and Permission Structure

**Tool:** `mcp__salesforce__run_soql_query`

Active users by profile:
```sql
SELECT Profile.Name, COUNT(Id) UserCount
FROM User
WHERE IsActive = true
GROUP BY Profile.Name
ORDER BY Profile.Name
```

Custom permission sets:
```sql
SELECT Name, Label, Description
FROM PermissionSet
WHERE IsOwnedByProfile = false AND IsCustom = true
ORDER BY Name
```

Permission set assignments (identify who has what access):
```sql
SELECT Assignee.Name, PermissionSet.Name
FROM PermissionSetAssignment
WHERE PermissionSet.IsCustom = true
ORDER BY PermissionSet.Name, Assignee.Name
```

### 1i. API Limits and Governor Health

**Tool:** `mcp__salesforce__run_soql_query`

```sql
SELECT CurrentValue, MaxValue, Remaining, Type
FROM OrgLimit
ORDER BY Type
```

Calculate `(CurrentValue / MaxValue) * 100` for each limit.
Flag any at > 80% as HIGH RISK in the artifact.
Refer to `knowledge/governor-limits.md` for risk thresholds.

### 1j. Installed Packages

**Tool:** `mcp__salesforce__run_soql_query`

```sql
SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix,
       SubscriberPackageVersion.Name, SubscriberPackageVersion.MajorVersion,
       SubscriberPackageVersion.MinorVersion
FROM InstalledSubscriberPackage
ORDER BY SubscriberPackage.Name
```

Flag any unmanaged packages — these are upgrade and support risks.

### 1k. Security Model

**Tool:** `mcp__salesforce__run_soql_query`

Org-wide defaults per object:
```sql
SELECT QualifiedApiName, ExternalSharingModel, InternalSharingModel
FROM EntityDefinition
WHERE IsCustomizable = true AND QualifiedApiName LIKE '%__c'
ORDER BY QualifiedApiName
```

Check against `knowledge/security-baseline.md` — flag any sensitive object with OWD = Public Read/Write as HIGH RISK.

MFA status:
```sql
SELECT Id, Name, RequiresMfa
FROM Profile
WHERE UserType = 'Standard'
ORDER BY Name
```

Connected Apps (OAuth access review):
```sql
SELECT Name, ContactEmail, OptionsAllowAdminApprovedUsersOnly
FROM ConnectedApplication
ORDER BY Name
```

---

## Step 2 — Requirements Grounding

For each requirement in `pre-sales.md`, use Headless 360 tools to check whether the org already has relevant configuration.

**Tool:** `mcp__salesforce__run_soql_query` — verify existing records, configuration, or data relevant to the requirement

**Tool:** `mcp__salesforce__retrieve_metadata` — check for existing metadata components (custom objects, fields, flows, classes) that relate to the requirement

For each requirement, record:
```
Requirement: [name from pre-sales]
Status: SUPPORTED | PARTIAL | BLOCKED | NEW
Existing config: [what Headless 360 tools found in the org]
Conflicts: [anything that will need to change]
Constraints: [limits or structural issues]
Notes: [anything else relevant]
```

Append each assessment to `workflow-memory.md`.

---

## Step 3 — FLS Matrix

Produce a field-level security matrix for all objects in scope.

**Tool:** `mcp__salesforce__run_soql_query`

Per-profile FLS per object (run for each object in scope):
```sql
SELECT SobjectType, Field, Parent.Profile.Name,
       PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE SobjectType = '{ObjectAPIName}'
AND Parent.IsOwnedByProfile = true
ORDER BY Parent.Profile.Name, Field
```

Per-permission-set FLS per object:
```sql
SELECT SobjectType, Field, Parent.Name,
       PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE SobjectType = '{ObjectAPIName}'
AND Parent.IsOwnedByProfile = false
ORDER BY Parent.Name, Field
```

Compile into a matrix table in the artifact. Refer to `skills/discovery/references/fls-matrix-template.md` for format and risk flags.

---

## Step 4 — Open Questions

Review everything gathered in Steps 1–3. List any questions that cannot be answered from org data alone and require stakeholder input:
- Business process questions (why does automation X exist?)
- Data quality questions (why are records incomplete?)
- Integration owners who need to be consulted
- Architectural decisions that were made previously without documentation

---

## Step 5 — Write Discovery Artifact

Write `engagements/{customer}/discovery.md`. Be specific — no placeholders, no TBD. Every finding must reference actual tool results.

```markdown
# Discovery — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Org:** {org alias}
**Pre-Sales artifact:** engagements/{customer}/pre-sales.md

## Summary
[3-4 sentences: org current state, key risks, key constraints for this engagement]

## Org Health Baseline

### Objects ({N} custom objects)
| Object API Name | Label | Fields | Triggers | Flows | Validation Rules | Notes |
|---|---|---|---|---|---|---|

### Apex Classes ({N} total)
| Class Name | Type (Handler/Service/Batch/Test/Other) | Has Test Class? | Notes |
|---|---|---|---|

### Apex Triggers ({N} total)
| Trigger Name | Object | Delegates to Handler? | Notes |
|---|---|---|---|

### LWC Components ({N} total)
| Component Name | Exposed? | Data Access (Wire/Apex) | Notes |
|---|---|---|---|

### Aura Components ({N} total — flag for LWC migration)
| Component Name | Notes |
|---|---|

### Automation Inventory
**Active Flows ({N} total):**
| Flow API Name | Type | Notes |
|---|---|---|

**Legacy Automation (flag for migration):**
| Name | Type | Object | Notes |
|---|---|---|---|

### Prompt Templates ({N} total)
| Template Name | Type | Object | Status | Notes |
|---|---|---|---|---|

### Agentforce Agents
| Agent Name | Channels | Status | Topics Count | Notes |
|---|---|---|---|---|

**Topics:**
| Agent | Topic Name | Description | Actions Count |
|---|---|---|---|

**Actions:**
| Topic | Action Name | Type (Flow/Apex/Prompt/Standard) | Backing Target | Target Exists? |
|---|---|---|---|---|

### Code Quality (from run_code_analyzer)
**Critical findings:** {N}
**High findings:** {N}
| Finding | Class/Trigger | Severity | Notes |
|---|---|---|---|

### Users and Permissions
- Active users: {N}
- Profiles in use: {list}
- Custom permission sets: {N}
- Key permission sets: {list}

### API Limits
| Limit Type | Current | Max | % Used | Status |
|---|---|---|---|---|

### Installed Packages
| Package | Namespace | Version | Notes |
|---|---|---|---|

### Security Model
- Org-wide defaults: [per object]
- Sharing model: [Public / Private / Controlled by Parent per key object]
- MFA status: [enabled / not enabled per profile]
- Connected Apps: [list with owner and purpose]
- Risks: [any HIGH RISK items from security-baseline.md check]

## Requirements Assessment

### Requirement: {Name}
- **Status:** SUPPORTED | PARTIAL | BLOCKED | NEW
- **Existing config:** {what Headless 360 tools found}
- **Conflicts:** {what will need to change}
- **Constraints:** {limits or structural issues}
- **Notes:** {anything else}

[Repeat for each requirement]

## FLS Matrix

### {Object API Name}
| Field | Profile / PermSet | Read | Edit | Risk |
|---|---|---|---|---|

[Repeat for each object in scope]

## Key Risks
[Numbered list: risk, impact, mitigation recommendation]

## Open Questions
[Numbered list of questions requiring stakeholder input before Design can begin]

## Recommended Scope Confirmation
[Confirm or adjust delivery mode and scope from Pre-Sales based on org findings]
```

---

## Step 6 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/discovery-evaluation.json`
3. Run memory consolidation:
   - Read `workflow-memory.md`
   - Promote durable learnings (org constraints, patterns, risks) to `core-memory.md`
   - Clear `workflow-memory.md` back to empty template
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Discovery complete for {Customer Name}**
Artifact: engagements/{customer}/discovery.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of key findings}

Open questions requiring your input before Design begins:
{numbered list}

Please respond:
- APPROVED — to proceed to Phase 2: Design
- REVISE: [your feedback] — to revise this discovery
```

---

## If the User Responds REVISE

1. Read the feedback and append it to `workflow-memory.md`
2. Identify which steps need re-running — do not redo the entire phase unless necessary
3. Re-run only the affected steps using Headless 360 tools
4. Update `discovery.md` (increment version, update date, update Status to DRAFT)
5. Re-evaluate and re-emit the gate

---

## References

### Discovery Checklists
- `skills/discovery/references/org-health-checklist.md` — full checklist per Salesforce cloud
- `skills/discovery/references/fls-matrix-template.md` — FLS matrix format and risk flags

### Code Patterns (to recognise during org review)
- `skills/discovery/references/trigger-patterns/account-trigger-handler.md` — what a well-structured trigger handler looks like; compare against org's triggers
- `skills/discovery/references/trigger-patterns/metadata-trigger-handler.md` — metadata-driven trigger routing pattern; flag if org lacks this
- `skills/discovery/references/trigger-patterns/metadata-trigger-service.md` — service layer separation pattern
- `skills/discovery/references/security-patterns/can-the-user-recipes.md` — CRUD/FLS enforcement pattern; flag if org's Apex does not use this approach
- `skills/discovery/references/security-patterns/strip-inaccessible-recipes.md` — `Security.stripInaccessible()` pattern for FLS enforcement
- `skills/discovery/references/platform-events/platform-events-recipes.md` — Platform Event publish/subscribe pattern; use when reviewing existing platform event automation

### Knowledge Base
- `knowledge/security-baseline.md` — minimum security standards to verify against
- `knowledge/governor-limits.md` — limit thresholds, risk ratings, and SOQL to check them
- `knowledge/naming-conventions.md` — naming standards to verify against org config
