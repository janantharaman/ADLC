# Modern Testing Patterns (Winter '23+)

Expert reference for modern Apex testing: StubProvider, SoqlStubProvider, and testing without DML.

## Overview

Modern testing patterns enable:
- **StubProvider** (Winter '23): Mock any interface without deployment
- **SoqlStubProvider** (Winter '23): Mock SOQL queries without database
- **Faster Tests**: Eliminate DML overhead, run tests in milliseconds
- **Better Isolation**: Test business logic independent of database state

---

## StubProvider Interface (Winter '23+)

**Introduced**: Winter '23 (API 56.0+)
**Purpose**: Create mock implementations of interfaces without deploying test code
**Benefit**: Test business logic in isolation, 10-100x faster tests

### The Problem: Traditional Testing

```apex
// ❌ TRADITIONAL: Requires DML, slow, brittle
@isTest
static void testAccountService() {
    // Setup (slow DML)
    Account acc = new Account(Name = 'Test');
    insert acc; // DML operation

    Contact con = new Contact(
        FirstName = 'John',
        LastName = 'Doe',
        AccountId = acc.Id
    );
    insert con; // Another DML operation

    // Test
    Test.startTest();
    AccountService.updateAccountContacts(acc.Id);
    Test.stopTest();

    // Verify (slow SOQL)
    Contact updated = [SELECT Id, Title FROM Contact WHERE Id = :con.Id];
    System.assertEquals('Updated', updated.Title);
}
```

### Solution: StubProvider

```apex
/**
 * @description Test with StubProvider - no DML, fast, isolated
 * @since API 56.0 (Winter '23)
 */
@isTest
static void testAccountServiceWithStub() {
    // Create stub - NO DML needed
    AccountSelector mockSelector = (AccountSelector) Test.createStub(
        AccountSelector.class,
        new AccountSelectorStub()
    );

    // Inject stub into service
    AccountService service = new AccountService(mockSelector);

    // Test business logic in isolation
    Test.startTest();
    List<Account> results = service.getAccountsByIndustry('Technology');
    Test.stopTest();

    // Verify
    System.assertEquals(5, results.size(), 'Should return 5 accounts');
    System.assertEquals('Technology', results[0].Industry);
}
```

### Creating a StubProvider

```apex
/**
 * @description Stub implementation for AccountSelector
 */
@isTest
public class AccountSelectorStub implements System.StubProvider {

    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        // Route to appropriate mock method
        if (stubbedMethodName == 'getAccountsByIndustry') {
            return mockGetAccountsByIndustry((String) listOfArgs[0]);
        }

        if (stubbedMethodName == 'getAccountById') {
            return mockGetAccountById((Id) listOfArgs[0]);
        }

        return null;
    }

    private List<Account> mockGetAccountsByIndustry(String industry) {
        // Return mock data without SOQL
        List<Account> mockAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            mockAccounts.add(new Account(
                Id = TestUtils.generateId(Account.SObjectType),
                Name = 'Test Account ' + i,
                Industry = industry
            ));
        }
        return mockAccounts;
    }

    private Account mockGetAccountById(Id accountId) {
        return new Account(
            Id = accountId,
            Name = 'Test Account',
            Industry = 'Technology'
        );
    }
}
```

### Production Code Pattern (Dependency Injection)

```apex
/**
 * @description Service layer with dependency injection for testability
 */
public class AccountService {

    private AccountSelector selector;

    // Constructor injection
    public AccountService(AccountSelector selector) {
        this.selector = selector;
    }

    // Default constructor for production
    public AccountService() {
        this(new AccountSelector());
    }

    public List<Account> getAccountsByIndustry(String industry) {
        // Uses injected selector (real or mock)
        List<Account> accounts = selector.getAccountsByIndustry(industry);

        // Business logic
        for (Account acc : accounts) {
            if (acc.AnnualRevenue == null) {
                acc.AnnualRevenue = 0;
            }
        }

        return accounts;
    }
}

/**
 * @description Selector interface for mocking
 */
public interface AccountSelector {
    List<Account> getAccountsByIndustry(String industry);
    Account getAccountById(Id accountId);
}

/**
 * @description Real selector implementation
 */
public class AccountSelectorImpl implements AccountSelector {

    public List<Account> getAccountsByIndustry(String industry) {
        return [
            SELECT Id, Name, Industry, AnnualRevenue
            FROM Account
            WHERE Industry = :industry
            WITH USER_MODE
            LIMIT 200
        ];
    }

    public Account getAccountById(Id accountId) {
        return [
            SELECT Id, Name, Industry, AnnualRevenue
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
        ];
    }
}
```

### Complete Test Example

```apex
@isTest
private class AccountServiceTest {

    @isTest
    static void testGetAccountsByIndustry() {
        // Given: Mock selector
        AccountSelector mockSelector = (AccountSelector) Test.createStub(
            AccountSelector.class,
            new AccountSelectorStub()
        );

        AccountService service = new AccountService(mockSelector);

        // When: Get accounts
        Test.startTest();
        List<Account> results = service.getAccountsByIndustry('Technology');
        Test.stopTest();

        // Then: Verify business logic
        System.assertEquals(5, results.size(), 'Should return 5 accounts');
        for (Account acc : results) {
            System.assertEquals('Technology', acc.Industry);
            System.assertNotEquals(null, acc.AnnualRevenue, 'Should set default revenue');
        }
    }

    @isTest
    static void testGetAccountsByIndustryEmptyResult() {
        // Given: Mock selector returning empty list
        AccountSelector mockSelector = (AccountSelector) Test.createStub(
            AccountSelector.class,
            new EmptyAccountSelectorStub()
        );

        AccountService service = new AccountService(mockSelector);

        // When
        Test.startTest();
        List<Account> results = service.getAccountsByIndustry('Nonprofit');
        Test.stopTest();

        // Then
        System.assertEquals(0, results.size(), 'Should return empty list');
    }
}

@isTest
class EmptyAccountSelectorStub implements System.StubProvider {
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        // Return empty list for all methods
        return new List<Account>();
    }
}
```

---

## SoqlStubProvider (Winter '23+)

**Introduced**: Winter '23 (API 56.0+)
**Purpose**: Mock SOQL queries with predefined results
**Benefit**: Test SOQL logic without database, instant tests

### Basic Usage

```apex
@isTest
static void testWithSoqlStub() {
    // Create mock account
    Account mockAccount = new Account(
        Id = TestUtils.generateId(Account.SObjectType),
        Name = 'Test Account',
        Industry = 'Technology'
    );

    // Create SOQL stub
    Test.SoqlStubProvider stub = Test.createSoqlStubProvider(
        new Map<String, List<SObject>>{
            'Account' => new List<Account>{ mockAccount }
        }
    );

    // Set stub
    Test.setSoqlStubProvider(stub);

    // Query returns mock data
    Test.startTest();
    Account result = [SELECT Id, Name FROM Account LIMIT 1];
    Test.stopTest();

    // Verify
    System.assertEquals(mockAccount.Id, result.Id);
    System.assertEquals('Test Account', result.Name);
}
```

### Advanced SOQL Stubbing

```apex
/**
 * @description Custom SOQL stub with query-specific responses
 */
@isTest
public class CustomSoqlStub implements Test.SoqlStubProvider {

    private Map<String, List<SObject>> resultsByObject;

    public CustomSoqlStub(Map<String, List<SObject>> resultsByObject) {
        this.resultsByObject = resultsByObject;
    }

    public List<SObject> handleSoqlQuery(
        String soqlQuery,
        List<SObject> queryResults
    ) {
        // Parse query to determine object type
        String objectName = extractObjectName(soqlQuery);

        // Return mock results for this object
        if (resultsByObject.containsKey(objectName)) {
            return resultsByObject.get(objectName);
        }

        return new List<SObject>();
    }

    private String extractObjectName(String soqlQuery) {
        // Extract "FROM Account" -> "Account"
        Pattern p = Pattern.compile('FROM\\s+(\\w+)');
        Matcher m = p.matcher(soqlQuery);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }
}

// Usage
@isTest
static void testMultipleQueries() {
    // Setup mock data for multiple objects
    List<Account> mockAccounts = new List<Account>{
        new Account(Id = TestUtils.generateId(Account.SObjectType), Name = 'Account 1'),
        new Account(Id = TestUtils.generateId(Account.SObjectType), Name = 'Account 2')
    };

    List<Contact> mockContacts = new List<Contact>{
        new Contact(
            Id = TestUtils.generateId(Contact.SObjectType),
            FirstName = 'John',
            LastName = 'Doe'
        )
    };

    // Create custom stub
    CustomSoqlStub stub = new CustomSoqlStub(
        new Map<String, List<SObject>>{
            'Account' => mockAccounts,
            'Contact' => mockContacts
        }
    );

    Test.setSoqlStubProvider(stub);

    // Test multiple queries
    Test.startTest();
    List<Account> accounts = [SELECT Id, Name FROM Account];
    List<Contact> contacts = [SELECT Id, FirstName FROM Contact];
    Test.stopTest();

    // Verify
    System.assertEquals(2, accounts.size());
    System.assertEquals(1, contacts.size());
}
```

---

## Test Utility: Fake ID Generator

```apex
/**
 * @description Utility to generate fake Salesforce IDs for testing
 */
@isTest
public class TestUtils {

    private static Integer idCounter = 1;

    public static Id generateId(Schema.SObjectType objectType) {
        String keyPrefix = objectType.getDescribe().getKeyPrefix();
        String fakeId = keyPrefix + '0'.repeat(12 - String.valueOf(idCounter).length()) + idCounter;
        idCounter++;
        return Id.valueOf(fakeId);
    }

    public static List<Id> generateIds(Schema.SObjectType objectType, Integer count) {
        List<Id> ids = new List<Id>();
        for (Integer i = 0; i < count; i++) {
            ids.add(generateId(objectType));
        }
        return ids;
    }
}

// Usage
@isTest
static void testWithFakeIds() {
    Id accountId = TestUtils.generateId(Account.SObjectType); // 0010000000001
    Id contactId = TestUtils.generateId(Contact.SObjectType); // 0030000000001

    Account mockAccount = new Account(
        Id = accountId,
        Name = 'Test Account'
    );

    // Use in tests without DML
}
```

---

## Comparison: Traditional vs Modern Testing

| Aspect | Traditional (DML-based) | Modern (Stub-based) |
|--------|------------------------|---------------------|
| **Speed** | Slow (100-500ms per test) | Fast (1-10ms per test) |
| **Setup** | DML required (insert, update) | No DML (instantiate objects) |
| **Isolation** | Database state affects tests | Pure unit tests |
| **Dependencies** | Triggers fire, rules execute | Complete isolation |
| **Maintenance** | Breaks on schema changes | Breaks only on interface changes |
| **Coverage** | Can test integration | Tests logic only |

### When to Use Each

```apex
// ✅ USE STUBS for: Unit tests (business logic)
@isTest
static void testBusinessLogic() {
    // Mock dependencies, test logic in isolation
    AccountService service = new AccountService(mockSelector);
    List<Account> results = service.getAccountsByIndustry('Tech');
    System.assertEquals(5, results.size());
}

// ✅ USE DML for: Integration tests (full flow)
@isTest
static void testIntegration() {
    // Test full flow including triggers, validation rules
    Account acc = new Account(Name = 'Test');
    insert acc; // Triggers fire

    Contact con = new Contact(
        FirstName = 'John',
        LastName = 'Doe',
        AccountId = acc.Id
    );
    insert con;

    // Verify full integration
    acc = [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id = :acc.Id];
    System.assertEquals(1, acc.Contacts.size());
}
```

---

## Migration from Traditional Tests

### Before: Traditional Test

```apex
@isTest
private class AccountServiceTest {

    @TestSetup
    static void setupData() {
        // DML setup (slow)
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert accounts;
    }

    @isTest
    static void testGetAccountsByIndustry() {
        // Test
        Test.startTest();
        List<Account> results = AccountService.getAccountsByIndustry('Technology');
        Test.stopTest();

        // Verify
        System.assertEquals(200, results.size());
    }
}
```

### After: Modern Test with Stubs

```apex
@isTest
private class AccountServiceTest {

    // No TestSetup needed - using stubs

    @isTest
    static void testGetAccountsByIndustry() {
        // Given: Mock selector
        AccountSelector mockSelector = (AccountSelector) Test.createStub(
            AccountSelector.class,
            new AccountSelectorStub()
        );

        AccountService service = new AccountService(mockSelector);

        // When
        Test.startTest();
        List<Account> results = service.getAccountsByIndustry('Technology');
        Test.stopTest();

        // Then
        System.assertEquals(5, results.size());
    }

    @isTest
    static void testBusinessLogicDefaultRevenue() {
        // Test specific business logic: default revenue to 0
        AccountSelector mockSelector = (AccountSelector) Test.createStub(
            AccountSelector.class,
            new AccountSelectorStubNullRevenue() // Returns accounts with null revenue
        );

        AccountService service = new AccountService(mockSelector);

        Test.startTest();
        List<Account> results = service.getAccountsByIndustry('Technology');
        Test.stopTest();

        // Verify business logic
        for (Account acc : results) {
            System.assertEquals(0, acc.AnnualRevenue, 'Should default to 0');
        }
    }
}

@isTest
class AccountSelectorStubNullRevenue implements System.StubProvider {
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        if (stubbedMethodName == 'getAccountsByIndustry') {
            List<Account> accounts = new List<Account>();
            for (Integer i = 0; i < 5; i++) {
                accounts.add(new Account(
                    Id = TestUtils.generateId(Account.SObjectType),
                    Name = 'Test Account ' + i,
                    Industry = 'Technology',
                    AnnualRevenue = null // Test null case
                ));
            }
            return accounts;
        }
        return null;
    }
}
```

---

## Best Practices

### 1. Separate Unit Tests from Integration Tests

```apex
// ✅ GOOD: Clear test names
@isTest
static void testBusinessLogic_DefaultRevenue_Unit() {
    // Stub-based, tests logic only
}

@isTest
static void testFullFlow_CreateAccountWithContacts_Integration() {
    // DML-based, tests full flow
}
```

### 2. Use Dependency Injection

```apex
// ✅ GOOD: Constructor injection
public class AccountService {
    private AccountSelector selector;

    public AccountService(AccountSelector selector) {
        this.selector = selector;
    }

    public AccountService() {
        this(new AccountSelectorImpl());
    }
}

// ❌ BAD: Hardcoded dependency
public class AccountService {
    public List<Account> getAccounts() {
        // Can't mock this!
        return [SELECT Id FROM Account];
    }
}
```

### 3. Create Reusable Stubs

```apex
// ✅ GOOD: Reusable stub library
@isTest
public class TestStubs {

    public class AccountSelectorStub implements System.StubProvider {
        private List<Account> accountsToReturn;

        public AccountSelectorStub(List<Account> accountsToReturn) {
            this.accountsToReturn = accountsToReturn;
        }

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'getAccountsByIndustry') {
                return accountsToReturn;
            }
            return null;
        }
    }
}

// Usage across multiple tests
@isTest
static void test1() {
    List<Account> mockData = new List<Account>{
        new Account(Id = TestUtils.generateId(Account.SObjectType), Name = 'Test')
    };
    AccountSelector stub = (AccountSelector) Test.createStub(
        AccountSelector.class,
        new TestStubs.AccountSelectorStub(mockData)
    );
}
```

### 4. Test Both Success and Failure Cases

```apex
@isTest
static void testSuccess() {
    // Mock successful scenario
    AccountSelector mockSelector = createSuccessStub();
    AccountService service = new AccountService(mockSelector);

    List<Account> results = service.getAccountsByIndustry('Tech');
    System.assertEquals(5, results.size());
}

@isTest
static void testEmptyResult() {
    // Mock empty result
    AccountSelector mockSelector = createEmptyStub();
    AccountService service = new AccountService(mockSelector);

    List<Account> results = service.getAccountsByIndustry('Nonprofit');
    System.assertEquals(0, results.size());
}

@isTest
static void testException() {
    // Mock exception scenario
    AccountSelector mockSelector = createExceptionStub();
    AccountService service = new AccountService(mockSelector);

    try {
        service.getAccountsByIndustry('Invalid');
        System.assert(false, 'Should throw exception');
    } catch (Exception e) {
        System.assert(e.getMessage().contains('Invalid'));
    }
}
```

---

## Performance Comparison

### Traditional Test (DML-based)

```apex
@isTest
static void traditionalTest() {
    // Setup: 200ms
    List<Account> accounts = TestDataFactory.createAccounts(200);
    insert accounts;

    // Execute: 100ms
    Test.startTest();
    AccountService.processAccounts(accounts);
    Test.stopTest();

    // Verify: 50ms
    List<Account> updated = [SELECT Id, Status__c FROM Account];

    // Total: ~350ms
}
```

### Modern Test (Stub-based)

```apex
@isTest
static void modernTest() {
    // Setup: 1ms (instantiate objects)
    AccountSelector mockSelector = (AccountSelector) Test.createStub(
        AccountSelector.class,
        new AccountSelectorStub()
    );

    // Execute: 5ms (pure logic)
    Test.startTest();
    AccountService service = new AccountService(mockSelector);
    List<Account> results = service.getAccountsByIndustry('Tech');
    Test.stopTest();

    // Verify: 1ms (assertions)
    System.assertEquals(5, results.size());

    // Total: ~7ms (50x faster!)
}
```

---

## Quick Reference

### Create Stub
```apex
MyInterface stub = (MyInterface) Test.createStub(
    MyInterface.class,
    new MyStubProvider()
);
```

### Stub Implementation
```apex
public class MyStubProvider implements System.StubProvider {
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        // Return mock data
        return mockData;
    }
}
```

### Generate Fake ID
```apex
Id fakeId = TestUtils.generateId(Account.SObjectType);
```

### SOQL Stub
```apex
Test.SoqlStubProvider stub = Test.createSoqlStubProvider(
    new Map<String, List<SObject>>{
        'Account' => mockAccounts
    }
);
Test.setSoqlStubProvider(stub);
```

---

## Resources

- [StubProvider Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_System_StubProvider.htm)
- [Test.createStub() Method](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_test.htm#apex_System_Test_createStub)
- [Dependency Injection Pattern](https://developer.salesforce.com/blogs/2022/07/test-apex-with-stub-api.html)
- Testing Standards: `.cursor/rules/layer-1-universal/03-testing-standards.md`
