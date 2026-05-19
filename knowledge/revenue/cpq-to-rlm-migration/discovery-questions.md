---
source: hand-authored — distilled from CPQToRCAMigration ADLC repo (discovery/SKILL.md v1, design/SKILL.md v1, SmartBytes core-memory, discovery-evaluation.json) April–May 2026
topic: CPQ to RLM Migration
section: discovery-questions
last-updated: 2026-05-18
---

# CPQ to RLM Migration — Discovery Questions and Inventory Guide

## Purpose

This file is the field guide for Discovery on any CPQ-to-RLM engagement. Use it to:
1. Know which SOQL queries to run
2. Know what counts mean (scoring thresholds, complexity signals)
3. Know which open questions must be answered before Design can begin

---

## Complexity Scoring — Migration Blocker Scorecard

Run this scorecard after completing the inventory. Each category scores LOW (0) / MEDIUM (1) / HIGH (2) / CRITICAL (3).

| Category | LOW | MEDIUM | HIGH | CRITICAL |
|---|---|---|---|---|
| QCP Scripts | 0 scripts | 1–3 scripts | 4+ scripts | Any script > 200 lines |
| Active Price Rules | < 10 | 10–30 | 31–60 | > 60 |
| Summary Variables | 0 | 1–5 | 6–15 | > 15 |
| MDQ Usage | Not used | 1–5 products | 6–20 products | > 20 products |
| Twin Fields | 0 pairs | 1–5 pairs | 6–15 pairs | > 15 pairs |
| Product Rules | < 5 | 5–20 | 21–50 | > 50 |
| Open Quotes | 0 | 1–50 | 51–200 | > 200 |
| Active Subscriptions | < 500 | 500–2,000 | 2,001–10,000 | > 10,000 |
| Custom Apex on CPQ | 0 classes | 1–5 | 6–15 | > 15 |
| Integrations | 0 | 1–2 | 3–5 | > 5 |
| Advanced Approvals | Not installed | Installed, < 50 records | > 50 records | — |
| BLNG in scope | Not installed | Installed, < 1,000 invoices | > 1,000 invoices | — |
| Quote Templates | 0 | 1–2 | 3–5 | > 5 or complex conditional sections |
| Discount Schedules | 0 | 1–10 | 11–30 | > 30 |
| Contracted Prices | 0 | 1–500 | 501–5,000 | > 5,000 |

**Total score and migration complexity band:**
- 0–6: **MODERATE** — phased migration feasible within standard timeline
- 7–15: **COMPLEX** — expect extended Design and re-architecture work, 6–12 month bridge
- 16–24: **HIGHLY COMPLEX** — recommend Discovery 2 sprint before full commitment
- 25+: **CRITICAL COMPLEXITY** — must escalate to solution architect review before proceeding to Design

---

## Step-by-Step Discovery Inventory

### 1. CPQ Package Baseline

```sql
SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix,
       SubscriberPackageVersion.MajorVersion, SubscriberPackageVersion.MinorVersion
FROM InstalledSubscriberPackage
WHERE SubscriberPackage.NamespacePrefix IN ('SBQQ', 'blng', 'sbaa')
ORDER BY SubscriberPackage.Name
```

Flag any CPQ version below 228.x (Summer '19) as upgrade risk. Also check for third-party packages hooking into SBQQ objects.

### 2. Data Volumes — Quotes and Subscriptions

```sql
SELECT SBQQ__Status__c, SBQQ__Type__c, COUNT(Id) cnt
FROM SBQQ__Quote__c
GROUP BY SBQQ__Status__c, SBQQ__Type__c
ORDER BY SBQQ__Status__c
```

```sql
SELECT SBQQ__Status__c, COUNT(Id) cnt
FROM SBQQ__Subscription__c
GROUP BY SBQQ__Status__c
```

Active subscriptions with latest end date (determines bridge period length):
```sql
SELECT Id, SBQQ__SubscriptionEndDate__c, SBQQ__Product__c
FROM SBQQ__Subscription__c
WHERE SBQQ__Status__c = 'Active'
ORDER BY SBQQ__SubscriptionEndDate__c ASC
LIMIT 500
```

> **Bridge period = latest active subscription end date.** Record this — it is the single most important date in the entire migration.

### 3. Product Catalog

```sql
SELECT IsActive, COUNT(Id) cnt FROM Product2 GROUP BY IsActive
```

Bundle structure (density drives re-modelling effort):
```sql
SELECT SBQQ__ConfiguredSKU__c, COUNT(Id) OptionCount
FROM SBQQ__ProductOption__c
GROUP BY SBQQ__ConfiguredSKU__c
ORDER BY COUNT(Id) DESC
LIMIT 100
```

```sql
SELECT COUNT() FROM SBQQ__ProductOption__c
```

MDQ (HIGH complexity signal — any result here = MDQ is in use):
```sql
SELECT Id, Name, SBQQ__Type__c, SBQQ__Product__c FROM SBQQ__Dimension__c
ORDER BY SBQQ__Product__c
```

### 4. QCP Scripts — CRITICAL

```sql
SELECT Id, Name, SBQQ__Code__c, SBQQ__API__c,
       SBQQ__QuoteLineFields__c, SBQQ__QuoteFields__c
FROM SBQQ__CustomScript__c
```

For each script found:
- Record all lifecycle hooks implemented: `onInit`, `onBeforeCalculate`, `onBeforePriceRules`, `onAfterPriceRules`, `onAfterCalculate`, `onAfterGroupCalculate`
- Count lines per function — < 50 = LOW, 50–200 = MEDIUM, > 200 = HIGH/CRITICAL
- QCP JavaScript does not run in RLM — every function must be rebuilt

### 5. Price Rules

```sql
SELECT Id, Name, SBQQ__Active__c, SBQQ__EvaluationEvent__c,
       SBQQ__EvaluationOrder__c, SBQQ__ConditionsMet__c
FROM SBQQ__PriceRule__c
WHERE SBQQ__Active__c = true
ORDER BY SBQQ__EvaluationOrder__c
```

```sql
SELECT SBQQ__Rule__r.Name, SBQQ__TargetObject__c, SBQQ__TargetField__c,
       SBQQ__Type__c, SBQQ__Value__c
FROM SBQQ__PriceAction__c
WHERE SBQQ__Rule__r.SBQQ__Active__c = true
LIMIT 500
```

```sql
SELECT Id, Name, SBQQ__Type__c, SBQQ__SourceObject__c, SBQQ__SourceField__c
FROM SBQQ__SummaryVariable__c
```

> **Summary Variables have NO direct RLM equivalent.** Every one must be rebuilt as an aggregation PricingStep (typically Apex-invoked). Flag > 15 as CRITICAL.

### 6. Configuration Rules and Product Rules

```sql
SELECT SBQQ__Type__c, COUNT(Id) cnt
FROM SBQQ__ProductRule__c
WHERE SBQQ__Active__c = true
GROUP BY SBQQ__Type__c
```

```sql
SELECT COUNT() FROM SBQQ__ConfigurationRule__c WHERE SBQQ__Active__c = true
```

```sql
SELECT Id, SBQQ__ConstrainedOption__c, SBQQ__ConstrainingOption__c,
       SBQQ__Type__c
FROM SBQQ__OptionConstraint__c
LIMIT 200
```

### 7. Custom Code

Retrieve all Apex classes and look for:
- References to `SBQQ` in type declarations or DML
- Calls to `SBQQ.ServiceRouter` (CPQ API — does not exist in RLM)
- Implements `SBQQ.CartCalculate` or `SBQQ.QuoteCalculator`
- Creates/updates `SBQQ__Quote__c`, `SBQQ__QuoteLine__c`, `SBQQ__Subscription__c`

Also retrieve all triggers — identify any trigger on SBQQ objects or on standard objects (Order, Contract) that reads SBQQ fields.

### 8. Twin Field Analysis

Query custom fields on each of these objects and compare API names across all four:

```sql
SELECT QualifiedApiName, DataType FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'SBQQ__QuoteLine__c'
  AND QualifiedApiName LIKE '%__c'
ORDER BY QualifiedApiName
```

Repeat for: `OrderItem`, `Asset`, `SBQQ__Subscription__c`.

Any field that appears on two or more objects with the same API name is a **twin field**. Each pair must be replaced with ContextDefinition/ContextMapping in RLM.

### 9. Integrations

Ask the customer directly (SOQL cannot detect all of these):
- **ERP integration** reading Order/Contract records created from CPQ (reads `SBQQ__`-extended fields on Order)
- **E-signature** (DocuSign, Conga) calling `SBQQ__QuoteTemplate__c`
- **CPQ Pricing API callouts** — any external system calling `/services/apexrest/SBQQ/v1/`
- **Tax integration** (Avalara, Vertex) via CPQ native tax hook
- **B2B Commerce** integration via CPQSM/SM connector

```sql
SELECT Name, Description FROM ConnectedApplication ORDER BY Name
```

### 10. Salesforce Billing (BLNG) — Run Only If In Scope

```sql
SELECT blng__Status__c, COUNT(Id) cnt
FROM blng__Invoice__c
GROUP BY blng__Status__c
```

> **SOQL access restriction:** BLNG objects (`blng__*`) frequently return "sObject type not supported" via standard REST API on demo/sandbox orgs. Use Tooling API or request a data export from the customer's production org if this occurs.

```sql
SELECT Id, blng__Status__c, blng__NextBillingDate__c
FROM blng__BillingSchedule__c
WHERE blng__Status__c IN ('Active', 'Pending')
ORDER BY blng__NextBillingDate__c ASC
LIMIT 500
```

### 11. CPQSM / Brownfield RCA Check

If the CPQSM connector is installed (look for `SM_CartItemBefore` or `SM_RevenueAsyncOperation` triggers), there may already be partial RLM configuration in the org. Query existing RLM objects:

```sql
SELECT Id, Name FROM ProductCatalog ORDER BY Name
```
```sql
SELECT Id, Name, Type FROM ProductSellingModel ORDER BY Name
```
```sql
SELECT Id, Name FROM PricingProcedure ORDER BY Name
```

**If any of these return records:** the Design phase must reconcile existing RLM config before building new. This is a blocking finding.

### 12. Security Baseline

```sql
SELECT QualifiedApiName, ExternalSharingModel, InternalSharingModel
FROM EntityDefinition
WHERE QualifiedApiName IN ('SBQQ__Quote__c', 'SBQQ__QuoteLine__c',
                            'SBQQ__Subscription__c', 'Order', 'Contract',
                            'Opportunity', 'Product2', 'Asset')
ORDER BY QualifiedApiName
```

Flag any object at OWD = Public Read/Write as HIGH RISK. In the SmartBytes engagement, 6 objects were at ReadWrite — this is a known security debt that must be remediated during migration.

---

## Open Questions That Must Be Resolved Before Design

These questions cannot be answered from org data alone. Get human answers before Design begins:

**Bridge Period**
- What is the latest active subscription end date in production? (the demo/sandbox org may have zero subscriptions — always get production data)
- Who owns CPQ amendments during the bridge period — CPQ team or RLM team?
- What is the customer's appetite for product catalogue rationalisation before migration?

**Data Migration Scope**
- Which Quote statuses are in scope for Wave 1 migration? (Draft+Approved only, or include Ordered+Contracted?)
- Are cancelled/expired Subscriptions required in RLM or active only?
- What is the maximum acceptable freeze window for cutover?
- Is multi-currency active? (Multiplies PricebookEntry volume per product)

**Pricing Architecture**
- For Contracted Prices — Option A (PricebookEntry override), B (Decision Table), or C (custom object + Apex)?
- Are inactive Price Rules in scope for Wave 2 rebuild or active rules only?
- QCP bug confirmation: any assignment operator (=) instead of comparison (==) in QCP code must be confirmed with customer before PricingProcedure spec is written

**Integrations**
- Have integration system owners confirmed re-architecture timelines?
- Which integrations must be live on Day 1 vs. can lag go-live?
- Has the tax integration provider confirmed RLM support?

**BLNG (if in scope)**
- Production invoice, billing schedule, and usage volumes (if SOQL access is blocked)
- Are revenue recognition rules (ASC 606 / IFRS 15) active? If yes, must RLM Billing match on Day 1?
- What is the cutover freeze strategy for Draft invoices?

**Brownfield**
- If CPQSM has partially configured RLM — what is the prior migration scope, and which existing RLM objects should be reused vs. rearchitected?

---

## Common SOQL Failures in CPQ Orgs

These fail silently or with unhelpful errors. Apply workarounds from the start:

| Query Target | Failure | Workaround |
|---|---|---|
| `blng__*` sObjects | "sObject type not supported" via standard REST API | Use Tooling API or customer data export |
| `SBQQ__ConfiguratorSettings__c` | Not accessible via standard SOQL | Use `retrieve_metadata` instead |
| `ProcessDefinition` | `SobjectType` filter fails | Use `TableEnumOrId` field |
| `FieldDefinition` | `IsCustom` field does not exist | Use `WHERE QualifiedApiName LIKE '%__c'` |
| `ConnectedApplication` | `ContactEmail` field does not exist | Query `Name` only |
| `sbaa__ApprovalChain__c` | No `SBQQ__Type__c` field | Query `Name` only; infer domain from name |
| `SBQQ__Cost__c` | Field names vary — query fails | Query `Name`/`Id` first, then describe for field names |
