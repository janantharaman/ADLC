---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/secure.html
date_fetched: 2026-05-01
section: well-architected
page_title: Secure
---

> Read about our update scheduleshere.

## Introduction

A secure system protects an organization’s stakeholders and data. Secure architectures verify user identities, restrict data access to only necessary information, and prevent data compromise.

Salesforce prioritizes customer trust and data security. The Salesforce Platform ensures privacy and security. Real-time system performance and security information is available at [Salesforce Trust](https://trust.salesforce.com/).

Protecting your org and customer data is the foundation of building secure Salesforce solutions. As a Salesforce architect, you are responsible for securing your org and customer data by utilizing Salesforce's built-in security features. Consider geographic distribution, industry, company operating procedures, and customer data types when making these decisions.

You can make your solutions more secure by focusing on three areas: organizational security, session security, and data security.

## Organizational Security

Organizational security safeguards systems from unauthorized access by ensuring only validated, authorized users can access a system, and only necessary features and data.

Signs that you have problematic organizational security include:

- Ad hoc processes to activate or deactivate users
- Unclear steps to update authorization for user or system role changes
- Reliance on the institutional knowledge of individuals for correct user security assignments
- Failure to align with established security frameworks or industry best practices
- Absence of a structured data governance framework and supporting policies

You can build better organizational security controls for your Salesforce orgs by focusing on authentication and authorization.

### Authentication

Authentication is crucial for security and access management, verifying the identity of users attempting to access your system. This applies to both human users (employees, customers) and automated users (external systems, integrations), with each user type requiring specific authentication schemes. To ensure secure access across all Salesforce entry points in your org, you'll need to set up various authentication methods.

To create secure authentication flows in Salesforce:

- **Create Salesforce users based on individuals, not personas**. Salesforce’s built-in auditing capabilities are most effective when each user account corresponds to a single individual accessing the platform. The use of shared user accounts compromises the effectiveness of these audits, introduces additional security vulnerabilities, escalates the potential impact of account breaches, and complicates your ability to create effective authorization schemes. This includes user accounts for integration users.
- **Secure UI-based access scenarios**. Most human users require some kind of UI-based access (often called login access) for a Salesforce org. Salesforce provides several layers of protection for these login scenarios, including:

Password policies. Cybercriminals often target usernames and passwords to gain unauthorized access to applications. While configuring password policies is a fundamental step in protecting login access, it’s important to note that this alone isn’t enough, as Salesforce allows for per-user overrides of these policies.
Multi-factor authentication (MFA). Salesforce requires MFA for all UI-based user logins. MFA provides an essential defense against credential leaks and brute-force attacks by requiring users to provide an additional form of identification, or factor, after successfully entering their username and password. This additional factor typically takes a physical form, such as a mobile device, security key, or biometric marker.
Single-sign on (SSO). In SSO scenarios, users only use one set of credentials across an organization's applications. Access to systems is provisioned and managed from a central location, which improves security. Salesforce can act as a service provider or an identity provider in SSO scenarios. Be sure to allow some or all admins to log in directly to Salesforce so they can address outages or issues with your SSO implementation.
Post-login steps. For some use cases, you might require users to complete additional steps before accessing your system. Custom login flows can be implemented to guide users through these extra process steps. Examples include:

Accepting terms and conditions
Working through login discovery and passwordless login scenarios
Limiting the number of simultaneous Salesforce sessions per user to reduce the likelihood of session-based attacks (see session security).
Connecting to geofencing services
- **Secure API-based access scenarios**. Any user can request API-based access for a Salesforce org. Salesforce provides several layers of protection for API-based scenarios, including:

API Access Control. Without API access control, anyone with a valid set of credentials can leverage any app to connect with your org — even if the connected app is not deployed in the org. Data access controls will still be enforced, but users could access information in uncontrolled ways. For example, an app could be used to download large volumes of data, or even upload corrupted information, without a system administrator’s approval.
API Only permissions. You can configure API Only user permissions in Salesforce. Assign this as part of a permission set to any automated or integration user personas to block UI-based access entirely.
Certificates and keys. Certificates and keys enable Salesforce to validate that requests originate from authorized businesses or companies. You will need to configure certificates and keys if you want to use SSO with Salesforce.
Connected apps. Configuring connected apps in Salesforce enables you to control external system access to Salesforce, including required authentication protocols, authorization scope, and session behavior in a single definition.
Named credentials. Named credentials enable you to control external access points and authentication protocols in a single definition within Salesforce. Use them to securely define and manage authentication for callouts from Apex, external services, and Salesforce Connect data sources.
- **Agentforce Agent Users Authentication**. Agentforce agents, built on Salesforce, use agent-user objects with manageable permissions just like those of real users. When setting up an agent, carefully align access with the role the agent plays, limiting data access to only what’s required to serve the end users. Just as important, agents can be configured with both public and private actions. For private actions, validate and authenticate end users, mapping them to agent context. This allows the Agent to impersonate and operate within the end user’s access controls, maintaining security and trust.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#organizational-security-patterns-and-anti-patterns) below shows what proper (and poor) authentication architecture looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about authentication tools available from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Authorization

Authorization defines what features, functionality, and data a user can access, as well as the actions they can perform with those resources, after they’ve been [authenticated](/docs/architect/well-architected/guide/secure#authentication). Authorization controls are not just for human users, they also need to be tailored for Agentforce Agent Users, especially Agents providing services to unauthenticated end users.

While restricting who can authenticate into your org is a crucial first step, it’s equally vital to pair strong authentication with robust authorization. Without adequate authorization controls, users could potentially create, edit, and delete records or access system functionality in ways that are harmful to your business and your stakeholders. Inadequate authorization control can also make systems harder to use. By controlling what users can do within the system, you foster higher levels of trust, safeguarding both your system and your users.

To build secure authorization schemes for Salesforce:

- **Follow the principle of least privilege**. Embrace the principle of least privilege (PoLP) by assigning users only the necessary permissions for their tasks. To follow this principle, design granular and modular permission sets. This allows for sophisticated access controls through permission set groups, enabling precise management of permissions, including the ability to [mute](https://help.salesforce.com/s/articleView?id=sf.perm_set_groups_muting.htm&type=5), [set expiration dates](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_permissions_assn_expiration.htm&type=5&release=238), and more. Align your systems [functional units](/docs/architect/well-architected/guide/composable#functional-units) with business capabilities to define granular permissions and effective permission set groups. Remember that permissions apply to *metadata* access in Salesforce. For details about configuring PoLP for Salesforce *data* access, see [Sharing and Visibility](/docs/architect/well-architected/guide/secure#sharing-and-visibility).
- **Think about user access in terms of personas, not individuals**. Thinking of authorization (or security in general) in terms of individual users will not set your system up to scale and evolve. Instead, design for and manage personas that represent groups of users. Secure Salesforce solutions use individuals for authentication, and personas for authorization. By defining security configurations for distinct personas, you gain granular control over access and privileges in your security model, which minimizes the need for refactoring in the long run. Include the security personas you define in your [design standards and documentation](/docs/architect/well-architected/guide/intentional#readability).
- **Control user access to metadata using permission sets and permission set groups**. Permission sets and permission set groups govern what metadata users can access and what they can do with that metadata. To learn more about Salesforce metadata, see [Metadata versus Data](/docs/architect/fundamentals/guide/architecture-basics#metadata-versus-data). Configure app assignments, feature license activations, managed package access, system permissions, [CRUD](https://developer.salesforce.com/docs/atlas.en-us.214.0.lightning.meta/lightning/apex_crud_fls.htm) access, and field-level access via permission sets and permission set groups. Include this access in your [design standards and documentation](/docs/architect/well-architected/guide/intentional#readability).
- **Use organization-wide defaults (OWDs) and sharing to control data access for users**. [Data and metadata](/docs/architect/fundamentals/guide/architecture-basics#metadata-versus-data) are distinct entities in Salesforce, requiring separate access controls for each. Use OWDs and built-in sharing tools to configure access for Salesforce data (individual records, files, and docs). For more details, see [Data Security](/docs/architect/well-architected/guide/secure#data-security).
- **Use OAuth scopes to control access for connected apps**. When configuring a connected app, you define the [scope](https://help.salesforce.com/s/articleView?id=remoteaccess_oauth_tokens_scopes.htm&type=5&language=en_US), or access permissions that app users will have to Salesforce resources. For more about managing OAuth tokens, see [Session Management](/docs/architect/well-architected/guide/secure#session-management).
- **Create one Salesforce user for every integration**. To adhere to the principle of least privilege, create a unique Salesforce [integration user](https://help.salesforce.com/s/articleView?id=sf.integration_user.htm) for each integration. This allows you to assign specific data access, improving control over operations, ensuring transaction traceability, and minimizing the impact of potential security breaches.
- **Implement unique accounts with the PoLP for all Agent users**. Each Agentforce Agent User should be unique and not reused across multiple Agents. Permissions for these accounts must strictly adhere to the principle of least privilege. Keep in mind that Actions executed by an Agent User may operate in an elevated security context within Salesforce or against external systems that do not respect Salesforce access controls. This could lead to Actions accessing or revealing sensitive information to users.
- **Minimize the use of profiles and migrate any access controls out of profiles**. Profiles provide the ability to limit access to [login IP ranges](https://help.salesforce.com/s/articleView?id=sf.security_networkaccess.htm&type=5), [login hours](https://help.salesforce.com/s/articleView?id=sf.login_hours.htm&type=5), and features specific to the legacy Salesforce Classic user interface (specifically default record types and page layout assignments). Any other functionality currently in profiles should be migrated to equivalent functionality in [permission sets and permission set groups](https://help.salesforce.com/s/articleView?id=sf.perm_set_groups_create_with_perm_sets.htm). Functionality in your profiles tied to Salesforce Classic UI features should be targeted for remediation.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#organizational-security-patterns-and-anti-patterns) below shows what proper (and poor) authorization practices looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about authorization tools available from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Organizational Security Patterns and Anti-Patterns

This table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for organizational security in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-organizational-security).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Authentication** | **In your design standards and documentation:**

 - Approved security personas are clearly defined and listed
            
 - Mapping between security personas and allowed authentication schemes (UI, API) exist in a security matrix | **If design standards and documentation exist, they:**

 - Do not include security personas
            
 - Do not include a security matrix with clear mappings for security personas and allowed authentication schemes |
| **In your org:**

 - Login configurations align to the [Salesforce MFA Check](https://security.salesforce.com/mfa-requirement-check)

 - The relationship between users and entities logging into Salesforce is 1:1 (no shared users)
            
 - [API Access Control](https://help.salesforce.com/s/articleView?language=en_US&type=5&id=sf.security_api_access_control_about.htm) prevents users from authenticating via an unauthorized connected app
            
 - If SSO is enabled, approved admin users have direct login access | **In your org:**

 - Login configurations do not align to the [Salesforce MFA Check](https://security.salesforce.com/mfa-requirement-check)

 - The relationship between users and entities logging into Salesforce is not 1:1 (there are shared user accounts)
            
 - If users access Salesforce from behind a firewall, the firewall uses hard-coded IP addresses to secure communications to/from Salesforce
            
 - [API Access Control](https://help.salesforce.com/s/articleView?language=en_US&type=5&id=sf.security_api_access_control_about.htm) is not enabled
            
 - If SSO is enabled, no approved admin users have direct login access |  |
| **In LWC, Apex, Aura:**

 - Methods that execute authentication use named credentials to handle username/password flows
            
 - No usernames or passwords appear in code in readable formats (no hard-coded values or strings)
            
 - If custom login flows exist, all related custom code uses appropriate `SessionManagement` methods | **In LWC, Apex, Aura:**

 - Authentication is handled ad hoc
            
 - Usernames and passwords appear in code |  |
| **Authorization** | **In your design standards and documentation:**

 - Every user and system with access to Salesforce maps to one or more personas in a security matrix
            
 - The security matrix clearly lists metadata permissions and assigned user personas
            
 - Use cases for granting elevated privileges are clearly listed, including:
            
 -- Modify All Data permissions
            
 -- View All Data permissions | **If design standards and documentation exist, they:**

 - Do not include a security matrix
            
 - Do not clearly list permissions
            
 - Do not clearly list use cases for granting elevated privileges |
| **In your org:**

 - Permission sets and permission set groups are used to control access to metadata
            
 - Permission sets and permission set groups align to business capabilities
            
 - Permissions assigned to users follow security matrix definitions
            
 - Profiles are used minimally and only to control login IP ranges and login hours
            
 - A unique API-only integration user is configured for every integration | **In your org:**

 - Permission set groups are not configured to allow for access based on business capabilities
            
 - Permission sets are configured ad hoc
            
 - Permission sets are redundant or are heavily duplicated; it is difficult to understand clear functional logic and differences between sets
            
 - Permissions assigned to users do not follow security matrix definitions
            
 - Profiles contain access controls for metadata
            
 - API only users are not configured or are shared across more than one integration |  |
| **In Apex:**

 - Database operations perform field- and object-level access checks appropriately, including:
            
 -- DML and Database DML statements declare [user or system mode](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_enforce_usermode.htm) for data operations AND/OR
            
 -- DML and Database DML statements use `stripInaccessible` methods before data operations
            
 -- SOQL and SOSL statements use `WITH USER_MODE` and `WITH SYSTEM_MODE` keywords AND/OR
            
 -- `stripInaccessible` methods are used to filter query and subquery results
            
 -- sObject describe result methods (i.e. `isAccessible`, `isCreateable`, `isUpdateable`, and/or `isDeletable`) are used sparingly | **In Apex:**

 - DML, Database Class methods, SOQL and SOSL run in default system mode
            
 - Database operations do not perform access checks appropriately, including:
            
 -- DML or Database Class methods exclusively use `isAccessible`, `isCreateable`, `isUpdateable`, and/or `isDeletable` checks for sObject and field-level access
            
 -- SOQL queries exclusively use `WITH SECURITY_ENFORCED` keywords for access restrictions |  |
| **In Flows**[(Security Considerations for Flow Design)](https://developer.salesforce.com/docs/atlas.en-us.secure_coding_guide.meta/secure_coding_guide/secure_coding_considerations_flow_design.htm)**:**

 - Flows use the most restrictive Execution Context possible, ideally User Mode
            
 - Security sensitive or privileged data access is performed by Subflows to minimize execution context
            
 - Limit logic performed in Record-triggered flows
            
 - Flow inputs are validated to ensure only permitted payloads are passed as input | **In Flows:**

 - Flows run in either System Mode or System Mode Without Sharing, regardless of what actions the flow performs
            
 - All flow logic is performed within a single, large flow
            
 - Flow inputs are not validated and are passed to consumers without verification |  |

## Session Security

A session is the series of requests and responses associated with a user over a period of time. A session is initiated when a user successfully authenticates into Salesforce. [Session security](https://help.salesforce.com/s/articleView?language=en_US&type=5&id=sf.security_overview_sessions.htm) is the practice of configuring your system to prevent unauthorized access and data breaches by thwarting session interference or hijacking.

All user activity in your system occurs within the context of a session, so it’s critical to account for how sessions are initiated, what can take place during a session, what devices users will (and should) employ, and how to detect and respond to suspicious or anomalous session behaviors.

You can build session security in Salesforce by focusing on three keys: session management, device access, and threat detection and response.

### Session Management

Sessions are initiated when a user successfully authenticates and gains access to Salesforce. These sessions enable the platform to associate specific requests and responses with that particular user.

HTTPS protocol facilitates communication between a front-end client and the Salesforce Platform. Clients can include browsers, mobile applications, local applications, and so on. HTTPS is a stateless protocol, which means that every communication is discrete and unrelated to any previous or future communications.

This stateless approach accelerates network communications and eliminates errors caused by broken links between packets. However, web apps still need a way to keep track of each user’s identity and other related information across multiple request and response interactions. Salesforce, like most web applications, accomplishes this using sessions and [tokens](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_tokens_scopes.htm&type=5).

- **Sessions** enable Salesforce to associate requests and responses with users. After a user is authenticated, the platform sends a session ID back to the client app, which includes this ID with any user requests (such as navigating, searching, and submitting data).
- **Tokens** enable users and connected applications to verify their identity once and use a unique access token from then on. Tokens have a limited lifespan and only provide access to specific resources (see [Authorization](/docs/architect/well-architected/guide/secure#authorization) for more about configuring access levels). Tokens allow access to authorized resources without requiring users to login.

If sessions and tokens aren't secured properly, bad actors can potentially interfere with them and impersonate users or execute malicious code in your system.

To build secure session management for Salesforce:

- **Understand how Salesforce classifies session types**. Identify and map approved [session types](https://help.salesforce.com/s/articleView?id=sf.security_session_types.htm&type=5) to security user personas, and record these in your documentation.
- **Control how sessions can originate and where session traffic can go**. Once you've identified the kinds of sessions various user personas are allowed to initiate, configure controls to block sessions that originate from unapproved sources or contexts. Salesforce provides several ways to control session origins and traffic, including:

Built-in session protection. Salesforce automatically enables org-wide protections for session-based malicious activity, including cross-site scripting, cross-site request forgery, content sniffing, clickjacking and more. These protections should never be disabled; some cannot be disabled.
Domains and IP ranges. All Salesforce orgs have My Domain enabled by default, which creates a company-specific subdomain for Salesforce access. You can customize or change the name associated with an org through My Domain. Further, Salesforce supports additional domain configurations for Experience Cloud sites and other application pages. Note: If your users need to access Salesforce from behind a company firewall, add the required domains to your firewall allowlists. You can set up login IP ranges and trusted IP ranges to control inbound login and session requests to Salesforce.
Login hours. If certain user personas have set working hours, you can restrict their ability to access Salesforce outside of defined login hours.
- **Control activities that require added session-level security**. By default, sessions can have two kinds of [security levels](https://help.salesforce.com/s/articleView?id=sf.security_overview_sessions.htm&type=5): standard and high-assurance. Use these security levels to control how users can and cannot carry out activities such as accessing reports and dashboards, or managing the security configurations in a Salesforce org. Session-level security policies can require users to establish [high-assurance sessions](https://help.salesforce.com/s/articleView?id=sf.security_auth_require_ha_session.htm&type=5) to carry out operations or block users from carrying out any sensitive operations at all.
- **Control activities that require added session-based permissions**. Salesforce supports [session-based permission](https://help.salesforce.com/s/articleView?id=sf.perm_sets_session_use.htm&type=5) activations to temporarily allow users elevated authorization or access to permissions during a particular session. You can activate and deactivate session-based permissions via Flow or Salesforce APIs.
- **Manage inactive user sessions through timeouts**. Ending inactive sessions is a key part of managing session security. This helps protect your system when, for example, a user leaves a Salesforce session open in a browser tab but is actively working in another application, or when a user’s mobile device is logged into Salesforce, but is unattended. Salesforce has a default session inactivity timeout of two hours. You can increase or decrease session inactivity timeout levels, but increasing timeouts should only be done with a compelling and well-documented justification.
- **Manage connected app sessions through token configuration.** When you configure a connected app, you also define the scope, or level of authorization, that will be granted to users accessing Salesforce through the connected app. This scope is enforced at the session level through [OAuth tokens](https://help.salesforce.com/s/articleView?id=remoteaccess_oauth_tokens_scopes.htm&type=5&language=en_US), which are issued after a user of a connected app successfully authenticates. You can control how long a token should last through [token refresh policies](https://help.salesforce.com/s/articleView?id=remoteaccess_oauth_tokens_scopes.htm&type=5&language=en_US). Org administrators can manually revoke tokens on a per-user and per-org basis, if needed.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#session-security-patterns-and-anti-patterns) below shows what proper (and poor) session management looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about session management tools available from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Device Access

In the current context, a *device* is any piece of electronic equipment that an individual will use to access Salesforce, such as a desktop workstation, laptop, tablet, or mobile phone.

Portable devices offer users the flexibility to access Salesforce from any location. However, this convenience potentially introduces additional attack vectors for malicious actors. These threat vectors range from simple tactics, such as shoulder surfing in a public place to steal credentials, to more sophisticated methods like installing malware on a device or creating a phony public Wi-Fi network to intercept data transmissions. Because of this, securing devices — especially portable devices — is essential to overall system security.

To secure device access for Salesforce:

- **Use the mobile app solutions provided by Salesforce**. Have users on mobile devices who need to access Salesforce use the official [Salesforce apps available for iOS and Android](https://help.salesforce.com/s/articleView?id=sf.mobile_security.htm&type=5). If business needs require a custom mobile solution, you should use the [Salesforce Mobile SDK](https://developer.salesforce.com/docs/atlas.en-us.mobile_sdk.meta/mobile_sdk/intro.htm), which provides methods for secure authentication and authorization.
- **Design mobile device usage into your session management**. Session security levels, session timeouts, and other session context controls should take into account any anticipated access from users on mobile devices. Consider what devices should and should not be allowed to access Salesforce, and what kinds of users should have access to mobile sessions. Include mobile access standards in your security persona documentation. For more on this topic, see [Session Management](/docs/architect/well-architected/guide/secure#session-management).
- **Supplement device-level security with Mobile Device Management (MDM) technology.** The Salesforce apps for iOS and Android are [compatible with many popular MDM suites](https://help.salesforce.com/s/articleView?id=sf.mobile_security_mdm.htm&type=5). You can configure additional access controls for the Salesforce app on user devices through your preferred MDM solution.
- **Supplement app-level security with Mobile Application Management (MAM) technology**. MAM technology supports app-level controls on mobile devices. Salesforce offers a paid [MAM add-on](https://help.salesforce.com/s/articleView?id=sf.mobile_security_mam_overview.htm&type=5) for Salesforce mobile apps.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#session-security-patterns-and-anti-patterns) below shows what proper (and poor) device management looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about device management tools available from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Threat Detection and Response

Threat detection is the process of identifying behavior patterns in your system that may indicate malicious activity. This can include larger than average volumes of data being downloaded or a user modifying fields containing sensitive data on several records within a shorter than average period of time. Responses to threats can include automated session expiration, alerting, and other notifications.

The goal of threat detection is to identify and respond to potential issues as quickly as possible. Taking action based on real-time threat detection can stop malicious behavior in its tracks. Salesforce offers [real-time event monitoring](https://help.salesforce.com/s/articleView?id=sf.real_time_event_monitoring_overview.htm&type=5) as an add-on or as part of [Salesforce Shield](https://www.salesforce.com/products/platform/products/shield/). Use one of these solutions if you have highly sensitive applications or require robust real-time threat detection and response capabilities.

To build an effective threat detection and response strategy for your Salesforce solutions:

- **Use built-in audit capabilities**. Salesforce offers a variety of [built-in tools](https://help.salesforce.com/s/articleView?id=sf.monitoring_admin.htm&type=5) to help track and audit changes to your org. For example, the [Setup Audit Trail](https://help.salesforce.com/s/articleView?id=sf.admin_monitorsetup.htm&type=5) allows you to view the audit history of administrative actions. Salesforce tracks field-level changes for a limited period of time by default, but you can activate [Field History Tracking](https://help.salesforce.com/s/articleView?id=sf.tracking_field_history.htm&type=5) to display field changes for up to 18 months in the UI and up to 24 months via the API. Additionally, you can activate [Field Audit Trail](https://help.salesforce.com/s/articleView?id=sf.field_audit_trail.htm&type=5) to retain an audit history for field-level changes indefinitely (until you manually delete the data).
- **Establish regular audit reviews**. Auditing is crucial for identifying anomalous changes that real-time threat detection might miss. Consider a scenario where a user with legitimate access consistently deletes a small number of records daily over an extended period. Since this user has valid login credentials, proper authorization to delete records, and isn’t deleting a large volume of records at once, the activity is unlikely to be detected as a real-time threat. However, an audit team reviewing user activity reports would clearly identify this trend of excessive record deletion by a single user over time, making it easier to address. As part of your [governance policies](/docs/architect/well-architected/guide/intentional#governance), establish regular intervals for auditing login history, user session activity, and connected app usage.
- **Develop a threat response strategy and include it in your security policies**. Create a threat response strategy that covers:

Threat response type definitions (for example, alerts and automations) and any stakeholder groups that should be involved. For more on designing messages or alerts, see Errors and Notifications.
Specific categories for real-time changes or activities that could be considered threats and the associated response type for each
A clear list of all automated threat responses (such as revoking tokens, ending sessions, deactivating user accounts, or blocking access to resources) and automation triggers

Event Monitoring provides the data necessary to enforce this principle by enabling real-time threat detection and response. Transaction Security applies your company’s policy-driven actions, and event types support the monitoring of user and application access over time.

Salesforce's native Threat Detection service uses statistical and machine learning models to identify suspicious behavior. This service generates specific events that guard against cyber attacks and suspicious data access.

Transaction Security takes security a step further since it provides a framework that intercepts key events happening in your org and applies your company’s policy-driven actions. This transforms Event Monitoring from a logging tool into an important component of an automated security defense.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#session-security-patterns-and-anti-patterns) below shows what proper (and poor) threat detection and response looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about threat detection, alerting, and response automation tools available from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Session Security Patterns and Anti-Patterns

This table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for session security in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-session-security).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Session Management** | **In your design standards and documentation:**

 - Security personas clearly list approved session types and timeout/duration settings for each persona
            
 - Login hours have been specified (or identified as not needed)
            
 - Operations requiring elevated session-level security or permissions are clear and discoverable
            
 - Connected app scope and token management policies are clear and discoverable | **In your design standards and documentation:**

 - Security personas do not exist or lack information about session types and timeout/duration settings
            
 - Security policies do not contain information about connected app scopes or token management |
| **In your org:**

 - Session audits show users only access Salesforce through expected session types
            
 - There is a clear, active permission set for "API Only User" access (with "API Only" permission set to TRUE) and all integration and automated users are assigned
            
 - If users access Salesforce from behind a firewall, the firewall uses an allowlist of required domains instead of IP addresses to secure communications to/from Salesforce
            
 - Inactive session timeout intervals do not exceed the default (2 hours)
            
 - All of the following settings are enabled:
            
 -- Clickjack protection for Setup pages
            
 -- Clickjack protection for non-Setup Salesforce pages
            
 -- Cross-Site Request Forgery (CSRF) protection
            
 -- Cross-Site Scripting (XSS) protection
            
 -- Enable content sniffing protection
            
 -- Referrer URL protection
            
 -- Warn users before they are redirected outside of Salesforce | **In your org:**

 - There is no regular session auditing
            
 - There are no definitions of what session types users should have
            
 - "API Only" permissions are unclear or missing from integration and automated users
            
 - If users access Salesforce from behind a firewall, the firewall uses hard-coded IP addresses to secure communications to/from Salesforce
            
 - Inactive session timeout intervals exceed the default (2 hours)
            
 - Any of the following settings are disabled:
            
 -- Clickjack protection for Setup pages
            
 -- Clickjack protection for non-Setup Salesforce pages
            
 -- Cross-Site Request Forgery (CSRF) protection
            
 -- Cross-Site Scripting (XSS) protection
            
 -- Enable content sniffing protection
            
 -- Referrer URL protection
            
 -- Warn users before they are redirected outside of Salesforce |  |
| **In LWC, Apex, Aura:**

 - If custom login flows exist, all related custom code uses appropriate `SessionManagement` methods to assign session-level security | **In LWC, Apex, Aura:**

 - If custom login flows exist, there is no logic to assign session-level security |  |
| **Device Access** | **In your design standards and documentation:**

 - Device policies are clear and discoverable
            
 - Security personas are clearly mapped to appropriate device usages and policies | **In your design standards and documentation:**

 - Security policies do not exist or do not contain information about device access |
| **In your org:**

 - Salesforce mobile connected app configuration requires PIN/passcode unlock after inactivity
            
 - If business needs require strict control of users who can access Salesforce mobile, API Access Control is enabled and permission sets are assigned to all users of Salesforce mobile apps | **In your org:**

 - Salesforce mobile connected app is not configured to require PIN/passcode unlock for inactivity
            
 – Business needs require strict control of users who can access Salesforce mobile, but API Access Control is not enabled or permission sets are not used to control access to Salesforce mobile apps |  |
| **Threat Detection and Response** | **In your design standards and documentation:**

 - Security policies contain a list of events that should trigger a response along with the appropriate response type
            
 - Audit levels have been specified for all objects in your data model
 - Steps to review logs available within Salesforce are documented
            
 - All automated responses are documented clearly | **In your design standards and documentation:**

 - Security policies do not exist or do not include information about threat detection and alerting
            
 - Documentation for automated responses does not exist or is unclear |
| **Within your company:**

 - Audit data is available in reports business stakeholders can understand and access
            
 - Regular reviews of audit history and reports take place | **Within your company:**

 - Audit data is only available through log files that require subject matter expertise to access and interpret
            
 - No processes exist to review auditing information |  |
| **In your org:**

 - Automations are in place to respond to threats by deactivating user accounts or blocking access to resources in real time if abnormal usage is detected
            
 - Notifications and alerts are configured to notify appropriate users about anomalous activity
            
 - Field History tracking is enabled for all fields containing private or sensitive data | **In your org:**

 - There are no automations in place to respond to threats
            
 - Notifications and alerts are either not configured to notify appropriate users about anomalous activity, or some notifications and alerts related to anomalous activity exist, but they are ad hoc
            
 - Field History tracking is not consistently enabled for fields containing private or sensitive data |  |

## Data Security

Data security is the practice of protecting your data from unauthorized access, corruption, or unintended deletion. Data security involves safeguarding data both in transit and at rest.

Strong data security minimizes the risks and potential damages from unauthorized access to your system. Inadequate data security leaves systems vulnerable to data breaches, which can severely impact customers and your company. Therefore, safeguarding your data is fundamental to building secure architectures.

Improving data security starts with a clear understanding of what is considered data within Salesforce, along with its classification. The individual records, files, and documents stored within a Salesforce org are its data. For more on the distinction between metadata and data, see [Salesforce Architecture Basics](/docs/architect/fundamentals/guide/architecture-basics#metadata-versus-data).

You can build stronger data security in your Salesforce solutions by focusing on sharing and visibility as well as the use of encryption.

> Note: When designing for data security, be sure to take into accountdata privacyas well asarchiving and purging, as both of these concepts will affect the overall data security of your solutions.

### Data Classification

Identify and classify all data stored within the Salesforce platform based on its sensitivity (e.g., public, internal, confidential, restricted). Define a clear **data classification policy** that outlines how each data type should be handled and protected. Implement appropriate security controls, such as field-level security, encryption, and data masking, to enforce the policy and protect sensitive data from unauthorized access or exposure. Review and audit these classifications and controls regularly to ensure they remain aligned with business and compliance requirements.

### Sharing and Visibility

Sharing and visibility involves configuring your system to control how users access data within Salesforce. It is important to note that sharing and visibility control which individual records a user can access, but these settings alone do not ultimately control what a user can do with a particular record, or which specific fields within that record are visible. Permissions to carry out data operations (like [CRUD](https://developer.salesforce.com/docs/atlas.en-us.214.0.lightning.meta/lightning/apex_crud_fls.htm)) are assigned to users through metadata access controls, which can be configured for a user at the individual object and field level. For more on this, see [Authorization](/docs/architect/well-architected/guide/secure#authorization).

Agentforce actions can expose data to both authenticated and anonymous users who typically lack direct access. When building Agentforce Agents, carefully consider and document all Actions assigned to the Agent. For each Action, you must understand:

- What data the Actions can access.
- What security context the Actions run in.
- Whether the Actions have knowledge retrieval or other capabilities that can incorporate sensitive or restricted data into the Agent session.

To configure effective sharing and visibility in Salesforce:

- **Design access around meaningful job functions**. Create a security matrix that maps your [user personas](/docs/architect/well-architected/guide/secure#authentication) to business functions they are to perform. Use this [template](/docs/architect/resources/guide/security-policy-template) as a foundation to design your sharing and visibility. For more on identifying meaningful business functions, see [Functional Units](/docs/architect/well-architected/guide/composable#functional-units).
- **Choose the simplest path to applying the principle of least privilege**. As you apply the [principle of least privilege](/docs/architect/well-architected/guide/secure#authorization) in designing sharing and visibility schemes, do so in the most straightforward way. Avoid over-engineered data restrictions and sharing schemes, which can cause downstream issues for system maintainability, scalability, and adaptability. Instead, take advantage of the [flexible, layered data sharing in Salesforce](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/sharing_architecture.pdf), to configure fine-grained rules for user access at the data level.
- **Set internal organization-wide defaults (OWDs) to Public Read Only, unless your business deals with sensitive data — then use Private**. OWDs control the level of "least" privilege users will have at the data level. You cannot restrict access below the level of your OWD. While Private OWDs might seem ideal in every use case, users across the business can often end up inadvertently replicating a more permissive OWD through complex sharing schemes. Additionally, Private OWDs can cause users to create duplicate data. Sharing calculations (and re-calculations) may take a significant amount of time to complete depending on data volume and parent-child or ownership skew — Private OWDs exacerbate this. It’s important to note that OWDs do not control CRUD permissions and field-level visibility. Only choose an OWD of Private when it is justified by business needs — most often, such justifications will be related to [compliance](/docs/architect/well-architected/guide/compliant).
- **Set external organization-wide defaults (OWDs) to Private, unless you have a compelling business reason to allow greater access**. [External OWDs](https://help.salesforce.com/s/articleView?id=sf.security_owd_external.htm&type=5) apply to users accessing Salesforce data from Experience Cloud sites, portals, and so on. This allows you to configure separate OWD baselines for internal and external users, to allow for differing types of “least” privilege. Always set the OWD for external users to Private — exceptions for a more open level must be clearly justified by business needs.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#data-security-patterns-and-anti-patterns) below shows what proper (and poor) sharing and visibility looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about sharing and visibility tools from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Use of Encryption

Encryption converts readable data into an indecipherable, encoded format. Encrypted data can be decrypted, or translated back to its original form, via a key. As a result, encryption is among the most effective methods for securing data both at rest and in transit, ensuring that even if unauthorized parties access the data, it will be unreadable.

To design for proper use of encryption in your Salesforce solutions:

- **Always adequately encrypt data in transit**. Salesforce [employs Transport Layer Security (TLS)](https://help.salesforce.com/s/articleView?id=sf.security_overview_infrastructure.htm&type=5) for all sessions that take place in a [Salesforce-supported browser](https://help.salesforce.com/s/articleView?id=sf.getstart_browser_overview.htm&type=5), and requires that outbound calls using HTTPS meet specific security standards. Platform APIs also employ HTTPS by default. Additionally, data sent between a Salesforce Experience Cloud site or a portal and its related Salesforce org is encrypted in transit [by default](https://help.salesforce.com/s/articleView?id=xcloud.security_pe_platform_encryption_faq.htm&type=5). If you use Salesforce's [built-in email services](https://help.salesforce.com/s/articleView?id=sf.emailadmin_send_email_from_salesforce_overview.htm&type=5), there are default levels for the Transport Layer Security (TLS) Salesforce uses to [send and attempt delivery of email](https://help.salesforce.com/s/articleView?id=sf.emailadmin_deliverability.htm&type=5). You should, at a minimum, ensure the org settings are not lower than the default settings, unless you have clear business justification. Based on the classification and sensitivity of your data, consider leveraging a private network connection to Salesforce via AWS Direct Connect or Salesforce Private Connect. This ensures that your data does not traverse the public internet, but instead flows securely over a private network connection for both user access and integrations.
- **If the business requires it, encrypt data at rest**. Salesforce offers different ways to encrypt data at rest.

Hyperforce. Data is encrypted at rest in orgs that use Hyperforce. Encryption is managed for your org by Salesforce. You cannot create (or destroy) your own encryption keys.
Salesforce Shield. Salesforce Shield enables you to encrypt data at rest in a Salesforce org at additional layers, including the application and database layers. With Shield, you have full management capabilities for your tenant’s encryption keys, including robust “Bring Your Own Key” (BYOK) options. You can also encrypt unstructured data (including files, attachments, search indexes, and events). Hyperforce-based instances offer the option to use an external key manager, allowing you to bring your own AWS KMS. With this capability, you maintain full control over the encryption keys within your KMS that are used to encrypt and decrypt the data stored in Salesforce—strengthening security and aligning with your organization’s compliance requirements.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/secure#data-security-patterns-and-anti-patterns) below shows what proper (and poor) use of encryption looks like in a Salesforce org. Use these to validate your designs before you build, or identify opportunities for further improvements.

To learn more about encryption tools available from Salesforce, see [Tools Relevant to Secure](/docs/architect/well-architected/guide/secure#tools-relevant-to-secure).

### Data Security Patterns and Anti-Patterns

This table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for data security in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-data-security).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Sharing and Visibility** | **In your design standards and documentation:**

 - A security matrix outlines the data each user persona is authorized to access
            
 - Different data access standards are used for external users and internal users, if applicable | **In your design standards and documentation:**

 - Design standards and documentation do not exist or do not contain a security matrix
            
 - If a security matrix exists, it does not outline data access for user personas |
| **In your org:**

 - Organization-wide defaults (OWDs) for internal users is Public Read, or OWDs for internal users is Private, due to compliance requirements
            
 - OWDs for external users is Private
            
 - Generative AI operates only in user mode, or select uses for system access have clear business justification | **In your org:**

 - OWDs for internal users is set to Private without business justification or OWDs for internal users is set to Public Read/Write
            
 - OWDs for external users are set to anything other than Private without business justification
            
 - Generative AI operates in system mode without business justification |  |
| **In Apex:**

 - All code accessing data (SOQL/SOSL) or performing data operations (DML/Database Class methods) uses `with sharing` keywords | **In Apex:**

 - `with sharing` keywords are used inconsistently |  |
|  |  |  |
| **Use of Encryption** | **In your design standards and documentation:**

 - Use cases for data encryption in transit and (if needed) at rest are clear and discoverable
            
 - Approved encryption protocols are clearly listed
            
 - Code documentation clearly indicates where encryption is used and what protocols are used | **In your design standards and documentation:**

 - Approved encryption protocols are not clear or not listed
            
 - Code is not documented or documentation is unclear on where and how encryption is used in code |
| **In your org:**

 - If security risks are identified that require greater data protection at rest, either Hyperforce or Salesforce Shield provide encryption at rest | **In your org:**

 - Business needs require greater data protection at rest, but neither Hyperforce nor Salesforce Shield is used |  |
| **In Apex:**

 - If business needs require greater data protection in transit, all code involved in integration carries out logic using [Crypto Class methods](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_crypto.htm) to encrypt data before transmission or decrypt data upon receipt | **In Apex:**

 - Business needs require greater data protection in transit, but code involved in integration carries out logic without encrypting data before transmission or upon receipt, or Crypto Class methods are used ad hoc |  |

## Tools Relevant to Secure

| Tool | Description | Organizational Security | Session Security | Data Security |
| --- | --- | --- | --- | --- |
| [Apex Crypto Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_crypto.htm) | Encrypt and decrypt data in Apex |  |  | X |
| [API Access Control](https://help.salesforce.com/s/articleView?id=security_api_access_control_about.htm&type=5&language=en_US) | Manage access to your Salesforce APIs and connected apps | X | X | X |
| [API Anomaly Event](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/sforce_api_objects_apianomalyevent.htm) | Track anomalies in how users make API calls |  | X |  |
| [Browser Security Settings](https://help.salesforce.com/s/articleView?id=browser_security.htm&type=5&language=en_US) | Protect sensitive data and monitor SSL certificates |  | X |  |
| [Certificate-Based Authentication](https://help.salesforce.com/s/articleView?id=security_certificate_based_auth.htm&type=5&language=en_US) | Authenticate individuals with unique digital certificates | X | X |  |
| [Certificates and Keys](https://help.salesforce.com/s/articleView?id=sf.security_keys_about.htm&type=5) | Verify requests to external websites from Salesforce |  | X | X |
| [Code Scanner](https://github.com/forcedotcom/code-analyzer) | Scan Apex code for Security vulnerabilities |  | X | X |
| [Connected Apps](https://help.salesforce.com/s/articleView?id=connected_app_overview.htm&type=5&language=en_US) | Integrate via APIs and standard protocols | X | X |  |
| [Credential Stuffing Event](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/sforce_api_objects_credentialstuffingevent.htm) | Track attempted logins that use stolen user credentials |  | X |  |
| [CSP Trusted Site](https://help.salesforce.com/s/articleView?id=sf.configuring_remoteproxy.htm&type=5) | Prevent code injection attacks (i.e. cross-site scripting) |  | X |  |
| [Custom Login Flows](https://help.salesforce.com/s/articleView?id=sf.security_login_flow.htm&type=5) | Control login business processes for users | X |  |  |
| [Customer Identity](https://help.salesforce.com/s/articleView?id=identity_about_customers_partners.htm&type=5&language=en_US) | Control website and app logins and verification | X |  |  |
| [Data Mask](https://help.salesforce.com/s/articleView?id=sf.data_mask_overview.htm&type=5) | Automatically mask sensitive data in sandboxes |  |  | X |
| [Debug Logs](https://help.salesforce.com/s/articleView?id=sf.code_debug_log.htm&type=5) | Track events that occur in your org |  | X |  |
| [Delegated Administration](https://help.salesforce.com/s/articleView?id=admin_delegate.htm&type=5&language=en_US) | Assign limited admin privileges to non-admin users | X |  | X |
| [Device Activation](https://help.salesforce.com/s/articleView?id=sf.security_overview_identity_verification.htm&type=5) | Verify logins from untrusted browsers, devices or IP ranges |  | X |  |
| [Enhanced Transaction Security](https://help.salesforce.com/s/articleView?id=sf.enhanced_transaction_security_policy_types.htm&type=5) | Intercept events, monitor and control user activity |  | X |  |
| [Field Access](https://help.salesforce.com/s/articleView?id=sf.modifying_field_access_settings.htm&type=5) | Control data access at the field level |  |  | X |
| [Field Audit Trail](https://help.salesforce.com/s/articleView?id=sf.field_audit_trail.htm&type=5) | Define a policy to retain archived field history data |  |  | X |
| [Field History Tracking](https://help.salesforce.com/s/articleView?id=sf.tracking_field_history.htm&type=5) | Track and display field history |  |  | X |
| [Frontdoor.jsp](https://help.salesforce.com/s/articleView?id=security_frontdoorjsp.htm&type=5&language=en_US) | Allow access with an existing session ID and server URL |  | X |  |
| [Heroku Connect](https://www.heroku.com/connect) | Bi-directional synch between Heroku and Salesforce |  |  | X |
| [Heroku Shield](https://www.heroku.com/shield) | Build HIPAA or PCI compliant apps |  |  | X |
| [High Assurance Session Security](https://help.salesforce.com/s/articleView?id=security_auth_require_ha_session.htm&type=5&language=en_US) | Require additional security for sensitive operations |  | X |  |
| [Identity Connect](https://help.salesforce.com/s/articleView?id=sf.identityconnect_about.htm&type=5) | Map user records to Active Directory accounts | X |  |  |
| [Identity Verification History](https://help.salesforce.com/s/articleView?id=sf.security_verification_history.htm&type=5) | Audit user identity verification attempts | X |  |  |
| [Integration User License](https://help.salesforce.com/s/articleView?language=en_US&id=sf.integration_user.htm) | Grant access to data and features via API only. | X |  | X |
| [Lightning Login](https://help.salesforce.com/s/articleView?id=sf.security_ll_overview.htm&type=5) | Prevent weak or forgotten passwords and locked-out accounts | X |  |  |
| [Login Access](https://help.salesforce.com/s/articleView?id=sf.identity_login_access.htm&type=5) | Allow support users to log in as another user | X |  |  |
| [Login Forensics](https://help.salesforce.com/s/articleView?id=sf.event_monitoring_faq.htm&type=5) | Identify behavior that may indicate identity fraud |  | X |  |
| [Login History](https://help.salesforce.com/s/articleView?id=users_login_history.htm&type=5&language=en_US) | Monitor org and Experience Cloud site login attempts | X |  |  |
| [Mobile Device Tracking](https://help.salesforce.com/s/articleView?id=security_device_management.htm&type=5&language=en_US) | Track and monitor mobile device access to your org |  | X |  |
| [Mobile SDK](https://developer.salesforce.com/docs/atlas.en-us.mobile_sdk.meta/mobile_sdk/intro.htm) | Connect to the Salesforce Platform within stand-alone mobile apps | X | X | X |
| [Monitor User Permissions (Shield)](https://help.salesforce.com/s/articleView?id=release-notes.rn_security_monitor_user_permissions.htm&type=5&release=238) | Permission set and permission set group changes | X |  | X |
| [Multifactor Authentication](https://help.salesforce.com/s/articleView?id=sf.security_overview_2fa.htm&type=5) | Require two or more verification methods for login | X | X |  |
| [Mutual Authentication](https://help.salesforce.com/s/articleView?id=sf.security_keys_uploading_mutual_auth_cert_api.htm&type=5) | Enforce SSL or TLS mutual authentication |  |  |  |
| [My Domain](https://help.salesforce.com/s/articleView?id=sf.domain_name_overview.htm&type=5) | Configure login pages and policies, SSO and social logins | X |  |  |
| [Named Credentials](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm&type=5) | Specify endpoint URLs and authentication parameters |  | X |  |
| [OAuth Authorization](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_authenticate.htm&type=5) | Authorize client application access via token exchange | X |  |  |
| [Password Policies](https://help.salesforce.com/s/articleView?id=admin_password.htm&type=5&language=en_US) | Set password history, length, and complexity | X |  |  |
| [Permission Set Assignment Expirations](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_permissions_assn_expiration.htm&type=5&release=238) | Set expirations for permission set and permission set group assignments | X |  | X |
| [Permission Set Event](https://help.salesforce.com/s/articleView?id=release-notes.rn_security_monitor_user_permissions.htm&type=5&release=238) | Monitor changes made to permission sets and permission set groups | X |  | X |
| [Permission Set Groups](https://help.salesforce.com/s/articleView?id=perm_set_groups.htm&type=5&language=en_US) | Bundle permission sets to support complex access requirements | X |  |  |
| [Permission Sets](https://help.salesforce.com/s/articleView?id=perm_sets_overview.htm&type=5&language=en_US) | Control how users access metadata, features and apps | X |  |  |
| [Private Connect](https://help.salesforce.com/s/articleView?id=sf.private_connect_overview.htm&type=5) | Secure integrations between Salesforce and Amazon Web Services |  |  | X |
| [Profiles](https://help.salesforce.com/s/articleView?id=sf.admin_userprofiles.htm&type=5) | Control login IP ranges and login hours | X |  |  |
| [Real-Time Event Monitoring](https://help.salesforce.com/s/articleView?id=sf.real_time_event_monitoring_overview.htm&type=5) | Monitor and detect standard events in Salesforce |  | X |  |
| [Remote Site Settings](https://help.salesforce.com/s/articleView?id=configuring_remoteproxy.htm&type=5&language=en_US) | Register external sites for Apex or JavaScript calls |  | X |  |
| [Report Anomaly Event](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/sforce_api_objects_reportanomalyevent.htm) | Track anomalies in how users run or export reports |  | X |  |
| [Restriction Rules](https://help.salesforce.com/s/articleView?id=sf.security_restriction_rule.htm&type=5) | Prevent users from accessing unnecessary records |  |  | X |
| [Salesforce Code Analyzer](https://github.com/forcedotcom/code-analyzer) | Scan code via IDE, CLI or CI/CD to ensure it adheres to best practices |  | X | X |
| [Scoping Rules](https://help.salesforce.com/s/articleView?id=sf.security_scoping_rule.htm&type=5) | Control the default records your users can see |  |  | X |
| [Security Center](https://help.salesforce.com/s/articleView?id=sf.security_center.htm&type=5) | View security settings across all your orgs, and configure alerts for posture changes | X |  | X |
| [Security Health Check](https://help.salesforce.com/s/articleView?id=sf.security_health_check.htm&type=5) | Identify vulnerabilities in your security settings |  |  | X |
| [Session Hijacking Event](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/sforce_api_objects_sessionhijackingevent.htm) | Identify unauthorized access via stolen session identifiers |  | X |  |
| [Session Management Class](https://developer.salesforce.com/docs/atlas.en-us.236.0.apexref.meta/apexref/apex_class_Auth_SessionManagement.htm) | Customize security settings for an active session |  | X |  |
| [Session Security Settings](https://help.salesforce.com/s/articleView?id=admin_sessions.htm&type=5&language=en_US) | Configure sessions to protect against malicious attacks |  | X |  |
| [Setup Audit Trail](https://help.salesforce.com/s/articleView?id=sf.admin_monitorsetup.htm&type=5) | Track recent setup changes made by admins |  |  | X |
| [Sharing Settings](https://help.salesforce.com/s/articleView?id=sf.managing_the_sharing_model.htm&type=5) | Control data access at the record level |  |  | X |
| [Shield Platform Encryption](https://help.salesforce.com/s/articleView?id=sf.security_pe_overview.htm&type=5) | Encrypt sensitive data at rest and in transit |  |  | X |
| [Single Sign-On](https://help.salesforce.com/s/articleView?id=sf.sso_about.htm&type=5) | Provide access to multiple applications via a single login | X | X |  |
| [System for Cross-Domain Identity Management (SCIM)](https://help.salesforce.com/s/articleView?id=sf.identity_scim_overview.htm&type=5) | Manage identities across systems via REST APIs |  | X |  |
| [Threat Detection](https://help.salesforce.com/s/articleView?id=sf.real_time_em_threat_detection.htm&type=5) | Use statistics and machine learning to detect threats |  | X |  |
| [Trusted IP Ranges](https://help.salesforce.com/s/articleView?id=security_networkaccess.htm&type=5&language=en_US) | Define IP addresses that don't require additional verification |  | X |  |
| [User Access Report](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FYkDDUA1&tab=e) | Get a unified view of your users' object, record, and permissions access | X |  | X |

## Resources Relevant to Secure

| Resource | Description | Organizational Security | Session Security | Data Security |
| --- | --- | --- | --- | --- |
| [A Guide to Sharing Architecture](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/sharing_architecture.pdf) | Learn more about access tools, sharing models, and use cases |  |  | X |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization | X | X | X |
| [How to Build a User Security Model](https://medium.com/salesforce-architects/how-to-build-a-user-security-model-12db130b3182) | Gain a better understanding of user security models | X |  | X |
| [How to Implement the Principle of Least Privilege in Salesforce](https://medium.com/salesforce-architects/how-to-implement-the-principle-of-least-privilege-in-salesforce-59d3dbab9908?source=friends_link&sk=b7650c7fca8ad47bdd876399bbb0c635) | Learn to apply PoLP data access controls in Salesforce | X |  | X |
| [Monitor User Sessions](https://help.salesforce.com/s/articleView?id=security_user_session_info.htm&type=5&language=en_US) | Review active sessions and end suspicious sessions |  | X |  |
| [Multi-Factor Authentication](https://security.salesforce.com/mfa) | Access official MFA resources from Salesforce | X |  |  |
| [Permission Set Groups (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/permission-set-groups/mute-permissions-in-permission-set-groups) | Get hands-on with permission set groups | X |  | X |
| [REST API Architecture](https://developer.salesforce.com/docs/atlas.en-us.234.0.api_rest.meta/api_rest/intro_rest_architecture.htm) | Understand REST API terms and concepts | X | X | X |
| [Security and the SOAP API](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_concepts_security.htm) | Understand SOAP API terms and concepts | X | X | X |
| [Security Best Practices for API and Internal System Users](https://medium.com/salesforce-architects/security-best-practices-for-api-access-and-internal-system-users-a6199d0cda09) | Secure access to Salesforce by API users and secure internal system users | X |  |  |
| [Security Implementation Guide](https://resources.docs.salesforce.com/238/latest/en-us/sfdc/pdf/salesforce_security_impl_guide.pdf) | Take a comprehensive look at Salesforce Security | X | X | X |
| [Security Policy Template](/docs/architect/resources/guide/security-policy-template) | Set Security Policies for your Organization | X | X | X |
| [Session Types](https://help.salesforce.com/s/articleView?id=security_session_types.htm&type=5&language=en_US) | Identify the types of sessions used to access your org |  | X |  |
| [Threat Modeling Fundamentals (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/threat-modeling-fundamentals) | Learn about security threats and how to prevent them. |  | X |  |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you'd like to see next.
