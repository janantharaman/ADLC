---
source: help.tableau.com — Server Authentication; Permissions; Server Process Overview; Tableau Cloud overview (2026-05-17)
product: Tableau Server / Tableau Cloud
section: server-cloud-admin
last-updated: 2026-05-17
---

# Tableau Server & Cloud — Administration Reference

## Tableau Server vs Tableau Cloud

| Dimension | Tableau Server | Tableau Cloud |
|---|---|---|
| Infrastructure | Self-hosted (on-prem or IaaS) | Fully managed by Salesforce/Tableau |
| Upgrades | Manual, planned upgrade cycles | Automatic — always on latest version |
| Scaling | Manual capacity planning | Auto-scales |
| Admin tool | Tableau Services Manager (TSM) | Tableau Cloud Manager web UI |
| Compliance regions | Customer-managed | 11 global regions (US, UK, Germany, India, Singapore, Japan, Australia, etc.) |
| MFA | Available via IdP integration | Native MFA built in |
| Compliance certs | Customer responsibility | SOC II, ISO, HIPAA, GDPR, PCI included |

**When to recommend Server:** Regulated industries requiring on-premises data; existing infrastructure investment; data residency requirements not met by Cloud regions.

**When to recommend Cloud:** New deployments, no data residency constraints; want zero infrastructure management; fastest path to Tableau Pulse and AI features.

## Authentication

### Identity Stores (Tableau Server — mutually exclusive)

| Store | Available Auth Methods |
|---|---|
| **Local** | Basic, SAML, Site SAML, OpenID Connect (OIDC), Connected Apps, Trusted Auth, Mutual SSL |
| **Active Directory** | Basic, SAML, Kerberos, SSPI (auto-SSO), Connected Apps, Trusted Auth, Mutual SSL |
| **LDAP** | Basic, SAML, Connected Apps, Trusted Auth, Mutual SSL |

### Authentication Methods

**Local Authentication**
Tableau Server verifies credentials directly. Supports password policies and account lockout. MFA is available on **Tableau Cloud only** — not natively on Server.

**SAML**
External IdP authenticates users and sends a SAML assertion to Tableau. Supported at server-wide level and per-site level. Incompatible with combining Kerberos/SSPI/Mutual SSL/OIDC on the same server.

**OpenID Connect (OIDC)**
Users sign in via an external IdP (e.g., Google, Okta) and are automatically signed into Tableau Server. Requires Local identity store. Active Directory and LDAP are not supported with OIDC.

**Kerberos**
Active Directory only (Windows). Enables seamless SSO via Kerberos tickets. Configured separately.

**NTLM / SSPI**
Default when Active Directory is configured. SSPI enables automatic login from Windows domain credentials (SSO-like). Do not enable SSPI if also using SAML, Trusted Authentication, a load balancer, or a proxy.

**Mutual SSL**
Server confirms a valid client SSL certificate and maps the certificate's username to a Tableau account.

**Connected Apps (Direct Trust)**
Uses JSON Web Tokens (JWTs) signed with a secret registered on the Tableau Server. Enables:
- Embedded analytics without separate Tableau login (SSO for embedded views)
- REST API authentication

Two sub-types:
1. **Direct trust**: Custom secret; JWT signed server-side in embedding application
2. **EAS / OAuth 2.0 trust**: Registers an external authorization server (IdP); enables IdP-based SSO for both embedded content and REST API

**Trusted Authentication (Legacy)**
Server receives a redeemable token from a trusted web server, then authenticates the user on behalf of the web server's existing auth. Predecessor to Connected Apps — use Connected Apps for new implementations.

**Personal Access Tokens (PATs)**
Long-lived tokens for REST API authentication. Not a primary auth method — used for service account automation. Managed per-user under My Account Settings.

### Client Authentication Compatibility

| Client | Notable methods |
|---|---|
| Tableau Desktop | Basic, SAML, Kerberos, SSPI, Mutual SSL |
| Web Browser | All UI methods; Connected Apps for embedding |
| REST API | Basic, Connected Apps (JWT), PAT |
| Tableau Mobile | Basic, SAML, Kerberos (iOS), SSPI, OIDC |
| tabcmd 2.0 | Basic, PAT |

## Permissions

### Permission Model Fundamentals

- **Capabilities** = specific actions (View, Web Edit, Download, Publish, etc.)
- **Permission rules** = which capabilities are Allowed / Denied / Unspecified for a user or group on an asset
- **Effective permissions** = final result after evaluating site role, license tier, and all applicable rules

**A capability is only granted if explicitly Allowed. Unspecified = Denied.**

### Hierarchy (broadest to most granular)

1. Site role + license tier (hard ceiling)
2. Project-level rules (default for all content in the project)
3. Content-level rules (override — only in Customizable projects)
4. View-level rules (override — only when workbook hides sheet tabs)

**Best practice:** Set rules at the Project level, assign to Groups, not individuals. Delete the All Users rule or set it explicitly to avoid ambiguity.

### Project Permission Modes

| Mode | Behaviour |
|---|---|
| **Locked** | Project rules enforced uniformly across all content. Only admins, project leaders/owners can change. Recommended for production content. |
| **Customizable** | Individual asset owners can override permissions per workbook, data source, flow. |

Every content type tab (Workbooks, Data Sources, Flows) must be configured separately at the project level — permission types do not inherit across content types.

### Site Roles and Capability Ceilings

| Site Role | Web Edit | Publish | Save/Overwrite | Download Full Data |
|---|---|---|---|---|
| Viewer | Never | Never | Never | Never |
| Explorer | Yes (can't save) | No | No | No |
| Explorer (Can Publish) | Yes | Existing data only | Yes | Optional |
| Creator | Yes | Yes (new data sources) | Yes | Yes |
| Administrator | Yes | Yes | Yes | Yes |

### Key Capabilities

| Capability | Description |
|---|---|
| View | Open and see the content |
| Web Edit | Edit the workbook in a browser |
| Download Image/PDF | Export static images |
| Download Full Data | Export underlying data to CSV |
| Publish | Publish into a project |
| Overwrite | Save over existing content (user becomes new owner) |
| Save a Copy | Publish As — create a new copy without overwriting |
| Connect | Connect to a published data source |
| Extract Refresh | Trigger on-demand extract refresh |
| Move | Relocate content to another project |
| Run Explain Data | Use Explain Data feature on marks |

### Data Source Permissions (Two Layers)

1. **Data authentication** — database credentials (embedded in workbook/data source, or prompt user)
2. **Tableau Connect capability** — controls whether a Tableau user can connect to the published data source

These are independent. A user can have Connect capability but lack database credentials, or vice versa.

### Moving Content

Non-admin users need:
- Creator or Explorer (Can Publish) site role
- View + Publish capabilities on the **destination** project
- Must be content owner, or have the Move capability

## Sites (Tableau Cloud and Server)

A Tableau Server can host multiple **sites** — isolated content namespaces. Each site has its own users, groups, projects, and content. Users are not automatically shared across sites.

Tableau Cloud: typically one site per customer. Enterprise customers can have multiple sites.

**Site admin:** Full control over one site's users, content, and settings. Cannot access other sites. Distinguished from Server Admin (full cross-site control) on Tableau Server.

## Projects

Projects are organisational folders for content (workbooks, data sources, flows). Nested projects are supported (sub-projects inherit the parent's lock mode unless overridden).

**Use projects to segment by:**
- Department or team (Sales Analytics, Finance, Operations)
- Data sensitivity (Public, Internal, Confidential, Restricted)
- Deployment environment (Development, Production)

**Project Leader:** A user designated to manage a project — can add/remove members, change permissions, lock/unlock the project — without being a full site admin.

## Tableau Cloud Manager

Central admin console for organisations with multiple Tableau Cloud sites:
- Manage users and licences across all sites from one place
- Monitor capacity and usage (API calls, storage, viewer counts)
- View real-time event logs
- Pre-built activity dashboards: licence utilisation, stale content, heavy users
- **Platform Data API:** REST API endpoint for programmatic retrieval of usage, audit, and licence data across all tenants

**Automated licence reclamation:** Use Platform Data API to identify users with zero logins in 90 days → automate licence removal.

## Tableau Services Manager (TSM — Server Only)

TSM is the command-line and web-based tool for managing Tableau Server infrastructure:
- Start/stop/restart individual services
- Configure external authentication (SAML, LDAP)
- Manage TLS certificates
- Set backup and maintenance schedules
- Configure email notification and monitoring
- Scale out nodes in a distributed deployment

TSM web UI: `https://<server>:8850`

Key CLI commands:
```bash
tsm status                        # Show service status
tsm restart                       # Restart all services
tsm configuration set -k <key> -v <value>  # Change server setting
tsm authentication saml configure # Configure SAML
tsm maintenance backup            # Trigger backup
```

## Tableau Pulse (Cloud Feature)

Tableau Pulse delivers proactive, personalized metric updates to users without requiring them to open a dashboard. Built on a metrics layer — each metric is a defined KPI with a time dimension and a target.

**Delivery channels:** Slack, Microsoft Teams, email

**Key features:**
- Natural language explanations of why a metric changed
- Multi-metric Q&A ("how does my region's revenue compare to last quarter?")
- Drill-down follow-ups
- Inspector: proactive alerts when trends change or thresholds are met

**Setup:** Define metrics in Tableau Cloud → Metrics → New Metric → connect to a published data source. Metrics require a time dimension and a measure.

**Pulse in Salesforce:** Metric digests surface in Salesforce via the Slack/Teams integration, appearing in the channels Salesforce users already use.

## Tableau AI Features

| Feature | Description | Availability |
|---|---|---|
| **Tableau Pulse** | Proactive metric monitoring, NL explanations, push to Slack/Teams/email | Tableau Cloud |
| **Tableau Agent — Prep** | NL data preparation — generates multi-step plans, writes calculations | Tableau Cloud / Prep Builder |
| **Tableau Agent — Authoring** | Suggests questions, converts NL to charts/calculations | Tableau Cloud |
| **Tableau Agent — Catalog** | Auto-generates descriptions for data sources, workbooks, tables | Tableau Cloud (Data Management add-on) |
| **Tableau Agent — Dashboards** | Finds relevant dashboards, explains visualisations, highlights key insights | Tableau Cloud |
| **Tableau Next — Concierge** | Conversational analytics with root-cause analysis | Tableau Next (rollout) |
| **Tableau Next — Inspector** | Alerts when trends change or thresholds are met | Tableau Next (rollout) |
| **Tableau Next — Data Pro** | Self-serve analytics: preps data, builds vizzes, builds semantic models | Tableau Next (rollout) |
| **Tableau MCP** | Connects Tableau to external AI agents via Model Context Protocol | Tableau Cloud |

## Embedding Tableau

### Embedding API v3

Used for Tableau Server 2022.3+ and Tableau Cloud. Replaces legacy JavaScript API.

```html
<tableau-viz
  src="https://online.tableau.com/views/WorkbookName/SheetName"
  width="800"
  height="600"
  hide-tabs
  toolbar="bottom">
</tableau-viz>
```

**Capabilities via Embedding API v3:**
- SSO integration (Connected Apps / JWT)
- Custom toolbar configuration (hide/show/position)
- Filter application via URL parameters or JS API
- Event listeners (mark selection, filter change, etc.)
- Embedded web authoring
- User access control via Connected Apps

### Authentication for Embedding

| Method | How It Works |
|---|---|
| **Connected Apps (Direct Trust)** | JWT signed server-side; no Tableau login prompt for embedded viewers |
| **EAS (External Auth Server)** | External IdP handles SSO; server trusts the IdP's tokens |
| **Core-based licence + Guest** | Allows viewing without any login — only for core-based licences |
| **Standard site account** | Viewer must have a Tableau account and log in separately |

### URL Parameters for Filters

Pass filter values via URL when embedding:
```
/views/Workbook/Sheet?filter_field=filter_value
// e.g.: ?Region=West&Category=Technology
```

For multi-value filters: `?Region=West,East`

### Allow List (Admin Control)

Admins can restrict which domains are allowed to embed Tableau content — or disable embedding entirely. Configured in Site Settings → Embedding.
