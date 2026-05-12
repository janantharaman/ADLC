---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: api-reference
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — API Reference

## REST API Base Path

All Salesforce Contracts REST resources are under:
```
https://yourInstance.salesforce.com/services/data/v{version}/connect/
```

---

## Clause Library Resources

### GET /connect/clause-library/clause-category-configurations
Get clause categories. Available v57.0.

**Parameters:**
- `name` (Required) — clause category name
- `usageType` (Required) — `Contract Clause Category` or `Disclosure Category`

---

### GET /connect/clause-library/document-clauses/fields
Get distinct field values for clauses in a clause set. Available v57.0.

**Parameters:**
- `clauseSetId` (Required)
- `fieldName` (Required) — `Language` or `Name`
- `language` (Required)
- `name` (Required)
- `status` (Required)

---

### GET /connect/clause-library/document-clause-sets
Get document clause sets with filters. Available v57.0.

**Parameters:**
- `category` (Required) — comma-separated
- `defaultLanguage` (Required) — comma-separated
- `name` (Required)
- `status` (Required) — comma-separated

---

## CLM Resources

### PATCH /connect/clm/contract-document-version/{contractDocumentVersionId}/checkIn
Check in a contract document version. Available v56.0.

---

### POST /connect/clm/contract-document-version/{contractDocumentVersionId}/checkout
Check out a contract document version for modification. Available v56.0.

**Request body:**
```json
{
  "templateId": "2dtxx000000004rAAA",
  "isExternalReviewImport": false,
  "externalReviewType": "OnlineMicrosoft365",
  "pdfDocumentId": "069XXXXXXXXXX",
  "wordDocumentId": "069XXXXXXXXXX"
}
```

| Field | Type | Required | Version |
|---|---|---|---|
| `templateId` | String | Required | 56.0 |
| `isExternalReviewImport` | Boolean | Optional | 59.0 |
| `externalReviewType` | String | Optional | 60.0 — `OnlineMicrosoft365` or `OfflineMicrosoftWord` |
| `pdfDocumentId` | String | Optional | 56.0 |
| `wordDocumentId` | String | Optional | 56.0 |

---

### GET/DELETE/PATCH /connect/clm/contract-document-version/{contractDocumentVersionId}/content-documents
Manage content documents on a contract document version. Available v56.0.

**DELETE parameter:**
- `contentDocumentId` (Required) — ID of ContentDocument to detach

**PATCH parameter (v60.0):**
- `contentDocumentId` (Required) — ID to update sharing
- `share` (Required) — `true` to enable sharing, `false` to disable

---

### PATCH/POST /connect/clm/contract
Create or update a contract. Available v56.0.

**Request body:**
```json
{
  "sourceObjectId": "006xx000001a4KaAAI",
  "templateName": "StandardAgreement",
  "isAutoDocgenRequired": true,
  "recordTypeName": "ContractLifecycleManagement"
}
```

| Field | Required | Notes |
|---|---|---|
| `sourceObjectId` | Required | Source record ID (e.g., Opportunity ID) |
| `isAutoDocgenRequired` | Required | Whether to auto-generate document |
| `templateName` | Optional | Template name for document generation |
| `recordTypeName` | Optional | Contract record type |

---

### PATCH /connect/clm/contract/{contractId}
Execute a contract action (trigger state transition). Available v56.0.

**Request body:**
```json
{
  "actionApiName": "updateEnvelopeStatus",
  "actionId": "0OA...",
  "actionData": {
    "isUpdateEnvelopeStatusSuccess": true
  }
}
```

Note: Either `actionApiName` OR `actionId` must be passed. Both together is valid; neither raises an exception.

---

### GET/POST /connect/clm/contract/{contractId}/contract-document-version
Get or create contract document versions. Available v56.0.

**POST request body:** Same as checkout body (`templateId` required).

---

### GET /connect/clm/document-generation-process/status
Get document generation status for a contract document version. Available v56.0.

**Parameters:**
- `contractDocumentVersionId` (Required)

---

### GET /connect/clm/document-template
List configured templates. Available v55.0.

**Parameters:**
- `usageType` (Required) — e.g., `Contract_Life_Cycle_Management`
- `isActive` (Required) — boolean
- `type` (Required) — e.g., `MicrosoftWord`
- `contractId` (Optional)

---

### GET /connect/clm/contract/{contractId}/contract-actions
List available actions for a contract. Available v56.0.

---

### PATCH /connect/clm/contract-document-version/{contractDocumentVersionId}/lock
Lock active document version. Available v56.0.

---

### PATCH /connect/clm/contract-document-version/{contractDocumentVersionId}/unlock
Unlock document version. Available v56.0.

---

### PATCH /connect/clm/contract-document-version/{contractDocumentVersionId}
Change template in a contract document version. Available v56.0. Same body as checkout.

---

## Context Mapping Extraction Resources

### POST /connect/clm/extraction-context-mappings
Create extraction context mapping for AI contract extraction. Available v61.0.

**Request body:**
```json
{
  "ContextUsecaseMapping": {
    "templateName": "ContractExtractionTemplate",
    "contextDefinitionDeveloperName": "ContractExtractionContextDefinition",
    "mappingName": "ContractExtractionMappingName",
    "targetObject": "Contract",
    "recordType": "CLM"
  },
  "contextAttributeMapping": [
    {
      "attributeId": "11nxx000001hOozAAE",
      "description": "extract startDate from the document"
    }
  ]
}
```

---

### GET/PATCH/DELETE /connect/clm/extraction-context-mappings/{contextUseCaseMappingId}
Get, update, or delete an extraction context mapping. Available v61.0.

---

## Customer Community Resources

### GET /connect/clm/cc/contract/{contractId}/contract-document-version
Get latest contract document version details for Customer Community users. Available v60.0.

**Parameters:**
- `showDetails` (Required) — boolean; include attachment details

---

### GET /connect/clm/cc/documentRecipient
Get e-signature recipient status for Customer Community users. Available v61.0.

**Parameters:**
- `contractDocumentVersionId` (Required)

---

### GET /connect/clm/cc/external-document
Get external document for review (Customer Community). Available v61.0.

**Parameters:**
- `contractDocumentVersionId` (Required)

---

## Data True-Up Resources (Microsoft 365 Integration)

### POST /connect/content-link/load
Fetch content token data from ContentLink objects. Available v62.0.

**Request body:**
```json
{
  "referenceObjectId": "a0X4W00000X8jklUAB",
  "isBulkRequest": false,
  "contentLinkIds": ["0D56A000008yhfSAAQ"]
}
```

---

### POST /connect/content-link/data-sync
Synchronize updated document values back to Salesforce records. Available v65.0.

**Request body:**
```json
{
  "referenceObjectId": "069xx0000004CsCAAU",
  "partialCommit": false,
  "isBulkRequest": false,
  "contentLinkDetailsList": [
    {
      "contentLinkId": "6UPVW00000003CQ4AY",
      "contentValue": "Updated contract description"
    }
  ]
}
```

---

## Design Document Template Resources

### GET/PATCH/POST /connect/docgen/document-templates
Manage document templates (create, update, clone, version). Available v60.0.

**GET parameters:**
- `offset`, `limit`, `searchString`, `type`, `usageType`, `cloneOnly`

**POST body:**
```json
{
  "name": "TemplateName",
  "type": "MicrosoftWord",
  "tokenMappingMethodType": "OmniDataTransform",
  "tokenMappingType": "JSON",
  "extractOmniDataTransformName": "ExtractName",
  "mapperOmniDataTransformName": "MapperName",
  "contentDocumentId": "069xx0000004CyeAAE",
  "documentGenerationMechanism": "ServerSide",
  "usageType": "Contract_Lifecycle_Management",
  "tokenList": "token1,token2,token3"
}
```

**POST parameters:**
- `action` — `Clone` or `NewVersion`
- `documentTemplateId` — required for Clone/NewVersion

---

## External Document Resources

### PUT /connect/external-document/save
Save external (Microsoft 365) document metadata. Available v58.0.

---

### GET/POST /connect/external-document
Get external document details or create a new external document. Available v58.0.

**POST body:**
```json
{
  "refObjectId": "...",
  "contentversionId": "...",
  "documentNamePrefix": "namespace_prefix",
  "isAsync": true
}
```

---

## E-Signature Resources

### POST /connect/e-sign/signature-requests/{sourceObjectId}/envelope/send
Send document envelope to DocuSign. Available v56.0.

**Request body (abbreviated):**
```json
{
  "vendor": "Docusign",
  "emailSettings": {
    "emailSubject": "Please sign",
    "emailBody": "..."
  },
  "recipients": {
    "signers": [
      {
        "name": "John Smith",
        "email": "john@example.com",
        "routingOrder": "1",
        "recipientId": "1",
        "signerRole": "Customer",
        "recipientType": "Signer"
      }
    ]
  },
  "documents": [
    {
      "name": "Contract.docx",
      "sourceId": "069XXXXXXXXXX",
      "fileExtension": "docx",
      "sourceType": "ContentVersion",
      "documentId": "1"
    }
  ]
}
```

---

### GET /connect/e-sign/documents
List documents sent for e-signature. Available v56.0.

**Parameters:**
- `sourceObjectId` (Required)
- `documentSelector` (Optional) — custom class name

---

### PATCH /connect/e-sign/signature-requests/{sourceObjectId}/envelopes/status
Update e-signature envelope status. Available v56.0.

---

### PATCH /connect/e-sign/signature-requests/{sourceObjectId}/envelopes/void
Void/expire e-signature envelopes. Available v56.0.

**Request body:**
```json
{
  "voidedReason": "Contract cancelled",
  "senderEmail": "sender@example.com"
}
```

---

### GET /connect/e-sign/notification-settings
Get DocuSign notification settings for an object. Available v56.0.

**Parameters:** `sourceObjectId` (Required)

---

### GET /connect/e-sign/recipients
Get list of e-signature recipients. Available v56.0.

**Parameters:** `sourceObjectId` (Required), `recipientSelector` (Optional)

---

### GET /connect/e-sign/signer-roles
Get available e-signature signer roles. Available v56.0.

---

## Invocable Action — Search Contract Document

**URI:** `POST /services/data/v67.0/actions/standard/searchContractDocument`

**Available since:** API v64.0

**License:** Requires `Contracts AI User` permission set.

**Request:**
```json
{
  "inputs": [
    {
      "contractId": "800VW000006142vYAA",
      "searchQuery": "Show me the contract for paper packaging deliveries.",
      "resultLimit": "1000"
    }
  ]
}
```

| Input | Type | Required | Notes |
|---|---|---|---|
| `contractId` | String | Yes | ID of the Contract record |
| `searchQuery` | String | Yes | Natural language search query |
| `resultLimit` | String | Yes | Max number of text segments returned |

**Response:**
```json
{
  "actionName": "searchContractDocument",
  "isSuccess": true,
  "outputValues": {
    "searchResult": "AGREEMENT FOR DELIVERY OF PAPER PACKAGING MATERIALS\n\nThis Agreement...."
  }
}
```

---

## SOQL Reference

```soql
-- Active contract document versions for a contract
SELECT Id, Status, CreationProcessType, LockType,
    HasRedlinedSection, RedlinedSectionCount, NonStandardSectionCount,
    DocumentTemplate.Name, DocumentTemplate.Type
FROM ContractDocumentVersion
WHERE ContractId = :contractId
AND Status = 'Active'
ORDER BY CreatedDate DESC

-- Clauses in a clause set by language
SELECT Id, Name, Content, Status, Language, IsAlternateClause, Version
FROM DocumentClause
WHERE DocumentClauseSetId = :clauseSetId
AND Status = 'Active'
ORDER BY Language, IsAlternateClause

-- Active obligations for a contract
SELECT Id, Name, Type, Party, State, Status, StartDate, EndDate,
    AssigneeUser.Name, OtherPartyAccount.Name
FROM Obligation
WHERE ReferenceObjectId = :contractId
AND State = 'Active'

-- Document generation process status
SELECT Id, Name, Status, Type, ReferenceObject,
    SourceObject.Name
FROM DocumentGenerationProcess
WHERE SourceObjectId = :contractDocVersionId
ORDER BY CreatedDate DESC
LIMIT 1

-- E-signature envelope status for a contract version
SELECT Id, Name, Status, Vendor, EnvelopeIdentifier,
    FinalStatusDateTime, FinalStatusReason
FROM DocumentEnvelope
WHERE ContractDocumentVersionId = :contractDocVersionId

-- Sales contract lines
SELECT Id, Name, Status, Quantity, UnitPrice, TotalPrice,
    Product2.Name, ProductCode,
    EffectiveStartDateTime, EffectiveEndDateTime
FROM SalesContractLine
WHERE ContractId = :contractId
AND Status = 'Active'
```
