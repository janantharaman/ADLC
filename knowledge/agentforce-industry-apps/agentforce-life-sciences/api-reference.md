---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: api-reference
last-updated: 2026-05-11
---

# Life Sciences Cloud — API Reference

## Business APIs (REST) — PDF pp.1495-1741

Life Sciences Cloud Business APIs are REST endpoints following Connect REST API conventions.

**Base URL pattern:** `https://yourInstance.salesforce.com/services/data/v66.0/connect/life-sciences/`

---

## Account Management APIs

### Merge Customer Account (POST) — v65.0+
Merges a list of customer accounts. If any one merge fails, the ENTIRE operation is cancelled.

**Resource:** `/connect/life-sciences/commercial/customers/actions/merge`

**Request:**
```json
{
  "customersToMerge": [
    {
      "winningId": "001x0000002kl8VFFV",
      "winningExternalId": "001x0000004op0XHHX",
      "losingId": "001x0000009gh6TDDT",
      "losingExternalId": "001x0000001ij7UEEU"
    }
  ],
  "overrideBlankValues": true
}
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `customersToMerge` | `MergeCustomersInput[]` | Yes | Up to 100 merge requests per call |
| `overrideBlankValues` | Boolean | No | If true: override null fields in winning account with non-null values from losing account |

---

### Merge Customer Account with Status (POST) — v65.0+
Merges accounts but processes all valid requests; does NOT fail entire operation if one is invalid.

**Resource:** `/connect/life-sciences/commercial/customers/actions/merge-with-status`

Same request body as above. Use this for bulk merges where partial success is acceptable.

---

### Account Manual Alignment (POST) — v65.0+
Manually aligns an account to a territory, creating a `ProviderAccountTerritoryInfo` record.

**Resource:** `/connect/life-sciences/commercial/customer-manual-alignment`

```json
{
  "territoryId": "territoryId",
  "accountId": "accountId"
}
```

---

### Account User Territory Information (POST) — v64.0+
Gets user details including territories and additional user info for an account.

**Resource:** `/connect/life-sciences/commercial/account-user-territory-info`

```json
{
  "accountId": "00xxG00000n6bbxxAA",
  "fieldNames": ["City", "IsActive", "LanguageLocaleKey"]
}
```

| Parameter | Type | Required |
|---|---|---|
| `accountId` | String | Yes |
| `fieldNames` | `<list>String` | No — returns Id and Name by default |

---

### Advanced Provider Search (POST) — v65.0+
Facilitates three search types: HCP (Healthcare Provider), HCO (Healthcare Organization), and license-based searches.

**Resource:** `/connect/life-sciences/commercial/advanced-provider-search`

**URL Parameter:** `externalSearch=true` — performs search on external system (default: false = internal)

```json
{
  "account": [{"field": "Name", "value": "Robert"}],
  "healthcareProvider": [
    {"field": "Specialties", "value": "Cardiology"},
    {"field": "PhoneticName", "value": "Robrt"}
  ],
  "contactPointAddress": [
    {"field": "IsPrimary", "value": "false"},
    {"field": "CountryCode", "value": "US"}
  ],
  "businessLicense": [
    {"field": "ComplianceScope", "value": "Address"},
    {"field": "LicenseNumber", "value": "123456"}
  ]
}
```

**Note:** At least one field from either `account` or `healthcareProvider` must be populated.

---

### Sample Limits Validation (POST)
Validates samples requested during a visit against sample limits for account, product, and template.

**Resource:** `/connect/life-sciences/commercial/validate-sample-limits`

---

### Visits (POST)
Creates visits for sales representatives.

**Resource:** `/connect/life-sciences/commercial/visits`

---

## Patient / Clinical APIs

### Book Slot Chain (POST) — v60.0+
Creates service appointments for a care program enrollee in advanced therapy management.

**Resource:** `/connect/health/advanced-therapy-management/book-slot-chain`

```json
{
  "careProgramEnrolleeId": "08pxx0000004C92AAE",
  "workProcedureId": "08pxx0000004C92AAE",
  "slots": [
    {
      "schedStartTime": "2022-03-26T16:30:00.000+0000",
      "schedEndTime": "2022-03-26T16:30:00.000+0000",
      "workTypeId": "08pxx0000004C92AAE",
      "serviceTerritoryId": "08pxx0000004C92AAE",
      "serviceResourceId": "08pxx0000004C92AAE",
      "contactId": "08pxx0000004C92AAE",
      "appointmentType": "Scheduled",
      "subject": "Apheresis",
      "additionalInformation": "Needs Cab Assistance",
      "street": "1 Market Street",
      "city": "San Francisco",
      "state": "CA",
      "postalCode": "94105",
      "country": "USA",
      "status": "Scheduled"
    }
  ]
}
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `careProgramEnrolleeId` | String | Yes | Enrollee for whom appointments are created |
| `workProcedureId` | String | Yes | Work procedure for which appointments are created |
| `slots` | `Slots[]` | Yes | Appointment slots to book (published + unpublished) |

**Note:** Only published slots trigger Salesforce Scheduler to actually book them.

---

### Work Type Lead Time (POST) — v60.0+
Gets work types and associated lead times optimized across regions for a specific advanced therapy.

**Resource:** `/connect/health/advanced-therapy-management/work-type-lead-time`

**Note:** Advanced Therapy Management only — do NOT use for standard FSL work types.

---

### Contact Encounter (POST) — v49.0+
Loads contact encounter details into the system.

**Resource:** `/services/data/vXX.X/contact-tracing`

**Prerequisites:**
- Must be used only in person account-enabled orgs
- Access to Contact Encounter and Contact Encounter Participants fields required

**Constraints:**
- Max 5 encounters per payload
- Max 50 participants per encounter
- To create new encounter: set `referenceID = null`
- To update existing encounter: pass `referenceID` of the encounter

**Auth:** Bearer token (OAuth 2.0)

---

### Patients (GET, POST, PUT) — FHIR
Retrieve, create, or update patient records using FHIR resource format.

**Purpose:** Creates/updates a patient record without making multiple separate calls to individual Salesforce objects.

---

## Apex Reference — `embeddedai` Namespace

### ApexMap Class

**Namespace:** `embeddedai`

**Purpose:** Create, clone, and convert string-based key-value pairs to JSON string format for use in prompt template context.

**Constructors:**
```apex
embeddedai.ApexMap map = new embeddedai.ApexMap();
```

**Methods:**
- `put(String key, String value)` — add key-value pair
- `toJSON()` — convert to JSON string
- `clone()` — clone the map

---

### RecordApexRepresentation Class

**Namespace:** `embeddedai`

**Purpose:** Creates a serializable representation of a record and its associated data for AI service integration. Used as input to the `serializeHierarchicalContextData` invocable action.

**Key Properties:**
```apex
embeddedai.RecordApexRepresentation rep = new embeddedai.RecordApexRepresentation();
// Properties depend on the specific record type being represented
// Pass list of RecordApexRepresentation to serializeHierarchicalContextData action
```

---

## ConnectApi Namespace (Connect in Apex)

LSC uses the standard `ConnectApi` namespace (used across all Salesforce clouds) for access to Connect REST API functionality from Apex.

See standard Salesforce ConnectApi documentation for namespace usage. LSC-specific functionality is exposed via the Business API REST endpoints, not via ConnectApi extensions.

---

## SOQL Reference

### Key Query Patterns

```soql
-- Care program enrollees and their programs
SELECT Id, Name, Status, CareProgram.Name, CareProgram.Type,
    (SELECT Name, Status FROM CareProgramEnrolleeProducts)
FROM CareProgramEnrollee
WHERE CareProgram.IsActive = true

-- Provider search data (denormalized read)
SELECT Id, ProviderId, ProviderName, PrimarySpecialty,
    PrimaryFacilityName, PrimaryCity, PrimaryState, NPI
FROM CareProviderSearchableField
WHERE PrimaryState = 'CA'

-- Research study candidates by study
SELECT Id, Name, Status, ResearchStudy.Name,
    CareProgramEnrollee.Name, CareProgramEnrollee.Account.Name
FROM ResearchStudyCandidate
WHERE ResearchStudy.Name = 'STUDY_001'
    AND Status IN ('Screened', 'Pre-Enrolled')

-- Active care benefit verify requests
SELECT Id, Name, Status, EnrolleeId, Member.Name, CreatedDate
FROM CareBenefitVerifyRequest
WHERE Status = 'Submitted'
ORDER BY CreatedDate ASC

-- Provider affiliations for a healthcare provider
SELECT Id, HealthcareProvider.Name, HealthcareFacility.Name,
    HealthcareFacility.PrimaryAddress.City,
    (SELECT CareSpecialty.Name FROM CareProviderFacilitySpecialties)
FROM ProviderAffiliation
WHERE HealthcareProvider.Id = :providerId AND IsActive = true

-- Sample limits for a provider-product combination
SELECT Id, Product2.Name, Account.Name, MonthlyLimit, AnnualLimit,
    CurrentMonthCount, CurrentYearCount
FROM ProviderSampleLimit
WHERE Account.Id = :accountId AND Product2.Id = :productId

-- Territory alignment for a user
SELECT Id, Account.Name, Account.NPI__c, Territory2.Name,
    IsManualAlignment
FROM ProviderAcctTerritoryInfo
WHERE Territory2.Territory2Model.Name = :modelName
    AND Territory2.UsersInTerritory2.User.Id = :userId

-- Digital verifications for a care program enrollee
SELECT Id, Status, VerificationType, CreatedDate,
    RelatedRecord.Name
FROM DigitalVerification
WHERE RelatedRecord.Type = 'CareProgramEnrollee'
    AND RelatedRecord.Id = :enrolleeId

-- Consent status for an account across channels
SELECT Id, ContactPoint.ContactPointType, Status,
    CommSubscription.Name, DataUsePurpose.Name
FROM CommSubscriptionConsent
WHERE ContactPoint.PartyId = :accountId
    AND Status != 'Withdrawn'
ORDER BY ContactPoint.ContactPointType
```

---

## HL7 v2.3 Storage in Salesforce

LSC supports HL7 v2.3 message mapping in addition to FHIR R4. Key HL7 segment → Salesforce mappings:

| HL7 Segment | Salesforce Object | Notes |
|---|---|---|
| PID (Patient Identification) | `Account`, `Contact` (Person Account) | Name → PersonName; Address → ContactPointAddress |
| XTN (Phone Number) | `ContactPointPhone` | XTN.1 = Telephone Number; XTN.2 = Contact type |
| PV1 (Patient Visit) | `ClinicalEncounter` | Visit number, patient class, admission/discharge times |
| OBX (Observation/Result) | `CareObservation`, `CareObservationComponent` | Observation value and units |
| DG1 (Diagnosis) | `ClinicalEncounterDiagnosis` | Diagnosis code → CodeSet lookup |
| AL1 (Allergy) | `AllergyIntolerance` | Allergy type, severity |
| RXO (Pharmacy Prescription Order) | `MedicationRequest` | Drug code, quantity, dosage |
| IN1 (Insurance) | `MemberPlan`, `CoverageBenefit` | Insurance plan, group number |

A middleware integration solution (MuleSoft or Apex) is required to convert HL7 v2.3 messages to Salesforce format. The Salesforce implementation varies from HL7 recommendations in data types (e.g., code → string or picklist).

---

## API Version Reference

| Feature | First Available API Version |
|---|---|
| Core LSC objects (care program, provider) | v44.0-v51.0 (varies by object) |
| FHIR-aligned Clinical Data Model | v51.0 |
| Advanced Therapy Management (Book Slot Chain) | v60.0 |
| Adverse Events + Clinical Trial Management | v61.0 |
| Care Program Site, CareProgramSiteContract | v61.0-v62.0 |
| `ApplnFormAppealStsChgEvnt` platform event | v63.0 |
| Activity Plan, AccountPlan family | v65.0 |
| BatchJob, DeviceSync objects | v65.0 |
| `CareBnftVrfyRqstStsChgEvent` platform event | v65.0 |
| Merge Customer Account API | v65.0 |
| Advanced Provider Search API | v65.0 |
| Current version (Spring '26) | v66.0 |
