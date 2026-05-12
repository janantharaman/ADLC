---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: overview
last-updated: 2026-05-11
---

# Health Cloud — Overview

## What It Is

Salesforce Health Cloud is a vertical industry cloud built on the Salesforce Platform, designed for healthcare providers, health insurance payers, life sciences organizations, and public health agencies. It provides a unified patient and member profile, care program management, clinical data integration, utilization management, prior authorization, social determinants of health tracking, and interoperability via FHIR R4 and HL7 standards. Health Cloud is built exclusively for Lightning Experience and is available in Enterprise and Unlimited Editions when the Health Cloud license is added.

**Source:** PDF p.5 — "This guide provides information on the custom objects used by Health Cloud and their fields … Available in: Lightning Experience … Available in: Enterprise and Unlimited Editions with Health Cloud."

---

## Industry Verticals and Use Cases

| Vertical | Primary Use Cases | Key Objects |
|---|---|---|
| **Provider** | Care management, clinical workflows, care plan coordination, post-discharge follow-up, referral management, home health scheduling | CarePlan, CareObservation, ClinicalEncounter, CareProgramEnrollee, ClinicalServiceRequest |
| **Payer** | Member enrollment, benefits verification, utilization management, prior authorization, provider network management, pharmacy benefits | CareRequest, CareBenefitVerifyRequest, CoverageBenefit, MemberPlan, CareProgram |
| **Life Sciences** | Clinical trial participant management, adverse event reporting, intelligent sales, advanced therapy management, medication management | AdverseEvent, ResearchStudy, MedicationReconciliation, CareProgramEnrollee |
| **Public Health** | Disease surveillance, emergency response management, crisis support center, population health monitoring | DiseaseDefinition, DiseaseInvestigation, DiseaseOutbreak, CareFacilityBed |

---

## Core Feature Domains

The following domains are documented in the Health Cloud Data Model (PDF pp.6-9). Each is a separately licensed or separately enabled feature area:

1. **Advanced Therapy Management** — Multi-step scheduling for complex therapies (cell and gene therapy). Powered by Salesforce Scheduler. Requires Multi-Step Scheduling permission set and Asset Scheduler Add-On license.
2. **Adverse Events** — Managing and documenting unfavorable or unintended signs, symptoms, or diseases from medical intervention. FHIR-aligned to the AdverseEvent resource.
3. **Assessment Generation** — Uses Einstein generative AI to create assessment questions from source documents. Combined with Discovery Framework for healthcare questionnaires.
4. **Benefits Verification** — Supports providers, payers, and life sciences organizations in determining benefits coverage for services and products. FHIR-aligned.
5. **Care Program Management** — Patient enrollment and management for care programs. Drives adherence and patient outcomes. Core object: CareProgramEnrollee.
6. **Clinical Data Model** — USCDI and FHIR R4-aligned clinical data storage. Replaced HealthcareProcedure/HealthcareDiagnosis with CodeSet/CodeSetBundle from Spring '21.
7. **Coverage Requirement Discovery (CRD)** — FHIR-aligned model for payer organizations to help providers access member and coverage-related information from EHR systems in real time.
8. **Crisis Support Center Management** — Range of crisis services from a single app: intake flow, provider/bed search across facilities. Requires Health Cloud Crisis Support Center Management App permission set and license.
9. **Disease Surveillance** — Tracks and manages disease data and public health activities. Centralized patient demographics, disability status, medications, specimens. Available from API v64.0 and later. Must enable in Public Health Settings.
10. **Documentation Templates and Rules (DTR)** — Da Vinci DTR framework under HL7 FHIR standards for standardized templates and rules in healthcare documentation. Uses CRD data model objects.
11. **Electronic Signatures** — Manages electronic consent via Digital Verifications. Supports ordered verifiers, user groups, and participant roles.
12. **Engagement Interaction** — Stores details about interactions between customers or their representatives and care agents (CCAs). Supports quick actions, custom fields (up to 50 per object), and personalized list views.
13. **FHIR Subscription** — Publishers store subscription topics, subscriber details, filters, and parameters. Platform events fire when subscribed resource changes occur. MuleSoft delivers notifications to subscriber endpoints.
14. **Financial Assistance Program** — Helps health and life sciences organizations implement programs for eligible patients receiving assistance with out-of-pocket medical expenses.
15. **Health Assessments** — Uses Discovery Framework and OmniStudio to build complex questionnaire paths. OmniStudio is required.
16. **Health Insurance** — Objects for managing healthcare payment, including employment, insurance coverage, dependents, benefits, and preauthorization requests.
17. **Home Health** — Data model built over Salesforce Field Service (FSL) objects. Stores patient preferences, resource skills, home visit details. Requires Field Service Lightning license.
18. **Integrated Care Management (ICM)** — USCDI and FHIR R4-aligned data model for clinical care plans, care plan templates, episodes of care. Requires enabling FHIR R4-Aligned Data Model and Enhanced Care Plans settings.
19. **Intelligent Appointment Management** — Integrates with external appointment management systems for multi-platform EHR appointment booking from within Salesforce.
20. **Intelligent Document Automation** — Simplifies document management, reduces manual entry, manages patient/member forms from intake through processing.
21. **Intelligent Sales** — Helps sales teams plan and execute sales visits and manage field inventory.
22. **Medication Management** — Objects for medication reconciliation, medication therapy reviews, comprehensive and targeted medication reviews.
23. **Participant Management** — Streamlines clinical trial recruitment and enrollment with USCDI and FHIR R4-aligned data model.
24. **Patient Program Outcome Management** — Defines and measures program outcomes, links patient progress to program outcomes. Supports program summary and patient outcome summary generation.
25. **Patient Segmentation** — Patient Segmentation dashboard generates insights into patient demographics and risk scores based on risk adjustment factors.
26. **Pharmacy Benefits Verification** — FHIR-CARIN and NCPDP-aligned data model for pharmacy benefits coverage determination.
27. **Prior Authorization / Utilization Management (UM)** — Supports health plan UM processes: reviewing medical care services, communicating clinical policies, ensuring right care in right setting at right time. Uses Discovery Framework objects.
28. **Provider Network Management** — Allows health insurance companies to manage provider networks and contract payment terms, and helps members find care.
29. **Provider Relationship Management** — Uses standard Salesforce objects to manage provider relationships.
30. **Remote Monitoring and Device Registration** — Data collected from patient devices (smart watches, heart monitors, etc.).
31. **Social Determinants of Health (SDOH)** — Represents barriers, health determinants, and interventions for a patient or member. Available from API version 45.0 and later.
32. **Timeline** — Configures a chronological view of records from multiple objects on a single page.
33. **Unified Health Scoring** — Three objects, three Tooling APIs, and a metadata type for implementing a unified health profile in Health Cloud.
34. **Utilization Management** — See Prior Authorization above; uses same set of CareRequest objects plus Discovery Framework.

---

## Key Architecture Principles

1. **FHIR R4 Alignment** — The Clinical Data Model is built to align with HL7's FHIR R4. FHIR resources map to specific Salesforce objects (see api-reference.md for full mapping). The implementation differs from the FHIR specification in how data types are handled (periods flattened to start/end dates, quantities flattened to value+unit fields, etc.).
2. **HL7 v2.3 Compatibility** — Because the Clinical Data Model aligns with FHIR R4, it is also compatible with its predecessor HL7 v2.3. A middleware layer (MuleSoft or custom Apex) is required to parse and map HL7 messages.
3. **OmniStudio / Discovery Framework** — Health Assessments, Utilization Management assessments, and many guided care workflows require OmniStudio (formerly Vlocity). OmniStudio deploys via its own toolchain separate from standard Salesforce metadata API.
4. **MuleSoft for EHR Integration** — Out-of-the-box integration templates ("MuleSoft Direct Integrations") are available in MuleSoft Exchange for connecting Health Cloud with external EHR systems.
5. **CodeSet and CodeSetBundle as the Code Standard** — Since Spring '21, all clinical codes (procedures, diagnoses, service types) are represented via CodeSet and CodeSetBundle objects. The prior HealthcareProcedure/HealthcareDiagnosis objects are deprecated.
6. **Person Accounts for Patients** — The Patient FHIR resource maps to Account and Contact objects. Patients are modeled using Person Accounts. This is an irreversible org setting.
7. **Business APIs for Complex Operations** — Health Cloud Business APIs wrap complex multi-object business logic into single API calls for common use cases (enrollment, prior auth, benefits verification). These are the recommended integration and UI component layer.

---

## Integration Points

| Integration | Technology | Purpose | Notes |
|---|---|---|---|
| EHR Systems (Epic, Cerner, etc.) | MuleSoft Direct Integrations or custom HL7 Apex parser | Receive clinical data from EHR, create ClinicalDocument / ClinicalEncounter / CareObservation records | Middleware required; no native HL7 parser in Salesforce |
| FHIR R4 APIs | Salesforce Healthcare API | Bidirectional sync with FHIR-compliant systems | Requires separate Healthcare API license; FHIR feature activation required |
| Einstein AI | Einstein for Health (separate license) | Predictive analytics, risk stratification, assessment generation | Not native to base Health Cloud; must be licensed separately |
| OmniStudio | OmniScript, Integration Procedures, DataRaptors | Guided care workflows, Health Assessments, discovery framework questionnaires | OmniStudio must be enabled; deploys separately from standard metadata |
| External Appointment Systems | Intelligent Appointment Management | Multi-EHR appointment booking from Salesforce | Supports multiple source systems on different EHR platforms |
| Remote Monitoring Devices | Remote Monitoring and Device Registration objects | Ingest device-collected health data | Data model objects; integration layer is customer-implemented |

---

## Editions and Licensing

- **Base requirement:** Enterprise Edition or Unlimited Edition with the **Health Cloud license** added.
- **Lightning Experience only:** Health Cloud is not available in Salesforce Classic.
- **Features requiring additional enablement:**
  - Advanced Therapy Management: Multi-Step Scheduling permission set + Asset Scheduler Add-On license
  - Crisis Support Center: Health Cloud Crisis Support Center Management App permission set + Crisis Support Center Management permission set license
  - Disease Surveillance: Enable in Public Health Settings; API v64.0 and later
  - FHIR APIs: Separate Healthcare API license required
  - Home Health: Salesforce Field Service (FSL) license required
  - Integrated Care Management: FHIR R4-Aligned Data Model setting + Enhanced Care Plans setting in Setup
  - OmniStudio (for Health Assessments): OmniStudio must be separately enabled and licensed
  - Social Determinants: Health Cloud managed package must be installed; Health Cloud Platform permission set license and Health Cloud Social Determinants permission set required
  - Unified Health Scoring: Unified Health Scoring license required
  - Einstein / Assessment Generation: Einstein generative AI capabilities; requires separate license
- **Permission Sets Pattern:** Most domains require domain-specific permission sets in addition to base Health Cloud Foundation and Health Cloud Platform permission sets.

---

## Business APIs Overview

The Health Cloud Business APIs (PDF pp.1771+) are RESTful APIs that wrap complex multi-object healthcare business logic into single API calls. Key characteristics:

- Most APIs are RESTful; a few are also available as Apex classes and methods
- They encapsulate business logic such as enrolling patients into care programs or creating prior authorization requests
- Callers are not required to understand the underlying healthcare data model
- They are the recommended approach for integration layers and custom UI components

**Source:** PDF p.5 — "The APIs wrap complex business logic by executing multiple tasks within a single API call. They aim to fulfill business use cases specific to the healthcare industry, such as enrolling patients into a care program or creating requests for prior authorizations."

---

## Tooling API and Developer Tools

The Tooling API (PDF pp.2112-2163) exposes Health Cloud metadata used in developer tooling, accessible through REST or SOAP. Tooling API SOQL capabilities allow retrieval of smaller pieces of metadata for development tooling purposes.

---

## Release History

| Release | Date | Key Items |
|---|---|---|
| Spring '26 | April 27, 2026 | Current release of this guide. API v66.0 context (Book/Cancel/Update Appointment actions at v65.0+). Disease Surveillance at API v64.0. |
| Various | Prior releases | Social Determinants available from API v45.0; Integrated Care Management ICM; FHIR R4-Aligned Data Model; Spring '21 CodeSet/CodeSetBundle replacing HealthcareProcedure/HealthcareDiagnosis |

**Source:** PDF p.1 — "Salesforce Health Cloud Developer Guide, Salesforce, Spring '26, Last updated: April 27, 2026."
