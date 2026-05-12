# Consumer Goods Cloud Full-Stack Developer (`/cgc-dev`)

## Overview

This skill provides expert-level Consumer Goods Cloud development capabilities, combining:
- **Generic Salesforce Expertise** (from `/fullstack-dev`): Apex, LWC, Agentforce, Data Cloud, testing
- **Consumer Goods Cloud Specialization**: Industry data models, retail execution, trade promotion management

**Developer**: Nisha (5 years CG Cloud experience)

**When to Use**: Invoke `/cgc-dev` for Consumer Goods Cloud-specific feature development.

**When to Delegate**:
- Generic Salesforce development → `/fullstack-dev`
- Architecture design → `/architect`
- Deep Apex optimization → `/apex-dev`
- Complex LWC patterns → `/lwc-dev`
- Complex integrations → `/integration-architect`

---

## Key Capabilities

### Consumer Goods Cloud Data Models

Expert knowledge of CG Cloud objects:
- **RetailStore**: Physical retail locations where products are sold
- **Visit**: Field representative visits to retail stores
- **ActionPlan**: Template-driven execution plans for store visits
- **AssessmentTask**: Audit/assessment activities during visits
- **AssessmentIndicatorDefinition**: Measurement criteria for assessments
- **StoreProduct**: Junction linking products to stores (assortment/distribution)

**Knowledge Source**: NotebookLM Notebook `9ca50af3-1937-43a6-87c4-3d8629a1ccbd`

---

### Trade Promotion Management

Deep understanding of TPM/TPO workflows:
- Trade promotion planning and budgeting
- Fund management and accrual processing
- Promotion performance analytics (ROI, lift analysis)
- Deduction management and settlement
- Trade Promotion Optimization with AI

---

### Retail Execution

Expert in field operations:
- Store visit planning and execution
- Planogram compliance verification
- Shelf space and share-of-shelf analysis
- Photo capture and image recognition
- Merchandising task management

---

### External Integrations

Experience with industry-standard integrations:
- **ERP System** (REST/SOAP): Product master data, orders, inventory
- **DSD System** (REST): Van loading, delivery, invoicing
- **Planogram Tools** (REST): Shelf compliance, image recognition
- **Distributor Management** (REST/SFTP): Orders, sell-through data

---

### Industry-Specific Competencies

#### Retail Execution (Expert)
- Store visit workflows, audit management, planogram compliance
- Photo capture, GPS verification, task automation

#### Trade Promotion Management (Expert)
- Promotion planning, fund management, ROI analytics
- Deduction management, TPO with AI

#### Route Planning & Optimization (Advanced)
- Territory-based routing, visit priority scoring
- Dynamic re-routing, GPS verification

#### Inventory & Order Management (Advanced)
- DSD workflows, van inventory, suggested orders
- Stock monitoring, returns processing

#### Field Force Automation (Expert)
- Offline-first mobile apps, guided selling
- Performance dashboards, coaching tools

---

## Common Use Cases

### 0. Store Visit Execution
End-to-end visit workflow: arrival, task execution, audit, departure.
**Technical Stack**: LWC mobile wizard, offline ActionPlan execution, GPS check-in/out, photo capture, Agentforce insights

### 1. Trade Promotion Dashboard
Interactive dashboard for promotion planning, execution, and ROI.
**Technical Stack**: LWC dashboard, Apex batch for ROI, Data Cloud analytics, fund management automation

### 2. Planogram Compliance Assessment
Automated shelf compliance with image recognition.
**Technical Stack**: Image capture LWC, Einstein Vision, AssessmentTask automation, compliance scoring

### 3. Route Optimization Engine
Intelligent route planning for field representatives.
**Technical Stack**: Batch Apex route calculation, mapping API integration, LWC map visualization

### 4. Distributor Order Management
Order capture and fulfillment for distributor network.
**Technical Stack**: Mobile LWC order entry, suggested order algorithm, ERP integration

---

## Technical Stack

### Backend (Apex)
- CG Cloud object operations and relationships
- Business logic (visit workflows, promotion calculations)
- Integration services (ERP, DSD, planogram)
- Batch processing for route optimization
- Offline sync conflict resolution

### Frontend (LWC)
- Mobile-optimized field rep experience
- Offline-capable components
- Data visualization (charts, maps)
- Photo capture and GPS integration

### AI & Automation (Agentforce)
- Context engineering for CG Cloud
- Trust Layer with CPG data governance
- RAG with Data Cloud grounding
- Visit insights and recommendations

### Data Platform (Data Cloud)
- Zero-copy retail analytics
- Real-time inventory ingestion
- Promotion performance tracking
- Cross-store analytics

---

## Layer 3: NotebookLM Integration

This skill uses **NotebookLM as the primary Layer 3 knowledge source**:

- **Notebook ID**: `9ca50af3-1937-43a6-87c4-3d8629a1ccbd`
- **Scope**: Comprehensive CG Cloud knowledge
- **Dynamic**: Sources are continuously added
- **Approach**: NotebookLM-first with built-in fallback

### How It Works

1. Task received with CG Cloud context
2. Nisha queries NotebookLM for relevant patterns
3. If available: applies latest patterns from notebook
4. If unavailable: uses built-in knowledge in SKILL.md
5. Always notes which source was used

### Example Queries

```
"What is the relationship between Visit and ActionPlan?"
"How should trade promotion funds be accrued?"
"Best practice for planogram compliance assessment?"
"Integration patterns for ERP order sync?"
```

---

## File Structure

```
cgc-dev/
├── SKILL.md          # Main skill definition (used by AI)
├── README.md         # Human-readable documentation (you are here)
└── EXTENDS.md        # How this extends /fullstack-dev
```

---

## Quick Start

### 1. Invoke the Skill

```bash
/cgc-dev "Build Store Visit Execution workflow"
```

### 2. Expected Behavior

The AI will:
1. Query NotebookLM for CG Cloud visit patterns
2. Reference correct data models (Visit, RetailStore, ActionPlan)
3. Design for offline-first (field rep mobile use)
4. Implement full-stack solution (Apex + LWC)
5. Provide test coverage (75%+)

### 3. Example Output

- Apex controller with `with sharing` and `SECURITY_ENFORCED`
- LWC components (offline-capable, mobile-optimized)
- Test class with CG Cloud test data factory
- Integration patterns for external systems

---

## Routing Indicators

Astro will automatically route to `/cgc-dev` when it detects:

- "consumer goods", "CG Cloud"
- "retail execution", "retail store"
- "trade promotion", "TPM", "TPO"
- "visit planning", "store visit"
- "action plan", "planogram"
- "route optimization", "field rep"
- "DSD", "direct store delivery"
- "inventory management", "van inventory"
- "store audit", "shelf compliance"
- "product assortment"

**Manual Invocation**: Use `/cgc-dev` directly for explicit routing.

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

## Best Practices

1. **Always query NotebookLM first** for CG Cloud patterns
2. **Use CG Cloud standard objects** (not custom recreations)
3. **Design offline-first** for field rep mobile apps
4. **Use ViewModel pattern** for Apex-LWC contracts
5. **Enforce sharing and FLS** with `with sharing` and `SECURITY_ENFORCED`
6. **Test thoroughly**: 75%+ coverage with bulk visit scenarios
7. **Consider mobile UX**: field reps work on phones in stores

---

## Version History

- **Created**: 2026-03-03
- **Industry**: Consumer Goods Cloud
- **Base Skill**: `/fullstack-dev`
- **Layer 3 Source**: NotebookLM `9ca50af3-1937-43a6-87c4-3d8629a1ccbd`
- **Specializations**: 5 competency areas, 6 data models, 4 integration types
