# Governor Limits — GDC Delivery Standards

Reference these during Discovery (check current utilisation) and Implementation (design within limits).
Flag any limit at > 80% utilisation as HIGH RISK in the Discovery artifact.

---

## Per-Transaction Limits (Apex)

| Limit | Threshold | GDC Design Rule |
|---|---|---|
| SOQL queries | 100 | Design for < 50; never query inside a loop |
| SOQL rows returned | 50,000 | Use LIMIT clauses; paginate large datasets |
| DML statements | 150 | Bulkify all DML; collect records and DML once |
| DML rows | 10,000 | Design batch sizes around this limit |
| CPU time (sync) | 10,000ms | Flag any class consuming > 3,000ms in tests |
| CPU time (async) | 60,000ms | Use Queueable/Batch for heavy processing |
| Heap size (sync) | 6MB | Avoid large string/blob operations in sync context |
| Heap size (async) | 12MB | |
| Callouts per transaction | 100 | Never loop callouts — use Queueable chain |
| Callout timeout | 120 seconds | Always set explicit timeout on HttpRequest |
| Future calls per transaction | 50 | Prefer Queueable over @future |

**Design rule: Never query or DML inside a for loop.** This is the most common limit violation.

```apex
// WRONG — SOQL in loop
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}

// CORRECT — bulkified
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    if (!contactsByAccount.containsKey(c.AccountId)) {
        contactsByAccount.put(c.AccountId, new List<Contact>());
    }
    contactsByAccount.get(c.AccountId).add(c);
}
```

---

## Org-Wide Limits

| Limit | Threshold | Check During Discovery |
|---|---|---|
| Daily API calls | Varies by edition/user count | Check OrgLimit: DailyApiRequests |
| Concurrent API calls | 25 (unlimited edition) | Check OrgLimit: ConcurrentAsyncGetReportInstances |
| Streaming API concurrent clients | 1,000 | Check if Platform Events in use |
| Bulk API v2 daily jobs | 15,000 | |
| File storage | Varies | Check % used |
| Data storage | Varies | Check % used; flag if > 80% |
| Custom objects | 800 (Enterprise) | Count during Discovery |
| Custom fields per object | 500 | Count per object |
| Active Flows | 4,000 | Count during Discovery |
| Apex classes | 5,000 | Count during Discovery |
| Scheduled Apex jobs | 100 concurrent | Check current scheduled jobs |

---

## Flow Limits

| Limit | Threshold | GDC Design Rule |
|---|---|---|
| Flow elements per flow | 2,000 | Break large flows into subflows |
| Active flow versions | 50 per definition | Delete old versions regularly |
| Flow interviews (sync) | 2,000 per transaction | Design for bulk scenarios |
| Flow bulk processing | 200 records per batch | Test record-triggered flows with bulk data |
| Screen flow steps | No hard limit | Keep under 10 screens for usability |
| Subflow depth | No hard limit | Keep under 5 levels for maintainability |

**Design rule:** Record-triggered flows must be tested with a bulk insert of 200 records before deployment. This is the platform batch size.

---

## Apex Test Coverage Requirements

| Scope | Platform Minimum | GDC Standard |
|---|---|---|
| Overall org coverage | 75% | 85% |
| Individual class | No individual minimum (platform) | 85% per class |
| Trigger handlers | 75% (platform) | 90% per handler |
| Batch classes | 75% (platform) | 85% |

**Every Apex class must have a corresponding test class.**
**Test classes must test failure scenarios, not just happy paths.**
**Never use SeeAllData=true in test classes.**

---

## Integration Limits

| System | Limit | Notes |
|---|---|---|
| REST API per day | Varies by edition | Check OrgLimit: DailyApiRequests |
| Bulk API v2 records per job | 150M rows | Use for > 10,000 record operations |
| Streaming / Platform Events | 250,000 per day (Enterprise) | Check OrgLimit: DailyDeliveredPlatformEvents |
| Named Credential callout timeout | 120 seconds | Set on every HttpRequest |
| Outbound messages per day | Unlimited (but monitor) | Check queue depth |

---

## Agentforce Limits

| Limit | Threshold | Notes |
|---|---|---|
| Agent topics per agent | 20 | Design topic structure carefully |
| Actions per topic | 20 | |
| Max turns per conversation | Varies | Design for concise, bounded conversations |
| Agent test suite runs per day | Varies by license | |

---

## How to Check Limits During Discovery

Use `mcp__salesforce__run_soql_query` to query OrgLimit:

```sql
SELECT CurrentValue, MaxValue, Remaining, Type
FROM OrgLimit
ORDER BY Type
```

Key limits to check by name:
- `DailyApiRequests` — daily REST API calls
- `DailyBulkV2QueryJobs` — Bulk API usage
- `ActiveScratchOrgs` — if DevHub
- `DailyDeliveredPlatformEvents` — if using Platform Events/Streaming
- `DataStorageMB` — data storage
- `FileStorageMB` — file storage

Calculate % used:
```
% used = (CurrentValue / MaxValue) * 100
```

Flag thresholds:
- > 80%: HIGH RISK — recommend immediate action before implementation
- 60-80%: MEDIUM RISK — monitor, plan for growth
- < 60%: LOW RISK — document for baseline
