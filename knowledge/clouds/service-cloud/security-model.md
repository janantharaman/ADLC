---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); service_presence_administrators.pdf (124p); salesforce_entitlements_implementation_guide.pdf (50p); omnichannel_supervisor.pdf (32p); chat_administrator.pdf (34p); api_cti.pdf (122p); voice_performance_metrics_guide.pdf (7p); lightning_knowledge_guide.pdf (91p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: security-model
last-updated: 2026-05-11
---

# Service Cloud — Security Model

---

## OWD Recommendations

| Object | Internal OWD | External OWD | Rationale |
|---|---|---|---|
| **Case** | Private | Private | Agents see only their own and queue cases; managers via Role Hierarchy; portal users see only their own |
| **CaseComment** | Controlled by Parent | Controlled by Parent | Inherits Case visibility automatically |
| **EmailMessage** | Controlled by Parent | Controlled by Parent | Inherits Case visibility |
| **Knowledge (`Knowledge__kav`)** | Public Read Only | Public Read Only | All agents must search; only authors edit; visibility further controlled by Data Categories |
| **Entitlement** | Public Read Only | Private | Agents need to verify entitlements; customers should NOT see entitlements |
| **Asset** | Private | Private | Account team and case owner access only |
| **LiveChatTranscript** | Controlled by Parent | Controlled by Parent | Inherits Case; restrict sensitive transcript content via FLS |
| **MessagingSession** | Controlled by Parent | N/A | Internal only; Controlled by Parent |
| **ServiceResource** | Public Read Only | Private | Agents need to see field resources; external users should not |
| **WorkOrder** | Private | Private | FSL — Account team and assigned resource only |

**When to deviate:**
- High-volume contact centers with large shared agent pools: consider Case OWD = Public Read/Write (all agents see all cases) — eliminates sharing overhead but reduces data isolation
- B2B with named account teams: Case OWD = Private + Sharing Rules per Account team

---

## Case Sharing Deep Dive

### Queue Ownership
When a Case is owned by a Queue:
- All Queue members can view AND edit the Case
- Visibility persists until an agent accepts (takes individual ownership)
- After acceptance: only the owner + role hierarchy above them have automatic access

### Role Hierarchy
- `Grant Access Using Hierarchies` should remain enabled for Service orgs (default = on)
- Managers above the case owner in the role hierarchy automatically get Read/Edit access
- Do NOT disable role hierarchy access for Case in Service Cloud orgs — supervisors need it to manage their teams' cases

### Case Teams
- `CaseTeamMember` adds collaborators to a specific case with defined `CaseTeamRole.AccessLevel` (Read or Edit)
- Useful for cross-functional case collaboration (Billing, Legal, Engineering on a single case)
- Team access is granted at the case level — does NOT grant broader access to Account or Contact
- Pre-defined Case Teams (templates) can auto-assign members when cases match criteria

### Sharing Rules
Design sharing rules for these common Service Cloud patterns:

| Scenario | Rule Type | Config |
|---|---|---|
| All agents in Tier1 group see all Tier1 queue cases | Criteria-based | Share Case WHERE OwnerId = Tier1_Queue → Tier1_Agents group |
| Account Executives see their account's cases | Record owner based | Share Case WHERE AccountId → Account Owner |
| Service Supervisors see all active cases | Profile/role based | Share all Cases with Service Manager role |

---

## Knowledge Article Visibility Model

Knowledge visibility is controlled by two separate, independent mechanisms:

### Channel Visibility Flags (on KnowledgeArticleVersion)

| Flag | API Name | Who Sees It |
|---|---|---|
| Internal App | `IsVisibleInApp` | Agents in Service Console (authenticated internal users) |
| Customer Portal | `IsVisibleInCsp` | Authenticated portal/Experience Cloud users with Customer Community license |
| Partner Portal | `IsVisibleInPrm` | Authenticated users with Partner Community license |
| Public Knowledge Base | `IsVisibleInPkb` | Unauthenticated public users (via Help Center or Salesforce Sites) |

**Critical:** These four flags are completely independent. Publishing an article does NOT automatically set any visibility flag. You must explicitly set each flag per article. A common mistake: publishing an article for internal use but accidentally setting `IsVisibleInPkb = true`, exposing internal-only content publicly.

### Data Category Visibility

Data Categories provide a second layer of visibility control at the content level:
- Articles tagged with a Data Category are only visible to users whose profile/permission set grants visibility to that category
- Default: all categories visible to all internal users — this default is usually wrong in regulated environments
- Configure Data Category Visibility per: profile, permission set, role

**Use Data Categories to:**
- Restrict internal-only technical content from portal users
- Segment articles by product line, region, or sensitivity level
- Control which articles Agentforce Service Agent can surface to customers vs. agents

**Setup path:** Setup → Data Category Visibility → assign categories per profile/permission set

---

## Entitlement Access

| Who | Recommended Access |
|---|---|
| Tier 1 Agents | Read on Entitlement (to verify customer's SLA tier) |
| Tier 2 / Service Ops | Read + Edit on Entitlement (can adjust dates, link assets) |
| Service Admin / Customer Success | Full CRUD (create/manage entitlement contracts) |
| Customers (portal users) | No access (External OWD = Private) |

**Key FLS restrictions on Entitlement:**
- `SlaProcessId` — restrict Edit to Service Ops only; incorrect SLA process assignment is a high-impact error
- `StartDate` / `EndDate` — restrict Edit to prevent unauthorized SLA extension
- `IsPerIncident` + `Cases` count — restrict to admins; directly impacts billing/contract tracking

---

## Omni-Channel Security

### Agent Presence Status
- Agents can only receive work when they set a Presence Status that includes the relevant Service Channel
- Presence Status changes are visible in Omni Supervisor to supervisors with the Supervisor Configuration permission
- Agents cannot see other agents' presence status by default — Omni Supervisor is required for that visibility

### Supervisor Workload Visibility
- Requires: Omni Supervisor Permission Set + Supervisor Configuration assigned
- Supervisor Configuration controls WHICH agents, queues, and skills each supervisor group can see
- **Gotcha:** Supervisor configurations use public groups — you cannot add users via role or "Grant Access Using Hierarchies" to supervisor configurations
- Supervisor features: real-time agent workload, whisper messaging, sneak peek (typing preview), conversation monitoring

**Supervisor permissions required:**
- `View All Data` is NOT required — Omni Supervisor operates within the supervisor's sharing model
- `Manage Service Channels` — required for channel configuration
- `Omni-Channel Supervisor` permission or permission set

---

## Agentforce Service Agent (Bot) — Data Access in System Context

**Critical security implication:** When an Agentforce Service Agent executes actions (SOQL queries, record lookups, case creation), it runs as the **Automated Process user** in **system context**. This means:
- Object-level security is bypassed
- FLS is bypassed
- Sharing rules are bypassed

The bot can theoretically access any record in the org unless you explicitly filter queries to the authenticated customer's context.

**Mitigation:**
- Always filter bot SOQL queries by `ContactId = :authenticatedContactId` or `AccountId = :authenticatedAccountId`
- Use `WITH SECURITY_ENFORCED` in SOQL where possible for bot invocable Apex
- Conduct a security review of all bot actions in the design phase
- Restrict which objects and fields bot actions are allowed to access via the agent's Topic and Action configuration

---

## Field Service Security

### ServiceTerritory Sharing
- Service Territories are visible to users with Read on `ServiceTerritory` object
- Field technicians should only see appointments in their assigned territory
- Use Territory-based sharing rules or filter logic in FSL mobile app queries

### ServiceResource Visibility
- Dispatcher Console requires Read on `ServiceResource`
- Field Technicians should only see their own `ServiceAppointment` records — configure via FSL permission sets
- `ServiceResource.IsActive = false` immediately stops work being assigned to that resource

### FSL Permission Set Hierarchy

| Permission Set | Who Gets It | Key Access |
|---|---|---|
| `FSL Agent Permissions` | Field technicians | View/edit their own Work Orders and Service Appointments; FSL Mobile App access |
| `FSL Dispatcher Permissions` | Dispatchers | Dispatcher Console, view all resources and territories, schedule appointments |
| `FSL Administrator Permissions` | FSL admins | Full configuration of FSL settings, resource management |

---

## Chat / Messaging Channel Security

### Pre-Chat Form Data Security
- Pre-chat form data is stored in `ConversationContextEntry` — review FLS on this object
- PII collected in pre-chat (name, email, phone) flows into `MessagingSession` fields — apply FLS
- Use **Secure Forms** in Messaging for sensitive data collection (e.g., account numbers, SSN) — these are encrypted in transit and not stored in plain text in the session transcript

### PII in Transcripts
- `LiveChatTranscript.Body` and `MessagingSession` related messages contain full conversation text including any customer-provided information
- Apply FLS on transcript body fields to restrict access to Service Ops / Compliance roles
- Consider data masking for sensitive PII patterns (credit card numbers, SSNs) — use Einstein Conversation Data Masking

### Service Cloud Voice Call Recordings
- Call recordings are stored in Salesforce (or partner telephony provider, depending on model)
- Access controlled via `VoiceCall` object FLS + object permissions
- Pause/resume recording feature available for PCI compliance (agents can pause before collecting payment info)
- Data deletion: separate process required for GDPR compliance — work with Salesforce support

---

## Profile vs. Permission Set Design

**Recommendation:** Thin profiles + layered permission sets. Profiles define the minimum access floor; permission sets grant feature-specific access.

### Recommended Permission Set Architecture

| Permission Set | Who Gets It | What It Grants |
|---|---|---|
| `Service_Core_Access` | All service agents | CRUD on Case, Read on Account/Contact/Entitlement/Asset, Case Queue access |
| `Service_Email_Access` | Agents using email channel | Access to EmailMessage object, Email-to-Case actions |
| `Service_Chat_Access` | Chat agents | Live Agent permission, `LiveChatTranscript` access, Chat Queue access |
| `Service_Messaging_Access` | Messaging agents | Digital Engagement (Messaging) access, MessagingSession CRUD |
| `Service_Knowledge_Reader` | All agents who search KB | Read on Knowledge, Knowledge component in console |
| `Service_Knowledge_Author` | KB authors | Create/Edit on Knowledge, Publish permission, Data Category visibility |
| `Service_Tier2_Access` | Tier 2 / specialists | All core + Edit on Entitlement, Manage CaseMilestone |
| `Service_Supervisor_Access` | Supervisors | OmniSupervisor, Transfer Work Items, View All Cases (if needed), Run Reports |
| `Service_Admin_Access` | Service admins | Full CRUD on all service objects, configure Omni-Channel, manage Knowledge |
| `FSL_Field_Tech` | Field technicians | FSL Agent Permissions + Service Appointments/Work Orders |
| `FSL_Dispatcher` | Dispatchers | FSL Dispatcher Permissions + full territory/resource visibility |

---

## FLS Recommendations for Sensitive Case Fields

| Field | Recommended FLS | Rationale |
|---|---|---|
| `Case.Description` | Read: all agents; Edit: agents only; no portal access | May contain PII; restrict from customer self-service view |
| `EmailMessage.TextBody` | Read: agents+; no guest user access | Full email content |
| `EmailMessage.HtmlBody` | Same as TextBody | Full HTML email body |
| `LiveChatTranscript.Body` | Read: agent role+; Edit: Read-Only (no edit allowed) | Immutable audit; contains PII |
| `Case.InternalNotes__c` (custom) | Internal only — no CSP/PKB visibility | If used for internal escalation notes |
| `Case.CompensationAmount__c` (custom) | Restrict to Service Ops + Managers | Financial sensitivity |
| `Entitlement.SlaProcessId` | Edit: Service Ops only | Incorrect change impacts all SLA calculations |
| `Entitlement.EndDate` | Edit: Service Ops + Admin only | Prevents unauthorized SLA extensions |
| `MessagingSession.*` body fields | Read: agent role+; no external access | Conversation content |

---

## Experience Cloud (Portal) Case Access

When Service Cloud integrates with Experience Cloud for customer self-service:

- **External OWD on Case must be Private** — customers see ONLY their own cases
- `Case.ContactId` must match the portal user's Contact record — this is the primary visibility gate
- `Case.AccountId` alone is NOT sufficient for B2C; use ContactId
- For B2B portals: `Account.Id` may be the gate — configure sharing rules accordingly
- Knowledge articles visible in portal: only those with `IsVisibleInCsp = true` AND Data Category visibility allows the portal user's profile
- `CaseComment.IsPublished = true` required for customers to see internal comments in the portal
- Guest user profile (unauthenticated) should only access: Web-to-Case form, Public Knowledge Base articles, Help Center content — nothing else

---

## Security Checklist for Service Cloud Engagements

- [ ] Case OWD set; external OWD = Private if portal in scope
- [ ] Knowledge visibility flags reviewed per article type
- [ ] Data Category Visibility configured per profile/permission set
- [ ] Entitlement object FLS restricts Edit to appropriate roles
- [ ] Omni Supervisor permission assigned only to supervisors
- [ ] Agentforce/bot actions scoped to authenticated customer context
- [ ] Live chat and messaging transcript FLS applied
- [ ] Call recording access restricted; pause/resume configured if PCI in scope
- [ ] FSL permission sets assigned separately from Service Cloud profiles
- [ ] Softphone layout assigned to agent profiles/permission sets
- [ ] Pre-chat PII fields reviewed and masked/restricted appropriately
- [ ] Secure Forms enabled for sensitive data collection in messaging
