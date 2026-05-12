# SKILL: Pre-Sales
**Phase:** 0 of 6 (Optional)
**Prerequisite artifact:** None
**Output artifact:** `engagements/{customer}/pre-sales.md`
**Evaluation output:** `engagements/{customer}/evaluation/pre-sales-evaluation.json`

---

## Purpose

Produce a scoped, credible statement of work that the delivery team can stand behind. This phase exists to prevent surprises — sizing assumptions made here directly constrain every downstream phase.

You are not doing technical analysis in this phase. You are capturing the customer's stated problem, translating it into a delivery scope, surfacing risks that could affect pricing or timeline, and producing a requirements list that Discovery can ground in org reality.

---

## Before You Start

1. Create `engagements/{customer}/` if it does not exist
2. Create `engagements/{customer}/memory/` with empty `core-memory.md` and `workflow-memory.md`
3. Confirm the customer name, org alias (if known), and engagement type (Full Pipeline or Quick Delivery) with the user
4. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first to understand what is available, then read any documents marked as relevant to Pre-Sales (SOW drafts, RFPs, requirements briefs, previous engagement summaries).
5. Append to `workflow-memory.md`: session start, customer name, engagement type, stated problem summary
6. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files (e.g., a Salesforce feature capability, licensing detail, or platform behaviour), use `WebSearch` before making an assumption. Prefer results from `trailhead.salesforce.com`, `help.salesforce.com`, `developer.salesforce.com`, and `github.com/trailheadapps`. Do not guess — search first.

---

## Step 1 — Capture the Customer Problem

Ask the user to provide (or paste) the customer's stated business problem, goals, and any known constraints. Do not infer requirements — only work from what is explicitly provided.

For each stated goal, record:
```
Goal: [name]
Stated as: [customer's words]
Initial interpretation: [your translation to Salesforce delivery terms]
Assumptions: [what you are assuming that the customer has not stated]
Risks: [what could make this harder or more expensive than stated]
```

Append each goal to `workflow-memory.md`.

---

## Step 2 — Draft Requirements List

Convert the customer goals into a structured requirements list. Each requirement must be:
- Actionable (a developer or admin can build it)
- Bounded (has a clear definition of done)
- Attributed to a source goal

Format:
```
REQ-001: [Short name]
Source: [Goal name from Step 1]
Description: [What must be built or configured]
Acceptance criteria: [How you will know it is done]
Salesforce area: [Object / Automation / Integration / UI / Security / AI]
Complexity estimate: S / M / L / XL
Dependencies: [Other requirements this depends on]
```

Flag any requirement that:
- Touches more than 3 objects (escalation signal for Full Pipeline)
- Requires integration with an external system (always M or above)
- Involves Agentforce or Einstein features (confirm license availability)
- Has no clear acceptance criteria (mark NEEDS_CLARIFICATION)

---

## Step 3 — Scope and Sizing

Based on the requirements list, produce a sizing summary:

| Delivery mode criteria | Met? |
|---|---|
| Change is additive (no existing config removed) | Yes / No |
| ≤ 3 objects, ≤ 2 automation paths | Yes / No |
| No integration endpoints affected | Yes / No |
| Discovery and Design already exist for impacted area | Yes / No |

If ALL four are met → recommend Quick Delivery.
If ANY is not met → recommend Full Pipeline.

Produce a rough effort estimate:
- S requirements: ~0.5 days each
- M requirements: ~1-2 days each
- L requirements: ~3-5 days each
- XL requirements: >5 days, flag for decomposition

Total estimate range (min/max) and key assumptions that drive the range.

---

## Step 4 — Risk Register

List the top risks that could affect delivery. For each risk:
```
Risk: [Name]
Likelihood: HIGH / MEDIUM / LOW
Impact: HIGH / MEDIUM / LOW
Trigger: [What would activate this risk]
Mitigation: [What would reduce it]
Owner: [Customer / GDC / Shared]
```

Common pre-sales risks to consider:
- Org access not yet granted — blocks Discovery start
- Multiple orgs or sandboxes in scope — multiplies effort
- Data migration in scope — always HIGH complexity
- Integration with systems GDC does not control
- Customer has existing automation that may conflict
- Einstein / Agentforce licensing not confirmed

---

## Step 5 — Write Pre-Sales Artifact

Write `engagements/{customer}/pre-sales.md`:

```markdown
# Pre-Sales — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Engagement type:** Full Pipeline | Quick Delivery

## Summary
[2-3 sentences: customer problem, proposed solution, delivery approach]

## Customer Goals
| # | Goal | Salesforce Area | Priority |
|---|---|---|---|

## Requirements
| ID | Name | Source Goal | Area | Complexity | Dependencies | Status |
|---|---|---|---|---|---|---|

## Sizing
- **Recommended delivery mode:** Full Pipeline | Quick Delivery
- **Estimated effort:** {min}–{max} days
- **Key assumptions:** [list]
- **Exclusions:** [what is explicitly out of scope]

## Risk Register
| Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|

## Open Questions
[Numbered list of questions requiring customer input before Discovery]

## Evaluation
- Score: N/100
- Gate: PASS | FAIL
- Blocking findings: [list or "None"]
```

---

## Step 6 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/pre-sales-evaluation.json`
3. Run memory consolidation:
   - Promote durable learnings to `core-memory.md` (customer preferences, constraints, key contacts)
   - Clear `workflow-memory.md` back to empty template
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Pre-Sales complete for {Customer Name}**
Artifact: engagements/{customer}/pre-sales.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of scope and key risks}

Open questions requiring your input before Discovery begins:
{numbered list}

Please respond:
- APPROVED — to proceed to Phase 1: Discovery
- REVISE: [your feedback] — to revise this pre-sales scope
```

---

## References

- `skills/pre-sales/references/wa-framework/overview.md` — Well-Architected overview to align scope with platform health goals
- `skills/pre-sales/references/wa-framework/trusted-overview.md` — Trusted pillar, for security/compliance scope considerations
- `skills/pre-sales/references/wa-framework/easy-overview.md` — Easy pillar, for UX and automation scope considerations
- `skills/pre-sales/references/wa-framework/adaptable-overview.md` — Adaptable pillar, for integration and ALM scope considerations
- `skills/pre-sales/references/decision-guides/get-started-platform-decision-guides.md` — Platform decision framework for choosing automation approach
