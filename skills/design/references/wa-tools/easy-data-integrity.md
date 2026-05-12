---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/easy-data-integrity.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Automated — Data Integrity
---

### Data Handling Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Data Integrity](/docs/architect/well-architected/guide/automated#data-integrity) → [Data Handling](/docs/architect/well-architected/guide/automated#data-handling)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Data Dictionary | ✅ Field-level data and prioritization logic for all data sources and data lake objects exists |
| Data 360 | Org | ✅ Composite keys are used to construct a unique primary key if one does not exist Use a formula field to join multiple fields from your data set when there is not a single field in the data set that is unique |
| Data 360 | Org | ✅ Data streams that use the CRM Connector leverage the bi-weekly full refresh When using the CRM Connector for incremental loads, a full refresh is initiated every two weeks. While this may increase data ingestion, it protects data integrity for metadata (like formula fields), which do not trigger a DML transaction, and as a result, are not included in incremental loads |
| Data 360 | Org | ✅ Individual ID is used to map Data 360 data to other systems Map Individuals in Data 360 to other systems using the Individual ID. For example, the Marketing Cloud Engagement Subscriber Key should be mapped to the Individual ID from Data 360 |
| Data 360 | Org | ✅ Fully Qualified Keys are used to accurately interpret data All DLOs that contain a key value have a key qualifier field and Fully Qualified Keys (FQK) are enabled in the org to ensure to avoid conflicts that can occur when multiple data streams are harmonized into a single Data Model Object (DMO) |
| Data 360 | Org | ✅ Normalized match methods are used in match rules when they are available Exact normalized match transforms source data to resolve common matching issues like trailing spaces, inconsistent formatting, and special characters. Leverage this method on fields where it is available instead of using fuzzy matching, unless you have configured multiple rulesets for testing and confirmed that the consolidation rate does not meet business needs |
| Einstein | Documentation | ✅ Data usefulness is documented as a part of AI project design Your company's definition of data usefulness is documented and operationalized to improve AI responses |
| Platform | Apex | ✅ Future Apex is used sparingly, for callouts or system object DML |
| Platform | Apex | ✅ Async Apex invocations use queueable to 'chain' complex DML across transactions |
| Platform | Apex | ✅ Batch Apex is used exclusively for large data volumes Batch Apex is best at processing large amounts of data. Asynchronous Apex has higher limits than synchronous Apex so that more work can be done. Avoid very small batch sizes where possible to avoid consequences of Flow Control (queue flooding), overhead and exhausting the daily Asynchronous Apex limit |
| Platform | Apex | ✅ All synchronous DML statements or Database class methods are carried out in before trigger execution contexts |
| Platform | Apex | ✅ Bulk API is used only when large amounts of data must be processed Bulk API is used when large amounts of data must be processed. Native SOAP and REST APIs are leveraged for smaller amounts of data processing |
| Platform | Data Dictionary | ✅ Field mapping from data lake object to data model object exists |
| Platform | Flow | ✅ All flows launched in user context abstract all system context transactions to subflows, which are consistently placed after a Pause element, to create a new transaction |
| Platform | Flow | ✅ All record-triggered flows have trigger order values populated |
| Platform | Flow | ✅ Flows involving external system callouts or long-running processes use asynchronous paths |
| Platform | Flow | ✅ Complex sequences of related data operations are created with Orchestrator (instead of invoking multiple subflows within a monolithic flow) |
| Platform | Org | ✅ Identity Resolution Reconciliation Rules follow the prioritization logic in your data dictionary |

### Error Handling Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Data Integrity](/docs/architect/well-architected/guide/automated#data-integrity) → [Error Handling](/docs/architect/well-architected/guide/automated#error-handling)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Org | ✅ Prompts specify the expected output Include direct instructions for the LLM to only generate the expected type of content. |
| Platform | Apex | ✅ Custom exceptions are used to create advanced error messaging and logic |
| Platform | Apex | ✅ Code wraps all DML, SOQL, callouts, and other critical process steps in `try-catch` blocks |
| Platform | Apex | ✅ Database class methods may be used exclusively for all data operations (instead of DML) |
| Platform | Apex | ✅ In async and bulk contexts, Database class methods are used instead of DML |
| Platform | Aura | ✅ JavaScript wraps all data operations and critical process steps in `try-catch` blocks |
| Platform | Aura | ✅ Within `try-catch` blocks, native JavaScript `Error` is used in throw statements (no usage of `$A.error()`) |
| Platform | Aura | ✅ All recoverable error logic appears within `catch` statements, and provides clear user messages |
| Platform | Flow | ✅ Flows with data operations, callouts, and other critical processing logic have fault paths for all key actions |
| Platform | Flow | ✅ Screen flows consistently use fault connectors to show errors to users |
| Platform | Flow | ✅ Custom error messages are configured for errors that will appear on screen |
| Platform | Lightning Web Components (LWC) | ✅ JavaScript wraps all data operations and critical process steps in `if ()`/`else if ()` blocks |
| Platform | Lightning Web Components (LWC) | ✅ All `@wire` functions use `data` and `error` properties provided by the API |
| Platform | Lightning Web Components (LWC) | ✅ All `if (error)`/`else if (error)` statements contain logic to process errors and provide informative messages |

### Data Handling Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Data Integrity](/docs/architect/well-architected/guide/automated#data-integrity) → [Data Handling](/docs/architect/well-architected/guide/automated#data-handling)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Org | ⚠️ Fields with supported normalized match methods use fuzzy matching Fuzzy match is applied to fields that offer exact normalized match methods |
| Data 360 | Org | ⚠️ Unified Individual ID is assumed to be immutable The unified individual ID is used as a master ID or global ID to be used by the rest of the organization |
| Data 360 | Org | ⚠️ Event Date is mapped to a mutable DateTime value Event Date is mapped to a mutable DateTime field such as LastUpdated or LastExtracted |
| Data 360 | Org | ⚠️ Primary Key is mapped to a field that is not unique Choosing any field as a primary key for your data stream if one does not exist in your data set without first validating that the selected field is unique |
| Data 360 | Org | ⚠️ Loading data in batches and then attempting to activate it in real-time. For example, a common but flawed approach might involve loading data hourly from an Amazon S3 bucket and then activating it through data actions |
| Platform | Apex | ⚠️ DML statements regularly appear in code that will be invoked in after trigger contexts |
| Platform | Apex | ⚠️ Batch Apex jobs have a very small scope size Very small batch sizes (such as scope size = 1) are used |
| Platform | Apex | ⚠️ Batch Apex is used for external callouts Large volumes of Salesforce data are pushed out of Salesforce to an external system using Batch Apex |
| Platform | Apex | ⚠️ Publish Immediately Platform Events are used adhoc Publish Immediately (Real-time) events are used instead of Publish After Commit (Non real-time) regardless of publish order requirements or record-locking risks. |
| Platform | Apex | ⚠️ Async Apex features are used arbitrarily Future Methods and Queueable Apex are used inconsistently or interchangeably |
| Platform | Apex | ⚠️ Async Apex features are used arbitrarily; it is not clear developers know when to use future vs queueable Apex, when to hand off DML to batch jobs |
| Platform | Apex | ⚠️ Async Apex is rarely used |
| Platform | Apex | ⚠️ Async Apex features are used arbitrarily Database operations do not have clear, consistent logic for passing execution to Batch Apex when needed |
| Platform | Data Dictionary | ⚠️ Field mapping from data lake objects to data model objects is not included |
| Platform | Data Dictionary | ⚠️ Field-level data and prioritization logic for data sources and data lake objects are not included |
| Platform | Flow | ⚠️ Performing DML using a collection that is an output from a screen component Leveraging the "Use the IDs and all field values from a record or record collection” setting on a create, update or delete element, when that collection is an output from a screen component |
| Platform | Flow | ⚠️ Record-triggered flows do not use trigger order attributes at all or do not use trigger order values consistently |
| Platform | Flow | ⚠️ Asynchronous paths are not used consistently or at all |
| Platform | Flow | ⚠️ Large, monolithic flows attempt to coordinate complex sequences of related data operations (with or without subflows) |
| Platform | Org | ⚠️ Identity Resolution Reconciliation Rules do not follow prioritization logic in the data dictionary |

### Error Handling Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Automated](/docs/architect/well-architected/guide/automated) → [Data Integrity](/docs/architect/well-architected/guide/automated#data-integrity) → [Error Handling](/docs/architect/well-architected/guide/automated#error-handling)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ DML, SOQL, callouts, or other critical process steps are not consistently wrapped in try-catch blocks |
| Platform | Apex | ⚠️ No Database class methods are used |
| Platform | Apex | ⚠️ Data operations are done exclusively with DML |
| Platform | Apex | ⚠️ `System.debug` statements appear in production code (and are not commented out) |
| Platform | Aura | ⚠️ JavaScript does not consistently wrap data operations and critical process steps in `try-catch` blocks |
| Platform | Aura | ⚠️ Components use `$A.error()` |
| Platform | Aura | ⚠️ Recoverable error logic does not consistently appear within `catch` statements, and error messages to users are not clear |
| Platform | Flow | ⚠️ Flows do not use fault paths consistently or at all |
| Platform | Flow | ⚠️ Custom error messages are not used, so users see the default "An unhandled fault has occurred in this flow" message |
| Platform | Lightning Web Components (LWC) | ⚠️ `@wire` functions do not use `data` and `error` properties provided by the API (or do not use them consistently) |
| Platform | Lightning Web Components (LWC) | ⚠️ If used at all, `if (error)`/`else if (error)` statements do not actually contain logic to process errors and provide useful error messages |
| Platform | Lightning Web Components (LWC) | ⚠️ JavaScript does not consistently use `if ()`/`else if ()` blocks with data operations or critical process steps |
