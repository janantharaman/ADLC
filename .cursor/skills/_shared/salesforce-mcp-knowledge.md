# Salesforce MCP Knowledge Integration Pattern

**Purpose**: Shared pattern for querying Salesforce MCP from any Cursor Skill. This enables real-time org metadata validation and live schema checking.

**For**: All Skills (Apex Developer, Solution Architect, LWC Developer, Astro, QA Engineer)

**Status**: Phase 3a - Metadata & Schema Validation (Read-Only)

---

## What is Salesforce MCP?

The Salesforce MCP Server (`@salesforce/mcp`) provides real-time access to your authenticated Salesforce org for:
- **Metadata Discovery**: Objects, fields, relationships, picklist values
- **SOQL Validation**: Check queries against actual schema
- **Org Limits**: Governor limits, API quotas, storage usage
- **Live Validation**: Verify assumptions before code generation

**Key Difference from NotebookLM**:
- NotebookLM: Static Well-Architected patterns, best practices
- Salesforce MCP: Live org data, your specific configuration

---

## Available MCP Tools (Phase 3a)

### Metadata & Schema Tools

#### describe_object
Get complete object schema including fields, relationships, record types.

```javascript
mcp__salesforce__describe_object({
  object_name: "Account"
})
```

**Returns**: Object metadata with:
- All fields (standard + custom)
- Field types, lengths, required status
- Relationships (lookups, master-detail)
- Record types
- Validation rules

**When to Use**:
- Validating objects exist before design
- Getting field lists for SOQL generation
- Checking field types for data handling
- Discovering relationships for integration

---

#### list_objects
List all objects available in the org.

```javascript
mcp__salesforce__list_objects({
  custom_only: false  // false = all objects, true = custom only
})
```

**Returns**: Array of object names

**When to Use**:
- Discovery phase (what's in this org?)
- Validating custom object names
- Finding objects for integration

---

#### get_field_details
Get detailed information about a specific field.

```javascript
mcp__salesforce__get_field_details({
  object_name: "Account",
  field_name: "Industry"
})
```

**Returns**: Field metadata with:
- Type (picklist, text, number, etc.)
- Length/precision
- Required status
- Picklist values (if applicable)
- Relationship details (if lookup/master-detail)

**When to Use**:
- Validating field exists before SOQL
- Getting picklist values for forms
- Checking field constraints for validation

---

#### get_picklist_values
Get all values for a picklist field.

```javascript
mcp__salesforce__get_picklist_values({
  object_name: "Account",
  field_name: "Industry"
})
```

**Returns**: Array of picklist values with labels

**When to Use**:
- Generating combobox options in LWC
- Validating picklist values in Apex
- Creating test data with valid values

---

### SOQL Validation Tools

#### validate_soql
Check SOQL query syntax against org schema.

```javascript
mcp__salesforce__validate_soql({
  query: "SELECT Id, Name, Custom_Field__c FROM Account WHERE Industry = 'Technology'"
})
```

**Returns**: Validation result with:
- `valid`: true/false
- `errors`: Array of validation errors (if any)
- `warnings`: Performance warnings (missing indexes, etc.)

**When to Use**:
- Before generating SOQL in Apex code
- Validating field names exist
- Checking query performance

---

### Org Information Tools

#### get_org_limits
Get current governor limits and usage.

```javascript
mcp__salesforce__get_org_limits()
```

**Returns**: Limits with usage:
- DailyAPIRequests (used/max)
- DataStorageMB (used/max)
- FileStorageMB (used/max)
- ConcurrentAsyncGetReportInstances (used/max)
- And many more...

**When to Use**:
- Checking API quota before integration design
- Validating storage capacity for data loads
- Assessing org capacity during architecture

---

#### get_org_info
Get authenticated org details.

```javascript
mcp__salesforce__get_org_info()
```

**Returns**: Org information:
- Org ID
- Org Name
- Instance URL
- Org Type (Sandbox, Production, Developer)
- Salesforce version

**When to Use**:
- Confirming which org you're connected to
- Checking org type for deployment decisions
- Displaying org context to user

---

## Integration Pattern

### Try MCP First → Fallback to Built-In Knowledge

All skills should follow this pattern for graceful degradation:

```markdown
## In Your Skill

When [performing task]:
1. **Try**: Query Salesforce MCP for live data
   Success: Use actual org metadata
   Failure: Fallback to built-in knowledge + warn user

2. **Apply**: Use validated data in solution
3. **Document**: Note whether validated against org

Example Code Flow:
```javascript
// Try MCP
try {
  const objectMeta = await queryMCP('describe_object', { object_name: 'Account' });
  // Use actual fields from org
  generateSOQL(objectMeta.fields);
} catch (error) {
  // Fallback to standard fields
  console.warn('⚠️ MCP unavailable. Using standard fields. Verify custom fields manually.');
  generateSOQL(STANDARD_ACCOUNT_FIELDS);
}
```
```

---

## When to Query MCP vs. Built-In Knowledge

### Query Salesforce MCP When:
- ✅ Need **CURRENT** org metadata (fields, objects, record types)
- ✅ Validating SOQL queries against live schema
- ✅ Checking governor limits and capacity
- ✅ Getting picklist values for UI components
- ✅ Verifying objects/fields exist before code generation
- ✅ Discovering custom objects and relationships

### Use Built-In Skill Knowledge When:
- ✅ Standard Salesforce APIs (documented behavior)
- ✅ Best practices (naming conventions, security patterns)
- ✅ Language syntax (Apex, SOQL, JavaScript)
- ✅ Well-Architected patterns (query NotebookLM)
- ✅ Governor limit thresholds (static limits)
- ✅ Platform features (documentation)

### Query NotebookLM When:
- ✅ Well-Architected patterns and principles
- ✅ Accessibility requirements
- ✅ Security patterns and anti-patterns
- ✅ Testing standards

**Three-Tier Knowledge Strategy**:
1. **NotebookLM**: Well-Architected patterns (static, curated)
2. **Salesforce MCP**: Live org metadata (dynamic, your org)
3. **Built-In Knowledge**: Platform fundamentals (static, universal)

---

## Integration Examples by Skill

### Astro (Orchestrator)
**When**: Analyzing requirements, planning implementation
**Queries**:
- `list_objects`: Discovery phase (what's in this org?)
- `describe_object`: Validate mentioned objects exist
- `get_org_limits`: Check capacity for solution

**Integration**:
```markdown
## In astro/SKILL.md - Step 1: Analyze Request

BEFORE creating plan:
1. Parse user request
2. Extract mentioned objects/features
3. Query Salesforce MCP for discovery:
   - Do mentioned objects exist?
   - What fields are available?
   - Any capacity concerns?
4. Ask clarifying questions WITH context from MCP

Example:
User: "Build approval workflow for Orders"
→ Query: describe_object("Order__c")
→ Result: Order__c exists with Status__c, Amount__c fields
→ Ask: "Should approval trigger when Status__c = 'Pending'?"

Fallback (no MCP):
→ Assume standard objects
→ Warn: "⚠️ Verify Order__c exists in your org"
```

---

### Solution Architect
**When**: Designing solutions, making architectural decisions
**Queries**:
- `describe_object`: Validate data model design
- `get_org_limits`: Check scalability constraints
- `list_objects`: Discover existing custom objects

**Integration**:
```markdown
## In solution-architect/SKILL.md - Dynamic Knowledge Integration

Step 1: Query NotebookLM for Well-Architected patterns (current)

Step 2: NEW - Query Salesforce MCP for org validation
When designing data models:
→ Query: describe_object(proposed_object)
→ Check: Does object already exist?
→ If exists: Get fields to avoid duplication
→ If not: Proceed with design

When designing integrations:
→ Query: get_org_limits()
→ Check: DailyAPIRequests capacity
→ Design: Bulk API if near limits, REST API if plenty

Step 3: Fallback to Built-In Knowledge (if MCP unavailable)
→ Use standard objects
→ Warn: "⚠️ Not validated against your org. Verify manually."

Step 4: Apply Well-Architected Framework
```

---

### Apex Developer
**When**: Writing triggers, classes, SOQL queries
**Queries**:
- `describe_object`: Get field list for SOQL
- `get_field_details`: Check field types
- `validate_soql`: Validate query syntax

**Integration**:
```markdown
## In apex-developer/SKILL.md - SOQL Generation

BEFORE generating SOQL:
1. Query: describe_object(target_object)
2. Validate: Do mentioned fields exist?
3. Generate: SOQL with validated fields
4. Validate: validate_soql(generated_query)

Example:
User: "Query Accounts with Discount_Percent__c > 20"

With MCP:
→ Query: describe_object("Account")
→ Check: Account.Discount_Percent__c exists? YES (Type: Percent)
→ Generate:
  SELECT Id, Name, Discount_Percent__c
  FROM Account
  WHERE Discount_Percent__c > 0.20
→ Validate: validate_soql(query)
→ Result: ✓ Valid, no warnings

Without MCP:
→ Generate query with assumption
→ Warn: "⚠️ Verify Discount_Percent__c exists in your org"

## Trigger Development

BEFORE creating trigger:
1. Query: list_triggers(object_name)
2. Check: Does trigger already exist?
3. If exists: Suggest modifying existing vs creating new
4. Fallback: Assume no conflicts + warn
```

---

### LWC Developer
**When**: Building Lightning Web Components, forms, UI
**Queries**:
- `get_picklist_values`: Get dropdown options
- `describe_object`: Get field types for form validation
- `get_field_details`: Check field requirements

**Integration**:
```markdown
## In lwc-developer/SKILL.md - Form Creation

BEFORE generating combobox/picklist:
1. Query: get_picklist_values(object, field)
2. Generate: Component with actual values
3. Fallback: Use @wire(getPicklistValues) for dynamic retrieval

Example:
User: "Create form with Industry picklist"

With MCP:
→ Query: get_picklist_values("Account", "Industry")
→ Result: ["Technology", "Healthcare", "Finance", ...]
→ Generate:
  get industryOptions() {
    return [
      {label: 'Technology', value: 'Technology'},
      {label: 'Healthcare', value: 'Healthcare'},
      {label: 'Finance', value: 'Finance'}
    ];
  }

Without MCP:
→ Generate dynamic retrieval:
  @wire(getPicklistValues, {
    recordTypeId: '$objectInfo.defaultRecordTypeId',
    fieldApiName: INDUSTRY_FIELD
  })
  industryPicklist;

## Wire Adapter Validation

BEFORE generating @wire(getRecord):
1. Query: describe_object(object_name)
2. Validate: Do requested fields exist?
3. Generate: @wire with validated fields
4. Fallback: Use standard fields + warn
```

---

### QA Engineer
**When**: Creating test plans, validating coverage
**Queries**:
- `describe_object`: Get required fields for test data
- `get_picklist_values`: Get valid values for tests
- `get_org_limits`: Understand test data volume constraints

**Integration**:
```markdown
## In qa-engineer/SKILL.md - Test Data Generation

BEFORE creating test data:
1. Query: describe_object(target_object)
2. Identify: Required fields, field types
3. Generate: Test data with valid values
4. For picklists: Query get_picklist_values()

Example:
User: "Create test data for Account"

With MCP:
→ Query: describe_object("Account")
→ Identify: Name (required), Industry (picklist), Custom_Field__c (text)
→ Query: get_picklist_values("Account", "Industry")
→ Generate:
  Account acc = new Account(
    Name = 'Test Account',
    Industry = 'Technology',  // Valid picklist value
    Custom_Field__c = 'Test Value'
  );

Without MCP:
→ Use standard required fields only
→ Warn: "⚠️ Verify custom fields and picklist values in your org"
```

---

## Best Practices

### Query Design
✅ **DO**:
- Query MCP early (discovery/planning phase)
- Cache results within skill execution
- Use specific object/field names
- Handle failures gracefully (fallback pattern)
- Inform user which org was validated against

❌ **DON'T**:
- Query repeatedly for same object metadata
- Assume MCP is always available
- Skip fallback implementation
- Query for basic Salesforce documentation

### Error Handling
✅ **DO**:
```markdown
try {
  const metadata = await queryMCP('describe_object', { object_name });
  // Use live data
  return generateWithMetadata(metadata);
} catch (error) {
  console.warn(`⚠️ Salesforce MCP unavailable: ${error.message}`);
  console.warn('Using built-in knowledge. Verify against your org manually.');
  // Fallback to standard knowledge
  return generateWithDefaults();
}
```

❌ **DON'T**:
```markdown
// No fallback - breaks if MCP unavailable
const metadata = await queryMCP('describe_object', { object_name });
return generateWithMetadata(metadata);
```

### User Communication
✅ **DO**:
- "✓ Validated against your org: MySandbox"
- "⚠️ Salesforce MCP unavailable. Using standard fields. Verify custom fields manually."
- "Found existing trigger: AccountTrigger. Modify existing or create new?"

❌ **DON'T**:
- Silently fail and use assumptions
- Generate invalid code without warnings
- Provide validation status without specifying which org

---

## Setup Requirements

### Prerequisites
Users must complete setup before MCP is available:

1. **Install Salesforce CLI**:
   ```bash
   sf --version  # Verify v2.x or higher
   ```

2. **Authenticate Org** (one-time):
   ```bash
   sf org login web --set-default --alias MySandbox
   ```

3. **Set Environment Variable** (recommended):
   ```bash
   echo 'export SALESFORCE_DEFAULT_ORG=MySandbox' >> ~/.zshrc
   source ~/.zshrc
   ```

4. **Restart Cursor** to load MCP configuration

### Verification
Users can verify setup:
```bash
# Check authenticated orgs
sf org list

# Test MCP connection
npx -y @salesforce/mcp --orgs MySandbox --toolsets orgs
```

### Troubleshooting
If MCP queries fail, check:
- Is org authenticated? `sf org list`
- Is environment variable set? `echo $SALESFORCE_DEFAULT_ORG`
- Did you restart Cursor after .mcp.json changes?

**For detailed setup**: See `.cursor/skills/_shared/salesforce-mcp-setup.md`

---

## Current Limitations (Phase 3a)

### Read-Only Mode
- ✅ Metadata queries (objects, fields, picklists)
- ✅ SOQL validation
- ✅ Org limits checking
- ❌ No code execution (Apex tests)
- ❌ No deployments
- ❌ No data modifications

**Why Read-Only?**
- Zero risk to org data
- No accidental deployments
- Focus on validation use case

### Future Phases (Not Yet Implemented)
- **Phase 3b**: Live code validation (static analysis, governor checks)
- **Phase 3c**: Sandbox testing (execute Apex tests)
- **Phase 3d**: Production deployment (with safeguards)

---

## Maintenance

### Keep This Pattern Updated
- ✅ Add new MCP tools as they become available
- ✅ Update query examples based on actual usage
- ✅ Document new integration patterns discovered
- ✅ Track which queries are most valuable

### Monitor Usage
- ✅ Which skills benefit most from MCP?
- ✅ Are fallbacks working correctly?
- ✅ Are users successfully setting up MCP?
- ✅ What additional MCP tools would be valuable?

---

## Resources

- **Salesforce MCP Server**: [@salesforce/mcp](https://github.com/salesforce/mcp)
- **Salesforce CLI**: [Salesforce CLI Documentation](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
- **MCP Configuration**: `.mcp.json` in project root
- **Setup Guide**: `.cursor/skills/_shared/salesforce-mcp-setup.md`
- **NotebookLM Pattern**: `.cursor/skills/_shared/notebooklm-knowledge.md` (complementary knowledge source)

---

**Version**: 1.0 (Phase 3a)
**Last Updated**: 2026-03-01
**Maintained By**: Salesforce Development Expert System

**Note**: This is Phase 3a implementation (Read-Only Metadata Validation). The pattern will evolve as additional phases are implemented.
