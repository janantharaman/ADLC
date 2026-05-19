---
source: tableau.com/learn/get-started; tableau.com/why-tableau/what-is-tableau; tableau.com/products/cloud-bi; tableau.com (2026-05-17)
product: Tableau
section: overview
last-updated: 2026-05-17
---

# Tableau — Overview

## What Tableau Is

Tableau is a visual analytics platform that enables people and organisations to explore, understand, and communicate data through interactive visualisations. Founded in 2003 as a Stanford computer science project, it was acquired by Salesforce in 2019.

Core technology: **VizQL** — a patented engine that translates drag-and-drop user actions into database queries and renders the results as visual graphics instantly. This is what makes Tableau feel fast and exploratory compared to traditional BI tools that require SQL knowledge.

Tableau is positioned as an end-to-end analytics platform: connect to data → clean and prepare → explore and build vizzes → share and collaborate.

## Product Family

| Product | Description | Deployment |
|---|---|---|
| **Tableau Desktop** | The authoring tool for building workbooks, dashboards, and stories | Local install (Windows / Mac) |
| **Tableau Cloud** | Fully hosted cloud analytics platform — publish, share, and collaborate | SaaS (Salesforce-managed) |
| **Tableau Server** | Self-hosted version of Tableau's sharing platform | On-premises or IaaS (Windows / Linux) |
| **Tableau Prep Builder** | Visual data preparation — flows for cleaning, joining, reshaping data | Local install (Windows / Mac); also web authoring |
| **Tableau Prep Conductor** | Scheduling, monitoring, and governance for Prep flows | Bundled with Tableau Server / Cloud |
| **Tableau Public** | Free version for public data stories | Cloud (all content is public) |
| **Tableau Pulse** | AI-driven proactive insights pushed to users in Slack, Teams, email | Included with Tableau Cloud |
| **Tableau Next** | Next-generation platform including Tableau Semantics (composable semantic layer) | Cloud (in rollout) |
| **Tableau Agent** | Agentic AI for data prep, analysis automation, conversational analytics, dashboard narratives | Cloud feature |
| **Tableau MCP** | Connects Tableau to external AI agents via Model Context Protocol | Cloud feature |

## User Role Licences

Tableau licensing is user-role based. Every user has one of three roles:

| Role | What They Can Do | Licence Tier |
|---|---|---|
| **Creator** | Full authoring: connect to data, build in Desktop, use Prep Builder, publish to Cloud/Server | Highest cost; includes Desktop + Prep |
| **Explorer** | Browse, edit, and create vizzes on Cloud or Server (no Desktop); can interact with all published content | Mid tier |
| **Viewer** | Browse and interact with published dashboards on Cloud/Server; cannot edit or create | Lowest cost |

**Creator licence bundle:** Tableau Desktop + Tableau Cloud + Tableau Prep Builder + Tableau Pulse.

## Admin Roles

| Admin Type | Scope |
|---|---|
| **Tableau Cloud Admin** | Manage the Cloud site: add users, set permissions, manage content, configure auth, monitor capacity |
| **Tableau Server Admin** | Install, configure, and maintain Tableau Server (Windows or Linux); manage TSM (Tableau Services Manager) |
| **Customer Portal Admin** | Manage licences and add users via the Salesforce/Tableau customer portal |

## Tableau Cloud

Tableau Cloud is the fully managed SaaS deployment. Key characteristics:
- **No infrastructure:** No installation, no upgrade management, always on the latest version
- **Hyperforce:** Built on Salesforce's Hyperforce infrastructure for global deployment
- **Global regions:** 11 regions including US, UK, Germany, India, Singapore, Japan, Australia
- **Compliance:** SOC II, ISO, HIPAA, GDPR, PCI out of the box
- **Tableau Cloud Manager:** Central admin console for managing multi-site deployments, usage, capacity
- **Platform Data API:** REST API for programmatic access to audit and usage data across all tenants
- **Salesforce integration:** Native embedding in Salesforce Lightning; SSO with Salesforce auth; Slack/Teams integration

## Tableau Server

Tableau Server is the self-hosted alternative for organisations that need data to stay within their own infrastructure.

Key differences from Cloud:
- Organisation manages upgrades, patching, scaling, and availability
- No automatic feature updates — requires planned upgrade cycles
- Full control over network topology, security zones, and data routing
- Tableau Services Manager (TSM) is the CLI and web-based admin tool

**When to recommend Tableau Server over Cloud:**
- Regulated industries with data residency requirements that Cloud regions do not satisfy
- Extremely large data volumes where on-premises data proximity matters
- Existing infrastructure investment and internal server team

## Tableau and Salesforce Integration

Since the 2019 acquisition, Tableau and Salesforce are increasingly integrated:

| Integration Point | Description |
|---|---|
| Salesforce Connector | Native Salesforce data source connector in Tableau — connects to any Salesforce org via OAuth, queries standard and custom objects via SOQL |
| Embedded Analytics | Tableau dashboards embed in Salesforce Lightning pages via the **Tableau Viz** Lightning component |
| CRM Analytics vs Tableau | CRM Analytics lives inside Salesforce; Tableau is a separate tool. For Salesforce-first teams, CRM Analytics is usually the right choice. Tableau is better when the data story spans multiple non-Salesforce systems. |
| Tableau Pulse in Salesforce | Pulse metric updates surface inside Salesforce via the Slack/Teams integrations that Salesforce users already use |

## Community and Learning Resources

| Resource | Description |
|---|---|
| Tableau Public | Free platform to publish and explore public data stories; 150K+ community members |
| Tableau Community Forums | Q&A and discussion |
| Tableau eLearning | 240 eLearning lessons via the Tableau training platform |
| Tableau Instructor-Led Training | 11 courses — Creator, Admin, Server tracks |
| How-to Videos | 109 videos on specific features |
| Data Literacy Program | Free online course on statistics, data types, and data storytelling fundamentals |
| Trailhead | Tableau content on Salesforce Trailhead for Salesforce-context learning |
| Tableau Visionaries | Community recognition programme for top contributors |
