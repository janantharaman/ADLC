---
source: hand-authored; supplemented from Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Financial Services Cloud — Automation Patterns

## Policy Lifecycle Flows

**Pattern — policy inception:**
```
Screen Flow (internal or customer portal):
  Screen 1: Select client Account, product, coverage dates
  Screen 2: Coverage details (assets, limits, deductibles)
  Screen 3: Premium calculation (invoke Apex pricing engine or external rating API)
  Screen 4: Review and confirm
  Actions:
    → Create InsurancePolicy (Status = 'Pending')
    → Create InsurancePolicyCoverage records
    → Create InsurancePolicyParticipant for insured, agent, beneficiaries
    → Create Task: 'Issue policy documents' assigned to underwriting team
```

**Pattern — policy renewal:**
```
Scheduled Flow (runs 60 days before ExpirationDate):
  Query: InsurancePolicy WHERE ExpirationDate = TODAY + 60 AND Status = 'InForce'
  Loop: For each expiring policy
    → Create Task: 'Renewal required' assigned to Account Owner
    → Create Opportunity: Type = 'Renewal', CloseDate = ExpirationDate - 30
    → Send renewal notification to client (if consent allows)
```

## Claims Processing Patterns

**Pattern — first notice of loss (FNOL) intake:**
```
Screen Flow (portal or service agent):
  Screen 1: Policy lookup (search by policy number or insured name)
  Screen 2: Loss details (date, type, description)
  Screen 3: Attachments (photos, documents)
  Actions:
    → Create Claim (Status = 'New', auto-number ClaimNumber)
    → Create Case linked to Claim (for service team follow-up)
    → Assign to Claims Queue via Assignment Rule
    → Send acknowledgement to claimant
```

**Pattern — claim status progression:**
```
Record-Triggered Flow on Claim | Before Save | Status changes
  Decision: New Status = 'Under Review'
    → Validate: LossDate is not blank, ClaimType is not blank
    → Set adjuster based on ClaimType and region

  Decision: New Status = 'Settled'
    → Validate: TotalClaimAmount populated, SettlementDate populated
    → Update linked InsurancePolicy: flag for premium review
```

## Referral Management

**Pattern — advisor referral tracking:**
```
Record-Triggered Flow on Opportunity | After Insert | Type = 'Referral'
  Action: Create ContactContactRelation between ReferredBy and new Contact (role = 'Referral Source')
  Action: Create Task: 'Thank referral source' assigned to advisor
  Action: Notify referring advisor via email
```

## Premium Reconciliation

**Pattern — bank transaction matching:**
```
Scheduled Batch (nightly):
  Query: BankTransaction__c WHERE MatchedRecord__c = null AND Status = 'Unmatched'
  For each transaction:
    → SOQL: Find Settlement__c or Invoice WHERE Amount and Reference match
    → If match found: Update BankTransaction.MatchedRecord__c, Status = 'Matched'
    → If no match: Create Reconciliation_Exception__c for manual review
```

**Pattern — period close:**
```
Approval Process on PeriodClose__c:
  Entry criteria: Status = 'Submitted for Close'
  Step 1: Finance Manager approval
  Step 2: Finance Director approval (if total variance > configurable threshold)
  On Final Approval:
    → Validation rule activates: blocks new transactions dated in closed period
    → Scheduled report triggers to generate period close summary
```

## Household Aggregation

**Pattern — household financial summary update:**
```
Record-Triggered Flow on FinancialAccount | After Save | Balance changes
  Action: Recalculate household total assets/liabilities
  Update: Household Account summary fields
```

**Note:** FSC managed package includes built-in household rollup calculations but they run asynchronously. For real-time totals on specific fields, supplement with custom Apex trigger rollups.

## Relationship Network Automation

**Pattern — create household relationship on policy inception:**
```
Record-Triggered Flow on InsurancePolicyParticipant | After Insert | Role = 'Joint Insured'
  Query: AccountAccountRelation WHERE AccountId = InsurancePolicyParticipant.AccountId
         AND RelatedAccountId = Policy.InsuredAccountId
         AND Roles INCLUDES 'Household Member'
  Decision: Relationship already exists?
    → No: Create AccountAccountRelation (Household Member, both directions)
    → Yes: Skip
```

---

## Flow for Financial Services Cloud

Source: fsc_dev_guide.pdf p.1310 (`Flow for Financial Services Cloud` metadata section).

FSC extends the standard Salesforce `Flow` metadata type with additional `processType` and `FlowActionCall.actionType` values.

### FSC-Specific Flow ProcessType

| Value | Purpose |
|---|---|
| `FSCLending` | Flow type for Financial Services Cloud Mortgage workflows. Available API v46.0+. Use for residential loan application flows, loan origination guidance, mortgage document collection. |

### FSC-Specific FlowActionCall ActionType Values

These action types are invocable from within a Flow's Action element. They appear as "FSC Standard Actions" in Flow Builder:

| ActionType Value | Label in Flow Builder | Available Since |
|---|---|---|
| `createFinancialRecords` | Create Financial Records | API v49.0 |
| `createIntegrationPlan` | Create Integration Plan | API v60.0 |
| `runIntegrationPlan` | Run Integration Plan | API v60.0 |
| `getPicklistValues` | Get Picklist Values | API v65.0 |
| `publishActionableOrchSrcEvent` | Publish Actionable Orchestration Source Event | API v62.0 |
| `createCaseForFeeReversal` | Create Case for Fee Reversal | API v62.0 |

---

## Pattern: Integration Plan

Source: fsc_dev_guide.pdf pp.1346–1348, 1357–1358.

### What Is an Integration Plan?

An Integration Plan is an FSC orchestration record that represents a sequence of external callout steps with dependencies. It uses **Dynamic Fulfillment Orchestration** to ensure each callout fires at the right time — queuing steps and their dependent steps so that downstream callouts wait for upstream results. Integration Plans are used in mortgage origination, onboarding, KYC, and any multi-step external integration scenario.

Architecture:
- An **Expression Set** defines which integrations are eligible and what their dependencies are
- `createIntegrationPlan` creates the plan record with all steps and their ordering
- `runIntegrationPlan` executes the plan — each callout step fires in dependency order
- Plans reference **Integration Definition** records configured in FSC Setup

### Pattern: Create Integration Plan in Flow

```
Screen Flow or Auto-launched Flow:
  Input: ResidentialLoanApplication record (or ApplicationForm, PartyProfile)

  Action: createIntegrationPlan
    Input:
      expressionSetName: 'HomeLoanIntegrationsES'    [required]
      anchorRecordId: {recordId}                     [required - supplies expression set inputs]
      contextDefinitionName: 'Home Loan Application Context'   [API v61+ optional]
      contextMappingName: 'Home Loan Application Context Mapping' [API v61+ optional]
      contextData: '{JSON context data}'             [API v61+ optional]
      isTaggedData: false                            [default]
    Output:
      integrationPlanId → store in variable

  Action: runIntegrationPlan
    Input:
      integrationPlanId: {integrationPlanId from above}
      contextId: {optionally the Context Service ID}
    Output:
      status: 'SUCCESS' | 'Running' | 'Not Started' | 'Failed'
```

### Input/Output Reference

**Create Integration Plan — Inputs**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `expressionSetName` | string | Yes | API name of the expression set identifying eligible integrations and dependencies |
| `anchorRecordId` | ID | Yes | ID of the record supplying expression set input parameters not in contextId |
| `contextDefinitionName` | string | No (v61+) | Name of the Context Definition record to build context data |
| `contextMappingName` | string | No (v61+) | Name of the Context Mapping record used to build context |
| `contextData` | string | No (v61+) | JSON of context data record |
| `isTaggedData` | boolean | No (v61+) | Whether key in data is a tagged key (default: false) |

**Create Integration Plan — Output**

| Parameter | Type | Description |
|---|---|---|
| `integrationPlanId` | ID | ID of the integration plan (includes each callout step and step dependency) |

**Run Integration Plan — Inputs**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `integrationPlanId` | ID | Yes | ID of the integration plan to execute |
| `contextId` | ID | No | ID of the Context Service referencing the record supplying expression set inputs. Recommended: Applicant, ApplicationForm, or PartyProfile record |

**Run Integration Plan — Output**

| Parameter | Type | Description |
|---|---|---|
| `status` | string | Execution status: `SUCCESS` (maps to Running), `Not Started`, `Failed` |

---

## Pattern: Actionable Orchestration

Source: fsc_dev_guide.pdf pp.1355–1356.

### What Is Actionable Orchestration?

Actionable Orchestration is an FSC feature that fires orchestration rules in response to data change events. It is used to automatically trigger business processes (alerts, notifications, follow-up tasks, downstream integrations) when specific data changes occur in monitored Data Objects.

The `publishActionableOrchSrcEvent` invocable action is the trigger mechanism — it publishes an event from a **Data Object Data Change Event** payload to the Actionable Orchestration engine.

### When to Use

- Client transaction exceeds threshold → trigger alert and follow-up workflow
- Policy renewal date approaching → fire orchestration rule to create renewal opportunity and notify advisor
- Claim status changes → publish event for downstream orchestration (e.g., release reserve, notify reinsurer)
- Any scenario where a CDC (Change Data Capture) or Data Object event should trigger structured multi-step orchestration

### Pattern: Publish Actionable Orchestration Source Event in Flow

```
Record-Triggered Flow on [Data Object] | After Save
  Action: publishActionableOrchSrcEvent
    Input:
      payloadCurrentValue: {serialize changed fields as JSON}   [required]
      sourceObjectDeveloperName: '[DataObject]__cio'            [required]
      dataSpace: 'FSC'                                          [optional - data space]
    Output: None
```

**Inputs**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `payloadCurrentValue` | string | Yes | JSON name-value pairs from the PayloadCurrentValue field of the Data Object Data Change Event payload |
| `sourceObjectDeveloperName` | string | Yes | API name of the source object developer named field in the Payload Current Value parameter |
| `dataSpace` | string | No | API name of the data space used to generate/manage contextual alerts |

**Output:** None (fire-and-forget publish)

---

## Pattern: Create Financial Records

Source: fsc_dev_guide.pdf pp.1344–1345.

### What It Does

The `createFinancialRecords` invocable action takes a `ResidentialLoanApplication` ID and automatically creates linked FSC records based on data in the application. The specific record types created are controlled by `IndustriesSettings` toggles (`createFinancialAccountFromLAAsset`, `createCustomerPropertyFromLAProperty`, etc.).

### Pattern in a Mortgage Origination Flow

```
Screen Flow (loan officer or online application):
  ... loan application data collection ...
  Action: createFinancialRecords
    Input:
      recordId: {ResidentialLoanApplication.Id}    [required]
    Output:
      status: 'SUCCESS' | 'PARTIAL_SUCCESS' | 'FAILURE'
      personAccountsIdList: [list of created Person Account IDs]
      financialAccountsIdList: [list of created FinancialAccount IDs]
      customerPropertiesIdList: [list of created CustomerProperty IDs]
      assetsAndLiabilitiesIdList: [list of created AssetsAndLiabilities IDs]
      errors: [list of error strings if PARTIAL_SUCCESS or FAILURE]
```

**Inputs**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `recordId` | ID | Yes | ID of the ResidentialLoanApplication record |

**Outputs**

| Parameter | Type | Description |
|---|---|---|
| `status` | string | `SUCCESS`, `PARTIAL_SUCCESS`, or `FAILURE` |
| `personAccountsIdList` | string | Comma-separated or JSON list of created PersonAccount IDs |
| `financialAccountsIdList` | string | List of created FinancialAccount IDs |
| `customerPropertiesIdList` | string | List of created CustomerProperty IDs |
| `assetsAndLiabilitiesIdList` | string | List of created AssetsAndLiabilities IDs |
| `errors` | string | List of errors encountered (empty on SUCCESS) |

**Prerequisite:** The relevant IndustriesSettings creation flags must be enabled before this action will create records of each type.

---

## Pattern: Get Assessment Response Summary

Source: fsc_dev_guide.pdf pp.1348–1350.

### What It Does

Returns a structured JSON summary of all assessment question responses for a given Assessment record. Used in KYC/onboarding flows to pass Discovery Framework data to:
- Document Generation (PDF rendering via Salesforce Document Generation)
- Downstream flow branches (conditional logic based on assessment answers)
- Agent summaries and case notes

The JSON output mirrors the OmniScript structure — each step is a key, each question within the step is a sub-key with `label` and `value`.

### Pattern in an Onboarding/KYC Flow

```
Screen Flow (KYC OmniScript completes → triggers flow):
  Action: getAssessmentResponseSummary
    Input:
      assessmentId: {Assessment.Id}    [required]
    Output:
      assessmentResponseSummary → JSON string

  Decision: assessmentResponseSummary contains required fields?
    → Yes: Continue to document generation step
    → No: Route to manual review queue
```

**Inputs**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `assessmentId` | ID | Yes | ID of the Assessment record for which to summarize responses |

**Output**

| Parameter | Type | Description |
|---|---|---|
| `assessmentResponseSummary` | string | JSON string with structure: `{OmniScript_Type_SubType_Language: {StepName: {label, value: {QuestionName: {label, value}}}}}` |

**Note:** The summary JSON structure follows the OmniScript step/question hierarchy. If the OmniScript has a step `Step1` with questions `FullName_m` and `DateOfBirth_m`, the JSON will have `{Step1: {label: "...", value: {FullName_m: {label: "Full Name", value: "Joe Smith"}, ...}}}`. Use this structure to map values into Document Generation templates.

---

## Automation Decision Matrix

Use this matrix to select the right automation tool for FSC scenarios:

| Scenario | Screen Flow + Invocable Action | OmniScript + Integration Procedure | Apex |
|---|---|---|---|
| Guided agent data entry (FNOL, policy inception) | Preferred — low-code, declarative | Also suitable — richer UX, step validation | Not needed |
| KYC/onboarding with assessment questions | Screen Flow + `getAssessmentResponseSummary` | OmniScript with Discovery Framework (native) | Not needed |
| Create mortgage records from loan application | Flow + `createFinancialRecords` invocable action | Integration Procedure calling same action | Not needed |
| Multi-step external integrations with dependencies | Flow + `createIntegrationPlan` + `runIntegrationPlan` | Integration Procedure calling same actions | Can wrap with @future or Queueable if timing critical |
| Real-time event-driven orchestration (CDC trigger) | Flow + `publishActionableOrchSrcEvent` | Integration Procedure via CDC trigger | Apex trigger + Platform Event for complex CEP |
| Household rollup calculations (real-time) | Record-Triggered Flow (simple field updates) | Not recommended (async nature of IP) | Apex trigger rollup (synchronous) |
| Bulk migration / batch data processing | Scheduled Flow + Batch Action | Not suitable for bulk | Apex Batch / Queueable (governor limit control) |
| Complex validation with external callouts | Before-save flow (validation) + After-save flow (callout via IP) | OmniScript Integration Action | Apex trigger + Continuation framework |
| Picklist value retrieval in Flow | Flow + `getPicklistValues` invocable action | IP with SOQL fetch | Not needed |
