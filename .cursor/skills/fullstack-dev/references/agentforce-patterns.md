# Agentforce Integration Patterns

Patterns for integrating Salesforce Agentforce (AI agents) with Atlas Reasoning Engine, RAG, prompt governance, and Einstein Trust Layer.

**2026-Forward**: These patterns represent the latest Agentforce capabilities for agentic workflows and predictive AI.

---

## Table of Contents
1. [Atlas Reasoning Engine](#atlas-reasoning-engine)
2. [Retrieval-Augmented Generation (RAG)](#retrieval-augmented-generation-rag)
3. [Prompt Governance](#prompt-governance)
4. [Einstein Trust Layer](#einstein-trust-layer)
5. [Agentforce 360 Observability](#agentforce-360-observability)
6. [Model Evaluation](#model-evaluation)

---

## Atlas Reasoning Engine

**What It Is**: Agentforce's multi-step reasoning engine that performs chain-of-thought processing for complex business logic.

**Use Cases**:
- Case deflection with reasoning steps
- Product recommendations based on purchase history
- Discount approval analysis
- Complex eligibility determination

### Basic Pattern

```apex
public class CaseDeflectionService {
    public static AgentforceResponse deflectCase(Case caseRecord) {
        // Build reasoning request
        Agentforce.ReasoningRequest req = new Agentforce.ReasoningRequest();
        req.setGoal('Resolve customer issue without human agent');
        req.setContext(buildCaseContext(caseRecord));
        req.setSteps(new List<String>{
            'Understand the issue',
            'Search knowledge base for similar issues',
            'Evaluate top 3 solutions',
            'Recommend best solution',
            'Generate customer response'
        });

        // Invoke Atlas Reasoning Engine
        Agentforce.ReasoningResponse response = Agentforce.reason(req);

        // Log reasoning trace
        logReasoningTrace(caseRecord.Id, response);

        return new AgentforceResponse(response);
    }

    private static String buildCaseContext(Case caseRecord) {
        return String.format(
            'Customer: {0} (Lifetime Value: ${1}, CSAT: {2}/5)\n' +
            'Issue: {3}\n' +
            'Priority: {4}\n' +
            'Category: {5}\n' +
            'Previous Cases: {6}',
            new List<String>{
                caseRecord.Contact.Name,
                String.valueOf(caseRecord.Account.Lifetime_Value__c),
                String.valueOf(caseRecord.Contact.CSAT_Score__c),
                caseRecord.Description,
                caseRecord.Priority,
                caseRecord.Type,
                String.valueOf(caseRecord.Contact.Total_Cases__c)
            }
        );
    }
}
```

### Chain-of-Thought Prompting

**Principle**: Break complex tasks into explicit reasoning steps.

```apex
Agentforce.ReasoningRequest req = new Agentforce.ReasoningRequest();
req.setGoal('Approve discount request');
req.setSteps(new List<String>{
    'Step 1: Analyze deal size and customer value',
    'Step 2: Check historical discount patterns for similar deals',
    'Step 3: Calculate profit margin at requested discount',
    'Step 4: Evaluate competitive landscape',
    'Step 5: Recommend approval/rejection with justification'
});
```

**Why**: Explicit steps improve accuracy and provide transparency.

### Agent-to-Agent Collaboration

**Pattern**: Multiple agents collaborate on a task.

```apex
public class DealAnalysisOrchestrator {
    public static DealRecommendation analyzeDeal(Opportunity opp) {
        // Agent 1: Financial Analysis
        Agentforce.Response financialAnalysis = FinancialAgent.analyze(opp);

        // Agent 2: Competitive Analysis
        Agentforce.Response competitiveAnalysis = CompetitiveAgent.analyze(opp);

        // Agent 3: Synthesize recommendations
        Agentforce.ReasoningRequest req = new Agentforce.ReasoningRequest();
        req.setGoal('Recommend discount approval');
        req.setContext('Financial Analysis: ' + financialAnalysis.result + '\n' +
                       'Competitive Analysis: ' + competitiveAnalysis.result);
        req.setSteps(new List<String>{
            'Weigh financial vs competitive factors',
            'Determine optimal discount percentage',
            'Provide approval recommendation'
        });

        Agentforce.ReasoningResponse synthesis = Agentforce.reason(req);

        return new DealRecommendation(synthesis);
    }
}
```

---

## Retrieval-Augmented Generation (RAG)

**What It Is**: Enriching AI prompts with relevant data retrieved from Data Cloud or Salesforce objects.

**Use Cases**:
- Customer support with knowledge base grounding
- Product recommendations based on purchase history
- Personalized marketing content
- Context-aware chatbots

### Basic RAG Pattern

```apex
public class KnowledgeRAGService {
    public static AgentforceResponse answerQuestion(String question, Id customerId) {
        // Step 1: Retrieve relevant context from Data Cloud
        List<UnifiedProfile> profiles = DataCloudService.getCustomerContext(customerId);

        // Step 2: Retrieve relevant knowledge articles
        List<Knowledge__kav> articles = [
            SELECT Title, Summary, Body
            FROM Knowledge__kav
            WHERE PublishStatus = 'Online'
            AND Title LIKE :('%' + extractKeywords(question) + '%')
            LIMIT 5
        ];

        // Step 3: Build grounded prompt
        String groundedContext = buildGroundedContext(profiles, articles);

        // Step 4: Invoke Agentforce with RAG
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt(question);
        req.setContext(groundedContext);
        req.setTemperature(0.3); // Lower for factual responses

        Agentforce.Response response = Agentforce.invoke(req);

        return new AgentforceResponse(response);
    }

    private static String buildGroundedContext(List<UnifiedProfile> profiles, List<Knowledge__kav> articles) {
        String context = 'Customer Profile:\n';
        for (UnifiedProfile profile : profiles) {
            context += '- Purchase History: ' + profile.purchaseHistory + '\n';
            context += '- Engagement Score: ' + profile.engagementScore + '\n';
        }

        context += '\nRelevant Knowledge Articles:\n';
        for (Knowledge__kav article : articles) {
            context += '- ' + article.Title + ': ' + article.Summary + '\n';
        }

        return context;
    }

    private static String extractKeywords(String question) {
        // Simple keyword extraction (in production, use NLP)
        return question.replaceAll('[^a-zA-Z0-9\\s]', '').toLowerCase();
    }
}
```

### Data Cloud Zero-Copy RAG

**Pattern**: Query Data Cloud directly for unified customer profiles.

```apex
public class DataCloudRAGService {
    public static AgentforceResponse generatePersonalizedEmail(Id customerId) {
        // Zero-copy query to Data Cloud
        DataCloudQuery query = new DataCloudQuery()
            .from('Unified_Individual')
            .where('sfdc_account_id', customerId)
            .select('purchase_history', 'engagement_score', 'sentiment', 'preferences');

        List<UnifiedProfile> profiles = DataCloud.execute(query);

        // Build context for AI
        String context = buildPersonalizationContext(profiles[0]);

        // Generate email with Agentforce
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt('Generate personalized promotional email');
        req.setContext(context);
        req.setTemplate('promotional_email');

        Agentforce.Response response = Agentforce.invoke(req);

        return new AgentforceResponse(response);
    }
}
```

**Reference**: See `./data-cloud-zero-copy.md` for Data Cloud patterns.

---

## Prompt Governance

**What It Is**: Version control, testing, and optimization of AI prompts.

### Prompt Template Pattern

```apex
public class PromptTemplateService {
    private static Map<String, String> PROMPT_TEMPLATES = new Map<String, String>{
        'case_deflection_v1' => 'You are a helpful customer service agent. Resolve this issue: {issue}',
        'case_deflection_v2' => 'You are a helpful customer service agent. Customer: {customer_name} (CSAT: {csat}). Issue: {issue}. Provide a solution that maintains high satisfaction.',
        'discount_approval_v1' => 'Analyze this discount request: {discount_percent}% on {deal_size}. Recommend approval or rejection.',
        'discount_approval_v2' => 'Analyze this discount request:\nDeal Size: ${deal_size}\nDiscount: {discount_percent}%\nCustomer LTV: ${customer_ltv}\nProfit Margin: {profit_margin}%\n\nRecommend: Approve or Reject with justification.'
    };

    public static String getPrompt(String templateKey, Map<String, String> variables) {
        String template = PROMPT_TEMPLATES.get(templateKey);
        if (template == null) {
            throw new PromptNotFoundException('Template not found: ' + templateKey);
        }

        // Substitute variables
        for (String key : variables.keySet()) {
            template = template.replace('{' + key + '}', variables.get(key));
        }

        return template;
    }

    public static void logPromptUsage(String templateKey, String prompt, Agentforce.Response response) {
        Prompt_Usage__c usage = new Prompt_Usage__c(
            Template_Key__c = templateKey,
            Prompt__c = prompt,
            Response__c = response.result,
            Tokens_Used__c = response.tokensUsed,
            Latency_Ms__c = response.latencyMs,
            Success__c = response.success
        );
        insert usage;
    }
}
```

### A/B Testing Prompts

```apex
public class PromptABTestService {
    public static AgentforceResponse testPromptVariants(Case caseRecord) {
        // Randomly assign variant
        String variant = Math.random() < 0.5 ? 'case_deflection_v1' : 'case_deflection_v2';

        // Get prompt from template
        String prompt = PromptTemplateService.getPrompt(variant, new Map<String, String>{
            'customer_name' => caseRecord.Contact.Name,
            'csat' => String.valueOf(caseRecord.Contact.CSAT_Score__c),
            'issue' => caseRecord.Description
        });

        // Invoke Agentforce
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt(prompt);
        Agentforce.Response response = Agentforce.invoke(req);

        // Log for analysis
        PromptTemplateService.logPromptUsage(variant, prompt, response);

        // Log A/B test result
        AB_Test_Result__c abTest = new AB_Test__c(
            Variant__c = variant,
            Case__c = caseRecord.Id,
            Success__c = response.success,
            User_Satisfaction__c = null // To be updated later
        );
        insert abTest;

        return new AgentforceResponse(response);
    }
}
```

**Analysis**: Query `Prompt_Usage__c` to compare token usage, latency, and success rates across variants.

---

## Einstein Trust Layer

**What It Is**: AI guardrails for data privacy, toxicity filtering, and hallucination detection.

### Trust Layer Configuration

```apex
public class TrustLayerService {
    public static Agentforce.Response invokeSafely(String prompt, String context) {
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt(prompt);
        req.setContext(context);

        // Configure Trust Layer
        TrustLayer trustLayer = new TrustLayer()
            .maskPII(true)              // Mask SSN, credit cards, emails
            .filterToxic(true)          // Block offensive content
            .detectHallucination(true)  // Validate against ground truth
            .auditLog(true)             // Log all AI decisions
            .dataResidency('US');       // Comply with data residency laws

        req.setGuardrails(trustLayer);

        Agentforce.Response response = Agentforce.invoke(req);

        // Check if guardrails were triggered
        if (response.guardrailsTriggered) {
            logGuardrailViolation(req, response);
        }

        return response;
    }

    private static void logGuardrailViolation(Agentforce.Request req, Agentforce.Response response) {
        Guardrail_Violation__c violation = new Guardrail_Violation__c(
            Prompt__c = req.prompt,
            Violation_Type__c = response.violationType, // 'PII', 'TOXIC', 'HALLUCINATION'
            Details__c = response.violationDetails
        );
        insert violation;
    }
}
```

### PII Masking Example

```apex
// Input prompt with PII
String prompt = 'Process refund for John Doe, SSN 123-45-6789, credit card 4111111111111111';

// Trust Layer masks PII
TrustLayer.maskPII(prompt);
// Output: 'Process refund for [NAME], SSN [SSN], credit card [CREDIT_CARD]'
```

### Hallucination Detection

**Pattern**: Validate AI output against ground truth (Data Cloud, Salesforce objects).

```apex
public class HallucinationDetector {
    public static Boolean detectHallucination(Agentforce.Response response, String groundTruth) {
        // Extract facts from response
        List<String> responseFacts = extractFacts(response.result);

        // Extract facts from ground truth
        List<String> groundTruthFacts = extractFacts(groundTruth);

        // Check for contradictions
        for (String responseFact : responseFacts) {
            if (!isConsistent(responseFact, groundTruthFacts)) {
                return true; // Hallucination detected
            }
        }

        return false;
    }

    private static List<String> extractFacts(String text) {
        // Simple fact extraction (in production, use NLP)
        return text.split('\\.');
    }

    private static Boolean isConsistent(String fact, List<String> groundTruthFacts) {
        for (String truthFact : groundTruthFacts) {
            if (fact.containsIgnoreCase(truthFact)) {
                return true;
            }
        }
        return false;
    }
}
```

---

## Agentforce 360 Observability

**What It Is**: Monitoring AI reasoning loops, identifying failure points, and optimizing performance.

### Reasoning Trace Logging

```apex
public class AgentforceObservability {
    public static void logReasoningTrace(Id recordId, Agentforce.ReasoningResponse response) {
        // Log overall reasoning
        Reasoning_Trace__c trace = new Reasoning_Trace__c(
            Record_Id__c = recordId,
            Goal__c = response.goal,
            Total_Steps__c = response.steps.size(),
            Success__c = response.success,
            Latency_Ms__c = response.latencyMs,
            Tokens_Used__c = response.tokensUsed,
            Cost__c = calculateCost(response.tokensUsed)
        );
        insert trace;

        // Log individual reasoning steps
        List<Reasoning_Step__c> steps = new List<Reasoning_Step__c>();
        for (Integer i = 0; i < response.steps.size(); i++) {
            Agentforce.ReasoningStep step = response.steps[i];
            steps.add(new Reasoning_Step__c(
                Reasoning_Trace__c = trace.Id,
                Step_Number__c = i + 1,
                Step_Description__c = step.description,
                Input__c = step.input,
                Output__c = step.output,
                Confidence__c = step.confidence,
                Duration_Ms__c = step.durationMs
            ));
        }
        insert steps;
    }

    private static Decimal calculateCost(Integer tokensUsed) {
        // Example: $0.01 per 1000 tokens
        return (tokensUsed / 1000.0) * 0.01;
    }

    public static List<ReasoningAnalytics> analyzeReasoningPerformance() {
        // Query reasoning traces
        List<Reasoning_Trace__c> traces = [
            SELECT Id, Goal__c, Success__c, Latency_Ms__c, Tokens_Used__c, Cost__c
            FROM Reasoning_Trace__c
            WHERE CreatedDate = LAST_N_DAYS:7
        ];

        // Aggregate metrics
        Map<String, ReasoningAnalytics> analyticsMap = new Map<String, ReasoningAnalytics>();
        for (Reasoning_Trace__c trace : traces) {
            if (!analyticsMap.containsKey(trace.Goal__c)) {
                analyticsMap.put(trace.Goal__c, new ReasoningAnalytics(trace.Goal__c));
            }
            analyticsMap.get(trace.Goal__c).addTrace(trace);
        }

        return analyticsMap.values();
    }
}

public class ReasoningAnalytics {
    public String goal;
    public Integer totalTraces = 0;
    public Integer successfulTraces = 0;
    public Decimal avgLatency = 0;
    public Decimal avgTokens = 0;
    public Decimal totalCost = 0;

    public ReasoningAnalytics(String goal) {
        this.goal = goal;
    }

    public void addTrace(Reasoning_Trace__c trace) {
        totalTraces++;
        if (trace.Success__c) {
            successfulTraces++;
        }
        avgLatency += trace.Latency_Ms__c;
        avgTokens += trace.Tokens_Used__c;
        totalCost += trace.Cost__c;
    }

    public Decimal getSuccessRate() {
        return totalTraces > 0 ? (successfulTraces / totalTraces) * 100 : 0;
    }

    public void finalize() {
        if (totalTraces > 0) {
            avgLatency /= totalTraces;
            avgTokens /= totalTraces;
        }
    }
}
```

### Performance Monitoring Dashboard

**Custom Object Schema**:
- `Reasoning_Trace__c`: Record reasoning executions
  - Fields: `Goal__c`, `Success__c`, `Latency_Ms__c`, `Tokens_Used__c`, `Cost__c`
- `Reasoning_Step__c`: Record individual reasoning steps
  - Fields: `Step_Number__c`, `Input__c`, `Output__c`, `Confidence__c`, `Duration_Ms__c`

**Dashboards**: Build Salesforce reports/dashboards to visualize:
- Success rate by goal
- Average latency by goal
- Token usage trends
- Cost analysis

---

## Model Evaluation

**What It Is**: Measuring AI model accuracy, latency, and cost.

### Evaluation Framework

```apex
public class ModelEvaluationService {
    public static ModelMetrics evaluateModel(String modelId, List<EvaluationCase> testCases) {
        ModelMetrics metrics = new ModelMetrics(modelId);

        for (EvaluationCase testCase : testCases) {
            // Invoke model
            Long startTime = System.currentTimeMillis();
            Agentforce.Response response = Agentforce.invoke(testCase.prompt);
            Long endTime = System.currentTimeMillis();

            // Evaluate accuracy
            Boolean isCorrect = testCase.expectedOutput.equals(response.result);
            metrics.addResult(isCorrect, endTime - startTime, response.tokensUsed);

            // Log evaluation
            Model_Evaluation__c eval = new Model_Evaluation__c(
                Model_Id__c = modelId,
                Test_Case__c = testCase.name,
                Prompt__c = testCase.prompt,
                Expected_Output__c = testCase.expectedOutput,
                Actual_Output__c = response.result,
                Is_Correct__c = isCorrect,
                Latency_Ms__c = endTime - startTime,
                Tokens_Used__c = response.tokensUsed
            );
            insert eval;
        }

        metrics.finalize();
        return metrics;
    }
}

public class ModelMetrics {
    public String modelId;
    public Integer totalCases = 0;
    public Integer correctPredictions = 0;
    public Decimal avgLatency = 0;
    public Decimal avgTokens = 0;

    public ModelMetrics(String modelId) {
        this.modelId = modelId;
    }

    public void addResult(Boolean isCorrect, Long latency, Integer tokens) {
        totalCases++;
        if (isCorrect) {
            correctPredictions++;
        }
        avgLatency += latency;
        avgTokens += tokens;
    }

    public Decimal getAccuracy() {
        return totalCases > 0 ? (correctPredictions / totalCases) * 100 : 0;
    }

    public void finalize() {
        if (totalCases > 0) {
            avgLatency /= totalCases;
            avgTokens /= totalCases;
        }
    }
}
```

### User Feedback Collection

```apex
public class UserFeedbackService {
    public static void collectFeedback(Id responseId, Boolean thumbsUp, String comment) {
        AI_Feedback__c feedback = new AI_Feedback__c(
            Response_Id__c = responseId,
            Thumbs_Up__c = thumbsUp,
            Comment__c = comment
        );
        insert feedback;

        // Trigger model retraining if feedback threshold met
        checkRetrainingThreshold();
    }

    private static void checkRetrainingThreshold() {
        // Query recent feedback
        List<AI_Feedback__c> recentFeedback = [
            SELECT Thumbs_Up__c
            FROM AI_Feedback__c
            WHERE CreatedDate = LAST_N_DAYS:7
        ];

        Integer thumbsDown = 0;
        for (AI_Feedback__c feedback : recentFeedback) {
            if (!feedback.Thumbs_Up__c) {
                thumbsDown++;
            }
        }

        // If >20% thumbs down, flag for review
        Decimal thumbsDownPercent = (thumbsDown / recentFeedback.size()) * 100;
        if (thumbsDownPercent > 20) {
            // Create task for data scientist
            Task reviewTask = new Task(
                Subject = 'Review AI Model Performance',
                Description = 'Model has ' + thumbsDownPercent + '% negative feedback'
            );
            insert reviewTask;
        }
    }
}
```

---

## Summary

**Key Patterns**:
1. **Atlas Reasoning**: Chain-of-thought prompting for complex business logic
2. **RAG**: Enrich prompts with Data Cloud or Salesforce data
3. **Prompt Governance**: Version control, A/B testing, template management
4. **Trust Layer**: PII masking, toxicity filtering, hallucination detection
5. **Observability**: Log reasoning traces, monitor performance
6. **Model Evaluation**: Measure accuracy, latency, cost

**Best Practices**:
- Always use Trust Layer for production AI features
- Log reasoning traces for debugging and optimization
- A/B test prompt variants to improve accuracy
- Collect user feedback for model retraining
- Monitor token usage and costs
- Validate AI output against ground truth (hallucination detection)

**Reference Files**:
- Context Engineering: `./context-engineering.md`
- Data Cloud RAG: `./data-cloud-zero-copy.md`
- Full-Stack Integration: `./full-stack-integration.md`
