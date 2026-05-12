# Salesforce Governor Limits - Quick Reference

## Per-Transaction Limits (Most Critical)

| Limit Type | Synchronous | Asynchronous | Notes |
|------------|-------------|--------------|-------|
| **SOQL Queries** | 150 | 200 | Use relationship queries to reduce count |
| **SOSL Queries** | 20 | 20 | For full-text search across objects |
| **DML Statements** | 150 | 150 | Use bulk DML, not DML in loops |
| **DML Rows** | 10,000 | 10,000 | Total rows across all DML |
| **CPU Time** | 10 seconds | 60 seconds | Pure computation time |
| **Heap Size** | 6 MB | 12 MB | Memory usage for variables/objects |
| **Callouts** | 100 | 100 | HTTP/SOAP requests |
| **Callout Time** | 120 seconds | 120 seconds | Total time for all callouts |
| **@future calls** | 50 | 0 | Cannot call @future from @future |
| **Queueable jobs** | 50 | 1 chain | Can chain queueables |
| **Email Invocations** | 10 single, 10 mass | Same | SingleEmailMessage vs MassEmailMessage |

## Platform Event Limits

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Publish Immediately** | 150 events | Via EventBus.publish() |
| **Publish in Trigger** | 150 events | Event publishing in triggers |
| **Publish via Apex** | 150 events | Per transaction |
| **Event Payload Size** | 1 MB | Maximum size per event |
| **Replay Window** | 24-72 hours | Depends on volume |
| **Subscriber Execution Time** | 60 seconds | Async execution limit |

## Query Limits

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Query Rows** | 50,000 | Total records queried |
| **Query Locator Rows** | 50 million | Via Database.QueryLocator (batch) |
| **Aggregate Queries** | 300 | COUNT(), SUM(), etc. |
| **Relationship Queries** | 5 levels | Account.Owner.Manager.Role.Name (5 levels) |
| **Subqueries** | 20 | Child relationships in one query |

## Database Operation Limits

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Records Retrieved by SOQL** | 50,000 | Use QueryLocator for more |
| **Records Retrieved by SOSL** | 2,000 | Hard limit |
| **Database.query() rows** | 50,000 | Dynamic SOQL |

## Batch Apex Limits

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Batch Jobs Queued** | 100 | Concurrent batch jobs |
| **Batch Size** | 200 (default) | Can set 1-2000 |
| **Max Batch Size** | 2,000 | Rarely use >200 |
| **Start Method CPU** | 10 seconds | For building QueryLocator |
| **Execute Method** | Normal limits | Per batch scope |

## Queueable Apex Limits

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Enqueue Calls** | 50 | Per transaction |
| **Chained Jobs** | 1 | From execute() method |
| **Max Stack Depth** | 5 | Chained job depth |
| **🆕 Delayed Execution** | 0-10,080 minutes | 7 days max delay (Winter '23+) |
| **🆕 Duplicate Prevention** | Per signature | Via AsyncOptions.duplicateSignature (Winter '23+) |

## Transaction Finalizer Limits (Winter '23+)

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Finalizers per Transaction** | 5 | Max finalizers attached per transaction |
| **CPU Time in Finalizer** | 10 seconds | Same as synchronous Apex |
| **Heap Size in Finalizer** | 6 MB | Same as synchronous Apex |
| **DML in Finalizer** | Allowed | Standard DML limits apply |

## Trigger Limits

| Limit Type | Value | Notes |
|------------|-------|-------|
| **Records per Trigger** | 200 | Default bulk size |
| **Trigger Batch Size** | Up to 200 | Can vary |

## Static Limits (24-Hour Period)

| Limit Type | Enterprise | Developer | Notes |
|------------|------------|-----------|-------|
| **Batch Apex Jobs** | 250,000 | 5 | Per 24 hours |
| **Scheduled Apex Jobs** | 100 | 5 | Concurrent |
| **Future Calls** | 250,000 | No limit | Per 24 hours |

## Checking Limits in Code

```apex
// Check current limits usage
public class LimitsChecker {

    public static void logLimits() {
        System.debug('SOQL Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        System.debug('DML Statements: ' + Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements());
        System.debug('DML Rows: ' + Limits.getDMLRows() + '/' + Limits.getLimitDMLRows());
        System.debug('CPU Time: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
        System.debug('Heap Size: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
        System.debug('Callouts: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());
    }

    public static Boolean isApproachingQueryLimit() {
        return Limits.getQueries() > (Limits.getLimitQueries() * 0.8);
    }

    public static Boolean isApproachingDMLLimit() {
        return Limits.getDMLStatements() > (Limits.getLimitDMLStatements() * 0.8);
    }
}
```

## Common Patterns to Avoid Limits

### 1. SOQL Query Limit (150)
```apex
// ❌ Bad - Query in loop (150 queries for 150 records)
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}

// ✅ Good - Single query with relationship
List<Account> accounts = [
    SELECT Id, (SELECT Id FROM Contacts)
    FROM Account
    WHERE Id IN :accountIds
];
```

### 2. DML Statement Limit (150)
```apex
// ❌ Bad - DML in loop (150 DML for 150 records)
for (Account acc : accounts) {
    update acc;
}

// ✅ Good - Bulk DML (1 DML for 150 records)
update accounts;
```

### 3. DML Rows Limit (10,000)
```apex
// Use Batch Apex for >10,000 records
public class MassUpdateBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Process up to 200 records per batch
        update scope;
    }

    public void finish(Database.BatchableContext bc) {}
}
```

### 4. Heap Size Limit (6 MB sync, 12 MB async)
```apex
// ❌ Bad - Loading all records into memory
List<Account> allAccounts = [SELECT Id, Name FROM Account]; // Could be 100,000+

// ✅ Good - Query for loop (iterates without loading all)
for (Account acc : [SELECT Id, Name FROM Account]) {
    // Process one at a time
}

// ✅ Good - Batch Apex for complex processing
public class ProcessAccountsBatch implements Database.Batchable<SObject> {
    // Processes in chunks
}
```

### 5. CPU Time Limit (10 seconds)
```apex
// ❌ Bad - Heavy computation in sync trigger
public class AccountTriggerHandler {
    public void afterInsert(List<Account> accounts) {
        for (Account acc : accounts) {
            // Complex calculations, JSON parsing, etc.
        }
    }
}

// ✅ Good - Move to async context
public class AccountTriggerHandler {
    public void afterInsert(List<Account> accounts) {
        System.enqueueJob(new ProcessAccountsQueueable(accounts));
    }
}
```

### 6. Future/Queueable Limit (50)
```apex
// ❌ Bad - Future in loop (hits limit at 50)
for (Account acc : accounts) {
    doCallout(acc.Id);
}

@future(callout=true)
public static void doCallout(Id accountId) {}

// ✅ Good - Single queueable with chaining
System.enqueueJob(new BulkCalloutQueueable(accounts));

public class BulkCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private List<Account> accounts;

    public void execute(QueueableContext ctx) {
        // Process batch, then chain to next batch
    }
}
```

## When to Use Each Async Method

| Method | Use Case | Limits | Chaining |
|--------|----------|--------|----------|
| **@future** | Simple callout or fire-and-forget | 10s CPU, no chaining | No |
| **Queueable** | Complex logic, need chaining | 60s CPU, can return values | Yes (1 level) |
| **Batch Apex** | Process >10,000 records | 60s CPU per batch | Via finish() |
| **Scheduled Apex** | Time-based jobs | 60s CPU | Via schedules |
| **Platform Events** | Decoupled pub/sub | Async subscriber | N/A |

## Monitoring Limits in Production

### Use Developer Console
1. Debug → Change Log Levels
2. Set Apex Code to FINEST
3. Check Execution Log for "LIMIT_USAGE_FOR_NS"

### Use Apex Code
```apex
public class LimitsTracker {
    public static void track(String operation) {
        System.debug('=== Limits for: ' + operation + ' ===');
        System.debug('Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        System.debug('DML: ' + Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements());
        System.debug('CPU: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
        System.debug('Heap: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
    }
}

// Usage
LimitsTracker.track('Before account update');
update accounts;
LimitsTracker.track('After account update');
```

### Custom Exception for Limit Warnings
```apex
public class GovernorLimitException extends Exception {}

public class LimitsGuard {
    public static void checkLimits() {
        if (Limits.getQueries() > 100) {
            throw new GovernorLimitException(
                'Approaching SOQL limit: ' + Limits.getQueries()
            );
        }
        if (Limits.getCpuTime() > 8000) {
            throw new GovernorLimitException(
                'Approaching CPU limit: ' + Limits.getCpuTime()
            );
        }
    }
}
```

## Resources
- [Official Governor Limits Docs](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/)
- [Execution Governors and Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm)
- [Limits Class Reference](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_limits.htm)
