---
name: Testing Standards
layer: 1
type: universal-foundation
composable: true
requires: []
alwaysApply: true
tags: [testing, apex-test, jest, code-coverage, test-data]
---

# Testing Standards (Layer 1 - Universal Foundation)

Comprehensive testing is mandatory for ALL Salesforce development. This rule defines the baseline testing practices that ensure quality and reliability.

## Core Testing Principles

1. **Test Early, Test Often**: Write tests alongside code, not after
2. **Test Behavior, Not Implementation**: Tests should validate business logic, not internal mechanics
3. **Tests Are Documentation**: Good tests explain how code should work
4. **Automated Testing**: All tests must be runnable via CI/CD
5. **Quality Over Coverage**: 100% coverage with meaningless assertions is worse than 75% with quality tests

---

## Code Coverage Requirements

### Salesforce Deployment Requirements

**Minimum**: **75% code coverage** required to deploy to production
- Counted across ALL Apex classes and triggers in the org
- Does NOT include test classes themselves
- Does NOT include managed packages

**Best Practice**: Aim for **85-90% coverage** with meaningful tests

### What Counts Toward Coverage?

**Counted**:
- ✅ Apex classes (except test classes)
- ✅ Apex triggers

**NOT Counted**:
- ❌ Test classes themselves (`@isTest` classes)
- ❌ Managed package code
- ❌ Lightning Web Components (use Jest instead)
- ❌ Flows, Validation Rules, Formula Fields (declarative tools)

---

## Apex Test Structure

### Test Class Basics

**Annotation**: Use `@isTest` to mark test classes

```apex
@isTest
private class AccountTriggerHandler_Test {
    // Test methods go here
}
```

**Best Practices**:
- ✅ Use `private` access modifier (tests don't need to be public)
- ✅ Suffix test class with `_Test` or `Test`
- ✅ One test class per production class (e.g., `AccountService_Test` for `AccountService`)

### Test Method Structure: Arrange-Act-Assert

Every test method should follow the **Arrange-Act-Assert** pattern:

1. **Arrange**: Set up test data and preconditions
2. **Act**: Execute the method under test
3. **Assert**: Verify the results

```apex
@isTest
static void testAccountCreation() {
    // ARRANGE: Set up test data
    Account testAccount = new Account(Name = 'Test Account', Industry = 'Technology');

    // ACT: Execute the method
    Test.startTest();
    insert testAccount;
    Test.stopTest();

    // ASSERT: Verify the results
    Account insertedAccount = [SELECT Id, Name, Industry FROM Account WHERE Id = :testAccount.Id];
    System.assertEquals('Test Account', insertedAccount.Name, 'Account name should match');
    System.assertEquals('Technology', insertedAccount.Industry, 'Industry should match');
    System.assertNotEquals(null, insertedAccount.Id, 'Account should have an ID');
}
```

---

## @TestSetup: Reusable Test Data

**Purpose**: Create test data ONCE per test class, accessible to ALL test methods

**Benefits**:
- Faster test execution (data created once, not per test method)
- Cleaner test methods (less setup code)
- Consistent data across tests

```apex
@isTest
private class AccountTriggerHandler_Test {

    // This runs ONCE before all test methods
    @TestSetup
    static void setupTestData() {
        // Create 200 test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                AnnualRevenue = 1000000
            ));
        }
        insert accounts;

        // Create related contacts
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(
                FirstName = 'John',
                LastName = 'Doe ' + acc.Id,
                AccountId = acc.Id
            ));
        }
        insert contacts;
    }

    @isTest
    static void testBulkUpdate() {
        // ARRANGE: Retrieve test data from @TestSetup
        List<Account> accounts = [SELECT Id, Industry FROM Account];
        System.assertEquals(200, accounts.size(), 'Should have 200 test accounts');

        // ACT: Update all accounts
        for (Account acc : accounts) {
            acc.Industry = 'Finance';
        }

        Test.startTest();
        update accounts;
        Test.stopTest();

        // ASSERT: Verify update
        List<Account> updatedAccounts = [SELECT Id, Industry FROM Account];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Finance', acc.Industry, 'Industry should be updated');
        }
    }

    @isTest
    static void testAccountDeletion() {
        // ARRANGE: Retrieve test data from @TestSetup
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];

        // ACT: Delete accounts
        Test.startTest();
        delete accounts;
        Test.stopTest();

        // ASSERT: Verify deletion
        List<Account> remainingAccounts = [SELECT Id FROM Account];
        System.assertEquals(190, remainingAccounts.size(), 'Should have 190 accounts remaining');
    }
}
```

**Important**: Data created in `@TestSetup` is **rolled back after each test method**, so tests remain isolated.

---

## Test.startTest() and Test.stopTest()

### Purpose

**`Test.startTest()`**: Resets governor limits
**`Test.stopTest()`**: Executes async code (Batch, Queueable, Future, Scheduled) and resets governor limits again

### Governor Limit Reset

**Before `Test.startTest()`**:
- You have FULL governor limits for test setup (100 SOQL, 150 DML, etc.)

**Between `Test.startTest()` and `Test.stopTest()`**:
- Governor limits reset (fresh 100 SOQL, 150 DML, etc.)
- This is where you execute the code under test

**After `Test.stopTest()`**:
- Governor limits reset again
- Async code completes (Batch, Queueable, Future)
- Assertions run with full limits

### Example: Testing Async Code

```apex
@isTest
static void testQueueableJob() {
    // ARRANGE: Set up test data
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 10; i++) {
        accounts.add(new Account(Name = 'Test Account ' + i));
    }
    insert accounts;

    // ACT: Enqueue queueable job
    Test.startTest();
    System.enqueueJob(new AccountProcessingQueueable(accounts));
    Test.stopTest();  // Queueable job COMPLETES here (synchronous in test context)

    // ASSERT: Verify queueable job results
    List<Account> updatedAccounts = [SELECT Id, Processed__c FROM Account];
    for (Account acc : updatedAccounts) {
        System.assertEquals(true, acc.Processed__c, 'Account should be marked as processed');
    }
}
```

**Key Point**: Async code (Batch, Queueable, Future, Scheduled) executes **synchronously** during `Test.stopTest()` in test context.

---

## Testing Bulk Operations (CRITICAL)

**Principle**: ALWAYS test with **200+ records** to ensure bulkification.

### Why 200?

- Salesforce best practice: Design for 200 records per trigger execution
- Catches bulkification issues (SOQL queries in loops, DML in loops)
- Realistic production scenario

```apex
// ✅ GOOD: Tests bulk scenario (200 records)
@isTest
static void testBulkAccountInsert() {
    // ARRANGE: Create 200 accounts
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
        accounts.add(new Account(Name = 'Bulk Account ' + i, Industry = 'Technology'));
    }

    // ACT: Bulk insert
    Test.startTest();
    insert accounts;
    Test.stopTest();

    // ASSERT: Verify all 200 inserted successfully
    List<Account> insertedAccounts = [SELECT Id, Name FROM Account WHERE Name LIKE 'Bulk Account%'];
    System.assertEquals(200, insertedAccounts.size(), 'Should insert 200 accounts');
}

// ❌ BAD: Only tests single record
@isTest
static void testAccountInsert() {
    // ARRANGE: Create 1 account
    Account acc = new Account(Name = 'Test Account');

    // ACT: Single insert
    Test.startTest();
    insert acc;
    Test.stopTest();

    // ASSERT: Verify insertion
    Account insertedAccount = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
    System.assertNotEquals(null, insertedAccount, 'Account should be inserted');
}
// Problem: Doesn't catch bulkification issues (SOQL in loops, DML in loops)
```

---

## Testing Positive AND Negative Scenarios

### Positive Tests (Happy Path)

Test that code works correctly with valid inputs.

```apex
@isTest
static void testValidAccountCreation() {
    // ARRANGE: Valid account
    Account acc = new Account(Name = 'Acme Corp', Industry = 'Technology');

    // ACT: Insert
    Test.startTest();
    insert acc;
    Test.stopTest();

    // ASSERT: Success
    Account insertedAccount = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
    System.assertEquals('Acme Corp', insertedAccount.Name);
}
```

### Negative Tests (Error Handling)

Test that code handles errors gracefully.

```apex
@isTest
static void testInvalidAccountCreation() {
    // ARRANGE: Invalid account (missing required Name field)
    Account acc = new Account(Industry = 'Technology');

    // ACT & ASSERT: Expect DmlException
    Test.startTest();
    try {
        insert acc;
        System.assert(false, 'Expected DmlException for missing required field');
    } catch (DmlException e) {
        // Expected exception
        System.assert(e.getMessage().contains('REQUIRED_FIELD_MISSING'), 'Should fail due to missing Name');
    }
    Test.stopTest();
}

@isTest
static void testUnauthorizedUpdate() {
    // ARRANGE: Create account as System Admin
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    // Create user with limited permissions
    User limitedUser = createTestUser('Standard User Profile');

    // ACT & ASSERT: Limited user tries to update account (should fail)
    System.runAs(limitedUser) {
        acc.Industry = 'Finance';

        Test.startTest();
        try {
            update acc;
            System.assert(false, 'Expected SecurityException');
        } catch (SecurityException e) {
            // Expected exception
            System.assert(e.getMessage().contains('permission'), 'Should fail due to insufficient permissions');
        }
        Test.stopTest();
    }
}
```

### Edge Cases

Test boundary conditions and unusual inputs.

```apex
@isTest
static void testEmptyList() {
    // ARRANGE: Empty list
    List<Account> accounts = new List<Account>();

    // ACT: Process empty list
    Test.startTest();
    AccountService.processAccounts(accounts);
    Test.stopTest();

    // ASSERT: No errors, graceful handling
    System.assertEquals(0, accounts.size(), 'Should handle empty list gracefully');
}

@isTest
static void testNullInput() {
    // ACT & ASSERT: Null input
    Test.startTest();
    try {
        AccountService.processAccounts(null);
        System.assert(false, 'Expected IllegalArgumentException for null input');
    } catch (IllegalArgumentException e) {
        System.assert(e.getMessage().contains('cannot be null'), 'Should validate null input');
    }
    Test.stopTest();
}

@isTest
static void testMaximumVolume() {
    // ARRANGE: Maximum DML limit (10,000 records)
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 10000; i++) {
        accounts.add(new Account(Name = 'Max Volume Account ' + i));
    }

    // ACT: Insert at maximum volume
    Test.startTest();
    insert accounts;
    Test.stopTest();

    // ASSERT: All records inserted
    Integer count = [SELECT COUNT() FROM Account WHERE Name LIKE 'Max Volume Account%'];
    System.assertEquals(10000, count, 'Should handle maximum DML volume');
}
```

---

## Assertions: Verify Expected Behavior

### Assert Methods

**`System.assertEquals(expected, actual, message)`**:
```apex
System.assertEquals('Technology', acc.Industry, 'Industry should be Technology');
System.assertEquals(200, accounts.size(), 'Should have 200 accounts');
```

**`System.assertNotEquals(expected, actual, message)`**:
```apex
System.assertNotEquals(null, acc.Id, 'Account ID should not be null');
System.assertNotEquals(0, accounts.size(), 'Account list should not be empty');
```

**`System.assert(condition, message)`**:
```apex
System.assert(acc.AnnualRevenue > 0, 'Annual revenue should be positive');
System.assert(!accounts.isEmpty(), 'Account list should not be empty');
```

### Good Assertions

**✅ Descriptive Messages**:
```apex
System.assertEquals(200, accounts.size(), 'Should insert exactly 200 accounts in bulk operation');
System.assertNotEquals(null, acc.Id, 'Account should have an ID after successful insert');
```

**❌ Generic Messages**:
```apex
System.assertEquals(200, accounts.size(), 'Failed');  // Not helpful!
System.assertNotEquals(null, acc.Id, 'Error');        // What error?
```

**✅ Assert Meaningful Values**:
```apex
// Assert business logic, not just existence
System.assertEquals('Approved', order.Status__c, 'Order status should be Approved after payment');
System.assertEquals(1500.00, order.Total_Amount__c, 'Total should be original amount minus discount');
```

---

## Test Data Factories

**Purpose**: Centralize test data creation for reusability and consistency.

```apex
@isTest
public class TestDataFactory {

    public static Account createAccount(String name, String industry) {
        return new Account(
            Name = name,
            Industry = industry,
            BillingCity = 'San Francisco',
            BillingState = 'CA'
        );
    }

    public static List<Account> createAccounts(Integer count, String industry) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount('Test Account ' + i, industry));
        }
        return accounts;
    }

    public static Contact createContact(String firstName, String lastName, Id accountId) {
        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = accountId,
            Email = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@test.com'
        );
    }

    public static User createTestUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + DateTime.now().getTime() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert u;
        return u;
    }
}
```

**Usage**:
```apex
@isTest
static void testAccountProcessing() {
    // ARRANGE: Use test data factory
    List<Account> accounts = TestDataFactory.createAccounts(200, 'Technology');
    insert accounts;

    // ACT: Process accounts
    Test.startTest();
    AccountService.processAccounts(accounts);
    Test.stopTest();

    // ASSERT
    // ...
}
```

---

## HttpCalloutMock: Testing API Callouts

**Problem**: Can't make real HTTP callouts in tests (Salesforce doesn't allow external network access during tests).

**Solution**: Use `HttpCalloutMock` to simulate HTTP responses.

### Single Endpoint Mock

```apex
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create mock response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"success", "message":"Order processed"}');
        res.setStatusCode(200);
        return res;
    }
}

@isTest
static void testApiCallout() {
    // ARRANGE: Set mock callout
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    // ACT: Make callout
    Test.startTest();
    HttpResponse response = OrderService.sendOrderToExternalSystem(orderId);
    Test.stopTest();

    // ASSERT: Verify response
    System.assertEquals(200, response.getStatusCode(), 'Should return 200 OK');
    System.assert(response.getBody().contains('success'), 'Response should indicate success');
}
```

### Multi-Endpoint Mock

```apex
@isTest
global class MultiEndpointMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // Route based on endpoint
        if (req.getEndpoint().contains('/orders')) {
            res.setBody('{"orderId":"12345", "status":"created"}');
            res.setStatusCode(201);
        } else if (req.getEndpoint().contains('/customers')) {
            res.setBody('{"customerId":"67890", "name":"Acme Corp"}');
            res.setStatusCode(200);
        } else {
            res.setBody('{"error":"Not found"}');
            res.setStatusCode(404);
        }

        return res;
    }
}

@isTest
static void testMultipleCallouts() {
    Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());

    Test.startTest();
    HttpResponse orderResponse = OrderService.createOrder();
    HttpResponse customerResponse = CustomerService.getCustomer();
    Test.stopTest();

    System.assertEquals(201, orderResponse.getStatusCode());
    System.assertEquals(200, customerResponse.getStatusCode());
}
```

---

## System.runAs: Testing with Different Users

**Purpose**: Test code behavior under different user permissions.

```apex
@isTest
static void testRestrictedUserAccess() {
    // ARRANGE: Create test user with limited permissions
    User standardUser = TestDataFactory.createTestUser('Standard User Profile');

    Account acc = new Account(Name = 'Test Account', Industry = 'Technology');
    insert acc;

    // ACT: Run code as limited user
    System.runAs(standardUser) {
        // Code here runs with standardUser's permissions

        Test.startTest();
        List<Account> accounts = AccountService.getAccounts();
        Test.stopTest();

        // ASSERT: User sees only accounts they have access to
        System.assert(accounts.size() <= 10, 'Standard user should have limited visibility');
    }
}

@isTest
static void testAdminUserAccess() {
    // ARRANGE: Create admin user
    User adminUser = TestDataFactory.createTestUser('System Administrator');

    Account acc = new Account(Name = 'Test Account', Industry = 'Technology');
    insert acc;

    // ACT: Run code as admin
    System.runAs(adminUser) {
        Test.startTest();
        List<Account> accounts = AccountService.getAccounts();
        Test.stopTest();

        // ASSERT: Admin sees all accounts
        System.assert(accounts.size() > 0, 'Admin should see all accounts');
    }
}
```

---

## LWC Testing with Jest

**Jest** is the JavaScript testing framework for Lightning Web Components.

### Basic Jest Test Structure

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
    // Clean up DOM after each test
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders account list', async () => {
        // ARRANGE: Mock Apex response
        const mockAccounts = [
            { Id: '001xxx000001', Name: 'Account 1', Industry: 'Technology' },
            { Id: '001xxx000002', Name: 'Account 2', Industry: 'Finance' }
        ];
        getAccounts.mockResolvedValue(mockAccounts);

        // ACT: Create component
        const element = createElement('c-account-list', {
            is: AccountList
        });
        document.body.appendChild(element);

        // Wait for async operations
        await Promise.resolve();

        // ASSERT: Verify rendering
        const listItems = element.shadowRoot.querySelectorAll('li');
        expect(listItems.length).toBe(2);
        expect(listItems[0].textContent).toBe('Account 1');
        expect(listItems[1].textContent).toBe('Account 2');
    });

    it('handles error gracefully', async () => {
        // ARRANGE: Mock Apex error
        getAccounts.mockRejectedValue(new Error('Network error'));

        // ACT: Create component
        const element = createElement('c-account-list', {
            is: AccountList
        });
        document.body.appendChild(element);

        // Wait for error handling
        await Promise.resolve();

        // ASSERT: Error message displayed
        const errorElement = element.shadowRoot.querySelector('.error-message');
        expect(errorElement).not.toBeNull();
        expect(errorElement.textContent).toContain('error');
    });

    it('handles user click event', async () => {
        // ARRANGE: Mock Apex response
        const mockAccounts = [{ Id: '001xxx000001', Name: 'Account 1' }];
        getAccounts.mockResolvedValue(mockAccounts);

        const element = createElement('c-account-list', {
            is: AccountList
        });
        document.body.appendChild(element);
        await Promise.resolve();

        // ACT: Simulate click
        const button = element.shadowRoot.querySelector('button');
        button.click();

        // ASSERT: Component state changed
        expect(element.selectedAccountId).toBe('001xxx000001');
    });
});
```

### Jest Coverage Target

**Best Practice**: Aim for **80%+ coverage** for Lightning Web Components.

---

## Testing Checklist

Before marking code as "done", verify:

- ✅ **75% minimum coverage** (aim for 85%+)
- ✅ **All test methods pass**
- ✅ **Bulk testing** (200+ records)
- ✅ **Positive scenarios** tested (happy path)
- ✅ **Negative scenarios** tested (error handling, invalid inputs)
- ✅ **Edge cases** tested (null, empty, max volume)
- ✅ **Assertions included** with descriptive messages
- ✅ **Test data isolated** (no hard-coded IDs, use `@TestSetup`)
- ✅ **API callouts mocked** (if applicable)
- ✅ **User permissions tested** (if applicable, use `System.runAs`)
- ✅ **LWC tests included** (if applicable, Jest tests)

---

## Quality Over Coverage

**❌ Bad Test (High Coverage, Low Value)**:
```apex
@isTest
static void testMethod1() {
    AccountService.processAccounts(new List<Account>());
    System.assert(true);  // Meaningless assertion!
}
// Problem: Achieves coverage but doesn't validate behavior
```

**✅ Good Test (Meaningful Validation)**:
```apex
@isTest
static void testAccountProcessingUpdatesStatus() {
    // ARRANGE
    List<Account> accounts = TestDataFactory.createAccounts(200, 'Technology');
    insert accounts;

    // ACT
    Test.startTest();
    AccountService.processAccounts(accounts);
    Test.stopTest();

    // ASSERT: Validate expected behavior
    List<Account> processedAccounts = [SELECT Id, Status__c FROM Account WHERE Id IN :accounts];
    for (Account acc : processedAccounts) {
        System.assertEquals('Processed', acc.Status__c, 'Account status should be updated to Processed');
    }
}
// Value: Validates actual business logic
```

---

**Tests are living documentation of how code should behave. Write tests that future developers (including yourself) will thank you for.**

**Applies to**: All Salesforce developers (Apex, LWC, Integrations, Data, Admin)
