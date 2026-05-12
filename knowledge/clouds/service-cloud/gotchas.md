---
source: Salesforce Service Cloud documentation (service_cloud_12-15-2025.pdf, 1374 pages); api_cti.pdf (122p); chat_administrator.pdf (34p); chat_rest.pdf (66p); service_presence_administrators.pdf (124p); salesforce_entitlements_implementation_guide.pdf (50p); voice_performance_metrics_guide.pdf (7p); lightning_knowledge_guide.pdf (91p); salesforce_knowledge_dev_guide.pdf (209p); embedded_services.pdf (42p); sos_administrators.pdf (12p); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: gotchas
last-updated: 2026-05-11
---

# Service Cloud — Gotchas and Common Misconfigurations

---

## G-01: Case OWD = Private Makes Queue Cases Invisible Without Proper Setup

**What happens:** With Case OWD set to Private, when a Case is owned by a Queue, ALL queue members can see and edit it. But once an agent accepts (takes ownership), visibility narrows to that agent + their manager chain via Role Hierarchy. Agents in the same queue can no longer see the case. This is intended behavior but surprises teams expecting "team visibility."

**Fix:** Use Case Sharing Rules to grant queue-member groups Read/Edit access, or keep Case OWD at Public Read/Write within the contact center if all agents should see all cases.

---

## G-02: `IsClosed = true` Is NOT Triggered by a Picklist Value Named "Closed"

**What happens:** Developers query `WHERE IsClosed = true` and miss cases with a "Closed" status that is not flagged as closed. Adding a picklist value named "Closed" does NOT automatically make `IsClosed = true`.

**Fix:** In Setup → Support Settings → Case Statuses (or the Case Object's Status picklist via Object Manager), check the "Closed" checkbox on each status value you want treated as closed. This is set per-value, not per-value-label.

---

## G-03: Email Threading Breaks When Subject Is Changed

**What happens:** Email-to-Case uses a thread token embedded in the subject AND body of outbound emails. If a customer modifies the subject line when replying, the token is no longer found in the subject, and the reply creates a NEW case instead of adding an `EmailMessage` to the existing case.

**Fix:**
- Include `{!Case.Thread_Id}` in BOTH subject AND body of all email templates
- Test with Outlook and Gmail — both handle threading differently
- Train agents not to change case subjects mid-conversation
- Use On-Demand Email-to-Case (Apex Email Service) for full control over thread ID parsing

> **PDF source (pages 94–95):** Lightning Editor in Email-to-Case has specific behavior for HTML vs. plain-text content; verify template encoding.

---

## G-04: `Knowledge__kav.PublishStatus` Cannot Be Set via DML

**What happens:** `UPDATE Knowledge__kav SET PublishStatus = 'Online'` throws a `DML Exception` or is silently ignored. This is a platform restriction on the Knowledge object.

**Fix:**
```apex
KbManagement.PublishingService.publishArticle(articleVersionId, true);
KbManagement.PublishingService.archiveOnlineArticle(articleVersionId, null);
```
Same applies to archiving, un-archiving, and deleting articles — all require `KbManagement` namespace methods.

---

## G-05: Lightning Knowledge — Article Types Replaced by Record Types

**What happens:** In Salesforce Classic, each article type (FAQ, How-To, etc.) was a separate SObject (`FAQ__kav`, `HowTo__kav`). After enabling Lightning Knowledge, article types are consolidated into record types on a single `Knowledge` object. The `__kav` suffix is still used in the API name.

**Impact on SOQL:** Post-Lightning Knowledge, you query `Knowledge__kav` (or your custom `Knowledge` object) and filter by `RecordType.DeveloperName`. In Classic, you had to query each type separately.

**Critical note (PDF, page 90):** "After you enable Lightning Knowledge, you can't disable it." Test in a sandbox before enabling in production. Also: `ArticleType` field is no longer accessible via SOQL or API after enabling Lightning Knowledge.

---

## G-06: Entitlement Process Milestones Do Not Fire Without `EntitlementId` on the Case

**What happens:** Cases created without `Case.EntitlementId` populated have NO SLA tracking. `SlaStartDate`, `SlaExitDate`, and `CaseMilestone` records are not created. Common scenario: Email-to-Case creates cases without auto-entitlement, so all email-generated cases silently skip SLA.

**Fix:** Use a Before-Insert Record-Triggered Flow to auto-populate `EntitlementId` based on `AccountId` (query active Entitlement for the Account). Do NOT rely on auto-response rules for this — they cannot set Case fields.

---

## G-07: Omni-Channel Presence Configuration Must Include the Service Channel

**What happens:** An agent is Online but receives no work. Root cause: their Presence Configuration does not include the Service Channel for the object type being routed.

**Fix:** After deploying a new Service Channel, update ALL relevant Presence Configurations to include the new channel. This is the #1 "why am I not getting cases?" complaint after adding a new channel type.

---

## G-08: Omni-Channel Capacity Model Cannot Be Switched Without Rebuilding

**What happens:** Two capacity models exist — **Size-Based** (numeric weight per work item) and **Tab-Based** (number of open tabs in the console). Once configured and in use, switching between them requires rebuilding all Service Channel configurations and RoutingConfigurations. Existing AgentWork records in flight will be affected.

**Fix:** Decide on capacity model at project inception. Size-Based is the recommended model for most implementations and is required for Enhanced Omni-Channel features like Omni Mobile.

> **PDF source (page 437):** "Omni Mobile supports status-based capacity, but not tab-based capacity."

---

## G-09: Skills-Based Routing — Agent Must Have Both Skill Assignment AND Service Channel Capacity

**What happens:** Agent has the required skill (`SkillUser` record exists with correct `SkillLevel`) but still doesn't receive work items. Root cause: agent's capacity for the Service Channel is 0, OR agent doesn't have a `ServiceResource` record, OR `ServiceResource.IsActive = false`.

**Fix:** Verify:
1. `SkillUser` record exists for the agent with skill level >= required level
2. Agent has a `ServiceResource` record with `ResourceType = 'Agent'` and `IsActive = true`
3. Agent's Presence Configuration has capacity > 0 for the relevant Service Channel
4. Agent's Presence Status includes the Service Channel

---

## G-10: Milestone Completion Is Not Automatic

**What happens:** Cases that technically meet the milestone completion criteria (e.g., email sent, case status updated) still show `CaseMilestone.IsCompleted = false` and accrue violations. Platform does not auto-complete milestones.

**Fix:** Choose one:
- **Milestone Actions (Setup):** Configure field updates on milestone completion events (no code; limited)
- **Flow on Case:** Record-Triggered Flow that triggers a "Complete Milestone" Apex action
- **Manual:** Add a "Complete Milestone" Quick Action to the case page layout

---

## G-11: `LiveChatTranscript` Cannot Be Deleted

**What happens:** `DELETE [SELECT Id FROM LiveChatTranscript WHERE...]` throws `INSUFFICIENT_ACCESS_OR_READONLY`. LiveChatTranscript records are immutable once created.

**Fix:** Design data retention processes around this limitation. For compliance use cases requiring deletion (GDPR), work with Salesforce support on data deletion tooling. Do not include LiveChatTranscript in standard data archival scripts.

---

## G-12: Web-to-Case 5,000 Cases/Day Limit

**What happens:** If your web form generates more than 5,000 submissions in a 24-hour period, excess submissions fail silently. No error is shown to the customer, and no case is created.

**Fix:**
- Monitor Web-to-Case volume with a daily Scheduled Flow or report
- For high-volume scenarios, use the Cases API (REST/SOAP) directly to create cases programmatically — no per-day limit
- Add server-side rate limiting on the form submission endpoint

---

## G-13: Knowledge Article Visibility — Four Independent Flags

**What happens:** An article is published (`PublishStatus = 'Online'`) but customers can't see it in the portal. Root cause: `IsVisibleInCsp = false` (or `IsVisibleInPkb = false` for public). These four flags are fully independent:
- `IsVisibleInApp` — Internal Service Console
- `IsVisibleInCsp` — Customer Portal / authenticated Experience Cloud
- `IsVisibleInPrm` — Partner Portal
- `IsVisibleInPkb` — Public Knowledge Base (unauthenticated)

**Fix:** Create a validation in your Knowledge article review process to confirm all intended visibility flags are set before approving publication.

---

## G-14: Case Teams Do Not Grant Record Access in All OWD Configurations

**What happens:** Adding a user as a `CaseTeamMember` with Edit access does not guarantee they can see the case if OWD is Private. `CaseTeamMember` adds record access BUT the behavior depends on the `CaseTeamRole.AccessLevel` and the org's OWD configuration.

**Fix:** Test case team access explicitly in a sandbox with your production OWD settings. If Case OWD is Private and the user is not in the owner's role hierarchy, Case Team is the mechanism to grant access — but verify it works in your configuration.

---

## G-15: Auto-Response Rules Do NOT Create `EmailMessage` Records

**What happens:** Auto-response rules send an outbound acknowledgement email to the case contact, but this email is NOT recorded as an `EmailMessage` on the case. Agents looking at the case feed see no trace of the auto-response.

**Fix:** If audit trail of auto-responses matters, replace auto-response rules with a Record-Triggered Flow that sends an email AND creates an outbound `EmailMessage` record via Apex or the `emailSimple` action.

---

## G-16: Case Assignment Rules Only Fire on Create (or Explicit Checkbox)

**What happens:** When Case priority changes to High (e.g., via Einstein Classification), the assignment rule does NOT automatically re-fire to route the case to Tier 2. The case stays with the original owner.

**Fix:** Use a Record-Triggered Flow on Case (After Save, When field changes) to update `OwnerId` or call `assignCase` action. Do NOT expect Assignment Rules to re-evaluate on updates.

---

## G-17: Record-Triggered Flows on Case Fire on EVERY Save — Including EmailMessage Inserts

**What happens:** When Email-to-Case processes an inbound email, it updates the Case record (sets `HasEmailMessages = true`, updates `LastModifiedDate`). This triggers any After-Save Record-Triggered Flow on Case. If your flow is not idempotent (e.g., it sends a notification every time Case is modified), agents will receive duplicate notifications.

**Fix:** Add a Decisions element at the start of every Case flow to check WHAT changed before taking action. Use `$Record.FieldName__IsChanged` formula-equivalent checks or entry criteria to narrow the firing condition.

---

## G-18: Entitlements Require Feature Enablement — Not Auto-Activated

**What happens:** Deploying `Entitlement`, `EntitlementProcess`, or `CaseMilestone` metadata to an org where Entitlement Management is not enabled throws `INVALID_TYPE` errors.

**Fix:** In Setup → Entitlement Settings, enable Entitlement Management BEFORE deploying Entitlement-related metadata. This is a common CI/CD pipeline failure on new org deployments.

---

## G-19: CTI Softphone Layout Must Be Assigned to Profile/Permission Set

**What happens:** Open CTI is configured, the telephony adapter is installed, but agents don't see the softphone panel in the Service Console. Root cause: softphone layout assignment is missing.

**Fix:** Setup → Softphone Layouts → Assign layout to the agent's profile (or permission set in newer configs). This is a separate assignment from page layouts and app navigation.

---

## G-20: FSL Is a Separate Managed Package — Separate Permission Sets Required

**What happens:** Users with Service Cloud Service Agent profile cannot create or view Work Orders, Service Appointments, or use the Dispatcher Console after FSL is installed.

**Fix:** FSL has its own permission sets (`FSL Agent Permissions`, `FSL Dispatcher Permissions`, `FSL Administrator Permissions`). These must be assigned in addition to Service Cloud profiles. FSL mobile app requires the `Field Service Mobile` permission set.

---

## G-21: Agentforce Service Agent Requires Digital Engagement License

**What happens:** Attempting to configure Agentforce Service Agent without the Digital Engagement add-on will result in messaging channels being unavailable, and the Service Agent cannot be connected to customer-facing channels.

**Fix:** Confirm Digital Engagement AND Agentforce for Service add-on licenses are present before scoping Agentforce Service Agent implementations.

---

## G-22: Einstein Bots — Data Access Runs as System Context

**What happens:** When an Agentforce Service Agent / Einstein Bot queries or updates Salesforce records as part of its actions, it runs in **system context** — bypassing object-level security, FLS, and sharing rules. A bot action that queries Case could return cases the customer should not see if not properly filtered.

**Fix:** Always scope bot queries with explicit SOQL `WHERE` clauses filtering by `ContactId` or `AccountId` based on the authenticated customer's context. Never query by ID alone without ownership validation.

---

## G-23: Bot Handoff to Live Agent — Context Is Not Automatic

**What happens:** After a bot hands off to a live agent, the agent receives the `MessagingSession` work item but may not see the full bot conversation transcript or the data collected during the bot flow (intent, slot values, customer-provided info).

**Fix:** Configure the bot to write collected data to the `MessagingSession` record (or a child object) before handing off. Use `ConversationContextEntry` to pass structured pre-conversation data. Explicitly map bot-collected data to Case fields before routing to agent.

---

## G-24: OmniSupervisor Tab Requires Permission Set

**What happens:** Supervisors have access to the Service Console app but cannot access OmniSupervisor tabs to monitor agent workloads.

**Fix:** Assign the `OmniSupervisor` permission set (or ensure the profile has the "Omni-Channel Supervisor" permission). Adding the supervisor to the Supervisor Configuration in Setup is also required for full feature access.

---

## G-25: Omni Mobile Does Not Support Tab-Based Capacity

**What happens:** Agents using the Salesforce Mobile App with Omni-Channel (Omni Mobile) cannot receive work items if the org uses tab-based capacity model.

**Fix:** Omni Mobile requires status-based (size-based) capacity model. If mobile agent support is required, switch to size-based capacity before go-live. See G-08.

> **PDF source (page 437):** Explicitly documented limitation.

---

## G-26: Knowledge Articles — Maximum 100 Smart Links Per Rich Text Field

**What happens:** Knowledge articles with more than 100 links to other Salesforce Knowledge articles in a single rich text field will silently drop links beyond the limit.

**Fix:** Limit cross-linking within individual articles. For large reference articles, split into multiple articles with a summary article that links to sections.

> **PDF source (page 382):** "You can have up to 100 links to different Salesforce Knowledge articles in one rich text field."

---

## G-27: Archiving Knowledge Articles Cannot Be Scheduled in Lightning

**What happens:** The UI offers no option to schedule article archival for a future date in Lightning Knowledge. Classic Knowledge supported scheduled archival; Lightning Knowledge does not (PDF, page 386).

**Fix:** Create a Scheduled Flow with a custom date field on the article (e.g., `Archive_Date__c`). When `Archive_Date__c <= TODAY`, invoke `KbManagement.PublishingService.archiveOnlineArticle()` via Apex.

---

## G-28: Unified Knowledge — Retirement Scheduled Summer '26

**What happens:** Orgs using Zoomin-based Unified Knowledge connectors will lose the feature in Summer '26. Third-party articles will no longer sync.

**Fix:** Migrate to Data 360 connectors before Summer '26. Plan migration as part of any engagement involving Unified Knowledge. Do NOT implement net-new Unified Knowledge integrations on new projects.

> **PDF source (page 84):** "Unified Knowledge is scheduled for retirement with the Summer '26 release."

---

## G-29: Email-to-Case — Routing Address Limit

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

**What happens:** There is an org-level limit on the number of Email-to-Case routing addresses. Default limit: 50 routing addresses. High-volume multi-brand implementations can hit this.

**Fix:** Contact Salesforce to increase the limit if needed. Alternatively, use a single routing address with logic in the inbound email Apex handler to route to appropriate queues based on email metadata (To address, Subject).

---

## G-30: Legacy Chat (Live Agent) Was RETIRED February 14, 2026

**What happens:** The legacy Chat product (`LiveChatTranscript`, Chat buttons, Chat deployments, Chat REST API) reached end-of-life on **February 14, 2026**. Any org still using legacy Chat after this date faces service disruption risk as Salesforce removes support.

**Fix:** Migrate to **Messaging for In-App and Web** before or as part of any Service Cloud engagement. Messaging for In-App and Web is the recommended replacement — it provides the same synchronous chat experience PLUS asynchronous conversations that can be resumed at any time.

**Impact on implementations:**
- Do NOT set up new Chat deployments, Chat buttons, or Chat agent configurations for any new project
- If a customer has existing Chat: scope migration to Messaging for In-App and Web as a required workstream
- The Chat REST API (`/chat/rest/System/SessionId/`, `ChasitorInit`, etc.) is deprecated — use Messaging REST API instead
- `LiveChatTranscript` records remain accessible but new transcripts are not created post-retirement

> **Source:** Confirmed in every Chat-related PDF guide (chat_administrator.pdf, chat_rest.pdf, chat_dev_guide.pdf, chat_support_agents.pdf, chat_support_supervisors.pdf) — all carry the same retirement warning.

---

## G-31: Open CTI Is Deprecated and Scheduled for Retirement February 2028

**What happens:** Open CTI is in maintenance mode — no new features are being added. It is already deprecated and unavailable for **newly created Agentforce Service orgs**. Retirement is confirmed for **February 2028**.

**Fix:** For any new telephony integration, use **Service Cloud Voice** instead of Open CTI. Service Cloud Voice integrates natively with Omni-Channel, Command Center for Service, and provides unified agent/supervisor experience across all digital channels.

**Impact on in-flight implementations:**
- Existing Open CTI implementations continue to work until February 2028
- New implementations using custom Open CTI adapters should be re-scoped to Service Cloud Voice
- The Classic and Lightning Open CTI APIs (`/support/api/66.0/interaction.js` and `/support/api/66.0/lightning/opencti_min.js`) have different method signatures — cannot be swapped in the same JS code

> **Source:** api_cti.pdf (Open CTI Developer Guide, Spring '26) — retirement notice on pages 1 and 8.

---

## G-32: Entitlement Process Business Hours Cannot Be Deployed via Change Sets

**What happens:** Entitlement Processes with custom Business Hours configured cannot be included in Change Sets for deployment to another org. Attempting to do so silently drops the Business Hours association, causing SLA timers to run 24/7 in the target org instead of the configured business schedule.

**Fix:** Use one of:
1. Create the Entitlement Process from scratch in the target org with the correct Business Hours
2. Use the Metadata API / Ant Migration Tool (not change sets) to transfer the full process
3. Remove Business Hours from the process before adding to a change set, then re-add manually post-deploy

> **Source:** salesforce_entitlements_implementation_guide.pdf, page 4 — explicitly called out as a limitation.

---

## G-33: Entitlement Limits — Hard Limits That Cause Silent Failures

**Hard limits confirmed (Spring '26):**
- Maximum **1,000 entitlement processes** per org — new processes fail to save after this
- Maximum **10 milestones** per entitlement process — additional milestones rejected
- Maximum **10,000 service contracts** in a service contract hierarchy
- Maximum **10,000 contract line items** in a contract line item hierarchy

Orgs with high SLA complexity (many product tiers, many customer segments) can approach the 1,000-process limit. Monitor via: `SELECT COUNT() FROM EntitlementProcess`.

> **Source:** salesforce_entitlements_implementation_guide.pdf, page 3.

---

## G-34: Service Cloud Voice Performance Data Deleted After 30 Days

**What happens:** Voice Channel performance data stored in `VoiceChannelInteractionEvent` and `VoiceChannelInteractionDetailEvent` objects is **automatically deleted after 30 days**. This data is not archived and cannot be recovered after deletion.

**Fix:** Build scheduled exports or scheduled CRM Analytics syncs if voice performance trend data beyond 30 days is needed for compliance, capacity planning, or quality assurance. Do not rely on these objects for long-term historical reporting.

> **Source:** voice_performance_metrics_guide.pdf, Spring '26: "All data for the new Voice objects are deleted after 30 days."

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

**What happens:** There is an org-level limit on the number of Email-to-Case routing addresses. Default limit: 50 routing addresses. High-volume multi-brand implementations can hit this.

**Fix:** Contact Salesforce to increase the limit if needed. Alternatively, use a single routing address with logic in the inbound email Apex handler to route to appropriate queues based on email metadata (To address, Subject).

---

## G-35: Enabling Lightning Knowledge Is Irreversible — And Breaks Classic API Queries

**What happens:** Once you enable Lightning Knowledge, it **cannot be disabled**. This changes the org's data model: article types are replaced by record types, and the `ArticleType` field is no longer accessible via SOQL or the API. Any custom Apex or SOQL that queries `ArticleType` will break silently (returns null) or throw errors.

**Additionally:**
- The Public Knowledge Base (PKB) package is not supported in Lightning Knowledge — use Experience Cloud Help Center instead
- Any installed packages containing article types must be deleted BEFORE enabling Lightning Knowledge
- Lightning Knowledge doesn't support federated search — stay on Classic for that
- Lookup searches in Lightning only return Published articles; Classic returns Draft/Published/Archived

**Fix:** Before enabling:
1. Remove all installed packages containing article types
2. Audit all Apex/SOQL for `ArticleType` references and replace with `RecordType`
3. Test in a recently refreshed full-copy sandbox with the Lightning Knowledge Migration Tool before enabling in production
4. Plan Experience Cloud Help Center setup as PKB replacement

> **Source:** lightning_knowledge_guide.pdf, pages 10-12; salesforce_knowledge_dev_guide.pdf, page 7.

---

## G-36: Knowledge__ka vs Knowledge__kav — Different Objects for Different Purposes

**What happens:** Developers often query `Knowledge__kav` when they need `Knowledge__ka`, or vice versa. The two objects serve different purposes and are not interchangeable.

| Object | Purpose | Key Use |
|---|---|---|
| `Knowledge__ka` | Abstract parent article — one record per article, ID never changes across versions | Deletes, metadata queries, deduplication via `KnowledgeArticleId` |
| `Knowledge__kav` | Article version — one per version + language, has content fields | Reading/writing content, filtered by `PublishStatus` |

**Common mistake:** Using `Knowledge__ka` to read article content fields (they don't exist there). Content fields (`Title`, custom fields, Rich Text Area fields) are only on `Knowledge__kav`.

**Correct pattern to get published article content:**
```soql
SELECT Id, Title, Summary, UrlName, IsVisibleInApp, IsVisibleInCsp
FROM Knowledge__kav
WHERE PublishStatus = 'Online'
  AND Language = 'en_US'
```

**Correct pattern to delete an article (requires deleting the parent `__ka`):**
```soql
SELECT Id FROM Knowledge__ka WHERE ArticleNumber = '000001234'
-- then: delete ka;  (requires Modify All on Knowledge)
```

> **Source:** salesforce_knowledge_dev_guide.pdf, pages 2-6 (Knowledge Object Model chapter).

---

## G-37: Knowledge Edition Article Limits Are Per-Org, Not Per-Version

**What happens:** Article limits are per-article (not per-version), but total version count = articles × retained versions × translations. An org can exhaust storage before hitting article count limits in multilingual, multi-version environments.

**Edition limits (confirmed):**
- Essentials/Professional: 500 articles, 10 versions/article, 1 language
- Enterprise/Developer: 50,000 articles, 10 versions/article, 5 languages
- Unlimited: 150,000 articles, 10 versions/article, 10 languages

**Caveat on version limits:** Versions attached to cases or work orders do NOT count against the 10-version-per-article limit, but DO count against org-total version limits. An article could legitimately have 25+ versions if 15 are case-attached.

**Monitor via:** Setup → Storage Usage → "Knowledge" (articles) and "Knowledge Versions" (versions).

> **Source:** lightning_knowledge_guide.pdf, pages 6-8 (Knowledge Scalability section).

---

## G-38: Archiving Lightning Knowledge Articles Cannot Be Scheduled for Future Date

**What happens (confirmed from lightning_knowledge_guide.pdf):** In Lightning Knowledge, you cannot schedule article archival for a future date. Archiving only happens immediately. This is different from Classic Knowledge, which supported scheduled archival.

**Fix:** Build a Scheduled Flow to periodically archive articles based on a date field:
```
Scheduled Flow — runs daily
  Filter: ExpirationDate__c <= TODAY AND PublishStatus = 'Online'
  Action: Invoke KbManagement.PublishingService.archiveOnlineArticle()
```

> **Source:** lightning_knowledge_guide.pdf, page 11 (General Usage Limitations section).

---

## G-39: SOS Video Chat Is Salesforce Classic Only — Not Available in Lightning

**What happens:** SOS (Service Cloud Snap-ins video chat + screen-sharing for mobile apps) is available only in **Salesforce Classic**. It is part of Service Cloud Snap-ins for Mobile Apps and requires a separate SOS license (available at additional cost on Enterprise/Performance/Unlimited/Developer). It does not work in Lightning Experience.

**Impact:** Do not scope SOS for orgs running Lightning-only. For video/screen-sharing in Lightning environments, use a third-party ISV solution or Service Cloud Voice with a partner that supports video.

> **Source:** sos_administrators.pdf, page 1: "Available in: Salesforce Classic."
