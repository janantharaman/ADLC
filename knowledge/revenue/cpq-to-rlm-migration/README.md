---
topic: CPQ to RLM Migration
section: index
last-updated: 2026-05-18
---

# CPQ to Revenue Cloud (RLM) Migration — Knowledge Base

This folder contains grounding knowledge for Salesforce CPQ → Revenue Lifecycle Management (RLM) migration engagements. All content is distilled from the ADLC CPQToRCAMigration delivery framework (SKILL.md v1, real SmartBytes engagement data) and the LKInsurance Revenue Cloud knowledge base.

> **Naming note:** "Revenue Cloud Advanced (RCA)", "Revenue Lifecycle Management (RLM)", and "Agentforce Revenue Management (ARM)" all refer to the same native-platform product. This folder uses RLM throughout.

---

## Files in This Folder

| File | Contents |
|---|---|
| `overview.md` | What the migration is, why it's happening (CPQ EoS), the five migration blocker categories, bridge period strategy, delivery sizing, migration approaches |
| `data-model.md` | Complete CPQ → RLM object mapping table, PCM dependency load order, Wave 1/Wave 2 scope, migration strategy patterns, cross-reference field specs, key field mappings |
| `discovery-questions.md` | Migration blocker scorecard with thresholds, step-by-step SOQL inventory guide, open questions that must be resolved before Design, common SOQL failures in CPQ orgs |
| `implementation-guide.md` | Wave 1 and Wave 2 step-by-step execution, dependency order, Apex batch patterns, delta load/freeze strategy, parity validation, deployment tooling reference |
| `design-patterns.md` | PricingProcedure architecture, Summary Variable replacement pattern, Contracted Price options A/B/C, product catalog re-model, MDQ re-architecture, bridge period design, integration patterns, permission set architecture, rollback design, evaluation rubric |
| `gotchas.md` | Common failures and surprises: BLNG SOQL access restriction, orphan data rates, brownfield CPQSM reconciliation, QCP bug patterns, CML MCDM reference breakage, Context Definition CI/CD duplicates, DRO two-pass rule loading |

---

## How to Use This Knowledge

### For Discovery
1. Read `overview.md` — understand the five blocker categories and bridge period
2. Use `discovery-questions.md` — run the SOQL inventory, score the migration blocker scorecard
3. Check `gotchas.md` — SOQL failure workarounds before running any queries

### For Design
1. Read `data-model.md` — understand the object mapping, load dependency order, and cross-reference field requirements
2. Read `design-patterns.md` — select the correct PricingProcedure architecture, contracted price option, bridge period design
3. Check `gotchas.md` — product catalog redesign mandate, Context Definition complexity, MDQ re-architecture

### For Implementation
1. Read `implementation-guide.md` — execute steps in dependency order
2. Read `data-model.md` — field mapping tables and tooling thresholds
3. Check `gotchas.md` — deployment tool selection, CML post-deploy verification, DRO two-pass pattern

---

## Key Facts to Remember

- **CPQ End of Sale:** March 2025. Estimated End of Support: 2029–2030.
- **Not a lift-and-shift:** Product catalog must be re-modelled; pricing logic must be rebuilt.
- **Bridge period:** CPQ and RLM coexist until the last active CPQ subscription renews into RLM. CPQ package must not be uninstalled until then.
- **QCP doesn't run in RLM:** Every QCP function = a rebuild, not a migration.
- **Summary Variables have no native equivalent:** Each one = an Apex-invoked PricingStep.
- **Cross-reference fields are mandatory:** `MigrationSource__c` and `CPQ*Id__c` fields must be on all target objects before any data is loaded.
- **BLNG SOQL is blocked on demo orgs:** Always get production data for billing volumes.
