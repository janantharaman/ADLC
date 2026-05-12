# USER_MODE Security Patterns (Spring '23+)

Expert reference for modern user mode database operations in Salesforce Apex.

## Overview

**Introduced**: Spring '23 (API 57.0+)
**Purpose**: Enforce user permissions (CRUD/FLS) AND capture user context in audit logs for compliance
**Use Cases**: GDPR, HIPAA, SOC 2 compliance requiring explicit user context in audit trails

USER_MODE provides three approaches for permission enforcement with user context tracking.

---

## Three USER_MODE Approaches

### 1. SOQL: `WITH USER_MODE`

**Use Case**: Query operations requiring user context in query logs

```apex
/**
 * @description Query with USER_MODE - enforces FLS and captures user context
 * @since API 57.0 (Spring '23)
 */
public with sharing class AccountSelector {
    public static List<Account> getAccountsByIndustry(String industry) {
        // USER_MODE enforces:
        // 1. Object-level read permission (CRUD)
        // 2. Field-level read permission (FLS)
        // 3. User context captured in logs (compliance)
        return [
            SELECT Id, Name, Industry, AnnualRevenue
            FROM Account
            WHERE Industry = :industry
            WITH USER_MODE
            LIMIT 200
        ];
    }
}
```

**Behavior**:
- Throws `System.QueryException` if user lacks object/field access
- Query fails entirely if ANY selected field is inaccessible
- User context logged for compliance auditing

**Testing**:
```apex
@isTest
static void testUserModeQuery() {
    // Create user with limited FLS
    User limitedUser = TestDataFactory.createUserWithProfile('Standard User');

    System.runAs(limitedUser) {
        Test.startTest();
        try {
            List<Account> accounts = AccountSelector.getAccountsByIndustry('Technology');
            System.assertEquals(0, accounts.size(), 'Should return accessible records only');
        } catch (System.QueryException e) {
            // Expected if user lacks object access
            System.assert(e.getMessage().contains('USER_MODE'), 'Should be USER_MODE exception');
        }
        Test.stopTest();
    }
}
```

---

### 2. DML: `AccessLevel.USER_MODE`

**Use Case**: DML operations requiring user context in DML audit logs

```apex
/**
 * @description Insert with USER_MODE - enforces CRUD/FLS and logs user context
 * @since API 57.0 (Spring '23)
 */
public with sharing class AccountService {
    public static void createAccounts(List<Account> accounts) {
        // USER_MODE enforces:
        // 1. Create permission (CRUD)
        // 2. Field-level create permission (FLS)
        // 3. User context in DML logs
        Database.SaveResult[] results = Database.insert(
            accounts,
            AccessLevel.USER_MODE
        );

        // Handle partial success
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug('DML Error: ' + error.getMessage());
                    // Log to custom Error__c object or Platform Event
                }
            }
        }
    }

    public static void updateAccounts(List<Account> accounts) {
        Database.SaveResult[] results = Database.update(
            accounts,
            AccessLevel.USER_MODE
        );
        handleResults(results);
    }

    public static void deleteAccounts(List<Account> accounts) {
        Database.DeleteResult[] results = Database.delete(
            accounts,
            AccessLevel.USER_MODE
        );
        handleDeleteResults(results);
    }

    private static void handleResults(Database.SaveResult[] results) {
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                // Handle permission errors gracefully
                System.debug('DML failed: ' + result.getErrors()[0].getMessage());
            }
        }
    }

    private static void handleDeleteResults(Database.DeleteResult[] results) {
        for (Database.DeleteResult result : results) {
            if (!result.isSuccess()) {
                System.debug('Delete failed: ' + result.getErrors()[0].getMessage());
            }
        }
    }
}
```

**Testing**:
```apex
@isTest
static void testUserModeDML() {
    User limitedUser = TestDataFactory.createUserWithProfile('Standard User');

    List<Account> accounts = TestDataFactory.createAccounts(200);

    System.runAs(limitedUser) {
        Test.startTest();
        Database.SaveResult[] results = Database.insert(accounts, AccessLevel.USER_MODE);
        Test.stopTest();

        // Check results
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }

        System.debug('Successful inserts: ' + successCount);
    }
}
```

---

### 3. Inline: `insert as user` / `update as user`

**Use Case**: Simple DML with user context, cleaner syntax

```apex
/**
 * @description Inline USER_MODE syntax for simple DML
 * @since API 57.0 (Spring '23)
 */
public with sharing class OrderService {
    public static void createOrders(List<Order__c> orders) {
        // Inline syntax - same behavior as AccessLevel.USER_MODE
        // Throws DmlException if user lacks permission
        insert as user orders;
    }

    public static void updateOrders(List<Order__c> orders) {
        update as user orders;
    }

    public static void deleteOrders(List<Order__c> orders) {
        delete as user orders;
    }

    public static void upsertOrders(List<Order__c> orders) {
        upsert as user orders;
    }
}
```

**Behavior**:
- Throws `DmlException` if user lacks CRUD permission
- Throws `DmlException` if user lacks FLS permission for ANY field
- Operation fails entirely (all-or-none by default)

**Testing**:
```apex
@isTest
static void testInlineUserMode() {
    User limitedUser = TestDataFactory.createUserWithProfile('Standard User');

    List<Order__c> orders = new List<Order__c>{
        new Order__c(Name = 'Order 1', Amount__c = 1000),
        new Order__c(Name = 'Order 2', Amount__c = 2000)
    };

    System.runAs(limitedUser) {
        Test.startTest();
        try {
            insert as user orders;
            System.assertEquals(2, [SELECT COUNT() FROM Order__c], 'Orders created');
        } catch (DmlException e) {
            // Expected if user lacks create permission
            System.assert(e.getMessage().contains('permission'), 'Should be permission error');
        }
        Test.stopTest();
    }
}
```

---

## Comparison: USER_MODE vs SECURITY_ENFORCED vs stripInaccessible()

| Feature | WITH USER_MODE | WITH SECURITY_ENFORCED | Security.stripInaccessible() |
|---------|----------------|------------------------|------------------------------|
| **API Version** | 57.0+ (Spring '23) | 40.0+ | 40.0+ |
| **Operations** | SOQL only | SOQL only | SOQL, DML |
| **Enforcement** | CRUD + FLS | FLS only | CRUD + FLS |
| **Behavior on Violation** | Query fails entirely | Query fails entirely | Strips inaccessible fields |
| **User Context Logging** | ✅ Yes (compliance) | ❌ No | ❌ No |
| **Partial Success** | ❌ No | ❌ No | ✅ Yes |
| **Use Case** | Compliance auditing | Read-only FLS enforcement | Dynamic field removal |

### Decision Matrix

```apex
// Use WITH USER_MODE when:
// - Need user context in query logs (GDPR, HIPAA compliance)
// - Want query to fail if user lacks access (strict enforcement)
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WITH USER_MODE
];

// Use WITH SECURITY_ENFORCED when:
// - Only need FLS enforcement (not CRUD)
// - Don't need user context in logs
// - Legacy code requiring SOQL security without USER_MODE
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WITH SECURITY_ENFORCED
];

// Use Security.stripInaccessible() when:
// - Need dynamic field removal (partial success)
// - User might lack access to some fields but operation should continue
// - Working with dynamic field sets
List<Account> accounts = [SELECT Id, Name, Industry, SSN__c FROM Account];
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.READABLE,
    accounts
);
return decision.getRecords(); // SSN__c removed if inaccessible
```

---

## Migration Guide

### From Security.stripInaccessible() → USER_MODE

**When to migrate**:
- New code requiring compliance auditing: Use USER_MODE
- Existing code with partial success requirement: Keep stripInaccessible()
- Existing code with strict enforcement: Migrate to USER_MODE

**Migration Steps**:

1. **Identify security enforcement pattern**:
```apex
// Before (stripInaccessible)
List<Account> accounts = [SELECT Id, Name, Industry FROM Account];
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.READABLE,
    accounts
);
return decision.getRecords();
```

2. **Migrate to USER_MODE** (strict enforcement):
```apex
// After (USER_MODE - strict)
return [
    SELECT Id, Name, Industry
    FROM Account
    WITH USER_MODE
];
// Query fails if user lacks access to ANY field
```

3. **OR keep stripInaccessible()** (partial success):
```apex
// Keep stripInaccessible if partial success needed
// Example: User might lack access to Industry but should still get Id, Name
List<Account> accounts = [SELECT Id, Name, Industry FROM Account];
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.READABLE,
    accounts
);
return decision.getRecords(); // Returns records with accessible fields only
```

### From WITH SECURITY_ENFORCED → WITH USER_MODE

**When to migrate**:
- Need user context logging for compliance
- Already using WITH SECURITY_ENFORCED and need CRUD enforcement too

**Migration Steps**:

1. **Replace SECURITY_ENFORCED with USER_MODE**:
```apex
// Before
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WITH SECURITY_ENFORCED
];

// After
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WITH USER_MODE
];
```

2. **Test with limited users**:
```apex
@isTest
static void testMigration() {
    User limitedUser = TestDataFactory.createUserWithProfile('Standard User');

    System.runAs(limitedUser) {
        Test.startTest();
        List<Account> accounts = AccountSelector.getAccounts();
        Test.stopTest();

        // Verify behavior with USER_MODE
        System.assertNotEquals(null, accounts);
    }
}
```

---

## Compliance Use Cases

### 1. GDPR - Data Access Logging

**Requirement**: Log which user accessed what data

```apex
/**
 * @description GDPR-compliant data access with user context logging
 */
public with sharing class GDPRAccountService {
    public static List<Account> getPersonalData(Set<Id> accountIds) {
        // WITH USER_MODE captures:
        // - User who accessed data
        // - Timestamp of access
        // - Fields accessed
        // Required for GDPR Article 30 (record of processing activities)
        return [
            SELECT Id, Name, PersonEmail, Phone, BillingAddress
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ];
    }
}
```

### 2. HIPAA - Protected Health Information (PHI)

**Requirement**: Enforce field-level security for PHI fields, log access

```apex
/**
 * @description HIPAA-compliant PHI access with audit trail
 */
public with sharing class PatientService {
    public static void updatePatientRecord(Id patientId, String diagnosis) {
        // AccessLevel.USER_MODE ensures:
        // 1. Only authorized users can update PHI
        // 2. User context logged for HIPAA audit
        Patient__c patient = new Patient__c(
            Id = patientId,
            Diagnosis__c = diagnosis // PHI field
        );

        Database.SaveResult result = Database.update(
            new List<Patient__c>{ patient },
            AccessLevel.USER_MODE
        )[0];

        if (!result.isSuccess()) {
            // Log unauthorized access attempt
            logSecurityEvent('Unauthorized PHI update attempt', patientId);
        }
    }

    private static void logSecurityEvent(String message, Id recordId) {
        // Log to Platform Event for real-time monitoring
        Security_Event__e event = new Security_Event__e(
            Message__c = message,
            Record_Id__c = recordId,
            User_Id__c = UserInfo.getUserId()
        );
        EventBus.publish(event);
    }
}
```

### 3. SOC 2 - Change Tracking

**Requirement**: Audit trail for all data modifications

```apex
/**
 * @description SOC 2-compliant change tracking with user context
 */
public with sharing class AuditableService {
    public static void updateWithAudit(List<Account> accounts) {
        // USER_MODE captures who made the change
        Database.SaveResult[] results = Database.update(
            accounts,
            AccessLevel.USER_MODE
        );

        // Create audit records
        List<Audit_Log__c> auditLogs = new List<Audit_Log__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                auditLogs.add(new Audit_Log__c(
                    Record_Id__c = results[i].getId(),
                    Action__c = 'Update',
                    User__c = UserInfo.getUserId(),
                    Timestamp__c = System.now()
                ));
            }
        }

        if (!auditLogs.isEmpty()) {
            insert auditLogs;
        }
    }
}
```

---

## Governor Limits Impact

USER_MODE has the same governor limit impact as standard operations:

| Operation | Limit | Notes |
|-----------|-------|-------|
| **SOQL with USER_MODE** | 150 (sync) / 200 (async) | Same as standard SOQL |
| **DML with USER_MODE** | 150 statements / 10,000 rows | Same as standard DML |
| **CPU Time** | 10s (sync) / 60s (async) | Additional CPU for permission checks (~5-10ms) |

**Performance Considerations**:
- USER_MODE adds ~5-10ms overhead per operation for permission checks
- Use bulkification to minimize impact (process 200 records vs 1 record)
- No additional SOQL queries consumed for permission checks

---

## Error Handling

### SOQL Errors

```apex
public static List<Account> safeUserModeQuery(String industry) {
    try {
        return [
            SELECT Id, Name, Industry
            FROM Account
            WHERE Industry = :industry
            WITH USER_MODE
        ];
    } catch (System.QueryException e) {
        // Handle permission errors
        if (e.getMessage().contains('USER_MODE')) {
            System.debug('User lacks permission to query Accounts');
            return new List<Account>();
        }
        throw e;
    }
}
```

### DML Errors

```apex
public static void safeUserModeDML(List<Account> accounts) {
    try {
        insert as user accounts;
    } catch (DmlException e) {
        // Handle permission errors
        for (Integer i = 0; i < e.getNumDml(); i++) {
            System.debug('DML Error on record ' + i + ': ' + e.getDmlMessage(i));
        }
    }
}
```

---

## Best Practices

### 1. Use with `with sharing`

```apex
// ✅ GOOD: USER_MODE + with sharing
public with sharing class AccountService {
    public static List<Account> getAccounts() {
        return [SELECT Id FROM Account WITH USER_MODE];
    }
}

// ❌ BAD: USER_MODE without sharing declaration
public class AccountService {
    // Sharing behavior unclear - avoid
}
```

### 2. Prefer USER_MODE for New Code

```apex
// ✅ GOOD: Modern approach (Spring '23+)
return [SELECT Id, Name FROM Account WITH USER_MODE];

// ⚠️ LEGACY: Still valid but less compliance-friendly
List<Account> accounts = [SELECT Id, Name FROM Account];
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.READABLE,
    accounts
);
return decision.getRecords();
```

### 3. Document Compliance Requirements

```apex
/**
 * @description Retrieves patient records with HIPAA-compliant access logging
 * @security USER_MODE enforces PHI field access permissions
 * @compliance HIPAA 164.308(a)(1)(ii)(D) - Access logging required
 */
public static List<Patient__c> getPatients(Set<Id> patientIds) {
    return [
        SELECT Id, Name, SSN__c, Diagnosis__c
        FROM Patient__c
        WHERE Id IN :patientIds
        WITH USER_MODE
    ];
}
```

### 4. Test with Multiple User Profiles

```apex
@isTest
static void testUserModeWithDifferentProfiles() {
    // Test with admin (full access)
    User adminUser = TestDataFactory.createUserWithProfile('System Administrator');

    System.runAs(adminUser) {
        List<Account> accounts = AccountService.getAccounts();
        System.assertNotEquals(0, accounts.size(), 'Admin should see all accounts');
    }

    // Test with standard user (limited access)
    User standardUser = TestDataFactory.createUserWithProfile('Standard User');

    System.runAs(standardUser) {
        List<Account> accounts = AccountService.getAccounts();
        // Might return 0 if user lacks access
    }
}
```

---

## Quick Reference

### SOQL Pattern
```apex
List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE];
```

### DML Pattern (Database methods)
```apex
Database.insert(accounts, AccessLevel.USER_MODE);
Database.update(accounts, AccessLevel.USER_MODE);
Database.delete(accounts, AccessLevel.USER_MODE);
Database.upsert(accounts, AccessLevel.USER_MODE);
```

### DML Pattern (Inline)
```apex
insert as user accounts;
update as user accounts;
delete as user accounts;
upsert as user accounts;
```

### Error Handling
```apex
try {
    insert as user accounts;
} catch (DmlException e) {
    // Handle permission errors
}
```

---

## When NOT to Use USER_MODE

**Don't use USER_MODE when**:
- System automation requires elevated permissions (document why)
- Batch jobs processing data independent of user context
- Integration user with full permissions (API user)

```apex
/**
 * @description Nightly cleanup job - requires system-level access
 * @security without sharing + standard DML (no USER_MODE)
 * @reason Cleanup job needs access to ALL records regardless of user permissions
 * @securityReview Approved 2026-03-06 by Security Team
 */
public without sharing class NightlyCleanupBatch implements Database.Batchable<SObject> {
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Standard DML (no USER_MODE) - system context
        delete scope;
    }
}
```

---

## Resources

- [WITH USER_MODE Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_SOQL_with_user_mode.htm)
- [AccessLevel Enum](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_enum_System_AccessLevel.htm)
- [Security Class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_Security.htm)
- Governor Limits: `references/governor-limits-reference.md`
