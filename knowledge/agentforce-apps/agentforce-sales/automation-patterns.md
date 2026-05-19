---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Sales Cloud — Automation Patterns

---

## Lead Lifecycle Automation

### Pattern: Lead Assignment Rules → Queue → Convert

**Declarative (preferred):**

1. **Assignment Rules** (Setup > Lead Assignment Rules): Criteria-based rules assign leads to User or Queue. Rules evaluate in order; first match wins. Only one Assignment Rule set can be active at a time.
2. **Lead Queue**: Unassigned leads pool into a queue. Queue members can claim from the queue list view.
3. **Auto-Response Rules**: Send acknowledgement email to lead on creation (e.g., web form submission). One Auto-Response Rule active at a time; first matching rule fires.
4. **Escalation Rules**: Escalate unworked leads after N hours. Assigns to escalation user/queue or sends email.

```
Web-to-Lead form submit
    → Lead created (AssignedOwner = queue or user via rule)
    → Auto-Response email to lead (Auto-Response Rule)
    → If not contacted in 48h → Escalate (Escalation Rule)
    → Rep works lead → Status = 'Working - Contacted'
    → Rep qualifies → convertLead() → Account + Contact + Opportunity
```

**Round-robin assignment (no native support):** Requires Apex. Pattern: Custom object `RoundRobinAssignment__c` tracks `CurrentIndex__c` per queue; Apex trigger on Lead reads index, assigns next user, increments.

### Pattern: Lead Scoring Flow

**When to use native scoring vs Einstein:**
- Einstein Lead Scoring: Available with Sales Cloud Einstein license; ML model trained on org's own conversion history. Requires 1,000+ leads with 120+ converted in last 2 years.
- Custom scoring: Formula field or Record-Triggered Flow accumulating score points based on activity, demographic, and engagement signals.

**Custom scoring formula pattern:**
```
// Formula field: Lead_Score__c
(IF(ISPICKVAL(Rating, 'Hot'), 30, IF(ISPICKVAL(Rating, 'Warm'), 15, 0))
+ IF(NOT(ISBLANK(Email)), 10, 0)
+ IF(AnnualRevenue > 1000000, 20, IF(AnnualRevenue > 100000, 10, 0))
+ IF(ISPICKVAL(LeadSource, 'Web'), 15, IF(ISPICKVAL(LeadSource, 'Partner Referral'), 25, 5)))
```

**Flow-based score update on activity:** Record-Triggered Flow on Task (AFTER INSERT) when WhoId is a Lead — update Lead.Score__c formula inputs or a numeric scoring field.

---

## Opportunity Stage Progression

### Pattern: Stage Gate Validation

Use **Validation Rules** (not Flow) for "required fields before advancing stage":

```
// Requires Amount before advancing past Proposal
AND(
  ISPICKVAL(StageName, 'Proposal/Price Quote'),
  ISBLANK(Amount)
)
→ Error: "Amount is required before moving to Proposal stage."

// Requires Close Date to be in the future for active stages
AND(
  NOT(IsClosed),
  CloseDate < TODAY()
)
→ Error: "Close Date cannot be in the past for open opportunities."
```

### Pattern: Stage Transition Record-Triggered Flow

**Trigger:** Opportunity, BEFORE SAVE, fires when `StageName` changes.

```
Flow: Stage_Transition_Handler

Decision: Stage changed from X to Y?
  Branch: → 'Closed Won'
    Action: Set CloseDate = TODAY()
    Action: Set Probability = 100
    Action: Create Task (AFTER save; use separate AFTER flow or platform event)
  Branch: → 'Negotiation/Review'
    Action: Send approval request email to manager
  Branch: → any Closed stage
    Action: Set Closed_Reason__c if blank
```

**Anti-patterns to avoid:**
- Do not use Workflow Rules for stage transitions — deprecated, limited capability
- Do not create Tasks in BEFORE-SAVE flows — Task insert requires Opportunity ID which exists after insert

### Pattern: Auto-Close Stale Opportunities (Scheduled Flow)

```
Flow: Auto_Close_Stale_Opportunities
Type: Scheduled (runs daily at 8pm)

Get Records: Opportunities WHERE
  IsClosed = false
  AND CloseDate < TODAY() - 90  (3 months past due)
  AND LastActivityDate < TODAY() - 60  (no recent activity)
  AND Auto_Exclude__c = false

Loop each Opportunity:
  Update Record: StageName = 'Closed Lost', Closed_Reason__c = 'Auto-closed: stale'
  Create Task: Subject = 'Auto-closed - review required', Status = 'Open', OwnerId = opp.OwnerId
```

**Warning:** Test with a small subset first. Notify sales reps before enabling. Include an `Auto_Exclude__c` checkbox for exceptional cases.

### Pattern: Opportunity Approval Process for Discounts

```
Approval Process: Opportunity_Discount_Approval
Object: Opportunity
Entry Criteria: Discount__c > 20 AND NOT(IS_APPROVED__c)

Initial Submitters: Opportunity Owner
Step 1: Assigned to = Opportunity.Owner.Manager
  - Approve → notify Owner
  - Reject → notify Owner with comments
Step 2 (if Discount > 40%): Assigned to = VP_Sales_Queue
  - Approve → set IS_APPROVED__c = true, send DocuSign (Apex action)
  - Reject → notify Owner with comments

Recall Condition: StageName = 'Closed Lost' (auto-recall on loss)
```

---

## Account Team Auto-Assignment

### Pattern: Auto-Add Account Team on Opportunity Stage Change

**Trigger:** Record-Triggered Flow on Opportunity, AFTER SAVE, when Stage changes to "Negotiation/Review".

```
Flow: Auto_Add_Account_Team_On_Negotiation

Decision: Stage = 'Negotiation/Review' AND Stage previously != 'Negotiation/Review'
  → True:
    Get Related Record: Account.Solutions_Engineer__c (custom lookup to User)
    If Solutions_Engineer__c is not null:
      Create Record: AccountTeamMember
        AccountId = Opportunity.AccountId
        UserId = Solutions_Engineer__c value
        TeamMemberRole = 'Solutions Engineer'
        AccountAccessLevel = 'Read'
        OpportunityAccessLevel = 'Edit'
        CaseAccessLevel = 'None'
```

**Note:** `AccountTeamMember` insert requires Account Team Selling enabled in Setup. Duplicate team member inserts throw DUPLICATE_VALUE error — check existing team members before inserting.

---

## Opportunity Split Automation

### Pattern: Auto-Create Revenue Split on New Opportunity

**When:** Opportunity is created with a custom "Channel Deal" record type. Auto-add channel manager as 20% overlay split.

```apex
// Apex trigger: OpportunityAfterInsert
trigger OpportunityTrigger on Opportunity (after insert) {
    List<Opportunity> channelOpps = new List<Opportunity>();
    for (Opportunity o : Trigger.new) {
        if (o.RecordTypeId == CHANNEL_RT_ID && o.Channel_Manager__c != null) {
            channelOpps.add(o);
        }
    }
    if (!channelOpps.isEmpty()) {
        OpportunitySplitService.createOverlaySplits(channelOpps);
    }
}

// Service class
public class OpportunitySplitService {
    public static void createOverlaySplits(List<Opportunity> opps) {
        Id overlayTypeId = [SELECT Id FROM OpportunitySplitType
                            WHERE DeveloperName = 'OverlaySplit' LIMIT 1].Id;
        List<OpportunitySplit> splits = new List<OpportunitySplit>();
        for (Opportunity o : opps) {
            splits.add(new OpportunitySplit(
                OpportunityId = o.Id,
                SplitOwnerId = o.Channel_Manager__c,
                SplitTypeId = overlayTypeId,
                SplitPercentage = 20
            ));
        }
        insert splits;
    }
}
```

**Prerequisite:** Opportunity Splits must be enabled. The Revenue split (totalling 100%) is managed separately — the above creates an Overlay split that can exceed 100% total.

---

## Territory Assignment Automation

### Manual Assignment
Via UI: Account record → Territory (related list) → Add Territory. Or data loader insert to `ObjectTerritory2Association`.

### Rule-Based Assignment
Territory Assignment Rules (Setup > Territory Models > Model > Assignment Rules):
- Criteria on Account fields (BillingState, Industry, AnnualRevenue, custom fields)
- Run rules: Preview → Activate → Run Rules (assigns accounts matching criteria to territories)
- Rules re-run automatically when Account fields referenced in rules change

### Pattern: Batch Assignment for Initial Load

See `api-reference.md` for Apex Batch pattern. Use after Territory Model activation for bulk assignment of existing accounts.

### Pattern: Triggered Re-Assignment on Account Update

```
Flow: Territory_Reassignment_Signal
Trigger: Account, AFTER SAVE, when BillingState or Industry changes

Action: Publish Platform Event Territory_Reassignment_Request__e
  Account_Id__c = Account.Id

// Separate Flow or Apex listener processes event and:
// 1. Deletes existing ObjectTerritory2Associations for this account
// 2. Re-evaluates territory criteria
// 3. Inserts new ObjectTerritory2Associations
```

**Caution:** Deleting and reinserting territory associations affects sharing immediately — test impact on rep access before deploying.

---

## Forecast Rollup Patterns

### Standard Rollup (Native)
Collaborative Forecasting automatically rolls up Opportunity amounts through Role or Territory hierarchy based on `ForecastCategoryName` field. No custom code needed.

### Pattern: Custom Forecast Metric (e.g., Weighted Pipeline by Product Family)

```soql
// Scheduled Apex or Flow populates custom Summary__c records
SELECT Product2.Family,
       SUM(Amount * Probability / 100) WeightedAmount,
       SUM(Amount) TotalPipeline,
       CALENDAR_QUARTER(CloseDate) FiscalQtr,
       CALENDAR_YEAR(CloseDate) FiscalYr
FROM OpportunityLineItem
WHERE Opportunity.IsClosed = false
  AND Opportunity.CloseDate = THIS_QUARTER
GROUP BY Product2.Family, CALENDAR_QUARTER(CloseDate), CALENDAR_YEAR(CloseDate)
```

### Pattern: Quota Attainment Tracking

```apex
// Compare ForecastingQuota to closed Opportunities
Map<Id, Decimal> quotaByUser = new Map<Id, Decimal>();
for (ForecastingQuota q : [
    SELECT AssignedToId, QuotaAmount
    FROM ForecastingQuota
    WHERE StartDate = :qtrStart
      AND ForecastingType.DeveloperName = 'OpportunityRevenue'
]) {
    quotaByUser.put(q.AssignedToId, q.QuotaAmount);
}

for (AggregateResult ar : [
    SELECT OwnerId, SUM(Amount) Closed
    FROM Opportunity
    WHERE IsWon = true
      AND CloseDate >= :qtrStart AND CloseDate <= :qtrEnd
    GROUP BY OwnerId
]) {
    Id ownerId = (Id) ar.get('OwnerId');
    Decimal closed = (Decimal) ar.get('Closed');
    Decimal quota = quotaByUser.get(ownerId);
    Decimal attainment = (quota != null && quota > 0) ? (closed / quota * 100) : 0;
    // Update user's quota attainment record
}
```

---

## Sales Engagement (High Velocity Sales) Automation

### Cadence Architecture

```
Cadence (ActionCadence)
    │
    └─► Cadence Steps (ActionCadenceStep)
           │  Step 1: Send Email (EmailMessage template)
           │  Step 2: Wait 2 days
           │  Step 3: Log Call (Task)
           │  Step 4: Wait 1 day
           │  Step 5: LinkedIn message step (if Sales Navigator integrated)
           └─► Cadence Tracker (ActionCadenceTracker) — links Target (Lead/Contact) to Cadence
```

### Work Queue
Surfaces all pending cadence steps for the assigned rep as a prioritized queue. Steps appear at the scheduled time. Reps complete steps (send email, log call) directly from the Work Queue.

### Pattern: Auto-Enroll Converted Leads into Nurture Cadence

```apex
// Apex after Lead convert: enroll new Contact into cadence
trigger LeadConvertTrigger on Lead (after update) {
    for (Lead l : Trigger.new) {
        if (l.IsConverted && !Trigger.oldMap.get(l.Id).IsConverted) {
            // Use ConnectApi or Platform Event to enroll Contact in cadence
            // Direct DML on ActionCadenceTracker is available in Apex
            ActionCadenceTracker tracker = new ActionCadenceTracker(
                ActionCadenceId = NURTURE_CADENCE_ID,
                TargetId = l.ConvertedContactId,
                AssignedToId = l.OwnerId
            );
            insert tracker;
        }
    }
}
```

**Note:** `ActionCadenceTracker` DML available in Apex. Check that the Cadence is Active before inserting tracker.

---

## Quote Sync Automation

### Pattern: Auto-Start Quote Sync on Quote Approval

```
Flow: Auto_Sync_Quote_After_Approval
Trigger: Quote, AFTER UPDATE, when Status changes to 'Approved'

Decision: Status = 'Approved' AND IsSyncing = false
  → True:
    Update Record: Quote.IsSyncing = true
    (Salesforce automatically stops any other syncing Quote for the same Opportunity)
```

### Pattern: Quote PDF Generation on Quote Send

```
Flow: Generate_Quote_PDF_On_Send
Trigger: Quote, AFTER UPDATE, when Status changes to 'Presented'

Action: Apex action GenerateQuotePDF
  → Uses SOAP API QuoteDocument or standard Quote template PDF generation
  → Attaches ContentDocument to Quote record
  → Optionally emails PDF to Quote.Contact
```

**Alternative:** Use DocuSign eSignature or similar package for quote-to-e-sign flow.

### Quote Sync Conflict Warning Pattern

```
// Validation Rule on Opportunity: warn if Amount is edited while Quote syncing
AND(
  IsSyncing__c = true,  // Custom formula: ISBLANK(SyncedQuoteId) = false
  NOT(ISNEW())
)
→ Warning: "This Opportunity has an active syncing Quote. Edit amounts on the Quote, not here."
```

---

## Einstein Lead and Opportunity Scoring Patterns

### Einstein Lead Scoring
- **Licence:** Sales Cloud Einstein or Agentforce for Sales
- **Training:** Automatic; uses org's converted/not-converted Lead history (needs 1000+ leads, 120+ converted)
- **Output field:** `Lead.Lead_Score__c` (API: `Lead.LeadScore` — system-managed, read-only)
- **Refresh:** Scores recalculated daily
- **When to use:** Org has sufficient lead conversion history; want ML-based prioritisation without custom formula maintenance
- **When NOT to use:** New org with insufficient history; highly regulated industry with model explainability requirements

### Einstein Opportunity Scoring
- **Output field:** `Opportunity.OpportunityScore` (system-managed) + `ScoringReasons` (text)
- **Insights:** "Deal is at risk," "No activity in 14 days," "Competitor mentioned in email"
- **Action:** Configure Signal rules to trigger tasks/alerts when score drops below threshold

```
// Flow: Alert manager when Opp score drops
Trigger: Opportunity, AFTER UPDATE, when OpportunityScore changes
Decision: OpportunityScore < 50 AND OpportunityScore was >= 50
  → Create Task: "Deal health alert - score dropped" assigned to Owner's Manager
  → Send Email: to Owner with link to Opportunity
```

---

## Pipeline Inspection Automation

### Signals Configuration
Pipeline Inspection uses "Change Metrics" from Opportunity history. No custom Apex needed. Configure:
- Which fields are tracked as change metrics (StageName, Amount, CloseDate, ForecastCategory)
- Alert thresholds for "at-risk" signals

### Pattern: Weekly Pipeline Review Reminder

```
Flow: Weekly_Pipeline_Review_Reminder
Type: Scheduled (Monday 7am)

Get Records: Opportunities WHERE
  IsClosed = false
  AND LastModifiedDate < TODAY() - 7  (not touched in 7 days)
  AND CloseDate <= THIS_QUARTER_END

Loop: Send Custom Notification to OwnerId
  Subject: "Stale opportunity needs update"
  Target: Opportunity record page
```

---

## Revenue Intelligence Data Pipeline

### Setup Pattern

1. Enable CRM Analytics (Einstein Analytics) in Setup
2. Install Revenue Intelligence app from AppExchange (included in Einstein 1)
3. Configure Data Pipeline: Setup > Revenue Intelligence > Data Pipeline
   - Select which orgs to sync (production, sandbox)
   - Configure sync schedule (daily recommended)
   - Map custom fields to Revenue Intelligence dimensions
4. Run initial data pipeline sync (can take 2-4 hours for large orgs)
5. Assign Revenue Intelligence permission sets to users

### Data Refresh Cadence
- Full refresh: weekly (configurable)
- Incremental refresh: daily
- Near-real-time signals: require Direct Data or Data Cloud integration

### Pattern: Custom KPI in Revenue Intelligence
Extend pre-built Revenue Intelligence dashboards using SAQL (Salesforce Analytics Query Language) in CRM Analytics. Do not modify the managed package dashboards — clone them first.

```saql
// Example: Win rate by territory
q = load "OpportunityDataset";
q = filter q by 'IsClosed' == "true";
q = group q by 'Territory2.Name', 'IsWon';
q = foreach q generate
    'Territory2.Name' as 'Territory',
    'IsWon' as 'IsWon',
    count() as 'Count';
```

---

## Seller Home Configuration

### Pattern: Configure Seller Home per Sales App

Seller Home is configured as a Lightning Home Page assigned to the Sales, Sales Console, or Sales Engagement app via the Lightning App Builder.

**Setup:**
1. Setup > Lightning App Builder > New Home Page
2. Choose "Home Page" type, assign to app (Sales, Sales Console, or Sales Engagement)
3. Add standard components: Pipeline Overview, Goals, Today's Events
4. Add Einstein Contact Suggestions component (requires EAC enabled)
5. Activate and assign to app

**Available Seller Home components:**
- **Pipeline Overview**: reads from open Opportunities by ForecastCategory; no custom config needed
- **Goals**: requires Collaborative Forecasting + quotas loaded in ForecastingQuota
- **Today's Events**: reads from user's calendar (EAC or native Salesforce Events)
- **Einstein Contact Suggestions**: requires EAC enabled; suggests contacts based on recent email/calendar activity
- **Recent Opportunities**: last-viewed Opportunities for the rep

**Note:** Seller Home components are standard — no custom LWC required. Each component observes the assigned user's OWD and sharing rules for data visibility.

---

## Personal Labels Automation

### Pattern: Bulk-Label Records from a List View

Personal Labels are user-private and not accessible via standard Apex DML (no public Apex API for PersonalLabel). Automation for Personal Labels is limited to:
- UI: Label from a list view (action button) or record page component
- Flow: Not supported — Personal Labels cannot be set by automated processes

**Design implication:** Do not build automation that creates or removes Personal Labels on behalf of users — this is not supported. Personal Labels are a user-driven productivity feature only.

---

## Duplicate Management

### Pattern: Duplicate Rules for Lead Import

```
Matching Rule: Lead_Duplicate_Match
  Match on: Email (exact) OR (FirstName + LastName + Company, fuzzy)
  
Duplicate Rule: Lead_Duplicate_Rule
  Action: Alert (not Block) for internal data entry
  Action: Block for external sources (Web-to-Lead, API inserts)
  Report: Log all duplicates to Duplicate_Exception__c custom object
```

**Best practice:** During data migration, set Duplicate Rule to "Allow" + report only. Re-enable blocking post-migration. `Database.DuplicateError` handling in Apex:

```apex
Database.SaveResult[] results = Database.insert(leads, false);
for (Database.SaveResult sr : results) {
    if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
            if (err instanceof Database.DuplicateError) {
                Database.DuplicateError dupErr = (Database.DuplicateError) err;
                Datacloud.FindDuplicatesResult findDupRes = dupErr.getDuplicateResult();
                // Log or handle; never silently discard
            }
        }
    }
}
```
