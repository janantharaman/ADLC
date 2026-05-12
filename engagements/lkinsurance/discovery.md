# Discovery — LKInsurance
**Status:** DRAFT
**Date:** 2026-04-29
**Version:** 1
**Org:** LKInsuranceDev
**Pre-Sales artifact:** N/A (Phase 0 skipped — no pre-sales.md present)

---

## Summary

LKInsurance is a Korean insurance brokerage firm running a mature Salesforce FSC org (Financial Services Cloud with Insurance features). The org contains 45+ custom domain objects across insurance placement, claims, reconciliation, settlements, and policy management, supported by 175 Apex classes, 12 triggers, 269 flows, and 80 LWC components — all actively developed by two vendor teams (i2max and trestle). Key risks are: (1) 37 of 74 active users are on the System Administrator (C) profile — a significant least-privilege violation for an insurance org handling financial data; (2) `LatestContractNumMgmt__c` has OWD = Public Read/Write internally and externally — a HIGH RISK for a financial sequencing object; (3) 10 unmanaged installed packages have no namespace and unclear ownership; and (4) approximately 15–20 dev/test flows exist in production that should be decommissioned. No pre-sales artifact exists; requirements gathering is an open action item before Design can begin.

---

## Org Health Baseline

### Objects (45 LK-custom domain objects + managed/platform objects)

| Object API Name | Label | Domain | OWD (Internal) | OWD (External) | Risk |
|---|---|---|---|---|---|
| ACC_AdditionalInfo__c | Additional Account Info | Account | Private | Private | OK |
| ACC_KYC__c | KYC | Account (KYC) | Private | Private | OK |
| ACC_News__c | News | Account | **ReadWrite** | Private | MEDIUM — internal ReadWrite |
| AccountDepositor__c | Account Depositor | Account/Banking | Private | Private | OK |
| BankTransaction__c | Bank Transaction | Reconciliation | Private | Private | OK |
| CLM_Allocation__c | Claim Allocation | Claims | ControlledByParent | ControlledByParent | OK |
| CLM_LocationOfLoss__c | Location of Loss | Claims | ControlledByParent | ControlledByParent | OK |
| CLM_LocationOfLossJunction__c | Location of Loss Junction | Claims | ControlledByParent | ControlledByParent | OK |
| COA__c | Chart of Accounts | Finance | Private | Private | OK |
| COM_ApprovalLineMgmt__c | Approval Line Management | Common | **ReadWrite** | Private | MEDIUM — internal ReadWrite |
| COM_Facility__c | Facility | Placement | Read | Private | OK |
| COM_FacilityBDX__c | Facility BDX | Placement | Read | Private | OK |
| COM_FacilityBDXLineItem__c | Facility BDX Line Item | Placement | ControlledByParent | ControlledByParent | OK |
| COM_FacilityParticipant__c | Facility Participant | Placement | Read | Private | OK |
| COM_InsurerCommission__c | Insurer Commission | Finance | Private | Private | OK |
| COM_Note__c | Note | Common | Private | Private | OK |
| COM_NumberCounter__c | Number Counter | Common | **ReadWrite** | Private | MEDIUM — internal ReadWrite |
| COM_OrganizationInfo__c | Organization Info | Common | **ReadWrite** | Private | MEDIUM — internal ReadWrite |
| COM_RiskSurveyReport__c | Risk Survey Report | Underwriting | Private | Private | OK |
| COM_TermsandConditions__c | Terms and Conditions | Common | Private | Private | OK |
| COM_VariousApprovalMgmt__c | Various Approval Management | Common | **ReadWrite** | Private | MEDIUM — internal ReadWrite |
| ExchangeRate__c | Exchange Rate | Finance | Private | Private | OK |
| FiduciaryOthers__c | Fiduciary Others | Finance | Private | Private | OK |
| Insurance_Policy_Coverage_Lineitem__c | Insurance Policy Coverage Line Item | Policy | ControlledByParent | ControlledByParent | OK |
| InsurancePolicyLineItem__c | Insurance Policy Line Item | Policy | Private | Private | OK |
| LatestContractNumMgmt__c | Latest Contract Number Management | Finance | **ReadWrite** | **ReadWrite** | **HIGH — both internal & external ReadWrite; financial sequencing object** |
| OPP_Cobroker__c | Co-Broker | Opportunity | ControlledByParent | ControlledByParent | OK |
| OPP_Layer__c | Layer | Opportunity | ControlledByParent | ControlledByParent | OK |
| OPP_Panel__c | Panel | Opportunity | ControlledByParent | ControlledByParent | OK |
| OPP_PremiumSchedule__c | Premium Schedule | Opportunity | Private | Private | OK |
| OPP_SlipInfo__c | Slip Info | Opportunity | Private | Private | OK |
| OPP_Subjectivity__c | Subjectivity | Opportunity | Private | Private | OK |
| OPP_TSIByLocation__c | TSI By Location | Opportunity | ControlledByParent | ControlledByParent | OK |
| OutwardFund__c | Outward Fund | Finance | Private | Private | OK |
| OutwardFundLineItem__c | Outward Fund Line Item | Finance | ControlledByParent | ControlledByParent | OK |
| PeriodClose__c | Period Close | Finance | **ReadWrite** | Private | MEDIUM — internal ReadWrite; financial control object |
| Placement__c | Placement | Placement | Private | Private | OK |
| PlacementLineItem__c | Placement Line Item | Placement | Private | Private | OK |
| POL_Buyer__c | Policy Buyer | Policy | Private | Private | OK |
| Reconciliation__c | Reconciliation | Finance | Private | Private | OK |
| ReconciliationLineItem__c | Reconciliation Line Item | Finance | ControlledByParent | ControlledByParent | OK |
| Settlement__c | Settlement | Finance | Private | Private | OK |
| SettlementLineItem__c | Settlement Line Item | Finance | Private | Private | OK |
| SLP_PanelJunction__c | Slip Panel Junction | Placement | Private | Private | OK |
| SOA_NoteJunction__c | SOA Note Junction | Finance | ControlledByParent | ControlledByParent | OK |
| SOA_Statement__c | SOA Statement | Finance | Private | Private | OK |
| Statement__c | Statement | Finance | Private | Private | OK |
| StatementLineItem__c | Statement Line Item | Finance | Private | Private | OK |

**Documentation gaps:** Most custom objects lack descriptions — violates GDC naming-conventions standard. Requires remediation in Design phase.

---

### Apex Classes (175 total)

| Class Name | Type | Has `_ts` Test Class? | Notes |
|---|---|---|---|
| ACC_AccountContactDigestCtrl | Controller | No | No corresponding _ts found |
| ACC_AdditionalAccountInfo_tr | Trigger Handler | Yes (ACC_AdditionalAccountInfo_tr_ts) | Follows _tr pattern |
| ACC_NaverNewsDelete_ba | Batch | Yes (_ts) | Deletes Naver news records |
| ACC_NaverNewsFetch_ba | Batch | Yes (_ts) | Fetches from Naver news API — external callout |
| ACC_NaverNewsFetch_sc | Scheduler | No separate _ts | Scheduler for news fetch |
| ACC_NaverNewsFetch_sv | Service | No | Naver API service class |
| ACC_News_Ctrl | Controller | Yes (_ts) | |
| ACC_TestDataFactory | Test Factory | N/A | |
| AccSecurityListAction_Ctrl | Controller | No | |
| AccountDepositorService | Service | No | |
| AccountDepositor_tr | Trigger Handler | Yes (_ts) | |
| AdditionalAccountInfoCheckActive_ba | Batch | Yes (_ts) | |
| BankTransactionService | Service | No | |
| BankTransaction_tr | Trigger Handler | No explicit _ts found | |
| CLM_DocGenEmailLink_Ctrl | Controller | Yes (_ts) | |
| CLM_QuickAction_Ctrl | Controller | Yes (_ts) | |
| CLM_SocPlaAllocationManage_Ctrl | Controller | Yes (_ts) | |
| COM_Cache | Service | Yes (_ts) | |
| COM_ContentDocumentLink_tr | Trigger Handler | No | File-related trigger handler |
| COM_ContentDocument_tr | Trigger Handler | No | |
| COM_DocGen_Ctrl | Controller | Yes (_ts) | DocGen controller |
| COM_EmailHeader_Ctrl | Controller | Yes (_ts) | |
| COM_FileList_Ctrl | Controller | Yes (_ts) | |
| COM_GoogleMapService | Service | Yes (_ts) | External callout — Google Maps |
| COM_Lookup_Ctrl | Controller | Yes (_ts) | |
| COM_MetaUtil | Utility | Yes (_ts) | |
| COM_Note_Ctrl | Controller | Yes (_ts) | |
| COM_Option | Utility | Yes (_ts) | |
| COM_RecordList_Ctrl | Controller | Yes (_ts) | |
| COM_RecordListEmail_Ctrl | Controller | No | |
| COM_TypeaheadPicklist_Ctrl | Controller | Yes (_ts) | |
| COM_Util | Utility | Yes (_ts) | |
| ClaimPLAUpdateHandler | Handler | Yes (ClaimPLAUpdateHandlerTest) | Note: uses Test suffix, not _ts |
| ClaimSOCUpdateHandler | Handler | Yes (ClaimSOCUpdateHandlerTest) | Note: uses Test suffix, not _ts |
| DocGenBatchProcess_tr | Trigger Handler | Yes (_ts) | |
| DocGenFormulaHelper | Helper | No | |
| DocumentAIPolicyProcessor | AI Processor | Yes (DocumentAIPolicyProcessorTest) | Agentforce/OCR integration |
| ExcelFileUploadController | Controller | No | |
| ExceptionSimulator | Test Utility | N/A | Dev/test utility — should not be in production |
| ExchangeRateService | Service | Yes (_ts) | |
| ExchangeRate_tr | Trigger Handler | No | |
| ExtractDocumentAIClaimDetails | AI Processor | Yes (ExtractDocumentAIClaimDetailsTest) | |
| ExtractDocumentAIDetails | AI Processor | Yes (ExtractDocumentAIDetailsTest) | |
| FSCPolicyFlowProcessor | Flow Processor | No | |
| FSCPolicyUpdDataMapperLKTest | Test | N/A | Standalone test |
| FacilityBDXDocGen | DocGen | No | |
| FiduciaryOthers_tr | Trigger Handler | No | |
| JSONParserHelper | Helper | No | |
| MappingTable | Utility | No | |
| NumberCounterFlowAction | Flow Action | No | |
| OPP_MarketLine_Ctrl | Controller | Yes (_ts) | |
| OPP_MarketLineRuleService | Service | No | |
| OPP_MarketLineService | Service | No | |
| OPP_Opportunity_tr | Trigger Handler | No | |
| OPP_RISlipInfo_Ctrl | Controller | No | |
| OPP_SlipInfo_tr | Trigger Handler | No | |
| OPP_TSIUpload_Ctrl | Controller | No | |
| OPP_TestDataFactory | Test Factory | N/A | |
| Opp_BrokerageSummary_Ctrl | Controller | Yes (_ts) | |
| Opp_LkCoBroking_Ctrl | Controller | Yes (_ts) | |
| Opp_MarketLineContainer_Ctrl | Controller | Yes (_ts) | |
| Opp_PremiumFromCedent_Ctrl | Controller | Yes (_ts) | |
| Opp_PremiumSchedule_Ctrl | Controller | Yes (_ts) | |
| Opp_ProducingCoBroking_Ctrl | Controller | Yes (_ts) | |
| Opp_SimulationPanel_Ctrl | Controller | Yes (_ts) | |
| Opp_TotalOrderSignedModal_Ctrl | Controller | Yes (_ts) | |
| POL_BuyerUpload_Ctrl | Controller | Yes (_ts) | |
| PolicyDataProcessor | Processor | Yes (PolicyDataProcessorTest) | |
| PolicyDataProcessorPA | Processor | No | |
| REC_* (18 classes) | Domain/Selector/Service | Partial — _ts variants exist | Reconciliation domain; layered architecture |
| RIClosingSlipDocGen | DocGen | No | |
| RecordLockStatus | Utility | Yes (RecordLockStatusTest) | |
| SOA_NoteManager_Ctrl | Controller | Yes (_ts) | |
| SettlementLineItem_tr | Trigger Handler | No | |
| SlipInfoProcessor | Processor | Yes (multiple test classes) | |
| TriggerHandler | Base Class | Yes (_ts) | Framework base — all triggers extend this |
| UpdateRelatedExchangeRateQueueable | Queueable | No | Async FX update |
| UserService | Service | No | |
| Util | Utility | No | Generic utility — no namespace prefix |

**Test class count:** 136 of 175 classes have corresponding `_ts` or `Test` variants (~78% coverage by class count). Note: `ExceptionSimulator` is a dev utility that should not be in production.

**Naming inconsistency:** `ClaimPLAUpdateHandler` and `ClaimSOCUpdateHandler` use `Test` suffix instead of `_ts` — violates LK convention. `Util` and `UserService` lack namespace prefixes.

---

### Apex Triggers (12 total)

| Trigger Name | Object | Delegates to Handler? | Handler Class | Notes |
|---|---|---|---|---|
| Account | Account | Yes | Account_tr | Note: not found in org retrieve — may be undeployed |
| AccountDepositor | AccountDepositor__c | Yes | AccountDepositor_tr | |
| AdditionalAccountInfoTrigger | ACC_AdditionalInfo__c | Yes | ACC_AdditionalAccountInfo_tr | Trigger name doesn't match handler naming convention |
| BankTransaction | BankTransaction__c | Yes | BankTransaction_tr | |
| ContentDocument | ContentDocument | Yes | COM_ContentDocument_tr | |
| ContentDocumentLink | ContentDocumentLink | Yes | COM_ContentDocumentLink_tr | |
| DocGenerationBatchProcess | DocGenerationBatchProcess | Yes | DocGenBatchProcess_tr | Platform object trigger |
| ExchangeRate | ExchangeRate__c | Yes | ExchangeRate_tr | |
| FiduciaryOthers | FiduciaryOthers__c | Yes | FiduciaryOthers_tr | |
| OPP_SlipInfoTrigger | OPP_SlipInfo__c | Yes | OPP_SlipInfo_tr | Trigger name inconsistent with handler |
| Opportunity | Opportunity | Yes | OPP_Opportunity_tr | |
| SettlementLineItem | SettlementLineItem__c | Yes | SettlementLineItem_tr | |

**Positive finding:** All 12 triggers follow the single-trigger-per-object pattern and delegate to handler classes via `.run()`. No logic in trigger bodies. This is GDC best practice compliant.

**Issue:** `Account` trigger exists locally but returned a "cannot be found" error during org retrieve — indicates the trigger may not be deployed in the org.

---

### LWC Components (80 total — 0 Aura)

| Component Name | Domain | Notes |
|---|---|---|
| accNewsContainer / accNewsItem | Account/News | Naver news display |
| accSecurityList | Account | Security list view |
| bankTransactionUploadCmp | Reconciliation | Excel upload |
| clmPLASOCDocGenWrapper / clmPostActionWrapper / clmQuickAction | Claims | DocGen and quick actions |
| clmSocPlaAllocationManage / LineItems / Summary | Claims | SOC/PLA allocation management |
| comAddressSearchModal / comDocGenQuickAction / comFacilityBdxLineItemList | Common | Shared utilities |
| comFileList / comLookup / comModal / comMultiPicklist / comNoRecords | Common | Shared UI components |
| comNoteList / comNoteListFilter / comPicklist / comRecordList | Common | Common list components |
| comTypeaheadPicklist | Common | Typeahead search |
| docgenQuickAction | Common | Doc generation |
| evaSettlementLineItemInquiry | Finance | Settlement inquiry |
| excelFileUploadLayout / exchangeRateUploadCmp | Finance | Upload utilities |
| oppBrokerageSummary / oppCobrokerConfirmModal / oppLKCoBroking | Opportunity | Brokerage management |
| oppMarketLine* (8 components) | Opportunity | Market line management suite |
| oppPremiumFromCedent / oppPremiumSchedule | Opportunity | Premium components |
| oppProducingCoBroking / oppProducingCoBrokingSingle | Opportunity | Co-broking |
| oppRISlipInfo / oppRQDocgenWrapper | Opportunity | RI slip management |
| oppSimulation / oppSlipInfo / oppSlipInfoRIClosingModal | Opportunity | Slip workflow |
| oppTSIByLocationTable / oppTSIExcelUpload | Opportunity | TSI management |
| oppTotalOrderSignedModal | Opportunity | Order signing |
| polBuyerExcelGrid / polBuyerExcelUpload / polCreateLineItems / polDocGenWrapper | Policy | Policy management |
| recBankTransactionBased / recBankTransactionInquiry | Reconciliation | Bank transaction recon |
| recCellLookup / recFiduciaryMappingModal / recFilterBar / recFilterField | Reconciliation | Recon utilities |
| recOutwardFundsRecordPage / recPeriodSelector / recReconciliationInquiry | Reconciliation | Recon workflow |
| recRelatedReconciliationModal / recReverseOffset / recSchemaService | Reconciliation | Advanced recon |
| recSettlementLineItemBased / recSettlementLineItemInquiry / recSplitSliModal | Reconciliation | Settlement line items |
| recTable / recTableCell / recUtils | Reconciliation | Recon table framework |
| recalculateFxButton / recalculateFxByPeriodButton | Finance | FX recalculation |
| soaNoteManage / soaNoteManageFilter / tempSoa | Finance/SOA | Statement of accounts |
| zChartjsTest | Test/Dev | Dev test component — should be decommissioned |

**No Aura components found** — no LWC migration work required. All components are modern LWC.

**Issue:** `zChartjsTest` is a dev test component that should be decommissioned from production.

---

### Automation Inventory

**Active Flows (269 total)** — breakdown by naming convention:

| Type Prefix | Count | Description |
|---|---|---|
| LK_TRG_ | 43 | Record-triggered flows |
| LK_SCR_ | 62 | Screen flows |
| LK_AUT_ | 30 | Auto-launched flows |
| LK_BAT_ | 6 | Batch/scheduled flows |
| LK_SCH_ | 2 | Scheduled flows |
| Document_AI / ExtractKR* | 8 | Agentforce/AI document processing |
| Project management (PMS) | ~45 | i2PMS project management flows |
| Dev/Test flows | ~15 | TEST, google, hiotest*, WJLEE_BK, LWJ_Test*, Number_1_Test, Slip_TEST, tmp_* |
| Unnamed/other | ~58 | General flows not matching LK convention |

**Key LK domain flows observed:**
- Insurance Policy: `LK_TRG_InsurancePolicy_AmountUpdate`, `LK_TRG_InsurancePolicy_NameUpdate`, `LK_BAT_InsurancePolicy_InceptionDatePostingCheck`, `LK_BAT_InsurancePolicy_RenewalOpptyCreate`
- Placement: `LK_AUT_Placement_ProrationCacl`, `LK_SCR_Placement_Closing`, `LK_SCR_PlacementLineItem_*` (adjustment, posting, send to closing, cancel, reverse)
- Claims: `LK_TRG_Claim_*`, `LK_SCR_Claim_*`, `LK_SCR_ClaimAllocation_*`
- Reconciliation/Finance: `LK_SCH_PeriodClose_*`, `LK_AUT_Record_Lock/UnLock`
- Agentforce: `Document_AI_Flow_for_Claim_Settlement`, `Document_AI_Flow_for_Insurance_Policy`, `ExtractKRPolicyDetailsFromDoc`, `ExtractSlipInformationKR`

**Legacy Automation:** No Process Builder or Workflow Rules detected.

**Flows requiring decommission (dev/test artifacts in production):**
- TEST, Slip_TEST, Number_1_Test, LWJ_Test, LWJ_Test_T_C, WJLEE_BK, google, hiotest05_dt_EditOneRow, hiotest05_dt_EditOneRow_Launched, hiotest06_dt_EditManyRow, hiotest07_dt_InsertRow, hiotest07_dt_Insert_Launched, tmp_Contract_DocNo_OnCreate, X_LK_SCR_* (4 deactivated variants), DemoFlow_DeepClone

---

### Prompt Templates (0 total)

No Prompt Templates found in the org. Agentforce agents rely exclusively on Flow and Apex actions. Einstein/GenAI document analysis uses the ADL_ Data Library objects rather than Prompt Templates.

---

### Agentforce Agents (4 total)

| Agent Name | Developer Name | Status | Notes |
|---|---|---|---|
| Agentforce Employee Agent | Agentforce_Employee_Agent | Active | Internal employee-facing agent |
| Agentforce Service Agent | Agentforce_Service_Agent | Active | Customer service agent |
| Document Analysis Agent | Document_Analysis_Agent | Active | Insurance document OCR/AI analysis |
| Flow Automation Agent | Flow_Automation_Agent | Active | Flow-driven automation agent |

**Agentforce License Assignments:**
- `Use_Flow_Automation_Agent`: 16 users — broad access
- `AgentforceServiceAgentUserPsg`: 2 users (agent system users)
- `Agentforce_Service_Agent1336560054_Permissions`: 1 user
- `Document_Analysis_Agent1315916709_Permissions`: 1 user

**Topics and Actions:** Not retrievable via SOQL/BotDefinition in this org configuration — requires manual Setup UI inspection.

**ADL Objects detected** (AI Data Library — for document grounding):
- ADL_AllInsuranceTyp, ADL_Document_Analys, ADL_PackageInsuranc, ADL_TestHPV, ADL_TestLib, ADL_package_insuran (each with __dll/__dlm variants) — used by Document Analysis Agent for insurance document parsing.

---

### Code Quality

Code Analyzer was attempted but requires individual file targeting, not directory-level scanning in this MCP tool version. Manual review of trigger bodies confirmed:
- All triggers are thin delegation wrappers (1 line of logic) — no SOQL, no DML, no business logic in trigger bodies.
- `TriggerHandler` base class present — framework pattern in use.

**Known risk patterns identified from class review:**
- `ExceptionSimulator` class exists in production — this is a test utility that should not be deployed to non-dev environments.
- `ACC_NaverNewsFetch_ba/sv` performs external callouts to Naver news API — no Named Credential confirmed via metadata, needs verification.
- `COM_GoogleMapService` performs external callouts — no Named Credential confirmed.
- Classes without test coverage (`_ts` equivalents): ~37 classes (~21%) lack identified test counterparts.

---

### Users and Permissions

- **Total active users:** 74
- **Active profiles in use:**

| Profile | User Count | Risk |
|---|---|---|
| System Administrator (C) | 37 | **HIGH RISK — 50% of users are Sys Admins** |
| LK_Team Member | 5 | OK |
| LK_Team Leader | 5 | OK |
| LK_Operation Member | 4 | OK |
| Standard User (C) | 8 | Review needed |
| Einstein Agent User | 2 | OK — system users |
| LK_Executive | 1 | OK |
| LK_Middle Office | 1 | OK |
| (X)LK_Executive | 1 | MEDIUM — prefixed with (X), may be deprecated |
| Sales Insights Integration User | 1 | OK |
| Salesforce API Only System Integrations | 1 | OK |
| SalesforceIQ Integration User | 1 | OK |
| Agentforce Guest User Profile | 1 | OK |
| Null (unknown) | 3 | Review needed |

- **Custom permission sets:** 47 total
- **Key LK permission sets:**
  - `LK_CRS_OCR_Test` — 18 users assigned (OCR/CRS testing)
  - `LK_UAT_Mgmt_PermSet` — 20 users assigned (UAT management)
  - `LK_Perm_FSC_Insurance` — 4 users (FSC Insurance access)
  - `LK_Integartion` [sic] — API integration (typo in name)
  - `LK_RE_TEST` — reinsurance test permissions
  - `LK_Posting_hio` — posting test for one user

**Issues:**
- `LK_Integartion` (sic) — typo in permission set API name; cannot be renamed without reassigning
- Multiple permission sets have null descriptions: `LK_Perm_FSC_Insurance`, `LK_UAT_Mgmt_PermSet`, `LK_RE_TEST`, `LK_Posting_hio`
- `onlyAdmin_dev` permission set exists — dev-only permission set should not be in production

---

### API Limits

OrgLimit object is not queryable via standard SOQL in this org. Limit status must be checked via Tooling API or Setup > Company Information. **This is an open question.**

---

### Installed Packages (26 total)

| Package | Namespace | Version | Type | Risk |
|---|---|---|---|---|
| AutoNavigate_Refresh | None | 1.0 | **Unmanaged** | HIGH — no namespace, no support |
| CDPAdvertising | cdpactvstrgptnr | 3.21 | Managed | OK |
| CollectionActionsL | None | 3.2 | **Unmanaged** | HIGH |
| DashboardPal | Dashboard_Pal | 2.6 | Managed | OK |
| Data Fetcher | joshdaymentlabs | 2.5 | Managed | LOW |
| datatable | None | 4.3 | **Unmanaged** | HIGH |
| fileUploadImproved | None | 2.0 | **Unmanaged** | HIGH |
| Flow Launcher | joshdaymentlabs | 1.4 | Managed | LOW |
| FlowActionsBasePack | usf3 | 3.19 | Managed | LOW |
| FlowScreenComponentsBasePack | None | 3.3 | **Unmanaged** | HIGH |
| GS_Sales_Reports_Dashboards | None | 1.0 | **Unmanaged** | HIGH |
| i2PMS | None | 1.0 | **Unmanaged** | HIGH — project management tool, large footprint |
| Nebula Logger - Unlocked Package | None | 4.16 | Unlocked | MEDIUM — unlocked pkg, no ISV support |
| ReactiveCollectionProcessors | None | 1.0 | **Unmanaged** | HIGH |
| RecordLockStatus | None | 1.0 | **Unmanaged** | HIGH |
| RelatedFiles | RelFiles | 1.6 | Managed | LOW |
| Sales Cloud | cdp_crm_dk1 | 1.4 | Managed (CDP) | OK |
| Sales Insights | OIQ | 1.0 | Managed | OK |
| Salesforce CDP CRM Loyalty | cdp_crm_dk4 | 1.8 | Managed | OK |
| Salesforce Connected Apps | sf_com_apps | 1.7 | Managed | OK |
| Salesforce Mobile Apps | sf_chttr_apps | 1.24 | Managed | OK |
| Salesforce Standard Data Model | ssot | 1.122 | Managed | OK |
| Salesforce.com CRM Dashboards | None | 1.0 | **Unmanaged** — Summer 2011 | HIGH — very old, no updates since 2011 |
| Service Cloud | cdp_crm_dk2 | 7.0 | Managed (CDP) | OK |
| Style Overwrite | SF_JY | 0.1 | Managed | LOW |
| Trailhead Playground | trlhdtips | 2.5 | Managed | LOW |

**10 unmanaged packages** — each is an upgrade and security risk. `Salesforce.com CRM Dashboards` (2011) is particularly concerning — should be evaluated for removal.

---

### Security Model

**Org-Wide Defaults — Findings:**

| Risk Level | Object | OWD | Issue |
|---|---|---|---|
| **HIGH** | LatestContractNumMgmt__c | ReadWrite (both) | Financial sequencing object fully open |
| MEDIUM | ACC_News__c | Internal ReadWrite | News object writable by all internal users |
| MEDIUM | COM_ApprovalLineMgmt__c | Internal ReadWrite | Approval configuration writable by all |
| MEDIUM | COM_NumberCounter__c | Internal ReadWrite | Counter object; risk of concurrent write conflicts |
| MEDIUM | COM_OrganizationInfo__c | Internal ReadWrite | Org config writable by all |
| MEDIUM | COM_VariousApprovalMgmt__c | Internal ReadWrite | Approval management writable by all |
| MEDIUM | PeriodClose__c | Internal ReadWrite | Financial period control object |
| MEDIUM | hiotest__c | Internal ReadWrite | Dev test object in production |
| MEDIUM | ers_datatableConfig__c | Internal ReadWrite | Config object writable by all |
| MEDIUM | FlowPersonalConfiguration__c | Internal ReadWrite | Flow config; acceptable if user-owned |
| MEDIUM | FlowTableViewDefinition__c | Internal ReadWrite | Flow view config; acceptable if user-owned |
| MEDIUM | In_App_Checklist_Settings__c | Internal ReadWrite | Checklist config |
| MEDIUM | LoggerSettings__c | Internal ReadWrite | Nebula Logger config; OK if Org-wide setting |
| INFO | Member__c | Internal ReadWrite | Project member object; likely intentional |

**MFA Status:** Cannot be queried via SOQL (`RequiresMfa` field not available). Requires Setup UI verification. **Open question.**

**Profiles:** No standard profiles appear to be used for operational users. LK-custom profiles (`LK_Team Member`, `LK_Team Leader`, `LK_Operation Member`, `LK_Executive`, `LK_Middle Office`) are in use — correct pattern. However, 37 users on `System Administrator (C)` is a critical least-privilege violation.

**Connected Apps — Risk Items:**
- `Workbench` — open to all users (OptionsAllowAdminApprovedUsersOnly = false) — developer tool should be restricted
- `Ant Migration Tool`, `Force.com IDE` — open to all users — should be admin-approved only
- `Dataloader Bulk`, `Dataloader Partner` — open to all users — acceptable for this org type if users need bulk operations
- `OIQ_Integration` — open to all users (OptionsAllowAdminApprovedUsersOnly = false) — Sales Insights integration; should be restricted to integration user only
- `Git_Backup_App` — admin-approved only — correct

---

## Requirements Assessment

No pre-sales artifact exists. Requirements were not formally captured in Phase 0. The following is inferred from the org analysis:

### Requirement: Insurance Policy Lifecycle Management
- **Status:** PARTIAL (inferred from org)
- **Existing config:** FSC Insurance objects in use (InsurancePolicy, InsurancePolicyLineItem, InsurancePolicyCoverage); custom objects OPP_SlipInfo__c, Placement__c, PlacementLineItem__c; 60+ policy/placement flows
- **Conflicts:** Multiple parallel screen flows for the same process (e.g., `LK_SCR_InsurancePolicyLineItem_*` has both active and X_-prefixed deprecated variants)
- **Constraints:** Record locking pattern in use via `LK_AUT_InsurancePolicyLineItem_RecordLock/Unlock`
- **Notes:** Formal requirements needed before Design

### Requirement: Claims Management
- **Status:** PARTIAL (inferred)
- **Existing config:** Standard Claim object with CLM_Allocation__c, CLM_LocationOfLoss__c, CLM_LocationOfLossJunction__c; 20+ claim flows
- **Notes:** PLA (Payment/Loss Allocation) and SOC (Statement of Claims) patterns identified from class names

### Requirement: Reconciliation / Financial Settlement
- **Status:** PARTIAL (inferred)
- **Existing config:** Reconciliation__c, Settlement__c, SettlementLineItem__c, OutwardFund__c, SOA_Statement__c, Statement__c; full REC_ domain Apex with layered selector/domain pattern; 20+ rec/settlement LWC components
- **Notes:** Mature financial reconciliation domain

### Requirement: AI/Agentforce Document Analysis
- **Status:** PARTIAL (inferred)
- **Existing config:** 4 Agentforce agents; ADL_ Data Library objects for grounding; DocumentAIPolicyProcessor, ExtractDocumentAIDetails Apex classes; `Document_AI_Flow_for_Claim_Settlement`, `Document_AI_Flow_for_Insurance_Policy`
- **Notes:** Active Agentforce usage; KR (Korean) policy extraction flows indicate Korean-language document processing

### Requirement: FX / Exchange Rate Management
- **Status:** SUPPORTED (inferred)
- **Existing config:** ExchangeRate__c, ExchangeRateService, ExchangeRate trigger, UpdateRelatedExchangeRateQueueable, recalculateFxButton/recalculateFxByPeriodButton LWC
- **Notes:** FX management appears complete

---

## FLS Matrix

FLS matrix requires formal scope confirmation and stakeholder agreement on objects in scope. Cannot produce a complete FLS matrix without confirmed requirements. The following objects are flagged as in-scope candidates based on org analysis:

- Placement__c, PlacementLineItem__c
- InsurancePolicyLineItem__c, Insurance_Policy_Coverage_Lineitem__c
- Settlement__c, SettlementLineItem__c
- Reconciliation__c, ReconciliationLineItem__c
- OPP_SlipInfo__c, OPP_PremiumSchedule__c

**FLS matrix will be produced in Design phase after scope confirmation.**

---

## Key Risks

1. **HIGH — Excessive System Administrator access:** 37 of 74 active users (50%) are on System Administrator (C) profile. For an insurance org handling financial data, this violates least-privilege principles and audit requirements. Mitigation: Audit and re-profile users to appropriate LK_ profiles before any production changes.

2. **HIGH — LatestContractNumMgmt__c OWD = Public Read/Write:** This is a financial contract number sequencing object. Public Write access means any user can corrupt the sequence. Mitigation: Set OWD to Private and create a sharing rule for authorized users only.

3. **HIGH — 10 unmanaged packages in production:** Packages without namespaces (`AutoNavigate_Refresh`, `CollectionActionsL`, `datatable`, `fileUploadImproved`, `FlowScreenComponentsBasePack`, `GS_Sales_Reports_Dashboards`, `i2PMS`, `ReactiveCollectionProcessors`, `RecordLockStatus`, `Salesforce.com CRM Dashboards`) have no ISV support, no upgrade path, and can conflict with platform releases. Mitigation: Evaluate each for replacement or formal support contract.

4. **HIGH — No formal requirements document:** No pre-sales artifact exists. All requirements are inferred from org analysis. Design cannot proceed without a validated requirements list signed off by the customer. Mitigation: Conduct requirements workshop before Design phase.

5. **MEDIUM — Developer/test artifacts in production:** ~15–20 flows (TEST, hiotest*, WJLEE_BK, google, etc.), `ExceptionSimulator` Apex class, `zChartjsTest` LWC component, `hiotest__c` custom object, `onlyAdmin_dev` permission set, and `zTest Profile` profile are present in production. Mitigation: Decommission all test artifacts in a cleanup sprint.

6. **MEDIUM — Connected Apps not admin-restricted:** Workbench, Force.com IDE, Ant Migration Tool, and OIQ_Integration are open to all users. Mitigation: Set `OptionsAllowAdminApprovedUsersOnly = true` for developer tools; restrict OIQ_Integration to the integration user.

7. **MEDIUM — Missing test coverage for ~21% of Apex classes:** ~37 Apex classes have no identified `_ts` test class. GDC standard is 85% per class. Mitigation: Identify untested classes and add test coverage during Implementation phase.

8. **MEDIUM — Account trigger not found in org:** `Account.trigger` exists in the local repository but was not found during org retrieve. This may indicate the trigger is not deployed, or was deleted from the org without updating the repo. Mitigation: Confirm deployment status before any Account-related work.

9. **MEDIUM — MFA status unknown:** `Profile.RequiresMfa` not queryable via SOQL. For an insurance firm, MFA should be mandatory for all operational users. Mitigation: Verify via Setup > Session Settings and enforce org-wide MFA.

10. **LOW — Permission set naming/description hygiene:** `LK_Integartion` (typo), multiple permission sets without descriptions, `test2` and `Test` permission sets in production. Mitigation: Document descriptions and plan cleanup; `LK_Integartion` cannot be renamed but a new correctly-named set can be created.

---

## Open Questions

1. **Requirements:** No pre-sales document exists. What are the confirmed deliverables for this engagement? A requirements workshop is needed before Design can begin. Who are the business stakeholders?

2. **Admin profile proliferation:** Why do 37 users have System Administrator (C) access? Is this intentional for the dev/test org, or does it reflect production state? If this is the production org, this must be remediated before any deployment.

3. **Engagement scope:** Is this a dev/QA sandbox or the production org? The `LKInsuranceDev` alias, presence of test flows, and Trailhead Playground package suggest it may be a development org — which changes the risk profile significantly.

4. **MFA status:** Is MFA enforced org-wide? Cannot be confirmed via SOQL. Please verify in Setup > Session Settings > Require MFA for User Interface Logins.

5. **OrgLimit utilisation:** API limits could not be queried via standard SOQL. What is the current API call volume? Please check Setup > Company Information or the Tooling API.

6. **Unmanaged packages:** Which unmanaged packages are actively used vs. installed but dormant? Specifically, is `i2PMS` (the project management package) owned by the i2max vendor team? What is the support model?

7. **Named Credentials:** `ACC_NaverNewsFetch` and `COM_GoogleMapService` make external callouts. Are Named Credentials in use for these integrations, or are endpoints hardcoded?

8. **Account trigger deployment gap:** `Account.trigger` exists locally but was not found in the org. Is this intentional or an oversight?

9. **Agentforce agent topics/actions:** The 4 agents' topics and actions could not be retrieved via SOQL. What are the intended capabilities and current test coverage for each agent?

10. **`(X)LK_Executive` profile:** One user is on the `(X)LK_Executive` profile which appears to be a deprecated version. Should this user be migrated to `LK_Executive`?

---

## Recommended Scope Confirmation

Based on org findings, this engagement should proceed as a **Full Pipeline** delivery. The org is large (175 classes, 269 flows, 80 LWC, 45+ custom objects, 4 Agentforce agents, 74 users) and has no formal requirements document. Scope determination requires a requirements workshop as the first action.

Suggested scope confirmation items for the customer:
1. Confirm whether this is the dev org or production
2. Provide the requirements/user stories that triggered this engagement
3. Confirm priority areas (e.g., Agentforce enhancements, reconciliation fixes, policy lifecycle improvements)
4. Confirm the delivery timeline and milestone dates
