# Salesforce B2C Commerce — Overview

## What is Salesforce B2C Commerce?

Salesforce B2C Commerce (formerly Demandware) is a cloud-based ecommerce platform for building, managing, and scaling consumer-facing digital storefronts. It provides a multi-tenant SaaS architecture designed for high-traffic retail scenarios, combining storefront technology, catalog management, order processing, and API layers under a single platform.

The platform supports two main storefront paradigms:
- **SFRA (Storefront Reference Architecture)** — server-side rendered, cartridge-based storefront running on the B2C platform itself
- **PWA Kit / Composable Storefront** — React-based headless storefront hosted on Managed Runtime (MRT), using SCAPI for all data access

---

## Architecture

### Realms, Instances, and Instance Groups

A customer's B2C Commerce deployment is organized into a **realm** — a single tenant environment that spans two instance groups:

| Instance Group | Contents | Purpose |
|---|---|---|
| **PIG** (Primary Instance Group) | Staging, Development, Production | Merchant-controlled promotion pipeline |
| **SIG** (Secondary Instance Group) | 3–47 On-Demand Sandboxes | Developer testing environments |

Most merchants operate with a single realm. The four-character realm code (e.g., `zzzv`) appears in hostnames and is required for sandbox management API calls.

### Four Instance Types

| Type | Group | Description |
|---|---|---|
| **Sandbox** | SIG | Developer testing. Most system jobs disabled. Short-lived, resettable. |
| **Staging** | PIG | Content/code testing before production. Data replicated from Staging to Production. |
| **Development** | PIG | Production environment simulation without caching. Used by QA. |
| **Production** | PIG | Live storefront. Full caching enabled. Replicated from Staging. |

### Hostname Pattern

B2C Commerce instances use hostnames in the format:
```
<instance-id>.dx.commercecloud.salesforce.com
```
or the legacy format:
```
<realm>-<instance>.demandware.net
```

### Data Flow

- **Data Replication** is one-way: Staging → Production
- **Code Upload** is performed via WebDAV into code version directories
- **Import/Export** (IMPEX) is the mechanism for feeding external system data (catalogs, inventory, orders, customers)
- **Catalog Feeds** provide supplemental catalog information from external systems

---

## Key Concepts

### SFRA — Storefront Reference Architecture

SFRA is the Salesforce-recommended server-side rendering framework for B2C Commerce storefronts. It uses:
- **Cartridges** as the packaging and deployment unit for code
- **Controllers** for request routing (replacing legacy Pipelines)
- **ISML templates** for server-side rendering
- **Hooks** for event-driven extension points
- A **cartridge path** (colon-separated list) configured in Business Manager to determine code resolution order

### PWA Kit / Composable Storefront

A React-based headless storefront architecture:
- Uses the **Retail React App** as a foundation with product listing, product detail, cart, and checkout pages
- Hosted on **Managed Runtime (MRT)** — a Node.js/Lambda infrastructure managed by Salesforce
- Communicates exclusively with **SCAPI** (Salesforce Commerce APIs) for all commerce data
- Supports server-side rendering (Express + React) and client-side hydration
- **Storefront Next** is an evolution of PWA Kit, currently in closed pilot

### Managed Runtime (MRT)

Salesforce-managed Node.js hosting for PWA Kit storefronts:
- Organized into **Projects** and **Environments**
- Deployments are **Bundles** (SSR + shared assets)
- Accessed via the MRT dashboard at `runtime.commercecloud.com`
- Requires an **MRT API Key** for CLI/programmatic access
- Environment variables are configured per environment
- Supports logging, URL redirects, and proxy configuration

### SCAPI — Salesforce Commerce APIs

The modern REST API layer for B2C Commerce, replacing OCAPI for shopper-facing operations:
- Uses short-code and tenant-id for routing
- Base URL pattern: `https://<short-code>.api.commercecloud.salesforce.com/...`
- Requires SLAS tokens for shopper API calls
- Requires OAuth client credentials for admin/data API calls
- API families: Shopper Login, Shopper Customers, Shopper Baskets, Shopper Orders, Shopper Products, Shopper Catalog, Shopper Search, Shopper Promotions, Shopper Experience, Shopper Gift Certificates, Custom APIs

### SLAS — Shopper Login and API Security

SLAS is the identity and token management service for shopper-facing SCAPI calls:
- Issues **access tokens** and **refresh tokens** to shoppers
- Supports **guest** and **registered customer** login flows
- Requires a SLAS client (public or private) configured per tenant
- SLAS clients are managed via Business Manager or the `b2c slas` CLI commands
- The tenant-id for SLAS is the organization ID **minus the `f_ecom_` prefix**

### OCAPI — Open Commerce API

Legacy API layer, still used for:
- Business Manager administration
- Data operations (catalog, inventory, code management)
- Some shopfront operations not yet migrated to SCAPI
- Configured in Business Manager under: `Administration > Site Development > Open Commerce API Settings`
- Permissions are configured per API client ID with resource-level grants

### Cartridge Model

Cartridges are the fundamental packaging unit in B2C Commerce:
- A cartridge is a directory containing controllers, templates, scripts, forms, static assets, and metadata
- Detected by the presence of a `.project` file
- Deployed via WebDAV to `/Cartridges/<code-version>/` on the instance
- Registered per-site in Business Manager with a **colon-separated cartridge path**
- Resolution order: left-to-right in the cartridge path (leftmost wins)
- Directory names cannot exceed 50 characters
- Can contain: controllers, ISML templates, scripts, form definitions, static content (images/CSS/JS), WSDL files

### Business Manager (BM)

The web-based administration console for B2C Commerce:
- Manages sites, catalogs, products, promotions, content, customers
- Configures OCAPI permissions, WebDAV access, code versions
- Used to register cartridges to sites
- Accessible at `https://<instance>/on/demandware.store/Sites-Site/default/ViewApplication-DisplayWelcomePage`

---

## Roles in B2C Commerce

| Role | Typical Activity |
|---|---|
| **Developers** | Work on Sandbox/Staging; deploy cartridges, write controllers/hooks |
| **Merchandisers** | Manage Staging for campaigns and product information |
| **Administrators** | Control access across all instances |
| **QA Engineers** | Test on Development instances |

---

## Site Architecture Considerations

When designing a B2C Commerce deployment, architects evaluate:
- **Geographical relationships** between storefronts and the teams that maintain them
- **Shared data requirements** — whether catalogs, pricebooks, or customer data should be shared across sites
- **Localization needs** — multi-locale storefront configuration
- **Multi-site topology** — whether customer data persists across storefronts
- **Storefront choice** — SFRA (server-rendered, cartridge-based) vs PWA Kit (headless, React-based)

---

## Developer Tooling Ecosystem

The modern B2C Commerce developer toolset includes:

| Tool | Package | Description |
|---|---|---|
| **B2C CLI** | `@salesforce/b2c-cli` | oclif-based CLI for deployments, jobs, sandboxes, SLAS, eCDN, MRT |
| **B2C DX MCP Server** | `@salesforce/b2c-dx-mcp` | MCP server for AI-assisted development (Claude Code, Cursor, Copilot) |
| **B2C Tooling SDK** | `@salesforce/b2c-tooling-sdk` | TypeScript SDK for custom integrations |
| **VS Code Extension** | N/A (`.vsix`) | Developer Preview; sandbox management, cartridge sync, SCAPI explorer, debugger |
| **Agent Skills** | GitHub plugin | 30+ preconfigured skills for AI coding agents |

The tooling was formerly known as **B2C DX**. CLI package name, commands, and configuration are unchanged.

---

## Documentation Consolidation Note

As of the documentation consolidation (2025/2026), Salesforce unified the table of contents for B2C Commerce, B2C Commerce APIs (SCAPI), and Composable Storefront into a single shared navigation. Both old and new URLs resolve to the same content. Release notes are at:
- B2C Commerce: `https://help.salesforce.com/s/articleView?id=commerce.b2c_parent.htm&type=5`
- Developer Docs release notes: `https://developer.salesforce.com/docs/commerce/b2c-commerce/guide/b2c-new-and-changed-in-upcoming-release.html`
