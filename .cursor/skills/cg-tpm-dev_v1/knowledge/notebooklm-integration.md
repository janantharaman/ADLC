# NotebookLM Knowledge Integration for CG TPM

> **Pattern**: Two-tier knowledge strategy (Try → Fallback → Always Provide)

## Configuration

**Notebook ID**: `9ca50af3-1937-43a6-87c4-3d8629a1ccbd`
**Notebook Title**: Industry Knowledge Base: CG TPM
**Source Count**: 41 sources
**Last Updated**: 2026-03-06

## Two-Tier Knowledge Strategy

This skill uses a dynamic knowledge integration pattern similar to the Salesforce MCP integration:

### Tier 1: NotebookLM (Live Knowledge)
- Queries CG TPM NotebookLM in real-time
- Always-current information
- Used for: implementation planning, latest patterns, validation

### Tier 2: Pre-Trained (Baseline Knowledge)
- Generated from NotebookLM snapshot (2026-03-06)
- Offline-capable
- Used for: quick reference, fallback when NotebookLM unavailable

## Query Strategy

When a developer uses `/cg-tpm-dev` for implementation:

### Step 1: Analyze Request
Determine what knowledge is needed:
- Data model inquiry? → Query for object structure
- Implementation pattern? → Query for use cases and technical patterns
- KPI question? → Query for calculation formulas
- Integration? → Query for external system patterns

### Step 2: Try NotebookLM First
```
TRY:
  Query NotebookLM with context-specific question
  Extract relevant information
  Use in response: "✓ From NotebookLM (latest)"
CATCH NotebookLMUnavailable:
  Fall back to Tier 2 (pre-trained materials)
  Warn user: "⚠️ Using pre-trained knowledge. NotebookLM unavailable."
```

### Step 3: Combine with Pre-Trained Knowledge
Even when NotebookLM works:
- Use NotebookLM for latest information
- Supplement with pre-trained patterns for implementation details
- Validate consistency between sources

## Query Templates

### For Data Models
**Query**: "What is the data model for [object name] in CG Cloud TPM? Include fields, relationships, and purpose."

**Example**:
```
Query: "What is the data model for Account Product List in CG Cloud TPM? Include fields, relationships, and purpose."
```

### For Business Processes
**Query**: "Explain the [process name] workflow in CG Cloud TPM, including steps, data involved, and best practices."

**Example**:
```
Query: "Explain the promotion management workflow in CG Cloud TPM, including steps, data involved, and best practices."
```

### For KPI Configuration
**Query**: "How do I configure [KPI name] in CG Cloud TPM? Include calculation formula and data sources."

**Example**:
```
Query: "How do I configure ROI KPI in CG Cloud TPM? Include calculation formula and data sources."
```

### For Technical Patterns
**Query**: "What are the implementation patterns for [feature] in CG Cloud TPM? Include code examples if available."

**Example**:
```
Query: "What are the implementation patterns for Processing Engine Data in CG Cloud TPM? Include code examples if available."
```

### For Integration Patterns
**Query**: "Describe the integration approach for [system] with CG Cloud TPM. Include data flow and API patterns."

**Example**:
```
Query: "Describe the integration approach for SAP ERP with CG Cloud TPM. Include data flow and API patterns."
```

## Graceful Degradation

When NotebookLM is unavailable:

**User Feedback**:
```
⚠️ NotebookLM unavailable. Using pre-trained CG TPM knowledge.

Note: Pre-trained materials were extracted on 2026-03-06.
For latest information, ensure NotebookLM is accessible.
```

**Functionality**:
- All guidance still provided
- Use pre-trained references (Tier 2)
- Suggest manual NotebookLM check for critical decisions

## Usage Examples

### Scenario 1: NotebookLM Available

```
Developer: /cg-tpm-dev How do I create a promotion?

Skill Response:
✓ From NotebookLM (latest):

Promotion Creation Workflow:
1. Set up Account Product List with eligible products
2. Create Promotion record with dates, discount
3. Link products via PromotionItem__c
4. Initialize KPI calculations (baseline, ROI)
5. Activate promotion (Status = 'Active')

[Detailed steps from NotebookLM]

Implementation Pattern (pre-trained):
[Code example from use-cases.md]
```

### Scenario 2: NotebookLM Unavailable

```
Developer: /cg-tpm-dev How do I create a promotion?

Skill Response:
⚠️ Using pre-trained CG TPM knowledge (NotebookLM unavailable)

Promotion Creation Workflow:
[Workflow from baseline knowledge in use-cases.md]

Implementation Pattern:
[Code example from use-cases.md]

Note: For latest updates, check NotebookLM when available.
```

### Scenario 3: Mixed Sources

```
Developer: /cg-tpm-dev Create promotion with claims processing

Skill Response:
✓ From NotebookLM (latest):
[Latest promotion workflow from NotebookLM]

Implementation Pattern (pre-trained):
[Code pattern from use-cases.md]

Combined Response:
[Step-by-step guide using both sources]
```

## NotebookLM Query Function

When implementing this skill, use the following pattern to query NotebookLM:

```javascript
async function queryNotebookLM(query, conversationId = null) {
    try {
        const response = await mcp__notebooklm__notebook_query({
            notebook_id: "9ca50af3-1937-43a6-87c4-3d8629a1ccbd",
            query: query,
            conversation_id: conversationId,
            timeout: 120
        });

        return {
            success: true,
            answer: response.answer,
            conversationId: response.conversation_id,
            source: "NotebookLM"
        };
    } catch (error) {
        console.warn("NotebookLM unavailable:", error);
        return {
            success: false,
            error: error.message,
            source: "Fallback"
        };
    }
}
```

## Performance Considerations

**Target Response Time**: < 120 seconds for NotebookLM queries

**Optimization Strategies**:
- Cache frequently queried content (optional)
- Use conversation_id for follow-up questions
- Fallback to pre-trained immediately if timeout

## Monitoring & Maintenance

**Track**:
- NotebookLM query success rate
- Average query response time
- Fallback usage frequency

**Update Schedule**:
- Review pre-trained knowledge quarterly
- Update when CG Cloud releases major features
- Regenerate after significant NotebookLM source additions

## Configuration Reference

See `config.json` for:
- Query templates
- Timeout settings
- Pre-trained file locations
- Feature flags
