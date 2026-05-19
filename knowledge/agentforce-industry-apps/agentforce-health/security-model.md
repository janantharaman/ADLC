---
source: Salesforce Health Cloud Developer Guide (health_cloud_dev_guide.pdf, 2300p); Spring '26; grounded 2026-05-11
cloud: Health Cloud
section: security-model
last-updated: 2026-05-11
---

# Health Cloud — Security Model

## HIPAA Compliance Context

Health Cloud is designed to store Protected Health Information (PHI) — which under HIPAA encompasses all individually identifiable health information. Salesforce provides a HIPAA-covered environment under a Business Associate Agreement (BAA), but the BAA must be signed before any PHI is loaded into the org. This is a pre-implementation legal step, not a technical one.

**Key HIPAA implications for Salesforce configuration:**

1. **Org-Wide Defaults (OWD)** — Most health objects must be set to Private. HIPAA's Minimum Necessary standard requires that users access only the PHI required for their job function.
2. **Field-Level Security** — All PHI fields must have FLS configured so that only authorized roles can read or edit them. HIPAA requires this even when record-level access is already controlled.
3. **Audit Trail** — Every PHI access should be auditable. Salesforce Event Monitoring (and ideally Salesforce Shield) should be enabled to log field access, report exports, and API calls on PHI fields.
4. **Encryption at Rest** — Shield Platform Encryption is recommended for PHI fields. Encrypt fields storing name, date of birth, diagnosis codes, medical record numbers, and any sensitive clinical data.
5. **Data Residency** — Confirm with the customer whether data residency requirements apply (e.g., EU data residency for GDPR-covered EU health data, or government cloud for US federal healthcare).

---

## OWD Recommendations

The following table reflects standard Health Cloud security posture. Deviations require documented justification.

| Object | Recommended OWD (Internal) | Recommended OWD (External / Guest) | Reasoning |
|---|---|---|---|
| Account (Patient/Member) | **Private** | **Private** | Core PHI container; care team access only; never expose to guest users |
| CarePlan | **Controlled by Parent** | **Private** | Inherits patient Account sharing; ICM CarePlan follows same model |
| CarePlanDetail / CarePlanActivity | **Controlled by Parent** | **Private** | Cascade from CarePlan |
| ClinicalEncounter | **Controlled by Parent** | **Private** | Inherits from patient Account |
| CareObservation | **Controlled by Parent (API v56.0+) / Private** | **Private** | Clinical readings; inherits patient sharing where supported; otherwise Private |
| CareBenefitVerifyRequest | **Private** | **Private** | Benefits data; member services + clinical access only |
| CareRequest (UM) | **Private** | **Private** | Utilization Management; UM team + requesting provider only |
| CareDiagnosis | **Controlled by Parent** | **Private** | Inherits from CareRequest |
| CoverageBenefit | **Private** | **Private** | Coverage data; member services team only |
| CareBarrier (SDOH) | **Controlled by Parent** | **Private** | Sensitive social data; care coordinators and social workers |
| CareProgramEnrollee | **Private** | **Private** | Program enrollment data tied to patient PHI |
| CareProgram | **Public Read Only** | **Private** | Program definitions are typically not PHI; individual enrollment is |
| CareFacilityBed | **Public Read Only** | **Private** | Bed availability is operational; not PHI |
| DiseaseDefinition | **Public Read Only** | **Private** | Disease definitions are reference data |
| DiseaseInvestigation | **Private** | **Private** | Public health investigation data; restricted access |

**Guest User Rule:** Health data must never be accessible to guest users. No public Salesforce sites should expose Health Cloud PHI objects. This is a hard security requirement.

---

## Permission Set Architecture

Health Cloud permissions are layered. Every user needs the base Health Cloud licenses plus domain-specific permission sets.

### Base Permission Sets (all Health Cloud users)
- `Health Cloud Foundation` — base Health Cloud object access
- `Health Cloud Platform` — platform-level Health Cloud access

### Domain-Specific Permission Sets

| Permission Set | Role | Key Access |
|---|---|---|
| `Health Cloud Care Coordinator` | Care managers, care coordinators, social workers | CRUD on CarePlan, CareProgramEnrollee, CareBarrier, CareDeterminant; Read/Create on ClinicalEncounter; Read on CareObservation |
| `Health Cloud Clinical User` | Physicians, nurses, clinicians | CRUD on CareObservation, ClinicalEncounter; Read/Create on MedicationRequest; Read on CarePlan |
| `Health Cloud Utilization Management` | UM reviewers, prior auth staff | CRUD on CareRequest, CareDiagnosis, CareRequestItem; Read on CarePlan; no SDOH access (Minimum Necessary) |
| `Health Cloud Member Services` | Payer member services agents | Read on CareProgramEnrollee, CoverageBenefit; Create/Read on Case; no clinical data |
| `Health Cloud Benefits Verification` | Benefits verification staff | CRUD on CareBenefitVerifyRequest, CoverageBenefit, CoverageBenefitItem |
| `Health Cloud Social Determinants` | SDOH-enabled care staff | Read/Write on CareBarrier, CareDeterminant, CareInterventionType |
| `Hls Clinical Decision Support` | CRD/DTR users | Coverage Requirement Discovery and Documentation Templates objects |
| `Health Cloud Crisis Support Center Management App` | Crisis center staff | CareFacilityBed; crisis intake objects |
| `Health Cloud Starter` | Life Sciences base users | Various Life Sciences / pharma objects |
| `Manage Pharmacy Benefits Verification` | Pharmacy benefits staff | CareBnftVrfyRqstStsChgEvent platform event subscription |
| `Multi-Step Scheduling` | Advanced Therapy coordinators | WorkProcedure, WorkTypeStep, ServiceAppointmentGroup, ServiceTerritoryRelationship |

---

## Sharing Model for Care Teams

The primary access mechanism in Health Cloud is care team membership. A care team connects Users (or Contact records representing external providers) to a patient's records.

### How Care Team Sharing Works

1. A `CareTeamMember` (or `CareProgramTeamMember`) record is created, linking a User to a patient's CareProgram or CarePlan.
2. An `AccountShare` record must be created (via Apex Managed Sharing) granting the care team member Read or Edit access to the patient's Account record.
3. All child objects set to "Controlled by Parent" inherit access automatically once the Account share exists.
4. When a care team member is removed, the `AccountShare` must be deleted. This requires a separate Apex trigger on the delete event of the CareTeamMember/CareProgramTeamMember object.

**Critical:** Care team sharing requires Apex Managed Sharing. There is no declarative sharing rule that can evaluate "is this User a CareTeamMember for this specific patient?" Standard sharing rules cannot express record-specific conditions of this type.

**Forgetting the delete trigger** is the most common security defect in Health Cloud implementations: former care team members retain access to patient records indefinitely until the AccountShare is explicitly removed.

### Sharing Objects Involved
- `AccountShare` — row-level share on the patient Account (RowCause = 'Manual' for Apex Managed Sharing)
- `CareObservationShare` — available for CareObservation (API v56.0+) when not using Controlled by Parent
- `CoverageBenefitShare` — for CoverageBenefit records
- `CareObservationOwnerSharingRule` — for OWD-based sharing rules on CareObservation
- Domain-specific `*Share` and `*OwnerSharingRule` objects exist for most Health Cloud objects (listed in Associated Objects sections)

---

## Guest User Restrictions

Health data must never be accessible to guest users (unauthenticated Experience Cloud visitors):

- All Health Cloud PHI objects must have External OWD = **Private**
- No public Salesforce Sites should use Health Cloud objects in their page layouts, SOQL queries, or Apex
- Guest user profile must not include any Health Cloud permission sets
- If patient self-service portal is required, use **authenticated Experience Cloud** with a Community User license, not a guest user configuration

---

## Data Residency and Encryption

### Shield Platform Encryption — Recommended Fields
Encrypt PHI fields to meet HIPAA administrative safeguards and protect against unauthorized database-level access:

| Object | Fields to Encrypt |
|---|---|
| Account (Person Account) | FirstName, LastName, BirthDate, Email, Phone, MobilePhone |
| ClinicalEncounter | (diagnosis-related fields, provider notes if stored) |
| CareObservation | ObservationValue fields |
| MedicationRequest | (drug name, dosage fields) |
| CareRequest | (member details, clinical notes) |
| AllergyIntolerance | (allergy code, reaction details) |

**Note:** Shield Platform Encryption affects SOQL queries (encrypted fields cannot be used in WHERE clauses by default without deterministic encryption). Plan encryption strategy during discovery — it affects query patterns throughout the implementation.

**Event Monitoring** (Salesforce Shield add-on): Required for PHI access audit trails. Log types to enable: ReportEvent, ListViewEvent, ApiTotalUsage, FieldAccessEvent (on PHI fields).

---

## Consent Management

**Source:** PDF p.7 — "Manage electronic signatures by using Digital Verifications. Set up signature trails for records or workflows that require users to verify key updates."

Health Cloud provides Electronic Signatures via the Digital Verifications feature:
- Define signature trails for records or workflows requiring user verification
- Configure order of designated verifiers
- Designate verifiers by user group or participant role
- Platform event `ApplnFormAppealStsChgEvnt` fires on Financial Assistance Program appeal status changes (API v63.0+)

**For 42 CFR Part 2 (US Substance Use Disorder consent):**
- SUD records require patient-specific, purpose-specific consent for each disclosure
- Generic HIPAA consent does not satisfy 42 CFR Part 2
- Implement a separate consent workflow with a distinct consent record type
- Restrict SUD-related CareObservations / ClinicalEncounters via a sensitivity flag and Apex Managed Sharing that grants access only to the treating provider

---

## External User Access (Experience Cloud Patient Portal)

If the engagement includes a patient self-service portal:

1. **License type:** Authenticated Experience Cloud user license (Partner Community or Customer Community Plus for PHI access with sharing)
2. **OWD:** External OWD on Account, CarePlan, CareObservation must be **Private**
3. **Sharing Set:** Grant the authenticated patient user Read access to their own records by scoping the Sharing Set: `$User.ContactId = Account.PersonContactId`
4. **Person Account model:** The portal user's Contact must match the patient's `Account.PersonContactId`
5. **Sensitive records:** 42 CFR Part 2 SUD records must never be exposed in the patient portal without explicit, separate consent configuration
6. **Guest user:** Must be disabled or have no access to Health Cloud objects

### Community License Considerations
- Customer Community Plus license is required if the patient needs to edit their own records (not just read)
- Customer Community license (read-only) is acceptable for view-only patient portals
- Each authenticated portal user consumes a Community User license seat

---

## Role Hierarchy Considerations

Health Cloud data access depends on the Salesforce Role Hierarchy when OWD is Private:
- Care coordinators, clinical staff, and UM reviewers should be at the same or lower level than patient record owners
- Do not use Role Hierarchy to grant broad cross-patient access; use care team sharing (Apex Managed Sharing) instead
- Supervisors who need to audit care team actions may be granted access via a separate Permission Set + Sharing Rule on non-PHI summary data rather than direct record access

---

## Sensitivity Restrictions (42 CFR Part 2 and Mental Health)

Mental health and substance use disorder (SUD) records have heightened legal protections under US 42 CFR Part 2 (SUD) and HITECH (mental health). These cannot be disclosed without specific patient consent per disclosure:

**Implementation approach:**
1. Add `IsSensitive__c` boolean flag to CareObservation and ClinicalEncounter
2. Apex Managed Sharing: sensitive records are accessible only to the `TreatingProvider__c` on the record — NOT the general care team
3. Validation rule blocking bulk export of records where `IsSensitive__c = true`
4. The patient portal must never expose sensitive records without explicit consent tracking
5. Document the implementation approach in the Security Design artifact for the engagement
