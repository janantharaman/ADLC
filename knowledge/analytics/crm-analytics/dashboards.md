---
source: Salesforce Trailhead — CRM Analytics Dashboard Building Basics; Build Advanced CRM Analytics Dashboards; Customize a Dashboard with CRM Analytics Advanced Editor; Embed a CRM Analytics Dashboard in Lightning Experience; trailhead.salesforce.com (2026-05-17)
product: CRM Analytics
section: dashboards
last-updated: 2026-05-17
---

# CRM Analytics — Dashboards, SAQL & Embedding

## Dashboard Basics

A CRM Analytics dashboard is a collection of widgets arranged on a canvas. Dashboards can span multiple datasets and reference multiple lenses. They are the primary artefact delivered to end users.

### Dashboard Designer (Point-and-Click)

The Dashboard Designer is the visual editor for building dashboards. Components:
- **Canvas:** The layout area. Widgets are dragged, resized, and arranged.
- **Widget Panel:** Available widget types to add to the canvas.
- **Query Panel:** Configures the data behind each widget (dataset, groupings, measures, filters).
- **Properties Panel:** Controls widget appearance (colours, labels, chart type, conditional formatting).

### Widget Types

| Widget | Purpose |
|---|---|
| **Chart** | Bar, line, scatter, donut, waterfall, map, pyramid — standard visualisations |
| **Table** | Tabular data display with sorting and pagination |
| **Metric** | Single KPI number with label |
| **Gauge** | Progress against a target |
| **Toggle / Picklist** | User-driven filter selection (dimension values) |
| **Date Selector** | Date range filter driven by user |
| **Container** | Grouping/visual container for layout |
| **Text / Image** | Static labels, instructions, logos |
| **Link** | Navigation to another dashboard, record, or URL |

## Key Dashboard Concepts

### Faceting
When a user clicks on a widget (e.g., selects "Q3" on a bar chart), all other widgets on the dashboard that share the same dataset automatically filter to that selection. This is called faceting. It happens automatically — no configuration needed for same-dataset widgets.

For widgets on different datasets, use **bindings** to propagate selections.

### Bindings
Bindings pass the current selection in one widget as a filter or value into another widget's query. Used to:
- Filter a widget on Dataset B based on a selection in Dataset A
- Build dynamic "Top N" queries where N is driven by a toggle
- Create greeting text that changes based on the current user

Bindings use SAQL result expressions: `cell(widget_name.result, row, column)`.

### Conditional Highlights
Apply colour formatting to chart bars or table cells based on value thresholds. Example: colour opportunity amounts red if below $10K, yellow if $10K–$50K, green if above $50K. Configured in the widget properties panel.

### Animated Pages
Dashboards can have multiple pages. Pages can auto-advance on a timer (animated/kiosk mode) — used for TV dashboards in sales floors or NOC screens.

### Conversational Queries (Ask Data)
Users can type natural language questions into a dashboard search bar ("What were my top accounts last quarter?") and CRM Analytics generates a visualisation. Requires the Conversational Queries feature to be enabled in Setup.

### Conditional Visibility
Widgets can be shown or hidden based on the value of another widget's selection or a dataset result. Used for guided analytics flows — show advanced filters only after a primary selection is made.

## SAQL — Salesforce Analytics Query Language

SAQL is the query language used by the CRM Analytics engine. Every widget in a dashboard executes a SAQL query behind the scenes. The Dashboard Designer generates SAQL automatically; the Advanced Editor exposes it for customisation.

### Basic SAQL Structure

```saql
q = load "dataset_api_name";
q = filter q by 'StageName' == "Closed Won";
q = group q by 'CloseDate_Year', 'OwnerId';
q = foreach q generate
    'CloseDate_Year' as 'CloseDate_Year',
    'OwnerId' as 'OwnerId',
    sum('Amount') as 'sum_Amount';
q = order q by 'sum_Amount' desc;
q = limit q 10;
```

### SAQL Clauses

| Clause | Purpose |
|---|---|
| `load` | Load a dataset by API name |
| `filter` | Apply row-level conditions. Operators: `==`, `!=`, `>`, `<`, `>=`, `<=`, `in`, `matches` |
| `group` | Group rows by one or more dimensions |
| `foreach` | Define which fields to output; apply aggregations |
| `order` | Sort results. `asc` or `desc`. |
| `limit` | Restrict result row count |
| `cogroup` | Join two datasets on a common key |
| `union` | Combine rows from two queries |

### Common Aggregations in `foreach`

```saql
sum('Amount') as 'TotalRevenue',
count() as 'RecordCount',
avg('DaysToClose') as 'AvgDays',
min('CloseDate') as 'EarliestClose',
max('Amount') as 'LargestDeal',
unique('OwnerId') as 'UniqueReps'
```

### Date Filtering

CRM Analytics date fields auto-expand to year/quarter/month/week/day parts:

```saql
q = filter q by date('CloseDate_Year', 'CloseDate_Month', 'CloseDate_Day')
    in ["2025-01-01".."2025-12-31"];
```

Or using relative dates (requires the `now()` function):

```saql
q = filter q by 'CloseDate_epoch' > (now() - 7776000);  // last 90 days in seconds
```

### Bindings in SAQL

Bindings inject user selections into SAQL queries:

```saql
// Widget "region_toggle" has a user's region selection
q = filter q by 'Region' == "{{cell(region_toggle.result, 0, \"Region\")}}";
```

### SOQL Direct Query in Dashboards

For real-time Salesforce data queries, use a SOQL step instead of SAQL:

```soql
SELECT StageName, SUM(Amount) TotalAmount, COUNT(Id) DealCount
FROM Opportunity
WHERE IsClosed = false
  AND CloseDate = THIS_YEAR
GROUP BY StageName
ORDER BY TotalAmount DESC
```

SOQL steps count against Salesforce API and governor limits — use judiciously.

## Advanced Editor

The Advanced Editor (accessible via the dashboard menu) exposes the full dashboard JSON. Used for:
- Complex bindings that the UI cannot produce
- Templated dynamic queries
- Bulk editing widget properties
- Version-controlling dashboard definitions

The JSON structure has three top-level keys:
- `datasets`: declares datasets used on the dashboard
- `steps`: defines all SAQL/SOQL queries
- `widgets`: defines layout, visual properties, and which step each widget references

## Embedding Dashboards in Salesforce

### Lightning Record Page Embedding

1. Edit the Lightning record page in App Builder
2. Drag the **CRM Analytics Dashboard** Lightning component onto the page
3. Configure: select the dashboard, choose filter fields to pass from the record context (e.g., pass `AccountId` from the record to filter the dashboard automatically)
4. Save and activate the page

### Lightning App Page / Home Page

Same as record page — drag and configure the component. On a home page, pass the current user (`{!$User.Id}`) as a filter value.

### Filtering Embedded Dashboards

Pass record field values as initial dashboard filters using the component's "Filter" properties:

| Property | Value |
|---|---|
| Filter Field | Dataset dimension API name (e.g., `Account_Id`) |
| Filter Value | Record field reference (e.g., `{!Account.Id}`) |

This ensures the embedded dashboard automatically scopes to the record being viewed.

### Mobile Dashboards

CRM Analytics dashboards render on mobile automatically. For optimal mobile UX:
- Build a separate mobile layout using the Dashboard Designer's mobile view toggle
- Limit widgets to 2 columns
- Use large metric widgets for KPIs
- Avoid complex filter rows that require fine motor interaction

## Template Apps

Salesforce ships pre-built Analytics apps for major clouds:
- **Sales Analytics** (Sales Cloud)
- **Service Analytics** (Service Cloud)
- **Financial Services Analytics** (Financial Services Cloud)
- **B2B Marketing Analytics** (Pardot/Marketing Cloud Account Engagement)

Template apps are deployed from the Analytics Studio → Create App → From Template wizard. They auto-create dataflows, datasets, and dashboards pre-wired to standard objects. Customise post-deployment — never edit the template app directly.

## Common Dashboard Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Too many widgets on one page | Slow load, all queries run on open | Split into pages or use conditional visibility |
| Using SOQL steps for large objects | Governor limits, slow queries | Extract via Data Sync + recipe instead |
| Building on dataflows when recipes available | Harder to maintain | Migrate incrementally as dataflows are touched |
| Embedding without record-context filter | Dashboard shows all-org data on a record page | Always pass record Id as filter |
| Not testing on mobile | Unusable on phone | Build mobile layout for any dashboard in mobile app |
