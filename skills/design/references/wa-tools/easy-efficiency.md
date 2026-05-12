---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/easy-efficiency.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Automated — Efficiency
---

### KPIs Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Efficiency](/docs/architect/well-architected/guide/automated#efficiency) → [KPIs](/docs/architect/well-architected/guide/automated#kpis)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Business | ✅ KPIs for your specific use cases are identified before enabling a gen AI feature KPIs for your specific use cases are identified before enabling a gen AI feature |
| Platform | Dashboards | ✅ All metrics related to KPIs are included in at least one dashboard |
| Platform | Documentation | ✅ Outputs for every automation are measurable and timebound |
| Platform | Documentation | ✅ Accountable stakeholders are listed for each KPI |

### Operational Logic Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Efficiency](/docs/architect/well-architected/guide/automated#efficiency) → [Operational Logic](/docs/architect/well-architected/guide/automated#operational-logic)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Business | ✅ Segmentation refresh needs are evaluated before implementing data federation Before federating data from external sources, ensure that the standard 12-hour or 24-hour schedule for segment refresh and activation from Data 360 to Marketing Cloud Engagement meets business needs. Rapid segmentation and activation are not currently supported when you use Bring Your Own Lake (BYOL) data federation |
| Data 360 | Documentation | ✅ Design for a 1:1 or 1 connection between Marketing Cloud and Data 360 Many CRM instances can be connected to many Data 360 instances, but more than one Marketing Cloud instance cannot be connected to the same Data 360 instance.However, a single Marketing Cloud instance can be connected to different Data 360 instances |
| Data 360 | Org | ✅ Optimize your segmentation schedules Set Publish Schedules only for the duration that the segment is needed for. Ad hoc or one time campaigns should use the "Don't refresh" Publish Schedule. Evergreen (aka "always on") campaigns should use a Publish Schedule of every 12 hours. For Evergreen campaigns, set the End Date only as far in the future as the campaign will be active for |
| Data 360 | Org | ✅ Optimize your calculated insight schedules If your Calculated Insight needs to run only once, use the "Not Scheduled" option and only manually publish once. If needed less frequently than every 24 hrs, consider other automation options like Flow |
| Data 360 | Org | ✅ Use Data Actions to create Platform Events for improved operational logic Using Data Actions to publish a platform event means you can decouple the data action coming from Data 360 (publishing an event) from the actions you need to happen in your org (invoking flows and apex triggers). This increases the scale of actions your org can react to from Data 360 and greater control over your operational logic. |
| Einstein | Agents | ✅ Define agent instructions as a part of the iterative build/test process Build out the required agent topic fields (name, description, scope) and add associated actions, then begin testing the topic. Incrementally add instructions to guide your agent to execute the topic and select actions in the desired manner in an iterative build/test loop |
| Einstein | Org | ✅ Your prompt templates specify persona and the persona's goal Your prompt templates contain contextual information such as the persona the LLM should assume, as well as that character's goal. For example, include language such as, “You are a marketing executive who wants to invite major customers to a live event.” |
| Einstein | Search Indexes | ✅ Omit fields with low entropy when creating Search Indexes for structured DMOs To improve relevancy, consider excluding data points with very low cardinality (the number of distinct elements in a list), or low entropy (list entries concentrated around a few values). In general, these fields provide little to no useful information for locating relevant data with vector search |
| Platform | Apex | ✅ SOQL statements are selective Comparison operators use positive logic (i.e. `INCLUDES`, `IN`) as primary or only logic in SOQL statements |
| Platform | Apex | ✅ SOQL statements are selective Usage of `= NULL`, `!= NULL` is rare and/or always follows a positive comparison operator in SOQL statements |
| Platform | Apex | ✅ SOQL statements are selective No `LIMIT 1` statements appear in SOQL |
| Platform | Apex | ✅ SOQL statements are selective No usage of `ALL ROWS` keyword appears in SOQL statements |
| Platform | Apex | ✅ No SOQL appears within a loop |
| Platform | Apex | ✅ All wildcard criteria appear in SOSL |
| Platform | Apex | ✅ SOQL statements are selective No SOQL statements use `LIKE` comparisons or partial text comparisons |
| Platform | Apex | ✅ SOQL is wrapped in `try-catch` |
| Platform | Apex | ✅ No variables refer to hard-coded values (for record types, users, etc. |
| Platform | Design Standards | ✅ The use cases for synchronous and asynchronous operations within automations are outlined clearly as part of design standards |
| Platform | Documentation | ✅ Planned and potential execution paths for automations are outlined clearly |
| Platform | Flow | ✅ No variables refer to hard-coded values (for record types, users, etc.) |
| Platform | Flow | ✅ Flows (including processes) hand logic off to Apex in large data volume contexts |
| Platform | Flow | ✅ Subflows are used for the sections of a processes that need to be reused across the business |
| Platform | Flow | ✅ All autolaunched flows and processes use decision and/or pause elements to evaluate entry criteria and prevent infinite loops or executions against large data volumes |

### Process Design Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Efficiency](/docs/architect/well-architected/guide/automated#efficiency) → [Process Design](/docs/architect/well-architected/guide/automated#process-design)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Org | ✅ Optimize Total Rows Processed in Batch Transforms Within Data Transforms, use a filter activity on the canvas to isolate only rows that need to be processed for successful transformation |
| Data 360 | Org | ✅ Consolidate Dimensions Across Calculated Insights Instead of writing multiple Calculated Insights with one dimension each, consolidate both dimensions into one Calculated Insight where possible |
| Platform | Apex | ✅ Each class serves a single, specific purpose |
| Platform | Apex | ✅ Each method performs a specific, granular task |
| Platform | Apex | ✅ All input variables have a clear purpose within the class |
| Platform | Apex | ✅ Code execution requires a minimal number of resources |
| Platform | Flow | ✅ Users are only asked to provide data when existing system data can't be used |
| Platform | Flow | ✅ Flows are organized in a hierarchical structure consisting of a main flow and supporting subflows |
| Platform | Flow | ✅ All user inputs have a clear purpose within the flow |
| Platform | Flow | ✅ Each flow serves a single, specific purpose |
| Platform | Flow | ✅ Each step performs a specific, granular task |

### KPIs Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Efficiency](/docs/architect/well-architected/guide/automated#efficiency) → [KPIs](/docs/architect/well-architected/guide/automated#kpis)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Dashboards | ⚠️ KPI reporting does not exist or dashboards are missing metrics related to some KPIs |
| Platform | Documentation | ⚠️ KPIs exist without accountable stakeholders |
| Platform | Documentation | ⚠️ KPIs do not exist for automations or have unclear time frames for measurements |

### Operational Logic Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Efficiency](/docs/architect/well-architected/guide/automated#efficiency) → [Operational Logic](/docs/architect/well-architected/guide/automated#operational-logic)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Documentation | ⚠️ Design for a many:1 connection between Marketing and Data 360 Diagrams or solution design documents specify more than one Marketing Cloud instance connecting to a singular Data 360 instance via the Marketing Cloud Connector |
| Data 360 | Org | ⚠️ Data federation is implemented without evaluating segmentation refresh needs Data federation is leveraged for data sets which require rapid segmentation and activation (1-hour or 4-hour schedule to send activation data), vs the standard 12-hour or 24-hour schedule |
| Data 360 | Org | ⚠️ Data federation is implemented without evaluating data transform needs An external DLO contains data needed for streaming data transforms |
| Einstein | Agents | ⚠️ Define agent instructions at the beginning of the design process Instructions are added before testing the agent's ability to execute the topic and select appropriate actions |
| Platform | Apex | ⚠️ SOQL statements are non-selective Comparisons using `NOT`, `NOT IN` criteria are used as the primary or only comparison operator in SOQL statements |
| Platform | Apex | ⚠️ SOQL statements are non-selective `ALL ROWS` keyword is used in SOQL statements |
| Platform | Apex | ⚠️ SOQL statements are non-selective `= NULL`, `!= NULL` criteria are used as the primary or only comparison operator in SOQL statements |
| Platform | Apex | ⚠️ Variables have hard-coded values |
| Platform | Apex | ⚠️ SOQL appears within loops |
| Platform | Apex | ⚠️ SOQL statements are non-selective `LIKE` and wildcard filter criteria appear frequently in SOQL statements in SOQL statements |
| Platform | Apex | ⚠️ SOQL is not wrapped in `try-catch` |
| Platform | Apex | ⚠️ SOQL statements are non-selective `LIMIT 1` statements appear in SOQL |
| Platform | Apex | ⚠️ SOSL is rarely or not consistently used for wildcard selection criteria |
| Platform | Design Standards | ⚠️ Use cases for synchronous and asynchronous operations are not addressed |
| Platform | Documentation | ⚠️ Automation invocation is not documented |
| Platform | Flow | ⚠️ Variables have hard-coded values |
| Platform | Flow | ⚠️ Flows (including processes) must be manually deactivated prior to bulk data loads |
| Platform | Flow | ⚠️ Portions of a flow are repeated across flows rather than using subflows |
| Platform | Flow | ⚠️ Flows (including processes) trigger "unhandled exception" notices |
| Platform | Flow | ⚠️ Even simple flows regularly cause errors related to governor limits |

### Process Design Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Efficiency](/docs/architect/well-architected/guide/automated#efficiency) → [Process Design](/docs/architect/well-architected/guide/automated#process-design)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ Classes serve multiple purposes |
| Platform | Apex | ⚠️ Methods perform multiple tasks or methods perform tasks that donâ€™t align to the stated purpose of the class theyâ€™re part of |
| Platform | Apex | ⚠️ Input variables arenâ€™t actually used in methods |
| Platform | Apex | ⚠️ Methods unnecessarily retrieve data from the database or from external systems |
| Platform | Flow | ⚠️ Flows require additional inputs to provide context |
| Platform | Flow | ⚠️ Flows serve multiple purposes |
| Platform | Flow | ⚠️ Groups of related steps contain functionality that overlaps with groups of steps in other flows |
| Platform | Flow | ⚠️ Flows ask for user inputs when stored data can be used instead |
| Platform | Flow | ⚠️ Flows require inputs whose data is not used |
