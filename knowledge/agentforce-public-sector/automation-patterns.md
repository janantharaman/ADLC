# Agentforce Public Sector (Public Sector Solutions) — Automation Patterns

## Pattern 1: Eligibility Determination via Business Rules Engine

**Use case:** Constituent applies for a benefit. System auto-assesses eligibility based on income, household size, residency, and program-specific rules — without code.

**Implementation:**
1. Create a `DecisionMatrix` for each eligibility rule set (e.g., Housing Assistance eligibility)
   - Rows: combinations of income bracket, household size, residency status
   - Output column: `EligibilityStatus` (Eligible / Ineligible / PendingReview)
2. Create an `ExpressionSet` for complex multi-condition overrides (e.g., veteran status exception)
3. Invoke the BRE from an OmniScript step using an Integration Procedure
4. Integration Procedure calls `ConnectApi.BusinessRulesEngine` to evaluate rules
5. Result updates `ProgramEnrollment.EligibilityStatus__c` field
6. If `PendingReview`, trigger a Case for manual review

**Config-first principle:** BRE replaces Apex eligibility logic — policy changes update the Decision Matrix, not code.

---

## Pattern 2: Benefit Application Intake via OmniScript

**Use case:** Constituent submits a benefit application through a public-facing portal. Application creates an Individual record, Program Enrollment, and routes to a case worker queue.

**Implementation:**
1. OmniScript: multi-step guided intake form
   - Step 1: Identity verification (name, DOB, address, ID number)
   - Step 2: Household composition
   - Step 3: Income and asset declaration
   - Step 4: Program selection and consent
2. DataRaptor Turbo Extract: look up existing `Individual` by ID number to prevent duplicates
3. DataRaptor Transform + Load: create/update `Individual`, `Contact`, `ProgramEnrollment`
4. Integration Procedure: invoke BRE eligibility check (Pattern 1)
5. Flow (auto-launched): if eligible, assign to case worker queue; if ineligible, send rejection notification
6. OmniScript confirmation step: show application reference number

**Guest user note:** OmniScript submissions from unauthenticated users must use an Integration Procedure with elevated context (Apex `without sharing` or Named Credential) — the guest user profile cannot directly create `Individual` records.

---

## Pattern 3: Grant Application Lifecycle

**Use case:** Organisation submits a grant application. Application goes through review, scoring, award decision, and disbursement tracking.

**Implementation:**
1. Experience Cloud portal with OmniScript application form
2. `GrantApplication` record created on submission with status `Submitted`
3. Approval Process (or Flow-based approval): route to Program Officer → Grant Manager → Finance
4. On approval: Flow creates `FundingAward` and `FundingAwardPeriod` records
5. Disbursement schedule: Flow creates `Disbursement` records for each payment milestone
6. Scheduled Flow: on disbursement due date, alert Finance and update status
7. CRM Analytics dashboard: grant portfolio view by program, status, disbursement balance

---

## Pattern 4: Permit and Inspection Workflow

**Use case:** Business submits a permit application. System routes to relevant department, schedules inspection, records outcomes, and issues license.

**Flow:**
```
Permit Application (OmniScript)
  → Create Permit record (status: Submitted)
  → Flow: assign to department queue based on permit type
  → Case Worker: review and approve/reject
  → If approved: create Inspection record and assign to inspector
  → Inspector: complete inspection, record pass/fail, note violations
  → If passed: Flow creates BusinessLicense (or updates renewal date)
  → Notification: email/SMS to applicant with outcome
```

**Scheduling:** Use `Inspection.ScheduledStartTime` and assignment to Inspector (User) or Queue. Field Service integration is available for complex multi-zone scheduling.

---

## Pattern 5: Agentforce Benefits Eligibility Agent

**Use case:** Constituent calls or chats with a government contact centre. Agentforce agent pre-screens eligibility before transferring to a case worker, reducing handle time.

**Implementation:**
1. Configure Agentforce Agent with `Benefits Eligibility` topic
2. Agent actions:
   - `GetConstituentProfile` — look up existing Individual by ID + DOB
   - `CheckProgramEligibility` — call BRE via Integration Procedure
   - `CreateDraftEnrollment` — create a ProgramEnrollment in Draft status for case worker pickup
   - `ScheduleAppointment` — create a Visit record for in-person case worker meeting
3. Agent escalates to human case worker when: eligibility is unclear, complex household situation, constituent requests human, or after 3 failed identification attempts
4. Transcript attached to the created Case for case worker context

---

## Pattern 6: Investigative Case Action Plans

**Use case:** Investigator opens a case. System generates a pre-defined action plan with the required investigation steps based on case type.

**Implementation:**
1. Create `ActionPlan Template` for each investigation type (fraud investigation, welfare check, compliance audit)
2. Flow trigger on Case creation: detect `CaseType`, look up matching template, create `ActionPlan` and `ActionPlanItem` records
3. Each `ActionPlanItem` generates a Task assigned to the investigator or a specialist
4. Milestones tracked via Flow on Task completion
5. Supervisor dashboard (CRM Analytics): case progress, overdue tasks, caseload balance

---

## Pattern 7: Automated Reminder and Deadline Notifications

**Use case:** Benefit recipients receive renewal reminders. Grant recipients receive disbursement deadline alerts. Permit applicants receive status updates.

**Implementation (Scheduled Flow):**
- Run daily
- Query `ProgramEnrollment` where `EnrollmentEndDate = TODAY + 30`
- Create outbound messages or invoke Messaging (SMS/email) via Flow action
- Log outreach as `Task` on the enrollment record

**Preference centre:** If constituents opt in/out of channels, store preferences on `Individual` or a custom `CommunicationPreference__c` object and filter before sending.

---

## Pattern 8: Complaints Intake with NLP Routing

**Use case:** Constituent submits a complaint via web form. NLP classifies the complaint type and routes to the correct department queue automatically.

**Implementation:**
1. OmniScript web form: free-text complaint description + category selection (optional)
2. Flow calls Einstein Classification or Agentforce Complaints Agent to classify free text
3. Based on classification output, Flow sets `Case.Queue` and `Case.Priority`
4. Case created and assigned; constituent receives confirmation with case reference
5. SLA Entitlement Process: auto-escalate if no first response within configured hours

---

## OmniStudio vs Flow — Decision Guide

| Scenario | Use |
|---|---|
| Multi-step constituent intake form | OmniScript |
| Simple internal admin data entry | Screen Flow |
| Record-triggered automation (on save) | Record-Triggered Flow |
| Scheduled batch processing | Scheduled Flow |
| Complex eligibility rules | Business Rules Engine |
| External API call within portal | Integration Procedure |
| Dashboard/card on record page | FlexCard |
| Approval routing | Approval Process or Flow |
