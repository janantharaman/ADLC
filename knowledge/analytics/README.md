---
section: analytics-index
last-updated: 2026-05-17
---

# Analytics Knowledge Base

This folder contains grounded reference knowledge for Salesforce analytics products used in GDC PS engagements.

## Structure

```
analytics/
  crm-analytics/          ← CRM Analytics (formerly Einstein Analytics / Tableau CRM)
    overview.md           ← What it is, architecture, components, licensing
    data-model.md         ← Datasets, dataflows, recipes, data sync, connected objects
    dashboards.md         ← Dashboard designer, widgets, bindings, SAQL, embedding
    security-model.md     ← Permission sets, row-level security, apps, sharing
    implementation-guide.md ← Setup, data integration, deployment checklist
    gotchas.md            ← 20 known issues: data pipeline, security, dashboards, deployment, SAQL
    admin-setup.md        ← Licenses, enabling in Setup, permission sets, Analytics Settings, Data Manager, app sharing, deployment checklist, REST API
  tableau/                ← Tableau (Desktop, Cloud, Server, Prep, Pulse)
    overview.md           ← Product family, roles, architecture, licensing
    data-model.md         ← Dimensions, measures, calculated fields, data types
    visualizations.md     ← Chart types, dashboards, stories, filters, maps
    publishing.md         ← Publishing to Cloud/Server, permissions, extracts
    prep.md               ← Tableau Prep Builder and Conductor
    data-connections.md   ← Relationships vs joins, unions, blending, live vs extract, Hyper API
    functions-reference.md ← Complete function reference (Number/String/Date/Logical/Aggregate/User/Table Calc/RAWSQL) + Parameters + Reference Lines
    server-cloud-admin.md ← Authentication methods, permissions model, sites, TSM, Pulse, AI features, embedding
    advanced-analytics.md ← LOD expressions (FIXED/INCLUDE/EXCLUDE), order of operations, table calc partitioning, trend lines, forecasting, Explain Data
    advanced-design.md    ← Maps (types/geocoding/background), dashboard actions, sets, groups, bins, shelves/marks card, performance optimization
    governance-sharing.md ← File types, permissions deep-dive, global filters, Data Management/Catalog, virtual connections, data alerts, accessibility
    viz-techniques.md     ← Mark types, dual axis, combo charts, dashboard layout (tiled/floating/containers), sorting, workbook formatting, custom palettes, keyboard shortcuts
    filters-deep-dive.md  ← All filter types (categorical/measure/date/table calc), filter order of operations, context filters, filter cards + display modes, aggregation behaviour, parameters
    developer-apis.md     ← REST API (endpoints, TSC Python), Hyper API (create/read/update .hyper files), tabcmd (commands reference), Metadata API (GraphQL lineage), Embedding API v3
```

## When to Load Which File

| Scenario | Load |
|---|---|
| New CRM Analytics engagement scoping | `crm-analytics/overview.md` |
| CRM Analytics data pipeline design | `crm-analytics/data-model.md` |
| CRM Analytics dashboard build or embed | `crm-analytics/dashboards.md` |
| CRM Analytics security/row-level access | `crm-analytics/security-model.md` |
| CRM Analytics setup and deployment | `crm-analytics/implementation-guide.md` |
| CRM Analytics deployment issues or unexplained behaviour | `crm-analytics/gotchas.md` |
| CRM Analytics admin setup, permissions, Data Manager, app sharing | `crm-analytics/admin-setup.md` |
| Tableau implementation or training | `tableau/overview.md` |
| Tableau viz design or calculated fields | `tableau/data-model.md` + `tableau/visualizations.md` |
| Publishing to Tableau Cloud or Server | `tableau/publishing.md` |
| Data prep pipeline design | `tableau/prep.md` |
| Tableau data source design (joins, relationships, extracts) | `tableau/data-connections.md` |
| Tableau calculated field or SAQL formula lookup | `tableau/functions-reference.md` |
| Tableau Server/Cloud admin, auth, permissions, or embedding | `tableau/server-cloud-admin.md` |
| Tableau LOD expressions, order of operations, forecasting | `tableau/advanced-analytics.md` |
| Tableau maps, sets, groups, bins, performance, best practices | `tableau/advanced-design.md` |
| Tableau file types, governance, Data Catalog, data alerts | `tableau/governance-sharing.md` |
| Tableau mark types, dual axis, dashboard layout, shortcuts | `tableau/viz-techniques.md` |
| Tableau filters (all types), filter cards, context filters, parameters, aggregation | `tableau/filters-deep-dive.md` |
| Tableau REST API, Hyper API, tabcmd, Metadata API, Embedding API code | `tableau/developer-apis.md` |
