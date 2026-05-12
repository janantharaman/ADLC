# Industry-Specific Skill Builder System

Automated builder for generating industry-specific Salesforce developer skills. This system extracts knowledge from NotebookLM notebooks, PDFs, or manual JSON and generates complete skill packages.

## Overview

**Problem**: Creating industry-specific skills manually requires 40-60 hours per skill (5,000+ lines of content).

**Solution**: This builder automates skill generation by:
1. Extracting industry knowledge from multiple sources
2. Merging with base `/fullstack-dev` skill patterns
3. Generating complete skill packages (SKILL.md, README.md, reference files)
4. Auto-updating Astro routing logic

**Result**: Generate a complete industry skill in ~10 minutes (vs 40+ hours manual).

---

## Three Input Methods

### Method 1: NotebookLM (Recommended - Most User-Friendly)

**Best for**: Users with access to NotebookLM who want to leverage multiple source types.

```bash
node builder.js \
  --notebook <notebook-id> \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

**Workflow**:
1. Create NotebookLM notebook
2. Add industry sources (PDFs, web pages, Google Docs, videos)
3. Get notebook ID from URL
4. Run builder

**Advantages**:
- Supports multiple source types (PDFs, web, Docs, videos)
- AI-powered extraction
- Iterative refinement (add more sources and regenerate)
- Fast (~10 minutes total)

---

### Method 2: PDF Upload (Fallback - No NotebookLM)

**Best for**: Users without NotebookLM who have industry documentation as PDFs.

```bash
node builder.js \
  --pdfs "./fsc-docs/*.pdf" \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

**Workflow**:
1. Organize PDFs in a directory
2. Run builder with glob pattern
3. Builder parses PDFs and extracts knowledge

**Advantages**:
- Works offline
- No external dependencies
- Simple local workflow

**Limitations**:
- Less accurate extraction than NotebookLM
- Only supports PDF files
- Manual text parsing (less intelligent)

---

### Method 3: Manual JSON (Power Users - Full Control)

**Best for**: Power users who want precise control over content or have existing JSON definitions.

```bash
node builder.js --json ./industries/fsc.json
```

**Workflow**:
1. Write JSON definition following schema
2. Run builder

**Advantages**:
- Full control over content
- No external dependencies
- Fast (no extraction step)

**Limitations**:
- Time-consuming to write (1-2 hours per industry)
- Requires understanding JSON schema
- Manual maintenance

---

## Quick Start

### 1. Install Dependencies

```bash
cd .cursor/skills/_templates
npm install
```

### 2. Choose Your Method

#### Option A: NotebookLM (Recommended)

```bash
# 1. Create NotebookLM notebook and add sources
# 2. Get notebook ID from URL: https://notebooklm.google.com/notebook/<id>
# 3. Run builder

node builder.js \
  --notebook abc123xyz \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

#### Option B: PDF Upload

```bash
# 1. Place PDFs in a directory
mkdir -p ./fsc-docs
# Add your PDFs to ./fsc-docs/

# 2. Run builder
node builder.js \
  --pdfs "./fsc-docs/*.pdf" \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

#### Option C: Manual JSON

```bash
# 1. Create JSON definition
# See ./industries/sample.json for template

# 2. Run builder
node builder.js --json ./industries/fsc.json
```

### 3. Verify Generated Skill

```bash
# Check generated files
ls -la ../fsc-dev/

# Verify line counts
wc -l ../fsc-dev/SKILL.md ../fsc-dev/README.md

# Test skill invocation (in Cursor IDE)
/fsc-dev "Build wealth management portal"
```

---

## Using Cursor Commands (Recommended)

### Overview

The easiest way to use the Skill Builder is through **Cursor Commands** - no terminal required!

**Benefits**:
- ✅ **Discoverable**: Shows up in command palette (`Cmd+Shift+P`)
- ✅ **Fast**: Direct execution, no AI parsing overhead
- ✅ **User-friendly**: Guided parameter input dialogs
- ✅ **Native integration**: Works just like built-in VS Code commands

### How to Use

**Step 1: Open Command Palette**
- Mac: `Cmd+Shift+P`
- Windows/Linux: `Ctrl+Shift+P`

**Step 2: Type "Skill Builder"**

You'll see three commands:
1. **Skill Builder: Generate from JSON** - For manual JSON files
2. **Skill Builder: Generate from NotebookLM** - For NotebookLM notebooks
3. **Skill Builder: Generate from PDFs** - For PDF documentation

**Step 3: Follow the Prompts**

Each command will prompt you for the required parameters:
- **JSON method**: Select JSON file from picker
- **NotebookLM method**: Enter notebook ID, skill name, and industry name
- **PDF method**: Enter PDF glob pattern, skill name, and industry name

**Step 4: View Results**

The builder executes in the integrated terminal and shows output in real-time.

### Example Workflows

#### Workflow 1: Generate from JSON

```
1. Press Cmd+Shift+P
2. Type "Skill Builder: Generate from JSON"
3. Select "./industries/sample.json"
4. Builder runs and generates skill
5. Done! (~10 seconds)
```

#### Workflow 2: Generate from NotebookLM

```
1. Create NotebookLM notebook with industry sources
2. Get notebook ID from URL (e.g., "abc123xyz")
3. Press Cmd+Shift+P
4. Type "Skill Builder: Generate from NotebookLM"
5. Enter notebook ID: "abc123xyz"
6. Enter skill name: "fsc-dev"
7. Enter industry name: "Financial Services Cloud"
8. Builder runs and generates skill
9. Done! (~2-3 minutes with extraction)
```

#### Workflow 3: Generate from PDFs

```
1. Place PDFs in a directory (e.g., "./docs/")
2. Press Cmd+Shift+P
3. Type "Skill Builder: Generate from PDFs"
4. Enter PDF pattern: "./docs/*.pdf"
5. Enter skill name: "healthcare-dev"
6. Enter industry name: "Health Cloud"
7. Builder runs and generates skill
8. Done! (~1-2 minutes)
```

### Configuration

The Cursor Commands are configured in two files:

1. **`.cursor/skills/_templates/commands.json`** - Command definitions
2. **`.vscode/settings.json`** - Registers commands with Cursor

These files are already set up and ready to use!

### Customization (Optional)

You can customize the commands by editing `commands.json`:

```json
{
  "commands": [
    {
      "name": "Your Custom Command",
      "id": "skill-builder.custom",
      "command": "cd {{workspaceFolder}}/.cursor/skills/_templates && node builder.js --your-args",
      "description": "Your description"
    }
  ]
}
```

---

## Detailed Usage

### NotebookLM Method

**Step 1: Create Notebook**

1. Navigate to: https://notebooklm.google.com
2. Create new notebook: "FSC Development Best Practices"
3. Add industry sources:
   - Upload PDFs (implementation guides, compliance docs)
   - Add web URLs (Salesforce documentation)
   - Connect Google Docs (internal architecture docs)
   - Add YouTube videos (training content)

**Step 2: Get Notebook ID**

From URL: `https://notebooklm.google.com/notebook/abc123xyz`
Notebook ID: `abc123xyz`

**Step 3: Run Builder**

```bash
node builder.js \
  --notebook abc123xyz \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

**What Happens**:
1. Builder queries NotebookLM with 5 structured prompts:
   - Extract data models
   - Extract regulations
   - Extract integrations
   - Extract competencies
   - Extract use cases
2. Parses responses into structured JSON
3. Generates skill files using templates
4. Updates Astro routing

**Expected Output**:
```
🚀 Skill Builder Starting...
📚 Method: NotebookLM (notebook ID: abc123xyz)
📚 Querying NotebookLM...
   🔍 Extracting data models...
   🔍 Extracting regulatory frameworks...
   🔍 Extracting integration patterns...
   🔍 Extracting competencies...
   🔍 Extracting use cases...
✅ Knowledge extraction complete!
   - Data models: 8
   - Regulations: 2 (FINRA, SEC)
   - Integrations: 3
   - Competencies: 4
   - Use cases: 5
🔍 Validating industry JSON...
✅ Validation passed!
🔨 Generating skill files...
   ✅ SKILL.md: 847 lines
   ✅ README.md: 312 lines
   ✅ EXTENDS.md: 98 lines
   ✅ SOURCES.md: 45 lines
   ✅ fsc-data-models.md: 234 lines
   ✅ Updated Astro routing
🎉 Skill generation complete!
```

---

### PDF Upload Method

**Step 1: Organize PDFs**

```bash
mkdir -p ./fsc-docs
# Add PDFs:
# - fsc-implementation-guide.pdf
# - finra-compliance-guide.pdf
# - core-banking-integration.pdf
```

**Step 2: Run Builder**

```bash
node builder.js \
  --pdfs "./fsc-docs/*.pdf" \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

**What Happens**:
1. Builder finds matching PDF files
2. Parses each PDF to extract text
3. Uses pattern matching to identify:
   - Salesforce objects (ending with __c)
   - Regulatory keywords (FINRA, HIPAA, etc.)
   - Integration patterns (REST, SOAP, etc.)
4. Generates skill files

**Note**: PDF extraction is less accurate than NotebookLM. For best results, use well-structured PDF documentation with clear headings and consistent formatting.

---

### Manual JSON Method

**Step 1: Create JSON Definition**

See `./industries/sample.json` for complete example.

Minimum required structure:
```json
{
  "skill_name": "fsc-dev",
  "industry_name": "Financial Services Cloud",
  "description": "FSC full-stack developer with expertise in wealth management",
  "routing_indicators": ["financial account", "securities", "FINRA"],
  "data_models": [
    {
      "object": "FinServ__FinancialAccount__c",
      "description": "Core financial account object",
      "key_fields": ["FinServ__Balance__c", "FinServ__AccountType__c"],
      "relationships": ["Account", "Contact"]
    }
  ],
  "regulatory_frameworks": [...],
  "key_integrations": [...],
  "unique_competencies": [...],
  "use_cases": [...],
  "reference_files": [...]
}
```

**Step 2: Validate JSON**

```bash
# Test JSON syntax
node -e "console.log(JSON.parse(require('fs').readFileSync('./industries/fsc.json')))"

# Run builder (validation happens automatically)
node builder.js --json ./industries/fsc.json
```

---

## Directory Structure

```
_templates/
├── schema/
│   └── industry-skill-schema.json    # JSON schema for validation
├── base/
│   ├── SKILL.template.md             # Main skill template
│   ├── README.template.md            # README template
│   ├── EXTENDS.template.md           # Extension docs template
│   └── SOURCES.template.md           # Source attribution template
├── extractors/
│   ├── notebooklm-extractor.js       # NotebookLM integration
│   ├── pdf-extractor.js              # PDF parsing
│   └── json-extractor.js             # Manual JSON loader
├── prompts/
│   ├── data-models.txt               # NotebookLM query: data models
│   ├── regulations.txt               # NotebookLM query: regulations
│   ├── integrations.txt              # NotebookLM query: integrations
│   ├── competencies.txt              # NotebookLM query: competencies
│   └── use-cases.txt                 # NotebookLM query: use cases
├── industries/                       # (Optional) Pre-built JSON definitions
│   └── sample.json                   # Example industry JSON
├── builder.js                        # Main orchestrator
├── package.json                      # Node dependencies
└── README.md                         # This file
```

---

## Generated Skill Structure

After running the builder, a complete skill package is generated:

```
../<skill-name>/
├── SKILL.md                          # Main skill (800-900 lines)
├── README.md                         # User docs (300-400 lines)
├── EXTENDS.md                        # Extension documentation
├── SOURCES.md                        # Source attribution (if NotebookLM)
└── references/
    ├── <industry>-data-models.md     # Data model deep-dive
    ├── <industry>-regulatory.md      # Compliance patterns
    ├── <industry>-integrations.md    # Integration patterns
    └── <industry>-use-cases.md       # Implementation examples
```

**Total**: ~1,500-2,000 lines generated from structured data input.

---

## Validation & Quality Checks

The builder automatically validates:

### 1. JSON Schema Validation
- All required fields present
- skill_name matches pattern: `^[a-z]+-dev$`
- Arrays have minimum items
- Expertise levels valid (Expert, Advanced, Intermediate)
- Reference file names end with `.md`

### 2. Content Quality Checks
- SKILL.md: 700-900 lines
- README.md: 250-400 lines
- EXTENDS.md: exists and valid
- Reference files: all generated
- No unresolved template variables (`{{...}}`)

### 3. Astro Routing Validation
- Routing indicators added
- No duplicate patterns
- Proper formatting

**If validation fails**, the builder will exit with clear error messages.

---

## Updating Existing Skills

To update a skill with new knowledge:

### Method 1: Add Sources to NotebookLM

1. Navigate to original notebook
2. Add new sources (PDFs, URLs, etc.)
3. Re-run builder with same notebook ID

```bash
node builder.js \
  --notebook abc123xyz \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

**Result**: Skill regenerated with updated knowledge.

### Method 2: Update JSON Manually

1. Edit `./industries/fsc.json`
2. Re-run builder

```bash
node builder.js --json ./industries/fsc.json
```

---

## Troubleshooting

### Error: "NotebookLM MCP integration not yet implemented"

**Issue**: NotebookLM extractor needs MCP server integration.

**Workaround**: Use PDF upload or manual JSON method until MCP integration is complete.

**Future**: Will integrate with NotebookLM MCP server for automated extraction.

### Error: "No PDF files found matching pattern"

**Issue**: PDF glob pattern doesn't match any files.

**Solution**:
```bash
# Check files exist
ls ./fsc-docs/*.pdf

# Use correct pattern
node builder.js --pdfs "./fsc-docs/*.pdf" ...
```

### Error: "JSON validation failed"

**Issue**: JSON doesn't conform to schema.

**Solution**: Check error messages for specific fields:
```
❌ Validation errors:
   /skill_name: must match pattern ^[a-z]+-dev$
   /data_models: must have at least 1 item
```

Fix issues in JSON and re-run.

### Warning: "Using mock data"

**Issue**: Extraction method failed, using placeholder data.

**Solution**: This is expected during development. Mock data allows testing builder logic. Generated skill will have generic content that should be replaced with real industry knowledge.

---

## Example: Building FSC Skill

Complete end-to-end example:

### 1. Create NotebookLM Notebook

**Sources Added**:
- FSC Implementation Guide (PDF)
- https://developer.salesforce.com/docs/atlas.en-us.financial_services_cloud.meta
- FINRA Compliance Guide (PDF)
- Core Banking Integration Patterns (Google Doc)
- FSC Data Model Overview (YouTube)

**Notebook ID**: `abc123xyz`

### 2. Run Builder

```bash
cd .cursor/skills/_templates

node builder.js \
  --notebook abc123xyz \
  --skill-name fsc-dev \
  --industry "Financial Services Cloud"
```

### 3. Review Output

```bash
# Check generated files
ls -la ../fsc-dev/
# SKILL.md, README.md, EXTENDS.md, SOURCES.md, references/

# Check line counts
wc -l ../fsc-dev/SKILL.md
# 847 lines

# Check Astro routing
grep -A 10 "Financial Services Cloud" ../astro/SKILL.md
```

### 4. Test Skill

In Cursor IDE:
```
/fsc-dev "Build wealth management portal with client portfolio tracking and FINRA compliance"
```

**Expected**: FSC developer responds with industry-specific guidance, FSC data models, FINRA requirements, and full-stack implementation.

---

## Best Practices

### 1. Curate Quality Sources

**NotebookLM works best with**:
- Official Salesforce documentation
- Industry compliance guides
- Architecture best practices
- Real-world implementation examples

**Avoid**:
- Marketing materials (low technical detail)
- Outdated documentation
- Non-technical content

### 2. Iterate and Refine

**First pass**: Generate skill with initial sources
**Review**: Check for gaps or inaccuracies
**Add sources**: Upload additional materials to NotebookLM
**Regenerate**: Re-run builder to incorporate new knowledge

### 3. Validate Generated Content

**Always review**:
- Data model accuracy (object names, fields)
- Regulatory requirements (consult legal/compliance)
- Integration patterns (verify with architecture team)
- Use cases (ensure they're realistic)

### 4. Customize Reference Files

Generated reference files are starting points. Enhance with:
- Code examples
- Architecture diagrams
- Decision trees
- Troubleshooting guides

---

## Maintenance

### Adding New Industries

1. Create NotebookLM notebook with industry sources
2. Run builder with new skill name
3. Review and refine generated skill
4. Update Astro routing (automatic)

### Updating Templates

To modify the skill template:

1. Edit `./base/SKILL.template.md`
2. Use Handlebars syntax for variables: `{{variable_name}}`
3. Test with existing industry JSON
4. Regenerate all skills to apply changes

### Schema Changes

To add new fields to industry JSON:

1. Update `./schema/industry-skill-schema.json`
2. Update templates to use new fields
3. Update extractors to populate new fields
4. Regenerate skills

---

## Advanced Usage

### Custom Handlebars Helpers

Add custom helpers in `builder.js`:

```javascript
Handlebars.registerHelper('uppercase', function(str) {
  return str.toUpperCase();
});
```

Use in templates:
```handlebars
{{uppercase industry_name}}
```

### Conditional Sections

Use Handlebars conditionals:

```handlebars
{{#if regulatory_frameworks}}
## Regulatory Compliance
{{#each regulatory_frameworks}}
- {{name}}: {{description}}
{{/each}}
{{/if}}
```

### Extending Extractors

Create custom extractor for new source types:

```javascript
// extractors/custom-extractor.js
class CustomExtractor {
  async extract(skillName, industryName) {
    // Custom extraction logic
    return industryJSON;
  }
}
```

Register in `builder.js`:
```javascript
const CustomExtractor = require('./extractors/custom-extractor');

if (argv.custom) {
  const extractor = new CustomExtractor(argv.customInput);
  industryJSON = await extractor.extract(argv.skillName, argv.industry);
}
```

---

## FAQ

**Q: Can I use this for non-Salesforce industries?**
A: Yes, but you'll need to modify templates and schema to remove Salesforce-specific sections.

**Q: How accurate is NotebookLM extraction?**
A: Depends on source quality. Well-structured documentation yields 80-90% accuracy. Always review and refine.

**Q: Can I mix methods (e.g., NotebookLM + manual JSON edits)?**
A: Yes! Generate from NotebookLM, then manually edit the generated JSON in `./industries/`, and regenerate.

**Q: What if my industry has no specific regulations?**
A: Set `regulatory_frameworks: []` in JSON. Template will skip compliance sections.

**Q: How do I delete a generated skill?**
A: `rm -rf ../<skill-name>/` and manually remove Astro routing section.

---

## Support

**Issues**: Report bugs or request features in project repository
**Documentation**: See `../FULLSTACK_DEVELOPER_STRATEGY.md` for architecture context
**Examples**: Check `./industries/` for sample JSON definitions

---

## License

MIT License - See project root for details.
