---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-scalability.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Reliable — Scalability
---

### Data Modeling Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Scalability](/docs/architect/well-architected/guide/reliable#scalability) → [Data Modeling](/docs/architect/well-architected/guide/reliable#data-modeling)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Org | ✅ Data transforms are used to denormalize data before mapping Data Transforms exists to transform source data, so that all contact points can be ingested separately into standard contact point objects |
| Platform | Business | ✅ Low-code builders understand the different field types supported by Salesforce, and evaluate reporting and encryption requirements before selecting field data types |
| Platform | Business | ✅ Sharing and data skew implications are evaluated before choosing to establish a master-detail relationship between objects |
| Platform | Data Model | ✅ Tables have been denormalized for scale |
| Platform | Data Model | ✅ Standard objects are used where possible |
| Platform | Design Standards | ✅ Standards and guidance for which business justifications warrant a custom object exist |

### Data Volume Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Scalability](/docs/architect/well-architected/guide/reliable#scalability) → [Data Volume](/docs/architect/well-architected/guide/reliable#data-volume)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Test Plans | ✅ Bulk load calculations account for Day 0 data loads You have planned for the large data volumes that often need to be migrated before your solution go-live (also known as Day 0), and have confirmed that you will not approach the maximum file size and maximum files per scheduled run concurrently |
| Platform | Apex | ✅ Logic exists to distribute the number of child records across multiple parent records in scenarios where data skew is a concern |
| Platform | Apex | ✅ Logic exists to assign all records to the appropriate human users when imported or replicated via an integration |
| Platform | Business | ✅ You have documented and implemented a data archiving and purging strategy |
| Platform | Business | ✅ Bulk data load strategy is optimized to optimize server consumption Load times, data sequences, record-locking, automation, and bulk sharing processes are accounted for in your bulk load strategy for efficient server consumption |
| Platform | Data | ✅ No parent records have more than 10,000 child records |
| Platform | Data | ✅ No users are assigned to more than 10,000 records of the same object type |
| Platform | Data | ✅ No instances exist where more than 10,000 records have lookup fields that point to the same record |
| Platform | Data | ✅ Bulk data loads into production do not occur during peak business hours |
| Platform | Data | ✅ Bulk data loads are sorted into batches according to `ParentId` field values |
| Platform | Data | ✅ Bulk data loads include only the minimum data needed for business decisions |
| Platform | Flow | ✅ Logic exists to distribute the number of child records across multiple parent records in scenarios where data skew is a concern |
| Platform | Flow | ✅ Logic exists to assign all records to the appropriate human users when imported or replicated via an integration |
| Platform | Org | ✅ Data post-processing is deferred during large data loads Post-processing automations are postponed until after large data loads are over. |
| Platform | Test Plans | ✅ Bulk API load strategy is tested in a full copy sandbox When planning for a data load using Bulk API in a full copy sandbox to identify the pattern, the sequence of load, and any locking issues that can arise. |

### Data Modeling Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Scalability](/docs/architect/well-architected/guide/reliable#scalability) → [Data Modeling](/docs/architect/well-architected/guide/reliable#data-modeling)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ Low-code builders select data types without evaluating downstream reporting and encryption requirements |
| Platform | Business | ⚠️ Sharing and data skew are not considered before establishing master-detail relationships between objects |
| Platform | Data Model | ⚠️ Tables have been normalized to avoid redundancy |
| Platform | Data Model | ⚠️ You have replicated standard objects |
| Platform | Design Standards | ⚠️ No standards for creating custom objects exist |

### Data Volume Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Scalability](/docs/architect/well-architected/guide/reliable#scalability) → [Data Volume](/docs/architect/well-architected/guide/reliable#data-volume)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Test Plans | ⚠️ Your bulk load calculations don't include Day 0 data loads Day 0 load calculations are not conducted, or if documented, are near the max value for both file size and files per run concurrently |
| Platform | Apex | ⚠️ Records created via data loads or integrations are assigned to a generic "integration user" |
| Platform | Apex | ⚠️ Child records are arbitrarily assigned to parent records regardless of the number of existing child records that have already been assigned |
| Platform | Business | ⚠️ You do not have a data archiving and purging strategy or your strategy has been documented but not implemented |
| Platform | Business | ⚠️ Bulk data loads are run without planning for scale Load times, data sequences, record-locking, automation, and bulk sharing processes are not considered before bulk data loads are conducted |
| Platform | Data | ⚠️ Bulk data loads into production occur during peak business hours |
| Platform | Data | ⚠️ Bulk data loads are not limited to the minimum data needed for business decisions |
| Platform | Data | ⚠️ Records with more than 10,000 child records exist |
| Platform | Data | ⚠️ Users are assigned to more than 10,000 records of the same type |
| Platform | Data | ⚠️ Instances exist where more than 10,000 records have lookup fields that point to the same record |
| Platform | Data | ⚠️ Bulk data loads are not sorted into batches according to `ParentId` field values |
| Platform | Flow | ⚠️ Records created via data loads or integrations are assigned to a generic "integration user" |
| Platform | Flow | ⚠️ Child records are arbitrarily assigned to parent records regardless of the number of existing child records that have already been assigned |
| Platform | Org | ⚠️ Bulk API load strategy is tested in a partial copy sandbox Bulk API load tests to determine batch load times are conducted on a subset of data in a partial copy sandbox. |
| Platform | Org | ⚠️ Conducting bulk data loads in parallel with other operations that lock records Running batch Apex in parallel along with data loads |
| Platform | Org | ⚠️ Choosing an API without considering the size of your dataset SOAP API is used for data loads greater than 500,000 records |
| Platform | Org | ⚠️ Reporting requirements drive role hierarchy design Using reporting requirements to determine what or how many role hierarchy levels you need |
| Platform | Org | ⚠️ Role hierarchy has empty roles Empty placeholder roles are created for the future |
| Platform | Org | ⚠️ Role hierarchy mimics your org chart You replicated your org structure in the role hierarchy, creating individual roles for each title at your company |
