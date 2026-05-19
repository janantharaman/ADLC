---
source: help.tableau.com — Joins & Unions; Relationships; Extracts; Data Blending; Customize Data Sources (2026-05-17)
product: Tableau
section: data-connections
last-updated: 2026-05-17
---

# Tableau — Data Connections, Joins, Relationships & Extracts

## The Tableau Data Model

Tableau's data model has two layers:

```
Logical Layer  →  Tables connected via Relationships ("noodles")
     ↓
Physical Layer →  Tables merged via Joins / Unions (inside a logical table)
```

You work at the logical layer by default. Double-click a logical table to open the physical layer.

### Relationships (Logical Layer — Default)

Relationships are the recommended way to combine tables. They are "flexible noodles" between logical tables in the data source canvas.

**Key properties:**
- No join type required — just specify matching fields
- Deferred and context-aware: joins are only executed at query time, only for tables whose fields are used in the current worksheet
- Preserve each table's native level of detail — aggregates are not duplicated
- Support many-to-many and full outer joins natively
- Tables remain independent in the data source — not merged into a flat table

**Relationship requirements:**
- Matching fields must share the same data type
- Geographic fields cannot define a relationship
- Circular relationships are not supported
- Cannot relate published data sources to each other

**Performance options (right-click relationship line):**
- **Cardinality:** Many-to-Many, Many-to-One, One-to-Many, One-to-One — helps Tableau optimise query generation
- **Referential Integrity:** Some Records Match (default), All Records Match — affects whether unmatched values are preserved

**When to use relationships over joins:**
- Multiple tables at different levels of detail (fact + dimension tables)
- Avoiding row duplication from fan-out joins
- Any new multi-table data source — relationships are the modern default

### Joins (Physical Layer)

Joins merge tables into a single flat logical table. Access via: double-click a logical table in the data source canvas → the join/union canvas opens.

| Join Type | Rows Kept |
|---|---|
| Inner | Only rows with matches in both tables — unmatched rows dropped |
| Left | All rows from left table; nulls for unmatched right |
| Right | All rows from right table; nulls for unmatched left |
| Full Outer | All rows from both tables; nulls where no match |

**Join clauses:**
- Most commonly equality (`=`) — but non-equi joins (`<`, `<>`) are supported
- Multiple clauses allowed (e.g., match on both first name AND last name)
- Clauses can include calculations (field concatenation, type conversions) — connector-dependent
- Null keys: most databases exclude rows where the join key is null; Tableau can override this for single-connection sources via Data → Join null values to null values

**Cross-database joins:**
- Join tables from different data sources using the Add button in the data pane
- The combined source behaves as a single source during analysis
- Not supported for cube data, extract-only connectors (Google Analytics), or published data sources
- Performance: same-database joins are always faster than cross-database joins

**Joins vs. Relationships summary:**

| Aspect | Relationships | Joins |
|---|---|---|
| Layer | Logical | Physical |
| Setup | Match fields, no join type | Choose join type explicitly |
| Level of detail | Each table preserves its own | Merged into one flat table |
| Duplicates | Avoid duplicated aggregates | Can duplicate rows |
| Published data sources | Can be related | Cannot be joined |
| Default | Yes (recommended) | Must opt in |

### Unions

Unions append rows from multiple tables. Tables must share compatible schemas (same field names and types).

**Creating a union:**
- Drag a second table below an existing table in the physical layer join canvas → union is created
- **Wildcard union:** specify a filename pattern and Tableau includes all matching files automatically — useful for combining monthly/yearly CSV or Excel files

**Field matching:** Fields with the same name merge automatically. Mismatched fields appear as separate columns — use the "Merge Mismatched Fields" option to manually align them.

## Data Blending

Data blending combines data from two separate data sources in a worksheet — it is not a join in the database. Each data source is queried independently; results are combined in Tableau.

**How blending works:**
- The first data source added to a worksheet is the **primary** source
- The second is the **secondary** source
- Blend fields (relationship keys) are auto-detected from field name matching, or set manually
- Secondary source data is always aggregated to the blend field granularity before being combined with the primary

**When to use blending:**
- Need to combine a published Tableau data source (cannot be joined) with another source
- Combining data from different database systems where cross-database joins are not supported
- Performance reasons — query each database separately, blend lightweight aggregates

**Blending limitations:**
- Secondary source fields show orange tick marks; some operations are restricted
- Cannot create calculated fields that combine fields from both sources directly
- Cannot use COUNTD (count distinct) on blended secondary source fields
- Blending is applied per worksheet — does not create a persistent combined data source

## Live vs Extract Connection

### Live Connection
- Every query sent directly to the data source in real time
- Always reflects current data — no refresh needed
- Performance depends entirely on data source speed and size
- Best for: transactional data that changes frequently, small-to-medium datasets, real-time dashboards

### Extract (.hyper format)
- Snapshot of data stored in Tableau's columnar `.hyper` format on disk
- Queries run against the local extract — very fast regardless of source latency
- Must be refreshed (manually or on schedule) to reflect updated data
- The older `.tde` format was deprecated March 2023; `.tde` cannot be opened from version 2024.2+

**Extract settings:**

| Setting | Description |
|---|---|
| Data Storage: Logical Tables | Default — one extract table per logical table; supports all features |
| Data Storage: Physical Tables | Joins computed at query time; can reduce file size; restrictions apply |
| Extract Filters | Limit rows included in the extract by field conditions |
| Aggregation | Aggregate for visible dimensions (fewer rows); Roll up dates to a coarser level |
| Number of Rows | All Rows / Top N / Sample |
| Incremental Refresh | Append only new rows since last refresh (requires All Rows + a date/numeric key field) |

**Physical Tables restrictions:** only equality joins, identical column types, no RAWSQL, no incremental refresh, no extract filters, no Top N or sampling, no data appending.

**Incremental refresh:**
- Appends new rows — does not update or delete existing rows
- From version 2024.2: subrange refresh — re-extracts a specified prior period to capture retroactive changes
- Incompatible with aggregation setting

**Refresh scheduling:** Set up in Tableau Cloud or Server post-publish → Data Source page → Schedule Extract Refresh.

**Extract tips:**
- Save the workbook after creating an extract to preserve the connection
- Avoid directly connecting to a `.hyper` file — table names differ, refresh is impossible, relationships are lost
- For User Function data policies on virtual connections, use live connections — extracts bypass those policies

**APIs for programmatic extract management:**
- **Hyper API** — create `.hyper` files programmatically (Python, Java, C++)
- **Tableau Server REST API / Tableau Server Client (Python)** — publish and trigger refresh programmatically

## Customising the Data Source

After connecting to data, customise the data source canvas before building worksheets:

| Operation | How |
|---|---|
| Rename a field | Double-click the field name in the data source grid |
| Hide a field | Right-click → Hide. Hidden fields excluded from extracts. |
| Create an alias | Right-click a dimension member → Edit Aliases |
| Set default aggregation | Right-click a measure → Default Properties → Aggregation |
| Set default sort | Right-click a dimension → Default Properties → Sort |
| Set default format | Right-click a measure → Default Properties → Number Format |
| Assign geographic role | Right-click a field → Geographic Role → select type |
| Create a folder | Right-click in data pane → Create Folder (organises fields into groups) |
| Add a data source filter | Data Source tab → Filters → Add (restricts data for all worksheets) |

**Data source filters** apply before all other filters and reduce the data available to the entire workbook. Use for security (exclude irrelevant rows), performance (reduce data volume), or scope (restrict to relevant time period).
