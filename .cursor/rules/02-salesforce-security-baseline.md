---
alwaysApply: true
---

# Salesforce Security Baseline

Security is paramount in Salesforce development. These standards ensure data protection, compliance, and secure code practices across ALL development work.

## Security Model Overview

Salesforce uses a **layered security model**:
1. **Org-Level**: Login controls, IP restrictions, session settings
2. **Object-Level (CRUD)**: Create, Read, Update, Delete permissions
3. **Field-Level (FLS)**: Field visibility and editability
4. **Record-Level (Sharing)**: Individual record access
5. **Feature-Level**: License and permission-based access

**Principle**: Security is restrictive by default, permissions are additive.

## Object-Level Security (CRUD)

### Definition
Controls whether users can **Create**, **Read**, **Update**, or **Delete** entire objects.

### Configuration
- **Profiles**: Baseline CRUD permissions for all users with that profile
- **Permission Sets**: Grant additional CRUD permissions (additive only)
- **Permission Set Groups**: Bundle multiple permission sets

### Best Practices
```
✓ Use Profiles for baseline access (least privilege)
✓ Use Permission Sets to grant additional access
✓ Custom objects default to hidden - explicitly grant access
✓ Never give "Modify All Data" unless absolutely necessary
✓ Separate read vs write permissions when possible
```

### Example Permissions
```
Profile: Sales User
  - Account: Read, Create, Edit
  - Opportunity: Read, Create, Edit, Delete
  - Contact: Read, Create, Edit
  - Invoice__c: Read only

Permission Set: Invoice Administrator
  - Invoice__c: Create, Edit, Delete (additive to Read)
```

## Field-Level Security (FLS)

### Definition
Controls whether users can **see** and **edit** individual fields on objects.

### Configuration
- Set per Profile and Permission Set
- Two levels: **Visible** and **Editable**
- Editable requires Visible

### Best Practices
```
✓ Sensitive fields should be hidden by default
✓ System fields (CreatedBy, LastModified) are read-only
✓ Custom fields default to visible - review and restrict
✓ Use FLS for PII/PHI data (SSN, credit cards, health data)
✓ Formula fields inherit FLS from referenced fields
```

### Examples
```
Sensitive Fields (Restrict FLS):
  - Social_Security_Number__c: Visible to HR only
  - Credit_Card_Number__c: Never store, or encrypt
  - Salary__c: Visible to managers and HR only
  - Personal_Health_Info__c: Visible to healthcare team only

General Fields:
  - Account_Name__c: Visible to all
  - Status__c: Visible to all, editable by administrators
```

## Record-Level Security (Sharing)

### Organization-Wide Defaults (OWD)
Baseline sharing settings for each object:
- **Private**: Only owner and roles above can access
- **Public Read Only**: Everyone can view, only owner can edit
- **Public Read/Write**: Everyone can view and edit
- **Controlled by Parent**: Child object inherits master's sharing (Master-Detail only)

### Best Practices for OWD
```
✓ Start with Private (most restrictive)
✓ Use Public Read Only for reference data
✓ Avoid Public Read/Write for sensitive objects
✓ Master-Detail children: Use "Controlled by Parent"
```

### Sharing Rules
Extend access beyond OWD:
- **Criteria-Based**: Share records matching criteria
- **Ownership-Based**: Share records owned by specific users/roles

```apex
// Example: Share all High Priority accounts with Sales Management
Criteria: Priority__c = 'High'
Share with: Sales Management Role
Access Level: Read/Write
```

### Manual Sharing
Users can manually share records they own via the Share button.

### Apex Managed Sharing
Programmatically grant access via `__Share` objects:

```apex
// Grant read access to Account
AccountShare accShare = new AccountShare();
accShare.AccountId = accountId;
accShare.UserOrGroupId = userId;
accShare.AccountAccessLevel = 'Read';
accShare.OpportunityAccessLevel = 'None';
accShare.RowCause = Schema.AccountShare.RowCause.Manual;
insert accShare;
```

## Apex Security

### Sharing Keywords (CRITICAL)

```apex
// Runs with sharing (enforces user's sharing rules) - DEFAULT FOR BEST PRACTICE
public with sharing class AccountService {
    public List<Account> getAccounts() {
        // Only returns accounts user has access to
        return [SELECT Id, Name FROM Account];
    }
}

// Runs without sharing (ignores sharing rules - SYSTEM CONTEXT)
public without sharing class SystemAccountService {
    public List<Account> getAllAccounts() {
        // Returns ALL accounts regardless of sharing
        return [SELECT Id, Name FROM Account];
    }
}

// Inherited sharing (inherits context from caller)
public inherited sharing class FlexibleAccountService {
    public List<Account> getAccounts() {
        // Respects caller's sharing context
        return [SELECT Id, Name FROM Account];
    }
}
```

**Default Behavior**:
- Classes without `with sharing` or `without sharing` run in **system context** (no sharing enforcement)
- **ALWAYS explicitly declare** `with sharing`, `without sharing`, or `inherited sharing`

### Best Practices for Sharing Keywords
```
✓ Use "with sharing" by default for user-facing operations
✓ Use "without sharing" only when system access is required (integrations, background jobs)
✓ Use "inherited sharing" for utility classes that should respect caller's context
✓ Document WHY "without sharing" is used (code comments)
✓ Never use "without sharing" to bypass security for user convenience
```

### CRUD and FLS Checks in Apex

#### Method 1: Schema Describe (Traditional)
```apex
// Check object-level CRUD
if (Schema.sObjectType.Account.isCreateable()) {
    insert newAccount;
}

if (Schema.sObjectType.Account.isUpdateable()) {
    update existingAccount;
}

if (Schema.sObjectType.Account.isDeletable()) {
    delete oldAccount;
}

// Check field-level security
if (Schema.sObjectType.Account.fields.Industry.isAccessible()) {
    String industry = acc.Industry; // Read
}

if (Schema.sObjectType.Account.fields.Industry.isUpdateable()) {
    acc.Industry = 'Technology'; // Write
}
```

#### Method 2: WITH SECURITY_ENFORCED (Preferred)
```apex
// Automatically enforces CRUD and FLS
List<Account> accounts = [
    SELECT Id, Name, Industry, AnnualRevenue
    FROM Account
    WHERE Industry = 'Technology'
    WITH SECURITY_ENFORCED
];
// Throws QueryException if user lacks FLS on any field
```

**Best Practice**: Use `WITH SECURITY_ENFORCED` in SOQL queries for automatic enforcement.

#### Method 3: Security.stripInaccessible()
```apex
// Automatically strips fields user cannot access
List<Account> accounts = [
    SELECT Id, Name, Industry, AnnualRevenue, SSN__c
    FROM Account
];

SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.READABLE,
    accounts
);

// Returns only fields user can read
List<Account> secureAccounts = decision.getRecords();
```

### DML Security
```apex
// Always check CRUD before DML
public class AccountService {

    public static void createAccounts(List<Account> accounts) {
        // Check create permission
        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Accounts');
        }

        // Perform DML
        insert accounts;
    }

    public static void updateAccounts(List<Account> accounts) {
        // Check update permission
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Accounts');
        }

        // Check field-level security for each field being updated
        if (!Schema.sObjectType.Account.fields.Industry.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Industry field');
        }

        update accounts;
    }
}
```

## SOQL Injection Prevention

### What is SOQL Injection?
Malicious user input manipulates SOQL queries to access unauthorized data.

### Vulnerable Code (NEVER DO THIS)
```apex
// ❌ DANGEROUS - User input directly in query
public List<Account> searchAccounts(String searchTerm) {
    String query = 'SELECT Id, Name FROM Account WHERE Name = \'' + searchTerm + '\'';
    return Database.query(query);
}

// User inputs: xyz' OR '1'='1
// Resulting query: SELECT Id, Name FROM Account WHERE Name = 'xyz' OR '1'='1'
// Returns ALL accounts!
```

### Safe Code (ALWAYS DO THIS)
```apex
// ✓ SAFE - Use bind variables
public List<Account> searchAccounts(String searchTerm) {
    return [SELECT Id, Name FROM Account WHERE Name = :searchTerm];
}

// ✓ SAFE - Sanitize input with String.escapeSingleQuotes()
public List<Account> searchAccounts(String searchTerm) {
    String sanitized = String.escapeSingleQuotes(searchTerm);
    String query = 'SELECT Id, Name FROM Account WHERE Name = \'' + sanitized + '\'';
    return Database.query(query);
}

// ✓ BEST - Use bind variables AND input validation
public List<Account> searchAccounts(String searchTerm) {
    // Validate input
    if (String.isBlank(searchTerm) || searchTerm.length() > 255) {
        throw new IllegalArgumentException('Invalid search term');
    }

    // Use bind variable
    return [SELECT Id, Name FROM Account WHERE Name = :searchTerm];
}
```

### Best Practices for SOQL Injection Prevention
```
✓ Always use bind variables (:variable) in SOQL
✓ Use String.escapeSingleQuotes() for dynamic SOQL
✓ Validate and sanitize ALL user input
✓ Whitelist acceptable characters (don't blacklist)
✓ Limit query scope with WHERE clauses
✓ Never concatenate user input directly into queries
```

## Cross-Site Scripting (XSS) Prevention

### What is XSS?
Malicious scripts injected into pages that execute in users' browsers.

### Vulnerable Code (Visualforce)
```html
<!-- ❌ DANGEROUS - Unescaped output -->
<apex:page controller="AccountController">
    <h1>{!accountName}</h1>
    <!-- If accountName contains <script>, it will execute -->
</apex:page>
```

### Safe Code (Visualforce)
```html
<!-- ✓ SAFE - Escaped output -->
<apex:page controller="AccountController">
    <h1><apex:outputText value="{!accountName}" escape="true"/></h1>
</apex:page>

<!-- ✓ SAFE - Use escape="true" by default -->
<apex:outputText value="{!HTMLENCODE(accountName)}"/>
<apex:outputText value="{!JSENCODE(accountName)}"/>
<apex:outputText value="{!URLENCODE(accountName)}"/>
```

### Safe Code (LWC)
```javascript
// ✓ SAFE - LWC automatically sanitizes output
<template>
    <h1>{accountName}</h1>
    <!-- Automatically escaped -->
</template>
```

### Best Practices for XSS Prevention
```
✓ Always escape user-generated content
✓ Use HTMLENCODE(), JSENCODE(), URLENCODE() in Visualforce
✓ LWC automatically escapes by default (use unsafeHTML carefully)
✓ Validate input on server-side (never trust client)
✓ Use Content Security Policy (CSP) headers
```

## External Integrations

### Named Credentials (Preferred)
Store authentication securely in Salesforce:
```apex
// ✓ SECURE - Use Named Credentials
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:MyNamedCredential/api/endpoint');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody(JSON.serialize(data));

Http http = new Http();
HttpResponse res = http.send(req);
```

### Best Practices for Integrations
```
✓ Use Named Credentials for external authentication
✓ Never hardcode credentials in code
✓ Store API keys in Custom Metadata or Protected Custom Settings
✓ Use HTTPS for all callouts (never HTTP)
✓ Validate SSL certificates
✓ Implement timeout limits (default 120 seconds)
✓ Log errors without exposing sensitive data
✓ Use OAuth2 for user-context integrations
```

### Secure Credential Storage
```apex
// ❌ NEVER DO THIS - Hardcoded credentials
String apiKey = 'abc123secretkey';

// ✓ GOOD - Store in Custom Metadata
Integration_Config__mdt config = [
    SELECT API_Key__c FROM Integration_Config__mdt WHERE DeveloperName = 'Production' LIMIT 1
];
String apiKey = config.API_Key__c;

// ✓ BEST - Use Named Credentials (no code access to credentials)
req.setEndpoint('callout:MyNamedCredential/api');
```

## Data Encryption

### Platform Encryption
Salesforce offers **Shield Platform Encryption** for at-rest data encryption:
- Encrypts data at rest in Salesforce databases
- FIPS 140-2 compliant
- Transparent to users and applications
- Fields, files, and attachments

### Field Encryption (Classic Encryption)
Built-in encryption for text fields:
```
// Encrypted Text Field (up to 175 characters)
// Masked from users without "View Encrypted Data" permission
// Use for: SSN, credit cards, sensitive IDs
```

### Best Practices for Encryption
```
✓ Use Shield Platform Encryption for regulated industries (HIPAA, PCI-DSS)
✓ Use Classic Encryption for individual sensitive fields
✓ Never log encrypted data in plain text
✓ Mask sensitive data in UI (show last 4 digits only)
✓ Use tokenization for credit card processing (never store full CC numbers)
```

## Session Security

### Login Settings
```
✓ Enforce password complexity requirements
✓ Enable two-factor authentication (MFA) for all users
✓ Set session timeout (2 hours default, adjust as needed)
✓ Restrict login IP ranges for sensitive orgs
✓ Lock accounts after failed login attempts
✓ Use login flows for conditional access
```

### Session Management in Code
```apex
// Get current user ID
Id currentUserId = UserInfo.getUserId();

// Get current user profile
Id profileId = UserInfo.getProfileId();

// Check if user has permission
Boolean canEdit = Schema.sObjectType.Account.isUpdateable();

// Never expose session ID in logs or error messages
```

## Security Code Review Checklist

Before deploying code, verify:

### Apex Security
- [ ] All classes use `with sharing`, `without sharing`, or `inherited sharing` explicitly
- [ ] CRUD checks before DML operations
- [ ] FLS checks for sensitive fields
- [ ] SOQL uses bind variables (no string concatenation)
- [ ] User input is validated and sanitized
- [ ] No hardcoded credentials or API keys
- [ ] Named Credentials used for external systems
- [ ] Error messages don't expose sensitive data

### SOQL Security
- [ ] All queries use `WITH SECURITY_ENFORCED` where applicable
- [ ] Dynamic SOQL uses `String.escapeSingleQuotes()`
- [ ] Queries include WHERE clauses (avoid `SELECT * FROM ...`)
- [ ] Limit query results (LIMIT clause)

### LWC/Visualforce Security
- [ ] Visualforce uses `escape="true"` for user input
- [ ] Visualforce uses HTMLENCODE/JSENCODE/URLENCODE
- [ ] LWC @api properties are validated server-side
- [ ] No sensitive data in JavaScript console.log

### Integration Security
- [ ] HTTPS used for all callouts
- [ ] Named Credentials used (not hardcoded credentials)
- [ ] SSL certificate validation enabled
- [ ] Timeout set for callouts
- [ ] Error handling doesn't expose sensitive data

## Security Resources

### Official Salesforce Security
- **Salesforce Security Guide**: https://help.salesforce.com/s/articleView?id=sf.security_overview.htm
- **Apex Security Best Practices**: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_security_best_practices.htm
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/

### Security Certifications
- **Salesforce Certified Platform Developer I/II**: Includes security topics
- **Salesforce Certified Sharing and Visibility Designer**: Deep dive into sharing
- **Salesforce Certified Security Architect**: Comprehensive security design

## When This Rule Applies

This security baseline rule is **ALWAYS ACTIVE** for:
- All Apex development (triggers, classes, web services)
- All Lightning Web Component development
- All Visualforce development
- All integration work (callouts, APIs)
- All data modeling (field encryption decisions)
- All user and permission management
- All code reviews and deployments

**Remember**: Security is not optional. It's a fundamental requirement for ALL Salesforce development.
