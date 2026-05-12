# NotebookLM Knowledge Integration for Senior JavaScript Architect

> **Pattern**: Two-tier knowledge strategy (Try → Fallback → Always Provide)

## Configuration

**Notebook ID**: `06dda307-e864-475d-957e-8e92de24d79d`
**Notebook URL**: https://notebooklm.google.com/notebook/06dda307-e864-475d-957e-8e92de24d79d
**Last Updated**: 2026-03-12

## Query Templates

### Architecture
- "What are the architecture patterns for [topic] in Node.js/TypeScript? Include scalability and performance."

### Performance
- "How do I optimize Node.js for [scenario]? Include event loop, streaming, and clustering."

### Data Structures
- "What data structures and algorithms are best for [use_case] in JavaScript/TypeScript?"

### Scalability
- "What are the patterns for [feature] in highly scalable Node.js enterprise systems?"

### Salesforce Integration
- "How do I integrate Node.js with Salesforce REST API? Include OAuth 2.0 and error handling."

## MCP Tool Usage

```javascript
await mcp__notebooklm__notebook_query({
    notebook_id: "06dda307-e864-475d-957e-8e92de24d79d",
    query: "Your context-specific question here",
    conversation_id: null,
    timeout: 120
});
```
