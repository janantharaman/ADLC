# Common Pitfalls for Solution Architects (Priya) 🚧

**Role**: Solution Architect
**Employee**: Priya
**Updated**: Continuously as learnings occur

---

## Architecture-Specific Pitfalls

*Pitfalls will be added as corrections occur in architecture work*

---

## Pitfall Categories

### 1. Well-Architected Gaps
*No patterns yet*

**Watch for**:
- Missing TRUSTED pillar (security, reliability)
- Missing EASY pillar (UX, maintainability)
- Missing ADAPTABLE pillar (scalability, flexibility)

---

### 2. Scalability Oversights
*No patterns yet*

**Watch for**:
- No LDV (Large Data Volume) strategy
- Missing pagination approach
- No caching strategy

---

### 3. Security Architecture
*No patterns yet*

**Watch for**:
- CRUD/FLS not addressed
- Authentication/authorization gaps
- Data encryption not considered

---

### 4. Configuration-First Not Evaluated
*No patterns yet*

**Watch for**:
- Jumping to code without considering declarative options
- Not evaluating Flow vs Apex trade-offs

---

## Quick Prevention Checklist

- [ ] All 3 Well-Architected pillars addressed (TRUSTED, EASY, ADAPTABLE)
- [ ] Scalability strategy for large data volumes
- [ ] Security architecture explicitly documented
- [ ] Configuration-First evaluation done

---

## See Also

- **Team-Wide Pitfalls**: `../_shared/common-pitfalls.md`
- **Well-Architected Patterns**: `../architecture-references/well-architected-24-patterns.md`

---
