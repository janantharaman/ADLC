---
source: Vlocity Build GitHub (vlocityinc/vlocity_build); E&U Developer Guide (Summer '26); grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: metadata-tooling
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Metadata & Tooling

## Deployment Architecture — Two-Track

E&U Cloud metadata deploys via **two separate tracks** that must be coordinated:

| Track | Tool | What It Deploys |
|---|---|---|
| **DataPacks (Vlocity-specific)** | IDX Workbench / `vlocity` npm CLI | OmniScripts, FlexCards, DataRaptors, Integration Procedures, EPC catalog, pricing, orchestration, CLM, calculation matrices |
| **Standard Salesforce Metadata** | `sf project deploy start` / MDAPI | Apex classes, Flows, LWC components, permission sets, custom objects/fields, custom settings |

Never mix these. DataPack JSON cannot be deployed via `sf project deploy start`. Standard metadata cannot be deployed via `packDeploy`.

---

## IDX Workbench (DataPack Deployment Tool)

### Installation
```bash
npm install --global vlocity
# Requires Node.js 18+

# Verify
vlocity --version
```

### Authentication
IDX uses Salesforce CLI org authentication:
```bash
sf org login web --alias eu-dev
```

### Core Commands

```bash
# Export DataPacks from org to local directory
vlocity packExport \
  -sfdx.username eu-dev \
  -job eu_export_job.yaml

# Deploy DataPacks from local directory to org
vlocity packDeploy \
  -sfdx.username eu-dev \
  -job eu_deploy_job.yaml

# Retry failed records from last deploy
vlocity packRetry \
  -sfdx.username eu-dev \
  -job eu_deploy_job.yaml

# Get diff between local DataPacks and org (line-by-line comparison)
vlocity packGetDiffs \
  -sfdx.username eu-dev \
  -job eu_deploy_job.yaml

# Validate matching keys and references
vlocity validateLocalData \
  -sfdx.username eu-dev \
  -job eu_deploy_job.yaml

# Check for stale object references
vlocity checkStaleObjects \
  -sfdx.username eu-dev \
  -job eu_deploy_job.yaml
```

### Job File Structure (`eu_deploy_job.yaml`)

```yaml
projectPath: ./vlocity-datapacks
expansionPath: datapack-expanded
sfdx.username: eu-dev

activate: true
autoRetryErrors: true
maxDepth: -1                    # -1 = full dependency depth
exportPacksMaxSize: 100         # max records per export batch
maximumDeployCount: 1           # records per deploy batch (increase for performance)

# Only deploy changed DataPacks vs. git commit
gitCheck: true

# Pre/post hooks (Apex class name)
preJobApex: MyPreDeployApex
postJobApex: MyPostDeployApex

queries:
  - VlocityDataPackType: OmniScript
    query: "SELECT Id FROM vlocity_cmt__OmniScript__c WHERE Name LIKE 'Enrollment%'"
  - VlocityDataPackType: IntegrationProcedure
    query: "SELECT Id FROM vlocity_cmt__OmniScript__c WHERE IsIntegrationProcedure__c = true"
  - VlocityDataPackType: Product2
    query: "SELECT Id FROM Product2 WHERE vlocity_cmt__IsActive__c = true"
  - VlocityDataPackType: Catalog
    query: "SELECT Id FROM vlocity_cmt__Catalog__c"
```

---

## DataPack Types — Full Reference

| DataPack Type | Salesforce Object(s) | Notes |
|---|---|---|
| `OmniScript` | `OmniProcess` / `vlocity_cmt__OmniScript__c` | Includes all child elements |
| `IntegrationProcedure` | `OmniProcess` with `IsIntegrationProcedure = true` | |
| `DataRaptor` | `OmniDataTransform` / `vlocity_cmt__DRBundle__c` + `DRMapItem__c` | |
| `FlexCard` | `OmniUiCard` / `vlocity_cmt__VlocityCard__c` | Includes all child cards and layouts |
| `VlocityCard` | `vlocity_cmt__VlocityCard__c` | Legacy name — use FlexCard |
| `VlocityUITemplate` | `vlocity_cmt__VlocityUITemplate__c` | |
| `VlocityUILayout` | `vlocity_cmt__VlocityUILayout__c` | |
| `VlocityAction` | `vlocity_cmt__VlocityAction__c` | |
| `Product2` | `Product2` + all related EPC objects | Includes ProductChildItem, ProductRelationship, AttributeAssignment |
| `Catalog` | `vlocity_cmt__Catalog__c` | Includes category relationships |
| `CatalogProductRelationship` | `vlocity_cmt__CatalogProductRelationship__c` | |
| `Pricebook2` | `Pricebook2` + `PricebookEntry` | |
| `AttributeCategory` | `vlocity_cmt__AttributeCategory__c` + `Attribute__c` | |
| `Attribute` | `vlocity_cmt__Attribute__c` | |
| `AttributeAssignment` | `vlocity_cmt__AttributeAssignment__c` | |
| `CalculationMatrix` | `vlocity_cmt__CalculationMatrix__c` + versions + rows | |
| `CalculationProcedure` | `vlocity_cmt__CalculationProcedure__c` + versions + steps | |
| `Rule` | `vlocity_cmt__Rule__c` + actions + filters | |
| `EntityFilter` | `vlocity_cmt__EntityFilter__c` | |
| `ContextDimension` | `vlocity_cmt__ContextDimension__c` | |
| `ObjectLayout` | `vlocity_cmt__ObjectLayout__c` | |
| `DocumentTemplate` | `vlocity_cmt__DocumentTemplate__c` + elements + sections | |
| `DocumentClause` | `vlocity_cmt__DocumentClause__c` | |
| `ItemImplementation` | `vlocity_cmt__ItemImplementation__c` | OM custom Apex registration |
| `OrchestrationItemDefinition` | `vlocity_cmt__OrchestrationItemDefinition__c` | |
| `OrchestrationPlanDefinition` | `vlocity_cmt__OrchestrationPlanDefinition__c` | |
| `ApexClass` | `ApexClass` | For DataPacks that include custom Apex |
| `StaticResource` | `StaticResource` | |

---

## VlocityMatchingKey__mdt — Required for Idempotent Deployments

Matching keys prevent duplicate record creation on redeployment. Define one per DataPack type that lacks a native unique key.

| Object | Recommended Matching Key |
|---|---|
| `Product2` | `vlocity_cmt__GlobalKey__c` |
| `vlocity_cmt__DRBundle__c` | `Name` |
| `vlocity_cmt__OmniScript__c` | Composite: Name + Type + SubType + Language |
| `vlocity_cmt__VlocityCard__c` | Composite: Name + Author + Version |
| `vlocity_cmt__Catalog__c` | `vlocity_cmt__GlobalKey__c` |
| `PricebookEntry` | Composite: Product2Id + Pricebook2Id + CurrencyIsoCode |
| `vlocity_cmt__AttributeCategory__c` | `vlocity_cmt__Code__c` |
| `vlocity_cmt__PriceList__c` | `vlocity_cmt__Code__c` |
| `vlocity_cmt__Rule__c` | `vlocity_cmt__GlobalKey__c` |
| `vlocity_cmt__OrchestrationItemDefinition__c` | Composite: Name + OrchestrationPlanDefinition (must define manually — no native key) |

**Query to inspect existing matching keys:**
```soql
SELECT Id, DeveloperName,
    vlocity_cmt__ObjectApiName__c,
    vlocity_cmt__MatchingKeyFields__c
FROM vlocity_cmt__VlocityMatchingKey__mdt
ORDER BY vlocity_cmt__ObjectApiName__c ASC
```

---

## VlocityDataPackConfiguration__mdt

Controls export/import limits per DataPack type:

```soql
SELECT Id, DeveloperName,
    vlocity_cmt__DefaultImportLimit__c,
    vlocity_cmt__DefaultExportLimit__c
FROM vlocity_cmt__VlocityDataPackConfiguration__mdt
```

Increase `DefaultImportLimit__c` for large CalculationMatrix deployments (default is often too low for pricing tables with thousands of rows).

---

## Namespace Placeholder

All source-controlled DataPack JSON uses `%vlocity_namespace%__` as the namespace placeholder. IDX Workbench replaces this with `vlocity_cmt__` at deploy time.

**Never deploy raw DataPack JSON via `sf project deploy start`** — the placeholder will not be resolved and all object/field references will fail.

In Apex source files (deployed via standard CLI), use the fully resolved namespace:
```apex
vlocity_cmt__OrchestrationItem__c item = [SELECT Id FROM vlocity_cmt__OrchestrationItem__c ...];
```

---

## Standard Metadata — Package XML Template

For non-DataPack Salesforce metadata (Apex, Flows, LWC, custom settings):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <!-- Custom Apex for OM task implementation -->
  <types>
    <members>MyServiceActivationAction</members>
    <members>MyFulfilmentHandler</members>
    <name>ApexClass</name>
  </types>
  <!-- Record-Triggered Flows on E&U objects -->
  <types>
    <members>ProgramEnrollment_OnApproval</members>
    <members>EnergyServiceAgreement_OnActivation</members>
    <name>Flow</name>
  </types>
  <!-- Custom LWC components (non-FlexCard) -->
  <types>
    <members>euServicePointMap</members>
    <members>euBillSummaryChart</members>
    <name>LightningComponentBundle</name>
  </types>
  <!-- Permission Sets -->
  <types>
    <members>EU_Contact_Center_Agent</members>
    <members>EU_Field_Service_Tech</members>
    <name>PermissionSet</name>
  </types>
  <!-- Custom fields on standard/managed objects -->
  <types>
    <members>Account.EU_Customer_Segment__c</members>
    <members>Account.EU_Territory__c</members>
    <name>CustomField</name>
  </types>
  <!-- Named Credentials -->
  <types>
    <members>CIS_Billing_System</members>
    <members>DocuSign_Production</members>
    <name>NamedCredential</name>
  </types>
  <version>67.0</version>
</Package>
```

---

## Deployment Order

Deploy E&U Cloud components in this sequence:

1. **Managed Package** — install `vlocity_cmt` first; all custom objects/fields depend on it
2. **Permission Sets** — deploy before assigning to users
3. **Named Credentials** — required before IPs with HTTP Actions can be tested
4. **Custom Objects / Fields** — any org-specific extensions to standard/managed objects
5. **Apex Classes** — `ItemImplementation__c` targets and custom triggers
6. **Flows** — record-triggered flows on E&U objects
7. **EPC Catalog DataPacks** — Catalog → Product2 → AttributeCategory → Attribute → AttributeAssignment → PricingPlan → CalculationMatrix
8. **Orchestration DataPacks** — OrchestrationItemDefinition → OrchestrationPlanDefinition → OrchestrationScenario → DecompositionRelationship → ItemImplementation
9. **OmniStudio DataPacks** — DataRaptor → Integration Procedure → FlexCard → OmniScript (this order ensures IP dependencies exist before FlexCards that invoke them)
10. **CLM / DocGen DataPacks** — DocumentTemplate → DocumentClause
11. **LWC Components** — custom LWC (non-FlexCard); FlexCard-generated LWC is deployed by activation in Step 9
12. **Lightning Pages / App Builder** — after LWC and FlexCards are activated

---

## Common Deployment Errors

| Error | Cause | Fix |
|---|---|---|
| `%vlocity_namespace%__` appears in deployed metadata | DataPack deployed via `sf project deploy start` instead of IDX | Always use `vlocity packDeploy` for DataPacks |
| Duplicate records created on redeploy | Missing `VlocityMatchingKey__mdt` for the DataPack type | Define matching key records before deploying |
| `CIRCULAR_REFERENCE` error in IDX | Two DataPacks reference each other | Use `supportHeadersOnly: true` first pass, then full deploy |
| CalculationMatrix rows not loading | Batch size < 2,000 | Ensure ≥ 2,000 rows per bulk load batch |
| `MANAGED_PICKLIST_VALUE_NOT_FOUND` | Managed Global Value Set missing values in target | Add picklist values via Setup UI before deploying |
| OmniScript not rendering after deploy | Not activated; Angular runtime in LWC org | Activate in OmniStudio Designer; ensure `IsLwcEnabled: true` |
| FlexCard actions not working after deploy | FlexCard not activated (LWC not generated) | Open FlexCard in designer and click Activate |
| `ItemImplementation` Apex not executing | Class not implementing `VlocityOpenInterface` | Implement `invokeMethod` and return `true` |
| Multi-currency deploy failure | Target org does not have multi-currency | Enable multi-currency in target org first |

---

## CI/CD Considerations

- **Two separate pipelines** — DataPack pipeline (IDX) + standard Salesforce metadata pipeline (sf CLI) must be coordinated in CI/CD
- **gitCheck: true** — use in IDX job files to deploy only changed DataPacks (significant performance gain in CI)
- **Activation step** — OmniScripts and FlexCards require activation after deployment; add a post-deploy Apex script or IDX `postJobApex` hook to activate components
- **Environment-specific data** — `VlocityMatchingKey__mdt`, `VlocityDataPackConfiguration__mdt`, Named Credential values, and custom settings are environment-specific; maintain per-env setup scripts
- **Never deploy `CalculationMatrixRow__c` records via DataPack in CI pipelines** for large pricing tables — use a scheduled data load job instead; CI DataPack deploys time out on large matrix tables
