# Agentforce Public Sector (Public Sector Solutions) — Gotchas

## Data Model and Objects

**1. PSS uses a managed package namespace — field API names are not obvious**
PSS objects and fields come from a managed package. Some use the `sfps__` namespace prefix; others are unmanaged platform objects. Never assume an API name from the UI label — always verify via Schema Builder or SOQL on `EntityDefinition` / `FieldDefinition` in the target org. PSS package versions can differ between customer orgs, and API names occasionally change between major releases.

**2. Individual vs Contact — don't confuse them**
PSS uses the `Individual` object (a standard Salesforce privacy/consent object) alongside `Contact`. `Individual` is linked to `Contact` via `Contact.IndividualId`. The `Individual` record holds privacy preferences and is the anchor for constituent identity. Many implementations incorrectly store constituent data on `Contact` only — this breaks privacy framework features and OmniScript identity lookups that expect `Individual`.

**3. BenefitProgram and CareProgram are NOT the same**
`BenefitProgram` is the standard PSS object for discrete benefit offerings. `CareProgram` is a Health Cloud concept for care coordination that is also available in PSS — it wraps multiple programs into a coordinated care plan. Using the wrong parent object creates reporting and eligibility tracking problems. Clarify the programme structure with the customer before modelling.

**4. Duplicate constituents are a critical data quality problem**
PSS has no automatic deduplication for `Individual` records. A constituent who submits multiple applications (different names, addresses) will create duplicate records. Implement a duplicate rule on `Individual` + `Contact` using standard Duplicate Management, and build a DataRaptor lookup in your OmniScript intake to check for existing records before creating new ones.

---

## Business Rules Engine

**5. BRE Decision Matrix rows have a hard size limit**
Decision Matrices have a practical row limit — very large matrices (hundreds of conditions) can cause performance issues in eligibility evaluations. If eligibility logic exceeds ~200 rows, split into multiple matrices invoked in sequence via Integration Procedure, rather than one giant matrix.

**6. BRE version activation is manual — no auto-activation**
When you publish a new version of a `DecisionMatrix` or `ExpressionSet`, the old version remains active until you explicitly activate the new one. There is no staging/blue-green promotion. In production, activating a new version is immediate — test thoroughly in sandbox and prepare a rollback plan (re-activate the previous version) before going live.

**7. BRE does not support date-range lookups natively**
Decision Matrices evaluate exact or range values, but date-range eligibility windows (e.g., "application received between Jan 1 and Mar 31 for this year's program") require pre-processing in the Integration Procedure before the matrix is called. Pass in a calculated flag (`IsWithinApplicationWindow__c`) rather than raw dates.

---

## OmniStudio and Portal

**8. OmniScript guest user submissions require elevated context for record creation**
The guest user profile cannot create `Individual`, `Contact`, or `ProgramEnrollment` records due to OWD = Private on these objects. Guest-facing OmniScripts must use a custom Apex controller or Integration Procedure running `without sharing` (with strict input validation) to insert records on behalf of the guest. Skipping this causes silent save failures in production.

**9. FlexCard data limits: 2,000 record cap**
FlexCards use DataRaptor Extract or SOQL to populate data. A single FlexCard card list will not return more than 2,000 records. For programme dashboards showing all cases across a large agency, aggregate in an Integration Procedure rather than returning raw records to a FlexCard.

**10. OmniStudio components are not in your deployable metadata if built via drag-and-drop UI**
OmniStudio components (OmniScripts, FlexCards, DataRaptors) created through the OmniStudio UI are stored as records, not metadata files. To deploy them, you must export the OmniScript/FlexCard JSON and re-import it in the target org — OR use the OmniStudio MCP (`mcp__omnistudio-mcp__os_create`, `mcp__omnistudio-mcp__fc_create`). Standard `sf project deploy` does NOT deploy OmniStudio components.

---

## Experience Cloud and Community

**11. Guest user record access breaks silently**
If OWD on a PSS object is set to Private and the guest user submits a form, the DML fails silently — the OmniScript shows a success message but no record is created. Always test guest user flows in a sandbox with `isGuestUser` = true and verify record creation via SOQL after submission.

**12. Community licences are a separate cost from PSS licences**
Every constituent who logs into the portal needs an Experience Cloud licence (Customer Community or Customer Community Plus). This is not included in the PSS Foundation licence. A deployment with 50,000 constituents requires 50,000 community licence seats. Model this cost during discovery.

**13. Self-registration requires Apex handler — not configurable declaratively**
The standard Experience Cloud self-registration page requires an Apex handler class. PSS provides a template, but it must be customised for your identity verification logic (e.g., matching incoming registrant to existing Individual by ID number). This is always a custom Apex task — budget for it.

---

## Government Cloud Plus

**14. Not all AppExchange packages are Government Cloud Plus compatible**
GovCloud Plus restricts which managed packages can be installed. Any third-party integration, analytics template, or utility package must be verified for GovCloud compatibility before design. Discovering an incompatibility after the design phase is approved is extremely costly.

**15. MuleSoft connectors to legacy government systems need separate ATO**
Even if PSS is deployed on Government Cloud Plus, MuleSoft connectors to on-premises legacy systems (COTS, mainframe, state databases) require their own security review and may require FedRAMP Moderate or equivalent ATO for the target system. MuleSoft's Government Cloud offering exists but is a separate procurement.

---

## Reporting and Analytics

**16. CRM Analytics for PSS is a separate licence SKU**
Pre-built CRM Analytics dashboards for PSS (case volume, benefit distribution, grant pipeline) require the "CRM Analytics for Public Sector Solutions" licence. The base PSS Foundation licence includes only standard Salesforce reports and dashboards. Confirm the customer's licence entitlements during discovery.

**17. ActionPlan completion reporting requires custom reports**
There are no standard PSS reports for Action Plan completion rates, investigator caseloads, or task SLA compliance. These are common supervisor requirements but require custom report types on `ActionPlan` and `ActionPlanItem`. Build custom report types in the design phase — do not assume they exist.

---

## Deployment

**18. Sandbox refresh does not copy BRE rule versions**
`DecisionMatrix` and `ExpressionSet` records are data, not metadata. A sandbox refresh from production will copy structure but not the Decision Matrix rows (the actual rule content). Maintain a data export + import script to repopulate BRE rules after sandbox refresh.

**19. OmniStudio components fail silently if dependency order is wrong**
When deploying OmniStudio components to a new org, the import order matters: DataRaptors first, then Integration Procedures, then OmniScripts, then FlexCards. Deploying in the wrong order causes components to reference missing dependencies — they appear deployed but fail at runtime with unhelpful errors.

**20. PSS managed package upgrades can deprecate custom objects**
Package upgrades may introduce new standard objects that replace custom objects built by earlier implementations (e.g., a custom `Inspection__c` object predating the PSS `Inspection` managed object). Always review release notes before upgrading and check for object name conflicts with your custom objects.
