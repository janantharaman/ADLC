# SKILL: Retrofit
**Phase:** Retrofit (Standalone or Post-Deployment)
**Prerequisite artifact:** `engagements/{customer}/discovery.md` (status: APPROVED) — minimum
**Output artifact:** `engagements/{customer}/retrofit.md`
**Evaluation output:** `engagements/{customer}/evaluation/retrofit-evaluation.json`

---

## Purpose

Assess and improve the architectural health of an existing Salesforce org against the Well-Architected framework. This phase is used when a customer has an org in production that was not built to GDC standards — inherited implementations, self-built orgs, or orgs that have drifted from their original design.

The output is not a new build specification. It is a prioritized remediation backlog with Well-Architected scores, pattern violations, and specific, actionable recommendations.

All Salesforce operations use Headless 360 MCP tools exclusively. Never use Bash or the sf CLI for org operations.

---

## Before You Start

1. Read `engagements/{customer}/memory/core-memory.md`
2. Read `engagements/{customer}/discovery.md` — the Discovery phase must have run first; Retrofit uses its findings as input
3. Confirm the org alias with the user
4. Confirm the scope of the retrofit: Full org assessment, or scoped to specific clouds / objects / automation?
5. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first, then read any documents marked as relevant to Retrofit (previous audit reports, known issue logs, vendor handover docs, original design documents).
6. Append to `workflow-memory.md`: session start, org alias, retrofit scope, discovery findings summary
7. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files (e.g., a Well-Architected pattern, anti-pattern definition, platform behaviour), use `WebSearch` before making an assumption. Prefer results from `architect.salesforce.com`, `trailhead.salesforce.com`, and `developer.salesforce.com`. Do not guess — search first.

---

## Step 1 — Well-Architected Scoring

Score the current org across the three pillars of the Well-Architected framework. Use the references in this skill as the scoring rubric.

Load all three pillar references before scoring:
- `skills/retrofit/references/wa-tools/adaptable-overview.md`
- `skills/design/references/wa-framework/trusted-overview.md`
- `skills/design/references/wa-framework/easy-overview.md`

### 1a. Trusted Pillar Assessment

**Organisational Security** — cross-reference discovery findings against the Trusted tools:

**Tool:** `mcp__salesforce__run_soql_query`

```sql
SELECT QualifiedApiName, ExternalSharingModel, InternalSharingModel
FROM EntityDefinition
WHERE IsCustomizable = true AND QualifiedApiName LIKE '%__c'
ORDER BY QualifiedApiName
```

Score against `skills/design/references/wa-tools/trusted-organizational-security.md`:
- Are OWDs set to least-privilege? (Private or Controlled by Parent for sensitive objects)
- Are permission sets used instead of profiles for access grants?
- Is MFA enforced for all standard users?

**Tool:** `mcp__salesforce__run_code_analyzer`

```
Run code analyzer to check for CRUD/FLS violations
```

Score against `skills/design/references/wa-tools/trusted-data-security.md`:
- Do Apex classes enforce FLS on all SOQL and DML?
- Are there hardcoded IDs or credentials?

### 1b. Easy Pillar Assessment

**Tool:** `mcp__salesforce__retrieve_metadata`

```
Retrieve type: ApexClass
Members: *
```

Score against `skills/design/references/wa-tools/easy-maintainability.md`:
- Do triggers delegate to handler classes?
- Are there god classes (>500 lines with mixed concerns)?
- Is there dead code (classes with no callers)?

**Tool:** `mcp__salesforce__run_soql_query`

```sql
SELECT Name, LengthWithoutComments, ApiVersion
FROM ApexClass
WHERE IsValid = true AND NamespacePrefix = null
ORDER BY LengthWithoutComments DESC
LIMIT 20
```

Flag any class > 300 lines without a clear single responsibility.

### 1c. Adaptable Pillar Assessment

Score using the Adaptable tools references:

**ALM** — `skills/retrofit/references/wa-tools/adaptable-application-lifecycle-management.md`:
- Is there a structured sandbox strategy (dev → QA → UAT → prod)?
- Are changes tracked in source control?
- Is there a CI/CD pipeline?

**Separation of Concerns** — `skills/retrofit/references/wa-tools/adaptable-separation-of-concerns.md`:
- One trigger per object?
- Business logic separated into service classes?
- No business logic in LWC controllers?

**Interoperability** — `skills/retrofit/references/wa-tools/adaptable-interoperability.md`:
- Are integrations using Named Credentials?
- Are there hardcoded endpoint URLs?
- Are API versions pinned to old versions?

**Packageability** — `skills/retrofit/references/wa-tools/adaptable-packageability.md`:
- Are there namespace collisions or unmanaged package risks?
- Is the metadata structured for packaging?

---

## Step 2 — Pattern and Anti-Pattern Audit

Using the pattern library references, identify which patterns the org uses and which anti-patterns it exhibits.

Load:
- `skills/retrofit/references/wa-tools/patterns.md` — catalogue of approved patterns
- `skills/retrofit/references/wa-tools/anti-patterns.md` — anti-patterns to find and flag

For each anti-pattern found, record:
```
Anti-pattern: [Name from anti-patterns.md]
Location: [Class/Flow/Object API name]
Evidence: [What you found — tool result]
Risk: HIGH / MEDIUM / LOW
Recommended pattern: [From patterns.md]
Remediation effort: S / M / L
```

---

## Step 3 — ALM and DevOps Assessment

**Tool:** `mcp__salesforce__run_soql_query`

Check sandbox count:
```sql
SELECT SandboxName, LicenseType, Status, Description
FROM SandboxInfo
ORDER BY SandboxName
```

Check last deploy activity:
```sql
SELECT Id, Status, StartDate, CompletedDate, NumberComponentsDeployed
FROM DeployRequest
WHERE Status = 'Succeeded'
ORDER BY CompletedDate DESC
LIMIT 10
```

Score against `skills/retrofit/references/wa-tools/adaptable-application-lifecycle-management.md`:
- Adequate sandbox strategy for the org's size and change velocity?
- Evidence of regular, structured deployments (not ad-hoc)?
- Incomplete or stale sandboxes?

---

## Step 4 — Incident Response and Continuity Review

Score against:
- `skills/retrofit/references/wa-tools/adaptable-incident-response.md`
- `skills/retrofit/references/wa-tools/adaptable-continuity-planning.md`

Questions to answer from discovery findings and user input:
- Is there a runbook for common failure scenarios?
- Are there monitoring and alerting mechanisms (Platform Event dead-letter queues, Apex exception emails)?
- Is there a disaster recovery plan for data loss?
- Are critical scheduled jobs monitored?

**Tool:** `mcp__salesforce__run_soql_query`

Check for active Apex exception email recipients:
```sql
SELECT Id, Name, ApexTriggerNamespacePrefix
FROM ApexEmailNotification
ORDER BY Name
```

---

## Step 5 — Prioritised Remediation Backlog

Based on Steps 1–4, produce a prioritised remediation backlog. Sort by: (impact × likelihood of failure) / effort.

For each item:
```
RETRO-001: [Short name]
Pillar: Trusted | Easy | Adaptable
Anti-pattern: [Name from anti-patterns.md]
Finding: [What is wrong]
Risk: HIGH / MEDIUM / LOW
Recommended fix: [Specific action referencing patterns.md]
Effort: S / M / L / XL
Priority: P1 (do now) / P2 (next sprint) / P3 (backlog)
Well-Architected citation: [Reference file]
```

P1 items: HIGH risk findings that are straightforward to fix (effort S or M)
P2 items: HIGH risk but large effort, or MEDIUM risk items
P3 items: LOW risk, cosmetic, or aspirational improvements

---

## Step 6 — Write Retrofit Artifact

Write `engagements/{customer}/retrofit.md`:

```markdown
# Retrofit Assessment — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Org:** {org alias}
**Discovery artifact:** engagements/{customer}/discovery.md

## Summary
[2-3 sentences: overall org health, key strengths, key risk areas]

## Well-Architected Scores

### Trusted
- Score: {N}/100
- Key strengths: [list]
- Key gaps: [list]

### Easy
- Score: {N}/100
- Key strengths: [list]
- Key gaps: [list]

### Adaptable
- Score: {N}/100
- Key strengths: [list]
- Key gaps: [list]

### Overall
- Score: {N}/100

## Anti-Patterns Found
| ID | Anti-Pattern | Location | Risk | Effort | Priority |
|---|---|---|---|---|---|

## Remediation Backlog

### P1 — Do Now
| ID | Finding | Recommended Fix | Effort | Citation |
|---|---|---|---|---|

### P2 — Next Sprint
| ID | Finding | Recommended Fix | Effort | Citation |
|---|---|---|---|---|

### P3 — Backlog
| ID | Finding | Recommended Fix | Effort | Citation |
|---|---|---|---|---|

## Open Questions
[Questions requiring customer input to complete the assessment]

## Evaluation
- Score: N/100
- Gate: PASS | FAIL
- Blocking findings: [list or "None"]
```

---

## Step 7 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/retrofit-evaluation.json`
3. Run memory consolidation:
   - Promote durable learnings to `core-memory.md` (org health patterns, key anti-patterns found, customer's tolerance for change)
   - Clear `workflow-memory.md` back to empty template
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Retrofit Assessment complete for {Customer Name}**
Artifact: engagements/{customer}/retrofit.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of org health and priority findings}

P1 items requiring immediate attention:
{numbered list}

Please respond:
- APPROVED — to finalise this assessment
- REVISE: [your feedback] — to extend or adjust the assessment
```

---

## References

### Well-Architected Tools (Adaptable)
- `skills/retrofit/references/wa-tools/patterns.md` — approved patterns catalogue
- `skills/retrofit/references/wa-tools/anti-patterns.md` — anti-patterns to identify and remediate
- `skills/retrofit/references/wa-tools/adaptable-overview.md` — Adaptable pillar overview
- `skills/retrofit/references/wa-tools/adaptable-application-lifecycle-management.md` — ALM patterns and scoring
- `skills/retrofit/references/wa-tools/adaptable-separation-of-concerns.md` — separation of concerns assessment
- `skills/retrofit/references/wa-tools/adaptable-interoperability.md` — integration health assessment
- `skills/retrofit/references/wa-tools/adaptable-packageability.md` — packaging readiness
- `skills/retrofit/references/wa-tools/adaptable-continuity-planning.md` — continuity and DR assessment
- `skills/retrofit/references/wa-tools/adaptable-incident-response.md` — incident response assessment

### Well-Architected Tools (Trusted and Easy — from design references)
- `skills/design/references/wa-tools/trusted-organizational-security.md`
- `skills/design/references/wa-tools/trusted-data-security.md`
- `skills/design/references/wa-tools/easy-maintainability.md`
- `skills/design/references/wa-framework/trusted-overview.md`
- `skills/design/references/wa-framework/easy-overview.md`

### Knowledge Base
- `knowledge/naming-conventions.md` — naming standard compliance check
- `knowledge/security-baseline.md` — security baseline to score against
- `knowledge/governor-limits.md` — limit health baseline
