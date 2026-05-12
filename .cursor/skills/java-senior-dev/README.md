# Senior Java Developer Skill

**Skill ID**: `java-senior-dev`
**Display Name**: Senior Java Developer (Karthik)
**Version**: 1.0.0
**Created**: 2026-03-12

## Overview

Expert-level guidance for Java backend development with Spring Boot, microservices, and REST APIs. This skill provides comprehensive support for enterprise Java development with **dynamic NotebookLM integration** for always-current knowledge.

## NotebookLM Integration

This skill uses a **two-tier knowledge strategy**:

### Tier 1: NotebookLM (Live Knowledge) ⭐
- Queries Java NotebookLM in real-time
- **Notebook ID**: `c7c284d4-30f1-4770-9b34-7cda51acf9fd`
- **URL**: https://notebooklm.google.com/notebook/c7c284d4-30f1-4770-9b34-7cda51acf9fd
- Always-current information from your knowledge base

### Tier 2: Built-in Knowledge (Fallback) 📚
- Comprehensive Java/Spring expertise in SKILL.md
- Offline-capable
- Used when NotebookLM unavailable

**Indicators**:
- `✓ From NotebookLM` - Using live knowledge base
- `⚠️ Built-in knowledge` - Using built-in expertise (NotebookLM unavailable)

## Usage

### Direct Invocation
```
/java-senior-dev "Create a Spring Boot REST API for order management"
```

### Via Astro (Orchestration)
```
/astro "Build a Java microservice that integrates with Salesforce"
```

## Core Competencies

- **Spring Boot**: Application structure, configuration, dependency injection
- **REST APIs**: Design, validation, versioning
- **Database**: JPA/Hibernate, Spring Data, query optimization
- **Microservices**: Service communication, resilience, observability
- **Testing**: JUnit 5, Mockito, integration tests (75%+ coverage)
- **Salesforce Integration**: REST APIs, OAuth 2.0, Bulk API

## Example Use Cases

1. **Create REST API**
   ```
   /java-senior-dev "Create a REST API for customer management with CRUD operations"
   ```

2. **Spring Boot Service**
   ```
   /java-senior-dev "Implement a Spring Boot service for order processing with JPA"
   ```

3. **Salesforce Integration**
   ```
   /java-senior-dev "Build a Java service that syncs data with Salesforce via REST API"
   ```

4. **Microservice**
   ```
   /java-senior-dev "Create a microservice for inventory management with circuit breaker"
   ```

## Layer Composition

- **Layer 1**: Universal Foundation (naming, security, performance, testing)
- **Layer 4**: Methodology (Well-Architected, Configuration-First, production-ready)
- **Layer 2**: Integration + Java specialization

## When to Delegate

- Architecture design → `/solution-architect`
- Salesforce integration design → `/integration-architect`
- Technical deep-dive → `/technical-architect`

## Testing the Skill

1. Open Cursor IDE in this project
2. Type `/java-senior-dev` to invoke directly, or `/astro` for orchestration
3. Provide a Java development task
4. Verify expert-level Java code with proper patterns and NotebookLM attribution
