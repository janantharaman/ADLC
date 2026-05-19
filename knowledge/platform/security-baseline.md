# Security Baseline — GDC Delivery Standards

Apply these checks during Discovery (verify current state) and Design/Implementation (enforce standards).
Any deviation from these baselines must be documented with a business justification in the artifact.

---

## Org-Wide Defaults (OWD)

| Object | Minimum Recommended OWD | Risk if Public Read/Write |
|---|---|---|
| Account | Private or Public Read Only | Data leakage across territories |
| Contact | Controlled by Parent | Exposure of personal data |
| Opportunity | Private | Revenue data visible to all users |
| Case | Private | Customer data exposure |
| Custom Objects (sensitive) | Private | Depends on data classification |
| Custom Objects (reference/config) | Public Read Only | Acceptable for lookup data |

**Flag as HIGH RISK:** Any sensitive object with OWD = Public Read/Write.
**Flag as MEDIUM RISK:** Any Opportunity or Case with OWD = Public Read Only.

---

## Profile and Permission Set Standards

- Never assign System Administrator profile to operational users
- Never use the System Administrator profile for API integrations — create a dedicated Integration User
- Every user should have the minimum permissions required for their role (principle of least privilege)
- Permission sets preferred over profile customisation — never modify standard profiles
- Review permission sets quarterly — remove unused assignments
- API-only users must have "API Only" or equivalent restriction — no UI login

---

## Field-Level Security

- Sensitive fields (PII, financial, health) must have Edit=false for all profiles except those that specifically need to write them
- Social Security Numbers, Credit Card Numbers, Bank Account Numbers — must never be stored in plain text custom fields; use Shield Platform Encryption or a managed package
- Fields containing PII must be documented in the Data Dictionary section of the Discovery artifact
- Default field visibility should be Read Only — grant Edit only where required

**PII Field Categories to flag during Discovery:**
- Name fields (FirstName, LastName, Full Name)
- Contact fields (Email, Phone, MobilePhone, HomePhone)
- Address fields (MailingStreet, BillingAddress, etc.)
- Date of Birth, Age, Gender
- Financial fields (Salary, Annual Revenue, Credit Score)
- Government IDs (SSN, Tax ID, Passport Number)
- Health information

---

## Sharing Rules

- Sharing rules should extend access, never restrict it below OWD
- Criteria-based sharing is preferred over ownership-based for predictability
- Document every sharing rule and its business justification
- Manual sharing should be minimised — it is not auditable at scale
- If a user consistently needs to manually share records, there is a sharing model design issue

---

## Connected Apps and OAuth

- Every Connected App must have an owner and documented business purpose
- OAuth scopes must follow least privilege — do not grant "Full Access" unless required
- Review Connected Apps during Discovery — decommission any without a current owner
- Client credentials flow preferred for server-to-server integrations (no user context)
- Refresh token policies must be set — no indefinite tokens for non-service accounts

---

## Apex Security

- All Apex must enforce FLS and CRUD using `Security.stripInaccessible()` or `WITH SECURITY_ENFORCED`
- No hardcoded credentials, endpoints, or secrets in Apex code — use Named Credentials and Custom Metadata
- All Apex running in user context must respect sharing rules (use `with sharing`)
- System-level operations that must bypass sharing must use `without sharing` explicitly and be documented
- No SOQL injection — always use bind variables (`WHERE Id = :recordId`), never string concatenation

```apex
// CORRECT
List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];

// INCORRECT — never do this
List<Account> accounts = Database.query('SELECT Id FROM Account WHERE Id = \'' + accountId + '\'');
```

---

## Flow Security

- Record-triggered flows run in system context — be explicit about what they can access
- Screen flows run in user context by default — test with lowest-privilege user
- Never use Flow to bypass sharing rules without documented justification
- Flows that access sensitive data must have FLS-aware Get Records elements
- Subflows must be documented — a chain of 5+ subflows is a complexity risk

---

## Integration Security

- All external integrations must use Named Credentials — no hardcoded URLs in code
- All inbound integrations must validate the source (IP allowlist, certificate, or signed payload)
- API user accounts must have IP restrictions where possible
- Outbound callouts must have a timeout set (max 120 seconds)
- Sensitive data in callout payloads must be logged at DEBUG level only, not INFO

---

## Data Security

- No production data in sandboxes — use Data Mask or anonymise before refresh
- No PII in test data — use generated/synthetic data in all test classes
- Bulk operations (50,000+ records) require explicit human approval during Implementation
- Data deletion is irreversible — always require explicit approval and backup confirmation

---

## Session and Login Security

- Session timeout: maximum 2 hours for standard users, 8 hours for admin users
- IP restrictions: required for all integration/API-only users
- MFA: required — verify during Discovery that MFA is enabled org-wide
- Login hours: restrict for service accounts where possible
- Single Sign-On: preferred for human users — reduces credential management risk
