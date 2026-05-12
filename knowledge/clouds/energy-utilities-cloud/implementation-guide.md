---
source: E&U Developer Guide (Summer '26); Vlocity Build GitHub; EPC Guide; ASLM Guide; CLM Guide; salesforceben.com E&U Guide; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: implementation-guide
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Implementation Guide

## Prerequisites

| Prerequisite | Verification |
|---|---|
| E&U Cloud license provisioned | Setup > Company Information > Licenses — confirm Energy and Utilities Cloud |
| OmniStudio installed / enabled | Setup > Installed Packages — confirm `vlocity_cmt` namespace OR OmniStudio GA enabled |
| Field Service enabled (if ASLM in scope) | Setup > Field Service Settings |
| Experience Cloud site (if self-serve portal in scope) | Setup > Digital Experiences > All Sites |
| Named Credentials configured for external systems | Setup > Named Credentials |
| Multi-currency enabled (if multi-currency required) | Setup > Company Information |
| API version 67.0 (Summer '26) for all new deployments | sfdx-project.json `sourceApiVersion: 67.0` |
| IDX Workbench / `vlocity` npm CLI | `npm install --global vlocity`; Node.js 18+ required |

---

## Phase 1: Org Setup and Package Configuration

### Step 1 — Install the Managed Package

1. Install `vlocity_cmt` managed package from AppExchange (or via Salesforce delivery team)
2. Confirm installation: Setup > Installed Packages > confirm "Salesforce Industries CME"
3. Verify namespace `vlocity_cmt` is active

**If using OmniStudio GA (Spring '22+ new orgs):**
- OmniStudio unmanaged objects (`OmniProcess`, `OmniUiCard`, `OmniDataTransform`) are available natively
- No separate OmniStudio package installation needed
- Legacy `vlocity_cmt__OmniScript__c` objects are deprecated — use `OmniProcess`

### Step 2 — Assign Permission Set Licenses

For Spring '22+ customers, assign PSLs per module to relevant users:

```
Setup > Permission Sets > [Module PSL] > Manage Assignments
```

Required minimum assignments:
- **CPQ PSL** → sales reps, contact center agents
- **EPC PSL** → product admins, catalog managers
- **OM PSL** → order operations, fulfillment team
- **DocGen PSL** → anyone generating contracts or documents

### Step 3 — Configure Custom Settings

Key custom settings to configure post-installation:

| Custom Setting | Key Field | Value |
|---|---|---|
| Vlocity CMT Settings | `DefaultPricingPlan__c` | API name of the default pricing plan |
| Vlocity CMT Settings | `DefaultPriceList__c` | API name of the default price list |
| Document Generation Settings | `ServerSideDocGenEnabled__c` | true (for server-side generation) |

---

## Phase 2: Enterprise Product Catalog Setup

### Step 4 — Build the Product Hierarchy

1. Create `AttributeCategory__c` records (group related attributes)
2. Create `Attribute__c` records (individual product/service attributes)
3. Create `Catalog__c` records (product catalog containers — e.g., "Residential Catalog", "C&I Catalog")
4. Create `Product2` records for product specifications
5. Create `ProductChildItem__c` records for bundle definitions
6. Create `ProductRelationship__c` records (requires/excludes/recommends rules)
7. Assign attributes to products via `AttributeAssignment__c`
8. Create `PriceList__c` hierarchy (base price list → segment-specific child price lists)
9. Create `PriceListEntry__c` records (product prices per price list)
10. Link products to catalogs via `CatalogProductRelationship__c`

**Use Product Designer (LWC-based)** for all new EPC work — not the legacy Product Console.

### Step 5 — Configure Pricing Plans

1. Create `PricingPlan__c` record (the overall pricing strategy)
2. Create `PricingPlanStep__c` records defining the pricing execution sequence
3. Create `CalculationMatrix__c` records for matrix-based pricing rules
4. Populate `CalculationMatrixRow__c` records (≥2,000 rows for bulk optimization)
5. Set `DefaultPricingPlan__c` custom setting to the active pricing plan

---

## Phase 3: Customer Interaction and CPQ Setup

### Step 6 — Build OmniScripts for Key Flows

Build as LWC-enabled OmniScripts (set `IsLwcEnabled: true`):

| Flow | OmniScript Type/SubType |
|---|---|
| New customer acquisition / quoting | `Quote / NewService` |
| Service modification (add/change/remove) | `Order / ModifyService` |
| Program enrollment | `Enrollment / EnergyProgram` |
| Service request / outage reporting | `ServiceRequest / Outage` |
| Account self-service | `Account / SelfService` |

### Step 7 — Build FlexCards for Customer 360

1. **Account 360 Card** — summary of account, billing accounts, service agreements
2. **Service Point Card** — active service points and meters per premises
3. **Billing Summary Card** — current balance, recent statements
4. **Active Programs Card** — enrolled programs and benefit disbursements
5. **Open Cases Card** — service requests and cases in progress

Activate each FlexCard to generate LWC components before embedding in Lightning pages.

### Step 8 — Configure Integration Procedures for CIS Integration

1. Create IP: `GetBillingInfo` — calls CIS via HTTP Action (Named Credential) → populates `Interface_BillingInfo__c` → DataRaptor Load to `Statement__c` + `AccountBalance__c`
2. Create IP: `GetUsageHistory` — pulls meter reads from AMI system → transforms to UsageImpactFactor records
3. Create IP: `PostPayment` — receives payment from payment gateway → creates `OrderPayment__c` → calls CIS payment API

---

## Phase 4: Energy Programs Setup

### Step 9 — Configure Programs

1. Create `Program` records (energy efficiency, LIHEAP, rebate programs, etc.)
2. Create `ProgramProduct` records (products/incentives associated with the program)
3. Create `ProgramApplnFormTemplate` records (defines the application form structure)
4. Create `ApplicationFormTemplate` records for form rendering in OmniScript
5. Configure `UsageImpactGroup__c` → `UsageImpactFactor__c` chains for efficiency measurement
6. Build enrollment OmniScript using `ApplicationFormTemplate` as data source

### Step 10 — Configure Benefit Disbursement

1. Create `BenefitType` records (rebate, bill credit, equipment, etc.)
2. Create `BenefitSchedule` records (monthly, quarterly, one-time)
3. Configure disbursement flows triggered on `ProgramEnrollment` status change
4. Set up `BudgetCategory` + `BudgetPeriod` for program budget tracking

---

## Phase 5: Order Management Setup

### Step 11 — Configure Orchestration

1. Create `OrchestrationItemDefinition__c` records (one per fulfillment task type)
2. Create `OrchestrationPlanDefinition__c` records (templates per scenario)
3. Create `OrchestrationDependencyDefinition__c` records (execution order/dependencies)
4. Create `OrchestrationScenario__c` records (map action+product → plan definition)
5. Create `DecompositionRelationship__c` records (commercial → technical product mapping)
6. For custom Apex tasks: create `ItemImplementation__c` records referencing your Apex classes (must implement `VlocityOpenInterface`)
7. For manual tasks: create `ManualQueue__c` records + `ManualQueueAssignmentRule__c`

### Step 12 — Configure Platform Events

Subscribe to platform events for order processing:
- `vlocity_cmt__OrderAsyncOperationEvent__e` — for async order status updates
- `vlocity_cmt__OrderUpdate__e` — for OM+ status changes

Use standard Flow or Apex trigger on the platform event to drive downstream processing.

---

## Phase 6: Asset Service Lifecycle Setup (if in scope)

### Step 13 — Configure ASLM Features

| Feature | Setup Required |
|---|---|
| Advanced Exchange | `Service Part Return Management` PSL assigned to FSL users; configure Return Order automation |
| Asset Coverage View | `FieldServiceEntitlementsView` license assigned; configure Entitlement templates |
| Asset Interactive Hierarchy | `FieldServiceAssetHierarchyAddOn` license; configure hierarchy display rules |
| Depot Repair | Configure Work Order types for depot repair; link to Return Order Line Items |
| Inventory Management | Configure inventory locations; assign `Inventory Item` records |
| Timesheet Management | Configure `PayGrade`, `PayGroup`, `PayPeriod`, `OvertimeType`, `DifferentialShift` records |

---

## Post-Deployment Checklist

After every E&U Cloud deployment to production:

- [ ] All PSLs assigned to relevant user profiles
- [ ] `DefaultPricingPlan__c` custom setting populated
- [ ] Named Credentials tested and verified (CIS, billing, DocuSign, etc.)
- [ ] OmniScripts activated (LWC mode)
- [ ] FlexCards activated and LWC components generated
- [ ] Integration Procedures tested end-to-end with real org data
- [ ] `OmniScriptInstance__c` purge job scheduled
- [ ] DocuSign OAuth 2.0 configured (if CLM/DocGen in scope)
- [ ] VF-based DocGen OmniScripts migrated to LWC equivalents (if upgrading Spring '25+)
- [ ] Multi-currency enabled in both source and target orgs (if multi-currency required)
- [ ] `OrchestrationScenario__c` records verified for all order types
- [ ] `VlocityMatchingKey__mdt` records defined for all custom DataPack types
- [ ] Calculation Matrix rows ≥ 2,000 for bulk-loaded pricing tables
- [ ] Platform Event triggers/flows configured for async order processing
- [ ] Billing interface staging objects (Interface_BillingInfo__c) have automated purge
