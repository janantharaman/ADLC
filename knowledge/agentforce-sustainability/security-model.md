# Agentforce Sustainability (Net Zero Cloud) — Security Model

## Permission Sets

Net Zero Cloud ships with managed permission sets. Clone and extend — never modify managed sets directly.

| Permission Set | Role |
|---|---|
| `Net Zero Cloud Admin` | Full access: configure emission sources, factors, goals, programmes, reporting |
| `Net Zero Cloud User` | Read/create carbon footprints; view dashboards; cannot configure emission factors or rulesets |
| `Net Zero Cloud Report Viewer` | Read-only: view dashboards and reports; cannot create or edit records |
| `Net Zero Cloud External User` (Community) | For Value Chain Partners submitting Scope 3 data via Experience Cloud portal |

> Assign `Net Zero Cloud Admin` sparingly — it includes the ability to modify Emission Factor Sets, which directly affects all calculated footprints across the org.

---

## Object-Level Security

Net Zero Cloud objects follow standard Salesforce CRUD/FLS patterns:

- `CarbonFootprint` — typically Read/Edit for sustainability users; Create for data entry users
- `EmissionFactor` and `EmissionFactorSet` — Read for most users; Edit restricted to admins only (changing factors recalculates all linked footprints)
- `SustainabilityGoal` — Read for all sustainability users; Create/Edit restricted to programme managers and above
- `ValueChainPartner` — Read/Edit for sustainability leads; limited to own partner records for external users

---

## Sharing Model

### Organisation Hierarchy and Data Access

Carbon footprints and emission sources are typically shared by the organisation unit hierarchy. A sustainability manager for a regional division should see their division's data but not other regions. Configure:

1. Create a custom sharing rule based on `OrganisationUnit` hierarchy
2. Or use Territory Management if the org already has territories configured

### External Partner Access (Scope 3 Hub)

Value Chain Partners submit data through an **Experience Cloud portal** (not directly into the Salesforce org UI). Configure:

- Experience Cloud site with `Customer Community Plus` or `Partner Community` licence
- `Net Zero Cloud External User` permission set assigned to partner contacts
- Object permissions: Create/Read on `PartnerFootprint`; no access to internal `CarbonFootprint` records
- Field-level security: exclude internal cost and financial fields from partner-visible field sets

---

## Data Residency and Encryption

- All Net Zero Cloud data is stored within the Salesforce org's standard data storage — no separate data lake
- Shield Platform Encryption can be applied to PII fields on `ValueChainPartner` if required
- Carbon Footprint records themselves are not PII and do not require Shield encryption in most implementations
- Hyperforce region selection applies at the org level — the same residency configuration as the rest of the org

---

## Audit and Compliance Considerations

### Data Auditability
Emission factors and calculation methods must be auditable for ESG assurance (third-party audit of sustainability reports). Configure:

- **Field History Tracking** on `CarbonFootprint.EmissionFactor`, `CarbonFootprint.TotalEmissions`, and `EmissionFactor.CO2Factor`
- **Setup Audit Trail** to capture admin changes to Emission Factor Sets
- Do NOT use rollup fields for audited totals — use explicit CarbonFootprint records so auditors can trace each calculation

### CSRD Assurance Readiness
CSRD requires "limited assurance" initially, moving to "reasonable assurance" by 2028. For assurance readiness:
- Each Carbon Footprint record must have `DataQualityIndicator` populated (Measured > Estimated > Default)
- Source documentation (utility invoices, travel records) should be linked as Salesforce Files on the Carbon Footprint record
- Calculation methodology must be documented — use the `Notes` field or a related `ContentNote`

---

## Multi-Org Security Considerations

For enterprises with multiple Salesforce orgs (hub-and-spoke Scope 3 model):
- Hub org aggregates footprints from spoke orgs via API or MuleSoft
- Spoke orgs expose read-only `CarbonFootprint` data via Connected App
- Hub org users must not have write access to spoke org records
- Use a dedicated integration user in each spoke org with minimum permissions (`Net Zero Cloud Report Viewer` + API access)
