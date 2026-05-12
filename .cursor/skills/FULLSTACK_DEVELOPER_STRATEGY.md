# Full-Stack Developer Strategy & Industry Cloud Specializations

**Status**: Phase 1 (Base `/fullstack-dev`) - In Progress
**Created**: 2026-03-01
**Purpose**: Master plan for full-stack developer skill and future industry cloud specializations

---

## Vision: Composable AI Developer Workforce

Build a **factory for industry-specialized AI developers** that can handle end-to-end Salesforce development across any industry vertical.

### Architecture Pattern

```
┌─────────────────────────────────────────────────┐
│  Base: Full-Stack Developer (/fullstack-dev)   │
│  ───────────────────────────────────────────   │
│  ✓ Apex + LWC Expert (unified)                  │
│  ✓ Platform Core (Architecture, Data)           │
│  ✓ AI-native (Agentforce, RAG, Trust Layer)     │
│  ✓ 2026-ready (External Apps, Slack, Data Cloud)│
│  ✓ DevOps + Integration + Soft Skills           │
└──────────────────┬──────────────────────────────┘
                   │
                   │ Inherits/Extends with Industry Expertise
                   │
    ┌──────────────┴────────┬──────────┬──────────┬─────────┐
    │                       │          │          │         │
┌───▼──────────┐  ┌────────▼─────┐ ┌─▼──────┐ ┌─▼──────┐ ┌▼──────┐
│ FSC Dev      │  │ Health Cloud │ │ Field  │ │ Comms  │ │ Mfg   │
│ /fsc-dev     │  │ /health-dev  │ │Service │ │ Cloud  │ │ Cloud │
│              │  │              │ │/fs-dev │ │/comm-dev│ │/mfg-dev│
│+ Insurance   │  │+ HIPAA       │ │+ Work  │ │+ TMF   │ │+ ERP  │
│+ Banking     │  │+ Care Plans  │ │ Orders │ │+ Order │ │+ SCM  │
│+ Wealth Mgmt │  │+ Patient 360 │ │+ Mobile│ │ Mgmt   │ │+ IoT  │
│+ FINRA/SEC   │  │+ EHR         │ │+ Sched │ │+ Catalog│ │+ ABF  │
└──────────────┘  └──────────────┘ └────────┘ └────────┘ └───────┘
```

---

## The JSON Profile (User-Provided)

**Full-Stack Developer Base Skills** - This is what drives the `/fullstack-dev` skill:

```json
[
  {
    "category": "Core Technical Skills",
    "skills": [
      { "skill": "Apex & Asynchronous Processing", "proficiency": "Expert" },
      { "skill": "Lightning Web Components (LWC)", "proficiency": "Expert" },
      { "skill": "System Architecture & Data Modeling", "proficiency": "Expert" },
      { "skill": "Agentforce & Predictive AI", "proficiency": "Advanced",
        "note": "Upgraded: Must master Atlas Reasoning Engine & RAG." },
      { "skill": "Integration Patterns (REST/SOAP/ECA)", "proficiency": "Expert",
        "note": "Updated: Transitioning from Connected Apps to External Client Apps (Spring '26)." },
      { "skill": "DevOps & CI/CD (Copado/SFDX)", "proficiency": "Expert" },
      { "skill": "Data Cloud (Genie)", "proficiency": "Advanced",
        "note": "Upgraded: Essential for 'Zero-Copy' data grounding." },
      { "skill": "Flow Orchestration", "proficiency": "Expert" },
      { "skill": "Security (Shield & Einstein Trust Layer)", "proficiency": "Expert",
        "note": "Updated: Added Trust Layer for AI Guardrails." }
    ]
  },
  {
    "category": "Strategic Architecture (2026 Focus)",
    "skills": [
      { "skill": "Identity & Access Mgmt (IAM)", "proficiency": "Expert" },
      { "skill": "Event-Driven Architecture", "proficiency": "Expert" },
      { "skill": "OmniStudio (Vlocity)", "proficiency": "Intermediate" },
      { "skill": "Code & AI Governance", "proficiency": "Expert",
        "note": "Updated: Includes Prompt Governance & Model Evaluation." },
      { "skill": "Large Data Volumes (LDV)", "proficiency": "Advanced" },
      { "skill": "Salesforce CPQ / RLM", "proficiency": "Intermediate" },
      { "skill": "Agent Observability & Logging", "proficiency": "Advanced",
        "reason": "NEW 2026: Using Agentforce 360 to trace and tune AI reasoning loops." },
      { "skill": "Slack-First Orchestration", "proficiency": "Intermediate",
        "reason": "NEW 2026: Architecting 'multiplayer' workflows where Agents and humans collaborate in Slack." }
    ]
  },
  {
    "category": "Soft Skills & Leadership",
    "skills": [
      { "skill": "Stakeholder Management", "proficiency": "Expert" },
      { "skill": "Tech-to-Biz Translation", "proficiency": "Expert" },
      { "skill": "Mentorship & Delegation", "proficiency": "Expert" },
      { "skill": "Emotional Intelligence (EQ)", "proficiency": "Advanced" },
      { "skill": "Strategic Negotiation", "proficiency": "Advanced" },
      { "skill": "Conflict Resolution", "proficiency": "Intermediate" },
      { "skill": "Context Engineering", "proficiency": "Advanced",
        "reason": "NEW 2026: The ability to design business context for AI to ensure high-ROI outputs." }
    ]
  }
]
```

---

## Why This Approach?

### 1. Real Developers Don't Split Like That
- A senior Salesforce dev builds features that need BOTH Apex backend AND LWC frontend
- Current separate `/apex-dev` and `/lwc-dev` skills create unnecessary friction for complete features
- Full-stack ownership = faster delivery + better integration

### 2. Agent Astro Needs Better Team Members
- Astro orchestrates between specialists, but most features need ONE developer who owns the whole vertical slice
- End-to-end ownership reduces coordination overhead

### 3. AI-Native Skills Signal This is an AI Agent
Key skills that show this is an AI agent profile, not a human:
- **Context Engineering** - teaching the agent HOW to be an effective AI
- **Agent Observability** - the agent needs to understand agent behavior
- **Prompt Governance** - the agent will use AI tools itself
- **Model Evaluation** - the agent evaluates other AI models

### 4. 2026-Forward Looking
- Agentforce & Atlas Reasoning Engine
- External Client Apps (Spring '26 transition from ECA)
- Data Cloud Zero-Copy patterns
- Slack-First Orchestration (multiplayer workflows)
- Einstein Trust Layer (AI guardrails)

### 5. Industry Cloud Scalability
- Each cloud has unique requirements but shares core platform skills
- Composable architecture: Base skills + Industry specialization
- No duplication of core Apex/LWC/Platform knowledge

---

## Phase 1: Base Full-Stack Developer (CURRENT)

**Skill Name**: `/fullstack-dev`

**Implementation Plan**: See `/Users/ronit.mukherjee/.claude/plans/resilient-popping-scroll.md`

**Files to Create**:
```
.cursor/skills/fullstack-dev/
├── SKILL.md                          # Main skill (~600 lines)
├── README.md                         # Documentation (~200 lines)
└── references/                       # 2026-forward patterns
    ├── agentforce-patterns.md        # Atlas Reasoning, RAG, Trust Layer
    ├── external-client-apps.md       # Spring '26 OAuth 2.0
    ├── data-cloud-zero-copy.md       # Zero-copy data grounding
    ├── slack-orchestration.md        # Multiplayer workflows
    ├── context-engineering.md        # AI context design
    └── full-stack-integration.md     # End-to-end patterns
```

**Content Strategy**:
- **Reuse**: Reference existing `/apex-dev` and `/lwc-dev` for deep dives
- **Focus**: Integration patterns + 2026-forward capabilities
- **Unique**: Full-stack perspective, soft skills, AI-native capabilities

**Integration with Astro**:
- Route when: End-to-end features, 2026-forward capabilities, full-stack ownership
- Examples: "Build portal with Agentforce", "Implement Data Cloud integration"

---

## Phase 2: Financial Services Cloud Developer (FUTURE)

**Skill Name**: `/fsc-dev`

**Extends**: `/fullstack-dev` (inherits all base capabilities)

**Additional Expertise**:

### Core FSC Knowledge
- Financial Services Cloud data model
  - Financial Accounts, Households, Account-Account Relationships
  - Person Accounts, Group Memberships
  - Financial Goals, Assets & Liabilities
- Product-based business models (retail banking, wealth management, insurance)
- Industry data sources (credit bureaus, market data, regulatory feeds)

### FSC-Specific Patterns
- **Household Management**: Single-household views, relationship hierarchies
- **KYC/AML Compliance**: Know Your Customer, Anti-Money Laundering
- **Wealth Management**: Portfolio management, financial planning, rebalancing
- **Insurance**: Policy management, claims processing, underwriting
- **Banking**: Loan origination, mortgage processing, account opening

### Regulatory & Compliance
- **FINRA** (Financial Industry Regulatory Authority)
- **SEC** (Securities and Exchange Commission)
- **SOX** (Sarbanes-Oxley)
- **GLBA** (Gramm-Leach-Bliley Act)
- **GDPR** (for EU customers)
- Audit trails, data retention, compliant disclosures

### FSC-Specific Security
- Enhanced security for PII (Personally Identifiable Information)
- Financial data encryption (Shield)
- Role-based access for advisors, bankers, compliance officers
- Transaction monitoring and fraud detection

**File Structure**:
```
.cursor/skills/fsc-dev/
├── SKILL.md                          # FSC developer persona
├── README.md                         # FSC-specific use cases
└── references/
    ├── fsc-data-model-patterns.md    # Household, Financial Account
    ├── fsc-compliance-requirements.md # FINRA, SEC, SOX, GLBA
    ├── fsc-security-patterns.md      # PII, encryption, audit trails
    ├── fsc-wealth-management.md      # Portfolio, goals, rebalancing
    ├── fsc-insurance-patterns.md     # Policy, claims, underwriting
    └── fsc-banking-patterns.md       # Loans, mortgages, accounts
```

**Routing Triggers for Astro**:
- "Build FSC solution", "Implement wealth management", "Create insurance portal"
- Mentions of: Household, Financial Account, KYC, compliance, portfolio

---

## Phase 3: Health Cloud Developer (FUTURE)

**Skill Name**: `/health-dev`

**Extends**: `/fullstack-dev`

**Additional Expertise**:

### Core Health Cloud Knowledge
- Health Cloud data model
  - Patient 360 (Clinical, Demographic, Social Determinants)
  - Care Plans, Care Plan Templates
  - Problems, Goals, Tasks, Medications
  - Provider Network, Facilities
- Clinical workflows (intake → diagnosis → treatment → follow-up)
- Interoperability standards (HL7 FHIR, HL7 v2, CCD)

### Health-Specific Patterns
- **Patient Engagement**: Portal, mobile app, telemedicine
- **Care Coordination**: Multi-provider collaboration, referrals
- **Care Plans**: Template-based care plan creation, task management
- **EHR Integration**: Epic, Cerner, Athenahealth integration
- **Population Health**: Risk stratification, care gap identification

### Regulatory & Compliance
- **HIPAA** (Health Insurance Portability and Accountability Act)
- **HITECH** (Health Information Technology for Economic and Clinical Health)
- **PHI** (Protected Health Information) handling
- Consent management, data privacy, audit logging
- Business Associate Agreements (BAA)

### Health-Specific Security
- PHI encryption at rest and in transit
- Role-based access (providers, nurses, admin, patients)
- Audit trails for all PHI access
- De-identification for analytics

**File Structure**:
```
.cursor/skills/health-dev/
├── SKILL.md
├── README.md
└── references/
    ├── health-cloud-data-model.md    # Patient, Care Plan, Problems
    ├── hipaa-compliance.md           # PHI, BAA, audit trails
    ├── ehr-integration-patterns.md   # HL7 FHIR, Epic, Cerner
    ├── care-plan-patterns.md         # Templates, tasks, workflows
    ├── patient-engagement.md         # Portal, mobile, telemedicine
    └── population-health.md          # Risk stratification, care gaps
```

---

## Phase 4: Field Service Developer (FUTURE)

**Skill Name**: `/fs-dev`

**Extends**: `/fullstack-dev`

**Additional Expertise**:

### Core Field Service Knowledge
- Field Service data model
  - Work Orders, Work Order Line Items
  - Service Appointments, Service Resources
  - Resource Absences, Operating Hours, Service Territories
  - Skills, Crews, Assets, Maintenance Plans
- Mobile workforce (technicians, dispatchers)
- Scheduling & optimization (FSL Scheduling Engine)

### Field Service Patterns
- **Work Order Management**: Creation, assignment, completion
- **Scheduling & Dispatch**: Automated scheduling, manual dispatch, emergency jobs
- **Mobile Experience**: Offline-first LWC, geolocation, signature capture
- **Asset Management**: Installed products, service history, warranties
- **Inventory Management**: Truck stock, product transfers, returns
- **Preventive Maintenance**: Maintenance plans, recurring work orders

### Integration Patterns
- **IoT Integration**: Connected devices, real-time sensor data
- **Route Optimization**: Integration with Google Maps, HERE, Mapbox
- **Inventory Systems**: ERP integration for parts availability
- **Mobile Devices**: iOS/Android app deployment via Mobile Publisher

**File Structure**:
```
.cursor/skills/fs-dev/
├── SKILL.md
├── README.md
└── references/
    ├── field-service-data-model.md   # Work Orders, Appointments
    ├── scheduling-patterns.md        # FSL optimization, dispatch
    ├── mobile-offline-patterns.md    # Offline-first LWC
    ├── asset-management.md           # Installed products, history
    ├── iot-integration.md            # Connected devices, sensors
    └── inventory-patterns.md         # Truck stock, transfers
```

---

## Phase 5: Communications Cloud Developer (FUTURE)

**Skill Name**: `/comm-dev`

**Extends**: `/fullstack-dev`

**Additional Expertise**:

### Core Communications Cloud Knowledge
- Communications Cloud (formerly Vlocity Communications)
- TM Forum standards (eTOM, SID, TAM, Frameworx)
- Product Catalog (offers, products, attributes, pricing)
- Order Management (configure → price → quote → order → fulfill)
- Service provisioning and activation

### Communications Patterns
- **Product Catalog Management**: Bundles, offers, eligibility, attributes
- **Configure Price Quote (CPQ)**: Guided selling, product configuration
- **Order Management**: Decomposition, orchestration, fulfillment tracking
- **Service Provisioning**: Activation workflows, network provisioning
- **Billing Integration**: Usage rating, billing, invoicing
- **Omnichannel**: Web, mobile, store, call center

### OmniStudio Expertise
- **OmniScripts**: Guided workflows for configure-price-quote
- **DataRaptors**: Data integration and transformation
- **Integration Procedures**: Server-side orchestration
- **FlexCards**: Reusable UI components for product display

**File Structure**:
```
.cursor/skills/comm-dev/
├── SKILL.md
├── README.md
└── references/
    ├── communications-cloud-overview.md # TM Forum, order lifecycle
    ├── product-catalog-patterns.md      # Offers, bundles, attributes
    ├── omnistudio-patterns.md           # OmniScripts, DataRaptors
    ├── order-management-patterns.md     # Decomposition, orchestration
    ├── service-provisioning.md          # Activation, network integration
    └── billing-integration.md           # Usage rating, invoicing
```

---

## Phase 6: Manufacturing Cloud Developer (FUTURE)

**Skill Name**: `/mfg-dev`

**Extends**: `/fullstack-dev`

**Additional Expertise**:

### Core Manufacturing Cloud Knowledge
- Manufacturing Cloud data model
  - Sales Agreements, Account Forecasts
  - Partner Portals, Rebate Programs
  - Production Plans, Bill of Materials
- Account-Based Forecasting (ABF)
- Partner relationship management

### Manufacturing Patterns
- **Sales Agreement Management**: Volume commitments, pricing tiers
- **Account-Based Forecasting**: Collaborative forecasting with customers
- **Rebate Programs**: Volume-based incentives, claim processing
- **Supply Chain Integration**: ERP, MES, WMS integration
- **Partner Portals**: Distributor/reseller self-service
- **IoT & Predictive Maintenance**: Connected products, sensor data

### Integration Patterns
- **ERP Integration**: SAP, Oracle, Microsoft Dynamics
- **MES Integration**: Manufacturing Execution Systems
- **WMS Integration**: Warehouse Management Systems
- **IoT Platform**: Asset tracking, predictive maintenance

**File Structure**:
```
.cursor/skills/mfg-dev/
├── SKILL.md
├── README.md
└── references/
    ├── manufacturing-cloud-overview.md  # ABF, sales agreements
    ├── abf-patterns.md                  # Collaborative forecasting
    ├── partner-portal-patterns.md       # Distributor self-service
    ├── erp-integration.md               # SAP, Oracle, Dynamics
    ├── iot-predictive-maintenance.md    # Connected products
    └── supply-chain-integration.md      # MES, WMS integration
```

---

## Composable Combinations (Future Potential)

The base + specialization architecture allows mixing:

### Cross-Industry Specialists
- **Healthcare Banking** (`/health-fsc-dev`): FSC + Health Cloud for healthcare financing
- **Insurance Field Service** (`/fsc-fs-dev`): FSC + Field Service for insurance claims adjusters
- **Telehealth Platform** (`/health-comm-dev`): Health + Communications for telemedicine
- **Connected Manufacturing** (`/mfg-fs-dev`): Manufacturing + Field Service for equipment maintenance

### Implementation Pattern
```markdown
## Skill: Healthcare Banking Developer

**Inherits From**:
- `/fullstack-dev` (base platform skills)
- `/fsc-dev` (financial services expertise)
- `/health-dev` (healthcare expertise)

**Unique Expertise**:
- Healthcare financing products (loans, payment plans)
- Medical billing integration
- Healthcare FSA/HSA management
- HIPAA + FINRA compliance intersection
```

---

## Knowledge Management Strategy

### Shared Foundation (Avoid Duplication)
All specialized skills reference:
- `/apex-dev` - Deep Apex expertise
- `/lwc-dev` - Deep LWC expertise
- `/architect` - Solution design patterns
- `architecture-references/` - Well-Architected patterns
- `_shared/` - NotebookLM and MCP integration

### Industry-Specific Knowledge
Each specialization adds:
- Industry data model patterns
- Regulatory/compliance requirements
- Industry-specific security patterns
- Integration patterns for industry systems
- Industry-specific workflows and processes

### Knowledge Sources
1. **NotebookLM**: Well-Architected patterns, accessibility, security
2. **Salesforce MCP**: Live org validation, metadata inspection
3. **Built-in References**: Industry-specific documentation in each skill
4. **Official Salesforce Docs**: Industry cloud documentation (FSC, Health Cloud, etc.)

---

## Agent Astro Orchestration

### Routing Logic for Industry Clouds

Astro identifies industry context from:
- Explicit mentions ("FSC", "Health Cloud", "Field Service")
- Industry terminology (Household, Care Plan, Work Order, Product Catalog)
- Regulatory mentions (HIPAA, FINRA, SOX)
- Use case descriptions (wealth management, telemedicine, scheduling)

### Orchestration Patterns

**Pattern 1: Single Industry Specialist**
```
User: "Build wealth management portal"
Astro: Routes to /fsc-dev (Financial Services specialist)
Result: FSC-specific implementation
```

**Pattern 2: Design + Industry Implementation**
```
User: "Design healthcare patient portal"
Astro:
  1. /architect (design Well-Architected solution)
  2. /health-dev (implement Health Cloud-specific features)
Result: Architected + compliant implementation
```

**Pattern 3: Cross-Industry**
```
User: "Build healthcare financing solution"
Astro:
  1. /architect (design cross-cloud architecture)
  2. /health-fsc-dev (implement hybrid solution)
     OR parallel: /health-dev + /fsc-dev
Result: Multi-cloud solution
```

---

## Implementation Timeline (Estimated)

### Phase 1: Base Full-Stack Developer ⏳ CURRENT
- **Duration**: 12-16 hours
- **Deliverables**: `/fullstack-dev` skill with 2026-forward capabilities
- **Status**: Planning complete, ready to implement

### Phase 2: Financial Services Cloud (FSC) 📅 Q2 2026
- **Duration**: 8-12 hours
- **Prerequisites**: Phase 1 complete, FSC documentation gathered
- **Deliverables**: `/fsc-dev` skill with compliance patterns

### Phase 3: Health Cloud 📅 Q2 2026
- **Duration**: 8-12 hours
- **Prerequisites**: Phase 1 complete, HIPAA documentation gathered
- **Deliverables**: `/health-dev` skill with clinical workflows

### Phase 4: Field Service 📅 Q3 2026
- **Duration**: 8-12 hours
- **Prerequisites**: Phase 1 complete, FSL documentation gathered
- **Deliverables**: `/fs-dev` skill with mobile/scheduling patterns

### Phase 5: Communications Cloud 📅 Q3 2026
- **Duration**: 10-14 hours (includes OmniStudio)
- **Prerequisites**: Phase 1 complete, Communications Cloud docs gathered
- **Deliverables**: `/comm-dev` skill with TM Forum patterns

### Phase 6: Manufacturing Cloud 📅 Q4 2026
- **Duration**: 8-12 hours
- **Prerequisites**: Phase 1 complete, Manufacturing Cloud docs gathered
- **Deliverables**: `/mfg-dev` skill with ABF patterns

**Total Estimated Effort**: 54-74 hours across 6 phases

---

## Success Criteria

### Base Full-Stack Developer (`/fullstack-dev`)
- ✅ Can implement end-to-end features (Apex + LWC)
- ✅ Integrates Agentforce, Data Cloud, External Client Apps
- ✅ Provides soft skills guidance (stakeholder mgmt, context engineering)
- ✅ Properly routes from Agent Astro
- ✅ References existing skills (no duplication)

### Industry Cloud Specialists
- ✅ Extends base full-stack capabilities
- ✅ Provides industry-specific data model expertise
- ✅ Includes regulatory/compliance guidance
- ✅ Offers industry-specific integration patterns
- ✅ Properly routes from Agent Astro based on industry context

### Overall System
- ✅ Scalable knowledge architecture (DRY principle)
- ✅ Clear routing logic in Agent Astro
- ✅ Production-ready implementations
- ✅ Comprehensive documentation
- ✅ Maintainable and extensible

---

## References for Future Implementation

### Official Salesforce Documentation
- **FSC**: https://help.salesforce.com/s/articleView?id=sf.fsc_admin_intro.htm
- **Health Cloud**: https://help.salesforce.com/s/articleView?id=sf.admin_intro_health_cloud.htm
- **Field Service**: https://help.salesforce.com/s/articleView?id=sf.fs_landing_page.htm
- **Communications Cloud**: https://help.salesforce.com/s/articleView?id=sf.comm_cloud_intro.htm
- **Manufacturing Cloud**: https://help.salesforce.com/s/articleView?id=sf.mfg_cloud_intro.htm

### Trailhead Modules
- FSC: https://trailhead.salesforce.com/content/learn/trails/get-started-with-financial-services-cloud
- Health Cloud: https://trailhead.salesforce.com/content/learn/trails/get-started-with-health-cloud
- Field Service: https://trailhead.salesforce.com/content/learn/trails/get-started-with-field-service
- Communications Cloud: https://trailhead.salesforce.com/content/learn/trails/communications-cloud-basics
- Manufacturing Cloud: https://trailhead.salesforce.com/content/learn/trails/get-started-with-manufacturing-cloud

### Regulatory Resources
- **HIPAA**: https://www.hhs.gov/hipaa/index.html
- **FINRA**: https://www.finra.org/
- **SEC**: https://www.sec.gov/

---

## Notes & Decisions Log

### 2026-03-01: Initial Planning
- User provided JSON profile for full-stack developer
- Identified need for composable architecture (base + specializations)
- Decision: Start with base `/fullstack-dev`, add industry clouds later
- Key insight: AI-native skills (Context Engineering, Agent Observability) signal this is for AI agents
- Architecture: Reference existing skills vs duplication (DRY principle)

### Future Decisions Needed
- [ ] Industry cloud priority order (FSC first, or Health Cloud?)
- [ ] Cross-industry combinations (when to implement?)
- [ ] NotebookLM notebooks for industry clouds (create separate notebooks?)
- [ ] MCP server extensions for industry clouds (custom tools?)
- [ ] Testing strategy for industry-specific skills
- [ ] Documentation updates for Astro routing with 5+ industry skills

---

## Contact & Maintenance

**Maintained By**: AI Developer Orchestration System
**Last Updated**: 2026-03-01
**Next Review**: After Phase 1 completion
**Questions**: Reference this document before implementing Phase 2+

---

**Remember**: This is the MASTER PLAN. Always refer back here before implementing new industry cloud specializations to maintain consistency and avoid duplication.
