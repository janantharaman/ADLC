---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: automation-patterns
last-updated: 2026-05-11
---

# Agentforce — Automation Patterns

## Action Types — When to Use Each

| Type | When to Use | Notes |
|---|---|---|
| Invocable Method (`@InvocableMethod`) | Business logic that already exists in Flow-compatible Apex; most common for new custom actions | Declarative-first; usable in both Flow and Agentforce |
| AuraEnabled Apex | Existing AuraEnabled methods you want to expose as actions without rewriting | Avoid for new builds; Invocable preferred |
| Named Query | Simple SOQL lookups with no business logic (find a record, get a list) | No Apex required; defined in Setup |
| Lightning Types | Structured form-fill-style actions with schema-validated I/O; ideal for data capture | Requires schema.json; 12 type primitives |
| Apex REST (`@RestResource`) | Agent needs to call an existing REST endpoint | Least preferred; use Invocable instead for new builds |

---

## Pattern 1 — Invocable Action

The standard pattern for custom agent actions.

```apex
public class GetPolicySummaryAction {

    public class Request {
        @InvocableVariable(required=true label='Policy ID')
        public Id policyId;
    }

    public class Response {
        @InvocableVariable(label='Policy Summary')
        public String summary;

        @InvocableVariable(label='Policy Status')
        public String status;
    }

    @InvocableMethod(
        label='Get Policy Summary'
        description='Returns a plain-language summary and status of an insurance policy. Use when the user asks about a specific policy.'
        category='Insurance'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Policy__c pol = [
                SELECT Id, Name, Status__c, Premium__c, Coverage_Type__c
                FROM Policy__c
                WHERE Id = :req.policyId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            Response res = new Response();
            res.status = pol.Status__c;
            res.summary = pol.Coverage_Type__c + ' policy, premium ' + pol.Premium__c + ', status ' + pol.Status__c;
            responses.add(res);
        }
        return responses;
    }
}
```

**Key rules for `@InvocableMethod` description:** This description is the primary signal Agentforce uses to select this action. Write it as a complete sentence describing what the action does AND when to invoke it. Vague descriptions cause misrouting.

---

## Pattern 2 — Models API (Apex)

Use `aiplatform.ModelsAPI` for LLM calls within your own Apex logic — not agent actions. Typical uses: pre-processing data for an action, summarizing records, embedding search.

```apex
// Text generation (chat completion)
aiplatform.ModelsAPIRequest req = new aiplatform.ModelsAPIRequest();
req.model = 'sfdc_ai__DefaultGPT4Omni';  // or 'sfdc_ai__DefaultClaude3Opus', etc.
aiplatform.ModelsAPIBatchInput batchInput = new aiplatform.ModelsAPIBatchInput();
aiplatform.ModelsAPIInput input = new aiplatform.ModelsAPIInput();
input.role = 'user';
input.content = 'Summarize this claim in two sentences: ' + claimDescription;
batchInput.messages = new List<aiplatform.ModelsAPIInput>{ input };
req.inputs = new List<aiplatform.ModelsAPIBatchInput>{ batchInput };
req.parameters = new Map<String, Object>{ 'maxTokens' => 200, 'temperature' => 0.3 };

aiplatform.ModelsAPIResponse resp = aiplatform.ModelsAPI.createChatGenerations(req);
String summary = resp.generations[0].messages[0].content;
```

```apex
// Embeddings
aiplatform.EmbeddingsAPIRequest embReq = new aiplatform.EmbeddingsAPIRequest();
embReq.inputs = new List<String>{ 'text to embed' };
embReq.model = 'sfdc_ai__DefaultTextEmbedding';
aiplatform.EmbeddingsAPIResponse embResp = aiplatform.ModelsAPI.createEmbeddings(embReq);
List<Double> vector = embResp.embeddings[0].embedding;
```

**Available model identifiers (Spring '26):**
- `sfdc_ai__DefaultGPT4Omni` — OpenAI GPT-4o
- `sfdc_ai__DefaultGPT4OmniMini` — OpenAI GPT-4o-mini
- `sfdc_ai__DefaultClaude3Opus` — Anthropic Claude 3 Opus
- `sfdc_ai__DefaultClaude3Sonnet` — Anthropic Claude 3 Sonnet
- `sfdc_ai__DefaultGeminiPro` — Google Gemini Pro
- `sfdc_ai__DefaultTextEmbedding` — default embeddings model
- Custom BYOLLM identifier — configured via LLM Open Connector

**`submitFeedback` — rating LLM responses:**
```apex
aiplatform.FeedbackAPIRequest fbReq = new aiplatform.FeedbackAPIRequest();
fbReq.generationId = resp.generations[0].id;
fbReq.feedback = 'positive'; // or 'negative'
fbReq.feedbackText = 'Accurate summary';
aiplatform.ModelsAPI.submitFeedback(fbReq);
```

---

## Pattern 3 — Agent Script (Deterministic Authoring)

Agent Script is a hybrid authoring mode: deterministic script blocks with LLM reasoning at decision points. Use when the conversation flow must follow a defined sequence (intake forms, approval workflows, compliance scripts).

### Three Authoring Modes

| Mode | Description | When to Use |
|---|---|---|
| LLM-only | Agent reasons freely within subagent instructions | Open-ended Q&A, research, summarization |
| Script-only | Fully deterministic; every response is scripted | Compliance scripts, legal disclosures, intake forms |
| Hybrid | Deterministic blocks + LLM reasoning at defined handoff points | Most structured workflows |

### Agent Script Syntax — Core Symbols

| Symbol | Meaning |
|---|---|
| `#` | Block identifier (step label) |
| `->` | Transition (go to next block) |
| `\|` | Conditional branch operator |
| `{!expression}` | Merge field — injects variable value |
| `@subagent.name` | Invoke a subagent |
| `@utils.escalate` | Escalate to human agent |
| `@utils.end` | End conversation |
| `@utils.repeat` | Repeat current block |

### Minimal Script Example (Claim Intake)

```
# greeting
Agent: Hello! I can help you file a claim. What is your policy number?
-> collect_policy_number

# collect_policy_number
Agent: Please provide your 10-digit policy number.
| Policy number provided -> verify_policy
| Customer says they don't have it -> no_policy_number

# no_policy_number
Agent: No problem. Please provide your full name and date of birth and I'll look it up.
-> lookup_by_name

# verify_policy
@action: GetPolicySummaryAction(policyId={!input.policyId})
| Policy found -> confirm_policy
| Policy not found -> policy_not_found

# confirm_policy
Agent: I found your policy: {!PolicySummary.coverage_type} effective {!PolicySummary.effective_date}. Is this correct?
| Yes -> collect_claim_details
| No -> retry_policy_lookup

# collect_claim_details
Agent: Please describe what happened.
-> submit_claim

# submit_claim
@action: CreateClaimAction(policyId={!input.policyId}, description={!input.description})
Agent: Your claim has been filed. Reference number: {!ClaimResult.caseNumber}
@utils.end
```

---

## Pattern 4 — Lightning Types Action

For structured data capture with schema validation. Define `schema.json` alongside the action metadata.

```json
{
  "title": "Create Insurance Claim",
  "description": "Captures structured claim intake data with type validation",
  "type": "object",
  "properties": {
    "policyId": {
      "title": "Policy ID",
      "lightning__textType": {
        "title": "Policy ID",
        "maxLength": 18
      }
    },
    "incidentDate": {
      "title": "Incident Date",
      "lightning__dateType": {
        "title": "Date of Incident"
      }
    },
    "claimAmount": {
      "title": "Claim Amount",
      "lightning__numberType": {
        "title": "Estimated Claim Amount",
        "minimum": 0
      }
    },
    "isEmergency": {
      "title": "Emergency Claim",
      "lightning__booleanType": {
        "title": "Is this an emergency claim?"
      }
    }
  },
  "required": ["policyId", "incidentDate"]
}
```

---

## Pattern 5 — Multi-Agent Orchestration

Agents can invoke other agents as subagents using `@subagent.name` syntax in Agent Script or by wiring GenAiPlugin references in the planner bundle.

```
# escalate_to_specialist
Agent: I'm connecting you with our claims specialist agent.
@subagent.ClaimsSpecialistAgent
-> wait_for_specialist_response

# wait_for_specialist_response
| Specialist resolved -> closing
| Specialist escalated -> human_handoff
```

For programmatic multi-agent coordination, the calling agent passes context variables to the called agent at invocation time. Context variables are read-only in the receiving agent — they cannot be modified.

---

## Pattern 6 — Testing Automation

Use `AiEvaluationDefinition` metadata to define test suites that run against an agent.

```yaml
# test_suite.aiEvaluationDefinition
fullName: InsuranceAgentTestSuite
subjectType: AGENT
subjectName: LKInsurance_Customer_Agent
testCases:
  - utterance: "I need to file a claim for my auto policy"
    expectedTopic: ClaimIntakeSubagent
    expectedActions:
      - GetPolicySummaryAction
      - CreateClaimAction
    expectedOutcome: "Claim reference number provided"
  - utterance: "What is my policy premium?"
    expectedTopic: PolicyInfoSubagent
    expectedActions:
      - GetPolicySummaryAction
    expectedOutcome: "Premium amount stated"
```

Run tests via Connect API (see api-reference.md). `metricScore` values:
- `PASS` / `FAILED` — for Boolean metrics (action invoked or not)
- `HIGH` / `LOW` / `UNCERTAIN` — for quality metrics (outcome match)

---

## Pattern 7 — Citations in Actions

When an action returns content that should be cited (grounding the agent response in specific records), use the Citations Apex pattern:

```apex
@InvocableMethod(
    label='Search Knowledge Articles'
    description='Searches knowledge base for articles relevant to the user question. Returns cited sources.'
)
public static List<GenAiActionOutput> searchKnowledge(List<Request> requests) {
    List<GenAiActionOutput> results = new List<GenAiActionOutput>();
    for (Request req : requests) {
        List<Knowledge__kav> articles = [
            SELECT Id, Title, Summary, ArticleBody__c, UrlName
            FROM Knowledge__kav
            WHERE PublishStatus = 'Online'
            AND Language = 'en_US'
            AND (Title LIKE :('%' + req.query + '%') OR Summary LIKE :('%' + req.query + '%'))
            WITH SECURITY_ENFORCED
            LIMIT 5
        ];

        GenAiActionOutput output = new GenAiActionOutput();
        output.inputText = req.query;
        output.sources = new List<GenAiSourceReference>();

        for (Knowledge__kav article : articles) {
            GenAiSourceReference ref = new GenAiSourceReference();
            ref.id = article.Id;

            GenAiSourceContentInfo content = new GenAiSourceContentInfo();
            content.fieldName = 'ArticleBody__c';
            content.objectName = 'Knowledge__kav';
            content.content = article.ArticleBody__c;
            ref.contents = new List<GenAiSourceContentInfo>{ content };

            GenAiSourceReferenceInfo meta = new GenAiSourceReferenceInfo();
            meta.label = article.Title;
            meta.source_object_record_id = article.Id;
            meta.source_object_api_name = 'Knowledge__kav';
            ref.metadata = meta;

            output.sources.add(ref);
        }
        results.add(output);
    }
    return results;
}
```

The agent will include citation links in its response to the user, pointing back to the knowledge articles that grounded the answer.
