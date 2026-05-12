# Context Engineering for AI

The art of designing business context for AI models to maximize accuracy and ROI.

**2026-Forward**: Context engineering is a critical skill for developers working with Agentforce and AI-powered features.

---

## Table of Contents
1. [What Is Context Engineering?](#what-is-context-engineering)
2. [Principles of Effective Context](#principles-of-effective-context)
3. [Prompt Engineering Techniques](#prompt-engineering-techniques)
4. [Model Evaluation Framework](#model-evaluation-framework)
5. [ROI Measurement](#roi-measurement)

---

## What Is Context Engineering?

### Definition
**Context Engineering**: The process of designing and structuring business context (data, rules, examples) that is fed to AI models to produce high-quality, business-relevant outputs.

### Why It Matters
- **Accuracy**: Better context = more accurate predictions
- **Relevance**: Ensures AI understands business domain
- **Consistency**: Repeatable, predictable results
- **ROI**: Higher quality outputs = better business outcomes

### Context vs Prompt
| Component | Purpose | Example |
|-----------|---------|---------|
| **Prompt** | What you want AI to do | "Generate discount approval recommendation" |
| **Context** | Business information AI needs | Customer LTV, deal size, historical discounts, profit margin |

**Both are critical**: Prompt tells AI what to do, context tells AI how to do it correctly.

---

## Principles of Effective Context

### Principle 1: Relevance (Only Include What Matters)

```apex
// ❌ WRONG: Context dump (too much irrelevant data)
String context = JSON.serialize(caseRecord); // All 50+ fields

Agentforce.Request req = new Agentforce.Request();
req.setPrompt('Suggest case resolution');
req.setContext(context);

// ✅ CORRECT: Relevant context only
String context = String.format(
    'Customer: {0} (Satisfaction: {1}/5, Lifetime Value: ${2})\n' +
    'Issue: {3}\n' +
    'Priority: {4}\n' +
    'Previous Similar Cases: {5}',
    new List<String>{
        caseRecord.Contact.Name,
        String.valueOf(caseRecord.Contact.CSAT_Score__c),
        String.valueOf(caseRecord.Account.Lifetime_Value__c),
        caseRecord.Description,
        caseRecord.Priority,
        String.valueOf(similarCasesCount)
    }
);

Agentforce.Request req = new Agentforce.Request();
req.setPrompt('Suggest case resolution');
req.setContext(context);
```

**Why**: Irrelevant data confuses AI, increases cost (more tokens), reduces accuracy.

---

### Principle 2: Clarity (Use Semantic Names)

```apex
// ❌ WRONG: Cryptic abbreviations
String context = 'Cust: ACME, ACV: 100K, LTV: 500K, CSat: 4.5, NPS: 8';

// ✅ CORRECT: Clear semantic names
String context = 'Customer Name: ACME Corp\n' +
                 'Annual Contract Value: $100,000\n' +
                 'Customer Lifetime Value: $500,000\n' +
                 'Customer Satisfaction Score: 4.5/5\n' +
                 'Net Promoter Score: 8/10';
```

**Why**: AI models trained on natural language understand semantic names better.

---

### Principle 3: Constraints (Include Business Rules)

```apex
// ❌ WRONG: Data only, no rules
String context = 'Deal Amount: $50,000\nDiscount Requested: 25%';

// ✅ CORRECT: Data + business rules
String context = 'Deal Amount: $50,000\n' +
                 'Discount Requested: 25%\n' +
                 'Customer Lifetime Value: $200,000\n' +
                 '\n' +
                 'Business Rules:\n' +
                 '- Discounts up to 10% require Sales Manager approval\n' +
                 '- Discounts 10-25% require VP Sales approval\n' +
                 '- Discounts >25% require CFO approval\n' +
                 '- High-value customers (LTV >$100K) get +5% discount flexibility\n' +
                 '- Profit margin must remain above 15%';
```

**Why**: AI needs to understand constraints to make valid recommendations.

---

### Principle 4: Examples (Few-Shot Learning)

```apex
// ❌ WRONG: No examples
String context = 'Customer: ACME, Deal: $50K, Discount: 20%';

// ✅ CORRECT: Include examples of good outcomes
String context = 'Customer: ACME Corp\n' +
                 'Deal Amount: $50,000\n' +
                 'Discount Requested: 20%\n' +
                 'Customer LTV: $200,000\n' +
                 '\n' +
                 'Examples of Successful Approvals:\n' +
                 '1. ABC Corp - $60K deal, 18% discount, LTV $150K → APPROVED (high LTV justified discount)\n' +
                 '2. XYZ Inc - $40K deal, 15% discount, LTV $80K → APPROVED (standard discount tier)\n' +
                 '3. DEF LLC - $30K deal, 25% discount, LTV $50K → REJECTED (discount too high for LTV)\n' +
                 '\n' +
                 'Based on these patterns, provide recommendation for current deal.';
```

**Why**: Examples teach AI what "good" looks like, improving accuracy.

---

## Prompt Engineering Techniques

### Technique 1: Instruction Clarity

```apex
// ❌ WRONG: Vague instruction
String prompt = 'Help with this case';

// ✅ CORRECT: Clear, specific instruction
String prompt = 'Analyze this customer support case and provide:\n' +
                '1. Root cause of the issue\n' +
                '2. Recommended resolution steps\n' +
                '3. Estimated resolution time\n' +
                '4. Confidence level (0-100%)';
```

---

### Technique 2: Output Format Specification

```apex
// ❌ WRONG: No format specified
String prompt = 'Suggest products for this customer';

// ✅ CORRECT: Specify output format
String prompt = 'Suggest products for this customer. Respond in JSON format:\n' +
                '{\n' +
                '  "recommendations": [\n' +
                '    {"product_id": "123", "name": "Product A", "reason": "..."},\n' +
                '    {"product_id": "456", "name": "Product B", "reason": "..."}\n' +
                '  ],\n' +
                '  "confidence": 0.85\n' +
                '}';
```

---

### Technique 3: Temperature Control

```apex
// For factual, deterministic responses (low temperature)
Agentforce.Request req = new Agentforce.Request();
req.setPrompt('What is the refund policy for this customer?');
req.setTemperature(0.0); // Deterministic, factual

// For creative, varied responses (high temperature)
Agentforce.Request req = new Agentforce.Request();
req.setPrompt('Generate a personalized email to this customer');
req.setTemperature(0.7); // Creative, varied
```

**Temperature Scale**:
- **0.0**: Deterministic (always same output)
- **0.3**: Mostly factual (slight variation)
- **0.7**: Balanced (creative but grounded)
- **1.0**: Highly creative (unpredictable)

---

### Technique 4: Chain-of-Thought Prompting

```apex
// ❌ WRONG: Direct question
String prompt = 'Should we approve this discount?';

// ✅ CORRECT: Chain-of-thought (step-by-step reasoning)
String prompt = 'Analyze this discount request step-by-step:\n' +
                'Step 1: Evaluate customer value (LTV, satisfaction)\n' +
                'Step 2: Analyze deal profitability (margin after discount)\n' +
                'Step 3: Compare to historical discount patterns\n' +
                'Step 4: Consider competitive landscape\n' +
                'Step 5: Provide recommendation (Approve/Reject) with justification';
```

**Why**: Explicit reasoning steps improve accuracy, especially for complex decisions.

---

### Technique 5: Role Specification

```apex
// ❌ WRONG: No role
String prompt = 'Analyze this deal';

// ✅ CORRECT: Specify AI role
String prompt = 'You are an experienced Sales Operations Manager with 15 years of experience.\n' +
                'Analyze this discount request and provide your expert recommendation.\n' +
                'Consider business profitability, customer value, and strategic importance.';
```

**Why**: Role context helps AI adopt appropriate persona and expertise level.

---

## Model Evaluation Framework

### Metric 1: Accuracy

**Definition**: % of AI predictions that match ground truth.

```apex
public class ModelAccuracyService {
    public static Decimal calculateAccuracy(List<Prediction> predictions) {
        Integer correct = 0;
        Integer total = predictions.size();

        for (Prediction p : predictions) {
            if (p.predicted.equals(p.actual)) {
                correct++;
            }
        }

        return total > 0 ? (Decimal)correct / total * 100 : 0;
    }
}

public class Prediction {
    public String predicted; // AI prediction
    public String actual;    // Ground truth
}
```

**Evaluation**:
```apex
// Example: Discount approval accuracy
List<Prediction> testCases = new List<Prediction>{
    new Prediction('Approve', 'Approve'),  // Correct
    new Prediction('Approve', 'Reject'),   // Wrong
    new Prediction('Reject', 'Reject'),    // Correct
    new Prediction('Approve', 'Approve')   // Correct
};

Decimal accuracy = ModelAccuracyService.calculateAccuracy(testCases);
// Result: 75% accuracy (3/4 correct)
```

---

### Metric 2: Latency

**Definition**: Time from request to response (milliseconds).

```apex
public class ModelLatencyService {
    public static Long measureLatency(Agentforce.Request req) {
        Long startTime = System.currentTimeMillis();

        Agentforce.Response response = Agentforce.invoke(req);

        Long endTime = System.currentTimeMillis();

        return endTime - startTime;
    }

    public static Decimal calculateAverageLatency(List<Long> latencies) {
        Long total = 0;
        for (Long latency : latencies) {
            total += latency;
        }
        return latencies.size() > 0 ? (Decimal)total / latencies.size() : 0;
    }
}
```

**Target Latencies**:
- **Real-time UI**: < 1 second
- **Background processing**: < 5 seconds
- **Batch analysis**: < 60 seconds

---

### Metric 3: Token Usage (Cost)

**Definition**: Number of tokens consumed (input + output).

```apex
public class ModelCostService {
    private static final Decimal COST_PER_1K_TOKENS = 0.01; // Example pricing

    public static Decimal calculateCost(Integer tokensUsed) {
        return (tokensUsed / 1000.0) * COST_PER_1K_TOKENS;
    }

    public static Decimal calculateROI(Decimal cost, Decimal businessValue) {
        return businessValue > 0 ? ((businessValue - cost) / cost) * 100 : 0;
    }
}

// Example: Discount approval AI
Integer tokensUsed = 500; // Prompt + context + response
Decimal cost = ModelCostService.calculateCost(tokensUsed); // $0.005

Decimal businessValue = 1000; // Saved $1000 in discounts (prevented bad approvals)
Decimal roi = ModelCostService.calculateROI(cost, businessValue); // 19,900% ROI
```

---

### Metric 4: Confidence Score

**Definition**: AI's confidence in its prediction (0-1).

```apex
public class ConfidenceAnalysisService {
    public static Map<String, Integer> analyzeConfidenceDistribution(List<Agentforce.Response> responses) {
        Map<String, Integer> distribution = new Map<String, Integer>{
            'high' => 0,    // >0.8
            'medium' => 0,  // 0.5-0.8
            'low' => 0      // <0.5
        };

        for (Agentforce.Response response : responses) {
            if (response.confidence > 0.8) {
                distribution.put('high', distribution.get('high') + 1);
            } else if (response.confidence > 0.5) {
                distribution.put('medium', distribution.get('medium') + 1);
            } else {
                distribution.put('low', distribution.get('low') + 1);
            }
        }

        return distribution;
    }
}
```

**Action Thresholds**:
- **High (>0.8)**: Auto-execute
- **Medium (0.5-0.8)**: Human review
- **Low (<0.5)**: Escalate to specialist

---

## ROI Measurement

### Formula
```
ROI = (Business Value - AI Cost) / AI Cost × 100%
```

### Example 1: Case Deflection

```apex
public class CaseDeflectionROI {
    public static Decimal calculateROI() {
        // Costs
        Decimal aiCostPerCase = 0.02;           // $0.02 per case analyzed
        Integer casesAnalyzed = 1000;
        Decimal totalAICost = aiCostPerCase * casesAnalyzed; // $20

        // Benefits
        Decimal avgAgentCostPerCase = 10.00;    // $10 agent cost per case
        Integer casesDeflected = 300;            // 30% deflection rate
        Decimal costSavings = avgAgentCostPerCase * casesDeflected; // $3,000

        // ROI
        Decimal roi = ((costSavings - totalAICost) / totalAICost) * 100;
        // Result: 14,900% ROI

        return roi;
    }
}
```

### Example 2: Discount Approval

```apex
public class DiscountApprovalROI {
    public static Decimal calculateROI() {
        // Costs
        Decimal aiCostPerAnalysis = 0.05;       // $0.05 per deal analyzed
        Integer dealsAnalyzed = 100;
        Decimal totalAICost = aiCostPerAnalysis * dealsAnalyzed; // $5

        // Benefits (prevented bad discounts)
        Decimal avgDealSize = 50000;
        Decimal avgBadDiscountPercent = 5;      // 5% excess discount
        Integer badDiscountsPrevented = 10;     // AI prevented 10 bad approvals
        Decimal costSavings = avgDealSize * (avgBadDiscountPercent / 100) * badDiscountsPrevented;
        // Result: $25,000 in prevented excessive discounts

        // ROI
        Decimal roi = ((costSavings - totalAICost) / totalAICost) * 100;
        // Result: 499,900% ROI

        return roi;
    }
}
```

### Example 3: Product Recommendations

```apex
public class ProductRecommendationROI {
    public static Decimal calculateROI() {
        // Costs
        Decimal aiCostPerRecommendation = 0.01; // $0.01 per recommendation
        Integer recommendationsGenerated = 10000;
        Decimal totalAICost = aiCostPerRecommendation * recommendationsGenerated; // $100

        // Benefits (increased conversions)
        Decimal conversionRateIncrease = 2;     // 2% increase in conversion
        Integer totalVisitors = 10000;
        Decimal avgOrderValue = 100;
        Decimal additionalRevenue = totalVisitors * (conversionRateIncrease / 100) * avgOrderValue;
        // Result: $20,000 in additional revenue

        // ROI
        Decimal roi = ((additionalRevenue - totalAICost) / totalAICost) * 100;
        // Result: 19,900% ROI

        return roi;
    }
}
```

---

## Best Practices

### 1. Iterative Improvement

```apex
// Version 1: Basic context
String contextV1 = 'Customer: ' + customer.Name + '\nIssue: ' + caseRecord.Description;
Decimal accuracyV1 = 65%; // Baseline

// Version 2: Add customer value
String contextV2 = contextV1 + '\nLifetime Value: $' + customer.Lifetime_Value__c;
Decimal accuracyV2 = 72%; // +7% improvement

// Version 3: Add business rules
String contextV3 = contextV2 + '\nBusiness Rule: High-value customers (>$100K) get priority resolution';
Decimal accuracyV3 = 80%; // +8% improvement

// Version 4: Add examples
String contextV4 = contextV3 + '\nExample: Similar case resolved by [solution]';
Decimal accuracyV4 = 88%; // +8% improvement
```

**Process**: Test → Measure → Improve → Repeat

---

### 2. A/B Testing

```apex
public class ContextABTestService {
    public static void runABTest(Case caseRecord) {
        // Randomly assign variant
        String variant = Math.random() < 0.5 ? 'A' : 'B';

        String context;
        if (variant == 'A') {
            context = buildContextA(caseRecord); // Current version
        } else {
            context = buildContextB(caseRecord); // New version
        }

        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt('Suggest case resolution');
        req.setContext(context);

        Agentforce.Response response = Agentforce.invoke(req);

        // Log for analysis
        AB_Test_Result__c result = new AB_Test_Result__c(
            Variant__c = variant,
            Case__c = caseRecord.Id,
            Confidence__c = response.confidence,
            Latency_Ms__c = response.latencyMs
        );
        insert result;
    }
}
```

**Analysis**: Compare accuracy, latency, cost between variants.

---

### 3. Monitoring & Alerting

```apex
public class ModelMonitoringService {
    public static void checkModelHealth() {
        // Query recent predictions
        List<AI_Prediction__c> predictions = [
            SELECT Confidence__c, Latency_Ms__c, Success__c
            FROM AI_Prediction__c
            WHERE CreatedDate = LAST_N_DAYS:1
        ];

        // Calculate metrics
        Decimal avgConfidence = 0;
        Decimal avgLatency = 0;
        Integer successCount = 0;

        for (AI_Prediction__c prediction : predictions) {
            avgConfidence += prediction.Confidence__c;
            avgLatency += prediction.Latency_Ms__c;
            if (prediction.Success__c) {
                successCount++;
            }
        }

        avgConfidence /= predictions.size();
        avgLatency /= predictions.size();
        Decimal successRate = (Decimal)successCount / predictions.size() * 100;

        // Alert if thresholds breached
        if (avgConfidence < 0.7) {
            sendAlert('Low confidence detected: ' + avgConfidence);
        }
        if (avgLatency > 2000) {
            sendAlert('High latency detected: ' + avgLatency + 'ms');
        }
        if (successRate < 80) {
            sendAlert('Low success rate: ' + successRate + '%');
        }
    }
}
```

---

## Summary

**Key Takeaways**:
1. **Context Engineering**: Designing business context for AI accuracy
2. **Principles**: Relevance, Clarity, Constraints, Examples
3. **Prompt Engineering**: Clear instructions, output format, temperature, chain-of-thought, role specification
4. **Evaluation**: Accuracy, latency, token usage, confidence
5. **ROI**: Measure business value vs AI cost

**Context Quality Checklist**:
- [ ] Includes only relevant data (not everything)
- [ ] Uses semantic names (not abbreviations)
- [ ] Specifies business rules and constraints
- [ ] Provides examples of good outcomes (few-shot learning)
- [ ] Clear prompt with expected output format
- [ ] Appropriate temperature for task (0.0 for factual, 0.7 for creative)

**Evaluation Checklist**:
- [ ] Accuracy measured against ground truth
- [ ] Latency monitored (< 1s for real-time)
- [ ] Token usage tracked (cost per request)
- [ ] Confidence thresholds defined (auto-execute vs human review)
- [ ] ROI calculated (business value vs AI cost)
- [ ] A/B testing for context improvements
- [ ] Monitoring & alerting for model health

**Reference Files**:
- Agentforce Patterns: `./agentforce-patterns.md`
- Data Cloud RAG: `./data-cloud-zero-copy.md`
- Full-Stack Integration: `./full-stack-integration.md`
- Slack Orchestration: `./slack-orchestration.md`
