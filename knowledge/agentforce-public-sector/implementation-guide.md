# Agentforce Public Sector (Public Sector Solutions) — Implementation Guide

## Pre-Implementation Checklist

- [ ] PSS licence confirmed and provisioned (`Setup → Company Information → Licenses`)
- [ ] Government Cloud Plus requirement confirmed (FedRAMP High needed? StateRAMP?)
- [ ] Modules in scope confirmed (Benefits, Grants, Permits, Investigations, Workforce — which?)
- [ ] Constituent data model agreed (Individual + Contact vs Contact-only)
- [ ] Portal requirement confirmed (authenticated community vs unauthenticated forms vs both)
- [ ] Number of community licence seats estimated
- [ ] BRE licensing confirmed (included in PSS Foundation; check tier)
- [ ] CRM Analytics for PSS licensing confirmed if dashboards needed
- [ ] OmniStudio licence confirmed (included in PSS Foundation)
- [ ] Integration requirements documented (which legacy systems, which protocols)
- [ ] MuleSoft availability confirmed for legacy system integrations
- [ ] AppExchange packages verified for GovCloud compatibility (if FedRAMP required)
- [ ] Data migration scope agreed (how many years of historical case/enrollment data)
- [ ] Identity verification approach agreed (self-registration flow, match on SSN/DOB?)

---

## Phase 1: Foundation Setup (Days 1–5)

### Step 1: Enable PSS and Assign Permission Sets

1. Confirm the managed package is installed: `Setup → Installed Packages`
2. Run the PSS Setup Assistant: `Setup → Public Sector Solutions Setup`
3. Assign permission sets:
   - `Public Sector Admin` → implementation team and agency admins
   - `Public Sector Access` + `OmniStudio User` → case workers and portal users
   - `Business Rules Engine Admin` → policy analysts who will author eligibility rules

### Step 2: Configure Organisation and Program Structure

1. Create `BenefitProgram` records for each program in scope
2. Define program attributes: eligibility criteria (documented), benefit types, enrollment limits
3. If using `CareProgram` structure (coordinated service delivery), create the program hierarchy
4. Set up `FundingSource` records for grant programs with total budget amounts

### Step 3: Configure Sharing and Security

1. Set OWD on `Individual`, `Contact`, `ProgramEnrollment`, `Case` to Private
2. Create sharing rules for supervisor visibility based on role hierarchy
3. Configure Experience Cloud site (if portal in scope): set guest user profile permissions
4. Enable **Secure Guest User Record Access** in Experience Cloud settings
5. Test guest user access with a throwaway session — verify no unintended object visibility

---

## Phase 2: Business Rules Engine Setup (Days 5–10)

### Step 4: Model Eligibility Rules

1. Document all eligibility criteria as decision tables (spreadsheet format first)
2. Create `DecisionMatrix` for each benefit program:
   - Input columns: income range, household size, residency, other criteria
   - Output column: `EligibilityStatus` (Eligible / Ineligible / PendingReview)
3. Create `ExpressionSet` for complex override conditions (veteran exemptions, disability thresholds)
4. Version and activate rules
5. Test via the BRE test tool in Setup — verify edge cases before connecting to OmniScript

### Step 5: Build Integration Procedure for Eligibility

1. Create an Integration Procedure: `CheckEligibility`
2. Steps:
   - Input: Individual ID, Program ID
   - DataRaptor: look up Individual demographics
   - HTTP Action: invoke BRE Connect API with mapped inputs
   - Response Action: map BRE output to return variables
3. Test the Integration Procedure in isolation before embedding in OmniScript

---

## Phase 3: OmniStudio Portal Development (Days 10–25)

### Step 6: Build Intake OmniScripts

For each service type (benefit application, grant application, permit application):

1. Draft the step flow on paper or whiteboard first — agree with agency stakeholders
2. Build OmniScript in OmniStudio Designer:
   - Set type to `OmniScript`, language `English`, sub-type matching the service
   - Use `Remote Action` element to call Integration Procedures
   - Use `DataRaptor Turbo Extract` for duplicate-check lookups
   - Use `DataRaptor Load` for final record creation
3. Map confirmation step output to show reference number to constituent
4. Test in OmniStudio Preview before embedding in Experience Cloud

### Step 7: Build Constituent Snapshot FlexCards

1. Create FlexCards for the case worker record page:
   - Enrollment history card
   - Active benefits card
   - Linked cases card
   - Interaction timeline card
2. Embed FlexCards in the `Contact` or `Individual` record page via Lightning App Builder

### Step 8: Configure Experience Cloud Portal

1. Create the portal site: `Setup → Digital Experiences → New`
2. Select template: **Help Center** (recommended for self-service) or **Customer Account Portal**
3. Add OmniStudio components to portal pages via Experience Builder
4. Configure self-registration page with Apex handler for constituent identity matching
5. Set up navigation: Home, Apply for Benefits, Check Application Status, Help

---

## Phase 4: Action Plans and Case Management (Days 20–30)

### Step 9: Configure Action Plan Templates

1. Identify investigation/inspection types that require structured task sequences
2. For each type, create an `Action Plan Template` in Setup
3. Add `Action Plan Template Item` records (tasks with dependencies and due-date offsets)
4. Build a record-triggered Flow: on Case creation with matching Type, create Action Plan from template

### Step 10: Configure Case Routing

1. Create Queues for each department or team (Benefits Processing, Grants Review, Inspections)
2. Create Case Assignment Rules: route based on `CaseType`, `RecordType`, or OmniScript-set fields
3. Configure Omni-Channel: add queues to routing configurations with capacity settings
4. Test routing end-to-end with test cases

---

## Phase 5: Data Migration (Days 25–40)

### Step 11: Prepare Migration Scripts

1. Map legacy fields to PSS data model (create a field mapping spreadsheet)
2. For each object: prepare CSV templates matching PSS field API names
3. Load reference data first: `BenefitProgram`, `FundingSource`, `LicenseType`, `InspectionType`
4. Load constituent data: `Account`, `Contact`, `Individual` (with parent-child linking)
5. Load transactional data: `ProgramEnrollment`, `GrantApplication`, `BusinessLicense`
6. Load sub-records last: `Benefit`, `FundingAward`, `Disbursement`, `Inspection`

### Step 12: Validate Migration

```sql
-- Confirm enrollment counts match legacy system
SELECT BenefitProgram__r.Name, Status__c, COUNT(Id) RecordCount
FROM ProgramEnrollment
GROUP BY BenefitProgram__r.Name, Status__c
ORDER BY BenefitProgram__r.Name

-- Check for orphaned enrollments (no linked Individual)
SELECT Id, Name, Status__c
FROM ProgramEnrollment
WHERE IndividualApplication__c = NULL
```

---

## Phase 6: Reporting and Analytics (Days 35–45)

### Step 13: Build Standard Reports

Create custom report types for:
- Program Enrollment + Benefit (for benefits reporting)
- Grant Application + Funding Award + Disbursement (for grants reporting)
- Inspection + Regulatory Code Violation (for compliance reporting)
- Action Plan + Action Plan Item (for investigation workflow reporting)

### Step 14: Configure CRM Analytics Dashboards (if licensed)

1. Create CRM Analytics Data Sync for PSS objects
2. Build Recipe: aggregate enrollments by program, status, and month
3. Build dashboard: caseload by worker, program uptake trends, grant disbursement pipeline

---

## Deployment Considerations

### What is deployable
- Custom fields, validation rules, flows, Apex
- Permission set customisations
- Report types and report folders
- Experience Cloud page layouts (partial — page structure yes, credentials no)
- CRM Analytics dashboards and recipes

### What must be manually configured per org
- BRE Decision Matrix rows (data records, not metadata)
- `BenefitProgram`, `FundingSource`, `LicenseType` reference data
- OmniStudio components (export/import JSON or use OmniStudio MCP)
- Experience Cloud site configuration and branding
- Queue and routing configuration

### Sandbox strategy
- Sandbox refresh does not copy Decision Matrix rows — maintain data load scripts
- OmniStudio components in sandbox must be re-imported after refresh
- Do not use real constituent PII in sandbox — use synthetic test data
- Test all managed package upgrades in full sandbox before production deployment
