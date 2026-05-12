# Naming Conventions — GDC Delivery Standards

These conventions apply to all Salesforce configuration and code produced during ADLC engagements.
Verify existing org config against these standards during Discovery. Apply them strictly during Implementation.

---

## General Rules

- Use PascalCase for API names (CustomObject__c, MyField__c)
- Use Title Case for labels ("My Custom Object", "My Field")
- No spaces, special characters, or abbreviations that aren't universally understood
- Prefix custom objects, fields, and classes with the project/product namespace where applicable
- Descriptions are mandatory on all custom objects, custom fields, and Apex classes

---

## Custom Objects

| Element | Convention | Example |
|---|---|---|
| API Name | PascalCase + __c | ServiceRequest__c |
| Label | Title Case, readable | Service Request |
| Plural Label | Title Case | Service Requests |
| Description | Required — purpose + owning team | "Tracks customer service requests. Owned by Service Cloud team." |

**Avoid:** Generic names (Item__c, Record__c, Data__c)
**Avoid:** Abbreviations (SvcReq__c, CustAcct__c)

---

## Custom Fields

| Element | Convention | Example |
|---|---|---|
| API Name | PascalCase + __c | RequestedDeliveryDate__c |
| Label | Title Case | Requested Delivery Date |
| Help Text | Required for non-obvious fields | "The date the customer requested delivery, not the scheduled date." |
| Description | Required | Business purpose of the field |

**Avoid:** Prefixing all fields with the object name (Account_Name__c on Account)
**Avoid:** Vague names (Flag__c, Status2__c, Temp__c)

---

## Apex Classes

| Element | Convention | Example |
|---|---|---|
| Class name | PascalCase, descriptive noun | ServiceRequestHandler |
| Test class | Same name + Test suffix | ServiceRequestHandlerTest |
| Trigger handler | Object + Handler | AccountHandler |
| Service class | Domain + Service | OpportunityService |
| Batch class | Domain + Batch | ContactCleanupBatch |
| Scheduler | Domain + Scheduler | ContactCleanupScheduler |

**One trigger per object** — triggers call a handler class, no logic in the trigger body.
**No SOQL in loops** — always bulkify.
**Test coverage minimum: 85%** — 75% is the platform minimum, GDC standard is 85%.

---

## Flows

| Element | Convention | Example |
|---|---|---|
| API Name | ObjectName_TriggerType_Purpose | Account_BeforeSave_SetDefaults |
| Label | Readable description | Account: Set Defaults Before Save |
| Description | Required — what it does and why | "Sets default values on Account before save. Created for PI-12 onboarding." |

**Naming pattern for trigger type:**
- Record-Triggered (Before Save): `Object_BeforeSave_Purpose`
- Record-Triggered (After Save): `Object_AfterSave_Purpose`
- Screen Flow: `Object_Screen_Purpose`
- Scheduled: `Object_Scheduled_Purpose`
- Auto-launched: `Object_AutoLaunch_Purpose`

**One Flow per trigger context per object** — do not create multiple Before Save flows on the same object.

---

## Permission Sets

| Element | Convention | Example |
|---|---|---|
| API Name | Role_Cloud_Access | ServiceAgent_ServiceCloud_Standard |
| Label | Human-readable | Service Agent - Service Cloud Standard |
| Description | Required — who gets this and why | "Standard access for Service Cloud agents. Assigned to all Tier 1 support staff." |

**Never modify standard profiles** — use permission sets.
**Stack permission sets** — one base set per cloud, add-ons for specific features.

---

## Validation Rules

| Element | Convention | Example |
|---|---|---|
| API Name | Object_Rule_Purpose | Account_Require_BillingAddress |
| Description | Required — what it checks and why | "Requires billing address on all Accounts with active Opportunities." |
| Error message | Plain English, actionable | "Please enter a billing address before saving. This is required for invoicing." |

---

## Custom Labels

| Element | Convention | Example |
|---|---|---|
| Name | Category_Purpose | Error_InvalidEmail |
| Value | Plain English | "Please enter a valid email address." |
| Categories | Use consistent category prefixes | Error_, Success_, Label_, Message_ |

---

## Named Credentials

| Element | Convention | Example |
|---|---|---|
| Name | System_Environment | PaymentGateway_Production |
| Label | Human-readable | Payment Gateway (Production) |

---

## Custom Metadata Types

| Element | Convention | Example |
|---|---|---|
| Object API Name | Purpose + __mdt | FeatureFlag__mdt |
| Record API Name | Feature_Setting | EnableBetaFlow_Config |

---

## Sandboxes

| Sandbox | Purpose | Refresh Cadence |
|---|---|---|
| dev | Developer testing | Weekly |
| qa | QA and UAT | Per release |
| staging | Pre-production validation | Per release |
| training | User training | Per quarter |

**Never develop directly in production.**
**Never deploy directly from dev to production** — always go through QA and staging.
