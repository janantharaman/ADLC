# Agentforce Sustainability (Net Zero Cloud) — Gotchas

## Data Model and Calculation

**1. Changing an Emission Factor recalculates nothing automatically**
Editing `EmissionFactor.CO2Factor` does NOT retroactively update linked `CarbonFootprint.TotalEmissions` records. Historical footprints are stored as point-in-time snapshots. If you need to restate historical data with updated factors, run a batch job to recalculate and update affected records — and document the restatement clearly for auditors.

**2. Emission Factor Set version management is manual**
There is no built-in versioning workflow for Emission Factor Sets. When annual factors are published (e.g., UK DEFRA), you must create new `EmissionFactor` records with new `EffectivePeriod` values. If you overwrite existing factor values, you lose the audit trail. Always create new records, never edit existing ones.

**3. Location-based vs market-based Scope 2 — you need two calculation runs**
CSRD and GHG Protocol Scope 2 reporting requires both location-based (grid average factor) and market-based (supplier-specific or residual mix) calculations. Net Zero Cloud stores one value per Carbon Footprint record. You need separate records or a custom field to hold both calculations — decide your data model approach before initial data entry.

**4. Total emissions field is not a roll-up**
`CarbonFootprint.TotalEmissions` is a stored number, not a roll-up summary. Reporting totals (total Scope 1, total org emissions) must be calculated in a report, CRM Analytics dashboard, or SOQL query. Do not display raw `TotalEmissions` fields as org totals on a dashboard — they represent individual footprint records, not aggregates.

**5. Data Quality Indicator is not enforced by default**
`DataQualityIndicator` (Measured / Estimated / Default) is a picklist field but is not required by default. For CSRD assurance, this field must be populated on every record. Add a validation rule to enforce it before going live, or every record ingested via API without this field will fail the assurance review.

---

## Scope 3 and Partner Data

**6. Scope 3 Hub external portal requires Experience Cloud licence**
The Supplier/Subsidiary data collection portal is built on Experience Cloud. Partner users need an Experience Cloud licence (Customer Community or Partner Community). This is an additional cost on top of the Net Zero Cloud licence — budget for it during discovery.

**7. Supplier-submitted data is not automatically trusted**
`PartnerFootprint` records submitted by suppliers must go through an approval process before being converted to `CarbonFootprint` records. Skipping the approval step means unvalidated data lands directly in your ESG reports. Always configure an approval flow with a sustainability team reviewer.

**8. Scope 3 Category 11 (Use of Sold Products) is hardest to collect**
This category requires knowing how customers use your products and their associated emissions. Most organisations default to spend-based or average-data approaches for Cat 11. Flag this during discovery — customers often underestimate the effort required and it can significantly inflate reported Scope 3.

---

## Reporting and Compliance

**9. CSRD data model mapping requires custom configuration**
The CSRD Data Model feature maps Net Zero Cloud fields to CSRD disclosure requirements. However, some CSRD data points (biodiversity, social topics) are not covered by standard Net Zero Cloud objects and require custom objects or fields. Scope the full CSRD data gap before project kick-off.

**10. Agentforce-drafted ESG content is not submission-ready**
AI-generated report drafts require human review, factual verification, and sign-off from a sustainability officer or CFO before regulatory submission. Treat the AI output as a first draft, not a final document. Build the review and approval step into the project plan.

**11. Framework requirements change — your report templates will too**
CSRD, GRI, and SASB requirements are updated regularly. Net Zero Cloud's framework templates are updated in Salesforce releases, but custom report templates built outside the managed package will not auto-update. Assign someone to review framework updates each year and update custom templates accordingly.

**12. CDP reporting requires a separate CDP platform submission**
Net Zero Cloud helps prepare CDP data, but final submission goes to the CDP platform (cdp.net) directly — it is not automated from Salesforce. Build manual export and submission steps into the reporting timeline.

---

## Integration and Architecture

**13. Multi-org aggregation requires custom integration**
If a customer has emissions data in multiple Salesforce orgs (Sales, Service, ERP), there is no native multi-org aggregation. You need MuleSoft or a custom API integration to collect Carbon Footprint records from satellite orgs and consolidate them in a central sustainability org. Plan this architecture during discovery.

**14. MuleSoft is required for most third-party data ingestion**
Utility APIs, fleet telematics, travel management platforms, and ERP systems rarely have native Salesforce connectors. MuleSoft Anypoint Platform (now Salesforce Integration) is the recommended and supported path. If the customer doesn't have MuleSoft, budget for either a MuleSoft licence or custom Apex REST integrations with associated maintenance overhead.

**15. CRM Analytics for Net Zero Cloud is a separate SKU**
The Climate Action Dashboard and programme analysis reports that use CRM Analytics require a separate CRM Analytics licence. Basic Net Zero Cloud includes standard Salesforce reports and dashboards only. Confirm which dashboards the customer expects during discovery and check their licence entitlements.

---

## Deployment

**16. Net Zero Cloud managed package upgrades can break custom extensions**
Net Zero Cloud is delivered as a managed package. Platform upgrades may change object structures, validation rules, or permission set assignments in ways that affect custom flows, triggers, or LWCs built on top. Always test managed package upgrades in a sandbox before deploying to production.

**17. Sandbox does not include emission factor data**
A sandbox refresh copies the org's metadata and configuration but does not include the Net Zero Marketplace emission factor datasets. You need to either re-purchase/install factor data in the sandbox, or use a reduced test dataset. Plan for this in your testing strategy.
