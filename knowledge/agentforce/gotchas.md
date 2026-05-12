---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: gotchas
last-updated: 2026-05-11
---

# Agentforce — Gotchas

## G-1: "Topics" → "Subagents" Rename (April 2026)

**What changed:** In April 2026 Salesforce renamed "Topics" to "Subagents" in the UI and documentation. The underlying metadata type (`GenAiPlugin`) and all API names did NOT change. Existing deployments continue to work with no code changes.

**Risk:** Confusion between older documentation (pre-April 2026) that uses "topics" and current documentation that uses "subagents." Both refer to the same construct. When reading pre-April content, mentally substitute "topic" → "subagent."

**How to detect:** If a knowledge article says "create a topic" and you're in the Agentforce Builder UI, look for "New Subagent" — that's the same button.

---

## G-2: Python SDK Variable Types Limited to Text and Boolean

**What:** The `agentforce-sdk` Python package only supports `Text` and `Boolean` as `data_type` values for `Variable`.

**Risk:** Developers expecting to pass `Number`, `Date`, `Id`, or `SObject` variables via Python SDK will get errors. Numbers must be passed as `Text` and converted within the action.

**Workaround:** Serialize numeric and date values as strings in the Python SDK; deserialize in the receiving action.

---

## G-3: Lightning Types — `title` Is Required on Every Type

**What:** Every Lightning Type property definition requires a `title` field at both the outer property level and inside the type definition. Omitting either will cause a validation error when deploying the action.

**Example of incorrect:**
```json
"policyId": {
  "lightning__textType": {}
}
```

**Correct:**
```json
"policyId": {
  "title": "Policy ID",
  "lightning__textType": {
    "title": "Policy ID"
  }
}
```

---

## G-4: InvocableMethod `description` Drives Action Selection

**What:** The `description` field on `@InvocableMethod` is the primary signal Agentforce uses to determine when to call the action. A vague or generic description causes the LLM to skip the action or call the wrong one.

**Anti-pattern:**
```apex
@InvocableMethod(label='Get Data' description='Gets data')
```

**Correct pattern:**
```apex
@InvocableMethod(
    label='Get Policy Summary'
    description='Returns a plain-language summary and current status of an insurance policy. Use when the user asks about their policy, coverage, premium, or renewal date.'
)
```

The description should state WHAT the action does AND the types of user requests that should trigger it.

---

## G-5: Agent User Must Be Explicitly Set in Production

**What:** If `agentUser` is not specified in the Bot metadata or YAML spec, Salesforce creates a system-managed agent user. This user may have inconsistent permissions across sandbox and production, making testing unreliable.

**Risk:** Actions that succeed in sandbox fail in production because the system-managed user has different permissions in each org.

**Fix:** Always specify `agentUser: your_agent_user@your.org` explicitly. Create a dedicated integration user per agent in every org.

---

## G-6: AiEvaluationDefinition Requires API v63.0+

**What:** The `AiEvaluationDefinition` metadata type is only available from API version 63.0 (Spring '26). Any deployment targeting an earlier API version will fail with `UNKNOWN_EXCEPTION` or `INVALID_TYPE`.

**Fix:** Set `<version>63.0</version>` in `package.xml` when including `AiEvaluationDefinition` members.

---

## G-7: Testing API — Run ID Must Be Polled; Results Not Synchronous

**What:** POST to start a test run returns a `runId` immediately, but the test suite runs asynchronously. You must poll GET status until `status = COMPLETED` before calling GET detailed report.

**Anti-pattern:** Calling GET detailed report immediately after POST — returns empty or stale results.

**Correct:** POST start → poll GET status every 2–5 seconds → when `COMPLETED`, call GET detailed report.

---

## G-8: Named Query Actions Are Read-Only

**What:** Named Query action type supports only SELECT SOQL queries. No DML (insert, update, delete) is possible via Named Query. Attempts to include DML in a Named Query configuration will fail at setup time.

**If DML is needed:** Use an Invocable Method action instead.

---

## G-9: Models API Consumes Einstein Requests in Apex Tests

**What:** Calls to `aiplatform.ModelsAPI` in Apex test methods consume real Einstein Requests from the org's quota. Unlike callouts to external services (which can be mocked), Models API calls in tests are NOT automatically mocked.

**Risk:** Running test suites that include Models API calls against a production org can exhaust Einstein Request quota.

**Workaround:** 
- Use `Test.isRunningTest()` to short-circuit Models API calls in test context
- Create a mock provider interface for test isolation
- Never run Models API test methods against production orgs

---

## G-10: Agent Script Transitions Must Be Exhaustive

**What:** In Agent Script, every conditional branch (`|`) that handles a decision point must either cover all cases or include a default branch. If a user response doesn't match any defined branch, the script stalls with no response.

**Anti-pattern:**
```
# confirm_policy
| Yes -> collect_claim_details
| No -> retry_policy_lookup
```
(What happens if the user says "Maybe" or provides an unrelated response?)

**Correct:**
```
# confirm_policy
| Yes -> collect_claim_details
| No -> retry_policy_lookup
| @default -> confirm_policy_again
```

---

## G-11: Context Variables Are Read-Only in Receiving Agent (Multi-Agent)

**What:** When Agent A invokes Agent B as a subagent, Agent A can pass context variables to Agent B. Those variables are read-only in Agent B's scope — Agent B cannot modify them. Agent B can only write to its own `Conversation`-scoped variables.

**Risk:** Assuming a called agent can update shared state and read the updates back — it cannot. Design multi-agent data flow so each agent owns its own data domain.

---

## G-12: BYOLLM Does Not Bypass Trust Layer

**What:** Bringing Your Own LLM via LLM Open Connector still routes through the Einstein Trust Layer. Data masking, toxicity detection, and audit logging all still apply. BYOLLM is NOT a way to skip security controls.

**Risk:** Architects assuming BYOLLM removes Trust Layer overhead and designing around it.

**Reality:** BYOLLM only affects which LLM model processes the prompt — the Trust Layer wrapper remains.

---

## G-13: GenAiPlannerBundle Wildcard (*) Deployment Can Timeout

**What:** Deploying `GenAiPlannerBundle:*` in `package.xml` retrieves all planner bundles in the org, which can be very large in orgs with many agents. Retrieval may time out.

**Fix:** Always deploy specific named members: `<members>My_Agent_Planner</members>` rather than using wildcards.

---

## G-14: Mobile SDK iOS Minimum Version Is iOS 17

**What:** The Agentforce iOS Mobile SDK requires iOS 17+ and is built with SwiftUI. Apps targeting iOS 16 or earlier cannot use the SDK.

**Risk:** Field service or mobile deployments assuming broad iOS compatibility.

---

## G-15: Python SDK Does Not Sync Back to Salesforce Org in Real-Time

**What:** The `agentforce-sdk` creates agent configurations programmatically, but deployment to the org is a separate step. The SDK generates metadata or calls the Agent API — it does not directly hot-reload a running agent in the org.

**Common misunderstanding:** Calling `AgentUtils.create_agent_from_file()` does not immediately update the live agent in production. It creates/updates the agent configuration via API, which still requires activation in the org.

---

## G-16: Apex Governor Limits Apply to Agent Actions

**What:** Invocable Method and AuraEnabled actions called by Agentforce run in the same Apex transaction context as any other Apex code. All governor limits apply: 100 SOQL queries, 150 DML operations, 10 MB heap, 10 seconds CPU time.

**Risk:** Multi-step agent workflows that chain several actions in sequence may approach limits, especially if each action queries multiple objects.

**Mitigation:**
- Keep each action focused on a single operation
- Use Queueable for work that can be deferred
- Aggregate SOQL queries where possible
