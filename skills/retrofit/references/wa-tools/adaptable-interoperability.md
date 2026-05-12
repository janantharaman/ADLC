---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/adaptable-interoperability.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Composable — Interoperability
---

### API Management Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Interoperability](/docs/architect/well-architected/guide/composable#interoperability) → [API Management](/docs/architect/well-architected/guide/composable#api-management)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ Client applications use the latest API version to call Salesforce Client applications calling Salesforce Platform APIs regularly update the API version they are using |
| Platform | Design Standards | ✅ Clear protocols for cross-component communication (i.e. APIs) exist |
| Platform | Design Standards | ✅ Protocols/APIs are outlined in logical groups that builders can search for and find |
| Platform | Design Standards | ✅ Protocols/APIs define variable data types, variable names, what is required or optional and provide a clear description of when to use |
| Platform | Documentation | ✅ It is possible to search for a particular API or protocol and identify components where it is implemented |
| Platform | Documentation | ✅ Every component's documentation clearly lists which API/communication protocol has been implemented |
| Platform | Org | ✅ API message formats and variables for internal communication are defined with custom metadata types |
| Platform | Org | ✅ API message formats and variables for internal communication are defined with platform events |
| Platform | Org | ✅ Code and declarative customizations reference the appropriate custom metadata type (or platform event) in order to send or receive information |

### Messaging and Eventing Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Interoperability](/docs/architect/well-architected/guide/composable#interoperability) → [Messaging and Eventing](/docs/architect/well-architected/guide/composable#messaging-and-eventing)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Org | ✅ Use Data Actions with Platform Events to reuse existing integration patterns Leverage Platform Events to make Data Actions available to external systems leverage existing Pub Sub API and Event Relay integrations |
| Platform | Apex | ✅ Custom event definitions are limited in scope (no system-wide events or messages are defined in code) |
| Platform | Apex | ✅ System-wide messaging or eventing services in Apex are annotated in ways that make them available in Salesforce Flow tools |
| Platform | Design Standards | ✅ Clear standards exist for when to use synchronous patterns (messaging) and asynchronous patterns (eventing) |
| Platform | Design Standards | ✅ Clear standards exist for event and message structures |
| Platform | Flow | ✅ Salesforce Flow tools reference system-wide messaging or eventing services |
| Platform | Lightning Web Components (LWC) | ✅ Custom event definitions are limited in scope (no system-wide events or messages are defined in code) |
| Platform | Org | ✅ Consistent messaging and eventing patterns appear in flows and code |
| Platform | Platform Events | ✅ Platform events used for internal system messaging are clearly labelled |

### API Management Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Interoperability](/docs/architect/well-architected/guide/composable#interoperability) → [API Management](/docs/architect/well-architected/guide/composable#api-management)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ Client applications use outdated API versions to call Salesforce Client applications calling Salesforce Platform APIs need to regularly update the API version they are using to the latest version |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not define APIs and use cases |
| Platform | Documentation | ⚠️ Component documentation does not exist |
| Platform | Documentation | ⚠️ Component documentation describes the API implemented within a component, but that is the only place the API definition appears |
| Platform | Documentation | ⚠️ It is not possible to search for a particular API or protocol and/or searches do not help identify components where an API or protocol has been implemented |
| Platform | Org | ⚠️ APIs are defined exclusively for communication between Salesforce and external systems |
| Platform | Org | ⚠️ Communication between components of the system (code and declarative customizations) is ad hoc |

### Messaging and Eventing Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Interoperability](/docs/architect/well-architected/guide/composable#interoperability) → [Messaging and Eventing](/docs/architect/well-architected/guide/composable#messaging-and-eventing)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ System-wide message and/or event structures are defined in code |
| Platform | Apex | ⚠️ System-wide event or message structures defined in Apex are not available in tools like flow |
| Platform | Design Standards | ⚠️ Design standards do not exist, or they lack clear standards for sync vs. async patterns and clear standards for message or event structures |
| Platform | Lightning Web Components (LWC) | ⚠️ System-wide message and/or event structures are defined in code |
| Platform | Org | ⚠️ Different strategies for messaging and eventing patterns appear across flow and code |
| Platform | Platform Events | ⚠️ Platform events used for internal system messaging are not clearly labelled or do not exist |
