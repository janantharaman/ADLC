# Data 360 — Overview

## What Is Data 360?

Data 360 is Salesforce's real-time customer data platform (CDP), built natively on the Salesforce platform. It unifies data from any source, resolves customer identity across channels, computes unified profiles, and activates that data across marketing, sales, service, and AI surfaces.

**Naming history:** Salesforce CDP → Genie (2022) → Data Cloud (2023) → Data 360 (2025)

The product is still referred to as "Data Cloud" in org metadata, CLI commands, and most current documentation. "Data 360" is the go-to-market name introduced at Dreamforce 2025.

---

## Core Value Proposition

| Problem | Data 360 Solution |
|---|---|
| Customer data fragmented across 10+ systems | Data streams ingest and normalize into a single lake |
| Same person has 5 different email addresses | Identity resolution merges into one Unified Individual |
| Segments take 24 hours to refresh | Real-time calculated insights and streaming ingestion |
| AI agents lack customer context | Data Graph grounds Agentforce with unified profile data |
| Activating audiences requires ETL pipelines | Native activation targets push directly to channels |

---

## Architecture Components

```
External Sources                   Data 360 Platform                    Activation / AI
─────────────────    ────────────────────────────────────────────    ─────────────────
CRM / ERP        →   Data Streams                                →   Marketing Cloud
Web / Mobile     →   Data Lake Objects (DLO)                     →   Sales / Service
Marketing Cloud  →   Identity Resolution  →  Unified Profile     →   Agentforce
Partner Data     →   Data Graphs                                 →   Activation Targets
Data Warehouses  →   Segments / Calculated Insights              →   External Platforms
```

### Key Components

**Data Streams** — the ingestion layer. Each stream maps a source to a Data Lake Object. Supports Salesforce objects (live sync), file-based (CSV/JSON via S3/SFTP), API (connector framework), and streaming (Pub/Sub API).

**Data Lake Objects (DLO)** — raw storage tables in the data lake. Schema-flexible. Never directly queryable by end users — always surfaced via Data Model Objects.

**Data Model Objects (DMO)** — the semantic layer. Mapped from DLOs and conform to the standard data model. Used for segmentation, calculated insights, and profile queries.

**Identity Resolution** — ruleset-based matching engine that links records across DLOs into a single `Unified Individual`. Match rules: exact match, fuzzy, rule priority. Reconciliation determines which source wins for each attribute.

**Unified Profile** — the merged view of a customer across all sources. Comprises `Unified Individual` + related `Unified Contact Point` records (email, phone, address).

**Calculated Insights** — SQL-based metrics computed and stored on the profile (e.g., LTV, churn score, days since last purchase). Refreshed on schedule or triggered.

**Segments** — filter-based audience definitions built on DMOs and calculated insights. Can be batch or real-time (streaming). Published to activation targets.

**Data Actions** — trigger Salesforce platform events, Flow, or webhooks in real time when a profile enters/exits a segment or a streaming event matches a condition.

**Activation Targets** — destinations: Marketing Cloud, Advertising (Google, Meta), CRM objects, partner activation, cloud storage.

**Data Graphs** — structured knowledge graph that represents relationships between unified entities. Primary input for grounding Agentforce agents with contextual customer data.

---

## Licensing

Data 360 is licensed separately from core Salesforce CRM. Key license types:

| License | What It Unlocks |
|---|---|
| Data Cloud — Salesforce Connector | Ingest from Salesforce orgs (Sales/Service/Marketing) |
| Data Cloud — Data Services | File ingestion, API connectors, Identity Resolution |
| Data Cloud for Marketing | Activation to Marketing Cloud, segments |
| Data Cloud for Sales/Service | Grounding Agentforce, CRM data actions |
| Data Cloud Add-On — Starter/Plus/Enterprise | Tiered by data volume, profile count, activation targets |

> Always confirm which Data Cloud SKUs are provisioned before designing ingestion scope. Missing a connector license blocks that data stream entirely.

---

## Where Data 360 Fits in the Salesforce Portfolio

- **Agentforce**: Data 360 is the memory and context layer for AI agents. Data Graphs feed the Retrieval Augmented Generation (RAG) pipeline.
- **Marketing Cloud**: Segments activate to Journey Builder, Email Studio, Mobile Studio.
- **Sales Cloud / Service Cloud**: Unified profiles surface inline on records via the Data Cloud profile component; data actions trigger CRM automation.
- **CRM Analytics**: Data Cloud datasets can be synced to CRM Analytics for dashboard reporting.
- **Revenue Cloud**: Order and contract data can be ingested to build customer lifetime value profiles.
