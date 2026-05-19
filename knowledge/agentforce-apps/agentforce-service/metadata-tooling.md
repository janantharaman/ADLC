---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); service_presence_administrators.pdf (124p); salesforce_entitlements_implementation_guide.pdf (50p); omnichannel_supervisor.pdf (32p); chat_administrator.pdf (34p); api_cti.pdf (122p); voice_performance_metrics_guide.pdf (7p); lightning_knowledge_guide.pdf (91p); salesforce_knowledge_dev_guide.pdf (209p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Service Cloud — Metadata and Tooling Reference

---

## Key Metadata Types for Service Cloud

| Metadata Type | API Name | What It Covers |
|---|---|---|
| Support Settings | `SupportSettings` | Case IsClosed mapping, case origins, default owner, email settings |
| Business Hours | `BusinessHours` | Business hour schedules including holiday references |
| Holidays | `Holiday` | Holiday definitions referenced by Business Hours |
| Case Business Process | `BusinessProcess` (type=Case) | Status picklist value sets per record type |
| Case Record Type | `RecordType` (on Case) | Record type definitions; reference Business Process |
| Assignment Rule | `AssignmentRule` | Case (and Lead) assignment rule sets |
| Auto-Response Rule | `AutoResponseRule` | Case auto-response email rule sets |
| Escalation Rule | `EscalationRule` | Case escalation time-based rules |
| Entitlement Process | `EntitlementProcess` | SLA process metadata; milestone definitions included |
| Milestone Type | `MilestoneType` | Named milestone type definitions |
| Knowledge Settings | `KnowledgeSettings` | Lightning Knowledge enabled, default language, supported languages |
| Knowledge Object | Custom SObject `Knowledge__kav` | Managed via Object Manager; article record types |
| Live Agent Settings | `LiveAgentSettings` | Enable/disable Chat; queue and routing configurations |
| Chat Button | `LiveChatButton` | Chat button/deployment settings |
| Chat Deployment | `LiveChatDeployment` | Embedded Service / Chat deployment |
| Omni-Channel Settings | `OmniChannelSettings` | Enable/disable Omni-Channel; enhanced mode |
| Service Channel | `ServiceChannel` | Service Channel definitions |
| Routing Configuration | `RoutingConfiguration` | Routing rules and capacity per channel |
| Presence Configuration | `PresenceUserConfig` | Agent presence capacity and channel assignments |
| Presence Decline Reason | `PresenceDeclineReason` | Reasons agents can decline work items |
| Supervisor Configuration | `SupervisorConfig` | Omni Supervisor visibility settings per supervisor group |
| Embedded Service | `EmbeddedServiceConfig` | Embedded Service deployment config |
| Embedded Service Flow Config | `EmbeddedServiceFlowConfig` | Pre-chat flow and bot routing |
| CTI Softphone Layout | `CallCenter` / `SoftphoneLayout` | Softphone layout definitions |
| Quick Text | `QuickText` | Agent quick text snippets |
| Macro | `Macro` | Automation macros (agents) |

---

## Deployment Ordering Constraints

Service Cloud has hard ordering dependencies. Deploy in this sequence to avoid errors:

```
Phase 1 — Foundation (no dependencies)
  ├── BusinessHours
  ├── Holiday
  ├── RecordType (Case) [without BusinessProcess first]
  └── CustomField on Case

Phase 2 — Support Infrastructure
  ├── BusinessProcess (Case) — depends on Status picklist values
  ├── RecordType (Case) — reference BusinessProcess
  ├── SupportSettings — depends on Email Templates, Case Status values
  ├── AssignmentRule — depends on Queues (must exist)
  ├── AutoResponseRule — depends on Email Templates
  └── EscalationRule — depends on Users/Queues

Phase 3 — Entitlement and Knowledge
  ├── MilestoneType — independent
  ├── EntitlementProcess — depends on MilestoneType, BusinessHours
  ├── KnowledgeSettings — enable before deploying Knowledge record types
  └── RecordType (Knowledge) — depends on KnowledgeSettings enabled

Phase 4 — Omni-Channel
  ├── ServiceChannel — independent
  ├── RoutingConfiguration — depends on ServiceChannel
  ├── PresenceUserConfig (PresenceConfiguration) — depends on ServiceChannel
  └── Queue (update with RoutingConfiguration) — depends on RoutingConfiguration

Phase 5 — Chat and Messaging
  ├── LiveChatSettings — enable first
  ├── LiveChatDeployment — depends on LiveChatSettings
  ├── LiveChatButton — depends on LiveChatDeployment, RoutingConfiguration
  └── EmbeddedServiceConfig — depends on LiveChatDeployment, ChatButton

Phase 6 — Page Layouts and Assignment
  ├── PageLayout (Case) — add new fields, related lists
  └── PermissionSet — assign new objects/fields
```

**Common failure pattern:** Deploying `EntitlementProcess` to an org where Entitlement Management is not enabled → `INVALID_TYPE` error. Always enable features in Setup before deploying their metadata.

---

## package.xml Examples

### Base Case Management Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Case.Status</members>
        <members>Case.Priority</members>
        <members>Case.Origin</members>
        <members>Case.Type</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Case-Technical Support Layout</members>
        <members>Case-Billing Layout</members>
        <name>Layout</name>
    </types>
    <types>
        <members>Case.Technical_Support</members>
        <members>Case.Billing</members>
        <name>RecordType</name>
    </types>
    <types>
        <members>Case.TechnicalSupportProcess</members>
        <members>Case.BillingProcess</members>
        <name>BusinessProcess</name>
    </types>
    <types>
        <members>Default</members>
        <name>AssignmentRule</name>
    </types>
    <types>
        <members>Default</members>
        <name>AutoResponseRule</name>
    </types>
    <types>
        <members>Default</members>
        <name>EscalationRule</name>
    </types>
    <types>
        <members>Case</members>
        <name>SupportSettings</name>
    </types>
    <types>
        <members>BusinessHours</members>
        <name>BusinessHours</name>
    </types>
    <version>62.0</version>
</Package>
```

### Omni-Channel Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ServiceChannel</name>
    </types>
    <types>
        <members>Case_Standard</members>
        <members>Chat_Standard</members>
        <members>Messaging_Standard</members>
        <name>RoutingConfiguration</name>
    </types>
    <types>
        <members>Default_Presence_Config</members>
        <members>Tier2_Presence_Config</members>
        <name>PresenceUserConfig</name>
    </types>
    <types>
        <members>Default_Decline_Reason</members>
        <name>PresenceDeclineReason</name>
    </types>
    <types>
        <members>Default</members>
        <name>OmniChannelSettings</name>
    </types>
    <version>62.0</version>
</Package>
```

### Knowledge Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Knowledge</members>
        <name>KnowledgeSettings</name>
    </types>
    <types>
        <members>Knowledge.FAQ</members>
        <members>Knowledge.HowTo</members>
        <members>Knowledge.Troubleshooting</members>
        <name>RecordType</name>
    </types>
    <types>
        <members>Knowledge-FAQ Layout</members>
        <members>Knowledge-HowTo Layout</members>
        <name>Layout</name>
    </types>
    <types>
        <members>Knowledge.Article_Body__c</members>
        <members>Knowledge.Internal_Notes__c</members>
        <name>CustomField</name>
    </types>
    <version>62.0</version>
</Package>
```

### Entitlement + SLA Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>First_Response</members>
        <members>Resolution</members>
        <members>Update_Frequency</members>
        <name>MilestoneType</name>
    </types>
    <types>
        <members>Premium_SLA</members>
        <members>Standard_SLA</members>
        <members>Basic_SLA</members>
        <name>EntitlementProcess</name>
    </types>
    <version>62.0</version>
</Package>
```

---

## Sandbox Refresh Considerations

When refreshing a sandbox, Service Cloud configuration requires post-refresh remediation:

| Component | Issue After Refresh | Fix |
|---|---|---|
| Email-to-Case routing addresses | Endpoint addresses change in sandbox | Reconfigure forwarding rules to point to new sandbox endpoints |
| Omni-Channel presence configurations | Preserve from production | No fix needed (configs deploy) — but test routing after refresh |
| Chat / Messaging channels | Sandbox-specific deployment needed | Re-run channel setup in sandbox; do NOT use prod credentials |
| CTI adapter | Points to production telephony | Disable CTI adapter or configure sandbox telephony instance |
| Email auto-response rules | May use production email addresses | Update rule notification targets to sandbox-safe addresses |
| Scheduled Flows | Paused on sandbox refresh | Re-activate after confirming they're sandbox-safe |
| Einstein features | Training data from prod is not available | Re-enable Einstein features in sandbox; retraining takes days/weeks |
| FSL managed package | May need reinstall or update in sandbox | Run post-refresh install script if FSL version mismatch |
| Service Cloud Voice | Telephony integrations are prod-specific | Disable Voice in sandbox or configure sandbox telephony |

**Sandbox email safety:** Ensure `Setup → Email → Deliverability` is set to "No Access" or "System Email Only" in sandbox to prevent sending emails to real customers during testing.

---

## Managed Package Components (FSL, Einstein Bots)

### Field Service Lightning (FSL) — Deployment Restrictions

- FSL is a **managed package** with namespace `FSL`
- FSL components cannot be modified in deploying org — only configured
- FSL metadata is NOT included in `package.xml` — deploy configuration via post-install scripts and custom flows
- FSL permission sets must be assigned post-install (cannot be deployed via metadata API)
- **Version management:** FSL package updates are separate from Salesforce releases — monitor AppExchange for FSL package updates quarterly

### Agentforce Service Agent — Deployment Restrictions

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

- Agentforce Service Agent configuration (Agent Type, Topics, Actions) deploys via Metadata API (`GenAiPlannerBundle` and related types)
- LLM-based features cannot be sandbox-tested identically to production — AI responses vary
- Agent actions that call external APIs require Named Credentials deployed separately
- Test agents with `Run As` in Agent Builder; functional testing in UAT org before production

---

## Tooling API Queries for Metadata Inspection

Use Tooling API (endpoint: `/services/data/v62.0/tooling/query/`) for metadata interrogation:

```soql
-- List all active Flows on Case object
SELECT Id, MasterLabel, ApiVersion, Status, TriggerType
FROM FlowDefinition
WHERE Status = 'Active'
  AND TriggerObjectOrEvent.QualifiedApiName = 'Case'

-- List Email-to-Case routing addresses
SELECT Id, EmailAddress, Name, IsActive, Queue.Name
FROM EmailServicesAddress
WHERE IsActive = true

-- Check Knowledge settings
SELECT IsEnabled, DefaultLanguage
FROM KnowledgeSettings

-- List all custom fields on Case
SELECT Id, QualifiedApiName, Label, DataType
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Case'
  AND IsCustom = true
ORDER BY QualifiedApiName

-- List Validation Rules on Case
SELECT Id, Active, Description, ErrorMessage, ValidationName
FROM ValidationRule
WHERE EntityDefinition.QualifiedApiName = 'Case'
  AND Active = true
```

---

## Knowledge Migration Patterns

### Classic Knowledge → Lightning Knowledge Migration

**Migration requirement:** All orgs must run the Lightning Knowledge Migration Tool before June 1, 2025 (PDF, page 90).

```
Pre-migration steps:
1. Create a full-copy sandbox for testing
2. Run Knowledge export (Article Type backup)
3. Delete any managed packages containing article types
4. Test migration tool in sandbox first

Migration steps:
1. Request Lightning Knowledge Migration Tool from Salesforce Support
2. Run migration tool in sandbox — converts article types to record types
   - FAQ__kav → Knowledge (record type: FAQ)
   - HowTo__kav → Knowledge (record type: HowTo)
3. Verify: query both old and new objects; compare counts
4. Update all SOQL in Apex, Reports, and Flows:
   - Old: SELECT * FROM FAQ__kav WHERE PublishStatus = 'online'
   - New: SELECT * FROM Knowledge__kav WHERE RecordType.DeveloperName = 'FAQ'
            AND PublishStatus = 'Online'
5. Test article visibility in each channel (app, portal, public)
6. Run migration in production during low-traffic window

Post-migration:
- Old article type objects become read-only for 15 days, then permanently deleted
- URL format changes (Classic URL contains Article ID; Lightning URL contains Version ID)
  → Update any hardcoded article URLs in portal, external sites
- Public Knowledge Base package NOT supported in Lightning — migrate to Help Center or Experience Cloud
```

---

## CI/CD Considerations for Service Cloud

### What to Include in Source Control

```
force-app/main/default/
  ├── assignmentRules/
  │   └── Case.assignmentRules-meta.xml
  ├── autoResponseRules/
  │   └── Case.autoResponseRules-meta.xml
  ├── escalationRules/
  │   └── Case.escalationRules-meta.xml
  ├── entitlementProcesses/
  │   ├── Premium_SLA.entitlementProcess-meta.xml
  │   └── Standard_SLA.entitlementProcess-meta.xml
  ├── milestoneTypes/
  │   ├── First_Response.milestoneType-meta.xml
  │   └── Resolution.milestoneType-meta.xml
  ├── serviceChannels/
  ├── presenceConfigurations/
  ├── routingConfigurations/
  ├── flows/
  │   ├── Case_Assignment_Flow.flow-meta.xml
  │   └── SLA_Monitor_Scheduled.flow-meta.xml
  ├── permissionSets/
  │   ├── Service_Agent_Access.permissionset-meta.xml
  │   └── Service_Supervisor_Access.permissionset-meta.xml
  └── layouts/
      └── Case-Technical Support Layout.layout-meta.xml
```

### What NOT to Source-Control (org-specific)

- Email routing address endpoints (org/sandbox-specific)
- User-specific records (queue membership by user ID)
- CTI softphone layout user assignments (profile-based, environment-specific)
- Survey invitation links (runtime-generated)
- Einstein model configurations (environment-specific training data)

### Deployment Validation

Always use `checkOnly: true` (validation deploy) before a production deployment:
```
sf project deploy validate --source-dir force-app --target-org prod --test-level RunLocalTests
```

For Service Cloud, run these specific Apex test classes as a minimum:
- All test classes covering Case triggers and flows
- All test classes covering EmailMessage handlers
- All test classes covering Entitlement/Milestone logic
- All test classes covering Knowledge automation
