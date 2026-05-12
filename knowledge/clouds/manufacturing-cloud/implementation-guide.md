---
source: "Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide); mfg_api_devguide.pdf (Spring '26, April 30, 2026)"
cloud: Manufacturing Cloud
section: implementation-guide
last-updated: 2026-05-10
---

# Manufacturing Cloud — Implementation Guide

## Setup Sequence

The correct order for configuring Manufacturing Cloud features matters. Follow this sequence to avoid dependency errors.

### Phase 1: Org Enablement (Required First)

1. Enable Manufacturing Cloud via `IndustriesManufacturingSettings` metadata: set `enableIndManufacturing` to `true`.
2. Assign the appropriate Manufacturing Cloud license to your org.
3. Assign permission sets to users for the specific modules they will use.

### Phase 2: Feature-by-Feature Enablement

Each feature has its own enablement toggle in `IndustriesManufacturingSettings`:

| Feature | Setting Field | API Version |
|---|---|---|
| Account Forecasting | `enableIndustriesMfgAccountForecast` | 47.0+ |
| Advanced Account Forecasting | `enableIndustriesMfgAdvForecast` | 47.0+ |
| Program-Based Business | `enableIndustriesMfgProgram` | 54.0+ |
| Account Manager Targets | `enableIndustriesMfgTargets` | 49.0+ |
| Connected Asset Services (prebuilt components) | `enableConnectedAssetSrvcsCmpnt` | 61.0+ |
| Vehicle and Asset Finance | `enableVehicleAndAssetFinance` | 60.0+ |
| Vehicle and Asset Finance Additional Components | `enableVehAssetFinAddtnlCmpnts` | 60.0+ |
| Vehicle and Asset Lending | `enableVehAndAstLending` | 62.0+ |
| Purchase Order Management | `enablePurchaseOrderMgt` (via PurchaseOrderMgmtSettings) | — |
| Inventory Replenishment | `enableInventoryReplenishment` (via InventoryReplenishmentSettings) | 63.0+ |
| Inventory Allocation | `enableInventoryAllocation` (via InventoryAllocationSettings) | 66.0+ |
| Service Console for Manufacturing | `enableMfgServiceConsole` (via MfgServiceConsoleSettings) | 56.0+ |
| Warranty Life Cycle Management | `enableWarrantyLCMgmt` (via WarrantyLifeCycleMgmtSettings) | — |
| Partner Lead Management Mappings | `enablePtnrLeadMgmtMappings` | 60.0+ |
| Manufacturing Agents | `enableMfgAgents` | 64.0+ |
| Default Analytics Dashboards (Beta) | `enableIndustriesMfgIAS` | 47.0+ |
| Telemetry Definition and Action Management | `enableTelemetryDefActnMgmt` (via IndustriesConnectedServiceSettings) | 65.0+ |
| Event Orchestration Decision Table | `enableEventOrchDecisionTable` (via IndustriesEventOrchSettings) | 60.0+ |

---

## Sales Agreements: Configuration Steps

### Prerequisites
- Manufacturing Cloud license enabled.
- "Manufacturing Sales Agreements" permission set assigned to users.
- `SalesAgreementSettings` metadata configured.

### Configuration Steps

1. **Configure SalesAgreementSettings** via Metadata API or Setup UI. This controls:
   - Display of agreement terms metrics.
   - Calculation mode for actuals.
   - Approval settings.

2. **Configure ObjectHierarchyRelationship** (if using Sales Agreement creation from Opportunity/Quote):
   - Create a mapping with `ConvertToSalesAgreement` usage type.
   - Map parent-level fields: Opportunity → SalesAgreement, Quote → SalesAgreement.
   - Map child-level fields: OpportunityLineItem → SalesAgreementProduct.
   - To use decimal values, map quantity fields to `InitialPlannedQtyValue`.

3. **Create Sales Agreements via API or UI:**
   - **Via Connect REST API:** POST to `/services/data/vXX.X/connect/manufacturing/sales-agreements` with a `sourceObjectId` (Opportunity or Quote ID).
   - **Via UI:** Create directly in the Sales Agreement object record page.

4. **Activate Sales Agreements:**
   - Set `Status` field to `Active`.
   - Once activated, `ActivatedDate` is populated.
   - Sales Agreement must be Active for actuals calculation to run.

5. **Actuals Calculation:**
   - Set `ActualsCalculationMode` on the SalesAgreement:
     - `Orders` — automatically from direct orders.
     - `OrdersThroughContracts` — from orders through contracts.
     - `DataProcessingEngine` — using a Data Processing Engine Definition.
     - `Manual` — manually via API upload.
   - Configure `FutureActCalcSchedules` to control how many future periods are included in actuals recalculation.
   - Trigger actuals refresh using the `refreshActualsCalculation` invocable action.

6. **Mass Updates:** Use `massUpdateSalesAgreement` invocable action for bulk updates to fields like `SalesPrice` across products and periods.

### Key Fields to Configure on SalesAgreement

| Field | Required | Notes |
|---|---|---|
| AccountId | Yes | The account this agreement belongs to |
| StartDate | Yes | When the agreement begins |
| ScheduleFrequency | Yes | Monthly, Quarterly, Yearly, Weekly, or Onetime. Default is Weekly. |
| ScheduleCount | Yes | Number of periods |
| ActualsCalculationMode | Yes | How actuals are calculated |
| DecimalScale | Optional | Number of decimal places applied to values. API v62.0+. |
| FutureActCalcSchedules | Optional | Number of future schedules for actuals calc (also configurable in SalesAgreementSettings from API v63.0+) |
| ShouldUserSpecPlnQuantity | Optional | If false (default), initial planned quantity is automatically distributed across all schedules. If true, user specifies quantity per schedule. |
| PriceAdjustmentScheduleId | Optional | Price adjustment schedule (API v59.0+) |

**Important note on schedule naming:** When naming `SalesAgreementProductSchedule` records, make sure the name correctly captures the month, quarter, or year for the particular schedule. If a schedule is from 15 Aug to 15 Sept, the system defaults the name to "August" — rename it to "15 Aug-15Sep" so that actuals are reflected correctly for that schedule.

**Decimal quantity mapping:** When mapping quantity fields with decimal values from Opportunity to SalesAgreement, you must map the quantity field to `InitialPlannedQtyValue` (not `InitialPlannedQuantity`). Set `IsQuantityInDecimals = true` on SalesAgreementProduct to enable decimal quantities.

### Sales Agreement Lifecycle States

```
Draft --> Active --> Expired
                --> Cancelled
```

---

## Account Forecasting: Setup Dependencies

### Prerequisites
- `enableIndustriesMfgAccountForecast` = true in IndustriesManufacturingSettings.
- Sales Agreements must be configured (forecasting draws from SA data).
- `AccountForecastSettings` metadata must be configured.

### AccountForecastSettings Configuration

Required fields to configure:

| Field | Notes |
|---|---|
| calculationFrequency | How often forecasts are recalculated (Monthly/Quarterly/Yearly/Weekly) |
| forecastFrequency | How often forecasts are generated |
| displayDuration | Number of periods to display |
| displayedForecastMetrics | Up to 10 comma-separated quantity metric names |
| displayedRevenueMetrics | Up to 10 comma-separated revenue metric names |
| editableAtStartOfPeriod | true/false — whether adjustments are allowed at start of period |
| editsAllowedFor | Number of days the adjustment window is open |
| startingPeriod | How many periods back from current date to start forecast generation |
| accountForecastFormulas | One or more formulas for quantity/revenue calculation |

### AccountForecastFormula Configuration

Each formula requires:
- `formula` — Salesforce formula string using field names from `AccountProductPeriodForecast` (e.g., `SalesAgreementPlannedQuantity + OpportunityQuantity`).
- `formulaType` — `QUANTITY` or `REVENUE`.
- `startingPeriod` / `endingPeriod` — period range the formula applies to.

### Forecast Adjustment Patterns

1. **Manual Adjustments via UI:** Users can adjust `AdjustedForecastQuantity` and `AdjustedForecastRevenue` on `AccountProductPeriodForecast` records. These are the ONLY fields that can be updated on `AccountProductPeriodForecast`. **Note: Neither field can be updated for past schedules.**

2. **Manual Adjustments via API:** Create `AccountForecastAdjustment` records linked to `AccountProductPeriodForecastId`. You can also update `AdjustmentComments` at the same time as `AdjustedForecastedQuantity` or `AdjustedForecastedRevenue`.

3. **Resetting adjustments:** To reset an adjusted quantity or adjusted revenue back to the auto-calculated value, deduct 999 from the current value. This triggers a reset to the auto-calculated value.

4. **Mass Updates via Action:** Use `massUpdateAccountForecast` invocable action to update a field across multiple products and periods in a single call.

5. **Recalculation:** Trigger `recalculateForecast` action with a specific `forecastId` or use `forecastId: "ALL"` to recalculate all account forecasts.

### Account Forecast Constraints

- Only 1 active AccountForecast per account at any time.
- Must expire an existing active forecast before creating a new one.
- Active forecasts must be expired before they can be deleted.
- Only the account owner can create the forecast record.
- EndDate of an active account forecast must be null and cannot be updated.
- Status cannot be changed from Expired to Active.

---

## Advanced Account Forecasting: Setup

### Prerequisites
- `enableIndustriesMfgAdvForecast` = true in IndustriesManufacturingSettings.
- "Manufacturing Advanced Account Forecast" permission set.
- For Import CSV action: "Import CSV for Advanced Account Forecasting" system permission OR Manufacturing Program Based Business permission set.

### Setup Steps

1. **Create an AdvAccountForecastSet** — defines the configuration (forecast frequency, periods, dimensions).

2. **Configure dimensions** — create `AdvAcctForecastDimension` records for the dimensions you want to use (e.g., product, region).

3. **Configure measure definitions** — create `AdvAcctForecastMeasureDef` records to define which measures appear in the forecast grid (max 10 metrics).

4. **Configure display groups** — optionally group measures/dimensions using `AdvAcctFrcstDisplayGroup` and `AdvAcctFrcstDplyGroupItem`.

5. **Configure periods** — set up `AdvAccountForecastPeriod` and `AdvAcctForecastPeriodGroup`.

6. **Add accounts (partners)** — create `AdvAcctForecastSetPartner` records (junction between forecast set and account). Status flow: Draft → Active → Inactive. **Important:** The default status for new partner records is `Active` (not `Draft`). If a partner record is Inactive, the corresponding forecast fact records cannot be edited.

7. **Optionally link to context objects** — create `AdvAcctForecastSetUse` records to link the forecast set to a ManufacturingProgram or other context object.

8. **Calculate forecasts** — use `calculateAdvancedAccountForecast` invocable action with `forecastSetId`, `accountId`, and `forecastDataId`.

9. **Update partner status** — use `updateAdvancedAccountForecastSetPartner` action to update partner record status from Draft to Active after forecast data is generated.

10. **Mass updates** — use `massUpdateAdvAccountForecast` action to update measures across filtered forecast fact records.

---

## Account Manager Targets: Setup

### Prerequisites
- `enableIndustriesMfgTargets` = true in IndustriesManufacturingSettings.
- `AcctMgrTargetSettings` configured.

### Setup Steps

1. **Configure AcctMgrTargetSettings** — set distribution frequency, team hierarchy for assignments, default price book.

2. **Create AcctMgrTargetMeasure** records — defines the picklist of available measure types.

3. **Create AcctMgrTarget** — the main target record (fiscal year, measure, target value, start/end date).

4. **Create AcctMgrTargetDstr** records — link the target to specific accounts, products, and price books. Child of AcctMgrTarget.

5. **Create AcctMgrPeriodicTargetDstr** records — defines per-period target values (12 period fields). Links to AcctMgrTarget or AcctMgrTargetDstr.

6. **Update assignment values** — use `updateAcctMgrTarget` invocable action when a target's overall value changes to automatically redistribute values based on percentage.

---

## Manufacturing Programs: Setup

### Prerequisites
- `enableIndustriesMfgProgram` = true in IndustriesManufacturingSettings.
- "Manufacturing Program Based Business" permission set.

### Setup Steps

1. **Create MfgProgramTemplate** — defines the template for a program type.

2. **Create MfgProgramTemplateItem** records — defines the transformation types associated with the template.

3. **Create ManufacturingProgram** — the main program record (linked to an account, with start/end dates).

4. **Generate forecast data** — system generates `MfgProgramForecastFact`, `MfgProgramCpntFrcstFact`, and `MfgProgramVariantFrcstFact` records.

5. **Run Transformations** — use the Transformations (POST) API to convert program component forecast data to Opportunities:
   - `MfgProgramCpntFrcstFact` → `Opportunity`
   - `ManufacturingProgram` → `Opportunity`
   - `MfgProgramCpntFrcstFact` → `OpportunityLineItem`
   - `Period` → `OpportunityLineItemSchedule`

6. **Import CSV data** — use `importRecordsFromCsvFile` action to bulk-import `MfgProgramForecastFact` data from CSV files.

7. **Link to Advanced Account Forecasting** — create `AdvAcctForecastSetUse` to use ManufacturingProgram as the context for advanced forecast generation.

---

---

## SalesAgreementSettings: New Fields (API v63.0+, v65.0+)

Two fields were added to `SalesAgreementSettings` metadata in recent API versions:

| Field | Type | API Version | Notes |
|---|---|---|---|
| `futureActCalcSchedules` | int | 63.0+ | Number of future schedules to include in actuals calculations, configurable org-wide in settings |
| `decimalScale` | int | 62.0+ | Number of decimal places applied to values in sales agreements, configurable org-wide |
| `arePredfndStatusValOveride` | boolean | 65.0+ | Indicates whether predefined status validations are overridden when the Override Predefined Status Validations feature is enabled. Default is false. |

The `arePredfndStatusValOveride` field allows overriding the standard status lifecycle constraints on Sales Agreements — use with caution, as it bypasses built-in validation rules.

---

## Metadata Deployment: Settings Types Summary

Each Settings metadata type has a specific file suffix and Settings name to use in `package.xml`:

| Settings Type | File | Package.xml member name | Min API Version |
|---|---|---|---|
| IndustriesManufacturingSettings | `IndustriesManufacturing.settings` | `IndustriesManufacturing` | 47.0 |
| SalesAgreementSettings | `SalesAgreementSettings.salesAgreementSetting` (in `salesAgreementSettings/` dir) | `*` | 47.0 |
| AcctMgrTargetSettings | `AcctMgrTarget.settings` | `AcctMgrTarget` | 49.0 |
| MfgServiceConsoleSettings | `MfgServiceConsole.settings` | `MfgServiceConsole` | 56.0 |
| WarrantyLifeCycleMgmtSettings | `WarrantyLifeCycleMgmt.settings` | `WarrantyLifeCycleMgmt` | 55.0 |
| InventoryReplenishmentSettings | `InventoryReplenishment.settings` | `InventoryReplenishment` | 63.0 |
| InventoryAllocationSettings | `InventoryAllocation.settings` | `InventoryAllocation` | 66.0 |
| PurchaseOrderMgmtSettings | `PurchaseOrderMgmt.settings` | `PurchaseOrderMgmt` | 63.0 |
| IndustriesConnectedServiceSettings | `IndustriesConnectedServiceSettings.settings` | `IndustriesConnectedService` | 65.0 |
| IndustriesEventOrchSettings | `IndustriesEventOrch.settings` | `IndustriesEventOrchSettings` | 60.0 |
| IndustriesFieldServiceSettings | `IndustriesFieldService.settings` | `IndustriesFieldService` | 60.0 |

**Wildcard behavior:** The wildcard `*` in `package.xml` does NOT work for most of these settings types individually. Use the specific member name shown above. Exceptions where `*` IS supported: `MfgServiceConsoleSettings`, `WarrantyLifeCycleMgmtSettings`, `SalesAgreementSettings`, `AcctMgrTargetSettings`, `AdvAccountForecastSet`, `MfgProgramTemplate`, `ObjectHierarchyRelationship`.

---

## Common Integration Patterns

### ERP Data Sync (Sales Agreements)

**Pattern:** Sync planned quantities and prices from ERP into Salesforce Sales Agreements.

**Approach:**
1. Configure `ObjectHierarchyRelationship` to map ERP source object fields to SalesAgreement and SalesAgreementProduct.
2. Use the Sales Agreement (POST) API with the ERP record ID as `sourceObjectId`.
3. For bulk updates to prices and quantities, use `massUpdateSalesAgreement` action.
4. For actuals from orders, set `ActualsCalculationMode` to `Orders` or `OrdersThroughContracts`.

### Forecast Data Import from External Systems

**Pattern:** Import forecast data from ERP or planning tools into Manufacturing Program forecast objects.

**Approach:**
1. Upload CSV file as a ContentDocument/ReceivedDocument.
2. Use `importRecordsFromCsvFile` invocable action with:
   - `targetObjectApiName`: e.g., `MfgProgramForecastFact`
   - `operationType`: `upsert` (requires `externalIdFieldName`) or `insert`
   - `receivedDocumentId`: ID of the uploaded CSV document

### Warranty Claim to Supplier Recovery

**Pattern:** Auto-generate supplier recovery claims from warranty claims.

**Approach:**
1. Create a `Claim` record with the warranty claim details.
2. Call the Warranty To Supplier Claims API to clone the claim hierarchy.
3. The API creates supplier recovery claims including `ClaimItem`, `ClaimCoverage`, and `ClaimCoveragePaymentDetail` records.

---

## Permission Sets Required

| Module | Permission Set |
|---|---|
| Sales Agreements | Manufacturing Sales Agreements |
| Account Forecasting | Manufacturing Cloud license (enableIndustriesMfgAccountForecast=true) |
| Advanced Account Forecasting | Manufacturing Advanced Account Forecast |
| Import CSV for Adv. Forecasting | Import CSV for Advanced Account Forecasting system permission (with Manufacturing Advanced Account Forecast PS) |
| Program-Based Business | Manufacturing Program Based Business |
| Service Console for Manufacturing | Manufacturing Cloud license + MfgServiceConsoleSettings enabled |

---

## Key Governor Limits and Constraints

### Sales Agreements
- Only 1 active AccountForecast per account at any time.
- `AccountProductPeriodForecast`: only `AdjustedForecastQuantity` and `AdjustedForecastRevenue` fields can be updated — all other fields are read-only.
- If both `isCurrentAndFutureSchedules` and `isCurrentSchedule` are both set to `true` in the `refreshActualsCalculation` action, the action fails with an error.

### AccountForecastSettings
- `displayedForecastMetrics` and `displayedRevenueMetrics`: maximum 10 comma-separated metric names.
- `calculationFrequency` and `forecastFrequency`: `Weekly` value is only available in API version 55.0 and later.

### Advanced Account Forecasting
- `AdvAcctForecastMeasureDef`: maximum 10 metrics can be displayed in the forecast grid.
- `AdvAcctForecastSetPartner` status can only change from Draft to Active or Active to Inactive — not backward.
- `massUpdateAdvAccountForecast`: both Manufacturing Cloud AND Advance Account Forecasting feature must be enabled.

### Tooling API
- `AccountForecastSettings.FullName`: Query this field only if the query result contains no more than one record. If more than one record exists, use multiple queries.

### Metadata Deployment
- The wildcard character `*` in package.xml does NOT apply to most feature settings metadata types (except `MfgServiceConsoleSettings` and `WarrantyLifeCycleMgmtSettings`).
- All feature flags in `IndustriesManufacturingSettings` default to `false` — must be explicitly set to `true`.

---

## AdvAcctForecastSetUse Status Values

The `AdvAcctForecastSetUse` object has a richer set of status values than `AdvAcctForecastSetPartner`. The full set of valid values for `AdvAcctForecastSetUse.Status` is:
- `Active` (default)
- `Approved`
- `Canceled`
- `Draft`
- `Inactive`
- `Rejected`
- `SubmittedForApproval`

This is different from `AdvAcctForecastSetPartner` which only has `Active`, `Draft`, and `Inactive`.

---

## massUpdateAdvAccountForecast: Input Parameters

| Input | Type | Required | Description |
|---|---|---|---|
| `actionType` | String | Yes | `DecreaseBy`, `IncreaseBy`, or `ReplaceWith` |
| `forecastReferenceId` | String | Yes | ID of `AdvAcctForecastSetUse` or `AdvAcctForecastSetPartner` record to update |
| `isPercent` | Boolean | Yes | If true, value is treated as a percentage. Default false. |
| `listViewId` | String | Yes | ID of the list view record containing filtered forecast fact records |
| `measureFieldName` | String | Yes | API name of the measure field on the list view object to update |
| `value` | String | Yes | Value to use for the update operation |

---

## Important Notes from Documentation

- **Manufacturing Cloud is available in Lightning Experience only.** Classic is not supported.
- **Invocable actions update org data permanently.** The documentation explicitly states: "These actions update the actuals data / forecast data in your Salesforce org. You must perform a database rollback to undo these actions." This applies to: `refreshActualsCalculation`, `recalculateForecast`, `massUpdateAccountForecast`, `massUpdateSalesAgreement`.
- **Sales Agreement activation is one-way:** Draft → Active → Expired/Cancelled. You cannot reactivate an expired or cancelled agreement.
- **Account Forecast expiration is required before deletion:** Active account forecast records must be expired before they can be deleted.
- **ObjectHierarchyRelationship prerequisite:** The mapping definition must be in place BEFORE calling the Sales Agreement (POST) API, otherwise the API call will fail.
- **InventoryItemReservation special access:** The Manufacturing Cloud fields on InventoryItemReservation are only available if a B2B Commerce, D2C Commerce, B2C Commerce, or Salesforce Order Management license is enabled — not just the Manufacturing Cloud license.
- **Work Orders for ProcessType field:** The `ProcessType` field added to `WorkOrderLineItem` requires Work orders or Field Service to be enabled. The only current valid value is `DepotRepair`.
- **API End-of-Life:** Salesforce supports each API version for a minimum of 3 years. Customers receive at least 1 year notice before support for a version ends.
