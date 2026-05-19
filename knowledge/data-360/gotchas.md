# Data 360 — Gotchas

## Ingestion

**1. Primary key collisions silently drop records**
If two records in a bulk upload share the same primary key, only the last one processed is retained. No error is thrown. Always deduplicate source data before upload and validate row counts against what Data 360 accepted.

**2. Schema changes break existing Data Streams**
Adding a new field to a Salesforce Connector Data Stream requires editing the stream and re-mapping. Existing data is not backfilled for the new field — only records ingested after the schema change will have values. Plan schema evolution before initial load.

**3. Incremental sync misses parent record changes**
The Salesforce Connector detects changes via `LastModifiedDate` on the mapped object. A Contact whose Account is re-assigned does not get a new `LastModifiedDate` on the Contact record. The profile update will not arrive until something else touches the Contact. Workaround: formula field on Contact that captures `Account.LastModifiedDate`.

**4. File ingestion date format must be ISO 8601**
Dates in any other format (MM/DD/YYYY, epoch milliseconds without explicit type mapping) will fail silently or land as strings, breaking date-based segment criteria. Enforce ISO 8601 at the source ETL layer.

**5. Bulk file size limit is 150 MB per file — plan splits accordingly**
Each file in a bulk job is capped at 150 MB, with a maximum of 100 files per job. Split large datasets across multiple files. Jobs older than 7 days are automatically deleted by the platform.
> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_get_started.htm

**6. Streaming ingestion is NOT real-time — ~3 minute latency**
Despite being called "streaming," the Ingestion API processes data asynchronously with approximately 3 minutes of latency before records appear in the DLO. Design any real-time use case to tolerate this lag. For sub-second event processing, use Salesforce Platform Events upstream and feed Data 360 on a micro-batch cadence.
> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_get_started.htm

**7. Null handling differs between streaming and batch**
Streaming API: null fields are dropped from the payload (the existing value is preserved). Bulk API: null fields overwrite the existing value with null. This asymmetry causes data loss if you use bulk uploads to "update" records and don't include all fields.

---

## Identity Resolution

**8. Identity resolution is not incremental by default**
A full identity resolution run re-processes all records. On large orgs (10M+ profiles) this takes hours. Schedule it during off-peak hours and do not trigger it after every small batch load.

**9. Match rules order matters — and is easy to get wrong**
Match rules are evaluated in priority order and the first match wins. A fuzzy name + zip rule placed before an exact email rule will match on weaker evidence when the email is available. Always put exact deterministic rules (email, phone, national ID) before probabilistic rules.

**10. Unified Individual IDs change after identity resolution runs**
If two previously separate Unified Individuals are merged in a subsequent run, one ID is retired and the other becomes canonical. Any external system storing `UnifiedRecordId` as a key must handle ID changes. Use `Individual Identity Link` to resolve source IDs to current unified IDs rather than storing unified IDs externally.

**11. Reconciliation "last write wins" can overwrite good data**
Reconciliation determines which source wins for each attribute when multiple sources have conflicting values. The default is last-modified-wins, which means a stale data feed with a recent `LastModifiedDate` can overwrite accurate data. Always define explicit reconciliation rules per attribute — don't rely on defaults for name, email, or demographic fields.

---

## Segmentation

**12. Segment member counts are estimates until publish**
The count shown in the segment builder is sampled, not exact. The true count is only known after the segment is published to an activation target. Do not promise marketing exact counts until after the first publish run.

**13. Real-time segments only evaluate streaming event data**
A real-time segment can only use DMOs that receive data via streaming ingestion. Batch-ingested DMOs (Salesforce Connector, file upload) are not evaluated in real time even if the segment is configured as "real-time." Mixing batch and streaming DMO criteria forces a batch evaluation cadence.

**14. Calculated Insights used in segments must refresh first**
If a segment criterion references a Calculated Insight, and the Calculated Insight hasn't refreshed yet, the segment uses stale values. Set Calculated Insight refresh to complete at least 30 minutes before the segment publish schedule.

**15. Consent filtering is opt-in, not automatic**
Segments do not automatically exclude opted-out individuals. You must explicitly add a `Contact Point Type Consent` filter to every segment that will activate to a communication channel. Missing this filter will send to opted-out individuals — a compliance violation.

---

## Activation

**16. Activation to Marketing Cloud uses a dedicated Data Extension — don't reuse existing DEs**
Data 360 activation manages the lifecycle of its target Data Extension (create, refresh, delete members). If you point an activation at an existing populated DE, Data 360 will overwrite it. Always create a dedicated DE for Data 360 activations.

**17. Subscriber Key mapping must be stable**
If you map `UnifiedRecordId` as the Subscriber Key and that ID changes after an identity resolution merge, the subscriber in Marketing Cloud becomes orphaned. Use a stable source system ID (CRM Contact ID or a hash of a canonical email) as the Subscriber Key.

**18. Activation failures don't block the segment**
If an activation fails (e.g., Marketing Cloud API timeout), Data 360 retries but continues processing other activations. Monitor the Activation History tab regularly — a failed activation silently falls behind without alerting anyone unless you set up monitoring.

---

## Data Graphs and Agentforce

**19. Data Graph changes require re-publishing**
Modifying a Data Graph (adding/removing fields, changing relationships) requires re-publishing the graph before Agentforce sees the changes. There is no live update. Coordinate Data Graph changes with the Agentforce team to avoid breaking agent behaviour during the re-publish window.

**20. Data Graph queries time out under high concurrency**
At peak load (large contact centre), concurrent Data Graph queries for every active interaction can exceed latency budgets. Pre-aggregate commonly needed metrics as Calculated Insights rather than computing them at query time via Data Graph traversal.

---

## Platform and Limits

**21. Data Streams per org has a default cap — request increases early**
An org approaching the default Data Streams limit needs a support case for an increase, which can take days. Audit Data Stream count during discovery if the customer has many CRM objects and external sources.

**22. Calculated Insight SQL cannot reference other Calculated Insights**
You cannot use a Calculated Insight value as input to another Calculated Insight's SQL. Compute composite metrics by joining the underlying DMOs in a single query, or use a multi-step CTE approach within one Calculated Insight definition.

**23. Data Cloud and Salesforce CRM share governor limits — carefully**
Data Actions that trigger Flow run in the Salesforce org's governor limit context. A Data Action triggering a Flow that performs SOQL queries counts against the org's daily SOQL limit. On high-volume Data Actions (millions of profile updates per day), this can exhaust org limits. Use Platform Events + async processing instead of synchronous Flow.

**24. Ingestion API rate limit is only 20 requests/hour for bulk**
The bulk Ingestion API has a low request rate limit (20/hour, 5 concurrent jobs). For large initial loads, batch data into the maximum 100-file, 150MB-per-file job structure and submit jobs sequentially. Do not design pipelines that require more than 20 job submissions per hour.
> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_get_started.htm
