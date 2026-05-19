---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); salesforce_entitlements_implementation_guide.pdf (50p); service_presence_administrators.pdf (124p); omnichannel_supervisor.pdf (32p); chat_administrator.pdf (34p); chat_dev_guide.pdf (62p); chat_rest.pdf (66p); api_cti.pdf (122p); api_console.pdf (346p); voice_performance_metrics_guide.pdf (7p); salesforce_knowledge_dev_guide.pdf (209p); lightning_knowledge_guide.pdf (91p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: api-reference
last-updated: 2026-05-11
---

# Service Cloud — API Reference

---

## Case SOQL Patterns

### Open Cases by Queue

```soql
SELECT Id, CaseNumber, Subject, Priority, Status, CreatedDate,
       Account.Name, Contact.Name
FROM Case
WHERE OwnerId IN (
    SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Tier1_Support'
)
AND IsClosed = false
ORDER BY Priority ASC, CreatedDate ASC
```

### Cases at SLA Risk (breach within next 2 hours)

```soql
SELECT Id, CaseNumber, Subject, SlaExitDate, Priority,
       Account.Name, Owner.Name
FROM Case
WHERE IsClosed = false
  AND EntitlementId != null
  AND SlaExitDate != null
  AND SlaExitDate < :System.now().addHours(2)
ORDER BY SlaExitDate ASC
```

### Escalated Cases

```soql
SELECT Id, CaseNumber, Subject, IsEscalated, Priority, Status,
       CreatedDate, LastModifiedDate, Owner.Name, Account.Name
FROM Case
WHERE IsEscalated = true
  AND IsClosed = false
ORDER BY CreatedDate DESC
```

### Cases Opened Today by Channel

```soql
SELECT Origin, COUNT(Id) CaseCount
FROM Case
WHERE CreatedDate = TODAY
GROUP BY Origin
ORDER BY CaseCount DESC
```

### Cases with No Activity in Last 5 Business Days

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

```soql
SELECT Id, CaseNumber, Subject, LastActivityDate, Owner.Name
FROM Case
WHERE IsClosed = false
  AND LastActivityDate < LAST_N_DAYS:5
ORDER BY LastActivityDate ASC
```

### Cases Owned by Specific Agent (with entitlement details)

```soql
SELECT Id, CaseNumber, Subject, Status, Priority,
       EntitlementId, Entitlement.Name, Entitlement.Type,
       SlaStartDate, SlaExitDate,
       Account.Name, Contact.Email
FROM Case
WHERE OwnerId = :agentUserId
  AND IsClosed = false
ORDER BY SlaExitDate ASC NULLS LAST
```

---

## Knowledge Article SOQL

### Object Disambiguation: `Knowledge__ka` vs `Knowledge__kav`

These are two different objects — do not confuse them:

| Object | Contains | When to Use |
|---|---|---|
| `Knowledge__ka` | Metadata only (ArticleNumber, TotalViewCount, FirstPublishedDate) | Deletes, metadata queries, deduplication by `KnowledgeArticleId` |
| `Knowledge__kav` | Content fields + all custom fields; has `PublishStatus`, `RecordTypeId` | Reading/writing article content; filter by PublishStatus |

`Knowledge__ka.Id` is stable across all versions. `Knowledge__kav.Id` changes with each new version.

### Published Articles by Channel Visibility

```soql
-- Lightning Knowledge query with channel visibility
SELECT Id, Title, Summary, UrlName, LastPublishedDate,
       IsVisibleInApp, IsVisibleInCsp, IsVisibleInPkb
FROM Knowledge__kav
WHERE PublishStatus = 'Online'
  AND Language = 'en_US'
  AND IsVisibleInApp = true
ORDER BY LastPublishedDate DESC
LIMIT 100
```

### Filter Articles by Data Category (WITH DATA CATEGORY clause)

```soql
-- Requires SOQL WITH DATA CATEGORY syntax — not filterable in standard WHERE clause
SELECT Id, Title, Summary, UrlName
FROM Knowledge__kav
WHERE PublishStatus = 'Online'
  AND Language = 'en_US'
WITH DATA CATEGORY Products__c AT Networking__c
ORDER BY LastPublishedDate DESC
```

> `WITH DATA CATEGORY` is a special SOQL clause — it is NOT a WHERE filter. Category visibility rules apply: user must have visibility to the specified category or the query returns zero results.

### Search with SOSL + Snippet (WITH SNIPPET)

```sosl
-- Returns highlighted excerpt around matched terms
FIND :searchTerm IN ALL FIELDS RETURNING
Knowledge__kav(
    Id, Title, Summary, UrlName
    WHERE PublishStatus = 'Online' AND Language = 'en_US'
    ORDER BY LastPublishedDate DESC
    LIMIT 20
)
WITH SNIPPET (target_length=120)
```

> `WITH SNIPPET` returns a text excerpt with the search term highlighted. Use this for search result previews. Available only in SOSL, not SOQL.

### Query Metadata (KnowledgeArticle — parent object)

```soql
-- TotalViewCount available on __ka, not on __kav
SELECT Id, ArticleNumber, TotalViewCount, FirstPublishedDate, LastPublishedDate,
       CaseAssociationCount
FROM Knowledge__ka
ORDER BY TotalViewCount DESC
LIMIT 50
```

### Search Published Articles by Keyword (SOSL)

```sosl
FIND :searchTerm IN ALL FIELDS RETURNING
Knowledge__kav(
    Id, Title, Summary, UrlName
    WHERE PublishStatus = 'Online' AND Language = 'en_US'
    ORDER BY LastPublishedDate DESC
    LIMIT 20
)
```

### Articles Attached to a Case

```soql
SELECT KnowledgeArticle.Title, KnowledgeArticle.Summary,
       KnowledgeArticle.UrlName, CreatedDate
FROM CaseArticle
WHERE CaseId = :caseId
ORDER BY CreatedDate DESC
```

### Most-Viewed Articles (for a time window)

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

```soql
-- Use KnowledgeArticleViewStat for view data
SELECT KnowledgeArticleId, NormalizedScore
FROM KnowledgeArticleViewStat
WHERE Channel = 'App'
ORDER BY NormalizedScore DESC
LIMIT 50
```

### Draft Articles Pending Review

```soql
SELECT Id, Title, CreatedBy.Name, CreatedDate, LastModifiedDate,
       RecordType.DeveloperName
FROM Knowledge__kav
WHERE PublishStatus = 'Draft'
  AND Language = 'en_US'
ORDER BY LastModifiedDate DESC
```

---

## Entitlement Milestone Status SOQL

### Active Cases with Milestone Violations

```soql
SELECT CaseId, Case.CaseNumber, Case.Subject,
       MilestoneType.Name, StartDate, TargetDate,
       IsViolated, IsCompleted, ElapsedTimeInMins, RemainingTimeInMins
FROM CaseMilestone
WHERE IsCompleted = false
  AND IsViolated = true
ORDER BY TargetDate ASC
```

### Upcoming Milestone Deadlines (next 4 hours)

```soql
SELECT CaseId, Case.CaseNumber, Case.Subject, Case.Owner.Name,
       MilestoneType.Name, TargetDate, RemainingTimeInMins
FROM CaseMilestone
WHERE IsCompleted = false
  AND IsViolated = false
  AND TargetDate < :System.now().addHours(4)
ORDER BY TargetDate ASC
```

### Milestone Completion Rate by Type

```soql
SELECT MilestoneType.Name,
       COUNT(Id) Total,
       SUM(CASE WHEN IsCompleted = true THEN 1 ELSE 0 END) Completed
FROM CaseMilestone
WHERE StartDate = THIS_MONTH
GROUP BY MilestoneType.Name
```

---

## EmailMessage SOQL for Case Threads

### All Email Messages on a Case (chronological)

```soql
SELECT Id, Subject, FromAddress, ToAddress,
       TextBody, Incoming, Status, MessageDate,
       CreatedBy.Name
FROM EmailMessage
WHERE ParentId = :caseId
ORDER BY MessageDate ASC
```

### Inbound Emails Without Agent Reply (identify unresponded cases)

```soql
SELECT ParentId, COUNT(Id) InboundCount
FROM EmailMessage
WHERE Incoming = true
  AND ParentId IN (
      SELECT Id FROM Case WHERE IsClosed = false
  )
GROUP BY ParentId
HAVING COUNT(Id) > 0
-- Cross-reference against cases that have outbound messages
```

### Recent Inbound Emails (across all cases, last 24 hours)

```soql
SELECT Id, ParentId, Case.CaseNumber, Subject, FromAddress,
       MessageDate, Status
FROM EmailMessage
WHERE Incoming = true
  AND MessageDate = LAST_N_HOURS:24
ORDER BY MessageDate DESC
```

---

## Omni-Channel Workload SOQL

### Queue Backlog (pending work items by queue)

```soql
SELECT ServiceChannel.MasterLabel,
       PendingServiceRouting.ServiceChannel.DeveloperName,
       COUNT(Id) Backlog,
       MIN(PushedDate) OldestItem
FROM PendingServiceRouting
WHERE IsReadyForRouting = true
GROUP BY ServiceChannel.MasterLabel, ServiceChannel.DeveloperName
ORDER BY COUNT(Id) DESC
```

### Active Agent Work by Channel

```soql
SELECT UserId, User.Name, ServiceChannel.MasterLabel,
       COUNT(Id) OpenItems
FROM AgentWork
WHERE Status IN ('Assigned', 'Opened')
GROUP BY UserId, User.Name, ServiceChannel.MasterLabel
ORDER BY COUNT(Id) DESC
```

### Agent Capacity Utilization

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

```soql
SELECT UserId, User.Name, ServicePresenceStatus.MasterLabel,
       ConfiguredCapacity, ActiveCapacity
FROM UserServicePresence
WHERE IsCurrentState = true
ORDER BY User.Name
```

---

## CaseComment Insert (Programmatic Note Creation)

### Apex — Create Internal CaseComment

```apex
CaseComment cc = new CaseComment();
cc.ParentId = caseId;
cc.CommentBody = 'Automated note: ' + message;
cc.IsPublished = false; // Internal only
insert cc;
```

### Apex — Create Customer-Visible CaseComment

```apex
CaseComment cc = new CaseComment();
cc.ParentId = caseId;
cc.CommentBody = 'Your case has been updated: ' + updateMessage;
cc.IsPublished = true; // Visible in portal
insert cc;
// Note: triggers portal email notification if configured in Support Settings
```

---

## Email-to-Case API Patterns

### Creating an EmailMessage Programmatically (outbound)

```apex
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setTargetObjectId(contactId); // Required for EmailMessage record creation
email.setWhatId(caseId);           // Links email to Case
email.setSubject('RE: Case #' + caseNumber + ' [ref:' + threadId + ']');
email.setPlainTextBody(emailBody + '\n\n[ref:' + threadId + ']');
email.setSenderDisplayName('Support Team');
email.setSaveAsActivity(true);      // Creates EmailMessage record
Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
```

### Creating EmailMessage via DML (record-only, no send)

```apex
EmailMessage em = new EmailMessage();
em.ParentId = caseId;
em.Subject = 'Case Update';
em.TextBody = noteBody;
em.HtmlBody = '<p>' + noteBody + '</p>';
em.FromAddress = 'support@company.com';
em.ToAddress = customerEmail;
em.Incoming = false;
em.Status = '3'; // Sent (0=New, 1=Read, 2=Replied, 3=Sent, 4=Forwarded, 5=Draft)
insert em;
```

---

## Knowledge Article Publish / Archive via Apex

### Publish a Draft Article

```apex
// publishArticle(articleVersionId, publishAsMinorVersion)
// true = major version (customer-visible version increment)
// false = minor version (internal only)
KbManagement.PublishingService.publishArticle(articleVersionId, true);
```

### Archive a Published Article

```apex
// archiveOnlineArticle(articleVersionId, scheduledDate)
// null = archive immediately
// DateTime value = schedule for future archival
KbManagement.PublishingService.archiveOnlineArticle(articleVersionId, null);
```

### Restore an Archived Article to Draft

```apex
KbManagement.PublishingService.restoreArchivedArticle(articleVersionId);
```

### Delete an Article Version (requires Modify All Records on Knowledge)

```apex
KbManagement.PublishingService.deleteArchivedArticle(articleVersionId);
// Cannot delete published articles directly — must archive first
```

---

## Bulk Case Closure Patterns

### Flow-Based Bulk Close

```
Scheduled Flow:
  Collection: Cases WHERE Status = 'Waiting for Customer' 
              AND LastModifiedDate < LAST_N_DAYS:14
              AND IsClosed = false
  Loop each case:
    Update Status = 'Auto-Closed'
    Create CaseComment: 'Automatically closed after 14 days of inactivity'
```

### Apex Bulk Close (with governor limit awareness)

```apex
// Safe batch pattern — Batchable Apex for large volumes
public class BulkCaseCloser implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status 
            FROM Case 
            WHERE Status = 'Waiting for Customer'
            AND LastModifiedDate < :Date.today().addDays(-14)
            AND IsClosed = false
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> cases) {
        for (Case c : cases) {
            c.Status = 'Auto-Closed';
        }
        update cases;
    }
    
    public void finish(Database.BatchableContext bc) {
        // Post-close notification logic
    }
}
// Invoke: Database.executeBatch(new BulkCaseCloser(), 200);
```

---

## CDC Events for Case (Change Data Capture)

Enable CDC on Case in Setup → Integrations → Change Data Capture.

### Subscribe to Case ChangeEvents (Platform Events / EMP API)

```javascript
// Subscribe via CometD / EMP API
const channel = '/data/CaseChangeEvent';
// Payload structure:
{
  "schema": "...",
  "payload": {
    "ChangeEventHeader": {
      "changeType": "UPDATE",       // CREATE, UPDATE, DELETE, UNDELETE
      "changedFields": ["Status", "Priority"],
      "recordIds": ["5001000000xxxxx"],
      "entityName": "Case",
      "changeOrigin": "...",
      "transactionKey": "...",
      "sequenceNumber": 1
    },
    "Status": "Closed",
    "Priority": "High"
    // Only changed fields + header are included
  }
}
```

### Use Cases for Case CDC
- Real-time sync to external ticketing systems (ServiceNow, Zendesk, Jira)
- Trigger downstream microservices on case status changes
- Audit logging in external data warehouses
- Real-time dashboard updates without polling

---

## Key Governor Limit Interactions

| Operation | Limit | Notes |
|---|---|---|
| Email-to-Case routing addresses | 50 per org (default) | Increase via Salesforce support |
| Web-to-Case submissions | 5,000/day org-wide | Excess silently dropped; monitor with reports |
| `KbManagement.PublishingService` calls | Governed by Apex limits (100 DML per transaction) | Each article operation counts as ~1 DML operation |
| SOSL search on Knowledge | 2,000 results max per SOSL statement | Paginate with OFFSET for large result sets |
| `EmailMessage` records per case | No hard limit; soft limit after several thousand | Performance degrades on case record page |
| Omni-Channel pending routing records | No hard limit; performance impact > 10,000 per queue | Monitor queue depth in Omni Supervisor |
| Case Milestone records | One per milestone type per case (per entitlement process) | Multiple entitlement processes = multiple milestones |
| Macro actions per macro | 20 actions per macro | Plan step count during design |
| Survey responses | Governed by Survey license Response Pack limits | Check contract |
| CaseMilestone violations tracked | Tracked until case is closed | No archival for active cases |
| Knowledge article versions | 100 accessible versions in Lightning (older versions in Classic only) | PDF source: page 393 |
| Knowledge rich text field links | 100 cross-article links per rich text field | PDF source: page 382 |
| External (Unified Knowledge) articles | 131,000 chars per article; truncated silently if exceeded | PDF source: page 83 |

---

## Live Agent REST API (Chat) — RETIRED Feb 14, 2026

> **RETIRED:** Legacy Chat (Live Agent) was retired on February 14, 2026. This section is preserved as a historical reference for orgs completing migration. Do NOT implement new Chat integrations. Use Messaging for In-App and Web for all new synchronous chat requirements.

Chat used a separate REST API at base URL `https://{hostname}/chat/rest/`. All requests required four custom HTTP headers:

| Header | Purpose |
|---|---|
| `X-LIVEAGENT-AFFINITY` | Session affinity token (from SessionId response) |
| `X-LIVEAGENT-API-VERSION` | API version number (e.g., `48`) |
| `X-LIVEAGENT-SESSION-KEY` | Session key from initial session creation |
| `X-LIVEAGENT-SEQUENCE` | Sequential integer; must increment with each request |

### Key Endpoints (historical reference)

```
POST /chat/rest/System/SessionId            — Create session; returns affinityToken + sessionKey
POST /chat/rest/Chasitor/ChatRequest        — Request agent connection
GET  /chat/rest/System/Messages             — Long-poll for incoming messages (200 = message, 204 = no message)
POST /chat/rest/Chasitor/ChatMessage        — Send customer message
POST /chat/rest/Chasitor/ChatEnd            — End session (reason: "client")
POST /chat/rest/Chasitor/ChasitorInit       — Set pre-chat data
GET  /chat/rest/Visitor/Availability        — Check if agents are available before starting chat
GET  /chat/rest/Visitor/BreadcrumbUrl       — Set page context for agent
```

### Migration Path

Replace `LiveChatTranscript` → `MessagingSession`. Messaging for In-App and Web uses the standard Salesforce REST API (`/services/data/v67.0/`) — no separate REST base URL or custom headers required. Agentforce Service Agent can handle automated first-response before routing to human agents.

---

## Open CTI JavaScript API — Deprecated for New Agentforce Service Orgs; Retiring Feb 2028

> **Deprecation notice (from api_cti.pdf):** Open CTI is deprecated for new Agentforce Service org implementations. Existing implementations continue to be supported until February 2028. Migrate to Service Cloud Voice.

Two separate JavaScript API files — Classic and Lightning. They are NOT interchangeable:

| Environment | JavaScript File |
|---|---|
| Salesforce Classic | `/support/api/66.0/interaction.js` |
| Lightning Experience | `/support/api/66.0/lightning/opencti_min.js` |

### Key Open CTI Methods (Lightning)

```javascript
// Initialize Open CTI (call after DOM ready)
sforce.opencti.onReady({ callback: function(response) { ... } });

// Get caller details (for screen pop)
sforce.opencti.getCallObjectReferences({ callback: function(response) {
    var callObjectId = response.returnValue.callObjectId;
}});

// Screen pop to a record
sforce.opencti.screenPop({ type: sforce.opencti.SCREENPOP_TYPE.SOBJECT,
    params: { recordId: '0031000000xxxxx' }
});

// Save call log (creates Task)
sforce.opencti.saveLog({
    value: {
        entityApiName: 'Task',
        Subject: 'Call with customer',
        CallType: 'Inbound',
        CallDurationInSeconds: 300
    }, callback: function(response) { ... }
});

// Set softphone panel height
sforce.opencti.setSoftphonePanelHeight({ heightPX: 400, callback: function(response) { ... } });
```

### Migration to Service Cloud Voice

- Screen pop logic: replace CTI JS `screenPop()` call → configure SCV Screen Pop in Setup
- Call logging: replace CTI JS `saveLog()` → configure After-Call Work (ACW) in SCV
- ANI lookup: replace CTI JS `getCallObjectReferences()` → SCV Contact Matching rules
- Remove softphone layout assignment from agent profiles; add Voice utility component instead

---

## Key Metadata API Types for Queries

Tooling API queries for service metadata inspection:

```soql
-- List all active Omni-Channel routing configurations
SELECT Id, MasterLabel, DeveloperName, RoutingModel, Capacity, PushTimeout
FROM RoutingConfiguration
WHERE IsDeleted = false

-- List all service channels
SELECT Id, MasterLabel, DeveloperName, RelatedEntityType
FROM ServiceChannel
WHERE IsDeleted = false

-- List active entitlement processes
SELECT Id, Name, IsActive, BusinessHoursId, SObjectType
FROM SlaProcess
WHERE IsActive = true

-- List all Case Assignment Rules
-- (Use Metadata API or Setup UI — not queryable via SOQL)
```
