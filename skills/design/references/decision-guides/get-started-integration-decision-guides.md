---
source_url: https://architect.salesforce.com/docs/architect/decision-guides/guide/get-started-integration-decision-guides.html
date_fetched: 2026-05-01
section: decision-guides
page_title: Integration Decision Guides
---

This section provides practical guidance for choosing the right data integration tools and approaches for Salesforce. It covers outbound integrations, inbound integrations, and cross-org scenarios, helping architects design and implement data-layer integrations that balance performance, maintainability, and cost.

## Data Integration with Salesforce

[Data Integration with Salesforce](/docs/architect/decision-guides/guide/data-integration) provides a comprehensive overview of Salesforce data integration tools and best practices:

- **Integration Tool Landscape**: Overview of Salesforce data integration tools, including low-code, hybrid, and pro-code options, with guidance on selecting the right tool for specific use cases.
- **Outbound Integrations**: Methods for sending data from Salesforce to external systems, including Change Data Capture, External Services, Heroku Connect, OmniStudio Integration Procedures, Salesforce Connect, MuleSoft Anypoint, and custom Apex solutions.
- **Inbound Integrations**: Approaches for bringing external data into Salesforce, with guidance on data replication versus virtualization and when to use each tool.
- **Cross-Org Integrations**: Recommended methods for sharing data between Salesforce orgs, including MuleSoft Anypoint, Heroku Connect, Native Salesforce APIs, Change Data Capture, and Salesforce Connect with Cross-Org Adapter, including guidance for replacing legacy Salesforce-to-Salesforce implementations.
- **Decision Framework**: Key considerations for selecting integration tools, such as existing tools and landscape, data flow requirements (timing, directionality, expected user experience), implementation complexity, maintainability, data volume, and platform limits.

Enables architects to choose the right integration tools and patterns for each scenario, minimizing unnecessary data replication, leveraging existing ESB/ETL solutions, and ensuring scalable, maintainable integrations that align with enterprise architecture principles.
