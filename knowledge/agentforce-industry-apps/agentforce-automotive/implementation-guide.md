---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf; GitHub: salesforce-misc/DataCloudAndAgentForceForAutomotive
cloud: Automotive Cloud
section: implementation-guide
---

# Automotive Cloud — Implementation Guide

## Pre-Implementation Checklist

Before beginning an Automotive Cloud implementation, confirm all of the following:

- [ ] Org edition is Enterprise, Unlimited, or Developer
- [ ] Required licenses are provisioned: Automotive Cloud, and optionally Vehicle and Asset Finance, Warranty Lifecycle Management, Salesforce Field Service
- [ ] MuleSoft license confirmed if using pre-built integration assets
- [ ] Agentforce/Einstein license confirmed if building Automotive Agents
- [ ] Sandbox strategy defined (Full Copy for production-parallel testing recommended)
- [ ] DMS integration requirements scoped — confirm data volume and sync frequency

---

## Setup Sequence

### Step 1: Enable Core Settings

Deploy `IndustriesAutomotive.settings` first — all other settings depend on this.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<IndustriesAutomotiveSettings xmlns="http://soap.sforce.com/2006/04/metadata">
    <enableAutomotiveCloud>true</enableAutomotiveCloud>
    <enableAutomotiveServiceExcellence>true</enableAutomotiveServiceExcellence>
</IndustriesAutomotiveSettings>
```

Enable additional features after base is active:

```xml
<enableAutomotiveScheduler>true</enableAutomotiveScheduler>       <!-- v58.0+ -->
<enableAutomotiveAppraisals>true</enableAutomotiveAppraisals>     <!-- v63.0+ -->
<enableConnectedVehSrvcsCmpnt>true</enableConnectedVehSrvcsCmpnt> <!-- v63.0+ -->
<enableDealerEssntlsAutomotive>true</enableDealerEssntlsAutomotive> <!-- v63.0+ -->
<enableAutomotiveAgents>true</enableAutomotiveAgents>             <!-- v64.0+ -->
```

For Fleet Management:
```xml
<!-- IndustriesManufacturing.settings -->
<enableFleetManagement>true</enableFleetManagement>               <!-- v59.0+ -->
```

For Criteria-Based Vehicle Search:
```xml
<!-- Industries.settings -->
<enableCriteriaBasedSearchAndFilter>true</enableCriteriaBasedSearchAndFilter>
```

### Step 2: Assign Permission Sets

Automotive Cloud is license-gated per feature set. Assign before testing any objects:

| Permission Set | Who Needs It |
|---|---|
| `Automotive Cloud User` | All Automotive Cloud users |
| `Automotive Cloud Sales` | Dealer sales reps (Lead, Opportunity, Vehicle) |
| `Automotive Cloud Finance` | Finance managers (FinancialAccount hierarchy) |
| `Automotive Cloud Claims` | Claims adjusters (Claim, ClaimCoverage, Appraisal) |
| `Automotive Cloud Fleet` | Fleet managers (Fleet, FleetAsset) |
| `Automotive Cloud Telemetry` | Admins managing connected vehicle telemetry |
| `Field Service Standard` | Service technicians (Visit, ServiceAppointment) |

### Step 3: Configure OWD and Sharing

Set Object-Wide Defaults before creating data:

| Object | OWD |
|---|---|
| `Vehicle` | Private |
| `VehicleDefinition` | Public Read Only |
| `FinancialAccount` | Private |
| `Claim` | Private |
| `Fleet` | Private |
| `Asset` | Controlled by Parent |
| `Appraisal` | Private |
| `SellerProduct` | Private |

### Step 4: Build the Product Catalog (VehicleDefinition → Vehicle)

1. Create `Product2` records for each vehicle model (one per trim level if different pricing)
2. Create `VehicleDefinition` records — one per model/trim/year combination — linked to `Product2`
3. Configure `DealerVehDefSearchableField` and `VehDefSearchableField` for inventory search
4. Import `Vehicle` records linked to `VehicleDefinition` (never create VehicleDefinition per vehicle)
5. Create `SellerProduct` records for dealer inventory

**SOQL to verify relationship integrity:**
```soql
SELECT COUNT(Id), VehicleDefinitionId
FROM Vehicle
WHERE VehicleDefinitionId = null
```
Zero rows expected — every Vehicle must have a VehicleDefinition.

### Step 5: Configure Lead-to-Opportunity Flow

1. Create `ObjectHierarchyRelationship` metadata for `LeadLineItem → OpportunityLineItem` mapping
2. Create `ObjectHierarchyRelationship` for `LeadPreferredSeller → OpportunityPreferredSeller`
3. Test the Transformations API manually:
```bash
curl -X POST https://yourInstance.salesforce.com/services/data/v66.0/connect/manufacturing/transformations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"inputObjectIds":["<leadLineItemId>"],"inputObjectName":"LeadLineItem","usageType":"TransformationMapping","outputObjectName":"OpportunityLineItem","outputObjectDefaultValues":{"OpportunityLineItem":{"OpportunityId":"<oppId>"}}}'
```

### Step 6: Configure Warranty and Claims (if required)

1. Enable `enableWarrantyLifecycleManagement` (separate from base Automotive Cloud)
2. Create `WarrantyTerm` records linked to `Product2`
3. Configure `ProductWarrantyTerm` junction records
4. Set up Claim queues and assignment rules for adjuster routing
5. Configure Claim record types if using both Warranty Claim and Pre-Warranty Authorization

### Step 7: Configure Telemetry (if connected vehicle)

1. Create `TelemetryDefinition` metadata — set `usageType` to `ConnectedVehicle`
2. Create `TelemetryDefinitionVersion` with base64-encoded JSON component structure
3. Create `TelemetryActionDefinition` linking version to a Flow
4. Create `TelemetryActionDefStep` records for each sensor/actuator path
5. Create `ActionableEventTypeDef` metadata for event type classification
6. Create `ActionableEventOrchDef` linking event type to execution Flow
7. Test with POST to `/connect/orchestration/inbound-events`

### Step 8: Configure Fleet Management (if required)

1. Enable `IndustriesManufacturingSettings.enableFleetManagement`
2. Assign Field Service licenses to fleet managers and service techs
3. Create `Fleet` records with proper Account ownership
4. Create `FleetAsset` junction records linking Fleet → Asset (→ Vehicle)
5. Set up `ServiceTerritory`, `WorkType`, and `ServiceResourceSkill` records
6. Create `GenericVisitTask` templates for routine maintenance tasks

### Step 9: Configure Experience Cloud (if customer portal)

1. Set up Customer Community or Customer Community Plus
2. Configure External OWD: `Asset` = Controlled by Parent; `FinancialAccount` = Private
3. Create sharing rules: customers see Assets and FinancialAccounts linked to their Account
4. Build portal pages with Vehicle and FinancialAccount summary components

### Step 10: DMS Integration

1. Add `ExternalId__c` (external ID, unique, indexed) to `Vehicle` and `SellerProduct`
2. Configure Named Credentials for DMS authentication (OAuth 2.0)
3. Use `upsert` with external ID for Vehicle and SellerProduct sync to prevent duplicates
4. For MuleSoft pre-built assets: customise partial failure handling and bulk chunking before go-live
5. Never use DMS proprietary IDs as Salesforce record IDs

---

## Data Volume Considerations

| Object | Expected Volume | Notes |
|---|---|---|
| VehicleDefinition | 100–10,000 | Catalog — low volume |
| Vehicle | 10,000–5M | Per dealer group scale |
| SellerProduct | 1,000–500K | Dealer inventory |
| FinancialAccount | Matches Vehicle | Grows with lending portfolio |
| Claim | Medium-high | Seasonal spikes post-storm |
| TelemetryDefinition | Dozens | Low — config metadata |
| ActionableOrchSourceEvent | Very high | Can be millions/day per fleet |
| ActionableEventOrchestration | High | One per processed event |

---

## Deployment Ordering (package.xml sequence)

Deploy in this order to avoid dependency failures:

1. **Settings** — `IndustriesAutomotiveSettings` first
2. **Custom Objects / Fields** — any org-specific extensions
3. **ObjectHierarchyRelationship** — after both input and output objects exist
4. **ActionableEventTypeDef** — before ActionableEventOrchDef
5. **ActionableEventOrchDef** — depends on event type and Flow
6. **TelemetryDefinition** — before TelemetryDefinitionVersion
7. **TelemetryDefinitionVersion** — before TelemetryActionDefinition
8. **TelemetryActionDefinition** — depends on version
9. **TelemetryActionDefStep + TelemetryActnDefStepAttr** — leaf metadata
10. **Flows** — after all referenced objects deployed
11. **Permission Sets** — after objects/fields
12. **Sharing Rules** — after OWD confirmed

---

## Discovery Questions — Automotive Cloud Engagements

### Personas and Business Model

1. Are you an OEM, dealer group, fleet operator, lender, or a combination?
2. How many dealer locations / service centres need to be represented?
3. Which personas need Salesforce access: sales reps, finance managers, service techs, claims adjusters, fleet managers, customers (portal)?
4. Do you have an existing DMS (Dealer Management System)? Which vendor?
5. Do customers interact with vehicles via a self-service portal today?

### Vehicle Lifecycle

6. How are vehicles currently tracked from manufacturing to sale to end-of-life?
7. What is your VIN management approach — are VINs assigned at import or at manufacture?
8. Do you manage vehicle inventory across multiple locations? How are transfers handled today?
9. Do you need to track appraisals (trade-ins, reacquisitions)?
10. What is your pre-owned/CPO (certified pre-owned) process?

### Financial Products

11. Do you offer auto lending or leasing products? Are they captive finance or third-party?
12. What financial account types are in scope: Automotive Loan, Automotive Lease, Asset Loan, Asset Lease?
13. How many active financial accounts are currently in your system?
14. Do you use a bureau for credit checks? Which provider? Integration required?

### Warranties and Claims

15. Do you manage manufacturer warranties, extended warranties, or both?
16. How many warranty claim types do you process per month?
17. Do you need pre-warranty authorizations (dealer approval before repair)?
18. Do you have supplier recovery claims (OEM recovers cost from parts supplier)?
19. Is claims handling handled in-house or routed to a third party?

### Connected Vehicle / Telematics

20. Do you have connected vehicle infrastructure (OEM telematics platform)?
21. What telematics events do you need to process in Salesforce (faults, location, state)?
22. What is the expected volume of telematics events per day?
23. What actions should fire when an event is received (create case, alert service centre, notify customer)?
24. Do you use MuleSoft for integration? Are you open to MuleSoft Direct Automotive assets?

### Fleet Management

25. Do you manage corporate fleets (company vehicles, trucks, equipment)?
26. How is fleet maintenance scheduled today? Any existing FSL implementation?
27. Do you need fleet-level reporting or only individual vehicle tracking?
28. Are there regulatory requirements (vehicle inspection schedules, driver certification)?

### Data Migration

29. What is the current source of vehicle and customer data?
30. What is the current record count: vehicles, financial accounts, claims, leads?
31. Are there data quality issues in source systems (duplicate VINs, missing fields)?
32. What is the target go-live window and freeze period for data migration?

---

## What Good Looks Like

- Every `Vehicle` record has a `VehicleDefinitionId` — no orphan vehicles
- `VehicleDefinition` is used as a catalog — 1 definition per model/trim, many vehicles per definition
- External IDs on `Vehicle` and `SellerProduct` for all DMS integrations
- OWD set to Private for financial and claims objects before first data load
- Telemetry events processed asynchronously — never in synchronous Apex triggers
- `TelemetryDefinitionVersion` immutability respected — new version created for schema changes
- `ObjectHierarchyRelationship` metadata deployed before Transformations API tested
- Permission sets used instead of profiles for all Automotive-specific access
- Claim routing via queues with queue-based sharing rules (not OWD public)
- Fleet and service objects gated behind Field Service license assignment
