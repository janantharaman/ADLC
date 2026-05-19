---
source: Salesforce Trailhead — CRM Analytics Data Integration Basics; Build and Administer CRM Analytics trail; trailhead.salesforce.com (2026-05-17)
product: CRM Analytics
section: data-model
last-updated: 2026-05-17
---

# CRM Analytics — Data Model & Data Pipelines

## Dataset Structure

A CRM Analytics dataset is the core data unit — a flat, columnar store optimised for the Analytics query engine. Datasets are not queryable via SOQL; they use SAQL (Salesforce Analytics Query Language) or the UI.

### Field Types in a Dataset

| Type | Description | Example |
|---|---|---|
| **Dimension** | String/categorical value. Used for grouping, filtering, slicing. | Account Name, Region, Stage |
| **Measure** | Numeric value. Aggregated (sum, avg, count, min, max) in queries. | Revenue, Quantity, Days Open |
| **Date** | Temporal field with automatic hierarchy (year → quarter → month → week → day → hour). | Close Date, Created Date |

Dimensions map to `"type": "dimension"` in dataset metadata. Measures map to `"type": "measure"`. Dates map to `"type": "date"` with a format specification.

### Extended Metadata (XMD)

Each dataset has an associated XMD file that controls display: field labels, aliases, date formats, number formats, colour palettes, and default chart configurations. XMD does not change the underlying data — it controls how the data is presented in the UI.

## Data Sources

CRM Analytics ingests data from three sources:

### 1. Salesforce Data (via Data Sync + Connected Objects)

Salesforce objects are enabled for Data Sync in Setup → Analytics → Data Manager → Connected Objects. Once enabled, the object's records sync on a schedule (typically every 24 hours, configurable to hourly).

**Objects commonly synced:**
- Opportunity, Account, Contact, Case, Lead
- Custom objects (append `__c`)
- Person Account variants
- Salesforce standard report data (via Salesforce connector in recipes)

Data Sync creates a "connected object" staging area — raw object extract — that dataflows and recipes reference as input.

**SOQL Direct Query (alternative to sync):** For small, real-time datasets, dashboards can query Salesforce data live via SOQL without syncing. Used for lookup data or real-time dashboards where extract latency is unacceptable. Not suitable for large volumes or complex joins.

### 2. External Data (CSV / Files)

Flat files (CSV, Excel) can be uploaded directly into CRM Analytics via:
- UI upload (manual)
- External Data API (programmatic)
- Recipes (file input step)

Use cases: cost data from finance, quota targets, territory mappings, reference tables.

### 3. External Systems (via Connectors)

CRM Analytics supports connectors to external databases and cloud services:
- Snowflake, Amazon S3, Google BigQuery, Microsoft Azure
- SAP, MuleSoft, Heroku Postgres
- REST API connectors (custom)

External connections are configured in Data Manager → Connected Data Sources.

## Data Pipelines: Dataflows vs Recipes

### Dataflows (Legacy)

JSON-defined transformation sequences. Each node is a transformation step:

| Node Type | Purpose |
|---|---|
| `sfdcDigest` | Extract a Salesforce connected object |
| `edgemart` | Reference an existing dataset or external data file |
| `augment` | Join two datasets (left join) |
| `computeExpression` | Add a calculated field |
| `computeRelative` | Window functions (running totals, prior-period comparisons) |
| `filter` | Filter rows |
| `flatten` | Flatten hierarchical data (e.g., role hierarchy) |
| `sfdcRegister` | Output a dataset and register it in the Analytics platform |

Dataflows are edited in the JSON editor. They run on a schedule (once/day by default). Multiple dataflows can run in sequence; ordering is managed manually.

**Gotcha:** Dataflows are still supported but no longer the recommended approach for new implementations. Recipes are preferred. If an org has legacy dataflows, do not migrate them without assessing dependencies — dashboards reference dataset API names, not dataflow names, so a clean dataset migration can coexist.

### Recipes (Modern — Preferred)

Visual, node-based data transformation tool in Data Manager. Recipes support the same transformations as dataflows but with a drag-and-drop interface and live preview at each node.

**Recipe Node Types:**

| Node | Purpose |
|---|---|
| **Input** | Connect to a connected Salesforce object, dataset, or external source |
| **Join** | Inner, left, right, or full outer join between two inputs |
| **Union** | Append rows from two datasets with matching schema |
| **Filter** | Remove rows based on conditions |
| **Formula** | Add a calculated column (using recipe formula syntax) |
| **Transform** | Rename, retype, or reformat fields; bucket/group values |
| **Aggregate** | Group by dimensions, compute aggregated measures |
| **Output** | Register the result as a dataset, or write back to a Salesforce object |

Recipes can also schedule write-backs to Salesforce — computed fields (e.g., risk scores, predicted close dates) written back to Opportunity or Account fields.

**Recipe vs Dataflow decision:**
- New implementation: always use Recipes
- Existing dataflow still working and not broken: leave it unless scope requires changes
- Dataflow with complex `flatten` node for hierarchy: Recipes now support hierarchy flattening — migrate when convenient

## Data Sync Scheduling

Data Sync runs are configured per connected object in Data Manager:
- **Full sync:** Re-extracts all records from the object. Use for initial load or after schema changes.
- **Incremental sync:** Extracts only records modified since the last sync (based on `SystemModstamp`). Use for daily operations.

Recipes and dataflows run after Data Sync completes. Configure pipeline run order in the Data Manager schedule view.

**Gotcha:** If a Data Sync fails (API limit exceeded, object schema change), downstream recipes and dataflows will run on stale data without explicit error surfacing in the UI. Always monitor the Data Manager job log, not just dashboard load status.

## Dataset Row Limits and Volume

| Tier | Approximate Row Limit per Dataset |
|---|---|
| CRM Analytics Growth | 100 million rows |
| CRM Analytics Plus | 100 million rows |
| Single file upload | 40 MB (API); unlimited via connector |

For very large datasets (>50M rows), consider pre-aggregating in recipes before outputting the final dataset. The Analytics engine is fast but full-table scans on 100M-row datasets affect dashboard load time.

## Connected Objects — Key Setup Steps

1. **Setup → Analytics → Data Manager → Connected Objects**
2. Toggle the Salesforce object to "Enabled"
3. Select fields to sync (do not sync all fields on large objects — increases sync time and dataset size)
4. Choose sync frequency (daily recommended for most objects; hourly for Case or Lead in active service environments)
5. Run the first sync manually to validate field selection
6. Verify in the Data Manager job log that the sync completed without errors

**Fields to always sync on Opportunity:**
`Id, AccountId, Name, Amount, CloseDate, StageName, OwnerId, RecordTypeId, CreatedDate, LastModifiedDate, IsClosed, IsWon`

Avoid syncing long text, rich text, or unused formula fields — they add volume without analytical value.
