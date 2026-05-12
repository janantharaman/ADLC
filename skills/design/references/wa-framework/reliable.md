---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/reliable.html
date_fetched: 2026-05-01
section: well-architected
page_title: Reliable
---

> Read about our update scheduleshere.

## Introduction

Reliable solutions operate effectively and dependably. They are available, perform consistently, and scale to support growing businesses.

A reliable system is not error-prone, behaves as expected, and provides results in a timely manner. Conversely, an unreliable system is slow, does not behave as expected, or fails at critical times. Unreliable systems provide inaccurate information, so stakeholders cannot trust them for business decisions.

System reliability is not constant. A system reliable today may become unreliable if not designed for growth. An unreliable system may require costly maintenance, refactoring, or re-implementation, diverting funds from strategic projects.

Improve reliability in your Salesforce solutions by focusing on three principles: [availability](/docs/architect/well-architected/guide/reliable#availability), [performance](/docs/architect/well-architected/guide/reliable#performance), and [scalability](/docs/architect/well-architected/guide/reliable#scalability). [Salesforce’s scalability product suite](https://www.salesforce.com/platform/application-scaling-performance-testing/) provides native capabilities to help architects operationalize reliable implementations.

## Availability

Availability is a measure of the percentage of time that your system is operational. The Salesforce Platform handles most [infrastructure-level](https://trust.salesforce.com/) availability issues. However, the availability of the solutions that you build on the platform, and which is experienced by your customers, is a shared responsibility. It’s important to understand that even with even with Salesforce's [high availability](https://trust.salesforce.com/en/#systemStatus), the risk of service interruption is never zero.

Architects must prepare for Salesforce service disruptions like planned maintenance or unforeseen circumstances. In addition to service disruptions, consider how to maintain high performance and grow with the business. Narrow architectural choices can lead to long-term availability issues.

Think about availability during the design phase, *before* your solution is built. The longer you defer architecting for availability, the higher the actual cost of availability issues will be in the long run. To mitigate potential risks, use Salesforce Scale Test in your test environment. In that environment, you can test at the scale of production before deploying code in production.

Architects use the language of the business, framing technical concerns for business stakeholders to gain buy-in and prioritize availability work.To mitigate potential risks, use Salesforce Scale Test in your test environment. In that environment, you can test at the scale of production before you deploy code in production.

You can architect for the higher availability of your Salesforce solutions through [risk management](/docs/architect/well-architected/guide/reliable#risk-management) and [failure mitigation](/docs/architect/well-architected/guide/reliable#failure-mitigation).

### Risk Management

Managing risks in the context of the Salesforce architecture involves identifying potential hazards to your system’s operation; its users, including employees, partners, and customers); and your business processes. Often, the formal process of conducting risk analysis falls under the responsibilities of project managers. As an architect, ensure that risk analysis adequately represents the concerns of technical and business stakeholders. It’s also your responsibility to identify the business-critical use cases that you need to scale-test for based on your production peak hotspots.

Some of the biggest pitfalls in risk management come from not dedicating enough time and thought to it. Teams often skip risk assessment Or they conflate solving for [backup and restore](/docs/architect/well-architected/guide/resilient#building-backup-and-restore-capabilities), an important part of mitigating risks to data integrity, with comprehensive risk assessment and mitigation.

To assess risk for your Salesforce solutions, use these methods:

- **Use a risk assessment framework**. Some large enterprises may already have relevant risk matrices in place. If yours does, use them to determine how to classify hazards, what kinds of information to gather, what you need to put in place for remediation, and more. If you don’t already have a risk assessment framework, find one from a reputable source and use it.
- **Assess impact severity and risk categories from the perspective of your customers**. Proactive Monitoring and Scale Center provide configurable alerts and dashboards. They continuously evaluate performance and scalability risks and reduce your reliance on manual checklists. Customer trust and perception are key to every business. In terms of business impact, risks for issues that reach customers usually outweigh risks for issues that don’t. Customers may not think about or perceive risks in the same way as internal teams. If a customer can’t log in to their account, they probably don’t care about the root cause of the issue. They care most about their own, immediate experience.
- **Prioritize your risks**. Ideally, every risk is linked to a solid mitigation and response plan. In reality, you’ll have gaps that you need to address over time. Adopting a “deliver value early and iterate” approach is important. You and your delivery and maintenance teams can take on only so much work at a given time. At Salesforce, a common expression is, “If everything is important, nothing is important.” We use V2MOMs to prioritize and align on work throughout the entire company, across teams, and down to each individual. (You can [learn more about V2MOMs](https://trailhead.salesforce.com/content/learn/modules/manage_the_sfdc_organizational_alignment_v2mom/msfw_oav2m_writing_a_v2mom) on Trailhead.) Use your risk assessments, which give you a chance to work with your stakeholders on prioritizing and committing to the most important risk management work. Use Scale Test - Test Plan Creation to identify the risks to prioritize and to mitigate those risks using scale testing.

Use Proactive Monitoring to detect early availability risks. It surfaces anomalies like API request limit spikes, row lock errors, or concurrent Apex failures, providing actionable insights before issues escalate into service disruptions.

The availability [patterns and anti-patterns](/docs/architect/well-architected/guide/reliable#availability-patterns-and-anti-patterns) show proper and poor risk management within a Salesforce solution. Use the patterns to validate your designs before you build or to identify refactoring areas in your system.

To learn more about Salesforce tools related to risk management, see [Salesforce Tools For Reliability](/docs/architect/well-architected/guide/reliable#salesforce-tools-for-reliability).

### Failure Mitigation

A failure point is a vulnerability that makes a system unreliable. Good failure mitigation is not about pinpointing every potential failure point. Instead, it is about quickly classifying and prioritizing failure points so that maintenance and support teams can respond effectively. See [incident response](/docs/architect/well-architected/guide/resilient#incident-response).

To develop better failure mitigation strategies:

- **Classify triggers for failure points in terms of people, process, and technology**. Just as you categorize risks in terms of people, process, and technology, apply the same thinking to how high-priority failure points are triggered. This approach helps you both identify potential failure triggers and develop and organize responses to them. Sometimes, you can mitigate seemingly divergent failure triggers with similar mitigation approaches, based on how the triggers are classified.

| Trigger Classfication/Type | Mitigation |
| --- | --- |
| People | Policy |
| Process | Playbooks, continuity plans |
| Technology | Redundancy |

- **Identify what basic, intermediate, and mature mitigation looks like**. It will take time to build out mitigation strategies. Define the levels of mitigation to help you and your team see where you can put controls in place immediately and how to focus your efforts over time. Always look for opportunities to use automation in your mitigation approaches—as early as is feasible. To illustrate what this approach looks like in practice, this example shows a people-oriented trigger and what policy-based mitigation looks like at basic, intermediate, and mature levels.

| Trigger | Mitigation | Basic | Intermediate | Mature |
| --- | --- | --- | --- | --- |
| User access change for a new or departing employee | Service-level agreement (SLA) and requirements for provisioning or deprovisioning users | Provision and deprovision users manually, according to SLAs for manual changes. | Process user changes through scheduled jobs, according to SLAs for scheduled changes. | Automate  provisioning and deprovisioning users through a SSO/IDM solution. |

In addition to using architectural playbooks and continuity planning, use Proactive Monitoring. With Proactive Monitoring, you can set up real-time alerting on failure triggers, such as login failures, CPU timeout exceptions, or concurrent API request errors. This approach to alerting augments failure mitigation by ensuring that both technical and business stakeholders are informed in time to reduce the impact of failures.

The [patterns and anti-patterns for availability](/docs/architect/well-architected/guide/reliable#availability-patterns-and-anti-patterns) show what proper and poor failure mitigation looks like in a Salesforce solution. Use them to validate your designs before you build, or to identify places in your system to refactor.

To learn more about Salesforce tools for failure mitigation, see [Tools Relevant to Reliable](/docs/architect/well-architected/guide/reliable#salesforce-tools-for-reliability).

### Availability Patterns and Anti-Patterns

This table shows a selection of patterns to look for or build in your org, and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for availability in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-availability).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Risk Management** | **In your business:**

 - An established risk assessment framework is in use.
        
 - Risks are categorized into people, process, and technology areas. | **In your business:**

 - The risk-assessment framework for Salesforce is ad hoc.
        
 - Risks aren’t clearly identified. |
| **In your documentation:**

 - Risk severity is categorized and assessed based on customer impact.
        
 - Risk mitigation and response plans are prioritized. | **In your documentation:**

 - The customer perspective isn't considered when assessing risk severity or category.
        
 - Risk mitigation and response plans try to capture every risk imaginable. |  |
| **Failure Mitigation** | **In your org:**

 - Failure point triggers and their corresponding mitigation plans are categorized by people, process, and technology.
        
 - Mitigation controls are put in place immediately, mature over time, and incorporate automation as early as possible.
        
 - To ensure optimal scalability, comprehensive testing and optimizing are completed before changes are released to production.
        
 - Before business-critical events, scale testing and optimization are performed, as per SLAs. | **In your org:**

 - Failure point triggers aren’t classified. Mitigation approaches don’t exist or are used only ad hoc.
        
 - Mitigation controls are not revisited or improved.
        
 - Automation isn’t used in mitigation. |
| **Monitoring and Observability** | **In your org:**

 - For checks and anomaly detection, Proactive Monitoring is enabled.
        
 - For ongoing visibility, Proactive Monitoring alerts are integrated with Scale Center. | **In your org:**

 - Only manual health checks are performed, and no continuous monitoring is in place. |

## Performance

System architecture performance is a measure of how much a system processes (throughput) and how fast it responds (latency). You typically understand your system's performance through production testing and monitoring.

A performant system completes processes in a timely manner at every anticipated demand level.

Poor performance goes hand in hand with higher latency and lower throughput, which lead to lower productivity and increased user frustration. Fixing performance issues is urgent because they can lead to a loss of customer trust and financial losses.

You can improve the performance of your solutions, by optimizing throughput and latency.

> Note: Throughput and latency optimization are essential aspects of improving system processing and responsiveness. It’s important to remember, however, that overall system performance also depends on how well you architect forscale. You must consider both dimensions in your designs.

### Throughput

In the context of the Salesforce architecture, throughput is the number of concurrent requests that a system can complete within a given time interval. Customers’ Salesforce solutions that are designed and optimized for throughput operate better within the built-in [governor limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm) of the Salesforce Platform.

Optimizing throughput in Salesforce begins with accurately calculating workloads in your system and planning for their growth. Without accurate projections for the demands that will be made on the system, you can’t pinpoint potential issues with the throughput capabilities of your system.

When thinking about workloads, consider these three dimensions.

- **The number of transactions** your system must process in a given amount of time
- **The number of users** who must access your system simultaneously
- **The overall complexity of transaction logic** in the system

When thinking about performance, teams sometimes focus too narrowly on compute and the constraints on maximum CPU time, which are among the platform’s governor limits. Teams with a narrow focus on CPU time overlook other methods for optimizing throughput. Expanding your focus and applying these methods improves the overall throughput and efficiency of your Salesforce architecture. Those improvements, in turn, will help reduce latency and increase overall system performance. ApexGuru proactively detects throughput-limiting anti-patterns such as SOQL in loops, DML in loops, inefficient GGD calls, and expensive methods. These insights help teams eliminate governor limit risks that cap throughput.

To optimize throughput in your system:

- **Favor asynchronous processing**. The Salesforce Platform uses transaction contexts to control data integrity and limit runaway code. See [transactions in Architecture Basics](/docs/architect/fundamentals/guide/architecture-basics#transactions) in Architecture Basics. For this reason, using asynchronous (async) processing where possible can help minimize potential bottlenecks in synchronous execution contexts. See [data handling](/docs/architect/well-architected/guide/automated#data-handling). Using async compute isn’t a cure for every kind of performance issue, and you’ll need to take latency into consideration when incorporating async processes. Certain platform capabilities, such as queueable Apex, may increase latency during traffic spikes because they cause messages to wait longer in a queue. Depending on your use case, you may decide to tolerate a potential decrease in responsiveness to maintain or improve throughput. In other cases, you may decide that increased latency isn't acceptable. With Scale Test, you can validate these trade-offs by simulating traffic spikes in a Full sandbox. There, you can measure how the jobs affect throughput and latency.
- **Always use bulkification**. At a high level, bulkification means carrying out operations against collections. Often, teams discussing bulkification for their Salesforce solutions focus on streamlining data operations against collections. See [Operational Logic](/docs/architect/well-architected/guide/automated#operational-logic). However, bulkification at a system level involves more than just data operations. Also consider certain tasks, such as callouts or complex computations, as candidates for bulkification. Proper bulkification reduces overhead. It executes multiple operations with one request instead of one request per operation. ApexGuru surfaces anti-bulkification patterns like [DML or SOQL inside loops](https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.apexguru_antipatterns.htm&type=5), which you can fix before scaling to production. See [Bulk Operations](/docs/architect/fundamentals/guide/platform-multitenant-architecture#bulk-operations).
- **Use SOSL for searches and treat SOQL like a data operation**. It may seem obvious that using overly complex SOQL statements will increase the amount of time it takes the system to retrieve records. SOQL adds overhead to the [underlying relational database](/docs/architect/fundamentals/guide/platform-multitenant-architecture#the-platform-data-layer), slowing processing. When using text or wildcard criteria, SOSL is more performant. SOSL uses the platform’s search engine, which is optimized for full-text indexing and universal searches. To optimize record retrieval patterns, make sure that your design standards specify when to use SOSL to find data in your system. Also make sure that they specify how to use SOQL for efficient data operations. See [Operational Logic](/docs/architect/well-architected/guide/automated#operational-logic)).
- **Use Platform Cache and ApexGuru**. The [Lightning Platform Cache](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_cache_namespace_overview.htm) layer provides faster performance and better reliability when caching Salesforce session and org data. Platform Cache improves performance by distributing cache space so that some applications or operations don’t steal capacity from others. ApexGuru detects missed opportunities to cache repeated queries (for example, [Platform Cache for SOQL results](https://help.salesforce.com/s/articleView?id=xcloud.apexguru_antipattern_soql_without_platform_cache.htm&type=5)), which improves throughput in high-scale environments.

The [patterns and anti-patterns](/docs/architect/well-architected/guide/reliable#performance-patterns-and-anti-patterns) for performance show what proper and poor throughput looks like in a Salesforce org. Use them to validate your designs before you build, or to identify opportunities for further optimization.

To learn more about Salesforce tools for throughput optimization, see [Salesforce Tools For Reliability](/docs/architect/well-architected/guide/reliable#salesforce-tools-for-reliability).

### Latency

Latency is a measure of how fast a system completes an execution path. Optimizing the throughput of your system will contribute to improving latency. Another dimension of latency is perceived performance, or how responsive the system seems to users.

People don’t want to wait for pages to load or for processes to finish. Users of your system will become frustrated if they frequently experience lengthy load times when trying to navigate list views, record pages, reports, and so on. When this happens, customers or partners may decide to take their business elsewhere rather than deal with poorly performing systems. Internally, employees may create workarounds to avoid using the system as designed, which can cause downstream issues for security and data integrity.

Perceived performance can be difficult to diagnose. When a user reports slow performance, support teams may not be able to reproduce the issue. Increased latency is often the result of a combination of smaller issues that build upon each other, which can make it difficult to diagnose the exact cause of perceived performance issues.

To reduce latency and improve responsiveness in your Salesforce system:

- **Optimize reports**. Ensure that each report serves a single, specific purpose. Clearly identify the audience and purpose of every report in your system. In reports, include only the minimum amount of data that audience members need to make decisions. Removing columns that don’t align to a report’s purpose will improve report performance by reducing the amount of data that needs to be retrieved and displayed.
- **Optimize filters**. Effective filters speed up report and list view performance by accurately scoping the number of rows that are retrieved from the database. As a general rule, the more specific you make your filter logic, the more efficient the underlying query for data will be. Ways to optimize filters include:

Using “equals” and “not equal to” instead of “contains” and “does not contain”
Avoiding filtering by formula fields
- **Simplify your sharing model**. An overly complex sharing model can slow down a variety of processes because the system must check the sharing and visibility model to determine if a user has access to the data to display or process. Complex sharing calculations can increase latency in reporting, list views, and automation running in the user’s context. See [Sharing and Visibility](/docs/architect/well-architected/guide/secure#sharing-and-visibility).
- **Optimize custom UI components**. Custom-built user interface (UI) components can increase latency. To optimize performance in custom UI components, consider doing these things.

Use Lightning Web Components (LWC). The LWC framework is closely aligned to modern web standards. Custom components written in LWC render more efficiently in web browsers and enable developers to use more performant JavaScript methods. Always aim to use LWC instead of older UI technologies, such as Aura or Visualforce.
Use Lightning Data Service. Lightning Data Service handles the creation and maintenance of secure, performant, and shared caching across components. Use it to avoid unnecessary round-trips to the server for data—and to increase overall application responsiveness.
Use client-side sorting and filtering for list data. For both LWC (preferred) and Aura components (otherwise), developers can use standard JavaScript array functionality to sort, filter, and select values on the client side, reducing the number of required trips to the server.

The [patterns and anti-patterns](/docs/architect/well-architected/guide/reliable#performance-patterns-and-anti-patterns) show what proper and poor latency looks like in a Salesforce org. Use them to validate your designs before you build, or to identify opportunities for further optimization.

To learn more about Salesforce tools for latency optimization, see [Salesforce Tools For Reliability](/docs/architect/well-architected/guide/reliable#salesforce-tools-for-reliability).

### Performance Patterns and Anti-Patterns

This table shows a selection of patterns to look for or build in your org, and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for performance in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-performance).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Throughput** | **In your design standards:**

 - Guidance for how to use Platform Cache adheres to [Platform Cache Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_platform_cache_best_practices.htm) | **In your design standards:**

 - If there is guidance for Platform Cache usage, it isn’t clear or doesn’t align with best practices. |
| **In your org:**

 - Bulkification is used for data and system operations.
            
 - DML or database methods always operate against collections in Apex.
            
 - The fields used during DML for shorter elapsedTime in the database are limited.
            
 - All wildcard criteria are used in SOSL.
            
 - SOQL statements are selective.:
            
 -- They don’t use LIKE comparisons or partial-text comparisons.
            
 -- Comparison operators use positive logic (in other words, INCLUDES or  IN) as their primary logic or only logic.
            
 -- = NULL and != NULL are used used only  rarely always follows a positive comparison operator. 
            
 – To minimize data load and maximize performance, only the fields needed in SOQL queries are retrieved.
            
 -- No LIMIT 1 statements are used.
            
 -- The ALL ROWS keyword isn’t used.
            
 - Asynchronous processing is favored where possible.
            
 - Platform Cache partitions are configured. | **In your org:**

 - DML statements are not bulkified.
                
 - DML or database methods operate against single records in Apex.
                
 - SOSL is rarely or not consistently used for wildcard selection criteria.
                
 - SOQL statements are non-selective:
                
 -- They include LIKE and wildcard filter criteria.
                
 -- Comparisons using !=, NOT or NOT IN criteria are used as the primary or only comparison operator.
                
 -- Uses = NULL and != NULL criteria as the primary or only comparison operators.
                
 -- LIMIT 1 statements are used.
                
 -- The ALL ROWS keyword is used.
                
 - SOQL appears within loops.
                
 - Synchronous processes are favored. |  |
| **Latency** | **In your org:**

 - Reports serve a single specific purpose and contain the minimum number of rows and columns needed to make decisions.
            
 - Filters use “equals” and ”not equal to.”
            
 - Filters don’t contain formula fields.
            
 - Sharing models are simplified as much as possible.
            
 - Custom UI components use Lightning Web Components (LWC).
            
 - LWC uses Lightning Data Service for data operations.
            
 - Sorting and filtering list data is handled on the client side in JavaScript.
            
 - Salesforce Edge is enabled. | **In your org:**

 - Reports serve multiple purposes or contain extra rows and columns that aren't needed to make decisions.
            
 - Filters use “contains” and “does not contain.”
            
 - Filters contain formula fields.
            
 - Sharing models are complex.
            
 - Custom UI components use frameworks that may result in less efficient rendering than LWC (e.g Aura or Visualforce).
            
 - LWC uses Apex for data operations.
            
 - Sorting and filtering list data is handled on the server side using Apex.
            
 - Salesforce Edge isn’t enabled. |

## Scalability

Scalability is a system’s ability to perform consistently as it evolves and grows. A scalable system handles large increases in transaction volumes or concurrent access without foundational changes. Salesforce’s platform services are designed to support application scalability. See [Internal Platform Processing](/docs/architect/fundamentals/guide/platform-multitenant-architecture#internal-platform-processing). With that said, as your organization grows, and demand for your products and services increases, you’re responsible for creating a system that can perform effectively and as expected. Architecting for scalability from the start results in faster delivery of new features and fewer service interruptions as user traffic increases. Early in the design phase, before deploying new features to production, use **Scale Test** to simulate projected workloads and validate that the architecture can scale to support them.

Systems not designed for scalability require constant and costly troubleshooting, redesign, and refactoring. Scalability issues compound over time, degrading performance throughout the system. In some cases, businesses find themselves spending a majority of development and maintenance resources on addressing scalability issues instead of on new features that create value.

Sometimes, a business reaches a critical tipping point. The original design of its system can’t support the business’s growth, and unexpected events make the system unstable. Use insights from **Scale Center** to identify scalability tipping points early. Scale Center surfaces exception hotspots, long-running transactions, and queue bottlenecks that worsen over time.

You can better architect for scale by focusing on data model optimization and data volume management.

*Note: Though not discussed here, testing for scalability is a critical part of validating your application architectures. For guidance, see testing strategy.*

### Data Modeling

Data modeling involves structuring the objects in your org and relating them to one another in a way that enables your users and automated processes to retrieve the data that they need as quickly as possible. Taking steps to [improve throughput](/docs/architect/well-architected/guide/reliable#throughput) addresses many performance issues, but your efforts won’t be as effective without an optimized data model.

The negative impacts of a poorly designed data model aren’t immediately noticeable; Its weaknesses are exposed as the system grows in terms of data volume, processes, users, and integrations. A well-designed data model makes it easier to continuously refactor your application as requirements are added and extended. **ApexGuru** surfaces data-access anti-patterns such as non-selective SOQL, unused fields, and schema inefficiencies that directly impact the scalability of the data model.

To optimize your data model:

- **Use the prebuilt data models from Salesforce**. Salesforce provides prebuilt data models for Sales, Service, and a variety of industry verticals. Using the data models provided by Salesforce ensures that capabilities in your system are defined only once, eliminating redundancy and silos and establishing a single source of truth across the entire system. Because you used Salesforce prebuilt data models for that single source, it’s easier to understand application data with analytics and to use Salesforce’s prebuilt artificial intelligence services. Also, reducing the customizations that you must support lowers maintenance costs and reduces technical debt.
- **Choose the right data types**. Understand the different types of fields supported by Salesforce and their limitations. Consider reporting and encryption requirements so that you can avoid needing to convert data between types in the future.
- **Choose the right relationships**. Salesforce supports two kinds of relationships between objects: master-detail and lookup. Master-detail relationships offer two primary benefits. One is built-in rollup summary capabilities, which count and aggregate detail from child records. The other is a built-in cascade deletion capability, through which deleting a parent record also deletes its child records. However, make sure that you understand the [sharing and data skew implications](/docs/architect/well-architected/guide/reliable#data-volume) of master-detail relationships before deciding to use them.
- **Denormalize for scale.** Normalization is the process of structuring your data model for reduced data redundancy and improved data integrity. Unfortunately, normalization sometimes causes scaling issues. Denormalized tables can perform better at scale, but remember to consider data integrity and redundancy.

The [patterns and anti-patterns](/docs/architect/well-architected/guide/reliable#scalability-patterns-and-anti-patterns) show what proper and poor data model optimization looks like in a Salesforce org. Use them to validate your designs before you build, or to identify opportunities for further optimization.

To learn more about Salesforce tools for data model optimization, see [Salesforce Tools For Reliability](/docs/architect/well-architected/guide/reliable#salesforce-tools-for-reliability).

### Data Volume

Data volume is a measure of the amount of data stored within your system, based on record counts and sizes. If your org has tens of thousands of users, tens of millions of records, or hundreds of gigabytes of total record storage, you have a large data volume. The volume of data and the relationships between objects in your org affects scalability and will likely have a greater impact on scalability than the number of records alone.

To improve the scalability of orgs with large data volumes:

- **Distribute child records**. Avoid parent-child data skew by ensuring that no parent has a large number of child records. The general recommendation is that no parent should have more than 10,000 child records. For example, in a deployment that has many contacts but doesn’t use accounts, consider setting up several account records and distributing related contact records among them.
- **Distribute ownership of records**. Avoid ownership skew by ensuring that no single user or queue owns, nor that all the members of a single role or public group own, more than 10,000 records from the same object. “Parking” data with a “dummy user” is a practice that often leads to ownership skew. If you encounter this issue, be mindful of the impact that it will have on [sharing calculations](/docs/architect/well-architected/guide/reliable#latency). If you can’t redistribute records to relieve the ownership skew, avoid assigning the data-owning user to a role. If your org’s sharing model requires a role assignment, place the data-owning user in a distinct role at the top of the sharing hierarchy. Don’t allow for frequent or unplanned changes in that user’s role. as any changes will have significant performance impacts due to sharing recalculations. Keep that user out of public groups that could be referenced in any sharing rules.
- **Reduce the amount of record data in Salesforce**. Salesforce is designed to provide businesses with a single view of their customers. It can seem counterintuitive that limiting data in Salesforce is a best practice. However, the power of the single view lies in how well it enables business users to understand and take action on customer data. As data volume grows, data that isn’t current or relevant to day-to-day processes or analytics lead to several issues. Those issues include degraded app performance; increased data security risk; and negative impacts on search, reporting, and analytics. To avoid such issues, define a data lifecycle for every object in your data model, with timelines and classifications for data as it ages and loses immediate business value. In accordance with the data lifecycle, implement these procedures to manage data over time.

Data archiving and purging-To keep data volumes as low as possible, remove records that aren’t needed by the business to help keep data volumes as low as possible. Use the Bulk API 2.0’s hard delete function to delete large data volumes.
Data aggregation- Create aggregation custom objects that summarize key historical trends or summary data in a format that’s compatible with reporting. Populate the custom objects using batch Apex. Users can then execute reports based on the aggregated object records.
Data tiering. Maintain large datasets in a different application if they aren’t needed for Salesforce reports or day-to-day work. Make the data available in Salesforce as needed via mashups, callouts, or external objects.

In practice, you may not always be able to immediately address the root cause of a scalability issue when problems arise. For this reason, Salesforce provides options to help ease immediate pain points. It is important to know that enabling these features in your org isn’t a viable, long-term architectural strategy for dealing with large data volumes. These short-term, stopgap workarounds can help reduce latency in systems suffering from poor data architecture, but they can also add technical debt to your org.

Short-term workarounds for scale issues include:

- **Custom indexes** Indexes are stored in a special internal table that the platform’s query optimizer uses to speed up data access operations. See [Multitenant Indexes](/docs/architect/fundamentals/guide/platform-multitenant-architecture#indexes)). The platform automatically indexes certain types of fields by default. To speed up poor-performing queries, you can request additional custom indexes by contacting Salesforce Customer Support. Use the Query Plan tool to determine whether custom indexes will improve the performance of your queries.
- **Skinny tables**. If you need to further optimize queries for common sets of fields on objects with more than 1 million records, skinny tables can help. Skinny tables eliminate the [background join](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_infrastructure_skinny_tables.htm) that occurs when using custom and standard fields from the same object in a report or automation. For you to use skinny tables, Salesforce Customer Support must enable them for your org.

The [patterns and anti-patterns](/docs/architect/well-architected/guide/reliable#scalability-patterns-and-anti-patterns) for scalability show what proper and poor data volume management looks like in a Salesforce org. Use them to validate your designs before you build, or to identify opportunities for further optimization.

To learn more about Salesforce tools for managing data volumes, see [Salesforce Tools For Reliability](/docs/architect/well-architected/guide/reliable#salesforce-tools-for-reliability).

### Scalability Patterns and Anti-Patterns

This shows a selection of patterns to look for or build in your org, and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for scalability in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-scalability).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Data Modeling** | **In your design standards:**

 - Standards and guidance for which business justifications warrant a custom object exist. | **In your design standards:**

 - No standards for creating custom objects exist. |
| **In your data model:**

 - Standard objects are used when possible.
                
 - ApexGuru checks for anti-patterns confirm that SOQL queries are selective and avoid inefficient schema usage.
                
 - Tables are denormalized for scale. | **In your data model:**

 - You have replicated standard objects.
                
 - Tables are normalized to avoid redundancy. |  |
| **Within your business:**

 - Low-code builders understand the different field types supported by Salesforce, and they evaluate reporting and encryption requirements before selecting field data types.
                
 - Before deciding to establish a master-detail relationship between objects, you evaluate the sharing and data skew implications of that relationship. | **Within your business:**

 - Low-code builders select data types without evaluating downstream reporting and encryption requirements.
                
 - Before deciding to establish master-detail relationships between objects, you don’t evaluate the sharing and data skew implications of that relationship. |  |
| **Data Volume** | **In your data:**

 - No parent records have more than 10,000 child records.
                
 - No users are assigned to more than 10,000 records of the same object type.
                
 -  No instances include  more than 10,000 records that have lookup fields pointing to the same record.
                
 - Bulk data loads are sorted into batches according to ParentId field values.
                
 - To ensure that batch strategies don’t break under concurrency, Scale Test is used to validate bulk load patterns at production scale.
                
 -  Bulk data loads into production don’t occur during peak business hours.
                
 -   Bulk data loads include only the minimum data needed for business decisions. | **In your data:**

 - Records with more than 10,000 child records exist.
                
 - Users are assigned to more than 10,000 records of the same type.
                
 - Instances exist where more than 10,000 records have lookup fields that point to the same record.
                
 - Bulk data loads aren’t sorted into batches according to ParentId field values.
                
 - Bulk data loads into production occur during peak business hours.
                
 - Bulk data loads aren’t limited to the minimum data needed for business decisions. |
| **In Flow and Apex :**

 - Logic exists to distribute the number of child records across multiple parent records in scenarios where data skew is a concern.
                
 - When importing or replicating records via integration, logic assigns them to the appropriate human users.
                
 - For Apex collections, such as lists and sets, logic exists to process multiple records to minimize queries and optimize data handling.
                
 - Efficient Apex code that follows the standards and best practices for scalable code is written and deployed. | **In Flow and Apex :**

 - Child records are arbitrarily assigned to parent records, regardless of the number of child records that are already assigned.
                
 -  Records created via data loads or integrations are assigned to a generic "integration user".
                
 - Multiple recursive SOQL queries from the same object are in synchronous transactions, leading to high heap usage.
                
 - When developers write Apex code, they introduce inefficiencies and performance [anti-patterns](https://help.salesforce.com/s/articleView?id=xcloud.apexguru_antipatterns.htm&type=5). |  |
| **Within your business:**

 - You have documented and implemented a data archiving and purging strategy | **Within your business:**

 - You do not have a data archiving and purging strategy or your strategy has been documented but not implemented |  |

## Salesforce Tools for Reliability

| Tool | Description | Availability | Performance | Scalability |
| --- | --- | --- | --- | --- |
| [Big Objects](https://developer.salesforce.com/docs/atlas.en-us.bigobjects.meta/bigobjects/big_object.htm) | Store and manage large volumes of data on the platform. |  |  | X |
| [Code Scanner](https://github.com/forcedotcom/code-analyzer) | Scan Apex code for performance issues. |  | X |  |
| [Custom Indexes](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_infrastructure_indexes.htm) | Improve query performance with custom indexes. |  |  | X |
| [Deleting Data](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_techniques_deleting_data.htm) | Remove unnecessary data to improve performance. |  | X | X |
| [Divisions](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_infrastructure_divisions.htm) | Partition data to limit record counts in queries and reports. |  |  | X |
| [Scale Test](https://help.salesforce.com/s/articleView?id=xcloud.scale_test_overview.htm&type=5) [](https://help.salesforce.com/s/articleView?id=sf.technical_requirements_performance_assistant.htm&type=5) | Test system performance and interpret the results. Before deploying to production, to validate scalability and performance, imulate large-scale UI and API workloads using Playwright or JMeter scripts. |  | X | X |
| [Scale Center](https://help.salesforce.com/s/articleView?id=xcloud.scale_center_overview.htm&type=5) | Get self-serve and real-time insights on system performance. Find long-running transactions, exception hotspots, and throughput bottlenecks. Diagnose scale issues earlier in your development cycle. |  | X | X |
| [ApexGuru](https://help.salesforce.com/s/articleView?id=release-notes.rn_apexguru.htm&release=258&type=5) | Use this  GenAI-based feature in Scale Center to detect Apex, SOQL, and test class anti-patterns at runtime. Through ApexGuru's integration with Salesforce Code Analyzer, get AI-powered recommendations and inline fixes in the development  workflow. Use those recommendations and fixes to resolve hotspots and improve query selectivity, bulkification, cache usage, and test quality. |  | X | X |
| [Salesforce Code Analyzer](https://github.com/forcedotcom/code-analyzer) | Scan code with IDE, CLI, or CI/CD to make sure that  it adheres to best practices. Through Salesforce Code Analyzer's integration with ApexGuru, get insights about performance anti-patterns directly in the developer workflow. |  | X |  |
| [Salesforce Edge Network](https://help.salesforce.com/s/articleView?id=sf.domain_name_edge_network_route_my_domain.htm&type=5) | Improve download times and the user experience by routing your [My Domain](https://help.salesforce.com/s/articleView?id=xcloud.domain_name_overview.htm&language=en_US&type=5) through the Salesforce Edge Network. |  | X |  |
| [Skinny Tables](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_infrastructure_skinny_tables.htm) | Avoid joins on tables that have frequently used fields. |  |  | X |
| [Proactive Monitoring](https://help.salesforce.com/s/articleView?id=000382042&type=1) | Continuously monitor anomalies in record growth, ownership skew, and performance regressions. Alert on scale issues before they become critical. |  | X | X |

## Salesforce Resources for Reliability

| Resource | Description | Availability | Performance | Scalability |
| --- | --- | --- | --- | --- |
| [Scaling Challenges Cost Millions — Here's How to Future-Proof Your Business](https://www.salesforce.com/blog/scalability/) | Discover how  implementing scalability leads to  sustainable growth and long-term success. |  | X | X |
| [Build and Deploy Scalable Applications using Scale Center](https://developer.salesforce.com/blogs/2023/07/salesforce-scale-center-is-generally-available) | Understand how to proactively assess and resolve performance issues in your Salesforce implementations. |  |  |  |
| [Analyze Performance & Scale Hotspots in Complex Salesforce Apps](https://developer.salesforce.com/blogs/2022/05/analyze-performance-scale-hotspots-in-complex-salesforce-apps) | Address performance and scalability issues in your org. |  | X | X |
| [Your App Shouldn't Panic in Rush-Hour Traffic - Here's How to Prepare](https://www.salesforce.com/blog/scale-testing/) | Learn four key steps for successful scale testing. |  |  |  |
| [The ApexGuru AI Engine Explained](https://developer.salesforce.com/blogs/2025/06/the-apexguru-ai-engine-explained) | Learn how ApexGuru uses custom-trained models, real-world org telemetry, and intelligent filtering to deliver precise, contextual, and actionable insights. |  | X | X |
| [Optimize Your Apex for Apps and Agentforce with ApexGuru](https://trailhead.salesforce.com/content/learn/modules/apexguru/optimize-apex-code-with-apexguru) | Learn how ApexGuru helps developers detect and fix performance anti-patterns, including SOQL, DML, debugging, and test inefficiencies., Use ApexGuru as an AI-powered coach for the scalable development of your apps and your implementation of Agentforce. |  | X | X |
| [ApexGuru Antipatterns](https://help.salesforce.com/s/articleView?id=xcloud.apexguru_antipatterns.htm&type=5) | Learn from the official library of ApexGuru-detected anti-patterns, which is updated for every major Salesforce release. |  | X | X |
| [Best Practices for Deployments with Large Data Volumes](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_introduction.htm) | Understand the process impacts of large data volumes. |  |  | X |
| [Considerations for Salesforce Edge Network](https://help.salesforce.com/s/articleView?id=xcloud.domain_name_edge_network_considerations.htm&type=5) | Find out how to prepare your org to use Salesforce Edge Network. |  | X |  |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization. | X | X | X |
| [Data Model Design Considerations](https://medium.com/salesforce-architects/data-model-design-considerations-when-building-salesforce-applications-part-1-4e605f504b54) | Optimize data models for scale and maintenance. |  | X | X |
| [Designing Record Access for Enterprise Scale](https://developer.salesforce.com/docs/atlas.en-us.draes.meta/draes/draes_preface.htm) | Optimize access control performance through configuration. |  |  | X |
| [Infrastructure for Systems with Large Data Volumes](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_infrastructure_for_performance.htm) | Learn about capabilities that support system performance for deployments with large data volumes. |  |  | X |
| [Learning Resources for Batch Management](https://help.salesforce.com/s/articleView?id=sf.admin_rebates_additional_resources_for_batch_management.htm&type=5) | Learn about Batch Management. |  | X | X |
| [Lightning Experience Performance Optimization](https://trailhead.salesforce.com/content/learn/modules/lightning-experience-performance-optimization) | Improve Lightning Experience in your org to help your users work faster. |  | X |  |
| [Managing Lookup Skew in Salesforce to Avoid Record Lock Exceptions](https://developer.salesforce.com/blogs/engineering/2013/04/managing-lookup-skew-to-avoid-record-lock-exceptions) | Understand how to minimize the effects of lookup skews. |  | X | X |
| [SOQL and SOSL Best Practices](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_best_practices_soql_and_sosl.htm) | Follow SOQL and SOSL best practices for deployments with large data volumes. |  | X | X |
| [Tools for Large-Scale Realignments](https://developer.salesforce.com/docs/atlas.en-us.draes.meta/draes/draes_tools.htm) | Plan and execute realignments effectively. |  |  | X |
| [Using Mashups](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/ldv_deployments_techniques_using_mashups.htm) | Maintain large data sets in a different application. |  | X | X |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you’d like to see next.
