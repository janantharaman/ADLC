---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/automated.html
date_fetched: 2026-05-01
section: well-architected
page_title: Automated
---

> Read about our update scheduleshere.

## Introduction

Systems demonstrate automated behavior by enabling the business to meet key goals and objectives faster and at scale. Healthy automation enables users to focus on high-value work and reduces time spent on repetitive, manual tasks or complex data entry.

Most often, automation means translating business processes from one form to another: from paper-based form to digital form, from an old system to a new one. With every business process translation comes an opportunity for transformation.

Transformation is not about using new technologies to introduce disruptive and confusing changes for users. Transformation is about creating simpler ways for work to get done, enabling business to grow without friction, and empowering business users to focus more deeply on what really matters to their stakeholders. From an architectural point of view, this involves identifying tasks that can be eliminated altogether, or handled automatically. It requires a clear connection between how technology is used and its measurable impact on the business.

Something important to note about automation with Salesforce: it can be done with a variety of tools, using programmatic and declarative skill sets. Designing automations that are well-architected is not about choosing to build with just one automation tool. It is about using approaches that are consistent and predictable, and enabling teams to develop, test, deploy, and maintain the automations you design. Your automations should take the most [maintainable and readable](/docs/architect/well-architected/guide/intentional) form possible.

This section covers how to design and refactor automations to enable businesses to meet key objectives faster and at scale. You can improve the architecture of your automations in Salesforce by focusing on efficiency and data integrity.

## Efficiency

Creating efficiency in your automations isn’t about dutifully re-creating business as usual with Salesforce technologies. It’s about deeply understanding the key metrics and business outcomes that teams will be accountable for meeting or tracking, and stepping back to see [functional units](/docs/architect/well-architected/guide/composable#functional-units) within and across the work that you’re automating. It’s about identifying how you can create patterns with your automations that enable the business to operate more effectively and quickly, at scale.

Efficient automation logic will make your systems:

- More scalable and valuable for the business
- More helpful for users
- More [adaptable](/docs/architect/well-architected/guide/adaptable-overview) and able to meet evolving business needs

You can improve efficiency in your automations through process design and operational logic.

### Process Design

Process design involves defining the ways work gets done. Building truly efficient and effective processes means your designs do not just replicate current ways of working. Identifying and removing ineffective or unclear steps is essential. Optimized processes should create measurable business value (see [KPIs](/docs/architect/well-architected/guide/automated#kpis)) without unnecessary steps. Unclear or unnecessary steps will likely create technical debt and result in unmaintainable automations.

Often, the responsibility for discovering and documenting business processes will fall under the responsibility of a business analyst or even a system administrator. Architects are responsible for partnering with these members of your team to make sure your process designs are technically sound and well structured. Applying your knowledge of the Salesforce platform as early as possible will help your team identify processes to streamline through automation or processes that need to change to avoid costly customizations.

To build optimized processes for Salesforce, consider:

- Define processes thoroughly. Processes with unclear purposes or ambiguous definitions are more likely to be misinterpreted at design-time. This will lead to flawed designs that are based on assumptions, which will result in incorrect or inefficient automations. Ensure the business processes you want to automate meet the following standards:

Scoped to a single, specific function (see Functional Units)
Has clearly defined, measurable outputs (see Business Value)
Has clearly defined inputs and outputs
- Make process steps clear.* While it can sometimes be tempting to add additional steps that “might be helpful in the future”, this is never a good approach. Every step in an automation be relevant to the outcome of the overall process. Ensure each process step has the following characteristics:

Performs a specific, granular task (See composable)
Required for the process to generate its defined output (remove all non-essential steps)
Can be completed using a minimal number of resources
Makes use of existing system data instead of asking for user inputs where possible (See engaging)
Provides input options that users can understand without having to know how the underlying systems work (See helpful)

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/automated#efficiency-patterns-and-anti-patterns) below shows what proper (and poor) optimization looks like in a Salesforce org. You can use these to validate your automation designs before you build, or identify automations that need to be optimized further.

To learn more about process automation tools available from Salesforce, see [Tools Relevant to Automated](/docs/architect/well-architected/guide/automated#tools-relevant-to-automated).

### Operational Logic

Operational logic deals with how effectively a process is translated from its design into an actual implementation. Automations with strong operational logic continue to perform well, regardless of spikes in transaction volumes or the number of concurrent instances that are running. Logically sound automations help businesses to more easily scale to operate at higher levels of demand. Building strong operational logic into your automations is directly related to the overall [reliability](/docs/architect/well-architected/guide/reliable) of your system.

Automations that do not operate effectively provide poor user and customer experiences, leading to both potential revenue losses and loss of customer trust. They also have higher maintenance costs and can become bottlenecks that delay related processes, contributing to overall system performance issues.

To create effective operational logic in automations, consider:

- **Ensure everyone creating automations knows the right way to do it**. Poor design choices can be made with any kind of automation tool. Code is no less prone to errors or poor implementation choices than click-based tools. The use of hard-coded reference IDs, for example, is an anti-pattern that appears in both Flow and code. Click-based tools should not be viewed as a license to allow anyone and everyone to release an automation into production. Every team member who creates an automation needs to know how to build it the right way. See [readability](/docs/architect/well-architected/guide/intentional#readability) and [design standards](/docs/architect/well-architected/guide/intentional#design-standards) for more about how to define and apply effective standards across your systems.
- **Clearly document all execution paths**. Increased usage of automations does not only increase potential data volumes, it also increases unplanned invocation contexts. You need to understand how different automations can be invoked, and ensure proper transaction controls (see data handling) appear in all automations that have multiple entry points. For example, screen flows won’t run with bulk data loads, but Apex triggers and triggered (and autolaunched) flows probably will. Clearly documenting planned and potential execution paths for automations is a key aspect of understanding what logical conditions you will need to accomodate during implementation.
- **“Bulkify” all data operations (including SOQL)**. Every data operation (insert, update, and so on) should be carried out against collections. Always. Without exceptions. This is what is meant by “bulkifying” operations. Though the platform can support singleton data operations, you should never allow singleton patterns to be implemented.
- **Use SOSL for search operations**. There is a misconception that data operations cannot be carried out against records returned via SOSL. It is true that DML cannot be invoked directly against SOSL results, but code can parse SOSL results and create a collection that can be referenced in DML or Database class methods. The key differences between SOSL and SOQL are the return types for each and how they respond to generalized or wildcard searches. SOSL can work against several sObject types (which is why the return type is different) and it can handle wildcard and generalized string searches with better performance than SOQL.
- **Treat SOQL like a data operation**. Don’t use SOQL to find records — use it to refine your data operations. SOQL and data operations can have very similar impact on the performance of the [underlying relational database](/docs/architect/fundamentals/guide/platform-multitenant-architecture#the-platform-data-layer). SOQL can even pass [an explicit DML indicator](https://developer.salesforce.com/docs/atlas.en-us.238.0.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_update.htm?q=for%20update) that will lock database rows in anticipation of data operations. To create scalable automations, make sure you treat SOQL with similar due diligence: don’t use it without very specific, well-formed selection criteria, do not allow extraneous field references, and require careful data type matching between fields and filter inputs in `WHERE` statement logic. Your code should also have proper controls to ensure a query will never run in non-bulkified contexts or against null or blank filter criteria.
- **Keep synchronous operations strictly focused on work that helps a user in real time**. During your [process optimization](/docs/architect/well-architected/guide/automated#process-design), identify logic that is relevant to what users need done in real time or near real time and what can be deferred into an asynchronous (async) transaction. See [Data Handling](/docs/architect/well-architected/guide/automated#data-handling) for more considerations about designing sync/async operations.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/automated#efficiency-patterns-and-anti-patterns) below shows what proper (and poor) operational logic looks like in Salesforce automation. You can use these to validate your automation designs before you build, or identify automations that need to be optimized further.

To learn more about tools available from Salesforce that can help you plan for scale, see [Tools Relevant to Automated](/docs/architect/well-architected/guide/automated#tools-relevant-to-automated).

### KPIs

Automation KPIs measure the impact of an automation over time. Without them, you’ll have no way to tell if an automation is truly adding business value or creating unintended complexity for your users. Every automation you build should be tied to a clear, measurable set of KPIs.

Good KPIs are defined by a measurable value along with an associated time frame. Examples include:

- [X number] working hours saved per month
- Processing failures from manual data entry reduced by [Y%] per week

Once you have clear, measurable KPIs, you have to also understand if and how an automation in Salesforce will generate data that is relevant to reporting against those KPIs.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/automated#efficiency-patterns-and-anti-patterns) below shows what proper (and poor) KPIs look like when it comes to Salesforce automations. You can use these to validate your existing KPIs, or identify where you need to better identify KPIs before you build.

To learn more about tools available from Salesforce for help with KPIs, see [Tools Relevant to Automated](/docs/architect/well-architected/guide/automated#tools-relevant-to-automated).

### Efficiency Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for efficiency in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-efficiency).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Process Design** | **In your org:**

 - Each flow serves a single, specific purpose
            
 - Each step performs a specific, granular task
            
 - Flows are organized in a hierarchical structure consisting of a main flow and supporting subflows
            
 - All user inputs have a clear purpose within the flow
            
 - Users are only asked to provide data when existing system data can’t be used | **In your org:**

 - Flows serve multiple purposes and require additional inputs to provide context
            
 - Flows require inputs whose data is not used
            
 - Groups of related steps contain functionality that overlaps with groups of steps in other flows
            
 - Flows ask for user inputs when stored data can be used instead |
| **In Apex:**

 - Each class serves a single, specific purpose
            
 - Each method performs a specific, granular task
            
 - All input variables have a clear purpose within the class
 - Code execution requires a minimal number of resources | **In Apex:**

 - Classes serve multiple purposes
            
 - Methods perform multiple tasks or methods perform tasks that don’t align to the stated purpose of the class they’re part of
            
 - Input variables aren’t actually used in methods
            
 - Methods unnecessarily retrieve data from the database or from external systems |  |
| **Operational Logic** | **In Flow:**

 - No variables refer to hard-coded values (for record types, users, etc.)
            
 - All autolaunched flows and processes use decision and/or pause elements to evaluate entry criteria and prevent infinite loops or executions against large data volumes
            
 - Flows (including processes) hand logic off to Apex in large data volume contexts
            
 - Subflows are used for the sections of a processes that need to be reused across the business | **In Flow:**

 - Variables have hard-coded values
            
 - Flows (including processes) must be manually deactivated prior to bulk data loads
            
 - Flows (including processes) trigger "unhandled exception" notices
            
 - Even simple flows regularly cause errors related to governor limits
            
 - Portions of a flow are repeated across flows rather than using subflows |
| **In Apex:**

 - No variables refer to hard-coded values (for record types, users, etc.)
            
 - All wildcard criteria appear in SOSL
            
 - SOQL is wrapped in `try-catch`

 - No SOQL appears within a loop
            
 - SOQL statements are selective, including:
                
 -- no usage of `LIKE` comparisons or partial text comparisons
                
 -- comparision operators use positive logic (i.e. `INCLUDES`, `IN`) as primary or only logic
                
 -- usage of `= NULL`, `!= NULL` is rare and/or always follows a positive comparision operator
                
 -- no `LIMIT 1` statements appear
                
 -- no usage of `ALL ROWS` keyword | **In Apex:**

 - Variables have hard-coded values
            
 - SOSL is rarely or not consistently used for wildcard selection criteria
            
 - SOQL is not wrapped in `try-catch`

 - SOQL appears within loops
            
 - SOQL statements are non-selective, including:
                
 -- `LIKE` and wildcard filter criteria appear
                
 -- comparisons using `NOT`, `NOT IN` criteria are used as the primary or only comparison operator
                
 -- `= NULL`, `!= NULL` criteria are used as the primary or only comparison operator
                
 -- `LIMIT 1` statements appear
                
 -- `ALL ROWS` keyword is used |  |
| **In your design standards and documentation:**

 - Planned and potential execution paths for automations are outlined clearly
                
 - The use cases for synchronous and asynchronous operations within automations are outlined clearly as part of design standards | **In your design standards and documentation:**

 - Automation invocation is not documented
                
 - Use cases for synchronous and asynchronous operations are not addressed |  |
| **KPIs** | **Within your documentation:**

 - Outputs for every automation are measurable and timebound
            
 - Accountable stakeholders are listed for each KPI | **Within your documentation:**

 - KPIs do not exist for automations or have unclear time frames for measurements
            
 - KPIs exist without accountable stakeholders |
| **Within reports and dashboards:**

 - All metrics related to KPIs are included in at least one report or dashboard | **Within reports and dashboards:**

 - KPI reporting does not exist or reports are missing metrics related to some KPIs |  |

## Data Integrity

Data integrity is about how well a system maintains accurate and complete data. The Salesforce Platform maintains robust, [built-in processing logic](/docs/architect/fundamentals/guide/architecture-basics#database-manipulation) designed to protect the integrity of data stored in an individual org’s relational database. One of the fundamentals of building healthy automations is understanding the built-in data integrity behaviors of Salesforce, and making sure all your automation designs align with (and acknowledge) these behaviors.

The biggest anti-patterns in automation design arise from failing to recognize the powerful [data integrity services already provided by Salesforce](/docs/architect/fundamentals/guide/architecture-basics#database-manipulation) and failing to use [standard functionality](/docs/architect/well-architected/guide/intentional#standard-versus-custom-functionality) that takes advantage of these services. To design automations that protect and maintain data integrity you must be familiar with the fundamental order of operation behaviors of Salesforce.

Properly extending data integrity into your custom automations means your system can:

- operate against bulk and large data volumes without manual intervention,
- enforce user security policies when needed and switch to system context when needed,
- encounter errors at run time and follow predictable recovery or failure paths.

You can build better data integrity into your Salesforce automations through proper data handling and error handling.

### Data Handling

The first step to designing for proper data handling in Salesforce is understanding how the multitenant platform handles [transactions](/docs/architect/fundamentals/guide/architecture-basics#transactions). This includes understanding the built-in [order of execution](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm) behaviors that the Salesforce Platform uses to ensure data integrity during record-level data operations. For more on the impacts of this behavior, see [Database Manipulation](/docs/architect/fundamentals/guide/architecture-basics#database-manipulation) in Salesforce Architecture Basics.

Poor data handling in your automations can be some of the most difficult anti-patterns to identify and fully remediate. The recursive and overlapping nature of the platform’s order of execution can make it difficult to see where issues originate. The specific section of code or flow that throws a fatal error or exceeds governor limits may not be the root cause of an underlying data handling issue.

*Transaction awareness* is key to building automations that perform reliably and at scale with Salesforce. This means making sure that every step in an automation is designed with the knowledge of where it is in relation to the platform-controlled [order of execution](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm), can carry out its function correctly, and passes on information to the next step correctly.

Regardless of the automation tool you are using, proper transaction awareness follows similar patterns and requires common considerations:

- Assume every automation will be asked to run against large data volumes without notice, at any given time. Automations should have paths to allow for batch or bulk execution (see [Scalability](/docs/architect/well-architected/guide/reliable#scalability)).
- Do not mix system and user context data operations in the same transaction.
- Reserve sync data operations for [before contexts](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_context_variables.htm) and use async operations for all *after* context actions.
- Use [messaging and notifications](/docs/architect/well-architected/guide/engaging#notifications-and-messages) to avoid creating in-app experiences that would require a user to wait for data based on the results of an async operation.

Beyond transaction awareness, there is a second dimension to data handling: knowing when to carry out logic in different [execution contexts](/docs/architect/fundamentals/guide/architecture-basics#execution-context). Common reasons to break automations up into different execution contexts include:

- **Large volume and/or complex data operations**

Bulkifying operations does not guarantee an automation will handle large data volumes correctly. If the volume of data operations within in an automation will exceed per transaction limits, you will need to carry out data operations using functionality specific to large data volumes (such as via batch Apex or the Bulk 2.0 API). These have distinct transaction limits, suited to large data volumes.
Data operations that need to traverse complex relationship hierarchies or carry out complex recalculations (not including formula fields) across records can easily exceed per transaction limits when carried out in bulk. Consider how “noisy” an update to one record is, in terms of the related data operations or SOQL needed to complete subsequent actions in the system.
The types of sObjects involved in the entire chain of an automation can require you to split data operations into separate transactions to avoid “mixed DML” errors.
- **Logic that needs to execute in user or system context**

The Salesforce Platform enforces sharing and visibility in user context. If you need to perform operations that extend beyond the permission levels of users of your automation, you’ll have to make sure those operations execute in system context.
Different tools will or will not run in different contexts:

Apex will run in system context by default. You can control if and how Apex behaviors enforce user-level sharing rules by using sharing keywords in an Apex class definition.
Flow has no single default behavior. A flow will run in user or system context based on how the flow is launched. You have the option to enforce sharing in system context.
Processes (that is, automations built with Process Builder) run in system context without sharing considerations. (Note: We recommend building low-code automations with Flow.
- **Logic that needs to execute asynchronously**

External system operations - Synchronous callouts or actions that access external data aren’t included in any platform rollback behaviors. To take advantage of these behaviors, you must place actions involving external systems into separate transactions (using async Apex methods, asynchronous paths, or invocable actions).
Eventing and messaging - To control the flow of events or messages related to data operations (and take advantage of platform rollback behaviors), place all actions related to messaging or events in after contexts, using async Apex methods.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/automated#data-integrity-patterns-and-anti-patterns) below shows what proper (and poor) data handling looks like in Salesforce automations. You can use these to validate your automation designs before you build, or identify automations that need to be refactored to improve data handling.

To learn more about tools available from Salesforce for data handling in automation, see [Tools Relevant to Automated](/docs/architect/well-architected/guide/automated#tools-relevant-to-automated).

### Error Handling

Error handling is critical for data integrity. Strong error handling also helps your system scale and age with more [resilience](/docs/architect/well-architected/guide/resilient).

Improper error handling in automations can lead to:

- Record inconsistencies and other data integrity issues
- Sending inaccurate notifications to users and other systems
- Wasting time and resources on manual or repeated processing
- Overall lack of [trust](/docs/architect/well-architected/guide/trusted-overview) in a system

Error handling in automations requires giving any running process the capability to parse an error for information, access logic about what the next steps should be based on error information, and then follow the correct path. These capabilities don’t need to be built over and over in every automation (that’s an [optimization anti-pattern](/docs/architect/well-architected/guide/automated#process-design)). Instead, every automation in the system should have the ability to connect to the relevant error handling [components](/docs/architect/well-architected/guide/composable#loose-coupling).

To build proper error handling controls into your automations, ask these questions:

- What is a “fatal” error?
- What is a “recoverable” error?
- For automations triggered by user actions, how can the automation catch and notify the user of errors before attempting to commit changes?

Once you’ve decided how to handle these errors, you can start to build effective error handling into your automations. The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/automated#data-integrity-patterns-and-anti-patterns) below shows what proper (and poor) error handling looks like in a Salesforce automation. You can use these to validate your automation designs before you build, or identify automations that need to be refactored to improve error handling.

To learn more about tools available from Salesforce for error handling, see [Tools Relevant to Automated](/docs/architect/well-architected/guide/automated#tools-relevant-to-automated).

### Data Integrity Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for data integrity in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-data-integrity).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Data Handling** | **In your data dictionary:**

 - Field-level data and prioritization logic for all data sources and data lake objects exists
            
 - Field mapping from data lake object to data model object exists | **In your data dictionary:**

 - Field-level data and prioritization logic for data sources and data lake objects are not included
            
 - Field mapping from data lake objects to data model objects is not included |
| **In your Apex:**

 - All synchronous DML statements or Database class methods are carried out in *before* trigger execution contexts
            
 - Async Apex invocations use queueables to 'chain' complex DML across transactions
            
 - Batch Apex is used exclusively for large data volumes
            
 - `@future` Apex is not used or used sparingly, for callouts or system object DML | **In your Apex:**

 - DML statements regularly appear in code that will be invoked in *after* trigger contexts
            
 - Async Apex is rarely used
            
 - Async Apex features are used arbitrarily, including:
            
 -- Future Methods and Queueable Apex are used inconsistently or interchangeably
            
 -- Database operations do not have clear, consistent logic for passing execution to Batch Apex when needed |  |
| **In Flow:**

 - All flows launched in user context abstract all system context transactions to subflows, which are consistently placed after a Pause element, [to create a new transaction](https://help.salesforce.com/s/articleView?id=flow_concepts_transaction.htm&type=5&language=en_US)

 - Complex sequences of related data operations are created with Orchestrator (instead of invoking multiple subflows within a monolithic flow)
            
 - All record-triggered flows have [trigger order values populated](https://help.salesforce.com/s/articleView?id=release-notes.rn_automate_flow_builder_trigger_order.htm&type=5&release=236)

 - Flows involving external system callouts or long-running processes use asynchronous paths | **In Flow:**

 - Large, monolithic flows attempt to coordinate complex sequences of related data operations (with or without subflows)
            
 - Record-triggered flows do not use trigger order attributes at all or do not use trigger order values consistently
            
 - Asynchronous paths are not used consistently or at all |  |
| **In your org:**

 - Identity Resolution Reconciliation Rules follow the prioritization logic in your data dictionary | **In your org:**

 - Identity Resolution Reconciliation Rules do not follow prioritization logic in the data dictionary |  |
|  |  |  |
| **Error Handling** | **In Apex:**

 - Code wraps all DML, SOQL, callouts, and other critical process steps in `try-catch` blocks
            
 - Custom exceptions are used to create advanced error messaging and logic
 - In async and bulk contexts, [Database class methods](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_dml_database.htm) are used instead of DML
            
 - Database class methods may be used exclusively for all data operations (instead of DML) | **In Apex:**

 - DML, SOQL, callouts, or other critical process steps are not consistently wrapped in `try-catch` blocks
            
 - `System.debug` statements appear in production code (and are not commented out)
            
 - No Database class methods are used
            
 - Data operations are done exclusively with DML |
| **In Lightning Web Components (LWC):**

 - JavaScript wraps all data operations and critical process steps in `if ()`/`else if ()` blocks
            
 - All `@wire` functions use `data` and `error` properties provided by the API
            
 - All `if (error)`/`else if (error)` statements contain logic to process errors and provide informative messages | **In LWC:**

 - JavaScript does not consistently use  `if ()`/`else if ()` blocks with data operations or critical process steps
            
 - `@wire` functions do not use `data` and `error` properties provided by the API (or do not use them consistently)
            
 - If used at all, `if (error)`/`else if (error)` statements do not actually contain logic to process errors and provide useful error messages |  |
| **In Aura:**

 - JavaScript wraps all data operations and critical process steps in `try-catch` blocks
            
 - Within `try-catch` blocks, native JavaScript `Error` is used in throw statements (no usage of `$A.error()`)
            
 - All recoverable error logic appears within `catch` statements, and provides clear user messages | **In Aura:**

 - JavaScript does not consistently wrap data operations and critical process steps in `try-catch` blocks
            
 - Components use `$A.error()`

 - Recoverable error logic does not consistently appear within `catch` statements, and error messages to users are not clear |  |
| **In Flow:**

 - Screen flows consistently use fault connectors to show errors to users
            
 - Custom error messages are configured for errors that will appear on screen
            
 - Flows with data operations, callouts, and other critical processing logic have fault paths for all key actions | **In Flow:**

 - Flows do not use fault paths consistently or at all
            
 - Custom error messages are not used, so users see the default "An unhandled fault has occurred in this flow" message |  |

## Business Value

The concept of business value, in the context of automation, is about how well processes create measurable, positive impact for business stakeholders. Ideally, process automation enables users to spend less time on repetitive, low-value tasks. It also helps boost data integrity by eliminating manual processing activities that could introduce errors. Much like [Process Design](/docs/architect/well-architected/guide/automated#process-design), identifying and delivering automations that will drive real business value requires work beyond basic discovery and business analysis.

At times, it may seem like the best way to deliver value to the business is to simply automate every process requested by a business user, either in the order they appear in your backlog (or ticketing queue) or based on political factors in your organization. This can lead to two related problems: building automations in a suboptimal order and building the wrong automations altogether. The first problem, poor prioritization, prevents high-value processes from getting implemented when they should, potentially slowing growth. The second problem, building the wrong automations, not only delays the delivery of high-value automations, it also leads to misspent time, unnecessary costs, and increased frustration among delivery teams.

You can deliver greater business value by focusing on KPIs and prioritization.

## Tools Relevant to Automated

| Tool | Description | Efficiency | Data Integrity | Business Value |
| --- | --- | --- | --- | --- |
| [Apex Batching](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch.htm) | Batch records together and process them maneagable chunks | X | X |  |
| [Apex Future Methods](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm) | Asynchronously execute apex methods in the background | X | X |  |
| [Apex Queueing ](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm) | Add apex jobs to a queue and monitor them | X | X |  |
| [Apex Scheduler](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_scheduler.htm) | Asynchronously execute apex classes at specified times | X | X |  |
| [Approvals](https://help.salesforce.com/s/articleView?id=what_are_approvals.htm&type=5&language=en_US) | Specify the required steps to approve records | X | X |  |
| [Asynchronous Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_async_overview.htm) | Run Apex code asynchronously | X | X |  |
| [Automated Actions](https://help.salesforce.com/s/articleView?id=customize_automatedactions.htm&type=5&language=en_US) | Perform field updates, email sends and other actions in the background | X | X |  |
| [Einstein Next Best Action](https://help.salesforce.com/s/articleView?id=einstein_next_best_action.htm&type=5&language=en_US) | Display the right recommendations to the right people at the right time | X |  | X |
| [Email Alert](https://help.salesforce.com/s/articleView?id=customize_wfalerts.htm&type=5&language=en_US) | Create and send automated emails | X |  | X |
| [Escalation Actions](https://help.salesforce.com/s/articleView?id=sf.rules_escalation_actions.htm&type=5) | Specify automated actions to take for case escalations | X | X |  |
| [Field Update](https://help.salesforce.com/s/articleView?id=workflow_managing_field_updates.htm&type=5&language=en_US) | Update field values based on automation | X | X |  |
| [Flow Builder](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_flow_fbuilder.htm&type=5&release=230) | Build automations with a point-and-click interface | X |  | X |
| [Flow Extensions](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_flow_extend.htm&type=5&language=en_US&release=230) | Access stored variables as component inputs in flows | X |  |  |
| [Flow Templates Library](https://www.salesforce.com/products/platform/workflow-automation/workflow-library/flow-index/?#service) | Use templates to design industry specific flows | X |  | X |
| [Flow Trigger](https://help.salesforce.com/s/articleView?id=creating_workflow_flow_actions.htm&type=5&language=en_US) | Automate complex business processes | X |  |  |
| [Invocable Actions](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_actions_invocable.htm) | Add Apex functionality to flows | X |  | X |
| [Orchestrator](https://help.salesforce.com/s/articleView?id=orchestrator_flow_orchestrator.htm&type=5&language=en_US) | Create and manage multi-step automations | X | X |  |
| [Outbound Message](https://help.salesforce.com/s/articleView?id=workflow_managing_outbound_messages.htm&type=5&language=en_US) | Send information from an automated process with receipts and retries |  | X |  |
| [Publish Platform Events with Flow](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_publish_flow.htm) | Publish events via user interactions and automations | X |  |  |
| [Query Optimizer](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_infrastructure_salesforce_query_optimizer.htm) | Use selectivity and indexes to improve query, report, and list view performance | X | X |  |
| [Salesforce Flow](https://help.salesforce.com/s/articleView?id=sf.flow_lightning_flow.htm&type=5) | Create declarative process automations with Flow Builder | X | X |  |
| [Send Notifications with Flows](https://help.salesforce.com/s/articleView?id=livemessage_automatic_notifications_flows.htm&type=5&language=en_US) | Send messages over SMS, WhatsApp, or Facebook Messenger | X |  | X |
| [Send Notifications with Processes](https://help.salesforce.com/s/articleView?id=livemessage_automatic_message_notifications_process.htm&type=5&language=en_US) | Send messages over SMS, WhatsApp, or Facebook Messenger | X |  | X |
| [SOQL FOR UPDATE modifier](https://developer.salesforce.com/docs/atlas.en-us.238.0.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_update.htm?q=for+update) | Lock records to prevent race conditions and thread safety issues |  | X |  |
| [Strategy Builder ](https://help.salesforce.com/s/articleView?id=nba_strategy_builder.htm&type=5&language=en_US) | Identify recommendations to surface on record pages | X |  | X |
| [Subflows](https://developer.salesforce.com/docs/atlas.en-us.salesforce_vpm_implementation_guide.meta/salesforce_vpm_implementation_guide/vpm_designer_about_subflows.htm) | Reduce flow complexity through reuse | X |  |  |
| [Subscribe to Platform Events with Flow](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_flow.htm) | Receive messages published through automations | X |  |  |
| [Task Actions](https://help.salesforce.com/s/articleView?id=customize_wftasks.htm&type=5&language=en_US) | Determine assignment details given to a user by an automation | X |  |  |

## Resources Relevant to Automated

| Resource | Description | Efficiency | Data Integrity | Business Value |
| --- | --- | --- | --- | --- |
| [Apex Execution Governors & Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm) | Learn how the Apex runtime engine enforces limits | X | X |  |
| [Batch Management Resources](https://help.salesforce.com/s/articleView?id=sf.admin_rebates_additional_resources_for_batch_management.htm&type=5) | Create, manage, schedule, and monitor batch jobs | X | X |  |
| [Best Practices for SOQL and SOSL ](https://developer.salesforce.com/docs/atlas.en-us.238.0.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_best_practices_soql_and_sosl.htm) | Improve query performance of applications with large data volumes |  | X |  |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization | X | X | X |
| [Flow Bulkification in Transactions](https://help.salesforce.com/s/articleView?id=sf.flow_concepts_bulkification.htm&type=5) | Design flows to operate against collections | X | X |  |
| [Flow Data Considerations](https://help.salesforce.com/s/articleView?id=sf.flow_considerations_trigger_schedule.htm&type=5) | Learn about schedule-triggered flows for batch data | X | X |  |
| [Flow Debugging](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_flow_debug.htm&type=5&release=230) | Test and troubleshoot flows |  | X |  |
| [How Requests are Processed](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/how_requests_are_processed.htm) | Learn how Salesforce processes jobs quickly and minimizes failures | X | X |  |
| [KPI Spreadsheet Template](/docs/architect/resources/guide/kpi-spreadsheet-template) | Determine the business value of a particular metric | X |  | X |
| [Making Callouts to External Systems from Invocable Actions](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_forcecom_flow_invocable_action_callout.htm) | Call external systems from a Flow using Apex | X |  |  |
| [Mixed DML Operations ](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dml_non_mix_sobjects.htm) | Know which sObjects can be used together for DML in the same transaction | X | X |  |
| [Order of Execution](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm) | Understand the order of events for inserts, updates, and upserts | X | X |  |
| [Query Plan FAQ](https://help.salesforce.com/s/articleView?id=000334796&type=1) | Optimize queries involving large data volumes | X | X |  |
| [Schedule-Triggered Flow Considerations](https://help.salesforce.com/s/articleView?id=sf.flow_considerations_trigger_schedule.htm&type=5) | Understand the special behaviors of schedule-triggered flows | X |  |  |
| [Transaction Control](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_transaction_control.htm) | Generate a savepoint that specifies the current database state | X | X |  |
| [What Happens When a Flow Fails? ](https://help.salesforce.com/s/articleView?id=sf.flow_build_logic_fault.htm&type=5) | Understand error handling in flows | X | X |  |
| [Workflow Automation Best Practice Guide](https://help.salesforce.com/s/articleView?id=000355199&type=1) | Get started with Salesforce automation | X | X | X |
| [Working with Very Large SOQL Queries](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_SOQL_VLSQ.htm) | Write more efficient SOQL Queries |  | X |  |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you’d like to see next.
