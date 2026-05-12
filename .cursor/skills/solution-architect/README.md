# Solution Architect Skill

Expert Salesforce Solution Architect skill for Cursor IDE.

## Usage

Invoke the skill in Cursor using:
```
/architect
```

## What This Skill Provides

- **Well-Architected Framework Expertise**: TRUSTED, EASY, ADAPTABLE pillars
- **NotebookLM Integration**: Dynamic knowledge retrieval for patterns and anti-patterns
- **Architectural Decision-Making**: Pattern selection, trade-off analysis, risk assessment
- **Multi-Domain Architecture**: Solution, data, integration, security, performance
- **Compliance & Standards**: Accessibility, security, regulatory requirements
- **Implementation Roadmap**: Phased approach with dependencies and risks

## Core Competencies

### Well-Architected Framework
- **TRUSTED**: Security, privacy, compliance, performance, resilience
- **EASY**: User experience, developer experience, maintainability
- **ADAPTABLE**: Scalability, flexibility, modularity, composability

### Architectural Domains
- Solution Architecture (end-to-end system design)
- Data Architecture (modeling, large volumes, migration)
- Integration Architecture (APIs, events, middleware)
- Security Architecture (authentication, authorization, compliance)
- Performance Architecture (optimization, caching, scalability)

## NotebookLM Knowledge Integration

This skill uses **NotebookLM as its primary knowledge source** for:
- Well-Architected patterns (24 patterns across 3 pillars)
- Accessibility standards (data entry, navigation, testing)
- Session security patterns (7 patterns)
- Anti-patterns to avoid

**Available Notebooks**:
- **Salesforce Well-Architected: Accessibility & Testing** (`03600af5-b421-4a6d-89d1-dcae0a482175`)

**Fallback**: If NotebookLM is unavailable, the skill uses built-in Well-Architected knowledge from foundation rules (`.cursor/rules/06-salesforce-architecture-principles.md`).

See `../_shared/notebooklm-knowledge.md` for complete integration pattern.

## Communication Style

This skill is designed for **technical leaders and enterprise architects**:
- Strategic focus on high-level design
- Pattern-based recommendations
- Trade-off analysis and decision documentation
- Cites NotebookLM patterns when applied
- Pragmatic balance of ideal vs. practical
- Visual diagrams where helpful

## Example Use Cases

### 1. **Design High-Volume Solution**
```
/architect
"Design a case management system for 100K+ cases per month with global support team"
```

**Skill will**:
- Query NotebookLM for scalability, accessibility, security patterns
- Propose architecture using Well-Architected Framework
- Document trade-offs and decisions
- Provide implementation roadmap
- Define testing strategy

### 2. **Architecture Review**
```
/architect
"Review this architecture for B2B commerce portal and identify risks"
```

**Skill will**:
- Query NotebookLM for relevant patterns and anti-patterns
- Evaluate against Well-Architected pillars
- Identify risks and anti-patterns present
- Recommend improvements with pattern references
- Prioritize remediations

### 3. **Accessibility Compliance Design**
```
/architect
"Design a customer onboarding portal that meets WCAG 2.1 AA standards"
```

**Skill will**:
- Query NotebookLM for accessibility patterns
- Apply data entry and navigation patterns
- Define multi-device and multi-language support
- Create accessibility testing strategy
- Validate against anti-patterns

### 4. **Integration Architecture**
```
/architect
"Design real-time integration between Salesforce and external ERP for order sync"
```

**Skill will**:
- Query NotebookLM for integration and security patterns
- Evaluate integration patterns (real-time, batch, event-driven)
- Design authentication and error handling
- Define API versioning strategy
- Create monitoring approach

### 5. **Security Architecture**
```
/architect
"Design secure authentication for external partner portal with MFA and SSO"
```

**Skill will**:
- Query NotebookLM for session security patterns
- Apply MFA, SSO, session timeout patterns
- Design threat detection and monitoring
- Define compliance requirements
- Validate against security anti-patterns

## Common Architecture Scenarios

The skill has deep knowledge of:
- High-volume case management
- B2B/B2C commerce portals
- Real-time integrations (ERP, external systems)
- Multi-tenant solutions
- Data migration and archival
- Mobile-first applications
- Partner/customer portals
- Global deployments with localization

## Output Format

When invoked, the skill provides:

```markdown
## Architecture Proposal: [Name]

### Requirements Summary
[Business and technical requirements]

### NotebookLM Patterns Retrieved
[Patterns from Well-Architected Framework]

### Architecture Overview
[High-level diagram and description]

### Well-Architected Analysis
- TRUSTED: [Security, performance, resilience]
- EASY: [User experience, maintainability]
- ADAPTABLE: [Scalability, flexibility]

### Trade-Offs & Decisions
[Options evaluated and decisions made]

### Anti-Patterns Validated Against
[Patterns avoided from NotebookLM]

### Implementation Sequence
[Phased approach]

### Testing Strategy
[Accessibility, performance, integration testing]

### Risks & Mitigations
[Identified risks with mitigation strategies]
```

## When to Use This Skill

Invoke `/architect` for:
- ✅ Designing new solutions from scratch
- ✅ Reviewing existing architectures
- ✅ Making architectural decisions (build vs. buy, pattern selection)
- ✅ Accessibility compliance design
- ✅ Security architecture design
- ✅ Scalability planning (high volume, growth)
- ✅ Integration architecture (APIs, events, middleware)
- ✅ Trade-off analysis (performance vs. flexibility)

## When to Delegate

- **Apex implementation** → `/apex-dev`
- **LWC implementation** → `/lwc-dev`
- **Test automation** → `/qa`
- **DevOps/CI/CD** → `/devops`
- **Data migration** → `/data-architect`

## Testing the Skill

To test this skill:
1. Open Cursor IDE in this project
2. Type `/architect` to invoke the skill
3. Provide an architectural design task
4. Verify the agent:
   - Queries NotebookLM for relevant patterns (if available)
   - Applies Well-Architected Framework (TRUSTED, EASY, ADAPTABLE)
   - Documents trade-offs and decisions
   - Validates against anti-patterns
   - Provides implementation roadmap

## Dependencies

### Required
- `.cursor/rules/06-salesforce-architecture-principles.md` (Well-Architected Framework basics)
- `../_shared/notebooklm-knowledge.md` (NotebookLM integration pattern)

### Optional (Enhanced Mode)
- NotebookLM MCP server (for dynamic pattern retrieval)
- Authenticated NotebookLM account (for accessing notebooks)

### Fallback
If NotebookLM is unavailable:
- Skill falls back to built-in Well-Architected knowledge from foundation rules
- Still provides expert architecture guidance
- Missing: Real-time pattern updates and latest accessibility standards

## Next Steps

After using this skill:
1. Document architecture decisions in Architecture Decision Records (ADRs)
2. Share with development team for implementation planning
3. Delegate implementation to appropriate skills (`/apex-dev`, `/lwc-dev`)
4. Define success metrics and monitoring strategy
5. Schedule architecture review after implementation

## Resources

- **Salesforce Well-Architected**: https://architect.salesforce.com
- **Foundation Rules**: `.cursor/rules/06-salesforce-architecture-principles.md`
- **NotebookLM Integration**: `../_shared/notebooklm-knowledge.md`
- **Pattern Catalog**: `.cursor/skills/architecture-references/`

---

**Version**: 1.0
**Created**: 2026-02-28
**Part of**: Salesforce Development Expert System
