# NotebookLM Knowledge Integration for Slack App Architect

> **Pattern**: Two-tier knowledge strategy. Extends js-architect. Slack-specific NotebookLM.

## Configuration

**Notebook ID**: `cf579b20-7f14-4828-8a9a-c0d7214e73f8`
**URL**: https://notebooklm.google.com/notebook/cf579b20-7f14-4828-8a9a-c0d7214e73f8
**Last Updated**: 2026-03-12

## Query Strategy

### Slack Design
- "What are the architecture and design patterns for [topic] in Slack apps? Include enterprise requirements."

### Bolt Framework
- "What are the Bolt framework best practices for [feature]? Include events and modals."

### Slack API
- "How do I use Slack API for [use_case]? Include rate limits and error handling."

### Deployment
- "What are the deployment patterns for [scenario] in enterprise Slack apps?"

### Security
- "What are the security requirements for Slack apps in enterprise? Include tokens and OAuth."

## MCP Tool Usage

```javascript
await mcp__notebooklm__notebook_query({
    notebook_id: "cf579b20-7f14-4828-8a9a-c0d7214e73f8",
    query: "Your Slack-specific question here",
    conversation_id: null,
    timeout: 120
});
```

## Inheritance Note

For Node.js/TypeScript patterns (non-Slack), also consider querying js-architect's NotebookLM:
- notebook_id: 06dda307-e864-475d-957e-8e92de24d79d
