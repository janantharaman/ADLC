---
source: hand-authored — distilled from CPQToRCAMigration ADLC repo (implementation/SKILL.md v1, design/SKILL.md v1, SmartBytes discovery-evaluation.json) April–May 2026
topic: CPQ to RLM Migration
section: implementation-guide
last-updated: 2026-05-18
---

# CPQ to RLM Migration — Implementation Guide

## Non-Negotiable Rules for Every Migration

1. **Steps execute in dependency order** — never start a step if its dependency step has not passed validation
2. **Orphan count = 0 is a hard gate** — any orphan record after a migration step is a blocking error; do not proceed until resolved
3. **Every mutation requires explicit human approval** — present action, scope, and target org; wait for confirmation
4. **Never deploy to production** — confirm target org is a sandbox before every deploy
5. **CPQ stays installed throughout** — never recommend or execute CPQ package uninstall during Implementation; not until all Wave 2 items are validated
6. **Cross-reference fields are mandatory** — `MigrationSource__c` and all `CPQ*Id__c` fields must be populated on every migrated record
7. **85% Apex test coverage before proceeding** — run tests after every Apex deploy; do not proceed if coverage < 85%
8. **Parity must pass before gate** — if any smoke-test scenario fails parity, resolve before emitting the gate
9. **Rollback owner is always a named human** — the agent never executes rollback; it produces the rollback queries for human execution

---

## Phase A — Pre-Migration Setup

### Deploy Cross-Reference Custom Fields

Deploy these fields before any data is loaded. They are required for bridge-period operation, delta loads, and rollback.

**Wave 1 fields:**

| Object | Field | Type |
|---|---|---|
| Quote | `MigrationSource__c` | Picklist (CPQ, RLM) |
| Quote | `CPQQuoteId__c` | Text(18) |
| QuoteLineItem | `MigrationSource__c` | Picklist (CPQ, RLM) |
| QuoteLineItem | `CPQQuoteLineId__c` | Text(18) |
| Asset | `MigrationSource__c` | Picklist (CPQ, RLM) |
| Asset | `CPQSubscriptionId__c` | Text(18) |
| AssetStatePeriod | `MigrationSource__c` | Picklist (CPQ, RLM) |

**Wave 2 fields:**

| Object | Field | Type |
|---|---|---|
| AttributeSet | `MigrationSource__c` | Picklist |
| AttributeSet | `CPQAttributeSetId__c` | Text(18) |
| ProductAttribute | `CPQConfigAttrId__c` | Text(18) |
| PriceAdjustmentSchedule | `MigrationSource__c` | Picklist |
| PriceAdjustmentSchedule | `CPQDiscountScheduleId__c` | Text(18) |
| PriceAdjustmentSchedule | `CPQBlockPriceId__c` | Text(18) |

After deploy, confirm fields are queryable before proceeding.

---

## Phase B — Wave 1 Migration (Strict Dependency Order)

### Step 1 — Product2 (Additive Update)

Populate RLM-specific fields on existing Product2 records. Do not re-create products — update in place.

| Field | Derivation |
|---|---|
| `ProductClass` | `'Set'` if has ProductOption children; `'Component'` if appears as option child; else `'Simple'` |
| `ProductSellingModel` lookup | Map from `SBQQ__SubscriptionPricing__c` — Fixed Price → TermOptimized; Usage Based → UsageBased; null → One-Time |

**Validation:** `SELECT COUNT() FROM Product2 WHERE ProductClass != null AND IsActive = true` must equal active product count.

### Step 2 — PricebookEntry (New Entries in RLM Pricebook)

Create new entries in the RLM-designated pricebook. Confirm RLM pricebook ID first. Map: Product2Id (direct), UnitPrice (direct), IsActive (direct), CurrencyIsoCode (direct), `UseStandardPrice = false`.

### Step 3 — ProductComponentGroup (Bundle Feature Groups)

Load before ProductRelatedComponent. `SBQQ__ProductFeature__c` → `ProductComponentGroup`.

| Source | Target | Notes |
|---|---|---|
| `SBQQ__ConfiguredSKU__c` | `ProductId` | Parent bundle lookup |
| `SBQQ__Number__c` | `Sequence` | Column order |

**Validation:** Count must equal `SBQQ__ProductFeature__c` count.

### Step 4 — ProductRelatedComponent (Bundle Options)

Depends on Step 3. `SBQQ__ProductOption__c` → `ProductRelatedComponent`.

Key resolution: `SBQQ__Feature__c` → `ProductComponentGroupId` — build an Id map by Name in the batch class; do not query inside the loop.

**Validation (orphan check):** `SELECT COUNT() FROM ProductRelatedComponent WHERE ParentProductId = null` must be 0.

### Step 5 — Quote (SBQQ__Quote__c)

Load only records matching the agreed status filter (locked before this step runs — no exceptions). Prefix migrated quote names with `MIGRATED-`. Populate `CPQQuoteId__c` = source `Id` (this is the external ID for delta upserts).

Status value mapping — typical: Draft→Draft, In Review→InReview, Approved→Approved, Ordered→Ordered, Contracted→Contracted.

**Validation:** Count by status must match source counts.

### Step 6 — QuoteLineItem (SBQQ__QuoteLine__c)

Depends on Step 5 being fully validated. Resolve `QuoteId` by joining on `CPQQuoteId__c` — pre-load a `Map<Id, Id>` of {SBQQ__Quote__c.Id → Quote.Id} before processing, never query inside the loop.

**Validation (orphan check):** `SELECT COUNT() FROM QuoteLineItem WHERE QuoteId = null AND MigrationSource__c = 'CPQ'` must be 0.

### Step 7 — Asset + AssetStatePeriod (Subscriptions)

Two-pass: Asset first, then AssetStatePeriod.

**Pass 1 — Asset:** Map `SBQQ__Account__c` → `AccountId`, `SBQQ__Product__c` → `Product2Id`, `SBQQ__SubscriptionEndDate__c` → `UsageEndDate`, `Status = 'Purchased'`, `CPQSubscriptionId__c = Id`.

**Pass 2 — AssetStatePeriod:** Resolve `AssetId` via `CPQSubscriptionId__c` map. For MDQ subscriptions: one ASP per `SBQQ__Dimension__c` segment (second pass after Wave 1, see Phase C Step 23).

**Validation:** Asset count must equal active subscription count. `SELECT COUNT() FROM AssetStatePeriod WHERE AssetId = null` must be 0.

### Step 8 — Wave 1 Freeze, Delta Load, and Go-Live

**Requires explicit human approval before any action.**

Sequence:
1. **Freeze CPQ quoting** — remove `SBQQ User` / `SBQQ Admin` permission sets from active users, or set Custom Setting freeze flag
2. **Delta extract** — query records modified after full extract run: `WHERE LastModifiedDate > {full_extract_datetime}`
3. **Delta upsert** — upsert using `CPQQuoteId__c` / `CPQSubscriptionId__c` as external IDs
4. **Go-live validation** — re-run all Wave 1 validation queries; all orphan counts must be 0
5. **Enable RLM quoting** — assign RLM permission sets per Design spec

**Rollback trigger:** orphan count > 0 OR count mismatch > 0.1% OR pricing error within 2 hours of go-live.
**Rollback action:** Hard delete all `Quote`, `QuoteLineItem`, `Asset`, `AssetStatePeriod` where `MigrationSource__c = 'CPQ'`. Re-assign CPQ permission sets. **Human must execute and confirm — not the agent.**

---

## Phase C — Wave 2 Migration (Post-Bridge, Phased)

CPQ must remain installed. Do not uninstall until every Wave 2 item is validated and signed off.

### Record-Migrate Objects (Steps 12–17 in SKILL.md sequence)

Execute in order:
1. **AttributeSet** ← `SBQQ__AttributeSet__c` — Direct Name/Description mapping + cross-reference
2. **ProductAttribute** ← `SBQQ__ConfigurationAttribute__c` — Depends on AttributeSet; resolve `AttributeSetId` via `CPQAttributeSetId__c` map
3. **PriceAdjustmentSchedule** ← `SBQQ__DiscountSchedule__c` — Value map: `Range` → `Tier`, `Term` → `Term`, `Percent` → `Percent`
4. **PriceAdjustmentTier** ← `SBQQ__DiscountTier__c` — Depends on PriceAdjustmentSchedule; resolve parent via `CPQDiscountScheduleId__c`
5. **Block Prices** ← `SBQQ__BlockPrice__c` — If ≤ 20 products and < 5 tiers: `PriceAdjustmentSchedule (Block)`; else Decision Table PricingStep
6. **Contracted Prices** ← `SBQQ__ContractedPrice__c` — Execute whichever option was confirmed in Design (A/B/C)

### Logic-Rebuild Objects

These require no bulk data load — CPQ configuration is analysed and re-implemented as RLM-native constructs:

#### Summary Variables → PricingStep (Apex)
For each `SBQQ__SummaryVariable__c`:
- Write Apex class `{VariableName}SummaryAggregation` — queries `QuoteLineItem` with equivalent filter and aggregation
- All SOQL must use `WITH SECURITY_ENFORCED`; no SOQL in loops
- Deploy → run Apex test → confirm ≥ 85% coverage → create PricingStep pointing to Apex class

#### Price Rules → PricingProcedure / PricingStep
Process active rules in `SBQQ__EvaluationOrder__c` ascending. For each rule:
- `ConditionsMet = All/Any` → PricingLogic or ContextMapping step
- `ConditionsMet = 'Custom'` → Apex step (deploy, test first)
- Translate `SBQQ__PriceCondition__c` → step conditions; `SBQQ__PriceAction__c` → step outputs
- Flag any PriceAction targeting an SBQQ field with no RLM equivalent — those need new custom fields on `Quote`/`QuoteLineItem`

#### QCP Scripts → PricingProcedure Steps / Apex
For each QCP hook, sequence PricingSteps to match original CPQ hook ordering:
- `onInit` → first step in PricingProcedure
- `onBeforeCalculate` → before price-rule steps
- `onBeforePriceRules` → immediately before price-rule step block
- `onAfterPriceRules` → immediately after price-rule step block
- `onAfterCalculate` → last step in PricingProcedure
- `onAfterGroupCalculate` → post-processing step (no group hook in RLM)

After deploying each Apex class, run `run_code_analyzer` — flag any HIGH/CRITICAL findings before proceeding.

Confirm no deployed class calls `SBQQ.ServiceRouter` — this CPQ API does not exist in RLM.

#### Product Rules + Configuration Rules → CML
Process in order: Validation → Alert → Selection → Filter.
- `ConditionsMet = 'Custom'` rules require Apex CML action
- After deploy, verify `IsActive = true` on each rule

#### MDQ Dimensions → ProductSellingModel + AssetStatePeriod (2nd Pass)
- Create `ProductSellingModel` records per Design spec
- Link MDQ products to new PSMs via Product2 update
- Query active Dimension records and create one `AssetStatePeriod` per segment, linked to parent Asset via `CPQSubscriptionId__c` map

#### Quote Templates → OmniStudio Document Generation
Agent-produced specification only — human builds the template. For each template, produce:
- Complete field token mapping (`{!SBQQ__Quote__c.Name}` → `{!Quote.Name}` etc.)
- Section structure spec
- E-signature connector confirmation

---

## Parity Validation (Before Phase Gate)

Before writing the artifact, run a smoke test — not the full Testing phase but a sanity check that pricing migration did not silently drop rules.

For 3–5 representative quote scenarios agreed with the customer:
1. Run scenario through CPQ — capture `SBQQ__NetAmount__c`, `SBQQ__GrandTotal__c`, line-level `SBQQ__NetPrice__c`
2. Run same scenario through RLM — capture `TotalAmount`, `GrandTotalAmount`, line-level `UnitPrice`
3. Compare outputs line by line — flag any delta > 0.01% as a blocking discrepancy
4. Document results — scenario name, CPQ output, RLM output, delta, pass/fail

If any scenario fails parity: identify which PricingStep is producing the incorrect value, correct it, re-run before emitting the gate.

---

## Deployment Tooling Reference

| Component Type | Recommended Tool | Known Issues |
|---|---|---|
| Context Definitions | Copado | Manual reference check post-deploy; CI/CD causes duplicates |
| Revenue Cloud Settings / Pricing Settings | Copado | None reported |
| Product Discovery Settings | Copado | None reported |
| Expression Sets + Versions | Copado / SFDX | Delete old versions from repo before full SFDX deploy |
| CML (Constraint Modelling Language) | MCDM / Manual | Reference links broken post-deploy; Groups buggy in MCDM |
| Decision Table Rows (data) | Copado / MCDM | Manual CSV has overlap issues at scale |
| PCM Data (Product2, PSM, Attributes) | MCDM / Prodly | None reported |
| Legal Entity | MCDM (insert only) | Updates fail via MCDM — use Data Loader for updates |
| Pricebook / PricebookEntry | MCDM / Copado | None reported |
| Custom Apex | Metadata deploy via Headless 360 | Always run tests post-deploy |

---

## Implementation Order — Full Dependency Sequence

```
Phase A: Pre-Migration Setup
  ├── Deploy cross-reference fields (Wave 1 + Wave 2)
  └── Verify RLM object accessibility

Phase B: Wave 1 (Day 1 Go-Live)
  ├── Product2 (additive update)
  ├── PricebookEntry (new RLM entries)
  ├── ProductComponentGroup (depends: Product2)
  ├── ProductRelatedComponent (depends: PCG)
  ├── Quote (depends: Account, Opportunity, Pricebook2)
  ├── QuoteLineItem (depends: Quote, Product2, PricebookEntry)
  ├── Asset + AssetStatePeriod (depends: Product2, Contract, Account)
  └── Freeze → Delta Load → Go-Live → Enable RLM

Phase C: Wave 2 (Post-Bridge, Phased)
  ├── Record-Migrate (AttributeSet → ProductAttribute → PriceAdjSched → PriceAdjTier → BlockPrices → ContractedPrices)
  ├── Logic-Rebuild (SummaryVariables → PriceRules → QCP Scripts → ProductRules → ConfigRules → MDQ 2nd Pass)
  └── OmniStudio Document Generation (human-built; agent spec only)
```
