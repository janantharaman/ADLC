---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); salesforce_entitlements_implementation_guide.pdf (50p); service_presence_administrators.pdf (124p); omnichannel_supervisor.pdf (32p); chat_administrator.pdf (34p); api_cti.pdf (122p); voice_performance_metrics_guide.pdf (7p); lightning_knowledge_guide.pdf (91p); salesforce_knowledge_dev_guide.pdf (209p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: data-model
last-updated: 2026-05-11
---

# Service Cloud — Data Model

## Object Relationship Diagram (Text)

```
Account ─────────────────────────────────────────────────────────┐
  │                                                               │
  ├──► Contact ──────────────────────────────────────────────────┤
  │       │                                                       │
  │       └──► EntitlementContact                                 │
  │                                                               │
  ├──► Asset ────────────────────────────────────────────────────┤
  │       │                                                       │
  ├──► Entitlement ─────────────────────────────────────────────►│
  │       │  (EntitlementProcess / SlaProcess)                    │
  │       └──► CaseMilestone ◄─────────────────────────────────┐ │
  │                                                             │ │
  └──► CASE ──────────────────────────────────────────────────►┘ │
         │  (CaseNumber, Status, Priority, Origin, Type)          │
         ├──► CaseComment                                         │
         ├──► EmailMessage                                        │
         ├──► CaseTeamMember ──► CaseTeamRole                    │
         ├──► CaseHistory                                         │
         ├──► CaseArticle ──────────────────────► Knowledge__kav  │
         ├──► LiveChatTranscript                                   │
         ├──► MessagingSession                                     │
         ├──► Task / Event                                         │
         └──► ContentDocumentLink ──► ContentDocument             │
                                          └──► ContentVersion     │

Omni-Channel:                                                     │
  ServiceChannel ──► PendingServiceRouting ──► AgentWork ◄── User │
  RoutingConfiguration ──► Queue                                  │

FSL:                                                              │
  ServiceTerritory ──► ServiceResource ──► ServiceAppointment     │
  WorkOrder ──► WorkOrderLineItem                                 │
  WorkOrder ──► ServiceAppointment                                │

Knowledge:                                                        │
  Knowledge__kav (KnowledgeArticleVersion)                       │
  ContentDocument ──► ContentVersion (attachments on articles)   │
```

---

## Case

**API name:** `Case`  
**What it is:** The primary service record. Represents a customer issue, request, or support ticket.

### Key Standard Fields

| Field API Name | Type | Notes |
|---|---|---|
| `CaseNumber` | AutoNumber | System-generated; read-only; cannot be set via API |
| `Subject` | Text(255) | Brief description; drives Einstein article recommendations |
| `Description` | LongTextArea | Full problem description; may contain PII |
| `Status` | Picklist | Drives lifecycle; `IsClosed` derives from this |
| `Priority` | Picklist | Values: High, Medium, Low |
| `Origin` | Picklist | Values: Email, Phone, Web, Chat, Internal; drives auto-response rules |
| `Type` | Picklist | Category of issue (Technical, Billing, etc.) |
| `Reason` | Picklist | Root cause category |
| `AccountId` | Lookup(Account) | Parent account |
| `ContactId` | Lookup(Contact) | Contact who submitted the case |
| `OwnerId` | Lookup(User\|Queue) | Current owner — may be a queue or user |
| `EntitlementId` | Lookup(Entitlement) | Links case to SLA process; **required for SLA tracking** |
| `SlaStartDate` | DateTime | When SLA clock started; auto-set on case creation if entitlement present |
| `SlaExitDate` | DateTime | When case must be resolved to avoid SLA breach |
| `IsClosed` | Boolean | Derived from Status picklist; controlled by Support Settings |
| `ClosedDate` | DateTime | Set automatically when `IsClosed` becomes true |
| `IsEscalated` | Boolean | Set when case is flagged for escalation |
| `SuppliedEmail` | Email | Email address from Web-to-Case or Email-to-Case |
| `SuppliedName` | Text | Name from Web-to-Case |
| `AssetId` | Lookup(Asset) | Asset associated with the case |
| `ParentId` | Lookup(Case) | For parent-child case hierarchies |
| `RecordTypeId` | Lookup(RecordType) | Drives page layout and business process |
| `BusinessHoursId` | Lookup(BusinessHours) | Overrides org default business hours for SLA calc |

### Standard Status Picklist Values

| Value | IsClosed | Notes |
|---|---|---|
| New | false | Default initial status |
| Working | false | Agent actively engaged |
| Escalated | false | Escalation flag; can trigger escalation rules |
| Closed | true | Terminal state; `IsClosed = true` only if flagged in Support Settings |

> **Gotcha:** A picklist value named "Closed" does NOT set `IsClosed = true` automatically. The `IsClosed` attribute must be explicitly checked per-value in Support Settings → Case Status.

---

## CaseComment

**API name:** `CaseComment`  
**What it is:** Internal notes or customer-facing comments on a case.

| Field | Type | Notes |
|---|---|---|
| `ParentId` | MasterDetail(Case) | The parent case |
| `CommentBody` | LongTextArea | The comment content (max 4,000 chars in Classic; long text in Lightning) |
| `IsPublished` | Boolean | `true` = visible to customer in Experience Cloud portal |
| `CreatedById` | Lookup(User) | Who wrote the comment |
| `CreatedDate` | DateTime | Auto-set |

> **Note:** `IsPublished = true` is required for portal users to see comments. Default is `false` (internal only).

---

## CaseHistory

**API name:** `CaseHistory`  
**What it is:** Audit trail of field changes on Case. Auto-created by field history tracking.

| Field | Type | Notes |
|---|---|---|
| `CaseId` | Lookup(Case) | Parent case |
| `Field` | Text | API name of the changed field |
| `OldValue` | AnyType | Value before change |
| `NewValue` | AnyType | Value after change |
| `CreatedById` | Lookup(User) | Who made the change |
| `CreatedDate` | DateTime | When change occurred |

> Enable field history tracking in Object Manager → Case → Fields & Relationships → Set History Tracking. Maximum 20 fields tracked.

---

## EmailMessage

**API name:** `EmailMessage`  
**What it is:** Individual email sent or received in the context of a case via Email-to-Case.

| Field | Type | Notes |
|---|---|---|
| `ParentId` | Lookup(Case) | The case this email is part of |
| `Subject` | Text | Email subject line; thread token must be in subject or body |
| `TextBody` | LongTextArea | Plain text version of the email body |
| `HtmlBody` | LongTextArea | HTML version of the email body |
| `FromAddress` | Email | Sender's email address |
| `ToAddress` | LongTextArea | Recipient email addresses (comma-separated) |
| `CcAddress` | LongTextArea | CC addresses |
| `BccAddress` | LongTextArea | BCC addresses |
| `Incoming` | Boolean | `true` = received from customer; `false` = sent by agent |
| `Status` | Picklist | Values: New, Read, Replied, Sent, Forwarded, Draft |
| `MessageDate` | DateTime | When email was sent/received |
| `Headers` | LongTextArea | Raw email headers; contains threading token |
| `ReplyToEmailMessageId` | Lookup(EmailMessage) | In-reply-to relationship |

> **Note:** Cannot delete EmailMessage records through normal DML — requires special consideration in data management. Triggers on `Case` fire when `EmailMessage` is inserted if the trigger monitors parent case changes.

---

## CaseTeamMember / CaseTeamRole

**API name:** `CaseTeamMember`, `CaseTeamRole`  
**What it is:** Ad-hoc team members on a specific case with defined roles.

| CaseTeamMember Field | Notes |
|---|---|
| `ParentId` | The Case |
| `MemberId` | User or Contact on the team |
| `TeamRoleId` | Lookup to `CaseTeamRole` |

| CaseTeamRole Field | Notes |
|---|---|
| `Name` | Role name (e.g., "Case Manager", "Technical Reviewer") |
| `AccessLevel` | Read or Edit |
| `PreferencesVisibleInCSP` | Visible to customer on portal |

> **Gotcha:** `CaseTeamMember` records do NOT automatically grant record access via the sharing model in all OWD configurations. If Case OWD is Private, the team member may not see the case. Verify that the access level in `CaseTeamRole` is respected given your OWD setting.

---

## Entitlement

**API name:** `Entitlement`  
**What it is:** A service contract that defines the support level a customer is entitled to. Cases must reference an Entitlement for SLA tracking to activate.

| Field | Type | Notes |
|---|---|---|
| `Name` | Text | Entitlement name |
| `EntitlementName` | Text | Alternate display name field (some APIs) |
| `AccountId` | Lookup(Account) | The account holding this entitlement |
| `AssetId` | Lookup(Asset) | Optional — ties entitlement to a specific asset |
| `ContactId` | Lookup(Contact) | Optional — personal entitlement for a specific contact |
| `StartDate` | Date | When entitlement becomes active |
| `EndDate` | Date | When entitlement expires |
| `Status` | Picklist | Active, Expired, Inactive |
| `Type` | Picklist | Support tier type (e.g., "Phone", "Web", "Premium") |
| `SlaProcessId` | Lookup(SlaProcess) | The SLA process (EntitlementProcess) governing milestones |
| `BusinessHoursId` | Lookup(BusinessHours) | Business hours used for SLA time calculations |
| `IsPerIncident` | Boolean | If true, has a fixed number of support cases allowed |
| `Cases` | Related List | Cases linked to this entitlement |

---

## EntitlementContact

**API name:** `EntitlementContact`  
**What it is:** Junction object linking Contacts to Entitlements (many-to-many).

| Field | Notes |
|---|---|
| `EntitlementId` | Lookup to Entitlement |
| `ContactId` | Lookup to Contact |

---

## CaseMilestone

**API name:** `CaseMilestone`  
**What it is:** Per-case tracking record for an SLA milestone (e.g., "First Response", "Resolution").

| Field | Type | Notes |
|---|---|---|
| `CaseId` | Lookup(Case) | The case being tracked |
| `MilestoneTypeId` | Lookup(MilestoneType) | Which milestone this is |
| `StartDate` | DateTime | When milestone timer started |
| `TargetDate` | DateTime | When milestone must be completed (SLA deadline) |
| `TargetResponseInMins` | Number | Minutes allowed from start to completion |
| `CompletionDate` | DateTime | When milestone was completed |
| `IsCompleted` | Boolean | `true` if milestone was completed |
| `IsViolated` | Boolean | `true` if `TargetDate` passed without completion |
| `ElapsedTimeInMins` | Number | Time elapsed on milestone (paused by business hours) |
| `RemainingTimeInMins` | Number | Time left before breach |

> **Gotcha:** Milestone completion is NOT automatic. You must configure a "Complete Milestone" flow action or trigger when the relevant case status is reached.

---

## SlaProcess / MilestoneType

**SlaProcess:** Setup-only metadata; not directly queryable as SObject. Defines which milestones apply and in what order.

**MilestoneType:** Queryable. Defines a named milestone type (e.g., "First Response", "Resolution").

| MilestoneType Field | Notes |
|---|---|
| `Name` | Milestone name |
| `Description` | What this milestone measures |
| `RecurrenceType` | None or Timeline (repeating milestones) |

---

## ServiceContract

**API name:** `ServiceContract`
**What it is:** A formal service agreement between a company and a customer. Groups multiple Entitlements when using Entitlement Model 2 or 3. Optional — required only if tracking contract expiry or line-item SLA differentiation.

| Field | Type | Notes |
|---|---|---|
| `Name` | Text | Contract name |
| `AccountId` | Lookup(Account) | The account holding this contract |
| `ContactId` | Lookup(Contact) | Optional — contact owner |
| `StartDate` | Date | Contract effective start |
| `EndDate` | Date | Contract expiry; used to trigger renewal workflows |
| `Status` | Picklist | Draft, Activated, Cancelled, Expired |
| `Price` | Currency | Contract value |
| `ParentServiceContractId` | Lookup(ServiceContract) | For contract hierarchies (max 10,000 records in hierarchy) |
| `Pricebook2Id` | Lookup(Pricebook2) | Required if adding ContractLineItems |

> **Org limit:** Maximum 10,000 records in a ServiceContract hierarchy.

---

## ContractLineItem

**API name:** `ContractLineItem`
**What it is:** A line item within a ServiceContract. Enables per-product or per-asset SLA differentiation (Entitlement Model 3).

| Field | Type | Notes |
|---|---|---|
| `ServiceContractId` | MasterDetail(ServiceContract) | Required |
| `Product2Id` | Lookup(Product2) | Product this line applies to |
| `AssetId` | Lookup(Asset) | Asset this line applies to (optional) |
| `Quantity` | Number | Number of support incidents or units |
| `UnitPrice` | Currency | Price per unit |
| `StartDate` | Date | Line item effective start |
| `EndDate` | Date | Line item expiry |
| `ParentContractLineItemId` | Lookup(ContractLineItem) | For line-item hierarchies (max 10,000 records) |

> **Org limit:** Maximum 10,000 records in a ContractLineItem hierarchy.

---

## VoiceCall

**API name:** `VoiceCall`
**What it is:** Created for each telephony call handled through Service Cloud Voice. Contains call metadata, transcript, and recording reference.

| Field | Type | Notes |
|---|---|---|
| `CallType` | Picklist | Inbound, Outbound, Internal |
| `FromPhoneNumber` | Phone | Caller ANI |
| `ToPhoneNumber` | Phone | Called number |
| `CallDurationInSeconds` | Number | Total call duration |
| `Status` | Picklist | Ringing, Connected, Ended, Missed |
| `OwnerId` | Lookup(User) | Agent who handled the call |
| `WhoId` | Lookup(Contact\|Lead) | Related person record |
| `WhatId` | Lookup(Case\|etc.) | Related object (Case auto-created) |
| `CallDisposition` | Text | After-call wrap-up disposition code |
| `RecordingUrl` | URL | Link to call recording (if recording enabled) |
| `TranscriptId` | Lookup | Reference to VoiceCallTranscript record |

> **Data retention:** Service Cloud Voice performance data (VoiceChannelInteractionEvent, VoiceChannelInteractionDetailEvent) is automatically deleted after 30 days. Export to external storage or use scheduled Apex to archive before deletion if long-term reporting is required.

---

## Knowledge (KnowledgeArticleVersion)

**API name:** `Knowledge__kav` (default; configurable prefix in Classic; Lightning Knowledge uses single `Knowledge` object with record types)

### Key Fields on the Article Object

| Field | Type | Notes |
|---|---|---|
| `Title` | Text(255) | Required; used in search |
| `Summary` | Text(255) | Short description for search results |
| `UrlName` | Text | SEO-friendly URL slug; must be unique; required |
| `KnowledgeArticleId` | Text | Immutable identifier across versions; use this for deduplication |
| `ArticleNumber` | AutoNumber | System-generated |
| `PublishStatus` | Picklist | **Online**, Draft, Archived — cannot be set via DML; use `KbManagement.PublishingService` |
| `VersionNumber` | Number | Incremented on each new draft |
| `Language` | Picklist | Article language (e.g., `en_US`) |
| `IsVisibleInApp` | Boolean | Visible to internal agents in Service Console |
| `IsVisibleInCsp` | Boolean | Visible in Customer Portal / Experience Cloud (authenticated customers) |
| `IsVisibleInPrm` | Boolean | Visible in Partner Portal |
| `IsVisibleInPkb` | Boolean | Visible in Public Knowledge Base (unauthenticated) |
| `LastPublishedDate` | DateTime | Last publication timestamp |
| `CreatedById` | Lookup(User) | Article author |

> **Gotcha:** `IsVisibleInApp`, `IsVisibleInCsp`, `IsVisibleInPrm`, and `IsVisibleInPkb` are **four independent boolean flags**. Publishing an article does not automatically make it visible anywhere — you must explicitly set each flag.

> **Gotcha:** In Lightning Knowledge, article types are replaced by **record types** on a single `Knowledge` object. The `__kav` suffix still applies in API names for the underlying SObject but Classic article type objects (`FAQ__kav`, `HowTo__kav`) continue to exist until migrated.

### CaseArticle (Junction Object)

**API name:** `CaseArticle`  
Links a case to a Knowledge article. Created when an agent attaches an article from the Knowledge component.

| Field | Notes |
|---|---|
| `CaseId` | The case |
| `KnowledgeArticleId` | The article's immutable ID |
| `CaseArticleNumber` | Auto-generated junction number |

---

## ContentDocument / ContentVersion

**API name:** `ContentDocument`, `ContentVersion`  
Used for file attachments on Knowledge articles and cases (via `ContentDocumentLink`).

| ContentVersion Field | Notes |
|---|---|
| `Title` | File display name |
| `VersionData` | Blob — the file content |
| `FileExtension` | Extension (pdf, png, docx, etc.) |
| `ContentDocumentId` | Parent document link |
| `IsLatest` | True for the most recent version |

---

## LiveChatTranscript

**API name:** `LiveChatTranscript`  
**What it is:** Record of a completed chat session. Read-only after creation.

| Field | Type | Notes |
|---|---|---|
| `Body` | LongTextArea | Full chat transcript text; max 32,768 characters |
| `CaseId` | Lookup(Case) | Case created/linked from the chat |
| `ContactId` | Lookup(Contact) | Contact associated with the chat |
| `AccountId` | Lookup(Account) | Account associated |
| `AgentId` | Lookup(User) | Agent who handled the chat |
| `Status` | Picklist | Completed, Missed, Abandoned |
| `StartTime` | DateTime | When chat started |
| `EndTime` | DateTime | When chat ended |
| `ChatDuration` | Number | Duration in seconds |
| `WaitTime` | Number | Time customer waited for agent in seconds |

> **Gotcha:** `LiveChatTranscript` records **cannot be deleted** once created (platform restriction). Treat as immutable audit records. Body truncation at 32,768 characters — long sessions silently truncated.

---

## MessagingSession

**API name:** `MessagingSession`  
**What it is:** Record of a Digital Engagement messaging conversation (SMS, WhatsApp, Facebook Messenger, etc.). Requires Digital Engagement add-on.

| Field | Type | Notes |
|---|---|---|
| `ContactId` | Lookup(Contact) | Customer contact |
| `CaseId` | Lookup(Case) | Linked case |
| `ChannelType` | Picklist | SMS, WhatsApp, Facebook, etc. |
| `Status` | Picklist | Active, Ended, Awaiting |
| `StartTime` | DateTime | Session start |
| `EndTime` | DateTime | Session end |
| `MessagingChannelId` | Lookup | The messaging channel configuration |
| `OwnerId` | Lookup(User\|Queue) | Current owner |

---

## Omni-Channel Objects

### ServiceChannel

**API name:** `ServiceChannel`  
Defines a channel type for Omni-Channel routing (e.g., Case, Chat, Messaging).

| Field | Notes |
|---|---|
| `MasterLabel` | Display name |
| `DeveloperName` | API name |
| `RelatedEntityType` | Object being routed (Case, ChatTranscript, MessagingSession, etc.) |
| `CapacityWeight` | Default capacity cost per work item on this channel |
| `InteractionComponent` | Custom component for the work item display |

### PendingServiceRouting

**API name:** `PendingServiceRouting`  
Represents a work item waiting to be assigned to an agent.

| Field | Notes |
|---|---|
| `WorkItemId` | The record being routed (Case ID, Chat ID, etc.) |
| `ServiceChannelId` | Which channel |
| `RoutingModel` | MostAvailable, LeastActive |
| `RoutingPriority` | Numeric priority — lower number = higher priority |
| `IsReadyForRouting` | When true, eligible to be assigned |
| `CapacityPercentage` | Percentage-based capacity for tab-based model |
| `CapacityWeight` | Size-based capacity cost |

### AgentWork

**API name:** `AgentWork`  
Record of work assigned to or accepted by an agent.

| Field | Notes |
|---|---|
| `UserId` | The agent |
| `WorkItemId` | The case/chat/message being worked |
| `ServiceChannelId` | Channel |
| `Status` | Assigned, Opened, Closed |
| `AcceptDateTime` | When agent accepted |

### RoutingConfiguration

**API name:** `RoutingConfiguration`  
Defines routing rules for a queue — capacity model, overflow, priority.

| Field | Notes |
|---|---|
| `MasterLabel` | Name |
| `RoutingModel` | MostAvailable or LeastActive |
| `Capacity` | Max concurrent work items |
| `OverflowAssigneeId` | Fallback user/queue if no agents available |
| `PushTimeout` | Seconds before a pushed work item is un-assigned if not accepted |

---

## Skills-Based Routing Objects

### SkillRequirement

**API name:** `SkillRequirement`  
Defines skill requirements on a `PendingServiceRouting` record.

| Field | Notes |
|---|---|
| `SkillId` | The skill required |
| `SkillLevel` | Minimum proficiency level (0–10) |
| `RelatedRecordId` | The `PendingServiceRouting` or work item |

### Skill / ServiceChannelSkill

- `Skill` — defines a skill with a name and description
- `SkillUser` — maps an agent (`User`) to a `Skill` with a `SkillLevel`

---

## Field Service Lightning Objects (Overview Level)

FSL is a managed package with its own namespace (`FSL__`). Core objects:

| Object | API Name | Purpose |
|---|---|---|
| Work Order | `WorkOrder` | Field service job request |
| Work Order Line Item | `WorkOrderLineItem` | Sub-tasks on a work order |
| Service Appointment | `ServiceAppointment` | Scheduled appointment for field work |
| Service Resource | `ServiceResource` | A field worker or crew |
| Service Territory | `ServiceTerritory` | Geographic work zone |
| Service Territory Member | `ServiceTerritoryMember` | Links resource to territory |
| Assigned Resource | `AssignedResource` | Links resource to appointment |
| Resource Absence | `ResourceAbsence` | Time-off / unavailability |
| Operating Hours | `OperatingHours` | Working hours per territory |
| Time Sheet | `TimeSheet` | FSL time tracking |

---

## Survey / SurveyResponse

**API name:** `Survey`, `SurveyResponse`, `SurveyQuestion`, `SurveyInvitation`

| Object | Notes |
|---|---|
| `Survey` | Template defining questions (CSAT, NPS, custom) |
| `SurveyInvitation` | Unique link sent to a respondent |
| `SurveyResponse` | Individual respondent's completion record |
| `SurveyQuestionResponse` | Per-question answer |

> **Gotcha:** Requires Survey license — not automatically available on base Service Cloud orgs. Check `Setup > Surveys` to confirm feature availability before designing survey flows.

---

## Macro / MacroAction

**API name:** `Macro`, `MacroAction`

| Macro Field | Notes |
|---|---|
| `Name` | Macro display name |
| `Description` | Purpose |
| `IsAlohaSupported` | Runs in Salesforce Classic |
| `IsLightningSupported` | Runs in Lightning Experience |
| `RunningUserId` | User context for macro execution |

| MacroAction Field | Notes |
|---|---|
| `MacroId` | Parent macro |
| `Action` | The operation (Update, SendEmail, LogANote, etc.) |
| `Target` | Field or component being acted on |
| `Value` | New value to set |
| `SortOrder` | Execution order |

---

## Quick Text

**API name:** `QuickText`  
Reusable response snippets for agents. Used in email, chat, and messaging channels.

| Field | Notes |
|---|---|
| `Name` | Display name |
| `Message` | The text content (supports merge fields) |
| `Category` | Optional grouping |
| `Channel` | Email, Chat, Messaging, Phone, Portal, Internal |
| `IsInsertable` | Whether agents can insert in composers |

---

## Summary Object Reference Table

| Object | Type | Required License |
|---|---|---|
| Case | Standard | Service Cloud (any) |
| CaseComment | Standard | Service Cloud (any) |
| CaseHistory | System | Service Cloud (any) |
| EmailMessage | Standard | Service Cloud (any) |
| CaseTeamMember / CaseTeamRole | Standard | Professional+ |
| Entitlement | Standard | Entitlement Management enabled |
| EntitlementContact | Standard | Entitlement Management |
| CaseMilestone / MilestoneType | Standard | Entitlement Management (Enterprise+ for monitoring) |
| Knowledge__kav | Standard | Knowledge add-on or Unlimited |
| CaseArticle | Standard | Knowledge add-on |
| ContentDocument / ContentVersion | Standard | Core platform |
| LiveChatTranscript | Standard | Digital Engagement |
| MessagingSession | Standard | Digital Engagement |
| ServiceChannel | Standard | Omni-Channel enabled |
| PendingServiceRouting | Standard | Omni-Channel enabled |
| AgentWork | Standard | Omni-Channel enabled |
| RoutingConfiguration | Standard | Omni-Channel enabled |
| Skill / SkillUser | Standard | Skills-Based Routing (Professional+) |
| WorkOrder / ServiceAppointment | FSL Managed Package | Field Service add-on |
| Survey / SurveyResponse | Standard | Survey license |
| Macro / MacroAction | Standard | Professional+ |
| QuickText | Standard | Group+ |
