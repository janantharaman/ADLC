---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); CME Managed Package Dev Guide (2025.12.04); Communications Cloud Integration Patterns and Practices (2025.12.10); SFI Best Practices; Standard Cart APIs Playbook; B2B Telecommunications documents ingested 2026-05-10; B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: automation-patterns
last-updated: 2026-05-10
---

# Communications Cloud — Automation Patterns

## Order Lifecycle Automation

### End-to-End Order Flow

```
1. LEAD / OPPORTUNITY
   └── Account identified or created (Account record, Contact record)

2. QUOTE CAPTURE (Industries CPQ)
   ├── OmniScript: Guided product selection
   ├── Eligibility check: Calculation Matrix or Apex
   ├── Product configuration: Attributes set on QuoteLineItem
   ├── Pricing: vlocity_cmt__PriceListEntry__c applied
   ├── Bundle resolution: vlocity_cmt__ProductChildItem__c expanded
   └── Quote created (Quote + QuoteLineItem records)

3. QUOTE APPROVAL
   └── Quote.Status: Draft → Approved → Accepted

4. ORDER PLACEMENT (placeOrder API call)
   ├── Quote converts to Order + OrderItem records
   ├── Order.Status: Draft → Activated
   ├── vlocity_cmt__OrderItemRelationship__c created for bundles
   └── [If TMF622 v5 + RLM]: Tax calculation triggered (async)

5. ORDER DECOMPOSITION
   ├── Integration Procedure: DecomposeOrder
   ├── Customer order → Sub-orders per provisioning domain
   │   ├── Network sub-order (OSS provisioning)
   │   ├── Billing sub-order (BSS billing setup)
   │   └── IT sub-order (CRM/ERP updates)
   └── vlocity_cmt__SubOrder__c records created

6. ORDER FULFILLMENT
   ├── Integration Procedures call external BSS/OSS systems
   │   ├── TMF641 outbound (MuleSoft) → Network OSS service order
   │   ├── TMF645 outbound (MuleSoft) → Service qualification check
   │   └── Billing system API → Create subscription/billing account
   ├── OrderItem.vlocity_cmt__FulfilmentStatus__c updated per domain
   └── Sub-order status rolled up to parent order

7. PROVISIONING COMPLETE
   ├── Asset record created from OrderItem (installed base)
   ├── Asset.vlocity_cmt__ProvisioningStatus__c = Active
   ├── Asset.ActivationDate set
   └── CDC Notification: TMF637 inventory update → Notification Framework

8. BILLING ACTIVATION
   └── Subscription/billing account activated in billing system
```

---

## Product Eligibility and Pricing Rule Patterns

### Pattern 1: Address-Based Eligibility (Fiber/Fixed Services)

**Trigger:** Sales rep enters customer address during quote
**Flow:**
1. OmniScript captures address input
2. Integration Procedure calls TMF645 (Service Qualification via MuleSoft)
3. OR Integration Procedure calls internal address/coverage database
4. Response: list of eligible product IDs
5. DataRaptor filters `Product2` catalog to only eligible offerings
6. OmniScript presents only eligible products to sales rep

**Objects involved:**
- `Account` (customer)
- `Product2` (eligible product catalog)
- `ProductCategory` (used in TMF679 qualification)
- `Integration Procedure` (service qualification callout)

### Pattern 2: Segment-Based Eligibility (B2B vs B2C)

**Trigger:** Account record type or segment field
**Flow:**
1. OmniScript reads `Account.RecordType.Name` or segment field
2. Calculation Matrix evaluates eligibility rules by segment
3. Eligible product list filtered to segment-appropriate offers
4. Pricing tier applied based on account classification

**Objects involved:**
- `Account.RecordType`
- `vlocity_cmt__Catalog__c` (category filtering)
- Calculation Matrix (eligibility rules)
- `vlocity_cmt__PriceList__c` (segment pricing)

### Pattern 3: Promotion/Discount Application

**Trigger:** Quote creation or product selection
**Flow:**
1. During CPQ quote, promotion rules evaluated against order criteria
2. `vlocity_cmt__Promotion__c` records matched by:
   - Date validity (`StartDateTime`, `EndDateTime`)
   - Product eligibility (criteria groups and criteria logic)
   - Customer segment (criteriaParameter evaluation)
3. Matching promotion creates `vlocity_cmt__QuotePricingAdjustment__c` on quote
4. Discount applied to `QuoteLineItem.vlocity_cmt__EffectiveBaseOneTimeTotal__c` or recurring total
5. On order conversion, discount referenced on `OrderItem`

**TMF671 promotion structure:**
- `pattern` → rule with priority
- `criteriaGroup` → grouped conditions with logical relationship
- `criteria` → individual condition (parameter, operator, value)
- `action` → reward type and value (discount percentage or amount)

### Pattern 4: Bundle Pricing Aggregation

**Trigger:** Bundle product selected in CPQ
**Flow:**
1. Parent `Product2` (bundle) selected
2. `vlocity_cmt__ProductChildItem__c` records expand child products
3. Child product prices summed from `vlocity_cmt__PriceListEntry__c`
4. Bundle-level override pricing applied if configured
5. Quantity constraints enforced (`vlocity_cmt__MinQuantity__c`, `vlocity_cmt__MaxQuantity__c`)

---

## OmniStudio Flow Patterns for Order Capture and Service Qualification

### OmniScript: Order Capture (Telecommunications Standard Pattern)

```
Step 1: Customer Lookup / Account Selection
  └── DataRaptor Extract: Account + Contact details

Step 2: Service Address Entry (for fixed/fiber services)
  └── Integration Procedure: ValidateAddress (calls TMF673 or internal)
  └── IF address valid → proceed
  └── IF invalid → prompt correction

Step 3: Service Qualification
  └── Integration Procedure: CheckServiceQualification
      └── Calls TMF645 (MuleSoft outbound) or internal coverage DB
      └── Returns: list of eligible product IDs

Step 4: Product Selection
  └── DataRaptor Extract: Filter Product2 catalog to eligible products
  └── Display product cards (FlexCard)
  └── User selects product(s) and bundle options

Step 5: Product Configuration
  └── For each selected product:
      └── DataRaptor: Load attribute definitions
      └── Present attribute inputs (e.g., data speed tier, contract term)
      └── Validate attribute constraints

Step 6: Pricing Summary
  └── DataRaptor: Calculate total pricing
      └── One-time: sum of vlocity_cmt__EffectiveBaseOneTimeTotal__c
      └── Recurring: sum of vlocity_cmt__EffectiveBaseRecurringTotal__c
  └── Apply applicable promotions

Step 7: Quote / Order Creation
  └── Integration Procedure: CreateQuoteOrOrder
      └── DataRaptor Load: Create Quote + QuoteLineItem records
      └── OR: Direct Order creation (bypass quote)
  └── Confirmation summary presented to user
```

### OmniScript: Change of Service (Modify Active Subscription)

```
Step 1: Account + Asset Lookup
  └── DataRaptor Extract: Get active Assets for Account

Step 2: Select Service to Modify
  └── Display current services (FlexCard)
  └── User selects service to modify

Step 3: Select Modification Type
  └── Upgrade / Downgrade / Add-On / Suspend / Resume / Cancel

Step 4: Product Selection (for upgrades/downgrades)
  └── DataRaptor: Load eligible replacement products
  └── OrderItem.vlocity_cmt__Action__c = Change

Step 5: Order Creation for Modification
  └── Integration Procedure: CreateChangeOrder
  └── Order created with action = Change on relevant OrderItem

Step 6: Confirmation
  └── Summary of changes, effective date
```

---

## Integration Procedure Patterns for BSS/OSS Integration

### Pattern: Order Decomposition Procedure

**Name convention:** `CP_OrderDecompose` or `IP_OrderDecomposition`

```yaml
Steps:
  1. DataRaptor Extract: Load Order + all OrderItems
  2. Loop: For each OrderItem
     a. Determine provisioning domain (Network vs Billing vs IT)
        - Based on Product2.ProductType or custom field
     b. Create vlocity_cmt__SubOrder__c record
     c. Set routing attributes on sub-order
  3. HTTP Action: Notify order orchestration system (if applicable)
  4. DataRaptor Load: Update Order status to "In Progress"
```

**Input:** OrderId
**Output:** List of created SubOrder IDs, Order status update

### Pattern: Network Provisioning Callout

**Name convention:** `IP_NetworkProvisioningCallout`

```yaml
Steps:
  1. DataRaptor Extract: Load SubOrder + OrderItem + Product details
  2. DataRaptor Transform: Map Salesforce fields to TMF641 Service Order format
  3. HTTP Action (REST): POST to external OSS endpoint
     - Endpoint: Retrieved from Named Credential
     - Body: TMF641-formatted JSON
  4. Parse response: Extract external system order ID
  5. DataRaptor Load: Update SubOrder with external tracking ID
  6. Conditional: If async response expected → set status = "Pending Provisioning"
                  If sync response → set status = "Provisioned"
```

### Pattern: Service Qualification Check

**Name convention:** `IP_ServiceQualification`

```yaml
Steps:
  1. Input: Address fields (street, city, state, zip)
  2. DataRaptor Transform: Map to TMF673 Geographic Address format
  3. HTTP Action: POST to MuleSoft TMF673/TMF645 endpoint
  4. Parse response: Extract eligible product IDs or network coverage flag
  5. Return: List of eligible Product2 IDs
```

### Pattern: Billing System Integration

**Name convention:** `IP_BillingAccountCreate`

```yaml
Steps:
  1. DataRaptor Extract: Load Order + Account + OrderItem pricing details
  2. DataRaptor Transform: Map to billing system payload format
  3. HTTP Action: POST to billing system (BSS) API
  4. Parse response: Extract billing account ID / subscription ID
  5. DataRaptor Load: Update Account.vlocity_cmt__BillingAccountId__c
  6. DataRaptor Load: Update Asset.vlocity_cmt__BillingAccountId__c
```

### Pattern: CDC-Based Notification Delivery

**Name convention:** `IP_SendTMFNotification`

Used by the Notification Framework to deliver TM Forum-aligned outbound notifications.

```yaml
Trigger: CDC Change Event on monitored object (configured in IntegrationProviderDefinition__mdt)

Steps:
  1. Receive CDC event payload
  2. DataRaptor Transform: Map Salesforce change data to TMF resource format
  3. HTTP Action: POST notification to configured external endpoint
  4. Log delivery result
```

**TMF632 Notification Trigger:**
- Object: `AccountContactRelation`
- Trigger events: Association created / Association updated
- Notification type: TMF632 (Party Role Management)

---

## DataRaptor Patterns for Product Catalog and Order Data

### DataRaptor: Extract Product Catalog for CPQ Display

**Type:** Extract
**Purpose:** Load product offerings filtered by eligibility and catalog category

```yaml
Source Object: Product2
Filters:
  - vlocity_cmt__IsOrderable__c = true
  - vlocity_cmt__Status__c = Active
  - [Category filter via vlocity_cmt__CatalogProductRelationship__c]
Output Fields:
  - Id
  - Name
  - Description
  - ProductCode (vlocity_cmt__GlobalKey__c)
  - vlocity_cmt__specificationSubType__c (isBundle)
  - vlocity_cmt__VersionLabel__c
Related Extract: vlocity_cmt__PriceListEntry__c (pricing)
Related Extract: vlocity_cmt__ProductChildItem__c (bundle children)
```

### DataRaptor: Load TMF622 Order Payload

**Type:** Load
**Purpose:** Create Order and OrderItem records from TMF622 inbound payload

```yaml
Primary Object: Order
Fields mapped:
  - Description ← productOrder.description
  - OrderReferenceNumber ← productOrder.externalId
  - vlocity_cmt__RequestedStartDate__c ← productOrder.requestedStartDate
  - vlocity_cmt__OriginatingChannel__c ← productOrder.channel
  - Status = Draft (initial)
Child Object: OrderItem (for each productOrderItem)
Fields mapped:
  - vlocity_cmt__Action__c ← productOrderItem.action
  - Quantity ← productOrderItem.quantity
  - Product2Id ← resolved from productOffering.id (ProductCode lookup)
  - vlocity_cmt__JSONAttribute__c ← productOrderItem.productCharacteristic (JSON)
```

### DataRaptor: Extract Asset Inventory for Account

**Type:** Extract
**Purpose:** Retrieve all active installed products for an account

```yaml
Source Object: Asset
Filters:
  - AccountId = {inputAccountId}
  - vlocity_cmt__ProvisioningStatus__c = Active
Output Fields:
  - Id
  - Name
  - vlocity_cmt__AssetReferenceId__c
  - vlocity_cmt__ProvisioningStatus__c
  - ActivationDate
  - Product2.Name
  - vlocity_cmt__BillingAccountId__r.Name
  - vlocity_cmt__JSONAttribute__c OR AttributeSelectedValues__c
```

### DataRaptor: Transform Attribute JSON (V1 to TMF format)

**Type:** Transform
**Purpose:** Convert `vlocity_cmt__JSONAttribute__c` to TMF622 `productCharacteristic` array format

```yaml
Input: vlocity_cmt__JSONAttribute__c (JSON string from OrderItem)
Transform: Parse JSON → for each attribute:
  - name: attributeuniquecode__c
  - value: value__c
  - valueType: valuedatatype__c
Output: TMF productCharacteristic array
```

---

## Flow Patterns for Subscription Management

### Flow: Suspend Service

**Type:** Auto-launched Flow
**Trigger:** User action on Account service page or incoming request
**Steps:**
1. Find active `Asset` record for the service
2. Set `Asset.vlocity_cmt__ProvisioningStatus__c` = Suspended
3. Create `Order` with `OrderItem.vlocity_cmt__Action__c` = Suspend
4. Integration Procedure: Notify billing system to suspend billing
5. Integration Procedure: Notify OSS to suspend network service

### Flow: Resume Service

**Type:** Auto-launched Flow
**Steps:**
1. Find suspended `Asset` record
2. Set `Asset.vlocity_cmt__ProvisioningStatus__c` = Active
3. Create `Order` with `OrderItem.vlocity_cmt__Action__c` = Resume
4. Integration Procedure: Resume billing
5. Integration Procedure: Restore network service

### Flow: Cancel Service / Termination

**Type:** Auto-launched Flow
**Steps:**
1. Find active `Asset` record
2. Set `Asset.vlocity_cmt__ProvisioningStatus__c` = Terminated
3. Set `Asset.LifecycleEndDate` = effective termination date (requires LifecycleManagement license)
4. Create `Order` with `OrderItem.vlocity_cmt__Action__c` = Remove
5. Integration Procedure: Send cancellation to billing system
6. Integration Procedure: Send termination order to OSS
7. CDC Notification: TMF637 inventory update triggered

---

## CPQ Invocable Actions (for Flow and Agentforce)

These are the core invocable actions available in the CME managed package. They can be called from Flow, Process Builder, Agentforce Actions, or custom Apex.

| Action Class | Description | Key Inputs |
|---|---|---|
| `CpqCartCreateInvocable` (Create Cart / Quote / Order) | Creates a new cart (quote or order) for an account | `accountId`, `objectType` (Quote/Order), `opportunityId` (optional), `name` (optional) |
| `CpqCartGetOffersForPartyInvocable` (Get Offers for Party) | Retrieves eligible offers for a party based on context and search criteria | `catalogcode`, `cartId`, `context`, `isloggedIn`, `priceListId`, `query`, `pagesize` |
| `CpqCartGetOffersForAssetInvocable` (Get Offers for Asset) | Retrieves offers eligible for an existing asset (upgrade/replacement) | `cartId`, `objectType`, `accountId`, `assetIds`, `isDisconnectFlow` |
| `CpqCartReplaceOfferInvocable` (Replace Offer in Cart) | Replaces an existing offer in a cart with a new offer; disconnects existing and adds new | `cartId`, `existingItemId`, `newOfferId` |
| `CpqCartDeleteItemInvocable` (Delete/Disconnect Item from Cart) | Deletes a line item or disconnects an existing asset item from a quote/order | `cartId`, `itemId`, `isDisconnect` |
| `CpqCartSubmitInvocable` (Submit/Place Order) | Places the order (triggers Draft → Activated status transition) | `cartId` |

**Agentforce Integration (Spring '26+):**
- CPQ invocable actions can be invoked as Agentforce Actions
- Requires Agentforce license + Communications Cloud
- Configure via: Setup → Agentforce Studio → Agent Actions → Add CPQ invocable action
- Standard flows (Get Offers for Asset, Replace Offer in Cart, Delete/Disconnect) can also be invoked as Agentforce Flows

**Bulk Async Engine for Cart APIs:**
- Available for high-volume cart operations (ESM multi-site, bulk order processing)
- Uses `startAsyncJob` and `getAsyncJobStatus` method pattern
- Process:
  1. Create a custom API (VIP or Apex REST/Remote Action) as entry point
  2. Call `startAsyncJob` → returns an async process ID
  3. Poll `getAsyncJobStatus` until complete
  4. Do NOT expose the Async Engine via Vlocity Open Interface directly — must go through custom API
- Async process named `Bulk CPQ`; tracked via `AsyncProcess__c` records

---

## Common Integration Patterns from B2B Telco Transformation

### Common Pitfalls (from Integration Patterns and Practices guide)

1. **Neglect of business simplification** — Rebuilding old complexity in a new system wastes effort
2. **Over-customization mimicking legacy** — Excessive Apex coding creates long-term maintenance debt
3. **Siloed team thinking** — Consumer, enterprise, and wholesale teams designing in isolation creates redundancy
4. **Insufficient integration planning** — Poor downstream system understanding causes last-minute delays
5. **Delayed MVP delivery** — Trying to deliver everything at once instead of launching with an MVP

### Standard Application Suite Architecture

Applications in Communications Cloud are built from:
- The CME Managed Package (core CPQ, OM, CLM, OmniStudio SR)
- Core platform components: OmniScripts, Cards, DataMappers, LWCs, Integration Procedures
- Core products: EPC, CPQ, Order Management, Digital Commerce APIs
- Industry-specific data model (communications)

### Enterprise Sales Management (ESM) Automation Pattern

```
Opportunity created (enterprise B2B deal)
    │
    ▼
ESM Quote (enterprise quote with groups)
    ├── OrderGroups / Locations added in bulk
    ├── Subscribers assigned per location
    ├── Products selected from EPC catalog
    │   ├── Products configured with attributes
    │   └── Bundle pricing aggregated
    ├── Bulk discounts applied across all line items
    │
    ▼
Enterprise Order (converted from ESM quote)
    ├── OrderItems created per location × product
    ├── Order decomposition generates FulfilmentRequests
    │   ├── Network sub-orders per provisioning domain
    │   └── Billing sub-orders for BSS setup
    │
    ▼
Orchestration Plan assembled
    ├── OrchestrationItem tasks dispatched
    │   ├── Manual Queue tasks (manual provisioning steps)
    │   └── Automated tasks (Integration Procedure callouts)
    │
    ▼
Assets created per product per location
```

---

## OmniStudio Best Practices (From SFI Best Practices Guide)

### Integration Procedure Best Practices
- Use Integration Procedures for all SOAP and REST callouts (not direct Apex)
- Expose Integration Procedures as REST APIs where external access needed
- Use Named Credentials for all endpoint URLs — never hardcode credentials
- Use custom permission (since Summer '19) to manage IP and DataRaptor access security
- Use `CheckCachedMetadataRecordSecurity = true` if controlling access via OWD (slight performance cost)
- Avoid unnecessary SetValues actions
- Apply consistent naming conventions across all IPs and DRs
- Use conditional blocks to group actions logically

### DataRaptor Best Practices
- In DR Extract: target no more than 3 objects per DataRaptor for performance
- Filter/order only on indexed fields
- Use formula fields in DRs — evaluated client-side in JavaScript, fast for real-time display
- Enable block caching for static or infrequently changed data

### OmniScript Best Practices

**Server Side:**
- Trim JSON requests to reduce payload
- Use Integration Procedures to reduce server round trips
- Perform calls asynchronously where possible
- Use action block where possible
- Avoid long-running transactions
- Avoid chain-on-step on SetValues elements
- Run logic on the server where possible (not client-side formulas when avoidable)

**Client Side:**
- Reduce conditional views, merge fields, and formula evaluations
- Trim JSON responses
- Make sure OmniOut application and JSON definitions are loaded from CMS
- Remove spaces from all UI element names (affects performance and search)
- Reduce number of OmniScript elements
- Enable Time Tracking Flag for performance profiling

### FlexCard Best Practices
- Each auto-compiled LWC file cannot exceed 131,072 characters — break large FlexCards into nested child cards
- Make event listeners unique: use `{recordId}` concatenation to avoid duplicate event handler firing
- Auto-generated LWCs start with `c-cf-**` — never modify them directly
- Use `lightning-datatable` instead of vlocity datatable for large volumes (supports infinite scrolling; note: not supported on mobile)

---

## CPQ Configuration Settings Reference (Performance-Critical Flags)

These CPQ Configuration Setup custom settings control runtime CPQ behavior. Wrong values cause performance issues or crashes.

| Setting | Recommended Value | Impact |
|---|---|---|
| `UOW Mode` | `true` (default since Spring '21) | Enables Unit of Work enhancements — reduces DML and SOQL in Cart-Based API calls |
| `V2 JSON / V2 AttributeModel` | Enabled | Reduces DB storage for attribute values; prefer V2 for new implementations |
| `CachedQueryMode` | `true` | Queries CacheQueryStore instead of DB directly; improves performance |
| `LevelBasedApproach` | `true` | Returns root + first-level children only; loads next level on expand click; critical for bundles with depth > 2 |
| `CacheAPI.SkinnyBasket` | `true` | AssetToBasket returns only key-value pairs; performance gain for Asset-to-Basket transactions |
| `CacheAPI.Trimmode` | `true` | Removes field + attribute metadata from Basket API responses; overrides SkinnyBasket; best for anonymous/logged-in flows |
| `CacheEnabled` | `true` | Enables Platform Cache; required for context rules and Tightest Match service |
| `DeltaPrice` | `true` | Runs pricing only on newly added items (not all items) — critical for carts with >50 items |
| `DeltaValidate` | `true` | Runs configuration rules only on changed items — pair with DeltaPrice |
| `GUID (UseAssetReferenceIdForParentAndRoot)` | `true` (default since Spring '21 for new installs) | Reduces DML in Add-to-Cart and other transactions |
| `Cart-Based APIs: Pricing=false, Validate=false` | Set for CreateCart | Skips pricing/validation at cart creation; improves CreateCart API performance |

**Context and Context Key for performance:**
- Always call APIs with both `context` parameter AND `context key` in the URL
- Step 1: Call Get Offers by Catalog → contextKey returned in response
- Step 2: All subsequent calls use that contextKey + context
- If account, asset, or contract changes: regenerate the context key

---

## Order Management Performance Settings

| Setting | Default | Description |
|---|---|---|
| `OrchestrationMode` | `PlatformEvents (Queueable)` (default since Spring '21 v230) | Controls orchestration logic in OM; Platform Events (Queueable) provides best scalability |
| `OrderDecompositionEnabled` | `true` | Disable (false) if FulfilmentRequests are not used (commercial orders only) — improves Order Submit performance |
| `ProductAttributesBatchProcessorSize` | `500` | Reduce if hitting governor limits during Refresh Platform Cache |
| `PriceBookRefreshBatchSize` | `200` | Reduce if hitting governor limits during Refresh Pricebook batch |
| `ProductHierarchyBatchProcessorSize` | `20` | Reduce if hitting governor limits during Product Hierarchy job |

---

## CLM Performance Patterns

- Use JPEG images instead of PNG in document templates (PNG is significantly larger)
- Use static content in templates rather than dynamic tokens where possible — more tokens = slower generation
- Set `"keepIntermediate": false` in GenerateAndConvert actions — stores only the PDF, discards intermediate document
- CLM update contract operation performance degrades with high product line × contract count combinations
- For DocuSign: use `ContractEnvelopeStatusScheduler` correctly — ensure Recipient Type is preserved as Carbon Copy (known bug in some versions)

---

## Integration (MuleSoft) Performance Pattern

- Use Composite Connector for running multiple queries in a single API call — reduces round trips significantly vs individual queries

---

## B2C Digital Commerce Order Flow

### Standard Digital Commerce API Flow (B2C Self-Service)

```
1. CONSUMER BROWSING (Anonymous or Authenticated)
   ├── Digital Commerce API: Get Catalog (by catalog context)
   │   └── Returns compiled product hierarchy from CachedAPIResponse
   ├── Service Qualification: Address lookup → eligible products filtered
   └── Product cards presented on consumer portal / mobile app

2. CART CREATION
   ├── Create Cart API: cartContextKey required (no JSONResult in Standard DC)
   ├── Anonymous session: no pseudo-account created (unlike Classic DC)
   └── Cart tracks items via CartDocument / CartDocumentItem

3. CART OPERATIONS (Basket APIs)
   ├── Add Item: Configure product attributes; pricing applied from compiled data
   ├── Promotions: Matched from compiledPromotionData in CachedAPIResponse
   ├── Update Item: Change attributes or quantity
   └── Remove Item: Delete from CartDocument

4. CHECKOUT
   ├── Account identification: Guest checkout or authenticated consumer
   ├── Payment capture: Credit card, billing account, or deferred billing
   └── Order submission: placeOrder call → Order + OrderItem records created

5. ORDER FULFILMENT (same as B2B flow from Step 5 onward)
   └── → Decomposition → Provisioning → Asset creation

6. POST-ORDER (B2C specific)
   ├── Order confirmation: Email/SMS to consumer
   ├── Consumer portal: Order status visible via self-service
   └── Abandoned Cart: If consumer leaves without ordering → Cart__c record persists for follow-up
```

### Key Differences: Standard DC APIs vs Classic DC APIs

| Aspect | Classic Digital Commerce | Standard Digital Commerce |
|--------|-------------------------|--------------------------|
| Basket API Response | Cached | Not cached — uses CartDocument |
| Pseudo-orders during configure | Created | NOT created |
| Pseudo-accounts for anonymous | Created | NOT created |
| JSONResult for CreateCart | Supported | NOT supported — only cartContextKey |
| Async bulk CreateCart | Supported | NOT supported |
| Custom hook interface names | Legacy names | New `Cpq*` interface names required |
| Performance | Limited by Apex governor limits | Processed at Java layer — faster |
| Compile data source | CPQ EPC compile | DC catalog compile (separate job) |

### Digital Commerce API: Compile Data Job

```
1. Ensure Standard DC APIs are enabled
2. Run: Vlocity CMT Administration → Cache Catalog Product Definitions → Start
         Select Catalog(s), Start Date, End Date → Ok
3. Verify compile data created:
   SELECT Id, Name, CacheKey__c, Type__c FROM CachedAPIResponse__c
   WHERE Type__c = 'cartCompiledOfferHierarchy' LIMIT 1
4. Each compile creates a new ConfigurationSnapshot__c
   → Runtime always picks latest active snapshot for the current date range
   → Purge older snapshots to free data storage
```

**Deep clean script (dev only):**
```apex
delete [SELECT Id FROM vlocity_digital__CachedAPIResponse__c];
delete [SELECT Id FROM vlocity_digital__AsyncProcess__c];
delete [SELECT id FROM vlocity_digital__ConfigurationSnapshot__c];
// Reset ConfigurationSnapshotLock and clear all cache
vlocity_digital.TelcoAdminConsoleController controller = new vlocity_digital.TelcoAdminConsoleController();
controller.setParameters('{"methodName":"clearAllCache"}');
controller.invokeMethod();
```

---

## B2C Connected Assets Automation Pattern

### Actionable Event Orchestration Flow

```
1. ASSET TELEMATICS EVENT GENERATED
   └── External telematics provider detects anomaly (temperature spike, battery failure, usage threshold)

2. EVENT INGEST INTO SALESFORCE (two options)
   Option A: Platform Event
     └── Publish: Actionable Orchestration Source Event
         Payload: { assetUniqueIdentifier, eventType, eventSubtype, eventCategory, eventData[] }
   Option B: Business API
     └── POST: Orchestration Inbound Events API
         Payload: { sourceSystemId, eventType, [eventSubtype], [eventCategory], [contextData] }

3. FILTER AND MATCH DECISION TABLE
   └── Matches event by type + subtype + category → identifies:
       ├── Context Definition (structure of event payload)
       ├── Context Mapping (maps event data to execution variables)
       └── Execution Procedure (expression set or flow to run)

4. CONTEXT DEFINITION LOOKUP
   └── Resolves event payload attributes to named variables
       e.g., assetUniqueIdentifier → Asset lookup; faultCode → diagnostic context

5. EXECUTION PROCEDURE
   Option A: Expression Set (simple record actions)
     └── Create record alert, asset milestone, or case directly
   Option B: Salesforce Flow (complex workflows)
     └── Evaluate existing conditions (is asset already serviced?) → conditional record creation
         → Notify customer → Schedule service appointment → Create work order

6. RESPONSE EVENT
   └── Publish: Actionable Orchestration Response Event
       Contains: executed action details, processing status, error description (if failed)
```

### Connected Asset Event Types (Telecom Use Cases)

| Event Type | Subtype Examples | Typical Actions |
|---|---|---|
| PerformanceAndDiagnostic | BatteryLow, SensorFault, HighTemperature | Create Record Alert, notify customer |
| UsageThreshold | MaintenanceAlert, DataCapApproaching | Create Asset Milestone, send notification |
| NetworkConnectivity | ConnectionLost, SignalDegraded | Create Case (Trouble Ticket), notify NOC |
| ServiceStatus | DeviceOffline, CPEUnresponsive | Create Work Order, schedule technician |

### Key Objects in Connected Assets Flow

| Object | Role in Flow |
|--------|-------------|
| Asset | Source record linked to connected device; must have `Connected Services Active = true` |
| Actionable Event Orchestration | Configuration record defining event type → execution procedure mapping |
| Context Definition | Defines payload structure for a given event type |
| Filter and Match Decision Table | Routes events to correct orchestration |
| Record Alert | Created when event triggers a customer-visible notification |
| Asset Milestone | Created to track key points in asset lifecycle |
| Work Order | Created for field service response to critical events |
| Case | Created for service assurance issues requiring CSR resolution |

---

## B2C Household and Family Plan Automation Patterns

### Pattern: Multi-Line Family Plan Enrollment

**Trigger:** Consumer enrolls additional household member in a family plan
**Flow:**
1. Agent or consumer self-service selects household account
2. `Household__c` record identified (or created) for consumer address
3. New `PartyRelationship__c` created linking new member to household
4. CPQ OmniScript run for new household member — products filtered by existing household plan
5. Quote/Order created with `OrderItem.vlocity_cmt__Action__c` = Add
6. Order decomposition creates provisioning sub-orders for new SIM or line
7. `Asset` created and linked to household billing account

### Pattern: Abandoned Cart Follow-Up (B2C Marketing Re-engagement)

**Trigger:** Consumer starts cart but does not complete purchase
**Flow:**
1. Cart abandoned — `Cart__c` record persists with `CartItem__c` child records
2. Marketing automation (Marketing Cloud or Salesforce Campaigns) reads `Cart__c` records
3. Re-engagement communication sent (email, push notification, SMS)
4. Consumer returns via tracked link → cart resumed with same items
5. If consumer completes purchase → `Cart__c` linked to resulting Order

### Pattern: Next-Best-Offer Recommendation (B2C Upsell/Cross-Sell)

**Trigger:** CSR opens Account 360 view or consumer visits self-service portal
**Flow:**
1. `AccountOffer__c` records queried for account — pre-computed offers
2. Vlocity Intelligence Machine (`VqMachine__c`) resources queried for recommendations
3. Promotion eligibility evaluated — `vlocity_cmt__Promotion__c` with `AccountDiscount__c`
4. Recommended offers displayed on FlexCard (Account 360) or consumer portal
5. Consumer/agent selects offer → CPQ cart created with pre-selected product

---

## B2C-Specific Integration Patterns

### Pattern: Digital Commerce to Payment Gateway Integration

```yaml
Steps:
  1. Consumer completes cart and proceeds to checkout
  2. Integration Procedure: PaymentCapture
     a. Collect payment method details (credit card, PayPal, etc.)
     b. HTTP Action: POST to payment gateway API
     c. Parse response: Extract payment confirmation / transaction ID
  3. On payment success:
     a. DataRaptor Load: Create Order record
     b. Set Order.Status = Draft; trigger placeOrder
  4. On payment failure:
     a. Return error to consumer portal
     b. Cart remains open for retry
```

### Pattern: Billing System Statement Sync (B2C 360° View)

```yaml
Steps:
  1. Scheduled Integration Procedure or Batch Apex: SyncBillingStatements
  2. HTTP Action: GET billing statements from BSS API
  3. DataRaptor Load: Upsert Statement__c records per Account
  4. DataRaptor Load: Upsert StatementLineItem__c records per Statement
  5. Account Balance Snapshot: Create AccountBalance__c record
  6. FlexCard: Displays latest billing summary in Consumer 360 view
```

### Pattern: Consumer Self-Service Order Status (Portal Integration)

```yaml
Steps:
  1. Consumer authenticates on Experience Cloud site
  2. Integration Procedure: GetConsumerOrders
     a. DataRaptor Extract: Load Orders + OrderItems for AccountId
     b. Filter: Status != Completed → show in-progress orders
  3. Return: Order status, expected completion date, sub-order progress
  4. FlexCard: Order Status Card on consumer portal
  5. CDC Notification: Order status changes trigger real-time portal update
     (via Streaming API or Experience Cloud component refresh)
```
