---
source: E&U Developer Guide (Atlas TOC, Summer '26); Vlocity Build GitHub; OmniStudio transcripts; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: api-reference
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — API Reference

## E&U Cloud REST API

### Program Application (the only E&U-specific REST endpoint in the Developer Guide)

**Endpoint:** `POST /services/data/v{version}/connect/energy-utilities/programs/{programId}/applications`

**Purpose:** Programmatic enrollment of a customer into an energy program (efficiency, rebate, assistance, etc.)

#### Request Body — ProgramApplicationInput

| Field | Type | Required | Description |
|---|---|---|---|
| `accountId` | String | Yes | Salesforce Account Id of the applicant |
| `contactId` | String | No | Contact Id (if individual applicant) |
| `applicationItems` | List<ProgramApplicationItemInput> | Yes | Line items for the application |
| `files` | List<ProgramApplicationFileInput> | No | Supporting documents |

#### Request Body — ProgramApplicationItemInput

| Field | Type | Required | Description |
|---|---|---|---|
| `programProductId` | String | Yes | Id of the ProgramProduct being applied for |
| `quantity` | Integer | No | Quantity requested |
| `attributes` | Map<String, Object> | No | Custom attributes for the application item |

#### Request Body — ProgramApplicationFileInput

| Field | Type | Required | Description |
|---|---|---|---|
| `fileName` | String | Yes | File name including extension |
| `fileContent` | String | Yes | Base64-encoded file content |
| `mimeType` | String | Yes | MIME type (e.g., `application/pdf`) |
| `documentType` | String | No | Type of supporting document |

#### Response Body — ProgramApplicationOutput

| Field | Type | Description |
|---|---|---|
| `applicationId` | String | Salesforce Id of the created IndividualApplication |
| `status` | String | Application status (Submitted, Pending Review, etc.) |
| `referenceNumber` | String | Human-readable reference number |
| `items` | List | Created IndividualApplicationItem records |

**Sample request:**
```json
{
  "accountId": "001XXXXXXXXXXXXXXXXX",
  "contactId": "003XXXXXXXXXXXXXXXXX",
  "applicationItems": [
    {
      "programProductId": "0XXXXXXXXXXXXXXXXXX",
      "quantity": 1,
      "attributes": {
        "HomeOwnershipStatus": "Owner",
        "AnnualIncome": 45000
      }
    }
  ]
}
```

---

## Integration Procedure as REST Endpoint

Integration Procedures can be exposed as REST APIs for external system consumption.

**Calling pattern:**
```
POST /services/apexrest/vlocity_cmt/v1/EnergyServices/{IPType}/{IPSubType}

Headers:
  Authorization: Bearer {access_token}
  Content-Type: application/json

Body: {
  "input": {
    "AccountId": "001XXXXXXXXXXXXXXXXX",
    "ServiceType": "Electric"
  },
  "sClassName": "{IPType}",
  "sMethodName": "{IPSubType}",
  "options": {}
}
```

**Response:**
```json
{
  "output": {
    "BillingAccounts": [...],
    "ServicePoints": [...],
    "CurrentBalance": 245.60
  },
  "options": {},
  "success": true
}
```

---

## VlocityOpenInterface — Custom Apex for OM

All custom Apex classes registered in `ItemImplementation__c` for Order Management task execution must implement `vlocity_cmt.VlocityOpenInterface`.

```apex
global class MyServiceActivation implements vlocity_cmt.VlocityOpenInterface {

    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outputMap,
        Map<String, Object> optionMap
    ) {
        if (methodName == 'doWork') {
            // Get orchestration item details
            Id orchItemId = (Id) inputMap.get('orchestrationItemId');
            vlocity_cmt__OrchestrationItem__c item = [
                SELECT Id, vlocity_cmt__OrchestrationPlan__r.vlocity_cmt__Order__c
                FROM vlocity_cmt__OrchestrationItem__c
                WHERE Id = :orchItemId
                WITH SECURITY_ENFORCED
            ];
            // Perform work
            // Set output
            outputMap.put('Status', 'Completed');
        }
        return true;
    }
}
```

**Registration:**
```
ItemImplementation__c:
  - Name: MyServiceActivation
  - Class Name: MyServiceActivation
  - Method: doWork
  - Orchestration Item Definition: [link to OrchestrationItemDefinition__c]
```

---

## CPQ API — Key Methods

The CPQ engine exposes methods through Integration Procedures and can be called via OmniScript action steps.

### getCards (Product Catalog Query)
Returns products available to a customer based on context (account, location, eligibility).

**Integration Procedure call:**
```json
{
  "sClassName": "vlocity_cmt.CPQInterface",
  "sMethodName": "getCards",
  "input": {
    "accountId": "001XXXXXXXXXXXXXXXXX",
    "catalogCode": "RESIDENTIAL_ELECTRIC",
    "getPricing": false
  }
}
```

**Performance note:** Always set `"getPricing": false` for catalog browse operations where pricing display is not required.

### getCardItems (Product Details with Pricing)
Returns full product detail including pricing for a specific product.

```json
{
  "sClassName": "vlocity_cmt.CPQInterface",
  "sMethodName": "getCardItems",
  "input": {
    "productId": "01t XXXXXXXXXXXXXXXXX",
    "accountId": "001XXXXXXXXXXXXXXXXX",
    "getPricing": true,
    "pricingPlanCode": "STANDARD"
  }
}
```

---

## DataRaptor Interface Objects (Billing Import)

These interface objects act as staging tables for importing data from external CIS/billing systems:

| Object | Purpose |
|---|---|
| `vlocity_cmt__Interface_BillingInfo__c` | Staging for billing balance/statement data from CIS |
| `vlocity_cmt__Interface_ProductAttribute__c` | Staging for product attribute data |
| `vlocity_cmt__Interface_DRGeneric__c` | Generic staging for any DataRaptor import |

**Pattern:** External system pushes data into interface objects → DataRaptor Transform + Load processes and normalizes data → target objects (Statement__c, AccountBalance__c) populated.

---

## Calculation Matrix — Invocation

**Via Integration Procedure (Matrix Action step):**
```json
{
  "stepType": "Matrix",
  "matrixName": "ResidentialRateMatrix",
  "inputs": {
    "CustomerSegment": "Residential",
    "UsageTier": "Tier2",
    "SeasonalFlag": "Summer"
  },
  "outputPath": "PricingResult"
}
```

**Via Apex:**
```apex
vlocity_cmt.CalculationMatrixService matrixService =
    new vlocity_cmt.CalculationMatrixService();
Map<String, Object> inputs = new Map<String, Object>{
    'CustomerSegment' => 'Residential',
    'UsageTier' => 'Tier2'
};
Map<String, Object> result = matrixService.execute('ResidentialRateMatrix', inputs);
Decimal rate = (Decimal) result.get('BaseRate');
```

---

## SOQL Reference

```soql
-- Active service agreements for an account via premises
SELECT Id, Name, Status,
    ServicePoint.Name,
    ServicePoint.vlocity_cmt__Premises__r.Name,
    ServicePoint.vlocity_cmt__Premises__r.vlocity_cmt__StreetAddress__c
FROM EnergyServiceAgreement
WHERE ServicePoint.vlocity_cmt__Premises__r.vlocity_cmt__Account__c = :accountId
AND Status = 'Active'

-- Program enrollments with benefit disbursements
SELECT Id, Name, Status__c,
    Program.Name,
    (SELECT Id, Amount__c, DisbursementDate__c, Status__c
     FROM BenefitDisbursements__r
     WHERE Status__c = 'Paid')
FROM ProgramEnrollment
WHERE AccountId = :accountId

-- Open OM tasks for an order
SELECT Id, Name, Status,
    vlocity_cmt__OrchestrationPlan__r.vlocity_cmt__Order__r.OrderNumber,
    vlocity_cmt__ItemImplementation__r.Name,
    vlocity_cmt__OrchestrationQueue__r.Name
FROM vlocity_cmt__OrchestrationItem__c
WHERE vlocity_cmt__OrchestrationPlan__r.vlocity_cmt__Order__c = :orderId
AND Status != 'Completed'
ORDER BY vlocity_cmt__Sequence__c ASC

-- Timesheet entries for a service resource in a pay period
SELECT Id, Name, vlocity_cmt__Date__c,
    vlocity_cmt__RegularHours__c,
    vlocity_cmt__OvertimeHours__c,
    vlocity_cmt__TimeSheet__r.vlocity_cmt__ServiceResource__r.Name
FROM vlocity_cmt__TimeSheetEntry__c
WHERE vlocity_cmt__TimeSheet__r.vlocity_cmt__ServiceResource__c = :resourceId
AND vlocity_cmt__TimeSheet__r.vlocity_cmt__PayPeriod__c = :payPeriodId

-- Calculation matrix lookup for pricing
SELECT Id, DeveloperName,
    vlocity_cmt__MatrixType__c,
    (SELECT Id, vlocity_cmt__InputValue__c, vlocity_cmt__OutputValue__c
     FROM vlocity_cmt__CalculationMatrixRows__r
     WHERE vlocity_cmt__IsActive__c = true)
FROM vlocity_cmt__CalculationMatrix__c
WHERE DeveloperName = 'ResidentialRateMatrix'
```
