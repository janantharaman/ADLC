---
source: help.tableau.com — Mark Types; Multiple Measures; Dashboard Layout; Sorting; Keyboard Shortcuts; Workbook Formatting (2026-05-17)
product: Tableau
section: viz-techniques
last-updated: 2026-05-17
---

# Tableau — Visualization Techniques Reference

## Mark Types

Tableau automatically selects a mark type based on the combination of fields placed on inner shelf positions.

### Automatic Mark Selection Logic

| Inner Fields on Rows / Columns | Auto-Selected Mark |
|---|---|
| Dimensions on both shelves | Text (cross-tab) |
| Measures on both shelves | Shape (scatter) |
| One dimension + one measure (non-date) | Bar |
| Date field + measure | Line |

Override via the mark type dropdown on the Marks card.

### All Mark Types

| Mark Type | Best For | Notes |
|---|---|---|
| **Bar** | Comparing measures across categories | Stacked variant shows part-to-whole |
| **Line** | Trends over time or ordered sequences | Path style: linear, step, or jump |
| **Area** | Cumulative contribution over time | Requires Stack Marks enabled; fills between line and axis |
| **Square** | Heat maps, treemaps | Add measure to Color → heat map; add dimensions → treemap (nested rectangles) |
| **Circle** | Individual data points | Solid circles; for open circles use Shape |
| **Shape** | Categorical scatter plots | 20 unique shapes; placing a dimension on Shape assigns distinct shapes per member |
| **Text** | Cross-tab / pivot tables, word clouds | Shows "Abc" until a measure is placed on Text target |
| **Map** | Geographic polygon/line fills | Requires geographic dimension on Detail + Lat/Long on shelves + measure on Color |
| **Pie** | Proportions (up to ~5 segments) | Angle target on Marks card; never auto-selected — avoid for many segments |
| **Gantt Bar** | Duration / timeline views | Bar length proportional to measure on Size |
| **Polygon** | Custom boundary shapes | Requires specially constructed data; rarely used |
| **Density** | Overlapping marks, geographic hotspots | Intensity slider; 10 dedicated colour palettes |

**Note:** Manually overriding the auto-selected mark type "might hide important information about your data."

---

## Dual Axis and Multiple Measures

### Three Approaches to Displaying Multiple Measures

**Separate axes (default):** Drag each measure to its own Rows/Columns position — each gets an independent scale.

**Blended axis:** Drop a second measure *onto* an existing axis to share a pane. Uses auto-generated **Measure Names** and **Measure Values** fields:
- Measure Values drives the shared axis
- Measure Names goes to Color (one line per measure)
- Measure Names is filtered to show only selected measures
- Best when measures have similar scale and units

**Dual axis:** Two independent axes layered over each other. Create by:
- Dragging a field to the **right edge** of the view until a black dashed line appears, or
- Right-clicking a shelf pill → **Dual Axis**
- Supports up to four layered axes

### Synchronizing Dual Axes

Right-click the secondary axis → **Synchronize Axis**

- Requires matching data types (integer vs decimal permitted since v2018.1)
- If greyed out: change one field's data type via Data pane → Change Data Type
- To swap primary/secondary: drag the secondary field in front of the primary until an orange triangle appears

### Combo Charts

Dual axis gives each measure its own Marks card — configure each independently:
- Marks types (e.g., Sales as Bar, Profit as Line)
- Independent colour, size, detail levels
- Classic pattern: Bar + Line on synchronized dual axis

---

## Dashboard Layout

### Tiled vs Floating

| Approach | Behaviour | Best For |
|---|---|---|
| **Tiled** | Single-layer grid; items resize with dashboard | Automatic-size dashboards; content that should scale |
| **Floating** | Can overlap other objects; pixel-positioned | Precise overlays, transparent legends, fixed-size dashboards |

"For best results, give floating objects and views a fixed size and position on a fixed size dashboard."

### Dashboard Sizing Options

| Mode | Behaviour |
|---|---|
| **Fixed** | Exact pixel dimensions; best cache performance; required for floating layouts |
| **Range** | Scales between min and max pixel values; suited for two display sizes with similar aspect ratios |
| **Automatic** | Fills the browser window; can produce unpredictable results on different screens |

### Layout Containers

Group related objects so they reposition automatically when contents shift:
- **Horizontal containers** — adjust width of contents
- **Vertical containers** — adjust height of contents
- **Distribute items evenly** via the container's right-click menu
- Remove a container to allow independent editing of its former contents

**Show/Hide button:** Toggle container visibility interactively. Best practice:
- Place objects to be hidden inside a **Horizontal or Vertical container** — when hidden, sibling objects fill the vacated space
- Top-level tiled objects leave blank space when hidden

### Dashboard Objects Available

| Object | Purpose |
|---|---|
| Horizontal / Vertical | Layout grouping containers |
| Text | Static headers, labels, annotations |
| Image | Brand logos, static visuals (supports URL linking) |
| Web Page | Embedded external content |
| Blank | Spacing control between objects |
| Navigation | Buttons that link to other sheets, dashboards, or stories |
| Download | Export buttons (PDF, PNG, PowerPoint) |
| Extension | Third-party integrations (e.g., Einstein, custom apps) |
| Pulse Metric | Embedded Tableau Pulse metric card |

### Device Layouts

Create optimised layouts for different screen sizes (Phone, Tablet, Desktop) from the same dashboard. Accessed via the Device Preview button in Dashboard view — select device type and configure layout independently.

---

## Sorting

### Sort Options (right-click a dimension header or axis)

| Option | Behaviour |
|---|---|
| **Ascending / Descending** | Alphabetical or numeric sort based on field values |
| **Data Source order** | Preserves the order records appear in the data source |
| **Manual** | Drag-and-drop reorder — only applies to the current view |
| **Field-based** | Sort by a measure (e.g., sort category by SUM(Sales) descending) |
| **Nested** | Sort within each partition independently (e.g., sort sub-categories within each category) |

### Accessing Sort Controls

- Toolbar sort buttons (ascending/descending) — applies to the active dimension
- Right-click a header → Sort
- Right-click a field pill on the shelf → Sort
- Sort icon on axis headers (hover to reveal)

### Resetting Sort

Right-click a dimension header → Clear Sort — removes manual and computed sorts, returning to data source order.

---

## Workbook Formatting

### Formatting Hierarchy

Format settings cascade from broadest to narrowest — more specific settings override broader ones:
1. **Workbook level** (Format menu → Workbook) — applies to all worksheets
2. **Worksheet level** (Format menu → specific elements) — overrides workbook defaults
3. **Field level** — calculated field or measure-specific formatting

**Note:** Applying a workbook-level font change will overwrite prior worksheet-level font customisations.

### Workbook-Level Options (Format → Workbook)

- **Lines:** Modify all line types (grid lines, zero lines, axis ticks, reference lines); can disable entirely. Opacity is linked to line colour — set opacity at worksheet level to preserve per-sheet colour differences.
- **Fonts:** Global font family, size, and style for titles, pane text, header text, tooltips.
- **Themes** (Desktop only): Smooth (v10+), Clean (v8-9), Modern (v3-7), Classic (v1-3)

Gray indicator dots appear next to settings that have been customised from defaults.

**Reset to Defaults** button reverts all workbook formatting.

### Custom Colour Palettes

Custom palettes are defined in `Preferences.tps` in My Tableau Repository:

**File location:**
- Windows: `C:\Users\[username]\Documents\My Tableau Repository\Preferences.tps`
- Mac: `/Users/[username]/Documents/My Tableau Repository/Preferences.tps`

**Format:**
```xml
<?xml version='1.0'?>
<workbook>
  <preferences>
    <color-palette name="Brand Palette" type="regular">
      <color>#003366</color>
      <color>#FF6600</color>
      <color>#339933</color>
    </color-palette>
    <color-palette name="Brand Diverging" type="ordered-diverging">
      <color>#003366</color>
      <color>#FFFFFF</color>
      <color>#CC0000</color>
    </color-palette>
  </preferences>
</workbook>
```

Palette types: `regular` (categorical), `ordered-sequential` (single-hue gradient), `ordered-diverging` (two-hue diverging).

After editing, reload: close and reopen Tableau Desktop (or restart Tableau Server).

---

## Keyboard Shortcuts Reference

### Workbook and File

| Action | Windows | Mac |
|---|---|---|
| New workbook | Ctrl+N | Cmd+N |
| New worksheet | Ctrl+M | Cmd+T |
| Open file | Ctrl+O | Cmd+O |
| Save | Ctrl+S | Cmd+S |
| Undo | Ctrl+Z | Cmd+Z |
| Redo | Ctrl+Y | Cmd+Shift+Z |
| Print | Ctrl+P | Cmd+P |
| Presentation mode | F7 / Ctrl+H | Opt+Return |

### Data

| Action | Windows | Mac |
|---|---|---|
| Connect to data | Ctrl+D | Cmd+D |
| Refresh data source | F5 | Cmd+R |
| Find in Data pane | Ctrl+F | Cmd+F |
| Run data updates | F9 | Shift+Cmd+0 |
| Toggle auto-updates | F10 | Opt+Cmd+0 |

### View Building

| Action | Windows | Mac |
|---|---|---|
| Show Me panel | Ctrl+1 | Cmd+1 |
| Swap rows and columns | Ctrl+W | Ctrl+Cmd+W |
| Place on Columns shelf | Alt+Shift+C | Opt+Shift+C |
| Place on Rows shelf | Alt+Shift+R | Opt+Shift+R |
| Place on Filters shelf | Alt+Shift+F | Opt+Shift+F |
| Place on Color | Alt+Shift+O | Opt+Shift+O |
| Place on Size | Alt+Shift+I | Opt+Shift+I |
| Place on Label/Text | Alt+Shift+T | Opt+Shift+T |
| Place on Detail | Alt+Shift+L | Opt+Shift+L |
| Place on Shape | Alt+Shift+S | Opt+Shift+S |
| Copy field to shelf | Ctrl+drag | Cmd+drag |
| Clear worksheet | Alt+Shift+Backspace | Opt+Shift+Del |
| Toggle dashboard grid | G | G |

### Cell Sizing

| Action | Windows | Mac |
|---|---|---|
| Smaller cells | Ctrl+B | Cmd+B |
| Larger cells | Ctrl+Shift+B | Cmd+Shift+B |
| Rows narrower | Ctrl+Left | Ctrl+Cmd+Left |
| Rows wider | Ctrl+Right | Ctrl+Cmd+Right |
| Columns shorter | Ctrl+Down | Ctrl+Cmd+Down |
| Columns taller | Ctrl+Up | Ctrl+Cmd+Up |

### Mark Selection

| Action | Windows | Mac |
|---|---|---|
| Select all marks | Ctrl+A | Cmd+A |
| Add mark to selection | Ctrl+click | Cmd+click |
| Rectangular selection | A | A |
| Lasso selection | D | D |
| Radial selection | S | S |
| Clear selection | Esc | Esc |
| Pan view | Shift+drag | Shift+drag |

### Pages Shelf Playback

| Action | Windows | Mac |
|---|---|---|
| Play / stop forward | F4 | F4 |
| Play / stop backward | Shift+F4 | Shift+F4 |
| Skip forward one page | Ctrl+. | Cmd+. |
| Skip backward one page | Ctrl+, | Cmd+, |

---

## Viz in Tooltip

Embed a miniature sheet inside another sheet's tooltip — a small contextual chart that appears on hover.

**Setup:**
1. Create the detail sheet (the mini-chart to embed)
2. On the main sheet: Worksheet → Tooltip → Insert → Sheets → [select the detail sheet]
3. Specify width, height, and maxrows

**Filtering:** The tooltip sheet automatically filters to the hovered mark's context. Disable this with "Don't filter" option if the full dataset should show.

**Limitations:** The tooltip sheet must be a worksheet (not a dashboard). The sheet cannot contain table calculations that depend on the full table scope.

---

## Combining Sheets with Measure Names and Measure Values

Tableau auto-creates two special fields when multiple measures are placed on a single axis:

- **Measure Names** — a dimension containing the names of all measures in the view
- **Measure Values** — the corresponding measure values

**Use cases:**
- Side-by-side bar charts comparing multiple KPIs
- Line charts showing multiple metrics on one axis
- Cross-tab with multiple measures per row

**Filter Measure Names** to show only the desired measures — drag it to Filters shelf and deselect unwanted measures.
