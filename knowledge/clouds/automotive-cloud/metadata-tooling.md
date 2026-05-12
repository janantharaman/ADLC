---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf
cloud: Automotive Cloud
section: metadata-tooling
---

# Automotive Cloud — Metadata and Tooling

## Metadata API Types Summary

| Metadata Type | Suffix | Folder | API Version | Purpose |
|---|---|---|---|---|
| `ActionableEventOrchDef` | `.actionableEventOrchDef` | `ActionableEventOrchDef` | 64.0+ | Event orchestration routing definition |
| `ActionableEventTypeDef` | `.ActionableEventTypeDef` | `ActionableEventTypeDefs` | 64.0+ | Event type and subtype catalog |
| `ObjectHierarchyRelationship` | `.ObjectHierarchyRelationship.settings` | — | 51.0+ | Field mapping between two objects |
| `TelemetryDefinition` | `.TelemetryDefinition` | `TelemetryDefinitions` | 65.0+ | Connected vehicle signal schema |
| `TelemetryDefinitionVersion` | `.TelemetryDefinitionVersion` | `TelemetryDefinitionVersions` | 65.0+ | Immutable version of signal schema |
| `TelemetryActionDefinition` | `.TelemetryActionDefinition` | `TelemetryActionDefinitions` | 65.0+ | Action triggered by telemetry signal |
| `TelemetryActionDefStep` | `.TelemetryActionDefStep` | `TelemetryActionDefSteps` | 65.0+ | Step within a telemetry action |
| `TelemetryActnDefStepAttr` | `.TelemetryActnDefStepAttr` | `TelemetryActnDefStepAttrs` | 65.0+ | Attribute on a telemetry action step |
| `IndustriesAutomotiveSettings` | — | — | 56.0+ | Core Automotive Cloud feature toggles |
| `IndustriesEventOrchSettings` | — | — | 60.0+ | Event Orchestration settings |
| `IndustriesManufacturingSettings` | — | — | 47.0+ | Fleet Management (shared with Mfg) |
| `IndustriesSettings` | — | — | 47.0+ | Criteria-Based Search and Appraisal |

---

## ActionableEventOrchDef

Defines which Flow or ExpressionSet executes when an inbound event matches an event type.

**File:** `force-app/main/default/ActionableEventOrchDef/Create_Asset_Registration.actionableEventOrchDef`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ActionableEventOrchDef xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionableEventUsageType>1</actionableEventUsageType>
    <apiName>Create_Asset_Registration</apiName>
    <eventTypeApiName>Create_Registration_Records</eventTypeApiName>
    <executionProcedureAPIName>CreateAssetFlow</executionProcedureAPIName>
    <executionProcedureType>2</executionProcedureType>
    <isActive>true</isActive>
    <isTemplate>false</isTemplate>
    <label>Create Asset Registration</label>
</ActionableEventOrchDef>
```

**Fields:**

| Field | Required | Description |
|---|---|---|
| `actionableEventUsageType` | | `1` = Automotive, `2` = Manufacturing, `3` = Standard |
| `apiName` | Yes | API name of this orchestration definition |
| `eventTypeApiName` | Yes | API name of the matching ActionableEventTypeDef |
| `eventSubtypeApiName` | | Optional subtype to narrow the match |
| `eventCategory` | | Category filter |
| `executionProcedureAPIName` | | Flow or ExpressionSet API name to execute |
| `executionProcedureType` | | `1` = ExpressionSetBasedOrchestration, `2` = FlowBasedOrchestration |
| `isActive` | Yes | Must be `true` to process events |
| `isTemplate` | Yes | Set `false` for deployed definitions |
| `label` | Yes | Human-readable label |
| `contextDefinitionDeveloperName` | | Context definition for the orchestration |
| `contextMappingTitle` | | Context mapping title |

---

## ActionableEventTypeDef

Defines the event type catalog and its subtypes.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ActionableEventTypeDef xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiName>Vehicle_Fault_Event</apiName>
    <label>Vehicle Fault Event</label>
    <eventSubtypes>
        <apiName>Engine_Overheat</apiName>
        <label>Engine Overheat</label>
    </eventSubtypes>
    <eventSubtypes>
        <apiName>Low_Battery</apiName>
        <label>Low Battery Warning</label>
    </eventSubtypes>
</ActionableEventTypeDef>
```

---

## ObjectHierarchyRelationship

Defines field mapping between input and output objects, used by the Transformations API.

**File:** `force-app/main/default/ObjectHierarchyRelationships/LeadToOpportunity.ObjectHierarchyRelationship.settings`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ObjectHierarchyRelationship xmlns="http://soap.sforce.com/2006/04/metadata">
    <parentObjectMapping>
        <inputObject>LeadPreferredSeller</inputObject>
        <outputObject>OpportunityPreferredSeller</outputObject>
        <mappingFields>
            <inputField>AccountId</inputField>
            <outputField>AccountId</outputField>
        </mappingFields>
        <mappingFields>
            <inputField>PreferredSellerType__c</inputField>
            <outputField>PreferredSellerType__c</outputField>
        </mappingFields>
    </parentObjectMapping>
    <mappingType>ParentToParent</mappingType>
    <masterLabel>Lead to Opportunity Preferred Seller</masterLabel>
    <usageType>TransformationMapping</usageType>
</ObjectHierarchyRelationship>
```

**`mappingType` values:** `ChildToChild` / `ParentToChild` / `ParentToParent` / `Support`

---

## TelemetryDefinition

Defines the structure of signals sent from a connected vehicle or asset.

**File:** `force-app/main/default/TelemetryDefinitions/VehicleEngineMonitoring.TelemetryDefinition`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TelemetryDefinition xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Engine parameter monitoring (temperature, RPM, fuel)</description>
    <developerName>VehicleEngineMonitoring</developerName>
    <isProtected>false</isProtected>
    <isTemplate>false</isTemplate>
    <masterLabel>VehicleEngineMonitoring</masterLabel>
    <usageType>ConnectedVehicle</usageType>
</TelemetryDefinition>
```

**`usageType`:** `ConnectedVehicle` or `ConnectedAsset`

---

## TelemetryDefinitionVersion

**Immutable once active.** To update the signal schema, create a new version — never edit an active one.

`telemetryComponentStructure` is a base64-encoded JSON tree representing the vehicle component hierarchy.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TelemetryDefinitionVersion xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Initial version of engine monitoring</description>
    <developerName>VehicleEngineMonitoringv1</developerName>
    <isActive>false</isActive>
    <isProtected>false</isProtected>
    <masterLabel>Vehicle Engine Monitoring v1.0</masterLabel>
    <telemetryComponentStructure><!-- base64-encoded JSON --></telemetryComponentStructure>
    <telemetryDefinition>VehicleEngineMonitoring</telemetryDefinition>
    <versionNumber>1</versionNumber>
</TelemetryDefinitionVersion>
```

**Decoded `telemetryComponentStructure` JSON example:**
```json
{
  "Vehicle": {
    "children": {
      "Body": {
        "children": {
          "Hood": {
            "children": {
              "Position": {
                "datatype": "uint8",
                "description": "Hood position 0=closed 100=open",
                "max": 100, "min": 0,
                "type": "actuator",
                "unit": "percent"
              }
            },
            "type": "branch"
          }
        },
        "type": "branch"
      }
    },
    "type": "branch"
  }
}
```

---

## TelemetryActionDefinition

Links a TelemetryDefinitionVersion to a Flow that executes when signals arrive.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TelemetryActionDefinition xmlns="http://soap.sforce.com/2006/04/metadata">
    <developerName>HoodStatusControl</developerName>
    <isActive>true</isActive>
    <isProtected>false</isProtected>
    <masterLabel>Hood Status Control</masterLabel>
    <telemetryDefinitionVersion>VehicleEngineMonitoringv1</telemetryDefinitionVersion>
    <executionProcedure>HoodControlFlow</executionProcedure>
</TelemetryActionDefinition>
```

---

## TelemetryActionDefStep

Step within a TelemetryActionDefinition, targeting a specific component path.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TelemetryActionDefStep xmlns="http://soap.sforce.com/2006/04/metadata">
    <delayInSeconds>0</delayInSeconds>
    <developerName>HoodStatusControl_HoodPositionStep</developerName>
    <groupName>BodyControlResponse</groupName>
    <isProtected>false</isProtected>
    <masterLabel>Hood Position Monitor</masterLabel>
    <operationType>Submit</operationType>
    <remoteEndPointUrl>https://api.sample-vehicle-management.com/hood</remoteEndPointUrl>
    <sequenceNumber>1</sequenceNumber>
    <targetComponentPath>Vehicle.Body.Hood</targetComponentPath>
    <telemetryActionDefinition>HoodStatusControl</telemetryActionDefinition>
</TelemetryActionDefStep>
```

**`operationType`:** `Retrieve` (read sensor value) or `Submit` (send actuator command)

---

## TelemetryActnDefStepAttr

Attribute (sensor/actuator signal) on a TelemetryActionDefStep.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TelemetryActnDefStepAttr xmlns="http://soap.sforce.com/2006/04/metadata">
    <allowedValues>INACTIVE,CLOSE,OPEN</allowedValues>
    <attributeName>Position</attributeName>
    <dataType>int8</dataType>
    <description>Sliding action such as window.</description>
    <developerName>HoodStatusControl_HoodPositionStep_Position</developerName>
    <isProtected>false</isProtected>
    <masterLabel>Hood Position Control</masterLabel>
    <telemetryActnDefStep>HoodStatusControl_HoodPositionStep</telemetryActnDefStep>
    <type>Actuator</type>
    <unitOfMeasure>Action</unitOfMeasure>
</TelemetryActnDefStepAttr>
```

**`dataType` values:** `Boolean`, `Double`, `Float`, `Int8`, `Int16`, `Int32`, `Integer`, `String`, `Uint8`, `Uint16`, `Uint32`, `Uint64`

**`type` values:** `Actuator` (send commands to vehicle) or `Sensor` (read values from vehicle)

---

## Settings Metadata Reference

### IndustriesAutomotiveSettings (`IndustriesAutomotive.settings`)

| Field | API Version | Default | Description |
|---|---|---|---|
| `enableAutomotiveCloud` | 56.0 | false | **Required first.** Core Automotive Cloud |
| `enableAutomotiveServiceExcellence` | 56.0 | false | Service Console for Automotive |
| `enableAutomotiveScheduler` | 58.0 | false | Salesforce Scheduler integration |
| `enableAutomotiveAppraisals` | 63.0 | false | Appraisal Management |
| `enableConnectedVehSrvcsCmpnt` | 63.0 | false | Connected Vehicle Services component |
| `enableDealerEssntlsAutomotive` | 63.0 | false | Dealer Essentials |
| `enableAutomotiveAgents` | 64.0 | false | Agentforce for Automotive |
| `enableAutoAgentsPilot` | — | false | Reserved — do not use |
| `enableGenAiForAutoPilot` | — | false | Reserved — do not use |

### IndustriesEventOrchSettings (`v.settings`)

| Field | API Version | Description |
|---|---|---|
| `enableEventOrchDecisionTable` | 60.0 | Enable Event Orchestration Decision Table |

### IndustriesManufacturingSettings (`IndustriesManufacturing.settings`)

_(Shared with Manufacturing Cloud)_

| Field | Description |
|---|---|
| `enableIndManufacturing` | Sales Agreements |
| `enableIndustriesMfgAccountForecast` | Account Forecasts |
| `enableIndustriesMfgAdvForecast` | Advanced Account Forecasting |
| `enablePartnerVisitManagement` | Partner Visit Management (v56.0+) |
| `enableFleetManagement` | Fleet Management (v59.0+) |
| `enableFundingWorkbench` | Funding Workbench (v66.0+) |

### IndustriesSettings (`Industries.settings`)

| Field | Description |
|---|---|
| `enableCriteriaBasedSearchAndFilter` | Vehicle and inventory faceted search |
| `enableAppraisalMgmt` | Appraisal Management (v63.0+) |

---

## package.xml Examples

### Minimal Automotive Cloud Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>IndustriesAutomotive</members>
        <name>Settings</name>
    </types>
    <types>
        <members>*</members>
        <name>PermissionSet</name>
    </types>
    <version>66.0</version>
</Package>
```

### Connected Vehicle (Telemetry) Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>TelemetryDefinition</name>
    </types>
    <types>
        <members>*</members>
        <name>TelemetryDefinitionVersion</name>
    </types>
    <types>
        <members>*</members>
        <name>TelemetryActionDefinition</name>
    </types>
    <types>
        <members>*</members>
        <name>TelemetryActionDefStep</name>
    </types>
    <types>
        <members>*</members>
        <name>TelemetryActnDefStepAttr</name>
    </types>
    <types>
        <members>*</members>
        <name>ActionableEventTypeDef</name>
    </types>
    <types>
        <members>*</members>
        <name>ActionableEventOrchDef</name>
    </types>
    <version>66.0</version>
</Package>
```

### Lead Transformation Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>LeadLineItem_to_OpportunityLineItem</members>
        <members>LeadPreferredSeller_to_OpportunityPreferredSeller</members>
        <name>ObjectHierarchyRelationship</name>
    </types>
    <types>
        <members>*</members>
        <name>Flow</name>
    </types>
    <version>66.0</version>
</Package>
```

---

## Tooling API Queries

### Retrieve installed Automotive Cloud feature settings

```soql
SELECT DeveloperName, EnableAutomotiveCloud, EnableAutomotiveServiceExcellence,
       EnableAutomotiveScheduler, EnableAutomotiveAppraisals, EnableAutomotiveAgents
FROM IndustriesAutomotiveSetting
LIMIT 1
```

### List all active ActionableEventOrchDef

```soql
SELECT DeveloperName, Label, EventTypeApiName, ExecutionProcedureAPIName,
       ExecutionProcedureType, IsActive
FROM ActionableEventOrchestrationDef
WHERE IsActive = true
ORDER BY DeveloperName
```

### List all TelemetryDefinition

```soql
SELECT DeveloperName, MasterLabel, UsageType, IsTemplate
FROM TelemetryDefinition
ORDER BY DeveloperName
```

### List active TelemetryDefinitionVersions

```soql
SELECT DeveloperName, MasterLabel, VersionNumber, IsActive,
       TelemetryDefinition.MasterLabel
FROM TelemetryDefinitionVersion
WHERE IsActive = true
ORDER BY TelemetryDefinition.DeveloperName, VersionNumber
```

### List ObjectHierarchyRelationship configurations

```soql
SELECT DeveloperName, MasterLabel, UsageType,
       ParentObjectMapping.InputObject, ParentObjectMapping.OutputObject
FROM ObjectHierarchyRelationship
ORDER BY UsageType, DeveloperName
```

---

## Flow Invocable Actions (Automotive-specific)

| Action Type | API Version | Description |
|---|---|---|
| `replenishInventoryUsingPolicy` | 65.0 | Execute inventory replenishment policy |

Use in Flow `FlowActionCall` with `actionType = replenishInventoryUsingPolicy`.

---

## Feature Module Metadata Dependencies

| Feature | Required Metadata |
|---|---|
| Connected Vehicle | TelemetryDefinition → TelemetryDefinitionVersion → TelemetryActionDefinition → TelemetryActionDefStep → TelemetryActnDefStepAttr → ActionableEventTypeDef → ActionableEventOrchDef |
| Lead-to-Opp Conversion | ObjectHierarchyRelationship (2: LeadLineItem + LeadPreferredSeller) |
| Inventory Transfer | SellerProduct records + LocationId references + IndustriesAutomotiveSettings |
| Fleet Management | IndustriesManufacturingSettings.enableFleetManagement + FSL licenses |
| Action Plans | ActionPlanTemplate → ActionPlanTemplateVersion → ActionPlanTemplateItem |
| Timeline | TimelineObjectDefinition |
| Action Launcher | RecordActionDeployment |

---

## Change Data Capture — Setup

Enable in Setup > Integrations > Change Data Capture. Select objects to track:
- `Vehicle` — for DMS sync monitoring
- `VehicleDefinition` — for catalog change notifications
- `AssetAccountParticipant` — for ownership transfer tracking

Once enabled, subscribe via Apex triggers or CometD streaming API client.
