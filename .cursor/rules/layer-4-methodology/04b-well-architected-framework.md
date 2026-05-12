---
name: Salesforce Well-Architected Framework
layer: 4
type: methodology
composable: true
requires: []
alwaysApply: true
crosses: all-layers
framework: salesforce-well-architected
tags: [architecture, trusted, easy, adaptable, patterns]
---

# Salesforce Well-Architected Framework (Layer 4 - Methodology)

The Salesforce Well-Architected Framework defines the three pillars of excellent Salesforce solutions: **Trusted**, **Easy**, and **Adaptable**.

## Three Pillars

Every architectural decision should be evaluated against ALL three pillars. A solution that excels in one pillar but fails in another is not well-architected.

---

### 1. Trusted (Security, Compliance, Reliability)

**Core Principle**: Users must trust that their data is secure, the system is reliable, and compliance requirements are met.

#### Key Principles

**Security First**:
- Enforce CRUD/FLS in ALL code (`with sharing`, `Security.stripInaccessible()`)
- Encrypt sensitive data (Platform Encryption for PII, PHI, PCI)
- Validate ALL user inputs (prevent SOQL injection, XSS)
- Use OAuth 2.0 for API authentication (not Session IDs)
- Apply principle of least privilege (profiles, permission sets, sharing rules)

**Compliance Ready**:
- Meet regulatory requirements (GDPR, HIPAA, SOC 2, PCI-DSS)
- Audit trails for sensitive operations (Field History Tracking, Event Monitoring)
- Data residency and localization (Hyperforce regions)
- Right to be forgotten (GDPR deletion requests)
- Data portability (export capabilities)

**Reliability & Resilience**:
- Design for failure (assume external APIs will fail, implement retry logic)
- Circuit breaker pattern (stop calling failing services)
- Graceful degradation (system remains functional even if non-critical features fail)
- Error logging and monitoring (Application Insights, Splunk, custom logging)
- Health checks and alerting (monitor governor limits, API usage, storage)

**Governance**:
- Change management process (review, approval, deployment)
- Code reviews and pair programming
- Automated testing in CI/CD pipelines
- Version control (Git, branching strategy)
- Documentation and knowledge transfer

#### Patterns for Trusted Solutions

**Field-Level Encryption**:
```apex
// Sensitive fields encrypted at rest (Platform Encryption)
Account acc = new Account(
    Name = 'Acme Corp',
    SSN__c = '123-45-6789',  // Encrypted field
    Credit_Card__c = '4111-1111-1111-1111'  // Encrypted field
);
insert acc;

// Queries automatically decrypt (if user has permission)
Account retrieved = [SELECT Id, Name, SSN__c FROM Account WHERE Id = :acc.Id];
// If user doesn't have permission, SSN__c returns *****
```

**Audit Trail with Platform Shield**:
- Field Audit Trail: Track field changes for up to 10 years
- Event Monitoring: Track logins, API calls, reports, SOQL queries
- Transaction Security: Real-time policies (e.g., block API calls from suspicious IPs)

**OAuth 2.0 Authentication**:
```apex
// ✅ GOOD: OAuth for external API calls
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.external.com/data');
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + getOAuthAccessToken());
HttpResponse res = new Http().send(req);

// ❌ BAD: Hardcoded credentials (security risk!)
req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('user:password')));
```

**Error Logging Framework**:
```apex
public class ErrorLogger {
    public static void log(String className, String methodName, Exception e) {
        Error_Log__c log = new Error_Log__c(
            Class_Name__c = className,
            Method_Name__c = methodName,
            Error_Message__c = e.getMessage(),
            Stack_Trace__c = e.getStackTraceString(),
            Timestamp__c = Datetime.now()
        );
        insert log;

        // Also send alert to monitoring system (e.g., Splunk, Datadog)
        sendAlertToMonitoring(log);
    }
}

// Usage
try {
    processOrders(orders);
} catch (Exception e) {
    ErrorLogger.log('OrderService', 'processOrders', e);
    throw e;
}
```

---

### 2. Easy (User Experience, Maintainability)

**Core Principle**: Solutions should be intuitive for users and easy to maintain for developers and admins.

#### Key Principles

**User Experience (UX)**:
- Intuitive UI (users can accomplish tasks without training)
- Progressive disclosure (show advanced features only when needed)
- Consistent design (Lightning Design System, SLDS)
- Responsive design (mobile and desktop)
- Accessibility (WCAG 2.1 AA compliance)
- Performance (pages load in < 2 seconds)

**Maintainability**:
- Clean code (readable, self-documenting)
- Modular design (separation of concerns)
- Reusable components (service layers, utility classes, LWC components)
- Comprehensive documentation (README, inline comments, API docs)
- Automated tests (75%+ coverage, meaningful assertions)

**Developer Experience (DX)**:
- Clear APIs (well-defined inputs/outputs, error messages)
- Reusable components (don't repeat yourself, DRY principle)
- Local development (Salesforce DX, scratch orgs, VS Code)
- Fast feedback loops (quick build-test-deploy cycles)
- Good tooling (CLI, IDE extensions, linters)

#### Patterns for Easy Solutions

**Lightning Design System (SLDS)**:
```html
<!-- ✅ GOOD: Use SLDS for consistent UI -->
<template>
    <lightning-card title="Account Details" icon-name="standard:account">
        <lightning-button
            label="Save"
            variant="brand"
            onclick={handleSave}>
        </lightning-button>
        <lightning-button
            label="Cancel"
            onclick={handleCancel}>
        </lightning-button>
    </lightning-card>
</template>

<!-- ❌ BAD: Custom styles (inconsistent, harder to maintain) -->
<template>
    <div style="border: 1px solid blue; padding: 10px;">
        <button style="background: blue; color: white;" onclick={handleSave}>Save</button>
    </div>
</template>
```

**Service Layer Pattern** (Separation of Concerns):
```apex
// ✅ GOOD: Service layer separates business logic from UI/triggers
// Trigger (thin, delegates to handler)
trigger AccountTrigger on Account (after insert, after update) {
    AccountTriggerHandler.handle();
}

// Handler (delegates to service)
public class AccountTriggerHandler {
    public static void handle() {
        if (Trigger.isAfter && Trigger.isInsert) {
            AccountService.createDefaultOpportunities(Trigger.new);
        }
    }
}

// Service (business logic, reusable)
public class AccountService {
    public static void createDefaultOpportunities(List<Account> accounts) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            opps.add(new Opportunity(
                Name = 'Initial Opportunity - ' + acc.Name,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        if (!opps.isEmpty()) {
            insert opps;
        }
    }
}

// ❌ BAD: All logic in trigger (hard to test, not reusable)
trigger AccountTrigger on Account (after insert) {
    List<Opportunity> opps = new List<Opportunity>();
    for (Account acc : Trigger.new) {
        opps.add(new Opportunity(...));
    }
    insert opps;
}
```

**Centralized Configuration** (Custom Metadata):
```apex
// ✅ GOOD: Use Custom Metadata for configuration (no code deploys needed!)
Integration_Setting__mdt setting = [
    SELECT API_Endpoint__c, Timeout__c, Retry_Count__c
    FROM Integration_Setting__mdt
    WHERE DeveloperName = 'Order_API'
    LIMIT 1
];

HttpRequest req = new HttpRequest();
req.setEndpoint(setting.API_Endpoint__c);
req.setTimeout(Integer.valueOf(setting.Timeout__c));

// ❌ BAD: Hardcoded configuration (requires code deploy to change!)
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.example.com/orders');
req.setTimeout(120000);
```

**Reusable LWC Components**:
```javascript
// ✅ GOOD: Create reusable components
// customButton.js (reusable button component)
import { LightningElement, api } from 'lwc';

export default class CustomButton extends LightningElement {
    @api label;
    @api variant = 'neutral'; // brand, neutral, destructive
    @api disabled = false;

    handleClick() {
        this.dispatchEvent(new CustomEvent('buttonclick'));
    }
}

// Usage in multiple components
<c-custom-button label="Save" variant="brand" onbuttonclick={handleSave}></c-custom-button>
<c-custom-button label="Delete" variant="destructive" onbuttonclick={handleDelete}></c-custom-button>
```

---

### 3. Adaptable (Scalability, Flexibility)

**Core Principle**: Solutions should handle growth (10x, 100x volume) and adapt to changing business requirements without major rework.

#### Key Principles

**Scalability**:
- Handle 10x growth without redesign (data volume, user count, transaction volume)
- Respect governor limits (design for bulk operations)
- Async processing for high-volume operations (Batch, Queueable, Platform Events)
- Efficient queries (indexed fields, selective filters, aggregate queries)
- Caching strategies (Platform Cache, local caching)

**Flexibility**:
- Easy to add features (modular design, plugin architecture)
- Easy to change business rules (configuration over code)
- Support multiple use cases (generic designs, parameterized components)
- Feature flags for gradual rollouts (Custom Metadata, Custom Permissions)

**Extensibility**:
- APIs for external systems (REST/SOAP, versioned endpoints)
- Webhooks for event notifications (Platform Events, Outbound Messages)
- Integration patterns (middleware, ESB, point-to-point)
- Managed packages for reusable solutions

#### Patterns for Adaptable Solutions

**Platform Events for Async Scaling**:
```apex
// ✅ GOOD: Use Platform Events for elastic scaling
// Publisher (doesn't wait for subscribers)
Order_Event__e event = new Order_Event__e(
    Order_Id__c = order.Id,
    Status__c = 'Processed',
    Amount__c = order.Amount__c
);
EventBus.publish(event);

// Subscriber (processes events asynchronously, scales independently)
trigger OrderEventTrigger on Order_Event__e (after insert) {
    List<Order__c> ordersToUpdate = new List<Order__c>();
    for (Order_Event__e event : Trigger.new) {
        ordersToUpdate.add(new Order__c(
            Id = event.Order_Id__c,
            Status__c = event.Status__c
        ));
    }
    update ordersToUpdate;
}

// Benefit: If you need to add another subscriber (e.g., send to external system),
// you don't modify the publisher - just add a new subscriber!
```

**Custom Metadata for Business Rules** (No Code Deploys!):
```apex
// ✅ GOOD: Use Custom Metadata for configurable business rules
// Discount_Rule__mdt custom metadata:
// Rule Name: Large_Order_Discount
// Min_Amount__c: 10000
// Discount_Percentage__c: 15

public class DiscountService {
    private static Map<String, Discount_Rule__mdt> rules;

    static {
        // Load all discount rules (cached)
        rules = new Map<String, Discount_Rule__mdt>();
        for (Discount_Rule__mdt rule : [SELECT DeveloperName, Min_Amount__c, Discount_Percentage__c FROM Discount_Rule__mdt]) {
            rules.put(rule.DeveloperName, rule);
        }
    }

    public static Decimal calculateDiscount(Decimal amount) {
        // Business rule: If amount >= 10000, apply 15% discount
        Discount_Rule__mdt largeOrderRule = rules.get('Large_Order_Discount');
        if (amount >= largeOrderRule.Min_Amount__c) {
            return amount * (largeOrderRule.Discount_Percentage__c / 100);
        }
        return 0;
    }
}

// Benefit: Change discount rule via Setup (no code deploy!)
// Add new rules without modifying code
```

**Versioned APIs with Deprecation Strategy**:
```apex
// ✅ GOOD: Version your REST APIs
@RestResource(urlMapping='/api/v1/orders/*')
global class OrderRestController_v1 {
    @HttpGet
    global static Order__c getOrder() {
        // v1 implementation (basic fields)
        return [SELECT Id, Name, Status__c FROM Order__c WHERE Id = :orderId];
    }
}

@RestResource(urlMapping='/api/v2/orders/*')
global class OrderRestController_v2 {
    @HttpGet
    global static OrderResponse getOrder() {
        // v2 implementation (enhanced response with more fields)
        Order__c order = [SELECT Id, Name, Status__c, Amount__c, Tax__c FROM Order__c WHERE Id = :orderId];
        return new OrderResponse(order);
    }
}

// Benefit: External systems can migrate at their own pace
// v1 deprecated but still functional for 6 months
```

**Feature Flags for Gradual Rollouts**:
```apex
// ✅ GOOD: Use Custom Permissions for feature flags
// Custom Permission: "Enable_Advanced_Reporting"

public class ReportingService {
    public static List<Report> getAvailableReports() {
        List<Report> reports = getBasicReports();

        // Check if user has advanced reporting enabled
        if (FeatureManagement.checkPermission('Enable_Advanced_Reporting')) {
            reports.addAll(getAdvancedReports());
        }

        return reports;
    }
}

// Benefit: Enable features for pilot users, then roll out gradually
// No code changes needed to enable/disable features
```

---

## Evaluating Decisions Against All Three Pillars

**Example Decision**: "Should we use Batch Apex or Queueable Apex for order processing?"

### Evaluate: Trusted

- **Batch Apex**: Higher governor limits (200 SOQL, 60s CPU), good for millions of records
- **Queueable Apex**: Standard limits (100 SOQL, 10s CPU), can chain jobs
- **Winner**: Batch Apex (more reliable for high volume)

### Evaluate: Easy

- **Batch Apex**: More complex to implement (3 methods: start, execute, finish)
- **Queueable Apex**: Simpler to implement (1 method: execute)
- **Winner**: Queueable Apex (easier to maintain)

### Evaluate: Adaptable

- **Batch Apex**: Scales to millions of records
- **Queueable Apex**: Limited to 50 chained jobs (can process 10K+ records per chain)
- **Winner**: Batch Apex (scales better for future growth)

### Trade-off Analysis

| Criterion | Batch Apex | Queueable Apex |
|-----------|------------|----------------|
| **Trusted** (Reliability) | ✅ High volume | ⚠️ Limited to 50 chains |
| **Easy** (Maintainability) | ⚠️ More complex | ✅ Simpler code |
| **Adaptable** (Scalability) | ✅ Millions of records | ⚠️ Limited to 10K-50K records |

**Decision**: If current volume < 10K records and expected to stay there, use **Queueable** (Easy wins). If volume > 10K or expected to grow significantly, use **Batch** (Trusted + Adaptable wins).

**Key Insight**: There's no "always right" answer. Evaluate against ALL three pillars based on your specific requirements.

---

## Well-Architected Checklist

Before finalizing any architectural decision, verify:

**Trusted**:
- ✅ Security enforced (CRUD/FLS, input validation, encryption)
- ✅ Compliance requirements met (GDPR, HIPAA, etc.)
- ✅ Failure scenarios handled (retry logic, error logging, alerts)
- ✅ Audit trails in place (who changed what, when)

**Easy**:
- ✅ User experience is intuitive (users can accomplish tasks easily)
- ✅ Code is maintainable (clean, modular, documented)
- ✅ Components are reusable (DRY principle)
- ✅ Tests are comprehensive (75%+ coverage, meaningful assertions)

**Adaptable**:
- ✅ Scales to 10x current volume (without redesign)
- ✅ Business rules are configurable (Custom Metadata, not hardcoded)
- ✅ Features can be added without major rework (modular design)
- ✅ Integrations are versioned and backward-compatible

---

## Common Anti-Patterns (Avoid These!)

### 1. Trusted Violations

❌ **Bypassing Security**: Using `without sharing` without justification
❌ **No Error Handling**: Assuming external APIs always work
❌ **Hardcoded Credentials**: Storing passwords/API keys in code

### 2. Easy Violations

❌ **Monster Classes**: 2000+ line classes that do everything
❌ **No Documentation**: Code with no comments or README
❌ **Copy-Paste Code**: Duplicating logic instead of extracting to utility classes

### 3. Adaptable Violations

❌ **Hardcoded Business Rules**: `if (amount > 10000)` instead of Custom Metadata
❌ **Single-Record Processing**: Loops with SOQL queries or DML operations inside
❌ **No Versioning**: Changing API contracts without versioning

---

## Well-Architected = Balanced

**The best solutions excel in ALL three pillars:**
- **Trusted**: Users trust the system with their data and business processes
- **Easy**: Users love using it, developers love maintaining it
- **Adaptable**: Grows with the business, adapts to changing requirements

**If you optimize for only one pillar, you'll create problems in the others.**

**Applies to**: All Salesforce employees (Architects, Developers, Admins) and ALL architectural decisions
