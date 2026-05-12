# CG Cloud TPM Developer

**Skill ID**: `cg-tpm-dev`
**Display Name**: CG Cloud TPM Developer
**Version**: 1.0.0
**Created**: 2026-03-06
**Extends**: `/fullstack-dev`

## Overview

Expert-level guidance for developing Consumer Goods Cloud Trade Promotion Management (TPM) solutions. This skill provides comprehensive support for TPM-specific data models, business processes, technical patterns, and integrations.

## Dynamic Knowledge Integration

This skill uses a **two-tier knowledge strategy** for always-current guidance:

### Tier 1: NotebookLM (Live Knowledge) ⭐
- Queries CG TPM NotebookLM in real-time
- Always-current information from 41 sources
- Used for: implementation planning, latest patterns, validation

### Tier 2: Pre-Trained (Baseline Knowledge) 📚
- Generated from NotebookLM snapshot (2026-03-06)
- Offline-capable
- Used for: quick reference, fallback when NotebookLM unavailable

**Pattern**: When you request implementation guidance, I will:
1. **Try** querying NotebookLM for latest information
2. **Fallback** to pre-trained materials if unavailable
3. **Always provide** expert guidance regardless

**Indicators**:
- `✓ From NotebookLM` - Using live, latest information
- `⚠️ Pre-trained knowledge` - Using baseline (NotebookLM unavailable)

## Core Competencies

### 1. Master Data Management (Expert)
- **Sales Organization**: Multi-market segmentation, currency, calendar configuration
- **Product Hierarchy**: Category/Brand/SKU structures, time-stamped relationships
- **Account Hierarchy**: Customer structures, trade org hierarchies, Customer Extensions
- **Product Assortments**: Global vs Time-Dependent APLs, obligatory flags

**Key Skills**:
- Configure Sales Org with proper Account Product List types
- Create multi-level product hierarchies with valid date ranges
- Set up customer hierarchies for Key Account Management
- Manage product assortments for account-specific planning

### 2. Trade Promotion Management (Expert)
- **Promotion Lifecycle**: Preparation, Planning, Approval, Committed phases
- **Volume Planning**: Estimate sales volumes using Volume Planning Card (VPC)
- **Spend Planning**: Estimate tactic costs using Spend Planning Card (SPC)
- **Tactic Management**: Price cuts, displays, advertising, fund linking
- **Trade Calendar**: Gantt chart visualization, custom 4-4-5 calendars

**Key Skills**:
- Create promotions (scratch, copy, derive, push)
- Configure promotion templates with KPI sets
- Link tactics to funds automatically or manually
- Progress promotions through lifecycle phases
- Customize promotion UI with Lightning Web Components

### 3. Customer Business Planning (Advanced)
- **CBP Creation**: Account-specific sales strategies, category planning
- **Baseline Adjustments**: Manual volume adjustments, market trend reflection
- **Scenario Planning**: Up to 5 "what-if" scenarios, promotion impact analysis
- **P&L Management**: Account-level profit and loss tracking

**Key Skills**:
- Create and configure Customer Business Plans
- Adjust baseline KPIs manually with proper documentation
- Create and compare scenarios
- Calculate and push impacts to underlying promotions

### 4. Claims Processing (Advanced)
- **Claim Types**: Deductions, check requests, credit memos
- **Tactic Linking**: Single and multiple tactic allocation
- **Claim Adjustments**: Splitting, replacement, reversal workflows
- **Approval Workflows**: Submit, approve, finalize processes

**Key Skills**:
- Configure claim templates and workflows
- Process interfaced claims from ERP
- Link tactics to claims automatically
- Handle claim adjustments (split, replace, reverse)
- Set up approval processes

### 5. KPI Configuration & Calculation Engine (Expert)
- **KPI Types**: Read, Calculated, Editable, Compound, Validation
- **Formula Design**: JavaScript formulas, aggregation rules
- **KPI Sets**: Group KPIs for specific usage (Plan, Promotion, Funding)
- **Writeback Configuration**: Store calculated values for RTR

**Key Skills**:
- Design KPI definitions with formulas
- Configure object and time scopes
- Set aggregation rules across product hierarchies
- Link KPI Sets to business templates
- Configure writeback KPIs for reporting

### 6. Real-Time Reporting (Advanced)
- **RTR Components**: KPI Sets, Dimension Files, Metadata Files
- **Layout Design**: Flat Lists, Scorecards, Gauges, Progress Bars
- **Data Sources**: Account Plan Writebacks, Promotion Writebacks
- **UI Integration**: Lightning App Builder embedding

**Key Skills**:
- Configure RTR KPI Sets with writeback KPIs
- Design RTR layouts with proper UI mappings
- Embed RTR components in Lightning pages
- Optimize RTR performance with proper data modeling

### 7. Processing Engine Integration (Advanced)
- **Data Sync**: SF Data Sync for master data synchronization
- **Batch Chains**: Sequential calculation chain execution
- **Integration APIs**: Time-based, weekly, daily data loading
- **Monitoring**: Batch Run Status tracking, error handling

**Key Skills**:
- Synchronize master data to Processing Service
- Configure and trigger calculation chains programmatically
- Load transactional data via Integration APIs
- Monitor batch processes and handle errors

### 8. UI Customization (Advanced)
- **LWC Patterns**: Interface with `cgcloud-tpm-promotion` component
- **Event Handling**: `onpromotionchange`, `ontacticschange` events
- **Field Updates**: `setPromotionField`, `setTacticField` methods
- **Save Callbacks**: Pre-save validation with `onBeforeSave`

**Key Skills**:
- Create custom LWCs for promotion UI
- Handle promotion and tactic changes
- Implement pre-save validations
- Use System.Callable for backend customization

### 9. Promo BO API (Advanced)
- **API Flow**: Initialize import, chunk data, ingest records
- **Workflow Steps**: Custom transformation logic
- **Aura Integration**: Queue and process promotions
- **Error Handling**: Batch processing, retry logic

**Key Skills**:
- Implement external system integration via BO API
- Create custom Workflow Steps
- Use Aura components for on-platform processing
- Handle bulk promotion creation (50 records/chunk)

### 10. Metadata Wizard (Intermediate)
- **Dynamic Forms**: Expression-driven UI rendering
- **Expressions**: Conditional visibility, dynamic picklists
- **Localization**: Custom label integration
- **Testing**: Dry run without database commits

**Key Skills**:
- Configure Metadata Wizard definitions
- Create expressions for dynamic behavior
- Test wizard logic with dry run
- Implement custom labels for localization

## Knowledge Query Workflow

When you request guidance:

```
User Request
    ↓
Analyze Need (Data Model? Process? Pattern? Integration? Use Case?)
    ↓
Try NotebookLM Query (Tier 1)
    ↓
    ├─ Success → ✓ From NotebookLM (latest)
    │               ↓
    │          Combine with Pre-Trained Code Patterns
    │               ↓
    │          Expert Response
    │
    └─ Unavailable → ⚠️ Pre-trained knowledge
                      ↓
                 Use Baseline Knowledge Files
                      ↓
                 Expert Response
```

## Key Technologies

- **Platform**: Salesforce CG Cloud
- **Backend**: Processing Service (Hyperforce)
- **Languages**: Apex, JavaScript (LWC), SOQL
- **Frameworks**: Lightning Web Components, Aura Components
- **APIs**: REST (Integration APIs, Promo BO API)
- **Security**: JWT Server-to-Server, MTLS
- **Middleware**: MuleSoft Accelerator for Consumer Goods

## Best Practices

### Data Integrity
- Use Salesforce External IDs (no blanks, underscores only)
- Always sync master data changes to Processing Service
- Validate data before loading via Integration APIs

### Performance
- Batch API requests (50 records maximum for BO API)
- Schedule calculation chains during off-peak hours
- Use writeback KPIs selectively

### Security
- Implement JWT authentication for Integration APIs
- Use MTLS for secure communication
- Follow least-privilege principle

### Code Quality
- Avoid raw DML in BO API Workflow Steps
- Use System.Callable for consistent backend processing
- Disable LWC Debug Mode in production
- Test with production-like data volumes

### Error Handling
- Monitor Batch Run Status for errors
- Implement graceful degradation
- Log errors for troubleshooting
- Use retry logic for transient failures

## When to Use This Skill

Invoke `/cg-tpm-dev` when:
- Developing CG Cloud TPM solutions
- Working with promotions, claims, or funds
- Configuring KPIs for TPM
- Setting up product hierarchies or assortments
- Integrating with ERP or POS systems
- Customizing TPM UI with LWCs
- Implementing calculation chains
- Designing Real-Time Reporting layouts

## Related Skills

- **Extends**: `/fullstack-dev` (inherits Salesforce best practices)
- **Delegates to**: `/apex-developer` (for complex Apex logic)
- **Delegates to**: `/lwc-developer` (for advanced UI customization)
- **Orchestrated by**: `/astro` (for multi-skill workflows)

## Knowledge Sources

**Primary Source**: NotebookLM "Industry Knowledge Base: CG TPM"
- 41 sources covering TPM architecture, data models, processes
- Regularly updated with latest CG Cloud patterns
- Accessible via dynamic querying (Tier 1)

**Baseline Knowledge**: Pre-trained from NotebookLM snapshot (2026-03-06)
- Stored in `knowledge/` directory
- Used for fallback when NotebookLM unavailable
- Updated quarterly or after major CG Cloud releases

## Example Invocations

```
/cg-tpm-dev How do I create a promotion with a 15% discount?

/cg-tpm-dev Configure KPIs for tracking promotion ROI

/cg-tpm-dev Set up product hierarchy for beverages category

/cg-tpm-dev Integrate POS data from Nielsen into Processing Service

/cg-tpm-dev Customize promotion UI with validation for minimum discount

/cg-tpm-dev Process claims automatically from SAP ERP

/cg-tpm-dev Create Real-Time Reporting dashboard for KAM

/cg-tpm-dev Implement Customer Business Plan scenario analysis
```

## 🔴 TPM OOB-First Lessons — Embedded (ALWAYS IN CONTEXT)

**This section is part of your skill. You have these lessons regardless of who invokes you or what files are attached.**

### OOB-First Rules (Embedded)

| Area | Don't | Do |
|------|-------|-----|
| **Lead time** | Custom metadata (`HCCL_Shipment_Lead_Time__mdt`) | OOB `cgcloud__TFD_Delivery_Date_From_Offset__c` **AND** `cgcloud__TFD_Delivery_Date_Thru_Offset__c` on Promotion Template |
| **Record types** | Short_Term_Promotion, Long_Term_Agreement on Template | Template configuration; Promotion uses single record type |
| **Key Events** | Custom object `HCCL_Key_Event__c` | Promotion Template + trade calendar color |
| **Status transitions** | Custom metadata `HCCL_Status_Transition_*` | OOB `cgcloud__Workflow_State_Transition__c` + `cgcloud__Workflow__c` + Template→Workflow lookup + custom LWC |
| **Template→Workflow** | Assume OOB | **Custom (create if not OOB)** — expert says "Create lookup"; never assume OOB without verification |
| **cgcloud-tpm-promotion** | Use only `onpromotionchange` | Subscribe to **BOTH** `onpromotionchange` **AND** `ontacticschange` — plus `setPromotionField`, `setCallback('onBeforeSave')` |
| **Post-deploy / scripts** | Only From offset | Include **BOTH** From and Thru offsets; link templates to Workflow |

### Pre-Delivery Verification (Run Every Time)

- [ ] **Lead time**: Both `cgcloud__TFD_Delivery_Date_From_Offset__c` and `cgcloud__TFD_Delivery_Date_Thru_Offset__c` in design and scripts
- [ ] **Template→Workflow**: Lookup from Promotion Template → `cgcloud__Workflow__c`; templates linked to Workflow
- [ ] **cgcloud-tpm-promotion**: Document and use BOTH events (`onpromotionchange`, `ontacticschange`)
- [ ] **Requirements**: If capstone vs user stories differ on scope/region, add clarifying note

### Pitfalls to Avoid

1. **Template→Workflow Lookup** — Expert says "Create a lookup field" → implement as Custom (create if not OOB)
2. **cgcloud-tpm-promotion events** — Component emits BOTH events; subscribe to both for UI sync
3. **Thru offset** — Post-deploy scripts and metadata must include Thru offset, not just From
4. **Template→Workflow linkage** — Ensure templates are linked to Workflow in configuration

*These lessons are in your skill. Apply them whether invoked via Astro or directly.*

---

## Common Pitfalls (Additional)

See **`references/common-pitfalls.md`** and **`references/tpm-oob-expert-feedback-2026-03.md`** for more detail.

## Skill Maintenance

**Update Schedule**:
- Review pre-trained knowledge: Quarterly
- Update after CG Cloud releases: Major features
- Regenerate from NotebookLM: Source changes

**Quality Assurance**:
- Test queries with NotebookLM available and unavailable
- Validate code examples in sandbox
- Monitor query performance (<120 seconds)
- Track fallback usage frequency

---

**Version History**:
- 1.0.0 (2026-03-06): Initial release with dynamic NotebookLM integration
