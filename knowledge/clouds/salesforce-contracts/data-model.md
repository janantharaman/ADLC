---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: data-model
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — Data Model

## Core Object Map

```
Contract (standard)
  ├── ContractDocumentVersion (versions of the contract document)
  │     ├── ContractDocVerContentDoc (junction → ContentDocument)
  │     ├── ContractDocVersionSection (rendered sections)
  │     ├── DocumentEnvelope (e-signature envelope)
  │     └── DocumentGenerationProcess (generation request/status)
  ├── SalesContractLine (product/pricing line items)
  └── Obligation (contractual commitments)
```

---

## Object Reference

### ClauseCatgConfiguration
**Purpose:** Clause category configuration for organizing clauses in the clause library.

| Field | Type | Notes |
|---|---|---|
| `MasterLabel` | string | Display name |
| `UsageType` | picklist | `ContractClauseCategory`, `DisclosureCategory` |

**License:** Requires `ClauseManagementAddOn` license.
**API:** Available v57.0+

---

### ContextUseCaseMapping
**Purpose:** Configures AI context service mappings for contract creation/update or extraction flows.

| Field | Type | Notes |
|---|---|---|
| `MasterLabel` | string | Display name |
| `MappingType` | picklist | `Hydration` (data retrieval) or `Persistence` (data storage/update) |
| `UseCaseType` | picklist | `ContractCreationOrUpdation` or `ContractExtraction` |
| `ContextDefinitionName` | string | References a ContextDefinition component |
| `MappingName` | string | e.g., `OppToCntrHydrationMapping` or `OppToCntrPersistenceMapping` |
| `ReferenceObjectName` | string | Source object (e.g., `Opportunity`) |
| `TargetObjectName` | string | Destination object (typically `Contract`) |
| `ReferenceObjectRecordType` | string | v61.0+ record type filtering on source |
| `TargetObjectRecordType` | string | v61.0+ record type filtering on target |
| `TargetObjectCustomFieldName` | string | Custom field linking target to reference object |
| `AdditionalUseCaseInput` | textarea | v67.0+ — stores LLM model selection for AI extraction |

---

### ContractDocumentReview
**Purpose:** Tracks external review cycles (Microsoft 365 or offline Word review).

| Field | Type | Notes |
|---|---|---|
| `Status` | picklist | `NotStarted`, `InProgress`, `Completed` |
| `ContractDocumentVersionId` | reference | Parent ContractDocumentVersion |
| `UnresolvedCommentCount` | int | Count of open review comments |

**License:** Requires DocGen platform license.

---

### ContractDocumentVersion
**Purpose:** Versioned snapshot of a contract document. Core unit of the CLM lifecycle.

| Field | Type | Notes |
|---|---|---|
| `Status` | picklist | `Active`, `Inactive`, `Draft` |
| `CreationProcessType` | picklist | `BatchMode`, `Checkout`, `CheckoutModify`, `ContractReconciliation`, `CreateContract`, `Customize`, `External_Online_Editor`, `Generate`, `Import`, `Microsoft365ExternalReview`, `Microsoft365PrivateExternalReview`, `ReconcileWord`, `UpdateContract` |
| `LockType` | picklist | `Generate`, `SuperUser`, `User` |
| `HasRedlinedSection` | boolean | Whether version has redlined sections |
| `RedlinedSectionCount` | int | Count of redlined sections |
| `NonStandardSectionCount` | int | Count of non-standard sections |
| `ContractId` | reference | Parent Contract |
| `DocumentTemplateId` | reference | Template used to generate this version |

**Key prefix:** `0qt`

---

### ContractDocVerContentDoc
**Purpose:** Junction between `ContractDocumentVersion` and `ContentDocument`.

| Field | Type | Notes |
|---|---|---|
| `ContractDocumentVersionId` | reference | Parent version |
| `ContentDocumentId` | reference | Linked ContentDocument |
| `DocumentType` | picklist | `AttachedDocument`, `ComparisonDocument`, `ContractDocument`, `ExternalReviewDocument`, `SignedDocument` |
| `DocumentSourceType` | picklist | `Content`, `External` |

---

### ContractDocVersionSection
**Purpose:** Individual sections within a `ContractDocumentVersion`.

| Field | Type | Notes |
|---|---|---|
| `SectionType` | picklist | `Clause`, `Context`, `Custom`, `EmbeddedTemplate`, `Image`, `Item`, `RepeatingContent`, `Signature` |
| `SectionContent` | textarea | HTML content of the section |
| `XmlContent` | textarea | XML representation |
| `TokenList` | textarea | Tokens used in this section |
| `SignatureContent` | textarea | DocuSign tokens (for Signature type) |
| `IsSectionStandard` | boolean | Whether the section matches standard library content |
| `IsRedlinedSection` | boolean | Whether the section has redlines |
| `Level` | int | Hierarchy level |
| `Sequence` | double | Order within the version |
| `SubSequence` | double | Sub-ordering |

---

### ContractExtractionResult
**Purpose:** Temporarily stores AI-extracted contract fields and clauses from uploaded PDFs before contract creation.

| Field | Type | Notes |
|---|---|---|
| `ContentDocumentId` | reference | Source PDF ContentDocument |
| `ExtractedContractDetails` | textarea | Extracted field values (JSON) |
| `ExtractedContractFieldCount` | int | Number of fields extracted |
| `ExtractedClauseContent` | textarea | Extracted clause content (up to 131K chars) |
| `ExtractedClauseContentDocId` | reference | ContentDocument for overflow clause content (>131K) |
| `ExtractedClauseCount` | int | Number of clauses extracted |
| `Status` | picklist | `ExtractionFailed`, `ExtractionInProgress`, `ReviewCompleted`, `ReviewInProgress`, `ReviewNotStarted` |
| `ExtractionMode` | picklist | `SingleExtraction`, `BulkExtraction` (v67.0) |
| `DocumentAIJobIdentifier` | string | v67.0 — AI job ID |
| `SourceDocumentIdentifier` | string | v67.0 — external repository document ID |
| `SubBatchJobSequence` | int | v67.0 — batch sequence number |

**Available since:** API v60.0

---

### ContractType
**Purpose:** Groups contracts with similar lifecycle states, permissions, templates, and clauses.

| Field | Type | Notes |
|---|---|---|
| `Name` | string | Contract type name |
| `IsDefault` | boolean | Whether this is the default type for the org |
| `SubTypes` | string | Linked Contract record type names |

---

### ContractTypeConfig
**Purpose:** Key/value settings defining behavior for a ContractType.

| Field | Type | Notes |
|---|---|---|
| `ContractTypeId` | reference | Parent ContractType |
| `ConfigType` | picklist | One of 30+ config keys (see implementation guide) |
| `ConfigValue` | textarea | Value for the config setting |
| `UsageType` | picklist | `DocumentSetting`, `ObligationSetting`, `Reconciliation`, `Redlining`, `SignatureSetting` |

---

### DocGenerationBatchProcess
**Purpose:** Groups multiple document generation requests for batch processing. Only one active batch at a time.

| Field | Type | Notes |
|---|---|---|
| `Status` | picklist | `New`, `InProgress`, `Completed`, `Paused`, `Canceled` |
| `TotalRequestCount` | int | Total requests in batch |
| `SuccessfulRequestCount` | int | Successful completions |
| `FailedRequestCount` | int | Failed requests |
| `InProgressRequestCount` | int | Currently processing |
| `Category` | picklist | `Agreements`, `Proposals`, `Quotes` |

**License:** Requires DocGen platform license.

---

### DocumentAuthoredContent
**Purpose:** Metadata for marked clauses and sections within a contract document or template.

| Field | Type | Notes |
|---|---|---|
| `ContentType` | picklist | `DocumentAuthoredClause`, `DocumentAuthoredSection`, `StandardDocumentClause` |
| `ContentGenerationSource` | picklist | `GenAIDrafted`, `GenAIExtracted`, `MarkedContent`, `StandardContent` |
| `ReferenceObjectId` | reference | `ContractDocumentVersion` or `DocumentTemplate` |
| `StandardContentObjectId` | reference | Linked `DocumentClause` (if standard content) |
| `ParentContentId` | reference | Parent `DocumentAuthoredContent` (for clause-within-section hierarchy) |
| `IsLibraryAdditionRequested` | boolean | Whether promotion to clause library has been requested |
| `IsReviewed` | boolean | Whether content has been reviewed |

---

### DocumentClause
**Purpose:** Reusable clause that can be associated with multiple templates.

| Field | Type | Notes |
|---|---|---|
| `Content` | textarea | HTML content of the clause |
| `Format` | picklist | `Rich_Text`, `Non_Formatted` |
| `Status` | picklist | `Draft`, `Review_Requested`, `In_Approval`, `Active`, `Archived`, `AI_Drafted` (v60.0) |
| `Language` | picklist | 18 supported languages (en_US default) |
| `IsAlternateClause` | boolean | Whether this is an alternate (not main) clause |
| `DocumentClauseSetId` | reference | Parent `DocumentClauseSet` |
| `Version` | int | Version number |

**License:** Requires `ClauseManagement` platform license + PSL.

---

### DocumentClauseSet
**Purpose:** Groups multiple language/alternate variations of the same clause.

| Field | Type | Notes |
|---|---|---|
| `Category` | picklist | References `ClauseCatgConfiguration` values |
| `DefaultLanguage` | picklist | Default language for the set |
| `Status` | picklist | `Draft`, `Active`, `Archived` |

---

### DocumentEnvelope
**Purpose:** Container for documents sent for e-signature.

| Field | Type | Notes |
|---|---|---|
| `ContractDocumentVersionId` | reference | Parent ContractDocumentVersion |
| `EnvelopeIdentifier` | string | DocuSign envelope ID |
| `Status` | picklist | `Sent`, `Delivered`, `Declined`, `Voided`, `Completed` |
| `Vendor` | picklist | eSignature provider (DocuSign) |
| `EnvelopeUri` | string | URI of the envelope |
| `EnvelopeSubject` | string | Email subject |
| `EnvelopeMessageContent` | textarea | Email body |
| `FinalStatusDateTime` | dateTime | When envelope was completed |

---

### DocumentGenerationProcess
**Purpose:** Server-side document generation request and response record.

| Field | Type | Notes |
|---|---|---|
| `Status` | picklist | `InProgress`, `Success`, `Failure` |
| `Type` | picklist | `Generate`, `Convert`, `GenerateAndConvert`, `MergePDF` |
| `SourceObjectId` | reference | `ContractDocumentVersion` that triggered generation |
| `ReferenceObject` | string | Object to which the generated document is attached |
| `TokenData` | textarea | JSON data with user-entered information |
| `DataRaptorInput` | textarea | Additional DataRaptor input |
| `IsLocalizationEnabled` | boolean | v67.0 — Apply user locale to context token data |
| `IsTocUpdateRequired` | boolean | v67.0 — Update table of contents (docs ≤25 MB) |
| `ShouldUseLargeFileSizeProc` | boolean | v67.0 — Route through LFS infrastructure |
| `ContextTokenProcessingType` | picklist | v67.0 — `Regular` or `Large` (Revenue Cloud licenses) |
| `PdfDocIdentifiersList` | string | v63.0 — Up to 10 PDF ContentVersionIds for merge |

**Auto-name:** `Request-001`, `Request-002`, etc.

---

### DocumentGenerationSetting
**Purpose:** Org-level settings for document generation behavior.

| Field | Type | Notes |
|---|---|---|
| `GenerationMechanism` | picklist | `ClientSide` (default), `ServerSide` |
| `IsServerSideDocGenEnabled` | boolean | Whether server-side generation is enabled |
| `IsBatchDocGnrnEnabled` | boolean | Whether batch generation is enabled |
| `BatchDocGnrnPctLimitPerHour` | percent | Hourly batch processing limit |
| `InProgDocGenRqstTmot` | int | Timeout in hours for InProgress records (1–24; default 6) |
| `IsInProgRqstTmotEnab` | boolean | Whether timeout is enabled |
| `GuestAccessNamedCredential` | string | Named credential for guest user document generation |
| `PreviewType` | picklist | `PDF` (default) or `Thumbnail` |

---

### DocumentTemplate
**Purpose:** Defines a document template for dynamic generation.

| Field | Type | Notes |
|---|---|---|
| `Type` | picklist | `Web`, `MicrosoftWord`, `Microsoft365Word`, `MicrosoftPowerpoint`, `HTMLArchive` |
| `Status` | picklist | `Draft`, `Active`, `Archived` |
| `TokenMappingMethodType` | picklist | `OmniDataTransform`, `ContextService`, `CustomClass` |
| `TokenMappingType` | picklist | `JSON`, `SalesforceObject` |
| `ExtractOmniDataTransformName` | string | Extract DataTransform bundle name |
| `MapperOmniDataTransformName` | string | Mapper DataTransform bundle name |
| `ContextDefinitionName` | string | v65.0+ — Context service definition |
| `ContextMappingName` | string | v65.0+ — Context service mapping |
| `ContextTransformationName` | string | v67.0+ — Context service transformation (nested groups, bundles) |
| `CustomClassName` | string | Custom Apex class for token data |
| `DocumentGenerationMechanism` | picklist | `ClientSide` (default) or `ServerSide` |
| `UsageType` | picklist | `Contract_Lifecycle_Management`, `Revenue_Lifecycle_Management` |
| `TargetTokenObject` | multipicklist | `Contract`, `Opportunity`, `Order`, `Quote` |
| `TargetTokenItemObject` | multipicklist | `OpportunityLineItem`, `OrderLineItem`, `QuoteLineItem` |
| `IsActive` | boolean | Whether template is active |
| `VersionNumber` | int | Template version |
| `UniqueName` | string | Used for migration between orgs |
| `HasBatchableSection` | boolean | Whether template has batchable sections |

---

### DocumentTemplateSection
**Purpose:** A section within a `DocumentTemplate`.

| Field | Type | Notes |
|---|---|---|
| `SectionType` | picklist | `Clause`, `Context`, `Custom`, `EmbeddedTemplate`, `Image`, `Item`, `RepeatingContent`, `Signature` |
| `DocumentTemplateId` | reference | Parent template |
| `DocumentTemplateClauseId` | reference | Linked `DocumentClause` (for Clause type) |
| `EmbeddedDocumentTemplateId` | reference | Embedded template (for EmbeddedTemplate type) |
| `SectionContent` | textarea | HTML or JSON content |
| `SectionSequenceNumber` | double | Display order |
| `AccessType` | picklist | `Editable` (default) or `ReadOnly` |
| `DisplayConditionExpression` | textarea | Condition logic for conditional section display |
| `TokenList` | textarea | Tokens used in section |
| `SectionTypeSignatureContent` | textarea | DocuSign tokens (for Signature type) |
| `IsBatchable` | boolean | Whether section uses batch generation |
| `IsDisplayOnNewPage` | boolean | Force page break before section |

---

### ESignatureConfig
**Purpose:** DocuSign integration configuration settings.

| Field | Type | Notes |
|---|---|---|
| `ConfigType` | picklist | `AnchorString`, `SignerRoles`, `SyncFileSizeLimit`, `CalloutTimeout`, `EnvelopesLastPollDate`, `CalloutNamedCredential`, `eSignVendorAccountId`, `RecipientsCustomClass`, `DocumentsCustomClass` |
| `ConfigValue` | string | Value for the config type |
| `GroupType` | picklist | `AnchorTabSetting`, `EnvelopeObjectLimits`, `CalloutConfigurationSetup`, `Envelope`, `eSignVendorAccount`, `CustomClassSetting` |
| `Vendor` | picklist | DocuSign only |

---

### ESignatureEnvelopeConfig
**Purpose:** Per-object DocuSign notification settings (expiry, reminders).

| Field | Type | Notes |
|---|---|---|
| `TargetObjectName` | picklist | Object the eSignature applies to |
| `Vendor` | picklist | DocuSign only |
| `IsExpirationEnabled` | boolean | Whether expiration is enabled |
| `ExpirationPeriod` | int | Days until expiry |
| `ExpirationWarningPeriod` | int | Days before expiry for warning |
| `IsReminderEnabled` | boolean | Whether reminders are enabled |
| `FirstReminderPeriod` | int | Days between delivery and first reminder |
| `ReminderIntervalPeriod` | int | Days between subsequent reminders |
| `IsVendorDefaultNtfcnEnabled` | boolean | Use DocuSign account default notifications |
| `VendorAccountIdentifier` | string | DocuSign branding identifier |

---

### ExternalDocStorageConfig
**Purpose:** Configures external document storage (Microsoft OneDrive).

| Field | Type | Notes |
|---|---|---|
| `StorageDriveType` | picklist | `MicrosoftOneDrive` (only value) |
| `TargetObject` | picklist | `All`, `Contract`, `DocumentTemplate`, `Disclosure`, `InfoLibraryExternalDocument` |
| `NamedCredentialId` | reference | Named Credential for the OneDrive connection |
| `DocumentPath` | textarea | Path from root in the external storage |
| `RecordTypeId` | reference | Record type filter for the target object |

---

### GeneratedDocumentSection
**Purpose:** A section in a generated (rendered) document (as opposed to a template section).

| Field | Type | Notes |
|---|---|---|
| `GeneratedDocumentId` | reference | Parent `GeneratedDocument` (master-detail) |
| `DocumentTemplateSectionId` | reference | Source template section |
| `SectionContent` | textarea | HTML content |
| `XmlContent` | textarea | XML content |
| `SectionOrder` | double | Order in the document |
| `TokenList` | textarea | Tokens used |
| `SectionTypeSignatureContent` | textarea | DocuSign tokens |

---

### Obligation
**Purpose:** Contractual commitments (payment due dates, renewal terms, compliance tasks).

| Field | Type | Notes |
|---|---|---|
| `ReferenceObjectId` | reference | Linked `Contract` |
| `AssigneeUserId` | reference | User responsible for fulfillment |
| `OtherPartyAccountId` | reference | Counterparty Account |
| `Party` | picklist | `FIRST_PARTY`, `OTHER_PARTY` |
| `State` | picklist | `Active`, `Expired`, `InActive`, `OnHold` (default OnHold) |
| `Status` | picklist | `Compliant`, `Non Compliant`, `At Risk`, `None` (default Compliant) |
| `StartDate` | date | Start of obligation period |
| `EndDate` | date | End of obligation period |
| `Type` | picklist | User-defined obligation type |

**License:** Requires `ObligationManagement` permission license.

---

### ObjectStateActionDefinition
**Purpose:** Links an object state (contract lifecycle state) to an action that triggers a state transition.

| Field | Type | Notes |
|---|---|---|
| `ActionType` | picklist | `Apex`, `ReferenceObject` |
| `DisplayLabel` | string | UI label for the action |
| `InvocableClassName` | string | Apex invocable class (for Apex type) |
| `InvocableMethodName` | string | Apex method name |
| `ReferenceObjectId` | reference | OmniProcess (for ReferenceObject type) |
| `IsSystem` | boolean | True if Salesforce-provided standard action |

---

### ObjectStateTransitionAction
**Purpose:** Junction between an `ObjectStateTransition` and an `ObjectStateActionDefinition`.

| Field | Type | Notes |
|---|---|---|
| `ObjectStateActionDefinitionId` | reference | The action being triggered |
| `ObjectStateDefinitionId` | reference | The state this applies to |
| `ObjectStateTransitionId` | reference | The transition this action belongs to |
| `IsActive` | boolean | Whether this action is active |
| `DisplaySequence` | int | Display order (>0) |

---

### SalesContractLine
**Purpose:** Contract product line items (mirroring order/quote line items in a contract context).

| Field | Type | Notes |
|---|---|---|
| `ContractId` | reference | Parent Contract |
| `Product2Id` | reference | Associated product |
| `OpportunityProductId` | reference | Source OpportunityLineItem |
| `OrderProductId` | reference | Source OrderItem |
| `OriginalLineItemId` | reference | Original line (for amendments) |
| `Status` | picklist | `Active`, `Inactive` |
| `Quantity` | double | Product quantity |
| `UnitPrice` | currency | Unit price |
| `TotalPrice` | currency | Total price |
| `EffectiveStartDateTime` | dateTime | Line item effective start |
| `EffectiveEndDateTime` | dateTime | Line item effective end |

---

### UserEsignVendorIdentifier
**Purpose:** Maps a Salesforce user to their DocuSign user ID.

| Field | Type | Notes |
|---|---|---|
| `UserId` | reference | Salesforce User |
| `ExternalUserIdentifier` | string | DocuSign user ID |
| `Vendor` | picklist | `DocuSign` (default) |
| `VendorType` | picklist | `eSignature` (default) or `Internal` |

---

## Key Relationships

```
DocumentClauseSet
  └── DocumentClause (many)            ← clause library

DocumentTemplate
  └── DocumentTemplateSection (many)   ← template definition
        └── DocumentClause             ← when SectionType = Clause

Contract
  ├── ContractDocumentVersion (many)   ← version history
  │     ├── ContractDocVerContentDoc   ← attached files
  │     ├── ContractDocVersionSection  ← rendered sections
  │     └── DocumentEnvelope           ← e-signature envelope
  ├── SalesContractLine (many)         ← product lines
  └── Obligation (many)                ← contractual commitments

ContractExtractionResult               ← AI-extracted data (pre-creation)
ContextUseCaseMapping                  ← AI context config
DocumentGenerationProcess              ← server-side gen requests
DocGenerationBatchProcess              ← batch gen containers
```
