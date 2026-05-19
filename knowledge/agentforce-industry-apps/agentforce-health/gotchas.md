---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: gotchas
last-updated: 2026-05-11
---

# Health Cloud — Gotchas and Common Misconfigurations

---

### G-1: Health Cloud Available Only in Lightning Experience
**Source:** PDF p.5 — "Available in: Lightning Experience"
**Impact:** High

Health Cloud objects, features, and UI components are available only in Lightning Experience. Salesforce Classic is not supported. If the customer's org has Classic-only users or workflows, a Lightning migration must be planned as a prerequisite. Classic page layouts, S-Controls, and Classic-only customizations will not work with Health Cloud features. Verify Lightning Experience enablement and user adoption during discovery.

---

### G-2: Enterprise and Unlimited Editions Only
**Source:** PDF p.5 — "Available in: Enterprise and Unlimited Editions with Health Cloud"
**Impact:** High

Health Cloud is not available in Professional Edition, Group Edition, or Essentials. The customer must be on Enterprise or Unlimited Edition plus have the Health Cloud license added. Verify edition during pre-sales. Customers attempting to trial Health Cloud on Professional Edition orgs will not be able to enable the required features.

---

### G-3: CodeSet/CodeSetBundle Replaced HealthcareProcedure/HealthcareDiagnosis (Spring '21)
**Source:** PDF p.6 — "Before the Spring '21 release, the Healthcare Procedure and Healthcare Diagnosis objects stored codes specifically related to procedures and diagnoses. Since the Spring '21 release, Health Cloud uses the Code Set and Code Set Bundle objects for this purpose instead."
**Impact:** High

Any SOQL queries, Apex code, reports, or integrations targeting the deprecated `HealthcareProcedure` or `HealthcareDiagnosis` objects on orgs running Spring '21 or later will return no results or throw `INVALID_TYPE` errors. All clinical code references must use `CodeSet` (for a single code) and `CodeSetBundle` (for a grouping of codes, equivalent to FHIR CodeableConcept).

Additionally, `CareDiagnosis.DiagnosisCodeId` (the old lookup to HealthCareDiagnosis) is deprecated — use `CareDiagnosis.DiagnosisCodeSetId` (polymorphic lookup to CodeSet or CodeSetBundle) instead. The deprecated field will be removed in a future release.

---

### G-4: Feature Activation Required Per Domain — Deploying Objects for Unenabled Features Causes Errors
**Source:** PDF pp.455, 463, 712 and multiple domain sections
**Impact:** High

Many Health Cloud data model domains require explicit feature activation in Setup before their objects are queryable or deployable. Attempting to reference objects from an unenabled domain will throw `INVALID_TYPE` in SOQL or deployment errors. Known activation requirements:

| Domain | Activation Required |
|---|---|
| Disease Surveillance | Enable on Public Health Settings page |
| Integrated Care Management | Enable FHIR R4-Aligned Data Model (FHIR R4 Support Settings) + Enhanced Care Plans (ICM Settings) |
| Advanced Therapy Management | Enable Multi-Step Scheduling; purchase Asset Scheduler Add-On license |
| Crisis Support Center | Enable Health Cloud Crisis Support Center Management App permission set + license |
| Social Determinants | Install Health Cloud managed package; assign Health Cloud Social Determinants permission set |
| Home Health | Enable Home Health; FSL license required |

Always verify feature activation as part of the Discover phase org inspection before designing SOQL or deploying metadata.

---

### G-5: FHIR API Requires Separate Healthcare API License
**Source:** PDF p.5 — "Use Salesforce Healthcare API to securely connect and interact with a system that uses Fast Health Interoperability Resources (FHIR) APIs"
**Impact:** High

The Salesforce Healthcare API (FHIR endpoints) is a separately licensed add-on. It is NOT included in the base Health Cloud license. The FHIR-aligned data model objects (CareObservation, HealthCondition, etc.) are included in Health Cloud, but the bidirectional FHIR API endpoints for EHR integration require the Healthcare API license. Additionally, FHIR Subscription functionality requires MuleSoft for real-time notification delivery to subscriber endpoints. Include Healthcare API licensing in the pre-sales estimate if FHIR-based EHR integration is in scope.

---

### G-6: OmniStudio Required for Health Assessments and Discovery Framework
**Source:** PDF p.7 — "Health Cloud Assessments use the power of Discovery Framework and OmniStudio to build more complex questionnaire paths."
**Impact:** High

Health Assessments will not function without OmniStudio enabled. The Discovery Framework (used by both Health Assessments and Utilization Management clinical criteria) relies on OmniStudio's OmniScript and Integration Procedure capabilities. OmniStudio must be purchased, enabled, and its metadata deployment pipeline configured separately from standard Salesforce metadata. If the engagement includes clinical assessments, UM clinical criteria, or guided assessment workflows, OmniStudio must be in scope.

**Secondary impact:** OmniStudio metadata does NOT deploy via standard `sf project deploy start`. It requires the OmniStudio DataPack toolchain or the `sf vlocity` plugin. Plan a separate deployment pipeline and test it early.

---

### G-7: HL7 Parsing Requires Custom Apex or MuleSoft — No Native Declarative Parser
**Source:** PDF p.5 — "HL7 (Health Level Seven) is a standard for exchanging electronic health records (EHR). You can parse EHR data transmitted via HL7 data messages and store it in Salesforce." (No native parser is provided.)
**Impact:** High

There is no native HL7 v2.x parser in Salesforce declarative tools (Flow, Process Builder, Lightning Web Components). HL7 message parsing requires:
1. MuleSoft Direct Integration — recommended; out-of-the-box integration templates for Epic and Cerner are available in MuleSoft Exchange
2. Custom Apex — using a third-party HL7 parsing library or hand-rolled segment parser

Any engagement with EHR integration must include a middleware estimate. Never scope EHR integration as a simple point-to-point callout from Flow.

---

### G-8: CareProgramEnrollee Status Transitions Must Follow Valid Lifecycle — Cannot Skip States
**Source:** PDF pp.135-140 (CareProgramEnrollee object fields); standard Health Cloud business rule
**Impact:** High

`CareProgramEnrollee.Status` is a restricted picklist with a governed lifecycle. Status transitions must follow the defined state machine — you cannot jump from an early state directly to a terminal state by skipping intermediate states. Attempting an invalid transition via API or Flow will result in a validation error.

Always inspect the Status picklist values and allowed transitions in Setup before building enrollment flows. Document the valid transitions in the design artifact. If the customer needs custom lifecycle states, plan the customization explicitly — do not assume all picklist values can be set in any order.

---

### G-9: Benefits Verification Platform Events Are Asynchronous — Do Not Wait for Response in Flow
**Source:** PDF pp.1484-1485 — `CareBnftVrfyRqstStsChgEvent` platform event
**Impact:** High

Benefits verification calls (to payer systems) are processed asynchronously. The `CareBnftVrfyRqstStsChgEvent` platform event (API v65.0+) fires when the status of a care benefit verify request changes. The response is not immediate.

Do NOT design synchronous user-facing flows that pause and wait for a benefits verification response. This will cause flow interview timeouts (24-hour limit) and poor user experience. The correct architecture is:
1. Create `CareBenefitVerifyRequest` with Status = 'Pending'
2. Trigger async processing
3. Return to the user immediately with a "pending" confirmation
4. Platform event fires when status changes → updates record → notifies user

---

### G-10: Home Health Data Model Built on Salesforce Field Service — FSL License Required
**Source:** PDF p.8 — "The Home Health data model is primarily built over the Salesforce Field Service data model and uses many of its objects."
**Impact:** High

Home Health is not a standalone Health Cloud feature — it depends on the Salesforce Field Service (FSL) data model. Key objects like ServiceAppointment, ServiceResource, ServiceTerritory, WorkOrder, and WorkType are FSL objects. Implementing Home Health requires:
1. Salesforce Field Service license (separate, additional cost)
2. FSL configuration (service territories, resources, operating hours, scheduling policies)
3. The Asset Scheduler Add-On license if assets are assigned to service territories

If Home Health is in scope, include FSL in the BOM and license review during pre-sales. The FSL implementation adds significant scope that must be estimated separately.

---

### G-11: Social Determinants Available from API v45.0 — Verify Org API Version
**Source:** PDF p.9 — "The social determinants data model represents the barriers, health determinants, and interventions for a patient or member. Available in API version 45.0 and later."
**Impact:** Medium

The Social Determinants domain (`CareBarrier`, `CareDeterminant`, `CareBarrierDeterminant`, etc.) requires API version 45.0 or later. Most modern orgs will meet this requirement, but verify the org's current API version before deploying SDOH components. Additionally, Social Determinants requires the Health Cloud managed package to be installed AND the `Health Cloud Social Determinants` permission set assigned.

---

### G-12: Person Accounts Cannot Be Disabled After Enablement
**Source:** Standard Salesforce platform behavior; confirmed by Health Cloud's FHIR mapping — "Patients are modeled using Person Accounts"
**Impact:** High

Health Cloud's FHIR mapping models patients as Person Accounts (PDF p.1488). Enabling Person Accounts in a Salesforce org is irreversible — it cannot be disabled after activation. If enabled in an existing org with large volumes of Contact data, all existing Contact records are affected by the Person Account model change. This requires a migration plan, stakeholder sign-off, and testing.

Confirm the Account model (Person Account vs. standard Account+Contact) during discovery. This is an org-level architectural decision with permanent consequences.

---

### G-13: FHIR Data Type Handling Differs from FHIR Specification — Integration Logic Must Account for Flattening
**Source:** PDF pp.1488-1490 — "Considerations for Integration"
**Impact:** Medium

Salesforce's implementation of FHIR R4 differs from the FHIR specification in how complex data types are stored:

- **Period** → flattened to two fields: `ActiveFromDate` / `ActiveToDate` (or similar start/end pair)
- **Quantity** → flattened to numeric value field + unit field (with lookup to UnitofMeasure object)
- **Range** → flattened to `LowerLimit`, `UpperLimit`, and unit fields
- **Ratio** → flattened to numerator + denominator + unit fields
- **URI** → stored as string (e.g., `CodeSet.SourceSystem`, `Identifier.SourceSystem`)
- **FHIR code type** → stored as string in Salesforce (not a code enum)
- **Zero-to-many coding (CodeableConcept)** → flattened to 15 CodeSet1Id through CodeSet15Id reference fields

Integration mappings must account for this flattening. FHIR transformation logic in MuleSoft or Apex must expand Salesforce fields back into proper FHIR resources when sending data out, and decompose FHIR resources into flattened fields when receiving.

---

### G-14: CodeSetBundle Supports Only 15 CodeSet References (FHIR CodeableConcept Flattening)
**Source:** PDF p.1489 — "According to FHIR, CodeableConcept has a zero-to-many coding resource. Because Salesforce doesn't support zero-to-many references, Code Set Bundle flattens this zero-to-many reference to 15 zero-to-one Code Set references (CodeSet1Id through CodeSet15Id)."
**Impact:** Medium

If a clinical code concept requires more than 15 code system references simultaneously (e.g., a procedure code that maps to more than 15 different coding systems at once), the standard CodeSetBundle model cannot accommodate it. This is an edge case in most implementations but must be considered in clinical data model design for complex code mapping scenarios.

---

### G-15: EngagementInteraction / EngagementAttendee / EngagementTopic — 50 Custom Field Limit Each
**Source:** PDF p.7 — "You can add up to 50 custom fields each in the EngagementAttendee, EngagementInteraction, and EngagementTopic objects."
**Impact:** Low

The Engagement domain objects have a hard limit of 50 custom fields per object (in addition to standard fields). This is significantly lower than the standard Salesforce limit of 500 custom fields per object. If the engagement interaction data model requires many custom capture fields, this limit may be hit. Plan the field model carefully.

---

### G-16: CareFacilityBed Requires Crisis Support Center License — Not General-Purpose
**Source:** PDF p.455 — "Crisis Support Center Management objects are available to users who are assigned the Health Cloud Crisis Support Center Management App permission set and the Health Cloud Crisis Support Center Management permission set license. Users also need the Health Cloud Foundation permission set and the Health Cloud Platform permission set license."
**Impact:** Medium

The `CareFacilityBed` object and related Crisis Support Center objects are not general-purpose bed management objects. They require a specific permission set license (Crisis Support Center Management). Do not use these objects for non-crisis capacity management use cases — use a custom object or the standard Salesforce Scheduler capacity model instead.

---

### G-17: Appointment Actions Require External Resource Slots When Booking External System Appointments
**Source:** PDF pp.2169-2172 — Book Appointment action
**Impact:** Medium

When booking an appointment with an external resource (e.g., an appointment slot in an external EHR system), the `slots` input array is required in the Book Appointment action. The `sourceSystem` input is also required when `workTypeId` is not provided. For Salesforce-native resources, `workTypeId` suffices. Integration designs that mix native and external resource booking must handle both input patterns.

---

### G-18: Disease Surveillance Objects Available from API v64.0 Only
**Source:** PDF p.463 — "DiseaseDefinition: This object is available in API version 64.0 and later."
**Impact:** Medium

All Disease Surveillance objects (DiseaseDefinition, DiseaseDefinitionCriteria, DiseaseInvestigation, etc.) were introduced in API version 64.0. Orgs on older API versions cannot use these objects. Additionally, the feature must be explicitly enabled on the Public Health Settings page. Public health engagements must verify both the org API version and feature activation.

---

### G-19: Apex Managed Sharing Required for Care Team Access — No Declarative Alternative
**Source:** Standard Health Cloud architecture; confirmed in security model analysis
**Impact:** High

There is no declarative sharing rule that can evaluate "share this patient Account with the User who has a CareTeamMember record for it." Standard sharing rules cannot reference record-specific conditions of this type. Apex Managed Sharing (`AccountShare` insert/delete via Apex triggers on CareTeamMember create/delete) is mandatory in any Health Cloud implementation that uses care team-based patient record access.

Missing the **delete trigger** is the most common security defect. Former care team members retain access to patient records indefinitely until the AccountShare is explicitly deleted.

---

### G-20: MuleSoft Required for FHIR Subscription Notifications to External Subscribers
**Source:** PDF p.7 — "When an event change occurs in the subscribed resource, it triggers a notification and a platform event is created as an Interoperability Topic Subscription Event record. Then, Mulesoft sends the notification to the subscriber's endpoint in real time."
**Impact:** Medium

The FHIR Subscription feature (InteropTopicSubscription domain) relies on MuleSoft to deliver real-time notifications to external subscriber endpoints. Salesforce creates the platform event when a subscribed FHIR resource changes, but MuleSoft is the delivery layer. Implementations using FHIR Subscription for external system notifications must include MuleSoft in the architecture.

---

### G-21: CareRequest DiagnosisCodeId Is Deprecated — Use DiagnosisCodeSetId
**Source:** PDF p.1333 — "DiagnosisCodeId will be deprecated in a future release, so use DiagnosisCodeSetId instead."
**Impact:** Medium

In the `CareDiagnosis` object, the legacy `DiagnosisCodeId` field (lookup to the deprecated `HealthCareDiagnosis` object) is being removed. All new development must use `DiagnosisCodeSetId` (polymorphic lookup to CodeSet or CodeSetBundle). Any existing implementations or integrations using `DiagnosisCodeId` need to be migrated.

---

### G-22: Health Cloud HIPAA BAA Must Be in Place Before Storing Any PHI
**Impact:** High
**Source:** Compliance requirement; not in technical PDF but operationally critical for all HC engagements

A signed Business Associate Agreement (BAA) between the customer and Salesforce must exist before any PHI is stored in the org. Without a BAA, storing patient names, dates of birth, or diagnosis information in Salesforce is a HIPAA violation. This is a pre-implementation legal requirement. Confirm the BAA exists and is on file during discovery. This is the first compliance checkpoint.
