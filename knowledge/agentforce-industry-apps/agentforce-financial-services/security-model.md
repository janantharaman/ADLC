---
source: hand-authored; supplemented from Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: security-model
last-updated: 2026-05-11
---

# Financial Services Cloud — Security Model

## FSC-Specific Security Concerns

FSC handles financial data — the most sensitive category in most Salesforce orgs. Key security priorities:
1. **Least privilege is non-negotiable:** Financial data exposure carries regulatory and reputational risk
2. **Audit trail must be complete:** Enable Field History Tracking on all financial objects
3. **Segregation of duties:** Who creates vs. approves vs. reconciles must be different roles

## OWD Recommendations

| Object | Internal OWD | Notes |
|---|---|---|
| InsurancePolicy | Private | Advisor/agent sees only their policies; claims team accesses via permission set |
| Claim | Private | Adjuster owns claim; supervisor sees via hierarchy |
| FinancialAccount | Private | Advisor sees client financial accounts; no broader access |
| FinancialHolding | Controlled by Parent | Inherits FinancialAccount sharing |
| Account (client) | Private | Advisor sees their book of business |
| Opportunity (policy deal) | Private | Advisor sees their pipeline |
| Reconciliation objects | Private | Finance team only |
| Settlement objects | Private | Finance team only |

**High risk to flag:** Any financial sequencing object (contract number management, policy number sequences, invoice numbering) must have OWD = `Private`. Public Read/Write on sequencing objects allows any user to corrupt sequential numbering, causing duplicate numbers and reconciliation failures — a regulatory risk in regulated financial orgs.

## Permission Set Design

| Permission Set | Who Gets It | What It Grants |
|---|---|---|
| `FSC_Advisor_Access` | Client advisors / relationship managers | CRUD on InsurancePolicy, FinancialAccount, Opportunity; Read on Claim |
| `FSC_Claims_Access` | Claims adjusters | CRUD on Claim; Read on InsurancePolicy/Account; no financial account editing |
| `FSC_Finance_Access` | Finance team | CRUD on Reconciliation, Settlement, BankTransaction, PeriodClose; no client data editing |
| `FSC_Compliance_Access` | Compliance/audit team | Read All on all FSC objects; no edit permissions |
| `FSC_Admin_Access` | Platform/IT admin | Full access including FSC configuration objects |

## Profile Right-Sizing

FSC engagements frequently inherit orgs where a large proportion of users are on the System Administrator profile. This is the most common FSC security anti-pattern — Sys Admin users can view all financial data, modify audit trails, change OWD, and bypass validation rules. Always audit active users by profile during Discovery and right-size each user to the minimum required profile + permission sets before delivering new features.

## Advisor Relationship Model

FSC uses `Account.OwnerId` for primary advisor ownership, but financial clients often have multiple advisors (lead advisor, service advisor, specialist). Model this via:
- `AccountTeamMember` (standard) for secondary advisors
- `AccountAccountRelation` for formal advisory relationships with named roles
- Sharing rules that grant AccountTeamMember access to FinancialAccount and InsurancePolicy records owned by the primary advisor

## Segregation of Duties for Finance

Critical for insurance and banking:
- **Reconciliation approval:** Require a different user from the reconciliation creator to approve — use Approval Process with `Cannot approve own records = true`
- **Settlement authorisation:** Settlement amounts above threshold require dual sign-off — implement as two-step Approval Process
- **Period close:** Only the Finance Director role should be able to submit a period close — enforce via validation rule checking `$Profile.Name` or a `Period_Close_Authoriser` permission

## Household OWD and Joint Account Access

In FSC wealth management, a household Account owns FinancialAccount records. Both joint account holders need access. Model via:
- `FinancialAccountRole` (FSC object) with role = 'Joint Owner' or `InsurancePolicyParticipant` with role = 'Joint Insured'
- Sharing rule: grant FinancialAccount Read to users associated with joint owner's Contact → User chain
- Do NOT set FinancialAccount OWD to Public Read — grant access at individual record level via sharing

## Multi-Currency in FSC

FSC financial objects store amounts in the record currency. Reporting in corporate currency uses dated exchange rates at the record's close date, not today's rate. Design must specify:
- Which currency fields use `CurrencyIsoCode` (most FSC financial fields do)
- How exchange rate snapshots are maintained for audit — store the rate used at transaction time in a custom field rather than relying solely on Salesforce dated exchange rates

---

## Compliant Data Sharing (CDS)

Source: fsc_dev_guide.pdf pp.1312–1315 (IndustriesSettings, AccountRelationshipShareRule metadata).

### What Compliant Data Sharing Is

Compliant Data Sharing is an FSC feature that provides rule-based, regulation-aware record access beyond standard Salesforce OWD and sharing rules. It is designed for regulated financial data scenarios where access to a client's data must be explicitly controlled and auditable — for example, preventing bankers from accessing client records unless there is a documented relationship.

CDS works alongside standard Salesforce sharing — it does not replace OWD, but adds an additional layer that can grant or restrict access based on relationship type and user attributes. CDS is enforced at query time and visible in access logs.

### CDS Metadata Type: AccountRelationshipShareRule

`AccountRelationshipShareRule` metadata type defines which records are shared, how they are shared, the account relationship type that drives sharing, and the access level granted. FSC Insurance extends this type with additional values. Source: fsc_dev_guide.pdf p.1299.

**FSC-specific `accountToCriteriaField` values** (criteria that must be met for sharing to apply):
- `BusinessMilestone.OwnerId`
- `BusinessMilestone.PrimaryAccountId`
- `Claim.AccountId`
- `Claim.OwnerId`
- `CustomerProperty.OwnerId`
- `CustomerProperty.PrimaryOwnerId`
- `InsurancePolicy.NameInsuredId`
- `InsurancePolicy.OwnerId`
- `PersonLifeEvent.OwnerId`

**FSC-specific `entityType` values** (the type of data shared by this rule):
- `BusinessMilestone`
- `Claim`
- `CustomerProperty`
- `InsurancePolicy`
- `PersonLifeEvent`

### IndustriesSettings — CDS Toggle Fields

These `IndustriesSettings` boolean fields control whether Compliant Data Sharing is active for each object:

| Setting | Default | Object Controlled |
|---|---|---|
| `enableCompliantDataSharingForAccount` | false | Account object |
| `enableCompliantDataSharingForOpportunity` | false | Opportunity object |
| `enableCompliantDataSharingForInteraction` | false | Interaction object |
| `enableCompliantDataSharingForInteractionSummary` | false | Interaction Summary object |
| `enableCompliantDataSharingForCustomObjects` | false | Custom objects |

### When to Use CDS vs Standard Salesforce Sharing

| Scenario | Recommended Approach |
|---|---|
| Advisor sees only their own clients (OWD=Private, hierarchy grants manager access) | Standard OWD + Role Hierarchy |
| Claims team must see policies when a claim is filed | Standard Criteria-based Sharing Rule on InsurancePolicy (Status = 'Claim Filed') |
| Regulated access: banker can only access client data if there is an active documented relationship | Compliant Data Sharing with AccountRelationshipShareRule |
| Compliance audit trail required for all data access by relationship type | Compliant Data Sharing |
| Multi-client household: joint account holder access | Standard sharing via FinancialAccountParty + sharing rule |

### CDS Deployment Note

Enabling CDS for an object in IndustriesSettings is a one-way toggle — test in sandbox before enabling in production. Once enabled, sharing recalculation runs across all existing records of the affected object, which can be a long-running operation in production orgs with large data volumes. Plan the activation window during low-traffic hours.

---

## IndustriesSettings — Security-Relevant Toggles

The following `IndustriesSettings` fields directly affect data visibility, access control, or compliance. Source: fsc_dev_guide.pdf pp.1312–1318.

| Setting | Default | Security/Access Impact |
|---|---|---|
| `enableClaimMgmt` | false | Must be enabled before claim participants, coverages, and settlements can be created or managed |
| `enableManyToManyRelationships` | false | When true, allows multiple claims per case — creates many-to-many data access paths that must be accounted for in sharing rules |
| `enableFinancialDealRoleHierarchy` | false | When true, financial deal data sharing follows role-based hierarchy; when false, deal access is controlled by OWD and manual sharing only |
| `enableInteractionRoleHierarchy` | false | Enables role hierarchy sharing for Interaction records — affects which users can see client interaction logs |
| `enableInteractionSummaryRoleHierarchy` | false | Enables role hierarchy sharing for Interaction Summaries |
| `allowMultipleProducersToWorkOnSamePolicy` | false | When true, multiple producers can be assigned to one policy — expand the sharing surface; ensure OWD and sharing rules account for multi-producer access |
| `enablePolicyAdministration` | false | When true, policy admin data model is active; transaction and transaction detail records become accessible |
| `rlaEditIfAccHasEdit` | false | When true, restricts ResidentialLoanApplication editing to users who also have edit access on the linked account — enforces data access alignment between objects |
