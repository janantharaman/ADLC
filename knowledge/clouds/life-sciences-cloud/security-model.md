---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: security-model
last-updated: 2026-05-11
---

# Life Sciences Cloud — Security Model

## Special Access Rules by Object (PDF pp.47-68)

Several LSC objects have Special Access Rules that restrict which users can query them. Verify these in the org before building queries.

| Object | Special Access Rule |
|---|---|
| `ApplnFormAppealStsChgEvnt` | Requires: Health Cloud Starter AND Manage Financial Assistance Program permission set |
| `CareBnftVrfyRqstStsChgEvent` | Requires: Manage Pharmacy Benefits Verification AND Health Cloud Starter (LSC) or Health Cloud Foundation (Health Cloud) permission set |
| `CareSystemFieldMapping` | Requires: Health Cloud or Life Sciences Cloud license + Health Cloud Foundation (Health Cloud) or Health Cloud Starter (Life Sciences Cloud) permission set |
| `CareProviderSearchConfig` | Same as CareSystemFieldMapping |
| `SearchResultActionConfig` | Only available if "Criteria-Based Search and Filter" is enabled in org |
| `TimelineObjectDefinition` | Only available in orgs with "Timeline" org preference enabled |
| `UIObjectRelationConfig` | Only available to Health Cloud or Life Sciences Cloud customers |

---

## HCP Data Classification

HCP data is regulated. Apply strict FLS on these fields:

| Field | Classification | Access Restriction |
|---|---|---|
| `NPI__c`, `DEA_Number__c` | Regulated identifier | Rep Read; Compliance Read/Edit; no external sharing |
| `License_Number__c` | Regulated identifier | Same as above |
| Sample transaction records | Audit trail | Rep creates; Read-only after submission; no delete |
| `CommSubscriptionConsent` records | GDPR/CCPA | Rep Read; Compliance team Edit; never delete |
| Medical Inquiry details | Confidential | MSL team only; reps no access |
| TOV (meals, speaker fees) aggregate | Sunshine Act | Finance/Compliance only; reps cannot edit after submission |
| `CareBenefitVerifyRequest` | PHI-adjacent | Requires specific permission set (Manage Pharmacy Benefits Verification) |
| Clinical Data Model objects (`ClinicalEncounter`, `DiagnosticSummary`, etc.) | PHI | FHIR R4 org pref required; restrict via profiles and permission sets |

---

## Sharing Model Considerations

### Account-Based Sharing
- Controlled by `enableAccountBasedSharing` in `IndustriesSettings`
- When enabled: data access is controlled based on account ownership
- Use when HCP/HCO data access should follow account assignment, not user role

### Territory-Based Sharing (PATS)
- Controlled by `enablePATSTerritoryBasedSharing` in `IndustriesSettings`
- Applies to Provider and Affiliate Tracking System
- Shares account-related data with users based on territory alignment
- Territory alignment jobs run to generate ProviderAcctTerritoryInfo records which drive sharing

### Primary Provider Restriction
- Controlled by `enablePrimaryProviderRestriction` in `IndustriesSettings`
- When enabled: restricts data access based on the primary provider assignment
- Use when a rep should only see accounts assigned to their primary territory

### Product Territory Access
- `enableProdTerrAlgnPrtHrchyAcc` — enables access to Product Territory Alignment Partner Hierarchy
- `enableProdTerrAvlRecSharing` — enables sharing of available records for Product Territories

---

## Permission Sets

LSC uses permission sets extensively for feature access. Key permission sets:

| Permission Set | Grants Access To |
|---|---|
| `Health Cloud Starter` (for Life Sciences Cloud) | Base LSC object access; required for platform events and some metadata types |
| `Manage Financial Assistance Program` | `ApplnFormAppealStsChgEvnt` platform event |
| `Manage Pharmacy Benefits Verification` | `CareBnftVrfyRqstStsChgEvent` platform event, `CareBenefitVerifyRequest` |
| `Multi-Step Scheduling` | Advanced Therapy Management features (ServiceAppointmentGroup, WorkTypeStep, etc.) |
| `FHIR R4 for Experience Cloud Sites` | Allows community users to access Clinical Data Model objects on Experience Cloud sites |

---

## Compliance Controls

### GDPR/CCPA — Consent
- Use `CommSubscription` + `CommSubscriptionConsent` + `ContactPointConsent` for channel-specific consent
- `DataUsePurpose` records define the reason for contact — link to consent records
- Consent records should NEVER be deleted — enforce with Validation Rule or Apex trigger
- `CommSubConsentCmplSnpsht` captures compliance snapshot at time of consent (API v65.0+)

### Sunshine Act (US Open Payments)
- Transfers of value (meals, speaker fees, consulting) to HCPs must be tracked
- LSC Expense objects + Visit Management support ToV tracking
- Finance/Compliance profiles should have Read-only access to submitted TOV records

### 21 CFR Part 11 / Electronic Signatures
- `DigitalVerification` + `DigitalVerificationSetup` + `DigitalVerfSetupDetail` support e-signature workflows
- `DigitalSignatureRequest` — reserved for future use (as of v66.0)
- Confirm Part 11 compliance requirements with customer's regulatory/legal team before go-live

### HIPAA (if PHI involved)
- Clinical Data Model objects contain PHI (patient name, diagnosis, medication, encounter data)
- Salesforce is HIPAA-eligible (BAA required — must be executed separately from standard contract)
- Restrict Clinical Data Model objects to users with explicit "Health Cloud" or "Life Sciences Cloud" permission sets
- Evaluate field-level encryption for PHI fields at rest

---

## Profile and Permission Set Architecture (Recommended)

For a typical LSC commercial engagement:

| User Type | Base Profile | Permission Sets |
|---|---|---|
| Field Sales Rep | Minimum access custom profile | `Health Cloud Starter`, territory-specific PSG |
| Medical Science Liaison (MSL) | Minimum access custom profile | `Health Cloud Starter`, Medical Inquiries PSG |
| Territory Manager | Minimum access custom profile | `Health Cloud Starter`, Territory Management PSG |
| Sample/Compliance Admin | Standard User | `Health Cloud Starter`, `Manage Financial Assistance Program` |
| Clinical Operations | Minimum access custom profile | `Health Cloud Starter`, FHIR R4 access PSG |
| Community/Patient User | Customer Community Plus | `FHIR R4 for Experience Cloud Sites` |

---

## OWD Defaults (Typical for LSC)

Most LSC objects default to Private OWD with sharing driven by territory alignment, account ownership, or explicit sharing rules. Key defaults to verify at implementation:

| Object | Recommended OWD | Sharing Mechanism |
|---|---|---|
| `Account` (HCP/HCO) | Private | Territory alignment (ProviderAcctTerritoryInfo) |
| `CareProgramEnrollee` | Private | Account ownership or explicit sharing |
| `ClinicalEncounter` | Private | Care team membership |
| `CommSubscriptionConsent` | Private | Profile-based; compliance team access only |
| `ResearchStudy` | Private | Explicit sharing + permission set |
| `Expense` | Private | Owner + manager role hierarchy |

---

## Namespace Caution

Older LSC orgs may use `HealthCloudGA__` namespace for some objects. Newer orgs use standard objects with no namespace (or `lsc__` for some custom extensions). Always verify before writing SOQL or Apex:

```apex
// Verify installed packages and namespaces
List<ApexClass> cls = [SELECT NamespacePrefix, Name FROM ApexClass LIMIT 10];
// Or query InstalledSubscriberPackage via Tooling API
```
