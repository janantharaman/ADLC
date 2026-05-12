---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: gotchas
last-updated: 2026-05-11
---

# Sales Cloud — Gotchas and Common Misconfigurations

---

## Lead Conversion

### Lead Convert is Irreversible
`Lead.IsConverted = true` is a permanent, one-way state change. There is no platform-supported way to unconvert a Lead. If automation converts leads incorrectly, the converted records (Account, Contact, Opportunity) must be manually deleted and the Lead remains marked as converted. Always test conversion criteria in a sandbox with realistic data before enabling in production.

### Custom Fields Are Silently Dropped on Conversion
Only standard Lead fields and custom Lead fields with explicit field mappings (Setup > Lead Fields > Map Lead Fields) carry over to Account, Contact, or Opportunity on conversion. Unmapped custom fields produce no error — the data is simply not transferred. Audit all custom Lead fields before go-live and ensure every business-critical field has a mapping.

### Duplicate Rules Can Block Lead Conversion
If Duplicate Rules on Account or Contact are set to "Block" and the conversion would create a duplicate Account or Contact, the conversion fails with `DUPLICATES_DETECTED`. This is particularly common when bulk-converting leads via Apex. Use `setBypassAccountDeduplication(true)` / `setBypassContactDeduplication(true)` on `LeadConvert` object only when the business process explicitly allows it — document the decision.

### Conversion Triggers Fire on All Three Objects
`convertLead()` fires Account triggers (insert or update), Contact triggers (insert or update), and Opportunity triggers (insert if created) in a single transaction. Any trigger that performs callouts, makes additional DML, or has tight governor limit usage must account for this compounded execution context.

### Lead Status "Closed - Converted" Cannot Be Removed
The Status picklist value that has `IsConverted = true` (default: "Closed - Converted") cannot be deleted. It can be renamed but its converted flag cannot be unset. Do not remove this value.

### Lead Conversion Adds System Fields to Contact History
When a Lead is converted, Salesforce adds two system-managed fields to the **Contact History** related list on the resulting Contact:
- `contactCreatedByLead` — indicates the Contact was created by this Lead conversion
- `contactUpdatedByLead` — indicates the Contact record was updated by this Lead conversion (when merging into existing Contact)

These are read-only audit fields. Do not map custom fields to these names — they are reserved system field names. Integration teams querying Contact History for conversion audit trails should be aware of these entries.

---

## Person Accounts

### Person Account Activation Is Irreversible
Enabling Person Accounts (`IsPersonAccount` feature) is a one-way org configuration change. Once enabled, it cannot be disabled without a complete data migration and org reconfiguration. Before enabling: assess all existing Contact data, all Apex code that assumes Contact has a separate Account, and all integrations that expect separate Account and Contact objects. Person Accounts merge Account and Contact behavior into a single record — triggers, FLS, OWD, and all integrations must handle both `IsPersonAccount = true` and `false` cases.

### Account Merge Does Not Support Person Account ↔ Business Account
Cannot merge a Person Account with a Business Account. Cannot change a Person Account back to a Business Account. Design the Account model before enabling PersonAccounts.

---

## Quote and Opportunity Sync

### Quote Sync Locks Opportunity Amount
When any Quote has `IsSyncing = true`, `Opportunity.Amount` becomes read-only in the UI and is driven entirely by `Quote.GrandTotal`. Reps frequently report "I can't edit the Amount field" — diagnose by checking `Opportunity.SyncedQuoteId`. Resolution: go to the Quote and deactivate sync, or delete the Quote.

### Only One Quote Can Sync Per Opportunity
Starting sync on Quote B automatically and silently stops sync on Quote A (for the same Opportunity). This happens without any warning or confirmation dialog. If reps maintain multiple Quotes, they may inadvertently change the Opportunity Amount by starting sync on a different Quote.

### Quote Line Item / Opportunity Line Item Sync Is One-Directional in Some Cases
When sync is active, changes to QuoteLineItems propagate to OpportunityLineItems. However, direct edits to OpportunityLineItems are blocked. After stopping sync, OLIs remain at the last synced state. If reps edit OLIs after stopping sync and then restart sync, the QLE values (not the edited OLI values) win — OLI edits are overwritten.

### CPQ Quotes and Native Quotes Cannot Coexist Well
If Salesforce CPQ (Revenue Cloud) is installed alongside native Quotes, rep confusion is common. CPQ uses `SBQQ__Quote__c` (custom object). Native Quote object should be hidden from profiles when CPQ is the quoting tool. Leaving both visible causes double-quoting, conflicting amount rollups, and incorrect Pipeline Inspection signals.

---

## Forecast Category and Stage

### New Stage Values Default to "Omitted" Forecast Category
When a new Stage picklist value is added without explicitly configuring its Forecast Category in Setup > Forecasts Settings > Stage Mappings, the default is `Omitted`. Opportunities in that Stage disappear from all forecasts silently. After every Stage picklist addition or rename, verify the Stage → Forecast Category mapping immediately.

### Renaming a Stage Value Does Not Auto-Update Existing Records
Salesforce picklist value renames propagate to existing records (unlike deleting a picklist value). However, downstream mappings (Forecast Category assignments, Stage-based Approval Process criteria, Flow decisions) reference the old picklist value text in some places. Audit all automations when renaming Stage values.

### Forecast Category Is Not Independently Editable by Default
Reps cannot change `ForecastCategoryName` directly on an Opportunity — it is derived from Stage. To allow independent Forecast Category overrides (e.g., a "Commit" override for a Stage = "Best Case" deal), enable "Allow Forecast Category Overrides" in Forecasting Settings and Surface the field on the page layout.

---

## Opportunity Splits

### Splits Require Collaborative Forecasting
Opportunity Splits cannot be enabled without first enabling Collaborative Forecasting. The dependency order: Enable Forecasting → Enable Opportunity Splits. Reversing this in metadata deploys will fail.

### Revenue Splits Must Total Exactly 100%
Revenue-type Opportunity Splits (for quota credit) must sum to exactly 100% or the platform throws a validation error. Overlay splits have no such constraint and can exceed 100% total. Distinguish the split type when creating splits via Apex.

### Split Deletion Does Not Fire Standard Triggers
`OpportunitySplit` delete does not fire a standard `after delete` trigger that many implementations rely on for downstream recalculation. Use platform events or CDC to observe split deletions in integrations.

---

## Territory Management

### Territory Management 2.0 (ETM) and Legacy Territory Cannot Coexist
Legacy Territory Management (Territory1) and Enterprise Territory Management (Territory2) cannot be simultaneously active. Orgs migrating must fully decommission Territory1 before activating Territory2. There is no migration tool — territory hierarchies must be rebuilt.

### Only One Active Territory2 Model at a Time
Only one `Territory2Model` can be in "Active" state. If you need to test a new territory structure, put the current model to "Planning" state, build the new one, then activate. Archiving a model removes all territory assignments — do not archive the active model without a tested replacement ready.

### Territory Assignment Is Not Included in Standard Metadata Deploy
`ObjectTerritory2Association` records (Account-to-Territory assignments) are data, not metadata. They cannot be deployed via change sets or Metadata API. Post-deploy data steps are required. Plan for this explicitly in every deployment checklist.

### ETM Territories Override Private OWD — May Cause Over-Sharing
When Account OWD = Private, ETM territory assignment grants access to all users in that territory for the Account and its related Opportunities. If territories are broad (e.g., "East Region" with 50 users), this effectively makes those 50 users' Opportunities visible to all territory members — which may exceed the intended sharing model. Design territory granularity before ETM activation.

---

## Standard Price Book

### Forecasting Range Is Bounded — Up to 15 Months or 8 Quarters
Collaborative Forecasting can display a maximum of:
- **15 months or fiscal periods** (past + future combined)
- **8 quarters** (past + future combined)

If a forecast type is configured for monthly periods, only 15 months of data are visible in the Forecasting tab at any time. This is often misunderstood as a data retention limit — the Opportunity data is not deleted, but the forecasting UI will not show periods outside this window. For historical reporting beyond 15 months, use reports on `ForecastingAdjustment` or Opportunity aggregations directly.

### Partner Portal User Opportunities Roll Up to Account Owner's Forecast
When a partner user owns an Opportunity and that partner user does NOT have a Forecast Manager, the Opportunity rolls up to the **Account Owner's forecast** — provided the Account Owner is the partner user's forecast manager. This means partner-owned opportunities can silently inflate internal forecast numbers if Account ownership and forecast hierarchy are not carefully designed.

---

## Standard Price Book
The Standard Price Book (`IsStandard = true`) cannot be deleted or set `IsActive = false` via the API. Attempts to do so throw an error. Every product must have a Standard Price Book entry before it can be added to any custom Price Book.

### Standard Price Book ID Varies by Org
The Standard Price Book record ID is different in every org (production, sandbox, scratch org). Do not hardcode the Standard Price Book ID in Apex or metadata. Always query it: `[SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1]`. In test methods, use `Test.getStandardPricebookId()`.

### Opportunity Pricebook Must Be Set Before Adding Products
`Opportunity.Pricebook2Id` must be set before inserting `OpportunityLineItem` records. Apex that creates an Opportunity and its OLIs in the same transaction must either use two separate DML statements (insert Opportunity, update Pricebook2Id, insert OLIs) or set `Pricebook2Id` in the initial Opportunity insert.

---

## Multi-Currency

### Exchange Rate Lag in Pipeline Reports
In multi-currency orgs, `Opportunity.Amount` is stored in the Opportunity's currency. Report rollups convert to corporate currency using the dated exchange rate at `CloseDate` (not today's rate). This causes pipeline amounts to fluctuate when rates change, even with no Opportunity edits. Stakeholders must understand this is by design.

### Advanced Currency Management (Dated Exchange Rates)
With Advanced Currency Management enabled, historical exchange rates are used for rollup. `CurrencyIsoCode` fields, formula fields referencing cross-currency amounts, and custom rollup summaries all behave differently under Advanced Currency Management vs standard multi-currency. Test all currency-related formulas and reports before enabling.

---

## Account Hierarchy

### Account Hierarchy Is Limited to 10 Levels
`ParentId` self-lookup supports parent-child relationships, but Salesforce reports and the account hierarchy UI only traverse up to 10 levels. Deep hierarchies (subsidiaries of subsidiaries) may not appear correctly in rolled-up reports.

### No Native Amount Rollup Up the Account Hierarchy
There is no standard mechanism to roll up Opportunity amounts from child Accounts to parent Accounts. Options: custom rollup field updated by Apex/Flow trigger on Opportunity, CRM Analytics report, or third-party AppExchange solution.

### Account Merge Re-Parents Child Records
Merging Accounts moves Contacts, Opportunities, Cases, and other child records to the surviving Account. OpportunityContactRoles are preserved. Account Teams are merged (duplicates removed). Review impact on territory assignments and sharing rules before bulk account merges.

---

## Campaign and Campaign Influence

### CampaignMember Status Is Not Synced to Contact Automatically
CampaignMember has its own `Status` picklist independent of Contact fields. A Contact's `Campaign.Status = 'Responded'` does not update any field on the Contact record. Build explicit automation (Flow or Apex) if you need campaign engagement signals on the Contact for segmentation.

### Campaign Influence Requires Specific Configuration
Primary Campaign Source (Opportunity.CampaignId) is simple attribution. Multi-touch Campaign Influence requires Customizable Campaign Influence to be enabled and Influence rules configured. Default Campaign Influence uses "First Touch" model. Customizable Campaign Influence allows custom attribution models but requires CRM Analytics for model analysis. The two approaches conflict if not planned before implementation.

### ROI Rollup Fields Are Approximations
Campaign rollup fields (`NumberOfLeads`, `AmountWonOpportunities`) are scheduled rollup aggregations, not real-time. **There can be a lag of up to 1 hour** before these fields reflect recent changes. Do not use them in real-time operational logic.

### Campaign Hierarchy — Single-Currency Constraint on Child Campaigns
Campaign hierarchy (via `ParentId`) supports up to **5 levels**. A critical constraint: all child campaigns in a hierarchy **must use the same currency** as the parent. Mixing currencies in a campaign hierarchy causes incorrect budget and ROI rollup values. If the org uses multi-currency, verify all campaigns in a hierarchy share the same `CurrencyIsoCode` before building rollup reports.

---

## Web-to-Lead

### 500/Day Hard Limit — Silent Drop Beyond That
Web-to-Lead processes a maximum of 500 submissions per 24-hour period. Submissions beyond 500 are silently discarded — there is no error to the submitting user. The org admin receives an email notification on the **first 5** rejected submissions only. If a campaign generates high traffic, this limit can be breached within hours. Monitor Web-to-Lead usage before large campaign launches.

### Pending Queue 50,000 Combined Cap
The Web-to-Lead + Web-to-Case combined pending queue has a 50,000-record cap. If the queue is backed up (e.g., during bulk imports or high-traffic periods), new submissions are rejected until the queue processes down. Check queue size before major campaign launches.

---

## Salesforce Maps Lite

### Maps Lite Is NOT Available in Enterprise Edition
Salesforce Maps Lite (visualize up to 50 records on a map) is included in **Performance and Unlimited** editions only. Enterprise edition customers must purchase the full Salesforce Maps add-on to get any mapping capability. This surprises implementations where the customer discovers Maps Lite in Trailhead but holds an Enterprise license.

### Maps Lite Not Available on Hyperforce EU Operating Zone
Salesforce Maps Lite is explicitly excluded from Hyperforce EU Operating Zone orgs regardless of edition. Do not include Maps Lite in designs for EU Hyperforce customers without confirming availability.

---

## Einstein Activity Capture (EAC)

### EAC Data Resides Outside Salesforce by Default
With standard EAC, email and calendar activities are stored in Amazon Web Services infrastructure (not in Salesforce), and are surfaced into Salesforce as a UI overlay only. They do not appear in standard SOQL queries against `Task` or `Event` objects. For compliance-sensitive orgs (FSI, healthcare), this is a significant data residency concern. **Einstein Activity Capture with Activity 360 Reporting** or Connected Campaigns stores activities in Salesforce — requires different license.

### EAC Activities Cannot Be Reported On via Standard Reports
Because standard EAC activities are not stored as Task/Event records, standard Activity reports do not include them. Use "Activities Report" in the EAC-specific report type, or enable Activity 360 Reporting. This surprises customers who assume all activity logging is unified.

### EAC Sync Is User-Controlled
EAC requires each user to connect their email account. Admins cannot force-connect on behalf of users. If reps opt out, their activities are not captured, creating gaps in activity data used by Einstein scoring models.

---

## Contacts and ContactRoles

### Contact Role Required for Opportunity-Contact Timeline Link
An `OpportunityContactRole` record must exist linking a Contact to an Opportunity for that Opportunity to appear in the Contact's Activity Timeline. Many implementations skip OCR creation, causing gaps in the "Opportunities" related list on Contact and in Contact-level reporting. Enforce OCR creation via a Validation Rule or Flow on Opportunity close.

### OpportunityContactRole Has No Standard Duplicate Protection
Multiple OCRs with the same ContactId + OpportunityId are allowed by the platform (there is no unique constraint). `IsPrimary` can only be true for one per Opportunity, but non-primary duplicates can accumulate. Consider a before-insert trigger to check for existing OCR before inserting.

---

## Sharing and OWD

### Private OWD + Large Role Hierarchy = Complex Sharing Audit
With Account/Opportunity OWD = Private, a rep at the bottom of a 6-level Role Hierarchy sees only their own records. Their manager sees down through the hierarchy. But Sharing Rules, Account Teams, and Territory assignments all add access back. Resulting "effective sharing" can be very difficult to audit. Use the "Access" button on individual records to troubleshoot unexplained access.

### Opportunity Sharing Does Not Automatically Follow Account Sharing
When Account OWD = Private and Opportunity OWD = Private (controlled by parent), changing Account sharing (e.g., via sharing rule) does propagate to related Opportunities. But if both are set to Private independently, Opportunity sharing is independent of Account sharing. Opportunity must have its own sharing rule or use Account Teams to give Opportunity access. This is a common misconfiguration: reps can see the Account but not its Opportunities.

### Manual Sharing is Not Preserved After Record Transfer
Manual sharing entries (`AccountShare` with RowCause = `Manual`) are deleted when Account ownership changes. If manual sharing is used as a core access mechanism (rather than Account Teams or Sharing Rules), transfers invalidate it silently. Use Account Teams for durable access grants.

---

## Record Type and Page Layout

### Record Type Assignment Requires Profile or Permission Set
Record Types are assigned to profiles and permission sets. If a user's profile does not include a Record Type, they cannot create records with that type and cannot see it in picklists. In permission-set-based orgs (no profile Record Type assignment), Record Types must be enabled on permission sets. Missing Record Type assignments are a common cause of "I can't see that pipeline stage" reports.

### Business Process Must Exist Before Record Type
`BusinessProcess` metadata (for Opportunity and Lead — defines which Stage/Status picklist values are active) must be deployed before `RecordType` metadata that references it. Deploying in wrong order fails silently or throws dependency errors. Package.xml ordering is critical.

### Changing Stage Picklist Values on a Business Process Affects All Associated Record Types
Business Processes filter which Stage values are available. If you add a new Stage to a Business Process used by multiple Record Types, it appears for all of them. To restrict a Stage to one Record Type, create a separate Business Process for that Record Type.
