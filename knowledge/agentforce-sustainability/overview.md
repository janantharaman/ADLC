# Agentforce Sustainability (Net Zero Cloud) — Overview

## Naming History
Net Zero Cloud (2021) → **Agentforce Net Zero / Agentforce Sustainability** (2025)

The product is still referred to as "Net Zero Cloud" in org metadata, permission sets, CLI commands, and most current documentation. "Agentforce Sustainability" or "Agentforce Net Zero" is the go-to-market name introduced at Dreamforce 2025.

> Source: salesforce.com/in/products/net-zero-cloud/overview/

---

## What It Is

Agentforce Sustainability is Salesforce's enterprise sustainability management platform, built natively on the Salesforce CRM. It consolidates sustainability and operational data from across an organisation, calculates greenhouse gas (GHG) emissions per the GHG Protocol, and enables ESG disclosure reporting against major regulatory frameworks.

**Core value:** Transform fragmented sustainability data into auditable carbon accounting, actionable emissions insights, and AI-drafted regulatory disclosures — without leaving the Salesforce platform.

---

## Key Modules and Capabilities

### Emissions Management
- **Carbon Conversion** — automatically converts utility bills, travel data, and fleet data to CO₂e emissions using the GHG Protocol standard
- **Scope 1, 2, and 3 tracking** — full coverage across direct, indirect, and value chain emissions
- **Environmental Accounting for Travel** — distance-based calculations for air, rail, and road travel; corrects fleet odometer errors
- **Water and Waste Management** — dedicated tracking objects and dashboards

### Scope 3 Emissions Hub
Manages upstream and downstream emissions across:
- Suppliers (purchased goods and services)
- Subsidiaries and joint ventures
- Franchisees
- Distributors and customers

Enables external stakeholder data collection via guided digital experiences (OmniStudio-powered) and validates submissions before consolidation.

### Analytics and Forecasting
- **Climate Action Dashboard** — centralized view of emissions, travel, water, and waste across the organisation
- **What-If Analysis** — scenario simulation to forecast future emissions trajectories and measure net zero target progress
- **Programme Analysis** — compares sustainability initiatives across three metrics: emissions savings, marginal abatement cost, and cumulative net impact
- **CRM Analytics integration** — deeper custom dashboards using the Salesforce Analytics layer

### ESG Disclosure and Reporting
- **Framework-specific report builders** for: CSRD (Corporate Sustainability Reporting Directive), SASB, GRI, CDP
- **Agentforce ESG Authoring** — AI drafts narrative sections of sustainability reports from platform data
- **Microsoft 365 Word plug-in** — collaborative report creation with rich text support; identifies missing data
- **CSRD Data Model and Mapping** — structured quantitative data capture aligned to CSRD requirements

### Data Collection and Automation
- **Assisted Data Collection** — automated stakeholder engagement workflows for data submission and validation
- Natural language querying of sustainability data (Einstein AI)
- MuleSoft connectors for ingesting data from third-party systems (ERP, utility APIs, fleet management)

---

## GHG Protocol Scope Coverage

| Scope | Definition | Examples |
|---|---|---|
| Scope 1 | Direct emissions from company-owned/controlled sources | Natural gas combustion, company vehicles, refrigerants |
| Scope 2 | Indirect emissions from purchased energy | Electricity, steam, heat, cooling |
| Scope 3 | All other indirect (value chain) emissions | Business travel, supplier goods, employee commuting, product use |

Scope 3 is the largest and hardest to track. The Scope 3 Emissions Hub addresses this directly.

---

## Target Industries

Applicable across all industries. High-adoption sectors:
- Manufacturing and Automotive
- Engineering, Construction, and Real Estate
- Retail and Consumer Goods
- Public Sector
- Agriculture and Mining
- Telecommunications
- Financial Services (ESG investor reporting)

---

## Integrations

| System | Integration Type | Purpose |
|---|---|---|
| MuleSoft | Native connector + AgentExchange | Ingest ERP, utility, fleet data |
| CRM Analytics | Native | Custom dashboards, deeper analysis |
| Field Service | Native | Fleet and truck roll emissions data |
| OmniStudio | Native | Supplier/subsidiary data collection portals |
| Microsoft 365 Word | Plug-in | Report authoring and collaboration |
| Net Zero Marketplace | Native | Purchase emission factor datasets |
| Partner ecosystem | API | Arcadia Data, Riskonnect ESG, CSRHub, SocialSuite |

---

## Licensing

- Multiple editions (Starter, Growth, Plus — verify with AE for current SKUs)
- CRM Analytics for Net Zero Cloud requires separate licensing
- Emission factor datasets purchasable through Net Zero Marketplace
- Assisted Data Collection (Scope 3 Hub external portal) may require OmniStudio licensing

> Source: salesforce.com/in/products/net-zero-cloud/overview/
