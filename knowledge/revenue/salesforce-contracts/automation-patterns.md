---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: automation-patterns
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — Automation Patterns

## Contract State Machine (Object State Framework)

### Pattern: Custom State Transition via Apex
When a contract state transition requires custom Apex logic, register an `ObjectStateActionDefinition` with `ActionType = Apex` and an invocable class:

```apex
global class ContractApprovalAction {
    @InvocableMethod(label='Execute Contract Approval')
    global static void execute(List<String> contractIds) {
        for (String contractId : contractIds) {
            // Custom approval logic
            Contract c = [SELECT Id, Status FROM Contract WHERE Id = :contractId];
            c.Status = 'Approved';
            update c;
        }
    }
}
```

Register in `ObjectStateActionDefinition`:
- `ActionType`: `Apex`
- `InvocableClassName`: `ContractApprovalAction`
- `InvocableMethodName`: `execute`

---

### Pattern: State Transition via OmniProcess
When a contract state transition should trigger an OmniScript or Integration Procedure, use `ActionType = ReferenceObject` and link to an `OmniProcess`:

1. Create an Integration Procedure (e.g., `ContractMgmt/ApproveContract`)
2. Create `ObjectStateActionDefinition`:
   - `ActionType`: `ReferenceObject`
   - `ReferenceObjectId`: ID of the OmniProcess
3. Create `ObjectStateTransitionAction` linking the definition to the transition

---

### Pattern: Trigger State Transition via REST
```
PATCH /services/data/v67.0/connect/clm/contract/{contractId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "actionApiName": "sendForSignature"
}
```

Get available actions first:
```
GET /services/data/v67.0/connect/clm/contract/{contractId}/contract-actions
```

---

## Document Generation

### Pattern: Auto-Generate Document on Contract Creation
Configure `ContractTypeConfig`:
- `ConfigType`: `AutoGenDocOnContractCreation`
- `ConfigValue`: `true`
- `UsageType`: `DocumentSetting`

And set `DefaultTemplateName` to the desired template developer name.

---

### Pattern: Server-Side Generation via Apex
```apex
Map<String, Object> params = new Map<String, Object>{
    'type'        => 'GenerateAndConvert',
    'status'      => 'InProgress',
    'requestText' => JSON.serialize(new Map<String, Object>{
        'contractDocumentVersionId' => cdvId
    })
};

Type t = Type.forName('industries_docgen.DocumentGenerationProcess');
System.Callable svc = (System.Callable) t.newInstance();
svc.Call('createDocumentGenerationProcess', params);
```

**Poll status:**
```apex
List<DocumentGenerationProcess> procs = [
    SELECT Id, Status, Type
    FROM DocumentGenerationProcess
    WHERE SourceObjectId = :cdvId
    ORDER BY CreatedDate DESC
    LIMIT 1
];
```

---

### Pattern: Listen for Generation Completion via Platform Event
Subscribe to `DocGenProcStsChgEvent` in a Trigger or Flow:

```apex
trigger DocGenProcessStatusTrigger on DocGenProcStsChgEvent (after insert) {
    for (DocGenProcStsChgEvent event : Trigger.New) {
        if (event.Status == 'Success') {
            // Handle generation success
            String cdvId = event.DocGenProcessIdentifier;
            // e.g., notify user, update record
        } else if (event.Status == 'Failure') {
            // Handle failure
            String errorMsg = event.Error;
        }
    }
}
```

---

### Pattern: Batch Document Generation
For generating documents across multiple contracts at once:

1. Create a `DocGenerationBatchProcess` record (Status: `New`)
2. Create individual `DocumentGenerationProcess` records linked to the batch
3. Monitor batch via `DocGenBtchStsChgEvent` platform event
4. Batch can be paused (`Status = Paused`) to allow other requests
5. Only one batch can be `InProgress` at a time

---

## E-Signature Automation

### Pattern: Send for Signature via Apex
```apex
// Build request via REST callout (or use the CLM REST action endpoint)
// POST /connect/e-sign/signature-requests/{sourceObjectId}/envelope/send

HttpRequest req = new HttpRequest();
req.setEndpoint('callout:CLM_NamedCredential/services/data/v67.0/connect/e-sign/signature-requests/' + contractId + '/envelope/send');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');

Map<String, Object> envelope = new Map<String, Object>{
    'vendor' => 'Docusign',
    'emailSettings' => new Map<String, Object>{
        'emailSubject' => 'Please sign: ' + contractName,
        'emailBody' => 'Your contract is ready for signature.'
    },
    'recipients' => new Map<String, Object>{
        'signers' => new List<Object>{
            new Map<String, Object>{
                'name' => signerName,
                'email' => signerEmail,
                'routingOrder' => '1',
                'recipientId' => '1',
                'signerRole' => 'Customer',
                'recipientType' => 'Signer'
            }
        }
    },
    'documents' => new List<Object>{
        new Map<String, Object>{
            'name' => 'Contract.docx',
            'sourceId' => contentVersionId,
            'fileExtension' => 'docx',
            'sourceType' => 'ContentVersion',
            'documentId' => '1'
        }
    }
};

req.setBody(JSON.serialize(new Map<String, Object>{'envelope' => envelope}));
Http http = new Http();
HttpResponse res = http.send(req);
```

---

### Pattern: Update Envelope Status via Contract Action
After DocuSign completes signing, trigger the status update:

```
PATCH /connect/clm/contract/{contractId}
{
  "actionApiName": "updateEnvelopeStatus",
  "actionData": {
    "isUpdateEnvelopeStatusSuccess": true
  }
}
```

The `EnvelopeStatusScheduler` handles this automatically every 15 minutes, but you can also trigger it manually via the REST action.

---

## Clause Library Automation

### Pattern: Promote Marked Content to Clause Library
When a user marks content in a contract document, create a `DocumentAuthoredContent` with `IsLibraryAdditionRequested = true`. Automate the promotion review in a Flow or Approval Process:

```apex
// Trigger on DocumentAuthoredContent where IsLibraryAdditionRequested = true
// Create a DocumentClause from the authored content
DocumentClause clause = new DocumentClause();
clause.Name = authoredContent.Name;
clause.Content = authoredContent.Content;
clause.Format = 'Rich_Text';
clause.Status = 'Review_Requested';
clause.Language = 'en_US';
clause.DocumentClauseSetId = clauseSetId;
insert clause;
```

---

## Obligation Automation

### Pattern: Auto-Activate Obligations Based on Contract Status
Configure `ContractTypeConfig`:
- `ConfigType`: `ActivateObligationsBasedOnContractStatus`
- `ConfigValue`: The contract status value that triggers obligation activation (e.g., `Activated`)

When the contract reaches that status, all linked `Obligation` records with `State = OnHold` are automatically set to `State = Active`.

---

### Pattern: Obligation Compliance Tracking via Scheduled Flow
Create a Scheduled Flow that runs daily:
1. Query `Obligation` records where `State = Active` AND `EndDate < TODAY`
2. Update `State = Expired`
3. Send notifications to `AssigneeUser`

---

## AI Contract Extraction Automation

### Pattern: Auto-Process Extraction on PDF Upload
Create a Record-Triggered Flow on `ContractExtractionResult`:
- Trigger: After Insert, Status = `ReviewNotStarted`
- Action: Send notification to contract manager to begin review

### Pattern: Create Contract from Extraction on Approval
When `ContractExtractionResult.Status → ReviewCompleted`:

```
POST /connect/clm/contract
{
  "sourceObjectId": "{opportunityId}",
  "isAutoDocgenRequired": false,
  "recordTypeName": "ContractLifecycleManagement"
}
```

Then use the `PATCH /connect/clm/contract/{contractId}` action to import extracted data.

---

## Microsoft 365 Integration Patterns

### Pattern: Data True-Up (Sync Document Changes to Salesforce)
After a user edits a contract in Microsoft 365 and wants to push changes back:

```
POST /connect/content-link/data-sync
{
  "referenceObjectId": "{contractId}",
  "partialCommit": true,
  "contentLinkDetailsList": [
    {
      "contentLinkId": "6UPVW00000003CQ4AY",
      "contentValue": "Updated payment terms..."
    }
  ]
}
```

### Pattern: Pull Latest Data into Document (True-Up Pull)
Before editing a document in Microsoft 365, pull the latest Salesforce values into the document:

```
POST /connect/content-link/load
{
  "referenceObjectId": "{contractId}",
  "contentLinkIds": ["0D56A000008yhfSAAQ"]
}
```

---

## Integration Procedure Integration

### Pattern: Call CLM REST Action from Integration Procedure
Use an HTTP Action step in an Integration Procedure to call CLM endpoints:

```json
{
  "stepType": "HTTPAction",
  "actionType": "PATCH",
  "resourcePath": "/services/data/v67.0/connect/clm/contract/{!ContractId}",
  "namedCredential": "CLM_API",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "actionApiName": "sendForSignature"
  },
  "responseOutputPath": "ContractActionResult"
}
```
