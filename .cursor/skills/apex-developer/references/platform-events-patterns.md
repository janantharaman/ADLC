# Platform Events Patterns (Expert Reference)

Comprehensive patterns for event-driven architecture using Platform Events in Salesforce.

## Overview

Platform Events enable event-driven, loosely-coupled architectures with:
- **Pub/Sub Messaging**: Decouple publishers from subscribers
- **Real-Time Integration**: React to changes immediately
- **Scalability**: Process events asynchronously
- **Reliability**: Guaranteed delivery with replay

---

## Platform Events vs Change Data Capture

### Decision Matrix

| Feature | Platform Events | Change Data Capture (CDC) |
|---------|-----------------|---------------------------|
| **Use Case** | Custom business events | Database change notifications |
| **Control** | Full control over event structure | Standard structure (field changes) |
| **Publishing** | Manual (Apex, Flow, API) | Automatic (on DML) |
| **Filtering** | Custom logic | All changes to subscribed objects |
| **Replay** | 24-72 hours | 3 days |
| **Volume** | 150 events per transaction | Unlimited (system-generated) |
| **Custom Fields** | Full custom fields | Limited metadata |

### When to Use Each

```apex
// ✅ USE PLATFORM EVENTS for:
// - Custom business events (Order Submitted, Payment Processed)
// - Cross-system integration events
// - Notifications with custom payloads
// - Event sourcing patterns

// ✅ USE CDC for:
// - Sync data to external systems (all Account changes)
// - Audit trail of record modifications
// - Cache invalidation on record updates
// - Real-time reporting dashboards
```

---

## Publishing Platform Events

### 1. Immediate Publishing (EventBus.publish)

**Use Case**: Publish event immediately, transaction-independent

```apex
/**
 * @description Publish event immediately
 * Event published regardless of transaction success/failure
 */
public class OrderService {

    public static void createOrder(Order__c order) {
        insert order;

        // Publish immediately (even if transaction rolls back)
        Order_Created__e event = new Order_Created__e(
            Order_Id__c = order.Id,
            Order_Amount__c = order.Amount__c,
            Customer_Email__c = order.Customer_Email__c,
            Timestamp__c = System.now()
        );

        List<Database.SaveResult> results = EventBus.publish(event);

        // Handle publish failures
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug('Event publish failed: ' + error.getMessage());
                }
            }
        }
    }
}
```

**Behavior**:
- Published immediately (does NOT wait for transaction commit)
- If transaction rolls back, event is still published
- Use for notifications, logging, monitoring

### 2. Transaction-Aware Publishing (DML insert)

**Use Case**: Publish only if transaction commits successfully

```apex
/**
 * @description Transaction-aware event publishing
 * Event published ONLY if transaction commits
 */
public class PaymentService {

    public static void processPayment(Payment__c payment) {
        try {
            // Process payment
            payment.Status__c = 'Processed';
            payment.Processed_Date__c = System.now();
            update payment;

            // Create event (not published yet)
            Payment_Processed__e event = new Payment_Processed__e(
                Payment_Id__c = payment.Id,
                Amount__c = payment.Amount__c,
                Status__c = 'Success'
            );

            // Insert publishes ONLY if transaction commits
            insert event;

            // If update fails, event is NOT published
        } catch (Exception e) {
            // Transaction rolled back, event not published
            System.debug('Payment processing failed: ' + e.getMessage());
            throw e;
        }
    }
}
```

**Behavior**:
- Event published only after transaction commits
- If transaction rolls back, event is NOT published
- Use for transactional events, state changes

### 3. Bulk Publishing

```apex
/**
 * @description Bulk event publishing (up to 150 events per transaction)
 */
public class BulkOrderService {

    public static void processOrders(List<Order__c> orders) {
        // Bulk DML
        update orders;

        // Bulk event creation
        List<Order_Updated__e> events = new List<Order_Updated__e>();
        for (Order__c order : orders) {
            events.add(new Order_Updated__e(
                Order_Id__c = order.Id,
                New_Status__c = order.Status__c,
                Updated_By__c = UserInfo.getUserId(),
                Timestamp__c = System.now()
            ));
        }

        // Bulk publish
        List<Database.SaveResult> results = EventBus.publish(events);

        // Log failures
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Failed to publish event for Order: ' + orders[i].Id);
            }
        }
    }
}
```

---

## Subscribing to Platform Events

### 1. Apex Trigger Subscription

**Pattern**: Process events in Apex trigger

```apex
/**
 * @description Platform Event trigger
 * Executes asynchronously when event is published
 */
trigger OrderCreatedTrigger on Order_Created__e (after insert) {
    OrderCreatedHandler.handle(Trigger.new);
}

/**
 * @description Event handler - processes events asynchronously
 */
public class OrderCreatedHandler {

    public static void handle(List<Order_Created__e> events) {
        List<Notification__c> notifications = new List<Notification__c>();

        for (Order_Created__e event : events) {
            // Process each event
            notifications.add(new Notification__c(
                Order_Id__c = event.Order_Id__c,
                Type__c = 'Order Created',
                Recipient__c = event.Customer_Email__c,
                Message__c = 'Your order has been created'
            ));

            // Send external notification
            sendExternalNotification(event);
        }

        if (!notifications.isEmpty()) {
            insert notifications;
        }
    }

    private static void sendExternalNotification(Order_Created__e event) {
        // Callouts not allowed in event triggers
        // Use Queueable for external integration
        System.enqueueJob(new SendNotificationJob(event));
    }
}
```

**Characteristics**:
- Executes asynchronously (separate transaction)
- No before triggers (only after insert)
- Cannot make callouts directly (use Queueable)
- Runs as Automated Process user

### 2. Flow Subscription

**Pattern**: Use Flow to process events (low-code)

```
Platform Event: Order_Created__e
↓
Record-Triggered Flow: "Process Order Created Event"
↓
Actions:
  - Send Email
  - Create Task
  - Update Custom Object
```

### 3. External Subscription (CometD)

**Pattern**: Subscribe from external system via Streaming API

```javascript
// Node.js example using CometD
const cometd = new CometD();

cometd.configure({
    url: 'https://instance.salesforce.com/cometd/57.0/',
    requestHeaders: {
        'Authorization': 'Bearer ' + accessToken
    }
});

cometd.handshake((handshakeReply) => {
    if (handshakeReply.successful) {
        // Subscribe to Platform Event
        cometd.subscribe('/event/Order_Created__e', (message) => {
            const event = message.data.payload;
            console.log('Order Created:', event.Order_Id__c);
            // Process event in external system
        });
    }
});
```

---

## Event Sourcing Pattern

**Pattern**: Store events as source of truth, derive state from events

```apex
/**
 * @description Event sourcing for Order lifecycle
 * All state changes captured as events
 */

// Event 1: Order Created
public class OrderCreatedEvent {
    public static void publish(Order__c order) {
        Order_Event__e event = new Order_Event__e(
            Order_Id__c = order.Id,
            Event_Type__c = 'Created',
            Payload__c = JSON.serialize(order),
            Timestamp__c = System.now()
        );
        insert event;
    }
}

// Event 2: Order Confirmed
public class OrderConfirmedEvent {
    public static void publish(Id orderId) {
        Order_Event__e event = new Order_Event__e(
            Order_Id__c = orderId,
            Event_Type__c = 'Confirmed',
            Timestamp__c = System.now()
        );
        insert event;
    }
}

// Event 3: Order Shipped
public class OrderShippedEvent {
    public static void publish(Id orderId, String trackingNumber) {
        Order_Event__e event = new Order_Event__e(
            Order_Id__c = orderId,
            Event_Type__c = 'Shipped',
            Payload__c = JSON.serialize(new Map<String, String>{
                'trackingNumber' => trackingNumber
            }),
            Timestamp__c = System.now()
        );
        insert event;
    }
}

// Subscriber: Rebuild state from events
trigger OrderEventTrigger on Order_Event__e (after insert) {
    OrderEventProjection.project(Trigger.new);
}

public class OrderEventProjection {
    public static void project(List<Order_Event__e> events) {
        Map<Id, Order__c> ordersToUpdate = new Map<Id, Order__c>();

        for (Order_Event__e event : events) {
            Order__c order = ordersToUpdate.get(event.Order_Id__c);
            if (order == null) {
                order = new Order__c(Id = event.Order_Id__c);
            }

            // Apply event to order state
            if (event.Event_Type__c == 'Created') {
                order.Status__c = 'Created';
            } else if (event.Event_Type__c == 'Confirmed') {
                order.Status__c = 'Confirmed';
                order.Confirmed_Date__c = event.Timestamp__c;
            } else if (event.Event_Type__c == 'Shipped') {
                order.Status__c = 'Shipped';
                order.Shipped_Date__c = event.Timestamp__c;
                Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(event.Payload__c);
                order.Tracking_Number__c = (String) payload.get('trackingNumber');
            }

            ordersToUpdate.put(order.Id, order);
        }

        update ordersToUpdate.values();
    }
}
```

---

## CQRS Pattern (Command Query Responsibility Segregation)

**Pattern**: Separate read and write models, sync via events

```apex
/**
 * @description CQRS with Platform Events
 * Write model: Order__c (transactional)
 * Read model: Order_Summary__c (optimized for queries)
 */

// Command Side: Write to Order__c
public class OrderCommandService {

    public static void createOrder(String customerName, Decimal amount) {
        // Write to command model
        Order__c order = new Order__c(
            Customer_Name__c = customerName,
            Amount__c = amount,
            Status__c = 'Created'
        );
        insert order;

        // Publish event to sync read model
        Order_Command__e event = new Order_Command__e(
            Command_Type__c = 'Create',
            Order_Id__c = order.Id,
            Customer_Name__c = customerName,
            Amount__c = amount
        );
        insert event;
    }

    public static void updateOrderStatus(Id orderId, String status) {
        // Update command model
        Order__c order = new Order__c(Id = orderId, Status__c = status);
        update order;

        // Publish event
        Order_Command__e event = new Order_Command__e(
            Command_Type__c = 'Update',
            Order_Id__c = orderId,
            Status__c = status
        );
        insert event;
    }
}

// Query Side: Read from Order_Summary__c
public class OrderQueryService {

    public static List<Order_Summary__c> getOrdersByCustomer(String customerName) {
        // Query optimized read model
        return [
            SELECT Id, Order_Id__c, Customer_Name__c, Amount__c,
                   Status__c, Item_Count__c, Last_Updated__c
            FROM Order_Summary__c
            WHERE Customer_Name__c = :customerName
            WITH USER_MODE
            ORDER BY Last_Updated__c DESC
        ];
    }

    public static Order_Summary__c getOrderSummary(Id orderId) {
        return [
            SELECT Id, Order_Id__c, Customer_Name__c, Amount__c,
                   Status__c, Item_Count__c, Last_Updated__c
            FROM Order_Summary__c
            WHERE Order_Id__c = :orderId
            WITH USER_MODE
        ];
    }
}

// Event Subscriber: Sync read model
trigger OrderCommandTrigger on Order_Command__e (after insert) {
    OrderReadModelSync.sync(Trigger.new);
}

public class OrderReadModelSync {

    public static void sync(List<Order_Command__e> events) {
        List<Order_Summary__c> summaries = new List<Order_Summary__c>();

        for (Order_Command__e event : events) {
            if (event.Command_Type__c == 'Create') {
                summaries.add(new Order_Summary__c(
                    Order_Id__c = event.Order_Id__c,
                    Customer_Name__c = event.Customer_Name__c,
                    Amount__c = event.Amount__c,
                    Status__c = 'Created',
                    Last_Updated__c = System.now()
                ));
            } else if (event.Command_Type__c == 'Update') {
                // Update existing summary
                List<Order_Summary__c> existing = [
                    SELECT Id FROM Order_Summary__c
                    WHERE Order_Id__c = :event.Order_Id__c
                ];
                if (!existing.isEmpty()) {
                    existing[0].Status__c = event.Status__c;
                    existing[0].Last_Updated__c = System.now();
                    summaries.add(existing[0]);
                }
            }
        }

        if (!summaries.isEmpty()) {
            upsert summaries;
        }
    }
}
```

---

## Retry Logic with RetryableException

```apex
/**
 * @description Retry failed event processing
 */
trigger Payment_Processed_Trigger on Payment_Processed__e (after insert) {
    PaymentEventHandler.handle(Trigger.new);
}

public class PaymentEventHandler {

    private static Integer MAX_RETRIES = 3;
    private static Map<Id, Integer> retryCount = new Map<Id, Integer>();

    public static void handle(List<Payment_Processed__e> events) {
        for (Payment_Processed__e event : events) {
            try {
                processPayment(event);
            } catch (Exception e) {
                // Get retry count
                Integer count = retryCount.get(event.EventUuid) ?? 0;

                if (count < MAX_RETRIES) {
                    // Retry event processing
                    retryCount.put(event.EventUuid, count + 1);
                    throw new EventBus.RetryableException(
                        'Payment processing failed, retrying... (attempt ' + (count + 1) + ')'
                    );
                } else {
                    // Max retries reached, log failure
                    logFailure(event, e);
                }
            }
        }
    }

    private static void processPayment(Payment_Processed__e event) {
        // Processing logic that might fail
        if (Math.random() < 0.3) {
            throw new CalloutException('External system unavailable');
        }

        // Update payment record
        Payment__c payment = new Payment__c(
            Id = event.Payment_Id__c,
            Status__c = 'Completed'
        );
        update payment;
    }

    private static void logFailure(Payment_Processed__e event, Exception e) {
        Error_Log__c log = new Error_Log__c(
            Event_Type__c = 'Payment_Processed__e',
            Event_UUID__c = event.EventUuid,
            Error_Message__c = e.getMessage(),
            Timestamp__c = System.now()
        );
        insert log;
    }
}
```

---

## Event Replay

**Use Case**: Replay missed events from specific replay ID

```apex
/**
 * @description Get last processed replay ID
 */
public class EventReplayService {

    public static Decimal getLastReplayId() {
        // Store last processed replay ID in custom setting
        Event_Replay__c setting = Event_Replay__c.getOrgDefaults();
        return setting.Last_Replay_Id__c ?? -1;
    }

    public static void updateLastReplayId(Decimal replayId) {
        Event_Replay__c setting = Event_Replay__c.getOrgDefaults();
        setting.Last_Replay_Id__c = replayId;
        upsert setting;
    }
}

// In event trigger
trigger OrderEventTrigger on Order_Event__e (after insert) {
    // Process events
    OrderEventHandler.handle(Trigger.new);

    // Update replay ID
    if (!Trigger.new.isEmpty()) {
        Decimal lastReplayId = Trigger.new[Trigger.new.size() - 1].ReplayId;
        EventReplayService.updateLastReplayId(lastReplayId);
    }
}
```

**Replay from specific ID**:
- Use Streaming API with `replayId` parameter
- Replay events from last 24-72 hours (depending on event volume)

---

## Monitoring and Debugging

### 1. Event Bus Monitoring

```apex
/**
 * @description Monitor event publishing success/failure
 */
public class EventMonitor {

    public static void publishWithMonitoring(Order_Created__e event) {
        List<Database.SaveResult> results = EventBus.publish(event);

        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                logSuccess(event);
            } else {
                logFailure(event, result.getErrors());
            }
        }
    }

    private static void logSuccess(Order_Created__e event) {
        Event_Log__c log = new Event_Log__c(
            Event_Type__c = 'Order_Created__e',
            Status__c = 'Success',
            Order_Id__c = event.Order_Id__c,
            Timestamp__c = System.now()
        );
        insert log;
    }

    private static void logFailure(Order_Created__e event, List<Database.Error> errors) {
        Event_Log__c log = new Event_Log__c(
            Event_Type__c = 'Order_Created__e',
            Status__c = 'Failed',
            Order_Id__c = event.Order_Id__c,
            Error_Message__c = errors[0].getMessage(),
            Timestamp__c = System.now()
        );
        insert log;
    }
}
```

### 2. Event Bus Usage Limits

```apex
/**
 * @description Check event publishing limits
 */
public class EventLimitsChecker {

    public static void checkLimits() {
        Integer published = Limits.getPublishImmediateDML();
        Integer limit = Limits.getLimitPublishImmediateDML();

        System.debug('Platform Events published: ' + published + '/' + limit);

        if (published > (limit * 0.8)) {
            // Approaching limit
            System.debug('WARNING: Approaching Platform Event limit');
        }
    }
}
```

---

## Testing Platform Events

### With Test.getEventBus() (Winter '23+)

```apex
@isTest
static void testEventPublishing() {
    // Given
    Order__c order = new Order__c(
        Name = 'Test Order',
        Amount__c = 1000
    );
    insert order;

    // When
    Test.startTest();
    OrderCreatedEvent.publish(order);

    // Get published events without stopping test
    List<Order_Created__e> publishedEvents = Test.getEventBus().getPublishedEvents(
        Order_Created__e.SObjectType
    );
    Test.stopTest();

    // Then
    System.assertEquals(1, publishedEvents.size());
    System.assertEquals(order.Id, publishedEvents[0].Order_Id__c);
}
```

### Traditional Testing

```apex
@isTest
static void testEventSubscriber() {
    // Given
    Order_Created__e event = new Order_Created__e(
        Order_Id__c = 'a001234567890ABC',
        Order_Amount__c = 1000,
        Customer_Email__c = 'test@example.com'
    );

    // When
    Test.startTest();
    Database.SaveResult result = EventBus.publish(event);
    Test.stopTest(); // Forces subscriber execution

    // Then
    System.assert(result.isSuccess());

    // Verify subscriber actions
    List<Notification__c> notifications = [
        SELECT Id, Order_Id__c
        FROM Notification__c
        WHERE Order_Id__c = :event.Order_Id__c
    ];
    System.assertEquals(1, notifications.size());
}
```

---

## Governor Limits

| Limit | Value | Notes |
|-------|-------|-------|
| **Events per transaction** | 150 | Via EventBus.publish() or DML |
| **Event size** | 1 MB | Total payload size |
| **Subscriber execution time** | 60 seconds | Async execution limit |
| **Delivery** | At least once | May deliver duplicates |
| **Replay window** | 24-72 hours | Depends on event volume |

---

## Best Practices

### 1. Idempotent Subscribers

```apex
// ✅ GOOD: Idempotent handling (use EventUuid)
public static void handle(List<Order_Created__e> events) {
    Set<String> processedUuids = getProcessedUuids();

    for (Order_Created__e event : events) {
        if (processedUuids.contains(event.EventUuid)) {
            continue; // Skip already processed
        }

        processEvent(event);
        markProcessed(event.EventUuid);
    }
}
```

### 2. Error Handling

```apex
// ✅ GOOD: Handle partial failures
public static void handle(List<Order_Created__e> events) {
    List<Notification__c> notifications = new List<Notification__c>();

    for (Order_Created__e event : events) {
        try {
            notifications.add(createNotification(event));
        } catch (Exception e) {
            logError(event, e);
            // Continue processing other events
        }
    }

    if (!notifications.isEmpty()) {
        Database.insert(notifications, false); // Allow partial success
    }
}
```

### 3. Bulkify Subscribers

```apex
// ✅ GOOD: Bulkified subscriber
public static void handle(List<Order_Created__e> events) {
    Set<Id> orderIds = new Set<Id>();
    for (Order_Created__e event : events) {
        orderIds.add(event.Order_Id__c);
    }

    // Single SOQL query
    Map<Id, Order__c> orders = new Map<Id, Order__c>([
        SELECT Id, Name, Amount__c FROM Order__c WHERE Id IN :orderIds
    ]);

    // Process in bulk
}
```

---

## Quick Reference

### Publish Immediate
```apex
EventBus.publish(event);
```

### Publish Transaction-Aware
```apex
insert event;
```

### Subscribe (Trigger)
```apex
trigger EventTrigger on My_Event__e (after insert) {
    EventHandler.handle(Trigger.new);
}
```

### Retry Logic
```apex
throw new EventBus.RetryableException('Retry message');
```

### Test Events
```apex
List<My_Event__e> events = Test.getEventBus().getPublishedEvents(
    My_Event__e.SObjectType
);
```

---

## Resources

- [Platform Events Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/)
- [Event-Driven Architecture Patterns](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_architecture_patterns.htm)
- [CometD (External Subscription)](https://cometd.org/)
- Governor Limits: `references/governor-limits-reference.md`
