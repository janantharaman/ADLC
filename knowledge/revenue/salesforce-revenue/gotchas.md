---
source: hand-authored + RCA Internal Playbook (May 2025) + RCA Deployment Strategy (cross-project tracker, real customer engagements) + Revenue Cloud Deployment Guide (Pilot) Spring '26 + Usage Management - Community Learning (Salesforce Confidential, Internal Training) + Spring '25 RCB Hands On Exercises + RCB Implementation Best Practices + RLM Spring '26 Developer Guide
cloud: Revenue Cloud
section: gotchas
last-updated: 2026-05-10
---

# Revenue Cloud — Gotchas and Common Misconfigurations

## CPQ Calculation Engine Must Not Be Bypassed

The CPQ pricing calculation engine (triggered when a Quote is recalculated) is the source of truth for all pricing on `SBQQ__QuoteLine__c`. If you insert or update QuoteLine records directly via Apex or Data Loader without triggering the CPQ calculation engine, price fields will be stale or zeroed out. Always use `SBQQ.QuoteAPI.save()` or trigger a recalculation via the CPQ API — never raw DML on QuoteLine if pricing accuracy matters.

## Large Quotes (200+ Lines) Cause Calculator Timeouts

CPQ's pricing calculator runs synchronously in the UI. Quotes with 200+ lines (common in enterprise software bundles) can cause 30–60 second page load times or calculator timeouts. CPQ has a `Large Quote Threshold` setting — when a quote exceeds it, the calculator runs asynchronously and users are notified when it completes. Set this threshold appropriately for the customer's typical quote size.

## CPQ and Standard Quote Must Not Coexist Actively

In a CPQ org, the standard Salesforce Quote object becomes redundant. If both are actively used, you get sync conflicts (CPQ Quote vs Standard Quote syncing to Opportunity Amount). Best practice: disable or hide the standard Quote tab and standard Quote button on Opportunity when CPQ is installed. Leaving both active leads to data integrity issues.

## Amendment Quotes Create Delta Lines — Not Full Replacements

When a rep amends a Contract in CPQ, the amendment Quote contains delta lines: `+5 seats of Product A` and `-2 seats of Product B`. These are NOT full replacement lines. Apex that looks at QuoteLines expecting full quantities will get incorrect results on amendment quotes. Always check `SBQQ__Quote__c.SBQQ__Type__c` (`Quote`, `Amendment`, `Renewal`) before processing QuoteLines in automation.

## Renewal Quotes Are Auto-Created — Customise with Care

CPQ auto-creates renewal opportunities and quotes before contract expiry. If a customer's sales team is not expecting this, they are surprised by opportunities appearing in their pipeline. The renewal creation timing and whether it creates an Opportunity is controlled by CPQ settings and `SBQQ__Quote__c.SBQQ__RenewalTerm__c`. Always configure and test renewal settings in sandbox before go-live.

## Advanced Approvals Is a Separate Package from CPQ

CPQ Advanced Approvals (`SBAA__` namespace) is a separate managed package from CPQ (`SBQQ__`). It must be separately licensed and installed. Standard Salesforce Approval Process on `SBQQ__Quote__c` works but is primitive — it doesn't support parallel approvals, conditional routing, or re-submission after partial approval. If the customer needs multi-tier deal desk approval, Advanced Approvals is almost always necessary. Confirm whether it is installed and licensed during discovery.

## Price Rules Fire in a Defined Order — Conflicts Are Silent

CPQ Price Rules evaluate in evaluation order (a numeric sequence you set). If two Price Rules set the same field, the higher-order rule wins silently. There is no warning or error — just an overwritten value. Poorly ordered Price Rules are a common source of "why is my price wrong?" bugs. Document all Price Rules with their evaluation order and what fields they set; review for conflicts before go-live.

## Billing Package Is Completely Separate from CPQ

CPQ (`SBQQ__`) and Billing (`blng__`) are two different managed packages that integrate but operate independently. Some customers assume CPQ includes billing — it does not. The billing module generates invoices from Orders; CPQ generates Orders from Contracts. Confirm whether Billing is licensed and installed before designing any invoice or payment automation.

## Revenue Recognition (ASC 606) Requires Billing Configuration

If the engagement includes revenue recognition, the `blng__` Billing package must be configured with Revenue Recognition Policies (`blng__RevRecPolicy__c`). This is a separate configuration track from the CPQ quote-to-cash configuration and requires accounting team involvement. Revenue recognition rules (performance obligations, allocation methods) must be defined by the customer's finance/accounting team — the Salesforce implementation team cannot make these determinations.

---

## ARM / RLM (Revenue Cloud on Core) Gotchas

### RLM and CPQ Cannot Coexist in the Same Org
There is no migration path that keeps both active simultaneously in a single org in a stable state. The transition approaches (phased, flash cut, new org) all involve a deliberate separation. Do not propose a "run both in parallel in the same org" approach — it is not supported.

### Product Catalog Redesign Is Mandatory for CPQ Migrations
The CPQ product catalog (SKU-per-variation) and the RLM catalog (attributes-based) are architecturally incompatible. Accelerator tools can transfer some data, but the product catalog almost always requires redesign. Never scope a CPQ-to-RLM migration as "just a data migration" — budget for product catalog reimplementation separately.

### Agentforce Quoting Is Pilot (as of May 2025)
Agentforce Quoting is in Pilot as of Spring '25 — not GA. Do not commit to this capability in a customer deliverable without confirming current release status. Check the Salesforce release notes at the start of every engagement.

### Revenue Events Are Consumed by External Systems Too
Revenue Events are not just consumed by internal users — headless, self-service, community, and commerce integrations also consume events. If the customer has high-volume external ordering (e.g., self-service storefront), model the event consumption carefully before committing to the $10K/50K event pricing. DRO and Invoice Mgmt cost 10 events each — high-volume orchestration can exhaust the 12K included events quickly.

### Minimum 5 User Licenses Required
There is no single-user or small-team deployment of Revenue Cloud. Minimum 5 user licenses are required even if most ordering is headless/external. This is a common surprise for SMB customers.

### OmniStudio Is Included in Revenue Cloud Advanced
OmniStudio (formerly Vlocity) is bundled with Revenue Cloud Advanced. For customers coming from Industries clouds (Financial Services Cloud, Health Cloud, Communications Cloud), this is significant — they may already have OmniStudio components. Verify this during discovery to avoid double-licensing.

### Data Masking Is NOT On by Default for Agentforce
Agentforce does not have data masking enabled by default. For customers with PII concerns (HIPAA, GDPR, financial data), this must be explicitly configured. "We have the Einstein Trust Layer" is not sufficient reassurance — bring security documentation and confirm data masking configuration is in scope. As of March/April 2025, customers can switch to Anthropic (on AWS Bedrock, inside Salesforce trust boundary) instead of OpenAI — this resolves some security objections.

### DRO Works With CPQ Only in Pilot
Dynamic Revenue Orchestration (DRO) works with CPQ managed package only in a limited pilot configuration (as of Spring '25). If a CPQ customer wants DRO, they need to migrate to RLM. Do not promise DRO + CPQ coexistence without confirming current release status.

### Quote Line Limit Is 1,000 Lines (RLM)
RLM supports up to 1,000 line items on a quote or order (as of current release). This is a significant increase from CPQ but still a hard limit. For customers with large catalogs or complex bundles (Dentsply-style with hundreds of thousands of dental products), design the quote structure to stay within this limit — use bundles and aggregation rather than individual lines.

## Revenue Cloud Billing Does NOT Include Revenue Recognition
As of February 2026, Revenue Cloud Billing (RCB) does not support revenue recognition (ASC 606 / IFRS 15). This is not on the near-term product roadmap. If a customer needs RevRec, recommend third-party tools such as **RightRev**. Never scope RevRec as part of the RCB implementation without confirming current product roadmap status.

## Context Definitions Add Significant Data Model Complexity
Context Definitions are central to how ARM prices and processes transactions — they define what data fields are available at each stage of the revenue process. Misconfigured or overly complex Context Definitions are a top source of implementation delays. Always design Context Definitions as part of the Design phase, not during build. Twin fields between Quote Lines and Order Lines must be explicitly mapped in Context Definitions.

## Transactional Data Migration Is Chronically Underestimated
Orders, subscriptions, assets, and in-process quotes from legacy systems (CPQ, ERP, homegrown) must be reshaped to the ARM data model — not simply imported. Active subscriptions must become Assets. In-process quotes must be rebuilt in the ARM quote model. Billing data must be converted to Billing Schedules. This is consistently the most underestimated part of CPQ-to-ARM migrations. Budget a dedicated Data Migration workstream with the Data Practice.

## Product Discovery Configuration Is Complex
Product Discovery (filtering, qualification/disqualification rules, guided selling) has its own configuration layer that is separate from the product catalog setup. It is easy to underestimate the configuration effort for Product Discovery, especially when customers need complex filtering by product family, channel, region, or customer segment. Scope Product Discovery as a separate workstream from PCM.

## Pricing Waterfall / Context Definitions Require Architect-Level Design
The Pricing Waterfall (pricing procedure, procedure plans, context definitions, Apex hooks) is the most technically complex part of ARM. It must be designed by a senior architect, not a developer. Errors in pricing waterfall design propagate to every quote and order. Never leave pricing procedure design to the Build phase — it must be completed and validated in Design.

## CPQ Sandbox Refresh Loses Package Settings

When a sandbox is refreshed from production, CPQ-specific settings (CPQ Settings object records, User preferences) are copied but the package itself may need to be re-configured if sandbox uses a different CPQ license tier than production. Always run a post-refresh validation checklist for CPQ orgs that includes verifying CPQ Settings, Price Rules, and Product Rules are intact.

---

## Deployment Gotchas — Sourced from Real RCA Customer Engagements

The following are known deployment failures and gotchas sourced from a cross-project tracker covering THFC, Genesys, Siemens, Mokah, Vestas, Finastra, TCS, and others. These are not hypothetical — they happened in production engagements.

### CML (Constraint Modeling Language) — MCDM Loses Reference Links

**Symptom:** After deploying CML code via MCDM, the code is present in the destination org but the reference to the CML model is broken — references point to nothing and must be manually re-linked.

**Additional issue:** MCDM has known problems when CML models include **Groups** — group references may not migrate correctly.

**Workaround:** After any MCDM deploy of CML, manually verify all CML model references in the destination org before testing. Post-deployment manual step is required even when CI/CD succeeds. (Siemens engagement)

### Context Definition — Manual Step Always Required

No tool fully automates Context Definition deployment without post-deployment manual intervention. Copado handles the metadata deploy, but reference resolution in the destination org must be verified by hand. (THFC, Siemens)

### Expression Set Versions — Old Versions Block Full Deployments

**Symptom:** When doing a full SFDX deployment, keeping old versions of Expression Set Versions in the repo causes deployment errors — the platform rejects deploying over an older version that is still present.

**Fix:** Delete old Expression Set Version records from the repo before a full deployment. Do not carry historical versions in source control if they are no longer active. (Mokah engagement)

### CI/CD Causes Duplicate Mappings on Context Definitions

**Symptom:** Running CI/CD (e.g., Travis CI) multiple times on Context Definitions (Revenue Cloud Settings, Pricing Settings, Quote/Order Settings) creates **duplicate mappings** in the destination org on subsequent pipeline runs.

**Fix:** Finastra shifted back to **manual deployment** for Context Definitions after hitting this issue. If using CI/CD, add a pre-deployment step to detect and remove duplicate mappings before deploying. (Finastra engagement)

### Legal Entity — Cannot Be Updated via MCDM

**Symptom:** Inserting `LegalEntity` records via MCDM works fine. Updating an existing `LegalEntity` record via MCDM throws an error.

**Workaround:** Insert Legal Entity records once via MCDM. For any subsequent updates, use Data Loader or manual edit. Never include LegalEntity in an update-mode MCDM migration plan. (Mokah engagement)

### Genesys — Manual Decision Table CSV Has Overlap Issues

**Symptom:** When managing Decision Table rows via manual CSV export/import, rows from different tables or overlapping condition columns cause silent overwrites or require in-person verification to detect conflicts.

**Recommendation:** Do not manage Decision Table rows via raw CSV if table count is large. Use Copado or MCDM with explicit row-level GUIDs to prevent overlap. (Genesys engagement)

### ProductConfigurationRule Requires npm Migration Utility — Not MCDM

`ProductConfigurationRule` stores rule content in a Binary Large Object (BLOB) field. That BLOB references product IDs which are org-specific and cannot be migrated as-is via standard data tools. You **must use the Salesforce-provided npm migration utility** to migrate ProductConfigurationRule records. MCDM and Data Loader will fail silently or create broken rule references.

### DRO Rule References Cannot Be Set on INSERT — Must Use UPDATE

`FulfillmentStepDefinition`, `ProductFulfillmentScenario`, `ProductFulfillmentDecompRule`, and `FulfillmentTaskAssignmentRule` all have JSON fields that contain internal RuleSet references. These RuleSet references are **not created on INSERT** — they must be populated by a subsequent UPDATE operation using the JSON fields. Inserting these records and then verifying will show null rule references until the UPDATE step runs. Tools that do only upsert will miss this.

### DRO Attribute Codes Must Be Consistent Across Orgs

DRO condition data (stored in JSON text fields) uses `AttributeCode` as the natural key to resolve `AttributeDefinition` records — not the record ID. If AttributeDefinition records in the target org have different attribute codes than the source, DRO rules will evaluate to false silently (the engine cannot find the rule set). Always verify attribute code parity between source and target before migrating DRO rules.

### Expression Set Ranks Must Be Unique — Even Across Draft Versions

Two expression set versions of the same parent expression set cannot share the same rank number, regardless of whether they are Draft or Active. This causes deployment failures when migrating expression set versions. Workflow: create new version in source → activate it in source → then migrate. If the target already has a version at the same rank, the migration fails.

### Context Service: Cannot Activate/Deactivate Within a Deployment Package

Activating or deactivating a Context Definition cannot be bundled into a metadata deployment package. It must be a separate, manual post-deployment step. Similarly, making a Context Mapping default or non-default must be done manually after deployment. Automation that assumes activation in the same deployment package will fail.

### Context Service: Modifying Deactivated Definitions Requires Manual Replication

You cannot programmatically modify custom nodes and attributes for a Context Definition that is in a deactivated state via deployment. To make changes: manually replicate the modifications in the target org, or delete the Context Definition in the target and deploy again. There is no deploy-based update path for deactivated definitions.

### Product Discovery Index Must Be Rebuilt After Deployment

If Product Discovery indexing is enabled in the source org but not yet enabled in the target: deploying the index flag (`enableIndexedProduct=true`) requires running a **Full Index Rebuild** in the target org before enabling the flag. If you enable the flag before rebuilding, the feature is unstable. Use Full Index Rebuild when enabling for the first time or changing index settings; use Partial Index Rebuild for incremental product/category updates.

### Billing Activation Sequence Is Strict and Must Not Be Reversed

Billing objects have a rigid activation dependency chain: BillingTreatmentItem must be activated FIRST, then BillingTreatment, then BillingPolicy. Similarly: TaxTreatment before TaxPolicy; PaymentTermItem before PaymentTerm; PaymentScheduleTreatment before PaymentSchedulePolicy. Activating in the wrong order throws errors. Deactivating a parent before deactivating its children also fails.

### Data Pipeline Must Be Enabled Before Billing

You cannot enable Billing (`enableBilling` flag) until the Salesforce Data Pipeline is enabled. Deployments that enable Billing before Data Pipeline produce a non-obvious error. Enable in sequence: Context Service → Data Pipeline → Billing.

### Clause Imports Always Insert as Draft

When migrating `DocumentClause` records, all clauses are inserted in Draft status regardless of their source status (Active, Archived, In Approval). You must run a second migration pass that includes status mapping to restore source statuses. If you don't do this, all your clauses will appear as Draft in the target, including those that should be Active or Archived. Clauses in "In Approval" status cannot be restored programmatically — approval must be reinitiated from the UI.

### Copado Is the Lowest-Friction Tool for Most RLM Metadata

Across all projects tracked, **Copado** was the most widely used and lowest-friction deployment tool for RLM metadata components:
- Context Definitions, Revenue Cloud Settings, Product Discovery Settings, Expression Sets, Expression Set Versions, Pricing Recipe, TLE, Managed Asset Viewer: all deploy cleanly via Copado with no reported issues across multiple engagements.
- For data migration (PCM objects, pricing data), **MCDM (Multi-Cloud Data Migration)** and **Prodly** are the most common tools.

**Tool selection summary by component type:**

| Component Type | Recommended Tool | Known Issues |
|---|---|---|
| Context Definitions | Copado | Manual reference check post-deploy; CI/CD causes duplicates |
| Revenue Cloud Settings / Pricing Settings | Copado | None reported |
| Product Discovery Settings | Copado | None reported |
| Expression Sets + Versions | Copado / SFDX | Delete old versions from repo before full SFDX deploy |
| Pricing Recipe | Copado | None reported |
| Decision Table Definition | Copado | None reported |
| Decision Table Rows (data) | Copado / MCDM | Manual CSV has overlap issues (Genesys) |
| TLE (Transaction Line Editor) | Copado | None reported |
| CML (Constraint Modeling Language) | MCDM / Manual | Reference links broken post-deploy; Groups buggy in MCDM |
| Managed Asset Viewer | Copado | None reported |
| PCM Data (Product2, PSM, Attributes, etc.) | MCDM / Prodly | None reported |
| Fulfillment Plan/Step/Scenario | MCDM / Copado | None reported |
| Legal Entity | MCDM (insert only) | Updates fail via MCDM — use Data Loader for updates |
| Pricebook / PricebookEntry | MCDM / Copado | None reported |

---

## Usage Management Gotchas

### Do Not SUM Persistent Usage Resources

`UsageResource` has a `UsagePersists` flag. For resources where `UsagePersists = true` (e.g., Data Storage, Licenses — things that have a point-in-time quantity, not an additive flow), you must use PEAK aggregation, not SUM. If you SUM storage readings, you will grossly overcharge customers. Example: storage peaks at 10GB on day 5, drops to 8GB on day 6 — total billed = 10GB PEAK, not 8+10+8+... etc.

### Rating Tier Rules Differ Between Pricing (NGP) and Rating (NGR)

Salesforce Pricing (NGP) supports **discrete tiers only** with inclusive lower and upper bounds. Rate Management's rating engine (NGR) supports **both discrete and continuous** resources. For continuous resources (like GB), the rule is lower-bound inclusive / upper-bound exclusive. Mixing up tier configurations between pricing and rating produces incorrect overage charges.

### Rate Card Entries Cannot Be Edited After Activation

`RateCardEntry` records can only be edited in Draft status. Once activated, they are immutable. To modify a rate: deactivate the entry (set to Inactive), then set back to Active with corrected values, or create a new entry. Valid status transitions: Draft → Active → Inactive; Inactive → Active. This is different from pricing — it is enforced at the record level for audit and determinism.

### ProductUsageGrant Cannot Be Deleted After Activation

`ProductUsageGrant` and `ProductUsageResource` records follow the same rule: can delete in Draft or Inactive, cannot delete in Active state. After activation, you can only extend the EffectiveEndDate. You cannot shorten the validity period of an active grant. This has contractual implications — plan grant validity carefully before activation.

### Grant Renewal vs Subscription Frequency Can Differ — Plan Billing Accordingly

The `UsageGrantRenewalPolicy.RenewalFrequency` can differ from the product's subscription frequency. Example: annual subscription with monthly grant renewal means granted entitlements refresh every month, but the subscription invoice is annual. This is intentional but frequently surprises billing designers. The Billing Policy (billing frequency for usages in arrears) is a third frequency dimension independent from both. All three must be configured consistently.

### Usage Selling Requires Rate Management Context Definition Sync

After setting up Usage products for selling, you must: (1) extend and sync the SalesTransaction context definition, (2) activate the rating discovery procedure, (3) sync the RatingDiscovery context definition, (4) refresh all Decision Tables used in the rating discovery procedure. Missing any of these steps results in rates not appearing during product browsing or quote creation — with no obvious error message.

### Consumption Lifecycle Requires DPE + Data Pipeline

Usage aggregation (the process that creates Usage Summaries from raw consumption logs) runs via Data Processing Engine (DPE) jobs. DPE requires: (1) CRM Analytics or Data Cloud, (2) Bulk API enabled. If the org lacks these prerequisites, consumption processing cannot run. Ensure both are enabled and licensed before designing the consumption lifecycle.

### UoM Conversion Is Required for Accurate Overage Billing

If a Rate Card Entry is defined in GB but a customer's consumption is metered in MB, the rating engine uses the UoM conversion factor to normalize before applying the rate. If the UoM class does not define the conversion between MB and GB, or if the wrong base unit is set, overage charges will be wrong. Define UoM classes and conversion factors before defining Rate Card Entries. Six decimal precision is supported.

---

## Revenue Cloud Billing (RCB) Gotchas

### BillingTreatmentItem → BillingTreatment → BillingPolicy Activation Order Is Strict

You cannot activate a BillingPolicy until its default BillingTreatment is Active, and you cannot activate a BillingTreatment until its BillingTreatmentItems are Active. The sequence is non-negotiable: activate BTIs first, then the BillingTreatment, then the BillingPolicy. Attempting to activate out of order produces validation errors with no clear messaging about the dependency chain.

### BillingTreatmentItem Requires ZeroAmountBehavior and Type — Even Though They Are Unused

In the current release, `ZeroAmountBehavior` and `Type` are required fields on BillingTreatmentItem even though they are not functionally used. Set `ZeroAmountBehavior = Create Invoice` and `Type = Percentage` as defaults. Only BTIs with `Type = Percentage` and `Percentage = 100` are processed in the current release — do not use FlatAmount or Remainder as primary types.

### Amending a Contract While Draft Invoices Exist Creates Ghost Billing Lines

Before amending any contract, post or cancel ALL related draft invoices. Amending while invoices are in Draft status leaves orphaned billing lines that are never invoiced and cannot be easily cleaned up. This is one of the most common sources of billing reconciliation issues post-go-live.

### Custom Apex Triggers on Order/OrderItem Break RCB Internal Trigger Ordering

RCB's billing engine uses before/after triggers on Order and OrderItem to determine billing schedules, tax calculations, and related record creation. Adding custom Apex triggers on these objects can fire at unexpected times relative to RCB's internal triggers, causing records to be created in the wrong state or tax calculations to use stale data. Use Flow (Before-Save or After-Save) instead, and even then, test thoroughly in a Full Sandbox.

### BillingSchedules Are NOT Created by Direct DML — Only via Context Service

Never attempt to insert BillingSchedule or BillingScheduleGroup records directly via Apex DML or Data Loader. These records must be generated through the Context Service (BillingContext Definition). Directly inserted records will lack required field values and will error during invoice generation. Use the `/commerce/invoicing/billing-schedules/actions/create` API or the `createBillingSchedules` invocable action.

### Invoice Preview API Has Significant Limitations

The Invoice Preview API (`/commerce/invoicing/invoices/collection/actions/preview`) does NOT support: ARC orders, Milestone-based billing products, usage overage calculations, bundles (shows products without parent-child relationships), or more than 200 BillingSchedules. Using it for these scenarios silently returns incomplete or incorrect preview data. Communicate these limitations clearly to Finance stakeholders who rely on previews for approval workflows.

### Tax Policy Cannot Be Edited After Activation for Certain Fields

Once a TaxPolicy is set to `Active`, key fields become read-only. Design TaxPolicies carefully before activation — particularly `TreatmentSelection` (Default/LegalEntity/Manual). Creating a new TaxPolicy and reassigning products is the only remediation path if the wrong selection was made.

### TaxEngine Must Be Active — Revenue Cloud Only Calls Active Tax Engines

If the TaxEngine record's Status is not `Active`, Revenue Cloud silently skips the tax calculation and records zero tax. There is no error thrown. Always verify the TaxEngine Status before testing any invoice with tax.

### PaymentTerm Cannot Be Activated Without a PaymentTermItem — And Cannot Change Inactive → Draft

`PaymentTerm` activation requires at least one `PaymentTermItem`. You cannot change a PaymentTerm's Status from Inactive to Draft (the flow is Draft → Active, and Inactive is a terminal state for Draft). Plan your PaymentTerm records carefully — do not create them with Inactive status unless you intend them to be permanently inactive.

### Bill Now (Generate Invoices) Silently Skips Accounts with 200+ BillingSchedules

The "Bill Now" / "Generate Invoices" on the Account page (and the `/commerce/invoicing/invoices/collection/actions/generate` API) silently skips accounts that have more than 200 BillingSchedules. No error is displayed. For high-volume accounts, use `BillingBatchScheduler` exclusively. This limit is not prominently documented in the UI.

### Billing Arrangement Splits Require API 66.0+ and BillingArrangement + BillingArrangementLine Records

The `BillingArrangement` feature (split invoices across multiple billing accounts) is only available from API version 66.0. If using earlier API versions, these objects do not exist. Also: each `BillingArrangementLine` generates a completely separate invoice — this is intentional but means multi-party billing arrangements multiply invoice volume.

### Milestone Billing Only Works for One-Time Products — Not Recurring

`EnableMilestoneBilling = true` on a BillingTreatment only applies to products with `ChargeType = One-Time`. Applying a milestone billing treatment to a recurring product will not generate `BillingMilestonePlan` records — the system falls back to standard billing without error. Default maximum is 20 BillingMilestonePlanItems per plan.

### Voiding a Posted Credit Memo Creates a Debit Memo — Not a Journal Reversal

When you void a posted CreditMemo via `POST /commerce/billing/credit-memos/{id}/actions/void`, the system creates a `DebitMemo` record (available API 65.0+). The DebitMemo will be included in the next invoice run — it does NOT create an immediate journal reversal. Finance teams need to be aware of this timing difference.

### GL Assignment Rule Priority Must Be Configured Explicitly

When multiple `GeneralLedgerAccountAssignmentRule` records exist for the same TransactionType + LegalEntity combination, the system uses the priority ranking to select which rule applies. If priority is not explicitly set, the system will pick arbitrarily. Map your GL Assignment Rules with explicit priority values during implementation, and test all combinations in a Full Sandbox.

### "Contract from Order" Is Required for Amendment Correctness

Always generate contracts from the Order (not the Opportunity). Amendment order products maintain a technical linkage to the original records only when the contract was generated from the Order. Contracts generated from Opportunities lack these linkage fields, causing amendment billing to compute incorrect proration amounts.

### BillingBatchFilterCriteria Must Be Configured — Default Picks Up Everything

`BillingBatchFilterCriteria` on a `BillingBatchScheduler` acts as a filter for which BillingSchedules are processed in each run. Without explicit criteria, the batch run processes ALL active BillingSchedules in the org — in high-volume orgs this causes governor limit issues, long processing times, and potential row lock errors. Always define explicit filter criteria in production.

### Charging Subscription Products in RCB Requires ChargeType = Recurring

For amendment proration to calculate correctly in RCB, all subscription products must have `ChargeType = Recurring` on the Product. If ChargeType is missing or set incorrectly, amendment order products will not prorate — they will be treated as new charges.

### Multi-Currency: Invoice Currency = Order Currency — No Additional Config Needed

RCB natively carries the currency ISO code and amounts from Order to Invoice. The invoice currency will always match the associated price book entry currency used during order creation. For corporate currency reporting, amounts are converted using Salesforce's exchange rate provider. Set your corporate currency in Billing Settings — this drives the `CorporateCurrencyCnvAmount` fields on Payment and Invoice objects.

### Legal Entity Is Required Even When Not Using Tax Integrations

Best practice: create at least one LegalEntity record before configuring Billing or Tax treatments. Even if not currently using external tax engines, many billing objects (BillingTreatment, TaxTreatment, GL Assignment Rules) reference LegalEntity. Retrofitting LegalEntity references after go-live requires updating all related records.

### Consecutive Invoice Post Batch Jobs Setting Prevents Row Locks — Enable for High-Volume Orgs

For orgs with high invoice volumes (thousands of invoices per run), enable "Consecutive Invoice Post Batch Jobs" in Billing Settings. Without this, multiple post operations for the same account run in parallel, causing row lock errors on Account and related records. This setting is off by default and is not obvious from the documentation.
