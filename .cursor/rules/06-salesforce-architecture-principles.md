---
alwaysApply: true
---

# Salesforce Architecture Principles

This rule embodies architectural excellence from **architect.salesforce.com** - the official Salesforce Architect resource. These principles guide ALL solution design decisions.

**Source**: https://architect.salesforce.com/

## Salesforce Well-Architected Framework

The Well-Architected Framework consists of three pillars that must be balanced in every solution:

### 1. 🛡️ TRUSTED - Security, Privacy, and Performance
**Definition**: Solutions must be secure, reliable, and performant.

#### Security & Privacy
- **Data Protection**: Encrypt sensitive data at rest and in transit
- **Access Control**: Implement least privilege principle
- **Audit Trail**: Enable field history tracking and setup audit trail
- **Compliance**: Meet regulatory requirements (GDPR, HIPAA, SOC 2)
- **Privacy by Design**: Build privacy into solutions from the start

**Key Practices**:
```
✓ Use Shield Platform Encryption for regulated data
✓ Implement field-level security for sensitive fields
✓ Configure sharing model to restrict access
✓ Enable Event Monitoring for security analytics
✓ Use Private Connect for secure external integrations
✓ Implement data masking for sandbox refreshes
```

#### Performance & Reliability
- **Response Time**: UI interactions < 2 seconds
- **Throughput**: Support concurrent users without degradation
- **Availability**: Design for 99.9%+ uptime
- **Scalability**: Handle growth in data, users, transactions

**Key Practices**:
```
✓ Use indexed fields in SOQL queries
✓ Implement lazy loading for UI components
✓ Use batch processing for bulk operations
✓ Configure platform cache for frequently accessed data
✓ Monitor API usage and optimize integrations
✓ Use CDN for static resources
```

### 2. 🎯 EASY - Simple, Efficient, and Usable
**Definition**: Solutions must be intuitive, maintainable, and delightful to use.

#### User Experience
- **Intuitive**: Users can accomplish tasks without training
- **Efficient**: Minimize clicks and steps
- **Consistent**: Follow Salesforce Lightning Design System (SLDS)
- **Accessible**: Meet WCAG 2.1 AA standards
- **Mobile-First**: Design for mobile users

**Key Practices**:
```
✓ Use standard Lightning components first
✓ Implement progressive disclosure (show what's needed, when needed)
✓ Provide inline help and guidance
✓ Use SLDS for consistent UI
✓ Test on mobile devices
✓ Implement keyboard navigation
```

#### Developer Experience
- **Maintainable**: Code is easy to understand and modify
- **Documented**: Clear documentation and comments
- **Testable**: Comprehensive automated tests
- **Reusable**: Components can be reused across solutions
- **Standard**: Follow Salesforce best practices

**Key Practices**:
```
✓ Use declarative tools (Flows) before custom code
✓ Follow naming conventions consistently
✓ Write self-documenting code with clear names
✓ Maintain 80%+ code coverage with meaningful tests
✓ Use design patterns (service layer, selector, etc.)
✓ Version control all metadata
```

### 3. 🔄 ADAPTABLE - Flexible, Scalable, and Composable
**Definition**: Solutions must evolve with changing business needs.

#### Flexibility
- **Configurable**: Business users can adjust behavior without code
- **Extensible**: New features can be added without breaking existing
- **Modular**: Components are loosely coupled
- **Multi-Tenant**: Support multiple business units or customers

**Key Practices**:
```
✓ Use Custom Metadata for configuration (not hard-coded values)
✓ Design for record types and page layouts
✓ Use permission sets for flexible access control
✓ Implement dynamic forms and conditional visibility
✓ Use Lightning App Builder for page customization
✓ Design APIs with versioning strategy
```

#### Scalability
- **Data Volume**: Support millions of records
- **User Growth**: Handle increasing concurrent users
- **Transaction Volume**: Process high throughput
- **Geographic Distribution**: Serve global users

**Key Practices**:
```
✓ Use Big Objects for high-volume historical data
✓ Implement data archival strategy
✓ Use Batch Apex for processing >10,000 records
✓ Partition data with sharing architecture
✓ Use Platform Events for event-driven architecture
✓ Implement caching strategy (Platform Cache, CDN)
```

## Architectural Design Patterns

### 1. Data Management Patterns

#### Master Data Management (MDM)
**Problem**: Multiple systems contain duplicate/conflicting customer data
**Solution**: Salesforce as single source of truth for customer data

**Pattern**:
```
External Systems → Integration Layer → Salesforce (Master)
                                          ↓
                                    Golden Record
```

**Best Practices**:
- Use External IDs for system integration
- Implement duplicate management rules
- Use Data Cloud for unified customer view
- Establish data governance process

#### Data Archival
**Problem**: Large data volumes impact performance
**Solution**: Archive old data to Big Objects or external storage

**Pattern**:
```
Active Data (Standard Objects) → Archive Process → Big Objects / External Storage
   ↓                                                    ↑
Performance-critical                              Historical queries
```

**Best Practices**:
- Archive data older than 2 years (adjust based on need)
- Use Big Objects for Salesforce-native archival
- Use External Objects for external storage (S3, etc.)
- Maintain data lineage and audit trail

#### Data Skew
**Problem**: Records unevenly distributed causing lock contention
**Solution**: Minimize sharing rules, use skinny tables, defer sharing calculations

**Symptoms**:
- Lock timeout errors
- Slow DML operations on specific records
- Unable to delete parent records

**Solutions**:
```
✓ Use "Private" OWD instead of Public Read/Write
✓ Minimize number of sharing rules
✓ Use granular sharing instead of group-based
✓ Consider separate objects for high-volume child records
✓ Use deferred sharing calculations for batch operations
```

### 2. Integration Patterns

Reference: **Integration Patterns and Practices** (architect.salesforce.com)

#### Request-Reply (Synchronous)
**Use Case**: Real-time data retrieval or updates
**Example**: Get customer details from external system during order creation

**Implementation**:
```apex
// Apex callout to external API
@future(callout=true)
public static void getCustomerDetails(Id accountId) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:External_API/customers/' + accountId);
    req.setMethod('GET');

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
        // Process response
    }
}
```

**Best Practices**:
- Use Named Credentials for authentication
- Implement timeout handling (max 120 seconds)
- Use @future or Queueable for async callouts from triggers
- Implement circuit breaker pattern for failing endpoints

#### Fire-and-Forget (Asynchronous)
**Use Case**: Send data to external system without waiting for response
**Example**: Send order confirmation to external fulfillment system

**Implementation**:
```apex
// Platform Event publishing
Fulfillment_Event__e event = new Fulfillment_Event__e(
    Order_Id__c = orderId,
    Status__c = 'New'
);
EventBus.publish(event);
```

**Best Practices**:
- Use Platform Events for decoupled architecture
- Implement idempotency (handle duplicate messages)
- Use retry logic for failed deliveries
- Monitor event bus usage and delivery status

#### Batch Data Synchronization
**Use Case**: Nightly sync of large data volumes
**Example**: Sync product catalog from external ERP

**Implementation**:
```apex
// Batch Apex for bulk data sync
public class ProductSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, External_Id__c FROM Product2]);
    }

    public void execute(Database.BatchableContext bc, List<Product2> scope) {
        // Make callout to get updated product data
        // Update products in batch
    }

    public void finish(Database.BatchableContext bc) {
        // Send completion notification
    }
}
```

**Best Practices**:
- Schedule during off-peak hours
- Use Bulk API 2.0 for large volumes (millions of records)
- Implement error handling and retry logic
- Use External IDs for upsert operations
- Monitor batch job status and failures

#### Remote Call-In
**Use Case**: External systems invoke Salesforce APIs
**Example**: Partner portal creates leads in Salesforce

**Implementation**:
```apex
@RestResource(urlMapping='/leads/*')
global class LeadAPI {
    @HttpPost
    global static String createLead(String firstName, String lastName, String email) {
        Lead newLead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Company = 'Unknown'
        );
        insert newLead;
        return newLead.Id;
    }
}
```

**Best Practices**:
- Use OAuth 2.0 for authentication
- Implement rate limiting (monitor API usage)
- Validate all input data (prevent injection attacks)
- Use composite API for related records
- Version your APIs (/services/apexrest/v1/leads)
- Return proper HTTP status codes

#### UI Update (Real-Time)
**Use Case**: Update UI based on external system changes
**Example**: Display real-time inventory status from warehouse system

**Implementation**:
```javascript
// Lightning Web Component subscribing to Platform Event
import { LightningElement } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class InventoryMonitor extends LightningElement {
    channelName = '/event/Inventory_Update__e';
    subscription = {};

    connectedCallback() {
        this.handleSubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            this.handleInventoryUpdate(response.data.payload);
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }
}
```

**Best Practices**:
- Use Platform Events or Streaming API for real-time updates
- Implement exponential backoff for reconnection
- Handle network interruptions gracefully
- Use Change Data Capture for record changes
- Consider message retention (24 hours for Platform Events)

### 3. Scalability Patterns

#### Tiered Data Storage
**Problem**: Active and historical data mixed, impacting performance
**Solution**: Store active data in standard objects, historical in Big Objects

**Pattern**:
```
Hot Data (0-6 months)    → Standard Objects (fast access)
Warm Data (6-24 months)  → Standard Objects (indexed)
Cold Data (24+ months)   → Big Objects (queryable archive)
Frozen Data (5+ years)   → External Storage (compliance archive)
```

#### Asynchronous Processing
**Problem**: Long-running operations block user interface
**Solution**: Process in background using async Apex

**Decision Matrix**:
```
| Pattern      | Records  | Chaining | Callouts | Use Case              |
|--------------|----------|----------|----------|-----------------------|
| @future      | <200     | No       | Yes      | Simple async callout  |
| Queueable    | <50,000  | Yes      | Yes      | Complex async logic   |
| Batch Apex   | Millions | Via finish() | Yes  | Bulk data processing  |
| Platform Events | N/A   | N/A      | N/A      | Decoupled messaging   |
```

#### Query Optimization
**Problem**: Slow SOQL queries impacting performance
**Solution**: Use selective queries with indexed fields

**Indexed Fields** (automatic):
- Id
- Name
- RecordTypeId
- CreatedDate
- LastModifiedDate
- SystemModstamp
- OwnerId (some objects)
- Master-Detail fields
- External ID fields (custom)

**Optimization Techniques**:
```apex
// ❌ Non-selective query (table scan)
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE Description LIKE '%technology%'
];

// ✅ Selective query (index used)
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE RecordTypeId = :techRecordTypeId
    AND CreatedDate = LAST_N_DAYS:30
    LIMIT 200
];
```

**Best Practices**:
- Always filter on indexed fields in WHERE clause
- Use LIMIT to restrict result size
- Avoid leading wildcards in LIKE queries
- Create custom indexes on frequently queried fields
- Use query plan tool to verify index usage

### 4. Security Patterns

#### Layered Security
**Pattern**: Defense in depth with multiple security layers

**Layers**:
```
1. Network Security: IP restrictions, certificates
2. Authentication: MFA, SSO, session management
3. Authorization: Profiles, permission sets
4. Object Security: CRUD permissions
5. Field Security: FLS restrictions
6. Record Security: Sharing rules, manual sharing
7. Data Encryption: Shield Platform Encryption
8. Application Security: Input validation, output encoding
```

#### Principle of Least Privilege
**Pattern**: Grant minimum permissions required for job function

**Implementation**:
```
1. Start with most restrictive profile
2. Add permission sets for additional access
3. Use permission set groups for role-based access
4. Review and audit permissions quarterly
5. Remove permissions when role changes
```

#### Data Classification
**Pattern**: Classify data by sensitivity and apply appropriate controls

**Classification Levels**:
```
Public: Freely shareable (product catalog)
  → No encryption, standard security

Internal: Company-only (employee directory)
  → Standard security, access control

Confidential: Restricted access (financial data)
  → FLS, sharing rules, audit trail

Highly Confidential: Heavily restricted (SSN, health records)
  → Shield Encryption, strict access, audit trail
```

## Domain-Specific Architecture

### Sales Cloud Architecture

#### Opportunity Management
**Best Practices**:
- Use standard Opportunity object (don't create custom)
- Leverage stage-based automation (Flows)
- Implement opportunity splitting for team selling
- Use Products and Price Books for quoting
- Enable Collaborative Forecasts

**Anti-Patterns**:
```
❌ Custom opportunity object (lose standard features)
❌ Too many opportunity stages (keep 5-7 stages)
❌ Complex opportunity approval (use Path for guidance)
```

#### Lead-to-Cash Process
**Architecture**:
```
Lead → Qualification → Opportunity → Quote → Order → Fulfillment → Invoice
  ↓         ↓              ↓           ↓        ↓         ↓          ↓
Marketing  Sales       Sales      CPQ     Order Mgmt  External  Billing
                                          Management     ERP      System
```

**Integration Points**:
- CPQ: Quote generation and pricing
- Order Management: Order processing
- ERP: Fulfillment and invoicing
- Data Cloud: Customer 360 view

### Service Cloud Architecture

#### Case Management
**Best Practices**:
- Use standard Case object with record types
- Implement omni-channel routing
- Use Lightning Service Console for agents
- Enable Knowledge base for self-service
- Implement SLA tracking with milestones

**Scalability Considerations**:
```
✓ Archive closed cases older than 2 years
✓ Use Big Objects for case history
✓ Implement case deflection with chatbots
✓ Use External Services for complex logic
✓ Enable caching for Knowledge articles
```

#### Multi-Channel Support
**Channels**:
```
Email → Email-to-Case → Case Creation
Phone → CTI Integration → Screen Pop
Chat → Embedded Chat → Real-time Support
Social → Social Studio → Social Case Creation
SMS → Marketing Cloud → SMS Case
Self-Service → Experience Cloud → Case Portal
```

### Experience Cloud Architecture

#### B2B Commerce
**Architecture Layers**:
```
Presentation Layer: Lightning Web Components
Business Logic Layer: Apex Classes, Flows
Data Layer: Standard/Custom Objects
Integration Layer: External ERP, Payment Gateway
```

**Best Practices**:
- Use Experience Builder for site creation
- Implement separate profiles for external users
- Use External Sharing for secure data access
- Enable guest user security best practices
- Implement CDN for static resources

#### B2C Commerce
**Considerations**:
- High volume of users (millions)
- Public access to product catalog
- Secure checkout process
- Integration with payment gateways
- Real-time inventory updates

**Scalability**:
```
✓ Use Platform Cache for product catalog
✓ Implement CDN for images/static content
✓ Use External Objects for inventory data
✓ Implement rate limiting for APIs
✓ Use Heroku for compute-intensive operations
```

## Architectural Decision Framework

### Making Architectural Decisions

When designing a solution, evaluate against the Well-Architected Framework:

#### Decision Matrix
```
Question 1: Is it TRUSTED?
  → Is data secure and encrypted?
  → Is access properly controlled?
  → Will it perform at scale?
  → Is it reliable and available?

Question 2: Is it EASY?
  → Is the UI intuitive for users?
  → Is the code maintainable for developers?
  → Can admins configure without code?
  → Is it well-documented?

Question 3: Is it ADAPTABLE?
  → Can it handle future growth?
  → Can it be extended without breaking?
  → Is it flexible for changing requirements?
  → Is it modular and composable?
```

#### Trade-Off Analysis

When trade-offs are necessary, document the decision:

**Example**: Custom Object vs External Object

| Criteria | Custom Object | External Object |
|----------|---------------|-----------------|
| Performance | ✅ Excellent | ⚠️ Network latency |
| Storage Cost | ❌ Counts against limits | ✅ No Salesforce storage |
| Relationships | ✅ Full support | ⚠️ Limited support |
| Security | ✅ Full Salesforce security | ⚠️ External system security |
| Query Limits | ⚠️ SOQL limits apply | ⚠️ Callout limits apply |

**Decision**: Use Custom Object for frequently accessed data (<100K records), External Object for large external datasets (millions of records).

### Architecture Review Checklist

Before finalizing architecture, verify:

#### Functional Requirements
- [ ] All business requirements addressed
- [ ] Edge cases and exceptions handled
- [ ] Integration points identified and feasible
- [ ] Data model supports all use cases
- [ ] Automation covers all scenarios

#### Non-Functional Requirements
- [ ] Performance targets defined and achievable
- [ ] Security requirements met
- [ ] Scalability validated (data volume, users)
- [ ] Compliance requirements addressed
- [ ] Availability/disaster recovery planned

#### Well-Architected Pillars
- [ ] **TRUSTED**: Security, privacy, performance validated
- [ ] **EASY**: User experience, developer experience optimized
- [ ] **ADAPTABLE**: Flexibility, scalability, modularity confirmed

#### Technical Design
- [ ] Standard Salesforce features used where possible
- [ ] Design patterns appropriately applied
- [ ] Governor limits considered
- [ ] Test strategy defined (unit, integration, UAT)
- [ ] Deployment strategy planned
- [ ] Monitoring and observability defined

## Performance Optimization

### Query Performance

#### Use Skinny Tables
**When**: Objects with many fields, querying subset frequently
**How**: Contact Salesforce to create skinny table

**Benefits**:
- Faster queries (fewer joins)
- Reduced query time by 50-80%
- Automatic synchronization

#### Platform Cache
**Use Cases**:
- Frequently accessed reference data
- Expensive calculations
- Session state management

**Implementation**:
```apex
// Store in Platform Cache
Cache.Org.put('PriceBookData', priceBookData, 3600); // Cache for 1 hour

// Retrieve from Platform Cache
List<PricebookEntry> priceBookData = (List<PricebookEntry>) Cache.Org.get('PriceBookData');

if (priceBookData == null) {
    // Cache miss - query database
    priceBookData = [SELECT Id, UnitPrice FROM PricebookEntry];
    Cache.Org.put('PriceBookData', priceBookData, 3600);
}
```

#### Use Formula Fields Judiciously
**Impact**:
- Formula fields calculated at runtime (not stored)
- Can slow down queries and list views
- Count toward field limit

**Alternatives**:
- Use Flows for field updates (stored value)
- Use Apex triggers for complex calculations
- Use roll-up summary fields where applicable

### Integration Performance

#### Bulk API 2.0
**Use When**: Loading >5,000 records

**Benefits**:
- Ingest up to 150 million records/day
- CSV-based for easy mapping
- Parallel processing for speed
- Query and result set tracking

**Example**:
```bash
# Create job
curl https://instance.salesforce.com/services/data/v60.0/jobs/ingest \
  -H "Authorization: Bearer token" \
  -H "Content-Type: application/json" \
  -d '{"object":"Account","operation":"insert"}'

# Upload CSV
curl https://instance.salesforce.com/services/data/v60.0/jobs/ingest/{jobId}/batches \
  -H "Authorization: Bearer token" \
  -H "Content-Type: text/csv" \
  --data-binary @accounts.csv

# Close job (start processing)
curl -X PATCH https://instance.salesforce.com/services/data/v60.0/jobs/ingest/{jobId} \
  -H "Authorization: Bearer token" \
  -H "Content-Type: application/json" \
  -d '{"state":"UploadComplete"}'
```

#### Composite APIs
**Use When**: Creating multiple related records

**Benefits**:
- Single API call for multiple operations
- Reduced API usage (counts as 1 call)
- All-or-none or partial success

**Example**:
```json
POST /services/data/v60.0/composite/tree/Account
{
  "records": [{
    "attributes": {"type": "Account", "referenceId": "ref1"},
    "Name": "Account 1",
    "Contacts": {
      "records": [{
        "attributes": {"type": "Contact", "referenceId": "ref2"},
        "FirstName": "John",
        "LastName": "Doe"
      }]
    }
  }]
}
```

## Monitoring and Observability

### Key Metrics to Monitor

#### Performance Metrics
```
✓ Average page load time (<2 seconds target)
✓ Apex CPU time (% of 10 second limit)
✓ SOQL query count per transaction
✓ API usage (% of daily limit)
✓ Batch job execution time
✓ Integration latency (response times)
```

#### Health Metrics
```
✓ Data storage usage (% of limit)
✓ File storage usage (% of limit)
✓ Automation executions (flows, processes)
✓ Error rates (API, Apex, integrations)
✓ User adoption metrics (logins, feature usage)
```

### Monitoring Tools

**Salesforce Native**:
- Event Monitoring (tracks API, reports, logins)
- Debug Logs (detailed execution logs)
- Setup Audit Trail (configuration changes)
- Field History Tracking (data changes)
- Email Log Files (email deliverability)

**AppExchange Solutions**:
- OwnBackup (data backup and recovery)
- Salesforce Optimizer (org health check)
- Elements.cloud (metadata management)

## Resources

### Official Salesforce Architect Resources
- **Main Site**: https://architect.salesforce.com/
- **Well-Architected Framework**: https://architect.salesforce.com/design/well-architected/overview
- **Design Patterns**: https://architect.salesforce.com/design/decision-guides/
- **Reference Architectures**: https://architect.salesforce.com/diagrams/
- **Best Practices**: https://architect.salesforce.com/articles/

### Certifications
- **Technical Architect**: Summit-level certification
- **Application Architect**: Design scalable applications
- **System Architect**: Design scalable technical solutions
- **Data Architecture**: Design data models and migrations
- **Integration Architecture**: Design integration solutions
- **Identity & Access**: Design secure identity solutions

### Learning Paths (Trailhead)
- Architect Journey (complete learning path)
- Enterprise Architecture (design patterns)
- Integration Architecture (patterns and practices)
- Data Architecture (modeling and migration)

## When This Rule Applies

This architecture principles rule is **ALWAYS ACTIVE** for:
- All solution design decisions
- All data model design
- All integration architecture
- All performance optimization
- All security architecture
- All scalability planning
- All code reviews from architectural perspective

**Remember**: Good architecture balances **TRUSTED**, **EASY**, and **ADAPTABLE**. Every decision should consider all three pillars.

**Design Principle**: *"Start with standards, customize when necessary, architect for change."*
