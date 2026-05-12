---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); Agentblazer Champion/Innovator/Legend curriculum; grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: implementation-guide
last-updated: 2026-05-11
---

# Agentforce — Implementation Guide

## Prerequisites

| Prerequisite | Verification |
|---|---|
| Agentforce license provisioned | Setup > Company Information > Licenses — look for "Agentforce for Salesforce" or "Einstein Platform" |
| Einstein Requests quota allocated | Setup > Einstein > Einstein Requests Usage |
| Experience Cloud site (if customer-facing) | Setup > Digital Experiences > All Sites |
| Agentforce-enabled profile/permission set for users | Setup > Permission Sets — confirm "Agentforce User" available |
| API version 59.0+ for most features; 63.0+ for Testing | Check scratch org or package.xml version |
| Agentforce DX (if code-first): Salesforce CLI v2.x + VS Code + Salesforce Extension Pack | `sf version` in terminal |

---

## Agentblazer Learning Progression

Build agent knowledge and implementation skills in this order:

### Champion Level (Foundation — Before Building)
1. Understand what Agentforce is: autonomous agents, Einstein Trust Layer, action types
2. Learn agent builder UI (no-code): Setup > Agents > New
3. Understand the 5 action types and when each applies
4. Know the terminology: agent, subagent (formerly topic), action, variable, session
5. Understand Einstein Requests billing model

### Innovator Level (Intermediate — Before Production)
1. Agent API: start sessions, exchange messages, end sessions
2. Models API: `aiplatform.ModelsAPI` — chat generation, embeddings, feedback
3. Agentforce DX: YAML spec authoring, CLI deployment, VS Code workflow
4. Testing API: `AiEvaluationDefinition` metadata + Connect API (start/poll/report)
5. Advanced actions: Invocable Methods with proper `description` annotations

### Legend Level (Advanced — For Complex Implementations)
1. Agent Script: deterministic + LLM hybrid authoring; full symbol/keyword set
2. Citations Apex: `GenAiActionOutput`, `GenAiSourceReference`, full citation chain
3. Lightning Types: schema.json authoring; 12 type definitions
4. Mobile SDK: iOS (SwiftUI, iOS 17+, CocoaPods) + Android (Jetpack Compose, API 29+)
5. Python SDK: `agentforce-sdk`; creating agents from YAML and modular files
6. Multi-agent orchestration: `@subagent.name` in Agent Script; context variable passing
7. BYOLLM: LLM Open Connector configuration; Named Credential on custom endpoint

---

## Phase 1: Design

### Step 1 — Define Agent Scope

Answer these questions before writing any code:
- What is the agent's primary persona? (Customer service? Internal productivity? Field rep support?)
- What are the 3–5 main domains (subagents) this agent needs to handle?
- For each domain: what information does the agent need to retrieve or write?
- What objects and fields in the org does the agent need access to?
- What is the agent's escalation path? (Human handoff via `@utils.escalate` or `Live Agent`)
- Is the agent internal (Salesforce UI) or external (Agent API / site)? → Determines `agent_type`

### Step 2 — Map Actions to Objects

| Subagent | Object(s) | Read/Write | Action Type |
|---|---|---|---|
| Policy Info | Policy__c | Read only | Named Query or Invocable |
| Claim Intake | Claim__c | Write (create) | Invocable |
| Knowledge Search | Knowledge__kav | Read only | Invocable (with Citations) |
| Escalation | Case | Write (update) | Invocable |

### Step 3 — Design the Agent User

1. Create a dedicated integration user for the agent in Setup > Users
2. Assign minimal permission sets: only the objects and fields the agent actions need
3. Test the user's access by running the SOQL queries your actions will use as that user

---

## Phase 2: Build Actions

### Step 4 — Create Invocable Methods

For each action in your map:

```apex
@InvocableMethod(
    label='[Human readable name]'
    description='[Specific description of what this action does AND when to invoke it]'
    category='[Your category]'
)
public static List<Response> execute(List<Request> requests) {
    // Always: CRUD/FLS enforcement on all SOQL
    // Never: DML outside of WITH SECURITY_ENFORCED queries
    // Governor limits: design for bulk (list input, list output)
}
```

Checklist per action:
- [ ] `@InvocableVariable` on all Request and Response fields
- [ ] `WITH SECURITY_ENFORCED` on all SOQL
- [ ] Bulkified (processes list, not single record)
- [ ] `description` on `@InvocableMethod` is specific and includes trigger keywords
- [ ] Test class with > 75% coverage written

### Step 5 — Register Actions in Setup

In Agentforce Builder (Setup > Agents > [Agent] > Actions):
1. Click New Action
2. Select action type (Flow, Apex, SOQL, etc.)
3. Find your Invocable Method by its `label`
4. Review parameter mapping
5. Confirm the action description (editable in Builder — override the annotation if needed for clarity)

---

## Phase 3: Build Agent (Agentforce DX — Code First)

### Step 6 — YAML Spec Structure

```yaml
# agent.yaml
agentType: External          # External | Internal
companyName: LKInsurance
role: |
  You are the LKInsurance customer service agent. You help customers
  manage their insurance policies, file claims, and find answers to
  policy questions. You always respond professionally and verify
  identity before discussing account details.
maxNumOfTopics: 5            # Default: 5; max number of active subagents
tone: neutral                # casual | formal | neutral
agentUser: agent_user@lkinsurance.com.sandbox  # Always specify
enrichLogs: true             # Enable detailed audit logging

topics:
  - name: PolicyInfo
    description: Handles policy information requests
    scope: Policy details, coverage questions, premium amounts, renewal dates
    instructions:
      - Always verify policy ID before returning details
      - Never share another customer's policy information
    actions:
      - GetPolicySummaryAction
      - GetPolicyDocumentsAction

  - name: ClaimIntake
    description: Handles new claim filing and claim status checks
    scope: Filing a claim, claim status, claim documents, claim payments
    instructions:
      - Verify policy is active before accepting claim
      - Always provide a claim reference number at completion
      - For emergency claims, immediately offer to escalate to human agent
    actions:
      - GetPolicySummaryAction
      - CreateClaimAction
      - GetClaimStatusAction
```

### Step 7 — CLI Workflow (Agentforce DX)

```bash
# 1. Authenticate to org
sf org login web --alias lkinsurance-dev

# 2. Pull existing agent definition from org (if starting from existing)
sf agent retrieve --agent-name "LKInsurance Customer Agent" --output-dir ./agents/

# 3. Edit YAML spec
code ./agents/lkinsurance_customer_agent.yaml

# 4. Validate spec (dry run)
sf agent deploy --manifest ./agents/lkinsurance_customer_agent.yaml --check-only

# 5. Deploy agent
sf agent deploy --manifest ./agents/lkinsurance_customer_agent.yaml

# 6. Activate agent version
sf agent activate --agent-name "LKInsurance Customer Agent"
```

---

## Phase 4: Testing

### Step 8 — Write AiEvaluationDefinition

```yaml
# test_suite.aiEvaluationDefinition
fullName: LKInsuranceAgentTestSuite
subjectType: AGENT
subjectName: LKInsurance_Customer_Agent
testCases:
  - utterance: "What is my policy premium for policy P-001?"
    expectedTopic: PolicyInfo
    expectedActions: [GetPolicySummaryAction]
    expectedOutcome: "Premium amount stated"

  - utterance: "I was in a car accident yesterday and need to file a claim"
    expectedTopic: ClaimIntake
    expectedActions: [GetPolicySummaryAction, CreateClaimAction]
    expectedOutcome: "Claim reference number provided"

  - utterance: "Can you tell me my neighbor's policy details?"
    expectedTopic: PolicyInfo
    expectedActions: [GetPolicySummaryAction]
    expectedOutcome: "Declined to provide other customer information"
```

### Step 9 — Run Tests via Connect API

```python
import requests

headers = {'Authorization': f'Bearer {session_id}', 'Content-Type': 'application/json'}
base = 'https://org.my.salesforce.com/services/data/v66.0/connect/ai-evaluations'

# Start
r = requests.post(base, json={
    'subjectName': 'LKInsurance_Customer_Agent',
    'subjectType': 'AGENT',
    'evaluationDefinitionName': 'LKInsuranceAgentTestSuite'
}, headers=headers)
run_id = r.json()['runId']

# Poll
import time
while True:
    status = requests.get(f'{base}/{run_id}', headers=headers).json()
    if status['status'] in ('COMPLETED', 'ERROR'):
        break
    time.sleep(3)

# Report
report = requests.get(f'{base}/{run_id}/details', headers=headers).json()
for result in report['testResults']:
    for metric in result['metrics']:
        print(f"{result['utterance'][:50]} | {metric['name']}: {metric['metricScore']}")
```

---

## Phase 5: Mobile SDK Setup (if mobile agent surface needed)

### iOS (SwiftUI)

```bash
# Podfile
pod 'AgentforceSDK', '~> 1.0'
```

```swift
import AgentforceSDK

// Initialize client
let client = AgentforceClient(
    instanceURL: URL(string: "https://yourorg.my.salesforce.com")!,
    accessToken: accessToken
)

// Start conversation
let conversation = try await client.startConversation(agentId: "0GxXXXXXXXXXXXX")

// Send message
let response = try await conversation.sendMessage("I need to file a claim")
print(response.text)
```

### Android (Jetpack Compose)

```kotlin
// build.gradle
implementation("com.salesforce.agentforce:sdk:1.0.0")

// In Composable
val client = remember { AgentforceClient(instanceUrl, accessToken) }
val conversation = remember { mutableStateOf<AgentforceConversation?>(null) }

LaunchedEffect(Unit) {
    conversation.value = client.startConversation(agentId)
}

// Send message
scope.launch {
    val response = conversation.value?.sendMessage(userInput)
    // Update UI with response.text
}
```

---

## Post-Deployment Checklist

After every Agentforce agent deployment to production:

- [ ] Agent user created and assigned with minimal permissions
- [ ] `agentUser` field explicitly set in Bot metadata
- [ ] All Invocable actions have specific, trigger-keyword-rich `description` annotations
- [ ] All action Apex classes enforce `WITH SECURITY_ENFORCED` on SOQL
- [ ] Agent test suite (`AiEvaluationDefinition`) deployed and all test cases pass
- [ ] Einstein Requests quota confirmed for expected session volume
- [ ] If Agent API: Connected App configured with IP restrictions and short token expiry
- [ ] Escalation path confirmed: `@utils.escalate` routes to correct queue or Live Agent config
- [ ] Einstein Activity Log reviewed for first 10 sessions after go-live
- [ ] If BYOLLM: Named Credential on LLM endpoint verified, Trust Layer still active
