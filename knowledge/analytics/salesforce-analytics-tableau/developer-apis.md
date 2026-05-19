---
source: help.tableau.com — REST API; tabcmd; Hyper API; Tableau Server Client (2026-05-17)
product: Tableau
section: developer-apis
last-updated: 2026-05-17
---

# Tableau — Developer APIs Reference

## REST API

### What It Does

The Tableau REST API lets you manage Tableau Server and Tableau Cloud resources programmatically via HTTP. Enables custom applications, deployment automation, and scripted administration.

All endpoints follow the URL pattern:
```
https://<server>/api/<api-version>/sites/<site-id>/<resource>
```

### Authentication

**Username/password (token exchange):**
```
POST /api/<version>/auth/signin
Body: { "credentials": { "name": "user", "password": "pass", "site": { "contentUrl": "" } } }
```
Returns an `x-tableau-auth` token for subsequent requests.

**Personal Access Tokens (PATs) — Recommended:**
```
POST /api/<version>/auth/signin
Body: { "credentials": { "personalAccessTokenName": "...", "personalAccessTokenSecret": "...", "site": { "contentUrl": "" } } }
```
PATs are long-lived and don't require re-authentication after password changes. Manage PATs per-user in My Account Settings.

### Key Endpoint Categories

| Category | Key Operations |
|---|---|
| **Authentication** | Sign in, sign out, switch site, list/revoke PATs |
| **Sites** | Create, delete, query, update sites; embedding settings; recently viewed content |
| **Workbooks & Views** | Publish, download, delete, update workbooks; query views; download PDF/image/PowerPoint; custom views |
| **Data Sources** | Publish, download, delete, update; trigger extract refresh; Hyper data upserts/inserts/deletes |
| **Users & Groups** | Add/remove/update users; create/delete/update groups; SCIM provisioning |
| **Jobs, Tasks & Schedules** | Create/delete/update schedules (Server only); cancel/query jobs; trigger on-demand refresh |
| **Flows** | Publish, download, run, delete Prep flows; manage flow permissions and linked tasks |
| **Metadata** | Data quality warnings; sensitivity labels; database and table permissions (requires Catalog/Data Management) |
| **Permissions** | Granular permission rules on workbooks, projects, data sources, flows |

### Hyper Data Endpoints (v3.7+)

For updating `.hyper` extract files without a full refresh:
- **Insert:** Add new rows to an extract
- **Upsert:** Insert new rows or update existing rows by key
- **Delete:** Remove rows matching a condition
- **Replace:** Swap the entire table content

### Tableau Server Client (TSC) — Python Library

Official Python SDK wrapping the REST API:
```python
import tableauserverclient as TSC

server = TSC.Server('https://tableau.example.com')
tableau_auth = TSC.PersonalAccessTokenAuth('token_name', 'token_secret', site_id='')
with server.auth.sign_in(tableau_auth):
    all_workbooks, _ = server.workbooks.get()
    for wb in all_workbooks:
        print(wb.name)
```

Install: `pip install tableauserverclient`

Key objects: `server.workbooks`, `server.datasources`, `server.views`, `server.users`, `server.groups`, `server.schedules`, `server.jobs`, `server.flows`

---

## Hyper API

### What It Is

The Hyper API lets you create, read, and update Tableau `.hyper` extract files directly using Python, Java, or C++ — without requiring Tableau Desktop. It uses Tableau's internal SQL engine (Hyper) which powers both Tableau extracts and Tableau Prep.

### Key Capabilities

- Build new `.hyper` files from scratch (from any data source)
- Append rows to existing extracts (incremental updates)
- Apply SQL transformations (JOIN, FILTER, AGGREGATE) before writing to the extract
- Load **CSV**, **Parquet**, and **Iceberg** formats natively without custom parsing
- "Rolling window updates or custom incremental updates" — delete old rows, insert new ones
- Connect data sources Tableau doesn't natively support

### Supported Languages and Platforms

| Language | Platforms |
|---|---|
| Python | Windows, macOS, Linux |
| Java | Windows, macOS, Linux |
| C++ | Windows, macOS, Linux |

### Integration with Tableau

Hyper files created via the API can be:
- Published to Tableau Cloud or Server using the **Tableau Server REST API** or **TSC Python library**
- Opened directly in Tableau Desktop
- Used as inputs in Tableau Prep

### Basic Python Pattern

```python
from tableauhyperapi import HyperProcess, Telemetry, Connection, CreateMode, TableDefinition, SqlType, Inserter, TableName

with HyperProcess(telemetry=Telemetry.SEND_USAGE_DATA_TO_TABLEAU) as hyper:
    with Connection(hyper.endpoint, 'mydata.hyper', CreateMode.CREATE_AND_REPLACE) as conn:
        conn.catalog.create_schema('Extract')
        table = TableDefinition(
            TableName('Extract', 'Extract'),
            [
                TableDefinition.Column('Customer ID', SqlType.text()),
                TableDefinition.Column('Sales', SqlType.double()),
                TableDefinition.Column('Order Date', SqlType.date()),
            ]
        )
        conn.catalog.create_table(table)
        with Inserter(conn, table) as inserter:
            inserter.add_rows([['C001', 1500.0, date(2024, 1, 15)]])
            inserter.execute()
```

Install: `pip install tableauhyperapi`

---

## tabcmd

A command-line utility for automating Tableau Server and Tableau Cloud administration tasks.

### Versions

| Version | OS | Auth | Notes |
|---|---|---|---|
| **tabcmd v1** | Windows only | Username/password | Full Server support; viz export broken pre-2024.1 |
| **tabcmd v2** | Windows, macOS, Linux | Username/password + **PATs** | Built on TSC Python; limited Server support; recommended for Tableau Cloud |

tabcmd v2 available at: `tableau.github.io/tabcmd`

### Authentication

```bash
# v1 — session-based
tabcmd login -s http://tabserver.mycompany.com -u admin -p mypassword

# Combined session + command (one-liner)
tabcmd delete "Sales_Workbook" -s http://tabserver.mycompany.com -u admin -p mypassword -t site-id
```

Common global options: `-s` (server URL), `-t` (site ID for non-Default sites), `-u` (username), `-p` (password)

### Key Commands

| Command | Purpose |
|---|---|
| `login / logout` | Establish / end authenticated session |
| `publish` | Publish workbook or data source to server |
| `get` | Download a workbook, data source, or view |
| `delete` | Delete a workbook from the server |
| `refreshextracts` | Trigger extract refresh for workbook or data source |
| `createusers` | Bulk-create users from a CSV file |
| `deleteusers` | Bulk-delete users from a CSV file |
| `addusers` | Add users to a group |
| `removeusers` | Remove users from a group |
| `creategroup` | Create a user group |
| `deletegroup` | Delete a user group |
| `createproject` | Create a new project |
| `deleteproject` | Delete a project |
| `export` | Export a view to PDF, PNG, or CSV |
| `version` | Display tabcmd version info |

### Status and Logging

- Success returns exit code **0**; errors print to stderr
- Full log: `C:\Users\<username>\AppData\Local\Tableau\tabcmd.log`
- Commands/options: case-insensitive; **values: case-sensitive**
- Tasks must run serially (not in parallel within one session)

---

## Tableau Server Client (TSC) — Python

The recommended Python library for Tableau Server and Tableau Cloud automation. A higher-level abstraction over the REST API.

```python
import tableauserverclient as TSC

# Authentication
server = TSC.Server('https://10ax.online.tableau.com', use_server_version=True)
auth = TSC.PersonalAccessTokenAuth('token-name', 'token-secret', site_id='my-site')

with server.auth.sign_in(auth):
    # List all workbooks
    all_workbooks, _ = server.workbooks.get()

    # Publish a workbook
    new_wb = TSC.WorkbookItem(project_id='abc123')
    new_wb = server.workbooks.publish('path/to/workbook.twbx', new_wb, TSC.Server.PublishMode.Overwrite)

    # Trigger extract refresh
    refresh_job = server.workbooks.refresh(workbook_id)

    # Download a workbook
    server.workbooks.download(workbook_id, filepath='download/path/')

    # Manage users
    new_user = TSC.UserItem('jsmith', 'Explorer')
    server.users.add(new_user)
```

### Key TSC Objects

| Object | Operations |
|---|---|
| `server.workbooks` | get, publish, download, refresh, delete, update |
| `server.datasources` | get, publish, download, refresh, delete, update |
| `server.views` | get, download image/pdf/csv |
| `server.users` | get, add, remove, update, populate_workbooks |
| `server.groups` | get, create, delete, add_user, remove_user |
| `server.projects` | get, create, delete, update |
| `server.schedules` | get, create, delete, add_workbook/datasource |
| `server.jobs` | get, cancel, wait_for_job |
| `server.flows` | get, publish, download, delete |

Install: `pip install tableauserverclient`

Docs: `tableau.github.io/server-client-python`

---

## Metadata API (GraphQL)

Query Tableau's content catalog using GraphQL. Does **not** require a Data Management license.

```graphql
query {
  workbooksConnection(first: 10) {
    nodes {
      name
      projectName
      owner { name }
      upstreamDatasources { name }
    }
  }
}
```

Endpoint: `POST https://<server>/api/metadata/graphql`
Authentication: Same `x-tableau-auth` token as REST API.

**Common use cases:**
- Discover all workbooks using a specific data source
- Trace lineage from database table → data source → workbook → embedded view
- Audit content ownership and permissions across a site
- Find stale content (workbooks last accessed > 90 days)

---

## Embedding API v3 (Reference)

Embed Tableau views in web applications using the Web Component standard.

```html
<script type="module"
  src="https://online.tableau.com/javascripts/api/tableau.embedding.3.latest.min.js">
</script>

<tableau-viz
  src="https://online.tableau.com/views/WorkbookName/SheetName"
  width="1200" height="700"
  hide-tabs
  toolbar="bottom"
  token="<JWT_from_connected_app>">
</tableau-viz>
```

### Key Properties

| Property | Description |
|---|---|
| `src` | Full URL to the view |
| `width / height` | Pixel dimensions |
| `hide-tabs` | Hides sheet tab navigation |
| `toolbar` | `"top"` / `"bottom"` / `"hidden"` |
| `token` | JWT for Connected App (SSO) authentication |
| `device` | `"default"` / `"desktop"` / `"tablet"` / `"phone"` |

### JavaScript Interaction

```javascript
const viz = document.querySelector('tableau-viz');

// Apply a filter programmatically
await viz.workbook.activeSheet.applyFilterAsync('Region', ['West', 'East'], FilterUpdateType.Replace);

// Listen for mark selection
viz.addEventListener('markselectionchanged', async (event) => {
  const marks = await event.detail.getMarksAsync();
  console.log(marks);
});

// Get parameter and change its value
const param = await viz.workbook.findParameterAsync('Min Sales Threshold');
await param.changeValueAsync(5000);
```

### Authentication Options for Embedding

| Method | How |
|---|---|
| **Connected Apps (Direct Trust)** | Server-signed JWT; no Tableau login prompt |
| **EAS (External Auth Server)** | External IdP handles SSO; server trusts IdP tokens |
| **Core-based licence + Guest** | View without any login — core-based licences only |
| **Standard site account** | Viewer must have Tableau account and log in |
