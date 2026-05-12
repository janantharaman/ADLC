---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); CME Managed Package Dev Guide (2025.12.04); Communications Cloud Integration Patterns and Practices (2025.12.10); B2B Telecommunications supplementary documents ingested 2026-05-10; B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: overview
last-updated: 2026-05-10
---

# Salesforce Communications Cloud — Overview

## What Is Communications Cloud?

Salesforce Communications Cloud (formerly Vlocity Communications Cloud) is a purpose-built industry cloud for communications service providers (CSPs) — including fixed-line, mobile, cable/MSO, and wholesale operators. It is built natively on Salesforce CRM and packages the Salesforce Platform with telecommunications-specific data models, business processes, APIs, and AI capabilities.

The product is positioned as the "#1 AI CRM for telecom" and includes Agentforce (the Salesforce AI Agent framework), industry-specific applications, a TM Forum-aligned data model, and pre-built integrations to BSS/OSS systems. It is the successor to Vlocity Communications Cloud after Salesforce acquired Vlocity in 2020.

### Product family naming:
- **Salesforce Communications Cloud** — the current marketed product name
- **Telecommunications Cloud** — an alternate/legacy designation for the same offering
- **Vlocity Communications Cloud** — legacy name (pre-acquisition); namespace `vlocity_cmt` persists in the codebase
- **Agentforce Communications** — the AI-enhanced product positioning as of Spring '26

## How It Relates to Other Salesforce Products

| Product | Relationship |
|---------|--------------|
| Industries CPQ (formerly Vlocity CPQ) | Core quoting/product catalog engine embedded in Communications Cloud; uses `vlocity_cmt` namespace |
| Order Management (Order Orchestration) | Order decomposition, orchestration, and fulfillment engine built into Communications Cloud |
| Revenue Cloud (Subscription Management) | Optional add-on for subscription lifecycle management and recurring billing |
| OmniStudio | Low-code tool layer (OmniScripts, DataRaptors, Integration Procedures, FlexCards) used to build guided flows and integrations |
| MuleSoft | Used for pre-built outbound integrations to BSS/OSS (TMF641, TMF645, TMF673–TMF675) |
| Salesforce Industries (common platform) | Shared platform components across all Industry Clouds |
| TM Forum Open APIs | 12 TM Forum APIs exposed as inbound REST APIs on Communications Cloud |

## Key Modules

### 1. Product Catalog Management (TMF620)
- Define products, bundles, offers, and pricing
- Mapped to `Product2`, `vlocity_cmt__Catalog__c`, `vlocity_cmt__CatalogProductRelationship__c`, `vlocity_cmt__PriceListEntry__c`
- Hierarchical catalog: Catalog → Category → Product Specification → Product Offering → Product Offering Price

### 2. Configure, Price, Quote (Industries CPQ)
- Guided selling and quoting engine
- Mapped to `Quote`, `QuoteLineItem`, `vlocity_cmt__QuoteLineItemRelationship__c`
- Supports attribute-based products, bundles, eligibility rules, and pricing adjustments
- Produces orders from quotes

### 3. Order Capture & Management
- Converts quotes/orders into actionable order records
- Mapped to `Order`, `OrderItem`, `vlocity_cmt__OrderItemRelationship__c`
- Order decomposition splits customer orders into sub-orders for provisioning
- Supported via TMF622 API

### 4. Customer Management (TMF629)
- Account, Contact, and Contract management
- Mapped to `Account`, `Contact`, `Contract`
- Supports B2C and B2B (enterprise) segments

### 5. Product Inventory Management (TMF637)
- Tracks installed/active products per account
- Mapped to `Asset` object with `vlocity_cmt` extensions

### 6. Subscription Management
- Manages subscription lifecycle: activate, modify, suspend, cancel
- Overlaps with Revenue Cloud Subscription Management when deployed together

### 7. Trouble Ticket Management (TMF621)
- Case-based issue and complaint management
- Mapped to `Case` with `vlocity_cmt__severity__c` extension

### 8. Agreement Management (TMF651)
- Contract and agreement lifecycle
- Mapped to `Contract`, `DocumentTemplate`

### 9. Promotion Management (TMF671)
- Promotions, discounts, and campaign rules
- Mapped to `vlocity_cmt__Promotion__c`

### 10. Product Offering Qualification (TMF679)
- Checks product eligibility at a given address or for a given customer
- Mapped to `Product2`, `Account`, `ProductCategory`

### 11. Enterprise Sales Management (ESM)
- Large-transaction selling for B2B/enterprise customers
- Thousands of line items across multiple product lines, locations, and subscribers
- Guided workflows for browsing, configuring, and viewing quote summaries
- Reference product models: Internet, mobile, VPN
- Bulk upload features for locations and subscribers
- Discount application across all line items in an enterprise quote
- Responsive UI based on SDK + Lightning Web Components
- Uses Industries CPQ internally for order processing
- Templates for proposals, contracts, and order management

### 12. Multiplay Subscription Management (MSM)
- Streamlines sales processes for communications service providers
- Manages subscriptions, personalizes offerings, provides customer support
- Designed for CSPs selling bundled services (internet, TV, voice)

### 13. Agentforce for Cart Operations
- AI-driven cart operations available since Spring '26
- Supports CPQ invocable actions via Agentforce Actions
- Can invoke CPQ flows: Get Offers for Asset, Replace Offer in Cart, Delete/Disconnect Cart Item
- Requires Agentforce license in addition to Communications Cloud
- Configure via Setup → Agentforce Studio; map CPQ invocable actions as Agentforce Actions

### 14. Digital Commerce (B2C Self-Service Ordering)
- Cloud-based solution for high-volume browsing and configuration of product offers on self-service channels
- Supports anonymous and authenticated user carts
- Enables advanced order-capture, guided selling, and elastic scaling for peak traffic (e.g., iPhone launch events)
- **Standard Digital Commerce APIs** — newer, Java-layer implementation that bypasses Apex governor limits; activated separately from Standard Cart-Based APIs
  - Enable via: Vlocity CMT Administration → Enable Features → Standard Digital Commerce APIs → Enable
  - Requires compile data generated via: Cache Catalog Product Definitions job (different from CPQ EPC compile)
  - No pseudo-orders, pseudo-accounts, or JSONResult in Standard DC APIs — must refactor any custom code that uses these
  - New interface implementation names required: `CpqAppHandler`, `CpqContextRule`, `CpqOfferEligibility`, `CpqResponse`, `CpqValidation`, `CpqTimePolicy`, `CpqTightestMatch`, `CpqPricingVariableCalc`, `CpqPricingEligibility`, `CpqPricing`
  - Cart creation only via `cartContextKey` (not JSONResult); async bulk create cart not supported
- **Classic Digital Commerce APIs** — legacy implementation; still in use in many orgs

### 15. Connected Assets (IoT / Telematics)
- Available in: Communications Cloud, Automotive Cloud, Energy and Utilities Cloud, Media Cloud
- Enables real-time actions on connected assets based on IoT/telematics event data
- **Actionable Event Orchestration**: Define orchestration processes triggered by asset events (sensor faults, temperature alerts, battery failures, usage thresholds)
  - Ingest events via: `Actionable Orchestration Source Event` platform event OR `Orchestration Inbound Events` business API (POST)
  - Decision table (`Filter and Match Actionable Event Orchestrations`) routes events to correct orchestration by type, subtype, category
  - Execution via Expression Sets (simple record creation/update) or Salesforce Flows (complex workflows)
  - Actions supported: create/update cases, work orders, asset milestones, record alerts
- **Data Cloud Experiences for Connected Assets**: Harmonize and analyze asset data at scale using Data Cloud; includes Asset Management Starter data kit
- **Proactive Asset Service**: Intelligent dashboards for asset health monitoring; health scores based on usage, age, maintenance history
- **Telemetry Definition and Action Management**: Manage sensor/actuator data; configure telemetry action definitions; automate service process generation
- Integration: Connect telematics providers to Salesforce via MuleSoft or any middleware; usage-based licensing (`Actionable Asset Event Orchestration Limit`)
- Permission sets required: `Actionable Event Orchestration Designer` + `Context Service Admin` + `Rule Engine Designer` (for designers); runtime users need read access on Cases, Asset Milestones, Record Alerts

### 16. Asset Service Lifecycle Management (ASLM)
- Available in: Communications Cloud, Energy and Utilities Cloud, Manufacturing Cloud, Media Cloud, Automotive Cloud, Service Cloud (with Field Service)
- Manages entire lifecycle of asset service operations and field service
- Key features:
  - **Advanced Exchange**: Streamlined return and replacement requests for defective products/parts; field techs initiate in one flow
  - **Asset Coverage View**: Quick access to customer entitlements from asset record
  - **Asset Interactive Hierarchy**: Visualize complex asset hierarchies (CPE, STB, SIM, network equipment)
  - **Book Service Appointment**: View, book, reschedule, cancel appointments from work order or other objects
  - **Depot Repair**: Manage repair process for returned items; auto-populate work order from return order line
  - **Inventory Batch Management**: Track serialized and non-serialized inventory using batch details
  - **Inventory Search and Transfer**: Criteria-Based Search for inventory; transfer between locations
  - **Inventory Count**: Cycle counts and ad hoc counts via Field Service mobile app
  - **Inventory Replenishment**: Policy-driven automated replenishment when stock falls below thresholds
  - **Product Service Campaign**: Organize product recalls, upgrades, service campaigns across large asset populations; segment and assign lists to agents
  - **Work Order Estimation**: Pre-service cost/effort estimation for repair, installation, and infrastructure expansion

### 17. TM Forum Industry APIs (Inbound)
- 12 TM Forum-compliant REST APIs exposed on Communications Cloud
- Direct Access via Connect/Apex REST endpoints (recommended from Winter '27)
- MuleSoft Gateway option (deprecated from Winter '27)

### 18. MuleSoft Direct Integrations (Outbound)
- 7 outbound integration templates: TMF620, TMF622, TMF641, TMF645, TMF673, TMF674, TMF675
- Pre-built on MuleSoft Exchange, deployed to customer MuleSoft instances

## Industry Verticals Covered

| Vertical | Notes |
|----------|-------|
| Mobile (MNO) | Core use case: consumer and enterprise mobile products |
| Fixed/Fiber (ILEC/CLEC) | Fiber subscriber experiences, address qualification |
| Cable/MSO | Bundled services (internet, TV, voice) |
| Wholesale | Inter-carrier wholesale transactions using standard APIs |
| Satellite | Supported on common platform |
| Utilities (overlap) | Shares platform with Energy & Utilities Cloud |
| Media | Shares platform with Media Cloud |

## High-Level Architecture and Data Flow

```
Customer Interaction Layer (Sales Rep / Customer Portal / Agent)
        |
        v
[Guided Selling / OmniScript / CPQ]
        |
        v
[Quote] --> [QuoteLineItem] --> [vlocity_cmt__QuoteLineItemRelationship__c]
        |
        v (Place Order)
[Order] --> [OrderItem] --> [vlocity_cmt__OrderItemRelationship__c]
        |
        v (Order Decomposition)
[Sub-Orders / Fulfillment Order Items]
        |
        v (Order Orchestration)
[Provisioning Tasks / Integration Procedures / BSS/OSS callouts]
        |
        v (Completion)
[Asset] (vlocity_cmt extensions) --> Product Inventory (TMF637)
        |
        v
[Subscription / Billing Account / Invoice]

Inbound TM Forum APIs (BSS/OSS → Salesforce):
  TMF620 (Catalog), TMF621 (Tickets), TMF622 (Orders),
  TMF629 (Customer), TMF637 (Inventory), TMF648 (Quote),
  TMF651 (Agreement), TMF667 (Documents), TMF671 (Promotion),
  TMF679 (Qualification)

Outbound MuleSoft Integrations (Salesforce → OSS/BSS):
  TMF620, TMF622, TMF641, TMF645, TMF673, TMF674, TMF675
```

## Key Personas

### Salesforce Internal / Delivery Personas

| Persona | Role | Primary Objects/Tools Used |
|---------|------|---------------------------|
| Sales Representative | Sell telecom products to B2C/B2B customers | CPQ OmniScript, Quote, QuoteLineItem, Product2 |
| Order Manager | Review, approve, and track orders | Order, OrderItem, Order Orchestration UI |
| Network Provisioner | Receive and action provisioning tasks from decomposed orders | Sub-orders, Integration Procedures, BSS/OSS APIs |
| Billing Administrator | Manage billing accounts, invoices, pricing | BillingAccount, PriceList, Promotion |
| Customer Service Agent | Resolve issues, manage tickets, handle changes | Case (TMF621), Asset (TMF637), guided change flows |
| CPQ Administrator | Configure product catalog, pricing rules, eligibility | vlocity_cmt__Catalog__c, vlocity_cmt__PriceListEntry__c |
| OmniStudio Developer | Build OmniScripts, DataRaptors, Integration Procedures | OmniStudio tooling |
| Integration Architect | Design BSS/OSS integration patterns | TM Forum APIs, MuleSoft, Integration Procedures |

### B2C Communications Industry Buyer Personas (Executive / Customer-Side)

These are the executive and business stakeholders at CSP customers. Understanding their goals and challenges is critical for discovery, pre-sales, and solution design.

| Persona | Primary Goals | Key Business Challenges |
|---------|---------------|------------------------|
| **Chief Technology Officer (CTO) / Chief Information Officer (CIO)** | Deploy and evolve technology to enable corporate goals; simplify IT; decommission legacy | Complex IT architecture slows time-to-market; costly patchwork systems; vendor lock-in (e.g., Amdocs managed service agreements); cultural resistance to agile ways of working |
| **Chief Product Officer (CPO)** | Rapidly bring new products and offers to market; eliminate duplicate catalogs across digital, retail, contact center, partner channels | Legacy IT stacks; siloed systems; long product/promotion introduction cycles; balancing governance with agility |
| **Chief Digital Officer (CDO)** | Deliver consistent omnichannel customer experience; drive consumer digital adoption; launch new brands fast | Difficult to achieve cross-channel consistency; product complexity slows digital commerce; siloed systems cause catalog duplication and data fragmentation |
| **Chief Marketing Officer (CMO)** | Measure ROI across cross-channel campaigns; personalize experience from awareness to advocacy; increase lead conversion | Lack of complete customer journey insight; disjointed online and offline experiences; inability to connect demand generation to revenue |
| **Chief Revenue Officer (CRO) / Head of Sales** | Meet revenue targets; increase order accuracy; accelerate quote-to-order; reduce agent administrative burden | Long manual quote-to-order processes; fragmented selling tools; poor real-time customer and pipeline visibility |
| **Chief Customer Experience Officer (CCEO) / Head of Customer Service** | Reduce call handling time; improve NPS; deliver omnichannel consistency; improve agent productivity | Agents lack 360° customer view and must use 5–10 systems; low self-service adoption; complex products require constant agent training |
| **Head of Field Operations / Service Delivery** | Achieve first-visit job completion; streamline order fulfillment; ensure on-time delivery | Incomplete work order data; no single source of truth; multiple disparate systems; balancing security with agility |

### B2C vs B2B Segment Differences

| Dimension | B2C (Consumer) | B2B (Enterprise) |
|-----------|---------------|-----------------|
| Primary sales channel | Digital self-service portal, retail stores, contact center | Account managers, B2B portal, inside sales, partners |
| Quote complexity | Simple (single consumer, few products) | Complex (thousands of line items, multi-site, ESM) |
| Order volume | Very high (peak events like iPhone launch) | Lower volume, higher value per order |
| Product catalog | Consumer mobility, broadband, TV bundles | Managed WAN, ICT bundles, large enterprise networking |
| Contract management | Minimal (standard consumer terms) | MSA, bespoke agreements, DocuSign workflows |
| Self-service expectation | High — consumers expect full digital self-service | Moderate — portals exist but agent-assisted preferred |
| Personalization | AI recommendations, next best offer at household level | Account-based selling, negotiated pricing |
| Key platform module | Digital Commerce, Multiplay Subscription Management | Enterprise Sales Management (ESM) |

### B2C-Specific Customer Interaction Channels

Channels active in B2C telecom implementations:

| Channel | Description |
|---------|-------------|
| Consumer web portal / digital storefront | Self-service browsing, configuring, and ordering products (powered by Digital Commerce APIs) |
| Retail stores | In-store assisted selling; store locator via `BusinessSite__c` / `BusinessSiteOffering__c` |
| Contact center (B2C CSR) | Agent-assisted service using 360° view: services, billing, orders, cases |
| Mobile application | Self-service order and service management on mobile |
| Third-party dealers / agents | Authorized dealer channels; partner portal ordering |
| Door-to-door sales | Field sales capture; typically assisted CPQ or mobile ordering |

## B2C vs B2B Architecture Differences

### B2C Order Flow (Digital Self-Service)

```
Consumer visits Digital Commerce channel (web/mobile)
        |
        v
[Anonymous or Authenticated Cart] — Digital Commerce APIs (Standard or Classic)
        |
        v
[Product Browse / Service Qualification] — Address eligibility check
        |
        v
[Cart Configuration] — Bundle selection, attributes, promotions applied
        |
        v
[Checkout / Payment] — Payment integration (credit card, billing account)
        |
        v
[Order Created] — OrderItem records; Asset-Based Ordering for existing subscribers
        |
        v
[Order Decomposition + Fulfillment] — Same orchestration as B2B but simpler topology
        |
        v
[Asset provisioned] → Confirmation to consumer portal/email/SMS
```

Key B2C differences vs B2B:
- No Opportunity required (consumer orders can bypass Opportunity creation)
- Anonymous user carts supported (no account required for browsing)
- Digital Commerce APIs (not just TMF648) are the primary order capture channel
- Promotions and personalized offers driven by marketing campaigns and household data
- Household and Party model used for family plan management (`Household__c`, `PartyRelationship__c`)
- Abandoned cart tracking via `Cart__c` and `CartItem__c` objects
- Subscription object (`Subscription__c`) used for individual subscriptions within a household
- Address-based service qualification critical (fiber/fixed customers)

### B2C-Specific Data Objects (Key Additions)

| Object | B2C Use Case |
|--------|-------------|
| `Household__c` | Family plans; grouping consumer contacts and assets by household |
| `PartyRelationship__c` | Relationships between consumers (e.g., head of household, family member) |
| `Subscription__c` | Individual subscription (one user at a time, governed by payment plan) |
| `Cart__c` | Abandoned shopping cart tracked for lead/contact follow-up |
| `CartItem__c` | Line item in an abandoned cart |
| `BusinessSite__c` | Retail store locations; used for store locator on consumer portal |
| `BusinessSiteOffering__c` | Services available at each retail store |
| `AccountOffer__c` | Product/promotion offered to a consumer account (tracks acceptance) |
| `Statement__c` | Historical billing statement imported from billing system |
| `StatementLineItem__c` | Individual bill line items imported from billing system |
| `SecurityDeposit__c` | Consumer security deposit tracking |

## Salesforce TM Forum Alignment Status

Salesforce Communications Cloud has been a TM Forum member since 2010 and holds the following certifications as of 2025:

| Certification | Product Certified | Year |
|---|---|---|
| SID Information Framework v22.0 | Enterprise Product Catalog (EPC) | 2022 |
| eTOM Process Framework v22.0 | Industries CPQ, Industries OM | 2023 |
| eTOM Process Framework v22.0 | Industries OM | 2023 |
| Ready for ODA (Open Digital Architecture) | Communications Cloud | 2024 |
| TM Forum Open API — GOLD Badge | Communications Cloud | 2025 |

### TM Forum Open API Delivery vs Roadmap (as of Spring '26)

**Delivered Inbound APIs:** TMF620, TMF621 (v4 + v5), TMF622 (v4 + v5), TMF629, TMF637, TMF648, TMF651, TMF667, TMF671, TMF679

**Delivered Outbound APIs:** TMF620, TMF622, TMF641, TMF645, TMF673, TMF674, TMF675

**Delivered Outbound Notifications:** TMF622, TMF651, TMF637, TMF629, TMF632

**In Progress (Spring '26):** TMF629 enhancements with Extensibility Framework; TMF699 (Inbound); TMF646 (Inbound); TMF666 (Inbound); TMF632 (Inbound)

**Planned (future):** TMF678 (Customer Bill — Outbound), TMF640 (Service Activation — Outbound), TMF653 (Service Test — Outbound), TMF663 (Shopping Cart — Inbound/Outbound), TMF769 (Product Test — Inbound), TMF683 (Party Interactions), TMF669 (Party Role Management)

### API Availability: Managed Package vs Core Platform

| API | Availability |
|-----|-------------|
| TMF621 v4, TMF622 v4, TMF648, TMF651, TMF667, TMF671 | Managed Package only |
| TMF620, TMF621 v5, TMF622 v5, TMF629, TMF637, TMF679 | Managed Package AND Core (Salesforce Platform) |
| TMF622 Notification, TMF637 Notification, TMF629 Notification, TMF632 Notification | Outbound; Managed Package and Core |

## CPQ Architecture: Managed Package vs Standard Cart APIs

### Managed Package (Legacy) CPQ
- CPQ logic runs via custom Apex installed on the platform
- Subject to governor limits: CPU time (10s sync), heap size (6 MB sync / 12 MB async), SOQL queries (100 sync / 200 async)
- Complex quote/cart operations can crash due to heavy JSON processing (text→data→text conversions)
- Still supported; default deployment model for pre-Standard CPQ orgs

### Standard Cart-Based APIs (Modern)
- CPQ logic processed by Salesforce's native Java core platform
- Bypasses Apex governor limits — runs at Java layer speed
- Significantly faster for complex carts and large catalogs
- Requires EPC Compile Data to be generated before use
- Migration path: Enable "Standard Salesforce libraries and cache with CPQ Cart-Based APIs" via Vlocity CMT Administration → Enable Features

**Why migrate:** Managed Package CPQ hits governor limits (CPU, heap, SOQL) as product catalogs and cart complexity grow. Standard Cart APIs offload processing to the Salesforce core Java layer.

## EPC Compile Data (Standard Cart APIs Prerequisite)

Standard Cart-Based APIs require EPC data to be pre-compiled into a structured cache format.

**To generate compile data:**
```
Vlocity CMT Administration → EPC Jobs → GENERATE COMPILE DATA → Start → Select pricelist → Start
```

**What gets compiled:**
1. Configuration, Eligibility, Availability, Attribute Configuration rules
2. Context Rules
3. Product Configure Procedures (PCPs)
4. Mappers (Asset-to-Order, Asset-to-Quote, Quote-to-Order, Order-to-Asset, Opportunity-to-Quote)
5. Product Hierarchy (stored in DataStore object, keyed by `ProductGroupKey__c`)
6. Promotions
7. Pricing Plans and Pricing Variable Maps

**Cache table:** `CachedAPIResponse__c` — stores compiled data by `Type__c` + `CacheKey__c`

**Snapshot management:** Each compile creates a new `ConfigurationSnapshot__c` record. Runtime always picks the latest active snapshot. Purge older snapshots manually to free data storage.

**When to re-run compile data:**
- Any modification to Rule, AttributeAssignment, ProductChildItem, PriceListEntry, Promotion, PricingPlan, CustomObjectMap
- After product hierarchy changes: run Product Hierarchy Maintenance first, then Generate Compile Data
- After clearing Managed Platform Cache

**Full clean slate (nuclear option — dev only):**
```apex
delete [SELECT Id FROM vlocity_digital__CachedAPIResponse__c];
delete [SELECT Id FROM vlocity_digital__AsyncProcess__c];
delete [SELECT id FROM vlocity_digital__ConfigurationSnapshot__c];
// Reset snapshot lock and clear all cache
```

## API Version History and Release Notes

| Salesforce Release | Key API/Feature Additions |
|-------------------|--------------------------|
| API version 58.0+ | IDX Workbench / datapack import minimum requirement |
| Spring '21 | UOW Mode defaults to True; UseAssetReferenceIdForParentAndRoot defaults to True for new installs; Standard Cart APIs available |
| Fall '18 | Product selling period dates added (required upgrade path for pre-Fall '18 orgs) |
| Spring '26 | Dual access: MuleSoft Gateway + Direct Access (Connect/Apex REST) both supported; TMF679 v5 added; Agentforce for Cart Operations |
| Summer '26 | MuleSoft Gateway still supported (last version) |
| Winter '27 | MuleSoft Gateway deprecated; only Direct Access supported going forward |
| Spring '26 (TMF) | TMF621 v5 Trouble Ticket introduced; TMF622 v5 Product Ordering introduced |
| CME Package 2025.12.04 | Latest CME managed package version (includes CLM, OM, CPQ, OmniStudio SR support) |

## Edition and License Requirements

- **Communications Cloud** is a licensed add-on on top of core Salesforce
- Requires Salesforce CRM (Sales Cloud or Service Cloud) as the base
- Notification Framework is included in the Communications Cloud base SKU
- DocGen (for Agreement Management TMF651) requires DocGen OrgPerm + DocGenDesigner addon
- MuleSoft Direct Integrations require a MuleSoft license (Anypoint Platform)
- Product Offering Qualification (TMF679) may require LifecycleManagement license for full Asset lifecycle fields
- Industries CPQ is bundled; Subscription Management and Revenue Cloud billed separately

## Key Technical Notes

- All Vlocity-era custom objects and fields use the `vlocity_cmt__` namespace prefix
- The namespace is maintained post-acquisition for backward compatibility
- `vlocity_cmt__GlobalKey__c` is the universal cross-system key used in TM Forum resource IDs
- Direct Access API endpoint domain: `api.commscloud.salesforce.com` (US Production)
- EU Production endpoint: `eu.api.commscloud.salesforce.com`
- OAuth 2.0 is the required authorization protocol for all Industry API access
