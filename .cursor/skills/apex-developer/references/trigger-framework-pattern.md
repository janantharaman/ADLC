# Trigger Framework Pattern

## Overview
A robust trigger framework that provides:
- One trigger per object
- Clear separation of concerns
- Recursion prevention
- Execution context awareness
- Easy testing

## Complete Implementation

### 1. Base Trigger Handler Class

```apex
/**
 * Base class for all trigger handlers
 * Provides context awareness and recursion prevention
 */
public virtual class TriggerHandler {

    // Static map to prevent recursion
    private static Map<String, Boolean> bypassedHandlers = new Map<String, Boolean>();

    // Context variables
    @TestVisible protected List<SObject> triggerNew;
    @TestVisible protected List<SObject> triggerOld;
    @TestVisible protected Map<Id, SObject> triggerNewMap;
    @TestVisible protected Map<Id, SObject> triggerOldMap;
    @TestVisible protected Integer triggerSize;

    // Constructor - sets context
    public TriggerHandler() {
        this.triggerNew = Trigger.new;
        this.triggerOld = Trigger.old;
        this.triggerNewMap = Trigger.newMap;
        this.triggerOldMap = Trigger.oldMap;
        this.triggerSize = Trigger.size;
    }

    /**
     * Main entry point - call from trigger
     */
    public void run() {
        if (isBypassed()) {
            return;
        }

        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert();
            } else if (Trigger.isUpdate) {
                beforeUpdate();
            } else if (Trigger.isDelete) {
                beforeDelete();
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert();
            } else if (Trigger.isUpdate) {
                afterUpdate();
            } else if (Trigger.isDelete) {
                afterDelete();
            } else if (Trigger.isUndelete) {
                afterUndelete();
            }
        }
    }

    // Virtual methods - override in child classes
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

    /**
     * Bypass mechanism for testing or recursive prevention
     */
    public static void bypass(String handlerName) {
        bypassedHandlers.put(handlerName, true);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    private Boolean isBypassed() {
        return bypassedHandlers.containsKey(getHandlerName());
    }

    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }
}
```

### 2. Object-Specific Trigger

```apex
/**
 * Single trigger for Account object
 * Delegates all logic to handler
 */
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new AccountTriggerHandler().run();
}
```

### 3. Object-Specific Handler

```apex
/**
 * Handler for Account trigger
 * Delegates to service layer for business logic
 */
public class AccountTriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        AccountService.setDefaultValues((List<Account>) triggerNew);
        AccountService.validateAccounts((List<Account>) triggerNew);
    }

    protected override void beforeUpdate() {
        AccountService.validateAccounts((List<Account>) triggerNew);
        AccountService.preventInvalidStatusChanges(
            (List<Account>) triggerNew,
            (Map<Id, Account>) triggerOldMap
        );
    }

    protected override void afterInsert() {
        AccountService.createDefaultContacts((List<Account>) triggerNew);
        AccountService.publishAccountCreatedEvents((List<Account>) triggerNew);
    }

    protected override void afterUpdate() {
        AccountService.updateRelatedOpportunities(
            (List<Account>) triggerNew,
            (Map<Id, Account>) triggerOldMap
        );
    }

    protected override void beforeDelete() {
        AccountService.preventDeletionWithActiveOpportunities((List<Account>) triggerOld);
    }
}
```

### 4. Service Layer (Business Logic)

```apex
/**
 * Service class for Account business logic
 * All business rules live here, not in triggers
 */
public class AccountService {

    /**
     * Set default values for new accounts
     */
    public static void setDefaultValues(List<Account> accounts) {
        for (Account acc : accounts) {
            if (String.isBlank(acc.Rating)) {
                acc.Rating = 'Warm';
            }
            if (acc.AnnualRevenue == null) {
                acc.AnnualRevenue = 0;
            }
        }
    }

    /**
     * Validate account data
     */
    public static void validateAccounts(List<Account> accounts) {
        for (Account acc : accounts) {
            if (String.isBlank(acc.Name)) {
                acc.addError('Account Name is required');
            }
            if (acc.Name?.length() > 255) {
                acc.addError('Account Name cannot exceed 255 characters');
            }
        }
    }

    /**
     * Update related opportunities when account changes
     * BULKIFIED - single SOQL query, single DML
     */
    public static void updateRelatedOpportunities(
        List<Account> newAccounts,
        Map<Id, Account> oldAccountMap
    ) {
        // Collect accounts where rating changed
        Set<Id> changedAccountIds = new Set<Id>();
        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountMap.get(acc.Id);
            if (acc.Rating != oldAcc.Rating) {
                changedAccountIds.add(acc.Id);
            }
        }

        if (changedAccountIds.isEmpty()) {
            return;
        }

        // Single SOQL - get all related opportunities
        List<Opportunity> oppsToUpdate = [
            SELECT Id, AccountId, StageName
            FROM Opportunity
            WHERE AccountId IN :changedAccountIds
            AND IsClosed = false
        ];

        // Build map for quick lookup
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Rating FROM Account WHERE Id IN :changedAccountIds]
        );

        // Update opportunities
        for (Opportunity opp : oppsToUpdate) {
            Account acc = accountMap.get(opp.AccountId);
            if (acc.Rating == 'Hot') {
                opp.StageName = 'Prospecting';
            }
        }

        // Single DML
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }

    /**
     * Prevent deletion of accounts with active opportunities
     */
    public static void preventDeletionWithActiveOpportunities(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Single SOQL with aggregate
        Map<Id, Integer> oppCountByAccount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT AccountId, COUNT(Id) oppCount
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = false
            GROUP BY AccountId
        ]) {
            oppCountByAccount.put(
                (Id) ar.get('AccountId'),
                (Integer) ar.get('oppCount')
            );
        }

        // Add errors to records
        for (Account acc : accounts) {
            Integer oppCount = oppCountByAccount.get(acc.Id);
            if (oppCount != null && oppCount > 0) {
                acc.addError(
                    'Cannot delete Account with ' + oppCount + ' active Opportunities'
                );
            }
        }
    }
}
```

## Testing the Framework

```apex
@isTest
private class AccountTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Rating = 'Warm'
            ));
        }
        insert accounts;
    }

    @isTest
    static void testBulkInsert() {
        // When
        Test.startTest();
        List<Account> newAccounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            newAccounts.add(new Account(Name = 'Bulk Account ' + i));
        }
        insert newAccounts;
        Test.stopTest();

        // Then
        List<Account> inserted = [SELECT Id, Rating FROM Account WHERE Name LIKE 'Bulk Account%'];
        System.assertEquals(200, inserted.size());
        for (Account acc : inserted) {
            System.assertEquals('Warm', acc.Rating, 'Default rating should be set');
        }
    }

    @isTest
    static void testBypassMechanism() {
        // Given
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        // When - bypass the handler
        TriggerHandler.bypass('AccountTriggerHandler');
        acc.Name = 'Updated Name';
        update acc;
        TriggerHandler.clearAllBypasses();

        // Then - handler was bypassed, no validation ran
        Account updated = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', updated.Name);
    }

    @isTest
    static void testPreventDeletion() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        // When/Then
        Test.startTest();
        try {
            delete acc;
            System.assert(false, 'Should have thrown exception');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('active Opportunities'));
        }
        Test.stopTest();
    }
}
```

## Best Practices

1. **One trigger per object** - Salesforce doesn't guarantee trigger execution order
2. **Thin triggers** - All logic in handler/service classes
3. **Service layer** - Business logic separate from trigger context
4. **Bulkification** - Always process collections, never single records
5. **Recursion prevention** - Use bypass mechanism or static flags
6. **Testing** - Test with 200+ records, test bypass mechanism
7. **Security** - Check CRUD/FLS in service methods

## Common Pitfalls

❌ **Don't do DML in loops**
```apex
for (Account acc : accounts) {
    update acc; // WRONG - DML in loop
}
```

❌ **Don't query in loops**
```apex
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id]; // WRONG
}
```

❌ **Don't put business logic in triggers**
```apex
trigger AccountTrigger on Account (before insert) {
    for (Account acc : Trigger.new) {
        // Complex business logic here - WRONG
    }
}
```

✅ **Always bulkify**
```apex
Set<Id> accountIds = new Set<Id>();
for (Account acc : accounts) {
    accountIds.add(acc.Id);
}
Map<Id, List<Contact>> contactsByAccount = getContactsByAccount(accountIds);
```
