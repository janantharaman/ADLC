# Agent Astro: Program Manager Mode

## Overview

When facing **complex, multi-component tasks**, Agent Astro transforms into a **Program Manager** that:
1. **Decomposes** complex requirements into logical subtasks
2. **Dynamically allocates** specialized developer agents (multiple devs of same type if needed)
3. **Manages dependencies** between subtasks (parallel vs sequential execution)
4. **Coordinates integration** across all components
5. **Validates production-readiness** with comprehensive testing and review

**Inspired by**: ChatDev's multi-agent approach + Cursor's power

---

## When to Activate Program Manager Mode

### Triggers (Automatic Detection)

Astro activates Program Manager mode when requirements meet **2+ criteria**:

1. **Multiple domains**: Backend + Frontend + Admin + Integration + Testing
2. **Large scope**: >5 components or >40 hours estimated effort
3. **Complex dependencies**: Component A must complete before Component B
4. **Multiple work streams**: Parallelizable subtasks (e.g., Orders API + Products API)
5. **Production-critical**: Payment processing, security, compliance, data migration

### Examples

✅ **Activate Program Manager Mode**:
- "Build complete order management system with inventory, payments, and fulfillment"
- "Migrate legacy system to Salesforce with 10+ custom objects and integrations"
- "Create multi-tenant portal with role-based access, dashboards, and reporting"

❌ **Use Standard Orchestration**:
- "Build customer portal with case management" (2 agents sufficient)
- "Create discount approval workflow" (1 agent sufficient)

---

## Phase 1: Requirement Analysis & Decomposition

### Step 1.1: Analyze Complexity

Astro evaluates:
- **Domains involved**: Backend, Frontend, Admin, Integration, Testing, etc.
- **Component count**: How many APIs, LWCs, flows, integrations?
- **Dependencies**: Sequential (A→B→C) vs Parallel (A || B || C)
- **Risk factors**: Security, performance, data volume, third-party dependencies

### Step 1.2: Ask Strategic Questions

Unlike simple orchestration, Astro asks **architecture-level questions**:

```
REQUIREMENT ANALYSIS:
I've identified this as a complex, multi-domain project requiring:
- 3 Backend developers (Order API, Payment API, Inventory batch job)
- 2 Frontend developers (Customer portal, Admin dashboard)
- 1 Admin configurator (Approval flows, validation rules)
- 1 QA engineer (End-to-end testing)

Before I decompose, let me clarify:

Q1: What are the CRITICAL requirements that block everything else?
    (e.g., data model, authentication, third-party API contracts)

Q2: What's the priority order?
    A) All features simultaneously (maximize parallel work)
    B) MVP first (order processing), then enhancements (inventory, reporting)
    C) Critical path first (payment integration, then UI)

Q3: Are there existing systems/APIs we must integrate with?
    A) Yes → [User provides details]
    B) No → We design from scratch

Q4: What's the deployment strategy?
    A) Big bang (deploy everything at once)
    B) Phased (deploy backend first, then frontend)
    C) Feature flags (deploy dark, enable progressively)
```

### Step 1.3: Create Task Decomposition Tree

Astro creates a **hierarchical breakdown**:

```
PROJECT: Order Management System

PHASE 1: Foundation (Sequential - must complete first)
├── Task 1.1: Data Model Design [Architect]
│   └── Objects: Order, OrderItem, Product, Payment, Shipment
├── Task 1.2: Security Architecture [Architect]
│   └── Sharing rules, CRUD/FLS, API authentication
└── Task 1.3: API Contract Specification [Architect]
    └── REST endpoints, schemas, error codes

PHASE 2: Backend Development (Parallel after Phase 1)
├── Task 2.1: Order API [Backend Dev 1]
│   ├── POST /orders (create order)
│   ├── GET /orders/{id} (retrieve order)
│   ├── PUT /orders/{id} (update order)
│   └── Tests: Bulk, CRUD/FLS, edge cases
├── Task 2.2: Payment API [Backend Dev 2]
│   ├── POST /payments (process payment)
│   ├── GET /payments/{id} (payment status)
│   ├── Integration: Stripe API callout
│   └── Tests: Success, failure, timeout scenarios
└── Task 2.3: Inventory Batch Job [Backend Dev 3]
    ├── Scheduled Apex: Daily inventory sync
    ├── Integration: External warehouse API
    └── Tests: Bulk (10K+ records), error handling

PHASE 3: Frontend Development (Parallel with Phase 2)
├── Task 3.1: Order Management UI [Frontend Dev 1]
│   ├── OrderList.lwc (display orders)
│   ├── OrderDetail.lwc (view/edit order)
│   ├── OrderForm.lwc (create order)
│   └── Tests: Jest, accessibility
└── Task 3.2: Admin Dashboard [Frontend Dev 2]
    ├── Dashboard.lwc (order analytics)
    ├── ReportViewer.lwc (reports)
    └── Tests: Jest, data visualization

PHASE 4: Configuration (Parallel with Phase 2/3)
└── Task 4.1: Approval Flows [Admin]
    ├── Order approval process (>$10K requires approval)
    ├── Payment retry flow
    └── Validation rules (order total, payment amount)

PHASE 5: Integration Testing (After Phase 2/3/4)
└── Task 5.1: End-to-End Testing [QA]
    ├── Create order → Process payment → Update inventory
    ├── Error scenarios (payment failure, inventory shortage)
    └── Performance testing (100+ concurrent orders)

PHASE 6: Production Readiness (After Phase 5)
└── Task 6.1: Final Review [Program Manager - Astro]
    ├── Integration validation (APIs match UIs)
    ├── Security audit (CRUD/FLS, API auth)
    ├── Performance validation (bulk operations)
    └── Documentation review
```

### Step 1.4: Identify Dependencies

Astro creates a **dependency graph**:

```
[Task 1.1, 1.2, 1.3] → Sequential (Foundation)
       ↓
[Task 2.1, 2.2, 2.3] || [Task 3.1, 3.2] || [Task 4.1] → Parallel (Implementation)
       ↓
[Task 5.1] → Sequential (Integration Testing)
       ↓
[Task 6.1] → Sequential (Final Review)
```

---

## Phase 2: Agent Allocation & Assignment

### Step 2.1: Determine Agent Requirements

Astro calculates:
- **How many agents per skill type**:
  - Backend: 3 (Order API, Payment API, Inventory batch)
  - Frontend: 2 (Customer portal, Admin dashboard)
  - Admin: 1 (Approval flows)
  - QA: 1 (End-to-end testing)
  - Architect: 1 (Foundation design)

- **Specialization per agent**:
  - Backend Dev 1: REST APIs (Order)
  - Backend Dev 2: REST APIs + External integration (Payment)
  - Backend Dev 3: Batch processing (Inventory)

### Step 2.2: Create Specialized Agent Prompts

Instead of generic "You are /apex-dev", Astro creates **role-specific prompts**:

**Backend Dev 1 (Order API)**:
```
AGENT ROLE: Backend Developer - Order Management Specialist

You are acting as an expert Apex developer specializing in ORDER MANAGEMENT.
Read .cursor/skills/apex-developer/SKILL.md for your persona.

YOUR SPECIALIZATION: REST APIs for Order object

ARCHITECTURAL CONTEXT:
[Shared foundation from Phase 1]
- Data Model: Order, OrderItem, Product
- Security: CRUD/FLS, API authentication
- API Standards: REST, JSON, HTTP status codes

YOUR SPECIFIC TASK:
Build REST API for Order management with these endpoints:
1. POST /services/apexrest/orders
   - Create order with line items
   - Validate: Product availability, pricing
   - Return: Order ID, order number, status

2. GET /services/apexrest/orders/{id}
   - Retrieve order with line items
   - Include: Product details, totals
   - Security: User can only see their own orders

3. PUT /services/apexrest/orders/{id}
   - Update order status, line items
   - Business rules: Cannot update if status = "Shipped"
   - Validate: Inventory availability

INTEGRATION POINTS:
- Your API will be consumed by: OrderList.lwc, OrderDetail.lwc (Frontend Dev 1)
- You will call: Payment API (Backend Dev 2) for payment processing
- Your data will be used by: Inventory batch job (Backend Dev 3)

DEPENDENCIES:
- WAIT FOR: Data model design (Task 1.1) ← Must complete first
- PARALLEL WITH: Payment API (Backend Dev 2), Frontend Dev 1, Admin
- BLOCKING: Integration testing (Task 5.1) ← Cannot start until you complete

DELIVERABLES:
1. OrderRestController.cls (REST API class)
2. OrderService.cls (Business logic)
3. OrderRestController_Test.cls (75%+ coverage)
4. API documentation (endpoints, schemas, error codes)

QUALITY GATES:
- Bulkification: Handle 200+ orders in single request
- Security: CRUD/FLS checks on Order, OrderItem, Product
- Error handling: All scenarios (validation, permission, system)
- Testing: Positive, negative, bulk, edge cases

OUTPUT FORMAT:
When complete, provide:
- Code files (cls files)
- API documentation (Markdown)
- Test results (coverage %, scenarios tested)
- Integration notes (what other agents need to know)
```

**Backend Dev 2 (Payment API)**:
```
AGENT ROLE: Backend Developer - Payment Integration Specialist

You are acting as an expert Apex developer specializing in PAYMENT PROCESSING & EXTERNAL INTEGRATIONS.
Read .cursor/skills/apex-developer/SKILL.md for your persona.

YOUR SPECIALIZATION: Payment API + Stripe integration

ARCHITECTURAL CONTEXT:
[Same shared foundation]

YOUR SPECIFIC TASK:
Build Payment API with Stripe integration:
1. POST /services/apexrest/payments
   - Process payment via Stripe
   - Handle: Success, failure, timeout scenarios
   - Store: Payment record with transaction ID

2. GET /services/apexrest/payments/{id}
   - Retrieve payment status
   - Check: Stripe API for real-time status

EXTERNAL INTEGRATION:
- Third-party: Stripe API
- Authentication: Named Credential (Stripe_API)
- Callout handling: @future method, timeout handling, retry logic

INTEGRATION POINTS:
- Called by: Order API (Backend Dev 1) when order is placed
- Data used by: Admin Dashboard (Frontend Dev 2) for payment analytics

DEPENDENCIES:
- WAIT FOR: Security architecture (Task 1.2) ← Must define API auth first
- PARALLEL WITH: Order API (Backend Dev 1), Inventory batch (Backend Dev 3)

DELIVERABLES:
1. PaymentRestController.cls
2. StripeIntegrationService.cls (callout logic)
3. PaymentRestController_Test.cls (mock callouts, all scenarios)
4. Named Credential setup guide

QUALITY GATES:
- Callout handling: Timeout, retry, error scenarios
- Security: API authentication, Stripe key management
- Testing: Mock all Stripe responses (success, failure, timeout)
```

**Frontend Dev 1 (Customer Portal)**:
```
AGENT ROLE: Frontend Developer - Customer Portal Specialist

You are acting as an expert LWC developer specializing in CUSTOMER-FACING UIs.
Read .cursor/skills/lwc-developer/SKILL.md for your persona.

YOUR SPECIALIZATION: Customer portal for order management

ARCHITECTURAL CONTEXT:
[Same shared foundation]

YOUR SPECIFIC TASK:
Build customer portal components:
1. OrderList.lwc - Display user's orders
2. OrderDetail.lwc - View/edit single order
3. OrderForm.lwc - Create new order

API INTEGRATION:
- Consume: Order API endpoints (Backend Dev 1)
  - GET /services/apexrest/orders
  - POST /services/apexrest/orders
  - PUT /services/apexrest/orders/{id}

INTEGRATION POINTS:
- Backend: Order API (Backend Dev 1) ← Your primary integration
- Backend: Payment API (Backend Dev 2) ← For payment status display

DEPENDENCIES:
- WAIT FOR: API contract specification (Task 1.3) ← Must know endpoints/schemas
- PARALLEL WITH: Backend Dev 1, Backend Dev 2, Frontend Dev 2

DELIVERABLES:
1. OrderList.lwc (JS, HTML, CSS)
2. OrderDetail.lwc (JS, HTML, CSS)
3. OrderForm.lwc (JS, HTML, CSS)
4. Jest tests (all components, accessibility)

QUALITY GATES:
- Accessibility: WCAG 2.1 AA compliance
- SLDS: Follow Salesforce Lightning Design System
- Error handling: Display all backend errors gracefully
- Testing: Jest tests + keyboard navigation
```

### Step 2.3: Create Shared Context Document

Astro creates a **single source of truth** shared by ALL agents:

```markdown
# Shared Context: Order Management System

## Data Model (Phase 1.1 - COMPLETED)
[Data model details...]

## Security Architecture (Phase 1.2 - COMPLETED)
[Security details...]

## API Contracts (Phase 1.3 - COMPLETED)
[API specifications...]

## Integration Map
- Order API (Backend Dev 1) → Called by OrderList.lwc, OrderDetail.lwc
- Payment API (Backend Dev 2) → Called by Order API, displayed in Admin Dashboard
- Inventory Batch (Backend Dev 3) → Reads Order data, updates Product inventory

## Error Handling Standards
[Shared error codes, formats...]

## Testing Requirements
[Shared testing standards...]
```

---

## Phase 3: Parallel Execution with Dependency Management

### Step 3.1: Execute Phase 1 (Foundation) - Sequential

Astro spawns **Architect agent** to complete foundation:

```
[Architect Agent] → Task 1.1, 1.2, 1.3
   ↓ COMPLETED
[Updates Shared Context Document]
   ↓
[User Approval Gate: "Foundation ready. Approve to proceed?"]
```

### Step 3.2: Execute Phase 2/3/4 (Implementation) - Parallel

After foundation approval, Astro spawns **7 agents simultaneously**:

```
Parallel Execution:
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ Backend Dev 1   │ │ Backend Dev 2   │ │ Backend Dev 3   │
│ (Order API)     │ │ (Payment API)   │ │ (Inventory)     │
└─────────────────┘ └─────────────────┘ └─────────────────┘
┌─────────────────┐ ┌─────────────────┐
│ Frontend Dev 1  │ │ Frontend Dev 2  │
│ (Customer UI)   │ │ (Admin UI)      │
└─────────────────┘ └─────────────────┘
┌─────────────────┐
│ Admin           │
│ (Flows)         │
└─────────────────┘

All execute independently with shared context
```

### Step 3.3: Monitor Progress & Collect Outputs

Astro tracks:
- Which agents have completed
- What each agent delivered
- Any errors or blockers reported

**Output Collection**:
```
Backend Dev 1 COMPLETED:
- OrderRestController.cls (300 lines)
- OrderService.cls (200 lines)
- OrderRestController_Test.cls (85% coverage)
- API docs

Backend Dev 2 COMPLETED:
- PaymentRestController.cls (250 lines)
- StripeIntegrationService.cls (150 lines)
- Tests (mock callouts, 80% coverage)

Frontend Dev 1 COMPLETED:
- OrderList.lwc (3 files)
- OrderDetail.lwc (3 files)
- OrderForm.lwc (3 files)
- Jest tests

[... all agents complete ...]
```

---

## Phase 4: Integration Validation & Code Review

### Step 4.1: Cross-Component Integration Validation

Astro validates **integration across all components**:

#### Validation 1: API Contract Consistency
```
CHECK: Backend Dev 1 (Order API) ↔ Frontend Dev 1 (Customer UI)

Backend declares:
  POST /services/apexrest/orders
  Request: {products: [{id, quantity, price}], shippingAddress: {...}}
  Response: {orderId, orderNumber, status, total}

Frontend calls:
  POST /services/apexrest/orders
  Sends: {products: [{id, quantity, price}], shippingAddress: {...}}
  Expects: {orderId, orderNumber, status, total}

✅ MATCH - Contracts aligned
```

#### Validation 2: Cross-Agent Dependencies
```
CHECK: Backend Dev 1 (Order API) → Backend Dev 2 (Payment API)

Order API creates order:
  Then calls: POST /services/apexrest/payments
  Sends: {orderId, amount, paymentMethod}

Payment API expects:
  POST /services/apexrest/payments
  Request: {orderId, amount, paymentMethod}

✅ MATCH - Integration point valid
```

#### Validation 3: Data Flow Consistency
```
CHECK: Backend Dev 3 (Inventory Batch) reads Order data

Inventory Batch queries:
  SELECT Id, (SELECT ProductId, Quantity FROM OrderItems) FROM Order

Order API creates:
  Order + OrderItem records with ProductId, Quantity

✅ MATCH - Data structure consistent
```

### Step 4.2: Code Review for Consistency

Astro performs **cross-agent code review**:

#### Review 1: Naming Conventions
```
CHECK: All agents follow same naming conventions

Backend Dev 1: OrderService.cls, OrderRestController.cls
Backend Dev 2: PaymentService.cls, PaymentRestController.cls
Backend Dev 3: InventoryBatchJob.cls

✅ CONSISTENT - Pattern: [Domain]Service, [Domain]RestController, [Domain]BatchJob
```

#### Review 2: Error Handling Patterns
```
CHECK: All agents use same error format

Backend Dev 1: Returns {error: "message", code: "ORD-001"}
Backend Dev 2: Returns {error: "message", code: "PAY-001"}
Frontend Dev 1: Catches {error, code} and displays error

✅ CONSISTENT - Error format unified across all agents
```

#### Review 3: Security Implementation
```
CHECK: All agents implement CRUD/FLS

Backend Dev 1: WITH SECURITY_ENFORCED in SOQL
Backend Dev 2: Schema.sObjectType.Payment__c.isCreateable()
Backend Dev 3: Database.insert(records, AccessLevel.USER_MODE)

✅ CONSISTENT - All use platform security
```

### Step 4.3: Identify Conflicts or Gaps

Astro detects **issues requiring resolution**:

```
⚠️ CONFLICT DETECTED:

ISSUE: Frontend Dev 1 expects field "orderStatus" (camelCase)
       Backend Dev 1 returns field "order_status" (snake_case)

IMPACT: Frontend will fail to parse response

RESOLUTION OPTIONS:
1. Modify Backend: Change to camelCase (breaks convention)
2. Modify Frontend: Accept snake_case (requires mapping)
3. Create adapter: Transform in middleware (overhead)

RECOMMENDATION: Option 2 (modify frontend with field mapping)

[Present to user for decision]
```

---

## Phase 5: Integration Testing

### Step 5.1: Spawn QA Agent

After Phase 4 validation, Astro spawns **QA agent**:

```
AGENT ROLE: QA Engineer - End-to-End Testing Specialist

YOUR TASK:
Create comprehensive integration tests for Order Management System

TEST SCENARIOS:
1. Happy Path: Create order → Process payment → Update inventory
   - User creates order with 3 products
   - Payment processes successfully via Stripe
   - Inventory decrements for all products
   - Order status updates to "Confirmed"

2. Error Path: Payment failure
   - User creates order
   - Stripe returns payment failure
   - Order status remains "Pending"
   - User sees error message in UI

3. Edge Case: Inventory shortage
   - User creates order
   - Product quantity insufficient
   - Order creation fails with error
   - User sees "Out of stock" message

4. Performance: 100 concurrent orders
   - Simulate 100 users creating orders simultaneously
   - Verify: All orders process without timeout
   - Verify: No governor limit errors

INTEGRATION POINTS:
Test ALL agent outputs:
- Backend Dev 1: Order API
- Backend Dev 2: Payment API
- Backend Dev 3: Inventory batch
- Frontend Dev 1: Customer UI
- Frontend Dev 2: Admin dashboard
- Admin: Approval flows

DELIVERABLES:
1. Integration test scripts (Apex test classes)
2. UI automation tests (if applicable)
3. Performance test results
4. Bug report (if any issues found)
```

### Step 5.2: Execute Integration Tests

QA agent runs tests and reports results:

```
INTEGRATION TEST RESULTS:

✅ PASSED (12 tests):
- Happy path: Create order → Payment → Inventory
- Error handling: Payment failure, inventory shortage
- Bulk operations: 200 orders processed
- UI integration: All components display correctly

⚠️ ISSUES FOUND (2):
1. Performance: 100 concurrent orders → 3 timeouts
   - Root cause: Inventory batch job not bulkified for high volume
   - Recommendation: Backend Dev 3 should optimize batch job

2. UI Bug: Admin dashboard shows $0.00 for pending payments
   - Root cause: Frontend Dev 2 doesn't handle null payment amounts
   - Recommendation: Add null check in AdminDashboard.lwc

ACTION REQUIRED:
- Fix issues above before production deployment
- Re-run integration tests after fixes
```

---

## Phase 6: Final Review & Production Readiness

### Step 6.1: Astro's Program Manager Review

Astro performs **final audit**:

#### Security Audit
```
SECURITY REVIEW:

✅ CRUD/FLS: All agents implement security checks
✅ API Authentication: Order API, Payment API use OAuth
✅ Data Sharing: Portal users see only their own orders
✅ Sensitive Data: Payment details encrypted at rest
✅ Audit Trail: All changes logged to custom object

SECURITY SCORE: 95/100
```

#### Performance Validation
```
PERFORMANCE REVIEW:

✅ Bulk Operations: All APIs handle 200+ records
✅ SOQL Queries: All selective, no SOQL in loops
✅ Callouts: Payment API uses @future, handles timeouts
⚠️ Batch Job: Inventory batch needs optimization (from QA findings)

PERFORMANCE SCORE: 85/100 (pending batch optimization)
```

#### Documentation Completeness
```
DOCUMENTATION REVIEW:

✅ API Documentation: All endpoints documented
✅ Code Comments: All classes have JSDoc/ApexDoc
✅ README: Deployment guide, testing guide
✅ Architecture Diagram: Data flow, integration points
✅ Runbook: Troubleshooting, monitoring

DOCUMENTATION SCORE: 100/100
```

### Step 6.2: Fix Issues & Re-Validate

Astro spawns **targeted agents** to fix issues:

```
[Backend Dev 3] → Fix batch job performance
   ↓ FIXED
[QA Agent] → Re-run performance tests
   ↓ PASSED
[Astro] → Update final review
```

### Step 6.3: Delivery Package

Astro prepares **complete delivery**:

```
✅ ORDER MANAGEMENT SYSTEM - PRODUCTION READY

DELIVERABLES:
1. Backend Code (3 developers):
   - OrderRestController.cls, OrderService.cls, Tests
   - PaymentRestController.cls, StripeIntegrationService.cls, Tests
   - InventoryBatchJob.cls, InventoryService.cls, Tests

2. Frontend Code (2 developers):
   - Customer Portal: OrderList.lwc, OrderDetail.lwc, OrderForm.lwc
   - Admin Dashboard: Dashboard.lwc, ReportViewer.lwc

3. Configuration (1 admin):
   - Order approval process
   - Payment retry flow
   - Validation rules

4. Testing (1 QA):
   - Integration test suite (12 scenarios)
   - Performance test results
   - Bug fixes validated

5. Documentation:
   - API documentation
   - Deployment guide
   - Testing guide
   - Runbook

QUALITY METRICS:
- Test Coverage: 85% (exceeds 75% requirement)
- Security Score: 95/100
- Performance Score: 95/100 (after optimization)
- Documentation: 100/100

DEPLOYMENT PLAN:
Phase 1: Deploy backend (Order API, Payment API)
Phase 2: Deploy batch job (scheduled for midnight)
Phase 3: Deploy frontend (Customer portal, Admin dashboard)
Phase 4: Enable approval flows
Phase 5: Production smoke test

ESTIMATED DEPLOYMENT TIME: 2 hours
ROLLBACK PLAN: Included in deployment guide

TEAM EFFORT:
- 8 agents (Architect, 3 Backend, 2 Frontend, 1 Admin, 1 QA)
- Total time: 4 hours (vs 20+ hours if sequential)
- Time savings: 80% through parallel execution

READY TO DEPLOY? [Yes/No]
```

---

## Summary: Program Manager Mode vs Standard Orchestration

| Aspect | Standard Orchestration | Program Manager Mode |
|--------|----------------------|---------------------|
| **Task Complexity** | Simple (2-3 agents) | Complex (5+ agents) |
| **Agent Allocation** | Fixed (1 per skill type) | Dynamic (multiple per type) |
| **Task Decomposition** | Manual | Automatic hierarchical breakdown |
| **Dependencies** | Simple (parallel or sequential) | Complex graph (phases, blockers) |
| **Integration Validation** | API contracts only | Cross-component, code review, testing |
| **Quality Gates** | Basic validation | Production-level audit (security, performance, docs) |
| **Team Coordination** | Minimal | Full program management (assignments, progress tracking) |
| **Delivery** | Code + tests | Complete system + deployment plan + runbook |

---

## Example Invocation

```bash
/astro "Build complete order management system with inventory, payments via Stripe, customer portal, admin dashboard, and approval workflows"
```

**Astro Response**:
```
Hi! I've analyzed your requirement - this is a COMPLEX, MULTI-DOMAIN PROJECT.

I'm activating PROGRAM MANAGER MODE to coordinate this properly.

INITIAL ANALYSIS:
- Domains: Backend (3), Frontend (2), Admin (1), QA (1)
- Estimated scope: 50+ hours if sequential
- Complexity: High (external integration, payments, multi-tenant)

I'll need to:
1. Decompose into phases and subtasks
2. Design foundation (data model, security, APIs)
3. Allocate 8 specialized developer agents
4. Coordinate parallel execution with dependency management
5. Validate integration across all components
6. Perform production-level testing and review

ESTIMATED TIME: 4-6 hours with parallel execution
ESTIMATED TEAM: 8 specialized agents

Let me ask some strategic questions first...

[Proceeds with Phase 1...]
```

---

## Implementation Notes

### Dynamic Agent Creation Pattern

Instead of hardcoded:
```javascript
// ❌ OLD: Fixed allocation
if (needsBackend) spawn("/apex-dev")
if (needsFrontend) spawn("/lwc-dev")
```

Use dynamic:
```javascript
// ✅ NEW: Dynamic allocation based on task decomposition
const backendTasks = ["Order API", "Payment API", "Inventory Batch"]
backendTasks.forEach((task, index) => {
  spawnAgent({
    type: "apex-dev",
    role: `Backend Developer ${index + 1}`,
    specialization: task,
    context: sharedContext,
    dependencies: taskDependencies[task]
  })
})
```

### Dependency Management

Use **task graph** to determine execution order:
```
Phase 1 → MUST COMPLETE → Phase 2 || Phase 3 → MUST COMPLETE → Phase 4
```

### Shared Context Updates

All agents read/write to shared context:
- **Read**: Get foundation decisions (data model, APIs)
- **Write**: Report completion, integration notes, blockers

### Integration Validation Framework

After parallel execution, validate:
1. API contracts match (endpoints, schemas, error codes)
2. Data structures consistent (field names, types)
3. Error handling unified (formats, codes)
4. Security patterns consistent (CRUD/FLS, sharing)
5. Code conventions aligned (naming, structure)
6. Dependencies satisfied (A calls B correctly)

---

This Program Manager Mode transforms Astro from a simple orchestrator into a **sophisticated project coordinator** capable of handling enterprise-scale complexity with multiple specialized developers, just like ChatDev but with Cursor's power!
