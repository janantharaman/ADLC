# Common Pitfalls for LWC Developers (Anjali) 🚧

**Role**: LWC Developer
**Employee**: Anjali
**Updated**: Continuously as learnings occur

---

## How to Use This File

**Before Starting Work**: Review recent pitfalls specific to LWC development
**Before Delivery**: Validate your components against documented pitfalls

---

## LWC-Specific Pitfalls

*Pitfalls will be added as corrections occur in LWC development work*

---

## Active Pitfalls (Currently Monitored)

*None yet - will be added as patterns specific to LWC development emerge*

---

## Pitfall Categories

### 1. Reactivity Issues
*No patterns yet*

**Watch for**:
- Missing `@track` or `@api` decorators
- Not using proper reactive patterns
- Mutating objects directly instead of creating new references

---

### 2. Error Handling
*No patterns yet*

**Watch for**:
- Missing error callback in wire/imperative Apex calls
- No user-friendly error messages
- Not handling loading/error states in UI

---

### 3. Accessibility (A11y)
*No patterns yet*

**Watch for**:
- Missing ARIA labels
- No keyboard navigation support
- Poor screen reader experience

---

### 4. Performance
*No patterns yet*

**Watch for**:
- Unnecessary re-renders
- Not using `renderedCallback` efficiently
- Heavy computations in getters

---

### 5. Security
*No patterns yet*

**Watch for**:
- Missing `@AuraEnabled` permission checks
- HTML sanitization gaps
- Exposing sensitive data in client-side JS

---

## Quick Prevention Checklist

Based on documented pitfalls, always check:
- [ ] Proper `@track`/`@api` decorators for reactivity
- [ ] Error handling for all Apex calls
- [ ] ARIA labels and accessibility attributes
- [ ] Loading/error states in UI
- [ ] Component follows LWC best practices

---

## See Also

- **Team-Wide Pitfalls**: `../_shared/common-pitfalls.md`
- **Team Learning Log**: `../_shared/team-learnings.md`

---

*Every documented pitfall makes your components more robust.*
