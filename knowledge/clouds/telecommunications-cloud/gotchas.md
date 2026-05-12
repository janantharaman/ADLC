---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); CME Managed Package Dev Guide (2025.12.04); SFI Best Practices; Standard Cart APIs Playbook; Integration Patterns and Practices (2025.12.10); B2B Telecommunications documents ingested 2026-05-10; B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: gotchas
last-updated: 2026-05-10
---

# Communications Cloud — Gotchas, Limitations, and Known Issues

## API and Integration Gotchas

### 1. MuleSoft Gateway Deprecation (Winter '27)
**Issue:** The MuleSoft Gateway option for inbound TM Forum APIs will be fully deprecated starting Winter '27. After that release, only Direct Access (Connect/Apex REST endpoints) is supported.

**Impact:** Any BSS/OSS system currently routing inbound API calls through MuleSoft endpoints to Salesforce must be re-pointed to direct Connect/Apex REST endpoints by Winter '27.

**Action required:** Audit all inbound integrations and update endpoint configurations before Winter '27 upgrade.

---

### 2. TMF622 v5 Tax Calculation Blocks Order Activation
**Issue:** When RLM (Revenue Lifecycle Management) or Revenue Cloud tax calculation is enabled, the order activation flow breaks.

**Specifics:**
- "Tax calculation for the order is an asynchronous process. The order cannot be activated until the tax calculation is complete."
- "Submitting an order for provisioning when tax calculation is enabled can only be done as a PATCH operation. However, this cannot be implemented, as RLM APIs do not support the PATCH operation."

**Impact:** If RLM tax is configured, the standard TMF622 v5 POST + activate flow does not work end-to-end without custom workarounds.

**Action required:** Confirm tax calculation requirements before choosing TMF622 v5. If tax is required with RLM, a custom async polling or trigger-based activation mechanism is needed.

---

### 3. TMF648 Synchronous SLA Unachievable
**Issue:** "If 648 POST is expected as a synchronous call — API time limit/SLA of 3s is not achievable."

**Impact:** External systems expecting sub-3-second synchronous quote creation via TMF648 POST will time out. TMF648 is inherently slower due to CPQ pricing calculations, bundle resolution, and opportunity creation.

**Action required:** Design integration for asynchronous quote creation with callback or polling pattern. Do not promise 3-second SLA for quote creation.

---

### 4. TMF679 Only Uses IDs — Names Are Ignored
**Issue:** "Only Id values are considered. Details such as product name, category name, and related party name are ignored" for qualification processing.

**Impact:** Even if a well-formed TMF679 payload includes `productOffering.name` or `relatedParty.name`, these are silently discarded. Only the `id` field is used for lookup.

**Action required:** Ensure sending systems provide correct Salesforce IDs in qualification payloads. Do not rely on name-based lookup.

---

### 5. TMF622 v4 — Products Must Pre-Exist in Salesforce
**Issue:** "Products of input payload should be present in Salesforce" — TMF622 does not create products on the fly.

**Impact:** If an external ordering system sends a product order with a product ID that doesn't exist in the Salesforce product catalog, the order will fail.

**Action required:** Maintain product catalog synchronization (use TMF620 or a scheduled ETL) before accepting orders via TMF622.

---

### 6. Region Availability is Limited (Spring '26)
**Issue:** Direct Access Industry APIs are only available in US East and EU regions as of Spring '26.

**Impact:** Customers in APAC, LATAM, or other regions cannot use Direct Access until additional data centers are added.

**Action required:** Confirm customer data residency requirements and verify regional availability before committing to Direct Access architecture.

---

## Industries CPQ Gotchas

### 7. Opportunity is Hardcoded as Mandatory for TMF648
**Issue:** "By default, opportunity is mandatory to create a quote." An Opportunity is auto-created with the hardcoded name `TMF Opportunity_%TIMESTAMP%` when a quote is created via the TMF648 API.

**Impact:** The Salesforce org will accumulate auto-generated Opportunity records with timestamp names. Opportunity stage progression, forecasting, and reporting may be affected.

**Action required:** Design Opportunity stage and ownership rules to handle auto-generated TMF opportunities. Consider a cleanup strategy or custom override if Opportunity creation is undesirable.

---

### 8. Quote Name is Auto-Generated (TMF648)
**Issue:** Quote name is hardcoded as `TMF Quote_%TIMESTAMP%` for all quotes created via the TMF648 API.

**Impact:** Quote names will not be human-readable unless customized. Searching for specific quotes by name will be difficult.

**Action required:** If meaningful quote names are required, implement a custom naming convention via post-processing trigger or Integration Procedure override.

---

### 9. QuoteLineItem Quantity Fixed at 1 (TMF648)
**Issue:** QuoteLineItem quantity is fixed at 1 when created via TMF648 API. The API does not support quantity > 1.

**Impact:** Multi-quantity line items (e.g., 5 handsets) cannot be represented as a single line item via TMF648 — each unit requires a separate line item.

**Action required:** Sending systems must split multi-quantity items into separate `quoteItem` entries in the TMF648 payload.

---

### 10. TMF648 Supports "Add" Action Only
**Issue:** The TMF648 API supports only the "add" action for QuoteLineItem. Change, Remove, Suspend, and Resume actions are not supported.

**Impact:** TMF648 cannot be used for modification quotes (change-of-service scenarios). Only new service addition is supported.

**Action required:** For change-of-service quotes, use a different mechanism (OmniScript-based CPQ flow, or direct API on Order object).

---

### 11. Attribute-Based Pricing Not Supported in TMF620
**Issue:** "Attribute-based pricing is not handled by TMF620 specification. It requires custom extensions."

**Impact:** Products with prices that vary based on attribute values (e.g., different prices for 100Mbps vs 1Gbps fiber) cannot be priced via standard TMF620 — custom extension is required.

**Action required:** Implement a custom pricing extension (Apex interface or Integration Procedure) for attribute-based pricing scenarios.

---

### 12. PriceList Must Be Pre-Configured in Custom Metadata
**Issue:** The price list for TMF API operations must be configured in `VlocityIntegrationSetting__mdt.TMForumPriceList`. If this is not set, all price-related operations fail.

**Impact:** Missing custom metadata configuration causes silent failures in pricing lookups for quotes and orders.

**Action required:** Verify `VlocityIntegrationSetting__mdt` is deployed with the correct `TMForumPriceList` value before going live. Include this in deployment verification checklist.

---

### 13. Default Attribute Category Must Exist
**Issue:** TMF620 requires a default `vlocity_cmt__AttributeCategory__c` to be pre-created and configured. If missing, attribute operations fail.

**Action required:** Create a default attribute category record early in the implementation. Reference it in `VlocityIntegrationSetting__mdt`.

---

## Order Management Gotchas

### 14. Order Decomposition Requires Correct Product Routing Configuration
**Issue:** Order decomposition logic must be configured to route order items to the correct provisioning domain. Misconfiguration sends all items to a single sub-order.

**Impact:** All products may be routed to the wrong fulfillment system, causing provisioning failures.

**Action required:** Thoroughly test order decomposition with all product types before go-live. Use test orders covering all provisioning domains.

---

### 15. vlocity_cmt__JSONAttribute__c vs AttributeSelectedValues__c (V1 vs V2)
**Issue:** Two different attribute storage models exist. V1 uses `vlocity_cmt__JSONAttribute__c` (a flat JSON blob on OrderItem/Asset). V2 uses `AttributeSelectedValues__c`. TMF622 v4 maps to V1; the data model evolves toward V2.

**Impact:** Reports, DataRaptors, and API mappings must target the correct attribute field depending on the org's attribute model version. Mixed environments cause data discrepancies.

**Action required:** Determine which attribute model the org is using early in the engagement. Standardize on V2 for new implementations.

---

### 16. Order Status Auto-Transition via placeOrder
**Issue:** When an order is placed via the TMF622 API `placeOrder` call, the order automatically transitions from Draft to Activated status. There is no intermediate approval step.

**Impact:** If there are business rules requiring order approval before activation, the standard API flow bypasses them.

**Action required:** Implement order approval via custom Flow or Process Builder triggered before the placeOrder call, or customize the order activation logic.

---

## Agreement Management Gotchas

### 17. AgreementSpecification Name Must Be Unique
**Issue:** The `name` field in `AgreementSpecification` (DocumentTemplate) is unique and cannot be reused.

**Impact:** If duplicate template names are attempted, the POST will fail.

**Action required:** Implement a naming convention for agreement templates. Consider including version numbers in template names.

---

### 18. DocGen License Required for Agreement Management
**Issue:** TMF651 Agreement Management requires DocGen OrgPerm + DocGenDesigner addon license. Without these, DocumentTemplate creation and agreement generation will fail.

**Impact:** Customers who purchase Communications Cloud but not DocGen cannot use the Agreement Management TM Forum API.

**Action required:** Confirm DocGen license is in scope before implementing TMF651.

---

### 19. TMF651 POST Limited to Single RelatedParty
**Issue:** AgreementSpecification POST is limited to a single `relatedParty` entry due to Salesforce license constraints.

**Action required:** If multiple related parties are needed on an agreement, use a PATCH operation after creation.

---

## Notification Framework Gotchas

### 20. CDC Update Events Only for Field-Level Tracking
**Issue:** The Integration Provider Definition Mapping for field-level CDC configuration is "applicable only for the update change event type." Insert/Delete/Undelete events do not support field-level filtering.

**Impact:** For insert notifications, all fields are included — field-level filtering does not apply.

**Action required:** Design notification filtering logic appropriately for each change event type.

---

### 21. AccountContactRelation Is the Only Supported Related Party Trigger (Spring '26)
**Issue:** As of Spring '26, the only supported related object notification is for `AccountContactRelation` changes linked to Contacts, triggering TMF632 notifications.

**Impact:** Other relationship changes (e.g., AccountAccount relationships, or custom junction objects) do not trigger TM Forum notifications natively.

**Action required:** Use custom Integration Procedures for notification triggers not covered by native framework.

---

## Document Management Gotchas

### 22. TMF667 POST Supports URL Upload Only
**Issue:** "Only URL upload is supported in POST method" for TMF667 Document Management. Binary file uploads are not supported via the TMF667 API.

**Impact:** External systems cannot directly upload file content via TMF667 — they must provide a URL to an externally accessible file, which Salesforce then links.

**Action required:** External systems must host files at accessible URLs before calling TMF667. Consider using Salesforce Files (ContentDocument) directly for file uploads outside the TM Forum API.

---

### 23. TMF667 documentType Auto-Populates as LINK
**Issue:** When using URL upload, `documentType` is automatically set to `LINK` and cannot be overridden.

**Action required:** If specific document type metadata is required, use a post-processing step to update the ContentVersion record.

---

## OmniStudio Gotchas

### 24. IDX Workbench Required for Datapack Migration (Not Salesforce DX)
**Issue:** TM Forum datapack content (TMF API static resources) must be imported via IDX Workbench, not standard Salesforce DX deployment. IDX Workbench handles Vlocity-specific metadata types.

**Impact:** Standard `sf project deploy` will not deploy datapack content correctly.

**Action required:** Maintain IDX Workbench in the development toolchain. Ensure Salesforce API 58.0+ is configured.

---

### 25. OmniStudio Metadata Deployment vs. IDX Workbench
**Issue:** Modern OmniStudio components (post-Vlocity migration) deploy via standard Salesforce DX. Legacy Vlocity components may still require IDX Workbench. The two deployment methods are not interchangeable.

**Impact:** Mixed-vintage environments with both legacy Vlocity datapacks and new OmniStudio metadata require both deployment tools.

**Action required:** Determine which OmniStudio deployment model is in use at the customer org. For new implementations, use standard Salesforce DX OmniStudio deployment.

---

## Feature Activation Requirements

| Feature | Activation Requirement |
|---------|----------------------|
| TM Forum Industry APIs (Direct Access) | Enable access in Setup; configure Connected App for OAuth 2.0 |
| MuleSoft Direct Integrations | Purchase MuleSoft license; accept consent terms; deploy assets from Anypoint Exchange |
| Notification Framework | Included in base SKU; configure `IntegrationProviderDefinition__mdt` records |
| Agreement Management (TMF651) | Enable DocGen OrgPerm + DocGenDesigner addon license |
| Asset LifecycleEndDate (TMF637) | Requires LifecycleManagement license |
| TMF622 v5 ordering | Salesforce API 62.0+ environment |
| CDC / Notification Framework | Enable Change Data Capture in Setup |
| OmniStudio | Included in Communications Cloud; activate in Setup |
| IDX Workbench | External tool — download and configure separately |
| TMFOpenAPIs Static Resource | Import via IDX Workbench from Setup → Static Resources |

---

## Known Ordering Constraints (What Must Be Done First)

```
1. Communications Cloud package installed (from AppExchange)
   ↓
2. OmniStudio activated
   ↓
3. Default Attribute Category created
   ↓
4. Price List created + VlocityIntegrationSetting__mdt configured
   ↓
5. Product Catalog built (Catalogs → Categories → Products → Pricing)
   ↓
6. TMFOpenAPIs datapacks imported (IDX Workbench, API 58.0+)
   ↓
7. Connected App created for OAuth 2.0 (for Industry API access)
   ↓
8. Permission Sets assigned to users
   ↓
9. CPQ OmniScripts deployed and configured
   ↓
10. Order Decomposition rules configured
    ↓
11. Integration Procedures for BSS/OSS callouts deployed
    ↓
12. Notification Framework configured (if needed)
    ↓
13. Go-live
```

Skipping or reordering steps 3, 4, or 6 will cause failures in TMF API operations.

---

## CPQ / EPC Gotchas

### 26. Standard Cart APIs Require EPC Compile Data — No Auto-Regeneration
**Issue:** Standard Cart-Based APIs rely on pre-compiled EPC data stored in `CachedAPIResponse__c`. This compile data is **not automatically regenerated** when product catalog changes are made.

**Impact:** Product changes, pricing updates, rule modifications, or promotion updates go live to the Standard Cart APIs only after the next EPC Compile Data job runs. Until then, the APIs serve stale data.

**Action required:** Include EPC Compile Data generation in all deployment runbooks for product catalog changes. Build a post-deployment job step. In the meantime, runtime APIs return data from the last active `ConfigurationSnapshot__c`.

---

### 27. Managed Platform Cache Is Not Cleared by Compile Data Job — Must Be Done First
**Issue:** The EPC Compile Data job generates from **platform cache**, not directly from the database. If platform cache holds stale data, the compile job regenerates stale compiled data.

**Impact:** A compile job run without clearing platform cache first will perpetuate stale data in the compiled output.

**Action required:** Always clear Managed Platform Cache before running the EPC Compile Data job:
```
1. Vlocity CMT Administration → Maintenance Jobs → CLEAR MANAGED PLATFORM CACHE → Start
2. Vlocity CMT Administration → EPC Jobs → GENERATE COMPILE DATA → Start → Select pricelist → Start
```

---

### 28. Product Hierarchy Changes Require Two-Step Refresh (Hierarchy Job + Compile)
**Issue:** Product hierarchy changes (bundle structure, child items, parent-child relationships) are stored in the `DataStore` object — not read directly from `ProductChildItem__c` at runtime. Compile data is generated from `DataStore`, not live product tables.

**Impact:** Adding/removing bundle children or restructuring hierarchy has no effect on Standard Cart APIs until a Product Hierarchy Maintenance job AND a Compile Data job both complete.

**Action required:**
```
1. Vlocity CMT Administration → Maintenance Jobs → PRODUCT HIERARCHY MAINTENANCE → Start
2. Vlocity CMT Administration → EPC Jobs → GENERATE COMPILE DATA → Start → Select pricelist → Start
```

---

### 29. EPC Compile Data Accumulates ConfigurationSnapshots — Causes Data Storage Issues
**Issue:** Every EPC compile run creates a new `ConfigurationSnapshot__c` record. Old snapshots are not automatically purged.

**Impact:** In active orgs with frequent product updates, the number of ConfigurationSnapshot records can grow into thousands, consuming significant data storage and slowing queries against the table.

**Action required:** Manually purge old snapshots regularly. Only the latest active snapshot is used at runtime; all others are safe to delete.

---

### 30. DocuSign Recipient Type Gets Overwritten to "Unknown" by Scheduler Bug
**Issue:** The `ContractEnvelopeStatusScheduler` batch job rewrites Carbon Copy recipients as "Unknown" recipient type. This also occurs when a signer designates a new signer using DocuSign.

**Impact:** Carbon Copy contracts are not sent to intended recipients. Contract execution fails silently for CC recipients.

**Action required:** Verify the CME managed package version includes the fix for this issue. Check that Recipient Type remains `Carbon Copy` after the scheduler runs. Apply patch if not already in place.

---

### 31. Orchestration Items Remain Pending Indefinitely if Start Milestone Fails
**Issue:** If the Start orchestration milestone remains in Pending state (e.g., due to a failed downstream order submission), all subsequent orchestration items in the plan also remain Pending indefinitely.

**Impact:** Order appears stalled with no error. Manual intervention required to identify the blocked milestone and restart the plan.

**Action required:** Implement monitoring on `OrchestrationItem__c` records with Status = Pending for > N hours. Build a Fallout Queue process to detect and surface stuck orchestration plans.

---

### 32. Order Sent to Fallout Queue on CannotCreateTransactionException
**Issue:** When Order Management cannot obtain a database transaction due to concurrency issues (`CannotCreateTransactionException`), orders can be moved to the Fallout queue, requiring manual intervention.

**Impact:** Order processing stalls. Customer impact until manual recovery.

**Action required:** Confirm the running CME package version handles this gracefully by automatically retrying instead of failing to Fallout. Check patch notes for this fix (addressed in recent CME patch releases).

---

### 33. kafka2sfdc Pod Restarts on ConcurrentPerOrgLongTxn (OM+ Environments)
**Issue:** In Order Management Plus environments, the kafka2sfdc pod restarts when it receives a `ConcurrentPerOrgLongTxn` error with HTTP 500. This causes notification delays and false monitoring alerts.

**Impact:** Delayed order status notifications to Salesforce; cloud engineering alert fatigue.

**Action required:** This is a transient exception. Verify the installed CME version implements retry logic instead of pod restart. This issue is patched in recent CME releases.

---

### 34. Vlocity Action Toolbar Does Not Auto-Refresh on Order Status Change
**Issue:** The Vlocity Action Toolbar on the Order Details page did not historically refresh when using the progress bar to change order status. Related action buttons would not display until a manual browser refresh.

**Impact:** User experience friction; agents may think the status change failed.

**Action required:** Confirmed fixed in recent CME patch releases. Verify that the installed package version includes the auto-refresh fix before going live.

---

### 35. FlexCard Auto-Compiled LWC Has 131,072-Character File Limit
**Issue:** OmniStudio auto-compiles a Lightning Web Component (LWC) every time a FlexCard is activated. Each file within the auto-generated LWC component folder cannot exceed 131,072 characters.

**Impact:** Complex FlexCards with many elements or nested structures can exceed this limit and fail to compile (activation will fail).

**Action required:** Split large FlexCards into multiple smaller child FlexCards. Custom LWCs embedded in FlexCards also increase auto-generated HTML significantly — minimize custom LWC usage within FlexCards.

---

### 36. DeltaPrice and DeltaValidate Must Both Be True for Large Carts
**Issue:** `DeltaPrice = false` re-runs pricing on ALL items in the cart on every change. `DeltaValidate = false` re-runs validation rules on ALL items. For carts with more than 50 items, this causes significant performance degradation and potential governor limit breaches.

**Impact:** Slow cart loads, CPU limit errors, user-facing timeouts on quote updates.

**Action required:** Enable both `DeltaPrice = true` AND `DeltaValidate = true` in CPQ Configuration Setup. Both must be enabled together — enabling only one provides partial benefit.

---

### 37. CacheAPI.Trimmode Overrides CacheAPI.SkinnyBasket
**Issue:** If both `CacheAPI.Trimmode` and `CacheAPI.SkinnyBasket` are configured, `Trimmode` takes precedence and `SkinnyBasket` is effectively ignored.

**Impact:** Unexpected behavior if developers configure both settings expecting additive effect.

**Action required:** Use `Trimmode = true` as the primary performance flag. No need to set SkinnyBasket when Trimmode is enabled.

---

### 38. Standard CPQ (Cart-Based APIs) Cannot Be Enabled Without Compile Data
**Issue:** If Standard Cart-Based APIs are enabled but no compile data has been generated yet, all cart API calls will fail silently or return empty results.

**Impact:** Go-live blocker if teams enable Standard Cart APIs before generating compile data.

**Action required:** Generate compile data immediately after enabling Standard Cart APIs. Verify by querying:
```soql
SELECT Id, Name, CacheKey__c, Type__c FROM CachedAPIResponse__c WHERE Type__c = 'cartCompiledOfferHierarchy' LIMIT 1
```

---

### 39. DataRaptor Extract Must Not Target More Than 3 Objects
**Issue:** DataRaptor Extract performance degrades significantly when targeting more than 3 source objects in a single DataRaptor.

**Impact:** Slow OmniScript step loading; potential timeout on complex DRs.

**Action required:** Split complex DataRaptors that join more than 3 objects into chained DataRaptors or Integration Procedure steps. Filter and order only on indexed fields.

---

### 40. OmniStudio Version History Accumulates — Storage Risk
**Issue:** OmniStudio and Integration Procedure versions are not automatically pruned. Each version is stored as a separate record.

**Impact:** In active development environments, version records can consume significant data storage. Excessive versions can also slow org operations.

**Action required:** Maintain a maximum of 3 active versions per OmniScript and Integration Procedure. Periodically audit and delete obsolete versions via the OmniStudio admin console.

---

### 41. Pre-Fall '18 Orgs Cannot Use Product Selling Period Dates Without Upgrade
**Issue:** Product selling period dates (SellingStartDate, SellingEndDate on Product2) are only available if the org has been upgraded to Fall '18 or later. Orgs on older packages must upgrade before using this feature.

**Impact:** Product catalog time-based availability features unavailable in old installations.

**Action required:** Confirm org is on Fall '18 or later before implementing selling period date–based eligibility logic.

---

### 42. Vlocity Action Toolbar and FlexCards Don't Auto-Refresh After Field Updates (Some Versions)
**Issue:** In some CME versions, the Vlocity Action Toolbar and FlexCards did not automatically refresh after record field updates. After adding an action to a FlexCard, the FlexCard also failed to refresh.

**Impact:** Users see stale data until manual page refresh.

**Action required:** Verify the CME patch version includes the auto-refresh fix. This is addressed in recent patch releases but may affect older installations.

---

## B2C Digital Commerce Gotchas

### 43. Standard DC APIs Break Existing Pseudo-Order Custom Code
**Issue:** Standard Digital Commerce APIs do NOT create pseudo-orders, pseudo-accounts, pseudo-order items, order price adjustments, order applied promotions, or order applied promotion items during basket operations. Any custom Apex triggers, Integration Procedures, or hooks that were built expecting these pseudo-objects will silently fail.

**Impact:** Custom pricing hooks, triggers monitoring pseudo-order creation, and Integration Procedures that reference these objects stop working when Standard DC APIs are enabled.

**Action required:** Audit all custom implementations before enabling Standard DC APIs:
1. Search for any Apex triggers on `Order`, `OrderItem`, `OrderAppliedPromotion__c`, `OrderAppliedPromotionItem__c`, `OrderPriceAdjustment__c` that run in basket/configure contexts
2. Search all Integration Procedures and custom hooks for references to pseudo-order objects
3. Refactor to use `CartDocument` and `CartDocumentItem` instead
4. Rename custom interface implementations to new Standard DC interface names (`CpqAppHandler`, `CpqContextRule`, etc.)

---

### 44. Standard DC APIs: Create Cart Only Works with cartContextKey
**Issue:** In Standard Digital Commerce APIs, the Create Cart API only supports cart creation via `cartContextKey`. Cart creation by passing `JSONResult` is NOT supported. Also, async bulk `CreateCart` is not supported.

**Impact:** Any existing Classic DC integration that creates carts by passing JSONResult directly will break.

**Action required:** Update all integrations creating Digital Commerce carts to use the `cartContextKey` pattern. Multiple orders can be created by passing multiple `CartContextKey` values in a single call, subject to governor limits.

---

### 45. Digital Commerce Compile Data Is a Separate Job from CPQ EPC Compile Data
**Issue:** Digital Commerce APIs use their own compiled catalog data (`Cache Catalog Product Definitions` job), separate from the CPQ EPC compile data job. Running only the CPQ EPC compile does NOT update Digital Commerce compiled data.

**Impact:** Product catalog changes applied and re-compiled for CPQ may still serve stale data to the Digital Commerce channel until the DC compile job also runs.

**Action required:** After any product catalog change, run BOTH:
1. Vlocity CMT Administration → EPC Jobs → GENERATE COMPILE DATA (for CPQ)
2. Vlocity CMT Administration → Cache Catalog Product Definitions (for Digital Commerce)
Include both jobs in all deployment runbooks.

---

### 46. "Lift and Shift" Programs for B2C Are a Known Red Account Pattern
**Issue:** B2C Communications Cloud programs that target replicating legacy functionality "like for like" — without product simplification, process transformation, or catalog rationalization — consistently become over-customized and go red.

**Impact:** Excessive customization of platform behavior, CPQ rules, and integration logic creates long-term technical debt and delays. Programs also frequently miss the intrinsic value of the platform.

**Action required:** During discovery, confirm the customer's objective includes product simplification and transformation, not just a lift-and-shift. If the scope explicitly excludes simplification, flag this as a delivery risk. Key indicators of lift-and-shift scope:
- Customer wants parity to old system rather than best-practice implementation
- No product rationalization planned
- Existing complex bundle hierarchy (depth > 3) being replicated as-is

---

### 47. Digital Commerce API Design Constraints Are a NO FLY ZONE
**Issue:** Digital Commerce API performance degrades significantly when approaching or exceeding design constraints. The exact thresholds are not published publicly, but known risk areas include:
- Product hierarchy depth > 3 levels
- Maximum child items per product > 10
- Line items per cart/quote > 20 (complexity threshold)
- Basket creation response time requirements < 5 seconds in all scenarios (often not achievable at high complexity)

**Impact:** Implementations that push beyond DC design constraints experience performance degradation, timeouts, and unpredictable behavior that cannot be resolved through configuration alone.

**Action required:** Conduct a thorough design review before committing to Digital Commerce API scope. If the design is near or exceeds constraints, escalate to Salesforce product team before committing to SLAs.

---

### 48. Person Account Model Cannot Be Reversed After Enabling
**Issue:** Enabling Person Accounts in a Salesforce org is irreversible. Person Accounts merge the Contact object into the Account object for individual records. This affects data model, reports, page layouts, and API behavior across the entire org.

**Impact:** Once enabled, all existing integrations, triggers, flows, and API calls that depend on the Account + Contact separation must be reviewed and potentially updated.

**Action required:** Before recommending Person Accounts for B2C:
1. Confirm the customer org does not already have a mixed B2B/B2C use case that requires both Person Accounts and standard Account + Contact pairs
2. Assess impact on existing Apex, flows, and integrations
3. Confirm with customer's architecture team — this is a one-way door

---

### 49. Connected Assets: Usage-Based Entitlement Limit (300 Orchestrations/Month)
**Issue:** Connected Assets Actionable Event Orchestration operates on a usage-based licensing model. Only assets with `Connected Services Active = true` are included. The standard entitlement is 300 orchestrations per month (split between expression-set and flow-based orchestrations).

**Impact:** High-volume telematics implementations that generate many events per asset may exhaust the monthly entitlement limit quickly, causing orchestration failures for events that exceed the cap.

**Action required:** At discovery, estimate expected event volume per month across all connected assets. If projected volume exceeds 300 orchestrations/month, discuss entitlement expansion with Salesforce. Also, filter events aggressively — only act on critical events requiring immediate action; not all sensor data events need to trigger orchestration.

---

### 50. TMF Inbound APIs: Availability Split Between Managed Package and Core Platform
**Issue:** Some TMF APIs are only available on the Communications Cloud Managed Package, while others are available on both Managed Package and Core Salesforce Platform. This affects pricing, licensing, and deployment strategy.

**Key availability details:**
- **Managed Package only:** TMF621 v4, TMF622 v4, TMF648, TMF651, TMF667, TMF671
- **Managed Package AND Core Platform:** TMF620, TMF621 v5, TMF622 v5, TMF629, TMF637, TMF679

**Impact:** Customers targeting a migration from Managed Package to Core Platform will lose access to some TM Forum APIs during/after migration. TMF648 (Quote Management) and TMF651 (Agreement Management) notably require Managed Package and have no Core Platform equivalent as of Spring '26.

**Action required:** Confirm target deployment model (Managed Package vs Core Platform) early in discovery. Design integration architecture around the API availability constraints for the chosen model. Review the official Open API Licensing sheet for exact entitlement details.

---

### 51. EPC Compile Data and DC Compile Data Do Not Automatically Recompile After Org Deployment
**Issue:** Deploying metadata changes (product catalog updates, rule changes, promotion updates) to production does not automatically trigger a recompile of either EPC or Digital Commerce compile data. The compiled cache reflects the state at the time of the last manual compile job run.

**Impact:** A production deployment that includes product catalog changes is NOT live to end users until the compile data jobs are explicitly re-run post-deployment.

**Action required:** Add the following steps to every production deployment runbook for catalog-related changes:
1. Clear Managed Platform Cache
2. Run Product Hierarchy Maintenance (if hierarchy changed)
3. Run EPC Compile Data job for all active price lists
4. Run Cache Catalog Product Definitions job (for DC)
5. Verify `CachedAPIResponse__c` records created with expected types
6. Purge old `ConfigurationSnapshot__c` records

---

### 52. Salesforce-to-Salesforce and Multi-System Transactions Cannot Be Distributed
**Issue:** Salesforce is transactional within its own database but cannot participate in distributed transactions initiated outside Salesforce. For B2C flows that span Salesforce + payment gateway + billing system + provisioning system, there is no native distributed transaction manager.

**Impact:** If a payment succeeds but the Salesforce order creation fails (or vice versa), the systems will be in an inconsistent state. There is no automatic rollback across system boundaries.

**Action required:** Design B2C checkout flows with compensating transactions and explicit error handling:
1. Payment capture should be the last step before order creation (not before)
2. Implement idempotency keys on payment gateway calls to handle retries safely
3. Build order creation as an atomic Salesforce operation (single transaction)
4. For failures: store payment transaction ID and implement a reconciliation process
5. Consider staging orders to a queue (Platform Event) before final commitment

---

## CLM and Document Generation Gotchas

### 53. Visualforce-Based DocGen OmniScripts Retired Spring '25
**Issue:** Four Visualforce-based Document Generation OmniScripts — `singleDocxVF`, `multiDocxVF`, `singleWebVF`, and the generic document generation OmniScript — were retired in Spring '25. Any clones of these OmniScripts are also unsupported and will not receive updates.

**Impact:** Orgs still using VF-based DocGen OmniScripts (or clones) after Spring '25 will receive no Salesforce support and may break in future releases. This is a breaking change for implementations that customized the VF-based scripts.

**Action required:** Migrate to Lightning Web Component-based equivalents:
- `singleDocxLwc` → replaces `singleDocxVF`
- `multiDocxLwc` → replaces `multiDocxVF`
- `singleWebLwc` → replaces `singleWebVF`

Install the `DocGenerationSampleLwc` datapack from the managed package to get the LWC samples. Path: App Launcher → Vlocity Templates → install LWC OmniScripts.

---

### 54. DocuSign OAuth 1.0 Deprecated — Must Migrate to OAuth 2.0
**Issue:** DocuSign deprecated OAuth 1.0 authentication. Managed Package users on Winter '23 (package version 240.11) or later must configure OAuth 2.0 named credentials for DocuSign. The deadline was March 2024.

**Impact:** Orgs that have not migrated to OAuth 2.0 will have broken DocuSign integration in their CLM Document Generation flows. This affects Communications, Media, Energy & Utilities, Insurance, and Public Sector managed packages.

**Action required:** 
1. In Setup → Auth. Providers → configure DocuSign OAuth 2.0 authentication provider
2. In Setup → Named Credentials → create a named credential using the DocuSign OAuth 2.0 provider
3. Verify document generation flows that use DocuSign e-signature function correctly end-to-end

---

### 55. Server-Side DocGen Has Throttling Limits That Can Block High-Volume Use
**Issue:** Server-side document generation (introduced Summer '21 for existing orgs, auto-provisioned for new customers on Spring '22 SKUs) has org-level throttling limits:
- 1,000 requests per hour
- 24,000 requests per day

Requests exceeding limits are blocked (not queued) and logged to `DocumentGenerationProcess__c`.

**Impact:** High-volume contract generation scenarios (e.g., bulk contract generation from a batch process) can hit the hourly limit, causing document generation to fail silently unless the calling process checks for errors.

**Action required:** 
- For bulk document generation, implement batching with explicit pauses between batches
- Monitor `DocumentGenerationProcess__c` for blocked requests
- Contact Salesforce support if org-level limits need to be increased

---

### 56. CLM Integration Uses Opportunities, Quotes, and Orders — CLM Not Standalone
**Issue:** Vlocity CLM integrates contract creation with the sales process: contracts are carried forward through Opportunity → Quote → Order stages. CLM is not a standalone contract management tool — it depends on the transactional objects being in place.

**Impact:** Attempts to implement CLM without the full CPQ/ordering pipeline in place will result in a gap where contract creation cannot be automated. Standalone CLM (e.g., NDA creation not tied to a sale) requires separate non-transactional contract flows.

**Action required:** At design phase, map which contracts are transactional (generated from the sales pipeline) vs non-transactional (NDAs, partner agreements). Non-transactional contracts require a separate CLM flow that creates `Contract` records directly, bypassing Opportunity/Quote/Order linkage.

---

## Order Management Gotchas

### 57. OM Custom Code Must NOT Modify Status/State Fields Directly
**Issue:** Modifying `Action__c`/`SubAction__c`/`SupplementalAction__c` on `OrderItem`, or `Status__c`/`OrderStatus__c`/`FulfilmentStatus__c` on `Order`/`OrderItem`/`FulfilmentRequestLine__c`, or `State__c` on `OrchestrationItem__c`/`OrchestrationPlan__c` from custom code will corrupt OM state.

**Impact:** OM orchestration plans get stuck, orchestration items remain in `Running` state permanently, and order fallout increases dramatically. This is one of the most common causes of OM production incidents.

**Action required:** Add static code analysis rules to prevent direct DML on these fields outside the OM managed package classes. In code reviews, flag any Apex or Integration Procedure that sets these fields. Use OM's built-in APIs to advance state.

---

### 58. Parallel Orchestration Items Doing Similar DMLs Cause Row Lock Timeouts
**Issue:** When multiple orchestration items run in parallel and each performs DML on the same parent records (e.g., multiple swim lanes updating the same Order or OrderItem), row lock timeout exceptions occur.

**Impact:** Orchestration fallout increases under parallel execution; orders with many parallel swim lanes are at highest risk.

**Action required:**
- Limit parallel items per swim lane to 16 or fewer
- For plans with many parallel swim lanes, serialize DML-heavy items using dependencies
- Split large orders with many parallel swim lanes across multiple orders (use `CrossOrderDependencyAllowed` for cross-order dependencies)
- Use an Auto Task at the end of parallel swim lanes to serialize the final update step

---

### 59. Apex Heap Size Exceptions During Decomposition — Too Many Attributes
**Issue:** If products or OrderItems have large numbers of attributes, Apex Heap Size exceptions occur during order decomposition. This is exacerbated by the Picklist attribute type, which is heavier than String attributes.

**Impact:** Order submission failures for complex products; decomposition cannot complete.

**Action required:**
- Reduce the number of attributes per product, OrderItem, FulfilmentRequestLine, Asset, and InventoryItem
- Prefer `String` attribute type over `Picklist` type on Technical Products
- Migrate to the V2 attribute model which has a lighter memory footprint
- Check Application Constraints documentation for exact heap limits

---

### 60. Debug Logging Enabled During Orchestration Causes Apex Time Limit Exceptions
**Issue:** If Apex Debug Logging is enabled (developer console, trace flags) or the `LoggingEnabled` custom setting is set to `True` during orchestration execution, the additional logging overhead causes Apex CPU/Time Limit exceptions in orchestration callouts.

**Impact:** Order orchestration failures in sandbox environments during development/debugging, and in production if trace flags are accidentally left on.

**Action required:**
- Always disable Apex Debug Logging and set `LoggingEnabled = False` before running OM in any environment, including sandboxes
- Use short-duration trace flags with specific user scoping to minimize blast radius
- Automate removal of trace flags via a scheduled job or post-deployment script

---

### 61. Orders Must Be Created Using Industries CPQ — Direct Order Creation Bypasses OM
**Issue:** Industries Order Management requires that commercial orders be created through Industries CPQ (using the Quote-to-Order flow). Orders created directly via Salesforce standard order creation or via `Order` sobject API without going through CPQ will not have the required technical enrichment for OM decomposition.

**Impact:** Direct order creation results in orders with missing decomposition attributes, causing OM to fail at the decomposition step.

**Action required:** All order creation flows (B2B via assisted channel, B2C via Digital Commerce) must go through the Industries CPQ `submitOrder` or `submitCart` API. Flag any custom integration or migration script that creates `Order` records directly — these must be refactored.

---

### 62. EPC Product Console Object Types Not Natively Compatible with Product Designer
**Issue:** If an existing product was created in Vlocity Product Console using facets other than **General Properties** (e.g., "Attribute Properties", "Design Time Attributes", "Run Time Attributes" as separate facets), those products are not directly editable in Vlocity Product Designer. Product Designer only displays attributes and fields configured in the General Properties facet — it ignores all other facets.

**Impact:** In upgrade projects (legacy Product Console → new Product Designer), all existing object types with non-General-Properties facets must be manually migrated. There is no automated conversion tool. This can be significant work for large catalogs.

**Action required:** Before migrating to Vlocity Product Designer, audit all Object Types for non-General-Properties facets. For each: recreate sections in the General Properties facet and reassign attributes/fields from the legacy facets. Do not delete legacy facets (they remain for Product Console backward compatibility), but ensure General Properties is populated for Product Designer usage.

---

### 63. DC Cache Excludes Certain Attributes — Must Explicitly Configure Exclusions
**Issue:** Vlocity EPC has a per-attribute setting that controls whether an attribute's value is included in the Digital Commerce basket cache. By default, all attributes ARE included in the cache key. For customer-specific attributes (e.g., IMEI number, serial number, customer-entered values), including them in the cache key breaks cache hits — every unique customer value creates a new cache entry.

**Impact:** If customer-specific attributes are included in the DC cache key, basket cache hit rates drop to near-zero for high-cardinality attributes, causing significant performance degradation in Digital Commerce.

**Action required:** In Vlocity Product Designer → attribute definition → set "Exclude from Basket Cache" to `true` for any attribute whose value is unique per customer or per order instance. The `ConfigureOffer` API will then exclude those attributes from the basket cache response. This setting is `false` by default.

---

### 64. Technical Product Specifications Must Use Attributes Only — Not Standard Fields
**Issue:** For Industries Order Management to correctly communicate product and fulfillment information with downstream systems during orchestration, technical product specifications must be defined using product attributes. Standard product fields (non-attribute fields) are not reliably passed through the decomposition → fulfillment request chain to external systems.

**Impact:** Downstream fulfillment systems (billing, provisioning, inventory) may not receive required product data if it is stored in standard fields instead of attributes on technical products.

**Action required:** Ensure all product modeling for technical products uses the attribute-based model exclusively. Apply the naming convention:
- `ATT_DC` prefix for decomposition attributes
- `ATT_DT` prefix for design-time attributes
- `ATT_RT` prefix for run-time (customer-specified) attributes
