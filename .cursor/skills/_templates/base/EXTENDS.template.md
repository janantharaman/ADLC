# How `/{{skill_name}}` Extends `/fullstack-dev`

## Architecture

This skill follows a **composition over duplication** approach:

```
/{{skill_name}} (Industry-Specific)
    └── extends /fullstack-dev (Generic Salesforce)
            └── references /apex-dev (Backend Deep-Dive)
            └── references /lwc-dev (Frontend Deep-Dive)
```

---

## Inherited Competencies (from `/fullstack-dev`)

The following capabilities are **inherited** and do NOT need to be duplicated:

### Backend & Frontend Integration
- ViewModel pattern (Apex ↔ LWC contracts)
- API contract design (REST/GraphQL)
- Cross-layer error handling
- End-to-end testing strategies

### 2026-Forward Platform Capabilities
- **Agentforce & Predictive AI**: Atlas Reasoning, RAG, Trust Layer, Observability
- **Data Cloud/Genie**: Zero-copy grounding, semantic layer, real-time ingestion
- **External Client Apps**: OAuth 2.0, federated identity, token management
- **Slack-First Orchestration**: Multiplayer workflows, canvas apps, notifications
- **Context Engineering**: AI context design for high ROI

### Strategic Architecture
- Identity & Access Management
- Event-Driven Architecture
- Large Data Volumes
- Flow Orchestration
- DevOps & CI/CD (Copado/SFDX)

### Testing Standards
- 75%+ code coverage requirement
- Unit + Integration + E2E testing
- Test data factory patterns
- Mocking strategies

### Security Best Practices
- Sharing rules (`with sharing`)
- Field-level security (`WITH SECURITY_ENFORCED`)
- CRUD/FLS enforcement
- PII masking and data protection

**Reference**: `../fullstack-dev/SKILL.md` for complete generic patterns

---

## Added Specializations ({{industry_name}}-Specific)

This skill **adds** the following {{industry_name}} expertise:

### 1. Industry Data Models

{{#each data_models}}
#### {{object}}
- **Purpose**: {{description}}
- **Key Fields**: {{#each key_fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
- **Relationships**: {{#each relationships}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
{{/each}}

**Why This Matters**: Generic `/fullstack-dev` doesn't know {{industry_name}} object names, field relationships, or business semantics. This skill provides deep object model expertise.

**Reference**: `./references/{{reference_file_prefix}}-data-models.md`

---

{{#if regulatory_frameworks}}
{{#if (gt regulatory_frameworks.length 0)}}
### 2. Regulatory Compliance

{{#each regulatory_frameworks}}
#### {{name}}
- **Scope**: {{description}}
- **Requirements**: {{#each key_requirements}}{{this}}{{#unless @last}}; {{/unless}}{{/each}}
{{/each}}

**Why This Matters**: Generic `/fullstack-dev` doesn't enforce industry-specific compliance. This skill ensures {{#each regulatory_frameworks}}{{name}}{{#unless @last}}, {{/unless}}{{/each}} requirements are met in all implementations.

**Reference**: `./references/{{reference_file_prefix}}-regulatory.md`

---

{{/if}}
{{/if}}

{{#if key_integrations}}
{{#if (gt key_integrations.length 0)}}
### 3. External System Integrations

{{#each key_integrations}}
#### {{name}}
- **Protocol**: {{protocol}}
- **Use Case**: {{use_case}}
- **Pattern**: {{example_endpoint}}
{{/each}}

**Why This Matters**: Generic `/fullstack-dev` doesn't know industry-standard systems or integration patterns. This skill provides pre-built integration templates.

**Reference**: `./references/{{reference_file_prefix}}-integrations.md`

---

{{/if}}
{{/if}}

### 4. Industry-Specific Competencies

{{#each unique_competencies}}
#### {{area}} ({{expertise_level}})

**Capabilities**:
{{#each capabilities}}
- {{this}}
{{/each}}

{{/each}}

**Why This Matters**: Generic `/fullstack-dev` lacks domain expertise in {{industry_name}} business processes. This skill provides specialized knowledge for industry use cases.

---

### 5. Industry Use Cases & Examples

{{#each use_cases}}
#### {{title}}
- **Description**: {{description}}
- **Components**: {{#each technical_components}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
{{/each}}

**Why This Matters**: Generic `/fullstack-dev` provides patterns but not industry context. This skill includes real-world {{industry_name}} scenarios and implementations.

**Reference**: `./references/{{reference_file_prefix}}-use-cases.md`

---

## Composition Strategy

### What Gets Inherited (DRY Principle)

**Generic Salesforce patterns are inherited, NOT duplicated**:
- Apex syntax and best practices → Reference `/fullstack-dev`
- LWC component lifecycle → Reference `/fullstack-dev`
- Agentforce integration code → Reference `/fullstack-dev/references/agentforce-patterns.md`
- Data Cloud queries → Reference `/fullstack-dev/references/data-cloud-zero-copy.md`
- Testing frameworks → Reference `/fullstack-dev/references/testing-cross-layer.md`

### What Gets Specialized (Industry Context)

**{{industry_name}}-specific knowledge is added**:
- Object model ({{#each data_models}}{{object}}{{#unless @last}}, {{/unless}}{{/each}})
{{#if regulatory_frameworks}}- Compliance ({{#each regulatory_frameworks}}{{name}}{{#unless @last}}, {{/unless}}{{/each}}){{/if}}
{{#if key_integrations}}- Integrations ({{#each key_integrations}}{{name}}{{#unless @last}}, {{/unless}}{{/each}}){{/if}}
- Business process expertise
- Use case templates

---

## When to Use Each Skill

### Use `/{{skill_name}}` When:
- Working with {{industry_name}} objects ({{data_models.[0].object}}, etc.)
{{#if regulatory_frameworks}}- {{regulatory_frameworks.[0].name}} compliance is required{{/if}}
- Building industry-specific features ({{use_cases.[0].title}}, etc.)
- Need domain expertise in {{#each unique_competencies}}{{area}}{{#unless @last}}, {{/unless}}{{/each}}

### Use `/fullstack-dev` When:
- Generic Salesforce development (no industry context)
- Custom objects (not industry-standard)
- Learning generic patterns (Agentforce, Data Cloud, testing)
- Architecture patterns (event-driven, LDV, etc.)

### Use `/apex-dev` When:
- Deep Apex optimization (governor limits, batch processing)
- Complex trigger frameworks
- Low-level performance tuning

### Use `/lwc-dev` When:
- Advanced SLDS customization
- Complex accessibility requirements
- Frontend architecture deep-dives

### Use `/architect` When:
- Solution design (high-level architecture)
- Well-Architected analysis
- Multi-cloud architecture

---

## Example: Inheritance in Action

### Scenario: Build {{use_cases.[0].title}}

**Step 1: Understand Context** (`/{{skill_name}}` expertise)
- Identifies required {{industry_name}} objects: {{data_models.[0].object}}
{{#if regulatory_frameworks}}- Validates {{regulatory_frameworks.[0].name}} requirements{{/if}}
- Plans integration with {{key_integrations.[0].name}}

**Step 2: Design ViewModel** (`/fullstack-dev` inherited pattern)
```apex
// Generic pattern from /fullstack-dev
public class {{industry_name}}ViewModel {
    @AuraEnabled public String id;
    @AuraEnabled public String displayName;
    // ... ViewModel fields
}
```

**Step 3: Implement Controller** (`/{{skill_name}}` + `/fullstack-dev`)
```apex
// Generic pattern: with sharing, SECURITY_ENFORCED (from /fullstack-dev)
// Industry context: {{data_models.[0].object}} query (from /{{skill_name}})
public with sharing class {{industry_name}}Controller {
    @AuraEnabled
    public static List<{{industry_name}}ViewModel> getData() {
        List<{{data_models.[0].object}}> records = [
            SELECT {{#each data_models.[0].key_fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
            FROM {{data_models.[0].object}}
            WITH SECURITY_ENFORCED
        ];
        return transform(records);
    }
}
```

**Step 4: Build LWC** (`/fullstack-dev` inherited pattern)
```javascript
// Generic LWC pattern from /fullstack-dev
import { LightningElement, track } from 'lwc';
import getData from '@salesforce/apex/{{industry_name}}Controller.getData';

export default class {{industry_name}}Component extends LightningElement {
    @track viewModel;
    // ... LWC implementation
}
```

**Step 5: Add Tests** (`/fullstack-dev` inherited standard)
```apex
// 75%+ coverage requirement from /fullstack-dev
// {{industry_name}} test data from /{{skill_name}}
@IsTest
private class {{industry_name}}ControllerTest {
    @IsTest
    static void testGetData() {
        {{data_models.[0].object}} record = {{industry_name}}TestDataFactory.create{{data_models.[0].object}}();
        Test.startTest();
        List<{{industry_name}}ViewModel> results = {{industry_name}}Controller.getData();
        Test.stopTest();
        System.assertEquals(1, results.size());
    }
}
```

**Result**:
- Generic patterns inherited (no duplication)
- {{industry_name}} expertise applied where needed
- Clean separation of concerns

---

## Benefits of Extension Model

### 1. No Duplication
- Generic Salesforce patterns live in one place (`/fullstack-dev`)
- Industry skills reference, not repeat
- Updates to `/fullstack-dev` benefit all industry skills

### 2. Clear Boundaries
- `/fullstack-dev`: Platform capabilities
- `/{{skill_name}}`: Industry domain knowledge
- No confusion about where patterns belong

### 3. Composability
- New industry skills can be added without modifying base
- Each industry skill is independent
- Astro routes intelligently based on context

### 4. Maintainability
- Update generic patterns once in `/fullstack-dev`
- Industry skills stay focused on domain knowledge
- Easier to keep skills current

---

## Skills Hierarchy

```
/architect (Solution Design)
    └── /fullstack-dev (Generic Full-Stack)
            ├── /apex-dev (Backend Specialist)
            ├── /lwc-dev (Frontend Specialist)
            └── Industry Skills (Domain Specialists)
                    ├── /{{skill_name}} ({{industry_name}})
                    ├── /health-dev (Health Cloud)
                    ├── /fs-dev (Field Service)
                    └── ... (other industries)
```

---

## Summary

**This skill (`/{{skill_name}}`) is NOT a standalone entity**. It's a **specialized extension** of `/fullstack-dev` that adds {{industry_name}} domain expertise while inheriting all generic Salesforce capabilities.

**Think of it as**:
- `/fullstack-dev` = Salesforce platform expert
- `/{{skill_name}}` = Salesforce platform expert **+ {{industry_name}} domain expert**

**Always reference base skills** for generic patterns. This skill focuses exclusively on {{industry_name}} specializations.
