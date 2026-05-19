# Data 360 — Implementation Guide

## Pre-Implementation Checklist

Before starting any Data 360 work, verify:

- [ ] Data Cloud licenses are provisioned on the org (`Setup → Company Information → Licenses`)
- [ ] Data Cloud is enabled (`Setup → Data Cloud Setup → Get Started`)
- [ ] Source system connectivity is confirmed (Salesforce org alias, S3 bucket permissions, API credentials)
- [ ] Identity resolution inputs are understood (which fields link the same person across systems)
- [ ] PII handling and consent requirements documented (GDPR/CCPA scope)
- [ ] Data residency requirements confirmed (Hyperforce region cannot change post-provisioning)
- [ ] Stakeholders aligned on profile freshness SLAs (real-time vs batch)

---

## Phase 1: Foundation Setup (Days 1–5)

### Step 1: Enable Data Cloud and Configure Org

1. Navigate to `Setup → Data Cloud Setup`
2. Accept Terms of Service
3. Note the Data Cloud instance URL returned after enabling — needed for all API calls (different from the Salesforce org URL)
4. Create an External Client Application (Connected App) for API access:
   - Enable OAuth settings
   - Required scopes: `cdp_ingest_api`, `api`, `refresh_token, offline_access`
   - **Uncheck** "Issue JSON Web Token (JWT)-based access tokens for named users"
   - Generate a private key and self-signed certificate for JWT Bearer flow
   - Use JWT Bearer flow for all M2M integrations (preferred over client credentials)

> Source: developer.salesforce.com/docs/data/data-cloud-int/guide/c360-a-create-ingestion-api-connected-app.html

### Step 2: Assign Permission Sets

Assign to the implementation team:
- `Data Cloud Admin` → implementation leads
- `Data Cloud Data Aware Specialist` → business analysts / QA

### Step 3: Configure Data Spaces (if required)

If multi-BU or multi-region isolation is needed, create Data Spaces now — before any Data Streams are created. Objects cannot be moved between Data Spaces after creation.

---

## Phase 2: Data Ingestion (Days 5–15)

### Step 4: Map Source Systems to DMOs

Before creating any Data Stream, produce a field-mapping document:

| Source System | Source Object | Source Field | DMO | DMO Field | Notes |
|---|---|---|---|---|---|
| Salesforce CRM | Contact | Id | Individual | ssot__SourceRecordId__c | Primary key |
| Salesforce CRM | Contact | Email | Contact Point Email | ssot__EmailAddress__c | Identity match field |
| ... | | | | | |

Do this for every source before touching the UI. Mismatched mappings are painful to fix after data is ingested.

### Step 5: Create Salesforce Connector Data Streams

1. `Data Cloud Setup → Data Streams → New`
2. Select source: Salesforce CRM (choose the org alias)
3. Select object
4. Field selection: only include fields needed for identity resolution, segmentation, and activation — not all fields
5. Set sync schedule: Full Refresh for initial load, then Incremental
6. Map to DMO immediately after stream creation — an unmapped stream is wasted storage

### Step 6: Create External Data Streams (if applicable)

For file-based or API ingestion:
1. `Data Cloud Setup → Salesforce Integrations → Ingestion API → New`
2. Name the connector and upload an **OpenAPI (OAS) `.yaml` schema file** describing the payload structure
3. Status shows **"Needs Data Stream"** — create the Data Stream to activate
4. In the Data Stream, designate: Primary Key field, optional Timestamp field (for out-of-order handling), Data Space assignment
5. After deployment, map the DLO to the appropriate DMO for segmentation use
6. Note the `sourceApiName` — needed for Streaming Ingestion API calls
7. Test with a small sample payload before full load

> Source: developer.salesforce.com/docs/data/data-cloud-int/guide/c360-a-connect-an-ingestion-source.html

### Step 7: Validate Ingestion

After the first run:
```sql
-- Check record count in DLO
SELECT COUNT(*) FROM {DLOApiName}

-- Check field population rate for key fields
SELECT 
    COUNT(*) AS Total,
    COUNT(ssot__EmailAddress__c) AS WithEmail,
    COUNT(ssot__MobileNumber__c) AS WithPhone
FROM ssot__ContactPointEmail__dlm
```

Compare counts against source system. A >5% discrepancy warrants investigation before proceeding to identity resolution.

---

## Phase 3: Identity Resolution (Days 15–20)

### Step 8: Configure Identity Resolution Ruleset

Navigate to `Data Cloud Setup → Identity Resolution → New Ruleset`

**Recommended rule order for B2C:**
1. Exact match: `Contact Point Email` + `Last Name` (high confidence)
2. Exact match: `Mobile Phone` + `Last Name` (high confidence)
3. Exact match: `Email` only (medium confidence — email can be shared)
4. Fuzzy match: `First Name` + `Last Name` + `Postal Code` (lower confidence, use only if above don't yield enough matches)

**Reconciliation rules:**
- Name fields: prefer Salesforce CRM (most authoritative)
- Email: prefer the most recently verified source
- Demographics: prefer the source with highest data quality score

### Step 9: Run Identity Resolution (Initial)

Run a full resolution. On large datasets (1M+ source records), this takes 2–8 hours.

After completion, validate:
```sql
-- Average source records per unified individual (>1.5 suggests good matching, >5 suggests over-merging)
SELECT 
    AVG(LinkCount) AS AvgLinksPerUnified
FROM (
    SELECT UnifiedIndividualId, COUNT(*) AS LinkCount
    FROM ssot__IndividualIdentityLink__dlm
    GROUP BY UnifiedIndividualId
)
```

If average is > 5, review match rules for over-merging. Common cause: fuzzy name + zip matching too broadly.

---

## Phase 4: Calculated Insights (Days 20–25)

### Step 10: Implement Core Metrics

Start with the 3–5 metrics that drive the first use case. Do not build all possible metrics upfront.

Standard starter metrics for most engagements:
- **Days Since Last Purchase** — recency signal
- **Total Lifetime Value** — monetary signal
- **Engagement Score** — email/web activity composite
- **Segment Flags** — boolean indicators for key business segments

### Step 11: Validate Calculated Insights

After the first run, spot-check against source system values:
- Pull 10 known customer records from CRM
- Look up their Unified Individual IDs via the Profile API
- Query the Calculated Insight values
- Compare against manually computed expected values

---

## Phase 5: Segmentation (Days 25–30)

### Step 12: Build Initial Segments

Start with simple segments that stakeholders can validate easily:
- All customers with a purchase in the last 12 months
- All customers with an open support case
- All opted-in email addresses

Complex segments (multi-DMO, Calculated Insight criteria) should be built after the simple ones validate.

### Step 13: Consent Filter Validation

For every segment intended for outbound activation, verify:
1. The consent DMO is mapped and populated
2. A `Contact Point Type Consent` filter is applied with the correct channel
3. The segment count drops appropriately (opted-out individuals should be excluded)

---

## Phase 6: Activation (Days 30–40)

### Step 14: Configure Activation Targets

For Marketing Cloud:
1. `Data Cloud Setup → Activation Targets → New`
2. Select Marketing Cloud Business Unit
3. Authenticate with the Marketing Cloud Connected App credentials
4. Test connection before building activations

### Step 15: Create and Test Activations

1. Create activation from the Segment
2. Map Unified Individual fields to the target DE/subscriber attributes
3. Run once in test mode (small segment)
4. Validate DE contents in Marketing Cloud
5. Verify Subscriber Key is correctly populated

---

## Phase 7: Data Actions (if real-time automation required)

### Step 16: Configure Data Actions

1. `Data Cloud Setup → Data Actions → New`
2. Select trigger: Streaming Event match or Segment Entry/Exit
3. Select action type: Flow, Platform Event, or Webhook
4. Map Data 360 fields to Flow input variables / event fields / webhook payload
5. Test with a known profile that will trigger the condition

---

## Deployment Considerations

### Metadata Deployment

Data 360 configuration is partially deployable via Metadata API:
- Data Streams: **not deployable** via standard metadata — must be recreated manually in each org
- Calculated Insights: deployable as `CalculatedInsight` metadata type
- Segments: deployable as `Segment` metadata type (Spring '25+)
- Activation Targets: **not deployable** — credentials are org-specific

**Recommendation:** Document Data Stream configuration in a runbook. Use Metadata API for Calculated Insights and Segments. Recreate Activation Targets manually with documented configuration.

### Sandbox Strategy

Data 360 in sandboxes:
- Sandbox refreshes do not copy Data Cloud data (only metadata configuration)
- Data Streams must be re-run after each refresh
- Use synthetic/anonymised data in sandbox — never copy production PII
- Sandbox Data Cloud license must be separately provisioned (it's not included in standard sandbox refresh)
