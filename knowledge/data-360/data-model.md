# Data 360 — Data Model

## Layer Architecture

Data 360 has a three-layer data model. Understanding the boundary between each layer is critical for correct implementation.

```
Layer 1: Data Lake Objects (DLO)     ← raw ingested data, no schema enforcement
Layer 2: Data Model Objects (DMO)    ← semantic model, standard + custom
Layer 3: Unified Objects              ← identity-resolved merged profiles
```

---

## Data Lake Objects (DLO)

- Created automatically when a Data Stream is configured
- Schema is inferred from source; fields are not typed strictly at ingestion
- One DLO per Data Stream
- Not directly usable in segmentation — must map to a DMO first
- Stored in the Data 360 data lake (Hyperforce object storage)
- Retention: configurable per DLO (default 1 year)

**DLO naming convention:** `{SourceName}_{ObjectName}__dll` (system-generated, not configurable)

---

## Data Model Objects (DMO)

The semantic layer. DMOs conform to a standard schema that enables cross-source joins and identity resolution.

### Standard DMO Categories

| Category | Key DMOs |
|---|---|
| Individual | `Individual`, `Contact Point Email`, `Contact Point Phone`, `Contact Point Address` |
| Engagement | `Web Engagement`, `Mobile Application`, `Email Engagement` |
| Sales | `Opportunity`, `Opportunity Line Item`, `Lead` |
| Service | `Case`, `Work Order` |
| Commerce | `Sales Order`, `Sales Order Product`, `Product` |
| Loyalty | `Loyalty Program Member`, `Transaction Journal` |
| Party | `Account`, `Party Identification` |

### Mapping DLO → DMO

Each DLO field must be mapped to a DMO field. Unmapped fields are still stored but not accessible in segmentation.

- A single DMO can receive mappings from multiple DLOs (fan-in)
- A single DLO can map to multiple DMOs (fan-out)
- Mapping is done in **Data Stream** configuration or the **Data Mapper** UI

### Custom DMOs

Can be created when standard DMOs don't fit. Best practice: extend standard before creating custom. Custom DMOs cannot participate in standard identity resolution rulesets unless explicitly configured.

---

## Unified Objects

Produced by the Identity Resolution process. Read-only — never written to directly.

### Key Unified Objects

| Object | Description |
|---|---|
| `Unified Individual` | The resolved "golden record" for a person |
| `Unified Contact Point Email` | De-duplicated email addresses linked to a Unified Individual |
| `Unified Contact Point Phone` | De-duplicated phone numbers |
| `Unified Contact Point Address` | De-duplicated postal addresses |
| `Individual Identity Link` | Junction: maps source `Individual` records → `Unified Individual` |

### Unified Individual

The central object. Every segment, calculated insight, and activation ultimately resolves to a `Unified Individual`. Key system fields:

| Field | Description |
|---|---|
| `UnifiedRecordId` | Immutable system ID for the unified profile |
| `LastModifiedDate` | When identity resolution last updated this record |
| `ssot__DataSourceId__c` | Source that "won" reconciliation for name/demographic fields |

---

## Calculated Insights

SQL-computed metrics stored as fields or objects on the unified profile.

### Types

**Profile Metric** — a single aggregated value per Unified Individual (e.g., total spend, NPS score). Stored as a field on a DMO.

**Segment Metric** — counts or statistics about segment membership.

**Multi-dimensional Metric** — a value per Individual per dimension (e.g., spend per product category). Stored as a child DMO.

### SQL Dialect

Uses ANSI SQL with Data 360 extensions. Key constraints:
- No subqueries in `WHERE` clause — use CTEs
- Date functions: `DATEDIFF()`, `DATE_TRUNC()`, `NOW()` supported
- Must reference DMOs by API name, not label
- Aggregation must produce one row per `UnifiedIndividualId` for profile metrics

---

## Segments

A segment is a saved filter expression over DMOs + calculated insights that produces a list of `Unified Individual` IDs.

### Segment Types

| Type | Refresh | Use Case |
|---|---|---|
| Batch | Scheduled (min 12h) | Large audiences for campaigns |
| Real-time | Streaming (seconds) | Triggered journeys, data actions |
| Waterfall | Sequential exclusion logic | Suppression, priority tiers |

### Segment Criteria Sources

- DMO attribute filters (e.g., `Email Engagement.OpenCount > 3`)
- Calculated Insight values (e.g., `LTV > 500`)
- Related object existence (e.g., has `Sales Order` in last 90 days)
- Other segment membership (nested segments)

---

## Data Relationships

DMOs are related using the standard Salesforce relationship model, with one key addition:

**Primary Key Specification** — each DMO must declare a primary key field. This is required for identity resolution and for deduplication at ingestion.

**Relationship Types in Data 360:**
- `Lookup` — standard FK relationship between DMOs
- `Party Relationship` — M:M between Individuals and Accounts (replaces Contact/AccountId)

### Entity Relationship (simplified)

```
Unified Individual
  ├── Unified Contact Point Email (1:M)
  ├── Unified Contact Point Phone (1:M)
  ├── Individual Identity Link → Individual (source) (M:M)
  └── [via Lookup] Sales Order, Case, Opportunity, etc.
```

---

## Key API Names (Reference)

| Label | API Name |
|---|---|
| Unified Individual | `ssot__UnifiedIndividual__dlm` |
| Individual | `ssot__Individual__dlm` |
| Contact Point Email | `ssot__ContactPointEmail__dlm` |
| Sales Order | `ssot__SalesOrder__dlm` |
| Data Source Object | `ssot__DataSourceObject__dlm` |

The `__dlm` suffix denotes a Data Lake/Model object. The `__dll` suffix denotes a Data Lake Layer (raw DLO) object.
