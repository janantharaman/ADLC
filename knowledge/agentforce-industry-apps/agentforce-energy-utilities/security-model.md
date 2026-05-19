---
source: Vlocity CLM Guide; Vlocity ASLM Guide; E&U Developer Guide (Summer '26, PDF v67.0 confirmed 2026-05-12); grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: security-model
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Security Model

## License and Permission Set Architecture

### New Customers (Spring '22+) — Permission Set Licenses

| Module | PSL Name | Who Needs It |
|---|---|---|
| CPQ | CPQ PSL | Sales reps, contact center agents doing quoting |
| EPC | EPC PSL | Product managers, catalog admins |
| Order Management | OM PSL | Order fulfillment, operations users |
| Contract Lifecycle Management | CLM PSL | Contract managers, legal admins |
| Document Generation | DocGen PSL | Anyone generating contracts/documents |
| Digital Commerce | DC PSL | E-commerce portal users, self-serve customers |

**Pre-Spring '22 customers:** Continue with managed package licenses until contract renewal. Do not mix PSL and managed package licenses on the same org.

### Field Service / ASLM Add-On Licenses

| Feature | License Required |
|---|---|
| Asset Coverage View | `FieldServiceEntitlementsView` add-on license |
| Asset Interactive Hierarchy | `FieldServiceAssetHierarchyAddOn` license |
| Asset Interactive Hierarchy — Current View | `AssetInteractiveHierarchyCurrentView` (Unlimited Edition) |

### Document Generation Permissions

| Role | Permission Set Required |
|---|---|
| DocGen template designer | `DocGen Designer` or `Contract Admin` |
| DocGen runtime (generating documents) | DocGen runtime permissions PSL |
| CLM contract admin | `Contract Admin` permission set |
| Service part returns (ASLM) | `Service Part Return Management` permission set |

### Named Permission Sets — Required by Standard E&U Objects (from Developer Guide)

These permission sets gate access at the object level and are documented in the Developer Guide's "Special Access Rules" for each object:

| Permission Set | Objects It Unlocks |
|---|---|
| `EAndU Cloud Program Access` | `ApplicationFormTemplate`, `ProgramEnrollment`, `ProgramProduct`, `IndicatorAssignment` |
| `EAndU Cloud Usage Impact Access` | `UsageImpactFactor`, `UsageImpactGroup`, `UsageImpactGroupFactor`, `UsageImpactGroupPgmMeasure`, `UsageImpactGroupVersion` |
| `Contractor Work Report Access` | `WorkReportLineItem`, `WorkReportError`, `WorkReport` (contractor-submitted fields) |
| `User Work Report Access` | `WorkReportLineItem`, `WorkReportError`, `WorkReport` (user fields) |

**Important:** `Budget`, `BudgetCategory`, `BudgetCategoryValue`, `BudgetPeriod` require both the **Grantmaking license enabled** AND the `Manage Budgets` system permission assigned — not just permission set assignment.

---

## OWD and Sharing Model

E&U Cloud managed objects follow the same OWD/sharing model as standard Salesforce. Key defaults to configure:

| Object | Recommended OWD | Notes |
|---|---|---|
| `vlocity_cmt__Premises__c` | Private or Public Read | Customer premises data — Private recommended; share via sharing rules or Account team |
| `vlocity_cmt__Catalog__c` | Public Read Only | Product catalog is not customer-sensitive |
| `vlocity_cmt__Promotion__c` | Public Read Only | Promotions are marketing configuration |
| `vlocity_cmt__OrchestrationPlan__c` | Private | Contains order fulfillment details; restrict to operations team |
| `vlocity_cmt__FulfilmentRequest__c` | Private | Backend fulfillment data |
| `vlocity_cmt__Statement__c` | Private | Customer billing data; strict access |
| `EnergyServiceAgreement` | Private | Energy contract data |
| `ProgramEnrollment` | Private | Customer program participation |
| `BillingAccount` | Private | Financial data |

---

## Named Credentials — Mandatory for Callouts

All external system callouts from Integration Procedures **must** use Named Credentials. This has been a Salesforce requirement since Summer '19 for E&U Cloud integrations.

Common named credentials in E&U implementations:
- **CIS/Billing system** — for meter reads, balance queries, payment posting
- **IVR/CTI system** — for call context injection
- **Marketing Cloud** — for journey triggers
- **DocuSign** — OAuth 2.0 (required from Winter '23 package v240.11+; OAuth 1.0 deprecated March 2024)
- **External product catalog** — for real-time pricing feeds
- **SAP/ERP** — for asset and work order synchronization

Anti-pattern: hardcoding endpoint URLs or credentials in Integration Procedure HTTP Action steps. Always use Named Credential references.

---

## DocuSign Security

- **Winter '23+ (package v240.11+):** DocuSign integration requires OAuth 2.0 only
- **OAuth 1.0 deprecated:** As of March 2024, OAuth 1.0 for DocuSign is no longer supported
- DocuSign Connected App must be configured with OAuth 2.0 before upgrading to package v240.11+
- `VlocityDocuSignTemplate__c` and `VlocityDocuSignBranding__c` store template and branding configuration

---

## Integration Procedure REST Exposure

Integration Procedures can be exposed as REST API endpoints, enabling external systems to call them without a dedicated Apex REST class. Security considerations:

- The IP REST endpoint inherits the calling user's permissions — the calling user must have access to all objects queried/modified within the IP
- Use Connected App + OAuth 2.0 for authenticating external callers
- Use Named Credentials for the outbound callouts within the IP
- Rate-limit external IP callers via API request limits on the Connected App

---

## OmniStudio Security

- **OmniScripts** run in the context of the logged-in user — all SOQL, DML, and callouts within an OmniScript respect that user's CRUD/FLS
- **DataRaptors (Extract/Load)** do not automatically enforce FLS — explicitly add FLS checks in Load operations or use permission-aware SOQL
- **Integration Procedures** run server-side but still in the calling user's context unless `Run as Integration User` is enabled
- **FlexCards** render data via DataRaptors — the underlying SOQL runs as the current user; restrict sensitive fields at the FLS level
- **Saved OmniScript instances** (`OmniScriptInstance__c`) may contain PII entered by users — ensure this object has strict OWD and purge policies

---

## Document Generation Limits (Server-Side)

| Limit | Value |
|---|---|
| Requests per hour per org | 1,000 |
| Requests per day per org | 24,000 |

Requests exceeding these limits are blocked and saved in the Document Generation Processes entity for retry. Plan for batch processing or off-peak scheduling for bulk document generation.

---

## Vlocity Data Cache / Data Store Security

| Object | Risk | Mitigation |
|---|---|---|
| `vlocity_cmt__VlocityDataCache__c` | System cache may contain sensitive API responses | OWD = Private; automated purge |
| `vlocity_cmt__Datastore__c` | Persistent cache | OWD = Private; purge stale records |
| `vlocity_cmt__CachedAPIResponse__c` | Cached external API data | Purge after TTL; do not cache credentials |
| `vlocity_cmt__VlocityErrorLogEntry__c` | May contain PII in error payloads | Restrict read access; periodic purge |

---

## Common Security Anti-Patterns in E&U

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Hardcoded CIS endpoint credentials in Integration Procedure | Credential exposure in metadata | Use Named Credentials |
| Public Read/Write OWD on `BillingAccount` or `Statement__c` | All users can see all customer billing data | Set OWD to Private; use sharing rules for service reps |
| System Administrator profile for field service users | Excessive privilege | Create dedicated FSL permission sets |
| OAuth 1.0 DocuSign integration not migrated | Authentication fails after March 2024 | Migrate to OAuth 2.0 before package upgrade |
| DataRaptor Load without FLS checks | Writes to fields the user cannot see | Add security check or use stripInaccessible equivalent |
| `OmniScriptInstance__c` not purged | PII accumulates in in-progress sessions | Schedule purge job for completed/expired sessions |
| Exposing Integration Procedures as public REST endpoints without OAuth | Unauthenticated access to business logic | Always authenticate IP REST callers via Connected App + OAuth |
