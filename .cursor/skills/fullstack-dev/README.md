# Full-Stack Developer Skill

**Skill Name**: `/fullstack-dev`

Full-stack Salesforce developer for end-to-end feature ownership with expertise in Apex, LWC, and 2026-forward platform capabilities (Agentforce, Data Cloud, External Client Apps, Slack orchestration).

---

## Usage

Invoke the skill in Cursor using:
```
/fullstack-dev
```

Then provide your full-stack development task:
```
"Build customer portal with Agentforce case deflection"
"Implement order management system with Data Cloud integration"
"Create Slack approval workflow with AI recommendations"
```

---

## What This Skill Provides

### End-to-End Ownership
- **Full-Stack Integration**: Apex backend + LWC frontend in a single feature
- **ViewModel Pattern**: Clean contracts between Apex and LWC
- **API Design**: RESTful endpoints that serve LWC components
- **Cross-Layer Testing**: Integration tests spanning Apex + LWC

### 2026-Forward Platform Capabilities
- **Agentforce & Predictive AI**: Atlas Reasoning Engine, RAG with Data Cloud, prompt governance, Einstein Trust Layer, Agentforce 360 observability
- **Data Cloud / Genie**: Zero-copy data grounding, real-time harmonization, unified profiles for AI context
- **External Client Apps**: Spring '26 OAuth 2.0 patterns, migration from ECA
- **Slack-First Orchestration**: Multiplayer workflows (Agents + humans), human-in-the-loop patterns
- **OmniStudio**: OmniScripts, DataRaptors, Integration Procedures

### Strategic Architecture
- **Identity & Access Management**: SSO, MFA, external identity, permission set groups
- **Event-Driven Architecture**: Platform Events, Change Data Capture, Streaming API
- **Large Data Volumes**: Skinny tables, Big Objects, batch processing, Platform Cache
- **Flow Orchestration**: Record-triggered, scheduled, screen, autolaunched flows

### DevOps & CI/CD
- **Copado Pipelines**: Automated deployment with quality gates
- **SFDX**: Source-driven development, scratch orgs, metadata API
- **Deployment Strategies**: Blue-green, canary releases, feature flags

### Soft Skills
- **Tech-to-Biz Translation**: Communicating technical concepts in business terms
- **Mentorship & Delegation**: When to involve specialized skills
- **Context Engineering**: Designing business context for high-ROI AI outputs

### Dynamic Knowledge Integration
- **🆕 NotebookLM**: Queries Well-Architected patterns, accessibility standards, security patterns
- **🆕 Salesforce MCP**: Live org validation (fields, objects, SOQL, limits)
- **Built-In References**: 2026-forward patterns, integration guides, code examples

---

## Core Competencies

### Full-Stack Integration (Expert)
- Backend: Apex service layer, triggers, batch jobs, REST APIs
- Frontend: LWC components, wire adapters, SLDS styling
- Integration: ViewModel pattern, API contracts, error handling
- Testing: Unit tests (Apex + LWC) + integration tests + E2E

**Reference**: `/apex-dev` for deep Apex, `/lwc-dev` for deep LWC, `./references/full-stack-integration.md` for integration patterns

### 2026-Forward Capabilities (Advanced/Intermediate)
- **Agentforce**: Atlas Reasoning, RAG, prompt governance, Trust Layer (`./references/agentforce-patterns.md`)
- **Data Cloud**: Zero-copy queries, performance optimization (`./references/data-cloud-zero-copy.md`)
- **External Client Apps**: OAuth 2.0 migration (`./references/external-client-apps.md`)
- **Slack Orchestration**: Multiplayer workflows (`./references/slack-orchestration.md`)
- **Context Engineering**: AI context design (`./references/context-engineering.md`)

### Strategic Architecture (Expert/Advanced)
- IAM, event-driven, LDV, Flow orchestration
- DevOps: Copado, SFDX, deployment strategies

### Soft Skills (Expert/Advanced)
- Tech-to-biz translation, mentorship, context engineering

---

## Included Resources

### Reference Materials (`./references/`)
- **agentforce-patterns.md** (~300 lines): Atlas Reasoning Engine, RAG, prompt governance, Trust Layer, Agentforce 360
- **external-client-apps.md** (~200 lines): Spring '26 OAuth 2.0 transition, migration guide
- **data-cloud-zero-copy.md** (~250 lines): Zero-copy architecture, query patterns, optimization
- **slack-orchestration.md** (~200 lines): Multiplayer workflows, Slack Actions + Agentforce
- **context-engineering.md** (~250 lines): AI context design, prompt engineering, model evaluation
- **full-stack-integration.md** (~300 lines): ViewModel pattern, API contracts, cross-layer testing

### Shared Knowledge (`../_shared/`)
- **notebooklm-knowledge.md**: Query patterns for Well-Architected knowledge
- **salesforce-mcp-knowledge.md**: Live org validation tools
- **salesforce-mcp-setup.md**: MCP configuration

### Related Skills
- **`/apex-dev`**: Deep backend expertise (triggers, batch, governor limits)
- **`/lwc-dev`**: Deep frontend expertise (SLDS, accessibility, state management)
- **`/architect`**: Solution design, Well-Architected analysis

---

## Communication Style

**Audience**: Expert developers who value efficiency and precision

**Approach**:
- **Code-First**: Working examples, not abstract descriptions
- **Integration-Focused**: Emphasize Apex ↔ LWC contracts
- **End-to-End**: Consider full feature lifecycle (database → API → UI → testing)
- **2026-Forward**: Prioritize modern capabilities (Agentforce, Data Cloud, External Client Apps)
- **Production-Ready**: Security, bulkification, error handling, testing always included

**Format**:
- ✅ CORRECT and ❌ WRONG for clarity
- Before/after code examples
- File paths and line numbers for reference
- Links to detailed references

---

## When to Use This Skill

### Use `/fullstack-dev` when:
✅ **End-to-End Feature** - Backend + frontend in a single feature
- Example: "Build customer portal with case submission and tracking"

✅ **2026-Forward Capabilities** - Agentforce, Data Cloud, External Client Apps, Slack
- Example: "Integrate Agentforce for case deflection"
- Example: "Query Data Cloud for unified customer profiles"
- Example: "Migrate to External Client Apps (Spring '26)"

✅ **Full-Stack Ownership** - Own entire feature from database to UI
- Example: "I need to build discount approval workflow end-to-end"

✅ **Slack Orchestration** - Multiplayer workflows with Agents + humans
- Example: "Create Slack approval workflow with AI recommendations"

✅ **Integration Focus** - Designing clean Apex ↔ LWC contracts
- Example: "Design API for product catalog LWC"

### Use specialized skills when:
- **`/apex-dev`**: Only backend needed (triggers, batch jobs, APIs)
- **`/lwc-dev`**: Only frontend needed (LWC components, SLDS styling)
- **`/architect`**: Only design needed (architecture, patterns, trade-offs)

---

## Example Use Cases

### 1. Build Customer Portal with Agentforce
```
/fullstack-dev

"Build a B2B customer portal where users can:
- View open cases
- Submit new cases
- Get AI-powered case deflection suggestions via Agentforce
- Receive Slack notifications for case updates
Requirements: SSO login, accessible (WCAG 2.1 AA), mobile-responsive"
```

**Expected Output**:
- Apex: CaseService, CaseRestController, Agentforce integration
- LWC: caseList, caseForm, caseDetail components
- Agentforce: RAG with knowledge base, Trust Layer config
- Slack: Notification service with Slack Actions
- Testing: Unit tests + integration tests + E2E scenarios

---

### 2. Implement Data Cloud Integration
```
/fullstack-dev

"Create a dashboard that displays:
- Unified customer profile from Data Cloud (zero-copy query)
- Purchase history, engagement score, sentiment
- Recommendations based on Data Cloud calculated insights
Requirements: Real-time updates, caching for performance"
```

**Expected Output**:
- Apex: DataCloudService with zero-copy queries, caching layer
- LWC: customerProfile dashboard with real-time updates
- Data Cloud: Query patterns, performance optimization
- Testing: Unit tests with mocked Data Cloud responses

---

### 3. Configure External Client App (Spring '26)
```
/fullstack-dev

"Migrate our warehouse integration from Named Credentials to External Client Apps:
- OAuth 2.0 authentication
- Inventory sync API
- Error handling and retry logic
Requirements: Zero downtime migration, backward compatibility during transition"
```

**Expected Output**:
- External Client App configuration
- Updated WarehouseIntegrationService with new OAuth pattern
- Migration plan with rollback strategy
- Testing: Authentication flows, API calls

---

### 4. Create Slack Approval Workflow with AI
```
/fullstack-dev

"Build a discount approval workflow:
- Sales rep requests discount approval
- Agentforce analyzes deal and provides recommendation
- Slack notification sent to manager with approval buttons
- Manager approves/rejects in Slack
- Opportunity updated in Salesforce
Requirements: Human-in-the-loop, audit trail"
```

**Expected Output**:
- Apex: DiscountApprovalService, Agentforce integration, Slack API
- LWC: discountRequestForm component
- Slack: Multiplayer workflow with approval actions
- Agentforce: Deal analysis with context engineering
- Testing: End-to-end approval scenarios

---

### 5. Build Order Management System
```
/fullstack-dev

"Implement order management with:
- Product catalog browsing
- Order creation with line items
- Payment processing integration
- Order tracking and history
Requirements: Bulkified, secure (CRUD/FLS), 75%+ test coverage"
```

**Expected Output**:
- Apex: OrderService, PaymentService, REST APIs
- LWC: productCatalog, orderForm, orderList, orderDetail
- Integration: ViewModel pattern, consistent error handling
- Testing: Unit tests (200+ records), integration tests, E2E flows

---

## Testing the Skill

### 1. Test Skill Invocation
```
In Cursor IDE:
1. Type `/fullstack-dev`
2. Provide a task: "Build customer portal with case management"
3. Verify: Agent responds with full-stack guidance (Apex + LWC + testing)
```

### 2. Test 2026-Forward Knowledge
```
In Cursor IDE:
1. Type `/fullstack-dev`
2. Ask: "How do I integrate Agentforce with Data Cloud for RAG?"
3. Verify: References ./references/agentforce-patterns.md and provides code examples
```

### 3. Test Delegation
```
In Cursor IDE:
1. Type `/fullstack-dev`
2. Ask: "Optimize trigger hitting SOQL limits"
3. Verify: Suggests delegating to `/apex-dev` for deep optimization
```

### 4. Test Integration Patterns
```
In Cursor IDE:
1. Type `/fullstack-dev`
2. Ask: "Design API contract for LWC product catalog"
3. Verify: Provides ViewModel pattern, REST endpoints, error handling
```

---

## Next Steps

### Phase 1: Core Implementation ✅
- [x] SKILL.md created with all competencies
- [x] README.md created with usage guide
- [ ] Reference files created (6 files)
- [ ] Astro routing logic updated

### Phase 2: Integration Testing
- Test skill invocation in Cursor
- Verify reference files are accessible
- Test Astro routing for full-stack requests
- Validate content quality (no duplication)

### Phase 3: Industry Cloud Specializations (Future)
- Financial Services Cloud Developer (`/fsc-dev`)
- Health Cloud Developer (`/health-dev`)
- Field Service Developer (`/fs-dev`)
- Communications Cloud Developer (`/comm-dev`)
- Manufacturing Cloud Developer (`/mfg-dev`)

See **`.cursor/skills/FULLSTACK_DEVELOPER_STRATEGY.md`** for the complete roadmap.

---

## Support

For questions or issues:
1. Invoke `/fullstack-dev` and describe your use case
2. Check reference materials in `./references/`
3. Review shared knowledge in `../_shared/`
4. Consult related skills: `/apex-dev`, `/lwc-dev`, `/architect`
5. Review foundation rules in `../../rules/`
6. Check the master strategy document: `../FULLSTACK_DEVELOPER_STRATEGY.md`

---

## Version

**Created**: 2026-03-01
**Status**: Active
**Extends**: N/A (Base skill)
**Extended By**: Future industry cloud specialists (FSC, Health, Field Service, etc.)
