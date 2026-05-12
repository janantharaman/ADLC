---
source_url: https://architect.salesforce.com/docs/architect/decision-guides/guide/get-started-data-360-decision-guides.html
date_fetched: 2026-05-01
section: decision-guides
page_title: Data 360 Decision Guides
---

This section provides practical guidance for making critical architectural decisions about Salesforce Data 360, including provisioning strategies, multi-org connectivity, and integration patterns. Use these guides to design and implement effective data architectures that unify customer data and enable AI-powered features.

## Data 360 Provisioning

[Data 360 Provisioning](/docs/architect/decision-guides/guide/data-360-provisioning) covers foundational decisions when provisioning Salesforce Data 360:

- **Home Org Selection**: Decide whether to provision Data 360 in an existing production org or create a dedicated org, considering governance, compliance, and time-to-value.
- **Multi-Org Strategy**: Choose between multiple independent Data 360 instances or using Data Cloud One to unify multiple Salesforce orgs, balancing autonomy, compliance, and cost.
- **Data Cloud One Architecture**: Enable multiple Companion Orgs to share a single Data 360 instance with centralized governance, metadata sharing, and feature parity across orgs.
- **Data Sharing Between Data 360 Orgs**: Use zero-copy data sharing between independent instances for regional compliance, business unit collaboration, or federated executive dashboards.
- **Provisioning Considerations**: Factor in data residency, governance models, latency, integration complexity, cost, and AI readiness for enterprise-wide deployments.

Helps architects design provisioning strategies that ensure simplicity, enterprise consistency, compliance, and scalability for Customer 360, AI, and cross-platform innovation.

## Data 360 Interoperability

[Data 360 Interoperability](/docs/architect/decision-guides/guide/data-360-interoperability) provides a framework for integrating Data 360 with external platforms and data lakes:

- **Data Ingestion Patterns**: Real-time, streaming, and batch ingestion for creating governed canonical datasets ideal for Customer 360, compliance, and centralized governance.
- **Zero-Copy Data Federation**: Live query, accelerated query (caching), and file federation methods to access external systems in real time without duplication, enabling personalization, dashboards, and AI/ML workloads.
- **Hybrid Approach**: Combine governed ingestion for core datasets with zero-copy federation for freshness and scalability, supporting omni-channel engagement, Agentforce-driven actions, and enterprise analytics.
- **Decision Framework**: Evaluate trade-offs in latency, cost, scalability, governance, and complexity to select the right integration pattern per data source.
- **Architect Playbooks**: Industry-specific guidance, design practices, and cost considerations for finance, healthcare, retail, and telecom scenarios.

Guides architects in balancing data freshness, governance, and pipeline efficiency to build scalable, interoperable, AI-ready data architectures that support both operational and analytical workloads.
