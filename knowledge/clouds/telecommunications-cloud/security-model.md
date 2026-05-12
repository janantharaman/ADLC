---
source: Salesforce Communications Cloud / Telecommunications Cloud Developer Documentation (developer.salesforce.com, Spring '26); SFI Best Practices (Salesforce); B2B Telecommunications documents ingested 2026-05-10; B2C Telecommunications documents ingested 2026-05-10
cloud: Telecommunications Cloud
section: security-model
last-updated: 2026-05-10
---

# Communications Cloud — Security Model

## Overview

Communications Cloud uses Salesforce's standard security framework — profiles, permission sets, record-level sharing, and field-level security (FLS) — plus several product-specific permission sets and configuration requirements for the TM Forum Industry APIs.

---

## Permission Sets by Module and Persona

### Core Communications Cloud Permission Sets

> **Note:** Official permission set API names from the managed package should be verified in the target org:
> ```soql
> SELECT Id, Name, Label, NamespacePrefix FROM PermissionSet WHERE NamespacePrefix IN ('vlocity_cmt', 'omnistudio') ORDER BY Name
> ```

| Permission Set (Label) | API Name Pattern | Module | Persona | Key Access Granted |
|----------------------|-----------------|--------|---------|-------------------|
| Communications Cloud User | `CommCloudUser` | All | All authenticated users | Base access to vlocity_cmt objects |
| Industries CPQ User | `IndustriesCPQUser` | CPQ / Catalog | Sales Rep, CPQ User | Quote, QuoteLineItem, Product2 CRUD; PriceList read |
| Industries CPQ Admin | `IndustriesCPQAdmin` | CPQ / Catalog | CPQ Admin | Full CRUD on all catalog objects; pricing setup |
| OmniStudio User | `OmniStudioUser` | OmniStudio | All flow users | Execute OmniScripts, FlexCards |
| OmniStudio Admin | `OmniStudioAdmin` | OmniStudio | Developers/Admins | Author and deploy OmniStudio components |
| Order Management User | `VlocityOrderManagement` | Order Management | Order Manager, Provisioner | Order, OrderItem CRUD; SubOrder access |
| Industry API Access | `IndustryAPIAccess` | TM Forum APIs | Integration users | OAuth 2.0 API access; Connected App permissions |
| DocGen User | `DocGenUser` | Agreement Management | Contract users | Generate documents from templates |
| DocGen Designer | `DocGenDesigner` | Agreement Management | Template designers | Create and modify DocumentTemplates |
| Notification Framework User | Included in base SKU | Notification Framework | Integration admin | Configure IntegrationProviderDefinition__mdt |

---

## Object-Level Security (OLS) by Persona

### Sales Representative
| Object | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| `Quote` | Yes | Yes | Yes | No |
| `QuoteLineItem` | Yes | Yes | Yes | No |
| `Order` | Yes | Yes | Limited | No |
| `OrderItem` | Yes | Yes | Limited | No |
| `Product2` | No | Yes | No | No |
| `vlocity_cmt__PriceList__c` | No | Yes | No | No |
| `vlocity_cmt__PriceListEntry__c` | No | Yes | No | No |
| `vlocity_cmt__Promotion__c` | No | Yes | No | No |
| `Asset` | No | Yes | No | No |
| `Account` | Yes | Yes | Yes | No |
| `Contact` | Yes | Yes | Yes | No |

### CPQ Administrator
| Object | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| `Product2` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__Catalog__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__CatalogProductRelationship__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__ProductChildItem__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__AttributeAssignment__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__Attribute__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__PriceList__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__PriceListEntry__c` | Yes | Yes | Yes | Yes |
| `vlocity_cmt__Promotion__c` | Yes | Yes | Yes | Yes |

### Order Manager / Provisioner
| Object | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| `Order` | Yes | Yes | Yes | No |
| `OrderItem` | Yes | Yes | Yes | No |
| `vlocity_cmt__OrderItemRelationship__c` | Yes | Yes | Yes | No |
| `vlocity_cmt__SubOrder__c` | Yes | Yes | Yes | No |
| `Asset` | Yes | Yes | Yes | No |
| `Case` | Yes | Yes | Yes | No |

### Customer Service Agent
| Object | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| `Case` | Yes | Yes | Yes | No |
| `CaseComment` | Yes | Yes | No | No |
| `Asset` | No | Yes | Limited | No |
| `Account` | No | Yes | Limited | No |
| `Contract` | No | Yes | No | No |

### Integration User (API)
| Object | Create | Read | Edit | Delete |
|--------|--------|------|------|--------|
| All TM Forum mapped objects | As needed per API | Yes | As needed per API | Restricted |
| `Order`, `OrderItem` | Yes | Yes | Yes | No |
| `Quote`, `QuoteLineItem` | Yes | Yes | Yes | No |
| `Asset` | Yes | Yes | Yes | No |
| `Case` | Yes | Yes | Yes | No |
| `Account`, `Contact` | Yes | Yes | Yes | No |
| `Contract` | Yes | Yes | Yes | No |
| `Product2`, `vlocity_cmt__*` catalog | Read | Yes | No | No |

---

## Field-Level Security (FLS) Requirements

### Critical FLS Requirements for TM Forum APIs

#### TMF621 v5 (Trouble Ticket) — MANDATORY
Per the official documentation: "Enable FLS for all Case fields per user profile" is a prerequisite for TMF621 v5.

Key Case fields requiring FLS enabled:
- `Subject`
- `Description`
- `Priority`
- `Status`
- `Type`
- `Origin`
- `ClosedDate`
- `vlocity_cmt__severity__c`
- `CaseTroubleTicket.severity`
- `CaseTroubleTicket.expectedResolutionDate`
- `CaseTroubleTicket.RequestedResolutionDate`
- `CaseTroubleTicket.externalId`

#### TMF637 (Product Inventory) — Key Asset Fields
FLS must be enabled on all mapped Asset fields for the integration user:
- `vlocity_cmt__AssetReferenceId__c`
- `vlocity_cmt__ProvisioningStatus__c`
- `vlocity_cmt__BillingAccountId__c`
- `vlocity_cmt__OrderProductId__c`
- `vlocity_cmt__JSONAttribute__c`
- `AttributeSelectedValues__c`

#### TMF622 (Product Ordering) — Key Order/OrderItem Fields
- `Order.vlocity_cmt__RequestedStartDate__c`
- `Order.vlocity_cmt__PriceList__c`
- `OrderItem.vlocity_cmt__Action__c`
- `OrderItem.vlocity_cmt__FulfilmentStatus__c`
- `OrderItem.vlocity_cmt__JSONAttribute__c`

---

## Sharing Model for Orders, Products, Subscriptions, and Cases

### Recommended Sharing Model

| Object | OWD (Org-Wide Default) | Sharing Rule Notes |
|--------|----------------------|-------------------|
| `Order` | Private or Public Read/Write | Share orders within account team; restrict cross-account access |
| `OrderItem` | Controlled by Parent | Inherits from Order |
| `Quote` | Private | Share with opportunity owner and account team |
| `QuoteLineItem` | Controlled by Parent | Inherits from Quote |
| `Asset` | Public Read | Typically read-accessible to service and support teams |
| `Case` | Private | Case queues and routing control access; agents see assigned cases |
| `Product2` | Public Read | Product catalog is read-only for all; admin-only edit |
| `vlocity_cmt__Catalog__c` | Public Read | Catalog data is read-only for all users |
| `vlocity_cmt__PriceList__c` | Public Read | Price lists read-only for sales; admin-only edit |
| `vlocity_cmt__Promotion__c` | Public Read | Promotions visible to all; admin-managed |
| `Account` | Private (recommended) or Public Read/Write per business model | Account ownership by sales rep is standard |
| `Contract` | Private | Accessible to account owner and contract admin |

> **Note:** OWD settings must be verified with the customer's data governance requirements. Telecom customers with strict data segregation (e.g., B2B enterprise accounts) typically use Private OWD for Order and Quote with explicit sharing rules.

---

## OAuth 2.0 and Connected App Configuration for Industry APIs

### Required Setup

1. **Create a Connected App** in Salesforce Setup:
   - Enable OAuth settings
   - Set OAuth scopes: `api`, `refresh_token` (minimum); add `full` if required
   - Configure callback URL for the external system
   - Note the Consumer Key and Consumer Secret

2. **OAuth 2.0 Authorization Flow** (three steps per official documentation):
   - Step 1: Client app requests access via Connected App
   - Step 2: Authorization server issues access token
   - Step 3: Resource server (Salesforce) validates token and grants API access

3. **Build Base URL** for API calls:
   ```
   US Production: https://api.commscloud.salesforce.com/[TMF API]/[version]/[resource]
   US Sandbox:    https://api.commscloud.salesforce.com/sandBox/[TMF API]/[version]/[resource]
   EU Production: https://eu.api.commscloud.salesforce.com/[TMF API]/[version]/[resource]
   EU Sandbox:    https://eu.api.commscloud.salesforce.com/sandBox/[TMF API]/[version]/[resource]
   ```

4. **Assign `IndustryAPIAccess` permission set** (or equivalent) to the integration user making API calls.

### Integration User Security Hardening
- Use a dedicated integration user (not a named user)
- Apply principle of least privilege: grant only the object/field access required by each API
- Use IP allowlisting on the Connected App to restrict which IPs can call the API
- Rotate Connected App credentials periodically
- Enable audit trail logging for integration user activity

---

## OmniStudio Security Considerations

### OmniScript Access Control
- OmniScripts are accessible to any user with the `OmniStudioUser` permission set
- There is no native row-level security on OmniScript execution — access control must be implemented within the OmniScript logic (check Account ownership, Case assignment, etc.)
- Sensitive operations (order placement, cancellation) in OmniScripts should include explicit authorization checks using DataRaptor lookups or Integration Procedure validations

### DataRaptor and Integration Procedure Security
- DataRaptors and Integration Procedures run in the context of the executing user by default
- For privileged operations (e.g., callouts to external systems), Named Credentials should be used to avoid embedding credentials in Integration Procedure HTTP actions
- Apex-backed Integration Procedures run as the user unless `without sharing` is explicitly used — verify sharing context for each IP

### Named Credential Usage
- External BSS/OSS callouts from Integration Procedures MUST use Named Credentials (not hardcoded endpoints or credentials)
- Named Credentials enforce authentication and can be updated centrally without code changes
- Required for: billing system callouts, OSS provisioning endpoints, address validation services

### FlexCard Data Exposure
- FlexCards display data from DataRaptors; ensure DataRaptor filter conditions restrict data to the current user's accessible accounts
- Avoid loading sensitive billing or financial data in FlexCards without explicit authorization checks

---

## Integration User Permission Requirements

For an integration user that calls all TM Forum APIs, the minimum permission requirements are:

| Requirement | Detail |
|-------------|--------|
| Profile | Minimum Salesforce license with API access |
| Permission Set | `IndustryAPIAccess` (or equivalent granting Connected App access) |
| Permission Set | Object/field access per API (see table above) |
| FLS | Enabled on all TM Forum-mapped fields for relevant objects |
| Org Permission | `CommsCloud` enabled |
| Org Permission | `Cases` enabled (for TMF621) |
| Org Permission | `DocGen` enabled (for TMF651 — Agreement Management) |
| Connected App | Authorization via OAuth 2.0; Consumer Key and Secret configured |
| IP Restriction | Recommended: allowlist external system IP ranges in Connected App |

---

## Notification Framework Security

### Who Can Configure the Notification Framework
- Only users with System Administrator profile or a custom profile with `Customize Application` permission can create/modify `IntegrationProviderDefinition__mdt` records.
- Integration Provider Definition Mapping configuration requires admin-level access to Custom Metadata.

### Outbound Notification Endpoint Security
- Notification delivery endpoints must be registered as Remote Site Settings (allow callouts)
- Endpoints should require mutual TLS or token-based authentication
- Notification payloads may contain PII (customer names, contact info in TMF632 notifications) — ensure receiving endpoint is secured and compliant with data privacy regulations

### CDC Security Model
- Change Data Capture events are generated by Salesforce infrastructure and delivered to the Notification Framework
- The framework processes events as the System context — standard Salesforce CRUD/FLS is not re-enforced during notification processing
- Ensure notification filtering (field-level CDC) is configured to exclude sensitive fields (e.g., financial data, account credentials) from notification payloads

---

## PII and Data Privacy Considerations

| Data Element | Object/Field | Privacy Consideration |
|-------------|-------------|----------------------|
| Customer Name | `Account.Name`, `Contact.Name` | Included in TMF629 API responses |
| Email Address | `Contact.Email` | Included in TMF629 contactMedium; restrict FLS for non-service users |
| Phone Number | `Contact.Phone` | Included in TMF629; restrict external exposure |
| Service Address | `Asset` address fields | Location PII; restrict access to authorized provisioning users |
| Billing Information | `vlocity_cmt__BillingAccountId__c` | Financial PII; restrict to billing admin persona |
| Order Details | `Order`, `OrderItem` | Commercial terms; restrict to account team |
| Notification Payloads | TMF632 (AccountContactRelation changes) | Contains PII; secure endpoint required |

**General rule:** Follow Salesforce's Well-Architected principle of least privilege — grant field-level access only to the roles that need each field for their business function. Audit FLS configurations at each phase gate.

---

## DataRaptor and Integration Procedure Access Control

### OWD-Based Access (Default Behavior)
- DataRaptor Bundle Object: `Default Internal Access = Private`, `Default External Access = Private`
- Vlocity Integration Procedure (OmniScript Object): same OWD defaults
- This means DataRaptors and Integration Procedures are private by default — access must be explicitly granted via Sharing Rules or Permission Sets

### Custom Permission-Based Access (Recommended since Summer '19)
- Use custom permissions to control which users can execute DataRaptors and Integration Procedures
- Preferred over OWD-based control for fine-grained access management
- When using OWD-based control: enable `CheckCachedMetadataRecordSecurity = true` to enforce record-level security on cached metadata (slight performance impact)

### Field-Level Security in DataRaptors
- **DataRaptor Load:** Always enforces FLS on Load operations — cannot bypass
- **DataRaptor Extract:** FLS enforcement is configurable via "Check Field Level Security" checkbox on the DataRaptor; disable only if performance requires and security implications are understood

---

## Secure Caching

- DataRaptors and Integration Procedures use cached results for performance
- If using OmniStudio (vs OmniStudio for Vlocity): uses **Scale Cache**
- If using OmniStudio for Vlocity: uses **Platform Cache**
- Cached data in `VlocityMetadata` platform cache is NOT secured by default
- Enable `CheckCachedMetadataRecordSecurity` custom setting to add record-level security checks on cached data
- If using custom permissions for access control (instead of OWD): this custom setting is NOT needed

---

## Governance Anti-Patterns to Avoid

| Anti-Pattern | Risk | Recommended Alternative |
|---|---|---|
| System Administrator profile for all implementation users | Over-privileged access to all financial/order data; bypasses all sharing rules | Right-size to Communications Cloud User profile + permission sets |
| Exposing the Bulk Async Engine (Cart APIs) via Vlocity Open Interface directly | Any authenticated user can invoke bulk operations, bypassing business controls | Always wrap in a custom API (VIP or Apex REST) as the access control boundary |
| Hardcoding Salesforce IDs in Apex or Integration Procedures | IDs differ between orgs; causes production failures; security through obscurity anti-pattern | Use dynamic ID resolution via SOQL or custom settings |
| OmniScript version sprawl | Old versions remain accessible and executable; inconsistent behavior across users | Limit to 3 active versions per OmniScript; regularly purge old versions |
| Integration user with System Administrator profile | Excessive access for API operations | Create dedicated Integration User profile with only required CRUD/FLS for integration objects |
| Using CPQ compile data for Digital Commerce | DC self-service storefront shows stale or missing product data | Run separate DC compile job after every catalog change |
| Enabling Person Accounts without a rollback plan | Irreversible — cannot be disabled once enabled; all Contacts converted | Validate Person Account requirement in Architecture Review before enabling |
| Shared users for integration systems | Audit trail cannot attribute actions to specific systems; violates 1:1 user principle | One dedicated integration user per external system |

---

## B2C-Specific Security Considerations

### Digital Commerce — Anonymous/Guest Cart Security

B2C self-service ordering allows unauthenticated (guest) users to browse and build carts before login. This introduces specific security requirements:

1. **Guest User Profile** — Experience Cloud site guest user must be configured with minimal access:
   - Read-only access to `Product2`, `vlocity_cmt__Catalog__c`, `vlocity_cmt__PriceList__c`
   - No access to `Order`, `Account`, `Contract` objects
   - No access to financial or PII fields

2. **Cart Session Security** — Each anonymous cart session requires a `cartContextKey` (unique session token):
   - The `cartContextKey` must be passed on every Standard DC API call to identify the session
   - Without it, cart operations fail with a generic error (not a clear auth error)
   - Store `cartContextKey` in browser session storage only — not localStorage

3. **Connected App for DC** — The Digital Commerce Connected App must be configured with:
   - OAuth scopes: `api`, `refresh_token` minimum
   - Guest user access enabled on the Experience Cloud site
   - IP restriction: allowlist DC middleware or CDN IPs only
   - Session timeout aligned to your guest session expiry policy

4. **Authentication Gate at Checkout** — Anonymous browsing is acceptable, but cart submission must force authentication:
   - Validate that the Experience Cloud site's checkout flow enforces login before `submitCart` API call
   - Guest users must not be able to create `Order` or `Account` records

### Connected Assets — Permission Set Security Model

Connected Assets introduces six additional permission sets (in addition to the base Communications Cloud permission sets):

| Permission Set | Persona | Access Granted |
|--------------|---------|--------------|
| `Actionable Event Orchestration Designer` | Fulfillment Designer | Create/edit orchestration plan definitions, rule assignments |
| `Actionable Event Orchestration Runtime` | Integration/System User | Execute orchestrations triggered by platform events |
| `Context Service Admin` | Platform Admin | Configure Context Service rule sets and metadata |
| `Context Service Runtime` | Integration/System User | Resolve context at runtime; read context rule metadata |
| `Rule Engine Designer` | Business Analyst / Admin | Author Rule Engine definitions |
| `Rule Engine Runtime` | Integration/System User | Execute Rule Engine evaluations at runtime |

> **Entitlement security:** The 300 orchestrations/month limit is enforced at the platform level. There is no field or permission to increase this limit on standard SKU — contact Salesforce Account team for higher-volume add-ons. Exceeding the limit silently blocks orchestrations without throwing an exception to the caller.

### Order Management Plus — Custom Code Security

Order Management Plus allows custom code extensions (integration adapters, auto tasks). The customer/PS team owns security of custom code:

| Responsibility | Detail |
|--------------|--------|
| Secure code development | Adhere to Salesforce secure coding guidelines; no hardcoded credentials |
| Vulnerability scanning | Scan custom code before every deployment to OM Plus environment |
| PII encryption keys | Customer owns and manages PII encryption keys for OM Plus |
| Salesforce + fulfillment system credentials | Customer manages; must not be embedded in custom code |
| Environment configuration secrets | Managed by customer; use Named Credentials for all external callouts |

### Person Account Security Considerations

When Person Accounts are enabled for B2C (individual consumer model):

- Person Accounts merge `Account` and `Contact` into a single record — standard Contact sharing rules no longer apply
- FLS on person account fields applies to the `Account` object; there is no separate `Contact` FLS
- Ensure `TMF629` (Customer Management API) integration users have FLS on person account fields they need to read/write
- Report on person accounts separately from business accounts — OWD for Account applies to both record types; use record type-based sharing rules to differentiate

### "What Good Looks Like" — Security Checklist (Well-Architected)

Apply this checklist at every Design and Deployment phase gate for Communications Cloud implementations:

| Category | Check |
|---------|-------|
| API Access Control | No unauthorized connected apps can authenticate to the org |
| Named Credentials | All Apex, LWC, Aura callouts use named credentials — no hardcoded usernames/passwords |
| No Hard-Coded Credentials | No usernames, passwords, tokens, or secrets appear in readable form in code |
| Custom Login Flows | All custom login Apex uses `SessionManagement` methods correctly |
| 1:1 User-to-System Mapping | No shared users — one integration user per external system |
| MFA Compliance | Login configurations aligned to Salesforce MFA requirements |
| SSO Safety | If SSO is enabled, at least one admin user has direct login access (break-glass) |
| Security Personas Documented | All approved personas documented with their allowed authentication schemes |
| Login Forensics | If login history required > 6 months, Login Forensics is configured |
| OmniScript Authorization | Sensitive operations in OmniScripts include explicit authorization checks |
| DataRaptor FLS | DataRaptor Extract "Check Field Level Security" enabled unless explicitly opted out |
| Named Credentials (IPs) | Integration Procedures using HTTP callouts reference Named Credentials, not hardcoded endpoints |
