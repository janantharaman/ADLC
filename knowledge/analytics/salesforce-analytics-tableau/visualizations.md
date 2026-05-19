---
source: help.tableau.com — Chart types, Filters, Workspace; tableau.com/learn/get-started (2026-05-17)
product: Tableau
section: visualizations
last-updated: 2026-05-17
---

# Tableau — Visualisations, Dashboards, Stories & Filters

## The Tableau Workspace

### Key Areas

| Area | Description |
|---|---|
| **Data Pane** | Left sidebar — dimensions, measures, calculated fields, parameters, sets |
| **Analytics Pane** | Left sidebar (tab toggle) — drag-in trend lines, reference lines, forecasts, totals |
| **Columns Shelf** | Fields here define what appears across the x-axis or column headers |
| **Rows Shelf** | Fields here define what appears down the y-axis or row headers |
| **Marks Card** | Controls the appearance of each mark: Color, Size, Label, Detail, Tooltip, Shape |
| **Filters Shelf** | Applied filters — drag any field here to filter the view |
| **Canvas / View** | The visualisation area where marks are rendered |
| **Show Me** | Toolbar button — recommends chart types based on fields selected; orange outline = recommended |

### Toolbar Highlights

| Button | Function |
|---|---|
| Undo / Redo | Unlimited undo back to last file open |
| Swap | Swaps fields between Rows and Columns shelves |
| Show Me | Chart type recommendations |
| Fit | Standard / Fit Width / Fit Height / Entire View |
| Show/Hide Cards | Toggle workspace panels |

## Chart Types

### Choosing a Chart Type (Show Me Framework)

Tableau's "Show Me" panel recommends chart types based on the fields selected. The underlying logic maps data questions to chart categories:

| Question Type | Chart Type |
|---|---|
| How has X changed over time? | Line chart |
| What is the relative size of items? | Bar chart, treemap |
| How do items rank? | Sorted bar chart |
| What is the distribution? | Histogram, box plot |
| Are X and Y correlated? | Scatter plot |
| What is the part-to-whole relationship? | Pie chart, treemap, stacked bar |
| How far is X from a target/average? | Bullet graph, bar chart with reference line |
| Where is data concentrated geographically? | Map (filled or symbol) |
| How does a value move through stages? | Sankey / flow diagram |

### Core Chart Types

**Bar Chart**
- One dimension on Rows/Columns (creates headers), one measure on the other shelf (creates axis)
- Sort: click the sort icon on the axis or right-click → Sort
- Stacked bar: add a second dimension to the Color mark
- Side-by-side bar: drag a second dimension to the Columns shelf

**Line Chart**
- Date dimension on Columns (continuous = axis, discrete = headers), measure on Rows
- Multiple lines: add a dimension to the Color mark
- Dual-axis line chart: drag a second measure to Rows → right-click the second axis → Dual Axis → Synchronise Axis

**Scatter Plot**
- One continuous measure on Columns, another on Rows → marks become dots
- Colour/size the dots by a dimension or measure
- Add a trend line: Analytics pane → drag Trend Line → Linear/Polynomial/etc.
- Reference line: Analytics pane → drag Reference Line → set to Mean, Median, or custom value

**Histogram**
- One measure → Show Me → select Histogram → Tableau auto-creates bins
- Or manually: right-click a measure → Create Bins → set bin size → use the bin field as a dimension on Columns

**Box Plot**
- Right-click a measure → Show Me → Box-and-Whisker Plot
- Shows distribution: median, quartiles, outliers
- Useful for comparing distributions across categories

**Treemap**
- Multiple dimensions + one or two measures → Show Me → Treemap
- Tile size = one measure; tile colour = second measure (optional)
- Good for part-to-whole relationships with many categories

**Maps**
- Geographic dimension (Country, State/Province, City, Postal Code, Latitude/Longitude)
- Tableau auto-geocodes standard geographic roles
- **Symbol map:** each location is a circle sized/coloured by a measure
- **Filled map:** regions filled by colour (choropleth) — drag a measure to the Color mark
- **Point distribution map:** scatter of lat/long points — set Columns = Longitude, Rows = Latitude; mark type = Automatic

**Heat Map / Highlight Table**
- Two dimensions on Rows and Columns + one measure on Color → filled squares
- Good for correlation patterns across two categorical dimensions

**Bullet Graph**
- A bar chart showing actual vs target
- Add a reference line at the target value; the bar shows the actual measure
- Or use Show Me → Bullet Graph with two measures (one for value, one for target)

**Pie Chart**
- Use sparingly — only for part-to-whole with few slices (< 5)
- Drag a dimension to the Color mark, a measure to Angle on the Marks card
- Or Show Me → Pie

**Gantt Chart**
- Two date fields: one for start (on Columns), one for duration
- Mark type = Gantt Bar; duration measure on the Size mark
- Good for project timelines, case SLA tracking

**Waterfall Chart**
- Custom chart using Gantt bars with a running total table calculation
- Shows contribution of each category to a cumulative total

## Dashboards

A dashboard is a collection of sheets arranged on a single canvas.

### Creating a Dashboard

1. Click the "New Dashboard" tab at the bottom of the workbook
2. Drag sheets from the left panel onto the canvas
3. Arrange using **Tiled** layout (precise grid) or **Floating** layout (absolute positioning)

### Dashboard Layout

**Tiled:** Sheets snap to a grid. Best for structured layouts that resize predictably.  
**Floating:** Sheets are positioned at absolute coordinates. Best for overlaying elements (e.g., a filter floating over a chart).

**Device Designer:** Preview and customise layouts for Desktop, Tablet, and Phone from the dashboard toolbar.

### Dashboard Actions

Actions connect sheets on a dashboard — user interactions in one sheet trigger changes in another:

| Action Type | Trigger | Effect |
|---|---|---|
| **Filter Action** | Click a mark on Sheet A | Filters Sheet B to the selected value |
| **Highlight Action** | Hover or click on a mark | Highlights matching marks on other sheets |
| **URL Action** | Click a mark | Opens a URL (can include field values in the URL) |
| **Navigate Action** | Click a mark or button | Navigates to another sheet, dashboard, or story point |
| **Parameter Action** | Click a mark | Updates a parameter with the clicked value |
| **Set Action** | Click a mark | Adds the clicked value to a set (for dynamic top-N etc.) |

Add actions via: Dashboard menu → Actions → Add Action.

### Dashboard Layout Containers

Use Horizontal and Vertical layout containers to group sheets. Containers allow padding, background colour, and proportional resizing. Use them for clean, maintainable layouts.

## Stories

A story is a sequence of story points — each point is a snapshot of a sheet or dashboard with a caption and optional annotations. Used for data-driven presentations.

Creating a story:
1. Click "New Story" tab
2. Drag sheets or dashboards onto the story canvas
3. Add a caption for each story point
4. Use annotations on marks (right-click a mark → Annotate) for narrative context

## Filters

### Order of Operations (Filters execute in this order)

1. Extract filters
2. Data source filters
3. Context filters
4. Dimension filters
5. Measure filters (and table calculation filters — last)

**Why it matters:** A measure filter applied after a context filter only sees values that passed the context filter. Table calculation filters are always last — they do not remove underlying data.

### Filter Types

**Dimension Filters (Categorical)**

Four tabs in the Filter dialog:
- **General:** Select which values to include or exclude (checklist)
- **Wildcard:** Pattern match — `starts with`, `ends with`, `contains`, `exactly matches`
- **Condition:** Rule-based — field meets a numeric/aggregated condition (e.g., AVG(Sales) ≥ $25)
- **Top:** Relative limit — top/bottom N values by a measure (e.g., Top 15 customers by Sales)

**Measure Filters (Quantitative)**

First select aggregation type (SUM, AVG, COUNT, etc.), then choose filter mode:
- Range of Values (min/max inclusive)
- At Least (open-ended minimum)
- At Most (open-ended maximum)
- Special (null, non-null, all)

**Date Filters**

- Relative dates (dynamic — last N days/weeks/months, updates on workbook open)
- Range of dates (fixed window)
- Discrete dates (select specific quarters/months/years)
- Individual dates (specific date values)

**Context Filters**

Promote a filter to Context by right-clicking it on the Filters shelf → Add to Context. Context filters compute first, and all subsequent filters operate only on the records that pass the context filter. Use for Top N filters to work correctly: without Context, "Top 10 by Sales" may compute across all regions even when a region filter is also applied.

**Table Calculation Filters**

A calculated field placed on the Filters shelf. Executes last. Does not reduce the underlying dataset — all aggregated values are still computed before the filter is applied. Use when the filter must reference a table calculation (e.g., filter to ranks 1–10).

### Quick Filters (Filter Cards)

Show a filter as an interactive card on a sheet or dashboard:
- Right-click any field on the Filters shelf → Show Filter
- Available card modes for dimensions: Single Value List, Dropdown, Slider, Multi-value List, Wildcard
- Available for measures/dates: Range slider, At Least, At Most, Relative to Now

Filter cards can be scoped via right-click → Apply to Worksheets → All Using This Data Source / All Using Related Data Sources / Selected Worksheets.

**Gotcha:** When using Tableau Cloud or Server with large datasets, dropdown filter cards with "Only Relevant Values" option selected make an extra query per user interaction. On large data sources this causes noticeable latency — test with "All Values in Database" if performance is an issue.

## Sets

Sets are custom groupings of dimension members that can be dynamic (based on a condition or Top N) or fixed (manually selected).

Dynamic set example — Top 10 Customers by Revenue:
- Right-click the Customer Name dimension → Create Set → Top → Top 10 by Sales
- The set updates as data changes

Use sets in calculations to create "in/out" comparisons: `IF [Top 10 Customers] THEN "Top 10" ELSE "Others" END`

## Groups

Groups merge multiple dimension values into a category. Example: group 50 US states into 4 sales territories. Unlike sets, groups are static — they do not update automatically when data changes.

Create: right-click dimension values in the view → Group.
