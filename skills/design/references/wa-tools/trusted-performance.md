---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-performance.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Reliable — Performance
---

### Latency Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Performance](/docs/architect/well-architected/guide/reliable#performance) → [Latency](/docs/architect/well-architected/guide/reliable#latency)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Org | ✅ Data Streams leverage upsert instead of full refresh where possible Full refresh clears out the table entirely and then repopulates it with data. Unless you truly need the full refresh, opt for upsert to get new and/or updated records only. This will improve processing times and reduce credit usage |
| Einstein | Agents | ✅ Agents have no more than 15 actions assigned to a given topic Fifteen or fewer actions are listed in the "This Topic's Actions" tab in Agent Builder |
| Einstein | Search Indexes | ✅ Omit fields with low cardinality from Search Indexes to reduce agent latency Ingesting fields with very low cardinality (the number of distinct elements in a list), or low entropy (list entries concentrated around a few values) can affect relevancy and latency Use the advanced setup in the Search Index Builder to select only relevant fields for chunking. This will reduce the size of your search index, reducing the latency of your agents |
| Platform | Flow | ✅ Specify fields within Get Records to improve performance When you specify which fields to store in a Get Records element you reduce the amount of data being returned from the server and passed to the client. If a Data Table consumes the output of this element, you could see significant performance improvement in your component |
| Platform | Org | ✅ Reports serve a single specific purposes |
| Platform | Org | ✅ Reports contain the minimum number of rows and columns needed to make decisions |
| Platform | Org | ✅ Filters use equals/not equal |
| Platform | Org | ✅ Filters do not contain formula fields |
| Platform | Org | ✅ Sharing models are simplified as much as possible |
| Platform | Org | ✅ Custom UI components use Lightning Web Components |
| Platform | Org | ✅ LWC uses Lightning Data Service for data operations |
| Platform | Org | ✅ Sorting and filtering list data is handled on the client side in JavaScript |
| Platform | Org | ✅ List views, reports, and dashboards are audited for performance Regular reviews identify performance issues (high runtime/DB cpu consumption), and least performant list views, reports, and dashboards are updated or removed |
| Platform | Org | ✅ Salesforce Edge is enabled |

### Throughput Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Performance](/docs/architect/well-architected/guide/reliable#performance) → [Throughput](/docs/architect/well-architected/guide/reliable#throughput)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apex | ✅ Bulk API batch sizes are tuned carefully Batch size will likely vary between jobs based on the nature of the objects, the operation, and the automation that underlies the object. A bit of an art, rather than a science, it is important to tune the batch size so that it performs as much work as possible, but does not exceed 10 minutes of execution time |
| Platform | Design Standards | ✅ Guidance for how to use Platform Cache adheres to Platform Cache Best Practices |
| Platform | Org | ✅ DML or Database methods always operate against collections in Apex |
| Platform | Org | ✅ SOQL statements are selective No usage of `LIKE` comparisons or partial text comparisons in SOQL |
| Platform | Org | ✅ SOQL statements are selective Comparison operators use positive logic (i.e. `INCLUDES`, `IN`) as primary or only logic in SOQL statements |
| Platform | Org | ✅ SOQL statements are selective Usage of `= NULL`, `!= NULL` is rare and/or always follows a positive comparison operator in SOQL statements |
| Platform | Org | ✅ SOQL statements are selective No `LIMIT 1` statements appear in SOQL |
| Platform | Org | ✅ No SOQL appears within a loop |
| Platform | Org | ✅ All wildcard criteria appear in SOSL |
| Platform | Org | ✅ Bulkification is used for data and system operations |
| Platform | Org | ✅ Asynchronous processing is favored where possible |
| Platform | Org | ✅ Platform Cache Partitions are configured |
| Platform | Org | ✅ SOQL statements are selective |
| Platform | Org | ✅ SOQL statements are selective No usage of `ALL ROWS` keyword appears in SOQL statements |

### Latency Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Performance](/docs/architect/well-architected/guide/reliable#performance) → [Latency](/docs/architect/well-architected/guide/reliable#latency)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Org | ⚠️ Data Streams refresh mode is set to Full Refresh by default All or most data streams have a refresh mode of Full Refresh |
| Einstein | Agents | ⚠️ Agents have more than 15 actions assigned to a given topic More than 15 actions are listed in the "This Topic's Actions" tab in Agent Builder |
| Platform | Lightning Web Components (LWC) | ⚠️ Assuming application events only execute when a component is being used In the Lightning Console, components contained in tabs that are not focused can still be listening for application events even though they are not visible |
| Platform | Org | ⚠️ Sharing models are complex |
| Platform | Org | ⚠️ Custom UI components use Aura or Visualforce |
| Platform | Org | ⚠️ LWC uses Apex for data operations |
| Platform | Org | ⚠️ Sorting and filtering list data is handled on the server side using Apex |
| Platform | Org | ⚠️ Filters use contains/does not contain |
| Platform | Org | ⚠️ Filters contain formula fields |
| Platform | Org | ⚠️ Salesforce Edge is not enabled |
| Platform | Org | ⚠️ Reports serve multiple purposes |
| Platform | Org | ⚠️ Reports contain extra rows and columns that aren't needed to make decisions |

### Throughput Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Performance](/docs/architect/well-architected/guide/reliable#performance) → [Throughput](/docs/architect/well-architected/guide/reliable#throughput)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ Enqueueing multiple Future or Queueable methods from a single synchronous action Multiple async methods are enqueued from a single synchronous action |
| Platform | Apex | ⚠️ Parent/child pairs are split across Bulk API batches Multiple batches contain child records that are related to the same parent |
| Platform | Design Standards | ⚠️ If there is guidance for Platform Cache usage, it is unclear or does not align with recommended best practices |
| Platform | Org | ⚠️ SOQL statements are non-selective `= NULL`, `!= NULL` criteria are used as the primary or only comparison operator in SOQL statements |
| Platform | Org | ⚠️ SOQL statements are non-selective `LIMIT 1` statements appear in SOQL |
| Platform | Org | ⚠️ SOQL statements are non-selective `ALL ROWS` keyword is used in SOQL statements |
| Platform | Org | ⚠️ DML statements are not bulkified |
| Platform | Org | ⚠️ Synchronous processes are favored |
| Platform | Org | ⚠️ SOQL appears within loops |
| Platform | Org | ⚠️ Planning for asynchronous operations to end at a specific time Designing processes or solutions that assume an asynchronous operation will end at a specific time or within a given SLA. |
| Platform | Org | ⚠️ Enqueuing batch jobs from synchronous operations Batch Apex jobs are initiated from synchronous end-user activity or integration API calls |
| Platform | Org | ⚠️ DML or Database methods operate against single records in Apex |
| Platform | Org | ⚠️ SOQL statements are non-selective `LIKE` and wildcard filter criteria appear in SOQL statements |
| Platform | Org | ⚠️ SOQL statements are non-selective Comparisons using `NOT`, `NOT IN` criteria are used as the primary or only comparison operator in SOQL statements |
| Platform | Org | ⚠️ Visualforce view state is used for application caching |
| Platform | Org | ⚠️ SOSL is rarely or not consistently used for wildcard selection criteria |
| Platform | Visualforce | ⚠️ Excessive polling during Visualforce remoting High traffic Visualforce pages poll the database more frequently than every five minutes |
