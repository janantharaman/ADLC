# FLS Matrix Template — Discovery Reference

## How to Use

Run the SOQL queries in SKILL.md Step 3 for each object in scope.
Compile results into the table format below for each object.
Flag any cells marked HIGH RISK.

## Risk Flags

| Condition | Risk Level |
|---|---|
| Field is Read=false for a profile that needs it for the process | HIGH — will cause errors |
| Field is Edit=true for a profile that should not modify it | HIGH — data integrity risk |
| Sensitive field (SSN, DOB, Credit, Salary) is Edit=true for all profiles | HIGH — security risk |
| Field has no Read access for any profile | MEDIUM — may be orphaned |
| Inconsistent access across profiles doing the same role | MEDIUM — support risk |

## Template

```markdown
### Object: {ObjectAPIName} ({Label})

| Field API Name | Field Label | Profile / PermSet | Read | Edit | Risk |
|---|---|---|---|---|---|
| Field__c | Field Label | System Administrator | ✓ | ✓ | — |
| Field__c | Field Label | Standard User | ✓ | ✗ | — |
| Sensitive__c | Sensitive Label | Standard User | ✓ | ✓ | HIGH |

**FLS Findings:**
- [Any access gaps or risks identified]
- [Profiles that need access adjusted before go-live]
- [Fields that need visibility rules reviewed]
```

## Common Objects to Check

### Lead / Contact / Account
Key sensitive fields: Email, Phone, MobilePhone, DoNotCall, HasOptedOutOfEmail

### Opportunity
Key fields: Amount, CloseDate, StageName, Probability, ForecastCategory

### Case
Key fields: Status, Priority, OwnerId, AccountId, ContactId, Description

### Custom Objects (per engagement)
Check all fields on custom objects in scope.

## Notes

- Permission Sets override Profile FLS — always check both
- If a field is required on a page layout but the Profile has Edit=false, users will get errors
- Run FLS checks in both the target sandbox AND production — they are not always in sync
- After implementation, re-run this matrix to confirm changes took effect
