---
source: hand-authored + RCA Internal Playbook (May 2025) + Salesforce Developer Data Model Gallery (https://developer.salesforce.com/docs/platform/data-models/guide/revenue-cloud-category.html) + RLM Spring '26 Developer Guide (API 66.0) + Spring '25 RCB Hands On Exercises
cloud: Revenue Cloud
section: data-model
last-updated: 2026-05-10
---

# Revenue Cloud — Data Model

## CPQ Managed Package Objects (SBQQ namespace)

### Quote (`SBQQ__Quote__c`)
- **Purpose:** CPQ quote — replaces native Salesforce Quote for complex pricing
- **Key fields:** `SBQQ__Opportunity2__c`, `SBQQ__Account__c`, `SBQQ__Status__c` (`Draft`, `Approved`, `Presented`, `Rejected`), `SBQQ__SubscriptionTerm__c`, `SBQQ__StartDate__c`, `SBQQ__EndDate__c`, `SBQQ__NetAmount__c`, `SBQQ__GrandTotal__c`
- **Notes:** CPQ Quote is a custom object, not the standard `Quote`. The two coexist in a CPQ org — always clarify which is being used. Standard Quote is typically disabled or hidden when CPQ is active.

### QuoteLine (`SBQQ__QuoteLine__c`)
- **Purpose:** Individual product line on a CPQ Quote
- **Key fields:** `SBQQ__Quote__c`, `SBQQ__Product__c`, `SBQQ__Quantity__c`, `SBQQ__UnitPrice__c`, `SBQQ__ListPrice__c`, `SBQQ__Discount__c`, `SBQQ__NetPrice__c`, `SBQQ__SubscriptionTerm__c`, `SBQQ__BundleRoot__c`, `SBQQ__RequiredBy__c`
- **Notes:** Bundle parent-child relationships use `SBQQ__BundleRoot__c` and `SBQQ__RequiredBy__c`. Never manually insert QuoteLines — always use CPQ API methods (Price Rule evaluation requires CPQ engine).

### Product2 Extensions in CPQ
- CPQ adds key fields to standard `Product2`: `SBQQ__SubscriptionType__c`, `SBQQ__SubscriptionTerm__c`, `SBQQ__BillingFrequency__c`, `SBQQ__BundleComponent__c`, `SBQQ__ProductType__c`
- **Notes:** All CPQ product configuration (options, features, bundle rules) is metadata, not data — configured in Setup > CPQ Configuration.

### Contract
- **API name:** `Contract` (standard Salesforce object extended by CPQ)
- **Purpose:** Executed agreement — generated from an approved CPQ Quote
- **Key fields:** `AccountId`, `StartDate`, `EndDate`, `Status` (`Draft`, `Activated`, `Expired`), `SBQQ__RenewalOpportunity__c`, `SBQQ__RenewalForecast__c`
- **Notes:** Contract activation (Status = `Activated`) triggers Asset and Subscription creation in CPQ. Never activate a Contract without completing the full Quote approval flow.

### Subscription (`SBQQ__Subscription__c`)
- **Purpose:** Tracks each active subscription line from an activated Contract
- **Key fields:** `SBQQ__Account__c`, `SBQQ__Product__c`, `SBQQ__Quantity__c`, `SBQQ__StartDate__c`, `SBQQ__EndDate__c`, `SBQQ__Contract__c`, `SBQQ__SubscriptionEndDate__c`
- **Notes:** Subscriptions are auto-created by CPQ on Contract activation. They are the source records for amendment and renewal quotes. Never manually create or delete Subscription records.

### Order / OrderItem (standard, extended by CPQ)
- **Purpose:** Fulfilled order generated from an Activated Contract
- **Key fields:** `AccountId`, `Contract.Id`, `Status` (`Draft`, `Activated`), `SBQQ__Quote__c`
- **Notes:** In CPQ, the order flow is: Quote → Contract → Order. Order activation triggers billing (if `blng__` Billing package is installed).

## Revenue Lifecycle Management Objects (RLM — platform-native, current product)

RLM uses standard platform objects with no managed package prefix. All objects are native Salesforce standard objects.

### Product Catalog Layer
| Object | Purpose |
|---|---|
| `ProductCatalog` | Top-level catalog container — products belong to a catalog |
| `Product2` | Core product record — extended with RLM-native fields |
| `ProductClassification` | Categorize products; child products inherit classification attributes |
| `ProductAttribute` | Attribute definition (e.g., Region, Edition, Term) |
| `ProductAttributeSet` | Group of attributes assigned to a product or classification |
| `ProductSellingModel` | Defines selling model: One-Time, Evergreen, Termed, Usage-Based |
| `ProductCategory` | Hierarchical product categories for catalog organization |
| `PricingPlan` / `PriceList` | Pricing structure — replaces Pricebook2 in RLM |
| `PriceAdjustmentSchedule` | Volume/tier pricing schedules |

**Key difference from CPQ:** RLM uses Attributes to capture product variations — you don't need a separate SKU per region/edition/term. One product + attributes = many configurations.

### Transaction Layer
| Object | Purpose |
|---|---|
| `Quote` (standard, enhanced) | Sales quote — can exist without an Opportunity |
| `QuoteLineItem` (standard, enhanced) | Quote line — references Product2 and pricing |
| `Order` (standard, enhanced) | Order — can be created directly without a Quote |
| `OrderItem` (standard, enhanced) | Order line |
| `Contract` (standard, enhanced) | Executed agreement — native, no SBQQ extension |
| `Asset` (standard, enhanced) | Customer-owned product instance — source for amendments/renewals |

### Order Orchestration Layer (DRO)
| Object | Purpose |
|---|---|
| `OrderDecomposition` | Breaks an order into fulfillment units per product |
| `FulfillmentOrder` | Downstream fulfillment instruction |
| `OrderOrchestrationPlan` | Defines the DRO swimlane/task sequence |
| `OrderOrchestrationTask` | Individual step in the fulfillment plan |

### Billing Layer (Revenue Cloud Advanced)
| Object | Purpose |
|---|---|
| `BillingSchedule` | Defines when and how a customer is billed |
| `Invoice` (standard) | Customer invoice generated from billing schedule |
| `InvoiceLine` | Line-level invoice detail |
| `PaymentTerm` | Net 30, Net 60, etc. |
| `Payment` | Payment record against invoice |

### RLM Transaction Flow
```
Opportunity (optional)
    │
    └──► Quote ──► QuoteLineItem ──► Product2 (with Attributes)
              │
         (Accepted)
              │
          Contract ──► Asset
              │
            Order ──► OrderItem
              │
     OrderDecomposition (DRO)
              │
       FulfillmentOrder ──► OrderOrchestrationTask
              │
        BillingSchedule
              │
           Invoice ──► InvoiceLine
```

**Note:** RLM and legacy CPQ (`SBQQ__`) are NOT compatible in the same org. Confirm at start of every engagement which product is in scope — they have entirely different data models, APIs, and configuration approaches.

---

## Official ARM/RLM Object Reference (by Domain)

Source: Salesforce Developer Data Model Gallery — Revenue Management  
Reference diagrams: https://developer.salesforce.com/docs/platform/data-models/guide/revenue-cloud-category.html

---

### 1. Product Catalog Management
**Purpose:** Entities and relationships for setting up and managing products, rules, and catalogs.

| Object | Purpose |
|---|---|
| `Product2` | Core product record |
| `ProductCatalog` | Top-level catalog container |
| `ProductCategory` | Hierarchical product categories |
| `ProductClassification` | Tag products; child products inherit attributes from classification |
| `AttributeCategory` | Groups of attributes for UI organisation |
| `AttributeDefinition` | Defines an attribute (e.g., Region, Edition, Term) |
| `AttributePicklist` | Picklist values for an attribute |
| `ProductAttributeDefinition` | Links an attribute to a product |
| `ProductClassificationAttribute` | Links an attribute definition to a classification |
| `ProductRelationshipType` | Defines the type of relationship between two products |
| `ProductRelatedComponent` | Links a product component to a parent product |
| `ProductComponentGroup` | Groups product components within a bundle |
| `ProductDisqualification` | Excludes a product from appearing in certain contexts |
| `ProductQualification` | Qualifies a product for certain contexts |
| `ProductCategoryQualification` | Qualifies an entire category |
| `ProductCategoryDisqualification` | Disqualifies an entire category |
| `ProductSellingModel` | Defines selling model: One-Time, Evergreen, Termed, Usage-Based |
| `ProductSellingModelOption` | Links a selling model option to a product |
| `ProrationPolicy` | Defines how charges are prorated |
| `ProductRampSegment` | Defines ramp pricing segments (e.g., Y1, Y2, Y3) |
| `ProductSpecificationType` | Classifies product specification types |
| `RuntimeCatalogSnapshot` | Snapshot of runtime catalog state for indexing |

---

### 2. Salesforce Pricing
**Purpose:** Entities and relationships for managing pricing processes, including product pricing and calculation and application of discounts.

| Object | Purpose |
|---|---|
| `Pricebook` | Price list container (replaces Pricebook2 in RLM pricing context) |
| `PricebookEntry` | Price of a product in a specific pricebook |
| `PricebookEntryDerivedPricing` | Derived pricing rules for pricebook entries |
| `PriceAdjustmentSchedule` | Volume/tier pricing schedule |
| `PriceAdjustmentTier` | Individual tier within a price adjustment schedule |
| `PriceRevisionPolicy` | Policy for how prices are revised over time |
| `AttributeBasedAdjustment` | Pricing adjustment driven by product attributes |
| `AttributeBasedAdjustmentRule` | Rule that governs attribute-based adjustments |
| `AttributeAdjustmentCondition` | Condition that triggers an attribute adjustment |
| `BundleBasedAdjustment` | Pricing adjustment applied at the bundle level |
| `Costbook` | Cost book for margin calculations |
| `CostbookEntry` | Cost of a product in a cost book |
| `ExpressionSet` | Reusable logical expression for pricing rules |
| `IndexRate` | Index rate for formula-derived pricing |
| `PricingAdjustmentBatchJob` | Batch job for bulk pricing adjustments |
| `PricingAdjustmentBatchJobLog` | Log of pricing adjustment batch runs |
| `PricingAPIExecution` | Log of pricing API calls |
| `PricingProcedureResolution` | Resolves which pricing procedure to execute |
| `PricingProcessExecution` | Execution record of a pricing process run |
| `ProductSellingModel` | (shared with PCM) |

---

### 3. Transaction Management — Quote
**Purpose:** Entities and relationships for managing quotes and quote line items.

| Object | Purpose |
|---|---|
| `Quote` | Sales quote (standard, enhanced for RLM) |
| `QuoteLineItem` | Individual product line on a quote |
| `QuoteLineGroup` | Groups quote lines for display or pricing |
| `QuoteLineDetail` | Extended detail fields on a quote line |
| `QuoteItemTaxItem` | Tax calculation per quote line |
| `QuoteAction` | Action taken on a quote (submit, approve, reject) |
| `QuoteDocument` | Generated document attached to a quote |
| `QuoteRecipientGroup` | Group of recipients for a quote document |
| `QuoteRecipientGroupMember` | Individual member of a recipient group |
| `QuoteProductRecipient` | Product-level recipient assignment |
| `QuoteLineAttribute` | Attribute value captured on a quote line |
| `QuoteLineRelationship` | Relationship between two quote lines (e.g., bundle parent-child) |
| `QuoteLinePriceAdjustment` | Price adjustment applied to a quote line |
| `QuoteLineRateAdjustment` | Rate adjustment for usage-based quote lines |
| `QuoteLineRateCardEntry` | Rate card entry linked to a quote line |
| `QuoteLineItemUsageResourceGrant` | Usage resource grant on a quote line |
| `QuoteLineItemUsageResourcePolicy` | Usage policy applied to a quote line |
| `SalesTransactionType` | Classifies the type of sales transaction |
| `RevenueTransactionErrorLog` | Errors during transaction processing |

---

### 4. Transaction Management — Order
**Purpose:** Entities and relationships for managing Revenue Management orders and order items.

| Object | Purpose |
|---|---|
| `Order` | Fulfilled order (standard, enhanced for RLM) |
| `OrderItem` | Individual order line (standard, enhanced) |
| `OrderItemAdjustmentLineItem` | Price adjustment on an order item |
| `OrderItemAttribute` | Attribute value on an order item |
| `OrderItemDetail` | Extended detail on an order item |
| `OrderItemGroup` | Groups order items |
| `OrderItemRateAdjustment` | Rate adjustment for usage-based order items |
| `OrderItemRateCardEntry` | Rate card entry linked to an order item |
| `OrderItemRecipient` | Recipient assignment at order item level |
| `OrderItemRelationship` | Relationship between order items (bundle) |
| `OrderItemTaxLineItem` | Tax per order item |
| `OrderItemType` | Classifies the type of order item |
| `OrderItemUsageResourceGrant` | Usage resource grant on an order item |
| `OrderItemUsageResourcePolicy` | Usage policy on an order item |
| `OrderAction` | Action taken on an order |
| `OrderDeliveryGroup` | Groups order items for delivery |
| `OrderDeliveryMethod` | Delivery method for an order group |
| `OrderStatusCodes` | Custom status codes for orders |
| `SalesTransactionType` | Classifies sales transaction type |
| `RateCard` | Rate card for usage/consumption pricing |
| `RateCardEntry` | Individual entry in a rate card |

---

### 5. Transaction Management — Contract
**Purpose:** Entities and relationships for tracking and managing contracts in Revenue Management.

| Object | Purpose |
|---|---|
| `Contract` | Executed agreement (standard, enhanced) |
| `AssetContractRelationship` | Links an asset to a contract |
| `ContractItemPrice` | Contracted price for a specific product |
| `ContractItemPriceAdjTier` | Tier-based adjustment on a contract item price |

---

### 6. Transaction Management — Asset
**Purpose:** Entities and relationships for tracking and managing Revenue Management assets (active subscriptions and entitlements).

| Object | Purpose |
|---|---|
| `Asset` | Active subscription or product instance (standard, enhanced) |
| `AssetAction` | Action taken on an asset (amend, renew, cancel) |
| `AssetActionSource` | Source record that triggered the asset action |
| `AssetActionSourcePromotion` | Promotion applied via an asset action |
| `AssetRateAdjustment` | Rate adjustment on an active asset |
| `AssetRateCardEntry` | Rate card entry linked to an asset |
| `AssetRelationship` | Relationship between two assets |
| `AssetStatePeriod` | Time-bounded state of an asset (for asset history) |
| `AssetStatePeriodAttribute` | Attribute value during a specific asset state period |
| `FulfillmentAsset` | Asset created during order fulfillment |
| `FulfillmentAssetAttribute` | Attribute on a fulfillment asset |
| `FulfillmentAssetRelationship` | Relationship between fulfillment assets |
| `OrderAction` | Action on an order that drives an asset change |
| `TransactionUsageEntitlement` | Usage entitlement tied to a transaction |

---

### 7. DRO — Design Time
**Purpose:** Entities for designing the order fulfillment orchestration plan.

| Object | Purpose |
|---|---|
| `FulfillmentWorkspace` | Container for a fulfillment orchestration design |
| `FulfillmentWorkspaceItem` | Item within a fulfillment workspace |
| `FulfillmentStepDefinition` | Defines a single step in the fulfillment plan |
| `FulfillmentStepDefinitionGroup` | Groups fulfillment step definitions |
| `FulfillmentStepDependencyDefinition` | Defines dependencies between steps |
| `FulfillmentStepJeopardyRule` | Rule to flag a step as in jeopardy (SLA breach) |
| `FulfillmentFalloutRule` | Rule to handle step fallout (failure) |
| `FulfillmentTaskAssignmentRule` | Rule to auto-assign fulfillment tasks |
| `ProductFulfillmentDecompositionRule` | Rule to decompose a product into fulfillment units |
| `ProductFulfillmentScenario` | Scenario for product fulfillment (e.g., provisioning) |
| `ProductDecompositionEnrichmentRule` | Enrichment rule applied during decomposition |
| `ProductDecompositionEnrichmentVariableMapping` | Variable mapping for enrichment rules |
| `OrchestrationPlanContextMapping` | Maps context data to the orchestration plan |
| `IntegrationDefinition` | Defines external system integration for a step |
| `FlowDefinition` | Flow invoked during a fulfillment step |
| `RuleSet` | Set of rules applied during orchestration |
| `ValueTransformation` | Transforms a value during orchestration |
| `ValueTransformationGroup` | Groups value transformations |
| `CustomFulfillmentScopeConfig` | Custom scope configuration for fulfillment |

---

### 8. DRO — Fulfillment (Runtime)
**Purpose:** Entities that execute the fulfillment orchestration at runtime.

| Object | Purpose |
|---|---|
| `FulfillmentOrder` | Runtime fulfillment order created from DRO |
| `FulfillmentOrderLineItem` | Line item within a fulfillment order |
| `FulfillmentPlan` | The executed orchestration plan |
| `FulfillmentStep` | Individual step being executed |
| `FulfillmentStepDependency` | Runtime dependency between steps |
| `FulfillmentStepOrchestration` | Orchestration record for a step |
| `FulfillmentStepSource` | Source record that triggered a step |
| `FulfillmentTransaction` | Transaction record for a fulfillment execution |
| `FulfillmentTransactionItem` | Item within a fulfillment transaction |
| `FulfillmentLineAttribute` | Attribute on a fulfillment line |
| `FulfillmentLineRelationship` | Relationship between fulfillment lines |
| `FulfillmentLineSourceRel` | Source relationship for a fulfillment line |
| `OrderItemDetail` | Detailed breakdown of an order item |
| `SalesOrder` | Sales order record in fulfillment context |
| `SalesTransaction` | Sales transaction being fulfilled |

---

### 9. Salesforce Contracts (CLM)
**Purpose:** Entities and relationships for tracking and managing the end-to-end lifecycle of contracts.

| Object | Purpose |
|---|---|
| `Contract` | Standard contract (enhanced with CLM capabilities) |
| `ContractType` | Type classification for contracts |
| `ContractTypeConfig` | Configuration for a contract type |
| `SalesContractLine` | Line item on a contract |
| `DocumentTemplate` | Reusable template for contract document generation |
| `DocumentAuthoredContent` | Authored content within a document |
| `DocumentClause` | Standard or negotiated clause |
| `DocumentClauseSet` | Set of clauses for a contract type |
| `DocumentEnvelope` | eSign envelope for a contract |
| `DocumentRecipient` | Recipient for a document or eSign envelope |
| `DocumentGenerationProcess` | Process record for generating a contract document |
| `ContractDocumentReview` | Review record for a contract document version |
| `ContractDocumentVersion` | Version of a contract document |
| `ClauseCategoryConfiguration` | Configuration for clause categories |
| `Obligation` | Contractual obligation to track |
| `ContextDefinition` | Defines data context available to contract processes |
| `ContextDefinitionMapping` | Maps fields into a context definition |
| `ContextUseCaseMapping` | Maps a context definition to a specific use case |
| `ObjectStateDefinition` | Defines states in a contract lifecycle |
| `ObjectStateTransition` | Allowed transition between states |
| `ObjectStateAction` | Action triggered on state transition |
| `ObjectStateActionDefinition` | Definition of a state transition action |
| `ObjectStateValue` | Current state value of an object |
| `OmniProcess` | OmniStudio process used in CLM flows |

---

### 10. Billing — Invoice
**Purpose:** Configuring billing criteria, payment periods, and payment due dates for generating invoices.

| Object | Purpose |
|---|---|
| `BillingAccount` | Billing-specific account configuration |
| `BillingArrangement` | Groups billing schedules for an account |
| `BillingArrangementLine` | Line within a billing arrangement |
| `BillingSchedule` | Defines when and how charges are billed |
| `BillingPeriodItem` | Individual billing period entry |
| `BillingPolicy` | Policy governing billing behaviour |
| `BillingTreatment` | Treatment rules for billing edge cases |
| `BillingMilestonePlan` | Milestone-based billing plan |
| `BillingBatchScheduler` | Scheduler for batch invoice runs |
| `Invoice` | Customer invoice |
| `InvoiceLine` | Individual line on an invoice |
| `InvoiceAddressGroup` | Groups invoice lines by address |
| `InvoiceBatchRun` | Batch run record for invoice generation |
| `InvoiceBatchDraftToPostedRun` | Batch job to post draft invoices |
| `InvoiceLineRelationship` | Relationship between invoice lines |
| `InvoiceLineTax` | Tax calculated on an invoice line |
| `PaymentSchedule` | Schedule of expected payments |
| `PaymentTerm` | Net 30, Net 60, etc. |
| `ProrationPolicy` | (shared with PCM) |
| `SequencePolicy` | Numbering sequence policy for invoices |
| `TaxTreatment` | Tax treatment for billing |
| `RevenueTransactionErrorLog` | Errors in billing transaction processing |
| `UsageResource` | Usage resource being billed |

---

### 11. Billing — Debit Memo
**Purpose:** Financial transaction debit memos for proper accounting and audit trails.

| Object | Purpose |
|---|---|
| `DebitMemo` | Debit memo document |
| `DebitMemoLine` | Individual line on a debit memo |
| `DebitMemoAddress` | Address associated with a debit memo |
| `DebitMemoLineTax` | Tax on a debit memo line |

---

### 12. Credit Memo
**Purpose:** Credit Memos linked to Invoices to reduce amounts owed or apply as future payment.

| Object | Purpose |
|---|---|
| `CreditMemo` | Credit memo document |
| `CreditMemoLine` | Individual line on a credit memo |
| `CreditMemoAddressGroup` | Address grouping for a credit memo |
| `CreditMemoInvoiceApplication` | Application of a credit memo to an invoice |
| `CreditMemoLineInvoiceLine` | Links a credit memo line to an invoice line |
| `CreditMemoLineTax` | Tax on a credit memo line |
| `SequencePolicy` | Numbering sequence for credit memos |

---

### 13. Payments
**Purpose:** Track and manage customer payments, ensuring proper application to Invoices and monitoring payment status.

| Object | Purpose |
|---|---|
| `Payment` | Payment record |
| `PaymentAuthorization` | Authorization for a payment |
| `PaymentAuthorizationAdjustment` | Adjustment to a payment authorization |
| `PaymentBatchRun` | Batch run for payment processing |
| `PaymentBatchRunCriteria` | Criteria for a payment batch run |
| `PaymentGateway` | Payment gateway configuration |
| `PaymentGatewayLog` | Log of gateway transactions |
| `PaymentGatewayProvider` | Gateway provider (Stripe, Adyen, etc.) |
| `PaymentGroup` | Groups related payments |
| `PaymentLineInvoice` | Links a payment to an invoice |
| `PaymentLineInvoiceLine` | Links a payment to a specific invoice line |
| `PaymentMethod` | Stored payment method (card, ACH) |
| `PaymentProviderPaymentMethodType` | Type of payment method supported by provider |
| `PaymentRetryRule` | Rule for retrying failed payments |
| `PaymentRetryRuleSet` | Set of retry rules |
| `PaymentSchedule` | Schedule of expected payments |
| `PaymentScheduleDistributionMethod` | How payment schedule distributions are calculated |
| `PaymentScheduleItem` | Individual item in a payment schedule |
| `PaymentSchedulePolicy` | Policy governing payment schedules |
| `PaymentScheduleTreatment` | Treatment rules for payment schedule edge cases |
| `PaymentScheduleTreatmentDetail` | Detail of a payment schedule treatment |
| `Refund` | Refund record |
| `RefundLinePayment` | Links a refund to a payment |
| `SavedPaymentMethod` | Saved/tokenised payment method |
| `CollectionPlan` | Collections plan for overdue accounts |
| `CollectionPlanItem` | Individual item in a collections plan |

---

### 14. Billing — Accounting
**Purpose:** Record and manage financial transactions related to Invoices, Payments, and Credit Memos, including journal entries connected to general ledger accounts.

| Object | Purpose |
|---|---|
| `LegalEntity` | Legal entity for multi-entity billing |
| `LegalEntityAccountingPeriod` | Accounting period for a legal entity |
| `AccountingPeriod` | Fiscal accounting period |
| `GeneralLedgerAccount` | GL account |
| `GeneralLedgerAccountAssignmentRule` | Rule to auto-assign GL accounts to transactions |
| `GeneralLedgerAccountPeriodSummary` | Period summary of GL account activity |
| `GeneralLedgerJournalEntryRule` | Rule governing journal entry creation |
| `TransactionJournal` | Journal entry record |
| `Credit` | Credit entry in the journal |
| `Debit` | Debit entry in the journal |
| `Record` | Generic record reference in accounting context |
| `Reference` | Reference record in accounting context |

---

### 15. Rate Management
**Purpose:** Calculating and managing consumption-based rates and rate adjustments for products and usage resources.

| Object | Purpose |
|---|---|
| `RateCard` | Rate card defining consumption prices |
| `RateCardEntry` | Individual entry in a rate card |
| `PricebookRateCard` | Links a rate card to a pricebook |
| `RatingFrequencyPolicy` | Policy defining how often usage is rated |
| `RatingRequest` | Request to rate a usage event |
| `RatingRequestBatchJob` | Batch job for rating requests |
| `AssetRateAdjustment` | Rate adjustment on an active asset |
| `AssetRateCardEntry` | Rate card entry linked to an asset |
| `AttributeBasedAdjustmentRule` | Attribute-driven rate adjustment rule |
| `RateAdjustmentByAttribute` | Rate adjustment by a specific attribute value |
| `RateAdjustmentByTier` | Rate adjustment by usage tier |
| `ResourceGrantMap` | Maps resource grants to rate cards |
| `UnitOfMeasureClass` | Class grouping units of measure |
| `UnitOfMeasureUnit` | Individual unit of measure |

---

### 16. Usage Management
**Purpose:** End-to-end usage management for usage-based products and usage resources.

| Object | Purpose |
|---|---|
| `UsageResource` | Defines a billable usage resource (e.g., API calls, GB storage) |
| `UsageResourcePolicy` | Policy governing usage resource behaviour |
| `UsageResourceBillingPolicy` | Billing policy for a usage resource |
| `UsageCommitmentPolicy` | Commitment policy for usage (minimum commit) |
| `UsageOveragePolicy` | Policy for handling overages |
| `UsageGrantRenewalPolicy` | Policy for renewing usage grants |
| `UsageGrantRolloverPolicy` | Policy for rolling over unused usage grants |
| `UsageBillingPeriodItem` | Billing period item for usage charges |
| `UsageRatableSummary` | Aggregated summary of ratable usage |
| `UsageRatableSummaryCommitmentAssetRate` | Commitment rate for a ratable summary |
| `UsageSummary` | Summary of usage for a period |
| `UsageEntitlementAccount` | Account-level usage entitlement |
| `UsageEntitlementBucket` | Bucket grouping of entitlements |
| `UsageEntitlementEntry` | Individual usage entitlement entry |
| `TransactionUsageEntitlement` | Usage entitlement tied to a transaction |
| `ProductUsageGrant` | Usage grant defined on a product |
| `ProductUsageResource` | Usage resource defined on a product |
| `ProductUsageResourcePolicy` | Usage resource policy on a product |
| `TransactionJournal` | Journal entry for usage transactions |

## Key CPQ Relationships

```
Opportunity
    │
    └──► SBQQ__Quote__c ──► SBQQ__QuoteLine__c ──► Product2
                │
           (Approved)
                │
            Contract ──► SBQQ__Subscription__c
                │
              Order ──► OrderItem
                │
          (if Billing)
                │
         blng__Invoice__c ──► blng__InvoiceLine__c
```

---

## RCB Key Object Field Reference (Spring '26 / API 62.0+)

### BillingPolicy
Core billing configuration object. Links to Products and determines invoice generation behaviour.
- `Name` — unique billing policy name
- `Status` — `Draft` | `Active` | `Inactive` (must be Active before use)
- `DefaultBillingTreatmentId` — lookup to BillingTreatment; used when no legal entity match
- `Description` — optional
- **Activation rule:** BillingTreatmentItems → BillingTreatment → BillingPolicy (strict order)

### BillingTreatment
A set of rules determining how an OrderItem is billed. Each Policy can have multiple Treatments.
- `Name`, `BillingPolicyId`, `LegalEntityId` (optional — for legal-entity-specific routing)
- `Status` — `Draft` | `Active` | `Inactive`
- `ExcludeFromBilling` — set `true` to suppress billing schedule creation for this treatment
- `EnableMilestoneBilling` — `true` enables milestone-based billing (One-Time products only)

### BillingTreatmentItem
Line-level rules within a Billing Treatment. Controls advance/arrears timing and amounts.
- `BillingType` — `Advance` | `Arrears` | `None`
  - **Advance:** billed on/before order product start date (e.g., prepaid)
  - **Arrears:** billed after start date (e.g., postpaid)
- `Type` — `Percentage` | `FlatAmount` | `Remainder`
- `Percentage` — 0–100%. Only 100% Percentage BTIs are processed (current release)
- `ZeroAmountBehavior` — required field; set `Create Invoice`
- `Controller` — `Billing Schedule Group` (determines which BSG fields override BS fields)
- `Status` — `Draft` | `Active`

### BillingSchedule
Runtime object auto-created on Order activation for each OrderItem with an active BillingPolicy.
- `OrderItemId` — parent order item
- `BillingPolicyId`, `BillingTreatmentId`
- `BillingType` — mirrors BTI billing type
- `BillingTermUnit` — `One-Term` (one-time) | `Monthly` | `Annual` | `Semi-Annual`
- **Do not manually create BillingSchedules** — they are generated by Context Service via the Billing Context Definition

### BillingScheduleGroup (BSG)
Groups one or more BillingSchedules for consolidated invoicing.
- `BillingTermUnit` — reflects the product charge type
- `Status` — `Active` | `Suspended` | `Cancelled`
- **Suspend/Resume Billing:** BSGs can be individually suspended; use `/commerce/invoicing/actions/suspend-billing` and `resume-billing`

### Invoice
- `Status` — `Draft` | `Posted` | `Cancelled` | `Error`
- `BillingAccountId` — the billing account being invoiced
- `InvoiceDate`, `DueDate` (calculated from PaymentTerm)
- `TotalAmount`, `Balance`
- `LegalEntityId` — required for multi-entity orgs
- **Cannot edit a Posted invoice** — use void → rebill or credit memo

### InvoiceLine
- `InvoiceId`, `OrderItemId`, `BillingScheduleId`
- `ChargeAmount`, `TaxAmount`, `TotalAmount`
- `Type` — `Charge` | `Tax` | `Credit`

### CreditMemo
- `Status` — `Draft` | `Posted` | `Applied` | `Cancelled`
- `CreditMemoDate`, `TotalAmount`, `Balance`
- `LegalEntityId`
- Created from: (a) negative invoice lines (auto, via billing setting), (b) standalone API, (c) Create-and-Apply API

### TaxPolicy
- `Status` — `Draft` | `Active` | `Inactive`
- `TreatmentSelection` — `Default` | `LegalEntity` | `Manual`
  - `Default`: all BSGs get the DefaultTreatmentId
  - `LegalEntity`: BSGs get the TaxTreatment matching their legal entity
  - `Manual`: you specify the treatment per BSG
- After activating a TaxPolicy, certain fields become read-only

### TaxTreatment
- `IsTaxable` — `true` triggers external tax engine call
- `TaxCode` — passed to external tax engine
- `TaxEngineId` — required when IsTaxable = true
- `ShouldUseTaxTreatmentItems` — `true` uses per-product TaxCode from TaxTreatmentItems (API 66.0+)

### LegalEntity
- Acts as the anchor for billing, tax, and accounting treatments
- Required before creating any Tax or Billing treatments that use legal-entity routing
- Each LegalEntity has its own `LegalEntityAccountingPeriod` records
- **Best practice:** create LegalEntity first, even if not using tax integrations yet

### GeneralLedgerAccount (API 63.0+)
- `AccountingCode` — unique code matching ERP chart of accounts
- `AccountingType` — `Asset` | `Liability`
- Used for debit/credit entries in the Dual Transaction Journal
- Covers: invoice lines, invoice line taxes, credit memo lines, credit memo taxes

### GeneralLedgerAccountAssignmentRule
- Links transaction type + legal entity to GL accounts (debit + credit)
- Supports multiple rules per transaction type; priority order determines which applies
- Transaction types: invoice, invoice line, credit memo, credit memo line, payment, tax

### PaymentTerm
- `Status` — `Draft` | `Active` | `Inactive`
- Cannot activate without at least one related `PaymentTermItem`
- Cannot change from Inactive → Draft

### PaymentTermItem
- `Type` — `Period-Based` (Invoice + N Days) | `Derive End of Month and Add Period` (EOM)
- `Period` + `PeriodUnit` — duration (e.g., 30 days = Net 30)
- `PaymentTimeline` — `Standard` (only one per PaymentTerm)

### BillingAccount (extended BillingAccount object)
Key RCB-specific fields (API 63.0+):
- `BillDayOfMonth` — 1–31, sets billing date (API 64.0+)
- `BillToContactId` — contact for invoice delivery (API 64.0+)
- `BillingSuspensionDate` / `BillingResumptionDate` — for suspend/resume
- `IsDefaultBillingProfile` — default profile flag (API 65.0+)
- `PaymentTermId` — payment term for this account (API 64.0+)
- `SavedPaymentMethodId` — for automatic payment collection (API 65.0+)
- `DoesSkipAutomaticPayments` — skip auto payment schedule creation (API 65.0+)
- `InvoiceDocumentTemplateId` — per-account PDF template (API 66.0+)
- `TaxIdentificationNumber`, `TaxExemptionNumber`, `TaxExemptionStatus`, `TaxExemptionExpirationDate` — (API 66.0+)

### BillingArrangement / BillingArrangementLine (API 66.0+)
Used when a single transaction's invoice amount needs to be split across multiple billing accounts.
- `BillingArrangementLine.BillingAccountId` — target billing account
- `BillingArrangementLine.Percentage` — portion invoiced to this account
- Each BillingArrangementLine results in a separate invoice

---

## RCB Runtime Object Flow

```
Order (Activated)
    │
    └── OrderItem (with BillingPolicy)
            │
     [Context Service — BillingContext Definition]
            │
     BillingScheduleGroup (BSG)  ←── BillingPolicy / BillingTreatment
            │
     BillingSchedule(s)  ←── BillingTreatmentItem (Advance/Arrears)
            │
     [Invoice Batch Run / Invoice Scheduler / Bill Now]
            │
         Invoice  ←── PaymentTerm (due date)
            │           └── LegalEntity
         InvoiceLine  ←── TaxTreatment → TaxEngine
            │
     [Post Invoice]
            │
     TransactionJournal  ←── GeneralLedgerAccountAssignmentRule
         ├── Debit entry  → GL Account (AR)
         └── Credit entry → GL Account (Revenue / Tax Liability)
```

**Key runtime constraint:** Invoice generation is driven by `BillingBatchScheduler` (scheduled runs) or on-demand via the `/commerce/invoicing/invoices/collection/actions/generate` API ("Bill Now"). Both methods respect the BillingBatchFilterCriteria.

---

## Billing Objects API Version Quick Reference

| Object | Min API Version |
|---|---|
| AccountingPeriod | 62.0 |
| BillingArrangement / BillingArrangementLine | 66.0 |
| BillingBatchScheduler | 62.0 |
| BillingMilestonePlan / BillingMilestonePlanItem | 63.0 |
| BillingSchedule / BillingScheduleGroup | 62.0 |
| CreditMemo + lines | 62.0 |
| DebitMemo + lines | 65.0 |
| GeneralLedgerAccount | 63.0 |
| Invoice / InvoiceLine | 62.0 |
| InvoiceDocument | 63.0 |
| LegalEntity | 62.0 |
| LegalEntityAccountingPeriod | 62.0 |
| PaymentSchedule / PaymentSchedulePolicy | 64.0 |
| PaymentRetryRuleSet | 66.0 |
| TaxTreatmentItem | 66.0 |
| TransactionJournal | 62.0 |
