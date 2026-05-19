---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: overview
last-updated: 2026-05-11
---

# Sales Cloud — Overview

## What Sales Cloud Is

Sales Cloud is Salesforce's core CRM platform for managing the complete revenue cycle: lead generation, account and contact management, opportunity pipeline, quoting, forecasting, and territory assignment. It is the foundational Salesforce cloud — the majority of Salesforce orgs are provisioned with Sales Cloud objects and licenses by default, regardless of which other clouds they purchase.

Sales Cloud sits at the center of the Salesforce Customer 360 architecture. Account, Contact, Activity, and Task objects are shared across Sales Cloud and Service Cloud. Opportunity data is the primary integration surface for CPQ/Revenue Cloud, Marketing Cloud, and financial systems.

---

## Edition Breakdown

| Edition | Key Capabilities | Target Segment |
|---|---|---|
| **Essentials** | Accounts, Contacts, Leads, Opportunities, basic reports, Chatter, mobile | SMB, up to 10 users |
| **Professional** | All Essentials + Collaborative Forecasting, Campaign management, custom profiles, API (read-only) | Growing SMB |
| **Enterprise** | All Professional + full API access, Territory Management 2.0, advanced automation (Flow), custom permission sets, custom apps | Mid-market and Enterprise |
| **Unlimited** | All Enterprise + Premier Success, additional sandbox types, full sandbox, more storage | Large enterprise |
| **Einstein 1 Sales** (formerly Unlimited+) | All Unlimited + Einstein Copilot for Sales, Revenue Intelligence, Sales Engagement, Einstein Conversation Insights, Data Cloud | Enterprise with AI/analytics needs |

**Edition-gating notes:**
- Collaborative Forecasting: Professional and above
- Enterprise Territory Management (ETM): Enterprise and above
- Opportunity Splits: Enterprise and above (requires Collaborative Forecasting)
- Sales Engagement (formerly HVS): add-on license on Enterprise/Unlimited; included in Einstein 1
- Pipeline Inspection: Enterprise and above
- Revenue Intelligence: add-on (CRM Analytics license required); included in Einstein 1
- Einstein Lead/Opportunity Scoring: Requires Sales Cloud Einstein license or Einstein 1 (basic Opportunity Scoring via "Sales Cloud Einstein For Everyone" perm set at no extra cost)
- Salesforce Maps Lite: Performance and Unlimited editions only; NOT available in Enterprise; NOT available for Hyperforce EU Operating Zone
- Personal Labels: all editions (Spring '26)

---

## Core Modules

### Leads
Unqualified prospects not yet associated to an Account or Contact. Leads have their own object with a dedicated conversion workflow that creates Account + Contact + optionally Opportunity. Lead source tracking and campaign influence begin here.

### Accounts
Companies (B2B) or individuals (B2C via Person Accounts). Accounts are the anchor record for the entire Sales Cloud data model. Account hierarchy (ParentId) supports enterprise account structures. Account Teams enable multi-user ownership.

### Contacts
Individual people at Accounts. Standard model is one Account per Contact. Contacts to Multiple Accounts (AccountContactRelation object) allows a Contact to be related to multiple Accounts — useful for board members, consultants, or shared contacts.

### Opportunities
Active sales deals with a Stage, Close Date, and Amount. The Opportunity is the primary forecasting and pipeline management unit. Products/Price Books, Quotes, Opportunity Teams, and Opportunity Splits all attach to the Opportunity.

### Products and Price Books
Product2 is the product catalog. Pricebook2 holds price lists (Standard Price Book + custom price books for regions, channels, or customer tiers). PricebookEntry links a Product to a Price Book with a unit price. Opportunities reference a Price Book; Opportunity Line Items reference Price Book Entries.

### Quotes (Native)
Formal pricing documents generated from Opportunities. Native Quotes use Quote Line Items and support PDF generation via Quote Templates. One Quote can sync to its parent Opportunity at a time, keeping prices in sync. For complex CPQ needs, Salesforce CPQ (Revenue Cloud) is a separate product.

### Collaborative Forecasting
Manager-driven revenue prediction tool. Rolls up Opportunity amounts through Role Hierarchy or Territory Hierarchy. Supports multiple Forecast Types (Revenue, Quantity, Product Family, Overlay). Managers can adjust subordinates' forecasts. Quota tracking via ForecastingQuota object.

### Enterprise Territory Management (ETM)
Many-to-many assignment of Accounts (and their Opportunities) to Territories. Supports territory hierarchies independent of Role Hierarchy. Overlapping territories support overlay specialists. Territory-based Forecast Type can replace role-based forecasting.

### Einstein / AI Features

Full feature-to-license mapping (Spring '26):

| Feature | License Required | Notes |
|---|---|---|
| Einstein Lead Scoring | Sales Cloud Einstein or Agentforce for Sales | Needs 1,000+ leads, 120+ converted in last 2 years |
| Einstein Opportunity Scoring | Sales Cloud Einstein or Agentforce for Sales | Available at no extra cost via "Sales Cloud Einstein For Everyone" perm set for basic scoring |
| Einstein Opportunity Insights | Sales Cloud Einstein | Included with Opportunity Scoring; follow-up reminders, deal health, competitor alerts |
| Einstein Activity Capture (Standard) | Einstein Activity Capture (EAC Standard) — **free up to 100 users** | Activity data stored outside Salesforce (AWS); not in SOQL |
| Einstein Activity Capture (Activity 360) | EAC with Activity 360 Reporting add-on | Activities stored in Salesforce; reportable via standard reports |
| Einstein Conversation Insights | Sales Cloud Einstein or Conversation Insights add-on | Requires telephony CTI integration |
| Sales Summaries (copilot action) | Agentforce for Sales or Einstein 1 Sales | Summarise call, email thread, or opportunity |
| Close Plans | Agentforce for Sales or Einstein 1 Sales | AI-generated close plan for an opportunity |
| Find Similar Deals | Agentforce for Sales | Find historical won/lost deals matching current opp |
| Auto-generate Call Summary | Agentforce for Sales | Post-call summary from Conversation Insights transcript |
| Research Account | Agentforce for Sales | Generate account summary from public + CRM data |
| Draft Sales Email | Agentforce for Sales or Einstein 1 Sales | Contextual email draft from opportunity/contact data |
| Pipeline Analysis | Agentforce for Sales | AI analysis of pipeline health and forecast gaps |
| Coaching Insights | Sales Cloud Einstein | Manager-facing coaching signals from activity data |
| Einstein Copilot for Sales (general) | Einstein 1 Sales | Generative AI assistant embedded in Lightning |
| Agentforce SDR Agent | Agentforce for Sales | Autonomous outbound lead nurture and qualification (Winter '26 GA) |
| Revenue Intelligence Dashboards | CRM Analytics (Einstein Analytics) license | Included in Einstein 1 Sales |

**Einstein Activity Capture licensing note:** EAC Standard is free for up to 100 active users. Above 100 users requires a paid EAC license. The free tier does NOT include Activity 360 Reporting (activities stored outside Salesforce).

### Seller Home
The default homepage for the Sales, Sales Console, and Sales Engagement apps (Spring '26). Replaces the generic "Home" tab for sales personas.

Components shown on Seller Home:
- **Pipeline overview**: open opportunity amounts by Forecast Category
- **Goals**: quota attainment progress (if quotas configured)
- **Today's Events**: calendar events for the current day
- **Contact suggestions**: Einstein-suggested contacts to reconnect with
- **Recent Opportunities**: rep's recently viewed/active deals

Seller Home is configurable per App via the Lightning App Builder. Standard home page layout rules (profiles/permissions) apply. No custom code required.

### Personal Labels (Spring '26)
New feature allowing individual users to tag records with personal labels visible only to them.

- **Supported objects:** Account, Cadence, Campaign, Contact, Lead, Opportunity, and any custom object enabled for labels
- **Limits:** Up to 20 personal labels per user per object type; 200 total labels per user; each label can tag up to 500 records
- **Visibility:** Labels are private — not visible to other users, not reportable org-wide
- **Access:** "Personal Label" component on record pages; also available via list view actions
- **Not the same as Topics:** Topics are collaborative/public; Personal Labels are strictly personal

### Sales Engagement (formerly High Velocity Sales)
Structured cadence-based outreach for SDRs and BDRs. Work Queue aggregates tasks (calls, emails, LinkedIn steps) into a prioritized action list. Cadences define multi-step outreach sequences with branching logic. Engagement data feeds Einstein scoring.

### Pipeline Inspection
Consolidated pipeline view showing Opportunity changes, deal health scores, AI insights, and week-over-week movement. Requires Enterprise+ and Collaborative Forecasting enabled.

### Revenue Intelligence
CRM Analytics-powered dashboards and AI for pipeline analytics, forecast analysis, activity analysis, and coaching. Requires CRM Analytics (Einstein Analytics) license. Data pipeline syncs Sales Cloud data into CRM Analytics datasets. Includes pre-built Revenue Intelligence app.

### WDC (Work.com Motivate) — Deprecated
WDC features (Goals, Coaching, Feedback, Performance Summaries, Rewards, Recognition) are **not available to new customers as of Spring '22**. Existing customers retain access to: Badges, Skills, and Thanks only. All other WDC modules (Goals, Coaching, Feedback, Performance, Rewards) have been removed. Do not include WDC in designs for new implementations.

### Salesforce Maps Lite
Included (no extra license) in **Performance** and **Unlimited** editions only.
- Visualize up to **50 records** on a map from any list view
- NOT available in Enterprise edition
- NOT available for Hyperforce EU Operating Zone
- Full Salesforce Maps (paid add-on) is required for route planning, territory mapping, and >50 record visualization

---

## B2B vs B2C Sales Patterns

| Dimension | B2B Pattern | B2C Pattern |
|---|---|---|
| Account model | Business Account | Person Account (requires org enablement — irreversible) |
| Deal structure | Opportunity with multiple contacts (OpportunityContactRole) | Single consumer contact, simpler opportunity |
| Forecasting | Role/Territory hierarchy, manager adjustments | Less common; often volume-based |
| Territory model | Geographic + named account + overlay | Geographic or product-based |
| Campaign attribution | Multi-touch via Campaign Influence | Single-touch CampaignSource typically sufficient |
| Quoting | Native Quote or CPQ depending on complexity | CPQ less common; often direct pricing |
| Partner channel | Experience Cloud partner portal, PartnerAccount on Opportunity | Rare |

---

## Key Personas

| Persona | Primary Objects | Key Capabilities Needed |
|---|---|---|
| **Sales Rep (AE)** | Lead, Account, Contact, Opportunity, Quote, Activity | Create/edit Opp, add products, generate quote, log activity, view own forecast |
| **SDR / BDR** | Lead, Contact, Activity, Cadence | Work Queue access, cadence management, Lead convert, email tracking |
| **Sales Manager** | Opportunity (team), Forecast, Coaching | View team pipeline, adjust forecasts, override approvals, Pipeline Inspection |
| **VP of Sales** | Forecast (org-wide), Revenue Intelligence, Quota | Org-wide pipeline view, revenue intelligence dashboards, quota setting |
| **Sales Ops / RevOps** | All objects, Assignment Rules, Pricebook, Territory | Admin-level configuration, data quality, territory maintenance, product catalog |
| **Systems Admin** | Metadata, Profiles, Permission Sets, Flows | Configuration management, deployment, integration maintenance |

---

## Integration Touchpoints

### CPQ / Revenue Cloud (Salesforce CPQ)
CPQ extends native Sales Cloud quoting with: product configuration rules, pricing rules, discounting approval workflow, contract lifecycle, amendment and renewal. When CPQ is present, native Quote object is typically disabled. CPQ Quote (`SBQQ__Quote__c`) replaces it. Opportunity Amount is driven by CPQ quote totals.

### Service Cloud
Shares Account, Contact, Activity objects. Case object is Service-specific but related to Account. OWD on Account and Contact must be designed to satisfy both Sales (private pipeline) and Service (broader case access). Entitlement and SLA features are Service-only.

### Experience Cloud (Partner Portal)
Channel/partner sales via PRM (Partner Relationship Management). Partners access Opportunities, Leads, and shared content through an Experience Cloud site. PartnerAccount field on Opportunity, Channel Manager role, and Partner User licenses. Deal registration flow is a common PRM pattern.

### Marketing Cloud / Account Engagement (Pardot)
Lead handoff from marketing automation to Sales Cloud. Connected Campaigns align Marketing Cloud/Pardot campaigns to Salesforce Campaign objects. Lead/Contact sync, prospect scoring alignment with Einstein Lead Scoring, and campaign influence attribution.

### ERP / Financial Systems
Opportunity-to-Order handoff for revenue recognition. Order and Contract objects in Sales Cloud serve as the bridge. Common integration points: SAP, Oracle ERP, NetSuite. Triggered by Opportunity Closed Won or Contract activation.

### Data Cloud
Unified customer profile augments Sales Cloud records with behavioral and identity data. Einstein AI models in Sales Cloud can be enhanced with Data Cloud signals. Requires Data Cloud license.

---

## API Version Notes

- **Current API version (Spring '26):** v67.0
- Sales Cloud core objects (Lead, Account, Contact, Opportunity) available since API v1.0
- Collaborative Forecasting objects (Forecasting3): API v26.0+
- Territory2 (ETM): API v30.0+
- OpportunityContactRole, OpportunitySplit: v26.0+
- Sales Engagement (Work Queue, Cadence): accessible via standard API; Cadence step objects via v50.0+
- Quote and QuoteLineItem: v18.0+
- Pipeline Inspection: UI feature; no dedicated API object — surfaces via standard Opportunity fields
- Agentforce SDR Agent: configured via Agent Builder; Agent API v1 (Winter '26)
