---
source: "Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide); mfg_api_devguide.pdf (Spring '26, April 30, 2026)"
cloud: Manufacturing Cloud
section: gotchas
last-updated: 2026-05-10
---

# Manufacturing Cloud — Gotchas, Limitations, and Cautions

This file consolidates all "Important," "Note," "Warning," and "Limitation" callouts from the Manufacturing Cloud Developer Guide, organized by category.

---

## Account Forecast Constraints

### Only One Active Forecast Per Account
There can be only 1 active `AccountForecast` at any time per account. You must expire the existing active forecast before creating a new one. Trying to create a second active forecast for the same account will fail.

### Forecast Status Transitions Are One-Way
You cannot change the Status of an `AccountForecast` from `Expired` to `Active`. The status lifecycle is: `Active` → `Expired` (one direction only).

### Active Forecasts Cannot Be Deleted Directly
Active `AccountForecast` records must be expired before they can be deleted.

### EndDate Restrictions on Active Forecasts
The `EndDate` of an active account forecast:
- Must be `null` (blank) while the forecast is Active.
- Cannot be updated once set.

### AccountProductPeriodForecast Is Nearly Read-Only
Other than the fields `AdjustedForecastQuantity` and `AdjustedForecastRevenue`, **no other fields** of `AccountProductPeriodForecast` can be updated. Attempting to update other fields via API will result in an error.

### AdjustedForecastQuantity and AdjustedForecastRevenue Cannot Be Updated for Past Schedules
Both `AdjustedForecastQuantity` and `AdjustedForecastRevenue` on `AccountProductPeriodForecast` **cannot be updated for past schedules**. Attempts to do so will fail.

### Resetting Adjusted Forecast Values to Auto-Calculated
To reset an adjusted quantity or adjusted revenue back to the system auto-calculated value, deduct 999 from the current value. This is the documented mechanism to "undo" a manual override and restore the auto-calculated forecast value.

### Only Account Owner Can Create AccountForecast
The `AccountForecast` record can only be created by the account owner (the user in the `OwnerId` field of the Account). Other users with object-level CRUD access cannot create forecasts for accounts they do not own.

### Weekly Frequency Only in API v55.0+
The `Weekly` value for `calculationFrequency` and `forecastFrequency` in `AccountForecastSettings` is only available in API version 55.0 and later. Using it with older API versions will result in an error.

### Metrics Display Limit
`displayedForecastMetrics` and `displayedRevenueMetrics` in `AccountForecastSettings` can contain a **maximum of 10 comma-separated metric names**. Exceeding this limit will cause configuration errors.

---

## Mass Update and Recalculation Action Gotchas

### Actions Update Org Data Permanently
The following invocable actions **permanently update data** in your Salesforce org. You must perform a database rollback to undo them:
- `refreshActualsCalculation`
- `recalculateForecast`
- `massUpdateAccountForecast`
- `massUpdateSalesAgreement`

There is no "dry run" or preview mode. Execute with caution in production.

### refreshActualsCalculation: Conflicting Parameters Cause Failure
If both `isCurrentAndFutureSchedules` and `isCurrentSchedule` are set to `true` simultaneously, the `refreshActualsCalculation` action **fails with an error**. Only one can be `true` at a time.

### massUpdateAdvAccountForecast Requires Both Features Enabled
To use the `massUpdateAdvAccountForecast` action, both:
- Manufacturing Cloud feature must be enabled (`enableIndManufacturing = true`)
- Advance Account Forecasting feature must be enabled (`enableIndustriesMfgAdvForecast = true`)

---

## AdvAcctForecastSetPartner Status Rules

The status of `AdvAcctForecastSetPartner` can only transition in one direction:
- `Draft` → `Active` (allowed)
- `Active` → `Inactive` (allowed)
- `Inactive` → `Active` — NOT allowed.
- `Active` → `Draft` — NOT allowed.

When using `updateAdvancedAccountForecastSetPartner` action without specifying a `status`, the default behavior is to move the record from Draft to Active.

### AdvAcctForecastSetPartner Default Status Is Active
The default status for a newly created `AdvAcctForecastSetPartner` record is `Active` (not `Draft`). This may be counterintuitive if you expect to review before activating. New partners are immediately active unless explicitly created with `Status = Draft`.

### Inactive Partner Blocks Forecast Fact Edits
If an `AdvAcctForecastSetPartner` record has `Status = Inactive`, you **cannot edit the corresponding `AdvAccountForecastFact` records**. You must reactivate or use a different partner before editing forecast data.

---

## Sales Agreement Gotchas

### ObjectHierarchyRelationship Must Exist Before Using Sales Agreement API
The Sales Agreement (POST) Connect REST API requires a `ConvertToSalesAgreement` mapping to be defined in `ObjectHierarchyRelationship` BEFORE the API is called. If the mapping does not exist, the API call will fail.

### Decimal Values Require InitialPlannedQtyValue
When mapping quantity fields with decimal values from Opportunity to SalesAgreement via the Connect REST API, you must map the quantity field to `InitialPlannedQtyValue` (not `InitialPlannedQuantity`). Failing to do this will result in decimal values being truncated or causing errors. Also set `IsQuantityInDecimals = true` on the `SalesAgreementProduct`.

### ScheduleFrequency Includes Onetime Value
The `ScheduleFrequency` field on `SalesAgreement` is a restricted picklist with the values: `Monthly`, `Quarterly`, `Yearly`, `Weekly`, and `Onetime` (displayed as "One-Time"). The default value is `Weekly`. The `Onetime` value is sometimes missed by developers expecting only periodic frequencies.

### ShouldUserSpecPlnQuantity Affects Quantity Distribution
The `ShouldUserSpecPlnQuantity` field on `SalesAgreement` defaults to `false`, which means the initial planned quantity of each product is **automatically distributed across all schedules**. If set to `true`, users must manually specify the planned quantity for each schedule. Not accounting for this default can lead to unexpected quantity distribution.

### Schedule Name Affects Actuals Mapping
The `Name` field on `SalesAgreementProductSchedule` should accurately capture the month, quarter, or year for that schedule. The system defaults the name based on period start (e.g., "August" for an Aug–Sep schedule). If not renamed to reflect the actual range (e.g., "15 Aug-15Sep"), actuals may not be reflected correctly for that schedule.

### arePredfndStatusValOveride: Override of Status Validations (API v65.0+)
The `SalesAgreementSettings` field `arePredfndStatusValOveride` (default: `false`, API v65.0+) allows overriding predefined status validations when the corresponding org feature is enabled. Enabling this bypasses standard lifecycle constraints. Use with extreme caution in production environments.

### SalesAgreementDefaultValues Can Remove Mappings
In the Sales Agreement Default Fields Input, providing a blank value for an output field in `salesAgreementDefaultValues` will remove that mapping field from the definition. This is intentional but can be surprising if not expected.

---

## importRecordsFromCsvFile Action Gotchas

### externalIdFieldName Is Required Except for Insert Operations
The `externalIdFieldName` input is optional only when `operationType` is `insert`. For `upsert` operations, `externalIdFieldName` is required. Missing this field in an upsert will cause the action to fail.

### Special Permission Required
To access the `importRecordsFromCsvFile` action, you must enable either:
- The "Import CSV for Advanced Account Forecasting" system permission (with Manufacturing Advanced Account Forecast permission set), OR
- The Manufacturing Program Based Business permission set.

Neither standard admin access nor the base Manufacturing Cloud license alone is sufficient.

---

## InventoryItemReservation Field Restrictions

### Requires Additional License Beyond Manufacturing Cloud
The Manufacturing Cloud fields added to `InventoryItemReservation` are only available if a **B2B Commerce, D2C Commerce, B2C Commerce, or Salesforce Order Management license** is enabled in your org. The Manufacturing Cloud license alone does not grant access.

---

## WorkOrderLineItem ProcessType Field

### Restricted Picklist with Only One Current Value
The `ProcessType` field added to `WorkOrderLineItem` by Manufacturing Cloud is a **restricted picklist**. Currently, the only valid value is `DepotRepair`. No other values are documented. This is a restrictive field — do not attempt to set non-listed values.

### Requires Field Service or Work Orders Enabled
The `WorkOrderLineItem` fields require Work orders or Field Service to be enabled in the org. The Manufacturing Cloud license alone does not make these available.

---

## Metadata Deployment Gotchas

### Wildcard Does Not Work for Most Settings Types
The wildcard character `*` in `package.xml` does **not** apply to the following settings metadata types:
- `IndustriesManufacturingSettings`
- `InventoryReplenishmentSettings`
- `PurchaseOrderMgmtSettings`
- `InventoryAllocationSettings`
- `IndustriesConnectedServiceSettings`
- `IndustriesEventOrchSettings`
- `IndustriesFieldServiceSettings`

The wildcard only applies when retrieving all settings at once, not for individual settings. Exceptions where wildcard IS supported: `MfgServiceConsoleSettings`, `WarrantyLifeCycleMgmtSettings`, `SalesAgreementSettings`, `AcctMgrTargetSettings`, `AdvAccountForecastSet`, `MfgProgramTemplate`, `ObjectHierarchyRelationship`.

### All Feature Flags Default to False
Every feature in `IndustriesManufacturingSettings` defaults to `false`. This means after deploying the metadata, you must explicitly set each feature to `true` to enable it. A common mistake is deploying the settings file and assuming features are enabled.

### AccountForecastSettings Deployment Requires Custom Fields
When deploying `AccountForecastSettings` that references custom fields in `objectMapping`, you must also include those custom fields (on `AccountProductPeriodForecast` and `AccountProductForecast`) in the same deployment package. Missing the custom fields will cause the deployment to fail.

### SalesAgreementSettings Deployment Requires Custom Fields in Package
When deploying `SalesAgreementSettings` that references custom fields in `objectMapping` (SalesAgreementProductSchedule → SalesAgreementProduct), you must include those custom fields in the same deployment package. The sample `package.xml` pattern is to include both `SalesAgreementProduct.MyField__c` and `SalesAgreementProductSchedule.MyField__c` as `CustomField` members in the same package.

### MfgProgramTemplate Requires Program-Based Business Feature
The `MfgProgramTemplate` metadata type requires the program-based business feature setting for Manufacturing Cloud to be enabled before you can create a program template. Deploying without the feature enabled will fail.

### AdvAccountForecastSet Metadata Requires Advanced Forecasting Feature
The `AdvAccountForecastSet` metadata type requires the advanced account forecasting feature setting (`enableIndustriesMfgAdvForecast = true`) to be enabled before you can create this metadata. Deploying without the feature enabled will fail.

### AcctMgrTargetSettings Special Access Rules
To use the `AcctMgrTargetSettings` metadata type, your Salesforce org must have the Manufacturing Cloud license. The org-level license is required, not just a user-level permission set.

### Tooling API: FullName Query Limit
When querying the `AccountForecastSettings` object via Tooling API, the `FullName` field can only be queried if the result contains **no more than one record**. If more than one record exists, an error is returned. Use multiple queries to retrieve multiple records.

---

## API Version Restrictions

| Object / Feature | Minimum API Version | Notes |
|---|---|---|
| AccountForecast, SalesAgreement, AccountProductForecast | 47.0 | Core sales agreement and forecasting objects |
| AcctMgrTarget, AcctMgrTargetDstr, AcctMgrPeriodicTargetDstr, AcctMgrTargetMeasure | 49.0 | Account Manager Targets module |
| AdvAccountForecastSet and related Adv. Forecasting objects | 53.0 | Advanced Account Forecasting |
| AdvAcctFrcstDisplayGroup, AdvAcctFrcstDplyGroupItem | 54.0 | Display groups for Adv. Forecasting |
| AssetWarranty, ProductWarrantyTerm, ManufacturingProgram, MfgProgramForecastFact | 55.0 | Warranty and Program-Based Business |
| AdvAcctForecastSetUse | 55.0 | Junction object for context-based forecasting |
| Visit, GenericVisitTask, GenericVisitTaskContext, GnrcVstKeyPerformanceInd | 56.0 | Visit Management |
| SalesAgreementSettings (Tooling API) | 57.0 | Tooling API access to SA settings |
| Claim, ClaimItem, ClaimCoverage, CodeSet, AssetMilestone | 58.0 | Warranty claims and code sets |
| Fleet, FleetAsset, FleetParticipant, Supplier, SupplierProduct | 59.0 | Fleet and Supplier Management |
| ProductItem, ProductTransfer, SerializedProduct, ReturnOrder, SalesAgreeProductAttribute | 60.0 | Field service inventory objects |
| ProductServiceCampaign, ProductServiceCampaignItem | 61.0 | Product Service Campaigns |
| ProductInvSearchableField, AccountForecastChangeEvent | 62.0 | Inventory search and CDC |
| InventoryCountPlan, InventoryCountAssessment, InventoryReplenishmentPolicy | 63.0 | Inventory Count and Replenishment |
| ActionableEventOrchDef, ActionableEventTypeDef | 64.0 | Actionable Event Orchestration metadata types |
| DealerProdtSearchableField, GoodsReceivedNote, ProductRqmtSpec, PurchaseOrder, StockRotationExecution | 65.0 | Dealer/Partner Lead Mgmt, Purchase Orders, Sample Mgmt |
| TelemetryActionDefinition, TelemetryActionDefStep, TelemetryActnDefStepAttr, TelemetryDefinition, TelemetryDefinitionVersion | 65.0 | Connected Asset/Vehicle Telemetry metadata types |
| IndustriesConnectedServiceSettings | 65.0 | Telemetry Definition and Action Management settings |
| SalesAgreementSettings.arePredfndStatusValOveride | 65.0 | New field on SalesAgreementSettings for overriding status validations |
| Sample Management (POST) API, PurchaseOrderMgmtSettings, InventoryAllocationSettings | 66.0 | Sample Management API, Inventory Allocation |

---

## Field-Level Restrictions

### Restricted Picklists
The following fields are **restricted picklists** — only documented values are valid:

| Object | Field | Values |
|---|---|---|
| AccountForecast | Status | Active, Expired |
| SalesAgreement | ActualsCalculationMode | DataProcessingEngine, Manual, Orders, OrdersThroughContracts |
| InventoryItemReservation | Status (Mfg-added) | Reserved, Cancelled, Reservation In Progress, Cancellation In Progress, Fulfilled |
| WorkOrderLineItem | ProcessType (Mfg-added) | DepotRepair |
| AccountForecastSettings | CalculationFrequency (Tooling) | Monthly (default), Quarterly |
| AccountForecastSettings | ForecastFrequency (Tooling) | Monthly (default), Quarterly |

### Read-Only Fields (Cannot Be Updated)
| Object | Fields That Cannot Be Updated |
|---|---|
| AccountProductPeriodForecast | All fields EXCEPT AdjustedForecastQuantity and AdjustedForecastRevenue |
| AccountForecast | EndDate (cannot be updated once set); Status (cannot change from Expired to Active) |

---

## Ordering Constraints (Must Be Created Before)

1. **AcctMgrTargetMeasure** must exist before creating `AcctMgrTarget` records (it provides the measure picklist).
2. **ObjectHierarchyRelationship** mapping with `ConvertToSalesAgreement` usage type must exist before calling the Sales Agreement (POST) API.
3. **AdvAccountForecastSet** must exist before creating `AdvAcctForecastSetPartner`, `AdvAcctForecastDimension`, `AdvAcctForecastMeasureDef`, or `AdvAccountForecastFact`.
4. **SalesAgreement** must be in `Active` status before actuals calculation will run.
5. **AccountForecast** with Active status: must expire existing active forecast before creating a new one.
6. **IndustriesManufacturingSettings** feature flags must be enabled via deployment before attempting to create related objects via API.
7. **MfgProgramTemplate** must exist before creating a `ManufacturingProgram` of that template type.

---

## Permission and License Prerequisites Easy to Miss

1. **Manufacturing Cloud license required at org level** — not just user-level permission sets. The org must have the Manufacturing Cloud license provisioned.
2. **Lightning Experience required** — Manufacturing Cloud is NOT available in Salesforce Classic.
3. **InventoryItemReservation Mfg fields** — require B2B Commerce / D2C Commerce / B2C Commerce / Salesforce Order Management license (not just Mfg Cloud license).
4. **Import CSV action** — requires specific system permission ("Import CSV for Advanced Account Forecasting"), not just the base Manufacturing Cloud license.
5. **massUpdateAdvAccountForecast** — requires BOTH Manufacturing Cloud AND Advance Account Forecasting features enabled (not just a permission set).
6. **MfgServiceConsoleSettings** — requires Manufacturing Cloud license to use this metadata type.

---

## Change Data Capture (CDC) Limitations

Not all Manufacturing Cloud objects support Change Data Capture. Only these objects have associated ChangeEvent objects:
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

Other Manufacturing Cloud objects (e.g., `AdvAccountForecastFact`, `MfgProgramForecastFact`, `Claim`) do NOT have CDC support.

---

## AgreementType Field Deprecation

The `AgreementType` field on `SalesAgreement` is **deprecated**. The documentation states: "We recommend not adding it to the page layout." A sales agreement is always volume-based regardless of this field's value. Do not build integrations or automation that depend on this field.

---

## AccountForecastAdjustment: AdjustmentComments Field Behavior

The `AdjustmentComments` field on `AccountForecastAdjustment` can only be updated **at the same time** as either `AdjustedForecastedQuantity` or `AdjustedForecastedRevenue`. Attempting to update `AdjustmentComments` alone in an update call will not persist the change.

---

## IsActive on AccountForecastAdjustment: Only Last 3 Changes Recorded

The `IsActive` field on `AccountForecastAdjustment` indicates whether the adjustment is part of the edit history. Only the **last three changes** (including the auto-calculated value) are recorded. Older adjustment history records are no longer considered active.

---

## enableIndustriesMfgIAS Is Beta

The `enableIndustriesMfgIAS` field in `IndustriesManufacturingSettings` (Default Analytics Dashboards) is a **Beta Service**. Use of this feature is subject to Beta Services Terms. Do not build production-critical workflows depending on this feature without consulting Salesforce.

---

## ObjectHierarchyRelationship: usageType Has Additional Values

The `usageType` field on `ObjectHierarchyRelationship` supports more values than just `ConvertToSalesAgreement`. The full set of valid values is:
- `ConvertToSalesAgreement` — standard SA creation from Opportunity/Quote
- `CLMFieldMapping` — Contract Lifecycle Management field mappings
- `EligibleProgramRebateType` — Eligible Program Rebate Type mappings
- `MapJournalToMemberAggregate` — Journal to Member Aggregate mappings
- `TransformationMapping` — Manufacturing Program transformation mappings

Ensure you use the correct `usageType` when creating `ObjectHierarchyRelationship` records for different use cases.

---

## AdvAcctForecastMeasureDef: Maximum 10 Metrics

The `AdvAcctForecastMeasureDef` object has a maximum of **10 metrics** that can be displayed in the forecast grid for a given `AdvAccountForecastSet`. This mirrors the 10-metric limit on `AccountForecastSettings.displayedForecastMetrics`.
