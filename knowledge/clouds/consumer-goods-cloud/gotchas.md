---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: gotchas
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Gotchas and Common Misconfigurations

## G-1: CGC Objects Not Available Without the Managed Package

The `cgcloud` namespace objects (Visit, RetailStore, AssessmentTask, cgcloud__Order__c, etc.) require the Consumer Goods Cloud managed package installed. Any Apex, Flow, or deployment referencing `cgcloud__` objects will fail with `INVALID_TYPE` if deployed to an org without the package. Always verify package installation before deploying.

## G-2: TPM Requires a Separate License

Trade Promotion Management (TPM) is a paid add-on to CGC. Objects like `cgcloud__Account_Plan__c`, `cgcloud__Fund__c`, `cgcloud__Payment__c`, `cgcloud__RTR_Report_Configuration__c` are only usable with the TPM license. Deploying TPM configuration without the license results in `INVALID_TYPE` errors. Confirm TPM licensing during discovery.

## G-3: Sync Management Requires a Separate Package

`cgc_sync__*` objects are in a separate managed package (Mobile Sync). The Consumer Goods license alone does not install it. Sync Management setup is required before the mobile offline app will function — it is NOT included or auto-configured by the base CGC package.

## G-4: runtimeNamespace Breaks @salesforce Imports

When the LWC component metadata file has `<runtimeNamespace>cgcloud</runtimeNamespace>`, the component CANNOT use `@salesforce` package imports (e.g., `@salesforce/apex`, `@salesforce/schema`). If your custom order screen LWC needs both `orderExtensionUtils` and `@salesforce/apex` calls, remove `runtimeNamespace` and enable Lightning Web Security (LWS) instead. LWS makes `runtimeNamespace` unnecessary.

## G-5: RE_Order Uses Temporary IDs — Never Bypass with Direct DML

Inside `RE_Order.Callable` hooks, records appended via `orderWrapper.append()` have temporary IDs until committed. If you use direct DML (`insert myRecord`) on a record that should be related to the order, the relationship cannot be resolved because the order's ID may not exist yet. Always use `orderWrapper.append()` and `orderWrapper.addRelationship()` — these let the framework resolve all IDs at commit time.

## G-6: RE_Order.DoWork Rolls Back the Entire Transaction on Exception

The `registerWork(DoWork)` post-commit hook runs AFTER the order and related records are committed. However, if `doWork()` throws any exception, **the entire transaction is rolled back** — including all the committed order records. Do not use `doWork()` for external callouts or operations that cannot be rolled back.

## G-7: Order Proposal List Callable Requires "Consider Listing" = Yes

The `RE_Order_Proposal_List` customization hook only fires if the Order Template has `Consider Listing` set to `Yes`. If the hook is registered but not firing, check the Order Template configuration first.

## G-8: cgcloud__Sales_Org__c Is a Formula — Not Filterable Efficiently

On many objects, `cgcloud__Sales_Org__c` is a calculated formula field (e.g., `TEXT(cgcloud__Account_Template__r.cgcloud__Sales_Org__c)`). Formula fields cannot be indexed. Filtering large datasets by Sales Org via this field will cause full-table scans. Where possible, use `cgcloud__Account_Template__c` (the lookup) for SOQL filters instead.

## G-9: Workflow State Transition picklist Is Restricted

`cgcloud__Workflow_State_Transition__c.cgcloud__From_Status__c` and `cgcloud__To_Status__c` are restricted picklists. The valid values are: Active, Approved, Cancelled, Check, Closed, Committed, Correction, ForApproval, Frozen, HoldBack, Planning, Ready, Rejected, Released, SendFax, WorkCompleted, final, initial, normal. You cannot add custom status values to this restricted picklist — any workflow state customization must use one of these existing values.

## G-10: Multi-Language Fields Need cgcloud__Language_Postfix__c Set on User

CGC description fields use a CASE formula on `$User.cgcloud__Language_Postfix__c` (values: Language1/Language2/Language3/Language4). If this field is not set on the User record, all description formulas fall back to `Description_Language_1__c`. For multilingual orgs, populate this field on every user record during setup — the Salesforce Locale setting alone does NOT drive this.

## G-11: Sync Config Performance Thresholds Have Specific Ranges

`cgc_sync__Sync_Config__c` performance fields have documented recommended ranges:
- `cgc_sync__Batch_Soql_Response_Time_Limit__c`: Range 2000-4000ms; recommended 4000ms
- `cgc_sync__CPU_Time_Calculation_Buffer__c`: Recommended 6500ms
- `cgc_sync__Download_Response_Time_Limit__c`: Range 2000-4000ms; recommended 2000ms
- `cgc_sync__Analyze_Threshold__c`: Range 100-100000

Values outside these ranges cause sync performance issues. Do not set these arbitrarily — use recommended values unless there is a specific performance-tuning reason.

## G-12: cgc_sync__Ignore_Client_Overrides__c Defaults to true

`cgc_sync__Sync_Config__c.cgc_sync__Ignore_Client_Overrides__c` defaults to `true`, meaning user-level and profile-level sync config overrides are ignored unless this flag is explicitly set to `false` at the org-level config. Teams that configure user-specific sync settings are often confused when they have no effect — this flag is the cause.

## G-13: AssessmentTask Bulk Insert Exceeds Flow DML Limits

Creating AssessmentTasks via Record-Triggered Flow on Visit insert hits the 150 DML per transaction limit quickly. A Visit with 50 task definitions = 50 AssessmentTask inserts. Batch-creating 10 Visits = 500 DML rows — well over the limit. Use a Queueable or Batch class for bulk AssessmentTask generation, not synchronous Flow.

## G-14: Visit Status Transitions Must Match Mobile App Expectations

The CGC mobile app expects specific `Visit.Status` values: `New`, `In Progress`, `Complete`, `Cancelled`. Custom intermediate statuses confuse the app's check-in/check-out flow. If adding intermediate statuses, test the mobile app check-in/check-out time tracking behavior thoroughly.

## G-15: Mobile Offline Requires Briefcase/Priming Configuration

The mobile app supports offline mode but requires explicit sync configuration:
1. Enable Mobile Offline in Setup
2. Configure Briefcase (what data syncs to device) per profile
3. Define named queries in `cgc_sync__Sync_Named_Query__c`
Missing this configuration = blank screens for offline reps in connectivity-poor areas. This is a go-live blocker.

## G-16: TPM Business Year Must Be Active for RTR Export

RTR KPI export functions are based on Sales Org, Business Year, and data source (account, promotion). All export functions require active Business Year records (`cgcloud__Business_Year__c`). Ensure Business Years are created and activated for each Sales Org before the first export — otherwise the export returns no data without any error message.

## G-17: Promotion Ingest API Has a 50-Promotion Limit Per Call

The TPM REST API endpoint `POST promotions/ingest` accepts a maximum of 50 promotion payloads per call. For bulk imports exceeding 50 promotions, the calling system must batch the requests. There is no automatic pagination or chunking — exceeding 50 results in a validation error.

## G-18: Account Hierarchy in cgcloud Can Be Deeply Nested

`cgcloud__Flatten_Account_Hierarchy__c` is provided specifically because traversing deep `ParentId` hierarchies via SOQL is limited to 5 levels and performs poorly. Use the flattened hierarchy object for reporting and search — do not write SOQL traversing Account.Parent.Parent.Parent chains.

## G-19: cgcloud__Trigger_Setting__c and cgcloud__Validation_Rules_Setting__c Are On/Off Switches

CGC provides these configuration objects to enable/disable individual managed package triggers and validation rules. They are frequently needed during data migration (turn off triggers before bulk load, turn back on after). However, these are **global** settings — there is no per-user or per-session disable. Always coordinate with the team before disabling in production.

## G-20: Objects for Future Use Should Not Be Used in Custom Development

The PDF section "Standard and Custom Objects for Future Use" lists objects including `cgcloud__Contract__c` family, `Shift`, `ShiftTemplate`, `TimeSheet`, `TimeSheetEntry`. These are present in the managed package but not yet supported by Salesforce for CGC use. Do not build custom logic on these objects — they may behave unexpectedly or be incompatible with future managed package upgrades.
