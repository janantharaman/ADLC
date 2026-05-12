---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); TMF620 Product Catalog Management API User Guide v4.1.0; Salesforce Alignment with TM Forum (June 2025); B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: api-reference
last-updated: 2026-05-10
---

# Communications Cloud — API Reference

## API Architecture Overview

Communications Cloud exposes two API layers:

1. **Inbound TM Forum Industry APIs** — External systems call INTO Salesforce Communications Cloud using TM Forum-aligned REST APIs
2. **Outbound MuleSoft Direct Integrations** — Salesforce Communications Cloud calls OUT to external BSS/OSS systems via pre-built MuleSoft templates

### Access Methods (as of Spring '26)

| Method | Description | Status |
|--------|-------------|--------|
| MuleSoft Gateway | Route API calls through MuleSoft endpoints | Deprecated from Winter '27 |
| Direct Access | Connect/Apex REST endpoints directly on Salesforce | Recommended; only option from Winter '27 |

---

## Inbound TM Forum Industry APIs

### Endpoint URL Format

```
[Domain]/[TMF API code]/[API version]/[Resource type]
```

### Domain Names by Region/Environment

| Environment | Domain |
|-------------|--------|
| US Production | `api.commscloud.salesforce.com` |
| US Sandbox | `api.commscloud.salesforce.com/sandBox/` |
| EU Production | `eu.api.commscloud.salesforce.com` |
| EU Sandbox | `eu.api.commscloud.salesforce.com/sandBox/` |

> Additional data centers are planned for future releases (as of Spring '26).

### Authorization

All API calls use OAuth 2.0. Three-step flow:
1. A connected app on behalf of the client app requests access to a REST API resource
2. An authorizing server grants access tokens to the connected app
3. The resource server validates access tokens and approves access to the protected REST API resource

### Complete TM Forum Inbound API List

| API Code | Version | Name | Key Salesforce Objects |
|----------|---------|------|----------------------|
| TMF620 | v4 | Product Catalog Management | `Product2`, `vlocity_cmt__Catalog__c`, `vlocity_cmt__PriceListEntry__c` |
| TMF621 | v4 | Trouble Ticket Management | `Case`, `CaseComment`, `ContentDocument` |
| TMF621 | v5 | Trouble Ticket Management (v5) | `Case`, `CaseTroubleTicket` |
| TMF622 | v4 | Product Ordering | `Order`, `OrderItem`, `vlocity_cmt__OrderItemRelationship__c` |
| TMF622 | v5 | Product Ordering (v5) | `Order`, `OrderItem`, `OrderDeliveryGroup` |
| TMF629 | v4 | Customer Management | `Account`, `Contact`, `Contract` |
| TMF637 | v4 | Product Inventory Management | `Asset` |
| TMF648 | v4 | Customer Quote Management | `Quote`, `QuoteLineItem` |
| TMF651 | v4 | Agreement Management | `Contract`, `DocumentTemplate` |
| TMF667 | v4 | Document Management | `ContentDocument`, `ContentVersion` |
| TMF671 | v4 | Promotion Management | `vlocity_cmt__Promotion__c` |
| TMF679 | v5 | Product Offering Qualification Management | `Product2`, `Account`, `ProductCategory` |

---

## Detailed API: TMF620 — Product Catalog Management (v4)

### Supported Resources and Operations

| Resource | GET | POST | PATCH | DELETE |
|----------|-----|------|-------|--------|
| Catalog | Yes | Yes | — | — |
| Category | Yes | Yes | — | — |
| ProductSpecification | Yes | Yes | — | — |
| ProductOffering | Yes | Yes | — | — |
| ProductOfferingPrice | Yes | — | — | — |

### Key Salesforce Field Mappings (ProductOffering → Product2)

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `name` | `Product2.Name` |
| `description` | `Product2.Description` |
| `productNumber` | `Product2.ProductCode` |
| `lifecycleStatus` | `Product2.vlocity_cmt__Status__c` |
| `isBundle` | `Product2.vlocity_cmt__specificationSubType__c` |
| `isSellable` | `Product2.vlocity_cmt__IsOrderable__c` |
| `validFor.startDateTime` | `Product2.vlocity_cmt__SellingStartDate__c` |
| `validFor.endDateTime` | `Product2.vlocity_cmt__EndOfLifeDate__c` |
| `version` | `Product2.vlocity_cmt__VersionLabel__c` |
| `id` (resource key) | `Product2.vlocity_cmt__GlobalKey__c` |
| `productOfferingPrice` | `vlocity_cmt__PriceListEntry__c` |
| `bundledProductOffering` | `vlocity_cmt__ProductChildItem__c` |
| `productOfferingRelationship` | `vlocity_cmt__ProductRelationship__c` |
| `prodSpecCharValueUse` | `vlocity_cmt__AttributeAssignment__c` |
| `attachment` | `vlocity_cmt__VlocityAttachment__c` |

### Required Configuration for TMF620
- `vlocity_cmt__PriceList__c` — must configure valid price list in metadata (`VlocityIntegrationSetting__mdt`)
- `vlocity_cmt__AttributeCategory__c` — must configure valid attribute category in metadata
- Default Attribute Category pre-created and configured for use with TMF620

### Attribute-Based Pricing Note
Attribute-based pricing is NOT handled by TMF620 specification — requires custom extensions.

---

## Detailed API: TMF622 — Product Ordering (v4)

### Supported Operations
- GET ProductOrder
- POST ProductOrder

### Key Salesforce Field Mappings (v4)

| TMF Field | Salesforce Mapping |
|-----------|-------------------|
| `id` | `Order.OrderNumber` |
| `description` | `Order.Description` |
| `externalId` | `Order.OrderReferenceNumber` |
| `requestedCompletionDate` | `Order.vlocity_cmt__RequestedCompletionDate__c` |
| `requestedStartDate` | `Order.vlocity_cmt__RequestedStartDate__c` |
| `orderDate` | `Order.CreatedDate` |
| `channel` | `Order.vlocity_cmt__OriginatingChannel__c` |
| `note` | `Order.vlocity_cmt__Notes__c` |
| `state` | `Order.Status` |
| `relatedParty` | `Account` |
| `vlocity_cmt__PriceList__c` | Price list field (mandatory, requires valid EPC setup) |
| `productOrderItem.action` | `OrderItem.vlocity_cmt__Action__c` |
| `productOrderItem.quantity` | `OrderItem.Quantity` |
| `productOrderItem.state` | `OrderItem.vlocity_cmt__FulfilmentStatus__c` |
| `productOrderItem.orderLineItemId` | `OrderItem.Id` |
| `productCharacteristic` | `OrderItem.vlocity_cmt__JSONAttribute__c` |
| `productOffering.name` | `Product2.Name` |
| `productOffering.id` | `Product2.ProductCode` |

---

## Detailed API: TMF622 — Product Ordering (v5)

### Key Changes vs v4
- `externalId` replaced by `ExternalIdentifier` sub-resource (`PoNumber`/`OrderReferenceNumber`)
- `relatedParty` uses new `partyOrPartyRole` sub-resource structure
- `expectedCompletionDate` maps to `OrderDeliveryGroup.PromisedDeliveryDate`
- `productOrderItem.id` maps to `OrderItem.OrderItemNumber`
- `itemPrice` sub-resource includes `priceAlteration` with discount support
- `quoteItem` reference links to `QuoteLineItemId`
- `periodBoundary`, `periodBoundaryDay`, `PeriodBoundaryStartMonth` fields added

### v5 Constraints
- Tax calculation is asynchronous — order cannot be activated until tax calculation is complete
- PATCH not supported for RLM APIs (blocking tax-calculation workflow)
- Orders auto-transition Draft → Activated via placeOrder API
- Unsupported fields: `completionDate`, `priority`, `requestedCompletionDate`, `channel`, `note`, `category`, `billingAccount`, `itemTerm`, `itemTotalPrice`

---

## Detailed API: TMF629 — Customer Management (v4)

### Supported Resources

| Resource | Operations |
|----------|------------|
| Customer (Account) | GET, POST |
| EngagedParty (Contact) | GET, POST |
| AgreementRef (Contract) | GET |

### Key Salesforce Field Mappings

| TMF Field | Salesforce Object | Salesforce Field |
|-----------|------------------|-----------------|
| `id` | Account | `Account.Id` |
| `name` | Account | `Account.Name` |
| `href` | Account | BaseUrl + Id |
| `referredType` | Account | `Account.RecordTypeId.Name` |
| `engagedParty.id` | Contact | `Contact.Id` |
| `engagedParty.name` | Contact | `Contact.LastName` |
| `contactMedium.email` | Contact | `Contact.Email` |
| `contactMedium.phone` | Contact | `Contact.Phone` |
| `contactMedium.fax` | Contact | `Contact.Fax` |
| `agreementRef.id` | Contract | `Contract.ContractNumber` |

---

## Detailed API: TMF637 — Product Inventory Management (v4)

### Key Salesforce Field Mappings (Product/Asset)

| TMF Field | Salesforce Field | Notes |
|-----------|-----------------|-------|
| `id` | `Asset.vlocity_cmt__AssetReferenceId__c` | Mandatory |
| `name` | `Asset.Name` | |
| `description` | `Asset.Description` | |
| `status` | `Asset.vlocity_cmt__ProvisioningStatus__c` | Mandatory by TMF |
| `isBundle` | `Asset.Product2.vlocity_cmt__specificationSubType__c` | |
| `isCustomerVisible` | `Asset.Product2.vlocity_cmt__IsOrderable__c` | |
| `productSerialNumber` | `Asset.SerialNumber` | |
| `startDate` | `Asset.ActivationDate` | |
| `terminationDate` | `Asset.LifecycleEndDate` | Requires LifecycleManagement license |
| `productCharacteristic` (V1) | `Asset.vlocity_cmt__JSONAttribute__c` | |
| `productCharacteristic` (V2) | `Asset.AttributeSelectedValues__c` | |
| `relatedParty` | `Asset.AccountId` | |
| `billingAccount` | `Asset.vlocity_cmt__BillingAccountId__c` | |
| `productOrderItem` | `Asset.vlocity_cmt__OrderProductId__c` | |

---

## Detailed API: TMF648 — Customer Quote (v4)

### Key Constraints
- By default, an Opportunity is mandatory for quote creation (auto-created with name `TMF Opportunity_%TIMESTAMP%`)
- Quote name auto-populated as `TMF Quote_%TIMESTAMP%`
- PriceList configured via metadata: `VlocityIntegrationSetting__mdt.TMForumPriceList`
- `PricebookEntry` ID fetched using product's `GlobalGroupKey__c`
- RelatedParty requires `AccountId` with Status "Active" and Active "Yes"

### SLA Constraint
"If 648 POST is expected as a synchronous call — API time limit/SLA of 3s is not achievable"

### Unsupported Features (TMF648 v4)
- Quote versioning
- `InstantSyncQuote` (error if set true)
- Child/sub-level products (only parent-level supported)
- QuoteLineItem quantity other than 1
- Actions other than "add"
- `PriceAlteration`, `Amount`, `Price`, `quoteTotalPrice/quoteItemPrice`, `state`, `validFor`, `effectiveQuoteCompletionDate`, `id`, `href`, `quoteDate` fields in POST body

### Key Field Mappings (Quote)

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `id` | `Quote.QuoteNumber` |
| `state` | `Quote.Status` |
| `quoteDate` | `Quote.CreatedDate` |
| `category` | `Quote.Type` |
| `quoteTotalPrice` | `Quote.vlocity_cmt__EffectiveOneTimeTotal__c` / `vlocity_cmt__EffectiveRecurringTotal__c` |
| `quoteItem.id` | `QuoteLineItem.LineNumber` |
| `quoteItem.action` | `QuoteLineItem.vlocity_cmt__Action__c` |
| `quoteItem.quantity` | `QuoteLineItem.Quantity` |
| `quoteItem.product.id` | `Product2.vlocity_cmt__GlobalGroupKey__c` |
| `quoteItem.productOffering.id` | `Product2.Id` |
| `quoteItemPrice` | `QuoteLineItem.vlocity_cmt__EffectiveBaseOneTimeTotal__c` / `vlocity_cmt__EffectiveBaseRecurringTotal__c` |
| `priceAlteration` | `vlocity_cmt__QuotePricingAdjustment__c.vlocity_cmt__Promotion__c` |
| `quoteItemRelationship.id` | `vlocity_cmt__QuoteLineItemRelationship__c.vlocity_cmt__RelatedQuoteLineItemId__c` |

---

## Detailed API: TMF651 — Agreement Management (v4)

### Supported Operations

| Resource | GET | POST | PATCH |
|----------|-----|------|-------|
| AgreementSpecification (DocumentTemplate) | Yes | Yes | Yes |
| Agreement (Contract) | Yes | Yes | Yes |

### Patchable Agreement Attributes
`description`, `engagedParty`, `associatedAgreement`, `agreementSpecification`, `agreementItem`

### Prerequisites
- DocGen OrgPerm enabled
- DocGenDesigner addon license
- AgreementSpecification name must be unique

### Key Mappings (Agreement → Contract)

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `name` | `Contract.Name` |
| `agreementType` | `Contract.ContractType` |
| `status` | `Contract.Status` |
| `documentNumber` | `Contract.ContractNumber` |
| `initialDate` | `Contract.CustomerSignedDate` |
| `statementOfIntent` | `Contract.Description` |
| `associatedAgreement` | `Contract.ParentContractId` |
| `engagedParty` | `Contract.AccountId` |

---

## Detailed API: TMF667 — Document Management (v4)

### Operations
- GET Document
- POST Document (URL upload only)

### Key Field Mappings

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `id` | `ContentVersion.ContentVersionId` |
| `name` | `ContentVersion.Title` |
| `description` | `ContentVersion.Description` |
| `creationDate` | `ContentVersion.CreatedDate` |
| `lastUpdate` | `ContentVersion.LastModifiedDate` |
| `status` | `ContentVersion.PublishStatus` |
| `attachment.url` | `ContentVersion.contentUrl` |

### Constraints
- Only URL upload supported in POST method
- `documentType` auto-populates as `LINK`
- Full-word search filtering for name attribute only

---

## Detailed API: TMF671 — Promotion Management (v4)

### Key Field Mappings (Promotion → vlocity_cmt__Promotion__c)

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `id` | `Promotion.PromotionCode` |
| `name` | `Promotion.Name` |
| `description` | `Promotion.Description` |
| `startDateTime` | `Promotion.StartDateTime` |
| `endDateTime` | `Promotion.EndDateTime` |
| `lifecycleStatus` | `Promotion.IsActive` |
| `pattern.id` | `promotionConfiguration → rules[index] → ruleName` |
| `pattern.priority` | `promotionConfiguration → rules[index] → priority` |
| `criteriaGroup.groupName` | `eventConfiguration → criteriaList → name` |
| `criteriaGroup.criteriaLogicalRelationship` | `eventConfiguration → criteriaList → customLogic` |
| `criteriaParameter` | `eventConfiguration → criteriaList → conditionList → contextTagName` |
| `criteriaOperator` | `eventConfiguration → criteriaList → conditionList → operator` |
| `criteriaValue` | `eventConfiguration → criteriaList → conditionList → valueList[0]` |
| `actionType` | `rewardConfiguration → type / rewardDetails → discountType` |
| `actionValue` | `rewardDetails → discountValue / voucherDefinition → id` |

---

## Detailed API: TMF679 — Product Offering Qualification (v5)

### Supported Operations
- POST CheckProductOfferingQualification
- GET QueryProductOfferingQualification

### Critical Behavior
"Only Id values are considered — details such as product name, category name, and related party name are ignored" during qualification processing.

### Key Mappings

| TMF Field | Salesforce Object | Salesforce Field |
|-----------|------------------|-----------------|
| `productOffering.id` | Product2 | Id |
| `relatedParty.id` | Account | Id |
| `category.id` | ProductCategory | Id |

---

## Detailed API: TMF621 — Trouble Ticket (v4 and v5)

### v4 Key Mappings

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `id` | `Case.CaseNumber` |
| `name` | `Case.Subject` |
| `description` | `Case.Description` |
| `priority` | `Case.Priority` |
| `status` | `Case.Status` |
| `severity` | `Case.vlocity_cmt__severity__c` |
| `ticketType` | `Case.Type` |
| `creationDate` | `Case.CreatedDate` |
| `resolutionDate` | `Case.ClosedDate` |
| `channel` | `Case.Origin` |
| `note.text` | `CaseComment.CommentBody` |

### v5 Additional Fields (CaseTroubleTicket extension)

| TMF Field | Salesforce Field |
|-----------|-----------------|
| `expectedResolutionDate` | `CaseTroubleTicket.expectedResolutionDate` |
| `requestedResolutionDate` | `CaseTroubleTicket.RequestedResolutionDate` |
| `externalId` (ExternalIdentifier sub-resource) | `CaseTroubleTicket.externalId` |

### v5 Prerequisites
- Enable FLS for all Case fields per user profile
- Create picklist values: Severity, TicketType, Status, Priority, Origin
- Org permissions: CommsCloud, Cases required

---

## Notification Framework (CDC-Based Outbound)

### Overview
The Notification Framework is included in the Communications Cloud base SKU. It uses Change Data Capture (CDC) to fire outbound TM Forum-aligned notifications to external systems.

### Key Characteristics
- CDC entity limit of 5 does NOT apply to the Notification Framework (bypassed)
- No subscription limits on CDC events via this framework
- Supports custom objects + specified standard Salesforce objects
- Configuration requires: Resource API Name, Resource Field API Names, Integration Provider Definition, Change Event Type

### Field-Level CDC
- Customers can select specific fields via Integration Provider Definition Mapping
- Field-level CDC applicable only for update change event type

### Related Party Notifications (TMF632)
Currently supported trigger: `AccountContactRelation` changes linked to Contacts trigger TMF 632 notifications on association or update events.

### Required Configuration Objects

| Configuration Item | Purpose |
|-------------------|---------|
| Resource API Name | The Salesforce object to monitor |
| Resource Field API Names | Specific fields to track for update events |
| Integration Provider Definition | Maps CDC events to notification payloads |
| Change Event Type | Insert, Update, Delete, Undelete |
| `IntegrationProviderDefinition__mdt` | Custom Metadata record per resource |

---

## Outbound MuleSoft Direct Integration APIs

### Available Outbound Integration Templates

| API Code | Name | Supported Operations | Notes |
|----------|------|---------------------|-------|
| TMF620 | Product Catalog Management | POST Offer, PATCH Offer | Publishes product offers from Salesforce to external systems |
| TMF622 | Product Ordering Management | POST only | May require customizations for full compatibility with external systems |
| TMF641 | Service Order Management | POST, PATCH, GET | Service order creation, updates, retrieval with notifications |
| TMF645 | Service Qualification | POST | Checks service availability at customer location |
| TMF673 | Geographic Address Management | POST | Validates geographic address data |
| TMF674 | Geographic Site Management | POST | Manages sites as geographic addresses or map-based locations |
| TMF675 | Geographic Location Management | POST | Handles locations with accuracy and spatial references |

### Setup Requirements
1. Purchase a MuleSoft Anypoint Platform instance
2. Accept terms and enable access (consent process)
3. Deploy integration assets using Industry Integration Solutions
4. Customize integration app for specific external system requirements
5. Connect Salesforce and MuleSoft instances (`sf.connect_to_mulesoft_instance.htm`)

---

## Industries CPQ API Patterns

### Quote-to-Order Flow (programmatic)
1. Create `Opportunity` (required)
2. POST to TMF648 or use CPQ guided flow to create `Quote` + `QuoteLineItem` records
3. `Quote.Status` transitions: Draft → Approved → Accepted
4. Call placeOrder to convert quote to `Order` + `OrderItem`
5. `Order.Status` transitions: Draft → Activated

### Product Pricing Lookup
- `PricebookEntry` ID fetched via product's `GlobalGroupKey__c`
- Price list configured via `VlocityIntegrationSetting__mdt.TMForumPriceList`
- `vlocity_cmt__PriceListEntry__c` drives pricing display and calculation

### DataRaptor / Integration Procedure Extension Points
TMF620 extensions use:
1. **Integration Procedures** — workflow automation and system connectivity
2. **Data Raptors** — data transformation and mapping
3. **Apex Interfaces** — programmatic extension points
4. **Custom Metadata** — configuration-driven customizations without code
5. **Resource Mappings** — define how TMF resources align with system objects

### Static Resource Import (TMFOpenAPIs)
- Requires Salesforce API version 58.0 or later
- Requires IDX Workbench with repository
- Download `TMFOpenAPIs` static resource from Setup → Static Resources
- Import via IDX Workbench selecting "Vlocity Types: All" and "Salesforce Types: All"
- Included datapacks: TMF620 v4, TMF621 v4, TMF622 v4, TMF629 v4, TMF648 v4, TMF637 v4

---

## TMF620 Product Catalog Management API — Detailed Spec (v4.1.0)

Source: TM Forum Specification TMF620 v4.1.0 (Team Approved, April 2021)

### Entity Lifecycle States

The TMF620 standard defines a formal lifecycle for catalog entities (Catalog, Category, ProductOffering, ProductSpecification):

| State | Description |
|-------|-------------|
| In Study | Initial state; macro conception started |
| In Design | Conception accepted; design in progress |
| In Test | Design approved; under testing |
| Active | Validated and tested; not yet available to customers |
| Launched | Available for purchase; customers can buy |
| Rejected | Test failed; final state (cannot recover) |
| Retired | End of marketing reached; cannot be sold to new customers, but existing customers may still hold it |
| Obsolete | No customers hold the element; can be removed from catalog |

**Salesforce mapping:** `Product2.vlocity_cmt__Status__c` maps to lifecycle status. Typical values: Draft → Active → Launched (Active + IsOrderable) → Retired.

### Characteristic-Based vs Schema-Based Product Definition

TMF620 supports two complementary models for defining product attributes:

| Approach | Description | Salesforce Equivalent |
|----------|-------------|----------------------|
| **Characteristic-based** | Attributes defined dynamically as name-value pairs with metadata (type, cardinality, allowed values) | `vlocity_cmt__Attribute__c` + `vlocity_cmt__AttributeAssignment__c` |
| **Schema-based** | Attributes defined as explicit JSON schema fields; schema-based extensions using `@schemaLocation` | Custom fields on `Product2` or custom Object Types |

**JSON polymorphism support:** TMF620 uses `@type`, `@baseType`, `@referredType`, and `@schemaLocation` attributes to support polymorphic collections and extension patterns. These can be used when consuming or producing TMF620 API payloads.

### TMF620 Sample Use Cases (Standard Catalog API Use Cases)

| Use Case | Description |
|----------|-------------|
| UC1 — Partner Catalog Sync | Partner updates catalog; notifies distributor; distributor requests export via `POST /exportJob`; retrieves at provided URL |
| UC2 — Incremental Notification | Partner pushes catalog change batch notifications; distributor updates local copy |
| UC3 — Duration Query | Administrator retrieves product offering effective dates by ID: `GET /productOffering/{ID}` |
| UC4 — Bundle Browse | Administrator retrieves all bundled product offerings in a bundle: `GET /productOffering` |
| UC5 — Lifecycle Update | Administrator updates lifecycle status: `PATCH /productOffering` (e.g., Launched → Retired) |
| UC6 — Order Capture Lookup | Distributor browses catalog during order capture; retrieves offerings by category, channel, place with `GET /depth` |
| UC7 — Price Retrieval | Distributor retrieves prices for a given offering: `GET /productOffering` with depth |
| UC8 — Availability Check | Distributor checks if offering available at customer location: `GET /productOffering` |

### Full TMF620 API Operations Summary (v4.1.0)

| Resource | Supported Operations |
|----------|---------------------|
| Catalog | GET (list), GET (retrieve), POST (create), PATCH, DELETE |
| Category | GET (list), GET (retrieve), POST (create), PATCH, DELETE |
| ProductOffering | GET (list), GET (retrieve), POST (create), PATCH, DELETE |
| ProductOfferingPrice | GET (list), GET (retrieve), POST (create), PATCH, DELETE |
| ProductSpecification | GET (list), GET (retrieve), POST (create), PATCH, DELETE |
| ImportJob | GET (list), GET (retrieve), POST (create), DELETE |
| ExportJob | GET (list), GET (retrieve), POST (create), DELETE |

> **Salesforce Communications Cloud note:** The Salesforce TMF620 implementation supports: GET Catalog, POST Catalog, GET Category, POST Category, GET ProductOffering, POST ProductOffering, GET ProductOfferingPrice. PATCH and DELETE are NOT all supported — verify current Salesforce implementation against the full TM Forum spec when designing integrations.

### TMF620 Notification Events (Outbound)

The standard defines the following notification event types. Salesforce implements outbound notifications via the Notification Framework (CDC-based):

| Event | Trigger |
|-------|---------|
| CatalogCreateEvent | Catalog record created |
| CatalogAttributeValueChangeEvent | Catalog attribute updated |
| CatalogStateChangeEvent | Catalog lifecycle status changed |
| CatalogDeleteEvent | Catalog record deleted |
| CategoryCreateEvent / AttributeValueChangeEvent / StateChangeEvent / DeleteEvent | Category lifecycle events |
| ProductOfferingCreateEvent / AttributeValueChangeEvent / StateChangeEvent / DeleteEvent | Product Offering lifecycle events |
| ProductOfferingPriceCreateEvent / AttributeValueChangeEvent / StateChangeEvent / DeleteEvent | Price lifecycle events |
| ProductSpecificationCreateEvent / AttributeValueChangeEvent / StateChangeEvent / DeleteEvent | Product Spec lifecycle events |

### Import/Export Job Resources (Bulk Catalog Operations)

TMF620 v4.1.0 includes `ImportJob` and `ExportJob` resources for bulk catalog operations:
- `POST /importJob` — Initiate bulk import of catalog data
- `POST /exportJob` — Initiate export of a catalog; returns URL for retrieval
- `DELETE /importJob/{id}` / `DELETE /exportJob/{id}` — Cancel jobs

These are particularly relevant for B2C implementations where an external PIM or catalog system must sync large product sets.

### Lifecycle Management Extensions (Versioning)

TMF620 v4.1.0 defines Lifecycle Management extensions for versioned catalog resources:

| Operation | Endpoint |
|-----------|---------|
| Query all versions | `GET /catalogManagement/v4/productOfferingVersion` |
| Query specific version | `GET /catalogManagement/v4/productOfferingVersion/{id}` |
| Query current version | `GET /catalogManagement/v4/productOffering/{id}/currentVersion` |
| Create new version | `POST /catalogManagement/v4/productOffering/{id}/version` |
| Modify existing version | `PATCH /catalogManagement/v4/productOfferingVersion/{id}` |

---

## TM Forum Open API Roadmap (Full Vision)

The Salesforce Communications Cloud TM Forum API roadmap (as of June 2025) covers:

### Delivered APIs (Spring '26 / API 260 and earlier)

**Inbound:** TMF620, TMF621 (v4 + v5), TMF622 (v4 + v5), TMF629, TMF637, TMF648, TMF651, TMF667, TMF671, TMF679

**Outbound:** TMF620, TMF622, TMF641, TMF645, TMF673, TMF674, TMF675

**Outbound Notifications:** TMF621, TMF622, TMF651, TMF637, TMF629, TMF632

### In Progress (Spring '26 — API 260)

- TMF629 (Inbound) with Extensibility Framework enhancements
- MuleSoft Gateway bypass capability for TMF Inbound APIs (Direct Access)

### Planned Roadmap (API 262+)

| API | Direction | Description |
|-----|-----------|-------------|
| TMF699 | Inbound | Sales Management |
| TMF646 | Inbound | Appointment Booking |
| TMF666 | Inbound | Account Management |
| TMF632 | Inbound | Party Management |
| TMF769 | Inbound | Product Test |
| TMF678 | Outbound | Customer Bill Management |
| TMF640 | Outbound | Service Activation |
| TMF653 | Outbound | Service Test Management |
| TMF663 | Inbound + Outbound | Shopping Cart |
| TMF683 | Inbound + Outbound | Party Interactions |
| TMF669 | Inbound + Outbound | Party Role Management |

### TM Forum Certification Map

| TM Forum Framework | Certified Products |
|---|---|
| eTOM Process Framework v22.0 | Industries CPQ, Industries Order Management |
| SID Information Framework v22.0 | Enterprise Product Catalog (EPC) |
| Open Digital Architecture (ODA) | Communications Cloud (Ready for ODA, 2024) |
| Open API — GOLD Badge | Communications Cloud (2025) |
