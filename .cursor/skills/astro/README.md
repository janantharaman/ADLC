# Agent Astro: Intelligent Orchestrator ⭐

Your friendly Salesforce development guide that analyzes requirements, routes to appropriate experts, and ensures production-quality solutions.

---

## 🆕 MAJOR UPDATE: True Orchestration Enabled (March 2, 2026)

**What Changed**: Astro is now a **true orchestrator** that actually invokes other cursor skills instead of just applying their principles internally.

**What This Means**:
- ✅ Astro now **actually calls** `/solution-architect`, `/apex-developer`, `/lwc-developer`, etc.
- ✅ You'll see **explicit skill invocations** in the tool call list
- ✅ Multiple agents can run **in parallel** for complex tasks
- ✅ True coordination between specialized experts

**Before**: Astro would say "I'll apply architect principles" but design everything itself
**After**: Astro invokes the solution-architect skill, which provides the actual design

**See**: `ORCHESTRATION_FIX_SUMMARY.md` for detailed changes

---

## Quick Start

Invoke Agent Astro in Cursor IDE:
```
/astro
```

Then provide your requirement:
```
"Build discount approval workflow"
"Design customer portal"
"Prevent duplicate Accounts"
"@requirements.md"
"JIRA-1234"
```

## What is Agent Astro?

**Agent Astro** is the intelligent orchestrator that serves as your **primary interface** for Salesforce development in this system. Named after Salesforce's beloved mascot, Astro provides a friendly, approachable way to build amazing solutions.

Think of Astro as your project coordinator who:
- ✅ Understands your requirements
- ✅ Figures out the best approach
- ✅ Coordinates the right experts
- ✅ Ensures production quality
- ✅ Keeps you in control

## Core Capabilities

### 1. Requirement Analysis 🔍
Astro understands requirements from multiple sources:

**Natural Language**:
```
/astro "Prevent duplicate Account names"
```

**Jira Tickets**:
```
/astro "JIRA-1234"
/astro "https://jira.company.com/browse/SFDC-1234"
```

**Markdown Files**:
```
/astro "@requirements.md"
/astro "/path/to/requirements.md"
```

**User Stories**:
```
/astro "As a sales rep, I want to track customer complaints"
```

### 2. Intelligent Routing 🎯
Astro automatically invokes the right expert skill:

| Task Type | Astro Routes To | Example |
|-----------|----------------|---------|
| Architecture/Design | `/architect` | "Design customer portal" |
| Backend Development | `/apex-dev` | "Create trigger for Accounts" |
| Complex (Both) | `/architect` → `/apex-dev` | "Build order processing system" |

**Future**:
- Configuration → `/admin`
- Frontend → `/lwc-dev`
- Testing → `/qa`

### 3. Plan-First Enforcement 🔒
**Non-negotiable**: Astro ALWAYS creates a plan and gets your approval before implementing.

**Workflow**:
```
1. Analyze requirement
2. Ask clarifying questions
3. Create detailed plan
4. Get your approval ← YOU CONTROL THIS
5. Coordinate experts
6. Deliver solution
```

### 4. Quality Assurance ✅
Before marking complete, Astro verifies:
- All requirements addressed
- Edge cases considered
- Testing approach defined
- Error handling implemented
- Documentation provided
- Production-ready quality

### 5. NotebookLM Coordination 📚
Astro knows our experts use NotebookLM:
- **Solution Architect**: Queries Well-Architected patterns
- **Apex Developer**: Queries accessibility/security patterns
- **Fallback**: Uses built-in knowledge if NotebookLM unavailable

You don't need to worry about this - Astro coordinates seamlessly.

## Available Expert Skills

### Current Team ✅

#### Solution Architect (`/architect`)
**Expertise**:
- Solution design and architecture
- Well-Architected Framework (TRUSTED, EASY, ADAPTABLE)
- Scalability planning
- Accessibility compliance
- Security architecture
- Integration design

**NotebookLM**: First approach for latest patterns

**Use for**: High-level design, architectural decisions, trade-off analysis

#### Apex Developer (`/apex-dev`)
**Expertise**:
- Apex triggers and handlers
- Batch/Scheduled/Queueable Apex
- REST/SOAP APIs
- Backend business logic
- Database operations (SOQL/DML)

**NotebookLM**: Enhanced with accessibility and security patterns

**Use for**: Backend implementation, business logic, integrations

### Coming Soon 🚀
- Admin Configurator (`/admin`)
- LWC Developer (`/lwc-dev`)
- QA Engineer (`/qa`)
- Program Manager (`/pm`)

## Usage Examples

### Example 1: Simple Configuration
```
/astro "Prevent duplicate Account names"

Astro analyzes → Simple validation task
Astro creates plan → Validation Rule approach
You approve → "yes"
Astro delivers → Step-by-step setup guide

Result: Production-ready validation rule in 2 minutes
```

### Example 2: Backend Development
```
/astro "Create trigger to update related Contacts when Account rating changes"

Astro analyzes → Backend development task
Astro asks questions → Clarify update logic
Astro creates plan → Trigger handler pattern, bulkified
You approve → "looks good"
Astro invokes /apex-dev → Complete implementation
Astro delivers → Trigger + Handler + Service + Tests

Result: Production-ready code with 75%+ coverage
```

### Example 3: Architecture + Development
```
/astro "Design and build a customer portal for case management"

Astro analyzes → Complex, needs architecture first
Astro asks questions → Users, features, security requirements
Astro creates plan → Multi-phase approach

Phase 1: Architecture
Astro invokes /architect → Solution design
Architect delivers → Well-Architected proposal
You review → Approve architecture

Phase 2: Implementation
Astro invokes /apex-dev → Backend implementation
Developer delivers → Complete code + tests
You review → Approve implementation

Result: Complete solution with architecture + implementation
```

### Example 4: From Jira
```
/astro "JIRA-1234"

Astro fetches ticket → Parses requirement
Astro summarizes → "Discount approval workflow"
Astro asks questions → Clarify thresholds, approvers
Astro creates plan → Approval Process approach
You approve → "yes"
Astro delivers → Complete implementation guide

Result: Jira-sourced requirement implemented
```

### Example 5: Parallel Execution (Complex)
```
/astro "Build customer portal with case management"

Astro analyzes → Complex, needs backend + frontend

Phase 1: Architectural Context
- Data model: Case, Contact, Portal User
- API contracts: GET /cases, POST /cases, PUT /cases/{id}
- Security: Portal sharing rules, CRUD/FLS
- [User approval via AskUserQuestion]

Phase 2: Parallel Execution
Astro spawns 2 agents simultaneously:
- Agent 1 (Backend): Acts as /apex-dev → REST APIs
- Agent 2 (Frontend): Acts as /lwc-dev → Portal UI

Both execute in parallel ← KEY ADVANTAGE

Phase 3: Integration Validation
Astro validates:
- ✅ API contracts match (endpoints, schemas)
- ✅ Error handling consistent
- ✅ Security unified
- [User approval via AskUserQuestion]

Phase 4: Delivery
- Complete solution (backend + frontend)
- Integration guide
- Testing checklist

Time: 30 minutes (vs 60+ if sequential)
Result: Fully integrated portal with validated APIs
```

### How Parallel Execution Works

**Behind the Scenes**:
1. Astro creates architectural context (data model, APIs, security)
2. Uses Agent tool to spawn multiple sub-agents simultaneously
3. Each agent receives identical context + specific task
4. Agents execute independently (true parallelism)
5. Astro validates integration after completion
6. Presents unified solution to you

**User Control**:
- Q&A Gate 1: Approve architecture before execution
- Q&A Gate 2: Approve implementation after execution
- Manual bypass: Still invoke /apex-dev or /lwc-dev directly

**Time Savings**:
- Sequential: Architecture (10 min) → Backend (25 min) → Frontend (25 min) = 60 minutes
- Parallel: Architecture (10 min) → Both in parallel (25 min) = 35 minutes
- **Savings: ~40% faster for complex tasks**

### Example 6: Program Manager Mode (Enterprise Complexity) 🎯
```
/astro "Build complete order management system with inventory, payments via Stripe, customer portal, admin dashboard, and approval workflows"

Astro analyzes → COMPLEX, activates PROGRAM MANAGER MODE

Phase 1: Strategic Analysis
- Identifies: 8 specialized agents needed
- Domains: Backend (3), Frontend (2), Admin (1), QA (1), Architect (1)
- Estimated: 50+ hours sequential → 4-6 hours parallel
- [Asks strategic questions about priorities, integrations, deployment]

Phase 2: Task Decomposition
- Creates hierarchical breakdown:
  • Phase 1: Foundation (Architect) → Data model, security, APIs
  • Phase 2-4: Implementation (7 agents in parallel)
    - Backend Dev 1: Order API
    - Backend Dev 2: Payment API + Stripe integration
    - Backend Dev 3: Inventory batch job
    - Frontend Dev 1: Customer portal (OrderList, OrderDetail, OrderForm)
    - Frontend Dev 2: Admin dashboard (Analytics, Reports)
    - Admin: Approval flows and validation rules
  • Phase 5: Integration Testing (QA agent)
  • Phase 6: Production Review (Astro)
- Dependency graph: Phase 1 → Phase 2||3||4 → Phase 5 → Phase 6

Phase 3: Agent Allocation & Execution
- Each agent gets:
  • Specialized role (e.g., "Backend Developer - Payment Integration Specialist")
  • Specific subtask (e.g., "Build Payment API with Stripe callout")
  • Shared context (data model, APIs, security standards)
  • Integration points (who they integrate with)
  • Dependencies (what must complete first, what they block)
- [User approval: "Foundation ready. Proceed with implementation?"]
- Spawns 7 agents in parallel
- All complete simultaneously

Phase 4: Integration Validation
- API contracts match (all endpoints align)
- Cross-component validation (Order API ↔ Payment API ↔ Inventory)
- Code review (naming conventions, error patterns, security)
- Identifies conflicts: "Frontend expects camelCase, backend returns snake_case"
- [Presents resolution options to user]

Phase 5: Integration Testing
- QA agent creates end-to-end tests
- Tests: Create order → Process payment → Update inventory
- Performance: 100 concurrent orders
- Finds 2 issues: Batch job optimization needed, null handling bug
- Re-spawns agents to fix issues
- Re-validates

Phase 6: Production Review
- Security audit: 95/100 (CRUD/FLS, encryption, audit trails)
- Performance validation: 95/100 (bulk operations, no SOQL loops)
- Documentation: 100/100 (API docs, runbooks, deployment guide)
- [User approval: "Ready to deploy?"]

Phase 7: Delivery
- Complete system (backend + frontend + config + tests)
- Deployment plan (phased rollout)
- Runbook (monitoring, troubleshooting)
- Quality metrics (85% coverage, security audit, perf validation)

Time: 4-6 hours (vs 50+ if sequential, vs 25+ if manual parallel)
Result: Production-ready enterprise system with 8 specialized agents
Savings: 80-90% time reduction through intelligent orchestration
```

### How Program Manager Mode Works

**Activation Triggers** (2+ criteria):
- Multiple domains (Backend + Frontend + Admin + Integration + Testing)
- Large scope (5+ components or 40+ hours)
- Complex dependencies (sequential phases + parallel work streams)
- Multiple agents per type needed (2 backend devs, not just 1)
- Production-critical (payments, security, compliance)

**Key Capabilities**:
1. **Task Decomposition**: Hierarchical breakdown into phases/subtasks
2. **Dynamic Allocation**: Multiple agents of same type (Backend Dev 1, 2, 3)
3. **Dependency Management**: Graph-based execution (Phase 1 → Phase 2 || 3)
4. **Integration Validation**: Cross-component, code review, conflict resolution
5. **Production Review**: Security audit, performance validation, QA testing
6. **Complete Delivery**: System + deployment plan + runbook + quality metrics

**Inspired by**: ChatDev's multi-agent coordination + Cursor's development power

**See**: `.cursor/skills/astro/program-manager-mode.md` for complete workflow

---

## Astro's Three Modes

| Mode | Complexity | Agents | Time Savings | Example |
|------|-----------|--------|--------------|---------|
| **Direct Execution** | Simple | 0-1 | N/A | "Create validation rule" |
| **Standard Orchestration** | Moderate | 2-3 | 40-50% | "Build customer portal" |
| **Program Manager Mode** | High | 5+ | 70-80% | "Build order management system" |

Astro **automatically detects** complexity and activates the appropriate mode!

## When to Use Astro vs. Direct Skills

### Use `/astro` (Recommended) ⭐
✅ You're not sure which expert to consult
✅ You want guidance on best approach
✅ Complex requirement needing multiple experts
✅ You want plan-first workflow enforced
✅ You want coordination handled for you
✅ You're new to the system

**Most users should start with Astro!**

### Use Skills Directly (Advanced)
✅ You know exactly which expert you need
✅ Quick, targeted change
✅ You want to skip orchestration
✅ You're an expert user

**Examples**:
```bash
# For most users (recommended)
/astro "Build discount approval"

# For experts only
/architect "Design discount approval architecture"
/apex-dev "Create Apex trigger for Account validation"
```

## Astro's Workflow (Detailed)

### Step 1: Requirement Analysis
```
You invoke: /astro "your requirement"

Astro:
- Parses input (natural language, Jira, MD file)
- Identifies key requirements
- Classifies task type (config, dev, architecture)
- Determines complexity
```

### Step 2: Clarifying Questions
```
Astro asks:
- Missing information
- Ambiguous requirements
- User preferences
- Constraints

Example:
"Q1: What discount threshold requires approval?"
"Q2: Who should approve?"
"Q3: How should users request approval?"
```

### Step 3: Plan Creation
```
Astro creates detailed plan:
- Solution approach (config vs code)
- Implementation steps
- Testing approach
- Estimated time
- Risks/considerations

Format:
SOLUTION APPROACH: [Description]
IMPLEMENTATION STEPS: [Numbered list]
TESTING APPROACH: [Test scenarios]
ESTIMATED TIME: [Duration]
```

### Step 4: Your Approval
```
Astro presents plan:
"Here's my plan... Ready to proceed? (yes/no)"

You decide:
- "yes" → Proceed with implementation
- "no" → Discuss changes
- "modify X" → Astro adjusts plan

🔒 Astro will NOT implement without your approval
```

### Step 5: Expert Coordination
```
Astro's internal logic:
- Architecture needed? → Invoke /architect
- Backend code needed? → Invoke /apex-dev
- Both needed? → /architect first, then /apex-dev
- (Future) Config possible? → Invoke /admin first
```

### Step 6: Solution Delivery
```
Astro delivers:
- Complete solution (design, code, config)
- Implementation guide
- Testing checklist
- Documentation
- Quality validation

Format:
✅ SOLUTION READY
IMPLEMENTATION: [Steps]
TESTING: [Checklist]
DOCUMENTATION: [Details]
```

## Plan-First Philosophy

### Why Plan-First?
1. **Build the Right Thing**: Avoid rework by clarifying upfront
2. **Production Quality**: Ensure professional solutions
3. **Your Control**: You approve the direction
4. **Save Time**: Faster than trial-and-error

### Astro's Commitment
```
❌ Astro will NOT: "Done! Here's the code."
✅ Astro WILL: "Here's my plan. Ready to proceed?"
```

### If You Try to Rush
```
You: "/astro Just implement it quickly"

Astro: "I understand you want speed, but I need to create
        a plan first. This ensures production quality and
        saves time by avoiding rework. It only takes a few
        minutes - let me analyze your requirement..."
```

## Quality Standards

Astro enforces these standards before marking complete:

### Functional ✅
- All requirements addressed
- Edge cases handled
- Error conditions considered

### Non-Functional ✅
- Performance acceptable
- Security implemented (CRUD/FLS)
- Accessibility considered (if UI)

### Testing ✅
- Test approach documented
- Test scenarios defined
- Bulk testing (if code)

### Documentation ✅
- Implementation steps clear
- Configuration documented
- Maintenance guide provided

### Production-Ready ✅
- Salesforce best practices
- Foundation rules followed
- Well-Architected principles applied
- No "quick hacks" or incomplete solutions

## Communication Style

### Astro Is:
- **Friendly**: Like Salesforce's Astro mascot - approachable
- **Professional**: Knowledgeable about best practices
- **Concise**: Clear and to-the-point
- **Proactive**: Asks questions before you have to
- **Collaborative**: Works with you as a team

### Astro Is NOT:
- Overly verbose
- Assuming without asking
- Implementing without approval
- Skipping quality checks

## Tips for Working with Astro

### 1. Be Specific
```
❌ "Fix the Account thing"
✅ "Prevent duplicate Account names"
```

### 2. Provide Context
```
❌ "Build a portal"
✅ "Build a customer portal where users can view and create Cases"
```

### 3. Answer Questions
```
Astro will ask clarifying questions.
Take a moment to answer - it ensures we build the right thing.
```

### 4. Review Plans Carefully
```
The plan is your opportunity to course-correct.
Review implementation steps and testing approach.
```

### 5. Trust the Process
```
Plan-first might feel slower initially, but it's faster overall.
No rework, no surprises, production-ready from the start.
```

## NotebookLM Integration

Astro coordinates NotebookLM usage transparently:

### Solution Architect
- Queries: Well-Architected patterns, accessibility, security
- Fallback: Built-in foundation rules

### Apex Developer
- Queries: Accessibility patterns (forms, data entry), security patterns
- Fallback: Built-in foundation rules

**You don't need to know about this** - Astro handles it automatically. Our experts have access to latest patterns when available, and comprehensive built-in knowledge as fallback.

## Testing Agent Astro

### Test 1: Simple Configuration
```bash
/astro "Prevent duplicate Account names"
```
**Expected**:
- Analyzes requirement
- Creates plan (Validation Rule)
- Waits for approval
- Delivers setup guide

### Test 2: Backend Development
```bash
/astro "Create trigger to update related Contacts"
```
**Expected**:
- Analyzes requirement
- Asks clarifying questions
- Creates plan (trigger handler pattern)
- Invokes /apex-dev
- Delivers complete code + tests

### Test 3: Architecture
```bash
/astro "Design a scalable customer portal"
```
**Expected**:
- Analyzes requirement
- Asks clarifying questions
- Invokes /architect for design
- Delivers architecture proposal
- Offers to coordinate implementation

## Troubleshooting

### Astro doesn't understand my requirement
→ Be more specific or provide examples
→ Break complex requirements into parts

### Astro asks too many questions
→ Provide more context upfront
→ Answer questions - they ensure quality

### I want to skip the plan
→ Plan-first is enforced for quality
→ Takes 2-5 minutes, saves hours later
→ You stay in control

### I need a different expert
→ Tell Astro: "I need the architect for this"
→ Or invoke skills directly: `/architect`, `/apex-dev`

## FAQs

**Q: Do I always have to use Astro?**
A: No, but it's recommended. Expert users can invoke skills directly.

**Q: Can Astro implement without a plan?**
A: No, plan-first is enforced for quality and brand protection.

**Q: What if I disagree with Astro's plan?**
A: Tell Astro what to change. The plan is collaborative.

**Q: Can Astro handle Jira tickets?**
A: Yes, provide ticket ID or URL.

**Q: Does Astro work offline?**
A: Yes, but without NotebookLM access (uses built-in knowledge).

**Q: Is Astro production-ready?**
A: Yes! Astro enforces production-quality standards.

## Next Steps

1. **Try Astro**: `/astro "your requirement"`
2. **Answer questions**: Clarify what you need
3. **Review plan**: Ensure it meets your needs
4. **Approve**: Give the green light
5. **Get solution**: Production-ready results

## Resources

- **Astro Skill**: `.cursor/skills/astro/SKILL.md`
- **Solution Architect**: `.cursor/skills/solution-architect/README.md`
- **Apex Developer**: `.cursor/skills/apex-developer/README.md`
- **NotebookLM Integration**: `.cursor/skills/_shared/notebooklm-knowledge.md`
- **System Overview**: `.cursor/README.md`

---

**Welcome to Salesforce Development with Agent Astro!** ⭐

Let's build amazing solutions together, the right way, every time.

**Invoke Astro**: `/astro "your requirement here"`
