---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: security-model
last-updated: 2026-05-11
---

# Agentforce — Security Model

## Einstein Trust Layer

The Einstein Trust Layer is Salesforce's foundational security mechanism for all LLM interactions. Every agent message, every Models API call, every prompt template invocation passes through it.

### Trust Layer Components

| Component | Description |
|---|---|
| **Data Masking** | PII and sensitive data are detected and replaced with tokens before the prompt leaves Salesforce infrastructure |
| **Zero Data Retention** | LLM providers (Anthropic, Google, OpenAI, BYOLLM) contractually cannot retain prompts or responses |
| **Secure Data Retrieval** | Retrieval-augmented generation (RAG) from Salesforce Data Cloud or connected sources goes through Trust Layer |
| **Toxicity Detection** | Both inbound (user) and outbound (LLM) content is scanned; toxic content is blocked |
| **Audit Log** | Every LLM interaction is logged in Einstein Activity Log; log includes: timestamp, user, agent, action, masked prompt, response, token count |
| **Grounding** | Responses are grounded in Salesforce data; hallucinated record references are suppressed |

### What the Trust Layer Does NOT Protect

- Org data shared with the agent via context variables from an external calling system — the calling system is responsible for injecting only appropriate data
- Agent actions that call external APIs directly (not via the Trust Layer) — these are subject only to the security of the called endpoint
- Actions that perform DML — data access follows the agent user's profile/permission set, not the calling user's permissions

---

## Agent User

Every Agentforce agent runs as a dedicated **agent user** — a Salesforce user record assigned to the agent. All Apex, Flow, and SOQL executed by agent actions runs in the context of this user.

### Agent User Security Requirements

| Requirement | Description |
|---|---|
| Dedicated user | The agent user must be a real Salesforce user (not a system admin); create a dedicated user per agent |
| Least privilege | Agent user should have only the permissions needed for its defined actions — not System Administrator |
| Permission Sets | Assign permission sets to the agent user to grant access to specific objects, fields, and Apex actions |
| Named Credential | If agent calls external APIs, use Named Credentials on the agent user — never hardcode credentials |
| CRUD/FLS enforcement | Agent Apex actions MUST enforce CRUD and FLS using `WITH SECURITY_ENFORCED` or `Security.stripInaccessible` |

### Configuring the Agent User

In the Agent metadata (BotVersion or YAML spec):
```yaml
agentUser: my_agent_user@myorg.com.sandbox
```

If `agentUser` is omitted, Salesforce assigns a system-managed user. Always specify explicitly in production configurations.

---

## Permission Requirements

### For Agent Execution

| Permission | Required For | Where to Grant |
|---|---|---|
| `Agentforce User` permission set | Users who interact with agents via Salesforce UI | Profile or Permission Set |
| Object CRUD on invoked objects | Agent Apex / Flow actions to read/write records | Agent user's Profile or Permission Set |
| FLS on accessed fields | Agent actions to read/write specific fields | Agent user's Permission Set |
| Apex class access | AuraEnabled / InvocableMethod actions to execute | Agent user's Profile or Permission Set |
| `Einstein.CreateEmbeddings` | Models API calls — embeddings | Agent user or API user's Permission Set |
| `Einstein.CreateGenerations` | Models API calls — text generation | Agent user or API user's Permission Set |

### For Agent API (External Access)

External systems calling the Agent API must authenticate via:
- OAuth 2.0 Connected App (recommended)
- Session-based auth (short-lived; not recommended for production)

The connected app user must have:
- `API Enabled` system permission
- `Agentforce User` or equivalent permission to initiate sessions

---

## Einstein Requests — Quota and Billing

Einstein Requests (ERs) are the billing unit for Agentforce platform usage.

| Action | ER Consumption |
|---|---|
| Agent API message exchange (1 round trip) | 1 ER |
| Models API `createChatGenerations` call | 1 ER |
| Models API `createEmbeddings` call | 1 ER |
| Models API `createGenerations` call | 1 ER |
| Agent testing via Testing API | ERs consumed per test case (same as runtime) |

Monitor consumption:
- Setup > Einstein > Einstein Requests Usage
- `EinsteinRequestEventLog` object (if Event Log File enabled)

Quota exhaustion: agent sessions fail with a `QUOTA_EXCEEDED` error. Configure alerts before quota is hit.

---

## Org-Level Security Considerations

### OWD and Sharing

Agent actions inherit the agent user's sharing access. Key points:
- If an Agentforce agent uses Named Queries or Invocable Methods that query records, those queries return only records the agent user can see (subject to OWD + sharing rules)
- For agents that need cross-org or admin-level data access, use `WITH SYSTEM_MODE` (System Mode flows) or `without sharing` Apex — but document and justify every use
- Never grant agents access to objects like `User`, `Profile`, or `PermissionSet` unless required

### Connected App Security

For Agent API:
- Use IP restrictions on the Connected App
- Use short token lifetimes (access token expiry ≤ 2 hours for external-facing agents)
- Rotate client secrets quarterly
- Enable "Require Secret for Web Server Flow" for web-based deployments

### Data Residency

Agentforce and Einstein Trust Layer processing occurs within Salesforce's Hyperforce infrastructure. For orgs on Hyperforce with data residency requirements:
- Confirm that the Einstein AI endpoint region matches the org's data residency commitment
- BYOLLM (Bring Your Own LLM) with LLM Open Connector allows directing LLM traffic to a region-specific endpoint

---

## BYOLLM Security Model

When using BYOLLM or LLM Open Connector:
- Named Credential on the LLM endpoint — credentials stored in Salesforce, not in code
- Trust Layer still wraps the call (data masking, toxicity detection, audit log still apply even for BYOLLM)
- Zero-retention guarantee: your custom LLM endpoint must meet Salesforce's data handling requirements or you must explicitly accept the deviation

---

## Common Security Anti-Patterns

| Anti-Pattern | Risk | Correct Approach |
|---|---|---|
| Agent user = System Administrator | Excessive privilege; any compromised action has full org access | Create dedicated agent user with minimal permissions |
| No FLS enforcement in agent Apex | Field-level data exposed regardless of user permissions | Use `WITH SECURITY_ENFORCED` or `Security.stripInaccessible()` on all SOQL |
| Hardcoded API keys in agent Apex | Credential exposure in code and version history | Use Named Credentials |
| Context variables injected without sanitization | Prompt injection via crafted context data | Sanitize all external context variable values; do not pass raw user input as context |
| Single connected app for all agent consumers | Blast radius if the app is compromised | One connected app per integration surface |
| Not specifying `agentUser` | Agent runs as system-managed user; no audit trail on who acted | Always specify `agentUser` explicitly |
