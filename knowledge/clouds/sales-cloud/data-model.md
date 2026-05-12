---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: data-model
last-updated: 2026-05-11
---

# Sales Cloud — Data Model

## Object Relationship Map

```
Campaign
    │
    └─► CampaignMember ◄──┬── Lead ──(convert)──► Account ◄─────────────┐
                          └── Contact                │                    │
                                    │                └──► Contact          │
                                    │                         │            │
                                    │                AccountContactRelation│
                                    │                                      │
                                    └──────────────► Opportunity ◄────────┘
                                                          │
                         ┌────────────────────────────────┼──────────────────────┐
                         │                                │                      │
               OpportunityContactRole          OpportunityLineItem           Quote
               OpportunityTeamMember             PricebookEntry           QuoteLineItem
               OpportunitySplit                   Product2                  (PDF Template)
                                                  Pricebook2
                                                       │
                                                   Contract
                                                       │
                                                  Order / OrderItem
```

---

## Lead

**API name:** `Lead`  
**Purpose:** Unqualified prospect not yet associated with Account, Contact, or Opportunity. Self-contained record until converted.

### Standard Fields

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| First Name | `FirstName` | String(40) | Optional |
| Last Name | `LastName` | String(80) | Required |
| Company | `Company` | String(255) | Required |
| Email | `Email` | Email | Used for duplicate matching |
| Phone | `Phone` | Phone | |
| Mobile | `MobilePhone` | Phone | |
| Title | `Title` | String(128) | |
| Website | `Website` | URL | |
| Lead Source | `LeadSource` | Picklist | See values below |
| Status | `Status` | Picklist | Drives assignment rules; see values below |
| Rating | `Rating` | Picklist | Hot / Warm / Cold |
| Annual Revenue | `AnnualRevenue` | Currency | |
| Number of Employees | `NumberOfEmployees` | Integer | |
| Industry | `Industry` | Picklist | Standard industry list |
| Address (Street/City/State/PostalCode/Country) | `Street`, `City`, `State`, `PostalCode`, `Country` | String | Separate fields; no compound address on Lead |
| Description | `Description` | TextArea(32000) | |
| Owner | `OwnerId` | Lookup(User/Queue) | Assignment Rules target this |
| Is Converted | `IsConverted` | Boolean | Read-only after convert; irreversible |
| Converted Date | `ConvertedDate` | Date | Set on conversion |
| Converted Account | `ConvertedAccountId` | Lookup(Account) | Set on conversion |
| Converted Contact | `ConvertedContactId` | Lookup(Contact) | Set on conversion |
| Converted Opportunity | `ConvertedOpportunityId` | Lookup(Opportunity) | Null if no Opp created at convert |
| Campaign | `CampaignId` | Lookup(Campaign) | Primary campaign attribution |
| Do Not Call | `DoNotCall` | Boolean | |
| Email Opt Out | `HasOptedOutOfEmail` | Boolean | |
| Fax Opt Out | `HasOptedOutOfFax` | Boolean | |
| Unread By Owner | `IsUnreadByOwner` | Boolean | Set true when new lead assigned |
| Jigsaw Contact ID | `JigsawContactId` | String | Data.com legacy field |

### Status Picklist (Default Values)

| Value | Meaning |
|---|---|
| Open - Not Contacted | New lead, no outreach yet |
| Working - Contacted | Rep has made contact |
| Closed - Converted | `IsConverted = true`; set automatically |
| Closed - Not Converted | Disqualified without converting |

**Customisation:** Add intermediate stages (e.g., "Nurture", "Meeting Scheduled"). The "Closed - Converted" value is reserved and cannot be removed.

### Rating Picklist (Default Values)
`Hot`, `Warm`, `Cold`

### LeadSource Picklist (Default Values)
`Web`, `Phone Inquiry`, `Partner Referral`, `Purchased List`, `Other`  
Add: `Inbound Marketing`, `Outbound SDR`, `Event`, `Referral` as standard additions for most engagements.

### Lead Conversion Behaviour

On `convertLead()`:
1. **Account**: Creates new Account from Lead.Company, or merges into existing Account if matched
2. **Contact**: Creates new Contact mapped from Lead fields, or merges into existing Contact
3. **Opportunity**: Optional — created with Lead.Company as name unless overridden; Stage defaults to first active stage
4. **Field mapping**: Custom Lead fields must have explicit field mappings to Account/Contact/Opportunity fields configured in Setup > Lead Fields > Map Lead Fields. Unmapped custom fields are lost on conversion.
5. **IsConverted** is set to `true` permanently; Lead record remains for historical reporting
6. **Duplicate rules** fire on convert for Account and Contact creation; configure carefully
7. **System fields added to Contact History**: `contactCreatedByLead` (Contact created from this Lead) and `contactUpdatedByLead` (existing Contact was updated). Read-only; for audit trail only.

### Key Relationship
Lead → Campaign via `CampaignId` (first touch attribution). Additional touches tracked via CampaignMember with `LeadId`.

---

## Account

**API name:** `Account`  
**Purpose:** Company (B2B) or individual (B2C via Person Account). Anchor of the Sales Cloud data model.

### Standard Fields

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Account Name | `Name` | String(255) | Required |
| Account Number | `AccountNumber` | String(40) | Not auto-generated; org-specific |
| Account Site | `Site` | String(80) | Branch/location qualifier |
| Type | `Type` | Picklist | See values below |
| Industry | `Industry` | Picklist | Standard industry list |
| Annual Revenue | `AnnualRevenue` | Currency | |
| Number of Employees | `NumberOfEmployees` | Integer | |
| Rating | `Rating` | Picklist | Hot / Warm / Cold |
| Phone | `Phone` | Phone | |
| Fax | `Fax` | Phone | |
| Website | `Website` | URL | |
| Billing Address | `BillingStreet/City/State/PostalCode/Country` | Address | |
| Shipping Address | `ShippingStreet/City/State/PostalCode/Country` | Address | |
| Description | `Description` | TextArea(32000) | |
| Owner | `OwnerId` | Lookup(User) | |
| Parent Account | `ParentId` | Lookup(Account) | Enables account hierarchy (up to 10 levels) |
| Account Source | `AccountSource` | Picklist | Tracks how account was created |
| SIC Code | `Sic` | String(20) | Standard Industry Classification |
| Ticker Symbol | `TickerSymbol` | String(20) | Public companies |
| Ownership | `Ownership` | Picklist | Public, Private, Subsidiary, Other |
| Jigsaw | `Jigsaw` | String | Data.com legacy |
| Cleaned Status | `CleanStatus` | Picklist | Data quality (if Data.com/Clean used) |

### Type Picklist (Default Values)
`Prospect`, `Customer - Direct`, `Customer - Channel`, `Channel Partner / Reseller`, `Installation Partner`, `Technology Partner`, `Other`

### Person Account Fields (B2C)
When Person Accounts enabled, Account gets Contact fields merged in: `FirstName`, `LastName`, `Email`, `MobilePhone`, `Birthdate`, `Gender__pc` (if enabled), etc. `IsPersonAccount` boolean field added to Account. Person Account records have no separate Contact record.

**Warning:** Person Accounts cannot be disabled once enabled. Requires careful OWD and sharing design — triggers and code must handle `IsPersonAccount` checks.

### Account Hierarchy
`ParentId` self-lookup creates hierarchy. Reports can traverse up to 10 levels. No native rollup of Opportunity amounts up the hierarchy — requires custom solution (Apex batch, formula, or CRM Analytics). `AccountHierarchy` SOSL feature allows querying all descendants.

### Account Team
`AccountTeamMember` child object. Team members get configurable access to Account, related Contacts, Opportunities, and Cases. Access levels: `Read`, `Edit`. Account Team Selling must be enabled in Setup.

---

## Contact

**API name:** `Contact`  
**Purpose:** Individual person associated with an Account.

### Standard Fields

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| First Name | `FirstName` | String(40) | |
| Last Name | `LastName` | String(80) | Required |
| Account Name | `AccountId` | Lookup(Account) | Required unless Contacts to Multiple Accounts enabled |
| Reports To | `ReportsToId` | Lookup(Contact) | Self-lookup for org chart |
| Title | `Title` | String(128) | |
| Department | `Department` | String(80) | |
| Email | `Email` | Email | |
| Phone | `Phone` | Phone | |
| Mobile | `MobilePhone` | Phone | |
| Fax | `Fax` | Phone | |
| Mailing Address | `MailingStreet/City/State/PostalCode/Country` | Address | |
| Other Address | `OtherStreet/City/State/PostalCode/Country` | Address | |
| Lead Source | `LeadSource` | Picklist | How contact was acquired |
| Birthdate | `Birthdate` | Date | |
| Description | `Description` | TextArea(32000) | |
| Owner | `OwnerId` | Lookup(User) | |
| Do Not Call | `DoNotCall` | Boolean | |
| Email Opt Out | `HasOptedOutOfEmail` | Boolean | |
| Fax Opt Out | `HasOptedOutOfFax` | Boolean | |

### Contacts to Multiple Accounts (AccountContactRelation)

When "Contacts to Multiple Accounts" is enabled:
- `AccountContactRelation` junction object links one Contact to multiple Accounts
- `AccountId` on Contact remains the "direct" or primary account
- `IsActive`, `IsDirect`, `Roles` (multi-select picklist) fields on ACR
- ACR is queryable via SOQL: `SELECT AccountId, ContactId, Roles FROM AccountContactRelation`
- Impacts triggers and integrations that assume single Account per Contact

### Merge Behaviour
Merging Contacts: Activities, cases, and opportunities (via OpportunityContactRole) re-parent to the surviving Contact. Duplicate rules should be configured before large-scale imports.

---

## Opportunity

**API name:** `Opportunity`  
**Purpose:** A specific sales deal with a projected close date and amount. Primary forecasting and pipeline unit.

### Standard Fields

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Opportunity Name | `Name` | String(120) | Required |
| Account Name | `AccountId` | Lookup(Account) | Required for most use cases |
| Close Date | `CloseDate` | Date | Required |
| Stage | `StageName` | Picklist | Required; maps to Forecast Category |
| Amount | `Amount` | Currency | Not required; populated from line items or manual entry |
| Probability | `Probability` | Percent | Auto-set from Stage; overridable |
| Expected Revenue | `ExpectedRevenue` | Currency | Calculated: Amount × Probability (read-only by default) |
| Forecast Category | `ForecastCategoryName` | Picklist | Derived from Stage; 5 default values |
| Type | `Type` | Picklist | New Business, Existing Business, Renewal, etc. |
| Lead Source | `LeadSource` | Picklist | How this deal was sourced |
| Campaign Source | `CampaignId` | Lookup(Campaign) | Primary campaign attribution |
| Price Book | `Pricebook2Id` | Lookup(Pricebook2) | Must be set before adding products |
| Owner | `OwnerId` | Lookup(User) | |
| Description | `Description` | TextArea(32000) | |
| Next Step | `NextStep` | String(255) | Free text; useful for stage gate tracking |
| Has Overdue Task | `HasOverdueTask` | Boolean | Computed |
| Has Open Activity | `HasOpenActivity` | Boolean | Computed |
| Has Activity | `HasActivity` | Boolean | Computed |
| Last Activity Date | `LastActivityDate` | Date | Computed from related activities |
| Last Modified Date | `LastModifiedDate` | DateTime | System |
| Is Closed | `IsClosed` | Boolean | True when Stage is "Closed Won" or "Closed Lost" |
| Is Won | `IsWon` | Boolean | True when Stage is "Closed Won" |
| Fiscal Quarter/Year | `FiscalQuarter`, `FiscalYear` | Integer | Derived from CloseDate + org fiscal year settings |
| Total Opportunity Amount | `TotalOpportunityQuantity` | Number | Sum of OLI quantities |
| Synced Quote | `SyncedQuoteId` | Lookup(Quote) | The currently syncing quote |
| Contract | `ContractId` | Lookup(Contract) | Links to generated contract |
| Partner Account | `PartnerAccountId` | Lookup(Account) | Channel/partner attribution |

### Stage Picklist and Forecast Category Mapping

| Default Stage Value | Default Probability | Default Forecast Category |
|---|---|---|
| Prospecting | 10% | Pipeline |
| Qualification | 20% | Pipeline |
| Needs Analysis | 20% | Pipeline |
| Value Proposition | 50% | Pipeline |
| Id. Decision Makers | 60% | Pipeline |
| Perception Analysis | 70% | Pipeline |
| Proposal/Price Quote | 75% | Pipeline |
| Negotiation/Review | 90% | Best Case |
| Closed Won | 100% | Closed |
| Closed Lost | 0% | Omitted |

**Critical:** Adding new Stage values without mapping Forecast Category defaults to `Omitted` — those Opportunities disappear from forecasts silently.

### Forecast Category Values
`Omitted`, `Pipeline`, `Best Case`, `Commit`, `Closed`

Custom Forecast Categories can be added (e.g., "Most Likely") — requires Forecast Settings configuration.

---

## OpportunityLineItem (Opportunity Product)

**API name:** `OpportunityLineItem`  
**Purpose:** Individual product lines on an Opportunity.

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Opportunity | `OpportunityId` | Lookup(Opportunity) | Required; parent |
| Product | `Product2Id` | Lookup(Product2) | Read-only after insert |
| Price Book Entry | `PricebookEntryId` | Lookup(PricebookEntry) | Required |
| Quantity | `Quantity` | Number | Required |
| Unit Price | `UnitPrice` | Currency | Sales price (may differ from list) |
| Total Price | `TotalPrice` | Currency | Calculated: UnitPrice × Quantity |
| List Price | `ListPrice` | Currency | From PricebookEntry; read-only |
| Discount | `Discount` | Percent | Does NOT auto-adjust UnitPrice; informational unless trigger/flow enforces |
| Service Date | `ServiceDate` | Date | For time-based or subscription products |
| Description | `Description` | TextArea(32000) | Product line description |
| Sort Order | `SortOrder` | Integer | Sequence on quotes/PDFs |
| Product Name | `Name` | String | From Product2; read-only |
| Product Code | `ProductCode` | String | From Product2; read-only |
| Product Family | `Product2.Family` | Picklist | Via relationship |

**Notes:**
- `Opportunity.Pricebook2Id` must be set before inserting OLI records
- When `Discount` is populated, Apex/Flow must calculate the adjusted `UnitPrice` — the field is not auto-computed by the platform
- If Quote is syncing, OLI changes propagate from QuoteLineItem; direct OLI edits may be blocked

---

## OpportunityContactRole

**API name:** `OpportunityContactRole`  
**Purpose:** Junction object linking Contacts to Opportunities with role context.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Opportunity | `OpportunityId` | Lookup(Opportunity) | |
| Contact | `ContactId` | Lookup(Contact) | |
| Role | `Role` | Picklist | See values below |
| Is Primary | `IsPrimary` | Boolean | Only one primary per Opportunity |

### Role Picklist (Default Values)
`Business User`, `Decision Maker`, `Economic Buyer`, `Economic Decision Maker`, `Evaluator`, `Executive Sponsor`, `Influencer`, `Technical Buyer`, `Other`

**Notes:**
- Required for Opportunity to appear in Contact's Activity Timeline correctly
- Not enforced by platform — must use Validation Rules or Flow to require at least one OCR with IsPrimary
- MEDDIC/MEDPICC implementations typically add custom Role values

---

## OpportunitySplit

**API name:** `OpportunitySplit`  
**Purpose:** Distributes Opportunity credit across multiple users.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Opportunity | `OpportunityId` | Lookup(Opportunity) | |
| User | `SplitOwnerId` | Lookup(User) | Split recipient |
| Split Type | `SplitTypeId` | Lookup(OpportunitySplitType) | Revenue, Overlay, or custom type |
| Split Percentage | `SplitPercentage` | Percent | Must total 100% for Revenue splits |
| Split Amount | `SplitAmount` | Currency | Calculated from Amount × Percentage |

**Prerequisites:** Collaborative Forecasting must be enabled. Opportunity Splits must be enabled in Setup > Opportunity Splits.

**Split Types:**
- **Revenue Split**: Credits for quota tracking; must total 100%
- **Overlay Split**: For specialists/SEs; can exceed 100% total
- Custom split types can be created for different attribution purposes

---

## Product2

**API name:** `Product2`  
**Purpose:** Product or service catalog entry.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Product Name | `Name` | String(255) | Required |
| Product Code | `ProductCode` | String(255) | SKU/part number |
| Product Family | `Family` | Picklist | Groups products for reporting and Forecast Types |
| Is Active | `IsActive` | Boolean | Inactive products hidden from Pricebook selection |
| Description | `Description` | TextArea(4000) | |
| Quantity Unit of Measure | `QuantityUnitOfMeasure` | Picklist | |
| External Data Source Key | `ExternalId` | String | For ERP sync patterns |

**Notes:**
- Products must have at least one PricebookEntry (in Standard Price Book) before they can be added to Opportunities
- Deactivating a product (`IsActive = false`) does not affect existing OLI records

---

## Pricebook2

**API name:** `Pricebook2`  
**Purpose:** Price list container.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Name | `Name` | String(255) | Required |
| Is Active | `IsActive` | Boolean | |
| Is Standard | `IsStandard` | Boolean | True only for the Standard Price Book; read-only |
| Description | `Description` | TextArea(255) | |

**Standard Price Book:** Every org has exactly one Standard Price Book (`IsStandard = true`). It cannot be deleted. In test contexts, use `Test.getStandardPricebookId()` to retrieve its ID (hardcoded ID is invalid in test methods). A product must have a Standard Price Book entry before it can be added to custom price books.

---

## PricebookEntry

**API name:** `PricebookEntry`  
**Purpose:** Links a Product2 to a Pricebook2 with a price.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Product | `Product2Id` | Lookup(Product2) | Required |
| Price Book | `Pricebook2Id` | Lookup(Pricebook2) | Required |
| Unit Price | `UnitPrice` | Currency | List price for this product in this book |
| Is Active | `IsActive` | Boolean | |
| Use Standard Price | `UseStandardPrice` | Boolean | If true, pulls price from Standard PBE |
| Currency ISO Code | `CurrencyIsoCode` | Picklist | In multi-currency orgs |

---

## Quote

**API name:** `Quote`  
**Purpose:** Formal pricing document generated from an Opportunity.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Opportunity | `OpportunityId` | Lookup(Opportunity) | Required |
| Quote Name | `Name` | String(255) | |
| Status | `Status` | Picklist | Draft, Needs Review, In Review, Approved, Rejected, Presented, Accepted, Denied |
| Is Syncing | `IsSyncing` | Boolean | Only one per Opp can be true |
| Expiration Date | `ExpirationDate` | Date | |
| Discount | `Discount` | Percent | |
| Subtotal | `Subtotal` | Currency | Sum before discount/tax |
| Tax | `Tax` | Currency | Manual entry; no auto-tax calculation natively |
| Total Price | `TotalPrice` | Currency | |
| Grand Total | `GrandTotal` | Currency | Total + Tax |
| Billing Address | `BillingStreet/City/State/PostalCode/Country` | Address | Defaults from Account |
| Shipping Address | `ShippingStreet/City/State/PostalCode/Country` | Address | |
| Contact | `ContactId` | Lookup(Contact) | Quote recipient |
| Owner | `OwnerId` | Lookup(User) | |
| Description | `Description` | TextArea(32000) | |

**Sync Behaviour:**
- Only one Quote per Opportunity can have `IsSyncing = true`
- When syncing: QuoteLineItem changes flow to OpportunityLineItems; Opportunity.Amount = Quote.GrandTotal
- Starting sync on one Quote automatically stops sync on any other Quote for the same Opportunity
- Stopping sync leaves OLI/Amount at last synced values

---

## QuoteLineItem

**API name:** `QuoteLineItem`  
**Purpose:** Product lines on a Quote.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Quote | `QuoteId` | Lookup(Quote) | Required |
| Product | `Product2Id` | Lookup(Product2) | |
| Price Book Entry | `PricebookEntryId` | Lookup(PricebookEntry) | Required |
| Quantity | `Quantity` | Number | Required |
| Unit Price | `UnitPrice` | Currency | |
| Total Price | `TotalPrice` | Currency | Calculated |
| List Price | `ListPrice` | Currency | From PBE |
| Discount | `Discount` | Percent | |
| Description | `Description` | TextArea | |
| Service Date | `ServiceDate` | Date | |
| Sort Order | `SortOrder` | Integer | |

---

## Contract

**API name:** `Contract`  
**Purpose:** Legal agreement between org and Account; often generated post-Closed Won.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Account | `AccountId` | Lookup(Account) | Required |
| Status | `Status` | Picklist | Draft, Activated, In Approval Process |
| Contract Number | `ContractNumber` | Auto-number | System-generated |
| Start Date | `StartDate` | Date | |
| Contract Term (months) | `ContractTerm` | Integer | |
| End Date | `EndDate` | Date | Calculated from Start + Term |
| Owner | `OwnerId` | Lookup(User) | |
| Contract | `ContractId` | (Opportunity has Lookup to Contract) | |
| Billing/Shipping Address | Various | Address | |
| Description | `Description` | TextArea | |
| Special Terms | `SpecialTerms` | TextArea | |
| Activated By | `ActivatedById` | Lookup(User) | Set on Status = Activated |
| Activated Date | `ActivatedDate` | DateTime | |

**Notes:** Once Activated, Contract cannot be edited (status becomes locked). Amendments require creating a new Contract. Integrates with CPQ for renewal automation.

---

## Order / OrderItem

**API name:** `Order`, `OrderItem`  
**Purpose:** Fulfillment records post-contract. Order represents a customer order; OrderItem is the product line.

### Order Key Fields

| Field | API Name | Type | Notes |
|---|---|---|---|
| Account | `AccountId` | Lookup(Account) | Required |
| Contract | `ContractId` | Lookup(Contract) | Optional; links to governing contract |
| Status | `Status` | Picklist | Draft, Activated |
| Effective Date | `EffectiveDate` | Date | Required |
| End Date | `EndDate` | Date | |
| Order Number | `OrderNumber` | Auto-number | |
| Bill To Contact | `BillToContactId` | Lookup(Contact) | |
| Ship To Contact | `ShipToContactId` | Lookup(Contact) | |
| Price Book | `Pricebook2Id` | Lookup(Pricebook2) | Required if adding OrderItems |
| Type | `Type` | Picklist | |
| Description | `Description` | TextArea | |

**Notes:** Orders follow same Pricebook pattern as Opportunities. OrderItems (API: `OrderItem`) reference PricebookEntry. Activated Orders are locked.

---

## Forecast / Collaborative Forecasting Objects

### ForecastingItem
Read-only aggregate object. Not directly queryable via standard SOQL in all contexts — use Forecasting API or ForecastingAdjustment objects.

### ForecastingAdjustment
**API name:** `ForecastingAdjustment`  
Manager override records on a subordinate's forecast.

| Field | API Name | Notes |
|---|---|---|
| Owner | `OwnerId` | Manager making the adjustment |
| ForecastingItem | `ForecastingItemId` | Item being adjusted |
| Adjusted Amount | `AdjustedAmount` | Override value |
| Territory/Role | `ForecastingTypeId` | Which forecast type |

### ForecastingQuota
**API name:** `ForecastingQuota`  
Per-user/per-period quota targets.

| Field | API Name | Notes |
|---|---|---|
| Assigned To | `AssignedToId` | User or Territory |
| Quota Amount | `QuotaAmount` | Target for the period |
| Start Date | `StartDate` | Period start |
| Product Family | `ProductFamily` | If Product Family forecast type |
| Forecast Type | `ForecastingTypeId` | Which forecast type |

---

## Territory2 (Enterprise Territory Management)

**API name:** `Territory2`  
**Purpose:** Defines a territory within a Territory Model.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Name | `Name` | String | |
| Territory Model | `Territory2ModelId` | Lookup(Territory2Model) | Parent model |
| Parent Territory | `ParentTerritory2Id` | Lookup(Territory2) | Hierarchy |
| Account Access Level | `AccountAccessLevel` | Picklist | Read, Edit |
| Opportunity Access Level | `OpportunityAccessLevel` | Picklist | Read, Edit, None |
| Case Access Level | `CaseAccessLevel` | Picklist | Read, Edit, None |
| Description | `DeveloperName` | String | Internal name |

### Territory2Model
Defines the territory hierarchy container. State: `Planning`, `Active`, `Archived`. Only one Active model at a time. Switching models requires archiving the current one.

### UserTerritory2Association
Links Users to Territory2 records. Role field (`RoleInTerritory2`) — e.g., Account Executive, Overlay Specialist.

### ObjectTerritory2Association
Links Account records to Territory2 records. `AssociationCause`: `Territory2Manual` (manual), `Territory2Rule` (rule-based), `Territory2AlignmentRule` (alignment-based).

---

## Campaign

**API name:** `Campaign`  
**Purpose:** Marketing initiative; tracks ROI through lead/contact membership.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Campaign Name | `Name` | String | Required |
| Type | `Type` | Picklist | See values below |
| Status | `Status` | Picklist | Planned, In Progress, Completed, Aborted |
| Start Date | `StartDate` | Date | |
| End Date | `EndDate` | Date | |
| Description | `Description` | TextArea | |
| Budgeted Cost | `BudgetedCost` | Currency | |
| Actual Cost | `ActualCost` | Currency | |
| Expected Revenue | `ExpectedRevenue` | Currency | |
| Expected Response (%) | `ExpectedResponse` | Percent | |
| Owner | `OwnerId` | Lookup(User) | |
| Parent Campaign | `ParentId` | Lookup(Campaign) | Campaign hierarchy |
| Is Active | `IsActive` | Boolean | |
| Num. Sent | `NumberSent` | Integer | For email campaigns |
| Number of Leads | `NumberOfLeads` | Integer | Rollup |
| Number of Converted Leads | `NumberOfConvertedLeads` | Integer | Rollup |
| Number of Contacts | `NumberOfContacts` | Integer | Rollup |
| Number of Responses | `NumberOfResponses` | Integer | Rollup: CampaignMember.HasResponded = true |
| Number of Opportunities | `NumberOfOpportunities` | Integer | Rollup |
| Number of Won Opportunities | `NumberOfWonOpportunities` | Integer | Rollup |
| Amount Won Opportunities | `AmountWonOpportunities` | Currency | Rollup |
| Amount All Opportunities | `AmountAllOpportunities` | Currency | Rollup |

### Campaign Type Picklist (Default)
`Telemarketing`, `Banner Ads`, `Email`, `Direct Mail`, `Seminar/Conference`, `Trade Show`, `Web`, `Other`

### Campaign Hierarchy Rules
- `ParentId` lookup creates a campaign hierarchy of up to **5 levels**
- All campaigns in a hierarchy must share the **same currency** (`CurrencyIsoCode`) — mixing currencies breaks budget and ROI rollup calculations
- Rollup stats (`NumberOfLeads`, `AmountWonOpportunities`, etc.) include stats from all child campaigns regardless of sharing settings — users without access to a child campaign still see its stats rolled up to the parent
- Rollup fields have up to **1 hour lag** — not real-time; do not drive operational logic from them

---

## CampaignMember

**API name:** `CampaignMember`  
**Purpose:** Junction between Campaign and Lead/Contact.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Campaign | `CampaignId` | Lookup(Campaign) | Required |
| Lead | `LeadId` | Lookup(Lead) | Either LeadId or ContactId required |
| Contact | `ContactId` | Lookup(Contact) | Either LeadId or ContactId required |
| Status | `Status` | Picklist | Sent, Opened, Clicked, Responded, etc. (customizable) |
| Has Responded | `HasResponded` | Boolean | Set to true when Status = a "responded" value |
| First Responded Date | `FirstRespondedDate` | Date | |
| Lead or Contact | `LeadOrContactId` | Polymorphic | Read-only computed |

**Notes:** CampaignMember Status values are campaign-specific — configured per campaign type. `HasResponded` is set by mapping a Status value to "responded" in Setup. Not automatically synced to Contact — separate field management required.

---

## Personal Labels (Spring '26)

Personal Labels allow individual users to tag records with private labels visible only to them.

**Object:** `PersonalLabel` (system-managed; not directly DML-accessible via Apex)

| Attribute | Value |
|---|---|
| Supported objects | Account, Cadence, Campaign, Contact, Lead, Opportunity, and enabled custom objects |
| Labels per user per object type | Up to 20 |
| Total labels per user | Up to 200 |
| Records per label | Up to 500 |
| Visibility | Private — visible only to the label owner |
| Reportable | No — personal labels are not available in standard reports |

**UI access:** "Personal Label" component on Lightning record pages (add via Lightning App Builder). Also available as a list view column action. Labels appear as colored chips on the record.

**Not the same as Topics:** Topics are public and collaborative. Personal Labels are strictly personal — not shared, not searchable by others.

---

## Key Lookup and Relationship Summary

| Child Object | Parent Object | Lookup Field | Relationship Type |
|---|---|---|---|
| Contact | Account | `AccountId` | Lookup (can be null) |
| Opportunity | Account | `AccountId` | Lookup |
| Opportunity | Campaign | `CampaignId` | Lookup (attribution) |
| OpportunityLineItem | Opportunity | `OpportunityId` | Master-Detail |
| OpportunityLineItem | PricebookEntry | `PricebookEntryId` | Lookup |
| OpportunityContactRole | Opportunity | `OpportunityId` | Master-Detail |
| OpportunityContactRole | Contact | `ContactId` | Lookup |
| Quote | Opportunity | `OpportunityId` | Lookup |
| QuoteLineItem | Quote | `QuoteId` | Master-Detail |
| QuoteLineItem | PricebookEntry | `PricebookEntryId` | Lookup |
| Contract | Account | `AccountId` | Lookup |
| Order | Account | `AccountId` | Master-Detail |
| Order | Contract | `ContractId` | Lookup |
| OrderItem | Order | `OrderId` | Master-Detail |
| CampaignMember | Campaign | `CampaignId` | Master-Detail |
| CampaignMember | Lead | `LeadId` | Lookup |
| CampaignMember | Contact | `ContactId` | Lookup |
| PricebookEntry | Product2 | `Product2Id` | Lookup |
| PricebookEntry | Pricebook2 | `Pricebook2Id` | Lookup |
| Territory2 | Territory2Model | `Territory2ModelId` | Lookup |
| UserTerritory2Association | Territory2 | `Territory2Id` | Lookup |
| UserTerritory2Association | User | `UserId` | Lookup |
