---
source: Vlocity Build GitHub; OmniStudio transcripts; EPC Guide; CLM/ASLM Guide; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: gotchas
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Gotchas

## G-1: vlocity_cmt Namespace Is Shared with Communications and Media Cloud

The `vlocity_cmt` managed package powers Energy and Utilities, Communications, AND Media clouds. All three clouds share the same managed package. If your org has Communications Cloud licensed, many E&U objects already exist. This can cause confusion when reading documentation — always confirm which features are license-gated vs. included in the base package.

---

## G-2: Managed Package Triggers Cannot Be Modified

The E&U managed package includes triggers on its managed objects. You **cannot** modify, disable, or replace these triggers. All custom trigger logic for managed objects must be implemented via:
- Record-Triggered Flows
- `ItemImplementation__c` registration for OM tasks
- `VlocityStateTransitionRule__c` metadata

Adding custom Apex triggers that perform DML on `vlocity_cmt__` objects can conflict with managed triggers and cause duplicate processing or data integrity issues.

---

## G-3: EPC Product Versioning Is Irreversible

Product versioning (create versions of product offers/specs) is a Beta feature in EPC. **Once enabled and then disabled, data integrity issues can result — this is explicitly documented as irreversible.** Enable only if your release process requires it and you are prepared to maintain it permanently.

---

## G-4: Multi-Currency Requires Both Orgs Enabled

When deploying DataPacks between orgs using IDX Workbench, **both the source and target orgs must have multi-currency enabled** if the DataPack contains currency-sensitive data (PriceListEntry, PricebookEntry). Deploying currency data to a non-multi-currency org causes silent failures or errors.

---

## G-5: OmniScript Embedded in >100 Others Hits SOQL Limits

When an OmniScript is embedded (referenced) by more than 100 other OmniScripts, SOQL governor limits are hit during compilation and activation. Symptoms: activation hangs or fails with a governor limit error.

**Fix:** Refactor deeply shared OmniScripts into Integration Procedure calls instead of embedded OmniScript components. Limit reuse of a single OmniScript to fewer than 100 consumers.

---

## G-6: Circular DataPack References Require forceDeploy or supportHeadersOnly

If two DataPack records reference each other (e.g., two Product2 records with mutual ProductRelationship), IDX Workbench deployment will fail with a circular reference error.

**Fix:** Use `"supportHeadersOnly": true` in the job file for the first pass (deploys headers without relationships), then deploy again without the flag to resolve relationships. Alternatively use `"supportForceDeploy": true` for hotfixes.

---

## G-7: CalculationMatrixRow Bulk Operations Only Trigger at ≥2,000 Records

DataRaptor Load operations on `CalculationMatrixRow__c` only execute bulk optimization when the record count is ≥ 2,000. Below that threshold, rows are processed record-by-record. For large pricing matrices, always batch imports at ≥ 2,000 rows to avoid performance issues.

---

## G-8: Large Attribute Sets Overflow CompiledAttributeOverride JSON

When a product has >300 AttributeAssignments with overrides, the compiled override JSON stored in `CompiledAttributeOverride__c` can exceed Salesforce's JSON field size limits. This causes CPQ to fail silently or return incomplete attribute data.

**Fix:** Reduce attribute cardinality; consolidate attributes into categories; use Attribute Binding to map to native Salesforce fields instead of custom attributes where possible.

---

## G-9: Managed Global Value Sets Cannot Be Updated via DataPack

DataPack deployment cannot update managed Global Value Sets (picklist values defined in the managed package). Attempting to deploy a DataPack that references a managed picklist value that doesn't exist in the target org will fail.

**Fix:** Add required picklist values via Salesforce Setup UI in the target org before DataPack deployment.

---

## G-10: VF-Based DocGen OmniScripts Retired in Spring '25

The Visualforce-based document generation OmniScripts (`singleDocxVF`, `multiDocxVF`, `singleWebVF`) were **retired in Spring '25**. Orgs still using these must migrate to the LWC-based equivalents:
- `singleDocxLwc`
- `multiDocxLwc`
- `singleWebLwc`

Any org that upgrades the E&U managed package to Spring '25+ without migrating VF DocGen OmniScripts will lose document generation capability.

---

## G-11: DocuSign OAuth 1.0 Deprecated March 2024

DocuSign integration requires OAuth 2.0 starting with package version 240.11 (Winter '23). OAuth 1.0 stopped working in March 2024. Orgs that didn't migrate before the deadline have broken DocuSign integrations.

**Fix:** Configure DocuSign Connected App with OAuth 2.0 before upgrading to package v240.11+. If already on this version without OAuth 2.0, reconfigure the DocuSign connected app immediately.

---

## G-12: Turbo Extract Does Not Support Formula Fields

DataRaptor Turbo Extract is the fastest data retrieval type but **does not support formula fields in output mappings** and does not support complex relationship queries. Using formula fields in a Turbo Extract produces empty or null values without errors.

**Fix:** Use standard Extract (not Turbo) when formula field output is required. Use Turbo only for simple field lookups on the primary object.

---

## G-13: DataRaptor Load Does Not Enforce FLS

DataRaptor Load operations do not automatically enforce field-level security. Users with access to run a DataRaptor Load can write to fields they may not have FLS access to.

**Fix:** Add explicit permission checks in your OmniScript or Integration Procedure before calling the DataRaptor Load, or use `stripInaccessible()` in a wrapping Apex Action if FLS enforcement is critical.

---

## G-14: CPQ API Performance — Always Disable Pricing When Not Needed

CPQ API calls (`getCards`, `getCardItems`) run pricing calculations by default. For catalog browsing, product filtering, and availability checks where pricing is not displayed, always pass `"getPricing": false`. Running pricing unnecessarily adds significant latency (pricing runs Calculation Procedures + Matrices).

---

## G-15: Orchestration Items Without Matching Key Cause Duplicates

When deploying `OrchestrationItemDefinition__c` records via DataPack, the matching key is not natively defined in the managed package. Without a matching key, redeployment creates duplicate orchestration item definitions instead of updating existing ones.

**Fix:** Define a `VlocityMatchingKey__mdt` record for `OrchestrationItemDefinition__c` using a unique business key (e.g., `Name` + `OrchestrationPlanDefinition__c` composite) before deploying.

---

## G-16: OmniScriptInstance__c PII Accumulation

`OmniScriptInstance__c` stores the state of in-progress OmniScript sessions. If users abandon sessions mid-flow, PII (customer details, service addresses, payment info) accumulates in this object indefinitely.

**Fix:** Schedule a daily/weekly purge job to delete completed and expired OmniScriptInstance records. Treat this object as a transient store, not a permanent record.

---

## G-17: %vlocity_namespace%__ Placeholder Must Be Resolved Before Deployment

Source-controlled DataPacks use `%vlocity_namespace%__` as the namespace placeholder. If you deploy DataPack JSON directly via MDAPI without running it through the IDX Workbench (`packDeploy`), the placeholder is not replaced and all object/field references fail.

**Fix:** Always use `vlocity packDeploy` (IDX) to deploy DataPacks — never deploy raw DataPack JSON via `sf project deploy start` directly.

---

## G-18: Integration Procedure Chain on Step Loses Context Variables

When "Chain on Step" is used to spin up a new transaction mid-IP (to avoid governor limits), the new transaction context does NOT inherit all variables from the parent transaction. Only explicitly passed input/output parameters are available.

**Fix:** Design IPs that use Chain on Step to be stateless — pass all required data explicitly via step parameters rather than relying on IP-level context variables.

---

## G-19: EPC Product Console Is Being Phased Out

The legacy Product Console (Angular-based) has been frozen — no new features are being added to it. All new EPC configuration work should use **Product Designer** (LWC-based) and **Pricing Designer**. Building new features in Product Console will require rework when it is eventually removed.

---

## G-20: ServicePoint Premises Field Points to Location, Not vlocity_cmt__Premises__c

`ServicePoint.PremisesId` is a lookup to the standard **`Location`** object (the relationship name in the UI is "Premises"). It is NOT a lookup to `vlocity_cmt__Premises__c`. Writing SOQL like `ServicePoint.vlocity_cmt__Premises__r.Name` will fail — use `ServicePoint.Premises.Name` instead.

A single Account → BillingAccount → Location (premises) → ServicePoint chain. The service point is the physical metered entry point; the Location holds the physical address (DistributionArea, GrossFloorArea, HasLifeSupport, HasSensitiveLoad). Do not use Account address fields as a proxy for service location.

---

## G-21: BillingAccount and ServicePoint Have Separate Status Lifecycles

`BillingAccount.Status` (Active / Inactive / Suspended) and `ServicePoint.Status` (Active / Disconnected / Abolished) are independent picklists. A billing account can be Active while a ServicePoint is Disconnected (e.g., non-pay disconnection pending reinstatement). Always check both statuses when determining whether a customer's service is live.

---

## G-22: ProgramEnrollment Does Not Directly Store AccountId

`ProgramEnrollment` does not have a direct `AccountId` field. The enrollee link is via `IndividualApplication.AccountId`. Querying program enrollments for a specific account requires joining through `IndividualApplication`: `WHERE IndividualApplication.AccountId = :accountId`.

---

## G-23: Budget/BudgetCategory Require Grantmaking License in Addition to Permissions

`Budget`, `BudgetCategory`, `BudgetCategoryValue`, and `BudgetPeriod` objects require **both** the Grantmaking license enabled in Setup AND the `Manage Budgets` system permission assigned. Assigning a permission set alone is not sufficient. If users get "Object not accessible" errors on Budget objects, check whether Grantmaking is enabled in Setup (not just licensed).
