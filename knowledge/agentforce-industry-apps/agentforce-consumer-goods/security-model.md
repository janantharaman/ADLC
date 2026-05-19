---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: security-model
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Security Model

## Namespace Security

CGC ships as a **managed package** (`cgcloud` namespace). Field-level security (FLS) on `cgcloud__` fields must be configured via permission sets or profiles — CGC does not auto-grant access to its own fields. When granting access, use permission sets rather than profile edits to keep managed package fields separate from org baseline settings.

The `cgc_sync` namespace (Sync Management) is a separate managed package. Access to Sync Management objects requires the Consumer Goods license AND the Mobile Sync package installed.

---

## Sharing Model

### Standard Object OWD Recommendations

| Object | Recommended OWD | Notes |
|---|---|---|
| `Account` | Private | Field reps see only their stores; sharing via territory or manual shares |
| `Visit` | Private | Rep sees own visits; manager sees via Role Hierarchy |
| `AssessmentTask` | Controlled by Parent | Inherits Visit sharing automatically |
| `RetailStore` | Private | Follows Account visibility |
| `Assortment` | Public Read Only | Field reps need read access to assortments |
| `Product2` | Public Read Only | All reps need catalog access |
| `cgcloud__Promotion__c` | Private | Marketing creates; reps see via sharing rules |
| `cgcloud__Order__c` | Private | Rep sees own orders; manager via hierarchy |

### Territory-Based Access (Common Pattern)

CGC orgs are frequently territory-based. Two approaches:

**Enterprise Territory Management (ETM)**
- Accounts (stores) assigned to territories
- Reps assigned to territories → automatically see all stores in their territory
- Best for strict territory boundaries

**Role Hierarchy + OWD**
- Visit OWD = Private; reps see their own Visits only
- Managers see subordinates' Visits via Role Hierarchy
- Simpler but cannot model overlapping territories

**Hybrid (most common):** ETM for Account/RetailStore access, Role Hierarchy for Visit/Order access. The `cgcloud__Account_Extension__c` object stores territory and sales org data for each account.

---

## Permission Set Design

CGC implementations should use dedicated permission sets rather than embedding CGC field access in profiles.

| Permission Set | Who Gets It | What It Grants |
|---|---|---|
| CGC Field Rep | All field reps | CRUD Visit/AssessmentTask, Read Account/RetailStore/Product2, Edit cgcloud__Order__c |
| CGC Territory Manager | Rep managers | Field Rep + View All Visits in territory, Edit Promotions |
| CGC Trade Marketing | Trade marketing team | CRUD cgcloud__Promotion__c/Fund__c, Read Accounts/Visit summaries |
| CGC Sync Admin | System admins only | Full access to cgc_sync__* objects for sync configuration |
| CGC TPM User | TPM users | CRUD TPM objects (Account Plan, Promotion, Tactic, Payment, Fund) |
| TPM Calculation Result Export | RTR export service user | Read Product/Account/Promotion/Tactic/Product Part objects and fields for KPI export |

---

## Sync Management Security

### cgc_sync Access Rules

- `cgc_sync__Sync_Config__c` uses `SetupOwnerId` (polymorphic: Organization/Profile/User) — a hierarchy: user-level config overrides profile-level overrides org-level, unless `cgc_sync__Ignore_Client_Overrides__c = true` in the org-level config
- `cgc_sync__Sync_Client_App_Profile_Mapping__c` — controls which sync configuration profile maps to which user, role, or profile
- Sync Tracked Object Config (`cgc_sync__Sync_Tracked_Object_Config__c`) determines what data is distributed to each mobile device — review carefully to avoid over-syncing sensitive fields

### Mobile App Access Model

Field reps on mobile use offline sync and require:
- Read on all objects that will be synced to the device (enforced by FLS during sync)
- Edit on Visit and AssessmentTask (for check-in/check-out and task completion)
- Edit on cgcloud__Order__c and cgcloud__Order_Item__c (for order capture)
- The sync process respects FLS — if a field is not accessible to the user profile/permission set, it will not be included in the sync payload

**Never grant System Administrator profile to field rep mobile users** — sync would download the entire org data to the device.

---

## cgcloud Object Sharing

### Custom Object Sharing

Most `cgcloud__*__c` custom objects support:
- `ChangeEvent` — change data capture
- `Feed` — Chatter feed tracking
- `History` — field history tracking
- `OwnerSharingRule` — sharing rules based on ownership
- `Share` — manual or programmatic sharing

### cgcloud__Sales_Organization__c and Tenant Data Isolation

CGC uses `cgcloud__Sales_Organization__c` as the primary tenant isolation mechanism in multi-org or multi-division implementations. Most TPM objects have a `cgcloud__Sales_Org__c` field (often a formula referencing the Account Template's sales org). This drives:
- Business year scoping
- Promotion template availability
- Fund allocation boundaries
- RTR report dimension configuration

**Security implication:** Sharing rules and territory assignments should align with Sales Organization boundaries. Cross-Sales-Org data access is a common misconfiguration — always verify that users from Sales Org A cannot see Sales Org B's promotions or funds.

---

## Retail Order Security

The `cgcloud/orderExtensionUtils` LWC service component and `cgcloud.RE_Order` Apex class expose methods that operate within the transaction. Security considerations:
- The callable Apex hook (`CGCloud Process Customization` custom metadata) runs in the context of the saving user — FLS and CRUD are enforced
- The `registerWork(DoWork work)` post-commit hook also runs in user context — do NOT use `with sharing` bypass here
- Avoid direct DML on records that are part of the `RE_Order` transactional state — use `orderWrapper.append()` and `addRelationship()` to let the framework manage IDs

---

## Data Residency for Field Reps

In APAC implementations (Korea, Japan, China, India), mobile data residency requirements may mandate that sync data stays within a specific region. If the customer mentions data localization requirements:
1. Verify Salesforce Hyperforce regional instance availability for their region
2. The `cgc_sync` package must be configured against the correct instance domain
3. Named Credential and Remote Site Settings must point to regional endpoints

---

## Auditing and Compliance

- Enable field history tracking on Visit, AssessmentTask, and cgcloud__Order__c for audit trail
- `cgcloud__Transaction_Log__c` provides a system-level log of TPM transactions
- `cgc_sync__Sync_History__c` and `cgc_sync__Sync_API_Log__c` provide sync audit trails
- For GDPR: `cgcloud__Account_Extension__c` may contain personal data extensions — include in data mapping
