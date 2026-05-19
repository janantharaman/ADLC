---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: gotchas
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — Gotchas

## G-1: Salesforce Contracts ≠ Vlocity CLM

Salesforce Contracts (`industries_clm`, `industries_docgen` namespaces) is the **native, next-generation CLM platform**. It is completely different from legacy Vlocity CLM which used `vlocity_cmt__DocumentTemplate__c`, `vlocity_cmt__DocumentClause__c`, and `vlocity_cmt__VlocityDocuSignTemplate__c`.

**They cannot coexist on the same contract record.** If an org has been using Vlocity CLM and upgrades to Salesforce Contracts, a migration is required. Do not confuse object names between the two systems.

---

## G-2: DocuSign Envelope Status Requires Scheduled Polling — Must Have 4 Jobs

DocuSign envelope status is not pushed to Salesforce in real time. It requires the `ind_docgen_api.EnvelopeStatusScheduler` to be scheduled 4 times per hour (at 0, 15, 30, 45 minutes). If fewer than 4 jobs are scheduled, envelope status updates are delayed.

**Fix:** Always schedule all 4 jobs. Use a scheduled Apex or CRON trigger to recreate them if they are removed.

---

## G-3: ContractDocumentVersion Key Prefix Is `0qt` — Not a Standard Object Prefix

The `ContractDocumentVersion` object key prefix is `0qt`. When building automation or writing code that checks object types from record IDs, include this prefix in your mappings.

---

## G-4: Only One DocGen Batch Can Be `InProgress` at a Time

`DocGenerationBatchProcess` enforces that only one batch can be `InProgress` at any given time. If a new batch is created when one is already running, the existing batch must be `Paused` or `Canceled` first. Running batch generation requests for a time-sensitive use case (e.g., on-demand contract generation) without anticipating this limit causes batch requests to queue indefinitely.

**Fix:** Check `DocGenerationBatchProcess.Status` before queuing batch jobs; use single-request `DocumentGenerationProcess` for on-demand generation.

---

## G-5: Server-Side DocGen Has InProgress Timeout — Default 6 Hours

`DocumentGenerationSetting.InProgDocGenRqstTmot` defaults to 6 hours. After this timeout, any `DocumentGenerationProcess` still in `InProgress` status is automatically set to `Failure`. For documents that legitimately take a long time (large DOCX with hundreds of sections), increase this setting.

**Fix:** Enable `IsInProgRqstTmotEnab` and increase `InProgDocGenRqstTmot` for large document scenarios.

---

## G-6: ContractExtractionResult Clause Content Has a 131K Character Limit

`ContractExtractionResult.ExtractedClauseContent` is a textarea limited to ~131K characters. For contracts with very long clause content, the overflow is stored in a linked ContentDocument via `ExtractedClauseContentDocId`. If your code reads `ExtractedClauseContent` and assumes all clause text is there, it will miss content for long contracts.

**Fix:** Always check `ExtractedClauseCount` and compare with the actual content length; if overflow, fetch from `ExtractedClauseContentDocId` ContentDocument.

---

## G-7: `searchContractDocument` Invocable Action Requires `Contracts AI User` PSL

The AI semantic search action (`searchContractDocument`) requires the `Contracts AI User` permission set, not just the standard DocGen license. Users missing this PSL get an authorization error when the action is invoked.

---

## G-8: DocumentTemplate.UniqueName Is Required for Org-to-Org Migration

`DocumentTemplate.UniqueName` is the field used by the Metadata API and managed packages to identify templates across orgs. If `UniqueName` is blank (possible on manually created templates), retrieving and deploying the template between orgs will fail or create duplicates.

**Fix:** Always populate `UniqueName` when creating DocumentTemplates. Use `DocumentTemplateConfig` shadow object to verify templates are properly registered for migration.

---

## G-9: Context Service Token Mapping Requires ContextDefinition + ContextMapping Pair

When `TokenMappingMethodType = ContextService`, both `ContextDefinitionName` AND `ContextMappingName` must be set. Setting only one results in a runtime error during document generation. Additionally, the `ContextDefinition` and `ContextMapping` components must exist in the org — they are not included in the `DocumentTemplate` metadata type.

**Fix:** Always deploy `ContextDefinition` and `ContextMapping` components before deploying `DocumentTemplate` components that reference them.

---

## G-10: MergePDF Is Limited to 10 PDFs

`DocumentGenerationProcess.Type = MergePDF` and `PdfDocIdentifiersList` accept a maximum of 10 PDF ContentVersionIds. Attempting to merge more than 10 PDFs in a single request fails silently or throws an exception.

**Fix:** For merges >10 PDFs, chain multiple MergePDF requests or redesign the template structure to reduce the number of merged documents.

---

## G-11: ESignatureConfig `CalloutNamedCredential` Must Be Set Before Any Envelope Send

All DocuSign API calls from Salesforce Contracts go through the Named Credential configured in `ESignatureConfig` with `ConfigType = CalloutNamedCredential`. If this record is missing or the `ConfigValue` references a non-existent Named Credential, every envelope send attempt fails with a callout exception — not a user-friendly error.

**Fix:** Validate `ESignatureConfig` records exist and the Named Credential is valid before deploying CLM to a new org.

---

## G-12: ContractType `isDefault` Can Only Be True on One Record

Only one `ContractType` record can have `IsDefault = true` in an org. If you deploy a package that includes a `ContractType` with `IsDefault = true` when another default already exists, the deployment fails or silently overrides the existing default.

**Fix:** Always set `IsDefault = false` in DataPack/Metadata deployments unless you explicitly intend to change the default.

---

## G-13: ExternalDocStorageConfig Routing Depends on RecordType Match

`ExternalDocStorageConfig` uses `RecordTypeId` to filter which contract records route to OneDrive storage. If the target contract record type does not match the configured record type, documents are stored in Salesforce (Files) instead of OneDrive — with no error. Teams often discover this only when looking for documents in OneDrive and they aren't there.

**Fix:** Test ExternalDocStorageConfig routing for all contract record types before go-live.

---

## G-14: `ObligationSetting` UsageType Only Available in Tooling API

The `ObligationSetting` value for `ContractTypeConfig.UsageType` is only available when querying via the Tooling API, not the standard API. Standard API queries on `ContractTypeConfig` for obligation-related configs will not return this `UsageType` value correctly.

---

## G-15: ClientSide DocGen Requires Browser Session — Cannot Be Used in Async/Batch

`DocumentGenerationMechanism = ClientSide` requires a browser session because the document is rendered client-side (typically in the user's browser using JavaScript). Any attempt to trigger ClientSide document generation from Apex, Integration Procedure, or a scheduled job will fail.

**Fix:** Always use `ServerSide` document generation for programmatic/automated generation. Reserve `ClientSide` for user-initiated UI actions only.

---

## G-16: DocumentAuthoredContent.IsLibraryAdditionRequested Does Not Auto-Create Clause

Setting `IsLibraryAdditionRequested = true` on a `DocumentAuthoredContent` record does NOT automatically create a `DocumentClause`. It only flags the request. Custom automation (Flow or Apex) must be built to read this flag and create the clause library entry.

---

## G-17: DataSync `partialCommit = false` Means All-or-Nothing

`POST /connect/content-link/data-sync` with `partialCommit = false` (the default) rolls back ALL token updates if any single token fails to save. If one field has a validation error, no changes are committed. This surprises teams that assume at least some changes will go through.

**Fix:** Use `partialCommit = true` in `data-sync` calls when you want successful records committed even if some fail, and handle the partial error response.
