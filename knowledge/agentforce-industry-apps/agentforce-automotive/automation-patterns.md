---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf
cloud: Automotive Cloud
section: automation-patterns
---

# Automotive Cloud — Automation Patterns

## Business REST APIs

All follow Connect REST API conventions (authentication, rate limits, error handling).

### 1. Inventory Visibility Product Transfer Action
- **Endpoint:** `POST /connect/inventory-visibility/actions?actionName=ProductTransfer`
- **Available:** API v59.0+
- **Use case:** Transfer serialized vehicle/product inventory between source and destination locations

**Request body:**
```json
{
  "items": [
    {
      "serializedProductId": "0jRxx000000009hEAA",
      "sourceLocationId": "131xx0000004FoLAAU",
      "destinationLocationId": "131xx0000004FpxAAE"
    }
  ]
}
```

**Request fields:** `serializedProductId` (required), `sourceLocationId` (required), `destinationLocationId` (required)

**Response:** `Inventory Actions Result` — `{ "errors": {}, "results": { "<serializedProductId>": "<transferRecordId>" } }`

### 2. Orchestration Inbound Events (POST)
- **Endpoint:** `POST /connect/orchestration/inbound-events`
- **Available:** API v59.0+ (enhanced fields from v60.0)
- **Use case:** Accept telematics/IoT events and route to ActionableEventOrchestration

**Request body example (vehicle faults):**
```json
{
  "sourceSystemIdentifier": "102",
  "type": "Transmission Issue",
  "subtype": "Transmission Over Temperature",
  "category": "FAULT",
  "eventData": "{\"Event\":{\"vin\":\"EFGHTYUIF56789GH\",\"faults\":[{\"code\":\"P0218\",\"type\":\"repair\",\"description\":\"Engine Overheating\"}],\"location\":{\"latitude\":34,\"longitude\":56}}}",
  "additionalEventCriteria": {
    "fieldList": [{ "field": "priority__c", "value": "high" }]
  }
}
```

**Request fields (v60.0):** `sourceSystemIdentifier`, `type`, `subtype`, `category`, `eventData`, `additionalEventCriteria` (all Optional)

**Response:** `Inbound Event` — `{ "sourceSystemIdentifier": "...", "status": "SUCCESS", "errors": [...], "actionResponse": [...] }`

### 3. Transformations
- **Endpoint:** `POST /connect/manufacturing/transformations`
- **Available:** API v55.0+
- **Use case:** Convert Lead data to Opportunity data (LeadLineItem → OpportunityLineItem, LeadPreferredSeller → OpportunityPreferredSeller)

**Request body:**
```json
{
  "inputObjectIds": ["0sTxx000000003FEAQ"],
  "inputObjectName": "LeadLineItem",
  "usageType": "TransformationMapping",
  "outputObjectName": "OpportunityLineItem",
  "outputObjectDefaultValues": { "OpportunityLineItem": { "OpportunityId": "abcd1234" } }
}
```

**`usageType` values:** ConvertToSalesAgreement / CLMFieldMapping / EligibleProgramRebateType / MapJournalToMemberAggregate / TransformationMapping

---

## Metadata API Types

### ActionableEventOrchDef
- **Suffix:** `.actionableEventOrchDef` | **Folder:** `ActionableEventOrchDef` | **API v64.0+**
- Defines which Flow or ExpressionSet executes when an event matches

| Field | Required | Description |
|---|---|---|
| `actionableEventUsageType` | | Automotive (1) / Manufacturing (2) / Standard (3) |
| `apiName` | ✓ | API name of the orchestration definition |
| `contextDefinitionDeveloperName` | | Context definition linked to this orchestration |
| `contextMappingTitle` | | Context mapping title |
| `eventCategory` | | Category of the orchestration |
| `eventSubtypeApiName` | | Subtype API name |
| `eventTypeApiName` | ✓ | Event type API name |
| `executionProcedureAPIName` | | Flow or ExpressionSet template API name |
| `executionProcedureType` | | ExpressionSetBasedOrchestration (1) / FlowBasedOrchestration (2) |
| `isActive` | ✓ | Active flag (default: false) |
| `isTemplate` | ✓ | Template flag (default: false) |
| `label` | ✓ | Human-readable label |

**Sample XML:**
```xml
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

### ActionableEventTypeDef
- **Suffix:** `.ActionableEventTypeDef` | **API v64.0+**
- Defines the event type and its subtypes

| Field | Required | Type | Description |
|---|---|---|---|
| `apiName` | ✓ | string | API name of the event type |
| `eventSubtypes` | | EventSubtype[] | Array of subtypes |
| `label` | ✓ | string | Label |

**EventSubtype subtype:** `apiName` (required), `label` (required)

### ObjectHierarchyRelationship
- **Suffix:** `.ObjectHierarchyRelationship.settings` | **API v51.0+**
- Defines field mapping between two objects (e.g., LeadLineItem → OpportunityLineItem)

| Field | Required | Description |
|---|---|---|
| `parentObjectMapping` | ✓ | InputObject → OutputObject mapping |
| `childObjectMapping` | | Child-level object mapping |
| `inputObjRecordsGrpFieldName` | | Field used to group input records |
| `mappingType` | | ChildToChild / ParentToChild / ParentToParent / Support |
| `masterLabel` | | Human-readable label |
| `outputPntRelationshipFieldName` | | Relationship field on output parent |
| `parentRecord` | | Parent record for the hierarchy |
| `parentRelationshipFieldName` | | Field defining parent-child relationship |
| `usageType` | ✓ | ConvertToSalesAgreement / CLMFieldMapping / TransformationMapping / etc. |

**ObjectMapping fields:** `inputObject` (required), `outputObject` (required), `mappingFields` (ObjectMappingField[])
**ObjectMappingField:** `inputField` (required), `outputField` (required)

**Sample:**
```xml
<ObjectHierarchyRelationship>
  <parentObjectMapping>
    <inputObject>LeadPreferredSeller</inputObject>
    <outputObject>OpportunityPreferredSeller</outputObject>
    <mappingFields><inputField>AccountId</inputField><outputField>AccountId</outputField></mappingFields>
  </parentObjectMapping>
  <mappingType>ParentToParent</mappingType>
  <usageType>TransformationMapping</usageType>
</ObjectHierarchyRelationship>
```

### TelemetryDefinition
- **API v65.0+** | Defines structure of a telemetry signal stream

| Field | Required | Description |
|---|---|---|
| `masterLabel` | ✓ | Human-readable name |
| `developerName` | | Internal API name |
| `description` | | Description |
| `isTemplate` | ✓ | Template flag (default: false) |
| `isProtected` | | Auto-generated (default: false) |
| `usageType` | | ConnectedAsset / ConnectedVehicle |

### TelemetryDefinitionVersion
- Immutable once active — create a new version to modify the schema

| Field | Required | Description |
|---|---|---|
| `masterLabel` | ✓ | Human-readable name |
| `developerName` | | Internal API name |
| `versionNumber` | ✓ | Version number (integer) |
| `telemetryDefinition` | ✓ | Parent TelemetryDefinition |
| `telemetryComponentStructure` | | JSON-encoded component tree (base64 in XML) |
| `isActive` | | Active flag (default: false) |
| `description` | | Description |

### TelemetryActionDefinition
- **API v65.0+** | Defines the action triggered by a telemetry signal

| Field | Required | Description |
|---|---|---|
| `masterLabel` | ✓ | Human-readable name |
| `developerName` | | Internal API name |
| `telemetryDefinitionVersion` | ✓ | Linked TelemetryDefinitionVersion |
| `executionProcedure` | | Flow API name to execute |
| `isActive` | | Active flag (default: false) |

### TelemetryActionDefStep
- **API v65.0+** | Step within a TelemetryActionDefinition

| Field | Required | Description |
|---|---|---|
| `masterLabel` | ✓ | Step name |
| `groupName` | ✓ | Group steps shown together in intake form |
| `operationType` | ✓ | Retrieve / Submit |
| `sequenceNumber` | ✓ | Step order |
| `targetComponentPath` | ✓ | Hierarchical path in vehicle system (e.g., `Vehicle.Body.Hood`) |
| `telemetryActionDefinition` | ✓ | Parent TelemetryActionDefinition |
| `delayInSeconds` | | Delay before execution |
| `remoteEndPointUrl` | | External endpoint URL |

### TelemetryActnDefStepAttr
- **API v65.0+** | Attribute on a TelemetryActionDefStep

| Field | Required | Description |
|---|---|---|
| `attributeName` | ✓ | Attribute name |
| `dataType` | ✓ | Boolean / Double / Float / Int8-64 / Integer / String / Uint8-64 |
| `type` | ✓ | Actuator / Sensor |
| `telemetryActnDefStep` | ✓ | Parent step |
| `allowedValues` | | Comma-separated allowed values |
| `minimumValue / maximumValue` | | Numeric range constraints |
| `unitOfMeasure` | | Unit (e.g., "percent", "Action") |

### Flow (Automotive Cloud additions)
Automotive Cloud adds invocable action types to `FlowActionCall.actionType`:
- `replenishInventoryUsingPolicy` (API v65.0+) — Executes inventory replenishment policy

### Settings Metadata Types

#### IndustriesAutomotiveSettings
File: `IndustriesAutomotive.settings` | **API v56.0+**

| Field | API Version | Description |
|---|---|---|
| `enableAutomotiveCloud` | 56.0 | **Enable Automotive Cloud** — required first |
| `enableAutomotiveServiceExcellence` | 56.0 | Service Console for Automotive |
| `enableAutomotiveScheduler` | 58.0 | Salesforce Scheduler integration |
| `enableAutomotiveAppraisals` | 63.0 | Appraisal Management features |
| `enableConnectedVehSrvcsCmpnt` | 63.0 | Connected Vehicle Services component |
| `enableDealerEssntlsAutomotive` | 63.0 | Dealer Essentials features |
| `enableAutomotiveAgents` | 64.0 | Automotive Agents (Agentforce) |
| `enableAutoAgentsPilot` | | Reserved for future use |
| `enableGenAiForAutoPilot` | | Reserved for future use |

#### IndustriesEventOrchSettings
File: `v.settings` | **API v60.0+**
- `enableEventOrchDecisionTable` — Enable Event Orchestration Decision Table

#### IndustriesManufacturingSettings
File: `IndustriesManufacturing.settings` | **API v47.0+**
_(shared with Manufacturing Cloud)_

| Field | Description |
|---|---|
| `enableIndManufacturing` | Sales Agreements feature |
| `enableIndustriesMfgAccountForecast` | Account Forecasts |
| `enableIndustriesMfgAdvForecast` | Advanced Account Forecasting |
| `enableIndustriesMfgIAS` | Default Analytics Dashboards (Beta) |
| `enablePartnerVisitManagement` | Partner Visit Management (v56.0+) |
| `enableFleetManagement` | Fleet Management (v59.0+) |
| `enableFundingWorkbench` | Funding Workbench (v66.0+) |

#### IndustriesSettings
File: `Industries.settings` | **API v47.0+**
- `enableCriteriaBasedSearchAndFilter` — Criteria-Based Search and Filter
- `enableAppraisalMgmt` — Appraisal Management (v63.0+)

---

## Feature Chapters

### Action Plans (Chapter 11)
Objects: `ActionPlan`, `ActionPlanItem`, `ActionPlanTemplate`, `ActionPlanTemplateItem`, `ActionPlanTemplateItemValue`, `ActionPlanTemplateVersion`

Use cases: Vehicle recall checklists, asset milestone tasks, partner visit task lists, service appointment follow-ups.

### Actionable Segmentation (Chapter 9)
References: `Actionable List Members`, `Actionable Segmentation`, `Outreach List` (Industries Common Resources)

Use cases: Segment customers by vehicle type, warranty status, or purchase probability for targeted outreach.

### Action Launcher (Chapter 10)
Metadata type: `RecordActionDeployment`
Deploy on: Vehicle, Asset, Account record pages; Service Console for Automotive app.

### Criteria-Based Search and Filter (Chapter 12)
Configured via `IndustriesSettings.enableCriteriaBasedSearchAndFilter`
Also available in: Health Cloud, Manufacturing Cloud, Public Sector Solutions.

### Identity Verification and Engagements (Chapter 13)
Data models: `Engagement`, `Identity Verification` (Industries Common Resources)
Use case: Verify caller identity in Service Console before processing requests.

### Interest Tags (Chapter 14)
Reference: `Interest Tagging` section of Industries Common Resources Developer Guide
Use case: Tag Vehicle and Lead records with customer interest attributes.

### Record Alerts (Chapter 15)
Reference: `Record Alerts` (Industries Common Resources)
Use case: Surface contextual warnings on Vehicle, Asset, FinancialAccount record pages.

### Service Process Studio (Chapter 16)
Reference: `Service Process Studio` (Industries Common Resources)
Use case: Build enhanced service intake and resolution processes.

### Timeline (Chapter 17)
Metadata type: `TimelineObjectDefinition`
Use case: Chronological view of events across multiple automotive objects on a single record page.

---

## Common Automation Patterns

### Lead → Opportunity Conversion (with vehicle data)
```
Lead (with LeadLineItem + LeadPreferredSeller)
  → Transformations API (TransformationMapping usageType)
  → OpportunityLineItem + OpportunityPreferredSeller created
  → VehicleDefinition looked up
  → ApplicationForm created for finance
```

### Telematics Fault Event Flow
```
Connected vehicle → POST /connect/orchestration/inbound-events
  { type: "Engine Fault", category: "FAULT", eventData: "..." }
  → ActionableEventOrchDef matches by eventTypeApiName
  → executionProcedure (Flow) invoked
  → ServiceAppointment + RecordAlert created
```

### Inventory Transfer Flow
```
DMS system → POST /connect/inventory-visibility/actions?actionName=ProductTransfer
  { items: [{ serializedProductId, sourceLocationId, destinationLocationId }] }
  → SellerProduct inventory updated
  → Response: { results: { "<serializedProductId>": "<transferRecordId>" } }
```
