# How `/fsc-dev` Extends `/fullstack-dev`

## Architecture

This skill follows a **composition over duplication** approach:

```
/fsc-dev (Industry-Specific)
    └── extends /fullstack-dev (Generic Salesforce)
            └── references /apex-dev (Backend Deep-Dive)
            └── references /lwc-dev (Frontend Deep-Dive)
```

---

## Inherited Competencies (from `/fullstack-dev`)

The following capabilities are **inherited** and do NOT need to be duplicated:

### Backend & Frontend Integration
- ViewModel pattern (Apex ↔ LWC contracts)
- API contract design (REST/GraphQL)
- Cross-layer error handling
- End-to-end testing strategies

### 2026-Forward Platform Capabilities
- **Agentforce & Predictive AI**: Atlas Reasoning, RAG, Trust Layer, Observability
- **Data Cloud/Genie**: Zero-copy grounding, semantic layer, real-time ingestion
- **External Client Apps**: OAuth 2.0, federated identity, token management
- **Slack-First Orchestration**: Multiplayer workflows, canvas apps, notifications
- **Context Engineering**: AI context design for high ROI

### Strategic Architecture
- Identity & Access Management
- Event-Driven Architecture
- Large Data Volumes
- Flow Orchestration
- DevOps & CI/CD (Copado/SFDX)

### Testing Standards
- 75%+ code coverage requirement
- Unit + Integration + E2E testing
- Test data factory patterns
- Mocking strategies

### Security Best Practices
- Sharing rules (`with sharing`)
- Field-level security (`WITH SECURITY_ENFORCED`)
- CRUD/FLS enforcement
- PII masking and data protection

**Reference**: `../fullstack-dev/SKILL.md` for complete generic patterns

---

## Added Specializations (Financial Services Cloud-Specific)

This skill **adds** the following Financial Services Cloud expertise:

### 1. Industry Data Models

#### FinServ__FinancialAccount__c
- **Purpose**: Core financial account object for tracking customer accounts, balances, and account types
- **Key Fields**: FinServ__Balance__c, FinServ__AccountType__c, FinServ__Status__c, FinServ__AccountNumber__c, FinServ__OpenDate__c
- **Relationships**: FinServ__FinancialAccountRole__c, Account, FinServ__FinancialGoal__c
#### FinServ__Securities__c
- **Purpose**: Investment securities tracking for stocks, bonds, and other financial instruments
- **Key Fields**: FinServ__Price__c, FinServ__Symbol__c, FinServ__AssetClass__c, FinServ__CUSIP__c, FinServ__Exchange__c
- **Relationships**: FinServ__FinancialAccount__c, FinServ__FinancialHolding__c
#### FinServ__FinancialGoal__c
- **Purpose**: Client financial goals for retirement planning, education savings, etc.
- **Key Fields**: FinServ__TargetValue__c, FinServ__TargetDate__c, FinServ__Status__c, FinServ__Type__c
- **Relationships**: FinServ__FinancialAccount__c, Account

**Why This Matters**: Generic `/fullstack-dev` doesn't know Financial Services Cloud object names, field relationships, or business semantics. This skill provides deep object model expertise.

**Reference**: `./references/financial-services-cloud-data-models.md`

---

### 2. Regulatory Compliance

#### FINRA
- **Scope**: Financial Industry Regulatory Authority compliance for trade surveillance and customer protection
- **Requirements**: Trade surveillance and monitoring; Customer verification (KYC/AML); Audit trail maintenance for all transactions; Disclosure requirements for investment products; Suitability assessments for client investments
#### SEC
- **Scope**: Securities and Exchange Commission regulations for investment advisors and broker-dealers
- **Requirements**: Form ADV filing and updates; Disclosure of conflicts of interest; Regular compliance reporting; Record retention requirements; Anti-fraud provisions

**Why This Matters**: Generic `/fullstack-dev` doesn't enforce industry-specific compliance. This skill ensures FINRA, SEC requirements are met in all implementations.

**Reference**: `./references/financial-services-cloud-regulatory.md`

---


### 3. External System Integrations

#### Core Banking System
- **Protocol**: REST API
- **Use Case**: Real-time account balance synchronization and transaction history
- **Pattern**: /api/v1/accounts/{accountId}/balance
#### Market Data Provider
- **Protocol**: WebSocket
- **Use Case**: Live securities pricing and market data streaming
- **Pattern**: wss://market.example.com/quotes
#### Custodian System
- **Protocol**: SFTP Batch
- **Use Case**: Nightly portfolio holdings and transactions reconciliation
- **Pattern**: sftp://custodian.example.com/holdings

**Why This Matters**: Generic `/fullstack-dev` doesn't know industry-standard systems or integration patterns. This skill provides pre-built integration templates.

**Reference**: `./references/financial-services-cloud-integrations.md`

---


### 4. Industry-Specific Competencies

#### Wealth Management (Expert)

**Capabilities**:
- Investment portfolio management and rebalancing
- Goal-based financial planning workflows
- Household relationship modeling (advisors, clients, beneficiaries)
- Performance reporting and attribution
- Fee calculation and billing

#### Retail Banking (Advanced)

**Capabilities**:
- Customer onboarding workflows (KYC/AML)
- Loan origination processes
- Credit decisioning integration
- Account opening automation
- Branch operations support

#### Regulatory Compliance (Expert)

**Capabilities**:
- FINRA reporting and surveillance
- SEC Form ADV generation
- Audit trail implementation
- Suitability assessment automation
- Data retention policies

#### Investment Analytics (Advanced)

**Capabilities**:
- Portfolio performance calculation
- Risk analysis and metrics
- Asset allocation optimization
- Benchmark comparison
- Tax-loss harvesting


**Why This Matters**: Generic `/fullstack-dev` lacks domain expertise in Financial Services Cloud business processes. This skill provides specialized knowledge for industry use cases.

---

### 5. Industry Use Cases & Examples

#### Wealth Management Portal
- **Description**: Client-facing portal for investment portfolio tracking, performance analysis, and goal monitoring
- **Components**: LWC dashboard with charts (Chart.js), Real-time market data feed (WebSocket), PDF statement generation (Apex), Data Cloud for historical performance, Agentforce for portfolio recommendations
#### Automated Compliance Reporting
- **Description**: Generate regulatory reports (Form ADV, FINRA) with automated data collection and validation
- **Components**: Scheduled batch Apex for data aggregation, Data Cloud queries for audit trail, Document generation (PDF/Excel), External Client App for compliance officer access, Email notification workflows
#### Client Onboarding Automation
- **Description**: Streamlined KYC/AML process with automated identity verification and account opening
- **Components**: LWC multi-step wizard, Integration with identity verification service (REST), Flow orchestration for approval workflows, Platform Events for system notifications, Agentforce for risk scoring
#### Portfolio Rebalancing Engine
- **Description**: Automated portfolio rebalancing based on target allocation and tax optimization
- **Components**: Batch Apex for portfolio analysis, Queueable Apex for trade execution, Integration with trading platform (REST), Custom metadata for rebalancing rules, LWC approval interface for advisors
#### Advisor 360 Dashboard
- **Description**: Comprehensive advisor view of clients, households, portfolios, and activities
- **Components**: LWC with multiple card components, Agentforce for client insights and next-best-actions, Data Cloud for cross-account analytics, Slack integration for advisor collaboration, Einstein Analytics for predictive insights

**Why This Matters**: Generic `/fullstack-dev` provides patterns but not industry context. This skill includes real-world Financial Services Cloud scenarios and implementations.

**Reference**: `./references/financial-services-cloud-use-cases.md`

---

## Composition Strategy

### What Gets Inherited (DRY Principle)

**Generic Salesforce patterns are inherited, NOT duplicated**:
- Apex syntax and best practices → Reference `/fullstack-dev`
- LWC component lifecycle → Reference `/fullstack-dev`
- Agentforce integration code → Reference `/fullstack-dev/references/agentforce-patterns.md`
- Data Cloud queries → Reference `/fullstack-dev/references/data-cloud-zero-copy.md`
- Testing frameworks → Reference `/fullstack-dev/references/testing-cross-layer.md`

### What Gets Specialized (Industry Context)

**Financial Services Cloud-specific knowledge is added**:
- Object model (FinServ__FinancialAccount__c, FinServ__Securities__c, FinServ__FinancialGoal__c)
- Compliance (FINRA, SEC)
- Integrations (Core Banking System, Market Data Provider, Custodian System)
- Business process expertise
- Use case templates

---

## When to Use Each Skill

### Use `/fsc-dev` When:
- Working with Financial Services Cloud objects (FinServ__FinancialAccount__c, etc.)
- FINRA compliance is required
- Building industry-specific features (Wealth Management Portal, etc.)
- Need domain expertise in Wealth Management, Retail Banking, Regulatory Compliance, Investment Analytics

### Use `/fullstack-dev` When:
- Generic Salesforce development (no industry context)
- Custom objects (not industry-standard)
- Learning generic patterns (Agentforce, Data Cloud, testing)
- Architecture patterns (event-driven, LDV, etc.)

### Use `/apex-dev` When:
- Deep Apex optimization (governor limits, batch processing)
- Complex trigger frameworks
- Low-level performance tuning

### Use `/lwc-dev` When:
- Advanced SLDS customization
- Complex accessibility requirements
- Frontend architecture deep-dives

### Use `/architect` When:
- Solution design (high-level architecture)
- Well-Architected analysis
- Multi-cloud architecture

---

## Example: Inheritance in Action

### Scenario: Build Wealth Management Portal

**Step 1: Understand Context** (`/fsc-dev` expertise)
- Identifies required Financial Services Cloud objects: FinServ__FinancialAccount__c
- Validates FINRA requirements
- Plans integration with Core Banking System

**Step 2: Design ViewModel** (`/fullstack-dev` inherited pattern)
```apex
// Generic pattern from /fullstack-dev
public class Financial Services CloudViewModel {
    @AuraEnabled public String id;
    @AuraEnabled public String displayName;
    // ... ViewModel fields
}
```

**Step 3: Implement Controller** (`/fsc-dev` + `/fullstack-dev`)
```apex
// Generic pattern: with sharing, SECURITY_ENFORCED (from /fullstack-dev)
// Industry context: FinServ__FinancialAccount__c query (from /fsc-dev)
public with sharing class Financial Services CloudController {
    @AuraEnabled
    public static List<Financial Services CloudViewModel> getData() {
        List<FinServ__FinancialAccount__c> records = [
            SELECT FinServ__Balance__c, FinServ__AccountType__c, FinServ__Status__c, FinServ__AccountNumber__c, FinServ__OpenDate__c
            FROM FinServ__FinancialAccount__c
            WITH SECURITY_ENFORCED
        ];
        return transform(records);
    }
}
```

**Step 4: Build LWC** (`/fullstack-dev` inherited pattern)
```javascript
// Generic LWC pattern from /fullstack-dev
import { LightningElement, track } from 'lwc';
import getData from '@salesforce/apex/Financial Services CloudController.getData';

export default class Financial Services CloudComponent extends LightningElement {
    @track viewModel;
    // ... LWC implementation
}
```

**Step 5: Add Tests** (`/fullstack-dev` inherited standard)
```apex
// 75%+ coverage requirement from /fullstack-dev
// Financial Services Cloud test data from /fsc-dev
@IsTest
private class Financial Services CloudControllerTest {
    @IsTest
    static void testGetData() {
        FinServ__FinancialAccount__c record = Financial Services CloudTestDataFactory.createFinServ__FinancialAccount__c();
        Test.startTest();
        List<Financial Services CloudViewModel> results = Financial Services CloudController.getData();
        Test.stopTest();
        System.assertEquals(1, results.size());
    }
}
```

**Result**:
- Generic patterns inherited (no duplication)
- Financial Services Cloud expertise applied where needed
- Clean separation of concerns

---

## Benefits of Extension Model

### 1. No Duplication
- Generic Salesforce patterns live in one place (`/fullstack-dev`)
- Industry skills reference, not repeat
- Updates to `/fullstack-dev` benefit all industry skills

### 2. Clear Boundaries
- `/fullstack-dev`: Platform capabilities
- `/fsc-dev`: Industry domain knowledge
- No confusion about where patterns belong

### 3. Composability
- New industry skills can be added without modifying base
- Each industry skill is independent
- Astro routes intelligently based on context

### 4. Maintainability
- Update generic patterns once in `/fullstack-dev`
- Industry skills stay focused on domain knowledge
- Easier to keep skills current

---

## Skills Hierarchy

```
/architect (Solution Design)
    └── /fullstack-dev (Generic Full-Stack)
            ├── /apex-dev (Backend Specialist)
            ├── /lwc-dev (Frontend Specialist)
            └── Industry Skills (Domain Specialists)
                    ├── /fsc-dev (Financial Services Cloud)
                    ├── /health-dev (Health Cloud)
                    ├── /fs-dev (Field Service)
                    └── ... (other industries)
```

---

## Summary

**This skill (`/fsc-dev`) is NOT a standalone entity**. It's a **specialized extension** of `/fullstack-dev` that adds Financial Services Cloud domain expertise while inheriting all generic Salesforce capabilities.

**Think of it as**:
- `/fullstack-dev` = Salesforce platform expert
- `/fsc-dev` = Salesforce platform expert **+ Financial Services Cloud domain expert**

**Always reference base skills** for generic patterns. This skill focuses exclusively on Financial Services Cloud specializations.
