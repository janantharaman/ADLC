---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf
cloud: Automotive Cloud
section: api-reference
---

# Automotive Cloud — API Reference

## Business REST APIs Overview

All Automotive Cloud Business APIs follow Connect REST API conventions (authentication, rate limiting, request/response format). Base URL pattern: `https://yourInstance.salesforce.com/services/data/vXX.X/connect/`

| API | Method | Resource | Available From |
|---|---|---|---|
| Inventory Visibility Product Transfer | POST | `/connect/inventory-visibility/actions` | API v59.0 |
| Orchestration Inbound Events | POST | `/connect/orchestration/inbound-events` | API v59.0 |
| Transformations | POST | `/connect/manufacturing/transformations` | API v55.0 |

---

## 1. Inventory Visibility Product Transfer Action

**Resource:** `POST /connect/inventory-visibility/actions`

Transfers serialized vehicle/product inventory between two locations. Wraps `InventoryTransfer` creation.

**Query parameter:** `actionName=ProductTransfer` (required)

### Request Body

```json
{
  "items": [
    {
      "serializedProductId": "0jRxx000000009hEAA",
      "sourceLocationId": "131xx0000004FoLAAU",
      "destinationLocationId": "131xx0000004FpxAAE"
    },
    {
      "serializedProductId": "0jRxx00000000BJEAY",
      "sourceLocationId": "131xx0000004FoLAAU",
      "destinationLocationId": "131xx0000004FpxAAE"
    }
  ]
}
```

### Request Fields (`Inventory Actions Item Input`)

| Field | Required | Type | Description |
|---|---|---|---|
| `serializedProductId` | Yes | String | ID of the serialized product (SellerProduct) to transfer |
| `sourceLocationId` | Yes | String | Location record ID to transfer from |
| `destinationLocationId` | Yes | String | Location record ID to transfer to |

### Response Body (`Inventory Actions Result`)

```json
{
  "errors": {},
  "results": {
    "0jRxx00000000rG": "0Luxx0000004Cc4CAE",
    "0jRxx00000000sr": "0Luxx0000004Cc4CAE"
  }
}
```

| Property | Type | Description |
|---|---|---|
| `errors` | Map\<String, String\> | Error message if transfer failed; empty on success |
| `results` | Map\<String, String\> | Map of serializedProductId → transferRecordId |

---

## 2. Orchestration Inbound Events

**Resource:** `POST /connect/orchestration/inbound-events`

Receives telematics/IoT events and routes them to the matching `ActionableEventOrchestration` definition. Used for connected vehicle fault processing, signal handling, and vehicle state changes.

### Request Body

```json
{
  "sourceSystemIdentifier": "102",
  "type": "Transmission Issue",
  "subtype": "Transmission Over Temperature",
  "category": "FAULT",
  "eventData": "{\"Event\":{\"vin\":\"EFGHTYUIF56789GH\",\"id\":\"0vLSE00000000G92AI\",\"businessSObjectType\":\"Vehicle\",\"faults\":[{\"code\":\"P0218\",\"type\":\"repair\",\"description\":\"Engine Overheating\"},{\"code\":\"P0219\",\"type\":\"repair\",\"description\":\"Low Battery Warning\"}],\"location\":{\"latitude\":34,\"longitude\":56},\"signals\":[{\"value\":\"34\",\"timeStamp\":\"2023-05-16T15:13:41.236Z\",\"dataType\":\"string\",\"unit\":\"cm\",\"name\":\"speed\"}]}}",
  "additionalEventCriteria": {
    "fieldList": [
      { "field": "priority__c", "value": "high" }
    ]
  }
}
```

### Request Fields (`Inbound Event Input`)

| Field | Available | Required | Type | Description |
|---|---|---|---|---|
| `sourceSystemIdentifier` | v60.0 | No | String | ID to identify the source system |
| `type` | v60.0 | No | String | Type of inbound event |
| `subtype` | v60.0 | No | String | Subtype of the inbound event |
| `category` | v60.0 | No | String | Category of the inbound event |
| `eventData` | v60.0 | No | String | JSON string with event data from telematics provider |
| `additionalEventCriteria` | v60.0 | No | Additional Criteria Input | Key-value pairs for tailored routing |

### Additional Criteria Input

```json
{
  "additionalEventCriteria": {
    "fieldList": [
      { "field": "priority__c", "value": "high" }
    ]
  }
}
```

| Field | Type | Description |
|---|---|---|
| `fieldList` | Field Match[] | List of field name/value matches |
| `field` | String | Field API name |
| `value` | Object | Field value to match |

### Response Body (`Inbound Event`)

```json
{
  "sourceSystemIdentifier": "123",
  "status": "SUCCESS",
  "errors": [
    {
      "code": "CREATE_OR_UPDATE_RECORD_FAILED",
      "message": "Object: Vehicle, Error Message: duplicate value found: VehicleIdentificationNumber duplicates value on record with id: 0vLxx0000002d7eAI"
    }
  ],
  "actionResponse": [
    {
      "actionName": "CreateUpdateAction",
      "actionOutput": {
        "objectName": "Account",
        "operationType": "Create",
        "recordId": "001xx000003gb9Naac"
      }
    }
  ]
}
```

| Property | API Version | Type | Description |
|---|---|---|---|
| `sourceSystemIdentifier` | v59.0 | String | Correlates to the inbound event |
| `status` | v59.0 | String | Status: `SUCCESS` or `FAILURE` |
| `errors` | v59.0 | Error Response[] | Error details if processing failed |
| `actionResponse` | v60.0 | Action Response[] | Actions taken by the orchestration |

### Action Response Object

| Property | Type | Description |
|---|---|---|
| `actionName` | String | Name of action executed |
| `actionOutput` | Map\<String, Object\> | Key-value output from the action |

---

## 3. Transformations API

**Resource:** `POST /connect/manufacturing/transformations`

Converts Lead data to Opportunity data during vehicle lead conversion. Supports LeadLineItem → OpportunityLineItem and LeadPreferredSeller → OpportunityPreferredSeller transformation patterns.

### Request Body

```json
{
  "inputObjectIds": [
    "0sTxx000000003FEAQ",
    "0sTxx000000004rEAA"
  ],
  "inputObjectName": "LeadLineItem",
  "usageType": "TransformationMapping",
  "outputObjectName": "OpportunityLineItem",
  "outputObjectDefaultValues": {
    "OpportunityLineItem": {
      "OpportunityId": "abcd1234",
      "CurrencyIsoCode": "USD"
    }
  }
}
```

### Request Fields (`Transformation Input`)

| Field | Required | Type | Description |
|---|---|---|---|
| `inputObjectIds` | Yes | String[] | Record IDs of input objects (all same type) |
| `inputObjectName` | Yes | String | Input object API name (see values below) |
| `outputObjectName` | Yes | String | Output object to create |
| `usageType` | Yes | String | Transformation type (see values below) |
| `outputObjectDefaultValues` | No | Map\<String, Map\<String, String\>\> | Default values for output object fields |

**`inputObjectName` values:**
- `MfgProgramCpntFrcstFact`
- `ManufacturingProgram`
- `Period`
- `Quote`
- `QuoteLineItem`
- `LeadLineItem`
- `LeadPreferredSeller`

**`usageType` values:**

| Value | Description |
|---|---|
| `TransformationMapping` | Generic field mapping via ObjectHierarchyRelationship |
| `ConvertToSalesAgreement` | Convert Manufacturing/Automotive program to Sales Agreement |
| `CLMFieldMapping` | Contract Lifecycle Management field mapping |
| `EligibleProgramRebateType` | Program rebate type mapping |
| `MapJournalToMemberAggregate` | Rebate journal to member aggregate |

### Response Body (`Transformation Output`)

```json
{
  "outputObjectDetails": [
    {
      "outputId": "Y_id1",
      "inputIds": ["X_id1", "X_id2"],
      "isSuccess": true,
      "errorReason": null
    }
  ],
  "errorDetails": [
    {
      "inputIds": ["X_id3"],
      "errorReason": "Mandatory field1 missing value",
      "isSuccess": false
    }
  ],
  "Status": "PARTIAL_SUCCESS"
}
```

---

## Change Data Capture — Supported Objects

Objects that support ChangeEvent (subscribe via Change Data Capture):

| Object | ChangeEvent Name |
|---|---|
| `Vehicle` | `VehicleChangeEvent` |
| `VehicleDefinition` | `VehicleDefinitionChangeEvent` |
| `AssetAccountParticipant` | `AssetAccountParticipantChangeEvent` |

**Usage pattern:**
```apex
// Subscribe to Vehicle changes via CometD or Apex trigger
trigger VehicleChangeTrigger on VehicleChangeEvent (after insert) {
    for (VehicleChangeEvent event : Trigger.new) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        // header.changeType: CREATE / UPDATE / DELETE / UNDELETE
        // header.recordIds: list of changed record IDs
    }
}
```

---

## SOQL Reference Patterns

### Find all Vehicles for a given dealer Account

```soql
SELECT Id, Name, VehicleIdentificationNumber, Status, ConditionType,
       VehicleDefinitionId, VehicleDefinition.ModelName, VehicleDefinition.ModelYear,
       VehicleDefinition.MakeName, CurrentOwnerId
FROM Vehicle
WHERE CurrentOwnerId = :dealerAccountId
AND Status = 'At Dealer Location'
ORDER BY CreatedDate DESC
```

### Active Fleet Assets with overdue maintenance

```soql
SELECT Id, Fleet.Name, Asset.Name, Asset.LastServiceDate, Asset.Status
FROM FleetAsset
WHERE Fleet.Status = 'Active'
AND Asset.LastServiceDate < LAST_N_DAYS:180
ORDER BY Asset.LastServiceDate ASC
NULLS FIRST
```

### Open Claims with coverage amounts

```soql
SELECT Id, Name, Status, Severity, TotalClaimedAmount, TotalAdjustedAmount,
       Account.Name, ClaimType,
       (SELECT Id, Name, CoveredAmount, ClaimCoverageType
        FROM ClaimCoverages__r)
FROM Claim
WHERE Status NOT IN ('Approved', 'Rejected')
ORDER BY CreatedDate DESC
```

### FinancialAccounts nearing maturity

```soql
SELECT Id, Name, Type, Status, MaturityDate, TotalOutstandingAmount,
       PrincipalAmount, InterestRate, Term
FROM FinancialAccount
WHERE Status = 'Active'
AND MaturityDate <= NEXT_N_DAYS:90
ORDER BY MaturityDate ASC
```

### LeadLineItems for active leads

```soql
SELECT Id, Lead.Name, Lead.Status, VehicleDefinitionId,
       VehicleDefinition__r.ModelName, VehicleDefinition__r.ModelYear,
       Quantity__c, UnitPrice__c
FROM LeadLineItem
WHERE Lead.IsConverted = false
AND Lead.Status != 'Dead'
```

### Appraisals with item breakdown

```soql
SELECT Id, Name, Status__c, AppraisalDate__c, Vehicle__r.Name,
       Vehicle__r.VehicleIdentificationNumber,
       (SELECT Id, ItemType__c, ProviderValue__c, AdjustedValue__c
        FROM AppraisalItems__r)
FROM Appraisal
WHERE Status__c = 'In Progress'
```

### Pending telemetry actions

```soql
SELECT Id, Name, EventType__c, Status__c, SourceSystemIdentifier__c,
       Vehicle__r.VehicleIdentificationNumber
FROM ActionableEventOrchestration
WHERE Status__c = 'Pending'
ORDER BY CreatedDate ASC
LIMIT 200
```

---

## Governor Limits Reference

| Category | Limit |
|---|---|
| REST API callouts per transaction | 100 |
| Orchestration Inbound Events — concurrent | Standard Salesforce async limits |
| SOQL rows returned per query | 50,000 |
| DML statements per transaction | 150 |
| DML rows per transaction | 10,000 |
| Platform Events published per day (with add-on) | 250,000 |
| `TelemetryDefinitionVersion` — immutable after activation | Cannot edit; create new version |
| Change Data Capture events per hour | 50,000 default |

> **Telematics note:** Connected vehicle telemetry can generate millions of events per day. Never process synchronously in triggers. Use Platform Events → Queueable/Batch Apex pattern. Monitor `DailyApiRequests` and `HourlyTimeBasedWorkflow` limits daily.
