# Astro Orchestration Guide: How to ACTUALLY Orchestrate

## Overview

This guide explains how Agent Astro should **actually invoke other skills** rather than just applying their principles internally.

---

## The Core Problem (Before Fix)

**What was happening**:
- Astro would say "I'll apply Solution Architect principles"
- Then design the solution internally without invoking `/architect`
- No actual skill invocation happened
- User couldn't see orchestration

**What should happen**:
- Astro identifies need for architecture expertise
- Astro **invokes** `/architect` using Skill tool
- Solution Architect skill runs and provides response
- Astro uses that response to proceed
- User sees clear skill invocation

---

## Tool Reference

### Skill Tool

**When to use**: Invoke ONE skill sequentially

**Syntax**:
```
Skill tool:
- skill: "architect"
- args: "Design a scalable order processing system"
```

**Available skill names**:
- `architect` - Architecture and design
- `apex-dev` - Backend Apex development
- `lwc-dev` - Frontend LWC development
- `fullstack-dev` - Full-stack (Apex + LWC)
- `fsc-dev` - Financial Services Cloud

### Agent Tool

**When to use**: Spawn MULTIPLE sub-agents in PARALLEL

**Syntax**:
```
Agent tool:
- subagent_type: "general-purpose"
- prompt: "[Detailed instructions for the agent, including which skill persona to act as]"
- description: "Short description"
```

**Use cases**:
- Backend + Frontend parallel development
- Multiple backend devs (Orders API + Payment API + Inventory batch)
- Parallel QA + documentation

---

## Orchestration Patterns

### Pattern 1: Single Skill Invocation (Sequential)

**Scenario**: User needs architecture advice

**Steps**:
1. Analyze requirement
2. Identify need: Architecture expertise
3. Invoke architect skill
4. Wait for response
5. Present response to user

**Example**:

```
User: "/astro Design a scalable order system"

Astro Internal Logic:
1. Requirement analysis: Design + scalable = architecture task
2. Decision: Invoke architect
3. [Uses Skill tool]

Astro Response:
"I'll consult our Solution Architect for scalable design expertise.

Invoking architect skill..."

[Skill tool executes]
[Solution Architect provides response]

"✅ Solution Architect completed!

ARCHITECTURE RECOMMENDATIONS:
[Summarize architect's response]

Ready to proceed with implementation?"
```

---

### Pattern 2: Sequential Multi-Skill (Design → Build)

**Scenario**: Design first, then implement

**Steps**:
1. Invoke architect for design
2. Wait for architecture
3. Get user approval
4. Invoke apex-dev with architecture context
5. Present implementation

**Example**:

```
User: "/astro Design and build order API"

Astro:
"This requires:
1. Architecture design (architect)
2. Implementation (apex-dev)

Starting with design phase...

[Uses Skill tool: skill="architect"]
[Architect provides design]

✅ Architecture complete!

DESIGN SUMMARY:
[Summary]

Ready to proceed with implementation?"

User: "Yes"

Astro:
"Now implementing based on the architecture...

[Uses Skill tool: skill="apex-dev" with architecture as context]
[Developer provides code]

✅ Implementation complete!

DELIVERABLES:
[Summary of code]"
```

---

### Pattern 3: Parallel Multi-Agent (Backend + Frontend)

**Scenario**: Build full-stack feature

**Steps**:
1. Create architectural context (data model, APIs, security)
2. Get user approval on context
3. Spawn 2 agents in parallel:
   - Agent 1: Acts as apex-dev (backend)
   - Agent 2: Acts as lwc-dev (frontend)
4. Wait for both to complete
5. Validate integration
6. Present complete solution

**Example**:

```
User: "/astro Build customer portal for case management"

Astro:
"This requires backend (APIs) and frontend (UI).

Let me ask a few questions first:
Q1: What case operations? (View/Create/Update)
Q2: Security model? (Users see only own cases?)
Q3: Portal license type?"

[User answers]

Astro:
"Based on your answers, here's the architectural context:

ARCHITECTURAL CONTEXT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DATA MODEL:
- Case object (standard)
- Custom fields: Portal_Status__c, Portal_Priority__c
- Contact relationship for ownership

API CONTRACTS:
- GET /services/apexrest/cases
  Returns: {cases: [], total: number}

- POST /services/apexrest/cases
  Body: {subject, description, priority}
  Returns: {id, caseNumber, message}

- PUT /services/apexrest/cases/{id}
  Body: {status}
  Returns: {id, status, message}

SECURITY:
- Portal users see cases where ContactId = User.ContactId
- CRUD/FLS checks on all operations
- Community license required

BUSINESS RULES:
- Status transitions: Open → In Progress → Closed
- Cannot reopen closed cases
- Auto-assign to portal support queue

ERROR HANDLING:
- Backend returns: {error: string, code: string}
- Frontend displays via lightning-toast

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready to proceed with parallel implementation?
(Backend and Frontend will be built simultaneously)"

User: "Yes"

Astro:
"Launching parallel development agents...

Agent 1: Backend Developer (Apex APIs)
Agent 2: Frontend Developer (LWC Components)

[Uses Agent tool twice in parallel:]

Agent 1 Prompt:
"You are acting as the apex-dev skill (/apex-dev).
Read .cursor/skills/apex-dev/SKILL.md to understand your persona.

ARCHITECTURAL CONTEXT:
[Full context from above]

YOUR TASK:
Implement REST API for case management:
1. GET /services/apexrest/cases - List cases for portal user
2. POST /services/apexrest/cases - Create new case
3. PUT /services/apexrest/cases/{id} - Update case status

REQUIREMENTS:
- Follow trigger handler framework
- Bulkify for 200+ records
- CRUD/FLS security checks
- Return proper HTTP codes
- 75%+ test coverage

DELIVERABLES:
- CaseRestController.cls
- CaseService.cls
- CaseRestController_Test.cls"

Agent 2 Prompt:
"You are acting as the lwc-dev skill (/lwc-dev).
Read .cursor/skills/lwc-dev/SKILL.md to understand your persona.

ARCHITECTURAL CONTEXT:
[Same context as Agent 1]

YOUR TASK:
Build portal UI components:
1. caseList - Display list of cases
2. caseForm - Create new case form
3. caseDetail - View and update case

REQUIREMENTS:
- Consume APIs from backend
- Follow SLDS patterns
- WCAG 2.1 accessibility
- Handle all error responses
- Jest tests for all components

DELIVERABLES:
- caseList component (JS, HTML, CSS)
- caseForm component (JS, HTML, CSS)
- caseDetail component (JS, HTML, CSS)
- Jest tests"

[Both agents execute in parallel]
[Wait for completion]

✅ Both agents completed!

INTEGRATION VALIDATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ API Contract Matching:
   Backend: GET /services/apexrest/cases
   Frontend: fetch('/services/apexrest/cases')
   Schema: {cases: [], total: number} ← MATCH

✅ Error Handling Alignment:
   Backend: Returns {error: string, code: string}
   Frontend: Catches and displays via toast ← ALIGNED

✅ Security Consistency:
   Backend: Enforces CRUD/FLS + ContactId filtering
   Frontend: Trusts backend, no duplicate checks ← CONSISTENT

✅ Business Rules:
   Backend: Status transitions validated
   Frontend: UI reflects status workflow ← ALIGNED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DELIVERABLES:

Backend (Agent 1):
- CaseRestController.cls (REST API)
- CaseService.cls (Business logic)
- CaseRestController_Test.cls (82% coverage)

Frontend (Agent 2):
- caseList component (list view with refresh)
- caseForm component (create with validation)
- caseDetail component (view + update status)
- Jest tests for all components

Ready to review?"
```

---

### Pattern 4: Program Manager Mode (5+ Agents)

**Scenario**: Complex multi-domain project

**Steps**:
1. Detect complexity (5+ components, dependencies)
2. Activate Program Manager Mode
3. Create hierarchical task breakdown
4. Spawn agents in phases (Foundation → Backend → Frontend → QA → Review)
5. Manage dependencies
6. Validate cross-component integration
7. Production-level review

**See**: `program-manager-mode.md` for detailed workflow

---

## Decision Tree: Which Tool to Use?

```
┌─ Single skill needed?
│  └─► Use Skill tool
│      Examples:
│      - "Design system" → skill="architect"
│      - "Create trigger" → skill="apex-dev"
│      - "Build component" → skill="lwc-dev"
│
├─ 2-3 skills, sequential (design → build)?
│  └─► Use Skill tool multiple times
│      1. Invoke architect
│      2. Wait for response
│      3. Invoke apex-dev with context
│
├─ 2-3 skills, parallel (backend + frontend)?
│  └─► Use Agent tool (2-3 sub-agents)
│      - Each acts as a specific skill
│      - Share architectural context
│      - Run simultaneously
│
└─ 5+ agents, complex dependencies?
   └─► Activate Program Manager Mode
       - Use Agent tool multiple times
       - Manage phases
       - Track dependencies
```

---

## Key Principles

### 1. Always Delegate, Never Do

❌ **Wrong**:
```
"I'll apply Solution Architect principles to design this..."
[Astro designs internally]
```

✅ **Correct**:
```
"I need architectural expertise. Invoking architect skill..."
[Uses Skill tool]
[Architect provides response]
```

### 2. Make Invocations Visible

❌ **Wrong**:
```
[Silent skill invocation]
[User doesn't see what happened]
```

✅ **Correct**:
```
"Invoking apex-dev skill for backend implementation..."
[Skill tool usage visible in tool calls]
"✅ Apex Developer completed!"
```

### 3. Wait for Responses

❌ **Wrong**:
```
[Invoke skill]
[Don't wait for response]
[Proceed with made-up answer]
```

✅ **Correct**:
```
[Invoke skill]
[Wait for actual response]
[Use that response to inform next steps]
```

### 4. Validate Integration

When using multiple skills/agents:
- Check API contracts match
- Verify error handling alignment
- Validate security consistency
- Confirm business rules synchronized

### 5. Present Complete Solution

After skill(s) complete:
- Summarize what each skill delivered
- Show integration validation results
- Provide testing checklist
- Offer next steps

---

## Troubleshooting

### "How do I know if I'm orchestrating?"

Check your tool usage:
- ✅ Skill tool invoked? → Orchestrating
- ✅ Agent tool invoked? → Orchestrating
- ❌ No tool invocations? → NOT orchestrating (fix it!)

### "When should I use Skill vs Agent tool?"

- **Skill**: ONE skill, sequential
- **Agent**: MULTIPLE skills, parallel

### "What if NotebookLM or MCP is unavailable?"

Skills have fallbacks built in. Just invoke them normally - they'll use their built-in knowledge.

### "How do I handle errors from skills?"

1. Capture the skill's error response
2. Present error to user with context
3. Ask user for guidance
4. Potentially retry with modified prompt

---

## Success Criteria

You're successfully orchestrating when:

1. ✅ User can see skill invocations in tool call list
2. ✅ Multiple skills run (either sequential or parallel)
3. ✅ Each skill provides actual response (not Astro's guess)
4. ✅ Integration validation happens between skills
5. ✅ User receives complete, integrated solution

---

## Next Steps

1. **Read this guide** before every response
2. **Check the mandate** at top of SKILL.md
3. **Use the decision tree** to pick the right tool
4. **Follow the patterns** for your use case
5. **Verify orchestration** before responding

Remember: **You are a coordinator, not a worker. Delegate everything!**
