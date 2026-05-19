# Data 360 — Automation Patterns

## Pattern 1: Batch Ingestion via Salesforce Connector

**Use case:** Sync Salesforce CRM objects (Accounts, Contacts, Cases, Orders) into Data 360 on a scheduled basis.

**How it works:**
1. Create a Data Stream with source = Salesforce CRM object
2. Select fields to sync (avoid syncing all fields — only what's needed for segmentation/profiling)
3. Map DLO fields to the appropriate DMO
4. Schedule: full refresh (initial load) then incremental via `LastModifiedDate` watermark

**Incremental sync gotcha:** The Salesforce Connector uses `LastModifiedDate` for incremental detection. If a parent record changes but the child record's `LastModifiedDate` does not update (e.g., a Contact's Account changes without touching the Contact), the sync will miss it. Use a formula field on the child to capture parent changes if this matters.

---

## Pattern 2: Real-Time Streaming via Pub/Sub API

**Use case:** Push behavioural events (web clicks, app events, purchase events) into Data 360 in near real-time.

**How it works:**
1. Create an Ingestion API Data Stream (type: Streaming)
2. Define the schema (JSON Schema format)
3. Publish events to the Data 360 Pub/Sub API endpoint using the Connected App credentials
4. Events land in the DLO within seconds and are available for real-time segment evaluation

**Key constraints (source-verified):**
- Max payload size: 200 KB per request
- Max 250 streaming requests/second across all endpoints combined (not per stream)
- Max 200 records deletable per streaming call — use Bulk API for larger deletes
- Events process asynchronously — data appears in DLO approximately every 3 minutes, not in seconds
- Events are immutable — no update via streaming; use Bulk Ingestion API for corrections
- Schema changes require a new Data Stream version — plan schema evolution carefully

> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_get_started.htm

---

## Pattern 3: Bulk Ingestion via File Upload / S3

**Use case:** Historical data loads, third-party data (data brokers, loyalty platforms, offline transaction data).

**How it works:**
1. Create an Ingestion API Data Stream (type: Bulk)
2. Upload CSV/JSON files via the Bulk Ingestion API or configure an S3/SFTP connector
3. Supports upsert and delete operations via a `__Operation` field in the file

**File format requirements (source-verified):**
- CSV: UTF-8, header row required, max file size **150 MB** (not 10GB — that was incorrect)
- Max 100 files per bulk job
- Date fields: ISO 8601 (`2025-05-19T10:00:00Z`)
- A primary key field must be present and unique per record — field designated in the schema definition
- Schema defined as an OpenAPI (OAS) `.yaml` file — uploaded when creating the Ingestion API connector

> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_get_started.htm

---

## Pattern 4: Identity Resolution Automation

Identity resolution does not run automatically after every ingestion — it must be triggered.

**Trigger options:**
- **Scheduled:** Run on a fixed cadence (hourly, daily). Best for batch ingestion patterns.
- **Event-triggered:** Trigger via Flow or API after a Data Stream completes. Best for near real-time profile freshness.
- **On-demand:** Manual trigger from Setup UI. Use for initial load validation only.

**Recommended pattern for near real-time:**
```
Data Stream (streaming) → DLO updated → Platform Event fired → Flow → 
Identity Resolution API trigger → Unified Profile updated → Data Action
```

---

## Pattern 5: Data Actions (Real-Time Triggers)

Data Actions fire when a streaming event matches a condition or when a profile enters/exits a real-time segment. They connect Data 360 events to Salesforce automation.

**Action types:**

| Type | What it does | When to use |
|---|---|---|
| Flow | Triggers a Salesforce Flow | CRM record updates, task creation, notifications |
| Platform Event | Publishes a Platform Event | Integration middleware, async processing |
| Webhook | HTTP POST to external endpoint | Third-party systems, CDPs, custom APIs |
| Marketing Cloud Journey | Fires a Journey Builder entry event | Triggered marketing sends |

**Data Action best practices:**
- Data Actions run asynchronously — do not design for synchronous response
- A failed Data Action retries 3 times with exponential backoff; after that it is dropped — build idempotent handlers
- Use Platform Events + a subscriber Flow rather than calling Flow directly for complex logic (avoids governor limit entanglement in the Data 360 execution context)

---

## Pattern 6: Calculated Insights for Scoring

**Use case:** Compute LTV, engagement score, churn risk, days-since-purchase — stored on the profile for use in segmentation without re-querying transactional data.

**SQL pattern (LTV example):**
```sql
SELECT
    ssot__UnifiedIndividualId__c,
    SUM(ssot__GrandTotalAmount__c) AS TotalSpend__c,
    COUNT(ssot__Id__c) AS OrderCount__c,
    MAX(ssot__OrderedDate__c) AS LastOrderDate__c
FROM
    ssot__SalesOrder__dlm
GROUP BY
    ssot__UnifiedIndividualId__c
```

**Scheduling:** Calculated Insights refresh on a schedule (minimum 1 hour for paid tiers). Plan the refresh cadence as part of the segment SLA — a Calculated Insight used in a segment must refresh before the segment publishes.

---

## Pattern 7: Segment → Activation → Marketing Cloud

**Use case:** Push a segment of high-value customers to Marketing Cloud for a campaign.

**Steps:**
1. Build segment on `Unified Individual` with desired criteria
2. Create Activation Target: Marketing Cloud Business Unit (OAuth-connected)
3. Create Activation: map Unified Profile fields to Marketing Cloud subscriber attributes
4. Set publish schedule or trigger on segment membership change
5. Marketing Cloud receives the audience as a Salesforce Data Extension

**Activation field mapping constraints:**
- `Subscriber Key` in Marketing Cloud must map to a unique, stable identifier — use `UnifiedRecordId` or a stable source system ID, never email (email changes)
- Maximum 200 mapped fields per activation
- Activation is additive by default: adds to the Data Extension. Enable "Full Refresh" if the DE should only contain current segment members.

---

## Pattern 8: Agentforce Grounding via Data Graph

**Use case:** An Agentforce agent needs real-time customer context (recent purchases, open cases, segment membership) to personalise responses.

**How it works:**
1. Create a Data Graph: define which DMOs and fields constitute the "context" for a customer lookup
2. Configure the Agentforce Topic to use the Data Graph as a knowledge source
3. At runtime, when a customer interacts, Agentforce retrieves the Data Graph node for that `UnifiedIndividualId` and injects it into the LLM context window

**Data Graph design principles:**
- Include only fields the agent actually needs — every field adds to token consumption
- Pre-compute complex values as Calculated Insights rather than joining at query time
- Test latency: Data Graph retrieval adds to agent response time; target < 300ms for real-time service interactions
