# Modern Asynchronous Patterns (Winter '23+)

Expert reference for modern Apex async capabilities: Transaction Finalizers, Queueable enhancements, and async testing patterns.

## Overview

Modern async patterns solve critical reliability and testing challenges:
- **Transaction Finalizers** (Winter '23): Guaranteed post-transaction cleanup
- **Queueable Delayed Execution** (Winter '23): Schedule jobs with millisecond precision
- **Queueable Duplicate Prevention** (Winter '23): Prevent duplicate async processing
- **Test.getEventBus()** (Winter '23): Test async operations without Test.stopTest() delays

---

## Transaction Finalizers (Winter '23+)

**Introduced**: Winter '23 (API 56.0+)
**Purpose**: Execute logic after transaction commits OR rolls back - guaranteed execution
**Use Cases**: Logging, cleanup, notifications that MUST happen regardless of success/failure

### The Problem Finalizers Solve

```apex
// ❌ PROBLEM: If this fails, logging never happens
public class OrderProcessor implements Queueable {
    public void execute(QueueableContext ctx) {
        try {
            processOrders(); // If this throws exception...
        } finally {
            logResults(); // ...this might not complete if heap/CPU limit hit
        }
    }
}
```

### Solution: Transaction Finalizer

```apex
/**
 * @description Queueable with guaranteed logging via Finalizer
 * @since API 56.0 (Winter '23)
 */
public class OrderProcessor implements Queueable, System.Finalizer {

    private List<Order__c> orders;

    public OrderProcessor(List<Order__c> orders) {
        this.orders = orders;
    }

    public void execute(QueueableContext ctx) {
        // Attach finalizer - guaranteed to execute
        System.attachFinalizer(this);

        // Main business logic
        processOrders();
    }

    public void execute(System.FinalizerContext ctx) {
        // ALWAYS runs - even if execute() fails
        // Runs AFTER transaction commits or rolls back

        String status = ctx.getResult() == System.ParentJobResult.SUCCESS
            ? 'SUCCESS'
            : 'FAILED';

        // Log results (guaranteed)
        logResults(status, ctx.getAsyncApexJobId(), ctx.getException());

        // Chain next job if needed
        if (ctx.getResult() == System.ParentJobResult.SUCCESS) {
            if (!orders.isEmpty()) {
                System.enqueueJob(new NextProcessor());
            }
        }
    }

    private void processOrders() {
        // Bulkified order processing
        for (Order__c order : orders) {
            order.Status__c = 'Processed';
            order.Processed_Date__c = System.now();
        }
        update orders;
    }

    private void logResults(String status, Id jobId, Exception ex) {
        // Log to Platform Event for real-time monitoring
        Process_Log__e log = new Process_Log__e(
            Job_Id__c = String.valueOf(jobId),
            Status__c = status,
            Records_Processed__c = orders.size(),
            Error_Message__c = ex != null ? ex.getMessage() : null,
            Timestamp__c = System.now()
        );
        EventBus.publish(log);
    }
}
```

### Finalizer Context Methods

```apex
public void execute(System.FinalizerContext ctx) {
    // Get parent job result
    System.ParentJobResult result = ctx.getResult();
    // Values: SUCCESS or UNHANDLED_EXCEPTION

    // Get parent job ID
    Id jobId = ctx.getAsyncApexJobId();

    // Get exception if failed
    Exception ex = ctx.getException();

    // Get request ID for correlation
    String requestId = ctx.getRequestId();
}
```

### Use Cases

#### 1. Guaranteed Logging

```apex
public class BatchProcessor implements Database.Batchable<SObject>, System.Finalizer {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.attachFinalizer(this);
        return Database.getQueryLocator([SELECT Id FROM Account LIMIT 10000]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Process batch
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        // Regular finish logic
    }

    public void execute(System.FinalizerContext ctx) {
        // Log batch results (guaranteed)
        Batch_Log__c log = new Batch_Log__c(
            Job_Id__c = String.valueOf(ctx.getAsyncApexJobId()),
            Status__c = ctx.getResult() == System.ParentJobResult.SUCCESS ? 'Completed' : 'Failed',
            Completed_At__c = System.now()
        );
        insert log;
    }
}
```

#### 2. Cleanup Resources

```apex
public class ExternalIntegration implements Queueable, System.Finalizer {

    private String sessionToken;

    public void execute(QueueableContext ctx) {
        System.attachFinalizer(this);

        // Create external session
        sessionToken = createExternalSession();

        // Do work with session
        callExternalAPI(sessionToken);
    }

    public void execute(System.FinalizerContext ctx) {
        // ALWAYS cleanup session - even if callExternalAPI() failed
        if (String.isNotBlank(sessionToken)) {
            closeExternalSession(sessionToken);
        }
    }

    private String createExternalSession() {
        // Create session in external system
        return 'session-token-12345';
    }

    private void callExternalAPI(String token) {
        // Make callout with session
    }

    private void closeExternalSession(String token) {
        // Close session (guaranteed)
    }
}
```

#### 3. Error Notification

```apex
public class CriticalProcessor implements Queueable, System.Finalizer {

    public void execute(QueueableContext ctx) {
        System.attachFinalizer(this);
        processCriticalData();
    }

    public void execute(System.FinalizerContext ctx) {
        // Send notification if failed
        if (ctx.getResult() == System.ParentJobResult.UNHANDLED_EXCEPTION) {
            sendFailureNotification(ctx.getException());
        }
    }

    private void processCriticalData() {
        // Critical processing
    }

    private void sendFailureNotification(Exception ex) {
        // Send Slack/email notification
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{'admin@company.com'});
        mail.setSubject('Critical Job Failed');
        mail.setPlainTextBody('Error: ' + ex.getMessage());
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }
}
```

### Governor Limits

| Limit | Value | Notes |
|-------|-------|-------|
| **Finalizers per transaction** | 5 | Max 5 finalizers attached per transaction |
| **CPU Time in finalizer** | 10 seconds | Same as synchronous Apex |
| **Heap Size in finalizer** | 6 MB | Same as synchronous Apex |
| **DML in finalizer** | Allowed | Standard DML limits apply |

### Testing Finalizers

```apex
@isTest
static void testFinalizerSuccess() {
    List<Order__c> orders = TestDataFactory.createOrders(200);
    insert orders;

    Test.startTest();
    System.enqueueJob(new OrderProcessor(orders));
    Test.stopTest();

    // Verify finalizer executed (check logs)
    List<Process_Log__e> logs = Test.getEventBus().getPublishedEvents(Process_Log__e.SObjectType);
    System.assertEquals(1, logs.size(), 'Finalizer should have logged');
    System.assertEquals('SUCCESS', logs[0].Status__c);
}

@isTest
static void testFinalizerFailure() {
    // Create invalid data to trigger exception
    List<Order__c> orders = new List<Order__c>{
        new Order__c(Name = null) // Required field violation
    };

    Test.startTest();
    try {
        System.enqueueJob(new OrderProcessor(orders));
    } catch (Exception e) {
        // Expected
    }
    Test.stopTest();

    // Verify finalizer logged failure
    List<Process_Log__e> logs = Test.getEventBus().getPublishedEvents(Process_Log__e.SObjectType);
    System.assertEquals(1, logs.size(), 'Finalizer should have logged even on failure');
    System.assertEquals('FAILED', logs[0].Status__c);
}
```

---

## Queueable Delayed Execution (Winter '23+)

**Introduced**: Winter '23 (API 56.0+)
**Purpose**: Schedule queueable jobs with precise delay (minutes to days)
**Use Cases**: Rate limiting, scheduled retries, time-based workflows

### Syntax

```apex
/**
 * @description Enqueue job with delay
 * @param queueable The job to execute
 * @param delayInMinutes Delay before execution (0-10080 minutes = 7 days)
 */
System.enqueueJob(queueable, delayInMinutes);
```

### Basic Usage

```apex
public class DelayedProcessor implements Queueable {

    private List<Account> accounts;

    public DelayedProcessor(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext ctx) {
        // Process accounts after delay
        for (Account acc : accounts) {
            acc.Status__c = 'Processed';
        }
        update accounts;
    }
}

// Enqueue with 30-minute delay
System.enqueueJob(new DelayedProcessor(accounts), 30);
```

### Use Cases

#### 1. Rate Limiting External APIs

```apex
/**
 * @description Rate-limited external API calls
 * Process batches with delay to respect API limits
 */
public class RateLimitedCallout implements Queueable, Database.AllowsCallouts {

    private List<Account> accounts;
    private Integer batchNumber;
    private static final Integer BATCH_SIZE = 10;
    private static final Integer DELAY_MINUTES = 5;

    public RateLimitedCallout(List<Account> accounts, Integer batchNumber) {
        this.accounts = accounts;
        this.batchNumber = batchNumber;
    }

    public void execute(QueueableContext ctx) {
        // Process current batch
        Integer startIndex = batchNumber * BATCH_SIZE;
        Integer endIndex = Math.min(startIndex + BATCH_SIZE, accounts.size());

        for (Integer i = startIndex; i < endIndex; i++) {
            callExternalAPI(accounts[i]);
        }

        // Enqueue next batch with delay
        if (endIndex < accounts.size()) {
            System.enqueueJob(
                new RateLimitedCallout(accounts, batchNumber + 1),
                DELAY_MINUTES
            );
        }
    }

    private void callExternalAPI(Account acc) {
        // Make HTTP callout
    }
}
```

#### 2. Retry with Exponential Backoff

```apex
/**
 * @description Retry failed operations with exponential backoff
 */
public class RetryProcessor implements Queueable {

    private Id recordId;
    private Integer attemptNumber;
    private static final Integer MAX_ATTEMPTS = 5;

    public RetryProcessor(Id recordId, Integer attemptNumber) {
        this.recordId = recordId;
        this.attemptNumber = attemptNumber;
    }

    public void execute(QueueableContext ctx) {
        try {
            processRecord(recordId);
        } catch (Exception e) {
            // Retry with exponential backoff
            if (attemptNumber < MAX_ATTEMPTS) {
                Integer delayMinutes = (Integer) Math.pow(2, attemptNumber); // 1, 2, 4, 8, 16 minutes
                System.enqueueJob(
                    new RetryProcessor(recordId, attemptNumber + 1),
                    delayMinutes
                );
            } else {
                // Max retries reached - log failure
                logFailure(recordId, e);
            }
        }
    }

    private void processRecord(Id recordId) {
        // Processing logic that might fail
    }

    private void logFailure(Id recordId, Exception e) {
        // Log permanent failure
    }
}
```

#### 3. Scheduled Follow-Up

```apex
/**
 * @description Send follow-up email after delay
 */
public class FollowUpEmail implements Queueable {

    private Id leadId;

    public FollowUpEmail(Id leadId) {
        this.leadId = leadId;
    }

    public void execute(QueueableContext ctx) {
        Lead lead = [SELECT Id, Email, Name FROM Lead WHERE Id = :leadId];

        // Send follow-up email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ lead.Email });
        mail.setSubject('Follow-up: ' + lead.Name);
        mail.setPlainTextBody('Thank you for your interest...');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
    }
}

// Send follow-up 1 day later (1440 minutes)
System.enqueueJob(new FollowUpEmail(leadId), 1440);
```

### Governor Limits

| Limit | Value | Notes |
|-------|-------|-------|
| **Max delay** | 10,080 minutes (7 days) | 0-10080 minutes |
| **Enqueue calls per transaction** | 50 | Same as regular queueable |
| **Stack depth** | 5 | Same as chained queueables |

### Testing Delayed Queueables

```apex
@isTest
static void testDelayedExecution() {
    List<Account> accounts = TestDataFactory.createAccounts(10);
    insert accounts;

    Test.startTest();
    System.enqueueJob(new DelayedProcessor(accounts), 30);
    Test.stopTest(); // Forces immediate execution in tests

    // Verify execution
    List<Account> updated = [SELECT Id, Status__c FROM Account];
    for (Account acc : updated) {
        System.assertEquals('Processed', acc.Status__c);
    }
}
```

---

## Queueable Duplicate Prevention (Winter '23+)

**Introduced**: Winter '23 (API 56.0+)
**Purpose**: Prevent duplicate processing of the same data
**Use Cases**: Idempotent operations, prevent double-processing from triggers

### Syntax

```apex
/**
 * @description Enqueue with duplicate prevention
 */
System.AsyncOptions options = new System.AsyncOptions();
options.minimumQueueableDelayInMinutes = 0;
options.maximumQueueableDelayInMinutes = 10;
options.duplicateSignature = 'unique-signature-' + recordId;

System.enqueueJob(queueable, options);
```

### Basic Usage

```apex
public class UniqueProcessor implements Queueable {

    private Id accountId;

    public UniqueProcessor(Id accountId) {
        this.accountId = accountId;
    }

    public void execute(QueueableContext ctx) {
        // Process account
        Account acc = [SELECT Id, Name FROM Account WHERE Id = :accountId];
        acc.Status__c = 'Processed';
        update acc;
    }
}

// Enqueue with duplicate prevention
System.AsyncOptions options = new System.AsyncOptions();
options.duplicateSignature = 'process-account-' + accountId;

System.enqueueJob(new UniqueProcessor(accountId), options);

// If called again with same signature within delay window, second call is ignored
```

### Use Cases

#### 1. Prevent Duplicate Trigger Processing

```apex
/**
 * @description Trigger handler with duplicate prevention
 */
public class AccountTriggerHandler {

    public static void afterUpdate(List<Account> accounts, Map<Id, Account> oldMap) {
        Set<Id> accountIds = new Set<Id>();

        for (Account acc : accounts) {
            if (acc.Status__c != oldMap.get(acc.Id).Status__c) {
                accountIds.add(acc.Id);
            }
        }

        if (!accountIds.isEmpty()) {
            enqueueProcessing(accountIds);
        }
    }

    private static void enqueueProcessing(Set<Id> accountIds) {
        for (Id accountId : accountIds) {
            // Prevent duplicate processing if trigger fires multiple times
            System.AsyncOptions options = new System.AsyncOptions();
            options.duplicateSignature = 'account-status-change-' + accountId;
            options.minimumQueueableDelayInMinutes = 0;
            options.maximumQueueableDelayInMinutes = 5; // Dedupe window: 5 minutes

            System.enqueueJob(new AccountProcessor(accountId), options);
        }
    }
}
```

#### 2. Idempotent External API Calls

```apex
/**
 * @description Idempotent external API integration
 */
public class ExternalAPISync implements Queueable, Database.AllowsCallouts {

    private Id recordId;
    private String externalId;

    public ExternalAPISync(Id recordId, String externalId) {
        this.recordId = recordId;
        this.externalId = externalId;
    }

    public void execute(QueueableContext ctx) {
        // Sync to external system
        syncToExternal(recordId, externalId);
    }

    private void syncToExternal(Id recordId, String externalId) {
        // HTTP callout
    }
}

// Enqueue with duplicate prevention by external ID
System.AsyncOptions options = new System.AsyncOptions();
options.duplicateSignature = 'external-sync-' + externalId;
options.maximumQueueableDelayInMinutes = 60; // 1 hour dedupe window

System.enqueueJob(new ExternalAPISync(recordId, externalId), options);
```

### Duplicate Signature Best Practices

```apex
// ✅ GOOD: Unique signature per record
options.duplicateSignature = 'process-' + recordId;

// ✅ GOOD: Unique signature per operation + record
options.duplicateSignature = 'sync-account-' + accountId;

// ✅ GOOD: Unique signature with timestamp for time-based deduplication
options.duplicateSignature = 'daily-summary-' + Date.today().format();

// ❌ BAD: Same signature for all records
options.duplicateSignature = 'process-accounts'; // All enqueues will dedupe!
```

---

## Migration from @future to Queueable

### Why Migrate?

| Feature | @future | Queueable |
|---------|---------|-----------|
| **Chaining** | ❌ No | ✅ Yes |
| **Complex parameters** | ❌ Primitives only | ✅ Objects/Lists |
| **Monitoring** | ⚠️ Limited | ✅ Full AsyncApexJob |
| **Finalizers** | ❌ No | ✅ Yes |
| **Delayed execution** | ❌ No | ✅ Yes (Winter '23+) |
| **Duplicate prevention** | ❌ No | ✅ Yes (Winter '23+) |

### Migration Pattern

```apex
// Before (@future)
public class AccountProcessor {
    @future
    public static void processAccounts(Set<Id> accountIds) {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        for (Account acc : accounts) {
            acc.Status__c = 'Processed';
        }
        update accounts;
    }
}

// Usage
AccountProcessor.processAccounts(accountIds);

// After (Queueable)
public class AccountQueueable implements Queueable {
    private List<Account> accounts;

    public AccountQueueable(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext ctx) {
        for (Account acc : accounts) {
            acc.Status__c = 'Processed';
        }
        update accounts;
    }
}

// Usage
List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
System.enqueueJob(new AccountQueueable(accounts));
```

---

## Testing Async Operations with Test.getEventBus()

**Introduced**: Winter '23 (API 56.0+)
**Purpose**: Test Platform Event publishing without Test.stopTest() delays

### Traditional Testing Problem

```apex
// ❌ PROBLEM: Test.stopTest() forces synchronous execution of ALL async jobs
@isTest
static void testAsync() {
    Test.startTest();
    System.enqueueJob(new MyQueueable());
    // Must call stopTest to force execution
    Test.stopTest(); // Forces ALL async jobs to complete

    // Verify results
}
```

### Modern Solution: Test.getEventBus()

```apex
/**
 * @description Test Platform Event publishing without stopTest
 */
@isTest
static void testEventPublishing() {
    Test.startTest();

    // Publish event
    Process_Log__e log = new Process_Log__e(
        Status__c = 'SUCCESS',
        Records_Processed__c = 100
    );
    EventBus.publish(log);

    // Get published events WITHOUT stopping test
    List<Process_Log__e> publishedEvents = Test.getEventBus().getPublishedEvents(
        Process_Log__e.SObjectType
    );

    Test.stopTest();

    // Verify
    System.assertEquals(1, publishedEvents.size());
    System.assertEquals('SUCCESS', publishedEvents[0].Status__c);
}
```

### Testing Finalizers with Event Bus

```apex
@isTest
static void testFinalizerLogging() {
    List<Order__c> orders = TestDataFactory.createOrders(200);
    insert orders;

    Test.startTest();
    System.enqueueJob(new OrderProcessor(orders));
    Test.stopTest();

    // Verify finalizer published log event
    List<Process_Log__e> logs = Test.getEventBus().getPublishedEvents(
        Process_Log__e.SObjectType
    );

    System.assertEquals(1, logs.size(), 'Finalizer should publish log');
    System.assertEquals('SUCCESS', logs[0].Status__c);
    System.assertEquals(200, logs[0].Records_Processed__c);
}
```

---

## Best Practices

### 1. Always Use Finalizers for Logging

```apex
// ✅ GOOD: Finalizer guarantees logging
public class Processor implements Queueable, System.Finalizer {
    public void execute(QueueableContext ctx) {
        System.attachFinalizer(this);
        doWork();
    }

    public void execute(System.FinalizerContext ctx) {
        logResults(ctx.getResult());
    }
}

// ❌ BAD: Logging might not happen if exception thrown
public class Processor implements Queueable {
    public void execute(QueueableContext ctx) {
        try {
            doWork();
        } finally {
            logResults(); // Might fail if CPU/heap limit hit
        }
    }
}
```

### 2. Use Delayed Execution for Rate Limiting

```apex
// ✅ GOOD: Delayed execution respects API limits
System.enqueueJob(new APICallout(), 5); // 5-minute delay

// ❌ BAD: Immediate execution might exceed rate limits
System.enqueueJob(new APICallout());
```

### 3. Use Duplicate Prevention in Triggers

```apex
// ✅ GOOD: Prevent duplicate processing from trigger recursion
System.AsyncOptions options = new System.AsyncOptions();
options.duplicateSignature = 'trigger-' + recordId;
System.enqueueJob(new TriggerProcessor(recordId), options);

// ❌ BAD: Trigger recursion causes duplicate processing
System.enqueueJob(new TriggerProcessor(recordId));
```

---

## Quick Reference

### Attach Finalizer
```apex
public void execute(QueueableContext ctx) {
    System.attachFinalizer(this);
    // Main logic
}

public void execute(System.FinalizerContext ctx) {
    // Guaranteed execution
}
```

### Delayed Execution
```apex
System.enqueueJob(queueable, 30); // 30-minute delay
```

### Duplicate Prevention
```apex
System.AsyncOptions options = new System.AsyncOptions();
options.duplicateSignature = 'unique-' + recordId;
System.enqueueJob(queueable, options);
```

### Test Event Bus
```apex
List<MyEvent__e> events = Test.getEventBus().getPublishedEvents(
    MyEvent__e.SObjectType
);
```

---

## Resources

- [Transaction Finalizers Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_transaction_finalizers.htm)
- [Queueable Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm)
- [AsyncOptions Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_AsyncOptions.htm)
- Governor Limits: `references/governor-limits-reference.md`
