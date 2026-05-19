---
source: Salesforce Trailhead — CRM Analytics Basics; Build and Administer CRM Analytics trail; trailhead.salesforce.com (2026-05-17)
product: CRM Analytics
section: overview
last-updated: 2026-05-17
---

# CRM Analytics — Overview

## What CRM Analytics Is

CRM Analytics (formerly Einstein Analytics, formerly Tableau CRM) is Salesforce's native, self-service business intelligence platform. It unifies data from multiple sources — Salesforce orgs, ERPs, data warehouses, and flat files — into a single analytical environment, delivering dashboards and AI-powered insights directly inside Salesforce.

Key characteristics:
- Salesforce-native: runs inside the Salesforce platform, respects the Salesforce security model
- Self-service: no IT dependency, no schema design, no separate installation required
- Mobile-first: works on desktop and mobile without configuration differences
- Scalable: handles large data volumes via extracted datasets stored in the Analytics platform
- Secure: inherits Salesforce org security; row-level security (RLS) configurable per dataset

## Name History

| Period | Name |
|---|---|
| 2015–2019 | Wave Analytics |
| 2019–2020 | Einstein Analytics |
| 2020–2022 | Tableau CRM |
| 2022–present | CRM Analytics |

Always use "CRM Analytics" in current engagements. Older documentation and metadata may still reference Einstein Analytics or Tableau CRM.

## Product Family Position

CRM Analytics is distinct from Tableau (the standalone BI product). Both are owned by Salesforce but serve different personas and deployment patterns:

| Dimension | CRM Analytics | Tableau |
|---|---|---|
| Deployment | Inside Salesforce org | Standalone (Cloud, Server, Desktop) |
| Data | Primarily Salesforce + extracted datasets | Any data source (100+ connectors) |
| Users | Salesforce users, sales/service teams | Enterprise BI teams, analysts |
| UI | Salesforce Lightning Experience | Tableau-specific UI |
| Licensing | CRM Analytics Growth / Plus / Einstein Predictions | Creator / Explorer / Viewer |
| Embedding | Native Lightning components | Embedded Analytics SDK |

## Core Architecture Components

```
External Data Sources (CSV, ERP, DW)
         ↓
    Data Sync / Dataflows / Recipes
         ↓
      Datasets (Analytics engine storage)
         ↓
    Lenses (single-dataset explorations)
         ↓
    Dashboards (multi-lens, multi-dataset)
         ↓
    Apps (container for dashboards, datasets, lenses)
         ↓
    Embedded in Lightning Pages / Chatter / Slack
```

### Component Definitions

**Dataset**
The fundamental data unit in CRM Analytics. A dataset is a structured collection of data optimised for fast querying by the Analytics engine. Datasets are not Salesforce objects — they are separate, compressed stores. Every dataset has:
- Dimensions (string/categorical fields — equivalent to Tableau dimensions)
- Measures (numeric fields — aggregated in queries)
- Date fields (temporal fields with special hierarchy support)
- Extended Metadata (XMD) — display formatting, aliases, colours

**Lens**
A single saved exploration of one dataset. A lens is to CRM Analytics what a worksheet is to Tableau: a single-dataset chart or table with filters and groupings applied. Lenses can be saved and shared independently.

**Dashboard**
A collection of widgets (charts, tables, metrics, filters, text) that can span multiple datasets and lenses. Dashboards are the primary delivery artefact — what users see and interact with. Built in the Dashboard Designer (point-and-click) or Dashboard JSON editor (advanced).

**App**
A container that groups related dashboards, datasets, and lenses into a shareable, permissionable unit. Apps are the deployment unit — you share an app with a user or profile, not individual dashboards. Apps can be templated for reuse across orgs.

**Dataflow**
The legacy data pipeline tool. A dataflow is a JSON-defined sequence of transformations that extracts Salesforce data, applies joins/aggregations/augmentations, and outputs one or more datasets. Dataflows run on a schedule. Being superseded by Recipes for most use cases.

**Recipe**
The modern data pipeline tool (Data Prep). Recipes use a visual, node-based interface to define data transformations — join, filter, aggregate, formula, transform. Recipes replace dataflows for new implementations. Output a dataset or write back to Salesforce objects.

**Data Sync**
The mechanism that pulls Salesforce object data into the Analytics platform as "connected objects" (raw object extracts). Data Sync runs on a schedule and stages Salesforce data for use in dataflows and recipes. Required before a dataflow or recipe can reference Salesforce data.

**Connected Objects**
Salesforce objects (standard or custom) that have been enabled for Data Sync. When synced, the object data is available as an input in dataflows and recipes.

## Licensing

| License | Key Capabilities |
|---|---|
| CRM Analytics Growth | Dashboards, lenses, datasets, dataflows, recipes, templated apps |
| CRM Analytics Plus | Everything in Growth + AI predictions, Einstein Discovery |
| Einstein Predictions | Standalone prediction builder without full Analytics |
| CRM Analytics Platform | Legacy name for Growth-equivalent license |

Assign via permission sets, not profiles. Two permission sets are required per user:
1. `CRM Analytics Plus User` (or `CRM Analytics Growth User`) — platform access
2. `CRM Analytics Plus Admin` (or `CRM Analytics Growth Admin`) — admin access for setup

## Developer Edition for Testing

Standard Trailhead Playground orgs do not include CRM Analytics. Use a dedicated CRM Analytics Developer Edition:

```
trailhead.salesforce.com/promo/orgs/analytics-de
```

This org includes a limited CRM Analytics Platform licence and pre-loaded sample datasets (DTC Electronics sales data).

## Integration with Salesforce

CRM Analytics is deeply integrated with Salesforce:
- **Embedding:** Dashboards embed natively in Lightning record pages, app pages, and home pages via standard Lightning components
- **Chatter/Slack:** Insights and dashboard snapshots share directly to Chatter feeds or Slack channels
- **Agentforce:** CRM Analytics predictions and datasets feed Agentforce actions and Einstein recommendations
- **Direct SOQL queries:** Advanced dashboards can query Salesforce data live (without extraction) via SOQL Direct Query
- **Write-back:** Recipes can write back computed values to Salesforce object fields

## Key Differentiators for PS Engagements

1. **No separate tool for Salesforce users** — analytics live where work happens; no context switch
2. **Row-level security inherits from Salesforce** — security model is not rebuilt separately
3. **Template apps** — reusable, pre-built analytics for FSC, Service Cloud, Sales Cloud ship with the platform
4. **Einstein Discovery integration** — predictive analytics built into the same interface
5. **SOQL Direct Query** — query Salesforce data live without extracting it, for small-volume, real-time use cases
