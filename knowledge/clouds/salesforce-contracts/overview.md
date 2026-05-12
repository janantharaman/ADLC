---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: overview
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — Overview

## What It Is

Salesforce Contracts is the **native, next-generation Contract Lifecycle Management (CLM)** platform built on core Salesforce. It is centered around the standard **`Contract`** object and extends it with document authoring, templating, e-signature, obligation tracking, AI extraction, and clause library management.

**This is distinct from Vlocity CLM.** Legacy Vlocity CLM used `vlocity_cmt__DocumentTemplate__c`, `vlocity_cmt__DocumentClause__c`, etc. Salesforce Contracts uses standard objects (`DocumentTemplate`, `DocumentClause`, `ContractDocumentVersion`) in the `industries_clm` and `industries_docgen` namespaces. When implementing CLM on E&U or other Vlocity-based clouds, confirm which CLM layer the customer is using.

---

## Namespaces

| Namespace | Purpose |
|---|---|
| `industries_clm` | Custom Apex logic hooks — document template filtering, custom class implementations |
| `industries_docgen` | Document generation engine — permission checks, process management, template management |
| `ind_docgen_api` | DocuSign envelope status scheduler |

No `vlocity_cmt__` prefix is used for any Salesforce Contracts object.

---

## License Architecture

| License | What It Enables |
|---|---|
| **DocGen platform license** | Core document generation (DocumentGenerationProcess, DocumentGenerationSetting, DocGenerationBatchProcess, DocumentTemplateSection, DocumentAuthoredContent) |
| **ClauseManagement platform license + PSL** | `DocumentClause`, `DocumentClauseSet` — clause library management |
| **ClauseManagementAddOn** | `ClauseCatgConfiguration` — clause category configuration |
| **ObligationManagement permission license** | `Obligation` object |
| **Contracts AI User** permission set | `searchContractDocument` invocable action (AI semantic search of contract documents) |

---

## Core Functional Areas

### 1. Document Template Management
- **`DocumentTemplate`** — defines the template (Word, PowerPoint, Microsoft365Word, Web, HTMLArchive)
- **`DocumentTemplateSection`** — sections within a template (Clause, Context, Custom, EmbeddedTemplate, Image, Item, RepeatingContent, Signature)
- Token mapping via **OmniDataTransform** (extract + mapper bundles) or **Context Service** (ContextDefinition + ContextMapping)
- Templates deployed as Metadata API type `DocumentTemplate` (.dt files in `documentTemplates/` folder)

### 2. Contract Document Lifecycle
- **`ContractDocumentVersion`** — versioned snapshots of a contract document; tracks status, lock type, redlines
- **`ContractDocVerContentDoc`** — junction to ContentDocument (types: AttachedDocument, ComparisonDocument, ContractDocument, ExternalReviewDocument, SignedDocument)
- **`ContractDocVersionSection`** — rendered sections in a version
- **`DocumentGenerationProcess`** — server-side generation request/response record
- Lifecycle: Create → Generate → Checkout → Review → CheckIn → Sign → Activate

### 3. E-Signature
- **`DocumentEnvelope`** — container for documents sent for e-signature
- **`ESignatureConfig`** — DocuSign integration settings (anchor strings, signer roles, callout timeouts)
- **`ESignatureEnvelopeConfig`** — notification settings (expiry, reminder periods) per target object
- **`UserEsignVendorIdentifier`** — maps Salesforce users to DocuSign user IDs
- Only DocuSign is supported as the vendor in the current release

### 4. Clause Library
- **`DocumentClauseSet`** — groups multiple language/alternate variations of a clause
- **`DocumentClause`** — the clause content (HTML, Rich Text or Non-Formatted); status: Draft → Review_Requested → In_Approval → Active → Archived
- **`ClauseCatgConfiguration`** — clause category config (Contract Clause Category / Disclosure Category)
- Requires `ClauseManagement` platform license

### 5. Contract Type Configuration
- **`ContractType`** — groups contracts with similar lifecycle, templates, and permissions
- **`ContractTypeConfig`** — key/value settings controlling DocuSign behavior, auto-generation, redline tracking, import status, etc.
- Deployed as Metadata API type `ContractType` (.contractType files)

### 6. Obligation Management
- **`Obligation`** — contractual commitments (payment dates, renewal terms, compliance tasks)
- Linked to `Contract` via `ReferenceObjectId`
- Status: Compliant / Non Compliant / At Risk / None; State: Active / Expired / Inactive / On Hold
- Requires `ObligationManagement` permission license

### 7. AI Contract Extraction
- **`ContractExtractionResult`** — holds AI-extracted fields and clauses from uploaded PDFs before contract creation
- **`ContextUseCaseMapping`** — configures the AI extraction context mappings (Hydration / Persistence)
- `searchContractDocument` invocable action enables semantic search within contract documents
- `ExtractionMode`: SingleExtraction or BulkExtraction (v67.0)

### 8. External Document Storage
- **`ExternalDocStorageConfig`** — routes documents to Microsoft OneDrive
- `DocumentAuthoredContent` — tracks marked clauses/sections within contract documents

---

## Key Design Principles

- **Contract-centric**: Everything links back to the standard `Contract` object, not a custom object
- **Template-driven**: All document generation flows through `DocumentTemplate` → `DocumentTemplateSection` → `DocumentGenerationProcess`
- **Version-controlled**: `ContractDocumentVersion` is the unit of change; multiple versions per contract are supported
- **External-storage ready**: OneDrive integration is native via `ExternalDocStorageConfig` + Named Credential
- **Token mapping**: Documents are populated with Salesforce data via OmniDataTransform bundles or Context Service definitions — no hardcoded data

---

## Relationship to E&U / Vlocity CLM

Vlocity-based E&U implementations that used Vlocity CLM objects (`vlocity_cmt__CLMContract__c`, `vlocity_cmt__DocumentTemplate__c`, `vlocity_cmt__VlocityDocuSignTemplate__c`) must be migrated to Salesforce Contracts when upgrading to modern package versions. The two systems are not compatible and cannot be used simultaneously on the same contract record.
