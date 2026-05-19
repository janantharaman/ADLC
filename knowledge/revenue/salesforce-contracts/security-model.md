---
source: Salesforce Contracts Developer Guide (v67.0 Summer '26, PDF confirmed 2026-05-12)
cloud: Salesforce Contracts (CLM)
section: security-model
last-updated: 2026-05-12
---

# Salesforce Contracts (CLM) — Security Model

## License Architecture

### Platform Licenses (Org-Level)

| License | Objects / Features Unlocked |
|---|---|
| **DocGen platform license** | `DocumentGenerationProcess`, `DocumentGenerationSetting`, `DocGenerationBatchProcess`, `DocumentTemplateSection`, `DocumentAuthoredContent`, `ContractDocumentReview` |
| **ClauseManagement platform license** | `DocumentClause`, `DocumentClauseSet` |
| **ClauseManagementAddOn** | `ClauseCatgConfiguration` |
| **ObligationManagement permission license** | `Obligation` |

### User Permission Sets

| Permission Set / PSL | Who Needs It |
|---|---|
| **ClauseManagement user PSL** | Anyone creating or managing clauses in the clause library |
| **DocGen Designer** or **DocGen Designer PSL** | Template designers who create/edit document templates |
| **DocGen runtime PSL** | Users generating documents (running generation on contracts) |
| **DocGen runtime CC PSL** | Customer Community users generating documents |
| **Contracts AI User** | Users invoking `searchContractDocument` invocable action (AI semantic search) |

### Checking Permissions Programmatically

Use the `industries_docgen.DocGenPermsAndAccessChecksService` class:

```apex
// Check if user is a DocGen designer
Boolean isDesigner = industries_docgen.DocGenPermsAndAccessChecksService.isDesigner(
    UserInfo.getOrganizationId(),
    UserInfo.getUserId(),
    'DocGenDesigner'
);

// Check if user has DocGen runtime permissions
Boolean isRuntime = industries_docgen.DocGenPermsAndAccessChecksService.isRuntimeUser(
    UserInfo.getOrganizationId(),
    UserInfo.getUserId(),
    'DocGenRuntimeUser'
);

// Check if user is a Customer Community runtime user
Boolean isRuntimeCC = industries_docgen.DocGenPermsAndAccessChecksService.isRuntimeCCUser(
    UserInfo.getOrganizationId(),
    UserInfo.getUserId(),
    'DocGenRuntimeCCUser'
);

// Check org-level DocGen permission
Boolean hasOrgPerm = industries_docgen.DocGenPermsAndAccessChecksService.hasDocGenOrgPerm(
    UserInfo.getOrganizationId(),
    'SomeOrgPermission'
);
```

---

## OWD and Sharing Model

| Object | Recommended OWD | Notes |
|---|---|---|
| `ContractDocumentVersion` | Private | Contains contract content; restrict to contract owners and approvers |
| `DocumentEnvelope` | Private | E-signature data; restrict to parties and contract team |
| `Obligation` | Private | Commitments tracking; restrict to legal and compliance |
| `ContractExtractionResult` | Private | Temporary AI extraction data; purge after review |
| `DocumentClause` | Public Read Only | Clause library is shared content |
| `DocumentTemplate` | Public Read Only | Templates are org-wide configuration |
| `DocumentClauseSet` | Public Read Only | Clause library organization |
| `ContractType` | Public Read Only | Configuration object |
| `ESignatureConfig` | Private | Contains credential-adjacent settings |

---

## Named Credentials — Mandatory

All external integrations must use Named Credentials:

| Integration | Purpose | Object |
|---|---|---|
| **DocuSign** | E-signature envelope callouts | Referenced in `ESignatureConfig.ConfigType = CalloutNamedCredential` |
| **Microsoft OneDrive** | External document storage | Referenced in `ExternalDocStorageConfig.NamedCredentialId` |
| **Guest user DocGen** | Generate docs as guest users | `DocumentGenerationSetting.GuestAccessNamedCredential` |

---

## DocuSign Integration Security

### Current Requirements
- DocuSign integration uses the `ESignatureConfig` object for all configuration
- `CalloutNamedCredential` config type stores the Named Credential name for callout authentication
- `eSignVendorAccountId` config type stores the DocuSign account ID
- Signer roles are configured via `ESignatureConfig.ConfigType = SignerRoles`

### Envelope Status Polling
DocuSign envelope status polling is handled by a scheduled Apex class that must be scheduled 4 times per hour:

```apex
ind_docgen_api.EnvelopeStatusScheduler envelopeScheduler =
    new ind_docgen_api.EnvelopeStatusScheduler();
System.schedule('Update Docusign Envelope Job 1', '0 0 * * * ?', envelopeScheduler);
System.schedule('Update Docusign Envelope Job 2', '0 15 * * * ?', envelopeScheduler);
System.schedule('Update Docusign Envelope Job 3', '0 30 * * * ?', envelopeScheduler);
System.schedule('Update Docusign Envelope Job 4', '0 45 * * * ?', envelopeScheduler);
```

---

## External Document Storage Security

Microsoft OneDrive integration via `ExternalDocStorageConfig`:
- Named Credential must be configured for the OneDrive account
- Documents are stored at the path defined in `DocumentPath`
- Access is controlled by the Named Credential — the underlying OAuth token in the Named Credential defines which OneDrive account is accessed
- Record type filtering is supported to route different contract types to different storage paths

---

## Custom Template Filtering Security

To restrict which document templates are available to users, implement `ind_docgen_api.OpenInterface` or `industries_clm.OpenInterface`:

```apex
global class MyTemplateFilter implements industries_clm.OpenInterface {
    public Boolean invokeMethod(
        String methodName,
        Map<String, Object> request,
        Map<String, Object> outMap
    ) {
        if (methodName == 'getDocumentTemplateList') {
            String contractId = (String) request.get('contractId');
            // Custom filtering logic based on user, contract, or business rules
            List<DocumentTemplate> templates = [
                SELECT Id, Name, Type, IsActive, VersionNumber
                FROM DocumentTemplate
                WHERE IsActive = true
                ORDER BY Name
            ];
            outMap.put('documentTemplateList', templates);
        }
        return true;
    }
}
```

Register the class in `ContractTypeConfig`:
- `ConfigType`: `DocumentTemplateFilterClass`
- `ConfigValue`: Apex class name

---

## Document Generation Rate Limits

From `DocumentGenerationSetting`:

| Setting | Default |
|---|---|
| `InProgDocGenRqstTmot` | 6 hours (InProgress records time out after this) |
| `BatchDocGnrnPctLimitPerHour` | Configurable percentage of hourly limit for batch |

**Org-level server-side document generation limits** (from security model knowledge):
- 1,000 requests per hour per org
- 24,000 requests per day per org

---

## Customer Community (External User) Access

Customer Community users can access contract documents via the CC-specific API endpoints:
- `GET /connect/clm/cc/contract/{contractId}/contract-document-version` — latest document version
- `GET /connect/clm/cc/documentRecipient` — e-signature recipient status
- `GET /connect/clm/cc/external-document` — external document for review

Security model for CC:
- CC users must have the `DocGen runtime CC PSL`
- Access is granted only for the latest, relevant contract document version
- Sharing is controlled by the Account and Contract status of the CC user
- `ContractDocVerContentDoc.DocumentType = ExternalReviewDocument` tracks documents shared externally

---

## Common Security Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Hardcoded DocuSign credentials in Apex or flow | Credential exposure in metadata | Use Named Credentials via `ESignatureConfig` |
| Public OWD on `ContractDocumentVersion` | Contract content visible to all users | Set OWD Private; use sharing rules for contract team |
| Not scheduling `EnvelopeStatusScheduler` | DocuSign envelope statuses go stale; signatures not reflected | Schedule all 4 jobs at 0, 15, 30, 45 minutes |
| Using `DocumentTemplateFilterClass` without testing | Wrong templates appear for wrong contract types | Test filter class against all contract types and user profiles |
| Not purging `ContractExtractionResult` | PII in extracted contract data accumulates | Delete after review is complete or after max 30 days |
| Exposing CLM REST endpoints without OAuth | Unauthenticated access to contract operations | Authenticate all callers via Connected App + OAuth 2.0 |
| Assigning DocGen Designer PSL to all users | Users can modify production templates | Restrict designer PSL to designated template authors only |
