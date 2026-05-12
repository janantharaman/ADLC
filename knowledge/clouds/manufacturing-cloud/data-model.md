---
source: "Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide); mfg_api_devguide.pdf (Spring '26, April 30, 2026)"
cloud: Manufacturing Cloud
section: data-model
last-updated: 2026-05-10
---

# Manufacturing Cloud — Data Model

## Edition and Availability

Manufacturing Cloud is available in Lightning Experience.
Available in: Enterprise, Unlimited, and Developer Editions.

## Object Relationship Diagram (Text)

```
Account
  |-- AccountForecast (1 active per account)
  |     |-- AccountProductForecast (per product, per rolling period)
  |           |-- AccountProductPeriodForecast (per product, per schedule period)
  |                 |-- AccountForecastAdjustment (manual adjustments)
  |
  |-- AdvAccountForecastSet (advanced forecast configuration)
  |     |-- AdvAcctForecastSetPartner (junction: set <-> account)
  |     |-- AdvAcctForecastSetUse (junction: set <-> context object, e.g. ManufacturingProgram)
  |     |-- AdvAcctForecastDimension (dimensions for the set)
  |     |-- AdvAcctForecastMeasureDef (measures displayed in grid)
  |     |-- AdvAcctFrcstDisplayGroup (display groups)
  |     |     |-- AdvAcctFrcstDplyGroupItem (items in a display group)
  |     |-- AdvAccountForecastPeriod
  |     |     |-- AdvAcctForecastPeriodGroup
  |     |-- AdvAccountForecastFact (generated forecast records)
  |     |     |-- AdvAcctForecastFactAdj (adjustments to forecast facts)
  |     |-- AdvAcctForecastDimSource (available dimension sources)
  |     |-- AdvAcctForecastAdjPeriod (adjustment period details)
  |
  |-- SalesAgreement
        |-- SalesAgreementProduct (per product)
        |     |-- SalesAgreementProductSchedule (per period)
        |     |     |-- SalesAgreementProdSchdAdj (manual adjustments)
        |     |-- SalesAgreeProductAttribute (custom key-value attributes)
        |-- [linked to Account via AccountId]

AcctMgrTarget
  |-- AcctMgrTargetDstr (per account/product/price book)
  |     |-- AcctMgrPeriodicTargetDstr (per period, 12 period fields)
  |-- AcctMgrTargetMeasure (measure picklist)

ManufacturingProgram
  |-- MfgProgramTemplate
  |     |-- MfgProgramTemplateItem (transformation type per template)
  |-- MfgProgramForecastFact (generated program forecast)
  |-- MfgProgramCpntFrcstFact (component forecast)
  |     |-- MfgPgmCpntFrcstFactOpptySchd (junction: forecast <-> OpportunityLineItemSchedule)
  |-- MfgProgramVariantFrcstFact (product variant forecast)

Asset
  |-- AssetWarranty -> WarrantyTerm
  |-- AssetMilestone
  |-- AssetAccountParticipant -> Account
  |-- AssetContactParticipant -> Contact

Claim
  |-- ClaimItem (defective asset)
  |-- ClaimCoverage (causal part)
  |     |-- ClaimCoveragePaymentDetail
  |-- ClaimParticipant -> Account

ProductItem (inventory at location)
  |-- ProductItemTransaction (consumed/replenished/adjusted/transferred)

ProductTransfer
  |-- ProductTransferState (serialized product state changes)

ProductRequest
  |-- ProductRequestLineItem

ProductionBatch
  |-- ProductBatchItem

InventoryCountPlan
  |-- InventoryCountPlanItem (products in plan)
InventoryCountAssessment
  |-- InventoryCountProductItem
  |     |-- InventoryCntProdtBatchItem
  |-- InventoryCntSerializedProdt

PurchaseOrder
  |-- PurchaseOrderItem
  |-- GoodsReceivedNote
        |-- GoodsReceivedNoteItem

ProductServiceCampaign
  |-- ProductServiceCampaignItem
  |-- ProductSvcCampaignDef
  |     |-- ProdtSvcCmpnDefPtnrInv
  |     |-- ProdtSvcCmpnDefRelaCausalItm
  |-- ProductSvcCampaignGrpDef
        |-- ProdtSvcCmpnGrpDefCausalItm
        |-- ProdtSvcCmpnGrpDefPtnr
        |-- ProdtSvcCmpnPreferredPartner
        |-- ProdtSvcCmpnWorkType

Fleet
  |-- FleetAsset -> Asset
  |-- FleetParticipant -> Account/Contact/User

Visit
  |-- GenericVisitTask
        |-- GenericVisitTaskContext
        |-- GnrcVstTaskContextRelation
        |-- GnrcVstKeyPerformanceInd

Supplier
  |-- SupplierProduct

ProductRqmtSpec
  |-- ProductRqmtSpecVersion
        |-- ProductRqmtSpecItem

SampleRequest
  |-- SampleRequestItem
```

---

## Domain 1: Sales Agreements

### SalesAgreement
Represents a long-term agreement between a buyer and a seller to negotiate price and volume of products. Available in API version 47.0 and later.

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Key Fields:**

| Field | Type | Description |
|---|---|---|
| AccountId | reference | ID of the referenced account |
| ActivatedDate | dateTime | Date/time the sales agreement was activated |
| ActualMarginPercentage | percent | Total actual margin as a percentage of total actual amount |
| ActualsCalculationMode | picklist | Mode used to calculate actuals: `DataProcessingEngine`, `Manual`, `Orders`, `OrdersThroughContracts` |
| AgreementType | picklist | Deprecated. Type of agreement (always volume-based) |
| ApprovedById | reference | ID of approving user |
| ApprovedDate | dateTime | Date/time of approval |
| CancellationDate | dateTime | Date/time of cancellation |
| CancellationReason | picklist | Reason for cancellation (customizable values) |
| ContactId | reference | ID of contact associated with the agreement account |
| DecimalScale | int | Number of decimal places applied to values |
| Description | textarea | User-defined context and information |
| EndDate | date | Date the sales agreement expires |
| FutureActCalcSchedules | int | Number of future schedules to include in actuals calculations |
| LastActualsCalculatedDate | dateTime | Date/time actuals were last calculated |
| Name | string | User-defined name of the sales agreement |
| OwnerId | reference | ID of record owner |
| PlannedMarginPercentage | percent | Total planned margin as a percentage of total planned amount |
| PriceAdjustmentScheduleId | reference | Price adjustment schedule associated with the agreement (API v59.0+) |
| ScheduleCount | int | Number of schedule periods |
| ScheduleFrequency | picklist | Frequency of schedule periods (Monthly, Quarterly, Yearly, Weekly) |
| StartDate | date | Start date of the agreement |
| Status | picklist | Status: `Draft`, `Active`, `Expired`, `Cancelled` |
| TotalActualAmount | currency | Total actual revenue amount |
| TotalActualQuantity | double | Total actual quantity |
| TotalPlannedAmount | currency | Total planned revenue amount |
| TotalPlannedQuantity | double | Total planned quantity |

**Associated Objects:** SalesAgreementChangeEvent, SalesAgreementShare

---

## Key Object Field Reference (Full)

This section contains complete field tables extracted from the Manufacturing Cloud Developer Guide (Spring '26).

---

### SalesAgreement — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Associated Objects:** SalesAgreementChangeEvent (API v62.0+), SalesAgreementShare

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountId | reference | Create, Filter, Group, Sort, Update | ID of the referenced account. Relationship: Account (Lookup) |
| ActivatedDate | dateTime | Filter, Nillable, Sort | Date and time on which the sales agreement is activated |
| ActualMarginPercentage | percent | Filter, Nillable, Sort | The total actual margin amount as a percentage of total actual amount |
| ActualsCalculationMode | picklist | Create, Defaulted on create, Filter, Group, Nillable, Sort, Update | Mode used to calculate actuals. Values: `DataProcessingEngine`, `Manual`, `Orders`, `OrdersThroughContracts` |
| AgreementType | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | **Deprecated.** Do not add to page layout. Type of the sales agreement (always volume-based) |
| ApprovedById | reference | Filter, Group, Nillable, Sort | ID of the user who approves the sales agreement. Relationship: ApprovedBy (Lookup → User) |
| ApprovedDate | dateTime | Filter, Nillable, Sort | Date and time on which the sales agreement was approved |
| CancellationDate | dateTime | Filter, Nillable, Sort | Date and time on which the sales agreement was canceled |
| CancellationReason | picklist | Filter, Group, Nillable, Sort, Update | Reason for canceling the sales agreement. Values can be customized |
| ContactId | reference | Create, Filter, Group, Nillable, Sort, Update | ID of a contact associated with the sales agreement account. Relationship: Contact (Lookup) |
| DecimalScale | int | Create, Filter, Group, idLookup, Nillable, Sort, Update | The number of decimal places applied to values in a sales agreement |
| Description | textarea | Create, Nillable, Update | User-defined context and information about the sales agreement |
| EndDate | date | Create, Filter, Group, Nillable, Sort, Update | Date and time on which the sales agreement expires |
| FutureActCalcSchedules | int | Create, Filter, Group, Nillable, Sort, Update | The number of future schedules to include in actuals calculations |
| LastActualsCalculatedDate | dateTime | Filter, Nillable, Sort | Date and time on which actuals were last calculated (automated daily job or ad-hoc action) |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | User-defined name of the sales agreement |
| OwnerId | reference | Create, Defaulted on create, Filter, Group, Sort, Update | ID of the user who owns this record. Relationship: Owner (Lookup → Group, User) |
| PlannedMarginPercentage | percent | Filter, Nillable, Sort | The total planned margin amount as a percentage of total planned amount |
| PriceAdjustmentScheduleId | reference | Create, Filter, Group, Nillable, Sort, Update | The price adjustment schedule associated with the sales agreement. Available in API version 59.0 and later. Relationship: PriceAdjustmentSchedule |
| PricebookId | reference | Create, Filter, Group, Nillable, Sort, Update | ID of the associated price book. Relationship: Pricebook (Lookup → Pricebook2) |
| ProductLevel | picklist | Create, Defaulted on create, Filter, Group, Sort, Update | Level of the products associated with the sales agreement. Values: `Product`, `ProductCategory` (Category). Default: `Product` |
| ReferenceFieldId | reference | Create, Filter, Group, Nillable, Sort, Update | The manufacturing program associated with the sales agreement. Available in API version 57.0 and later. Relationship: ReferenceField → ManufacturingProgram |
| RenewedFromAgreementId | reference | Create, Filter, Group, Nillable, Sort, Update | ID of the immediate parent from which the sales agreement is renewed. Relationship: RenewedFromAgreement (Lookup → SalesAgreement) |
| RenewedToAgreementId | reference | Filter, Group, Nillable, Sort | ID of the renewed sales agreement. Relationship: RenewedToAgreement (Lookup → SalesAgreement) |
| ScheduleCount | int | Create, Filter, Group, Sort, Update | Number of schedules in the sales agreement |
| ScheduleFrequency | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | Frequency at which schedules occur. Values: `Monthly`, `Onetime` (One-Time), `Quarterly`, `Weekly`, `Yearly`. Default: `Weekly` |
| ShouldUserSpecPlnQuantity | boolean | Create, Defaulted on create, Filter, Group, Sort, Update | Whether the user specifies planned quantity (true) or it is auto-distributed (false). Default: false |
| StartDate | date | Create, Filter, Group, Sort, Update | Date on which the sales agreement must get activated |
| Status | picklist | Create, Defaulted on create, Filter, Group, Sort, Update | Status of the sales agreement. Values: `Activated`, `Approved`, `Cancelled`, `Draft`, `Expired`, `Rejected`, `UnderRevision`. Default: `Draft` |
| StatusCode | picklist | Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort | Set of five predefined status codes. Values: `Activated`, `Approved`, `Cancelled`, `Draft`, `Expired`, `Rejected`, `UnderRevision`. Default: `Draft` |
| TotalActualAgreementAmount | currency | Filter, Nillable, Sort | The sum of total actual amounts across all products. Calculated field |
| TotalActualCostAmount | currency | Filter, Nillable, Sort | The sum of total actual cost amounts across all products. Calculated field |
| TotalActualMarginAmount | currency | Filter, Nillable, Sort | The sum of total actual margin amounts across all products. Calculated field |
| TotalAgreementAmount | currency | Filter, Nillable, Sort | Total value of the sales agreement. Calculated field |
| TotalPlannedCostAmount | currency | Filter, Nillable, Sort | The sum of total planned cost amounts across all products. Calculated field |
| TotalPlannedMarginAmount | currency | Filter, Nillable, Sort | The sum of total planned margin amounts across all products. Calculated field |
| TotalProposedAgreementAmount | currency | Filter, Nillable, Sort | Total value of the sales agreement when under revision. Calculated field |

**Note on Status field:** The Status field values can be customized but must map to at least one of the predefined status codes.

---

### SalesAgreementProduct — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Associated Objects:** SalesAgreementProductChangeEvent (API v62.0+), SalesAgreementProductHistory (API v49.0+)

| Field Name | Type | Properties | Description |
|---|---|---|---|
| ActualMarginPercentage | percent | Filter, Nillable, Sort | The total actual margin amount as a percentage of total actual amount |
| AreSchedulesCreatedManually | boolean | Create, Defaulted on create, Filter, Group, Sort, Update | Indicates whether schedules are created automatically or manually |
| CostPrice | currency | Filter, Nillable, Sort | The cost of manufacturing one unit of a product. Calculated field |
| DiscountPercentage | percent | Filter, Nillable, Sort | Percent of discount offered on the sales price |
| DisplayName | string | Create, Filter, Group, Nillable, Sort, Update | Display name for the product |
| GuidancePrice | currency | Create, Filter, Nillable, Sort, Update | The guidance price calculated using core pricing rules, used to determine the sales price |
| InitialPlannedAmount | currency | Create, Filter, Nillable, Sort, Update | The total amount of the product/category initially planned across the sales agreement term |
| InitialPlannedQtyValue | double | Create, Filter, Nillable, Sort, Update | The initial quantity of a product planned for sale across schedules. Stores decimal values |
| InitialPlannedQuantity | int | Filter, Group, Sort | The total quantity of the product/category initially planned across the sales agreement term (integer) |
| IsActualsCalculationProduct | boolean | Create, Defaulted on create, Filter, Group, Sort, Update | Indicates whether this product is used for actuals calculations instead of other products with the same product name. Default: false |
| IsAddedAfterActivation | boolean | Defaulted on create, Filter, Group, Sort | Indicates whether the product/category was added after the sales agreement was activated. Default: false |
| IsQuantityInDecimals | boolean | Create, Defaulted on create, Filter, Group, Sort, Update | Indicates whether quantities are decimal values (true) or integer values (false). Default: false |
| IsUnderRevision | boolean | Defaulted on create, Filter, Group, Sort | Indicator of whether the product/category is under revision |
| LastPricingExecIdentifier | string | Filter, Group, idLookup, Sort | The unique identifier for the last price waterfall information |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| ListPrice | currency | Filter, Nillable, Sort | Price of a product as specified in a price book |
| Name | string | Filter, Group, idLookup, Sort | Name of the product or category |
| PlannedMarginPercentage | percent | Filter, Nillable, Sort | The total planned margin amount as a percentage of total planned amount |
| PricebookEntryId | reference | Filter, Group, Sort | ID of the referenced price book |
| ProductCategoryId | reference | Create, Filter, Group, Nillable, Sort | The product category associated with the sales agreement. Relationship: ProductCategory (Lookup) |
| ProductId | reference | Filter, Group, Nillable, Sort | ID of the product |
| SalesAgreementId | reference | Filter, Group, Sort | ID of the sales agreement to which the product is added |
| SalesPrice | currency | Filter, Nillable, Sort | Price per unit at which you initially decide to sell the product |
| TotalActualAmount | currency | Filter, Nillable, Sort | Sum of actual amounts across all schedules at a given time |
| TotalActualCostAmount | currency | Filter, Nillable, Sort | Sum of actual cost amounts across all schedules. Calculated field |
| TotalActualMarginAmount | currency | Filter, Nillable, Sort | Sum of actual margin amounts across all schedules. Calculated field |
| TotalActualQuantity | int | Filter, Group, Nillable, Sort | Sum of actual quantities across all schedules at a given time |
| TotalActualQuantityValue | double | Filter, Nillable, Sort | Sum of actual quantities in decimals. Calculated field |
| TotalActualShipmentQuantity | double | Filter, Nillable, Sort | Sum of actual shipment quantities across all schedules. Calculated field |
| TotalClonedActualQuantity | double | Filter, Nillable, Sort | Rolled up cumulative actual quantity based on cloned actual quantities. Calculated field |
| TotalForecastedAmount | currency | Filter, Nillable, Sort | Sum of forecasted amounts across all schedules at a given time |
| TotalForecastedQuantity | int | Filter, Group, Nillable, Sort | Sum of forecasted quantities across all schedules at a given time |
| TotalForecastedQtyValue | double | Filter, Nillable, Sort | Sum of forecasted quantities in decimals. Calculated field |
| TotalPlannedAmount | currency | Filter, Nillable, Sort | Sum of planned amounts across all schedules at a given time |
| TotalPlannedCostAmount | currency | Filter, Nillable, Sort | Sum of planned cost amounts across all schedules. Calculated field |
| TotalPlannedMarginAmount | currency | Filter, Nillable, Sort | Sum of planned margin amounts across all schedules. Calculated field |
| TotalPlannedQuantity | int | Filter, Group, Nillable, Sort | Sum of planned quantities across all schedules at a given time |
| TotalPlannedQuantityValue | double | Filter, Nillable, Sort | Sum of planned quantities in decimals. Calculated field |
| TotalPlannedShipmentQuantity | double | Filter, Nillable, Sort | Sum of planned shipment quantities. Calculated field |
| TotalProposedPlannedAmount | currency | Filter, Nillable, Sort | Sum of planned amounts when sales agreement is under revision |
| TotalProposedPlannedQuantity | int | Filter, Group, Nillable, Sort | Sum of planned quantities when sales agreement is under revision |
| TotalProposedPlnQtyValue | double | Filter, Nillable, Sort | Sum of proposed quantities in decimals. Calculated field |
| TotalUnallocatedOrderQuantity | double | Filter, Nillable, Sort | Sum of unallocated order quantities across all schedules. Calculated field |
| TotalUnallocatedOrderRevenue | currency | Filter, Nillable, Sort | Sum of unallocated order revenue across all schedules. Calculated field |
| TotalUnallocatedPlannedQty | double | Filter, Nillable, Sort | Difference between initial planned quantity value and total planned quantity value for manually distributed products |

---

### SalesAgreementProductSchedule — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), update()

**Associated Objects:** SalesAgreementProductScheduleHistory (API v49.0+)

| Field Name | Type | Properties | Description |
|---|---|---|---|
| ActualAmount | currency | Filter, Nillable, Sort | Actual amount per product per schedule of a sales agreement |
| ActualCostAmount | currency | Filter, Nillable, Sort | The cost of manufacturing the actual quantity of a product |
| ActualMarginAmount | currency | Filter, Nillable, Sort | The difference between sales price and cost price for the actual quantity |
| ActualMarginPercentage | percent | Filter, Nillable, Sort | The difference between sales price and cost price for the actual quantity, as a percentage of the sales price |
| ActualQuantity | int | Filter, Group, Nillable, Sort | Actual quantity per product per schedule of a sales agreement |
| ActualQuantityValue | double | Filter, Nillable, Sort, Update | The actual quantity in decimals |
| ActualShipmentQuantity | double | Filter, Nillable, Sort, Update | The actual quantity of a product being shipped to a partner |
| ClonedActualQuantity | double | Filter, Nillable, Sort, Update | The actual quantity copied over from an agreement from which the current schedule was deep cloned |
| CostPrice | currency | Filter, Nillable, Sort, Update | The cost of manufacturing one unit of a product |
| DerivedPlannedAmount | currency | Filter, Nillable, Sort | Planned amount per product per schedule of a sales agreement |
| DiscountPercentage | percent | Filter, Nillable, Sort | Percent of discount per unit of the product for a specific schedule |
| EndDate | date | Filter, Group, Sort | Date on which the schedule ends |
| ForecastedAmount | currency | Filter, Nillable, Sort | Forecasted amount per product per schedule of a sales agreement |
| ForecastedQuantity | int | Filter, Group, Nillable, Sort | Forecasted Quantity per product per schedule of a sales agreement |
| ForecastedQuantityValue | double | Filter, Nillable, Sort, Update | The forecasted quantity in decimals |
| IsUnderRevision | boolean | Defaulted on create, Filter, Group, Sort | Indicator of whether the schedule is under revision |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| MaximumOrderQuantity | double | Filter, Nillable, Sort, Update | The maximum quantity for a product in a single order |
| MinimumPurchaseQuantity | double | Filter, Nillable, Sort, Update | The minimum quantity of a product that a partner must purchase for a specific schedule |
| MinimumPurchaseRevenue | currency | Filter, Nillable, Sort, Update | The minimum revenue of a product that must be generated for a specific schedule |
| Name | string | Filter, Group, idLookup, Sort | User-defined name of the schedule. Note: name should capture the month/quarter/year for that period |
| PlannedAmount | currency | Filter, Nillable, Sort, Update | Planned amount for a product for a specific schedule |
| PlannedCostAmount | currency | Filter, Nillable, Sort | The cost of manufacturing the planned quantity of a product |
| PlannedMarginAmount | currency | Filter, Nillable, Sort | The difference between sales price and cost price for the planned quantity |
| PlannedMarginPercentage | percent | Filter, Nillable, Sort | The difference between sales price and cost price for the planned quantity, as a percentage of the sales price |
| PlannedQuantity | int | Filter, Group, Nillable, Sort | Planned quantity for a product for a specific schedule |
| PlannedQuantityValue | double | Filter, Nillable, Sort, Update | The planned quantity in decimals |
| PlannedShipmentQuantity | double | Filter, Nillable, Sort, Update | The planned quantity of a product to be shipped to a partner |
| ProposedCostPrice | currency | Filter, Nillable, Sort, Update | The proposed cost for one unit when under revision |
| ProposedDerivedPlannedAmount | currency | Filter, Nillable, Sort | Planned amount for a specific schedule when under revision |
| ProposedDiscountPercentage | percent | Filter, Nillable, Sort | Discount per unit per schedule when under revision |
| ProposedPlannedAmount | currency | Filter, Nillable, Sort, Update | Planned amount for a specific schedule when under revision |
| ProposedPlannedQuantity | int | Filter, Group, Nillable, Sort | Planned quantity for a specific schedule when under revision |
| ProposedPlannedQtyValue | double | Filter, Nillable, Sort, Update | The planned quantity in decimals when under revision |
| ProposedSalesPrice | currency | Filter, Nillable, Sort | Price per unit per schedule when under revision |
| SalesAgreementProductId | reference | Filter, Group, Sort | ID of the sales agreement product of which the schedule is a part |
| SalesPrice | currency | Filter, Nillable, Sort | Price per unit per schedule of the product at which you want to sell it |
| StartDate | date | Filter, Group, Sort | Date on which the schedule starts |
| UnallocatedOrderQuantity | double | Filter, Nillable, Sort, Update | The ordered quantity of a product that isn't associated with a sales agreement |
| UnallocatedOrderRevenue | currency | Filter, Nillable, Sort, Update | The revenue generated from an order that isn't associated with a sales agreement |

---

### SalesAgreementProdSchdAdj — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdjustedBy | reference | Filter, Group, Sort | The ID of the user who made an adjustment to the sales agreement product schedule record |
| SalesAgreementProductSchedule | reference | Filter, Group, Sort | The sales agreement product schedule record to which an adjustment was made |
| AdvAccountForecastMeasureDefinition | reference | Filter, Group, Sort | The measure definition of the advanced account forecast record to which the adjustment is being made |
| InitialValue | int | Create, Filter, Group, Sort, Update | The value in the sales agreement product schedule record before the adjustment |
| UpdatedValueStatus | picklist | Create, Filter, Group, Restricted picklist, Sort, Update | The status of the adjustment made to a sales agreement product schedule |
| Comment | textarea | Create, Nillable, Update | Additional information provided by the user who made the adjustments |

---

### SalesAgreeProductAttribute — Complete Field Reference

**API Version:** 60.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), query(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AttributeDefinitionId | reference | Create, Filter, Group, Sort, Update | The definition of the attribute that describes the sales agreement product. Relationship: AttributeDefinition (Lookup) |
| AttributeDefinitionName | string | Filter, Group, idLookup, Nillable, Sort | The name of the sales agreement product attribute |
| AttributePicklistValueId | reference | Create, Filter, Group, Nillable, Sort, Update | The value in the attribute picklist that describes the sales agreement product. Relationship: AttributePicklistValue (Lookup) |
| AttributeValue | string | Create, Filter, Group, Nillable, Sort, Update | The value of the sales agreement product attribute |
| SalesAgreementProductId | reference | Create, Filter, Group, Sort | The sales agreement product that the attribute describes. Relationship: SalesAgreementProduct (Lookup) |
| UnitOfMeasure | reference | Create, Filter, Group, Sort, Update | The unit of measure associated with the sales agreement product attribute. Relationship: UnitOfMeasure (Lookup) |

---

### AccountForecast — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Associated Objects:** AccountForecastChangeEvent (API v62.0+)

**Special Access Rules:** Only the account owner can create the account forecast record.

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountId | reference | Filter, Group, Sort | ID of the account for which forecast is generated |
| DefaultAccountGrowthPercentage | percent | Filter, Nillable, Sort | Default value of the account growth metric used to calculate forecast for the first time. Default: 0 |
| DefaultMarketGrowthPercentage | percent | Filter, Nillable, Sort | Default value of the market growth metric used to calculate forecast for the first time. Default: 0 |
| EndDate | date | Filter, Group, Nillable, Sort | Date till which forecast is generated. Note: must be null for active forecasts; cannot be updated |
| LastCalculatedDate | dateTime | Filter, Nillable, Sort | Date on which forecast was last calculated, either automatically or manually |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| Name | string | Filter, Group, idLookup, Sort | Name of the account forecast record |
| OwnerId | reference | Filter, Group, Sort | Owner of the account. Note: only the account owner can create the forecast record |
| StartDate | date | Filter, Group, Nillable, Sort | Date from which forecast is generated. Created automatically in active status |
| Status | picklist | Defaulted on create, Filter, Group, Restricted picklist, Sort | Status of the forecast record. Values: `Active`, `Expired`. Constraints: only 1 active at a time; cannot change from Expired to Active; active records must be expired before deletion |
| TotalAdjustedRevenue | double | Filter, Nillable, Sort | Total revenue after manual adjustments are made |
| TotalRevenue | double | Filter, Nillable, Sort | Total revenue as calculated by the application |

---

### AccountForecastAdjustment — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountProdPeriodForecastId | reference | Filter, Group, Sort | Lookup to the account product period ID to which adjustments are made |
| AdjustedById | reference | Filter, Group, Sort | ID of the user who makes the adjustment |
| AdjustedByName | string | Filter, Group, Sort | Name of the user who makes the adjustment |
| AdjustmentComments | textarea | Nillable | Notes provided by the user stating reason for adjustment. Can be updated along with AdjustedForecastedQuantity or AdjustedForecastedRevenue |
| AdjustmentType | picklist | Defaulted on create, Filter, Group, Restricted picklist, Sort | States whether adjustment is made to forecast quantity or forecast revenue. Values: `Quantity`, `Revenue` |
| FromValue | double | Filter, Nillable, Sort | Value before adjustment |
| IsActive | boolean | Defaulted on create, Filter, Group, Sort | Whether the adjustment is recorded as part of the edit history. Only last three changes (including auto-calculated value) are recorded |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| Name | string | Filter, Group, idLookup, Sort | Name of the record |
| ToValue | double | Filter, Nillable, Sort | Value after adjustment |

**Note:** To reset the adjusted quantity or adjusted revenue, deduct 999 from the value. This will reset the adjusted forecast quantity or adjusted forecast revenue to the auto-calculated value.

---

### AccountForecastPeriodMetric — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), update()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountForecastId | reference | Filter, Group, Sort | ID of the account forecast record which the period metrics are part of |
| AccountGrowthPercentage | percent | Filter, Nillable, Sort | Expected or projected rate of growth for the account, for that particular forecast period |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| MarketGrowthPercentage | percent | Filter, Nillable, Sort | Expected or projected rate of growth for the market, for that particular forecast period |
| Name | string | Filter, Group, idLookup, Sort | Name of the record |
| PeriodId | reference | Filter, Group, Sort | ID of the period as derived from the Period entity based on the fiscal year |

---

### AccountProductForecast — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountForecastId | reference | Filter, Group, Sort | ID of the account forecast record which the account product is part of |
| IsActive | boolean | Defaulted on create, Filter, Group, Sort | Indicator of whether the product is active or not |
| IsSystemGenerated | boolean | Defaulted on create, Filter, Group, Sort | Indicator of whether the record was manually inserted or system-generated |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| Name | string | Filter, Group, idLookup, Sort | Name of the product |
| ProductId | reference | Filter, Group, Sort | ID of the product |
| TotalAdjustedForecastedQuantity | double | Filter, Group, Nillable, Sort | Total forecasted quantity after manual adjustments |
| TotalAdjustedForecastedRevenue | double | Filter, Nillable, Sort | Total forecasted revenue after manual adjustments |
| TotalCurrentOrdersQuantity | double | Filter, Group, Nillable, Sort | Total quantity derived from orders in the current period |
| TotalCurrentOrdersRevenue | double | Filter, Nillable, Sort | Total revenue derived from orders in the current period |
| TotalForecastedQuantity | double | Filter, Group, Nillable, Sort | Total forecasted quantity before manual adjustments |
| TotalForecastedRevenue | double | Filter, Nillable, Sort | Total forecasted revenue before manual adjustments |
| TotalOpportunityQuantity | double | Filter, Group, Nillable, Sort | Total quantity derived from opportunities in the current period |
| TotalOpportunityRevenue | double | Filter, Nillable, Sort | Total revenue derived from opportunities in the current period |
| TotalPastOrdersQuantity | double | Filter, Group, Nillable, Sort | Total quantity derived from orders in the last forecast period |
| TotalPastOrdersRevenue | double | Filter, Nillable, Sort | Total revenue derived from orders in the last forecast period |
| TotalSalesAgreementPlannedQuantity | double | Filter, Group, Nillable, Sort | Total planned quantity derived from sales agreements in the current period |
| TotalSalesAgreementPlannedRevenue | double | Filter, Nillable, Sort | Total planned revenue derived from sales agreements in the current period |

---

### AccountProductPeriodForecast — Complete Field Reference

**API Version:** 47.0 and later

**Supported Calls:** describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), update()

**Important:** Other than `AdjustedForecastedQuantity` and `AdjustedForecastedRevenue` (and `AdjustmentComments`), no other fields of this object can be updated.

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccForecastPeriodMetricId | reference | Filter, Group, Nillable, Sort | ID of each account forecast period metric used in forecast formula calculations |
| AccountProductForecastId | reference | Filter, Group, Sort | ID of a specific product for which forecast is calculated for this period |
| AdjustedForecastedQuantity | double | Filter, Nillable, Sort | Forecasted quantity either auto-calculated or overwritten by a user. Note: cannot be updated for past schedules |
| AdjustedForecastedRevenue | double | Filter, Nillable, Sort | Forecasted revenue either auto-calculated or overwritten by a user. Note: cannot be updated for past schedules |
| AdjustmentComments | textarea | Nillable | User-defined notes stating the reason for a manual adjustment. Can be updated along with AdjustedForecastedQuantity or AdjustedForecastedRevenue |
| CurrentOrdersQuantity | double | Filter, Nillable, Sort | Calculated quantity of all active orders for this account in the current period |
| CurrentOrdersRevenue | double | Filter, Nillable, Sort | Calculated revenue of all active orders for this account in the current period |
| ForecastedQuantity | double | Filter, Nillable, Sort | Auto-calculated quantity based on forecast formula and configurations |
| ForecastedRevenue | double | Filter, Nillable, Sort | Auto-calculated revenue based on forecast formula and configurations |
| IsActive | boolean | Defaulted on create, Filter, Group, Sort | Indicator of whether the record is part of the forecast display period |
| LastCalculatedDate | dateTime | Filter, Nillable, Sort | Date when the value was last calculated (due to rolling over or through recalculation) |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was referenced |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The most recent date on which this record was viewed |
| Name | string | Filter, Group, idLookup, Sort | Name of the record |
| OpportunityQuantity | double | Filter, Nillable, Sort | Calculated quantity of all active opportunities for this account in the current period |
| OpportunityRevenue | double | Filter, Nillable, Sort | Calculated revenue of all active opportunities for this account in the current period |
| PastOrdersQuantity | double | Filter, Nillable, Sort | Calculated quantity of all active orders for this account in the last forecast period |
| PastOrdersRevenue | double | Filter, Nillable, Sort | Calculated revenue of all active orders for this account in the last forecast period |
| PeriodId | reference | Filter, Group, Sort | ID of the period as derived from the Period entity based on the fiscal year |
| SalesAgreementPlannedQuantity | double | Filter, Nillable, Sort | Calculated quantity for all active sales agreements for this account in the current period. Calculated on pro-rata basis if SA period does not coincide with forecast display period |
| SalesAgreementPlannedRevenue | double | Filter, Nillable, Sort | Calculated revenue for all active sales agreements for this account in the current period. Calculated on pro-rata basis |
| StartDate | date | Filter, Group, Nillable, Sort | Date on which the period starts |

---

### AcctMgrTarget — Complete Field Reference

**API Version:** 49.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Associated Objects:** AcctMgrTargetChangeEvent (API v62.0+), AcctMgrTargetFeed, AcctMgrTargetHistory, AcctMgrTargetShare

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AssignedTargetPercentage | percent | Create, Filter, Nillable, Sort, Update | The percentage of the parent account manager target value assigned to a team member |
| AssignedToUserId | reference | Create, Filter, Group, Sort, Update | The ID of a user who has been assigned an account manager target |
| EndDate | date | Create, Filter, Group, Nillable, Sort, Update | Populated based on the end date of the selected fiscal year. Read-only field |
| FiscalYearId | reference | Create, Filter, Group, Nillable, Sort, Update | The ID of the fiscal year selected for an account manager target. Read-only field |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The timestamp for when a user last referenced an account manager target record |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The timestamp for when a user last viewed an account manager target record |
| Measure | picklist | Create, Defaulted on create, Filter, Group, Sort, Update | The measure of an account manager target. Can be a custom value but must map to a predefined measure type. Default: `Revenue` |
| MeasureType | picklist | Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort | Predefined measure types. Values: `Currency` (default), `Other` |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | The user-defined name of an account manager target |
| OwnerId | reference | Create, Defaulted on create, Filter, Group, Sort, Update | The ID of a user who owns an account manager target record |
| ParentAcctMgrTargetId | reference | Create, Filter, Group, Nillable, Sort, Update | The ID of the parent account manager target |
| StartDate | date | Create, Filter, Group, Nillable, Sort, Update | Populated based on the start date of the fiscal year |
| TargetCurrencyValue | currency | Create, Filter, Nillable, Sort, Update | The value of an account manager target with measure type Currency |
| TargetValue | double | Create, Filter, Nillable, Sort, Update | The value of an account manager target with measure type Other |
| TeamMemberHierarchyType | picklist | Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort | Hierarchy type of team members for target assignments. Values: `ForecastsHierarchy`, `ManagerHierarchy` (default) |

---

### AcctMgrTargetDstr — Complete Field Reference

**API Version:** 49.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Associated Objects:** AcctMgrTargetDstrChangeEvent (API v62.0+), AcctMgrTargetDstrHistory

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountId | reference | Create, Filter, Group, Nillable, Sort, Update | ID of the account selected for an account manager target distribution |
| AcctMgrTargetId | reference | Create, Filter, Group, Sort | The ID of an account manager target |
| AssignedTargetPercentage | percent | Create, Filter, Nillable, Sort, Update | The percentage of the parent account manager target value assigned to a team member |
| ListPrice | currency | Create, Filter, Nillable, Sort, Update | The list price of a product selected for distribution |
| Name | string | Autonumber, Defaulted on create, Filter, idLookup, Sort | The user-defined name of an account manager target |
| PricebookEntryId | reference | Create, Filter, Group, Nillable, Sort, Update | The ID of a product in relation to the price book selected for distribution |
| PricebookId | reference | Create, Filter, Group, Nillable, Sort, Update | The ID of the price book selected for distribution by product |
| ProductId | reference | Create, Filter, Group, Nillable, Sort, Update | The ID of a product selected for distribution |
| TargetCurrencyValue | currency | Create, Filter, Nillable, Sort, Update | The distribution value with measure type Currency |
| TargetValue | double | Create, Filter, Nillable, Sort, Update | The distribution value with measure type Other |

---

### AcctMgrPeriodicTargetDstr — Complete Field Reference

**API Version:** 49.0 and later

**Supported Calls:** describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), update()

**Associated Objects:** AcctMgrPeriodicTargetDstrHistory

**Note:** Has twelve period ID fields (Period1Id–Period12Id) and twelve corresponding value pairs (TargetCurrencyValue and TargetValue) per period.

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AcctMgrTargetDstrId | reference | Filter, Group, Nillable, Sort, Update | The ID of an AcctMgrTargetDstr object. Relationship: AcctMgrTargetDstr |
| AcctMgrTargetId | reference | Filter, Group, Sort | The ID of an account manager target. Master-detail relationship → AcctMgrTarget |
| FiscalPeriodId | reference | Filter, Group, Nillable, Sort, Update | The ID of the fiscal year for an account manager target. Relationship → Period |
| LastReferencedDate | dateTime | Filter, Nillable, Sort | The timestamp when the current user last accessed this record |
| LastViewedDate | dateTime | Filter, Nillable, Sort | The timestamp when the current user last viewed this record |
| Name | string | Autonumber, Defaulted on create, Filter, idLookup, Sort | The user-defined name of an account manager target |
| Period1Id–Period12Id | reference | Filter, Group, Nillable, Sort, Update | The ID of the 1st through 12th period of the distribution. Each relationship → Period |
| Period1TargetCurrencyValue–Period12TargetCurrencyValue | currency | Filter, Nillable, Sort, Update | The value of each period with measure type Currency |
| Period1TargetValue–Period12TargetValue | double | Filter, Nillable, Sort, Update | The value of each period with measure type Other |

---

### AcctMgrTargetMeasure — Complete Field Reference

**API Version:** 49.0 and later

**Supported Calls:** describeSObjects(), query(), retrieve()

This is a dynamic picklist table referenced in AcctMgrTarget.

| Field Name | Type | Properties | Description |
|---|---|---|---|
| ApiName | string | Filter, Group, idLookup, Sort | The API name of the measure type |
| IsDefault | boolean | Defaulted on create, Filter, Group, Sort | Specifies whether the measure type is Currency (false) or Other (true). Default: false |
| MasterLabel | string | Filter, Group, Nillable, Sort | The name of the account manager target |
| MeasureType | picklist | Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort | Values: `Currency`, `Other` |
| SortOrder | int | Filter, Group, Nillable, Sort | The order of sorting the values in AcctMgrTargetMeasure |

---

### AdvAccountForecastSet — Complete Field Reference

**API Version:** 53.0 and later

**Supported Calls:** (standard create/delete/query/retrieve/update/upsert — see AdvAccountForecastSet documentation)

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountFieldName | picklist | Create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The field name for the account in the advanced account forecast fact record. Values include `AccountId`, `AdvAcctForecastSetPartnerId`, `AdvAcctForecastSetUseId`, `ManufacturingProgramId`, etc. |
| CalculationFrequency | picklist | Create, Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The frequency at which the forecast set is recalculated automatically. Values: `Monthly` (default), `Quarterly`, `Weekly`, `Yearly` |
| Description | textarea | Create, Filter, Group, Nillable, Sort, Update | The description of the advanced account forecast set record |
| DeveloperName | string | Create, Filter, Group, Sort, Update | The name of the advanced account forecast set record |
| ForecastFactObjectName | picklist | Create, Filter, Group, Restricted picklist, Sort, Update | The API name of the object used to store the forecast facts. Values: `AdvAccountForecastFact`, `MfgProgramCpntFrcstFact`, `MfgProgramForecastFact`, `MfgProgramVariantFrcstFact` |
| ForecastPeriodGroupId | reference | Create, Filter, Group, Sort, Update | The forecast period group associated with the forecast set. Relationship → AdvAcctForecastPeriodGroup |
| ForecastQuantityFieldName | picklist | Create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The field name for the forecast quantity in the advanced account forecast fact record. Extensive list of possible values including AdjustedForecastedQuantity, ForecastedQuantity, ProgramQuantity, SalesAgreementQuantity, etc. |
| ForecastRevenueFieldName | picklist | Create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The field name for the forecast revenue in the advanced account forecast record. Same values as ForecastQuantityFieldName |
| ForecastSetFieldName | picklist | Create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The name of the field used to store the forecast set and fact object relation. Values: `AdvAcctForecastSetPartnerId`, `AdvAcctForecastSetUseId`, `ManufacturingProgramId` |
| ForecastSetName | string | Create, Filter, Group, idLookup, Sort, Update | The name of the forecast set |
| ForecastStatusFieldName | picklist | Create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The field name for the Status in the advanced account forecast fact record. Values: `CurrencyIsoCode`, `ExternalReferenceNumber`, `Name`, `Status` |
| GenerationDpeDefNameId | reference | Create, Filter, Group, Nillable, Sort, Update | The Data Processing Engine definition used to generate advanced account forecast fact records. Relationship → BatchCalcJobDefinition |
| Language | picklist | Create, Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The combined language and locale ISO code |
| MasterLabel | string | Create, Filter, Group, Sort, Update | Label for this advanced account forecast set value. Internal label not translated |
| NamespacePrefix | string | Filter, Group, Nillable, Sort | The namespace prefix. Available in API version 58.0 and later |
| PeriodFieldName | picklist | Create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The field name for the period in the advanced account forecast fact record. Values: `PeriodId` |
| RecalculateDpeDefNameId | reference | Create, Filter, Group, Nillable, Sort, Update | The Data Processing Engine definition used to recalculate advanced account forecast fact records. Relationship → BatchCalcJobDefinition |
| RegenerationDpeDefNameId | reference | Create, Filter, Group, Nillable, Sort, Update | The Data Processing Engine definition used to regenerate advanced account forecast fact records. Relationship → BatchCalcJobDefinition |
| RolloverDpeDefNameId | reference | Create, Filter, Group, Nillable, Sort, Update | The Data Processing Engine definition used to generate rollover advanced account forecast fact records. Relationship → BatchCalcJobDefinition |
| RolloverFrequency | picklist | Create, Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The frequency of rollover of the advanced account forecast records. Values: `Monthly` (default), `Quarterly`, `Weekly`, `Yearly` |
| Status | picklist | Create, Filter, Group, Restricted picklist, Sort, Update | The status of the advanced account forecast set. Values: `Active`, `Inactive` |

---

### AdvAcctForecastSetPartner — Complete Field Reference

**API Version:** 53.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountId | reference | Create, Filter, Group, Sort, Update | The account that uses the forecast set for generating advanced account forecast records. Relationship: Account (Lookup) |
| AdvAccountForecastSetId | reference | Create, Filter, Group, Sort, Update | The forecast set associated with the account. Relationship: AdvAccountForecastSet (Lookup) |
| ExternalReferenceNumber | string | Create, Filter, Group, idLookup, Nillable, Sort, Update | The reference number used to associate the account forecast set partner with the account forecast fact records |
| LastCalculationDate | date | Create, Filter, Group, Nillable, Sort, Update | The date when advanced account forecast values were last calculated for the associated account and forecast set |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | Name of the record |
| Status | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | Status of the advanced account forecast set partner record. Values: `Active`, `Draft`, `Inactive`. Default: `Active`. Note: if partner record is inactive, you cannot edit the corresponding forecast fact records |

---

### AdvAcctForecastSetUse — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdvAccountForecastSetId | reference | Create, Filter, Group, Sort, Update | The forecast set associated with the account. Relationship: AdvAccountForecastSet (Lookup) |
| ExternalReferenceNumber | string | Create, Filter, Group, idLookup, Nillable, Sort, Update | The reference number of the manufacturing program record used to associate it with the account forecast fact records |
| ForecastContextId | reference | Create, Filter, Group, Sort, Update | The object whose record is used as the context for generating forecasts. Polymorphic relationship → Account, ManufacturingProgram |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | Name of the advanced account forecast use record |
| Status | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | Status of the advanced account forecast set partner record. Values: `Active`, `Approved`, `Canceled`, `Draft`, `Inactive`, `Rejected`, `SubmittedForApproval`. Default: `Active` |

---

### ManufacturingProgram — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AccountId | reference | Create, Filter, Group, Nillable, Sort, Update | The account for which the manufacturing program is created. Relationship: Account (Lookup) |
| Description | string | Create, Filter, Group, Nillable, Sort, Update | The description of the manufacturing program |
| EndDate | date | Create, Filter, Group, Nillable, Sort, Update | The end date of the manufacturing program |
| ExternalName | string | Create, Filter, Group, Nillable, Sort, Update | The name used for the manufacturing program by external organizations |
| ManufacturingProgramTemplateId | reference | Create, Filter, Group, Nillable, Sort, Update | The template used for the manufacturing program. Relationship: ManufacturingProgramTemplate (Lookup → MfgProgramTemplate) |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | The name of the manufacturing program record |
| ProgramType | picklist | Create, Filter, Group, Nillable, Sort, Update | Specifies the type of manufacturing program |
| RelatedManufacturingProgramId | reference | Create, Filter, Group, Nillable, Sort, Update | Another manufacturing program associated with the manufacturing program. Relationship: RelatedManufacturingProgram (Lookup → ManufacturingProgram) |
| StartDate | date | Create, Filter, Group, Nillable, Sort, Update | The start date of the manufacturing program |
| Status | picklist | Create, Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort, Update | The status of the manufacturing program. Values: `Active`, `Draft`, `Inactive`. Default: `Draft` |

---

### MfgProgramForecastFact — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdjustedForecastedQuantity | double | Create, Filter, Nillable, Sort, Update | The adjusted value of the forecasted quantity |
| AdjustedForecastedRevenue | currency | Create, Filter, Nillable, Sort, Update | The adjusted value of the forecasted revenue |
| AdvAcctForecastSetUseId | reference | Create, Filter, Group, Nillable, Sort, Update | The advanced account forecast set context associated with this forecast fact record. Relationship → AdvAcctForecastSetUse |
| ExpectedRevenuePerUnit | currency | Create, Filter, Nillable, Sort, Update | The expected revenue per unit of the product |
| ExternalReferenceNumber | string | Create, Filter, Group, idLookup, Nillable, Sort, Update | The external identifier for the manufacturing program forecast fact record |
| ForecastedQuantity | double | Create, Filter, Nillable, Sort, Update | The forecasted quantity calculated by multiplying product quantity with market share percentage |
| ForecastedRevenue | currency | Create, Filter, Nillable, Sort, Update | The forecasted revenue calculated by multiplying forecasted quantity with market share percentage |
| ManufacturingProgramId | reference | Create, Filter, Group, Nillable, Sort, Update | The manufacturing program associated with this forecast fact record. Relationship → ManufacturingProgram |
| MarketSharePercent | percent | Create, Filter, Nillable, Sort, Update | The market share of the total number of product units in percent |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | The name of the manufacturing program forecast fact record |
| PeriodId | reference | Create, Filter, Group, Sort, Update | The calendar period associated with this forecast fact record. Relationship → Period |
| PeriodStartDate | date | Filter, Group, Nillable, Sort | The start date of the period for which the forecast fact records are generated |
| PreviousPeriodProgramQuantity | double | Create, Filter, Nillable, Sort, Update | The product quantity in the previous period |
| ProductionLocationId | reference | Create, Filter, Group, Nillable, Sort, Update | The production location of the account. Relationship → Location |
| ProductionModelId | reference | Create, Filter, Group, Nillable, Sort, Update | The production model associated with this forecast fact record. Relationship → Product2 |
| ProgramQuantity | double | Create, Filter, Nillable, Sort, Update | The total number of units of the product manufactured as part of the program |
| Status | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | Status of the manufacturing program forecast fact record. Values: `Active`, `Inactive`. Default: `Inactive` |

---

### MfgProgramCpntFrcstFact — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdjustedForecastedQuantity | double | Create, Filter, Nillable, Sort, Update | The adjusted value of the forecasted quantity |
| AdjustedForecastedRevenue | currency | Create, Filter, Nillable, Sort, Update | The adjusted value of the forecasted revenue |
| AdvAcctForecastSetUseId | reference | Create, Filter, Group, Nillable, Sort, Update | The advanced account forecast set context. Relationship → AdvAcctForecastSetUse |
| CostUnitOfMeasurementId | reference | Create, Filter, Group, Nillable, Sort, Update | Relationship → UnitOfMeasure |
| ExpectedProfitPerUnit | currency | Create, Filter, Nillable, Sort, Update | The expected profit per unit from the product variant component |
| ExpectedProfitPercent | percent | Create, Filter, Nillable, Sort, Update | The expected profit from the product variant component in percent |
| ExternalReferenceNumber | string | Create, Filter, Group, idLookup, Nillable, Sort, Update | The external identifier for this record |
| ForecastedQuantity | double | Create, Filter, Nillable, Sort, Update | The forecasted quantity calculated by multiplying the forecasted quantity of the associated manufacturing program with the number of component units per product variant unit |
| ForecastedRevenue | currency | Create, Filter, Nillable, Sort, Update | The forecasted revenue from the product variant component |
| ManufacturingProgramId | reference | Create, Filter, Group, Nillable, Sort, Update | The manufacturing program associated with this record. Relationship → ManufacturingProgram |
| Name | string | Create, Filter, Group, idLookup, Sort, Update | The name of the Manufacturing Program Component Forecast Fact record |
| PeriodId | reference | Create, Filter, Group, Sort, Update | The period associated with this record. Relationship → Period |
| PeriodStartDate | date | Filter, Group, Nillable, Sort | The start date of the period for which the records are generated |
| ProductComponentId | reference | Create, Filter, Group, Nillable, Sort, Update | The component of the product variant. Relationship → Product2 |
| ProductId | reference | Create, Filter, Group, Nillable, Sort, Update | The manufacturing program product associated with this record. Relationship → Product2 |
| ProductionLocationId | reference | Create, Filter, Group, Nillable, Sort, Update | The production location of the account. Relationship → Location |
| ProductionModelId | reference | Create, Filter, Group, Nillable, Sort, Update | The model associated with this record. Relationship → Product2 |
| SellingPricePerUnit | currency | Create, Filter, Nillable, Sort, Update | The selling price of a unit of the product variant component |
| Status | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | Status of this record. Values: `Active`, `Inactive`. Default: `Inactive` |
| TotalCostPerUnit | currency | Create, Filter, Nillable, Sort, Update | The total cost of a unit (total fixed cost per unit + variable cost per unit) |
| TotalFixedCostPerUnit | double | Create, Filter, Nillable, Sort, Update | The total fixed cost of a unit of the product variant component |
| VariableCostPerUnit | currency | Create, Filter, Nillable, Sort, Update | The variable cost of a unit of the product variant component |

---

### MfgProgramTemplate — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeSObjects(), query(), retrieve(), update(), upsert()

**Associated Objects:** MfgProgramTemplateFeed, MfgProgramTemplateHistory, MfgProgramTemplateOwnerSharingRule, MfgProgramTemplateShare

| Field Name | Type | Properties | Description |
|---|---|---|---|
| Description | string | Create, Filter, Group, Nillable, Sort, Update | The description of the manufacturing program template |
| ProgramTemplateName | string | Create, Filter, Group, idLookup, Sort, Update | The unique identifier for the manufacturing program template |
| Status | picklist | Create, Defaulted on create, Filter, Group, Restricted picklist, Sort, Update | Status of the template. Values: `Active`, `Draft`, `Inactive`. Default: `Active` |

---

### MfgProgramTemplateItem — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeSObjects(), query(), retrieve(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdvAccountForecastSetId | reference | Create, Filter, Group, Nillable, Sort, Update | The forecast set associated with the transformation. Relationship → AdvAccountForecastSet |
| ContextDefinition | string | Create, Filter, Group, Nillable, Sort, Update | The context definition that defines how data is mapped and transformed to the target object |
| Description | string | Create, Filter, Group, Nillable, Sort, Update | The description of the manufacturing program template item |
| MfgProgramTemplateId | reference | Create, Filter, Group, Sort | The manufacturing program template associated with the template item. Relationship → MfgProgramTemplate |
| SourceContextMappingName | string | Create, Filter, Group, Nillable, Sort, Update | The context mapping that defines how data is mapped from a list of facts (Input Data) to create structured information |
| TargetContextMappingName | string | Create, Filter, Group, Nillable, Sort, Update | The context mapping that defines how the structured data is saved to the target object |
| TemplateItemName | string | Create, Filter, Group, Sort, Update | The name of the manufacturing program template item |
| TransformationDisplayOrder | int | Create, Filter, Group, Sort, Update | The display order of the transformation in the manufacturing program template |
| TransformationType | picklist | Create, Filter, Group, Restricted picklist, Sort, Update | Type of transformation. Values: `BusinessTransformation`, `ForecastSetRelation` |

---

### MfgPgmCpntFrcstFactOpptySchd — Complete Field Reference

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeSObjects(), query(), retrieve(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| ManufacturingProgramComponentForecastFact | reference | Create, Filter, Group, Sort | Represents information about the generated manufacturing program forecast records |
| OpportunityLineItemSchedule | reference | Create, Filter, Group, Sort | Represents the opportunity line item schedule. Relationship → OpportunityLineItemSchedule |
| OpportunityLineItem | reference | Create, Filter, Group, Sort | Represents an opportunity line item associated with an Opportunity. Relationship → OpportunityLineItem |
| Opportunity | reference | Create, Filter, Group, Sort | Represents an opportunity. Relationship → Opportunity |
| Product | reference | Create, Filter, Group, Sort | Represents the Product on the fact being converted to Opportunity Line Item. Relationship → Product2 |

---

### AdvAcctForecastAdjPeriod — Complete Field Reference

**API Version:** 53.0 and later

**Supported Calls:** create(), delete(), describeSObjects(), query(), retrieve(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdjustmentDayCount | int | Create, Filter, Group, Sort, Update | The number of days during which forecast adjustments can be made |
| AdvAccountForecastSetId | reference | Create, Filter, Group, Sort | The forecast set associated with the adjustment period. Relationship → AdvAccountForecastSet |
| Frequency | picklist | Create, Filter, Group, Restricted picklist, Sort, Update | How frequently the adjustment windows will open. Values: `Month`, `Quarter`, `Year` |
| ProfileId | reference | Create, Filter, Group, Nillable, Sort, Update | The profile with which the forecast set can be adjusted. Relationship → Profile |
| StartDay | int | Create, Filter, Group, Sort, Update | The day when forecast adjustments can begin |

### SalesAgreementProduct
Represents the total quantity/amount and default pricing of a product or category across the total time period of the sales agreement. Available in API version 47.0 and later.

**Key Fields:**

| Field | Type | Description |
|---|---|---|
| Name | string | Name of the agreement product |
| SalesAgreementId | reference | Parent sales agreement |
| PricebookEntryId | reference | Price book entry for the product |
| InitialPlannedQuantity | double | Initial planned quantity |
| TotalPlannedQuantity | double | Total planned quantity across all schedules |
| TotalActualQuantity | double | Total actual quantity across all schedules |

**Associated Objects:** SalesAgreementProductHistory, SalesAgreementProductChangeEvent

### SalesAgreementProductSchedule
Represents the quantity/amount and pricing information for a product for a particular schedule period. Available in API version 47.0 and later.

**Key Fields:**

| Field | Type | Description |
|---|---|---|
| SalesAgreementProductId | reference | Parent sales agreement product |
| StartDate | date | Start date of this schedule period |
| PlannedQuantity | double | Planned quantity for this period |
| ActualQuantity | double | Actual quantity for this period |
| SalesPrice | currency | Sales price for this period |

**Associated Objects:** SalesAgreementProductScheduleHistory

### SalesAgreementProdSchdAdj
Represents manual adjustments made to metric values for a sales agreement product schedule. Available in API version 47.0 and later.

### SalesAgreeProductAttribute
Represents a virtual object storing key-value pairs for attributes of sales agreement products. Available in API version 60.0 and later.

### SalesContractLine
Stores a contract's product information, including price, quantity, and components covered. Available in API version 59.0 and later.

---

## Domain 2: Account Forecasting (Standard)

### AccountForecast
Represents the rolling forecast record of a particular account. Prepared using data from sales agreements, orders, and opportunities. Available in API version 47.0 and later.

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Key Fields:**

| Field | Type | Description |
|---|---|---|
| AccountId | reference | ID of the account for which forecast is generated |
| DefaultAccountGrowthPercentage | percent | Default account growth metric for first-time calculation. Default: 0 |
| DefaultMarketGrowthPercentage | percent | Default market growth metric for first-time calculation. Default: 0 |
| EndDate | date | Date through which forecast is generated. Note: must be null for active forecasts; cannot be updated |
| LastCalculatedDate | dateTime | Date on which forecast was last calculated (auto or manual) |
| Name | string | Name of the account forecast record |
| OwnerId | reference | Account owner. Note: only account owner can create the forecast record |
| StartDate | date | Date from which forecast is generated. Created automatically in active status |
| Status | picklist | Status: `Active`, `Expired`. Note: only 1 active forecast per account; must expire existing before creating new; cannot change from Expired to Active |
| TotalAdjustedRevenue | double | Total revenue after manual adjustments |
| TotalRevenue | double | Total calculated revenue |

**Associated Objects:** AccountForecastChangeEvent (API v62.0+)

**Constraints:**
- There can be only 1 active account forecast at any time per account.
- An existing account forecast must be expired before creating a new one.
- Active account forecast records must be expired before deleting them.
- You cannot change Status from Expired to Active.
- EndDate of an active account forecast must be null and cannot be updated.
- Only the account owner can create the account forecast record.

### AccountForecastAdjustment
Represents manual adjustments made to forecast values for a particular account. Available in API version 47.0 and later.

**Supported Calls:** describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search()

**Key Fields:**

| Field | Type | Description |
|---|---|---|
| AccountProdPeriodForecastId | reference | Parent AccountProductPeriodForecast record |
| AdjustedForecastQuantity | double | Manually adjusted forecast quantity |
| AdjustedForecastRevenue | double | Manually adjusted forecast revenue |
| AdjustmentNote | textarea | Notes on the adjustment |

### AccountForecastPeriodMetric
Represents records of account metrics that vary by period but are not specific to a product. Available in API version 47.0 and later.

### AccountProductForecast
Represents the cumulative values for planned quantities, opportunities, and orders of a sales agreement for a given product across all periods in the rolling time period. Available in API version 47.0 and later.

### AccountProductPeriodForecast
Represents the quantity and revenue information of opportunities, sales agreements, orders, and resultant forecasted quantities for a product in a particular time period.

**Important:** Other than the fields `AdjustedForecastQuantity` and `AdjustedForecastRevenue`, no other fields of this object can be updated. Available in API version 47.0 and later.

---

## Domain 3: Advanced Account Forecasting

### AdvAccountForecastSet
Represents a collection of fields to set up an advanced account forecast set. Available in API version 53.0 and later.

### AdvAcctForecastSetPartner
Represents a junction between an advanced account forecast set and an account. Status can be: `Draft`, `Active`, `Inactive`. Available in API version 53.0 and later.

### AdvAcctForecastSetUse
Represents a junction between an advanced account forecast set and another object whose record serves as the context for generating forecasts (e.g., a ManufacturingProgram or a Sustainability Cloud object). Available in API version 55.0 and later.

### AdvAccountForecastFact
Represents information about the generated advanced account forecast records. Available in API version 53.0 and later.

### AdvAcctForecastFactAdj
Represents information about adjustments made to advanced account forecast fact records. Available in API version 53.0 and later.

### AdvAcctForecastMeasureDef
Represents information about the measures to be displayed in the advanced account forecasts grid for the forecast set. Available in API version 53.0 and later.

### AdvAccountForecastPeriod
Represents information about the periods for which advanced account forecasting is applied. Available in API version 53.0 and later.

### AdvAcctForecastPeriodGroup
Represents information about advanced account forecast period records. This is the parent object of all related advanced account forecast period records. Available in API version 53.0 and later.

### AdvAcctForecastDimension
Represents information about the dimensions selected for an advanced account forecast set. Available in API version 53.0 and later.

### AdvAcctForecastDimSource
Represents information about the dimensions that can be used by advanced account forecast sets to generate advanced account forecast records. Available in API version 53.0 and later.

### AdvAcctFrcstDisplayGroup
Represents information about the groups for the advanced account forecast set measures or dimensions. Available in API version 54.0 and later.

### AdvAcctFrcstDplyGroupItem
Represents information about the items associated with a display group for an advanced account forecast set. Available in API version 54.0 and later.

### AdvAcctForecastAdjPeriod
Represents details about the adjustment period of the advanced account forecast values. Available in API version 53.0 and later.

---

## Domain 4: Account Manager Targets

### AcctMgrTarget
Represents a target created by an account manager. Stores fiscal year, measure, target value, start date, end date, and assignment information. Available in API version 49.0 and later.

**Associated Objects:** AcctMgrTargetHistory, AcctMgrTargetShare, AcctMgrTargetFeed, AcctMgrTargetChangeEvent

### AcctMgrTargetDstr
Represents the account, product, and price book associated with an account manager target. Child of AcctMgrTarget. Available in API version 49.0 and later.

**Associated Objects:** AcctMgrTargetDstrHistory, AcctMgrTargetDstrChangeEvent

### AcctMgrPeriodicTargetDstr
Represents the target value of each period of an account manager target. Has twelve fields for periods and twelve corresponding fields to hold the target value. Child of either AcctMgrTarget or AcctMgrTargetDstr. Available in API version 49.0 and later.

**Associated Objects:** AcctMgrPeriodicTargetDstrHistory

### AcctMgrTargetMeasure
Represents the type of measure for an account manager target. This object is a dynamic picklist table referenced in account manager target. Available in API version 49.0 and later.

---

## Domain 5: Program-Based Business

### ManufacturingProgram
Represents information about a manufacturing program (e.g., a program for a specific account to manufacture components for a concept vehicle). Available in API version 55.0 and later.

### MfgProgramTemplate
Represents information about the templates associated with a manufacturing program. Available in API version 55.0 and later.

### MfgProgramTemplateItem
Represents information about the transformation type associated with a manufacturing program template. Available in API version 55.0 and later.

### MfgProgramForecastFact
Represents information about the generated manufacturing program forecast records. Available in API version 55.0 and later.

### MfgProgramCpntFrcstFact
Represents information about the generated manufacturing program component forecast records. Available in API version 55.0 and later.

### MfgPgmCpntFrcstFactOpptySchd
Represents a junction between the forecast and opportunity line item schedule objects, providing details on the relationship between forecast data and corresponding sales order schedules. Available in API version 55.0 and later.

### MfgProgramVariantFrcstFact
Represents information about the generated manufacturing program product variant forecast records. Available in API version 55.0 and later.

---

## Domain 6: Warranty Lifecycle Management

### WarrantyTerm
Represents warranty terms defining labor, parts, and expenses covered, along with exchange options, provided to rectify issues with products. Available in Manufacturing Cloud in API version 55.0 and later.

### AssetWarranty
Defines the warranty terms applicable to an asset along with any exclusions and extensions. Available in Manufacturing Cloud in API version 55.0 and later.

### ProductWarrantyTerm
Defines the relationship between a product or product family and a warranty term. Available in Manufacturing Cloud in API version 55.0 and later.

### WarrantyTermCoverage
Represents a junction between the warranty term coverage and a product or codeset (such as repair code or labor code). Available in API version 58.0 and later.

### Claim
Represents a warranty Claim submitted by a partner to a manufacturer, or a supplier recovery claim submitted by the manufacturer to a supplier. Available in Manufacturing Cloud in API version 58.0 and later.

### ClaimItem
Represents a defective asset that requires repair or replacement. Available in Manufacturing Cloud in API version 58.0 and later.

### ClaimCoverage
Represents a causal part in a defective asset that requires repair or replacement. Available in Manufacturing Cloud in API version 58.0 and later.

### ClaimCoveragePaymentDetail
Represents the claim coverage amount that must be paid to a claimant for a part replaced or a labor service performed to rectify a causal part in a defective asset. Available in Manufacturing Cloud in API version 58.0 and later.

### ClaimParticipant
A junction object that associates the Claim object with the Account object. Represents the participants of a claim. Available in Manufacturing Cloud in API version 58.0 and later.

---

## Domain 7: Product Service Campaigns

### ProductServiceCampaign
Represents a set of activities to be performed for a product service campaign (e.g., product recall or safety upgrade). Available in API version 61.0 and later.

### ProductServiceCampaignItem
Represents an item (asset or serialized product) included in a product service campaign. Available in API version 61.0 and later.

### ProductSvcCampaignDef
Represents information about the product or part that is impacted in a product service campaign. Available in API version 65.0 and later.

### ProductSvcCampaignGrpDef
Represents information about product service campaign definitions within groups based on attributes. Available in API version 65.0 and later.

### ProdtSvcCmpnGrpDefCausalItm
Represents information about the impacted item that caused the service campaign to be initiated. Available in API version 65.0 and later.

### ProdtSvcCmpnGrpDefPtnr
Represents information about the coordinating partner for a product service campaign. Available in API version 65.0 and later.

### ProdtSvcCmpnDefPtnrInv
Represents information about the partner-held inventory of items impacted by a product service campaign. Available in API version 65.0 and later.

### ProdtSvcCmpnDefRelaCausalItm
Represents information about the cause associated with a product service campaign definition. Available in API version 65.0 and later.

### ProdtSvcCmpnPreferredPartner
Represents information about the most appropriate partner to execute a product service campaign within a geographic area. Available in API version 65.0 and later.

### ProdtSvcCmpnWorkType
Represents information about the eligible work types that can be associated with a product service campaign. Available in API version 65.0 and later.

---

## Domain 8: Field Service and Inventory Management

### ProductItem
Represents the stock of a product at a particular inventory location (warehouse, distribution lot). Available in API version 60.0 and later.

### ProductItemTransaction
Represents an action taken on a product item (consumed, replenished, adjusted, transferred). Auto-generated records. Available in API version 60.0 and later.

### ProductTransfer
Represents the transfer or movement of a product item between two inventory locations. Available in API version 60.0 and later.

### ProductTransferState
Represents an action taken to associate a serialized product with a product transfer. Available in API version 60.0 and later.

### ProductRequest
Represents a request or order for products to and from specific inventory locations. Available in API version 60.0 and later.

### ProductRequestLineItem
Represents a product requested as part of a product request. Available in API version 60.0 and later.

### ProductRequired
Represents a product needed to complete a work order or work order line item. Available in API version 60.0 and later.

### ProductConsumed
Represents an item from product inventory used to complete a work order or work order line item. Available in API version 60.0 and later.

### ProductConsumedState
Represents an action taken to associate a serialized product with a product transfer. Available in API version 60.0 and later.

### SerializedProduct
Records serial numbers for each product in an inventory. Available in API version 60.0 and later.

### SerializedProductTransaction
Represents a change in the state of a serialized product. Available in API version 60.0 and later.

### Shipment
Represents a product item that is in transit between two inventory locations. Available in API version 60.0 and later.

### ShipmentItem
Represents a product included in a shipment. Available in API version 60.0 and later.

### ReturnOrder
Represents the repair, return, or recall of product items. Available in API version 60.0 and later.

### ReturnOrderLineItem
Represents a product returned, recalled, or repaired as part of a return order. Available in API version 60.0 and later.

---

## Domain 9: Supplier and Purchase Order Management

### Supplier
Represents information about a supplier that a manufacturer procures product parts and components from. Available in API version 59.0 and later.

### SupplierProduct
Represents information about a product procured from a supplier. Available in API version 59.0 and later.

### PurchaseOrder
Represents the Purchase Order entity capturing a formal request from a Buyer to a Supplier to supply goods or services. Identified by a unique PurchaseOrderNumber. Tracks lifecycle via StatusCode. Available in API version 65.0 and later.

### PurchaseOrderItem
Represents an individual line on a parent Purchase Order detailing a specific product or service being procured. Captures Quantity, UnitPrice, Product reference, and LineTotal. Available in API version 65.0 and later.

### GoodsReceivedNote
Represents a record created by the buyer to confirm delivery of goods from a supplier. Used to verify received items match the purchase order. Available in API version 65.0 and later.

### GoodsReceivedNoteItem
Represents a single line entry on the Goods Received Note (GRN) that details the receiving status of a specific product. Records total quantity received and indicates damaged, short-delivered, or excess units. Available in API version 65.0 and later.

---

## Domain 10: Inventory Count and Replenishment

### InventoryCountPlan
Represents a plan to count inventory at a location. Available in API version 63.0 and later.

### InventoryCountPlanItem
Represents a product in an inventory plan. Child of InventoryCountPlan. Available in API version 63.0 and later.

### InventoryCountAssessment
Represents an inventory count performed at a location. Available in API version 63.0 and later.

### InventoryCountProductItem
Represents the inventory count of a product at a location. Child of InventoryCountAssessment. Available in API version 63.0 and later.

### InventoryCntProdtBatchItem
Represents the inventory count of a batch of a product at a location. Available in API version 55.0 and later.

### InventoryCntSerializedProdt
Represents a serialized product in an inventory count. Available in API version 63.0 and later.

### InventoryReplenishmentPolicy
Represents a policy for replenishing inventory when the inventory quantity reaches a minimum level. Available in API version 63.0 and later.

---

## Domain 11: Visit Management

### Visit
Represents information about a visit that a manager schedules for a field rep, usually at distributor, supplier, and partner locations. Available in API version 56.0 and later.

### GenericVisitTask
Represents information about a task that can be performed during a visit. Available in Manufacturing Cloud in API version 56.0 and later.

### GenericVisitTaskContext
Represents the context or purpose for a generic visit task. Available in Manufacturing Cloud in API version 56.0 and later.

### GnrcVstTaskContextRelation
Represents common attributes used for a visit task and a visit task context. Available in Manufacturing Cloud in API version 56.0 and later.

### GnrcVstKeyPerformanceInd
Represents the key performance indicators that can be recorded while performing a task during a visit. Allows comparison of expected and actual metric values. Available in Manufacturing Cloud in API version 56.0 and later.

---

## Domain 12: Fleet Management

### Fleet
Represents a group of assets used in commercial, service, or transport operations in the manufacturing industry. Available in API version 59.0 and later.

### FleetAsset
Represents the relationship between an asset and the fleet to which it belongs. Available in API version 59.0 and later.

### FleetParticipant
Represents the relationship between a fleet and a participant (account, contact, or user). Available in API version 59.0 and later.

---

## Domain 13: Asset Lifecycle

### AssetMilestone
Represents the key events in the lifecycle of an asset (manufacturing, registration, resale). Available in API version 58.0 and later.

### AssetAccountParticipant
Represents a junction between the Asset and Account objects describing the association between a participating account and an asset. Available in API version 59.0 and later.

### AssetContactParticipant
Represents a junction between the Asset and Contact objects describing the association between a participating contact and an asset. Available in API version 59.0 and later.

---

## Domain 14: Code Sets

### CodeSet
Represents various industry-defined codes in the context of their systems and versions. Available in Manufacturing Cloud in API version 58.0 and later.

### CodesetRelationship
Represents a relationship between a codeset and its related codeset (e.g., a labor code associated with a fault code). Available in Manufacturing Cloud in API version 58.0 and later.

### ProductFaultCode
Represents a relationship between a product or product family and the fault code. Available in API version 58.0 and later.

### ProductLaborCode
Represents a junction between the labor code applicable to a product or product family and the required standard effort. Available in API version 58.0 and later.

---

## Domain 15: Production Batches

### ProductionBatch
Represents the batch of homogeneous products manufactured in the same production line. Available in API version 65.0 and later.

**Associated Objects:** ProductionBatchFeed, ProductBatchItem (change event)

### ProductBatchItem
Represents the details about the product items in each batch. Available in API version 65.0 and later.

**Associated Objects:** ProductBatchItemFeed, ProductBatchItemChangeEvent

---

## Domain 16: Dealer and Partner Lead Management

### LeadPreferredSeller
Represents the relationship between a lead and the dealer account that the lead selects, or the relationship between a lead and the account that provides the lead. Available in API version 65.0 and later.

**Associated Objects:** LeadPreferredSellerChangeEvent

### OpportunityPreferredSeller
Represents the relationship between an opportunity and a dealer account, or between an opportunity and the account that provided the lead from which the opportunity was created. Available in API version 65.0 and later.

**Associated Objects:** OpportunityPreferredSellerChangeEvent

### DealerProdtSearchableField
Represents information about dealers selling and/or servicing products for location-based searches. Helps customers find nearby dealer locations. Available in API version 65.0 and later.

### SellerProduct
Represents information about the products associated with a seller (availability, production details, seller's role for the product). Available in API version 65.0 and later.

---

## Domain 17: Sample Management and Product Requirement Specifications

### SampleRequest
Represents a request for product samples including customer account details, request date, and status. Available in API version 65.0 and later.

### SampleRequestItem
Represents information on items associated with a sample request (product, custom specifications, quantity, price). Available in API version 65.0 and later.

### ProductRqmtSpec
Defines a complete set of requirements. Captures associated Account and Contact, tracks lifecycle status, and acts as parent for all related requirement items and versions. Available in API version 65.0 and later.

### ProductRqmtSpecItem
Represents a specific and measurable requirement within a requirement specification for a requested product. Defines what must be delivered and how to verify its fulfilment. Available in API version 65.0 and later.

### ProductRqmtSpecVersion
Represents a specific, numbered snapshot of a Requirement Specification at a particular time, outlining purpose, scope, constraints, and validation methods. Available in API version 65.0 and later.

---

## Domain 18: Rebates and Stock Rotation

### StockRotationExecution
Represents a stock rotation rebate activity, recording affected inventory and partner information for rebate claim processing. Available in API version 65.0 and later.

### StockRotationExecutionItem
Represents the affected partner inventory in a stock rotation rebate execution, used to determine claim eligibility. Available in API version 65.0 and later.

---

## Domain 19: Engagement Management

### EngagementInteraction
Represents information about an interaction between a service representative and the organization's customer. Can be initiated through communication channels and can cover one or more topics. Available in API version 55.0 and later.

### EngagementAttendee
Represents information about an attendee of an engagement (e.g., customer or service representative). Available in API version 55.0 and later.

### EngagementTopic
Represents information about the topics discussed by a customer and other attendees during an engagement. Available in API version 55.0 and later.

---

## Domain 20: Search Fields

### ProductInvSearchableField
Represents a dataset on inventory information that is the basis for searching product inventory. Contains multiple fields from ProductItem and related objects. Available in API version 62.0 and later.

### ProductInventoryBatchSearchableField
Represents production batch data used for inventory search including batch item details for a specific location. Serves as the basis for Criteria-Based and Filter Search. Available in API version 47.0 and later.

---

## Domain 21: Repair and Diagnosis

### WorkOrderDiagnosis
Represents the diagnosis details of the Work Order that the user records during depot repair.

---

## Manufacturing Cloud Fields on Standard Objects

Manufacturing Cloud adds fields to standard Salesforce objects to manage sales agreements and account forecasts. These fields allow tracking of metrics and data specifically for manufacturing workflows.

**Available in:** Enterprise, Unlimited, and Developer Editions. Requires Manufacturing Cloud enabled.

### Manufacturing Cloud Fields on InventoryItemReservation

**Object Description:** Represents an inventory item reservation for a specific product and location. Available in API version 60.0 and later.

**Special Access Rules:** This object is available only if a B2B Commerce, D2C Commerce, B2C Commerce, or Salesforce Order Management license is enabled.

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Manufacturing Cloud Added Fields:**

| Field | Type | Properties | Description |
|---|---|---|---|
| ProductItemId | reference | Create, Filter, Group, Sort, Update | The product item record specifying the product and location details used in the allocation. Relationship: ProductItem |
| Status | picklist | Create, Filter, Group, Sort, Update | Current state of the inventory item reservation. Values: `Reserved`, `Cancelled`, `Reservation In Progress`, `Cancellation In Progress`, `Fulfilled` |
| ReservationDateTime | dateTime | Create, Filter, Sort | Date and time when the inventory reservation was created. Used for tracking lifecycle and prioritization during sourcing |
| IsAutoReserved | boolean | Create, Defaulted on create, Filter, Update | Whether the reservation was created automatically (true) or manually (false). Default: false |

### Manufacturing Cloud Fields on WorkOrderLineItem

**Object Description:** Represents a subtask on a work order in field service. Available in API version 36.0 and later.

**Special Access Rules:** Work orders or Field Service must be enabled.

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

**Manufacturing Cloud Added Fields:**

| Field | Type | Properties | Description |
|---|---|---|---|
| ProcessType | picklist | Filter, Group, Nillable, Restricted picklist, Sort | Specifies the process type of the work order. Values: `DepotRepair` |

---

## Associated Objects

Manufacturing Cloud standard objects support the following associated object patterns:

### Feed Objects (StandardObjectNameFeed)
Follows the standard Salesforce feed pattern. Objects that have associated Feed objects:
- `AcctMgrTargetFeed`
- `ProductBatchItem` (Feed)
- `ProductionBatch` (Feed)

### History Objects (StandardObjectNameHistory)
Objects that have associated History objects:
- `AcctMgrTargetHistory`
- `AcctMgrTargetDstrHistory`
- `AcctMgrPeriodicTargetDstrHistory`
- `SalesAgreementProductHistory`
- `SalesAgreementProductScheduleHistory`
- `ProductBatchItem` (History)
- `ProductionBatch` (History)

### Share Objects (StandardObjectNameShare)
Objects that have associated Share objects:
- `AcctMgrTargetShare`
- `ProductBatchItem` (Share)
- `ProductionBatch` (Share)

### Change Event Objects (StandardObjectNameChangeEvent)
Objects that support Change Data Capture:
- `AccountForecast` (API v62.0+)
- `AcctMgrTarget`
- `AcctMgrTargetDstr`
- `LeadLineItem`
- `LeadPreferredSeller`
- `OpportunityPreferredSeller`
- `ProductBatchItem`
- `ProductionBatch`
- `SalesAgreement`
- `SalesAgreementProduct`

**Note:** Other Manufacturing Cloud objects (e.g., `AdvAccountForecastFact`, `MfgProgramForecastFact`, `Claim`) do NOT have CDC support.

---

## Additional Standard Object Details

### AdvAcctForecastDimension — Field Reference

**API Version:** 53.0 and later

**Supported Calls:** create(), delete(), describeSObjects(), query(), retrieve(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdvAcctForecastDimName | string | Create, Filter, Group, idLookup, Sort, Update | The name of the dimension |
| AdvAcctForecastDimSourceId | reference | Create, Filter, Group, Sort, Update | The dimension source associated with the forecast set dimension record. Relationship → AdvAcctForecastDimSource |
| AdvAcctForecastSetId | reference | Create, Filter, Group, Sort, Update | The forecast set associated with the dimension. Relationship → AdvAccountForecastSet |
| DimensionFieldName | picklist | Create, Filter, Group, Restricted picklist, Sort, Update | The API name of the field for the dimension in the custom object. Values include `AccountId`, `AdvAccountForecastSetId`, `AdvAcctForecastSetPartnerId`, `ProductId`, `PeriodId`, etc. |

### MfgProgramVariantFrcstFact — Key Fields

**API Version:** 55.0 and later

**Supported Calls:** create(), delete(), describeLayout(), describeSObjects(), getDeleted(), getUpdated(), query(), retrieve(), search(), undelete(), update(), upsert()

| Field Name | Type | Properties | Description |
|---|---|---|---|
| AdjustedForecastedQuantity | double | Create, Filter, Nillable, Sort, Update | The adjusted value of the forecasted quantity |
| AdvAcctForecastSetUseId | reference | Create, Filter, Group, Nillable, Sort, Update | The advanced account forecast set context. Relationship → AdvAcctForecastSetUse |
| ExternalReferenceNumber | string | Create, Filter, Group, idLookup, Nillable, Sort, Update | The external identifier for the manufacturing program variant forecast fact record |
| ForecastedQuantity | double | Create, Filter, Nillable, Sort, Update | The forecasted quantity calculated by multiplying the forecasted quantity of the associated manufacturing program with the variant's market share percentage |
| ManufacturingProgramId | reference | Create, Filter, Group, Nillable, Sort, Update | The manufacturing program associated with this variant forecast fact record. Relationship → ManufacturingProgram |
