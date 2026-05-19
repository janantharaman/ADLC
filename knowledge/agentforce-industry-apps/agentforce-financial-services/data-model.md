---
source: Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata queried from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: data-model
last-updated: 2026-05-11
---

# Financial Services Cloud — Data Model

All field data is sourced directly from the LKInsuranceDev org via FieldDefinition queries (API v67.0). Fields marked with `__c` are custom fields present in this org; unmarked fields are standard FSC platform fields.

---

## FSC Standard Objects — Complete List by Domain

### Insurance Domain

| API Name | Label | Notes |
|---|---|---|
| `InsurancePolicy` | Insurance Policy | Central insurance object; parent of coverage, assets, participants, transactions, claims |
| `InsurancePolicyCoverage` | Insurance Policy Coverage | Coverage lines (sections) under a policy; child of InsurancePolicy |
| `InsurancePolicyAsset` | Insurance Policy Asset | Physical assets insured; child of InsurancePolicy |
| `InsurancePolicyParticipant` | Insurance Policy Participant | People/entities associated with a policy (insured, broker, insurer, beneficiary) |
| `InsurancePolicyTransaction` | Insurance Policy Transaction | Premium billing and financial transactions on a policy |
| `InsurancePolicyProductClause` | Insurance Policy Product Clause | Product clauses attached to a policy |
| `InsurancePolicySurcharge` | Insurance Policy Surcharge | Surcharges applied to a policy |
| `InsurancePolicyTeamMember` | Insurance Policy Team Member | Team members assigned to a policy |
| `InsuranceContract` | Insurance Contract | Insurance contract record |
| `InsuranceProfile` | Insurance Profile | Insurance profile for risk assessment |
| `InsuranceRatePlan` | Insurance Rate Plan | Rate plans for premium calculation |
| `InsuranceRatePlanLineItem` | Insurance Rate Plan Line Item | Line items within a rate plan |
| `InsuranceRatePlanCommission` | Insurance Rate Plan Commission | Commission rates within a rate plan |
| `InsuranceRatingRequest` | Insurance Rating Request | Rating requests for premium calculation |
| `InsuranceContributionPlan` | Insurance Contribution Plan | Group insurance contribution plans |
| `InsuranceAsyncBulkRequest` | Insurance Async Bulk Request | Bulk processing requests for insurance operations |
| `InsuranceAsyncBulkRequestItem` | Insurance Async Bulk Request Item | Individual items in a bulk request |
| `InsuranceAsyncBulkRecordDetail` | Insurance Async Bulk Record Detail | Record-level detail for bulk processing |

### Claims Domain

| API Name | Label | Notes |
|---|---|---|
| `Claim` | Claim | A claim filed against an InsurancePolicy |
| `ClaimItem` | Claim Item | Individual items/losses within a claim |
| `ClaimParticipant` | Claim Participant | Parties involved in a claim (claimant, adjuster, witness) |
| `ClaimCoverage` | Claim Coverage | Links a claim to specific policy coverage lines |
| `ClaimPaymentSummary` | Claim Payment Summary | Summary of payments made on a claim |
| `ClaimAttribute` | Claim Attribute | Additional attributes for claims (read-only, non-customizable) |
| `ClaimItemAttribute` | Claim Item Attribute | Additional attributes for claim items |
| `ClaimItemRelatedObject` | Claim Item Related Object | Related objects linked to claim items |
| `ClaimTeamMember` | Claim Team Member | Team members assigned to a claim |

### Financial Account Domain (Banking)

| API Name | Label | Notes |
|---|---|---|
| `FinancialAccount` | Financial Account | Bank, loan, investment, or insurance premium account |
| `FinancialAccountTransaction` | Financial Account Transaction | Transactions (debits, credits) on a financial account |
| `FinancialAccountParty` | Financial Account Party | Parties (owners, authorized users) linked to a financial account |
| `FinancialAccountBalance` | Financial Account Balance | Balance snapshots for a financial account |
| `FinancialAccountFee` | Financial Account Fee | Fees charged on a financial account |
| `FinancialAccountStatement` | Financial Account Statement | Account statements |
| `FinancialAccountMilestone` | Financial Account Milestone | Milestone events on a financial account |
| `FinancialAccountAddress` | Financial Account Address | Addresses associated with financial accounts |

### Financial Goals & Planning Domain (Wealth Management)

| API Name | Label | Notes |
|---|---|---|
| `FinancialGoal` | Financial Goal | Client investment or savings goal |
| `FinancialGoalFunding` | Financial Goal Funding | Funding sources linked to a goal |
| `FinancialGoalParty` | Financial Goal Party | Parties (clients, advisors) linked to a goal |
| `FinancialPlan` | Financial Plan | Comprehensive financial plan document |
| `FinancialSecurity` | Financial Security | A tradeable security (stock, bond, fund) |

### Relationship Domain

| API Name | Label | Notes |
|---|---|---|
| `AccountAccountRelation` | Account-Account Relation | Relationship between two Accounts (household, business partner, employer) |
| `ContactContactRelation` | Contact-Contact Relation | Relationship between two Contacts (beneficiary, advisor, referral) |

---

## Associated Objects (System-generated per FSC object)

Each FSC object has associated system objects:

| Suffix | Purpose |
|---|---|
| `Feed` | Chatter feed (e.g., `ClaimFeed`, `InsurancePolicyFeed`) |
| `History` | Field history tracking (e.g., `ClaimHistory`, `InsurancePolicyHistory`) |
| `Share` | Sharing records (e.g., `ClaimShare`, `InsurancePolicyShare`) |
| `ChangeEvent` | Change Data Capture events (e.g., `ClaimChangeEvent`) |
| `OwnerSharingRule` | Owner-based sharing rules |

---

## Full Field Reference — Core Objects

### InsurancePolicy

**Total fields in LKInsuranceDev: 189 (101 standard + 88 custom)**

#### Standard Fields

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Insurance Policy ID | ID | |
| `Name` | LK Ref. Name | Text(255) | |
| `NameInsuredId` | Insured | Master-Detail | Account |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `Status` | Status | Picklist | |
| `Substatus` | Substatus | Picklist | |
| `PolicyStage` | Policy Stage | Picklist | |
| `PolicyType` | Policy Type | Picklist | |
| `PolicyTerm` | Policy Term | Picklist | |
| `LineOfBusiness` | Line of Business | Picklist | |
| `LineOfCoverage` | Line of Coverage | Picklist | |
| `PolicyName` | Policy Name | Text(255) | |
| `PolicyCode` | Policy Code | Text(255) | |
| `PolicyDescription` | Policy Description | Long Text Area(32000) | |
| `UniversalPolicyNumber` | Universal Policy Number | Text(255) Unique | |
| `ReferencePolicyNumber` | Reference Policy Number | Text(255) | |
| `EffectiveDate` | Effective Date | Date/Time | |
| `EffectiveFromDate` | Effective From Date | Date | |
| `EffectiveToDate` | Effective To Date | Date | |
| `ExpirationDate` | Expiration Date | Date/Time | |
| `OriginalEffectiveDate` | Original Effective Date | Date/Time | |
| `OriginalEffectiveFromDate` | Original Effective From Date | Date | |
| `OriginalEffectiveToDate` | Original Effective To Date | Date | |
| `OriginalExpirationDate` | Original Expiration Date | Date/Time | |
| `RenewalDate` | Renewal Date | Date/Time | |
| `PlannedRenewalDate` | Planned Renewal Date | Date | |
| `ActualRenewalDate` | Actual Renewal Date | Date | |
| `FinalRenewalDate` | Final Renewal Date | Date/Time | |
| `PreviousRenewalDate` | Previous Renewal Date | Date/Time | |
| `DateRenewed` | Date Renewed | Date/Time | |
| `CancellationDate` | Cancellation Date | Date/Time | |
| `CancellationEffectiveDate` | Cancellation Effective Date | Date | |
| `CancellationReason` | Cancellation Reason | Long Text Area(32000) | |
| `CancellationReasonType` | Cancellation Reason Type | Picklist | |
| `SaleDate` | Sale Date | Date/Time | |
| `RatingDate` | Rating Date | Date | |
| `PaidToDate` | Paid To Date | Date | |
| `PremiumAmount` | Premium Amount | Currency(16, 0) | |
| `GrossWrittenPremium` | Gross Written Premium | Currency(16, 0) | |
| `StandardPremiumAmount` | Standard Premium | Currency(16, 0) | |
| `StandardCommissionAmount` | Standard Commission | Currency(16, 0) | |
| `StandardFeeAmount` | Standard Fee | Currency(16, 0) | |
| `StandardTaxAmount` | Standard Tax | Currency(16, 0) | |
| `TotalStandardAmount` | Total Standard Amount | Formula (Currency) | |
| `TermPremiumAmount` | Term Premium | Currency(16, 0) | |
| `TotalTermPremiumAmount` | Total Term Premium Amount | Currency(16, 0) | |
| `TermCommissionAmount` | Term Commission | Currency(16, 0) | |
| `TotalCommissionAmount` | Total Commission Amount | Currency(16, 0) | |
| `TermFeeAmount` | Term Fee | Currency(16, 0) | |
| `TotalTermFeeAmount` | Total Term Fee Amount | Currency(16, 0) | |
| `TermTaxAmount` | Term Tax | Currency(16, 0) | |
| `TotalTermTaxAmount` | Total Term Tax Amount | Currency(16, 0) | |
| `TaxesSurcharges` | Taxes and Surcharges | Currency(16, 0) | |
| `TotalSumInsured` | Sum Insured | Currency(16, 0) | |
| `CurrentDueAmount` | Current Due Amount | Currency(16, 0) | |
| `PastDueAmount` | Past Due Amount | Currency(16, 0) | |
| `PaymentDueDate` | Payment Due Date | Date/Time | |
| `PremiumFrequency` | Premium Frequency | Picklist | |
| `PremiumPaymentType` | Premium Payment Type | Picklist | |
| `PremiumCalculationMethod` | Premium Calculation Method | Picklist | |
| `PreviousPremium` | Previous Premium | Currency(16, 0) | |
| `CommissionPercent` | Commission Percent | Percent(3, 0) | |
| `CommissionFrequency` | Commission Frequency | Picklist | |
| `BillingType` | Billing Type | Picklist | |
| `AuditTerm` | Audit Term | Picklist | |
| `FundingType` | Funding Type | Picklist | |
| `PlanType` | Plan Type | Picklist | |
| `PlanTier` | Plan Tier | Picklist | |
| `ChangeType` | Change Type | Picklist | |
| `ChangeSubtype` | Change Subtype | Picklist | |
| `RenewalChannel` | Renewal Channel | Picklist | |
| `CashSurrenderValue` | Cash Surrender Value | Currency(16, 0) | |
| `Discount` | Discount | Number(18, 0) | |
| `EmployeeContribution` | Employee Contribution | Currency(16, 0) | |
| `EmployerContribution` | Employer Contribution | Currency(16, 0) | |
| `ExpectedRevenueAmount` | Expected Revenue Amount | Currency(16, 0) | |
| `HasAnyAutoCoverage` | Has Any Auto coverage | Checkbox | |
| `IsActive` | Active | Checkbox | |
| `IsPolicyEditLocked` | Policy Edit Locked | Checkbox | |
| `IsRenewedPolicy` | Renewed Policy | Checkbox | |
| `IsLoanEligibile` | Eligible for loan | Checkbox | |
| `ProducerId` | Producer | Lookup | Producer |
| `IntermediaryAccountId` | Intermediary Account | Lookup | Account |
| `BillingCarrierAccountId` | Billing Carrier Account | Lookup | Account |
| `WritingCarrierAccountId` | Insurer | Lookup | Account |
| `UnderwritingEntityId` | Underwriting Entity | Lookup | LegalEntity |
| `ContractGroupPlanId` | Contract Group Plan | Lookup | ContractGroupPlan |
| `ProductId` | Product | Lookup | Product2 |
| `SourceOpportunityId` | Source Opportunity | Lookup | Opportunity |
| `SourceQuoteId` | Source Quote | Lookup | Quote |
| `OriginalPolicyId` | Original Policy | Lookup | InsurancePolicy |
| `ParentPolicyId` | Parent Policy | Lookup | InsurancePolicy |
| `PriorPolicyId` | Prior Policy | Lookup | InsurancePolicy |
| `RenewedFromPolicyId` | Renewed From Policy | Lookup | InsurancePolicy |
| `SourcePolicyId` | Source Policy | Lookup | InsurancePolicy |
| `ServicingOffice` | Servicing Office | Address | |
| `SourceSystem` | Source System | Text(255) | |
| `SourceSystemIdentifier` | Source System Identifier | Text(255) Unique | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

#### Notable Custom Fields (LKInsuranceDev)

| API Name | Label | Data Type | Notes |
|---|---|---|---|
| `LOB1__c` | LOB1 | Picklist | Line of business classification level 1 |
| `LOB2__c` | LOB2 | Picklist | Line of business classification level 2 |
| `LOB3__c` | LOB3 | Picklist | Line of business classification level 3 |
| `BrokerageRate__c` | Brokerage Rate(%) | Number(16, 2) | Brokerage commission rate |
| `BrokerageAmt__c` | Brokerage Amt. | Number(16, 2) | Brokerage amount |
| `Currency__c` | Currency | Picklist | Policy currency |
| `ExchangeRate__c` | Exchange Rate | Number(16, 2) | FX rate applied to policy |
| `PostingDate__c` | Posting Date | Date | Accounting posting date |
| `InceptionDate__c` | Inception Date | Date/Time | Policy inception date |
| `RefPlacement_lk__c` | Ref. Placement | Lookup | Placement__c — links policy to placement record |
| `PolicyHodler_lk__c` | Policy Holder | Lookup | Account — explicit policyholder link |
| `EGIMasterPolicy_lk__c` | Master Policy(EGI) | Lookup | InsurancePolicy — for group/master policy hierarchy |
| `Participant_Count__c` | Participant Count | Roll-Up Summary | COUNT of InsurancePolicyParticipant |
| `Count_Of_Coverage_ChildItems__c` | Count Of Coverage ChildItems | Roll-Up Summary | COUNT of InsurancePolicyCoverage |

---

### Claim

**Total fields in LKInsuranceDev: 142 (standard + custom)**

#### Standard Fields

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Claim ID | ID | |
| `Name` | Claim Number | Text(255) | |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `Status` | Status | Picklist | |
| `Severity` | Severity | Picklist | |
| `LossType` | Loss Type | Picklist | |
| `ClaimType` | Claim Type | Picklist | |
| `ClaimReasonType` | Claim Reason Type | Picklist | |
| `ClaimReason` | Claim Reason | Text(255) | |
| `LossDate` | Loss Date | Date/Time | |
| `ClaimLossDate` | Claim Loss Date | Date | |
| `ReportDate` | Report Date | Date/Time | |
| `InitiationDate` | Initiation Date | Date/Time | |
| `FinalizedDate` | Finalized Date | Date/Time | |
| `AssessmentDate` | Assessment Date | Date/Time | |
| `VisitDate` | Visit Date | Date/Time | |
| `ActualAmount` | Actual Amount | Currency(16, 0) | |
| `EstimatedAmount` | Estimated Amount | Currency(16, 0) | |
| `ApprovedAmount` | Approved Amount | Currency(16, 0) | |
| `Summary` | Summary | Long Text Area(32000) | |
| `RepairShop` | Repair Shop | Text(100) | |
| `RepairShopLocation` | Repair Shop Location | Long Text Area(32000) | |
| `VisitSite` | Visit Site | Long Text Area(32000) | |
| `IncidentSite` | Incident Site | Address | |
| `UsageType` | Usage Type | Picklist | |
| `FnolChannel` | FNOL Channel | Picklist | |
| `RenewalChannel` | Renewal Channel | Picklist | |
| `RecordSource` | Record Source | Picklist | |
| `FinancialAuthorityStatus` | Financial Authority Status | Picklist | |
| `IsAuthoritiesNotified` | Authorities Notified | Checkbox | |
| `IsClosed` | Closed | Checkbox | |
| `IsDrivable` | Drivable | Checkbox | |
| `IsInhabitable` | Inhabitable | Checkbox | |
| `ReportingAuthority` | Reporting Authority | Text(100) | |
| `ReportNumber` | Report Number | Text(100) | |
| `AccountId` | Account | Lookup | Account |
| `PolicyNumberId` | Policy Number | Lookup | InsurancePolicy |
| `InsuredAssetId` | Insured Asset | Lookup | InsurancePolicyAsset |
| `CaseId` | Case | Lookup | Case |
| `IncidentId` | Incident | Lookup | Incident |
| `ProductId` | Product | Lookup | Product2 |
| `SourceId` | Claim Source | Lookup | PersonLifeEvent, BusinessMilestone, WorkOrder |
| `SourceSystem` | Source System | Text(255) | |
| `SourceSystemIdentifier` | Source System Identifier | Text(255) Unique | |
| `RecordTypeId` | Record Type | Record Type | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

#### Notable Custom Fields (LKInsuranceDev)

| API Name | Label | Data Type | Notes |
|---|---|---|---|
| `InsurancePolicy_lk__c` | Insurance Policy | Lookup(InsurancePolicy) | Explicit policy lookup (supplements PolicyNumberId) |
| `Placement_lk__c` | LK Ref. Name | Lookup(Placement__c) | Links claim to placement record |
| `ParentClaim_lk__c` | Parent Claim | Lookup(Claim) | Parent-child claim hierarchy |
| `LossAmt__c` | Loss Amount (100%) | Number(16, 2) | Full loss amount at 100% |
| `LossAmtLK_fm__c` | Loss Amount (for LK Share) | Formula(Number) | LK share of loss amount |
| `TotalAmt__c` | Total Amount (100%) | Number(16, 2) | Total claim amount |
| `LKShare__c` | LK Share(%) | Percent(10, 2) | LK's participation share |
| `ClaimCurrency__c` | Claim Currency | Picklist | Currency for claim amounts |
| `SettlementCurrency__c` | Settlement Currency | Picklist | Currency for settlement |
| `LOB1__c` | LOB1 | Picklist | Line of business |
| `Stage__c` | Stage | Picklist | Claim workflow stage |
| `CedantName_lk__c` | Cedant Name | Lookup(Account) | Reinsurance cedant reference |
| `CDIssueDate__c` | C/D Note Issue Date | Date | Credit/Debit note issue date |
| `LocationCount_rs__c` | Location Count | Roll-Up Summary | COUNT of location of loss records |

---

### InsurancePolicyCoverage

**Total fields in LKInsuranceDev: 81 (standard + custom)**

#### Standard Fields

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Insurance Policy Coverage ID | ID | |
| `Name` | Name | Auto Number | |
| `InsurancePolicyId` | Insurance Policy | Master-Detail | InsurancePolicy |
| `InsurancePolicyAssetId` | Insurance Policy Asset | Lookup | InsurancePolicyAsset |
| `InsurancePolicyParticipantId` | Insurance Policy Participant | Lookup | InsurancePolicyParticipant |
| `ContractGroupPlanId` | Contract Group Plan | Lookup | ContractGroupPlan |
| `ProductId` | Product | Lookup | Product2 |
| `ProductSellingModelId` | Product Selling Model | Lookup | ProductSellingModel |
| `ParentCoverageId` | Parent Coverage | Lookup | InsurancePolicyCoverage |
| `OriginalCoverageId` | Original Coverage | Lookup | InsurancePolicyCoverage |
| `PriorCoverageId` | Prior Coverage | Lookup | InsurancePolicyCoverage |
| `SourceCoverageId` | Source Coverage | Lookup | InsurancePolicyCoverage |
| `Category` | Category | Picklist | |
| `CategoryCode` | Category Code | Text(255) | |
| `CategoryGroup` | Category Group | Picklist | |
| `CategoryGroupType` | Category Group Type | Picklist | |
| `CoverageCode` | Coverage Code | Text(255) | |
| `CoverageName` | Location Name | Text(255) | |
| `Description` | Description | Long Text Area(32000) | |
| `EffectiveDate` | Effective Date | Date/Time | |
| `EffectiveFromDate` | Effective From Date | Date | |
| `EffectiveToDate` | Effective To Date | Date | |
| `ExpirationDate` | Expiration Date | Date/Time | |
| `LimitAmount` | Limit Amount | Currency(16, 0) | |
| `LimitDate` | Limit Date | Date | |
| `LimitPercentage` | Limit Percentage | Percent(3, 0) | |
| `LimitRange` | Limit Range | Picklist | |
| `DeductibleAmount` | Deductible Amount | Currency(16, 0) | |
| `PremiumAmount` | Premium Amount | Currency(16, 0) | |
| `StandardPremiumAmount` | Standard Premium | Currency(16, 0) | |
| `StandardCommissionAmount` | Standard Commission | Currency(16, 0) | |
| `StandardFeeAmount` | Standard Fee | Currency(16, 0) | |
| `StandardTaxAmount` | Standard Tax | Currency(16, 0) | |
| `TotalStandardAmount` | Total Standard Amount | Formula (Currency) | |
| `TermPremiumAmount` | Term Premium | Currency(16, 0) | |
| `TermCommissionAmount` | Term Commission | Currency(16, 0) | |
| `TermFeeAmount` | Term Fee | Currency(16, 0) | |
| `TermTaxAmount` | Term Tax | Currency(16, 0) | |
| `TotalTermAmount` | Total Term Amount | Formula (Currency) | |
| `CommissionPercent` | Commission Percent | Percent(3, 0) | |
| `ExpectedRevenueAmount` | Expected Revenue Amount | Currency(16, 0) | |
| `Discount` | Discount | Currency(16, 0) | |
| `EmployeeContribution` | Employee Contribution | Currency(16, 0) | |
| `EmployerContribution` | Employer Contribution | Currency(16, 0) | |
| `DeathBenefitOptionType` | Death Benefit Option Type | Picklist | |
| `IncomeOptionType` | Income Option Type | Picklist | |
| `BenefitPaymentFrequency` | Benefit Payment Frequency | Picklist | |
| `SourceSystem` | Source System | Text(255) | |
| `SourceSystemIdentifier` | Source System Identifier | Text(255) Unique | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### InsurancePolicyParticipant

**Total fields in LKInsuranceDev: 75 (standard + custom)**

#### Standard Fields

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Insurance Policy Participant ID | ID | |
| `Name` | Name | Auto Number | |
| `InsurancePolicyId` | Insurance Policy | Master-Detail | InsurancePolicy |
| `PrimaryParticipantAccountId` | Primary Participant Account | Lookup | Account |
| `PrimaryParticipantContactId` | Primary Participant Contact | Lookup | Contact |
| `RelatedParticipantAccountId` | Related Participant Account | Lookup | Account |
| `RelatedParticipantContactId` | Related Participant Contact | Lookup | Contact |
| `LegalGuardianId` | Legal Guardian | Lookup | Account |
| `ProductId` | Product | Lookup | Product2 |
| `ProductSellingModelId` | Product Selling Model | Lookup | ProductSellingModel |
| `OriginalParticipantId` | Original Participant | Lookup | InsurancePolicyParticipant |
| `PriorParticipantId` | Prior Participant | Lookup | InsurancePolicyParticipant |
| `SourceParticipantId` | Source Participant | Lookup | InsurancePolicyParticipant |
| `RelatedInsPolicyParticipantId` | Related Insurance Policy Participant | Lookup | InsurancePolicyParticipant |
| `Role` | Role | Picklist (Multi-Select) | |
| `RelationshipToInsured` | Relationship to Insured | Picklist | |
| `ParticipantCode` | Participant Code | Text(255) | |
| `ParticipantName` | Participant Name | Text(255) | |
| `BeneficiarySharePercentage` | Beneficiary Share Percentage | Percent(3, 0) | |
| `IsActiveParticipant` | Active Participant | Checkbox | |
| `IsMinorBeneficiary` | Minor Beneficiary | Checkbox | |
| `IsPolicyholder` | Policy holder | Checkbox | |
| `EffectiveDate` | Effective Date | Date/Time | |
| `EffectiveFromDate` | Effective From Date | Date | |
| `EffectiveToDate` | Effective To Date | Date | |
| `ExpirationDate` | Expiration Date | Date/Time | |
| `EmployeeContribution` | Employee Contribution | Currency(16, 0) | |
| `EmployerContribution` | Employer Contribution | Currency(16, 0) | |
| `StandardPremiumAmount` | Standard Premium | Currency(16, 0) | |
| `StandardCommissionAmount` | Standard Commission | Currency(16, 0) | |
| `StandardFeeAmount` | Standard Fee | Currency(16, 0) | |
| `StandardTaxAmount` | Standard Tax | Currency(16, 0) | |
| `TotalStandardAmount` | Total Standard Amount | Formula (Currency) | |
| `TermPremiumAmount` | Term Premium | Currency(16, 0) | |
| `TermCommissionAmount` | Term Commission | Currency(16, 0) | |
| `TermFeeAmount` | Term Fee | Currency(16, 0) | |
| `TermTaxAmount` | Term Tax | Currency(16, 0) | |
| `TotalTermAmount` | Total Term Amount | Formula (Currency) | |
| `SourceSystem` | Source System | Text(255) | |
| `SourceSystemIdentifier` | Source System ID | Text(255) Unique | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

#### Notable Custom Fields (LKInsuranceDev)

| API Name | Label | Data Type | Notes |
|---|---|---|---|
| `Insurer__c` | Insurer | Lookup(Account) | The insurer (lead or participating) |
| `InsurerPolicyNo__c` | Insurer Policy No. | Text(255) | Insurer's own policy reference number |
| `BrokerageAmt__c` | Brokerage Amt. | Number(16, 2) | Brokerage amount for this participant |
| `BrokerageRate__c` | Brokerage Rate(%) | Percent(16, 2) | Brokerage rate for this participant |
| `SignedLine__c` | Signed Line(%) | Number(16, 2) | Insurer's signed line (participation %) |
| `LeadInsurer__c` | Lead Insurer | Checkbox | Whether this participant is the lead insurer |
| `CoBrokingType__c` | Co-Broking Type | Picklist | Co-broking arrangement type |
| `isCoBroker__c` | is Co-Broker | Checkbox | Whether this participant is a co-broker |

---

### InsurancePolicyAsset

**Total fields in LKInsuranceDev: 49 (standard + custom)**

#### Standard Fields

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Insurance Policy Asset ID | ID | |
| `Name` | Name | Auto Number | |
| `InsurancePolicyId` | Insurance Policy | Master-Detail | InsurancePolicy |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `PrimaryPolicyParticipantId` | Primary Policy Participant | Lookup | InsurancePolicyParticipant |
| `CustomerPropertyId` | Customer Property | Lookup | CustomerProperty |
| `ProductId` | Product | Lookup | Product2 |
| `ProductSellingModelId` | Product Selling Model | Lookup | ProductSellingModel |
| `OriginalAssetId` | Original Asset | Lookup | InsurancePolicyAsset |
| `PriorAssetId` | Prior Asset | Lookup | InsurancePolicyAsset |
| `RelatedInsurancePolicyAssetId` | Related Insurance Policy Asset | Lookup | InsurancePolicyAsset |
| `SourceAssetId` | Source Asset | Lookup | InsurancePolicyAsset |
| `AssetCode` | Asset Code | Text(255) | |
| `AssetName` | Asset Name | Text(255) | |
| `EffectiveFromDate` | Effective From Date | Date | |
| `EffectiveToDate` | Effective To Date | Date | |
| `IsActive` | Active | Checkbox | |
| `StandardPremiumAmount` | Standard Premium | Currency(16, 0) | |
| `StandardCommissionAmount` | Standard Commission | Currency(16, 0) | |
| `StandardFeeAmount` | Standard Fee | Currency(16, 0) | |
| `StandardTaxAmount` | Standard Tax | Currency(16, 0) | |
| `TotalStandardAmount` | Total Standard Amount | Formula (Currency) | |
| `TermPremiumAmount` | Term Premium | Currency(16, 0) | |
| `TermCommissionAmount` | Term Commission | Currency(16, 0) | |
| `TermFeeAmount` | Term Fee | Currency(16, 0) | |
| `TermTaxAmount` | Term Tax | Currency(16, 0) | |
| `TotalTermAmount` | Total Term Amount | Formula (Currency) | |
| `Asset_Address__c` | Asset Address | Address (compound) | |
| `Asset_Location__c` | Asset Location | Geolocation (compound) | |
| `SourceSystem` | Source System | Text(255) | |
| `SourceSystemIdentifier` | Source System Identifier | Text(255) Unique | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### InsurancePolicyTransaction

**Total fields: 30**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Insurance Policy Transaction ID | ID | |
| `Name` | Name | Text(255) | |
| `InsurancePolicyId` | Insurance Policy | Master-Detail | InsurancePolicy |
| `InsurancePolicyVersionId` | Insurance Policy Version | Lookup | InsurancePolicy |
| `ParentTransactionId` | Parent Transaction | Lookup | InsurancePolicyTransaction |
| `PriorTransactionId` | Prior Transaction | Lookup | InsurancePolicyTransaction |
| `Type` | Type | Picklist | |
| `Category` | Category | Picklist | |
| `Status` | Status | Picklist | |
| `BillingStatus` | Billing Status | Picklist | |
| `TransactionNumber` | Transaction Number | Text(255) | |
| `TransactionAmount` | Transaction Amount | Currency(16, 0) | |
| `CommissionAmount` | Commission Amount | Currency(16, 0) | |
| `TransactionFeeAmount` | Transaction Fee | Currency(16, 0) | |
| `TransactionTaxAmount` | Transaction Tax | Currency(16, 0) | |
| `TotalTransactionAmount` | Total Transaction Amount | Formula (Currency) | |
| `EffectiveFromDate` | Effective From Date | Date | |
| `TransactionEffectiveDate` | Transaction Effective Date | Date/Time | |
| `TransactionPostedDate` | Transaction Posted Date | Date/Time | |
| `PostedDate` | Posted Date | Date | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### ClaimItem

**Total fields: 21**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Claim Item ID | ID | |
| `Name` | Name | Text(255) | |
| `ClaimId` | Claim | Master-Detail | Claim |
| `ClaimParticipantId` | Claim Participant | Lookup | ClaimParticipant |
| `InsurancePolicyCoverageId` | Insurance Policy Coverage | Lookup | InsurancePolicyCoverage |
| `InsurancePolicyAssetId` | Insurance Policy Asset | Lookup | InsurancePolicyAsset |
| `ProductId` | Product | Lookup | Product2 |
| `Category` | Category | Picklist | |
| `ClaimInstanceIdentifier` | Claim Instance Identifier | Text(255) | |
| `Description` | Description | Long Text Area(32000) | |
| `CurrentAddress` | Current Address | Address (compound) | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### ClaimParticipant

**Total fields: 21**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Claim Participant ID | ID | |
| `Name` | Name | Auto Number | |
| `ClaimId` | Claim | Master-Detail | Claim |
| `InsurancePolicyParticipantId` | Insurance Policy Participant | Lookup | InsurancePolicyParticipant |
| `ParticipantAccountId` | Participant Account | Lookup | Account |
| `ParticipantContactId` | Participant Contact | Lookup | Contact |
| `Roles` | Roles | Picklist (Multi-Select) | |
| `IsInjured` | Injured | Checkbox | |
| `ClaimInstanceIdentifier` | Claim Instance Identifier | Text(255) | |
| `SourceSystem` | Source System | Text(255) | |
| `SourceSystemIdentifier` | Source System Identifier | Text(255) Unique | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### ClaimCoverage

**Total fields: 24**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Claim Coverage ID | ID | |
| `Name` | Name | Text(255) | |
| `ClaimId` | Claim | Master-Detail | Claim |
| `ClaimItemId` | Claim Item | Lookup | ClaimItem |
| `ClaimParticipantId` | Claim Participant | Lookup | ClaimParticipant |
| `InsurancePolicyCoverageId` | Insurance Policy Coverage | Lookup | InsurancePolicyCoverage |
| `InsurancePolicyAssetId` | Insurance Policy Asset | Lookup | InsurancePolicyAsset |
| `InsurancePolicyParticipantId` | Insurance Policy Participant | Lookup | InsurancePolicyParticipant |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `Status` | Status | Picklist | |
| `InternalReserveMode` | Internal Reserve Mode | Picklist | |
| `LossReserveAmount` | Loss Reserve Amount | Currency(16, 0) | |
| `ExpenseReserveAmount` | Expense Reserve Amount | Currency(16, 0) | |
| `Description` | Description | Long Text Area(32000) | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### FinancialAccount

**Total fields in LKInsuranceDev: 43**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Financial Account ID | ID | |
| `Name` | Name | Text(255) | |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `Status` | Status | Picklist | |
| `Type` | Type | Picklist | |
| `InterestType` | Interest Type | Picklist | |
| `FinancialAccountNumber` | Financial Account Number | Text(255) | |
| `OpeningDate` | Opening Date | Date | |
| `ClosingDate` | Closing Date | Date | |
| `MaturityDate` | Maturity Date | Date | |
| `RenewalDate` | Renewal Date | Date | |
| `PaymentDueDate` | Payment Due Date | Date | |
| `AmountDue` | Amount Due | Currency(16, 0) | |
| `CreditLimit` | Credit Limit | Currency(16, 0) | |
| `DownPaymentAmount` | Down Payment Amount | Currency(16, 0) | |
| `PrincipalAmount` | Principal Amount | Currency(16, 0) | |
| `PrincipalPaidYearToDate` | Principal Paid Year To Date | Currency(16, 0) | |
| `TotalOutstandingAmount` | Total Outstanding Amount | Currency(16, 0) | |
| `InterestRate` | Interest Rate | Number(16, 2) | |
| `InterestPaidYearToDate` | Interest Paid Year To Date | Currency(16, 0) | |
| `InsurancePaidYearToDate` | Insurance Paid Year To Date | Currency(16, 0) | |
| `PropertyTaxPaidYearToDate` | Property Tax Paid Year To Date | Currency(16, 0) | |
| `Term` | Term | Number(9, 0) | |
| `IsHeldAway` | Held Away | Checkbox | |
| `IsManaged` | Managed | Checkbox | |
| `IsOverdraftAllowed` | Overdraft Allowed | Checkbox | |
| `HeldAwayBankName` | Held Away Bank Name | Text(255) | |
| `HeldAwayBankRoutingCode` | Held Away Bank Routing Code | Text(255) | |
| `BankerId` | Banker | Lookup | Banker |
| `BranchUnitId` | Branch Unit | Lookup | BranchUnit |
| `ProductId` | Product | Lookup | Product2 |
| `RelatedFinancialAccountId` | Related Financial Account | Lookup | FinancialAccount |
| `SourceSystemIdentifier` | Source System Identifier | External Lookup | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### FinancialAccountTransaction

**Total fields: 25**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Financial Account Transaction ID | ID | |
| `Name` | Name | Auto Number | |
| `FinancialAccountId` | Financial Account | Master-Detail | FinancialAccount |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `Type` | Type | Picklist | |
| `SubType` | Sub Type | Picklist | |
| `Status` | Status | Picklist | |
| `DebitCreditIndicator` | Debit Credit Indicator | Picklist | |
| `Amount` | Amount | Currency(16, 0) | |
| `Description` | Description | Text(255) | |
| `TransactionDate` | Transaction Date | Date/Time | |
| `PostedDate` | Posted Date | Date/Time | |
| `TransactionCode` | Transaction Code | Text(255) | |
| `TransactionIdentifier` | Transaction Identifier | Text(80) | |
| `SourceSystemIdentifier` | Source System Identifier | External Lookup | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

### FinancialGoal

**Total fields: 28**

| API Name | Label | Data Type | References |
|---|---|---|---|
| `Id` | Financial Goal ID | ID | |
| `Name` | Name | Text(255) | |
| `OwnerId` | Owner Name | Lookup | User, Group |
| `FinancialPlanId` | Financial Plan | Lookup | FinancialPlan |
| `Type` | Type | Picklist | |
| `Category` | Category | Picklist | |
| `Status` | Status | Picklist | |
| `Priority` | Priority | Picklist | |
| `Description` | Description | Text(255) | |
| `TargetAmount` | Target Amount | Currency(18, 0) | |
| `InitialAmount` | Initial Amount | Currency(18, 0) | |
| `ActualAmount` | Actual Amount | Currency(18, 0) | |
| `EstimatedSuccessPercent` | Estimated Success Percent | Percent(3, 0) | |
| `Frequency` | Withdrawal Frequency | Picklist | |
| `StartDate` | Start Date | Date | |
| `TargetDate` | Target Date | Date | |
| `CompletionDate` | Completion Date | Date | |
| `SourceSystemIdentifier` | Source System Identifier | Text(255) | |
| `RecordVisibilityId` | Record Visibility | Lookup | |
| `CreatedById` | Created By | Lookup | User |
| `CreatedDate` | Created Date | Date/Time | |
| `LastModifiedById` | Last Modified By | Lookup | User |
| `LastModifiedDate` | Last Modified Date | Date/Time | |
| `IsDeleted` | Deleted | Checkbox | |
| `SystemModstamp` | System Modstamp | Date/Time | |

---

## Object Relationship Diagrams

### Insurance Domain

```
Account (NameInsured)
    │
    └──[Master-Detail]──► InsurancePolicy
                               │
                               ├──[Master-Detail]──► InsurancePolicyCoverage
                               │         │
                               │         ├── ParentCoverageId → InsurancePolicyCoverage (hierarchy)
                               │         └── InsurancePolicyAssetId → InsurancePolicyAsset
                               │
                               ├──[Master-Detail]──► InsurancePolicyAsset
                               │         └── PrimaryPolicyParticipantId → InsurancePolicyParticipant
                               │
                               ├──[Master-Detail]──► InsurancePolicyParticipant
                               │         ├── PrimaryParticipantAccountId → Account
                               │         └── PrimaryParticipantContactId → Contact
                               │
                               ├──[Master-Detail]──► InsurancePolicyTransaction
                               │
                               └──[Lookup]──► Claim (PolicyNumberId)
                                               │
                                               ├──[Master-Detail]──► ClaimItem
                                               │         └── InsurancePolicyCoverageId → InsurancePolicyCoverage
                                               │
                                               ├──[Master-Detail]──► ClaimParticipant
                                               │         └── InsurancePolicyParticipantId → InsurancePolicyParticipant
                                               │
                                               └──[Master-Detail]──► ClaimCoverage
                                                         ├── InsurancePolicyCoverageId → InsurancePolicyCoverage
                                                         ├── ClaimItemId → ClaimItem
                                                         └── ClaimParticipantId → ClaimParticipant
```

### Financial Account Domain

```
Account (Client)
    │
    └──[Lookup via FinancialAccountParty]──► FinancialAccount
                                                 │
                                                 ├──[Master-Detail]──► FinancialAccountTransaction
                                                 ├──[Master-Detail]──► FinancialAccountBalance
                                                 ├──[Master-Detail]──► FinancialAccountFee
                                                 ├──[Master-Detail]──► FinancialAccountStatement
                                                 ├──[Master-Detail]──► FinancialAccountMilestone
                                                 └──[Master-Detail]──► FinancialAccountParty
```

### Financial Goals Domain

```
Account (Client)
    │
    └──► FinancialPlan
               │
               └──► FinancialGoal
                         │
                         ├──► FinancialGoalFunding (funding sources)
                         └──► FinancialGoalParty (linked parties/advisors)
```

### Relationship Domain

```
Account ──[AccountAccountRelation]──► Account
 (Household members, business relationships, employer-employee)

Contact ──[ContactContactRelation]──► Contact
 (Beneficiary, advisor, referral, family)
```

---

## Common Custom Object Patterns in FSC Implementations

| Pattern | Custom Object | Domain | Purpose |
|---|---|---|---|
| Placement / brokerage deal | `Placement__c` | Insurance broking | Represents a placement deal; InsurancePolicy records link back to it |
| Coverage layer | `CoverageLayer__c` | Commercial insurance | Layers within a placement |
| Premium reconciliation | `Reconciliation__c` | Finance/accounting | Period reconciliation record |
| Settlement record | `Settlement__c` | Finance/accounting | Payment settlement against a claim or invoice |
| Bank transaction | `BankTransaction__c` | Reconciliation | Bank statement line items |
| Chart of accounts | `COA__c` | Internal accounting | Accounting code mapping |
| Referral tracking | `Referral__c` | Banking/advisory | Referral pipeline tracking (pre-Spring '26 orgs only — now replaced by standard `Referral` object in API v66+) |
| Facility (reinsurance) | `COM_Facility__c` | Reinsurance | Reinsurance facility; InsurancePolicy links via `Facility__c` |

---

## BranchUnit Object Family

Available since API v51.0. Used in Banking module. Source: fsc_dev_guide.pdf pp.115–124.

### BranchUnit

Represents a physical or virtual branch of a financial institution.

**Supported Calls:** create, delete, describeLayout, describeSObjects, getDeleted, getUpdated, query, retrieve, search, undelete, update, upsert

| Field | Type | Description |
|---|---|---|
| `Id` | ID | Branch Unit ID |
| `Name` | string | Branch name |
| `AccountId` | Lookup(Account) | Account with additional branch information; must be unique within the org |
| `BranchCode` | string | External system identifier for the branch |
| `BranchManagerId` | Lookup(User) | Manager or main point of contact for the branch |
| `IsActive` | boolean | Whether the branch is active (default: false); inactive branches excluded from banker assignments and automatic associations |
| `StartDate` | date | Date the branch most recently became active |
| `EndDate` | date | Date the branch most recently stopped being active |
| `LocationId` | Lookup(Location) | Physical location where branch operates |
| `OperatingHoursId` | Lookup(OperatingHours) | Operating hours record for normal business |
| `OperationalState` | picklist | Operational readiness of the branch |
| `ParentBranchUnitId` | Lookup(BranchUnit) | Parent branch unit (for branch hierarchies) |
| `ServiceTerritoryId` | Lookup(ServiceTerritory) | Service territory corresponding to this branch |
| `Type` | picklist | Branch interaction type: `Physical`, `PhysicalAndVirtual`, `Virtual` |
| `OwnerId` | Lookup(User, Group) | Record owner |

**Associated objects:** BranchUnitChangeEvent, BranchUnitFeed, BranchUnitHistory, BranchUnitOwnerSharingRule, BranchUnitShare

### BranchUnitBusinessMember

Represents a user or contact with a specific role at a branch. Available API v51.0+.

| Field | Type | Description |
|---|---|---|
| `BranchUnitId` | Lookup(BranchUnit) | Branch unit for this assignment |
| `BusinessUnitMemberId` | Lookup(User, Contact) | User or contact with the predefined role |
| `StartDate` | date | Date this person was assigned this role |
| `EndDate` | date | Date this person stopped fulfilling this role |
| `IsActive` | boolean | Whether this role assignment can be used (default: false) |
| `ServiceTerritoryMemberId` | Lookup(ServiceTerritoryMember) | Links to service territory member for appointment scheduling |
| `Name` | Auto Number | Auto-generated name |

### BranchUnitCustomer

Links a customer Account to a BranchUnit. Available API v51.0+.

| Field | Type | Description |
|---|---|---|
| `BranchUnitId` | Lookup(BranchUnit) | The branch handling this customer |
| `AccountId` | Lookup(Account) | Customer account associated with the branch |
| `AssociationLevel` | picklist | Branch's responsibility level: `Primary` (default), `Secondary` |
| `LastInteractionDate` | date | Date when the customer account was associated with the branch |
| `Name` | Auto Number | Auto-generated name |

### BranchUnitRelatedRecord

Links a related record (case, account, opportunity) to a BranchUnit. Available API v51.0+. Used by Record Association Builder rules (RelatedRecordAssocCriteria metadata).

| Field | Type | Description |
|---|---|---|
| `BranchUnitId` | Lookup(BranchUnit) | Branch unit associated with the related record |
| `AccountId` | Lookup(Account) | Customer account associated with the related record |
| `BusinessUnitMemberId` | Lookup | Business unit member active at the branch when the association was made |
| `RelatedRecordId` | Lookup (polymorphic) | ID of the related record (Account, Case, Lead, Opportunity, Contact, InteractionSummary) |
| `RelatedObjectName` | picklist | Object type: Account, Case, Lead, Opportunity, Contact, InteractionSummary |
| `RelatedRecordAssocCriteriaId` | Lookup | The RelatedRecordAssocCriteria that triggered creation of this record |
| `Reason` | picklist | Reason for associating the record with the branch |
| `Comment` | string | Comments about the relationship |
| `Name` | Auto Number | Auto-generated name |

**Relationship:** `FinancialAccount.BranchUnitId` links a financial account directly to a branch.

---

## FinancialDeal Object Family

Available since API v52.0 (FinancialDeal, FinancialDealParty, FinancialDealParticipant) through API v54.0 (FinancialDealAsset, FinancialDealBid). Requires `enableDealManagement = true` in IndustriesSettings. Used for Commercial Banking investment banking deal pipeline. Source: fsc_dev_guide.pdf pp.323–340.

### FinancialDeal

Represents a deal that a financial institution is working on.

**Supported Calls:** create, delete, describeLayout, describeSObjects, getDeleted, getUpdated, query, retrieve, search, undelete, update, upsert

| Field | Type | Description |
|---|---|---|
| `Id` | ID | Financial Deal ID |
| `Name` | string | Name of the deal |
| `AccountId` | Lookup(Account) | Customer who engaged the institution in the deal |
| `FinancialDealCode` | string | Unique code identifying the deal |
| `FinancialDealType` | picklist | Type: `Advisory`, `Capital Raising`, `Debt Capital Market`, `Initial Public Offering`, `Mergers and Acquisitions`, `Secondary Offering` |
| `Stage` | picklist | Deal stage: `Pitch`, `Mandate`, `Execution`, `Closed` |
| `Status` | picklist | `Open`, `On Hold`, `Closed` |
| `Role` | picklist | Institution's role: `Advisor`, `Bookrunner`, `Syndication Agent` |
| `ConfidentialityType` | picklist | `Confidential`, `Public` |
| `ConflictStatus` | picklist | Conflict clearance: `Approved`, `Declined` |
| `ExpectedCloseDate` | date | Expected deal close date |
| `MandatedDate` | date | Date the deal was mandated |
| `CloseProbability` | percent | Probability of successful close |
| `TransactionValue` | currency | Total transaction value |
| `TotalExpectedFee` | currency | Total expected fee for the institution |
| `ReceivedFee` | currency | Total fee received to date |
| `TotalExpense` | currency | Total expense incurred to date |
| `Description` | textarea | Deal description |
| `ParentFinancialDealId` | Lookup(FinancialDeal) | Parent deal (for deal hierarchies) |
| `OwnerId` | Lookup(User, Group) | Record owner |

**Associated objects:** FinancialDealChangeEvent, FinancialDealFeed, FinancialDealHistory, FinancialDealOwnerSharingRule, FinancialDealShare

### FinancialDealAsset

Represents assets included in a financial deal. Available API v54.0+.

| Field | Type | Description |
|---|---|---|
| `FinancialDealId` | Lookup(FinancialDeal) | The deal this asset belongs to |
| `AssetId` | Lookup(Asset) | The Salesforce Asset record involved in the deal |
| `AssetType` | picklist | `Office Space`, `Residential Space` |
| `Address` | Address (compound) | Location of the asset |
| `UnitCount` | double | Total number of units |
| `UnitOfMeasureId` | Lookup(UnitOfMeasure) | Unit of measure for the asset |
| `Name` | string | Name of the deal asset record |

### FinancialDealBid

Represents bids placed by parties in a financial deal. Available API v54.0+.

| Field | Type | Description |
|---|---|---|
| `FinancialDealId` | Lookup(FinancialDeal) | The deal this bid is for |
| `FinancialDealPartyId` | Lookup(FinancialDealParty) | The party making the bid |
| `BidAmount` | currency | Amount the party is willing to pay |
| `BidDate` | date | Date the bid was placed |
| `BidRound` | string | Bidding round identifier |
| `Name` | Auto Number | Auto-generated name |

### FinancialDealInteraction

Junction between an Interaction and a FinancialDeal. Available API v53.0+.

| Field | Type | Description |
|---|---|---|
| `FinancialDealId` | Lookup(FinancialDeal) | The deal associated with the interaction |
| `InteractionId` | Lookup(Interaction) | The interaction associated with this record |
| `Comment` | textarea | Notes about the deal associated with the interaction |
| `Name` | Auto Number | Auto-generated name |

### FinancialDealParty

Represents parties (partners, competitors) involved in a deal. Available API v52.0+.

| Field | Type | Description |
|---|---|---|
| `FinancialDealId` | Lookup(FinancialDeal) | The deal this party is involved in |
| `PartyId` | Lookup(Account) | Account ID of the party |
| `ContactId` | Lookup(Contact) | Contact ID of the party |
| `PartyType` | picklist | `Company`, `Individual` |
| `PartyRole` | picklist | `Competitor`, `Partner`, `Syndicate` |
| `Stage` | picklist | Party stage: `Teaser Sent`, `Non-Disclosure Agreement Signed`, `Indication of Interest Sent`, `Confidential Information Memorandum Sent`, `Letter of Intent Sent`, `Declined` |
| `LastStageChangeDate` | dateTime | Date of last Stage field change (API v54+) |
| `Name` | Auto Number | Auto-generated name |
| `OwnerId` | Lookup(User, Group) | Record owner |

### FinancialDealParticipant

Represents the internal user or group with whom the deal is shared. Available API v52.0+.

| Field | Type | Description |
|---|---|---|
| `FinancialDealId` | Lookup(FinancialDeal) | The deal being shared |
| `Comments` | string | Notes about the deal participant |

### FinancialDeal Object Diagram

```
FinancialDeal
    ├──► FinancialDealParty (external parties: competitors, partners, syndicates)
    ├──► FinancialDealParticipant (internal users/groups sharing the deal)
    ├──► FinancialDealBid (bids submitted by FinancialDealParties)
    ├──► FinancialDealAsset (physical assets included in the deal)
    └──► FinancialDealInteraction (junction to Interaction records)
```

---

## Referral Object

Standard FSC object for referral management. Available since API v66.0. Replaces the custom `Referral__c` pattern used in pre-Spring '26 implementations. Source: fsc_dev_guide.pdf pp.836–847.

**Supported Calls:** create, delete, describeLayout, describeSObjects, getDeleted, getUpdated, query, retrieve, search, undelete, update, upsert

| Field | Type | Description |
|---|---|---|
| `Id` | ID | Referral ID |
| `Name` | Auto Number | Auto-generated referral name |
| `ReferralDate` | date | Date the referral was received |
| `ReferralType` | picklist | `INBOUND` (Inbound), `OUTBOUND` (Outbound) |
| `ReferralScore` | int | Einstein-scored likelihood the referral will buy the product |
| `Category` | picklist | Category of referral |
| `Priority` | picklist | Priority of the referral |
| `EstimatedReferralValue` | currency | Estimated business value (target AUM, anticipated loan amount, policy premium) |
| `AuthorizationStatus` | picklist | `Submitted`, `InReview`, `Authorized`, `Rejected` |
| `Result` | picklist | Referral outcome |
| `IsSelfReferred` | boolean | Whether the client made the referral themselves (default: false) |
| `IsBusinessReferral` | boolean | Whether the referral represents a business entity (default: false) |
| `ClientId` | Lookup(Account) | Account associated with the referral (the referred client) |
| `ClientName` | string | Name of the referral |
| `ClientBusinessName` | string | Name of the referred business |
| `ClientEmail` | email | Email address of the referral |
| `ClientPhone` | phone | Phone number of the referral |
| `ClientLanguage` | multipicklist | Languages the referral speaks |
| `ReferrerId` | Lookup(Account, Contact, LoyaltyProgramMember, User) | Person or organization that made the referral |
| `ReferrerContactId` | Lookup(Contact) | Contact associated with the referrer |
| `ReferrerName` | string | Name of the referring person/organization |
| `ReferrerOrg` | string | Organization that referred the client |
| `ReferrerEmail` | email | Email of the referrer |
| `ReferrerPhone` | phone | Phone of the referrer |
| `ReferredPartyId` | Lookup(Account, Contact, Lead) | The party being referred |
| `ProviderId` | Lookup(Account, Contact, HealthcareProvider) | Person/org the client is being referred to |
| `ProviderName` | string | Name of the provider |
| `ProviderOrg` | string | Organization the client is referred to |
| `ProviderEmail` | email | Email of the provider |
| `ProviderPhone` | phone | Phone of the provider |
| `OpportunityId` | Lookup(Opportunity) | Associated Opportunity record |
| `CaseId` | Lookup(Case) | Associated Case record |
| `Product2Id` | Lookup(Product2) | Product the referral wants to buy |
| `ProductCategoryId` | Lookup(ProductCategory) | Product category |
| `OutboundSourceId` | Lookup(ApplicationForm, Case, Referral) | Source of an outbound referral |
| `Description` | textarea | Description of the referral |
| `Comments` | textarea | Additional details |
| `OwnerId` | Lookup(User, Group) | Record owner |

**Note on Einstein Referral Scoring:** `ReferralScore` is populated by Einstein Referral Scoring when `enableReferralScoring = true` in IndustriesSettings. This is an AI-generated field; do not set it manually in integrations.

---

## ResidentialLoanApplication (Key Fields)

The `ResidentialLoanApplication` object (available API v48.0+, Mortgage/Lending module) is the central record for loan origination. The `createFinancialRecords` invocable action takes a `ResidentialLoanApplication.Id` as input and creates downstream FSC records from it.

Key relationships used by `createFinancialRecords` output:
- Creates `PersonAccount` records from loan applicant data
- Creates `FinancialAccount` records representing assets, liabilities, and the mortgage loan (controlled by `IndustriesSettings` flags: `createFinancialAccountFromLAAsset`, `createFinancialAccountFromLALiability`, `createFinancialAccountsFromLAFinancials`)
- Creates `CustomerProperty` records from loan application properties
- Creates `AssetsAndLiabilities` records

The `createFinancialRecords` action returns ID lists for each created record type, enabling downstream flow actions to reference newly-created records without additional SOQL queries.
