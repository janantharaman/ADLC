# Financial Services Cloud Full-Stack Developer (`/fsc-dev`)

## Overview

This skill provides expert-level Financial Services Cloud development capabilities, combining:
- **Generic Salesforce Expertise** (from `/fullstack-dev`): Apex, LWC, Agentforce, Data Cloud, testing
- **Financial Services Cloud Specialization**: Industry data models, regulatory compliance, integrations

**When to Use**: Invoke `/fsc-dev` for Financial Services Cloud-specific feature development.

**When to Delegate**:
- Generic Salesforce development → `/fullstack-dev`
- Architecture design → `/architect`
- Deep Apex optimization → `/apex-dev`
- Complex LWC patterns → `/lwc-dev`

---

## Key Capabilities

### Financial Services Cloud Data Models

Expert knowledge of Financial Services Cloud objects:
- **FinServ__FinancialAccount__c**: Core financial account object for tracking customer accounts, balances, and account types
- **FinServ__Securities__c**: Investment securities tracking for stocks, bonds, and other financial instruments
- **FinServ__FinancialGoal__c**: Client financial goals for retirement planning, education savings, etc.

**Reference**: `./references/financial-services-cloud-data-models.md`

---

### Regulatory Compliance

Deep understanding of compliance requirements:
- **FINRA**: Financial Industry Regulatory Authority compliance for trade surveillance and customer protection
- **SEC**: Securities and Exchange Commission regulations for investment advisors and broker-dealers

**Reference**: `./references/financial-services-cloud-regulatory.md`

---


### External Integrations

Experience with industry-standard integrations:
- **Core Banking System** (REST API): Real-time account balance synchronization and transaction history
- **Market Data Provider** (WebSocket): Live securities pricing and market data streaming
- **Custodian System** (SFTP Batch): Nightly portfolio holdings and transactions reconciliation

**Reference**: `./references/financial-services-cloud-integrations.md`

---


### Industry-Specific Competencies

#### Wealth Management (Expert)
- Investment portfolio management and rebalancing
- Goal-based financial planning workflows
- Household relationship modeling (advisors, clients, beneficiaries)
- Performance reporting and attribution
- Fee calculation and billing

#### Retail Banking (Advanced)
- Customer onboarding workflows (KYC/AML)
- Loan origination processes
- Credit decisioning integration
- Account opening automation
- Branch operations support

#### Regulatory Compliance (Expert)
- FINRA reporting and surveillance
- SEC Form ADV generation
- Audit trail implementation
- Suitability assessment automation
- Data retention policies

#### Investment Analytics (Advanced)
- Portfolio performance calculation
- Risk analysis and metrics
- Asset allocation optimization
- Benchmark comparison
- Tax-loss harvesting


---

## Common Use Cases

### 0. Wealth Management Portal

Client-facing portal for investment portfolio tracking, performance analysis, and goal monitoring

**Technical Stack**: LWC dashboard with charts (Chart.js), Real-time market data feed (WebSocket), PDF statement generation (Apex), Data Cloud for historical performance, Agentforce for portfolio recommendations

### 1. Automated Compliance Reporting

Generate regulatory reports (Form ADV, FINRA) with automated data collection and validation

**Technical Stack**: Scheduled batch Apex for data aggregation, Data Cloud queries for audit trail, Document generation (PDF/Excel), External Client App for compliance officer access, Email notification workflows

### 2. Client Onboarding Automation

Streamlined KYC/AML process with automated identity verification and account opening

**Technical Stack**: LWC multi-step wizard, Integration with identity verification service (REST), Flow orchestration for approval workflows, Platform Events for system notifications, Agentforce for risk scoring

### 3. Portfolio Rebalancing Engine

Automated portfolio rebalancing based on target allocation and tax optimization

**Technical Stack**: Batch Apex for portfolio analysis, Queueable Apex for trade execution, Integration with trading platform (REST), Custom metadata for rebalancing rules, LWC approval interface for advisors

### 4. Advisor 360 Dashboard

Comprehensive advisor view of clients, households, portfolios, and activities

**Technical Stack**: LWC with multiple card components, Agentforce for client insights and next-best-actions, Data Cloud for cross-account analytics, Slack integration for advisor collaboration, Einstein Analytics for predictive insights


**Reference**: `./references/financial-services-cloud-use-cases.md` for detailed examples

---

## Technical Stack

### Backend (Apex)
- Custom objects and relationships
- Business logic enforcement
- Integration services
- Compliance validation
- Batch processing for large data volumes

### Frontend (LWC)
- Industry-specific components
- Data visualization
- User interaction patterns
- Error handling and validation

### AI & Automation (Agentforce)
- Context engineering for Financial Services Cloud
- Trust Layer with FINRA compliance
- RAG with Data Cloud grounding
- Predictive analytics

### Data Platform (Data Cloud)
- Zero-copy data integration
- Real-time data ingestion
- Semantic layer for AI
- Cross-cloud analytics

---

## File Structure

```
fsc-dev/
├── SKILL.md                          # Main skill definition (this file used by AI)
├── README.md                         # Human-readable documentation (you are here)
├── EXTENDS.md                        # How this extends /fullstack-dev

└── references/                       # Deep-dive technical guides
    ├── financial-services-cloud-data-models.md
    ├── financial-services-cloud-regulatory.md
    ├── financial-services-cloud-integrations.md
    └── financial-services-cloud-use-cases.md
```

---

## Quick Start

### 1. Invoke the Skill

```bash
/fsc-dev "Build Wealth Management Portal"
```

### 2. Expected Behavior

The AI will:
1. Understand Financial Services Cloud context
2. Reference correct data models (FinServ__FinancialAccount__c, etc.)
3. Ensure FINRA compliance
4. Implement full-stack solution (Apex + LWC)
5. Provide test coverage (75%+)

### 3. Example Output

- Apex controller with `with sharing` and `SECURITY_ENFORCED`
- LWC component with error handling
- Test class with Financial Services Cloud test data factory
- Integration patterns for external systems

---

## Routing Indicators

Astro will automatically route to `/fsc-dev` when it detects:

- "financial account"
- "securities"
- "FINRA"
- "wealth management"
- "retail banking"
- "investment portfolio"
- "FSC"

**Manual Invocation**: Use `/fsc-dev` directly for explicit routing.

---

## Integration with Base Skills

This skill **extends** `/fullstack-dev` and inherits:
- Apex & LWC integration patterns
- Agentforce & Data Cloud capabilities
- Testing standards (75%+ coverage)
- Security best practices
- DevOps & CI/CD patterns

**See**: `EXTENDS.md` for detailed inheritance documentation

---

## Reference Files

Deep-dive technical guides:

### fsc-data-models.md

FSC data model deep dive with ERD diagrams and field definitions

**Sections**:
- Overview
- FinancialAccount and Roles
- Securities and Holdings
- Financial Goals
- Household Relationships
- Best Practices

**Location**: `./references/fsc-data-models.md`

### fsc-regulatory.md

FINRA and SEC compliance patterns for Salesforce implementations

**Sections**:
- FINRA Compliance
- SEC Regulations
- Audit Trail Implementation
- PII Protection and Data Masking
- Reporting Requirements
- Best Practices

**Location**: `./references/fsc-regulatory.md`

### fsc-integrations.md

Core banking and market data integration patterns

**Sections**:
- Core Banking Integration (REST)
- Market Data Feeds (WebSocket)
- Custodian Reconciliation (SFTP)
- Identity Verification Services
- Error Handling Patterns
- Best Practices

**Location**: `./references/fsc-integrations.md`

### fsc-use-cases.md

Common FSC implementation scenarios with code examples

**Sections**:
- Wealth Management Portal
- Compliance Reporting
- Client Onboarding
- Portfolio Rebalancing
- Advisor Dashboard
- Best Practices

**Location**: `./references/fsc-use-cases.md`


---

## Knowledge Sources

This skill was manually curated from industry best practices and Salesforce documentation.

---

## Testing

### Unit Tests
```apex
@IsTest
private class Financial Services CloudControllerTest {
    @IsTest
    static void testGetFinServ__FinancialAccount__c() {
        // Setup test data
        FinServ__FinancialAccount__c record = Financial Services CloudTestDataFactory.createFinServ__FinancialAccount__c();

        // Test
        Test.startTest();
        List<Financial Services CloudViewModel> results = Financial Services CloudController.getData();
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size());
    }
}
```

### Integration Tests
```apex
@IsTest
private class Financial Services CloudIntegrationTest {
    @IsTest
    static void testEndToEndFlow() {
        // Test full user journey across Financial Services Cloud objects
    }
}
```

### LWC Tests
```javascript
import { createElement } from 'lwc';
import Financial Services CloudComponent from 'c/financialServicesCloudComponent';

describe('c-financial-services-cloud-component', () => {
    it('renders Financial Services Cloud data correctly', () => {
        const element = createElement('c-financial-services-cloud-component', {
            is: Financial Services CloudComponent
        });
        document.body.appendChild(element);
        // Assertions
    });
});
```

---

## Best Practices

1. **Always use ViewModel pattern** for Apex ↔ LWC contracts
2. **Enforce sharing and FLS** with `with sharing` and `SECURITY_ENFORCED`
3. **Validate FINRA compliance** before deployment
4. **Test thoroughly**: 75%+ coverage with integration tests
5. **Document industry patterns** in code comments
6. **Use NotebookLM** for deep research on edge cases

---

## Support & Feedback

- **Issues**: Report bugs or request features in project repository
- **Documentation**: See `./references/` for detailed guides
- **Base Patterns**: Reference `../fullstack-dev/references/`

---

## Version History

- **Generated**: Manual creation
- **Industry**: Financial Services Cloud
- **Base Skill**: `/fullstack-dev`
- **Specializations**: 4 competency areas, 3 data models, 2 regulatory frameworks
