---
source: Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata queried from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Financial Services Cloud — Implementation Guide

---

## Pre-Implementation Checklist

Before writing a single line of code or configuration, verify these items in the target org:

1. **FSC license confirmed** — Account has FSC license; check Setup → Company Information → User Licenses
2. **Feature activation confirmed** — Insurance and/or Wealth Management features activated in Setup → Financial Services Cloud → Feature Activation
3. **FSC version identified** — Query `InstalledSubscriberPackage` to confirm FSC managed package version; note whether objects use `FinServ__` namespace or platform-managed standard names
4. **API version** — Establish target API version (this org: v67.0, Spring '26); use consistent version across all tooling
5. **Object availability verified** — Run FieldDefinition query on InsurancePolicy, Claim, FinancialAccount to confirm expected fields exist before designing against them
6. **ARC configuration scope** — Determine which relationship types and objects ARC must display; plan ARC setup as a dedicated configuration sprint

---

## Setup Sequence by Module

### Module 1: Insurance — Setup Sequence

Follow this order. Dependencies will cause failures if out of sequence.

```
Step 1: Activate Insurance Feature
  → Setup → Financial Services Cloud → Feature Activation → Insurance: ON
  → Activates: InsurancePolicy, Claim, InsurancePolicyCoverage, InsurancePolicyParticipant,
                InsurancePolicyAsset, InsurancePolicyTransaction

Step 2: Configure OWD (Sharing Settings)
  → InsurancePolicy: Private
  → Claim: Private
  → Child objects: Controlled by Parent (Coverage, Participant, Asset, Transaction, ClaimItem, etc.)

Step 3: Create Record Types
  → InsurancePolicy: Commercial Lines, Personal Lines, Marine, Life, Group
  → Claim: Property, Liability, Auto, Marine, Life, Group
  → (Must match policy admin system line of business categories)

Step 4: Configure Picklist Values
  → InsurancePolicy.Status: InForce, Pending, Cancelled, Lapsed, Expired, Quoted, Bound
  → InsurancePolicy.PolicyType: values per product catalogue
  → InsurancePolicy.LineOfBusiness: values aligned to LOB1/LOB2/LOB3 custom fields
  → Claim.Status: New, Under Review, Pending Documentation, Settled, Denied, Closed
  → InsurancePolicyParticipant.Role: Insured, Co-Insured, Beneficiary, Broker, Co-Broker, Insurer, Underwriter

Step 5: Create/Deploy Custom Fields
  → Deploy custom fields on InsurancePolicy, InsurancePolicyCoverage, InsurancePolicyParticipant, Claim
  → All custom fields must exist before validation rules that reference them

Step 6: Deploy Validation Rules
  → InsurancePolicy: EffectiveDate before ExpirationDate, UniversalPolicyNumber required
  → Claim: LossDate not in future, PolicyNumberId required, required fields per record type
  → InsurancePolicyParticipant: at least one Insured role per policy (check via before-save flow)

Step 7: Create Page Layouts and Lightning Pages
  → InsurancePolicy: Header (policy core fields), Related lists (Coverages, Participants, Claims, Transactions)
  → Claim: Header (claim core), Related lists (ClaimItems, ClaimParticipants, ClaimCoverages)
  → Add ARC component to InsurancePolicy and Account Lightning pages

Step 8: Configure Assignment Rules (Claims)
  → Create Claim Assignment Rules: assign by ClaimType, LOB, geographic region, or team
  → Create Queue per claims team (Property, Liability, Marine, etc.)

Step 9: Build Core Flows
  → FNOL Screen Flow (policy lookup → loss details → create Claim)
  → Policy inception Screen Flow (coverage details → participants → premium → create policy)
  → Policy renewal Scheduled Flow (notify 60 days before expiry)
  → Claim status progression Record-Triggered Flow

Step 10: Deploy Permission Sets
  → FSC_Claims_Access, FSC_Advisor_Access, FSC_Finance_Access, FSC_Compliance_Access
  → Assign to users post-deployment

Step 11: Data Migration
  → Load InsurancePolicy via Bulk API 2.0 using SourceSystemIdentifier as external ID
  → Load InsurancePolicyCoverage (requires InsurancePolicyId — use PolicyId from prior step)
  → Load InsurancePolicyParticipant (requires InsurancePolicyId)
  → Load InsurancePolicyAsset
  → Load Claims (historic closed claims for reference)
```

### Module 2: Financial Accounts (Banking) — Setup Sequence

```
Step 1: Activate Banking Feature (if applicable)
  → Setup → Financial Services Cloud → Feature Activation → Banking: ON

Step 2: Configure FinancialAccount Record Types
  → Checking, Savings, Term Deposit, Current Loan, Mortgage, Investment

Step 3: Set Picklist Values
  → FinancialAccount.Type: Savings, Checking, CD, MoneyMarket, Investment, Loan, Mortgage, Other
  → FinancialAccount.Status: Open, Closed, Frozen, PendingClose
  → FinancialAccount.InterestType: Fixed, Variable, Mixed
  → FinancialAccountTransaction.Type: Deposit, Withdrawal, Transfer, Fee, Interest, Payment
  → FinancialAccountTransaction.DebitCreditIndicator: Debit, Credit

Step 4: Configure Banker and BranchUnit Records
  → Create Banker records (FSC object for relationship managers)
  → Create BranchUnit records (FSC object for branch locations)
  → Link BankerId and BranchUnitId on FinancialAccount records

Step 5: Configure Sharing
  → FinancialAccount: Private
  → FinancialAccountTransaction: Controlled by Parent
  → Sharing rule: grant joint account holder access via AccountTeamMember or FinancialAccountParty

Step 6: Build Integration
  → FinancialAccount sync from core banking: upsert on SourceSystemIdentifier (External Lookup)
  → FinancialAccountTransaction feed: daily batch or real-time via Platform Events
```

### Module 3: Household Model and ARC — Setup Sequence

```
Step 1: Create Household Account Record Type
  → Account record type: Household
  → This unlocks ARC household features

Step 2: Configure Relationship Types
  → Setup → Relationship Settings → AccountAccountRelation Roles
     Add: Household Member, Employer, Business Partner, Subsidiary, Referral
  → Setup → Relationship Settings → ContactContactRelation Roles
     Add: Spouse, Child, Parent, Advisor, Attorney, Accountant, Referral

Step 3: ARC Configuration
  → Setup → ARC Settings → Create Relationship Groups
     Example groups: Household (shows household members), Policy Network (shows policies + participants)
  → Configure which objects display in each group
  → Configure visible fields per object tile
  → Note: some ARC settings are UI-only; must be repeated in each environment

Step 4: Add ARC Component to Pages
  → Account Lightning Page: add "Actionable Relationship Centre" component
  → InsurancePolicy Lightning Page: add ARC component showing policy participant network

Step 5: Configure Household Rollups
  → FSC managed package rolls up household financial metrics asynchronously
  → For real-time metrics: build custom Apex trigger rollups on FinancialAccount balance changes
  → Do NOT build flows that depend on rollup field values being current immediately after DML
```

### Module 4: Financial Goals (Wealth Management) — Setup Sequence

```
Step 1: Activate Wealth Management Feature
  → Setup → Financial Services Cloud → Feature Activation → Wealth Management: ON
  → Activates: FinancialGoal, FinancialPlan, FinancialSecurity, FinancialGoalFunding

Step 2: Configure Picklists
  → FinancialGoal.Type: Retirement, Education, Home Purchase, Emergency Fund, Other
  → FinancialGoal.Category: Short-term, Medium-term, Long-term
  → FinancialGoal.Status: NotStarted, InProgress, Achieved, Cancelled
  → FinancialGoal.Priority: High, Medium, Low
  → FinancialGoal.Frequency (withdrawal): Monthly, Quarterly, Annual, OneTime

Step 3: Link Goals to Clients
  → Create FinancialPlan linked to Account
  → Create FinancialGoal with FinancialPlanId
  → Create FinancialGoalParty linking Goal to Account/Contact with advisory role
```

---

## Key Configuration Objects and Dependencies

| Configuration Object | Depends On | Required Before |
|---|---|---|
| `InsurancePolicyCoverage` records | `InsurancePolicy` (parent) | None |
| `InsurancePolicyParticipant` records | `InsurancePolicy` (parent), `Account`/`Contact` | ClaimParticipant |
| `Claim` records | `InsurancePolicy` (PolicyNumberId) | ClaimItem, ClaimParticipant, ClaimCoverage |
| `ClaimCoverage` records | `Claim` + `InsurancePolicyCoverage` | None |
| `FinancialAccountTransaction` | `FinancialAccount` (parent) | None |
| `FinancialGoal` | `FinancialPlan` (optional) | FinancialGoalFunding, FinancialGoalParty |
| Custom fields on standard objects | Standard object exists in org | Validation rules that reference them |
| ARC component | Relationship types configured | None |
| Household rollups (managed pkg) | Household Account record type active | Async — not immediate |

---

## Permission Sets Required by Module and Persona

### Insurance Module

| Persona | Required Permission Sets | Key Object Access |
|---|---|---|
| Insurance Advisor / Account Manager | `FSCInsurance` + `FSC_Advisor_Access` | CRUD InsurancePolicy, Read Claim |
| Claims Adjuster | `FSCInsurance` + `FSC_Claims_Access` | CRUD Claim, ClaimItem, ClaimParticipant, ClaimCoverage; Read InsurancePolicy |
| Underwriter | `FSCInsurance` + `FSC_Underwriter_Access` | CRUD InsurancePolicy, InsurancePolicyCoverage; Read Claim |
| Finance / Accounting | `FSC_Finance_Access` | CRUD reconciliation objects; Read InsurancePolicy, Claim |
| Compliance / Audit | `FSC_Compliance_Access` | Read-only all FSC objects |
| Platform Admin | `FSC_Admin_Access` + System Admin profile | Full access |

### Banking Module

| Persona | Required Permission Sets | Key Object Access |
|---|---|---|
| Relationship Manager / Banker | `FSCBanking` + `FSC_Banker_Access` | CRUD FinancialAccount; Read FinancialAccountTransaction |
| Branch Manager | `FSCBanking` + `FSC_BranchManager_Access` | Read all branch accounts; CRUD assignments |
| Operations | `FSC_Operations_Access` | CRUD FinancialAccountTransaction feeds |

---

## Integration Patterns

### Pattern 1: Policy Admin System (PAS) → Salesforce (Inbound)

**Use case:** Policy data mastered in PAS; Salesforce is system of engagement.

```
PAS triggers event on policy change
    → Platform Event published to Salesforce (or MuleSoft/Mule publishes)
    → Salesforce Event Handler Flow/Apex upserts InsurancePolicy
       using SourceSystemIdentifier as external ID (Unique Case-Insensitive)
    → Upserts InsurancePolicyCoverage using Coverage SourceSystemIdentifier
    → Upserts InsurancePolicyParticipant using Participant SourceSystemIdentifier

Key fields:
  InsurancePolicy.SourceSystemIdentifier = PAS Policy ID
  InsurancePolicyCoverage.SourceSystemIdentifier = PAS Coverage Line ID
  InsurancePolicyParticipant.SourceSystemIdentifier = PAS Participant ID
```

### Pattern 2: Salesforce → PAS (Outbound)

**Use case:** Policy bound in Salesforce; instruction sent to PAS for issuance.

```
InsurancePolicy created/updated in Salesforce
    → Record-Triggered Flow (After Save, Status = 'Bound')
    → Callout to MuleSoft/middleware with policy payload
    → PAS acknowledges with PAS Policy Number
    → Callback upserts InsurancePolicy.SourceSystemIdentifier = PAS ID
```

### Pattern 3: Core Banking → Salesforce FinancialAccount Sync

```
Nightly batch from core banking system
    → Bulk API 2.0 upsert on FinancialAccount
       externalIdFieldName = SourceSystemIdentifier
    → Bulk API 2.0 upsert on FinancialAccountTransaction
       externalIdFieldName = SourceSystemIdentifier

Note: FinancialAccount.SourceSystemIdentifier is External Lookup type
(not standard Text Unique) — different behaviour from insurance objects.
```

### Pattern 4: Claims System Integration

```
Claim opened in Salesforce (FNOL via screen flow)
    → Salesforce Claim.Id shared with external claims system
    → Claims system updates: EstimatedAmount, Status, AdjusterId
    → Updates flow back via Platform Event → Apex/Flow upsert on Claim.SourceSystemIdentifier
    → ClaimItem records sync per loss item
    → ClaimCoverage sync per coverage reserve
```

---

## Key Governor Limits and FSC Considerations

| Limit | Impact on FSC | Mitigation |
|---|---|---|
| SOQL 100 queries per transaction | InsurancePolicy with many related children can exhaust quickly | Use aggregate subqueries; batch processing for multi-object operations |
| DML 150 rows per transaction | Bulk policy inception (many coverages, participants) may hit limit | Use Apex batch or @future for large bulk operations |
| SOQL timeout (120s) | `Claim` and `FinancialAccountTransaction` objects accumulate millions of records | Always include date range filters; add indexed custom fields for common query patterns |
| Heap 6MB / 12MB (async) | Large JSON payloads from PAS integration | Chunked processing; streaming rather than full payload in memory |
| Trigger recursion | FSC record-triggered flows + Apex triggers on same object can recurse | Use static variable recursion guard in Apex; design flows to fire before-save only for validation |
| Rollup limits | FSC managed package rollups count against the 25 rollup limit | Track rollup count early; plan custom aggregate Apex if approaching limit |
| Field History Tracking | Max 20 fields per object | Prioritise high-value audit fields (Status, PremiumAmount, ClaimAmount) |

---

## Important Callouts from FSC Documentation

### Feature Activation is Irreversible

Once Insurance or Wealth Management features are activated in an org, they cannot be deactivated. Activate in scratch orgs for development and in sandboxes refreshed from production for testing. Do not activate in a sandbox unless you intend to activate in production.

### ARC Configuration is Environment-Specific

ARC relationship group configuration stored in `Custom Metadata` is deployable. However, UI-only ARC settings (component visibility, object tile display preferences) must be re-configured manually in each environment after sandbox refresh. Document these settings in the deployment runbook.

### Household Rollups Are Async — Not Real-Time

The FSC managed package calculates household financial summaries asynchronously via platform events. After inserting a FinancialAccount record, the household total assets field will NOT reflect the new account immediately. Do not write Apex tests or flows that assert rollup values in the same transaction as the DML.

### InsurancePolicyParticipant.Role is Multi-Select Picklist

`InsurancePolicyParticipant.Role` is `Picklist (Multi-Select)`. In SOQL, use `INCLUDES` rather than `=`:
```soql
SELECT Id FROM InsurancePolicyParticipant
WHERE InsurancePolicyId = :policyId
AND Role INCLUDES ('Insured')
```

### SourceSystemIdentifier Uniqueness Enforcement

`SourceSystemIdentifier` on `InsurancePolicyCoverage`, `InsurancePolicyParticipant`, `InsurancePolicyAsset`, and `ClaimParticipant` is **Unique Case-Insensitive**. Integration upserts that attempt duplicate `SourceSystemIdentifier` values will throw `DUPLICATE_VALUE` errors. The external system must guarantee unique IDs per record before sending to Salesforce.

### Policy Hierarchy via Prior/Original/Renewed Links

InsurancePolicy supports a full version/endorsement/renewal hierarchy:

| Field | Purpose |
|---|---|
| `OriginalPolicyId` | Points to the very first version of this policy |
| `PriorPolicyId` | Points to the immediately preceding version |
| `ParentPolicyId` | Points to the parent policy (for sub-policies) |
| `RenewedFromPolicyId` | Points to the policy this was renewed from |
| `SourcePolicyId` | Integration source policy reference |

Design the integration to correctly set these fields during initial load and renewal cycles.

### Claim Does Not Auto-Link to InsurancePolicyCoverage

`Claim` links to `InsurancePolicy` via `PolicyNumberId`, but does NOT automatically create `ClaimCoverage` records. The claims intake process (FNOL flow or integration) must explicitly create `ClaimCoverage` records linking the claim to the specific `InsurancePolicyCoverage` lines applicable to the loss. This is a frequent gap in initial implementations.

### Multi-Currency

FSC financial fields (`PremiumAmount`, `LimitAmount`, `ActualAmount`, etc.) are in the record's `CurrencyIsoCode`. When multi-currency is enabled:
- Reporting in corporate currency uses Salesforce's dated exchange rates (close date of the record)
- For audit compliance, store the exchange rate used at transaction time in a custom field (e.g., `ExchangeRate__c` on InsurancePolicyParticipant in this org)
- Do not rely solely on Salesforce dated exchange rates for financial reporting — they can be overwritten

---

## Deployment Runbook Template

A standard FSC deployment should follow this sequence:

1. **Validate only deploy** — `sf project deploy start --dry-run` or MCP `deploy_metadata` with `checkOnly: true`
2. **Confirm no blocking test failures** — all Apex tests pass with ≥75% coverage
3. **Confirm feature activation** matches between source and target org
4. **Deploy metadata** in order: objects → fields → validation rules → flows → permission sets → layouts
5. **Run post-deploy data validation queries** — verify record counts, spot-check key records
6. **Configure ARC settings** manually (UI-only settings)
7. **Assign permission sets** to users
8. **Smoke test** each key user persona: Advisor, Claims Adjuster, Finance

---

## IndustriesSettings Activation Sequence

Source: fsc_dev_guide.pdf pp.1312–1318. Enable IndustriesSettings in this order to avoid dependency failures. All fields are boolean; default is false unless noted.

### Phase 1 — Core Feature Enablement (enable first, no dependencies)

```
1. enableClaimMgmt                      → enables FNOL, claim participants, coverages, settlements
2. enableFinancialAccountMgmt           → enables Financial Account Management Standard Objects
3. enableDealManagement                 → enables FinancialDeal object family
4. enablePolicyAdministration           → enables policy admin data model (transactions/details)
5. allowMultipleProducersToWorkOnSamePolicy → enables multi-producer on same policy
```

### Phase 2 — Discovery Framework (depends on Phase 1 base license)

```
6. enableDiscoveryFrameworkMetadata     → enables AssessmentQuestion/Set metadata
7. enableIndustriesAssessment           → enables Industries Assessment feature
8. enableIndustriesKYC                  → enables KYC workflow
9. enableEnhancedQuestionCreation       → enables enhanced question creation UX
```

### Phase 3 — Sharing and Compliance (enable after object/permission set deployment)

```
10. enableCompliantDataSharingForAccount         → CDS for Account
11. enableCompliantDataSharingForOpportunity     → CDS for Opportunity
12. enableCompliantDataSharingForInteraction     → CDS for Interaction
13. enableCompliantDataSharingForInteractionSummary → CDS for Interaction Summary
14. enableCompliantDataSharingForCustomObjects   → CDS for custom objects
15. enableInteractionRoleHierarchy               → role hierarchy sharing for Interactions
16. enableInteractionSummaryRoleHierarchy        → role hierarchy sharing for Interaction Summaries
17. enableFinancialDealRoleHierarchy             → role hierarchy sharing for Financial Deals
```

### Phase 4 — Reporting and AI (enable after core features and data is present)

```
18. enableFSCInsuranceReport            → pre-built insurance dashboard (REQUIRES allowMultipleProducers = true first)
19. enableReferralScoring               → Einstein Referral Scoring
20. enableAccountScoreEnabled           → Account Scoring
21. enableB2BEinstein                   → Einstein AI for B2B
22. enableWealthManagementAIPref        → AI for Wealth Management (API v63+)
```

### Phase 5 — Mortgage/Lending Data Automation (enable before using createFinancialRecords action)

```
23. createFinancialAccountFromLAAsset       → creates FA from loan application assets
24. createFinancialAccountFromLALiability   → creates FA from loan application liabilities
25. createFinancialAccountsFromLAFinancials → creates FA for mortgage loan
26. createFinancialAccountsFromLAProperty   → creates FA from property record
27. createCustomerPropertyFromLAProperty    → creates CustomerProperty from LA property
28. createFSCAssetFromLAAsset               → creates Asset from LA asset
29. createFSCAssetFromLAProperty            → creates Asset from LA property
30. createFSCLiabilityFromLAFinancial       → creates Liability from LA financial
31. createFSCLiabilityFromLALiability       → creates Liability from LA liability
32. enableMortgageRlaTotalsOrgPref          → enables assets/liabilities totals on RLA
33. loanApplicantAutoCreation               → auto-creates LoanApplicant records
34. loanApplicantAddressAutoCreation        → auto-creates LoanApplicant address records
35. rlaEditIfAccHasEdit                     → restricts RLA editing by account access
```

**Critical rule:** Never enable `enableFSCInsuranceReport` before `allowMultipleProducersToWorkOnSamePolicy`. The setting silently fails or produces configuration errors.

---

## Financial Deal Management Setup

Source: fsc_dev_guide.pdf pp.323–340 (FinancialDeal object), p.1315 (IndustriesSettings).

```
Step 1: Enable Deal Management Feature
  → IndustriesSettings: enableDealManagement = true
  → This activates FinancialDeal, FinancialDealParty, FinancialDealParticipant,
    FinancialDealBid, FinancialDealAsset, FinancialDealInteraction

Step 2: Configure Role Hierarchy Sharing (optional)
  → IndustriesSettings: enableFinancialDealRoleHierarchy = true
  → When enabled, deal data sharing follows role-based hierarchy
  → When disabled (default), sharing is controlled by OWD and manual sharing rules only

Step 3: Configure FinancialDeal OWD
  → Recommended: Private (bankers see only their deals; managers see via hierarchy)
  → FinancialDealParty and FinancialDealParticipant: Controlled by Parent

Step 4: Configure ParticipantRole Metadata (optional)
  → Deploy ParticipantRole records for FinancialDeal parent object
  → Valid parentObject values for FinancialDeal: 'FinancialDeal' (API v52+)
  → ParticipantRole controls defaultAccessLevel (None, Read, Edit) for participants

Step 5: Configure Interaction Integration (optional)
  → IndustriesSettings: enableFinancialDealCallReportPref = true
  → Enables junction object between FinancialDeal and Interaction/Interaction Summary
  → IndustriesSettings: enableFinancialDealCallReportCmpPref = true
  → Enables admin config of Account Interactions component for FinancialDeal

Step 6: Build Deal Pipeline Flow
  → Screen Flow for deal creation: Stage = 'Pitch', Role, FinancialDealType
  → Record-Triggered Flow on FinancialDeal | Before Save | Stage changes
    → Validate: Mandate date required when Stage = 'Mandate'
    → Validate: TransactionValue required when Stage = 'Execution'
  → Assign FinancialDealParticipant records for internal deal team members

Step 7: Deploy Permission Sets
  → Create FSC_DealTeam_Access: CRUD on FinancialDeal, FinancialDealParty,
    FinancialDealBid; Read on FinancialDealParticipant
  → Create FSC_DealAdmin_Access: CRUD on all FinancialDeal objects
```

---

## Referral Management Setup

Source: fsc_dev_guide.pdf pp.836–847 (Referral object), p.1317 (enableReferralScoring).

```
Step 1: Confirm API Version
  → Referral standard object requires API v66.0 or later
  → Check target org API version before attempting to use Referral object
  → Pre-Spring '26 orgs: custom Referral__c object is still in use — migrate after upgrade

Step 2: Enable Einstein Referral Scoring (optional)
  → IndustriesSettings: enableReferralScoring = true
  → Enables AI-powered ReferralScore field population
  → Requires Einstein Referral Scoring add-on license

Step 3: Configure Referral OWD
  → Referral: Private (owner-based access)
  → Or: Controlled by Parent if referrals are child of another object

Step 4: Configure Picklist Values
  → Referral.Category: per business need (e.g., Insurance, Wealth, Mortgage, Banking)
  → Referral.Priority: High, Medium, Low
  → Referral.ReferralType: INBOUND (default), OUTBOUND — restricted picklist, do not add values

Step 5: Build Referral Intake Flow
  → Screen Flow:
    Screen 1: Client information (ClientId or ClientName, ClientEmail, ClientPhone)
    Screen 2: Referral details (Category, Priority, Product2Id, ProviderId)
    Screen 3: Review and confirm
    Action: Create Referral (ReferralType = 'INBOUND', AuthorizationStatus = 'Submitted')
    Action: Create Task for advisor to follow up

Step 6: Build Referral Status Flow
  → Record-Triggered Flow on Referral | Before Save | AuthorizationStatus changes
    Decision: Status = 'Authorized'
      → Create Opportunity linked to Referral.OpportunityId
      → Send notification to ProviderId/ProviderEmail
    Decision: Status = 'Rejected'
      → Send decline notification to ReferrerId

Step 7: Add Referral Related List to Account Page
  → Add Referral related list to Account Lightning Page
  → Fields to show: Name, ReferralDate, ReferralType, Category, Status, EstimatedReferralValue

Step 8: Permission Sets
  → Add Referral: Read to FSC_Advisor_Access
  → Add Referral: CRUD to FSC_ReferralManager_Access (dedicated referral team)
```
