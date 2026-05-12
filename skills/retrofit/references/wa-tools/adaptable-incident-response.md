---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/adaptable-incident-response.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Resilient — Incident Response
---

### Ability to Triage Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response) → [Ability to Triage](/docs/architect/well-architected/guide/resilient#ability-to-triage)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ SMEs or stakeholders who should be alerted to support complex issues are identified before an incident occurs |
| Platform | Business | ✅ The hand-off between delivery and support teams is a part of go-live |
| Platform | Business | ✅ If consulted, Salesforce architects respond quickly and help the team stay focused on recovery |
| Platform | Documentation | ✅ System and design patterns used in a given solution are discoverable and readable by support staff |
| Platform | Org | ✅ Logging and custom error messages are incorporated into execution paths throughout the system |

### Monitoring and Alerting Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response) → [Monitoring and Alerting](/docs/architect/well-architected/guide/resilient#monitoring-and-alerting)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Documentation | ✅ Entry criteria for prompt tuning alerts are defined based on direct and indirect generative AI feedback metrics |
| Platform | Org | ✅ Alerts are only used to inform users of scenarios that require human intervention; other failures are logged and reportable |
| Platform | Org | ✅ Alerts are sent to users who are capable of responding to them |
| Platform | Org | ✅ When possible, alerts are delivered in advance of a potential failure |

### Time to Recover Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response) → [Time to Recover](/docs/architect/well-architected/guide/resilient#time-to-recover)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ Teams know what services in production they are responsible for owning |
| Platform | Business | ✅ Recovery protocols are practiced on regular intervals |
| Platform | Documentation | ✅ Recovery tactics are defined and classified by incident type and trigger |
| Platform | Documentation | ✅ Exit criteria for incident responses exist in your SLOs and are clear |
| Platform | Documentation | ✅ Activation criteria and assignment logic for elevated permissions during incidents are clear |
| Platform | Documentation | ✅ Incident response permission sets and authorizations are clearly listed |
| Platform | Org | ✅ Session-based permission sets for incident response exist and can be assigned to support staff during recovery |
| Platform | Org | ✅ Setup Audit Trail shows designated recovery testers have logged into testing environment on agreed upon time and have followed recovery test scripts |
| Platform | Test Plans | ✅ Test scripts for recovery testing exist and are repeatable |
| Platform | Test Plans | ✅ Environments for incident simulations are clearly listed |

### Ability to Triage Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response) → [Ability to Triage](/docs/architect/well-architected/guide/resilient#ability-to-triage)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ SMEs or stakeholders who should be alerted aren't identified until an incident occurs |
| Platform | Business | ⚠️ The hand-off between delivery teams and support teams isn't a part of the release process |
| Platform | Business | ⚠️ Salesforce architects consider incident response to be outside their scope of work |
| Platform | Documentation | ⚠️ System and design patterns used in a given solution are not readily available to support staff |
| Platform | Org | ⚠️ Logging and custom error messages are not used |

### Monitoring and Alerting Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response) → [Monitoring and Alerting](/docs/architect/well-architected/guide/resilient#monitoring-and-alerting)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Documentation | ⚠️ There are no criteria defined for triggering prompt tuning alerts for generative AI apps |
| Platform | Org | ⚠️ Alerts are sent when any type of failure occurs, regardless of whether follow-on actions are required |
| Platform | Org | ⚠️ Alerts about issues requiring technical solutions are delivered to business users |
| Platform | Org | ⚠️ Alerts are only delivered in response to failures that have already occurred |

### Time to Recover Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response) → [Time to Recover](/docs/architect/well-architected/guide/resilient#time-to-recover)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ It is unclear what teams are responsible for different services in production |
| Platform | Business | ⚠️ Recovery protocols don't exist or aren't practiced on regular intervals |
| Platform | Documentation | ⚠️ Incident response is performed ad hoc |
| Platform | Documentation | ⚠️ Exit criteria for incident responses do not exist |
| Platform | Documentation | ⚠️ Elevated permissions are not assigned, or assigned ad hoc |
| Platform | Documentation | ⚠️ Incident response permission sets and authorizations are not listed |
| Platform | Org | ⚠️ Session-based permission sets do not exist for incident response, or are not authorized for support staff to use |
| Platform | Org | ⚠️ Setup Audit Trail shows designated recovery testers have not logged into the testing environment or did not follow recovery test scripts |
| Platform | Test Plans | ⚠️ Environments are not established for incident simulations |
| Platform | Test Plans | ⚠️ Test scripts do not exist for recovery testing |
