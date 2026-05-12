---
source: "Salesforce Manufacturing Cloud Developer Guide (mfg_api_devguide); mfg_api_devguide.pdf (Spring '26, April 30, 2026)"
cloud: Manufacturing Cloud
section: metadata-tooling
last-updated: 2026-05-10
---

# Manufacturing Cloud — Metadata API and Tooling API

## Metadata API Types

Metadata API enables you to access some types and feature settings that you can customize in the user interface. For more information about Metadata API and to find a complete reference of existing metadata types, see the Metadata API Developer Guide.

---

### AccountForecastSettings

**Description:** Represents settings that define the generation of account forecasts and their display on the account's record page. These settings also define the periods during which the account forecast values can be edited and the formula definitions for account forecast calculations.

**File Suffix and Directory Location:** `AccountForecastSettings.accountForecastSetting` file in the `accountForecastSettings` folder.

**Available Version:** 47.0 and later.

**Note:** In the package manifest, all organization settings metadata types are accessed using the Settings name.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| accountFilterId | string | Specifies the list view having a filtered list of accounts. Only the accounts in the entered list view are eligible for account forecasting. Available in API version 49.0 and later |
| accountForecastFormulas | AccountForecastFormula | Holds the formula for quantity and revenue metrics based on sales agreements, orders, opportunities, and account metrics. Not derived — defined by the admin user. Can have one or more formulas per org |
| acctPrdctPrdFrcstVolCnt | int | The number of existing records in the AccountProductPeriodForecast object. Available in API version 49.0 and later |
| calculationFrequency | CalculationFrequency (enum) | Required. Source from which frequency of account forecast recalculation is derived. Valid values: `Monthly`, `Quarterly`, `Yearly`, `Weekly` (Weekly available from API v55.0) |
| displayDuration | int | Required. Number of periods for which forecast is generated and displayed |
| displayedForecastMetrics | string | Required. The quantity metrics selected for display in the account forecast in specified sequence. Maximum 10 comma-separated metric names |
| displayedRevenueMetrics | string | Required. The revenue metrics selected for display in the account forecast in specified sequence. Maximum 10 comma-separated metric names |
| editableAtStartOfPeriod | boolean | Required. Indicates whether account forecast can be adjusted at the start of the adjustment period (true) or not (false) |
| editsAllowedFor | int | Required. Number of days from which the adjustment period is derived |
| forecastFrequency | ForecastFrequency (enum) | Required. Source from which frequency of account forecast generation is derived. Valid values: `Monthly`, `Quarterly`, `Yearly`, `Weekly` (Weekly from API v55.0) |
| objectMapping | ObjectMapping | Foreign key to ObjectMapping that maps fields from AccountProductPeriodForecast (input) to AccountProductForecast (output) |
| opportunityProbabilityEnabled | boolean | Indicates whether to use probability of opportunities to calculate forecast values (true) or not (false). Available in API version 50.0 and later |
| primaryNotifEmailAddress | string | The email address to which notifications are sent |
| productFilterId | string | Specifies the list view having a filtered list of products. Only products in the entered list view are valid for account forecasting. Available in API version 49.0 and later |
| recalculateAllFrcstCnt | int | The number of times account forecasts are recalculated for all eligible accounts in an org. Available in API version 49.0 and later |
| regenerateForecastCnt | int | Number of times account forecasts are regenerated for all eligible accounts in an org. Available in API version 49.0 and later |
| salesAgreementFilterId | string | Specifies the list view having a filtered list of sales agreements eligible for account forecasting. Available in API version 50.0 and later |
| secondaryNotifEmailAddress | string | The second email address to which notifications are sent |
| startingPeriod | int | Required. Number of periods to go back from the current date for account forecast generation |

**Nested Type — AccountForecastFormula:**

| Field Name | Field Type | Description |
|---|---|---|
| endingPeriod | int | Required. The period until which the forecast formula is effective |
| formula | string | Required. The formula based on which AccountProductPeriodForecast values are calculated |
| formulaType | FormulaType (enum) | Required. Valid values: `QUANTITY`, `REVENUE` |
| startingPeriod | int | Required. The period from which the forecast formula is effective |

**Nested Type — ObjectMapping:**

| Field Name | Field Type | Description |
|---|---|---|
| inputObject | string | Required. The input object (AccountProductPeriodForecast) |
| mappingFields | ObjectMappingField[] | The mapping of source object fields to target object fields |
| outputObject | string | Required. The output object (AccountProductForecast) |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<AccountForecastSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <accountForecastFormulas>
    <endingPeriod>12</endingPeriod>
    <formula>SalesAgreementPlannedQuantity + OpportunityQuantity</formula>
    <formulaType>QUANTITY</formulaType>
    <startingPeriod>1</startingPeriod>
  </accountForecastFormulas>
  <calculationFrequency>QUARTERLY</calculationFrequency>
  <displayDuration>12</displayDuration>
  <displayedForecastMetrics>OpportunityQuantity,CurrentOrdersQuantity,SalesAgreementPlannedQuantity</displayedForecastMetrics>
  <displayedRevenueMetrics>OpportunityRevenue,CurrentOrdersRevenue,SalesAgreementPlannedRevenue</displayedRevenueMetrics>
  <editableAtStartOfPeriod>true</editableAtStartOfPeriod>
  <editsAllowedFor>15</editsAllowedFor>
  <forecastFrequency>MONTHLY</forecastFrequency>
  <startingPeriod>3</startingPeriod>
  <primaryNotifEmailAddress>abc@example.com</primaryNotifEmailAddress>
  <objectMapping>
    <inputObject>AccountProductPeriodForecast</inputObject>
    <mappingFields>
      <inputField>APPF1__c</inputField>
      <outputField>APF1__c</outputField>
    </mappingFields>
    <outputObject>AccountProductForecast</outputObject>
  </objectMapping>
</AccountForecastSettings>
```

**Sample package.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>AccountProductForecast.APF1__c</members>
    <members>AccountProductPeriodForecast.APPF1__c</members>
    <name>CustomField</name>
  </types>
  <types>
    <members>*</members>
    <name>AccountForecastSettings</name>
  </types>
  <version>47.0</version>
</Package>
```

---

### AcctMgrTargetSettings

**Description:** Represents the settings of account manager targets. These settings define the distribution frequency, the hierarchy of team members for assignments, and the default price book of account manager targets. Also displays the record usage details by account manager targets in your Salesforce org.

**File Suffix and Directory Location:** `acctMgrTargetSetting` in the `acctMgrTargetSettings` folder.

**Available Version:** 49.0 and later.

**Special Access Rules:** Your Salesforce org must have the Manufacturing Cloud license.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| acctMgrPeriodicTargetDstrCnt | int | The number of existing records in the AcctMgrTargetDstr object |
| periodType | PeriodTypes (enum) | Required. Indicates the type of period to use for distribution. Values: `Month`, `Quarter`, `Year` |
| pricebookId | string | The ID of the default price book selected for account manager target distribution by product |
| teamMemberHierarchyType | TeamMemberHierarchyType (enum) | Required. The hierarchy type of team members for assignments. Values: `ManagerHierarchy`, `ForecastsHierarchy` |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<AcctMgrTargetSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <periodType>Month</periodType>
  <teamMemberHierarchyType>ManagerHierarchy</teamMemberHierarchyType>
</AcctMgrTargetSettings>
```

**Wildcard Support:** This metadata type supports the wildcard character `*` in the package.xml manifest file.

---

### ActionableEventOrchDef

**Description:** Represents the definition of an actionable event orchestration so that the records can be migrated from one org to another.

**File Suffix and Directory Location:** `.actionableEventOrchDef` in the `ActionableEventOrchDef` folder.

**Available Version:** 64.0 and later.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| actionableEventUsageType | string | The usage type of the actionable event orchestration definition. Values: `Automotive` (1), `Manufacturing` (2), `Standard` (3) |
| apiName | string | Required. The API name of the actionable event orchestration definition record |
| contextDefinitionDeveloperName | string | The developer name of a context definition associated with this record |
| contextMappingTitle | string | The title of a context mapping associated with this record |
| eventCategory | string | The category of an actionable event orchestration definition |
| eventSubtypeApiName | string | The API name of an actionable event orchestration definition subtype |
| eventTypeApiName | string | Required. The API name of an actionable event orchestration definition type |
| executionProcedureAPIName | string | The API name of the flow definition or expression set template that executes the orchestration |
| executionProcedureType | string | Specifies the type of automated procedure. Values: `ExpressionSetBasedOrchestration` (1), `FlowBasedOrchestration` (2) |
| isActive | boolean | Required. Specifies if the record is active (true) or not (false). Default: false |
| isTemplate | boolean | Required. Indicates whether this is a template (true) or not (false). Default: false |
| label | string | Required. The label of the actionable event orchestration definition record |

**Wildcard Support:** This metadata type supports the wildcard character `*` in the package.xml manifest file.

---

### ActionableEventTypeDef

**Description:** Represents the definition of an actionable event type so that the records can be migrated from one org to another.

**File Suffix and Directory Location:** `.ActionableEventTypeDef` in the `ActionableEventTypeDef` folder.

**Available Version:** 64.0 and later.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| apiName | string | Required. The API name of an actionable event type definition |
| eventSubtypes | EventSubtype[] | The subtypes of an actionable event |
| label | string | Required. Label of the actionable event type definition |

**Nested Type — EventSubtype:**

| Field Name | Field Type | Description |
|---|---|---|
| apiName | string | Required. The API name of an actionable event subtype |
| label | string | Required. Label of the event subtype |

**Wildcard Support:** This metadata type supports the wildcard character `*` in the package.xml manifest file.

---

### AdvAccountForecastSet

**Description:** Represents the forecast sets that define the forecast configurations for each business unit or different groups of accounts. With separate forecast sets at account or business unit level, you can focus on account-specific data and manage configuration updates for one business unit without impacting any other business unit's data.

**File Suffix and Directory Location:** `.advAccountForecastSet` in the `AdvAccountForecastSet` folder.

**Available Version:** 53.0 and later.

**Special Access Rules:** The advanced account forecasting feature setting for Manufacturing Cloud is required.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| accountFieldName | string | The field name for the account in the advanced account forecast fact record |
| calculationFrequency | AdvAcctFcstCalcFrequency (enum) | The frequency at which the forecast set is recalculated automatically. Values: `Monthly` (default), `Quarterly`, `Weekly`, `Yearly` |
| description | string | The description of the advanced account forecast set record |
| dimensions | AdvAcctForecastDimension[] | The dimensions selected for the forecast set to categorize the forecast data |
| displayGroups | AdvAcctFrcstDisplayGroup[] | The information about the groups for the advanced account forecast set measures or dimensions |
| forecastAdjPeriods | AdvAcctForecastAdjPeriod[] | The details about the adjustment period of the advanced account forecast values |
| forecastFactObjectName | string | Required. The API name of the object that contains the advanced forecast fact records |
| forecastFormulas | AdvAccountForecastFormula[] | The formula definitions for advanced account forecast calculations |
| forecastPeriodGroupId | string | The forecast period group associated with the advanced account forecast set |
| forecastQuantityFieldName | string | The field name for the forecast quantity in the advanced account forecast fact record |
| forecastRevenueFieldName | string | The field name for the forecast revenue in the advanced account forecast record |
| forecastSetFieldName | string | The name of the field used to store the forecast set and fact object relation |
| forecastSetName | string | The name of the forecast set |
| forecastStatusFieldName | string | The field name for the Status in the advanced account forecast fact record |
| generationDpeDefName | string | The name of the Data Processing Engine definition used to generate advanced account forecast fact records |
| language | string | The combined language and locale ISO code |
| masterLabel | string | Label for this advanced account forecast set value. Internal label not translated |
| measureDefinitions | AdvAcctForecastMeasureDef[] | The measures to be displayed in the advanced account forecasts grid |
| periodFieldName | string | The field name for the period in the advanced account forecast fact record |
| recalculateDpeDefName | string | The Data Processing Engine definition used to recalculate advanced account forecast fact records |
| regenerationDpeDefName | string | The Data Processing Engine definition used to regenerate advanced account forecast fact records |
| rolloverDpeDefName | string | The Data Processing Engine definition used to generate rollover advanced account forecast fact records |
| rolloverFrequency | AdvAcctFcstCalcFrequency (enum) | The frequency of rollover of the advanced account forecast records. Values: `Monthly` (default), `Quarterly`, `Weekly`, `Yearly` |
| status | string | The status of the advanced account forecast set. Values: `Active`, `Inactive` |

**Nested Type — AdvAccountForecastFormula:**

| Field Name | Field Type | Description |
|---|---|---|
| formula | string | The formula used for advanced account forecast calculation |
| formulaType | string | The type of formula. Values: `QUANTITY`, `REVENUE` |
| startingPeriod | int | The period from which the formula is effective |
| endingPeriod | int | The period until which the formula is effective |

---

### Flow for Manufacturing Cloud

**Description:** Represents the metadata associated with a flow. With Flow, you can create an application that navigates users through a series of screens to query and update records in the database. You can also execute logic and provide branching capability based on user input to build dynamic applications.

**Note:** Manufacturing Cloud exposes additional `actionType` values for the `FlowActionCall` Metadata type:
- `InvocableActionType` field: additional valid values only for Manufacturing Cloud include `Sales Agreement` (available in API version 61.0 and later).

---

### MfgProgramTemplate

**Description:** Represents a definition of a program to create a program-based business. A program-based business (also known as a Manufacturing Program) enables manufacturers to drive their business models with forecasting tools and manage the end-to-end sales process efficiently.

**File Suffix and Directory Location:** `.mfgProgramTemplate` in the `MfgProgramTemplate` folder.

**Available Version:** 54.0 and later.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| description | string | The description of the manufacturing program template |
| masterLabel | string | Label for this manufacturing program template |
| programTemplateItems | MfgProgramTemplateItem[] | The template items associated with this template |
| status | MfgProgramTemplateStatus (enum) | The status of the manufacturing program template. Values: `Active`, `Draft`, `Inactive` |

**Nested Type — MfgProgramTemplateItem:**

| Field Name | Field Type | Description |
|---|---|---|
| advAccountForecastSetName | string | The forecast set associated with the transformation |
| contextDefinition | string | The context definition for data mapping |
| description | string | The description of the template item |
| sourceContextMappingName | string | The context mapping for source data |
| targetContextMappingName | string | The context mapping for target data |
| templateItemName | string | The name of the manufacturing program template item |
| transformationDisplayOrder | int | The display order of the transformation |
| transformationType | MfgProgramTransformationType (enum) | Type of transformation. Values: `BusinessTransformation`, `ForecastSetRelation` |

---

### ObjectHierarchyRelationship

**Description:** Represents an organization's custom field mappings for sales agreement conversion. Fields can be mapped from Opportunity and Quotes to SalesAgreement and SalesAgreementProduct.

**File Suffix and Directory Location:** `ObjectHierarchyRelationship.settings` in the `settings` folder.

**Available Version:** 51.0 and later.

**What it configures:** Used by the Sales Agreement (POST) Connect REST API. Define a `ConvertToSalesAgreement` mapping usage type to map input object (Opportunity or Quote) to output object (SalesAgreement) and define field mappings. All products from the source object child entity will be added to the sales agreement.

**Note:** To use decimal values, map quantity values to `InitialPlannedQtyValue`.

**Key Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| childObjectMapping | ObjectMappingField[] | Mapping of child object fields (e.g., OpportunityLineItem → SalesAgreementProduct) |
| masterLabel | string | The label of the ObjectHierarchyRelationship |
| usageType | string | The usage type. Use `ConvertToSalesAgreement` for sales agreement conversion |
| parentRelationshipFieldName | string | The parent input object (e.g., `Opportunity`) |
| outputPntRelationshipFieldName | string | The parent output object (e.g., `SalesAgreement`) |
| parentRecord | string | The parent record details |
| inputObjRecordsGrpFieldName | string | The field used to group input object records (e.g., `Account`) |
| mappingType | string | The type of mapping (e.g., `ParentToParent`) |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ObjectHierarchyRelationship xmlns="http://soap.sforce.com/2006/04/metadata">
  <childObjectMapping>
    <inputObject>OpportunityLineItem</inputObject>
    <mappingFields>
      <inputField>Quantity</inputField>
      <outputField>InitialPlannedQuantity</outputField>
    </mappingFields>
    <outputObject>SalesAgreementProduct</outputObject>
  </childObjectMapping>
  <masterLabel>ObjectHierarchyRelationship</masterLabel>
  <usageType>ConvertToSalesAgreement</usageType>
  <parentRelationshipFieldName>Opportunity</parentRelationshipFieldName>
  <outputPntRelationshipFieldName>SalesAgreement</outputPntRelationshipFieldName>
  <mappingType>ParentToParent</mappingType>
</ObjectHierarchyRelationship>
```

**Wildcard Support:** This metadata type supports the wildcard character `*` in the package.xml manifest file.

---

### SalesAgreementSettings

**Description:** Represents settings that control the display of agreement terms metrics in sales agreements and the calculation of the actual quantity of products in sales agreements. These settings also control the approval of sales agreements.

**File Suffix and Directory Location:** `SalesAgreementSettings.salesAgreementSetting` in the `salesAgreementSettings` directory.

**Available Version:** 47.0 and later.

This type extends the Metadata metadata type and inherits its `fullName` field. In the package manifest, all organization settings metadata types are accessed using the `Settings` name.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| actualsCalculationMode | ActualsCalculationMode (enum) | Required. Source from which the actual ordered quantity of a product is calculated. Values: `DataProcessingEngine` (API v63.0+), `Manual` (default), `Orders`, `OrdersThroughContracts` |
| arePredfndStatusValOveride | boolean | Indicates whether predefined status validations are overridden (true). Default: false. Available in API version 65.0 and later |
| decimalScale | int | Required. Number of decimal places applied to values in sales agreements. Available in API version 62.0 and later |
| displayGroups | AdvAcctFrcstDisplayGroup | Represents information about the groups for the advanced account forecast set measures or dimensions. Available in API version 56.0 and later |
| displayedAgreementTermsMetrics | string | Required. Metrics selected for display in Agreement Terms in specified sequence. Maximum 10 comma-separated metric names |
| futureActCalcSchedules | int | Required. Number of future schedules to include in actuals calculations. Available in API version 63.0 and later |
| measureDefinitions | AdvAcctForecastMeasureDef | Represents information about measures to display in the advanced account forecasts grid. Available in API version 56.0 and later |
| objectMapping | ObjectMapping | Foreign key to ObjectMapping that maps fields from the input object (SalesAgreementProductSchedule) to the output object (SalesAgreementProduct) |
| primaryNotifEmailAddress | string | The email address to which notifications are sent |
| renewalPeriodDayCount | int | The number of days before the end date of a sales agreement from when it can be renewed. Available in API version 50.0 and later |
| secondaryNotifEmailAddress | string | The second email address to which notifications are sent |

**Nested Type — AdvAcctFrcstDisplayGroup:**

| Field Name | Field Type | Description |
|---|---|---|
| advAcctFrcstDisplayGroupName | string | Required. Name of the advanced account forecast display group |
| displayGroupItems | AdvAcctFrcstDplyGroupItem | Items associated with a display group |
| displayGroupType | AdvAcctFrcstDisplayGroupType (enum) | Category for the display group. Values: `MEASURE` |
| isDefault | boolean | Whether the display group is the default group (true) or not (false). Default: false |
| userProfileName | string | Profile for which the display group is applicable |

**Nested Type — AdvAcctFrcstDplyGroupItem:**

| Field Name | Field Type | Description |
|---|---|---|
| advAcctFrcstDplyGroupItemName | string | Required. Name of the advanced account forecast display group item |
| displayOrder | string | Required. Display order of the display group item |
| measureReferenceName | string | Name of the measure associated with the display group item |

**Nested Type — AdvAcctForecastMeasureDef:**

| Field Name | Field Type | Description |
|---|---|---|
| advAcctForecastMeasureDefName | string | Required. Name for the measure |
| aggregationType | AdvAcctFcstAggregationType (enum) | Required. Type of aggregation. Values: `AVERAGE`, `MAXIMUM`, `MINIMUM`, `SUM` |
| computationMethod | AdvAcctFcstComputationMethod (enum) | Required. Method used for calculating advanced account forecast values. Values: `CUSTOM`, `DATA_PROCESSING_ENGINE_DEFINITION`, `FORMULA` |
| forecastDataMeasureName | string | Required. Field of the facts object used for this measure |
| forecastMeasureName | string | Required. Name for the measure to show on UI |
| forecastMeasureType | AdvAcctFcstMeasureType (enum) | Required. Measure type. Values: `QUANTITY`, `REVENUE` |
| isAdjustmentTracked | boolean | Whether adjustments made to this metric are tracked (true) or not (false). Default: false |

**Nested Type — ObjectMapping:**

| Field Name | Field Type | Description |
|---|---|---|
| inputObject | string | Required. The input object (SalesAgreementProductSchedule) |
| mappingFields | ObjectMappingField[] | The mapping of source object fields to target object fields |
| outputObject | string | Required. The output object (SalesAgreementProduct) |

**Nested Type — ObjectMappingField:**

| Field Name | Field Type | Description |
|---|---|---|
| inputField | string | Required. Field in the inputObject. This field is mapped to the field in outputField |
| outputField | string | Required. Field in the outputObject. This field is mapped from the field in inputField |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<SalesAgreementSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <actualsCalculationMode>Orders</actualsCalculationMode>
  <decimalScale>0.2</decimalScale>
  <displayedAgreementTermsMetrics>PlannedQuantity,ActualQuantity,SalesPrice</displayedAgreementTermsMetrics>
  <futureActCalcSchedules>10</futureActCalcSchedules>
  <isOnlyApprovalProcessUsed>false</isOnlyApprovalProcessUsed>
  <primaryNotifEmailAddress>abc@salesforce.com</primaryNotifEmailAddress>
  <renewalPeriodDayCount>50</renewalPeriodDayCount>
  <objectMapping>
    <inputObject>SalesAgreementProductSchedule</inputObject>
    <mappingFields>
      <inputField>SAPS1__c</inputField>
      <outputField>SAP1__c</outputField>
    </mappingFields>
    <outputObject>SalesAgreementProduct</outputObject>
  </objectMapping>
</SalesAgreementSettings>
```

**Wildcard Support:** This metadata type supports the wildcard character `*` in the package.xml manifest file.

---

### TelemetryActionDefinition

**Description:** Represents the action taken on a telemetry signal sent from a connected asset or vehicle, such as getting the current status of a vehicle or its component, or sending a request to perform a remote action on the vehicle or its component.

**File Suffix and Directory Location:** `.TelemetryActionDefinition` in the `TelemetryActionDefinitions` folder.

**Available Version:** 65.0 and later.

This type extends the Metadata metadata type and inherits its `fullName` field.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| actionName | string | Required. The full name of the action related to a telemetry definition |
| description | string | The description of the telemetry action definition |
| developerName | string | The developer's internal name for the API. Must be unique |
| executionProcedure | string | The execution procedure used to fulfill telemetry action related processes |
| isActive | boolean | Indicates whether the telemetry definition version is active (true) or not (false). Default: false |
| isProtected | boolean | An auto-generated value that doesn't impact behavior. Default: false |

---

### TelemetryActionDefStep

**Description:** Represents a step in the action for a telemetry signal definition.

**File Suffix and Directory Location:** `.TelemetryActionDefStep` in the `TelemetryActionDefSteps` folder.

**Available Version:** 65.0 and later.

**Enumerations:** `TelemetryActnDefStepOpType` (enumeration of type string) — specifies the operation type for the step.

---

### TelemetryActnDefStepAttr

**Description:** Represents the attributes of a telemetry action definition step.

**File Suffix and Directory Location:** `.TelemetryActnDefStepAttr` in the `TelemetryActnDefStepAttrs` folder.

**Available Version:** 65.0 and later.

**Enumerations:** `TelemetryActnDefStepAttrType` (enumeration of type string) — specifies the attribute type for the step.

---

### TelemetryDefinition

**Description:** Represents the definition of the structure of a telemetry signal sent from a connected asset or vehicle.

**File Suffix and Directory Location:** `.TelemetryDefinition` in the `TelemetryDefinitions` folder.

**Available Version:** 65.0 and later.

**Enumerations:** `TelemetryDefinitionUsageType` (enumeration of type string) — specifies the usage type of the telemetry definition.

---

### TelemetryDefinitionVersion

**Description:** Represents a version of the structure of a telemetry signal sent from a connected asset or vehicle.

**File Suffix and Directory Location:** `.TelemetryDefinitionVersion` in the `TelemetryDefinitionVersions` folder.

**Available Version:** 65.0 and later.

**Fields (partial):**

| Field Name | Field Type | Description |
|---|---|---|
| telemetryComponentStructure | string | The structure of the components in the telemetry definition that send signals, represented in JSON format |
| telemetryDefinition | string | Required. The telemetry definition associated with the telemetry definition version |
| versionNumber | int | Required. The version number of the telemetry definition version |

---

## Settings Types

Settings types extend the Metadata metadata type and inherit its `fullName` field. In the package manifest, all organization settings metadata types are accessed using the `Settings` name.

### InventoryAllocationSettings

**Description:** Settings for the Inventory Allocation feature.

**File Suffix and Directory Location:** `InventoryAllocation.settings` in the `settings` folder.

**Available Version:** 66.0 and later.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enableInventoryAllocation | boolean | Indicates whether the Inventory Allocation feature is enabled (true) or disabled (false). Default: false |

---

### IndustriesConnectedServiceSettings

**Description:** Settings for the Industries Connected Service feature of Manufacturing Cloud.

**File Suffix and Directory Location:** `IndustriesConnectedServiceSettings.settings` in the `settings` folder.

**Available Version:** 65.0 and later.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enablePrebuiltCmpntTlmtryMgmt | boolean | Enables the prebuilt component for telemetry management in Connected Service. Default: false |

---

### IndustriesEventOrchSettings

**Description:** Settings for Industries Event Orchestration in Manufacturing Cloud.

**File Suffix and Directory Location:** `IndustriesEventOrch.settings` in the `settings` folder.

**Available Version:** 60.0 and later.

---

### IndustriesFieldServiceSettings

**Description:** Settings for Industries Field Service in Manufacturing Cloud.

**File Suffix and Directory Location:** `IndustriesFieldServiceSettings.settings` in the `settings` directory.

**Available Version:** 60.0 and later.

---

### IndustriesManufacturingSettings

**Description:** Represents feature-level settings for Manufacturing Cloud. Controls enabling/disabling of individual Manufacturing Cloud features.

**Available Version:** 47.0 and later.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enableConnectedAssetSrvcsCmpnt | boolean | Enables the Connected Asset Services component. Default: false |
| enableIndManufacturing | boolean | Enables Manufacturing Cloud. Default: false |
| enableIndustriesMfgAccountForecast | boolean | Enables Account Forecasting. Default: false |
| enableIndustriesMfgAdvForecast | boolean | Enables Advanced Account Forecasting. Default: false |
| enableIndustriesMfgIAS | boolean | Enables the Industries Manufacturing IAS feature. Default: false |
| enableIndustriesMfgProgram | boolean | Enables Manufacturing Program Based Business. Default: false |
| enableIndustriesMfgTargets | boolean | Enables Account Manager Targets. Default: false |
| enableMfgAgents | boolean | Enables Manufacturing Agents. Default: false |
| enablePtnrLeadMgmtMappings | boolean | Enables Partner Lead Management Mappings. Default: false |
| enableVehAndAstLending | boolean | Enables the Vehicle and Asset Lending feature. Default: false. Available from API version 62.0 and later |
| enableVehicleAndAssetFinance | boolean | Enables the Vehicle And Asset Finance feature. Default: false. Available from API version 60.0 and later |
| enableVehAssetFinAddtnlCmpnts | boolean | Enables the predefined components for Vehicle And Asset Finance. Default: false. Available from API version 60.0 and later |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<IndustriesManufacturingSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableConnectedAssetSrvcsCmpnt>true</enableConnectedAssetSrvcsCmpnt>
  <enableIndManufacturing>false</enableIndManufacturing>
  <enableIndustriesMfgAccountForecast>false</enableIndustriesMfgAccountForecast>
  <enableIndustriesMfgAdvForecast>false</enableIndustriesMfgAdvForecast>
  <enableIndustriesMfgIAS>false</enableIndustriesMfgIAS>
  <enableIndustriesMfgProgram>false</enableIndustriesMfgProgram>
  <enableIndustriesMfgTargets>false</enableIndustriesMfgTargets>
  <enableMfgAgents>false</enableMfgAgents>
  <enablePtnrLeadMgmtMappings>false</enablePtnrLeadMgmtMappings>
  <enableVehAndAstLending>true</enableVehAndAstLending>
  <enableVehAssetFinAddtnlCmpnts>true</enableVehAssetFinAddtnlCmpnts>
  <enableVehicleAndAssetFinance>true</enableVehicleAndAssetFinance>
</IndustriesManufacturingSettings>
```

**Sample package.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>IndustriesManufacturing</members>
    <name>Settings</name>
  </types>
  <version>47.0</version>
</Package>
```

---

### InventoryReplenishmentSettings

**Description:** Represents the setting for enabling the Inventory Replenishment feature.

**File Suffix and Directory Location:** `InventoryReplenishment.settings` in the `settings` folder.

**Available Version:** 63.0 and later.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enableInventoryReplenishment | boolean | Enables the Inventory Replenishment feature. Default: false |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<InventoryReplenishmentSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableInventoryReplenishment>true</enableInventoryReplenishment>
</InventoryReplenishmentSettings>
```

**Note:** The wildcard character `*` in package.xml does not apply to this metadata type. The wildcard applies only when retrieving all settings, not for an individual setting.

---

### MfgServiceConsoleSettings

**Description:** Represents the settings to access the Service Console for Manufacturing.

**File Suffix and Directory Location:** `MfgServiceConsole.settings` in the `settings` directory.

**Available Version:** 56.0 and later.

**Special Access Rules:** To use this metadata type, your Salesforce org must have the Manufacturing Cloud license.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enableMfgServiceConsole | boolean | Enables Service Console for Manufacturing (true) or disables (false). Note: By default, Service Console for Manufacturing is disabled |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<MfgServiceConsoleSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableMfgServiceConsole>true</enableMfgServiceConsole>
</MfgServiceConsoleSettings>
```

---

### PurchaseOrderMgmtSettings

**Description:** Represents the settings for enabling Manufacturing features like Purchase Order Management.

**File Suffix and Directory Location:** `PurchaseOrderMgmt.settings` in the `settings` folder.

**Available Version:** 66.0 and later.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enablePurchaseOrderMgt | boolean | Enables the Purchase Order Management feature. Default: false |

**Sample Definition:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PurchaseOrderMgmtSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enablePurchaseOrderMgt>true</enablePurchaseOrderMgt>
</PurchaseOrderMgmtSettings>
```

**Note:** The wildcard character `*` in package.xml does not apply to this metadata type for feature settings.

---

### WarrantyLifeCycleMgmtSettings

**Description:** Represents settings that control the Warranty Administration for your org.

**File Suffix and Directory Location:** `WarrantyLifecycleMgmt.settings` in the `settings` directory.

**Available Version:** 54.0 and later.

**Fields:**

| Field Name | Field Type | Description |
|---|---|---|
| enableWarrantyLCMgmt | boolean | Enables warranty life-cycle management (true) or disables (false) |

**Sample Definition:**
```xml
<WarrantyLifecycleMgmtSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableWarrantyLCMgmt>true</enableWarrantyLCMgmt>
</WarrantyLifecycleMgmtSettings>
```

**Sample package.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>WarrantyLifecycleMgmt</members>
    <name>Settings</name>
  </types>
  <version>54.0</version>
</Package>
```

---

## Tooling API Objects

Tooling API exposes metadata used in developer tooling that you can access through REST or SOAP. Tooling API's SOQL capabilities for many metadata types allow you to retrieve smaller pieces of metadata. For more information about Tooling API objects and to find a complete reference of all supported objects, see Introducing Tooling API.

---

### AccountForecastSettings (Tooling API)

**Description:** Represents settings that define the generation of account forecasts and their display on the account's record page. These settings also define the periods during which the account forecast values can be edited and the formula definitions for account forecast calculations.

**Available Version:** 47.0 and later.

**Supported SOAP Calls:** create(), describeSObjects(), query(), retrieve(), update(), upsert()

**Supported REST HTTP Methods:** GET, POST, PATCH, PUT

**Fields:**

| Field | Type | Properties | Description |
|---|---|---|---|
| AcctPrdctPrdFrcstVolCnt | int | Filter, Group, Nillable, Sort | Number of existing records in the AccountProductPeriodForecast object. Available in API version 49.0 and later |
| CalculationFrequency | picklist | Defaulted on Create, Filter, Group, Restricted picklist, Sort | Source from which frequency of account forecast recalculation is derived. Valid values: `Monthly` (default), `Quarterly` |
| DeveloperName | string | Filter, Group, Sort | The developer name for AccountForecastSettings |
| DisplayDuration | int | Filter, Group, Sort | The number of periods for which the forecast is generated and displayed |
| DisplayedForecastMetrics | textarea | Filter, Sort | The quantity metrics selected for display in the account forecast. Maximum 10 comma-separated metric names |
| DisplayedRevenueMetrics | textarea | Filter, Sort | The revenue metrics selected for display in the account forecast. Maximum 10 comma-separated metric names |
| EditsAllowedFor | int | Filter, Group, Nillable, Sort | The number of days either during the start or end of a period when an account forecast's values can be edited |
| ForecastFrequency | picklist | Defaulted on Create, Filter, Group, Restricted picklist, Sort | Source from which frequency of account forecast generation is derived. Valid values: `Monthly` (default), `Quarterly` |
| FullName | string | Create, Group, Nillable | The unique name for these account forecast settings. Must contain only underscores and alphanumeric characters; must be unique, begin with a letter, not include spaces, not end with an underscore, and not contain two consecutive underscores. Note: Query this field only if the query result contains no more than one record |
| HasOpportunityItemSchedule | boolean | Create, Filter, Group, Sort | Indicates whether to use probability of opportunities associated with accounts to calculate forecast values (true). Default: false. Available in API version 50.0 and later |
| HasOpportunityProbability | boolean | Create, Filter, Group, Sort | Indicates whether to use the probability of opportunities associated with accounts to calculate forecast values (true). Default: false. Available in API version 50.0 and later |
| Language | picklist | Defaulted on Create, Filter, Group, Nillable, Restricted picklist, Sort | The language for AccountForecastSettings |
| MasterLabel | string | Filter, Group, Sort | Master label for AccountForecastSettings. Internal label not translated |
| PrimaryNotifEmailAddress | email | Filter, Group, Nillable, Sort | The email address to which notifications are sent |
| RecalculateAllFrcstCnt | int | Filter, Group, Nillable, Sort | The number of times account forecasts are recalculated for all eligible accounts in an org. Available in API version 49.0 and later |
| RegenerateForecastCnt | int | Filter, Group, Nillable, Sort | The number of times account forecasts are regenerated for all eligible accounts in an org. Available in API version 49.0 and later |
| StartingPeriod | int | Filter, Group, Sort | The number of periods to go back from the current date for account forecast generation |

---

### AcctMgrTargetSettings (Tooling API)

**Description:** Represents the settings of account manager targets. These settings define the distribution frequency, the hierarchy of team members for assignments, and the default price book of account manager targets. Also displays the record usage details by account manager targets in your Salesforce org.

**Available Version:** 49.0 and later.

**Supported SOAP Calls:** create(), describeSObjects(), query(), retrieve(), update(), upsert()

**Supported REST HTTP Methods:** GET, POST, PATCH, PUT

**Fields:**

| Field | Type | Properties | Description |
|---|---|---|---|
| DeveloperName | string | Filter, Group, Sort | The developer name for AcctMgrTargetSettings |
| DistributionFrequency | picklist | Defaulted on create, Filter, Group, Restricted picklist, Sort | The distribution frequency for account manager targets. Valid values: `Month`, `Quarter`, `Year` |
| FullName | string | Create, Group, Nillable | The unique full name for the settings. Query only if result contains no more than one record |
| Language | picklist | Defaulted on create, Filter, Group, Nillable, Restricted picklist, Sort | The language of the account manager target settings |
| MasterLabel | string | Filter, Group, Sort | Master label for AcctMgrTargetSettings. Internal label not translated |
| PricebookId | string | Filter, Group, Nillable | The ID of the price book |
| TeamMemberHierarchyType | picklist | Defaulted on create, Filter, Group, Restricted picklist, Sort | The hierarchy type of team members for account manager target assignments. Values: `ForecastsHierarchy`, `ManagerHierarchy` |

---

### RecordActionDeployment (Tooling API)

**Description:** Represents configuration settings for the Actions & Recommendations and Action Launcher components.

**Available Version:** 45.0 and later.

**Supported SOAP Calls:** create(), describeSObjects(), query(), retrieve(), update(), upsert()

**Supported REST HTTP Methods:** GET, POST, PATCH, PUT

**Fields:**

| Field | Type | Properties | Description |
|---|---|---|---|
| ChannelConfigurations | various | Filter | Channel default settings for the deployment. Visible only in the metadata for a record |
| ComponentName | picklist | Filter, Group, Nillable, Restricted picklist, Sort | Specifies the name of the component used in the deployment. Values: `ActionLauncher` (1), `ActionsAndRecommendations` (0). Available in API version 56.0 and later |
| DeploymentContexts | RecordActionDeploymentContext | Not applicable | Object describing deployment contexts |
| FullName | string | Create, Group, Nillable | The unique name used as the record action deployment identifier. Must contain only underscores and alphanumeric characters. Query only if result contains no more than one record |
| Language | picklist | Defaulted on Create, Filter, Group, Nillable, Restricted picklist, Sort | The language for the deployment. Supported values include standard Salesforce language codes (e.g., `en_US`, `fr`, `de`, `ja`) |
| ManageableState | ManageableState (enum) | Filter, Group, Nillable | The manageability state of the component in packaging |
| Metadata | RecordActionDeployment | Create, Nillable, Update | Metadata that defines record action deployments. Query only if result contains no more than one record |
| NamespacePrefix | string | Filter, Group, Nillable, Sort | The namespace prefix associated with the record action deployment |

---

### SalesAgreementSettings (Tooling API)

**Description:** Represents settings that control the display of agreement terms metrics in sales agreements and the calculation of the actual quantity of products in sales agreements. These settings also control the approval of sales agreements.

**Available Version:** 57.0 and later.

**Supported SOAP Calls:** create(), describeSObjects(), query(), retrieve(), update(), upsert()

**Supported REST HTTP Methods:** GET, POST, PATCH, PUT

**Fields:**

| Field | Type | Properties | Description |
|---|---|---|---|
| ActualsCalculationMode | picklist | Filter, Group, Sort | Source from which the actual ordered quantity of a product is calculated. Values: `DataProcessingEngine`, `Manual`, `Orders`, `OrdersThroughContracts` |
| DeveloperName | string | Filter, Group, Sort | The developer name for SalesAgreementSettings |
| DisplayedAgreementTermsMetrics | textarea | Filter, Sort | Metrics selected for display in Agreement Terms. Maximum 10 comma-separated metric names |
| FullName | string | Create, Group, Nillable | The full name of the associated metadata object. Query only if result contains no more than one record |
| IsOnlyApprovalProcessUsed | boolean | Default on Create, Filter, Group, Sort | Indicates whether only approval (not self-approval) of sales agreements is allowed through Approval Flow (true) or both are allowed (false). Default: false |
| Language | picklist | Defaulted on Create, Filter, Group, Nillable, Restricted picklist, Sort | The language of the sales agreement settings |
| MasterLabel | string | Filter, Group, Sort | Master label for SalesAgreementSettings. Internal label not translated |
| PrimaryNotifEmailAddress | email | Filter, Group, Nillable, Sort | The email address to which notifications are sent |
| RenewalPeriodDayCount | int | Filter, Group, Nillable, Sort | The number of days before the end date of a sales agreement from when it can be renewed. Available in API version 50.0 and later |
| SecondaryNotifEmailAddress | string | Filter, Group, Nillable, Sort | The second email address to which notifications are sent |

---

## Deployment Considerations

### Settings Types
- The wildcard character `*` in package.xml does **not** apply to most feature settings metadata types. The wildcard applies only when retrieving **all** settings, not for an individual setting.
- Exceptions: `MfgServiceConsoleSettings` and `WarrantyLifeCycleMgmtSettings` do support the wildcard character `*` in the manifest file.
- Settings files use the `.settings` file extension and are stored in the `settings` folder. There is only one settings file for each settings component.

### AccountForecastSettings
- When deploying `AccountForecastSettings`, also include any custom fields referenced in `objectMapping` (e.g., custom fields on `AccountProductPeriodForecast` and `AccountProductForecast`).
- The `FullName` field in Tooling API: query only if the result contains no more than one record — otherwise an error is returned.

### ObjectHierarchyRelationship
- Must be configured before using the Sales Agreement (POST) Connect REST API.
- Uses the `ConvertToSalesAgreement` mapping usage type.

### Flow for Manufacturing Cloud
- Manufacturing Cloud adds `actionType` values to `FlowActionCall`. Ensure your org has the appropriate Manufacturing Cloud features enabled before deploying Flows that reference these action types.

### IndustriesManufacturingSettings
- All feature flags default to `false`. You must explicitly set each feature to `true` to enable it.
- `enableIndustriesMfgAdvForecast` must be `true` before using Advanced Account Forecasting objects or the `massUpdateAdvAccountForecast` action.
- `enableIndustriesMfgProgram` must be `true` before using Manufacturing Program objects.
- `enableIndustriesMfgTargets` must be `true` before using AcctMgrTarget objects.
