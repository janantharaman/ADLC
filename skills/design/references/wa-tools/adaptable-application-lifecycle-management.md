---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/adaptable-application-lifecycle-management.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Resilient — Application Lifecycle Management
---

### Environment Strategy Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management) → [Environment Strategy](/docs/architect/well-architected/guide/resilient#environment-strategy)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Org | ✅ Metadata in a given environment is independent from your release artifacts |
| Platform | Org | ✅ Environments do not directly correspond to a release path |
| Platform | Org | ✅ Release paths for a change depend on the type of the change (high risk, medium risk, low risk) |
| Platform | Org | ✅ Overcrowded environments do not exist |
| Platform | Org | ✅ Risky configuration changes are never made directly in production |
| Platform | Org | ✅ No releases occur during peak business hours |
| Platform | Org | ✅ A source-driven development and release model is adopted |
| Platform | Sandboxes | ✅ Source tracking is enabled for Developer and Developer Pro sandboxes |

### Release Management Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management) → [Release Management](/docs/architect/well-architected/guide/resilient#release-management)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Design Standards | ✅ Release names are clear |
| Platform | Design Standards | ✅ Teams can find and follow clear guidelines for tagging artifacts, development items, and other work with the correct release names |
| Platform | Documentation | ✅ Release names are searchable and discoverable |
| Platform | Documentation | ✅ It is possible to pull together a clear view of a release manifest by release name |
| Platform | KPIs | ✅ Quality threshholds for generative AI apps are defined for different development stages |
| Platform | Production | ✅ Metadata shows use of stable release mechanisms Deployments via Metadata API use `source` format |
| Platform | Production | ✅ Metadata shows use of stable release mechanisms Metadata is organized into unlocked packages |
| Platform | Production | ✅ Deployment logs show no failed deployments within the available history |
| Platform | Production | ✅ Deployment history shows clear release cadences and fairly uniform deployment clusters within release windows |
| Platform | Production | ✅ DevOps Center is active and installed |
| Platform | Production | ✅ Metadata shows use of stable release mechanisms Change sets are not used to release changes |
| Platform | Roadmap | ✅ Features are tied clearly to a specific, named release |
| Platform | Roadmap | ✅ Release names are clear |
| Platform | Roadmap | ✅ Release names are searchable and discoverable |

### Testing Strategy Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management) → [Testing Strategy](/docs/architect/well-architected/guide/resilient#testing-strategy)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Apex | ✅ Apex test classes include coverage for queries run against Data Cloud objects Test classes extend the System.SoqlStubProvider class and override the handleSoqlQuery() method. DMO instances are created using either Test.createStubQueryRow() or Test.createStubQueryRows(). |
| Platform | Apex | ✅ Data factory patterns are used for unit tests |
| Platform | Apex | ✅ Mock/stubs are used to simulate API responses |
| Platform | Business | ✅ You include scale testing as part of your QA process when you have B2C-scale apps, large volumes of users, or large volumes of data |
| Platform | Business | ✅ Your scale tests have well-defined criteria |
| Platform | Business | ✅ You conduct scale testing in a Full sandbox |
| Platform | Business | ✅ Your scale tests are focused high priority aspects of the system |
| Platform | Business | ✅ Simulators are used to replicate production-like conditions for scalability and performance testing |
| Platform | Business | ✅ Tests are automated to run when changes come into source control |
| Platform | Business | ✅ Endurance, stress, performance, and scale tests are run at several intervals in the application development cycle and considered on-going tasks |
| Platform | Business | ✅ Prompt engineering includes a quality review by a human |
| Platform | Business | ✅ Usability tests employ a variety of devices and assistive technology |
| Platform | Org | ✅ All test data is scrubbed of sensitive and identifying data |
| Platform | Test Plans | ✅ Environments are classified by what type of tests they can support |
| Platform | Test Plans | ✅ Appropriate test regimes are specified according to risk, use case, or complexity |

### Environment Strategy Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management) → [Environment Strategy](/docs/architect/well-architected/guide/resilient#environment-strategy)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Org | ⚠️ Environments directly correspond to a release path |
| Platform | Org | ⚠️ The release path for every change is the same |
| Platform | Org | ⚠️ Overcrowded environments exist |
| Platform | Org | ⚠️ Risky configuration changes are made directly in production |
| Platform | Org | ⚠️ An org-based development and release model is adopted |
| Platform | Org | ⚠️ Releases occur during peak business hours |
| Platform | Org | ⚠️ Metadata in a given environment is your release artifact |
| Platform | Sandboxes | ⚠️ Source tracking is not enabled for Developer and Developer Pro sandboxes |

### Release Management Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management) → [Release Management](/docs/architect/well-architected/guide/resilient#release-management)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Release names are absent |
| Platform | Design Standards | ⚠️ Teams refer to artifacts, development items, and other work in different ways |
| Platform | Documentation | ⚠️ Release names are ad hoc or do not exist |
| Platform | Documentation | ⚠️ It is not possible to pull together a clear view of a release manifest using a release name |
| Platform | KPIs | ⚠️ Quality thresholds for generative AI apps are not defined, or are not defined at different development stages |
| Platform | Production | ⚠️ Metadata indicates use of org-based release mechanisms Deployments via Metadata API use `package.xml` format |
| Platform | Production | ⚠️ Metadata indicates use of org-based release mechanisms Active use of change sets |
| Platform | Production | ⚠️ Deployment logs show repeated instances of failed deployments within the available history |
| Platform | Production | ⚠️ Deployments have no discernable cadence or show uneven clusters of deployments (signs of hot-fix and ad hoc rollbacks) |
| Platform | Production | ⚠️ DevOps Center is not enabled and installed |
| Platform | Roadmap | ⚠️ Features are not tied clearly to a specific release |
| Platform | Roadmap | ⚠️ Release names are absent |
| Platform | Roadmap | ⚠️ Release names are ad hoc or do not exist |

### Testing Strategy Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management) → [Testing Strategy](/docs/architect/well-architected/guide/resilient#testing-strategy)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Apex | ⚠️ Test coverage does not exist for SOQL queries run against Data Cloud objects SOQL queries against a DMO are not covered by apex test methods |
| Platform | Apex | ⚠️ Your unit tests are reliant on org data |
| Platform | Apex | ⚠️ Mocks/stubs are not used |
| Platform | Business | ⚠️ Your scale tests aren't prioritized |
| Platform | Business | ⚠️ You don't conduct scale tests as a part of your QA process and you have B2C-scale apps, large volumes of users, or large volumes of data |
| Platform | Business | ⚠️ Your scale tests don't have well-defined criteria |
| Platform | Business | ⚠️ You conduct scale tests in a Partial Copy or Developer sandbox |
| Platform | Business | ⚠️ Usability tests are not conducted, or are conducted on a limited set of devices |
| Platform | Business | ⚠️ Production-like volumes of user requests, API traffic, and variations in network speed are not tested. |
| Platform | Business | ⚠️ Test automation is not in place |
| Platform | Business | ⚠️ Prompt engineering lacks a quality review by a human |
| Platform | Business | ⚠️ Endurance, stress, performance, scale tests are considered a phase or stage of development. |
| Platform | Org | ⚠️ Test data is identical to production data |
| Platform | Test Plans | ⚠️ It is not clear which environment can support what type of tests |
| Platform | Test Plans | ⚠️ Test regimes are not categorized by risk, use case, or complexity |
| Platform | Test Plans | ⚠️ Performance testing for custom LWC is an afterthought Waiting until the end of the development cycle to test custom Lightning components |
| Platform | Test Plans | ⚠️ Testing integrations with less than 50% of expected user traffic Relying on the result of a handful of users to consider an integration test sufficient |
