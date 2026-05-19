---
source: Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide)
cloud: Manufacturing Cloud
section: automation-patterns
last-updated: 2026-05-10
---

# Manufacturing Cloud — Automation Patterns

## Sales Agreement Automation

### Sales Agreement Lifecycle Flow

```
Opportunity / Quote (source)
        |
        v (ObjectHierarchyRelationship mapping)
POST /connect/manufacturing/sales-agreements
        |
        v
SalesAgreement (Status: Draft)
  ├── SalesAgreementProduct
  │     └── SalesAgreementProductSchedule (period-level planned qty/revenue)
  └── [Manual or ERP sync for planned values]
        |
        v (Activate)
SalesAgreement (Status: Active)
        |
        v (Scheduled or triggered)
Actuals Calculation
  ActualsCalculationMode: Orders | OrdersThroughContracts | DataProcessingEngine | Manual
        |
        v
SalesAgreementProductSchedule.ActualQuantity, ActualRevenue (populated)
```

**Actuals Calculation trigger pattern (Invocable Action in Flow):**
```
Action: refreshActualsCalculation
Input: salesAgreementId (required)
When to trigger: After Order activation / nightly scheduled batch
```

**Mass Update pattern (bulk price or quantity updates):**
```
Action: massUpdateSalesAgreement
Input: array of SalesAgreementProduct + period records with updated values
Use case: Annual price adjustments, volume renegotiations
Important: Mass updates are PERMANENT — no rollback once committed
```

### Sales Agreement → Opportunity Conversion Pattern

```
1. Configure ObjectHierarchyRelationship:
   - Usage type: ConvertToSalesAgreement
   - Parent mapping: Opportunity → SalesAgreement
   - Child mapping: OpportunityLineItem → SalesAgreementProduct
   - Map quantity to InitialPlannedQtyValue for decimal support

2. Trigger creation:
   POST /connect/manufacturing/sales-agreements
   Body: { "sourceObjectId": "<OpportunityId>" }

3. Result:
   - SalesAgreement created with fields from mapping
   - SalesAgreementProducts created for each OpportunityLineItem
   - SalesAgreementProductSchedules generated per ScheduleFrequency and ScheduleCount
```

---

## Account Forecasting Automation

### Standard Account Forecast Recalculation

```
AccountForecast (one active per Account, ForecastSet, StartDate, EndDate)
  └── AccountProductForecast (per product per account)
        └── AccountProductPeriodForecast (per period)
              ├── PlannedRevenue (from Sales Agreements)
              ├── ActualRevenue (from Orders)
              ├── OpportunityRevenue (from open Opps)
              └── ForecastAdjustment (manual — stored in AccountForecastAdjustment)
```

**Mass Update pattern (bulk manual adjustments):**
```
Action: massUpdateForecast
Input: array of AccountProductPeriodForecast records with updated values
Important: Permanent — no rollback
Requires: Manufacturing Cloud + Advanced Account Forecasting feature enabled
```

### Advanced Account Forecasting Recalculation

```
Action: calculateAdvancedAccountForecasts
Input: advAccountForecastSetId (required)
When to trigger: after source data changes (new orders, SA updates)
Available since: API 52.0
```

**Forecast data import from CSV:**
```
Action: importRecordsFromCsvFile
Input: ContentVersionId (CSV file), objectApiName (e.g., MfgProgramForecastFact)
Requires: Manufacturing Advanced Account Forecast + Import CSV permission
          OR Manufacturing Program Based Business permission
```

---

## Manufacturing Programs Automation

### Transformations API — Convert Program Forecasts to Opportunities

The Transformations API converts `MfgProgramForecastFact` and component forecast data into Salesforce Opportunities and OpportunityLineItems.

```
POST /connect/manufacturing/transformations

Input: {
  "forecastSetId": "<AdvAccountForecastSetId>",
  "transformationType": "MfgProgramToOpportunity"
}

Output: Opportunity + OpportunityLineItem records created
```

Use case: When a manufacturing program reaches a milestone, convert program forecasts to committed pipeline Opportunities for standard CRM reporting.

---

## Warranty and Claims Automation

### Warranty to Supplier Claims

Clones a warranty claim hierarchy to generate a supplier recovery claim.

```
POST /connect/manufacturing/warranty-supplier-claims

Input: {
  "warrantyClaimId": "<ClaimId>",
  "supplierId": "<SupplierId>"
}

Output: New Claim record (supplier recovery) with cloned ClaimItems, ClaimCoverages
```

---

## Sample Management Automation

### Product Requirement Specification — Create / Update / Version

```
POST /connect/manufacturing/sample-management/product-specifications

Operations:
  - "Insert": Creates a new ProductRqmtSpec record
  - "Update": Updates an existing ProductRqmtSpec record
  - "Version": Creates a new version of an existing ProductRqmtSpec

Required inputs: requestUniqueId, operation, productSpecificationInput
```

**Apex class pattern (ind_mfg_sample_mgmt_apex namespace):**
```apex
// Create specification
ind_mfg_sample_mgmt_apex.ProductSpecification spec = new ind_mfg_sample_mgmt_apex.ProductSpecification();
spec.operation = 'Insert';
// ... set properties

ind_mfg_sample_mgmt_apex.ProductSpecificationInput input = new ind_mfg_sample_mgmt_apex.ProductSpecificationInput();
input.productSpecification = spec;

// Submit
ind_mfg_sample_mgmt_apex.ManufacturingCloudAPI.submitProductSpecification(input);
```

---

## Key Invocable Actions Summary (for Flow/Process Builder)

| Action Name | Purpose | Key Inputs | Available Since |
|---|---|---|---|
| `refreshActualsCalculation` | Recalculate actuals for a Sales Agreement | `salesAgreementId` | 47.0 |
| `massUpdateSalesAgreement` | Bulk update SA product/period fields | Array of SA records | 48.0 |
| `massUpdateForecast` | Bulk update Account Forecast period records | Array of forecast records | 48.0 |
| `calculateAdvancedAccountForecasts` | Recalculate advanced forecasts | `advAccountForecastSetId` | 52.0 |
| `importRecordsFromCsvFile` | Import forecast data from CSV | `ContentVersionId`, `objectApiName` | 55.0 |

All actions are available at:
```
POST /services/data/vXX.X/actions/standard/{actionName}
```

---

## ERP Integration Patterns

### Planned Quantity Sync from ERP
- **Pattern:** Nightly batch upsert of `SalesAgreementProductSchedule` records via Bulk API 2.0
- **Key fields to sync:** `PlannedQuantity`, `PlannedRevenue`, `ScheduleStartDate`
- **Trigger actuals:** After sync, invoke `refreshActualsCalculation` for affected SalesAgreements

### Order Actuals Flow (when `ActualsCalculationMode = Orders`)
```
ERP Order Confirmation
        |
        v
Salesforce Order (Activated) + OrderItem
        |
        v (automated by Manufacturing Cloud engine)
SalesAgreementProductSchedule.ActualQuantity updated
        |
        v
AccountProductPeriodForecast.ActualRevenue updated
```

### Forecast Import Pattern (Advanced Account Forecasting)
```
1. ERP/Planning system exports forecast data as CSV
2. Upload CSV as ContentVersion (Files)
3. Invoke importRecordsFromCsvFile action with ContentVersionId
4. Manufacturing Cloud processes CSV and upserts AdvAccountForecastFact records
5. Invoke calculateAdvancedAccountForecasts to refresh derived metrics
```

---

## Flow Design Recommendations

- Use **After-Save Record-Triggered Flows** on `Order` for actuals recalculation triggers — avoid Before-Save to prevent order activation interference
- Use **Scheduled Flows** (nightly) for `calculateAdvancedAccountForecasts` — do not run on every record change
- Do **not** add Apex triggers on `SalesAgreement` or `AccountForecast` — use Flow or Invocable Actions to interact with Manufacturing Cloud objects
- Mass Update actions (`massUpdateSalesAgreement`, `massUpdateForecast`) are irreversible — always build a confirmation/approval step in the Flow before invoking them
- For high-volume actuals calculation, use the `DataProcessingEngine` ActualsCalculationMode instead of `Orders` — it avoids governor limits from synchronous trigger chains
