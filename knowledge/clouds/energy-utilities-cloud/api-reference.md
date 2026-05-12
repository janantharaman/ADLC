---
source: E&U Developer Guide (Summer '26, v67.0, PDF confirmed 2026-05-12); Vlocity Build GitHub; OmniStudio transcripts; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: api-reference
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — API Reference

## E&U Cloud REST API

### Program Application (the only E&U-specific REST endpoint in the Developer Guide)

**Endpoint:** `POST /services/data/v{version}/connect/eu-program/applications`

**Available since:** API v58.0

**Purpose:** Programmatic enrollment of a customer into an energy program (efficiency, rebate, EV charger, energy efficiency, etc.). Creates an `IndividualApplication` record plus child `IndividualApplicationItem` records.

**Example URI:**
```
https://yourInstance.salesforce.com/services/data/v67.0/connect/eu-program/applications
```

#### Request Body — ProgramApplicationInput

| Field | Type | Required | Description |
|---|---|---|---|
| `programId` | String | Yes | Id of the Program record |
| `accountId` | String | Yes | Id of the applicant's Account record |
| `description` | String | No | Description of the application |
| `applicationItems` | ProgramApplicationItemInput[] | Yes | List of program products being applied for |
| `files` | ProgramApplicationFileInput[] | No | Supporting documents (ContentDocument references) |

#### Request Body — ProgramApplicationItemInput

| Field | Type | Required | Description |
|---|---|---|---|
| `programProductId` | String | Yes | Id of the ProgramProduct associated with the program |
| `status` | String | No | Status of the item |

#### Request Body — ProgramApplicationFileInput

| Field | Type | Required | Description |
|---|---|---|---|
| `contentDocumentId` | String | Yes | Id of an existing ContentDocument record to attach |

#### Response Body — ProgramApplicationOutput

| Field | Type | Description |
|---|---|---|
| `applicationId` | String | Tracking number for the created IndividualApplication |
| `message` | String | Response message (e.g., "Your application has been submitted successfully") |
| `success` | Boolean | `true` if application created successfully, `false` otherwise |

**Sample request:**
```json
{
  "programId": "11Wxx0000004GkaEAE",
  "accountId": "001xx000003GlBHAA0",
  "description": "Individual Application created for Program EV Charger Rebate",
  "applicationItems": {
    "records": [
      {
        "programProductId": "11mxx0000004PROAA2"
      }
    ]
  },
  "files": {
    "records": [
      {
        "contentDocumentId": "069xx0000004DWWAA2"
      }
    ]
  }
}
```

**Sample response:**
```json
{
  "success": true,
  "message": "Your application has been submitted successfully",
  "applicationId": "IA-0000000456"
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
-- Active service agreements for an account
-- ServicePoint.PremisesId → Location (relationship name "Premises", NOT vlocity_cmt__Premises__c)
SELECT Id, Name, Status, ActivationDate, Type,
    ServicePoint.Name, ServicePoint.ServiceType,
    ServicePoint.MarketIdentifier,
    ServicePoint.Premises.Name, ServicePoint.Premises.ExternalReference
FROM EnergyServiceAgreement
WHERE AccountId = :accountId
AND Status = 'Active'

-- Program enrollments with benefit assignments
SELECT Id, Name,
    Program.Name, Program.ProgramType,
    EnrolleeRole,
    (SELECT Id, Status, EntitlementAmount,
            NextPayoutDate, PayoutFrequency
     FROM BenefitAssignments__r
     WHERE Status = 'Active')
FROM ProgramEnrollment
WHERE IndividualApplication.AccountId = :accountId

-- Open OM tasks for an order
SELECT Id, Name, Status,
    vlocity_cmt__OrchestrationPlan__r.vlocity_cmt__Order__r.OrderNumber,
    vlocity_cmt__ItemImplementation__r.Name,
    vlocity_cmt__OrchestrationQueue__r.Name
FROM vlocity_cmt__OrchestrationItem__c
WHERE vlocity_cmt__OrchestrationPlan__r.vlocity_cmt__Order__c = :orderId
AND Status != 'Completed'
ORDER BY vlocity_cmt__Sequence__c ASC

-- TimeSheetEntry for a service resource (standard E&U objects — no vlocity_cmt prefix)
-- TimeSheet and TimeSheetEntry are standard objects; PayType, OvertimeType are related
SELECT Id, TimeSheetId, StartDateTime, EndDateTime, Status, StatusComment, Category,
    TimeBlockSequence,
    TimeSheet.ServiceResourceId,
    TimeSheet.PayGrade.Name,
    TimeSheet.Status,
    JobExpenseType.Name,
    OvertimeType.Name
FROM TimeSheetEntry
WHERE TimeSheet.ServiceResourceId = :resourceId
AND TimeSheet.StartDateTime >= :periodStart
AND TimeSheet.EndDateTime <= :periodEnd
ORDER BY TimeBlockSequence ASC

-- Calculation matrix lookup for pricing
SELECT Id, DeveloperName,
    vlocity_cmt__MatrixType__c,
    (SELECT Id, vlocity_cmt__InputValue__c, vlocity_cmt__OutputValue__c
     FROM vlocity_cmt__CalculationMatrixRows__r
     WHERE vlocity_cmt__IsActive__c = true)
FROM vlocity_cmt__CalculationMatrix__c
WHERE DeveloperName = 'ResidentialRateMatrix'
```
