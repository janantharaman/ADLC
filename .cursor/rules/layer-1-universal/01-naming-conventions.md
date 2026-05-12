---
name: Naming Conventions
layer: 1
type: universal-foundation
composable: true
requires: []
alwaysApply: true
tags: [naming, conventions, apex, lwc, readability]
---

# Naming Conventions (Layer 1 - Universal Foundation)

Consistent naming is critical for readability, maintainability, and collaboration. These conventions apply to ALL Salesforce development work.

## Core Principles

1. **Descriptive Names**: Names should clearly describe what they represent
2. **Avoid Abbreviations**: Use full words unless abbreviation is universally understood (e.g., `Id`, `URL`, `API`)
3. **Be Consistent**: Follow patterns religiously
4. **Length Balance**: Long enough to be clear, short enough to be practical

---

## Apex Classes

### Class Names

**Format**: **PascalCase** (capitalize first letter of each word, no underscores)

**Examples**:
- `AccountTriggerHandler`
- `OrderService`
- `ProductController`
- `EmailNotificationBatch`
- `InventoryUpdateQueueable`

### Class Suffixes (Pattern-Based)

Use suffixes to indicate class purpose:

**Controllers** (handle UI logic):
- REST Controllers: `AccountRestController`, `OrderApiController`
- Lightning Controllers: `AccountListController`, `ProductSearchController`
- Visualforce Controllers: `AccountPageController`

**Services** (business logic layer):
- `InventoryService`, `NotificationService`, `OrderProcessingService`

**Trigger Handlers** (delegate trigger logic):
- `AccountTriggerHandler`, `OpportunityTriggerHandler`, `OrderTriggerHandler`

**Batch Classes** (implement `Database.Batchable`):
- `DailyInventoryUpdateBatch`, `MonthlyReportGenerationBatch`, `DataCleanupBatch`

**Queueable Classes** (implement `Queueable`):
- `OrderProcessingQueueable`, `EmailSendingQueueable`, `ApiCalloutQueueable`

**Schedulable Classes** (implement `Schedulable`):
- `DailyDataCleanupSchedule`, `WeeklyReportSchedule`

**Test Classes**:
- `AccountTriggerHandler_Test`, `OrderService_Test`, `ProductController_Test`
- Alternative: `AccountTriggerHandlerTest`, `OrderServiceTest`

**Utility Classes** (helper methods):
- `DateUtils`, `StringUtils`, `ValidationUtils`

**Selector Classes** (SOQL queries):
- `AccountSelector`, `OpportunitySelector`, `ContactSelector`

### Examples

```apex
// ✅ GOOD
public class AccountTriggerHandler {
    // Handler logic
}

public class OrderProcessingService {
    // Business logic
}

public class DailyInventoryUpdateBatch implements Database.Batchable<SObject> {
    // Batch logic
}

// ❌ BAD
public class accounthandler { // Wrong: lowercase
}

public class AcctHandler { // Avoid: abbreviation not universally understood
}

public class Account { // Avoid: conflicts with standard object
}
```

---

## Apex Methods

### Method Names

**Format**: **camelCase** (lowercase first letter, capitalize subsequent words)

**Start with Verb**: Methods perform actions, so start with action verbs

**Common Verbs**:
- `get` - Retrieve data: `getAccountById()`, `getActiveOrders()`
- `set` - Set a value: `setAccountName()`, `setIsActive()`
- `is` / `has` / `should` - Boolean methods: `isActive()`, `hasPermission()`, `shouldProcess()`
- `calculate` - Perform calculation: `calculateDiscount()`, `calculateTotalAmount()`
- `process` - Execute business logic: `processOrders()`, `processPayment()`
- `send` - Send notifications: `sendEmail()`, `sendNotification()`
- `create` - Create records: `createAccount()`, `createOpportunities()`
- `update` - Update records: `updateAccountStatus()`, `updateInventory()`
- `delete` - Delete records: `deleteInactiveAccounts()`
- `validate` - Validation logic: `validateInput()`, `validateBusinessRules()`

### Boolean Method Prefixes

**Use**: `is`, `has`, `should`, `can`

```apex
// ✅ GOOD: Boolean methods with clear prefixes
public static Boolean isActive(Account acc) {
    return acc.Active__c == true;
}

public static Boolean hasPermission(User u, String permissionName) {
    // Check permission
}

public static Boolean shouldProcessOrder(Order__c order) {
    return order.Status__c == 'Pending' && order.Amount__c > 0;
}

public static Boolean canApproveOrder(User u, Order__c order) {
    // Authorization check
}

// ❌ BAD: Unclear boolean method names
public static Boolean active(Account acc) { // Missing prefix
}

public static Boolean checkPermission(User u) { // Verb doesn't indicate boolean return
}
```

### Examples

```apex
// ✅ GOOD
public static List<Account> getAccountsByIndustry(String industry) {
    return [SELECT Id, Name FROM Account WHERE Industry = :industry];
}

public static void processOrders(List<Order__c> orders) {
    // Processing logic
}

public static Decimal calculateDiscount(Decimal amount, Decimal percentage) {
    return amount * (percentage / 100);
}

public static Boolean isEligibleForDiscount(Account acc) {
    return acc.AnnualRevenue > 1000000;
}

// ❌ BAD
public static List<Account> accounts(String industry) { // Not a verb
}

public static void process(List<Order__c> orders) { // Too generic
}

public static Decimal calc(Decimal amount, Decimal percentage) { // Abbreviation
}
```

---

## Apex Variables

### Variable Names

**Format**: **camelCase**

**Descriptive**: Variable name should describe what it holds

```apex
// ✅ GOOD
String accountName = 'Acme Corporation';
Integer orderCount = 100;
Boolean isActive = true;
Decimal totalAmount = 1500.50;
Date startDate = Date.today();
List<Account> accounts = new List<Account>();
Map<Id, Contact> contactMap = new Map<Id, Contact>();

// ❌ BAD
String an = 'Acme'; // Too abbreviated
Integer x = 100; // Not descriptive
Boolean flag = true; // What does "flag" mean?
List<Account> accountList = new List<Account>(); // "List" suffix redundant (variable type already says it's a List)
```

### Collection Variables

**Pluralize Collection Names**:

```apex
// ✅ GOOD: Plural names for collections
List<Account> accounts = new List<Account>();
Set<Id> accountIds = new Set<Id>();
Map<Id, Contact> contactsById = new Map<Id, Contact>();

// ❌ BAD: Singular names for collections
List<Account> account = new List<Account>(); // Confusing!
Set<Id> accountId = new Set<Id>(); // Confusing!
```

### Constants

**Format**: **ALL_CAPS with underscores**

```apex
// ✅ GOOD: Constants
public static final Integer MAX_RETRY_COUNT = 3;
public static final String DEFAULT_COUNTRY = 'USA';
public static final Decimal DEFAULT_DISCOUNT_PERCENTAGE = 10.0;
public static final Integer DEFAULT_PAGE_SIZE = 50;

// ❌ BAD
public static final Integer maxRetryCount = 3; // Should be ALL_CAPS
public static final String default_country = 'USA'; // Should be ALL_CAPS
```

### Loop Variables

**Short names acceptable for simple loops**:

```apex
// ✅ GOOD: Short variable in simple loop
for (Integer i = 0; i < 10; i++) {
    // Simple iteration
}

// ✅ GOOD: Descriptive variable in complex loop
for (Account acc : accounts) {
    // Complex logic with account
}

// ✅ GOOD: Index with descriptive collection
for (Integer i = 0; i < accounts.size(); i++) {
    Account currentAccount = accounts[i];
    // Use currentAccount
}
```

---

## Apex Triggers

### Trigger Names

**Format**: `ObjectNameTrigger` (PascalCase, suffix with `Trigger`)

**One trigger per object**: Consolidate all events into a single trigger

```apex
// ✅ GOOD: One trigger per object
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    AccountTriggerHandler.handle();
}

trigger OpportunityTrigger on Opportunity (after insert, after update) {
    OpportunityTriggerHandler.handle();
}

trigger OrderTrigger on Order__c (before insert, after insert, before update, after update) {
    OrderTriggerHandler.handle();
}

// ❌ BAD: Multiple triggers per object (avoid!)
trigger AccountBeforeInsert on Account (before insert) {
    // Logic
}

trigger AccountAfterInsert on Account (after insert) {
    // Logic
}
// Problem: Hard to manage, can cause recursion issues, execution order unclear
```

---

## Lightning Web Components (LWC)

### Component Names

**Folder Name**: **camelCase** (lowercase first letter)
**File Names**: Match folder name exactly
**JavaScript Class**: **PascalCase** (capitalize first letter)

```
// ✅ GOOD: LWC structure
/lwc
  /accountList
    accountList.js        // JavaScript file
    accountList.html      // HTML template
    accountList.css       // Styles
    accountList.js-meta.xml  // Metadata

// accountList.js
import { LightningElement } from 'lwc';
export default class AccountList extends LightningElement {
    // Component logic (class name is PascalCase)
}
```

**Component Name Examples**:
- `accountList` (folder) → `AccountList` (class)
- `orderForm` (folder) → `OrderForm` (class)
- `customDataTable` (folder) → `CustomDataTable` (class)
- `productCard` (folder) → `ProductCard` (class)

### JavaScript Properties

**Format**: **camelCase**

```javascript
// ✅ GOOD
import { LightningElement, api, track } from 'lwc';

export default class AccountList extends LightningElement {
    @api recordId;              // Public property (camelCase)
    @track selectedItems = [];  // Tracked property
    isLoading = false;          // Private property
    errorMessage;

    // Private properties with underscore prefix (convention)
    _cachedData;
    _internalCounter = 0;
}

// ❌ BAD
@api RecordId;           // Should be camelCase
@track selected_items;   // Should be camelCase
```

### HTML Attributes

**Format**: **kebab-case** (lowercase with hyphens)

```html
<!-- ✅ GOOD: HTML attributes -->
<template>
    <lightning-card title="Account List" icon-name="standard:account">
        <c-custom-component
            record-id={recordId}
            is-loading={isLoading}
            selected-items={selectedItems}
            onselect={handleSelect}>
        </c-custom-component>
    </lightning-card>
</template>

<!-- ❌ BAD -->
<c-custom-component
    recordId={recordId}         <!-- Should be kebab-case -->
    IsLoading={isLoading}       <!-- Should be kebab-case -->
    selected_items={selectedItems}>  <!-- Underscore not standard -->
</c-custom-component>
```

### Event Names

**Custom Events**: **camelCase** (without "on" prefix in name, but with "on" prefix when listening)

```javascript
// ✅ GOOD: Dispatch custom event
this.dispatchEvent(new CustomEvent('select', {
    detail: { recordId: this.recordId }
}));

// ✅ GOOD: Listen to custom event (use "on" prefix)
<c-account-list onselect={handleSelect}></c-account-list>
```

---

## Database Objects

### Custom Objects

**Format**: **PascalCase with underscores**, suffix `__c`

```
// ✅ GOOD
Custom_Product__c
Order_Line_Item__c
Discount_Rule__c
Customer_Preference__c

// ❌ BAD
customproduct__c           // Not PascalCase
Custom-Product__c          // Use underscores, not hyphens
CustomProduct__c           // Missing word separators
```

### Custom Fields

**Format**: **PascalCase with underscores**, suffix `__c`

```
// ✅ GOOD
Discount_Amount__c
Total_Price__c
External_Id__c
Is_Active__c
Created_By_External_System__c

// ❌ BAD
discountAmount__c          // Not PascalCase
Discount-Amount__c         // Use underscores, not hyphens
DiscountAmt__c             // Avoid abbreviations
```

### External Objects

**Format**: Same as custom objects, suffix `__x`

```
// ✅ GOOD
External_Product__x
SAP_Order__x
```

### Custom Metadata Types

**Format**: Same as custom objects, suffix `__mdt`

```
// ✅ GOOD
Integration_Setting__mdt
Feature_Flag__mdt
Business_Rule__mdt
```

### Custom Settings

**Format**: Same as custom objects, suffix `__c`

```
// ✅ GOOD
Application_Config__c      // Hierarchy custom setting
API_Endpoint__c           // List custom setting
```

### Platform Events

**Format**: Same as custom objects, suffix `__e`

```
// ✅ GOOD
Order_Event__e
Notification_Event__e
Integration_Event__e
```

---

## API Names and Labels

### Labels vs API Names

**Label**: User-facing name (can have spaces, special characters)
**API Name**: Internal name used in code (follows naming conventions above)

```
// ✅ GOOD: Separate label and API name
Label: "Total Amount"
API Name: Total_Amount__c

Label: "Is Active?"
API Name: Is_Active__c

Label: "Customer Preference"
API Name: Customer_Preference__c
```

---

## Comments and Documentation

### Inline Comments

**Purpose**: Explain WHY, not WHAT

```apex
// ✅ GOOD: Explains why
// Query with LIMIT to avoid heap size issues with large orgs (500K+ accounts)
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1000];

// Bypass sharing rules because this is a nightly admin job
public without sharing class DataCleanupBatch implements Database.Batchable<SObject> {
    // ...
}

// ❌ BAD: States the obvious
// Query accounts
List<Account> accounts = [SELECT Id, Name FROM Account];

// Loop through accounts
for (Account acc : accounts) {
    // ...
}
```

### Class and Method Headers

**Format**: ApexDoc style (like Javadoc)

```apex
/**
 * @description Handles Account trigger logic following the handler pattern.
 * Enforces business rules and maintains data integrity.
 * @author Jane Doe
 * @date 2025-01-15
 */
public class AccountTriggerHandler {

    /**
     * @description Main entry point for trigger handler. Routes to appropriate methods
     * based on trigger context.
     */
    public static void handle() {
        if (Trigger.isBefore && Trigger.isInsert) {
            handleBeforeInsert(Trigger.new);
        }
        // ...
    }

    /**
     * @description Validates and enriches Account records before insert.
     * @param newAccounts List of new Account records from Trigger.new
     */
    private static void handleBeforeInsert(List<Account> newAccounts) {
        // Implementation
    }
}
```

---

## Naming Anti-Patterns (Avoid These!)

### 1. Abbreviations

```apex
// ❌ BAD
String acctName;           // Use "accountName"
Integer cnt;               // Use "count"
Boolean flg;               // Use "isActive" or describe what the flag means
List<Account> accs;        // Use "accounts"

// ✅ GOOD
String accountName;
Integer count;
Boolean isActive;
List<Account> accounts;
```

### 2. Generic Names

```apex
// ❌ BAD
void process();            // Process what?
void handle();             // Handle what?
Boolean check();           // Check what?
Integer value;             // Value of what?

// ✅ GOOD
void processOrders();
void handleAccountUpdate();
Boolean checkInventoryAvailability();
Integer discountPercentage;
```

### 3. Redundant Suffixes

```apex
// ❌ BAD
List<Account> accountList;           // Type already says "List"
Set<Id> accountIdSet;                // Type already says "Set"
Map<Id, Account> accountMap;         // Type already says "Map"

// ✅ GOOD
List<Account> accounts;
Set<Id> accountIds;
Map<Id, Account> accountsById;       // "ById" adds meaning (how the map is keyed)
```

### 4. Hungarian Notation (Type Prefixes)

```apex
// ❌ BAD
String strName;            // Type prefix unnecessary (Apex is strongly-typed)
Integer intCount;
Boolean bIsActive;

// ✅ GOOD
String name;
Integer count;
Boolean isActive;
```

---

## Quick Reference

| Element | Convention | Example |
|---------|------------|---------|
| **Apex Class** | PascalCase | `AccountTriggerHandler` |
| **Apex Method** | camelCase (verb-first) | `processOrders()`, `isActive()` |
| **Apex Variable** | camelCase | `accountName`, `totalAmount` |
| **Apex Constant** | ALL_CAPS | `MAX_RETRY_COUNT` |
| **Apex Trigger** | `ObjectNameTrigger` | `AccountTrigger` |
| **LWC Folder** | camelCase | `accountList` |
| **LWC Class** | PascalCase | `AccountList` |
| **LWC Property** | camelCase | `@api recordId` |
| **LWC HTML Attribute** | kebab-case | `record-id={recordId}` |
| **Custom Object** | PascalCase + `__c` | `Custom_Product__c` |
| **Custom Field** | PascalCase + `__c` | `Discount_Amount__c` |
| **Custom Metadata** | PascalCase + `__mdt` | `Integration_Setting__mdt` |
| **Platform Event** | PascalCase + `__e` | `Order_Event__e` |

---

## Consistency is KEY

**The most important rule**: Be consistent! Once you choose a pattern, stick to it throughout your codebase. Consistency makes code easier to read, maintain, and debug.

**Applies to**: All Salesforce developers (Apex, LWC, Integrations, Data, Admin)
