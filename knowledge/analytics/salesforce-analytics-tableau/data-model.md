---
source: help.tableau.com — Dimensions and Measures; Calculated Fields; Workspace overview; get-started-tutorial; (2026-05-17)
product: Tableau
section: data-model
last-updated: 2026-05-17
---

# Tableau — Data Model: Dimensions, Measures & Calculated Fields

## Core Data Concepts

### Dimensions vs Measures

Every field in Tableau is either a **dimension** or a **measure**. This classification drives how Tableau aggregates and displays data.

| Concept | Dimensions | Measures |
|---|---|---|
| **Nature** | Qualitative / categorical | Quantitative / numeric |
| **Role** | Group and segment data | Values to aggregate |
| **SQL analogy** | GROUP BY columns | Aggregated columns (SUM, COUNT, AVG) |
| **Examples** | Region, Category, Customer Name, Order Date | Sales, Quantity, Profit, Discount |
| **Default pill colour** | Blue | Green |

Tableau auto-classifies fields when you connect to a data source: strings → dimensions, numbers → measures, dates → dimensions (but can be used as measures).

**Gotcha:** Numeric IDs (Customer ID, Postal Code, Phone Number) are classified as measures by default but should be converted to dimensions — they should never be summed or averaged.

### Discrete vs Continuous

This is separate from dimension/measure. Each field is also either discrete or continuous:

| | Discrete (Blue) | Continuous (Green) |
|---|---|---|
| **Definition** | Individually separate, distinct values | Forms an unbroken range |
| **On Rows/Columns** | Creates **headers** | Creates an **axis** |
| **On Colour** | Categorical palette (one colour per value) | Quantitative gradient |
| **On Filters** | Choose which members to include | Specify a min/max range |

This gives four combinations:
1. **Discrete Dimension** (Blue) — e.g., Product Category → creates column headers
2. **Continuous Dimension** (Green) — e.g., Order Date as a range → creates a date axis
3. **Discrete Measure** (Blue) — e.g., SUM(Sales) formatted as headers → unusual, used in crosstabs
4. **Continuous Measure** (Green) — e.g., SUM(Sales) on an axis → standard bar/line chart

Converting between discrete and continuous: right-click the pill → Convert to Discrete / Convert to Continuous.

### Level of Detail

Adding a dimension to the view increases the level of detail — more distinct combinations of dimension values → more marks.

Example:
- 4 Regions → 4 marks
- 4 Regions × 3 Segments → 12 marks
- 4 Regions × 3 Segments × 12 Months → 144 marks

Dimensions placed on the Marks card (Color, Size, Detail, Tooltip) also increase detail without adding headers or axes.

## Data Pane

The Data pane (left sidebar in the worksheet view) shows:
- **Dimensions** section: categorical fields (blue icon)
- **Measures** section: numeric fields (green icon)
- **Sets, Parameters, Calculated Fields** appear at the bottom of their respective sections

Fields with an `=` icon are calculated fields. Fields with a `#` icon are numeric measures. Fields with `Abc` are string dimensions.

## Calculated Fields

Calculated fields create new columns derived from existing data. The original data is never modified — calculations are computed at query time.

### Creating a Calculated Field

Analysis menu → Create Calculated Field  
Or right-click in the Data pane → Create Calculated Field

Name the field, write the formula, click OK. The field appears in the Data pane with an `=` icon.

Editing: right-click the field → Edit. Changes propagate to all sheets using that field immediately.

### Three Types of Calculated Fields

#### 1. Basic (Row-Level or Aggregate)

Operate either on individual rows or on aggregated values.

**Row-level example:**
```
[Sales] - [Cost]
// Returns a new measure: gross profit per row
```

**Aggregate example:**
```
SUM([Profit]) / SUM([Sales])
// Profit margin: computed on the aggregated totals in the view
```

**Type-conversion:**
```
DATEPARSE("yyyy-MM-dd", [Date_String])
// Convert a string field to a date
```

**Conditional logic:**
```
IIF([Sales] != 0, [Discount] / [Sales], 0)
// Discount ratio, avoiding divide-by-zero

IF [Category] = "Technology" THEN "Tech"
ELSEIF [Category] = "Furniture" THEN "Furn"
ELSE "Other"
END
```

#### 2. LOD (Level of Detail) Expressions

LOD expressions give explicit control over the granularity at which a calculation is performed — independent of what dimensions are in the view.

Three keywords:

| Keyword | Behaviour | Use Case |
|---|---|---|
| `FIXED` | Compute at the specified dimensions, ignoring the view's LOD | Cohort analysis, customer-level totals shown at order-level detail |
| `INCLUDE` | Compute at a finer granularity than the view (more detailed) | Add a dimension to the calc that isn't in the view |
| `EXCLUDE` | Compute at a coarser granularity (less detailed) | Remove a dimension from the calc that is in the view |

**FIXED example — customer total revenue (used in customer-level scatter):**
```
{ FIXED [Customer Name] : SUM([Sales]) }
// Each customer gets their total — regardless of what other dimensions are in view
```

**INCLUDE example — average order value per product per customer:**
```
{ INCLUDE [Order ID] : SUM([Sales]) }
// Adds Order ID granularity to the calc even if Order ID is not in the view
```

**EXCLUDE example — percentage of total (exclude Region from a Region-breakdown view):**
```
SUM([Sales]) / { EXCLUDE [Region] : SUM([Sales]) }
// Percent of total: numerator is regional sales; denominator is all-region sales
```

#### 3. Table Calculations

Table calculations transform values using the marks already in the view. They operate **after** aggregation — on the result set, not on the raw data.

Key table calculations (accessible via Quick Table Calculation or custom formula):
- **Running Total:** `RUNNING_SUM(SUM([Sales]))`
- **Percent of Total:** `SUM([Sales]) / TOTAL(SUM([Sales]))`
- **Rank:** `RANK(SUM([Sales]))`
- **Period-over-Period (LOOKUP):** `SUM([Sales]) - LOOKUP(SUM([Sales]), -1)` (difference from prior period)
- **Moving Average:** `WINDOW_AVG(SUM([Sales]), -2, 0)` (3-period moving average)

Table calculations are computed on the Tableau server/desktop side, not pushed to the database. They are affected by the `Compute Using` setting (Table Down, Table Across, Specific Dimensions).

**Gotcha:** Table calculation filters do not remove underlying data — they are applied last in the order of operations. If a user filters to "Top 10" using a table calc, the underlying data for ranks 11+ still exists and affects percentage-of-total calculations.

## Parameters

Parameters are user-controlled variables that can substitute values in calculations, reference lines, filters, and bin sizes.

Creating a parameter: Data pane → right-click → Create Parameter. Set data type (integer, float, string, date, boolean), allowable values (all, list, range), and current value.

Using a parameter in a calculated field:
```
IF [Sales] > [Min Sales Threshold]
// [Min Sales Threshold] is a parameter — user sets the threshold value at runtime
```

Show the parameter control: right-click the parameter → Show Parameter Control.

## Data Types

| Tableau Type | Icon | Notes |
|---|---|---|
| String | Abc | Text; always a dimension |
| Number (decimal) | # | Measure by default |
| Number (whole) | # | Measure by default |
| Date | Calendar | Dimension by default; can be continuous |
| Date & Time | Calendar with clock | Dimension by default |
| Boolean | T/F | Dimension (True/False) |
| Geographic | Globe | Dimension; enables map chart |

Type conversions: `STR()`, `INT()`, `FLOAT()`, `DATE()`, `DATEPARSE()`.
