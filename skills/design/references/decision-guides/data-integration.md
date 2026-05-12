---
source_url: https://architect.salesforce.com/docs/architect/decision-guides/guide/data-integration.html
date_fetched: 2026-05-01
section: decision-guides
page_title: Data Integration with Salesforce
---

## Guide Overview

There are a multitude of ways to access, synchronize, and share data between Salesforce and external systems. But not every tool is right for your particular project. This guide walks through the landscape of data integration tools available from Salesforce. It also offers recommendations for the tools (or combinations of tools) that are most appropriate given a particular use case, as well as guidance on tools to avoid for specific scenarios.

This decision guide focuses on data-level integrations involving Salesforce. Specifically, it covers the following data integration use cases:

- Salesforce to external systems
- External systems to Salesforce
- Salesforce organization to Salesforce organization

These are only a subset of the integration challenges that Salesforce Architects face, so we plan on adding more decision guides focused on event-driven integration, building effective customer- or employee-facing workflows using process integration, and so on. Finally, it’s important to note that many of the tools and approaches described here can be used to solve integration challenges across the wider enterprise, but such uses are beyond the scope of this guide.

### Takeaways

- **Avoid unnecessary data replication.** Unless the data absolutely needs to reside in Salesforce, consider data virtualization with Salesforce Connect instead. More data in your organization ultimately leads to larger data volumes, which can adversely affect [performance](/docs/architect/well-architected/guide/reliable#performance) and add technical debt. If your data already resides in Salesforce and you need it in an external system, avoid copying it to an external system unless absolutely necessary. Instead, have the external system access the data via the Salesforce APIs.
- **Use MuleSoft or other Enterprise Service Bus (ESB) or Extract-Transform-Load (ETL) solutions, if available and part of your existing landscape.** Because these tools are built to help support data migration and transformation, they often have powerful capabilities that enable you to reuse integrations across the enterprise, maintain stronger governance, and centralize management of integrations. In this guide, wherever MuleSoft Anypoint is recommended, consider whether your existing ESB/ETL solution will suffice.
- **Harmonize data from different sources with Data 360 and Data Cloud One.** Through the Customer 360 Data Model, identity resolution, data federation, and other features, Data 360 consolidates data from Salesforce and other external systems into a unified view of your customer. And with [Data Cloud One](/docs/architect/fundamentals/guide/data360_integration_patterns_and_practices.html#unified-multi-org-data-platform-with-data-cloud-one), users in other Salesforce orgs can safely access data shared virtually from Data 360 through data spaces.
- Move data between orgs using **Data 360 actions and activations.** After data is ingested from different orgs into Data 360, data [actions and activations](/docs/architect/fundamentals/guide/data360_integration_patterns_and_practices.html#data-activation-patterns--data-outbound) can sync the data to another org. This approach can be very useful for integrations with Marketing Cloud orgs.
- Extract and move data using **MuleSoft Anypoint.** MuleSoft Anypoint can be used to extract data from Data 360 using Connect API and Data Graph API and move it to another Salesforce org. Without Data 360, MuleSoft Anypoint can also be used when data needs to be moved between orgs without being replicated in Data 360.
- **Use caution if you choose to build with Outbound Messaging.** Salesforce will continue supporting Outbound Messaging within current functional capacities, but does not plan on making further investments in this technology.
- **Integration user license with "API Only" profile is always recommended for all integrations.** Salesforce also recommends using External Client Applications (in favor of connected apps or SOAP login) as the properly permissioned AuthN and AuthZ patterns for all integrations.

## Common Considerations for Choosing Data Integration Tools

Before diving into the data integration tools available, it’s important to keep a few common considerations in mind when choosing a tool. As is typical with architecture, there is no prescriptive answer to every business challenge. If you’ve uttered the words “it depends” when making integration choices, then you’re in the right place.

| Area to Consider | Common Questions |
| --- | --- |
| Existing Tools and Landscape | Is there an existing ESB or ETL solution in place? Does the data involved have regulatory or compliance requirements? Where are the systems you're trying to integrate located (in the cloud or on-premise)? |
| Data Flow (Timing, Expected User Experience, Directionality) | Does the data need to move synchronously, asynchronously or can it be batched/scheduled? Is data replication required? What system should be the source of truth? What is the data source? What is the target destination? Is user interaction required? Does the user need to see the result of the integration? What are the needs around exception handling (retry, notify, fail)? How tightly-coupled should systems be? |
| Implementation | What is the level of effort for non-Salesforce systems? What teams are responsible for delivering integrations? What tools do they prefer to use? |
| [Maintainability](/docs/architect/well-architected/guide/intentional#maintainability) | What teams will be expected to maintain the integration? What skills do they currently have? What skills will they need in the future? What is the total cost of ownership over time? How important is the ability to test, debug, troubleshoot with low or pro code tools? |
| [Data Volume](/docs/architect/well-architected/guide/reliable#data-volume) | How much data is involved in the integration? Will you be working with [Large Data Volumes](https://trailhead.salesforce.com/content/learn/modules/large-data-volumes) (LDV)? How frequently will changes happen in bulk? What sort of impact will singleton updates have? How often will they occur? |
| Limits | Will the data need to undergo complex transformation? Does the data need to be combined from several source systems? How often will an integration take place on a per user basis? How many users total? Have you planned ahead for bulk data loads (example: initial data load for a new instance)? |

## Product Comparison

Here is a high-level overview of the tools available for data integration and some considerations to start evaluating each option. The following sections include in-depth use cases and details about the capabilities of these tools.

|  | From Salesforce to External System | From External System to Salesforce | Execution | Additional License Required |
| --- | --- | --- | --- | --- |
| **Apex Actions** | Available | Available | Server-Side | No |
| **Change Data Capture** | Available | Not Available | Server-Side | No* |
| **Custom Apex (REST and SOAP Web Services)** | Available | Available | Server-Side | No |
| **External Services** | Available | Not Available | Server-Side | No |
| **Heroku Connect** | Available | Available | Server-Side | Yes |
| **Data 360** | Available | Available | Server-Side | Yes |
| **MuleSoft Anypoint** | Available | Available | Server-Side | Yes |
| **Native Salesforce APIs** | Not Available | Available | Server-Side | No |
| **Omniscript** | Available | Available | Client-Side*** | Yes |
| **OmniStudio Integration Procedure** | Available | Available | Server-Side | Yes |
| **Outbound Messaging** | Not Ideal | Not Available | Server-Side | No |
| **Platform Events** | Available | Available | Server-Side | No** |
| **Salesforce Connect/External Objects** | Available | Available | Server-Side | Yes |

[*Add-on required for high-volume change data capture event use cases](https://developer.salesforce.com/docs/atlas.en-us.change_data_capture.meta/change_data_capture/cdc_allocations.htm)

[**Add-on required for high-volume platform event use cases](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm)

***Suitable in situations where it's ok for business logic to run within the web browser.

Column legend:

- **Available**: works well for most use cases
- **Not Ideal**: possible but consider an alternative tool
- **Not Available**: no plans to support in the next twelve months

### Other tools that may be involved in moving data into and out of Salesforce:

There are other tools that may support some aspects of a data-layer integration, but must not be considered a primary means of solving integration problems. Let’s take a quick look at these tools now.

**Lightning Web Components** are typically used for process integrations, but they can make callouts using JavaScript functionality, so data could be involved in these transactions.

**Salesforce Flow** can be used to orchestrate external callouts with External Services or Apex Actions. Salesforce Flow by itself is not considered a standalone data integration tool.

**Data Import Wizard and Data Loader** can be used to synchronize, import, and migrate data. While Data Loader commands can also be scripted to automate the import and export of data, the [command-line interface](https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/command_line_intro.htm) is for Windows only and neither of these tools is a recommended base for a data integration strategy. Instead, use them to complement your data stewardship and maintenance strategy.

[Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_force_data.htm) data commands can be used to manipulate records in your org. Commands are available to help you import and export data with the Bulk API and SObject Tree Save API, and perform simple CRUD operations on individual records with the REST API. The Salesforce CLI by itself is not considered a standalone data integration tool.

**OmniStudio Data Mapper** can be used as a declarative ETL tool to move data between Salesforce objects and JSON data structures. While a REST interface is automatically created for each Data Mapper interface, providing a declarative way to move data from external systems to Salesforce objects, Data Mapper standalone is not a recommended base for a data integration strategy. Data Mapper actions are available in OmniStudio Integration Procedures.

[Dataloader.io](http://dataloader.io/) is another data loader tool for Salesforce powered by MuleSoft's Anypoint Platform allowing you to quickly and securely import, export and delete unlimited amounts of data for your enterprise. Dataloader.io is not a recommended base for a data integration strategy.

## Salesforce to External Systems (Outbound Integration)

For outbound integrations from Salesforce, you may consider different types of tools: low-code, pro-code, or a hybrid. The following sections provide guidance for each of these tool types and offer sample solutions.

- [Low-Code Tools for Outbound Integrations](#low-code-tools-for-outbound-integrations-from-salesforce)
- [Hybrid Tools for Outbound Integrations](#hybrid-tools-for-outbound-integrations-from-salesforce)
- [Pro-Code Tools for Outbound Integrations](#pro-code-tools-for-outbound-integrations-from-salesforce)

### Low-Code Tools for Outbound Integrations from Salesforce

|  | Guidance | Licensing | Timing | Volume & Scale |  | Delivery & Maintenance |  |  | Privacy & Security |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | **When to Use** | **Additional License** | **Sync (Request/Reply) or Async (Fire/Forget)** | **Multi-Object Support** | **LDV/Bulk** | **Testing & Deployment**** | **Debugging** | **Built-In Error Handling/Retry Behavior** | **Can Use with Data Encrypted at Rest** | **Authentication Protocol** |
| **Change Data Capture** | When you need to publish record-level changes made in Salesforce to an external system and don't need a custom payload. | Required | Async | No | No | Yes | With pro-code tools | Yes | Yes | OAuth |
| **External Services** | When you're orchestrating a process using Flow, Apex, Einstein Bots or OmniStudio and the external system APIs are described using OpenAPI specifications. | Not Required | Sync | Yes | No | Yes | With pro-code tools | No | N/A | Named Credentials |
| **Heroku Connect** | When you want to extend your data with bidirectional sync to enable mobile and other apps on Heroku, and you want the data to also be replicated to Salesforce. | Required | Async | Yes | Yes | No | With pro code tools | Yes | Yes, via Shield Connect | OAuth |
| **OmniStudio Integration Procedure** | When you need to transform data without user interaction and improve performance by processing on the server instead of the browser. | Required | Both | Yes | Yes | Yes | Declarative support | Yes | Yes | Named Credentials |
| **Salesforce Connect/External Objects** | When you want data to appear in the Salesforce UI, but want the data to be stored in an external system. Data is not replicated to Salesforce. | Required | Sync | No | Yes* | Yes | With pro-code tools & a declarative tracer | No | N/A | Named Credentials |
| *OData adapters older than version 4.01 are subject to callout limits. See [OData Callout Rate Limit Considerations](https://help.salesforce.com/s/articleView?id=platform.odata_general_limits.htm&type=5) for more details. ** Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production. |  |  |  |  |  |  |  |  |  |  |

### Use Case: Outbound Integration Using Low-Code Tools

> When opportunities are won, an order for the associated products needs to be created in the company’s ERP system or order management system.

**Change Data Capture** As Opportunity records are updated, Change Data Capture publishes change events that contain the updates to the objects. The change events are consumed on the customer’s side over a CometD connection (or via a MuleSoft connector) and used to update the customer’s ERP or order management system. Change events can be enriched to always include external record IDs or other data from the object (such as region) that are needed for the integration. Change event streams for multiple objects can be combined into *channels* for simplified subscription and stream processing (so you can subscribe to and process one stream instead of many).

**External Services** If you have a web service that supports the OpenAPI 2.0 or 3.0 specification, you can expose the operations and services as an External Service within Salesforce. The API operations (for example create order) can be called as an Invocable Action in a flow built with Flow Builder when the stage of the opportunity is changed to "Won".

**Heroku Connect** Heroku Connect is typically used to keep a Heroku Postgres Database and Salesforce in sync. If the customer uses Heroku Postgres as their source-of-truth transactional store, then you can sync the records and the changes from Salesforce to Heroku Postgres using Heroku Connect. From there, you can use Heroku Streaming Connectors to publish those changes to Apache Kafka and send them as events to downstream applications, including the ERP or order management system.

**OmniStudio Integration Procedure** When an order is submitted, the Omniscript orchestrating the process can post the order details to an ERP or MuleSoft connector. The post can be executed either directly by the Omniscript (client-side) or indirectly via an Integration Procedure (server-side). If the ERP system throws a validation error, the Omniscript UI must notify the user, and if necessary, translate and contextualize the error for the user.

**Salesforce Connect/External Objects** You can create a record-triggered flow in Salesforce that inserts a record into the related external object(s) when the stage of the opportunity is changed to "Won". Since this is a [mixed transaction](https://help.salesforce.com/articleView?id=000328873&type=1&mode=1), to avoid errors add a pause element for zero seconds between the Opportunity update and the related external object insert(s) so that you close one transaction context before you start a new one.

### Hybrid Tools for Outbound Integrations from Salesforce

|  | Guidance | Licensing | Timing | Volume & Scale |  | Delivery & Maintenance |  |  | Privacy & Security |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | **When to Use** | **Additional License** | **Sync (Request/Reply) or Async (Fire/Forget)** | **Multi-Object Support** | **LDV/Bulk** | **Testing & Deployment**** | **Debugging** | **Built-In Error Handling/Retry Behavior** | **Can Use with Data Encrypted at Rest** | **Authentication Protocol** |
| **Apex Actions** | When you want to automate callouts to another system via Salesforce Flow. A developer can write an Apex class that a flow can invoke, or you can download a prebuilt solution from AppExchange. | Not Required | Both | Yes | No | Yes | With pro-code tools | No | Yes | Multiple |
| **Event Relays** | When you need to send platform events and change data capture events to Amazon EventBridge from Salesforce. Event Relays only connect to AWS Eventbridge | No | Async | Yes | No | Yes | Yes | Yes | Yes | HTTP/1.1 with TLS |
| **Outbound Messaging** | When you need to send SOAP messages over HTTP(S) to a designated endpoint with guaranteed receipt when triggered by a workflow rule. | Not Required | Async | No | No | Yes | Declarative support | Yes | Yes | Two-way TLS |
| **Platform Events** | When you need a custom-defined, structured payload for near real-time changes in Salesforce or an external system. | Not Required* | Async | Yes | No | Yes | With pro-code tools | Yes | Yes | OAuth |
| **Salesforce Connect/External Objects (with custom Apex adapters)** | When you want data to appear in the Salesforce UI, but want the data to be stored in an external system that cannot use standard protocols like OData or GraphQL. | Required | Both | Yes | Yes | Yes | With pro-code tools | No | N/A | Multiple |
| **Data 360** | When you want harmonized data from different sources in one data store, or you want to replicate your data to other Salesforce orgs or to other external systems. | Required | Both | Yes | Yes | Yes | Yes | Yes | Yes | Multiple |

[*Add-on](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm) required for high-volume use cases.

**Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production.

### Use Case: Outbound Integration Using Hybrid Tools

> When opportunities are won, an order for the associated products needs to be created in the company’s ERP or order management system.

**Apex Actions** A record-triggered flow based on the opportunity state can be triggered automatically when an opportunity is won. The flow executes an invocable action that uses an external callout to submit the order to the order management system or ERP solution. High-volume submissions and multisite orders are handled by Apex batch and queue mechanisms.

**Outbound Messaging** After [setting up outbound messaging](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_om_outboundmessaging_setting_up.htm), you can define a workflow rule triggered by the opportunity update to send a SOAP message over HTTP(S) to a specified endpoint URL hosting the listener. The message will contain the fields specified when the outbound message was created. If the information in the object changes after the notification is queued, but before it is sent, only the updated information will be delivered and messages will stay in the queue until sent successfully, or until they are 24 hours old. After 24 hours, messages are dropped from the queue. If the ERP system requires additional data, you can pass the sessionId in outbound messages so the external system can make a callback request.

**Platform Events** You can define a platform event that includes the custom payload with the data required to create the records in the external system. Because Platform Events are not auto-published upon record change, you must publish the event via Apex, Salesforce Flow, or Process Builder when the stage of the opportunity is changed to "Won". An external service listens to the platform event channel using CometD (or a MuleSoft connector) and creates the appropriate records in the external system.

**Salesforce Connect/External Objects (with custom Apex adapters)** A solution based on Salesforce Connect/External Objects is not perfectly suited for a use case that purely requires data synchronization. However, this solution can apply in cases where users within Salesforce need to see, and potentially interact with data from the external system, and the data cannot be replicated in Salesforce. If the ERP or order management system does not support OData or GraphQL protocols, then the development team can use the [Apex Connector Framework](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_connector_start.htm) to write Apex classes that handle communication with the external system via a supported protocol.

**Data 360** A solution based on Data 360 is perfectly suited for use cases where we need harmonized data from different sources in one data store. It can be also used when we need to replicate data from one Salesforce org to multiple Salesforce orgs or to other external systems using Data 360 as a data hub. When an opportunity is won and updated in the source org, opportunity data will be synced to Data 360, where it can be replicated in other systems including Salesforce orgs using different mechanisms like actions, activations, and APIs. Similarly, an opportunity can be referred without replicating the data in other Salesforce orgs using Data Cloud One. However, Data Cloud One does not support non-Salesforce platforms.

### Pro-Code Tools for Outbound Integrations from Salesforce

|  | Guidance | Licensing | Timing | Volume & Scale |  | Delivery & Maintenance |  |  | Privacy & Security |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | **When to Use** | **Additional License** | **Sync (Request/Reply) or Async (Fire/Forget)** | **Multi-Object Support** | **LDV/Bulk** | **Testing & Deployment**** | **Debugging** | **Built-In Error Handling/Retry Behavior** | **Can Use with Data Encrypted at Rest** | **Authentication Protocol** |
| **Custom Apex** | When you need more functionality than is available in low-code tools. | Not Required | Both | Yes | Yes | Yes | With pro-code tools | No | Yes* | Multiple |
| **External Services** | Integrating from code with external system APIs are described using OpenAPI specifications. | Not Required | Sync | Yes | No | Yes | With pro-code tools | No | N/A | Multiple |
| **MuleSoft Anypoint** | When you need a single enterprise-grade, unified solution to build, orchestrate, and manage your integrations; when you need to replace a legacy point-to-point architecture; or when you need API management support. | Required | Both | Yes | Yes | Yes | With pro-code tools | No | Yes* | Multiple |

*Enabling Shield Platform Encryption changes certain behaviors, see [General Shield Platform Encryption Considerations](https://help.salesforce.com/articleView?id=sf.security_pe_considerations_general.htm&type=5) for more details.

**Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production.

### Use Case: Outbound Integration Using Pro-Code Tools

> When opportunities are won, an order for the associated products needs to be created in the company’s ERP or order management system.

**Custom Apex** You can create an Apex trigger and trigger handler(s) on the Opportunity that makes a callout to the ERP or order management system when the stage of the opportunity is changed to "Won". Note that if you make callouts from a trigger or after performing a DML operation, you must use a method annotated as future or queueable. A callout in a trigger holds the database connection open for the lifetime of the callout. All Apex code is bound by [Apex Governor and API Limits](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_overview.htm), which are revised on an ongoing basis.

**External Services** If the company’s external ERP or order management system are defined via an OpenAPI specification the callouts to those services that are performed in the future method or queueable job could be simplified. The registered external services can be called directly from Apex without needing to write boilerplate code. In the example, the callout to create the order can be handled by the external service.

**MuleSoft Anypoint** MuleSoft Anypoint provides enterprise-grade API management. MuleSoft Anypoint can create APIs to enable read (and/or write) access to data for Salesforce and many other enterprise systems. There are [many prebuilt connectors available](https://www.mulesoft.com/platform/cloud-connectors) to simplify implementation, and companies can create and publish their own connectors as well. These APIs can be deployed in Anypoint with flexible security policies, supporting centralized management and governance. There are no restrictions on volume of transactions, as long as the API has been properly sized for its peak utilization (as measured in vCores).

## External Systems Data to Salesforce (Inbound Integration)

For inbound integrations to Salesforce, you may consider different types of tools: low-code, pro-code, or a hybrid. The following sections provide guidance for each of these tool types and offer sample solutions.

- [Low-Code Tools for Inbound Integrations](#low-code-tools-for-inbound-integrations-to-salesforce)
- [Hybrid Tools for Inbound Integrations](#hybrid-tools-for-inbound-integrations-to-salesforce)
- [Pro-Code Tools for Inbound Integrations](#pro-code-tools-for-inbound-integrations-to-salesforce)

### Low-Code Tools for Inbound Integrations to Salesforce

|  | Guidance | Licensing | Timing | Volume & Scale |  | Delivery & Maintenance |  |  | Privacy & Security |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | When to Use | Additional License | Sync (Request/Reply) or Async (Fire/Forget) | Multi-Object Support | LDV/Bulk | Testing & Deployment* | Debugging | Built-In Error Handling/Retry Behavior | Can Use with Data Encrypted at Rest | Authentication Protocol |
| **Heroku Connect** | When you want to extend your data with bidirectional sync to enable mobile and other apps on Heroku, and you want the data to also be replicated to Salesforce. | Required | Async | Yes | Yes | No | With pro-code tools | Yes | Yes, via Shield Connect | OAuth |
| **OmniStudio Integration Procedure** | When you need to import and transform data from third-party sources without user interaction. | Required | Both | Yes | Yes | Yes | Declarative support | No | Yes | Named Credentials |
| **Salesforce Connect/External Objects** | When you want data to appear in the Salesforce UI, but want the data to be stored in an external system that can use standard protocols like OData or GraphQL. | Required | Sync | Yes | Yes | Yes | With pro-code tools | No | N/A | Multiple |

*Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production.

### Use Case: Inbound Integration Using Low-Code Tools

> A contact is updated in the organization’s ERP system. This contact information needs to be updated in Salesforce.

**Heroku Connect** Heroku Connect is typically used to keep a Heroku Postgres Database and Salesforce in sync. Unless the ERP system uses Heroku Postgres as its transaction store, this use case is not possible. If it does use Heroku Postgres, then changes made in the Postgres tables can be synced to objects in Salesforce using Heroku Connect.

**OmniStudio Integration Procedure** After the ERP system updates the contact record, an OmniStudio Integration Procedure with a Data Mapper Load Action and a Response Action can be called via the REST API generated by Data Mapper. First, a Data Mapper Load action sends a JSON or XML payload, which is used to upsert the contact records based on an External ID field or through an [Upsert Key](https://trailhead.salesforce.com/content/learn/modules/omnistudio-data-tools-and-internal-data/build-an-integration-procedure-with-conditional-dataraptor-loads?trail_id=build-guided-experiences-with-omnistudio). If a simple response in JSON is all that is expected, a Response Action can send back any relevant information from the previous actions to indicate success or failure. If the ERP system expects a specific response then a Data Mapper Transform or Extract Action can be used to generate a JSON or XML response with additional features to declaratively include data that was generated in triggers by the contact record update. The main challenge with this scenario is concurrency: Multiple calls to update the same contact record concurrently will cause issues as the API exists directly in Salesforce.

**Salesforce Connect / External Objects** Salesforce Connect and external objects are not recommended for this use case, because the scenario specifically requires data replication in Salesforce. If you have a pre-existing Salesforce Connect integration built to the ERP, you can configure the OData 4.0 connector to support external change data capture if the ERP can support change data capture. Further, you must configure in Salesforce to subscribe to the change stream from the ERP, using Pub/Sub API.

### Hybrid Tools for Inbound Integrations to Salesforce

|  | Guidance | Licensing | Timing | Volume & Scale |  | Delivery & Maintenance |  |  | Privacy & Security |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | When to Use | Additional License | Sync (Request/Reply) or Async (Fire/Forget) | Multi-Object Support | LDV/Bulk | Testing & Deployment** | Debugging | Built-In Error Handling/Retry Behavior | Can Use with Data Encrypted at Rest | Authentication Protocol |
| **Platform Events** | When you need a custom-defined, structured payload for near real-time changes in Salesforce or an external system. | Not Required* | Async | Yes | No | Yes | With pro-code tools | Yes | Yes | OAuth |
| **Salesforce Connect/External Objects (with custom Apex adapters)** | When you need data to appear in the Salesforce UI, but want the data to be stored in an external system that cannot use OData 2.0/4.0 protocols. | Required | Both | Yes | Yes | Yes | With pro-code tools | No | N/A | Multiple |
| **Data 360** | When you want harmonized data from different sources in one data store, or you want to replicate your data from other Salesforce orgs or to other external systems. Data 360 also supports virtualization for some platforms. | Required | Both | Yes | Yes | Yes | No | Yes | Yes | Multiple |

*[Add-on](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm) required for high-volume use cases.

**Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production.

### Use Case: Inbound Integration Using Hybrid Tools

> A contact is updated in the organization’s ERP system. This contact information needs to be updated in Salesforce.

**Platform Events** Custom code in an external system publishes a Platform Event when the contact record is updated in the ERP. A trigger, Process or Flow in Salesforce can subscribe to the platform event, and update the corresponding Salesforce object(s) when an event is processed. The Platform Event may function simply as a signal that a change happened in the customer’s ERP system without containing any data, or it may contain the actual data needed to update the Salesforce object.

**Salesforce Connect/External Objects (with custom Apex adapters)** This solution isn't applicable in a use case that requires data replication. This solution is applicable if you need users in Salesforce to see information from an external system that must not or cannot be replicated in Salesforce, and the external system cannot support standard protocols like OData or GraphQL. See [Use Case: Outbound Integration Using Hybrid Tools](#use-case-outbound-integration-using-hybrid-tools) for an example use case for an Apex custom adapter.

**Data 360** When a contact is updated in external systems like ERP, the contact updates can be synced to Data 360 either using available out of the box connectors or using APIs and pro-code tools like MuleSoft. Contact can also be referenced in Data 360 using zero copy mechanism (available with some platforms).  Once data is available in Data 360, different out of the box integration mechanisms can be used for syncing the data to other Salesforce orgs. Data can be accessed by reference using Data Cloud One. Data can be replicated too using activations and other APIs using out of the box connectors or with the help of pro-code tools like MuleSoft Anypoint platform.

### Pro-Code Tools for Inbound Integrations to Salesforce

|  | Guidance | Licensing | Timing | Volume & Scale |  | Delivery & Maintenance |  |  | Privacy & Security |  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | When to Use | Additional License | Sync (Request/Reply) or Async (Fire/Forget) | Multi-Object Support | LDV/Bulk | Testing & Deployment**** | Debugging | Built-In Error Handling/Retry Behavior | Can Use with Data Encrypted at Rest | Authentication Protocol |
| **Custom Apex REST & SOAP Web Services** | When you need more functionality than provided by the native API endpoints such as cross object processing or other complex logic. | Not Required | Both | Yes | Yes | Yes | With pro-code tools | No | Yes*** | Multiple |
| **MuleSoft Anypoint** | When you need a single enterprise-grade, unified solution to build, orchestrate, and manage your integrations; when you need to replace a legacy point-to-point architecture; or when you need API management support. | Required | Both | Yes | Yes | Yes | With pro-code tools | No | Yes*** | Multiple |
| **Native Salesforce APIs** | When you need more control or have a pro-code skill set to build integrations via REST API, SOAP API, Bulk API, or GraphQL APIs, or gRPC. | Not Required* | Both | Yes***** | Yes | Yes | With pro-code tools | Yes** | Yes*** | Multiple |

*[API Request Limits and Allocations](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_platform_api.htm) apply.

**Bulk APIs have aspects of retry behavior and a number of APIs offer *rollback* protection via allOrNone setting (for example, see [allOrNone Parameters in Composite and Collections Requests](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_composite_allornone.htm))

***Enabling Shield Platform Encryption changes certain behaviors, see [General Shield Platform Encryption Considerations](https://help.salesforce.com/articleView?id=sf.security_pe_considerations_general.htm&type=5) for more details.

****Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production.

*****Composite APIs have multi-object support.

### Use Case: Inbound Integration Using Pro-Code Tools

> A contact is updated in the organization’s ERP system. This contact information needs to be updated in Salesforce.

**Custom Apex REST and SOAP Web Services** You can create a web service using Apex code that could perform CRUD (create, read, update, delete) operations on the Contact object. This service will be invoked via SOAP or REST from the external system (the ERP).

**MuleSoft Anypoint** The intent of MuleSoft Anypoint is to provide enterprise grade API management. MuleSoft Anypoint offers a [large set of prebuilt connectors](https://www.mulesoft.com/platform/cloud-connectors) that you can use to integrate with many ERP systems including SAP, Oracle EBS, Oracle ERP, and NetSuite. You can create a flow to listen for events in these ERP systems (in this case, when a new contact is created). When the flow is kicked off it uses the Salesforce connector to create a new Contact record (or update one if the contact already exists). Additionally, it is possible to integrate with other systems, if the replication transaction involves syndicating the contact into other systems. If needed, you can use the mapping and transformation language (DataWeave) to perform complex logic and calculations as information flows across multiple disparate systems. Authentication against these systems can be done through many different authentication mechanisms such as Basic Authentication and OAuth, among others. There are no restrictions on volume of transactions as long as the flow has been properly sized for its peak utilization (measured in vCores).

**Native Salesforce APIs** As (or immediately after) the update transaction in the ERP system completes, you can perform an upsert operation on the Contact object via the SOAP API or perform a [PATCH](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_update_fields.htm) against the Contact sObjects REST API in the Salesforce organization.

## Salesforce to Salesforce Integrations

The Salesforce to Salesforce product has reached its end of life. Salesforce to Salesforce made it easy for partners working together to sell to and support joint customers, but Salesforce will be investing in bringing more innovation to other tools. Moving forward, the following approaches are recommended for sharing data between Salesforce organizations.

### Tools for Data Integration Across Salesforce Organizations

|  | Guidance | Cost | Timing | Volume & Scale |  |  | Delivery & Maintenance |  | Privacy & Security |  | Tools to Implement |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | **When to Use** | **Additional License** | **Sync (Request/Reply) or Async (Fire/Forget)** | **Multi-Object Support** | **LDV/Bulk** | **Testing & Deployment*** | **Debugging** | **Built-In Error Handling/Retry Behavior** | **Can Use with Data Encrypted at Rest** | **Authentication Protocol** | **Low Code → Pro Code** |
| **Heroku Connect** | When you want to extend your data with bidirectional sync across Salesforce orgs and also enable access to the data from mobile and other apps running on Heroku | Required | Async | Yes | Yes | No | With pro-code tools | Yes | Yes, via Shield Connect | OAuth | Low Code |
| **MuleSoft Anypoint** | When you need a single enterprise-grade, unified solution to build, orchestrate, and manage your integrations; when you need to replace a legacy point-to-point architecture; or when you need API management support | Required | Both | Yes | Yes | Yes | With pro-code tools | No | Yes** | Multiple | Pro Code |
| **Native Salesforce APIs** | When Salesforce or Heroku Connect are not an option or you need more complex processing | Not Required | Both | No | Yes | Yes | With pro-code tools | No | Yes** | Multiple | Pro Code |
| **Change Data Capture** | When you need to publish record-level changes made in Salesforce to an external system and don't need a custom payload. | Required | Async | No | No | Yes | With pro-code tools | Yes | Yes | OAuth |  |
| **Salesforce Connect with Cross-Org Adapter** | When you want users in one org to view or edit records in a different org without data replication | Required | Async | Yes | Yes | Yes | With pro-code tools | N/A | N/A | Multiple | Low Code |
| **Data 360** | When you want users in one org to view or edit records in a different org with data replicated in Data 360. | Required | Both | Yes | Yes | Yes | With pro-code tools | Yes | Yes | Multiple | Hybrid |

*Testing and Deployment refers to the ability to build in a lower environment and deploy via the [Metadata API](https://developer.salesforce.com/docs/metadata-coverage/), packages, or change sets to production

**Enabling Shield Platform Encryption changes certain behaviors, see [General Shield Platform Encryption Considerations](https://help.salesforce.com/articleView?id=sf.security_pe_considerations_general.htm&type=5) for more details.

*Platform events are not optimal for integrating data from one Salesforce organization to another, because they can’t “listen” between organizations for the same event. Custom Apex is also not a recommended approach for this type of integration.*

### Use Case: Connecting Multiple Salesforce Orgs

> A large enterprise operates across multiple business units (BUs). Each BU has its own Salesforce organization. A single customer deals with multiple business units of the enterprise and thus has account and opportunity data in multiple organizations. The enterprise needs to access an aggregated view of all the Account and Opportunity data across all BUs in a single org.

*Note: All solutions below design for the least amount of data replication, in accordance with Takeaway #1.*

**Data 360** Account and opportunity data from different Salesforce orgs can be ingested into Data 360 using out of the box Salesforce connectors. They can be aggregated and harmonized as well (if required). Once data is aggregated in Data 360, it can be accessed in other Salesforce orgs using Data Cloud One without data replication.

**Heroku Connect** For each BU's individual organization, you can use Heroku Connect to sync changes from Salesforce into a single Heroku Postgres database. In this scenario, bi-directional syncing isn't enabled, only syncing from Salesforce to Postgres. Then, in Heroku Connect, you can enable the OData provider and select the tables you want to expose as external objects in the Salesforce org where you want an aggregated view. From within Salesforce, you define an external data source pointing to the OData provider in Heroku.

**MuleSoft Anypoint** MuleSoft Anypoint provides enterprise-grade API management. A MuleSoft Anypoint API can be configured so that it reads information from multiple related Salesforce organizations using the Salesforce connector with multiple connections to the organizations. The MuleSoft flow can query the different Salesforce organizations and return a specific structure that is enhanced or enriched with other third-party information if needed. When the API is invoked, it will make all the proper Salesforce organization callouts (in this example querying Account and Opportunity information) so that the data can be processed by the consumer (likely a UI). Authentication against these systems can be done through a variety of authentication mechanisms including basic authentication and OAuth. There are no restrictions on the volume of transactions, so long as the flow has been properly sized for its peak utilization (measured in vCores or Cores).

**Native Salesforce APIs** Query operations can be issued to each of the organizations of interest, notably via the Salesforce Bulk API 2.0, which is well-suited to efficiently extract thousands of records. You can retrieve the query results from each organization individually and aggregate them with a custom application or middleware per customer requirements.

**Salesforce Connect with Cross-Org Adapter** The Salesforce Connect Cross-Org adapter is not a strong fit in this scenario, since Accounts or Opportunities from remote orgs will all appear in the central org as *different* objects. For example, there is no way to add up a grand total for the Amounts of all the Opportunities across all the orgs.

**Selective Updates Cross-Org Scenario:** A salesperson, using Salesforce organization A, needs to view and update Case data from Salesforce organization B and add case comments to the parent case on Salesforce organization B while working in organization A. Data must not be replicated to organization A.

**Heroku Connect** You can use the same approach described in the *Data Aggregation Scenario* above. However, you must enable CRUD on the external object via the OData connector and write the changes back to Heroku Postgres.

**MuleSoft Anypoint** MuleSoft Anypoint provides enterprise-grade API management. You can use the same approach described in the *Data Aggregation Scenario* above.

**Native Salesforce APIs** Use Named Credentials and invoke the native Salesforce APIs to read and update data in the related Salesforce organization. A component must be designed to display the data.

**Salesforce Connect with Cross-Org Adapter** The ability to view data in an external object (as well as edit the data if you have CRUD enabled on the external object) is supported through the [Salesforce cross-org adapter](https://help.salesforce.com/articleView?id=sf.xorg_adapter_about.htm&type=5). Relationships are also supported between external objects so you can link to the parent case in the external object. However, creating relationships is a manual process today in which you convert an existing datatype to a relationship datatype. Additionally, optimizations made within Service Cloud to work with Cases more effectively do not cascade through to the remote org. Salesforce strongly recommends testing the Cross-Org Adapter and evaluating the tradeoffs in working with External Objects vs Standard Objects for your use case.

**Data Synchronization Cross-Org**: When an account for a customer is updated in one of the organization’s business unit Salesforce organizations, the other Salesforce organization Account objects need to be updated to keep consistent account information.

**Data 360** Data 360 can be used for data replication from one org to another Salesforce org. Account data from one Salesforce org can be ingested to Data 360 using out of the box Salesforce connectors. We can use data activation mechanisms like batch activation, near real time data actions or API based activations as well to move the data from Data 360 to Salesforce Org.

**Heroku Connect** You can use the same approach described in the *Data Aggregation Scenario* above. However, you must enable bidirectional syncing, and you no longer need to enable Salesforce Connect as the bi-directional syncing will keep all the organizations up-to-date when changes are made to the Postgres table.

**MuleSoft Anypoint** MuleSoft Anypoint provides enterprise-grade API management. You can [configure a Mule application](https://docs.mulesoft.com/design-center/about-designing-a-mule-application) with Flow Designer in MuleSoft Anypoint to listen for standard and custom object events to kick off an autolaunched flow in Salesforce. When the Mule application is triggered, it can invoke the Anypoint Connector for Salesforce to communicate with any number of Salesforce organizations. In this use case, when an Account record is updated in one Salesforce organization, the Mule app can update Account records in the related Salesforce organizations. Each related Salesforce organization would have a unique update step built into the overall application flow in MuleSoft. Authentication against these systems can be done through various authentication mechanisms, including basic authentication and OAuth. There are no restrictions on the volume of transactions as long as the flow has been properly sized for its peak utilization (measured in vCores or Cores).

**Native Salesforce APIs** The [Replication API](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_guidelines_datareplication.htm) (getUpdated, getDeleted operations) could be used to sync data across orgs, but this approach is not recommended.

**Salesforce Connect with Cross-Org Adapter** You can use record-triggered flows and external objects to keep some data in sync between Salesforce organizations. For example, updating an account record in Organization A triggers a flow that then updates the matching record on the Account external object, which writes those updates to the account record in Organization B. This requires the proper use of flow semantics to avoid [mixed DML transactions](https://help.salesforce.com/articleView?id=000328873&type=1&mode=1). Also, bear in mind that Validation Rules and Flows in Organization B will be triggered in the same way as when changes are made by our REST/SOAP APIs.

## Closing Remarks

Keep this guide in mind and refer to it when you’re planning a new data integration involving Salesforce. It’s always a good idea to understand the full scope of options available to you, and how they may fit with your specific use case.

### Tell us what you think

Help us make sure we're publishing what’s most relevant to you. [Take our survey](https://sfdc.co/J0cWb) to provide feedback on this content and tell us what you’d like to see next.
