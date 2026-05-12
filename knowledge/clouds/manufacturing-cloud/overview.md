---
source: Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide)
cloud: Manufacturing Cloud
section: overview
last-updated: 2026-05-10
---

# Manufacturing Cloud — Overview

## What Is Manufacturing Cloud

Manufacturing Cloud is a Salesforce industry cloud that provides a data model, APIs, and tools to create and manage sales agreements and account forecasts. It gives manufacturers an integrated sales experience and enables business negotiations and planning by connecting sales data, orders, and forecasts in a single platform.

Manufacturing Cloud is available in **Lightning Experience**.

## Edition Requirements

**Available in:** Enterprise, Unlimited, and Developer Editions.

A Manufacturing Cloud license is required for most features. Specific permission sets are required for individual modules (e.g., Manufacturing Sales Agreements, Manufacturing Advanced Account Forecast, Manufacturing Program Based Business).

## Key Modules

### Sales Agreements
Long-term agreements between a buyer and a seller to negotiate price and volume of products. Sales agreements track planned vs. actual quantities and revenue across multiple product schedules. The core objects are `SalesAgreement`, `SalesAgreementProduct`, and `SalesAgreementProductSchedule`.

### Account Forecasting (Standard)
Rolling forecast records for accounts prepared using data directly from sales agreements, orders, and opportunities. The core objects are `AccountForecast`, `AccountProductForecast`, and `AccountProductPeriodForecast`. Manual adjustments are stored in `AccountForecastAdjustment`.

### Advanced Account Forecasting
An enhanced forecasting capability introduced in API version 53.0 that supports configurable forecast sets, multiple dimensions, display groups, and measure definitions. Core objects include `AdvAccountForecastSet`, `AdvAccountForecastFact`, `AdvAcctForecastFactAdj`, `AdvAcctForecastMeasureDef`, `AdvAccountForecastPeriod`, `AdvAcctForecastDimension`, and related objects.

### Account Manager Targets
Allows account managers to set and track sales targets by fiscal year, measure, and account/product. Core objects: `AcctMgrTarget`, `AcctMgrTargetDstr`, `AcctMgrPeriodicTargetDstr`, `AcctMgrTargetMeasure`.

### Program-Based Business (Manufacturing Programs)
Enables manufacturers to drive business models with forecasting tools and manage end-to-end sales processes. Core objects: `ManufacturingProgram`, `MfgProgramTemplate`, `MfgProgramForecastFact`, `MfgProgramCpntFrcstFact`, `MfgProgramVariantFrcstFact`, `MfgPgmCpntFrcstFactOpptySchd`, `MfgProgramTemplateItem`.

### Warranty Lifecycle Management
Manages warranty terms, claims, and coverage for manufactured products and assets. Core objects: `WarrantyTerm`, `AssetWarranty`, `Claim`, `ClaimItem`, `ClaimCoverage`, `ClaimCoveragePaymentDetail`, `ClaimParticipant`, `ProductWarrantyTerm`, `WarrantyTermCoverage`.

### Product Service Campaigns
Manages campaigns for product recalls, upgrades, and safety campaigns. Core objects: `ProductServiceCampaign`, `ProductServiceCampaignItem`, `ProductSvcCampaignDef`, `ProductSvcCampaignGrpDef`, `ProdtSvcCmpnGrpDefCausalItm`, `ProdtSvcCmpnGrpDefPtnr`, `ProdtSvcCmpnDefPtnrInv`, `ProdtSvcCmpnDefRelaCausalItm`, `ProdtSvcCmpnPreferredPartner`, `ProdtSvcCmpnWorkType`.

### Field Service and Inventory Management
Manages product inventory, transfers, requests, and serialized products. Core objects: `ProductItem`, `ProductItemTransaction`, `ProductTransfer`, `ProductRequest`, `ProductRequestLineItem`, `ProductRequired`, `ProductConsumed`, `SerializedProduct`, `SerializedProductTransaction`, `Shipment`, `ShipmentItem`, `ReturnOrder`, `ReturnOrderLineItem`.

### Visit Management
Manages field representative visits to distributor, supplier, and partner locations. Core objects: `Visit`, `GenericVisitTask`, `GenericVisitTaskContext`, `GnrcVstKeyPerformanceInd`, `GnrcVstTaskContextRelation`.

### Fleet Management
Manages groups of assets used in commercial, service, or transport operations. Core objects: `Fleet`, `FleetAsset`, `FleetParticipant`.

### Supplier and Purchase Order Management
Manages supplier relationships and purchase orders. Core objects: `Supplier`, `SupplierProduct`, `PurchaseOrder`, `PurchaseOrderItem`, `GoodsReceivedNote`, `GoodsReceivedNoteItem`.

### Sample Management and Product Requirement Specifications
Manages product sample requests and requirement specifications for manufacturing. Core objects: `SampleRequest`, `SampleRequestItem`, `ProductRqmtSpec`, `ProductRqmtSpecItem`, `ProductRqmtSpecVersion`.

### Inventory Count and Replenishment
Manages physical inventory counts and automated replenishment policies. Core objects: `InventoryCountPlan`, `InventoryCountPlanItem`, `InventoryCountAssessment`, `InventoryCountProductItem`, `InventoryCntProdtBatchItem`, `InventoryCntSerializedProdt`, `InventoryReplenishmentPolicy`.

### Dealer and Partner Lead Management
Manages partner lead routing and dealer product searches. Core objects: `LeadPreferredSeller`, `OpportunityPreferredSeller`, `DealerProdtSearchableField`, `SellerProduct`.

### Rebates and Stock Rotation
Manages stock rotation rebate activities and claim processing. Core objects: `StockRotationExecution`, `StockRotationExecutionItem`.

### Connected Assets and Telemetry
Manages telemetry signals from connected assets and vehicles. Configured via Metadata API types: `TelemetryDefinition`, `TelemetryDefinitionVersion`, `TelemetryActionDefinition`, `TelemetryActionDefStep`, `TelemetryActnDefStepAttr`.

### Engagement Management
Manages customer interaction records across service representatives and communication channels. Core objects: `EngagementInteraction`, `EngagementAttendee`, `EngagementTopic`.

### Asset Lifecycle Management
Manages asset milestones, asset-account and asset-contact relationships. Core objects: `AssetMilestone`, `AssetAccountParticipant`, `AssetContactParticipant`.

### Code Sets
Manages industry-defined codes (labor codes, fault codes) and their relationships. Core objects: `CodeSet`, `CodesetRelationship`, `ProductFaultCode`, `ProductLaborCode`.

### Production Batches
Manages batches of homogeneous products manufactured in the same production line. Core objects: `ProductionBatch`, `ProductBatchItem`.

## High-Level Data Flow

```
ERP / External Systems
        |
        v
Sales Agreements
  SalesAgreement -> SalesAgreementProduct -> SalesAgreementProductSchedule
        |
        +--------> Account Forecasting
        |          AccountForecast -> AccountProductForecast -> AccountProductPeriodForecast
        |                  |
        |            [Manual Adjustments: AccountForecastAdjustment]
        |
        +--------> Advanced Account Forecasting
        |          AdvAccountForecastSet -> AdvAccountForecastFact -> AdvAcctForecastFactAdj
        |
        +--------> Manufacturing Programs
        |          ManufacturingProgram -> MfgProgramTemplate -> MfgProgramForecastFact
        |                  |
        |            [Transformations -> Opportunity -> OpportunityLineItem]
        |
Orders / Opportunities ---------> Feed into Forecast Actuals Calculation
        |
        v
Account Manager Targets
  AcctMgrTarget -> AcctMgrTargetDstr -> AcctMgrPeriodicTargetDstr
```

## Integration Points

- **ERP Systems**: Sales agreement data (planned quantities, prices) is typically synchronized from ERP systems via the Sales Agreement Connect REST API (`/services/data/vXX.X/connect/manufacturing/sales-agreements`) or bulk data import.
- **Pricing Systems**: Price book entries are referenced from standard Salesforce `PricebookEntry` objects on `SalesAgreementProduct`.
- **Opportunity/Quote Conversion**: The `ObjectHierarchyRelationship` metadata type defines field mappings from Opportunity/Quote to SalesAgreement, enabling conversion via the Sales Agreement (POST) API.
- **CSV Import**: The `importRecordsFromCsvFile` invocable action supports bulk import of forecast data (e.g., `MfgProgramForecastFact`) from CSV files.
- **Transformations API**: The `/connect/manufacturing/transformations` endpoint converts Manufacturing Program component forecast data to Opportunities and OpportunityLineItems.
- **Warranty Claims**: The Warranty To Supplier Claims API (`/connect/manufacturing/warranty-supplier-claims`) clones warranty claims and hierarchy to generate supplier recovery claims.

## Permission Sets Required (by Module)

| Module | Permission Set |
|---|---|
| Sales Agreements | Manufacturing Sales Agreements |
| Advanced Account Forecasting | Manufacturing Advanced Account Forecast |
| Program-Based Business | Manufacturing Program Based Business |
| Import CSV | Import CSV for Advanced Account Forecasting (with Advanced Account Forecast PS) OR Manufacturing Program Based Business PS |
| Mass Update (Adv. Forecast) | Manufacturing Cloud + Advance Account Forecasting feature enabled |
| Warranty | Manufacturing Cloud license |

## API Version History (Key Milestones)

| API Version | Feature Introduced |
|---|---|
| 47.0 | Sales Agreements, Account Forecasting (core objects), AccountForecastSettings |
| 48.0 | Mass Update actions for Forecast and Sales Agreement |
| 49.0 | Account Manager Targets, AccountForecastSettings filters |
| 50.0 | Opportunity probability in forecast calculations |
| 51.0 | Sales Agreement Connect REST API (POST) |
| 52.0 | Calculate Advanced Account Forecasts action |
| 53.0 | Advanced Account Forecasting (AdvAccountForecastSet and related) |
| 54.0 | Advanced Forecast Display Groups (AdvAcctFrcstDisplayGroup), WarrantyLifeCycleMgmtSettings |
| 55.0 | Program-Based Business, AssetWarranty, AdvAcctForecastSetUse, Import CSV action |
| 56.0 | Visit Management, GnrcVst* objects, MfgServiceConsoleSettings |
| 57.0 | SalesAgreementSettings Tooling API |
| 58.0 | Warranty/Claims objects (Claim, CodeSet, AssetMilestone, etc.) |
| 59.0 | Fleet, Supplier, SalesContractLine, AssetAccountParticipant, AssetContactParticipant |
| 60.0 | Field Service inventory objects (ProductItem, ProductTransfer, etc.), SalesAgreeProductAttribute |
| 61.0 | ProductServiceCampaign, Refresh Actuals Calculation for future schedules |
| 62.0 | ProductInvSearchableField, AccountForecastChangeEvent |
| 63.0 | Inventory Count objects, InventoryReplenishmentPolicy |
| 65.0 | DealerProdtSearchableField, GoodsReceivedNote, ProductRqmtSpec, ProductSvcCampaignDef, PurchaseOrder, SellerProduct, StockRotation objects |
| 66.0 | Sample Management (POST) API, PurchaseOrderMgmtSettings |

## API End-of-Life Policy

Salesforce supports each API version for a minimum of 3 years from the date of first release. Customers are notified at least 1 year before support for a version ends.
