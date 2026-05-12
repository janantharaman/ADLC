# CG Cloud TPM Developer Skill

**Skill Command**: `/cg-tpm-dev`

Expert AI agent for Consumer Goods Cloud Trade Promotion Management (TPM) development with dynamic NotebookLM integration for always-current guidance.

## Quick Start

```bash
# Invoke the skill
/cg-tpm-dev

# With specific request
/cg-tpm-dev How do I create a promotion?

# Complex scenario
/cg-tpm-dev Set up product hierarchy for beverages with automatic APL
```

## What is This?

The `/cg-tpm-dev` skill provides expert-level guidance for developing CG Cloud TPM solutions. It combines:

1. **Live Knowledge** (Tier 1): Real-time queries to NotebookLM with 41 CG TPM sources
2. **Pre-Trained Knowledge** (Tier 2): Offline baseline knowledge for graceful fallback
3. **Salesforce Best Practices**: Inherits from `/fullstack-dev` skill

## Features

### Dynamic Knowledge Integration

The skill uses a two-tier approach:

**✓ From NotebookLM (latest)**:
- When NotebookLM is available
- Queries 41 sources for latest information
- Combines live knowledge with implementation patterns

**⚠️ Pre-trained knowledge**:
- When NotebookLM is unavailable
- Uses baseline knowledge from 2026-03-06 snapshot
- Still provides complete expert guidance

### Core Capabilities

1. **Master Data Management**
   - Sales Organization configuration
   - Product hierarchies (Category → Brand → SKU)
   - Account hierarchies and customer extensions
   - Product assortments (Global vs Time-Dependent)

2. **Trade Promotion Management**
   - Promotion lifecycle (Preparation → Committed)
   - Volume and spend planning
   - Tactic management and fund linking
   - Trade Calendar customization

3. **Customer Business Planning**
   - CBP creation and configuration
   - Baseline adjustments
   - Scenario planning (up to 5 scenarios)
   - P&L management

4. **Claims Processing**
   - Claim types (Deductions, check requests, credit memos)
   - Tactic linking
   - Claim adjustments (splitting, replacement, reversal)
   - Approval workflows

5. **KPI Configuration**
   - KPI types (Read, Calculated, Editable, Compound, Validation)
   - Formula design with aggregation rules
   - KPI Sets for specific usage
   - Writeback configuration for RTR

6. **Real-Time Reporting**
   - RTR component configuration
   - Layout design (Flat Lists, Scorecards, Gauges, Progress Bars)
   - Lightning App Builder integration

7. **Processing Engine Integration**
   - Data synchronization to Processing Service
   - Batch chain configuration and execution
   - Integration APIs (time-based, weekly, daily data)
   - Batch monitoring and error handling

8. **UI Customization**
   - Lightning Web Components for promotion UI
   - Event handling (`onpromotionchange`, `ontacticschange`)
   - Pre-save validation with callbacks
   - Backend customization with System.Callable

9. **Promo BO API**
   - External system integration
   - Bulk promotion creation (50 records/chunk)
   - Custom Workflow Steps
   - Aura component integration

10. **Metadata Wizard**
    - Dynamic form configuration
    - Expression-driven behavior
    - Localization support
    - Dry run testing

## Usage Examples

### Example 1: Create Promotion

```
/cg-tpm-dev Create a Q1 beverage promotion with 15% discount for national accounts

Expected Response:
✓ From NotebookLM (latest):
[Promotion creation workflow with latest patterns]

Implementation Pattern (pre-trained):
[Apex code example for promotion creation]
[LWC code for UI customization]
[BO API pattern for bulk creation]
```

### Example 2: Configure KPIs

```
/cg-tpm-dev Configure ROI KPI with formula and writeback for RTR

Expected Response:
✓ From NotebookLM (latest):
[KPI configuration steps]
[Formula definition]
[Writeback setup]

Implementation (pre-trained):
[Apex code for KPI calculation]
[Integration API example]
```

### Example 3: Process Claims

```
/cg-tpm-dev Set up automated claim processing from SAP ERP

Expected Response:
✓ From NotebookLM (latest):
[Claim processing workflow]
[ERP integration pattern]

Implementation (pre-trained):
[Apex handler for interfaced claims]
[Tactic linking logic]
[Approval process configuration]
```

### Example 4: Fallback Mode

```
[NotebookLM unavailable]
/cg-tpm-dev How do I set up product hierarchy?

Expected Response:
⚠️ Using pre-trained CG TPM knowledge (NotebookLM unavailable)

Product Hierarchy Setup:
[Workflow from baseline knowledge]

Implementation:
[Apex code for hierarchy creation]
[Data sync configuration]

Note: For latest updates, check NotebookLM when available.
```

## Knowledge Sources

### Tier 1: NotebookLM (Live)
- **Notebook**: "Industry Knowledge Base: CG TPM"
- **ID**: `9ca50af3-1937-43a6-87c4-3d8629a1ccbd`
- **Sources**: 41 documents covering TPM architecture, data models, processes
- **Updated**: Regularly

### Tier 2: Pre-Trained (Baseline)
- **Snapshot Date**: 2026-03-06
- **Location**: `knowledge/` directory
- **Files**:
  - `data-models.md` - Core TPM objects
  - `business-processes.md` - 5 major processes
  - `technical-patterns.md` - 5 implementation patterns
  - `integration-patterns.md` - ERP, POS, API patterns
  - `use-cases.md` - Common development scenarios
  - `notebooklm-integration.md` - Integration guide
  - `config.json` - Configuration

## Architecture

```
User Request: /cg-tpm-dev How do I create a promotion?
    ↓
Analyze Request (Implementation pattern needed)
    ↓
Try NotebookLM Query (Tier 1)
    ↓
    ├─ Available: ✓ From NotebookLM (latest)
    │               ↓
    │          [Latest promotion workflow]
    │               ↓
    │          Combine with pre-trained code patterns
    │               ↓
    │          Complete implementation guide
    │
    └─ Unavailable: ⚠️ Pre-trained knowledge
                    ↓
               [Baseline promotion workflow]
                    ↓
               Complete implementation guide
```

## Integration with Other Skills

### Extends: `/fullstack-dev`
Inherits Salesforce best practices:
- Security patterns
- Governor limit management
- Testing standards
- LWC development standards

### Delegates To
- **`/apex-developer`**: Complex Apex logic
- **`/lwc-developer`**: Advanced UI customization
- **`/solution-architect`**: Architecture decisions

### Orchestrated By
- **`/astro`**: Multi-skill workflows, delegation logic

## Best Practices

### When to Use This Skill

✅ **Use `/cg-tpm-dev` for**:
- Anything related to CG Cloud TPM
- Promotions, claims, funds, KPIs
- Product/account hierarchies
- Processing Engine integration
- TPM-specific UI customization

❌ **Don't use for**:
- Generic Salesforce development → Use `/fullstack-dev`
- Non-TPM CG Cloud features → Use `/fullstack-dev`
- Architecture only → Use `/solution-architect`

### Performance Tips

1. **Query Efficiency**: NotebookLM queries complete in <120 seconds
2. **Conversation Context**: Use follow-up questions to maintain conversation_id
3. **Offline Development**: Pre-trained knowledge works without NotebookLM
4. **Code Examples**: All examples are production-ready patterns

### Troubleshooting

**Issue**: NotebookLM unavailable
- **Solution**: Skill automatically falls back to pre-trained knowledge
- **Action**: None required, guidance still provided

**Issue**: Outdated information in pre-trained knowledge
- **Solution**: Query NotebookLM for latest updates
- **Action**: Pre-trained updated quarterly

**Issue**: Query timeout (>120 seconds)
- **Solution**: Automatic fallback to pre-trained
- **Action**: Check NotebookLM authentication if persistent

## Maintenance

### Update Schedule
- **Pre-trained knowledge**: Quarterly review
- **After CG Cloud releases**: Regenerate if major features
- **NotebookLM sources added**: Re-extract knowledge

### Quality Metrics
- **Query Success Rate**: Target >95%
- **Average Response Time**: Target <120s
- **Fallback Usage**: Monitor frequency
- **Code Example Quality**: Production-ready

## Technical Details

### Technologies
- **Platform**: Salesforce CG Cloud
- **Backend**: Processing Service (Hyperforce)
- **Languages**: Apex, JavaScript (LWC), SOQL
- **APIs**: REST (Integration APIs, Promo BO API)
- **Security**: JWT, MTLS
- **Middleware**: MuleSoft Accelerator

### Knowledge Base Size
- **Data Models**: 8 core objects
- **Business Processes**: 5 major workflows
- **Technical Patterns**: 5 implementation patterns
- **Integration Patterns**: 4 external systems
- **Use Cases**: 5 common scenarios
- **Total**: 41 NotebookLM sources

## Getting Help

### Documentation
- **Knowledge Base**: See `knowledge/` directory
- **Integration Guide**: `knowledge/notebooklm-integration.md`
- **Configuration**: `knowledge/config.json`

### Support
- **Skill Issues**: Check NotebookLM authentication
- **Outdated Information**: Update pre-trained knowledge
- **Feature Requests**: Add to NotebookLM sources

## Version History

### 1.0.0 (2026-03-06)
- Initial release
- Dynamic NotebookLM integration (41 sources)
- Pre-trained baseline knowledge
- Two-tier knowledge strategy
- Graceful fallback implementation

---

**Quick Reference**:
- Command: `/cg-tpm-dev`
- Extends: `/fullstack-dev`
- Knowledge: NotebookLM + Pre-trained
- Sources: 41 TPM documents
- Updated: 2026-03-06
