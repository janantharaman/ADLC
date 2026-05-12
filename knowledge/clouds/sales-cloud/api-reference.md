---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: api-reference
last-updated: 2026-05-11
---

# Sales Cloud — API Reference

---

## Web-to-Lead HTML Form

Web-to-Lead is a form-post mechanism (not a REST API). Leads are created by POSTing an HTML form to `https://webto.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8`.

### Required Hidden Fields

```html
<input type="hidden" name="oid" value="{orgId}">
<input type="hidden" name="retURL" value="https://yoursite.com/thank-you">
```

### Debug Mode (Sandbox Testing)

Add this hidden field to see a debug response page instead of redirecting to retURL. Shows field mapping, org ID validation, and any assignment rule evaluation:

```html
<input type="hidden" name="debug" value="1">
<input type="hidden" name="debugEmail" value="admin@yourorg.com">
```

Remove the `debug` field before go-live — it will show the debug page to real users.

### Key Limits (Spring '26)

| Limit | Value | Notes |
|---|---|---|
| Submissions per 24-hour period | **500** | Hard limit; excess submissions are silently discarded |
| Admin notification on reject | First 5 rejections | After 5, admin is not notified again until next rejection batch |
| Pending queue (Web-to-Lead + Web-to-Case combined) | **50,000 records** | New submissions rejected if queue exceeds 50,000 unprocessed |
| Field mapping | Declarative in Setup > Lead Fields > Map Lead Fields | Unmapped custom fields not passed through |

### Supported Field Types
Standard Lead fields are passable directly by field API name. Custom fields use the full API name with `__c`. Example:
```html
<input type="text" name="first_name" value="Jane">
<input type="text" name="last_name" value="Doe">
<input type="text" name="email" value="jane@example.com">
<input type="text" name="company" value="Acme Corp">
<input type="text" name="lead_source" value="Web">
<input type="text" name="Custom_Field__c" value="custom value">
```

---

## Lead Conversion API

### `Database.convertLead()`

The primary Apex method for converting Leads programmatically.

```apex
// Minimal conversion
LeadConvert lc = new LeadConvert();
lc.setLeadId(leadId);
lc.setConvertedStatus('Closed - Converted'); // Must be a "converted" status value
lc.setDoNotCreateOpportunity(false);         // Set true to skip Opp creation
lc.setOpportunityName('Account Name - Deal Name');
lc.setOwnerId(userId);                       // Optional; defaults to lead owner

// Merge into existing Account and Contact
lc.setAccountId(existingAccountId);
lc.setContactId(existingContactId);

Database.LeadConvertResult result = Database.convertLead(lc);

if (result.isSuccess()) {
    Id newAccountId = result.getAccountId();
    Id newContactId = result.getContactId();
    Id newOpportunityId = result.getOpportunityId(); // Null if doNotCreateOpportunity = true
} else {
    for (Database.Error err : result.getErrors()) {
        System.debug(err.getMessage());
    }
}
```

**Bulk conversion:**
```apex
List<Database.LeadConvert> conversions = new List<Database.LeadConvert>();
// ... populate list
List<Database.LeadConvertResult> results = Database.convertLead(conversions);
```

### LeadConvert Input Parameters

| Method | Type | Description |
|---|---|---|
| `setLeadId(Id)` | Id | Required. The Lead to convert. |
| `setConvertedStatus(String)` | String | Required. A picklist value with IsConverted=true. |
| `setAccountId(Id)` | Id | Merge into existing Account; omit to create new. |
| `setContactId(Id)` | Id | Merge into existing Contact; omit to create new. |
| `setOpportunityId(Id)` | Id | Merge into existing Opportunity (rare). |
| `setOpportunityName(String)` | String | Name for new Opportunity; defaults to Company. |
| `setDoNotCreateOpportunity(Boolean)` | Boolean | True to skip Opportunity creation. |
| `setOwnerId(Id)` | Id | Owner for created records; defaults to lead owner. |
| `setSendNotificationEmail(Boolean)` | Boolean | Send assignment email on convert. |
| `setBypassAccountDeduplication(Boolean)` | Boolean | Skip account duplicate check (v52+). |
| `setBypassContactDeduplication(Boolean)` | Boolean | Skip contact duplicate check (v52+). |

### Field Mapping Behaviour on Convert

- Standard Lead fields map to standard Account/Contact/Opportunity fields automatically
- Custom Lead fields map **only** if explicitly configured in Setup > Lead Fields > Map Lead Fields
- Unmapped custom fields are silently dropped — no error, no warning
- If merging into existing Account/Contact, field values from Lead do **not** overwrite existing values by default

### Governor Limit Interaction
- Each `convertLead()` call counts as DML — bulk convert in one call to stay within DML limits
- Conversion fires triggers on Account, Contact, and Opportunity — account for recursive trigger risks
- Duplicate rules fire during conversion; they can block conversion if set to "Block" action

---

## SOQL Patterns for Sales Cloud

### Pipeline Query (Open Opportunities by Stage)

```soql
SELECT StageName, COUNT(Id) NumOpps, SUM(Amount) TotalAmount
FROM Opportunity
WHERE IsClosed = false
  AND CloseDate >= THIS_QUARTER
  AND OwnerId IN :teamUserIds
GROUP BY StageName
ORDER BY SUM(Amount) DESC
```

### Opportunity with Line Items and Products

```soql
SELECT Id, Name, Amount, StageName, CloseDate,
       Account.Name, Owner.Name,
       (SELECT Id, Product2.Name, Product2.ProductCode, Quantity,
               UnitPrice, TotalPrice, PricebookEntry.Name
        FROM OpportunityLineItems
        ORDER BY SortOrder)
FROM Opportunity
WHERE Id = :opportunityId
```

### Opportunity with All Contacts (via OCR)

```soql
SELECT Id, Name,
       (SELECT ContactId, Contact.Name, Contact.Email, Role, IsPrimary
        FROM OpportunityContactRoles
        WHERE IsPrimary = true)
FROM Opportunity
WHERE AccountId = :accountId
  AND IsClosed = false
```

### Account with Full Sales Picture

```soql
SELECT Id, Name, Type, AnnualRevenue,
       (SELECT Id, Name, StageName, Amount, CloseDate, Probability
        FROM Opportunities
        WHERE IsClosed = false
        ORDER BY CloseDate ASC),
       (SELECT Id, LastName, FirstName, Email, Title
        FROM Contacts
        ORDER BY LastName),
       (SELECT Id, ActivityDate, Subject, Status
        FROM ActivityHistories
        WHERE ActivityDate >= LAST_N_DAYS:90
        ORDER BY ActivityDate DESC
        LIMIT 10)
FROM Account
WHERE Id = :accountId
```

### Campaign ROI Query

```soql
SELECT Id, Name, Type, Status,
       NumberOfLeads, NumberOfConvertedLeads,
       NumberOfContacts, NumberOfResponses,
       NumberOfOpportunities, NumberOfWonOpportunities,
       AmountWonOpportunities, ActualCost,
       (AmountWonOpportunities - ActualCost) ROI_Formula_Note
FROM Campaign
WHERE Status = 'Completed'
  AND EndDate >= LAST_N_MONTHS:12
ORDER BY AmountWonOpportunities DESC
```
> Note: ROI calculation must be done in code or a formula field; SOQL cannot compute cross-field arithmetic.

### Opportunity Forecast Rollup by Territory

```soql
SELECT Territory2.Name,
       SUM(Amount) TotalPipeline,
       SUM(CASE WHEN ForecastCategoryName = 'Commit' THEN Amount ELSE 0 END) CommitAmount
FROM Opportunity
WHERE IsClosed = false
  AND Territory2Id != null
  AND CloseDate = THIS_QUARTER
GROUP BY Territory2.Name
```
> Note: `Territory2Id` on Opportunity is available when ETM is enabled. This query requires aggregate SOQL support — validate in your API version.

### Lead Conversion Funnel Query

```soql
SELECT LeadSource, IsConverted,
       COUNT(Id) LeadCount
FROM Lead
WHERE CreatedDate >= THIS_YEAR
GROUP BY LeadSource, IsConverted
ORDER BY LeadSource, IsConverted
```

### Contacts to Multiple Accounts (AccountContactRelation)

```soql
SELECT Contact.Name, Contact.Email,
       AccountId, Account.Name, Roles, IsActive, IsDirect
FROM AccountContactRelation
WHERE ContactId = :contactId
ORDER BY IsDirect DESC
```

### ForecastingQuota Query

```soql
SELECT AssignedToId, AssignedTo.Name, StartDate,
       QuotaAmount, ProductFamily
FROM ForecastingQuota
WHERE StartDate >= :firstDayOfFiscalYear
  AND ForecastingType.DeveloperName = 'OpportunityRevenue'
ORDER BY AssignedTo.Name, StartDate
```

---

## Product Catalog Management — Upsert Patterns

### Upsert Products from ERP Sync

```apex
// Use External ID field for upsert key
List<Product2> products = new List<Product2>();
for (ERPProduct p : erpProducts) {
    products.add(new Product2(
        Name = p.name,
        ProductCode = p.sku,
        ExternalId__c = p.externalId,  // Custom External ID field
        Family = p.productFamily,
        IsActive = p.isActive,
        Description = p.description
    ));
}
Database.upsert(products, Product2.ExternalId__c, false);

// Then upsert Standard Pricebook Entries
Id stdPriceBookId = Test.isRunningTest()
    ? Test.getStandardPricebookId()
    : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

List<PricebookEntry> stdEntries = new List<PricebookEntry>();
// ... build entries with Product2Id from upsert results
Database.upsert(stdEntries, false);
```

### Creating Custom Pricebook Entries

```apex
// Custom PBE requires Standard PBE to exist first
List<PricebookEntry> customEntries = new List<PricebookEntry>();
for (PricebookEntry stdPbe : standardEntries) {
    customEntries.add(new PricebookEntry(
        Pricebook2Id = customPricebookId,
        Product2Id = stdPbe.Product2Id,
        UnitPrice = stdPbe.UnitPrice * 0.85,  // 15% channel discount
        IsActive = true,
        CurrencyIsoCode = 'USD'
    ));
}
insert customEntries;
```

---

## Batch Territory Assignment

### Pattern: Rule-based Territory Assignment via Apex Batch

```apex
global class TerritoryAssignmentBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, BillingState, Industry, AnnualRevenue
            FROM Account
            WHERE Territory2Id__c = null  // Custom field tracking assignment
            AND IsActive__c = true
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<ObjectTerritory2Association> associations = new List<ObjectTerritory2Association>();
        Map<String, Id> territoryByState = TerritoryService.getStateTerritoryMap();

        for (Account acc : accounts) {
            Id territoryId = territoryByState.get(acc.BillingState);
            if (territoryId != null) {
                associations.add(new ObjectTerritory2Association(
                    ObjectId = acc.Id,
                    Territory2Id = territoryId,
                    AssociationCause = 'Territory2Manual'
                ));
            }
        }
        insert associations;
    }

    global void finish(Database.BatchableContext bc) {}
}
```

**Governor limit note:** `ObjectTerritory2Association` DML counts toward standard DML limits. Batch size of 200 is appropriate. Territory rule evaluation (automated) can be triggered via the Territory2Model activation — separate from Apex batch.

---

## Forecast Hierarchy Queries

### Query All Forecast Subordinates for a Manager

```soql
// Standard Role-based: traverse UserRole hierarchy
SELECT Id, Name, UserRoleId, UserRole.Name, UserRole.ParentRoleId
FROM User
WHERE IsActive = true
  AND UserRole.ParentRoleId = :managerRoleId
```

### Aggregate Forecast by Period

```soql
SELECT OwnerId, Owner.Name,
       SUM(Amount) TotalAmount,
       SUM(CASE WHEN ForecastCategoryName = 'Commit' THEN Amount ELSE 0 END) Commit,
       SUM(CASE WHEN ForecastCategoryName = 'Best Case' THEN Amount ELSE 0 END) BestCase
FROM Opportunity
WHERE CloseDate >= :periodStart
  AND CloseDate <= :periodEnd
  AND IsClosed = false
GROUP BY OwnerId, Owner.Name
ORDER BY SUM(Amount) DESC
```

---

## Connect REST API — Sales Cloud Relevant Endpoints

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

### Composite API (for multi-object transactions)

`POST /services/data/v67.0/composite`

Use for creating Opportunity + OpportunityLineItems in a single round-trip:

```json
{
  "allOrNone": true,
  "compositeRequest": [
    {
      "method": "POST",
      "url": "/services/data/v67.0/sobjects/Opportunity",
      "referenceId": "NewOpp",
      "body": {
        "Name": "Acme Corp - Q2 Deal",
        "AccountId": "001xx000003GYqIAAW",
        "StageName": "Qualification",
        "CloseDate": "2026-06-30",
        "Amount": 50000,
        "Pricebook2Id": "01sxx000000POEAAA4"
      }
    },
    {
      "method": "POST",
      "url": "/services/data/v67.0/sobjects/OpportunityLineItem",
      "referenceId": "OLI1",
      "body": {
        "OpportunityId": "@{NewOpp.id}",
        "PricebookEntryId": "01uxx000000001ZAAQ",
        "Quantity": 5,
        "UnitPrice": 10000
      }
    }
  ]
}
```

### Lead Convert REST Endpoint

`POST /services/data/v67.0/sobjects/Lead/{leadId}`  
Lead conversion is not a REST endpoint — use the SOAP API `convertLead()` or Apex `Database.convertLead()`.

### Bulk API 2.0 for Lead Import

```
POST /services/data/v67.0/jobs/ingest
Content-Type: application/json

{
  "operation": "upsert",
  "object": "Lead",
  "externalIdFieldName": "External_ID__c",
  "contentType": "CSV",
  "lineEnding": "LF"
}
```

### Standard SObject REST for Opportunity

```
GET  /services/data/v67.0/sobjects/Opportunity/{id}
POST /services/data/v67.0/sobjects/Opportunity
PATCH /services/data/v67.0/sobjects/Opportunity/{id}

// With related records (Composite Graph or nested queries)
GET /services/data/v67.0/sobjects/Opportunity/{id}?fields=Id,Name,Amount,StageName,CloseDate
```

---

## Platform Events Relevant to Sales Cloud

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

Salesforce does not ship standard pre-built Platform Events for Sales Cloud objects (Opportunity, Lead, etc.). Sales Cloud automations use:

1. **Change Data Capture (CDC)**: Standard event channels for detecting record changes
2. **Custom Platform Events**: Common pattern for integration

### Change Data Capture — Sales Cloud Objects

Enable CDC for these objects in Setup > Change Data Capture:
- `OpportunityChangeEvent`
- `LeadChangeEvent`
- `AccountChangeEvent`
- `ContactChangeEvent`
- `OrderChangeEvent`

**CDC event fields:** `ChangeEventHeader` (contains `changeType`: CREATE/UPDATE/DELETE/UNDELETE, `changedFields`, `recordIds`), then the changed field values.

### SOQL on CDC Streams (via CometD / EMP API)

```apex
// Subscribe in Apex (via Trigger on ChangeEvent — available v46+)
trigger OpportunityChangeTrigger on OpportunityChangeEvent (after insert) {
    List<OpportunityChangeEvent> events = Trigger.new;
    for (OpportunityChangeEvent event : events) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        if (header.changeType == 'UPDATE') {
            List<String> changedFields = header.changedFields;
            if (changedFields.contains('StageName')) {
                // Handle stage change
            }
        }
    }
}
```

### Custom Platform Event Pattern for Closed Won Notification

```apex
// Define Platform Event: Opportunity_Closed_Won__e
// Fields: OpportunityId__c (Text), AccountName__c (Text), Amount__c (Currency)

// Publish from Record-Triggered Flow or Apex:
Opportunity_Closed_Won__e evt = new Opportunity_Closed_Won__e(
    OpportunityId__c = opp.Id,
    AccountName__c = opp.Account.Name,
    Amount__c = opp.Amount
);
EventBus.publish(evt);
```

---

## Governor Limit Interactions Specific to Sales Cloud

> **Source:** Platform knowledge (Spring '26) — verify against latest release notes.

### Lead Conversion

| Limit | Value | Impact |
|---|---|---|
| DML statements per transaction | 150 | `convertLead()` = 1 DML per call; bulk list = still 1 DML total |
| Triggers fired on conversion | 3+ | Account (insert or update), Contact (insert or update), Opportunity (insert if created) — each fires own trigger chain |
| Callouts blocked after conversion | Yes | Cannot make callouts in same transaction after DML (standard rule) |
| Duplicate rule processing | Inline | Adds to CPU time; 10,000 records/batch max before CPU timeout risk |

### Opportunity with Products

| Limit | Value | Impact |
|---|---|---|
| Products per Opportunity | 500 (soft limit) | Beyond 200 OLIs, UI degrades; Apex works but memory usage increases |
| Pricebook query per DML | 1 | Set `Pricebook2Id` on Opportunity before inserting OLIs or use same transaction carefully |
| Quote sync on high-volume OLI | N/A | Quote sync recalculates all QLIs on each save — expensive for 100+ line items |

### Forecasting

| Limit | Value | Impact |
|---|---|---|
| Forecast types per org | 4 | Max 4 active ForecastingType records; choose carefully (Revenue, Quantity, Product Family, Overlay) |
| Forecast hierarchy depth | Role hierarchy depth | No explicit limit but deep hierarchies (10+ levels) increase rollup latency |
| ForecastingQuota records | No documented limit | Quarterly loads of 1000+ users: use Bulk API 2.0 |

### Territory Management (ETM)

| Limit | Value | Impact |
|---|---|---|
| Territory models per org | 4 (Active: 1) | Only 1 Active Territory2Model at a time |
| Territories per model | 1,000 | Above this, rule evaluation performance degrades |
| Rules per territory | 5 | Each territory assignment rule limited to 5 filter criteria |
| ObjectTerritory2Association | No documented hard limit | Batch-assign; large orgs (100k+ Accounts) should use scheduled batch |

### Campaign Members

| Limit | Value | Impact |
|---|---|---|
| Campaign members per campaign | 200,000 | Above this, performance degrades in UI and reports |
| Bulk import via Data Loader | Standard Bulk API limits | 10 million records/rolling 24 hours |

---

## Key SOQL Anti-Patterns in Sales Cloud

| Anti-Pattern | Problem | Fix |
|---|---|---|
| `SELECT * FROM Opportunity` | Fetching all fields wastes heap; no SELECT * in SOQL anyway | Enumerate only needed fields |
| `SELECT Id FROM Opportunity WHERE Name LIKE '%deal%'` | Leading wildcard prevents index use; full table scan | Use indexed fields (Id, OwnerId, AccountId, CloseDate, StageName) |
| Nested SOQL in loop | Hits SOQL 100-query limit | Collect IDs, query once outside loop |
| Querying OLI without filtering Opportunity | Returns all OLIs across org | Always filter by `OpportunityId IN :oppIds` |
| Forecast rollup in trigger | Forecast rollup is async; triggering from Apex may cause stale reads | Use Scheduled Jobs or Platform Events for forecast recalculation signals |
| Querying `ForecastingItem` directly | Object not available in all API contexts | Use `ForecastingAdjustment` and Opportunity aggregations instead |
