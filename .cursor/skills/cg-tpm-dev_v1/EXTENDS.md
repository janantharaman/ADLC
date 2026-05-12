# Extension: CG Cloud TPM Developer extends Fullstack Developer

**Base Skill**: `/fullstack-dev`
**Extended Skill**: `/cg-tpm-dev`

## Inheritance Model

The `/cg-tpm-dev` skill **extends** `/fullstack-dev`, inheriting all Salesforce best practices while adding CG Cloud TPM-specific expertise.

```
/fullstack-dev (Base)
    ↓ extends
/cg-tpm-dev (Extended)
```

## Inherited Capabilities

### From `/fullstack-dev`

1. **Apex Development**
   - Governor limit management
   - Bulkification patterns
   - Trigger frameworks
   - Test class standards (75%+ coverage)

2. **Lightning Web Components**
   - Component architecture
   - Event handling
   - Lightning Data Service
   - Wire adapters
   - Best practices

3. **Security**
   - Object-level security (CRUD/FLS)
   - Sharing rules
   - Field-level security
   - WITH SECURITY_ENFORCED in SOQL

4. **Integration**
   - REST API patterns
   - HTTP callouts
   - Named Credentials
   - External Services

5. **Data Management**
   - SOQL optimization
   - Relationship queries
   - Data Loader patterns
   - Bulk API usage

6. **Testing**
   - Test data factories
   - Assertion patterns
   - Mock callouts
   - Test coverage requirements

## CG TPM-Specific Extensions

### Added Competencies

1. **TPM Data Models** (New)
   - Sales Organization multi-market patterns
   - Product hierarchies with time-stamped relationships
   - Account Product Lists (Global vs Time-Dependent)
   - Trade Calendar with custom 4-4-5 structures

2. **Processing Service Integration** (New)
   - Dual-architecture (Platform + Hyperforce)
   - SF Data Sync patterns
   - Batch chain orchestration
   - Integration APIs for mass data

3. **TPM Business Processes** (New)
   - Promotion lifecycle management
   - Customer Business Planning
   - Claims processing workflows
   - KPI calculation engine

4. **TPM UI Patterns** (Extended LWC)
   - `cgcloud-tpm-promotion` component integration
   - Edit Mode patterns (multi-record before save)
   - Pre-save validations with callbacks
   - Batched field updates

5. **Promo BO API** (New)
   - Two-step initialization pattern
   - Workflow Steps transformation
   - Chunked data ingestion (50 records)
   - System.Callable backend hooks

6. **Real-Time Reporting** (New)
   - Writeback KPI configuration
   - RTR component setup
   - Dynamic P&L layouts
   - Proper aggregation patterns

## When to Use Which Skill

### Use `/fullstack-dev` for:
- Generic Salesforce development
- Standard objects and processes
- Non-TPM CG Cloud features
- Foundational Salesforce patterns

### Use `/cg-tpm-dev` for:
- Anything CG Cloud TPM-specific
- Promotions, claims, funds, KPIs
- Processing Engine integration
- TPM-specific UI customization
- Product/account hierarchies
- Trade Calendar management

### Skill Automatically Extends:
When you invoke `/cg-tpm-dev`, you automatically get:
- All `/fullstack-dev` capabilities
- Plus CG TPM-specific expertise

## Integration Pattern

```
User Request: "Create a promotion with validation"
    ↓
/cg-tpm-dev (TPM-specific)
    ↓
    ├─ TPM Knowledge: Promotion data model, lifecycle
    │  (From NotebookLM or pre-trained)
    │
    ├─ TPM Patterns: cgcloud-tpm-promotion component
    │  (CG TPM-specific)
    │
    └─ Inherited from /fullstack-dev:
       ├─ LWC best practices
       ├─ Apex patterns (bulkification, triggers)
       ├─ Security (CRUD/FLS)
       └─ Testing standards
```

## Code Example: Extension in Action

### Promotion Creation with Extended Capabilities

```apex
// From /fullstack-dev: Apex best practices
public class PromotionService {
    // Inherited: Bulkification pattern
    public static List<cgcloud__Advanced_Promotion__c> createPromotions(List<PromotionRequest> requests) {
        List<cgcloud__Advanced_Promotion__c> promos = new List<cgcloud__Advanced_Promotion__c>();

        // Extended: CG TPM-specific data model knowledge
        for (PromotionRequest req : requests) {
            cgcloud__Advanced_Promotion__c promo = new cgcloud__Advanced_Promotion__c(
                Name = req.name,
                cgcloud__Promotion_Template__c = req.templateId,
                cgcloud__Anchor__c = req.customerId,
                cgcloud__Start_Date__c = req.startDate,
                cgcloud__End_Date__c = req.endDate,
                cgcloud__Phase__c = 'Preparation' // TPM-specific phase
            );
            promos.add(promo);
        }

        // Inherited: Security-enforced DML
        insert as user promos;

        // Extended: Trigger Processing Engine calculation
        triggerPromotionCalculation(promos);

        return promos;
    }

    // Extended: CG TPM Processing Service integration
    private static void triggerPromotionCalculation(List<cgcloud__Advanced_Promotion__c> promos) {
        cgcloud.TPM_BC_Settings options = new cgcloud.TPM_BC_Settings('0001');
        options.execPromotion = true;

        cgcloud.TPMCalculationChain chain = new cgcloud.TPMCalculationChain(options);
        chain.startProcess();
    }
}

// Extended: CG TPM-specific System.Callable hook
public class PromotionCustomHandler implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        if (action == 'execute') {
            // Inherited: Apex patterns, error handling
            try {
                Id promoId = (Id) args.get('promotionId');

                // Extended: CG TPM business logic
                createPromotionMetrics(promoId);
                linkDefaultTactics(promoId);

            // Inherited: Error handling patterns
            } catch (Exception e) {
                System.debug('Error in promotion handler: ' + e.getMessage());
                throw e;
            }
        }
        return null;
    }

    // Extended: CG TPM-specific metrics
    private void createPromotionMetrics(Id promoId) {
        // TPM-specific implementation
    }

    // Extended: CG TPM-specific tactic setup
    private void linkDefaultTactics(Id promoId) {
        // TPM-specific implementation
    }
}
```

### LWC Example: Extended UI Pattern

```javascript
// From /fullstack-dev: LWC best practices
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Extended: CG TPM-specific component
export default class CustomPromotionForm extends LightningElement {
    @track promotionData = {};

    // Inherited: LWC lifecycle hooks
    connectedCallback() {
        this.initializePromotion();

        // Extended: CG TPM-specific component integration
        const promotionComponent = this.template.querySelector('[data-id="promotion"]');
        promotionComponent.addEventListener('onpromotionchange', this.handlePromotionChange.bind(this));
    }

    // Extended: CG TPM Edit Mode pattern
    handlePromotionChange(event) {
        this.promotionData = event.detail;

        // Inherited: Error handling
        if (!this.validatePromotion()) {
            this.showError('Invalid promotion data');
        }
    }

    // Extended: CG TPM pre-save validation
    registerValidation() {
        const p = this.template.querySelector('[data-id="promotion"]');

        // CG TPM-specific callback pattern
        p.setCallback('onBeforeSave', this.validateBeforeSave.bind(this));
    }

    validateBeforeSave(promotion, tactics) {
        // Inherited: Validation patterns
        if (!promotion.startDate || !promotion.endDate) {
            return Promise.reject(new Error('Dates are required'));
        }

        // Extended: CG TPM-specific validation
        if (tactics.length === 0) {
            return Promise.reject(new Error('At least one tactic is required'));
        }

        return Promise.resolve();
    }

    // Inherited: Toast notification pattern
    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
}
```

## Benefits of Extension

### Code Reusability
- Don't repeat Salesforce best practices
- Focus on TPM-specific logic
- Cleaner, more maintainable code

### Consistency
- Same security patterns across skills
- Consistent testing standards
- Uniform error handling

### Knowledge Efficiency
- Build on foundational knowledge
- Specialize where needed
- Clear separation of concerns

## Delegation Chain

```
User invokes: /cg-tpm-dev
    ↓
TPM-specific guidance needed?
    ├─ Yes: /cg-tpm-dev handles
    │       (Uses NotebookLM + pre-trained)
    │
    └─ Generic Salesforce?
        └─ Inherits from /fullstack-dev
            ↓
        Complex Apex needed?
            └─ Can delegate to /apex-developer
                ↓
        Advanced LWC?
            └─ Can delegate to /lwc-developer
```

## Testing Extension

### Test Coverage
Both inherited and extended capabilities should be tested:

```apex
@isTest
public class PromotionServiceTest {
    // Inherited: Test data factory pattern
    @testSetup
    static void setup() {
        TestDataFactory.createPromotionTestData();
    }

    // Inherited: Bulkification testing
    @isTest
    static void testBulkPromotionCreation() {
        List<PromotionRequest> requests = createTestRequests(200);

        Test.startTest();
        List<cgcloud__Advanced_Promotion__c> promos = PromotionService.createPromotions(requests);
        Test.stopTest();

        // Inherited: Assert pattern
        System.assertEquals(200, promos.size(), 'Should create 200 promotions');
    }

    // Extended: CG TPM-specific validation
    @isTest
    static void testPromotionPhaseValidation() {
        // TPM-specific test logic
    }

    // Extended: Processing Engine integration test
    @isTest
    static void testCalculationChainTrigger() {
        // Mock Processing Service callout
        // Test batch chain initialization
    }
}
```

## Summary

| Aspect | /fullstack-dev | /cg-tpm-dev |
|--------|---------------|-------------|
| **Scope** | Generic Salesforce | CG Cloud TPM |
| **Data Models** | Standard + Custom | TPM-specific objects |
| **Integration** | Standard APIs | Processing Service APIs |
| **UI Patterns** | Standard LWC | cgcloud-tpm-promotion |
| **Knowledge Source** | Built-in | NotebookLM + Pre-trained |
| **Specialization** | Broad | Deep TPM expertise |

**Extension Model**: `/cg-tpm-dev` = `/fullstack-dev` + TPM Expertise

---

**Note**: When you use `/cg-tpm-dev`, you automatically benefit from all `/fullstack-dev` capabilities while getting TPM-specific guidance. This extension model ensures consistency while enabling specialization.
