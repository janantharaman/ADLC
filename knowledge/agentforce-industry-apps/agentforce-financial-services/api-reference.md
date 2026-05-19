---
source: Salesforce Financial Services Cloud Developer Guide + FSC Object Reference (developer.salesforce.com, Spring '26); org metadata queried from LKInsuranceDev via Headless 360 MCP (API v67.0, 2026-05-10); fsc_dev_guide.pdf (1396p); Spring '26 (April 28, 2026); grounded 2026-05-11
cloud: Financial Services Cloud
section: api-reference
last-updated: 2026-05-11
---

# Financial Services Cloud — API Reference

> **Note on documentation access:** The Salesforce Atlas documentation portal (developer.salesforce.com/docs/atlas) uses JavaScript rendering that is not accessible via automated fetch. The API reference sections below are compiled from: (1) direct org metadata queries via Tooling API v67.0 on LKInsuranceDev, (2) Salesforce product documentation knowledge current as of Spring '26, and (3) observed patterns in this org's implementation. Sections on Connect REST APIs and Invocable Actions reflect platform-level FSC capabilities; specific endpoints should be verified against the live org's documentation or the Salesforce FSC Object Reference guide at developer.salesforce.com.

---

## Standard Salesforce APIs for FSC Objects

FSC objects are accessible via all standard Salesforce APIs since they are platform-managed standard objects:

| API | Access Method | Notes |
|---|---|---|
| REST API | `GET/POST/PATCH/DELETE /services/data/vXX.0/sobjects/{ObjectName}/` | Standard CRUD for all FSC objects |
| SOAP API | WSDL-based | Full CRUD; use for integration with legacy systems |
| Bulk API 2.0 | `/services/data/vXX.0/jobs/ingest/` | For high-volume data loads (InsurancePolicy, Claim initial loads) |
| Tooling API | `/services/data/vXX.0/tooling/sobjects/` | Metadata and field definitions |
| SOQL | Via REST/SOAP query endpoint | Standard SOQL including relationships |
| Streaming API / CometD | PushTopic, CDC | ChangeEvent objects available for all core FSC objects |

### Change Data Capture (CDC) Objects

All major FSC objects have CDC events enabled. To subscribe:
- Topic: `/data/{ObjectName}ChangeEvent`
- Available events: `ClaimChangeEvent`, `InsurancePolicyChangeEvent`, `InsurancePolicyCoverageChangeEvent`, `InsurancePolicyParticipantChangeEvent`, `InsurancePolicyAssetChangeEvent`, `InsurancePolicyTransactionChangeEvent`, `FinancialAccountChangeEvent`, `FinancialAccountTransactionChangeEvent`, `FinancialGoalChangeEvent`, `FinancialPlanChangeEvent`, `FinancialSecurityChangeEvent`, `ClaimCoverageChangeEvent`, `ClaimItemChangeEvent`, `ClaimParticipantChangeEvent`, `ClaimPaymentSummaryChangeEvent`, `InsuranceContractChangeEvent`, `InsuranceRatePlanChangeEvent`

---

## Connect REST API — FSC Business APIs

The FSC Connect REST API provides higher-level operations beyond basic CRUD. Base path: `/services/data/vXX.0/connect/`

### Insurance APIs

| Endpoint | Method | Description |
|---|---|---|
| `/connect/insurance/policies` | GET | Retrieve insurance policies with filtering |
| `/connect/insurance/policies/{policyId}` | GET | Get single policy with related data |
| `/connect/insurance/claims` | GET, POST | List or create claims |
| `/connect/insurance/claims/{claimId}` | GET, PATCH | Get or update a claim |
| `/connect/insurance/claims/{claimId}/fnol` | POST | Submit First Notice of Loss |

### Async Bulk Operations

FSC provides `InsuranceAsyncBulkRequest` for bulk policy and claim operations:

- Create `InsuranceAsyncBulkRequest` with `Type` (e.g., `PolicyRenewal`, `ClaimBatch`)
- Create `InsuranceAsyncBulkRequestItem` records as children
- Poll `InsuranceAsyncBulkRequest.Status` for completion
- Review `InsuranceAsyncBulkRecordDetail` for per-record results

---

## Invocable Actions — FSC

FSC registers several invocable actions (callable from Flow and Apex).

### Insurance Invocable Actions

| Action Name | Category | Description |
|---|---|---|
| `CreateInsurancePolicy` | Insurance | Creates an InsurancePolicy with related participant and coverage records in one transaction |
| `RenewInsurancePolicy` | Insurance | Creates a renewal policy linked to the prior policy via `RenewedFromPolicyId` |
| `CancelInsurancePolicy` | Insurance | Sets policy Status to Cancelled with cancellation date and reason |
| `EndorseInsurancePolicy` | Insurance | Creates an endorsement version of a policy |
| `CreateClaim` | Claims | Creates a Claim record linked to a policy (FNOL action) |
| `CloseClaim` | Claims | Marks a claim as closed with final settlement amount |
| `GeneratePremiumSchedule` | Insurance | Generates `InsurancePolicyTransaction` billing schedule records for a policy |

### Financial Account Invocable Actions

| Action Name | Category | Description |
|---|---|---|
| `CreateFinancialAccount` | Banking | Creates a FinancialAccount with initial balance and party |
| `CloseFinancialAccount` | Banking | Sets FinancialAccount Status to Closed with closing date |
| `TransferFunds` | Banking | Creates debit/credit FinancialAccountTransaction pair between two accounts |

### Household / Relationship Actions

| Action Name | Category | Description |
|---|---|---|
| `CreateHousehold` | Relationships | Creates a Household Account and links existing Contacts |
| `AddHouseholdMember` | Relationships | Creates AccountAccountRelation or ContactContactRelation for household |
| `CreateReferral` | Referrals | Creates a referral record and associated Contact-Contact relationship |

---

## Apex Namespaces and Classes

FSC provides Apex classes under the `financialservices` or `ConnectApi` namespace.

### ConnectApi Namespace (FSC)

```apex
// Insurance policy operations
ConnectApi.InsurancePolicy policy = ConnectApi.Insurance.getPolicy(policyId);
ConnectApi.InsurancePolicyInput input = new ConnectApi.InsurancePolicyInput();
ConnectApi.Insurance.createPolicy(input);

// Claim operations
ConnectApi.ClaimInput claimInput = new ConnectApi.ClaimInput();
claimInput.policyId = policyId;
claimInput.lossDate = Date.today();
ConnectApi.Insurance.createClaim(claimInput);
```

### Key Apex Trigger Considerations for FSC

```apex
// Correct pattern: query FSC objects via standard SOQL
List<InsurancePolicy> policies = [
    SELECT Id, Name, Status, NameInsuredId, EffectiveDate, ExpirationDate,
           WritingCarrierAccountId, ProducerId, PremiumAmount
    FROM InsurancePolicy
    WHERE NameInsuredId = :accountId
    AND Status = 'InForce'
];

// Claim with related policy participant and coverage
List<Claim> claims = [
    SELECT Id, Name, Status, PolicyNumberId,
           PolicyNumberId.Name, PolicyNumberId.NameInsuredId,
           LossDate, ActualAmount, EstimatedAmount,
           (SELECT Id, Roles, ParticipantAccountId FROM ClaimParticipants),
           (SELECT Id, InsurancePolicyCoverageId, LossReserveAmount FROM ClaimCoverages)
    FROM Claim
    WHERE PolicyNumberId IN :policyIds
];

// InsurancePolicy with all child counts
List<InsurancePolicy> policiesWithCounts = [
    SELECT Id, Name, Status,
           (SELECT Id FROM InsurancePolicyCoverages),
           (SELECT Id FROM InsurancePolicyParticipants),
           (SELECT Id FROM Claims)
    FROM InsurancePolicy
    WHERE Id = :policyId
];
```

### Child Relationship Names for SOQL

| Parent Object | Child Object | Relationship Name in SOQL |
|---|---|---|
| `InsurancePolicy` | `InsurancePolicyCoverage` | `InsurancePolicyCoverages` |
| `InsurancePolicy` | `InsurancePolicyAsset` | `InsurancePolicyAssets` |
| `InsurancePolicy` | `InsurancePolicyParticipant` | `InsurancePolicyParticipants` |
| `InsurancePolicy` | `InsurancePolicyTransaction` | `InsurancePolicyTransactions` |
| `InsurancePolicy` | `Claim` (via PolicyNumberId) | `Claims` |
| `Claim` | `ClaimItem` | `ClaimItems` |
| `Claim` | `ClaimParticipant` | `ClaimParticipants` |
| `Claim` | `ClaimCoverage` | `ClaimCoverages` |
| `FinancialAccount` | `FinancialAccountTransaction` | `FinancialAccountTransactions` |
| `FinancialAccount` | `FinancialAccountParty` | `FinancialAccountParties` |
| `FinancialAccount` | `FinancialAccountBalance` | `FinancialAccountBalances` |

---

## SOQL Query Patterns

### Get All Active Policies for an Account

```soql
SELECT Id, Name, Status, PolicyType, LineOfBusiness,
       EffectiveDate, ExpirationDate, PremiumAmount, TotalSumInsured,
       WritingCarrierAccountId, ProducerId
FROM InsurancePolicy
WHERE NameInsuredId = '001XXXXXXXXXXXXXXX'
AND Status = 'InForce'
ORDER BY ExpirationDate ASC
```

### Get Open Claims with Policy and Coverage Detail

```soql
SELECT Id, Name, Status, ClaimType, LossDate, EstimatedAmount, ActualAmount,
       PolicyNumberId, PolicyNumberId.Name, PolicyNumberId.NameInsuredId,
       AccountId, AccountId.Name
FROM Claim
WHERE IsClosed = false
AND Status != 'Denied'
ORDER BY LossDate DESC
```

### Get Policy Participants with Roles

```soql
SELECT Id, Role, PrimaryParticipantAccountId, PrimaryParticipantAccountId.Name,
       IsActiveParticipant, IsPolicyholder,
       InsurancePolicyId, InsurancePolicyId.Name
FROM InsurancePolicyParticipant
WHERE InsurancePolicyId = '0MW00000000XXXXXXX'
ORDER BY Role
```

### Get Financial Accounts for a Client

```soql
SELECT Id, Name, Type, Status, FinancialAccountNumber,
       OpeningDate, MaturityDate, PrincipalAmount, TotalOutstandingAmount,
       InterestRate, BankerId, BranchUnitId
FROM FinancialAccount
WHERE Id IN (
    SELECT FinancialAccountId FROM FinancialAccountParty
    WHERE PartyId = '001XXXXXXXXXXXXXXX'
)
ORDER BY OpeningDate DESC
```

### Policy Coverage Summary

```soql
SELECT InsurancePolicyId, InsurancePolicyId.Name,
       Category, CategoryGroup,
       LimitAmount, DeductibleAmount, PremiumAmount,
       EffectiveFromDate, EffectiveToDate
FROM InsurancePolicyCoverage
WHERE InsurancePolicyId = '0MW00000000XXXXXXX'
ORDER BY Category, CategoryGroup
```

---

## RecordType Usage

Several FSC objects use Record Types to branch the data model:

| Object | Common Record Types | Notes |
|---|---|---|
| `InsurancePolicy` | Commercial, Personal, Life, Marine | Controls page layout and picklist values |
| `Claim` | Auto, Property, Liability, Marine, Life | Controls adjuster assignment rules and page layout |
| `FinancialAccount` | Checking, Savings, Loan, Investment, InsurancePremium | Controls visible fields |
| `Account` | Household, Person Account, Business | Household type activates ARC household features |

---

## Platform Events and CDC Integration

### Change Data Capture Subscription (LWC)

```javascript
import { LightningElement } from 'lwc';
import { subscribe, MessageContext } from 'lightning/empApi';

export default class PolicyChangeSubscriber extends LightningElement {
    subscription = {};

    connectedCallback() {
        subscribe('/data/InsurancePolicyChangeEvent', -1, (message) => {
            const changeType = message.data.payload.ChangeEventHeader.changeType;
            const recordIds = message.data.payload.ChangeEventHeader.recordIds;
            // Handle 'CREATE', 'UPDATE', 'DELETE', 'UNDELETE'
        }).then(response => {
            this.subscription = response;
        });
    }
}
```

### Platform Event for FSC Integration

Common pattern for policy admin system integration:
1. External system publishes Platform Event `PolicySyncEvent__e` on policy change
2. FSC org subscribes via Flow or Apex trigger
3. Upsert `InsurancePolicy` using `SourceSystemIdentifier` as external ID key
4. Upsert child `InsurancePolicyCoverage` and `InsurancePolicyParticipant` records

---

## Important API Constraints

| Constraint | Detail |
|---|---|
| `SourceSystemIdentifier` uniqueness | Unique Case-Insensitive on InsurancePolicyCoverage, InsurancePolicyParticipant, InsurancePolicyAsset, ClaimParticipant — enforce in integration upserts |
| `FinancialAccount.SourceSystemIdentifier` | External Lookup type — links to external system without Salesforce ID constraint |
| `InsurancePolicy.UniversalPolicyNumber` | Unique Case-Insensitive — use for cross-system policy number lookups |
| `InsurancePolicyCoverage.Name` | Auto Number — do not set manually |
| `InsurancePolicyParticipant.Name` | Auto Number — do not set manually |
| `InsurancePolicyAsset.Name` | Auto Number — do not set manually |
| `ClaimParticipant.Name` | Auto Number — do not set manually |
| `FinancialAccountTransaction.Name` | Auto Number — do not set manually |
| Master-Detail cascade delete | Deleting InsurancePolicy cascades to InsurancePolicyCoverage, InsurancePolicyAsset, InsurancePolicyParticipant, InsurancePolicyTransaction. Plan integration delete operations carefully. |
| API version | This org: v67.0 (Spring '26). Some fields may not exist in earlier API versions. |

---

## SOQL Query Patterns — Referral Object

Source: fsc_dev_guide.pdf pp.836–847 (Referral field definitions).

```soql
-- Query open inbound referrals with client and referrer detail
SELECT Id, Name, ReferralDate, ReferralType, ReferralScore,
       Category, Priority, EstimatedReferralValue, AuthorizationStatus,
       ClientId, ClientId.Name, ClientEmail, ClientPhone,
       ReferrerId, ReferrerName, ReferrerOrg,
       ProviderId, ProviderName,
       OpportunityId, OpportunityId.Name,
       Product2Id, Product2Id.Name
FROM Referral
WHERE ReferralType = 'INBOUND'
AND AuthorizationStatus NOT IN ('Rejected')
ORDER BY ReferralDate DESC

-- Query referral pipeline by source (referrer)
SELECT ReferrerId, ReferrerName, ReferrerOrg,
       COUNT(Id) ReferralCount,
       SUM(EstimatedReferralValue) TotalEstimatedValue,
       AVG(ReferralScore) AvgScore
FROM Referral
WHERE ReferralDate >= LAST_N_MONTHS:12
GROUP BY ReferrerId, ReferrerName, ReferrerOrg
ORDER BY TotalEstimatedValue DESC

-- Query referrals by category for a specific client
SELECT Id, Name, ReferralDate, Category, Priority,
       ReferralType, AuthorizationStatus, EstimatedReferralValue,
       ReferrerName, ProviderName
FROM Referral
WHERE ClientId = '001XXXXXXXXXXXXXXX'
ORDER BY ReferralDate DESC

-- Query outbound referrals with their outbound source
SELECT Id, Name, ReferralDate, ReferralType,
       OutboundSourceId, ProviderId, ProviderName,
       EstimatedReferralValue
FROM Referral
WHERE ReferralType = 'OUTBOUND'
AND ReferralDate >= THIS_YEAR
```

---

## SOQL Query Patterns — FinancialDeal Object Family

Source: fsc_dev_guide.pdf pp.323–340 (FinancialDeal field definitions).

```soql
-- Query active financial deals by institution role and stage
SELECT Id, Name, FinancialDealCode, FinancialDealType, Stage, Status,
       AccountId, AccountId.Name,
       Role, TransactionValue, TotalExpectedFee, ReceivedFee,
       ExpectedCloseDate, MandatedDate, CloseProbability
FROM FinancialDeal
WHERE Status = 'Open'
ORDER BY ExpectedCloseDate ASC, CloseProbability DESC

-- Query deals by stage with deal parties
SELECT Id, Name, Stage, Status, TransactionValue,
       AccountId.Name,
       (SELECT Id, PartyId, PartyId.Name, PartyRole, PartyType, Stage
        FROM FinancialDealParties)
FROM FinancialDeal
WHERE Status != 'Closed'
ORDER BY Stage

-- Query deal participants (internal team members)
SELECT FinancialDealId, FinancialDealId.Name, FinancialDealId.Stage,
       Comments
FROM FinancialDealParticipant
WHERE FinancialDealId IN (
    SELECT Id FROM FinancialDeal WHERE Status = 'Open'
)

-- Query bids on a specific deal
SELECT Id, Name, FinancialDealId, FinancialDealPartyId,
       BidAmount, BidDate, BidRound,
       FinancialDealPartyId.PartyId, FinancialDealPartyId.PartyId.Name
FROM FinancialDealBid
WHERE FinancialDealId = '0XXXXXXXXXXXXXXXXX'
ORDER BY BidDate DESC, BidAmount DESC
```

---

## Standard Invocable Action Reference

Source: fsc_dev_guide.pdf pp.1344–1358. All actions use REST endpoint `/services/data/vXX.X/actions/standard/{actionName}`.

### Create Financial Records

**URI:** `/services/data/v49.0/actions/standard/createFinancialRecords`
**Methods:** GET, HEAD, POST | **Format:** JSON, XML | **Available:** API v49.0+

**Input Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `recordId` | ID | Yes | ID of the ResidentialLoanApplication record |

**Output Parameters**

| Parameter | Type | Description |
|---|---|---|
| `status` | string | `SUCCESS`, `PARTIAL_SUCCESS`, or `FAILURE` |
| `personAccountsIdList` | string | List of IDs for created PersonAccount records |
| `financialAccountsIdList` | string | List of IDs for created FinancialAccount records |
| `customerPropertiesIdList` | string | List of IDs for created CustomerProperty records |
| `assetsAndLiabilitiesIdList` | string | List of IDs for created AssetsAndLiabilities records |
| `errors` | string | List of errors that occurred during creation |

**Sample request:**
```json
{ "recordId": "0cdB0000000CbVGIA0" }
```

---

### Create Integration Plan

**URI:** `/services/data/v60.0/actions/standard/createIntegrationPlan`
**Methods:** POST | **Format:** JSON | **Available:** API v60.0+

**Input Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `expressionSetName` | string | Yes | API name of the expression set identifying eligible integrations and their dependencies |
| `anchorRecordId` | ID | Yes | ID of the record supplying expression set input parameters missing from contextId |
| `contextDefinitionName` | string | No (v61+) | Name of the Context Definition record |
| `contextMappingName` | string | No (v61+) | Name of the Context Mapping record |
| `contextData` | string | No (v61+) | JSON string of context data |
| `isTaggedData` | boolean | No (v61+) | Whether key in data is tagged (default: false) |

**Output Parameters**

| Parameter | Type | Description |
|---|---|---|
| `integrationPlanId` | ID | ID of the created integration plan (includes callout steps and dependencies) |

---

### Run Integration Plan

**URI:** `/services/data/v60.0/actions/standard/runIntegrationPlan`
**Methods:** POST | **Format:** JSON | **Available:** API v60.0+

**Input Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `integrationPlanId` | ID | Yes | ID of the integration plan to execute |
| `contextId` | ID | No | ID of the Context Service for expression set inputs. Recommended: Applicant, ApplicationForm, or PartyProfile |

**Output Parameters**

| Parameter | Type | Description |
|---|---|---|
| `status` | string | `SUCCESS` (Running), `Not Started`, or `Failed` |

---

### Get Assessment Response Summary

**URI:** `/services/data/v56.0/actions/standard/getAssessmentResponseSummary`
**Methods:** POST | **Format:** JSON | **Available:** API v56.0+

**Input Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `assessmentId` | ID | Yes | ID of the Assessment record to summarize |

**Output Parameters**

| Parameter | Type | Description |
|---|---|---|
| `assessmentResponseSummary` | string | JSON string containing assessment question texts and responses. Structure mirrors the OmniScript step/question hierarchy. |

**Output structure example:**
```json
{
  "KYC_Individual_English": {
    "Step1": {
      "label": "Identity Details",
      "value": {
        "FullName_m": { "label": "Full Name", "value": "Joe Smith" },
        "DateOfBirth_m": { "label": "Date of Birth", "value": "2000-07-27" }
      }
    }
  }
}
```

---

### Get Picklist Values

**URI:** `/services/data/v66.0/actions/standard/getPicklistValues`
**Methods:** POST | **Format:** JSON, XML | **Available:** API v65.0+

**Input Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `inputData` | string | Yes | JSON array of objects. Each object: `{ "objectName": "...", "recordTypeId": "...", "fields": ["field1", "field2"] }`. `recordTypeId` is optional. |

**Output Parameters**

| Parameter | Type | Description |
|---|---|---|
| `outputData` | string | JSON array. Each element: `{ "objectName": "...", "fieldMetadata": [{ "fieldName": "...", "picklistValues": [{ "apiName": "...", "label": "..." }] }] }`. Invalid fields return `errorMessage` instead of `picklistValues`. |

**Sample input:**
```json
{
  "inputs": {
    "inputData": [
      { "objectName": "FinancialPlan", "fields": ["Status", "Type"] },
      { "objectName": "Claim", "recordTypeId": "012XXXXXXXXXXXXXXX", "fields": ["Status"] }
    ]
  }
}
```

---

### Publish Actionable Orchestration Source Event

**URI:** `/services/data/v66.0/actions/standard/publishActionableOrchSrcEvent`
**Methods:** POST | **Format:** JSON, XML | **Available:** API v62.0+

**Input Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `payloadCurrentValue` | string | Yes | JSON structure with name-value pairs from the PayloadCurrentValue field of the Data Object Data Change Event |
| `sourceObjectDeveloperName` | string | Yes | API name of the source object developer named field mentioned in the Payload Current Value |
| `dataSpace` | string | No | API name of the data space for managing contextual alerts |

**Output:** None (fire-and-forget)
