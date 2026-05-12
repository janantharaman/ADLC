# Full-Stack Integration Patterns

End-to-end patterns for integrating Apex backend with LWC frontend in Salesforce development.

---

## Table of Contents
1. [ViewModel Pattern](#viewmodel-pattern)
2. [API Contract Design](#api-contract-design)
3. [Error Handling Across Layers](#error-handling-across-layers)
4. [Cross-Layer Testing](#cross-layer-testing)
5. [Common Pitfalls](#common-pitfalls)

---

## ViewModel Pattern

### Problem
Exposing sObjects directly to LWC creates tight coupling:
- LWC breaks when Apex fields change
- Computed values require modifying sObject
- Versioning APIs becomes difficult
- Frontend gets unnecessary fields (security risk)

### Solution: ViewModel Pattern
Create a data transfer object (DTO) that serves as a contract between Apex and LWC.

---

### Example 1: Basic ViewModel

#### ❌ WRONG: Direct sObject Exposure
```apex
@AuraEnabled
public static Account getAccount(Id accountId) {
    return [SELECT Id, Name, Phone, Industry, AnnualRevenue FROM Account WHERE Id = :accountId];
}
```

**Problems**:
- LWC receives all fields (even if not needed)
- Adding/removing fields breaks LWC
- No computed properties (e.g., formatted revenue)

#### ✅ CORRECT: ViewModel Pattern
```apex
public class AccountViewModel {
    @AuraEnabled public String id;
    @AuraEnabled public String name;
    @AuraEnabled public String phone;
    @AuraEnabled public String industry;
    @AuraEnabled public String formattedRevenue; // Computed field

    public AccountViewModel(Account acc) {
        this.id = acc.Id;
        this.name = acc.Name;
        this.phone = acc.Phone;
        this.industry = acc.Industry;
        // Computed field: Format revenue
        this.formattedRevenue = formatCurrency(acc.AnnualRevenue);
    }

    private String formatCurrency(Decimal amount) {
        return amount != null ? '$' + amount.format() : 'N/A';
    }
}

@AuraEnabled
public static AccountViewModel getAccount(Id accountId) {
    Account acc = [SELECT Id, Name, Phone, Industry, AnnualRevenue FROM Account WHERE Id = :accountId];
    return new AccountViewModel(acc);
}
```

**Benefits**:
- Clear contract (LWC knows exactly what to expect)
- Computed fields without modifying sObject
- Versioning: Add new fields to ViewModel without breaking LWC
- Security: Only expose needed fields

---

### Example 2: List ViewModel with Pagination

```apex
public class AccountListViewModel {
    @AuraEnabled public List<AccountViewModel> accounts;
    @AuraEnabled public Integer total;
    @AuraEnabled public Integer pageSize;
    @AuraEnabled public Integer pageNumber;
    @AuraEnabled public Boolean hasMore;

    public AccountListViewModel(List<Account> accounts, Integer total, Integer pageSize, Integer pageNumber) {
        this.accounts = new List<AccountViewModel>();
        for (Account acc : accounts) {
            this.accounts.add(new AccountViewModel(acc));
        }
        this.total = total;
        this.pageSize = pageSize;
        this.pageNumber = pageNumber;
        this.hasMore = (pageNumber * pageSize) < total;
    }
}

@AuraEnabled
public static AccountListViewModel getAccounts(Integer pageNumber, Integer pageSize) {
    Integer offset = (pageNumber - 1) * pageSize;

    List<Account> accounts = [
        SELECT Id, Name, Phone, Industry, AnnualRevenue
        FROM Account
        ORDER BY Name
        LIMIT :pageSize OFFSET :offset
    ];

    Integer total = [SELECT COUNT() FROM Account];

    return new AccountListViewModel(accounts, total, pageSize, pageNumber);
}
```

**LWC Consumption**:
```javascript
import { LightningElement, track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountService.getAccounts';

export default class AccountList extends LightningElement {
    @track accounts = [];
    @track pageNumber = 1;
    @track pageSize = 10;
    @track total = 0;
    @track hasMore = false;

    connectedCallback() {
        this.loadAccounts();
    }

    loadAccounts() {
        getAccounts({ pageNumber: this.pageNumber, pageSize: this.pageSize })
            .then(result => {
                this.accounts = result.accounts;
                this.total = result.total;
                this.hasMore = result.hasMore;
            })
            .catch(error => {
                console.error('Error loading accounts:', error);
            });
    }

    handleNext() {
        if (this.hasMore) {
            this.pageNumber++;
            this.loadAccounts();
        }
    }
}
```

---

## API Contract Design

### RESTful Endpoint Pattern

#### Example: Order Management API

```apex
@RestResource(urlMapping='/api/v1/orders/*')
global class OrderRestController {

    // GET /api/v1/orders?status=open&limit=10
    @HttpGet
    global static OrderListResponse getOrders() {
        RestRequest req = RestContext.request;
        String status = req.params.get('status');
        Integer limitParam = Integer.valueOf(req.params.get('limit') ?? '10');

        try {
            List<Order> orders = OrderService.getOrders(status, limitParam);
            return OrderListResponse.success(orders);
        } catch (Exception e) {
            return OrderListResponse.error(e.getMessage());
        }
    }

    // GET /api/v1/orders/{orderId}
    @HttpGet
    global static OrderResponse getOrder() {
        RestRequest req = RestContext.request;
        String orderId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

        try {
            Order order = OrderService.getOrder(orderId);
            return OrderResponse.success(order);
        } catch (OrderNotFoundException e) {
            return OrderResponse.error(e.getMessage(), 404);
        } catch (Exception e) {
            return OrderResponse.error(e.getMessage());
        }
    }

    // POST /api/v1/orders
    @HttpPost
    global static OrderResponse createOrder() {
        RestRequest req = RestContext.request;
        OrderRequest orderReq = (OrderRequest) JSON.deserialize(req.requestBody.toString(), OrderRequest.class);

        try {
            Order order = OrderService.createOrder(orderReq);
            return OrderResponse.success(order, 201);
        } catch (OrderValidationException e) {
            return OrderResponse.error(e.getMessage(), 400);
        } catch (Exception e) {
            return OrderResponse.error(e.getMessage());
        }
    }

    // PUT /api/v1/orders/{orderId}
    @HttpPut
    global static OrderResponse updateOrder() {
        RestRequest req = RestContext.request;
        String orderId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        OrderRequest orderReq = (OrderRequest) JSON.deserialize(req.requestBody.toString(), OrderRequest.class);

        try {
            Order order = OrderService.updateOrder(orderId, orderReq);
            return OrderResponse.success(order);
        } catch (OrderNotFoundException e) {
            return OrderResponse.error(e.getMessage(), 404);
        } catch (OrderValidationException e) {
            return OrderResponse.error(e.getMessage(), 400);
        } catch (Exception e) {
            return OrderResponse.error(e.getMessage());
        }
    }

    // DELETE /api/v1/orders/{orderId}
    @HttpDelete
    global static OrderResponse deleteOrder() {
        RestRequest req = RestContext.request;
        String orderId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

        try {
            OrderService.deleteOrder(orderId);
            return OrderResponse.success(null, 204);
        } catch (OrderNotFoundException e) {
            return OrderResponse.error(e.getMessage(), 404);
        } catch (Exception e) {
            return OrderResponse.error(e.getMessage());
        }
    }
}

// Response ViewModels
global class OrderResponse {
    global Order order;
    global Integer statusCode;
    global String message;
    global Boolean success;

    global static OrderResponse success(Order order) {
        return success(order, 200);
    }

    global static OrderResponse success(Order order, Integer statusCode) {
        OrderResponse response = new OrderResponse();
        response.order = order;
        response.statusCode = statusCode;
        response.success = true;
        return response;
    }

    global static OrderResponse error(String message) {
        return error(message, 500);
    }

    global static OrderResponse error(String message, Integer statusCode) {
        OrderResponse response = new OrderResponse();
        response.message = message;
        response.statusCode = statusCode;
        response.success = false;
        return response;
    }
}

global class OrderListResponse {
    global List<Order> orders;
    global Integer total;
    global Integer statusCode;
    global String message;
    global Boolean success;

    global static OrderListResponse success(List<Order> orders) {
        OrderListResponse response = new OrderListResponse();
        response.orders = orders;
        response.total = orders.size();
        response.statusCode = 200;
        response.success = true;
        return response;
    }

    global static OrderListResponse error(String message) {
        OrderListResponse response = new OrderListResponse();
        response.message = message;
        response.statusCode = 500;
        response.success = false;
        return response;
    }
}
```

---

## Error Handling Across Layers

### Principle: Consistent Error Structure
All errors (validation, not found, internal) should follow the same structure for LWC to handle uniformly.

### Apex: Custom Exceptions
```apex
public class OrderValidationException extends Exception {}
public class OrderNotFoundException extends Exception {}
public class OrderProcessingException extends Exception {}
```

### Apex: Service Layer with Error Handling
```apex
public class OrderService {
    public static Order createOrder(OrderRequest req) {
        // Validation
        if (req.amount <= 0) {
            throw new OrderValidationException('Amount must be greater than zero');
        }
        if (String.isBlank(req.accountId)) {
            throw new OrderValidationException('Account ID is required');
        }

        // Business logic
        try {
            Order order = new Order(
                AccountId = req.accountId,
                Amount__c = req.amount,
                Status__c = 'Open'
            );

            // Check CRUD/FLS
            if (!Schema.sObjectType.Order.isCreateable()) {
                throw new OrderProcessingException('Insufficient permissions to create order');
            }

            insert order;
            return order;
        } catch (DmlException e) {
            throw new OrderProcessingException('Failed to create order: ' + e.getMessage());
        }
    }
}
```

### LWC: Unified Error Handling
```javascript
import { LightningElement } from 'lwc';
import createOrder from '@salesforce/apex/OrderService.createOrder';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderForm extends LightningElement {
    accountId;
    amount;

    handleSubmit() {
        createOrder({ accountId: this.accountId, amount: this.amount })
            .then(result => {
                this.showToast('Success', 'Order created successfully', 'success');
                this.resetForm();
            })
            .catch(error => {
                const message = this.extractErrorMessage(error);
                this.showToast('Error', message, 'error');
            });
    }

    extractErrorMessage(error) {
        // Handle different error formats
        if (error.body) {
            if (error.body.message) {
                return error.body.message;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            } else if (error.body.fieldErrors) {
                const fieldErrors = Object.values(error.body.fieldErrors).flat();
                if (fieldErrors.length > 0) {
                    return fieldErrors[0].message;
                }
            }
        } else if (error.message) {
            return error.message;
        }
        return 'Unknown error occurred. Please try again.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    resetForm() {
        this.accountId = '';
        this.amount = 0;
    }
}
```

---

## Cross-Layer Testing

### Unit Tests (Apex)
```apex
@isTest
private class OrderServiceTest {
    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount();
        insert acc;
    }

    @isTest
    static void testCreateOrder_Success() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OrderRequest req = new OrderRequest();
        req.accountId = acc.Id;
        req.amount = 1000;

        // When
        Test.startTest();
        Order order = OrderService.createOrder(req);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, order.Id, 'Order should be created');
        System.assertEquals(1000, order.Amount__c, 'Amount should match');
        System.assertEquals('Open', order.Status__c, 'Status should be Open');
    }

    @isTest
    static void testCreateOrder_ValidationError() {
        // Given
        OrderRequest req = new OrderRequest();
        req.accountId = null; // Invalid
        req.amount = 1000;

        // When/Then
        try {
            OrderService.createOrder(req);
            System.assert(false, 'Should have thrown OrderValidationException');
        } catch (OrderValidationException e) {
            System.assert(e.getMessage().contains('Account ID is required'), 'Should have validation message');
        }
    }
}
```

### Integration Tests (REST API)
```apex
@isTest
private class OrderRestControllerTest {
    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount();
        insert acc;
    }

    @isTest
    static void testCreateOrder_RestEndpoint() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String requestBody = '{"accountId": "' + acc.Id + '", "amount": 1000}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/v1/orders';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        // When
        Test.startTest();
        OrderRestController.OrderResponse response = OrderRestController.createOrder();
        Test.stopTest();

        // Then
        System.assertEquals(201, response.statusCode, 'Should return 201 Created');
        System.assertEquals(true, response.success, 'Should be successful');
        System.assertNotEquals(null, response.order, 'Should return order');
        System.assertEquals(1000, response.order.Amount__c, 'Amount should match');
    }

    @isTest
    static void testGetOrders_WithFilters() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order order1 = new Order(AccountId = acc.Id, Amount__c = 1000, Status__c = 'Open');
        Order order2 = new Order(AccountId = acc.Id, Amount__c = 2000, Status__c = 'Closed');
        insert new List<Order>{ order1, order2 };

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/v1/orders';
        req.httpMethod = 'GET';
        req.params.put('status', 'Open');
        req.params.put('limit', '10');
        RestContext.request = req;

        // When
        Test.startTest();
        OrderRestController.OrderListResponse response = OrderRestController.getOrders();
        Test.stopTest();

        // Then
        System.assertEquals(200, response.statusCode, 'Should return 200 OK');
        System.assertEquals(true, response.success, 'Should be successful');
        System.assertEquals(1, response.orders.size(), 'Should return 1 open order');
        System.assertEquals('Open', response.orders[0].Status__c, 'Status should be Open');
    }
}
```

### LWC Jest Tests
```javascript
// orderForm.test.js
import { createElement } from 'lwc';
import OrderForm from 'c/orderForm';
import createOrder from '@salesforce/apex/OrderService.createOrder';

// Mock Apex call
jest.mock(
    '@salesforce/apex/OrderService.createOrder',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-order-form', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should create order successfully', async () => {
        // Given
        const element = createElement('c-order-form', {
            is: OrderForm
        });
        document.body.appendChild(element);

        const mockOrder = { Id: '001xxx', Amount__c: 1000 };
        createOrder.mockResolvedValue(mockOrder);

        // When
        const form = element.shadowRoot.querySelector('lightning-input');
        form.value = 1000;
        form.dispatchEvent(new CustomEvent('change'));

        const submitButton = element.shadowRoot.querySelector('lightning-button');
        submitButton.click();

        // Wait for promises
        await Promise.resolve();

        // Then
        expect(createOrder).toHaveBeenCalledWith({ accountId: expect.any(String), amount: 1000 });
    });

    it('should handle error', async () => {
        // Given
        const element = createElement('c-order-form', {
            is: OrderForm
        });
        document.body.appendChild(element);

        const mockError = { body: { message: 'Amount must be greater than zero' } };
        createOrder.mockRejectedValue(mockError);

        // When
        const submitButton = element.shadowRoot.querySelector('lightning-button');
        submitButton.click();

        // Wait for promises
        await Promise.resolve();

        // Then
        // Verify toast message was shown (would require mocking ShowToastEvent)
    });
});
```

---

## Common Pitfalls

### Pitfall 1: Exposing Internal IDs
**Problem**: Exposing Salesforce record IDs in URLs or APIs.

**Solution**: Use external IDs or slugs.

```apex
// ❌ WRONG
@HttpGet
global static OrderResponse getOrder() {
    String orderId = RestContext.request.params.get('id'); // Salesforce ID exposed
    // ...
}

// ✅ CORRECT
@HttpGet
global static OrderResponse getOrder() {
    String orderNumber = RestContext.request.params.get('orderNumber'); // External ID
    Order order = [SELECT Id FROM Order WHERE OrderNumber__c = :orderNumber LIMIT 1];
    // ...
}
```

---

### Pitfall 2: N+1 Query Problem
**Problem**: Querying related records in a loop.

**Solution**: Bulkify with relationship queries.

```apex
// ❌ WRONG
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
    acc.Contacts = contacts; // N+1 queries
}

// ✅ CORRECT
List<Account> accounts = [
    SELECT Id, Name, (SELECT Id, Name FROM Contacts)
    FROM Account
];
```

---

### Pitfall 3: Large Payloads
**Problem**: Returning 1000+ records to LWC.

**Solution**: Implement pagination.

```apex
// See "Example 2: List ViewModel with Pagination" above
```

---

### Pitfall 4: Inconsistent Error Formats
**Problem**: Different error structures for validation vs server errors.

**Solution**: Unified error response (see "Error Handling Across Layers" above).

---

### Pitfall 5: Missing CRUD/FLS Checks
**Problem**: Users without permissions see errors.

**Solution**: Check CRUD/FLS before DML.

```apex
// ✅ CORRECT
if (!Schema.sObjectType.Order.isCreateable()) {
    throw new OrderProcessingException('Insufficient permissions to create order');
}
```

---

## Summary

**Key Patterns**:
1. **ViewModel Pattern**: Decouple Apex from LWC with data transfer objects
2. **API Contract Design**: RESTful endpoints with consistent response structure
3. **Error Handling**: Unified error format across layers
4. **Cross-Layer Testing**: Unit tests + integration tests + Jest tests

**Best Practices**:
- Always use ViewModels (never expose sObjects directly)
- Implement pagination for large datasets
- Unified error handling (consistent structure)
- Bulkify queries (avoid N+1)
- Check CRUD/FLS before DML
- Use external IDs (not Salesforce IDs) in APIs

**Reference Files**:
- Apex patterns: `../../apex-developer/references/`
- LWC patterns: `../../lwc-developer/references/`
- Testing standards: `../../rules/03-salesforce-testing-standards.md`
