# CG Cloud TPM Integration Patterns

> **Source**: Extracted from NotebookLM (41 sources) on 2026-03-06

## Architecture Overview

CG Cloud TPM uses a dual-architecture model:
- **Salesforce Platform**: Master Data and UI interaction
- **Backend Cloud Processing Service (Hyperforce)**: Heavy data volumes and calculation engines

Integrations occur at multiple levels to synchronize data across:
- Salesforce
- Processing Service
- External systems

---

## 1. External Data Sources

### ERP Systems (e.g., SAP)

**Purpose**: Source of master data and transactional data

**Integration Pattern**: ERP → Middleware (MuleSoft) → Salesforce Platform

**Data Types**:
- **Master Data**:
  - Customers
  - Products
  - Product Hierarchies
  - Bill of Materials (BOMs)

**Flow**:
1. Extract data from ERP
2. Transform via middleware (MuleSoft Accelerator for Consumer Goods)
3. Load into Salesforce Platform

### Syndicated & POS Data (e.g., Nielsen, IRI, Retail Link)

**Purpose**: Volume data and performance metrics

**Integration Pattern**: External Source → Middleware → Processing Service (Direct)

**Data Types**:

**Time-Based Data**:
- List prices
- Shelf prices
- Cost of Goods Sold (COGS)
- Exchange rates

**Weekly Data**:
- Baseline volumes

**Daily Data**:
- Actual volumes (Sell-In and Sell-Out/POS data)
- Actual revenue
- Actual condition values

**Flow**:
1. Extract data from syndicated source
2. Transform via middleware
3. Load directly into Processing Service via Integration APIs

---

## 2. API Patterns

### Integration APIs (Processing Service REST API)

**Purpose**: Load heavy transactional data into backend Processing Service

**Security**: JWT Server-to-Server flows and MTLS

**API Structure**:

```http
POST /integration/api/v1/data
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

{
    "salesOrg": "0001",
    "productId": "PROD_123",
    "customerId": "CUST_456",
    "timeFrame": "2026-W01",
    "conditionType": "BASE",
    "value": 1000
}
```

**Required Parameters**:
- External Product ID
- Customer ID
- Sales Org
- Time Frame
- 4-character Condition Type ("Read" code)

**Data Types Loaded**:
- Baselines
- Actuals
- Prices
- COGS
- Exchange rates

**Best Practices**:
- Use Salesforce External IDs (no blanks or special characters except underscores)
- Batch requests for performance
- Implement retry logic for transient failures
- Monitor API rate limits

### Business Object (Promo BO) API

**Purpose**: Create or mass-load promotions from external systems

**Pattern**: Two-step initialization and chunking

**API Flow**:

**Step 1: Initialize Import**
```http
POST /services/apexrest/cgcloud/promotions/initialize
{
    "nrOfItems": 150,
    "salesOrg": "0001"
}

Response:
{
    "importId": "a1b2c3d4-5678-90ef-ghij-klmnopqrstuv"
}
```

**Step 2: Ingest Data (Chunked)**
```http
POST /services/apexrest/cgcloud/promotions/ingest
{
    "importId": "a1b2c3d4-5678-90ef-ghij-klmnopqrstuv",
    "promotions": [
        {
            "name": "Q1 Beverage Promotion",
            "startDate": "2026-01-01",
            "endDate": "2026-03-31",
            "template": "National_Promo",
            "customer": "CUST_456",
            "products": ["PROD_123", "PROD_124"]
        }
        // Up to 50 records per request
    ]
}
```

**Transformation Engine**:
- Converts standard JSON to Business Object records
- Uses Apex "Workflow Steps" for transformation logic
- Executes validation and calculations

**Best Practices**:
- Chunk data into batches of 50 records maximum
- Use standard Workflow Steps as baseline
- Monitor import status via Batch Run Status
- Handle errors gracefully with retry logic

---

## 3. Real-Time Reporting (RTR) Data Sources

**Purpose**: RTR pulls pre-calculated data for immediate reporting

**Data Sources**:

### Backend Writebacks (Hyperforce)
- Account Plan Writebacks
- Promotion Writebacks
- Stored in Processing Service database

**Requirement**: KPIs must be defined as "Writeback KPIs"

### Salesforce Platform Data
- Fund values
- Direct Salesforce object data

### Best Practices

**What to Writeback**:
- Volume metrics
- Revenue metrics
- Underlying components for calculations

**What NOT to Writeback**:
- Percentages (causes incorrect aggregation)
- Prices (causes incorrect aggregation on disaggregation)
- Conditions

**Reason**: RTR aggregates and disaggregates values dynamically. Use underlying components (Volume, Revenue) and let RTR calculate derived metrics (Price = Revenue/Volume).

**Configuration Pattern**:
```apex
// Configure Writeback KPI
KPI Definition:
- Name: "Target Volume"
- Type: Calculated
- Writeback: true
- Writeback Code: "TVOL"

// RTR retrieves using writeback code
RTR Query:
- KPI: "TVOL"
- Aggregation: SUM
- Dimensions: [Product, Customer, Week]
```

---

## 4. Data Cloud Connectivity

**Note**: The provided sources detail architecture involving Salesforce Platform, Hyperforce Processing Engine, and standard middleware integrations (MuleSoft). Sources do not contain specific information regarding direct connectivity patterns with Salesforce Data Cloud.

**Recommendation**: Consult standard Salesforce Data Cloud documentation for:
- Ingesting CG Cloud data into Data Cloud
- Zero-copy integration patterns
- Real-time data streaming

---

## 5. Integration Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    External Systems                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐     │
│  │   ERP    │  │   POS    │  │ Syndicated Data  │     │
│  │  (SAP)   │  │  Data    │  │ (Nielsen, IRI)   │     │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘     │
└───────┼─────────────┼─────────────────┼───────────────┘
        │             │                 │
        │        ┌────▼─────────────────▼────┐
        │        │      Middleware           │
        │        │  (MuleSoft Accelerator)   │
        │        └────┬─────────────────┬────┘
        │             │                 │
        │             │                 │
┌───────▼─────────────▼──┐      ┌──────▼───────────────┐
│  Salesforce Platform   │      │  Processing Service  │
│  ┌──────────────────┐  │      │    (Hyperforce)      │
│  │  Master Data     │  │      │  ┌────────────────┐  │
│  │  - Products      │  │◄────►│  │  Calculation   │  │
│  │  - Accounts      │  │ Sync │  │    Engine      │  │
│  │  - Hierarchies   │  │      │  └────────────────┘  │
│  └──────────────────┘  │      │  ┌────────────────┐  │
│  ┌──────────────────┐  │      │  │  Mass Data     │  │
│  │  Transactions    │  │      │  │  - Baselines   │  │
│  │  - Promotions    │  │      │  │  - Actuals     │  │
│  │  - Claims        │  │      │  │  - KPIs        │  │
│  └──────────────────┘  │      │  └────────────────┘  │
└────────────────────────┘      └──────────────────────┘
         │                                 │
         └──────────┬──────────────────────┘
                    │
         ┌──────────▼──────────┐
         │  Real-Time Reporting │
         │      (RTR)           │
         └──────────────────────┘
```

---

## 6. Integration Patterns Summary

### Master Data Integration
- **Source**: ERP
- **Target**: Salesforce Platform
- **Method**: Middleware (MuleSoft)
- **Frequency**: Real-time or scheduled batches
- **Post-Load**: SF Data Sync to Processing Service

### Transactional Data Integration
- **Source**: POS, Syndicated Data
- **Target**: Processing Service (Direct)
- **Method**: Integration APIs (REST)
- **Frequency**: Daily or weekly
- **Security**: JWT + MTLS

### Promotion Bulk Loading
- **Source**: External systems or custom UI
- **Target**: Salesforce Platform
- **Method**: Promo BO API
- **Frequency**: On-demand
- **Chunking**: 50 records per request

### Reporting Data
- **Source**: Processing Service (Writebacks)
- **Target**: RTR Components
- **Method**: Query Writeback KPIs
- **Frequency**: Real-time

---

## 7. Best Practices

### Security
- Use JWT Server-to-Server authentication
- Implement MTLS for API communication
- Rotate credentials regularly
- Follow least-privilege principle

### Performance
- Batch API requests
- Monitor rate limits
- Schedule large data loads during off-peak hours
- Use compression for large payloads

### Data Quality
- Validate External IDs before loading
- Implement data quality checks in middleware
- Log transformation errors
- Maintain audit trail

### Error Handling
- Implement retry logic with exponential backoff
- Handle partial failures gracefully
- Monitor integration job status
- Alert on critical failures

### Monitoring
- Track API response times
- Monitor data volume trends
- Set up alerts for integration failures
- Review error logs regularly

### Maintenance
- Keep middleware connectors updated
- Test integrations after CG Cloud upgrades
- Document custom integration logic
- Version control integration configurations
