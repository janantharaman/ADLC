---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf
cloud: Automotive Cloud
section: gotchas
---

# Automotive Cloud — Gotchas and Common Misconfigurations

## Metadata Deployment

### IndustriesAutomotiveSettings Must Be Enabled Before Object Deployment
Deploying Automotive Cloud custom objects or metadata before enabling `IndustriesAutomotiveSettings` causes cryptic errors. Always deploy the settings metadata first in a separate step.

### ObjectHierarchyRelationship Ordering Matters
`ObjectHierarchyRelationship` metadata must be deployed after the objects it references. If parent objects are not deployed first, the deployment fails with a generic "Object not found" error.

### TelemetryDefinition Versioning
`TelemetryDefinitionVersion` records are immutable once activated. To modify a telemetry schema, create a new `TelemetryDefinitionVersion` — do not edit the existing one. Old versions remain active until explicitly superseded.

### ActionableEventOrchDef Circular References
Orchestration definitions that reference each other (even indirectly) will cause the event orchestration engine to loop silently. Always draw the event flow graph before deploying.

## Data Model

### Vehicle vs Asset
`Vehicle` is an Automotive Cloud custom object holding vehicle identity (VIN, make, model). `Asset` is the standard Salesforce object holding ownership and value. They are related but distinct:
- `Vehicle` → stores the physical vehicle identity
- `Asset` → stores the owned item (vehicle) in a customer's possession

Confusing the two leads to incorrect reporting and broken sharing rules. Always query both when investigating "where is the vehicle data?"

### VehicleDefinition Is a Catalog, Not a Vehicle
`VehicleDefinition` is a template (like a product catalog entry). Never create one per vehicle — one `VehicleDefinition` can have thousands of `Vehicle` children.

### FinancialAccount Is Shared with Financial Services Cloud
The `FinancialAccount` object exists in both Financial Services Cloud and Automotive Cloud. If both are installed in the same org, namespace conflicts are possible. Verify which namespace is in use before writing SOQL.

### LeadLineItem Requires Active Lead
`LeadLineItem` records cannot be created against a converted Lead. Automation that fires on Lead conversion and tries to clone `LeadLineItem` records to Opportunity will fail silently if the trigger condition is wrong.

## Integration

### DMS Integration Data Mapping
Dealer Management Systems (DMS) use proprietary stock number and vehicle ID schemes. Never use DMS IDs as Salesforce record IDs — always create an `ExternalId__c` field on `Vehicle` and `SellerProduct` and use upsert with external ID to avoid duplicates on re-sync.

### Orchestration Inbound Events — No Retry Built In
The Orchestration Inbound Events REST API does not have built-in retry on failure. If the org is at governor limit or the orchestration definition is misconfigured, the event is silently dropped. Implement an idempotency key on `ActionableOrchSourceEvent` and check for duplicates at the receiver.

### MuleSoft Direct Assets — Customisation Caveats
MuleSoft Direct pre-built assets for Automotive Cloud are starting points, not production-ready connectors. They do not handle partial failures, bulk operations, or field-level security. Always test at volume before go-live.

### Telemetry Data Volume
Connected vehicle telemetry can generate millions of events per day. Never process telemetry events synchronously in a trigger — always use Platform Events or the Orchestration Inbound Events API and process asynchronously via Queueable or Batch Apex. Monitor `DailyApiRequests` and `HourlyTimeBasedWorkflow` limits.

## Licensing

### Per-Object License Checks
Automotive Cloud features are license-gated per object type. Attempting to read `TelemetryDefinition` or `Fleet` without the correct license returns a `FIELD_INTEGRITY_EXCEPTION` rather than a permission error, making it hard to diagnose.

### Field Service License Required for Visit Objects
`Visit`, `GenericVisitTask`, `ServiceTerritory`, and `ServiceResourceSkill` require the **Salesforce Field Service** license, not just Automotive Cloud. Implementations that include service management need both licenses.

### Financial Services Cloud Overlap
If the customer also licenses Financial Services Cloud, the `FinancialAccount` object hierarchy is shared. Implementing both clouds requires careful namespace and record type planning to avoid collision.

## Field-Level Gotchas from the Official API

### OdometerState vs OdometerStatus
`OdometerStatus` is being deprecated — use `OdometerState`. Do not build automation or reports on `OdometerStatus`.

### DrivetrainSystem vs DrivetrainType
`DrivetrainType` is being deprecated — use `DrivetrainSystem`. Same pattern applies to `DoorStyle`/`DoorStyleType`, `FuelSource`/`FuelType`, `TransmissionSystem`/`TransmissionType`.

### Auto-Populated Fields on Vehicle
Several Vehicle fields are auto-populated from the related VehicleDefinition and cannot be directly set:
- `Classification`, `DrivetrainSystem`, `EngineName`, `FuelSource`, `MakeName`, `ModelName`, `ModelYear`, `TrimLevel`
Attempting to set these via API will fail silently or be overwritten.

### WarrantyLifecycleManagement Required for Claims
`Claim`, `ClaimCoverage`, `ClaimCoveragePaymentDetail`, `ClaimItem` — all require **both** `enableAutomotiveCloud` AND `enableWarrantyLifecycleManagement` (or equivalent) to be enabled. Deploying claim objects to an org without both settings active will return `FIELD_INTEGRITY_EXCEPTION`.

### FinancialAccount Requires Vehicle and Asset Finance
`FinancialAccount` and its child objects require `Automotive and Vehicle and Asset Finance must be enabled` (per Special Access Rules in the API docs). This is a separate feature toggle from base Automotive Cloud.

### enableAutomotiveCloud Must Be Enabled Before All Others
`IndustriesAutomotiveSettings.enableAutomotiveCloud` must be `true` before any other automotive setting. Enabling child features first causes deployment errors.

## Performance

### VehicleSearchableField — Index Maintenance
`VehicleSearchableField` and `VehDefSearchableField` maintain search indexes. Bulk-loading `Vehicle` or `VehicleDefinition` records bypasses the index update trigger. After bulk loads, run the "Rebuild Vehicle Search Index" batch job or criteria-based search will return stale results.

### Appraisal Cascade Deletes
`Appraisal` → `AppraisalItem` → `AppraisalItemAddOn` is a master-detail chain. Deleting an `Appraisal` cascades and deletes all children. Ensure no downstream processes hold references before bulk deleting appraisals.

### Codeset Relationships — No Circular Hierarchies
`CodesetRelationship` supports hierarchical classification trees. The platform does not validate for circular references at insert time — a circular hierarchy will cause infinite loops in any recursive code walking the tree.
