---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: implementation-guide
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — Implementation Guide

## Setup Sequence for a New CLM Implementation

### Step 1: Enable Licenses and Permissions
1. Enable DocGen platform license in Setup
2. Assign `DocGen Designer` PSL to template authors
3. Assign `DocGen runtime PSL` to contract managers
4. Enable `ClauseManagement` platform license if using clause library
5. Assign `ClauseManagement` PSL to clause library managers
6. Enable `ObligationManagement` permission license if using obligations

### Step 2: Configure Named Credentials
1. Create Named Credential for DocuSign (OAuth)
2. Create Named Credential for Microsoft OneDrive (if using external storage)
3. Create Named Credential for guest user document generation (if applicable)

### Step 3: Create ContractType
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ContractType xmlns="http://soap.sforce.com/2006/04/metadata">
  <masterLabel>Standard_Agreement</masterLabel>
  <isDefault>true</isDefault>
  <subTypes>RecordTypeName1</subTypes>
</ContractType>
```

### Step 4: Configure ContractTypeConfig
Key configurations for a typical CLM setup:

| ConfigType | Typical Value | UsageType |
|---|---|---|
| `AutoGenDocOnContractCreation` | `true` | DocumentSetting |
| `ContractSignedStatus` | `Activated` | SignatureSetting |
| `ContractSignatureDeclinedSts` | `Draft` | SignatureSetting |
| `ContractSignatureExpiredStatus` | `Draft` | SignatureSetting |
| `ContractSignatureVoidedStatus` | `Draft` | SignatureSetting |
| `DefaultTemplateName` | Template developer name | DocumentSetting |
| `TrackContractRedlines` | `true` | Redlining |
| `DocumentTemplateFilterClass` | Apex class name | DocumentSetting |
| `ExternalReviewRequired` | `true` | DocumentSetting |
| `DocuSignReminderEnabled` | `true` | SignatureSetting |
| `DocuSignReminderDelayinDays` | `2` | SignatureSetting |
| `DocuSignReminderFrequency` | `2` | SignatureSetting |
| `DocuSignExpireEnabled` | `true` | SignatureSetting |
| `DocuSignExpiresAfter` | `30` | SignatureSetting |
| `AsyncCheckInEnabled` | `true` | DocumentSetting |

### Step 5: Configure ESignatureConfig
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ESignatureConfig xmlns="http://soap.sforce.com/2006/04/metadata">
  <configType>CalloutNamedCredential</configType>
  <configValue>DocuSign_Credential</configValue>
  <groupType>CalloutConfigurationSetup</groupType>
  <masterLabel>DocuSignCalloutNC</masterLabel>
  <vendor>DocuSign</vendor>
</ESignatureConfig>
```

### Step 6: Create ESignatureEnvelopeConfig
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ESignatureEnvelopeConfig xmlns="http://soap.sforce.com/2021/10/metadata">
  <masterLabel>DocuSign_Contract</masterLabel>
  <targetObjectName>Contract</targetObjectName>
  <isExpirationEnabled>true</isExpirationEnabled>
  <expirationPeriod>30</expirationPeriod>
  <expirationWarningPeriod>5</expirationWarningPeriod>
  <isReminderEnabled>true</isReminderEnabled>
  <firstReminderPeriod>2</firstReminderPeriod>
  <reminderIntervalPeriod>2</reminderIntervalPeriod>
  <isVendorDefaultNtfcnEnabled>false</isVendorDefaultNtfcnEnabled>
  <vendor>DocuSign</vendor>
</ESignatureEnvelopeConfig>
```

### Step 7: Create Document Template
```xml
<?xml version="1.0" encoding="UTF-8"?>
<DocumentTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
  <name>StandardAgreement</name>
  <type>MicrosoftWord</type>
  <documentGenerationMechanism>ServerSide</documentGenerationMechanism>
  <tokenMappingMethodType>OmniDataTransform</tokenMappingMethodType>
  <tokenMappingType>JSON</tokenMappingType>
  <extractOmniDataTransformName>ContractExtractor</extractOmniDataTransformName>
  <mapperOmniDataTransformName>ContractMapper</mapperOmniDataTransformName>
  <usageType>Contract_Lifecycle_Management</usageType>
  <targetTokenObject>CONTRACT</targetTokenObject>
  <isActive>true</isActive>
  <status>Active</status>
  <masterLabel>Standard_Agreement_v1</masterLabel>
</DocumentTemplate>
```

### Step 8: Schedule DocuSign Envelope Status Polling
```apex
ind_docgen_api.EnvelopeStatusScheduler s = new ind_docgen_api.EnvelopeStatusScheduler();
System.schedule('DocuSign Status Job 1', '0 0 * * * ?', s);
System.schedule('DocuSign Status Job 2', '0 15 * * * ?', s);
System.schedule('DocuSign Status Job 3', '0 30 * * * ?', s);
System.schedule('DocuSign Status Job 4', '0 45 * * * ?', s);
```

---

## Document Template Token Mapping

### OmniDataTransform Pattern (Classic)
1. Create an Extract DataTransform bundle (`ExtractOmniDataTransformName`) — reads data from Salesforce
2. Create a Mapper DataTransform bundle (`MapperOmniDataTransformName`) — maps extracted data to template tokens
3. Assign both to the DocumentTemplate

### Context Service Pattern (Modern, v65.0+)
1. Create a `ContextDefinition` component — defines node structure and relationships
2. Create a Context Mapping (`ContextMappingName`) — maps attributes and nodes to related objects
3. Optionally create a Context Filter (`ContextFilterName`) — filters, orders, or limits data at runtime
4. Optionally create a Context Transformation (`ContextTransformationName`, v67.0) — handles nested groups and product bundles
5. Set `TokenMappingMethodType` = `ContextService` in DocumentTemplate

### Custom Class Pattern
1. Implement a custom Apex class (`CustomClassName`) that provides token values
2. Set `TokenMappingMethodType` = `CustomClass`

---

## Contract Lifecycle (State Machine)

Salesforce Contracts uses `ObjectStateDefinition`, `ObjectStateTransition`, `ObjectStateActionDefinition`, and `ObjectStateTransitionAction` to define the contract lifecycle state machine.

**Standard contract states (typical):**
1. Draft
2. In Review
3. Approved
4. Active
5. Expired / Terminated

**State transitions are triggered by:**
- `ObjectStateActionDefinition.ActionType = Apex` — custom Apex invocable class
- `ObjectStateActionDefinition.ActionType = ReferenceObject` — OmniProcess (OmniScript/Integration Procedure)

**Calling a state transition via REST:**
```
PATCH /connect/clm/contract/{contractId}
{
  "actionApiName": "activateContract"
}
```

---

## Document Generation Flow (Server-Side)

**Via Apex:**
```apex
Map<String, Object> parameters = new Map<String, Object>();
parameters.put('requestText', '{}');
parameters.put('type', 'GenerateAndConvert');  // Generate + convert to PDF
parameters.put('status', 'InProgress');
parameters.put('title', 'Contract Agreement');

Type docgenType = Type.forName('industries_docgen.DocumentGenerationProcess');
System.Callable docgen = (System.Callable) docgenType.newInstance();
docgen.Call('createDocumentGenerationProcess', parameters);
```

**Poll status via REST:**
```
GET /connect/clm/document-generation-process/status?contractDocumentVersionId={id}
```

**Listen for status changes via Platform Events:**
- `DocGenProcStsChgEvent` — emitted when individual request status changes
- `DocGenBtchStsChgEvent` — emitted when batch request status changes

---

## Clause Library Implementation

### Create Clause Set and Clauses
1. Create `DocumentClauseSet` with category and default language
2. Create `DocumentClause` records linked to the set (one per language/alternate)
3. Set main clause `IsAlternateClause = false`, alternates `= true`
4. Use approval process or `Review_Requested` → `In_Approval` → `Active` workflow to govern clause activation

### Use Clauses in Templates
1. Add `DocumentTemplateSection` with `SectionType = Clause`
2. Set `DocumentTemplateClauseId` to the approved `DocumentClause`
3. Set `DisplayConditionExpression` for conditional display (e.g., show jurisdiction-specific clause only when `{!Contract.BillingCountry} = 'US'`)

### Custom Template Filtering (to limit available clauses/templates by context)
```apex
global class ContractTemplateFilter implements industries_clm.OpenInterface {
    public Boolean invokeMethod(
        String methodName,
        Map<String, Object> request,
        Map<String, Object> outMap
    ) {
        if (methodName == 'getDocumentTemplateList') {
            String contractId = (String) request.get('contractId');
            String usageType = (String) request.get('usageType');

            List<Contract> contracts = [
                SELECT BillingCountry, RecordType.DeveloperName
                FROM Contract
                WHERE Id = :contractId
            ];

            List<DocumentTemplate> templates;
            if (!contracts.isEmpty() &&
                contracts[0].BillingCountry == 'US') {
                templates = [
                    SELECT Id, Name, Type, IsActive, VersionNumber
                    FROM DocumentTemplate
                    WHERE IsActive = true
                    AND Name LIKE '%_US_%'
                    ORDER BY Name
                ];
            } else {
                templates = [
                    SELECT Id, Name, Type, IsActive, VersionNumber
                    FROM DocumentTemplate
                    WHERE IsActive = true
                    ORDER BY Name
                ];
            }
            outMap.put('documentTemplateList', templates);
        }
        return true;
    }
}
```

---

## AI Contract Extraction Implementation

### Prerequisites
1. Configure `ContextUseCaseMapping` with `UseCaseType = ContractExtraction`
2. Assign `Contracts AI User` permission set to users who will extract contracts
3. Optional: Configure `AdditionalUseCaseInput` (v67.0) to specify the LLM model

### Extraction Flow
1. User uploads contract PDF → creates `ContentDocument`
2. System creates `ContractExtractionResult` linked to the ContentDocument
3. AI processes and populates `ExtractedContractDetails` (JSON of field values) and `ExtractedClauseContent`
4. User reviews extraction result in the UI
5. On approval: `Contract` record created from extracted data; `ContractExtractionResult.Status → ReviewCompleted`

### Bulk Extraction (v67.0)
- Set `ExtractionMode = BulkExtraction` on `ContractExtractionResult`
- Use `SubBatchJobSequence` to track order within batch
- Multiple PDFs processed in one batch job identified by `DocumentAIJobIdentifier`

### Semantic Search (AI)
```
POST /services/data/v67.0/actions/standard/searchContractDocument
{
  "inputs": [{
    "contractId": "800VW000006142vYAA",
    "searchQuery": "What are the termination conditions?",
    "resultLimit": "2000"
  }]
}
```

---

## External Document Storage (Microsoft OneDrive)

### Configure ExternalDocStorageConfig
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ExternalDocStorageConfig xmlns="http://soap.sforce.com/2006/04/metadata">
  <documentPath>/Salesforce/Contracts/{!Contract.ContractNumber}/</documentPath>
  <externalDocStorageIdentifier>OneDriveContractStorage</externalDocStorageIdentifier>
  <masterLabel>Contract_OneDrive_Storage</masterLabel>
  <namedCredential>OneDrive_NC</namedCredential>
  <storageDriveType>MicrosoftOneDrive</storageDriveType>
  <targetObject>Contract</targetObject>
</ExternalDocStorageConfig>
```

### Flow
1. Contract document generated → routed to OneDrive via ExternalDocStorageConfig
2. `ContractDocVerContentDoc.DocumentSourceType = External` tracks externally stored documents
3. Microsoft 365 add-in can pull/push data via `content-link/load` and `content-link/data-sync` endpoints

---

## Obligation Management

### Create Obligations via Apex or Flow
```apex
Obligation ob = new Obligation();
ob.Name = 'Quarterly Payment Q1 2026';
ob.ReferenceObjectId = contractId;
ob.AssigneeUserId = assigneeUserId;
ob.Party = 'FIRST_PARTY';
ob.Type = 'Payment Obligation';
ob.StartDate = Date.today();
ob.EndDate = Date.today().addDays(90);
ob.State = 'Active';
ob.Status = 'Compliant';
insert ob;
```

### Obligation Status Automation
Configure `ContractTypeConfig`:
- `ConfigType = ActivateObligationsBasedOnContractStatus` — auto-activates obligations when contract reaches a specified status
