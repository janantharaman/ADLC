# Slack-First Orchestration Patterns

Patterns for building multiplayer workflows where AI agents and humans collaborate via Slack.

**2026-Forward**: This represents the shift to async, collaborative workflows where Slack is the primary interface.

---

## Table of Contents
1. [Multiplayer Workflow Architecture](#multiplayer-workflow-architecture)
2. [Slack Actions + Agentforce](#slack-actions--agentforce)
3. [Human-in-the-Loop Patterns](#human-in-the-loop-patterns)
4. [Async Collaboration](#async-collaboration)
5. [Best Practices](#best-practices)

---

## Multiplayer Workflow Architecture

### What Is Multiplayer?
**Definition**: Workflows where multiple participants (humans + AI agents) collaborate asynchronously to achieve an outcome.

**Traditional Workflow** (Sequential):
```
Request → Agent 1 → Agent 2 → Approval → Complete
```

**Multiplayer Workflow** (Collaborative):
```
Request → Slack Channel
          ↓
    Multiple participants collaborate:
    - AI Agent suggests solutions
    - Human expert provides context
    - Manager approves
    - AI Agent implements
    - QA verifies
          ↓
        Complete
```

### Benefits
1. **Async**: Participants work on their own time
2. **Transparent**: All stakeholders see progress
3. **Collaborative**: Humans + AI work together
4. **Scalable**: Multiple workflows run in parallel
5. **Context-Preserved**: Full conversation history in Slack

### Use Cases
- Discount approval (sales rep + AI + manager)
- Case escalation (support agent + AI + specialist)
- Code review (developer + AI + tech lead)
- Incident response (on-call + AI + team)

---

## Slack Actions + Agentforce

### Pattern 1: AI Recommendation + Human Approval

**Scenario**: Sales rep requests discount, AI analyzes deal, manager approves in Slack.

```apex
public class DiscountApprovalService {
    public static void requestApproval(Opportunity opp) {
        // Step 1: Get AI recommendation
        Agentforce.ReasoningRequest req = new Agentforce.ReasoningRequest();
        req.setGoal('Analyze discount request');
        req.setContext(buildDealContext(opp));
        req.setSteps(new List<String>{
            'Analyze deal size and customer value',
            'Check historical discount patterns',
            'Calculate profit margin',
            'Recommend approval or rejection'
        });

        Agentforce.ReasoningResponse aiResponse = Agentforce.reason(req);

        // Step 2: Send to Slack with AI recommendation
        Slack.Message msg = new Slack.Message()
            .channel('#sales-approvals')
            .text('🔔 Discount Approval Request')
            .addSection('Deal Information', formatDealInfo(opp))
            .addSection('🤖 AI Recommendation', aiResponse.recommendation)
            .addField('Confidence', aiResponse.confidence + '%')
            .addField('Reasoning', aiResponse.reasoning)
            .addDivider()
            .addAction('Approve', 'approve_' + opp.Id, 'primary')
            .addAction('Reject', 'reject_' + opp.Id, 'danger')
            .addAction('Ask AI Questions', 'ask_ai_' + opp.Id, 'default');

        Slack.send(msg);

        // Step 3: Log request
        logApprovalRequest(opp.Id, aiResponse);
    }

    private static String buildDealContext(Opportunity opp) {
        return String.format(
            'Deal: {0}\nAmount: ${1}\nDiscount Requested: {2}%\nCustomer LTV: ${3}\nWin Probability: {4}%',
            new List<String>{
                opp.Name,
                String.valueOf(opp.Amount),
                String.valueOf(opp.Discount_Percent__c),
                String.valueOf(opp.Account.Lifetime_Value__c),
                String.valueOf(opp.Probability)
            }
        );
    }

    private static String formatDealInfo(Opportunity opp) {
        return '• *Deal*: ' + opp.Name + '\n' +
               '• *Amount*: $' + opp.Amount.format() + '\n' +
               '• *Discount*: ' + opp.Discount_Percent__c + '%\n' +
               '• *Customer*: ' + opp.Account.Name + '\n' +
               '• *Stage*: ' + opp.StageName;
    }
}
```

---

### Pattern 2: Interactive AI Q&A in Slack

**Scenario**: Manager can ask AI follow-up questions before approving.

```apex
@RestResource(urlMapping='/slack/interactions/*')
global class SlackInteractionHandler {

    @HttpPost
    global static void handleInteraction() {
        RestRequest req = RestContext.request;
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String actionId = (String) payload.get('action_id');

        if (actionId.startsWith('ask_ai_')) {
            handleAskAI(payload);
        } else if (actionId.startsWith('approve_')) {
            handleApproval(payload, true);
        } else if (actionId.startsWith('reject_')) {
            handleApproval(payload, false);
        }
    }

    private static void handleAskAI(Map<String, Object> payload) {
        String oppId = extractOppId(payload);
        String question = (String) payload.get('text');

        // Get deal context
        Opportunity opp = [SELECT Id, Name, Amount, Discount_Percent__c FROM Opportunity WHERE Id = :oppId];

        // Ask AI
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt(question);
        req.setContext(buildDealContext(opp));

        Agentforce.Response aiResponse = Agentforce.invoke(req);

        // Reply in Slack thread
        Slack.Message reply = new Slack.Message()
            .channel(payload.get('channel'))
            .threadTs(payload.get('message_ts')) // Reply in thread
            .text('🤖 AI Response:\n' + aiResponse.result);

        Slack.send(reply);
    }

    private static void handleApproval(Map<String, Object> payload, Boolean approved) {
        String oppId = extractOppId(payload);
        String userId = (String) payload.get('user_id');

        // Update Opportunity
        Opportunity opp = new Opportunity(Id = oppId);
        opp.Discount_Approved__c = approved;
        opp.Approved_By__c = getUserIdFromSlack(userId);
        opp.Approval_Date__c = System.now();
        update opp;

        // Update Slack message
        Slack.Message update = new Slack.Message()
            .channel(payload.get('channel'))
            .messageTs(payload.get('message_ts'))
            .text(approved ? '✅ *APPROVED* by <@' + userId + '>' : '❌ *REJECTED* by <@' + userId + '>');

        Slack.updateMessage(update);

        // Notify sales rep
        notifySalesRep(opp, approved);
    }
}
```

---

### Pattern 3: Multi-Stage Approval Workflow

**Scenario**: Discount requires multiple approvals based on amount.

```apex
public class MultiStageApprovalService {
    public static void initiateApproval(Opportunity opp) {
        // Determine approval stages based on discount amount
        List<ApprovalStage> stages = determineApprovalStages(opp);

        // Start first stage
        ApprovalStage firstStage = stages[0];

        Slack.Message msg = new Slack.Message()
            .channel(firstStage.channel)
            .text('🔔 Stage ' + firstStage.stageNumber + ' Approval Required')
            .addSection('Deal Information', formatDealInfo(opp))
            .addSection('Approval Stage', firstStage.description)
            .addField('Required By', firstStage.approverRole)
            .addAction('Approve & Continue', 'approve_stage_' + opp.Id + '_' + firstStage.stageNumber)
            .addAction('Reject', 'reject_stage_' + opp.Id);

        Slack.send(msg);

        // Create approval record
        Approval__c approval = new Approval__c(
            Opportunity__c = opp.Id,
            Current_Stage__c = firstStage.stageNumber,
            Total_Stages__c = stages.size(),
            Status__c = 'Pending'
        );
        insert approval;
    }

    private static List<ApprovalStage> determineApprovalStages(Opportunity opp) {
        List<ApprovalStage> stages = new List<ApprovalStage>();

        Decimal discountPercent = opp.Discount_Percent__c;

        // Stage 1: Sales Manager (all discounts)
        stages.add(new ApprovalStage(1, 'Sales Manager Approval', '#sales-approvals', 'Sales Manager'));

        // Stage 2: VP Sales (if discount > 15%)
        if (discountPercent > 15) {
            stages.add(new ApprovalStage(2, 'VP Sales Approval', '#vp-approvals', 'VP Sales'));
        }

        // Stage 3: CFO (if discount > 25%)
        if (discountPercent > 25) {
            stages.add(new ApprovalStage(3, 'CFO Approval', '#executive-approvals', 'CFO'));
        }

        return stages;
    }
}

public class ApprovalStage {
    public Integer stageNumber;
    public String description;
    public String channel;
    public String approverRole;

    public ApprovalStage(Integer stageNumber, String description, String channel, String approverRole) {
        this.stageNumber = stageNumber;
        this.description = description;
        this.channel = channel;
        this.approverRole = approverRole;
    }
}
```

---

## Human-in-the-Loop Patterns

### Pattern 1: AI Suggests, Human Decides

**Use Case**: Case escalation - AI suggests solution, human approves.

```apex
public class CaseEscalationService {
    public static void escalateCase(Case caseRecord) {
        // Step 1: AI analyzes case
        Agentforce.ReasoningRequest req = new Agentforce.ReasoningRequest();
        req.setGoal('Suggest case resolution');
        req.setContext(buildCaseContext(caseRecord));

        Agentforce.ReasoningResponse aiResponse = Agentforce.reason(req);

        // Step 2: Send to Slack for human review
        Slack.Message msg = new Slack.Message()
            .channel('#support-escalations')
            .text('🆘 Case Escalation')
            .addSection('Case Details', formatCaseInfo(caseRecord))
            .addSection('🤖 AI Suggested Resolution', aiResponse.recommendation)
            .addField('Confidence', aiResponse.confidence + '%')
            .addAction('Accept AI Solution', 'accept_ai_' + caseRecord.Id, 'primary')
            .addAction('Provide Custom Solution', 'custom_solution_' + caseRecord.Id, 'default')
            .addAction('Escalate to Specialist', 'escalate_specialist_' + caseRecord.Id, 'danger');

        Slack.send(msg);
    }
}
```

---

### Pattern 2: AI Monitors, Human Intervenes

**Use Case**: AI handles routine tasks, escalates edge cases to humans.

```apex
public class SmartRoutingService {
    public static void routeCase(Case caseRecord) {
        // Step 1: AI analyzes case complexity
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt('Analyze case complexity and suggest routing');
        req.setContext(buildCaseContext(caseRecord));

        Agentforce.Response aiResponse = Agentforce.invoke(req);

        Decimal confidence = aiResponse.confidence;

        if (confidence > 0.9) {
            // High confidence - AI handles automatically
            handleAutomatically(caseRecord, aiResponse);
        } else if (confidence > 0.6) {
            // Medium confidence - AI suggests, human reviews
            requestHumanReview(caseRecord, aiResponse);
        } else {
            // Low confidence - Route to human specialist
            escalateToSpecialist(caseRecord, aiResponse);
        }
    }

    private static void requestHumanReview(Case caseRecord, Agentforce.Response aiResponse) {
        Slack.Message msg = new Slack.Message()
            .channel('#support-triage')
            .text('⚠️ Case Needs Review (Medium Confidence)')
            .addSection('Case', formatCaseInfo(caseRecord))
            .addSection('AI Suggestion', aiResponse.result)
            .addField('Confidence', aiResponse.confidence + '%')
            .addAction('Approve AI Solution', 'approve_ai_' + caseRecord.Id)
            .addAction('Override & Reassign', 'override_' + caseRecord.Id);

        Slack.send(msg);
    }
}
```

---

### Pattern 3: Feedback Loop for Model Improvement

**Use Case**: Collect human feedback to improve AI recommendations.

```apex
public class FeedbackCollectionService {
    public static void collectFeedback(String responseId, Boolean thumbsUp, String comment) {
        // Store feedback
        AI_Feedback__c feedback = new AI_Feedback__c(
            Response_Id__c = responseId,
            Thumbs_Up__c = thumbsUp,
            Comment__c = comment,
            Timestamp__c = System.now()
        );
        insert feedback;

        // If negative feedback, notify data science team
        if (!thumbsUp) {
            Slack.Message msg = new Slack.Message()
                .channel('#ai-model-monitoring')
                .text('👎 Negative AI Feedback Received')
                .addField('Response ID', responseId)
                .addField('Comment', comment)
                .addAction('Review Model', 'review_model_' + responseId);

            Slack.send(msg);
        }

        // Check if retraining threshold met
        checkRetrainingThreshold();
    }
}
```

---

## Async Collaboration

### Pattern 1: Broadcast + Collect Responses

**Use Case**: Get input from multiple team members asynchronously.

```apex
public class TeamCollaborationService {
    public static void broadcastForInput(Id recordId, String question) {
        Slack.Message msg = new Slack.Message()
            .channel('#team-collaboration')
            .text('💬 Team Input Needed')
            .addSection('Question', question)
            .addAction('Provide Input', 'input_' + recordId, 'primary')
            .addAction('Skip', 'skip_' + recordId, 'default');

        Slack.send(msg);

        // Create collaboration record
        Team_Collaboration__c collab = new Team_Collaboration__c(
            Record_Id__c = recordId,
            Question__c = question,
            Status__c = 'Collecting Input',
            Deadline__c = System.now().addHours(24)
        );
        insert collab;
    }

    public static void collectResponse(Id collabId, Id userId, String response) {
        // Store response
        Collaboration_Response__c collabResponse = new Collaboration_Response__c(
            Collaboration__c = collabId,
            User__c = userId,
            Response__c = response,
            Timestamp__c = System.now()
        );
        insert collabResponse;

        // Check if all responses collected
        Team_Collaboration__c collab = [SELECT Id, Required_Responses__c FROM Team_Collaboration__c WHERE Id = :collabId];

        Integer responseCount = [SELECT COUNT() FROM Collaboration_Response__c WHERE Collaboration__c = :collabId];

        if (responseCount >= collab.Required_Responses__c) {
            synthesizeResponses(collabId);
        }
    }

    private static void synthesizeResponses(Id collabId) {
        // Get all responses
        List<Collaboration_Response__c> responses = [
            SELECT Response__c, User__r.Name
            FROM Collaboration_Response__c
            WHERE Collaboration__c = :collabId
        ];

        // Use AI to synthesize
        String context = 'Team responses:\n';
        for (Collaboration_Response__c response : responses) {
            context += '- ' + response.User__r.Name + ': ' + response.Response__c + '\n';
        }

        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt('Synthesize team input into actionable recommendations');
        req.setContext(context);

        Agentforce.Response aiSynthesis = Agentforce.invoke(req);

        // Post synthesis to Slack
        Slack.Message summary = new Slack.Message()
            .channel('#team-collaboration')
            .text('📊 Team Input Summary')
            .addSection('AI Synthesis', aiSynthesis.result)
            .addSection('Individual Responses', formatResponses(responses));

        Slack.send(summary);
    }
}
```

---

### Pattern 2: Threaded Discussions

**Use Case**: Keep related conversations organized in Slack threads.

```apex
public class ThreadedDiscussionService {
    public static String startDiscussion(String topic, String initialMessage) {
        Slack.Message msg = new Slack.Message()
            .channel('#discussions')
            .text('💬 New Discussion: ' + topic)
            .addSection('Topic', topic)
            .addSection('Initial Message', initialMessage);

        Slack.MessageResponse response = Slack.send(msg);

        // Store thread ID for replies
        Discussion__c discussion = new Discussion__c(
            Topic__c = topic,
            Slack_Thread_Ts__c = response.threadTs,
            Status__c = 'Active'
        );
        insert discussion;

        return response.threadTs;
    }

    public static void replyToDiscussion(Id discussionId, String message) {
        Discussion__c discussion = [SELECT Slack_Thread_Ts__c FROM Discussion__c WHERE Id = :discussionId];

        Slack.Message reply = new Slack.Message()
            .channel('#discussions')
            .threadTs(discussion.Slack_Thread_Ts__c) // Reply in thread
            .text(message);

        Slack.send(reply);
    }
}
```

---

## Best Practices

### 1. Message Design
```apex
// ✅ CORRECT: Clear, actionable messages
Slack.Message msg = new Slack.Message()
    .channel('#approvals')
    .text('🔔 Action Required: Discount Approval')
    .addSection('Deal', 'Acme Corp - $100K')
    .addField('Discount', '20%')
    .addField('AI Recommendation', 'Approve (85% confidence)')
    .addDivider()
    .addAction('Approve', 'approve_123', 'primary')
    .addAction('Reject', 'reject_123', 'danger');

// ❌ WRONG: Vague, no context
Slack.Message msg = new Slack.Message()
    .channel('#approvals')
    .text('Click here')
    .addAction('Button', 'action_123');
```

### 2. Timeout Handling
```apex
public class ApprovalTimeoutService {
    // Scheduled job: Check for expired approvals
    public static void checkExpiredApprovals() {
        List<Approval__c> expired = [
            SELECT Id, Opportunity__c
            FROM Approval__c
            WHERE Status__c = 'Pending'
            AND Created_Date < :System.now().addHours(-24)
        ];

        for (Approval__c approval : expired) {
            // Send reminder
            Slack.Message reminder = new Slack.Message()
                .channel('#sales-approvals')
                .text('⏰ Approval Timeout Reminder')
                .addSection('Status', 'This approval has been pending for 24 hours')
                .addAction('Approve Now', 'approve_' + approval.Opportunity__c)
                .addAction('Escalate', 'escalate_' + approval.Opportunity__c);

            Slack.send(reminder);
        }
    }
}
```

### 3. Error Handling
```apex
try {
    Slack.send(msg);
} catch (SlackException e) {
    // Fallback: Send email or create task
    sendEmailFallback(msg);
    logSlackError(e);
}
```

### 4. Testing
```apex
@isTest
private class SlackOrchestrationTest {
    @isTest
    static void testDiscountApproval() {
        // Mock Slack API
        Test.setMock(HttpCalloutMock.class, new SlackHttpMock(200, '{"ok": true}'));

        // Create opportunity
        Opportunity opp = TestDataFactory.createOpportunity();

        // Request approval
        Test.startTest();
        DiscountApprovalService.requestApproval(opp);
        Test.stopTest();

        // Verify Slack message sent (check HTTP callout)
    }
}
```

---

## Summary

**Key Takeaways**:
1. **Multiplayer Workflows**: Humans + AI collaborate asynchronously
2. **Slack as Interface**: Primary collaboration layer
3. **Human-in-the-Loop**: AI suggests, humans decide
4. **Async by Default**: Participants work on their own time
5. **Context-Preserved**: Full conversation history in Slack

**Patterns**:
| Pattern | Use Case | Example |
|---------|----------|---------|
| AI Recommendation + Human Approval | Discount approvals | AI analyzes, manager approves |
| Interactive Q&A | Follow-up questions | Manager asks AI before approving |
| Multi-Stage Approval | Complex workflows | Sales Manager → VP → CFO |
| AI Monitors, Human Intervenes | Smart routing | AI handles routine, escalates edge cases |
| Broadcast + Collect | Team input | Get input from multiple experts |

**Reference Files**:
- Agentforce Integration: `./agentforce-patterns.md`
- Context Engineering: `./context-engineering.md`
- Full-Stack Integration: `./full-stack-integration.md`
