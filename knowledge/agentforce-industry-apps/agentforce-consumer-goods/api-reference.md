---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: api-reference
last-updated: 2026-05-11
---

# Consumer Goods Cloud — API Reference

## TPM Business APIs (REST)

TPM REST APIs are workflow-based. All mutation endpoints require a `workflow` integer (the Business Object API workflow to execute) in v55+.

### Promotions Ingest (POST)

**Endpoint:** `/services/apexrest/cgcloud/v1/promotions/ingest`

**Parameters:**

| Name | Type | Required | API Version | Description |
|---|---|---|---|---|
| `workflow` | Integer | Yes | v55 | Promotion Business Object API workflow name |
| `importId` | Integer | No | v55 | Import transaction ID; if not passed a new one is created |
| `salesOrg` | SalesOrgName | No | v55 | Sales organization |
| `promotions` | List\<Object\> | Yes | v55 | List of promotion payloads. Max 50 items |

**Sample request:**
```json
{
  "workflow": "Create",
  "importId": "12345678-1234-1234-1234-123456789012",
  "salesOrg": "0001",
  "promotions": [
    {
      "AnchorAccount": "CS_Atlanta",
      "PromotionTemplate": "Customer Promotion",
      "Comment": "New promo",
      "Slogan": "Summer Sale",
      "DateFrom": "2024-01-01",
      "DateThru": "2024-12-31",
      "PlacementDateFrom": "2024-03-01",
      "PlacementDateThru": "2024-04-30",
      "DeliveryDateFrom": "2024-08-01",
      "DeliveryDateThru": "2024-09-30",
      "OrderDateFrom": "2024-06-01",
      "OrderDateThru": "2024-07-30",
      "CommitDate": "2024-01-10",
      "ProductFilter": {
        "Criteria": {
          "Category": ["Snacks", "Beverages"],
          "Brand": ["Empower_Cola", "HiChoc"]
        }
      },
      "ManualInputs": [
        {"KPI": "ProPlanTotalVolume", "Value": 900000}
      ],
      "Tactics": [
        {
          "Amount": 2500,
          "CompensationModel": "PerCase",
          "DateFrom": "2024-05-01",
          "DateThru": "2024-07-30",
          "InStoreDateFrom": "2024-05-01",
          "InStoreDateThru": "2024-07-15",
          "TacticTemplate": "PriceReduction"
        }
      ]
    }
  ]
}
```

### Promotions Import Status

Returns status of a promotion import by `importId`. Used to poll import completion for async workflows.

---

## Response Bodies

| Body | Description |
|---|---|
| `Recommendation Decisions Output` | Details of recommendation decision processed for input recommendations |
| `Save Recommendation Decision Details` | Details of a recommendation decision |
| `Save Recommendation Decision Status` | Status of the save recommendation decision |
| `Begin Promotion Import Output` | Output of promotion import request |
| `Promotion Import Output` | Output of promotion import output request |
| `Import Status Output` | Import status details |

---

## cgcloud Apex Namespace

### cgcloud.RE_Order Class

Provides programmatic access to the retail order sObject and its related sObjects during the order save process.

```apex
cgcloud.RE_Order orderWrapper = (cgcloud.RE_Order) params.get('order');
```

| Method | Signature | Returns | Description |
|---|---|---|---|
| `getOrder()` | `global RE_Order.Record getOrder()` | `RE_Order.Record` | Order wrapper |
| `getOrderItems()` | `global List<RE_Order.Record> getOrderItems()` | `List<RE_Order.Record>` | All order item wrappers |
| `getOrderItems(Boolean, Boolean, Boolean)` | Filtered by includeNew, includeDirty, includeDeleted | `List<RE_Order.Record>` | Filtered order items |
| `append(SObject)` | `global RE_Order.Record append(SObject record)` | `RE_Order.Record` | Add custom sObject to transaction |
| `addRelationship(child, field, parent)` | `global void addRelationship(RE_Order.Record, SObjectField, RE_Order.Record)` | void | Define relationship between two records |
| `registerWork(DoWork)` | `global void registerWork(DoWork work)` | void | Register post-commit work |

### cgcloud.RE_Order.Record Class

Wraps an sObject record in the order transaction.

| Method | Signature | Description |
|---|---|---|
| `isDeleted()` | `global Boolean isDeleted()` | Record is flagged for deletion |
| `isNew()` | `global Boolean isNew()` | Record is new (not yet in DB) |
| `getId()` | `global Boolean getId()` | Temporary SFDC ID (before commit) |
| `getRecord()` | `global Boolean getRecord()` | Returns the wrapped SObject |

### cgcloud.RE_Order.DoWork Interface

```apex
global class MyWork implements cgcloud.RE_Order.DoWork {
    global override void doWork() {
        // Runs after all order records committed
        // Exception here rolls back entire transaction
    }
}
```

### cgcloud.TPM_Promotion.TacticRecord Class

Used in Business Object API workflow steps to access tactic data.

```apex
cgcloud.TPM_Promotion.TacticRecord tactic =
    (cgcloud.TPM_Promotion.TacticRecord) context.get('currentOutput');
cgcloud__Tactic__c myRecord = (cgcloud__Tactic__c) tactic.getRecord();
```

### cgcloud.RTRReportResult Class

Provides access to Real Time Report row data.

| Method | Description |
|---|---|
| `FlatList getRows(String rowTypeFilter)` | Returns rows filtered by type |
| `FlatlistRow.hasNext()` | Iterator: has next row |
| `FlatlistRow.next()` | Iterator: next row |

---

## orderExtensionUtils LWC Service Component

**Import path:** `cgcloud/orderExtensionUtils`

| Method | Signature | Description |
|---|---|---|
| `getOrderData` | `getOrderData(recordId)` | Get order header SObject data |
| `updateOrderData` | `updateOrderData(recordId, srcThisRef, fieldApiName, value)` | Update Order__c field in memory |
| `getOrderItemData` | `getOrderItemData(recordId)` | Get order line item data |
| `updateOrderItemData` | `updateOrderItemData(recordId, srcThisRef, itemId, fieldApiName, value)` | Update Order_Item__c field |
| `setCustomState` | `setCustomState(recordId, customState)` | Set custom payload passed to Apex save hook |
| `getIsOrderInEditMode` | `getIsOrderInEditMode()` | Returns Boolean: is order in edit mode |
| `registerListenerForOrderDataUpdates` | `registerListenerForOrderDataUpdates(recordId, thisRef, callback)` | Callback on order field change |
| `registerOrderDataInlineValidator` | `registerOrderDataInlineValidator(recordId, thisRef, callback)` | Validate order field (return error string or '') |
| `registerListenerForOrderItemDataUpdates` | `registerListenerForOrderItemDataUpdates(recordId, thisRef, callback)` | Callback on any order item field change |
| `registerOrderItemDataInlineValidator` | `registerOrderItemDataInlineValidator(recordId, thisRef, callback)` | Validate order item field |
| `registerBeforeAddItemActionHandler` | `registerBeforeAddItemActionHandler(recordId, thisRef, callback)` | Hook before items added (can modify items or throw Error) |
| `registerBeforeSaveActionHandler` | `registerBeforeSaveActionHandler(recordId, thisRef, callback)` | Hook before save (can throw Error to cancel) |
| `registerListenerForEnablingOrDisablingEditMode` | `registerListenerForEnablingOrDisablingEditMode(recordId, thisRef, callback)` | Callback on edit/read mode toggle |

All methods are in API version 59.0+.

**registerBeforeSaveActionHandler callback payload:**
```javascript
handleBeforeSaveCB(savePayload) {
    const { orderItemsToBeUpserted: orderItems, updatedOrder: orderData } = savePayload;
    // orderItems: array of order items to be upserted
    // orderData: the updated order header
    if (orderData.cgcloud__Header_Discount_Percentage__c > 15) {
        throw new Error("Header discount can't be greater than 15");
    }
}
```

---

## SOQL Reference

### Key Visit/Assessment Queries

```soql
-- Active visits for a rep today
SELECT Id, Name, Status, Account.Name, PlannedVisitStartTime, ActualVisitStartTime
FROM Visit
WHERE OwnerId = :userId
AND PlannedVisitStartTime = TODAY
AND Status != 'Cancelled'
ORDER BY PlannedVisitStartTime ASC

-- Assessment task completion for a visit
SELECT Id, Name, TaskType, Status, StartTime, EndTime,
    AssessmentTaskDefinition.Name
FROM AssessmentTask
WHERE ParentId = :visitId
ORDER BY SequenceNumber ASC

-- Store KPI targets
SELECT Id, RetailStore.Name, AssessmentIndicatorDefinition.Name,
    Target__c, InStoreLocationCategory.Name
FROM RetailStoreKpi
WHERE RetailStore.Account.Id = :accountId

-- Retail visit actual KPIs
SELECT Id, RetailStore.Name, AssessmentIndicatorDefinition.Name,
    Value__c, Visit.ActualVisitStartTime
FROM RetailVisitKpi
WHERE Visit.Id = :visitId
```

### Key Sync Management Queries

```soql
-- Sync history for a device
SELECT Id, Name, cgc_sync__Sync_Action_Type__c, cgc_sync__Sync_Client_Queue_Status__c,
    cgc_sync__Last_Queue_Status_Request_At__c
FROM cgc_sync__Sync_Client_Registration__c
WHERE cgc_sync__Device_Id__c = :deviceId
ORDER BY cgc_sync__Last_Queue_Status_Request_At__c DESC

-- Sync configuration for a profile
SELECT Id, Name, cgc_sync__ClientApp_ID__c,
    cgc_sync__Download_Page_Size_Limit__c,
    cgc_sync__CPU_Time_Calculation_Buffer__c
FROM cgc_sync__Sync_Config__c
WHERE SetupOwnerId = :profileId
```

### Key TPM Queries

```soql
-- Active promotions for an account and sales org
SELECT Id, Name, cgcloud__Status__c, cgcloud__Date_From__c, cgcloud__Date_Thru__c,
    cgcloud__Anchor_Account__r.Name,
    (SELECT Id, cgcloud__Amount__c, cgcloud__Compensation_Model__c
     FROM cgcloud__Tactics__r WHERE cgcloud__Status__c = 'Active')
FROM cgcloud__Promotion__c
WHERE cgcloud__Anchor_Account__c = :accountId
AND cgcloud__Status__c = 'Active'

-- Fund balance for a business year
SELECT Id, Name, cgcloud__Business_Year__c,
    cgcloud__Budget__c, cgcloud__Committed__c, cgcloud__Remaining__c
FROM cgcloud__Fund__c
WHERE cgcloud__Sales_Organization__c = :salesOrgId
AND cgcloud__Business_Year__c = :businessYear

-- Account plan for a specific account and year
SELECT Id, Name, cgcloud__Business_Year__c, cgcloud__Version__c,
    (SELECT Id, cgcloud__Category__r.Name, cgcloud__Manual_Calculation_Input__c
     FROM cgcloud__Account_Plan_Categories__r)
FROM cgcloud__Account_Plan__c
WHERE cgcloud__Account__c = :accountId
AND cgcloud__Business_Year__c = :businessYear

-- Orders for a visit
SELECT Id, Name, cgcloud__Status__c, cgcloud__Total_Amount__c,
    cgcloud__Customer_Order_Id__c,
    (SELECT Id, cgcloud__Product__r.Name, cgcloud__Quantity__c, cgcloud__Price__c
     FROM cgcloud__Order_Items__r)
FROM cgcloud__Order__c
WHERE cgcloud__Visit__c = :visitId
```
