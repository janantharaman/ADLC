---
alwaysApply: true
---

# Salesforce Naming Conventions

Consistent naming conventions improve code readability, maintainability, and team collaboration. These standards apply to ALL Salesforce development.

## Custom Objects

### Format
- **PascalCase** (capitalize first letter of each word)
- **Descriptive and business-focused** (reflect business terminology)
- **Singular form** (e.g., `Account`, not `Accounts`)
- **API Name**: Automatically appends `__c` suffix

### Examples
```
Invoice__c
Payment_Transaction__c
Product_Catalog__c
Shipping_Address__c
Service_Request__c
```

### Best Practices
- Use underscores to separate multi-word names
- Avoid abbreviations unless widely understood
- Keep names under 40 characters
- Prefix with namespace for managed packages

## Custom Fields

### Format
- **PascalCase** with underscores
- **Descriptive and specific**
- **API Name**: Automatically appends `__c` suffix

### Field Type Conventions
```
Text Fields:          Customer_Name__c, Email_Address__c
Number Fields:        Credit_Limit__c, Quantity__c
Currency Fields:      Total_Amount__c, Unit_Price__c
Date Fields:          Due_Date__c, Effective_Start_Date__c
Checkbox Fields:      Is_Active__c, Has_Discount__c (Boolean prefixes: Is_, Has_, Can_)
Picklists:           Status__c, Category__c, Priority__c
Lookup/MD:           Account__c, Contact__c, Parent_Invoice__c
```

### Boolean Field Prefixes
Use consistent prefixes for checkbox fields:
- `Is_`: State (e.g., `Is_Active__c`, `Is_Verified__c`)
- `Has_`: Possession (e.g., `Has_Discount__c`, `Has_Children__c`)
- `Can_`: Permission (e.g., `Can_Edit__c`, `Can_Approve__c`)
- `Should_`: Recommendation (e.g., `Should_Send_Email__c`)

### Examples
```
// Good
Account_Manager__c
Total_Contract_Value__c
Is_VIP_Customer__c
Has_Active_Subscription__c
Renewal_Date__c

// Avoid
Acct_Mgr__c          // Unclear abbreviation
TCV__c               // Acronym without context
VIPCust__c           // No underscores, hard to read
active__c            // Not descriptive enough
```

## Apex Classes

### Class Types and Naming

#### Controllers (LWC/Aura)
```apex
// Format: [ObjectName]Controller
AccountController.cls
InvoiceListController.cls
PaymentProcessingController.cls
```

#### Trigger Handlers
```apex
// Format: [ObjectName]TriggerHandler
AccountTriggerHandler.cls
OpportunityTriggerHandler.cls
InvoiceTriggerHandler.cls
```

#### Service Classes (Business Logic)
```apex
// Format: [ObjectName]Service
AccountService.cls
OpportunityService.cls
InvoiceService.cls
PaymentService.cls
```

#### Selector Classes (SOQL Queries)
```apex
// Format: [ObjectName]Selector
AccountSelector.cls
OpportunitySelector.cls
InvoiceSelector.cls
```

#### Utility Classes
```apex
// Format: [Purpose]Utility or [Purpose]Helper
DateUtility.cls
StringHelper.cls
ValidationUtility.cls
EmailHelper.cls
```

#### Batch Classes
```apex
// Format: [Purpose]Batch
AccountUpdateBatch.cls
InvoiceGenerationBatch.cls
DataCleanupBatch.cls
```

#### Queueable Classes
```apex
// Format: [Purpose]Queueable
PaymentProcessingQueueable.cls
EmailNotificationQueueable.cls
ExternalSystemSyncQueueable.cls
```

#### Schedulable Classes
```apex
// Format: [Purpose]Scheduler or [Purpose]Schedule
InvoiceGenerationScheduler.cls
DataBackupSchedule.cls
```

#### Test Classes
```apex
// Format: [ClassName]Test
AccountService.cls → AccountServiceTest.cls
OpportunityTriggerHandler.cls → OpportunityTriggerHandlerTest.cls
```

#### REST API Classes
```apex
// Format: [Resource]RestService or [Resource]API
@RestResource(urlMapping='/invoices/*')
global class InvoiceRestService { }

@RestResource(urlMapping='/payments/*')
global class PaymentAPI { }
```

#### Exception Classes
```apex
// Format: [Purpose]Exception
ValidationException.cls
IntegrationException.cls
PaymentProcessingException.cls
```

### Class Naming Best Practices
- **PascalCase** (no underscores)
- Suffix indicates purpose (Controller, Service, Handler, etc.)
- Maximum 40 characters
- Descriptive and unambiguous

## Triggers

### Format
```apex
// Format: [ObjectName]Trigger
// ONE trigger per object
AccountTrigger.trigger
OpportunityTrigger.trigger
InvoiceTrigger.trigger
```

### Best Practice
- **One trigger per object** (Salesforce doesn't guarantee execution order for multiple triggers)
- Delegate all logic to handler class
- Keep trigger itself to 3-5 lines maximum

```apex
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    new AccountTriggerHandler().run();
}
```

## Lightning Web Components (LWC)

### Component Naming
- **camelCase** for folder/file names
- **kebab-case** in HTML
- Descriptive and component-focused

### File Structure
```
lwc/
├── accountList/
│   ├── accountList.js        // camelCase
│   ├── accountList.html       // camelCase
│   ├── accountList.css        // camelCase
│   └── accountList.js-meta.xml
├── invoiceDetail/
│   ├── invoiceDetail.js
│   ├── invoiceDetail.html
│   └── invoiceDetail.js-meta.xml
```

### HTML Usage
```html
<!-- Use kebab-case in HTML -->
<c-account-list></c-account-list>
<c-invoice-detail record-id={invoiceId}></c-invoice-detail>
```

### Component Types
```
// List components
accountList, contactList, invoiceList

// Detail components
accountDetail, contactDetail, invoiceDetail

// Form components
accountForm, contactForm, invoiceForm

// Card components
accountCard, revenueCard, metricCard

// Utility components
errorPanel, spinner, toast
```

## Variables and Properties

### Apex Variables
```apex
// camelCase for local variables and properties
String accountName;
Integer recordCount;
List<Account> activeAccounts;
Map<Id, Contact> contactMap;
Set<Id> accountIds;

// Constants: UPPER_CASE with underscores
public static final String DEFAULT_STATUS = 'Active';
public static final Integer MAX_RECORDS = 200;
public static final Decimal TAX_RATE = 0.08;
```

### JavaScript Variables (LWC)
```javascript
// camelCase for variables and properties
let accountName;
let recordCount;
const activeAccounts = [];
const contactMap = new Map();

// Constants: UPPER_CASE with underscores
const MAX_RECORDS = 200;
const DEFAULT_STATUS = 'Active';
const API_ENDPOINT = '/services/data/v60.0';
```

### Apex Properties
```apex
// Public properties: camelCase
public String accountName { get; set; }
public List<Account> accounts { get; set; }

// Private properties: camelCase
private Integer recordCount;
private Map<Id, Contact> contactsByAccountId;
```

### LWC Properties
```javascript
// @api properties (public): camelCase
@api recordId;
@api accountName;
@api isActive;

// @track properties (reactive): camelCase
@track accounts = [];
@track isLoading = false;

// Private properties: camelCase
selectedAccountId;
errorMessage;
```

## Methods and Functions

### Apex Methods
```apex
// camelCase for method names
public void processAccounts() { }
public List<Account> getActiveAccounts() { }
private void validateData() { }
public static void updateRelatedRecords() { }

// Boolean methods: use is/has/can prefix
public Boolean isActive() { }
public Boolean hasErrors() { }
private Boolean canProcess() { }
```

### JavaScript Functions (LWC)
```javascript
// camelCase for function names
handleClick() { }
loadAccounts() { }
validateInput() { }
calculateTotal() { }

// Boolean functions: use is/has/can prefix
isValid() { }
hasErrors() { }
canSubmit() { }

// Event handlers: use handle prefix
handleSave() { }
handleCancel() { }
handleInputChange() { }
```

## Flows

### Flow Naming
- **PascalCase** with underscores
- Descriptive and action-oriented
- Include trigger type if relevant

```
Create_Invoice_Record
Update_Contact_Email
Screen_Flow_New_Customer_Onboarding
Record_Triggered_Account_Update
Scheduled_Flow_Daily_Data_Sync
```

### Flow Types
```
Screen Flow:              Screen_Flow_[Purpose]
Record-Triggered Flow:    Record_Triggered_[Object]_[Action]
Scheduled Flow:           Scheduled_Flow_[Purpose]
Autolaunched Flow:        Autolaunched_[Purpose]
```

### Flow Variables
- **PascalCase**
- Descriptive names

```
varAccountId
varContactEmail
varTotalAmount
varIsActive
colAccounts (collection)
```

## Process Builder / Workflows (Legacy)

### Process Names
```
PascalCase with underscores
Account_Update_Process
Opportunity_Stage_Change_Process
Case_Escalation_Process
```

### Workflow Rules
```
PascalCase with underscores
New_Lead_Assignment
Case_Auto_Response
Opportunity_Follow_Up
```

## Validation Rules

### Format
- **PascalCase** with underscores
- Descriptive of what is being validated

```
Account_Name_Required
Email_Format_Validation
Amount_Must_Be_Positive
Start_Date_Before_End_Date
Discount_Within_Range
```

## Custom Labels

### Format
- **PascalCase** with underscores
- Grouped by feature/object

```
Error_Message_Required_Field
Button_Label_Save
Header_Text_Account_Details
Validation_Message_Invalid_Email
Success_Message_Record_Created
```

## Custom Metadata Types

### Format
- **PascalCase**
- Suffix with `__mdt`
- Descriptive of configuration purpose

```
Integration_Configuration__mdt
Approval_Settings__mdt
Email_Template_Config__mdt
Tax_Rate_Configuration__mdt
```

## Permission Sets

### Format
- **PascalCase** with underscores
- Descriptive of access granted
- Group by role or feature

```
Account_Manager_Access
Invoice_Admin_Full_Access
Read_Only_Dashboard_Access
Custom_Object_Editor
API_Integration_User
```

## Profiles

### Format
- **Title Case** with spaces (Salesforce standard)
- Descriptive of user role

```
Sales Representative
Account Manager
System Administrator
Customer Community User
Integration API User
```

## Quick Reference Table

| Type | Convention | Example |
|------|------------|---------|
| Custom Object | PascalCase + `__c` | `Invoice__c` |
| Custom Field | PascalCase + `__c` | `Total_Amount__c` |
| Apex Class | PascalCase + Type | `AccountService.cls` |
| Trigger | PascalCase + Trigger | `AccountTrigger.trigger` |
| LWC Component | camelCase | `accountList/` |
| Apex Variable | camelCase | `accountName` |
| Apex Constant | UPPER_CASE | `MAX_RECORDS` |
| Apex Method | camelCase | `processAccounts()` |
| JS Function | camelCase | `handleClick()` |
| Flow | PascalCase_Underscores | `Create_Invoice_Record` |
| Validation Rule | PascalCase_Underscores | `Amount_Must_Be_Positive` |
| Custom Label | PascalCase_Underscores | `Error_Message_Required_Field` |
| Permission Set | PascalCase_Underscores | `Invoice_Admin_Access` |

## Code Comments

### Apex Comments
```apex
/**
 * Service class for Account business logic
 * Handles account creation, updates, and related operations
 */
public class AccountService {

    /**
     * Creates new accounts with default values
     * @param accountNames List of account names to create
     * @return List of created Account records
     */
    public static List<Account> createAccounts(List<String> accountNames) {
        // Validate input
        if (accountNames == null || accountNames.isEmpty()) {
            throw new IllegalArgumentException('Account names cannot be empty');
        }

        // Create accounts
        List<Account> accounts = new List<Account>();
        for (String name : accountNames) {
            accounts.add(new Account(Name = name, Rating = 'Warm'));
        }

        return accounts;
    }
}
```

### JavaScript Comments (LWC)
```javascript
/**
 * Account list component
 * Displays a searchable list of accounts with pagination
 */
export default class AccountList extends LightningElement {

    /**
     * Handles search input changes
     * @param {Event} event - Input change event
     */
    handleSearchChange(event) {
        // Debounce search to avoid excessive queries
        const searchTerm = event.target.value;
        // ... implementation
    }
}
```

## Best Practices Summary

1. **Be Consistent**: Follow these conventions across the entire codebase
2. **Be Descriptive**: Names should clearly indicate purpose
3. **Avoid Abbreviations**: Unless widely understood (e.g., ID, URL, API)
4. **Use Prefixes/Suffixes**: Indicate type (Controller, Service, Handler, Test)
5. **Keep It Short**: Under 40 characters when possible
6. **Use Business Terms**: Align with business vocabulary
7. **Test Class Names**: Match the class being tested with `Test` suffix
8. **One Trigger Per Object**: Use handler pattern for logic
9. **Boolean Prefixes**: Use `is`, `has`, `can` for clarity

## When This Rule Applies

This naming convention rule is **ALWAYS ACTIVE** for:
- All custom object and field creation
- All Apex class development
- All Lightning Web Component development
- All Flow creation
- All validation rule creation
- All permission set creation
- All code reviews

**Remember**: Consistent naming makes code self-documenting and easier for teams to collaborate.
