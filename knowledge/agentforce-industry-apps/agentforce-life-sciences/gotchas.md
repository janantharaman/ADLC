---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: gotchas
last-updated: 2026-05-11
---

# Life Sciences Cloud — Gotchas and Known Issues

## G-1: LSC Namespace Varies by Org Vintage
**Impact:** High

Older LSC orgs use the `HealthCloudGA__` namespace for some LSC objects (because LSC was originally part of Health Cloud). Newer orgs use standard objects with no namespace or `lsc__` for some extensions. Some orgs have a mix. Before writing any SOQL or Apex, always verify:

```apex
SELECT NamespacePrefix, Name FROM ApexClass LIMIT 10
// Or query InstalledSubscriberPackage via Tooling API
```

Hard-coding the wrong namespace prefix causes `INVALID_TYPE` errors on every deployment that touch LSC objects.

---

## G-2: Clinical Data Model Requires Org Preference
**Impact:** High

The FHIR R4-aligned Clinical Data Model objects (`AllergyIntolerance`, `ClinicalEncounter`, `DiagnosticSummary`, `HealthCondition`, `MedicationRequest`, `PatientImmunization`, etc.) are **not available by default**. They require "FHIR R4 Support Settings" → "FHIR-Aligned Clinical Data Model" org preference to be enabled in Setup.

**Before** enabling this org pref, confirm:
1. The customer has Life Sciences Cloud license (not just Health Cloud or plain Sales Cloud)
2. A migration plan exists for any existing clinical objects that may conflict
3. Fields on standard objects (ContactPointPhone, Account.IsActive) added by the pref are understood

After enabling: the pref **cannot be rolled back** in production without Salesforce Support intervention.

---

## G-3: Community Users Need Separate Permission Set for Clinical Data
**Impact:** High

For LSC sites built on Experience Cloud: community users cannot access Clinical Data Model objects by default even if the FHIR R4 org pref is enabled. They need the **"FHIR R4 for Experience Cloud Sites"** permission set explicitly assigned.

Without this permission set, any page or LWC that queries `ClinicalEncounter`, `AllergyIntolerance`, etc. for an authenticated community user returns zero results with no error — causing silent data access failures that are hard to debug.

---

## G-4: Multi-Step Scheduling Requires Asset Scheduler Add-On License
**Impact:** High

Advanced Therapy Management's Multi-Step Scheduling uses Salesforce Scheduler with assets. For **each asset assigned to a service territory**, the customer must purchase an **Asset Scheduler Add-On license**. This is separate from the base Salesforce Scheduler license.

If the customer has scheduled advanced therapy appointments and the Asset Scheduler Add-On is missing, Scheduler will fail at the asset availability step with a license error — not a clear configuration error.

Also required: Multi-Step Scheduling permission set must be assigned to users managing advanced therapy scheduling.

---

## G-5: CodeSet 15-Reference Limit for CodeableConcept
**Impact:** Medium

The FHIR `CodeableConcept` resource supports zero-to-many `coding` references. Salesforce flattens this to exactly 15 zero-to-one `CodeSet` references on `CodeSetBundle` (`CodeSet1Id` through `CodeSet15Id`).

If an incoming FHIR message has more than 15 coding references for a concept, the excess references are silently dropped during import. The integration developer must handle this truncation explicitly in the transformation layer.

---

## G-6: Period / Quantity / Range / Ratio Flattening in FHIR Mapping
**Impact:** Medium

FHIR data types `Period`, `Quantity`, `Range`, and `Ratio` don't have native equivalents in Salesforce. They are flattened:
- **Period** → two date fields (start/end): e.g., `AllergyIntolerance.OnsetStartDateTime` + `AllergyIntolerance.OnsetEndDateTime`
- **Quantity** → numeric + unit field
- **Range** → upper limit + lower limit + unit (reference to UnitofMeasure object)
- **Ratio** → numerator + denominator + unit

Integration transforms must account for this flattening. Reconstructing FHIR resources from Salesforce data requires explicit de-flattening logic.

---

## G-7: ProviderSampleLimitTemplate Is Immutable After Cloning
**Impact:** Medium

The `ProviderSampleLimitTemplate` metadata type has an `IsCloned` boolean field. Once a template is cloned, `IsCloned = true` and the cloned template's configuration is locked in certain contexts. The `isCloned` field cannot be set back to `false` via metadata deployment — it is set by the system when the clone operation occurs.

---

## G-8: Territory Alignment Jobs Must Complete Before Sharing Takes Effect
**Impact:** High

LSC's Provider and Affiliate Territory Sharing (PATS) is not instantaneous. When territory alignment rules change:
1. Alignment rules are saved
2. A background job runs to recalculate `ProviderAcctTerritoryInfo` records
3. Sharing recalculations run after job completion

Until the job completes, reps may see stale data (either too much or too little access). During UAT, always run territory alignment jobs to completion before testing data visibility. Do not test sharing with un-run alignment jobs.

---

## G-9: ActionableList Object Available Only in API v65.0+
**Impact:** Medium

`ActionableList`, `ActionableListFilterCriteria`, `BatchJob`, `BatchJobPart`, `DeviceSyncSummary`, and related objects are only available in API version 65.0 (Spring '26) and later. Any Apex, SOQL, or metadata package targeting earlier API versions will fail with `INVALID_TYPE` for these objects.

Always confirm the org's current API version before planning a deployment that uses these objects.

---

## G-10: Consent Records Must Not Be Deleted
**Impact:** High — GDPR/CCPA risk

Salesforce does NOT prevent deletion of `CommSubscriptionConsent` or `ContactPointConsent` records by default. However, deleting these records permanently destroys GDPR and CCPA audit evidence.

**Day 1 guard — add a Validation Rule on CommSubscriptionConsent:**
```
AND(ISBLANK(Id), FALSE)  // Always false — triggers on delete
// Or use an Apex trigger:
trigger PreventConsentDelete on CommSubscriptionConsent (before delete) {
    for (CommSubscriptionConsent c : Trigger.old) {
        c.addError('Consent records cannot be deleted. Set Status to OptOut instead.');
    }
}
```

---

## G-11: Provider Search API Queries Denormalized Object — Not the Master Object
**Impact:** Medium

`CareProviderSearchableField` is a denormalized search object that contains copied field data from `HealthcareProvider`, `Account`, and `ContactPointAddress`. It is maintained by the system.

**Do NOT write to `CareProviderSearchableField` directly.** Write to the source objects (`HealthcareProvider`, `Account`). The system will sync denormalized data. If you write to the search object directly, the next sync will overwrite your changes silently.

Also: `CareProviderSearchConfig` controls which fields appear in search results — configure it via metadata, not direct object manipulation.

---

## G-12: Smart Actions on Search Results Need Specific actionType Values
**Impact:** Low

`SearchResultActionConfig` (API v59.0+) supports only three `actionType` values:
- `FlowDefinition`
- `LightningWebComponent`
- `OmniScript` (API v60.0+)

Attempting to configure other action types (QuickAction, InvocableAction) in `SearchResultActionConfig` is not supported and will error at activation.

---

## G-13: IndustriesSettings Fields Are Feature Flags — Irreversible in Some Cases
**Impact:** High

`IndustriesSettings` controls 30+ feature toggles for Life Sciences Cloud. Some of these toggles activate data models or governance features that are **difficult or impossible to reverse** in production:

| Setting | Reversibility |
|---|---|
| `enableAccountBasedSharing` | Partially reversible — disabling may orphan sharing records |
| `enableLifeSciencesClinialTrailManagement` | Not confirmed reversible; creates clinical trial objects in org |
| `enableAdverseEvents` | Not confirmed reversible; activates adverse event data model |
| `enableLifeSciencesConsent` | Do NOT disable after consent records exist |
| `enableCPBestConTimeSharing` | Generally reversible |

Always test `IndustriesSettings` changes in sandbox before enabling in production. Treat irreversible settings as architectural decisions requiring stakeholder sign-off.

---

## G-14: Work Type Lead Time API Is Advanced Therapy Management Only
**Impact:** Low

The Work Type Lead Time Business API (`POST /connect/health/advanced-therapy-management/work-type-lead-time`) is specific to Advanced Therapy Management. It is NOT a general-purpose work type API. Attempting to use it for non-ATM work types (standard FSL work orders) will return empty results or errors.

For standard FSL lead time calculations, use the FSL platform API directly, not this endpoint.

---

## G-15: DigitalSignatureRequest Is Reserved for Future Use
**Impact:** Low

As of API v66.0 (Spring '26), `DigitalSignatureRequest` is documented as "Reserved for future use." Do not build integrations or flows that depend on this object. Use `DigitalVerificationSetup` and `DigitalVerification` for all current e-signature workflows.

---

## G-16: Book Slot Chain API Processes Both Published and Unpublished Slots
**Impact:** Medium

The Book Slot Chain API (`POST /connect/health/advanced-therapy-management/book-slot-chain`) accepts both published and unpublished appointment slots as input. **Only published slots trigger the Salesforce Scheduler API to book them.** Unpublished slots are recorded without triggering Scheduler.

This distinction is not obvious from the API name. If a developer passes only unpublished slots expecting Scheduler to book them, the appointments will be recorded but NOT actually scheduled in the Scheduler system.

---

## G-17: Merge Customer Account API — All-or-Nothing vs. Partial
**Impact:** Medium

Two versions of the Merge Customer Account Business API exist with different failure behavior:

| Endpoint | Behavior on Error |
|---|---|
| `POST /connect/life-sciences/commercial/customers/actions/merge` | If ANY merge fails, the ENTIRE operation is cancelled (all-or-nothing) |
| `POST /connect/life-sciences/commercial/customers/actions/merge-with-status` | Processes all valid requests; does not fail the entire operation if one request is invalid |

Choosing the wrong endpoint for bulk merge operations can result in silent partial failures (first endpoint) or unexpected successes mixed with failures (second endpoint). Use the `-with-status` endpoint when merging multiple accounts to get per-request outcomes.

---

## G-18: UIObjectRelationConfig queryText Uses Custom Graph Traversal Syntax
**Impact:** Low

The `UIObjectRelationConfig` metadata type uses a JSON-based `queryText` format with `startNode`, `traversalNodes`, and `fieldNode` structure — not standard SOQL. This syntax is specific to the Object Relation UI component.

Example of the traversal syntax (from PDF p.1849):
```json
{
  "startNode": {"initialObject": "RelatedObject"},
  "traversalNodes": [
    {
      "destinationObjectEnumOrId": "Account",
      "fieldEnumOrId": "ParentId",
      "traversalDirection": "parent"
    }
  ],
  "fieldNode": {"fieldEnumOrId": "Name"}
}
```

Attempting to use SOQL or standard relationship syntax in `queryText` will fail silently or throw parsing errors.
