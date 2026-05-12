---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Health Cloud — Automation Patterns

## Invocable Actions Reference

**Source:** PDF pp.2168-2219 (Health Cloud Standard Invocable Actions section)

Health Cloud provides standard invocable actions for healthcare facility management and appointment workflows. These are accessible via REST HTTP methods and can be called from Flow using the Invocable Action element.

| Action Name | API Version | HTTP Method / URI | Purpose | Key Inputs | Key Outputs |
|---|---|---|---|---|---|
| **Book Appointment** | v65.0+ | POST `/services/data/v65.0/connect/health/appointment-management/appointment` | Create or book a new appointment | `workTypeId` OR `appointmentTypes`/`serviceTypes`/`serviceCategories`; `participants` (Patient + Facility required; Provider or Device required); `startDate` (required); `channelId` (if engagement channel configured); `slots` (for external resources) | `id`, `isSuccess`, `status`, `errorMessages` |
| **Cancel Appointment** | v65.0+ | PATCH `/services/data/66.0/connect/health/appointment-management/appointment/{id}` | Cancel an existing appointment | `id` (URL param, required); `status` (required, e.g. "Cancelled"); `cancellationReason`; `comment` | `id`, `isSuccess`, `status`, `errorMessages` |
| **Create Referral** | v59.0+ | POST `/services/data/vXX.X/actions/standard/createReferral` | Create a patient referral (creates Account, ClinicalServiceRequest, ClinicalServiceRequestDetail) | `subjectRecord` (required — patient Account details); `requesterId` (required — requesting provider ID); `performers` (required — comma-separated provider/org IDs); `referralRecord` (ClinicalServiceRequest fields); `referralDetailsRecords`; `matchDuplicates`; `referralNotes` | `referralIds` (list of created referral IDs) |
| **Create Quote for Home Visits** | v63.0+ | POST `/services/data/v63/actions/standard/createQuoteForHomeVisits` | Create a quote for patient home visits | `quoteName` (required); `priceBookId` (required); `accountId`; `opportunityId`; `startDateTime`; `endDateTime`; `workTypeIds`; `visitCount`; `isTravelInventoryIncluded`; `pricingPreference` (System/Force/Skip); `currencyCode`; `productPricingAttributeDetails` | `quoteId`; `errorMessage`; `errorCode` |
| **Create Template of Service Appointment** | v63.0+ | POST (standard action) | Create a Cancelled-status service appointment used as a template for manual home visit scheduling | Template details | Service appointment ID |
| **Get Data Using Context Definition** | — | POST (standard action) | Get data from a context service using a context definition and associated context mapping | Context definition ID; context mapping | Data from context service |
| **Get Resources** | — | POST (standard action) | Search for available resources (healthcare providers, medical assets) based on search criteria | Search criteria | Available resources list |
| **Get Resources for Manual Scheduling** | — | POST (standard action) | Recommend resources for manual scheduling of start-of-care visit or recurring visits | Visit details; scheduling constraints | Recommended resources |
| **Get Slots** | v65.0 context | POST `/services/data/v65.0/connect/health/appointment-management/slots` | Retrieve available appointment slots for one or more resources | `startDate` (required); `endDate`; `workTypeId` OR `appointmentTypes`/`serviceTypes`/`serviceCategories`; `channelId`; `resources` array; `sourceSystem` | `resourceSlotDetails` array |
| **Get Transcript from Conversation** | — | POST (standard action) | Get transcript for a conversation record (voice call, messaging session, chat transcript) | Conversation record ID | Transcript content |
| **Handle Resource Absence** | — | POST (standard action) | Remove service resource visit assignments for a period; optionally update affected visit statuses | Resource ID; date range; target status | Update results |
| **Process Received Document** | — | POST (standard action) | Create a record with processed results of a received document | Received document reference | Created record ID |
| **Reschedule Recurring Home Visits** | — | POST (standard action) | Reschedule all home visits based on recurrence pattern and scheduling policy | Recurrence pattern; scheduling policy ID; affected visit details | Updated visit records |
| **Schedule Group Visits** | — | POST (standard action) | Create visiting records for patient home visits bundled into a group; schedule single start-of-care or series of recurring visits | Bundle details; visit type | Care service visit records |
| **Schedule Home Visit** | — | POST (standard action) | Schedule a home visit to assess the patient condition before scheduling recurring visits | Patient details; assessment visit parameters | Start-of-care service appointment |
| **Schedule Home Visits Manually** | — | POST (standard action) | Create start-of-care or recurring home visits with manually selected care resources | Care resource selection; scheduling details | Visit records |
| **Schedule Recurring Home Visit** | v63.0+ context | POST `/services/data/v63/actions/standard/scheduleRecurringHomeVisit` | Create a set of recurring home healthcare visits and assign service resources per scheduling policy | `schedulingPolicyId`; `firstVisitStartDateTime`; `firstVisitStartEndTime`; `visitsRequired`; `frequencyType` (DAILY etc.); `selectedDays`; `clinicalServiceRequestId`; `skillsIdList`; `operatingHoursId`; `accountId`; `serviceTerritoryId`; resource lists; `workTypeIdsList`; `visitSourceId` | `careServiceVisitPlanId`; `serviceAppointmentId` |
| **Update Appointment** | v65.0+ | PUT `/services/data/66.0/connect/health/appointment-management/appointment/{id}` | Update an existing appointment | `id` (URL param, required); `workTypeId` OR `appointmentTypes`/`serviceTypes`/`serviceCategories`; `participants`; `startDate`; `endDate`; `channelId`; `slots`; `sourceSystem`; `specialties`; `timeZone` | `id`, `isSuccess`, `status`, `errorMessages` |

**Note on participants for Book/Update Appointment:**
- Patient (Account reference as `Patient/{id}`) and Facility (Location reference as `Facility/{id}`) are mandatory
- For single resource appointment: either Device (asset) or Provider required
- For multi-resource appointment: both Device and Provider required

---

## Pattern 1: Care Program Enrollment

**Trigger:** Care Coordinator initiates enrollment via Screen Flow or OmniScript
**Objects created:** CareProgramEnrollee, CarePlan (optionally), CareTeamMember assignments

```
Screen Flow or OmniScript:
  Screen 1: Search/match existing Account (patient)
  Screen 2: Select CareProgram; collect enrollment date
  Screen 3: Assign Care Coordinator (User lookup)
  Screen 4: Confirmation

  Actions:
    → Create CareProgramEnrollee:
        AccountId = matched patient Account
        CareProgramId = selected program
        Status = 'Active' (validate lifecycle — cannot skip states)
        EnrollmentDate = TODAY
    → Create CareProgramTeamMember:
        CareProgramEnrolleeId = new enrollee
        UserId = selected care coordinator
        Role = 'Care Coordinator'
    → Optionally invoke Health Cloud Business API for complex enrollment
      (if multi-object creation with business logic needed)
    → Create initial CarePlan if ICM is enabled:
        AccountId = patient
        Status = 'Active'
        StartDate = TODAY
```

**Critical business rule:** `CareProgramEnrollee.Status` transitions must follow a valid lifecycle. You cannot skip states (e.g., cannot go directly from Pending to Completed without passing through Active). Validate the picklist transitions in Setup before building enrollment flows.

---

## Pattern 2: Benefits Verification Request

**Trigger:** Record-Triggered Flow on CareBenefitVerifyRequest after Insert
**Important:** Benefits verification is asynchronous — the response comes via Platform Event, not synchronously.

```
Record-Triggered Flow on CareBenefitVerifyRequest | After Insert
  → Invoke Health Cloud Business API for Benefits Verification
    (or external payer system callout via Integration Procedure)
  → Set Status = 'In Progress'

--- Asynchronous response path ---

Platform Event Trigger: CareBnftVrfyRqstStsChgEvent (API v65.0+)
  → On receive: Query CareBenefitVerifyRequest by RecordIdentifier
  → Update CareBenefitVerifyRequest.Status = event.Status
  → If Status = 'Completed':
      Create CoverageBenefit records from response data
      Notify requesting care coordinator via custom notification
  → If Status = 'Failed':
      Create Task: 'Manual benefits verification required'
      Assign to benefits verification queue
```

**Design warning:** Do NOT build synchronous user-facing flows that wait for a benefits verification response. The platform event pattern is the correct architecture. Synchronous waits will cause flow timeouts and poor user experience.

---

## Pattern 3: Prior Authorization / Utilization Management Request

**Trigger:** Flow trigger on CareRequest creation; or OmniScript-guided UM intake
**Objects involved:** CareRequest, CareDiagnosis, CareRequestItem, CareRequestReviewer, Discovery Framework assessments

```
Record-Triggered Flow on CareRequest | After Insert
  Decision: CareRequest.RequestType
    → 'Service Request':
        Create CareRequestItem with CPT codes (via CodeSet reference)
        Assign to UM Nurse Reviewer queue based on specialty
    → 'Drug Request':
        Create CareRequestDrug with medication details
        Assign to Pharmacy UM queue
    → 'Admission Notification':
        Create CareRequestItem with DRG code
        Assign to concurrent review queue

  For all types:
    → Check SLA timeline:
        If CareRequest.IsUrgent = true:
          Set target review date = TODAY + 3 (72-hour CMS requirement)
          Assign to Expedited UM queue
        Else:
          Set target review date = TODAY + 14 (14-day CMS standard requirement)
    → Send acknowledgement notification to requesting provider

--- Clinical Review Path ---

CareRequestReviewer record created by UM reviewer:
  → UM reviewer creates CareRequestReviewer:
      ReviewerType = 'Clinical'
      Status = 'In Review'
  → If clinical criteria met: Status = 'Approved'
  → If not met: Status = 'Denied'
      → Create TrackedCommunication for denial notice to provider
  → If peer-to-peer review requested:
      Assign to Medical Director queue
      Create CareRequestReviewer (Type = 'Medical Director')
```

**OmniStudio note:** Utilization Management assessments use Discovery Framework objects for clinical criteria decision support. OmniStudio must be enabled if clinical criteria questionnaires are part of the UM workflow.

---

## Pattern 4: Assessment Administration (Discovery Framework / OmniStudio)

**Trigger:** Care Coordinator initiates assessment from patient record via OmniScript
**Objects involved:** AssessmentDefinition, AssessmentQuestion, AssessmentQuestionResponse, AssessmentIndicatorDefinition

```
OmniScript → Assessment flow:
  Step 1: Load AssessmentDefinition for the required assessment type
  Step 2: Use DataRaptor to fetch AssessmentQuestion records
           (filtered by AssessmentDefinition + active AssessmentQuestionVersion)
  Step 3: Render questions in OmniScript UI
  Step 4: Patient/coordinator provides responses
  Step 5: Save AssessmentQuestionResponse records

--- Post-assessment scoring ---

Integration Procedure (or Apex):
  → Load AssessmentIndicatorDefinition records for this assessment
  → Score responses against indicator thresholds
  → Determine risk level or clinical finding

--- Care plan actions ---

Record-Triggered Flow or Integration Procedure:
  → If score indicates high risk:
      Create GoalAssignment (if ICM enabled)
      Create CarePlanActivity records for intervention tasks
      Assign to appropriate care coordinator
  → If SDOH screening indicates barriers:
      Create CareBarrier records
      Create CareDeterminant records
      Link via CareBarrierDeterminant
```

**Note:** Assessment Generation (AI-powered question creation from source documents) uses Einstein generative AI capabilities and requires separate license/enablement. The OmniScript/DataRaptor pattern above is for standard Discovery Framework assessment delivery.

---

## Pattern 5: Care Plan Activity Automation

**Scheduled Flow — care gap outreach:**

```
Scheduled Flow (daily):
  Query: CarePlanActivity WHERE Status NOT IN ('Completed','Cancelled')
          AND ActivityDate < TODAY - 7 (overdue threshold)
          AND OwnerId IN :[care coordinator user set]
  Loop: For each overdue CarePlanActivity
    → Create Task: 'Follow up on overdue care plan activity'
      Subject = 'Overdue: ' + CarePlanActivity.Subject
      WhatId = CarePlanActivity.CarePlanId
      ActivityDate = TODAY
      OwnerId = CarePlanActivity.OwnerId
    → If ActivityDate < TODAY - 14 (escalation threshold):
        Send custom notification to care manager's supervisor
        Create CareObservation: Type = 'Care Plan Adherence Alert'
```

**Governor limit warning:** Scheduled Flows have a 2,000-record-per-interview limit and cannot be parallelized. For populations over 1,000 patients, use Scheduled Batch Apex instead of Scheduled Flow for this pattern. Scheduled Flows are appropriate for low-volume scenarios only.

---

## Pattern 6: HL7 / EHR Integration

**Source:** PDF p.5 — "HL7 (Health Level Seven) is a standard for exchanging electronic health records (EHR). You can parse EHR data transmitted via HL7 data messages and store it in Salesforce."

```
--- HL7 v2.3 Inbound Path ---

MuleSoft Direct Integration (preferred) or Custom Apex HL7 Parser:
  → Receive HL7 v2.3 message
  → Parse segments:
      PID → Account (Patient) — map to PersonName, ContactPointAddress
      PV1 → ClinicalEncounter — admit type, attending provider
      DG1 → ClinicalEncounterDiagnosis — ICD-10 codes → CodeSet records
      OBX → CareObservation + CareObservationComponent — lab results
      AL1 → AllergyIntolerance
      RXA/RXO → MedicationRequest or MedicationStatement
  → Upsert to Salesforce via FHIR-aligned objects
  → Fire Platform Event if downstream processing needed

--- FHIR R4 Inbound Path ---

Salesforce Healthcare API (requires separate license):
  → FHIR server receives R4 resource bundle
  → Maps resources to Salesforce objects per FHIR-to-Salesforce mapping table
    (see data-model.md for full mapping)
  → Consent verification (21st Century Cures Act) before patient data ingestion
  → FHIR Subscription model can notify downstream systems via
    InteropTopicSubscription → MuleSoft → subscriber endpoint
```

**Important:** There is no native HL7 parser in Salesforce declarative tools (Flow, Process Builder). HL7 v2.3 parsing requires either:
1. MuleSoft Direct Integration (out-of-the-box integration templates available in MuleSoft Exchange)
2. Custom Apex with a third-party HL7 parsing library

A middleware integration solution is required to convert messages from HL7 and FHIR-based systems to Salesforce fields and objects.

---

## Pattern 7: Remote Monitoring / Device Data Ingestion

```
External device data ingest (custom or via MuleSoft):
  → Receive device reading (e.g., blood pressure, glucose, heart rate)
  → Match to patient Account via MRN or device ID
  → Create CareObservation:
      PatientId = matched Account
      Code = LOINC code for the measurement type
      CodeSystem = 'LOINC'
      ObservationDate = reading timestamp
      CareObservationComponent for each reading value

Record-Triggered Flow on CareObservation | After Insert:
  → Evaluate thresholds (via custom metadata for configurable limits)
  → If value outside normal range:
      Create Task for care coordinator
      Send notification to assigned provider
      If critical threshold: create high-priority Case
```

---

## Pattern 8: Home Health Visit Scheduling

**Using Schedule Recurring Home Visit invocable action:**

```
Screen Flow or OmniScript (Home Health Coordinator):
  Screen 1: Select patient (Account)
  Screen 2: Select ClinicalServiceRequest (the care order)
  Screen 3: Select scheduling policy, work types, frequency

  Action: Schedule Recurring Home Visit
    Inputs:
      schedulingPolicyId: selected policy
      firstVisitStartDateTime: start of recurring window
      visitsRequired: ordered count
      frequencyType: 'DAILY' / 'WEEKLY' / etc.
      clinicalServiceRequestId: care order reference
      skillsIdList: required caregiver skills
      accountId: patient Account
      serviceTerritoryId: patient service territory
      workTypeIdsList: visit types
    Output:
      careServiceVisitPlanId → store on CareServiceVisitPlan
      serviceAppointmentId → first appointment created

--- Resource conflict handling ---

Handle Resource Absence action:
  → If care resource is unavailable:
      Remove their visit assignments for the absence period
      Optionally set affected visit Status to 'Unscheduled'
      Reschedule via Reschedule Recurring Home Visits action
```

---

## Automation Decision Matrix

| Use Case | Recommended Approach | When to Use Instead |
|---|---|---|
| Single-record create/update with simple conditions | **Record-Triggered Flow** | Simple, no complex multi-object orchestration needed |
| Guided multi-step intake or care coordination workflows | **OmniScript + Integration Procedures** | When workflow has branching, conditional screens, multi-step navigation |
| Benefits verification, prior auth, enrollment (complex multi-object) | **Health Cloud Business API** | Standard healthcare business operations; wraps complex logic |
| Appointment booking, cancellation, slot retrieval | **Invocable Actions** (Book/Cancel/Get Slots) | Purpose-built for appointment management |
| EHR/HL7 data ingestion | **MuleSoft Direct Integration** or **Custom Apex** | No native HL7 parser available |
| FHIR R4 bidirectional sync | **Salesforce Healthcare API** | Requires separate Healthcare API license |
| Population-scale scheduled processing (>1,000 records) | **Scheduled Batch Apex** | Scheduled Flow has 2,000-record limit; cannot be parallelized |
| Low-volume scheduled tasks (<1,000 records) | **Scheduled Flow** | Simple scheduled automation |
| Clinical questionnaires / assessments | **Discovery Framework + OmniScript** | OmniStudio required; standard for health assessments and UM criteria |
| Einstein AI-powered assessment generation | **Assessment Generation feature** | Requires Einstein generative AI license |
| Consent / electronic signature workflows | **Digital Verifications / Electronic Signatures** | Built-in Health Cloud feature |

---

## Platform Events Reference

**Source:** PDF pp.1483-1485

### ApplnFormAppealStsChgEvnt
**Available:** API version 63.0 and later
**Access:** Requires Health Cloud Starter and Manage Financial Assistance Program permission set

| Field | Type | Description |
|---|---|---|
| `AppealIdentifier` | string | Identifier of the appeal with a status change |
| `AppealStatus` | picklist | Accepted / Rejected |
| `ApplicationFormIdentifier` | string | Identifier of the associated application |
| `EventCreationDateTime` | dateTime | When the event was created |

**When fired:** When the status of a Financial Assistance Program appeal changes.

### CareBnftVrfyRqstStsChgEvent
**Available:** API version 65.0 and later
**Access:** Requires Manage Pharmacy Benefits Verification AND Health Cloud Starter (Life Sciences Cloud) or Health Cloud Foundation (Health Cloud) permission set

| Field | Type | Description |
|---|---|---|
| `EventCreationDateTime` | dateTime | When the event was created |
| `RecordIdentifier` | string | Identifier of the associated care benefit verify request record |
| `Status` | string | Status of the care benefit verify request |

**When fired:** When the status of a care benefit verify request changes. This is the downstream trigger for updating CareBenefitVerifyRequest records and creating CoverageBenefit records.

---

## Business APIs Summary

**Source:** PDF pp.1771+ — the Business APIs are described as RESTful APIs that "wrap complex business logic by executing multiple tasks within a single API call."

The Business APIs are the recommended integration layer for Health Cloud operations. They differ from standard REST APIs in that:
- A single call can create multiple related objects
- They enforce Health Cloud business rules (e.g., status lifecycle validation)
- They do not require callers to understand the full Health Cloud data model
- Most are RESTful; some are also available as Apex classes/methods

**Comparison: Business API vs Invocable Action vs Custom Apex**

| Factor | Business API | Invocable Action | Custom Apex |
|---|---|---|---|
| Best for | Integration layer, external systems, custom UI components | Flow-based automation, low-code orchestration | Complex custom logic, bulk operations, non-standard patterns |
| Requires understanding data model? | No (wraps it) | Partially | Yes (full) |
| Bulk capable? | Limited — per-patient operations | Limited — flow iteration | Yes (Batch Apex) |
| Standard healthcare patterns | Yes | Yes (appointment-focused) | No — must implement from scratch |
| MuleSoft integration friendly | Yes (REST) | Via Salesforce API | Via Salesforce API |
