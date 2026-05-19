---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: data-model
last-updated: 2026-05-11
---

# Life Sciences Cloud — Data Model

## Standard Objects by Domain (PDF pp.47-68)

LSC provides 200+ standard objects. This file covers the key objects by domain with descriptions and API versions.

---

## Clinical Engagement Objects

| Object | Description | API Version |
|---|---|---|
| `AdverseEventAction` | Preventive or ameliorating actions related to an adverse event | v61.0+ |
| `AdverseEventCause` | Entity suspected to have caused the adverse event | v61.0+ |
| `AdverseEventContribFactor` | Contributing factors to adverse event probability/severity | v61.0+ |
| `AdverseEventEntry` | The adverse event record for research participants | v61.0+ |
| `AdverseEventOutcome` | Type of outcome from the adverse event | v61.0+ |
| `AdverseEventParty` | Who participated in the adverse event and how | v61.0+ |
| `AdverseEventSupportInfo` | Supporting information relevant to the event | v61.0+ |
| `AdverseEvntResultingEffect` | Effect on subject due to the adverse event | v61.0+ |
| `AdvTherapyFieldOptOverride` | Fields with changed optionality based on parameters | v59.0+ |
| `CareSiteIstgrSearchableFld` | Clinical trial investigator associated with a site | v63.0+ |
| `CustodyChainEntry` | Entry or event in chain of custody | v59.0+ |
| `CustodyItem` | Item in the custody chain | v59.0+ |
| `CustodyVerfcTypeOverride` | Verification of custody chain entry | v59.0+ |
| `EnrollmentEligibilityCriteria` | Criteria for patient enrollment eligibility | — |
| `ResearchStudy` | Clinical research study record | — |
| `ResearchStudyCandidate` | Study candidate record | — |
| `ResearchStudyCmprGroup` | Comparison groups within a research study | — |
| `ResearchStudyProtocolInfo` | Protocol information for a research study | — |
| `ResearchStudyRelation` | Relationship between research studies | — |
| `ResearchStudyRndmBlockSlot` | Slot within a randomization block | — |
| `RsrchStdyRandomizationBlock` | Randomization block for a research study | — |
| `RsrchStdyRandomizationCrit` | Randomization criteria for a research study | — |
| `Sprint` | A phase or sprint in a research study | — |
| `Subject` | Research study participant subject | — |
| `SubjectAssignment` | Assignment of a subject to a research study | — |

---

## Customer Engagement (LS C4CE) Objects

### Account Planning (Key Account Management — API v65.0+)

| Object | Description |
|---|---|
| `AccountPlanParticipant` | Team members participating in the account plan |
| `AccountPlanProduct` | Products associated with an account plan or its objectives |
| `AccountPlanRelaObjAnalysis` | Strategic analysis on objects related to the account plan (SWOT-style) |
| `AccountPlanRelationship` | Relationship between multiple account plans |
| `AccountPlanStakeholder` | Key individuals who influence the account's actions |
| `AccountPlanStkhldrAction` | Junction between account plan stakeholder and an action |
| `AccountPlanStkhldrProduct` | Junction between account plan stakeholder and a product |
| `AcctPlanPtcpStakeholder` | Junction between account plan participant and stakeholder |

### Actionable Lists (API v65.0+)

| Object | Description |
|---|---|
| `ActionableList` | An actionable list for targeted account engagement |
| `ActionableListFilterCriteria` | Filter conditions for actionable list data inclusion/exclusion |
| `LifeSciAccountListColumn` | Columns in an account list |
| `LifeSciAccountListMember` | Individual members of a Life Science account list |
| `LifeSciAcctGrpAssignment` | Assignment of account group to actionable list |
| `LifeSciAcctListFilterCrit` | Filter criteria for Life Science account lists |
| `LifeScienceAccountList` | List of accounts for targeting |
| `LifeScienceAccountListObject` | Object types associated with the account list |

### Activity Plans (API v65.0+)

| Object | Description |
|---|---|
| `ActionPlan` | Compliance program instance assigned to an account (extended by LSC) |
| `ActionPlanItem` | Junction between Action Plan and Provider Engagement Compliance Cycle |
| `ActionPlanStatusPeriod` | Historical status changes of an action plan |
| `ActionPlanTemplate` | Template for action plans (API v65.0+) |
| `ActionPlanTemplateAssignment` | Association of template with care plan template, goal, or problem definition |
| `ActionPlanTemplateItemValue` | Value associated with an action plan template item |
| `ActionPlanTemplateItem` | Item on an action plan template version (API v64.0+) |
| `ActionPlanTemplateVersion` | Version of an action plan template |
| `ActivityPlan` | User's activity goals for a cycle (API v65.0+) |
| `ActivityPlanTerritory` | Territory details associated with an activity plan (API v65.0+) |
| `ActivityTiming` | Detailed info about activity repeated in regular intervals (API v52.0+) |

### App Alerts (API v65.0+)

| Object | Description |
|---|---|
| `AppAlert` | Alert message at object, tab, or global level |
| `AppAlertTerritory` | Junction between an Alert and Territory |
| `AppAlertUserResponse` | User action for an alert |

### Consent Management (API v65.0+)

| Object | Description |
|---|---|
| `CommSubConsentCmplSnpsht` | Snapshot of compliance info at time of consent |
| `CommSubscription` | Customer's subscription preferences for a communication |
| `CommSubscriptionConsent` | Customer's consent to a communication subscription |
| `ComplianceStatementDef` | Compliance statements for provider engagements |
| `ContactPointConsent` | Consent to contact via a specific contact point |
| `DataUsePurpose` | Reason for contacting a prospect or customer |

### Data Change Requests

| Object | Description |
|---|---|
| `LifeSciDataChangeDef` | Definition for configurable data validation change requests |
| `LifeSciDataChangeRequest` | Instance of a data change request |
| `LifeSciDataChgDefMngFld` | Managed fields associated with a data change definition |
| `LifeSciDataChgDefRecType` | Record type mappings for a data change definition |
| `LifeSciDataChgPersonaDef` | Persona definitions for data change workflows |

### Digital Verification (API v60.0+)

| Object | Description |
|---|---|
| `DigitalSignature` | A signature on a record (LSC fields extend standard object) |
| `DigitalVerfSetupDetail` | Contextual details of a digital verification setup |
| `DigitalVerification` | Verification record for a related record |
| `DigitalVerificationSetup` | Setup details (number of signatures needed, related record action) |

### Email Management

| Object | Description |
|---|---|
| `LifeSciEmailTemplate` | Email template for field use |
| `LifeSciEmailTmplFragment` | Fragment component of an email template |
| `LifeSciEmailTmplRelaFrgmt` | Relationship between email template and fragment |
| `LifeSciEmailTmplSnapshot` | Snapshot of email template state |

### Mobile Sync (API v65.0+)

| Object | Description |
|---|---|
| `DeviceSyncSummary` | Summary of data synchronized from a mobile device |
| `DeviceSyncTransaction` | Set of related data items to sync from mobile device |
| `DeviceSyncTransactionLog` | Log of synchronized data from mobile device |
| `DeviceSyncTransactionRecord` | Single data item to sync from mobile device |

### Provider Search & Territory

| Object | Description | API Version |
|---|---|---|
| `CareProviderAdverseAction` | Adverse actions against a provider (malpractice, revoked license) | v47.0+ |
| `CareProviderFacilitySpecialty` | Specialties a practitioner provides at a given location | — |
| `CareProviderSearchableField` | Denormalized search data for provider search performance | v47.0+ |
| `CareProviderSearchConfig` | Fields that appear in provider search results | v48.0+ |
| `CareSpecialty` | Provider specialty codes and descriptions | — |
| `CareSpecialtyTaxonomy` | Junction between CareSpecialty and CareTaxonomy | v52.0+ |
| `CareSystemFieldMapping` | Mapping from source system fields to Salesforce fields | — |
| `CareTaxonomy` | Static list of taxonomy codes | — |
| `ProviderAcctProductInfo` | Product information for provider accounts | — |
| `ProviderAcctTerritoryInfo` | Territory info for provider accounts | — |
| `ProviderActivityGoal` | Activity goals for a provider | — |
| `ProviderActivityGoalMeasure` | Measures for provider activity goals | — |
| `ProviderActivityMeasureType` | Types of measures for provider activity | — |
| `ProviderActvtyPlanAdjusment` | Adjustments to provider activity plans | — |
| `ProviderAffiliation` | Provider affiliation records | — |
| `ProviderAffiliationProduct` | Products associated with provider affiliations | — |
| `ProviderSampleLimit` | Sample limits for providers | — |
| `ProviderSampleLimitTemplate` | Templates defining sample limit rules | — |
| `ProviderSearchSyncLog` | Log for provider search synchronization | — |

### Sampling and Inventory

| Object | Description | API Version |
|---|---|---|
| `Expense` | Expenses related to a visit (LSC fields extend standard) | v65.0+ |
| `ExpenseParticipant` | Participant in an expense allocation | v65.0+ |
| `ExpenseType` | Category for classifying an expense | v65.0+ |
| `InventoryCountAssessment` | Assessment of inventory count | — |
| `InventoryOperation` | An inventory operation (transfer, receipt, count) | — |
| `ProductRequired` | Products required for a work order | — |
| `ProductTerrDtlAvailability` | Detailed product availability by territory | — |
| `ProductTerritoryAvailability` | Product availability across territories | — |
| `ProductTransfer` | Transfer of product between locations | — |
| `SerializedProduct` | A serialized unit of a product | — |

---

## Patient Engagement Objects

### Care Program Management

| Object | Description | API Version |
|---|---|---|
| `CareProgram` | Set of activities offered to participants (therapy, financial assistance, wellness) | — |
| `CareProgramAssistance` | Junction between CareProgram and Program objects | v61.0+ |
| `CareProgramCampaign` | Relationship between CareProgram and Campaign | — |
| `CareProgramDetail` | Detail records related to the care program | v61.0+ |
| `CareProgramEligibilityRule` | Criteria for patient care program enrollment eligibility | — |
| `CareProgramEnrollee` | Participant enrolled in a care program | — |
| `CareProgramEnrolleeProduct` | Affiliation between enrollee and care program product/provider | — |
| `CareProgramEnrollmentCard` | Membership card with enrollment code | — |
| `CareProgramGoal` | Business or clinical goal related to a care program | — |
| `CareProgramProduct` | Affiliation between care program and product/provider | — |
| `CareProgramProvider` | Business account that is the service provider for a care program product | — |
| `CareProgramSite` | Care program site details | v61.0+ |
| `CareProgramSiteContract` | Association of a care program site and a contract | v62.0+ |
| `CareProgramStatusPeriod` | Historical status changes of a care program | v61.0+ |
| `CareProgramTeamMember` | Person delivering services under a program | — |
| `CarePgmEnrleeStatusPeriod` | Historical status/stage changes of a care program enrollee | v61.0+ |
| `CarePgmEnrolleeWkOrdStep` | Step in a work order for a care program enrollee | v58.0+ |
| `CarePgmEnrolleeWorkOrder` | Work order for a care program enrollee | v58.0+ |
| `CarePgmEnrollmentEvalRslt` | Result of eligibility evaluation for research study or care program | v62.0+ |
| `CarePgmProvHealthcareProvider` | Primary healthcare professional for a care program provider | v49.0+ |
| `CarePgmTeamMbrRolePeriod` | Historical role changes of a care program team member | v61.0+ |
| `ProgramEnrlEligibilityCrit` | Eligibility criteria for program enrollment | — |
| `ProgramEnrollment` | Enrollment record for a program | — |
| `ProgramRecommendationRule` | Rules for recommending programs | — |

### Clinical Data Model (FHIR R4-aligned — requires org pref enablement)

**Requires "FHIR R4 Support Settings" org preference to be enabled.**

| Object | Description | API Version |
|---|---|---|
| `AllergyIntolerance` | Clinical assessment of patient's allergy or intolerance | v51.0+ |
| `CarePerformer` | Person performing care (physician, patient's contact, caregiver) | v51.0+ |
| `ClinicalAlert` | Warning/notification for healthcare entities | v51.0+ |
| `ClinicalEncounter` | Healthcare encounter (pre-admission through discharge) | v51.0+ |
| `ClinicalEncounterDiagnosis` | Diagnosis related to a clinical encounter | v51.0+ |
| `ClinicalEncounterFacility` | Facilities involved in an encounter | v51.0+ |
| `ClinicalEncounterIdentifier` | Identifier information for a clinical encounter | v51.0+ |
| `ClinicalEncounterProvider` | Providers involved in an encounter | v51.0+ |
| `ClinicalEncounterReason` | Reasons why encounter was required | v51.0+ |
| `ClinicalEncounterSvcRequest` | Service requests related to a clinical encounter | v51.0+ |
| `ClinicalServiceRequest` | Request for procedure or diagnostic service | v51.0+ |
| `ClinicalServiceRequestDetail` | Multi-object junction for additional service request info | v51.0+ |
| `ClinicalDetectedIssue` | Detected issue from clinical activity | v55.0+ |
| `ClinicalDetectedIssueDetail` | Additional info about clinical detected issue | v55.0+ |
| `DiagnosticSummary` | Findings and interpretations of patient tests | v51.0+ |
| `DiagnosticSummaryDetail` | Additional info for DocumentReference-type DiagnosticSummary | v52.0+ |
| `HealthCondition` | Maps to FHIR Condition resource | — |
| `MedicationRequest` | Request for medication (FHIR MedicationRequest) | — |
| `MedicationStatement` | Medication statement record | — |
| `MedicationStatementDetail` | Additional details for a medication statement | — |
| `MedicinalIngredient` | Ingredient of a medication | — |
| `PatientHealthReaction` | Patient reaction to medication or event | — |
| `PatientImmunization` | Patient immunization record | — |
| `PatientImmunizationProtocol` | Protocol associated with patient immunization | — |
| `PatientMedicalProcedure` | Medical procedure performed on a patient | — |
| `PatientMedicalProcedureDetail` | Detail records for patient medical procedure | — |
| `PatientMedicationDosage` | Dosage information for patient medication | — |

**Objects that do NOT require org pref:**
CareObservation, CareObservationComponent, CareProviderFacilitySpecialty, CodeSet, CodeSetBundle, HealthcareFacility, HealthcarePractitionerFacility, HealthcareProvider, Identifier, Medication, PersonLanguage, PersonName

### FHIR R4 → Salesforce Object Mapping

| FHIR Resource | Salesforce Object(s) |
|---|---|
| `Address` | `ContactPointAddress` |
| `AdverseEvent` | `AdverseEventEntry` (and related objects) |
| `AllergyIntolerance` | `AllergyIntolerance`, `PatientHealthReaction` |
| `Annotation` | `AuthorNote` |
| `CarePlan` | `CarePlan`, `CarePlanDetail`, `CarePlanActivity`, `CarePlanActivityDetail` |
| `CodeableConcept` | `CodeSetBundle` (up to 15 CodeSet references: CodeSet1Id…CodeSet15Id) |
| `Coding` | `CodeSet` |
| `CommunicationRequest` | `TrackedCommunication`, `TrackedCommunicationDetail` |
| `Condition` | `HealthCondition` |
| `ContactPoint` | `ContactPointPhone` |
| `Device` | `Asset`, `CareRegisteredDevice` |
| `DiagnosticReport` | `DiagnosticSummary` |
| `DocumentReference` | `DiagnosticSummary`, `DiagnosticSummaryDetail` |
| `Dosage` | `PatientMedicationDosage` |
| `Encounter` | `ClinicalEncounter` + 6 child objects |
| `EpisodeOfCare` | `CareEpisode`, `CareEpisodeDetail` |
| `Flag` | `ClinicalAlert` |
| `Goal` | `GoalAssignment`, `GoalAssignmentDetail` |
| `HumanName` | `PersonName` |
| `Identifier` | `Identifier` |
| `Immunization` | `PatientImmunization`, `PatientHealthReaction` |
| `Location` | `HealthcareFacility`, `Location` |
| `Medication` | `Medication` |
| `MedicationRequest` | `MedicationRequest` |
| `MedicationStatement` | `MedicationStatement` |
| `Observation` | `CareObservation`, `CareObservationComponent` |
| `Organization` | `Account` |
| `Patient` | `Account`, `Contact` (Person Accounts) |
| `Practitioner` | `HealthcareProvider`, person accounts |
| `PractitionerRole` | `HealthcarePractitionerFacility`, `CareProviderFacilitySpecialty` |
| `Procedure` | `PatientMedicalProcedure`, `PatientMedicalProcedureDetail` |
| `RelatedPerson` | `Account`, `Contact` via `ContactContactRelation__c` |
| `ResearchStudy` | `ResearchStudy` |
| `ServiceRequest` | `ClinicalServiceRequest`, `ClinicalServiceRequestDetail` |
| `Timing` | `ActivityTiming` |

**FHIR Integration Notes:**
- A middleware solution (MuleSoft or Apex) is required to convert FHIR/HL7 messages to Salesforce objects
- `CodeableConcept` flattened to 15 CodeSet references (`CodeSet1Id` through `CodeSet15Id`) — FHIR's zero-to-many not supported natively
- Period fields → two date fields (start/end); Quantity → numeric + unit; Range → upper/lower + unit; Ratio → numerator + denominator + unit

### Financial Assistance Program

| Object | Description | API Version |
|---|---|---|
| `Applicant` | Care program enrollee represented as an applicant | v59.0+ |
| `AssessmentEnvelope` | Envelope containing assessments for a user | v58.0+ |
| `AssessmentEnvelopeItem` | Item in an assessment envelope | v58.0+ |
| `AssessmentTask` | Activities like patient registration or order authorization | — |
| `Award` | Professional awards of a person or organization | — |
| `Benefit` | Benefits associated with the financial assistance program | v51.0+ |
| `BenefitType` | Type of benefits available to the care program enrollee | v51.0+ |
| `BatchJob` | Instance of a batch job running or run | v65.0+ |
| `BatchJobPart` | One part of a batch job | v65.0+ |

### Health Insurance

| Object | Description |
|---|---|
| `CareBarrier` | Obstacles affecting a patient or member | v45.0+ |
| `CareBarrierDeterminant` | Relationship of barrier to a determinant | v45.0+ |
| `CareBarrierType` | Standard list of barriers maintained by org | v45.0+ |
| `CareBenefitVerifyRequest` | Request for verification of benefits | v53.0+ |
| `CareDeterminant` | Determinants of health for a patient | v45.0+ |
| `CareDeterminantType` | Standard list of determinants of health | v45.0+ |
| `CarePreauth` | Details of preauthorizations for care under a member's plan | — |
| `CarePreauthItem` | Items included in a preauthorization | — |
| `CareService` | Healthcare treatment, service, or procedure | v59.0+ |
| `CoverageBenefit` | Benefits provided to a covered member | — |
| `CoverageBenefitItem` | Specific service covered by insurance plan | v53.0+ |
| `CoverageBenefitItemLimit` | Details of expenditure/limit/coverage for a benefit | v53.0+ |
| `Formulary` | Details of formulary covered by payer's health insurance plan | v65.0+ |
| `FormularyItem` | Products within the formulary (drug tier, coverage, copay) | v65.0+ |
| `MemberPlan` | Insurance plan membership record | — |
| `MergeRequest` | Request to merge customer accounts | — |

### Advanced Therapy Management

| Object | Description | API Version |
|---|---|---|
| `CareRegisteredDevice` | Device registration information for a patient or enrollee | v49.0+ |
| `DocumentTemplate` | Information about dynamic document generation | v56.0+ |
| `LifeSciDocTemplateVersion` | Version of a document template | — |
| `ServiceAppointmentGroup` | Group of service appointments for multi-step scheduling | — |
| `ServiceTerritoryRelationship` | Relationships between affiliated service territories | — |
| `WorkTypeStep` | Steps within a work type for multi-step procedures | — |
| `WorkTypeStepLdTimeOvride` | Lead time override for a work type step | — |
| `WorkTypeSvcTerrSchdPrio` | Scheduling priority for work types across territories | — |

### Social Determinants (API v45.0+)

`CareBarrier`, `CareBarrierDeterminant`, `CareBarrierType`, `CareDeterminant`, `CareDeterminantType`, `CareInterventionType`

---

## StandardValueSet Names (Standard Picklist Fields)

Key LSC standard value sets and their associated field names:

| Standard Value Set Name | Field Name |
|---|---|
| `CareProgramStatus` | `CareProgram.Status` |
| `ICAPurposeType` | `InventoryCountAssessment.Purpose` |
| `ProdRequestLineltemStatus` | `ProductRequestLineItem.Status` |
| `VisitChannel` | `ProviderVisit.Channel`, `ProviderVisitProdDetailing.ProviderVisitChannel`, `Visit.Channel` |
| `VisitPriority` | `Visit.VisitPriority` |

---

## Fields Added to Standard Objects by FHIR R4 Org Pref

When "FHIR R4 Support Settings" is enabled, the following fields are added to standard objects:
- `ContactPointPhone.PreferenceRank`
- `ContactPointPhone.UsageType`
- `ContactPointEmail.PreferenceRank`
- `ContactPointEmail.UsageType`
- `ContactPointAddress.PreferenceRank`
- `ContactPointAddress.UsageType`
- `Account.IsActive`

---

## Associated Objects (Auto-generated Standard LSC Patterns)

For many LSC objects, Salesforce auto-generates associated objects following these patterns:
- `{ObjectName}ChangeEvent` — Change Data Capture event
- `{ObjectName}Feed` — Chatter feed for the object
- `{ObjectName}History` — Field history tracking
- `{ObjectName}OwnerSharingRule` — Sharing rule configuration
- `{ObjectName}Share` — Manual share record

---

## SOQL Patterns

```soql
-- Care program enrollees with their care programs and products
SELECT Id, Name, Status, CareProgram.Name, CareProgramEnrolleeProduct.Name
FROM CareProgramEnrollee
WHERE Status = 'Enrolled'

-- Provider search: get HCPs with their specialties and facility
SELECT Id, Name, Specialty__c, NPI__c,
    (SELECT CareSpecialty.Name, HealthcareFacility.Name FROM CareProviderFacilitySpecialties)
FROM HealthcareProvider
WHERE IsActive = true

-- Research study candidates for a specific study
SELECT Id, Name, Status, ResearchStudy.Name, CareProgramEnrollee.Name
FROM ResearchStudyCandidate
WHERE ResearchStudy.Name = 'STUDY_NAME'

-- Consent management: get active communication consents for an account
SELECT Id, ContactPointConsent.PartyId, CommSubscription.Name, Status
FROM CommSubscriptionConsent
WHERE ContactPointConsent.Party.Id = :accountId AND Status = 'OptIn'

-- Care benefit verification requests pending
SELECT Id, Name, Status, CareProgramEnrollee.Name, CreatedDate
FROM CareBenefitVerifyRequest
WHERE Status IN ('Submitted', 'In Progress')
ORDER BY CreatedDate ASC

-- Digital verifications for a care program enrollee
SELECT Id, Status, VerificationType, RelatedRecordId
FROM DigitalVerification
WHERE RelatedRecord.Id = :enrolleeId

-- Provider visits by territory and date range
SELECT Id, Name, Visit.Channel, Visit.VisitPriority, VisitDate,
    Account.Name, Account.NPI__c
FROM ProviderVisit
WHERE Visit.PlannedVisitStartTime >= :startDate
    AND Visit.PlannedVisitStartTime <= :endDate
    AND Visit.TerritoryId = :territoryId
```
