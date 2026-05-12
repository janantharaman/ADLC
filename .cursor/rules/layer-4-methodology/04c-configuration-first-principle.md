---
alwaysApply: true
---

# Configuration-First Principle (Layer 4 - Methodology)

**Core Principle**: Before writing ANY custom code (Apex, LWC), ALWAYS evaluate declarative solutions first.

## Salesforce Philosophy: "Click, Not Code"

Salesforce is a declarative platform at its core. Declarative tools should be the **first choice**, not an afterthought.

## Decision Framework (Evaluate in THIS Order)

```
1. Can Flow solve this? ✅
   ├─ Yes → Use Flow (Record-Triggered, Screen, Autolaunched, Scheduled)
   └─ No → Continue to #2

2. Can Validation Rule solve this? ✅
   ├─ Yes → Use Validation Rule with formula
   └─ No → Continue to #3

3. Can Formula Field solve this? ✅
   ├─ Yes → Use Formula Field
   └─ No → Continue to #4

4. Can Approval Process solve this? ✅
   ├─ Yes → Use Approval Process with actions
   └─ No → Continue to #5

5. Must use custom code? ❌
   └─ Consult /apex-dev or /lwc-dev
```

## Why Configuration-First?

### Benefits of Declarative Solutions

1. ✅ **No Test Coverage Required**: Flows don't need 75% code coverage
2. ✅ **Easier Maintenance**: Admins can modify Flows without developers
3. ✅ **Upgradeable**: Salesforce maintains declarative tools across releases
4. ✅ **Faster Development**: Build Flows faster than writing Apex
5. ✅ **Less Technical Debt**: No code to maintain, refactor, or debug
6. ✅ **Better Aligned with Platform**: Salesforce-native solutions

### When Custom Code IS Appropriate

1. ❌ **Bulk Operations**: >2,000 records (Flow limit)
2. ❌ **Complex Logic**: >50 decision points, deeply nested conditions
3. ❌ **Performance-Critical**: Sub-second response times required
4. ❌ **Governor Limit Optimization**: Need manual control over SOQL/DML
5. ❌ **External API Integrations**: Complex authentication, retry logic
6. ❌ **Real-time UI**: Dynamic, reactive user interfaces (use LWC)

## Use MCP to Make Informed Decisions

Before deciding on an approach, **query the org via MCP** to understand existing configuration:

```javascript
// Check existing Flows on this object
mcp.salesforce.listFlows({ object: 'Account', activeOnly: true })
// Response: ["Account_AfterInsert_CreateTasks", "Account_BeforeSave_UpdateRating"]
// Decision: Can we extend existing Flow or need new one?

// Check existing Validation Rules
mcp.salesforce.getValidationRules({ object: 'Opportunity' })
// Response: List of rules with formulas and error messages
// Decision: Can we add to existing rule or create new one?

// Check existing Formula Fields
mcp.salesforce.getFields({ object: 'Contact', type: 'Formula' })
// Response: List of formula fields
// Decision: Can we reuse existing calculation?

// Check existing Approval Processes
mcp.salesforce.getApprovalProcesses({ object: 'Opportunity' })
// Response: Active approval processes with steps
// Decision: Can we modify existing process?
```

## Workflow Integration with Skills

### Primary Workflow

```
User Request
    ↓
Invoke /admin (Admin/Configurator skill - if available)
    ↓
MCP: Query existing org configuration
    ↓
Evaluate: Can declarative tools solve this?
    ├─ YES → Recommend Flow/Validation Rule/Formula Field ✅
    │         Document the solution
    │         User implements via Setup UI
    │
    └─ NO → Delegate to appropriate developer skill:
            ├─ /apex-dev (if backend logic needed)
            ├─ /lwc-dev (if UI component needed)
            └─ /solution-architect (if complex architecture needed)
```

### All Developer Skills Follow This Principle

When `/apex-dev`, `/lwc-dev`, or `/solution-architect` are invoked, they should:
1. **First ask**: "Have you evaluated declarative options?"
2. **Verify**: "Can this be solved with Flow/Validation/Formula?"
3. **Only proceed with code** if declarative won't work

## Real-World Examples

### Example 1: Account Rating Update (DECLARATIVE ✅)

**Requirement**: When Opportunity Amount exceeds $100,000, update Account Rating to "Hot"

**Wrong Approach** ❌:
```apex
// Writing Apex trigger - OVERKILL!
trigger OpportunityTrigger on Opportunity (after update) {
    // 50 lines of code, test class needed, maintenance burden
}
```

**Right Approach** ✅:
```
Record-Triggered Flow: "Opportunity_AfterUpdate_UpdateAccountRating"
- Trigger: After Save
- Condition: Amount > 100000
- Action: Update Records
  - Object: Account
  - Field: Rating = "Hot"

NO CODE NEEDED! ✅
```

### Example 2: Bulk Account Update (CUSTOM CODE ✅)

**Requirement**: Update 50,000 Accounts daily with external system data

**Wrong Approach** ❌:
```
Scheduled Flow (can't handle 50k records - limit 2,000)
```

**Right Approach** ✅:
```apex
// Scheduled Batch Apex
global class AccountBatchUpdate implements Database.Batchable<SObject> {
    // Handles 50,000 records in batches
}
```

### Example 3: Prevent Invalid Data (DECLARATIVE ✅)

**Requirement**: Prevent Account deletion if it has related Contacts

**Wrong Approach** ❌:
```apex
// Apex trigger - OVERKILL!
trigger AccountTrigger on Account (before delete) {
    // Code, tests, maintenance
}
```

**Right Approach** ✅:
```
Validation Rule: "Account_Prevent_Delete_With_Contacts"
- Error Condition: NumberOfContacts > 0
- Error Message: "Cannot delete Account with related Contacts"

NO CODE NEEDED! ✅
```

## Architects Must Balance Declarative vs Code

Solution Architects and Technical Architects must consider:
- **Easy Pillar**: Prefer declarative (easier to maintain)
- **Adaptable Pillar**: Use code when scalability requires it
- **Trusted Pillar**: Both are valid, choose based on requirements

## Summary Checklist

Before writing ANY code, ask:
- [ ] Have I checked existing org configuration via MCP?
- [ ] Can Flow handle this requirement?
- [ ] Can Validation Rule enforce this?
- [ ] Can Formula Field calculate this?
- [ ] Can Approval Process automate this?
- [ ] Have I consulted configuration-first options?
- [ ] Is custom code truly necessary?

**Only if all above are NO → proceed with custom code**

## When This Principle Applies

This Configuration-First principle is **ALWAYS ACTIVE** for:
- All feature development (regardless of complexity)
- All automation requirements
- All data validation needs
- All approval workflows
- All calculations and field updates

Remember: The best code is no code. Always evaluate "Click, Not Code" first.

**See also**:
- Layer 4: Well-Architected Framework (Rule 06) for Easy pillar (simplicity)
- Layer 4: SPSM Framework for Design stage methodology
- Layer 1: Automation Decision Guide (Rule 04) for detailed automation patterns
