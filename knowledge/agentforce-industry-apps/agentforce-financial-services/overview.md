---
source: Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata queried from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: overview
last-updated: 2026-05-11
---

# Financial Services Cloud — Overview

## What FSC Is

Financial Services Cloud (FSC) is Salesforce's industry vertical CRM for banking, insurance, wealth management, mortgage and lending organisations. It extends Sales Cloud and Service Cloud with:

- Industry-specific standard objects (InsurancePolicy, Claim, FinancialAccount, FinancialGoal, etc.)
- The Household data model and Actionable Relationship Centre (ARC) for multi-party client relationship management
- Pre-built flows, reports, dashboards, and Lightning record pages tuned for financial services personas
- Agentforce Financial Services integration for AI-driven automation (claims intake, onboarding, servicing)

FSC is delivered as a combination of platform-managed standard objects (no namespace prefix since ~Spring '20) plus managed package components. Older orgs may retain the `FinServ__` namespace prefix on some objects.

## Industry Verticals Covered

| Vertical | Sub-verticals | Key Platform Capabilities |
|---|---|---|
| Insurance | Agencies & Brokerages, P&C, Life & Annuity, Group Benefits, Marine | InsurancePolicy, Claim, InsurancePolicyAsset, InsurancePolicyCoverage, InsurancePolicyParticipant, InsurancePolicyTransaction |
| Banking | Commercial Banking, Retail Banking, Credit Unions, Community Banks | FinancialAccount, FinancialAccountTransaction, BranchUnit, Banker |
| Wealth & Asset Management | Wealth Management, Asset Management | FinancialGoal, FinancialPlan, FinancialSecurity, FinancialGoalFunding |
| Mortgage & Lending | Mortgage, Consumer Lending | FinancialAccount (Type=Loan), LoanApplicationAsset, LoanApplicantIncome |
| Financial Advisory | Independent advisors, practice management | ARC, AccountAccountRelation, ContactContactRelation, Household model |

## Licensing and Edition Requirements

- Base requirement: Salesforce Enterprise or Unlimited Edition
- FSC license add-on required for: FSC standard objects, ARC, Household model
- Insurance feature activation required for: `InsurancePolicy`, `Claim`, `InsurancePolicyCoverage`, `InsurancePolicyParticipant`, `InsurancePolicyAsset`, `InsurancePolicyTransaction`
- Wealth Management feature activation required for: `FinancialGoal`, `FinancialPlan`, `FinancialSecurity`
- Agentforce for FSC: additional license for AI agent capabilities (Claims Agent, Onboarding Agent, etc.)

Not all FSC objects are available without specific feature enablement in FSC Setup. Deploying metadata for a feature that is not activated causes `INVALID_TYPE` errors.

## Key Modules

### Actionable Relationship Centre (ARC)
ARC is a Lightning record page component that renders a visual, interactive map of all relationships for an Account or Contact — household members, business relationships, policies, financial accounts, referral network, and advisors. ARC is configuration-heavy: relationship groups, visible objects, role types, and display rules are defined in Setup → ARC Settings. Some ARC config is stored as custom metadata (deployable); some is UI-only (must be configured per environment).

### Household Model
The household is a standard Account with a special record type. Individual clients are Contacts linked to the household Account via Account-Contact Relationships (ACR). Household aggregation of financial metrics (total assets, total liabilities, total premium) runs asynchronously via managed package rollup fields — not real-time.

Key relationship objects:
- `AccountAccountRelation` — Account-to-Account relationships (household member, business partner, employer)
- `ContactContactRelation` — Contact-to-Contact relationships (beneficiary, advisor, referral)

### Financial Accounts (Banking)
`FinancialAccount` represents a customer's financial account: current/savings account, loan, investment account, or insurance premium payment account. Each account has a `Type` picklist, `Status`, and financial metrics (Balance, CreditLimit, PrincipalAmount, etc.). Child objects: `FinancialAccountTransaction`, `FinancialAccountParty`, `FinancialAccountBalance`, `FinancialAccountFee`, `FinancialAccountStatement`, `FinancialAccountMilestone`.

### Insurance Module
Built around the `InsurancePolicy` object as the central record. Full object hierarchy:
```
InsurancePolicy
  ├── InsurancePolicyCoverage (coverage lines, one per risk section)
  │     └── linked to InsurancePolicyAsset (insured assets)
  ├── InsurancePolicyAsset (physical assets insured under policy)
  ├── InsurancePolicyParticipant (insured, beneficiary, co-insured, broker/agent, insurer)
  ├── InsurancePolicyTransaction (premium billing transactions)
  └── Claim
        ├── ClaimItem (specific loss items)
        ├── ClaimParticipant (claimant, adjuster, witness)
        └── ClaimCoverage (coverage applicable to the claim)
```

Additional insurance objects: `InsuranceContract`, `InsuranceProfile`, `InsuranceRatePlan`, `InsuranceRatePlanLineItem`, `InsuranceRatePlanCommission`, `InsuranceRatingRequest`, `InsurancePolicySurcharge`, `InsurancePolicyTeamMember`, `InsurancePolicyProductClause`, `InsuranceContributionPlan`, `InsuranceAsyncBulkRequest`.

### Financial Goals (Wealth Management)
`FinancialGoal` tracks a client's investment or savings target. Links to `FinancialPlan` (comprehensive financial plan) and is funded via `FinancialGoalFunding`. Associated parties tracked via `FinancialGoalParty`. Requires Wealth Management feature activation.

### Financial Securities
`FinancialSecurity` represents a tradeable security (stock, bond, fund). Used in wealth management to model holdings. Distinct from `FinancialHolding` (which is the FinServ-namespace legacy object in older orgs).

## High-Level Data Flow

```
Client (Account / Person Account)
    │
    ├──► Household Account ──► AccountAccountRelation ──► Other Accounts
    │         │
    │         └──► ContactContactRelation ──► Contacts (family, advisors)
    │
    ├──► InsurancePolicy ──► InsurancePolicyCoverage ──► InsurancePolicyAsset
    │         │                    (coverage lines)         (insured items)
    │         │
    │         ├──► InsurancePolicyParticipant (insured, broker, insurer, beneficiary)
    │         ├──► InsurancePolicyTransaction (billing/premium transactions)
    │         └──► Claim ──► ClaimItem ──► ClaimCoverage
    │                   └──► ClaimParticipant
    │
    └──► FinancialAccount ──► FinancialAccountTransaction
               │
               └──► FinancialGoal ──► FinancialGoalFunding
```

## Integration Points

| Integration | Direction | Pattern |
|---|---|---|
| Policy Admin System (PAS) | Bidirectional | `SourceSystemIdentifier` on most FSC objects for external ID sync; MuleSoft or middleware; bulk API for initial load |
| Core Banking System | Inbound | FinancialAccount + FinancialAccountTransaction sync via batch ETL or event-driven |
| Claims System | Bidirectional | Claim object as lightweight system of engagement; PAS as system of record |
| Data Aggregators (Yodlee, Plaid) | Inbound | FinancialAccount balance and transaction feeds |
| Agentforce / Einstein | Internal | Claims Agent (FNOL), Onboarding Agent, Copilot for FSC |
| Marketing Cloud | Outbound | Client segments, policy anniversary triggers, renewal campaigns |

## API Version Notes

- FSC standard objects (InsurancePolicy, Claim, FinancialAccount, etc.) available as platform-managed objects since API v46.0 (Summer '19) for core objects, later versions for newer objects
- This org runs API v67.0 (Spring '26)
- Objects confirmed present in LKInsuranceDev: InsurancePolicy (189 fields including custom), Claim (142 fields), InsurancePolicyCoverage (81 fields), InsurancePolicyParticipant (75 fields), InsurancePolicyAsset (49 fields), FinancialAccount (43 fields), InsurancePolicyTransaction (30 fields), FinancialGoal (28 fields), ClaimCoverage (24 fields), FinancialAccountTransaction (25 fields), ClaimItem (21 fields), ClaimParticipant (21 fields)

## Key Salesforce Releases Affecting FSC

| Release | Change |
|---|---|
| Summer '19 / API v46 | FSC standard objects promoted to platform-managed (no namespace) |
| Spring '20 | ARC GA; relationship groups configurable |
| Spring '25 | Agentforce Claims Agent GA for insurance (FNOL automation) |
| Winter '26 | ARC enhanced with AI-powered relationship suggestions |
| Spring '26 (v67, April 28, 2026) | Confirmed org version for LKInsuranceDev; Referral object GA (API v66); Get Picklist Values invocable action (API v65); Publish Actionable Orchestration Source Event (API v62); RetrievalSummaryDefinition metadata (API v61) |

## Important Operational Facts

1. **Rollup fields are asynchronous** — FSC managed package household and financial account summary rollups (total assets, total premium) recalculate asynchronously. Not real-time. Do not build business logic that expects immediate rollup updates.

2. **Feature activation is per-org** — Insurance and Wealth features must be activated in FSC Setup. Sandbox refreshes must mirror production feature activation for accurate UAT.

3. **Namespace history** — Pre-Spring '20 orgs use `FinServ__FinancialAccount__c`; modern orgs use `FinancialAccount`. Always verify via EntityDefinition before writing SOQL.

4. **`SourceSystemIdentifier`** — Most FSC objects have this external ID field for integration sync. It is Unique Case-Insensitive on core insurance objects, supporting upsert-based integration patterns.

---

## Standard Invocable Actions (Spring '26)

FSC registers standard invocable actions callable from Flow (via `FlowActionCall`) and via REST (`/services/data/vXX.X/actions/standard/`). Source: fsc_dev_guide.pdf pp.1344–1358.

| Action Name | API Name | Available Since | Purpose |
|---|---|---|---|
| Create Financial Records | `createFinancialRecords` | API v49.0 | Creates person accounts, contacts, financial accounts, properties, assets, and liabilities from a residential loan application (ResidentialLoanApplication record). Input: `recordId`. Outputs: `status`, `personAccountsIdList`, `financialAccountsIdList`, `customerPropertiesIdList`, `assetsAndLiabilitiesIdList`, `errors`. |
| Create Integration Plan | `createIntegrationPlan` | API v60.0 | Creates an integration plan record using Expression Sets to determine eligible integrations and Dynamic Fulfillment Orchestration to create related records. Input: `expressionSetName`, `anchorRecordId`, optionally `contextDefinitionName`, `contextMappingName`, `contextData`, `isTaggedData` (API v61+). Output: `integrationPlanId`. |
| Run Integration Plan | `runIntegrationPlan` | API v60.0 | Triggers an existing integration plan using Dynamic Fulfillment Orchestration — ensures callouts happen in the correct order by queuing each step alongside its dependencies. Input: `integrationPlanId`, optionally `contextId`. Output: `status` (Running, Not Started, Failed). |
| Get Assessment Response Summary | `getAssessmentResponseSummary` | API v56.0 | Retrieves OmniScript-structured summary JSON of assessment question responses for a given assessment record. Used to pass KYC/onboarding assessment data to Document Generation or downstream flows. Input: `assessmentId`. Output: `assessmentResponseSummary` (JSON string). |
| Get Picklist Values | `getPicklistValues` | API v65.0 | Returns picklist values for specified fields of specified objects, optionally filtered by record type ID. Input: `inputData` (JSON with objectName, recordTypeId, fields[]). Output: `outputData` (JSON). |
| Publish Actionable Orchestration Source Event | `publishActionableOrchSrcEvent` | API v62.0 | Publishes an actionable orchestration source event from a Data Object Data Change Event payload. Triggers downstream orchestration rules in Actionable Relationship Centre. Input: `payloadCurrentValue` (required), `sourceObjectDeveloperName` (required), `dataSpace`. No output. |
| Create Case for Fee Reversal | `createCaseForFeeReversal` | API v62.0 | Creates a service case to request a fee reversal for a financial account client. Exposed via `FlowActionCall.actionType`. |

### Flow Integration — FSC-Specific ProcessType and ActionType Values

From fsc_dev_guide.pdf p.1310 (`Flow for Financial Services Cloud` metadata section):

- **`FSCLending`** — a `processType` value on the `Flow` metadata type for Financial Services Cloud Mortgage flows. Available API v46.0+.
- Additional `FlowActionCall.actionType` values exposed by FSC (all callable from Flow Designer):
  - `createCaseForFeeReversal`
  - `createFinancialRecords`
  - `createIntegrationPlan`
  - `getPicklistValues`
  - `publishActionableOrchSrcEvent`
  - `runIntegrationPlan`

---

## IndustriesSettings Metadata

`IndustriesSettings` is the primary org-level settings metadata type for FSC. It is stored as `Industries.settings` in the `settings/` folder and accessed via `<name>Settings</name>` in `package.xml`. Available since API v47.0. Requires the FSC Insurance permission set for access in Insurance editions. Source: fsc_dev_guide.pdf pp.1312–1318.

### Key Insurance Settings

| Setting Field | Default | Purpose |
|---|---|---|
| `allowMultipleProducersToWorkOnSamePolicy` | false | Allows multiple producers assigned to the same insurance policy |
| `enableAccessToMasterListOfCoverageTypes` | false | Grants insurance agents access to the master coverage type list |
| `enableClaimMgmt` | false | Enables FNOL recording, claim participant/coverage/settlement management |
| `enableManyToManyRelationships` | false | Allows multiple claims per case and multiple cases per claim; multiple assets per policy participant |
| `enablePolicyAdministration` | false | Enables policy admin data model including transaction and transaction detail objects |
| `enableFSCInsuranceReport` | false | Grants sales managers access to pre-built insurance dashboard and reports (requires `allowMultipleProducersToWorkOnSamePolicy` = true first) |
| `enableCalculationUsingParentPolicyOnly` | false | Calculates premiums using only the parent policy's premium (for hierarchical policies) |

### Key Banking / Financial Account Settings

| Setting Field | Default | Purpose |
|---|---|---|
| `enableFinancialAccountMgmt` | false | Enables Financial Account Management Standard Objects (FinancialAccountStatement, FinancialAccountTransaction v61+, etc.) |
| `enableDealManagement` | false | Enables FinancialDeal object family (Commercial Banking deal pipeline) |
| `enableFinancialDealRoleHierarchy` | false | Configures role-based hierarchy data sharing for financial deals |
| `enableFinancialDealCallReportPref` | false | Enables junction object between FinancialDeal and Interaction/Interaction Summary |
| `enableB2B` | false | Enables B2B capabilities for commercial banking, business accounts, corporate banking |
| `enableB2BAccountPlan` | false | Enables B2B Account Planning feature |

### Key Mortgage / Lending Settings

| Setting Field | Default | Purpose |
|---|---|---|
| `createFinancialAccountFromLAAsset` | false | Auto-creates FinancialAccount records from loan application assets during import |
| `createFinancialAccountFromLALiability` | false | Auto-creates FinancialAccount records from loan application liabilities during import |
| `createFinancialAccountsFromLAFinancials` | false | Auto-creates a FinancialAccount representing the mortgage loan |
| `createCustomerPropertyFromLAProperty` | false | Auto-creates CustomerProperty from loan application property |
| `createFSCAssetFromLAAsset` | false | Auto-creates Asset records from loan application assets |
| `enableMortgageRlaTotalsOrgPref` | false | Enables calculation of assets/liabilities totals for residential loan applications |
| `loanApplicantAutoCreation` | false | Auto-generates LoanApplicant records for new RLAs linked to person accounts (API v51+) |
| `loanApplicantAddressAutoCreation` | false | Auto-generates LoanApplicant address records for new RLAs linked to person accounts (API v51+) |
| `rlaEditIfAccHasEdit` | false | Restricts RLA editing to users who also have edit access on the account |

### Key Compliance / Sharing Settings

| Setting Field | Default | Purpose |
|---|---|---|
| `enableCompliantDataSharingForAccount` | false | Enables Compliant Data Sharing for Account object |
| `enableCompliantDataSharingForOpportunity` | false | Enables Compliant Data Sharing for Opportunity |
| `enableCompliantDataSharingForInteraction` | false | Enables Compliant Data Sharing for Interaction |
| `enableCompliantDataSharingForInteractionSummary` | false | Enables Compliant Data Sharing for Interaction Summary |
| `enableCompliantDataSharingForCustomObjects` | false | Enables Compliant Data Sharing for custom objects |
| `enableInteractionRoleHierarchy` | false | Enables role-hierarchy-based sharing for Interactions |
| `enableInteractionSummaryRoleHierarchy` | false | Enables role-hierarchy-based sharing for Interaction Summaries |

### Key AI / Einstein Settings

| Setting Field | Default | Purpose |
|---|---|---|
| `enableReferralScoring` | false | Enables Einstein Referral Scoring for FSC |
| `enableAccountScoreEnabled` | false | Enables Account Scoring/rating capabilities for financial accounts |
| `enableB2BEinstein` | false | Enables Einstein AI features for B2B Financial Services |
| `enableWealthManagementAIPref` | false | Enables AI features for Wealth Management (API v63+) |
| `enableCollectionRiskScoringCFE` | false | Enables AI-powered risk scoring for collections accounts |

### Key Discovery Framework Settings

| Setting Field | Default | Purpose |
|---|---|---|
| `enableDiscoveryFrameworkMetadata` | false | Enables AssessmentQuestion and AssessmentQuestionSet metadata features |
| `enableIndustriesAssessment` | false | Enables Industries Assessment feature of Discovery Framework |
| `enableIndustriesKYC` | false | Enables Industries KYC (Know Your Customer) |
| `enableEnhancedQuestionCreation` | false | Enables Enhanced Question Creation for Discovery Framework |

### Deployment Note

`IndustriesSettings` is deployed as part of `Settings` metadata type:
```xml
<types>
  <members>Industries</members>
  <name>Settings</name>
</types>
<version>47.0</version>
```

---

## Apex Triggers in FSC

Source: fsc_dev_guide.pdf p.11 (intro), pp.1109–1120 (Apex reference).

The FSC developer guide notes that Apex triggers, classes, and components in the **FSC managed package** carry the `FinServ__` namespace prefix and are **one API version behind** the core Salesforce API. Standard FSC objects (InsurancePolicy, Claim, FinancialAccount, etc.) are platform-managed and match the current API version.

### FSC Apex Namespaces

| Namespace | Purpose |
|---|---|
| `commonserviceexcellence` | Provides `IntegrationHandler` class used by financial account FlexCards and Integration Procedures. Cannot be used in DML operations. |
| `disputemanagement` | Provides `DisputeMgmtHelper` class for Transaction Dispute Management OmniScript (raise disputes, create merchant alerts, validate transactions). Cannot be used in DML operations. |
| `fsccashflow` | Provides `FSCCashFlowUtil` class for managing party income/expense entities in FSCCashFlow FlexCards. |

### commonserviceexcellence.IntegrationHandler

Key callable class for real-time financial account data retrieval. Main methods:
- `call(action, args)` — dispatches to sub-actions: `executeOmniCallback`, `getContinuation`, `getTransactionProperties`
- `executeCallout(requestId, payload, devName)` — calls the provider class defined in an Integration Definition record
- `getOmniContinuation(...)` / `getLightningContinuation(...)` — retrieves Continuation objects for async callouts from Integration Procedures or LWC
- `getTransactionProperties` action — checks if `Fetch Real Time Financial Account Info` preference is enabled; controls whether FlexCards pull live data from core banking vs. cached Salesforce data

### disputemanagement.DisputeMgmtHelper

Key callable class for transaction disputes. Primary actions via `call(action, args)`:
- `raiseDispute` — assembles transaction dispute data, creates related objects, returns summary (caseId, caseNumber, svcCatalogRequestId)
- `createDisputeItemMerchAlert` — creates a merchant alert for disputed transactions
- `filterTransactions` — separates transactions into Disputed, Valid, ClearForWriteOff, Invalid lists
- `validateDisputedTransactions` — validates disputed amounts for errors
- `generateRequestGuid` — creates a GUID for the dispute request

### Trigger Deployment Notes

- When writing Apex triggers on FSC standard objects, use the platform object API names (`InsurancePolicy`, `Claim`, etc.) — no namespace prefix needed for modern orgs
- Triggers on FSC managed package custom objects (those with `FinServ__` prefix in legacy orgs) must reference the namespace prefix
- The standard trigger best-practice pattern applies: one trigger per object, all logic in handler classes; use static recursion guard for flows + triggers on the same object
