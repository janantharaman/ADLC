---
alwaysApply: true
---

# Lightning Web Components (LWC) Development Standards

Lightning Web Components are the modern standard for building UI on the Salesforce platform. These standards ensure high-quality, performant, and maintainable LWC development.

## When to Create Custom LWC

### ✅ Create Custom LWC When:
- Standard Lightning components don't meet requirements
- Complex custom business logic required
- Specialized UI/UX needs
- Custom data visualization (charts, maps, dashboards)
- Integration with third-party JavaScript libraries
- Reusable component across multiple pages
- Performance optimization needed (standard components too slow)

### ❌ Avoid Custom LWC When:
- Standard Lightning components available (use `lightning-*` base components)
- Simple field display/edit (use Lightning Record Page)
- Standard related lists sufficient (use standard components)
- Quick prototype/MVP (use App Builder first)
- No technical resources for maintenance

## LWC File Structure

### Basic Component Structure
```
lwc/
└── myComponent/
    ├── myComponent.html           // Template
    ├── myComponent.js             // JavaScript controller
    ├── myComponent.css            // Styles (optional)
    ├── myComponent.js-meta.xml    // Metadata config
    └── __tests__/                 // Jest tests (optional)
        └── myComponent.test.js
```

### Naming Conventions
- **Folder name**: camelCase (e.g., `accountList`, `invoiceDetail`)
- **File names**: Match folder name exactly
- **Component usage in HTML**: kebab-case (e.g., `<c-account-list>`, `<c-invoice-detail>`)
- **Class names**: PascalCase (e.g., `export default class AccountList extends LightningElement`)

## HTML Template Best Practices

### Use Lightning Base Components
```html
<!-- ✅ GOOD - Use base components -->
<template>
    <lightning-card title="Account List">
        <lightning-datatable
            key-field="id"
            data={accounts}
            columns={columns}>
        </lightning-datatable>
    </lightning-card>
</template>

<!-- ❌ AVOID - Don't reinvent the wheel -->
<template>
    <div class="custom-card">
        <table>
            <!-- Custom table implementation -->
        </table>
    </div>
</template>
```

### Conditional Rendering
```html
<!-- Use if:true and if:false -->
<template>
    <template if:true={isLoading}>
        <lightning-spinner alternative-text="Loading"></lightning-spinner>
    </template>

    <template if:true={hasData}>
        <lightning-datatable data={accounts}></lightning-datatable>
    </template>

    <template if:true={hasError}>
        <div class="slds-text-color_error">{errorMessage}</div>
    </template>
</template>
```

### Iterating Over Lists
```html
<!-- Use for:each or iterator:it -->
<template>
    <!-- for:each - Simple iteration -->
    <template for:each={accounts} for:item="account">
        <div key={account.Id}>
            <p>{account.Name}</p>
        </div>
    </template>

    <!-- iterator - When you need index -->
    <template iterator:it={accounts}>
        <div key={it.value.Id}>
            <p>{it.value.Name} (Position: {it.index})</p>
            <template if:true={it.first}>First item</template>
            <template if:true={it.last}>Last item</template>
        </div>
    </template>
</template>
```

### Event Handling
```html
<template>
    <!-- Use onclick, onchange, etc. -->
    <lightning-button
        label="Save"
        onclick={handleSave}>
    </lightning-button>

    <lightning-input
        label="Search"
        value={searchTerm}
        onchange={handleSearchChange}>
    </lightning-input>

    <!-- Custom events -->
    <c-child-component
        onselect={handleChildSelect}>
    </c-child-component>
</template>
```

## JavaScript Best Practices

### Variable Declarations
```javascript
// ✅ Use const for constants
const MAX_RECORDS = 100;
const DEFAULT_PAGE_SIZE = 25;

// ✅ Use let for variables that change
let currentPage = 1;
let searchTerm = '';

// ❌ NEVER use var (outdated, function-scoped)
var oldStyle = 'avoid this';
```

### Property Decorators

#### @api - Public Properties
```javascript
import { LightningElement, api } from 'lwc';

export default class AccountDetail extends LightningElement {
    // Public property - accessible from parent
    @api recordId;
    @api objectApiName;

    // Public method - callable from parent
    @api
    refresh() {
        this.loadAccount();
    }
}
```

#### @track - Reactive Private Properties (LEGACY)
```javascript
// ⚠️ @track is legacy - use regular properties instead
import { LightningElement } from 'lwc';

export default class AccountList extends LightningElement {
    // ✅ Modern way - automatic reactivity for primitives
    searchTerm = '';
    isLoading = false;

    // ✅ For objects/arrays, reassign to trigger reactivity
    accounts = [];

    addAccount(newAccount) {
        // Create new array to trigger reactivity
        this.accounts = [...this.accounts, newAccount];
    }
}
```

#### @wire - Retrieve Salesforce Data
```javascript
import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

export default class AccountList extends LightningElement {
    @api recordId;

    // Wire to UiRecordApi
    @wire(getRecord, { recordId: '$recordId', fields: ['Account.Name', 'Account.Industry'] })
    account;

    // Wire to Apex method
    @wire(getAccounts)
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }
}
```

### Function Definitions
```javascript
// ✅ Use arrow functions for methods
export default class AccountList extends LightningElement {
    accounts = [];

    // Arrow function - preserves 'this' context
    handleClick = () => {
        this.loadAccounts();
    }

    // Traditional method - also fine
    handleSave(event) {
        const accountId = event.target.dataset.id;
        this.saveAccount(accountId);
    }

    // Async function
    async loadAccounts() {
        try {
            this.isLoading = true;
            const result = await getAccounts();
            this.accounts = result;
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    // Helper function (private)
    handleError(error) {
        console.error('Error:', error);
        this.errorMessage = error.body?.message || 'Unknown error';
    }
}
```

### Getters for Computed Values
```javascript
export default class AccountList extends LightningElement {
    accounts = [];
    searchTerm = '';

    // Computed property using getter
    get filteredAccounts() {
        if (!this.searchTerm) {
            return this.accounts;
        }
        return this.accounts.filter(acc =>
            acc.Name.toLowerCase().includes(this.searchTerm.toLowerCase())
        );
    }

    // Boolean getter
    get hasAccounts() {
        return this.accounts && this.accounts.length > 0;
    }

    // Conditional class
    get containerClass() {
        return this.hasAccounts ? 'slds-m-around_medium' : 'slds-hide';
    }
}
```

## Data Access Patterns

### Pattern 1: Lightning Data Service (@wire)
```javascript
// ✅ Preferred for standard CRUD operations
import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Account.Name',
    'Account.Industry',
    'Account.AnnualRevenue'
];

export default class AccountDetail extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get accountName() {
        return this.account.data?.fields.Name.value;
    }
}
```

### Pattern 2: Apex Imperative Call
```javascript
// ✅ Use for complex queries, business logic
import { LightningElement } from 'lwc';
import getAccountsWithOpportunities from '@salesforce/apex/AccountController.getAccountsWithOpportunities';

export default class AccountList extends LightningElement {
    accounts = [];
    error;
    isLoading = false;

    async connectedCallback() {
        await this.loadAccounts();
    }

    async loadAccounts() {
        this.isLoading = true;
        try {
            this.accounts = await getAccountsWithOpportunities();
            this.error = undefined;
        } catch (error) {
            this.error = error;
            this.accounts = [];
        } finally {
            this.isLoading = false;
        }
    }
}
```

### Pattern 3: @wire Apex with Parameters
```javascript
import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

export default class AccountList extends LightningElement {
    searchTerm = '';
    pageSize = 25;

    @wire(getAccounts, { searchTerm: '$searchTerm', pageSize: '$pageSize' })
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data;
        } else if (error) {
            this.handleError(error);
        }
    }

    handleSearchChange(event) {
        // Updating searchTerm triggers @wire refresh
        this.searchTerm = event.target.value;
    }
}
```

## Caching and Performance

### Cache Apex Results
```javascript
// Server-side caching in Apex
public class AccountController {
    // Cache results with @AuraEnabled(cacheable=true)
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 100];
    }
}

// Client-side usage
import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

export default class AccountList extends LightningElement {
    // Cached data automatically by LWC framework
    @wire(getAccounts)
    accounts;
}
```

### Lazy Loading Components
```javascript
// Load components only when needed
export default class AccountDetail extends LightningElement {
    showAdvancedSection = false;

    toggleAdvanced() {
        // Advanced section only renders when toggled
        this.showAdvancedSection = !this.showAdvancedSection;
    }
}
```

```html
<template>
    <lightning-button label="Show Advanced" onclick={toggleAdvanced}></lightning-button>

    <template if:true={showAdvancedSection}>
        <!-- Heavy component loaded only when needed -->
        <c-advanced-analytics></c-advanced-analytics>
    </template>
</template>
```

### Debouncing User Input
```javascript
export default class SearchBar extends LightningElement {
    searchTerm = '';
    delayTimeout;

    handleSearchChange(event) {
        const searchTerm = event.target.value;

        // Clear previous timeout
        clearTimeout(this.delayTimeout);

        // Debounce: wait 300ms after user stops typing
        this.delayTimeout = setTimeout(() => {
            this.searchTerm = searchTerm;
            this.performSearch();
        }, 300);
    }

    performSearch() {
        // Execute search
    }
}
```

## Component Communication

### Parent to Child - Public Methods/Properties
```javascript
// Child component
export default class ChildComponent extends LightningElement {
    @api recordId;

    @api
    refresh() {
        // Public method callable from parent
        this.loadData();
    }
}

// Parent component
export default class ParentComponent extends LightningElement {
    handleRefresh() {
        // Call child's public method
        this.template.querySelector('c-child-component').refresh();
    }
}
```

### Child to Parent - Custom Events
```javascript
// Child component - Dispatch event
export default class ChildComponent extends LightningElement {
    handleSelect(event) {
        const selectedId = event.target.dataset.id;

        // Dispatch custom event
        this.dispatchEvent(new CustomEvent('select', {
            detail: { recordId: selectedId }
        }));
    }
}

// Parent component - Handle event
export default class ParentComponent extends LightningElement {
    handleChildSelect(event) {
        const recordId = event.detail.recordId;
        console.log('Selected:', recordId);
    }
}
```

```html
<!-- Parent template -->
<template>
    <c-child-component onselect={handleChildSelect}></c-child-component>
</template>
```

### Sibling Communication - Pub/Sub (Lightning Message Service)
```javascript
// Publisher component
import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import ACCOUNT_SELECTED from '@salesforce/messageChannel/AccountSelected__c';

export default class AccountList extends LightningElement {
    @wire(MessageContext)
    messageContext;

    handleAccountSelect(event) {
        const accountId = event.target.dataset.id;

        // Publish message
        publish(this.messageContext, ACCOUNT_SELECTED, {
            recordId: accountId
        });
    }
}

// Subscriber component
import { LightningElement, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import ACCOUNT_SELECTED from '@salesforce/messageChannel/AccountSelected__c';

export default class AccountDetail extends LightningElement {
    @wire(MessageContext)
    messageContext;

    subscription;

    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            ACCOUNT_SELECTED,
            (message) => this.handleAccountSelected(message)
        );
    }

    handleAccountSelected(message) {
        this.recordId = message.recordId;
        this.loadAccount();
    }
}
```

## Error Handling

### Apex Error Handling
```javascript
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveAccount from '@salesforce/apex/AccountController.saveAccount';

export default class AccountForm extends LightningElement {
    async handleSave() {
        try {
            await saveAccount({ accountData: this.accountData });
            this.showSuccessToast();
        } catch (error) {
            this.handleError(error);
        }
    }

    handleError(error) {
        let message = 'Unknown error';

        // Handle different error types
        if (error.body) {
            if (error.body.message) {
                message = error.body.message;
            } else if (error.body.fieldErrors) {
                // Field validation errors
                const fieldErrors = error.body.fieldErrors;
                message = Object.values(fieldErrors).flat().join(', ');
            } else if (error.body.pageErrors) {
                // Page-level errors
                message = error.body.pageErrors.map(e => e.message).join(', ');
            }
        } else if (error.message) {
            message = error.message;
        }

        this.showErrorToast(message);
    }

    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showSuccessToast() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Account saved successfully',
            variant: 'success'
        }));
    }
}
```

## Lifecycle Hooks

```javascript
export default class LifecycleExample extends LightningElement {
    // Constructor - Component created
    constructor() {
        super();
        // Don't access DOM here
        console.log('Constructor called');
    }

    // connectedCallback - Component inserted into DOM
    connectedCallback() {
        // Load initial data
        console.log('Component connected');
        this.loadData();
    }

    // renderedCallback - After every render
    renderedCallback() {
        // Access DOM elements, third-party library init
        console.log('Component rendered');
    }

    // disconnectedCallback - Component removed from DOM
    disconnectedCallback() {
        // Cleanup: unsubscribe, clear intervals
        console.log('Component disconnected');
    }

    // errorCallback - Error in component or child
    errorCallback(error, stack) {
        console.error('Error occurred:', error);
        console.error('Stack:', stack);
    }
}
```

## Styling Best Practices

### Use SLDS Classes
```html
<!-- ✅ Use Salesforce Lightning Design System -->
<template>
    <div class="slds-card slds-p-around_medium">
        <h1 class="slds-text-heading_medium slds-m-bottom_small">Account List</h1>
        <div class="slds-grid slds-gutters">
            <div class="slds-col slds-size_1-of-2">
                <!-- Content -->
            </div>
        </div>
    </div>
</template>
```

### Component-Specific Styles
```css
/* myComponent.css */

/* Scoped to component */
.container {
    padding: 1rem;
    background-color: #f3f3f3;
}

.header {
    font-size: 1.5rem;
    font-weight: bold;
    color: #0176d3;
}

/* Hover effects */
.card:hover {
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
    transform: translateY(-2px);
    transition: all 0.3s ease;
}
```

### Design Tokens
```css
/* Use Salesforce design tokens */
.custom-element {
    color: var(--slds-c-button-brand-color-background);
    padding: var(--slds-c-button-spacing-block-start);
}
```

## Web Accessibility (a11y)

### Semantic HTML
```html
<!-- ✅ Use semantic elements -->
<template>
    <article>
        <header>
            <h1>Account Details</h1>
        </header>
        <section>
            <h2>Contact Information</h2>
            <!-- Content -->
        </section>
    </article>
</template>
```

### ARIA Attributes
```html
<template>
    <!-- Screen reader support -->
    <button
        aria-label="Close modal"
        aria-pressed={isPressed}
        onclick={handleClose}>
        <lightning-icon icon-name="utility:close"></lightning-icon>
    </button>

    <!-- Live regions for dynamic content -->
    <div role="status" aria-live="polite" aria-atomic="true">
        {statusMessage}
    </div>
</template>
```

### Keyboard Navigation
```javascript
export default class AccessibleComponent extends LightningElement {
    handleKeyDown(event) {
        // Support Enter and Space for button-like elements
        if (event.key === 'Enter' || event.key === ' ') {
            this.handleClick();
            event.preventDefault();
        }

        // Support Escape to close modals
        if (event.key === 'Escape') {
            this.closeModal();
        }
    }
}
```

## Testing (Jest)

### Basic Test Structure
```javascript
// accountList.test.js
import { createElement } from 'lwc';
import AccountList from 'c/accountList';

describe('c-account-list', () => {
    afterEach(() {
        // Clean up DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders accounts', () => {
        // Given
        const element = createElement('c-account-list', {
            is: AccountList
        });

        // When
        document.body.appendChild(element);

        // Then
        const accountElements = element.shadowRoot.querySelectorAll('.account-item');
        expect(accountElements.length).toBeGreaterThan(0);
    });
});
```

### Testing Apex Calls
```javascript
import { createElement } from 'lwc';
import AccountList from 'c/accountList';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

// Mock Apex method
jest.mock('@salesforce/apex/AccountController.getAccounts', () => {
    return {
        default: jest.fn()
    };
}, { virtual: true });

describe('c-account-list', () => {
    it('loads accounts from Apex', async () => {
        // Given
        const mockAccounts = [
            { Id: '001', Name: 'Account 1' },
            { Id: '002', Name: 'Account 2' }
        ];
        getAccounts.mockResolvedValue(mockAccounts);

        const element = createElement('c-account-list', {
            is: AccountList
        });
        document.body.appendChild(element);

        // When - Wait for async operations
        await Promise.resolve();

        // Then
        const accounts = element.shadowRoot.querySelectorAll('.account-item');
        expect(accounts.length).toBe(2);
    });
});
```

## LWC vs Aura

| Feature | LWC | Aura |
|---------|-----|------|
| **Performance** | Faster (native web standards) | Slower (custom framework) |
| **Standards** | ES6+, Web Components | Proprietary |
| **Bundle Size** | Smaller | Larger |
| **Learning Curve** | Easier (JavaScript) | Steeper (Aura-specific) |
| **Future** | ✅ Active development | ⚠️ Maintenance mode |
| **Recommendation** | **Use for all new development** | Legacy only |

## Quick Checklist

Before deploying LWC components:
- [ ] Component follows naming conventions
- [ ] Uses Lightning base components where possible
- [ ] Proper error handling implemented
- [ ] Apex methods use @AuraEnabled(cacheable=true) when appropriate
- [ ] Accessibility (ARIA, keyboard navigation) implemented
- [ ] Responsive design (works on mobile)
- [ ] Performance optimized (debouncing, lazy loading)
- [ ] Jest tests written and passing
- [ ] SLDS classes used for styling
- [ ] No console.log statements in production code
- [ ] Public APIs (@api) documented

## When This Rule Applies

This LWC development standards rule is **ALWAYS ACTIVE** for:
- All Lightning Web Component development
- All LWC code reviews
- All UI component design decisions
- All component refactoring
- All Aura to LWC migrations

**Remember**: LWC is the future of Salesforce UI development. Build with web standards, optimize for performance, design for accessibility.
