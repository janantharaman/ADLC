---
source_url: https://architect.salesforce.com/docs/architect/reference-diagrams/guide/section-interaction-process-flow.html
date_fetched: 2026-05-01
section: reference-diagrams
page_title: Interaction Process Flow
---

Interaction process flow diagrams illustrate the sequence of interactions, data flows, and process steps between system components, services, and users. These diagrams help architects and developers understand how different parts of a system communicate, how events propagate through the architecture, and how asynchronous and synchronous processes are orchestrated. They provide essential documentation for understanding system behavior, identifying bottlenecks, and optimizing process flows.

This section contains 6 reference diagrams related to interaction process flow:

| Diagram Name | Description |
| --- | --- |
| [Asynchronous Processing Via Platform Events](/docs/architect/reference-diagrams/guide/asynchronous-processing-via-platform-events) | Shows how asynchronous processing works with platform events. The events published into the bus are consumed by subscribers for processing. |
| [Claim Check](/docs/architect/reference-diagrams/guide/claim-check) | Shows an event being published when a record is modified. The message body of the event is stored in a database, and only a reference is passed through the message bus. |
| [Customer Personalization Flow](/docs/architect/reference-diagrams/guide/customer-personalization-flow) | Shows time-based interactions involved in the end-to-end flow of information from customer interactions through personalization engines to delivery systems. |
| [External Integrations Via Http](/docs/architect/reference-diagrams/guide/external-integrations-via-http) | An example solution architecture diagram from the Building Forms Decision Guide that shows external integrations using HTTP protocols. |
| [Hospitality Loyalty Management Process](/docs/architect/reference-diagrams/guide/hospitality-loyalty-management-process) | Shows time-based interactions of systems in a hospitality loyalty management process. |
| [Queuing](/docs/architect/reference-diagrams/guide/queuing) | Shows an example of the Queuing pattern that depicts an event being published and written to a queue, with subscribers processing events in order. |
