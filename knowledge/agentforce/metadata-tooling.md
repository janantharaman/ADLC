---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: metadata-tooling
last-updated: 2026-05-11
---

# Agentforce — Metadata & Tooling

## Metadata Types Summary

| Metadata Type | API Version | File Suffix | Directory | Wildcard (*) |
|---|---|---|---|---|
| `AiAuthoringBundle` | v59.0+ | `.aiAuthoringBundle` | `aiAuthoringBundles/` | Yes |
| `Bot` | v47.0+ | `.bot` | `bots/` | Yes |
| `BotVersion` | v47.0+ | `.botVersion` | `bots/{BotName}/` | Yes |
| `GenAiFunction` | v59.0+ | `.genAiFunction` | `genAiFunctions/` | Yes |
| `GenAiPlannerBundle` | v59.0+ | `.genAiPlannerBundle` | `genAiPlannerBundles/` | No — use named members |
| `GenAiPlugin` | v59.0+ | `.genAiPlugin` | `genAiPlugins/` | Yes |
| `AiEvaluationDefinition` | v63.0+ | `.aiEvaluationDefinition` | `aiEvaluationDefinitions/` | Yes |

---

## Metadata Type Details

### AiAuthoringBundle

Full agent configuration export format. Used by Agentforce DX. Targets `Bot.BotVersion` format internally.

**When to use:** Primary artifact for version-controlling agent configurations in DX-based workflows. Use this instead of manually managing `Bot` + `BotVersion` separately.

**Sample XML (abbreviated):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<AiAuthoringBundle xmlns="http://soap.sforce.com/2006/04/metadata">
  <agentType>External</agentType>
  <companyName>LKInsurance</companyName>
  <role>You are the LKInsurance customer service agent...</role>
  <maxNumOfTopics>5</maxNumOfTopics>
  <tone>neutral</tone>
  <agentUser>agent_user@lkinsurance.com.sandbox</agentUser>
</AiAuthoringBundle>
```

---

### Bot

Container for an Agentforce agent. One Bot record per agent.

**File location:** `bots/{BotDeveloperName}.bot`

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Bot xmlns="http://soap.sforce.com/2006/04/metadata">
  <botUser>agent_user@lkinsurance.com</botUser>
  <contextVariables>
    <dataType>Text</dataType>
    <developerName>CustomerId</developerName>
    <label>Customer ID</label>
    <varType>Context</varType>
  </contextVariables>
  <description>LKInsurance Customer Service Agent</description>
  <label>LKInsurance Customer Agent</label>
</Bot>
```

**Package manifest:**
```xml
<types>
  <members>LKInsurance_Customer_Agent</members>
  <name>Bot</name>
</types>
```

---

### BotVersion

Versioned configuration of an agent. Contains conversation variables and flow references.

**File location:** `bots/{BotName}/{BotName}.botVersion`

**Sample XML (BotVersion with ConversationVariable):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<BotVersion xmlns="http://soap.sforce.com/2006/04/metadata">
  <conversationVariables>
    <dataType>Text</dataType>
    <developerName>currentPolicyId</developerName>
    <label>Current Policy ID</label>
    <varType>Conversation</varType>
  </conversationVariables>
  <conversationVariables>
    <dataType>Boolean</dataType>
    <developerName>isVerified</developerName>
    <label>Customer Verified</label>
    <varType>Conversation</varType>
  </conversationVariables>
  <entryDialog>Greeting</entryDialog>
</BotVersion>
```

---

### GenAiFunction (Action)

Represents a single callable action.

**File location:** `genAiFunctions/{FunctionDeveloperName}.genAiFunction`

**Sample XML (Invocable Method action):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
  <description>Returns a plain-language summary and current status of an insurance policy. Use when the user asks about their policy, coverage, premium, or renewal date.</description>
  <functionType>SfdcApexMethod</functionType>
  <label>Get Policy Summary</label>
  <parameters>
    <description>The Salesforce ID of the policy record</description>
    <isRequired>true</isRequired>
    <label>Policy ID</label>
    <parameterName>policyId</parameterName>
    <parameterType>String</parameterType>
  </parameters>
  <outputParameters>
    <description>Plain-language summary of the policy</description>
    <label>Policy Summary</label>
    <parameterName>summary</parameterName>
    <parameterType>String</parameterType>
  </outputParameters>
</GenAiFunction>
```

**Sample XML (Named Query action):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
  <description>Finds active policies for a customer. Use when the user asks to list their policies.</description>
  <functionType>SfdcSoqlQuery</functionType>
  <label>List Customer Policies</label>
</GenAiFunction>
```

**Package manifest:**
```xml
<types>
  <members>GetPolicySummaryAction</members>
  <members>CreateClaimAction</members>
  <members>ListCustomerPolicies</members>
  <name>GenAiFunction</name>
</types>
```

---

### GenAiPlugin (Subagent / Topic)

Represents a subagent domain. References actions available within the domain.

**File location:** `genAiPlugins/{PluginDeveloperName}.genAiPlugin`

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<GenAiPlugin xmlns="http://soap.sforce.com/2006/04/metadata">
  <description>Handles insurance policy information requests and coverage questions</description>
  <genAiFunctions>
    <functionName>GetPolicySummaryAction</functionName>
    <functionName>GetPolicyDocumentsAction</functionName>
  </genAiFunctions>
  <instructions>Always verify policy ID before returning details. Never share another customer's policy information.</instructions>
  <label>Policy Info</label>
  <pluginInstructions>
    <description>Identity verification requirement</description>
    <instructionType>Standard</instructionType>
    <language>en_US</language>
  </pluginInstructions>
  <scope>Policy details, coverage questions, premium amounts, renewal dates</scope>
</GenAiPlugin>
```

**Package manifest:**
```xml
<types>
  <members>PolicyInfo</members>
  <members>ClaimIntake</members>
  <name>GenAiPlugin</name>
</types>
```

---

### GenAiPlannerBundle

Groups subagents and actions for agent planning configuration.

**File location:** `genAiPlannerBundles/{BundleDeveloperName}.genAiPlannerBundle`

**Note on wildcard:** Do NOT use `*` for `GenAiPlannerBundle` in package.xml — always use named members. Wildcard can cause timeout on large orgs.

**Package manifest:**
```xml
<types>
  <members>LKInsurance_Customer_Agent_Planner</members>
  <name>GenAiPlannerBundle</name>
</types>
```

---

### AiEvaluationDefinition

Agent test suite for automated testing via Connect API. Minimum API version v63.0.

**File location:** `aiEvaluationDefinitions/{TestSuiteDeveloperName}.aiEvaluationDefinition`

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<AiEvaluationDefinition xmlns="http://soap.sforce.com/2006/04/metadata">
  <subjectType>AGENT</subjectType>
  <subjectName>LKInsurance_Customer_Agent</subjectName>
  <testCases>
    <utterance>What is my policy premium?</utterance>
    <expectedTopic>PolicyInfo</expectedTopic>
    <expectedActions>GetPolicySummaryAction</expectedActions>
    <expectedOutcome>Premium amount stated</expectedOutcome>
  </testCases>
  <testCases>
    <utterance>I need to file a claim for my auto policy</utterance>
    <expectedTopic>ClaimIntake</expectedTopic>
    <expectedActions>GetPolicySummaryAction</expectedActions>
    <expectedActions>CreateClaimAction</expectedActions>
    <expectedOutcome>Claim reference number provided</expectedOutcome>
  </testCases>
</AiEvaluationDefinition>
```

**Package manifest (note v63.0 required):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>LKInsuranceAgentTestSuite</members>
    <name>AiEvaluationDefinition</name>
  </types>
  <version>63.0</version>
</Package>
```

---

## Tooling API Objects

For programmatic inspection of agent configurations (read-only, not for deployment):

```soql
SELECT Id, DeveloperName, Description, FunctionType
FROM GenAiFunctionDefinition
WHERE DeveloperName LIKE 'GetPolicy%'

SELECT Id, DeveloperName, PlannerSpec
FROM GenAiPlannerDefinition
WHERE DeveloperName = 'LKInsurance_Customer_Agent_Planner'
```

---

## YAML Spec Format (Agentforce DX)

### Agent YAML Fields

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `agentType` | String | Yes | — | `External` or `Internal` |
| `companyName` | String | Yes | — | Company name for agent persona |
| `role` | String | Yes | — | Multi-line agent role/persona description |
| `maxNumOfTopics` | Integer | No | 5 | Maximum active subagents |
| `tone` | String | No | `neutral` | `casual`, `formal`, or `neutral` |
| `agentUser` | String | No (but strongly recommended) | System-managed | Username of agent user |
| `enrichLogs` | Boolean | No | false | Enable detailed Einstein Activity Logging |
| `promptTemplateName` | String | No | — | Custom prompt template override |
| `groundingContext` | String | No | — | Static context injected into every prompt |
| `topics` | List | Yes | — | Subagent definitions |

### Topic (Subagent) YAML Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | String | Yes | Developer name |
| `description` | String | Yes | Purpose description |
| `scope` | String | Yes | Types of user requests this subagent handles |
| `instructions` | List<String> | No | Behavioral rules |
| `actions` | List<String> | Yes | Action API names |

### Test YAML Fields (AiEvaluationDefinition)

| Field | Type | Required | Description |
|---|---|---|---|
| `fullName` | String | Yes | Test suite developer name |
| `subjectType` | String | Yes | Always `AGENT` |
| `subjectName` | String | Yes | Agent developer name being tested |
| `testCases` | List | Yes | One or more test cases |
| `testCases.utterance` | String | Yes | Simulated user input |
| `testCases.expectedTopic` | String | No | Expected subagent invoked |
| `testCases.expectedActions` | List<String> | No | Expected action sequence |
| `testCases.expectedOutcome` | String | No | Expected response content (string) |

---

## Agentforce DX CLI Commands

```bash
# List all agents in org
sf agent list --target-org lkinsurance-dev

# Retrieve agent definition
sf agent retrieve --agent-name "LKInsurance Customer Agent" --output-dir ./agents/

# Deploy agent from YAML
sf agent deploy --manifest ./agents/lkinsurance_customer_agent.yaml --target-org lkinsurance-dev

# Validate (check-only deploy)
sf agent deploy --manifest ./agents/lkinsurance_customer_agent.yaml --check-only --target-org lkinsurance-dev

# Activate agent version
sf agent activate --agent-name "LKInsurance Customer Agent" --target-org lkinsurance-dev

# Run agent test suite
sf agent test run --test-suite-name LKInsuranceAgentTestSuite --target-org lkinsurance-dev

# Generate agent YAML from existing org agent
sf agent generate --agent-name "LKInsurance Customer Agent" --target-org lkinsurance-dev
```

---

## Full Package XML Template — Agentforce Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <!-- Agent container -->
  <types>
    <members>LKInsurance_Customer_Agent</members>
    <name>Bot</name>
  </types>
  <!-- Agent version -->
  <types>
    <members>LKInsurance_Customer_Agent.v1</members>
    <name>BotVersion</name>
  </types>
  <!-- Subagents (topics) -->
  <types>
    <members>PolicyInfo</members>
    <members>ClaimIntake</members>
    <members>KnowledgeSearch</members>
    <name>GenAiPlugin</name>
  </types>
  <!-- Actions -->
  <types>
    <members>GetPolicySummaryAction</members>
    <members>CreateClaimAction</members>
    <members>GetClaimStatusAction</members>
    <members>SearchKnowledgeAction</members>
    <name>GenAiFunction</name>
  </types>
  <!-- Planner bundle — ALWAYS use named members, never wildcard -->
  <types>
    <members>LKInsurance_Customer_Agent_Planner</members>
    <name>GenAiPlannerBundle</name>
  </types>
  <!-- Apex action classes -->
  <types>
    <members>GetPolicySummaryAction</members>
    <members>CreateClaimAction</members>
    <members>GetClaimStatusAction</members>
    <members>SearchKnowledgeAction</members>
    <name>ApexClass</name>
  </types>
  <!-- Test suite — requires v63.0 -->
  <types>
    <members>LKInsuranceAgentTestSuite</members>
    <name>AiEvaluationDefinition</name>
  </types>
  <version>63.0</version>
</Package>
```

---

## Deployment Order

Deploy Agentforce metadata in this sequence to avoid dependency errors:

1. **Apex Classes** — action implementations must exist before action definitions reference them
2. **Flows** — if any subagent actions use Flow
3. **GenAiFunction** — action definitions; reference Apex classes
4. **GenAiPlugin** — subagent definitions; reference GenAiFunctions
5. **GenAiPlannerBundle** — references GenAiPlugins and GenAiFunctions
6. **Bot** — agent container
7. **BotVersion** — versioned config; references Bot
8. **AiAuthoringBundle** — full agent export (if using DX YAML approach; replaces steps 6–7)
9. **AiEvaluationDefinition** — test suites; deployed last; requires all subject metadata present

---

## Common Deployment Errors

| Error | Cause | Fix |
|---|---|---|
| `INVALID_TYPE: AiEvaluationDefinition` | Package.xml version < 63.0 | Set `<version>63.0</version>` |
| `GenAiFunction not found` when deploying GenAiPlugin | GenAiFunction not deployed first | Deploy in correct order: functions before plugins |
| `GenAiPlannerBundle timeout` | Used `*` wildcard on GenAiPlannerBundle | Always use named members for GenAiPlannerBundle |
| `Bot activation failed` | BotVersion not deployed or referenced agent user doesn't exist | Deploy BotVersion; create agent user first |
| `Agent user not found` | `agentUser` field references non-existent user | Create the agent user in target org before deploying |
| `Action description too short` | LLM cannot distinguish actions — wrong action invoked at runtime | Write specific, keyword-rich descriptions (see G-4) |
| `Test case UNCERTAIN` result | `expectedOutcome` string is too strict or vague | Revise expectedOutcome to match agent's typical response phrasing |

---

## CI/CD Considerations

- **Never use `GenAiPlannerBundle:*`** in package.xml — always named members (see G-13)
- **AiEvaluationDefinition requires v63.0** — pin this in your CI/CD package.xml
- **Agent user must exist in target org** before any Bot metadata deployment; provision the user via a separate setup step in your pipeline
- **Einstein Requests quota** — running AiEvaluationDefinition test suites in CI consumes quota; plan for this in sandbox quota allocation
- **Test result polling** — CI pipelines running Connect API tests must implement polling with timeout; typical test suite completion is 30–120 seconds depending on test case count
- **Agent activation** — deploying BotVersion does not automatically activate it; add an activation step (`sf agent activate`) to your pipeline post-deploy
