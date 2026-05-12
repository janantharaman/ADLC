---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: data-model
last-updated: 2026-05-11
---

# Agentforce — Data Model

## Metadata Type Hierarchy

```
Bot (agent container)
└── BotVersion (versioned configuration)
    ├── ConversationVariable (typed session variables)
    └── BotSubDialog (conversation flow nodes)

GenAiPlannerBundle (agent planning config)
├── GenAiPlugin (subagent — formerly topic)
│   └── GenAiPluginInstructionDef (instruction)
└── GenAiFunction (action definition)
    └── schema.json (Lightning Types I/O schema)

AiAuthoringBundle (full agent YAML export)
└── targets Bot.BotVersion format
```

---

## Metadata Types

### Bot

Container object for an Agentforce agent. Introduced at v47.0 (predates Agentforce; originally for Einstein Bots).

| Field | Type | Description |
|---|---|---|
| `fullName` | String | Developer API name of the bot |
| `botUser` | String | Username of the agent user (optional; defaults if not set) |
| `contextVariables` | List | Context variables accessible across sessions |
| `description` | String | Agent description |
| `label` | String | Display name |
| `botVersions` | List<BotVersion> | One or more versioned configurations |

**Directory:** `bots/`
**File suffix:** `.bot`

---

### BotVersion

A versioned configuration of an agent. Each bot has one or more versions; one version is "active."

| Field | Type | Description |
|---|---|---|
| `fullName` | String | `BotName.versionLabel` format |
| `conversationVariables` | List<ConversationVariable> | Variables scoped to a conversation session |
| `nlpProviders` | List | NLP provider configuration |
| `entryDialog` | String | Entry dialog/subagent name |
| `mainMenuDialog` | String | Main menu dialog name |

**ConversationVariable fields:**

| Field | Type | Description |
|---|---|---|
| `developerName` | String | API name for the variable |
| `label` | String | Display name |
| `dataType` | Enum | `Text`, `Boolean`, `Number`, `Currency`, `Date`, `DateTime`, `Id`, `SObject` |
| `varType` | Enum | `Conversation` (persists for session) or `Context` (read-only external input) |

**Note:** Python SDK Variable class only supports `Text` and `Boolean` data types. Full metadata supports all 8 types above.

---

### GenAiFunction (Action Definition)

Represents a single callable action available to an agent.

| Field | Type | Description |
|---|---|---|
| `fullName` | String | API name of the action |
| `description` | String | Natural language description (used by LLM for action selection) |
| `functionType` | Enum | `SfdcFlow`, `SfdcApexMethod`, `SfdcSoqlQuery`, `SfdcLightningType`, `SfdcAuraEnabled` |
| `parameters` | List | Input parameters for the action |
| `outputParameters` | List | Output parameters returned by the action |

For Lightning Types actions, I/O is defined in a companion `schema.json` file.

**Directory:** `genAiFunctions/`
**File suffix:** `.genAiFunction`

---

### GenAiPlugin (Subagent / Topic)

Represents a subagent (formerly called a topic). Each plugin scopes a domain and lists its available actions.

| Field | Type | Description |
|---|---|---|
| `fullName` | String | API name of the subagent |
| `description` | String | Natural language description |
| `instructions` | List<String> | Ordered list of behavioral instructions |
| `scope` | String | Natural language scope — used by planner to route user requests |
| `genAiFunctions` | List | Actions available to this subagent |
| `pluginInstructions` | List<GenAiPluginInstructionDef> | Structured instruction objects (alternative to list) |

**Directory:** `genAiPlugins/`
**File suffix:** `.genAiPlugin`

---

### GenAiPlannerBundle

The planning bundle that groups subagents and actions for an agent version.

| Field | Type | Description |
|---|---|---|
| `fullName` | String | API name |
| `description` | String | Bundle description |
| `agentType` | Enum | `CopilotAgent`, `EinsteinGPTAgent` |
| `genAiPlugins` | List | Subagents included in this bundle |
| `genAiFunctions` | List | Global actions (available to all subagents) |
| `plannerSpec` | String | YAML spec (used by Agentforce DX) |

**Directory:** `genAiPlannerBundles/`
**File suffix:** `.genAiPlannerBundle`

---

### AiAuthoringBundle

Full agent export format used by Agentforce DX. Targets `Bot.BotVersion` format. Contains the complete agent YAML including subagents, actions, and variables.

**File suffix:** `.aiAuthoringBundle`
**Primary use:** VS Code / CLI-based authoring and version control

---

### AiEvaluationDefinition (Testing)

Metadata type for automated agent test suites. Minimum API version v63.0.

| Field | Type | Description |
|---|---|---|
| `fullName` | String | API name of the test suite |
| `subjectType` | String | Always `"AGENT"` for agent tests |
| `subjectName` | String | API name of the agent being tested |
| `testCases` | List | One or more test case definitions |

**TestCase fields:**

| Field | Type | Description |
|---|---|---|
| `utterance` | String | The simulated user input |
| `expectedTopic` | String | Expected subagent to be invoked |
| `expectedActions` | List<String> | Expected action sequence |
| `expectedOutcome` | String | Expected response content (string match) |

**Directory:** `aiEvaluationDefinitions/`
**File suffix:** `.aiEvaluationDefinition`

---

## Tooling API Objects

### GenAiFunctionDefinition

Tooling API representation of an action definition. Used for programmatic creation/inspection.

```soql
SELECT Id, DeveloperName, Description, FunctionType
FROM GenAiFunctionDefinition
WHERE DeveloperName LIKE 'My%'
```

### GenAiPlannerDefinition

Tooling API representation of the planner bundle.

```soql
SELECT Id, DeveloperName, PlannerSpec
FROM GenAiPlannerDefinition
WHERE DeveloperName = 'My_Agent_Planner'
```

---

## Agent Variable Data Model

Variables are typed values that carry state within an agent session. Two scopes:

| Scope | Direction | Description |
|---|---|---|
| `Conversation` | Read/Write | Agent can read and write; persists for the session duration |
| `Context` | Read-only | Injected at session start (e.g., userId, accountId from calling system); agent reads but cannot overwrite |

Variable types (full metadata — `BotVersion.ConversationVariable`):
- `Text` — string
- `Boolean` — true/false
- `Number` — numeric
- `Currency` — decimal with currency symbol
- `Date` — date without time
- `DateTime` — date + time
- `Id` — Salesforce record Id
- `SObject` — full sObject record reference

**Python SDK restriction:** Only `Text` and `Boolean` are supported in the `agentforce-sdk`.

---

## Action I/O Schema (Lightning Types)

For Lightning Types actions, the input/output contract is defined in a `schema.json` file alongside the `.genAiFunction` metadata file.

12 supported Lightning Types:

| Type | JSON Key | Required Properties | Optional Properties |
|---|---|---|---|
| Boolean | `lightning__booleanType` | `title` | — |
| Date | `lightning__dateType` | `title` | — |
| DateTime | `lightning__dateTimeType` | `title` | — |
| DateTime (string) | `lightning__dateTimeStringType` | `title` | — |
| Integer | `lightning__integerType` | `title` | `minimum`, `maximum`, `multipleOf` |
| Number | `lightning__numberType` | `title` | `minimum`, `maximum`, `multipleOf` |
| Text | `lightning__textType` | `title` | `maxLength` |
| Multiline Text | `lightning__multilineTextType` | `title` | `maxLength` |
| Rich Text | `lightning__richTextType` | `title` | `maxLength` |
| Object | `lightning__objectType` | `title` | nested properties |
| Time | `lightning__timeType` | `title` | — |
| URL | `lightning__urlType` | `title` | `lightning:allowedUrlSchemes` |

---

## Citations Data Model

When an action invocation returns citations, the following Apex types carry the citation data:

| Class | Description |
|---|---|
| `GenAiActionOutput` | Wraps action output; has `inputText` (String) and `sources` (List<GenAiSourceReference>) |
| `GenAiSourceReference` | One source reference; has `id`, `contents` (List<GenAiSourceContentInfo>), `metadata` (GenAiSourceReferenceInfo) |
| `GenAiSourceContentInfo` | Content from one field; has `fieldName`, `objectName`, `content` (String) |
| `GenAiSourceReferenceInfo` | Metadata about the source; has `link`, `source_object_record_id`, `source_object_api_name`, `label` |
| `GenAiCitations` | Collection of cited references; has `references` (List<GenAiCitedReference>) |
| `GenAiCitedReference` | One cited reference; links `GenAiSourceReference` → `GenAiCitedReferenceInfo` |
| `GenAiCitedReferenceInfo` | Citation metadata: `citedText`, `citedFieldName`, `citedObjectName`, `sourceReferenceId` |

---

## SOQL Reference

```soql
-- List all agents (Bot metadata)
SELECT Id, DeveloperName, Description
FROM BotDefinition
ORDER BY DeveloperName ASC

-- List all subagents / topics (GenAiPlugin)
SELECT Id, DeveloperName, Description
FROM GenAiPluginDefinition
ORDER BY DeveloperName ASC

-- List all registered actions (GenAiFunction)
SELECT Id, DeveloperName, Description, FunctionType
FROM GenAiFunctionDefinition
ORDER BY DeveloperName ASC

-- List active agent test suites
SELECT Id, DeveloperName, SubjectType, SubjectName
FROM AiEvaluationDefinition
WHERE SubjectType = 'AGENT'

-- Check Einstein Requests consumption (if available)
SELECT Id, EventDate, Count
FROM EinsteinRequestEventLog
ORDER BY EventDate DESC
LIMIT 100
```
