---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/resilient.html
date_fetched: 2026-05-01
section: well-architected
page_title: Resilient
---

> Read about our update scheduleshere.

## Introduction

Resilient solutions maintain a high quality of service even when failures occur. If performance degrades or service is interrupted, the solution quickly and effectively recovers.

The resilience of a solution is grounded in two key qualities:

- **Toughness**: When problems occur, the solution withstands and endures them.
- **Elasticity**: After problems are resolved, the solution returns to its ideal state or shape.

To architect your solution for resilience, you must design for both toughness and elasticity, ensuring both durability and rapid recovery in the face of planned and unplanned changes.

In technology contexts, consider a system or solution as a collection of interdependent components that coordinate to perform shared goals. Every component has the potential to fail. Problems within those components, from code and configuration defects to network and hardware issues, can cause unexpected, undesired behavior. A system demonstrates resilient behavior when one or more components fail, but the overall system continues to function or quickly returns to a stable state.

To improve the resilience of your Salesforce solutions, we recommend focusing on three key habits.

- [Application lifecycle management (ALM)](/docs/architect/well-architected/guide/resilient#application-lifecycle-management)—How teams manage software throughout its lifecycle, from ideation through retirement
- [Incident response](/docs/architect/well-architected/guide/resilient#incident-response)—How teams identify, address, and prevent issues that affect the availability or security of a system
- [Continuity planning](/docs/architect/well-architected/guide/resilient#continuity-planning)—How teams plan for their people and systems to continue to function when unplanned events cause problems

## Application Lifecycle Management

Application lifecycle management (ALM) is a practice for holistically managing software throughout its lifecycle, from creation through retirement. ALM is a cornerstone of system resiliency and encompasses people, processes, tools, and disciplines related to the application lifecycle. Those disciplines include DevOps and delivery methodologies, observability, testing strategies, governance, and CI/CD.

When a business practices effective ALM, its teams react quickly to change, and its applications keep pace with evolving business requirements without compromising stability or quality.

On the other hand, without healthy ALM, teams struggle at every stage of the application lifecycle.

Symptoms of poor ALM include:

- Slow and error-prone development cycles
- Intensive and difficult deployments
- High-severity issues or bugs discovered in production and post-QA environments
- AI agents that hallucinate or behave inconsistently
- Frequent rollbacks or hot-fix deployments required to stabilize releases

Because ALM touches nearly every aspect of a solution, establishing clear and effective ALM practices for your solution is a key part of your architectural work.

Build better ALM practices by focusing on three key areas.

- [Release management](/docs/architect/well-architected/guide/resilient#release-management)—The planning, sequencing, controlling, and migrating of changes into different environments
- [Environment strategy](/docs/architect/well-architected/guide/resilient#environment-strategy)—A strategy for how to use and manage applications in target environments during development and testing
- [Signaling strategy](/docs/architect/well-architected/guide/resilient#signaling-strategy)—Definition of critical signals and application instrumentation used to detect and remediate failures within the system before degradation occurs
- [Testing strategy](/docs/architect/well-architected/guide/resilient#testing-strategy)—The principles and standards guiding how you plan and run tests to gauge the success of your applications during ALM processes

### Release Management

Release management involves planning, sequencing, controlling, and migrating changes into one or more environments. A single release is a group of planned changes that a team moves into a target environment at the same time.

Releasing a change to a system introduces risk to it. If the system is in a stable state before the change, it transitions to a new state, where it’s also more vulnerable to risks from future changes. If any future changes trigger an uncontrolled, unstable state in the system, they can cause a critical incident. In a solution architecture, designing for resilient releases is more than just [testing individual changes effectively](/docs/architect/well-architected/guide/resilient#testing-strategy). It also involves planning how to introduce changes to your systems and their users safely.

The work that your teams do depends on predictable and accurate release information. In your change management and enablement processes, be clear about which changes can move into your system. In your release management and enablement processes, specify how—and how often—changes are released to your system.

Your business stakeholders also care about release information, especially if it’s related to features or bug fixes that they request. To build trust in your solution and demonstrate value to your stakeholders, establish release schedules that are consistent and clear and ship release artifacts that are stable.

To establish effective release management for Salesforce:

- **Tightly align with architectural and development governance**. Ensure that releases are planned well in advance to align with all relevant governance forums and controls. Before starting on development, get all prioritized Agentforce use cases reviewed and approved by the AI Council. Get high-risk Agentforce use cases reviewed by Legal and Ethical Use teams.Use deployment checklists and documentation to track deployment artifacts, such as Agentforce agent API names, against governance activities.
- **Don’t use org-based development or release processes**. This paradigm reflects older, more limited technologies for development and release. With the Salesforce CLI, teams can now adopt source-driven development and release capabilities.
- **Choose the most stable release mechanism possible**. This approach accomplishes two things. First, it minimizes the duration of release windows and service interruptions. Second, it allows for highly controlled and predictable release behaviors. The more stable your release mechanism, the less likely it is that releases will introduce changes that require hotfixes or rollbacks. Should an unforeseen issue arise, stable release mechanisms also create simpler ways for support staff or system administrators to perform rollbacks.

The best release mechanisms for your team are the most stable options that your team has the required skills for. These are the recommended release mechanisms, listed in order of stability. All of them are compatible with each other, so use several of them in tandem if that’s best for your company.

- [Unlocked packages](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_intro.htm)—Unlocked packages are the most stable release artifact. Deploying changes by installing a package is the fastest and most predictable way of introducing change. Packages use versioning, which allows for robust change management and fine-grained, system-admin-friendly rollbacks. And packages require strong metadata management, which can help you identify mismanaged dependencies early. They also create auditable development pipelines and artifacts. See [Packageability](/docs/architect/well-architected/guide/composable#packageability).
- [DevOps Center](https://help.salesforce.com/s/articleView?id=sf.devops_center_overview.htm&type=5)—DevOps Center allows delivery teams with low-code or pro-code skill sets to use source control, work collaboratively on changes, and define common release paths. DevOps Center integrates with source control and allows for point-and-click control of changes and deployments.
- **Source-driven development and metadata deploys using Salesforce CLI**—If you can’t use packages, use the Salesforce CLI for your source-driven development and metadata deployment. Don’t deploy metadata using the older package.xml format, which follows a different structure than the recommended [source format](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_source_file_format.htm). The source format evolved to support package development, scratch-org workflows, and more granular change tracking in sandboxes. The format is more readable, allows for more decoupling of complex metadata types and dependencies, and gives you much more control over deployment manifests.
- **Name your releases**. Give your releases clear identifiers to help your teams and stakeholders stay aligned. At Salesforce, the name of each major release starts with “Spring,” “Summer,” or “Winter,” followed by the year of the release (for example, “Summer ’25). If you don’t already have a naming convention to define and organize releases at your company, establish one and use it. Using clear release names makes it easier to stay organized at every stage of planning, development, and delivery, throughout your teams’ systems. Use your release names in your [roadmap](/docs/architect/well-architected/guide/intentional#roadmapping) to clearly communicate to your stakeholders which changes are coming and when. Use your release names in your documentation, change logs, work descriptions, code comments, and branches of source control so that you can easily trace and audit your development artifacts.
- **Within a release manifest, manage dependencies well**. Salesforce metadata has built-in dependencies. A common reason that Salesforce deployments fail is that dependencies aren’t properly managed. Choosing a stable release mechanism, as described earlier, can help expose mismanaged dependencies earlier in your development cycle. One of the main reasons that unlocked packages are the most stable release vehicle is their strong metadata management, which is required for package development and creation. If you or your release management teams don’t understand the built-in dependencies between Salesforce metadata types, you won’t be able to proactively spot problematic combinations in your deployment and release manifests. See [Dependency Management](/docs/architect/well-architected/guide/composable#dependency-management).

The [patterns and anti-patterns for ALM](/docs/architect/well-architected/guide/resilient#alm-patterns-and-anti-patterns) show what proper and poor release management looks like for a Salesforce org. Use the patterns to validate your designs before you build, or to identify places in your system that need to be refactored.

To learn more about Salesforce tools for release management, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Environment Strategy

Salesforce provides a variety of [environments](https://help.salesforce.com/s/articleView?id=sf.create_test_instance.htm&type=5) for you to use during application development and testing cycles. An effective environment strategy for Salesforce requires understanding how to use the environments and what good management looks like. In ALM, how useful a development or testing environment is depends on its fidelity to and isolation from production.

A good environment strategy provides several benefits.

- Greater fidelity to production
- Faster environment setups and teardowns
- More agile in development and testing
- Improved security throughout your pipeline
- Less noise and conflict throughout delivery stages
- Happier development teams

Teams often struggle to realize these benefits. Challenges to getting the most out of your development environments and strategy can come from several sources. One likely source is the type of development model that your teams follow.

In the older, org-based development approach, each environment needed to serve several functions. In addition to being where your team does its various kinds of work, it needed to be the source for your release artifacts (that is, the metadata that you wanted to deploy in a release). Because environments weren’t easy to set up or tear down, they were often overcrowded and full of metadata conflicts between teams, and they don’t contribute meaningful speed or flexibility to ALM overall.

Using a source-based development model fundamentally shifts the relationship that environments have to your releases and release artifacts. In this model, source control is the source of the metadata that you want to release. Environments are just places where your teams do their work.

However, following the source-based development model doesn’t alone guarantee a good environment strategy. Even with source control, teams can still struggle to set up conditions to test integrations with external systems; configurations that depend on metadata that isn’t in source control, such as managed packages or customizations that depend on [data](/docs/architect/fundamentals/guide/architecture-basics#metadata-versus-data)), and so on. In certain circumstances, the challenges from a source-based model is are similar to the challenges that are typical of an org-based model.

To develop an effective environment strategy:

- **Adopt a source-driven development and release model**. Stop using [org-based development](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models) models. See [Release Management](/docs/architect/well-architected/guide/resilient#release-management).) You must untangle your environments from what you deploy to them to create a healthy environment strategy and healthier releases.
- **Understand the types of work that each environment supports**. The environment types supported by Salesforce have different capabilities and limits. As you design your environment strategy, consider what the environments can and can’t do. Make sure that your teams do their work in an environment that has the capabilities that they need. For guidance, refer to this overview of the Salesforce development environments and their features.

|  | Scratch Org | Developer Sandbox | Developer Pro Sandbox | Partial Copy Sandbox | Full Sandbox |
| --- | --- | --- | --- | --- | --- |
| **Supports Org Shape** | Yes | No | No | No | No |
| **Supports Source Tracking** | Yes | Yes | Yes | No | No |
| **Lifespan** | 1–30 days | Manually controlled | Manually controlled | Manually controlled | Manually controlled |
| **Refresh Interval** | Not Available | 1 day | 1 day | 5 days | 29 days |
| **Release Preview Support** | [Developer controlled](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs_version_selection.htm) | Based on sandbox instance | Based on sandbox instance | Based on sandbox instance | Based on sandbox instance |
| **Provisioning Time** | > 5 minutes | Hours or days | Hours or days | Hours or days | Hours or days |
| **Metadata Determined By** | Source control | Production | Production | Production | Production |
| **Data Determined By** | Manual data load | Manual data load | Manual data load | Sandbox template | Production |
| **Data Limit** | 200 MB | 200 MB | 1 GB | 5 GB | Same as in production |

Refer to this table to learn which features and environments to use for several common development tasks.

| Task | Org Shape | Source Tracking | Frequent Refreshes | Release Preview Support | All metadata from production | Partial Metadata from production | Large datasets from production | Partial datasets from production | Compatible Environments |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Prototyping** | X | X | X | X | X | X |  | X | Scratch Orgs, Developer and Developer Pro Sandboxes |
| **New Feature Investigations or Proof-of-Concept Development** | X | X | X | X | X | X |  | X | Scratch Orgs, Developer and Developer Pro Sandboxes |
| **User Acceptance Testing** |  | X | X | X | X | X |  | X | Developer, Developer Pro and Partial Copy sandboxes |
| **Performance and Scale Testing** |  |  |  | X | X |  | X |  | Full sandbox |
| **User Training** |  |  | X | X | X | X | X* | X | Developer Pro, Partial Copy and*Full sandboxes |
| *If required to complete a specific kind of work, otherwise use a less resource-intense environment |  |  |  |  |  |  |  |  |  |

In addition, note that for Agentforce agents that use features such as the Einstein Data Library, knowledge articles, and unstructured data, comprehensive testing is limited unless you have a Data 360 sandbox. You also need a Data 360 sandbox to ensure accurate testing conditions.

- Decouple environments from release artifacts. Don’t use org-based development. Treat environments as places where work happens for a fixed amount of time. Consider the state of metadata in an environment as being separate from your release artifacts. If a piece of code or configuration gets “figured out” in an environment, it should be committed to source control, making it a release artifact.

Environments are ephemeral. Build processes so that you can create and destroy them as quickly as possible.
Artifacts endure. They belong in source control.
- Decouple environments from release paths. It’s common to see mandatory release paths that require for changes to be deployed to specific environments. Often, this approach is implemented to establish a proxy for validating application maturity or release stability. Teams can also use it to attempt to minimize the number of environments where they must configure a complex testing infrastructure. In source-based paradigms, you have greater flexibility in how and where you can validate and test changes.

Release stages apply to release artifacts, not environments. Don’t create an environment just for the purpose of “gathering” all changes in a particular release stage. That’s what source control, especially branching, is for. Use branching strategies in source control to organize which changes to deploy to which environments. Depending on the work that you need to do, you may need to deploy all the metadata in a release to an environment. Branching enables you to do that. With some exceptions, every development environment must be refreshed or destroyed as soon as the relevant work is finished. Make sure you synchronize any changes to metadata that take place within a specific environment—and that you want to retain—to source control.
Environments are only as useful as their fidelity to production. Optimize your environment setup workflows or automation so that you can tear down or refresh environments as quickly as possible. Consider any configuration that blocks you from performing faster, more frequent environment refreshes as a critical risk to the overall resilience of your ALM processes. If you have related remediation work, add it to your plans and prioritize it. Explore how you can adopt more loosely coupled, modular units in your system. They enable teams to perform more types of development in scratch orgs, and they free up sandbox allocations for other work. Don’t forget about the capabilities that scratch orgs provide for testing features that you don’t have in production, either because you haven’t purchased licenses for them or enabled them.
In environments that business users or end users can access, let those users focus on what matters to them. Don’t have generic, undifferentiated environments where many different groups of end users or business stakeholders try to do ALM-related work. Invite and activate specific stakeholders into specific environments to do specific work. Carefully evaluate any process that puts end users or business stakeholders in an environment with more data than a Partial Copy sandbox can support. Make sure the data volume is necessary to the work to be done. Plan your user acceptance testing and early-stage development cycles so that they occur as closely together as possible. Optimize all testing stages to enable faster, earlier feedback and iteration cycles for your development teams and end users. See testing strategy.
- Build different release paths for different types of changes. Not all changes require that the same types of ALM work be completed in the same order. Having end users perform acceptance testing for minor changes to backend components of a system probably isn’t a good use of their time. User acceptance and scale testing can be tremendously valuable during the early-stage development of a mobile application, though. Identify release paths for different categories of change, such as high risk, medium risk, and low risk.

High risk: Changes impact customers, partners, or all internal users. Changes impact security or integration. Changes add complex new functionality.
Medium risk: Changes impact more than a defined threshold of internal users. Changes impact data models, automation that carries out data operations, or integration.
Low risk: Directly impacts fewer than a defined threshold of internal users. Doesn’t include changes to security, data models or automations involving data operations, or integration.
- Don’t allow overcrowded environments to exist. A lack of discipline in prioritizing, scoping, and sequencing work inevitably leads to overloaded development environments, with volumes of work that are too much, too many, too different. Overcrowded environments create high levels of stress, ambiguity, and conflict among development teams. They also create noise within development pipelines and impede quality control efforts. In addition to these negative impacts, overcrowded development environments are serious threats to environment maintenance and security. Consider overcrowding as a symptom of potential problems in your ALM processes. Investigate for any root cause issues and address them. If you still face overcrowding, you can purchase additional sandboxes.

The list of [patterns and anti-patterns for ALM](/docs/architect/well-architected/guide/resilient#alm-patterns-and-anti-patterns) shows what proper and poor environment management looks like in a Salesforce org. Use them to validate your designs before you build, or to identify areas of your system that need to be refactored.

To learn more about Salesforce tools for environment management, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Signaling Strategy

A signaling strategy defines the critical signals and application instrumentation needed to detect, diagnose, and remediate failures before they cascade into system-wide degradation. Effective instrumentation transforms applications from passive victims of failure into active participants in their own resilience, capable of detecting problems, adapting their behavior, and coordinating graceful degradation when necessary.

When applications implement comprehensive instrumentation, they gain the ability to self-regulate under stress, communicate their health status to operators, and participate in coordinated recovery efforts. These capabilities allow systems to maintain service quality even as individual components experience distress. On the other hand, without proper instrumentation, applications become black boxes that fail silently until catastrophic symptoms appear. Teams react to problems only after users report them, and troubleshooting becomes an exercise in archaeology rather than observation.

- Detect failures within the application. Applications must instrument themselves to detect and respond to common failure patterns that emerge under heavy load. Consider queue saturation. When message queues fill faster than they can be processed, uninstrumented applications continue accepting work until memory exhaustion or timeout cascades occur. Properly instrumented applications monitor queue depth, rejection rates, and processing latency, triggering defensive responses when thresholds are exceeded.
- Effectively handle signals from outside the application: The handling of signals from the operating system represents another critical instrumentation point. Applications must register handlers for termination signals (SIGTERM, SIGINT) to enable graceful shutdown. During shutdown, properly instrumented applications stop accepting new work, allow in-flight requests to complete, flush buffers, close connections cleanly, and deregister from service discovery. This orchestrated shutdown prevents data loss and allows load balancers to redirect traffic without disruption.
- Instrument for complex failure scenarios: Beyond these basic patterns, applications must instrument for more subtle failure modes. Identifying gray failures, where components appear healthy to some observers while failing for others, requires correlating both internal and external signals. An application might instrument its database connection pool to report successful health checks while simultaneously tracking transaction completion rates that reveal creeping degradation. Effective instrumentation strategies layer multiple observation points.

Business metrics track application-specific success indicators, such as order completion rates or search result quality.
System metrics monitor resource utilization, latency distributions, and error rates.
Synthetic probes continuously exercise critical paths to detect degradation before users encounter it.
Distributed tracing provides request-level visibility across service boundaries.

These signals are exposed through standardized interfaces that allow both automated systems and human operators to assess application health. The instrumentation itself becomes part of the application's resilience strategy, enabling circuit breakers to trip based on error rates, autoscalers to respond to queue depths, and [operators to make informed decisions during incidents](/docs/architect/well-architected/guide/resilient#incident-response).

The [patterns and anti-patterns for ALM](/docs/architect/well-architected/guide/resilient#alm-patterns-and-anti-patterns) show what a proper and poor signaling strategy look like in a Salesforce org. Use them to validate your designs before you build, or to identify areas of your system that need to be refactored.

To learn more about Salesforce tools for a signaling strategy, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Testing Strategy

A test strategy is a set of guiding principles and standards for how to plan and run tests that gauge the success and failure of applications during ALM processes. A test strategy keeps every stakeholder who is involved in testing informed about and aligned with the priority, purpose, and scope of a given test. It also helps project teams create effective and thoughtful test plans.

Typically, developers or quality assurance and testing experts are involved in creating and executing specific tests. A test strategy helps ensure that these individuals know what kinds of tests need to be conducted for a given project and in what sequence to conduct them. A test strategy also helps ensure that teams have what they need to build well-formed tests, test plans, and artifacts (for example, test data sets, devices, and traffic or network simulators).

An effective testing strategy creates a clear picture of how, when, where, and why to run different test types—including unit tests, UI tests, and regression tests—in various combinations and conditions to uncover how your system and any in-flight changes will behave. An effective test strategy produces tests that show you how well a system conforms to non-functional requirements—such as scalability, reliability, and usability—which can be difficult to measure through a single kind of test.

To create effective testing strategies for Salesforce:

- **Test iteratively, frequently, and through automated means as much as possible**. Design and implement test automation that enables teams to run a variety of test types against a variety of workloads. Orchestrate various test runs to happen automatically when changes come into source control. This approach enables teams to proactively identify and address regressions early on. Use continuous integration/continuous delivery (CI/CD) for this effort if possible. If you don’t, establish clear test plans that enable teams to run sequences of tests early and often, in a self-service manner. For Agentforce agents testing, rely on Testing Center for rigorous, batch testing of AI agents with various inputs to ensure that they function correctly across different scenarios.
- **Recognize that not every change requires every kind of test**. Just as an effective release pipeline accommodates paths for high-, medium-, and low-risk applications, so does an effective test strategy. Clearly outline for teams how to select and follow an appropriate testing regime for applications with various types of risk, use cases, or complexity. See [Environment Strategy](/docs/architect/well-architected/guide/resilient#environment-strategy).
- **Define which tests can be conducted in different environment types**. Fidelity to production is a key component of accurate testing, but it means different things for different kinds of tests. For example, regression testing needs fidelity to production in terms of metadata, and to some extent, data. Make sure to define what kind of fidelity to production is required for a given set of tests, and clearly classify what types of environments can support the conditions that are appropriate for different tests. For an overview of the types of work that align to each environment type, See [Environment Strategy](/docs/architect/well-architected/guide/resilient#environment-strategy).
- **Use endurance, stress, performance, and scale tests to continuously gauge application maturity**. These tests show how release ready an application is, relative to production-level needs. For major new features, run these tests at several intervals in the application development cycle. It’s an anti-pattern to consider these tests as a part of only a single phase or stage of development instead of as part of ongoing tasks. It’s most useful for teams to get feedback about app performance early and often, which helps them better understand how close or far the app if from production-level readiness. The ability to better identify and address issues before changes go into production is well worth the added complexity of frequently running more sophisticated tests.

Know which tests matter. You will probably have a fixed amount of time to conduct your scale or performance testing, making it impractical to test every facet of your system. Not all features are used equally, and not all scale bottlenecks will impact the business equally. Ensure that your scale tests are focused on the most highly used and highly valued parts of the system. Define and understand the most important opportunities for verifying and improving scale and performance in your org.
Know what “good enough” looks like. Defining the success criteria for your scale and performance tests is critical. Make sure that you and your development teams use the success criteria as testing benchmarks. Also, ensure that they inform the functional requirements that development teams build towards. Typically, these criteria include supporting a specific number of concurrent users with response times that are less than an agreed-upon value, and your service-level objectives (SLOs). Define your key target criteria, and then design scale and performance tests that ensure that the criteria are met.
Ensure that you have adequate environments. Scale and performance testing require a particular fidelity to production. Your datasets, request demographics, request rates, and workload characteristics in your non-production environments should all match what you see in production as much as possible. For scale testing, you must use a Full sandbox. If your org doesn’t have a Full sandbox for scale testing, you can’t run adequate scale tests.
- **Ensure that test workloads help you measure non-functional requirements**. Remember to consider:

Test data-Every kind of test should occur against data that is isolated from production. In Apex unit tests, implement data-factory patterns to ensure that code generates its own test data, isolated from environment data. You can also create and maintain test datasets in a variety of formats to test data-load behaviors, populate development environments with data for UI-based tests, and assist with integration testing. All test data, whether maintained as an externalized dataset or created on demand by data-factory code, should be scrubbed of sensitive and identifying data. It should include corrupt, incomplete, and malformed data to support negative and boundary unit-test behaviors.
Mock and stub services-For integration testing, you can use mock and stub services to simulate API responses. Apex supports a Stub API to create mocking frameworks for use in Apex tests. Mocking to create mocking frameworks that can be used in Apex tests. Mocks and stubs can help validate data-handling behaviors of a system, with less reliance on complex data factories or external test data sets. Mocks and stubs are sometimes more appropriate to use in tests where production-like traffic or data volumes aren’t relevant.
Devices and assistive technology-A key part of building engaging and accessible applications is ensuring that they meet user expectations across a variety of devices and with different types of assistive technologies. Meaningful usability testing may require more investment and different kinds of expertise to carry out effectively, but it’s an essential part of knowing how well architected your user-facing applications will be when they’re released.
Simulators-When you need to replicate production-like volumes of user requests, API traffic, or variations in network speed, you may need tools that simulate these conditions. Not every test needs this level of investment. These tools are often most useful in scalability and performance testing.
AI and agent testing-A primary goal of testing is to reduce AI hallucinations, which are convincing responses that are fabricated and incorrect . Ensure that AI use cases are tested to highlight common issues that are caused by an incomplete understanding of the customer, missing data, fields with incomplete metadata, and outdated data. Use the Testing Center to assist with creating necessary test data for such tests.

### ALM Patterns and Anti-Patterns

The following table shows a selection of patterns to look for or build in your org, and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for ALM in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/adaptable-application-lifecycle-management).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Release Management** | **In production:**

 - Metadata shows use of stable release mechanisms, such as:
        
 -- Metadata being organized into unlocked packages
        
 -- DevOps Center being active and installed
        
 -- Deployments via the Metadata API using the source format
        
 - Deployment logs show no failed deployments within the available history.
        
 - Deployment history shows clear release cadences and fairly uniform deployment clusters within release windows. | **In production:**

 - Metadata indicates use of org-based release mechanisms, such as:
        
 -- Active use of change sets
        
 -- Deployments via Metadata API use package.xml format
        
 - Deployment logs show repeated instances of failed deployments within the available history.
        
 - Deployments have no discernable cadence or show uneven clusters of deployments, which are signs of hot-fixes and ad hoc rollbacks).
        
 - DevOps Center isn't enabled and installed. |
| **In your roadmap and documentation:**

 - Release names are clear.
        
 - Features are clearly tied to a specific, named release.
        
 - Release names are searchable and discoverable.
        
 - Teams can find and follow clear guidelines for tagging artifacts, development items, and other work with the correct release names.
        
 - It's possible to pull together a clear view of a release manifest by a release name.
        
 - Quality threshholds for generative AI apps are defined for different development stages. | **In your roadmap and documentation:**

 - Release names aren't included.
        
 - Features aren't clearly tied to a specific release.
        
 - Release names are used ad hoc or don't exist.
        
 - Teams refer to artifacts, development items, and other work in different ways.
        
 - It's not possible to pull together a clear view of a release manifest using a release name.
        
 - Quality thresholds for generative AI apps aren't defined, or if they are, aren't defined for different development stages. |  |
| **Environment Strategy** | **In your orgs:**

 - A source-driven development and release model is adopted.
            
 - Source tracking is enabled for Developer and Developer Pro sandboxes.
            
 - Metadata in a given environment is independent from release artifacts.
            
 - Environments don't directly correspond to a release path.
            
 - Release paths for a change depend on the type of the change (high risk, medium risk, or low risk).
            
 - Overcrowded environments don't exist.
            
 - Risky configuration changes are never made directly in production.
            
 - No releases occur during peak business hours.
            
 - Data 360 sandboxes are used to properly test agentic use cases that require Einstein Data Library, knowledge articles, and unstructured data | **In your orgs:**

 - An org-based development and release model is adopted.
                
 - Source tracking isn't enabled for Developer and Developer Pro sandboxes.
                
 - Metadata in a given environment is a release artifact.
                
 - Environments directly correspond to a release path.
                
 - The release path for every change is the same, regardless of the type of change.
                
 - Overcrowded environments exist. - Risky configuration changes are made directly in production.
                
 - Releases occur during peak business hours.
                
 - Agentforce agents that require Einstein Data Library, knowledge articles, and unstructured data are not tested using Data 360 sandboxes |
| **Signaling Strategy** | **In your orgs:**

 - Teams collaborate on defining and standardizing health check APIs and SLOs.
                
 - The regular review and refinement of signaling strategies are part of post-mortems and operational readiness reviews.
                
**In production:**

 - Health checks are implemented for all applications.
                
 - Applications provide explicit signals about their health, such as their load and capabilities.
                
 - Applications are designed to degrade gracefully when dependencies are unhealthy.
                
 - Load shedding is used to prevent cascading failures.
                
**In your design:**

 - Backpressure and load-shedding mechanisms prevent services from being overwhelmed by traffic.
                
 - It's assumed that dependencies eventually fail. Signal handlers are built to ameliorate failures. | **In your orgs:**

 - Teams operate in silos, creating inconsistent and incompatible health-signaling mechanisms.
                
 - Signaling strategies are an afterthought, only addressed when an incident occurs.
                
**In production:**

 - Components fail silently without signaling their health status.
                
 - Applications retry requests to unhealthy services indefinitely.
                
 - All requests are treated with the same priority, regardless of their importance.
                
 - To identify problems, operators rely solely on reactive measures, such as user complaints or critical system failures.
                
**In your design:**

 - It's assumed that all dependencies will always be available, and network partitions, latency spikes, or other common issues aren't accounted for.
                
 - Applications accept all incoming requests, even when they are overloaded, leading to increased latency and a higher likelihood of failure |
| **Testing Strategy** | **In your business:**

 - Usability tests employ a variety of devices and assistive technology.
                
 - Simulators are used to replicate production-like conditions for scalability and performance testing.
                
 - Tests are automated to run when changes come into source control.
                
 - Endurance, stress, performance, and scale tests are run at several intervals in the application development cycle and considered ongoing tasks.
                
 - You include scale testing as part of your QA process when you have B2C-scale apps, large volumes of users, or large volumes of data.
                
 - Your scale tests are focused on high-priority aspects of the system.
                
 - Your scale tests have well-defined criteria.
                
 - You conduct scale testing in a Full sandbox.
                
 - Prompt engineering includes a quality review by a human.
                
 - Agentforce Testing Center is used for robust agent testing. | **In your business:**

 - Usability tests aren't conducted, or if they are, are conducted on a limited set of devices.
                
 - Production-like volumes of user requests, API traffic, and variations in network speed aren't tested.
                
 - Test automation isn't in place.
                
 - Endurance, stress, performance, scale tests are considered a phase or stage of development.
                
 - You don't conduct scale tests as a part of your QA process, and you have B2C-scale apps, large volumes of users, or large volumes of data.
                
 - Your scale tests aren't prioritized.
                
 - Your scale tests don't have well-defined criteria.
                
 - You conduct scale tests in a Partial Copy or Developer sandbox.
                
 - Prompt engineering doesn't include a quality review by a human.
                
 - Agentforce agents aren't tested, or if they are, tested only ad hoc using Agent Builder. |
| **In your org:**

 - All test data is scrubbed of sensitive and identifying data. | **In your org:**

 - Test data is identical to production data. |  |
| **In Apex:**

 - Data factory patterns are used for unit tests
            
 - Mocks and stubs are used to simulate API responses. | **In Apex:**

 - Unit tests rely on org data.
                
 - Mocks and stubs aren't used. |  |
| **In your design standards and documentation:**

 - Environments are classified by the types of tests they can support.
            
 - Appropriate test regimes are specified according to risk, use case, or complexity. | **In your design standards and documentation:**

 - Which types of tests each environment supports isn't clear.
                
 - Test regimes aren't categorized by risk, use case, or complexity. |  |

## Incident Response

In security and site reliability engineering (SRE), incident response is focused on how teams identify and address events that impact the overall availability or security of a system, as well as how teams work to address root causes and prevent future issues. Incident response involves the processes, tools, and organizational behaviors required to address issues in real time and after an issue occurs.

As an architect, you may not be the person monitoring your solution’s operations on a day-to-day basis once it goes live. Part of architecting for resilience is designing recovery capabilities that enable support teams to perform first-level diagnosis, stabilize systems, and effectively hand over the investigation and root cause mitigation to development or maintenance teams. Teams directly supporting users on a day-to-day basis may not have a deep understanding of or expertise in the architecture of the system. It’s essential for these teams to have the tools and processes that they need to monitor daily operations, access information from the system when diagnosing a potential incident, and serve as effective first-responders for any issues impacting availability.

You can improve how well teams respond to incidents in your Salesforce solutions by focusing on your [time to recover](/docs/architect/well-architected/guide/resilient#time-to-recover), [ability to triage](/docs/architect/well-architected/guide/resilient#ability-to-triage), and [monitoring and alerting](/docs/architect/well-architected/guide/resilient#monitoring-and-alerting).

### Time to Recover

When an incident occurs, the first priority must be restoring systems to a stable operational state. Often, businesses think that the only way to recover from an incident is to “fix the problem.” This assumption is fair in that accurate root cause analysis and remediation is how you ultimately resolve critical issues in a system. However, “fixing the problem” during the early stages of crisis response isn’t the most practical approach. Depending on the severity of an incident, every second of it and its impact could lead to a revenue or reputation loss for the business.

Often, attempting to diagnose and address root causes delays efforts to restore a system to operation. Logistically, adopting an approach that asks incident responders to address root causes puts tremendous strain on the subject matter experts (SMEs) and support staff at your company. Working to find and fix root causes *during* an incident requires SMEs to be on call for every incident, which can block frontline, customer-facing support staff from taking action. It can also result in teams releasing changes that, in turn, create more incidents. Ultimately, such an approach increases costs, consumes bandwidth across teams, and leads to behaviors in times of crisis that can erode customer trust and brand reputation.

The right incident management paradigm is to prioritize and focus on recovery as a first step. After a system is restored to stability, you can follow up with blameless postmortems, incident investigations, root cause remediation, and similar activities. This order of operations better enables incident response staff to triage, diagnose, and execute recovery tactics, alerting relevant SMEs to assist only as necessary. It also enables SMEs to identify and fix the root causes of an incident with less pressure from a tickingclock.

To adopt a recovery-first mindset to incident response:

- **Establish and achieve service-level objectives SLOs**. SLOs are standards that you develop with your stakeholders for specific non-functional requirements (NFR) of a system, such as performance or uptime. These objectives are measured by service-level indicators (SLIs), over a period of time. Without SLOs, much of the work around incident response and troubleshooting complex issues can feel disorganized and reactive—for example, prompting swift action to “stop this specific error, for this handful of users who reported it.” This cycle is often what causes teams to push root cause analysis closer to incident response—because it seems like it will help stop the reactive behaviors. Establishing SLOs and SLIs is a more effective way to start. To establish SLOs, think about these questions.

What are the NFR of your system for the next 1–3 years? For example, your NFR may include the response times, peak request rates, and concurrent users that your system must be able to support.
What do you want your customers and their users to experience? Base your SLOs on the answer to this question, which might be, “Users can run reports quickly in Salesforce.”
What can you measure, and for what period of time should you measure it? Base your SLIs on the answer this question. An SLI to match the previous example might be “x% of reports load within n seconds on average, measured over a 30-day period.”
- **Define and standardize recovery tactics.** Change rollbacks and workaround implementations can help get a system functional again and minimize the impact of an incident. Document recovery tactics and protocols that can be executed by the appropriate members of your support or operations teams. Recovery tactics differ based on incident type. The next table shows a general framework that maps incident types to recovery tactics. For more on identifying failure points and defining mitigation strategies, See [Availability](/docs/architect/well-architected/guide/reliable#availability).

| Incident Type | Apparent Trigger | Recovery Tactics |
| --- | --- | --- |
| **System Outage** | Corrupted logins or issues with account access | An account recovery policy |
| Service unavailability | Activating redundant, backup service; manual workarounds |  |
| **Production Bug** | A recent change | Deployment rollback or de-deployment of the previous version |
| An emergent,  unexplained bug | Manual workarounds, disabling non-essential features, escalating to SMEs |  |

- **Define clear exit criteria**. Use your SLOs to determine when your system is out of incident or impact status.
- **Define processes for post-incident reviews and root cause remediation.** Take time to review incidents after service is restored. During reviews, take a *blameless postmortem* approach. Work with stakeholders to focus on establishing clear facts about *what* occurred and *how* it occurred, rather than attempting to assign fault or blame to individuals. Use different review formats to examine ways to address issues in the long term.

An after-action review focuses on the response to the incident. It’s useful for evaluating if the appropriate response processes and tactics are in place.
A root cause analysis focuses on the root cause of the incident. It can help identify any bugs or issues in your system’s design and implementation that led to the incident.
- **Practice your agreed-upon recovery protocols periodically**. Practice recovery protocols to ensure that everyone knows how to handle incidents well. Use sandboxes and test environments to give teams places to practice incident simulation and recovery. Also practice your post-incident reviews. Doing all that practice makes recovery a part of your engineering and support culture.

The [patterns and anti-patterns for incident response](/docs/architect/well-architected/guide/resilient#incident-response-patterns-and-anti-patterns) show what architecting to prioritize recovery looks like in a Salesforce solution. Use them to validate your designs before you build, or to identify areas of your system that need to be refactored.

To learn more about Salesforce tools to help with time to recover, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Ability to Triage

In the context of technology, triaging involves assigning categories and levels of severity to issues and support requests. No matter how well planned your solution is, user support issues and requests will arise. These issues can stem from a lack of sufficient training or change management, gaps in UI/UX, unexpected end-user behaviors, and urgent system issues not caught by [monitoring or alerting](/docs/architect/well-architected/guide/resilient#monitoring-and-alerting).

Support and operations teams need to be able to investigate user support queries efficiently and diagnose them quickly. Triaging issues to filter out less severe concerns and quickly spot critical system incidents is a key competency for these teams. Poor triaging slows all levels of user support, prolongs critical incidents, and increases the risk of further disruptions to your customers and your business.

Although you may not be involved in day-to-day operations and support, as an architect, it’s your responsibility to help ensure that your support and operations teams can effectively triage issues in any solution that you create on the Salesforce platform.

To enable teams to effectively triage issues within your Salesforce solutions:

- **Ensure that support teams have access to useful information**.

Document your system and design patterns. Ensuring readability and consistency in your solution is a key part of enabling support staff to understand the system that they are responsible for supporting. In your documentation, consider how teams will find information about how to prioritize issues or incidents with different parts of the system. Also, ensure that teams can quickly get to technical information about recovery tactics based on the area of impact. Provide relevant troubleshooting guides for common Agentforce issues, such as Topic Classification and Action Selection, which can help teams quickly triage problems related to permissions or configuration.
Design with debugging in mind. Support teams and org administrators will need to enable debugging and diagnostics to correctly triage user issues in various environments. Examples of debug-friendly patterns include those that incorporate logging and custom error messages into execution paths throughout the system. Enable support teams on common Agentforce debugging approaches with tools such as Event logs and Agent Builder’s reasoning view.
Identify incident SMEs and stakeholders. Create a list of relevant SMEs or stakeholders who should be available to support recovery from an incident, and who should be involved during post-incident analysis.
Treat handoffs thoughtfully. Ensure the quality of each solution handoff to support or operations teams as a part of go-live. Provide training for support staff to walk through the relevant system architecture and mock-incident response drills. Think about post-incident handoffs, including how teams should document information that isn’t captured by logs or case notes, as well as how incident responders can contribute to root cause investigations or perform user acceptance testing for any remediations.
- **If you’re consulted, keep everyone focused on recovery as the top concern**.

Respond quickly. Respond quickly to any user support requests, monitoring notifications, and alerts you receive.
Help distinguish symptoms from issues. Work to determine if there is an actual system incident that needs to be addressed. Try to identify the components with the actual issues. Help ensure that the agreed-upon recovery tactics are followed to get the system out of incident status quickly.
- For Agentforce agents supporting critical use cases, ensure viable and relevant workarounds are in place and can be switched on with short notice as a redundancy measure. Examples include switching to manual handling or redirecting to relevant documentations for manual review.

The [patterns and anti-patterns for incident response](/docs/architect/well-architected/guide/resilient#incident-response-patterns-and-anti-patterns) show what architecting for effective triaging looks like in a Salesforce solution. Use them to validate your designs before you build, or to identify areas of your system that need to be refactored.

To learn more about Salesforce tools to help with triaging, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Monitoring and Alerting

*Monitoring* and *alerting* are widely used terms in site reliability engineering. In the context of system resiliency, monitoring is continuously assessing the current state of a system, and alerting is automating notifications to stakeholders about potential concerns about the state of the system. Effective monitoring and alerting is a key part of decoupling the scale and growth of your system from the scale and growth of your support staff.

Salesforce provides a variety of built-in capabilities to monitor behaviors in your system. Salesforce also offers [real-time event monitoring](https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/real_time_event_monitoring_overview.htm) as an add-on or as part of [Salesforce Shield](https://www.salesforce.com/products/platform/products/shield/). In any Salesforce solution, designs architected for monitoring and alerting provide:

- Capabilities for automated incident response
- Relevant information to the right users, at the right time
- Clear information for historical views and trend analysis

To architect for effective monitoring and alerting within your Salesforce solutions:

- **Make automation a priority**. Although notifying users about critical state changes is a crucial part of keeping your systems stable and operational, in an ideal architecture, the system self-corrects issues when possible and only sends alerts for urgent, non-recoverable issues. Even without self-correcting capabilities, automation can make your alerting and reporting more useful.

Start with what Salesforce already provides. The Salesforce Platform provides relevant logs and APIs for you to monitor your solution’s operations with respect to governor limits. In addition, the platform sends alerts for governor limit violations and similar issues. Use these logs and alerts as the basis for exploring ways to more fully automate system self-recovery, incident reporting, and alerts. For example, you might implement automation that monitors the log, and then takes a recovery action when a particular type of event is logged.
Classify changes to system state in predictable ways. Create specific, meaningful categories for key states that you want to monitor and report on. Align these categories with the categories that you define to manage state in your application components. Adopt an API-oriented mindset for how you handle state change information. Consistent message formats and state categories simplifies automation, reporting, and alerting.
Align your automation logic with the other parts of your system. If you’ve built proper automation error handling, you can extend those patterns to how you classify state changes and respond with automation. For state changes that are considered recoverable, you can automate retry behaviors. For state changes that are considered critical or fatal, automate alerts to users.
- **Avoid creating noise**. When users receive too many alerts, especially alerts that don’t require taking any action, they tend to start disabling or ignoring all alerts. This scenario undermines any efforts to create [helpful](/docs/architect/well-architected/guide/engaging#helpful) alerts. To better scope who receivesalerts, what triggers them, and when they’re triggered, consider doing these things.

Build stakeholder maps. To make sure that your system delivers the right alerts to the right stakeholders at the right times, first identify and classify your stakeholder groups.
Route messages based on user privileges. Only send alerts to recipients who have the ability and authority to respond. Business users might benefit from alerts about issues that they can fix by correcting issues in records that they have access to. If an issue requires a more involved technical response, alerts should be directed to support staff.
Make the expected response clear. Only send alerts in scenarios that require human intervention. Structure messages to clearly indicate the action that’s expected from the recipient. If you do send an alert to a stakeholder for visibility, and no action is required from them, make that clear in the version of the message that they receive.
Make alerts timely and relevant. Alerts that are delivered in response to failures that occurred and still need to be remediated) aren’t as helpful as alerts about a potential failure. Ideally, support staff are alerted as soon as problematic conditions occur in the system, providing an opportunity to triage issues before they can have negative impacts on business operations.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/resilient#incident-response-patterns-and-anti-patterns) show what architecting for effective monitoring and alerting looks like in a Salesforce solution. Use them to validate your designs before you build, or to identify areas of your system that need to be refactored.

To learn more about Salesforce tools for monitoring and alerting, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Incident Response Patterns and Anti-Patterns

This table shows a selection of patterns to look for or build in your org, and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for incident response in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/adaptable-incident-response).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Time to Recover** | **In your business:**

 - Recovery protocols are practiced at regular intervals.
                
 - Teams know which services in production they own and are responsible for.
                
 - Teams understand relevant tooling to support the diagnosis of issues. | **In your business:**

 - Recovery protocols don't exist or aren't practiced at regular intervals.
                
 - Which teams own and are responsible for the different services in production isn't clear.
                
 - Teams have no guidance or standards on tooling to support the diagnosis of issues. |
| **In your documentation:**

 - Recovery tactics are defined and classified by incident type and trigger.
            
 - Exit criteria for incident responses are included in SLOs and are clear.
            
 - Activation criteria and assignment logic for elevated permissions during incidents are clear.
            
 - Incident response permission sets and authorizations are clearly listed.
            
 - A troubleshooting guide to assist with identifying and diagnosing common issues exists. | **In your documentation:**

 - Incident response is performed ad hoc.
                
 - Exit criteria for incident responses don't exist.
                
 - Elevated permissions aren't assigned, or if they are, are assigned ad hoc.
                
 - Incident response permission sets and authorizations aren't listed. |  |
| **In your org:**

 - Session-based permission sets for incident response exist and can be assigned to support staff during recovery.
            
 - Setup Audit Trail shows that designated recovery testers logged into the testing environment at  the agreed-upon time and  followed recovery test scripts. | **In your org:**

 - Session-based permission sets don't exist for incident response, or if they do, support staff aren't authorized to use them.
                
 - Setup Audit Trail shows that designated recovery testers didn't logged into the testing environment or didn't follow recovery test scripts |  |
| **In your test plans:**

 - Test scripts for recovery testing exist and are repeatable.
            
 - Environments for incident simulations are clearly listed. | **In your test plans:**

 - Test scripts for recovery testing don't exist.
                
 - Environments for incident simulations aren't established. |  |
| **Ability to Triage** | **In your business:**

 - SMEs or stakeholders who should be alerted to support complex issues are identified before an incident occurs.
                
 - The handoff between delivery and support teams is a part of go-live.
                
 - If consulted, Salesforce architects respond quickly and help the team stay focused on recovery. | **In your business:**

 - SMEs or stakeholders who should be alerted aren't identified until an incident occurs.
                
 - The handoff between delivery teams and support teams isn't a part of the release process.
                
 - Salesforce architects consider incident response to be outside their scope of work. |
| **In your documentation:**

 - System and design patterns used in a given solution are discoverable and readable by support staff. | **In your documentation:**

 - System and design patterns used in a given solution aren't readily available to support staff. |  |
| **In your org:**

 - Logging and custom error messages are incorporated into execution paths throughout the system. | **In your org:** - Logging and custom error messages aren't used. |  |
| **Monitoring and Alerting** | **In your org:**

 - Alerts are used only to inform users of scenarios that require human intervention; other failures are logged and reportable.
                
  - Alerts are sent to users who are capable of responding to them.
                
 - When possible, alerts are delivered before a potential failure. | **In your org:**

 - Alerts are sent when any type of failure occurs, regardless of whether follow-on actions are required.
                
 - Alerts about issues requiring technical solutions are delivered to business users.
                
 - Alerts are only delivered in response to failures that have already occurred. |
| **In your documentation:**

 - Entry criteria for prompt-tuning alerts are defined based on direct and indirect generative AI feedback metrics. | **In your documentation:**

 - There are no criteria defined for triggering prompt-tuning alerts for generative AI apps. |  |

## Continuity Planning

A key to business resilience is continuity planning, which focuses on how to enable people and systems to function through issues caused by an unplanned event. Business continuity plans (BCPs) take a people-oriented view of how to keep processes moving forward through crisis. Technical aspects of continuity planning are contained in the disaster-recovery portions of a BCP. See [Technology Continuity](/docs/architect/well-architected/guide/resilient#technology-continuity).

Without adequate continuity plans, your organization may now know how to act—and therefore not act at all—during a crisis or system outage. Ineffective continuity planning can have catastrophic impact on customers, stakeholders, and business. In the wake of an adverse event, each moment that passes without maintaining or recovering critical processes risks financial damage, reputational damage, employee safety, and even regulatory compliance.

You can build better continuity planning into your systems by focusing your efforts in three areas: [defining business continuity for Salesforce](/docs/architect/well-architected/guide/resilient#business-continuity), [planning for technology continuity](/docs/architect/well-architected/guide/resilient#technology-continuity), and [building backup and restore capabilities](/docs/architect/well-architected/guide/resilient#building-backup-and-restore-capabilities).

### Business Continuity

Your company may already have a BCP in place. If it does, make sure that Salesforce is included in it. If your company doesn’t have a BCP, work with your stakeholders to create one that covers your Salesforce orgs.

Salesforce is often relied upon to be a source of truth for customer data and essential business processes across many business divisions. As such, the role that Salesforce plays in a BCP may differ from the roles that other systems play. It’s likely that Salesforce will be involved in many high-priority areas for recovery.

To create relevant business continuity planning for Salesforce systems:

- **Clarify priorities for recovery**. As with the general approach for [incident response](/docs/architect/well-architected/guide/resilient#incident-response), recovery needs to be the first priority for systems in moments of crisis. Many business-critical services run in and with Salesforce. You must help stakeholders identify the correct priority for recovering various business functions and capabilities. A general framework could be:

Stabilize essential business infrastructure.
Stabilize customer services.
Stabilize employee and partner services.
- **Account for your ecosystem in your BCPs**. Salesforce is not the only system in your landscape. Make sure that you identify gaps in your BCP around systems that integrate with Salesforce, solutions installed from AppExchange vendors, and any other systems that connect to data or processes in Salesforce. If your ability to deliver depends on vendors, ask those vendors about their continuity plans. Assess their capabilities and plan for how to keep your systems available.
- **Integrate BCP concerns into your testing strategy**. Create test plans for your BCP and carry them out. It’s especially important to test the areas of your BCP related to processes or people, which are often overlooked. Incorporate relevant items from your BCP into your overall ALM [test strategy](/docs/architect/well-architected/guide/resilient#testing-strategy). Create and follow a maintenance schedule to review tests and ensure that your plan stays up to date.

The [patterns and anti-patterns for continuity planning](/docs/architect/well-architected/guide/resilient#continuity-planning-patterns-and-anti-patterns) show what proper and poor continuity planning looks like in a Salesforce solution. Use them to validate your designs before you build, or to identify places in your system that need to be refactored.

To learn more about Salesforce tools for defining business continuity, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Technology Continuity

The goal of technology continuity is to make sure that issues with components in a system don’t prevent the business from maintaining essential operations. Salesforce prioritizes maintaining our services at the highest levels of availability and providing transparent information about any issues. You can see real-time information about Salesforce system performance and issues at [trust.salesforce.com](https://trust.salesforce.com/). As an architect building on Salesforce, your solutions benefit from the site reliability, security, and performance capabilities that Salesforce provides across the entire platform.

However, the overall continuity of your Salesforce solutions extends beyond the built-in services Salesforce provides. From an architectural perspective, Salesforce technology continuity planning has to begin with asking and answering questions about how Salesforce fits into your larger enterprise landscape. What kinds of systems integrate with Salesforce? How do external systems depend on processes or information in Salesforce? In your Salesforce orgs, what processes or functionality rely on AppExchange solutions? Do your users access Salesforce through third-party identity services or SSO?

To build better technology continuity in your Salesforce systems:

- **Assess your infrastructure.** The most common remediation strategy for technology outages or issues is building redundant services or systems that you can fall back to during an incident. At Salesforce, we have an intentionally redundant architecture, meaning that we maintain copies of our customers’ systems and services in different physical locations. We use several disaster-recovery techniques, including site switching, which enables us to direct user traffic from one data center to another if needed. To identify where you might need to build intentional redundancy, ask yourself these questions.

What happens during a service interruption for the [X] service? Can we switch from that service to another one?
How long does it take to recover [X]? What is the impact to our customers? What is the impact to our partners? What is the impact to internal teams?
What about backups and their frequency? Could the backups provide the data needed to support the business?
Do we have dependencies on vendors? What are their BCP plans?
- **Provide operational support.** Operational support is about getting teams back up and running as fast as possible. Think through how your system can handle significant increases in capacity requirements and demand from unanticipated changes, including changes that are industry wide, region wide, or global. Make sure that your BCP accounts for the additional resources or break-glass procedures that Site Reliability Engineering (SRE) or support teams may need to respond to incidents effectively. Questions to ask about operational support include:

In an outage, would our technical teams have the tools that they need to continue work? Have we simulated an outage to validate plans or identify gaps?
If a disaster is in a specific area, do we have coverage plans for that area?
Are our customers global? Do they operate 24/7?
Do we have proper monitoring and alerting to notify the appropriate individuals when there are failures?
- **Automate and test your recovery tactics.** After an issue is remediated, identify where it occurred and how it was fixed. If you can, based on the remediation, automate your recovery tactics and adjust any process issues. Many companies schedule incident simulations for a subset of services to test system resiliency. An example could be simulating a system administrator account being locked out or compromised, or simulating an outage or issue with an AppExchange provider. See [Incident Response](/docs/architect/well-architected/guide/resilient#incident-response).)Questions to ask about how testing and automation can help you restore services faster include:

How often do we schedule and run incident simulations?
Do we know how long it takes to restore services to a stable state?
Do we have stable delivery processes in place?
Do we know where we can automate failover and recovery?

Treat any items that come out of your post-incident reviews like your other development items. Add them to your planning systems so that you can prioritize them and work on them.

The [patterns and anti-patterns for continuity planning](/docs/architect/well-architected/guide/resilient#continuity-planning-patterns-and-anti-patterns) show what proper and poor technology continuity planning looks like in a Salesforce solution. Use them to validate your designs before you build, or to identify places in your system that need to be refactored.

To learn more about Salesforce tools for technology continuity planning, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Building Backup and Restore Capabilities

Restoring backed-up copies of data or metadata can help return your org to its last known stable state. It can also provide a failover system during a catastrophic system failure or service interruption. Backing up your data and metadata regularly and storing your encrypted, backed-up copies in a secure location adds an additional layer of resilience to your architecture.

Without backup and restore strategies, you can’t restore clean versions of your production data and metadata when they’re maliciously corrupted, when defects inadvertently make their way into production, or when a failure during a large data load corrupts production data. Any one of these scenarios can result in your business-critical production data becoming corrupt or even permanently lost. Setting up backup and restore technology offers a number of advantages in addition to continuity planning, including assisting with strategies for mitigating large data volumes and adhering to compliance-related retention policies.

To help ensure continuity with backup and restore strategies in your Salesforce solutions:

- **Get started.** The first step to having a good backup and restore strategy is to have a strategy in the first place. Even something as simple as making nightly backups of all of your org’s data and metadata can save your business from losing critical information or functionality during a disaster.
- **Restrict access to backups.** System administrators are the only users who should have access to backed-up copies of your data. That access restriction prevents a business user from being able to view records in a backup copy that they wouldn’t be authorized to view in your org.
- **Test your restore process regularly.** Regardless of which backup and restore strategy you implement, [test](/docs/architect/well-architected/guide/resilient#testing-strategy) your restore process in a Full or Partial Copy sandbox regularly to be sure that it will work correctly when you need it.
- **Align your backup and restore strategy with your data archival strategy.** Determine what should happen in your backups or archives when records are archived or purged from your system. See [Data Volume](/docs/architect/well-architected/guide/reliable#data-volume)).

You may need a more granular backup strategy if your data volumes are so large that a full backup doesn’t have time to complete before the next backup starts running. You may also need a more granular backup strategy if your organization’s data changes so frequently that the updates are mission critical to your organization.

To make your backup strategy more granular:

- **Scope your backups to specific objects**. This strategy involves backing up records from different objects at different time intervals. Keep in mind that child objects must be backed up at the same intervals as their parents to maintain data consistency.
- **Time-box** **partial backups**. This strategy involves differentiating between full backups (of all data and metadata) and partial backups (of only metadata and records that have been added or changed since the last backup).

***Don’t ever stop performing full backups**. It’s important to note that you should never eliminate full backups completely, even if data volumes result in long run times. For large data volumes, plan for regular but infrequent full backups (for example, weekly backups). Also plan for more frequent partial or object-specific backups (for example, nightly backups or backups every X number of hours). This approach gives you the flexibility to reconstruct the most complete and accurate dataset to use in your restore processes.*

The [patterns and anti-patterns for continuity planning](/docs/architect/well-architected/guide/resilient#continuity-planning-patterns-and-anti-patterns) show what proper and poor backup and restore capabilities look like in a Salesforce solution. Use them to validate your designs before you build, or to identify places in your system that need to be refactored.

### Salesforce Backup and Recover

Salesforce Backup and Recover, an integrated Salesforce solution that includes Own Recover from the Own acquisition, protects important data from loss or corruption. Our highly secure, easy-to-set-up, always-available solution ensures business continuity and data resilience, and it simplifies compliance.

Use Salesforce Backup and Recover to prevent data loss, recover from data incidents quickly, and simplify your overall data management strategy. You can create backup policies for high-value and regulated data, and restore that data in just a few clicks.

#### Deploy Automated Backups

Automated daily backups protect all your crucial org data, including metadata, sandboxes, managed package data, file attachments, and more. Run backups as frequently as needed to meet your recovery point objective (RPO) goals and safeguard your deployments. Backups are always accessible and stored securely and compliantly. Continuous Data Protection is also available for even more sensitive or transactional data, allowing for faster recovery of rapidly changing, critical information.

#### Monitor Data Proactively

Detect unusual data activity, data loss, and corruption with proactive alerts that are sent directly to your email. Receive real-time alerts to identify statistical outliers or to create rules that notify you of unusual data activity, helping you detect incidents faster than ever before.

#### Restore Precisely and Swiftly

Salesforce Backup and Recover expedites recovery by providing granular visibility into changes, allowing for the quick identification and restoration of affected data. Tools such as visual graphs highlight unwanted changes, while easy-to-use recovery features precisely restore affected objects, fields, and records.

#### Extend the Use of Your Backups

Our tools enable you to use backups for analytics, audits, and compliance, offering searchable historical data, open search functionality for the visibility of past data, and export capabilities for external analytics or warehousing. This repurposes backups without needing additional Salesforce APIs.

#### Unified Backup Data Management

Backup and Recover offers a single console for consolidating all backups, management, operations, and compliance. This console allows you to access, manage, customize, and monitor backups for all your production orgs and sandboxes. With it, you can also execute data subject requests to ensure backup data compliance, and have full control to customize backup schedules, frequency, and retention policies.

#### Key Use Cases for Salesforce Backup and Recover

- **Mitigate the impact of data incidents**. Salesforce Backup and Recover helps mitigate data incidents, such as cyberattacks or malicious internal or external activity, by enabling users to revert affected records to their pre-incident state. Backup and Recover’s export functionality guarantees continuous access to and usability of users’ critical data.
- **Prevent permanent data loss**. Human error remains the leading cause of data loss. Backup and& Recover offers a precise and quick solution to these mistakes.
- **More easily meet data compliance and legal requirements**. Salesforce Backup and Recover supports the shared responsibility model, enabling self-serve functionality for the bulk forgets or data rectification in your backup data.

To learn more about Salesforce tools for backup and restore, see [Salesforce Tools for Resiliency](/docs/architect/well-architected/guide/resilient#salesforce-tools-for-resiliency).

### Continuity Planning Patterns and Anti-Patterns

This table shows a selection of patterns to look for or build in your org, and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for continuity planning in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/adaptable-continuity-planning).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Business Continuity** | **In your business:**

 - A "recovery first" mindset is adopted with a focus on bringing the highest-priority business functions and capabilities out of impact as soon as possible.
             
 - There is a maintenance schedule for the review of BCP test plans. | **In your business:**

 - A "fix the problem" mentality is the only approach to incident management.
             
 - BCP test plans aren't refreshed at regular intervals. |
| **In your documentation:**

 - A BCP exists containing steps to continue processing or triage data if Salesforce becomes unavailable, a list of events that trigger the use of the BCP, and steps and intervals for BCP testing.
         
 - The BCP includes upstream and downstream systems and dependencies. | **In your documentation:**

 - A BCP doesn't exist, isn't complete, or includes only Salesforce. |  |
| **In your test plans:**

 - The areas of your BCP related to processes and people are accounted for. | **In your test plans:**

 - The areas of your BCP related to processes and people aren't accounted for. |  |
| **Technology Continuity** | **In your business:**

 - You have evaluated if you need to build intentional redundancy or failover systems
            
 - Incident recovery tactics are automated wherever possible. | **In your business:**

 - You have not evaluated the need for intentional redundancy or fail-over systems
            
 - Incident recovery tactics are all manual. |
| **In your documentation:**

 - The BCP accounts for additional resources or break-glass procedures that teams might need to respond to incidents effectively. | **In your documentation:**

 - The BCP doesn't include operational support needs. |  |
| **Backup and Restore** | **In your documentation:**

 - A backup and restore strategy exists for both data and metadata. | **In your documentation:**

 - A backup and restore strategy doesn't exist, or if it does, is incomplete, applying to only data or only metadata, not both. |
| **At your company:**

 - Backups are stored in a secure location that only authorized users can access.
        
 - Test plans and test logs show that data restores are tested in a Full or Partial Copy sandbox at least two times each year. | **At your company:**

 - Backups aren't human readable.
            
 - Backups are stored in locations that unauthorized business users can access.
            
 - There is no data restoration process or the data restoration process is untested. |  |

## Salesforce Tools for Resiliency

| Tool | Description | Application Lifecycle Management | Incident Response | Continuity Planning |
| --- | --- | --- | --- | --- |
| [Apex Hammer Tests](https://help.salesforce.com/s/articleView?id=sf.apex_hammer_execution_status.htm&type=5) | Learn about Salesforce Apex testing in current and new releases. | X |  |  |
| [Apex Stub API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_stub_api.htm) | Build a mocking framework to streamline testing. | X |  |  |
| [Backup and Recover](https://help.salesforce.com/s/articleView?id=sf.backup_restore.htm&type=5) | Automatically generate backups to prevent data loss. |  |  | X |
| [Big Objects](https://help.salesforce.com/s/articleView?id=sf.custom_index.htm&type=5) | Store and manage large volumes of data on the platform. |  |  | X |
| [Field History Tracking](https://help.salesforce.com/s/articleView?id=tracking_field_history.htm&type=5&language=en_US) | Track and display field history. |  | X |  |
| [Get Adoption and Security Insights for Your OrganizationOpen link in new window](https://help.salesforce.com/s/articleView?id=adoption_security_metrics.htm&type=5&language=en_US) | Monitor the adoption and usage of Lightning Experience in your org. |  | X |  |
| [Manage Bulk Data Load Jobs](https://help.salesforce.com/s/articleView?id=monitoring_async_api_jobs_overview.htm&type=5&language=en_US) | Create update, or delete large volumes of records with the Bulk API. |  | X |  |
| [Manage Real-Time Event Monitoring Events](https://help.salesforce.com/s/articleView?id=event_monitoring_monitor_events_with_event_manager.htm&type=5&language=en_US) | Manage event monitoring streaming and storage settings. |  | X |  |
| [Data and Storage Resources](https://help.salesforce.com/s/articleView?id=admin_monitorresources.htm&type=5&language=en_US) | View your Salesforce org's storage limits and usage. |  | X |  |
| [Monitor Debug Logs](https://help.salesforce.com/s/articleView?id=code_monitoring_debug_logs.htm&type=5&language=en_US) | Monitor logs and set flags to trigger logging. |  | X |  |
| [Monitor Login Activity with Login Forensics](https://help.salesforce.com/s/articleView?id=event_monitoring_faq.htm&type=5&language=en_US) | Identify behavior that may indicate identity fraud. |  | X |  |
| [Monitor Setup Changes with Setup Audit Trail](https://help.salesforce.com/s/articleView?id=admin_monitorsetup.htm&type=5&language=en_US) | Track recent setup changes made by admins. |  | X |  |
| [Monitor Training History](https://help.salesforce.com/s/articleView?id=monitoring_training_history.htm&type=5&language=en_US) | View the Salesforce training classes that your users have taken. |  | X |  |
| [Monitoring Background Jobs](https://help.salesforce.com/s/articleView?id=monitoring_background_jobs.htm&type=5&language=en_US) | Monitor background jobs in your organization. |  | X |  |
| [Monitoring Scheduled Jobs](https://help.salesforce.com/s/articleView?id=data_monitoring_jobs.htm&type=5&language=en_US) | View report snapshots, scheduled Apex jobs, and dashboard refreshes. |  | X |  |
| [Scale Test](https://help.salesforce.com/s/articleView?id=sf.technical_requirements_performance_assistant.htm&type=5) | Test system performance and interpret the results. | X |  |  |
| [Proactive Monitoring](https://www.salesforce.com/services/professional-services/proactive-monitoring/) | Minimize disruptions by using Salesforce monitoring services. |  | X |  |
| [Salesforce Data Mask](https://help.salesforce.com/s/articleView?id=sf.data_mask_overview.htm&type=5) | Automatically mask data in a sandbox. | X |  |  |
| [The System Overview Page](https://help.salesforce.com/s/articleView?id=dev_force_com_system_overview_page.htm&type=5&language=en_US) | View usage data and limits for your organization. |  | X |  |
| [Use force:lightning:lint](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/intro_framework.htm) | Analyze and validate code via the Salesforce CLI. | X |  |  |

## Resources Relevant to Resilient

| Resource | Description | Application Lifecycle Management | Incident Response | Continuity Planning |
| --- | --- | --- | --- | --- |
| [7 Anti-Patterns in Performance and Scale Testing](https://medium.com/salesforce-architects/7-anti-patterns-in-performance-and-scale-testing-ba4eeda00516?source=friends_link&sk=5268a41719e7d01ba7f89f003064918f) | Avoid common anti-patterns in performance and scale testing. | X |  |  |
| [Analyze Performance & Scale Hotspots in Complex Salesforce Apps](https://developer.salesforce.com/blogs/2022/05/analyze-performance-scale-hotspots-in-complex-salesforce-apps) | Learn an approach for addressing performance and scalability issues in your org. | X |  |  |
| [Build a Disaster Recovery Plan (Trailhead)](https://trailhead.salesforce.com/en/content/learn/modules/cybersecurity-threat-prevention-and-response/build-a-disaster-recovery-plan) | Build a disaster recovery plan. |  |  | X |
| [Business Continuity is More than Backup and Restore](https://medium.com/salesforce-architects/business-continuity-is-more-than-backup-and-restore-bebe9fb9b93d) | Get a comprehensive view of BCP. |  |  | X |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization. | X |  |  |
| [Diagnostics and Monitoring tools in Salesforce](https://medium.com/salesforce-architects/diagnostics-and-monitoring-tools-for-salesforce-part-1-bfa059f9a63e?source=search_post---------3----------------------------) | Learn how to improve the quality and performance of your implementations. |  | X |  |
| [Guiding Principles for Business Continuity Planning](https://medium.com/salesforce-architects/guiding-principles-for-bcps-6871d29ee947) | Review the basic principles underlying effective BCP. |  |  | X |
| [How to Scale Test on Salesforce](https://medium.com/salesforce-architects/how-to-scale-test-on-salesforce-bf933d5948b9) | Learn the five phases of the scale testing lifecycle. | X |  |  |
| [Introduction to Performance Testing](https://developer.salesforce.com/blogs/2020/09/introduction-to-performance-testing) | Learn how to develop a performance testing method. | X |  |  |
| [Monitor Your Organization](https://help.salesforce.com/s/articleView?id=sf.monitoring_admin.htm&type=5) | Learn about self-service monitoring options. |  | X |  |
| [Test Strategy Template](/docs/architect/resources/guide/test-strategy-template) | Create and customize scale and performance test plans. | X |  |  |
| [Test Strategy Template](/docs/architect/resources/guide/test-strategy-template) | Ensure that your test strategy is complete. | X |  |  |
| [Understand Source-Driven Development (Trailhead)](https://trailhead.salesforce.com/en/content/learn/modules/sfdx_dev_model/sfdx_dev_model_sdd) | Learn about package development and scratch orgs. | X |  |  |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you'd like to see next.
