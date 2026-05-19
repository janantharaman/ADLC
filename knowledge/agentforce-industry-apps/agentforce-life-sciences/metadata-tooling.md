---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Life Sciences Cloud — Metadata & Tooling

## Metadata Types (PDF pp.1827-1869)

### Summary Table

| Metadata Type | API Version | File Suffix | Directory | Wildcard (*) |
|---|---|---|---|---|
| `CareBenefitVerifySettings` | v52.0+ | `.careBenefitVerifySettings` | `careBenefitVerifySettings/` | Yes |
| `CareLimitType` | v52.0+ | `.careLimitType` | `careLimitTypes/` | Yes |
| `CareRequestConfiguration` | v44.0+ | `.careRequestConfiguration` | `careRequestConfigurations/` | Yes |
| `CareSystemFieldMapping` | v49.0+ | `.careSystemFieldMapping` | `careSystemFieldMappings/` | N/A |
| `CareProviderAfflRoleConfig` | Tooling API only | N/A | N/A | N/A |
| `CareProviderSearchConfig` | v48.0+ | `.careProviderSearchConfig` | `careProviderSearchConfigs/` | N/A |
| `IndustriesSettings` | v61.0+ | See Settings | `settings/Industries.settings` | N/A |
| `IndustriesUnifiedInventorySettings` | v61.0+ | See Settings | `settings/` | N/A |
| `LifeSciConfigCategory` | — | — | — | — |
| `LifeSciConfigRecord` | — | — | — | — |
| `ProviderSampleLimitTemplate` | v66.0 | `.providerSampleLimitTemplate` | `providerSampleLimitTemplates/` | Yes |
| `SearchResultActionConfig` | v59.0+ | `.SearchResultActionConfigSettings` | `SearchResultActionConfigSettings/` | Yes |
| `TimelineObjectDefinition` | v55.0+ | `.timelineObjectDefinition` | `timelineObjectDefinitions/` | Yes |
| `UIObjectRelationConfig` | v54.0+ | `.uiObjectRelationConfig` | `uiObjectRelationConfigs/` | Yes |
| `ActionableListDefinition` | v57.0+ | `.actionableListDefinition` | `actionableListDefinitions/` | Yes |
| `Flow for Life Sciences Cloud` | Extends standard Flow | — | `flows/` | Yes |

---

## Metadata Type Details

### CareBenefitVerifySettings (v52.0+)

Represents configuration settings for benefit verification requests.

**File suffix:** `.careBenefitVerifySettings`
**Directory:** `careBenefitVerifySettings/`

| Field | Type | Description |
|---|---|---|
| `codeSetType` | string | Code set type for benefits verification service type codes |
| `defaultNpi` | string | Default National Provider Identifier for verification requests |
| `generalPlanServiceTypeCode` | string | Service type code for the plan benefits as a whole |
| `isDefault` | boolean | Whether this is the default verification service |
| `masterLabel` | string | Required. Name of the benefits verification service |
| `organizationName` | string | Organization name for the verification request service |
| `serviceApexClass` | string | Apex class used to access the benefits verification service |
| `serviceNamedCredential` | string | Named Credential used to access the service |
| `serviceTypeSourceSystem` | string | Service type code for the plan benefits as a whole |
| `uriPath` | string | Link to payer endpoint |

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CareBenefitVerifySettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <generalPlanServiceTypeCode>30</generalPlanServiceTypeCode>
  <isDefault>true</isDefault>
  <masterLabel>PrimaryPayerBenefits</masterLabel>
  <serviceApexClass>PayerBenefitVerifyService</serviceApexClass>
  <serviceNamedCredential>PayerAPI_Prod</serviceNamedCredential>
  <uriPath>/benefits/verify/v2</uriPath>
  <serviceTypeSourceSystem>NCPDP</serviceTypeSourceSystem>
  <codeSetType>NDC</codeSetType>
  <defaultNpi>1234567890</defaultNpi>
  <organizationName>BioPharm Corp</organizationName>
</CareBenefitVerifySettings>
```

---

### CareLimitType (v52.0+)

Defines characteristics of limits on benefit provision.

**File suffix:** `.careLimitType`
**Directory:** `careLimitTypes/`

| Field | Type | Description |
|---|---|---|
| `isProtected` | boolean | Auto-generated; doesn't impact behavior |
| `limitType` | string | Source of limit (e.g., co-insurance requirement) |
| `masterLabel` | string | Required. Name of the limit type |
| `metricType` | `CareLimitTypeMetricType` | Metric for calculating benefit limit: `Amount`, `Money`, `Percentage`, `Text` |

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CareLimitType xmlns="http://soap.sforce.com/2006/04/metadata">
  <limitType>CoinsuranceRequirement</limitType>
  <masterLabel>Coinsurance 80/20</masterLabel>
  <metricType>Percentage</metricType>
  <isProtected>false</isProtected>
</CareLimitType>
```

---

### CareRequestConfiguration (v44.0+)

Represents record type configuration for service requests, drug requests, or admission requests.

**File suffix:** `.careRequestConfiguration`
**Directory:** `careRequestConfigurations/`

| Field | Type | Required | Description |
|---|---|---|---|
| `careRequestRecordType` | string | Yes | The record type for the care request |
| `careRequestRecords` | `CareRequestRecords[]` | — | List of objects configuring the care request |
| `careRequestType` | string | Yes | Type of care request (appeal, service request, admission) |
| `isActive` | boolean | — | Whether the care request is active |
| `masterLabel` | string | Yes | User-friendly name |

**CareRequestRecords sub-object:**

| Field | Type | Required | Description |
|---|---|---|---|
| `careRequestRecord` | string | Yes | The object selected to configure the care request |

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CareRequestConfiguration xmlns="http://soap.sforce.com/2006/04/metadata">
  <careRequestRecordType>DrugRequest</careRequestRecordType>
  <careRequestRecords>
    <careRequestRecord>CareRequestItem</careRequestRecord>
  </careRequestRecords>
  <careRequestRecords>
    <careRequestRecord>CareRequestDrug</careRequestRecord>
  </careRequestRecords>
  <careRequestType>Drug Request</careRequestType>
  <isActive>true</isActive>
  <isDefaultRecordType>false</isDefaultRecordType>
  <masterLabel>DrugRequest</masterLabel>
</CareRequestConfiguration>
```

---

### CareSystemFieldMapping (v49.0+)

Maps source system fields to Salesforce objects and fields.

**Special Access:** Health Cloud or Life Sciences Cloud license + Health Cloud Foundation or Health Cloud Starter permission set required.

**File suffix:** `.careSystemFieldMapping`
**Directory:** `careSystemFieldMappings/`

| Field | Type | Required | Description |
|---|---|---|---|
| `externalIdField` | string | — | ID of the field in the external system |
| `isActive` | boolean | — | Whether mapping is active (default: false) |
| `isProtected` | boolean | — | Auto-generated |
| `masterLabel` | string | Yes | Name of the care system field mapping |
| `role` | `SourceSystemFieldRole` | Yes | Role the field represents. Valid values: `Patient`, `RemoteMonitoringDevice`, `RemoteMonitoringPatient`, `ServiceProvider`, `NotApplicable` |
| `sourceSystem` | string | — | System where the record originated |
| `targetObject` | string | — | Salesforce object to which the external field maps |

**Role → targetObject rules:**
- `Patient` → targetObject = `Account`; used by Enrollment API as patient ID
- `RemoteMonitoringDevice` → targetObject = `Asset`; maps to `CareObservation.Device`
- `RemoteMonitoringPatient` → targetObject = `Account`; maps to `CareObservation.ObservedSubject`
- `ServiceProvider` → targetObject = `Account`; used by Enrollment API as provider ID
- `NotApplicable` → targetObject = `CareProgram` or `Product`

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CareSystemFieldMapping xmlns="http://soap.sforce.com/2006/04/metadata">
  <externalIdField>EpicPatientId</externalIdField>
  <isActive>true</isActive>
  <isProtected>false</isProtected>
  <masterLabel>Epic_Patient_Mapping</masterLabel>
  <role>Patient</role>
  <sourceSystem>Epic</sourceSystem>
  <targetObject>Account</targetObject>
</CareSystemFieldMapping>
```

---

### CareProviderSearchConfig (v48.0+)

Configures fields that appear in care provider search results.

**File suffix:** `.careProviderSearchConfig`
**Directory:** `careProviderSearchConfigs/`

| Field | Type | Required | Description |
|---|---|---|---|
| `isActive` | boolean | — | Whether configuration is active |
| `isProtected` | boolean | — | Auto-generated |
| `mappedObject` | `ProviderSearchObjectMapping` | Yes | `HealthCarePractitionerFacility` or `HealthCareProvider` |
| `masterLabel` | string | Yes | Name of the care provider |
| `sourceField` | string | — | API name of the field copied to the target object |
| `targetField` | string | — | API name of the field to copy data to |

---

### IndustriesSettings (v61.0+)

Represents all Life Sciences Cloud feature toggles.

**Stored as:** `settings/Industries.settings`
**Accessed in package manifest as:** `<members>Industries</members><name>Settings</name>`

Key fields for Life Sciences Cloud (see overview.md for full list):

| Field | Type | Description |
|---|---|---|
| `enableAccountBasedSharing` | boolean | Enable Account-Based Sharing |
| `enableAdverseEvents` | boolean | Adverse Events data model |
| `enableAppAlerts` | boolean | In-app alerts and notifications |
| `enableLifeSciencesClinialTrailManagement` | boolean | Clinical Trial Management |
| `enableLifeSciencesConsent` | boolean | Consent management |
| `enableLifeSciencesCustomerEngagementBase` | boolean | Foundation for LS C4CE |
| `enableLSC4CEPackage` | boolean | Core Customer Engagement package |
| `enableLSC4CEVisits` | boolean | Visit management |
| `enableLSC4CEKeyAccountManagement` | boolean | Key Account Management |
| `enableNextBestAction` | boolean | AI Next Best Action |
| `enablePATSTerritoryBasedSharing` | boolean | Territory-Based Sharing (PATS) |
| `enableProdTerrAvlRecSharing` | boolean | Product Territory record sharing |

---

### ProviderSampleLimitTemplate (v66.0)

Template defining sample limit rules for providers.

**File suffix:** `.providerSampleLimitTemplate`
**Directory:** `providerSampleLimitTemplates/`

Key fields: `isActive`, `isAdvanced`, `isCloned`, `isLawBased`, `priorityNumber`, `discrepancyAlertType`, `ruleCondition`, `ruleExpression`

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ProviderSampleLimitTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
  <fullName>SampleLimitTemplate_Standard</fullName>
  <label>Standard Sample Limit Template</label>
  <isActive>true</isActive>
  <isAdvanced>false</isAdvanced>
  <isCloned>false</isCloned>
  <isLawBased>true</isLawBased>
  <priorityNumber>1</priorityNumber>
  <discrepancyAlertType>Warning</discrepancyAlertType>
  <ruleCondition>Account.Type = 'Provider'</ruleCondition>
  <ruleExpression>SampleQuantity &lt;= 100</ruleExpression>
</ProviderSampleLimitTemplate>
```

---

### SearchResultActionConfig (v59.0+)

Configures actions a user can perform on criteria-based search results.

**Special Access:** "Criteria-Based Search and Filter" must be enabled in org.

**File suffix:** `.SearchResultActionConfigSettings`
**Directory:** `SearchResultActionConfigSettings/`

| Field | Type | Required | Description |
|---|---|---|---|
| `actionReference` | string | Yes | ID of the action instance (Flow API name, LWC API name, or OmniScript name) |
| `actionScope` | `SearchResultActionScope` | Yes | `Global` (all record types) or `Inline` (single record, v64.0+) |
| `actionType` | `SearchResultActionType` | Yes | `FlowDefinition`, `LightningWebComponent`, or `OmniScript` (v60.0+) |
| `agentConfirmationMessage` | string | — | Confirmation message for agent (255 char max, v64.0+) |
| `description` | string | — | Description of the action config |
| `isAiAction` | boolean | — | Whether action uses generative AI (default: false, v64.0+) |
| `masterLabel` | string | Yes | Display name in search page |

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<SearchResultActionConfig xmlns="http://soap.sforce.com/2006/04/metadata">
  <actionReference>Create_Case_For_Provider</actionReference>
  <actionScope>Global</actionScope>
  <actionType>FlowDefinition</actionType>
  <description>Screen flow to create a case for a provider.</description>
  <isAiAction>false</isAiAction>
  <masterLabel>Create Case</masterLabel>
</SearchResultActionConfig>
```

---

### TimelineObjectDefinition (v55.0+)

Stores timeline configuration for chronological view of records.

**Special Access:** "Timeline" org preference must be enabled.

**File suffix:** `.timelineObjectDefinition`
**Directory:** `timelineObjectDefinitions/`

| Field | Type | Required | Description |
|---|---|---|---|
| `baseObject` | string | Yes | Object on which timeline is based (Salesforce or custom object) |
| `definition` | string | Yes | Timeline definition in JSON format |
| `isActive` | boolean | — | Whether timeline is active |
| `masterLabel` | string | Yes | UI label of the timeline definition |

**Note:** The `definition` field contains a complex nested JSON structure defining anchor object, events, filters, and sort orders. See PDF p.1845 for full JSON schema example.

---

### UIObjectRelationConfig (v54.0+)

Admin-created configuration for the object relation UI component.

**Special Access:** Health Cloud or Life Sciences Cloud customer required.

**File suffix:** `.uiObjectRelationConfig`
**Directory:** `uiObjectRelationConfigs/`

| Field | Type | Required | Description |
|---|---|---|---|
| `contextObject` | string | Yes | Object providing context for this configuration |
| `contextObjectRecordType` | string | — | Record type of context object (if applicable) |
| `directRelationshipField` | string | — | Child relationship field for direct relationships |
| `indirectObjectContextField` | string | — | Junction object field matching context object |
| `indirectObjectRelatedField` | string | — | Junction object field matching related object |
| `indirectRelationshipObject` | string | — | Junction object for indirect relationships |
| `isActive` | boolean | — | Whether configuration is active |
| `masterLabel` | string | Yes | UI label |
| `relatedObject` | string | Yes | Object containing data to display |
| `relatedObjectRecordType` | string | — | Record type of related object |
| `relationshipType` | `ObjectRelationshipType` | Yes | `Direct`, `Indirect`, `InverseDirect`, or `Self` |
| `UIObjectRelationFieldConfigs` | `UIObjectRelationFieldConfig[]` | — | Field configuration rows |

**UIObjectRelationFieldConfig sub-object:**

| Field | Type | Required | Description |
|---|---|---|---|
| `displayLabel` | string | Yes | User-defined label for this field row |
| `queryText` | string | Yes | JSON-based traversal query (not SOQL) |
| `rowOrder` | int | Yes | Display order (top-to-bottom) |

---

### ActionableListDefinition (v57.0+)

Data source definition for an actionable list.

**File suffix:** `.actionableListDefinition`
**Directory:** `actionableListDefinitions/`

| Field | Type | Required | Description |
|---|---|---|---|
| `batchCalcJobDefinition` | string | — | Batch calculation job for creating the actionable list |
| `datasetName` | string | — | Dataset associated with the actionable list |
| `edgeMart` | string | — | EdgeMart dataset (v58.0+) |
| `isActive` | boolean | — | Whether definition is active (default: false) |
| `masterLabel` | string | Yes | Required. Master label |
| `objectName` | picklist | Yes | Object for which list is created: `Account`, `Asset`, `CareRequest`, `Case`, `Claim`, `Contact`, `HealthcareFacility`, `InsurancePolicy`, `Lead`, `MemberPlan`, `Opportunity`, etc. |
| `type` | picklist | — | List type: `RetailStoreList` or `HealthcareProviderList` |

---

### Flow for Life Sciences Cloud

Extends the standard `Flow` metadata type with additional LSC-specific `actionType` values for `FlowActionCall`:

| actionType Value | Description |
|---|---|
| `assignCndtToResearchStudyGroup` | Assign candidates to research study comparison groups |
| `generateResearchStudyBlocks` | Generate randomization block records |
| `getContextData` | Retrieve context data for prompt templates |
| `processCriteriaMatchingResp` | Parse GPT-generated criteria matching response for study candidates |
| `serializeHierarchicalContextData` | Serialize hierarchical context data for prompt templates |

---

## Tooling API Objects (PDF pp.1762-1827)

Key Tooling API objects available for LSC development tooling:

| Object | Description |
|---|---|
| `AssessmentConfiguration` | Configuration for assessments (OmniStudio-backed) |
| `CareBenefitVerifySettings` | Tooling API access to benefit verification settings |
| `CareLimitType` | Tooling API access to care limit type definitions |
| `CareProviderAfflRoleConfig` | Configuration for provider affiliation roles |
| `CareProviderSearchConfig` | Tooling API access to provider search config |
| `CareRequestConfiguration` | Tooling API access to care request configurations |
| `CareSystemFieldMapping` | Tooling API access to system field mappings |
| `TimelineObjectDefinition` | Tooling API access to timeline definitions |
| `SearchableObjDataSyncInfo` | Data sync info for searchable objects |
| `SearchCriteriaConfiguration` | Configuration for criteria-based search |
| `LifeSciConfigCategory` | Category for Life Sciences configuration records |
| `ProviderSampleLimitTemplate` | Tooling API access to sample limit templates |

---

## CI/CD Considerations

### Deployment Order

Deploy LSC metadata components in this sequence to avoid dependency errors:

1. **Permission Sets** — deploy before settings that require them
2. **IndustriesSettings** — feature flags (deploy carefully; some are irreversible)
3. **CareSystemFieldMapping** — field mapping config
4. **CareBenefitVerifySettings + NamedCredential** — together (NamedCredential must exist first)
5. **CareRequestConfiguration + RecordTypes + BusinessProcess** — together (see sample package.xml)
6. **CareProviderSearchConfig** — after provider objects available
7. **ProviderSampleLimitTemplate** — after sample management enabled
8. **SearchResultActionConfig** — after Flows and LWC deployed
9. **TimelineObjectDefinition + UIObjectRelationConfig** — after base objects exist
10. **ActionableListDefinition** — after CRM Analytics datasets configured
11. **Flows** — after all referenced objects and metadata exist

### Validate-Only Deploy

```bash
sf project deploy start \
  --manifest package.xml \
  --target-org production-alias \
  --dry-run
```

### Common Deployment Errors

| Error | Cause | Fix |
|---|---|---|
| `FIELD_INTEGRITY_EXCEPTION` on IndustriesSettings | Feature dependency not met (e.g., enabling Clinical Trial Management before base engagement) | Enable prerequisite settings first; deploy in sequence |
| `INVALID_TYPE` on LSC objects | API version too low, or missing Life Sciences Cloud license | Set API version to 66.0+; verify license |
| `Named Credential not found` for CareBenefitVerifySettings | Named Credential not deployed/created in target org | Deploy Named Credential before CareBenefitVerifySettings |
| `Cannot modify isCloned field` on ProviderSampleLimitTemplate | Attempting to set isCloned programmatically | isCloned is system-managed; do not include in metadata deploy if value is true |
| `SearchResultActionConfig requires Criteria-Based Search` | Feature not enabled in target org | Enable "Criteria-Based Search and Filter" in IndustriesSettings first |

---

## Salesforce CLI Commands

**Retrieve all LSC metadata:**
```bash
sf project retrieve start \
  --metadata "Settings:Industries" \
  --metadata "CareBenefitVerifySettings:*" \
  --metadata "CareSystemFieldMapping:*" \
  --metadata "CareRequestConfiguration:*" \
  --metadata "CareProviderSearchConfig:*" \
  --metadata "ProviderSampleLimitTemplate:*" \
  --metadata "TimelineObjectDefinition:*" \
  --target-org sandbox-alias
```

**Deploy to production (validate first):**
```bash
# Step 1: validate
sf project deploy start \
  --manifest package.xml \
  --target-org prod-alias \
  --dry-run

# Step 2: deploy
sf project deploy start \
  --manifest package.xml \
  --target-org prod-alias
```
