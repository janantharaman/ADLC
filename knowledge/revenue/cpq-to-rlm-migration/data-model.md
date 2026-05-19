---
source: hand-authored — distilled from CPQToRCAMigration ADLC repo (discovery/SKILL.md v1, design/SKILL.md v1, implementation/SKILL.md v1, discovery-evaluation SmartBytes) April–May 2026
topic: CPQ to RLM Migration
section: data-model
last-updated: 2026-05-18
---

# CPQ to RLM Migration — Object Mapping and Data Model

## Core Object Mapping

Every CPQ object that needs to survive migration must be either **record-migrated** (bulk-loaded into a corresponding RLM object) or **logic-rebuilt** (CPQ configuration is analysed and re-implemented as RLM-native configuration). There is no third category.

| CPQ Object | API Name | RLM Target | Migration Type |
|---|---|---|---|
| Quote | `SBQQ__Quote__c` | `Quote` (standard, enhanced) | Record-migrate |
| Quote Line | `SBQQ__QuoteLine__c` | `QuoteLineItem` (standard, enhanced) | Record-migrate |
| Subscription | `SBQQ__Subscription__c` | `Asset` + `AssetStatePeriod` | Re-architect — not a direct migration |
| Product Option | `SBQQ__ProductOption__c` | `ProductRelatedComponent` | Record-migrate |
| Product Feature | `SBQQ__ProductFeature__c` | `ProductComponentGroup` | Record-migrate |
| Configuration Attribute | `SBQQ__ConfigurationAttribute__c` | `ProductConfigurationAttribute` | Record-migrate |
| Attribute Set | `SBQQ__AttributeSet__c` | `AttributeSet` (native) | Record-migrate |
| Product Rule | `SBQQ__ProductRule__c` | Constraint Modelling Language (CML) | Logic-rebuild |
| Configuration Rule | `SBQQ__ConfigurationRule__c` | Constraint Modelling Language (CML) | Logic-rebuild |
| Price Rule | `SBQQ__PriceRule__c` | `PricingProcedure` / `PricingStep` | Logic-rebuild |
| Price Action | `SBQQ__PriceAction__c` | `PricingStep` output assignment | Logic-rebuild (embedded) |
| Price Condition | `SBQQ__PriceCondition__c` | ContextMapping / Step condition | Logic-rebuild (embedded) |
| Summary Variable | `SBQQ__SummaryVariable__c` | PricingStep aggregation (Apex) | Logic-rebuild — no direct equivalent |
| Discount Schedule | `SBQQ__DiscountSchedule__c` | `PriceAdjustmentSchedule` | Record-migrate |
| Discount Tier | `SBQQ__DiscountTier__c` | `PriceAdjustmentTier` | Record-migrate |
| Block Price | `SBQQ__BlockPrice__c` | `PriceAdjustmentSchedule` (Block type) | Record-migrate |
| Quote Calculator Plugin | `SBQQ__CustomScript__c` | `PricingProcedure` steps / Apex / Flow | Logic-rebuild (full re-build) |
| Quote Template | `SBQQ__QuoteTemplate__c` | OmniStudio Document Generation | Logic-rebuild |
| Contracted Price | `SBQQ__ContractedPrice__c` | Account-context PricingProcedure step | Logic-rebuild / Record-migrate |
| MDQ Dimension | `SBQQ__Dimension__c` | `ProductSellingModel` + `AssetStatePeriod` | Re-architect |
| Configurator Settings | `SBQQ__ConfiguratorSettings__c` | Revenue Cloud Setup configuration | Manual re-configure |
| BLNG Invoice | `blng__Invoice__c` | `Invoice` (native) | Record-migrate (posted invoices) |
| BLNG Invoice Line | `blng__InvoiceLine__c` | `InvoiceLine` (native) | Record-migrate with parent |
| BLNG Billing Schedule | `blng__BillingSchedule__c` | `BillingSchedule` (native) | Re-create active schedules |
| BLNG Usage | `blng__Usage__c` | `UsageSummary` (native) | Migrate unprocessed records |
| BLNG Payment Method | `blng__PaymentMethod__c` | `SavedPaymentMethod` (native) | Re-create via payment APIs |
| BLNG Credit Note | `blng__CreditNote__c` | `CreditMemo` (native) | Migrate open credit memos |
| BLNG RevRec Rule | `blng__RevenueRecognitionRule__c` | Revenue Recognition Settings (Setup) | Re-configure in Setup |
| Twin Fields | (field-level pairs) | `ContextDefinition` + `ContextMapping` | Logic-rebuild — per pair |

---

## RLM Product Catalog Management (PCM) Objects — Load Dependency Order

PCM objects must be loaded in dependency order. Objects at the same level can be loaded in parallel.

### Level 1 — No dependencies (load first, in parallel)
- `AttributePicklist` ← `SBQQ__AttributeSet__c` (strategy: Apex → Temp Object → MCDM/Prodly)
- `AttributeCategory` ← `SBQQ__ConfigurationAttribute__c` Global type (strategy: Src Object → MCDM)
- `ProductCatalog` ← Customer-provided CSV (strategy: CSV → MCDM)
- `ProductClassification` ← Customer-provided CSV (strategy: CSV → MCDM)
- `ProductRelationshipType` ← Auto-created — no migration action required
- `ProductSellingModel` ← Derived from `SBQQ__SubscriptionPricing__c` (strategy: CSV → MCDM)
- `ProductSpecificationType` ← Customer-provided (strategy: CSV → MCDM)
- `ProratePolicy` ← Customer-provided (strategy: CSV → MCDM)
- `Pricebook2` ← `Pricebook2` (strategy: Src Object → MCDM)
- `Product2` — base fields only, RLM lookups added in Level 2

### Level 2 — Depends on Level 1
- `AttributePicklistValue` ← `SBQQ__AttributeValue__c` (depends on: AttributePicklist)
- `Product2` — update with `ProductClassificationId` (depends on: ProductClassification)
- `ProductCategory` ← CSV — two-pass: root categories first, then children (depends on: ProductCatalog; self-lookup)
- `PricebookEntry` ← `PricebookEntry` (depends on: Pricebook2, Product2)

### Level 3 — Depends on Level 2
- `AttributeDefinition` ← `SBQQ__ConfigurationAttribute__c` (depends on: AttributePicklist, AttributePicklistValue)
- `ProductComponentGroup` ← `SBQQ__ProductFeature__c` (depends on: Product2)
- `ProductSellingModelOption` ← Derived (depends on: Product2, ProductSellingModel, ProratePolicy)
- `ProductRampSegment` ← `SBQQ__Dimension__c` (depends on: ProductSellingModel, Product2)

### Level 4 — Depends on Level 3
- `ProductRelatedComponent` ← `SBQQ__ProductOption__c` (depends on: Product2 × 2, ProductComponentGroup, ProductRelationshipType)
- `ProductClassificationAttr` ← Customer manual (depends on: ProductClassification, AttributeCategory, AttributeDefinition)
- `AttributeCategoryAttribute` ← Auto-created — no migration action required

### Level 5 — Depends on Level 4
- `ProductRelComponentOverride` ← Customer manual
- `AttrPicklistExcludedValue` ← Customer manual

### Auto-created (no migration action)
- `ProductAttributeDefinition` — auto-created by Salesforce when ProductClassificationAttribute is updated. Never load directly.

---

## Migration Strategy Patterns

| Pattern | When to Use | Examples |
|---|---|---|
| `Src Obj → MCDM → Target` | CPQ object has a direct RLM equivalent and field mapping is straightforward | Product2, ProductComponentGroup, ProductRelatedComponent, ProductSellingModelOption |
| `CSV → MCDM → Target` | RLM object has no CPQ source equivalent — customer-provided or derived | ProductCatalog, ProductClassification, ProductCategory, ProductSellingModel, ProratePolicy |
| `Apex → Temp Obj → MCDM → Target` | CPQ data requires transformation too complex for declarative mapping | AttributePicklist, AttributePicklistValue, AttributeDefinition |
| `Customer manually associates` | Business-specific association that cannot be derived from CPQ metadata | ProductCategoryProduct, ProductClassificationAttribute, overrides |
| `Auto Created in Target` | RLM creates records automatically as a side effect of other configuration | ProductRelationshipType, ProductAttributeDefinition |

**Critical constraint:** For `CSV → MCDM → Target` objects — no changes to CPQ product data should be made after the migration extract begins. Enforce a **product data freeze** at the start of the migration sprint.

---

## Product Classification Pre-Work

Before migration, the customer must identify product segregation dimensions. Three custom fields on `Product2` are used as input signals:
- `rca_catalog` → maps to `ProductCatalog` (e.g., `ABC_Hardware`, `ABC_Software`)
- `rca_category` → maps to `ProductCategory` (comma-separated for multiple)
- `rca_classification` → maps to `ProductClassification` (e.g., `ABC_HandHeld`)

The customer must either manually populate these fields or configure a Custom Setting mapping that an Apex batch reads to drive the catalog/category/classification load. Confirm approach early — it blocks all Level 1 PCM work.

---

## Wave 1 and Wave 2 Scope

### Wave 1 — Day 1 Go-Live (product catalog + active transactional data)
- Product2 (additive RLM field population)
- PricebookEntry (new RLM pricebook entries)
- ProductComponentGroup (`SBQQ__ProductFeature__c`)
- ProductRelatedComponent (`SBQQ__ProductOption__c`)
- Quote (`SBQQ__Quote__c` — in-scope status filter only)
- QuoteLineItem (`SBQQ__QuoteLine__c`)
- Asset + AssetStatePeriod (`SBQQ__Subscription__c` Active — one Asset per subscription, one ASP per subscription or MDQ segment)

### Wave 2 — Post-Bridge (pricing config + logic rebuild)
- AttributeSet, ProductAttribute (record-migrate)
- PriceAdjustmentSchedule + PriceAdjustmentTier (record-migrate)
- Block Prices (record-migrate)
- Contracted Prices (logic-rebuild: option A/B/C — Design decision required)
- Summary Variables → PricingStep Apex (logic-rebuild)
- Price Rules + PriceActions + PriceConditions → PricingProcedure/PricingStep (logic-rebuild)
- QCP Scripts → PricingProcedure steps / Apex / Flow (logic-rebuild — highest complexity)
- Product Rules + Configuration Rules + Option Constraints → CML (logic-rebuild)
- MDQ Dimensions → ProductSellingModel + AssetStatePeriod (logic-rebuild + second-pass record-migrate)
- Quote Templates → OmniStudio Document Generation (human-built; agent produces spec only)

### Tooling Decision Thresholds
| Volume | Tooling |
|---|---|
| < 10,000 records | Apex Batch — agent-deployable with user approval |
| 10,000–100,000 records | Bulk API via Data Loader — agent produces CSV spec; human executes |
| > 100,000 records | External ETL (MuleSoft, Informatica) — agent produces source SOQL + field mapping; ETL team executes |

---

## Cross-Reference Fields — Mandatory for All Migrations

These fields must be created on RLM target objects **before any data is loaded**. They enable bridge-period cross-referencing, delta loads, and rollback.

| Field API Name | Object | Type | Purpose |
|---|---|---|---|
| `MigrationSource__c` | Quote, QuoteLineItem, Asset, AssetStatePeriod | Picklist (CPQ, RLM) | Record origin tracking |
| `CPQQuoteId__c` | Quote | Text(18) | Cross-reference to `SBQQ__Quote__c.Id` |
| `CPQQuoteLineId__c` | QuoteLineItem | Text(18) | Cross-reference to `SBQQ__QuoteLine__c.Id` |
| `CPQSubscriptionId__c` | Asset | Text(18) | Cross-reference to `SBQQ__Subscription__c.Id` |
| `CPQAttributeSetId__c` | AttributeSet | Text(18) | Cross-reference to `SBQQ__AttributeSet__c.Id` |
| `CPQDiscountScheduleId__c` | PriceAdjustmentSchedule | Text(18) | Cross-reference to `SBQQ__DiscountSchedule__c.Id` |
| `CPQBlockPriceId__c` | PriceAdjustmentSchedule | Text(18) | Cross-reference to `SBQQ__BlockPrice__c.Id` |

`CPQ*Id__c` fields serve as external IDs for delta loads during the freeze window. `MigrationSource__c` is the rollback key — used to bulk-delete all migrated records if Wave 1 must be reversed.

---

## Key Field Mappings

### Product2 (additive update — existing records updated)

| Action | Field | Source / Derivation |
|---|---|---|
| Populate | `ProductClass` | `'Set'` if has ProductOption children; `'Component'` if appears as ProductOption child; else `'Simple'` |
| Populate | `ProductSellingModel` lookup | `SBQQ__SubscriptionPricing__c = 'Fixed Price'` → TermOptimized; `'Usage Based'` → UsageBased; null → One-Time |

### Quote (SBQQ__Quote__c → RLM Quote)

| Source Field | Target Field | Notes |
|---|---|---|
| `Name` | `Name` | Prefix with `MIGRATED-` |
| `SBQQ__Account__c` | `AccountId` | Direct |
| `SBQQ__Opportunity2__c` | `OpportunityId` | Direct |
| `SBQQ__Status__c` | `Status` | Value map: Draft→Draft, Approved→Approved, Ordered→Ordered, etc. |
| `SBQQ__NetAmount__c` | `TotalAmount` | Direct |
| `SBQQ__GrandTotal__c` | `GrandTotalAmount` | Direct |
| `Id` | `CPQQuoteId__c` | Cross-reference — external ID for delta upserts |

### Subscription (SBQQ__Subscription__c → Asset + AssetStatePeriod)

One active Subscription = one Asset + one AssetStatePeriod (multiple ASP for MDQ).

| Source | Asset Target | Notes |
|---|---|---|
| `SBQQ__Account__c` | `AccountId` | Direct |
| `SBQQ__Product__c` | `Product2Id` | Direct |
| `SBQQ__Quantity__c` | `Quantity` | Direct |
| `SBQQ__SubscriptionEndDate__c` | `UsageEndDate` | Direct |
| `SBQQ__NetPrice__c` | `Price` | Direct |
| `Id` | `CPQSubscriptionId__c` | Cross-reference |
| — | `Status` | `'Purchased'` |
| — | `MigrationSource__c` | `'CPQ'` |

| Source | AssetStatePeriod Target | Notes |
|---|---|---|
| `SBQQ__StartDate__c` | `StartDate` | Direct |
| `SBQQ__SubscriptionEndDate__c` | `EndDate` | Direct |
| `SBQQ__Quantity__c` | `Quantity` | Direct |
| `SBQQ__NetPrice__c` | `MRR` | Monthly: direct; annual: divide by 12 |
| — | `State` | `'Active'` |
