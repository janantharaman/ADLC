---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Sales Cloud — Implementation Guide

---

## Pre-Engagement Checklist

Before beginning design or implementation, verify the following with the customer:

### Licensing
- [ ] Confirm Sales Cloud edition (Essentials / Professional / Enterprise / Unlimited / Einstein 1)
- [ ] Confirm number of Sales Cloud licenses and license types (Salesforce, Sales Professional, etc.)
- [ ] Confirm add-on licenses: Sales Cloud Einstein, Sales Engagement (HVS), Revenue Intelligence, CPQ/Revenue Cloud, Experience Cloud (for Partner Portal)
- [ ] Confirm multi-currency requirement (Advanced Currency Management is irreversible once enabled)
- [ ] Confirm Person Account requirement (irreversible once enabled)

### Enabled Features (query or check Setup)
- [ ] Is Collaborative Forecasting enabled?
- [ ] Is Enterprise Territory Management (ETM) enabled? Which version: Territory1 (legacy) or Territory2?
- [ ] Are Opportunity Splits enabled?
- [ ] Is Contacts to Multiple Accounts enabled?
- [ ] Is Account Teams enabled?
- [ ] Is Einstein Activity Capture enabled? Which tier? (Standard free ≤100 users; Activity 360 for Salesforce-stored activities)
- [ ] Is Pipeline Inspection enabled?
- [ ] Is Sales Engagement (Work Queue / Cadences) enabled?
- [ ] Is Revenue Intelligence/CRM Analytics licensed and configured?
- [ ] Is CPQ installed? (Check for `SBQQ__` namespace in Setup > Installed Packages)
- [ ] Is Salesforce Maps or Maps Lite available? (Maps Lite: Performance/Unlimited only; NOT Enterprise)
- [ ] Are WDC features in scope? (Note: WDC not available to new customers since Spring '22 — Goals, Coaching, Feedback, Performance, Rewards removed; Badges/Skills/Thanks only remain)

### Org Health
- [ ] What is the current API version used by existing integrations?
- [ ] Are Duplicate Rules currently blocking or allowing?
- [ ] What is the current OWD for Account, Contact, Lead, Opportunity?
- [ ] Are there existing Validation Rules that may conflict with import or automation?
- [ ] How many active Flows are on Opportunity? (High count = performance risk)
- [ ] What is the largest object data volume? (Accounts, Opportunities, Leads)

---

## Sales Process Setup Sequence

This sequence avoids dependency failures. Follow it for new implementations:

```
1. Define Business Process (Opportunity stages, Lead statuses)
2. Configure Stage picklist values (Opportunity StageName)
   → Map each Stage to Forecast Category + Probability immediately
3. Configure Lead Status picklist values
4. Create Record Types (reference the Business Processes from step 1-3)
5. Create Page Layouts and assign to Record Types
6. Configure Profiles and Permission Sets (assign Record Types)
7. Configure Assignment Rules (Lead Assignment, Case Assignment)
8. Configure Auto-Response Rules and Escalation Rules (Lead)
9. Configure Approval Processes (discount approval, deal approval)
10. Configure Validation Rules
11. Configure Flows (stage transitions, team assignment, notifications)
12. Configure Reports and Dashboards
```

**Deployment dependency:** BusinessProcess → RecordType → PageLayout. Deploy in this order.

---

## Lead Management Setup

### Web-to-Lead
1. Setup > Web-to-Lead > Generate Web-to-Lead HTML
2. Select fields to capture (First Name, Last Name, Email, Company, Lead Source at minimum)
3. Specify Return URL (thank-you page)
4. Embed HTML form in marketing landing page
5. Add `<input type="hidden" name="debug" value="1">` to the form for sandbox testing — returns a debug page instead of the return URL, showing field mapping and errors
6. Enable reCAPTCHA (Setup > Web-to-Lead > Enable reCAPTCHA) to prevent spam
7. Test with sandbox org before going live

**Hard limits (confirmed, Spring '26):**
- **500 submissions per 24-hour period** — submissions beyond this are discarded; admin receives notification email on the first 5 rejected submissions
- **Pending queue: 50,000 combined** (Web-to-Lead + Web-to-Case) — if the queue is backed up beyond 50,000 unprocessed records, new submissions are rejected until the queue clears
- These limits are per-org; contact Salesforce Support to discuss increases for high-volume use cases

**Design note:** For campaigns expected to exceed 500 leads/day (e.g., large paid media campaigns), route submissions through Marketing Cloud/Account Engagement or a middleware layer that batches submissions instead of going directly through Web-to-Lead.

### Assignment Rules
1. Setup > Lead Assignment Rules > New
2. Create rule entries in priority order (rule entries evaluated top-to-bottom; first match wins)
3. Criteria: use indexed fields where possible (OwnerId, Status, LeadSource)
4. Assign to User or Queue (Queue preferred for shared ownership; User for dedicated territories)
5. Check "Notify Assignee" to send email on assignment
6. Activate the rule (only one rule active at a time)

**Round-robin:** Not native. Options: (1) Apex trigger with a custom counter, (2) AppExchange package (e.g., LeanData, RingLead), (3) Flow with a custom round-robin counter object.

### Auto-Response Rules
1. Setup > Lead Auto-Response Rules
2. Create rule entries with email template selection per criteria
3. Use branded HTML templates; include opt-out link for compliance
4. Activate the rule

### Lead Conversion Field Mapping
1. Setup > Object Manager > Lead > Fields & Relationships > Map Lead Fields
2. For each Lead field, specify the Account/Contact/Opportunity field it maps to on convert
3. Map all custom fields that must carry over
4. Verify mapping after every new custom Lead field addition

### Duplicate Management for Leads
1. Setup > Matching Rules > New (or use standard "Standard Lead Matching Rule")
2. Matching criteria: Email exact match OR (FirstName + LastName + Company, fuzzy)
3. Setup > Duplicate Rules > New
4. Reference the matching rule; set action (Alert or Block)
5. Enable for internal user entry; consider Block for API/Web-to-Lead sources

---

## Product Catalog Setup

### Setup Sequence for Product Catalog

```
1. Define Product Families (picklist on Product2.Family)
2. Create Product records (Product2)
   → Set IsActive = true for live products
   → Set ProductCode (must be unique if used as external key)
3. Create Standard Price Book entries (PricebookEntry with IsStandard PB)
   → Every product needs a Standard PBE before it can go in custom PBs
4. Create custom Price Books (Pricebook2)
   → e.g., "Enterprise Price Book", "Partner Price Book", "USD Public Sector"
5. Create custom Price Book entries (PricebookEntry with custom PB)
   → UseStandardPrice = true if same as Standard; false if different
6. Assign Price Book to Opportunities (manually or via Flow/Apex)
```

### ERP Sync Pattern for Product Catalog
- Use External ID field on Product2 (e.g., `ERP_SKU__c` with External ID = true)
- Bulk upsert via Bulk API 2.0 using ERP SKU as the external key
- Sync runs nightly; deactivate products (`IsActive = false`) rather than deleting
- Custom Price Book entries for specific channels/regions managed separately from ERP

---

## Quoting Setup (Native)

### Quote Template Setup
1. Setup > Quotes > Quote Templates > New
2. Design quote PDF layout using quote template editor
3. Add company header, line item table, totals, signature block
4. Set as default template for standard quoting

### Quote Settings
1. Setup > Quotes > Enable Quotes (must be enabled first)
2. Configure Quote PDF settings (page orientation, number of decimal places)
3. Add Quote related list to Opportunity page layout

### Quote Sync Rules
- Quote sync must be started manually by the rep (click "Start Sync" on Quote)
- Only one Quote can be syncing per Opportunity
- Educate reps: stopping sync does NOT revert Opportunity amount; it stays at last synced value

### CPQ vs Native Quote Decision
| Criteria | Use Native Quote | Use CPQ |
|---|---|---|
| Simple product catalog (<50 products) | Yes | Overkill |
| Complex configuration rules (bundles, constraints) | No | Yes |
| Multi-tier approvals with discounting | Possibly | Preferred |
| Contract lifecycle management (amendments, renewals) | No | Yes |
| Subscription billing | No | Revenue Cloud |
| Multi-currency advanced pricing | Possible | Preferred |

---

## Forecasting Setup

### Enable Collaborative Forecasting
1. Setup > Forecasts Settings > Enable Forecasting
2. Select forecast hierarchy: **Role Hierarchy** (default) or **Territory Hierarchy** (requires ETM)
   - Territory-based forecasting requires a separate Forecast Type configured with Territory2
3. Select forecast measure: **Revenue** (Amount), **Quantity**, or both
4. Enable **Forecast Categories** display
5. Configure visible forecast period range (e.g., 3 months, 6 months, 1 year)

### Define Forecast Types
1. Setup > Forecasts Settings > Forecast Types
2. Standard: "Opportunity Revenue" (StageName → ForecastCategoryName → Amount)
3. Optional: "Opportunity Quantity", "Product Family Revenue", "Overlay Revenue"
4. Max 4 active Forecast Types per org

### Set Quotas
1. Via UI: Forecasts tab > Set Quota (one user at a time)
2. Via Bulk API: Upload ForecastingQuota records with Bulk API 2.0 (for large sales teams)
3. Required fields: `AssignedToId`, `StartDate`, `QuotaAmount`, `ForecastingTypeId`
4. Quotas are period-based (monthly or quarterly depending on settings)

### Configure Forecast Adjustments
1. Setup > Forecasts Settings > Enable Manager Adjustments
2. Enable Forecast Adjustments to allow managers to override subordinate forecasts
3. Adjustments recorded in `ForecastingAdjustment` object

### Verify Stage → Forecast Category Mapping
After every Stage picklist change, verify:
1. Setup > Forecasts Settings > Stage Mapping
2. Confirm every Stage value maps to one of: Omitted, Pipeline, Best Case, Commit, Closed

---

## Territory Management 2.0 Setup

### Prerequisites
- Enterprise edition or above
- Enable Enterprise Territory Management in Setup > Territory Management

### Setup Sequence

```
1. Enable Enterprise Territory Management (Setup > Territory Management > Enable)
2. Create Territory2Model (Setup > Territory Management > New Model)
   → Status: Planning (do not activate until fully built)
3. Create Territory2 records (territory hierarchy nodes)
   → Define AccountAccessLevel and OpportunityAccessLevel for each territory
4. Create Territory Assignment Rules (for each Territory2)
   → Criteria: BillingState = 'CA', Industry = 'Healthcare', etc.
5. Add Users to Territories (UserTerritory2Association)
   → Assign role in territory (e.g., Account Executive, Sales Engineer)
6. Preview territory assignments: Territory2Model > Preview Assignments
7. Run territory assignment rules: Territory2Model > Run Assignment Rules
8. Review assignment coverage and adjust rules
9. Activate Territory2Model (one active model at a time)
10. Activate Forecasting by Territory (if using territory-based forecasting)
```

**Post-activation data step:** ObjectTerritory2Association records are data — must be loaded separately from metadata deploy. Plan a post-deploy data load script.

### Territory vs Role Hierarchy Decision

| Use Role Hierarchy | Use Territory Hierarchy |
|---|---|
| Simple org structure, one rep per account | Complex overlay coverage models |
| Single-level geographic coverage | Overlapping territories (geo + industry + overlay) |
| No territory-based forecasting needed | Territory-based quota and forecasting required |
| Small sales team (<50 reps) | Large, complex enterprise sales motion |

---

## Sales Engagement (High Velocity Sales) Enablement

### Prerequisites
- Sales Engagement license (add-on on Enterprise/Unlimited; included in Einstein 1)
- Einstein Activity Capture must be enabled

### Setup Sequence
1. Setup > Sales Engagement > Enable Sales Engagement
2. Assign permission sets: `High Velocity Sales User` to all Sales Engagement users
3. Configure Cadence Builder: Setup > Sales Engagement > Cadences
4. Create email templates for cadence steps (Lightning Email Templates)
5. Connect telephony (optional): Setup > High Velocity Sales > Connect Telephony
6. Configure Work Queue filters and sort order
7. Train reps on Work Queue usage

### Key Configuration Options
- **Cadence auto-enroll rules**: Automatically enroll Leads/Contacts meeting criteria into a cadence (Flow or Apex trigger on Lead creation)
- **Step branching**: Branch cadence path based on email open/click signals
- **Reporting**: Sales Engagement reports available in standard report types

---

## Seller Home Setup

Seller Home is the default homepage for the Sales, Sales Console, and Sales Engagement apps (Spring '26). Configure it before go-live to give reps a useful starting screen.

```
1. Setup > Lightning App Builder > New > Home Page
2. Assign to App: Sales (or Sales Console / Sales Engagement)
3. Add components to the canvas:
   - Pipeline Overview (reads open Opps by ForecastCategory — no extra config)
   - Goals (requires Collaborative Forecasting + quotas loaded)
   - Today's Events (reads Salesforce calendar or EAC-synced calendar)
   - Einstein Contact Suggestions (requires EAC enabled)
   - Recent Opportunities
4. Activate and assign to profiles/apps
```

**Note:** No custom LWC required. All Seller Home components are standard. Each observes sharing rules — reps see only their own pipeline data.

---

## Salesforce Maps Lite Setup

Available in **Performance and Unlimited** editions only. NOT available in Enterprise. NOT available in Hyperforce EU Operating Zone.

```
1. No installation required — Maps Lite is included in the platform
2. Enable: Setup > Maps Settings > Enable Salesforce Maps Lite
3. Add "Map" button to Opportunity, Account, or Contact list views via List View Actions
4. Users can visualize up to 50 records at a time from any list view
```

**If customer is on Enterprise edition or EU Hyperforce:** Recommend full Salesforce Maps (paid add-on) for any mapping requirement.

---

## Einstein Features Enablement Order

**License requirements vary by feature — check the Einstein feature/license table in overview.md before configuring.**

```
1. Enable Einstein Activity Capture (EAC)
   → Setup > Einstein Activity Capture > Settings
   → Connect admin's email first; then roll out to users
   → Standard EAC (free ≤100 users): activity data stored outside Salesforce (not in SOQL)
   → Activity 360 Reporting (paid add-on): activities stored in Salesforce; reportable
   → EAC is required for Seller Home's Einstein Contact Suggestions and Sales Engagement

2. Enable Einstein Lead Scoring
   → Setup > Einstein Lead Scoring > Enable
   → Requires: 1,000+ leads, 120+ converted in last 2 years
   → Model trains automatically (24-48 hours initially)
   → Add Lead Score field and Scoring Factors to Lead page layout

3. Enable Einstein Opportunity Scoring
   → Setup > Einstein Opportunity Scoring > Enable
   → Requires: 200+ closed opportunities in last 2 years
   → Basic tier: "Sales Cloud Einstein For Everyone" permission set (no extra cost)
   → Full tier: Sales Cloud Einstein license
   → Add Opportunity Score and Scoring Reasons to Opportunity page layout

4. Enable Einstein Opportunity Insights
   → Included with Opportunity Scoring
   → Insights appear as notifications on Opportunity record

5. Enable Conversation Insights (if telephony integrated)
   → Setup > Einstein Conversation Insights > Enable
   → Requires telephony CTI integration
   → Requires Sales Cloud Einstein or Conversation Insights add-on license

6. Enable Agentforce for Sales / Einstein Copilot for Sales
   → Agentforce for Sales: Setup > Agentforce > Sales Actions
   → Einstein 1 Sales: Setup > Einstein Copilot > Enable
   → Configure trusted data sources (grounding) and permissions
   → Actions include: Sales Summaries, Close Plans, Draft Sales Email, Research Account
```

**WDC (Work.com) note:** WDC Goals, Coaching, Feedback, Performance Summaries, and Rewards are **not available to new customers** as of Spring '22. Do not include these features in designs for new implementations. Existing customers retain Badges, Skills, and Thanks only.

---

## Pipeline Inspection Configuration

### Prerequisites
- Enterprise edition or above
- Collaborative Forecasting must be enabled

### Setup
1. Setup > Pipeline Inspection > Enable Pipeline Inspection
2. Configure change tracking fields: StageName, Amount, CloseDate, ForecastCategoryName (at minimum)
3. Configure AI insights display (requires Einstein Opportunity Scoring for full signals)
4. Add Pipeline Inspection to Opportunity list view (Setup > Pipeline Inspection > Add to List View)
5. Assign Pipeline Inspection permission to relevant users (Sales Managers and VPs)

---

## Integration Patterns

### ERP Product Sync
**Pattern:** Nightly scheduled integration (MuleSoft, Boomi, or custom middleware)

```
ERP Product Record
    → Transform to Product2 + PricebookEntry format
    → Bulk API 2.0 upsert using ERP SKU as External ID
    → Handle errors: log to custom Error__c object; alert integration admin
    → Post-sync: deactivate orphaned products (in Salesforce but not in ERP)
```

### Billing System Opportunity-to-Order Handoff
**Trigger:** Opportunity Stage = "Closed Won" (CDC event or Platform Event)

```
1. Create Contract from Opportunity (Apex or Flow)
2. Create Order from Contract (Apex or Flow)
3. Publish Platform Event: New_Order__e with Order details
4. Billing system subscribes to New_Order__e via CometD/EMP API
5. Billing system creates invoice/subscription; responds with Billing_ID
6. Salesforce updates Order.Billing_Reference__c with Billing_ID
```

### Marketing Automation (Pardot / Marketing Cloud Account Engagement) Lead Handoff
**Pattern:** Connected Campaigns + Lead/Contact sync

```
Pardot Prospect (score >= threshold)
    → Pardot-Salesforce sync creates Lead record
    → Lead source = 'Marketing Qualified Lead'
    → Assignment Rule: route to SDR queue based on Industry/Geography
    → SDR reviews → converts or nurtures
    → Converted Contact stays synced to Pardot for continued marketing
```

### Experience Cloud Partner Portal (PRM)
**Pattern:** Channel deal registration

```
Partner logs into Experience Cloud site
    → Creates Deal Registration (custom object or standard Opportunity with Is_Partner_Deal__c)
    → Flow: notify Channel Manager; assign to partner account team
    → Channel Manager approves → Opportunity created in main org
    → Partner tracks status in portal (read-only Opportunity via sharing)
```

---

## Performance Considerations

### Large Opportunity Volumes (1M+ records)
- Use indexed fields in SOQL WHERE clauses: `OwnerId`, `AccountId`, `CloseDate`, `StageName`, `IsClosed`
- Avoid formula fields in SOQL (non-indexable)
- Pre-aggregate pipeline summaries in scheduled Apex or CRM Analytics instead of on-demand report queries
- Set record limits on list views (default 50 rows; cap custom list views at 2000)

### Forecast Rollup at Scale
- Collaborative Forecasting rollups are asynchronous — not real-time
- For real-time pipeline visibility: use Pipeline Inspection or CRM Analytics
- Avoid triggering forecast recalculations from Apex triggers — use scheduled jobs

### Territory Rule Evaluation at Scale
- Territory Assignment Rules re-evaluate when referenced Account fields change
- For orgs with 100k+ Accounts, rule evaluation can take hours
- Run rules off-hours (nightly batch)
- Limit rule criteria to indexed Account fields (BillingState, BillingCountry, Type, Industry)

### Flow Performance on Opportunity
- Every additional Record-Triggered Flow on Opportunity adds execution time
- Review: Setup > Process Automation Settings > Record-Triggered Flows
- Consolidate multiple Flows into one Flow with multiple decision branches where possible
- Flows that do SOQL inside loops are a common performance issue — bulk-collect IDs outside loops

---

## Discovery Questions for Sales Cloud Engagements

Use these during the Discovery phase with the customer's Sales Ops, VP Sales, and IT lead:

**Sales Process**
1. How many distinct sales processes do you have? (e.g., SMB, Enterprise, Renewal, Partner)
2. What are your Opportunity Stage names and what are the entry/exit criteria for each?
3. What fields must be populated at each stage (stage gate requirements)?
4. How do you handle late-stage changes to deal scope or amount?
5. Do you use formal quoting? Native Salesforce Quotes or CPQ?

**Lead Management**
6. Where do leads come from? (Web form, event, purchased list, marketing automation, partner)
7. How are leads currently routed to reps? (Geography, industry, account size, round-robin)
8. What is your lead disqualification/nurture process?
9. Do you have a separate SDR/BDR team? Do they need Sales Engagement / cadences?
10. How long does a lead typically live before conversion or disqualification?

**Forecasting**
11. Do you forecast by revenue, quantity, or both?
12. Is your forecast hierarchy role-based or territory-based?
13. Do managers adjust subordinate forecasts today?
14. Do you need product-family level forecasting?
15. What is your forecasting cadence (weekly, monthly, quarterly)?
16. Do you set quotas in Salesforce? How are quotas loaded?

**Territory**
17. Do you have overlapping territories (e.g., geographic rep + industry overlay specialist)?
18. How often does your territory model change?
19. Do you need territory-based forecasting (separate from role hierarchy)?
20. How do you handle accounts that span territories?

**Products and Pricing**
21. How many active products/SKUs are in your catalog?
22. Do you have multiple price books (by region, channel, customer segment)?
23. Where is the product catalog mastered? (ERP, Salesforce, spreadsheet)
24. Do you need complex product configuration rules? (Bundles, constraints, dependencies)

**Integrations and Data**
25. What systems does Salesforce need to integrate with? (ERP, billing, marketing automation, telephony, data enrichment)
26. What is the data migration scope? (Accounts, Contacts, Opportunities, history — how many years?)
27. Are there compliance requirements affecting data storage? (PII, GDPR, HIPAA)
28. Does your sales team work in mobile? What mobile-specific features are needed?
