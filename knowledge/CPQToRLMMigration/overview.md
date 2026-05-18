---
source: hand-authored — distilled from CPQToRCAMigration ADLC repo (SKILL.md v1, CLAUDE.md v1, core-memory SmartBytes engagement) April–May 2026
topic: CPQ to RLM Migration
section: overview
last-updated: 2026-05-18
---

# CPQ to Revenue Cloud (RLM) Migration — Overview

## The Fundamental Framing

CPQ to RLM is a **re-platforming engagement, not an upgrade**. The source (`SBQQ__` managed package) and the target (RLM — native Salesforce platform objects) have fundamentally different data models, pricing engines, and configuration paradigms. A lift-and-shift migration will fail. Every engagement must account for re-architecture, not just data movement.

> **Naming note:** "Revenue Cloud Advanced (RCA)", "Revenue Lifecycle Management (RLM)", and "Agentforce Revenue Management (ARM)" all refer to the same product — the native-platform Revenue Cloud. This document uses RLM throughout.

---

## Why Migrations Are Happening Now

### CPQ End of Sale
Salesforce CPQ officially entered **End of Sale in March 2025**. Estimated End of Support: **2029–2030**. Every CPQ-to-RLM engagement operates under this outer boundary. Customers who are in multi-year renewal cycles must plan their bridge period to end before support terminates.

### What CPQ Cannot Do (That RLM Can)
| Limitation | CPQ (SBQQ) | RLM |
|---|---|---|
| Product catalog model | SKU-per-variation — proliferates to thousands of products | Attributes-based — one product, many configurations |
| Pricing engine control | Black box — fixed calculation sequence | Configurable PricingProcedure — full sequencing control |
| API access | Limited — cannot freely modify quote state | API-first — full invocable actions, Agentforce-native |
| Order orchestration | Stops at Order creation | Dynamic Revenue Orchestrator (DRO) built in |
| DevOps | Managed package constraints | Any Salesforce-compatible CI/CD toolchain |
| Billing | Separate `blng__` package | Revenue Cloud Billing built in (Advanced tier) |
| Agentforce | Very limited API surface | Full agentic automation end-to-end |
| Active investment | Feature-frozen | All new Salesforce revenue capability |

---

## No Automated Migration Tool Exists

Salesforce does not provide a point-and-click migration wizard. Migration requires:
1. **Discovery** — Inventory and complexity assessment of the CPQ org
2. **Design** — Re-architecture of pricing logic, product catalog, and integrations for RLM
3. **Implementation** — Manual re-implementation of pricing logic, configuration rules, and integrations
4. **Testing** — Parity validation comparing CPQ output to RLM output on identical inputs
5. **Deployment** — Phased cutover with rollback plan

**Accelerator tools available:**
- **Gearset** — Readiness check, stepwise auto-migration, record-level traceability
- **MCDM (Multi-Cloud Data Migration)** — Salesforce-provided tool for PCM and data migration
- **Copado** — Best-in-class for RLM metadata deployment
- **Prodly** — Used for PCM data (Product2, PSM, attribute sets)

---

## The Four Migration Approaches

| Approach | Description | Best Fit |
|---|---|---|
| Refactoring Migration + Flash Cut Off | Maintain CPQ during migration; cut over to RLM at go-live. Implement in new sandbox of current org. | CPQ still meeting needs; clean cutover preferred |
| Phased Deployment | Deploy new RLM functionality (e.g., CLM) alongside CPQ. Faster time-to-value for specific capabilities. | Planning 18+ months out; need incremental value |
| Start with New Product / Channel / BU | Deploy RLM to new geography, product line, or channel while keeping CPQ live. Phased roll-off. | New GTM motion needed quickly |
| New Salesforce Org | Start fresh. Salesforce and RLM deployed in phases. | Org consolidation needed; technical debt too costly to unwind |

For all approaches: **never run CPQ and RLM in full parallel in the same org as a stable long-term state** — this is not supported.

---

## The Bridge Period Strategy

During the bridge period, CPQ and RLM coexist in the same org. This is a **production architecture that must be explicitly designed**, not a transitional afterthought.

- **New quotes and contracts** are created in RLM from Day 1 of go-live
- **Existing active contracts remain in CPQ** until renewal — at which point they migrate to RLM
- **Bridge period length** is driven by the **longest active subscription term** in the customer's org
- CPQ managed package **must NOT be uninstalled** until all active subscriptions have renewed into RLM — this is a hard constraint

### What Must Coexist During Bridge
- `SBQQ__Quote__c` (CPQ) and RLM `Quote` (standard, enhanced) both active
- `SBQQ__Subscription__c` (CPQ) and RLM `Asset` / `AssetStatePeriod` both active
- `Order` and `Contract` standard objects extended by both CPQ and RLM simultaneously — segregation by Record Type required

---

## The Five Migration Blocker Categories

Every engagement must assess these five categories — they determine timeline and risk:

| Category | What It Is | Why It Blocks |
|---|---|---|
| **QCP Scripts** | JavaScript Quote Calculator Plugin (`SBQQ__CustomScript__c`) | Does not run in RLM; must be fully rebuilt as PricingProcedure steps, Apex, or Flow |
| **Price Rules** | `SBQQ__PriceRule__c` configuration | Does not migrate; must be rebuilt as RLM PricingProcedures / PricingSteps |
| **Twin Fields** | Field-level sync between Quote Line, Order Item, Asset, Subscription | Twin field sync mechanism does not exist in RLM; replace with ContextDefinition / ContextMapping |
| **MDQ** | Multi-Dimensional Quoting — time-segmented quote lines | Requires full re-architecture using ProductSellingModel and AssetStatePeriod |
| **Integrations** | Any system reading `SBQQ__` objects or calling CPQ REST APIs | Must be re-pointed to RLM objects and APIs; CPQ REST API does not exist in RLM |

---

## What Must Be Re-Implemented (Not Migrated)

The following cannot be bulk-loaded from CPQ to RLM — they must be rebuilt:
- Quote Calculator Plugins (QCP) — full rebuild as PricingProcedure steps
- All CPQ Price Rules — rebuild as PricingSteps
- Summary Variables — rebuild as aggregation PricingSteps (no direct RLM equivalent)
- Product catalog — re-model as attributes-based (not SKU-per-variation)
- CPQ Quote Templates — rebuild in OmniStudio Document Generation
- All custom Apex classes and triggers referencing `SBQQ__` objects
- Flows on CPQ objects
- Configuration Rules → rebuild in CML (Constraint Modelling Language)
- MDQ Dimensions → rebuild as ProductSellingModel + AssetStatePeriod

---

## Delivery Sizing (from Real Implementations)

- **Timeline:** 10–18+ months for full CPQ-to-RLM migration
- **Budget:** $2.5M–$5M+ for a full engagement
- **Approach:** Lead with a **Define & Design phase** before committing full build scope
- **MVP first:** Tightly scoped first release with core quoting; complexity in later releases
- **Team requirement:** ARM requires specialized skills — generalists will struggle; functional domain leadership is equally critical as technical
