# NotebookLM Knowledge Integration Pattern

**Purpose**: Shared pattern for querying NotebookLM from any Cursor Skill. This enables dynamic knowledge retrieval from curated Salesforce resources.

**For**: All Skills (Apex Developer, Solution Architect, LWC Developer, QA Engineer, etc.)

---

## Available NotebookLM Notebooks

### 1. Salesforce Well-Architected: Accessibility & Testing
**Notebook ID**: `03600af5-b421-4a6d-89d1-dcae0a482175`

**Contains**:
- ✅ Accessibility Data Entry Pattern (input devices, translations, testing)
- ✅ Accessibility Navigation Pattern (keyboard navigation, visual cues, ARIA)
- ✅ Testing requirements for accessibility compliance
- ✅ Anti-patterns to avoid

**When to Query**:
- Building forms or data entry interfaces
- Implementing navigation controls
- Writing accessibility tests
- Designing multilingual applications
- Implementing keyboard navigation

**Example Queries**:
```
"What are the accessibility requirements for data entry?"
"What are the navigation accessibility patterns?"
"What anti-patterns should I avoid for accessible navigation?"
"What testing is required for accessibility compliance?"
"How should translations be stored for accessibility?"
```

### 2. Consumer Goods Cloud
**Notebook ID**: `9ca50af3-1937-43a6-87c4-3d8629a1ccbd`

**Contains**:
- ✅ CG Cloud data models (RetailStore, Visit, ActionPlan, AssessmentTask, StoreProduct)
- ✅ Trade Promotion Management (TPM/TPO) patterns
- ✅ Retail execution workflows and best practices
- ✅ Route planning and visit optimization
- ✅ Inventory management and DSD patterns
- ✅ Industry integrations (ERP, DSD, planogram, distributor)
- ✅ Offline-first design patterns for field apps

**Dynamic**: Sources are continuously added to this notebook.

**When to Query**:
- Building retail execution workflows (visits, audits, action plans)
- Implementing trade promotion management features
- Working with CG Cloud data models and relationships
- Designing offline-first field rep mobile apps
- Integrating with ERP, DSD, or planogram systems
- Route planning and visit optimization

**Example Queries**:
```
"What are the key data model relationships in Consumer Goods Cloud?"
"How should trade promotion funds be managed and accrued?"
"What is the best practice for planogram compliance assessment?"
"How to integrate Consumer Goods Cloud with ERP for order sync?"
"What are the offline-first design patterns for field rep apps?"
"How does route optimization work in Consumer Goods Cloud?"
```

**Primary User**: `/cgc-dev` (Nisha, CG Cloud Developer)

### 3. Additional Notebooks (Add as Available)
As you add more notebooks to NotebookLM, document them here:

```
Notebook Name: [Name]
Notebook ID: [UUID]
Contains: [List key patterns/knowledge]
When to Query: [Scenarios]
Example Queries: [Sample questions]
```

---

## How to Query NotebookLM from Skills

### Pattern 1: Direct Query for Specific Knowledge

When you need specific information during task execution:

```markdown
## In Your Skill

When designing [specific feature]:
1. Query NotebookLM for relevant patterns
2. Apply patterns to current context
3. Generate code/design with patterns integrated

Example:
"User asks me to create an accessible form"
→ Query: "accessibility requirements for data entry"
→ Apply: Multi-device support, Translation Workbench, keyboard navigation
→ Generate: Code with accessibility built-in
```

### Pattern 2: Pre-Task Knowledge Gathering

Before starting complex tasks, gather relevant knowledge:

```markdown
## In Your Skill

For architectural decisions:
1. Identify decision domains (security, scalability, integration)
2. Query NotebookLM for patterns in each domain
3. Evaluate options against Well-Architected pillars
4. Document decision with pattern references
```

### Pattern 3: Validation Against Standards

After generating solutions, validate against standards:

```markdown
## In Your Skill

After generating code:
1. Query NotebookLM for relevant anti-patterns
2. Check if solution violates any anti-patterns
3. Refactor if issues found
4. Document compliance with patterns
```

---

## MCP Tool Reference

### Query a Notebook
```javascript
mcp__notebooklm__notebook_query({
  notebook_id: "03600af5-b421-4a6d-89d1-dcae0a482175",
  query: "What are the accessibility requirements for data entry?",
  source_ids: null  // Query all sources, or specify specific source IDs
})
```

**Returns**: AI-generated answer with citations from notebook sources

### Get Notebook Summary
```javascript
mcp__notebooklm__notebook_describe({
  notebook_id: "03600af5-b421-4a6d-89d1-dcae0a482175"
})
```

**Returns**: Summary of notebook contents and suggested topics

### Get Source Content
```javascript
mcp__notebooklm__source_get_content({
  source_id: "bb48e122-14a2-4baa-adfd-3c8cf0c671c3"
})
```

**Returns**: Raw text content from a specific source

---

## Integration Examples by Skill

### Apex Developer
**When**: Writing triggers, classes, or security logic
**Queries**:
- "Accessibility requirements for data entry"
- "Security patterns for session management"
- "Testing requirements for accessibility"

**Integration**:
```markdown
## In apex-developer/SKILL.md

When generating form handlers:
- Query NotebookLM for accessibility data entry patterns
- Ensure support for multiple input devices
- Include multi-language support via Translation Workbench
- Generate tests for keyboard navigation and screen readers
```

### Solution Architect
**When**: Designing solutions, making architectural decisions
**Queries**:
- "Well-Architected patterns for [domain]"
- "Scalability patterns for [use case]"
- "Security patterns for [scenario]"

**Integration**:
```markdown
## In solution-architect/SKILL.md

When designing architecture:
1. Query NotebookLM for relevant Well-Architected patterns
2. Evaluate options: TRUSTED, EASY, ADAPTABLE
3. Document pattern selections with NotebookLM references
4. Validate against anti-patterns from NotebookLM
```

### LWC Developer
**When**: Building Lightning Web Components
**Queries**:
- "Accessibility navigation patterns"
- "ARIA requirements for interactive elements"
- "Keyboard navigation standards"

**Integration**:
```markdown
## In lwc-developer/SKILL.md

When building LWC components:
- Query NotebookLM for navigation accessibility patterns
- Implement ARIA attributes per patterns
- Ensure keyboard navigation support
- Generate Jest tests for accessibility
```

### QA Engineer
**When**: Creating test plans, writing tests
**Queries**:
- "Accessibility testing requirements"
- "Test steps for multiple input devices"
- "Anti-patterns to test against"

**Integration**:
```markdown
## In qa-engineer/SKILL.md

When creating test plans:
- Query NotebookLM for accessibility test requirements
- Include tests for multiple input devices
- Include multi-language testing
- Verify UI/UX consistency tests included
```

---

## Best Practices

### Query Design
✅ **DO**:
- Ask specific, focused questions
- Reference the domain/feature context
- Request concrete patterns or anti-patterns
- Ask for implementation guidance

❌ **DON'T**:
- Ask overly broad questions ("Tell me about accessibility")
- Query without context
- Ignore citations/sources in responses

### Knowledge Application
✅ **DO**:
- Apply patterns within the task context
- Cite NotebookLM as knowledge source
- Validate solutions against anti-patterns
- Update skills as NotebookLM knowledge grows

❌ **DON'T**:
- Copy-paste without understanding
- Ignore Well-Architected framework balance
- Skip validation against anti-patterns
- Assume patterns are complete (always verify)

### Performance
✅ **DO**:
- Cache frequently queried information within skill execution
- Query once per task, not per code block
- Use specific notebook/source IDs when possible

❌ **DON'T**:
- Query repeatedly for same information
- Query for knowledge already in skill files
- Query for basic Salesforce documentation (use built-in knowledge first)

---

## When to Query vs When to Use Built-In Knowledge

### Query NotebookLM When:
- ✅ Need specific Well-Architected patterns
- ✅ Checking accessibility compliance requirements
- ✅ Validating against documented anti-patterns
- ✅ Getting official Salesforce architect guidance
- ✅ Need current compliance/testing standards

### Use Built-In Skill Knowledge When:
- ✅ Basic Salesforce platform features (governor limits, APIs)
- ✅ Common coding patterns (bulkification, trigger handlers)
- ✅ Standard best practices (naming conventions, security)
- ✅ Language syntax (Apex, JavaScript, SOQL)
- ✅ Tool usage (Salesforce CLI, VS Code)

---

## Extending This Pattern

### Adding New Notebooks

When you add notebooks to NotebookLM:

1. **Document the notebook** in "Available NotebookLM Notebooks" section above
2. **List its contents** (patterns, standards, guidance)
3. **Define when to query** (scenarios, use cases)
4. **Provide example queries** (3-5 sample questions)

### Adding to Existing Skills

To add NotebookLM to an existing skill:

1. **Identify knowledge gaps** in the skill
2. **Add reference** to this pattern file in skill's SKILL.md
3. **Document when to query** in skill's specific context
4. **Provide examples** of queries for that skill's domain
5. **Update skill's README** with NotebookLM capabilities

### Creating New Skills with NotebookLM

For new skills:

1. **Reference this pattern** in SKILL.md: "Use NotebookLM Knowledge Integration Pattern"
2. **List specific notebooks** relevant to the skill
3. **Define query triggers** (when should the skill query?)
4. **Provide domain-specific queries** (examples for that role)
5. **Include in workflow** (pre-task, during-task, validation)

---

## Maintenance

### Keep This Pattern Updated
- ✅ Add new notebooks as they're created
- ✅ Update query examples based on actual usage
- ✅ Document new integration patterns discovered
- ✅ Remove/archive deprecated notebooks

### Monitor Usage
- ✅ Track which queries are most valuable
- ✅ Identify gaps in NotebookLM content
- ✅ Refine query patterns for better results
- ✅ Share effective queries across skills

---

## Resources

- **NotebookLM Dashboard**: https://notebooklm.google.com
- **Your Notebooks**: Check current authenticated account
- **MCP Server**: `notebooklm` server (configured in .mcp.json)
- **Well-Architected**: https://architect.salesforce.com

---

**Version**: 1.0
**Last Updated**: 2026-02-28
**Maintained By**: Salesforce Development Expert System

**Note**: This pattern evolves as your NotebookLM knowledge base grows. Keep it current for maximum value across all skills.
