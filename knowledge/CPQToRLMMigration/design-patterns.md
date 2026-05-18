---
source: hand-authored — distilled from CPQToRCAMigration ADLC repo (design/SKILL.md v1, implementation/SKILL.md v1, SmartBytes core-memory and discovery-evaluation) April–May 2026
topic: CPQ to RLM Migration
section: design-patterns
last-updated: 2026-05-18
---

# CPQ to RLM Migration — Design Patterns

## Pricing Procedure Architecture

### From CPQ Price Rules to RLM PricingSteps

Each active CPQ Price Rule becomes one or more `PricingStep` records in a `PricingProcedure`. The PricingProcedure is the container; PricingSteps execute in sequence within it.

**Step type selection:**

| Condition | Step Type |
|---|---|
| All/Any conditions, field-based output | `PricingLogic` or `ContextMapping` |
| Tabular lookup (rate-based, product-attribute-based) | `DecisionTable` |
| `ConditionsMet = 'Custom'` — complex logic | Apex-invoked step |
| QCP hook replacement requiring callouts or complex state | Apex-invoked step |

**PricingProcedure structure for a standard org:**
- One procedure per major pricing context: standard quote, amendment, renewal
- Steps execute in evaluation order — sequence matters; preserve CPQ evaluation order exactly
- QCP hook replacement steps must be sequenced to match original hook ordering (onInit → onBeforeCalculate → onBeforePriceRules → price rule steps → onAfterPriceRules → onAfterCalculate)

### Summary Variable Replacement Pattern

`SBQQ__SummaryVariable__c` records have no native RLM equivalent. The replacement pattern:

```
1 Summary Variable
    → 1 Apex class: {VariableName}SummaryAggregation
        - Queries QuoteLineItem with equivalent filter
        - Applies SUM/MIN/MAX/COUNT/AVG aggregation
        - Returns result as a PricingContext variable
    → 1 PricingStep (Apex-invoked)
        - Positioned before any price-rule steps that consume the variable
        - Output: named context variable replaces SBQQ summary variable reference
```

If > 15 summary variables exist: evaluate Decision Table consolidation — multiple similar aggregations may share one table.

### Contracted Price Design Options

| Option | When to Use | Approach |
|---|---|---|
| **A — Account PricebookEntry override** | Simple per-account flat price overrides, no date logic, low volume | Create account-specific PricebookEntry records in the RLM pricebook |
| **B — Decision Table PricingStep** | High-volume contracted prices with consistent logic (account + product → price) | PricingStep of type DecisionTable with AccountId as input column, AdjustedPrice as output |
| **C — Custom Object + Apex PricingStep** | Complex logic: date ranges, product families, discount stacking | Custom object mirroring ContractedPrice__c + Apex PricingStep that reads from it |

An architect must confirm the approach. This choice affects both the Design artifact and the Wave 2 data load plan.

---

## Product Catalog Re-Model Patterns

### Re-Model, Don't Migrate

The product catalog section of any Design artifact must show **attribute-based redesign**, not a flat list of CPQ SKUs renamed for RLM. The re-model, don't migrate principle is non-negotiable.

**CPQ catalog pattern:** One SKU per product variation
- Software v1 Enterprise US, Software v1 Enterprise EU, Software v1 Pro US, Software v1 Pro EU → 4 separate `Product2` records

**RLM catalog pattern:** One product + attributes
- Software v1 → 1 `Product2` + `AttributeDefinition` records for Edition (Enterprise, Pro) and Region (US, EU)

### Bundle Re-Model

| CPQ Object | RLM Target | Notes |
|---|---|---|
| `SBQQ__ProductFeature__c` | `ProductComponentGroup` | Feature group → component group; one per feature |
| `SBQQ__ProductOption__c` | `ProductRelatedComponent` | Option → related component; cardinality rules preserved |

For bundles with > 20 options: HIGH complexity for attribute-based re-modelling. Each option that was previously a separate SKU must be evaluated — can it become an attribute value, or must it remain a separate component?

### MDQ Re-Architecture Pattern

| CPQ Construct | RLM Replacement |
|---|---|
| `SBQQ__Dimension__c` (time segment definition) | `ProductSellingModel` (Type: TermOptimized or SubscriptionTerm) |
| MDQ quote line (segmented pricing) | `ProductRampSegment` on the ProductSellingModel |
| Active MDQ subscription segment | `AssetStatePeriod` (one per active segment) |

For each MDQ product:
1. Create/configure `ProductSellingModel` with segment definition
2. Link affected `Product2` records to the new PSM
3. Second-pass migration: create `AssetStatePeriod` per active `SBQQ__Dimension__c` segment

---

## Bridge Period Design Patterns

### Record Type Segregation — Mandatory

Every org transitioning to RLM during a bridge period must introduce Record Type segregation on at minimum: `Order` and `Contract`. CPQ-originated records and RLM-originated records must be distinguishable by Record Type. Without this:
- Triggers and flows cannot conditionally route processing
- Reporting cannot split CPQ vs. RLM pipeline
- Amendment/renewal routing decisions cannot be automated

If no record type differentiation exists, Design must introduce new record types as part of the RLM go-live deployment.

### Amendment and Renewal Routing During Bridge

| Transaction Type | Source | Goes To | Notes |
|---|---|---|---|
| New business | Any | RLM | Always from Day 1 of go-live |
| Amendment of CPQ-originated contract | CPQ contract | CPQ | Must not route to RLM |
| Renewal of CPQ subscription | CPQ subscription | RLM at renewal | Migration moment — renewal in RLM triggers Wave 1 subscription migration for that account |
| Add-on to active CPQ contract | CPQ contract | CPQ (during bridge) | Discuss with customer — some prefer RLM even for add-ons |

### Cross-System Reporting During Bridge

During the bridge period, revenue pipeline data is split across CPQ (`SBQQ__Quote__c`) and RLM (`Quote`). Options:
1. **CRM Analytics unified dataset** — build a combined dataset joining both object types
2. **Custom report type** — custom report type spanning CPQ and RLM objects
3. **Manual process** — separate CPQ and RLM reports combined offline

Always confirm which approach the customer's reporting team requires — this is frequently overlooked until go-live week.

---

## Integration Re-Architecture Patterns

### CPQ REST API → RLM Connect API

| CPQ API | RLM Replacement |
|---|---|
| `/services/apexrest/SBQQ/v1/` (price a quote) | RLM Pricing Procedure invocation via Connect REST API |
| `/services/apexrest/SBQQ/v1/` (calculate) | Standard Quote API with PricingProcedure context |

Any external system calling the CPQ REST API must be re-pointed before go-live. These callouts will break on Day 1 if CPQ permissions are removed.

### ERP Order Sync Pattern

If an ERP reads CPQ-extended fields on `Order` (`SBQQ__Quote__c`, `SBQQ__Contracted__c`, `SBQQ__Ordered__c`):
1. Identify every SBQQ field the ERP reads from `Order`
2. Map each to the RLM equivalent field on `Order` (or a new custom field if no equivalent exists)
3. Modify the ERP mapping table — or build a field bridging layer if the ERP cannot be changed
4. During bridge: ERP must handle both CPQ-extended fields (on CPQ-originated Orders) and RLM fields (on RLM-originated Orders) simultaneously

### Tax Integration Pattern

CPQ has a native tax hook (`SBQQ__TaxPlugin__c` interface). RLM uses a different invocation point — the TaxEngine record with a TaxTreatment linked to a TaxPolicy linked to BillingSchedules. The migration steps:
1. Configure `TaxEngine` record (Avalara, Vertex, or custom)
2. Create `TaxTreatment` with `IsTaxable = true` and the correct `TaxEngineId`
3. Create `TaxPolicy` referencing the TaxTreatment
4. Link TaxPolicy to BillingSchedules via BillingPolicy chain
5. Decommission CPQ tax plugin after Wave 2 validation

**Gotcha:** If `TaxEngine.Status` is not `Active`, RLM silently skips tax calculation and records zero tax — no error. Always verify TaxEngine Status before invoice testing.

---

## Permission Set Design Pattern

RLM requires new permission sets because the underlying objects change from `SBQQ__*` to native platform objects. CPQ permission sets do not carry over.

**Layered permission set architecture (from Design SKILL.md):**

| Set | Assigned To | Core Permissions |
|---|---|---|
| `RLM_SalesUser_Base` | All users touching RLM | Read/Create/Edit on Quote, QuoteLineItem, ProductCatalog; Read on Product2, Pricebook2 |
| `RLM_SalesManager_Base` | Managers | Extends Base; adds Approve on Quote, View All on QuoteLineItem |
| `RLM_AdminUser_Base` | Admins | Full access to RLM configuration objects |
| `RLM_Quoting_Create` | Reps who create quotes | Create on Quote |
| `RLM_Pricing_Admin` | Pricing team | Create/Edit/Delete PricingProcedure, PricingStep |
| `RLM_ProductCatalog_Admin` | Catalog team | Create/Edit/Delete Product2, ProductCatalog, ProductRelatedComponent |

Naming convention: `Role_Cloud_Access` — e.g., `SalesRep_RLM_Standard`.

**Verify license compatibility:** RLM requires Salesforce or Revenue Cloud user licenses. Community or Partner license users cannot access RLM objects. Confirm during Design — not after go-live.

---

## Rollback Design — Non-Negotiable Artifact Content

Every Design artifact must include explicit rollback plans for both Wave 1 and Wave 2. A Design artifact without a rollback plan will not pass the evaluation gate.

### Wave 1 Rollback
- **Trigger:** orphan count > 0, count mismatch > 0.1%, or pricing error confirmed within 2 hours
- **Action:** Hard delete all `Quote`, `QuoteLineItem`, `Asset`, `AssetStatePeriod` where `MigrationSource__c = 'CPQ'`
- **CPQ re-enable:** Re-assign SBQQ User permission sets; remove CPQ freeze flag
- **Owner:** Named architect or delivery lead — a human must execute and confirm

### Wave 2 Rollback
- **Trigger:** PricingProcedure produces incorrect output on parity test, or orphan count > 0 on any Wave 2 validation query
- **Record-migrated objects:** Hard delete `AttributeSet`, `PriceAdjustmentSchedule`, `PriceAdjustmentTier` where `MigrationSource__c = 'CPQ'`
- **Logic-rebuilt objects:** Deactivate affected `PricingProcedure` records; re-enable CPQ Price Rules as interim
- **Hard constraint:** Wave 2 rollback is only possible while CPQ is still installed — do not uninstall CPQ until all Wave 2 items are validated and signed off

---

## Evaluation Rubric (Phase Gates)

Each phase artifact is scored against this rubric (100 points):

| Category | Points | What to Check |
|---|---|---|
| Structure & Completeness | 15 | All required sections present, no placeholders |
| Safety & Security | 15 | No PII exposure, CRUD/FLS enforced, no hardcoded credentials |
| Migration Parity | 20 | CPQ behaviours accounted for in RLM design — no silent drops |
| Requirements Coverage | 20 | All items from previous phase addressed |
| Well-Architected Alignment | 10 | Config-first, declarative-before-code, least privilege |
| Bridge Strategy Integrity | 10 | Coexistence period technically sound, no data conflicts between SBQQ and RLM objects |
| Deployment Readiness | 10 | Compiles, tests pass, coverage met, rollback documented |

Score ≥ 80: PASS. Score 60–79: flag issues, architect decides. Score < 60: FAIL — must revise.
