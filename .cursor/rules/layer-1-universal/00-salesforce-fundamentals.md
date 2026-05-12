---
name: Salesforce Fundamentals
layer: 1
type: universal-foundation
composable: true
requires: []
alwaysApply: true
tags: [salesforce, platform, governor-limits, soql, objects]
---

# Salesforce Fundamentals (Layer 1 - Universal Foundation)

This rule provides the foundational knowledge of the Salesforce platform that ALL employees must understand and apply.

## Core Platform Concepts

### Salesforce Data Model

**Objects**: Salesforce stores data in objects (similar to database tables)
- **Standard Objects**: Pre-built by Salesforce (Account, Contact, Opportunity, Case, Lead, etc.)
- **Custom Objects**: Created by developers/admins (suffix: `__c`)
  - Example: `Custom_Product__c`, `Order_Line_Item__c`
- **External Objects**: Connect to external data sources (suffix: `__x`)
- **Platform Events**: Publish-subscribe events for async integration (suffix: `__e`)

**Fields**: Columns in objects that store specific data
- **Field Types**: Text, Number, Date, DateTime, Picklist, Checkbox, Currency, Formula, Rollup Summary, Lookup, Master-Detail
- **Custom Fields**: Created by developers/admins (suffix: `__c`)
  - Example: `Discount_Amount__c`, `Total_Price__c`
- **System Fields**: Automatically maintained by Salesforce
  - `Id`, `CreatedDate`, `CreatedById`, `LastModifiedDate`, `LastModifiedById`, `SystemModstamp`

**Relationships**: Connect objects together
- **Lookup**: Loosely coupled relationship (1-to-many)
  - Example: Account ← Contact (a Contact looks up to an Account)
  - Parent deletion doesn't cascade to children
- **Master-Detail**: Tightly coupled relationship (1-to-many)
  - Example: Account ← Order (an Order is master-detail to Account)
  - Parent deletion cascades to children
  - Child inherits parent's sharing rules
  - Enables rollup summary fields on parent
- **Many-to-Many**: Junction object with two master-detail relationships
  - Example: Student ← Student_Class__c → Class

**Record Types**: Enable multiple UI layouts and picklist values per object
- Different page layouts for different user groups
- Different picklist values based on record type
- Example: "Standard Account" vs "Partner Account" record types

---

## Governor Limits (CRITICAL)

**Principle**: Salesforce is a multi-tenant platform. ALL tenants share the same infrastructure. Governor limits prevent any one tenant from monopolizing resources.

### Per-Transaction Limits

A "transaction" is a single execution context (e.g., one trigger execution, one Apex REST call, one Flow execution).

**SOQL Queries**:
- Synchronous: **100 queries** per transaction
- Asynchronous (Batch, Queueable, Future, Scheduled): **200 queries** per transaction

**DML Statements**:
- **150 DML statements** per transaction
- Examples: `insert`, `update`, `delete`, `undelete`, `upsert`, `merge`

**DML Rows**:
- **10,000 total rows** per transaction
- Counted across ALL DML operations (inserts + updates + deletes)

**Heap Size** (Memory Usage):
- Synchronous: **6 MB**
- Asynchronous: **12 MB**

**CPU Time** (Execution Time):
- Synchronous: **10,000 ms** (10 seconds)
- Asynchronous: **60,000 ms** (60 seconds)

**Callouts** (HTTP/SOAP requests to external systems):
- **100 callouts** per transaction
- **120 seconds** maximum per callout
- **12 MB** maximum response size

**SOSL Queries** (Full-text search):
- **20 SOSL queries** per transaction

### Daily Limits

**API Calls**:
- Varies by Salesforce edition
- Professional: 1,000 per user/day (max 15,000)
- Enterprise: 1,000 per user/day (max 1,000,000)
- Unlimited: 1,000 per user/day (unlimited)

**Batch Apex**:
- **250,000 batch jobs** per 24 hours
- **5 concurrent batch jobs** per org

**Platform Events**:
- Enterprise: 250,000 events per 24 hours
- Unlimited: 1,000,000 events per 24 hours

**Email**:
- **5,000 single emails** per day
- **10 mass emails** per day (up to 5,000 contacts each)

### Design Principle: ALWAYS Bulk

**❌ BAD: Single-record processing**
```apex
trigger AccountTrigger on Account (after insert) {
    for (Account acc : Trigger.new) {
        // Query inside loop (N+1 query pattern)
        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
        // DML inside loop
        insert new Opportunity(Name = 'New Opp', AccountId = acc.Id);
    }
}
// Problem: 200 Accounts = 200 SOQL queries + 200 DML operations (governor limit exceeded!)
```

**✅ GOOD: Bulk processing**
```apex
trigger AccountTrigger on Account (after insert) {
    List<Opportunity> oppsToInsert = new List<Opportunity>();

    for (Account acc : Trigger.new) {
        oppsToInsert.add(new Opportunity(Name = 'New Opp', AccountId = acc.Id));
    }

    // Single DML operation (bulk insert)
    if (!oppsToInsert.isEmpty()) {
        insert oppsToInsert;
    }
}
// Solution: 200 Accounts = 1 DML operation (well within limits!)
```

**Standard**: Design for **200+ records** per transaction. If it works for 200, it works for production.

---

## SOQL (Salesforce Object Query Language)

### Best Practices

**1. SELECT Only Fields You Need**
```apex
// ❌ BAD: Selects all fields (performance impact, heap size)
List<Account> accounts = [SELECT FIELDS(ALL) FROM Account];

// ✅ GOOD: Select specific fields
List<Account> accounts = [SELECT Id, Name, Industry, BillingCity FROM Account];
```

**2. Use WHERE Clause with Indexed Fields**

**Indexed Fields** (automatically indexed):
- `Id`, `Name`, `OwnerId`, `CreatedDate`, `SystemModstamp`
- External ID fields
- Custom fields with "Unique" or "External ID" attributes

```apex
// ✅ GOOD: Filter by indexed field
List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :accountId];

// ⚠️ OK, but slower: Filter by non-indexed field
List<Account> accounts = [SELECT Id, Name FROM Account WHERE Custom_Field__c = 'Value'];
```

**3. Use LIMIT for Large Datasets**
```apex
// ❌ BAD: Could return millions of records (heap size limit!)
List<Account> accounts = [SELECT Id, Name FROM Account];

// ✅ GOOD: Limit to manageable size
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1000];
```

**4. Avoid N+1 Query Pattern**
```apex
// ❌ BAD: Query inside loop
List<Account> accounts = [SELECT Id FROM Account LIMIT 100];
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id]; // 100 queries!
}

// ✅ GOOD: Relationship query OR collect IDs and query once
// Option 1: Relationship query
List<Account> accounts = [SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 100];

// Option 2: Collect IDs and query once
List<Account> accounts = [SELECT Id FROM Account LIMIT 100];
Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]; // 1 query!
```

**5. Use Aggregate Functions**
```apex
// Get count of Contacts per Account
AggregateResult[] results = [
    SELECT AccountId, COUNT(Id) contactCount
    FROM Contact
    GROUP BY AccountId
];

// Use SUM, MAX, MIN, AVG
AggregateResult[] results = [
    SELECT AccountId, SUM(Amount) totalAmount, AVG(Amount) avgAmount
    FROM Opportunity
    WHERE StageName = 'Closed Won'
    GROUP BY AccountId
];
```

**6. Relationship Queries**
```apex
// Parent-to-Child (1-to-many)
List<Account> accounts = [
    SELECT Id, Name,
           (SELECT Id, FirstName, LastName FROM Contacts)
    FROM Account
];

// Child-to-Parent (many-to-1)
List<Contact> contacts = [
    SELECT Id, FirstName, LastName,
           Account.Name, Account.Industry
    FROM Contact
];
```

---

## Apex Basics

### Language Characteristics

**Strongly-Typed**: Must declare variable types
```apex
String name = 'John';
Integer count = 10;
Account acc = new Account(Name = 'Acme');
```

**Object-Oriented**: Classes, inheritance, interfaces, polymorphism
```apex
public class AccountService {
    public static void processAccounts(List<Account> accounts) {
        // Implementation
    }
}
```

**Multi-Tenant**: Runs on shared Salesforce servers
- Governor limits enforce fair resource usage
- All code must be bulkified

### Triggers

**Trigger Events**: `before insert`, `after insert`, `before update`, `after update`, `before delete`, `after delete`, `after undelete`

**Before Triggers**: Validate or modify records BEFORE saving to database
- Use `Trigger.new` to access records
- Can modify field values directly (no DML needed)

**After Triggers**: Perform actions AFTER records are saved
- Use `Trigger.new` for new values, `Trigger.old` for old values
- Cannot modify trigger records (read-only)
- Use for creating related records, callouts, etc.

**Best Practice**: One trigger per object, delegate logic to handler class
```apex
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    AccountTriggerHandler.handle();
}
```

### Context Variables

- `Trigger.new`: List of new versions of records
- `Trigger.old`: List of old versions of records (update/delete only)
- `Trigger.newMap`: Map of new versions (Id → Record)
- `Trigger.oldMap`: Map of old versions (Id → Record)
- `Trigger.isInsert`, `Trigger.isUpdate`, `Trigger.isDelete`, `Trigger.isUndelete`
- `Trigger.isBefore`, `Trigger.isAfter`

---

## Platform Features

### Declarative Tools (Click, Not Code)

**Flows**: Powerful automation tool (record-triggered, scheduled, screen flows)
**Process Builder** (Legacy): Automate actions when records change
**Workflow Rules** (Legacy): Simple automation (field updates, email alerts)
**Validation Rules**: Enforce data quality (e.g., "End Date must be after Start Date")
**Formula Fields**: Calculated fields (e.g., `Full_Name__c = FirstName + ' ' + LastName`)
**Rollup Summary Fields**: Aggregate child records (e.g., SUM of Order amounts on Account)
**Approval Processes**: Multi-step approval workflows

### Asynchronous Processing

Use async Apex when:
- Long-running operations (avoid CPU timeout)
- External callouts (avoid blocking user)
- Large data volumes (higher governor limits)

**Queueable Apex**: Best for most async work
- Can chain jobs (queue another job from a job)
- Can pass complex types (not just primitives)
- Monitors progress in Setup → Apex Jobs

**Batch Apex**: Process millions of records
- Splits records into batches (default 200 per batch)
- Each batch has fresh governor limits
- Max 50 million records per job

**Scheduled Apex**: Run jobs on schedule (daily, weekly, etc.)
- Implements `Schedulable` interface
- Schedule via UI or `System.schedule()`

**Future Methods**: Legacy async pattern (use Queueable instead)
- `@future` annotation
- Only primitives and collections of primitives

**Platform Events**: Publish-subscribe event bus
- Decouple publishers from subscribers
- Async, scalable integration pattern

### Integration

**REST API**: Standard HTTP/JSON API
- Authentication: OAuth 2.0, Session ID
- Operations: Query, insert, update, delete, upsert
- Composite API for multiple operations in one request

**SOAP API**: XML-based API (legacy, but still used)
- WSDL-based (strongly-typed)
- Enterprise WSDL (org-specific) vs Partner WSDL (generic)

**Platform Events**: Publish-subscribe event bus
- Near real-time (seconds, not milliseconds)
- Durable (replays available for 72 hours)
- Use for async integration between systems

**Change Data Capture (CDC)**: Subscribe to data changes
- Automatically publishes events when records change
- Use for syncing data to external systems

**Streaming API**: Real-time event notifications
- PushTopic (SOQL-based subscriptions)
- Generic Streaming (custom events)

### UI Technologies

**Lightning Web Components (LWC)**: Modern, standards-based framework
- Web Components standard
- Fast, lightweight
- TypeScript support
- Use for NEW development

**Aura Components** (Legacy): Salesforce's original component framework
- Still supported, but LWC preferred for new work

**Visualforce** (Legacy): Server-side rendered pages
- MVC pattern
- Use only for complex PDF generation or when LWC isn't sufficient

---

## Key Takeaways

**1. Design for Bulk**: ALWAYS assume 200+ records per transaction
**2. Respect Governor Limits**: Monitor SOQL queries, DML operations, CPU time, heap size
**3. Use Indexed Fields**: WHERE clauses on indexed fields = fast queries
**4. One Trigger Per Object**: Use handler pattern for maintainability
**5. Declarative First**: Evaluate Flows/Validation Rules before writing code
**6. Async When Needed**: Use Queueable/Batch for long-running or high-volume operations
**7. Test Everything**: 75% minimum coverage, aim for 85%+

---

**Applies to**: All Salesforce developers (Apex, LWC, Integrations, Data, Admin)
