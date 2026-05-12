---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: overview
last-updated: 2026-05-11
---

# Life Sciences Cloud — Overview

## What It Is

Life Sciences Cloud (LSC) is Salesforce's end-to-end, purpose-built platform for the life sciences industry, spanning clinical to medical to commercial domains. It extends the Salesforce platform with objects, APIs, and compliance capabilities for pharmaceutical, biotech, and medical device companies — covering HCP (Healthcare Practitioner) engagement, clinical trial management, patient support programs, and MedTech commercial operations.

This guide is sourced from the Life Sciences Cloud Developer Guide, Version 66.0, Spring '26.

## Four Core Engagement Domains

### 1. Clinical Engagement
Objects and data models for clinical trial management, adverse event tracking, site and participant management, and research study operations.

Key feature areas:
- **Adverse Events** — track and report unintended effects on research participants (API v61.0+)
- **Site Management** — manage clinical trial sites including investigator tracking (CareProviderSearchableField, CareSiteIstgrSearchableFld)
- **Participant Management** — Subject, SubjectAssignment, ResearchStudy, ResearchStudyCandidate, ResearchStudyCmprGroup
- **Randomization** — ResearchStudyRndmBlockSlot, RsrchStdyRandomizationBlock, RsrchStdyRandomizationCrit
- **Sprint Management** — Sprint object for trial phase tracking

### 2. Customer Engagement (LS C4CE — Life Sciences Cloud for Customer Engagement)
Objects and data models for commercial field operations — HCP and HCO engagement, territory management, sample management, visit planning.

Key feature areas:
- **Account Plan / Key Account Management** — AccountPlan, AccountPlanParticipant, AccountPlanProduct, AccountPlanRelationship, AccountPlanStakeholder (API v65.0+)
- **Visit Management** — ProviderVisit, ProviderVisitProdDetailing, Visit; face-to-face, phone, remote channels
- **Samples Management** — track pharmaceutical sample inventory, distribution, and e-signature receipt
- **Sample Inventory Management** — InventoryCountAssessment, InventoryOperation (API v65.0+)
- **Product Territory Management** — ProductTerrDtlAvailability, ProductTerritoryAvailability, ProviderAcctTerritoryInfo
- **Territory Management** — built on Salesforce Enterprise Territory Management; Territory Alignment, Territory Content Template Assignment, Territory User Downtime
- **Next Best Intelligence (AI)** — Next Best Customer, Next Best Action, Next Best Message (AI-driven recommendations; requires enableNextBestAction / enableNextBestCustomer / enableNextBestMessage in IndustriesSettings)
- **Medical Inquiries** — capture questions from healthcare professionals; MedicalInquiry, MedicalInquiryInteraction
- **Consent Management** — CommSubscription, CommSubscriptionConsent, ContactPointConsent, DataUsePurpose (API v65.0+)
- **Segmentation** — LifeScienceAccountList, LifeSciAcctListFilterCrit, LifeSciAcctGrpAssignment; static and dynamic segmentation
- **Data Change Requests** — LifeSciDataChangeDef, LifeSciDataChangeRequest; configurable data validation workflows
- **Field Email** — LifeSciEmailTemplate, LifeSciEmailTmplFragment; streamlines email creation for field teams
- **Mobile Sync** — DeviceSyncSummary, DeviceSyncTransaction, DeviceSyncTransactionLog (API v65.0+); offline capability
- **Actionable Lists** — ActionableList, ActionableListFilterCriteria (API v65.0+)
- **Activity Plans** — ActivityPlan, ActivityPlanTerritory (API v65.0+)
- **Compliance** — ComplianceStatementDef; digital signature capture (DigitalSignature, DigitalVerification)

### 3. Patient Engagement
Objects for patient support programs, care management, clinical data model, and financial assistance.

Key feature areas:
- **Care Program Management** — CareProgram, CareProgramEnrollee, CareProgramProduct, CareProgramProvider, CareProgramSite (API v61.0+)
- **Advanced Therapy Management** — Multi-Step Scheduling for complex procedures (apheresis → manufacturing → infusion); ServiceAppointmentGroup, ServiceTerritoryRelationship; powered by Salesforce Scheduler; requires Multi-Step Scheduling permission set and Asset Scheduler Add-On license
- **Clinical Data Model** — FHIR R4-aligned; enabled via "FHIR R4 Support Settings" org pref; AllergyIntolerance, ClinicalEncounter, DiagnosticSummary, HealthCondition, MedicationRequest, PatientImmunization, PatientMedicalProcedure
- **Financial Assistance Program** — Benefit, BenefitType, ProgramEnrollment, EnrollmentEligibilityCriteria; ApplnFormAppealStsChgEvnt platform event (API v63.0)
- **Health Insurance** — CoverageBenefit, CoverageBenefitItem, MemberPlan, CarePreauth, CarePreauthItem
- **Pharmacy Benefits Verification** — FHIR-CARIN and NCPDP aligned; CareBnftVrfyRqstStsChgEvent platform event (API v65.0)
- **Social Determinants** — CareBarrier, CareDeterminant, CareInterventionType (API v45.0+)
- **Electronic Signatures** — DigitalVerification, DigitalVerfSetupDetail, DigitalVerificationSetup
- **Intelligent Document Automation** — DocumentTemplate, LifeSciDocTemplateVersion; patient form management
- **Patient Program Outcome Management** — Outcome, OutcomeActivity; program and patient outcome summaries
- **Provider Relationship Management** — HealthcareProvider, HealthcareFacility, ProviderAffiliation, CareSpecialty

### 4. MedTech Commercial Engagement
Objects for medical device companies — field sales, device tracking, serialized product management.

Key feature areas:
- **Product and Inventory** — SerializedProduct, InventoryOperation, InventoryCountAssessment
- **Work Order Management** — WorkTypeStep, WorkTypeStepLdTimeOvride, WorkTypeSvcTerrSchdPrio
- Integrated with Salesforce Field Service (FSL)

---

## Editions and Licensing

- **Available in:** Enterprise and Unlimited Editions
- Life Sciences Cloud is a separate license add-on; does NOT include a base Sales/Service Cloud license in every bundle — confirm with customer's contract
- Feature-level enablement via `IndustriesSettings` metadata (see metadata-tooling.md)
- Some features require additional permission sets: Multi-Step Scheduling, FHIR R4 for Experience Cloud Sites, Health Cloud Starter (for Life Sciences Cloud)
- **Apex namespaces:** No single managed package namespace — LSC uses standard Salesforce objects with LSC-specific fields; some older orgs may have `HealthCloudGA` namespace from Health Cloud overlap

---

## Key Terminology

| Term | Definition |
|---|---|
| **HCP** | Healthcare Practitioner — physician, nurse practitioner, etc. |
| **HCO** | Healthcare Organization — hospital, clinic, pharmacy |
| **KOL** | Key Opinion Leader — high-influence HCP targeted for medical education |
| **FHIR R4** | Fast Health Interoperability Resources v4.0 — HL7 standard for EHR exchange; LSC Clinical Data Model is built to align with it |
| **HL7 v2.3** | Older HL7 message standard; also supported via LSC Clinical Data Model |
| **CARIN** | Consumer-directed payer data exchange standard; used in Pharmacy Benefits Verification |
| **NCPDP** | National Council for Prescription Drug Programs; standard for pharmacy benefits |
| **Advanced Therapy** | Cell and gene therapy requiring multi-step scheduling across sites |
| **LS C4CE** | Life Sciences Cloud for Customer Engagement — the commercial module |
| **PATS** | Provider and Affiliate Tracking System — territory-based sharing mechanism |
| **DataPack** | OmniStudio IDX Workbench unit for deploying LSC configuration |
| **CodeSet** | Standard object representing industry codes (ICD, SNOMED, NDC, etc.) |
| **CodeSetBundle** | Groups of CodeSets across multiple coding systems |

---

## Compliance Context

| Regulation | Requirement | LSC Feature |
|---|---|---|
| **Sunshine Act / Open Payments (US)** | Track transfers of value (meals, speaker fees, consulting) to HCPs; report annually to CMS | Transfer of Value tracking via Visit Management and Interaction records |
| **GDPR / CCPA** | HCP consent for commercial communications must be captured, stored, and honored | CommSubscription, CommSubscriptionConsent, ContactPointConsent |
| **21 CFR Part 11 / Annex 11** | Electronic records and e-signatures in clinical context must meet FDA/EMA standards | DigitalVerification, DigitalVerificationSetup; confirm Part 11 requirements before go-live |
| **HIPAA (if PHI involved)** | Patient health information must be protected; Business Associate Agreement required | Compliant Data Sharing + standard Salesforce encryption; evaluate with customer's legal team |
| **Sample Accountability (US)** | Pharmaceutical sample distribution to HCPs must be recorded and e-signed | Sample Management + DigitalSignature |

---

## When to Use Life Sciences Cloud

| Use Case | LSC Feature |
|---|---|
| Pharma/biotech medical rep CRM — visit reporting, detailing, speaker programs | Customer Engagement (LS C4CE) |
| Medical device field sales with clinical support | MedTech Commercial Engagement |
| Medical information (MI) request management | Medical Inquiries |
| Sample management and e-signature | Samples Management + DigitalVerification |
| KOL management and medical education tracking | Account Plan (Key Account Management) |
| Consent management for HCP marketing (GDPR/CCPA) | Consent Management objects |
| Clinical trial management and participant tracking | Clinical Engagement domain |
| Patient support program enrollment and management | Patient Engagement / Care Program Management |
| Financial assistance for patients | Financial Assistance Program |
| Advanced cell/gene therapy scheduling | Advanced Therapy Management |
| Pharmacy benefits verification | Pharmacy Benefits Verification |

---

## When NOT to Use Life Sciences Cloud

| Need | Use Instead |
|---|---|
| Patient-facing consumer portal | Health Cloud (or Life Sciences + Experience Cloud) |
| Pure commercial CRM without regulated features | Sales Cloud |
| Adverse event pharmacovigilance system | Veeva Vault Safety or dedicated PVMS |
| Clinical data warehouse / analytical layer | External system + MuleSoft |
| EHR / EMR primary system | External EHR (Epic, Cerner) + LSC integration |

---

## Release History

| Feature | Release | Notes |
|---|---|---|
| Actionable List, BatchJob, DeviceSync objects | API v65.0 (Spring '26) | New Customer Engagement objects |
| CareProgramSite, CareProgramSiteContract | API v61.0-62.0 | Patient Engagement additions |
| Adverse Events, Clinical Trial Management | API v61.0 | enableAdverseEvents, enableLifeSciencesClinialTrailManagement |
| ActionableListDefinition metadata | API v57.0+ | Customer Engagement metadata type |
| Referral (LSC-specific) | API v66.0 | Not in standard FSC; verify namespace |
| Activity Plan, AccountPlan family | API v65.0 | Key Account Management |
| ResearchStudy Randomization | API v61.0+ | Clinical trial randomization blocks |
