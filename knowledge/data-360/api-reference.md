# Data 360 — API Reference

## API Overview

Data 360 exposes four distinct API surfaces. Each serves a different purpose and uses different authentication patterns.

| API | Purpose | Auth |
|---|---|---|
| Ingestion API | Push data into Data Streams | OAuth 2.0 Client Credentials |
| Query API | Read DMO/DLO data and unified profiles | OAuth 2.0 JWT Bearer |
| Calculated Insights API | Trigger and monitor CI jobs | OAuth 2.0 JWT Bearer |
| Streaming Ingestion (Pub/Sub) | Real-time event ingestion | OAuth 2.0 Client Credentials |

Base URL: `https://{your-subdomain}.c360a.salesforce.com` (Data Cloud-specific domain, distinct from the Salesforce instance URL)

---

## Authentication

Data 360 APIs require a **two-step token exchange** — a Salesforce access token is obtained first, then exchanged for a Data 360-specific access token.

**Step 1 — Get Salesforce access token (JWT Bearer Flow — recommended for M2M):**
```
POST https://login.salesforce.com/services/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
&assertion={signed_jwt}
```

**Step 2 — Exchange for Data 360 token:**
```
POST {instance_url}/services/a360/token
Authorization: Bearer {salesforce_access_token}
```

The response contains a Data 360-scoped `access_token` and the Data Cloud `instance_url` — use this URL, not the Salesforce org URL, as the base for all Data 360 API calls.

**Required OAuth scopes on the Connected App:**
- `Access and manage your Data 360 Ingestion API data (cdp_ingest_api)`
- `Access and manage your data (api)`
- `Perform requests on your behalf at any time (refresh_token, offline_access)`

**Connected App setting:** Uncheck "Issue JSON Web Token (JWT)-based access tokens for named users" — this must be disabled for the M2M flow to work correctly.

> Source: developer.salesforce.com/docs/data/data-cloud-int/guide/c360-a-create-ingestion-api-connected-app.html

---

## Ingestion API

### Bulk Ingestion

**Upload a batch of records (upsert):**
```
POST https://{dc-subdomain}.c360a.salesforce.com/api/v1/ingest/jobs
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "object": "MyCustomObject__dll",
  "contentType": "CSV",
  "operation": "upsert"
}
```

Then upload the CSV data:
```
PUT https://{dc-subdomain}.c360a.salesforce.com/api/v1/ingest/jobs/{jobId}/batches
Content-Type: text/csv

Id,FirstName,LastName,Email
001,Jane,Smith,jane@example.com
```

Close the job:
```
PATCH https://{dc-subdomain}.c360a.salesforce.com/api/v1/ingest/jobs/{jobId}
{ "state": "UploadComplete" }
```

**Delete records:**
Same flow, set `"operation": "delete"` and only include the primary key field in the CSV.

### Streaming Ingestion

```
POST https://{dc-subdomain}.c360a.salesforce.com/api/v1/ingest/sources/{sourceApiName}/{objectApiName}
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "data": [
    {
      "Id": "evt-001",
      "EventType": "PageView",
      "Url": "/products/shoes",
      "Timestamp": "2025-05-19T10:00:00Z",
      "IndividualId": "ind-123"
    }
  ]
}
```

Max 1,000 records per call. Returns HTTP 202 (accepted) — streaming is async, not synchronous confirmation of landing.

---

## Query API

The Query API uses **ANSI standard SQL** (not SOQL) to query across data model, data lake, unified, and linked objects.

**Method:** POST to `/api/v1/query`  
**Max rows per request:** 49,999  
**Execution:** Synchronous

### Basic Query

```
POST https://{dc-instance-url}/api/v1/query
Content-Type: application/json
Authorization: Bearer {dc_access_token}

{
  "sql": "SELECT ssot__FirstName__c, ssot__LastName__c FROM ssot__Individual__dlm LIMIT 10"
}
```

### Profile Query (by Unified Individual ID)

```sql
SELECT 
    ui.ssot__Id__c,
    ui.ssot__LastModifiedDate__c,
    cpe.ssot__EmailAddress__c
FROM ssot__UnifiedIndividual__dlm ui
JOIN ssot__UnifiedContactPointEmail__dlm cpe 
    ON ui.ssot__Id__c = cpe.ssot__PartyId__c
WHERE ui.ssot__Id__c = '0Af...'
```

### Pagination

Use `limit`, `offset`, and `orderby` parameters. The `done` boolean signals when all results are retrieved.

```json
{
  "data": [...],
  "rowCount": 49999,
  "queryId": "...",
  "startTime": "2025-05-19T10:00:00Z",
  "endTime": "2025-05-19T10:00:01Z",
  "metadata": { "fieldName": { "type": "...", "placeInOrder": 0, "typeCode": "..." } },
  "done": false
}
```

When `done` is false, fetch the next batch using `orderby` + `offset` increments.

> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_query.htm

---

## Calculated Insights API

### Trigger a Calculated Insight Run

```
POST https://{dc-subdomain}.c360a.salesforce.com/api/v1/calculatedinsights/{ciApiName}/run
Authorization: Bearer {access_token}
```

### Check Run Status

```
GET https://{dc-subdomain}.c360a.salesforce.com/api/v1/calculatedinsights/{ciApiName}/runs/{runId}
```

Response statuses: `Queued`, `Running`, `Succeeded`, `Failed`

---

## Identity Resolution API

### Trigger Identity Resolution Run

```
POST https://{dc-subdomain}.c360a.salesforce.com/api/v1/identityresolution/{rulesetApiName}/run
Authorization: Bearer {access_token}
```

### Get Run Status

```
GET https://{dc-subdomain}.c360a.salesforce.com/api/v1/identityresolution/{rulesetApiName}/runs/{runId}
```

---

## Segment API

### Publish a Segment On-Demand

```
POST https://{dc-subdomain}.c360a.salesforce.com/api/v1/segments/{segmentApiName}/publish
Authorization: Bearer {access_token}
```

### Get Segment Member Count

```
GET https://{dc-subdomain}.c360a.salesforce.com/api/v1/segments/{segmentApiName}/count
```

Note: Returns an estimate for large segments until the first full publish completes.

---

## Profile API (Unified Profile Lookup)

Look up a unified profile by a source system identifier (e.g., email address, CRM Contact ID).

```
GET https://{dc-subdomain}.c360a.salesforce.com/api/v1/profile/lookup
  ?key=email&value=jane%40example.com
Authorization: Bearer {access_token}
```

Returns the `UnifiedIndividualId` and linked contact points. Use this for real-time profile lookup in service/sales contexts.

---

## Rate Limits and Quotas

Verified limits from official developer documentation:

| API / Resource | Limit |
|---|---|
| Ingestion API requests per hour | 20 |
| Ingestion API concurrent bulk jobs | 5 |
| Ingestion API files per bulk job | 100 |
| Bulk file size | 150 MB per file |
| Streaming payload size | 200 KB per request |
| Streaming requests/second (all endpoints combined) | 250 |
| Streaming delete records per call | 200 maximum |
| Bulk job retention | 7 days (older jobs are deleted) |
| Streaming processing latency | ~3 minutes (asynchronous) |
| Query API max rows per request | 49,999 |

> Source: developer.salesforce.com/docs/atlas.en-us.c360a_api.meta/c360a_api/c360a_api_get_started.htm

Additional limits (vary by edition — verify via `Data Cloud Setup → Usage and Limits`):
- Data Streams per org
- Unified profile count
- Segment count
- Calculated Insight count
- Activation target count

Always check the org's current provisioned limits before designing ingestion volume or segment publish frequency.
