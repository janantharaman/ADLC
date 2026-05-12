---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-session-security.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Secure — Session Security
---

### Device Access Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Session Security](/docs/architect/well-architected/guide/secure#session-security) → [Device Access](/docs/architect/well-architected/guide/secure#device-access)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Documentation | ✅ Security personas are clearly mapped to appropriate device usages and policies |
| Platform | Documentation | ✅ Device policies are clear and discoverable |
| Platform | Org | ✅ Salesforce mobile connected app configuration requires PIN/passcode unlock after inactivity |
| Platform | Org | ✅ If business needs require strict control of users who can access Salesforce mobile, API Access Control is enabled and permission sets are assigned to all users of Salesforce mobile apps |

### Session Management Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Session Security](/docs/architect/well-architected/guide/secure#session-security) → [Session Management](/docs/architect/well-architected/guide/secure#session-management)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apex | ✅ If custom login flows exist, all related custom code uses appropriate SessionManagement methods to assign session-level security |
| Platform | Aura | ✅ If custom login flows exist, use an Apex controller with the necessary `SessionManagement` methods to assign session-level security |
| Platform | Design Standards | ✅ Security personas clearly list approved session types and timeout/duration settings for each persona |
| Platform | Design Standards | ✅ Standards are defined for the activities that require elevated session-level security |
| Platform | Design Standards | ✅ Standards are defined for the activities that require elevated permissions to be assigned |
| Platform | Design Standards | ✅ Connected app scope and token management policies are clear and discoverable |
| Platform | Documentation | ✅ Connected app scope and token management policies are clear and discoverable |
| Platform | Documentation | ✅ Login hours have been specified (or identified as not needed) |
| Platform | Lightning Web Components (LWC) | ✅ If custom login flows exist, use an Apex controller with the necessary `SessionManagement` methods to assign session-level security |
| Platform | Org | ✅ If users access Salesforce from behind a firewall, the firewall uses an allowlist of required domains instead of IP addresses to secure communications to/from Salesforce |
| Platform | Org | ✅ Inactive session timeout intervals do not exceed the default (2 hours) |
| Platform | Org | ✅ All of the following settings are enabled: -Clickjack protection for Setup pages -Clickjack protection for non-Setup Salesforce pages -Cross-Site Request Forgery (CSRF) protection -Cross-Site Scripting (XSS) protection -Enable content sniffing protection -Referrer URL protection -Warn users before they are redirected outside of Salesforce |
| Platform | Org | ✅ Session audits show users only access Salesforce through expected session types |
| Platform | Org | ✅ There is a clear, active permission set for "API Only User" access (with "API Only" permission set to TRUE) and all integration and automated users are assigned |

### Threat Detection & Response Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Session Security](/docs/architect/well-architected/guide/secure#session-security) → [Threat Detection & Response](/docs/architect/well-architected/guide/secure#threat-detection-response)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Agents | ✅ Agent event logs include conversation data Enable the setting for enriched event logs, unless there is a critical reason why conversation data should be masked |
| Einstein | Einstein Trust Layer | ✅ Generative AI features are regularly audited Einstein Generative AI Audit Data is enabled from the Einstein Feedback setup page. Generative AI conversations, including the prompt and it's response, are regularly audited and reviewed |
| Platform | Company | ✅ Audit data is available in reports business stakeholders can understand and access |
| Platform | Company | ✅ Regular reviews of audit history and reports take place |
| Platform | Documentation | ✅ All automated responses are documented clearly |
| Platform | Documentation | ✅ Steps to review logs available within Salesforce are documented |
| Platform | Documentation | ✅ Audit levels have been specified for all objects in your data model |
| Platform | Documentation | ✅ Security policies contain a list of events that should trigger a response along with the appropriate response type |
| Platform | Org | ✅ Automations are in place to respond to threats by deactivating user accounts or blocking access to resources in real time if abnormal usage is detected |
| Platform | Org | ✅ Notifications and alerts are configured to notify appropriate users about anomalous activity |
| Platform | Org | ✅ Field History tracking is enabled for all fields containing private or sensitive data |

### Device Access Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Session Security](/docs/architect/well-architected/guide/secure#session-security) → [Device Access](/docs/architect/well-architected/guide/secure#device-access)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Documentation | ⚠️ Security policies do not exist or do not contain information about device access |
| Platform | Org | ⚠️ Salesforce mobile connected app is not configured to require PIN/passcode unlock for inactivity |
| Platform | Org | ⚠️ Business needs require strict control of users who can access Salesforce mobile, but API Access Control is not enabled or permission sets are not used to control access to Salesforce mobile apps |

### Session Management Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Session Security](/docs/architect/well-architected/guide/secure#session-security) → [Session Management](/docs/architect/well-architected/guide/secure#session-management)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ If custom login flows exist, there is no logic to assign session-level security |
| Platform | Aura | ⚠️ If custom login flows exist, there is no logic to assign session-level security |
| Platform | Design Standards | ⚠️ Standards are not defined for the activities that require elevated session-level security |
| Platform | Design Standards | ⚠️ Standards are not defined for the activities that require elevated permissions to be assigned |
| Platform | Design Standards | ⚠️ Security policies do not contain information about connected app scopes or token management |
| Platform | Design Standards | ⚠️ Security personas do not exist or lack information about session types and timeout/duration settings |
| Platform | Documentation | ⚠️ Connected app scope and token management policies are not documented |
| Platform | Lightning Web Components (LWC) | ⚠️ If custom login flows exist, there is no logic to assign session-level security |
| Platform | Org | ⚠️ There are no definitions of what session types users should have |
| Platform | Org | ⚠️ "API Only" permissions are unclear or missing from integration and automated users |
| Platform | Org | ⚠️ There is no regular session auditing |
| Platform | Org | ⚠️ If users access Salesforce from behind a firewall, the firewall uses hard-coded IP addresses to secure communications to/from Salesforce |
| Platform | Org | ⚠️ Inactive session timeout intervals exceed the default (2 hours) |
| Platform | Org | ⚠️ Any of the following settings are disabled: -Clickjack protection for Setup pages -Clickjack protection for non-Setup Salesforce pages -Cross-Site Request Forgery (CSRF) protection -Cross-Site Scripting (XSS) protection -Enable content sniffing protection -Referrer URL protection -Warn users before they are redirected outside of Salesforce |

### Threat Detection & Response Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Secure](/docs/architect/well-architected/guide/secure) → [Session Security](/docs/architect/well-architected/guide/secure#session-security) → [Threat Detection & Response](/docs/architect/well-architected/guide/secure#threat-detection-response)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Einstein | Org | ⚠️ Generative AI features are not audited Generative AI conversations, including the prompt and it's response, are not regularly audited and reviewed |
| Platform | Company | ⚠️ Audit data is only available through log files that require subject matter expertise to access and interpret |
| Platform | Company | ⚠️ No processes exist to review auditing information |
| Platform | Documentation | ⚠️ Security policies do not exist or do not include information about threat detection and alerting |
| Platform | Documentation | ⚠️ Documentation for automated responses does not exist or is unclear |
| Platform | Org | ⚠️ There are no automations in place to respond to threats |
| Platform | Org | ⚠️ Notifications and alerts are either not configured to notify appropriate users about anomalous activity, or some notifications and alerts related to anomalous activity exist, but they are ad hoc |
| Platform | Org | ⚠️ Field History tracking is not consistently enabled for fields containing private or sensitive data |
