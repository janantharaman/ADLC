---
source_url: https://architect.salesforce.com/docs/architect/decision-guides/guide/get-started-platform-decision-guides.html
date_fetched: 2026-05-01
section: decision-guides
page_title: Platform Decision Guides
---

This section provides practical guidance for making critical architectural decisions about Salesforce Platform capabilities. It covers asynchronous processing, record-triggered events, form building, event-driven architecture, and step-based async frameworks to help architects design scalable, maintainable, and high-performance platform solutions.

## Asynchronous Processing

[Asynchronous Processing](/docs/architect/decision-guides/guide/async-processing) provides guidance on tools and approaches for asynchronous operations in Salesforce:

- **Asynchronous Processing Tools**: Comparison of Queueable Apex, Scheduled Apex, Platform Event Triggers, Change Data Capture, Scheduled Path (After Commit Flows), and Asynchronous Path (Record-Triggered Flows), with guidance on appropriate use cases.
- **Server-Side Asynchronous Processing**: Patterns for long-running database operations, external callouts, and large-volume record processing.
- **Client-Side Asynchronous Processing**: Techniques like Apex Continuation Callouts and client-side asynchronous processing that may execute in browsers or mobile apps.
- **Decision Framework**: Consider use case validation, scalability, understanding when transactions are truly asynchronous, monitoring, and handling extreme load events.
- **Best Practices and Anti-Patterns**: Guidance for proper use, including outbound integrations, monitoring, and avoiding common pitfalls.

Enables architects to implement scalable, reliable, and maintainable asynchronous patterns, avoiding pitfalls that compromise performance.

## Building Forms

[Building Forms](/docs/architect/decision-guides/guide/build-forms) guides architects on Salesforce form-building options:

- **Form-Building Tools**: Comparison of Dynamic Forms, Screen Flow, OmniStudio, Screen Flow with Lightning Web Components (LWC), and LWC, including skills and licensing considerations.
- **Decision Framework**: Consider object impact, form scope, navigation, location (app, mobile, web), UX, and test automation.
- **Tool Selection Guidance**: Recommendations from simple record layouts to multi-page wizards and branded customer-facing forms.
- **Combination Patterns**: Guidance for combining tools, e.g., Screen Flow navigation with LWC styling.
- **Advanced Features**: Deep dives into capabilities and limitations to inform tool choice.

Helps architects select the right form-building approach for their specific UX, functional, and integration requirements.

## Event-Driven Architecture

[Event-Driven Architecture](/docs/architect/decision-guides/guide/event-driven) provides a comprehensive guide to Salesforce eventing tools and patterns:

- **Eventing Tools**: Overview of Platform Events, Change Data Capture, Pub/Sub API, MuleSoft Anypoint, Streaming API, and integration considerations.
- **Event-Driven Patterns**: Includes publish/subscribe, fanout, passed messages, streaming, and queueing patterns for various event-driven use cases.
- **Integration with MuleSoft**: Using Anypoint connectors (Pub/Sub, JMS, Kafka, Solace, MQ, MQTT, AMQP) for enterprise architectures.
- **Platform Events and Change Data Capture**: Guidance on preferred mechanisms for publishing record and field changes, with migration from PushTopic/Generic Events.
- **Implementation Patterns**: Best practices for scalability, consistency, error handling, and monitoring.

Enables architects to design scalable, near real-time event-driven systems that connect multiple systems efficiently.

## Step-Based Async Framework

[Step-Based Async Framework](/docs/architect/decision-guides/guide/step-based-async-framework) provides a framework for modular, scalable asynchronous job processing:

- **Framework Architecture**: Components include Queueable Apex, Finalizers, Scheduled Flow, Apex Cursors, Invocable Actions, and Slack integrations.
- **Step-Based Processing**: Breaks work into independent steps that can run, retry, and restart with shared governance and operational visibility.
- **Implementation Guidance**: Patterns for Step interface, Step Processor, Apex Invocable layer, delay handling, and notifications.
- **Best Practices**: Recommended when most information exists in CRM, for high-volume workloads, and hierarchical or tree-based record processing; guidance on when not to use.
- **Enterprise-Grade Features**: Governance, compliance, distributed state, progress tracking, SLA monitoring, failure diagnostics, and audit-level logging.

Provides architects a scalable alternative to monolithic batch jobs and chained async calls, supporting high-volume Salesforce workloads with full operational transparency.

## Record-Triggered Automation

[Record-Triggered Automation](/docs/architect/decision-guides/guide/record-triggered) provides the framework for designing record-triggered automation on the Salesforce Platform:

- **Tool Selection**: When to use Record-Triggered Flow versus Apex triggers, guided by automation density (low, medium, high) and the density selection matrix.
- **Automation Density**: How to assess automation quantity, record volume, and dependency sprawl to choose Flow, hybrid (Flow with Invocable Apex), or Apex triggers.
- **Entry Points and Governance**: One entry point per Salesforce Object; guidance on entry conditions, recursion control, and ordered execution.
- **Asynchronous Invocation**: When and how to invoke asynchronous processes from record-triggered flows or Apex, with caution around error handling and governor limits.
- **Best Practices**: Patterns for bulkification, hybrid Flow–Apex design, and avoiding common pitfalls in trigger automation.

Enables architects to design scalable, maintainable, and performant record-triggered automation aligned with platform standards.
