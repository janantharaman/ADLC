# Extension: Senior Java Developer (Standalone)

**Skill**: `/java-senior-dev`
**Base**: Standalone (does not extend another skill)

## Overview

The Senior Java Developer skill is a **standalone** skill for enterprise Java backend development. It does not extend another skill but operates within the same composable architecture (Layer 1 + Layer 4) as other team members.

## Architecture Alignment

```
Layer 1 (Universal) + Layer 4 (Methodology)
    ↓
/java-senior-dev (Java + Integration specialization)
```

## Relationship to Other Skills

### Complements (Collaboration)
- **Integration Architect** (`/integration-architect`): Rahul designs integration architecture; Karthik implements Java-side
- **Solution Architect** (`/solution-architect`): Priya designs overall system; Karthik implements Java components
- **Technical Architect** (`/technical-architect`): Aditya provides deep technical design; Karthik implements

### Distinct Scope
- **Apex Developer** (`/apex-dev`): Salesforce backend (Apex) - different platform
- **Java Senior Dev** (`/java-senior-dev`): Java backend - external systems, microservices

## Inherited Principles (from Layer 1 + Layer 4)

1. **Naming Conventions**: Java standards (camelCase, PascalCase)
2. **Security**: Input validation, authentication, authorization
3. **Performance**: Resource limits, bulk operations, optimization
4. **Testing**: 75%+ coverage, integration tests
5. **Well-Architected**: Trusted, Easy, Adaptable
6. **Configuration-First**: Spring config before code
7. **Production-Ready**: Error handling, documentation, deployment

## Knowledge Source

| Source | Type | Purpose |
|--------|------|---------|
| NotebookLM | Live (Tier 1) | Java patterns, Spring Boot, best practices |
| SKILL.md | Built-in (Tier 2) | Fallback when NotebookLM unavailable |

## When to Use

- Java backend development
- Spring Boot REST APIs
- Microservices
- Java-Salesforce integration
- External system backends (Java)
