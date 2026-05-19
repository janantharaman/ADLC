---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Sales Cloud — Metadata and Tooling Reference

---

## Key Metadata Types for Sales Cloud Implementations

| Metadata Type | API Name | Purpose | Deployment Notes |
|---|---|---|---|
| Business Process | `BusinessProcess` | Defines active picklist values for Opportunity Stages and Lead Statuses per Record Type | Must deploy BEFORE RecordType that references it |
| Record Type | `RecordType` | Organises records by type; controls Business Process, page layout, picklist subsets | Depends on BusinessProcess |
| Page Layout | `Layout` | Field arrangement on record pages | Deployed after RecordType; assign via Profile/PermSet metadata |
| Assignment Rule | `AssignmentRule` | Lead and Case routing rules | Rule entries include criteria and assignee references |
| Auto-Response Rule | `AutoResponseRule` | Email acknowledgement on Lead/Case creation | References Email Templates |
| Duplicate Rule | `DuplicateRule` | Controls duplicate checking behavior | References MatchingRule |
| Matching Rule | `MatchingRule` | Defines match criteria for duplicate detection | Deploy before DuplicateRule |
| Approval Process | `ApprovalProcess` | Multi-step approval workflow | References User/Queue; deploy after Profile/PermSet |
| Forecasting Settings | `ForecastingSettings` | Enables forecasting, sets hierarchy and measure | Partially deployable; some settings require Setup UI |
| Territory2 Model | `Territory2Model` | Territory hierarchy container | Data (assignments) cannot be deployed — must be loaded separately |
| Territory2 | `Territory2` | Individual territory record | Deployed as metadata; assignment associations are data |
| Territory2 Type | `Territory2Type` | Classifies territories (e.g., Geographic, Named Account) | |
| Territory2 Rule | `Territory2Rule` | Account-to-territory assignment criteria | |
| Opportunity Settings | In `SalesSettings` | Enables/disables Opportunity Teams, Splits, etc. | Part of Sales Settings metadata |
| Quote Settings | `QuoteSettings` | Enables Quotes | Simple enable; Quote Templates are additional metadata |
| Custom Field | `CustomField` on standard objects | Business-specific fields | Deploy field before validation rules/flows that reference it |
| Validation Rule | `ValidationRule` | Data entry enforcement | Deploy after the fields they reference |
| Flow | `Flow` | Automation (Record-Triggered, Scheduled, Screen, Autolaunched) | Deploy with `status = Active`; inactive flows skip activation |
| Email Template | `EmailTemplate` | Reusable email content | Required by Assignment Rules, Auto-Response Rules, Approval Processes |
| Report | `Report` | Saved analytics | Deployed in report folder context |
| Dashboard | `Dashboard` | Visual analytics | Deployed in dashboard folder context |
| Sharing Rules | `SharingRules` | Extend record access beyond OWD | Cannot exceed OWD — only opens access, never restricts |

---

## Deployment Ordering Constraints

Violations of this order cause dependency failures. Deploy in this sequence:

```
1. Custom Objects (if any)
2. Custom Fields (on all objects referenced by downstream metadata)
3. Matching Rules
4. Duplicate Rules
5. Picklist value updates (via CustomField metadata)
6. Business Processes (Opportunity stages, Lead statuses)
7. Record Types (reference Business Process)
8. Page Layouts (reference fields)
9. Profile / Permission Set (assign Record Types, page layouts)
10. Email Templates
11. Assignment Rules (reference Email Templates, Users/Queues)
12. Auto-Response Rules (reference Email Templates)
13. Escalation Rules
14. Approval Processes (reference Users/Queues, Email Templates)
15. Validation Rules
16. Flows (reference fields, objects)
17. Territory2 Types → Territory2 Models → Territory2 records → Territory2 Rules
18. Sharing Rules
19. Reports, Dashboards
```

**Post-deploy data steps (not metadata):**
- ObjectTerritory2Association records (territory account assignments)
- ForecastingQuota records (quota loads)
- User territory assignments (UserTerritory2Association)
- Assignment Rule activation (can be done via metadata but verify active flag)
- Pricebook2 and PricebookEntry records (if not managing as metadata)

---

## Package.xml Examples

### Core Sales Cloud Deployment (New Implementation)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Lead</members>
        <members>Opportunity</members>
        <members>Account</members>
        <members>Contact</members>
        <members>Quote</members>
        <members>OpportunityLineItem</members>
        <members>Product2</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Lead.Custom_Field__c</members>
        <members>Opportunity.Discount__c</members>
        <members>Opportunity.Closed_Reason__c</members>
        <members>Account.Segment__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Opportunity.Standard_Opportunity_Process</members>
        <members>Lead.Standard_Lead_Process</members>
        <name>BusinessProcess</name>
    </types>
    <types>
        <members>Opportunity.Enterprise_Opportunity</members>
        <members>Opportunity.SMB_Opportunity</members>
        <members>Lead.Standard</members>
        <name>RecordType</name>
    </types>
    <types>
        <members>Opportunity-Enterprise Opportunity Layout</members>
        <members>Lead-Lead Layout</members>
        <name>Layout</name>
    </types>
    <types>
        <members>Standard_Lead_Assignment</members>
        <name>AssignmentRule</name>
    </types>
    <types>
        <members>Standard_Lead_Matching_Rule</members>
        <name>MatchingRule</name>
    </types>
    <types>
        <members>Standard_Lead_Duplicate_Rule</members>
        <name>DuplicateRule</name>
    </types>
    <types>
        <members>Opportunity_Discount_Approval</members>
        <name>ApprovalProcess</name>
    </types>
    <types>
        <members>Stage_Transition_Handler</members>
        <members>Auto_Close_Stale_Opportunities</members>
        <name>Flow</name>
    </types>
    <types>
        <members>Opportunity.Amount_Required_Before_Proposal</members>
        <name>ValidationRule</name>
    </types>
    <types>
        <members>Sales_Standard_Access</members>
        <members>Sales_Manager_Access</members>
        <name>PermissionSet</name>
    </types>
    <version>67.0</version>
</Package>
```

### Territory Management 2.0 Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Geographic</members>
        <members>Named_Account</members>
        <name>Territory2Type</name>
    </types>
    <types>
        <members>FY26_Territory_Model</members>
        <name>Territory2Model</name>
    </types>
    <types>
        <members>FY26_Territory_Model.North_America</members>
        <members>FY26_Territory_Model.EMEA</members>
        <members>FY26_Territory_Model.APAC</members>
        <name>Territory2</name>
    </types>
    <types>
        <members>FY26_Territory_Model.North_America.West_Rule</members>
        <name>Territory2Rule</name>
    </types>
    <version>67.0</version>
</Package>
```

### Sales Engagement (HVS) Configuration Package

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Sales_Engagement_User</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>HVS_Lead_Cadence_Email</members>
        <members>HVS_Follow_Up_Email</members>
        <name>EmailTemplate</name>
    </types>
    <!-- ActionCadence metadata is managed via Setup UI; not fully deployable via package.xml in all versions -->
    <version>67.0</version>
</Package>
```

---

## CPQ vs Native Quote Metadata Differences

| Concern | Native Salesforce Quote | Salesforce CPQ (Revenue Cloud) |
|---|---|---|
| Object | `Quote` (standard) | `SBQQ__Quote__c` (managed package custom object) |
| Line Items | `QuoteLineItem` (standard) | `SBQQ__QuoteLine__c` (managed) |
| Product rules | None (validation rules only) | `SBQQ__ProductRule__c` — constraints, errors, alerts, selections |
| Price rules | Manual or Flow | `SBQQ__PriceRule__c` — automatic price adjustments |
| Contract/renewal | Manual | `SBQQ__Contract__c`, `SBQQ__Subscription__c` — automated renewal |
| Approval flow | Standard Approval Process | CPQ Advanced Approvals (`sbaa__` namespace) |
| Metadata namespace | None (standard objects) | `SBQQ__` (managed; cannot modify managed metadata) |
| Deployment | Standard change set / Metadata API | Package upgrades via AppExchange; custom config in `SBQQ__CustomScript__c`, `SBQQ__ConfigurationRule__c` |
| Quote templates | Quote Template (standard) | `SBQQ__QuoteTemplate__c` (managed) + custom template sections |

**Key implication:** CPQ metadata is in a managed namespace. You cannot deploy or modify the CPQ managed package metadata. You can only deploy custom configuration records and custom extension objects. CPQ migration must be handled in the CPQ UI and through sandbox-to-sandbox data migration for configuration records.

---

## Sandbox Refresh Considerations

When refreshing a sandbox from production (or creating a new scratch org), the following Sales Cloud elements require post-refresh attention:

### Assignment Rules
- Assignment Rules are copied as metadata in a full or partial sandbox refresh
- **User references** in rule entries point to production user IDs. These IDs are different in sandbox. After refresh, audit Assignment Rule entries with user assignments and remap to sandbox user IDs.
- Queue assignments are ID-based as well — verify Queue IDs in sandbox.

### Territory Hierarchy
- `Territory2Model` metadata is copied. Territory model state in sandbox defaults to "Planning" after refresh (Active model in production does not auto-activate in sandbox).
- `ObjectTerritory2Association` records (account-to-territory data) are NOT included in partial sandbox refreshes. Full sandbox includes all data including these records.
- After sandbox refresh, re-run territory assignment rules: Setup > Territory Management > Run Assignment Rules.

### Forecast Quotas
- `ForecastingQuota` records are data, not metadata. They are included in full sandbox refreshes but not partial. In Developer or Developer Pro sandboxes, quotas must be reloaded manually.

### Einstein Features
- Einstein Lead/Opportunity Scoring models do not transfer to sandbox. Einstein scoring in sandbox uses a separate model trained on sandbox data. Ensure sandbox has sufficient closed opportunity history for model training, or create test records.
- Einstein Activity Capture connections (email/calendar) must be reconfigured per-user in sandbox.

### Pricebook and Product Data
- In partial sandbox, Pricebook and Product records may not be present. Load a representative catalog subset for testing.
- Standard Price Book ID differs between production and sandbox — always query dynamically.

### Connected Apps / OAuth
- OAuth tokens and Connected App configurations do not carry over. Reauthorize any integration users post-refresh.
- Named Credentials referencing production endpoints: update to sandbox endpoints post-refresh.

---

## Tooling API Queries for Sales Cloud Metadata Inspection

Use the Tooling API (`/services/data/v67.0/tooling/query/`) for inspecting metadata in org:

### List All Active Flows on Opportunity

```soql
SELECT Id, ApiName, Label, Status, ProcessType, TriggerObjectOrEventLabel
FROM FlowDefinitionView
WHERE TriggerObjectOrEventLabel = 'Opportunity'
  AND Status = 'Active'
ORDER BY Label
```

### List All Validation Rules on Opportunity

```soql
SELECT Id, EntityDefinition.QualifiedApiName, ValidationName,
       Description, ErrorDisplayField, Active
FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
ORDER BY ValidationName
```

### List Assignment Rule Entries

```soql
SELECT Id, Name, Active
FROM AssignmentRule
WHERE SobjectType = 'Lead'
  AND Active = true
```

### List Custom Fields on Lead

```soql
SELECT Id, QualifiedApiName, Label, DataType, IsCustom
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Lead'
  AND IsCustom = true
ORDER BY QualifiedApiName
```

### List Record Types on Opportunity

```soql
SELECT Id, Name, DeveloperName, IsActive, BusinessProcessId, BusinessProcess.Name
FROM RecordType
WHERE SobjectType = 'Opportunity'
  AND IsActive = true
ORDER BY Name
```

### List All Active Duplicate Rules

```soql
SELECT Id, DeveloperName, IsActive, SobjectSubtype
FROM DuplicateRule
WHERE IsActive = true
ORDER BY DeveloperName
```

### Inspect Page Layout Assignments

```soql
SELECT Id, ProfileId, Profile.Name, RecordTypeId, RecordType.Name, LayoutId
FROM ProfileLayout
WHERE TableEnumOrId = 'Opportunity'
ORDER BY Profile.Name
```

### Check Territory2 Model Status

```soql
SELECT Id, Name, DeveloperName, State, ActivatedDate, LastModifiedDate
FROM Territory2Model
ORDER BY LastModifiedDate DESC
```

---

## Key Custom Settings Patterns in Sales Cloud Implementations

| Custom Setting Pattern | Purpose | Typical Fields |
|---|---|---|
| `SalesConfiguration__c` (hierarchy) | Feature flags and thresholds for sales automation | `EnableAutoClose__c`, `StaleOpportunityDays__c`, `DiscountApprovalThreshold__c` |
| `ForecastSettings__c` (hierarchy) | Forecast period and quota display config | `CurrentFiscalQuarterStart__c`, `ForecastCurrencyCode__c` |
| `TerritoryAssignment__c` (list) | Territory rule lookup tables | `BillingState__c`, `Territory2Id__c`, `Priority__c` |
| `PricebookConfig__c` (hierarchy) | Which pricebook to assign for different deal types | `PartnerPricebookId__c`, `PublicSectorPricebookId__c` |
| `IntegrationEndpoints__c` (hierarchy) | Environment-specific endpoint URLs | `ERPBaseURL__c`, `BillingSystemURL__c` |

**Best practice:** Use Hierarchy Custom Settings (not List) for anything that may vary by user or profile. This allows sandbox and production to have different values without metadata changes — just data updates.

**Avoid:** Storing IDs (Record IDs) in Custom Settings that differ between environments. Use External ID fields or named records to retrieve IDs dynamically instead.

---

## Salesforce Sales Settings Metadata

The `SalesSettings` metadata type controls several Sales Cloud feature toggles:

**Key fields in SalesSettings:**
- `enableAccountTeams` — Account Teams feature
- `enableOpportunityTeam` — Opportunity Teams feature
- `enableSalesConsole` — Sales Console (legacy)
- `enableOpportunitySplits` — Opportunity Splits (also requires Forecasting)
- `allowMultipleCurrencies` — Multi-currency (irreversible to disable)

Query current settings via Tooling API:
```soql
SELECT enableAccountTeams, enableOpportunityTeam, enableOpportunitySplits
FROM SalesSettings
```

---

## ForecastingSettings Deployment Notes

`ForecastingSettings` metadata is partially deployable. Key limitations:
- Enabling/disabling Forecasting overall: deployable
- Forecast hierarchy type (Role vs Territory): deployable
- Forecast Type definitions: partially deployable; some configurations require Setup UI
- Stage → Forecast Category mappings: NOT deployable via Metadata API — must be set in Setup UI

**Workaround for Stage → Forecast Category mapping:** Document the required mappings in implementation notes. Include in deployment runbook as a manual post-deploy step. Validate via Tooling API query on `ForecastingType` and Stage metadata after deploy.
