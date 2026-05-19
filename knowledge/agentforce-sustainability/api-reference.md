# Agentforce Sustainability (Net Zero Cloud) — API Reference

## API Access Pattern

Net Zero Cloud objects are standard Salesforce objects — accessible via the same Salesforce REST API, SOAP API, Bulk API, and SOQL as any other org object. There is no separate Net Zero Cloud API endpoint.

**Base URL:** `https://{your-instance}.salesforce.com/services/data/v{api-version}/`

Authentication is via the same OAuth 2.0 flows used for all Salesforce APIs.

---

## Key SOQL Queries

### Total Emissions by Scope (current year)
```sql
SELECT Scope__c, SUM(TotalEmissions__c) TotalCO2e
FROM CarbonFootprint
WHERE CALENDAR_YEAR(ReportingPeriodEndDate__c) = 2025
GROUP BY Scope__c
```

### Top 10 Emission Sources by CO2e
```sql
SELECT EmissionSource__r.Name, SUM(TotalEmissions__c) TotalCO2e
FROM CarbonFootprint
WHERE CALENDAR_YEAR(ReportingPeriodEndDate__c) = 2025
GROUP BY EmissionSource__r.Name
ORDER BY TotalCO2e DESC
LIMIT 10
```

### Footprints Missing Data Quality Indicator
```sql
SELECT Id, Name, OrganisationUnit__r.Name, TotalEmissions__c
FROM CarbonFootprint
WHERE DataQualityIndicator__c = NULL
AND CALENDAR_YEAR(ReportingPeriodEndDate__c) = 2025
```

### Active Emission Factors for a Given Period
```sql
SELECT Id, ActivityType__c, CO2Factor__c, Unit__c, Region__c
FROM EmissionFactor
WHERE EmissionFactorSet__r.Name = 'UK DEFRA 2024'
AND EffectivePeriodStartDate__c <= 2025-12-31
AND (EffectivePeriodEndDate__c = NULL OR EffectivePeriodEndDate__c >= 2025-01-01)
```

### Progress Against Sustainability Goal
```sql
SELECT 
    sg.Name,
    sg.TargetYear__c,
    sg.ReductionTarget__c,
    SUM(cf.TotalEmissions__c) CurrentEmissions
FROM SustainabilityGoal sg
LEFT JOIN CarbonFootprint cf ON cf.SustainabilityGoal__c = sg.Id
WHERE sg.Status__c = 'Active'
GROUP BY sg.Name, sg.TargetYear__c, sg.ReductionTarget__c
```

---

## REST API — Create Carbon Footprint Record

```
POST /services/data/v66.0/sobjects/CarbonFootprint
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "Name": "Electricity - London HQ - Jan 2025",
  "EmissionSource__c": "a0B000000xxxxxxx",
  "OrganisationUnit__c": "a0C000000xxxxxxx",
  "Scope__c": "Scope2",
  "EmissionCategory__c": "Purchased Electricity",
  "ActivityData__c": 15420,
  "ActivityDataUnit__c": "kWh",
  "TotalEmissions__c": 3592.86,
  "EmissionFactor__c": "a0D000000xxxxxxx",
  "CalculationMethod__c": "Activity-Based",
  "DataQualityIndicator__c": "Measured",
  "ReportingPeriodStartDate__c": "2025-01-01",
  "ReportingPeriodEndDate__c": "2025-01-31"
}
```

---

## Bulk API — Loading Historical Footprint Data

For initial historical loads (multiple years of Carbon Footprint records), use the Bulk API v2:

```
POST /services/data/v66.0/jobs/ingest
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "object": "CarbonFootprint",
  "contentType": "CSV",
  "operation": "insert",
  "lineEnding": "LF"
}
```

Upload CSV:
```
POST /services/data/v66.0/jobs/ingest/{jobId}/batches
Content-Type: text/csv

Name,EmissionSource__c,Scope__c,TotalEmissions__c,...
"Elec - Jan 2024","a0Bxxx","Scope2",3200,...
```

---

## Metadata API — Deploying Net Zero Cloud Configuration

Net Zero Cloud custom fields, validation rules, flows, and report types are deployable via standard Metadata API.

Managed package components (standard objects like `CarbonFootprint`, `EmissionFactor`) are **not** included in your org's deployable metadata — they come with the package. Only your customisations on top are deployable.

### Retrieve custom configuration
```bash
sf project retrieve start \
  --metadata CustomObject:CarbonFootprint__c \
  --metadata Flow:Create_CarbonFootprint_from_Utility_Bill \
  --metadata ValidationRule:CarbonFootprint.RequireDataQualityIndicator
```

### Deploy to production
```bash
sf project deploy start \
  --source-dir force-app/main/default \
  --test-level RunLocalTests
```

---

## CRM Analytics API (for Dashboard Automation)

If Net Zero Cloud dashboards are built in CRM Analytics, use the CRM Analytics REST API to:
- Trigger Dataset refreshes after bulk footprint uploads
- Fetch dashboard data for external reporting
- Embed dashboards in external portals via the Analytics Embedding API

```
POST /services/data/v66.0/wave/dataflowjobs
Content-Type: application/json

{
  "dataflowId": "02K000000xxxxxxx",
  "command": "start"
}
```

---

## Useful Object API Names Reference

| Label | API Name | Notes |
|---|---|---|
| Carbon Footprint | `CarbonFootprint` | Central emissions record |
| Emission Source | `EmissionSource` | What generates emissions |
| Emission Factor | `EmissionFactor` | Conversion rate |
| Emission Factor Set | `EmissionFactorSet` | Factor dataset |
| Sustainability Goal | `SustainabilityGoal` | Net zero target |
| Sustainability Programme | `SustainabilityProgramme` | Reduction initiative |
| Value Chain Partner | `ValueChainPartner` | Scope 3 supplier/subsidiary |
| Partner Footprint | `PartnerFootprint` | Scope 3 submitted data |
| Disclosure | `Disclosure` | ESG report instance |

> Note: Exact API names vary slightly by Net Zero Cloud version. Always verify via `sf org list metadata` or Schema Builder in the target org before building integrations.
