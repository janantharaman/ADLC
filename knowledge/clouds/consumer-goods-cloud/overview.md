---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: overview
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Overview

## What It Is

Consumer Goods Cloud (CGC) is Salesforce's industry cloud for consumer goods manufacturers and distributors. It enables field teams, trade promotion managers, and route delivery drivers to manage retail execution, promotional spending, and direct store delivery from a single platform. CGC ships as a managed package under the `cgcloud` namespace installed on top of Enterprise or Unlimited orgs.

**Official Guide:** Consumer Goods Cloud Developer Guide, Spring '26 (1840 pages)

---

## Product Modules

### Retail Execution (RE)
Plan store visits for field representatives, track inventory, capture signatures, take orders, and analyze business health across retail stores. Includes:
- **Sync Management** — keeps data in sync between Salesforce org and offline mobile devices (`cgc_sync` namespace)
- **Direct Store Delivery (DSD)** — create routes and tours for delivery drivers (`cgcloud` namespace objects)
- **Einstein Visit and Activity Recommendation** — AI-driven visit and task recommendations

### Trade Promotion Management (TPM)
Plan, execute, and track promotional activities across retailers from planning to settlement. Includes:
- Promotion lifecycle: planning → execution → payment
- KPI tracking and Real Time Reporting (RTR) export via Hyperforce
- Rate-Based Funding (RBF) and fund management
- Business Object API for external system integration

---

## Two-Namespace Architecture

| Namespace | Used For |
|---|---|
| `cgcloud` | All CGC custom objects (RE + TPM + shared) — the primary namespace |
| `cgc_sync` | Sync Management objects and custom metadata types only |

CGC adds `cgcloud__` fields directly to standard objects (Account, Asset, Product2, User, etc.) AND provides hundreds of `cgcloud__*__c` custom objects. The managed package namespace is `cgcloud` throughout — do NOT confuse with `cgc` or `cg`.

---

## Editions and Licensing

| Requirement | Detail |
|---|---|
| Base edition | Enterprise or Unlimited |
| CGC RE license | Consumer Goods Cloud (includes Retail Execution) |
| TPM license | Separate Consumer Goods Cloud Trade Promotion Management add-on |
| Mobile offline sync | Mobile Sync package (separate install; `cgc_sync` namespace) |
| Einstein recommendations | Einstein Recommendation Builder add-on |
| DSD | Included in CGC RE license |

---

## Key Capabilities by Module

### Retail Execution
- Store visit planning and execution via mobile app (Salesforce Retail Execution mobile app)
- Assessment tasks: planogram check, inventory check, promotion check, in-store survey, custom tasks (`AssessmentTask.TaskType`)
- Order entry with customizable proposal list, order header/items (`cgcloud__Order__c`)
- Signature capture (`SignatureTask`, `SignatureTaskLineItem`)
- Assortment management per store (`Assortment`, `StoreAssortment`, `AssortmentProduct`)
- KPI tracking: target vs. actual per store (`RetailStoreKpi`, `RetailVisitKpi`)
- Asset management: coolers, dispensers, POS materials (`Asset` extended with `cgcloud__` fields)

### Sync Management (`cgc_sync` namespace)
- Bidirectional data sync between Salesforce and mobile app
- Sync action types: `INITIAL_SYNC`, `REGULAR_SYNC`, `BACKGROUND_SYNC`, `ON_DEMAND_SYNC`, `FSOD`
- Full sync vs. incremental (configurable per tracked object via `cgc_sync__Sync_Tracked_Object_Config__c`)
- Deployment packages with Runtime Artifacts (RTAs) to mobile devices
- Performance tracking via `cgc_sync__Sync_API_Log__c`

### Direct Store Delivery (DSD)
- Route and tour management for delivery drivers
- Custom objects: `cgcloud__Route__c`, `cgcloud__Tour__c`, `cgcloud__Vehicle__c`, `cgcloud__Vehicle_Warehouse__c`
- Order, payment, delivery, and return processing at retail stops

### Trade Promotion Management
- Account plans per business year per category (`cgcloud__Account_Plan__c`, `cgcloud__Business_Year__c`)
- Promotion creation with tactics: price reductions, display, shipment date windows
- Fund management: budgets, allocations, rate-based funding (`cgcloud__Fund__c`, `cgcloud__RBF_Template__c`)
- Payment management at tactic-product level (`cgcloud__Payment__c`, `cgcloud__Payment_Tactic_Product__c`)
- Real Time Reporting (RTR) export from Hyperforce — CSV export per KPI set
- Business Object API for promotion import/export workflows (up to 50 promotions per call)
- MetadataWizard for custom UI wizard pages

---

## When to Use Consumer Goods Cloud

| Use Case | Fit |
|---|---|
| FMCG field sales with store visit workflows | Excellent |
| Beverage/snack manufacturer managing trade promotions | Excellent |
| CPG distributor with route-based deliveries | Excellent (DSD) |
| Retail chain managing own stores | Poor — CGC is for manufacturers, not retailers |
| Non-consumer goods industry | Poor — consider Manufacturing or Service Cloud |

---

## Integration Patterns

- **External ERP → TPM:** Business Object API REST endpoints for promotion, tactic, fund, and payment ingestion
- **Mobile → Salesforce:** Sync Management (`cgc_sync`) handles bidirectional offline data sync
- **RTR export:** Hyperforce CSV export for KPIs consumed by external BI tools
- **LWC order customization:** `cgcloud/orderExtensionUtils` service component for client-side order screen hooks
- **Server-side order hooks:** Apex `System.Callable` registered via `CGCloud Process Customization` custom metadata type

---

## Modeler (Low-Code Customization)

CGC mobile app UI can be customized via the VS Code–based Modeler tool without Apex. Modeler controls screen layouts, navigation flows, and component visibility. When Modeler isn't enough, use LWC + `cgcloud/orderExtensionUtils` or Apex callable hooks.

---

## Key API Versions

| Feature | API Version |
|---|---|
| Core RE objects (Visit, RetailStore, AssessmentTask) | v47.0 |
| DeliveryTask, OtherComponentTask, SignatureTask | v50.0 |
| VehicleUserAssignment | v51.0 |
| RetailStoreGroupAssignment | v52.0 |
| Account, Asset, Product2, User CGC field additions | v55.0 |
| TPM core objects | v54.0 |
| cgc_sync__Sync_Client_Registration__c | v61.0 |
| RE orderExtensionUtils LWC service component | v59.0 |
| RetailExecutionSettings metadata type | v47.0 (enableProductHierarchy v53.0, enableVisitSharing v55.0) |
| Current version (Spring '26) | v66.0 |
