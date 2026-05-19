---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Health Cloud — Metadata Types and Tooling API

## Metadata Types Table

**Source:** PDF pp.2224-2295 (Metadata Types section)

All metadata types listed below are Health Cloud-specific. They extend the standard `Metadata` base type and inherit its `fullName` field.

---

### CareBenefitVerifySettings
**Purpose:** Configuration settings for benefit verification requests.
**File suffix:** `.careBenefitVerifySettings`
**Directory:** `careBenefitVerifySettings/`
**API version:** 52.0 and later
**Wildcard support:** Supported in package.xml

| Field | Type | Required | Description |
|---|---|---|---|
| `codeSetType` | string | No | The code set type for the benefits verification service type codes |
| `defaultNpi` | string | No | Default National Provider Identifier for benefits verification requests |
| `generalPlanServiceTypeCode` | string | No | Service type code for the plan benefits as a whole |
| `isDefault` | boolean | No | Whether this is the default verification service |
| `masterLabel` | string | **Yes** | Name of the benefits verification service |

**Use:** Deploy this metadata type to configure payer connectivity settings for the Benefits Verification domain. One configuration per payer system integration.

---

### CareLimitType
**Purpose:** Defines the characteristics of limits on benefit provision.
**Source:** Listed in PDF p.2224 — "Defines the characteristics of limits on benefit provision."
**Note:** Full field specification not found in extracted pages — verify separately in full PDF section.

---

### CareRequestConfiguration
**Purpose:** Represents the details for a record type such as service request, drug request, or admission request. One or more record types can be associated with a care request.
**File suffix:** `.careRequestConfiguration`
**Directory:** `careRequestConfigurations/`
**API version:** 44.0 and later
**Wildcard support:** Supported in package.xml

| Field | Type | Required | Description |
|---|---|---|---|
| `careRequestRecordType` | string | **Yes** | The record type for the care request |
| `careRequestType` | string | **Yes** | The type of care request (e.g., "appeal", "service request", "admission") |
| `isActive` | boolean | No | Whether the care request is active |
| `isDefaultRecordType` | boolean | No | Whether this is the default record type |
| `masterLabel` | string | **Yes** | User-friendly name |
| `careRequestRecords` | CareRequestRecords[] | No | List of objects to configure the care request |

**CareRequestRecords subtype:**

| Field | Type | Required | Description |
|---|---|---|---|
| `careRequestRecord` | string | **Yes** | The object selected to configure the care request (e.g., CareRequestItem, CareRequestDrug) |

**Declarative sample:**
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
  <isActive>false</isActive>
  <isDefaultRecordType>false</isDefaultRecordType>
  <masterLabel>DrugRequest</masterLabel>
</CareRequestConfiguration>
```

**package.xml sample:**
```xml
<types>
  <members>Case.DrugRequest</members>
  <name>BusinessProcess</name>
</types>
<types>
  <members>*</members>
  <name>CareRequestConfiguration</name>
</types>
<types>
  <members>CareRequest.DrugRequest</members>
  <members>CareRequestDrug.DrugRequest</members>
  <members>CareRequestItem.DrugRequest</members>
  <members>Case.DrugRequest</members>
  <name>RecordType</name>
</types>
<version>44.0</version>
```

---

### CareSystemFieldMapping
**Purpose:** Represents a mapping from source system fields to Salesforce objects and fields. Used for the Enrollment API to map external patient IDs to Salesforce Account records, and for Remote Monitoring device mappings.
**File suffix:** `.careSystemFieldMapping`
**Directory:** `careSystemFieldMappings/`
**API version:** 49.0 and later
**Access:** Requires Health Cloud or Life Sciences Cloud license + Health Cloud Foundation (or Health Cloud Starter for Life Sciences) permission set

| Field | Type | Required | Description |
|---|---|---|---|
| `externalIdField` | string | No | The ID of the field in the external system |
| `isActive` | boolean | No | Whether the mapping is active (default: false) |
| `isProtected` | boolean | No | Auto-generated; does not currently affect behavior |
| `masterLabel` | string | **Yes** | Name of the care system field mapping |
| `role` | SourceSystemFieldRole | **Yes** | Role the field represents. Valid values: `Patient`, `RemoteMonitoringDevice`, `RemoteMonitoringPatient`, `ServiceProvider`, `NotApplicable` |
| `sourceSystem` | string | No | The system where the record originated (e.g., "Epic") |
| `targetObject` | string | No | The Salesforce object to which the external field is mapped |

**Role descriptions:**
- `Patient` — Enrollment API uses `externalIdField` as patient ID; used when `targetObject` = Account
- `RemoteMonitoringDevice` — Maps `externalIdField` on Asset to Device field in CareObservation; used when `targetObject` = Asset
- `RemoteMonitoringPatient` — Maps `externalIdField` on Account to ObservedSubject in CareObservation; used when `targetObject` = Account
- `ServiceProvider` — Enrollment API uses `externalIdField` as provider ID; used when `targetObject` = Account
- `NotApplicable` — Used when `targetObject` = CareProgram or Product

**Declarative sample:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CareSystemFieldMapping xmlns="http://soap.sforce.com/2006/04/metadata">
  <externalIdField>AccountNumber</externalIdField>
  <isActive>true</isActive>
  <isProtected>false</isProtected>
  <masterLabel>Map1</masterLabel>
  <role>Patient</role>
  <sourceSystem>Epic</sourceSystem>
  <targetObject>Account</targetObject>
</CareSystemFieldMapping>
```

---

### CareProviderSearchConfig
**Purpose:** Represents the information about the fields that appear in care provider search results.
**File suffix:** `.careProviderSearchConfig`
**Directory:** `careProviderSearchConfigs/`
**API version:** 48.0 and later

| Field | Type | Required | Description |
|---|---|---|---|
| `isActive` | boolean | No | Whether this configuration is active |
| `isProtected` | boolean | No | Auto-generated; does not affect behavior |
| `mappedObject` | ProviderSearchObjectMapping | **Yes** | Mapped object. Valid values: `HealthCarePractitionerFacility`, `HealthCareProvider` |
| `masterLabel` | string | **Yes** | Name of the care provider search configuration |
| `sourceField` | string | No | API name of the field copied to the target object |
| `targetField` | string | No | API name of the field to copy data to |

**package.xml includes:** Both the CareProviderSearchConfig member AND the CustomField members for both source and searchable field:
```xml
<types>
  <members>HealthcareProvider.Test1__c</members>
  <name>CustomField</name>
</types>
<types>
  <members>CareProviderSearchableField.Test1__c</members>
  <name>CustomField</name>
</types>
<types>
  <members>Test</members>
  <name>CareProviderSearchConfig</name>
</types>
```

---

### Flow for Health Cloud
**Purpose:** Represents the metadata associated with a Flow — specifically documenting the additional `actionType` values that Health Cloud adds to the standard FlowActionCall metadata type.
**Base type:** Extends standard Flow metadata type

**Health Cloud-specific FlowActionCall actionType values:**

| actionType Value | Purpose | API Version |
|---|---|---|
| `appointment` | Create or book a new appointment | v65.0+ |
| `createQuoteForHomeVisits` | Create a quote for patient home visits | v63.0+ |
| `createReferral` | Create a patient referral record | v59.0+ |
| `createTemplateOfServiceAppt` | Create a template service appointment (Cancelled status) for manual home visit scheduling | v63.0+ |
| `getResources` | Search for available resources (healthcare providers, medical assets) | — |
| `getResourcesForMnlScheduling` | Get recommended resources for manual start-of-care or recurring visit scheduling | — |
| `getTranscriptForConversation` | Get transcript for a conversation record (voice call, messaging session, chat transcript) | v64.0+ |
| `handleResourceAbsence` | Remove service resource visit assignments for a period; optionally update visit statuses | — |
| `invokeGenericFHIR` | Invoke an external service with provided payload as request body; return response | — |
| `processReceivedDocument` | Create a record with processed results of a received document | — |
| `scheduleHomeVisitManually` | Create start-of-care or recurring home visits with manually selected care resources | — |
| `scheduleHomeVisit` | Schedule a home visit to assess patient condition before scheduling recurring visits | — |
| `scheduleRecurringHomeVisit` | Create a set of recurring home healthcare visits; assign service resources per scheduling policy | — |

**Deployment note:** Flows using Health Cloud action types must be deployed to orgs where the corresponding Health Cloud features are enabled. Deploying a Flow with `actionType = scheduleRecurringHomeVisit` to an org without Home Health enabled will fail.

---

### Icon
**Purpose:** Represents the mapping of custom icons to objects (e.g., PersonLifeEvent icons, InsurancePolicy milestone icons).
**File suffix:** `.icon`
**Directory:** `icons/`
**API version:** 49.0 and later
**Access:** Requires Health Cloud or Financial Services Cloud license

| Field | Type | Required | Description |
|---|---|---|---|
| `image` | string | **Yes** | The image file mapped to the object (use ContentAsset metadata type to hold the icon image) |
| `key` | string | **Yes** | A field value in the object (e.g., for PersonLifeEvent: `birthday`, `marriage`, `childbirth`) |
| `usageType` | IconUsageType | **Yes** | The object mapped to the image. Valid values: `PersonLifeEvent`, `InsurancePolicy`, `BusinessMilestone`, `AssetMilestone`, `FinancialAccountMilestone` |

**Note:** The icon image referenced in the `image` field must be stored as a ContentAsset metadata type.

---

### IdentityVerificationProcDef
**Purpose:** Represents the definition of the identity verification process (for verifying patient/member identity before care coordination actions).
**File suffix:** `.IdentityVerificationProcDef`
**Directory:** `IdentityVerificationProcDefs/`
**API version:** 54.0 and later
**Access:** Health Cloud permission set license required
**Wildcard support:** Not explicitly stated — verify separately

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | **Yes** | Label of the Identity Verification Process Definition record |
| `searchLayoutType` | IdentityVerificationSearchLayoutType | **Yes** | Display layout of search component. Valid values: `Stack`, `Tab` |
| `identityVerificationProcDtls` | IdentityVerificationProcDtl[] | No | List of Identity Verification Process Detail elements |

---

### IdentityVerificationProcDtl
**Purpose:** Represents the verification-related details such as search criteria, verification criteria, or the custom Apex class.
**File suffix:** `.IdentityVerificationProcDtl`
**Directory:** `IdentityVerificationProcDtls/`
**API version:** 54.0 and later
**Wildcard support:** Supported in package.xml

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | **Yes** | Label of the Identity Verification Process Detail |
| `developerName` | string | **Yes** | Developer name (alphanumeric + underscores; must start with letter) |
| `dataSourceType` | IdentityVerificationDataSourceType | **Yes** | Data source type: `External` or `Salesforce` |
| `objectName` | string | No | Name of the Salesforce object searched and verified |
| `searchType` | IdentityVerificationSearchType | **Yes** | Type of search |
| `searchSequenceNumber` | int | **Yes** | Order in which search is performed |
| `searchRecordUniqueIdField` | string | No | Field storing unique identifier of a displayed record |
| `searchResultSortBy` | string | No | Values used to sort search results |
| `searchFilter` | string | No | Comma-separated list of predefined filter conditions |
| `optionalVerifiersMinVerfCount` | int | No | Minimum number of optional verifiers that must be checked |
| `isActive` | boolean | No | Whether the record is active |
| `isRetryAllowedAfterLimit` | boolean | No | For internal use only |
| `apexClass` | string | No | Apex class for searching and verifying data in an external system |
| `displayRecordFieldName` | string | No | Field name shown to user after successful verification (API v58.0+) |
| `linkedIdVerfProcessDet` | string | No | Linked identity verification process detail record (API v58.0+) |
| `identityVerificationProcFlds` | IdentityVerificationProcFld[] | No | List of Identity Verification Process Field elements |

---

### IdentityVerificationProcFld
**Purpose:** Represents the search and verification fields used in identity verification.
**File suffix:** `.IdentityVerificationProcFld`
**Directory:** `IdentityVerificationProcFlds/`
**API version:** 54.0 and later
**Access:** Health Cloud permission set license required
**Wildcard support:** Supported in package.xml

| Field | Type | Required | Description |
|---|---|---|---|
| `masterLabel` | string | **Yes** | Label of the Identity Verification Process Field |
| `developerName` | string | **Yes** | Developer name |
| `fieldName` | string | **Yes** | Label of the field containing verification data |
| `fieldType` | IdentityVerificationProcFldFieldType | **Yes** | Type of field. Values: `additionalResultField` (fetched but not displayed), `optionalVerifier`, `requiredVerifier`, `resultField` (displayed in results), `searchField` (reserved), `searchFilter` |
| `dataSourceType` | IdentityVerificationProcFldDataSourceType | **Yes** | `External` or `Salesforce` |
| `fieldDataType` | picklist | No | Data type of external source field: address, checkbox, currency, dateonly, datetime, email, number, other, percent, phone, picklist, reference, text, timeonly, url |
| `customFieldLabel` | string | No | Custom label for the verification data field |
| `fieldValueFormula` | string | No | Reserved for future use |
| `isActive` | boolean | No | Whether the record is active (default: false) |
| `isManualInput` | boolean | No | Whether the user can manually enter identity verification details (default: false; API v58.0+) |
| `sequenceNumber` | int | **Yes** | Sequence number of the field |

---

### IndustriesSettings
**Purpose:** Represents settings for Health Cloud (and other Industries clouds). This is the primary metadata type for enabling/disabling Health Cloud features at the org level.
**File location:** Single file `Industries.settings` in the `settings/` directory
**In package.xml:** Referenced as `Settings` with member `Industries`
**API version:** 47.0 and later
**Access:** Health Cloud permissions required

**Key fields for Health Cloud feature activation:**

| Field | Type | API Version | Description |
|---|---|---|---|
| `enableClinicalDataModel` | boolean | 51.0+ | Enable Clinical Data Model (FHIR R4-aligned objects) |
| `enableContactCenterAccess` | boolean | 56.0+ | Enable Contact Center for Health Cloud app |
| `enableCareMgmtSlackAccess` | boolean | 56.0+ | Enable Care Coordination for Slack app |
| `enableCustomFlowsOnCycleCount` | boolean | 56.0+ | Enable Custom Flows on Cycle Count page |
| `enableCustomFlowsOnExpiryPage` | boolean | 56.0+ | Enable Custom Flows on Expiry page |
| `enableDiseaseSurveillancePref` | boolean | 64.0+ | Enable Disease Surveillance (infectious disease monitoring) |
| `enableHcCorePatientConsole` | boolean | — | Enable OOTB Health Cloud Console App for Patients |
| `enableHcStdRelationshipJunctions` | boolean | — | Use core group membership settings instead of managed package settings |
| `enableHlsClinicalDcsnSuptAccessOrgPreference` | boolean | — | Enable Clinical Decision Support (CRD/DTR capabilities) |
| `enableHlsFhirSubscriptionSetting` | boolean | — | Enable Documentation Template Rule processes and FHIR Subscription data model for UM and Clinical Decision Support |
| `enableLifeSciencesClinialTrialManagement` | boolean | — | Enable clinical trial participant recruitment and enrollment |
| `enableMedicationManagementEnabled` | boolean | 53.0+ | Enable Medication Management |
| `enableMedicalDeviceEnabled` | boolean | — | Enable Intelligent Sales features |
| `enableMedRecSetting` | boolean | 54.0+ | Enable Medication Reconciliation |
| `enableMultipleCareProgramEnrolleeOrgPref` | boolean | 49.0+ | Enable Multiple Care Program Enrollee per patient |
| `enableProviderSearchSyncOrgPref` | boolean | — | Sync provider data search every six hours |
| `enableRosterFileFeatureOrgPreference` | boolean | — | Enable roster file feature for Provider Network Management |
| `enableTrialManagementConsentManagement` | boolean | — | Enable consent management for clinical trial candidates |
| `enableUMPayerAppAccessOrgPreference` | boolean | — | Enable OOTB Utilization Management Payers App |
| `enableVisitInventoryEnabled` | boolean | — | Enable visit data model |
| `IsHomeHealthEnabled` | boolean | — | Enable Home Health (scheduling and executing home healthcare visits) |
| `enableCandidateMatching` | boolean | — | Enable automatic candidate matching to clinical trials |
| `enableAuthorizationCustomSharingPCU` | boolean | — | Enable custom sharing for electronic consent forms with Customer Community Plus users |
| `enableIndustriesLPIPreference` | boolean | 63.0+ | Enable Industries Licensing, Permitting, and Inspections |

**Declarative sample (minimum Health Cloud activation):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<IndustriesSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableClinicalDataModel>true</enableClinicalDataModel>
  <enableContactCenterAccess>true</enableContactCenterAccess>
  <enableCareMgmtSlackAccess>true</enableCareMgmtSlackAccess>
  <enableMedicationManagementEnabled>true</enableMedicationManagementEnabled>
  <enableMedRecSetting>true</enableMedRecSetting>
  <enableMultipleCareProgramEnrolleeOrgPref>false</enableMultipleCareProgramEnrolleeOrgPref>
  <enableProviderSearchSyncOrgPref>true</enableProviderSearchSyncOrgPref>
  <IsHomeHealthEnabled>false</IsHomeHealthEnabled>
</IndustriesSettings>
```

**package.xml:**
```xml
<types>
  <members>Industries</members>
  <name>Settings</name>
</types>
<version>47.0</version>
```

---

### ScoreCategory
**Purpose:** Represents the category and subcategories that form a unified health profile in the Unified Health Scoring feature.
**File suffix:** `.scoreCategory`
**Directory:** `scoreCategories/`
**API version:** 55.0 and later

| Field | Type | Required | Description |
|---|---|---|---|
| `categoryName` | string | **Yes** | Name of the score category |
| `description` | string | **Yes** | Description of the score category |
| `developerName` | string | **Yes** | Unique API name (alphanumeric + underscores; must start with letter; no spaces) |
| `iconUrl` | string | **Yes** | URL for the category icon image |
| `masterLabel` | string | **Yes** | UI label of the score category record |
| `parentCategoryId` | string | No | Parent score category ID. Do NOT use for top-level categories representing unified health profiles |
| `scoreCategoryCalcInsights` | ScoreCategoryCalcInsight[] | No | Maps category to calculated insights in Salesforce Data Cloud |
| `scoreRangeClassifications` | ScoreRangeClassification[] | No | Defines score ranges and their classifications for this category |

**ScoreCategoryCalcInsight subtype** (use only with Salesforce Data Cloud for score calculation):

| Field | Type | Required | Description |
|---|---|---|---|
| `insightName` | string | **Yes** | API name of the calculated insight that derives scores |
| `insightDateFieldName` | string | **Yes** | API name of the date field in the insight specifying last calculation |
| `insightScoreFieldName` | string | **Yes** | API name of the score field (the measure dimension) |
| `insightSubjectFieldName` | string | **Yes** | API name of the field referencing the subject (Account, Lead, or Contact — the dimension) |

---

### TimelineObjectDefinition
**Purpose:** Container for timeline configuration details. Used to configure the Health Cloud Timeline component (chronological view of records from multiple objects).
**API version:** 55.0 and later
**Notes:** Both a Tooling API object and a metadata type.

---

### UIObjectRelationConfig
**Purpose:** Represents the admin-created configuration of the object relation UI component.
**Source:** Listed in PDF p.2225 — "Represents the admin-created configuration of the object relation UI component."
**Note:** Full field specification not found in extracted pages — verify separately in full PDF section.

---

### VirtualVisitConfig
**Purpose:** Represents an external video provider configuration, which relays events from Salesforce to the provider.
**Source:** Listed in PDF p.2225 — "Represents an external video provider configuration, which relays events from Salesforce to the provider."
**Note:** Full field specification not found in extracted pages — verify separately.

---

### Translations
**Purpose:** Standard Salesforce metadata type that enables work with translations for various supported languages. Health Cloud component labels can be translated via Translation Workbench.
**Note:** This is the standard Salesforce Translations metadata type; not Health Cloud-specific.

---

## Tooling API Objects

**Source:** PDF pp.2112-2163

Tooling API exposes metadata used in developer tooling, accessible through REST or SOAP. Tooling API SOQL capabilities allow retrieval of smaller metadata pieces for developer tooling integration.

### Key Tooling API Objects

| Object | Purpose | Notes |
|---|---|---|
| `CareSystemFieldMapping` (Tooling) | Query active CareSystemFieldMapping configurations | Use `IsActive = true` filter; `Metadata` field returns full configuration as complexvalue |
| `TimelineObjectDefinition` (Tooling) | Query Timeline configurations for the Health Cloud Timeline component | API v55.0+ |
| `ScoreCategory` (Tooling) | Query Unified Health Scoring categories | API v55.0+ |
| `ScoreCategoryCalcInsight` (Tooling) | Query mappings between score categories and Data Cloud calculated insights | API v55.0+; use when CDP/Data Cloud calculates scores |
| `ScoreRangeClassification` (Tooling) | Query score range classifications for Unified Health Scoring | API v55.0+ |

**CareSystemFieldMapping Tooling API key fields:**

| Field | Type | Description |
|---|---|---|
| `FullName` | string | Full name of the CareSystemFieldMapping type; query only if result contains no more than one record |
| `IsActive` | boolean | Whether the mapping is active (default: false) |
| `Language` | picklist | Language of the field mapping (en_US, de, fr, ja, etc.) |
| `ManageableState` | picklist | Managed state: beta, deleted, deprecated, installed, released, unmanaged, etc. |
| `MasterLabel` | string | User-interface label |
| `Metadata` | complexvalue | The full CareSystemFieldMapping metadata |

---

## Key Deployment Patterns

### Change Set vs Metadata API

| Component Type | Change Set | Metadata API (sf CLI) | Notes |
|---|---|---|---|
| CareBenefitVerifySettings | Limited availability in component picker | **Recommended** | Use `sf project deploy start` |
| CareLimitType | Limited | **Recommended** | — |
| CareRequestConfiguration | Limited | **Recommended** | API v44.0+ |
| CareSystemFieldMapping | Limited | **Recommended** | API v49.0+ |
| CareProviderSearchConfig | Limited | **Recommended** | API v48.0+ |
| Flow for Health Cloud | Yes (via standard Flow deployment) | **Recommended** | Use source-driven DX |
| Icon | Limited | **Recommended** | Requires ContentAsset for icon image |
| IdentityVerificationProcDef/Dtl/Fld | Limited | **Recommended** | API v54.0+ |
| IndustriesSettings | Yes (via Settings) | **Recommended** | Single file; use `members: Industries` |
| ScoreCategory | Limited | **Recommended** | API v55.0+ |
| TimelineObjectDefinition | Limited | **Recommended** | API v55.0+ |
| OmniStudio (OmniScripts, IPs, FlexCards, DataRaptors) | **Not supported** | **Not supported via standard Metadata API** | Must use OmniStudio DataPack CLI toolchain |

**Recommendation:** Use Salesforce DX (source-driven development with `sf project deploy start`) for all Health Cloud implementations. Change Sets do not reliably support Health Cloud-specific metadata types, and OmniStudio components require a completely separate pipeline.

---

### Required Deployment Order

Deploy Health Cloud components in this order to avoid dependency failures:

```
Step 1: Custom objects and fields (any non-HC custom objects)
        └── Custom fields on standard objects (Account, Lead, Contact, Opportunity)

Step 2: IndustriesSettings
        └── Enable features before deploying components that depend on them
        └── package.xml member: "Industries" → name: "Settings"

Step 3: CareSystemFieldMapping records (one per external system / role)
        └── Required before Enrollment API or Remote Monitoring can function

Step 4: CareRequestConfiguration records
        └── Required before UM / Prior Auth intake flows function

Step 5: CareBenefitVerifySettings records
        └── Required before Benefits Verification flows can execute

Step 6: CareProviderSearchConfig records
        └── Required before provider search UI components function

Step 7: IdentityVerificationProcDef → IdentityVerificationProcDtl → IdentityVerificationProcFld
        └── Deploy in this hierarchy order (parent before children)

Step 8: ScoreCategory records (if Unified Health Scoring)
        └── Include ScoreCategoryCalcInsight subtypes if using Data Cloud

Step 9: TimelineObjectDefinition records
        └── Configure timeline after base objects are deployed

Step 10: Icon records (with ContentAsset dependencies)
         └── Deploy ContentAsset first, then Icon

Step 11: VirtualVisitConfig records (if telehealth integration)
         └── External video provider configuration

Step 12: Flow for Health Cloud
         └── Flows using HC actionType values must be deployed after
             corresponding features are activated (Step 2)

Step 13 (separate pipeline): OmniStudio DataPacks
         └── Use vlocity/OmniStudio CLI toolchain
         └── OmniScripts, Integration Procedures, DataRaptors, FlexCards
         └── Deploy after all dependent Salesforce metadata is deployed
```

---

### FHIR Configuration Deployment

When FHIR API is in scope:
1. `IndustriesSettings` with `enableHlsFhirSubscriptionSetting = true` (for DTR/UM FHIR features)
2. `IndustriesSettings` with `enableClinicalDataModel = true` (for FHIR-aligned Clinical Data Model)
3. FHIR server settings configuration (via Setup UI in the org — not a deployable metadata type as of this guide)
4. `InteropTopic`, `InteropTopicSubscription`, and related subscription records (deployed as data, not metadata)

---

### package.xml Template for Full Health Cloud Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <!-- Core Settings -->
  <types>
    <members>Industries</members>
    <name>Settings</name>
  </types>

  <!-- Care Request Configuration (UM/Prior Auth) -->
  <types>
    <members>*</members>
    <name>CareRequestConfiguration</name>
  </types>

  <!-- System Field Mappings (EHR integration) -->
  <types>
    <members>*</members>
    <name>CareSystemFieldMapping</name>
  </types>

  <!-- Benefits Verification Settings -->
  <types>
    <members>*</members>
    <name>CareBenefitVerifySettings</name>
  </types>

  <!-- Provider Search Configuration -->
  <types>
    <members>*</members>
    <name>CareProviderSearchConfig</name>
  </types>

  <!-- Identity Verification -->
  <types>
    <members>*</members>
    <name>IdentityVerificationProcDef</name>
  </types>
  <types>
    <members>*</members>
    <name>IdentityVerificationProcDtl</name>
  </types>
  <types>
    <members>*</members>
    <name>IdentityVerificationProcFld</name>
  </types>

  <!-- Unified Health Scoring -->
  <types>
    <members>*</members>
    <name>ScoreCategory</name>
  </types>

  <!-- Timeline Configuration -->
  <types>
    <members>*</members>
    <name>TimelineObjectDefinition</name>
  </types>

  <!-- Icons -->
  <types>
    <members>*</members>
    <name>Icon</name>
  </types>

  <!-- Flows -->
  <types>
    <members>*</members>
    <name>Flow</name>
  </types>

  <!-- Apex -->
  <types>
    <members>*</members>
    <name>ApexClass</name>
  </types>
  <types>
    <members>*</members>
    <name>ApexTrigger</name>
  </types>

  <version>66.0</version>
</Package>
```

**Notes:**
- Wildcard `*` is supported for all Health Cloud metadata types listed above
- OmniStudio components are NOT included — use separate DataPack deployment
- Virtual Visit Config and UIObjectRelationConfig should be added if those features are in scope
