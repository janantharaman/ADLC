# Agentforce Public Sector (Public Sector Solutions) — Metadata Tooling

## What Is and Isn't Deployable

PSS is delivered as a **managed package**. The package components (standard objects like `ProgramEnrollment`, `BenefitProgram`) are not in your org's deployable metadata. Only your customisations on top of the package are deployable.

| Component | Deployable | Notes |
|---|---|---|
| Custom fields on PSS objects | Yes | Standard `CustomField` metadata |
| Validation rules | Yes | Standard `ValidationRule` metadata |
| Flows (record-triggered, auto-launched, screen) | Yes | Standard `Flow` metadata |
| Apex classes/triggers | Yes | Standard Apex metadata |
| Permission sets (custom) | Yes | Do not deploy managed permission sets |
| Report types and reports | Yes | Standard report metadata |
| CRM Analytics dashboards + recipes | Yes | `WaveApplication`, `WaveDashboard`, etc. |
| Decision Matrix rows | No | Data records — load via Data Loader or script |
| BenefitProgram / FundingSource records | No | Data records — load per org |
| OmniStudio components | Partial | Export/import JSON; or use OmniStudio MCP |
| Experience Cloud site structure | Partial | Page layouts yes; credentials no |
| Managed package components (ProgramEnrollment object itself) | No | Comes with package install |
| Queue and routing configuration | No | Manual per-org config |

---

## OmniStudio Deployment — Special Handling Required

OmniStudio components (OmniScripts, FlexCards, DataRaptors, Integration Procedures) are **stored as records**, not as metadata files in `force-app/`. They cannot be deployed with standard `sf project deploy`.

### Option 1: OmniStudio MCP (recommended)
Use the OmniStudio MCP tools during implementation:
```
mcp__omnistudio-mcp__os_create    ← push OmniScript JSON to org
mcp__omnistudio-mcp__fc_create    ← push FlexCard JSON to org
mcp__omnistudio-mcp__dm_create    ← push DataRaptor JSON to org
```

### Option 2: IDX Workbench (bulk export/import)
For bulk migration of many components:
1. In source org: `OmniStudio → OmniStudio Export → IDX Workbench → Export All`
2. Download the export ZIP
3. In target org: `OmniStudio → OmniStudio Import → IDX Workbench → Import`

**Import order within IDX Workbench:**
1. DataRaptors first
2. Integration Procedures
3. OmniScripts
4. FlexCards

Importing in the wrong order causes broken references at runtime.

### Option 3: Manual JSON export/import
For individual components:
1. Source org: OmniStudio Designer → Open component → Export JSON
2. Target org: OmniStudio Designer → New → Import JSON

---

## SFDX Commands

### Retrieve custom configuration from org
```bash
# Retrieve custom extensions on PSS objects
sf project retrieve start \
  --metadata "CustomField:ProgramEnrollment.EligibilityStatus__c" \
  --metadata "ValidationRule:ProgramEnrollment.RequireEligibilityCheck" \
  --metadata "Flow:AssignCaseWorkerOnEnrollment" \
  --metadata "PermissionSet:PSS_Custom_CaseWorker"

# Retrieve CRM Analytics assets
sf project retrieve start \
  --metadata "WaveApplication:PublicSectorAnalytics" \
  --metadata "WaveDashboard:BenefitsProgramDashboard"
```

### Deploy to production (with test run)
```bash
sf project deploy start \
  --source-dir force-app/main/default \
  --test-level RunLocalTests \
  --dry-run
```

### Validate PSS package version
```bash
sf package installed list --target-org YOUR_ORG_ALIAS
```

---

## Managed Package Version Management

PSS follows Salesforce's standard 3-release-per-year cadence (Spring, Summer, Winter). Each release may include:
- New standard objects (check for naming conflicts with custom objects)
- New or updated BRE formula functions
- New OmniStudio base components
- Updates to managed permission sets

**Before upgrading:**
1. Review PSS release notes on help.salesforce.com
2. Install new package version in a full sandbox
3. Run all custom flows, triggers, and Apex tests
4. Re-import OmniStudio components and test all intake flows end-to-end
5. Verify CRM Analytics dashboards still render correctly
6. Check custom fields and validation rules for conflicts with new managed components

---

## Data Loading for Reference Records

BRE Decision Matrix rows, BenefitProgram records, and FundingSource records are data, not metadata. Load via:

```bash
# Decision Matrix rows (BRE eligibility rules)
sf data import bulk \
  --sobject DecisionMatrixRow \
  --file decision-matrix-housing-eligibility.csv \
  --target-org YOUR_ORG_ALIAS

# Benefit Programs
sf data import bulk \
  --sobject BenefitProgram \
  --file benefit-programs.csv \
  --target-org YOUR_ORG_ALIAS
```

---

## Headless 360 (MCP) Usage for PSS

Use `mcp__salesforce__run_soql_query` to query PSS objects during discovery and implementation:

```sql
-- Check installed package version and objects available
SELECT Id, Name, NamespacePrefix, MajorVersion, MinorVersion
FROM InstalledSubscriberPackage
WHERE Name LIKE '%Public Sector%'

-- Verify PSS objects are present in the org
SELECT QualifiedApiName, Label
FROM EntityDefinition
WHERE QualifiedApiName IN ('ProgramEnrollment', 'BenefitProgram', 'GrantApplication',
                           'Inspection', 'ActionPlan', 'BusinessLicense')
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
  fields/
    ProgramEnrollment.EligibilityStatus__c.field-meta.xml
    GrantApplication.RequestedAmount__c.field-meta.xml
  flows/
    AssignCaseWorkerOnEnrollment.flow-meta.xml
    GrantApplicationApprovalRouting.flow-meta.xml
  permissionsets/
    PSS_Custom_CaseWorker.permissionset-meta.xml
    PSS_Custom_Supervisor.permissionset-meta.xml
  validationRules/
    ProgramEnrollment.RequireEligibilityCheck.validationRule-meta.xml
  wave/
    BenefitsProgramDashboard.waveapplication-meta.xml

# OmniStudio components — stored separately as JSON
omnistudio/
  omni-scripts/
    BenefitApplicationIntake.json
    PermitApplicationIntake.json
  flex-cards/
    ConstituentSnapshot.json
    EnrollmentHistory.json
  data-raptors/
    GetConstituentEnrollments.json
  integration-procedures/
    CheckEligibility.json
```

Data load scripts for BRE rules and reference data should live in:
```
engagements/{customer}/docs/
  pss-data-load/
    decision-matrix-housing-eligibility.csv
    benefit-programs.csv
    funding-sources.csv
    data-load-runbook.md
```

---

## Monitoring

| What | Where |
|---|---|
| Package version | Setup → Installed Packages |
| OmniStudio component errors | OmniStudio Designer → Errors tab |
| Flow errors | Setup → Flow Errors |
| BRE rule activation status | Setup → Business Rules Engine |
| Data load job history | Setup → Bulk Data Load Jobs |
| CRM Analytics sync status | Analytics Studio → Data Manager |
| Portal activity | Experience Cloud → Site Administration |
| Case routing health | Omni-Channel Supervisor tab |
