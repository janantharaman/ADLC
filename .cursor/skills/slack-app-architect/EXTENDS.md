# Extension: Slack App Architect extends JavaScript Architect

**Base Skill**: `/js-architect` (Arnav)
**Extended Skill**: `/slack-app-architect` (Devika)

## Inheritance Model

The `/slack-app-architect` skill **extends** `/js-architect`, inheriting Node.js/TypeScript architecture expertise while adding Slack platform specialization.

```
/js-architect (Base - Arnav)
    ↓ extends
/slack-app-architect (Extended - Devika)
```

## Inherited from js-architect

1. **Architecture Patterns**: Microservices, clean architecture, hexagonal
2. **Data Structures & Algorithms**: Complexity, caching, streaming
3. **High-Performance Node.js**: Event loop, clustering, worker threads
4. **Scalable Enterprise Systems**: Horizontal scaling, fault tolerance
5. **TypeScript**: Advanced types, design patterns
6. **REST/API Design**: Versioning, security, performance
7. **Layer 1 + Layer 4**: Universal Foundation, Methodology

## Slack-Specific Extensions

1. **Slack App Design**: Manifest, OAuth, enterprise requirements
2. **Bolt Framework**: Events, slash commands, modals, workflows
3. **Slack APIs**: Web API, Events API, Workflow Builder
4. **Performance**: < 3s response, rate limits, async
5. **Security**: Tokens, signing, enterprise (EKM, DLP)
6. **Deployment**: Distribution, org apps, production

## Knowledge Sources

| Source | Notebook ID | Purpose |
|--------|-------------|---------|
| Slack NotebookLM | cf579b20-7f14-4828-8a9a-c0d7214e73f8 | Slack patterns, API, best practices |
| js-architect | 06dda307-e864-475d-957e-8e92de24d79d | Node.js base (inherited) |

## When to Use

### Use `/slack-app-architect` for:
- Slack app development (any phase)
- Bolt framework, Events API
- Enterprise Slack apps
- Slack-Salesforce integration (Slack side)

### Use `/js-architect` for:
- Generic Node.js (non-Slack)
- When Slack context not needed
