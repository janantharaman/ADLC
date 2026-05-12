---
source: Salesforce E&U Developer Guide (Atlas TOC, Summer '26); Vlocity Communications Object List Spring '21; EPC Guide; Order Management docs; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: data-model
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Data Model

## Architecture Pattern

E&U Cloud data model is an **additive layer** on top of the standard Salesforce data model. Standard objects (Account, Contact, Asset, Order, Product2, etc.) are extended with `vlocity_cmt__` namespace fields. Industry-specific objects are entirely new managed objects.

All custom fields and objects carry the `vlocity_cmt__` namespace prefix. In source control, `%vlocity_namespace%__` is the placeholder replaced at deployment time.

---

## Standard Salesforce Objects Extended by E&U

| Object | Key E&U Extensions |
|---|---|
| `Account` | Supports business, consumer, service, billing, and aggregator sub-types via Object Type framework; multi-party household and B2B2C support |
| `Asset` | Extended for Asset-Based Ordering (ABO); asset state management; lifecycle transitions |
| `AssetRelationship` | Non-hierarchical asset relationships (peer-to-peer, hierarchical) |
| `Contact` | Party relationship linkage |
| `Order` | Extended for ABO; Order Groups for multi-site; recurring/overage charges on line items |
| `OrderItem` | Extended with recurring charges, installation dates, overage amounts |
| `Opportunity` | Extended for ABO; multi-site Opportunity Groups |
| `OpportunityLineItem` | Extended with recurring/overage charges |
| `Quote` | Extended with Vlocity fields; multi-site Quote Groups |
| `QuoteLineItem` | Extended with installation dates, recurring charges, overage |
| `Product2` | Extended for EPC; selling period dates (EffectiveDate/EndDate); lifecycle states |
| `Pricebook2` | Extended with Price List hierarchy |
| `PricebookEntry` | Extended with recurring/overage charges |
| `Contract` | Extended for CLM; version management |

---

## E&U-Specific Standard Objects (from Developer Guide — Summer '26)

The E&U Developer Guide documents 63 standard objects across these domains:

### Billing & Account Domain
| Object | Description |
|---|---|
| `AccountBillingAccount` | Junction between Account and BillingAccount |
| `BillingAccount` | Billing account record; may aggregate multiple service accounts |
| `BillingAccountContact` | Contact associated with a billing account |
| `BalanceAdjustmentRequest` | Request to adjust account balance |

### Energy Service Domain
| Object | Description |
|---|---|
| `EnergyServiceAgreement` | Master service agreement for energy supply |
| `EnergyServiceAgreementItem` | Line item on an energy service agreement |
| `ServicePoint` | Physical entry point for services to premises; separately metered; key for fixed-line energy/utility services |

### Programs & Benefits Domain
| Object | Description |
|---|---|
| `Program` | Energy efficiency or assistance program definition |
| `ProgramEnrollment` | Customer enrollment in a program |
| `ProgramProduct` | Products associated with a program |
| `ProgramApplnFormTemplate` | Form template for program applications |
| `IndividualApplication` | Individual's application to a program |
| `IndividualApplicationItem` | Line item on an individual application |
| `PreliminaryApplicationRef` | Reference for pre-qualification before full application |
| `ApplicationFormTemplate` | Template defining application form structure |
| `Benefit` | Benefit record (shared with Nonprofit Cloud Program Management) |
| `BenefitAssignment` | Assignment of benefit to individual |
| `BenefitDisbursement` | Disbursement event for a benefit |
| `BenefitType` | Type/category of benefit |
| `BenefitSchedule` | Schedule defining when benefits are disbursed |
| `BenefitSession` | Session record for benefit delivery |
| `CaseProgram` | Junction between Case and Program |

### Usage & Measurement Domain
| Object | Description |
|---|---|
| `UsageImpactFactor` | Individual factor contributing to usage impact |
| `UsageImpactGroup` | Group of usage impact factors for a program measure |
| `UsageImpactGroupFactor` | Junction: UsageImpactGroup ↔ UsageImpactFactor |
| `UsageImpactGroupPgmMeasure` | Program measure linked to a usage impact group |
| `UsageImpactGroupVersion` | Version of a usage impact group |
| `IndicatorAssignment` | Assignment of a KPI indicator to a record |

### Workforce / Field Service Domain
| Object | Description |
|---|---|
| `TimeSheet` | Timesheet header for a service resource's work period |
| `TimeSheetEntry` | Entry within a timesheet (day/shift) |
| `TimeSheetEntryItem` | Detailed item within a timesheet entry (task/activity) |
| `TimeSheetValidationError` | Validation error on a timesheet entry |
| `TimeSheetWageTypeSummary` | Summary of wage types on a timesheet |
| `AssetTimesheet` | Junction: Asset ↔ TimeSheet (asset serviced during timesheet period) |
| `WorkOrder` | Field work order |
| `WorkOrderLineItem` | Line item on a work order |
| `WorkReport` | Report generated after work order completion |
| `WorkReportLineItem` | Line item on a work report |
| `WorkReportError` | Error recorded on a work report |
| `ServiceResource` | Field service technician or crew |
| `ServiceResourceCostRule` | Cost rule applied to a service resource (hourly rate, overtime) |
| `ServiceResourceLeaveBalance` | Leave balance for a service resource |
| `ResourceAbsence` | Absence record for a service resource |

### Compensation & HR Domain
| Object | Description |
|---|---|
| `PayGrade` | Grade level determining base compensation |
| `PayGroup` | Group of employees sharing pay processing rules |
| `PayPeriod` | Pay period definition (weekly, biweekly, monthly) |
| `PayType` | Type of payment (regular, overtime, shift differential) |
| `OvertimeApprover` | Designated approver for overtime requests |
| `OvertimeType` | Type of overtime (daily OT, weekly OT, double time) |
| `DifferentialShift` | Shift with differential pay (night shift, weekend) |
| `SupplementalCompensation` | Additional compensation above base (bonus, hazard pay) |
| `LaborUnion` | Union membership and contract terms |
| `JobExpenseType` | Expense category for job-related expenses |
| `CostCenter` | Organizational cost center for budget allocation |

### Budget Domain
| Object | Description |
|---|---|
| `Budget` | Budget header for a period/program |
| `BudgetCategory` | Category within a budget |
| `BudgetCategoryValue` | Allocated value for a budget category |
| `BudgetPeriod` | Time period for a budget |

### Shared / Address Domain
| Object | Description |
|---|---|
| `Address` | Standardized address record |
| `Location` | Physical location (meter site, depot, warehouse) |
| `CaseRelatedSubject` | Links a case to a subject entity |
| `OpportunityProductRecipient` | Recipient of a product in an opportunity |
| `WorkType` | Type of work for field service scheduling |

---

## vlocity_cmt Managed Objects (Full Catalog)

### Account / Party Objects
| API Name | Description |
|---|---|
| `vlocity_cmt__AccountBalance__c` | Historical billing snapshot; local copy from billing system |
| `vlocity_cmt__AccountDiscount__c` | Standing discount for future purchases |
| `vlocity_cmt__AccountDiscountItem__c` | Item-level child of Account Discount |
| `vlocity_cmt__AccountDiscountPricing__c` | Pricing adjustments on Account Discount |
| `vlocity_cmt__AccountHold__c` | Freeze/suspension on account process |
| `vlocity_cmt__AccountOffer__c` | Product/promotion offered to account |
| `vlocity_cmt__AccountPriceAdjustment__c` | Discount/fee/override per asset or billing account |
| `vlocity_cmt__AccountProductRollup__c` | Product and category quantity rollups for Account |
| `vlocity_cmt__Party__c` | Master party record; B2C, B2B, B2B2C |
| `vlocity_cmt__PartyRelationship__c` | Typed relationships between parties |
| `vlocity_cmt__PartyRelationshipType__c` | Defines source/target relationship types |
| `vlocity_cmt__Household__c` | Family/affinity group grouping |
| `vlocity_cmt__AccountAppliedPromotion__c` | Active promotion applied to assets/contracts |
| `vlocity_cmt__AccountAppliedPromotionItem__c` | Junction: promotion ↔ asset |

### Premises & Service Point (EU-Specific)
| API Name | Description |
|---|---|
| `vlocity_cmt__Premises__c` | Complex/building where services are delivered; energy/utility service location |
| `vlocity_cmt__PremisesPartyRelationship__c` | Owner/tenant/facility manager relationship to premises |

**Note:** `ServicePoint` is a standard E&U object (no namespace). It is "useful for fixed line services including energy and utility services" — key linking Account → Premises → ServicePoint.

### CPQ / Quote / Order Objects
| API Name | Description |
|---|---|
| `vlocity_cmt__Cart__c` | Abandoned shopping cart |
| `vlocity_cmt__CartItem__c` | Master-detail child of Cart |
| `vlocity_cmt__QuoteAppliedPromotion__c` | Promotion applied to quote |
| `vlocity_cmt__QuoteAppliedPromotionItem__c` | Junction object |
| `vlocity_cmt__QuoteDiscount__c` | Quote-level discount |
| `vlocity_cmt__QuoteDiscountItem__c` | Child of Quote Discount |
| `vlocity_cmt__QuoteDiscountPricing__c` | Child of Quote Discount Pricing |
| `vlocity_cmt__QuoteGroup__c` | Multi-site quote grouping |
| `vlocity_cmt__QuoteLineItemRelationship__c` | Dependency/upgrade relationships between QLIs |
| `vlocity_cmt__QuotePricingAdjustment__c` | Specific price adjustments on quote |
| `vlocity_cmt__QuoteProductRollup__c` | Product and category rollups for Quote |
| `vlocity_cmt__QuoteMember__c` | Member record of Quote group |
| `vlocity_cmt__OpportunityAppliedPromotion__c` | Promotion request on opportunity |
| `vlocity_cmt__OpportunityDiscount__c` | Opportunity-level discount |
| `vlocity_cmt__OpportunityGroup__c` | Multi-site grouping for opportunity |
| `vlocity_cmt__OpportunityMember__c` | Member record |
| `vlocity_cmt__OpportunityLineItemRelationship__c` | Dependency/upgrade between OLIs |
| `vlocity_cmt__OrderAppliedPromotion__c` | Promotion applied on order |
| `vlocity_cmt__OrderAppliedPromotionItem__c` | Junction |
| `vlocity_cmt__OrderDiscount__c` | Order-specific discount |
| `vlocity_cmt__OrderGroup__c` | Site/service-point grouping in order |
| `vlocity_cmt__OrderMember__c` | Member record |
| `vlocity_cmt__OrderPayment__c` | Payment event from payment gateway |
| `vlocity_cmt__OrderItemRelationship__c` | Dependency/upgrade relationships |
| `vlocity_cmt__OrderProductRollup__c` | Product and category rollups |
| `vlocity_cmt__OrderRelationship__c` | Relationship between two orders |
| `vlocity_cmt__OrderPriceAdjustment__c` | Price adjustments on order |
| `vlocity_cmt__OrderAsyncOperationEvent__e` | Platform Event for async order operations |
| `vlocity_cmt__OrderUpdate__e` | Platform Event for OM+ status updates |

### Product / Catalog Objects
| API Name | Description |
|---|---|
| `vlocity_cmt__ProductChildItem__c` | Bundle component definitions |
| `vlocity_cmt__ProductRelationship__c` | requires/excludes/recommends rules |
| `vlocity_cmt__ProductRelationshipType__c` | Types of product relationships |
| `vlocity_cmt__ProductAvailability__c` | Geographic availability exclusions |
| `vlocity_cmt__ProductEligibility__c` | Eligibility rules |
| `vlocity_cmt__OverrideDefinition__c` | Commercial offer overrides of spec attributes |
| `vlocity_cmt__ProductConfigurationProcedure__c` | CPQ rule actions for attribute changes |
| `vlocity_cmt__Catalog__c` | Container for products; hierarchical |
| `vlocity_cmt__CatalogProductRelationship__c` | Associates product with catalog |
| `vlocity_cmt__CatalogRelationship__c` | Associates category with parent catalog |
| `vlocity_cmt__Attribute__c` | Product/account/contact attribute definition |
| `vlocity_cmt__AttributeCategory__c` | Grouping for attributes |
| `vlocity_cmt__AttributeAssignment__c` | Assignment of attribute to object/product |
| `vlocity_cmt__AttributeAssignmentRule__c` | Auto-assign attributes under conditions |
| `vlocity_cmt__AttributeBinding__c` | Binds attribute to a specific Salesforce field |
| `vlocity_cmt__CompiledAttributeOverride__c` | JSON net of all attribute overrides |
| `vlocity_cmt__PriceList__c` | Base/child price list hierarchy |
| `vlocity_cmt__PriceListEntry__c` | Specific price per product per price list |
| `vlocity_cmt__PricingElement__c` | Definition of charge/discount (for rating) |
| `vlocity_cmt__PricingPlan__c` | Sequenced CPQ pricing logic definition |
| `vlocity_cmt__PricingPlanStep__c` | Step within a pricing plan |
| `vlocity_cmt__PricingVariable__c` | Declared price/charge type for agile pricing |
| `vlocity_cmt__PricingVariableBinding__c` | Binds pricing variable to line item field |
| `vlocity_cmt__Promotion__c` | Promotional pricing definition |
| `vlocity_cmt__PromotionItem__c` | Product included/applicable in promotion |
| `vlocity_cmt__ChargeMeasurement__c` | Usage-based charge unit (kWh, therms, gallons, etc.) |

### Order Management / Orchestration Objects
| API Name | Description |
|---|---|
| `vlocity_cmt__FulfilmentRequest__c` | Order to a backend/fulfillment system |
| `vlocity_cmt__FulfilmentRequestLine__c` | Line item in a fulfillment request |
| `vlocity_cmt__FulfilmentRequestDecompRelationship__c` | Decomposition relationship for fulfillment |
| `vlocity_cmt__OrchestrationPlan__c` | Assembled fulfillment plan for a specific order |
| `vlocity_cmt__OrchestrationPlanDefinition__c` | Template defining tasks needed for a scenario |
| `vlocity_cmt__OrchestrationItem__c` | Actual task instance |
| `vlocity_cmt__OrchestrationItemDefinition__c` | Task definition |
| `vlocity_cmt__OrchestrationItemRelationship__c` | Relationships between orchestration items |
| `vlocity_cmt__OrchestrationItemSource__c` | Source for an orchestration item |
| `vlocity_cmt__OrchestrationDependency__c` | Runtime dependency between task instances |
| `vlocity_cmt__OrchestrationDependencyDefinition__c` | Controls execution order between task definitions |
| `vlocity_cmt__OrchestrationScenario__c` | Maps action+sub-action+product to a plan definition |
| `vlocity_cmt__OrchestrationQueue__c` | Processing stream/queue for tasks |
| `vlocity_cmt__OrchestrationQueueAssignmentRule__c` | Rules for assigning items to queues |
| `vlocity_cmt__ManualQueue__c` | Work queue for manual tasks |
| `vlocity_cmt__ManualQueueMember__c` | Assigns users to manual queues |
| `vlocity_cmt__DecompositionRelationship__c` | Maps commercial product to technical product |
| `vlocity_cmt__ItemImplementation__c` | Registration of custom Apex for a fulfillment task |
| `vlocity_cmt__ErrorCode__c` | Error code definition |
| `vlocity_cmt__ErrorCodeNamespace__c` | Namespace grouping for error codes |
| `vlocity_cmt__InventoryItem__c` | Inventory item record |
| `vlocity_cmt__InventoryItemDecompositionRelationship__c` | Decomposition for inventory items |

### Billing / Statement Objects (Local Copies from External CIS)
| API Name | Description |
|---|---|
| `vlocity_cmt__Statement__c` | Billing statement header |
| `vlocity_cmt__StatementLineItem__c` | Line item on a billing statement |
| `vlocity_cmt__PaymentAdjustment__c` | Payment adjustment event |
| `vlocity_cmt__PaymentMethod__c` | Payment method on file |
| `vlocity_cmt__PaymentPlan__c` | Payment installment plan |
| `vlocity_cmt__SecurityDeposit__c` | Security deposit record |
| `vlocity_cmt__Dunning__c` | Collections/dunning activity |
| `vlocity_cmt__Jurisdiction__c` | Regulatory jurisdiction |

### CLM / Document Objects
| API Name | Description |
|---|---|
| `vlocity_cmt__ContractGroup__c` | Contract group container |
| `vlocity_cmt__ContractLineItem__c` | Contract line item |
| `vlocity_cmt__ContractVersion__c` | Versioned contract document |
| `vlocity_cmt__ContractTerm__c` | Term/clause on a contract |
| `vlocity_cmt__ContractType__c` | Contract type configuration |
| `vlocity_cmt__DocumentTemplate__c` | Template for document generation |
| `vlocity_cmt__DocumentClause__c` | Reusable clause in document templates |
| `vlocity_cmt__VlocityDocuSignTemplate__c` | DocuSign envelope template |
| `vlocity_cmt__VlocityDocuSignBranding__c` | DocuSign branding configuration |

### Calculation Objects (for Pricing Rules and Matrices)
| API Name | Description |
|---|---|
| `vlocity_cmt__CalculationMatrix__c` | Decision matrix for pricing/eligibility rules |
| `vlocity_cmt__CalculationMatrixColumn__c` | Column definition in a matrix |
| `vlocity_cmt__CalculationMatrixRow__c` | Row in a calculation matrix |
| `vlocity_cmt__CalculationMatrixVersion__c` | Version of a calculation matrix |
| `vlocity_cmt__CalculationProcedure__c` | Multi-step calculation procedure |
| `vlocity_cmt__CalculationProcedureStep__c` | Step in a calculation procedure |
| `vlocity_cmt__CalculationProcedureVariable__c` | Variable used in a calculation procedure |
| `vlocity_cmt__CalculationProcedureVersion__c` | Version of a calculation procedure |

### Platform Events
| API Name | Description |
|---|---|
| `vlocity_cmt__OrderAsyncOperationEvent__e` | Async order processing events |
| `vlocity_cmt__OrderUpdate__e` | OM+ order status updates |
| `vlocity_cmt__VlocityTrackingEvent__e` | OmniStudio/UI analytics tracking events |

---

## Key Relationship Diagrams

### Energy Service Relationship
```
Account
  └── BillingAccount (AccountBillingAccount junction)
  └── Premises (vlocity_cmt__Premises__c)
        └── ServicePoint (standard)
              └── EnergyServiceAgreement
                    └── EnergyServiceAgreementItem
```

### Program Enrollment Relationship
```
Program
  └── ProgramProduct (products covered)
  └── ProgramEnrollment (customer enrolled)
        └── IndividualApplication
              └── IndividualApplicationItem
        └── Benefit → BenefitAssignment → BenefitDisbursement
```

### Order Orchestration Relationship
```
Order
  └── OrderGroup (multi-site)
        └── OrderMember
  └── OrderItem
        └── OrderItemRelationship (dependency/upgrade)
  └── FulfilmentRequest
        └── FulfilmentRequestLine
              └── OrchestrationPlan
                    └── OrchestrationItem (tasks)
                          └── ManualQueue (manual tasks)
```

### CPQ Object Hierarchy
```
Catalog
  └── CatalogRelationship (category hierarchy)
  └── CatalogProductRelationship → Product2
        └── ProductChildItem (bundles)
        └── ProductRelationship (requires/excludes)
        └── AttributeAssignment → Attribute (AttributeCategory)
PricingPlan
  └── PricingPlanStep
        └── PriceList → PriceListEntry → Product2
        └── CalculationMatrix / CalculationProcedure
```

---

## OmniStudio Object Names

| Legacy (Managed) | Current (Unmanaged / Spring '22+) |
|---|---|
| `vlocity_cmt__OmniScript__c` | `OmniProcess` |
| `vlocity_cmt__Element__c` | `OmniProcessElement` |
| `vlocity_cmt__VlocityCard__c` | `OmniUiCard` |
| `vlocity_cmt__DRBundle__c` | `OmniDataTransform` |
| Integration Procedure | `OmniProcess` with `IsIntegrationProcedure = true` |

---

## Deprecated Objects (Do Not Use)

`ContextRule__c`, `ContextRuleset__c`, `ProductTemplate__c`, `PricingComponent__c`, `PromotionApplicableProduct__c`, `PromotionPricingAlteration__c`, `OrderItemPriceAdjustment__c`, `AssetPricingAdjustment__c`, `LargeDataStore__c`

---

## SOQL Reference

```soql
-- Account → BillingAccount → ServicePoint
SELECT Id, Name,
    (SELECT Id, vlocity_cmt__BillingAccount__r.Name
     FROM AccountBillingAccounts)
FROM Account
WHERE Id = :accountId

-- Active Energy Service Agreements for a premises
SELECT Id, Name, Status,
    ServicePoint.Name, ServicePoint.vlocity_cmt__Premises__r.Name
FROM EnergyServiceAgreement
WHERE ServicePoint.vlocity_cmt__Premises__r.vlocity_cmt__Account__c = :accountId
AND Status = 'Active'

-- Program enrollments for a customer
SELECT Id, Name, Status__c,
    Program.Name, Program.vlocity_cmt__Type__c
FROM ProgramEnrollment
WHERE AccountId = :accountId

-- Open orchestration items (manual tasks)
SELECT Id, Name, Status,
    vlocity_cmt__OrchestrationPlan__r.vlocity_cmt__Order__r.OrderNumber,
    vlocity_cmt__ItemImplementation__r.Name
FROM vlocity_cmt__OrchestrationItem__c
WHERE Status = 'Open'
AND vlocity_cmt__ManualQueue__c != null
ORDER BY CreatedDate ASC
```
