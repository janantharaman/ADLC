---
alwaysApply: true
---

# Salesforce Platform Foundation

This rule provides core Salesforce platform knowledge that applies to ALL development work. These fundamentals are always active.

## Platform Architecture

### Multi-Tenant Architecture
- Salesforce is a multi-tenant cloud platform where multiple customers (orgs) share the same infrastructure
- **Governor Limits** exist to ensure fair resource usage across all tenants
- All code must be designed for scalability and resource efficiency
- Never assume unlimited resources - always design for limits

### Org Types
- **Production Org**: Live customer data, requires 75% test coverage for deployment
- **Sandbox Org**: Copy of production for development/testing (Full, Partial, Developer, Developer Pro)
- **Scratch Org**: Temporary, source-driven org for development (7-30 days)
- **Trailhead Playground**: Free development org for learning

## Core Data Model

### Standard Objects
Salesforce provides pre-built standard objects:
- **Account**: Companies/organizations
- **Contact**: Individuals
- **Opportunity**: Sales deals
- **Lead**: Prospective customers
- **Case**: Customer service requests
- **Campaign**: Marketing campaigns
- **Task/Event**: Activities
- **User**: System users
- **Custom Objects**: Built by developers (API name ends with `__c`)

### Relationships
- **Lookup**: Loosely coupled relationship (can be null)
- **Master-Detail**: Tightly coupled relationship (child inherits security, cannot be null)
  - Master-Detail drives roll-up summary fields
  - Deleting master cascades to children
  - Child records inherit sharing from master
- **Many-to-Many**: Junction object with two master-detail relationships
- **External Lookup**: Relationship to external systems
- **Hierarchical**: Self-relationship (only on User object)

### Field Types
- **Text**: String, Email, Phone, URL, Text Area (Long/Rich)
- **Number**: Number, Currency, Percent
- **Date/Time**: Date, Date/Time
- **Picklist**: Single/Multi-select picklists
- **Checkbox**: Boolean
- **Formula**: Calculated fields (read-only)
- **Roll-Up Summary**: Aggregates on child records (Master-Detail only)
- **Auto-Number**: Auto-incrementing unique ID
- **Geolocation**: Latitude/Longitude

## Automation Hierarchy

### Declarative (Low-Code)
1. **Validation Rules**: Field-level validation (before save)
2. **Workflows**: Simple field updates, email alerts, tasks (LEGACY - use Flows)
3. **Process Builder**: Multi-step automation (LEGACY - use Flows)
4. **Flows**: Visual automation for complex logic (PREFERRED for declarative)
5. **Approval Processes**: Multi-step approval workflows

### Programmatic (Code)
6. **Apex Triggers**: Custom code on DML events (before/after insert/update/delete)
7. **Apex Classes**: Business logic, integrations, batch jobs
8. **Lightning Web Components (LWC)**: Modern UI components
9. **Aura Components**: Legacy UI components (prefer LWC)
10. **Visualforce**: Legacy page framework (prefer LWC)

## Order of Execution

Critical understanding for trigger and automation development:

1. **System Validation**: Required fields, field formats
2. **Before Triggers**: Run before record is saved to database
3. **Custom Validation Rules**: User-defined validation
4. **After Triggers**: Run after record is saved but before commit
5. **Assignment Rules**: Lead/Case assignment
6. **Auto-Response Rules**: Email auto-responses
7. **Workflow Rules**: Field updates, email alerts (immediate)
8. **Processes**: Process Builder (immediate actions)
9. **Flows**: Record-triggered flows
10. **Escalation Rules**: Case escalation
11. **Roll-Up Summary Fields**: Calculated
12. **Criteria-Based Sharing**: Applied
13. **Commit to Database**: Transaction committed
14. **Post-Commit Logic**: Email sends, async jobs queued

**Key Takeaway**: Before triggers can modify fields, after triggers cannot. Always consider order of execution when debugging automation.

## Security Model

### Org-Level Security
- **Login IP Ranges**: Restrict access by IP
- **Login Hours**: Restrict access by time
- **Session Settings**: Timeout, two-factor authentication

### Object-Level Security (CRUD)
- **Profiles**: Define baseline object permissions (Create, Read, Edit, Delete)
- **Permission Sets**: Grant additional permissions (additive only)
- **Permission Set Groups**: Bundle multiple permission sets

### Field-Level Security (FLS)
- **Field Permissions**: Per profile/permission set (Visible, Editable)
- Always check FLS in Apex: `Schema.sObjectType.Account.fields.Industry.isAccessible()`
- Use `WITH SECURITY_ENFORCED` in SOQL queries

### Record-Level Security (Sharing)
- **Organization-Wide Defaults (OWD)**: Baseline sharing (Private, Public Read Only, Public Read/Write)
- **Role Hierarchy**: Users higher in hierarchy can access records owned by subordinates
- **Sharing Rules**: Extend access based on criteria or ownership
- **Manual Sharing**: User-initiated sharing
- **Apex Sharing**: Programmatic sharing via `__Share` objects
- **Team Sharing**: Account/Opportunity teams

**Sharing Enforcement in Apex**:
```apex
// Runs in system context (ignores sharing) by default
public class AccountService {
    // ...
}

// Enforces sharing rules
public with sharing class AccountService {
    // ...
}

// Explicitly ignores sharing
public without sharing class AccountService {
    // ...
}
```

## Governor Limits (Critical)

### Per-Transaction Limits
- **150 SOQL queries** (sync), 200 (async)
- **150 DML statements** (sync/async)
- **10,000 DML rows total** (sync/async)
- **10 seconds CPU time** (sync), 60 seconds (async)
- **6 MB heap size** (sync), 12 MB (async)
- **100 callouts per transaction**
- **50 @future calls per transaction**
- **50 queueable jobs per transaction**

### Design Implications
- **Never put SOQL in loops** - collect IDs, query once
- **Never put DML in loops** - collect records, DML once
- **Bulkify everything** - code must handle 200+ records
- **Use async Apex** for long-running operations
- **Use Batch Apex** for >10,000 records
- **Use Platform Events** for decoupled systems

## Development Lifecycle

### Metadata API
- All configuration stored as metadata (XML files)
- Can be version-controlled (Git)
- Deployed between orgs via Change Sets, ANT, SFDX, or CI/CD

### Salesforce DX (SFDX)
- Modern development workflow (source-driven)
- **Scratch Orgs**: Temporary, disposable environments
- **Source Format**: Metadata in Git-friendly format
- **CLI**: `sf` command-line tool
- **Package Development**: Modular, reusable packages

### Source Control
- Use Git for version control
- Source format (not metadata format)
- `.forceignore` file excludes unwanted metadata
- Branch strategy: feature branches → dev → QA → prod

## API & Integration

### APIs Available
- **REST API**: Modern, JSON-based CRUD operations
- **SOAP API**: Enterprise WSDL, strongly-typed
- **Bulk API**: Load large data volumes (async)
- **Streaming API**: Real-time event notifications
- **Metadata API**: Deploy/retrieve configuration
- **Tooling API**: Development tools, IDE integration
- **UI API**: Build UI with Lightning Data Service

### API Limits
- **15,000 API calls per 24 hours** (Enterprise Edition per user)
- **100,000 API calls per 24 hours** (Unlimited Edition per user)
- Monitor via System Overview or API Usage notifications

### Integration Patterns
- **Request-Reply**: Synchronous API calls
- **Fire-and-Forget**: Async messaging (Platform Events)
- **Batch Data Sync**: Bulk API, scheduled jobs
- **Remote Call-In**: External systems call Salesforce
- **Remote Call-Out**: Salesforce calls external systems
- **UI Update**: External systems update Salesforce UI (Streaming API, Platform Events)

## Best Practices Summary

### Code Quality
- Write bulkified code (handle 200+ records)
- Use trigger handler frameworks
- Separate business logic from trigger context (service layer)
- Check CRUD/FLS permissions
- Write comprehensive tests (75%+ coverage)

### Performance
- Minimize SOQL queries (use relationship queries)
- Avoid SOQL/DML in loops
- Use selective queries (indexed fields)
- Use @future or Queueable for callouts
- Use Batch Apex for large data volumes

### Security
- Always use `with sharing` unless explicitly needed
- Check CRUD/FLS in Apex
- Use `WITH SECURITY_ENFORCED` in SOQL
- Sanitize user input to prevent SOQL injection
- Use Named Credentials for external auth

### Maintainability
- Follow naming conventions
- Comment complex logic
- Use constants for magic numbers
- Keep methods small and focused
- Use meaningful variable names

### Testing
- 75% code coverage minimum for production
- Test bulk scenarios (200+ records)
- Use test data factories
- Never use `@isTest(SeeAllData=true)`
- Test positive and negative scenarios
- Use `Test.startTest()` and `Test.stopTest()` for async

## Documentation Resources

### Official Salesforce Documentation
- **Developer Guide**: https://developer.salesforce.com/docs
- **Apex Reference**: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta
- **LWC Reference**: https://developer.salesforce.com/docs/component-library
- **Object Reference**: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta
- **API Reference**: https://developer.salesforce.com/docs/apis

### Trailhead (Free Learning)
- **Trailhead**: https://trailhead.salesforce.com
- Modules on Apex, LWC, Data Modeling, Security, Integration

### Community Resources
- **Salesforce Stack Exchange**: https://salesforce.stackexchange.com
- **Salesforce Developer Forums**: https://developer.salesforce.com/forums
- **GitHub**: Salesforce open-source projects

## When This Rule Applies

This foundation rule is **ALWAYS ACTIVE** for:
- All Apex development
- All LWC development
- All declarative automation (Flows, Process Builder)
- All data modeling decisions
- All integration work
- All security configurations
- All testing

**Remember**: These are platform fundamentals. More specific guidance comes from role-specific skills (`/apex-dev`, `/lwc-dev`, `/architect`).
