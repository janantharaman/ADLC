# {{industry_name}} Full-Stack Developer (`/{{skill_name}}`)

## Overview

This skill provides expert-level {{industry_name}} development capabilities, combining:
- **Generic Salesforce Expertise** (from `/fullstack-dev`): Apex, LWC, Agentforce, Data Cloud, testing
- **{{industry_name}} Specialization**: Industry data models, regulatory compliance, integrations

**When to Use**: Invoke `/{{skill_name}}` for {{industry_name}}-specific feature development.

**When to Delegate**:
- Generic Salesforce development → `/fullstack-dev`
- Architecture design → `/architect`
- Deep Apex optimization → `/apex-dev`
- Complex LWC patterns → `/lwc-dev`

---

## Key Capabilities

### {{industry_name}} Data Models

Expert knowledge of {{industry_name}} objects:
{{#each data_models}}
- **{{object}}**: {{description}}
{{/each}}

**Reference**: `./references/{{reference_file_prefix}}-data-models.md`

---

{{#if regulatory_frameworks}}
{{#if (gt regulatory_frameworks.length 0)}}
### Regulatory Compliance

Deep understanding of compliance requirements:
{{#each regulatory_frameworks}}
- **{{name}}**: {{description}}
{{/each}}

**Reference**: `./references/{{reference_file_prefix}}-regulatory.md`

---

{{/if}}
{{/if}}

{{#if key_integrations}}
{{#if (gt key_integrations.length 0)}}
### External Integrations

Experience with industry-standard integrations:
{{#each key_integrations}}
- **{{name}}** ({{protocol}}): {{use_case}}
{{/each}}

**Reference**: `./references/{{reference_file_prefix}}-integrations.md`

---

{{/if}}
{{/if}}

### Industry-Specific Competencies

{{#each unique_competencies}}
#### {{area}} ({{expertise_level}})
{{#each capabilities}}
- {{this}}
{{/each}}

{{/each}}

---

## Common Use Cases

{{#each use_cases}}
### {{@index}}. {{title}}

{{description}}

**Technical Stack**: {{#each technical_components}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}

{{/each}}

**Reference**: `./references/{{reference_file_prefix}}-use-cases.md` for detailed examples

---

## Technical Stack

### Backend (Apex)
- Custom objects and relationships
- Business logic enforcement
- Integration services
{{#if regulatory_frameworks}}- Compliance validation{{/if}}
- Batch processing for large data volumes

### Frontend (LWC)
- Industry-specific components
- Data visualization
- User interaction patterns
- Error handling and validation

### AI & Automation (Agentforce)
- Context engineering for {{industry_name}}
{{#if regulatory_frameworks}}- Trust Layer with {{regulatory_frameworks.[0].name}} compliance{{/if}}
- RAG with Data Cloud grounding
- Predictive analytics

### Data Platform (Data Cloud)
- Zero-copy data integration
- Real-time data ingestion
- Semantic layer for AI
- Cross-cloud analytics

---

## File Structure

```
{{skill_name}}/
├── SKILL.md                          # Main skill definition (this file used by AI)
├── README.md                         # Human-readable documentation (you are here)
├── EXTENDS.md                        # How this extends /fullstack-dev
{{#if sources}}├── SOURCES.md                        # Source notebook documentation{{/if}}
└── references/                       # Deep-dive technical guides
    ├── {{reference_file_prefix}}-data-models.md
    {{#if regulatory_frameworks}}├── {{reference_file_prefix}}-regulatory.md{{/if}}
    {{#if key_integrations}}├── {{reference_file_prefix}}-integrations.md{{/if}}
    └── {{reference_file_prefix}}-use-cases.md
```

---

## Quick Start

### 1. Invoke the Skill

```bash
/{{skill_name}} "Build {{use_cases.[0].title}}"
```

### 2. Expected Behavior

The AI will:
1. Understand {{industry_name}} context
2. Reference correct data models ({{data_models.[0].object}}, etc.)
{{#if regulatory_frameworks}}3. Ensure {{regulatory_frameworks.[0].name}} compliance{{/if}}
4. Implement full-stack solution (Apex + LWC)
5. Provide test coverage (75%+)

### 3. Example Output

- Apex controller with `with sharing` and `SECURITY_ENFORCED`
- LWC component with error handling
- Test class with {{industry_name}} test data factory
- Integration patterns for external systems

---

## Routing Indicators

Astro will automatically route to `/{{skill_name}}` when it detects:

{{#each routing_indicators}}
- "{{this}}"
{{/each}}

**Manual Invocation**: Use `/{{skill_name}}` directly for explicit routing.

---

## Integration with Base Skills

This skill **extends** `/fullstack-dev` and inherits:
- Apex & LWC integration patterns
- Agentforce & Data Cloud capabilities
- Testing standards (75%+ coverage)
- Security best practices
- DevOps & CI/CD patterns

**See**: `EXTENDS.md` for detailed inheritance documentation

---

## Reference Files

Deep-dive technical guides:

{{#each reference_files}}
### {{name}}

{{description}}

**Sections**:
{{#each sections}}
- {{this}}
{{/each}}

**Location**: `./references/{{name}}`

{{/each}}

---

## Knowledge Sources

{{#if sources}}
This skill was generated from industry knowledge extracted on {{sources.extraction_date}}.

**Source Notebook**: {{sources.notebook_url}}

See `SOURCES.md` for details on source materials.
{{else}}
This skill was manually curated from industry best practices and Salesforce documentation.
{{/if}}

---

## Testing

### Unit Tests
```apex
@IsTest
private class {{industry_name}}ControllerTest {
    @IsTest
    static void testGet{{data_models.[0].object}}() {
        // Setup test data
        {{data_models.[0].object}} record = {{industry_name}}TestDataFactory.create{{data_models.[0].object}}();

        // Test
        Test.startTest();
        List<{{industry_name}}ViewModel> results = {{industry_name}}Controller.getData();
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size());
    }
}
```

### Integration Tests
```apex
@IsTest
private class {{industry_name}}IntegrationTest {
    @IsTest
    static void testEndToEndFlow() {
        // Test full user journey across {{industry_name}} objects
    }
}
```

### LWC Tests
```javascript
import { createElement } from 'lwc';
import {{industry_name}}Component from 'c/{{camelCase industry_name}}Component';

describe('c-{{kebabCase industry_name}}-component', () => {
    it('renders {{industry_name}} data correctly', () => {
        const element = createElement('c-{{kebabCase industry_name}}-component', {
            is: {{industry_name}}Component
        });
        document.body.appendChild(element);
        // Assertions
    });
});
```

---

## Best Practices

1. **Always use ViewModel pattern** for Apex ↔ LWC contracts
2. **Enforce sharing and FLS** with `with sharing` and `SECURITY_ENFORCED`
{{#if regulatory_frameworks}}3. **Validate {{regulatory_frameworks.[0].name}} compliance** before deployment{{/if}}
4. **Test thoroughly**: 75%+ coverage with integration tests
5. **Document industry patterns** in code comments
6. **Use NotebookLM** for deep research on edge cases

---

## Support & Feedback

- **Issues**: Report bugs or request features in project repository
- **Documentation**: See `./references/` for detailed guides
- **Base Patterns**: Reference `../fullstack-dev/references/`

---

## Version History

- **Generated**: {{#if sources}}{{sources.extraction_date}}{{else}}Manual creation{{/if}}
- **Industry**: {{industry_name}}
- **Base Skill**: `/fullstack-dev`
- **Specializations**: {{unique_competencies.length}} competency areas, {{data_models.length}} data models{{#if regulatory_frameworks}}, {{regulatory_frameworks.length}} regulatory frameworks{{/if}}
