# Knowledge Sources for `/{{skill_name}}`

## Overview

This skill was generated from industry-specific knowledge extracted using the **Skill Builder System**. The knowledge was sourced from a curated NotebookLM notebook containing {{industry_name}} best practices, documentation, and implementation guides.

---

## Source Notebook

{{#if sources}}
**Notebook ID**: `{{sources.notebook_id}}`
**Notebook URL**: {{sources.notebook_url}}
**Extraction Date**: {{sources.extraction_date}}

### Accessing the Notebook

You can query the source notebook directly using NotebookLM MCP tools:

```
Query the notebook for deep research on {{industry_name}} topics:
- notebook_id: {{sources.notebook_id}}
- Example query: "How do I implement {{use_cases.[0].title}}?"
```

---

## Extracted Knowledge

The skill builder extracted the following knowledge areas from the notebook:

### 1. Data Models ({{data_models.length}} objects)

{{#each data_models}}
- **{{object}}**: {{description}}
{{/each}}

### 2. Regulatory Frameworks ({{regulatory_frameworks.length}} regulations)

{{#each regulatory_frameworks}}
- **{{name}}**: {{description}}
{{/each}}

### 3. External Integrations ({{key_integrations.length}} systems)

{{#each key_integrations}}
- **{{name}}** ({{protocol}}): {{use_case}}
{{/each}}

### 4. Competency Areas ({{unique_competencies.length}} areas)

{{#each unique_competencies}}
- **{{area}}** ({{expertise_level}}): {{capabilities.length}} capabilities
{{/each}}

### 5. Use Cases ({{use_cases.length}} scenarios)

{{#each use_cases}}
- **{{title}}**: {{description}}
{{/each}}

---

## Extraction Process

The skill builder used structured prompts to query NotebookLM and extract knowledge:

### Query 1: Data Models
**Prompt**: Extract Salesforce object API names, descriptions, key fields, and relationships
**Result**: {{data_models.length}} objects identified

### Query 2: Regulatory Frameworks
**Prompt**: Identify compliance requirements and regulations
**Result**: {{regulatory_frameworks.length}} regulations identified

### Query 3: External Integrations
**Prompt**: List external system integration patterns
**Result**: {{key_integrations.length}} integrations identified

### Query 4: Competency Areas
**Prompt**: Identify required skill areas and expertise levels
**Result**: {{unique_competencies.length}} competency areas identified

### Query 5: Use Cases
**Prompt**: Extract common implementation scenarios
**Result**: {{use_cases.length}} use cases identified

---

## Source Materials

The NotebookLM notebook likely contains materials such as:

- **Salesforce Documentation**: Official {{industry_name}} implementation guides
- **Architecture Guides**: Industry-specific architecture patterns
- **Compliance Documentation**: Regulatory requirements and best practices
- **Integration Guides**: External system integration patterns
- **Use Case Examples**: Real-world implementation scenarios
- **Training Materials**: Videos, tutorials, and learning paths

*Note: Specific sources depend on what was uploaded to the NotebookLM notebook.*

---

## Updating This Skill

To update this skill with new knowledge:

### Option 1: Add Sources to Existing Notebook

1. Navigate to the source notebook: {{sources.notebook_url}}
2. Add new sources (PDFs, web pages, Google Docs, etc.)
3. Re-run the skill builder:
   ```bash
   cd .cursor/skills/_templates
   node builder.js --notebook {{sources.notebook_id}} --skill-name {{skill_name}} --industry "{{industry_name}}"
   ```

### Option 2: Create New Notebook

1. Create a new NotebookLM notebook with updated sources
2. Get the new notebook ID from the URL
3. Run the skill builder with the new notebook ID:
   ```bash
   cd .cursor/skills/_templates
   node builder.js --notebook <new-notebook-id> --skill-name {{skill_name}} --industry "{{industry_name}}"
   ```

### Option 3: Manual JSON Update

1. Edit the industry JSON definition: `.cursor/skills/_templates/industries/{{skill_name}}.json`
2. Re-run the skill builder:
   ```bash
   cd .cursor/skills/_templates
   node builder.js --json ./industries/{{skill_name}}.json
   ```

---

## Quality Assurance

The extracted knowledge was validated against:

- **JSON Schema**: All data conforms to `industry-skill-schema.json`
- **Completeness**: Minimum thresholds met (1+ data model, 1+ competency, 1+ use case)
- **Format Consistency**: All fields properly structured
- **Routing Indicators**: At least 3 keywords for Astro routing

**Validation Date**: {{sources.extraction_date}}

---

## Querying the Source Notebook

You can query the source notebook directly for deeper research:

### Example Queries

**Use Case Research**:
```
Query: "How do I implement {{use_cases.[0].title}} in {{industry_name}}?"
Notebook ID: {{sources.notebook_id}}
```

**Compliance Deep-Dive**:
```
Query: "What are the detailed {{regulatory_frameworks.[0].name}} requirements for Salesforce implementations?"
Notebook ID: {{sources.notebook_id}}
```

**Integration Patterns**:
```
Query: "Show me examples of {{key_integrations.[0].name}} integration with Salesforce"
Notebook ID: {{sources.notebook_id}}
```

**Data Model Relationships**:
```
Query: "Explain the relationship between {{data_models.[0].object}} and related objects"
Notebook ID: {{sources.notebook_id}}
```

### Using NotebookLM MCP

```javascript
// Example: Query notebook via MCP
const response = await mcp.notebooklm.notebook_query({
    notebook_id: "{{sources.notebook_id}}",
    query: "Your question here"
});
console.log(response.answer);
```

---

## Version History

**Current Version**:
- Generated: {{sources.extraction_date}}
- Notebook: {{sources.notebook_id}}
- Method: NotebookLM Extraction

**Previous Versions**:
- (Track updates here when skill is regenerated)

---

## Attribution

This skill was automatically generated using the **Industry-Specific Skill Builder System**.

**Builder Location**: `.cursor/skills/_templates/`
**Builder Command**: `node builder.js --notebook {{sources.notebook_id}} --skill-name {{skill_name}} --industry "{{industry_name}}"`

**Source Knowledge**: User-curated NotebookLM notebook
**Builder System**: Automated extraction and template generation
**Quality Assurance**: JSON schema validation + content quality checks

{{else}}
## Manual Curation

This skill was manually curated (no NotebookLM extraction). Knowledge sources:
- Salesforce official documentation
- Industry best practices
- Community contributions
- Internal architecture guides

To convert this skill to use NotebookLM extraction:

1. Create a NotebookLM notebook with {{industry_name}} sources
2. Get the notebook ID
3. Run the skill builder:
   ```bash
   cd .cursor/skills/_templates
   node builder.js --notebook <notebook-id> --skill-name {{skill_name}} --industry "{{industry_name}}"
   ```

{{/if}}

---

## Support

For questions about the source materials or extraction process:

1. **Review the source notebook**: {{#if sources}}{{sources.notebook_url}}{{else}}(No source notebook){{/if}}
2. **Check reference files**: `./references/` directory
3. **Query NotebookLM**: Use MCP tools for deep research
4. **Update sources**: Add new materials and regenerate skill

---

## License & Usage

The knowledge in this skill is derived from publicly available Salesforce documentation and industry best practices. Use in accordance with Salesforce terms of service and applicable regulations.

{{#if regulatory_frameworks}}
**Compliance Note**: Always validate {{#each regulatory_frameworks}}{{name}}{{#unless @last}}, {{/unless}}{{/each}} requirements with legal counsel before production deployment.
{{/if}}
