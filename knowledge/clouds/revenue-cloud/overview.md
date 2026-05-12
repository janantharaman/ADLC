---
source: hand-authored + RCA Internal Playbook (May 2025)
cloud: Revenue Cloud
section: overview
---

# Revenue Cloud — Overview

## What It Is

Revenue Cloud (formerly Salesforce CPQ + Billing + B2B Commerce) is Salesforce's platform for managing the full revenue lifecycle: configure-price-quote (CPQ), contract management, subscription billing, order management, and revenue recognition. It sits on top of Sales Cloud and handles complex product configurations, multi-tiered pricing, and subscription amendments that the native Opportunity/Quote objects cannot handle.

## When to Use Revenue Cloud

Use Revenue Cloud when the engagement objective is one or more of:
- Complex product configuration with rules, constraints, and guided selling
- Multi-tier or volume-based pricing (bundles, discounts, price schedules)
- Subscription management: renewals, amendments, upgrades/downgrades, co-termination
- Contract lifecycle management with automated renewal quoting
- Recurring billing and invoice generation from contracts
- Revenue recognition (ASC 606 / IFRS 15 compliance)
- Multi-cloud B2B commerce + CPQ unified quoting

## When NOT to Use Revenue Cloud

| Need | Use Instead |
|---|---|
| Simple single-product quoting with fixed price | Native Salesforce Quote object |
| B2C e-commerce (consumer checkout) | B2C Commerce Cloud |
| Procurement / vendor-side purchasing | External procurement system |
| Pure subscription management without CPQ | Subscription Management add-on (lighter) |

## CPQ vs Native Quote

| Feature | Native Quote | Revenue Cloud (CPQ) |
|---|---|---|
| Product configuration rules | No | Yes |
| Bundle pricing | No | Yes |
| Volume/tiered pricing | No | Yes |
| Subscription amendments | No | Yes |
| Automated renewal quotes | No | Yes |
| Contract → Order generation | No | Yes |
| Revenue recognition | No | Yes (Billing) |

## Licensing

Revenue Cloud (CPQ) is a separate managed package — it is NOT included in Sales Cloud. It requires:
- Salesforce CPQ license (per user)
- CPQ managed package (`SBQQ__`) installed in the org
- Optional: Billing (`blng__`), Advanced Approvals, Revenue Intelligence

## Revenue Cloud on Core vs CPQ Managed Package

This is the most critical distinction to establish at the start of any engagement.

| Dimension | CPQ Managed Package (SBQQ) | Revenue Cloud on Core (RLM) |
|---|---|---|
| Architecture | Managed package — NOT built on core platform | Natively built on Salesforce Platform |
| Product Catalog | SKU-based — one SKU per variation | Attributes-based — fewer SKUs, reusable templates |
| Pricing Engine | Black box — fixed calculation sequence, hard to customise | Configurable pricing engine — full control over sequence |
| APIs | Limited (create quote but not freely modify) | API-first — full control over all operations |
| Transaction flow | Opportunity → Quote → Contract → Order required | Order can be created without Opportunity or Quote |
| UX | Limited customization | Composable, persona-based, drag-and-drop |
| Order Orchestration | Stops at order creation — no downstream visibility | Dynamic Revenue Orchestrator (DRO) built in |
| DevOps | Complex — managed package constraints | Any Salesforce-compatible DevOps tool works |
| Billing | Separate `blng__` package | Revenue Cloud Billing built in (Advanced tier) |
| Agentforce | Very limited — few APIs for agents to call | Full invocable actions — agents can automate end-to-end |
| Status | Feature-frozen — no new development | Active product — all new investment here |

**Rule:** New customers should always be scoped on Revenue Cloud on Core (RLM). Legacy CPQ (SBQQ) customers are candidates for migration — this is not a "lift and shift" but a refactoring migration.

---

## Pricing & Editions (as of May 2025)

### Revenue Cloud Growth — $150/user/month
- Product Catalog & Price Management
- Product Configurator (rules & constraint-based)
- Price & Quote
- Advanced Approvals
- Order Management
- Subscription & Asset Lifecycle
- Usage Selling
- Foundations ($0 — Agentforce agent templates, flex credits)
- DocBuilder (quotes only)
- 12,000 Revenue Events/org/year included

### Revenue Cloud Advanced — $200/user/month
Everything in Growth, plus:
- Contract Lifecycle Management (CLM)
- Advanced Doc Gen with Salesforce Doc Gen (quotes & contracts)
- Dynamic Revenue Orchestration (DRO)
- Invoice Management
- Revenue Management Intelligence dashboards
- Agentforce Agent Templates
- External User Support (headless, self-service, community, commerce, PRM)
- Billing Schedules

### Revenue Events (Consumption Pricing)
- 12,000 events/org/year included in base license
- Additional events: $10,000 per 50,000 events
- **Event costs by operation type (Internal):**
  - Pricing, Config, Quote, Order, Contracts, Doc Gen: 1 event each
  - DRO, Invoice Mgmt: 10 events each
- **Event costs by operation type (External/headless):**
  - Pricing, Config, Quote, Order, Contracts, Doc Gen: 1 event each
  - DRO, Invoice Mgmt: 10 events each
- A user license is NOT required to consume a Revenue Event — but minimum 5 active Revenue Cloud user licenses must exist in the org

### Minimum
- 5 user licenses required
- Requires Sales Cloud or Service Cloud as the base

---

## CPQ to Revenue Cloud Migration

**There is no "lift and shift."** The transition is a Refactoring Migration — both data transfer (via accelerator tools) and reimplementation of functionality in the new architecture.

### Transition Approaches

| Approach | Description | Best Fit |
|---|---|---|
| Refactoring Migration + Flash Cut Off | Maintain CPQ during migration, cut over at RLM go-live. Implement in new sandbox of current production org. | CPQ still meeting needs, clean cutover preferred |
| Phased Deployment | Deploy new RLM functionality (e.g., CLM) alongside CPQ. Faster time-to-value. | CPQ still meeting current needs, planning 18 months+ out |
| Start with New Product/Channel/BU | Deploy RLM to new geography, product line, or channel while keeping CPQ live. Phased roll-off. | Need to deploy new GTM motion quickly |
| New Salesforce Org | Start fresh. Option to deploy Salesforce and Revenue Cloud in phases. | Org consolidation needed; technical debt too costly to unwind |

### What Must Be Reimplemented (not migrated)
- Quote Calculator Plugins
- Page Security Plugins
- Custom Apex, Triggers, Workflows, Process Builders, Flows, OmniScripts
- Product catalog (architecture is fundamentally different — attributes vs SKUs)
- All customizations built on the managed package

### Accelerator Tools
- **Gearset** — DevOps platform with intimate CPQ/RLM data structure knowledge; readiness check, stepwise auto-migration, record-level traceability
- **Copado/partner tools** — For CPQ with complex bundle structures, Apex-level customizations, or self-migrating customers

---

## Key Sales Plays (for Architects — understand customer context)

| Play | Trigger Signal |
|---|---|
| Automate & Agentify Quote to Cash | Long quote build times, manual amendment process |
| Migrate from CPQ to RCA | Customer outgrowing CPQ scalability/APIs, wants new channels/pricing models |
| Scale & Simplify Q2C | Quote errors, approval delays, rogue discounting, missed renewals |
| Sell Through Multiple Channels | Direct + partner + self-service needed; B2B buyers want B2C experience |
| Launch New Products Quickly | SKU proliferation, slow product launch cycles |
| Create the Perfect Order | Post-sale fulfillment chaos, manual order handoff to back office |
| Collect Cash Faster | AR delays, incorrect invoices, billing disconnected from CRM |
| Buy AND Build | API-first customization needed, omni-channel UX, external integrations |
| Revive DND CPQ Deals | Previous CPQ evaluation failed — RLM solves those gaps |

---

## Key Buyer Personas

| Persona | What They Care About | Pain Points to Listen For |
|---|---|---|
| Head of Sales / CRO | Pipeline growth, forecast accuracy, sales productivity | Too much admin work, slow quote generation |
| Sales Ops / Rev Ops | Quoting efficiency, single system, catching renewals | Rogue discounting, rep errors, revenue leakage |
| Finance / CFO / Controller | Accurate financials, policy compliance, cash collection | Invoice errors, slow AR, manual reconciliation |
| Legal / General Counsel | Risk mitigation, standardized contracts, no maverick deals | Non-standard T&C, lengthy contract review |
| IT / CIO | Connected systems, governance, lower TCO | Multiple tools, high maintenance cost, integrations |

---

## Key Salesforce Releases That Affect Revenue Cloud

- **Spring '25**: Revenue Lifecycle Management (RLM) — next-gen Revenue Cloud without `SBQQ__` prefix, natively on platform (not managed package). Separate from legacy CPQ.
- **Winter '26**: AI Quote Assist (Agentforce for Revenue Cloud) — suggest product configurations from RFP text
- **Ongoing**: CPQ managed package and RLM are separate products. Legacy CPQ (SBQQ) is feature-frozen; new customers should evaluate RLM. For existing CPQ customers, migration path to RLM is not yet GA.

---

## RLM Capability Map

Revenue Lifecycle Management is organized into 7 functional pillars plus Selling and Platform layers.

### 1. Product Design
| Capability | Notes |
|---|---|
| Product Catalog | Central repository of all sellable products |
| Selling Models | One-time, subscription, usage-based, evergreen |
| Attributes | Drive configuration, pricing, and rules without separate SKUs |
| Categories & Hierarchies | Organize catalog for discovery and navigation |
| Classification | Tag products for filtering and entitlement |
| Configuration | Bundle rules, constraints, option groups |
| Product Rules | Validation, selection, filter, and constraint rules |

### 2. Price Management
| Capability | Notes |
|---|---|
| Pricing Constructs | Price lists, price schedules, price adjustments |
| Management & Execution | Pricing procedure execution, Context Definition |
| Price Rules | Attribute-based, volume-based, formula-derived rules |
| Optimization | Floor pricing, goal seek, margin analysis |

### 3. Configure, Price, Quote (CPQ)
| Capability | Notes |
|---|---|
| Product Discovery | Guided search, filtering, recommendations |
| External Configuration | Integration with external configurators (e.g., Logik.io, ThreeKit) |
| Rules Engine | Real-time constraint and validation evaluation |
| Quote Lifecycle | Quote status, versioning, approval workflow |
| E-commerce | Self-service quoting via storefront |
| Partner Quoting | Channel/partner-submitted quotes |
| Approvals | Multi-tier, parallel, delegated approvals |

### 4. Contract Lifecycle Management (CLM)
| Capability | Notes |
|---|---|
| Document Templates | Standard and dynamic contract templates |
| Document Generation | Automated output document generation |
| Clause Library | Reusable standard and negotiated clauses |
| Redlining | Customer negotiation and markup tracking |
| Checking & Version Control | Contract audit trail and change tracking |
| E-signature | DocuSign, Adobe Sign, Conga integration |
| Obligation Management | SLA tracking, contract obligation fulfilment |

### 5. Order Management
| Capability | Notes |
|---|---|
| OmniChannel | Unified order intake across channels |
| Orchestration | Dynamic Revenue Orchestrator (DRO) — multi-step order fulfilment |
| Decomposition | Breaking orders into fulfilment units |
| Fulfillment | Downstream provisioning handoff |
| Provisioning | Service activation and entitlement |
| Asset Management | Subscriber asset lifecycle, amendments, renewals |

### 6. Billing & Collections
| Capability | Notes |
|---|---|
| Billing Management | Invoice generation, billing schedules |
| Tax | Avalara/Vertex integration |
| Invoicing | Invoice delivery, payment terms |
| Payments | Salesforce Payments, Chargent, Stripe integration |
| Collections | Dunning, payment retry, collections workflow |
| Usage | Usage ingestion and rating for metered billing |
| Revenue Recognition | ASC 606 / IFRS 15 recognition schedules |
| Ledger Management | GL posting, journal entries to ERP |

### 7. Revenue Lifecycle Intelligence
| Capability | Notes |
|---|---|
| Data Analytics | Revenue pipeline and booking analytics |
| Revenue Forecasting | ARR/MRR forecasting |
| Performance Metrics | KPIs across the revenue lifecycle |
| Predictive Analytics | AI-driven churn, renewal, and upsell predictions |

---

### Selling Layer (Foundation — requires Sales Cloud)
- Territory Management, Account Management, Lead Management
- Contact Management, Opportunity Management

### Platform Layer (Cross-cutting)
- Security Management, OAuth, Master Data Management
- Product Integration, Pricing Integration, Order Integration, Commerce Integration
- Globalization, Currency Management, Mobile, Reporting
