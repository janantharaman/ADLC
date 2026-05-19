---
source: tableau.com/products/prep; help.tableau.com (2026-05-17)
product: Tableau Prep
section: prep
last-updated: 2026-05-17
---

# Tableau Prep — Data Preparation

## What Tableau Prep Is

Tableau Prep is a visual, no-code data preparation tool. It enables analysts to connect to raw data, clean and reshape it, and output a clean, analysis-ready dataset — without writing SQL or ETL scripts.

Prep is used **before** Tableau Desktop or Tableau Cloud authoring: the output of a Prep flow becomes the data source for Tableau visualisations.

## Two Products

| Product | Role |
|---|---|
| **Tableau Prep Builder** | The authoring environment — build flows visually with instant feedback at every step. Available as a local install (Windows/Mac) and via web authoring on Tableau Cloud/Server. |
| **Tableau Prep Conductor** | The automation and governance layer — schedules flow runs, monitors status, tracks data lineage and connections. Bundled with Tableau Cloud and Tableau Server (Advanced Management). |

## How Flows Work

A Prep flow is a directed graph of steps. Data enters at Input nodes, passes through transformation steps, and exits at Output nodes.

```
Input(s) → Clean → Join/Union → Aggregate → Formula → Output(s)
```

At every step, Prep shows a live data sample and profile of the data — counts, distributions, null values, outliers — so the user can see what the transformation did immediately without having to run the full dataset.

## Step Types

### Input Step

Connects to a data source:
- Files: Excel, CSV, JSON, PDF, Spatial files
- Databases: 100+ native connectors (Snowflake, BigQuery, SQL Server, Oracle, Salesforce, PostgreSQL, and more)
- Published data sources on Tableau Server or Cloud
- Google Sheets, OneDrive, SharePoint

Multiple input steps can exist in a single flow — for joining data from multiple sources.

### Clean Step

The primary transformation step. Operations available:

| Operation | Description |
|---|---|
| Rename field | Change the field name |
| Retype | Change data type (string → date, number → string) |
| Remove field | Drop a column from the flow |
| Filter rows | Remove rows matching a condition |
| Clean values | Remove whitespace, change case, replace nulls |
| Bucket / Group | Merge categorical values into groups |
| Split | Split one field into multiple (delimiter or fixed position) |
| Pivot | Columns to rows or rows to columns |
| Calculate | Add a calculated field using Tableau calculation syntax |

All operations are recorded as a visible list on the step — the user can review, reorder, or delete individual operations at any time.

### Join Step

Combines two inputs based on matching field values:

| Join Type | Rows Kept |
|---|---|
| Inner | Only rows with matches in both inputs |
| Left | All rows from the left input; nulls for unmatched right |
| Right | All rows from the right input; nulls for unmatched left |
| Full Outer | All rows from both; nulls where no match |
| Not Inner | Rows with NO match (anti-join) |
| Left Only | Rows from left with no match in right |
| Right Only | Rows from right with no match in left |

Join fields are selected visually. Prep highlights mismatches and suggests join field corrections based on field name and data profiling.

### Union Step

Combines rows from two or more inputs with compatible schemas:
- Fields with the same name merge automatically
- Mismatched fields appear as separate columns (can be manually merged)
- Useful for appending monthly files, combining data from parallel systems

### Aggregate Step

Groups rows and computes aggregated values:
- Select which fields to group by (placed in "Grouped Fields")
- Select which fields to aggregate (placed in "Aggregated Fields") with SUM, AVG, COUNT, MIN, MAX, etc.
- Result is one row per unique combination of grouped fields

Use Aggregate when the downstream analysis needs a summarised dataset to reduce load time.

### Formula Step (Calculated Fields)

Creates new fields using Tableau's calculation syntax:
- Same functions available as in Tableau Desktop
- Supports string, date, numeric, logical, and type-conversion functions
- Calculations can reference other calculated fields in the same step

### Pivot Step

**Columns to Rows:** Unpivots wide format to long format. Example: a table with columns Jan, Feb, Mar, Apr → two columns: Month and Value.

**Rows to Columns:** Pivots long format to wide format. Select the field whose values become column headers, and the field whose values populate those columns.

### Output Step

Writes the prepared data to a destination:
- **Published Data Source:** Publishes to Tableau Cloud or Server as a data source that workbooks can connect to
- **File:** Saves to CSV, Hyper extract, Excel, or spatial file
- **Database:** Writes back to a database table (Snowflake, BigQuery, SQL Server — with appropriate connector)
- **Salesforce:** Writes back to a Salesforce object (requires Salesforce Output connector)

A flow can have multiple output steps — output different subsets or aggregations of the same data to multiple destinations in a single run.

## Agentic AI in Prep Builder (Tableau Agent)

Tableau Prep Builder includes AI-assisted transformation suggestions:
- Suggests matching fields for joins based on data profiling
- Recommends cleaning operations for detected data quality issues (extra spaces, inconsistent capitalisation, outlier values)
- Generates calculated field formulas from natural language descriptions ("calculate the number of days between Order Date and Ship Date")

## Scheduling with Prep Conductor

Published flows are scheduled in Tableau Cloud (or Server with Advanced Management):

1. Publish the flow from Prep Builder
2. Tableau Cloud → Schedules → New Schedule → select the flow → set frequency
3. Conductor runs the flow on the schedule, refreshing the output data source
4. Failure notifications sent via email or Slack integration

**Flow run log:** Accessible in Tableau Cloud → Jobs. Shows each run's start/end time, duration, and error details.

**Lineage:** Tableau Cloud's Data Catalog tracks: which databases feed which flows → which data sources → which workbooks → which views. Use this to assess impact before changing a source schema.

## Licensing

Tableau Prep Builder and Conductor are **included with Creator licences**. They are not available to Explorers or Viewers. Not sold standalone since April 2018.

## Key Use Cases for PS Engagements

| Scenario | Prep Approach |
|---|---|
| Joining Salesforce export with ERP flat file | Input: Salesforce data source + CSV file → Join on account ID → Output |
| Normalising monthly sales files from different regions | Input: multiple CSV files → Union → Clean (normalise field names) → Output |
| Unpivoting a pivot table from finance | Input: Excel → Pivot (Columns to Rows) → Clean → Output |
| Creating a daily-refreshed summary for a dashboard | Input: database table → Aggregate → Output to published data source → Schedule daily |
| Feeding CRM Analytics with clean external data | Input: source file/database → Clean → Output to CSV → Upload to CRM Analytics via External Data API |

## Common Gotchas

| Gotcha | Impact | Prevention |
|---|---|---|
| Schema change in source breaks flow | Flow fails; output data source not refreshed | Monitor Conductor job log; add alerting on failures |
| Full outer join on large tables | Very slow; may time out | Use inner or left join where possible; filter early in the flow |
| Output to published data source not refreshed before workbook opens | Viewers see stale data | Schedule flow to run before expected dashboard usage window |
| Calculated field using date functions on a string field | Null output or error | Retype the field to Date before the calculation step |
| Flow with many steps is slow in preview | Sample computation overhead | Reduce sample size in Prep Builder settings during authoring; full run is faster |
