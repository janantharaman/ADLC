# Team-Wide Common Pitfalls 🚧

**Purpose**: Document patterns that apply across multiple employees/roles
**Owner**: Meera (Staffing Manager)
**Usage**: All employees should review this before starting work

---

## How to Use This File

**Before Starting Work**:
- Review recent pitfalls to avoid repeating team mistakes
- Check if your current task relates to any documented pattern

**When You See a Pattern Here**:
- Apply the corrected approach
- Add preventive check to your mental checklist
- Validate your work doesn't have the same issue

---

## Cross-Role Patterns

*Patterns will be added as corrections occur across multiple employees*

### Format:
```
## ❌ Pitfall: [Title]

**Applies to**: [Employee roles]
**Frequency**: [X occurrences] across [employees]
**Category**: [Layer Compliance / Security / Testing / Architecture / etc.]

**What happens**: [Description of the mistake]

**Real examples**:
- [Employee 1]: [Specific instance]
- [Employee 2]: [Specific instance]

**Correct approach**:
[How to do it right - with code/design examples]

**Prevention**:
- [Checklist item added]
- [Process improvement made]

**Status**: [Active monitoring / Resolved]
```

---

## Active Patterns (Currently Monitored)

*None yet - will be added as patterns emerge*

---

## Pattern Categories

### 1. Layer Compliance Issues
*No patterns yet*

**Common symptoms**:
- Missing Layer 1 security checks
- Skipped Layer 4 methodology application
- Configuration-First not evaluated

---

### 2. Security & CRUD/FLS
*No patterns yet*

**Common symptoms**:
- Missing `with sharing` keyword
- No CRUD/FLS checks before DML
- Hardcoded credentials

---

### 3. Bulkification & Performance
*No patterns yet*

**Common symptoms**:
- SOQL inside loops
- DML inside loops
- No Collection-based processing

---

### 4. Testing Gaps
*No patterns yet*

**Common symptoms**:
- No bulk testing (200+ records)
- Missing negative test cases
- Insufficient coverage (<75%)

---

### 5. Error Handling
*No patterns yet*

**Common symptoms**:
- No try-catch blocks
- Generic error messages
- No user-friendly error handling

---

### 6. Architecture Oversights
*No patterns yet**

**Common symptoms**:
- Scalability not addressed
- Well-Architected pillars skipped
- Integration patterns missing

---

## Resolved Patterns (No Longer Recurring)

*None yet - patterns move here after 3+ months with no recurrence*

---

## Statistics

**Total Team-Wide Patterns**: 0
**Active Monitoring**: 0
**Resolved**: 0
**Average Occurrences per Pattern**: N/A

---

## Prevention Strategies Applied

*Will be updated as patterns are resolved*

---

## Notes

- **Role-specific patterns** belong in individual employee `references/common-pitfalls.md`
- **Team-wide patterns** (affecting 2+ employees) go here
- **One-off mistakes** stay in team-learnings.md log only

---

*This file helps us avoid repeating mistakes across the team. Every pattern documented is a lesson learned collectively.*
