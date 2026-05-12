---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-organizational-security.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Secure — Organizational Security
---

### Authentication Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Organizational Security](/docs/architect/well-architected/guide/secure#organizational-security) → [Authentication](/docs/architect/well-architected/guide/secure#authentication)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apex | ✅ Methods that execute authentication use named credentials to handle username/password flows |
| Platform | Apex | ✅ No usernames or passwords appear in code in readable formats (no hard-coded values or strings) |
| Platform | Apex | ✅ If custom login flows exist, all related custom Apex uses appropriate `SessionManagement` methods |
| Platform | Aura | ✅ No usernames or passwords appear in code in readable formats (no hard-coded values or strings) |
| Platform | Aura | ✅ Methods that execute authentication use named credentials to handle username/password flows |
| Platform | Documentation | ✅ Approved security personas are clearly defined and listed |
| Platform | Documentation | ✅ Mapping between security personas and allowed authentication schemes (UI, API) exist in a security matrix |
| Platform | Lightning Web Components (LWC) | ✅ Methods that execute authentication use named credentials to handle username/password flows |
| Platform | Lightning Web Components (LWC) | ✅ No usernames or passwords appear in code in readable formats (no hard-coded values or strings) |
| Platform | Org | ✅ API Access Control prevents users from authenticating via an unauthorized connected app |
| Platform | Org | ✅ The relationship between users and entities logging into Salesforce is 1:1 (no shared users) |
| Platform | Org | ✅ Login configurations align to the Salesforce MFA Check |
| Platform | Org | ✅ If SSO is enabled, approved admin users have direct login access |
| Platform | Org | ✅ Login Forensics is used when login history must be stored for more than 6 months Use Login Forensics when login history retention is required to be stored for 6 months-10 years |

### Authorization Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Organizational Security](/docs/architect/well-architected/guide/secure#organizational-security) → [Authorization](/docs/architect/well-architected/guide/secure#authorization)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Bots | ✅ A unique bot user is configured for each business use case In the Einstein Bot Builder Overview section of a bot configuration, the bot user selected provides only the minimum amount of access needed to carry out the business purpose the bot is designed to achieve, following the principle of least privilege |
| Platform | Apex | ✅ DB operations perform field-level and object-level access checks appropriately DML and Database DML statements declare user or system mode for data operations AND/OR DML and Database DML statements use `stripInaccessible` methods before data operations |
| Platform | Apex | ✅ DB operations perform field-level and object-level access checks appropriately SOQL and SOSL statements use `WITH USER_MODE` and `WITH SYSTEM_MODE` keywords AND/OR `stripInaccessible` methods are used to filter query and subquery results |
| Platform | Apex | ✅ Database operations perform field- and object-level access checks appropriately sObject describe result methods (i.e. `isAccessible`, `isCreateable`, `isUpdateable`, and/or `isDeletable`) are used sparingly |
| Platform | Design Standards | ✅ Use cases for granting elevated privileges are clearly listed Including: - Modify All Data permissions - View All Data permissions |
| Platform | Documentation | ✅ Every user and system with access to Salesforce maps to one or more personas in a security matrix |
| Platform | Documentation | ✅ The security matrix clearly lists metadata permissions and assigned user personas |
| Platform | Org | ✅ Permission sets and permission set groups are used to control access to metadata |
| Platform | Org | ✅ Permission sets and permission set groups align to business capabilities |
| Platform | Org | ✅ A unique API only integration user is configured for every integration |
| Platform | Org | ✅ Profiles are used minimally and only to control login IP ranges and login hours |
| Platform | Org | ✅ Permissions assigned to users follow security matrix definitions |

### Authentication Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Organizational Security](/docs/architect/well-architected/guide/secure#organizational-security) → [Authentication](/docs/architect/well-architected/guide/secure#authentication)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ Usernames and passwords appear in code |
| Platform | Apex | ⚠️ If custom login flows exist, there is no logic to assign session-level security |
| Platform | Apex | ⚠️ Authentication is handled ad hoc |
| Platform | Aura | ⚠️ Authentication is handled ad hoc |
| Platform | Aura | ⚠️ Usernames and passwords appear in code |
| Platform | Business | ⚠️ User provisioning and deprovisioning SLAs and requirements do not exist |
| Platform | Documentation | ⚠️ Does not include security personas |
| Platform | Documentation | ⚠️ Security matrix does not have clear mappings for security personas and allowed authentication schemes |
| Platform | Lightning Web Components (LWC) | ⚠️ Authentication is handled ad hoc |
| Platform | Lightning Web Components (LWC) | ⚠️ Usernames and passwords appear in code |
| Platform | Org | ⚠️ API Access Control is not enabled |
| Platform | Org | ⚠️ If users access Salesforce from behind a firewall, the firewall uses hard-coded IP addresses to secure communications to/from Salesforce |
| Platform | Org | ⚠️ The relationship between users and entities logging into Salesforce is not 1:1 (there are shared user accounts) |
| Platform | Org | ⚠️ If SSO is enabled, no approved admin users have direct login access |
| Platform | Org | ⚠️ Login configurations do not align to the Salesforce MFA Check |
| Platform | Org | ⚠️ Legacy Named Credentials are used to authenticate to external systems Using Legacy Named Credentials to specify the URL of a callout endpoint and its required authentication parameters |

### Authorization Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Organizational Security](/docs/architect/well-architected/guide/secure#organizational-security) → [Authorization](/docs/architect/well-architected/guide/secure#authorization)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Einstein | Bots | ⚠️ Einstein Bots use the Basic Chatbot User or a "generic" bot user In the Einstein Bot Builder Overview section of a bot configuration, the Bot User selected is the Basic Chatbot User or a "generic" Custom Chatbot User that is shared across bots that are used for different business purposes |
| Platform | Apex | ⚠️ DML, Database Class methods, SOQL and SOSL run in default system mode |
| Platform | Apex | ⚠️ Database operations do not perform access checks appropriately SOQL queries exclusively use `WITH SECURITY_ENFORCED` keywords for access restrictions |
| Platform | Apex | ⚠️ Database operations do not perform access checks appropriately DML or Database Class methods exclusively use `isAccessible`, `isCreateable`, `isUpdateable`, and/or `isDeletable` checks for sObject and field-level access |
| Platform | Design Standards | ⚠️ Use cases for granting elevated permissions are not clearly listed Including: - Modify All Data permissions - View All Data permissions |
| Platform | Documentation | ⚠️ Does not clearly list metadata permissions and assigned personas |
| Platform | Documentation | ⚠️ Documentation does not include a security matrix |
| Platform | Org | ⚠️ Permissions assigned to users do not follow security matrix definitions |
| Platform | Org | ⚠️ Profiles contain access controls for metadata |
| Platform | Org | ⚠️ Permission sets are configured ad hoc |
| Platform | Org | ⚠️ Permission set groups are not configured to allow for access based on business capabilities |
| Platform | Org | ⚠️ API only users are not configured or are shared across more than one integration |
| Platform | Org | ⚠️ Permission sets are redundant or are heavily duplicated; it is difficult to understand clear functional logic and differences between sets |
