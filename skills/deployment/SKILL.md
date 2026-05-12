# SKILL: Deployment
**Phase:** 5 of 6
**Prerequisite artifact:** `engagements/{customer}/testing.md` (status: APPROVED)
**Output artifact:** `engagements/{customer}/deployment.md`
**Evaluation output:** `engagements/{customer}/evaluation/deployment-evaluation.json`

---

## Purpose

Deploy the validated, tested implementation to production safely. This phase is irreversible — mistakes here affect live users. Every action must be confirmed by the user before execution.

You never deploy to production without an explicit human APPROVED response for each deploy action. There are no exceptions.

All Salesforce operations use Headless 360 MCP tools exclusively. Never use Bash or the sf CLI for org operations.

---

## Before You Start

1. Read `engagements/{customer}/memory/core-memory.md`
2. Read `engagements/{customer}/testing.md` — confirm the gate is APPROVED and no blocking issues remain
3. Read `engagements/{customer}/impl-summary.md` — know exactly what components are being deployed
4. Confirm the production org alias with the user — do not assume
5. Confirm the deployment window with the user (maintenance window, off-peak hours)
6. **Cloud-Specific Context:** Check `core-memory.md` for the cloud(s) in scope. Load the relevant cloud primer(s) — post-deploy verification steps and go-live checks are cloud-specific:
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
   Load all cloud primers that apply.
7. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first, then read any documents marked as relevant to Deployment (change advisory board templates, go-live checklist, hypercare plan, rollback runbook).
   Also read `knowledge/sdd-template.md` sections **Appendix: Deployment** and **Appendix: Testing > Go Live Readiness** — the `deployment.md` artifact populates the SDD Deployment Runbook and Go Live checklists (Pre/Go/Post with columns: Responsible, Environment, Task, Owner, Timeline, Status).
8. Confirm the rollback plan with the user before any deploy begins
9. Append to `workflow-memory.md`: session start, target prod org, deploy window, rollback plan, approval to proceed
10. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files (e.g., deploy flag behaviour, metadata type constraints, post-deploy verification steps), use `WebSearch` before making an assumption. Prefer results from `trailhead.salesforce.com`, `developer.salesforce.com`, and `help.salesforce.com`. Do not guess — search first.

---

## Step 1 — Pre-Deployment Org Check

Before touching production, verify its current state.

**Tool:** `mcp__salesforce__run_soql_query`

Check org limits are not already near thresholds:
```sql
SELECT CurrentValue, MaxValue, Remaining, Type
FROM OrgLimit
WHERE Type IN ('DailyApiRequests', 'HourlyTimeBasedWorkflow', 'ActiveScratchOrgs')
ORDER BY Type
```

Check current deployment status (no in-flight deployments):
```sql
SELECT Id, Status, NumberComponentsDeployed, NumberComponentErrors, StartDate
FROM DeployRequest
WHERE Status IN ('Pending', 'InProgress')
ORDER BY StartDate DESC
LIMIT 5
```

If any deployment is in progress, stop. Do not deploy concurrently.

**Tool:** `mcp__salesforce__run_apex_test`

Run a subset of critical test classes in production to confirm baseline is healthy before adding to it:
```
Run critical Apex test classes (key business logic only, not full suite)
Target org: {production org alias}
```

---

## Step 2 — Validation Deploy to Production

**Tool:** `mcp__salesforce__deploy_metadata` (checkOnly: true — mandatory)

```
checkOnly: true
All components from impl-summary.md
Run all tests: true
Target org: {production org alias}
```

Present the full validation result to the user:
- Component count, error count
- Test results: pass/fail count, coverage percentage
- Any errors — list each one with component name and message

If any errors or coverage failures: STOP. Do not proceed to full deploy. Surface the issues to the user.

Only present the full deploy option after a clean validation result.

---

## Step 3 — Production Deploy

**Present to the user before running:**

```
READY TO DEPLOY TO PRODUCTION

Target org: {production org alias}
Components: {N} components
Tests: All Apex tests will run during deploy
Validation result: CLEAN (from Step 2)
Deployment window: {confirmed window}
Rollback plan: {confirmed plan}

This action is irreversible. Respond APPROVED to execute.
```

Wait for explicit APPROVED. Do not deploy without it.

**Tool:** `mcp__salesforce__deploy_metadata`

```
checkOnly: false
All components from impl-summary.md
Run all tests: true
Target org: {production org alias}
```

Monitor the deployment. If it fails mid-deploy, immediately surface the error to the user — do not attempt automatic remediation.

---

## Step 4 — Post-Deployment Verification

After a successful deploy, verify the components are live and functional.

**Tool:** `mcp__salesforce__run_soql_query`

Verify key metadata deployed:
```sql
SELECT QualifiedApiName, Label
FROM EntityDefinition
WHERE QualifiedApiName IN ({list of new object API names})
```

Verify Apex classes compiled in production:
```sql
SELECT Name, Status, IsValid, LengthWithoutComments
FROM ApexClass
WHERE Name IN ({list of new class names})
ORDER BY Name
```

Verify Flows are active:
```sql
SELECT ApiName, Status, ProcessType
FROM FlowDefinition
WHERE ApiName IN ({list of new flow API names})
```

**Tool:** `mcp__salesforce__assign_permission_set`

Assign new permission sets to pilot users (if the design specifies a phased rollout):
```
Assign permission set: {PermissionSetName}
User: {pilot user username}
Target org: {production org alias}
```

Present action and wait for user approval before each assignment.

---

## Step 5 — Smoke Test in Production

**Tool:** `mcp__salesforce__run_apex_test`

Run the key test classes in production to confirm coverage is maintained:
```
Run Apex tests: {new test classes from impl-summary.md}
Target org: {production org alias}
```

Confirm:
- All new test classes pass in production
- Org-wide coverage did not drop below 75%

---

## Step 6 — Write Deployment Artifact

Write `engagements/{customer}/deployment.md`:

```markdown
# Deployment — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Org:** {production org alias}
**Testing artifact:** engagements/{customer}/testing.md

## Summary
[2-3 sentences: what was deployed, deployment outcome, any issues encountered]

## Deployment Details
- **Deployment window:** {date and time}
- **Validation deploy:** PASS
- **Full deploy:** PASS | FAIL
- **Deploy duration:** {approx}
- **Components deployed:** {N}

## Deployed Components
| Component | API Name | Type | Status |
|---|---|---|---|

## Post-Deploy Verification
| Check | Expected | Actual | Status |
|---|---|---|---|

## Permission Set Assignments
| Permission Set | User | Status |
|---|---|---|

## Production Test Results
- New class coverage: {list with %}
- Org-wide coverage: {N}%
- Test failures: {N} (list if any)

## Issues Encountered
[Any problems during or after deploy, with resolution]

## Rollback Record
[If rollback was needed: what was rolled back, why, how]

## Open Questions
[Any post-deploy issues requiring follow-up]

## Evaluation
- Score: N/100
- Gate: PASS | FAIL
- Blocking findings: [list or "None"]
```

---

## Step 7 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/deployment-evaluation.json`
3. Run memory consolidation:
   - Promote durable learnings to `core-memory.md` (deployment patterns, prod-specific constraints, rollback decisions)
   - Clear `workflow-memory.md` back to empty template
   - Append to `daily-memory.md`: date, engagement complete, key outcome
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Deployment complete for {Customer Name}**
Artifact: engagements/{customer}/deployment.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of deployment outcome}

Please respond:
- APPROVED — to close this engagement phase
- REVISE: [your feedback] — to document additional remediation steps
```

---

## References

### Deployment Patterns
- `skills/deployment/references/deployment-patterns/trigger-handler-framework.md` — TriggerHandler pattern review checklist before production deploy
- `skills/deployment/references/deployment-patterns/account-service-layer.md` — service layer pattern to verify in deployed code
- `skills/deployment/references/deployment-patterns/apex-recipes-readme.md` — Apex Recipes deployment guide (scratch org → sandbox → production flow)
- `skills/deployment/references/deployment-patterns/lwc-recipes-readme.md` — LWC Recipes deployment guide

### Knowledge Base
- `knowledge/governor-limits.md` — production limit thresholds to monitor post-deploy
- `knowledge/security-baseline.md` — verify security config is intact post-deploy
