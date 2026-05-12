# Project Context Pattern (Layer 3.5)

This pattern enables project-specific context that dynamically switches between projects while keeping all other layers reusable.

## Pattern Overview

```
Layer 1: Foundation (✅ always active, reusable)
Layer 2: Tech Stack (✅ skill-specific, reusable)
Layer 3: Industry (⏳ future, reusable)
Layer 3.5: Project (✅ dynamic, switches) ← THIS PATTERN
Layer 4: Methodology (✅ always active, reusable)
```

## Why Layer 3.5?

**Problem**: Developers need project-specific context (requirements, architecture, decisions) without manual repetition.

**Solution**: Auto-loaded rule file that provides project context to all skills automatically.

**Key Benefits**:
- ✅ **Composable**: Only this layer changes when switching projects
- ✅ **Reusable**: Same developer works on multiple projects
- ✅ **Automatic**: No skill code changes needed
- ✅ **Isolated**: No cross-project data leakage

## How to Use in Skills

### Pattern 1: Reference Project Context During Discovery

```markdown
## Discovery Phase

When starting work, check if project context is available:
1. Look for "PROJECT CONTEXT" markers in conversation
2. Reference project-specific requirements, architecture, constraints
3. If no project context, use industry patterns + org metadata
4. Ask user if unsure: "What are the project requirements for [feature]?"
```

**Example** (Apex Developer):
```
User: "Create order REST API"

You (internal):
1. Check project context: "Order API must support 100k requests/day" ✅
2. Check org metadata: Order__c exists with fields...
3. Apply foundation rules: Bulkification, security
4. Apply tech patterns: REST controller, service layer

You (to user):
"Based on project requirements (100k requests/day), I'll design for:
- Batch API support (handle 200 records per call)
- Async processing for heavy operations
- Response caching with Redis (per project architecture)
- Integration with SAP for inventory (per project spec)

Would you like me to create a detailed implementation plan?"
```

### Pattern 2: Align Solutions with Project Decisions

```markdown
## Solution Design

When designing solutions:
1. Check project context for architectural decisions
2. Follow project-specific patterns (don't propose alternatives)
3. Respect project constraints (integrations, vendors, timelines)
4. Reference project decisions explicitly in your rationale
```

**Example** (Solution Architect):
```
User: "Design payment integration"

You (internal):
1. Check project context: "Use Stripe (NOT PayPal - per 2026-02-15 meeting)" ✅
2. Don't propose PayPal alternative - already decided

You (to user):
"I'll design the payment integration using Stripe, as specified
in project architecture decisions.

Per project requirements:
- Async webhook handling for payment confirmation
- Fraud detection integration (required)
- Multi-currency support (USD, EUR, GBP)
- PCI compliance (per project security standards)

Architecture:
[Stripe-specific design, no PayPal mention]
"
```

### Pattern 3: Validate Against Project Requirements

```markdown
## Implementation Validation

Before delivering solution:
1. Cross-check against project requirements (if available)
2. Verify alignment with project architecture
3. Confirm constraints are respected
4. Flag any deviations explicitly
```

**Example** (Full-Stack Developer):
```
User: "Build customer order portal"

You (internal):
1. Check project context:
   - "Must support mobile" ✅
   - "WCAG AA compliance required" ✅
   - "Integrate Agentforce for FAQs" ✅
2. Design solution that satisfies all three

You (to user):
"Here's the customer portal design aligned with project requirements:

✅ Mobile-responsive (responsive-grid, mobile-first)
✅ WCAG AA compliant (semantic HTML, ARIA labels, keyboard nav)
✅ Agentforce integration for FAQs (embedded chatbot component)

Components:
[Implementation details that satisfy all project requirements]
"
```

## Common Patterns

### Pattern: Project-Specific Performance Requirements

```markdown
Project context: "API must respond within 200ms"

Your solution:
- Implement caching layer ✅
- Use async where possible ✅
- Add performance logging ✅
- Document expected response times ✅
```

### Pattern: Project-Specific Integration Constraints

```markdown
Project context: "Must integrate with SAP (no changes to SAP allowed)"

Your solution:
- Design Salesforce to adapt to SAP API (not vice versa) ✅
- Add retry logic for SAP failures ✅
- Cache SAP responses where appropriate ✅
- Document SAP integration points ✅
```

### Pattern: Project-Specific Go-Live Constraints

```markdown
Project context: "Go-live date: Q2 2026 (June 30)"

Your approach:
- Prioritize MVP features ✅
- Defer nice-to-haves ✅
- Focus on production-ready quality ✅
- Consider timeline in recommendations ✅
```

## Graceful Degradation

**When project context is NOT available**:
- ✅ Skills work normally (no errors)
- ✅ Fall back to industry patterns + org metadata
- ✅ Warn user: "No project context active (generic development mode)"
- ✅ Ask for project-specific requirements if needed

**Example**:
```
User: "Build discount feature"

You (internal):
1. Check project context: Not available
2. Fall back to generic patterns

You (to user):
"I'll build a discount feature using Salesforce best practices.

⚠️ Note: No project context active. Using generic implementation.

If you have project-specific requirements (approval thresholds,
discount limits, stakeholders), please share them and I'll adjust
the design.

Otherwise, I'll proceed with industry-standard patterns..."
```

## Best Practices

### DO ✅

- **Reference project context naturally**: "Per project requirements..." or "Based on project architecture..."
- **Validate alignment**: Cross-check solutions against project constraints
- **Flag deviations**: If you must deviate from project spec, explain why
- **Ask if unsure**: "What are the project requirements for this feature?"
- **Respect decisions**: Don't propose alternatives to already-decided choices

### DON'T ❌

- **Don't assume**: If no project context, don't invent project requirements
- **Don't override**: Don't propose alternatives when project has decided (e.g., Stripe vs PayPal)
- **Don't ignore constraints**: Respect timeline, integration, vendor constraints
- **Don't leak context**: Don't reference Project A details when working on Project B

## Examples by Skill

### Apex Developer

**With Project Context**:
```
"I'll implement the Order API with these project-specific optimizations:
- Support 100k requests/day (per project SLA)
- Integrate with SAP via REST (per project architecture)
- Use Redis caching with 30-min TTL (per 2026-02-22 meeting)
- Stripe webhook handling (per project payment integration)
"
```

**Without Project Context**:
```
"I'll implement the Order API using Salesforce best practices:
- Bulkified operations (handle 200 records)
- Standard REST patterns
- Generic caching strategy
- Typical error handling

If you have project-specific requirements (SLAs, integrations,
caching strategies), please share them for a tailored solution."
```

### Solution Architect

**With Project Context**:
```
"Architecture Design (aligned with project):

Data Model:
✅ Extends existing Order__c (per project data model)
✅ Uses SAP_Order_ID__c for integration (per project)
✅ Follows project naming conventions

Integration:
✅ SAP REST API with 5s timeout (per project spec)
✅ Stripe webhooks for async payment (per project)
✅ Splunk for centralized logging (per project)

This design satisfies project requirements for 100k concurrent users
and 99.9% uptime SLA."
```

**Without Project Context**:
```
"Architecture Design (generic Salesforce patterns):

Data Model:
- Custom Order__c object (standard approach)
- Standard integration fields
- Salesforce naming conventions

Integration Options:
- Option A: Real-time REST integration
- Option B: Async batch integration
- Option C: Platform Events

Which integrations and SLAs apply to your use case?"
```

### LWC Developer

**With Project Context**:
```
"I'll build the customer portal with project requirements:

✅ Mobile-responsive (project requirement)
✅ WCAG AA compliant (project requirement)
✅ Integrate Agentforce chatbot (project requirement)
✅ Use Stripe payment widget (per project vendor)

Component Architecture:
[Design that satisfies all project-specific requirements]
"
```

**Without Project Context**:
```
"I'll build the customer portal using LWC best practices:
- Responsive design
- Accessibility (ARIA labels)
- Standard Lightning components

Do you have specific requirements for:
- Mobile/tablet support level?
- Accessibility compliance (WCAG level)?
- Chatbot integration?
- Payment provider?"
```

## Switching Projects

When user switches projects:
```bash
# They run:
python .cursor/tools/generate-project-context.py \
  --input="PROJECT: NewProject.md" \
  --force

# Next conversation:
# - New project context automatically loads
# - You reference new project requirements
# - Previous project context no longer available
```

**Your behavior**:
- ✅ Use new project context naturally
- ✅ Don't reference old project
- ✅ If confused, ask: "Which project are we working on?"

## Verification

To verify you're using project context correctly:
1. **Check**: Do you reference project-specific requirements?
2. **Check**: Do solutions align with project architecture?
3. **Check**: Do you respect project constraints?
4. **Check**: Do you flag deviations explicitly?

If YES to all → ✅ Using project context correctly!

## See Also

- `.cursor/rules/layer-3-dynamic/README.md` - Project context overview
- `.cursor/tools/README.md` - Generator tool usage
- `claude-plans/LAYER_3.5_IMPLEMENTATION_PLAN.md` - Implementation details
