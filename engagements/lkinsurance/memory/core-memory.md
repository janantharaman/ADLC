# Core Memory — LKInsurance
**Org:** LKInsuranceDev
**Last updated:** 2026-04-29

## delivery-patterns
- org-alias: LKInsuranceDev
- trigger-pattern: all triggers use `.run()` delegation to `*_tr` handler classes — consistent pattern
- test-class-naming: `*_ts` suffix for test classes (LK convention, not the standard `*Test`)
- flow-naming: LK_TRG_ (record-triggered), LK_SCR_ (screen), LK_AUT_ (auto-launch), LK_BAT_ (batch/scheduled), LK_SCH_ (scheduled)
- apex-naming: COM_ (common), ACC_ (account), OPP_ (opportunity), CLM_ (claim), REC_ (reconciliation), SOA_ (statement of account), POL_ (policy)
- delivery-team: mixed Korean/English team; Korean names appear as i2max and trestle vendor teams

## org-constraints
- OrgLimit SOQL not queryable via standard API in this org — use Tooling API or admin UI check
- Profile.RequiresMfa field not available via SOQL — MFA status requires Setup UI check
- Account.trigger exists locally but not found in org retrieve — potential undeployed local change
- 642 objects returned from CustomObject retrieve includes platform/standard objects — filter for __c only for true custom object count (~45 LK-custom objects)
- OWD: LatestContractNumMgmt__c = ReadWrite both internal and external — HIGH RISK, financial object
- 37 users on System Administrator (C) profile — anomalously high, needs review

## common-failures
- OrgLimit query fails via standard SOQL — use Tooling API: SELECT CurrentValue, MaxValue FROM OrgLimit
- InstalledSubscriberPackage requires Tooling API (useToolingApi: true)
- ConnectedApplication.ContactEmail field does not exist — omit from queries
- Profile.RequiresMfa does not exist in SOQL — cannot query MFA status programmatically
- BotDefinition.Status field does not exist — use DeveloperName and MasterLabel only

## customer-preferences
- Korean-language descriptions appear in some permission sets (e.g., "CRS 담당자 OCR Test 를 위한 권한 관리") — bilingual artifact acceptable
- Active development by multiple vendor teams (i2max, trestle) simultaneously — expect frequent org changes
