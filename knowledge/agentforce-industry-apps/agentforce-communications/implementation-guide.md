---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); CME Managed Package Dev Guide (2025.12.04); SFI Best Practices; Standard Cart APIs Playbook; Communications Cloud Integration Patterns and Practices (2025.12.10); B2B Telecommunications documents ingested 2026-05-10; B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: implementation-guide
last-updated: 2026-05-10
---

# Communications Cloud — Implementation Guide

## Prerequisites and License Verification

Before starting implementation, confirm the following with the customer:

| Requirement | Notes |
|-------------|-------|
| Salesforce CRM license (Sales Cloud or Service Cloud) | Base platform required |
| Communications Cloud license | Industry-specific add-on |
| OmniStudio license | Included in most Communications Cloud packages |
| DocGen / DocGenDesigner license | Required only if implementing Agreement Management (TMF651) |
| MuleSoft Anypoint Platform license | Required only if using Outbound MuleSoft Direct Integrations |
| LifecycleManagement license | Required for `Asset.LifecycleEndDate` in Product Inventory (TMF637) |
| Salesforce API version 58.0+ | Required for IDX Workbench datapack import |

---

## Module Setup Sequence

### Module 1: Product Catalog Setup

**Purpose:** Define the product hierarchy — catalogs, categories, product specifications, product offerings, and pricing.

**Step-by-step:**

1. **Enable Communications Cloud features** in Setup → Feature Settings → Industries → Communications
2. **Configure the Attribute Category** — create or verify a default `vlocity_cmt__AttributeCategory__c` record; this is mandatory for TMF620 API attribute operations
3. **Create Price Lists** — create `vlocity_cmt__PriceList__c` records; associate to org via `VlocityIntegrationSetting__mdt` (set `TMForumPriceList` field)
4. **Create Catalog (root)** — create a `vlocity_cmt__Catalog__c` record with `vlocity_cmt__IsCatalogRoot__c = true`
5. **Create Categories** — create `vlocity_cmt__Catalog__c` records with `vlocity_cmt__IsCatalogRoot__c = false`; relate to root catalog
6. **Create Product Specifications** — create `Product2` records representing the base product specification type; set `vlocity_cmt__Status__c = Active`, record type = "Product"
7. **Create Product Offerings** — create `Product2` records representing sellable offers; set `vlocity_cmt__IsOrderable__c = true` for standalone-sellable products
8. **Define Bundles** — create `vlocity_cmt__ProductChildItem__c` records linking parent and child `Product2` records; set min/max quantities
9. **Define Attributes** — create `vlocity_cmt__Attribute__c` records; assign to products via `vlocity_cmt__AttributeAssignment__c`
10. **Create Price List Entries** — create `vlocity_cmt__PriceListEntry__c` records linking products to price lists; set charge type (One-Time, Recurring), frequency, and amount
11. **Import TMFOpenAPIs datapacks** via IDX Workbench (see metadata-tooling.md)
12. **Set PriceList in Custom Metadata** — update `VlocityIntegrationSetting__mdt.TMForumPriceList` to reference the active price list

**Verification query:**
```soql
SELECT Id, Name, vlocity_cmt__IsCatalogRoot__c, vlocity_cmt__IsActive__c
FROM vlocity_cmt__Catalog__c
ORDER BY vlocity_cmt__IsCatalogRoot__c DESC
```

---

### Module 2: Configure, Price, Quote (Industries CPQ)

**Purpose:** Enable guided selling, product configuration, and quoting.

**Step-by-step:**

1. **Verify product catalog is complete** (prerequisite)
2. **Configure Pricebooks** — create `Pricebook2` records and `PricebookEntry` records alongside vlocity price list entries
3. **Enable CPQ in OmniStudio** — deploy standard CPQ OmniScripts from the Communications Cloud package
4. **Configure Eligibility Rules** — define rules that determine which products are available to which account types/segments using Calculation Matrix or Apex
5. **Configure Pricing Rules** — define promotion application rules via `vlocity_cmt__Promotion__c` and `vlocity_cmt__TimePlan__c`
6. **Configure Product Relationships** — define requires/excludes/recommends in `vlocity_cmt__ProductRelationship__c`
7. **Set up Opportunity-to-Quote flow** — default behavior: CPQ creates an Opportunity automatically (named `TMF Opportunity_%TIMESTAMP%`) when a quote is created via TMF648 API
8. **Configure Quote Templates** — for customer-facing documents (requires DocGen if using Agreement Management)
9. **Assign CPQ Permission Sets** — assign relevant permission sets to Sales Rep and CPQ Admin personas

**Key configuration item:**
- `VlocityIntegrationSetting__mdt` — stores PriceList reference for TMF API quote creation
- Opportunity is hardcoded as mandatory in TMF648 POST — cannot be removed without customization

---

### Module 3: Order Management

**Purpose:** Convert quotes to orders, decompose orders for fulfillment, and orchestrate provisioning.

**Step-by-step:**

1. **Verify CPQ setup is complete** (prerequisite)
2. **Configure Order Decomposition Rules** — define how a customer order breaks into sub-orders per provisioning domain (network, IT, billing, etc.); implemented via Integration Procedures and Order Decomposition configuration
3. **Deploy Order Orchestration OmniScripts** — standard OmniScripts from Communications Cloud package
4. **Configure Sub-Order routing** — define which `vlocity_cmt__SubOrder__c` records route to which fulfillment system
5. **Configure Order Status transitions** — custom picklist values for `Order.Status` aligned to telecom order lifecycle (Draft, Submitted, In Progress, Completed, Cancelled)
6. **Set up Order Item relationship rules** — configure parent-child relationships via `vlocity_cmt__OrderItemRelationship__c`
7. **Configure Integration Procedures for BSS/OSS callouts** — build Integration Procedures that call network provisioning, billing, and activation systems
8. **Enable placeOrder API flow** — order auto-transitions Draft → Activated when placed via TMF622 API
9. **Configure tax calculation** (if using RLM/Revenue Cloud) — tax is asynchronous; orders cannot be activated until tax calc completes; PATCH not supported for tax-enabled RLM orders via TMF622 v5

**Key fields to configure on Order:**
- `vlocity_cmt__PriceList__c` — mandatory for EPC-configured orders
- `vlocity_cmt__RequestedStartDate__c` — mandatory in TMF622 implementation
- `vlocity_cmt__OriginatingChannel__c` — set per order capture channel

---

### Module 4: Product Inventory Management

**Purpose:** Track installed/active products per account as service inventory.

**Step-by-step:**

1. **Verify Order Management is functional** (prerequisite — orders must create Assets)
2. **Configure Asset record type** — ensure Asset uses appropriate record type for telecom inventory
3. **Configure `vlocity_cmt__ProvisioningStatus__c` picklist** — add values matching TMF637 status values (Active, Inactive, Terminated, Suspended, etc.)
4. **Map Asset to Billing Account** — populate `vlocity_cmt__BillingAccountId__c` from Order during provisioning
5. **Configure V1 vs V2 Attribute Model** — decide between `vlocity_cmt__JSONAttribute__c` (V1) and `AttributeSelectedValues__c` (V2); V2 is preferred for new implementations
6. **Enable LifecycleManagement** (if using `LifecycleEndDate`) — requires additional license
7. **Verify TMF637 Static Resource** — ensure TMF637 v4 datapack is imported

---

### Module 5: Trouble Ticket Management (Case)

**Purpose:** Manage customer-reported incidents, complaints, and service requests.

**Step-by-step:**

1. **Configure Case record type** for telecom tickets
2. **Create custom picklist values** on `Case`:
   - `vlocity_cmt__severity__c`: Critical, Major, Minor
   - `Type`: Incident, Complaint, Request
   - `Priority`: Critical, High, Medium, Low
   - `Origin`: (channel values per business requirement)
3. **Enable FLS** for all Case fields per user profile (v5 prerequisite)
4. **Configure CaseTroubleTicket** extension object fields (v5)
5. **Enable org permissions**: CommsCloud, Cases
6. **Configure Case routing** via Case Queues or Omni-Channel

---

### Module 6: Agreement Management

**Purpose:** Manage contracts, MSAs, and service agreements.

**Prerequisites:**
- DocGen OrgPerm enabled
- DocGenDesigner addon license

**Step-by-step:**

1. **Enable DocGen** in Setup
2. **Create DocumentTemplate records** (AgreementSpecification) — names must be unique
3. **Configure Contract record type** for telecom agreements
4. **Set `ContractType` picklist values** for agreement types
5. **Configure Agreement Items** — relate `Product2` records to contracts (Sales Contract Line)
6. **Set up PATCH-enabled Agreement updates** — only: description, engagedParty, associatedAgreement, agreementSpecification, agreementItem

---

### Module 7: Notification Framework (CDC Outbound)

**Purpose:** Push TM Forum-aligned change notifications to external systems.

**Step-by-step:**

1. **License verification** — Notification Framework is included in base Communications Cloud SKU; no extra license needed
2. **Create `IntegrationProviderDefinition__mdt` record** for each object to be monitored:
   - Set Resource API Name (e.g., `Account`)
   - Set Resource Field API Names (fields to monitor)
   - Set Integration Provider Definition (endpoint/system reference)
   - Set Change Event Type (Insert, Update, Delete, Undelete)
3. **Configure field-level CDC** — use Integration Provider Definition Mapping to select specific fields for update events
4. **Verify CDC limits are bypassed** — the 5-entity CDC limit does NOT apply to this framework; configure as many resources as needed
5. **Test with AccountContactRelation** changes to verify TMF632 notification delivery

---

## Industries CPQ Configuration Steps

### Product Catalog Configuration Checklist
- [ ] Root Catalog created (`vlocity_cmt__IsCatalogRoot__c = true`)
- [ ] Categories created and linked to root catalog
- [ ] Product Specifications created (record type = Product, status = Active)
- [ ] Product Offerings created with `vlocity_cmt__IsOrderable__c` set appropriately
- [ ] Bundle relationships defined (`vlocity_cmt__ProductChildItem__c`)
- [ ] Attributes defined and assigned to products
- [ ] Price Lists created
- [ ] Price List Entries created for all sellable products
- [ ] `VlocityIntegrationSetting__mdt.TMForumPriceList` set to active price list
- [ ] Default Attribute Category configured
- [ ] TMFOpenAPIs datapacks imported via IDX Workbench

### CPQ Rule Configuration
| Rule Type | Object Used | Description |
|-----------|-------------|-------------|
| Eligibility Rules | Calculation Matrix or Apex | Which products are available to which segments |
| Pricing Rules | `vlocity_cmt__Promotion__c` | Discounts, promotions, offers |
| Product Relationships | `vlocity_cmt__ProductRelationship__c` | Requires / Excludes / Recommends |
| Bundle Constraints | `vlocity_cmt__ProductChildItem__c` | Min/max quantities for bundle children |
| Attribute Constraints | `vlocity_cmt__AttributeAssignment__c` | Which attributes apply to which products |

---

## OmniStudio Usage Patterns for Communications Cloud

### OmniScripts (Guided UI Flows)
| Pattern | Use Case |
|---------|----------|
| Guided Product Configuration | Walk sales reps through product/bundle selection |
| Order Capture Flow | Capture customer and product details; create Order |
| Service Qualification | Present eligible products based on address/location |
| Change Request Flow | Modify active services on an account |
| Trouble Ticket Creation | Guided ticket submission for customer issues |

### DataRaptors (Data Load / Transform / Extract)
| Pattern | Use Case |
|---------|----------|
| Load — Product Catalog Data | Mass load product catalog from external systems |
| Extract — Order Summary | Extract order and line item data for display in FlexCard |
| Transform — TMF Attribute Mapping | Map vlocity_cmt attribute JSON to TMF productCharacteristic format |
| Extract — Asset Inventory | Extract installed base data for a given account |
| Load — TMF622 Order Payload | Map inbound TMF622 JSON to Order/OrderItem fields |

### Integration Procedures (Server-Side Orchestration)
| Pattern | Use Case |
|---------|----------|
| Order Decomposition | Split customer order into provisioning sub-orders |
| BSS System Callout | Call billing system APIs after order placement |
| OSS Provisioning Trigger | Trigger network provisioning system from order events |
| Address Validation | Call TMF673 Geographic Address service |
| Service Availability Check | Call TMF645 Service Qualification service |
| Price Calculation | Invoke pricing engine for complex pricing scenarios |
| Notification Delivery | Send TMF-aligned notifications to external systems |

### FlexCards (UI Components)
| Pattern | Use Case |
|---------|----------|
| Account 360 Card | Display account services, orders, tickets in one view |
| Asset Inventory Card | Show installed products per account |
| Order Status Card | Real-time order progress tracking |
| Product Catalog Card | Browse available products for a customer |

---

## Integration Patterns (BSS/OSS Stack)

### Inbound (External → Salesforce)

| External System | Integration Pattern | TM Forum API Used |
|----------------|--------------------|--------------------|
| BSS Product Catalog | External catalog publishes to Salesforce | TMF620 POST ProductOffering |
| Network OSS (Orders) | Network sends order status updates | TMF622 PATCH ProductOrder |
| Billing System | External billing creates tickets | TMF621 POST TroubleTicket |
| CRM/BSS | External CRM syncs customer data | TMF629 POST Customer |
| Inventory System | Inventory sync to Salesforce | TMF637 (sync Asset records) |

### Outbound (Salesforce → External)

| External System | Integration Pattern | Integration Template Used |
|----------------|--------------------|-----------------------------|
| Network OSS (Provisioning) | Salesforce sends service orders | TMF641 Service Order |
| BSS Catalog Sync | Publish product changes downstream | TMF620 Product Catalog |
| Address Validation | Validate customer addresses in real-time | TMF673 Geographic Address |
| Service Qualification | Check service availability at address | TMF645 Service Qualification |
| Site Management | Manage geographic sites for service delivery | TMF674/TMF675 |

### API Migration Note (Winter '27)
- From Winter '27: MuleSoft Gateway for inbound API calls will be deprecated
- All integrations must migrate to Direct Access (Connect/Apex REST endpoints)
- Update BSS/OSS system configurations to point to `api.commscloud.salesforce.com` directly

---

## Permission Sets Required by Module/Persona

> **To-be-grounded:** Official permission set API names are not fully documented in the pages retrieved. The following are best-practice names based on standard Communications Cloud implementation patterns. Verify actual names in org:

| Permission Set Name | Module | Persona |
|--------------------|--------|---------|
| `CommCloudUser` | All modules | All users (base access) |
| `IndustriesCPQUser` | CPQ / Product Catalog | Sales Rep, CPQ Admin |
| `OmniStudioUser` | OmniStudio | All OmniStudio flow users |
| `OmniStudioAdmin` | OmniStudio | OmniStudio developers/admins |
| `VlocityOrderManagement` | Order Management | Order Manager |
| `IndustryAPIAccess` | TM Forum Industry APIs | Integration users, API consumers |
| `DocGenUser` | Agreement Management | Users creating agreements |
| `DocGenDesigner` | Agreement Management | Agreement template designers |

**To verify actual permission sets in an org:**
```soql
SELECT Id, Name, Label FROM PermissionSet WHERE NamespacePrefix = 'vlocity_cmt'
```

---

## Key Governor Limits and Constraints

| Constraint | Value / Notes |
|-----------|---------------|
| TMF648 POST synchronous SLA | 3-second API SLA is NOT achievable for synchronous quote creation |
| Tax calculation (RLM/v5) | Asynchronous — blocks order activation until complete |
| CDC entity limit | Standard Salesforce limit of 5 CDC entities does NOT apply to Notification Framework |
| Quote versioning | Not supported in TMF648 |
| TMF622 v5 PATCH | PATCH not supported for RLM APIs |
| IDX Workbench API minimum | Salesforce API 58.0 required |
| AgreementSpecification names | Must be unique |
| RelatedParty in TMF648 | Requires AccountId with Status "Active" and Active "Yes" |
| QuoteLineItem quantity (TMF648) | Fixed at 1 |
| TMF648 action support | "add" action only |
| TMF679 qualification | Only `Id` values are processed; name/description fields are ignored |
| MuleSoft Gateway deprecation | Winter '27: only Direct Access supported for inbound APIs |
| TMF622 v4 ProductOffering lookup | Products must pre-exist in Salesforce (cannot create on-the-fly via order) |
| US region availability | US East only (as of Spring '26); EU also available |

---

## Standard Cart APIs Migration Checklist

Before migrating from Managed Package CPQ to Standard Cart-Based APIs:

- [ ] Enable Standard Cart APIs: Vlocity CMT Administration → Enable Features → "Standard Salesforce libraries and cache with CPQ Cart-Based APIs" → Configure
- [ ] Clear Managed Platform Cache before generating compile data
- [ ] Run Product Hierarchy Maintenance job (if any hierarchy changes)
- [ ] Run EPC Compile Data job for each active price list
- [ ] Verify compile data exists: `SELECT COUNT() FROM CachedAPIResponse__c WHERE Type__c = 'cartCompiledOfferHierarchy'`
- [ ] Set CPQ Configuration Settings: `UOW Mode = true`, `V2 JSON = enabled`, `CacheEnabled = true`
- [ ] Set `DeltaPrice = true` and `DeltaValidate = true` for carts with >50 items
- [ ] Set `CacheAPI.Trimmode = true` for best Basket API performance
- [ ] Set `LevelBasedApproach = true` for bundles with depth > 2
- [ ] Configure context key pattern in all CPQ API calls (improves performance significantly)
- [ ] Test all existing CPQ OmniScripts against Standard Cart APIs
- [ ] Validate ESM flows if ESM is in use

---

## Salesforce Best Practices for Communications Cloud Implementations

### Data Layer
- Use custom objects for non-standard data; do not modify standard objects unnecessarily
- Store global data on parent/standard Salesforce objects for reporting
- Reduce the number of page layouts on standard objects (performance and maintenance benefit)
- Local / segment-specific data belongs in child custom objects with appropriate visibility
- Review Communications Cloud Blueprint: `architect.salesforce.com/diagrams#design-patterns`

### Process Layer (Automation)
- Default to OmniStudio for user-driven and background automation
- Evaluate triggers: User-Triggered (Action Item, Field Change, Navigation, Pricing Plan) vs Background (Trigger, Process Builder, Auto-Launch Flow)
- Use Formula Fields for simple business logic and validation
- Lightning Flow Wizard for complex, multi-step processes
- Apex for computation-heavy logic that can't be done declaratively

### UI Layer
- Maximum 10 Lightning Components per Page Layout (performance guideline)
- Use Dynamic Components for conditional visibility (profile, record type, field value-driven)
- FlexCards for contextual data display; OmniScripts for guided user interactions

### Apex Development Standards
- Never put SOQL or DML inside a loop
- Use SOQL for loops for large result sets (hundreds/thousands of records) to avoid heap size issues
- No empty try/catch blocks — always handle exceptions meaningfully
- For multi-phase DML: use save points + rollback in catch blocks
- Never hardcode IDs — use `RecordTypeUtil.getRecordTypeByDeveloperName()` or similar
- For DML where partial success is acceptable: use `Database.insert(list, false)` and iterate results
- Recommended frameworks: Ian's (Nebula) Trigger Framework; Nebula Error Logger; Vlocity Integration Framework

### Governance
- Architecture Board should review all non-standard design decisions
- Technical Architect oversees all projects; participates in Scrum of Scrums
- Run Optimizer report before every release; compare reports between releases to detect drift
- Apply custom indexes for all CME objects (required for CPQ performance — contact Salesforce for index application)
- Adopt package-driven development (DX Scratch Orgs) — split components into meaningful packages

---

---

## Module 8: Digital Commerce (B2C Self-Service Ordering)

**Purpose:** Enable high-volume B2C self-service ordering through digital channels (web/mobile portal).

**Prerequisites:** Product Catalog, CPQ, and Order Management configured (Modules 1–3 above).

**Step-by-step:**

1. **Enable Standard Digital Commerce APIs** (recommended for new B2C implementations):
   - Vlocity CMT Administration → Enable Features → Standard Digital Commerce APIs → Enable
2. **Run Load API Metadata job** (prerequisite for compile data):
   - Vlocity CMT Administration → Cache Catalog Product Definitions → Start → Select Catalog(s), Start Date and End Date → Ok
   - Refresh the page after the job to verify it ran (if no job visible, Standard DC APIs not enabled)
3. **Verify compile data** — generated DC compile data differs from CPQ EPC compile; both may be needed
4. **Configure anonymous cart access** — in Standard DC APIs, no pseudo-accounts are created for anonymous sessions; existing user accounts and assets are still queryable
5. **Update custom hook interface names** — if any custom implementations exist from Classic DC APIs, rename to Standard DC interface names:
   - `CpqAppHandler`, `CpqContextRule`, `CpqOfferEligibility`, `CpqResponse`, `CpqValidation`, `CpqTimePolicy`, `CpqTightestMatch`, `CpqPricingVariableCalc`, `CpqPricingEligibility`, `CpqPricing`
6. **Refactor any pseudo-order dependent code** — Standard DC APIs do not create pseudo-orders, pseudo-accounts, or related objects during basket operations. Any triggers or Integration Procedures using these objects must be refactored to use `CartDocument`/`CartDocumentItem` instead.
7. **Configure Cart Context Key** — for Create Cart API in Standard DC, only `cartContextKey` is supported (not JSONResult)
8. **Test abandoned cart tracking** — verify `Cart__c` and `CartItem__c` records are created for tracked anonymous/authenticated sessions
9. **Configure Experience Cloud site** (for consumer portal) — add cart and catalog components to the site

**Key constraints:**
- Async bulk Create Cart job is not supported in Standard DC APIs
- Basket API Response is not cached in Standard DC APIs (cart operations use cart document)
- Multiple orders can be created by passing multiple CartContextKeys (governor limits apply)
- `ConfigurationSnapshot__c` effectivity: runtime picks the latest active snapshot; purge older ones to free storage

---

## Module 9: Connected Assets Setup

**Purpose:** Enable IoT/telematics event processing and actionable orchestration for connected assets (CPE, set-top boxes, mobile devices, network equipment).

**Prerequisites:** Communications Cloud base license; Actionable Asset Event Orchestration usage entitlement.

**Step-by-step:**

1. **Enable features in Setup:**
   - Actionable Event Orchestration
   - Event Orchestration Decision Table
   - Context Definitions
2. **Assign permission sets:**
   - Event designers: `Actionable Event Orchestration Designer`, `Context Service Admin`, `Rule Engine Designer`
   - Runtime users: `Actionable Event Orchestration Runtime`, `Context Service Runtime`, `Rule Engine Runtime`
   - Additional read access on Cases, Asset Milestones, Record Alerts
3. **Mark assets as Connected Services Active** — only assets with Connected Services Active = true are considered for orchestration; usage-based entitlement applies (300 orchestrations/month for Manufacturing usage type)
4. **Integrate telematics provider with Salesforce** — via MuleSoft or custom middleware; telematics system publishes events to Salesforce
5. **Create event types and subtypes** — define categories to differentiate events (e.g., PerformanceAndDiagnostic / MalfunctioningFilters)
6. **Create Context Definition** — define nodes and attributes matching the event request payload structure (Asset Identifier, Event Type, Event Fault Code, sensor values, signals)
7. **Configure execution procedure** — Expression Sets (for simple record creation/update) or Flows (for complex workflows)
8. **Configure Filter and Match decision table** — extend to add input/output parameters; routes each event type/subtype to correct execution procedure
9. **Choose event ingest method:**
   - Platform Event: Publish `Actionable Orchestration Source Event`; subscribe to `Actionable Orchestration Response Event` for results
   - Business API: POST to Orchestration Inbound Events API; review response for executed actions and errors
10. **Test with sample event payload** — verify orchestration creates correct record type (Case, Work Order, Asset Milestone, Record Alert)

---

## Module 10: Asset Service Lifecycle Management (ASLM) Setup

**Purpose:** Enable field service management for telecom asset operations (CPE installation, repair, device exchange, depot repair).

**Prerequisites:** Service Cloud (with Field Service add-on for most ASLM features); Communications Cloud license.

**Key features and setup steps:**

1. **Advanced Exchange:** Enable feature; assign `Service Part Return Management` permission set to admins, field techs, and service managers; configure work order-to-return order line item integration
2. **Asset Coverage View:** No special setup required; appears on Asset record page with entitlement configuration
3. **Asset Interactive Hierarchy:** Enable in Setup; useful for visualizing CPE hierarchies (modem → router → set-top boxes)
4. **Book Service Appointment:** Requires Field Service; configure service territories, operating hours, and skill requirements
5. **Depot Repair:** Configure work order types for depot repair; enable auto-population from return order line items
6. **Inventory Batch Management:** Enable batch tracking on `ProductItem` records for serialized/non-serialized inventory
7. **Inventory Search and Transfer:** Configure Criteria-Based Search for inventory; set up transfer workflows between warehouse locations
8. **Inventory Count:** Configure cycle count schedules; enable Field Service mobile app for count capture
9. **Inventory Replenishment:** Define replenishment policies (min/max stock thresholds); schedule automated replenishment job
10. **Product Service Campaign:** Configure product service campaign types (recall, upgrade, proactive service); assign lists to service agents; integrate with Asset records for mass action
11. **Work Order Estimation:** Configure work type groups; enable estimation from quotes, orders, and asset repair tickets

---

## Module 11: B2C-Specific CPQ Configuration

### B2C Catalog Structure Recommendations

For B2C implementations, the product catalog typically has a simpler structure than enterprise B2B:

| Element | B2C Approach |
|---------|-------------|
| Catalog depth | 2–3 levels max (Root Catalog → Category → Product) |
| Bundle depth | 1–2 levels (Parent offering → child components) |
| Attribute model | V2 (`AttributeSelectedValues__c`) strongly preferred |
| Promotions | High volume; must compile data after each promotion change |
| Eligibility | Address-based (fiber/fixed) + account-type based |
| Price lists | Typically 1–2 (consumer + promotional); separate from B2B price list |

### B2C Household and Party Model Setup

1. **Enable Person Accounts** (if using Person Account model for individual consumers) — requires Salesforce org configuration; cannot be undone; separate from standard Account+Contact model
2. **Configure Party record type** for Individual consumer (`Party__c` with appropriate record type)
3. **Configure Household record** (`Household__c`) — used for family plan management, multi-line account view
4. **Configure PartyRelationshipType records** — create types: Head of Household, Family Member, Authorized User
5. **Link Accounts to Households** via `PartyRelationship__c` with start/end dates
6. **Configure Relationship Graph** — `RelationshipGraph__c` and `RelationshipGraphTraversal__c` for visual display of household relationships in the agent console

### B2C Subscription Management Setup

1. **Configure `Subscription__c` object** — define subscription types for each service line (mobile, broadband, TV)
2. **Link subscriptions to Account, Asset, and Billing Account**
3. **Configure `AccountOffer__c`** — track offers made to consumer accounts and acceptance dates
4. **Configure `AccountBalance__c`** — set up billing system integration to sync balance snapshots; used for 360° view
5. **Configure `Statement__c` and `StatementLineItem__c`** — set up billing system integration to import statement data

---

## Module 12: Order Management (IOM) Setup

Industries Order Management (IOM) provides catalog-driven order decomposition and orchestration. It is the fulfillment backbone for both B2B and B2C orders.

### Order Management Roles

| Role | Responsibilities |
|------|----------------|
| System Administrator | Installation, setup, patch management, non-standard situation resolution |
| Fulfillment Designer | Create technical products, decomposition rules, orchestration plan definitions; integration design |
| Fulfillment Manager | Manage queues, allocate work, analytics, SLA oversight |
| Fulfillment Operator | Handle manual task queues at runtime; resolve items before SLA breach |
| Fallout Operator | Monitor error queues, investigate fallout, retry or skip failed tasks |
| Integration Specialist | Build callout configurations to external fulfillment systems |

### Step 1: Enable Order Management in the Org
1. Install Communications Cloud managed package (includes OM module)
2. Verify `Order Management` feature is licensed
3. Enable `Industries Order Management` in Setup → Industries Setup
4. Configure four Orchestration Queues (created automatically on install)

### Step 2: Configure Key Custom Settings

| Custom Setting API Name | Recommended Value | Notes |
|------------------------|------------------|-------|
| `OrderSubmitMode` | `Synchronous` (default) or `Queueing` | Use `Queueing` for large-volume orgs; changes status state values |
| `OrchestrationMode` | `PlatformEvents (Queueable)` | Best scalability (default since Spring '21 v230) |
| `OrderDecompositionEnabled` | `true` | Set `false` only if FulfilmentRequests are not used — improves submit performance |
| `CrossOrderDependencyAllowed` | `false` (default) | Enable for cross-order orchestration dependencies |
| `LoggingEnabled` | `false` | Keep `false` in all environments; debug logging causes Apex Time Limit exceptions in orchestration |

### Step 3: Configure Technical Products in the Enterprise Product Catalog

Technical products represent the fulfillment layer — entities understood by downstream systems (billing, provisioning, network). They are defined in the Shared Catalog (Vlocity Product Console).

1. Open **Vlocity Product Console** → Foundation → Attributes → create decomposition attributes (prefix `ATT_DC`)
2. Create **Object Types** for each technical product category — use IS-A hierarchy (BASE Service Spec Type → subtype)
3. Assign decomposition attributes to object types via Layout Management → Decomposition Attributes section
4. Create **Technical Products** (Product2 records with technical object types assigned)
5. Create **Decomposition Relationships** — map commercial product fields/attributes → decomposition attribute on technical product

> **Key rule:** Technical product specifications must use attributes only — not standard Product2 fields. Standard fields are not reliably passed through the decomposition chain to external systems.

### Step 4: Define Orchestration Plan Definitions

1. In the **Order Management app** → Orchestration Plan Definitions tab → New
2. Define **Orchestration Scenarios** — rules that associate products/actions with a plan definition at runtime (e.g., product = Fiber Internet AND action = Add → use Fiber Add Orchestration Plan)
3. Design orchestration plan swimlanes:
   - **Limit to 16 orchestration items per swimlane** (exceeding can trigger max trigger depth exception)
   - **Converging design preferred:** end each plan with a single Auto Task
   - **Minimize parallelism for DML-heavy items** — parallel DML on same parent records causes row lock timeouts
4. Configure orchestration item types:
   - **Auto Task** — automated system tasks (callouts, data enrichment)
   - **Manual Task** — human tasks assigned to Orchestration Queues
   - **Callout** — external system callout via Integration Procedure or Apex adapter

### Step 5: Configure Fallout Handling

1. Assign each orchestration item an **error queue** for fallout routing
2. Configure **Jeopardy (SLA) rules** — OM will flag orchestration items at risk of missing SLAs
3. Set up **retry policies** — define which error types are auto-retried vs flagged for manual intervention
4. Build **fallout dashboards** for Fallout Operators showing stuck/failed orchestrations

### Step 6: Integrate with Downstream Fulfillment Systems

Fulfillment systems receive order data through orchestration callouts:

1. **Create Named Credentials** for each downstream system (billing BSS, network OSS, inventory)
2. **Create Integration Procedures** for each callout type — these are invoked by Auto Task orchestration items
3. Map OM fulfillment request data → downstream system payload using DataRaptors
4. Handle responses: parse response, update FulfilmentRequestLine status, throw error if downstream failure
5. Test in a non-production environment before go-live using the OM test harness

### Step 7: Preparing for Production

Before go-live:

1. Run **Application Constraints check** — verify order volume projections against OM platform limits
2. Disable **Apex Debug Logging** and set `LoggingEnabled = False` (logging overhead causes CPU limit failures)
3. Configure **Orchestration Queue balancing** — OM auto-load-balances across 4 queues; verify queue assignments are set
4. Load test with representative order mix — include supplemental/change orders, not just new orders
5. Configure **monitoring dashboards** for: Orchestration Plans in progress, Fallout queue depth, SLA jeopardy counts

---

## B2B Communications Telco Transformation Discovery Questions

These questions are drawn from the Salesforce B2B Comms Architect Discovery Assistant framework.

### Product Catalog & EPC
1. How many products/offers are currently in scope for the initial implementation?
2. How many pricing rules, eligibility rules, and promotion types exist?
3. Is attribute-based pricing required (prices vary based on configuration attributes)?
4. What is the expected bundle depth (parent → child → grandchild levels)?
5. Are there separate catalogs for different customer segments (B2C, SMB, Enterprise)?
6. Is there a legacy product catalog system that must be synchronized?

### CPQ and Quoting
1. Are quotes required, or do agents place orders directly?
2. Is Enterprise Sales Management (multi-site, large enterprise quoting) required?
3. What is the expected number of line items per quote/order?
4. Are Standard Cart-Based APIs (vs Managed Package CPQ) required or preferred?
5. Is there a requirement for Quote versioning or approval workflows?
6. What MACD actions are required: Add, Change, Suspend, Resume, Remove?

### Order Management
1. How many downstream fulfillment systems exist (network OSS, billing BSS, IT systems)?
2. What is the order decomposition pattern — how many sub-order domains?
3. Are Fulfilment Requests used, or are commercial Orders sufficient?
4. What is the orchestration mode preference (Platform Events Queueable vs Batch Apex)?
5. Are there manual provisioning steps requiring Manual Queue assignment?
6. What is the SLA for order fulfillment per service type?

### Integration Architecture
1. Which BSS/OSS systems require integration (billing, provisioning, inventory, mediation)?
2. Is MuleSoft already licensed and in use, or is direct API integration the pattern?
3. Which TM Forum APIs are required inbound vs outbound?
4. Is the customer planning Direct Access or MuleSoft Gateway (note: Gateway deprecated Winter '27)?
5. What is the data residency requirement (US East only available for Direct Access in Spring '26)?
6. Are there CDC-based notification requirements to downstream systems?

### Contract Lifecycle Management (CLM)
1. Is DocGen licensed (required for Agreement Management and CLM)?
2. How many contract templates are in scope?
3. What is the contract signing workflow (DocuSign vs manual vs e-signature)?
4. Are there MSA / sub-agreement hierarchies required?

### Performance and Scale
1. What is the expected peak concurrent CPQ session count?
2. What is the largest expected cart size (number of line items)?
3. Are there large bundle hierarchies (depth > 2)? → Standard Cart APIs highly recommended
4. What data volumes exist for EPC objects (products, rules, promotions)?
5. Has the customer applied CME custom indexes? (Required for performance at scale)

---

## B2C-Specific Discovery Questions

### Digital Commerce / Consumer Self-Service
1. What channels does the customer support for B2C (retail stores, consumer portal, contact center, 3rd-party dealers)?
2. Can consumers place orders today through digital channels? What percentage of orders are digital?
3. How many different catalogs must be updated when introducing a new product or promotion?
4. How long does it take to introduce a new product or promotion? Are competitors faster?
5. How are eligibility rules enforced for retail sellers and CSRs based on customer location?
6. Do you use intelligent next-best-offer recommendations in both self-service and assisted modes?
7. Can customers amend in-flight orders? What is the order fallout rate?
8. What technology powers the current consumer commerce site? Can marketing launch offers without IT?
9. Do you have plans to launch new high-speed internet services or a new mobile brand requiring a greenfield IT stack?
10. Is Digital Commerce API usage near or exceeding design constraints? (This is a NO FLY ZONE risk)

### B2C CPQ and Quoting (from CPQ BVS Discovery Questions)
1. How long does it take to complete a quote using your current system?
2. How many quotes are processed per day? What is the average quote value?
3. What percentage of quotes are accepted without changes? How many require edits?
4. Does your team apply discounts to quotes? What is the average discount applied?
5. Are quoting errors common? Are errors detected before quotes are sent to customers?
6. How many quotes require recalculation? How much time does reprocessing take?
7. Do you process quotes for subscription renewals? How many per day/month?
8. How many different systems do reps use to manage customer information?
9. How much time do reps spend gathering customer information per quote (past pricing, previous discounts)?

### B2C Customer Service
1. How long does it take to onboard and train new B2C service agents? How many systems do they use daily?
2. What is the annual attrition rate among B2C service agents?
3. Can agents access a 360° view of all customer products, services, billing, and order status?
4. Can you deliver a consistent service experience across all channels and devices?
5. What is your average call handling time and first call resolution rate?
6. What percentage of consumers self-serve today online or via mobile device?

### B2C Field Operations
1. How long does it take to onboard and train B2C field service technicians?
2. What is the average time to complete an install and first-visit resolution rate?
3. How many jobs does a technician complete per day?
4. Do you have a video remote assistance program?
5. Are there plans to move common service tasks to self-service channels?

### B2C Marketing and Personalization
1. Are you able to capture every lead interaction across all sales channels (web, telesales, retail, door-to-door)?
2. Do you have a way to follow up with customers who abandoned their shopping carts?
3. How do you nurture leads from initial contact through conversion?
4. Are your current communications to customers personalized and relevant?
5. What is your current demand generation response rate / conversion rate?
6. Do you have challenges around Net Promoter Score (NPS)?

### B2C Architecture Risk Assessment
| Risk Factor | Significance |
|---|---|
| Fewer than 50 users when fully deployed | Integration cost disproportionate for small deployments |
| Relying on not-yet-GA functionality | NO FLY ZONE — do not proceed until GA |
| No long-range architecture/blueprint established | Likely delivery risk |
| Scope excludes product simplification | High customization risk; "lift and shift" programs go red |
| Digital Commerce API near design constraints | NO FLY ZONE |
| Implementing without an experienced accredited partner | Leading indicator for red accounts |
| "Lift and shift" vs transformation objective | Over-customization without extracting platform value |
| Production-ready launch > 12 months | Protracted timelines cause business impatience and risk |
| Implementing into a highly customized existing org | High complexity; consider greenfield pilot |
| Product hierarchy depth > 3 | Complexity increases |
| Max child items per product > 10 | Complexity increases |
| Max line items per quote > 20 | Complexity increases |
| External pricing system integration | Complexity increases |
| Basket creation response < 5 seconds required in all scenarios | Complexity increases; often not achievable |
| Sensitive data (PCI, PII, data residency) | Compliance complexity increases |

---

## Integration Patterns Reference

### Pattern Selection Matrix (from Salesforce Integration Patterns and Practices v65.0)

| Scenario | Pattern | Timing |
|---|---|---|
| Salesforce invokes external process and waits for response | Remote Process Invocation — Request and Reply | Synchronous |
| Salesforce invokes external process without waiting | Remote Process Invocation — Fire and Forget | Asynchronous |
| Data synchronized between Salesforce and external system in batch | Batch Data Synchronization | Asynchronous |
| External system creates, reads, updates, or deletes Salesforce data | Remote Call-In | Synchronous or Asynchronous |
| Salesforce UI updates automatically from data changes | UI Update Based on Data Changes | Asynchronous |
| Salesforce accesses external data in real time without storing it | Data Virtualization | Synchronous |

**Integration pattern categories:**
- **Process Integration** — orchestration or choreography across application boundaries; requires complex transaction handling; implement complex orchestrations at middleware layer (Salesforce timeout values and governor limits make this mandatory for long-running transactions)
- **Data Integration** — synchronize information between systems; ranges from simple upsert to complex referential integrity updates
- **Virtual Integration** — access external data in real time; removes need for data replication; triggered by user action, workflow, or record update

**Key architectural considerations:**
- Salesforce is transactional within itself but cannot participate in distributed transactions initiated outside Salesforce
- Complex multi-system transactions and rollback/compensation must be implemented at the middleware layer
- Message routing, translation, and transformation can be coded in Apex but not recommended for maintenance and performance reasons — use middleware
- Salesforce supports Change Data Capture (CDC) for near-real-time outbound data synchronization to external systems
