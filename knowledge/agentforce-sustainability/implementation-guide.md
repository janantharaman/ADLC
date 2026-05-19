# Agentforce Sustainability (Net Zero Cloud) — Implementation Guide

## Pre-Implementation Checklist

- [ ] Net Zero Cloud licence confirmed and provisioned (`Setup → Company Information → Licenses`)
- [ ] GHG Protocol scope categories agreed with sustainability team (which Scope 3 categories are in scope)
- [ ] Reporting frameworks confirmed (CSRD mandatory? GRI? CDP voluntary?)
- [ ] Base year and net zero target year agreed
- [ ] Organisation hierarchy documented (which entities, subsidiaries, divisions are in scope)
- [ ] Data sources inventoried (which utility providers, travel systems, fleet systems, ERPs)
- [ ] Emission factor sources agreed (UK DEFRA? US EPA? Custom industry factors?)
- [ ] Scope 3 supplier engagement scope agreed (all suppliers vs material spend threshold)
- [ ] CRM Analytics licence confirmed if advanced dashboards are required
- [ ] MuleSoft availability confirmed for third-party data ingestion
- [ ] Assurance requirements confirmed (none / limited / reasonable assurance for CSRD)

---

## Phase 1: Foundation Setup (Days 1–5)

### Step 1: Enable Net Zero Cloud

1. Install the Net Zero Cloud managed package from AppExchange
2. Run the Setup Assistant: `Setup → Net Zero Cloud Setup`
3. Assign permission sets:
   - `Net Zero Cloud Admin` → sustainability leads and implementation team
   - `Net Zero Cloud User` → data entry users and sustainability managers
   - `Net Zero Cloud Report Viewer` → executives and auditors

### Step 2: Configure Organisation Hierarchy

1. Create `OrganisationUnit` records for each entity in scope
2. Set parent-child relationships to reflect the legal/operational structure
3. Assign each unit a `Boundary` (Operational Control, Financial Control, or Equity Share) — this determines which emissions you are required to report
4. Align the hierarchy with the customer's consolidation boundary used for financial reporting

### Step 3: Set Up Emission Factor Sets

1. Purchase or import emission factor datasets from Net Zero Marketplace, or upload custom factors
2. Create `EmissionFactorSet` records named by standard + year (e.g., "UK DEFRA 2024", "US EPA eGRID 2024")
3. Create `EmissionFactor` records under each set for every activity type relevant to the customer's operations
4. Set `EffectivePeriod` dates — factors must be period-specific for historical accuracy

---

## Phase 2: Emission Sources and Data Mapping (Days 5–15)

### Step 4: Create Emission Sources

Create an `EmissionSource` record for every distinct source in scope:
- Each building (for energy/heat)
- Each vehicle fleet
- Each business travel category
- Each Scope 3 category being tracked

**Naming convention:** `{Entity} - {Source Type} - {Location}` e.g., "London HQ - Electricity - UK Grid"

### Step 5: Map Data Sources

For each Emission Source, document:
| Emission Source | Data Source | Frequency | Integration Method | Owner |
|---|---|---|---|---|
| London HQ Electricity | EDF Energy API | Monthly | MuleSoft | Facilities |
| Business Air Travel | Concur API | Quarterly | MuleSoft | HR |
| Fleet Vehicle Fuel | Telematics CSV | Monthly | Bulk API | Fleet Mgmt |

### Step 6: Build Data Ingestion Flows

For each data source:
1. Build or configure the integration (MuleSoft flow, CSV upload template, or manual entry screen flow)
2. Map source fields to `CarbonFootprint` object fields
3. Implement emission factor lookup logic (match by activity type, region, and period)
4. Set `DataQualityIndicator` based on data quality (Measured for metered data, Estimated for calculated, Default for industry averages)
5. Test with one month of data before full historical load

---

## Phase 3: Historical Data Load (Days 15–25)

### Step 7: Load Base Year Data

Load at minimum the base year (typically 2019 or 2021) plus the most recent complete year:
1. Export historical data from source systems into CSV templates
2. Map to `CarbonFootprint` fields — one record per emission source per reporting period
3. Load via Bulk API (`sf data import bulk --sobject CarbonFootprint --file historical_data.csv`)
4. Validate totals against existing sustainability reports if available

### Step 8: Validate Scope Totals

After load, run SOQL validation queries:
```sql
-- Confirm totals match expected values from prior reports
SELECT Scope__c, CALENDAR_YEAR(ReportingPeriodEndDate__c) Year,
       SUM(TotalEmissions__c) TotalCO2e
FROM CarbonFootprint
GROUP BY Scope__c, CALENDAR_YEAR(ReportingPeriodEndDate__c)
ORDER BY Year
```

Discrepancies > 2% versus prior reported values require investigation before proceeding.

---

## Phase 4: Sustainability Goals and Programmes (Days 25–30)

### Step 9: Configure Sustainability Goals

1. Create the primary `SustainabilityGoal` (e.g., Net Zero by 2040, 50% reduction by 2030)
2. Set `BaselineYear`, `TargetYear`, `ReductionTarget`, and target scope
3. The goal baseline emissions are calculated from Carbon Footprint records in the base year

### Step 10: Create Sustainability Programmes

For each planned initiative:
1. Create a `SustainabilityProgramme` record linked to the goal
2. Set `ExpectedEmissionsReduction` (tCO₂e), `MarginalAbatementCost` (£/tCO₂e), and expected delivery timeline
3. Run Programme Analysis to generate the marginal abatement cost curve

---

## Phase 5: Scope 3 Supplier Engagement (Days 30–45, if in scope)

### Step 11: Configure the Scope 3 Emissions Hub

1. Enable Experience Cloud and create the supplier portal site
2. Assign `Net Zero Cloud External User` permission set to partner contacts
3. Configure OmniScript forms for each Scope 3 category being collected
4. Set up `ValueChainPartner` records for each supplier/subsidiary in scope
5. Test submission flow end-to-end with a pilot supplier before broad rollout

### Step 12: Supplier Outreach and Onboarding

1. Send portal access invitations via automated email (use Salesforce Email Templates + Flow)
2. Include submission deadline, data requirements, and calculation guidance
3. Configure reminder flows at 4 weeks, 2 weeks, and 1 week before deadline
4. Assign a sustainability team member as point of contact for supplier queries

---

## Phase 6: Reporting and Dashboards (Days 45–55)

### Step 13: Configure Climate Action Dashboard

1. Deploy CRM Analytics Data Sync for `CarbonFootprint`, `SustainabilityGoal`, and `SustainabilityProgramme`
2. Build Recipe: aggregate by scope, category, organisation unit, month, and year
3. Schedule nightly Recipe refresh
4. Build and publish the Climate Action Dashboard

### Step 14: Configure ESG Disclosure Reports

1. Navigate to `Net Zero Cloud → Disclosures → New`
2. Select the target framework (CSRD, GRI, SASB, CDP)
3. Map `CarbonFootprint` aggregate data to the framework's disclosure topics
4. Configure Agentforce ESG Authoring (if licensed) for narrative draft generation
5. Test the report generation with current year data

---

## Deployment Considerations

### What is deployable
- Custom fields on Net Zero Cloud objects
- Validation rules
- Flows and Apex triggers
- Report types and report folders
- CRM Analytics dashboards and recipes
- Permission set assignments (as permission set groups)

### What must be manually configured in each org
- `EmissionFactor` and `EmissionFactorSet` records (data, not metadata)
- `OrganisationUnit` hierarchy
- `SustainabilityGoal` and `SustainabilityProgramme` records
- Experience Cloud site configuration
- Connected App credentials for third-party integrations

### Sandbox strategy
- Sandbox refresh does not include emission factor data — maintain a data load script to re-populate factors
- Do not use real supplier contact data in sandbox — use synthetic records
- Test all managed package upgrades in sandbox before production deployment
