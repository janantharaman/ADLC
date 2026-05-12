# How `/cgc-dev` Extends `/fullstack-dev`

## Architecture

This skill follows a **composition over duplication** approach:

```
/cgc-dev (Industry-Specific)
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

## Added Specializations (Consumer Goods Cloud-Specific)

This skill **adds** the following CG Cloud expertise:

### 1. Industry Data Models

#### RetailStore
- **Purpose**: Physical retail locations where products are sold
- **Key Fields**: Name, AccountId, StoreType, Address, Status
- **Relationships**: Account (parent), Visit (child), AssessmentTask (child), StoreProduct (junction)

#### Visit
- **Purpose**: Field representative visits to retail stores
- **Key Fields**: PlannedVisitStartTime, PlannedVisitEndTime, ActualVisitStartTime, ActualVisitEndTime, VisitedStoreId, VisitorId, Status
- **Relationships**: RetailStore (parent), User (parent), VisitedTask (child), ActionPlan (child)

#### ActionPlan
- **Purpose**: Template-driven execution plans for store visits
- **Key Fields**: Name, ActionPlanTemplateId, TargetId, ActionPlanType, Status
- **Relationships**: ActionPlanTemplate (parent), ActionPlanItem (child), Visit (parent)

#### AssessmentTask
- **Purpose**: Audit/assessment activities during visits
- **Key Fields**: Name, TaskType, Status, AssessmentIndDefinitionId
- **Relationships**: AssessmentIndicatorDefinition (parent), Visit (parent), RetailStore (parent)

#### AssessmentIndicatorDefinition
- **Purpose**: Measurement criteria for store assessments
- **Key Fields**: Name, DataType, Description
- **Relationships**: AssessmentTask (child)

#### StoreProduct
- **Purpose**: Junction linking products to stores
- **Key Fields**: RetailStoreId, ProductId, IsAuthorized, FacingsTarget
- **Relationships**: RetailStore (parent), Product2 (parent)

**Why This Matters**: Generic `/fullstack-dev` doesn't know CG Cloud object names, field relationships, or retail business semantics. This skill provides deep object model expertise.

**Knowledge Source**: NotebookLM Notebook `9ca50af3-1937-43a6-87c4-3d8629a1ccbd` (dynamic, continuously updated)

---

### 2. Industry Integrations

#### ERP System (SAP, Oracle)
- **Protocol**: REST/SOAP
- **Use Case**: Product master sync, order management, inventory
- **Pattern**: Named Credentials, Platform Events, scheduled batch

#### DSD System
- **Protocol**: REST
- **Use Case**: Van loading, delivery confirmation, invoicing
- **Pattern**: Mobile-optimized APIs, offline sync, GPS tracking

#### Planogram Tools
- **Protocol**: REST
- **Use Case**: Shelf compliance, image recognition, share-of-shelf
- **Pattern**: Image upload, async processing, Einstein Vision

#### Distributor Management
- **Protocol**: REST/SFTP
- **Use Case**: Distributor orders, sell-through data
- **Pattern**: Batch processing, External Objects, Data Cloud

**Why This Matters**: Generic `/fullstack-dev` doesn't know CPG-industry systems or integration patterns. This skill provides pre-built integration templates.

---

### 3. Industry-Specific Competencies

#### Retail Execution (Expert)
- Store visit workflows, audit management, planogram compliance
- Photo capture, GPS verification, merchandising tasks

#### Trade Promotion Management (Expert)
- Promotion planning, fund management, ROI analytics
- Deduction management, TPO with AI

#### Route Planning & Optimization (Advanced)
- Territory-based routing, visit priority scoring
- Dynamic re-routing, coverage gap analysis

#### Inventory & Order Management (Advanced)
- DSD workflows, van inventory, suggested orders
- Stock monitoring, returns processing

#### Field Force Automation (Expert)
- Offline-first mobile apps, guided selling
- Performance dashboards, coaching tools

**Why This Matters**: Generic `/fullstack-dev` lacks domain expertise in CPG business processes. This skill provides specialized knowledge for retail execution, trade promotions, and field operations.

---

### 4. Industry Use Cases & Examples

#### Store Visit Execution
- **Description**: End-to-end visit workflow with offline capability
- **Components**: LWC mobile wizard, GPS check-in, ActionPlan execution, photo capture

#### Trade Promotion Dashboard
- **Description**: Promotion planning, execution tracking, ROI analytics
- **Components**: LWC dashboard, Apex batch ROI calculation, Data Cloud analytics

#### Planogram Compliance Assessment
- **Description**: Automated shelf compliance with image recognition
- **Components**: Image capture LWC, Einstein Vision, compliance scoring

#### Route Optimization Engine
- **Description**: Intelligent route planning for field reps
- **Components**: Batch Apex routing, mapping API, LWC map visualization

#### Distributor Order Management
- **Description**: Order capture for distributor network
- **Components**: Mobile LWC order entry, suggested order algorithm, ERP integration

**Why This Matters**: Generic `/fullstack-dev` provides patterns but not CPG context. This skill includes real-world CG Cloud scenarios.

---

## Composition Strategy

### What Gets Inherited (DRY Principle)
**Generic Salesforce patterns are inherited, NOT duplicated**:
- Apex syntax and best practices → Reference `/fullstack-dev`
- LWC component lifecycle → Reference `/fullstack-dev`
- Agentforce integration → Reference `/fullstack-dev/references/agentforce-patterns.md`
- Data Cloud queries → Reference `/fullstack-dev/references/data-cloud-zero-copy.md`
- Testing frameworks → Reference `/fullstack-dev/references/testing-cross-layer.md`

### What Gets Specialized (Industry Context)
**CG Cloud-specific knowledge is added**:
- Object model (RetailStore, Visit, ActionPlan, AssessmentTask, StoreProduct)
- Industry integrations (ERP, DSD, planogram, distributor)
- Business process expertise (retail execution, TPM, route optimization)
- Offline-first design patterns (critical for field reps)
- NotebookLM dynamic knowledge (Layer 3)

---

## When to Use Each Skill

### Use `/cgc-dev` When:
- Working with CG Cloud objects (RetailStore, Visit, ActionPlan, etc.)
- Building retail execution workflows
- Implementing Trade Promotion Management
- Route planning and visit optimization
- Need domain expertise in CPG business processes

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

## Layer 3: Dynamic Knowledge via NotebookLM

Unlike static reference files, this skill's Layer 3 uses **NotebookLM for dynamic knowledge**:

```
/fsc-dev (Financial Services)
    └── Layer 3: Static reference files (./references/*.md)

/cgc-dev (Consumer Goods)
    └── Layer 3: NotebookLM Notebook (dynamic, always growing)
        Notebook ID: 9ca50af3-1937-43a6-87c4-3d8629a1ccbd
```

**Advantages of NotebookLM-based Layer 3**:
- Sources continuously added (notebook grows over time)
- Always query for latest patterns
- No need to manually update reference files
- AI-generated answers with citations

---

## Skills Hierarchy

```
/architect (Solution Design)
    └── /fullstack-dev (Generic Full-Stack)
            ├── /apex-dev (Backend Specialist)
            ├── /lwc-dev (Frontend Specialist)
            └── Industry Skills (Domain Specialists)
                    ├── /fsc-dev (Financial Services Cloud)
                    ├── /cgc-dev (Consumer Goods Cloud) ← THIS SKILL
                    ├── /health-dev (Health Cloud) [future]
                    └── ... (other industries)
```

---

## Summary

**This skill (`/cgc-dev`) is NOT a standalone entity**. It's a **specialized extension** of `/fullstack-dev` that adds Consumer Goods Cloud domain expertise while inheriting all generic Salesforce capabilities.

**Think of it as**:
- `/fullstack-dev` = Salesforce platform expert
- `/cgc-dev` = Salesforce platform expert **+ Consumer Goods Cloud domain expert**

**Always reference base skills** for generic patterns. This skill focuses exclusively on CG Cloud specializations, with NotebookLM providing dynamic Layer 3 industry knowledge.
