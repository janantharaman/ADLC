---
source: Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide)
cloud: Manufacturing Cloud
section: security-model
last-updated: 2026-05-10
---

# Manufacturing Cloud — Security Model

## License Requirements

Manufacturing Cloud features require **both** a Salesforce base license (Enterprise, Unlimited, or Developer Edition) **and** a Manufacturing Cloud industry license. The industry license unlocks the Manufacturing Cloud objects and APIs.

**Available in:** Lightning Experience only. Classic is not supported.

---

## Permission Sets by Module

Each Manufacturing Cloud module has its own permission set. Users need both the base Manufacturing Cloud license and the appropriate permission set(s) for each module they access.

| Module | Permission Set | Notes |
|---|---|---|
| Sales Agreements | Manufacturing Sales Agreements | Required for all SA API access |
| Account Forecasting | Manufacturing Cloud license + `enableIndustriesMfgAccountForecast = true` | Enabled via IndustriesManufacturingSettings |
| Advanced Account Forecasting | Manufacturing Advanced Account Forecast | Required for AdvAccountForecastSet APIs |
| Advanced Forecast Mass Update | Manufacturing Cloud + Advanced Account Forecasting feature | Both must be enabled |
| CSV Import (Adv. Forecasting) | Import CSV for Advanced Account Forecasting system permission | Must be combined with the Advanced Account Forecast PS |
| CSV Import (Program Business) | Manufacturing Program Based Business PS | Includes CSV import access |
| Program-Based Business | Manufacturing Program Based Business | Required for ManufacturingProgram objects |
| Warranty Life Cycle Management | Manufacturing Cloud license + `enableWarrantyLCMgmt = true` | Via WarrantyLifeCycleMgmtSettings |
| Service Console for Manufacturing | Manufacturing Cloud license + `enableMfgServiceConsole = true` | Via MfgServiceConsoleSettings |
| Purchase Order Management | Manufacturing Cloud license + `enablePurchaseOrderMgt = true` | Via PurchaseOrderMgmtSettings |
| Inventory Replenishment | Manufacturing Cloud license + `enableInventoryReplenishment = true` | Via InventoryReplenishmentSettings |
| Manufacturing Agents | `enableMfgAgents = true` | In IndustriesManufacturingSettings |
| Partner Lead Management | `enablePtnrLeadMgmtMappings = true` | In IndustriesManufacturingSettings |
| Connected Asset Services | `enableConnectedAssetSrvcsCmpnt = true` | In IndustriesManufacturingSettings |
| Inventory Item Reservation fields | B2B Commerce, D2C Commerce, B2C Commerce, OR Salesforce Order Management license | NOT included with Manufacturing Cloud license alone |

---

## Special Access Rules by API / Object

### Sales Agreement API
- Requires **Manufacturing Cloud license** with the **Manufacturing Sales Agreements** permission set
- Both conditions must be true for API access

### Sample Management API (API 66.0+)
- Requires Manufacturing Cloud license
- POST endpoint: `/connect/manufacturing/sample-management/product-specifications`

### Warranty To Supplier Claims API
- Requires Manufacturing Cloud license + Warranty Life Cycle Management enabled

### Transformations API
- Requires Manufacturing Cloud license + Program-Based Business permission set

### InventoryItemReservation (Manufacturing Cloud fields)
- **Special access rule:** The Manufacturing Cloud–specific fields on `InventoryItemReservation` are only available when a **B2B Commerce, D2C Commerce, B2C Commerce, or Salesforce Order Management** license is enabled
- A standalone Manufacturing Cloud license is NOT sufficient

### WorkOrderLineItem (ProcessType field)
- Requires **Work Orders or Field Service** to be enabled
- The only valid current value is `DepotRepair`

---

## Object-Level Access Patterns

### AccountForecast
- Only **one active AccountForecast** per account at any given time
- Active account forecast records must be **expired before they can be deleted**
- `AccountProductPeriodForecast`: only `AdjustedForecastQuantity` and `AdjustedForecastRevenue` are updatable — all other fields are system-managed (read-only)

### AdvAcctForecastSetPartner
- Status transitions: `Draft` → `Active` → `Inactive` (forward only — no reversals)

### Tooling API — AccountForecastSettings
- Query `FullName` only when the result contains ≤ 1 record
- If more than one record is possible, break into multiple targeted queries

---

## Metadata Deployment Security Notes

- All feature flags in `IndustriesManufacturingSettings` default to `false` and must be explicitly enabled
- Wildcard character `*` in `package.xml` does NOT work for most Manufacturing Cloud settings metadata types
- Exception: `MfgServiceConsoleSettings` and `WarrantyLifeCycleMgmtSettings` do support wildcard retrieval

---

## Invocable Action Data Security

Manufacturing Cloud invocable actions operate with the running user's permissions. Key actions that write permanent data:

| Action | Data Written | Warning |
|---|---|---|
| `refreshActualsCalculation` | Updates `SalesAgreementProductSchedule` actuals | Permanent — database rollback required to undo |
| `massUpdateSalesAgreement` | Updates SA product/period fields in bulk | Permanent — no rollback |
| `massUpdateForecast` / `massUpdateAdvAccountForecast` | Updates forecast period values | Permanent — no rollback |
| `calculateAdvancedAccountForecasts` | Recalculates `AdvAccountForecastFact` records | Triggered async — check status before re-running |
| `importRecordsFromCsvFile` | Upserts or inserts forecast records from CSV | Permanent — validate CSV before invocation |

**Recommendation:** Build approval/confirmation gates in Flow before invoking any mass-update or actuals-calculation action. These actions are explicitly documented as non-reversible without a full database rollback.

---

## API Authentication

Manufacturing Cloud APIs use standard Salesforce OAuth 2.0 authentication. All endpoints require:
```
Authorization: Bearer {access_token}
```

The connected app / integration user must have:
- The appropriate Manufacturing Cloud license
- The relevant module permission set(s)
- Object-level CRUD permissions for the objects being read/written

---

## Persona → Permission Set Mapping (Recommended)

| Persona | Recommended Permission Sets |
|---|---|
| Sales Manager | Manufacturing Sales Agreements + Manufacturing Advanced Account Forecast |
| Account Manager | Manufacturing Sales Agreements + Manufacturing Advanced Account Forecast |
| Operations / Planning | Manufacturing Advanced Account Forecast + Manufacturing Program Based Business |
| Field Service Representative | Manufacturing Cloud license + MfgServiceConsoleSettings |
| Finance / Rebates | Manufacturing Cloud license (rebate objects) |
| Integration User (ERP sync) | Manufacturing Sales Agreements + Manufacturing Program Based Business + API-Only User |
| Admin / Setup | System Administrator + all Manufacturing Cloud permission sets |
