---
source: help.tableau.com — Permissions; Data Management; Virtual Connections; Data-Driven Alerts; Ask Data; Accessibility; File Types; Global Filters (2026-05-17)
product: Tableau Cloud / Tableau Server
section: governance-sharing
last-updated: 2026-05-17
---

# Tableau — Governance, Sharing & Collaboration

## File Types

| Extension | Name | Contains | When to Use |
|---|---|---|---|
| `.twb` | Workbook | Worksheet definitions + data source *references* (links to external data) | Default save when recipients have their own data access |
| `.twbx` | Packaged Workbook | `.twb` + embedded copies of local file data sources + background images + extracts | Sharing self-contained workbooks with users who lack server/DB access |
| `.tbm` | Bookmark | Single worksheet snapshot; no parameter values or Pages shelf state | Quick sharing of one view without a full workbook |
| `.twbr` | Recovered Workbook | Auto-generated after a crash in the same folder as the original | Not a deliberate format — open and re-save as `.twb` or `.twbx` |
| `.tds` | Data Source | Data source connection metadata only — no actual data | Sharing reusable connection definitions |
| `.tdsx` | Packaged Data Source | `.tds` + embedded local file data | Sharing a self-contained data source including file data |
| `.hyper` | Extract | Columnar snapshot of data in Tableau's fast-query format | Created when publishing with an extract, or programmatically via Hyper API |
| `.tflx` | Packaged Flow | Tableau Prep flow + embedded data sources | Sharing a Prep flow with its input data |

**Key rule:** `.twbx` and `.tdsx` bundle everything locally — the workbook is *no longer linked* to original data sources. Content is stored in plain text; all data is readable by anyone who opens the file. Rename to `.zip` to unpackage.

---

## Permissions (Deep Dive)

### The Permission Model

Permissions control what users can do with content (workbooks, data sources, flows, views). They work at two layers:
1. **Capability rules** — Allowed / Denied / Unspecified (per user or group, per asset or project)
2. **Effective permissions** — final result after applying license tier + site role + all applicable rules

**Critical rule:** A capability is granted **only if explicitly Allowed**. Unspecified = Denied.

- One click on a capability circle = **Allowed** (filled)
- Two clicks = **Denied** (X)
- Three clicks = **Unspecified** (empty = effectively Denied)

### Permissions Hierarchy

Broadest to most granular:
1. **License tier** (hard ceiling — license cannot be exceeded)
2. **Site role** (e.g., Viewer can never web-edit regardless of project rule)
3. **Project-level rules** (default for all content in the project)
4. **Content-level rules** (override — only in Customizable projects)
5. **View-level rules** (override — only when workbook hides sheet tabs)

### Locked vs Customizable Projects

| Mode | Behaviour |
|---|---|
| **Locked** | Project rules enforced uniformly. Only admins, project leaders, and project owners can change. Use for production content. |
| **Customizable** | Individual asset owners can set per-workbook/data-source/flow permissions independently. |

Even in Customizable projects, best practice is to manage permissions at the project level.

**Tabs visible vs hidden view permissions:**
- When workbook shows tabs → views inherit workbook permissions (view dialog is read-only)
- When workbook hides tabs → views start with workbook permissions but become independent — changes to the workbook's rules *don't* propagate to views
- Re-enabling tabs *overrides* any independent view-level permissions

### Site Roles and Capability Ceilings

| Site Role | Web Edit | Publish New DS | Overwrite | Download Full Data |
|---|---|---|---|---|
| Viewer | Never | Never | Never | Never |
| Explorer | Yes (can't save) | No | No | No |
| Explorer (Can Publish) | Yes | Existing DS only | Yes | Optional |
| Creator | Yes | Yes (new DS) | Yes | Yes |
| Administrator | Yes | Yes | Yes | Yes |

### Web Authoring Permission Matrix

| Goal | Minimum Role | Web Edit | Download/Save Copy | Overwrite | Publish to Project |
|---|---|---|---|---|---|
| Edit without saving | Explorer | Allow | Deny | Deny | Optional |
| Save as new content | Explorer (Can Publish) | Allow | Allow | Deny | Allow |
| Overwrite existing | Explorer (Can Publish) | Allow | Allow | Allow | Allow |
| Publish new data source | Creator | Allow | Optional | Optional | Allow |

### Moving Content

Non-admin users need **all three simultaneously**:
1. Creator or Explorer (Can Publish) site role
2. View + Publish capabilities on the **destination** project
3. Content ownership, or the **Move** capability on the asset

Moving a database requires Move capability on both the database **and** its tables.

### Data Source Authentication Interaction

When a workbook uses a published data source, two independent auth settings interact:

| Workbook Auth | Data Source Auth | Result for Viewer |
|---|---|---|
| Embed password | Embed password | Viewer sees data as workbook author |
| Embed password | Prompt user | Workbook *author* is prompted, not the viewer |
| Prompt user | Embed password | Viewer needs own **Connect** capability |
| Prompt user | Prompt user | Viewer needs Connect capability + own database credentials |

### Best Practice Summary

- Set rules at the **Project level**, assign to **Groups** not individuals
- Delete the All Users rule or set it explicitly to avoid unintended access
- Use **Project Leaders** to delegate day-to-day project management without granting site admin
- Use **Locked** mode for all production content

---

## Global / Cross-Sheet Filters

Filter scope options (right-click a filter on the Filters shelf):

| Scope | Behaviour |
|---|---|
| **Only This Worksheet** | Default — local to current sheet |
| **All Using This Data Source** | Applies to all worksheets sharing the same primary data source (global) |
| **All Using Related Data Sources** | Applies across all worksheets using related data sources; auto-appears on new sheets |
| **Selected Worksheets** | Manual multi-sheet selection; chosen filter takes precedence over existing filters on the same field |

**Dashboard-level filtering:** Within a dashboard, scope to all sheets on that dashboard via: Apply to Worksheets → Selected Worksheets → All on dashboard.

**Legacy naming:** Earlier Tableau Desktop versions called these "Make Global" (now "All Using This Data Source") and "Make Local" (now "Only This Worksheet").

---

## Data Management (Tableau Catalog)

**Licensing:** As of September 16, 2024, Data Management is bundled with Tableau Enterprise and Tableau+ licenses. No longer sold separately. The Metadata API and GraphiQL tool do *not* require Data Management.

### Tableau Catalog

| Feature | Description |
|---|---|
| **Data Discovery** | Search databases, tables, and columns used in published sources — not just workbooks |
| **Certification** | Mark databases and tables as trusted/authoritative |
| **Data Quality Warnings** | Flag stale, deprecated, or inaccurate data — warnings surface to workbook consumers |
| **Lineage** | Trace data from source database → table → data source → workbook → dashboard; identify downstream impact before changing a data source |
| **Impact Analysis** | Email owners of affected workbooks/data sources/flows when an upstream asset changes |
| **Tagging & Descriptions** | Organise assets with searchable metadata |
| **Permissions** | Control visibility of external asset metadata through lineage |

### Virtual Connections

A Virtual Connection is a reusable, shareable connection to curated database tables — sitting between the database and published data sources.

**Key properties:**
- Central point to manage database credentials (one change propagates to all workbooks using the virtual connection)
- Attach **Data Policies** (row-level security rules) that apply at the connection level
- Test security via "Preview as User" before publishing
- Schedule extract refreshes to keep virtual connection data current
- Workbooks using a virtual connection consume data via the connection's permissions, not their own credentials

**Data Policies vs Security Predicates:** Tableau's Data Policies apply row-level security at the virtual connection level (before the workbook layer); CRM Analytics security predicates apply at dataset query time. Both approaches filter at the data layer rather than the presentation layer.

### Tableau Prep Conductor

Part of Data Management — orchestrates scheduled flow execution:
- Schedule flows on recurring or fixed-time schedules
- Monitor health via email notifications on flow failure
- Administrative views show performance history and disk usage

---

## Data-Driven Alerts

Automated notifications triggered when a continuous numeric measure crosses a defined threshold.

### Setup

- Requires a **continuous numeric axis** (not supported: Gantt charts, maps, numeric bins, discrete numeric axes)
- Configure via the Alerts side panel → Create
- Set: subject line, threshold condition, schedule (hourly/daily/weekly), recipients
- Red line in preview shows where the threshold sits against current data
- "Make visible to others" option for shared alert management

### Delivery Methods

| Channel | Notes |
|---|---|
| **Email** | Includes management links |
| **Tableau site** | In-platform notification bell |
| **Slack** | Requires Tableau for Slack app |

### Management

- Owners can edit threshold, schedule, and recipients
- Non-owners can add themselves ("Add Me")
- Managed from My Content or alert emails
- Alerts suspend after repeated failures (connectivity loss, removed data source, expired credentials); resume via My Content or notification email

---

## Natural Language Querying

### Ask Data (Retired)

Ask Data was **retired in Tableau Cloud in February 2024** and in **Tableau Server 2024.2**. It allowed users to type plain-language questions and receive instant visualizations.

It required authors to create a *lens* — a curated definition of which fields were available for querying. Tableau AI (Authoring and Dashboards agents) is its intended replacement.

### Tableau Agent — Authoring (Current)

Part of Tableau AI on Tableau Cloud. Converts natural language to chart suggestions and calculations. Does not require pre-configuration of lenses.

**Available in:** Tableau Cloud (Cloud features — not Tableau Server).

---

## Accessibility

Tableau supports dashboards conforming to **WCAG 2.2 AA** (Section 508 compliant).

### Accessible View Elements

A compliant view can include: title, single/multi-value filters, categorical legends, captions, tabs, alt text for visualizations, color-blind palette, View Data window.

### Keyboard and Assistive Technology

- Full keyboard navigation (no mouse required)
- ARIA roles for programmatic interpretation by assistive technologies
- Text equivalents for charts and visualizations
- Contrast standards compliance

### Alt Text

Available on **Tableau Cloud 23.2+**. Authors add alt text per view for screen reader access.

### Authentication for Embedded Accessible Views

Embed database credentials at publish time to prevent authentication prompts from interrupting accessible workflows for users relying on assistive technology.

### Authoring Best Practices for Accessibility

- Do not rely on colour alone — use shape or label as a secondary encoding
- Use the Color-Blind palette for views where colour is a primary encoding
- Ensure sufficient contrast between text and background
- Use the **Color Contrast Analyzer** tool to verify contrast ratios
- Write meaningful axis and field labels (not raw database column names)
- Provide tooltips as full sentences, not raw values
