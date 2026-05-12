#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const Handlebars = require('handlebars');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const Ajv = require('ajv');

// Import extractors
const NotebookLMExtractor = require('./extractors/notebooklm-extractor');
const PDFExtractor = require('./extractors/pdf-extractor');
const JSONExtractor = require('./extractors/json-extractor');

// Register Handlebars helpers
Handlebars.registerHelper('gt', function(a, b) {
  return a > b;
});

Handlebars.registerHelper('camelCase', function(str) {
  return str.replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) => {
    return index === 0 ? letter.toLowerCase() : letter.toUpperCase();
  }).replace(/\s+/g, '');
});

Handlebars.registerHelper('kebabCase', function(str) {
  return str.toLowerCase().replace(/\s+/g, '-');
});

// Parse CLI arguments
const argv = yargs(hideBin(process.argv))
  .option('notebook', {
    type: 'string',
    description: 'NotebookLM notebook ID',
  })
  .option('pdfs', {
    type: 'string',
    description: 'Path to PDF files (glob pattern)',
  })
  .option('json', {
    type: 'string',
    description: 'Path to JSON definition file',
  })
  .option('skill-name', {
    type: 'string',
    description: 'Skill name (e.g., fsc-dev)',
  })
  .option('industry', {
    type: 'string',
    description: 'Industry name (e.g., Financial Services Cloud)',
  })
  .check((argv) => {
    // Ensure exactly one input method is specified
    const methods = [argv.notebook, argv.pdfs, argv.json].filter(Boolean);
    if (methods.length !== 1) {
      throw new Error('Specify exactly ONE input method: --notebook, --pdfs, or --json');
    }

    // For notebook and pdfs, require skill-name and industry
    if ((argv.notebook || argv.pdfs) && (!argv.skillName || !argv.industry)) {
      throw new Error('--skill-name and --industry are required for --notebook and --pdfs methods');
    }

    return true;
  })
  .help()
  .argv;

// Main function
async function main() {
  console.log('🚀 Skill Builder Starting...\n');
  console.log('═══════════════════════════════════════════════════════════════\n');

  let industryJSON;

  // Extract knowledge based on input method
  if (argv.notebook) {
    console.log(`📚 Method: NotebookLM`);
    console.log(`   Notebook ID: ${argv.notebook}`);
    console.log(`   Skill Name: ${argv.skillName}`);
    console.log(`   Industry: ${argv.industry}\n`);

    const extractor = new NotebookLMExtractor(argv.notebook);
    industryJSON = await extractor.extract(argv.skillName, argv.industry);
  } else if (argv.pdfs) {
    console.log(`📄 Method: PDF Upload`);
    console.log(`   PDF Pattern: ${argv.pdfs}`);
    console.log(`   Skill Name: ${argv.skillName}`);
    console.log(`   Industry: ${argv.industry}\n`);

    const extractor = new PDFExtractor(argv.pdfs);
    industryJSON = await extractor.extract(argv.skillName, argv.industry);
  } else if (argv.json) {
    console.log(`📝 Method: Manual JSON`);
    console.log(`   JSON File: ${argv.json}\n`);

    const extractor = new JSONExtractor(argv.json);
    industryJSON = await extractor.extract();
  }

  console.log('✅ Knowledge extraction complete!');
  console.log('───────────────────────────────────────────────────────────────');
  console.log(`   Data models: ${industryJSON.data_models.length}`);
  console.log(`   Regulations: ${industryJSON.regulatory_frameworks.length}`);
  console.log(`   Integrations: ${industryJSON.key_integrations.length}`);
  console.log(`   Competencies: ${industryJSON.unique_competencies.length}`);
  console.log(`   Use cases: ${industryJSON.use_cases.length}`);
  console.log('───────────────────────────────────────────────────────────────\n');

  // Validate JSON against schema
  console.log('🔍 Validating industry JSON...');
  validateIndustryJSON(industryJSON);
  console.log('✅ Validation passed!\n');

  // Generate skill
  console.log('🔨 Generating skill files...');
  console.log('───────────────────────────────────────────────────────────────');
  await generateSkill(industryJSON);

  console.log('───────────────────────────────────────────────────────────────');
  console.log('\n🎉 Skill generation complete!');
  console.log(`   📁 Skill location: .cursor/skills/${industryJSON.skill_name}/\n`);
  console.log('═══════════════════════════════════════════════════════════════\n');
  console.log('Next steps:');
  console.log(`   1. Review generated files in .cursor/skills/${industryJSON.skill_name}/`);
  console.log(`   2. Test skill invocation: /${industryJSON.skill_name} "your task"`);
  console.log(`   3. Verify Astro routing in .cursor/skills/astro/SKILL.md\n`);
}

// Generate skill from industry JSON
async function generateSkill(industry) {
  // Load templates
  const skillTemplate = Handlebars.compile(loadTemplate('SKILL.template.md'));
  const readmeTemplate = Handlebars.compile(loadTemplate('README.template.md'));
  const extendsTemplate = Handlebars.compile(loadTemplate('EXTENDS.template.md'));
  const sourcesTemplate = Handlebars.compile(loadTemplate('SOURCES.template.md'));

  // Prepare template data
  const templateData = {
    ...industry,
    data_model_summary: industry.data_models.map(dm => dm.object).join(', '),
    regulatory_summary: industry.regulatory_frameworks.map(rf => rf.name).join(', '),
    integration_summary: industry.key_integrations.map(ki => ki.name).join(', '),
    reference_file_prefix: industry.industry_name.toLowerCase()
      .replace(/\s+/g, '-')
      .replace(/[^a-z-]/g, '')
  };

  // Generate files
  const skillContent = skillTemplate(templateData);
  const readmeContent = readmeTemplate(templateData);
  const extendsContent = extendsTemplate(templateData);
  const sourcesContent = sourcesTemplate(templateData);

  // Create output directory
  const outputDir = path.join(__dirname, '..', industry.skill_name);
  fs.mkdirSync(outputDir, { recursive: true });
  fs.mkdirSync(path.join(outputDir, 'references'), { recursive: true });

  // Write files
  fs.writeFileSync(path.join(outputDir, 'SKILL.md'), skillContent);
  fs.writeFileSync(path.join(outputDir, 'README.md'), readmeContent);
  fs.writeFileSync(path.join(outputDir, 'EXTENDS.md'), extendsContent);
  if (industry.sources) {
    fs.writeFileSync(path.join(outputDir, 'SOURCES.md'), sourcesContent);
  }

  console.log(`   ✅ SKILL.md: ${skillContent.split('\n').length} lines`);
  console.log(`   ✅ README.md: ${readmeContent.split('\n').length} lines`);
  console.log(`   ✅ EXTENDS.md: ${extendsContent.split('\n').length} lines`);
  if (industry.sources) {
    console.log(`   ✅ SOURCES.md: ${sourcesContent.split('\n').length} lines`);
  }

  // Generate reference files
  await generateReferenceFiles(industry, outputDir);

  // Update Astro routing
  await updateAstroRouting(industry);
}

// Generate industry-specific reference files
async function generateReferenceFiles(industry, outputDir) {
  for (const ref of industry.reference_files) {
    const content = await generateReferenceContent(ref, industry);
    const filePath = path.join(outputDir, 'references', ref.name);
    fs.writeFileSync(filePath, content);
    console.log(`   ✅ ${ref.name}: ${content.split('\n').length} lines`);
  }
}

// Generate reference file content
async function generateReferenceContent(refFile, industry) {
  let content = `# ${refFile.description}\n\n`;
  content += `**Industry**: ${industry.industry_name}\n`;
  content += `**Generated**: ${new Date().toISOString()}\n\n`;
  content += `---\n\n`;

  // Generate content for each section
  for (const section of refFile.sections) {
    content += `## ${section}\n\n`;

    // Match section to relevant industry data
    if (refFile.name.includes('data-models')) {
      // Add data model details
      const relevantModels = industry.data_models.filter(dm =>
        section.toLowerCase().includes('overview') ||
        section.toLowerCase().includes('core') ||
        dm.object.toLowerCase().includes(section.toLowerCase())
      );

      if (relevantModels.length > 0) {
        relevantModels.forEach(model => {
          content += `### ${model.object}\n\n`;
          content += `${model.description}\n\n`;
          content += `**Key Fields**:\n`;
          model.key_fields.forEach(field => {
            content += `- \`${field}\`\n`;
          });
          content += `\n`;
          if (model.relationships.length > 0) {
            content += `**Relationships**:\n`;
            model.relationships.forEach(rel => {
              content += `- ${rel}\n`;
            });
            content += `\n`;
          }
        });
      } else {
        content += `[Detailed content for ${section}]\n\n`;
      }
    } else if (refFile.name.includes('regulatory')) {
      // Add regulatory details
      const relevantRegs = industry.regulatory_frameworks.filter(rf =>
        section.toLowerCase().includes('regulations') ||
        rf.name.toLowerCase().includes(section.toLowerCase())
      );

      if (relevantRegs.length > 0) {
        relevantRegs.forEach(reg => {
          content += `### ${reg.name}\n\n`;
          content += `${reg.description}\n\n`;
          content += `**Key Requirements**:\n`;
          reg.key_requirements.forEach(req => {
            content += `- ${req}\n`;
          });
          content += `\n`;
        });
      } else {
        content += `[Detailed content for ${section}]\n\n`;
      }
    } else if (refFile.name.includes('integrations')) {
      // Add integration details
      const relevantInts = industry.key_integrations.filter(ki =>
        section.toLowerCase().includes('common') ||
        ki.name.toLowerCase().includes(section.toLowerCase())
      );

      if (relevantInts.length > 0) {
        relevantInts.forEach(int => {
          content += `### ${int.name}\n\n`;
          content += `**Protocol**: ${int.protocol}\n`;
          content += `**Use Case**: ${int.use_case}\n`;
          content += `**Example Endpoint**: \`${int.example_endpoint}\`\n\n`;
        });
      } else {
        content += `[Detailed content for ${section}]\n\n`;
      }
    } else if (refFile.name.includes('use-cases')) {
      // Add use case details
      const relevantUCs = industry.use_cases.filter(uc =>
        section.toLowerCase().includes('common') ||
        uc.title.toLowerCase().includes(section.toLowerCase())
      );

      if (relevantUCs.length > 0) {
        relevantUCs.forEach(uc => {
          content += `### ${uc.title}\n\n`;
          content += `${uc.description}\n\n`;
          content += `**Technical Components**:\n`;
          uc.technical_components.forEach(comp => {
            content += `- ${comp}\n`;
          });
          content += `\n`;
        });
      } else {
        content += `[Detailed content for ${section}]\n\n`;
      }
    } else {
      content += `[Content for ${section}]\n\n`;
    }
  }

  content += `---\n\n`;
  content += `**Reference**: See \`../SKILL.md\` for complete ${industry.industry_name} skill definition.\n`;

  return content;
}

// Update Astro SKILL.md with new routing
async function updateAstroRouting(industry) {
  const astroPath = path.join(__dirname, '..', 'astro', 'SKILL.md');

  if (!fs.existsSync(astroPath)) {
    console.log('   ⚠️  Astro SKILL.md not found, skipping routing update');
    return;
  }

  let astroContent = fs.readFileSync(astroPath, 'utf8');

  // Check if routing already exists
  if (astroContent.includes(`/${industry.skill_name}`)) {
    console.log(`   ⚠️  Routing for /${industry.skill_name} already exists in Astro`);
    return;
  }

  const routingSection = `
### ${industry.industry_name} → \`/${industry.skill_name}\`

**Indicators**:
${industry.routing_indicators.map(ind => `- "${ind}"`).join('\n')}

**Examples**:
${industry.use_cases.slice(0, 2).map(uc => `- "${uc.title}"`).join('\n')}

**When to use \`/${industry.skill_name}\` vs \`/fullstack-dev\`**:
- Use \`/${industry.skill_name}\` when working with ${industry.industry_name} objects or features
- Use \`/fullstack-dev\` for generic Salesforce development

---

`;

  // Find insertion point (before the end of the routing logic section)
  const insertionMarker = '## Routing Logic';
  const markerIndex = astroContent.indexOf(insertionMarker);

  if (markerIndex !== -1) {
    // Find the end of the routing logic section
    const nextSectionIndex = astroContent.indexOf('##', markerIndex + insertionMarker.length);
    const insertionPoint = nextSectionIndex !== -1 ? nextSectionIndex : astroContent.length;

    astroContent =
      astroContent.slice(0, insertionPoint) +
      routingSection +
      astroContent.slice(insertionPoint);

    fs.writeFileSync(astroPath, astroContent);
    console.log(`   ✅ Updated Astro routing for /${industry.skill_name}`);
  } else {
    // Append to end if no routing logic section found
    astroContent += '\n' + routingSection;
    fs.writeFileSync(astroPath, astroContent);
    console.log(`   ✅ Appended Astro routing for /${industry.skill_name}`);
  }
}

// Validate JSON against schema
function validateIndustryJSON(industry) {
  const schemaPath = path.join(__dirname, 'schema', 'industry-skill-schema.json');

  if (!fs.existsSync(schemaPath)) {
    console.log('   ⚠️  Schema file not found, skipping validation');
    return;
  }

  const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  const ajv = new Ajv({ allErrors: true, strictSchema: false });
  const validate = ajv.compile(schema);
  const valid = validate(industry);

  if (!valid) {
    console.error('   ❌ Validation errors:');
    validate.errors.forEach(err => {
      console.error(`      ${err.instancePath}: ${err.message}`);
    });
    throw new Error('JSON validation failed');
  }
}

// Load template helper
function loadTemplate(templateName) {
  const templatePath = path.join(__dirname, 'base', templateName);

  if (!fs.existsSync(templatePath)) {
    throw new Error(`Template not found: ${templatePath}`);
  }

  return fs.readFileSync(templatePath, 'utf8');
}

// Run main function
main().catch(err => {
  console.error('\n❌ Error:', err.message);
  console.error('\nStack trace:');
  console.error(err.stack);
  process.exit(1);
});
