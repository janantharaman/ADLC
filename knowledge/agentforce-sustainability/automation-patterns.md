# Agentforce Sustainability (Net Zero Cloud) — Automation Patterns

## Pattern 1: Automated Carbon Footprint Creation from Utility Bills

**Use case:** Monthly electricity/gas/water invoices → automatic Carbon Footprint records without manual data entry.

**Implementation:**
1. Configure MuleSoft or an API connector to receive utility invoice data (from ERP, utility portal API, or email-parsed CSV)
2. Create a Flow (Screen Flow or Auto-launched) that:
   - Looks up the relevant `EmissionSource` by building/meter ID
   - Looks up the active `EmissionFactor` for the fuel type, region, and billing period
   - Creates a `CarbonFootprint` record with calculated CO₂e = `ActivityData × EmissionFactor.CO2Factor`
   - Sets `DataQualityIndicator` = `Measured`
3. Attach the invoice file as a Salesforce File (`ContentDocumentLink`) on the `CarbonFootprint` record

**Key decision:** Use activity-based calculation (kWh × factor) rather than spend-based (£ × factor) wherever possible — activity-based is more accurate and preferred for CSRD assurance.

---

## Pattern 2: Business Travel Emissions via Expense System Integration

**Use case:** Employee expense claims for flights, hotels, and ground transport → automatic Scope 3 Category 6 footprints.

**Implementation:**
1. Connect to expense management system (Concur, Expensify) via MuleSoft or REST API
2. Map expense line items to Net Zero Cloud emission categories:
   - Air travel → distance-based calculation using origin/destination city pair
   - Hotel stays → nights × emission factor per hotel category
   - Ground transport → km × mode-specific factor
3. Flow creates `CarbonFootprint` records under `EmissionSource` = Business Travel
4. Quarterly roll-up report confirms total Scope 3 Cat 6

**Distance-based travel note:** Net Zero Cloud includes built-in distance calculation for air travel using IATA city codes. Use this rather than spend-based for more accurate reporting.

---

## Pattern 3: Scope 3 Supplier Data Collection via External Portal

**Use case:** Collect GHG data from hundreds of suppliers without requiring them to have Salesforce access.

**Implementation:**
1. Create Experience Cloud site with `Net Zero Cloud External User` licence
2. Build OmniScript guided flow for supplier data submission (annual activity data by category)
3. Submitted data lands as `PartnerFootprint` records in the hub org
4. Approval Flow: Sustainability team reviews and approves/rejects each submission
5. On approval, Flow creates `CarbonFootprint` records from the approved `PartnerFootprint`
6. Reminder Flow: auto-email suppliers who haven't submitted after X days

**Scope 3 Hub alternative:** Use the built-in Scope 3 Emissions Hub if licensed — it provides the guided data collection UI, validation rules, and aggregation without custom OmniScript development.

---

## Pattern 4: What-If Analysis for Net Zero Roadmap

**Use case:** Model different emission reduction scenarios (e.g., 50% renewable energy by 2027 vs 80% by 2030) and forecast progress against the net zero target.

**Built-in capability:** The What-If Analysis module is configured in the UI — no code required:
1. Create a `SustainabilityGoal` with baseline year, target year, and reduction target
2. Create `SustainabilityProgramme` records for each initiative with expected reduction and cost
3. What-If Analysis tool projects the combined impact across all programmes
4. Programme Analysis compares initiatives by marginal abatement cost curve

**Custom extension:** If more complex scenario modelling is needed (Monte Carlo simulation, different growth assumptions), feed Net Zero Cloud data into CRM Analytics using a Data Sync and build custom SAQL-based scenario analyses.

---

## Pattern 5: Emission Factor Update Automation

**Use case:** Government emission factors are updated annually (e.g., UK DEFRA publishes new factors each June). All historical and future footprints must use the correct factor for the year.

**Implementation:**
1. Create a new `EmissionFactor` record with updated values and an `EffectivePeriod` start date
2. Do NOT delete or edit the old factor — historical Carbon Footprint records must remain auditable with the factor that was current at the time
3. Flow on `CarbonFootprint` creation: look up the factor with `EffectivePeriod` covering the `ReportingPeriod` end date
4. Annual batch job: re-calculate Carbon Footprint records for the current year using the newly published factors (prior year records remain locked)

---

## Pattern 6: CRM Analytics Dashboard Automation

**Use case:** Executive sustainability dashboard showing month-over-month emissions by scope, progress against targets, and top emission sources — refreshed daily.

**Implementation:**
1. Create a CRM Analytics Data Sync from `CarbonFootprint`, `SustainabilityGoal`, and `SustainabilityProgramme`
2. Build a Recipe to aggregate by scope, category, organisation unit, and month
3. Schedule Recipe refresh nightly
4. Build dashboard with KPIs: total CO₂e, % vs target, scope breakdown, top 10 sources
5. Embed dashboard in Net Zero Cloud home page via Lightning App Builder

---

## Pattern 7: Agentforce ESG Report Drafting

**Use case:** Automatically draft the narrative sections of a CSRD or GRI report using Agentforce, populated with live data from Net Zero Cloud.

**How it works:**
1. Agentforce ESG Authoring agent is configured with access to `CarbonFootprint`, `SustainabilityGoal`, and `Disclosure` records
2. User prompts the agent: "Draft the GHG emissions section for our 2025 CSRD report"
3. Agent queries the relevant Carbon Footprint records, formats them per the CSRD template, and generates a narrative draft
4. Draft is created in the `Disclosure` record and pushed to Microsoft Word via the M365 plug-in for human review and editing
5. User identifies flagged missing data points and completes them before final submission

**Governance note:** Agentforce-drafted content must be reviewed and approved by a human sustainability officer before submission to any regulatory body. Never auto-submit AI-drafted ESG disclosures.
