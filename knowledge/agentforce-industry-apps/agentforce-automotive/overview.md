---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf; GitHub: salesforce-misc/DataCloudAndAgentForceForAutomotive
cloud: Automotive Cloud
section: overview
---

# Automotive Cloud — Overview

## What It Is

Automotive Cloud is a Salesforce industry cloud that provides data models, APIs, and features for OEMs, dealers, and fleet operators to manage the full vehicle lifecycle — from lead and finance through service, warranties, and end-of-life. It extends the core Sales and Service Cloud platform with automotive-specific objects, metadata types, and business APIs.

**Available editions:** Enterprise, Unlimited, Developer

## Key Use Cases

| Persona | Use Cases |
|---|---|
| OEM | Vehicle definition catalog, dealer network management, warranty terms, telemetry processing |
| Dealer | Lead management with vehicle interest, opportunity-to-sales-agreement, vehicle inventory, service appointments |
| Fleet Manager | Fleet and fleet asset tracking, scheduled maintenance, driver/operator assignments |
| Lender | Auto lending with financial accounts, credit profiles, asset-backed financial products |
| Insurance | Claims management, coverage tracking, appraisals |

## Core Feature Set

- **Vehicle Lifecycle Management**: Track individual vehicles from manufacturing through disposal with `Vehicle` and `VehicleDefinition` objects
- **Inventory Management**: Dealer inventory with `SellerProduct`; REST API for inventory visibility and product transfers
- **Auto Lending**: Full financial account hierarchy linked to vehicle assets; credit profile management
- **Fleet Management**: `Fleet`, `FleetAsset`, `FleetParticipant` for corporate fleet operators
- **Claims and Warranty**: `Claim`, `ClaimItem`, `ClaimCoverage`, `WarrantyTerm`, `AssetWarranty`
- **Telemetry**: `TelemetryDefinition`, `TelemetryActionDefinition` — ingest and act on connected vehicle data
- **Action Plans**: Structured task templates applied to any automotive object
- **Record Alerts**: Surface contextual warnings on record pages
- **Timeline**: Unified activity timeline across automotive objects
- **Interest Tags**: Tag records with interest attributes for personalisation
- **Actionable Segmentation**: Segment customers for targeted outreach
- **Action Launcher**: Quick-launch flows and actions from record pages
- **Criteria-Based Search and Filter**: Faceted vehicle and inventory search
- **Identity Verification / Engagements**: Verify customer identity in service workflows
- **Service Process Studio**: Configure service intake and resolution processes

## Integration

Automotive Cloud integration assets are available in **MuleSoft Direct** for deployment. The three primary REST business APIs are:
1. Inventory Visibility Product Transfer Action
2. Orchestration Inbound Events (POST)
3. Transformations (data mapping/conversion)

## Key Settings to Enable

Enable features via `IndustriesAutomotiveSettings` metadata (file: `IndustriesAutomotive.settings`):

| Setting | Enables |
|---|---|
| `enableAutomotiveCloud` | Core Automotive Cloud — enable first |
| `enableAutomotiveServiceExcellence` | Service Console for Automotive |
| `enableAutomotiveScheduler` | Salesforce Scheduler integration (v58.0+) |
| `enableAutomotiveAppraisals` | Appraisal Management (v63.0+) |
| `enableConnectedVehSrvcsCmpnt` | Connected Vehicle Services (v63.0+) |
| `enableDealerEssntlsAutomotive` | Dealer Essentials (v63.0+) |
| `enableAutomotiveAgents` | Agentforce for Automotive (v64.0+) |

Additional settings:
- `IndustriesManufacturingSettings.enableFleetManagement` — Fleet Management (v59.0+)
- `IndustriesSettings.enableCriteriaBasedSearchAndFilter` — Vehicle inventory search

## Required Licenses

| License | For |
|---|---|
| Automotive Cloud | Core objects (Vehicle, Fleet, Claim, etc.) |
| Vehicle and Asset Finance | FinancialAccount objects |
| Warranty Lifecycle Management | Claim objects |
| Salesforce Field Service | Visit, ServiceTerritory, ServiceAppointment objects |
| Agentforce / Einstein | Agentforce agents for Automotive |
| MuleSoft | Pre-built integration assets in MuleSoft Direct |

## Data Cloud Integration (from real implementations)

Reference implementation (`salesforce-misc/DataCloudAndAgentForceForAutomotive`) uses:
- **Data Streams:** Salesforce CRM connector, Experience Cloud Event Connector, Ingestion APIs (real-time telemetric data, vehicle issues)
- **Calculated Insights:** Customer Lifetime Value, Customer Satisfaction Score, Interest from survey data
- **Data Graphs:** Web Engagement RT, Automotive Real Time
- **ML Model:** Predicted Likelihood of Purchase (trained on Opportunity data: Total Amount, Test Drive Date, Car Model, Interactions)
- **Segments:** High Purchase Probability, Warranty End Date, Dealership Visitors
- **Agentforce:** Service Agent with Einstein Search (hybrid, E5 Large V2), Product Retriever, FAQ Retriever
