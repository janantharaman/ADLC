# Modern Language Features (Spring '23+)

Expert reference for modern Apex syntax: Safe navigation operator and null coalescing operator.

## Overview

**Introduced**: Spring '23 (API 57.0+)
**Purpose**: Simplify null handling with concise, readable syntax
**Features**:
- **Safe Navigation (`?.`)**: Null-safe property/method access
- **Null Coalescing (`??`)**: Default value assignment

---

## Safe Navigation Operator (`?.`)

**Syntax**: `object?.property` or `object?.method()`
**Purpose**: Access properties/methods only if object is not null
**Returns**: `null` if any part of chain is null

### Basic Usage

```apex
// ❌ BEFORE: Manual null checks
String ownerName;
if (account != null && account.Owner != null && account.Owner.Name != null) {
    ownerName = account.Owner.Name;
} else {
    ownerName = 'Unknown';
}

// ✅ AFTER: Safe navigation
String ownerName = account?.Owner?.Name;
if (ownerName == null) {
    ownerName = 'Unknown';
}
```

### Property Access

```apex
/**
 * @description Safe navigation for property access
 */
public class AccountService {

    public static String getOwnerName(Account account) {
        // Returns null if account, Owner, or Name is null
        return account?.Owner?.Name;
    }

    public static String getOwnerEmail(Account account) {
        // Chain multiple properties safely
        return account?.Owner?.Email;
    }

    public static Integer getContactCount(Account account) {
        // Works with relationship queries
        return account?.Contacts?.size();
    }
}

// Usage
Account acc = [SELECT Id, Owner.Name, Owner.Email FROM Account LIMIT 1];
String ownerName = AccountService.getOwnerName(acc); // Safe even if Owner is null
```

### Method Invocation

```apex
/**
 * @description Safe navigation for method calls
 */
public class ContactService {

    public static String getFormattedPhone(Contact contact) {
        // Call method only if contact is not null
        return contact?.getFormattedPhone();
    }

    public static Boolean isVIP(Contact contact) {
        // Works with Boolean returns
        Boolean vip = contact?.isVIP();
        return vip != null && vip;
    }
}

public class Contact {
    public String getFormattedPhone() {
        if (String.isNotBlank(this.Phone)) {
            return this.Phone.replaceAll('[^0-9]', '');
        }
        return null;
    }

    public Boolean isVIP() {
        return this.Tier__c == 'Gold' || this.Tier__c == 'Platinum';
    }
}
```

### Collection Access

```apex
/**
 * @description Safe navigation with collections
 */
public static String getFirstContactName(Account account) {
    // Safe access to collection element
    return account?.Contacts?.isEmpty() == false
        ? account.Contacts[0]?.Name
        : null;
}

public static String getFirstOpportunityStage(Account account) {
    // Chain with collection and property access
    List<Opportunity> opps = account?.Opportunities;
    return opps?.isEmpty() == false ? opps[0]?.StageName : null;
}
```

### Complex Chaining

```apex
/**
 * @description Complex safe navigation chains
 */
public class OpportunityService {

    public static String getAccountOwnerManagerName(Opportunity opp) {
        // Multi-level relationship traversal
        return opp?.Account?.Owner?.Manager?.Name;
    }

    public static String getPrimaryContactRole(Opportunity opp) {
        // Navigate through relationship to custom field
        return opp?.Primary_Contact__r?.Role__c;
    }

    public static Decimal getAccountAnnualRevenue(Opportunity opp) {
        // Safe access to numeric fields
        return opp?.Account?.AnnualRevenue;
    }
}
```

---

## Null Coalescing Operator (`??`)

**Syntax**: `value1 ?? value2 ?? value3`
**Purpose**: Return first non-null value
**Returns**: First non-null value in chain, or `null` if all are null

### Basic Usage

```apex
// ❌ BEFORE: Nested ternary or if-else
String displayName = account.Name != null ? account.Name :
                    (account.Nickname__c != null ? account.Nickname__c : 'Unknown');

// ✅ AFTER: Null coalescing
String displayName = account.Name ?? account.Nickname__c ?? 'Unknown';
```

### Default Values

```apex
/**
 * @description Null coalescing for default values
 */
public class AccountService {

    public static Decimal getRevenue(Account account) {
        // Default to 0 if null
        return account.AnnualRevenue ?? 0;
    }

    public static String getIndustry(Account account) {
        // Default to 'Other' if null
        return account.Industry ?? 'Other';
    }

    public static Integer getEmployeeCount(Account account) {
        // Default to 1 if null
        return account.NumberOfEmployees ?? 1;
    }
}
```

### Multiple Fallbacks

```apex
/**
 * @description Multiple fallback values
 */
public static String getContactInfo(Contact contact) {
    // Try email, then phone, then mailing address, then default
    return contact.Email
        ?? contact.Phone
        ?? contact.MailingStreet
        ?? 'No contact info';
}

public static String getPreferredName(Contact contact) {
    // Try nickname, then first name, then last name, then default
    return contact.Nickname__c
        ?? contact.FirstName
        ?? contact.LastName
        ?? 'Unknown';
}
```

### Configuration Values

```apex
/**
 * @description Use for configuration defaults
 */
public class ConfigService {

    public static Integer getMaxRetries() {
        Config__c config = Config__c.getOrgDefaults();
        // Default to 3 if not configured
        return (Integer) config?.Max_Retries__c ?? 3;
    }

    public static Integer getTimeoutSeconds() {
        Config__c config = Config__c.getOrgDefaults();
        // Default to 30 seconds
        return (Integer) config?.Timeout_Seconds__c ?? 30;
    }

    public static String getAPIEndpoint() {
        Config__c config = Config__c.getOrgDefaults();
        // Default to production endpoint
        return config?.API_Endpoint__c ?? 'https://api.production.com';
    }
}
```

---

## Combining Both Operators

**Pattern**: `object?.property ?? defaultValue`
**Purpose**: Safe navigation with default fallback

### Common Patterns

```apex
/**
 * @description Combine safe navigation and null coalescing
 */
public class CombinedExamples {

    // Pattern 1: Safe navigation + default value
    public static String getOwnerName(Account account) {
        return account?.Owner?.Name ?? 'Unassigned';
    }

    // Pattern 2: Complex chain + default
    public static String getManagerEmail(Contact contact) {
        return contact?.Account?.Owner?.Manager?.Email ?? 'no-manager@company.com';
    }

    // Pattern 3: Multiple properties + default
    public static String getContactMethod(Contact contact) {
        return contact?.Email ?? contact?.Phone ?? contact?.MailingAddress ?? 'No contact method';
    }

    // Pattern 4: Collection access + default
    public static String getFirstContactName(Account account) {
        return account?.Contacts?.isEmpty() == false
            ? account.Contacts[0]?.Name ?? 'Unnamed Contact'
            : 'No Contacts';
    }

    // Pattern 5: Numeric with default
    public static Decimal calculateDiscount(Opportunity opp) {
        Decimal discountPercent = opp?.Discount_Percent__c ?? 0.0;
        Decimal amount = opp?.Amount ?? 0.0;
        return amount * discountPercent / 100;
    }
}
```

### Real-World Examples

```apex
/**
 * @description Real-world use cases combining operators
 */
public class RealWorldExamples {

    // Use Case 1: Display logic for UI
    public static String getDisplayName(Account account) {
        return account?.Name ?? account?.External_Id__c ?? 'Account-' + account?.Id;
    }

    // Use Case 2: Validation with defaults
    public static Boolean isValidForProcessing(Order__c order) {
        Decimal amount = order?.Amount__c ?? 0;
        String status = order?.Status__c ?? 'Draft';
        String accountName = order?.Account__r?.Name ?? '';

        return amount > 0
            && status == 'Approved'
            && String.isNotBlank(accountName);
    }

    // Use Case 3: Calculations with nulls
    public static Decimal calculateTotal(Opportunity opp) {
        Decimal baseAmount = opp?.Amount ?? 0;
        Decimal taxRate = opp?.Tax_Rate__c ?? 0.08; // Default 8%
        Decimal discount = opp?.Discount_Amount__c ?? 0;

        return (baseAmount - discount) * (1 + taxRate);
    }

    // Use Case 4: Integration payload
    public static Map<String, Object> buildPayload(Account account) {
        return new Map<String, Object>{
            'accountName' => account?.Name ?? 'Unknown',
            'industry' => account?.Industry ?? 'Other',
            'revenue' => account?.AnnualRevenue ?? 0,
            'ownerEmail' => account?.Owner?.Email ?? 'unassigned@company.com',
            'website' => account?.Website ?? '',
            'phone' => account?.Phone ?? ''
        };
    }

    // Use Case 5: Logging with safe access
    public static void logAccountUpdate(Account account, Account oldAccount) {
        String message = String.format(
            'Account {0} updated. Name: {1} -> {2}, Industry: {3} -> {4}',
            new List<String>{
                account?.Id ?? 'Unknown',
                oldAccount?.Name ?? 'N/A',
                account?.Name ?? 'N/A',
                oldAccount?.Industry ?? 'N/A',
                account?.Industry ?? 'N/A'
            }
        );
        System.debug(message);
    }
}
```

---

## Performance Considerations

### CPU Impact

```apex
// ✅ NEGLIGIBLE: Modern operators have minimal CPU overhead
String name = account?.Owner?.Name ?? 'Unknown';
// CPU impact: ~0.01ms (same as manual null checks)

// Manual equivalent has same performance
String name;
if (account != null && account.Owner != null && account.Owner.Name != null) {
    name = account.Owner.Name;
} else {
    name = 'Unknown';
}
// CPU impact: ~0.01ms
```

### Bulk Operations

```apex
/**
 * @description Modern operators in bulk processing
 */
public static void updateAccountNames(List<Account> accounts) {
    for (Account acc : accounts) {
        // Efficient in bulk - no additional overhead
        acc.Display_Name__c = acc?.Name ?? acc?.External_Id__c ?? 'Account-' + acc.Id;
    }
    update accounts;
}

// Performance: Same as manual null checks
// 200 records: ~10ms total
```

---

## Migration Patterns

### From Manual Null Checks

```apex
// BEFORE: Manual null check pyramid
public static String getContactInfo(Contact con) {
    if (con != null) {
        if (con.Account != null) {
            if (con.Account.Owner != null) {
                if (con.Account.Owner.Email != null) {
                    return con.Account.Owner.Email;
                }
            }
        }
    }
    return 'no-email@company.com';
}

// AFTER: Safe navigation + null coalescing
public static String getContactInfo(Contact con) {
    return con?.Account?.Owner?.Email ?? 'no-email@company.com';
}
```

### From Ternary Operators

```apex
// BEFORE: Nested ternary
String displayName = account.Name != null ? account.Name :
                    (account.Nickname__c != null ? account.Nickname__c :
                    (account.External_Id__c != null ? account.External_Id__c : 'Unknown'));

// AFTER: Null coalescing
String displayName = account.Name ?? account.Nickname__c ?? account.External_Id__c ?? 'Unknown';
```

### From Try-Catch Null Handling

```apex
// BEFORE: Try-catch for null safety (anti-pattern!)
String ownerName;
try {
    ownerName = account.Owner.Name;
} catch (NullPointerException e) {
    ownerName = 'Unknown';
}

// AFTER: Safe navigation
String ownerName = account?.Owner?.Name ?? 'Unknown';
```

---

## Testing Modern Operators

```apex
@isTest
private class ModernOperatorsTest {

    @isTest
    static void testSafeNavigationWithNull() {
        // Given: Account with null Owner
        Account acc = new Account(Name = 'Test Account');

        // When: Access Owner.Name safely
        String ownerName = acc?.Owner?.Name;

        // Then: Returns null (no exception)
        System.assertEquals(null, ownerName);
    }

    @isTest
    static void testSafeNavigationWithValue() {
        // Given: Account with Owner
        User owner = [SELECT Id, Name FROM User LIMIT 1];
        Account acc = new Account(Name = 'Test Account', OwnerId = owner.Id);
        insert acc;
        acc = [SELECT Id, Owner.Name FROM Account WHERE Id = :acc.Id];

        // When: Access Owner.Name safely
        String ownerName = acc?.Owner?.Name;

        // Then: Returns owner name
        System.assertEquals(owner.Name, ownerName);
    }

    @isTest
    static void testNullCoalescingDefault() {
        // Given: Account with null AnnualRevenue
        Account acc = new Account(Name = 'Test', AnnualRevenue = null);

        // When: Apply null coalescing
        Decimal revenue = acc.AnnualRevenue ?? 0;

        // Then: Returns default value
        System.assertEquals(0, revenue);
    }

    @isTest
    static void testNullCoalescingValue() {
        // Given: Account with AnnualRevenue
        Account acc = new Account(Name = 'Test', AnnualRevenue = 100000);

        // When: Apply null coalescing
        Decimal revenue = acc.AnnualRevenue ?? 0;

        // Then: Returns actual value
        System.assertEquals(100000, revenue);
    }

    @isTest
    static void testCombinedOperators() {
        // Given: Account with null Owner
        Account acc = new Account(Name = 'Test Account');

        // When: Combine both operators
        String ownerName = acc?.Owner?.Name ?? 'Unassigned';

        // Then: Returns default value
        System.assertEquals('Unassigned', ownerName);
    }

    @isTest
    static void testBulkProcessing() {
        // Given: 200 accounts with various null states
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = i < 100 ? 'Account ' + i : null,
                Industry = i < 50 ? 'Technology' : null
            ));
        }

        // When: Apply modern operators in bulk
        Test.startTest();
        for (Account acc : accounts) {
            acc.Display_Name__c = acc?.Name ?? 'Unnamed-' + acc.Id;
            acc.Industry = acc.Industry ?? 'Other';
        }
        Test.stopTest();

        // Then: All records processed successfully
        for (Account acc : accounts) {
            System.assertNotEquals(null, acc.Display_Name__c);
            System.assertNotEquals(null, acc.Industry);
        }
    }
}
```

---

## Common Pitfalls

### 1. Boolean Evaluation

```apex
// ⚠️ CAREFUL: Safe navigation returns null, not false
Boolean isActive = account?.Is_Active__c;
if (isActive) { // NPE if isActive is null!
    // Do something
}

// ✅ CORRECT: Combine with null coalescing
Boolean isActive = account?.Is_Active__c ?? false;
if (isActive) {
    // Safe
}
```

### 2. Numeric Zero vs Null

```apex
// ⚠️ CAREFUL: Zero is different from null
Decimal amount = 0;
Decimal result = amount ?? 100; // Returns 0, not 100!

// ✅ CORRECT: Check for null explicitly
Decimal amount = null;
Decimal result = amount ?? 100; // Returns 100
```

### 3. Empty String vs Null

```apex
// ⚠️ CAREFUL: Empty string is not null
String name = '';
String display = name ?? 'Unknown'; // Returns '', not 'Unknown'

// ✅ CORRECT: Use String.isBlank() for empty strings
String display = String.isBlank(name) ? 'Unknown' : name;
```

---

## Best Practices

### 1. Prefer Modern Operators for Readability

```apex
// ✅ GOOD: Readable and concise
String email = contact?.Account?.Owner?.Email ?? 'no-email@company.com';

// ❌ VERBOSE: Hard to read
String email;
if (contact != null && contact.Account != null &&
    contact.Account.Owner != null && contact.Account.Owner.Email != null) {
    email = contact.Account.Owner.Email;
} else {
    email = 'no-email@company.com';
}
```

### 2. Use for Optional Fields

```apex
// ✅ GOOD: Optional fields with defaults
public class OrderService {
    public static Decimal calculateTotal(Order__c order) {
        Decimal subtotal = order?.Subtotal__c ?? 0;
        Decimal tax = order?.Tax__c ?? 0;
        Decimal shipping = order?.Shipping__c ?? 0;
        return subtotal + tax + shipping;
    }
}
```

### 3. Chain Carefully

```apex
// ✅ GOOD: Reasonable chain depth
String managerName = employee?.Manager?.Name ?? 'No Manager';

// ⚠️ CAREFUL: Very deep chains reduce readability
String name = record?.Parent?.Parent?.Parent?.Parent?.Owner?.Name ?? 'Unknown';
// Consider breaking into multiple statements
```

---

## Quick Reference

### Safe Navigation Syntax
```apex
// Property access
String name = account?.Name;

// Nested properties
String ownerName = account?.Owner?.Name;

// Method call
String formatted = contact?.getFormattedPhone();

// Collection access
String firstName = account?.Contacts?.isEmpty() == false
    ? account.Contacts[0]?.Name
    : null;
```

### Null Coalescing Syntax
```apex
// Single default
String name = account.Name ?? 'Unknown';

// Multiple fallbacks
String contact = email ?? phone ?? address ?? 'None';

// With safe navigation
String owner = account?.Owner?.Name ?? 'Unassigned';
```

### Combined Pattern
```apex
// Safe navigation + null coalescing + default
String display = record?.Parent?.Name ?? record?.External_Id__c ?? 'Unknown';
```

---

## Resources

- [Safe Navigation Operator Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_expressions_safe_navigation.htm)
- [Null Coalescing Operator Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_expressions_null_coalescing.htm)
- [Apex Language Reference](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/)
