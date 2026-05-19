---
source: Salesforce Trailhead — CRM Analytics Administration Basics; Quick Start: CRM Analytics; CRM Analytics Data Integration Basics; trailhead.salesforce.com (2026-05-17)
product: CRM Analytics
section: implementation-guide
last-updated: 2026-05-17
---

# CRM Analytics — Implementation Guide

## Pre-Implementation Checklist

Before starting any CRM Analytics engagement, verify:

- [ ] CRM Analytics license is provisioned (Growth or Plus) — confirm in Setup → Company Information → Licenses
- [ ] At minimum one `CRM Analytics Plus Admin` permission set exists and is assigned to the implementing user
- [ ] Salesforce data to be analysed is identified (which objects, which fields)
- [ ] Data volumes are estimated (record counts per object — affects sync time and dataset size)
- [ ] Row-level security requirements are defined (who sees what — owner-only, role hierarchy, custom)
- [ ] Existing Analytics apps or dataflows in the org are inventoried to avoid conflicts

## Phase 1 — Setup and Enable Features

### Step 1: Enable CRM Analytics

Setup → Analytics → Getting Started → Enable CRM Analytics

This one-time action provisions the Analytics Studio and Data Manager in the org.

### Step 2: Assign Permission Sets

Assign to all users before proceeding:

```
Permission Sets → CRM Analytics Plus User → Manage Assignments → Add Users
Permission Sets → CRM Analytics Plus Admin → Manage Assignments → Add admin users
```

### Step 3: Configure Data Manager

Setup → Analytics → Data Manager → Settings

Key settings:
- **Default Timezone:** Set to the org's primary timezone for consistent date calculations
- **Fiscal Year Start Month:** Must match the org's fiscal year setting or date-based reports will be wrong
- **Auto-install Updates:** Enable for managed template apps to receive Salesforce updates

### Step 4: Enable Additional Features (as needed)

| Feature | Where to Enable | When |
|---|---|---|
| Conversational Queries | Analytics Settings → Conversational Queries | Always — low-effort high-value |
| Einstein Discovery | Analytics Settings → Predictions | When predictive analytics is in scope |
| Mobile Dashboard | Enabled by default | Always works |
| Direct SOQL Query | Enabled by default | When real-time Salesforce data needed |
| Advanced Analytics | Analytics Settings | For templated app customisation |

## Phase 2 — Connect Data (Data Sync)

### Step 1: Enable Connected Objects

Data Manager → Connected Objects → toggle each Salesforce object to Enabled

**Minimum object set for a Sales Analytics implementation:**
- Opportunity
- Account
- Contact
- User
- OpportunityHistory (for pipeline trend)
- OpportunityTeamMember (if team selling is in scope)

For Service Analytics add:
- Case
- CaseComment
- CaseHistory
- Contact
- User

### Step 2: Select Fields to Sync

For each connected object, select only the fields needed for analysis. Over-syncing increases runtime and dataset size.

**Opportunity field selection guide:**
- Always include: `Id, AccountId, Name, Amount, CloseDate, StageName, OwnerId, RecordTypeId, Type, ForecastCategoryName, IsClosed, IsWon, CreatedDate, LastModifiedDate`
- Include if in scope: `CampaignId, LeadSource, Probability, TotalOpportunityQuantity, ExpectedRevenue`
- Exclude: long text fields, formula fields that derive from already-included fields, unused custom fields

### Step 3: Run Initial Sync

Data Manager → Connected Objects → Run Now (for each enabled object)

Monitor in Data Manager → Job Log. All objects must show "Completed" status before building recipes.

**First-sync timing estimates:**
| Object Size | Approximate Sync Time |
|---|---|
| < 100K records | 2–5 minutes |
| 100K–1M records | 10–30 minutes |
| 1M–5M records | 30–90 minutes |
| > 5M records | 2+ hours — consider incremental field selection |

## Phase 3 — Build Data Pipelines

### Using Recipes (Recommended)

Data Manager → Recipes → New Recipe

**Standard pattern for a Sales pipeline dataset:**

1. **Input node:** Connected Object = Opportunity
2. **Input node:** Connected Object = User (for owner names)
3. **Join node:** Join Opportunity.OwnerId = User.Id (Left join — keep all Opportunities even if no User match)
4. **Input node:** Connected Object = Account
5. **Join node:** Join Opportunity.AccountId = Account.Id (Left join)
6. **Filter node:** Filter out junk records if needed (e.g., IsDeleted = false is automatic; add record type filters if applicable)
7. **Transform node:** Rename fields to user-friendly labels; set field types
8. **Formula node:** Add calculated fields (e.g., DaysToClose = DATEDIFF(CloseDate, CreatedDate, "DAY"))
9. **Output node:** Name the dataset (e.g., `Opportunities_Pipeline`); set run schedule

**Recipe scheduling:**
- Once-daily at 2 AM org timezone is the standard default
- For active sales dashboards, hourly is reasonable for objects under 500K records
- Never schedule more frequently than every 20 minutes — sync overhead accumulates

### Dataset API Names

Dataset API names (set in the Output node) are the identifiers used in SAQL queries and dashboard widget configurations. Use descriptive, stable names:
- `Opportunities_Pipeline`
- `Cases_ServiceOps`
- `Accounts_360`

Do not use spaces or special characters. Renaming a dataset API name breaks all SAQL queries referencing it.

## Phase 4 — Build the Analytics App

### Step 1: Create an App

Analytics Studio → Create → App → Empty App (or From Template)

Name the app clearly: `[CustomerName] Sales Analytics`, `[CustomerName] Service Ops`.

### Step 2: Build Dashboards

Dashboard Designer → Add widgets → configure queries → arrange layout.

**Standard Sales Analytics dashboard pages:**
1. **Pipeline Overview:** Total pipeline, weighted pipeline, count of open deals, avg deal size — metric widgets + bar chart by stage
2. **Activity Trends:** Closed won over time (line chart by month), stage conversion funnel
3. **Rep Performance:** Table of reps with pipeline, wins, avg deal size, win rate
4. **Account Health:** Scatter plot of account size vs engagement; map chart if geo data available

### Step 3: Configure Filters and Faceting

Every dashboard needs at minimum:
- Date range toggle (current quarter / current year / all time)
- Owner/team selector (picklist toggle)
- Record type selector (if multiple record types in scope)

Faceting handles same-dataset cross-filtering automatically. Add explicit bindings for cross-dataset filtering.

### Step 4: Set Security Predicates

For every dataset that contains user-specific data, set the security predicate before sharing the app. See `security-model.md` for predicate patterns.

### Step 5: Share the App

Analytics Studio → App → Share → add users, roles, or profiles → set access level (Viewer for end users, Editor for power users, Manager for admins).

## Phase 5 — Embed in Lightning

For any dashboard that should appear in context of a Salesforce record:
1. Edit the record page in App Builder
2. Add the **CRM Analytics Dashboard** component
3. Select the dashboard, configure the record-context filter
4. Activate the page for the relevant profiles

See `dashboards.md` — Embedding section for detailed steps and filter configuration.

## Deployment: Sandbox → Production

CRM Analytics apps, dashboards, datasets, and dataflows are metadata types and deploy via standard Salesforce change sets or SFDX.

**Metadata types to include:**
- `WaveApplication` (app)
- `WaveDashboard` (dashboard)
- `WaveDataset` (dataset registration — not the data itself)
- `WaveDataflow` (dataflow JSON)
- `WaveRecipe` (recipe)
- `WaveTemplateBundle` (if using template apps)
- `WaveXmd` (extended metadata for datasets)

**Critical deployment gotcha:** Dataset data does not deploy — only the metadata (schema + configuration). After deploying to production:
1. Enable Data Sync for the same objects in production
2. Run Data Sync
3. Run the recipe/dataflow to populate the dataset
4. Validate security predicates

The app will appear empty in production until the data pipeline runs.

**Package.xml snippet for CRM Analytics:**
```xml
<types>
    <members>*</members>
    <name>WaveApplication</name>
</types>
<types>
    <members>*</members>
    <name>WaveDashboard</name>
</types>
<types>
    <members>*</members>
    <name>WaveDataflow</name>
</types>
<types>
    <members>*</members>
    <name>WaveRecipe</name>
</types>
<types>
    <members>*</members>
    <name>WaveXmd</name>
</types>
```

## Common Gotchas

| Gotcha | Impact | Prevention |
|---|---|---|
| Data Sync failure not surfaced to users | Dashboard shows stale data silently | Monitor Data Manager job log daily; set up alert flows on job failure |
| Security predicate not set in production | All users see all data | Pre-deployment checklist: predicate set = required |
| Dataset API name changed post-deployment | All SAQL queries break | Treat dataset API names as immutable after first deployment |
| Fiscal year not configured before first recipe run | Date groupings are wrong (calendar year used instead of fiscal) | Set fiscal year in Analytics Settings before first recipe run |
| Template app updated by Salesforce, custom changes overwritten | Dashboard customisations lost | Never edit template app dashboards directly — clone first |
| Too many SOQL Direct Query steps | Governor limits hit during dashboard load | Replace with Data Sync + recipe for objects > 10K records |
| Embedded dashboard shows admin data in shared views | Predicate bypass for admins is confusing | Always test as a non-admin Viewer user before go-live |
