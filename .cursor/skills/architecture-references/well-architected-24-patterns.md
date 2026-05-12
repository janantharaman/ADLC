# Salesforce Well-Architected: 24 Proven Patterns

**Source**: Salesforce Well-Architected Framework (architect.salesforce.com)

The Well-Architected Framework defines 24 proven patterns across three pillars: **Trusted**, **Easy**, and **Adaptable**. Each pattern provides guidance for building production-ready Salesforce solutions.

## Overview

| Pillar | Patterns | Focus |
|--------|----------|-------|
| 🛡️ **TRUSTED** | 8 patterns | Security, Privacy, Performance, Reliability |
| 🎯 **EASY** | 8 patterns | User Experience, Developer Experience, Simplicity |
| 🔄 **ADAPTABLE** | 8 patterns | Flexibility, Scalability, Composability |

---

## 🛡️ TRUSTED Pillar (8 Patterns)

### Pattern 1: Defense in Depth (Security)
**Problem**: Single security layer can be bypassed
**Solution**: Multiple overlapping security controls

**Implementation**:
```
Layer 1: Network (IP restrictions, VPN, Private Connect)
Layer 2: Authentication (MFA, SSO, session management)
Layer 3: Authorization (Profiles, permission sets)
Layer 4: Object Security (CRUD permissions)
Layer 5: Field Security (FLS)
Layer 6: Record Security (Sharing rules)
Layer 7: Data Encryption (Shield Platform Encryption)
Layer 8: Application Security (Input validation, SOQL injection prevention)
```

**Best Practices**:
- Enable MFA for all users
- Use IP restrictions for admin users
- Implement field-level encryption for PII/PHI
- Regular security reviews and audits

**Anti-Patterns**:
```
❌ Relying only on profile permissions
❌ Disabling security features for "ease of use"
❌ Using "without sharing" by default
❌ Storing sensitive data unencrypted
```

### Pattern 2: Least Privilege Access (Security)
**Problem**: Over-permissioned users increase security risk
**Solution**: Grant minimum permissions required

**Implementation**:
```apex
// Start with most restrictive profile
Profile: Minimum Access - Salesforce

// Add specific permissions via permission sets
Permission Set: View Accounts
Permission Set: Edit Opportunities
Permission Set: Run Reports

// Use permission set groups for roles
Permission Set Group: Sales Representative
  ├─ View Accounts
  ├─ Edit Opportunities
  └─ Run Reports
```

**Best Practices**:
- Review permissions quarterly
- Remove permissions when roles change
- Use permission set expiration dates
- Audit permission assignments regularly

### Pattern 3: Data Classification & Protection (Privacy)
**Problem**: All data treated with same security level
**Solution**: Classify and protect based on sensitivity

**Data Classification Levels**:
```
Level 1 - Public:
  - Product catalog, public knowledge articles
  - Controls: Standard security

Level 2 - Internal:
  - Employee directory, internal documents
  - Controls: Access control, OWD Private

Level 3 - Confidential:
  - Financial data, customer contracts
  - Controls: FLS, sharing rules, audit trail

Level 4 - Highly Confidential:
  - SSN, credit cards, health records
  - Controls: Shield Encryption, strict access, field audit trail
```

**Implementation**:
```apex
// Use custom labels for classification
Schema.DescribeFieldResult field = Account.SSN__c.getDescribe();
String classification = field.getLabel(); // "SSN (Highly Confidential)"

// Enforce at query time
List<Account> accounts = [
    SELECT Id, Name, SSN__c
    FROM Account
    WITH SECURITY_ENFORCED
];
```

### Pattern 4: Encryption at Rest & in Transit (Privacy)
**Problem**: Data vulnerable during storage and transmission
**Solution**: Encrypt data in all states

**At Rest**:
```
Shield Platform Encryption:
✓ Encrypts data in Salesforce databases
✓ FIPS 140-2 compliant
✓ Transparent to applications
✓ Key rotation supported

Classic Encryption:
✓ Field-level encryption (175 chars max)
✓ Masked in UI
✓ Requires "View Encrypted Data" permission
```

**In Transit**:
```
TLS 1.2/1.3:
✓ All Salesforce traffic encrypted
✓ Certificate pinning for mobile apps
✓ Mutual TLS for high-security integrations
```

**Best Practices**:
- Use Shield for regulated industries (HIPAA, PCI-DSS)
- Encrypt fields containing PII/PHI
- Use Named Credentials for external integrations (auto TLS)

### Pattern 5: Performance by Design (Performance)
**Problem**: Performance issues discovered after deployment
**Solution**: Build performance in from the start

**Performance Targets**:
```
UI Response Time: < 2 seconds
API Response Time: < 500ms
Batch Processing: Scale to millions of records
Concurrent Users: Support without degradation
```

**Implementation Checklist**:
```
Query Optimization:
✓ Use indexed fields in WHERE clauses
✓ Selective queries (filter to <10% of records)
✓ Minimize relationship queries depth
✓ Use SOQL for loops for large result sets

UI Optimization:
✓ Lazy load components
✓ Use Lightning Data Service caching
✓ Implement pagination
✓ Debounce user input
✓ Use Platform Cache for reference data

Bulk Processing:
✓ Batch Apex for >10,000 records
✓ Bulk API 2.0 for data loads
✓ Parallel processing where possible
```

### Pattern 6: Observability & Monitoring (Reliability)
**Problem**: Issues not detected until user reports
**Solution**: Proactive monitoring and alerting

**Key Metrics**:
```
Performance Metrics:
- Page load time (target: <2s)
- API response time (target: <500ms)
- Apex CPU time (% of limits)
- SOQL query count

Business Metrics:
- Successful transactions
- Failed API calls
- Integration errors
- User adoption (logins, feature usage)

Resource Metrics:
- Data storage (% of limit)
- File storage (% of limit)
- API usage (% of daily limit)
```

**Implementation**:
```apex
// Custom logging framework
public class Logger {
    public static void log(String level, String message, Exception ex) {
        Log__c log = new Log__c(
            Level__c = level,
            Message__c = message,
            Stack_Trace__c = ex?.getStackTraceString(),
            Timestamp__c = Datetime.now()
        );
        insert log;

        // Send critical errors to Slack/PagerDuty
        if (level == 'ERROR') {
            notifyOps(log);
        }
    }
}
```

**Monitoring Tools**:
- Event Monitoring (tracks API, reports, logins)
- Transaction Security Policies (detect anomalies)
- Platform Events (real-time event streaming)
- Custom dashboards (performance metrics)

### Pattern 7: Resilience & Fault Tolerance (Reliability)
**Problem**: Single point of failure causes system outage
**Solution**: Design for failure, build redundancy

**Resilience Patterns**:
```
Circuit Breaker Pattern:
- Stop calling failing external system
- Return cached data or default response
- Retry after cooldown period

@future(callout=true)
public static void callExternalSystem() {
    if (isCircuitOpen('ExternalAPI')) {
        // Return cached data
        return getCachedData();
    }

    try {
        // Make callout
        HttpResponse res = http.send(req);
        resetCircuit('ExternalAPI');
    } catch (Exception e) {
        incrementFailureCount('ExternalAPI');
        if (getFailureCount('ExternalAPI') > 5) {
            openCircuit('ExternalAPI');
        }
    }
}

Retry Pattern with Exponential Backoff:
- Retry failed operations
- Increase delay between retries
- Set maximum retry attempts

public void retryOperation() {
    Integer maxRetries = 3;
    Integer retryCount = 0;
    Integer delayMs = 1000;

    while (retryCount < maxRetries) {
        try {
            performOperation();
            return; // Success
        } catch (Exception e) {
            retryCount++;
            if (retryCount >= maxRetries) {
                throw e; // Failed after all retries
            }
            // Exponential backoff: 1s, 2s, 4s
            Thread.sleep(delayMs * Math.pow(2, retryCount - 1));
        }
    }
}
```

**Best Practices**:
- Implement idempotency (duplicate requests safe)
- Use async processing for non-critical operations
- Cache frequently accessed data
- Design for graceful degradation

### Pattern 8: Disaster Recovery & Business Continuity (Reliability)
**Problem**: Data loss or system unavailability
**Solution**: Backup, recovery, and continuity planning

**Backup Strategy**:
```
Daily Backups:
✓ Automated daily backups (Salesforce built-in)
✓ Weekly exports via Data Loader
✓ Third-party backup solution (OwnBackup, Spanning)

What to Back Up:
✓ All data (standard and custom objects)
✓ Metadata (configuration, code)
✓ Attachments and files
✓ Chatter posts and feeds
```

**Recovery Planning**:
```
RTO (Recovery Time Objective): 4 hours
RPO (Recovery Point Objective): 24 hours

Recovery Scenarios:
1. Accidental deletion → Restore from recycle bin (15 days)
2. Mass data corruption → Restore from daily backup
3. Org unavailable → Failover to sandbox (read-only mode)
4. Complete data loss → Restore from weekly export
```

---

## 🎯 EASY Pillar (8 Patterns)

### Pattern 9: Progressive Disclosure (User Experience)
**Problem**: Users overwhelmed with too many fields/options
**Solution**: Show what's needed, when it's needed

**Implementation**:
```
Record Pages:
✓ Use tabs to group related fields
✓ Use sections with collapsible headers
✓ Hide advanced fields with dynamic forms
✓ Use Path component for guided experience

Forms:
✓ Show required fields first
✓ Conditional visibility based on selections
✓ Multi-step wizards for complex processes
✓ Inline help for complex fields
```

**Example (LWC)**:
```javascript
<template>
    <!-- Basic fields always visible -->
    <lightning-input label="Account Name" required></lightning-input>
    <lightning-input label="Industry"></lightning-input>

    <!-- Advanced section - collapsed by default -->
    <lightning-accordion>
        <lightning-accordion-section label="Advanced Details">
            <lightning-input label="SIC Code"></lightning-input>
            <lightning-input label="D&B Number"></lightning-input>
        </lightning-accordion-section>
    </lightning-accordion>

    <!-- Conditional field - only show if custom -->
    <template if:true={isCustomIndustry}>
        <lightning-input label="Custom Industry"></lightning-input>
    </template>
</template>
```

### Pattern 10: Declarative First (Developer Experience)
**Problem**: Custom code is hard to maintain
**Solution**: Use declarative tools before writing code

**Decision Flow**:
```
Can it be done with Flows? → YES → Use Flow
  ↓ NO
Can it be done with validation rules? → YES → Use Validation Rule
  ↓ NO
Can it be done with formula fields? → YES → Use Formula Field
  ↓ NO
Can it be done with process builder? → YES → Use Flow (migrate PB)
  ↓ NO
Requires custom Apex → Write Apex with invocable actions (callable from Flow)
```

**Benefits**:
```
✓ Easier to maintain (visual vs code)
✓ Faster to build (drag and drop)
✓ Admins can modify without developer
✓ Lower TCO (total cost of ownership)
```

**When to Use Apex**:
```
Complex logic (nested conditions, calculations)
Bulk operations (>10,000 records)
External integrations (callouts)
Performance critical operations
Complex query logic (dynamic SOQL)
Governor limit optimization
```

### Pattern 11: Self-Service & Guided Experiences (User Experience)
**Problem**: Users need training for every task
**Solution**: Self-documenting UI with guidance

**Guidance Tools**:
```
1. Path Component:
   - Visual process guidance
   - Key fields and actions at each stage
   - Success tips and best practices

2. In-App Guidance:
   - Floating prompts for new features
   - Targeted messages based on context
   - Step-by-step walkthroughs

3. Help Text:
   - Field-level help (inline descriptions)
   - Rich text formatting supported
   - Context-specific guidance

4. Knowledge Base:
   - Self-service articles
   - Search functionality
   - Lightning Knowledge component
```

**Example (Flow Screen)**:
```
Screen 1: Welcome
  - Display Text: "This wizard will guide you through creating a new account."
  - Display Text: "You'll need: Company name, industry, and primary contact info."

Screen 2: Account Information
  - Account Name (required) - Help: "Enter the legal company name"
  - Industry (picklist) - Help: "Select the primary industry"
  - Annual Revenue - Help: "Estimated annual revenue in USD"

Screen 3: Review & Confirm
  - Display Account: Show all entered data
  - Checkbox: "I have verified this information is correct"
```

### Pattern 12: Consistent UI/UX (User Experience)
**Problem**: Inconsistent experience across pages
**Solution**: Use Salesforce Lightning Design System (SLDS)

**SLDS Benefits**:
```
✓ Consistent look and feel
✓ Accessibility built-in (WCAG 2.1 AA)
✓ Responsive design (mobile-first)
✓ Pre-built components
✓ Regular updates (follows Salesforce releases)
```

**Implementation**:
```html
<!-- Use Lightning base components -->
<lightning-card title="Account List">
    <lightning-datatable
        key-field="Id"
        data={accounts}
        columns={columns}>
    </lightning-datatable>
</lightning-card>

<!-- Use SLDS classes for custom HTML -->
<div class="slds-card slds-p-around_medium">
    <h2 class="slds-text-heading_medium">Account Details</h2>
    <div class="slds-grid slds-gutters">
        <div class="slds-col slds-size_1-of-2">
            <!-- Content -->
        </div>
    </div>
</div>
```

**UI Standards Checklist**:
```
✓ Use Lightning base components (not custom HTML)
✓ Follow SLDS spacing and sizing
✓ Use SLDS icons and colors
✓ Implement responsive grid system
✓ Test on mobile devices
✓ Verify accessibility (keyboard navigation, screen readers)
```

### Pattern 13: Testable & Maintainable Code (Developer Experience)
**Problem**: Code breaks with changes, hard to debug
**Solution**: Write clean, testable, well-documented code

**Clean Code Principles**:
```
1. Single Responsibility:
   - Each class has one job
   - Each method does one thing
   - Separation of concerns

2. DRY (Don't Repeat Yourself):
   - Extract common logic to utility classes
   - Use inheritance/composition

3. Meaningful Names:
   - Classes: AccountService (noun)
   - Methods: processAccounts() (verb)
   - Variables: filteredAccounts (descriptive)

4. Small Functions:
   - Methods < 50 lines
   - Clear input/output
   - Single level of abstraction
```

**Test Strategy**:
```apex
@isTest
private class AccountServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create shared test data once
        TestDataFactory.insertAccounts(200);
    }

    @isTest
    static void testProcessAccounts_WithValidData_Success() {
        // Given (Arrange)
        List<Account> accounts = [SELECT Id FROM Account];

        // When (Act)
        Test.startTest();
        AccountService.processAccounts(accounts);
        Test.stopTest();

        // Then (Assert)
        List<Account> processed = [SELECT Id, Status__c FROM Account];
        for (Account acc : processed) {
            System.assertEquals('Processed', acc.Status__c, 'Status should be updated');
        }
    }

    @isTest
    static void testProcessAccounts_WithInvalidData_ThrowsException() {
        // When/Then
        try {
            AccountService.processAccounts(null);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('accounts'), 'Error message should mention accounts');
        }
    }
}
```

### Pattern 14: Documentation as Code (Developer Experience)
**Problem**: Documentation outdated or missing
**Solution**: Document within code and automate

**Documentation Types**:
```apex
/**
 * Service class for Account business logic
 * Handles account creation, updates, and related operations
 *
 * @author John Doe
 * @date 2024-01-15
 * @version 1.0
 */
public with sharing class AccountService {

    /**
     * Creates new accounts with default values
     *
     * @param accountNames List of account names to create
     * @return List of created Account records
     * @throws IllegalArgumentException if accountNames is null or empty
     *
     * @example
     * List<String> names = new List<String>{'Acme Corp', 'TechCo'};
     * List<Account> accounts = AccountService.createAccounts(names);
     */
    public static List<Account> createAccounts(List<String> accountNames) {
        // Validate input
        if (accountNames == null || accountNames.isEmpty()) {
            throw new IllegalArgumentException('Account names cannot be empty');
        }

        // Create accounts
        List<Account> accounts = new List<Account>();
        for (String name : accountNames) {
            accounts.add(new Account(
                Name = name,
                Rating = 'Warm' // Default rating for new accounts
            ));
        }

        return accounts;
    }
}
```

**Auto-Generated Documentation**:
```
ApexDocs:
- Generates HTML docs from Javadoc comments
- Updates automatically from source code
- Hosted on internal wiki/Confluence

Metadata Documentation:
- Custom fields with descriptions
- Help text on all fields
- Page layout annotations
```

### Pattern 15: Reusable Components (Developer Experience)
**Problem**: Duplicate code across projects
**Solution**: Build component library

**Component Types**:
```
Utility Classes:
- StringUtility: String manipulation
- DateUtility: Date calculations
- ValidationUtility: Common validations
- EmailHelper: Email formatting and sending

LWC Components:
- error-panel: Standard error display
- loading-spinner: Loading indicator
- confirmation-modal: Confirmation dialogs
- data-table: Enhanced datatable

Invocable Actions:
- Send Custom Email
- Create PDF Document
- Call External API
- Generate Report
```

**Packaging**:
```
Unlocked Package: "Common Utilities v1.0"
├─ Apex Classes
│  ├─ StringUtility
│  ├─ DateUtility
│  └─ ValidationUtility
├─ LWC Components
│  ├─ errorPanel
│  ├─ loadingSpinner
│  └─ confirmationModal
└─ Custom Metadata
   └─ Configuration__mdt
```

### Pattern 16: Usability Testing (User Experience)
**Problem**: UI doesn't match user needs
**Solution**: Test with real users iteratively

**Testing Methods**:
```
1. Prototype Testing:
   - Low-fidelity mockups
   - Test core workflows
   - Identify major issues early

2. Usability Testing:
   - Observe users completing tasks
   - Measure time and errors
   - Collect qualitative feedback

3. A/B Testing:
   - Test two versions simultaneously
   - Measure conversion/completion rates
   - Choose best-performing version

4. Analytics Review:
   - Track feature adoption
   - Identify drop-off points
   - Measure time on page
```

**Implementation**:
```
UAT (User Acceptance Testing):
Phase 1: Internal testing (1 week)
  - Test core workflows
  - Verify business logic
  - Check edge cases

Phase 2: Pilot users (2 weeks)
  - 5-10 representative users
  - Monitor usage patterns
  - Collect feedback

Phase 3: Rollout (gradual)
  - Enable for 25% of users
  - Monitor adoption and issues
  - Enable for 100% after validation
```

---

## 🔄 ADAPTABLE Pillar (8 Patterns)

### Pattern 17: Configuration Over Customization (Flexibility)
**Problem**: Hard-coded values require code changes
**Solution**: Externalize configuration to metadata

**Configuration Storage Options**:
```
Custom Metadata Types (Recommended):
✓ Deployable between orgs
✓ Version controlled
✓ Queryable with SOQL
✓ No governor limits
✓ Cacheable

Custom Settings (Legacy):
✓ Hierarchical (org/profile/user level)
✓ List-based (name-value pairs)
✓ Fast access (cached)
✗ Not deployable as configuration

Big Objects:
✓ Store billions of records
✓ Custom indexes
✗ Limited query functionality
✗ Not for configuration
```

**Example**:
```apex
// ❌ Hard-coded configuration
public class PaymentProcessor {
    private static final String API_ENDPOINT = 'https://api.payment.com';
    private static final Integer TIMEOUT = 30000;
    private static final String API_KEY = 'abc123'; // Security issue!
}

// ✅ Configuration via Custom Metadata
public class PaymentProcessor {
    private static Payment_Config__mdt config = getConfiguration();

    private static Payment_Config__mdt getConfiguration() {
        return [
            SELECT API_Endpoint__c, Timeout__c, API_Key__c
            FROM Payment_Config__mdt
            WHERE DeveloperName = 'Production'
            LIMIT 1
        ];
    }

    public static void processPayment() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.API_Endpoint__c);
        req.setTimeout(Integer.valueOf(config.Timeout__c));
        // API key stored in Named Credential
    }
}
```

### Pattern 18: API-First Design (Composability)
**Problem**: Tight coupling between systems
**Solution**: Design APIs before implementation

**API Design Principles**:
```
1. RESTful:
   - Resource-based URLs (/accounts, /contacts)
   - HTTP verbs (GET, POST, PUT, DELETE)
   - Stateless

2. Versioned:
   - /services/apexrest/v1/accounts
   - /services/apexrest/v2/accounts
   - Maintain backwards compatibility

3. Self-Documenting:
   - Clear resource names
   - Consistent structure
   - Include documentation endpoint

4. Secured:
   - OAuth 2.0 authentication
   - Rate limiting
   - Input validation
```

**Implementation**:
```apex
@RestResource(urlMapping='/v1/accounts/*')
global with sharing class AccountAPI {

    @HttpGet
    global static Account getAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

        return [
            SELECT Id, Name, Industry, AnnualRevenue
            FROM Account
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
        ];
    }

    @HttpPost
    global static String createAccount(String name, String industry) {
        // Validate input
        if (String.isBlank(name)) {
            RestContext.response.statusCode = 400;
            return '{"error":"Account name is required"}';
        }

        // Check CRUD
        if (!Schema.sObjectType.Account.isCreateable()) {
            RestContext.response.statusCode = 403;
            return '{"error":"Insufficient permissions"}';
        }

        // Create account
        Account acc = new Account(Name = name, Industry = industry);
        insert acc;

        RestContext.response.statusCode = 201;
        return acc.Id;
    }
}
```

### Pattern 19: Event-Driven Architecture (Composability)
**Problem**: Tight coupling between processes
**Solution**: Use events for decoupled communication

**Event Types**:
```
Platform Events:
✓ Publish-subscribe pattern
✓ Decoupled systems
✓ Async processing
✓ 24-hour retention

Change Data Capture:
✓ Automatic on record changes
✓ Real-time updates
✓ No code required

Custom Events (LWC):
✓ Component communication
✓ Parent-child decoupling
✓ Event bubbling
```

**Implementation**:
```apex
// Publisher: Order processing
public class OrderService {
    public static void processOrder(Order__c order) {
        // Process order logic

        // Publish event
        Order_Processed__e event = new Order_Processed__e(
            Order_Id__c = order.Id,
            Total_Amount__c = order.Total_Amount__c,
            Status__c = 'Processed'
        );
        EventBus.publish(event);
    }
}

// Subscriber: Fulfillment system
trigger OrderProcessedEventTrigger on Order_Processed__e (after insert) {
    List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();

    for (Order_Processed__e event : Trigger.new) {
        fulfillments.add(new Fulfillment__c(
            Order_Id__c = event.Order_Id__c,
            Status__c = 'Pending',
            Amount__c = event.Total_Amount__c
        ));
    }

    insert fulfillments;
}

// Another Subscriber: Analytics system (external)
// Listens via Streaming API, no Salesforce code needed
```

**Benefits**:
```
✓ Loose coupling (publisher doesn't know subscribers)
✓ Scalability (multiple subscribers)
✓ Fault tolerance (async processing)
✓ Real-time integration
```

### Pattern 20: Microservices Architecture (Scalability)
**Problem**: Monolithic org becomes unmanageable
**Solution**: Decompose into smaller, focused services

**Decomposition Strategy**:
```
By Business Capability:
- Sales Org: Leads, Opportunities, Quotes
- Service Org: Cases, Knowledge, Entitlements
- Marketing Org: Campaigns, Journeys, Events
- Operations Org: Orders, Fulfillment, Inventory

By Data Domain:
- Customer Data Org: Accounts, Contacts
- Product Data Org: Products, Price Books
- Transaction Data Org: Orders, Invoices
- Analytics Org: Reports, Dashboards
```

**Integration**:
```
API Gateway Pattern:
External System → API Gateway → Sales Org
                              → Service Org
                              → Marketing Org

Event-Driven Pattern:
Sales Org → Platform Event → Service Org
                          → Marketing Org
                          → Analytics Org
```

**Best Practices**:
```
✓ Each org owns specific data domain
✓ Cross-org communication via APIs or events
✓ Shared services (authentication, logging)
✓ Independent deployment cycles
✓ Org-specific governance
```

**Challenges**:
```
- Data duplication (eventual consistency)
- Cross-org reporting (use Data Cloud)
- Transaction management (saga pattern)
- Increased operational complexity
```

### Pattern 21: Data Archival & Retention (Scalability)
**Problem**: Growing data volume impacts performance
**Solution**: Archive old data, retain what's needed

**Archival Strategy**:
```
Retention Policy:
0-2 years:   Active data (standard objects)
2-5 years:   Archived data (Big Objects)
5-7 years:   Compliance archive (external storage)
7+ years:    Deleted (per legal requirements)
```

**Implementation Options**:
```
Option 1: Big Objects (Salesforce-native)
✓ Store billions of records
✓ Custom indexes for queries
✓ Queryable via SOQL
✗ Limited to specific query patterns
✗ No relationships

Option 2: External Objects (External storage)
✓ Data stays in external system
✓ Queryable via SOQL (like native)
✓ No Salesforce storage limits
✗ Network latency
✗ Requires external system

Option 3: Data Masking (Compliance)
✓ Retain record structure
✓ Anonymize sensitive data
✓ Meet GDPR "right to be forgotten"
✗ Data not recoverable
```

**Archival Process**:
```apex
// Batch Apex to archive old cases
public class CaseArchivalBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Cases closed > 2 years ago
        Date archiveDate = Date.today().addYears(-2);
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, Subject, Status, ClosedDate,
                   (SELECT Id, CommentBody FROM CaseComments)
            FROM Case
            WHERE Status = 'Closed'
            AND ClosedDate < :archiveDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        // Archive to Big Object
        List<Case_Archive__b> archives = new List<Case_Archive__b>();

        for (Case c : scope) {
            archives.add(new Case_Archive__b(
                Case_Id__c = c.Id,
                Case_Number__c = c.CaseNumber,
                Subject__c = c.Subject,
                Status__c = c.Status,
                Closed_Date__c = c.ClosedDate
            ));
        }

        database.insertImmediate(archives); // Big Object insert

        // Delete original cases
        delete scope;
    }

    public void finish(Database.BatchableContext bc) {
        // Send completion notification
    }
}
```

### Pattern 22: Multi-Tenant Architecture (Flexibility)
**Problem**: Single org serves multiple business units
**Solution**: Design for multi-tenancy from the start

**Isolation Strategies**:
```
Record Type-Based:
✓ Simple to implement
✓ Shared object schema
✗ Limited isolation
✗ Reporting complexity

Business Unit Field:
✓ Flexible filtering
✓ Sharing rules for isolation
✗ Manual enforcement
✗ Potential for errors

Separate Orgs:
✓ Complete isolation
✓ Independent governance
✗ Higher license cost
✗ Integration overhead
```

**Implementation (Record Type)**:
```apex
public with sharing class MultiTenantService {

    // Filter by record type (tenant)
    public static List<Account> getAccountsForTenant(Id recordTypeId) {
        return [
            SELECT Id, Name, Industry
            FROM Account
            WHERE RecordTypeId = :recordTypeId
            WITH SECURITY_ENFORCED
        ];
    }

    // Enforce tenant on insert
    public static void createAccount(Account acc, String tenantName) {
        Id recordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(tenantName)
            .getRecordTypeId();

        acc.RecordTypeId = recordTypeId;
        insert acc;
    }
}
```

**Best Practices**:
```
✓ Default tenant filters on list views
✓ Page layouts by record type
✓ Sharing rules for data isolation
✓ Validation rules to enforce tenant
✓ Separate permission sets per tenant
✓ Tenant-specific automation (flows, triggers)
```

### Pattern 23: Horizontal & Vertical Scaling (Scalability)
**Problem**: System cannot handle growth
**Solution**: Scale in multiple dimensions

**Horizontal Scaling** (More orgs):
```
Single Org → Multiple Orgs
  ↓
Geographic Distribution:
- North America Org
- Europe Org
- Asia-Pacific Org

Functional Distribution:
- Sales Org
- Service Org
- Marketing Org
- Operations Org
```

**Vertical Scaling** (Optimize within org):
```
Data Volume:
✓ Archive old data (Big Objects)
✓ Use external objects for large datasets
✓ Implement data partitioning

Processing:
✓ Batch Apex for bulk operations
✓ Platform Cache for frequently accessed data
✓ Asynchronous processing (@future, Queueable)

Query Performance:
✓ Custom indexes on frequently queried fields
✓ Skinny tables for large objects
✓ Selective queries (filter to <10% of records)
```

**Scaling Decision Matrix**:
```
| Dimension | Trigger | Strategy |
|-----------|---------|----------|
| Data Volume | >50M records | Archive, Big Objects, External Objects |
| Users | >10,000 concurrent | Multiple orgs, load balancing |
| Transactions | >1M API calls/day | Caching, async processing, Heroku |
| Integration | >100 systems | API gateway, event bus, middleware |
```

### Pattern 24: Graceful Degradation (Reliability)
**Problem**: External dependency failure breaks entire system
**Solution**: Degrade functionality, don't break

**Implementation**:
```apex
public class ProductPricingService {

    /**
     * Get product price with fallback
     * 1. Try external pricing system
     * 2. Fallback to cached prices
     * 3. Fallback to default prices
     */
    public static Decimal getProductPrice(String productId) {
        try {
            // Try external pricing system
            return callExternalPricingAPI(productId);

        } catch (CalloutException e) {
            // Fallback 1: Check platform cache
            Decimal cachedPrice = (Decimal) Cache.Org.get('price_' + productId);
            if (cachedPrice != null) {
                Logger.log('INFO', 'Using cached price for ' + productId);
                return cachedPrice;
            }

            // Fallback 2: Check Salesforce price book
            List<PricebookEntry> entries = [
                SELECT UnitPrice
                FROM PricebookEntry
                WHERE Product2Id = :productId
                AND Pricebook2.IsStandard = true
                LIMIT 1
            ];

            if (!entries.isEmpty()) {
                Logger.log('WARN', 'Using standard price book for ' + productId);
                return entries[0].UnitPrice;
            }

            // Fallback 3: Return default price
            Logger.log('ERROR', 'All pricing sources failed for ' + productId);
            return 0.00; // Or throw exception if price is critical
        }
    }

    /**
     * Batch process with partial success
     */
    public static void processOrders(List<Order__c> orders) {
        List<Order__c> successfulOrders = new List<Order__c>();
        List<Order__c> failedOrders = new List<Order__c>();

        for (Order__c order : orders) {
            try {
                processOrder(order);
                successfulOrders.add(order);
            } catch (Exception e) {
                // Log error but continue processing other orders
                Logger.log('ERROR', 'Failed to process order ' + order.Id, e);
                failedOrders.add(order);
            }
        }

        // Update successful orders
        if (!successfulOrders.isEmpty()) {
            update successfulOrders;
        }

        // Queue failed orders for retry
        if (!failedOrders.isEmpty()) {
            queueForRetry(failedOrders);
        }
    }
}
```

**Degradation Levels**:
```
Level 1: Full Functionality
  - All features working
  - Real-time external data

Level 2: Reduced Functionality
  - Core features working
  - Cached external data (slightly stale)

Level 3: Essential Only
  - Critical features only
  - Default/fallback values
  - Read-only mode

Level 4: Maintenance Mode
  - Error message to users
  - No data processing
  - Retry mechanism active
```

**Best Practices**:
```
✓ Identify critical vs non-critical features
✓ Implement caching for external data
✓ Design fallback mechanisms
✓ Monitor external dependencies
✓ Alert operations on degradation
✓ Provide clear user messages
```

---

## Pattern Selection Guide

### By Project Type

**New Implementation**:
1. Configuration Over Customization (17)
2. API-First Design (18)
3. Defense in Depth (1)
4. Performance by Design (5)
5. Testable Code (13)

**Legacy Modernization**:
1. Microservices Architecture (20)
2. Event-Driven Architecture (19)
3. Data Archival (21)
4. Graceful Degradation (24)

**Scalability Requirements**:
1. Horizontal & Vertical Scaling (23)
2. Data Archival & Retention (21)
3. Multi-Tenant Architecture (22)
4. Event-Driven Architecture (19)

**Compliance Requirements**:
1. Data Classification & Protection (3)
2. Encryption at Rest & in Transit (4)
3. Defense in Depth (1)
4. Least Privilege Access (2)

**User Experience Focus**:
1. Progressive Disclosure (9)
2. Self-Service & Guided Experiences (11)
3. Consistent UI/UX (12)
4. Usability Testing (16)

### By Business Driver

| Driver | Primary Patterns | Secondary Patterns |
|--------|------------------|-------------------|
| **Security** | 1, 2, 3, 4 | 6, 7, 24 |
| **Performance** | 5, 21, 23 | 6, 19, 20 |
| **User Adoption** | 9, 11, 12 | 16, 10, 14 |
| **Scalability** | 23, 21, 20 | 19, 22, 18 |
| **Maintainability** | 13, 14, 15 | 10, 17, 18 |
| **Flexibility** | 17, 18, 22 | 19, 10, 15 |
| **Reliability** | 7, 8, 24 | 6, 19, 20 |
| **Compliance** | 3, 4, 2 | 1, 6, 8 |

---

## Implementation Checklist

For each new project, evaluate against the Well-Architected patterns:

### Phase 1: Design
- [ ] Identify which patterns apply to this project
- [ ] Document architectural decisions and trade-offs
- [ ] Create architecture diagram showing pattern usage
- [ ] Review with stakeholders and technical team

### Phase 2: Implementation
- [ ] Implement security patterns first (defense in depth)
- [ ] Build configuration layer (externalize settings)
- [ ] Design APIs before implementation
- [ ] Create reusable components for common functionality

### Phase 3: Testing
- [ ] Test performance under load
- [ ] Test security controls (CRUD/FLS, sharing)
- [ ] Test degradation scenarios (external failures)
- [ ] Conduct usability testing with real users

### Phase 4: Deployment
- [ ] Deploy monitoring and observability tools
- [ ] Document runbooks for common issues
- [ ] Train users on new features
- [ ] Plan for gradual rollout (pilot → full)

### Phase 5: Operations
- [ ] Monitor key metrics (performance, adoption, errors)
- [ ] Review architecture quarterly
- [ ] Refactor based on lessons learned
- [ ] Update documentation continuously

---

## Resources

- **Official Site**: https://architect.salesforce.com/
- **Well-Architected Framework**: https://architect.salesforce.com/design/well-architected
- **Reference Architectures**: https://architect.salesforce.com/diagrams
- **Best Practices**: https://architect.salesforce.com/articles
- **Certifications**: Technical Architect, Application Architect, System Architect

---

**Remember**: These 24 patterns provide a proven foundation for building **TRUSTED**, **EASY**, and **ADAPTABLE** Salesforce solutions. Apply them thoughtfully based on your specific requirements and constraints.
