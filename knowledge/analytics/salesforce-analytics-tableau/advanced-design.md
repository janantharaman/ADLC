---
source: help.tableau.com — Maps; Sets; Groups; Bins; Shelves & Marks; Dashboard Actions; Performance; Best Practices (2026-05-17)
product: Tableau
section: advanced-design
last-updated: 2026-05-17
---

# Tableau — Advanced Design Reference

## Maps

### When to Use Maps

Maps answer **spatial questions** — only use them when geography is central to the question. A bar chart often beats a map for simple state-level comparisons.

### Map Types

| Type | Best For | Example |
|---|---|---|
| **Proportional Symbol** | Quantitative data at locations | Earthquake magnitude by city |
| **Choropleth (Filled Map)** | Ratio / aggregated data per geographic region | Obesity rates by county |
| **Point Distribution** | Approximate locations, visual clustering | Hailstorm incident locations |
| **Density (Heatmap)** | Trends within geographic clusters | Taxi pickup hotspots |
| **Flow (Path)** | Movement over time | Storm track paths |
| **Spider (Origin-Destination)** | Origin ↔ destination relationships | Bike share ride start/end |

### Geographic Roles

Assign via Data pane → click the data type icon → Geographic Role → choose role. Tableau then auto-generates Latitude and Longitude measures.

| Role | Field Should Contain |
|---|---|
| **Country/Region** | Country names or ISO 3166-1 alpha-2/alpha-3 codes |
| **State/Province** | First-level admin divisions worldwide |
| **County** | Second-level admin divisions (US counties, French départements) |
| **City** | Cities with population 15,000+ worldwide (multiple languages) |
| **ZIP Code/Postcode** | Postal codes (US, Australia, Germany, and others) |
| **CBSA/MSA (US)** | Core Based Statistical Area codes or names |
| **Congressional District (US)** | US congressional district names/numbers |
| **NUTS Europe** | NUTS levels 1–3 codes and names |
| **Airport** | IATA or ICAO airport codes |
| **Area Code (US)** | US telephone area codes (numbers only) |
| **Latitude / Longitude** | Decimal degree values — numeric fields only |

For unrecognised locations, import **custom geocoding**: Map → Geocoding → Import Custom Geocoding.

### Building a Map

**Symbol (point) map:**
1. Double-click a geographic field — Tableau auto-places generated Lat/Long and creates a map
2. Drag a measure to **Size** → proportional symbol map
3. Drag a measure to **Color** → colour-encoded symbol map

**Filled (choropleth) map:**
1. Double-click a geographic field
2. Marks card → Mark Type → **Map** → region boundaries appear
3. Drag a measure to **Color** → choropleth

**Density map:**
1. Drag Latitude and Longitude fields to the canvas
2. Add a measure to Detail
3. Marks card → Mark Type → **Density**
4. Use Intensity slider to adjust concentration vividness

### Supported Spatial File Formats

- Esri Shapefiles (`.shp`)
- MapInfo tables (`.tab`)
- KML files (`.kml`)
- GeoJSON (`.geojson`)
- TopoJSON

### Background Map Options

| Map Style | Characteristics |
|---|---|
| **Light** | Emphasises marks; non-data areas in white/light grey |
| **Normal** | General-purpose; water in light blue |
| **Dark** | Inverted; non-data areas in black/dark grey |
| **Streets** | Includes major roads and transit networks |
| **Outdoors** | Terrain and natural features, parks |
| **Satellite** | Global satellite imagery |
| **Offline** | Cached locally — no internet connection required |
| **None** | Plots lat/long without any background |

Change via: **Map → Background Maps → [style]**

#### WMS (Web Map Service)

Legacy feature for custom WMS servers as background maps. Saves as `.tmsd` in `My Tableau Repository/Mapsources`.

#### Offline Maps

Cached at:
- **Windows:** `C:\Program Files\Tableau\<Version>\Local\Maps`
- **Mac:** `//Applications/<Version>.app/Contents/install/local/maps`

Reconnect to online maps when: toggling uncached layers, zooming to uncached levels, or panning beyond stored imagery.

### Custom Geocoding

Use when Tableau doesn't recognise your location names (e.g., custom territories, internal regions, postal code formats from unsupported countries).

Import custom geocoding: **Map → Geocoding → Import Custom Geocoding**

Required CSV format: geocoding file with columns matching location type and coordinates.

### Density Maps

Add more marks than a proportional symbol map can show clearly. Configuration: Marks card → change mark type to **Density**.

### Origin-Destination (Spider / Flow) Maps

Visualize paths between locations. Two data structure approaches:

**Row-per-location approach (most common):**
- Two rows per path: one origin row, one destination row
- A Path ID column combining origin + destination (e.g., `"NYC_LAX"`)
- Latitude/Longitude on each row
- Marks card: Line mark type, Path ID on Detail, right-click Lat/Long → Dimension (not aggregate)

**Path-order approach (for multi-stop routes):**
- One row per stop on a path
- Path ID column grouping stops that belong to one route
- Order of Points column defining draw sequence
- Marks card: Line mark type, Path ID on Detail, Order field on Path shelf, right-click Order → Dimension

**MAKELINE alternative:**
If origin and destination are on the **same row**, use the `MAKELINE` spatial function to draw lines directly — no Path shelf needed.

**Dynamic filtering by hub:**
Create a parameter (e.g., `SelectedHub`), then a calculated field that parses the Path ID string to classify rows as "Origin," "Destination," or "Unselected." Filter to show only paths where the selected hub is the origin or destination.

### Map Layers Pane

**Map → Map Layers** opens a pane to toggle background detail:
- Country/region borders and names
- State/province borders and names
- County borders
- City names (at appropriate zoom levels)
- Zip code boundaries
- Roads and highways
- Terrain and topography
- Coastlines and water bodies

Toggling layers that aren't in the offline cache requires an internet connection.

---

## Dashboard Actions

Actions connect views within dashboards and enable interactive navigation. They execute in this order: Parameter → Set → Filter → Go to Sheet → Highlight → Go to URL. Within each type, actions run **alphabetically** by name.

### Action Types

| Type | Purpose |
|---|---|
| **Filter** | Use selected marks to filter another sheet's data |
| **Highlight** | Highlight matching marks on another sheet, dimming all others |
| **Go to URL** | Open an external URL or file path |
| **Go to Sheet** | Navigate to another worksheet, dashboard, or story |
| **Change Parameter** | Update a parameter value by interacting with a mark |
| **Change Set Values** | Update a set's membership by interacting with marks |

### Filter Action Configuration

1. **Dashboard → Actions → Add Action → Filter**
2. **Source sheet:** which sheet triggers the action
3. **Run on:** Hover / Select / Menu
   - **Hover:** triggers on mouseover
   - **Select:** triggers on click (optionally limit to single-select only)
   - **Menu:** appears in the tooltip as a right-click option (name the action well — it becomes the tooltip label)
4. **Target sheets:** which sheets receive the filter
5. **Cleared selection behaviour:**
   - **Leave the filter** — maintains filtered results when deselected
   - **Show all values** — removes filter on deselection
   - **Exclude all values** — hides everything when nothing selected (useful for "show only when selected" patterns)
6. **Selected fields:** All Fields or specific fields

#### Matching Logic

- Relational sources: can cross-link even when field names differ
- Multidimensional sources: require the same data source and matching field names

#### Limitation

Filter actions using `USERNAME()` or row-level security user functions will not work correctly due to how security is evaluated server-side.

### Highlight Action

Dims non-matching marks while highlighting matching ones — keeps all data visible in context (unlike filter which removes non-matching marks).

Best for interactive dashboard exploration where you want to preserve the full data context. Configure custom fields to match on, and source/target sheets to apply the highlight to.

**Highlight vs Filter:**
- Use **Highlight** when keeping all marks visible (context-preserved) is important
- Use **Filter** when non-matching data should be removed from view

### URL Action

Opens an external URL, file, or email. Can open in new tab or within a dashboard web page object.

**URL template with field substitution:**
- Use the Insert menu in the URL field to insert `<FieldName>` placeholders
- Referenced fields **must exist in the view** — add to Marks Detail shelf if not otherwise visible
- Parameter display values are sent by default; to send actual value, append `~na`: `http://<IPAddress~na>/page.htm`

**URL prefix requirements:** must begin with `http`, `https`, `ftp`, `mailto`, `news`, `gopher`, `tsc`, `tsl`, `sms`, or `tel`

**Email pattern:**
```
mailto:<EmailField>?subject=Your Subject&body=<DataField>
```
Use `%0a` as delimiter for multi-value email body lists.

**Run on Menu** works particularly well for URL actions (descriptive name becomes the tooltip link text).

### Parameter Action Configuration

**Dashboard → Actions → Add Action → Change Parameter**

Lets the audience click a mark to update a parameter value. The parameter drives calculations, reference lines, or Top N filters elsewhere on the dashboard.

**Use patterns:**
- Click a category bar → update a "Selected Category" parameter → drives a detail table below
- Click a time period → update a date parameter → drives a comparison chart
- Dual-axis chart where clicking a bar updates a parameter driving a target reference line

### Set Action Configuration

**Dashboard → Actions → Add Action → Change Set Values**

Clicking marks updates the membership of a set. The target views immediately reflect the updated set.

**Set membership update modes:**
- **Assign values** — replaces all current members with selected marks
- **Add values** — appends selected marks to existing members
- **Remove values** — drops selected marks from membership

**Cleared-selection behaviour:**
- **Keep set values** — members unchanged when deselected
- **Add all values to set** — entire dimension joins the set (restores full context)
- **Remove all values from set** — set becomes empty

**Requirements:** Set must already exist before creating the action; set must be used in the visualization.

**Advanced patterns:**

*Proportional brushing:* Click a mark → colour other charts by proportion IN/OUT of set. Clear-selection set to "Add all values" restores full context.

*Asymmetric drill-down:* `IF [Category Set] THEN [Sub-Category] ELSE [Category] END` — expands only the selected branch of the hierarchy.

*Colour rescaling:* Return a measure only for set members → colour palette rescales to selected subset, reducing outlier distortion.

*Relative date comparison:* Click a timeline mark → assigns a date to a set → downstream calcs derive "target date" for KPI comparison across dashboard.

---

## Sets

Sets define a custom subset of a dimension's members for comparison and filtering.

### Types of Sets

| Type | Members Change? | Dimensions Supported |
|---|---|---|
| **Dynamic Set** | Yes — when data changes | Single dimension only |
| **Fixed Set** | No | Single or multiple dimensions |

### Creating a Dynamic Set

Right-click a dimension → **Create → Set**

Three tabs:
- **General:** select specific members, or "Use all" to capture future members automatically
- **Condition:** rule-based inclusion (e.g., `SUM([Sales]) > 100000`), works like filter conditions
- **Top:** limit by rank/metric (e.g., top 5 customers by revenue), works like Top N filters

### Creating a Fixed Set

Select marks in a view → right-click → **Create Set**

Options: exclude rather than include selected members, remove unwanted dimensions, specify separator for multi-dimension members, auto-add to Filters shelf.

### Using Sets in Views

**In/Out mode** (default): Two categories — **In** (set members) and **Out** (everything else). Enable via: right-click set → Show In/Out of Set.

**Show Members mode:** Lists individual set members and applies a filter showing only those members. Enable via: right-click set → Show Members in Set.

**Set Controls:** Filter-like card that lets users toggle set membership interactively. Only works with dynamic sets. Enable via: right-click set in Data pane → Show Set.

### Combining Sets

Creates a new set from two existing sets on the same dimension.

| Combination | Result |
|---|---|
| All Members in Both Sets | Union (A ∪ B) |
| Shared Members in Both Sets | Intersection (A ∩ B) |
| Except Shared Members | Difference (A − B) |

### Common Set Patterns

**Contribution to total:**
1. Create a condition-based set (e.g., customers with Sales > $5,000)
2. Drag set to Rows, Sales to Columns
3. Apply Quick Table Calculation → Percent of Total
4. See what share of total sales the top customers represent

**Cohort overlap analysis:**
1. Filter by Year A → select all marks → Create Set ("Customers 2023")
2. Filter by Year B → select all marks → Create Set ("Customers 2024")
3. Combine sets → Shared Members
4. Count distinct to see returning customer overlap

---

## Groups

Groups manually combine dimension members into named categories.

### Creating Groups

**From the view:** Select one or more marks → click group icon in the tooltip bar. If multiple dimensions are present, Tableau prompts for which to group on.

**From the Data pane:** Right-click a dimension → **Create → Group** → select members → click **Group**. A default name is generated from the combined member names.

### The "Other" Group

Enable "Include Other" in the Edit Group dialog to bundle all non-grouped members into a single **Other** group — useful for highlighting specific segments against everything else.

### Editing Groups

Right-click the group field in the Data pane → **Edit Group**

| Action | How |
|---|---|
| Add members to group | Drag members into the target group |
| Remove members | Select → Ungroup |
| Create a new group | Select members → Group |
| Rename | Select group → Rename |
| Find members | Use the Find option (Desktop only) |

### Groups vs Sets vs Bins

| Mechanism | Source | Changes Dynamically? | Use For |
|---|---|---|---|
| **Group** | Discrete members | No (fixed categories) | Combining labelling errors, creating ad hoc categories |
| **Set** | Dimension members | Yes (condition-based) | Comparison of in/out, interactive selection, cohort analysis |
| **Bin** | Continuous measure | No | Histograms, range bucketing |

---

## Bins

Bins convert a continuous measure into discrete range buckets.

### Creating Bins

Right-click a measure → **Create → Bins** → set bin size.

**Bin size determination:**
- Manual entry
- Click **Suggest Bin Size** (Tableau calculates using: `bins = 3 + log₂(n) × log(n)`)
- Reference values shown: Min, Max, Diff (range), CntD (count distinct)

### Limitations

- Works only with **relational data sources**
- Binned fields cannot be used in calculated field expressions
- Workaround for calculations: `FLOOR([Sales]/1000)*1000` replicates fixed-size binning

### Building a Histogram

1. Create bin from a measure (e.g., `Sales (bin)` with size 1000)
2. Convert binned field to **continuous** (right-click → Continuous)
3. Place on Columns
4. Place original measure on Rows
5. Change aggregation to **Count** or **Count (Distinct)**

---

## Shelves and Marks Card Reference

### Columns and Rows Shelves

- **Dimensions** on Rows/Columns → create **headers** (axis labels)
- **Measures** on Rows/Columns → create **quantitative axes**
- Additional fields add more rows, columns, and panes for increasing detail

Mark type is auto-determined by the combination of fields. Override via the Marks card dropdown.

### Marks Card Properties

| Property | Multiple Fields? | Notes |
|---|---|---|
| **Color** | Yes (hold Shift to add without replacing) | Multiple colour fields create layered legends |
| **Size** | No (one field only) | |
| **Shape** | No (one field only) | |
| **Label** | Yes | |
| **Detail** | Yes | Adds granularity without visual encoding |
| **Tooltip** | Yes | Rewrite as full sentences for best storytelling |

After placing a field on the Marks card, click its icon to reassign it to a different property.

### Pages Shelf

Breaks a view into navigable pages — one per member of the field placed on Pages. Navigation options: dropdown, forward/back buttons, slider, keyboard shortcuts (`Ctrl+.` / `Ctrl+,`). Autoplay with speed control.

**Show History:** displays trailing marks from prior pages on the current page (useful for animated time-series comparisons).

When a measure is placed on Pages, Tableau converts it to a **discrete measure** automatically.

### Filters Shelf

- Internal filter: field already contributing to rows/columns
- External filter: field not present elsewhere in the view
- Both types filter independently — ordering on the shelf does not affect results

---

## Performance Optimization

### Core Principles

- "Strings and dates are slow, numbers and Booleans are fast" — prefer numeric keys over string joins
- "Only connect to the data you need" — hide unused fields, apply source filters early
- Fix slow data sources **upstream** — Tableau cannot compensate for a slow database

### Extracts vs Live

- Extracts are almost always faster for analytical workloads under a few hundred million rows
- Use live connections only when: real-time data is required, or working at billion-row scale where extract size becomes prohibitive

### Dashboard Design for Performance

- Overcrowded dashboards are the primary cause of slow load times — every widget fires a query on open
- Strategy: guided drill-down — show summary first, reveal detail on demand
- Use **conditional visibility** (Show/Hide containers) to defer queries for off-screen content

### Query Reduction

- Apply data source filters to exclude rows never needed in the workbook
- Use extracts with Extract Filters to pre-filter before queries hit the extract
- Avoid COUNTD on large datasets — it is expensive; replace with pre-aggregated datasets where possible
- Replace LOD-heavy calculations with pre-computed fields in the data source or recipe when possible

### Performance Recorder

**Help → Settings and Performance → Start Performance Recording**

Run a recording while interacting with the workbook, then stop it to generate a performance workbook showing:
- Which queries ran and how long they took
- Time spent on layout, rendering, and calculations
- Query text for each request

Use this to identify whether the bottleneck is: long individual queries, excessive query count, slow calculations, or rendering.

---

## Visualization Best Practices

### Chart Selection

Use the right chart for the question:
- **Comparison across categories:** Bar chart (horizontal for long labels)
- **Trend over time:** Line chart
- **Part-to-whole:** Stacked bar or treemap (avoid pie charts for >4 segments)
- **Correlation/distribution:** Scatter plot, box-whisker, histogram
- **Geographic distribution:** Map (only when geography is the actual question)
- **KPI tracking:** Text table with conditional formatting or bullet graph

### Color Best Practices

- **Discrete fields:** categorical palettes — distinct but harmonious colours
- **Continuous fields:** quantitative palettes
  - Positive-only: single-colour gradient
  - Mixed positive/negative: diverging two-colour gradient
- Limit colour count: too many colours create visual overload
- Use neutral colours with one bright accent to emphasise key findings
- Align custom palettes with client brand identity for embedded/portal deployments

### Typography

Tableau's built-in fonts are optimised for small-size legibility. External font alternatives if needed: Arial, Verdana, Trebuchet MS, Times New Roman, Lucida Sans.

Format hierarchically: **Workbook → Worksheet → Individual element** (broadest to narrowest — saves repeated overrides).

### Axes

- Default auto-adjusting axes complicate comparisons across views — fix the axis range for consistent comparisons
- For very large ranges, add grid lines to help viewers stay oriented

### Tooltips

Tooltips are a storytelling tool — not just a data dump. Rewrite as full sentences, bold key elements, and highlight what is most important to the viewer. Support `Viz in Tooltip` for embedded mini-charts.

### Accessibility

- Do not rely on colour alone to convey information — use shape or label as a secondary encoding
- Provide sufficient contrast between text and background
- Use meaningful axis and field names instead of raw database column names
