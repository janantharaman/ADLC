---
name: Security Baseline
layer: 1
type: universal-foundation
composable: true
requires: []
alwaysApply: true
tags: [security, crud, fls, sharing, input-validation]
---

# Security Baseline (Layer 1 - Universal Foundation)

Security is NON-NEGOTIABLE in Salesforce development. This rule defines the baseline security practices that ALL employees must apply.

## Core Security Principle

**Default to Secure**: Unless there's an explicit, security-reviewed reason to bypass security controls, ALWAYS respect user permissions and enforce data protection.

---

## CRUD and FLS (Field-Level Security) Enforcement

### What is CRUD?

**CRUD** = Create, Read, Update, Delete permissions at the **object level**

- Configured in **Profiles** and **Permission Sets**
- Example: "Can users create Accounts? Can they delete Opportunities?"

### What is FLS?

**FLS** = Field-Level Security permissions at the **field level**

- Configured in **Profiles** and **Permission Sets**
- Example: "Can users see the `Discount_Amount__c` field? Can they edit `Status__c`?"

### Why Enforce CRUD/FLS?

**Without CRUD/FLS enforcement**, Apex code runs in **system mode** (bypasses user permissions). This means:
- ❌ Users can query/modify data they shouldn't have access to
- ❌ Sensitive fields (SSN, salary, credit cards) could be exposed
- ❌ Users could delete records they don't own
- ❌ **Security violation** and potential compliance breach (GDPR, HIPAA, etc.)

---

## Apex: `with sharing` vs `without sharing`

### Sharing Rules

**Sharing Rules** control **record-level access** (which records can a user see/edit?).

Salesforce has a complex sharing model:
- **Organization-Wide Defaults (OWD)**: Baseline access (Private, Public Read Only, Public Read/Write)
- **Role Hierarchy**: Users higher in the hierarchy can access records owned by users below them
- **Sharing Rules**: Extend access based on criteria or ownership
- **Manual Sharing**: Share specific records with specific users/groups

**`with sharing`** = Respect sharing rules (user sees only records they have access to)
**`without sharing`** = Ignore sharing rules (user sees ALL records, like an admin)

### When to Use Each

```apex
// ✅ GOOD: Default to "with sharing"
public with sharing class AccountService {
    public static List<Account> getAccounts() {
        // User sees only Accounts they have access to
        return [SELECT Id, Name FROM Account];
    }
}

// ⚠️ USE SPARINGLY: "without sharing" (document WHY!)
/**
 * @description Runs in elevated mode to perform nightly data cleanup.
 * This job needs access to ALL records regardless of user permissions.
 * Security reviewed: 2025-01-15 by Jane Doe
 */
public without sharing class DataCleanupBatch implements Database.Batchable<SObject> {
    // Elevated permissions justified for admin job
}

// ❌ BAD: No sharing declaration (inherits from caller - unpredictable!)
public class AccountService {
    // Sharing behavior depends on caller's context - AVOID!
}
```

**Default**: Use **`with sharing`** unless there's a documented, security-reviewed reason to use `without sharing`.

---

## User Mode Database Operations (Preferred for Compliance - Spring '23+)

**Introduced**: Spring '23 (API 57.0+)
**Purpose**: Enforce CRUD/FLS AND capture user context in audit logs (GDPR, HIPAA, SOC 2 compliance)

USER_MODE provides three approaches for permission enforcement with user context tracking.

### 1. SOQL with USER_MODE

```apex
// ✅ PREFERRED for compliance: USER_MODE enforces CRUD + FLS and logs user context
List<Account> accounts = [
    SELECT Id, Name, Industry, AnnualRevenue
    FROM Account
    WHERE Industry = :industry
    WITH USER_MODE
    LIMIT 200
];
```

**Behavior**:
- Enforces object-level read permission (CRUD)
- Enforces field-level read permission (FLS)
- Captures user context in logs (compliance)
- Query fails if user lacks access to ANY field

### 2. DML with USER_MODE

```apex
// ✅ PREFERRED for compliance: USER_MODE in DML operations
Database.insert(newAccounts, AccessLevel.USER_MODE);
Database.update(accounts, AccessLevel.USER_MODE);
Database.delete(oldAccounts, AccessLevel.USER_MODE);

// Inline syntax (same behavior)
insert as user newAccounts;
update as user accounts;
delete as user oldAccounts;
```

**Behavior**:
- Enforces CRUD permission (create/update/delete)
- Enforces FLS permission for all fields
- Captures user context in DML logs
- Operation fails if user lacks permission

### Decision Matrix: USER_MODE vs SECURITY_ENFORCED vs stripInaccessible()

| Feature | WITH USER_MODE | WITH SECURITY_ENFORCED | Security.stripInaccessible() |
|---------|----------------|------------------------|------------------------------|
| **API Version** | 57.0+ (Spring '23) | 40.0+ | 40.0+ |
| **Operations** | SOQL, DML | SOQL only | SOQL, DML |
| **Enforcement** | CRUD + FLS | FLS only | CRUD + FLS |
| **User Context Logging** | ✅ Yes (compliance) | ❌ No | ❌ No |
| **Behavior on Violation** | Fails entirely | Fails entirely | Strips inaccessible fields |
| **Use Case** | Compliance auditing | FLS enforcement only | Dynamic field removal |

**When to use which**:
```apex
// ✅ USER_MODE: Compliance auditing (GDPR, HIPAA), user context in logs, strict enforcement
List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE];

// ✅ SECURITY_ENFORCED: FLS enforcement only, read operations
List<Account> accounts = [SELECT Id, Name FROM Account WITH SECURITY_ENFORCED];

// ✅ stripInaccessible(): Dynamic field removal, partial success allowed
List<Account> accounts = [SELECT Id, Name, Industry FROM Account];
SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, accounts);
return decision.getRecords(); // Industry removed if inaccessible
```

---

## Apex: Enforce CRUD and FLS with `Security.stripInaccessible()`

### The Problem

```apex
// ❌ BAD: No CRUD/FLS enforcement
public with sharing class AccountService {
    public static List<Account> getAccounts() {
        // Even with "with sharing", this query returns ALL fields
        // User might not have FLS permission to see some fields!
        return [SELECT Id, Name, Industry, AnnualRevenue, SSN__c FROM Account];
    }

    public static void updateAccounts(List<Account> accounts) {
        // User might not have permission to UPDATE Accounts!
        // User might not have permission to edit certain fields!
        update accounts;
    }
}
```

### The Solution: `Security.stripInaccessible()`

**Introduced**: API version 40.0+
**Purpose**: Automatically enforce CRUD and FLS by stripping inaccessible fields

```apex
// ✅ GOOD: Enforces CRUD/FLS on read
public with sharing class AccountService {
    public static List<Account> getAccounts() {
        List<Account> accounts = [SELECT Id, Name, Industry, AnnualRevenue, SSN__c FROM Account LIMIT 100];

        // Strip fields user doesn't have READ access to
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            accounts
        );

        // Returns records with only accessible fields
        return decision.getRecords();
    }
}

// ✅ GOOD: Enforces CRUD/FLS on write
public with sharing class AccountService {
    public static void updateAccounts(List<Account> accounts) {
        // Check if user can UPDATE Accounts at all (CRUD)
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('User does not have permission to update Accounts');
        }

        // Strip fields user can't edit (FLS)
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accounts
        );

        update decision.getRecords();
    }
}

// ✅ GOOD: Enforces CRUD/FLS on insert
public with sharing class AccountService {
    public static void createAccounts(List<Account> accounts) {
        // Check if user can CREATE Accounts (CRUD)
        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new SecurityException('User does not have permission to create Accounts');
        }

        // Strip fields user can't populate on insert (FLS)
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            accounts
        );

        insert decision.getRecords();
    }
}
```

### Access Types

- `AccessType.READABLE` - Enforce read permissions (use before SOQL results)
- `AccessType.CREATABLE` - Enforce create permissions (use before `insert`)
- `AccessType.UPDATABLE` - Enforce update permissions (use before `update`)
- `AccessType.UPSERTABLE` - Enforce upsert permissions (use before `upsert`)

### Manual CRUD Checks (Alternative)

If you need more control, check CRUD manually using Schema methods:

```apex
// ✅ GOOD: Manual CRUD checks
public with sharing class AccountService {
    public static List<Account> getAccounts() {
        // Check if user can READ Accounts
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new SecurityException('User does not have permission to read Accounts');
        }

        return [SELECT Id, Name FROM Account LIMIT 100];
    }

    public static void updateAccounts(List<Account> accounts) {
        // Check if user can UPDATE Accounts
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('User does not have permission to update Accounts');
        }

        update accounts;
    }

    public static void deleteAccounts(List<Account> accounts) {
        // Check if user can DELETE Accounts
        if (!Schema.sObjectType.Account.isDeletable()) {
            throw new SecurityException('User does not have permission to delete Accounts');
        }

        delete accounts;
    }
}
```

**Schema Methods**:
- `Schema.sObjectType.Account.isAccessible()` - Can user READ?
- `Schema.sObjectType.Account.isCreateable()` - Can user CREATE?
- `Schema.sObjectType.Account.isUpdateable()` - Can user UPDATE?
- `Schema.sObjectType.Account.isDeletable()` - Can user DELETE?

### Manual FLS Checks (Alternative)

Check FLS manually using `DescribeFieldResult`:

```apex
// ✅ GOOD: Manual FLS checks
public with sharing class AccountService {
    public static void updateAccountIndustry(Id accountId, String industry) {
        // Check if user can edit the Industry field
        if (!Schema.sObjectType.Account.fields.Industry.isUpdateable()) {
            throw new SecurityException('User does not have permission to edit Industry field');
        }

        Account acc = new Account(Id = accountId, Industry = industry);
        update acc;
    }
}
```

---

## LWC: User Mode Wire Adapters (Automatic FLS Enforcement)

### The Good News

**Lightning Web Components** automatically enforce FLS when using standard wire adapters.

```javascript
// ✅ GOOD: Wire adapters respect FLS automatically
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Account.Name',
    'Account.Industry',
    'Account.AnnualRevenue',
    'Account.SSN__c'  // Sensitive field
];

export default class AccountDetails extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    // Data is automatically filtered by FLS
    // If user can't see SSN__c, it won't be returned
}
```

**Standard Wire Adapters** (FLS-enforced):
- `getRecord` (from `lightning/uiRecordApi`)
- `getRecords`
- `getRecordUi`
- `updateRecord`
- `createRecord`
- `deleteRecord`

### The Caveat: Apex Callouts

If you use **Apex methods** in LWC, you must enforce CRUD/FLS **in the Apex method itself**.

```apex
// ✅ GOOD: LWC calls Apex, Apex enforces CRUD/FLS
public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        // Enforce FLS before returning to LWC
        List<Account> accounts = [SELECT Id, Name, Industry FROM Account LIMIT 100];
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            accounts
        );
        return decision.getRecords();
    }
}
```

---

## Input Validation

**Principle**: NEVER trust user input. Always validate and sanitize.

### 1. Validate Required Fields

```apex
// ✅ GOOD: Validate required inputs
public static void createOrder(String accountId, Decimal amount, String status) {
    // Validate required fields
    if (String.isBlank(accountId)) {
        throw new IllegalArgumentException('Account ID is required');
    }
    if (amount == null || amount <= 0) {
        throw new IllegalArgumentException('Amount must be a positive number');
    }
    if (String.isBlank(status)) {
        throw new IllegalArgumentException('Status is required');
    }

    // Proceed with logic
    Order__c order = new Order__c(
        Account__c = accountId,
        Amount__c = amount,
        Status__c = status
    );
    insert order;
}

// ❌ BAD: No validation
public static void createOrder(String accountId, Decimal amount, String status) {
    insert new Order__c(Account__c = accountId, Amount__c = amount, Status__c = status);
    // What if accountId is null? What if amount is negative?
}
```

### 2. Validate Data Types

```apex
// ✅ GOOD: Validate ID type
public static Account getAccountById(String accountId) {
    if (String.isBlank(accountId)) {
        throw new IllegalArgumentException('Account ID is required');
    }

    // Validate that the ID is a valid 15 or 18-character Salesforce ID
    try {
        Id validId = Id.valueOf(accountId);

        // Validate that it's an Account ID
        if (validId.getSObjectType() != Schema.Account.SObjectType) {
            throw new IllegalArgumentException('Invalid Account ID: ' + accountId);
        }
    } catch (StringException e) {
        throw new IllegalArgumentException('Invalid Account ID format: ' + accountId);
    }

    return [SELECT Id, Name FROM Account WHERE Id = :accountId];
}

// ❌ BAD: No validation
public static Account getAccountById(String accountId) {
    return [SELECT Id, Name FROM Account WHERE Id = :accountId];
    // What if accountId is a Contact ID? System.QueryException!
}
```

### 3. Prevent SOQL Injection

**SOQL Injection** = Attacker manipulates user input to alter SOQL query behavior

```apex
// ❌ VERY BAD: SOQL Injection Vulnerability!
public static List<Account> searchAccounts(String searchTerm) {
    // If searchTerm = "test' OR Name != 'test", query becomes:
    // SELECT Id, Name FROM Account WHERE Name LIKE '%test' OR Name != 'test%'
    // This returns ALL accounts, not just matching ones!
    String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'%' + searchTerm + '%\'';
    return Database.query(query);
}

// ✅ GOOD: Use bind variables (prevents SOQL injection)
public static List<Account> searchAccounts(String searchTerm) {
    // Escape single quotes to prevent injection
    String safeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';

    // Use bind variable (Salesforce automatically sanitizes)
    return [SELECT Id, Name FROM Account WHERE Name LIKE :safeTerm];
}

// ✅ ALSO GOOD: Use static SOQL with bind variable
public static List<Account> searchAccountsByIndustry(String industry) {
    // Bind variable :industry is automatically sanitized
    return [SELECT Id, Name FROM Account WHERE Industry = :industry];
}
```

**Key Defenses**:
- ✅ Use **bind variables** (`:variable`)
- ✅ Use `String.escapeSingleQuotes()` for user input in SOQL
- ❌ NEVER concatenate user input directly into SOQL strings

### 4. Validate Business Logic

```apex
// ✅ GOOD: Validate business rules
public static void applyDiscount(Order__c order, Decimal discountPercentage) {
    // Validate range
    if (discountPercentage < 0 || discountPercentage > 100) {
        throw new IllegalArgumentException('Discount percentage must be between 0 and 100');
    }

    // Validate business rule: only apply discount to approved orders
    if (order.Status__c != 'Approved') {
        throw new BusinessException('Discounts can only be applied to approved orders');
    }

    // Apply discount
    order.Discount_Percentage__c = discountPercentage;
    order.Discounted_Amount__c = order.Amount__c * (1 - discountPercentage / 100);
    update order;
}
```

### 5. Sanitize HTML and JavaScript (LWC)

```javascript
// ✅ GOOD: Use {value} binding (auto-escapes HTML)
<template>
    <p>{accountName}</p>  <!-- Automatically escapes HTML entities -->
</template>

// ❌ BAD: Use lwc:inner-html (XSS vulnerability!)
<template>
    <div lwc:inner-html={accountName}></div>  <!-- Renders raw HTML - XSS risk! -->
</template>

// If you MUST use lwc:inner-html, sanitize first:
import DOMPurify from 'dompurify';

get sanitizedAccountName() {
    return DOMPurify.sanitize(this.accountName);
}
```

---

## Sharing and Record Access

### Understand Sharing Models

**Object-Level Sharing** (Organization-Wide Defaults):
- **Private**: Only owner and roles above can access
- **Public Read Only**: All users can view, only owner can edit
- **Public Read/Write**: All users can view and edit
- **Controlled by Parent**: Master-Detail relationship inherits parent's sharing

**Record-Level Sharing**:
- **Role Hierarchy**: Users higher in hierarchy see records owned by users below
- **Sharing Rules**: Extend access based on criteria (e.g., "Share Accounts in California with West Coast team")
- **Manual Sharing**: Explicitly grant access to specific users/groups
- **Apex Managed Sharing**: Programmatically create sharing records

### Manual Sharing (When Needed)

```apex
// ✅ GOOD: Programmatically grant access
public with sharing class AccountSharingService {
    public static void shareAccountWithUser(Id accountId, Id userId, String accessLevel) {
        // Validate inputs
        if (accountId == null || userId == null) {
            throw new IllegalArgumentException('Account ID and User ID are required');
        }

        // Create manual share
        AccountShare share = new AccountShare(
            AccountId = accountId,
            UserOrGroupId = userId,
            AccountAccessLevel = accessLevel,  // 'Read' or 'Edit'
            OpportunityAccessLevel = 'None',   // No access to child Opportunities
            CaseAccessLevel = 'None',          // No access to child Cases
            RowCause = Schema.AccountShare.RowCause.Manual  // Manual sharing reason
        );

        try {
            insert share;
        } catch (DmlException e) {
            // Handle sharing already exists, no permission, etc.
            System.debug('Failed to share Account: ' + e.getMessage());
        }
    }

    public static void removeManualSharing(Id accountId, Id userId) {
        List<AccountShare> shares = [
            SELECT Id
            FROM AccountShare
            WHERE AccountId = :accountId
              AND UserOrGroupId = :userId
              AND RowCause = :Schema.AccountShare.RowCause.Manual
        ];

        if (!shares.isEmpty()) {
            delete shares;
        }
    }
}
```

**Sharing Objects**:
- `AccountShare` (for Account)
- `OpportunityShare` (for Opportunity)
- `ContactShare` (for Contact)
- `[ObjectName]__Share` (for custom objects with Private OWD)

---

## Sensitive Data Handling

### 1. Field-Level Encryption

Use **Platform Encryption** (formerly Shield Platform Encryption) for highly sensitive data:

- Encrypts data at rest
- Searchable encrypted fields (deterministic encryption)
- Requires Shield add-on license

### 2. Mask Sensitive Fields

```apex
// ✅ GOOD: Mask sensitive data in logs or UI
public static String maskCreditCard(String cardNumber) {
    if (String.isBlank(cardNumber) || cardNumber.length() < 4) {
        return '****';
    }

    // Show only last 4 digits
    String lastFour = cardNumber.substring(cardNumber.length() - 4);
    return '****' + lastFour;
}

// Usage
System.debug('Processing payment for card: ' + maskCreditCard(cardNumber));
// Output: "Processing payment for card: ****1234"
```

### 3. Avoid Logging Sensitive Data

```apex
// ❌ BAD: Logging sensitive data
System.debug('SSN: ' + account.SSN__c);
System.debug('Credit Card: ' + order.Credit_Card__c);

// ✅ GOOD: Don't log sensitive fields
System.debug('Processing account: ' + account.Id);
System.debug('Processing order: ' + order.Id);
```

---

## Quick Security Checklist

Before deploying ANY code, verify:

- ✅ **Apex classes use `with sharing`** (unless documented exception)
- ✅ **CRUD checked** (`isAccessible()`, `isCreateable()`, `isUpdateable()`, `isDeletable()`)
- ✅ **FLS enforced** (`Security.stripInaccessible()` or manual checks)
- ✅ **User input validated** (required fields, data types, ranges)
- ✅ **SOQL injection prevented** (bind variables, `String.escapeSingleQuotes()`)
- ✅ **Sensitive data protected** (encryption, masking, no logging)
- ✅ **Sharing rules respected** (manual sharing only when needed, documented)

---

## Common Security Anti-Patterns (Avoid These!)

### 1. No Sharing Declaration

```apex
// ❌ BAD: Sharing behavior depends on caller
public class AccountService {
    // Inherits sharing from caller - unpredictable!
}

// ✅ GOOD: Explicit sharing declaration
public with sharing class AccountService {
    // Always respects sharing rules
}
```

### 2. Ignoring CRUD/FLS

```apex
// ❌ BAD: No CRUD/FLS checks
public with sharing class AccountService {
    public static void updateAccounts(List<Account> accounts) {
        update accounts;  // User might not have permission!
    }
}

// ✅ GOOD: Enforce CRUD/FLS
public with sharing class AccountService {
    public static void updateAccounts(List<Account> accounts) {
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('No permission to update Accounts');
        }
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, accounts);
        update decision.getRecords();
    }
}
```

### 3. SOQL Injection

```apex
// ❌ BAD: Dynamic SOQL with user input
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';
List<Account> accounts = Database.query(query);

// ✅ GOOD: Bind variable
String safeName = String.escapeSingleQuotes(userInput);
List<Account> accounts = [SELECT Id FROM Account WHERE Name = :safeName];
```

---

## Default to Secure

**When in doubt, choose the more secure option:**
- ✅ Use `with sharing` by default
- ✅ Always enforce CRUD/FLS unless there's a specific reason not to
- ✅ Always validate user input
- ✅ Always use bind variables in SOQL
- ✅ Never log sensitive data

**Security is everyone's responsibility.**

**Applies to**: All Salesforce developers (Apex, LWC, Integrations, Data, Admin)
