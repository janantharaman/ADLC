---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Life Sciences Cloud — Implementation Guide

## Prerequisites

Before beginning any Life Sciences Cloud implementation:

| Prerequisite | Verification |
|---|---|
| Life Sciences Cloud license purchased | Check Setup > Company Information > Licenses |
| Base edition is Enterprise or Unlimited | LSC requires Enterprise+ |
| OmniStudio installed and configured (if using Assessment/Discovery Framework) | Check Setup > Installed Packages for OmniStudio |
| Salesforce Scheduler licensed (if using Advanced Therapy Management) | Check permission set licenses |
| Asset Scheduler Add-On license (for ATM with assets) | Separate add-on per asset |
| Person Accounts enabled (for Patient Engagement / Clinical Data Model) | Setup > Account Settings |
| My Domain configured | Required for any Experience Cloud or SSO integration |

---

## Phase 1: Core Org Setup

### Step 1 — Enable IndustriesSettings Features

Life Sciences Cloud features are enabled via `IndustriesSettings` metadata. Activate features in this recommended sequence to avoid dependency issues:

**Phase 1A — Foundation (enable first)**
1. `enableLifeSciencesCustomerEngagementBase` — foundational LS C4CE components
2. `enableAccountBasedSharing` — if territory/account-based sharing is required
3. `enableLifeSciencesConsent` — consent management objects

**Phase 1B — Customer Engagement**
4. `enableLSC4CEPackage` — core Customer Engagement package
5. `enableLSC4CEVisits` — visit management
6. `enableLSC4CERemoteEngagement` — remote engagement
7. `enableLSC4CEEmailAndTemplate` — email and template management
8. `enableLSC4CEDocumentManagement` — document management
9. `enableLifeSciListsAndFilters` — lists and filters
10. `enableLifeSciencesMergeManagement` — merge management
11. `enableLifeSciencesProviderEngagementCompliance` — compliance features

**Phase 1C — Key Account Management (if needed)**
12. `enableLSC4CEKeyAccountManagement` — key account management
13. `enableLSC4CEMedInsights` — medical insights

**Phase 1D — Territory and Products**
14. `enablePATSTerritoryBasedSharing` — territory-based sharing (PATS)
15. `enablePrimaryProviderRestriction` — primary provider restrictions
16. `enableProdTerrAlgnPrtHrchyAcc` — product territory alignment partner hierarchy
17. `enableProdTerrAvlRecSharing` — product territory record sharing

**Phase 1E — AI/Intelligence (if licensed)**
18. `enableNextBestAction` — Next Best Action recommendations
19. `enableNextBestCustomer` — Next Best Customer recommendations
20. `enableNextBestMessage` — Next Best Message recommendations
21. `enableIESentimentAnalysis` — Einstein Sentiment Analysis (API v54.0+)

**Phase 2 — Clinical and Patient (separate activation decision)**
22. `enableLifeSciencesConsent` (verify enabled)
23. `enableAdverseEvents` — Adverse Events data model (API v61.0, if clinical engagement)
24. `enableLifeSciencesClinialTrailManagement` — Clinical Trial Management (API v61.0)
25. `enableLifeSciencesSiteManagement` — Site Management for clinical trials

**CRITICAL:** Some settings are irreversible. Always enable in a sandbox first and validate before production activation. See gotchas.md G-13 for irreversible settings.

---

### Step 2 — Configure FHIR R4 Clinical Data Model (Patient Engagement only)

If the implementation includes Patient Engagement with clinical data:

1. Confirm Life Sciences Cloud license includes clinical data model access
2. Setup → FHIR R4 Support Settings → Enable "FHIR-Aligned Clinical Data Model" org pref
3. Assign `FHIR R4 for Experience Cloud Sites` permission set to any community users who need Clinical Data Model access
4. Verify the standard object field additions: `ContactPointPhone.PreferenceRank`, `Account.IsActive`, etc.
5. Configure CodeSet and CodeSetBundle with your organization's coding system (ICD-10, SNOMED CT, NDC, etc.)

---

## Phase 2: Customer Engagement (LS C4CE) Setup

### Step 3 — Territory Management Configuration

1. Enable Salesforce Enterprise Territory Management (Setup → Territories)
2. Create Territory2Model for your company's territory hierarchy
3. Configure territory types (e.g., National, Regional, District, Territory)
4. Set up alignment rules:
   - Explicit customer alignment (account-to-territory direct assignment)
   - Geographical alignment (zip/state-based)
   - Affiliation alignment (provider network affiliation)
5. Assign users to territories
6. Enable `enablePATSTerritoryBasedSharing` in IndustriesSettings
7. Run territory alignment jobs to generate `ProviderAcctTerritoryInfo` records
8. Verify sharing recalculation completed

---

### Step 4 — Provider Search Configuration

1. Configure `CareProviderSearchConfig` metadata to define searchable fields
2. Activate the config (set `isActive = true`)
3. Trigger initial data sync to populate `CareProviderSearchableField` denormalized records
4. Test provider search with `Advanced Provider Search API`
5. Configure `SearchResultActionConfig` for actions available on search results (Flow, LWC, or OmniScript)

---

### Step 5 — Sample Management Setup

1. Create `ProviderSampleLimitTemplate` records defining sample limit rules per account segment
2. Configure territory-product sample allocation (`ProductTerrDtlAvailability`)
3. Set up `DigitalVerificationSetup` for e-signature capture on sample receipts
4. Configure the Sample Limits Validation API endpoint
5. Build sample disbursement Screen Flow (see automation-patterns.md)
6. Assign sample management permission sets to field reps

---

### Step 6 — Consent Management Setup

1. Configure `DataUsePurpose` records (one per communication purpose: marketing, medical, safety)
2. Configure `CommSubscription` channel types (Email, Phone, Mail, Digital, etc.)
3. Build consent capture Screen Flow (see automation-patterns.md)
4. Add Validation Rule to prevent consent record deletion (see gotchas.md G-10)
5. Assign consent management permission sets

---

### Step 7 — Account Plan / Key Account Management (if licensed)

1. Enable `enableLSC4CEKeyAccountManagement` in IndustriesSettings
2. Configure AccountPlan record types and page layouts
3. Set up `ActionPlanTemplate` records for standard account plan activities
4. Configure `AccountPlanRelationship` for account plan hierarchy
5. Assign `AccountPlanStakeholder` and `AccountPlanParticipant` to account plans

---

## Phase 3: Patient Engagement Setup

### Step 8 — Care Program Setup

1. Create `CareProgram` records (one per support program offered)
2. Define `CareProgramProduct` affiliations (which products the program covers)
3. Define `CareProgramProvider` affiliations (service providers)
4. Configure `EnrollmentEligibilityCriteria` for each program
5. Set up `ProgramRecommendationRule` if using AI-driven program recommendations
6. Configure `CareProgramSite` records for clinical trial programs (API v61.0+)

---

### Step 9 — Financial Assistance Program Setup

1. Configure `BenefitType` records for program types (copay assistance, insurance premium, etc.)
2. Configure `Benefit` record templates
3. Set up application form workflows
4. Subscribe to `ApplnFormAppealStsChgEvnt` platform event (requires Manage Financial Assistance Program permission set)
5. Build appeal status change handler (see automation-patterns.md)

---

### Step 10 — Pharmacy Benefits Verification Setup

1. Configure `CareBenefitVerifySettings` metadata (payer endpoint, NPI, service type codes)
2. Set up Named Credential for payer endpoint
3. Configure `CareRequestConfiguration` for drug request record types
4. Subscribe to `CareBnftVrfyRqstStsChgEvent` platform event
5. Assign `Manage Pharmacy Benefits Verification` permission set to relevant users

---

### Step 11 — Advanced Therapy Management (if licensed)

**Prerequisites:**
- Salesforce Scheduler license
- Asset Scheduler Add-On license (per asset in a service territory)
- Multi-Step Scheduling permission set

1. Configure work types for procedure steps (apheresis, manufacturing, infusion)
2. Set up `WorkTypeStep` records defining the sequence of procedure steps
3. Configure `WorkTypeStepLdTimeOvride` for any lead time overrides
4. Set up `ServiceTerritoryRelationship` records to define affiliated sites
5. Configure service resources (human + asset) at each service territory
6. Build multi-step scheduling Flow using Book Slot Chain API (see automation-patterns.md)
7. Test end-to-end scheduling flow with actual service territories

---

## Phase 4: Clinical Trial Management (if licensed)

### Step 12 — Clinical Trial Setup

1. Enable `enableLifeSciencesClinialTrailManagement` in IndustriesSettings
2. Create `ResearchStudy` records for each trial
3. Configure `ResearchStudyCmprGroup` (comparison groups / arms)
4. Set up `RsrchStdyRandomizationCrit` (inclusion/exclusion criteria)
5. Configure `ResearchStudyProtocolInfo`
6. Build enrollment Flow using `processCriteriaMatchingResp` invocable action for AI-assisted eligibility

---

## Phase 5: Deployment Preparation

### package.xml Template for LSC Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <!-- LSC Core Settings -->
  <types>
    <members>Industries</members>
    <name>Settings</name>
  </types>
  <!-- Consent and Communication -->
  <types>
    <members>*</members>
    <name>CareBenefitVerifySettings</name>
  </types>
  <types>
    <members>*</members>
    <name>CareRequestConfiguration</name>
  </types>
  <types>
    <members>*</members>
    <name>CareSystemFieldMapping</name>
  </types>
  <types>
    <members>*</members>
    <name>CareProviderSearchConfig</name>
  </types>
  <!-- Provider Sample Limits -->
  <types>
    <members>*</members>
    <name>ProviderSampleLimitTemplate</name>
  </types>
  <!-- Timeline -->
  <types>
    <members>*</members>
    <name>TimelineObjectDefinition</name>
  </types>
  <!-- UI Object Relation -->
  <types>
    <members>*</members>
    <name>UIObjectRelationConfig</name>
  </types>
  <!-- Search Actions -->
  <types>
    <members>*</members>
    <name>SearchResultActionConfig</name>
  </types>
  <!-- Actionable Lists -->
  <types>
    <members>*</members>
    <name>ActionableListDefinition</name>
  </types>
  <!-- Standard metadata -->
  <types>
    <members>*</members>
    <name>CustomObject</name>
  </types>
  <types>
    <members>*</members>
    <name>ApexClass</name>
  </types>
  <types>
    <members>*</members>
    <name>Flow</name>
  </types>
  <types>
    <members>*</members>
    <name>PermissionSet</name>
  </types>
  <types>
    <members>*</members>
    <name>NamedCredential</name>
  </types>
  <version>66.0</version>
</Package>
```

---

### Post-Deployment Checklist

After every LSC deployment to production, manually verify:

- [ ] Territory alignment jobs ran and completed (check job status)
- [ ] `ProviderAcctTerritoryInfo` records generated for all active territories
- [ ] `CareProviderSearchableField` populated (run re-sync if empty)
- [ ] `CareBenefitVerifySettings` Named Credential resolves in production
- [ ] Platform event subscriptions (appeal, benefit verify) are active
- [ ] Permission sets assigned to appropriate users (Health Cloud Starter, etc.)
- [ ] `DigitalVerificationSetup` records activated for e-signature workflows
- [ ] Sample limits correctly copied from sandbox (verify `ProviderSampleLimitTemplate`)
- [ ] FHIR R4 org pref enabled in production if enabled in source (if applicable)
- [ ] `IndustriesSettings` changes verified in target org (not always deployable via metadata)

---

## Integration Architecture

### External EHR / HL7 Integration

```
EHR System (Epic / Cerner)
    ↓ HL7 v2.3 or FHIR R4 messages
MuleSoft (Anypoint Platform) — recommended
    ↓ Transform: HL7 segments → Salesforce objects
Salesforce LSC
    ↓ Store in Clinical Data Model objects
      (ClinicalEncounter, AllergyIntolerance, MedicationRequest, etc.)
```

**Alternative (no MuleSoft):**
```
EHR System
    ↓ FHIR R4 REST API
Apex HTTP Callout (using Named Credential)
    ↓ Transform FHIR JSON → Salesforce DML
Salesforce LSC Clinical Data Model
```

### Pharmacy System Integration

```
Pharmacy Benefits Manager (PBM)
    ↓ CARIN/NCPDP protocol
LSC Pharmacy Benefits Verification API
    ↓ CareBenefitVerifyRequest → CareBnftVrfyRqstStsChgEvent
Salesforce LSC → CoverageBenefit, FormularyItem
```

### Territory Alignment Integration

```
External Territory Management System
    ↓ Account-to-territory mappings
Account Manual Alignment API
    POST /connect/life-sciences/commercial/customer-manual-alignment
    ↓ Creates ProviderAccountTerritoryInfo
Salesforce LSC → Sharing recalculation
```
