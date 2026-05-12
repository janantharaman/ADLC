# Common Pitfalls for Apex Developers (Vikram) 🚧

**Role**: Apex Developer
**Employee**: Vikram
**Updated**: Continuously as learnings occur

---

## How to Use This File

**Before Starting Work**:
- Review recent pitfalls specific to Apex development
- Check if your current task relates to any documented pattern

**Before Delivery**:
- Validate your code against documented pitfalls
- Ensure preventive checks have been applied

---

## Apex-Specific Pitfalls

*Pitfalls will be added as corrections occur in Apex development work*

### Format:
```
## ❌ Pitfall #[N]: [Short Title]

**Date**: [When it happened]
**Context**: [What task/requirement]
**Category**: [Bulkification / Security / Testing / Performance / etc.]

**What went wrong**:
[Specific mistake made]

**User feedback**:
"[Exact user quote]"

**Incorrect code**:
```apex
// The wrong approach
[Code that caused the issue]
```

**Corrected code**:
```apex
// The correct approach
[Fixed code]
```

**Why this matters**:
[Impact / consequences of the mistake]

**Lesson learned**:
[Key takeaway]

**Prevention added to checklist**:
- [ ] [New checklist item]

**Status**: [Monitoring / Resolved]
```

---

## Active Pitfalls (Currently Monitored)

---

### ❌ Pitfall #1: SOQL Inside Loop

**Date**: 2026-03-03
**Context**: Account trigger - updating related Contacts based on Account rating change
**Category**: Bulkification & Performance

**What went wrong**:
SOQL query was placed inside a for loop, causing governor limit exceptions with 200+ Account records.

**User feedback**:
"This won't work with 200 Accounts - you'll hit the SOQL query limit"

**Incorrect code**:
```apex
// ❌ WRONG - SOQL in loop (hits governor limit at 101 Accounts)
trigger AccountTrigger on Account (after update) {
    for (Account acc : Trigger.new) {
        // SOQL inside loop - FAILS with bulk data!
        List<Contact> contacts = [
            SELECT Id, CustomField__c
            FROM Contact
            WHERE AccountId = :acc.Id
        ];

        for (Contact c : contacts) {
            c.CustomField__c = acc.Rating;
        }
        update contacts;
    }
}
```

**Corrected code**:
```apex
// ✅ CORRECT - Single SOQL query, Map for lookups
trigger AccountTrigger on Account (after update) {
    Set<Id> accountIds = Trigger.newMap.keySet();

    // Single SOQL query outside loop
    Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
    for (Contact c : [
        SELECT Id, AccountId, CustomField__c
        FROM Contact
        WHERE AccountId IN :accountIds
    ]) {
        if (!contactsByAccount.containsKey(c.AccountId)) {
            contactsByAccount.put(c.AccountId, new List<Contact>());
        }
        contactsByAccount.get(c.AccountId).add(c);
    }

    // Process using Map lookup
    List<Contact> contactsToUpdate = new List<Contact>();
    for (Account acc : Trigger.new) {
        if (contactsByAccount.containsKey(acc.Id)) {
            for (Contact c : contactsByAccount.get(acc.Id)) {
                c.CustomField__c = acc.Rating;
                contactsToUpdate.add(c);
            }
        }
    }

    if (!contactsToUpdate.isEmpty()) {
        update contactsToUpdate;
    }
}
```

**Why this matters**:
- **Governor Limit**: SOQL limit is 100 queries per transaction
- **Production Risk**: Fails silently in sandbox, crashes in production with bulk data
- **Layer 1 Violation**: Bulkification is mandatory in all Apex code

**Lesson learned**:
Always move SOQL queries outside loops. Use Collections (Map, Set, List) for bulk data processing.

**Prevention added to checklist**:
- [x] No SOQL queries inside loops?
- [x] Code handles 200+ records in single transaction?
- [x] Using Map/Set for lookups instead of repeated queries?

**Status**: Active monitoring

---

## Pitfall Categories

### 1. Bulkification Issues
**Patterns Documented**: 1 (See Pitfall #1)

**Watch for**:
- SOQL inside loops ✅ Pitfall #1 documented
- DML inside loops
- Not using Collections (Maps, Lists, Sets)

---

### 2. Governor Limits
*No patterns yet*

**Watch for**:
- Hitting SOQL query limits (101+)
- Hitting DML statement limits (151+)
- Hitting CPU time limits

---

### 3. Security (CRUD/FLS)
*No patterns yet*

**Watch for**:
- Missing `with sharing` keyword
- No CRUD checks before SOQL/DML
- No `Security.stripInaccessible()` on DML operations

---

### 4. Testing Gaps
*No patterns yet*

**Watch for**:
- Missing bulk test scenarios (200+ records)
- No negative test cases
- Insufficient coverage (<75%)

---

### 5. Trigger Patterns
*No patterns yet*

**Watch for**:
- Logic in trigger itself (should be in handler)
- Not following trigger framework pattern
- No context variable checks

---

### 6. Async Apex Issues
*No patterns yet*

**Watch for**:
- Missing error handling in future/queueable
- Not checking async limits
- Missing retry logic

---

## Resolved Pitfalls

*Pitfalls move here after 3+ months with no recurrence*

---

## Statistics

**Total Pitfalls Documented**: 1
**Active Monitoring**: 1
**Resolved**: 0
**Average Time to Resolution**: N/A
**Last Updated**: 2026-03-03

---

## Quick Prevention Checklist

Based on documented pitfalls, always check:
- [ ] No SOQL/DML inside loops
- [ ] `with sharing` keyword present
- [ ] CRUD/FLS checks before database operations
- [ ] Bulk test scenario included (200+ records)
- [ ] Following trigger framework pattern (if trigger work)

*This checklist grows as pitfalls are documented*

---

## See Also

- **Team-Wide Pitfalls**: `../_shared/common-pitfalls.md` (applies to all employees)
- **Team Learning Log**: `../_shared/team-learnings.md` (all corrections tracked)
- **Apex Best Practices**: `bulkification-examples.md`, `trigger-framework-pattern.md`

---

*This file makes you a better developer over time. Every documented pitfall is a lesson learned.*
