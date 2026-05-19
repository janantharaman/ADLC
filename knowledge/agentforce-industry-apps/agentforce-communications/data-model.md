---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); Vlocity Communications Object List Spring '21; CME Managed Package Dev Guide (2025.12.04); B2B Telecommunications documents ingested 2026-05-10; B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: data-model
last-updated: 2026-05-10
---

# Communications Cloud — Data Model

## Namespace Note

All Vlocity/Communications Cloud custom objects and custom fields use the `vlocity_cmt__` namespace prefix. This namespace is preserved post-Salesforce acquisition. Standard Salesforce objects (Account, Order, Product2, etc.) are extended with custom fields in this namespace.

`vlocity_cmt__GlobalKey__c` is the universal cross-system unique identifier used as the TM Forum resource ID across all entities.

---

## Domain 1: Product Catalog

### Core Catalog Objects

| Object API Name | Description | Approx. API Version |
|----------------|-------------|---------------------|
| `Product2` | Standard Salesforce product object, extended with vlocity_cmt fields for telecom specifics | All |
| `vlocity_cmt__Catalog__c` | Serves dual role as both Catalog and Category (differentiated by `vlocity_cmt__IsCatalogRoot__c`) | All |
| `vlocity_cmt__CatalogProductRelationship__c` | Relates products to catalog categories | All |
| `vlocity_cmt__ProductChildItem__c` | Defines bundle/child product relationships (parent-child offering hierarchy) | All |
| `vlocity_cmt__ProductRelationship__c` | Non-hierarchical product relationships (e.g., requires, excludes, recommends) | All |
| `vlocity_cmt__AttributeAssignment__c` | Assigns specification characteristics (attributes) to products | All |
| `vlocity_cmt__Attribute__c` | Defines a characteristic type (attribute definition) | All |
| `vlocity_cmt__AttributeCategory__c` | Groups attributes into categories for assignment to products | All |
| `vlocity_cmt__Picklist__c` | Defines a picklist data type for attribute values | All |
| `vlocity_cmt__PicklistValue__c` | Individual values within a picklist | All |
| `vlocity_cmt__VlocityAttachment__c` | Stores documents, images, and videos linked to products | All |
| `vlocity_cmt__ObjectClass__c` | Defines the object type/target product schema for a product | All |
| `ProductCategory` | Standard Salesforce product category object; used in eligibility qualification (TMF679) | All |

### Key Fields Added to `Product2` by Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__Status__c` | Picklist | Lifecycle status (Active, Draft, Retired, etc.) |
| `vlocity_cmt__IsOrderable__c` | Checkbox | Whether product is standalone-orderable (isSellable in TMF) |
| `vlocity_cmt__specificationSubType__c` | Picklist | Simple vs. Bundle indicator (isBundle in TMF) |
| `vlocity_cmt__GlobalKey__c` | Text | Universal cross-system key; used as TMF resource ID |
| `vlocity_cmt__VersionLabel__c` | Text | Version identifier |
| `vlocity_cmt__SellingStartDate__c` | Date | Product selling start date |
| `vlocity_cmt__EndOfLifeDate__c` | Date | Product end-of-life date |
| `vlocity_cmt__EffectiveDate__c` | Date | Product effective start date |
| `vlocity_cmt__EndDate__c` | Date | Product end date |
| `vlocity_cmt__FulfilmentStartDate__c` | Date | Fulfillment start date |
| `vlocity_cmt__SellingEndDate__c` | Date | Selling end date |
| `vlocity_cmt__VersionStartDateTime__c` | DateTime | Version validity start |
| `vlocity_cmt__VersionEndDateTime__c` | DateTime | Version validity end |
| `vlocity_cmt__ProductSpecId__c` | Lookup | Reference to the product specification |
| `vlocity_cmt__ObjectTypeId__c` | Lookup | Reference to ObjectClass (target product schema) |
| `vlocity_cmt__IsActive__c` | Checkbox | Active flag (mapped from TMF lifecycleStatus) |
| `vlocity_cmt__RecurringFrequency__c` | Picklist | Recurring charge period (Monthly, Annual, etc.) |
| `vlocity_cmt__VendorAccountId__c` | Lookup(Account) | Vendor/partner account reference |

### Catalog / Category Object (`vlocity_cmt__Catalog__c`) Key Fields

| Field API Name | Type | Description |
|---------------|------|-------------|
| `Name` | Text | Catalog or category name |
| `vlocity_cmt__GlobalKey__c` | Text | TMF resource ID |
| `vlocity_cmt__Description__c` | Text | Description |
| `vlocity_cmt__IsActive__c` | Checkbox | Active flag (TMF lifecycleStatus) |
| `vlocity_cmt__IsCatalogRoot__c` | Checkbox | `true` = top-level Catalog; `false` = Category |
| `vlocity_cmt__StartDateTime__c` | DateTime | Validity start |
| `vlocity_cmt__EndDateTime__c` | DateTime | Validity end |
| `vlocity_cmt__VendorAccount__c` | Lookup(Account) | Related vendor account |

---

## Domain 2: Pricing

### Core Pricing Objects

| Object API Name | Description |
|----------------|-------------|
| `vlocity_cmt__PriceList__c` | Top-level price list container; must be configured for CPQ and TMF APIs |
| `vlocity_cmt__PriceListEntry__c` | Price entry for a specific product/offer on a price list |
| `vlocity_cmt__PricingElement__c` | Pricing component (amount and frequency) within a price list entry |
| `vlocity_cmt__PricingVariable__c` | Pricing variable (charge type, currency, frequency) |
| `vlocity_cmt__Promotion__c` | Promotions, discounts, and offer terms |
| `vlocity_cmt__TimePlan__c` | Time plan defining duration and validity of a promotion |
| `PricebookEntry` | Standard Salesforce pricebook entry; used alongside vlocity price model |

### Key Fields on `vlocity_cmt__PriceListEntry__c`

| Field API Name | Type | Description |
|---------------|------|-------------|
| `Name` | Text | Reference number of the price list entry |
| `vlocity_cmt__DisplayText__c` | Text | Description of the price entry |
| `vlocity_cmt__EffectiveFromDate__c` | Date | Validity start (TMF validFor.startDateTime) |
| `vlocity_cmt__EffectiveUntilDate__c` | Date | Validity end (TMF validFor.endDateTime) |
| `vlocity_cmt__ChargeType__c` | Picklist | Price type (One-Time, Recurring, Usage) |
| `vlocity_cmt__RecurringFrequency__c` | Picklist | Recurring charge period |
| `vlocity_cmt__Amount__c` | Currency | Price amount |
| `vlocity_cmt__CurrencyCode__c` | Text | Currency code (ISO) |
| `vlocity_cmt__IsActive__c` | Checkbox | Price entry lifecycle status |
| `vlocity_cmt__PricingElementId__c` | Lookup | Link to pricing element |

### Key Fields on `vlocity_cmt__Promotion__c`

| Field API Name | Type | Description |
|---------------|------|-------------|
| `Name` | Text | Promotion name |
| `vlocity_cmt__Description__c` | Text | Promotion description |
| `PromotionCode` | Text | TMF promotion ID (TMF671) |
| `StartDateTime` | DateTime | Promotion start |
| `EndDateTime` | DateTime | Promotion end |
| `IsActive` | Checkbox | Lifecycle status |

---

## Domain 3: Orders

### Core Order Objects

| Object API Name | Description |
|----------------|-------------|
| `Order` | Standard Salesforce Order; used as the customer-facing commercial order |
| `OrderItem` | Standard Salesforce Order Line Item; one per product in the order |
| `vlocity_cmt__OrderItemRelationship__c` | Relationship between order items (parent-child bundles) |
| `vlocity_cmt__SubOrder__c` | Sub-order created during order decomposition for downstream fulfillment |
| `OrderDeliveryGroup` | Standard object for delivery grouping; used in TMF622 v5 for `PromisedDeliveryDate` |

### Key Fields Added to `Order` by Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__RequestedCompletionDate__c` | DateTime | TMF requestedCompletionDate |
| `vlocity_cmt__RequestedStartDate__c` | Date | TMF requestedStartDate (mandatory in implementation) |
| `vlocity_cmt__OriginatingChannel__c` | Text | Sales channel (TMF channel) |
| `vlocity_cmt__Notes__c` | Long Text | Order notes (TMF note) |
| `vlocity_cmt__PriceList__c` | Lookup | Associated price list (required for EPC setup) |
| `OrderReferenceNumber` | Text | External ID (TMF externalId) |
| `OrderNumber` | Auto Number | Internal order number (TMF id) |
| `Status` | Picklist | Order status; auto-transitions Draft → Activated via placeOrder API |

### Key Fields Added to `OrderItem` by Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__Action__c` | Picklist | Order action: Add, Change, Remove, Suspend, Resume |
| `vlocity_cmt__FulfilmentStatus__c` | Picklist | Fulfillment status of the line item |
| `vlocity_cmt__JSONAttribute__c` | Long Text (JSON) | Attribute values in JSON format (V1 model) |
| `vlocity_cmt__AttributeSelectedValues__c` | Long Text (JSON) | Attribute values (V2 model) |
| `Quantity` | Number | Product quantity |
| `OrderItemNumber` | Auto Number | Line item identifier (TMF id in v5) |

### Key Fields on `vlocity_cmt__OrderItemRelationship__c`

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__ParentOrderItemId__c` | Lookup(OrderItem) | Parent order line item |
| `vlocity_cmt__ChildOrderItemId__c` | Lookup(OrderItem) | Child order line item |
| `vlocity_cmt__RelationshipType__c` | Text | Relationship type (e.g., "bundles") |

---

## Domain 4: Quotes (CPQ)

### Core Quote Objects

| Object API Name | Description |
|----------------|-------------|
| `Quote` | Standard Salesforce Quote; used as CPQ quote header |
| `QuoteLineItem` | Standard Salesforce Quote Line Item; one per product in the quote |
| `vlocity_cmt__QuoteLineItemRelationship__c` | Parent-child relationship between quote line items |
| `vlocity_cmt__QuotePricingAdjustment__c` | Pricing adjustment/discount applied to a quote or line item |
| `Opportunity` | Standard; CPQ requires an opportunity for quote creation by default |

### Key Fields Added to `Quote` by Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__EffectiveOneTimeTotal__c` | Currency | Total one-time charges (TMF quoteTotalPrice) |
| `vlocity_cmt__EffectiveRecurringTotal__c` | Currency | Total recurring charges (TMF quoteTotalPrice) |

### Key Fields Added to `QuoteLineItem` by Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__Action__c` | Picklist | Line item action (Add, Change, Remove) |
| `vlocity_cmt__EffectiveBaseOneTimeTotal__c` | Currency | Base one-time price (TMF quoteItemPrice) |
| `vlocity_cmt__EffectiveBaseRecurringTotal__c` | Currency | Base recurring price (TMF quoteItemPrice) |
| `vlocity_cmt__AttributeSelectedValues__c` | Long Text (JSON) | Attribute values on the line item |
| `vlocity_cmt__productSpecid__c` | Lookup | Product specification reference |
| `LineNumber` | Number | Line item number (TMF id) |
| `Status` | Text | Line item status |

### Key Fields on `vlocity_cmt__QuoteLineItemRelationship__c`

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__RelatedQuoteLineItemId__c` | Lookup(QuoteLineItem) | Related child line item |
| `vlocity_cmt__RelationshipType__c` | Text | Relationship type |

---

## Domain 5: Customers and Accounts

### Account Extensions for Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `AccountNumber` | Text | TMF customer/account ID reference |
| `RecordType.Name` | Lookup | Used to differentiate: Individual, Business, BillingAccount, etc. |
| `vlocity_cmt__BillingAccountId__c` | Lookup(Account) | Reference to billing account (on Asset) |

### Contract Extensions (Agreement Management)

| Field API Name | Type | Description |
|---------------|------|-------------|
| `ContractNumber` | Auto Number | TMF Agreement id (documentNumber) |
| `ContractType` | Text | Agreement type (TMF agreementType) |
| `CustomerSignedDate` | Date | Initial date (TMF initialDate) |
| `Description` | Long Text | Statement of intent (TMF statementOfIntent) |
| `Status` | Picklist | Agreement status |
| `StartDate` | Date | Agreement start (TMF agreementPeriod.startDateTime) |
| `EndDate` | Date | Agreement end (generated via agreementTerm) |
| `ParentContractId` | Lookup(Contract) | Associated/parent agreement |

---

## Domain 6: Product Inventory (Installed Base)

### Asset Extensions for Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__AssetReferenceId__c` | Text | TMF Product Inventory id (mandatory) |
| `vlocity_cmt__ProvisioningStatus__c` | Picklist | TMF product status (Active, Inactive, Terminated, etc.) |
| `vlocity_cmt__BillingAccountId__c` | Lookup(Account) | Billing account for this installed product |
| `vlocity_cmt__OrderProductId__c` | Lookup(OrderItem) | Originating order item |
| `vlocity_cmt__JSONAttribute__c` | Long Text (JSON) | Attribute values V1 model |
| `AttributeSelectedValues__c` | Long Text (JSON) | Attribute values V2 model |
| `vlocity_cmt__PriceListEntry__c` | Lookup | Active pricing for this installed product |
| `SerialNumber` | Text | Product serial number (TMF productSerialNumber) |
| `ActivationDate` | Date | Service start date (TMF startDate) |
| `LifecycleEndDate` | Date | Service termination date (TMF terminationDate; requires LifecycleManagement license) |
| `Product2Id` | Lookup(Product2) | Product offering reference |

---

## Domain 7: Trouble Tickets (Cases)

### Case Extensions for Communications Cloud

| Field API Name | Type | Description |
|---------------|------|-------------|
| `vlocity_cmt__severity__c` | Picklist | Ticket severity: Critical, Major, Minor (TMF severity, mandatory) |
| `Subject` | Text | Ticket name (TMF name) |
| `Description` | Long Text | Issue description (TMF description, mandatory) |
| `Priority` | Picklist | Critical, High, Medium, Low (TMF priority) |
| `Status` | Picklist | Case status (TMF status) |
| `Type` | Picklist | Incident, Complaint, Request (TMF ticketType, mandatory) |
| `Origin` | Picklist | Source channel (TMF channel) |
| `ClosedDate` | DateTime | Resolution date |
| `CaseNumber` | Auto Number | TMF trouble ticket id |
| `ParentId` | Lookup(Case) | Related/parent ticket (TroubleTicketRelationship) |

### CaseTroubleTicket (v5 extension object)

| Field API Name | Type | Description |
|---------------|------|-------------|
| `severity` | Picklist | v5 severity extension |
| `expectedResolutionDate` | DateTime | Expected resolution date |
| `RequestedResolutionDate` | DateTime | Customer-requested resolution date |
| `externalId` | Text | External identifier |

---

## Domain 8: Documents and Agreements

### ContentDocument (Standard) — used by TMF667 and TMF651

| Object | Usage |
|--------|-------|
| `ContentDocument` | Document file storage (TMF667 document management) |
| `ContentVersion` | Versions of content documents; TMF667 maps to this |
| `DocumentTemplate` | DocGen document template (required for Agreement Specification / TMF651) |

---

## Object Relationship Diagram (Text Format)

```
vlocity_cmt__Catalog__c (root)
  └── vlocity_cmt__Catalog__c (category, IsCatalogRoot=false)
        └── vlocity_cmt__CatalogProductRelationship__c
              └── Product2 (Product Offering / Product Specification)
                    ├── vlocity_cmt__ProductChildItem__c → Product2 (bundle children)
                    ├── vlocity_cmt__ProductRelationship__c → Product2 (requires/excludes)
                    ├── vlocity_cmt__AttributeAssignment__c → vlocity_cmt__Attribute__c
                    ├── vlocity_cmt__PriceListEntry__c → vlocity_cmt__PriceList__c
                    └── vlocity_cmt__VlocityAttachment__c

Opportunity
  └── Quote
        └── QuoteLineItem
              ├── vlocity_cmt__QuoteLineItemRelationship__c (parent-child)
              └── vlocity_cmt__QuotePricingAdjustment__c → vlocity_cmt__Promotion__c

Order
  └── OrderItem
        └── vlocity_cmt__OrderItemRelationship__c (parent-child)

Order → (Decomposition) → vlocity_cmt__SubOrder__c → Provisioning

Asset (Product Inventory)
  ├── Account (BillingAccount)
  ├── Product2 (Product Offering)
  └── OrderItem (originating order line)

Account
  ├── Contact → AccountContactRelation (triggers TMF632 notification)
  └── Contract (Agreement)
        └── vlocity_cmt__Obligation__c (AgreementTerm)

Case (TroubleTicket)
  ├── CaseComment (Note)
  ├── ContentDocument (Attachment)
  ├── Account / Contact (RelatedParty)
  └── Asset (RelatedEntity)
```

---

## TM Forum to Salesforce Object Cross-Reference

| TM Forum API | TM Forum Resource | Salesforce Object |
|-------------|-------------------|------------------|
| TMF620 | Catalog | `vlocity_cmt__Catalog__c` (IsCatalogRoot=true) |
| TMF620 | Category | `vlocity_cmt__Catalog__c` (IsCatalogRoot=false) |
| TMF620 | ProductSpecification | `Product2` |
| TMF620 | ProductOffering | `Product2` |
| TMF620 | ProductOfferingPrice | `vlocity_cmt__PriceListEntry__c` |
| TMF621 | TroubleTicket | `Case` |
| TMF621 | Note | `CaseComment` |
| TMF621 | Attachment | `ContentDocument` |
| TMF622 | ProductOrder | `Order` |
| TMF622 | ProductOrderItem | `OrderItem` |
| TMF629 | Customer | `Account` |
| TMF629 | EngagedParty | `Contact` |
| TMF629 | AgreementRef | `Contract` |
| TMF637 | Product (inventory) | `Asset` |
| TMF648 | Quote | `Quote` |
| TMF648 | QuoteItem | `QuoteLineItem` |
| TMF651 | AgreementSpecification | `DocumentTemplate` |
| TMF651 | Agreement | `Contract` |
| TMF651 | AgreementItem | Sales Contract Line |
| TMF667 | Document | `ContentDocument` / `ContentVersion` |
| TMF671 | Promotion | `vlocity_cmt__Promotion__c` |
| TMF679 | CheckProductOfferingQualification | `Product2`, `Account`, `ProductCategory` |

---

## Custom Metadata Types Used in Communications Cloud

| Custom Metadata API Name | Purpose |
|--------------------------|---------|
| `VlocityIntegrationSetting__mdt` | Stores integration configuration including `TMForumPriceList` setting |
| `IntegrationProviderDefinition__mdt` | CDC/Notification Framework: defines object, fields, and change event type |
| Integration Provider Definition Mapping | Maps CDC fields to notification payloads |

> **Note:** The exact Custom Metadata API names for all settings should be verified in the target org via `run_soql_query` on `CustomMetadata` before deployment.

---

## Domain 9: Order Management Objects

The following objects are the core of the Vlocity Order Management subsystem. These are `vlocity_cmt__` namespace objects.

| Object Label | API Name | Description | Type |
|---|---|---|---|
| FulfilmentRequest | `FulfilmentRequest__c` | An order placed with a backend/fulfillment system (CFS, billing, logistics). Generated by OM decomposition. | Transactional |
| FulfilmentRequestLine | `FulfilmentRequestLine__c` | A line item in a fulfillment request; refers to a Product2 spec and optionally an Asset | Transactional |
| FulfilmentRequestDecompRelationship | `FulfilmentRequestDecompRelationship__c` | Links source Order or FulfilmentRequest with a generated FulfilmentRequest from decomposition | Transactional |
| FulfilmentRequestLineDecompRelationship | `FulfilmentRequestLineDecompRelationship__c` | Links source Order/FR Line with a generated FRL from decomposition | Transactional |
| FulfilmentRequestLineRelationship | `FulfilmentRequestLineRelationship__c` | Dependency relationship between Fulfilment Request Lines controlling orchestration order | Transactional |
| FRLSourceBundleRelationship | `FulfilmentRequestLineSourceRootOrderItem__c` | Links each FRL to its source Root Order Items after decomposition | Transactional |
| OrchestrationPlan | `OrchestrationPlan__c` | Assembled order fulfillment plan identifying tasks to fulfill an order | Transactional |
| OrchestrationPlanDefinition | `OrchestrationPlanDefinition__c` | Set of defined tasks for a fulfillment scenario | Setup |
| OrchestrationItem | `OrchestrationItem__c` | A fulfillment task assembled into an Orchestration Plan; MD child of OrchestrationPlan | Transactional |
| OrchestrationItemDefinition | `OrchestrationItemDefinition__c` | Definition of a task for fulfillment scenarios; MD child of OrchestrationPlanDefinition | Setup |
| OrchestrationDependency | `OrchestrationDependency__c` | Dependency of one OrchestrationItem on another; MD child of OrchestrationItem | Transactional |
| OrchestrationDependencyDefinition | `OrchestrationDependencyDefinition__c` | Defined dependency between OrchestrationItemDefinitions; controls execution order | Setup |
| OrchestrationScenario | `OrchestrationScenario__c` | Maps a requested action + sub-action on a Product to an OrchestrationPlanDefinition | Setup |
| OrchestrationQueueAssignmentRule | `OrchestrationQueueAssignmentRule__c` | Controls which queue an orchestration plan/task runs on | Setup |
| OrchestrationItemRelationship | `OrchestrationItemRelationship__c` | Generic item relationship; used during supplemental Order for dependency continuity | Transactional |
| OrchestrationItemSource | `OrchestrationItemSource__c` | Links each OrchestrationItem to source OrderItem(s) or FRL(s) after plan creation | Transactional |
| ManualQueue | `ManualQueue__c` | Work queue for manual fulfillment tasks | Transactional |
| ManualQueueAssignmentRule | `AssignmentRule__c` | Assignment rule governing which user gets manual tasks | Transactional |
| ManualQueueMember | `ManualQueueMember__c` | Assignment of a user to a manual queue; MD child of ManualQueue | Transactional |
| DecompositionRelationship | `DecompositionRelationship__c` | Rule describing how to translate a commercial order item into a technical backend item | Setup |
| InventoryItem | `InventoryItem__c` | Non-customer-owned items (SIM cards, set-top boxes, meters) tracked before sale/assignment | Transactional |
| InventoryItemDecompositionRelationship | `InventoryItemDecompositionRelationship__c` | Links source Asset or InventoryItem with one identified in decomposition | Transactional |
| ItemImplementation | `ItemImplementation__c` | Registration of custom Apex/Java code to execute a fulfillment task | Transactional |
| ErrorCode | `ErrorCode__c` | Error code unique to an ErrorCodeNamespace; used by OM to interpret external errors; MD child | Setup |
| ErrorCodeNamespace | `ErrorCodeNamespace__c` | Container for a set of unique error codes | Setup |
| OrderUpdate | `OrderUpdate__e` | Internal Platform Event for OM+ order status propagation | Transactional |
| OrderAsyncOperationEvent | `OrderAsyncOperationEvent__e` | Requests async operation on an order or order item bundle | Transactional |

---

## Domain 10: Agreement / Contract Lifecycle Management (CLM) Objects

| Object Label | API Name | Description | Type |
|---|---|---|---|
| Document | `Document__c` | Online document representation; can have physical files (PDF, Word) attached | Setup |
| DocumentClause | `DocumentClause__c` | Paragraph of legal language/provision used to assemble contract documents | Setup |
| DocumentSection | `DocumentSection__c` | Details about each section of a generated object document | Setup |
| DocumentTemplate | `DocumentTemplate__c` | Reusable assembly of clauses/sections; once activated can generate docs for multiple contracts | Setup |
| DocumentTemplateElement | `DocumentTemplateElement__c` | Stores original DOCX template and the result after clause token replacement | Setup |
| DocumentTemplateSection | `DocumentTemplateSection__c` | Section of a document template (clauses, images, context, embedded templates, signature) | Setup |
| DocumentTemplateSectionCondition | `DocumentTemplateSectionCondition__c` | Condition for dynamic display of a document section; uses Vlocity Entity Filters | Setup |
| DocumentToken | `DocumentToken__c` | Stores tokens/variables inserted into Document Clause content | Setup |
| GenericDocuSignDocument | `GenericDocument__c` | Information about documents in a DocuSign eSignature envelope | Transactional |
| GenericDocuSignEnvelope | `GenericEnvelope__c` | Stores DocuSign envelope information | Transactional |
| GenericDocuSignRecipient | `GenericRecipient__c` | Status of each recipient in a DocuSign envelope | Transactional |

---

## Domain 11: CPQ Rules and Eligibility Objects

| Object Label | API Name | Description | Type |
|---|---|---|---|
| ProductChildItem | `ProductChildItem__c` | Component products in a bundle; added automatically when parent is added to cart | Setup |
| ProductRelationship | `ProductRelationship__c` | Requires/Excludes/Recommends product relationships; independent of bundle hierarchy | Setup |
| ProductEligibility | `ProductEligibility__c` | Marks products as ineligible under certain circumstances (e.g., account type, SLA) | Setup |
| ProductAvailability | `ProductAvailability__c` | Marks products unavailable in specific geographic areas (state, zip code range) | Setup |
| ProductOverrideDefinition | `OverrideDefinition__c` | Identifies overriding child items / attribute assignments for commercial offers | Setup |
| ProductConfigurationProcedure | `ProductConfigurationProcedure__c` | Rule actions that change product choices available during quoting/ordering (hide, require, constrain attributes) | Setup |
| ObjectAppliedResult | `ObjectAppliedResult__c` | Execution results for rules applied against a target object | Transactional |

---

## Domain 12: Pricing and Rating Objects

| Object Label | API Name | Description | Type |
|---|---|---|---|
| PriceList | `PriceList__c` | Top-level price list; base list + child lists inheriting from base | Setup |
| PriceListEntry | `PriceListEntry__c` | Specific price/discount/fee defined within a price list; includes terms, duration, policies | Setup |
| PricingElement | `PricingElement__c` | Definition of a price, charge, fee, discount, tax (e.g., "$50 monthly recurring"); used for rating system integration | Setup |
| PricingPlan | `PricingPlan__c` | Sequenced pricing logic definition; activate by setting DefaultPricingPlan CPQ Configuration | Setup |
| PricingPlanStep | `PricingPlanStep__c` | Steps within a PricingPlan; defines pricing methods called by PricingPlanService | Setup |
| PricingVariable | `PricingVariable__c` | Declared type of price/charge/discount for agile pricing definition | Setup |
| PricingVariableBinding | `PricingVariableBinding__c` | Binds a PricingVariable to a specific field on order/quote/contract line or asset | Setup |

---

## Domain 13: Customer and Party Model Objects

| Object Label | API Name | Description | Type |
|---|---|---|---|
| Party | `Party__c` | Individual, business, government, or household. Every Account, Contact, Household also tracked as Party. Supports B2C, B2B, B2B2C. | Master |
| PartyRelationship | `PartyRelationship__c` | Typed relationships between parties (households, contacts, partners, accounts) with start/end dates; visualized in relationship graph | Master |
| Household | `Household__c` | Affinity group / family / user-defined collection of related parties; useful for B2C family plans | Master |
| Premises | `Premises__c` | Physical location where services are provided; can represent building, floor, or site subdivision | Local Copy |
| PremisesPartyRelationship | `PremisesPartyRelationship__c` | Relationship between premises and a party (owner, tenant, facility manager, legal rep) | Local Copy |
| AccountBalance | `AccountBalance__c` | Historical snapshot of charges, credits, and balance at a point in time; populated from billing system | Local Copy |
| AccountHold | `AccountHold__c` | Hold/freeze on a customer account process (suspension of charging, ordering, collections) | Transactional |
| AccountOffer | `AccountOffer__c` | Product/promotion offered to an account; tracks start date and acceptance date | Transactional |
| AccountDiscount | `AccountDiscount__c` | Standing discount granted to a customer for future purchases within a period | Transactional |
| AccountDiscountItem | `AccountDiscountItem__c` | Item/category to which an AccountDiscount applies; MD child of AccountDiscount | Transactional |
| AccountDiscountPricing | `AccountDiscountPricing__c` | Discount pricing adjustments for an AccountDiscount; MD child of AccountDiscount | Transactional |
| AccountProductRollup | `AccountProductRollup__c` | Stores Product and Category Quantity rollups for Account | Transactional |
| AccountPriceAdjustment | `AccountPriceAdjustment__c` | Specific discount, fee, override price applied to an asset, contract, or billing account | Transactional |
| PaymentMethod | `PaymentMethod__c` | Customer's saved payment method (credit card, bank account); MD child of Account | Master |
| PaymentAdjustment | `PaymentAdjustment__c` | Customer service rep-requested billing adjustment (dispute resolution, write-off) | Local Copy |
| PaymentPlan | `PaymentPlan__c` | Agreed-to payment arrangement for a customer account (e.g., 6-month debt repayment) | Local Copy |

---

## Domain 14: Subscription Management Objects (Post-Order Applied Promotions)

| Object Label | API Name | Description | Type |
|---|---|---|---|
| AppliedPromotion | `AccountAppliedPromotion__c` | Application of a promotion to customer subscriptions/assets; tracks duration, pricing benefits | Transactional |
| AppliedPromotionAffectedAsset | `AccountAppliedPromotionItem__c` | Intersection between AppliedPromotion and an affected Asset | Transactional |
| OfferMigrationPlan | `OfferMigrationPlan__c` | Configured migration path from existing offer(s) to new offer(s) | Local Copy |
| OfferMigrationComponentMapping | `OfferMigrationComponentMapping__c` | Component-level mapping between existing offer component and new offer component; MD child of OfferMigrationPlan | Local Copy |
| LineOfBusiness | `LineOfBusiness__c` | Differentiates business segments (mobile, networking, wholesale) with separate product lines/processes | Setup |

---

## Domain 15: Enterprise Quoting and Order Group Objects (ESM)

Used for Enterprise Sales Management (ESM) — large-scale B2B quotes with thousands of line items.

| Object Label | API Name | Description | Type |
|---|---|---|---|
| OrderGroup | `OrderGroup__c` | Collection of sites/service points within a multi-site order that share similar service configuration | Transactional |
| OrderMember | `OrderMember__c` | Member record of an OrderGroup | Transactional |
| OpportunityGroup | `OpportunityGroup__c` | Collection of service points or service accounts at the opportunity stage | Transactional |
| OpportunityMember | `OpportunityMember__c` | Member record of an OpportunityGroup | Transactional |
| OrderRelationship | `OrderRelationship__c` | Relationship between two orders | Transactional |

---

## Domain 16: Interaction Tracking Objects

| Object Label | API Name | Description | Type |
|---|---|---|---|
| ExpandedInteractionLog | `ExpandedInteractionLog__c` | Normalized version of Console Action Log; tracks user clickstream statistics | Transactional |
| EventDuringInteraction | `EventDuringInteraction__c` | Individual user clickstream event during an Expanded Interaction Log session | Transactional |
| CustomerInteractionTopic | `CustomerInteractionTopic__c` | Topic discussed during a customer interaction (account, asset, case, specific field/charge) | Transactional |

---

---

## Domain 17: B2C-Specific Objects (Consumer / Digital Commerce)

These objects are primarily used in B2C implementations. Most exist in the Vlocity Communications object list but are not prominent in B2B-only implementations.

### Consumer Commerce / Digital Channel Objects

| Object Label | API Name | Description | Model Sub Type |
|---|---|---|---|
| Cart | `Cart__c` | An abandoned shopping cart tracked for a lead, account, or contact. Used to pursue follow-up actions with the prospect or customer. | Transactional |
| Cart Item | `CartItem__c` | An item added to an abandoned shopping cart. Master-detail child of Cart. | Transactional |
| Subscription | `Subscription__c` | A service generally used by one user (or at one location) at a time, governed by a single payment plan. A user becomes a "subscriber" through establishment of their first subscription. | Transactional |

### Retail / Store Location Objects

| Object Label | API Name | Description | Model Sub Type |
|---|---|---|---|
| Site / Store Location | `BusinessSite__c` | Tracks retail stores and customer service locations where consumers can obtain products or services. Located by address and geo-location. Used for store locator on consumer portal. | Setup |
| Site Offering / Store Offering | `BusinessSiteOffering__c` | Describes types of services available at a given retail store (bill payment, equipment return, product availability). | Setup |

### Consumer Billing / Financial Objects

| Object Label | API Name | Description | Model Sub Type |
|---|---|---|---|
| Statement | `Statement__c` | Summaries from billing software imported into Salesforce. Historical billing statements retained here. | Local Copy |
| Statement Line Item | `StatementLineItem__c` | Individual bill line items imported from the billing system. | Local Copy |
| Security Deposit | `SecurityDeposit__c` | Describes the security deposit paid by the consumer customer. | Local Copy |
| Collections Activity | `Dunning__c` | Represents collection activities — late payment reminders, service disconnect notices — for customer or vendor outstanding invoices. Master-detail child of Account. | Transactional |
| Payment Adjustment | `PaymentAdjustment__c` | CSR-requested billing adjustment (dispute resolution, write-off). Approved adjustments feed to billing system. | Local Copy |
| Payment Plan | `PaymentPlan__c` | Agreed payment arrangement for a customer account (e.g., debt repayment over 6 months). | Local Copy |

### Assessment Objects (for B2C onboarding, credit check, eligibility)

| Object Label | API Name | Description | Model Sub Type |
|---|---|---|---|
| Assessment | `Assessment__c` | Assessment of an individual/customer at a given point in time. Also represents templates with questions and possible answers. Used for credit checks, onboarding questionnaires, service qualification forms. | Setup/Transactional |
| Assessment Answer | `AssessmentAnswer__c` | Answer to a given question on an Assessment. | Setup/Transactional |
| Assessment Question | `AssessmentQuestion__c` | Question on an Assessment, including pre-defined answer options. | Setup/Transactional |

### Application / Service Application Objects

| Object Label | API Name | Description | Model Sub Type |
|---|---|---|---|
| Application | `Application__c` | Submission of an application for products or services by an individual, group, or organization (e.g., fiber service application, SIM activation request). | Transactional |
| Application Party Relationship | `ApplicationPartyRelationship__c` | Identifies the party/parties submitting the application. | Transactional |
| Application Template | `ApplicationTemplate__c` | Represents a type of application (form type). | Setup |

### B2C Account Record Types (Key for Segmentation)

The `Account` standard object uses record types in Communications Cloud to differentiate:

| Record Type | Description |
|---|---|
| Individual / Person Account | B2C consumer customer (individual person) |
| Business Account | B2B corporate customer |
| Billing Account | Billing entity for a consumer or business (how services are billed) |
| Service Account | Service location where services are delivered (for fixed-line/fiber) |

> **Note:** Person Accounts (Salesforce standard feature) are commonly used for B2C consumer records instead of the Account + Contact pair. Confirm at discovery whether the customer org uses Person Accounts or Account + Contact for individual consumers.

### B2C Party Model Objects (Already in Domain 13, key for B2C)

| Object | B2C Significance |
|--------|-----------------|
| `Party__c` | Every Account (individual or business) and Contact is also tracked as a Party. Supports B2C and B2B2C. |
| `PartyRelationship__c` | Relationships between consumers (Head of Household, Family Member, etc.); visualized in relationship graph. |
| `Household__c` | Family/affinity group of related parties. Used for family plans, multi-line household management. |
| `PartyRelationshipType__c` | Defines relationship types (e.g., Head of Household, CEO, Board Member). |

### EPC / Catalog Interface Objects (Digital Commerce Compile Data)

| Object | API Name | Description |
|--------|----------|-------------|
| `Spec Template Mapping` | `SpecTemplateMapping__c` | Maps product templates to product specs; used in GoDigital catalog and promotions alignment feature. |
| `Spec Template Attribute Mapping` | `SpecTemplateAttributeMapping__c` | Maps attributes between product templates and specs; used in GoDigital catalog alignment. |
| `CachedAPIResponseOffers` | `CachedAPIResponseOffers__c` | Mapping for codes of offers presented under CacheKey; part of Digital Commerce compile data. |
| `CachedAPIChange` | `CachedAPIChange__c` | Tracks cached dependency objects for compile data change management. |
| `CachedAPIChangeEntry` | `CachedAPIChangeEntry__c` | Logs of recomputation batch jobs against cached API change objects. |
| `CachedAPIMigrate` | `CachedAPIMigrate__c` | Tracks cached dependency objects during cache migration. |
| `CachedKeyMapping` | `CachedKeyMapping__c` | Maps original and recomputed cache keys of CachedAPIResponse entries. |

### Connected Assets Objects

New objects added by the Connected Assets feature:

| Object | Description |
|--------|-------------|
| Actionable Event Orchestration | Configuration record defining type, subtype, execution procedure for asset events |
| `Actionable Orchestration Source Event` | Platform event for publishing inbound asset events from telematics systems |
| `Actionable Orchestration Response Event` | Platform event for subscribing to orchestration execution results |
| Context Definition (Connected Assets) | Defines event payload structure for orchestration input variables |
| Filter and Match Decision Table | Routes events to correct orchestration by type/subtype/category |

---

## Domain 18: Deprecated / Obsolete Objects (Do Not Use)

These objects exist in some orgs but are deprecated in Communications Cloud Spring '21 and later:

| Deprecated Object | API Name | Replacement |
|---|---|---|
| Asset Pricing Adjustment | `AssetPricingAdjustment__c` | Use Account Pricing (`AccountPriceAdjustment__c`) |
| Offer Pricing Component | `OfferPricingComponent__c` | Use Price List Entries |
| Order Item Pricing Adjustment | `OrderItemPriceAdjustment__c` | Use Order Pricing Adjustment |
| Quote Line Item Pricing Adjustment | `QuoteLineItemPricingAdjustment__c` | Use Quote Pricing Adjustment |
| Pricing Component | `PricingComponent__c` | Use Pricing Elements |
| Product Template | `ProductTemplate__c` | Use `Product2` with record type = Product Template |
| Vlocity Context Rule | `ContextRule__c` | Use Vlocity Entity Filters |
| Vlocity Context Ruleset | `ContextRuleset__c` | Use Vlocity Rules |
| ProductAttribXN | `ProductAttribXN__c` | Use `JSONData__c` or `AttributesData__c` on line items |
| Party Association | `Party_Association__c` | Deprecated |

---

## CachedAPIResponse (EPC Compile Data Table)

Central cache table used by Standard Cart-Based APIs.

| Field | Description |
|---|---|
| `Type__c` | Compiled data type (e.g., `compiledAdvancedRule`, `compiledContextRule`, `cartCompiledOfferHierarchy`, `compiledPromotionData`, `cartCompiledPricingData`) |
| `CacheKey__c` | Unique identifier within each type (e.g., Rule ID, Product ID, `EligibilityRules`) |
| `ApiResponse__c` | Compiled JSON payload |

**Query to inspect compiled rules:**
```soql
SELECT Id, Name, CacheKey__c, Type__c FROM CachedAPIResponse__c WHERE Type__c = 'compiledAdvancedRule'
```

**Key compiled type → source objects mapping:**

| Compiled Type | CacheKey Pattern | Source Objects |
|---|---|---|
| `compiledAdvancedRule` | Rule ID or keyword | `Rule__c`, `RuleAction__c`, `EntityFilter__c`, `EntityFilterCondition__c` |
| `compiledContextRule` | Rule ID | `Rule__c`, `EntityFilter__c` |
| `compiledContextDimension` | `contextDimensions` | `ContextMapping__c`, `ContextDimension__c`, `ContextScope__c` |
| `cartCompiledOfferHierarchy` | Product Group Key or mapper name | `Product2`, `ProductChildItem__c`, `PriceListEntry__c`, `CustomObjectMap__c` |
| `compiledPromotionData` | Promotion ID | `Promotion__c`, `PromotionItem__c`, `PriceListEntry__c` |
| `cartCompiledPricingData` | productId;rootProductId;promotionId;pricelistId | `PricingPlan__c`, `PricingPlanStep__c`, `PricingVariable__c`, `PricingVariableBinding__c` |
