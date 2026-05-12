# Bulkification Examples

## Core Principle
**ALL Apex code must handle 200+ records efficiently.** Salesforce can trigger your code with up to 200 records at once (or more in batch contexts).

## Example 1: SOQL in Loops

### ❌ WRONG - SOQL in Loop
```apex
public class ContactUpdater {
    public static void updateContacts(List<Account> accounts) {
        for (Account acc : accounts) {
            // SOQL in loop - hits 150 query limit at 150 accounts
            List<Contact> contacts = [
                SELECT Id, Email
                FROM Contact
                WHERE AccountId = :acc.Id
            ];

            for (Contact con : contacts) {
                con.Email = acc.Website;
            }
            update contacts; // DML in loop too!
        }
    }
}
```
**Problems:**
- 200 accounts = 200 SOQL queries (limit: 150)
- 200 accounts = 200 DML operations (limit: 150)
- Fails with >150 accounts

### ✅ CORRECT - Single SOQL, Bulk DML
```apex
public class ContactUpdater {
    public static void updateContacts(List<Account> accounts) {
        // Collect all account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Single SOQL query
        List<Contact> allContacts = [
            SELECT Id, Email, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ];

        // Build map for quick lookup
        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);

        // Update all contacts
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact con : allContacts) {
            Account acc = accountMap.get(con.AccountId);
            if (acc != null && acc.Website != null) {
                con.Email = acc.Website;
                contactsToUpdate.add(con);
            }
        }

        // Single DML operation
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
```
**Benefits:**
- 1 SOQL query (vs 200)
- 1 DML operation (vs 200)
- Handles 200+ accounts efficiently

## Example 2: DML in Loops

### ❌ WRONG - DML in Loop
```apex
public class OpportunityCreator {
    public static void createOpportunities(List<Account> accounts) {
        for (Account acc : accounts) {
            Opportunity opp = new Opportunity(
                Name = acc.Name + ' Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            );
            insert opp; // DML in loop - fails at 150 accounts
        }
    }
}
```

### ✅ CORRECT - Bulk DML
```apex
public class OpportunityCreator {
    public static void createOpportunities(List<Account> accounts) {
        List<Opportunity> oppsToInsert = new List<Opportunity>();

        for (Account acc : accounts) {
            oppsToInsert.add(new Opportunity(
                Name = acc.Name + ' Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }

        // Single DML operation
        if (!oppsToInsert.isEmpty()) {
            insert oppsToInsert;
        }
    }
}
```

## Example 3: Nested Queries

### ❌ WRONG - Query in Loop
```apex
public class AccountProcessor {
    public static void processAccounts(List<Account> accounts) {
        for (Account acc : accounts) {
            // Query contacts
            List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];

            // Query opportunities - more SOQL!
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];

            // Process...
        }
    }
}
```

### ✅ CORRECT - Relationship Queries
```apex
public class AccountProcessor {
    public static void processAccounts(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        // Single query with relationships
        List<Account> accountsWithRelated = [
            SELECT Id, Name,
                (SELECT Id, FirstName, LastName FROM Contacts),
                (SELECT Id, Name, StageName FROM Opportunities)
            FROM Account
            WHERE Id IN :accountIds
        ];

        // Process all data
        for (Account acc : accountsWithRelated) {
            List<Contact> contacts = acc.Contacts;
            List<Opportunity> opps = acc.Opportunities;
            // Process...
        }
    }
}
```

## Example 4: Future Method Callouts

### ❌ WRONG - Future in Loop
```apex
public class ExternalSystemIntegration {
    public static void syncAccounts(List<Account> accounts) {
        for (Account acc : accounts) {
            syncToExternalSystem(acc.Id); // 100 limit on future calls
        }
    }

    @future(callout=true)
    public static void syncToExternalSystem(Id accountId) {
        // Make callout
    }
}
```
**Problem:** Hits 100 future method limit at 100 accounts

### ✅ CORRECT - Queueable with Chaining
```apex
public class ExternalSystemIntegration {
    public static void syncAccounts(List<Account> accounts) {
        System.enqueueJob(new AccountSyncQueueable(accounts));
    }
}

public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Account> accounts;
    private Integer startIndex;

    public AccountSyncQueueable(List<Account> accounts) {
        this(accounts, 0);
    }

    private AccountSyncQueueable(List<Account> accounts, Integer startIndex) {
        this.accounts = accounts;
        this.startIndex = startIndex;
    }

    public void execute(QueueableContext context) {
        // Process batch of 50
        Integer endIndex = Math.min(startIndex + 50, accounts.size());
        List<Account> batch = new List<Account>();
        for (Integer i = startIndex; i < endIndex; i++) {
            batch.add(accounts[i]);
        }

        // Make callouts for this batch
        syncBatch(batch);

        // Chain to next batch
        if (endIndex < accounts.size()) {
            System.enqueueJob(new AccountSyncQueueable(accounts, endIndex));
        }
    }

    private void syncBatch(List<Account> batch) {
        for (Account acc : batch) {
            // Make callout
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.example.com/sync');
            req.setMethod('POST');
            req.setBody(JSON.serialize(acc));
            HttpResponse res = http.send(req);
        }
    }
}
```

## Example 5: Large Data Volumes

### ❌ WRONG - Loading All Records
```apex
public class DataMigration {
    public static void migrateData() {
        // Trying to query 100,000+ records
        List<Account> allAccounts = [SELECT Id, Name FROM Account];

        for (Account acc : allAccounts) {
            // Process - HEAP SIZE LIMIT exceeded
        }
    }
}
```

### ✅ CORRECT - Batch Apex or Query for Loop
```apex
// Option 1: Query for Loop (simple cases)
public class DataMigration {
    public static void migrateData() {
        // Query for loop - processes in chunks
        for (Account acc : [SELECT Id, Name FROM Account]) {
            // Process one at a time
            // No heap size issues
        }
    }
}

// Option 2: Batch Apex (complex logic)
public class AccountMigrationBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Industry
            FROM Account
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Process up to 200 records at a time
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : scope) {
            if (acc.Industry == null) {
                acc.Industry = 'Other';
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Send completion email
    }
}

// Execute: Database.executeBatch(new AccountMigrationBatch(), 200);
```

## Example 6: Map-Based Lookups

### ❌ WRONG - List Searching in Loop
```apex
public class OrderProcessor {
    public static void processOrders(List<Order> orders, List<Product2> products) {
        for (Order ord : orders) {
            // Searching list inside loop - O(n²) complexity
            for (Product2 prod : products) {
                if (prod.Id == ord.ProductId__c) {
                    ord.ProductName__c = prod.Name;
                    break;
                }
            }
        }
        update orders;
    }
}
```
**Problem:** O(n²) complexity = slow for large datasets

### ✅ CORRECT - Map-Based Lookup
```apex
public class OrderProcessor {
    public static void processOrders(List<Order> orders, List<Product2> products) {
        // Build map once - O(n)
        Map<Id, Product2> productMap = new Map<Id, Product2>(products);

        // Single pass through orders - O(n)
        for (Order ord : orders) {
            Product2 prod = productMap.get(ord.ProductId__c);
            if (prod != null) {
                ord.ProductName__c = prod.Name;
            }
        }

        update orders;
    }
}
```
**Benefits:** O(n) complexity vs O(n²)

## Testing Bulkification

### Always Test with 200+ Records
```apex
@isTest
private class ContactUpdaterTest {

    @isTest
    static void testBulkUpdate() {
        // Given - create 200 accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Website = 'test' + i + '@example.com'
            ));
        }
        insert accounts;

        // Create 200 contacts (1 per account)
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id
            ));
        }
        insert contacts;

        // When - update all accounts
        Test.startTest();
        ContactUpdater.updateContacts(accounts);
        Test.stopTest();

        // Then - verify all contacts updated
        List<Contact> updated = [SELECT Id, Email FROM Contact];
        System.assertEquals(200, updated.size());

        // Verify governor limits not exceeded
        System.assert(Limits.getQueries() < 100, 'Too many SOQL queries');
        System.assert(Limits.getDMLStatements() < 10, 'Too many DML statements');
    }
}
```

## Quick Checklist

Before deploying Apex code, verify:
- [ ] No SOQL in loops
- [ ] No DML in loops
- [ ] No future/queueable calls in loops
- [ ] Using Maps for lookups (not nested loops)
- [ ] Tested with 200+ records
- [ ] Checked Limits class usage in tests
- [ ] Used Database methods with allOrNone=false for partial success scenarios
- [ ] Used Batch Apex for >10,000 records
- [ ] Used Query for Loop for large result sets

## Resources
- [Apex Design Patterns](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_design_patterns.htm)
- [Governor Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm)
- [Bulk Trigger Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_bulk_best_practices.htm)
