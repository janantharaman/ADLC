---
source: hand-authored — distilled from CPQToRCAMigration ADLC repo (discovery/SKILL.md v1, design/SKILL.md v1, implementation/SKILL.md v1, core-memory SmartBytes engagement, common-failures log) April–May 2026
topic: CPQ to RLM Migration
section: gotchas
last-updated: 2026-05-18
---

# CPQ to RLM Migration — Gotchas and Common Failures

## Org-Level Gotchas

### BLNG Objects Are Not Accessible via Standard SOQL on Demo/Sandbox Orgs

All `blng__*` sObjects frequently return "sObject type not supported" via standard REST API on demo orgs and some sandboxes. This is not a permissions issue — it is an API endpoint restriction. Use the Tooling API or request a data export from the customer's production org. Never report zero BLNG volumes without confirming the API is accessible — the actual volumes may be large.

### Demo Org Data Volumes Are Near-Zero but Config Is Production-Representative

CPQ demo orgs (like `sfcpqdemo`) typically have 0–2 Quotes and 0 active Subscriptions. This means:
- Bridge period cannot be estimated from the demo org — always request production subscription inventory
- Data complexity scoring categories (Open Quotes, Active Subscriptions) will score LOW on a demo — configuration complexity categories (Price Rules, QCP, MDQ) are production-representative
- Never use demo org data volumes as the basis for Implementation sprint estimation

### CPQSM Connector Creates Brownfield RLM Configuration

If the CPQSM (Subscription Management) connector is installed (look for `SM_CartItemBefore` or `SM_RevenueAsyncOperation` triggers), the org may already have partial RLM objects: ProductCatalogs, ProductSellingModels, ProductCategories, ProductSellingModelOptions, AttributeDefinitions. These must be reconciled before Design. Options: reuse existing (preferred if clean), or rearchitect from scratch. Attempting to load new RLM objects that conflict with existing ones will produce constraint errors.

---

## CPQ Calculation Engine Gotchas (Source Side)

### QCP JavaScript Does Not Run in RLM

The Quote Calculator Plugin (`SBQQ__CustomScript__c`) is JavaScript that executes in the CPQ calculation engine. This engine does not exist in RLM. Every QCP function must be rebuilt — there is no partial migration path. The target is PricingProcedure steps (Apex-invoked, Flow, or Decision Table depending on function complexity). Budget rebuild time proportional to line count and hook complexity.

### QCP Assignment vs Comparison Bug Pattern

A common bug in production QCP code: using `=` (assignment) instead of `==` (comparison) in conditional logic. This causes a condition to always evaluate to `true` because the assignment succeeds. The customer may not know this exists — it may be intentional behaviour that was never corrected, or it may be a genuine bug. **Always confirm intended behaviour with the customer before specifying the PricingProcedure rebuild.** Never carry the bug forward silently.

### Summary Variables Have No Direct RLM Equivalent

`SBQQ__SummaryVariable__c` records aggregate values across quote lines (SUM, MIN, MAX, COUNT). There is no native aggregation step type in RLM PricingProcedures. Every summary variable must be rebuilt as an Apex-invoked PricingStep that queries `QuoteLineItem` with an equivalent filter. If > 15 summary variables exist, escalate to architect — Decision Table consolidation may be needed.

### Price Rule Evaluation Order Conflicts Are Silent

CPQ Price Rules evaluate in numeric order. If two rules write to the same field, the higher-order rule wins with no warning. When rebuilding as PricingSteps, the sequence must be preserved exactly. Any change in sequence changes pricing outcomes. Always document the full rule set with evaluation orders before specifying PricingStep sequences.

### Amendment Quotes Contain Delta Lines — Not Full Replacements

CPQ amendment quotes contain delta lines (`+5 seats`, `-2 seats`), not full replacement quantities. Any Wave 1 migration logic that reads QuoteLine quantities and assumes they represent total contracted quantity will produce incorrect Asset records. Always check `SBQQ__Quote__c.SBQQ__Type__c` (`Quote`, `Amendment`, `Renewal`) before processing — amendment lines need different handling.

---

## Design Phase Gotchas

### CPQ and RLM Cannot Coexist as a Stable Long-Term Architecture

CPQ and RLM can coexist during the bridge period, but this is a time-limited production state, not a permanent architecture. The bridge period must have a defined end date driven by the latest active CPQ subscription. Do not scope a "run both forever" architecture — it is not supported by Salesforce and leads to data integrity debt.

### Product Catalog Redesign Is Mandatory

CPQ's product catalog (one SKU per product variation) and the RLM catalog (attributes-based — one product, many configurations) are architecturally incompatible. You cannot bulk-load CPQ ProductOptions and ProductFeatures directly into RLM and have a functional attribute-based catalog. The catalog must be redesigned with the customer. Never scope a CPQ-to-RLM migration as "just a data migration" for the product catalog.

### Data Segregation During Bridge Requires Explicit Record Type Design

During the bridge period, `Order` and `Contract` standard objects are written to by both CPQ and RLM. Without explicit Record Type differentiation, it is impossible to determine which records are CPQ-originated and which are RLM-originated. A CPQ-originated `Order` must never route to RLM amendment logic; an RLM-originated `Order` must never route to CPQ renewal logic. Design record type segregation before go-live.

### MDQ Re-Architecture Is Not a Data Load

MDQ (`SBQQ__Dimension__c`) does not migrate to a single RLM object. MDQ requires:
1. Re-architecture of the affected products to use `ProductSellingModel` with the appropriate type
2. A second-pass migration of `AssetStatePeriod` records (one per MDQ segment) after Wave 1 Assets are created

Any engagement with MDQ must budget this as a separate workstream. The 63% orphan rate seen in real orgs (Dimensions with null `Product__c`) means pre-migration data triage is often required first.

### Contracted Prices Strategy Must Be Confirmed Before Design Is Approved

There is no default correct approach for migrating `SBQQ__ContractedPrice__c`. Three options exist:
- **Option A:** Account-specific PricebookEntry overrides (simple, high volume)
- **Option B:** Decision Table PricingStep (account + product lookup)
- **Option C:** Custom Object + Apex PricingStep (complex date-range or family-based discounting)

The choice affects both the Design phase and the Wave 2 data load. An architect must confirm the approach — this cannot be left as TBD in the Design artifact.

### Context Definitions Must Be Designed in Design Phase — Not During Build

Context Definitions define what data fields are available at each stage of the RLM revenue process. Misconfigured or overly complex Context Definitions are a top cause of implementation delays. Twin fields between Quote Lines and Order Lines must be explicitly mapped here. Never leave Context Definition design to the build phase.

---

## Implementation Gotchas

### BillingSchedules Must Not Be Directly Inserted

Never insert `BillingSchedule` or `BillingScheduleGroup` records via Apex DML or Data Loader. These are generated by Context Service (BillingContext Definition). Directly inserted records lack required internal field values and will error during invoice generation. Use the `/commerce/invoicing/billing-schedules/actions/create` API or the `createBillingSchedules` invocable action.

### SBQQ.ServiceRouter Does Not Exist in RLM

Any Apex class that calls `SBQQ.ServiceRouter` must be rebuilt — this CPQ API entry point does not exist in RLM. Identify all references during Discovery, flag them as BLOCKER-level items. The RLM replacement is the standard Connect REST API or direct Apex against native platform objects.

### Triggers on Standard Objects Fire for Both CPQ and RLM Records During Bridge

Triggers on `Order`, `Contract`, and `Asset` that reference SBQQ fields will fire for both CPQ-originated and RLM-originated records during the bridge period. SBQQ fields will return null on RLM-originated records. Any trigger or flow that reads SBQQ fields on these objects without null-checking will produce errors or incorrect behaviour from Day 1 of go-live. Fix these before go-live — not after.

### Apex Coverage Must Be Run After Every Deploy — Not Just at Gate

CPQ orgs with 2,000+ Apex classes have coverage-sensitive deployments. A class that deploys with 85% coverage may drop below threshold if a related class changes. Run `run_apex_test` after every individual deploy, not just at the phase gate. Do not batch deploys and test once at the end.

### ProductConfigurationRule Requires Salesforce npm Migration Utility

`ProductConfigurationRule` stores rule content in a BLOB field containing org-specific product IDs. MCDM and Data Loader will fail silently or create broken rule references. You **must use the Salesforce-provided npm migration utility** to migrate ProductConfigurationRule records. This is not optional.

### CML Reference Links Break After MCDM Deploy

After deploying CML code via MCDM, the code may be present in the target org but reference links are broken (references point to nothing). Groups in CML models have additional known issues in MCDM. **Post-deployment manual verification of all CML model references is required after every MCDM deploy.** This is a known platform limitation as of Spring '26.

### Context Definition CI/CD Creates Duplicate Mappings

Running CI/CD pipelines (Travis CI, GitHub Actions, Copado pipelines) multiple times on Context Definitions creates **duplicate mappings** in the target org on subsequent runs. This is a known issue. Options: (a) add a pre-deployment step to detect and remove duplicates, or (b) manage Context Definition deployments manually (the approach used by Finastra after encountering this in production).

### DRO Rule References Must Be Set via UPDATE — Not INSERT

`FulfillmentStepDefinition`, `ProductFulfillmentScenario`, and related DRO objects contain JSON fields with internal RuleSet references. These references **cannot be set on INSERT** — they must be populated in a subsequent UPDATE operation. Tools that do only upsert will leave these fields null. Two-pass migration is required for all DRO objects with JSON-based rule references.

---

## Data Quality Gotchas Found in Real Engagements

### High Orphan Rates Are Common in Mature CPQ Orgs

The SmartBytes engagement found:
- `SBQQ__ProductOption__c`: 47% orphaned (null `SBQQ__ConfiguredSKU__c`)
- `SBQQ__ProductFeature__c`: 57% orphaned (null `SBQQ__ConfiguredSKU__c`)
- `SBQQ__Dimension__c`: 63% orphaned (null `SBQQ__Product__c`)

A bulk load of these objects into RLM will produce high orphan counts and fail validation gates. **Pre-migration data triage sprint is required before Wave 1 for any org with orphan rates > 10%.** Budget this as explicit scope — not a quick cleanup task.

### Multi-Currency Multiplies PricebookEntry Volume

If the org has multi-currency enabled, there is one `PricebookEntry` per product per currency per pricebook. A 500-product catalog in 5 currencies = 2,500 PricebookEntry records just for the standard pricebook. The tooling decision (Apex Batch vs Bulk API) must account for the multiplied volume, not just the raw product count.

### sbaa Advanced Approvals Chains Span Both CPQ and Billing Workstreams

In orgs with both CPQ and Billing, `sbaa__ApprovalChain__c` records often cover both quoting approvals (Discounting, Legal) and billing approvals (Invoice Review, Billing Run, Credit Note). These cannot be separately migrated — the sbaa approval architecture must be redesigned as a unified plan covering both workstreams. Splitting the migration by workstream and leaving sbaa for later is not viable.
