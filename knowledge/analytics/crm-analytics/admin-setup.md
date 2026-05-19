---
source: Salesforce Trailhead — CRM Analytics Administration Basics (module overview); CRM Analytics developer documentation; Salesforce product page (2026-05-17)
product: CRM Analytics
section: admin-setup
last-updated: 2026-05-17
---

# CRM Analytics — Admin Setup Reference

## What Admins Configure

CRM Analytics administration covers five areas:
1. **Setup & Enable** — turn on CRM Analytics in the org, configure Analytics Settings
2. **Assign Permissions** — grant access via permission sets, control who can view vs build
3. **Enable Features** — activate specific Analytics capabilities (AI, mobile, template apps)
4. **Control Access & Secure Data** — configure security predicates, app sharing, row-level security
5. **Set Up Apps** — configure template apps (Sales Analytics, Service Analytics, FSC Analytics)

---

## Pre-Requisites

### Licenses

| License | Purpose |
|---|---|
| **CRM Analytics Plus** | Full authoring + admin capabilities. Required for building dashboards, dataflows, recipes. |
| **CRM Analytics Growth** | Viewing dashboards only, no building. |
| **CRM Analytics Platform** (legacy) | Older name for the Analytics Plus tier. |

CRM Analytics is available as an add-on to Sales Cloud, Service Cloud, or FSC. The license must be provisioned on the org before setup can begin.

### Enabling CRM Analytics

**Setup → Analytics → Getting Started → Enable CRM Analytics**

Once enabled:
- The **Analytics Studio** app appears in the App Launcher
- The **Data Manager** app appears (for data sync and pipeline management)
- Salesforce auto-creates a default Analytics app

---

## Permission Sets

Two platform-level permission sets control access. These are **managed permission sets** — do not edit them directly.

| Permission Set | Who Gets It | What It Grants |
|---|---|---|
| **CRM Analytics Plus User** | Analysts, business users who view dashboards | View dashboards; run queries; share apps |
| **CRM Analytics Plus Admin** | CRM Analytics administrators | All Plus User permissions + manage data sync, create/edit dataflows and recipes, configure security predicates, manage app sharing |

**Assignment path:** Setup → Permission Sets → [select permission set] → Manage Assignments → Add Assignments

### Functional Permissions (within permission sets)

| Permission | Controls |
|---|---|
| Create and Edit Analytics Apps | Create new apps, share them |
| Manage Analytics Templates | Create and modify template apps |
| Edit Analytics Dataflows | Modify dataflow definitions |
| Edit CRM Analytics Recipes | Modify recipe definitions |
| Manage CRM Analytics | Full admin — all configuration |
| Upload External Data to Analytics | Load CSV/external data to datasets |
| View Analytics | View existing dashboards (minimum) |

---

## Analytics Settings (Post-Enable Configuration)

**Setup → Analytics → Settings**

Key settings to configure before first data sync:

| Setting | Why It Matters |
|---|---|
| **Fiscal Year Start Month** | Controls fiscal year in date fields. Must be set before running any recipe or dataflow — datasets created before this change need regeneration. |
| **Enable Einstein Discovery** | Activates AI-powered predictive analytics features |
| **Enable Mobile Dashboards** | Enables the Salesforce Mobile CRM Analytics app |
| **Enable Embedded Dashboards** | Required for embedding dashboards in Lightning pages |
| **Enable Public Sharing** | Allows apps to be shared publicly (all authenticated users) |

---

## Data Manager

The Data Manager is the central hub for all data pipeline operations.

**Access:** App Launcher → Data Manager

### Key Data Manager Tabs

| Tab | Purpose |
|---|---|
| **Connect** | Enable Connected Objects (Salesforce objects available for Data Sync) |
| **Monitor** | Real-time view of running and recent Data Sync jobs |
| **Dataflows** | Create, edit, and schedule dataflow definitions |
| **Recipes** | Create, edit, and schedule recipe definitions |
| **Datasets** | Browse all datasets; view lineage; configure security predicates; view schema |
| **Schedules** | Manage sync and dataflow/recipe run schedules |
| **Job Log** | History of all jobs (Data Sync, dataflows, recipes) with status, run time, error messages |

### Connected Objects

Connected Objects are Salesforce objects enabled for Data Sync (pulling data from the Salesforce database into CRM Analytics).

**Enable a Connected Object:**
1. Data Manager → Connect → Salesforce Connectors
2. Find the object (standard or custom)
3. Toggle on "Sync" for the object
4. Select which fields to include
5. Choose sync frequency: Every hour / Every day / Custom schedule

**Considerations:**
- Only synced fields are available in recipes and dataflows
- Syncing large objects (e.g., Case with millions of records) affects Data Sync time — be selective with fields
- SystemModstamp is used for incremental sync — objects updated via bulk operations without trigger execution may miss incremental updates

### Job Log Monitoring

The Job Log is the only reliable source for detecting failed sync jobs — dashboard viewers see no error when data is stale from a failed sync.

**Best practice:** Create a Flow scheduled daily to query the Analytics job log and post to Slack/Chatter if any job has "Failed" status.

---

## App Management

### Creating an App

1. Analytics Studio → Create → App
2. Choose: Blank App or Template App
3. Set App Name and share settings
4. Add dashboards, lenses, and datasets

### Template Apps

Pre-built analytics applications aligned to Salesforce Clouds:
- **Sales Analytics** — pipeline, forecast, team performance
- **Service Analytics** — case trends, agent performance, CSAT
- **FSC Analytics** — advisor performance, AUM, relationship health

**Never edit template app dashboards directly** — Salesforce updates managed template apps automatically, overwriting custom edits.

**Always clone first:**
1. In the app: clone the dashboard (Save As)
2. Or: clone the entire app (Save App As)
3. Work in the clone only

### App Sharing Modes

| Mode | Who Can Access |
|---|---|
| **Private** | Only the app owner (default for new apps) |
| **Shared** | Named users and groups explicitly added |
| **Public** | All users with the CRM Analytics Plus User permission set |

### Access Levels within Shared/Public Apps

| Level | What the User Can Do |
|---|---|
| **Viewer** | View dashboards and run explorations. Cannot create or edit assets. |
| **Editor** | All Viewer rights + create/edit/delete dashboards, lenses, datasets within the app |
| **Manager** | All Editor rights + manage app sharing, change app settings, delete the app |

---

## Deployment Checklist

When deploying CRM Analytics from sandbox to production:

| Step | Notes |
|---|---|
| Include `WaveApplication`, `WaveDashboard`, `WaveDataset`, `WaveDataflow`, `WaveRecipe`, `WaveXmd` in package.xml | All required metadata types — missing any breaks the deployment |
| Enable same Connected Objects in production | Recipes fail if connected objects are not enabled in the target org |
| Set security predicates in production post-deploy | Predicates are configuration, not code — verify manually in Data Manager after each deployment |
| Run all Data Sync jobs | Data does not migrate — run sync in production before go-live |
| Run all recipes/dataflows | Datasets are empty until pipeline runs |
| Set Analytics fiscal year before first pipeline run | Cannot change retroactively without regenerating all datasets |
| Test as a non-admin Viewer user | Admin users bypass security predicates — always verify as a Viewer |

---

## CRM Analytics REST API

CRM Analytics exposes a REST API for programmatic access to datasets, dashboards, and queries.

**Base URL:** `https://<instance>.salesforce.com/services/data/v<version>/wave/`

### Key Resources

| Resource | Operations |
|---|---|
| `/wave/datasets` | List, create, delete datasets |
| `/wave/datasets/<id>/versions` | Manage dataset versions |
| `/wave/datasets/<id>/records` | Query dataset records |
| `/wave/lenses` | List and create lenses |
| `/wave/dashboards` | List, create, update dashboards |
| `/wave/recipes` | List, start, stop, schedule recipes |
| `/wave/dataflows` | List, start, stop, schedule dataflows |
| `/wave/query` | Execute SAQL or SOQL queries against datasets |

### Authentication

Uses standard Salesforce OAuth 2.0 (same as all Salesforce APIs). Access token obtained via:
- Username/Password flow
- Connected App OAuth flow (recommended for production integrations)
- JWT Bearer Token flow (for server-to-server)

### External Data API

Upload external (non-Salesforce) data to CRM Analytics datasets via multipart HTTP uploads:

1. `POST /wave/datasets` — create the dataset metadata
2. `PUT /wave/datasets/<id>/parts/<N>` — upload data parts (CSV or binary)
3. `POST /wave/datasets/<id>/commit` — finalise the upload

Supports incremental append, full replace, or upsert operations.

---

## Subscription and Alert Monitoring

CRM Analytics has no native data-driven alerting equivalent to Tableau's threshold alerts. Alert patterns:

1. **Scheduled Flow with SOQL:** Query the job log daily via a scheduled Flow → post to Slack/email if any job failed
2. **Dashboard Subscription (limited):** Analytics Studio dashboards can be subscribed to for scheduled email delivery — not threshold-based
3. **Einstein Discovery Predictive Alerts:** For predictive score thresholds — available with Einstein Discovery add-on
