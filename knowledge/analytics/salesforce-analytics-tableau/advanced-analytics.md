---
source: help.tableau.com — LOD Expressions; Order of Operations; Table Calculations; Trend Lines; Forecasting; Explain Data (2026-05-17)
product: Tableau
section: advanced-analytics
last-updated: 2026-05-17
---

# Tableau — Advanced Analytics Reference

## Level of Detail (LOD) Expressions

LOD expressions compute values at a **different granularity than the current view**. They appear in the Data pane as calculated fields and are wrapped in curly braces `{}`.

### Three LOD Types

| Type | Syntax | Granularity | Affected by Dimension Filters? |
|---|---|---|---|
| **FIXED** | `{FIXED [Dim1], [Dim2] : AGG([Measure])}` | Specified dimensions only | ❌ No (computed before dimension filters) |
| **INCLUDE** | `{INCLUDE [Dim] : AGG([Measure])}` | View dimensions + extra dimension | ✅ Yes |
| **EXCLUDE** | `{EXCLUDE [Dim] : AGG([Measure])}` | View dimensions minus specified | ✅ Yes |

**Table-scope LOD** (no dimensions specified):
```
{SUM([Sales])}        ← grand total of all sales regardless of view
{AVG([Discount])}     ← average discount across entire table
```

### FIXED — Key Behaviours

- Computes at specified dimensions regardless of what is in the view
- Example: `{FIXED [Region] : SUM([Sales])}` always gives region-level total even in a view broken down by city
- Can produce **dimensions** (if based on a date/string field) or **measures** (if based on a numeric field)
- **Critical:** FIXED ignores dimension filters — must promote those filters to **Context Filters** if they should affect FIXED expressions
- When placed on a shelf, Tableau auto-wraps: `SUM({FIXED [Segment] : SUM([Sales])})`

### INCLUDE — Key Behaviours

- Adds extra dimensions beyond what's in the view
- Always produces **measures**
- Results have same or **finer** granularity than the view → values are never replicated
- Use case: compute an average at a finer level, then aggregate back up

```
// Average sales per order in each region
{INCLUDE [Order ID] : SUM([Sales])}
// Then AVG() of this in a region-level view gives avg order size per region
```

### EXCLUDE — Key Behaviours

- Removes dimensions from the current view's level of detail
- Always produces **measures**
- Always causes **replicated values** — Tableau defaults to `ATTR` aggregation to signal this
- Use case: compute percent of total that respects filters

```
// Percent of total that adjusts when dimension filters applied
SUM([Sales]) / SUM({EXCLUDE [Sub-Category] : SUM([Sales])})
```

### Common LOD Patterns

**Compare row to overall average:**
```
[Sales] - {FIXED : AVG([Sales])}
```

**Cohort first order date:**
```
{FIXED [Customer ID] : MIN([Order Date])}
```

**Customer lifetime value:**
```
{FIXED [Customer ID] : SUM([Sales])}
```

**Ratio of part to whole (stable despite filters):**
```
SUM([Sales]) / ATTR({FIXED : SUM([Sales])})
```

**Max sales per category:**
```
{FIXED [Category] : MAX([Sales])}
```

### LOD Limitations

- Floating-point measures can behave unreliably in LOD comparisons
- LOD expressions do not appear on the Data Source page
- Data blending: linking field from primary source must be in view before secondary-source LOD expressions work
- Not supported on: Microsoft Access, Splunk, multidimensional cubes, Actian Vectorwise, DataStax Enterprise, and some legacy connectors

---

## Order of Operations (Query Pipeline)

Tableau applies filters and calculations in a fixed sequence. Understanding this order is essential for predictable results.

### Pipeline (top = earliest, bottom = latest)

| Step | Notes |
|---|---|
| 1. **Extract Filters** | Limit data in the extract file itself |
| 2. **Data Source Filters** | Apply to entire workbook, all worksheets |
| 3. **Context Filters** | Per-worksheet; run before all other worksheet filters |
| 4. **FIXED LOD Expressions** | Computed here — before dimension filters |
| 5. **Dimension Filters** | Including Top N filters (simultaneous) |
| 6. **INCLUDE / EXCLUDE LOD** | Computed after dimension filters |
| 7. **Measure Filters** | Filter on aggregated measure values |
| 8. **Table Calculation Filters** | Applied after table calcs run |

### Critical Interactions

**FIXED ignores dimension filters:**
A FIXED LOD computes at step 4, before dimension filters (step 5). Filtering out California does not reduce a FIXED total.
Fix: promote the filter to a **Context Filter** (right-click filter → Add to Context).

**Table calculations see filtered data:**
Table calcs (step 8) run after dimension filters. A `RUNNING_SUM` or `PERCENT OF TOTAL` table calc will recalculate based on whatever is left after filtering.
Fix: replace with a FIXED LOD expression for stable denominators.

**Top N + Dimension filters are simultaneous:**
A view with both a "Top 10" filter and a "Region = West" filter runs them at the same level. The Top 10 is from the already-region-filtered set.
Fix: if you want "Top 10 nationally, shown only for West", make the West filter a Context Filter.

---

## Table Calculations

Table calculations transform values using the **visible result set in the view** — not raw data. They run last in the order of operations.

### The Virtual Table

Every view has a virtual table determined by all dimensions on Rows, Columns, Pages, and Marks (Color, Size, Label, Detail, Path). Table calculations operate within this virtual table.

### Partitioning vs Addressing

- **Addressing fields:** The dimensions the calculation traverses (the direction of movement)
- **Partitioning fields:** The dimensions that define independent scope (calculation restarts per partition)

All dimensions in the level of detail are either addressing or partitioning.

### Compute Using Options

| Option | Behaviour |
|---|---|
| **Table (across)** | Across columns, restarts each row |
| **Table (down)** | Down rows, restarts each column |
| **Table (across then down)** | Across columns then wraps down |
| **Table (down then across)** | Down rows then wraps across |
| **Pane (down)** | Down within each pane |
| **Pane (across then down)** | Across then down within pane |
| **Cell** | Single cell scope |
| **Specific Dimensions** | Manually designate addressing vs partitioning fields |

### Specific Dimensions + "At the Level"

When using Specific Dimensions: checked = addressing (the calculation moves across these), unchecked = partitioning (the calculation resets here).

The **At the Level** option (available with multiple addressing fields) sets a positional break point — like positional partitioning. Options: Deepest (default), or a named dimension level.

### Quick Table Calculations

Right-click a measure on a shelf → Quick Table Calculation:

| Quick Calc | What It Does |
|---|---|
| Running Total | Cumulative sum from first row |
| Difference | Current minus previous value |
| Percent Difference | ((Current - Previous) / Previous) × 100 |
| Percent of Total | Value / total of partition |
| Rank | Rank within partition |
| Percentile | Percentile within partition |
| Moving Average | Average over sliding window |
| YTD Total | Cumulative sum resetting each year |
| Compound Growth Rate | CAGR over the partition |
| Year over Year Growth | Current year vs same period prior year |
| YTD Growth | YTD total vs same YTD prior year |

### Gotchas

- Table calcs recompute when you filter — a "% of total" changes when you exclude categories
- Partitioning by **Compute Using** = value-based; by **At the Level** = position-based (subtle but important)
- Order of fields in Specific Dimensions (top to bottom) defines the direction the calculation travels

---

## Trend Lines

Trend lines project data patterns using statistical models. Add via: Analytics pane → drag **Trend Line** → drop on model type.

### Requirements
- Both axes must contain fields interpretable as numbers
- Not available with stacked bars
- Multidimensional date hierarchies stored as strings are not supported

### Model Types

| Model | Formula | Notes |
|---|---|---|
| **Linear** | `Y = b0 + b1 * X` | Most common; slope b1, intercept b0 |
| **Logarithmic** | `Y = b0 + b1 * ln(X)` | Filters out negative X values |
| **Exponential** | `Y = exp(b0) * exp(b1 * X)` | Filters negative Y; no confidence bands |
| **Power** | `Y = b0 * X^b1` | Both variables log-transformed before estimation |
| **Polynomial** | `Y = b0 + b1*X + b2*X^2 + ...` | Degree 2–8; for non-linear curved patterns |

### Confidence Bands

Tableau shows 95% confidence bands by default. Not available for exponential models.

### Statistics on Hover

Hovering a trend line shows:
- **Equation** (coefficients)
- **R²** (proportion of variance explained; 1.0 = perfect fit)
- **P-value** (≤ 0.05 generally considered significant)

### Options

- Show per-colour trend lines or a single unified line across all mark colours
- Exclude specific fields as factors
- Force y-intercept through zero (requires continuous fields on both axes)
- Show recalculated lines on selection/highlight

---

## Forecasting

Tableau forecasting extrapolates trends using **exponential smoothing models**, which weight recent observations more heavily than older ones.

### Availability

Requires: at least one date dimension + at least one measure.

Without a date dimension, forecasting is possible if an **integer-valued dimension** exists.

**Not available** when the view contains:
- Table calculations
- Disaggregated measures
- Percent calculations
- Grand Totals or Subtotals
- Exact Date aggregation

Not supported for multidimensional data sources on Windows.

### Enabling

- Right-click → Forecast → Show Forecast
- Or: Analysis menu → Forecast → Show Forecast

### Configuration

Forecasting is automatic but configurable (Forecast Options):
- Forecast length
- Forecast model (automatic or choose exponential smoothing type)
- Ignore last N periods (to exclude incomplete periods)
- Prediction intervals

### Web Authoring Limitation

Published views can be viewed with forecasting, but **web editing cannot modify or add forecasts** — must be done in Desktop.

---

## Explain Data (Data Guide)

Explain Data automatically identifies statistical explanations for why a specific mark's value is unusually high or low.

### How to Access

- Open **Data Guide** pane (toolbar icon)
- Or: hover a mark → tooltip → Data Guide icon
- Analysis scope:
  - Dashboard-level: scans for outliers across the view
  - Sheet-level: analyzes marks in that sheet
  - Mark-level: explains a single mark

### Key Concepts

| Term | Meaning |
|---|---|
| **Analyzed mark** | The specific data point under examination |
| **Expected value** | Median of predicted values between 15th–85th percentile |
| **Higher than expected** | Mark value falls above the predicted range |
| **Lower than expected** | Mark value falls below the predicted range |
| **Unvisualized fields** | Fields in the data source not currently in the view — Explain Data uses these as explanatory factors |
| **Distribution** | All possible values and their frequency of occurrence |

### Data Requirements

- Measures must use **SUM, AVG, COUNT, COUNTD, or AGG**
- Single primary data source only
- Blended or cube data sources: **not supported**
- Only **one mark** at a time — no multi-mark comparison

### Permissions

Viewers need specific permission to view explanations. Authors control which fields are included in analysis via Explain Data Settings.
Creators/Explorers can additionally open explanation visualizations as new worksheets.
