---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-data-security.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Secure — Data Security
---

### Sharing & Visibility Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Data Security](/docs/architect/well-architected/guide/secure#data-security) → [Sharing & Visibility](/docs/architect/well-architected/guide/secure#sharing-visibility)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Org | ✅ Data segregation is enforced with Data Spaces Data Spaces exist to segregate and ensure the proper visibility for Data 360 data |
| Einstein | Bots | ✅ Flows initiated by a bot run in bot user context Flows initiated by a bot use the user profile and permission sets associated with the bot to determine the object permissions and field-level access of the Flow. |
| Platform | Apex | ✅ All code accessing data (SOQL/SOSL) or performing data operations (DML/Database Class methods) uses with sharing keywords |
| Platform | Design Standards | ✅ Different data access standards are used for external users and internal users, if applicable |
| Platform | Documentation | ✅ A security matrix outlines the data each user persona is authorized to access |
| Platform | Flow | ✅ Screen flows in user context whenever possible Avoid running screen flow in system context. If this can't be avoided, use the Subflow element to launch a subflow that contains only the actions that require permissions beyond what the running user has, instead of setting the entire Screen Flow to run in system context |
| Platform | Flow | ✅ Specifying which fields will stored by a Flow running in system context Always specify which fields to store when using a Get Records element running in system context |
| Platform | Org | ✅ Generative AI operates only in user mode, or select uses for system access have clear business justification |
| Platform | Org | ✅ Organization-wide defaults (OWDs) for internal users is Public Read, or OWDs for internal users is Private, due to compliance requirements |
| Platform | Org | ✅ OWDs for external users is Private |

### Use of Encryption Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Data Security](/docs/architect/well-architected/guide/secure#data-security) → [Use of Encryption](/docs/architect/well-architected/guide/secure#use-of-encryption)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apex | ✅ If business needs require greater data protection in transit, all code involved in integration carries out logic using Crypto Class methods to encrypt data before transmission or decrypt data upon receipt |
| Platform | Design Standards | ✅ Use cases for data encryption in transit and (if needed) at rest are clear and discoverable |
| Platform | Design Standards | ✅ Approved encryption protocols are clearly listed |
| Platform | Documentation | ✅ Code documentation clearly indicates where encryption is used and what protocols are used |
| Platform | Org | ✅ If security risks are identified that require greater data protection at rest, either Hyperforce or Salesforce Shield provide encryption at rest |

### Sharing & Visibility Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Data Security](/docs/architect/well-architected/guide/secure#data-security) → [Sharing & Visibility](/docs/architect/well-architected/guide/secure#sharing-visibility)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Einstein | Bots | ⚠️ Flows initiated by a bot run in system context A Flow initiated by a bot runs in system mode. This can occur if you haven't enabled the Run Flows in Bot User Context update in the release update section of setup |
| Platform | Apex | ⚠️ With sharing keywords are used inconsistently |
| Platform | Documentation | ⚠️ Documentation does not exist or does not contain a security matrix |
| Platform | Documentation | ⚠️ If a security matrix exists, it does not outline data access for user personas |
| Platform | Flow | ⚠️ System context is used in screen flows surfaced to external users Entire screen flows use system context to surface data that external users do not have permissions to access through the sharing model |
| Platform | Flow | ⚠️ Store all fields when using a Get Records element in system context Choosing the "Automatically store all fields" option when configuring a Get Records element that will run in system context |
| Platform | Org | ⚠️ OWDs for internal users is set to Private without business justification or OWDs for internal users is set to Public Read/Write |
| Platform | Org | ⚠️ Generative AI operates in system mode without business justification |
| Platform | Org | ⚠️ OWDs for external users are set to anything other than Private without business justification |

### Use of Encryption Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Data Security](/docs/architect/well-architected/guide/secure#data-security) → [Use of Encryption](/docs/architect/well-architected/guide/secure#use-of-encryption)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ Business needs require greater data protection in transit, but code involved in integration carries out logic without encrypting data before transmission or upon receipt, or Crypto Class methods are used ad hoc |
| Platform | Design Standards | ⚠️ Approved encryption protocols are not clear or not listed |
| Platform | Design Standards | ⚠️ Code is not documented or documentation is unclear on where and how encryption is used in code |
| Platform | Org | ⚠️ Business needs require greater data protection at rest, but neither Hyperforce nor Salesforce Shield is used |
