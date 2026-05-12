# NotebookLM Knowledge Integration for Senior Java Developer

> **Pattern**: Two-tier knowledge strategy (Try → Fallback → Always Provide)

## Configuration

**Notebook ID**: `c7c284d4-30f1-4770-9b34-7cda51acf9fd`
**Notebook URL**: https://notebooklm.google.com/notebook/c7c284d4-30f1-4770-9b34-7cda51acf9fd
**Notebook Title**: Java Knowledge Base - Senior Developer
**Last Updated**: 2026-03-12

## Two-Tier Knowledge Strategy

### Tier 1: NotebookLM (Live Knowledge)
- Queries Java NotebookLM in real-time
- Always-current information from your knowledge base
- Used for: implementation patterns, best practices, framework updates

### Tier 2: Built-in Knowledge (Fallback)
- Comprehensive Java/Spring expertise in SKILL.md
- Offline-capable
- Used when NotebookLM unavailable

## Query Strategy

When a developer uses `/java-senior-dev` for implementation:

### Step 1: Analyze Request
Determine what knowledge is needed:
- Spring Boot pattern? → Query for framework best practices
- REST API design? → Query for API patterns
- Database optimization? → Query for JPA/Hibernate patterns
- Salesforce integration? → Query for external API patterns

### Step 2: Try NotebookLM First
```
TRY:
  Query NotebookLM with context-specific question
  Extract relevant information
  Use in response: "✓ From NotebookLM (latest)"
CATCH NotebookLMUnavailable:
  Fall back to built-in knowledge (SKILL.md)
  Warn user: "⚠️ Using built-in Java knowledge. NotebookLM unavailable."
```

### Step 3: Combine with Built-in Knowledge
Even when NotebookLM works:
- Use NotebookLM for latest information
- Supplement with built-in patterns for implementation details
- Validate consistency between sources

## Query Templates

### For Spring Boot
**Query**: "What are the best practices for [topic] in Spring Boot? Include code examples if available."

**Examples**:
- "What are the best practices for REST API error handling in Spring Boot?"
- "What are the best practices for configuration management in Spring Boot 3.x?"

### For REST APIs
**Query**: "What are the REST API design patterns for [domain]? Include validation and error handling."

**Examples**:
- "What are the REST API design patterns for order management? Include validation and error handling."
- "What are the best practices for API versioning in REST?"

### For Database/JPA
**Query**: "How do I optimize JPA/Hibernate for [scenario]? Include N+1 prevention and indexing."

**Examples**:
- "How do I optimize JPA for bulk insert operations? Include batch size and N+1 prevention."
- "What are the best practices for JPA entity relationships and lazy loading?"

### For Microservices
**Query**: "What are the patterns for [feature] in Java microservices? Include resilience and observability."

**Examples**:
- "What are the patterns for circuit breakers in Java microservices?"
- "How do I implement retry logic for external API calls in Spring Boot?"

### For Salesforce Integration
**Query**: "How do I integrate Java with Salesforce [api_type]? Include OAuth and error handling."

**Examples**:
- "How do I integrate Java with Salesforce REST API? Include OAuth 2.0 JWT and error handling."
- "What are the best practices for Salesforce Bulk API 2.0 from Java?"

## MCP Tool Usage

When implementing, use the NotebookLM MCP tool:

```javascript
// Call notebook_query via MCP
await mcp__notebooklm__notebook_query({
    notebook_id: "c7c284d4-30f1-4770-9b34-7cda51acf9fd",
    query: "Your context-specific question here",
    conversation_id: null,
    timeout: 120
});
```

## Graceful Degradation

When NotebookLM is unavailable:

**User Feedback**:
```
⚠️ Using built-in Java knowledge (NotebookLM unavailable).

Note: For latest patterns, ensure NotebookLM is accessible.
Run `nlm login` if authentication has expired.
```

**Functionality**:
- All guidance still provided from SKILL.md
- Suggest manual NotebookLM check for critical decisions

## Performance Considerations

**Target Response Time**: < 120 seconds for NotebookLM queries

**Optimization**:
- Use conversation_id for follow-up questions
- Fallback to built-in immediately if timeout
