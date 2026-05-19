---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Health Cloud — Implementation Guide

## Prerequisites

Before beginning any Health Cloud implementation, verify all of the following are in place:

### License Requirements
| Requirement | Details | Who Confirms |
|---|---|---|
| **Health Cloud License** | Enterprise or Unlimited Edition with Health Cloud license applied | Salesforce AE / Customer IT |
| **Lightning Experience** | Lightning Experience must be enabled; Classic is not supported | Salesforce Admin |
| **OmniStudio License** | Required for Health Assessments, Discovery Framework, guided care workflows | Customer Procurement |
| **FSL License** | Required for Home Health domain | Customer Procurement |
| **Healthcare API License** | Required for FHIR R4 bidirectional API endpoints (not included in base HC) | Customer Procurement |
| **Einstein License** | Required for Assessment Generation (AI-powered question creation) | Customer Procurement |
| **Unified Health Scoring License** | Required for Unified Health Scoring feature | Customer Procurement |
| **Asset Scheduler Add-On** | Required for Advanced Therapy Management (assets at service territories) | Customer Procurement |
| **Multi-Step Scheduling Permission Set License** | Required for Advanced Therapy Management | Customer Admin |
| **HIPAA BAA** | Signed Business Associate Agreement between customer and Salesforce must exist before any PHI is stored | Legal |

### Technical Prerequisites
- Salesforce org on API version 56.0 or higher is strongly recommended (many features require v58.0, v64.0, v65.0+)
- Person Accounts: confirm whether the org uses or should use Person Accounts for patients/members (irreversible decision)
- Existing data: document current clinical/member data sources and migration plan before go-live
- MuleSoft: if EHR/HL7/FHIR integration is in scope, MuleSoft must be planned as part of the architecture from day one

---

## Feature Activation Sequence

Features should be activated in this general order to avoid dependency failures. Always test activation in a Sandbox first.

```
1. Enable Lightning Experience (if not already enabled)
2. Enable Person Accounts (if using person-centric model for patients)
   → Irreversible. Plan carefully.
3. Assign Health Cloud base permission sets to Health Cloud admin users:
   - Health Cloud Foundation
   - Health Cloud Platform
4. Assign domain-specific permission set licenses and permission sets per role
5. Activate domain features in Setup as required:
   a. Home Health:
      - Enable Home Health in Setup
      - Configure Salesforce Field Service (service territories, resources, etc.)
   b. Integrated Care Management:
      - Enable FHIR R4-Aligned Data Model on FHIR R4 Support Settings page
      - Enable Enhanced Care Plans on Integrated Care Management Settings page
   c. Disease Surveillance:
      - Enable on Public Health Settings page
   d. Social Determinants:
      - Install Health Cloud managed package (if not already installed)
      - Assign Health Cloud Social Determinants permission set to appropriate users
   e. OmniStudio (for Health Assessments / Discovery Framework):
      - Enable OmniStudio in Setup
      - Configure OmniStudio deployment pipeline (separate from standard metadata)
   f. FHIR APIs:
      - Activate Healthcare API feature (requires Healthcare API license)
      - Configure FHIR server settings
   g. Crisis Support Center:
      - Assign Health Cloud Crisis Support Center Management App permission set
      - Assign Crisis Support Center Management permission set license
   h. Advanced Therapy Management:
      - Enable Multi-Step Scheduling (permission set)
      - Configure Asset Scheduler Add-On
   i. Disease Surveillance:
      - Enable in Public Health Settings; requires API v64.0+
6. Configure Shield Platform Encryption (if required for HIPAA PHI protection)
7. Configure Salesforce Event Monitoring (for PHI access audit trails)
```

---

## Care Program Setup Sequence

### Step 1: Configure CareProgram Records
```
1. Navigate to: Health Cloud Setup → Care Programs (or use the CareProgram object directly)
2. Create CareProgram records for each program type:
   - Name: descriptive program name (e.g., "Type 2 Diabetes Management Program")
   - Category: appropriate program category
   - Status: Active
   - StartDate: program launch date
3. Configure CareProgramProduct records if products/services are associated with the program
4. Configure CareProgramSite records if Site Management is enabled (API v64.0+)
```

### Step 2: Configure CareProgramEnrollee Status Picklist
```
1. Navigate to: Setup → Object Manager → CareProgramEnrollee → Fields & Relationships → Status
2. Review existing picklist values
3. Add or configure values per business requirements
4. CRITICAL: Document valid status transitions — cannot skip states
5. Add validation rules if needed to enforce transition logic
6. Test all transitions before go-live
```

### Step 3: Assign Permission Sets by Role
```
All users need:
  - Health Cloud Foundation permission set
  - Health Cloud Platform permission set license

By role, additionally assign:
  - Care Coordinators: [domain-specific coordinator permission set]
  - Clinical Staff: [clinical user permission set]
  - UM Reviewers: [utilization management permission set]
  - Member Services: [member services permission set]
  - Benefits Verification Staff: Benefits Verification permission set
```

### Step 4: Configure Care Team Member Roles
```
1. Configure CareTeamMember or CareProgramTeamMember role picklist values
2. Build Apex Managed Sharing triggers:
   a. CareTeamMember INSERT trigger → create AccountShare
   b. CareTeamMember DELETE trigger → delete AccountShare (critical — do not skip)
3. Test sharing: verify care team member can access patient record
4. Test delete: verify access is removed when team member removed
```

### Step 5: Configure OWD and Role Hierarchy
```
1. Set Account (Patient) OWD = Private (Internal and External)
2. Set CarePlan, ClinicalEncounter, CareObservation to Controlled by Parent or Private
3. Set CareRequest (UM) to Private
4. Set CareBenefitVerifyRequest to Private
5. Configure Role Hierarchy so UM reviewers and care coordinators are at appropriate levels
6. Verify no over-sharing occurs through role hierarchy above Private OWD objects
```

---

## Clinical Data Model Setup

### CodeSet and CodeSetBundle Configuration

CodeSets are reference data records — they are typically loaded from standard clinical terminologies:

```
1. Load CodeSet records for required code systems:
   - ICD-10-CM (diagnoses)
   - CPT (procedures)
   - SNOMED CT (clinical concepts)
   - LOINC (lab and clinical observations)
   - HCPCS (procedures/equipment for Medicare/payer use)
   - NDC (National Drug Codes for pharmacy)
   - RxNorm (medications)

2. Loading options:
   a. Bulk load via Data Import Wizard or Data Loader (CSV from code authority sources)
   b. MuleSoft integration with a clinical terminology service (NLM VSAC, etc.)
   c. Pre-populated seed data from Health Cloud package (if included)

3. Create CodeSetBundle records to group related codes:
   - Each CodeSetBundle can reference up to 15 CodeSet records (CodeSet1Id through CodeSet15Id)
   - Create bundles for common code groupings (e.g., "Diabetes ICD-10 Codes")

4. Verify deprecation:
   - Confirm no existing code references HealthcareProcedure or HealthcareDiagnosis
   - Update any existing SOQL, reports, or integrations to use CodeSet/CodeSetBundle
```

### Clinical Data Activation Steps

```
1. Confirm FHIR R4-Aligned Data Model is enabled (for ICM objects)
2. Configure PersonName records — set up FullName format per org requirements
3. Configure ContactPointAddress — verify Address field mapping from FHIR Address resource
4. Configure Identifier records for patient MRN, NPI, and other external identifiers
5. Configure UnitofMeasure reference records (required for Quantity and Range field support)
6. Test ClinicalEncounter creation and verify ClinicalEncounterDiagnosis links correctly
7. Test CareObservation creation with CareObservationComponent for compound measurements
```

---

## Integrated Care Management Setup

### ICM Feature Activation
```
1. Navigate to Setup → FHIR R4 Support Settings
   → Enable: FHIR R4-Aligned Data Model
2. Navigate to Setup → Integrated Care Management Settings
   → Enable: Enhanced Care Plans
3. Verify objects are accessible: CarePlan, CarePlanDetail, CarePlanActivity,
   CarePlanActivityDetail, GoalAssignment, GoalAssignmentDetail,
   CareEpisode, CareEpisodeDetail, ProblemDefinition
```

### Care Plan Template Configuration
```
1. Create ProblemDefinition records for common clinical problems
   (e.g., "Type 2 Diabetes", "Heart Failure", "Hypertension")
2. Create ActionPlanTemplateAssignment records to associate action plan templates
   with problems and goals
3. Configure AsmtQstnRespRecommendation records to map assessment responses
   to care plan recommendations (problems, goals, interventions)
4. Test: complete an assessment → verify recommendation-based care plan items are created
```

### Consent Framework Setup
```
1. Configure Electronic Signatures / Digital Verifications:
   Navigate to Setup → Digital Verifications
2. Define signature trails for care consent workflows
3. Configure verifier order and verifier groups
4. For 42 CFR Part 2 (SUD consent): set up separate consent workflow with
   distinct consent record type and IsSensitive__c flag logic
5. Test consent capture and verify audit trail in Digital Verifications records
```

---

## OmniStudio + Health Assessments Setup

**Critical prerequisite:** OmniStudio must be enabled before Health Assessments can function.

### OmniStudio Enablement
```
1. Verify OmniStudio license is purchased
2. Navigate to Setup → OmniStudio Settings → Enable OmniStudio
3. Install OmniStudio package (if using managed package version)
4. Configure OmniStudio DataPack deployment toolchain:
   - Install SF CLI with vlocity or OmniStudio extensions
   - Set up OmniStudio-specific CI/CD pipeline separate from standard metadata deployment
5. Verify OmniStudio user permissions (OmniStudio User or OmniStudio Admin profile/perm set)
```

### AssessmentQuestion Setup
```
1. Create AssessmentDefinition records for each assessment type
2. Create AssessmentQuestion records linked to the AssessmentDefinition
3. Create AssessmentQuestionVersion records (version management for question updates)
4. Configure AssessmentIndicatorDefinition records to define scoring logic
5. Create AsmtQstnRespRecommendation mappings for care plan recommendation triggers
```

### Discovery Framework Configuration
```
1. Build OmniScripts for each assessment delivery workflow:
   - Use DataRaptor (Extract) to load AssessmentQuestion records
   - Capture responses via OmniScript UI components
   - Use DataRaptor (Transform / Load) to save AssessmentQuestionResponse records
2. Build Integration Procedures for scoring logic:
   - Load AssessmentIndicatorDefinition records
   - Evaluate response scores against thresholds
   - Return care plan recommendations
3. Test full assessment flow: initiation → questionnaire → responses → scoring → care plan actions
```

---

## EHR / HL7 Integration Setup

### MuleSoft Direct Integration (Recommended Approach)
```
1. Confirm MuleSoft license is available
2. Retrieve pre-built integration templates from MuleSoft Exchange:
   - Health Cloud for Epic integration app
   - Health Cloud for Cerner integration app
   - (Other EHR-specific templates as available)
3. Configure MuleSoft connection to EHR system:
   - HL7 v2.x inbound listener (receive ADT, ORU, ORM messages)
   - FHIR R4 client (if EHR supports FHIR endpoint)
4. Configure field mappings in MuleSoft (or customize pre-built mappings):
   - PID segment → Account (PersonName, ContactPointAddress)
   - PV1 segment → ClinicalEncounter
   - DG1 segment → ClinicalEncounterDiagnosis (ICD-10 → CodeSet)
   - OBX segment → CareObservation + CareObservationComponent (LOINC → CodeSet)
   - AL1 segment → AllergyIntolerance
5. Configure error handling and retry logic for failed messages
6. Set up monitoring and alerting for integration failures
```

### Custom Apex HL7 Parser (Alternative)
```
1. If MuleSoft is not available, implement a custom Apex HL7 parser:
   - Use a third-party Apex HL7 library or hand-roll segment parsing
   - Build Apex REST endpoint to receive HL7 messages from the EHR interface engine
   - Parse segments into POJO representations
   - Map to Health Cloud objects using the FHIR mapping table
2. Handle HL7 acknowledgement (ACK) messages back to the EHR
3. Implement error handling: if parsing fails, write to a HL7ErrorLog__c object
   for manual review
4. Key limitation: custom Apex parsers are harder to maintain as EHR message
   structures evolve — MuleSoft is preferred for long-term maintainability
```

### FHIR API Activation Steps
```
1. Verify Healthcare API license is active on the org
2. Navigate to Setup → Healthcare API Settings (exact name may vary by release)
   → Enable Healthcare API
3. Configure FHIR server settings:
   - Set the FHIR base URL
   - Configure authentication (OAuth2)
4. Test FHIR endpoint access:
   GET /services/data/vXX.X/connect/health/fhir/r4/Patient?identifier=[test-id]
5. Configure FHIR Subscription if real-time notifications to external systems are needed:
   → Create InteropTopic records
   → Create InteropTopicSubscription records
   → Configure MuleSoft as the notification delivery layer
```

---

## Deployment Considerations

### Metadata Deployment Order for Health Cloud Components

Health Cloud metadata has dependencies. Deploy in this order to avoid failures:

```
Tier 1 — Core Platform Setup (no HC dependencies)
  - Custom fields on standard objects (Account, Contact, Lead, Opportunity)
  - Custom objects (any non-HC custom objects needed by the implementation)
  - Record Types
  - Page Layouts
  - Custom Labels
  - Custom Metadata Types

Tier 2 — Health Cloud Metadata Types
  - CareBenefitVerifySettings (.careBenefitVerifySettings)
  - CareLimitType
  - CareRequestConfiguration (.careRequestConfiguration)
  - CareSystemFieldMapping (.careSystemFieldMapping)
  - CareProviderSearchConfig
  - IndustriesSettings (Health Cloud settings)
  - IdentityVerificationProcDef + IdentityVerificationProcDtl + IdentityVerificationProcFld
  - ScoreCategory (Unified Health Scoring)
  - Icon (.icon)
  - TimelineObjectDefinition
  - UIObjectRelationConfig
  - VirtualVisitConfig

Tier 3 — Flow and Automation
  - Flows (Record-Triggered, Screen, Scheduled)
  - Flow for Health Cloud metadata type (use HealthCloudFlow record type in Flow metadata)
  - Apex Classes and Apex Triggers
  - Custom Notifications
  - Permission Sets and Permission Set Groups

Tier 4 — OmniStudio Components (separate pipeline)
  - OmniScripts (deployed via OmniStudio DataPacks)
  - Integration Procedures
  - DataRaptors
  - FlexCards
  NOTE: OmniStudio components do NOT deploy via sf project deploy start.
  Use the vlocity/OmniStudio CLI toolchain.

Tier 5 — Reference Data (Data Load)
  - CodeSet records (ICD-10, CPT, SNOMED, LOINC, NDC, RxNorm)
  - CodeSetBundle records
  - CareProgram records
  - HealthcareFacility records
  - AssessmentDefinition + AssessmentQuestion + AssessmentQuestionVersion records
```

### Change Set Limitations

When using Change Sets (instead of Metadata API / DX):
- Health Cloud-specific metadata types (CareRequestConfiguration, CareSystemFieldMapping, etc.) may not be available in Change Set component picker in all versions
- OmniStudio components cannot be deployed via Change Sets — always use DataPack toolchain
- FlexCards and OmniScripts are not in the standard Change Set component list
- Recommendation: Use Salesforce DX (sf CLI with `sf project deploy start`) for Health Cloud implementations rather than Change Sets; source-driven development is strongly preferred

### Sandbox Strategy
```
1. Developer Sandbox or Developer Pro Sandbox for initial development
   → Limitation: no data from production; configure reference data (CodeSet, CareProgram) manually
2. Partial Copy Sandbox for integration testing
   → Use this to test EHR integration and data flows
3. Full Copy Sandbox (or UAT org) for performance testing and UAT
   → Required for population health scenarios; test with realistic patient volumes
4. Production deployment:
   → Always deploy via Change Set or Metadata API (not manually in Setup)
   → Health Cloud Business API calls to production require explicit approval (see CLAUDE.md mutation tool rules)
```

---

## Quick Setup Checklists

### Minimum Viable Setup — Care Program Management
- [ ] Health Cloud Foundation and Platform permission sets assigned
- [ ] CareProgram records created
- [ ] CareProgramEnrollee Status picklist validated
- [ ] OWD: Account = Private
- [ ] Apex Managed Sharing triggers for CareTeamMember (insert + delete)
- [ ] Enrollment Flow or OmniScript built and tested
- [ ] Care coordinator assigned via CareProgramTeamMember

### Minimum Viable Setup — Benefits Verification
- [ ] Benefits Verification permission set assigned
- [ ] CareBenefitVerifySettings metadata type deployed (API v52.0+)
- [ ] Record-Triggered Flow on CareBenefitVerifyRequest configured
- [ ] Platform event subscription for CareBnftVrfyRqstStsChgEvent configured (API v65.0+)
- [ ] OWD: CareBenefitVerifyRequest = Private
- [ ] Tested end-to-end: create request → status change → platform event → record update

### Minimum Viable Setup — Prior Authorization / UM
- [ ] UM permission set assigned to UM reviewers
- [ ] CareRequestConfiguration metadata type deployed
- [ ] CareRequest, CareDiagnosis, CareRequestItem objects accessible
- [ ] UM intake flow or OmniScript built
- [ ] SLA tracking configured (custom or Entitlement Process)
- [ ] Denial notification via TrackedCommunication tested
- [ ] OWD: CareRequest = Private

### Minimum Viable Setup — Home Health
- [ ] FSL license confirmed and FSL enabled
- [ ] Service Territories configured
- [ ] Service Resources configured
- [ ] Scheduling Policies configured
- [ ] Home Health feature enabled in Setup
- [ ] Schedule Recurring Home Visit invocable action tested
- [ ] CareServiceVisit and CareServiceVisitPlan objects accessible
