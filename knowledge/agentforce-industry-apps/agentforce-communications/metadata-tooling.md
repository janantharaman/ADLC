---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: metadata-tooling
last-updated: 2026-05-10
---

# Communications Cloud — Metadata and Tooling

## Namespace

All Communications Cloud custom metadata, objects, and fields live under the `vlocity_cmt` namespace (Vlocity Communications & Media Telco). This namespace prefix appears on all custom object API names (`vlocity_cmt__ObjectName__c`) and custom field API names (`vlocity_cmt__FieldName__c`).

---

## Key Custom Metadata Types

Custom Metadata Types (CMTs) in Communications Cloud drive runtime behavior without code changes. The following are confirmed from official documentation:

| Custom Metadata API Name | Purpose | Key Field(s) |
|--------------------------|---------|-------------|
| `VlocityIntegrationSetting__mdt` | Central integration settings for TM Forum APIs | `TMForumPriceList` (price list for TMF API operations) |
| `IntegrationProviderDefinition__mdt` | Notification Framework: defines which Salesforce object and fields trigger CDC-based outbound notifications | Resource API Name, Resource Field API Names, Change Event Type |
| Integration Provider Definition Mapping | Maps CDC change events to TM Forum notification payload fields | Object fields → notification attributes |

> **To-be-grounded:** Full list of all `vlocity_cmt__` Custom Metadata Type API names should be queried from the target org via:
> ```soql
> SELECT DeveloperName, Label, QualifiedApiName FROM CustomObject WHERE IsCustomMetadataType = TRUE AND NamespacePrefix = 'vlocity_cmt'
> ```

---

## Key Custom Objects (Object Metadata)

The following objects are part of the Communications Cloud managed package and require the `vlocity_cmt__` namespace prefix in all references:

### Product Catalog Domain
| Object API Name | Label |
|----------------|-------|
| `vlocity_cmt__Catalog__c` | Catalog / Category |
| `vlocity_cmt__CatalogProductRelationship__c` | Catalog Product Relationship |
| `vlocity_cmt__ProductChildItem__c` | Product Child Item |
| `vlocity_cmt__ProductRelationship__c` | Product Relationship |
| `vlocity_cmt__AttributeAssignment__c` | Attribute Assignment |
| `vlocity_cmt__Attribute__c` | Attribute |
| `vlocity_cmt__AttributeCategory__c` | Attribute Category |
| `vlocity_cmt__Picklist__c` | Picklist |
| `vlocity_cmt__PicklistValue__c` | Picklist Value |
| `vlocity_cmt__VlocityAttachment__c` | Vlocity Attachment |
| `vlocity_cmt__ObjectClass__c` | Object Class |

### Pricing Domain
| Object API Name | Label |
|----------------|-------|
| `vlocity_cmt__PriceList__c` | Price List |
| `vlocity_cmt__PriceListEntry__c` | Price List Entry |
| `vlocity_cmt__PricingElement__c` | Pricing Element |
| `vlocity_cmt__PricingVariable__c` | Pricing Variable |
| `vlocity_cmt__Promotion__c` | Promotion |
| `vlocity_cmt__TimePlan__c` | Time Plan |

### Orders Domain
| Object API Name | Label |
|----------------|-------|
| `vlocity_cmt__OrderItemRelationship__c` | Order Item Relationship |
| `vlocity_cmt__SubOrder__c` | Sub Order |

### Quote Domain
| Object API Name | Label |
|----------------|-------|
| `vlocity_cmt__QuoteLineItemRelationship__c` | Quote Line Item Relationship |
| `vlocity_cmt__QuotePricingAdjustment__c` | Quote Pricing Adjustment |

### Case/Ticket Domain
| Object API Name | Label |
|----------------|-------|
| `CaseTroubleTicket` | Case Trouble Ticket (v5 extension) |

### Agreements Domain
| Object API Name | Label |
|----------------|-------|
| `vlocity_cmt__Obligation__c` | Obligation (Agreement Term) |

---

## OmniStudio Metadata Types

OmniStudio (formerly Vlocity OmniStudio) is the primary low-code development platform for Communications Cloud. Its metadata types are deployed as standard Salesforce metadata.

| Metadata Type | API Name | Description |
|--------------|----------|-------------|
| OmniScript | `OmniScript` | Guided UI flows (replaces Vlocity OmniScript) |
| DataRaptor | `DataRaptor` | Data load/transform/extract components |
| DataRaptor Bundle | `DataRaptorBundleDefinition` | Grouped DataRaptor definitions |
| Integration Procedure | `IntegrationProcedure` | Server-side orchestration flows |
| FlexCard | `FlexCard` | UI card components |
| Calculation Matrix | `CalculationMatrix` | Decision tables for pricing/eligibility |
| Calculation Procedure | `CalculationProcedure` | Calculation logic flows |

> **Note:** OmniStudio metadata types are deployed using standard Salesforce DX (`sf project deploy`) or `deploy_metadata` MCP tool. They do NOT use the IDX Workbench for deployment (IDX is used only for Vlocity datapack content migration).

---

## Metadata API Types Relevant to Communications Cloud

### Standard Salesforce Metadata Types Used

| Metadata Type | API Name | Communications Cloud Usage |
|--------------|----------|---------------------------|
| Custom Object | `CustomObject` | All `vlocity_cmt__*__c` objects |
| Custom Field | `CustomField` | Fields on standard objects (Order, OrderItem, Account, Product2, Case, Asset, Quote, QuoteLineItem) |
| Custom Metadata | `CustomMetadata` | `VlocityIntegrationSetting__mdt`, `IntegrationProviderDefinition__mdt` |
| Permission Set | `PermissionSet` | Role-based access control by module |
| Named Credential | `NamedCredential` | External service credentials for Integration Procedures |
| Remote Site Setting | `RemoteSiteSetting` | Allow external callouts |
| Static Resource | `StaticResource` | `TMFOpenAPIs` — TM Forum OpenAPI specifications |
| Connected App | `ConnectedApp` | OAuth 2.0 connected app for Industry API authorization |
| Apex Class | `ApexClass` | Custom Apex extensions, API implementations |
| Flow | `Flow` | Screen flows, auto-launched flows for order processes |
| Custom Labels | `CustomLabel` | Internationalization for UI components |
| Record Type | `RecordType` | Product, Account, and Case record type differentiation |

---

## IDX Workbench — Datapack Deployment

IDX Workbench is the tool used for importing/exporting Vlocity-style "datapacks" (product catalog data, OmniStudio components in legacy format).

### Prerequisites
- Salesforce API version **58.0 or later**
- IDX Workbench installed and configured
- Repository created in IDX Workbench

### Datapack Import Steps (for TMFOpenAPIs static resource)
1. Navigate to Setup → Static Resources → locate `TMFOpenAPIs` → download and unzip
2. In IDX Workbench: New Repository → select unzipped folder
3. Designate source and target Salesforce org
4. Create new project: select **Vlocity Types: All** and **Salesforce Types: All**
5. Fetch available datapacks
6. Select all datapacks → move to Selected list → Save twice
7. Click **Migrate** to push all selected components to org

### Included TM Forum Datapack Content (Static Resource)
| Datapack | Content |
|----------|---------|
| TMF 620 v4 | Product Catalog API specification |
| TMF 621 v4 | Trouble Ticket API specification |
| TMF 622 v4 | Product Ordering API specification |
| TMF 629 v4 | Customer Management API specification |
| TMF 648 v4 | Customer Quote API specification |
| TMF 637 v4 | Product Inventory API specification |

---

## Package.xml Template for Communications Cloud Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- OmniStudio Components -->
    <types>
        <members>*</members>
        <name>OmniScript</name>
    </types>
    <types>
        <members>*</members>
        <name>DataRaptor</name>
    </types>
    <types>
        <members>*</members>
        <name>IntegrationProcedure</name>
    </types>
    <types>
        <members>*</members>
        <name>FlexCard</name>
    </types>
    <!-- Custom Metadata -->
    <types>
        <members>VlocityIntegrationSetting__mdt.*</members>
        <name>CustomMetadata</name>
    </types>
    <types>
        <members>IntegrationProviderDefinition__mdt.*</members>
        <name>CustomMetadata</name>
    </types>
    <!-- Permission Sets -->
    <types>
        <members>CommCloudUserPermSet</members>
        <name>PermissionSet</name>
    </types>
    <!-- Connected Apps -->
    <types>
        <members>IndustryAPIConnectedApp</members>
        <name>ConnectedApp</name>
    </types>
    <!-- Static Resources -->
    <types>
        <members>TMFOpenAPIs</members>
        <name>StaticResource</name>
    </types>
    <!-- Apex Classes (custom extensions) -->
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
    <version>62.0</version>
</Package>
```

> **Note:** The exact permission set names, connected app names, and custom metadata record names should be verified from the target org before deploying. Use `mcp__salesforce__run_soql_query` to enumerate actual deployed components.

---

## Deployment Notes

### Deploy Sequence
Communications Cloud deployment must follow this sequence to avoid dependency failures:

1. Deploy base managed package (Communications Cloud package from AppExchange)
2. Deploy OmniStudio package (if not already included in Communications Cloud package)
3. Run IDX Workbench to import TMFOpenAPIs datapacks
4. Deploy Custom Metadata records (`VlocityIntegrationSetting__mdt`, `IntegrationProviderDefinition__mdt`)
5. Deploy Permission Sets
6. Deploy Apex extensions (if any)
7. Deploy OmniStudio components (OmniScripts, DataRaptors, Integration Procedures, FlexCards)
8. Deploy Flows and Page Layouts
9. Assign Permission Sets to users
10. Configure Connected App for OAuth 2.0 (Industry API)

### Validation Deploy Before Activation
Always run a check-only deploy before activating:
```
mcp__salesforce__deploy_metadata with checkOnly: true
```

### MuleSoft Integration Deployment
1. Enable access and accept consent terms in Salesforce Setup
2. Enable Integration Assets (`sf.enable_integration_assets.htm`)
3. Connect Salesforce org to MuleSoft instance (`sf.connect_to_mulesoft_instance.htm`)
4. Deploy pre-built integration templates from MuleSoft Anypoint Exchange

---

## Tooling API Objects

> **To-be-grounded:** The Tooling API object list for Communications Cloud-specific types has not been formally published in the documentation pages retrieved. Standard Salesforce Tooling API objects (ApexClass, ApexTrigger, CustomObject, etc.) apply. For vlocity_cmt-namespace Tooling API types, query the target org:
> ```
> GET /services/data/v62.0/tooling/sobjects/
> ```
> and filter for `vlocity_cmt` namespace objects.

---

## B2C Module Metadata (Digital Commerce, Connected Assets, ASLM)

### Digital Commerce Metadata

Digital Commerce introduces its own metadata components separate from the B2B CPQ path:

| Component Type | API Name / Location | Purpose |
|---------------|-------------------|---------|
| Standard DC Connected App | Setup → Connected Apps | OAuth 2.0 for guest/anonymous cart sessions |
| DC Site (Experience Cloud site) | Setup → Digital Experiences | Self-service storefront; requires guest profile config |
| `CartDocument` (standard object) | Standard object (no namespace) | New cart model for Standard DC APIs (replaces pseudo-orders) |
| `CartDocumentItem` (standard object) | Standard object (no namespace) | Line items in the new cart model |
| `CachedAPIResponse__c` | `vlocity_cmt` namespace | Stores CPQ compile data (product structure, pricing) |
| `ConfigurationSnapshot__c` | `vlocity_cmt` namespace | Stores Digital Commerce compile data (separate from CPQ compile) |
| `CommerceEntitlement` policy | Setup → Commerce → Buyer Groups | Controls which product catalogs are visible per buyer segment |

#### DC Compile Data — Two Separate Jobs

> **Critical:** CPQ compile data and Digital Commerce compile data are two distinct jobs. Running CPQ compile does NOT update DC compile data. Both must be run after any product catalog change.

```apex
// CPQ compile (B2B/assisted channel)
vlocity_cmt.CpqAppHandlerJob.doInvoke('compile', params);

// Digital Commerce compile (B2C self-service channel)
vlocity_cmt.DcCompileJob.doInvoke('compile', params);

// Deep clean compile (full re-generation, use for post-deployment resets)
vlocity_cmt.DcCompileJob.doInvoke('deepClean', params);
```

#### DC Deployment Order
When deploying Digital Commerce updates, follow this sequence:
1. Deploy product catalog changes (Product2, `vlocity_cmt__*` objects)
2. Run CPQ compile job
3. Run DC compile job (separate — does NOT auto-run after CPQ compile)
4. Flush DC cache if `CachedAPIResponse__c` cache is stale
5. Deploy Experience Cloud site pages and LWC components
6. Test anonymous cart access via Connected App guest user

### Connected Assets Metadata

| Component Type | API Name / Description |
|---------------|----------------------|
| Actionable Orchestration Source Event | Platform event: triggers Connected Assets orchestration |
| `ActionableEventOrchestration__c` | Orchestration record tracking event processing |
| `ActionableEventOrchestrationItem__c` | Individual steps within an orchestration |
| Context Service rule set | Custom metadata — drives IoT/telematics context resolution |
| Rule Engine definition | Custom metadata — defines the business rules applied to events |
| `vlocity_cmt__ConnectedAsset__c` | Asset extension for connected/IoT-enabled assets |

#### Connected Assets Permission Set Groups

The following permission sets are required for Connected Assets users (Spring '26):

| Permission Set | Persona | Purpose |
|--------------|---------|---------|
| `Actionable Event Orchestration Designer` | Fulfillment Designer | Create/modify orchestration definitions |
| `Actionable Event Orchestration Runtime` | System/Integration User | Execute orchestrations at runtime |
| `Context Service Admin` | Platform Admin | Configure Context Service rules |
| `Context Service Runtime` | System/Integration User | Resolve context at runtime |
| `Rule Engine Designer` | Business Analyst | Author rules applied to orchestration |
| `Rule Engine Runtime` | System/Integration User | Execute rules at runtime |

> **Entitlement limit:** Connected Assets Actionable Event Orchestration is licensed at **300 orchestrations/month** on standard SKU. Monitor usage via `ActionableEventOrchestration__c` record counts. Excess orchestrations are blocked — not queued.

### CLM / Document Generation Metadata

Contract Lifecycle Management and Document Generation use the following metadata components:

| Component Type | API Name / Description |
|---------------|----------------------|
| Document Template | `vlocity_cmt__DocumentTemplate__c` (or OmniStudio Foundation `DocumentTemplate`) | Word/PowerPoint `.docx` template with token placeholders |
| Document Generation Process | `DocumentGenerationProcess__c` | Tracks server-side doc gen requests and throttling state |
| CLM Contract | `Contract` (standard object) + CLM fields | Standard Salesforce Contract extended with CLM actions |
| DocGen OmniScript (LWC) | `singleDocxLwc`, `multiDocxLwc`, `singleWebLwc` | Lightning Web Component-based generation (active) |
| DocGen OmniScript (deprecated) | `singleDocxVF`, `multiDocxVF`, `singleWebVF` | Visualforce-based — **retired Spring '25** |

#### Document Token Format Reference

| Token Type | Format | Example | Supported Files |
|-----------|--------|---------|----------------|
| Standard field | `{{fieldApiName}}` | `{{Account.Name}}` | .docx, .pdf |
| Image | `{{IMG_<name>}}` | `{{IMG_header}}` | .docx, .pdf, .pptx |
| Rich text | `{{RTB_<name>}}` | `{{RTB_ProductDetails}}` | .docx only |
| Hyperlink | `{{HYP_<name>}}` | `{{HYP_ProductURL}}` | .docx, .pptx |

> **Migration note:** Orgs using `singleDocxVF` or `multiDocxVF` OmniScripts (or clones of them) must migrate to LWC equivalents by Spring '25. The LWC versions are available in the `DocGenerationSampleLwc` datapack.

#### Server-Side Document Generation Throttling Limits

| Limit | Default Value |
|-------|--------------|
| Max requests per hour (per org) | 1,000 |
| Max requests per day (per org) | 24,000 |

Requests exceeding limits are blocked and logged to `DocumentGenerationProcess__c`. Monitor this object for throttling events in high-volume orgs.

#### DocuSign OAuth 2.0 Requirement (CLM)

DocuSign deprecated OAuth 1.0. Orgs on Winter '23 (package version 240.11) or later **must** configure OAuth 2.0 named credentials for DocuSign. Failure to do so breaks DocuSign-integrated document generation workflows.

Setup path: Setup → Named Credentials → configure DocuSign OAuth 2.0 authentication provider.

### Order Management Metadata

| Component Type | API Name / Description |
|---------------|----------------------|
| Orchestration Plan Definition | `OrchestrationPlanDefinition__c` | Design-time plan template |
| Orchestration Plan | `OrchestrationPlan__c` | Runtime instance of a plan definition |
| Orchestration Item Definition | `OrchestrationItemDefinition__c` | Design-time task template |
| Orchestration Item | `OrchestrationItem__c` | Runtime task instance |
| Orchestration Dependency Definition | `OrchestrationDependencyDefinition__c` | Design-time dependency |
| Orchestration Dependency | `OrchestrationDependency__c` | Runtime dependency instance |
| Fulfillment Request | `FulfilmentRequest__c` | Decomposed sub-order for a downstream system |
| Fulfillment Request Line | `FulfilmentRequestLine__c` | Line item in a fulfillment request |
| Orchestration Queue | `OrchestrationQueue__c` | Four built-in queues; engine auto-load-balances across them |

#### Order Management Fulfillment Status Values

**Synchronous mode** (default `OrderSubmitMode`):
- `Draft` → `In Progress` → `Activated` (success) or `Rejected` (failure)
- `Decomposed` — appears only for Decomposition Only submissions

**Asynchronous/Queueing mode** (set `OrderSubmitMode` = `Queueing`):
- `Draft` → `Submitted` → `Submitted for Fulfillment` → `In Progress` → `Activated`
- `Superseded` — order replaced by an amendment

#### OM Custom Settings (Key)

| Custom Setting | API Name | Purpose |
|--------------|----------|---------|
| Order Submit Mode | `OrderSubmitMode` | `Synchronous` (default) or `Queueing` |
| Cross-Order Dependency | `CrossOrderDependencyAllowed` | Enable dependencies across separate orders |
| Logging Enabled | `LoggingEnabled` | Set to `False` in production — debug logging causes Apex Time Limit exceptions |

#### OM Key Constraint: Field Modification Restrictions

Custom code, Integration Procedures, and DataRaptors **must not** modify the following OM fields directly:
- `Action__c`, `SubAction__c`, `SupplementalAction__c` on `OrderItem` records
- `Status__c`, `OrderStatus__c`, `FulfilmentStatus__c` on `Order`/`OrderItem`/`FulfilmentRequestLine__c` records
- `State__c` on `OrchestrationItem__c`/`OrchestrationPlan__c` records

Modifying these fields outside OM's own processes causes state corruption and blocked/stuck orchestrations.

---

## EPC Product Catalog Administration Tools

### Product Designer vs Product Console — When to Use Each

| Task | Use | Notes |
|------|-----|-------|
| Create/edit attributes, picklists, object types, product specs, bundles | **Product Designer** (LWC, Spring '20+) | Recommended for all new work; drag-and-drop; search; improved performance |
| Create/edit pricing elements (pricing plans, pricing variables, time plans, time policies) | **Product Console** only | Product Designer does not support pricing element creation |
| Manage legacy products with non-General-Properties facets | **Product Console** | Product Designer only shows General Properties facet; legacy facets invisible |
| Translate product catalog to multiple languages | **Product Console** (Multilingual Catalog feature) | String translations supported in both but configured in Product Console |
| Track catalog changes with Projects | **Product Designer** | Projects track changes only when made in Product Designer (not Product Console) |
| Export product reports/audits | **Product Designer** | Reports feature available in Product Designer |

### EPC PSR (Product-Service-Resource) Layer Model

The EPC product hierarchy follows TM Forum's product-service-resource decomposition model:

| Layer | EPC Term | Description | OM Role |
|-------|---------|-------------|---------|
| Commercial | Product Specification / Product Offering | What the business sells to customers — commercial view with pricing | Order capture (CPQ) |
| CFS | Customer Facing Service Spec (CFSS) | Technical products representing customer-facing services (e.g., broadband port, SIM) | Decomposition target |
| RFS | Resource Facing Service Spec (RFSS) | Underlying network/resource specs (access port, IP address allocation, cable attributes) | Downstream OSS provisioning |
| Physical | Physical/Logical Resource | Allocated physical resources (phone number, IP, equipment serial) | Network inventory systems |

### EPC Versioning (GA — Spring '26)

Product versioning allows managing product lifecycle from inception to retirement without disrupting active transactions:

- Create multiple versions of an Offer or Product Specification
- Manage lifecycle states per version: Draft → In-Test → Active/Released → Retired
- CPQ supports browsing, order capture, and MACD on versioned products
- **Not supported for Technical Products** — only commercial offers and product specifications
- Before enabling Versioning, run the two EPC Schema upgrade jobs:
  1. **Populate New Fields job** — populates `GlobalGroupKey` and `VersionLabel` on Product2, Object Type, Picklist
  2. **Populate Product Hierarchy Group Key Path job** — populates `ProductHierarchyGroupKeyPath` on OrderItems, Assets, etc.

> **Warning:** Turning on Versioning is irreversible. Test thoroughly in sandbox before enabling in production.

---

## Permission Set Licenses (PSL) — B2C Modules (Spring '22+)

Starting Spring '22, new Communications Cloud customers provisioned via new SKUs (post 17 May 2022) use **Permission Set Licenses (PSLs)** instead of managed package licenses. Existing customers can migrate at contract renewal.

Modules with PSLs available:
- CPQ
- EPC (Enterprise Product Catalog)
- DC (Digital Commerce)
- OM (Order Management)
- CLM (Contract Lifecycle Management)
- DocGen (Document Generation)

> **Key distinction:** PSLs allow you to grant permissions incrementally on top of a base user license without purchasing full managed package seats. Query assigned PSLs via:
> ```soql
> SELECT AssigneeId, PermissionSetLicenseId FROM PermissionSetLicenseAssign WHERE PermissionSetLicense.DeveloperName LIKE '%Industries%'
> ```
