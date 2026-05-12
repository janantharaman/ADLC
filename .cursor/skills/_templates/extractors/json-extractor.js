const fs = require('fs');
const path = require('path');

class JSONExtractor {
  constructor(jsonPath) {
    this.jsonPath = jsonPath;
  }

  async extract() {
    console.log('📝 Loading JSON definition...\n');

    try {
      // Check if file exists
      if (!fs.existsSync(this.jsonPath)) {
        throw new Error(`JSON file not found: ${this.jsonPath}`);
      }

      // Read and parse JSON
      const jsonContent = fs.readFileSync(this.jsonPath, 'utf8');
      const industryJSON = JSON.parse(jsonContent);

      console.log(`   ✅ Loaded JSON definition from ${path.basename(this.jsonPath)}`);

      // Validate required fields
      this.validateJSON(industryJSON);

      console.log(`   ✅ JSON validation passed\n`);

      return industryJSON;
    } catch (error) {
      console.error('❌ JSON extraction failed:', error.message);
      throw error;
    }
  }

  validateJSON(json) {
    const requiredFields = [
      'skill_name',
      'industry_name',
      'description',
      'routing_indicators',
      'data_models',
      'regulatory_frameworks',
      'key_integrations',
      'unique_competencies',
      'use_cases',
      'reference_files'
    ];

    const missingFields = requiredFields.filter(field => !(field in json));

    if (missingFields.length > 0) {
      throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
    }

    // Validate skill_name pattern
    if (!json.skill_name.match(/^[a-z]+-dev$/)) {
      throw new Error('skill_name must match pattern: ^[a-z]+-dev$ (e.g., fsc-dev)');
    }

    // Validate arrays have minimum items
    if (json.data_models.length === 0) {
      throw new Error('data_models array must have at least 1 item');
    }

    if (json.unique_competencies.length === 0) {
      throw new Error('unique_competencies array must have at least 1 item');
    }

    if (json.use_cases.length === 0) {
      throw new Error('use_cases array must have at least 1 item');
    }

    if (json.reference_files.length === 0) {
      throw new Error('reference_files array must have at least 1 item');
    }

    // Validate data model structure
    json.data_models.forEach((dm, index) => {
      if (!dm.object || !dm.description || !dm.key_fields || !dm.relationships) {
        throw new Error(`data_models[${index}] missing required fields`);
      }
    });

    // Validate competencies structure
    json.unique_competencies.forEach((comp, index) => {
      if (!comp.area || !comp.expertise_level || !comp.capabilities) {
        throw new Error(`unique_competencies[${index}] missing required fields`);
      }
      const validLevels = ['Expert', 'Advanced', 'Intermediate'];
      if (!validLevels.includes(comp.expertise_level)) {
        throw new Error(`unique_competencies[${index}].expertise_level must be Expert, Advanced, or Intermediate`);
      }
    });

    // Validate use cases structure
    json.use_cases.forEach((uc, index) => {
      if (!uc.title || !uc.description || !uc.technical_components) {
        throw new Error(`use_cases[${index}] missing required fields`);
      }
    });

    // Validate reference files structure
    json.reference_files.forEach((ref, index) => {
      if (!ref.name || !ref.description || !ref.sections) {
        throw new Error(`reference_files[${index}] missing required fields`);
      }
      if (!ref.name.endsWith('.md')) {
        throw new Error(`reference_files[${index}].name must end with .md`);
      }
    });
  }
}

module.exports = JSONExtractor;
