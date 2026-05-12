---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); service_presence_administrators.pdf (124p); salesforce_entitlements_implementation_guide.pdf (50p); omnichannel_supervisor.pdf (32p); chat_administrator.pdf (34p); api_cti.pdf (122p); voice_performance_metrics_guide.pdf (7p); lightning_knowledge_guide.pdf (91p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Service Cloud — Automation Patterns

---

## 1. Case Assignment Rules

**Mechanism:** Setup > Case Assignment Rules (declarative, no code required)  
**When they fire:** On Case create, OR when "Assign using active assignment rules" is checked on a Case update. They do NOT re-fire automatically on field changes.

**Pattern — queue-based tier routing:**
```
Rule 1: Type = 'Technical' AND Priority = 'High'  →  Queue: Tier2_Technical
Rule 2: Type = 'Billing'                           →  Queue: Billing_Support
Rule 3: Origin = 'Chat'                            →  Queue: Chat_Team
Rule 4: Origin = 'Email' AND Product__c = 'ERP'   →  Queue: ERP_Support
Default: (no criteria)                             →  Queue: General_Support
```

**Key design rules:**
- Only ONE active assignment rule set at a time
- Rules evaluate top-to-bottom; first match wins
- Can assign to User or Queue
- Can optionally send notification email to assignee

**Re-assignment on field change (Assignment Rules don't auto-re-fire):**
> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.
```
Record-Triggered Flow on Case | After Save | Any update
  Decision: Priority = 'Critical' AND OwnerId = Queue.Tier1_General.Id
    True → Update OwnerId = Queue.Tier2_Technical.Id
```
Or use an Apex trigger that calls `Assignment.assignRecord(caseRecord, true)`.

---

## 2. Escalation Rules

**Mechanism:** Setup > Escalation Rules (declarative)  
**When they fire:** Time-based; evaluated by a background process against cases matching criteria. Cases escalate after a specified elapsed time since Case creation or last modification.

**Pattern — time-based escalation:**
```
Rule 1: Priority = 'High' AND IsClosed = false
  Action after 4 hours: Set IsEscalated = true, Notify Queue.Manager_Queue
Rule 2: Priority = 'Medium' AND IsClosed = false
  Action after 8 hours: Send email to Case Owner's Manager
Rule 3: (default)
  Action after 24 hours: Notify support@company.com
```

**Escalation Actions available:** Reassign to User/Queue, Send notification email.  
**Limitation:** Escalation rules cannot invoke Flows or Apex natively — for complex escalation logic, pair with a Scheduled Flow that queries overdue cases.

---

## 3. Case Auto-Response Rules

**Mechanism:** Setup > Auto-Response Rules  
**When they fire:** On Case create (Email-to-Case inbound, Web-to-Case form submissions)

**Pattern:**
```
Rule 1: Origin = 'Web' AND Type = 'Technical'  → Template: "Web Technical Acknowledgement"
Rule 2: Origin = 'Email'                       → Template: "Email Case Acknowledgement"
Default: → Template: "General Case Acknowledgement"
```

> **Note:** Auto-response rules send email directly via SMTP — they do NOT create `EmailMessage` records. If you need an `EmailMessage` audit trail of the acknowledgement, use a Flow or Apex instead.

---

## 4. Web-to-Case Setup

**Mechanism:** Setup > Web-to-Case (generates HTML form)

**Setup sequence:**
1. Enable Web-to-Case in Support Settings
2. Configure default response template
3. Generate HTML form (selects fields to capture)
4. Embed form in external website

**Spam prevention:**
- Enable reCAPTCHA in Web-to-Case settings
- Add field validation (honeypot hidden fields via custom HTML)
- Limit: **5,000 cases/day** org-wide. Excess submissions fail silently — add monitoring via Scheduled Flow querying `Case WHERE CreatedDate = TODAY AND Origin = 'Web'`.

---

## 5. Email-to-Case Threading

**Two modes:**

| Mode | How It Works | When to Use |
|---|---|---|
| **Standard (Simple)** | Salesforce polls a mailbox via IMAP/POP | Simpler setup; requires firewall access from Salesforce to mail server |
| **On-Demand (Apex Email Service)** | Mailbox forwards to a Salesforce Apex inbound email endpoint | Recommended; no firewall issues; more control over processing |

**Thread ID token:** Salesforce embeds a unique token (`ref:_xxxxxxxxxx:` pattern) in outbound email subject AND body. When customer replies, the token is parsed to route the email to the correct existing case as a new `EmailMessage`.

**Threading failure causes:**
- Customer changes the email subject (strips the thread token from subject)
- Email client rewrites or strips the body token
- Agent reply template does not include `{!Case.Thread_Id}`
- HTML-only emails where the token is in HTML body but plain-text version is absent

**On-Demand setup:**
```
1. Create Apex class implementing Messaging.InboundEmailHandler
2. Configure Email Service endpoint: Setup > Email Services
3. Add the Apex endpoint address to mailbox forwarding rules
4. The Apex handler: parse thread ID → query Case → create EmailMessage
```

---

## 6. Omni-Channel Routing Patterns

### Queue-Based Routing (Standard)

```
ServiceChannel (Case) → RoutingConfiguration → Queue → PendingServiceRouting → AgentWork
```

Work items are pushed to available agents in a queue. Agents must have:
- Presence Status set to a status that includes the relevant Service Channel
- Capacity available (size-based: enough weight left; tab-based: open slots)

**PDF source (page 427):** Omni-Channel supports routing for Cases, Chats, Leads, MessagingSessions, VoiceCalls, WorkOrders, and 15+ other objects.

### Skills-Based Routing (Enhanced Omni-Channel)

```
SkillRequirement records on PendingServiceRouting → match to agents with SkillUser records
```

**Requirements:**
- Enhanced Omni-Channel enabled
- Service Resources created for each agent
- Skills assigned to agents via `SkillUser`
- Agents must have skill-based routing enabled in their routing config

**Pattern — language-based routing via Omni-Channel Flow:**
> **PDF source (pages 355–358):**
```
Omni-Channel Flow (type: Omni-Channel Flow)
  → Get Records: Contact by email from pre-chat form
  → Decision: Contact.MailingCountryCode = 'FR'
      True  → Route Work to Queue: French_Support_Queue
      False → Route Work to Queue: English_Support_Queue
```

### Omni-Channel Flows (Advanced Routing)

Omni-Channel Flows unify routing setup for all channel types in Flow Builder. Key flow variables:
- `recordId` (Text, Available for Input) — required; the work item ID
- `input_record` (Record Variable, Available for Input) — optional; full work item record
- `skillList` (Record Collection of SkillRequirement, Available for Input) — for skills routing
- `prechat` (Record Collection of ConversationContextEntry, Available for Input) — for pre-chat form data

**Flow must end with a `Route Work` action** (route to Queue, Skill, Agent, or Bot).

**Screen pop pattern (PDF, page 360):**
```
Omni-Channel Flow → Route Work Action + Add Screen Pop Action
  → Opens: Case record (primary), Contact record (subtab), Channel-Object Linking flow (subtab)
  Max 3 records/flows via Screen Pop
```

---

## 7. Einstein Case Classification

**What it does:** Automatically suggests or sets Case field values (Priority, Type, Reason) based on Subject/Description using ML trained on historical cases.

**Minimum data requirement:** 1,000+ closed cases per category for reliable classification.

**Setup pattern:**
1. Enable Einstein Case Classification in Setup
2. Configure which fields to classify and whether to auto-set or surface suggestions
3. Monitor prediction accuracy in Einstein dashboards

**Pattern — auto-tag + route:**
```
1. Case created (Email-to-Case or Web-to-Case)
2. Einstein Classification fires: sets Type = 'Billing', Priority = 'High'
3. Case Assignment Rule evaluates: Type = 'Billing' → Queue: Billing_Team
```

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

---

## 8. Einstein Article Recommendations

**What it does:** Analyzes case subject/description and suggests relevant Knowledge articles in the Knowledge component.

**Two suggestion modes:**
- **Suggested Articles (keyword-based):** Enabled by default with Lightning Knowledge. Uses tokenization and relevance scoring.
- **Einstein Article Recommendations (AI-based):** Analyzes case-article attachment history. Requires Einstein for Service license.

**Pattern — agent workflow:**
```
Agent opens Case → Knowledge component auto-loads suggested articles
  → Agent reviews suggestions → attaches relevant article (creates CaseArticle)
  → Case closed → feedback loop improves future recommendations
```

---

## 9. Einstein Reply Recommendations

**What it does:** Surfaces pre-written response suggestions in the Chat/Messaging composer during live conversations, based on conversation context and historical resolutions.

**Requirements:** Agentforce for Service or Einstein for Service license; Digital Engagement (Chat or Messaging).

**Training:** Requires minimum 300+ historical chat transcripts or messaging sessions with replies marked as used.

---

## 10. Macro Automation

**What macros can do:** Update case fields, send email (with template), log a case comment, change case status, send Quick Text.

**Pattern — bulk case close macro:**
```
Macro: "Close Resolved - Send Resolution Email"
  Action 1: Update Case.Status → 'Closed'
  Action 2: Update Case.Resolution__c → 'Issue resolved per KB article #xxx'
  Action 3: Send Email using template: "Case Resolution Template"
  Action 4: Log Note: "Case closed via bulk macro by {$User.FirstName}"
```

**Macro sharing:** Macros are private by default. Share via public groups in macro settings.

> **Note:** Macros cannot be used with Knowledge articles directly (platform limitation as of Spring '26 — PDF page 404: "You can't use macros with Knowledge articles").

---

## 11. Entitlement + Milestone SLA Automation

### SLA Clock Start

```
Case Created → Case.EntitlementId set (via assignment rule, before-insert flow, or manual) 
  → Platform sets Case.SlaStartDate = NOW()
  → CaseMilestone records created per EntitlementProcess milestones
```

**Pattern — auto-entitlement via Before Save Flow:**
```
Record-Triggered Flow on Case | Before Save | IsNew = true
  → Get Records: Entitlement WHERE AccountId = Case.AccountId AND Status = 'Active'
  → Set Case.EntitlementId = first matching entitlement Id
```

### Milestone Completion

Milestone completion does NOT happen automatically. Options:
1. **Milestone Actions in Setup:** Configure email/field update on milestone completion or violation (no code, simple cases)
2. **Flow on CaseMilestone:** Record-Triggered Flow when `IsCompleted = true` → perform downstream actions
3. **Complete Milestone Quick Action:** Add to case page layout — agent clicks to mark complete

**Pattern — auto-complete "First Response" milestone on EmailMessage insert:**
```
Record-Triggered Flow on EmailMessage | After Save | Incoming = false (outbound)
  → Get Records: CaseMilestone WHERE CaseId = EmailMessage.ParentId 
                  AND MilestoneType.Name = 'First Response' AND IsCompleted = false
  → Update CaseMilestone.CompletionDate = NOW(), IsCompleted = true
```

### Milestone Violation Escalation

**Pattern — proactive SLA monitoring with Scheduled Flow:**
```
Scheduled Flow: Runs every 30 minutes
  SOQL: Cases WHERE SlaExitDate < (NOW + 30 mins) AND IsClosed = false
  For each case:
    → Update Priority to 'High'
    → Create Task: "SLA at risk — review immediately"
    → Send email to Case Owner + Manager
```

---

## 12. Knowledge Article Lifecycle

```
Draft (created) 
  → [optional] Submit for Review → Approval Process
  → Published (Online)
  → [periodic review] Update Draft Version (article remains Published while draft exists)
  → Archive (removed from search; still accessible via direct URL and reporting)
```

**Publish via Apex (required — cannot set PublishStatus via DML):**
```apex
KbManagement.PublishingService.publishArticle(articleVersionId, true);
// true = publish as major version (false = minor/draft update)
```

**Archive via Apex:**
```apex
KbManagement.PublishingService.archiveOnlineArticle(articleVersionId, null);
// null = archive immediately; or pass a future DateTime
```

**Lightning Knowledge lifecycle note (PDF, page 386):**  
Archiving cannot be scheduled for a future date natively. Use a Scheduled Flow with a date field on the article to trigger archival.

---

## 13. Agentforce Service Agent (Bot) Pattern

**Architecture:**
```
Customer initiates chat/messaging session
  → Omni-Channel Flow routes to Bot (Agentforce Service Agent)
  → Bot: intent detection → slot filling → action (KB lookup, case create, account lookup)
  → Handoff condition met (customer requests human / bot cannot resolve)
  → Omni-Channel Flow: route session to human agent queue
  → Agent receives work item; full conversation transcript visible in MessagingSession
```

**Handoff pattern (critical):** Conversation context (pre-chat data, bot transcript, identified contact) must be explicitly passed to the agent via the `MessagingSession` record and the `ConversationContextEntry` object. It is NOT automatic.

**Deployment requirement:** Agentforce Service Agent requires Digital Engagement license AND Agentforce for Service add-on.

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

---

## 14. Chat / Messaging Escalation to Case

**Pattern — automated case creation from chat:**
```
Omni-Channel Flow (for Chat/Messaging)
  → Get Records: Contact by email from pre-chat form
  → Create Case: Origin = 'Chat', ContactId = contact.Id, Subject = pre-chat issue
  → Route Work: Queue = Chat_Support_Queue
  → Add Screen Pop: Open new Case record in agent console
```

When chat ends, `LiveChatTranscript` (or `MessagingSession`) is auto-created. Link to case via `CaseId` field.

---

## 15. Field Service: Work Order to Appointment Flow

```
Case (service request) 
  → Create Work Order (linked to Case, Account, Asset)
  → Create Work Order Line Items (specific tasks)
  → Create Service Appointment (requested time window)
  → Dispatcher Console: optimized scheduling → assign Service Resource
  → Service Resource receives appointment in FSL Mobile App
  → Mobile Worker: update status → Complete appointment
  → Work Order Status → Completed
  → Case Status → Closed (via Flow or Apex)
```

**Automation — case-to-work-order flow:**
```
Record-Triggered Flow on Case | After Save | Type = 'Field Service Request' AND IsNew = true
  → Create WorkOrder: AccountId = Case.AccountId, CaseId = Case.Id
  → Create ServiceAppointment: ParentRecordId = WorkOrder.Id
```

---

## 16. Scheduled Flow for Proactive SLA Monitoring

```
Scheduled Flow: Every hour
  Collection: Cases WHERE IsClosed = false 
               AND EntitlementId != null 
               AND SlaExitDate <= ADDMINUTES(NOW, 60)
               AND IsEscalated = false
  Loop each case:
    Update IsEscalated = true
    Create Task: Subject = 'SLA Warning - 1 hour remaining', OwnerId = Case.OwnerId
    Send email: Template = 'SLA_Warning_Manager_Notification'
```

---

## 17. Case Merge Automation Considerations

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

- Case merge is initiated manually or via API (no declarative merge automation)
- Merged cases have `Status = 'Closed'` and `IsClosed = true`; the surviving case retains all `EmailMessage`, `CaseComment`, and `CaseMilestone` children
- Automation on the losing case's `Status → Closed` transition WILL fire (escalation flows, record-triggered flows) — test carefully
- FSL Work Orders linked to merged cases: the losing case's Work Orders must be manually re-linked or handled via Apex
- If using CDC (Change Data Capture) on Case, a merge generates `ChangeEvent` for both the surviving and merged cases

---

## 18. Quick Actions for Agents

Agents in the Service Console use **Quick Actions** (object-specific or global) to perform common tasks without leaving the case record.

| Action Type | Example | Where Configured |
|---|---|---|
| Object-specific | Update Case Status | Case page layout |
| Global | Create Child Case | Global Actions setup |
| Send Email | Email template-based reply | Case page layout + Email-to-Case enabled |
| Log a Call | Record post-call notes | Case page layout |
| Create Knowledge Article from Case | Draft article with case info pre-populated | Case page layout; requires Knowledge enabled |

---

## 19. Omni-Channel Fallback Mode (Enhanced Only)

**What it is:** When all agents in a queue are unavailable or at capacity, Omni-Channel Fallback Mode can route work to a fallback queue or trigger a flow instead of leaving work pending indefinitely.

**Pattern — Fallback to backup queue after timeout:**
```
Setup → Routing Configurations → [Edit]
  → Enable Fallback Queue: [select queue]
  → Fallback Timeout: 300 seconds (5 minutes)

Result: if work item is not accepted within 5 minutes, routed to fallback queue
```

**Pattern — Trigger Flow on fallback:**
```
Omni-Channel Flow:
  Trigger: Work Item Queued and Timeout Exceeded
  Flow Action: Create Case Comment "Escalated due to queue wait time"
  Flow Action: Update Case Priority = 'High'
  Flow Action: Route to Manager Queue
```

> Requires Enhanced Omni-Channel. Standard Omni-Channel does not support Fallback Mode.

---

## 20. Primary vs Interruptible Capacity Routing Pattern

Use this pattern when agents handle both synchronous (voice) and asynchronous (cases) work and voice calls should take priority.

```
Setup:
  Voice Routing Configuration:
    → Capacity Type: Primary
    → Primary Capacity: 1 (one call at a time)

  Case Routing Configuration:
    → Capacity Type: Interruptible
    → Interruptible Capacity: 3 (up to 3 cases)

Agent Presence Configuration:
  → Voice (Primary): max 1
  → Cases (Interruptible): max 3

Result:
  - Agent working 3 cases receives an inbound call
  - Omni-Channel routes the call and pauses the 3 case work items
  - After call ends, case work items resume
  - If agent is on a call (Primary capacity full), additional calls queue
    but cases continue routing normally (separate capacity pool)
```

---

## Automation Decision Matrix

| Requirement | Recommended Tool |
|---|---|
| Route new cases to queues by field criteria | Case Assignment Rules |
| Escalate cases after N hours | Escalation Rules |
| Auto-reply to customer on case creation | Auto-Response Rules |
| Re-route case on field change | Record-Triggered Flow (after save) |
| SLA monitoring and proactive alerting | Scheduled Flow |
| Complete milestones automatically | Record-Triggered Flow on EmailMessage or Case |
| Route chats/messaging dynamically by customer attribute | Omni-Channel Flow |
| Bulk case operations by agents | Macros |
| Auto-classify case fields using AI | Einstein Case Classification |
| Surface relevant KB articles | Einstein Article Recommendations |
| 24/7 customer self-service bot | Agentforce Service Agent |
| Case creation from field service event | Record-Triggered Flow on WorkOrder |
| Handle overflow when all agents unavailable | Omni-Channel Fallback Mode (Enhanced only) |
| Prioritize voice calls over case work | Primary/Interruptible capacity routing (Enhanced only) |
| **New synchronous chat channel** | **Messaging for In-App and Web — NOT legacy Chat (retired Feb 14, 2026)** |
