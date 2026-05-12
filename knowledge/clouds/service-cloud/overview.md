---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); api_console.pdf (346p); api_cti.pdf (122p); case_feed_dev_guide.pdf (44p); chat_administrator.pdf (34p); chat_dev_guide.pdf (62p); chat_rest.pdf (66p); chat_support_agents.pdf; chat_support_supervisors.pdf; omnichannel_supervisor.pdf (32p); salesforce_entitlements_implementation_guide.pdf (50p); service_presence_administrators.pdf (124p); service_presence_developer_guide.pdf (23p); voice_performance_metrics_guide.pdf (7p); embedded_services.pdf (42p); sos_administrators.pdf (12p); lightning_knowledge_guide.pdf (91p); salesforce_knowledge_dev_guide.pdf (209p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: overview
last-updated: 2026-05-11
---

# Service Cloud — Overview

## What Service Cloud Is

Service Cloud is Salesforce's customer service and support platform. It transforms inbound customer communications — email, phone, chat, messaging apps, Experience Cloud sites, SMS, social, and more — into Cases, routes those cases to service reps, and gives reps a unified workspace to resolve issues efficiently. The platform spans synchronous (chat, voice) and asynchronous (email, messaging) channels, self-service deflection (Knowledge, Help Center, Agentforce Service Agent), and field-deployed work (Field Service Lightning).

> **PDF source (page 7):** "With Service Cloud, you can choose how your customers reach you—by email, phone, messaging apps, Experience Cloud sites, chat, text, and more."

Service Cloud shares the Account and Contact data model with Sales Cloud. Case is the primary Service object — it is not shared with Sales Cloud and should be governed by a separate OWD.

---

## Position in the Salesforce Stack

```
Salesforce Platform (core CRM)
 ├── Sales Cloud          — Opportunity, Lead, Quote
 ├── Service Cloud        — Case, Entitlement, Knowledge, Omni-Channel
 │    ├── Experience Cloud — Self-service portals, Help Centers
 │    ├── Field Service    — Work Orders, Scheduling (managed package)
 │    └── Agentforce       — AI Agents (Service Agent, Copilot)
 └── Marketing Cloud      — Campaign, Journey Builder
```

---

## Edition Breakdown

| Feature Area | Essentials | Professional | Enterprise | Unlimited | Developer |
|---|---|---|---|---|---|
| Cases | Yes | Yes | Yes | Yes | Yes |
| Case Teams | No | Yes | Yes | Yes | Yes |
| Escalation Rules | Yes | Yes | Yes | Yes | Yes |
| Omni-Channel (Standard) | Yes | Yes | Yes | Yes | Yes |
| Omni-Channel (Enhanced) | No | No | Yes | Yes | Yes |
| Skills-Based Routing | No | Yes | Yes | Yes | Yes |
| Omni Flows | No | Yes | Yes | Yes | Yes |
| Knowledge | Add-on | Add-on | Add-on | Included | Add-on |
| Einstein features | See Einstein matrix | See Einstein matrix | See Einstein matrix | Included | See Einstein matrix |
| Entitlement Management | No | Yes | Yes | Yes | Yes |
| Entitlement Process Monitoring | No | No | Yes | Yes | Yes |
| Service Intelligence | No | No | Yes | Yes | No |
| Service Insights | No | No | Yes | Yes | No |
| Macros | Yes | Yes | Yes | Yes | Yes |
| Contact Requests | Yes | Yes | Yes | Yes | Yes |
| Experience Cloud Sites | No | No | Yes | Yes | Yes |
| Help Centers | Yes | Yes | Yes | Yes | Yes |
| Shift Scheduling | No | No | Yes | Yes | Yes (Contact Center add-on req'd) |

> **Source:** Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf), pages 8–14.

---

## License Add-Ons

| Add-On | What It Unlocks | Licensing Model |
|---|---|---|
| **Digital Engagement** | Enhanced Messaging (SMS, WhatsApp, Facebook, LINE), Enhanced Chat, Messaging for In-App and Web | Per-org license |
| **Service Cloud Voice** | CTI/telephony integration, real-time transcription, call recording | Per-user license; telephony partner choice (Amazon Connect, Partner Telephony) |
| **Field Service** | FSL managed package — Work Orders, Service Territories, Dispatch Console, Mobile Worker app | Per-user license (Dispatcher, Field Technician, Contractor) |
| **Agentforce for Service** | Agentforce Service Agent (AI-powered bot), Einstein Reply Recommendations, Einstein Copilot for Service | Consumption-based (conversations) |
| **Einstein for Service** | Case Classification, Article Recommendations, Reply Recommendations (varies by edition) | Included in Unlimited; add-on for Enterprise |
| **Feedback Management** | Survey / CSAT / NPS | Survey Response Pack or Feedback Management - Starter/Growth |
| **Service Catalog** | Employee and customer service request catalog | Agentforce for Service + Customer Service Catalog add-on |
| **Contact Center** | Shift Scheduling (WFM) | Enterprise/Performance/Unlimited |
| **Knowledge** | Salesforce Knowledge article base | Included in Unlimited; add-on for Professional/Enterprise/Performance |

> **Source:** PDF pages 7–14; Spring '26 platform knowledge.

---

## Core Modules

### Case Management
The backbone of Service Cloud. A Case represents a customer issue, request, or support ticket. Cases are created from Email-to-Case, Web-to-Case, manual entry, or API. The lifecycle is governed by the Status picklist (with IsClosed flag), business processes per record type, case assignment rules, escalation rules, and auto-response rules.

### Service Console
Lightning-based agent workspace. Supports multi-tab navigation, split view, utility bar components (macros, history, Omni-Channel widget), and sub-tabs for related records. The console is a Lightning App with the console navigation type.

### Omni-Channel Routing
Pushes work items (Cases, Chat Transcripts, Messaging Sessions, Voice Calls, Leads, custom objects) to available agents based on routing rules. Two routing models:
- **Queue-Based Routing** — work items placed in queues; pushed to agents with capacity
- **Skills-Based Routing** — work items matched to agents with required skills (Enterprise+ with Service Cloud)

Two implementations:
- **Standard Omni-Channel** — available in Lightning and Classic; limited features
- **Enhanced Omni-Channel** — Lightning only; **recommended for all net-new implementations**; required for Omni Mobile, Omni Flows, Fallback Mode, Supervisor Wallboard, Agent Inbox View, paused status, and all future features

**Standard vs Enhanced Omni-Channel feature matrix (Spring '26):**

| Feature | Standard | Enhanced |
|---|---|---|
| Chat (Live Agent) and standard Messaging routing | Yes | Yes |
| Routing, Omni Flows, Omni Supervisor, basic capacity | Yes | Yes |
| Custom report types for agent work | Yes | Yes |
| Voice, Case, Enhanced Messaging, all routable objects | No | Yes |
| Support for apps with standard navigation | No | Yes |
| Skills-based work transfer from Omni-Channel work list | No | Yes |
| Omni-Channel Fallback Mode | No | Yes |
| Supervisor Wallboard | No | Yes |
| Agent Inbox View | No | Yes |
| Paused status (status-based capacity) | No | Yes |
| Sidebar layout for Omni-Channel component | No | Yes |
| Customizable tabs in Omni Supervisor | No | Yes |
| Higher maximum queued work items | No | Yes |
| All future features and enhancements | No | Yes |

**Primary vs Interruptible capacity:** Enhanced Omni-Channel supports designating work items as Primary (uninterruptible, e.g., voice calls) or Interruptible (can be paused for urgent primary work, e.g., cases). Agents have separate primary and interruptible capacity pools. Omni-Channel routes primary work even when interruptible capacity is full, and vice versa.

Omni Supervisor provides real-time visibility into agent workload, queue backlogs, skills routing, and agent status. Supports whisper messaging, sneak-peek, and conversation monitoring.

**Omni Supervisor tabs (Spring '26):**
- **Agents tab** — All Agents view (status, channels, queues, primary/interruptible capacity, ACW) and Agents by Queue view
- **Queues Backlog tab** — Queue priority, work size, total waiting, wait times; shown if queue-based or external routing enabled
- **Assigned Work tab** — In-flight work items and agent assignments
- **Skills Backlog tab** — Pending work for skills-based routing; shown only if skills-based routing enabled
- **Wallboard tab** — Real-time contact center metrics snapshot; Enhanced Omni only

### Knowledge (Salesforce Knowledge)
Article-based knowledge base. Articles exist per record type (Lightning Knowledge) and have publish lifecycle: Draft → Review → Published (Online) → Archived. Visibility controlled by four independent channel flags: Internal App, Customer Portal, Partner Portal, Public Knowledge Base. Articles are linked to cases via `CaseArticle` junction records.

**Key API objects:**
- `Knowledge__ka` — abstract parent; one record per article regardless of version/status; ID never changes across versions; use for deletes and metadata queries
- `Knowledge__kav` — concrete article version object; one record per version + language; use for reading/writing content fields; filtered by `PublishStatus` (Draft / Online / Archived)
- `KnowledgeArticle` / `KnowledgeArticleVersion` — abstract SOAP API ancestors; in Lightning Knowledge always use the concrete `__ka`/`__kav` forms

**Edition article limits (confirmed from lightning_knowledge_guide.pdf):**

| Edition | Max Articles | Max Versions/Article | Max Languages |
|---|---|---|---|
| Essentials | 500 | 10 | 1 |
| Professional | 500 | 10 | 1 |
| Enterprise | 50,000 | 10 | 5 |
| Developer | 50,000 | 10 | 5 |
| Unlimited | 150,000 | 10 | 10 |

> Limits on versions don't count versions attached to cases/work orders (those can exceed the per-article version limit). Contact Salesforce Support to increase limits. Lightning Knowledge uses record types (max 200/object); Classic Knowledge used article types (max 100).

**Enabling Lightning Knowledge is irreversible.** After enabling, article types are replaced by record types; `ArticleType` field is no longer accessible via SOQL/API; the PKB (Public Knowledge Base) package is not supported — use Experience Cloud Help Center instead.

**Unified Knowledge** (retirement scheduled Summer '26): third-party content aggregation via Zoomin connectors (Confluence, SharePoint, ServiceNow, Zendesk, etc.). Replacement path: Data 360 connectors.

### Einstein AI for Service

| Capability | What It Does | License Required |
|---|---|---|
| Einstein Case Classification | Auto-populates case fields (Type, Priority, Reason) based on ML from historical data | Einstein for Service |
| Einstein Article Recommendations | Surfaces relevant Knowledge articles on cases using AI matching | Einstein for Service |
| Einstein Reply Recommendations | Suggests response text to agents mid-conversation | Agentforce for Service / Einstein for Service |
| Agentforce Service Agent | Autonomous AI agent for 24/7 inbound support on messaging/chat channels | Agentforce for Service add-on; consumption-based |
| Einstein Copilot for Service | In-console AI assistant — summarize, draft, suggest next steps | Agentforce for Service |
| Conversation Intelligence | Real-time sentiment, key topics from voice and messaging | Service Cloud Voice or Digital Engagement |
| Next Best Action | Recommendations driven by Salesforce Recommendations | Separate license (Strategy Builder) |

### Field Service Lightning (FSL)
A separate managed package installed on top of Service Cloud. Adds Work Orders, Work Order Line Items, Service Territories, Service Resources, Service Appointments, and the Dispatcher Console. Requires separate Field Service permission sets and the Field Service Mobile App (offline-first, iOS/Android).

### Live Agent / Chat / Messaging

| Channel | Object Created | License | Status |
|---|---|---|---|
| Chat (Embedded Service / Live Agent) | `LiveChatTranscript` | Digital Engagement add-on | **RETIRED Feb 14, 2026** — migrate to Messaging for In-App and Web |
| Messaging (SMS, WhatsApp, Facebook) | `MessagingSession` | Digital Engagement add-on | GA |
| Messaging for In-App and Web | `MessagingSession` | Digital Engagement add-on | GA — **recommended replacement for Chat** |
| Service Cloud Voice | `VoiceCall` | Service Cloud Voice license | GA |

> **Chat retirement (confirmed):** The legacy Chat (Live Agent) product was **retired on February 14, 2026**. All documentation marks it as in maintenance mode and directs customers to migrate to Messaging for In-App and Web. Do NOT implement new Chat channels — use Messaging for In-App and Web for all new synchronous chat requirements.

### Email-to-Case
Converts inbound emails to Cases and `EmailMessage` records. Two modes: **Standard** (Salesforce connects to mail server) and **On-Demand** (Apex email service endpoint — recommended for orgs with firewall restrictions or complex email routing). Thread ID token in subject/body routes replies to the correct existing case.

### Web-to-Case
HTML form submitted by customers creates Cases directly in Salesforce. Limit: 5,000 cases/day org-wide. Spam protection via reCAPTCHA.

### Entitlements and SLAs
`Entitlement` records define service contract terms per Account/Asset. `EntitlementProcess` defines SLA milestone types and timers. `CaseMilestone` tracks per-milestone status on cases, including violation detection.

### Macros
Automated sequences of actions executable by agents in the Service Console (e.g., send email template, close case, log comment). Macros can be shared with agents via public groups or individually.

### Surveys (Feedback Management)
CSAT/NPS surveys sent post-case-close via Flow or Apex. Requires Survey license (Survey Response Pack or Feedback Management add-on). Survey Response objects store results.

### Swarming
Connects agents across teams to resolve complex cases via Slack or Chatter-based collaboration. Creates a `SwarmMember` child record on Case.

### Incident Management
Tracks service-impacting incidents; links multiple cases to a parent Incident. Available in Professional+ with Service Cloud.

### Service Catalog
Employee/customer-facing service request catalog. Routes requests into Cases or other objects. Requires Agentforce for Service + Customer Service Catalog add-ons.

---

## Key Personas

| Persona | Role | Primary Objects |
|---|---|---|
| **Service Agent (Tier 1)** | Handles inbound cases, chats, messages | Case, EmailMessage, LiveChatTranscript, MessagingSession |
| **Service Agent (Tier 2/Specialist)** | Escalated/complex cases; deeper product expertise | Case, Entitlement, Knowledge |
| **Service Supervisor** | Monitors queues, agent workload, SLA compliance | Omni Supervisor, Report, Dashboard |
| **Knowledge Author** | Creates, edits, publishes Knowledge articles | Knowledge (`Knowledge__kav`) |
| **Service Admin/Operations** | Configures rules, queues, entitlements, reporting | Setup objects, Queues, Entitlement Processes |
| **Field Technician** | Completes work orders on-site via FSL mobile app | WorkOrder, ServiceAppointment |
| **Dispatcher** | Schedules and optimizes field appointments | Dispatcher Console, ServiceTerritory |
| **Customer (Self-Service)** | Searches Knowledge, submits cases via portal | Case (portal), Knowledge (public/CSP) |

---

## Integration Touchpoints

| System | Integration Pattern | Notes |
|---|---|---|
| **Sales Cloud** | Shared Account/Contact; Case ↔ Opportunity/Quote lookups via custom fields | Service agents often need Read on Opportunity — use Permission Sets |
| **Experience Cloud** | Customer self-service portal; Community case creation; Knowledge base | External OWD on Case must be Private; ContactId = portal user's Contact |
| **CTI/Voice (Open CTI)** | Browser-based softphone via Open CTI JS API; screen-pop on ANI match | Softphone layout must be assigned to profile/permission set |
| **Service Cloud Voice** | Native Salesforce telephony via Amazon Connect or partner telephony | Real-time transcription, call recording, unified routing |
| **Slack** | Swarming (Case → Slack channel); Agentforce actions | Slack for Salesforce managed package |
| **Marketing Cloud** | Case deflection emails; Service Cloud connector for case-triggered journeys | Separate MC license; Journey Builder integration |
| **ERP/Billing Systems** | Case creation from billing events; lookup to external order/contract data | External Objects (OData), Apex callouts, Platform Events |
| **CTI Adapters** | Genesys, Avaya, Five9, Amazon Connect, NICE CXone (partner packages) | Open CTI standard; partner-specific managed packages |

---

## B2B vs B2C Service Patterns

| Dimension | B2B | B2C |
|---|---|---|
| **Primary linking object** | Account (corporate) | Contact (individual) |
| **SLA model** | Entitlement per Account; often tiered (Bronze/Gold/Platinum) | Entitlement per customer segment; often time-based |
| **Case volume** | Lower volume, higher complexity | High volume, lower per-case complexity |
| **Channel mix** | Email, phone, CSP portal | Chat, messaging (WhatsApp/SMS), self-service, phone |
| **Knowledge** | Internal (agent-facing) + CSP (partner portal) | Public Knowledge Base + Customer Portal |
| **Routing** | Account-tier-based queue routing; named account teams | Omni-Channel with skills-based routing; contact center model |
| **FSL** | Common (field technicians per enterprise account) | Less common (consumer appliance/utility verticals) |

---

## Key Release History (Service Cloud)

| Release | Change |
|---|---|
| Winter '16 | Lightning Knowledge introduced — article types replaced by record types; `__kav` suffix retained |
| Summer '19 | Enhanced Omni-Channel introduced |
| Spring '22 | WDC (Work.com) non-core features removed for new customers |
| Spring '25 | Agentforce Service Agent (formerly Einstein Bot) available for net-new deployments |
| **February 14, 2026** | **Legacy Chat (Live Agent) RETIRED** — migrate to Messaging for In-App and Web |
| Winter '26 | OmniSupervisor enhanced with real-time sentiment scoring on messaging |
| Summer '26 | Unified Knowledge scheduled for retirement (migrate to Data 360 connectors) |
| **February 2028** | **Open CTI scheduled for retirement** — deprecated now for new Agentforce Service orgs; migrate to Service Cloud Voice |
| **Classic Knowledge** | Migration to Lightning Knowledge required — Lightning Knowledge Migration Tool must be run before June 1, 2025 |

> **Source:** PDF pages 84, 90; Spring '26 platform knowledge.
