---
source: "Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide); mfg_api_devguide.pdf (Spring '26, April 30, 2026)"
cloud: Manufacturing Cloud
section: api-reference
last-updated: 2026-05-10
---

# Manufacturing Cloud — API Reference

Manufacturing Cloud Business APIs are RESTful APIs that are sometimes available as Apex classes and methods. These APIs follow similar conventions as Connect REST APIs.

For architecture, authentication, rate limits, and request/response conventions, see the Connect REST API Developer Guide.

---

## Connect REST API Endpoints

### Sales Agreement (POST)

**Purpose:** Create a sales agreement from an external source, including quote, opportunity, or custom object.

**Resource:** `/services/data/vXX.X/connect/manufacturing/sales-agreements`

**Available version:** 51.0

**HTTP methods:** POST

**Requires Chatter:** No

**Special Access Rules:** Salesforce org must have the Manufacturing Cloud license with the Sales Agreements permission set.

**Request Body (JSON example):**
```json
{
  "sourceObjectId": "0kFT1000000000RMAQ",
  "salesAgreementDefaultValues": {
    "salesAgreement": {
      "StartDate": "2020-01-01",
      "ScheduleFrequency": "Monthly",
      "ScheduleCount": "10"
    },
    "salesAgreementProduct": {
      "PricebookEntry": "01uxx00000091jOAAQ",
      "Name": "test-sap1",
      "InitialPlannedQuantity": "1"
    }
  }
}
```

**Request Body Properties:**

| Name | Type | Description | Required | Available Version |
|---|---|---|---|---|
| salesAgreementDefaultValues | Sales Agreement Default Fields Input[] | Default field values for SalesAgreement and SalesAgreementProduct entities not defined in the mapping definition. Note: You can remove a mapping field from the definition by providing the output field value as blank for SalesAgreement or SalesAgreementProduct | Optional | 51.0 |
| sourceObjectId | String | ID of the source object containing the mapping definition used to create the sales agreement record | Required | 51.0 |

**Response Body:** Sales Agreement Output

**Prerequisite:** Before use, configure a `ConvertToSalesAgreement` mapping usage type in `ObjectHierarchyRelationship` settings to map an input object (Quote or Opportunity) to an output object (SalesAgreement) and define field mappings. All products from the source object child entity will be added to the sales agreement. To use decimal values, map quantity values to `InitialPlannedQtyValue`.

---

### Sample Management (POST)

**Purpose:** Creates, updates, or versions Product Requirement Specification records.

**Resource:** `/connect/manufacturing/sample-management/product-specifications`

**Resource Example:** `https://yourInstance.salesforce.com/services/data/v66.0/connect/manufacturing/sample-management/product-specifications`

**Available version:** 66.0

**HTTP methods:** POST

**Request Body (JSON example):**
```json
{
  "requestUniqueId": "insert_op_req_1",
  "operation": "Insert",
  "productRequirementSpecification": {
    "properties": [
      { "field": "Name", "value": "Project Everest Core Requirements" },
      { "field": "AccountId", "value": "001xx000003GaGxAAK" },
      { "field": "Status", "value": "Draft" }
    ],
    "productRequirementSpecificationVersions": [
      {
        "properties": [
          { "field": "Name", "value": "Functional1136" },
          { "field": "Purpose", "value": "To define the MVP features" },
          { "field": "Version", "value": "2" }
        ],
        "productRequirementSpecificationItems": [
          {
            "properties": [
              { "field": "Name", "value": "Functional1136" },
              { "field": "Statement", "value": "The system shall display a real-time summary of KPIs" },
              { "field": "Category", "value": "Functional" }
            ]
          }
        ]
      }
    ]
  }
}
```

**Request Body Properties:**

| Name | Type | Description | Required | Available Version |
|---|---|---|---|---|
| operation | String | The action to perform | Required | 66.0 |
| productRequirementSpecification | Product Requirement Specification Input[] | The Product Requirement Specification data to process | Required | 66.0 |
| requestUniqueId | String | A unique ID for request tracing. Returned in the response | Optional | 66.0 |

**Response Body:** Sample Management Output

---

### Transformations (POST)

**Purpose:** Perform the business transformation of program component forecast data (source object) to opportunities (target object).

Supported transformation scenarios:
- `MfgProgramCpntFrcstFact` to `Opportunity`
- `ManufacturingProgram` to `Opportunity`
- `MfgProgramCpntFrcstFact` to `OpportunityLineItem`
- `Period` to `OpportunityLineItemSchedule`

**Resource:** `/connect/manufacturing/transformations`

**Resource Example:** `https://yourInstance.salesforce.com/services/data/vXX.X/connect/manufacturing/transformations`

**Available version:** 55.0

**HTTP methods:** POST

**Request Body Properties:**

| Name | Type | Description | Required | Available Version |
|---|---|---|---|---|
| inputObjectIds | String[] | IDs of the source objects for transformation | Required | 55.0 |
| contextMapping | String | The context mapping that defines how data is mapped | Optional | 55.0 |
| conversionType | String | The type of conversion to perform | Optional | 55.0 |

**Request Body (JSON example):**
```json
{
  "inputObjectIds": [
    "0sTxx000000003FEAQ"
  ],
  "contextMapping": "ClaimDetailsMapping",
  "conversionType": "Supplier Recovery Claim",
  "supplierRecoveryProducts": [
    {
      "product2Id": "01tSB000000PXLlYAO",
      "salesContractLineId": "0sLSB00000001Ab2AI"
    }
  ]
}
```

**Response Body:** Transformation Output

---

### Warranty To Supplier Claims (POST)

**Purpose:** Clones an existing warranty claim and its hierarchy (claim items, claim coverage, claim coverage payment details) to create supplier recovery claims.

**Resource:** `/connect/manufacturing/warranty-to-supplier-claims`

**Available version:** 61.0

**HTTP methods:** POST

**Request Body Properties:**

| Name | Type | Description | Required | Available Version |
|---|---|---|---|---|
| warrantyClaimIds | String[] | IDs of the warranty claim records to clone | Required | 61.0 |
| contextMapping | String | Context mapping for the cloning operation | Optional | 61.0 |
| conversionType | String | The type of conversion (e.g., `Supplier Recovery Claim`) | Optional | 61.0 |
| supplierRecoveryProducts | Object[] | Products for supplier recovery, each containing `product2Id` and optionally `salesContractLineId` | Optional | 61.0 |

**Response Body:** Warranty To Supplier Claims Output

---

## Request Bodies

### Sales Agreement Default Fields Input
Default field values for SalesAgreement and SalesAgreementProduct entities.

### Sales Agreement Input
Input representation for the Sales Agreement POST endpoint.

### Product Requirement Specification Input
The Product Requirement Specification data to process for the Sample Management endpoint.

### Product Requirement Specification Item Input
Represents a specific item within a requirement specification version.

### Product Requirement Specification Version Input
Represents a version of a requirement specification.

### Sample Management Input
Input representation for the Sample Management POST endpoint.

### Transformation Input
Input representation for the Transformations POST endpoint.

### Warranty To Supplier Claims Input
Input representation for the Warranty To Supplier Claims POST endpoint.

---

## Response Bodies

### Sales Agreement Output
Output from the Sales Agreement (POST) endpoint.

### Sample Management Output

**Response (JSON example):**
```json
{
  "message": "Product Requirement Specification retrieved successfully",
  "data": {
    "id": "0Dm5g000000KyZ3CAK",
    "name": "Pharmaceutical Grade Tablet Specification",
    "status": "Active",
    "priority": "High",
    "productRequirementSpecificationVersions": [
      {
        "id": "0Dn5g000000LmN4CAK",
        "name": "Version 2.0",
        "version": 2,
        "purpose": "Define specifications for manufacturing pharmaceutical tablets",
        "effectiveDate": "2024-02-01T00:00:00.000Z",
        "productRequirementSpecificationItems": [...]
      }
    ]
  },
  "errors": null
}
```

**Response Properties:**

| Property Name | Type | Description | Filter Group | Available Version |
|---|---|---|---|---|
| data | Product Requirement Specification Output[] | The resulting Product Requirement Specification data | Small | 66.0 |
| errors | Product Requirement Specification Error Detail[] | A list of errors. Null if successful | Small | 66.0 |
| message | String | A message confirming the result of the operation | Small | 66.0 |
| requestUniqueId | String | The unique ID from the request, used for tracing | Small | 66.0 |
| status | String | The status of the operation | Small | 66.0 |

### Object Details Output
Output representation for object detail information.

### Product Requirement Specification Output
Output representation of a Product Requirement Specification record.

### Product Requirement Specification Error
Error representation for Product Requirement Specification operations.

### Product Requirement Specification Error Detail
Detailed error information for Product Requirement Specification operations.

### Product Requirement Specification Item Output
Output representation of a Product Requirement Specification Item.

### Product Requirement Specification Version Output
Output representation of a Product Requirement Specification Version.

### Transformation Output

**JSON example:**
```json
{
  "outputObjectDetails": [
    { "outputId": "Y_id1", "inputIds": ["X_id1", "X_id2"] }
  ],
  "errorDetails": [
    { "inputIds": ["X_id3", "X_id4"], "errorReason": "Mandatory field1 missing value" }
  ],
  "Status": ""
}
```

**Properties:**

| Property Name | Type | Description | Available Version |
|---|---|---|---|
| outputObjectDetails | Object Details Output[] | Provides information on input and output IDs, error details, and transformation status | 55.0 |
| status | String | The status of the transformation request | 55.0 |

### Warranty To Supplier Claims Output
Output representation with the supplier recovery claims created from warranty claims.

**Properties:**

| Property Name | Type | Description | Available Version |
|---|---|---|---|
| supplierClaimsIds | String[] | The IDs of the claim records of the claim type Supplier Recovery Claim | 61.0 |

---

## Invocable Actions

Manufacturing Cloud exposes standard invocable actions for use in Flow Builder, Process Builder, and direct REST calls.

**Base URI for all actions:** `/services/data/vXX.X/actions/standard/{actionName}`

**Authentication:** `Authorization: Bearer token`

---

### Calculate Advanced Account Forecasts Action

**Action name:** `calculateAdvancedAccountForecast`

**URI:** `/services/data/vXX.X/actions/standard/calculateAdvancedAccountForecast`

**Purpose:** Calculate forecasts for an account based on the formulae associated with the forecast set.

**Available version:** 52.0

**HTTP Methods:** GET, POST

**Formats:** JSON

**Inputs:**

| Input | Type | Description |
|---|---|---|
| accountId | array | The ID of the account record for which to calculate the forecasts |
| forecastDataId | array | The ID of the forecast data for which the forecast is being calculated |
| forecastSetId | array | The ID of the forecast set associated with the forecast formulae to be used for calculation |

**Sample Request:**
```json
{
  "inputs": [{
    "forecastSetId": "0ni5sajb8347k3s",
    "accountId": "0yAxx00004000002AAA",
    "forecastDataId": "0r4ft8941574TRE78V"
  }]
}
```

**Sample Response:**
```json
[{ "errors": null, "isSuccess": true }]
```

---

### Import Records from CSV File Action

**Action name:** `importRecordsFromCsvFile`

**URI:** `/services/data/v55.0/actions/standard/importRecordsFromCsvFile`

**Purpose:** Import and convert data from an uploaded CSV file into records of the target object.

**Available version:** 55.0

**HTTP Methods:** GET, HEAD, POST

**Formats:** JSON, XML

**Special Access Rules:** To access this action, enable the "Import CSV for Advanced Account Forecasting" system permission with the Manufacturing Advanced Account Forecast permission set, OR enable the Manufacturing Program Based Business permission set.

**Inputs:**

| Input | Type | Required | Description |
|---|---|---|---|
| externalIdFieldName | string | Required (optional if operationType is insert) | The name of the target object field that contains the external ID, used for upsert operations |
| operationType | string | Required | The type of operation to perform. Valid values: `upsert`, `insert` |
| receivedDocumentId | string | Required | The ID of the received document record to be converted |
| targetObjectApiName | string | Required | The API name of the object used to convert the CSV file data into records |

**Outputs:** None.

**Sample POST Request:**
```json
{
  "inputs": [{
    "receivedDocumentId": "0ioT10000000043IAA",
    "targetObjectApiName": "MfgProgramForecastFact",
    "operationType": "upsert",
    "externalIdFieldName": "ExternalId__c"
  }]
}
```

**Sample Response:**
```json
[{ "actionName": "importRecordsFromCsvFile", "errors": null, "isSuccess": true }]
```

---

### Refresh Actuals Calculation Action

**Action name:** `refreshActualsCalculation`

**URI:** `/services/data/vXX.X/actions/standard/refreshActualsCalculation`

**Purpose:** Refresh actuals calculations for sales agreements for current and past periods.

**Available version:** 47.0

**Required permission set:** Manufacturing Sales Agreements

**HTTP Methods:** GET, HEAD, POST

**Formats:** JSON, XML

**Important:** These actions update the actuals data in your Salesforce org. You must perform a database rollback to undo these actions.

**Inputs:**

| Input | Type | Description |
|---|---|---|
| userId | ID | The ID of the user. An email is sent to this user when the action is complete |
| salesAgreementId | string | The ID of the sales agreement for refreshing actuals |
| isCurrentAndFutureSchedules | boolean | true = refresh actuals for current period and future schedules (number based on FutureActCalcSchedules field); false = current only. If both isCurrentAndFutureSchedules and isCurrentSchedule are true, the action fails |
| isCurrentSchedule | boolean | true = refresh actuals for current period only; false = refresh current and past periods |

**Sample Request:**
```json
{
  "inputs": [{
    "userId": "005Ws000001Agn0IAC",
    "salesAgreementId": "0YAWs0000004FkBOAU",
    "isCurrentSchedule": true,
    "isCurrentAndFutureSchedules": false
  }]
}
```

**Sample Success Response:**
```json
[{
  "actionName": "refreshActualsCalculation",
  "errors": null,
  "isSuccess": true,
  "outputValues": {
    "isSuccess": true,
    "message": "Actuals calculation refreshed successfully",
    "recordsProcessed": 15,
    "salesAgreementId": "0YAWs0000004FkBOAU"
  }
}]
```

**Sample Error Response:**
```json
[{
  "actionName": "refreshActualsCalculation",
  "errors": [{
    "statusCode": "INVALID_INPUT",
    "message": "Sales Agreement not found or user does not have access",
    "fields": ["salesAgreementId"]
  }],
  "isSuccess": false,
  "outputValues": null
}]
```

---

### Recalculate Forecasts Action

**Action name:** `recalculateForecast`

**URI:** `/services/data/vXX.X/actions/standard/recalculateForecast`

**Purpose:** Recalculate forecasts based on orders, opportunity, and sales agreement figures.

**Available version:** 47.0

**Required:** Manufacturing Cloud license

**HTTP Methods:** GET, HEAD, POST

**Formats:** JSON, XML

**Important:** These actions update the forecast data in your Salesforce org. You must perform a database rollback to undo these actions.

**Inputs:**

| Input | Type | Description |
|---|---|---|
| userId | ID | The ID of the user. An email is sent to this user when the action is complete |
| forecastId | string | The ID of the forecast for recalculation. Use `ALL` to recalculate all account forecasts |

**Sample Request (single forecast):**
```json
{ "inputs": [{ "userId": "005xx000001X7QLAA0", "forecastId": "0yAxx0000000001EAA" }] }
```

**Sample Request (all forecasts):**
```json
{ "inputs": [{ "userId": "005xx000001X7QLAA0", "forecastId": "ALL" }] }
```

---

### Mass Update Account Forecast Action

**Action name:** `massUpdateAccountForecast`

**URI:** `/services/data/vXX.X/actions/standard/massUpdateAccountForecast`

**Purpose:** Mass update account forecast fields for different products and periods with a single action.

**Available version:** 48.0

**Required:** Manufacturing Cloud license

**HTTP Methods:** GET, HEAD, POST

**Formats:** JSON, XML

**Important:** These actions update the forecast data in your Salesforce org. You must perform a database rollback to undo these actions.

**Inputs:**

| Input | Type | Description |
|---|---|---|
| entityId | string | The ID of the forecast to mass update |
| fieldToUpdate | string | The developer name of an AccountProductPeriodForecast field (e.g., `ForecastedQuantity`) |
| periods | anyType | Comma-separated list of period IDs |
| products | anyType | Comma-separated list of account forecast product IDs |
| operation | string | Operation for mass update. Valid values: `IncreaseBy`, `DecreaseBy`, `ReplaceWith` |
| numericvalue | double | Numeric value to use in the operation (up to 15 digits) |
| numericValueType | string | Type of operation. Valid values: `Percentage`, `Absolute` |
| adjNote | string | Any comments on the mass update operation |

---

### Mass Update Sales Agreement Action

**Action name:** `massUpdateSalesAgreement`

**URI:** `/services/data/vXX.X/actions/standard/massUpdateSalesAgreement`

**Purpose:** Mass updates to sales agreement fields for different products and periods with a single action.

**Available version:** 48.0

**Required:** Manufacturing Cloud license

**HTTP Methods:** GET, HEAD, POST

**Formats:** JSON, XML

**Important:** These actions update the sales agreement based data in your Salesforce org. You must perform a database rollback to undo these actions.

**Inputs:**

| Input | Type | Description |
|---|---|---|
| entityId | string | The ID of the sales agreement to mass update |
| fieldToUpdate | string | The developer name of a SalesAgreementProductSchedule field (e.g., `SalesPrice`) |
| periods | anyType | List of SalesAgreementProductSchedule periods in `yyyy-MM-dd` date format (e.g., `2020-01-01,2020-02-01`) |
| products | anyType | Comma-separated list of sales agreement product IDs |
| operation | string | Operation for mass update. Valid values: `Increase By`, `Decrease By`, `Replace With` |
| numericvalue | double | Numeric value to use (up to 15 digits) |
| numericValueType | string | Type of operation. Valid values: `percentage`, `absolute` |

**Sample Request:**
```json
{
  "inputs": [{
    "entityId": "0YALT000000H9rh4AC",
    "products": ["0YBLT0000000Mq94AE"],
    "periods": ["ALL"],
    "fieldToUpdate": "SalesPrice",
    "operation": "Increase By",
    "numericValue": "15",
    "numericValueType": "absolute"
  }]
}
```

---

### Update Account Manager Target Values Action

**Action name:** `updateAcctMgrTarget`

**URI:** `/services/data/vXX.X/actions/standard/updateAcctMgrTarget`

**Purpose:** Update an account manager target's assignment values when the target's value changes, based on the parent's target value and percentage.

**Available version:** 49.0

**Required:** Manufacturing Cloud license

**HTTP Methods:** GET, HEAD, POST

**Formats:** JSON, XML

**Inputs:**

| Input | Type | Required | Description |
|---|---|---|---|
| entityId | ID | Required | The ID of the account manager target record |

---

### Mass Update Advance Account Forecast Action

**Action name:** `massUpdateAdvAccountForecast`

**URI:** `/services/data/vXX.X/actions/standard/massUpdateAdvAccountForecast`

**Purpose:** Update a measure of AdvAccountForecastFact records based on a filter condition of the selected list view.

**Available version:** 56.0

**HTTP Methods:** POST

**Formats:** JSON, XML

**Special Access Rules:** Manufacturing Cloud and Advance Account Forecasting feature must both be enabled.

**Inputs:**

| Input | Type | Required | Description |
|---|---|---|---|
| actionType | String | Required | The type of action to perform on the selected measure. Valid values: `DecreaseBy`, `IncreaseBy`, `ReplaceWith` |
| forecastReferenceId | String | Required | The ID of the advanced account forecast set use record OR advanced account forecast set partner record to be updated |
| isPercent | Boolean | Required | Specifies whether the values are a percentage (true) or not (false). Default: false |
| listViewId | String | Required | The ID of the list view record containing the filtered forecast fact records to be updated |
| measureFieldName | String | Required | The API name of a measure field on the list view object to be updated in the forecast records |
| value | String | Required | The value to use to update the measure |

**Outputs:**

| Output | Type | Description |
|---|---|---|
| errors | List\<String\> | A list of error messages if the operation fails |
| isSuccess | Boolean | Indicates whether the operation is successful |

**Sample Request:**
```json
{
  "inputs": [{
    "actionType": "Increase By",
    "forecastReferenceId": "0ogT10000000BekIAE",
    "isPercent": false,
    "listViewId": "00BT1000000WIUxMAO",
    "measureFieldName": "custom_measure__c",
    "value": "1"
  }]
}
```

---

### Update Advanced Account Forecast Set Partner Action

**Action name:** `updateAdvancedAccountForecastSetPartner`

**URI:** `/services/data/vXX.X/actions/standard/updateAdvancedAccountForecastSetPartner`

**Purpose:** Updates the status of the Advanced Account Forecast Set Partner record after the forecast data for a given combination of account and forecast set has been generated.

**Available version:** 53.0

**HTTP Methods:** POST

**Formats:** JSON

**Inputs:**

| Input | Type | Required | Description |
|---|---|---|---|
| accountId | string | Optional | The ID of an account record |
| forecastSetId | string | Required | The ID of the advanced account forecast set associated with the account |
| status | string | Optional | Status to set for the Advanced Account Forecast Set Partner record. Valid values: `Active`, `Inactive`. Can change from Draft to Active or Active to Inactive. Default: sets status from Draft to Active |

**Sample Requests:**
```json
// Set specific account+set to Active
{ "inputs": [{ "forecastSetId": "0ni5sajb8347k3s", "accountId": "001jsdhsdjo457", "status": "Active" }] }

// Set all partners for a forecast set to Active
{ "inputs": [{ "forecastSetId": "0ni5sajb8347k3s" }] }

// Set all partners for a forecast set to Inactive
{ "inputs": [{ "forecastSetId": "0ni5sajb8347k3s", "status": "Inactive" }] }
```

---

## Apex Reference

### Namespace: ind_mfg_sample_mgmt_apex

The `ind_mfg_sample_mgmt_apex` namespace provides classes and properties to manage the lifecycle and documentation of product requirements in manufacturing. Create, update, or version Product Requirement Specification records to ensure sample data remains consistent and compliant with production standards.

#### Classes in ind_mfg_sample_mgmt_apex

| Class | Description |
|---|---|
| `ProductRequirementSpecification` | Represents the resulting product requirement specification data |
| `ProductRequirementSpecificationItem` | A list of items for this specification version |
| `ProductRequirementSpecificationVersion` | A list of versions for this specification |

---

### ProductRequirementSpecification Class

**Namespace:** `ind_mfg_sample_mgmt_apex`

**Description:** Represents the resulting product requirement specification data.

**Properties:**

| Property | Signature | Type | Description |
|---|---|---|---|
| accountId | `public String accountId {get; set;}` | String | The ID of the associated customer account |
| contactId | `public String contactId {get; set;}` | String | The ID of the contact at the associated account |
| createdById | `public String createdById {get; set;}` | String | The ID of the user who created the specification |
| createdDate | `public String createdDate {get; set;}` | String | The creation date and time of the specification |
| customAttributes | `public String customAttributes {get; set;}` | String | A JSON string containing custom fields and their values |
| id | `public String id {get; set;}` | String | The ID of the Product Requirement Specification |
| lastModifiedById | `public String lastModifiedById {get; set;}` | String | The ID of the user who last modified the specification |
| lastModifiedDate | `public String lastModifiedDate {get; set;}` | String | The last modified date and time of the specification |
| latestVersionId | `public String latestVersionId {get; set;}` | String | The ID of the latest version of the specification |
| name | `public String name {get; set;}` | String | The name of the Product Requirement Specification |
| origin | `public String origin {get; set;}` | String | The source that initiated the requirement |
| ownerId | `public String ownerId {get; set;}` | String | The ID of the user who owns the specification |
| priority | `public String priority {get; set;}` | String | The priority of the requirement |
| productRequirementSpecificationVersion | `public ind_mfg_sample_mgmt_apex.ProductRequirementSpecificationVersion productRequirementSpecificationVersion {get; set;}` | `ind_mfg_sample_mgmt_apex.ProductRequirementSpecificationVersion` | A list of versions for this specification |
| stage | `public String stage {get; set;}` | String | The current stage of the specification in its workflow |
| status | `public String status {get; set;}` | String | The current status of the specification |

---

### ProductRequirementSpecificationItem Class

**Namespace:** `ind_mfg_sample_mgmt_apex`

**Description:** A list of items for this specification version.

**Properties:**

| Property | Signature | Type | Description |
|---|---|---|---|
| acceptanceCriteria | `public String acceptanceCriteria {get; set;}` | String | The measurable conditions for requirement fulfillment |
| additionalInfo | `public String additionalInfo {get; set;}` | String | Additional notes or instructions for this item |
| category | `public String category {get; set;}` | String | The type of requirement, such as Functional or Performance |
| createdById | `public String createdById {get; set;}` | String | The ID of the user who created the item |
| createdDate | `public String createdDate {get; set;}` | String | The creation date and time of the item |
| customAttributes | `public String customAttributes {get; set;}` | String | A JSON string containing custom fields and their values |
| id | `public String id {get; set;}` | String | The ID of the specification item |
| lastModifiedById | `public String lastModifiedById {get; set;}` | String | The ID of the user who last modified the item |
| lastModifiedDate | `public String lastModifiedDate {get; set;}` | String | The last modified date and time of the item |
| name | `public String name {get; set;}` | String | The name of the specification item |
| ownerId | `public String ownerId {get; set;}` | String | The ID of the user who owns the item |
| productRqmtSpecVersionId | `public String productRqmtSpecVersionId {get; set;}` | String | The ID of the parent specification version |
| riskLevel | `public String riskLevel {get; set;}` | String | The criticality of this requirement |
| statement | `public String statement {get; set;}` | String | A detailed, testable statement of the requirement |
| targetValue | `public String targetValue {get; set;}` | String | The specific, desired value for this requirement |
| tolerance | `public String tolerance {get; set;}` | String | The acceptable range of deviation from the target value |
| unitOfMeasureId | `public String unitOfMeasureId {get; set;}` | String | The ID of the unit of measure for the target value and tolerance |
| verificationMethod | `public String verificationMethod {get; set;}` | String | The method used to validate this requirement |

---

### ProductRequirementSpecificationVersion Class

**Namespace:** `ind_mfg_sample_mgmt_apex`

**Description:** A list of versions for this specification.

**Properties:**

| Property | Signature | Type | Description |
|---|---|---|---|
| additionalInfo | `public String additionalInfo {get; set;}` | String | Additional notes or instructions for this version |
| assumptions | `public String assumptions {get; set;}` | String | Conditions or beliefs assumed to be true for the design |
| constraints | `public String constraints {get; set;}` | String | Limitations, such as cost or time, that must be met |
| contentDocumentId | `public String contentDocumentId {get; set;}` | String | The ID of an attached document |
| createdById | `public String createdById {get; set;}` | String | The ID of the user who created the version |
| createdDate | `public String createdDate {get; set;}` | String | The creation date and time of the version |
| customAttributes | `public String customAttributes {get; set;}` | String | A JSON string containing custom fields and their values |
| effectiveDate | `public String effectiveDate {get; set;}` | String | The date this specification version becomes valid |
| expiryDate | `public String expiryDate {get; set;}` | String | The date this specification version becomes obsolete |
| id | `public String id {get; set;}` | String | The ID of the specification version |
| intendedUse | `public String intendedUse {get; set;}` | String | The business or functional goal of the product |
| lastModifiedById | `public String lastModifiedById {get; set;}` | String | The ID of the user who last modified the version |
| lastModifiedDate | `public String lastModifiedDate {get; set;}` | String | The last modified date and time of the version |
| name | `public String name {get; set;}` | String | The name of the specification version |
| ownerId | `public String ownerId {get; set;}` | String | The ID of the user who owns the version |
| productRequirementSpecificationItems | `public List<ind_mfg_sample_mgmt_apex.ProductRequirementSpecificationItem> productRequirementSpecificationItems {get; set;}` | `List<ind_mfg_sample_mgmt_apex.ProductRequirementSpecificationItem>` | A list of items for this specification version |
| productRqmtSpecId | `public String productRqmtSpecId {get; set;}` | String | The ID of the parent specification |
| purpose | `public String purpose {get; set;}` | String | The business reason for the requirement |
| refProductCategoryId | `public String refProductCategoryId {get; set;}` | String | The ID of the category for the reference product |
| refProductId | `public String refProductId {get; set;}` | String | The ID of a reference or baseline product |
| scope | `public String scope {get; set;}` | String | The defined boundaries for the product or project |
| verificationMethod | `public String verificationMethod {get; set;}` | String | The method used to confirm the requirement is met |
| version | `public Integer version {get; set;}` | Integer | The version number |

---

## Flow Metadata for Manufacturing Cloud

Manufacturing Cloud exposes additional `actionType` values for the `FlowActionCall` Metadata type. This enables Manufacturing Cloud invocable actions to be called from Flow.

**Additional valid values for InvocableActionType (Manufacturing Cloud only):**

| Value | Available Version |
|---|---|
| Sales Agreement | 61.0 and later |

For more information on Flow and FlowActionCall metadata, see the Metadata API Developer Guide.
