---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Automation Patterns

## Retail Order Save Customization (Apex — `System.Callable`)

The most important CGC extension point. Register a callable Apex class to intercept the retail order save process.

### Registration

1. Create global Apex class implementing `System.Callable`
2. In Setup → Custom Metadata Types → `CGCloud Process Customization` → Manage Records
3. Create record:
   - `Label`: `RE_Order_Save`
   - `DeveloperName`: `RE_Order_Save`
   - `Class`: `<Your Callable APEX Class>`
   - `Method`: `save`
   - `Enabled`: checked

### Pattern — Add Custom sObject to Order Transaction

```apex
global class RetailOrderSaveCustomization implements System.Callable {
    public Object call(String m, Map<String, Object> params) {
        cgcloud.RE_Order orderWrapper = (cgcloud.RE_Order) params.get('order');
        cgcloud__Order__c order = (cgcloud__Order__c) orderWrapper.getOrder().getRecord();

        MyCustomSObject__c mySObject = new MyCustomSObject__c();
        mySObject.Custom__c = order.cgcloud__Customer_Order_Id__c;
        cgcloud.RE_Order.Record myRecordWrapper = orderWrapper.append(mySObject);
        // Relate custom sObject to the Order
        orderWrapper.addRelationship(
            myRecordWrapper,
            MyCustomSObject__c.Order__c,
            orderWrapper.getOrder()
        );
        return null;
    }
}
```

**Key rule:** All `append()` records are committed in all-or-none fashion. Never use direct DML inside the hook — the `RE_Order` framework manages IDs (temporary IDs are used for uncommitted records).

### Pattern — Modify Order/Item Fields

```apex
public Object call(String m, Map<String, Object> params) {
    cgcloud.RE_Order orderWrapper = (cgcloud.RE_Order) params.get('order');
    cgcloud__Order__c order = (cgcloud__Order__c) orderWrapper.getOrder().getRecord();
    order.cgcloud__Customer_Order_Id__c = 'my-custom-id';

    cgcloud__Order_Item__c orderItem =
        (cgcloud__Order_Item__c) orderWrapper.getOrderItems()[0].getRecord();
    orderItem.Custom__c = 'new value';
    return null;
}
```

### Pattern — Parent-Child Custom sObject Relationship

```apex
public Object call(String m, Map<String, Object> params) {
    cgcloud.RE_Order orderWrapper = (cgcloud.RE_Order) params.get('order');
    cgcloud__Order__c order = (cgcloud__Order__c) orderWrapper.getOrder().getRecord();

    MyCustomSObject__c parent = new MyCustomSObject__c();
    cgcloud.RE_Order.Record parentWrapper = orderWrapper.append(parent);
    orderWrapper.addRelationship(parentWrapper, MyCustomSObject__c.Order__c, orderWrapper.getOrder());

    MyChildSObject__c child = new MyChildSObject__c();
    cgcloud.RE_Order.Record childWrapper = orderWrapper.append(child);
    orderWrapper.addRelationship(childWrapper, MyChildSObject__c.MyCustomSObject__c, parentWrapper);
    return null;
}
```

### Pattern — Save Custom State from LWC

```apex
public Object call(String m, Map<String, Object> params) {
    cgcloud.RE_Order orderWrapper = (cgcloud.RE_Order) params.get('order');
    String payloadString = (String) params.get('customState'); // Set via setCustomState() in LWC
    if (payloadString != null && payloadString != '') {
        Map<String, Object> customPayload = (Map<String, Object>) JSON.deserializeUntyped(payloadString);
        MyCustomSObject__c mySObject = new MyCustomSObject__c();
        mySObject.Custom__c = (String) customPayload.get('Custom__c');
        mySObject.Duration__c = (Integer) customPayload.get('Duration__c');
        if (mySObject.Custom__c != null) {
            cgcloud.RE_Order.Record rec = orderWrapper.append(mySObject);
            orderWrapper.addRelationship(rec, MyCustomSObject__c.Order__c, orderWrapper.getOrder());
        }
    }
    return null;
}
```

### Pattern — Post-Commit Work (`RE_Order.DoWork`)

```apex
global class RetailOrderSaveCustomization implements System.Callable {
    public class MyAfterCommitWork implements cgcloud.RE_Order.DoWork {
        cgcloud__Order__c m_order;
        MyAfterCommitWork(cgcloud__Order__c order) { m_order = order; }
        global override void doWork() {
            // Runs AFTER all order records committed. Transaction rolls back on any exception.
            System.debug('Order committed: ' + m_order.Id);
        }
    }
    public Object call(String m, Map<String, Object> params) {
        cgcloud.RE_Order orderWrapper = (cgcloud.RE_Order) params.get('order');
        cgcloud__Order__c order = (cgcloud__Order__c) orderWrapper.getOrder().getRecord();
        orderWrapper.registerWork(new MyAfterCommitWork(order));
        return null;
    }
}
```

---

## RE_Order Class Reference

| Method | Signature | Description |
|---|---|---|
| `getOrder()` | `global RE_Order.Record getOrder()` | Returns Record wrapper for the order |
| `getOrderItems()` | `global List<RE_Order.Record> getOrderItems()` | All order item wrappers |
| `getOrderItems(Boolean new, Boolean dirty, Boolean deleted)` | Filtered order items | Filter by state flags |
| `append(SObject record)` | `global RE_Order.Record append(SObject record)` | Add custom sObject to transaction |
| `addRelationship(child, field, parent)` | `global void addRelationship(RE_Order.Record, SObjectField, RE_Order.Record)` | Define parent-child relationship |
| `registerWork(DoWork work)` | `global void registerWork(DoWork work)` | Register post-commit work |

**RE_Order.Record methods:**
- `isDeleted()` — flagged for deletion
- `isNew()` — new record (not yet in DB)
- `getId()` — temporary SFDC ID
- `getRecord()` — returns the wrapped SObject

---

## Order Proposal List Customization (Apex)

Register via `CGCloud Process Customization`: DeveloperName = `RE_Order_Proposal_List`, Method = `proposalList`.

```apex
global class OrderProposalListCustomization implements System.Callable {
    public Object call(String m, Map<String, Object> params) {
        List<Product2> products = (List<Product2>) params.get('products');
        Id accountId = (Id) params.get('accountId');
        Id orderId = (Id) params.get('orderId');
        List<Id> productIdList = new List<Id>();

        // Custom logic to add/remove product IDs
        for (Integer i = 0; i < Math.min(products.size(), 4); i++) {
            productIdList.add(products.get(i).Id);
        }
        return JSON.serialize(productIdList); // Must return JSON-serialized List<Id>
    }
}
```

**Note:** The `Consider Listing` setting in the Order Template must be set to `Yes` before the hook fires.

---

## orderExtensionUtils LWC Service Component

The `cgcloud/orderExtensionUtils` service component provides client-side access to order data. Namespace: `cgcloud`.

| Method | API Version | Description |
|---|---|---|
| `getOrderData(recordId)` | v59.0 | Get order header data |
| `updateOrderData(recordId, thisRef, fieldApiName, value)` | v59.0 | Update Order__c field |
| `getOrderItemData(recordId)` | v59.0 | Get order line item data |
| `updateOrderItemData(recordId, thisRef, itemId, fieldApiName, value)` | v59.0 | Update Order_Item__c field |
| `setCustomState(recordId, customState)` | v59.0 | Set custom payload forwarded to Apex save hook |
| `getIsOrderInEditMode()` | v59.0 | Check if order is in edit mode |
| `registerListenerForOrderDataUpdates(recordId, thisRef, callback)` | v59.0 | Listen for order field changes |
| `registerOrderDataInlineValidator(recordId, thisRef, callback)` | v59.0 | Validate order field changes (return error message or '') |
| `registerListenerForOrderItemDataUpdates(recordId, thisRef, callback)` | v59.0 | Listen for order item changes |
| `registerOrderItemDataInlineValidator(recordId, thisRef, callback)` | v59.0 | Validate order item changes |
| `registerBeforeAddItemActionHandler(recordId, thisRef, callback)` | v59.0 | Hook before items added to order |
| `registerBeforeSaveActionHandler(recordId, thisRef, callback)` | v59.0 | Hook before order save (can throw Error to cancel) |
| `registerListenerForEnablingOrDisablingEditMode(recordId, thisRef, callback)` | v59.0 | Listen for edit/read mode toggle |

**LWC metadata requirement:**
```xml
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
  <apiVersion>59.0</apiVersion>
  <isExposed>true</isExposed>
  <targets>
    <target>lightning__RecordPage</target>
  </targets>
  <targetConfigs>
    <targetConfig targets="lightning__RecordPage">
      <objects><object>cgcloud__Order__c</object></objects>
    </targetConfig>
  </targetConfigs>
  <runtimeNamespace>cgcloud</runtimeNamespace>  <!-- NOT needed if LWS is enabled -->
</LightningComponentBundle>
```

**Note:** When Lightning Web Security (LWS) is enabled, `runtimeNamespace` is not required. When set, the component cannot use `@salesforce` package imports.

---

## TPM Business Object API (Apex Callable)

TPM workflows are customizable via Apex classes implementing `System.Callable`, registered as Business Object API Workflow Steps.

```apex
global with sharing class SetCommentValue implements System.Callable {
    public static Object call(String method, Map<String, Object> context) {
        cgcloud.TPM_Promotion.TacticRecord tactic =
            (cgcloud.TPM_Promotion.TacticRecord) context.get('currentOutput');
        Map<String, Object> input = (Map<String, Object>) context.get('currentInput');
        cgcloud__Tactic__c myRecord = (cgcloud__Tactic__c) tactic.getRecord();
        myRecord.Comment__c = input.get('MyComment') != null
            ? String.valueOf(input.get('MyComment')) : '';
        return null;
    }
}
```

**Workflow Step registration (Business Object API Workflow Steps tab):**
- `Business Object API Workflow Step Name`: `SetCommentValue`
- `Classname`: `SetCommentValue`
- `Description`: Purpose of the step

**Available managed package workflow steps:**
- `loadPromotionDefaults(update)` — loads promotion defaults on update
- `loadTacticDefaults(update)` — loads tactic defaults on update

---

## TPM REST API — Ingest Promotions

```json
POST /services/apexrest/cgcloud/v1/promotions/ingest
{
  "workflow": "Create",
  "importId": "12345678-1234-1234-1234-123456789012",
  "salesOrg": "0001",
  "promotions": [
    {
      "AnchorAccount": "CS_Atlanta",
      "PromotionTemplate": "Customer Promotion",
      "DateFrom": "2024-01-01",
      "DateThru": "2024-12-31",
      "Tactics": [
        {
          "Amount": 2500,
          "CompensationModel": "PerCase",
          "DateFrom": "2024-05-01",
          "DateThru": "2024-07-30",
          "TacticTemplate": "PriceReduction"
        }
      ]
    }
  ]
}
```

| Field | Type | Required | Version |
|---|---|---|---|
| `workflow` | Integer | Yes | v55+ |
| `importId` | Integer | No | v55+ |
| `salesOrg` | SalesOrgName | No | v55+ |
| `promotions` | List\<Object\> | Yes (max 50) | v55+ |

---

## RTR KPI Export Configuration

To export KPIs from Hyperforce as CSV:

1. Create `cgcloud__RTR_Report_Configuration__c` records for each dimension per sales org:
   - **Account Dimension** — fetches from `Account`; include `Name`, `cgcloud__ExternalId__c`, `cgcloud__Account_Number__c`
   - **Promotion Dimension** — fetches from `cgcloud__Promotion__c`; must include `accountid` attribute mapped to `cgcloud__Anchor_Account__c`
   - **Tactic Dimension** — fetches from `cgcloud__Tactic__c`
   - **Product Dimension** — fetches from `Product2`
   - **Product Part Dimension** — for BOM/component-level exports

2. Configure dimension meta as JSON arrays with `name`, `fieldsf`, and `fieldsf$label` properties

3. Assign `TPM Calculation Result Export` permission set to the export service user

4. Save and synchronize dimension meta to Consumer Goods Cloud Processing Service

**KPI data sources available for export:**
- `DailyRealData`, `DailyIntData` — daily actuals/integers
- `ProductMeasures`, `AccountMeasures`, `AccountProductMeasures` — dimension-level measures
- `WeeklyMeasureReal`, `WeeklyMeasureInt` — weekly measures
- `AccountAndPromotionMeasures` — writeback source

---

## RTR Apex Reference (`cgcloud` namespace)

The `cgcloud.RTRReportResult` class provides access to Real Time Report data.

```apex
cgcloud.RTRReportResult result = /* obtained from RTR framework */;
cgcloud.RTRReportResult.FlatList flatList = result.getRows('MyRowType');

for (cgcloud.RTRReportResult.FlatlistRow row : flatList) {
    // Process each row
}
```

**Methods:**
- `FlatList getRows(String rowTypeFilter)` — returns rows filtered by type
- `FlatlistRowIterable` — implements `Iterable<FlatlistRow>` with `hasNext()` and `next()`

---

## Visit Execution Automation

**Pattern — auto-create AssessmentTasks on Visit creation:**
```
Record-Triggered Flow on Visit | After Insert | Status = 'New'
  Query: AssessmentTaskDefinitions WHERE active = true AND VisitType matches
  Loop: For each definition
    → Create AssessmentTask: ParentId = triggering Visit.Id
```

**Bulk note:** Bulk visit creation (e.g., route generation for 500+ stores) should use a Batch/Queueable class rather than synchronous Flow to avoid 150 DML per transaction limits.

**Pattern — Visit completion KPI update:**
```
Record-Triggered Flow on Visit | After Save | Status changes to 'Complete'
  Recalculate Visit.ComplianceScore__c from AssessmentTasks
  Update Account KPI summary fields
```
