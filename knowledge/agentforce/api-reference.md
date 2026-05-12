---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: api-reference
last-updated: 2026-05-11
---

# Agentforce — API Reference

## Agent API (REST)

The Agent API provides a REST interface for external systems to interact with Agentforce agents. Used for web chat widgets, mobile apps, headless integrations, and platform-to-platform agent calls.

### Session Lifecycle

```
POST /services/data/v66.0/einstein/ai-agent/agents/{agentId}/sessions
  → { sessionId }

POST /services/data/v66.0/einstein/ai-agent/sessions/{sessionId}/messages
  → { message, sessionId, sessionStatus }

DELETE /services/data/v66.0/einstein/ai-agent/sessions/{sessionId}
  → 204 No Content
```

### Start Session

**Endpoint:** `POST /services/data/v{version}/einstein/ai-agent/agents/{agentId}/sessions`

**Request body:**
```json
{
  "externalSessionKey": "unique-session-key-from-your-system",
  "instanceConfig": {
    "endpoint": "https://yourorg.my.salesforce.com"
  },
  "streamingCapabilities": {
    "chunkTypes": ["Text"]
  },
  "bypassUser": false
}
```

**Response:**
```json
{
  "sessionId": "0GxXXXXXXXXXXXX",
  "externalSessionKey": "unique-session-key-from-your-system"
}
```

### Send Message

**Endpoint:** `POST /services/data/v{version}/einstein/ai-agent/sessions/{sessionId}/messages`

**Request body:**
```json
{
  "message": {
    "role": "user",
    "content": [{
      "type": "text",
      "text": "I need to file a claim for my auto policy"
    }]
  },
  "variables": [
    {
      "name": "userId",
      "type": "Text",
      "value": "005XXXXXXXXXXXXXXXXX"
    },
    {
      "name": "accountId",
      "type": "Text",
      "value": "001XXXXXXXXXXXXXXXXX"
    }
  ]
}
```

**Response:**
```json
{
  "sessionId": "0GxXXXXXXXXXXXX",
  "sessionStatus": "ACTIVE",
  "messages": [{
    "role": "assistant",
    "content": [{
      "type": "text",
      "text": "I can help you file a claim. Could you provide your policy number?"
    }]
  }],
  "actionsExecuted": [
    { "actionName": "GetPolicySummaryAction", "status": "SUCCESS" }
  ]
}
```

### End Session

**Endpoint:** `DELETE /services/data/v{version}/einstein/ai-agent/sessions/{sessionId}`

Returns `204 No Content` on success.

### Session Statuses

| Status | Description |
|---|---|
| `ACTIVE` | Session is live and accepting messages |
| `ENDED` | Session was explicitly ended (DELETE called) |
| `EXPIRED` | Session timed out due to inactivity |
| `ERROR` | Session encountered an unrecoverable error |

---

## Models API (Apex — `aiplatform.ModelsAPI`)

### Class Reference

All methods are static. Minimum API version: v59.0.

| Method | Signature | Description |
|---|---|---|
| `createChatGenerations` | `static ModelsAPIResponse createChatGenerations(ModelsAPIRequest req)` | Chat completion (conversational, multi-turn) |
| `createGenerations` | `static ModelsAPIResponse createGenerations(ModelsAPIRequest req)` | Text generation (single-turn, no conversation history) |
| `createEmbeddings` | `static EmbeddingsAPIResponse createEmbeddings(EmbeddingsAPIRequest req)` | Generate embedding vectors from text |
| `submitFeedback` | `static void submitFeedback(FeedbackAPIRequest req)` | Submit thumbs up/down on a generation response |

### ModelsAPIRequest

| Field | Type | Description |
|---|---|---|
| `model` | String | Model identifier (e.g., `sfdc_ai__DefaultGPT4Omni`) |
| `inputs` | List<ModelsAPIBatchInput> | List of message batches (usually 1) |
| `parameters` | Map<String, Object> | Model parameters: `maxTokens`, `temperature`, `topP`, `stopSequences` |

### ModelsAPIBatchInput

| Field | Type | Description |
|---|---|---|
| `messages` | List<ModelsAPIInput> | Conversation messages |

### ModelsAPIInput

| Field | Type | Description |
|---|---|---|
| `role` | String | `"user"`, `"assistant"`, or `"system"` |
| `content` | String | Message text content |

### ModelsAPIResponse

| Field | Type | Description |
|---|---|---|
| `generations` | List<Generation> | One generation per batch input |

### Generation

| Field | Type | Description |
|---|---|---|
| `id` | String | Generation ID (use for feedback submission) |
| `messages` | List<ModelsAPIOutput> | Generated messages |

### ModelsAPIOutput

| Field | Type | Description |
|---|---|---|
| `role` | String | Always `"assistant"` |
| `content` | String | Generated text |
| `finishReason` | String | `"stop"`, `"length"`, `"content_filter"` |

### EmbeddingsAPIRequest

| Field | Type | Description |
|---|---|---|
| `inputs` | List<String> | Texts to embed |
| `model` | String | Embedding model identifier |

### EmbeddingsAPIResponse

| Field | Type | Description |
|---|---|---|
| `embeddings` | List<Embedding> | One per input text |

### Embedding

| Field | Type | Description |
|---|---|---|
| `embedding` | List<Double> | Vector values |
| `index` | Integer | Position in input list |

### FeedbackAPIRequest

| Field | Type | Description |
|---|---|---|
| `generationId` | String | ID from Generation.id |
| `feedback` | String | `"positive"` or `"negative"` |
| `feedbackText` | String | Optional explanation |

### Available Model Identifiers

| Identifier | Provider | Notes |
|---|---|---|
| `sfdc_ai__DefaultGPT4Omni` | OpenAI | GPT-4o |
| `sfdc_ai__DefaultGPT4OmniMini` | OpenAI | GPT-4o-mini |
| `sfdc_ai__DefaultClaude3Opus` | Anthropic | Claude 3 Opus |
| `sfdc_ai__DefaultClaude3Sonnet` | Anthropic | Claude 3 Sonnet |
| `sfdc_ai__DefaultGeminiPro` | Google | Gemini Pro |
| `sfdc_ai__DefaultTextEmbedding` | Salesforce | Default embeddings |
| Custom BYOLLM | Your endpoint | Configured via LLM Open Connector; any string |

---

## Testing Connect API

Automated agent test execution is orchestrated via Connect API. `AiEvaluationDefinition` is the metadata; Connect API is the runtime.

### Start Test Run

**Endpoint:** `POST /services/data/v{version}/connect/ai-evaluations`

**Request body:**
```json
{
  "subjectName": "LKInsurance_Customer_Agent",
  "subjectType": "AGENT",
  "evaluationDefinitionName": "InsuranceAgentTestSuite"
}
```

**Response:**
```json
{
  "runId": "0ZgXXXXXXXXXXXX",
  "status": "NEW"
}
```

### Get Run Status

**Endpoint:** `GET /services/data/v{version}/connect/ai-evaluations/{runId}`

**Response:**
```json
{
  "runId": "0ZgXXXXXXXXXXXX",
  "status": "IN_PROGRESS",
  "testCasesTotal": 10,
  "testCasesCompleted": 4,
  "testCasesFailed": 1
}
```

**Status values:** `NEW` → `IN_PROGRESS` → `COMPLETED` | `ERROR`

### Get Detailed Report

**Endpoint:** `GET /services/data/v{version}/connect/ai-evaluations/{runId}/details`

**Response structure:**
```json
{
  "runId": "0ZgXXXXXXXXXXXX",
  "status": "COMPLETED",
  "testResults": [
    {
      "utterance": "I need to file a claim",
      "expectedTopic": "ClaimIntakeSubagent",
      "actualTopic": "ClaimIntakeSubagent",
      "expectedActions": ["GetPolicySummaryAction", "CreateClaimAction"],
      "actionsSequence": ["GetPolicySummaryAction", "CreateClaimAction"],
      "outcome": "Claim reference number provided to user",
      "metrics": [
        { "name": "topicMatch", "metricScore": "PASS" },
        { "name": "actionMatch", "metricScore": "PASS" },
        { "name": "outcomeMatch", "metricScore": "HIGH" }
      ]
    }
  ]
}
```

### metricScore Values

| Score | Metric Type | Description |
|---|---|---|
| `PASS` | Boolean (topic match, action match) | Expected value matched actual |
| `FAILED` | Boolean | Expected value did not match actual |
| `HIGH` | Quality (outcome match) | Strong match between expected and actual outcome |
| `LOW` | Quality | Weak match |
| `UNCERTAIN` | Quality | Could not determine match |

---

## Citations Apex Classes

Full class reference for building actions that return grounded, cited responses.

### GenAiActionOutput

| Field | Type | Description |
|---|---|---|
| `inputText` | String | The user's query or input (echoed for context) |
| `sources` | List<GenAiSourceReference> | Source references that ground the response |

### GenAiSourceReference

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique ID for this reference (typically record Id) |
| `contents` | List<GenAiSourceContentInfo> | Content from one or more fields |
| `metadata` | GenAiSourceReferenceInfo | Metadata about the source record |

### GenAiSourceContentInfo

| Field | Type | Description |
|---|---|---|
| `fieldName` | String | API name of the field containing content |
| `objectName` | String | API name of the object |
| `content` | String | Actual text content from the field |

### GenAiSourceReferenceInfo

| Field | Type | Description |
|---|---|---|
| `link` | String | URL to the source (optional) |
| `source_object_record_id` | String | Salesforce record Id |
| `source_object_api_name` | String | Object API name |
| `label` | String | Human-readable title for the citation |

### GenAiCitations

| Field | Type | Description |
|---|---|---|
| `references` | List<GenAiCitedReference> | All cited references in the response |

### GenAiCitedReference / GenAiCitedReferenceInfo

Used to link a citation back to the specific text that was cited in the response:

| Field | Type | Description |
|---|---|---|
| `citedText` | String | The exact text excerpt that was cited |
| `citedFieldName` | String | Field the cited text came from |
| `citedObjectName` | String | Object the cited text came from |
| `sourceReferenceId` | String | Links back to `GenAiSourceReference.id` |

---

## Python SDK Class Reference

Install: `pip install agentforce-sdk`

### Agentforce (Client)

```python
from agentforce import Agentforce

# Username/password auth
client = Agentforce(username='user@org.com', password='pass+token', instance_url='https://org.my.salesforce.com')

# Session-based auth
client = Agentforce(session_id='00DXXXXXXX!...', instance_url='https://org.my.salesforce.com')
```

### Agent

```python
from agentforce import Agent

agent = Agent(
    name='LKInsurance Customer Agent',
    description='Handles insurance policy inquiries and claim intake for LKInsurance customers',
    agent_type='External',   # 'External' or 'Internal'
    company_name='LKInsurance',
    topics=[topic1, topic2],
    variables=[var1, var2],
    system_messages=['Always respond in the customer\'s preferred language.']
)
```

### Topic (Subagent)

```python
from agentforce import Topic

topic = Topic(
    name='ClaimIntake',
    description='Handles insurance claim intake and filing',
    scope='Claim filing, claim status, claim documents',
    instructions=[
        'Always verify policy number before accepting claim details.',
        'If policy not found, offer to look up by name and date of birth.',
        'Provide a claim reference number at the end of every successful intake.'
    ],
    actions=[action1, action2]
)
```

### Action

```python
from agentforce import Action, AttributeMapping

action = Action(name='GetPolicySummaryAction')
action.add_input('policyId')
action.map_input(AttributeMapping(
    action_parameter='policyId',
    variable='currentPolicyId',
    direction='input'
))
action.map_output(AttributeMapping(
    action_parameter='summary',
    variable='policySummary',
    direction='output'
))
```

### Variable

```python
from agentforce import Variable

# Text variable (conversation-scoped)
var = Variable(
    name='currentPolicyId',
    data_type='Text',          # 'Text' or 'Boolean' ONLY in Python SDK
    var_type='conversation'    # 'conversation' or 'context'
)
```

### AgentUtils

```python
from agentforce import AgentUtils

# Create agent from YAML file
agent = AgentUtils.create_agent_from_file('agent_config.yaml')

# Create from dict
agent = AgentUtils.create_agent_from_dict(config_dict)

# Create from directory structure (topics as subdirectories)
agent = AgentUtils.create_agent_from_directory_structure('./agent_dir/')

# Create from modular files (topics, actions in separate files)
agent = AgentUtils.create_agent_from_modular_files(
    agent_file='agent.yaml',
    topics_dir='./topics/',
    actions_dir='./actions/'
)

# Generate agent info summary
info = AgentUtils.generate_agent_info(agent)
```

### PromptTemplateUtils

```python
from agentforce import PromptTemplateUtils

template = PromptTemplateUtils.generate_prompt_template(
    template_name='PolicySummaryTemplate',
    description='Generates a customer-friendly policy summary',
    content='You are an insurance assistant. Summarize this policy: {!policy_data}'
)
```
