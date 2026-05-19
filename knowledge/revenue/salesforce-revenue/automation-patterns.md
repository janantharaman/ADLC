---
source: hand-authored + RCA Internal Playbook (May 2025) + jongpie/NebulaFramework + jongpie/NebulaLogger + Usage Management - Community Learning (Salesforce Confidential, Internal Training, Revenue Lifecycle Advanced, Winter '25 - Spring '25) + Spring '25 RCB Hands On Exercises + RLM Spring '26 Developer Guide (API 66.0) + RCB Implementation Best Practices
cloud: Revenue Cloud
section: automation-patterns
last-updated: 2026-05-10
---

# Revenue Cloud — Automation Patterns

## Configure-Price-Quote Flow

**CPQ uses its own internal calculation engine** — do NOT use standard Record-Triggered Flows or Apex to manipulate CPQ Quote pricing calculations. The CPQ engine handles:
- Price Rules (Apex-free pricing logic — CPQ's version of Flow for pricing)
- Product Rules (validation and selection rules during configuration)
- Quote Calculator Plugin (Apex — only when Price Rules are insufficient)

**Pattern — guided selling (product filters and recommended products):**
```
CPQ Configuration (no Apex):
  Product Rule: If Opportunity Industry = 'Healthcare' → Hide non-compliant products
  Product Rule: If selected product requires an add-on → Add recommended option automatically
  Price Rule: If Quantity >= 100 → Apply volume discount tier 3
```

**Quote approval via CPQ Advanced Approvals (not standard Approval Process):**
- CPQ Advanced Approvals handles multi-tier deal desk approval
- It is a separate managed package (`apttus__`/`sbaa__`) — verify it is installed and licensed
- Do NOT mix CPQ Advanced Approvals with standard Salesforce Approval Process on `SBQQ__Quote__c`

## Contract Activation Automation

**Pattern — post-Contract activation:**
```
Record-Triggered Flow on Contract | After Save | Status changes to 'Activated'
  Note: Do NOT trigger CPQ processes from here — CPQ handles Subscription creation internally
  Safe actions after activation:
    → Create Task: 'Customer Success onboarding call' assigned to CSM
    → Send contract confirmation email to Account's contract contact
    → Create Opportunity for upsell (if contract value > threshold)
```

**Warning:** Inserting or updating `SBQQ__Subscription__c` or `SBQQ__QuoteLine__c` records in a trigger or Flow on Contract activation can cause infinite loops or double-processing. Always test in isolation.

## Renewal Automation

**Pattern — automated renewal opportunity creation (CPQ native):**
CPQ creates renewal quotes automatically based on `SBQQ__Quote__c.SBQQ__RenewalTerm__c` and Contract end dates. Configure this in CPQ Settings — do NOT build custom automation for this — CPQ's native renewal engine handles it.

**Custom addition — renewal notification:**
```
Scheduled Flow (daily):
  Query: Contract WHERE EndDate = TODAY + 90 AND SBQQ__RenewalForecast__c = false
  Loop: For each expiring contract
    → Create Task: 'Begin renewal conversation' assigned to Contract Owner
    → Update Contract: SBQQ__RenewalForecast__c = true (to prevent re-notification)
```

## Amendment Flow

Amendments (mid-contract changes: add seats, remove products, upgrade/downgrade) are handled via CPQ's Amendment button which creates an amendment Quote. Do NOT build custom amendment logic — use CPQ's built-in amendment flow:
1. Rep clicks `Amend` on the Contract
2. CPQ creates an amendment `SBQQ__Quote__c` with delta lines (positive/negative quantity changes)
3. Quote goes through standard approval flow
4. On approval, CPQ updates Subscription records with the amendments

**Custom addition — amendment approval routing by change type:**
```
CPQ Advanced Approvals (SBAA) configuration:
  Rule: If amendment increases TCV > 20% → Route to Sales Director
  Rule: If amendment decreases TCV > 10% → Route to VP Sales + Finance
```

---

## RLM (Revenue Cloud on Core) Automation Patterns

### Invocable Actions — Use Instead of Custom Apex

RLM exposes key processes as Invocable Actions callable from Flow, Apex, REST API, or Agentforce. Always prefer these over custom Apex for Q2C operations.

**Standard Invocable Actions (Spring '26 GA — see `implementation-guide.md` for full catalog):**

*Transaction Management:*
- `Create Contract Action` — create contract from a quote
- `Create Order From Quote` — place a single order from an accepted quote
- `Create Orders From Quote` — place multiple orders from one quote (requires `enableAdvCreateOrdersFromQuote`)
- `Create or Update Asset From Order` / `...From Order Item` — async asset creation (result via `CreateAssetOrderEvent`)
- `Initiate Amendment` — start amendment flow on active assets/contract
- `Initiate Cancellation` — cancel an active subscription/asset
- `Initiate Renewal` — trigger renewal flow for expiring assets
- `Initiate Transfer` — transfer assets to a different account
- `Initiate Rollback on Last Action` — roll back the last asset action
- `Get Renewable Assets Summary` — returns eligible-for-renewal asset list

*DRO (Fulfillment):*
- `Decompose Sales Transaction` — break order into fulfillment units
- `Submit Order` / `Submit Sales Transaction` — submit to DRO
- `Orchestrate Sales Transaction` / `Orchestrate Transaction` — full DRO orchestration
- `Freeze` / `Unfreeze Sales Transaction` — lock/unlock during fulfillment
- `Get Point Of No Return` — check cancellation cutoff

*Pricing:*
- `Run Salesforce Pricing Action` (Flow) / `Run Salesforce Headless Pricing Action` (API/Apex)

*Advanced Approvals:*
- `Review Approval Work Item` — approve/reject; `Recall`, `Reassign`, `Override`, `Cancel` actions also available

*Billing:*
- `Post Draft Invoice` / `Post Draft Invoice Batch Run`, `Issue Credit Memo`, `Apply Credit`, `Generate Invoice Documents`, `Write Off Invoices`, `Suspend Billing`, `Void Posted Credit Memo` — see full list in `implementation-guide.md`

*Usage Management:*
- `Invoke Summary Creation Action`, `Process Consumption Overages Action`, `Refresh Usage Entitlement Bucket Action`, `Retrigger Entitlement Creation Process Action`

*Rate Management:*
- `Invoke Rating Service Action` — rate usage records against rate cards

*Product Configurator:*
- `Run Config Rules Action` — execute constraint rules against product configuration

**Pattern — Agentforce quoting action:**
```
Agent Topic: Quote Management
Instruction: 
  1. Creation of new business quote requires Account, Opportunity, 
     Service Start Date, Product, Term (in months).
  2. Retrieve Account and Opportunity from record context if available.
  3. Term — always represent in months.
Actions: Create New Business Quote → Add QuoteLine → Apply Discount → Summarize Quote
```

### Dynamic Revenue Orchestrator (DRO) Patterns

DRO orchestrates post-order fulfillment. Design swimlanes in the visual canvas for order tasks and dependencies.

**Pattern — standard SaaS provisioning:**
```
Order Accepted
  → Decompose order into fulfillment units per product
  → Task 1: Provision software entitlement (system: ERP/provisioning API)
  → Task 2: Create support account (system: Service Cloud case)
  → Task 3: Send welcome email to customer contact
  → Task 4: Create Customer Success onboarding task
  → Update Asset status to 'Active'
```

**Pattern — amendment/renewal DRO:**
DRO automatically updates fulfillment tasks for amendments, renewals, and cancellations when configured. Do NOT build manual Flow automation for post-amendment provisioning — DRO handles it if properly configured.

### Pricing Engine Configuration (RLM)

RLM's pricing engine is fully configurable — unlike CPQ's black box:
1. Define `PricingPlan` with pricing steps in controlled sequence
2. Each step maps to a pricing operation (List Price → Volume Discount → Attribute Adjustment → Committed Spend Discount)
3. Customer controls what pricing data appears in transactional records (reportable)

**Pattern — attribute-based pricing:**
```
Product: Cloud Storage
Attributes: Region (US/EU/APAC), Term (12/24/36 months), Tier (Starter/Pro/Enterprise)
Pricing Plan:
  Step 1: Retrieve base list price from PriceList
  Step 2: Apply region-based adjustment (EU +10%, APAC +5%)
  Step 3: Apply term commitment discount (24mo -5%, 36mo -10%)
  Step 4: Apply tier volume discount from PriceAdjustmentSchedule
```

### RLM Approval Patterns

RLM Advanced Approvals are built in — no separate `SBAA__` package required.

**Approval types supported:**
- Parallel approvals (multiple approvers simultaneously)
- Efficient routing (approver determined by record data)
- Group approvals (unanimous or first-to-approve)
- Dynamic approvers (calculated at submission time)
- Smart approvals (skip if already approved at lower amount)
- Preview approvals (show approver chain before submitting)

---

## Apex Observability — Nebula Logger

For all Apex in RLM/ARM implementations, use **Nebula Logger** (`jongpie/NebulaLogger`) as the standard observability layer. This is the most widely adopted open-source logging framework for Salesforce Apex, with 900+ stars and active maintenance (last updated May 2026). It logs across Apex, Flow, LWC/Aura, and OmniStudio — critical for ARM implementations where fulfillment spans multiple execution contexts.

**Installation (Unlocked Package — recommended):**
```bash
sf package install --wait 20 --security-type AdminsOnly --package 04tg700000086Y5AAI
```

**Standard Apex logging pattern:**
```apex
// In any Apex class or trigger handler
Logger.info('Quote created', quoteRecord);
Logger.error('DRO task failed: ' + e.getMessage())
  .setRecord(orderRecord)
  .addTag('DRO')
  .addTag('fulfillment')
  .saveLog();
```

**Trigger handler pattern:**
```apex
// In SObjectTriggerHandler subclass
public override void afterInsert(Map<Id, SObject> newRecordsMap) {
    Logger.info('Order insert - ' + newRecordsMap.size() + ' records');
    // ... trigger logic ...
    Logger.saveLog();
}
```

**Flow logging:**
Add the "Add Log Entry" invocable action in any Flow step — no Apex needed. Tag entries by process name for filtering in the Log viewer.

**LWC logging:**
```javascript
import { getLogger } from 'c/logger';
const logger = getLogger();
logger.info('Quote summary loaded').saveLog();
```

**Key objects stored by Nebula Logger:**
- `Log__c` — transaction-level record
- `LogEntry__c` — individual log lines with level, message, related record
- `LogEntryTag__c` / `LoggerTag__c` — tagging/filtering
- `LoggerScenario__c` — scenario grouping for end-to-end traces

**Configuration:**
- `LoggerSettings__c` (custom metadata) — retention, default log level, async save
- `LogEntryDataMaskRule__mdt` — mask PII fields before persistence (required for HIPAA/GDPR orgs — see security-model.md)

**ARM-specific guidance:**
- Tag log entries by DRO task name, pricing step, and invocable action name to trace the full Q2C execution path
- Set `setSaveMethod('QUEUEABLE')` in high-volume order processing paths to avoid governor limits
- Data masking rules are mandatory if logging quote/order lines that contain pricing or customer PII

---

## Usage Management — Concepts and Patterns

### Module Overview

Usage Management in Revenue Lifecycle Advanced covers five capability areas, released incrementally:

| Module | What It Does | Released |
|---|---|---|
| **Wallet Management** | Entitlements per asset; drawdown tracking; wallet balance per resource | Spring '25 |
| **Usage Modelling** | Define usage resources, grants, policies; product-to-resource association | Winter '25 |
| **Usage Selling** | Purchase experience; rate card visibility during quoting; rate negotiation | Winter '25 |
| **Rate Management** | Rate cards, tiered rates, attribute-based rates, rating procedures | Winter '25 |
| **Consumption Lifecycle** | Mediation ingestion; aggregation; overage rating; liable summary; billing | Spring '25 |

Available in: **Revenue Cloud Advanced and Plus** (Usage Selling, Rate Management); **Revenue Cloud Billing** (Consumption, Wallet, Drawdown)

### Core Concepts

#### Anchor Product vs Pack

**Anchor Product** — the main service subscription. Has a subscription price and recurring period. May grant included resources (Usage Resource Grants). Defines overage rates.

```
Example: Quantum Collaboration Suite — $300/mo
  Included resources (Usage Resource Grants):
    Call Meetings     100 EA    $1/call overage
    Video Meetings     50 EA    $3/video overage
    Emails             10K      $0.05/email overage
    Data Transfer      10 GB    $10/GB overage
```

**Pack** — add-on, not a service. Grants additional quantity of one or more resources. Can be one-time or recurring. Examples: "200 Call Meetings Pack", "100 Quantum Credits Pack". Packs are used to sell resource add-ons and give customers more predictability on usage costs.

**Key distinction:** Anchor products are the service; packs are additional quantities of resources for that service.

#### Usage Resource

A thing that can be consumed, measured, and rated. Examples: API Calls, Cloud Storage (GB), Call Meetings, Video Meeting Duration (minutes), Data Transfer (GB).

**`UsagePersists` flag on UsageResource:** Determines aggregation behavior.
- `UsagePersists = false` (Data Transfer): consumption is additive — use SUM. Day 1: 1GB, Day 2: 0.2GB → Total: 1.2GB
- `UsagePersists = true` (Data Storage): consumption is a point-in-time measurement — use PEAK, not SUM. Day 1: 1GB, Day 2: 2.5GB, Day 3: 1.5GB (cleaned up) → PEAK = 2.5GB. Never sum storage — that would be wrong.

#### Product Usage Grant

Governs what resources are granted when a customer purchases a product. Each grant has:

| Property | Description |
|---|---|
| `Quantity` | Amount granted (e.g., 100 EA, 10 GB) |
| `Rollover Policy` | Unused resources rollover (yes/no, how many times) |
| `Proration` | Whether to prorate on partial periods |
| `Renewal Policy` | Renewal frequency (can differ from subscription frequency — annual sub, monthly grant renewal) |
| `Validity` | How long entitlements are valid |
| `Billing Policy` | Billing frequency for usages in arrears |
| `Usage Product Definition` | Billing SKU — how the overage appears on the invoice |

**Billing Policy aggregation methods:** Event (per-event rating), SUM, PEAK, LAST, FIRST

**Effectivity on grants:** Multiple grants for the same resource with different date ranges (effectivity from/to) allow different included quantities over time. The system slices at order time.

#### Unit of Measure (UoM)

Customers define their own UoM classes and units with conversion factors:
- TIME class: Microseconds, Milliseconds, Seconds (base), Minutes, Hours, Day (default)
- ITEM COUNT class: Each (base), Dozen, 100 EA, 1K EA, 1M EA (default)
- BYTE class: Byte (base), KB, MB, GB (default), TB, PB

**UoM conversion is used in rating.** Example: Rate = $12/GB, Consumption = 85 MB → Overage = 85 MB × ($12/1000 MB) = $1.02. Six decimal precision supported. Current release supports default UoM only (future releases will allow any unit).

### Rate Management

**Rating Procedure = Base Rate × Tier Rate × Attribute-Based Rate**

Three stacking rate types:
1. **Base Rate** — flat rate per unit (e.g., $10/GB)
2. **Tier Rate** — adjustment based on consumption quantity ranges (e.g., 0–5 GB: -10%, 5–10 GB: -20%, 10–50 GB: -30%)
3. **Attribute-Based Rate** — adjustment based on product/consumption attributes (e.g., INBOUND: +25%, OUTBOUND: +50%)

**Tier Types:**
- **Discrete (COUNT):** Lower bound inclusive, upper bound inclusive (NGP rule). Used for countable items.
- **Continuous (BYTE/GB):** Lower bound inclusive, upper bound exclusive (NGR rule). Used for continuous resources.

Salesforce Pricing (NGP) supports discrete tiers only. Rating (NGR) supports both discrete and continuous.

**Rating Procedure** is an ordered stack of rating elements that compute the net rate. Pricing Manager sets up rates; Pricing Designer builds the procedure. Rate lifecycle management prevents unintended changes.

**Rating Discovery** — defines which rates are available for selling (visible during quoting). Must be active and set up before sales reps can see rates during browsing/quoting.

### Usage Build Sequence (Design-Time)

Think top-down; build bottom-up:

| Step | What | Change Frequency |
|---|---|---|
| 1 | Unit of Measure Classes / Units | Infrequent — fewer than a dozen |
| 2 | Usage Product Definitions (billing SKUs) | Infrequent — fewer than 100 |
| 3 | Policies (Rollover, Refresh, Aggregation) | Infrequent — fewer than 10 each |
| 4 | Usage Resources | Infrequent — fewer than 100 |
| 5 | Sellable Usage Products + Product Usage Grants + Rating Policies | Frequent — hundreds or more |
| 6 | Rate Cards + Rate Card Entries | Rate cards: few; entries: hundreds or thousands |

### Usage Selling Journey (Run-Time)

```
Pricing Manager defines rates → Rate Cards + Rate Card Entries
Pricing Designer builds Rating Procedure + Rating Discovery
Sales Rep browses catalog → sees usage products with resource/rate card details
Sales Rep creates Quote → adds usage product as Quote Line Item
  → selects Grant Binding (Self/Asset or Target/Custom Tenant)
  → views and negotiates rate cards
Sales Rep submits order → Order Management provisions services
Customer consumes resources → Mediation meters consumption events
System aggregates consumption → DPE jobs create Usage Summaries
Rating engine rates overages → creates Rateable Summaries
Wallet drawdown occurs → debit transactions per wallet
Billing reads Liable Summaries → generates invoice
```

**Grant Binding:** When purchasing, choose where grants are allocated:
- **Self (Asset):** Grants allocated to wallet bound to the asset created for the chosen product
- **Target (Custom Tenant):** Application identifies target ID via customization

### Consumption Lifecycle Flow

1. **Mediation:** External system meters consumption → sends raw consumption logs to Salesforce
2. **Aggregation:** DPE jobs run aggregation (SUM or PEAK depending on UsagePersists) per policy definition
3. **Rating:** Rating engine checks if resources were purchased with grants; calculates overages; rates overages against negotiated rate card
4. **Wallet Drawdown:** Consumed units redeemed from wallet balance (configurable: expire-first, create-first, or create-last draw order)
5. **Liable Summary:** Monthly summary with consumed units, overage units, rate, and total payable amount
6. **Billing:** Reads Liable Summaries → generates invoices for overage charges

### Usage Management — Key Configuration Setup Paths (Appendix B)

| Setting | Path |
|---|---|
| Context Service (prerequisite) | Context Service > Context Service Settings |
| Rate Management | Setup > Usage Management > Usage Management Settings |
| Rating Setup (Rating Waterfall + Persistence) | Setup > Usage Management > Rate Management Setup |
| Rate Management: Admin | Permission Sets |
| Rate Management: Design Time User | Permission Sets |
| Rate Management: Manager | Permission Sets |
| Rate Management: Run Time User | Permission Sets |

**Key Decision Table Definitions for Usage Management:**
- Binding Object Rate Adjustment Resolution Entries
- Binding Object Rate Card Entry Resolution Entries
- Rate Card Entry Resolution Entries 2
- Rate Adjustment by Attribute / Tier / Volume Resolution Entries
- Pricebook Rate Card Entries
- Asset Rate / Asset Rate Card Entry / Asset Tier-based / Volume-based adjustments
- Attribute-based Rate Adjustment by Rate Card Entry ID (multiple variants)

**Key Flows for Usage Management:**
- Call Rating Service
- Call Entitlement Refresh Service
- Create Summary
- Generate Liable Summary
- Generate Usage Rateable Summary
- Generate Usage Summary
- Orchestrate Usage Management

**Key DPE Templates:**
- Create Liable Summary Template
- Create Usage Summary Template

### Usage Management — Post-Deployment Steps (for Selling / Revenue Cloud Advanced)
1. Confirm Rates, Grants, and Policies for usage products are set up and active
2. Extend and sync the SalesTransaction context definition
3. Confirm pricing procedure is active and set up correctly in Revenue Settings
4. Refresh Decision Tables referenced in pricing procedures
5. Set up and activate the rating discovery procedure
6. Sync the RatingDiscovery context definition
7. Refresh all Decision Tables used in the rating discovery procedure

### Usage Management — Post-Deployment Steps (for Consumption / Revenue Cloud Billing)
1. Clone and set up the Orchestration Flow
2. Configure Data Processing Engine (DPE) jobs
3. Set up and activate the rating procedure
4. Sync the Rate Management context definition
5. Refresh all Decision Tables used in the rating procedure

---

## Billing Automation (if blng__ installed)

**Pattern — invoice generation on Order activation:**
```
Record-Triggered Flow on Order | After Save | Status = 'Activated'
  Invoke Apex: blng.TriggerHandler.processOrders() 
  (Note: Billing triggers are handled by the Billing package — do not replicate)
```

**Pattern — payment collection follow-up:**
```
Scheduled Flow (daily):
  Query: blng__Invoice__c WHERE DueDate < TODAY AND Status != 'Paid' AND Status != 'Cancelled'
  Loop: For each overdue invoice
    → Create Task: 'Follow up on overdue invoice' assigned to Account Owner
    → Send payment reminder email to billing contact
```

---

## Revenue Cloud Billing (RCB) — Native Platform Billing Automation

RCB is platform-native (no managed package). All billing automation uses standard Flows, Invocable Actions, Business APIs, and the Context Service. Governor limits apply in full.

### Context Aware Billing Schedule API

The core billing engine. BillingSchedules are generated via Context Service — not by direct SOQL insert.

```
BillingContext Definition (Setup → Context Definitions → BillingContext)
├── Structure Nodes
│   ├── BillingTransaction node set (does NOT share relationship with BSG node set)
│   │   ├── BillingTransaction → Order
│   │   ├── BillingTransactionItem → OrderItem
│   │   ├── BillingTransactionItemRelationship → OrderItemRelationship
│   │   └── BillingTransactionItemDetail → OrderItemDetail
│   └── BSG Node set
│       ├── BillingScheduleGroup → BillingScheduleGroup
│       ├── BillingSchedule → BillingSchedule
│       └── BillingScheduleGroupRelationship → BillingScheduleGroupRelationship
└── Two predefined mappings
    ├── OrderEntitiesMapping (BillingTransaction nodes → Order entities)
    └── BSGEntitiesMapping (BillingSchedule nodes → BSG entities)
```

**Business API — Create Billing Schedules from Orders:**
```
POST /commerce/invoicing/billing-schedules/actions/create
Body: { "orderIds": ["801xx000000..."] }
```

**Business API — Create Billing Schedules from any transaction (standalone):**
```
POST /commerce/invoicing/standalone/billing-schedules/actions/create
```
Use for external transactions — bypasses Order requirement.

**Invocable Action (Flow):**
```
Action: createBillingSchedules
Input: orderId (string, required)
```

### Invoice Generation Patterns

**Scheduled Invoice Batch (BillingBatchScheduler):**
- Create a `BillingBatchScheduler` record with cron expression
- Each run creates an `InvoiceBatchRun` record
- `BillingBatchFilterCriteria` determines eligible BillingSchedules
- After generation, invoices start in `Draft` status

**Post Invoices (Draft → Posted):**
```
POST /commerce/invoicing/invoices/collection/actions/post
Body: { "invoiceIds": ["0GX..."] }
```
Also available as invocable action `postInvoices` for use in Flow.

**Bill Now (On-Demand, Account-Level):**
- UI: Account record → dropdown → "Generate Invoices" → select Target Date, Invoice Date, Status
- API: `POST /commerce/invoicing/invoices/collection/actions/generate`
- **Limit:** Account must have ≤ 200 BillingSchedules; use BillingBatchScheduler for larger accounts

**Invoice Preview API (no persistent storage):**
```
POST /commerce/invoicing/invoices/collection/actions/preview
```
- Returns invoice + line data for next 2 billing periods
- Does NOT store invoices in Salesforce
- Limitations: no ARC orders, no Milestone billed products, max 200 BillingSchedules, no usage overages

**External Invoice Ingestion (standalone invoice):**
```
POST via Invoice Ingestion API
```
- Creates invoices without BillingSchedule/BSG — for migration from other billing systems or one-time invoices with no subscription

### Billing Policy / Treatment Hierarchy Setup Pattern

```
Step 1: Create BillingTreatmentItem(s)
        - BillingType: Advance | Arrears
        - Type: Percentage (100%) | FlatAmount | Remainder
        - Status: Active
        - ZeroAmountBehavior: Create Invoice (required field)

Step 2: Create BillingTreatment
        - Add BillingTreatmentItems to the related list
        - Set Status → Active

Step 3: Create BillingPolicy
        - Set DefaultBillingTreatmentId
        - Set Status → Active

Step 4: Assign BillingPolicy to Product2
        (via ProductSellingModel or direct product field)
```

**Legal entity routing:** If `BillingTreatment.LegalEntityId` matches the Order's LegalEntity, that treatment is used. If no match, the BillingPolicy's DefaultBillingTreatment is used. If no default, billing fails.

### Milestone Billing Pattern (One-Time Products Only)

```
1. Create BillingPolicy (e.g., "Milestone Billing")
2. Create BillingTreatment → check "Enable Milestone Billing"
3. Create BillingTreatmentItems with:
   - MilestoneType: "Date" or "Event"
   - MilestoneCommencementTrigger: Order Product Activation Date
4. Assign BillingPolicy to One-Time sellable products
5. Runtime:
   - Order activation → BillingMilestonePlan auto-created
   - BillingMilestonePlanItems created per configured milestone
   - Event-based items: mark "Milestone Accomplished" → Status changes to "Ready for Invoicing"
   - Date-based items: auto-marked "Ready for Invoicing" on configured date
   - Invoice Scheduler picks up "Ready for Invoicing" items
```

**Milestone limits:** ≤ 20 BillingMilestonePlanItems per plan (configurable org value). Amendments supported for uninvoiced milestones only — void invoice first to edit invoiced milestones.

### Suspend and Resume Billing

```
Suspend: POST /commerce/invoicing/actions/suspend-billing
  Body: { "billingAccountId": "..." }  — suspends entire account
  OR    { "billingScheduleGroupIds": ["..."] }  — suspends specific BSGs

Resume:  POST /commerce/invoicing/actions/resume-billing
```

BSGs in `Suspended` status are skipped by invoice batch runs. Resumption does NOT restart the billing cycle — it picks up from where it left off.

### Credit Memo Automation Patterns

**Auto-create from negative invoice lines (billing setting):**
- Toggle in Billing Settings: "Convert Negative Invoice Lines to Credit Memos"
- When enabled: any posted invoice with a negative line auto-generates a CreditMemo

**Credit application settings:**
- "Credit Application Level": `Invoice` (apply CM balance to entire invoice) or `InvoiceLine` (apply CM line to invoice line)
- "Auto Apply Credit Balances" setting: when enabled, available credit balances are automatically applied to new invoices on generation

**Standalone Credit Memo API:**
```
POST /commerce/invoicing/credit-memos/actions/generate
```

**Create and Apply in one call:**
```
POST /commerce/invoicing/credit-memos/creditMemoId/actions/apply
POST /commerce/invoicing/credit-memo-lines/creditMemoLineId/actions/apply  (line level)
```

**Unapply and Void:**
```
POST /commerce/invoicing/credit-memo-inv-applications/creditMemoInvApplicationId/actions/unapply
POST /commerce/billing/credit-memos/creditMemoId/actions/void  (void Posted CM → creates DebitMemo)
```
Invocable actions also available: `applyCredit`, `unapplyCredit`, `voidPostedCreditMemo`

### Write-Off Invoices

```
POST /commerce/invoicing/invoices/actions/write-off
Invocable Action: writeOffInvoices (requires Billing Operations User + Credit Memo Operations User perm sets)
```
Creates credit memos with the write-off amount and closes the invoice.

### Void Invoice

```
POST /commerce/invoicing/invoices/invoiceId/actions/void
```
Voids a posted invoice to allow rebilling. Use before amending any invoiced milestones.

### Recover Billing Schedules (Error Recovery)

```
POST /services/data/v66.0/actions/standard/recoverBillingSchedules
Input: billingScheduleId (in Error or Processing status)
```
Also available via: `POST /commerce/invoicing/billing-schedules/collection/actions/recover`

### Tax Engine Integration Pattern

```
1. Install external tax provider integration package (Avalara, Vertex, etc.)
2. Create Named Credential (Setup → Named Credentials)
3. Create TaxEngine record:
   - TaxEngineProvider
   - Named Credential
   - Status: Active (ONLY active engines are called for tax calc)
   - Mailing address + seller code
4. Create TaxTreatment:
   - IsTaxable: true
   - TaxCode (product code for tax engine)
   - TaxEngineId → your TaxEngine record
5. Create TaxPolicy:
   - TreatmentSelection: Default | LegalEntity | Manual
   - DefaultTreatmentId
   - Status: Active
6. Assign TaxPolicy to Product2
```

**Tax is calculated at OrderItem creation** when `IsTaxable = true`. Use Full Sandbox for testing tax callouts — never test with live tax engine in Developer Edition.

### Payment Terms Setup

```
Payment Term (Status: Active, Default checkbox)
    └── PaymentTermItem
        ├── Type: Period-Based          → Invoice + N Days (e.g., Net 30)
        │   Period: 30, PeriodUnit: Day, PaymentTimeline: Standard
        └── Type: Derive End of Month   → EOM + N Days (e.g., EOM + 30)
            Period: 30, PeriodUnit: Day, PaymentTimeline: Standard
```

**Rules:** Cannot activate PaymentTerm without a PaymentTermItem. Cannot change Inactive → Draft. Only one Standard PaymentTimeline per PaymentTerm.

### GL / Accounting Journal Automation

```
GeneralLedgerAccount (AccountingType: Asset | Liability)
    ↑ assigned by ↑
GeneralLedgerAccountAssignmentRule
  - TransactionType (invoice line, CM line, payment, tax)
  - LegalEntityId
  - DebitGLAccount, CreditGLAccount

Runtime (on Invoice Post):
  TransactionJournal created
  ├── Debit entry  → AR GL Account
  └── Credit entry → Revenue GL Account
```

**Priority:** When multiple GL Assignment Rules exist for the same TransactionType + LegalEntity, the system uses priority ranking to select the correct rule.

**Accounting Period management:** Each LegalEntity has `LegalEntityAccountingPeriod` records. Close periods via a DPE definition configured in Billing Settings (General Billing Settings → DPE definition for closing Legal Entity Accounting Periods).

### BillingBatchScheduler Pattern (Automated Invoice Runs)

```
BillingBatchScheduler (schedule by cron)
    └── InvoiceBatchRun (per execution)
         └── BillingBatchFilterCriteria (eligible BillingSchedules)
              └── Invoices generated (Draft)
                   └── InvBatchDraftToPostedRun (posts all Draft invoices from the run)
```

**Enable Consecutive Invoice Post Batch Jobs** (setting) for high-volume orgs — prevents row lock errors when multiple invoices are generated for the same account simultaneously.

### Invoice PDF Document Generation

```
1. Design template in Document Template Designer (OOB template available)
2. Billing Settings → Document Generation toggle = ON
3. Assign template to BillingAccount.InvoiceDocumentTemplateId (API 66.0+)
   OR use org-default template in Billing Settings
4. Email delivery: configure email template in Billing Settings
   → attach PDF to BillingAccount via BillingAccount.ShouldAttachInvoiceDocToEmail = true
```

Async batch doc generation API:
```
POST /commerce/billing/invoices/invoice-batch-docgen/{invoiceBatchRunId}/actions/{actionName}
```

### Key Billing Business APIs Summary

| Category | API Endpoint | Action |
|---|---|---|
| Billing Schedules | `/commerce/invoicing/billing-schedules/actions/create` | Generate from Orders |
| Billing Schedules | `/commerce/invoicing/standalone/billing-schedules/actions/create` | Generate from any transaction |
| Billing Schedules | `/commerce/invoicing/billing-schedules/collection/actions/recover` | Error recovery |
| Suspend/Resume | `/commerce/invoicing/actions/suspend-billing` | Suspend account/BSG |
| Suspend/Resume | `/commerce/invoicing/actions/resume-billing` | Resume account/BSG |
| Invoices | `/commerce/invoicing/invoices/collection/actions/generate` | Bill Now |
| Invoices | `/commerce/invoicing/invoices/collection/actions/post` | Post drafts |
| Invoices | `/commerce/invoicing/invoices/collection/actions/preview` | Preview (no storage) |
| Invoices | `/commerce/invoicing/invoices/invoiceId/actions/void` | Void posted invoice |
| Invoices | `/commerce/invoicing/invoices/actions/write-off` | Write off |
| Invoices | invoice ingestion API | External/standalone invoice |
| Credit Memos | `/commerce/invoicing/credit-memos/actions/generate` | Create standalone CM |
| Credit Memos | `/commerce/invoicing/credit-memos/{id}/actions/apply` | Apply CM to invoice |
| Credit Memos | `/commerce/invoicing/invoices/{id}/actions/convert-to-credit` | Convert negative lines to CM |
| Credit Memos | `/commerce/billing/credit-memos/{id}/actions/void` | Void posted CM |
| Payments | `/revenue/billing/transactions/actions/apply` | Apply payments + credits |
| Accounting | Send email for batch run | `/commerce/invoicing/invoice-batch-runs/actions/send-email` |

### Key Billing Invocable Actions (for Flow)

| Action Name | Purpose |
|---|---|
| `createBillingSchedules` | Generate BillingSchedules from Order |
| `postInvoices` | Post Draft invoices |
| `applyCredit` | Apply CM or CM line to invoice |
| `unapplyCredit` | Unapply CM from invoice |
| `unapplyPayment` | Unapply a payment from invoice |
| `voidPostedCreditMemo` | Void a Posted Credit Memo → creates DebitMemo |
| `writeOffInvoices` | Write off unpaid/partial invoices |
| `recoverBillingSchedules` | Recover billing schedules in Error/Processing status |

### Key Billing Platform Events

| Platform Event | Trigger |
|---|---|
| `BillingScheduleCreatedEvent` | BillingSchedule created via Context Service API |
| `BillSchdCreatedEventDetail` | Per-OrderItem detail within a BillingScheduleCreatedEvent |

Subscribe to `BillingScheduleCreatedEvent` to react asynchronously after billing schedules are created (e.g., set downstream flags, trigger provisioning).

### RCB Charge Type → BSG Billing Term Unit Mapping

| Product Charge Type | BillingTermUnit on BSG |
|---|---|
| One-Time | `One-Term` |
| Recurring (Monthly) | `Monthly` |
| Recurring (Annual) | `Annual` |
| Recurring (Semi-Annual) | `Semi-Annual` |
| Usage-Based | Determined by UsageResource billing period |

### Implementation Best Practices (5 Pillars)

**1. Data Foundation & Architectural Integrity**
- Create LegalEntity first — it anchors Tax, Billing, and Revenue treatments
- "Twin Field" strategy: match API names and types for custom fields across Product, Quote, and Order so data flows seamlessly through the Lead-to-Cash lifecycle
- Cleanse Product Catalog before going live — redesign legacy products for RCB's constraint rules engine

**2. Automation & Performance**
- Use Flow (record-triggered on record creation) to set critical fields like `MatchingId` on UsageSummaries or LegalEntity on Order Products
- Do NOT add custom Apex triggers on Order or OrderItem — they cause unpredictable order-of-operations conflicts with RCB's internal triggers
- Enable Consecutive Invoice Post Batch Jobs for high-volume orgs

**3. Subscription & Amendment Guardrails**
- Always generate contracts from the Order (not the Opportunity) to maintain correct amendment linkage
- Before amending a contract, ensure all related Draft invoices are Posted or Cancelled — amending while invoices are in Draft creates ghost billing lines
- Ensure all subscription products have `ChargeType = Recurring` for amendment proration to calculate correctly

**4. Integration & Financial Alignment**
- Define the "Point of Handoff" early: Lead-to-Invoice (Salesforce is SoR) vs Lead-to-Order (ERP handles invoicing)
- Map GL Rules and GL Treatments to mirror your ERP's chart of accounts before go-live
- Use external tax engine (Avalara/Vertex) for real-time tax. Test tax callouts in Full Sandbox only

**5. Testing & Change Management**
- Test Cancel-and-Rebill with your maximum anticipated invoice line count — it is resource-intensive and triggers custom automation
- Finance and RevOps teams must approve invoice PDF layout and revenue recognition schedules before sign-off
