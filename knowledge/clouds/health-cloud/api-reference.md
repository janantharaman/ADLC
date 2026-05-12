---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: api-reference
last-updated: 2026-05-11
---

# Health Cloud — API Reference

## SOQL Patterns

### Active Care Program Enrollees

```soql
SELECT Id,
       AccountId,
       Account.Name,
       CareProgramId,
       CareProgram.Name,
       Status,
       EnrollmentDate,
       ExitDate,
       EnrolleeType
FROM CareProgramEnrollee
WHERE Status = 'Active'
ORDER BY EnrollmentDate DESC
```

**Notes:** Status is a restricted picklist — do not hardcode values without checking valid values in Setup. EnrolleeType (FullBenefitDual, PartialBenefitDual, NonDual, Dual) applies to payer/Medicare dual-eligible scenarios.

---

### Open Care Plan Activities by Coordinator

```soql
SELECT Id,
       Subject,
       Status,
       ActivityDate,
       CarePlanId,
       CarePlan.Name,
       CarePlan.AccountId,
       CarePlan.Account.Name,
       OwnerId,
       Owner.Name
FROM CarePlanActivity
WHERE Status NOT IN ('Completed', 'Cancelled')
  AND OwnerId = :coordinatorId
ORDER BY ActivityDate ASC
```

**Notes:** CarePlanActivity is the Integrated Care Management activity object. Requires ICM / Enhanced Care Plans enabled. Use `NULLS LAST` if ActivityDate may be null for activities without a due date.

---

### Benefits Verification Requests Pending

```soql
SELECT Id,
       Name,
       Status,
       MemberId,
       Member.Name,
       ServiceType,
       CreatedDate
FROM CareBenefitVerifyRequest
WHERE Status IN ('Pending', 'In Progress')
ORDER BY CreatedDate ASC
```

**Notes:** Benefits verification is asynchronous. The platform event `CareBnftVrfyRqstStsChgEvent` fires on status change. Do not poll this query in a loop — subscribe to the platform event instead.

---

### Social Determinants for a Patient

```soql
SELECT Id,
       Name,
       Category,
       Status,
       AccountId,
       BarrierId,
       Barrier.Name,
       DeterminantId,
       Determinant.Name
FROM CareBarrierDeterminant
WHERE AccountId = :patientId
ORDER BY CreatedDate DESC
```

**Alternative — query CareBarrier directly:**

```soql
SELECT Id,
       Name,
       Status,
       AccountId,
       CareBarrierTypeId,
       CareBarrierType.Name,
       StartDate,
       EndDate
FROM CareBarrier
WHERE AccountId = :patientId
  AND Status = 'Active'
```

**Notes:** Social Determinants require API v45.0 and the Health Cloud Social Determinants permission set. The CareBarrierDeterminant object links barriers to health determinants.

---

### Care Observations (Clinical Readings) for a Patient

```soql
SELECT Id,
       Name,
       ClinicalStatus,
       Code,
       CodeSystem,
       ObservationDate,
       PatientId
FROM CareObservation
WHERE PatientId = :patientId
ORDER BY ObservationDate DESC
LIMIT 50
```

**Notes:** CareObservation maps to the FHIR Observation resource. ClinicalStatus, Code, CodeSystem are standard FHIR-aligned fields. Use CareObservationComponent to query component values (e.g., systolic/diastolic for blood pressure):

```soql
SELECT Id,
       CareObservationId,
       Code,
       CodeSystem,
       ValueQuantity,
       ValueUnit,
       ComponentSequence
FROM CareObservationComponent
WHERE CareObservationId = :observationId
ORDER BY ComponentSequence ASC
```

---

### Utilization Management / Prior Authorization Requests

```soql
SELECT Id,
       Name,
       Status,
       AccountId,
       Account.Name,
       RequestType,
       CreatedDate,
       (SELECT Id, CodeType, DiagnosisCodeSetId, IsPrimary
        FROM CareDiagnoses
        WHERE IsPrimary = true
        LIMIT 1)
FROM CareRequest
WHERE Status NOT IN ('Approved', 'Denied', 'Cancelled')
  AND AccountId = :memberId
ORDER BY CreatedDate DESC
```

**Notes:** `CareDiagnoses` is the child relationship name for `CareDiagnosis` records on `CareRequest`. Use `DiagnosisCodeSetId` — the legacy `DiagnosisCodeId` field is deprecated.

---

### Active Health Conditions for a Patient

```soql
SELECT Id,
       Name,
       ClinicalStatus,
       Code,
       CodeSystem,
       OnsetDateTime,
       AbatementDateTime,
       AccountId
FROM HealthCondition
WHERE AccountId = :patientId
  AND ClinicalStatus = 'Active'
ORDER BY OnsetDateTime DESC
```

**Notes:** HealthCondition maps to the FHIR Condition resource. Part of the Clinical Data Model.

---

### Medication Requests for a Patient

```soql
SELECT Id,
       Name,
       Status,
       MedicationId,
       Medication.Name,
       RequestDate,
       AccountId,
       AuthorizingPractitionerId
FROM MedicationRequest
WHERE AccountId = :patientId
  AND Status = 'Active'
ORDER BY RequestDate DESC
```

---

### Disease Investigations

```soql
SELECT Id,
       Name,
       Status,
       DiseaseDefinitionId,
       DiseaseDefinition.Name,
       DiseaseDefinition.IsHighRisk,
       CreatedDate
FROM DiseaseInvestigation
WHERE Status = 'Active'
ORDER BY CreatedDate DESC
```

**Notes:** Available API v64.0+. Disease Surveillance must be enabled on Public Health Settings page.

---

### Available Beds at a Crisis Facility

```soql
SELECT Id,
       Name,
       AvailableBedCapacity,
       TotalBedCapacity,
       BedTypeCodeId,
       HealthcareFacilityId,
       HealthcareFacility.Name
FROM CareFacilityBed
WHERE AvailableBedCapacity > 0
  AND HealthcareFacilityId = :facilityId
ORDER BY AvailableBedCapacity DESC
```

**Notes:** Available API v58.0+. Crisis Support Center Management feature and permission set required.

---

### CodeSet Records for a Code System

```soql
SELECT Id,
       Code,
       Description,
       SourceSystem,
       Status
FROM CodeSet
WHERE SourceSystem = 'ICD-10-CM'
  AND Status = 'Active'
  AND Code LIKE 'J18%'
ORDER BY Code ASC
```

**Notes:** CodeSet is the FHIR Coding equivalent. SourceSystem stores the coding system URI as a string. Replaced HealthcareProcedure/HealthcareDiagnosis from Spring '21.

---

## Business APIs Reference

**Source:** PDF pp.1771+ — Health Cloud Business APIs section

The Business APIs are the recommended integration layer for complex Health Cloud operations. They wrap multi-object business logic into single API calls.

| API Area | Pattern | Purpose | Key Request Fields | Key Response Fields |
|---|---|---|---|---|
| Patient Enrollment | POST `/services/apexrest/...` or Business API endpoint | Enroll a patient in a care program; creates CareProgramEnrollee + care team records | patientId, careProgramId, enrollmentDate, careCoordinatorId | enrolleeId, status, errors |
| Benefits Verification | POST Business API | Initiate a benefits verification request against a payer system | memberId, serviceType, serviceDate, providerId | requestId, status (async) |
| Prior Authorization | POST Business API | Create a prior authorization request with diagnoses and service items | memberId, requestType, diagnoses[], serviceItems[], urgency | requestId, status, acknowledgementDate |
| Care Plan | POST/PATCH Business API | Create or update a care plan for a patient | patientId, carePlanDetails, goals[], activities[] | carePlanId, status |
| Referral | POST `/services/data/vXX.X/actions/standard/createReferral` | Create a patient referral | subjectRecord, requesterId, performers[], referralRecord | referralIds[] |
| Home Visit Scheduling | POST `/services/data/v63/actions/standard/scheduleRecurringHomeVisit` | Schedule recurring home visits | schedulingPolicyId, frequencyType, clinicalServiceRequestId, accountId | careServiceVisitPlanId, serviceAppointmentId |
| Appointment Booking | POST `/services/data/v65.0/connect/health/appointment-management/appointment` | Book a healthcare appointment | workTypeId OR appointmentTypes; participants[]; startDate | id, isSuccess, status |
| Slot Search | POST `/services/data/v65.0/connect/health/appointment-management/slots` | Find available appointment slots | startDate, endDate, workTypeId OR appointmentTypes, resources[] | resourceSlotDetails[] |
| Appointment Update | PUT `/services/data/66.0/connect/health/appointment-management/appointment/{id}` | Update existing appointment | id (URL), workTypeId, participants[], startDate | id, isSuccess, status |
| Appointment Cancel | PATCH `/services/data/66.0/connect/health/appointment-management/appointment/{id}` | Cancel an appointment | id (URL, required), status (required), cancellationReason | id, isSuccess, status |

**Note:** Specific Business API endpoint paths for patient enrollment, benefits verification, and prior authorization are documented in the full Health Cloud Business APIs section (PDF pp.1771-2111). The exact URIs are not all extracted here — refer to the PDF for specific endpoints. The Appointment Management and Referral endpoints are fully documented above from the Invocable Actions section.

---

## Invocable Actions Reference

**Source:** PDF pp.2168-2220 (Health Cloud Standard Invocable Actions)

These actions are available as standard invocable actions callable from Flow using the Invocable Action element, or via REST.

| Action Name | API Version | HTTP Method | URI | Key Inputs | Key Outputs |
|---|---|---|---|---|---|
| Book Appointment | v65.0+ | POST | `/services/data/v65.0/connect/health/appointment-management/appointment` | `participants[]` (Patient+Facility required; Provider or Device required); `startDate` (required); `workTypeId` OR `appointmentTypes`/`serviceTypes`/`serviceCategories`; `channelId`; `slots` (for external resources); `sourceSystem` (if external); `specialties`; `timeZone` | `id`, `isSuccess`, `status`, `errorMessages` |
| Cancel Appointment | v65.0+ | PATCH | `/services/data/66.0/connect/health/appointment-management/appointment/{id}` | `id` (URL, required); `status` (required, e.g. "Cancelled"); `cancellationReason`; `comment` | `id`, `isSuccess`, `status`, `errorMessages` |
| Update Appointment | v65.0+ | PUT | `/services/data/66.0/connect/health/appointment-management/appointment/{id}` | `id` (URL, required); `participants[]`; `workTypeId` OR `appointmentTypes`/`serviceTypes`/`serviceCategories`; `startDate`; `endDate`; `slots`; `sourceSystem`; `timeZone` | `id`, `isSuccess`, `status`, `errorMessages` |
| Get Slots | v65.0+ | POST | `/services/data/v65.0/connect/health/appointment-management/slots` (implied) | `startDate` (required); `endDate`; `workTypeId` OR `appointmentTypes`/`serviceTypes`/`serviceCategories`; `channelId`; `resources[]`; `sourceSystem` | `resourceSlotDetails[]` |
| Create Referral | v59.0+ | POST | `/services/data/vXX.X/actions/standard/createReferral` | `subjectRecord` (required — patient Account details); `requesterId` (required); `performers[]` (required); `referralRecord` (ClinicalServiceRequest); `referralDetailsRecords`; `matchDuplicates`; `referralNotes` | `referralIds[]` |
| Create Quote for Home Visits | v63.0+ | POST | `/services/data/v63/actions/standard/createQuoteForHomeVisits` | `quoteName` (required); `priceBookId` (required); `accountId`; `opportunityId`; `startDateTime`; `endDateTime`; `workTypeIds[]`; `visitCount`; `isTravelInventoryIncluded`; `pricingPreference` (System/Force/Skip); `currencyCode`; `productPricingAttributeDetails[]` | `quoteId`; `errorMessage`; `errorCode` |
| Schedule Recurring Home Visit | v63.0+ context | POST | `/services/data/v63/actions/standard/scheduleRecurringHomeVisit` | `schedulingPolicyId`; `firstVisitStartDateTime`; `firstVisitStartEndTime`; `visitsRequired`; `frequencyType` (DAILY etc.); `selectedDays`; `clinicalServiceRequestId`; `skillsIdList[]`; `operatingHoursId`; `accountId`; `serviceTerritoryId`; `careResourceCount`; `workTypeIdsList[]`; `visitSourceId[]` | `careServiceVisitPlanId`; `serviceAppointmentId` |
| Schedule Home Visit | — | POST | standard action URI | Start-of-care home visit inputs | Service appointment details |
| Schedule Home Visits Manually | — | POST | standard action URI | Manual resource selection; scheduling details | Visit records |
| Schedule Group Visits | — | POST | standard action URI | Bundle details; visit type; group scheduling parameters | Care service visit records |
| Reschedule Recurring Home Visits | — | POST | standard action URI | Recurrence pattern; scheduling policy; affected visit IDs | Updated visit records |
| Handle Resource Absence | — | POST | standard action URI | Resource ID; absence start/end; target visit status | Updated assignments |
| Create Template of Service Appointment | v63.0+ | POST | standard action URI | Template appointment details | Template service appointment ID |
| Get Resources | — | POST | standard action URI | Search criteria (specialty, skills, location) | Available resource list |
| Get Resources for Manual Scheduling | — | POST | standard action URI | Visit details; scheduling constraints | Recommended resources |
| Get Transcript from Conversation | — | POST | standard action URI | Conversation record ID | Transcript content |
| Process Received Document | — | POST | standard action URI | Received document reference | Created record with extracted data |
| Get Data Using Context Definition | — | POST | standard action URI | Context definition ID; context mapping | Data from context service |

---

## Platform Events

**Source:** PDF pp.1483-1485

### ApplnFormAppealStsChgEvnt
**API name:** `ApplnFormAppealStsChgEvnt`
**Available:** API version 63.0 and later
**Supported calls:** `create()`, `describeSObjects()`
**Access:** Requires Health Cloud Starter and Manage Financial Assistance Program permission set

| Field | Type | Properties | Description |
|---|---|---|---|
| `AppealIdentifier` | string | Create, Nillable | The identifier of an appeal that has a status change |
| `AppealStatus` | picklist | Create, Nillable, Restricted picklist | Status: **Accepted** or **Rejected** |
| `ApplicationFormIdentifier` | string | Create, Nillable | The identifier of the application associated with an appeal |
| `EventCreationDateTime` | dateTime | Create, Nillable | The date and time when the event was created |

**When fired:** When the status of a Financial Assistance Program appeal changes.

**Subscribe pattern (Flow / Apex Trigger):**
```apex
// Apex trigger on ApplnFormAppealStsChgEvnt
trigger FinancialAssistanceAppealStatusHandler on ApplnFormAppealStsChgEvnt (after insert) {
    for (ApplnFormAppealStsChgEvnt event : Trigger.new) {
        // Process appeal status change
        // event.AppealIdentifier, event.AppealStatus, event.ApplicationFormIdentifier
    }
}
```

---

### CareBnftVrfyRqstStsChgEvent
**API name:** `CareBnftVrfyRqstStsChgEvent`
**Available:** API version 65.0 and later
**Supported calls:** `create()`, `describeSObjects()`
**Access:** Requires Manage Pharmacy Benefits Verification AND (Health Cloud Starter for Life Sciences Cloud OR Health Cloud Foundation for Health Cloud)

| Field | Type | Properties | Description |
|---|---|---|---|
| `EventCreationDateTime` | dateTime | Create, Nillable | The date and time when the event was created |
| `RecordIdentifier` | string | Create | The identifier of the associated care benefit verify request record |
| `Status` | string | Create | The status of the care benefit verify request |

**When fired:** When the status of a care benefit verify request changes.

**Key design pattern — subscribe and update:**
```apex
// Apex trigger on CareBnftVrfyRqstStsChgEvent
trigger BenefitsVerificationStatusHandler on CareBnftVrfyRqstStsChgEvent (after insert) {
    Set<String> recordIdentifiers = new Set<String>();
    Map<String, String> identifierToStatus = new Map<String, String>();

    for (CareBnftVrfyRqstStsChgEvent event : Trigger.new) {
        recordIdentifiers.add(event.RecordIdentifier);
        identifierToStatus.put(event.RecordIdentifier, event.Status);
    }

    // Query and update CareBenefitVerifyRequest records
    List<CareBenefitVerifyRequest> requests = [
        SELECT Id, Name, Status
        FROM CareBenefitVerifyRequest
        WHERE Id IN :recordIdentifiers
    ];

    for (CareBenefitVerifyRequest req : requests) {
        req.Status = identifierToStatus.get(req.Id);
    }
    update requests;
}
```

---

## FHIR Resource to Salesforce Object Mapping (Quick Reference)

**Source:** PDF pp.1486-1488

| FHIR Resource | Salesforce Object(s) | Key Field Notes |
|---|---|---|
| Address | ContactPointAddress | `.line` = single string (merge multiple); period flattened to ActiveFromDate/ActiveToDate |
| AdverseEvent | AdverseEvent | — |
| AllergyIntolerance | AllergyIntolerance, PatientHealthReaction | `onset.onsetPeriod` → OnsetStartDateTime / OnsetEndDateTime |
| Annotation | AuthorNote | — |
| CarePlan | CarePlan, CarePlanDetail, CarePlanActivity, CarePlanActivityDetail | ICM CarePlan objects |
| CodeableConcept | CodeSetBundle | 15 CodeSet references (CodeSet1Id through CodeSet15Id) |
| Coding | CodeSet | `coding.system` URI → `CodeSet.SourceSystem` (string) |
| CommunicationRequest | TrackedCommunication, TrackedCommunicationDetail | UM domain |
| Condition | HealthCondition | — |
| Device | Asset, CareRegisteredDevice | — |
| DiagnosticReport | DiagnosticSummary | — |
| DocumentReference | DiagnosticSummary, DiagnosticSummaryDetail | — |
| Dosage | PatientMedicationDosage | `dispenseRequest.initialFill.quantity` flattened to quantity+unit fields |
| Encounter | ClinicalEncounter + 6 related objects | ClinicalEncounterDiagnosis, ClinicalEncounterFacility, ClinicalEncounterIdentifier, ClinicalEncounterProvider, ClinicalEncounterReason, ClinicalEncounterSvcRequest |
| EpisodeOfCare | CareEpisode, CareEpisodeDetail | ICM |
| Flag | ClinicalAlert | — |
| Goal | GoalAssignment, GoalAssignmentDetail | ICM |
| HumanName | PersonName | FirstName/LastName/FullName; ParentRecordId → Person Account |
| Identifier | Identifier | `identifier.system` URI → `Identifier.SourceSystem` (string) |
| Immunization | PatientImmunization, PatientHealthReaction | — |
| Location | HealthcareFacility, Location | — |
| Medication | Medication | — |
| MedicationRequest | MedicationRequest | — |
| MedicationStatement | MedicationStatement | — |
| Observation | CareObservation, CareObservationComponent | — |
| Organization | Account | — |
| PASClaim | CareDiagnosis, CareRequest, CareRequestDrug, CareRequestItem, CareRequestReviewer, Identifier | Prior Auth FHIR alignment |
| PASClaimResponse | CareProcessingError, AuthorNote, TrackedCommunication, TrackedCommunicationDetail | — |
| PASMetricData | CareRequestExchangeInfo | — |
| Patient | Account, Contact (Person Account) | `Account.PersonContactId` for portal user matching |
| Practitioner | HealthcareProvider, Person Account | — |
| PractitionerRole | HealthcarePractitionerFacility, CareProviderFacilitySpecialty | — |
| Procedure | PatientMedicalProcedure, PatientMedicalProcedureDetail | Range fields flattened to LowerLimit/UpperLimit/Unit |
| RelatedPerson | Account, Contact (ContactContactRelation__c) | — |
| ResearchStudy | ResearchStudy | Participant Management domain |
| ServiceRequest | ClinicalServiceRequest, ClinicalServiceRequestDetail | `quantity.quantityRatio` flattened to QuantityNumerator/QuantityDenominator/QuantityNumeratorUnitId |
| Subscription | InteropTopicSubscription, InteropTopicSubscriptionDtl, InteropTopicSubcrParameter, InteropTopicSubcrFilter | FHIR Subscription domain |
| SubscriptionTopic | InteropTopic, InteropTopicDetail, InteropTopicTriggerCriteria, InteropTopicFilter, InteropTopicNtfcnResource | — |
| Timing | ActivityTiming | — |

---

## API Version Reference

| Feature / Object | Minimum API Version |
|---|---|
| Social Determinants (CareBarrier, CareDeterminant, etc.) | 45.0 |
| CareProgramEnrollee (base) | Prior to v49.0 |
| CareProgramEnrollee.CareProgramEnrolleeId on ProductRequest | 49.0 |
| CoverageBenefitItem | 53.0 |
| ScoreCategory, ScoreCategoryCalcInsight, ScoreRangeClassification (Unified Health Scoring) | 55.0 |
| TimelineObjectDefinition | 55.0 |
| ServiceAppointmentGroup, ServiceTerritoryRelationship (Advanced Therapy) | 56.0 |
| CareObservationShare (OWD sharing for CareObservation) | 56.0 |
| TrackedCommunication, TrackedCommunicationDetail | 57.0 |
| CareProcessingError | 58.0 |
| CareFacilityBed, CarePgmEnrolleeWorkOrder, CarePgmEnrolleeWkOrdStep, Team, TeamMember | 58.0 |
| Create Referral invocable action | 59.0 |
| CustodyChainEntry, CustodyItem, CustodyVerfcTypeOverride, WorkTypeStepLdTimeOvride, WorkTypeSvcTerrSchdPrio | 59.0 |
| CareProgramEnrollee.EnrolledAtId (Site Management) | 64.0 |
| Disease Surveillance (DiseaseDefinition, DiseaseInvestigation, DiseaseOutbreak, etc.) | 64.0 |
| Book Appointment, Cancel Appointment, Update Appointment, Get Slots invocable actions | 65.0 |
| CareBnftVrfyRqstStsChgEvent platform event | 65.0 |
| CoverageBenefit (Home Health add-on fields) | 66.0 |
