---
source: help.tableau.com — Filtering; Filter Cards; Context Filters; Global Filters; Order of Operations; Parameters (2026-05-17)
product: Tableau
section: filters-deep-dive
last-updated: 2026-05-17
---

# Tableau — Filters Deep Dive

## Filter Order of Operations

Filters execute in a fixed sequence. Understanding this is critical for predictable results.

| Order | Filter Type | Notes |
|---|---|---|
| 1 | **Extract Filters** | Applied when extract is created — limits rows in the .hyper file |
| 2 | **Data Source Filters** | Apply to entire workbook; all worksheets |
| 3 | **Context Filters** | Per-worksheet; run before all other worksheet-level filters |
| 4 | **FIXED LOD Expressions** | Computed before dimension filters |
| 5 | **Dimension Filters** | Simultaneous — Top N and dimension filters run at the same level |
| 6 | **INCLUDE / EXCLUDE LOD** | Run after dimension filters |
| 7 | **Measure Filters** | Filter on aggregated measure values |
| 8 | **Table Calculation Filters** | Run last — do not remove underlying data |

---

## Creating Filters

### Method 1: Select Marks Directly

Click a mark or drag to select multiple marks → tooltip bar shows **Keep Only** and **Exclude** buttons.
- **Keep Only** — retains only selected marks, filters out all others
- **Exclude** — removes selected marks, shows everything else

Not available when a Wildcard Match filter is already active on the same field.

### Method 2: Select Headers

Click row or column headers → Exclude or Keep Only. Selecting a hierarchical header automatically selects all child members beneath it.

### Method 3: Drag to Filters Shelf

Drag any field from the Data pane onto the Filters shelf → Filter dialog opens.

---

## Filter Types by Data Type

### Categorical Filters (Dimensions) — Four Tabs

**General tab:** Select / deselect individual members. Options:
- Use All — includes all current and future members
- Select From List — manual member selection

**Wildcard tab:** Pattern matching using `*` as wildcard.
- Contains, Starts with, Ends with, Exactly matches
- Not case-sensitive

**Condition tab:** Rule-based filtering using aggregated measures or calculated conditions.
- Examples: `AVG([Price]) >= 25`, `SUM([Sales]) > 100000`

**Top tab:** Limit results by rank.
- By Field: e.g., Top 10 Products by SUM(Sales)
- By Formula: custom expression for ranking

All four tabs are **cumulative** — they are applied left to right (an AND relationship).

### Quantitative Filters (Measures)

First select aggregation (SUM, AVG, MIN, MAX, COUNT, etc.), then choose:

| Option | Behaviour |
|---|---|
| **Range of Values** | Min and max — both inclusive |
| **At Least** | All values ≥ a minimum |
| **At Most** | All values ≤ a maximum |
| **Special** | Null / non-null / all values |

**Performance tip:** For large data sources, replacing a measure filter with a **Set** based on the same condition can significantly improve query speed.

### Date Filters

| Option | Behaviour |
|---|---|
| **Relative Dates** | Dynamic range that updates when the workbook is opened (e.g., last 30 days, year-to-date); can be anchored to a specific date |
| **Range of Dates** | Fixed start and end date |
| **Discrete Dates** | Filter entire date levels (quarters, months, years, etc.) |
| **Individual Dates** | Specific date selections |
| **Latest Date Preset** | When using discrete dates — "Filter to latest date value when workbook is opened" |

### Table Calculation Filters

Built by placing a calculated field (that contains a table calculation) on the Filters shelf.
- Run **last** in the order of operations
- Do not remove underlying data — only affect what is displayed
- "Apply to totals" option available when totals are shown in the view

---

## Context Filters

Context filters run **before** all other worksheet-level filters (step 3 in the order of operations). They function as a pre-filter that limits the dataset before dimension filters, measure filters, and table calculations run.

### When to Use Context Filters

**1. Top N with a dimension filter:**
Without context: A "Region = West" filter and a "Top 10 by Sales" filter run simultaneously — you get "Top 10 overall, shown only for West."
With context on the Region filter: Region = West runs first (step 3), then Top 10 picks from the West-only dataset → "Top 10 within West."

**2. FIXED LOD respecting a filter:**
FIXED LOD runs at step 4, before dimension filters (step 5). A dimension filter cannot affect a FIXED expression unless it is promoted to a context filter.
Promote the filter: right-click the filter pill on the Filters shelf → **Add to Context**

**3. Performance on large datasets:**
A context filter reduces the overall data set before dimension and measure filters execute — can significantly speed up queries on large tables.

### Creating a Context Filter

Right-click any filter on the Filters shelf → **Add to Context**

The filter pill turns grey on the Filters shelf to indicate it is now a context filter.

### Context Filter Scope

Context filters are **per-worksheet** — unlike data source filters which apply workbook-wide. The "latest date filter" uses workbook-level context (not per-worksheet).

---

## Global / Cross-Sheet Filter Scope

Right-click a filter on the Filters shelf to set its scope:

| Scope | Behaviour |
|---|---|
| **Only This Worksheet** | Default. Local to current sheet. No icon shown. |
| **All Using This Data Source** | All worksheets sharing the same primary data source. Global — auto-applies to new sheets using this source. |
| **All Using Related Data Sources** | All worksheets using related data sources. Auto-applies to new related sheets. |
| **Selected Worksheets** | Opens a dialog — manually pick target sheets. Chosen filter overrides any existing filter on the same field in those sheets. |

**Reverting a global filter** to "Only This Worksheet" disconnects the filter from other sheets (each becomes independent) rather than removing it.

**Dashboard-level filtering:** Within a dashboard → filter pill right-click → Apply to Worksheets → Selected Worksheets → "All on dashboard."

---

## Interactive Filter Cards

Show a filter card to give viewers interactive filtering controls.

**Show a filter card:**
- Right-click a field in the Data pane → Show Filter
- Or add the field to Filters shelf — in web authoring it appears automatically

### Filter Card Display Modes

**For Categorical Dimensions:**

| Mode | UI Control |
|---|---|
| Single Value (List) | Radio buttons — one selection |
| Single Value (Dropdown) | Dropdown — one selection |
| Single Value (Slider) | Slider — useful for ordered dimensions |
| Multiple Values (List) | Checkboxes — multiple selections |
| Multiple Values (Dropdown) | Dropdown with checkboxes |
| Multiple Values (Custom List) | Type or paste values to build a custom list |
| Wildcard Match | Text entry with `*` wildcard; not case-sensitive |

**For Measures / Dates:**

| Mode | UI Control |
|---|---|
| Range of Values / Dates | Dual slider with data bar |
| At Least / Starting Date | Open-ended lower bound |
| At Most / Ending Date | Open-ended upper bound |
| Relative to Now | Dynamic date range (continuous dates only) |
| Browse Periods | Preset ranges — day, week, month, etc. |

**Data bar:** The strip inside range sliders shows the actual distribution of values — only visible when the filtered field is also in the view at the same aggregation level.

### Filter Card Options (right-click the card header)

- **Edit Filter** — reopens the Filter dialog
- **Remove Filter** — removes from shelf and view
- **Apply to worksheets** — scope control
- **Only relevant values** — shows values passing other active filters
- **All values in database** — ignores all other filters
- **All values in context** — shows values passing context filters only
- **Include/Exclude values** — toggle filter mode
- **Hide Card** *(Desktop only)* — hides the card without removing the filter

### Filter Card Customization *(Desktop only)*

Right-click the filter card header → **Customize:**

| Option | Effect |
|---|---|
| Show All Value / Show Only Relevant Values | Toggle "All" option at top of list |
| Show Search | Search box within the filter list |
| Show Include/Exclude toggle | Allows viewers to switch between include and exclude modes |
| Allow changing filter type | Lets viewers change between single/multi-select modes |
| Show More/Fewer | Collapses long lists |
| Show Apply button | Defers filter execution until user clicks Apply |
| Show "Show All Values" button | Displays a red indicator when values are excluded |
| Show Null Controls | Options to include / exclude / show only null values |

---

## Aggregation Behaviour

### Automatic Aggregation

When a measure is added to a view, Tableau auto-aggregates it. The current aggregation shows in the field name (e.g., `SUM(Sales)`). Each measure has a default aggregation set at the data source level.

Aggregation only works for **relational data sources** — multidimensional sources are pre-aggregated at the source.

### Available Aggregations

| Aggregation | Behaviour |
|---|---|
| SUM | Sum of all values |
| AVG | Arithmetic mean; nulls ignored |
| MIN / MAX | Minimum or maximum value |
| COUNT | Count of non-null rows |
| COUNT DISTINCT (COUNTD) | Count of unique non-null values |
| MEDIAN | Median; nulls ignored |
| STDEV / STDEVP | Sample / population standard deviation |
| VAR / VARP | Sample / population variance |
| **ATTR** | Returns the value if all rows share the same value; returns `*` (asterisk) if multiple values exist |

**ATTR formula:** `IF MIN([dim]) = MAX([dim]) THEN MIN([dim]) ELSE "*" END`

Use ATTR for:
- Dimensions in data blending (required for dimension fields from secondary source)
- Dimensions in table calculations (which require aggregate expressions)
- Confirming a dimension has a single value at the current granularity

### Disaggregating Measures

Toggle via **Analysis → Aggregate Measures** (uncheck).

Shows a separate mark for every individual row in the data source — reveals the raw data distribution without aggregation. Useful for scatter plots to surface outliers. **Caution:** can severely degrade performance on large data sources.

---

## Parameters (Reference)

A parameter is a workbook variable (number, date, string, or boolean) that substitutes into calculations, filters, and reference lines.

### Creating a Parameter

Data pane → dropdown → **Create Parameter**

Configuration:
- **Name** — appears as the control label
- **Data Type** — Integer, Float, String, Boolean, Date, Date & Time
- **Current Value** — default value
- **Allowable Values:**
  - *All* — free text entry, no restrictions
  - *List* — discrete values; import from a field, type manually, or paste
  - *Range* — min, max, step (not available for String type)
- **Display Format** — *(Desktop only)*

### Using Parameters

**In a calculated field:**
```
IF [Sales] > [Min Sales Threshold] THEN "Above Target" ELSE "Below Target" END
// [Min Sales Threshold] is a parameter
```

**In a Top N filter:**
Filter dialog → Top tab → By Field → select parameter as the N value

**In a reference line:**
Analytics pane → Reference Line → Value dropdown → select parameter

**In a set action:**
Dashboard action updates the parameter value on mark interaction

### Showing Parameter Controls

Right-click parameter in Data pane → **Show Parameter**

Display modes:
- Slider (Range and numeric types)
- Compact list (List type)
- Radio buttons (List type with few values)
- Type-in field (All and exact match)

### Dynamic Parameters

A parameter can automatically refresh its value from a field:
- Refresh a **current value** from a single-value FIXED LOD expression
- Refresh a **list** from a field (shows current unique values)
- Refresh a **range** min/max from field min/max

Refresh occurs: when workbook opens, or on manual data refresh.

**Avoid dynamic parameters in extract filters** — Tableau must evaluate the full dataset before filtering, degrading performance.

### Parameter Troubleshooting

Default fallback values when a dynamic refresh fails:
- Integer → `1`
- Float → `1.0`
- String → `""` (empty)
- Date → current date

Common failure causes: field returns multiple values, data type mismatch, source field deleted, user cancels the query.
