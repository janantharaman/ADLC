---
source: help.tableau.com — Publishing workbooks; Tableau Cloud overview; tableau.com/products/cloud-bi (2026-05-17)
product: Tableau
section: publishing
last-updated: 2026-05-17
---

# Tableau — Publishing, Sharing & Governance

## Publishing a Workbook (Tableau Desktop)

### Steps

1. **Open the workbook** in Tableau Desktop
2. **Server menu → Publish Workbook** (or Tableau Cloud → Publish Workbook)
3. **Sign in:** For Tableau Cloud, the address is `https://online.tableau.com`
4. **Choose a project** — projects are the organisational containers on Server/Cloud
5. **Set name and tags** — tags are comma-separated; multi-word tags use quotes
6. **Configure options** (see below)
7. **Click Publish**
8. Optionally set up extract refresh schedules after publishing

### Publishing Options

#### Sheets

- All sheets publish by default; specific sheets can be hidden
- **Security note:** Hiding sheets is a UX choice, not a security control. Users with download permission can still access hidden sheets via workbook download.
- **Showing sheet tabs:** When tabs are shown, all sheets share workbook-level permission rules. Without tabs, individual view-level permissions can be set independently.

#### Data Sources and Credentials

- **Publish data source embedded in workbook:** Data source lives inside the workbook. Anyone with workbook access has data access.
- **Publish data source separately:** Publishes the data source as a standalone asset. Multiple workbooks can connect to it. Permissions are managed on the data source independently.
- **Embed credentials:** Stores login credentials in the published workbook/data source. Required for scheduled extract refreshes. Only use for service account credentials, not personal credentials.
- **Prompt users:** Users enter credentials when they open the workbook. Requires each viewer to have their own account on the data source.

#### Include External Files

| Scenario | Setting |
|---|---|
| Local Excel/CSV, Tableau Server | Check "Include External Files" — creates a static snapshot embedded in the workbook |
| Local file, Tableau Cloud, Bridge-supported connector | Do not check — use Tableau Bridge for live/refreshed access |
| Local file, Tableau Cloud, flat file (Excel/CSV/txt) | Leave unchecked — a shadow extract is created automatically |
| Local file, Tableau Cloud, non-Bridge connector | Check "Include External Files" — file becomes static snapshot |

**Gotcha:** Checking "Include External Files" for Tableau Cloud does not store the file on Tableau's servers for standalone data sources — you need Bridge + UNC path for that.

#### Show Selections

Publishes the workbook with a specific set of marks highlighted/selected, so viewers open it with that context already visible.

#### Device Layouts

Publishes mobile layouts alongside the default desktop layout. Preview in browser post-publish; if adjustments are needed, edit in Desktop and republish.

## Tableau Cloud — Site Structure

```
Tableau Cloud
└── Site (one per org/team, managed independently)
    ├── Projects (organisational folders)
    │   ├── Workbooks (published .twbx or .twb files)
    │   ├── Data Sources (published .tds or .tdsx files)
    │   ├── Flows (published Prep flows)
    │   └── Metrics (Pulse metrics)
    └── Users (Creators, Explorers, Viewers)
```

### Projects

Projects are the primary content organisation unit. Permissions applied to a project cascade to all content within it. Use projects to segment content by:
- Team or department (Sales, Finance, Operations)
- Data sensitivity (Public, Confidential, Restricted)
- Environment (Development, Production)

Nested projects are supported — a project can contain sub-projects.

### Permissions

Tableau Cloud and Server permissions are capability-based. Each permission rule grants a combination of capabilities:

| Capability | Viewers | Explorers | Creators |
|---|---|---|---|
| View | ✅ | ✅ | ✅ |
| Filter | ✅ | ✅ | ✅ |
| Download Image/PDF | ✅ | ✅ | ✅ |
| Download Full Data | ❌ | Optional | ✅ |
| Web Edit | ❌ | ✅ | ✅ |
| Save Workbook | ❌ | Optional | ✅ |
| Publish | ❌ | ❌ | ✅ |
| Move/Delete | ❌ | ❌ | Admin/Owner |

Permissions can be set on: Site → Project → Workbook → View level. Lower levels override higher levels.

**Best practice:** Set permissions at the Project level — apply to all content. Override per-workbook only when a workbook has different access needs from its project.

## Extract vs Live Connection

### Live Connection

- Every query goes directly to the data source in real time
- Always shows current data
- Performance depends on data source query speed
- Best for: small-to-medium datasets, frequently changing data, databases that are always available

### Extract

- Snapshot of data stored in Tableau's high-performance `.hyper` format
- Queries run against the local extract — very fast regardless of source
- Must be refreshed on a schedule to stay current
- Supports incremental refresh (append new rows since last refresh) for large tables
- Best for: large datasets, slow or unreliable data sources, published workbooks shared with many viewers

### Configuring Extract Refresh (Tableau Cloud / Server)

1. Publish the workbook with an embedded extract
2. After publishing, navigate to the data source page → Refresh Extracts → Schedule
3. Set frequency (hourly, daily, weekly, custom CRON)
4. Requires embedded credentials or impersonation on the data source

**Tableau Cloud extract limits:**
- Tableau Cloud hosts the extract on Salesforce infrastructure
- Up to 15 scheduled refresh tasks per site on standard tier

## Tableau Bridge

Tableau Bridge enables Tableau Cloud to access data behind a firewall (on-premises databases, local file servers) for live connections and extract refreshes.

- Install Bridge on a Windows machine inside the network
- Bridge authenticates with Tableau Cloud and acts as a proxy
- Supports most native Tableau connectors
- Bridge pools multiple agents for scale

When to use Bridge:
- Data source is on-premises (SQL Server, Oracle, SAP on internal servers)
- Tableau Cloud needs live access to internal systems
- Direct connectivity from Cloud to the database is not possible due to firewall rules

## Embedding Tableau in External Applications

### Tableau Embedding API (v3)

Embed Tableau views in custom web applications using the JavaScript Embedding API:

```html
<tableau-viz
  src="https://online.tableau.com/views/Workbook/Sheet"
  width="800"
  height="600"
  hide-tabs
  toolbar="bottom">
</tableau-viz>
```

### Tableau Viz Lightning Component (in Salesforce)

Embed Tableau dashboards natively in Salesforce Lightning:
1. Install the Tableau Viz Lightning component from AppExchange
2. Add the component to a Lightning page in App Builder
3. Set the Tableau URL and optional filter parameters (pass record field values as filters)

### Connected Apps (for Embedding Security)

For production embedding use Connected Apps (Tableau Server) or Tableau Trusted Authentication (Cloud) to ensure users don't need to log in separately to view embedded Tableau content.

## Tableau Cloud Governance

### Tableau Cloud Manager

Central admin console for organisations with multiple Tableau Cloud sites:
- Manage users and licences across all sites
- Monitor capacity and usage
- View real-time event logs
- Access pre-built activity dashboards (who is using what, stale content, licence utilisation)

### Platform Data API

REST API for programmatic access to audit and usage data. Use cases:
- Automated licence reclamation (identify inactive users)
- Content quality dashboards (views with no sessions in 90 days)
- Cross-site governance reporting

### Stale Content Management

Tableau Cloud surfaces stale content warnings (workbooks not viewed in > 90 days). Admins can bulk-delete or archive stale content via the Admin view or Platform Data API.

## Publishing from Tableau Prep

Flows (Tableau Prep) are published to Tableau Cloud or Server and run by Tableau Prep Conductor:

1. In Prep Builder: Flow menu → Publish → choose server and project
2. Set an output destination: published data source on Server/Cloud, or external database
3. After publishing: schedule the flow in Tableau Cloud → Schedules

Prep Conductor tracks flow status, sends failure notifications, and provides lineage from source to published data source.
