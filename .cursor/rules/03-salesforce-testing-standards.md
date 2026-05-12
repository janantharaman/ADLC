---
alwaysApply: true
---

# Salesforce Testing Standards

Comprehensive testing is mandatory for production deployments. These standards ensure code quality, reliability, and compliance with Salesforce requirements.

## Testing Requirements

### Code Coverage
- **75% minimum** for production deployment (Salesforce requirement)
- **80%+ recommended** for enterprise applications
- **90%+ recommended** for critical business logic
- Coverage is calculated across ALL Apex code in the org (not per class)

### Coverage Calculation
```
Code Coverage = (Lines Covered by Tests / Total Lines of Code) × 100%

Example:
- Total Lines: 1,000
- Covered Lines: 800
- Coverage: 800 / 1,000 = 80%
```

### What Counts Toward Coverage
✓ Apex Classes (all logic)
✓ Apex Triggers (all trigger events)
✗ Test classes themselves (excluded from coverage)
✗ Managed package code (excluded from coverage)

## Test Class Basics

### Test Class Structure
```apex
@isTest
private class AccountServiceTest {

    // @TestSetup - Runs ONCE, data available to all test methods
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    // Test method - Tests one specific scenario
    @isTest
    static void testCreateAccount() {
        // Given - Arrange
        String accountName = 'New Test Account';

        // When - Act
        Test.startTest();
        Account acc = AccountService.createAccount(accountName);
        Test.stopTest();

        // Then - Assert
        Account result = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals(accountName, result.Name, 'Account name should match');
        System.assertNotEquals(null, result.Id, 'Account should have been created');
    }

    // Test negative scenario
    @isTest
    static void testCreateAccount_NullName_ThrowsException() {
        // When/Then
        Test.startTest();
        try {
            AccountService.createAccount(null);
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('name'), 'Error message should mention name');
        }
        Test.stopTest();
    }

    // Test bulk scenario (200+ records)
    @isTest
    static void testBulkAccountCreation() {
        // Given
        List<String> accountNames = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            accountNames.add('Bulk Account ' + i);
        }

        // When
        Test.startTest();
        List<Account> accounts = AccountService.createAccounts(accountNames);
        Test.stopTest();

        // Then
        System.assertEquals(200, accounts.size(), 'Should create 200 accounts');
        List<Account> inserted = [SELECT Id FROM Account WHERE Name LIKE 'Bulk Account%'];
        System.assertEquals(200, inserted.size(), 'All accounts should be inserted');
    }
}
```

### Test Class Annotations
```apex
@isTest                    // Marks class as test class (no code coverage counted)
@isTest(SeeAllData=true)   // Access real data (AVOID - use test data instead)
@isTest(IsParallel=true)   // Enable parallel test execution (recommended)

@TestSetup                 // Runs once before all test methods in class
@isTest                    // Marks individual test method
```

## Test Data Management

### Test Data Factory Pattern (RECOMMENDED)
```apex
@isTest
public class TestDataFactory {

    /**
     * Creates test Accounts
     * @param count Number of accounts to create
     * @return List of created accounts (not inserted)
     */
    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                Rating = 'Warm',
                AnnualRevenue = 1000000
            ));
        }
        return accounts;
    }

    /**
     * Creates and inserts test Accounts
     */
    public static List<Account> insertAccounts(Integer count) {
        List<Account> accounts = createAccounts(count);
        insert accounts;
        return accounts;
    }

    /**
     * Creates test Contacts for given Accounts
     */
    public static List<Contact> createContacts(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + acc.Name,
                AccountId = acc.Id,
                Email = 'test@example.com'
            ));
        }
        return contacts;
    }

    /**
     * Creates complete test data hierarchy
     */
    public static Map<String, List<SObject>> createCompleteTestData() {
        Map<String, List<SObject>> testData = new Map<String, List<SObject>>();

        // Create Accounts
        List<Account> accounts = insertAccounts(10);
        testData.put('Accounts', accounts);

        // Create Contacts
        List<Contact> contacts = createContacts(accounts);
        insert contacts;
        testData.put('Contacts', contacts);

        // Create Opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            opps.add(new Opportunity(
                Name = acc.Name + ' Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;
        testData.put('Opportunities', opps);

        return testData;
    }
}
```

### Using Test Data Factory
```apex
@isTest
private class AccountServiceTest {

    @TestSetup
    static void setupTestData() {
        // Use factory to create consistent test data
        TestDataFactory.insertAccounts(200);
    }

    @isTest
    static void testAccountProcessing() {
        // Query test data created in @TestSetup
        List<Account> accounts = [SELECT Id, Name FROM Account];

        Test.startTest();
        AccountService.processAccounts(accounts);
        Test.stopTest();

        // Assertions...
    }
}
```

### Best Practices for Test Data
```
✓ Use @TestSetup for data shared across test methods
✓ Use Test Data Factory for reusable data creation
✓ NEVER use @isTest(SeeAllData=true) - creates fragile tests
✓ Create minimal data needed for the test
✓ Use realistic data (valid formats, required fields)
✓ Use unique data to avoid conflicts (timestamps, counters)
```

## Testing Triggers

### Trigger Test Structure
```apex
@isTest
private class AccountTriggerTest {

    @TestSetup
    static void setupTestData() {
        TestDataFactory.insertAccounts(200);
    }

    @isTest
    static void testBeforeInsert() {
        // Given
        List<Account> newAccounts = TestDataFactory.createAccounts(200);

        // When
        Test.startTest();
        insert newAccounts;
        Test.stopTest();

        // Then - Verify trigger logic executed
        List<Account> inserted = [SELECT Id, Rating FROM Account WHERE Name LIKE 'Test Account%'];
        for (Account acc : inserted) {
            System.assertEquals('Warm', acc.Rating, 'Trigger should set default rating');
        }
    }

    @isTest
    static void testBeforeUpdate() {
        // Given
        List<Account> accounts = [SELECT Id, Industry FROM Account];
        for (Account acc : accounts) {
            acc.Industry = 'Healthcare';
        }

        // When
        Test.startTest();
        update accounts;
        Test.stopTest();

        // Then
        List<Account> updated = [SELECT Id, Industry FROM Account];
        for (Account acc : updated) {
            System.assertEquals('Healthcare', acc.Industry);
        }
    }

    @isTest
    static void testAfterInsert() {
        // Given - Contacts should be created automatically
        List<Account> newAccounts = TestDataFactory.createAccounts(10);

        // When
        Test.startTest();
        insert newAccounts;
        Test.stopTest();

        // Then
        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :newAccounts
        ];
        System.assertEquals(10, contacts.size(), 'Should create one contact per account');
    }

    @isTest
    static void testBeforeDelete_PreventDeletionWithOpportunities() {
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
            System.assert(e.getMessage().contains('Opportunity'), 'Error should mention Opportunity');
        }
        Test.stopTest();
    }

    @isTest
    static void testTriggerBypass() {
        // Given
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        // When - Bypass trigger
        Test.startTest();
        TriggerHandler.bypass('AccountTriggerHandler');
        acc.Name = 'Updated Name';
        update acc;
        TriggerHandler.clearAllBypasses();
        Test.stopTest();

        // Then
        Account updated = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Name', updated.Name);
    }
}
```

## Testing Bulk Scenarios

### Why Test Bulk?
- Triggers can receive up to 200 records at once
- Batch Apex processes large volumes
- Data imports/migrations involve thousands of records
- Governor limits apply to bulk operations

### Bulk Test Example
```apex
@isTest
static void testBulkProcessing() {
    // Given - 200 records (trigger context size)
    List<Account> accounts = TestDataFactory.createAccounts(200);
    insert accounts;

    // Create related records (bulk)
    List<Contact> contacts = new List<Contact>();
    for (Account acc : accounts) {
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = acc.Id
            ));
        }
    }
    insert contacts; // 1,000 contacts

    // When - Update all accounts
    Test.startTest();
    for (Account acc : accounts) {
        acc.Industry = 'Technology';
    }
    update accounts;
    Test.stopTest();

    // Then - Verify bulk operation succeeded
    List<Account> updated = [SELECT Id, Industry FROM Account];
    System.assertEquals(200, updated.size());

    // Verify governor limits not exceeded
    System.assert(Limits.getQueries() < 100, 'SOQL queries within limits');
    System.assert(Limits.getDMLStatements() < 10, 'DML statements within limits');
}
```

## Testing Asynchronous Apex

### Testing @future Methods
```apex
public class AccountService {
    @future
    public static void sendEmailNotification(Id accountId) {
        // Send email logic
    }
}

@isTest
private class AccountServiceTest {
    @isTest
    static void testFutureMethod() {
        // Given
        Account acc = TestDataFactory.insertAccounts(1)[0];

        // When - Future methods execute between Test.startTest() and Test.stopTest()
        Test.startTest();
        AccountService.sendEmailNotification(acc.Id);
        Test.stopTest(); // Future method completes here

        // Then - Verify results
        // Check email was sent, logs updated, etc.
    }
}
```

### Testing Queueable Apex
```apex
public class AccountProcessingQueueable implements Queueable {
    private List<Account> accounts;

    public AccountProcessingQueueable(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        // Process accounts
        for (Account acc : accounts) {
            acc.Industry = 'Technology';
        }
        update accounts;
    }
}

@isTest
private class AccountProcessingQueueableTest {
    @isTest
    static void testQueueable() {
        // Given
        List<Account> accounts = TestDataFactory.insertAccounts(10);

        // When
        Test.startTest();
        System.enqueueJob(new AccountProcessingQueueable(accounts));
        Test.stopTest(); // Queueable executes here

        // Then
        List<Account> updated = [SELECT Id, Industry FROM Account];
        for (Account acc : updated) {
            System.assertEquals('Technology', acc.Industry);
        }
    }
}
```

### Testing Batch Apex
```apex
public class AccountUpdateBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Industry FROM Account]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            acc.Industry = 'Technology';
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        // Send completion email
    }
}

@isTest
private class AccountUpdateBatchTest {
    @TestSetup
    static void setupTestData() {
        TestDataFactory.insertAccounts(250); // More than batch size
    }

    @isTest
    static void testBatch() {
        // When
        Test.startTest();
        Database.executeBatch(new AccountUpdateBatch(), 200); // Batch size 200
        Test.stopTest(); // Batch completes here

        // Then
        List<Account> updated = [SELECT Id, Industry FROM Account];
        System.assertEquals(250, updated.size());
        for (Account acc : updated) {
            System.assertEquals('Technology', acc.Industry);
        }
    }
}
```

### Testing Scheduled Apex
```apex
public class DailyAccountUpdateScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountUpdateBatch());
    }
}

@isTest
private class DailyAccountUpdateSchedulerTest {
    @isTest
    static void testScheduler() {
        // When
        Test.startTest();
        String cron = '0 0 0 * * ?'; // Daily at midnight
        System.schedule('Test Schedule', cron, new DailyAccountUpdateScheduler());
        Test.stopTest(); // Scheduled job executes here

        // Then - Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE CronExpression = :cron
        ];
        System.assertEquals(1, jobs.size());
    }
}
```

## Testing Callouts

### Mock HTTP Callout
```apex
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"success","data":{"id":"12345"}}');
        res.setStatusCode(200);
        return res;
    }
}

@isTest
private class ExternalServiceTest {
    @isTest
    static void testCallout() {
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // When
        Test.startTest();
        String response = ExternalService.makeCallout();
        Test.stopTest();

        // Then
        System.assert(response.contains('success'));
    }
}
```

### Mock Multiple Callouts
```apex
@isTest
global class MultiMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // Different responses based on endpoint
        if (req.getEndpoint().contains('/api/accounts')) {
            res.setBody('{"accounts":[{"id":"1"}]}');
            res.setStatusCode(200);
        } else if (req.getEndpoint().contains('/api/contacts')) {
            res.setBody('{"contacts":[{"id":"2"}]}');
            res.setStatusCode(200);
        } else {
            res.setBody('{"error":"Not found"}');
            res.setStatusCode(404);
        }

        return res;
    }
}
```

## Assertion Best Practices

### Use Descriptive Assert Messages
```apex
// ❌ Bad - No context
System.assertEquals(10, accounts.size());

// ✅ Good - Clear message
System.assertEquals(10, accounts.size(), 'Should return 10 active accounts');
```

### Common Assertions
```apex
// Equality
System.assertEquals(expected, actual, 'Values should match');
System.assertNotEquals(unexpected, actual, 'Values should not match');

// Null checks
System.assertNotEquals(null, obj, 'Object should not be null');
System.assertEquals(null, obj, 'Object should be null');

// Boolean conditions
System.assert(condition, 'Condition should be true');
System.assert(!condition, 'Condition should be false');

// Collection checks
System.assertEquals(10, list.size(), 'List should have 10 elements');
System.assert(!list.isEmpty(), 'List should not be empty');
System.assert(map.containsKey(key), 'Map should contain key');
```

## Testing Lightning Web Components

### Jest Tests (JavaScript)
```javascript
// accountList.test.js
import { createElement } from 'lwc';
import AccountList from 'c/accountList';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

// Mock Apex method
jest.mock(
    '@salesforce/apex/AccountController.getAccounts',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-account-list', () => {
    afterEach(() => {
        // Clean up DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays accounts', async () => {
        // Given
        const mockAccounts = [
            { Id: '001', Name: 'Account 1' },
            { Id: '002', Name: 'Account 2' }
        ];
        getAccounts.mockResolvedValue(mockAccounts);

        // When
        const element = createElement('c-account-list', {
            is: AccountList
        });
        document.body.appendChild(element);

        // Wait for async operations
        await Promise.resolve();

        // Then
        const accountElements = element.shadowRoot.querySelectorAll('.account-item');
        expect(accountElements.length).toBe(2);
    });

    it('handles error', async () => {
        // Given
        getAccounts.mockRejectedValue(new Error('Failed to load'));

        // When
        const element = createElement('c-account-list', {
            is: AccountList
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Then
        const errorElement = element.shadowRoot.querySelector('.error');
        expect(errorElement).not.toBeNull();
    });
});
```

## Code Coverage Best Practices

### What NOT to Do
```apex
// ❌ Don't write tests just for coverage
@isTest
static void testCoverage() {
    AccountService.method1();
    AccountService.method2();
    AccountService.method3();
    // No assertions - this is useless
}
```

### What TO Do
```apex
// ✅ Write meaningful tests that verify behavior
@isTest
static void testAccountCreation_WithValidData_CreatesAccount() {
    // Given - Arrange
    String accountName = 'Test Account';

    // When - Act
    Test.startTest();
    Account acc = AccountService.createAccount(accountName);
    Test.stopTest();

    // Then - Assert
    System.assertNotEquals(null, acc.Id, 'Account should be created');
    System.assertEquals(accountName, acc.Name, 'Name should match input');
    System.assertEquals('Warm', acc.Rating, 'Default rating should be set');
}
```

## Running Tests

### Via Developer Console
```
Test → New Run → Select classes → Run
```

### Via VS Code (Salesforce Extensions)
```
Right-click test class → Run Apex Tests
```

### Via Salesforce CLI
```bash
# Run all tests in org
sf apex run test --test-level RunLocalTests --result-format human

# Run specific test class
sf apex run test --tests AccountServiceTest --result-format human

# Run tests with code coverage
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# Run tests in scratch org
sf apex run test --target-org MyScratchOrg --test-level RunLocalTests
```

## Test Coverage Checklist

Before deployment, ensure:
- [ ] 75%+ code coverage across all Apex
- [ ] All triggers have test classes
- [ ] Bulk scenarios tested (200+ records)
- [ ] Positive and negative test cases
- [ ] Async methods tested (between Test.startTest/stopTest)
- [ ] Governor limits verified in tests
- [ ] Callouts mocked with Test.setMock()
- [ ] Test data factory used (no SeeAllData=true)
- [ ] All assertions include descriptive messages
- [ ] LWC components have Jest tests

## When This Rule Applies

This testing standards rule is **ALWAYS ACTIVE** for:
- All Apex class development
- All trigger development
- All Lightning Web Component development
- All code reviews
- All production deployments
- All CI/CD pipelines

**Remember**: Tests are not just for coverage - they document expected behavior and prevent regressions.
