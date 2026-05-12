const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

class NotebookLMExtractor {
  constructor(notebookId) {
    this.notebookId = notebookId;
    this.prompts = this.loadPrompts();
  }

  loadPrompts() {
    const promptsDir = path.join(__dirname, '..', 'prompts');
    return {
      dataModels: fs.readFileSync(path.join(promptsDir, 'data-models.txt'), 'utf8'),
      regulations: fs.readFileSync(path.join(promptsDir, 'regulations.txt'), 'utf8'),
      integrations: fs.readFileSync(path.join(promptsDir, 'integrations.txt'), 'utf8'),
      competencies: fs.readFileSync(path.join(promptsDir, 'competencies.txt'), 'utf8'),
      useCases: fs.readFileSync(path.join(promptsDir, 'use-cases.txt'), 'utf8')
    };
  }

  async extract(skillName, industryName) {
    console.log('📚 Querying NotebookLM...\n');

    try {
      // Query NotebookLM for each knowledge area (parallel for speed)
      const [dataModels, regulations, integrations, competencies, useCases] = await Promise.all([
        this.extractDataModels(),
        this.extractRegulations(),
        this.extractIntegrations(),
        this.extractCompetencies(),
        this.extractUseCases()
      ]);

      // Generate routing indicators from extracted knowledge
      const routingIndicators = this.generateRoutingIndicators(
        dataModels,
        regulations,
        competencies
      );

      // Generate description
      const description = this.generateDescription(industryName, competencies);

      // Construct industry JSON
      return {
        skill_name: skillName,
        industry_name: industryName,
        description: description,
        routing_indicators: routingIndicators,
        data_models: dataModels,
        regulatory_frameworks: regulations,
        key_integrations: integrations,
        unique_competencies: competencies,
        use_cases: useCases,
        reference_files: this.generateReferenceFilesList(industryName),
        sources: {
          notebook_id: this.notebookId,
          notebook_url: `https://notebooklm.google.com/notebook/${this.notebookId}`,
          extraction_date: new Date().toISOString()
        }
      };
    } catch (error) {
      console.error('❌ NotebookLM extraction failed:', error.message);
      console.log('⚠️  Falling back to mock data for development...');
      return this.getMockIndustryJSON(skillName, industryName);
    }
  }

  async queryNotebookLM(prompt) {
    // TODO: Implement actual NotebookLM MCP call
    // For now, this is a placeholder that would integrate with the MCP server

    // Option 1: Use Claude CLI with MCP (if available)
    // Option 2: Direct MCP server call (requires MCP server running)
    // Option 3: HTTP request to MCP server endpoint

    // Placeholder implementation:
    console.log('   ⚠️  NotebookLM MCP integration not yet implemented');
    console.log('   ℹ️  To implement: Install NotebookLM MCP server and update this method');
    throw new Error('NotebookLM MCP integration pending');
  }

  async extractDataModels() {
    console.log('   🔍 Extracting data models...');
    try {
      const response = await this.queryNotebookLM(this.prompts.dataModels);
      return this.parseDataModelsResponse(response);
    } catch (error) {
      console.log('   ⚠️  Using mock data models');
      return this.getMockDataModels();
    }
  }

  parseDataModelsResponse(response) {
    const models = [];

    // Pattern: Object name, description, fields, relationships
    const objectPattern = /(\d+\.\s+)?(\w+__\w+__c|\w+)\s*\n\s*-?\s*Description:\s*(.+?)\n\s*-?\s*Key Fields?:\s*(.+?)\n\s*-?\s*Related Objects?:\s*(.+?)(?=\n\n|\n\d+\.|\s*$)/gis;

    let match;
    while ((match = objectPattern.exec(response)) !== null) {
      const object = match[2].trim();
      const description = match[3].trim();
      const keyFields = match[4].split(',').map(f => f.trim()).filter(f => f && f !== 'None');
      const relationships = match[5].split(',').map(r => r.trim()).filter(r => r && r !== 'None');

      if (object && description) {
        models.push({
          object: object,
          description: description,
          key_fields: keyFields.length > 0 ? keyFields : ['Name'],
          relationships: relationships
        });
      }
    }

    return models.length > 0 ? models : this.getMockDataModels();
  }

  async extractRegulations() {
    console.log('   🔍 Extracting regulatory frameworks...');
    try {
      const response = await this.queryNotebookLM(this.prompts.regulations);
      return this.parseRegulationsResponse(response);
    } catch (error) {
      console.log('   ⚠️  Using mock regulations');
      return this.getMockRegulations();
    }
  }

  parseRegulationsResponse(response) {
    const regulations = [];

    // Pattern: Regulation name, description, requirements
    const regPattern = /(\d+\.\s+)?([A-Z][A-Za-z\s]+)\s*\n\s*-?\s*Description:\s*(.+?)\n\s*-?\s*Key Requirements?:\s*\n((?:\s*-\s*.+\n?)+)/gis;

    let match;
    while ((match = regPattern.exec(response)) !== null) {
      const name = match[2].trim();
      const description = match[3].trim();
      const requirements = match[4]
        .split('\n')
        .map(line => line.trim().replace(/^-\s*/, ''))
        .filter(line => line && line !== 'None');

      if (name && description && requirements.length > 0) {
        regulations.push({
          name: name,
          description: description,
          key_requirements: requirements
        });
      }
    }

    return regulations.length > 0 ? regulations : this.getMockRegulations();
  }

  async extractIntegrations() {
    console.log('   🔍 Extracting integration patterns...');
    try {
      const response = await this.queryNotebookLM(this.prompts.integrations);
      return this.parseIntegrationsResponse(response);
    } catch (error) {
      console.log('   ⚠️  Using mock integrations');
      return this.getMockIntegrations();
    }
  }

  parseIntegrationsResponse(response) {
    const integrations = [];

    // Pattern: System name, protocol, use case, endpoint
    const intPattern = /(\d+\.\s+)?(.+?)\s*\n\s*-?\s*Protocol:\s*(.+?)\n\s*-?\s*Use Case:\s*(.+?)\n\s*-?\s*(?:Example\s+)?Endpoint:\s*(.+?)(?=\n\n|\n\d+\.|\s*$)/gis;

    let match;
    while ((match = intPattern.exec(response)) !== null) {
      const name = match[2].trim();
      const protocol = match[3].trim();
      const useCase = match[4].trim();
      const endpoint = match[5].trim();

      if (name && protocol && useCase) {
        integrations.push({
          name: name,
          protocol: protocol,
          use_case: useCase,
          example_endpoint: endpoint || '/api/v1/endpoint'
        });
      }
    }

    return integrations.length > 0 ? integrations : this.getMockIntegrations();
  }

  async extractCompetencies() {
    console.log('   🔍 Extracting competencies...');
    try {
      const response = await this.queryNotebookLM(this.prompts.competencies);
      return this.parseCompetenciesResponse(response);
    } catch (error) {
      console.log('   ⚠️  Using mock competencies');
      return this.getMockCompetencies();
    }
  }

  parseCompetenciesResponse(response) {
    const competencies = [];

    // Pattern: Area, expertise level, capabilities
    const compPattern = /(\d+\.\s+)?(.+?)\s+\((\w+)\)\s*\n\s*(?:Capabilities?:)?\s*\n((?:\s*-\s*.+\n?)+)/gis;

    let match;
    while ((match = compPattern.exec(response)) !== null) {
      const area = match[2].trim();
      const level = match[3].trim();
      const capabilities = match[4]
        .split('\n')
        .map(line => line.trim().replace(/^-\s*/, ''))
        .filter(line => line);

      if (area && level && capabilities.length > 0) {
        competencies.push({
          area: area,
          expertise_level: level,
          capabilities: capabilities
        });
      }
    }

    return competencies.length > 0 ? competencies : this.getMockCompetencies();
  }

  async extractUseCases() {
    console.log('   🔍 Extracting use cases...');
    try {
      const response = await this.queryNotebookLM(this.prompts.useCases);
      return this.parseUseCasesResponse(response);
    } catch (error) {
      console.log('   ⚠️  Using mock use cases');
      return this.getMockUseCases();
    }
  }

  parseUseCasesResponse(response) {
    const useCases = [];

    // Pattern: Title, description, technical components
    const ucPattern = /(\d+\.\s+)?(.+?)\s*\n\s*-?\s*Description:\s*(.+?)\n\s*-?\s*Technical Components?:\s*(.+?)(?=\n\n|\n\d+\.|\s*$)/gis;

    let match;
    while ((match = ucPattern.exec(response)) !== null) {
      const title = match[2].trim();
      const description = match[3].trim();
      const components = match[4].split(',').map(c => c.trim()).filter(c => c);

      if (title && description && components.length > 0) {
        useCases.push({
          title: title,
          description: description,
          technical_components: components
        });
      }
    }

    return useCases.length > 0 ? useCases : this.getMockUseCases();
  }

  generateRoutingIndicators(dataModels, regulations, competencies) {
    const indicators = [];

    // Add data model object names (simplified)
    dataModels.slice(0, 3).forEach(dm => {
      const objectName = dm.object.replace(/__c$/, '').replace(/__/g, ' ').toLowerCase();
      indicators.push(objectName);
    });

    // Add regulation names
    regulations.slice(0, 2).forEach(reg => {
      indicators.push(reg.name);
    });

    // Add competency areas (lowercase)
    competencies.slice(0, 2).forEach(comp => {
      indicators.push(comp.area.toLowerCase());
    });

    // Ensure at least 3 indicators
    if (indicators.length < 3) {
      indicators.push('industry', 'cloud', 'implementation');
    }

    return indicators;
  }

  generateDescription(industryName, competencies) {
    if (competencies.length >= 2) {
      const areas = competencies.slice(0, 2).map(c => c.area).join(', ');
      return `${industryName} full-stack developer with expertise in ${areas} and regulatory compliance`;
    }
    return `${industryName} full-stack developer with industry-specific expertise`;
  }

  generateReferenceFilesList(industryName) {
    const prefix = industryName.toLowerCase()
      .replace(/\s+/g, '-')
      .replace(/[^a-z-]/g, '');

    return [
      {
        name: `${prefix}-data-models.md`,
        description: `${industryName} data model deep dive`,
        sections: ['Overview', 'Core Objects', 'Relationships', 'Best Practices']
      },
      {
        name: `${prefix}-regulatory.md`,
        description: `${industryName} compliance patterns`,
        sections: ['Regulations', 'Audit Requirements', 'Security', 'Best Practices']
      },
      {
        name: `${prefix}-integrations.md`,
        description: `${industryName} integration patterns`,
        sections: ['Common Integrations', 'API Patterns', 'Error Handling', 'Best Practices']
      },
      {
        name: `${prefix}-use-cases.md`,
        description: `${industryName} implementation scenarios`,
        sections: ['Common Use Cases', 'Technical Patterns', 'Code Examples', 'Best Practices']
      }
    ];
  }

  // Mock data for development/fallback
  getMockDataModels() {
    return [
      {
        object: 'Industry__CustomObject__c',
        description: 'Core industry object for business data',
        key_fields: ['Name', 'Status__c', 'Value__c', 'Type__c'],
        relationships: ['Account', 'Contact']
      },
      {
        object: 'Industry__Transaction__c',
        description: 'Tracks industry-specific transactions',
        key_fields: ['Name', 'Amount__c', 'Date__c', 'Status__c'],
        relationships: ['Industry__CustomObject__c', 'Account']
      }
    ];
  }

  getMockRegulations() {
    return [
      {
        name: 'Industry Regulation',
        description: 'Standard industry compliance framework',
        key_requirements: [
          'Data protection and privacy',
          'Audit trail maintenance',
          'Regular compliance reporting'
        ]
      }
    ];
  }

  getMockIntegrations() {
    return [
      {
        name: 'External System',
        protocol: 'REST API',
        use_case: 'Real-time data synchronization',
        example_endpoint: '/api/v1/sync'
      }
    ];
  }

  getMockCompetencies() {
    return [
      {
        area: 'Domain Expertise',
        expertise_level: 'Expert',
        capabilities: [
          'Industry knowledge and best practices',
          'Business process optimization',
          'Solution design and architecture'
        ]
      },
      {
        area: 'Technical Implementation',
        expertise_level: 'Advanced',
        capabilities: [
          'Custom development patterns',
          'Integration architecture',
          'Performance optimization'
        ]
      }
    ];
  }

  getMockUseCases() {
    return [
      {
        title: 'Standard Implementation',
        description: 'Common industry implementation pattern for core business processes',
        technical_components: ['Apex Controller', 'LWC Component', 'Integration Service']
      },
      {
        title: 'Data Migration',
        description: 'Bulk data migration from legacy systems',
        technical_components: ['Batch Apex', 'Data Loader', 'Validation Rules']
      }
    ];
  }

  getMockIndustryJSON(skillName, industryName) {
    return {
      skill_name: skillName,
      industry_name: industryName,
      description: this.generateDescription(industryName, this.getMockCompetencies()),
      routing_indicators: ['industry', 'cloud', 'implementation'],
      data_models: this.getMockDataModels(),
      regulatory_frameworks: this.getMockRegulations(),
      key_integrations: this.getMockIntegrations(),
      unique_competencies: this.getMockCompetencies(),
      use_cases: this.getMockUseCases(),
      reference_files: this.generateReferenceFilesList(industryName),
      sources: {
        notebook_id: this.notebookId,
        notebook_url: `https://notebooklm.google.com/notebook/${this.notebookId}`,
        extraction_date: new Date().toISOString()
      }
    };
  }
}

module.exports = NotebookLMExtractor;
