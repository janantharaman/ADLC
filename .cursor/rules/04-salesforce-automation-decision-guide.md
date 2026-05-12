---
alwaysApply: true
---

# Salesforce Automation Decision Guide

Choosing the right automation tool is critical for maintainability, performance, and scalability. This guide helps you select between Flows, Process Builder, Workflow Rules, and Apex based on your requirements.

## Automation Tool Overview

| Tool | Status | Use Case | Complexity | Performance |
|------|--------|----------|------------|-------------|
| **Flows** | ✅ Current | Complex automation, UI, scheduled | Low to High | Good |
| **Apex** | ✅ Current | Custom logic, bulk operations, integrations | High | Excellent |
| **Process Builder** | ⚠️ Legacy | Simple automation (migrate to Flows) | Low to Medium | Fair |
| **Workflow Rules** | ⚠️ Legacy | Field updates, email alerts (migrate to Flows) | Low | Good |

**Salesforce Recommendation**: Use **Flows** for declarative automation, **Apex** for programmatic needs.

## Decision Flow

```
START
  │
  ├─ Can it be done declaratively (no-code/low-code)?
  │   ├─ YES → Use Flow
  │   └─ NO → Continue
  │
  ├─ Does it require complex logic or external integrations?
  │   ├─ YES → Use Apex
  │   └─ NO → Continue
  │
  ├─ Does it involve bulk operations (>10,000 records)?
  │   ├─ YES → Use Apex (Batch/Queueable)
  │   └─ NO → Continue
  │
  ├─ Is performance critical (milliseconds matter)?
  │   ├─ YES → Use Apex
  │   └─ NO → Use Flow
  │
  └─ Does it require UI interaction?
      ├─ YES → Use Screen Flow or LWC
      └─ NO → Use Record-Triggered Flow
```

## When to Use Flows

### ✅ Use Flows For:
- Record-triggered automation (before/after save)
- Field updates and validations
- Email alerts and notifications
- Creating related records
- Screen-based data collection
- Scheduled automation (daily/weekly tasks)
- Simple approval processes
- Integration with external systems (via invocable actions)
- No-code/low-code requirements

### Flow Types

#### 1. Record-Triggered Flows
**Use Case**: Automation when records are created, updated, or deleted

```
Trigger: When Account is created or updated
Condition: Industry equals 'Technology'
Action: Create default Contact
       Send email to Account Owner
       Update Account Rating to 'Hot'
```

**Best Practices**:
- Use "Fast Field Updates" for same-record updates (before save)
- Use "Actions and Related Records" for complex automation (after save)
- Set entry conditions to minimize executions
- Avoid recursion with conditions (e.g., "IsChanged" operator)

#### 2. Screen Flows
**Use Case**: Guided UI experiences for data entry or wizards

```
Screen 1: Collect Account information
Screen 2: Collect Contact information
Screen 3: Review and confirm
Final: Create Account and Contact
```

**Best Practices**:
- Use Lightning pages to embed flows
- Validate data at each screen
- Show progress indicator for multi-step flows
- Handle errors gracefully with error screens

#### 3. Scheduled Flows
**Use Case**: Time-based automation (daily cleanup, weekly reports)

```
Schedule: Daily at 2:00 AM
Query: Get all Opportunities closing today
Action: Send reminder email to owners
```

**Best Practices**:
- Schedule during off-peak hours
- Process in batches (use loops carefully)
- Monitor scheduled flow runs

#### 4. Autolaunched Flows
**Use Case**: Reusable automation called from other tools

```
Called by: Apex, Process Builder, another Flow
Input: Account Id
Logic: Calculate revenue, update fields
Output: Success/Failure status
```

**Best Practices**:
- Design for reusability
- Use input/output variables
- Handle errors and return status
- Create invocable methods in Apex if complex logic needed

### Flow Limitations
- **50 DML operations** per interview (flow execution)
- **100 SOQL queries** per interview
- **6 MB heap size**
- **Bulkification**: Flows process one record at a time in record-triggered context
- **Governor limits**: Share limits with Apex in the same transaction

### Flow Performance Tips
```
✓ Use "Get Records" with selective filters (indexed fields)
✓ Minimize loops (process collections when possible)
✓ Use Fast Field Updates for same-record changes
✓ Avoid unnecessary queries (reuse existing data)
✓ Test with realistic data volumes
✓ Consider Apex for bulk processing >1,000 records
```

## When to Use Apex

### ✅ Use Apex For:
- Complex business logic (nested conditions, calculations)
- Bulk operations (>10,000 records)
- External integrations (REST/SOAP callouts)
- Performance-critical operations
- Complex data transformations
- Governor limit optimization (bulkification)
- Custom REST/SOAP APIs
- Complex query logic (dynamic SOQL)
- Advanced error handling
- Recursive operations

### Apex Automation Types

#### 1. Triggers
**Use Case**: Record-triggered automation requiring complex logic

```apex
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    new AccountTriggerHandler().run();
}

// Handler class
public class AccountTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        // Complex logic: Update 5+ related objects based on multiple conditions
        AccountService.processAccountChanges(
            (List<Account>) Trigger.new,
            (Map<Id, Account>) Trigger.oldMap
        );
    }
}
```

**Best Practices**:
- One trigger per object
- Delegate to handler class
- Bulkify all logic
- Use service layer for business logic

#### 2. Batch Apex
**Use Case**: Process large data volumes (>10,000 records)

```apex
public class AccountUpdateBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Industry FROM Account WHERE CreatedDate = LAST_N_DAYS:365
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Process up to 200 records at a time
        for (Account acc : scope) {
            acc.Industry = 'Updated';
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        // Send completion email
    }
}

// Execute: Database.executeBatch(new AccountUpdateBatch(), 200);
```

#### 3. Queueable Apex
**Use Case**: Async operations with callouts, chaining

```apex
public class ExternalSystemSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Account> accounts;

    public ExternalSystemSyncQueueable(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        // Make callouts
        for (Account acc : accounts) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.example.com/sync');
            req.setMethod('POST');
            req.setBody(JSON.serialize(acc));

            Http http = new Http();
            HttpResponse res = http.send(req);
        }

        // Chain to next batch if needed
        if (accounts.size() > 100) {
            System.enqueueJob(new ExternalSystemSyncQueueable(nextBatch));
        }
    }
}
```

#### 4. @future Methods
**Use Case**: Simple async operations, callouts

```apex
public class NotificationService {
    @future(callout=true)
    public static void sendNotification(Id recordId) {
        // Make callout to external system
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.example.com/notify');
        req.setMethod('POST');

        Http http = new Http();
        HttpResponse res = http.send(req);
    }
}
```

#### 5. Invocable Methods (Flow Integration)
**Use Case**: Call Apex from Flows

```apex
public class AccountService {
    @InvocableMethod(label='Calculate Revenue' description='Calculates account revenue')
    public static List<Result> calculateRevenue(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            // Complex calculation logic
            Decimal revenue = performComplexCalculation(req.accountId);

            Result res = new Result();
            res.totalRevenue = revenue;
            results.add(res);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    public class Result {
        @InvocableVariable
        public Decimal totalRevenue;
    }
}
```

## Comparison: Flow vs Apex

| Criteria | Flow | Apex |
|----------|------|------|
| **Development Skill** | Admin/Low-Code | Developer/High-Code |
| **Maintenance** | Easy (visual) | Requires coding knowledge |
| **Performance** | Good for <1,000 records | Excellent for bulk operations |
| **Bulkification** | One record at a time | Handles 200+ records efficiently |
| **Testing** | Manual testing | Automated unit tests (75% coverage) |
| **Version Control** | XML metadata | Source code (Git-friendly) |
| **Debugging** | Debug logs, Flow Inspector | Detailed debug logs, breakpoints |
| **Complexity** | Low to Medium | Medium to High |
| **Callouts** | Via invocable actions | Native support |
| **Deployment** | Standard metadata | Standard metadata + tests |

## Migration Path: Legacy Tools to Modern

### Workflow Rules → Flows
```
Workflow Rule: Account field update on creation
↓
Record-Triggered Flow (Before Save):
  - Trigger: Account created
  - Action: Update fields (Fast Field Update)
```

### Process Builder → Flows
```
Process Builder: Create related Contact when Account created
↓
Record-Triggered Flow (After Save):
  - Trigger: Account created
  - Action: Create Contact record
```

### Benefits of Migration
- **Improved performance**: Flows are optimized
- **Better debugging**: Flow Inspector shows execution details
- **Enhanced features**: More actions, better UI
- **Future-proof**: Salesforce actively develops Flows

## Automation Design Patterns

### Pattern 1: Simple Field Update
**Use**: Record-Triggered Flow (Before Save - Fast Field Update)
```
Trigger: Opportunity Stage changed to "Closed Won"
Action: Update Close Date to Today
        Update Probability to 100%
```

### Pattern 2: Create Related Records
**Use**: Record-Triggered Flow (After Save)
```
Trigger: Account created
Action: Create default Contact
        Create default Opportunity
        Send welcome email
```

### Pattern 3: Complex Multi-Object Logic
**Use**: Apex Trigger + Service Layer
```apex
// When Account rating changes to "Hot"
// - Update all related Opportunities to "Prospecting"
// - Create Task for Account Owner
// - Send email to Sales Manager
// - Log to custom object
AccountService.handleHotRating(accounts, oldAccountMap);
```

### Pattern 4: Bulk Data Processing
**Use**: Batch Apex
```apex
// Update 50,000 Accounts based on external data
Database.executeBatch(new AccountUpdateBatch(), 200);
```

### Pattern 5: External System Integration
**Use**: Queueable Apex (if >100 callouts) or @future (if <100)
```apex
// Sync Accounts to external CRM
System.enqueueJob(new AccountSyncQueueable(accounts));
```

### Pattern 6: Scheduled Automation
**Use**: Scheduled Flow (simple) or Scheduled Apex (complex)
```
Simple: Scheduled Flow to send daily reminders
Complex: Scheduled Apex to batch process and sync external systems
```

## Multi-Org Considerations

### Single Business Unit (Simple Org)
- **Flows preferred** for most automation
- **Apex for**: Complex logic, bulk operations, integrations
- Keep automation simple and maintainable

### Multi-Business Unit (Complex Org)
- **Segment automation by business unit** using record types or custom fields
- **Use Apex for shared logic** (invocable methods called by Flows)
- **Consider**: Multiple flows vs single parameterized flow
- **Example**:
  ```
  Business Unit A: Flow for specific rules
  Business Unit B: Flow for different rules
  Shared Logic: Apex invocable method for common calculations
  ```

## Automation Best Practices

### General Guidelines
```
✓ Start with Flow (declarative first)
✓ Use Apex when Flow limitations are reached
✓ Document automation purpose and logic
✓ Use descriptive names (see naming conventions)
✓ Test with realistic data volumes
✓ Monitor execution (Setup → Debug Logs)
✓ Review governor limits regularly
✓ Avoid recursion (set entry conditions carefully)
✓ Version control all automation
```

### Performance Guidelines
```
✓ Minimize SOQL queries (reuse data)
✓ Bulkify Apex (handle 200+ records)
✓ Use selective queries (indexed fields)
✓ Avoid complex loops in Flows
✓ Use Batch Apex for >10,000 records
✓ Schedule heavy automation during off-peak hours
✓ Monitor CPU time (10 seconds sync, 60 async)
```

### Governance Guidelines
```
✓ Maintain automation inventory (documentation)
✓ Establish change control process
✓ Require peer review for complex automation
✓ Test in sandbox before production
✓ Monitor error logs and failed executions
✓ Deactivate unused automation
✓ Consolidate overlapping automation
```

## When to Refactor

Signs you should refactor from Flow to Apex:
- **Performance issues** (timeouts, slow execution)
- **Governor limit errors** (too many SOQL/DML)
- **Maintenance complexity** (Flow becomes too large/complex)
- **Testing requirements** (need automated unit tests)
- **Bulk operations** (processing thousands of records)
- **Advanced logic** (nested conditions, complex calculations)

## Quick Decision Matrix

| Scenario | Recommended Tool | Why |
|----------|------------------|-----|
| Update same record on save | Flow (Fast Field Update) | Simple, performant |
| Create related records | Flow (After Save) | Declarative, easy to maintain |
| Complex multi-object updates | Apex Trigger | Better performance, bulkification |
| Process 50,000 records | Batch Apex | Designed for large volumes |
| External system callout | Queueable Apex or @future | Native callout support |
| Scheduled daily cleanup | Scheduled Flow or Apex | Depends on complexity |
| User-facing wizard | Screen Flow | Designed for UI interaction |
| Complex calculations | Apex Invocable Method | Reusable, testable, called by Flow |
| Simple email alert | Flow | Quick to build, easy to maintain |
| Dynamic query logic | Apex | Dynamic SOQL support |

## When This Rule Applies

This automation decision guide is **ALWAYS ACTIVE** for:
- All automation design decisions
- All Flow vs Apex decisions
- All architecture reviews
- All refactoring decisions
- All performance optimization discussions
- All code/automation reviews

**Remember**: Choose the right tool for the job. Start with Flow, use Apex when necessary.
