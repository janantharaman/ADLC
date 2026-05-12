---
source_url: https://architect.salesforce.com/docs/architect/decision-guides/guide/data-360-interoperability.html
date_fetched: 2026-05-01
section: decision-guides
page_title: Data 360 Interoperability
---

## Overview

Enterprises often store data in both Salesforce and other external data lakes such as Snowflake, Google BigQuery, Databricks, Redshift, or cloud storage like Amazon S3. This siloing of data in different source system poses a challenge for companies who want to harness the full power of their data.

Architects working to bring together data across multiple data lakes face key architectural decisions around how best to integrate that data. Data 360 offers multiple options for data integration, each of which offers different pros and cons.

This guide provides a framework to evaluate which pattern best fits your requirements for latency, cost, scalability, governance, and complexity when integrating data, helping you choose when to use data ingestion, Zero Copy data federation, or a hybrid approach. The guide will also help you select between different methods of data ingestion and data federation, each of which fills a different need.

Integrating external data lakehouses with Data 360 requires careful consideration of trade-offs between data freshness, governance, and pipeline efficiency. For example, using Zero Copy data federation live queries maximize the freshness of the data but can reduce pipeline efficiency as you move more data over the network. Therefore, for most real-world implementations, a combination of ingestion and federation within a multi-cloud lakehouse ecosystem is the optimal path. This hybrid approach ensures a scalable, governed, interoperable architecture that seamlessly supports both low-latency operational workloads such as real-time personalization and fraud detection, and analytical workloads like regulatory reporting and historical trend analysis. This decision guide will help you understand how to navigate these trade-offs and select the right strategy.

## Takeaways

- **Data Ingestion:** Copies data into Salesforce Data 360, creating governed, canonical Data Models. Ideal when you need to:

Build a comprehensive Customer 360: Unify and transform disparate sources into a single, trusted profile.
Meet strict regulatory compliance: Create an auditable, centralized copy where data access and lineage can be tightly controlled.
- **Zero Copy Federation:** Queries external sources in real time without duplication, enabling real-time personalization, live dashboards, and rapid source onboarding. Two primary options with trade-offs you must balance:

Live & Caching (Accelerated Query): Best for interactive analysis and real-time dashboards on data that lives in external data platforms like Snowflake, Google BigQuery, Redshift, or Databricks. Avoids slow, costly data duplication by pushing processing down to the source system.
File Federation: Best for large-scale batch processing and AI model training on data in your cloud data lake (S3, ADLS). Avoids costly and slow ingestion by directly querying files in open table formats, unlocking massive datasets for ETL and data science workloads.
- **Hybrid Model:** Blend ingestion for Unified Profiles with federation for freshness, supporting omni-channel engagement, Agentforce-driven actions, and AI/ML training.

### Important Considerations

- Hybrid Architecture: Mixing data ingest and data federation is often needed.

Use Data Ingest on critical data for canonical data models and core governance.
Federate all other data via Zero Copy to minimize operational overhead of building and maintaining the ingestion data pipelines.
- Data Ingestion Frequency Matters: Choose the frequency based on business value, latency needs, and operational complexity.

Use real-time for time-sensitive workflows (personalization, live dashboards, Agentforce actions).
Near real-time for moderately urgent processes (campaigns, operational reports).
Batch for historical or low-velocity datasets.
- Match the Federation Pattern to Latency & Performance: Choose the one that best matches your access patterns and the requirements for freshness, performance, and cost.

Use Live Query for operational dashboards and real-time personalization where low latency is critical.
Use Caching (Accelerated Query) when queries are frequent but slightly stale results are acceptable which balances performance and cost.
Use File Federation for large-scale, throughput-heavy analytics or batch workloads which are ideal for historical or less time-sensitive datasets.
- Align the Governance with Data Residency Requirements:

Use ingestion where centralized governance is critical.
Use federation where decentralized governance is acceptable, while enforcing strict governance at the external source. Zero Copy respects source-level policies such as row-level security (RLS) and data masking.
- Prioritize Ingestion for High-Value Workflows: Apply ingestion selectively to critical processes such as identity resolution, regulatory reporting, and operational activation.
- Cost & Complexity Drive the Decision: Real-time ingestion can be expensive and complex. Architects should weigh the cost of onboarding, storing, and transforming data against the cost of querying it directly via Zero Copy.

Choosing the right integration pattern — Data Ingestion, Zero Copy, or a Hybrid approach — directly impacts latency, governance, operational efficiency, and cost across multi-cloud platforms. This decision shapes how real-time insights, AI-driven activation, and personalized engagement can be delivered reliably and at scale.

## Product Comparison

This table provides a technical comparison of Data Ingestion and Zero Copy patterns in Salesforce Data 360, focusing on capabilities, trade-offs, and benefits, along with enterprise use cases and outcomes. Architects can use this as a reference for designing hybrid, multi-cloud data platforms that balance performance, cost, and compliance.

| Pattern Type | Mode / Tool | Benefits | Considerations | Outcomes |
| --- | --- | --- | --- | --- |
| **Data Ingestion** | **Real-Time:**Sub-second latency ingestion via Ingestion APIs with CDC support. Continuous streaming pipelines. | - Immediate insights
- Ideal for low-latency operational and personalization use cases
- Supports event-driven workflows | - High cost
- Complex architecture
- Requires low-latency source systems
- High-volume sources can cause excessive streaming leading to saturated pipelines
- I/O intensive
- Consider selective fields and filtering to reduce overhead | **Agentforce:**
- Real-time fraud alerts, retail personalization, operational alerts
**Analytics:**
- Sub-second dashboards, KPI monitoring
**Compliance:**
- Continuous customer record updates for regulated workflows |
|  | **Streaming:**Micro-batch ingestion every 1–3 minutes via native connectors | - Balanced cost vs freshness
- Simpler architecture than real-time
- Supports incremental updates | - Slight latency
- May not be suitable for critical sub-second decisions
- Batch size impacts memory/compute
- I/O is moderate
- Best for predictable, repeated update patterns
- Consider windowed aggregation to reduce processing load | **Agentforce:**
- Timely campaign triggers, near-live engagement
**Analytics:**
- Recommendation engines, near-live dashboards
**Compliance:**
- Frequent updates with auditability |
|  | **Batch:**Scheduled large-volume loads via connectors or APIs. Supports object storage and ETL/ELT pipelines. | - Cost-efficient for massive datasets
- Easy to implement
- Reliable for historical analytics | - Data latency
- Unsuitable for time-sensitive operations
- I/O intensive during load windows
- Network throughput may become a bottleneck for large files
- Best for historical aggregation or regulated reporting workflows | **Agentforce:**
- IT support tickets (Jira/ServiceNow), aggregated workflows
**Analytics:**
- Historical analysis, trend evaluation
**Complainance:**
- Regulatory reporting, patient/claims data aggregation |
| **Zero Copy** | **Live Query:**Direct queries on external systems; schema-on-read; no data duplication | - Maximum freshness
- Minimal storage overhead; supports real-time operational insights | - Dependent on source performance
- High query volume may affect latency
- Ideal for queries with predicate pushdown & aggregation to minimize I/O
- Avoid unfiltered queries on massive datasets | **Agentforce:**
- Dynamic workflows adapting to live activity
**Analytics:**
- Operational dashboards, live reporting
**Compliance:**
- Respects row-level security & masking at source |
|  | **Accelerated Query (Caching):**Cached local copies for federated queries. Configurable from 15 min to 7 days. Optimized query execution | - Reduces latency
- Lower cost than repeated live queries
- Improves performance for frequent access patterns | - Cache management required
- Staleness depends on cache interval
- Best for high-frequency queries
- Not suitable for sub-second decisioning | **Agentforce:**
- Pre-aggregated engagement metrics for fast decisioning
**Analytics:**
- BI dashboards, segmentation, analytical reporting
**Compliance:**
- Consistent regulated dashboards with audit logs |
|  | **File Federation:**Direct access to large historical datasets in object stores or lakes (S3, Iceberg, Google BigQuery, Redshift). | - Handles massive-scale datasets
- Minimal storage in Data 360
- Supports AI/ML workloads | - Read-only
- Query performance depends on external system throughput
- Optimized for batch-heavy, throughput-intensive jobs
- Not suitable for real-time dashboard | **Agentforce:**
- (Not typical — batch-heavy)
**Analytics:**
- ML/AI training, historical analytics, petabyte-scale reporting
**Compliance:**
- Governed access to external datasets without duplication |

## Data 360 Integration Patterns

### Data Ingestion

With data ingestion, data is physically copied into Data 360 and fully governed, unlike Zero Copy where data remains at the source. Compute for transformations happens within Data 360, which allows for centralized governance and auditing.

#### Data Ingestion Use Cases

Use data ingestion to store canonical, governed datasets in Salesforce Data 360 for compliance and operational control. Use ingestion when full control, auditing, and traceability are required. Ideal for regulated or high-value workflows where centralized compute and governance are critical.

Ingestion is best for building a trusted foundation for identity resolution, regulatory reporting, and mission-critical AI-driven workflows and customer engagement.

#### Data Ingestion Methods

Data ingestion methods vary depending on what connector you use to ingest your data. Some connectors offer a variety of ingestion methods, while others operate only in batch or streaming mode. See [Data 360: Integrations and Connectors](https://help.salesforce.com/s/articleView?id=data.c360_a_sources_targets.htm&type=5) for a complete list of Data 360 connectors and their available methods.

- **Real-Time**

Sub-second ingestion using streaming pipelines or Change Data Capture (CDC).
Best for time-sensitive workflows (fraud detection, personalization, operational dashboards).
Push transformations and aggregations within Data 360 to reduce downstream I/O and optimize compute usage. Use incremental CDC to minimize data shuffling.
- **Streaming**

Ingestion every 1–3 minutes in small increments.
Balances freshness and cost, suitable for campaign orchestration, near-live engagement, and operational reporting.
Use micro-batches to control I/O spikes. Aggregate data at source if possible to reduce transfer volumes and optimize storage.
- **Batch (Scheduled Loads)**

Periodic ingestion of large datasets (hourly, daily, weekly).
Cost-efficient and reliable for historical datasets, regulatory reporting, and compliance use cases.
Ensure compute locality in the same region as source storage for performance and cost optimization.

#### Architect Playbook

- **Use Cases for Data Ingestion**

Generate Customer 360 Unified Profiles: Building a single source of truth for customer identity and attributes.
Maintain regulatory compliance datasets: Enforcing governance, lineage, and auditability for sensitive data.
Centralize campaign orchestration: Ensuring marketing, sales, and service all operate from consistent, trusted datasets.
- **Design Practices**

Favor batch ingestion for historical or low-latency-tolerant needs, such as archival reporting or periodic snapshots.
Use CDC or streaming APIs to maintain freshness for operational and personalization workflows, ensuring near real-time updates.
Control storage and compute growth by applying incremental loads, rather than reloading entire datasets, to optimize cost and efficiency.
Align ingestion pipelines with compute locality and incremental processing to reduce network I/O. Apply transformations inside Data 360 to avoid moving raw data unnecessarily.
- **Cost Considerations**

Real-Time Ingestion: Highest compute and pipeline costs; justified for high-value, time-sensitive workflows such as personalization, operational dashboards, or Agentforce-driven actions.
Streaming Ingestion: Moderate compute and storage costs; suitable for frequent updates that can tolerate slight delays, like campaign orchestration or operational reporting.
Batch Ingestion: Lower compute costs, predictable storage; best for historical datasets or low-frequency updates. Ingesting batch data from Salesforce orgs using certain connectors is free.
Refresh Mode: Selecting Incremental Refresh mode reduces total ingestion and compute costs. We recommend using incremental refresh wherever possible to optimize efficiency across all ingestion types.
Cost is also impacted by I/O volume from source to Data 360. Optimizing batch sizes, partitions, and regional alignment reduces transfer costs and improves performance.
- **Industry Scenarios**

Finance: Ingest datasets required for knowing your customer (KYC), Anti Money Laundering (AML), and fraud detection, where auditability and compliance are non-negotiable.
Healthcare: Use ingestion for patient identity resolution and HIPAA-compliant records, enabling secure, unified views.
Retail: Consolidate point of sale (POS), eCommerce, and loyalty program data into unified profiles for segmentation and personalization
Telecom: Support churn prevention and usage analytics with canonical, governed subscriber data.

#### Data Ingestion Method Decision Criteria

| Feature | Real-Time Ingestion | Streaming Ingestion | Batch Ingestion |
| --- | --- | --- | --- |
| **Latency and Freshness** | Sub-second latency ingestion via Ingestion APIs with Change Data Capture (CDC) support. Provides continuous streaming pipelines. Best for low-latency operational use cases. | Micro-batch ingestion every 1–3 minutes via native connectors. Supports incremental updates. Slight latency is expected. | Data latency is expected. Scheduled large-volume loads. Periodic ingestion (hourly, daily, weekly). Unsuitable for time-sensitive operations. |
| **Primary Use Cases** | Ideal for low-latency operational and personalization use cases. Used for time-sensitive workflows. Supports event-driven workflows. Used for real-time fraud alerts and operational alerts. | Suitable for moderately urgent processes. Used for campaign orchestration, near-live engagement, and operational reporting. Used for timely campaign triggers. | Cost-efficient for massive datasets. Reliable for historical analytics. Used for historical aggregation or regulated reporting workflows. Best for historical or low-velocity datasets. |
| **Architectural Complexity and I/O** | High cost and complex architecture. Requires low-latency source systems. I/O intensive. High-volume sources can cause saturated pipelines. | Simpler architecture than real-time. I/O is moderate. Best for predictable, repeated update patterns. Batch size impacts memory/compute. | Easy to implement. I/O intensive during load windows. Network throughput may become a bottleneck for large batches. |
| **Cost Considerations** | Highest compute and pipeline costs. Justified only for high-value, time-sensitive workflows. | Moderate compute and storage costs. Provides a balanced cost vs freshness approach. Suitable for frequent updates that can tolerate slight delays. | Lower compute costs and predictable storage. Recommended for historical datasets or low-frequency updates. Ingestion via Salesforce internal pipelines is free. |
| **Design Practices** | Use incremental CDC to minimize data shuffling. Filter and use selective fields to reduce overhead. | Use micro-batches to control I/O spikes. Consider windowed aggregation to reduce processing load. | Favor this for archival reporting or periodic snapshots. Ensure compute locality in the same region as source storage for cost optimization. |

### Zero Copy Data Federation

#### Zero Copy Use Cases

Use Zero Copy for real-time querying of external systems without data duplication, enabling agility, freshness, and scalable access to large or transient datasets. It is best for live dashboards, exploratory analytics, AI/ML model training, and real-time customer engagement directly through Salesforce Data 360.

#### Zero Copy Methods

When using Zero Copy, architects must further decide between three available data federation methods, each of which offers its own tradeoffs between freshness, performance, and cost.

- **Live Query**

Runs queries directly against external systems (Snowflake, Google BigQuery, Redshift, Databricks, etc.) with no data duplication.
Optimal when predicates and aggregations can be pushed down, minimizing data movement over the network and reducing I/O on the Salesforce Data 360 compute.
Best for real-time insights and low-latency operational dashboards. Dependent on the external system's performance.
- **Caching (Accelerated Query)**

Temporarily stores cached copies of federated data in Salesforce Data 360.
Reduces repeated query costs and latency for frequently accessed datasets, with configurable duration (minutes to days).
Data is not permanently copied or fully governed; freshness is managed via scheduled refreshes from the source.
- **File Federation**

Provides direct, read-only access to large-scale datasets in object stores (e.g., S3, GCS with Iceberg).
Best for AI/ML workloads, historical analytics, and petabyte-scale reporting without moving data.
Query performance depends heavily on object format, partitioning, and network I/O. Large scans can generate substantial I/O if not optimized.

#### Architect Playbook

- **Use Cases**

Real-time personalization & adaptive workflows: Deliver dynamic offers, recommendations, and next-best actions as customer behavior changes.
Live dashboards & operational analytics: Power business-critical dashboards and KPIs directly from external warehouses.
AI/ML model training with large external datasets: Leverage petabyte-scale data from data lakes and warehouses using file federation without moving it.
- **Industry Scenarios**

Retail/Media: Enable personalized recommendations and real-time customer engagement by federating clickstream or content interaction data.
Finance: Run fraud detection and risk scoring in near real time by querying external warehouses without duplicating sensitive data.
Tech/Enterprise: Support cross-cloud reporting, IT service dashboards, and operational analytics where datasets reside in multiple systems.
- **Design Practices**

Live Query

Use for high-QPS, low-latency queries when freshness is critical.
Push predicates and aggregations to the external system to reduce data shuffling over the network.
Avoid queries that scan massive data volumes unnecessarily; consider partition pruning and filters.

File Federation

Access petabyte-scale datasets in object stores without ingestion.
Keep object storage in the same cloud region as Salesforce compute to minimize latency and egress costs.
Use partitioned, columnar formats (Parquet/ORC) and pushdown filters to reduce I/O and network transfer.
Leverage query and predicate pushdown to filter and aggregate data at the source, reducing data movement.
Avoid cross-region data access unless necessary, as it increases I/O, latency, and costs.

Caching (Accelerated Query)

Cache frequently accessed datasets to balance cost and performance.
Configure refresh intervals to balance freshness vs. query cost.

Compliance: Enforce governance at the source by leveraging row-level security (RLS) and masking policies directly within federated systems. Below are best practices for uniform RLS and masking across platforms.

Use a Centralized Enterprise ID: Map users and entities in Salesforce Data 360 to a unique, centralized enterprise identifier that corresponds to identities in external systems.
Align Security Policies: Ensure row-level security and masking policies in federated systems are applied based on the mapped identity. This preserves compliance when querying external data.
Standardize Identity Schemas: Maintain consistent identity attributes (email, user ID, customer ID, etc.) across all data sources to avoid mismatches and access violations.
- **Cost Considerations**

Live Query: Pay-per-query model — costs accrue on external lakehouse compute and can spike with high QPS. Best for freshness-critical use cases where value is greater than cost variability.
Accelerated Query (Caching): Lowers query cost compared to Live Query by reducing hits to the source system, but adds to batch data ingestion costs for filling and refreshing the cache. Best for frequently accessed datasets.
File Federation: Cheapest storage option as data in Object Store, but query costs depend on file size, partitioning, and pruning. Best for historical or bulk data at petabyte scale.

#### Zero Copy Method Decision Criteria

| Decision Point | Live Query | Caching (Accelerated Query) | File Federation |
| --- | --- | --- | --- |
| **Data Source Location** | External data lakehouses (Snowflake, Google BigQuery, Redshift, Databricks). | External data lakehouses (Snowflake, Google BigQuery, Redshift, Databricks) | Object stores or cloud data lakes (S3, ADLS, GCS), often using open table formats like Iceberg. |
| **Purpose/Use Case** | Ideal for interactive analysis and real-time dashboards. Best for real-time personalization and dynamic workflows. | Best for when queries are frequent but slightly stale results are acceptable. Suitable for BI dashboards and segmentation. | Best for large-scale batch processing and AI/ML model training. Ideal for historical analytics and petabyte-scale reporting. |
| **Freshness/Latency** | Maximum freshness; queries run directly in real time. Supports sub-second decisioning. | Slightly stale results are acceptable. Freshness depends on the cache interval, configurable from 15 minutes to 7 days. | Optimized for batch-heavy, throughput-intensive jobs. Not suitable for real-time dashboarding. |
| **Access Pattern** | Best for infrequent or ad-hoc queries. Use for high-QPS (query per second), low-latency queries where freshness is critical. | Best for high-frequency read scenarios. Improves performance for frequent access patterns. | Read-only access. Suited for petabyte-scale datasets without ingestion. |
| **Performance Drivers** | Highly dependent on the external source system's performance. Optimized when predicates and aggregations can be pushed down to the source. | Reduces latency compared to repeated live queries. Performance depends on cache management and interval. | Performance depends heavily on object format, partitioning, and external system throughput. Use partitioned, columnar formats (Parquet/ORC). |
| **Cost Implications** | Pay-per-query model. Costs accrue on external lakehouse compute. Cost-effective for infrequent queries but expenses can spike with high query per second (QPS) volume. | Lower cost than repeated live queries. Reduces the need to repeatedly query the external source. Adds cache storage and refresh overhead. | Cheapest storage option. Query costs depend on file size and partitioning. |
| **Key Consideration** | Avoid unfiltered queries that scan massive data volumes unnecessarily. | Requires cache management. Not suitable for sub-second decisioning. | Query performance relies heavily on optimization via partitioning and predicate pushdown. |

### Hybrid Approach

Hybrid architectures enable architects to anchor critical datasets in Data 360 for centralized governance while leveraging federated queries for freshness, reduced duplication, and scalable access to large external datasets. This approach balances I/O, compute locality, cost, and compliance requirements.

#### Hybrid Use Cases

Use a hybrid approach for balanced governance, freshness, and operational efficiency by combining data ingestion and zero copy to deliver real-time, actionable insights. Use ingestion for high-value, regulated datasets where traceability, RLS, and masking are required, and federation for ephemeral or high-volume datasets where freshness and performance are key.

#### Architect Playbook

- **Use Cases**

Omni-channel engagement: Blend historical customer data with real-time behavior to deliver consistent, context-aware experiences.
AI/ML pipelines: Train models on curated, canonical datasets while enriching them with raw or real-time signals from external sources.
Mixed compliance & agility needs: Apply strict governance for sensitive data but federate for operational agility.
- **Industry Scenarios**

Retail: Use ingestion for identity resolution and profile unification; federate for real-time offers and personalization.
Healthcare: Maintain golden patient records via ingestion while federating IoT device streams and sensor data for immediate context.
Financial Services: Ingest regulated data into a compliance-governed lake while federating external queries for fraud detection and risk monitoring.
- **Design Practices**

Anchor Governance with Ingestion: Ingest high-value or regulated data into canonical models to ensure trust and compliance.
Use Federation for Freshness: Let external lakehouses provide real-time or large-scale data access without duplication.
Balance Cost vs. Performance: Profile workloads to decide what to ingest vs. federate, minimizing unnecessary storage or query costs.
Apply Layered Governance: Enforce centralized governance for ingested data, while leveraging federated systems' own security controls (e.g., RLS, masking).
When designing hybrid pipelines, ensure incremental ingestion for historical datasets and push aggregations or filters to federated sources to optimize I/O and compute usage.
- **Cost Considerations**

Optimize total cost versus performance by combining ingestion for compliance or critical data with federation when freshness is necessary.
Account for I/O and compute distribution when mixing ingestion and federation. To reduce compute cost in source systems of repeated queries, use caching (Accelerated Query) for high-read, frequently accessed federated datasets.

## Use Case Decision Guide

Below are common archetypes that illustrate how to apply this logic.

1. **The "Single Source of Truth" Archetype: Centralize and Govern**

Scenario: You need to build compliant, unified Customer 360 profiles for your entire global enterprise. The data comes from a dozen different systems, must adhere to strict GDPR and CCPA regulations, and will serve as the trusted source for all marketing and service interactions.
Recommended Pattern: Data Ingestion. The priority is governance, trust, and control. Ingesting the data into Data 360 is the only way to create a fully auditable, canonical profile that is insulated from the source systems.
2. **The "Real-Time Insights" Archetype: Analyze Without Moving**

Scenario: Your data science team needs to run exploratory queries on a massive, constantly updating transaction table in Snowflake. At the same time, your executive team wants a live BI dashboard powered by that same data. Moving petabytes of data daily is too slow and expensive.
Recommended Pattern: Zero Copy Federation. The priority is speed, agility, and cost-efficiency at scale. Zero Copy allows you to leverage the immense power of your existing data warehouse for real-time queries without the overhead and latency of data duplication.
3. **The "Hybrid Intelligence" Archetype: Govern the Core, Federate the Edge**

Scenario: You want to enrich your governed, ingested customer profiles with real-time behavioral signals (like website clicks) from a data lake. You need the stability of the core profile but the immediacy of the live data to power in-the-moment personalization.
Recommended Pattern: A Hybrid Approach. Use Data Ingestion to create the stable, governed core of your customer data. Then use Zero Copy to federate the volatile, real-time "edge" data, joining it at query time for a complete, up-to-the-second view.

## The Path Forward

Enterprise data strategy is no longer about choosing a single integration pattern — it's about architecting controlled flexibility within an interoperable data ecosystem. Selecting the right data integration method for each source data system based on business needs often leads to a hybrid approach that blends the strengths of both data ingestion and data federation.:

- Ingest mission-critical, governed datasets into Salesforce Data 360 for compliance, identity resolution, and operational workflows.
- Federate data via Zero Copy for live, exploratory, and AI-driven analytics without duplicating storage.

Salesforce Data 360 on Hyperforce delivers multi-region resilience and scalability. ts open lakehouse with Iceberg tables enables compute separation and interoperability with platforms like Snowflake, Databricks, and S3 Iceberg — forming the backbone of a truly interoperable, multi-cloud data ecosystem.

As data ecosystems evolve, continuously balance freshness, cost, performance, and compliance to maintain architectural agility. Future-proof your platform by unifying ingested, governed data with federated access. This enables real-time intelligence, AI activation, and enterprise-scale personalization across clouds, regions, and business domains.

One-size-fits-all solutions don't suit most businesses. The optimal strategy maps the right pattern to the right business driver.

## About the Authors

Yugandhar Bora is a Software Engineering Architect at Salesforce, specializing in data architecture within the Data & Intelligence Applications platform. He leads enterprise architecture review board (EARB) initiatives focused on data governance and unified data models, while contributing to automated platform provisioning solutions.

Jan Fernando is a Principal Architect in the Office of the Chief Architect at Salesforce. He joined Salesforce in 2012, bringing a wealth of experience from his time in the startup ecosystem. Prior to joining the Office of the Chief Architect, he spent over a decade in the Platform organization, where he led several key technology transformations.
