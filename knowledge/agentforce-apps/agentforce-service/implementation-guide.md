---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); service_presence_administrators.pdf (124p); salesforce_entitlements_implementation_guide.pdf (50p); omnichannel_supervisor.pdf (32p); chat_administrator.pdf (34p); api_cti.pdf (122p); voice_performance_metrics_guide.pdf (7p); embedded_services.pdf (42p); lightning_knowledge_guide.pdf (91p); sos_administrators.pdf (12p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Service Cloud — Implementation Guide

---

## Pre-Engagement Checklist

### License Verification

Before scoping any Service Cloud engagement, confirm in production org (or customer-provided license list):

- [ ] Service Cloud edition (Professional / Enterprise / Unlimited)
- [ ] Number of Service Cloud user licenses available
- [ ] Digital Engagement add-on (required for Messaging, WhatsApp, SMS, Messaging for In-App and Web; **Chat/Live Agent retired Feb 14, 2026 — do not scope new Chat implementations**)
- [ ] Service Cloud Voice add-on (if telephony in scope; **preferred over Open CTI for new implementations — Open CTI retiring Feb 2028**)
- [ ] Field Service add-on (if FSL in scope)
- [ ] Agentforce for Service add-on (if AI agents or Einstein features in scope)
- [ ] Knowledge add-on (required unless Unlimited edition)
- [ ] Survey license (Feedback Management add-on or Survey Response Pack)
- [ ] Entitlement Management enabled (Setup → Entitlement Settings)
- [ ] Omni-Channel enabled (Setup → Omni-Channel Settings)

### Org Limit Checks

```soql
-- Query current Email-to-Case routing addresses
SELECT Count() FROM EmailServicesAddress WHERE IsActive = true

-- Check if Knowledge is enabled
SELECT IsEnabled FROM KnowledgeSettings (Tooling API)

-- Check active service channels
SELECT Count() FROM ServiceChannel WHERE IsDeleted = false
```

### Key Discovery Questions (28 questions)

**Volume and Channels:**
1. What is the expected monthly case volume?
2. What are the inbound channels (email, phone, chat, messaging, self-service, social)?
3. What percentage of cases come from each channel?
4. What is the peak concurrent chat/messaging session count?
5. Is telephony in scope? Which provider (Amazon Connect, Genesys, Avaya, Five9, NICE, other)?

**SLA and Entitlements:**
6. Do you have customer-facing SLA commitments? What are the response and resolution targets?
7. Are SLAs differentiated by customer tier (Bronze/Gold/Platinum)?
8. Are SLAs per-account or per-contact or per-asset?
9. Do SLAs apply only during business hours? Are there multiple business hour schedules (regions, holidays)?
10. What happens on SLA breach — escalation to whom?

**Knowledge Base:**
11. Do you have an existing knowledge base? In what system?
12. How many articles exist? What formats (HTML, PDF, Word)?
13. Do customers have self-service access to KB? Via portal or public site?
14. Is multilingual KB required? Which languages?
15. What is the article authoring workflow — who creates, reviews, approves, publishes?

**Routing and Assignment:**
16. How many tiers of support agents exist?
17. What routing criteria are used (product type, customer tier, language, skills)?
18. Do agents specialize by skill or product area?
19. Are there overflow queues for after-hours or high-volume periods?
20. Is round-robin assignment required within a queue?

**Field Service:**
21. Is field service dispatch in scope?
22. How many field technicians and territories?
23. Is the FSL mobile app required for offline-first work order completion?
24. Is GPS/location tracking of field workers required?

**AI and Automation:**
25. Is AI-powered case classification, article recommendations, or reply recommendations in scope?
26. Is a customer-facing bot (Agentforce Service Agent) required for 24/7 support?
27. What level of Einstein features are available under the customer's license?

**Integration:**
28. Are there external systems that need to create or receive cases (ERP, billing, ticketing)?

---

## Core Setup Sequence (Service Basics)

Follow this sequence to avoid dependency errors. Never skip steps — downstream configs depend on earlier ones.

### Step 1: Support Settings

```
Setup → Support Settings
  ✓ Enable Case Comment Notification to Contacts
  ✓ Notify Case Owner on New Comments
  ✓ Case Assigned Email Template: [select template]
  ✓ Keep existing case status when re-assigning (if applicable)
  ✓ Configure IsClosed flag for each Status picklist value
  ✓ Set Default Case Owner (user or queue)
```

### Step 2: Business Hours

```
Setup → Business Hours
  → Create named business hour schedules (e.g., 9-5 EST, 24x7, EMEA)
  → Mark holidays (Setup → Holidays → add to Business Hours)
```

### Step 3: Case Record Types + Page Layouts

```
Object Manager → Case → Record Types
  → Create record types per case category (e.g., Technical, Billing, Field Service)
  → For each record type: assign Business Process (determines which Status values are available)
  → Create Page Layouts per record type (agent layout vs. simplified layout)
```

### Step 4: Case Assignment Rules

```
Setup → Case Assignment Rules → New
  → Add rule entries (criteria → User or Queue)
  → Activate the rule
```

### Step 5: Case Escalation Rules

```
Setup → Escalation Rules → New
  → Add escalation criteria and time-based actions
  → Activate the rule
```

### Step 6: Auto-Response Rules

```
Setup → Auto-Response Rules → New
  → Add criteria and email template per rule entry
  → Activate the rule
```

### Step 7: Email-to-Case

```
Setup → Email-to-Case
  ✓ Enable Email-to-Case
  ✓ Enable On-Demand Service (recommended)
  → Add routing addresses (one per support email address)
  → For each routing address:
      - Set "Create Task for New Email" (optional)
      - Set "Save Email Attachments as Attachments" (if needed)
      - Set "Team Name" and "Case Owner" (queue)
  → Configure email forwarding on mail server to Salesforce endpoint
```

### Step 8: Web-to-Case

```
Setup → Web-to-Case
  ✓ Enable Web-to-Case
  → Set default response template
  → Generate HTML form (select fields)
  → Embed form on external website
  → Enable reCAPTCHA (spam prevention)
```

---

## Omni-Channel Setup Sequence

Follow exactly in this order — dependencies exist between steps.

```
1. Setup → Omni-Channel Settings → Enable Omni-Channel
2. Enable Enhanced Omni-Channel (recommended for all new implementations)
3. Setup → Service Channels → New
   → One Service Channel per object type (Case, Chat, Messaging, etc.)
   → Set Capacity Weight per channel
4. Setup → Routing Configurations → New
   → Set Routing Model (MostAvailable or LeastActive)
   → Set Capacity (max concurrent work items)
   → Set Push Timeout (seconds before item un-assigns if not accepted)
5. Setup → Queues → (existing or new queues)
   → Add Service Channels to Queue Routing Configuration
   → Add Queue Members (users or public groups)
6. Setup → Presence Configurations → New
   → Add the Service Channels agents are allowed to handle
   → Set capacity limits per Service Channel
7. Setup → Presence User Configs → Assign Presence Configurations to agents
   (via profile or permission set assignment)
8. App Manager → Service Console App → Edit
   → Add Omni-Channel component (sidebar recommended over utility bar)
9. Assign 'Omni-Channel' permission set or permission to agent profiles
10. [If Skills-Based Routing] Setup → Skills → Create skills
    → Assign SkillUser records to agents
    → Create routing rules that use skills
```

**Validation:** Have a test agent set status to Available and submit a test case. Verify it routes correctly in Omni Supervisor.

### Standard vs Enhanced Omni-Channel Decision

Always enable Enhanced Omni-Channel for new implementations. The only reason to stay on Standard is if the org is on Classic or must use a Salesforce Classic app.

| Requirement | Standard | Enhanced |
|---|---|---|
| Route Voice calls via Omni | No | Yes |
| Route Cases via Omni | No | Yes |
| Route Enhanced Messaging sessions | No | Yes |
| Use standard-navigation apps | No | Yes |
| Omni-Channel Fallback Mode | No | Yes |
| Supervisor Wallboard | No | Yes |
| Agent Inbox View | No | Yes |
| Paused status (status-based capacity) | No | Yes |
| Sidebar layout for Omni widget | No | Yes |
| Skills transfer from work list | No | Yes |
| All future features | No | Yes |
| Chat + Standard Messaging routing | Yes | Yes |

**Primary vs Interruptible capacity** (Enhanced only): designate work items as Primary (uninterruptible — voice calls) or Interruptible (can pause when urgent Primary work arrives — cases, messaging). Agents have separate capacity pools for each. Configure in Routing Configuration:
```
Setup → Routing Configurations → [Edit]
  → Capacity Type: Primary OR Interruptible
  → Primary Capacity: max concurrent primary work items
  → Interruptible Capacity: max concurrent interruptible items
```

---

## Chat → Messaging for In-App and Web Migration

**Legacy Chat (Live Agent) was retired on February 14, 2026.** Do not scope new Chat implementations. All existing Chat deployments must migrate to Messaging for In-App and Web.

### Migration Steps

```
1. Confirm Digital Engagement add-on is active (required for Messaging for In-App and Web)
2. Setup → Messaging Settings → New Channel → Messaging for In-App and Web
   → Configure pre-chat form fields to match existing Chat pre-chat form
   → Configure routing (queue or skills — same as current Chat routing config)
3. Create or reuse Omni-Channel Routing Configuration for Messaging channel
4. Assign 'Messaging Agent' permission set to all agents (replacing 'Live Agent' permission set)
5. Remove LiveChatButton deployment snippet from website
   → Add Embedded Service Messaging snippet (generated in Setup → Embedded Service)
6. Update Service Console app:
   → Remove Chat component from utility bar
   → Add Messaging component to utility bar
7. Configure Agentforce Service Agent (optional but recommended):
   → First-response bot handles common queries before routing to human
8. Update Einstein Reply Recommendations training data source:
   → Retrain on MessagingSession transcripts (not LiveChatTranscript)
9. Archive LiveChatTranscript records (Chat sessions become read-only post-retirement)
10. Test end-to-end: customer initiates session → routes to agent → agent accepts in Omni-Channel
```

### Object Mapping

| Old (Chat / Live Agent) | New (Messaging for In-App and Web) |
|---|---|
| `LiveChatTranscript` | `MessagingSession` |
| `LiveChatVisitor` | No direct equivalent (session-based) |
| `LiveChatButton` | `MessagingChannel` (Setup object) |
| `LiveChatDeployment` | `EmbeddedServiceConfig` |
| Live Agent permission set | Messaging Agent permission set |

---

## Open CTI → Service Cloud Voice Migration

Open CTI is deprecated for new Agentforce Service orgs and is scheduled for retirement in February 2028. Migrate all telephony to Service Cloud Voice.

```
1. Confirm Service Cloud Voice license is provisioned (requires account team)
2. Choose Voice model:
   - SCV with Amazon Connect (Salesforce-managed telephony) — preferred for new orgs
   - SCV with Partner Telephony — if existing CCaaS contract (Genesys, Avaya, Five9, NICE)
3. Export CTI adapter XML and map:
   - Screen pop logic → SCV Screen Pop configuration in Setup
   - Call logging (Task creation) → SCV After-Call Work (ACW) configuration
   - ANI lookup → SCV Contact Matching rules
4. Remove Open CTI softphone layout from agent profiles
5. Add Voice component to Service Console utility bar
6. Assign Service Cloud Voice permission set to telephony agents
7. Configure Omni-Channel Unified Routing to handle VoiceCall alongside Cases/Messaging
8. Test: inbound call → screen pop → case created → ACW logged
```

---

## Knowledge Setup Sequence

### Edition Limits — Check Before Scoping

| Edition | Max Articles | Max Versions/Article | Max Languages |
|---|---|---|---|
| Essentials | 500 | 10 | 1 |
| Professional | 500 | 10 | 1 |
| Enterprise | 50,000 | 10 | 5 |
| Developer | 50,000 | 10 | 5 |
| Unlimited | 150,000 | 10 | 10 |

Contact Salesforce Support to increase limits above these defaults. Total versions = articles × retained versions × translations; this can exceed article-count limits in multilingual implementations.

### Pre-Enablement Checklist

Before enabling Lightning Knowledge in production:
- [ ] Remove ALL installed packages that contain article types
- [ ] Audit all Apex and SOQL for `ArticleType` references (they break post-enablement)
- [ ] Run the Lightning Knowledge Migration Tool in a full-copy sandbox first
- [ ] Plan for Experience Cloud Help Center as PKB (Public Knowledge Base package) replacement — PKB is not supported in Lightning Knowledge
- [ ] Confirm no federated search requirement (Lightning Knowledge does not support federated search)

```
1. Setup → Knowledge Settings → Enable Knowledge
   WARNING: IRREVERSIBLE — cannot be undone after enabling
2. Enable Lightning Knowledge (required — Classic Knowledge retired June 1, 2025)
   → After enabling: article types replaced by record types; ArticleType field inaccessible
3. Object Manager → Knowledge → Record Types
   → Create record types per article category (FAQ, How-To, Troubleshooting, etc.)
   → Max 200 record types per object (Lightning Knowledge limit)
4. Object Manager → Knowledge → Page Layouts
   → Create layouts per record type
   → Include: Title, Summary, URL Name (required — cannot remove from layout), visibility flags, content fields
   → Add Publication Status field to enable inline editing
5. Setup → Data Categories
   → Create category groups (e.g., Products, Geography)
   → Create categories within groups
   → Map categories to record types
6. Setup → Data Category Visibility → Configure per profile/permission set
7. Assign Knowledge User license to all Knowledge authors/users
8. Assign permission set: Knowledge LSF (or custom permission set with Create/Edit/Publish on Knowledge)
   → To delete archived articles: user must have Modify All on Knowledge
9. App Manager → Service Console → Add Knowledge component to Case page layout
10. [Optional] Enable Einstein Article Recommendations in Setup
11. [Optional] Configure Unified Knowledge (NOTE: retiring Summer '26 — use Data 360 instead)
12. [Optional] Set up Validation Status picklist:
    Setup → Knowledge Settings → Enable Validation Status
    → Create values (e.g., Validated, Needs Review, Not Validated)
```

---

## Entitlement + SLA Setup Sequence

### Choose Your Entitlement Model First

Three implementation tiers — pick the appropriate model before building:

| Model | Objects Used | When to Use |
|---|---|---|
| **Model 1: Entitlements Only** | `Entitlement` on Account/Contact/Asset | Simple SLAs without contract tracking |
| **Model 2: Entitlements + Service Contracts** | `Entitlement`, `ServiceContract` | Contract-based service with expiry dates |
| **Model 3: Full Hierarchy** | `Entitlement`, `ServiceContract`, `ContractLineItem` | Line-item SLA differentiation per product/asset |

**Hard limits (org-wide):**
- Maximum Entitlement Processes: **1,000**
- Maximum Milestones per Process: **10**
- Maximum Service Contract hierarchy depth: **10,000 records**
- Maximum Contract Line Item hierarchy depth: **10,000 records**
- Entitlement Process Business Hours: **cannot be deployed via Change Sets** — use Metadata API or Ant Migration Tool

```
1. Setup → Entitlement Settings → Enable Entitlement Management
2. Setup → Business Hours → Confirm business hours exist for each SLA schedule
3. Setup → Entitlement Processes (SLA Processes)
   → Create SLA Process: name, SObject (Case), active dates, business hours
   → Add Milestone Types to the process:
       - Name: "First Response"
       - Target Response: 4 hours (adjust per SLA)
       - Start Time Criteria: Case Created
   → Add more milestones (Resolution, Update Frequency, etc.)
   → For each milestone: define Milestone Actions:
       - On Entry: send email, update field
       - On Success: log completion
       - On Violation: send email to manager, update priority
4. Object Manager → Case → Page Layouts
   → Add Case Milestones related list to Case layout
   → Add Entitlement lookup field
   → Add SlaStartDate, SlaExitDate fields
5. Create Entitlement records per Account/Customer (or import)
6. [If Model 2/3] Create ServiceContract records per customer; link Entitlements to ServiceContract
7. [If Model 3] Create ContractLineItem records per product/asset within ServiceContract
8. [Optional] Create Entitlement Templates for auto-assignment
9. Configure Before-Insert Flow for auto-entitlement on Case create
10. Test: create a case linked to an account with an entitlement;
    verify CaseMilestone records created, SlaStartDate populated

NOTE: If deploying via Metadata API, deploy EntitlementProcess WITHOUT Business Hours
first, then update to add Business Hours in a second deployment. Change Sets cannot
deploy Entitlement Process Business Hours at all — use Metadata API only.
```

---

## Einstein for Service Setup Order

Setup order matters — classification must be trained before recommendations are useful.

```
1. Einstein Case Classification
   a. Setup → Einstein Case Classification → Enable
   b. Select fields to classify (Type, Priority, Reason, custom fields)
   c. Set confidence threshold (recommend 70%+)
   d. Review accuracy after 2 weeks; adjust threshold
   e. Requires: 1,000+ closed cases per classification category

2. Einstein Article Recommendations
   a. Setup → Einstein Article Recommendations → Enable
   b. Requires: Lightning Knowledge enabled + sufficient article-case attach history (500+)
   c. Recommendations appear in Knowledge component on Case page

3. Einstein Reply Recommendations
   a. Setup → Einstein Reply Recommendations → Enable
   b. Train on historical messaging/chat transcripts (300+ sessions)
   c. Configure max recommendations shown (default: 3)
   d. Requires: Digital Engagement license

4. Agentforce Service Agent (Einstein Bot successor)
   a. Setup → Agents → New Agent → type: Service Agent
   b. Configure Topics (intent groups) and Actions (what the bot can do)
   c. Connect to Messaging/Chat channels
   d. Set escalation conditions (keywords, max turns, customer request)
   e. Test in Agent Builder before deploying
   f. Requires: Agentforce for Service add-on + Digital Engagement
```

---

## Field Service Lightning Setup (High Level)

FSL is a managed package — install separately from AppExchange.

```
1. Install FSL managed package from AppExchange (latest version)
2. Assign FSL permission sets to:
   - Administrators: FSL Administrator Permissions
   - Dispatchers: FSL Dispatcher Permissions
   - Field Technicians: FSL Agent Permissions + FSL Mobile App license
3. Enable FSL Settings: Setup → Field Service Settings
4. Configure Service Territories (geographic work zones)
5. Configure Operating Hours per territory
6. Create Service Resources (one per field technician/crew)
   → Link each ServiceResource to a Salesforce User
   → Set ResourceType = 'Technician' (or 'Crew' for teams)
7. Assign Service Resources to Service Territories (ServiceTerritoryMember)
8. Configure Work Types (templates for work orders with default duration/skills)
9. Dispatcher Console: Setup → Field Service Settings → Dispatcher Console
10. Install FSL Mobile App on field technician devices
    → Configure mobile app settings (offline, location tracking, etc.)
11. Integrate with Case: configure Flow or Apex to create WorkOrder from Case
12. Optimizer configuration (if automated scheduling is in scope):
    → Field Service Scheduling Policy
    → Configure FSL Optimizer settings
```

---

## Service Cloud Voice Setup

```
1. Choose telephony model:
   - Service Cloud Voice with Amazon Connect (Salesforce-managed)
   - Service Cloud Voice with Partner Telephony (bring your own CCaaS)
2. Contact Salesforce to provision Voice (requires account team involvement)
3. Setup → Voice → Create Amazon Contact Center (or configure partner)
4. Map Salesforce users to telephony provider users
5. Configure phone channels and routing:
   - Setup → Voice → Contact Centers → Edit → Routing Configuration
6. Assign Voice users the Service Cloud Voice permission set
7. Configure the call recording settings (record all / agent-initiated / off)
8. Add Voice component to Service Console utility bar
9. Configure Omni-Channel to handle voice calls alongside other channels
   (Omni-Channel Unified Routing)
10. Test end-to-end: make a test call → verify screen pop, transcript, case creation
```

---

## Digital Engagement Setup (Chat + Messaging)

### Live Chat (Embedded Service)

```
1. Enable Chat: Setup → Chat Settings → Enable Chat
2. Create Chat Buttons: Setup → Chat Buttons & Invitations
   → Configure routing type (Queue or Skills)
   → Set queue/routing configuration
3. Setup → Embedded Service → New Deployment
   → Configure branding, pre-chat form fields, offline experience
   → Generate deployment code snippet
4. Add snippet to website pages
5. Add Chat component to Service Console (via console app navigation)
6. Assign 'Live Agent' permission set to chat agents
7. Configure Omni-Channel to route chats
8. Test: initiate chat from website → verify agent receives in Omni-Channel
```

### Messaging (SMS, WhatsApp, Facebook)

```
1. Requires: Digital Engagement add-on
2. Setup → Messaging Settings → New Channel
   → Select channel type (SMS, WhatsApp, Facebook Messenger)
   → Follow provider-specific OAuth/credential setup
3. Configure routing: assign Omni-Channel queue to messaging channel
4. Assign 'Messaging Agent' permission set to messaging agents
5. Add Messaging component to Service Console
6. [Optional] Configure Agentforce Service Agent as first responder before routing to human
7. Test: send a message from customer device → verify session created → routes to agent
```

---

## Self-Service Portal Setup (Experience Cloud + Knowledge)

```
1. Setup → Experience Cloud → New Site
   → Template: Customer Service (recommended) or Help Center
2. Configure Knowledge component on the portal (article list, search, categories)
3. Configure Case deflection: Web-to-Case form on portal for escalation
4. Set External OWD on Case to Private
5. Configure Case sharing so portal users see only their own cases
   (ContactId match to portal user's Contact)
6. Set Knowledge article visibility flags (IsVisibleInCsp = true for articles
   to be visible to authenticated portal users)
7. Configure Data Category Visibility for portal user profiles
8. Set up Experience Cloud user profiles (Customer Community User)
9. Publish the site
10. [Optional] Enable Agentforce Service Agent on the portal for bot-first deflection
```

---

## Performance at Scale

### Large Case Volumes (500k+ cases/year)

- Index key query fields: `Status`, `OwnerId`, `CreatedDate`, `AccountId` (auto-indexed if in SOQL WHERE frequently; use Custom Indexes for custom fields)
- Avoid `SELECT *` on Case — specify only needed fields
- Use `LIMIT` and `OFFSET` for paginated list views
- Defer report refresh for large case reports — schedule off-hours
- Use Batch Apex for bulk operations, not real-time triggers
- Archive cases older than 2+ years using Big Objects or external archival

### Knowledge Search Performance

- Knowledge search indexing is near-real-time but can lag 10–15 minutes after publish
- Avoid very short article titles (< 5 words) — search ranking degrades
- Use Promoted Search Terms for key articles that should always surface for specific queries
- Enable Topics on articles for better categorization and search
- External article imports (Unified Knowledge / Data 360) have longer indexing delays

### Omni-Channel Supervisor Performance

- Omni Supervisor refreshes every few seconds — avoid adding all agents globally in one config
- Use Supervisor Configurations to scope each supervisor to their agent group only
- Large orgs (1,000+ agents) should create multiple Supervisor Configurations by team/region

---

## Integration Patterns

### ERP → Case Creation

```
Pattern: ERP event (e.g., billing exception) → REST API POST to Salesforce Cases endpoint
  POST /services/data/v62.0/sobjects/Case/
  Body: {
    "Subject": "Billing Exception - Invoice #xxx",
    "Origin": "Integration",
    "AccountId": "...",
    "ContactId": "...",
    "Type": "Billing",
    "Priority": "High",
    "Custom_ERP_Reference__c": "INV-12345"
  }
```

### Telephony CTI (Open CTI)

```
Open CTI JavaScript API runs in agent's browser (softphone component):
- CTI adapter: vendor JavaScript + XML adapter file (deployed to Salesforce)
- Screen pop: inbound call ANI → SOQL for Contact → navigate to record
- Call logging: After-call wrap-up creates Task with CallType, CallDurationInSeconds
- Apex interaction: limited to logging — CTI state management in JS only

Key API methods (sforce.opencti.*):
  - getCallObjectReferences()   — identify caller
  - screenPop()                 — open record
  - saveLog()                   — create Task
  - setSoftphonePanelHeight()   — UI control
```

### Marketing Cloud Case Deflection

```
Pattern:
  1. Marketing Cloud Journey Builder: trigger email campaign based on service event
  2. Service Cloud connector: sync Case status to Marketing Cloud contact attributes
  3. Journey: if Case created → send knowledge article recommendations email
     → if Case closed (resolved) → send CSAT survey invitation
  4. Survey response syncs back to Salesforce via Marketing Cloud connector
```

---

## Post-Go-Live Monitoring Checklist

- [ ] Web-to-Case daily submission count (alert if approaching 5,000/day limit)
- [ ] Email-to-Case bounce rate (check email service endpoint health)
- [ ] Omni-Channel queue depth (alert if backlog > threshold)
- [ ] SLA violation rate (Omni Supervisor + custom report)
- [ ] Einstein Case Classification confidence scores (Setup → Einstein → Classification)
- [ ] Knowledge article search deflection rate (KB views vs. case creations)
- [ ] Survey response rate and CSAT/NPS trend
- [ ] Omni Supervisor real-time agent utilization
- [ ] Apex CPU and heap limits in high-volume triggers (Setup → Apex Jobs → monitor errors)
- [ ] Scheduled Flow run history (check for failures in Setup → Scheduled Jobs)
