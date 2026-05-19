---
source: Rev Cloud Practice FY27 — ARM Implementation Enablement and Lessons Learned (AMERS Revenue Cloud Practice, Internal) + Best Practices for Implementing Revenue Cloud Advanced + Revenue Cloud Developer Guide v66.0 Spring '26 (Salesforce) + Revenue Cloud Deployment Guide (Pilot) Spring '26 Feb 2026 + Spring '25 RCB Hands On Exercises + RCB Implementation Best Practices + RCB Rate Card Feb 2026 + RCB Dual Billing Model (July 2025)
cloud: Revenue Cloud Advanced / Agentforce Revenue Management (ARM)
section: implementation-guide
last-updated: 2026-05-10
---

# Revenue Cloud — Implementation Guide

This file contains implementation-level guidance sourced from the AMERS Revenue Cloud Practice FY27 internal enablement deck. Use this during Design and Implementation phases to ground architectural decisions in real delivery experience.

---

## TL;DR — What Every Architect Must Know Before Starting

1. **Timeline and cost:** Typical ARM implementation is 10–18+ months and $2.5M–$5M+. Set or reset expectations early.
2. **Lead with Define & Design:** For large transformations, always recommend a Define & Design phase first before scoping the full build.
3. **MVP first:** Focus the first release on a tightly scoped MVP with core quoting. Complexity comes in later releases.
4. **Not a lift-and-shift:** No "easy button" migration from CPQ to ARM. Refactoring migration requires both data transfer tools and reimplementation.
5. **ARM is more complex than CPQ:** Requires deeper technical and platform expertise. Functional domain leadership is equally critical.
6. **Roadmap unknowns are real:** Feature gaps may drive near-term customization. Always customize in a way that is easy to refactor when the OOTB feature arrives.
7. **Zero room for error:** Revenue flows must be validated end-to-end on real scenarios and data before go-live.
8. **Transactional data migration is underestimated:** Budget significant time for migrating orders, subscriptions, assets from legacy systems.

---

## Key Lessons from Real Implementations

### What Causes Failures

| Anti-Pattern | What Happens |
|---|---|
| Compressed timelines | Scope creep + chaos at go-live |
| Lift-and-shift mindset | Technical bloat, blocks innovation |
| No executive owner | No cross-functional alignment, stalled decisions |
| Re-platforming broken processes | Garbage in, garbage out — must rethink the process |
| Neglecting change management | Users not prepared, adoption fails |
| Wrong team | ARM requires specialized skills — generalists will struggle |
| Integration gaps | Disconnected systems derail execution |
| No iteration plan | Stalled progress post go-live |

### Validated Observations from Implementations

- ARM implementations **expose revenue process maturity gaps** — the project will surface broken processes the customer didn't know they had
- **First 60–90 days** are critical — early alignment determines the entire program trajectory
- ARM requires an **executive owner with a strong business case** — not just a project manager
- ARM value is delivered **in phases**, not fully at go-live — communicate this upfront
- **Integrations, data, and change management** are core scope, not add-ons
- **Cheapest ARM implementations become the most expensive** — under-resourcing causes rework
- **Data volume and pricing complexity drive risk** — scope these carefully
- **Adoption leads to expansion** — early user success is the key to Phase 2

---

## Implementation Methodology

### Phase Structure: PLAN → BUILD → LAUNCH → ITERATE → EXPAND

**PLAN**
- Align on Revenue Cloud vision and objectives
- Establish program governance
- Define Revenue Cloud transformation plan
- Design foundation for MVP and future scale

**BUILD**
- Iterative development by sprint
- Migrate configurations from existing solution
- Transform processes using new innovations
- Execute end-to-end testing

**LAUNCH**
- Deploy and launch MVP
- Transform and migrate transactional data
- Support human-centered change management
- Measure KPIs and adoption

**ITERATE**
- Optimize solution based on user feedback
- Configure complex requirements
- Support and monitor production

**EXPAND**
- Scale to additional product lines, BUs, and regions
- Transition and enable customer team
- Innovate with ongoing product releases
- Expand with omnichannel sales
- Activate AI-powered efficiencies

---

## Define & Design Phase (Recommended for Large Transformations)

Always recommend Define & Design for large transformations. It is a 12–15 week engagement (3 phases):

### Phase 1: Discover (Weeks 0–4)
- Aligned program vision and objectives
- As-Is Quote-to-Cash analysis (foundational processes, capabilities, technical architecture)
- Prioritized solution capabilities aligned to Epics and Features
- Project kickoff and stakeholder mapping

### Phase 2: Define (Weeks 5–9)
- Future State process diagrams (changes from As-Is, pain points solved, key personas)
- Capability-based reverse demos and future state visioning sessions
- Prioritized capabilities for MVP agreed upon
- Future State Epics and Features for MVP

### Phase 3: Design + Readout (Weeks 10–13)
- Solution Design Document
- User stories for first two sprints
- Phased implementation plan and alignment on Phase 1 scope
- Phase 1 project budget and resource plan
- OR handover to chosen implementor with knowledge transfer

**Key customer time commitments during Define & Design:**
- Executive Sponsor: 2–3 hours in weeks 1–2, occasional touchbase through delivery
- Business Owner(s): 20% weeks 1–2, then 3–4 hrs/week for sprint demos and UAT
- Product Owner: 100% — full-time role owning the backlog
- Technical Architect: 50% design, 50–100% implementation
- Project Manager: 100% throughout

---

## Qualifying & Scoping Questions (for Pre-Sales and Discovery)

### Initial Qualifying Questions
- What is the customer's existing quoting and/or billing solution? Are they on legacy CPQ or Billing?
- Have Revenue Cloud licenses been sold? If not, what is the license deal timeline?
- Does the customer have a timeline and budget expectation? (Set expectations: 10–18+ months, $2.5M–$5M+)
- What capabilities does the customer intend to use? (This has large impact on LOE)
- Have they identified an MVP use case? Encourage starting with lower complexity.
- Does the customer intend to do business process transformation, or just re-platform?
- Is there transactional data (quotes, orders, invoices, assets, subscriptions) in another system that needs migration?
- What sales channels will be in scope? (Direct, partner, self-service?)

### Products & Pricing (1hr session)
- How many unique products or services do you sell?
- What system is currently your product master? Your pricing master?
- Are products ever bundled or sold as a package?
- How are products priced? (One-time, Subscription, Usage)
- Do you offer special pricing? (Contracted, Cost & Margin, Tiered Discounts, Multi-year Ramps, Free Trials)
- What attributes are captured during the sales cycle that impact price? (Standard: Quantity/Date; Complex: Distance, Material Type, Customer Segment)
- Do you allow sales reps to provide discretionary discounts? Describe that process.
- How often do prices change? How does it affect existing customers?

### Quoting & Approval (1hr session)
- How are quotes done today? How standardized are they across the business?
- Do you currently use Opportunities in Salesforce?
- Describe scenarios when a customer receives a quote. How many versions during a typical sales cycle?
- Do you have systematic approvals? What % of quotes require approval?
- What types of people approve a quote? (Legal, Finance, Sales Ops, Sales Management)
- Does the quote document also serve as a legal contract?
- Are you planning to use CLM for redlining and obligation management?

### Ordering & Asset Lifecycle Management (1hr session)
- Do you plan to use Salesforce Orders to support fulfillment?
- If DRO is in scope — raise a DSR for additional scoping support
- How often do customers require changes to products or pricing?
- What is your change or cancellation process today?
- Do you process renewals?

### Invoicing & Billing (1.5hr session)
**Important: Revenue Cloud Billing does NOT support revenue recognition. Not on near-term roadmap as of Feb 2026. Recommend third-party tools such as RightRev.**

- What invoicing/payment models does your business use? (Recurring, usage, one-time, milestone)
- How many invoices do you generate per month? Same day or anniversary billing?
- Do you operate in countries with strict government invoicing requirements? (Brazil, etc.)
- Do you invoice in Japanese Yen? What currencies are involved?
- What taxation engine do you use? (Vertex or Avalara for US; may use OOB Salesforce Tax Engine for simple international)
- What payment processor? Intending to continue or switch to Salesforce Payments?
- What payment terms do you offer? (Net 30/60/90 or complex terms)
- Describe Dunning & Collections processes
- How do you manage aging reporting? (ERP or billing system)
- Do you apply late fees? Offer refunds?
- Do you issue credits? Automate allocation of credits to future invoices?
- Do you need full GL setup in Salesforce? Financial periods and closing procedures?
- How many legal entities? How many GL accounts per entity?
- Do you have an existing ERP integration? More than 1 ERP? How often do you sync data?

---

## Release 1 PI Plan — Core ARM Capabilities by Sprint

Use this as a reference when estimating scope for a first release.

### Product Catalog & Bundles
- Product Catalog(s) and Product Categories
- Products, child products, and groups
- Product Classifications
- Attributes and Attribute Categories
- Units of Measure, Rate Management, Percent of Total
- Product2 Custom Fields

### Constraint Engine
- Quantity validations, Geo validations
- Warning messages, Compatibility messages, Product conflict messages
- Auto-add required products

### Product Discovery
- Default Catalog, Product filtering by Plan/Product Line/Family
- Product Qualification/Disqualification Rules

### Pricing & Waterfall
- Pricebook & Pricebook Entries
- Discounting (Channel, Volume, Attribute, Bundle), Cost, Margin, MRR
- Selling Model, Price Waterfall Procedure
- Apex hooks, Procedure Plans, Context Definitions
- Custom Field Mapping, Ramped Bundles, Contract Pricing

### Quoting
- TLE Column and Detail Selection, Quote Layout & Custom Fields
- Quote Creation, Opportunity Syncing, Custom Opportunity Product fields
- TLE Grouping, Contract Generation, Approval Button
- Transaction Summary on Quote, Lightning Preview Document

### Ordering
- Order and Order Product Page Layouts
- Twin fields from Quote Line to Order Line and Quote to Order
- Transaction Summary on Order, Order Generation, Order Activation

### Approvals
- Default Approval Orchestration Flow, Notification templates
- Flow/Subflow framework

### Asset Management (Amend / Renew / Cancel)
- Amendment, Renewal, Cancel, Replacement structures
- Cancel & Replace, Early Renewal, Channel amendments

### Dynamic Revenue Orchestration (if in scope)
- Fallout and SLA Jeopardy Administration
- Extend Sales Transaction Context Definition
- Design-Time and Run-Time Order Decomposition and Orchestration
- Orchestration Plans and Fulfillment Steps
- Enable In-Flight Amendments

---

## CPQ to ARM Migration Guide

### Why Customers Move from CPQ to ARM
| Driver | Description |
|---|---|
| Asset Lifecycle vs Contract-Based Sales | ARM supports advanced pricing, ramps, and asset-based revenue recognition |
| Better & More Flexible UI/UX | Intuitive UI, agent assistance, pre-built templates |
| Attribute-Based Product Catalog | Launch new products in days, not months |
| Easier Maintenance | Constraint-based config, unified catalog, reduced IT overhead |
| Omni-Channel Selling | Direct, e-commerce, partners — all from one platform |
| Core Platform & Composability | API-first, composable, scalable — future-proof |
| Agentforce | Agents automate quoting, renewals, billing inquiries |

### Migration Approach — 3 Steps

**Step 1: Design for Transition**
- Plan transformation of CPQ configuration data
- Refactor complex and/or custom features for new architecture
- Health of current CPQ implementation drives level of effort (complexity, customization, technical debt)
- Iteratively release features by cohort (product, channel, user group, geography)
- Deprecate legacy CPQ and Billing customizations and workarounds

**Step 2: Configure in Revenue Cloud**
- Convert configuration data: products, options, rules
- Develop optimized solutions for complex/custom requirements using new ARM features
- Document what must be rebuilt vs what accelerator tools can transfer

**Step 3: Migrate Transactional Data**
- Identify relevant transactional data: active subscriptions, in-process quotes
- Reshape Quotes and Orders to Revenue Cloud data model
- Generate Contracts and Assets for future renewals and amendments
- Migrate billing data to-be-processed
- Plan and execute full cutover from CPQ and Billing

### Data Migration Scope (ARM Migration Path — 4 Pillars)
| Pillar | Criteria | ROM Scale |
|---|---|---|
| One-to-One | Source and destination design are identical | 67 objects, 1,911 fields |
| Translation | Source objects map to one or more destination objects | 143 objects, 4,371 fields |
| Customized Translation | Source objects map to new RLM objects or custom objects | Customer-specific |
| Installed Packages | Packages in source org needed in new RLM org | Customer-specific |

### CPQ and ARM Coexistence (Same Org — Trust But Verify)

It is possible to run CPQ and ARM in the same org during migration, but it requires careful management:

| Object | CPQ | ARM | Recommendation |
|---|---|---|---|
| Opportunity | Shared | Shared | Use a screen flow to redirect users to the correct tool (CPQ or ARM) |
| Product2 | SKU-based | Attributes-based | Changes to Product2 metadata impact both — test carefully |
| Product Options | Separate (product options) | Separate (product components) | Mutually exclusive — no impact |
| Product Rules | Product Rules | Configuration Rules | Mutually exclusive — no impact |
| Pricing | Pricebook2 + Price Rules | Pricebook2 + Attribute-Based Pricing | Keep SEPARATE pricebooks for CPQ and ARM |
| Order | Standard Order | Standard Order | Same object — shared metadata changes require regression assessment |
| Contract | Standard Contract | Standard Contract | Shared object — requires functional impact assessment |
| Asset | Standard Asset | Standard Asset | Shared object — amendment usage in CPQ requires functional assessment |
| Subscriptions | SBQQ__Subscription__c | Standard Asset | Mutually exclusive — no impact |
| Approvals | SBAA__ managed package | Flow Orchestrations (core) | Separate data model — no impact |
| Doc Gen | CPQ-specific templates | OmniStudio DocGen | Mutually exclusive — separate templates |

---

## Agentforce Revenue Management (ARM) — AI Implementation Guide

### When to Implement Agentforce for Revenue

A use case is high-ROI for Agentforce when ALL of the following are true:
1. **Data is unified and accessible** — core decision data is connected, current, and reachable
2. **Process is repeatable at scale** — the same decision happens consistently across many instances
3. **Rules are enforceable, not advisory** — policies and thresholds can be embedded in the system
4. **Inputs are structured, outputs are defined** — clear inputs lead to predictable, auditable outcomes
5. **Outcomes are measurable** — speed, cost, quality, revenue, or risk reduction can be tracked
6. **Work happens in the system of record** — not in email threads, spreadsheets, or manual handoffs
7. **Exceptions have a clear escalation path** — edge cases route to a human without breaking the process
8. **The process has a transactable core** — there's a discrete system action the agent can reliably execute

### Getting Started with Agentforce Use Cases
1. Start with the biggest operational bottleneck (high-volume, repeatable, clear rules)
2. Validate the data foundation first — if data isn't usable, the use case won't scale
3. Shadow operators to capture real decision logic (what they check, how they decide, when they escalate)
4. Define escalation boundaries — agents handle routine; anything exceeding thresholds goes to human
5. Encode governance in the system — pricing thresholds, approval policies, contract rules must be enforced by the system, not just recommended by the agent
6. Instrument outcomes and feedback loops upfront
7. Build capability, not just experiments — develop teams that can rethink workflows with AI

### Revenue Agent Roadmap (as of FY27)

| Agent | Status | Capability |
|---|---|---|
| Quoting | GA Now | Create new business quotes, add lines, apply discounts |
| Consumption Mgmt & Advanced Quoting | GA Now | Track real-time consumption and overages, amendment quotes |
| Contract Search | GA Now | Search and retrieve contract details |
| Partner Quoting | GA Now | Quotes via partner channels |
| Invoice Explanation | GA Now | Detailed charge breakdowns, dispute support |
| Dispute Resolution | GA Now | Resolve billing disputes |
| Product Description Generation | GA Now | Auto-generate product descriptions |
| Renewals Agent | GA Now | Automate renewal quoting |
| Product Bundling & Recommendations | June '26 | Intelligent bundle suggestions |
| Ordering Agent | June '26 | Automated order placement |
| Collections Agent | June '26 | AR collections automation |
| Compliance Agent | October '26 | Contract compliance validation |

---

## Business Value KPIs (Benchmark Data)

| Metric | Improvement |
|---|---|
| Win Rates | +28% |
| Quoting Time Savings (Configuration & Approval) | -33% |
| Quoting Errors | -42% |
| Forecast Accuracy | +34% |
| Customer Satisfaction (throughout sales process) | +32% |
| Agility & Flexibility of IT Systems | +30% |
| Speed of Business Process Automation | +30% |
| Deal cycle time (enterprise go-live reference) | 4–6 days → 2–4 hours |
| Quote creation speed (Salesforce self-implementation) | 75% faster |
| Clicks to create a quote (Salesforce self-implementation) | 87% fewer |

---

## Billing Capability Comparison (Winter '26)

| Capability | Invoice Management (included in RCA) | Revenue Cloud Billing (add-on) |
|---|---|---|
| One-Time & Subscription Charges | ✓ | ✓ |
| Usage Invoicing & Milestone Charges | — | ✓ |
| Usage Rating & Consumption Calculation | — | ✓ |
| Tax | ✓ | ✓ |
| Invoicing, Credits | ✓ | ✓ |
| Invoice Grouping, Write-off | — | ✓ |
| Debit Memos | — | ✓ |
| Standalone Billing | — | ✓ |
| Invoice Doc Gen & Email Delivery | ✓ | ✓ |
| Accounting Periods & Closure | ✓ | ✓ |
| GL Accounts, Journal Entries (AR), FX Gain/Loss | — | ✓ |
| Payments, Refunds & Collections | — | ✓ |
| Analytics & Ops Console | ✓ | ✓ |

**Note:** Revenue Cloud Billing does NOT support revenue recognition. Recommend third-party tools (e.g., RightRev) for ASC 606 / IFRS 15 compliance.

---

## Key Objects & Features by Q2C Domain

### CPQ Domain
- **Key Objects:** Product, Price Book, Price Rule, Quote, Quote Line, Price Dimensions (usage), Lookup Tables
- **KPIs:** Quote-to-Close Time, Average Deal Size / Upsell Rate, Quote Accuracy (first-pass approval rate)

### Contracting & Order Management
- **Key Objects:** Contract, Order, Order Product, Asset, Order Summary, Fulfillment Schedules
- **KPIs:** Time to Contract Execution, Order Accuracy (Contract-to-Order match rate), Time from Contract to Fulfillment

### Billing & Invoicing
- **Key Objects:** Billing Contract, Billing Schedule, Usage Summary, Invoice, Invoice Line, Entitlement and Rating Configuration
- **KPIs:** Billing Accuracy, Days to Invoice, Dispute Rate

### Payment & Collections
- **KPIs:** Days Sales Outstanding (DSO), Payment Success Rate, Collections Efficiency

---

## Best Practices for Implementing Revenue Cloud Advanced

### Pre-Implementation (Before Any Build Starts)

**1. Understand Current Pain Points**
Do discovery with end users before designing anything. Identify where:
- Sales reps are working around the system to get quotes approved
- Finance teams are manually correcting invoices because billing logic doesn't align with contracts
- Processes are disconnected between quoting, contracting, and billing

These pain points define the goals to design around — without them, implementation becomes a re-platforming exercise rather than a transformation.

**2. Review and Clean the Product Catalog**
The product catalog is the core of quoting, pricing, billing, and renewals. Problems here propagate everywhere.
- Resolve duplicate SKUs before go-live — they will cause data integrity issues in quotes and invoices
- Eliminate inconsistent pricing across pricebooks
- Redesign legacy CPQ bundles using RCA's attribute-based model (do not lift-and-shift bundle structures)
- A unified, clean product catalog is the single biggest factor in long-term maintainability

**3. Align with the Finance Team Early**
Map the full deal cycle with Finance before designing anything:
- How products are configured → how discounts are applied → when a contract is signed → how invoices are triggered
- Identify manual steps currently required (they will need to be automated or explicitly scoped out)
- Identify where systems are disconnected or processes are disjointed
- Identify automation opportunities

**4. Map Your Revenue Flows End to End**
Trace the full path: product configuration → final net price → order → invoice → cash collection. Do this before Design starts. This mapping:
- Surfaces gaps between what the system can do and what the business needs
- Identifies integration touchpoints (ERP, billing, payment gateway)
- Defines the acceptance criteria for end-to-end testing

---

### Design Phase Best Practices

| Do | Avoid |
|---|---|
| Align one pricing procedure per pricing strategy | One giant pricing rule that handles everything |
| Separate base price, discounts, surcharges, and taxes into distinct steps | Embedding UI logic inside pricing logic |
| Use constraint rules only for business validation | Duplicating products for minor variations (use Attributes instead) |
| Document every pricing decision with a rationale | Undocumented pricing rules that only one person understands |

**Key principle:** Every pricing decision should be traceable to a documented business rule. If you can't explain why a pricing step exists, it shouldn't be in the pricing procedure.

---

### Build Phase Best Practices

| Do | Avoid |
|---|---|
| Build pricing rules incrementally — one rule at a time, validated before adding the next | Deploying all pricing rules at once and debugging after |
| Validate pricing early and often — test with real product/pricing data from the start | Waiting until UAT to discover pricing errors |
| Use feature branches and enforce code freeze during deployment windows | Deploying during active merges (causes metadata conflicts) |
| Deploy in strict sequence: Packages → RCA Metadata → Data | Deploying data before metadata is in place |
| Track all deployments using a single deployment plan template | Skipping pre/post deployment verification steps |

**Deployment sequence rule — always:**
```
1. Install/update managed packages (if any)
2. Deploy RCA metadata (objects, fields, pricing config, product catalog)
3. Deploy data (product records, pricebook entries, pricing rules)
4. Run post-deployment validation checklist
```

---

## RevenueManagementSettings — Complete Field Reference (Spring '26, API v66.0)

**Metadata type:** `RevenueManagementSettings`  
**File location:** `settings/revenuemanagement.settings`  
**Available from:** API version 60.0  
**Access via package.xml:** `<members>RevenueManagement</members><name>Settings</name>`

All fields are Boolean. Enable in sequence — some fields have prerequisite dependencies.

| Field | Description | Notes |
|---|---|---|
| `enableCoreCPQ` | Enable read/write access to Revenue Cloud features and objects | Required first — enables the platform |
| `enableRevUnifiedSetup` | Enable procedure plan for price calculation (pricing waterfall) | Required for `skipOrgSttPricing` |
| `enableTransactionProcessor` | Enable transaction types for quotes and orders | **Cannot be turned off after enabled** |
| `enableDeltaPricing` | Reprice only changed lines (delta) instead of full quote | v63.0+, improves performance on large quotes |
| `enableRampDeal` | Create ramp deals with segments (start/end dates, quantities, prices) | v62.0+ |
| `enableGroupRampPref` | Create group ramp segments across multiple products | v65.0+; requires `groupsEnabled` and `enableTransactionCloning` = true |
| `groupsEnabled` | Allow grouping of line items in quotes and orders | v62.0+ |
| `enableTransactionCloning` | Clone quotes/orders with line items and groups | v64.0+ |
| `enableAutoAddDerivedAsset` | Auto-add derived-pricing assets when contributing products are added | v62.0+ |
| `enableAsIsRenewals` | Enable as-is renewal capability for existing assets | v64.0+ |
| `enableAdvCreateOrdersFromQuote` | Allow generating multiple orders from a single quote | v65.0+ |
| `enableAdvancedDetailLinePricing` | Enable advanced pricing for quote and order detail line items | v65.0+ |
| `relaxUniqueCipValidation` | Enable fully customizable extensions to contract item prices | v64.0+ |
| `skipOrgSttPricing` | Skip default pricing procedure for quote/order sales transactions | Requires `enableRevUnifiedSetup` = true |
| `hidePriceRefreshNtfcn` | Hide stale-price notification on quotes/orders | v65.0+; caution — can mask pricing errors |

**Declarative sample (full enable):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<RevenueManagementSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableCoreCPQ>true</enableCoreCPQ>
  <enableRevUnifiedSetup>true</enableRevUnifiedSetup>
  <enableTransactionProcessor>true</enableTransactionProcessor>
  <enableDeltaPricing>true</enableDeltaPricing>
  <enableRampDeal>true</enableRampDeal>
  <groupsEnabled>true</groupsEnabled>
  <enableTransactionCloning>true</enableTransactionCloning>
  <enableAutoAddDerivedAsset>true</enableAutoAddDerivedAsset>
  <enableAsIsRenewals>true</enableAsIsRenewals>
  <enableAdvCreateOrdersFromQuote>true</enableAdvCreateOrdersFromQuote>
  <enableAdvancedDetailLinePricing>true</enableAdvancedDetailLinePricing>
  <relaxUniqueCipValidation>true</relaxUniqueCipValidation>
</RevenueManagementSettings>
```

**Critical warning:** `enableTransactionProcessor` cannot be disabled after it is turned on. Once you enable transaction types in an org, you must also create at least one `TransactionProcessingType` Tooling API record and set it as the default — you cannot have zero defaults after enabling.

---

## Revenue Cloud Deployment Guide (Pilot, Spring '26)

This section supersedes earlier deployment notes. Source: *Revenue Cloud Deployment Guide (Pilot), Salesforce Spring '26, last updated February 17, 2026.* This is the authoritative reference for org-to-org DevOps for Revenue Cloud. Intended audience: advanced Salesforce developers and architects familiar with established DevOps concepts.

### What the Guide Does NOT Cover
- Data migration from external/legacy systems to Salesforce
- There is no built-in Revenue Cloud-specific deployment tool — select Salesforce or third-party tools appropriate for your use case
- Custom objects, fields, Apex classes, LWCs — these are implementation-specific and must be handled per engagement

### Deployment Philosophy

Revenue Cloud has an **intricate dependency graph** between metadata and data records. The order in which you deploy matters — deploying data before its supporting metadata causes validation errors and data corruption.

**Full vs. Incremental:**
- **Full deployment** — entire metadata + data set migrated. Use for initial org setup, major releases, or first sandbox sync.
- **Incremental deployment** — delta only (changed metadata + associated data records). Use for ongoing DevOps. Requires version control to diff environments.

**Mixed-mode reality:** Deployment is NOT "all metadata first, then all data". There are complex two-way dependencies between metadata and data. For example, deploying a custom object with a lookup to Account requires Account records to exist first. Parent records must exist before child records. Circular dependencies (A depends on B, B depends on A) require: deploy A → deploy B → redeploy A.

### Complete RLM Component Inventory — Metadata vs Data Migration

Every RLM component categorised by deployment type. Use this as the checklist for scoping a deployment plan.

| Domain | Component | Deploy As |
|---|---|---|
| **Setup** | Context Definition | Metadata |
| **Setup** | Context Mapping | Metadata |
| **Setup** | Revenue Cloud Settings | Metadata |
| **PCM** | Product Selling Model | Data Migration |
| **PCM** | Product2 | Data Migration |
| **PCM** | Product Selling Model Option | Data Migration |
| **PCM** | Attribute Definition | Metadata |
| **PCM** | Attribute Picklist | Data Migration |
| **PCM** | Attribute Category | Data Migration |
| **PCM** | Product Classification | Data Migration |
| **Discovery** | Catalog | Data Migration |
| **Discovery** | Product Category | Data Migration |
| **Discovery** | Product Category Product | Data Migration |
| **Discovery** | Category Hierarchy | Data Migration |
| **Discovery** | Procedure Plan | Data Migration |
| **Discovery** | Procedure Plan Definition | Data Migration |
| **Discovery** | Search Filter Fields | Metadata |
| **Discovery** | Product Discovery Settings | Metadata |
| **Configurator** | Product Component Group | Data Migration |
| **Configurator** | Product Related Component | Data Migration |
| **Configurator** | Product Constraint Model (CML) | Metadata |
| **Configurator** | Constraint Model Rule | Metadata |
| **Configurator** | Attribute Set Product | Data Migration |
| **Configurator** | Configuration Flow | Metadata |
| **Configurator** | Configurator Action | Metadata |
| **Pricing** | Pricing Procedure | Metadata |
| **Pricing** | Pricing Recipe | Metadata |
| **Pricing** | Decision Table Definition | Metadata |
| **Pricing** | Decision Table Rows | Data Migration |
| **Pricing** | Price Adjustment Schedule | Data Migration |
| **Pricing** | Price Adjustment Tier | Data Migration |
| **Pricing** | Pricebook2 | Data Migration |
| **Pricing** | PricebookEntry | Data Migration |
| **Pricing** | Costbook | Data Migration |
| **Pricing** | CostbookEntry | Data Migration |
| **TLE** | TLE Action Buttons | Metadata |
| **TLE** | TLE Column Configuration | Metadata |
| **TLE** | Sales Transaction Context | Metadata |
| **Quoting** | Document Builder Template | Metadata |
| **Quoting** | Quote Validation Rule | Metadata |
| **ALM** | Assetization Rule | Metadata |
| **ALM** | Managed Asset Viewer | Metadata |
| **ALM** | Asset Action Script | Metadata |
| **LifeCycle** | Renewal Procedure | Metadata |
| **LifeCycle** | Amendment Flow | Metadata |
| **LifeCycle** | Co-termination Logic | Metadata/Data |
| **Fulfillment** | Fulfillment Plan | Data Migration |
| **Fulfillment** | Fulfillment Step | Data Migration |
| **Fulfillment** | Fulfillment Scenario | Data Migration |
| **DRO** | Orchestration Event | Metadata |
| **Usage** | Usage Rating Procedure | Metadata |
| **Usage** | Rate Card | Data Migration |
| **Usage** | Unit of Measure | Data Migration |

### Mandatory Deployment Sequence

```
1. Install / update managed packages (if any)
2. Deploy metadata — in dependency order:
   a. Product Spec Record Types (required before any Product2 records)
   b. AttributeBasedAdjRule (required before AttributeBasedAdjustment records)
   c. Decision Tables (required before Pricing Recipes)
   d. Context Definitions
   e. Expression Sets (must be INACTIVE — activate post-deploy)
   f. Pricing Recipes / Procedure Plans
3. Deploy data records — in parent-before-child order:
   a. Product2 / ProductCategory / ProductCatalog
   b. PriceBook2 / PriceBookEntry
   c. PricingPlan / PricingProcedure
   d. Transaction setup data
4. Activate components (Expression Sets, Decision Tables, Context Definitions)
5. Run post-deployment validation checklist
```

**Circular dependency handling:** When object A depends on B and B depends on A, deploy A first (with nullable reference to B), then deploy B, then redeploy A to populate the reference.

### Global Unique ID (GUID) Strategy

Salesforce internal record IDs are **not portable** across orgs — the same record has a different ID in Dev, QA, UAT, and Production. GUIDs solve this.

**Add a GUID field to every deployed object on day one — before any deployment work begins:**
1. Object Manager → object → Fields & Relationships → New → Text
2. Length: 255 (recommended)
3. Check: **Unique** and **External ID** — mandatory
4. Repeat for every RLM object in scope

**Alternative:** You can maintain your own mapping table of record IDs across orgs instead of a GUID field.

**Good GUID characteristics:** Immutable, globally unique, non-translatable, single key, programmatically generated.

**Avoid:** Record Name field (mutable), combination of mutable attributes (Name + Version + Sequence), concatenated keys, conditional keys (Pricebook + Product OR Pricebook + Product + ISO Code), manually entered values.

**Non-extensible objects** (protected, no GUID field allowed): A few Revenue Cloud objects are protected and cannot be extended with custom fields. Create an external reference table to store GUIDs for these. The deployment guide does not list them explicitly — identify them when they reject field creation in Object Manager.

**Populate GUIDs during AND after initial deployment:** You must populate the GUID field not only at the start of your deployment process but also for any new records generated along the way.

**Usage in deployment:** Always use GUID as the external ID field for upsert operations when migrating records between orgs. This prevents duplicates and ensures precise update targeting. In the event of a deployment failure, use the GUID to quickly locate the affected record in the target org.

### Object Deployment Sequence by Module (Appendix A)

Use these sequences for data migration planning. Deploy in the numbered order within each module. Objects earlier in the sequence must exist before later ones can be inserted (foreign key constraint).

#### Product Catalog Management (PCM) — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `ProductSpecificationType` | Metadata |
| 2 | `ProductSpecification` (Record Type) | Metadata |
| 3 | `AttributePicklist` | FK: User, User Group, Unit of Measure |
| 4 | `AttributePicklistValue` | FK: AttributePicklist (Master-Detail) |
| 5 | `UnitOfMeasureClass` | |
| 6 | `UnitOfMeasure` | FK: UnitOfMeasureClass |
| 7 | `AttributeDefinition` | FK: AttributePicklist, UnitOfMeasure |
| 8 | `AttributeCategory` | |
| 9 | `AttributeCategoryAttribute` | FK: AttributeCategory, AttributeDefinition |
| 10 | `ProductClassification` | |
| 11 | `ProductClassificationAttr` | FK: AttributeDefinition, ProductClassification |
| 12 | `TaxPolicy` | FK: User, TaxTreatment |
| 13 | `Product2` | FK: ProductClassification, BillingPolicy, TaxPolicy, UnitOfMeasure |
| 14 | `TaxEngine` | FK: NamedCredential, TaxEngineProvider |
| 15 | `TaxTreatment` | FK: LegalEntity, Product, TaxPolicy, TaxEngine |
| 16 | `ProductAttributeDefinition` | FK: AttributeDefinition, ProductClassificationAttr, UnitOfMeasure |
| 17 | `AttrPicklistExcludedValue` | |
| 20 | `ProductSellingModel` | |
| 21 | `ProductSellingModelOption` | FK: ProductSellingModel, Product |
| 22 | `ProductRampSegment` | |
| 23 | `ProductRelationshipType` | |
| 24 | `ProductComponentGroup` | |
| 25 | `ProductRelatedComponent` | FK: Product, ProductClassification, ProductSellingModel, ProductComponentGroup |
| 26 | `ProductComponentGrpOverride` | |
| 27 | `ProductRelComponentOverride` | |
| 28 | `ProductCatalog` | |
| 29 | `ProductCategory` | FK: Catalog (Master-Detail) |
| 30 | `ProductCategoryProduct` | FK: Product, Category (Master-Detail) |
| 31 | `ProductQualification` | |
| 32 | `ProductDisqualification` | |
| 33 | `ProductCategoryQualification` | |
| 34 | `ProductCategoryDisqual` | |
| 37–45 | Assessment objects | AssessmentQuestion → AssessmentQuestionVersion → Assessment → etc. |

**Note:** Internal objects (RuntimeCatalogIndexSetting, WebStoreSearchAttrSettings) are not accessible.

#### Salesforce Pricing — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `ProductSellingModel` | |
| 2 | `ProductSellingModelOption` | FK: ProductSellingModel (Master-Detail), Product2, ProrationPolicy |
| 3 | `Pricebook2` | |
| 4 | `CostBook` | |
| 5 | `PriceBookEntry` | FK: Pricebook2, Product2, ProductSellingModel |
| 6 | `CostBookEntry` | FK: CostBook (Master-Detail), Product |
| 7 | `PriceAdjustmentSchedule` | FK: Pricebook2, Contract |
| 8 | `PriceAdjustmentTier` | FK: PriceAdjustmentSchedule (Master-Detail), ProductSellingModel, Product2 |
| 9 | `PriceBookEntryDerivedPrice` | FK: Product2, PricebookEntry, Pricebook2, ProductSellingModel |
| 10 | `BundleBasedAdjustment` | FK: PriceAdjustmentSchedule (Master-Detail), Product2, ProductSellingModel |
| 11 | `AttributeBasedAdjRule` | |
| 12 | `AttributeAdjustmentCondition` | FK: AttributeBasedAdjRule (Master-Detail), AttributeDefinition, Product2 |
| 13 | `AttributeBasedAdjustment` | FK: PriceAdjustmentSchedule (Master-Detail), ProductSellingModel, AttributeBasedAdjRule, Product2 |
| 30 | `IndexRate` | (extended from Financial Services Cloud) |
| 35 | `PriceBookPriceGuidance` | Metadata |
| 40 | `PricingProcedureResolution` | Metadata; FK: ExpressionSet |
| 40 | `PricingProcedureOutputMap` | FK: PricingRecipeTableMapping, OutputFieldName |
| 50 | `PricingRecipe` | Metadata |
| 50 | `ProrationPolicy` | |
| 90 | `ProductPriceRange` | FK: Pricebook2 |

**Key Pricing gotchas (Appendix C):**
- You need active context definitions for pricing recipes
- A PricingRecipe is marked as default in an org; System Admin can access PricingRecipe — Pricing Admin cannot
- You cannot create or update fields of a PricingRecipe object
- Decision tables and pricing procedures must be activated
- Refresh decision tables after any new or modified price book entries
- You cannot delete a standard price book — set to Inactive instead
- Deleting a price adjustment schedule cascades all associated data deletion without warning
- Active field of a PriceBookEntry is NOT considered for resolution (Salesforce Pricing ignores PriceBook active flag too)

#### Product Configurator — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `ProductConfigurationRule` | FK: User |
| 1 | `ProductConfigurationFlow` | FK: UserFlowIdentifier |
| 1 | `ExpressionSetConstraintObj` | FK: ExpressionSetId, ReferenceObjectId (Polymorphic) |
| 2 | `ProductConfigFlowAssignment` | FK: User, ProductId, ProductClassificationId, ProductConfigurationFlow |

**Key Configurator gotchas (Appendix C):**
- `ProductConfigurationRule` has a BLOB field for rule content; BLOB references product IDs — cannot be migrated as-is — **must use the npm migration utility** for migration
- `ExpressionSetConstraintObj.ReferenceObjectId` is polymorphic — references object IDs across environments; resolve before migration
- Product catalog management data must be migrated before `ExpressionSetConstraintObj` records and before `ProductConfigurationRule` records
- When updating an Expression Set (Constraint Model), the target must be deactivated first

#### Transaction Management — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `AppUsageAssignment` | Metadata |
| 1 | `SalesTransactionType` | Metadata |
| 1 | `QuoteTemplateRichTextData` | Metadata |
| 1 | `TransactionProcessingType` | Metadata |

*Note: Object deployment details for Transaction Management are planned for a future version of the guide.*

#### Dynamic Revenue Orchestrator (DRO) — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `FulfillmentStepDefinitionGroup` | No FKs |
| 2 | `FulfillmentStepDefinition` | FK: Ruleset, ExpressionSet, FulfillmentStepDefinitionGroup |
| 3 | `FulfillmentStepDependencyDef` | FK: FulfillmentStepDefinition |
| 4 | `ProductFulfillmentScenario` | FK: FulfillmentStepDefinitionGroup, Ruleset, Product2, ProductClassification |
| 5 | `FulfillmentWorkspace` | No FKs |
| 6 | `FulfillmentWorkspaceItem` | FK: FulfillmentWorkspace, FulfillmentStepDefinitionGroup |
| 7 | `FulfillmentFalloutRule` | No FKs |
| 8 | `FulfillmentStepJeopardyRule` | No FKs |
| 9 | `FulfillmentTaskAssignmentRule` | FK: Ruleset, ExpressionSet |
| 1 | `ProductFulfillmentDecompRule` | FK: Ruleset, Product2, ProductClassification |
| 2 | `ValTfrmGrp` | No FKs |
| 3 | `ValTfrm` | FK: ValTfrmGrp, AttributePicklistValue |
| 4 | `ProductDecompEnrichmentRule` | FK: ProductFulfillmentDecompRule, ExpressionSet, AttributeDefinition |
| 5 | `ProdtDecompEnrchVarMap` | FK: ProductDecompEnrichmentRule, AttributeDefinition |

**DRO Special Fields (JSON, not portable as-is):**
- `FulfillmentStepDefinition.ExecuteOnConditionData` — JSON tied to internal RuleSet reference; **must use UPDATE operation** to set rule references in target, not INSERT
- `FulfillmentStepDefinition.ResumeOnConditionData` — same pattern
- `ProductFulfillmentScenario.ConditionData` — tied to ScenarioRule (RuleSet reference)
- `ProductFulfillmentDecompRule.ConditionData` — tied to ExecuteOnRule (RuleSet reference)
- `FulfillmentTaskAssignmentRule.ConditionData` — tied to Condition (RuleSet reference)

**DRO Migration Prerequisites:**
1. Products (`Product2`) must exist in target — `ProductFulfillmentDecompRule` has a hard FK to ProductId
2. `AttributeDefinition` records must exist — DRO condition data references attribute codes as natural keys
3. `AttributePicklistValue` records must exist for any attributes used in condition expressions
4. Attribute codes must be **consistent between source and target** — DRO stores JSON with attribute codes as natural keys; mismatches cause rule evaluation failures
5. When DRO is enabled in a new org, the system auto-creates `DRORuleLibrary` — the active rule library version must point to the same context definition as the DRO Admin settings
6. When moving to a new rule library version: deactivate old version → activate cloned version; **cloning from an older version loses rule sets from the latest version**

**DRO Post-Migration steps:**
- Refresh Decision Tables used by DRO Fallout Management
- Refresh Decision Tables used by DRO Jeopardy Management
- Activate technical products in the target org

#### Usage Management — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `UsageResourceBillingPolicy` | No FKs (Usage Aggregation Policy) |
| 2 | `UsageGrantRolloverPolicy` | No FKs |
| 3 | `UsageGrantRenewalPolicy` | No FKs |
| 4 | `UsageOveragePolicy` | No FKs |
| 5 | `UsageCommitmentPolicy` | No FKs |
| 6 | `RateCard` | No FKs |
| 7 | `UsageResource` | FK: UnitOfMeasure, UnitOfMeasureClass, Product2, UsageResourceBillingPolicy |
| 8 | `PriceBookRateCard` | FK: PriceBook2, RateCard |
| 9 | `RatingFrequencyPolicy` | FK: Product2, UsageResource |
| 10 | `ProductUsageResource` | FK: Product2, UsageResource |
| 11 | `RateCardEntry` | FK: RateCard, UnitOfMeasure, UnitOfMeasureClass, UsageResource, Product2, ProductSellingModel |
| 12 | `UsageResourcePolicy` | FK: UsageResource, UsageOveragePolicy, RatingFrequencyPolicy, UsageResourceBillingPolicy, UsageCommitmentPolicy |
| 13 | `ProductUsageGrant` | FK: ProductUsageResource, UnitOfMeasure, UnitOfMeasureClass, UsageGrantRolloverPolicy, UsageGrantRenewalPolicy, Product2, ProductSellingModel |
| 14 | `ProductUsageResourcePolicy` | FK: ProductUsageResource, UsageOveragePolicy, RatingFrequencyPolicy, UsageResourceBillingPolicy, UsageCommitmentPolicy, ProductSellingModel |
| 15 | `RateAdjustmentByTier` | FK: RateCardEntry |
| 16 | `RateAdjustmentByAttribute` | FK: RateCardEntry, AttributeBasedAdjRule |

**Usage Management Status Rules (Appendix C):**
- `ProductUsageResource` and `ProductUsageGrant`: Draft → Active → Inactive; can delete in Draft or Inactive, NOT Active; after activation, can extend EffectiveEndDate only
- `RateCardEntry`: Draft status only allows edits; cannot edit after activation; Draft → Active → Inactive / Inactive → Active

#### Billing — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `Profile` | |
| 2 | `User` | |
| 3 | `UserRole` | |
| 4 | `LegalEntity` | Contains polymorphic address field |
| 5 | `BillingPolicy` | Activate after BillingTreatment is activated |
| 6 | `BillingTreatment` | Activate after BillingTreatmentItem is activated |
| 7 | `BillingTreatmentItem` | Activate FIRST when activating BillingPolicy |
| 8 | `TaxEngineProvider` | FK: ApexAdapter |
| 9 | `TaxEngine` | FK: NamedCredential, TaxEngineProvider |
| 10 | `TaxPolicy` | Activate after TaxTreatment is activated |
| 11 | `TaxTreatment` | Activate FIRST when activating TaxPolicy |
| 12 | `PaymentTerm` | Activate after PaymentTermItem is activated |
| 13 | `PaymentTermItem` | Activate FIRST when activating PaymentTerm |
| 14 | `AccountingPeriod` | |
| 15 | `LegalEntityAccountingPeriod` | FK: LegalEntity, AccountingPeriod |
| 16 | `GeneralLedgerAccount` | FK: LegalEntity |
| 17 | `GeneralLedgerAcctAsgntRule` | FK: LegalEntity, GeneralLedgerAccount |
| 18 | `PaymentSchedulePolicy` | Activate after PaymentScheduleTreatment |
| 19 | `PaymentScheduleTreatment` | Activate FIRST when activating PaymentSchedulePolicy |
| 20 | `PaymentScheduleTreatmentDtl` | FK: PaymentScheduleTreatment, PymtSchdDistributionMethod |
| 21 | `PymtSchdDistributionMethod` | |
| 22 | `BillingMilestonePlan` | FK: BillingTreatment |
| 23 | `BillingMilestonePlanItem` | FK: BillingMilestonePlan |
| 24 | `GeneralLedgerJrnlEntryRule` | FK: GeneralLedgerAccount, GeneralLedgerAcctAsgntRule |

**Billing Activation Order:**
BillingTreatmentItem → BillingTreatment → BillingPolicy (activate in this exact sequence)
TaxTreatment → TaxPolicy
PaymentTermItem → PaymentTerm
PaymentScheduleTreatment → PaymentSchedulePolicy

**Billing additional prerequisite:** Data pipeline must be enabled BEFORE enabling Billing. Order to Billing Schedule Flow must be copied from template and activated.

#### Industries Common Components (Context Service, BRE, DPE)
| Object API | Notes |
|---|---|
| `ContextDefinition` | Sequence TBD (planned for future guide version) |
| `ContextTag` | |
| `ContextDefinitionSync` | |
| `ContextNodeAttrDictionary` | FK: ContextNodeMapping, ContextNode |
| `ExpressionSetDefinition` | No FKs |
| `ExpressionSetDefinitionVersion` | FK: ExpressionSetDefinition |
| `DecisionTable` | No FKs |
| `RuleLibrary` | Not supported by Metadata API |
| `RuleLibraryVersion` | FK: RuleLibraryDefVersion; Not supported by Metadata API |

**BRE/Expression Set deployment rules:**
- Initial deployment: Expression Sets and Decision Tables can be deployed in any state
- Subsequent updates: migrate a **new version** — do NOT update the existing active version
- Two expression set versions of the same parent CANNOT have the same rank (regardless of Draft/Active state)
- Activate sub-expressions after deployment
- Dynamic rules are stored in platform objects (not setup objects) — no platform support for deploying dynamic rules
- General dependency order: Standard/custom objects → Context Definitions, Decision Tables, Object Aliases → Sub Expression Sets → Parent Expression Set Version

**Context Service deployment rules:**
- Context tags and individual sObject mappings must be unique per definition
- Standard definitions are versioned; new changes must have a higher version than what exists in the target
- Deployments that modify existing custom mappings are supported
- **NOT supported:** Deploying context definitions from current to older release; modifying custom nodes/attributes for deactivated definitions; modifying standard nodes/attributes for activated definitions; activating/deactivating as part of a deployment package — must be a separate manual step; making a context mapping default/non-default within a deployment — must be a separate manual step

**Data Processing Engine (DPE) deployment rules:**
- Objects have Draft and Active states
- Must be created in Draft then activated via API
- Configuration cannot be changed after Active
- Set to Inactive to modify, then reactivate
- Dependencies: CRM Analytics or Data Cloud; Bulk API
- Both orgs must be on the same Salesforce release version

#### Salesforce Contracts (CLM) — Key Sequence
| Seq | Object API | Notes |
|---|---|---|
| 1 | `ClauseCatgConfiguration` | Metadata — migrate via metadata deployment tools (SFDX, Package Manager) |
| 2 | `DocumentClauseSet` | FK: ClauseCatgConfiguration; migrate via data tools; add external ID for upsert |
| 3 | `DocumentClause` | FK: DocumentClauseSet, ContentDocument |

**Clause migration rules (Appendix C):**
- All clauses INSERT in Draft status regardless of source status — run a follow-up upsert to restore Active/Archived status
- Status transitions: Draft → Active, Active → Draft (only if unused), Active → Archived; Archived is immutable
- Insert main clauses before alternate clauses
- Cannot modify DocumentClauseSet, Language, IsAlternateClause, or Version fields after creation (restricted fields)
- Clause status mapping: Archived → insert as Draft, then archive; Active → insert as Draft, then activate; In Approval → insert as Draft, must reinitiate approval from UI
- No automated clause migration utility exists — use Data Loader with OAuth authentication
- Create external ID field on DocumentClauseSet and DocumentClause for upsert tracking
- Must manually map ClauseCategoryConfiguration IDs between source and target orgs
- Template migration (Microsoft 365 templates) requires ALL referenced clauses to exist first — resolves by: ClauseSetName + ClauseName + ClauseVersion + ClauseLanguage

### Component State Management

Before deploying updates to existing components, check their state:

| Component Type | State Behavior |
|---|---|
| Expression Sets | Must be **INACTIVE** before deploying an update — deployment to an active version fails |
| Decision Tables | Deploy dependents before deploying the table |
| Context Definitions | Migrate dependent elements (field aliases, object aliases) before migrating the Context Definition |
| Pricing Recipes / Procedure Plans | Deploy Decision Tables first |
| Product Catalog items | Product Spec Record Types must exist before Product2 records |

**Deploy new components:** If component doesn't exist in target, deploy with all its versions.  
**Deploy updates:** Deactivate in target first → deploy update → reactivate.  
**Deploy with dependencies:** Migrate all dependency components independently before deploying the component that references them.

### Post-Deployment Validation Checklist

After every Revenue Cloud deployment:
1. Verify `RevenueManagementSettings` fields are correct for the target org
2. Confirm Expression Sets are active and correct version is active
3. Confirm Context Definitions are active
4. Verify Pricing Recipes / Procedure Plans reference correct Decision Tables
5. Spot-check a quote creation end-to-end (create quote → add line → price → order)
6. Confirm DRO orchestration templates are active and assigned to correct products
7. Check that feature toggle settings are appropriate for the target env (disable automation in lower envs if needed)

### TransactionProcessingType — Tooling API Object

Controls how each sales transaction (quote/order) is processed. Create via POST to `/services/data/v66.0/tooling/sobjects/TransactionProcessingType`.

Key fields:
- `RuleEngine`: `StandardConfigurator` | `AdvancedConfigurator`
- `PricingPreference`: `Force` (reprice all) | `System` (delta pricing) | `Skip` (no pricing)
- `TaxPreference`: `Skip` (skip tax calculation — useful in lower envs)
- `RatingPreference`: `Fetch` (save catalog rates for usage resources) — v66.0+, requires Rate Management enabled
- `SaveType`: `Standard` (only valid value currently; `Large` reserved for future use)

```json
{
  "SaveType": "Standard",
  "DeveloperName": "DefaultTransactionType",
  "MasterLabel": "Default Transaction Type",
  "RuleEngine": "StandardConfigurator",
  "PricingPreference": "System",
  "TaxPreference": "Skip"
}
```

---

## Complete Platform Events Catalog (Spring '26)

Platform events are the primary mechanism for integrating with RLM's async processes. Subscribe via Apex Triggers, Flows, or Pub/Sub API.

### Transaction Management Platform Events

| Event | Available From | Purpose | Subscription Channel |
|---|---|---|---|
| `CreateAssetOrderEvent` | v55.0 | Async result of `createOrUpdateAssetFromOrder` / `createOrUpdateAssetFromOrderItem` — success or error | `/event/CreateAssetOrderEvent` |
| `PlaceOrderCompletedEvent` | v63.0 | Order created/updated via Place Order API or Place Sales Transaction API | `/event/PlaceOrderCompletedEvent` |
| `QuoteSaveEvent` | v60.0 | Quote saved via Place Quote or Place Sales Transaction API — success or error | `/event/QuoteSaveEvent` |
| `QuoteToOrderCompletedEvent` | v56.0 | `createOrderFromQuote` REST request complete — order record or errors | `/event/QuoteToOrderCompletedEvent` |

### Dynamic Revenue Orchestrator Platform Events

| Event | Purpose |
|---|---|
| `FulfillmentSourceChangeEvent` | Notifies when a fulfillment source record changes — use to react to mid-fulfillment state changes |
| `SalesTrxnDecompositionEvent` | Notifies when a sales transaction has been decomposed into fulfillment units |

### Billing Platform Events

| Event | Available From | Purpose |
|---|---|---|
| `BillingScheduleCreatedEvent` | — | Billing schedule created from a billing transaction |
| `CreditInvoiceProcessedEvent` | — | Credit invoice processed |
| `CreditMemoProcessedEvent` | — | Credit memo processed |
| `InvoiceProcessedEvent` | — | Invoice posted (use to trigger downstream finance/ERP sync) |
| `NegInvcLineProcessedEvent` | — | Negative invoice line processed |
| `SequenceAssignedEvent` | — | Invoice/memo sequence number assigned |
| `VoidInvoiceProcessedEvent` | — | Invoice voided |

**Event-driven integration pattern for billing:**
```
InvoiceProcessedEvent subscriber (Apex Trigger or Flow)
  → Check Invoice.Status = 'Posted'
  → Callout to ERP via Named Credential (async, Queueable)
  → Update Invoice with ERP reference number
```

---

## Complete Invocable Actions Catalog (Spring '26)

All invocable actions callable from Flow, Apex, REST API, or Agentforce.

### Transaction Management — Quote & Order Actions

| Action | API Name | Purpose | Available From |
|---|---|---|---|
| Create Contract | `createContract` | Create a contract from a quote | — |
| Create or Update Asset From Order | `createOrUpdateAssetFromOrder` | Async asset creation from order | v55.0 |
| Create or Update Asset From Order Item | `createOrUpdateAssetFromOrderItem` | Asset creation from specific order item | — |
| Create Order From Quote | `createOrderFromQuote` | Place a single order from a quote | v56.0 |
| Create Orders From Quote | `createOrdersFromQuote` | Place multiple orders from a quote (requires `enableAdvCreateOrdersFromQuote`) | v65.0 |
| Get Renewable Assets Summary | `getRenewableAssetsSummary` | Returns summary of assets eligible for renewal | — |
| Initiate Amendment | `initiateAmendment` | Start amendment flow on active assets/contract | — |
| Initiate Cancellation | `initiateCancellation` | Cancel an active subscription/asset | — |
| Initiate Renewal | `initiateRenewal` | Trigger renewal flow for expiring assets | — |
| Initiate Rollback on Last Action | `initiateRollbackOnLastAction` | Roll back the last asset action | — |
| Initiate Transfer | `initiateTransfer` | Transfer assets to a different account | — |

### Advanced Approvals Actions

| Action | Purpose |
|---|---|
| Cancel Approval Submission | Cancel a submitted approval request |
| Get Previous Related Record Details | Get details of the previously approved version of a record |
| Override Approval Work Item | Admin override of a pending approval |
| Reassign Approval Work Item | Reassign a work item to a different approver |
| Recall Approval Submission | Recall a submitted approval (before any approver acts) |
| Review Approval Work Item | Approve or reject a work item |

### Dynamic Revenue Orchestrator Actions

| Action | Purpose |
|---|---|
| Decompose Sales Transaction | Break order into fulfillment units per product |
| Freeze Sales Transaction | Lock a transaction from further changes during fulfillment |
| Get Point Of No Return | Check if a transaction has passed the cancellation cutoff |
| Orchestrate Sales Transaction | Submit to DRO for full fulfillment orchestration |
| Orchestrate Transaction | Orchestrate a specific transaction context |
| Submit Order | Submit order to DRO (simpler than Orchestrate Sales Transaction) |
| Submit Sales Transaction | Full headless order submission through DRO |
| Unfreeze Sales Transaction | Release a frozen transaction |

### Salesforce Pricing Actions

| Action | Purpose |
|---|---|
| Run Salesforce Headless Pricing Action | Invoke pricing engine in headless/API context |
| Run Salesforce Pricing Action | Invoke pricing engine from Flow |

### Rate Management Actions

| Action | Purpose |
|---|---|
| Invoke Rating Service Action | Rate usage records against rate cards |

### Product Configurator Actions

| Action | Purpose |
|---|---|
| Run Config Rules Action | Execute constraint rules against a product configuration |

### Usage Management Actions

| Action | Purpose |
|---|---|
| Invoke Summary Creation Action | Create usage summaries for billing period |
| Process Consumption Overages Action | Handle overage charges for exceeded usage |
| Refresh Usage Entitlement Bucket Action | Refresh/reset usage entitlement buckets |
| Retrigger Entitlement Creation Process Action | Re-run entitlement creation for an order item |

### Billing Actions

| Action | Purpose |
|---|---|
| Apply Credit | Apply credit memo to an invoice |
| Apply Payments and Credits by Rules | Apply payments per configured rules |
| Create Billing Schedules From Billing Transaction | Generate billing schedules from a billing transaction |
| Create Standalone Billing Schedules | Create billing schedules without a billing transaction |
| Extend Invoice Due Date | Push out an invoice due date |
| Generate Account Statement | Create a statement PDF for an account |
| Generate Invoice Documents | Create invoice PDF documents |
| Issue Credit Memo | Issue a credit memo against an invoice |
| Post Draft Credit Memo | Move credit memo from Draft to Posted |
| Post Draft Invoice | Move invoice from Draft to Posted |
| Post Draft Invoice Batch Run | Batch post multiple draft invoices |
| Recover Billing Schedules | Recover billing schedules after a failure |
| Suspend Billing | Suspend billing for an account/asset |
| Unapply Credit | Reverse an applied credit |
| Unapply Payment | Reverse an applied payment |
| Update Bill To Contact | Update the billing contact on an invoice |
| Void Posted Credit Memo | Void a posted credit memo |
| Write Off Invoices | Write off uncollectible invoice amounts |

---

## Customer Staffing Requirements (for SOW scoping)

| Role | Design % | Implementation % |
|---|---|---|
| Project Sponsor | 15% | 5% |
| Product Owner | 100% | 50% |
| Project Manager | 100% | 100% |
| Technical Architect | 50% | 50–100% |
| Engineer / Developer | 25% | 100% |
| Quality Assurance | 10% | 100% |
| Domain SMEs | 50% | 25–50% |
| Data Architect | 50% | 100% |

---

## Revenue Cloud Billing (RCB) — Implementation Guide

### What RCB Is

Revenue Cloud Billing (RCB) is the platform-native billing engine replacing the Salesforce Billing Managed Package (BMP/blng__). It is available in API version 62.0 and later (Spring '24+). Key differentiators from BMP:
- **No managed package prefix** — all objects are standard Salesforce objects
- **Context Service drives billing schedule creation** — not direct DML
- **Full governor limit exposure** — no package-level governor limit isolation
- **Requires explicit permission sets** — Billing Admin, Billing Operations User, Billing Customer Service User, Tax Admin, Credit Memo Operations User, Payment Ops
- Available in Enterprise, Unlimited, and Developer Editions with Revenue Cloud Billing license

### RCB Pricing Model (Rate Card — Feb 2026)

| Usage Type | Unit | Multiplier |
|---|---|---|
| Invoicing | Per $1 USD of Total Invoice Amount (or portion thereof) | 0.02 |

**In plain terms:** 1 Billing Event is consumed for every $50 USD invoiced. A $5,000 invoice consumes 100 Billing Events.
- Total Invoice Amount = sum of all Invoice Subtotals posted during the Order Term (excluding taxes)
- Multi-currency: non-USD Subtotals are converted to USD using Salesforce's exchange rate provider
- **No rollover** — unused Billing Events expire at the Order End Date
- Billing Events are included with certain Salesforce Services (see Order Form Usage Details table)
- Additional Billing Events can be purchased as add-on SKUs

### Dual Billing Model (BMP → RCB Migration)

For customers migrating from the legacy Billing Managed Package to RCB:

**RPO Calculation:**
```
RPO (Remaining Performance Obligation Credit) = 
    Total BMP Cost × (Remaining Months / Contract Duration)
```

**Migration Model:**
- RPO credit is calculated at the BMP Cutoff Date
- Customer purchases RCB with included Billing Events (e.g., 1.5M events over 3 years = 500K/year)
- Additional RCB Events can be purchased as add-ons
- A **Dual Billing Period** exists: customer pays for both BMP (remaining RPO offset) and RCB platform license simultaneously during transition
- The swap must be **revenue neutral** — the RPO credit offsets the RCB platform license cost for the remaining BMP contract term
- Use the **Dual Billing Modeling Tool** (RCB_Implementation_Estimator.xlsx) to model the financial impact before presenting to the customer

**Key constraint:** BMP consumption is not measured during the Dual Billing Period — only the time remaining (months) is used for RPO calculation.

### Unified Setup Checklist (Billing Settings + Guided Setup)

**Step 1 — Enable Billing (Billing Settings):**
1. Setup → search "Billing Settings"
2. Activate the Billing toggle
3. Select/customize the Context Definition (defaults to OOB BillingContext)
4. Set defaults: Legal Entity, Billing Treatment, Tax Treatment, DPE definition (for closing Accounting Periods)
5. Configure Credit Memo behavior:
   - Toggle: "Convert Negative Invoice Lines to Credit Memos" (auto-generate CMs)
   - Credit Application Level: `Invoice` or `InvoiceLine`
   - Auto Apply Credit Balances toggle
6. Document Generation toggle + select/create PDF template
7. Email delivery settings (OOB email template or custom)

**Step 2 — Guided Setup (3 steps):**

**Step 2a — Billing Prerequisites:**
- Create Billing Users (SysAdmin → User Management)
- Assign permission sets: Billing Admin, Billing Operations User, Billing Customer Service User

**Step 2b — Create Billing Entities (in dependency order):**
1. Legal Entity (anchor for all treatments)
2. TaxEngine (if using external tax) → TaxTreatment → TaxPolicy (activate: TaxTreatment first)
3. BillingTreatmentItem → BillingTreatment → BillingPolicy (activate in this order)
4. PaymentTermItem → PaymentTerm (activate after PaymentTermItem created)
5. PaymentScheduleTreatment → PaymentSchedulePolicy (activate in this order)
6. GeneralLedgerAccounts → GL Account Assignment Rules
7. Accounting Periods (per LegalEntity)

**Step 2c — Invoice Templates:**
- Create/customise invoice PDF templates via Document Template Designer
- Assign to org default in Billing Settings or per-BillingAccount via `InvoiceDocumentTemplateId`

### Billing Configuration Hierarchy (Design-Time Objects)

```
LegalEntity
├── BillingPolicy
│   ├── BillingTreatment [LegalEntityId optional — for routing]
│   │   └── BillingTreatmentItem [BillingType: Advance/Arrears, Type: Percentage/FlatAmount/Remainder]
│   └── DefaultBillingTreatmentId
├── TaxPolicy [TreatmentSelection: Default/LegalEntity/Manual]
│   └── TaxTreatment [IsTaxable, TaxCode, TaxEngineId]
│       └── TaxTreatmentItem [per-product tax codes, API 66.0+]
├── PaymentTerm
│   └── PaymentTermItem [Period-Based or EOM]
├── PaymentSchedulePolicy
│   └── PaymentScheduleTreatment
└── GeneralLedgerAccountAssignmentRule
    └── GeneralLedgerAccount [Asset or Liability]
```

**Product Association:**
- BillingPolicy → assigned to Product2 (drives BillingSchedule creation on order activation)
- TaxPolicy → assigned to Product2 (drives tax calculation at OrderItem creation)

### Charge Type Implementation Patterns

**One-Time Charge:**
- No design-time config needed for billing (charge type is product-level)
- BSG created with `BillingTermUnit = One-Term`
- Invoice generated on order activation (or next scheduled run)
- Can combine with Milestone Billing treatment for phased one-time billing

**Recurring Charge:**
- BSG `BillingTermUnit` = `Monthly` | `Annual` | `Semi-Annual` (based on product)
- BTI `BillingType = Advance` or `Arrears` controls when first invoice is generated
  - **Advance:** invoice date falls on/before order product start date
  - **Arrears:** invoice date falls after order product start date
- ChargeType must be `Recurring` for amendment proration to work

**Usage Charge:**
- BSG reflects usage billing period from UsageResource configuration
- Invoice includes detailed usage breakdown (quantity consumed, overage charges)
- Usage-based billing schedules are processed by invoice batch runs alongside recurring charges
- Invoice Preview API does NOT calculate usage overages

**Milestone-Based (One-Time only):**
- BillingTreatment with `EnableMilestoneBilling = true`
- BillingMilestonePlan auto-created on order activation
- Items have status: `Waiting for Milestone Accomplishment` → `Ready for Invoicing`
- Date-based: auto-transition on configured date
- Event-based: manual "Milestone Accomplished" action
- Up to 20 items per plan

### Early Renewals

When a customer renews before the current subscription expires:
- Invoices are automatically generated reflecting the early renewal dates and adjusted pricing
- Handles billing for overlapping periods (remaining current subscription + new renewal period)
- Product must have ChargeType = Recurring and active BillingPolicy

### Evergreen Subscription Amendments

For add, amend, and cancel operations on evergreen subscriptions:
- Ensures correct billing amount based on amendment type and date
- Key requirement: all related Draft invoices must be Posted or Cancelled before amending

### Invoice Management Feature Set

| Feature | Capability |
|---|---|
| Scheduled Batch | `BillingBatchScheduler` with cron, respects `BillingBatchFilterCriteria` |
| On-Demand (Account) | "Generate Invoices" on Account (≤200 BSGs) |
| Invoice Preview | Next 2 billing periods, no storage, no usage overages |
| External Ingestion | Standalone invoices without BSG/BillingSchedule |
| Milestone Billing | Phased billing tied to dates or events |
| Usage-Based | Invoices with consumed quantity + overage breakdown |
| PDF Generation | Document Template Designer, per-account templates |
| Email Delivery | BillingAccount email template, attach PDF toggle |
| Suspend/Resume | Per-account or per-BSG; picks up from suspension point |
| Invoice Grouping | Consolidate invoices with custom grouping |

### GL and Financial Accounting Setup Pattern

```
1. Chart of Accounts: Create GeneralLedgerAccount records
   - Match your ERP's chart of accounts exactly
   - AccountingType: Asset (AR) or Liability (Revenue, Tax Payable)

2. GL Assignment Rules: For each TransactionType:
   - Invoice Line → Debit: AR Account, Credit: Revenue Account
   - Invoice Line Tax → Debit: AR Account, Credit: Tax Payable Account
   - Credit Memo Line → Debit: Revenue Account, Credit: AR Account
   - Credit Memo Tax → Debit: Tax Payable, Credit: AR Account
   - Payment → Debit: Cash Account, Credit: AR Account
   Assign LegalEntity to each rule for multi-entity orgs

3. Accounting Periods: Create LegalEntityAccountingPeriod records
   - One per LegalEntity per period (monthly recommended)
   - Close via DPE definition configured in Billing Settings

4. Post-Implementation: Dual Transaction Journals auto-created on Invoice Post
   - TransactionJournal record → Debit + Credit entries
   - Export to ERP via API or integration middleware
```

**ERP Integration decision:** Define the "Point of Handoff" in Discovery:
- **Lead-to-Invoice model:** Salesforce is the system of record; ERP receives posted invoices, payments, and journal entries
- **Lead-to-Order model:** ERP receives Orders from Salesforce and handles all billing/invoicing

### Key Permission Sets Required

| Permission Set | Who Needs It |
|---|---|
| Billing Admin | Setup/config of billing objects |
| Billing Operations User | Invoice generation, batch runs, "Bill Now" |
| Billing Customer Service User | Read access to billing for CS reps |
| Tax Admin | TaxEngine, TaxPolicy, TaxTreatment setup |
| Credit Memo Operations User | Apply/unapply credit memos; write-off invoices |
| Payment Ops | Apply/unapply payments |
| Billing Collections and Recovery Specialist | CollectionPlan, CollectionPlanItem access |
| Manage Errors Using Invoice Error Recovery API | recoverBillingSchedules action |

### Suspension and Resume Billing Pattern

Use cases: billing disputes, payment failures, account holds.

```
Design-Time: No configuration needed
Runtime:
  Suspend: POST /commerce/invoicing/actions/suspend-billing
    → BillingAccount.BillingSuspensionDate is set
    → BSGs status = Suspended
    → Suspended BSGs are skipped in all invoice batch runs
  
  Resume:  POST /commerce/invoicing/actions/resume-billing  
    → BillingAccount.BillingResumptionDate is set
    → BSGs return to Active
    → Billing resumes from where it left off (no billing cycle restart)
```

Note: `DoesSkipAutomaticPayments` on BillingAccount (API 65.0+) can be used to prevent automatic payment schedule creation while an account is in dispute.

### Testing Strategy for RCB

1. **Billing Schedule Creation:** Activate an Order → verify BSG and BillingSchedule created with correct BillingType and BillingTermUnit
2. **Invoice Generation:** Run Invoice Batch or Bill Now → verify Invoice created in Draft with correct InvoiceLines and amounts
3. **Tax Calculation:** Verify TaxEngine is Active → run Invoice → confirm InvoiceLineTax records populated
4. **Post Invoice:** Verify status transition Draft → Posted → TransactionJournal created with correct GL entries
5. **Credit Memo:** Create CM, apply to posted Invoice → verify Invoice balance reduced
6. **Amendment:** Amend an active subscription → verify proration calculation correct and new Invoice reflects delta
7. **Cancel-and-Rebill:** Full cycle test with maximum anticipated invoice line count
8. **PDF Generation:** Verify InvoiceDocument created and email sent to BillToContact
9. **Multi-entity:** Test with 2 LegalEntities — verify correct Treatment/Tax/GL routing

**Full Sandbox requirement:** Tax engine callouts and payment gateway callouts must be tested in Full Sandbox (not Developer Edition, not Partial Sandbox). Full Sandbox is non-negotiable for any RCB go-live.

### Discovery Questions Specific to RCB

Use these during Discovery phase when scoping billing requirements:

1. Are you migrating from Salesforce Billing Managed Package (BMP/blng__)? If yes, calculate RPO and model the Dual Billing Period.
2. How many legal entities does the organization have? Do billing/tax/accounting treatments differ per entity?
3. What billing charge types are required? (One-Time, Recurring, Usage-Based, Milestone)
4. What is the billing frequency? (Monthly, Annual, Semi-Annual, custom milestones?)
5. Do you bill in advance or arrears, or both depending on product?
6. Are you using an external tax engine? (Avalara, Vertex?) Which tax jurisdictions must be supported?
7. What is your GL structure? Do you need the Dual Transaction Journal integrated with an ERP?
8. What is the "Point of Handoff" — Lead-to-Invoice (Salesforce SoR) or Lead-to-Order (ERP handles billing)?
9. Do you require multi-currency invoicing? What is the corporate currency for reporting?
10. How should credit memos be handled? Auto-generate from negative lines, or manual API-driven workflows?
11. What payment terms are standard? Net 30, Net 60, EOM? Customer-specific terms?
12. Do you need payment schedule automation (split payments, retry rules)?
13. What invoice PDF customization is required? Per-legal-entity templates? Branded layouts?
14. What is your expected invoice volume per month? (determines BillingBatchScheduler sizing and Billing Events cost)
15. Are there suspension/resumption scenarios? (disputes, non-payment holds)
16. Are evergreen subscriptions in scope? Early renewals? Ramp contracts?
