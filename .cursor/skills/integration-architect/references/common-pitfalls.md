# Common Pitfalls for Integration Architects (Rahul) 🚧

**Role**: Integration Architect
**Employee**: Rahul
**Updated**: Continuously as learnings occur

---

## Integration-Specific Pitfalls

*Pitfalls will be added as corrections occur in integration work*

---

## Pitfall Categories

### 1. Error Handling Strategy
*No patterns yet*

**Watch for**:
- No retry logic for failed callouts
- Missing circuit breaker pattern
- No fallback strategy when external system is down

---

### 2. Idempotency
*No patterns yet*

**Watch for**:
- Duplicate request handling not addressed
- No external ID tracking
- Missing deduplication logic

---

### 3. Rate Limiting
*No patterns yet*

**Watch for**:
- Not accounting for external API rate limits
- No queueing/throttling mechanism
- Missing governor limit considerations for callouts

---

### 4. Security & Authentication
*No patterns yet*

**Watch for**:
- Hardcoded credentials
- Not using Named Credentials
- Missing OAuth/JWT patterns

---

## Quick Prevention Checklist

- [ ] Retry logic with exponential backoff
- [ ] Idempotency ensured (external ID tracking)
- [ ] Rate limiting handled
- [ ] Named Credentials for authentication
- [ ] Error responses documented

---

## See Also

- **Team-Wide Pitfalls**: `../_shared/common-pitfalls.md`

---
