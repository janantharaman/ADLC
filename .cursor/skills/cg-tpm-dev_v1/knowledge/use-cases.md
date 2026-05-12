# CG Cloud TPM Common Development Use Cases

> **Source**: Extracted from NotebookLM (41 sources) on 2026-03-06

## 1. Creating Promotions

### UI Customization

**Use Case**: Custom promotion creation form with dynamic validation

**Pattern**: Interface with `cgcloud-tpm-promotion` Lightning Web Component

**Implementation**:

```javascript
// Read live promotion changes
export default class CustomPromotionForm extends LightningElement {

    connectedCallback() {
        const promotionComponent = this.template.querySelector('[data-id="promotion"]');

        // Listen to promotion changes
        promotionComponent.addEventListener('onpromotionchange', this.handlePromotionChange.bind(this));
        promotionComponent.addEventListener('ontacticschange', this.handleTacticsChange.bind(this));
    }

    handlePromotionChange(event) {
        const promotionData = event.detail;

        // Custom validation logic
        if (this.needsCustomValidation(promotionData)) {
            this.validatePromotion(promotionData);
        }
    }

    handleTacticsChange(event) {
        const tacticsData = event.detail;

        // Update related calculations
        this.updateTacticCalculations(tacticsData);
    }

    // Programmatically update promotion
    updatePromotionField(fieldName, value) {
        const p = this.template.querySelector('[data-id="promotion"]');
        p.setPromotionField(fieldName, value);
    }

    // Batched tactic updates
    updateTacticFields(tacticId, updates) {
        const p = this.template.querySelector('[data-id="promotion"]');
        Object.entries(updates).forEach(([field, value]) => {
            p.setTacticField(tacticId, field, value);
        });
    }

    // Pre-save validation
    registerValidation() {
        const p = this.template.querySelector('[data-id="promotion"]');
        p.setCallback('onBeforeSave', this.validateBeforeSave.bind(this));
    }

    validateBeforeSave(promotion, tactics) {
        // Custom validation logic
        if (!this.isValidPromotionDate(promotion.startDate, promotion.endDate)) {
            return Promise.reject(new Error('End date must be after start date'));
        }

        if (tactics.length === 0) {
            return Promise.reject(new Error('At least one tactic is required'));
        }

        return Promise.resolve();
    }
}
```

### Backend Customization

**Use Case**: Execute custom logic during promotion save

**Pattern**: Implement `System.Callable` interface

**Implementation**:

```apex
public class CustomPromotionHandler implements System.Callable {

    public Object call(String action, Map<String, Object> args) {
        if (action == 'execute') {
            Id promotionId = (Id) args.get('promotionId');
            executeCustomLogic(promotionId);
        }
        return null;
    }

    private void executeCustomLogic(Id promotionId) {
        // Retrieve promotion
        cgcloud__Advanced_Promotion__c promo = [
            SELECT Id, Name, cgcloud__Anchor__c, cgcloud__Start_Date__c, cgcloud__End_Date__c
            FROM cgcloud__Advanced_Promotion__c
            WHERE Id = :promotionId
        ];

        // Create related custom records
        createPromotionMetrics(promo);

        // Send notifications
        notifyStakeholders(promo);

        // Update external systems
        syncWithExternalSystem(promo);
    }

    private void createPromotionMetrics(cgcloud__Advanced_Promotion__c promo) {
        // Custom metrics tracking
        Promotion_Metrics__c metrics = new Promotion_Metrics__c(
            Promotion__c = promo.Id,
            Created_Date__c = System.now(),
            Status__c = 'Active'
        );
        insert metrics;
    }

    private void notifyStakeholders(cgcloud__Advanced_Promotion__c promo) {
        // Send email notifications
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{'kam@example.com'});
        mail.setSubject('New Promotion Created: ' + promo.Name);
        mail.setPlainTextBody('Promotion ' + promo.Name + ' has been created.');
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }

    private void syncWithExternalSystem(cgcloud__Advanced_Promotion__c promo) {
        // API callout to external system
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.external-system.com/promotions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(promo));

        Http http = new Http();
        HttpResponse res = http.send(req);
    }
}
```

**Registration**: Add to **CGCloud Process Customization** Custom Metadata Type

### API Integration

**Use Case**: Bulk create promotions from external system

**Pattern**: Two-step Promo BO API

**Implementation**:

```javascript
// Step 1: Initialize import
async function initializePromotionImport(totalRecords, salesOrg) {
    const response = await fetch('/services/apexrest/cgcloud/promotions/initialize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            nrOfItems: totalRecords,
            salesOrg: salesOrg
        })
    });
    const result = await response.json();
    return result.importId;
}

// Step 2: Ingest promotions in chunks
async function ingestPromotions(importId, promotions) {
    const chunkSize = 50;

    for (let i = 0; i < promotions.length; i += chunkSize) {
        const chunk = promotions.slice(i, i + chunkSize);

        await fetch('/services/apexrest/cgcloud/promotions/ingest', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                importId: importId,
                promotions: chunk
            })
        });
    }
}

// Usage
const promotions = [
    {
        name: 'Q1 Beverage Promotion',
        startDate: '2026-01-01',
        endDate: '2026-03-31',
        template: 'National_Promo',
        customer: 'CUST_456',
        products: ['PROD_123', 'PROD_124']
    },
    // ... more promotions
];

const importId = await initializePromotionImport(promotions.length, '0001');
await ingestPromotions(importId, promotions);
```

---

## 2. Processing Claims

### Claim Ingestion Configuration

**Use Case**: Configure system to handle interfaced claims from ERP

**Pattern**: Claim Template configuration + middleware setup

**Implementation**:

```apex
// Claim processing handler
public class ClaimProcessingHandler {

    public void processInterfacedClaim(Map<String, Object> claimData) {
        // Step 1: Create claim record
        cgcloud__Claim__c claim = new cgcloud__Claim__c(
            cgcloud__Customer__c = (Id) claimData.get('customerId'),
            cgcloud__Amount__c = (Decimal) claimData.get('amount'),
            cgcloud__Claim_Type__c = 'Deduction',
            cgcloud__Status__c = 'Open',
            External_Claim_ID__c = (String) claimData.get('externalId')
        );
        insert claim;

        // Step 2: Link tactics automatically
        linkTacticsToCllaim(claim.Id, claimData);

        // Step 3: Submit for approval
        submitClaimForApproval(claim.Id);
    }

    private void linkTacticsToCllaim(Id claimId, Map<String, Object> claimData) {
        // Find matching tactics based on customer, dates, products
        List<cgcloud__Tactic__c> matchingTactics = [
            SELECT Id, cgcloud__Promotion__r.cgcloud__Start_Date__c, cgcloud__Promotion__r.cgcloud__End_Date__c
            FROM cgcloud__Tactic__c
            WHERE cgcloud__Promotion__r.cgcloud__Anchor__c = :claimData.get('customerId')
            AND cgcloud__Promotion__r.cgcloud__Start_Date__c <= :claimData.get('claimDate')
            AND cgcloud__Promotion__r.cgcloud__End_Date__c >= :claimData.get('claimDate')
        ];

        // Link tactics to claim
        List<cgcloud__Claim_Tactic__c> claimTactics = new List<cgcloud__Claim_Tactic__c>();
        for (cgcloud__Tactic__c tactic : matchingTactics) {
            claimTactics.add(new cgcloud__Claim_Tactic__c(
                cgcloud__Claim__c = claimId,
                cgcloud__Tactic__c = tactic.Id
            ));
        }
        insert claimTactics;
    }

    private void submitClaimForApproval(Id claimId) {
        // Create approval process submission
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(claimId);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
    }
}
```

### Claim Adjustment Workflows

**Use Case**: Handle claim corrections (splitting, replacement, reversal)

**Implementation**:

```apex
public class ClaimAdjustmentService {

    // Claim Splitting: Partially pay claim
    public void splitClaim(Id originalClaimId, Decimal partialAmount) {
        cgcloud__Claim__c originalClaim = [
            SELECT Id, cgcloud__Amount__c, cgcloud__Customer__c
            FROM cgcloud__Claim__c
            WHERE Id = :originalClaimId
        ];

        // Create partial payment claim
        cgcloud__Claim__c partialClaim = new cgcloud__Claim__c(
            cgcloud__Customer__c = originalClaim.cgcloud__Customer__c,
            cgcloud__Amount__c = partialAmount,
            cgcloud__Parent_Claim__c = originalClaimId,
            cgcloud__Claim_Type__c = 'Partial Payment'
        );
        insert partialClaim;

        // Update original claim
        originalClaim.cgcloud__Amount__c -= partialAmount;
        originalClaim.cgcloud__Status__c = 'Partially Paid';
        update originalClaim;
    }

    // Claim Replacement: Correct wrong tactics
    public void replaceTactic(Id claimId, Id oldTacticId, Id newTacticId) {
        // Remove old tactic link
        delete [
            SELECT Id FROM cgcloud__Claim_Tactic__c
            WHERE cgcloud__Claim__c = :claimId AND cgcloud__Tactic__c = :oldTacticId
        ];

        // Add new tactic link
        insert new cgcloud__Claim_Tactic__c(
            cgcloud__Claim__c = claimId,
            cgcloud__Tactic__c = newTacticId
        );
    }

    // Claim Reversal: Cancel the claim
    public void reverseClaim(Id claimId, String reason) {
        cgcloud__Claim__c claim = [
            SELECT Id FROM cgcloud__Claim__c WHERE Id = :claimId
        ];

        claim.cgcloud__Status__c = 'Cancelled';
        claim.cgcloud__Cancellation_Reason__c = reason;
        claim.cgcloud__Cancelled_Date__c = System.now();
        update claim;
    }
}
```

---

## 3. Configuring KPIs

### Formula-Based KPI

**Use Case**: Calculate Promotion ROI

**Configuration**:

```javascript
// KPI Definition: ROI
// Type: Calculated
// Formula:
((actualSales - baselineSales - promotionCost) / promotionCost) * 100

// Mechanics:
// - Object Scope: Promotion
// - Time Scope: Promotion Duration
// - Aggregation: SUM
```

**Implementation in Apex**:

```apex
public class KPICalculationService {

    public void calculatePromotionROI(Id promotionId) {
        cgcloud__Advanced_Promotion__c promo = [
            SELECT Id, Actual_Sales__c, Baseline_Sales__c, Promotion_Cost__c
            FROM cgcloud__Advanced_Promotion__c
            WHERE Id = :promotionId
        ];

        // ROI = (Incremental Sales - Promotion Cost) / Promotion Cost
        Decimal incrementalSales = promo.Actual_Sales__c - promo.Baseline_Sales__c;
        Decimal roi = ((incrementalSales - promo.Promotion_Cost__c) / promo.Promotion_Cost__c) * 100;

        promo.ROI__c = roi;
        update promo;
    }
}
```

### Writeback KPI Configuration

**Use Case**: Configure KPI for Real-Time Reporting

**Configuration Steps**:

1. **Define KPI**:
   - Name: "Target Volume"
   - Type: Calculated
   - Writeback: true
   - Writeback Code: "TVOL"

2. **Configure Integration API**:

```json
{
    "salesOrg": "0001",
    "productId": "PROD_123",
    "customerId": "CUST_456",
    "timeFrame": "2026-W01",
    "conditionType": "TVOL",
    "value": 1000
}
```

3. **Load Data via API**:

```apex
public class KPIIntegrationService {

    public void loadTargetVolumes(List<KPIData> kpiDataList) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://processing-service.com/integration/api/v1/data');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getJWTToken());

        req.setBody(JSON.serialize(kpiDataList));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new IntegrationException('Failed to load KPI data: ' + res.getBody());
        }
    }

    private String getJWTToken() {
        // Generate JWT token for authentication
        // Implementation depends on JWT library
        return 'jwt_token_here';
    }
}

public class KPIData {
    public String salesOrg;
    public String productId;
    public String customerId;
    public String timeFrame;
    public String conditionType;
    public Decimal value;
}
```

---

## 4. Setting up Product Hierarchies

### Product Hierarchy Creation

**Use Case**: Create multi-level product hierarchy (Category → Brand → SKU)

**Implementation**:

```apex
public class ProductHierarchyService {

    public void createProductHierarchy() {
        // Step 1: Create hierarchy nodes (Product Groups)
        Product2 category = new Product2(
            Name = 'Beverages',
            RecordTypeId = getProductGroupRecordType(),
            cgcloud__Product_Level__c = 'Category',
            cgcloud__CG_Cloud_External_Product_ID__c = 'CAT_BEV'
        );
        insert category;

        Product2 brand = new Product2(
            Name = 'Premium Cola',
            RecordTypeId = getProductGroupRecordType(),
            cgcloud__Product_Level__c = 'Brand',
            cgcloud__CG_Cloud_External_Product_ID__c = 'BRAND_COLA'
        );
        insert brand;

        // Step 2: Create SKU (actual product)
        Product2 sku = new Product2(
            Name = 'Premium Cola 500ml',
            RecordTypeId = getProductRecordType(),
            cgcloud__Product_Level__c = 'SKU',
            cgcloud__CG_Cloud_External_Product_ID__c = 'SKU_COLA_500',
            ProductCode = 'COLA500'
        );
        insert sku;

        // Step 3: Create hierarchy relationships
        List<cgcloud__Product_Hierarchy__c> hierarchies = new List<cgcloud__Product_Hierarchy__c>();

        // Category → Brand
        hierarchies.add(new cgcloud__Product_Hierarchy__c(
            cgcloud__Parent_Product__c = category.Id,
            cgcloud__Child_Product__c = brand.Id,
            cgcloud__Valid_From__c = Date.today(),
            cgcloud__Structure_Type__c = 'Sales'
        ));

        // Brand → SKU
        hierarchies.add(new cgcloud__Product_Hierarchy__c(
            cgcloud__Parent_Product__c = brand.Id,
            cgcloud__Child_Product__c = sku.Id,
            cgcloud__Valid_From__c = Date.today(),
            cgcloud__Structure_Type__c = 'Sales'
        ));

        insert hierarchies;

        // Step 4: Sync to Processing Service
        syncProductsToProcessingService(new List<Id>{category.Id, brand.Id, sku.Id});
    }

    private Id getProductRecordType() {
        return Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
    }

    private Id getProductGroupRecordType() {
        return Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product Group').getRecordTypeId();
    }

    private void syncProductsToProcessingService(List<Id> productIds) {
        // Trigger SF Data Sync
        cgcloud.DataSyncService.syncProducts(productIds);
    }
}
```

---

## 5. Managing Account Product Lists (APLs)

### Time-Dependent Product Assortment

**Use Case**: Configure time-dependent APL for seasonal products

**Implementation**:

```apex
public class ProductAssortmentService {

    public void createTimeDependendAssortment(Id customerId, List<Id> productIds, Date validFrom, Date validThru) {
        // Step 1: Create Product Assortment
        cgcloud__Product_Assortment__c assortment = new cgcloud__Product_Assortment__c(
            Name = 'Q1 2026 Assortment',
            cgcloud__Customer__c = customerId,
            cgcloud__Valid_From__c = validFrom,
            cgcloud__Valid_Thru__c = validThru,
            cgcloud__Obligatory__c = false
        );
        insert assortment;

        // Step 2: Link products to assortment
        List<cgcloud__Product_Assortment_Item__c> items = new List<cgcloud__Product_Assortment_Item__c>();
        for (Id productId : productIds) {
            items.add(new cgcloud__Product_Assortment_Item__c(
                cgcloud__Product_Assortment__c = assortment.Id,
                cgcloud__Product__c = productId
            ));
        }
        insert items;

        // Step 3: Sync to Processing Service
        syncAssortmentToProcessingService(assortment.Id);
    }

    private void syncAssortmentToProcessingService(Id assortmentId) {
        // Trigger sync batch process
        Database.executeBatch(new AssortmentSyncBatch(assortmentId));
    }
}
```

### Global APL (Automatic)

**Use Case**: Configure automatic product list based on baseline/price KPIs

**Implementation**:

```apex
public class GlobalAPLService {

    public void configureSalesOrgForGlobalAPL(Id salesOrgId) {
        // Set Sales Org to use Global APL type
        cgcloud__Sales_Organization__c salesOrg = [
            SELECT Id, cgcloud__Account_Product_List_Type__c
            FROM cgcloud__Sales_Organization__c
            WHERE Id = :salesOrgId
        ];

        salesOrg.cgcloud__Account_Product_List_Type__c = 'Global';
        update salesOrg;

        // Schedule batch process to build APLs
        scheduleGlobalAPLBatch();
    }

    private void scheduleGlobalAPLBatch() {
        // Global APL batch automatically includes products with:
        // - Active baseline volume KPI, OR
        // - Active list price KPI

        cgcloud.GlobalAPLBatch batch = new cgcloud.GlobalAPLBatch();
        Database.executeBatch(batch);
    }
}
```

---

## Best Practices Summary

### Creating Promotions
- Use `System.Callable` for consistent backend processing across UI, mass copy, and BO API
- Batch tactic field updates for performance
- Disable LWC Debug Mode in production

### Processing Claims
- Automate claim ingestion from ERP when possible
- Maintain clear documentation for adjustment workflows
- Test approval processes thoroughly

### Configuring KPIs
- Test formulas with sample data before production
- Use writeback KPIs selectively (only what's needed for RTR)
- Document calculation logic clearly

### Product Hierarchies
- Always sync to Processing Service after hierarchy changes
- Use meaningful External IDs (no special characters except underscores)
- Test aggregation logic with production-like data volumes

### Account Product Lists
- Choose Global vs Time-Dependent based on business needs
- Schedule APL batch processes during off-peak hours
- Monitor assortment changes impact on promotions
