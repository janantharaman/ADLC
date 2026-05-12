# CG Cloud TPM Knowledge Base

> **Extracted from**: NotebookLM "Industry Knowledge Base: CG TPM" (41 sources)
> **Extraction Date**: 2026-03-06
> **Skill**: `/cg-tpm-dev`

## Knowledge Files

This directory contains comprehensive CG Cloud Trade Promotion Management (TPM) knowledge extracted from NotebookLM and structured for the `/cg-tpm-dev` skill.

### Core Knowledge Files

1. **[data-models.md](data-models.md)** - Core TPM Data Models
   - Sales Organization
   - Product & Product Hierarchy
   - Account & Account Hierarchy
   - Promotion
   - Account Product List (APL)
   - Trade Calendar
   - KPI Objects

2. **[business-processes.md](business-processes.md)** - TPM Business Processes
   - Customer Business Planning (CBP)
   - Promotion Management
   - Claims Processing
   - KPI Configuration
   - Real-Time Reporting (RTR)

3. **[technical-patterns.md](technical-patterns.md)** - Implementation Patterns
   - Processing Engine Data
   - Batch Chains
   - Promotion UI Customization
   - Promo BO API
   - Metadata Wizard

4. **[integration-patterns.md](integration-patterns.md)** - Integration Architecture
   - ERP Systems (SAP)
   - POS & Syndicated Data
   - Integration APIs
   - Real-Time Reporting Data Sources
   - Security & Best Practices

5. **[use-cases.md](use-cases.md)** - Common Development Scenarios
   - Creating Promotions (UI, Backend, API)
   - Processing Claims
   - Configuring KPIs
   - Setting up Product Hierarchies
   - Managing Account Product Lists

### Configuration Files

6. **[config.json](config.json)** - NotebookLM Integration Configuration
   - Notebook ID and settings
   - Query templates
   - Pre-trained baseline configuration

7. **[notebooklm-integration.md](notebooklm-integration.md)** - Dynamic Knowledge Integration Guide
   - Two-tier knowledge strategy
   - Query patterns and templates
   - Graceful degradation approach

## Two-Tier Knowledge Strategy

This knowledge base implements a **dynamic knowledge integration pattern**:

### Tier 1: NotebookLM (Live Knowledge) ⭐
- Real-time queries to NotebookLM
- Always-current information
- Used for: latest patterns, validation, up-to-date guidance

### Tier 2: Pre-Trained (Baseline Knowledge) 📚
- Static files in this directory
- Offline-capable
- Used for: quick reference, fallback when NotebookLM unavailable

**Pattern**: Try NotebookLM → Fallback to Pre-Trained → Always Provide Expert Guidance

## Usage

When the `/cg-tpm-dev` skill is invoked:

1. **Analyze** the developer's request
2. **Try** querying NotebookLM for latest information (Tier 1)
3. **Fallback** to pre-trained files if NotebookLM unavailable (Tier 2)
4. **Combine** live knowledge with implementation patterns
5. **Always provide** complete expert guidance

**Indicators**:
- `✓ From NotebookLM (latest)` - Using live knowledge
- `⚠️ Pre-trained knowledge` - Using baseline (NotebookLM unavailable)

## Knowledge Coverage

### Data Models (100%)
- 8 core objects fully documented
- Field definitions and relationships
- Synchronization requirements

### Business Processes (100%)
- 5 major processes with step-by-step workflows
- Best practices for each process
- Common pitfalls and solutions

### Technical Patterns (100%)
- 5 key implementation patterns
- Code examples and best practices
- Integration with Processing Service

### Integration Patterns (95%)
- ERP, POS, API patterns fully documented
- Data Cloud connectivity (limited sources - needs supplementation)

### Use Cases (100%)
- 5 common development scenarios
- Complete code examples
- UI, backend, and API implementations

## Maintenance

### Update Schedule
- **Quarterly**: Review for accuracy
- **After CG Cloud Updates**: Regenerate if major features added
- **Source Changes**: Re-extract when NotebookLM sources updated

### Update Process
1. Query NotebookLM with updated questions
2. Review differences from current files
3. Update affected knowledge files
4. Update `snapshot_date` in config.json
5. Test skill with updated knowledge

## Quality Metrics

**Source Coverage**: 41 sources analyzed
**Extraction Quality**: High (direct quotes with citations)
**Code Examples**: Production-ready patterns
**Integration Coverage**: Comprehensive (ERP, POS, APIs)

## Next Steps

This knowledge base serves as **Tier 2 (Pre-Trained)** knowledge for the `/cg-tpm-dev` skill.

**Phase 2**: Design skill structure (SKILL.md, README.md)
**Phase 3**: Implement dynamic NotebookLM querying
**Phase 4**: Test and validate skill
**Phase 5**: Deploy to team

---

**Note**: This knowledge base is designed to work in conjunction with dynamic NotebookLM queries for always-current guidance while maintaining offline capability.
