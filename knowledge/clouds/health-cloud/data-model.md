---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: data-model
last-updated: 2026-05-11
---

# Health Cloud — Data Model

## Domain Overview Table

| Domain | Key Objects | Purpose | Notes / API Version |
|---|---|---|---|
| Advanced Therapy Management | AdvTherapyFieldOptOverride, CarePgmEnrolleeWorkOrder, CarePgmEnrolleeWkOrdStep, ServiceAppointmentGroup, ServiceTerritoryRelationship, WorkProcedure, WorkProcedureStep, WorkTypeExtension, WorkTypeStep, CustodyChainEntry, CustodyItem, CustodyVerfcTypeOverride, Team, TeamMember | Multi-step scheduling for complex therapies (cell/gene therapy) | Built on Salesforce Scheduler; requires Multi-Step Scheduling permission set + Asset Scheduler Add-On license; API v56.0+ |
| Adverse Events | AdverseEvent | Document unfavorable events from medical intervention | FHIR-aligned |
| Assessment / Discovery Framework | AssessmentQuestion, AssessmentQuestionVersion, AssessmentIndicatorDefinition, AssessmentDefinition, AssessmentQuestionResponse | Healthcare questionnaires with OmniStudio | Requires OmniStudio |
| Benefits Verification | CareBenefitVerifyRequest, CoverageBenefit, CoverageBenefitItem | Determine coverage for services and products | FHIR-aligned; async via platform event |
| Care Program Management | CareProgram, CareProgramEnrollee, CareProgramProduct, CareProgramSite, CareProgramTeamMember | Enroll and manage patients in care programs | Core cross-domain object; CareProgramEnrollee is the hub |
| Clinical Data Model | CodeSet, CodeSetBundle, ClinicalEncounter, ClinicalDocument, AllergyIntolerance, CareObservation, CareObservationComponent, HealthCondition, MedicationRequest, MedicationStatement, PatientMedicalProcedure | FHIR R4 and USCDI-aligned clinical data storage | CodeSet/CodeSetBundle replaced HealthcareProcedure/HealthcareDiagnosis from Spring '21 |
| Coverage Requirement Discovery | ServiceInformationRequest, ServiceInfoRequestDetail, ServiceInfoResponseCoverage, ServiceInfoRespCoverageDetail, ServiceInfoResponseAction, ServiceInfoRespSuggestion, ServiceInfoRespOvrideOpt | FHIR-aligned CRD for real-time coverage requirements from EHR | Requires Hls Clinical Decision Support permission set |
| Crisis Support Center | CareFacilityBed | Bed management across facilities for crisis services | API v58.0+; requires Health Cloud Crisis Support Center Management App permission set + license |
| Disease Surveillance | DiseaseDefinition, DiseaseDefinitionCondition, DiseaseDefinitionCriteria, DiseaseInvestigation, DiseaseInvestigationCase, DiseaseOutbreak | Track disease data and public health activities | API v64.0+; enable in Public Health Settings |
| Electronic Signatures | Digital Verifications objects | Electronic consent and signature trails | Uses Digital Verifications framework |
| Engagement Interaction | EngagementInteraction, EngagementAttendee, EngagementTopic | Customer–agent interaction details | Supports 50 custom fields per object; quick actions supported |
| FHIR Subscription | InteropTopicSubscription, InteropTopicSubscriptionDtl, InteropTopicSubcrParameter, InteropTopicSubcrFilter, InteropTopic, InteropTopicDetail, InteropTopicTriggerCriteria | Publisher-subscriber FHIR Subscription framework | MuleSoft delivers notifications to subscriber endpoints |
| Financial Assistance | ApplnFormAppeal, ApplicationForm related objects | Patient financial assistance programs | Platform event: ApplnFormAppealStsChgEvnt (API v63.0+) |
| Home Health | CareServiceVisit, CareServiceVisitPlan, HomeVisitPatient | Home healthcare visit scheduling and management | Built on Salesforce Field Service; FSL license required |
| Integrated Care Management | ActionPlanTemplateAssignment, AsmtQstnRespRecommendation, CarePlan, CarePlanDetail, CarePlanActivity, CarePlanActivityDetail, GoalAssignment, GoalAssignmentDetail, CareEpisode, CareEpisodeDetail, ProblemDefinition | USCDI and FHIR R4-aligned care plan model | Requires enabling FHIR R4-Aligned Data Model + Enhanced Care Plans in Setup |
| Medication Management | MedicationReconciliation, MedicationTherapyReview, MedicationRecommendation | Medication reconciliation and therapy reviews | Clinician/care coordinator focused |
| Prior Authorization / UM | CareRequest, CareDiagnosis, CareRequestDrug, CareRequestItem, CareRequestExtension, CareRequestReviewer, CareRequestExchangeInfo, CareRequestSupportingCntnt, CareProcessingError, TrackedCommunication, TrackedCommunicationDetail | Prior authorization and utilization management | Uses Discovery Framework objects; FHIR-aligned via PASClaim/PASClaimResponse |
| Social Determinants | CareBarrier, CareBarrierDeterminant, CareBarrierType, CareDeterminant, CareDeterminantType, CareInterventionType | Barriers, determinants, and interventions for a patient | API v45.0+; requires Health Cloud managed package + Health Cloud Social Determinants permission set |
| Timeline | TimelineObjectDefinition | Chronological view of records across multiple objects | Tooling API object also available |
| Unified Health Scoring | ScoreCategory, ScoreCategoryCalcInsight, ScoreRangeClassification | Unified health profile with score categories and ranges | API v55.0+; requires Unified Health Scoring license; can integrate with Salesforce CDP |
| Utilization Management | See Prior Authorization row above — UM uses the same CareRequest objects | — | — |

---

## Object Relationships Diagram (Text)

```
Account (Patient / Member — Person Account model)
  ├── CareProgramEnrollee → CareProgram
  │     ├── CarePgmEnrolleeWorkOrder (Advanced Therapy)
  │     └── CarePgmEnrolleeWkOrdStep (Advanced Therapy)
  │
  ├── CarePlan (Integrated Care Management)
  │     ├── CarePlanDetail
  │     ├── CarePlanActivity → CarePlanActivityDetail
  │     └── GoalAssignment → GoalAssignmentDetail
  │
  ├── ClinicalEncounter (FHIR: Encounter)
  │     ├── ClinicalEncounterDiagnosis
  │     ├── ClinicalEncounterFacility
  │     └── ClinicalEncounterProvider
  │
  ├── CareObservation (FHIR: Observation)
  │     └── CareObservationComponent
  │
  ├── HealthCondition (FHIR: Condition)
  │
  ├── MedicationRequest (FHIR: MedicationRequest)
  │
  ├── AllergyIntolerance (FHIR: AllergyIntolerance)
  │
  ├── CareBenefitVerifyRequest (Benefits Verification)
  │     └── CoverageBenefit → CoverageBenefitItem
  │
  ├── CareRequest (Prior Auth / UM)
  │     ├── CareDiagnosis
  │     ├── CareRequestItem
  │     ├── CareRequestDrug
  │     ├── CareRequestReviewer
  │     └── TrackedCommunication
  │
  ├── CareBarrier (Social Determinants)
  │     ├── CareBarrierDeterminant
  │     └── CareDeterminant
  │
  └── CareServiceVisit (Home Health)
        └── CareServiceVisitPlan
```

---

## Core Patient / Member Objects

### CareProgramEnrollee
**API name:** `CareProgramEnrollee`
**Available:** API version context: present in Advanced Therapy Management section (p.10); fields include Advanced Therapy features from v58.0+

**Purpose:** Represents a participant enrolled in a care program. The central junction object between a patient (Account) and a CareProgram. This is the hub object for patient journey tracking.

**Key fields (from PDF pp.135-145):**
- `AccountId` — the patient/member (Person Account)
- `CareProgramId` — the care program this person is enrolled in
- `Status` — enrollment status (picklist); valid transitions must be followed
- `EnrollmentDate` / `ExitDate` — enrollment lifecycle dates
- `EnrolledAtId` — polymorphic lookup to CareProgramSite; available API v64.0+ when Site Management enabled
- `EnrolleeType` — picklist: FullBenefitDual, PartialBenefitDual, NonDual, Dual
- `EnrollmentLocationId` — service territory for advanced therapy program execution (API v59.0+, Advanced Therapy feature)
- `CurrentWorkOrderId` — current work order for Advanced Therapy (API v58.0+)
- `CurrentWorkOrderStepId` — current work order step for Advanced Therapy (API v58.0+)

**Notes:** CareProgramEnrollee Status transitions must follow a valid lifecycle; you cannot skip states. This is a critical business rule for implementations.

### CareProgram
**API name:** `CareProgram`
**Purpose:** The care program definition (diabetes management, oncology support, maternity, etc.)

**Key fields:**
- `Name` — program name
- `Category` — type of program
- `Status` — Active / Inactive
- `StartDate` / `EndDate` — program date range

### CarePlan (Integrated Care Management)
**API name:** `CarePlan`
**Source:** PDF p.1486 — "The CarePlan FHIR resource maps to the CarePlan, CarePlanDetail, CarePlanActivity, and CarePlanActivityDetail objects in Salesforce."

**Purpose:** FHIR R4-aligned care plan for a patient in the Integrated Care Management data model. This is the ICM-specific CarePlan, distinct from the legacy care plan model.

**Key related objects:**
- `CarePlanDetail` — details / sections within the care plan
- `CarePlanActivity` — individual actions / interventions in the plan
- `CarePlanActivityDetail` — additional detail on a care plan activity
- `GoalAssignment` — goals linked to the care plan (FHIR: Goal)
- `GoalAssignmentDetail` — goal detail records

**Activation requirement:** Enable FHIR R4-Aligned Data Model setting on the FHIR R4 Support Settings page AND Enhanced Care Plans setting on the Integrated Care Management Settings page.

### ActionPlanTemplateAssignment
**API name:** `ActionPlanTemplateAssignment`
**Source:** PDF p.713

**Purpose:** Associates an action plan template with a care plan template, goal, or problem definition. When instantiated, generates corresponding intervention tasks and links them to the appropriate record.

---

## Clinical Data Model

### CodeSet and CodeSetBundle
**Source:** PDF p.6 — "Before the Spring '21 release, the Healthcare Procedure and Healthcare Diagnosis objects stored codes specifically related to procedures and diagnoses. Since the Spring '21 release, Health Cloud uses the Code Set and Code Set Bundle objects for this purpose instead."

**CodeSet (API name: `CodeSet`)**
- FHIR mapping: Coding resource
- Stores a single clinical code (ICD-10, CPT, SNOMED, etc.)
- Key field: `Code` (string — FHIR coding.code is mapped to string in Salesforce)
- Key field: `SourceSystem` (string — maps from FHIR coding.system URI)

**CodeSetBundle (API name: `CodeSetBundle`)**
- FHIR mapping: CodeableConcept resource
- Groups up to 15 CodeSet references (CodeSet1Id through CodeSet15Id)
- CodeableConcept's zero-to-many coding flattened to 15 zero-to-one references in Salesforce

**Critical:** Any SOQL or Apex that references the deprecated `HealthcareProcedure` or `HealthcareDiagnosis` objects on orgs upgraded to Spring '21 or later will fail with INVALID_TYPE or no results. Always use CodeSet/CodeSetBundle.

**CareRequestItem and CareDiagnosis use:** `DiagnosisCodeSetId` is a polymorphic lookup to either CodeSet or CodeSetBundle. The old `DiagnosisCodeId` (lookup to HealthCareDiagnosis) is deprecated and will be removed in a future release.

### Key Clinical Objects and FHIR Mappings
(Source: PDF pp.1486-1488)

| FHIR Resource | Salesforce Object(s) | Notes |
|---|---|---|
| Address | ContactPointAddress | `use` mapped as picklist; `line` is single string (merge multiple lines) |
| AdverseEvent | AdverseEvent | Direct mapping |
| AllergyIntolerance | AllergyIntolerance, PatientHealthReaction | — |
| Annotation | AuthorNote | — |
| CarePlan | CarePlan, CarePlanDetail, CarePlanActivity, CarePlanActivityDetail | ICM CarePlan |
| CodeableConcept | CodeSetBundle | 15 CodeSet references |
| Coding | CodeSet | — |
| CommunicationRequest | TrackedCommunication, TrackedCommunicationDetail | — |
| Condition | HealthCondition | — |
| ContactPoint | ContactPointPhone | — |
| Device | Asset, CareRegisteredDevice | — |
| DiagnosticReport | DiagnosticSummary | — |
| DocumentReference | DiagnosticSummary, DiagnosticSummaryDetail | — |
| Dosage | PatientMedicationDosage | — |
| Encounter | ClinicalEncounter, ClinicalEncounterDiagnosis, ClinicalEncounterFacility, ClinicalEncounterIdentifier, ClinicalEncounterProvider, ClinicalEncounterReason, ClinicalEncounterSvcRequest | — |
| EpisodeOfCare | CareEpisode, CareEpisodeDetail | ICM |
| Flag | ClinicalAlert | — |
| Goal | GoalAssignment, GoalAssignmentDetail | ICM |
| HumanName | PersonName | FirstName/LastName/FullName pattern; ParentRecordId links to Person Account |
| Identifier | Identifier | — |
| Immunization | PatientImmunization, PatientHealthReaction | — |
| Location | HealthcareFacility, Location | — |
| Medication | Medication | — |
| MedicationRequest | MedicationRequest | — |
| MedicationStatement | MedicationStatement | — |
| Observation | CareObservation, CareObservationComponent | — |
| Organization | Account | — |
| PASClaim | CareDiagnosis, CareRequest, CareRequestDrug, CareRequestItem, CareRequestReviewer, Identifier | Prior Auth FHIR mapping |
| PASClaimResponse | CareProcessingError, AuthorNote, TrackedCommunication, TrackedCommunicationDetail | — |
| Patient | Account, Contact (Person Account) | — |
| Practitioner | HealthcareProvider, Person Account | — |
| PractitionerRole | HealthcarePractitionerFacility, CareProviderFacilitySpecialty | — |
| Procedure | PatientMedicalProcedure, PatientMedicalProcedureDetail | — |
| RelatedPerson | Account, Contact (ContactContactRelation__c) | — |
| ResearchStudy | ResearchStudy | Participant Management domain |
| ServiceRequest | ClinicalServiceRequest, ClinicalServiceRequestDetail | — |
| Subscription | InteropTopicSubscription, InteropTopicSubscriptionDtl, InteropTopicSubcrParameter, InteropTopicSubcrFilter | FHIR Subscription domain |
| SubscriptionTopic | InteropTopic, InteropTopicDetail, InteropTopicTriggerCriteria, InteropTopicFilter, InteropTopicNtfcnResource | — |
| Timing | ActivityTiming | — |

**Data type handling differences from FHIR spec:**
- **Period:** Flattened to `ActiveFromDate` / `ActiveToDate` or similar start/end fields
- **Quantity:** Flattened to numeric value + unit fields; unit references `UnitofMeasure` object
- **Range:** Flattened to `LowerLimit`, `UpperLimit`, and unit fields
- **Ratio:** Flattened to numerator + denominator + unit fields
- **URI:** Stored as string (e.g., `CodeSet.SourceSystem`, `Identifier.SourceSystem`)
- **Code (FHIR code type):** Stored as string in Salesforce if simple; stored as picklist if value set has conceptually simple values

---

## Benefits Verification Domain

**Source:** PDF pp.23-100 (Benefits Verification section)

### CareBenefitVerifyRequest
**Purpose:** Represents a request to verify insurance benefits for a service or product.
**Key fields:**
- `MemberId` — reference to the member (Account)
- `Status` — lifecycle status (Pending, In Progress, Completed, Failed)
- `ServiceType` — the service type being verified
- `CreatedDate` — when the request was initiated

**Asynchronous nature:** Benefits verification is asynchronous. The platform event `CareBnftVrfyRqstStsChgEvent` (API v65.0+) fires when the status changes. Do not build synchronous user-facing flows that wait for verification completion.

### CoverageBenefit
**Purpose:** Coverage benefit information returned from verification.
**Key fields (from PDF p.100):**
- `TotalBenefitAmount` — total coverage benefit amount (currency)
- `UrgentCareCopay` — member's urgent care copay contribution (currency)
- `VerificationDate` — date on which the benefit was verified
- Available in API v66.0+ with Home Health add-on for home health visit fields

### CoverageBenefitItem
**Purpose:** Specific service covered by the insurance plan.
**Available:** API version 53.0 and later
**Key fields (from PDF p.101):**
- `BenefitCategory` — the benefit category name
- `CodeSetServiceTypeId` — lookup to CodeSet for the service type code

---

## Utilization Management / Prior Authorization Domain

**Source:** PDF pp.1330-1340

### CareRequest
**Purpose:** General details of a care-related request including member information, admission date, decision reason. A single request can contain multiple diagnoses, services, or drugs. Covers preauthorizations for drugs and services, admission notifications, concurrent review of admissions, appeals, complaints, and grievances.

**Key related objects:**
- `CareDiagnosis` — diagnosis details for the request (ICD-10-CM codes via DiagnosisCodeSetId)
- `CareRequestDrug` — drug request details (name, strength, frequency, administration instructions)
- `CareRequestItem` — care service request details (name, modifiers, effective date)
- `CareRequestExtension` — extra details: subscriber details for health plan, home healthcare status, ambulance transportation
- `CareRequestReviewer` — reviewer details: name, type, status at review end, notes, date (API v52.0+)
- `CareRequestExchangeInfo` — information about care request exchange; maps from FHIR PASMetricData (API v63.0+)
- `CareRequestSupportingCntnt` — supporting content such as assessments or content documents (API v63.0+)
- `CareProcessingError` — processing errors sent from payer to provider on authorization request (API v58.0+)
- `TrackedCommunication` — communication/information request details (API v57.0+)
- `TrackedCommunicationDetail` — additional TrackedCommunication information (API v57.0+)

### CareDiagnosis Key Fields
- `CareRequestId` — parent care request
- `CodeType` — picklist: `ICD-10-CM`
- `DiagnosisCodeSetId` — polymorphic lookup to CodeSet or CodeSetBundle (preferred over deprecated `DiagnosisCodeId`)
- `IsPrimary` — whether this is the primary diagnosis
- `EffectiveDate` / `EndDate` — diagnosis validity range
- `DischargeCode` / `DischargeCodeDescription` / `DischargeCodeType` — discharge-specific diagnosis fields

---

## Social Determinants Domain

**Source:** PDF pp.1297-1298

**Activation:** Requires Health Cloud managed package installed. Users need Health Cloud Platform permission set license and Health Cloud Social Determinants permission set. Available API version 45.0 and later.

### Key Objects

| Object | Purpose |
|---|---|
| `CareBarrier` | Circumstances or obstacles affecting a patient or member |
| `CareBarrierDeterminant` | Relationship between a barrier and a determinant for a patient |
| `CareBarrierType` | Standard organization-maintained list of barriers |
| `CareDeterminant` | Determinants of health (safe housing, employment, food access) |
| `CareDeterminantType` | Standard organization-maintained list of determinants including domain and type |
| `CareInterventionType` | Types of interventions for addressing barriers |

---

## Integrated Care Management Domain

**Source:** PDF p.712

**Activation:** Enable FHIR R4-Aligned Data Model on FHIR R4 Support Settings page AND Enhanced Care Plans on Integrated Care Management Settings page.

**Key objects (from PDF p.713-714):**

| Object | Purpose |
|---|---|
| `ActionPlanTemplateAssignment` | Associates action plan template with care plan template, goal, or problem definition |
| `AsmtQstnRespRecommendation` | Maps assessment question response to care plan recommendation (problems, goals, interventions) |
| `CarePlan` | FHIR R4-aligned patient care plan |
| `CarePlanDetail` | Sections/details within a care plan |
| `CarePlanActivity` | Individual care plan action/intervention |
| `CarePlanActivityDetail` | Detail on a care plan activity |
| `GoalAssignment` | Goal linked to a care plan (FHIR: Goal) |
| `GoalAssignmentDetail` | Goal assignment detail |
| `CareEpisode` | Episode of care (FHIR: EpisodeOfCare) |
| `CareEpisodeDetail` | Episode detail |
| `ProblemDefinition` | Clinical problem definition used in care plan library |

---

## Crisis Support Center Domain

**Source:** PDF pp.455-458

**Activation:** Requires Health Cloud Crisis Support Center Management App permission set AND Health Cloud Crisis Support Center Management permission set license. Also requires Health Cloud Foundation permission set AND Health Cloud Platform permission set license.

**Available in:** Lightning Experience; Enterprise and Unlimited Editions with Health Cloud or Life Sciences Cloud.

### CareFacilityBed
**API name:** `CareFacilityBed`
**Available:** API version 58.0 and later

**Purpose:** Represents different bed types at a facility, associated with care programs and products.

**Key fields:**
- `AvailableBedCapacity` — integer; available bed count
- `TotalBedCapacity` — integer; total bed count
- `BedTypeCodeId` — lookup to CodeSetBundle for bed type
- `HealthcareFacilityId` — lookup to HealthcareFacility
- `ReferenceRecordId` — polymorphic lookup to CareProgram, CareProgramProduct, or Product

---

## Disease Surveillance Domain

**Source:** PDF pp.463-470

**Activation:** Enable Disease Surveillance on the Public Health Settings page in Setup.
**Available:** API version 64.0 and later.

### Key Objects

| Object | Purpose | Key Fields |
|---|---|---|
| `DiseaseDefinition` | A disease that public health organizations monitor to identify and prevent outbreaks | `Name`, `Status` (Active/Draft/Inactive), `Type` (Animal Borne, Blood Borne, etc.), `IsHighRisk` (boolean), `ActivationDate`, `ExpirationDate`, `IcdCodeId` (lookup to CodeSetBundle), `AuthorityReportingLevel` (Global/Local/National/State) |
| `DiseaseDefinitionCriteria` | Criteria (clinical, laboratory, epidemiologic linkage) for diagnosing the disease | — |
| `DiseaseDefinitionCondition` | Individual condition within disease definition criteria | `ConditionMatchRequirement` (Necessary/Sufficient/Supportive), `DiseaseDefinitionCriteriaId` |
| `DiseaseInvestigation` | An investigation of a specific disease instance | — |
| `DiseaseInvestigationCase` | Junction between DiseaseInvestigation and Case | — |
| `DiseaseOutbreak` | A disease outbreak monitored by the public health organization | — |

---

## Home Health Domain

**Source:** PDF pp.635-637

**Dependency:** Built over the Salesforce Field Service (FSL) data model. FSL license required.

### Key Objects (from PDF pp.635-636)

| Object | Purpose | Key Fields |
|---|---|---|
| `CareServiceVisit` | Individual home health visit record | `CarePlanContextId` (polymorphic: ActionPlan, CarePlan, CarePlanDetail, GoalAssignment, GoalAssignmentDetail), `CompletedVisitCount`, `CreatedVisitCount`, `IsServiceAuthorizationRequired` |
| `CareServiceVisitPlan` | Plan for a series of home visits | — |

**`CarePlanContextId`** is a polymorphic lookup added in API v59.0 that ties a home health visit to the relevant care plan or goal context.
**`ClinicalServiceRequestId`** on CareServiceVisit links to the service request for the visit.

---

## Assessment / Discovery Framework Domain

**Source:** PDF pp.70-100; FHIR mapping at pp.1487-1488

**Dependency:** OmniStudio must be enabled. Health Assessments will not function without OmniStudio.

### Key Objects

| Object | Purpose | FHIR Mapping |
|---|---|---|
| `AssessmentDefinition` | Defines an assessment (questionnaire) | DTRStdQuestionnaire |
| `AssessmentQuestion` | Individual question within an assessment | DTRStdQuestionnaire |
| `AssessmentQuestionVersion` | Version of an assessment question | DTRStdQuestionnaire |
| `AssessmentQuestionResponse` | Response to an assessment question | DTRStdQuestionnaire; also InformationOrigin maps here |
| `AssessmentIndicatorDefinition` | Defines how responses score/indicate a clinical finding | — |
| `Assessment` | An instance of a completed or in-progress assessment | DTRQuestionnaireResponse |
| `AssessmentReason` | Reason for the assessment | DTRQuestionnaireResponse |

**Utilization Management uses Discovery Framework:** UM assessments and clinical review questionnaires are built using Discovery Framework objects.

---

## Medication Management Domain

### Key Objects

| Object | Purpose |
|---|---|
| `MedicationReconciliation` | Reconciliation of a patient's full medication list |
| `MedicationTherapyReview` | Comprehensive or targeted medication therapy review |
| `MedicationRecommendation` | Clinical recommendations from a medication review |
| `MedicationRequest` | A request/prescription for a medication (FHIR: MedicationRequest) |
| `MedicationStatement` | Record of medication being taken (FHIR: MedicationStatement) |
| `PatientMedicationDosage` | Dosage details (FHIR: Dosage) |

---

## Engagement Interaction Domain

**Source:** PDF p.7

### Key Objects

| Object | Purpose | Custom Field Limit |
|---|---|---|
| `EngagementInteraction` | Records interaction between customer/rep and CSR/CCA including start/end time and topic | Up to 50 custom fields |
| `EngagementAttendee` | Attendees in the interaction | Up to 50 custom fields |
| `EngagementTopic` | Topic of the engagement interaction | Up to 50 custom fields |

Supports quick actions for routine CCA tasks and personalized list views with My engagement attendees / My engagement interactions / My engagement topics filters.

---

## Fields on Standard Objects (Health Cloud Extensions)

**Source:** PDF pp.1479-1482

Health Cloud adds custom fields to standard objects for referral management and appointment scheduling. Key examples:

**On Lead** (referral management):
- `AnticipatedDischargeDate__c`, `Diagnosis__c`, `DischargeDate__c`
- `EmergencyContact*` fields, `Gender__c`, `Homebound__c`
- `InsuranceGroupId__c`, `InsuranceMemberId__c`, `InsuranceType__c`
- `ReferralStatus__c`, `ReferredToOrganization__c`, `ReferredToPractitioner__c`
- `ReferringNPI__c`, `TypeOfService__c`, `Specialty__c`

**On Contact** (referral scoring):
- `ConvertedReferrals__c`, `ReferrerScore__c`, `TotalReferrals__c`

**On Opportunity** (referral management):
- `Diagnosis__c`, `InsuranceType__c`, `ReferralReceivedDate__c`, `Specialty__c`, `TypeOfService__c`

**On Service Appointment** (health appointment scheduling):
- `StatusReason` — picklist with healthcare-specific values (None, Proposed, NoShow, Rejected, etc.)

**On ProductRequest** (care program device requests):
- `CareProgramEnrolleeId` — lookup to CareProgramEnrollee (API v49.0+)
- `LastModifiedById` — standard tracking field
