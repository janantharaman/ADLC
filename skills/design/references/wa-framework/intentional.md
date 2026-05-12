---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/intentional.html
date_fetched: 2026-05-01
section: well-architected
page_title: Intentional
---

> Read about our update scheduleshere.

## Introduction

Intentional solutions deliver business value immediately and over time. Intentional architectures are planned and delivered strategically, can be maintained effectively, and are easy for humans to read and understand.

Features and fixes are prioritized and delivered in ways that are transparent to business and technology stakeholders alike. Engineering choices create implementations that are easy for delivery and maintenance teams to work with, without added features or complications. Intentional architectures are easier to own, maintain, and evolve with the business because they follow clear and consistent implementation patterns. Builders can interpret and implement designs for new features, and maintenance teams can understand documentation of what’s been implemented.

You can create more intentional systems by focusing on three key areas: strategy, maintainability, and readability.

## Strategy

Strategy in architecture means systems are thoughtfully planned and delivered. It means delivery and maintenance teams have a clear view of the work to be done today and in the future, and everyone is aligned around the “why” of the work to be done. It means urgent requests can be triaged effectively and efficiently, and stakeholders can clearly understand the impacts and trade-offs of requests.

You can build clearer strategy into your architecture by focusing on prioritzation, roadmapping and governance.

### Prioritization

Prioritization means planning the order and scope of the work you will deliver. Prioritization involves understanding the true impact of deliverables on the business, evaluating those impacts against other work requests and the overall roadmap for your product or program.

One way to evaluate the impact of a given work item is to look at the actual cost or benefit to the business. Once you’ve identified the [KPIs](/docs/architect/well-architected/guide/automated#kpis) for the automation, you can use a [business impact calculation worksheet](/docs/architect/resources/guide/kpi-spreadsheet-template) to evaluate the overall cost or benefit of implementation. These calculations can help you get alignment and buy-in from your stakeholders about what automations to build and in what order. They can also help you identify automations to postpone or avoid. For automations, see [process design](/docs/architect/well-architected/guide/automated#process-design) for more about identifying effective work.

Establishing a prioritization framework for delivery will also help you and your maintenance teams manage user expectations and stay aligned with your roadmap.

Some considerations you can use for prioritization include:

- Business impact (cost/benefit) of the deliverable
- Amount of new work required for the deliverable
- Amount of work required to maintain the deliverable

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#strategy-patterns-and-anti-patterns) below shows what proper (and poor) prioritization looks like when it comes to Salesforce work. You can use these to validate your implementation plans, or identify where you need to better identify priorities before you build.

To learn more about tools available from Salesforce for help with prioritization, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Roadmapping

A roadmap is a prioritized, validated, well-defined view of what's to be done. Effective roadmaps provide a clear picture of the business impact and technology impact of the work ahead. Engaging your business and technical stakeholders is a key part of roadmapping. Roadmaps enable you to get feedback and buy-in about the approach and outcomes before any work begins. Ultimately, roadmaps align every stakeholder about the “why” of work ahead.

If your team uses a backlog, it's important to understand your roadmap is not a summary or list of the items in the backlog. The relationship is the opposite: Items are only to enter the backlog if they can be clearly and credibly tied to a deliverable on your roadmap. High-quality roadmaps, created with the engagement of stakeholders, provide delivery and maintenance teams with a clear view of what they should focus on and how they should prioritize requests, making it easier to sort out conflicting requests and manage stakeholder expectations.

Poor or non-existent roadmapping leads to:

- Lack of clarity around when new features and functionality will be available
- Conflicting priorities among stakeholders
- A disconnect between the solutions being delivered and the overall organizational vision
- Difficulty understanding what work is underway
- Uneven workloads across teams
- Lack of visibility into relationships and dependencies between work items
- Stalled implementations, due to mismanaged dependencies

Stakeholders often need information that aligns to their roles in order to make decisions. Creating effective roadmaps requires a clear understanding of your audience and the type of information they need. Roadmaps are categorized into two styles to support business and technical audiences. Each style contains two levels of granularity to support different types of information.

Business roadmaps help stakeholders plan for organizational change, capitalize on growth opportunities, and stay aligned on corporate objectives. Business roadmaps also provide a way to ensure that IT spend aligns to the overall business vision.

- Create a business capability roadmap to show executive stakeholders the capabilities that will be enabled. This type of roadmap contains high-level details about the capabilities themselves and how they align to business objectives, such as increasing operational efficiencies or launching a new product line.
- Create a business feature roadmap to drill into a specific capability and show its supporting features and functionality when you need to help business stakeholders with resource planning, budgeting, and change management.

Technology roadmaps help technical stakeholders with budget and resource allocation planning. They also help implementation teams understand where their projects fit as part of a bigger overall picture and identify any cross-team dependencies.

- Create a technology system roadmap to show the specific systems that will be implemented, along with any system-level dependencies. This type of roadmap shows high-level system information and the alignment between systems and business capabilities.
- Create a technology component roadmap to drill into the specific components of a system that will be deployed to help with resource planning and enablement requirements. This type of roadmap shows component-level information and implementation requirements (for example, declarative development, pro-code, and so on).

Make sure your roadmaps contain realistic timelines. A common mistake is to include only the amount of time it will take to implement a system without also considering the amount of time it will take to complete related activities. This can result in over-allocation of implementation team members and longer than anticipated delays. When creating a roadmap, account for the time it will take to complete the following:

- Documentation of all new and updated functionality
- Maintenance of existing functionality needed to support new features
- Updates to related systems required to support integrations
- Elevated support from project teams immediately after go-live
- Testing, training, and change management

Business and technology roadmaps that are well aligned communicate a holistic view of when capabilities will go live and what technology is behind them. The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#strategy-patterns-and-anti-patterns) below shows what proper (and poor) roadmaps look like for a Salesforce org. You can use these to validate or improve your roadmapping strategy.

To learn more about Salesforce tools that can help you with roadmapping, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Governance

Governance is the structure you use to handle prioritization, decision-making, and change management with your stakeholders. Governance makes it clear how decisions are made and communicated. It provides consistent ways for feedback and requests to enter into the decision-making process, and for all stakeholders to understand the status of maintenance and development work. Governance helps release management processes to be clear and consistent, and helps all team members understand their roles and responsibilities.

Without proper governance, teams will experience a variety of issues, including:

- Requests for overlapping features and functionality arrive ad hoc
- Implementation teams prioritize "easier" efforts or requests from more influential stakeholders, without proper consideration of business value, trade-offs, or overall organizational goals
- Lack of consistent approval and review processes
- Inconsistent release cadences and quality
- High defect rates, overwrites, conflicts, and redundant work in development efforts

Perhaps the clearest sign that a system doesn’t have effective governance is slow and cumbersome releases. It’s important to recognize that the size of a governance system is not a measure of its efficacy. In fact, elaborate systems for governance (like those found in many large enterprises) can throttle the speed and frequency of releases.

Good governance is about making it hard for bad customizations to get past the early stages of development, and getting good customizations into production predictably and consistently.

Too often, governance efforts are reactionary. They are initiated or redoubled when an issue, such as excessive technical debt, starts becoming a business problem. In many cases, the unfortunate response is for the business to “lock down” development efforts and releases, instead of creating effective [design standards](/docs/architect/resources/guide/design-standards-template) and building automation to enforce those standards within developer tool chains and source control systems.

When building the framework for your Salesforce governance system include the following elements and consider these key questions to be answered:

- **Work requests.** How can users ask for functionality or features? How are bugs reported?
- **Prioritization and work planning.** Who decides what work requests matter? How is work scoped, prioritized, and accepted or signed off on?
- **Environments and release planning.** What is the environment pipeline for development, testing, and release? Who does what to provision, refresh, and provide access? Who handles deployments and validation? How and when are changes released? How do you handle deployments or environments during a Salesforce release cycle? (For more on this, see [Application Lifecycle Management](/docs/architect/well-architected/guide/resilient#application-lifecycle-management).)
- **Service ownership and production support.** Who supports what? Who handles “hot-fix” production issues? How are those items tested and released? Who is responsible for the overall security standards of the org?

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#strategy-patterns-and-anti-patterns) below shows what proper (and poor) governance looks like for a Salesforce org. You can use these to validate or improve your governance strategy.

To learn more about Salesforce tools available for governance, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Strategy Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for strategy in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-strategy).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Prioritization** | **Within your documentation:**

 - All new work items have clear business value metrics (for example, revenue increases, cost savings from process optimizations, and so on)
            
 - Roadmaps show work prioritized based on business value | **Within your documentation:**

 - Business value associated with work is unclear or nonexistent
            
 - Roadmaps don't exist |
| **Within your company:**

 - Implementation and maintenance costs have been identified for all work items
            
 - Requests for features are prioritized based on business impact, amount of new work required to deliver, and amount of work required to maintain | **Within your company:**

 - Costs associated with implementing and maintaining features are unclear
            
 - Requests are delivered on an ad hoc or first-in/first-out basis |  |
| **Roadmapping** | **Roadmaps:**

 - Communicate information that's tailored to your audience (business or technical)
            
 - Communicate information at the correct level of detail
            
 - Show start and end dates
            
 - Show prerequisites and dependencies | **Roadmaps (if they exist):**

 - Are used as project kickoff materials and not artifacts for delivery
            
 - Do not help align stakeholders and delivery teams
            
 - Mix levels of detail (for example, by including systems and components within the same roadmap)
            
 - Contain information that isn't tailored to their audience (for example, business capabilities and systems within the same roadmap) |
| **Within your business:**

 - Stakeholders understand the "why" of work items
            
 - Delivery teams know how to evaluate backlog items against longer term priorities
            
 - Teams know who's doing what and how to manage dependencies
            
 - Work is intentional, even when priorities have to change quickly | **Within your business:**

 - Work is pulled from whatever is in the backlog and there is no clear “why"
            
 - Teams have trouble coordinating interdependent work and often replicate work without realizing it
            
 - Work is often reactive
            
 - Stakeholders often feel frustrated and confused about what's being done and are usure when new capabilities will be delivered |  |
| **Governance** | **Within your business:**

 - Users can easily report bugs and request features
            
 - The prioritization process for work items is documented and transparent to all stakeholders
            
 - Environment strategy is clearly documented and development environments match the documentation
            
 - Release planning is predictable and transparent to all delivery team members
            
 - Team members know who's responsible for what throughout app lifecycle
            
 - Releases are clear to users and delivery/maintenance teams
            
 - Production support processes are clear and hot-fixes have a clear path to production
            
 - Teams and projects only use AI models approved for business uses | **Within your business:**

 - Bug reports and feature requests are ad hoc
            
 - Work items have no clear prioritization
            
 - Environments are provisioned ad hoc and may not be refreshed predictably; developers often do not have the environments and access they need
            
 - Releases are unpredictable for delivery teams and users
            
 - Teams do not know who is responsible for what
            
 - Hot-fixes are addressed ad hoc
            
 - Your backlog has become an “idea bank” that is stale and stagnant
            
 - Governance bodies act as a help desk that troubleshoots support requests
            
 - Documentation is not easily accessible
            
 - Teams select AI models ad hoc |

## Maintainability

Maintainability means a system can be kept in a healthy state, with new features moving into and technical debt moving out of the system on a regular, predictable basis. Maintainable systems enable your teams to deliver value to the business with predictable speed and quality. The maintainability of a system depends on several factors, including how readable it is, how loosely coupled it is, and how thorough its testing strategy is.

Most importantly, the maintainability of a system depends on the straightforwardness of its design. This section covers ways to create more straightforward solution designs, and increase maintainability.

You can build solutions that are easier to maintain by focusing on two keys: using standard over custom functionality and handling technical debt.

### Standard Versus Custom Functionality

Salesforce offers a range of prebuilt solutions — Sales Cloud, Service Cloud, and many Salesforce industry solutions — as well as the flexibility to create your own custom solutions. The foundational services that power Salesforce’s own cloud solutions are also available to any custom solutions built on the Salesforce Customer 360 Platform. Use the prebuilt services and solutions from Salesforce as a trusted foundation for as many of your solutions as possible.

Using prebuilt platform services has two distinct benefits. First, your apps naturally benefit from the latest Salesforce innovations with every release. And second, your development teams can focus on expanding and deepening the business capabilities provided by your Salesforce solutions rather than handling basic architectural heavy lifting.

Properly choosing when to use standard functionality and when to build custom functionality isn’t challenging from an architectural point of view. The keys are:

- **Customizing the platform means modifying and extending, not copying**. As you design or evaluate your architecture, you should ask: Does this already exist somewhere in the Salesforce platform? If the answer is “*Yes, but...[insert changes a business stakeholder wants here...]”*, then use the prebuilt feature in the platform. The architectural work to be done is identifying the most useful ways to configure the prebuilt Salesforce feature to meet business expectations.
- **No customizations are trivial**. Over time, every change has consequences. If you need to implement a custom solution, you can mitigate the inevitable [technical debt](/docs/architect/well-architected/guide/intentional#technical-debt) your system will accrue by choosing to use low-code technology whenever possible, and by creating [composable units](/docs/architect/well-architected/guide/composable) in your implementations.
- **Consider the build-buy spectrum**. The [Salesforce AppExchange](https://appexchange.salesforce.com/) is a marketplace of apps and solutions to extend Salesforce. AppExchange apps can deliver functionality without the overhead involved in building and maintaining a custom solution. Consider the following when evaluating AppExchange solutions:

Identify solution features and gaps. Ideally, you’ll find an app that meets all of your business requirements. In reality, you may not find a perfect fit. As you assess solutions, map functionality in the potential solution to a prioritized list of business requirements. This will help you find the solution that best meets your most critical requirements.
Use sandboxes and free trials. Use free trial periods to evaluate apps in sandbox environments and identify the best fit. Determine if apps will require you to make configuration changes that conflict with your existing configuration.
Consider near-term and long-term costs. Evaluate long-term app maintenance savings against the recurring costs of subscription-based apps. Avoid scenarios where you have to pay recurring costs for lots of functionality your business stakeholders will never use.
- **Use the prebuilt data models from Salesforce.** Salesforce provides prebuilt data models for Sales, Service, and a variety of industry verticals. Using the data models provided by Salesforce ensures capabilities in your system are defined only once (eliminating redundancy and silos), establishes a single source of truth across the entire system, makes it easier to understand application data with analytics, makes it easier to use Salesforce’s prebuilt artificial intelligence services, lowers maintenance costs (by reducing customizations you need to support), and reduces technical debt.

It is that simple. As you can see in the [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#maintainability-patterns-and-anti-patterns) below, the anti-patterns boil down to replicating standard features in a custom solution, or using more complex technology to deliver customizations.

In practice, you may encounter a scenario in which a custom functionality anti-pattern is viewed by business stakeholders as the best or only viable way forward. In these instances, it is essential that you explain to the stakeholders the trade-offs involved in choosing this path and then thoroughly document the decision, its rationale, and its implementation. This is also an area where delivering core value early and adapting over time can help your stakeholders better understand the best way forward.

To learn more about Salesforce tools that can help you increase maintainability, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Technical Debt

Technical debt is a natural part of any system. Yesterday’s sound designs can become anti-patterns when technology or business needs change. Maybe something built to fill a gap in Salesforce platform functionality suddenly becomes redundant with a new Salesforce release or product launch. Perhaps a more performant or flexible technology supersedes a technology you’ve already implemented. Technical debt can be created in many ways.

A key benefit of building applications with the Salesforce Customer 360 Platform is the [backwards compatibility built into the platform](/docs/architect/fundamentals/guide/architecture-basics#platform-apis). This means that new platform innovations may change the pattern you should use for solutions moving forward, but the everyday function of solutions you’ve built on previous Salesforce technologies will continue to work. Over time, any solution based on older technology will begin to pose risks or bottlenecks for adding new features into your apps, and lower overall solution health.

Planning for and carrying out regular work to address technical debt is essential to maintaining healthy, straightforward designs in a Salesforce solution. Failing to plan for, audit for, and remediate technical debt is a sure way to create a system that is poorly architected.

One way to minimize technical debt is to avoid introducing it as much as possible, by avoiding shortcuts and by preferring [standard functionality over custom functionality](/docs/architect/well-architected/guide/intentional#standard-versus-custom-functionality). Shortcuts, like hard-coding values, may be tempting to save time, but in the long-term they create debt that must be repaid.

The keys to addressing technical debt from an architectural perspective include:

- Identifying the actual [cost or benefits to the business](/docs/architect/resources/guide/kpi-spreadsheet-template) of action versus inaction
- Proper [roadmapping](/docs/architect/well-architected/guide/intentional#roadmapping)
- Building [composable solutions](/docs/architect/well-architected/guide/composable)

The difficulty can be getting stakeholders aligned with taking action. Some stakeholders may perceive on-going maintenance as addressing “yesterday’s mistakes” or taking away from the features they want their budget to support.

Showing the real business impacts of action and inaction, along with clearly defined deliverables and timelines can help your stakeholders understand the value and relative priority of addressing technical debt. Consistently doing the work to connect technical debt to business impacts won’t just help your stakeholders to better understand the work to be done. It will also help you ensure you’re identifying and addressing technical debt in ways that truly benefit users.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#maintainability-patterns-and-anti-patterns) below shows what proper (and poor) technical debt management looks like for a Salesforce org.

To learn more about Salesforce tools that can help you with technical debt, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Maintainability Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for maintainability in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-maintainability).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Standard vs. Custom** | **In your design standards:**

 - There is a clear guiding principle to keep solutions from unnecessary customization
            
 - The guiding principle for solutions uses the following priority: 1. Use built-in platform services, 2. Consider AppExchange apps before building a custom solution, 3. Use low-code customizations before writing code | **In your design standards:**

 - Design standards either don't exist or don't have a clear rationale for avoiding unneeded customizations and code |
| **In your documentation:**

 - Decision records show calculation for near- and long-term costs when choosing to build or buy solutions | **In your documentation:**

 - Decision records do not consider both near- and long-term costs when choosing to build or buy solutions |  |
| **In data models:**

 - No objects have names or functionality that duplicates standard objects
            
 - Standard objects are not used for purposes that are far outside their intended scope | **In data models:**

 - Objects duplicate the names and/or functionality of standard objects
            
 - Standard objects are used for purposes far outside their intended scope |  |
| **In LWC, Aura, or Visualforce:**

 - No code exists to override standard page view mechanisms | **In LWC, Aura, or Visualforce:**

 - Code exists to override standard page view mechanisms, often in the form of a single page app |  |
| **In LWC, Aura, or Apex:**

 - No code attempts to override or circumvent the platform order of execution | **In LWC, Aura, or Apex:**

 - Code attempts to override or circumvent the platform order of execution |  |
| **Technical Debt** | **In your roadmap:**

 - Work to address tech debt is planned
            
 - Deliverables and begin/end dates are clear | **In your roadmap:**

 - No work to address tech debt is planned
            
 - Deliverables are vague; begin/end dates are unclear |
| **In your decision records:**

 - KPIs for pre-/post- tech debt remediation are clearly documented
            
 - Trade-off discussions for action and inaction focus on business costs or benefits | **In your decision records:**

 - Tech debt remediation has no measurable KPIs
            
 - Tech debt is considered in technical or IT-focused terms, with no relevance to the business |  |
| **In your org:**

 - No unsupported or legacy technology is active, including:
            
 -- All users work in Lightning Experience
            
 -- no or very few uses of `@future` in Apex (Queueable is used)
            
 -- All third-party Apex belongs to AppExchange packages
            
 -- no active Workflow Rules (Flow is used)
            
 -- no active Process Builder processes (Flow is used)
            
 -- PushTopic Events (Change Data Capture is used)
            
 -- Generic Events (Platform Events are used)
            
 -- API versions prior to 30.0
            
 -- Salesforce org connections use Cross-Org Adapter for Salesforce Connect | **In your org:**

 - Unsupported or legacy technology is active, including:
            
 -- Users working in Salesforce Classic
            
 -- `@future` usage in Apex
            
 -- Third-party Apex from non-AppExchange sources
            
 -- Workflow Rules
            
 -- Process Builder processes
            
 -- PushTopic Events
            
 -- Generic Events
            
 -- API versions prior to 30.0
            
 -- Salesforce to Salesforce connections |  |

## Readability

At its core, the concept of *readability* is about creating consistency that makes it easy for people to understand how things work. Building readable systems aligns delivery and maintenance teams, and helps people who are unfamiliar with the system quickly understand how pieces fit together. It means your team can be less dependent on individual people with institutional or historical knowledge to effectively onboard vendors or new team members. It means skilled individuals on a team can focus on the quality and trade-offs of the choices being made, because the system’s configuration and code are easy for humans to read and understand. Readability can speed up governance and quality assurance processes, and help teams better identify when they might be creating redundant customizations. It can also boost the chances of having a system that behaves in ways that are reusable and testable.

You can increase readability via effective design standards and documentation.

### Design Standards

[Design standards](/docs/architect/resources/guide/design-standards-template) provide guidance to keep all customizations consistent, even at the earliest stages of development. Design standards act like guardrails, keeping all delivery teams and maintenance teams working on your system aligned on how to approach and implement customizations. Defining design standards helps boost the productivity of your delivery and maintenance teams, makes code and architectural reviews easier to conduct, and provides a basis for better [documentation](/docs/architect/well-architected/guide/intentional#documentation).

Without design standards, teams are more likely to work in silos. Without the coherence that design standards provide, businesses will find themselves struggling with:

- Vendors and development teams using ad hoc patterns and approaches across solutions, potentially introducing anti-patterns and reducing reusability (see [Separation of Concerns](/docs/architect/well-architected/guide/composable#separation-of-concerns)).
- Increased time to resolve production issues, and support teams required to onboard new team members and help them understand a disparate set of patterns and approaches.
- Poor cross-team collaboration, redundancies in work across teams, time lost resolving conflicts, and bugs discovered during integration testing.
- Increased frustration and higher turnover rates.

A key benefit of design standards stems from the conversations and decisions stakeholders must make to create them. Specifically, the process gives your business and technology leads the opportunity to align around what optimal design looks like for your business.

Include the following in your [design standards](/docs/architect/resources/guide/design-standards-template)

- **Naming conventions for Salesforce metadata**. Define a set of conventions for how every customization in a system is to be named. Good naming conventions don’t just enforce consistency across the names of objects, fields, code, flows, and other elements of your system. Good naming conventions also help development teams to use names that convey information about the purpose and functionality of what they’re building. As a result, other stakeholders can better understand a particular customization, just by seeing its name.
- **Approved design patterns and their use cases**. Establish a library of [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/patterns), along with key information about when (and when not) to use each pattern. The library might include required Apex trigger patterns, or flow orchestration patterns based on the [composability](/docs/architect/well-architected/guide/composable) you want in your system.
- **Development environment and tool guidance**. Maintain a clear list of the tools development teams are to use for their work. This could include approved tool chains and languages for anyone writing code, or declarative features that are (or are not) approved for low-code development. Your standards might include a list of source control systems for customization and documentation, and required check-in/check-out steps. They might also include a list of environments to be used for different kinds of development work.

Along with defining these standards, you’ll need to decide how and where to maintain and store them. If teams across your company can’t find your design standards (or aren’t even aware they exist), they won’t be effective. Ideally, your design standards live within the same system as your documentation (see the next section for more).

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#readability-patterns-and-anti-patterns) below shows what proper (and poor) design standards look like for a Salesforce org. You can use these to validate or improve your design standards.

To learn more about Salesforce tools that can help you define design standards, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Documentation

Documentation explains the what, how, and why of your system. Without meaningful and consistent documentation, teams waste a lot of time trying to understand the system as it is (and potentially misunderstanding features and customizations).

Good documentation takes time to create. While most teams agree that documentation is important for large projects, it can be a tempting step to skip when making quick changes like configuration updates or minor tweaks to an automation. Not documenting the changes you make to your system is always an anti-pattern. Skipping documentation may save a small amount of time upfront, but the amount of time required to troubleshoot an org that isn’t properly documented will more than cancel out those time savings. Always include enough time to create documentation in all of your estimates, regardless of the level of effort required for the updates you’re planning to make.

The lack of clear documentation can lead to a variety of problems, including:

- Development cycles spent on reworking existing implementations
- Repetitive discussions revisiting or puzzling over previous decisions
- Longer onboarding for new team members or vendors
- Over-dependence on individuals with institutional or historical knowledge
- Redundant architectures to support the same or similar capabilities across the business
- Difficulty in communicating the purpose and value of your solution to key stakeholders

For Salesforce solutions, maintain documentation for:

- **Solution overviews**. [Diagrams](/docs/architect/reference-diagrams/guide/introduction) enable you and your stakeholders to visualize solutions at various levels of detail. The Salesforce diagram framework helps you create diagrams that show the business capabilities of solutions, as well as technical implementation details.
- **Decision records**. Keep a record of the options considered, trade-offs, final decision, and reasoning in a central location that all team members can access for future reference.
- **Code**. The format of code itself is a key piece of documentation, and this can (and should) align with your [design standards](/docs/architect/well-architected/guide/intentional#design-standards). You will also want to have a log of key information, and update it with every modification of a piece of code. For all classes, triggers, and components, document the following:

Who authored the code
When the code was written
What the code is supposed to do
Key dependencies
All changes
- **Declarative customization**. For every kind of customization that can be made to the metadata in your org, Salesforce provides [built-in attributes](/docs/architect/fundamentals/guide/platform-multitenant-architecture#browser-based-no-code-and-low-code-application-development) for teams to provide helpful information about the purpose and intent of the metadata. As part of your design standards, include how teams are to use these built-in features and how they are to name declarative customizations. Also maintain a log of key information that is identical to what you use for code.

Develop a set of documentation standards to ensure that all current and future team members will be able to interpret documents the same way. ([design standards](/docs/architect/resources/guide/design-standards-template) can help with this.) It’s also important to consider how users will be able to search documentation to find relevant sections or terms. As your system ages and grows in complexity, your documentation will also grow. The usefulness of the information in your documentation will be directly related to how often, how quickly, and how easily users can search for and find relevant items.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/intentional#readability-patterns-and-anti-patterns) below shows what proper (and poor) documentation looks like for a Salesforce org. You can use these to validate or improve your documentation strategy.

To learn more about Salesforce tools for documentation, see [Tools Relevant to Intentional](/docs/architect/well-architected/guide/intentional#tools-relevant-to-intentional).

### Readability Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for readability in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-readability).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Design Standards** | **In your org:**

 - Code and declarative customizations have consistent, human-readable names
            
 - Data models have consistent, uniform names for objects and fields
            
 - Audits show fields are consistently filled out and referenced in reports, etc. | **In your org:**

 - Code and declarative customizations do not have consistent names
            
 - Data models have inconsistent names and many objects and fields seem to be redundant
            
 - Audits show many unused fields or various levels of usage, and there is no consistent link to reporting, etc. |
| **Within your business:**

 - Teams know what tools to use (and not use) to get work done
            
 - Approved design patterns are easy to find and identify by use case
            
 - Approved AI models are clearly identified and include an intended purpose | **Within your business:**

 - Teams use many different tools to get similar work done
            
 - There are no approved design patterns
            
 - It takes a lot of time for vendors or new employees to onboard
            
 - Approved AI models are not clearly identified, and their intended purpose is unclear |  |
| **Documentation** | **In your org:**

 - Code and declarative customizations have clear descriptions | **In your org:**

 - Code and declarative customizations do not have descriptions, have descriptions that are difficult to understand, or have descriptions that don't seem to match what the customization is actually doing |
| **Within your business:**

 - Diagrams for business capabilities and technical implementation details exist for all solutions
            
 - Key who/when/what information logs exist for code and declarative customizations
            
 - People can search for and find relevant documentation | **Within your business:**

 - The what/how/why of solutions is hard to find and may be unavailable to most teams
            
 - People struggle to understand solutions and the system they are working with
            
 - It takes a lot of time for vendors or new employees to onboard |  |

## Tools Relevant to Intentional

| Tool | Description | Strategy | Maintainability | Readability |
| --- | --- | --- | --- | --- |
| [ApexDoc](https://github.com/SalesforceFoundation/ApexDoc) | Document Apex with static HTML pages |  | X | X |
| [Bulk Delete Inactive Picklist Values](https://help.salesforce.com/s/articleView?id=sf.fields_picklist_delete_inactive_values.htm&language=en_US&type=5&_ga=2.216886358.1142927923.1683068265-1808100124.1682614163) | Delete inactive unused values from picklists |  | X |  |
| [Lightning Design System Validator](https://www.lightningdesignsystem.com/tools/validator/) | Validate markup and see how to improve your code |  | X | X |
| [Migrate to Flow](https://help.salesforce.com/s/articleView?id=release-notes.rn_automate_flow_mgmt_migrate_to_flow_tool.htm&type=5&release=242&_ga=2.180751207.1142927923.1683068265-1808100124.1682614163) | Convert Workflow Rules and Process Builder processes into flows |  | X |  |
| [Project Management Tool by Salesforce Labs](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3u00000MRsKnEAL) | Manage projects within your Salesforce Org | X | X |  |
| [Salesforce Extensions for Visual Studio Code (Expanded)](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-expanded) | Analyze Salesforce code efficiently with Visual Studio Code Extensions |  | X | X |
| [Org Check](https://sfdc.co/OrgCheck) | Quickly analyze your org and its technical debt |  | X |  |
| [Salesforce Code Analyzer](https://github.com/forcedotcom/code-analyzer) | Scan code via IDE, CLI or CI/CD to ensure it adheres to best practices |  | X | X |
| [Salesforce Roadmap Explorer](https://architect.salesforce.com/roadmaps/roadmap-explorer) | Explore Salesforce product innovations | X |  |  |
| [Setup Audit Trail](https://help.salesforce.com/s/articleView?id=sf.admin_monitorsetup.htm&type=5) | Track setup changes and audit history | X | X |  |

## Resources Relevant to Intentional

| Resource | Description | Strategy | Maintainability | Readability |
| --- | --- | --- | --- | --- |
| [5 Documentation Strategies to Improve Your Salesforce Org](https://www.salesforce.com/blog/documentation-strategies-to-improve-your-salesforce-org/) | Improve Salesforce implementation documentation | X |  |  |
| [Choose Naming Conventions (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/success-cloud-coding-conventions/choose-naming-conventions-sc) | Learn how to apply naming conventions |  |  | X |
| [Defining, Identifying, and Measuring Technical Debt](https://medium.com/salesforce-architects/defining-identifying-and-measuring-technical-debt-5f783e2b381d) | Define, identify and measure technical debt | X | X |  |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization | X | X | X |
| [Get Started with Salesforce Diagrams](/diagrams) | Learn how to create the right diagram for your use case |  |  | X |
| [Getting Started with Coding Conventions (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/success-cloud-coding-conventions/get-started-with-coding-conventions-sc) | Define and follow coding conventions |  |  | X |
| [How to Tackle Technical Debt (Trailhead)](https://trailhead.salesforce.com/trailblazer-community/download/file/0693A000006PskRQAS) | Manage technical debt in your Salesforce org | X | X |  |
| [Improve Your Apex Code (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/success-cloud-coding-conventions/improve-your-apex-code-sc) | Apply basic principles of test-driven development |  |  | X |
| [Organizational Alignment (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/manage_the_sfdc_organizational_alignment_v2mom?trailmix_creator_id=strailhead&trailmix_slug=prepare-for-your-strategy-designer-credential) | Learn the V2MOM process for alignment | X |  |  |
| [Prioritizing and Planning a Way Out of Technical Debt](https://medium.com/salesforce-architects/prioritizing-and-planning-a-way-out-of-technical-debt-6f18fbb2b007) | Form a plan to reduce and remove technical debt | X | X |  |
| [Salesforce Naming Conventions Template](https://salesforce.quip.com/MW5cAPVwat8k#JCIACA8Q963) | Get started with naming conventions |  | X | X |
| [Technical Debt: What Is It and Why Should You Care? ](https://admin.salesforce.com/blog/2021/tech-debt-what-it-is-and-why-you-should-care) | Understand the impact of technical debt in your org |  | X |  |
| [Using the Business Model Canvas in Enterprise Architecture](https://medium.com/salesforce-architects/using-the-business-model-canvas-in-enterprise-architecture-5c136803a99d) | Create, deliver, and see value in a business model | X |  |  |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you’d like to see next.
