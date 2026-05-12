# CG Cloud TPM Technical Implementation Patterns

> **Source**: Extracted from NotebookLM (41 sources) on 2026-03-06

## 1. Processing Engine Data

### Architecture Pattern

CG Cloud TPM segregates data between:
- **Salesforce Platform**: Stores Master Data (products, accounts) and business processes (promotions)
- **Processing Service/Hyperforce**: Handles mass data, P&L calculations, and KPIs

Data must be synchronized to the Processing Service via:
- Standard SF Data Sync processes
- Integration APIs

### Data Integration Patterns

Data loaded into the processing service follows three generic table structures:

**Time-Based Data**
- Used for: List prices, shelf prices, exchange rates
- Required parameters: `Date From`, `Date Thru`

**Weekly Data**
- Used for: Baseline and target volumes
- Required parameters: Weekly value, product/customer references

**Daily Data**
- Used for: Actual volumes (Sell-In/Sell-Out), actual revenues
- Loaded on daily basis

### Best Practices

**External ID Requirements**:
- `Product ID` and `Customer ID` fields must correspond to Salesforce External IDs
- No blanks or special characters (underscores are permitted)

**Master Data Synchronization**:
- Always synchronize master data changes using "SF Data Sync" tool:
  - Sales Org settings
  - Product configurations
  - Customer hierarchies
  - Template Metadata
- Ensures off-core calculation engine uses correct updated structures

---

## 2. Batch Chains

### Implementation Pattern

TPM calculation chains execute sequentially off-core. For example:
- Long Term Agreement calculations start only after Basic Customer Business Plan calculations finish

Scheduling is handled on Salesforce platform via:
- Apex Batches
- Job Scheduling Transactions

### Code Patterns

**Triggering Calculation Chain Programmatically**:

```apex
// Configure batch settings
cgcloud.TPM_BC_Settings options = new cgcloud.TPM_BC_Settings('0001');
options.execAccountPlanBasic = true;
options.execAccountPlanBusinessPlan = true;
options.execPromotion = true;
options.execFundCalculation = false;

// Initialize and start chain
cgcloud.TPMCalculationChain chain = new cgcloud.TPMCalculationChain(options);
chain.startProcess();
```

**Custom Batch Scheduling**:

```apex
// Bundle items into ScheduleJobTransaction
// open() signals new job arriving to off-core
transaction.open();

// Add batch items
transaction.addItem(batchItem);

// close() signals no more items will arrive
transaction.close();
```

### Monitoring

Monitor batch processes via **Batch Run Status** object:
- Live status tracking
- Execution error reporting

### Best Practices

- Monitor Batch Run Status for errors
- Schedule calculation chains during off-peak hours
- Test batch configurations in sandbox before production deployment

---

## 3. Promotion UI Customization

### Implementation Pattern

TPM UI operates in "Edit Mode":
- Users see results of changes across related records before save
- Final save is all-or-nothing to database

Custom Lightning Web Components (LWCs) must interface with core `<cgcloud-tpm-promotion>` service component.

### Code Patterns

**Reading Live UI Changes**:

```javascript
// Event handlers for live data
handlePromotionChange(event) {
    const promotionData = event.detail;
    // Process promotion changes
}

handleTacticsChange(event) {
    const tacticsData = event.detail;
    // Process tactics changes
}

// Register event handlers
const promotionComponent = this.template.querySelector('[data-id="promotion"]');
promotionComponent.addEventListener('onpromotionchange', this.handlePromotionChange);
promotionComponent.addEventListener('ontacticschange', this.handleTacticsChange);
```

**Updating Records on UI**:

```javascript
// Update promotion fields
const p = this.template.querySelector('[data-id="promotion"]');
p.setPromotionField('fieldName', newValue);

// Update tactic fields (batched for performance)
p.setTacticField(tacticId, 'fieldName', newValue);
```

**UI Validations Before Save**:

```javascript
// Register callback to halt save if validation fails
const p = this.template.querySelector('[data-id="promotion"]');
p.setCallback('onBeforeSave', this._beforeSaveCallback.bind(this));

_beforeSaveCallback(promotion, tactics) {
    // Perform validations
    if (validationFails) {
        return Promise.reject(new Error('Validation failed: specific reason'));
    }
    return Promise.resolve();
}
```

**APEX Backend Customization**:

```apex
// Implement System.Callable for custom logic during save
public class CustomPromotionHandler implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        if (action == 'execute') {
            // Custom logic here
            // Insert related records
            // Execute validations
        }
        return null;
    }
}
```

Register in **CGCloud Process Customization** Custom Metadata Type.

### Best Practices

- Value updates using `setTacticField` are batched for performance
- Multiple calls produce only a single `tacticschange` event
- Enable LWC Debug Mode during development
- **Always disable Debug Mode in Production** for optimal performance
- Use `System.Callable` for consistent backend processing across UI, mass copy, and BO API

---

## 4. Promo BO API

### Implementation Pattern

Promotion Business Object (BO) API is used to:
- Bulk-create promotions from external systems
- Manipulate promotions from custom UI elements

**Processing Flow**: Receive Data → Transform → Commit to DB → Calculate → Complete

Transformation logic driven by APEX plugins called "Workflow Steps".

### Code Patterns

**External System API Flow**:

```javascript
// Step 1: Initialize import
POST /services/apexrest/cgcloud/promotions/initialize
{
    "nrOfItems": 100,
    "salesOrg": "0001"
}

// Response includes importId
{
    "importId": "a1b2c3d4"
}

// Step 2: Chunk and ingest data
POST /services/apexrest/cgcloud/promotions/ingest
{
    "importId": "a1b2c3d4",
    "promotions": [
        // Array of up to 50 promotion records
        {
            "name": "Q1 Beverage Promo",
            "startDate": "2026-01-01",
            // ... other fields
        }
    ]
}
```

**Aura Integration**:

```javascript
// Asynchronous processing
const boApi = component.find('boApi');
boApi.queue(promotionData);

// Synchronous processing
boApi.process(promotionData).then(result => {
    // Handle result
}).catch(error => {
    // Handle error
});
```

### Best Practices

- Use standard provided Workflow Steps as baseline
- Steps are updated with latest Managed Package configurations
- **Crucial**: Avoid placing raw DML operations in BO API Workflow steps
- Instead, use standard TPM Promotion Save APEX hook (`System.Callable`)
- Ensures custom processing fires consistently regardless of creation method:
  - UI
  - Mass copy
  - BO API
- Chunk data into batches of 50 records maximum for optimal performance

---

## 5. Metadata Wizard

### Implementation Pattern

Metadata Wizard is a dynamic rendering engine that:
- Builds step-by-step forms entirely from metadata configurations
- Uses "expressions" (similar to Visualforce syntax) for dynamic behaviors
- Examples: "New Promotion" screen, custom wizards

**Key Feature**: Dynamically updates picklist values based on prior field selections

Natively passes generated input directly into Promo BO API to create resulting promotion.

### Expression Syntax

```javascript
// Example expression for conditional visibility
{expression: "promotion.template == 'National'"}

// Example expression for dynamic picklist
{expression: "getProducts(promotion.category)"}
```

### Best Practices

**Avoid Circular Dependencies**:
- Carefully review expressions
- Circular dependencies between variables and UI components trigger infinite rendering loops

**Testing**:
- Use built-in "Dry Run" button
- Safely test form logic and expressions
- No actual commits to Salesforce database during dry run

**Localization**:
- Implement custom labels directly in wizard metadata definitions
- Automatically supports localization

**Development Process**:
1. Define metadata structure
2. Create expressions for dynamic behavior
3. Test with Dry Run
4. Validate in sandbox
5. Deploy to production

---

## Integration Best Practices

### Data Quality
- Validate External IDs before loading
- Ensure master data sync before transactional data
- Monitor data sync job status

### Performance
- Batch process large data volumes
- Schedule calculation chains during off-peak hours
- Use writeback KPIs selectively (only what's needed for reporting)

### Error Handling
- Monitor Batch Run Status object
- Implement retry logic for transient errors
- Log errors for troubleshooting

### Security
- Use JWT Server-to-Server flows for Integration APIs
- Implement MTLS for secure communication
- Follow least-privilege principle for API access

### Testing
- Test in sandbox with production-like data volumes
- Validate calculation results
- Test graceful degradation when Processing Service is unavailable
