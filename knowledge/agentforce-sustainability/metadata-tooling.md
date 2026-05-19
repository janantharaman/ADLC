# Agentforce Sustainability (Net Zero Cloud) — Metadata Tooling

## What Is and Isn't Deployable

Net Zero Cloud is delivered as a **managed package**. The package components themselves are not in your org's deployable metadata. Only your customisations on top of the package are deployable.

| Component | Deployable | Notes |
|---|---|---|
| Custom fields on NZC objects | Yes | Standard `CustomField` metadata |
| Validation rules | Yes | Standard `ValidationRule` metadata |
| Flows (record-triggered, auto-launched) | Yes | Standard `Flow` metadata |
| Apex classes/triggers | Yes | Standard Apex metadata |
| Permission sets (custom) | Yes | Do not deploy managed permission sets |
| Report types and reports | Yes | Standard report metadata |
| CRM Analytics dashboards + recipes | Yes | `WaveApplication`, `WaveDashboard`, etc. |
| EmissionFactor / EmissionFactorSet records | No | Data records — load via Data Loader or API |
| OrganisationUnit records | No | Data records |
| SustainabilityGoal records | No | Data records |
| Experience Cloud site configuration | Partial | Site structure yes; credentials no |
| Managed package components (CarbonFootprint object itself) | No | Comes with package install |

---

## SFDX Commands

### Retrieve custom configuration from org
```bash
# Retrieve all customisations on Net Zero Cloud objects
sf project retrieve start \
  --metadata "CustomField:CarbonFootprint.DataQualityIndicator__c" \
  --metadata "ValidationRule:CarbonFootprint.RequireDataQualityIndicator" \
  --metadata "Flow:Create_Carbon_Footprint_From_Utility" \
  --metadata "PermissionSet:NZC_Custom_Admin"

# Retrieve CRM Analytics assets
sf project retrieve start \
  --metadata "WaveApplication:Net_Zero_Sustainability" \
  --metadata "WaveDashboard:Climate_Action_Dashboard"
```

### Deploy to production (with test run)
```bash
sf project deploy start \
  --source-dir force-app/main/default \
  --test-level RunLocalTests \
  --dry-run
```

### Validate Net Zero Cloud package version
```bash
sf package installed list --target-org YOUR_ORG_ALIAS
```

---

## Managed Package Version Management

Net Zero Cloud releases follow Salesforce's standard 3-release-per-year cadence (Spring, Summer, Winter). Each release may include:
- New standard fields on `CarbonFootprint` or other objects
- New or updated validation rules within the managed package
- New permission set assignments
- Updated Emission Factor datasets on Net Zero Marketplace

**Before upgrading:**
1. Review the Net Zero Cloud release notes on help.salesforce.com
2. Install the new package version in a sandbox
3. Run all custom flows, triggers, and tests
4. Verify CRM Analytics dashboards still render correctly
5. Check that custom fields and validation rules did not conflict with new managed components

---

## Data Loading for Emission Factors

Emission factors are data records, not metadata. Load them via:

### Option 1: Net Zero Marketplace (recommended)
Purchase and install factor datasets directly within Net Zero Cloud Setup. Automatically creates `EmissionFactorSet` and `EmissionFactor` records.

### Option 2: Data Loader / Bulk API (custom factors)
For proprietary or industry-specific factors not available in the Marketplace:

```bash
# Using Salesforce CLI data import
sf data import bulk \
  --sobject EmissionFactorSet \
  --file emission_factor_sets.csv \
  --target-org YOUR_ORG_ALIAS

sf data import bulk \
  --sobject EmissionFactor \
  --file emission_factors.csv \
  --target-org YOUR_ORG_ALIAS
```

**CSV template for EmissionFactor:**
```
Name,EmissionFactorSet__c,ActivityType__c,CO2Factor__c,Unit__c,Region__c,EffectivePeriodStartDate__c,EffectivePeriodEndDate__c
"Electricity UK Grid 2024","UK DEFRA 2024","Purchased Electricity",0.20493,"kWh","UK","2024-01-01","2024-12-31"
```

---

## Headless 360 (MCP) Usage for Net Zero Cloud

Use `mcp__salesforce__run_soql_query` to query Net Zero Cloud objects directly during discovery and implementation phases:

```sql
-- Check what emission sources exist in the org
SELECT Id, Name, Category__c, Scope__c, OrganisationUnit__r.Name
FROM EmissionSource
ORDER BY Scope__c, Category__c

-- Check data completeness for current year
SELECT Scope__c, COUNT(Id) RecordCount, SUM(TotalEmissions__c) TotalCO2e,
       COUNT_DISTINCT(EmissionSource__c) Sources
FROM CarbonFootprint
WHERE CALENDAR_YEAR(ReportingPeriodEndDate__c) = 2025
GROUP BY Scope__c
```

Use `mcp__salesforce__retrieve_metadata` to pull custom configuration:
```json
{
  "metadataType": "Flow",
  "folder": "force-app/main/default/flows"
}
```

Use `mcp__salesforce__deploy_metadata` with `checkOnly: true` for validation before production deployment.

---

## Version Control Conventions

```
force-app/main/default/
  customMetadata/          ← custom metadata type records (if used for config)
  fields/
    CarbonFootprint.CustomField1__c.field-meta.xml
  flows/
    Create_CarbonFootprint_From_Utility.flow-meta.xml
  permissionsets/
    NZC_Custom_Admin.permissionset-meta.xml
  validationRules/
    CarbonFootprint.RequireDataQualityIndicator.validationRule-meta.xml
  wave/                    ← CRM Analytics assets
    Climate_Action_Dashboard.waveapplication-meta.xml
```

Data load scripts and CSV templates for emission factors should live in:
```
engagements/{customer}/docs/
  nzc-data-load/
    emission-factor-sets.csv
    emission-factors-uk-defra-2024.csv
    organisation-units.csv
    data-load-runbook.md
```

---

## Monitoring

| What | Where |
|---|---|
| Package version | Setup → Installed Packages |
| Data load job history | Setup → Bulk Data Load Jobs |
| Flow errors | Setup → Flow Errors |
| CRM Analytics sync status | Analytics Studio → Data Manager |
| Supplier portal activity | Experience Cloud → Site Administration |
