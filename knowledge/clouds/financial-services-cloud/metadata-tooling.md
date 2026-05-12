---
source: Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata queried from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Financial Services Cloud — Metadata and Tooling API Reference

> **Note:** The Salesforce Atlas documentation portal is JavaScript-rendered and not accessible via automated fetch. The sections below are compiled from: org metadata queries via Tooling API v67.0 on LKInsuranceDev; FSC platform documentation knowledge current to Spring '26; and direct extraction from fsc_dev_guide.pdf (1396p, Spring '26) pp.1299–1360.

---

## Metadata API — FSC-Relevant Types

These Metadata API types are used when deploying or retrieving FSC configuration.

### Standard Metadata Types Used in FSC

| Metadata Type | File Extension | FSC Use |
|---|---|---|
| `CustomObject` | `.object-meta.xml` | Custom objects in FSC implementations (Placement__c, etc.) |
| `CustomField` | (within object XML) | Custom fields on standard FSC objects (InsurancePolicy, Claim, etc.) |
| `CustomMetadata` | `.md-meta.xml` | ARC configuration, custom settings, feature flags |
| `Layout` | `.layout-meta.xml` | Page layouts for InsurancePolicy, Claim, FinancialAccount |
| `FlexiPage` | `.flexipage-meta.xml` | Lightning record pages for FSC objects including ARC component |
| `RecordType` | (within object XML) | Record types for InsurancePolicy, Claim, FinancialAccount |
| `ValidationRule` | (within object XML) | Validation rules on FSC objects |
| `Flow` | `.flow-meta.xml` | Policy lifecycle flows, claim flows, household flows |
| `PermissionSet` | `.permissionset-meta.xml` | FSC-specific permission sets (Advisor, Claims, Finance) |
| `PermissionSetGroup` | `.permissionsetgroup-meta.xml` | Grouped permission sets by persona |
| `Profile` | `.profile-meta.xml` | Object/field-level access for FSC objects |
| `SharingRules` | `.sharingRules-meta.xml` | Sharing rules for InsurancePolicy, Claim, FinancialAccount |
| `AssignmentRules` | `.assignmentRules-meta.xml` | Claim assignment rules |
| `EscalationRules` | `.escalationRules-meta.xml` | Claim escalation rules |
| `ApexClass` | `.cls` | Apex classes for FSC business logic |
| `ApexTrigger` | `.trigger` | Triggers on FSC objects |
| `LightningComponentBundle` | (LWC directory) | Custom LWC components extending FSC pages |
| `QuickAction` | `.quickAction-meta.xml` | Quick actions on InsurancePolicy, Claim pages |
| `CompactLayout` | (within object XML) | Compact layouts for FSC record pages |
| `FieldSet` | (within object XML) | Field sets used by FSC managed page components |
| `ListView` | (within object XML) | List views for FSC objects |
| `Report` | `.report-meta.xml` | FSC pre-built and custom reports |
| `Dashboard` | `.dashboard-meta.xml` | FSC advisor/claims dashboards |
| `EmailTemplate` | `.email-meta.xml` | Templates for policy renewal, claim acknowledgement |
| `NetworkBranding` | `.networkBranding-meta.xml` | Experience Cloud branding (customer portal) |
| `CommunityTemplateDefinition` | — | Experience Cloud templates for client portals |
| `CustomTab` | `.tab-meta.xml` | Custom tabs for FSC navigation |
| `CustomApplication` | `.app-meta.xml` | FSC-specific app definitions (Insurance, Wealth, Banking) |
| `HomePageLayout` | `.homePageLayout-meta.xml` | Home page layouts per persona |

### FSC-Specific Metadata API Types (from FSC Developer Guide)

These are FSC-specific Metadata API types documented in fsc_dev_guide.pdf pp.1299–1340. Source-verified from Spring '26.

| Metadata Type | File Suffix | Available Since | Purpose |
|---|---|---|---|
| `AccountRelationhipShareRule` | (extends MetadataWithContent) | Existing | Defines which object records are shared via account relationships; FSC Insurance adds Insurance-specific criteria fields |
| `AssessmentQuestion` | `.AssessmentQuestion` (in AssessmentQuestions/) | API v55.0 | Container for Discovery Framework assessment questions; includes versioning |
| `AssessmentQuestionSet` | `.AssessmentQuestionSet` (in AssessmentQuestionSets/) | API v55.0 | Groups AssessmentQuestions into sets for assessments |
| `ClaimFinancialSettings` | `.claimFinancialSettings` (in ClaimFinancialSettings/) | API v57.0 | Configures pending financial authority status values for claims, claim coverages, and claim coverage payment details |
| `DocumentChecklistSettings` | `DocumentChecklist.settings` (in settings/) | API v55.0 | Org-level settings for DocumentChecklistItem: custom sharing and deletion controls |
| `Flow` (FSC extensions) | `.flow-meta.xml` | API v46.0+ | Standard Flow type with FSC-added processType (`FSCLending`) and FlowActionCall actionType values |
| `Icon` | `.icon` (in icons/) | API v49.0 | Maps custom icons to FSC object types (PersonLifeEvent, InsurancePolicy, BusinessMilestone, AssetMilestone, FinancialAccountMilestone) |
| `IndustriesSettings` | `Industries.settings` (in settings/) | API v47.0 | Primary FSC feature toggle settings for the org; accessed via `<name>Settings</name>` in package.xml |
| `OmniScript` | `.omniScript` (in omniScripts/) | API v56.0 | OmniScript and Integration Procedure metadata for Discovery Framework; requires OmniStudio license |
| `ParticipantRole` | `.participantRole` (in participantRoles/) | API v50.0 | Defines roles and default access levels for participants on supported parent objects (FinancialDeal, Account, Interaction, etc.) |
| `RelatedRecordAssocCriteria` | `.relatedRecordAssocCriteria` (in relatedRecordAssocCriteria/) | API v52.0 | Criteria for automatic branch-record associations; triggers BranchUnitRelatedRecord creation |
| `RelationshipGraphDefinition` | `.relationshipGraphDefinition` (in relationshipGraphDefinitions/) | API v55.0 | Defines ARC-style relationship graph traversal configuration (HorizontalHierarchy); deployable ARC config |
| `RetrievalSummaryDefinition` | `.retrievalSummaryDefinition` (in retrievalSummaryDefinitions/) | API v61.0 | Configures data retrieval patterns for summarizing related records across object relationships |

### FSC-Specific Custom Metadata Types

These are typically deployed as `CustomMetadata` records:

| Type | Purpose |
|---|---|
| `FSC_Feature_Flag` (or similar) | Enable/disable FSC feature modules per environment |
| ARC configuration metadata | Relationship group definitions, visible object types |
| Insurance configuration | LOB picklist mappings, coverage category codes |

---

## Retrieving FSC Object Metadata

### Package.xml for FSC Object Retrieval

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>InsurancePolicy</members>
        <members>Claim</members>
        <members>ClaimItem</members>
        <members>ClaimParticipant</members>
        <members>ClaimCoverage</members>
        <members>InsurancePolicyCoverage</members>
        <members>InsurancePolicyAsset</members>
        <members>InsurancePolicyParticipant</members>
        <members>InsurancePolicyTransaction</members>
        <members>FinancialAccount</members>
        <members>FinancialAccountTransaction</members>
        <members>FinancialGoal</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>InsurancePolicy-*</members>
        <members>Claim-*</members>
        <members>FinancialAccount-*</members>
        <name>Layout</name>
    </types>
    <types>
        <members>InsurancePolicy-*</members>
        <members>Claim-*</members>
        <name>RecordType</name>
    </types>
    <version>67.0</version>
</Package>
```

### Retrieving All Custom Fields on FSC Standard Objects

When retrieving custom fields on standard FSC objects via sf CLI:
```bash
# Retrieve InsurancePolicy object with all custom fields
sf project retrieve start --metadata "CustomObject:InsurancePolicy"

# Retrieve specific custom field
sf project retrieve start --metadata "CustomField:InsurancePolicy.BrokerageRate__c"
```

**Important:** Standard FSC objects (`InsurancePolicy`, `Claim`, etc.) are platform-managed. The retrieve will return only the *customizations* added to these objects — not the standard field definitions. Standard field definitions are part of the FSC platform and are not deployable.

---

## Tooling API — FSC Objects

The Tooling API is used for metadata queries and debugging. Key objects used in FSC development:

| Tooling API Object | Purpose |
|---|---|
| `EntityDefinition` | Query all objects in org including FSC objects |
| `FieldDefinition` | Query fields on FSC objects with type and label information |
| `ValidationRule` | Query validation rules on FSC objects |
| `WorkflowRule` | Query legacy workflow rules (if any) on FSC objects |
| `FlowDefinition` | Query flow definitions touching FSC objects |
| `ApexClass` | Query Apex classes; check for FSC-related code |
| `ApexTrigger` | Query triggers on FSC objects |
| `CustomField` | Query custom field definitions for metadata retrieval |
| `RecordType` | Query record type definitions on FSC objects |
| `Layout` | Query page layout definitions |
| `FlexiPage` | Query Lightning page definitions |

### Useful Tooling API Queries

```soql
-- Find all FSC-related objects in the org
SELECT QualifiedApiName, Label, IsCustomizable
FROM EntityDefinition
WHERE QualifiedApiName LIKE 'Insurance%'
   OR QualifiedApiName LIKE 'Claim%'
   OR QualifiedApiName LIKE 'Financial%'
ORDER BY QualifiedApiName

-- Find all fields on InsurancePolicy
SELECT QualifiedApiName, Label, DataType, IsCompound, IsNameField, ReferenceTo
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'InsurancePolicy'
ORDER BY QualifiedApiName

-- Find all validation rules on insurance objects
SELECT Id, EntityDefinition.QualifiedApiName, ValidationName, Active, Description
FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName IN ('InsurancePolicy','Claim','InsurancePolicyCoverage')
ORDER BY EntityDefinition.QualifiedApiName, ValidationName

-- Find all triggers on FSC objects
SELECT Id, Name, TableEnumOrId, Status, Body
FROM ApexTrigger
WHERE TableEnumOrId IN ('InsurancePolicy','Claim','FinancialAccount','InsurancePolicyCoverage')
ORDER BY TableEnumOrId, Name

-- Find flows that reference InsurancePolicy
SELECT Id, ApiName, Label, ProcessType, Status
FROM FlowDefinition
WHERE ProcessType IN ('AutoLaunchedFlow','Flow','Workflow','InvocableProcess')
ORDER BY ApiName
```

---

## Deployment Notes for FSC

### Cannot Deploy

The following cannot be deployed via Metadata API — they must be configured manually in each environment:

- FSC feature activation (Insurance, Wealth Management) — done via FSC Setup page in the target org
- Some ARC configuration settings (relationship group visibility, component display settings)
- Named Credentials used by insurance integration endpoints
- FSC-specific permission set assignments (users must be assigned post-deployment)

### Must Deploy in Order

For FSC implementations, metadata deployment order matters:

1. Custom objects (Placement__c, etc.) — must exist before their fields
2. Custom fields on standard FSC objects — before validation rules that reference them
3. Custom metadata types and records — before flows that read them
4. Flows — before permission sets that include flow access
5. Permission sets — before profiles that reference them
6. Page layouts / FlexiPages — after all components they reference

### Partial Deployment Risk

**Do not partially deploy** a policy or claim object package. If `InsurancePolicyCoverage` custom fields deploy but the related `InsurancePolicy` custom fields do not (due to a field dependency), Formula fields that cross-reference both objects will fail. Always validate deploy (`checkOnly: true`) before full deployment.

### Test Class Coverage for FSC Objects

```apex
// Minimum test setup for InsurancePolicy unit tests
@TestSetup
static void makeData() {
    // 1. Create Account (NameInsured)
    Account acc = new Account(Name='Test Insured', RecordTypeId='...');
    insert acc;
    
    // 2. Create InsurancePolicy
    InsurancePolicy policy = new InsurancePolicy(
        Name = 'TEST-001',
        NameInsuredId = acc.Id,
        Status = 'InForce',
        EffectiveDate = Date.today(),
        ExpirationDate = Date.today().addYears(1),
        PolicyType = 'Commercial'
    );
    insert policy;
    
    // 3. Create coverage and participant as needed by test scenario
}
```

---

## FSC Permission Set Architecture (Metadata)

FSC ships with pre-built permission sets. In addition, implementations add custom permission sets. Key permission set groups to deploy:

### Standard FSC Permission Sets (platform-provided)

| Permission Set | Purpose |
|---|---|
| `FSCInsurance` | Base access for Insurance objects |
| `FSCWealthManagement` | Base access for Wealth objects |
| `FSCBanking` | Base access for Banking objects |
| `FinancialServicesCloudBasic` | Base FSC access |

### Custom Permission Sets (implementation-defined)

| Permission Set | Persona | Key Grants |
|---|---|---|
| `FSC_Advisor_Access` | Client advisors | CRUD InsurancePolicy, FinancialAccount, Opportunity; Read Claim |
| `FSC_Claims_Access` | Claims adjusters | CRUD Claim, ClaimItem, ClaimParticipant, ClaimCoverage; Read InsurancePolicy |
| `FSC_Finance_Access` | Finance team | CRUD reconciliation/settlement objects; no client data edit |
| `FSC_Compliance_Access` | Compliance/audit | Read-all FSC objects; no edit |
| `FSC_Admin_Access` | Platform admin | Full access including FSC Setup configuration |

---

## FSC Sharing Model Configuration (Metadata)

### OWD Recommendations (configure in Security Settings)

| Object | Recommended OWD | Rationale |
|---|---|---|
| `InsurancePolicy` | Private | Each advisor/team sees only their policies |
| `Claim` | Private | Adjuster owns claim; hierarchy grants supervisor access |
| `FinancialAccount` | Private | Advisor sees their client accounts only |
| `InsurancePolicyCoverage` | Controlled by Parent | Inherits InsurancePolicy sharing |
| `InsurancePolicyParticipant` | Controlled by Parent | Inherits InsurancePolicy sharing |
| `InsurancePolicyAsset` | Controlled by Parent | Inherits InsurancePolicy sharing |
| `InsurancePolicyTransaction` | Controlled by Parent | Inherits InsurancePolicy sharing |
| `FinancialAccountTransaction` | Controlled by Parent | Inherits FinancialAccount sharing |
| `ClaimItem` | Controlled by Parent | Inherits Claim sharing |
| `ClaimParticipant` | Controlled by Parent | Inherits Claim sharing |
| `ClaimCoverage` | Controlled by Parent | Inherits Claim sharing |
| `FinancialGoal` | Private | Client/advisor relationship controls access |

### Sharing Rules Metadata

Sharing rules for FSC objects should be deployed as `SharingRules` metadata:

```xml
<!-- Example: Share InsurancePolicy with Claims team when Status = 'Claim Filed' -->
<sharingCriteriaRules>
    <fullName>SharePolicyWithClaims</fullName>
    <accessLevel>Read</accessLevel>
    <label>Share Policy with Claims Team</label>
    <sharedTo>
        <group>Claims_Team_Queue</group>
    </sharedTo>
    <criteriaItems>
        <field>InsurancePolicy.Status</field>
        <operation>equals</operation>
        <value>Claim Filed</value>
    </criteriaItems>
</sharingCriteriaRules>
```

---

## IndustriesSettings Field Reference

Source: fsc_dev_guide.pdf pp.1312–1318. Full field reference for `IndustriesSettings` (accessed as `Industries.settings`; available API v47.0+). All fields are boolean; default is false unless noted. See overview.md for grouped descriptions by domain.

### Insurance Fields

| Field | Default | Available Since |
|---|---|---|
| `allowMultipleProducersToWorkOnSamePolicy` | false | FSC Insurance editions |
| `enableAccessToMasterListOfCoverageTypes` | false | FSC Insurance editions |
| `enableClaimMgmt` | false | — |
| `enableManyToManyRelationships` | false | FSC Insurance editions |
| `enablePolicyAdministration` | false | — |
| `enableFSCInsuranceReport` | false | API v48.0 (FSC Insurance editions; requires `allowMultipleProducersToWorkOnSamePolicy` first) |
| `enableCalculationUsingParentPolicyOnly` | false | — |
| `allowBenefitAssignmentWithInactiveProgramEnrollment` | false | API v65.0 |

### Banking / Financial Account Fields

| Field | Default | Available Since |
|---|---|---|
| `enableFinancialAccountMgmt` | false | FSC Insurance editions |
| `enableDealManagement` | false | FSC Insurance editions |
| `enableFinancialDealRoleHierarchy` | false | — |
| `enableFinancialDealCallReportPref` | false | API v54.0 |
| `enableFinancialDealCallReportCmpPref` | false | API v54.0 |
| `enableB2B` | false | — |
| `enableB2BAccountPlan` | false | — |
| `enableCallReportAdminContextPref` | false | — |
| `enableInteractionSummaryPref` | false | FSC Insurance editions |
| `enableInteractionRoleHierarchy` | false | — |
| `enableInteractionSummaryRoleHierarchy` | false | FSC Insurance editions |
| `enableSyncInteractionsPref` | false | — |
| `enableSlackForCib` | false | — |
| `enableTimelinePref` | false | — |

### Mortgage / Lending Fields

| Field | Default | Available Since |
|---|---|---|
| `createCustomerPropertyFromLAProperty` | false | — |
| `createFinancialAccountFromLAAsset` | false | — |
| `createFinancialAccountFromLALiability` | false | — |
| `createFinancialAccountsFromLAFinancials` | false | — |
| `createFinancialAccountsFromLAProperty` | false | — |
| `createFSCAssetFromLAAsset` | false | — |
| `createFSCAssetFromLAProperty` | false | — |
| `createFSCLiabilityFromLAFinancial` | false | — |
| `createFSCLiabilityFromLALiability` | false | — |
| `enableDigitalLendingPref` | false | — |
| `enableDigitalLendingReadOnlyOrgPref` | false | — |
| `enableMortgageRlaTotalsOrgPref` | false | FSC Insurance editions |
| `loanApplicantAutoCreation` | false | API v51.0 (FSC Insurance editions) |
| `loanApplicantAddressAutoCreation` | false | API v51.0 (FSC Insurance editions) |
| `rlaEditIfAccHasEdit` | false | — |
| `brwrCntctFrExtrnlSrcsPref` | false | — |

### Compliant Data Sharing Fields

| Field | Default | Available Since |
|---|---|---|
| `enableCompliantDataSharingForAccount` | false | FSC Insurance editions |
| `enableCompliantDataSharingForOpportunity` | false | FSC Insurance editions |
| `enableCompliantDataSharingForInteraction` | false | — |
| `enableCompliantDataSharingForInteractionSummary` | false | — |
| `enableCompliantDataSharingForCustomObjects` | false | FSC Insurance editions |

### Collections Fields

| Field | Default | Available Since |
|---|---|---|
| `collectionAsaAgentPref` | false | — |
| `clctnAndRecoveryAgntPref` | false | — |
| `enableCollectionFLowOps` | false | — |
| `enableCollectionRiskScoringCFE` | false | — |
| `enableCollectionTimeline` | false | FSC Insurance editions |
| `showCollectionContactAndAccount` | false | — |

### AI / Einstein Fields

| Field | Default | Available Since |
|---|---|---|
| `enableReferralScoring` | false | FSC Insurance editions |
| `enableAccountScoreEnabled` | false | — |
| `enableB2BEinstein` | false | — |
| `enableWealthManagementAIPref` | false | API v63.0 |
| `enableCollectionRiskScoringCFE` | false | — |
| `enableEinsteinDocReaderMappings` | false | — |

### Discovery Framework Fields

| Field | Default | Available Since |
|---|---|---|
| `enableDiscoveryFrameworkMetadata` | false | — |
| `enableIndustriesAssessment` | false | — |
| `enableIndustriesKYC` | false | — |
| `enableEnhancedQuestionCreation` | false | — |

### Rollup / Performance Fields

| Field | Default | Available Since |
|---|---|---|
| `enableRBLUsingCalcService` | false | FSC Insurance editions |
| `enableRecordRollup` | false | FSC Insurance editions |
| `transformRBLtoDPE` | false | — |

### Sample IndustriesSettings XML (from fsc_dev_guide.pdf p.1318)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<IndustriesSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <allowMultipleProducersToWorkOnSamePolicy>true</allowMultipleProducersToWorkOnSamePolicy>
  <enableAccessToMasterListOfCoverageTypes>false</enableAccessToMasterListOfCoverageTypes>
  <enableCompliantDataSharingForAccount>true</enableCompliantDataSharingForAccount>
  <enableFSCInsuranceReport>false</enableFSCInsuranceReport>
  <enableInteractionSummaryPref>true</enableInteractionSummaryPref>
  <enableInteractionSummaryRoleHierarchy>true</enableInteractionSummaryRoleHierarchy>
  <enableManyToManyRelationships>true</enableManyToManyRelationships>
  <enableMortgageRlaTotalsOrgPref>true</enableMortgageRlaTotalsOrgPref>
  <enableRBLUsingCalcService>true</enableRBLUsingCalcService>
  <enableRecordRollup>true</enableRecordRollup>
  <enableReferralScoring>true</enableReferralScoring>
  <loanApplicantAddressAutoCreation>true</loanApplicantAddressAutoCreation>
  <loanApplicantAutoCreation>true</loanApplicantAutoCreation>
</IndustriesSettings>
```

**Package.xml reference:**
```xml
<types>
  <members>Industries</members>
  <name>Settings</name>
</types>
<version>47.0</version>
```

---

## RelationshipGraphDefinition Metadata

Source: fsc_dev_guide.pdf pp.1336–1339. Available API v55.0+. Requires FSC permission set license.

### What It Configures

`RelationshipGraphDefinition` configures the Actionable Relationship Centre (ARC) — defines how the graph traverses object hierarchies, which related objects appear, how records are sorted and filtered, and what UI actions are available on each node. This metadata is the **deployable** portion of ARC configuration (UI-only ARC settings still require manual configuration per environment).

### Key Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | Yes | User-friendly name; displayed in Setup as "Label" |
| `isActive` | boolean | Yes | Whether graph is available for use (default: true; read-only in API v55.0) |
| `isTemplate` | boolean | Yes | Whether this graph can be used as a template (default: false); displayed as "Set as Template" in UI |
| `relationshipGraphDefVersions` | RelationshipGraphDefVersion[] | Yes | List of graph versions |

### RelationshipGraphDefVersion Sub-fields

| Field | Type | Required | Description |
|---|---|---|---|
| `graphType` | string | Yes | Type of graph. In API v55.0, only `HorizontalHierarchy` is supported |
| `graphDefinition` | string | Yes | JSON string defining the full graph structure: root node, child relationships, sort fields, filter criteria, UI actions, display fields |

### graphDefinition JSON Structure

```json
{
  "graph": {
    "rootNode": {
      "object": { "entity": "Account" },
      "configurationType": "Primary",
      "sortFields": [{ "field": { "field": "LastModifiedDate", "whichEntity": "TARGET" }, "order": "DESC" }],
      "nodeUiConfig": {
        "fieldsToDisplay": [],
        "showFieldLabels": true,
        "actions": {}
      },
      "childRelationships": [{
        "OneToMany": {
          "targetObjectNode": {
            "object": { "entity": "Contact" },
            "configurationType": "Custom",
            "nodeUiConfig": {
              "fieldsToDisplay": [
                { "field": "Name", "whichEntity": "TARGET" },
                { "field": "Phone", "whichEntity": "TARGET" }
              ],
              "actions": {
                "containerActions": [{ "action": "New" }],
                "recordActions": [{ "action": "Edit" }, { "action": "Delete" }]
              }
            },
            "filter": {
              "filterCriteria": [{ "field": { "field": "Name", "whichEntity": "TARGET" }, "operator": "eq", "value": "Salesforce" }],
              "booleanFilter": "1"
            }
          }
        }
      }]
    },
    "globalUiConfig": {
      "borderColor": "Green2",
      "borderThickness": "2px",
      "fieldLayout": "Vertically Stacked",
      "recordContainerExpansion": true,
      "recordExpansion": true
    }
  }
}
```

**Package.xml reference:**
```xml
<types>
  <members>*</members>
  <name>RelationshipGraphDefinition</name>
</types>
<version>55.0</version>
```

---

## RetrievalSummaryDefinition Metadata

Source: fsc_dev_guide.pdf pp.1340–1341 (field reference), pp.1297–1298 (response body). Available API v61.0+.

### What It Configures

`RetrievalSummaryDefinition` stores header information for a retrieval definition — it configures **data retrieval patterns for summarizing related records across object relationships**. Used to configure the `getAssessmentResponseSummary` invocable action's data model and to support rollup-style summary views in FSC Lightning components.

The response body includes: `lastRefresh` (Long Date — last refresh of rollups), `rootNode` (developer name of fields), plus nested `RetrievalSummaryResultNode` and `RetrievalSummaryResultRecord` structures.

### Key Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | Yes | User-friendly name when RetrievalSummaryDefinition is created |
| `retrievalSummaryDefFields` | RetrievalSummaryDefField[] | No | Collection of fields to retrieve from the root object; each specifies which field from target object to include and processing order |
| `retrievalSummaryDefObjects` | RetrievalSummaryDefObject[] | No | Collection of object definitions for the retrieval definition |

### Response Output Structure

When used via API (e.g., through `getAssessmentResponseSummary`):

| Property | Type | Description |
|---|---|---|
| `lastRefresh` | Long Date | Last refresh date of rollups (API v61+) |
| `rootNode` | RetrievalSummaryResultRootNode | Developer name of fields; contains `children`, `fields`, `name`, `type` |
| `rootNode.children` | RetrievalSummaryResultNode[] | Child nodes of the root node; each has `label`, `name`, `records`, `type` |
| `rootNode.fields` | Map<String, Object> | Fields on the root node |

**Package.xml reference:**
```xml
<types>
  <members>*</members>
  <name>RetrievalSummaryDefinition</name>
</types>
<version>61.0</version>
```

---

## ParticipantRole Metadata

Source: fsc_dev_guide.pdf pp.1330–1332. Available API v50.0+.

### What It Configures

`ParticipantRole` defines the name and default sharing access level for a role that a participant can hold in the context of a parent record. Used to configure which roles exist on FSC objects that support participant-based access (e.g., who is an "Advisor" on an Account, who is a "Syndicate Member" on a FinancialDeal).

### Key Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | Yes | Name for the participant role (e.g., "Advisor", "Underwriter") |
| `defaultAccessLevel` | picklist | Yes | Default sharing access: `None`, `Read` (Read Only), `Edit` (Read/Write) |
| `isActive` | boolean | No | Whether the participant role is active |
| `parentObject` | string | Yes | The parent object for this role |

### Supported parentObject Values

| Value | Available Since |
|---|---|
| `Account` | API v50.0 |
| `FinancialDeal` | API v52.0 |
| `Interaction` | API v52.0 |
| `InteractionSummary` | API v51.0 |
| `Opportunity` | API v50.0 |
| `Budget` | API v59.0 |
| `IndividualApplication` | API v59.0 |
| `FundingAward` | API v59.0 |
| `FundingOpportunity` | API v50.0 |
| `Team` | API v58.0 |
| Custom objects | API v50.0 |

### Sample ParticipantRole XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ParticipantRole xmlns="http://soap.sforce.com/2006/04/metadata">
  <defaultAccessLevel>Read</defaultAccessLevel>
  <isActive>true</isActive>
  <masterLabel>Advisor</masterLabel>
  <parentObject>Account</parentObject>
</ParticipantRole>
```

**Package.xml reference:**
```xml
<types>
  <members>*</members>
  <name>ParticipantRole</name>
</types>
<version>50.0</version>
```

---

## RelatedRecordAssocCriteria Metadata

Source: fsc_dev_guide.pdf pp.1333–1335. Available API v52.0+. Requires FSC Extension permission set.

### What It Configures

`RelatedRecordAssocCriteria` configures criteria for automatically linking records (accounts, leads, opportunities, cases) with the BranchUnits that work with them. When the criteria condition is met, a `BranchUnitRelatedRecord` is automatically created.

### Key Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | Yes | Internal label for the criteria (not translated) |
| `associationType` | enumeration | Yes | `BranchManagement` (only supported value) |
| `eventType` | enumeration | Yes | Event that triggers association: `Create` or `Update` |
| `referenceObject` | string | Yes | The reference object for the association (e.g., `Account`) |
| `preCondition` | string | Yes | Formula that, when true, creates a new association (e.g., `[Account].AnnualRevenue > 3000000`) |
| `status` | enumeration | Yes | `Active`, `Draft`, or `Inactive` |
| `description` | string | No | Description of the criteria |
| `selectedOwnerField` | string | No | Alternative to default Owner ID for determining the owner |
| `associationHandlerApexClass` | string | No | Custom Apex class implementing `fscwmgen.BranchManagementAssociationHandler` interface for unsupported objects |

### Sample RelatedRecordAssocCriteria XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<RelatedRecordAssocCriteria xmlns="http://soap.sforce.com/2006/04/metadata">
  <associationType>BranchManagement</associationType>
  <eventType>Create</eventType>
  <masterLabel>RevenueThreeMillion</masterLabel>
  <preCondition>[Account].AnnualRevenue > 3000000</preCondition>
  <referenceObject>Account</referenceObject>
  <status>Active</status>
</RelatedRecordAssocCriteria>
```

---

## ClaimFinancialSettings Metadata

Source: fsc_dev_guide.pdf pp.1306–1308. Available API v57.0+. Requires InsurancePolicyAdminAccess or InsuranceClaimMgmtAccess add-on license.

### What It Configures

`ClaimFinancialSettings` configures the pending financial authority status values used in the insurance claim financial workflow. These status values define the pending state before financial authority is granted at each level.

### Key Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | Yes | Unique label identifying these settings in the UI |
| `claimPendingAuthorityStatus` | string | Yes | Status value for pending financial authority on Claim |
| `claimCovPendingAuthStatus` | string | Yes | Status value for pending financial authority on Claim Coverage |
| `clmCovPymtDtlPendAuthSts` | string | Yes | Status value for pending financial authority on Claim Coverage Payment Detail |

### Sample ClaimFinancialSettings XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ClaimFinancialSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <claimCovPendingAuthStatus>Pending Authority</claimCovPendingAuthStatus>
  <claimPendingAuthorityStatus>Pending Authority</claimPendingAuthorityStatus>
  <clmCovPymtDtlPendAuthSts>Pending Authority</clmCovPymtDtlPendAuthSts>
  <masterLabel>Claim Financial Settings</masterLabel>
</ClaimFinancialSettings>
```

**Package.xml reference:**
```xml
<types>
  <members>*</members>
  <name>ClaimFinancialSettings</name>
</types>
<version>57.0</version>
```

---

## DocumentChecklistSettings Metadata

Source: fsc_dev_guide.pdf pp.1308–1309. Available API v55.0+.

### What It Configures

Org-level settings for `DocumentChecklistItem` objects. Controls custom sharing and deletion behaviour for document checklists used in mortgage/lending and onboarding flows.

### Key Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `dciCustomSharing` | boolean | false | Enables custom sharing rules for DocumentChecklistItem records |
| `deleteDCIWithFiles` | boolean | false | Enables deletion of DocumentChecklistItem records when files are deleted |

### Sample DocumentChecklistSettings XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<DocumentChecklistSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <dciCustomSharing>true</dciCustomSharing>
  <deleteDCIWithFiles>true</deleteDCIWithFiles>
</DocumentChecklistSettings>
```

**Package.xml reference:**
```xml
<types>
  <members>DocumentChecklist</members>
  <name>Settings</name>
</types>
<version>55.0</version>
```

---

## OmniScript Metadata (FSC/Discovery Framework)

Source: fsc_dev_guide.pdf pp.1319–1330. Available API v56.0+. Requires OmniStudio license + Discovery Framework enabled.

### What It Configures

`OmniScript` metadata type stores complete OmniScript and Integration Procedure definitions for FSC. When `designerCustomizationType` is `discoveryframework`, it configures KYC and onboarding assessment flows that integrate with `AssessmentQuestion` and `AssessmentQuestionSet` metadata.

### Key Fields (top-level)

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | Yes | OmniScript type value (e.g., `Discovery`) |
| `subType` | string | Yes | OmniScript sub-type value (e.g., `Framework`) |
| `language` | string | Yes | Language (e.g., `English`) |
| `uniqueName` | string | Yes | Unique name: `Type_SubType_Language_VersionNumber` |
| `versionNumber` | string | Yes | Version number |
| `isActive` | boolean | No | Whether active (default: false) |
| `isIntegrationProcedure` | boolean | No | Whether this is an Integration Procedure (default: false) |
| `omniProcessType` | enumeration | Yes | `OmniScript` |
| `designerCustomizationType` | string | No | Use `discoveryframework` for Discovery Framework |
| `omniProcessElements` | OmniProcessElement[] | No | Elements (steps, questions, actions) |

### Key Deployment Rules

1. If `designerCustomizationType = discoveryframework`, all question references in the OmniScript must be within `<uniqueIndex>` tags
2. Enable `enableDiscoveryFrameworkMetadata = true` in IndustriesSettings before deploying Discovery Framework OmniScripts
3. Deploy AssessmentQuestion records before the OmniScript that references them; if questions don't exist in target org, OmniScript deployment fails
4. OmniScripts of type Discovery Framework do not support IDX Workbench
5. `isMetadataCacheDisabled = true` disables metadata cache for Integration Procedures (useful for development/debugging)

---

## Icon Metadata

Source: fsc_dev_guide.pdf p.1311. Available API v49.0+. Requires Health Cloud or FSC license.

### What It Configures

Maps custom icon images (stored as ContentAsset) to FSC object types for timeline and milestone display.

### Key Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `usageType` | IconUsageType | Yes | Object being mapped: `PersonLifeEvent`, `InsurancePolicy`, `BusinessMilestone`, `AssetMilestone`, `FinancialAccountMilestone` |
| `key` | string | Yes | Field value on the object (e.g., `birthday`, `marriage`, `childbirth` for PersonLifeEvent) |
| `image` | string | Yes | ContentAsset name holding the icon image |

### Sample Icon XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Icon xmlns="http://soap.sforce.com/2006/04/metadata">
  <usageType>PersonLifeEvent</usageType>
  <key>Birth</key>
  <image>BirthIcon</image>
</Icon>
```

---

## Tooling API Objects — FSC-Specific

Source: fsc_dev_guide.pdf p.1359 (Tooling API chapter introduction).

| Tooling API Object | Available Since | Purpose |
|---|---|---|
| `ClaimFinancialSettings` | API v57.0 | Query/manage insurance claim financial authority settings |
| `RelationshipGraphDefinition` | API v55.0 | Query/manage ARC relationship graph definitions |
| `RevenueSourceCategoryConfig` | API v57.0 | Query Revenue Data Source stage information and revenue metrics |
| `RevenueSourceObjectConfig` | API v57.0 | Query data from underlying Salesforce objects storing opportunity/product revenue data |
| `StageCondition` | API v62.0 | Query stage transition rules and criteria (Discovery Framework) |

### ClaimFinancialSettings Tooling API Fields

| Field | Type | Properties |
|---|---|---|
| `ClaimCovPendingAuthStatus` | string | Create, Filter, Group, Sort, Update |
| `ClaimPendingAuthorityStatus` | string | Create, Filter, Group, Sort, Update |
| `ClmCovPymtDtlPendAuthSts` | string | Create, Filter, Group, Sort, Update |
| `DeveloperName` | string | Create, Filter, Group, Sort, Update |
| `Language` | picklist | Create, Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort, Update |
| `ManageableState` | picklist | Filter, Group, Nillable, Restricted picklist, Sort |

**Supported SOAP API Calls:** create(), delete(), describeSObjects(), query(), retrieve(), update(), upsert()
**Supported REST API Methods:** DELETE, GET, HEAD, PATCH, POST, Query
