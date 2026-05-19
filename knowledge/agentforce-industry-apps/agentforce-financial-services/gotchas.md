---
source: Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata queried from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: gotchas
last-updated: 2026-05-11
---

# Financial Services Cloud — Gotchas and Known Limitations

---

## Feature Activation and Object Availability

### FSC Objects Require Feature Activation

- `InsurancePolicy`, `Claim`, `InsurancePolicyCoverage`, `InsurancePolicyParticipant`, `InsurancePolicyAsset`, `InsurancePolicyTransaction` require **Insurance feature activation**
- `FinancialGoal`, `FinancialPlan`, `FinancialSecurity`, `FinancialGoalFunding` require **Wealth Management feature activation**
- Deploying metadata that references these objects in an org where the feature is not activated causes `INVALID_TYPE` errors
- **Activation is irreversible** — once activated, features cannot be deactivated; use scratch orgs for exploratory work

### Sandbox Feature Activation Must Mirror Production

Developer Edition orgs and Trailhead Playgrounds do NOT include FSC Insurance or Wealth features. Only Full or Partial sandboxes refreshed from a production org with FSC licensed and activated will have the correct feature set. Running UAT in a DE org will cause "it worked in sandbox, fails in prod" failures in reverse — features present in prod but not in DE.

### FSC Namespace History

Pre-Spring '20 orgs use `FinServ__FinancialAccount__c` (managed package namespace). Modern orgs use platform-managed `FinancialAccount` (no namespace). Some orgs have both coexisting after upgrade. **Always verify actual API names via EntityDefinition query before writing SOQL or Apex.** Never assume the API name based on documentation alone.

---

## Read-Only and System-Managed Fields

### Auto Number Name Fields

These `Name` fields are auto-generated and must NOT be set programmatically:

| Object | Field | Data Type |
|---|---|---|
| `InsurancePolicyCoverage` | `Name` | Auto Number |
| `InsurancePolicyParticipant` | `Name` | Auto Number |
| `InsurancePolicyAsset` | `Name` | Auto Number |
| `ClaimParticipant` | `Name` | Auto Number |
| `FinancialAccountTransaction` | `Name` | Auto Number |

Attempting to set these fields in an insert/update will throw `FIELD_INTEGRITY_EXCEPTION`.

### System Fields (Always Read-Only)

- `Id`, `CreatedById`, `CreatedDate`, `SystemModstamp`, `IsDeleted` — never set these
- `LastViewedDate`, `LastReferencedDate` — updated by platform, not settable

### Formula Fields

Formula fields on FSC objects (e.g., `TotalStandardAmount`, `TotalTermAmount` on InsurancePolicyCoverage and InsurancePolicyParticipant) are read-only and recalculated by the platform. Do not set them in DML.

### Rollup Summary Fields

`InsurancePolicy.Participant_Count__c` and `Count_Of_Coverage_ChildItems__c` (in this org) are Roll-Up Summary fields. Read-only; updated asynchronously when child records change.

---

## Unique and Uniqueness Constraints

### SourceSystemIdentifier Constraints

| Object | Field | Type | Constraint |
|---|---|---|---|
| `InsurancePolicyCoverage` | `SourceSystemIdentifier` | Text(255) | Unique Case-Insensitive |
| `InsurancePolicyParticipant` | `SourceSystemIdentifier` | Text(255) | Unique Case-Insensitive |
| `InsurancePolicyAsset` | `SourceSystemIdentifier` | Text(255) | Unique Case-Insensitive |
| `ClaimParticipant` | `SourceSystemIdentifier` | Text(255) | Unique Case-Insensitive |
| `InsurancePolicy` | `SourceSystemIdentifier` | Text(255) | Unique Case-Insensitive |
| `InsurancePolicy` | `UniversalPolicyNumber` | Text(255) | Unique Case-Insensitive |
| `FinancialAccount` | `SourceSystemIdentifier` | External Lookup | Different type — external ID lookup, not standard unique text |

Integration upserts that send duplicate `SourceSystemIdentifier` values will throw `DUPLICATE_VALUE`. The source system must guarantee globally unique IDs.

**Critical difference:** `FinancialAccount.SourceSystemIdentifier` is an **External Lookup** type (not standard Text Unique). It behaves differently from insurance object `SourceSystemIdentifier` fields. External Lookup fields link to an ExternalDataSource — they cannot be used in standard upsert operations the same way. Verify behaviour in org before building integration.

---

## SOQL Gotchas

### Multi-Select Picklist Querying

`InsurancePolicyParticipant.Role` is a **Multi-Select Picklist**. Use `INCLUDES`/`EXCLUDES`, never `=`:

```soql
-- CORRECT
WHERE Role INCLUDES ('Insured', 'Co-Insured')

-- WRONG -- returns no results or errors
WHERE Role = 'Insured'
```

`ClaimParticipant.Roles` is also Multi-Select. Same rule applies.

### Large Object Query Timeouts

`Claim` and `FinancialAccountTransaction` accumulate millions of records in active orgs. **Always include a date range filter** on indexed date fields:

```soql
-- CORRECT
SELECT Id, Status FROM Claim
WHERE LossDate >= LAST_N_YEARS:2

-- WRONG -- will time out at scale
SELECT Id, Status FROM Claim
```

`InsurancePolicyParticipant` also grows very large in broking environments with many insurer participants per policy. Filter by `InsurancePolicyId` whenever possible.

### Child Relationship Query Depth

SOQL allows only 1 level of nested subquery. You cannot nest `ClaimCoverages` inside `Claims` inside `InsurancePolicies` in a single query. Break into separate queries with collected ID sets.

### Policy Number Ambiguity

`InsurancePolicy.Name` in this org stores the LK internal reference number. The standard `UniversalPolicyNumber` field stores the unique policy number. The lookup field `InsurancePolicy_lk__c` on `Claim` is a custom field that may differ from `PolicyNumberId`. **Always verify which field is used for business policy number identification in the specific org.**

---

## Relationship and Hierarchy Restrictions

### Master-Detail Cascade Delete

Deleting an `InsurancePolicy` record cascades and deletes ALL:
- `InsurancePolicyCoverage` (all lines)
- `InsurancePolicyAsset` (all assets)
- `InsurancePolicyParticipant` (all participants)
- `InsurancePolicyTransaction` (all transactions)

This is standard Salesforce Master-Detail behaviour. **Never delete InsurancePolicy records in production without confirming there are no dependent Claims.** Claims link via Lookup (not Master-Detail) to InsurancePolicy, but Claims referencing a deleted policy will lose their policy reference.

Similarly, deleting `Claim` cascades to `ClaimItem`, `ClaimParticipant`, `ClaimCoverage`.

Deleting `FinancialAccount` cascades to `FinancialAccountTransaction`, `FinancialAccountParty`, `FinancialAccountBalance`, `FinancialAccountFee`.

### InsurancePolicyCoverage Cannot Exist Without InsurancePolicy

`InsurancePolicyCoverage.InsurancePolicyId` is a **Master-Detail** field — it is required on insert and cannot be changed after creation. If a coverage record needs to move to a different policy (e.g., policy restatement), you must delete and re-create.

Same restriction applies to: `InsurancePolicyParticipant`, `InsurancePolicyAsset`, `InsurancePolicyTransaction`, `ClaimItem`, `ClaimParticipant`, `ClaimCoverage`, `FinancialAccountTransaction`.

---

## Picklist Value Restrictions

### Status Fields — Core Values

These standard picklist values are expected by platform logic and should not be removed:

| Object | Field | Reserved Values |
|---|---|---|
| `InsurancePolicy` | `Status` | `InForce`, `Cancelled`, `Lapsed`, `Expired` |
| `InsurancePolicyCoverage` | (no Status standard field) | — |
| `InsurancePolicyTransaction` | `Status` | `Pending`, `Posted`, `Cancelled` |
| `InsurancePolicyTransaction` | `Type` | `NewBusiness`, `Renewal`, `Endorsement`, `Cancellation` |
| `Claim` | `Status` | `New`, `Open` (varies by implementation) |
| `FinancialAccount` | `Status` | `Open`, `Closed` |
| `FinancialAccountTransaction` | `DebitCreditIndicator` | `Debit`, `Credit` |
| `FinancialGoal` | `Status` | `NotStarted`, `InProgress`, `Achieved`, `Cancelled` |

Do not remove or rename these values — Apex code, flows, and assignment rules may reference them as literal strings.

### Picklist Dependency Chains

In this org, `LOB1__c` → `LOB2__c` → `LOB3__c` on both `InsurancePolicy` and `Claim` are likely dependent picklists. Changes to controlling picklist values cascade to dependent values. Test all three levels before deploying picklist changes.

---

## ARC Configuration Restrictions

### UI-Only Settings Are Not Deployable

Some ARC configuration exists only in the org's UI (Setup → ARC Settings) and cannot be captured in metadata:
- Relationship group display order
- Object tile field selection per group
- ARC component sidebar preferences

These must be manually re-configured after every sandbox refresh. Include an ARC configuration checklist in the deployment runbook.

### ARC Requires Account Record Type = Household

The ARC household features (showing household members, aggregated financials) only activate on Account records with the **Household record type**. Regular business Account records show a different ARC view. Do not assume ARC will look the same on all Account records.

---

## Security and Compliance Constraints

### Sequencing Objects Must Have OWD = Private

Any object managing sequential numbers (policy number generator, claim reference sequencer, invoice numbers) must have OWD = `Private`. If set to `Public Read/Write`, any user can insert or update records and corrupt the sequence, causing duplicate numbers and reconciliation failures. This is a **HIGH RISK** finding in any FSC engagement.

### Field History Tracking Limit

Salesforce allows a maximum of **20 fields per object** for Field History Tracking. For `InsurancePolicy` (189 fields) and `Claim` (142 fields), prioritise:
- Status, PremiumAmount, TotalSumInsured (InsurancePolicy)
- Status, EstimatedAmount, ActualAmount, ApprovedAmount (Claim)
- OwnerId (both) for adjuster/advisor reassignment audit

### System Administrator Profile Anti-Pattern

FSC orgs frequently have too many users on System Administrator profile from initial setup. Sys Admin users can:
- View all financial data regardless of OWD
- Modify field history tracking settings
- Change OWD and sharing rules
- Bypass validation rules

Conduct a profile audit during Discovery. Any user on Sys Admin profile who does not need admin access is a security finding. Right-size to least-privilege profiles + permission sets before delivering new functionality.

---

## Performance Constraints

### Asynchronous Rollups

FSC managed package household and financial account summary rollup fields recalculate asynchronously. Do not build:
- Flows that read rollup values immediately after DML on child records
- Apex tests that assert rollup values in the same test method as the child record insert
- Batch jobs that use rollup totals in the same run that updates source records

Allow at least one async cycle before reading rollup values.

### Reconciliation Object Accumulation

Finance reconciliation objects (BankTransaction equivalents, settlement records, period close records) accumulate millions of rows in active orgs. Design must include:
- Date-indexed fields on all reconciliation objects (add custom index on CloseDate or PostingDate)
- Archive strategy for records beyond regulatory retention period (typically 7 years)
- Batch jobs for period-end processing running in off-peak hours
- SOQL in triggers/flows on these objects must always include selective date filters

### Flow Evaluation at Scale

Every active record-triggered flow evaluates on qualifying record operations — including flows that are dev/test artifacts that were never deactivated. In production orgs with large transaction volumes, orphaned test flows create performance degradation and debugging noise. Include a housekeeping story in the first sprint to deactivate and delete automation artifacts without a production business purpose.

---

## Version and API Compatibility

### Minimum API Version by Object

| Object | Available Since (approx.) | Notes |
|---|---|---|
| `InsurancePolicy` | API v46.0 (Summer '19) | Platform-managed (no namespace) |
| `Claim` | API v46.0 (Summer '19) | Platform-managed |
| `InsurancePolicyCoverage` | API v46.0 (Summer '19) | Platform-managed |
| `InsurancePolicyParticipant` | API v46.0 (Summer '19) | Platform-managed |
| `InsurancePolicyAsset` | API v46.0 (Summer '19) | Platform-managed |
| `InsurancePolicyTransaction` | API v50.0+ (Winter '21) | Added later |
| `ClaimCoverage` | API v50.0+ | Added later |
| `ClaimPaymentSummary` | API v54.0+ | Added in more recent releases |
| `FinancialAccount` | API v46.0 (Summer '19) | Platform-managed |
| `FinancialAccountTransaction` | API v46.0 | Platform-managed |
| `FinancialGoal` | API v46.0 | Requires Wealth feature |
| `FinancialPlan` | API v52.0+ | Added later |
| `FinancialSecurity` | API v52.0+ | Added later |
| `InsuranceRatePlan` | API v54.0+ | Rating engine objects |
| `InsuranceAsyncBulkRequest` | API v56.0+ | Async bulk processing |

**This org runs API v67.0 (Spring '26).** Objects with higher minimum API versions are present and usable.

### Deployment to Lower API Version Orgs

If deploying metadata from this org (v67.0) to an org running an older API version, fields and objects introduced in higher API versions will fail to deploy. Check target org API version before cross-org deployments.

---

## Unmanaged Package Risk

FSC orgs commonly contain unmanaged packages installed by prior vendors (utility libraries, integration connectors, reporting tools). Unmanaged packages:
- Cannot be upgraded — require manual re-deployment
- May conflict with FSC platform updates
- Create orphaned code if the vendor stops maintaining them
- Are not visible in normal metadata deployments

Flag all unmanaged packages during Discovery via `SELECT Id, SubscriberPackageId, SubscriberPackage.Name FROM InstalledSubscriberPackage`. Evaluate each for: (a) migrate into org codebase, or (b) document as technical debt with remediation timeline.

---

## Known Limitations (Spring '26)

1. **ClaimCoverage.Name is Text, not Auto Number** — unlike other claim child objects. Integrations must provide a meaningful name value.

2. **InsurancePolicyCoverage.Name is Auto Number** — the display name for a coverage line must be stored in `CoverageName` field, not in the auto-number `Name` field.

3. **InsurancePolicyParticipant has no direct Account Master-Detail** — the parent Master-Detail is `InsurancePolicyId`. Account links are Lookup fields (`PrimaryParticipantAccountId`, `RelatedParticipantAccountId`). This means participant records are NOT directly accessible from Account record pages via standard related lists — custom components or custom relationship fields are needed to show policy participants from an Account.

4. **Claim does not auto-link to InsurancePolicyCoverage** — as noted in the implementation guide, `ClaimCoverage` records linking the claim to specific coverages must be created explicitly by the FNOL intake process.

5. **Multi-Select picklist `Role` field** on `InsurancePolicyParticipant` — allows multiple roles per participant record. This is intentional but requires careful validation logic: a participant should not have both `Insured` and `Insurer` roles simultaneously. Build validation rules or before-save flows to enforce business rules.

6. **ARC does not display Custom Objects by default** — ARC relationship maps show standard FSC objects. Custom objects (Placement__c, Reconciliation__c, etc.) require custom ARC extensions or supplemental Lightning components.

7. **InsurancePolicy.Name in this org is a custom label** — The `Name` field label shows "LK Ref. Name" (custom field label override). The standard `PolicyName` field stores the policy description. The unique policy identifier is `UniversalPolicyNumber`. Developers joining this engagement must understand this naming divergence.

---

## Gotchas from FSC Developer Guide (Spring '26)

### FSC Managed Package API Version Lag

Source: fsc_dev_guide.pdf p.11.

**The custom objects, components, classes, and triggers in the FSC managed package are one API version behind the core Salesforce API.** FSC standard objects (InsurancePolicy, Claim, FinancialAccount, etc.) are platform-managed and match the current API version.

**Practical impact:**
- If your org's API version is v67.0 (Spring '26), managed package custom objects (those with `FinServ__` namespace) are at v66.0
- When deploying metadata that references FSC managed package custom objects, use the managed package API version (current org version minus 1), not the current org API version
- Apex code in the managed package runs at the lower API version — do not pass managed package objects to methods expecting the current-version type signatures
- This mismatch is invisible in most day-to-day operations but becomes visible when Apex compilation errors reference type incompatibilities between managed and unmanaged code

**Rule:** Always confirm which version context applies — platform FSC objects follow current API, managed package `FinServ__` objects follow current API minus 1.

---

### AccountAccountRelation Requires Group Membership Settings

Source: fsc_dev_guide.pdf p.12 (Special Access Rules for AccountAccountRelation).

`AccountAccountRelation` is a standard FSC object and is **available only when Group Membership Settings are enabled** in the org.

- **Where to enable:** Setup → Account Settings → Group Membership Settings
- **Impact:** If Group Membership Settings is not enabled, queries to `AccountAccountRelation` will return errors or empty results. Deploying flows or Apex that reference this object will fail at runtime even though compilation succeeds.
- **Migration note:** Orgs upgrading from legacy `FinServ__AccountAccountRelation__c` (managed package) to standard `AccountAccountRelation` must enable Group Membership Settings before migrating data.

---

### AccountFinancialSummary Requires Financial Summary Rollup Setting

Source: fsc_dev_guide.pdf p.16 (Special Access Rules for AccountFinancialSummary).

`AccountFinancialSummary` is a standard FSC object available since API v62.0 but is **only available when the Financial Summary Rollup settings are turned on**.

- **Where to enable:** Setup → Financial Services Cloud → Feature Settings → Financial Summary Rollup
- **Impact:** Without this setting enabled, `AccountFinancialSummary` is not queryable, not creatable, and not referenceable in flows or Apex
- `AccountFinancialSummary` stores aggregated financial metrics per account: `TotalFinancialAccountBal`, `TotalHeldFinclAcctValue`, `TotalInsurancePolicyCount`, `TotalClaimCount`, `TotalLiabilityValue`, `TotalNonFinancialAssetVal`, `TotalBankDepositValue`
- All summary fields include a paired `*UpdatedDate` dateTime field tracking when each metric was last recalculated

---

### FinancialAccountStatement, FinancialAccountTransaction (v61) Require Financial Account Management Setting

Source: fsc_dev_guide.pdf pp.314, 317, 320 (Special Access Rules).

`FinclAcctPtyFinclAsset`, `FinancialAccountStatement`, and the newer version of `FinancialAccountTransaction` (API v61) are only available when **Financial Account Management Standard Objects** setting is enabled:

- **IndustriesSettings field:** `enableFinancialAccountMgmt = true`
- **Impact:** Deploying metadata or running SOQL against these objects without the setting enabled causes `INVALID_TYPE` errors

---

### FinancialDeal Requires Deal Management Setting

Source: fsc_dev_guide.pdf pp.1315 (IndustriesSettings `enableDealManagement`).

The `FinancialDeal` object family (FinancialDeal, FinancialDealAsset, FinancialDealBid, FinancialDealInteraction, FinancialDealParty, FinancialDealParticipant) requires:

- **IndustriesSettings field:** `enableDealManagement = true`
- **Impact:** All FinancialDeal objects are unavailable without this setting. Do not deploy flows or Apex referencing FinancialDeal objects in orgs where Deal Management is not enabled.

---

### IndustriesSettings Deployment Sequence — Some Settings Have Dependencies

Source: fsc_dev_guide.pdf pp.1312–1318.

Some IndustriesSettings fields must be enabled in a specific sequence because later settings depend on earlier ones:

1. **`enableFSCInsuranceReport`** requires `allowMultipleProducersToWorkOnSamePolicy = true` to be set first. Attempting to enable `enableFSCInsuranceReport` without the prerequisite will silently have no effect or cause configuration errors.

2. **Discovery Framework OmniScripts** require `enableDiscoveryFrameworkMetadata = true` before deploying OmniScript components of type `discoveryframework`. Deploying them first causes deployment failures.

3. **`enableCompliantDataSharingFor*` settings** should be enabled only after the corresponding sharing rules and permission sets are deployed. Enabling CDS on an object before the sharing rules exist will lock out users from records they previously had access to.

4. **`enableFinancialAccountMgmt`** should be enabled before deploying `FinancialAccountStatement` or `FinclAcctPtyFinclAsset` object metadata.

**Rule:** Before deploying any metadata that depends on an IndustriesSettings toggle, confirm the toggle is already enabled in the target org. Build this check into the deployment runbook as a pre-flight validation step.

---

### Referral Object Is New in API v66.0 — Pre-Spring '26 Orgs Use Custom Objects

`Referral` (standard FSC object) was introduced in API v66.0. Orgs on older API versions will have custom `Referral__c` objects from their implementation. After upgrading to Spring '26 (v67), both the old custom object and the new standard object may coexist. **Do not assume referral data lives in `Referral` without verifying via EntityDefinition query.** Check which object is in use before building SOQL or flows.

---

### ClaimFinancialSettings Requires Insurance Access License

Source: fsc_dev_guide.pdf p.1307 (ClaimFinancialSettings Special Access Rules).

The `ClaimFinancialSettings` metadata type (configures pending financial authority status values for claims) requires access to either the **InsurancePolicyAdminAccess** or **InsuranceClaimMgmtAccess** add-on license. Attempting to deploy or retrieve `ClaimFinancialSettings` in an org without these licenses will fail with a permissions error.

---

### RelatedRecordAssocCriteria (Branch Management) Requires FSC Extension Permission

Source: fsc_dev_guide.pdf p.1323 (RelatedRecordAssocCriteria Special Access Rules).

The `RelatedRecordAssocCriteria` metadata type for Branch Management auto-association rules requires the **Financial Services Cloud Extension permission set**. Without this, deployment of `RelatedRecordAssocCriteria` components will fail.

---

### OmniScript Metadata Requires OmniStudio License + Discovery Framework

Source: fsc_dev_guide.pdf p.1319 (OmniScript Special Access Rules).

The `OmniScript` metadata type requires both:
1. An **OmniStudio license** in the target org
2. The **Discovery Framework feature** enabled (`enableDiscoveryFrameworkMetadata = true` in IndustriesSettings)

Deploying OmniScript metadata to an org without these will fail. This is a common deployment failure when deploying from a licensed developer sandbox to a target org that does not yet have OmniStudio provisioned.
