# CG TPM Code Reviewer Skill

**Skill Command**: `/cg-tpm-code-reviewer`

Expert AI agent for reviewing Consumer Goods Cloud Trade Promotion Management (TPM) code. Shikha brings 10 years of experience and enforces best practices, Layer 1+4 compliance, and TPM-specific patterns.

## Quick Start

```bash
# Invoke the skill
/cg-tpm-code-reviewer

# With specific review request
/cg-tpm-code-reviewer Review this Promotion creation Apex class for best practices

# Compliance validation
/cg-tpm-code-reviewer Validate Layer 1 and Layer 4 compliance in this TPM trigger
```

## What is This?

The `/cg-tpm-code-reviewer` skill provides expert-level code review for CG Cloud TPM implementations. It combines:

1. **CG TPM Expertise**: Extends `/cg-tpm-dev` - full TPM data model, Processing Service, and business process knowledge
2. **Layer Compliance**: Enforces Layer 1 (Universal Foundation) and Layer 4 (Methodology)
3. **Best Practices**: TPM-specific patterns from cg-tpm-dev (data integrity, performance, security, error handling)
4. **10 Years Experience**: Shikha's deep expertise in CG Cloud and Trade Promotion Management

## Features

### Core Capabilities

1. **Code Review**
   - Apex (triggers, handlers, services, batch jobs)
   - LWC (cgcloud-tpm-promotion integration, event handling)
   - TPM-specific implementations (Promotion, Claim, KPI, Fund, Tactic)

2. **Compliance Validation**
   - Layer 1: Naming, governor limits, security, bulk operations, 75%+ tests
   - Layer 4: Well-Architected, Configuration-First, production-ready
   - TPM Best Practices: Data integrity, Processing Service, error handling

3. **Security & Performance**
   - CRUD/FLS enforcement
   - Bulkification (200+ records)
   - No SOQL in loops
   - Governor limit awareness
   - Processing Service optimization

4. **Structured Feedback**
   - Critical / High / Medium / Low prioritization
   - Line-by-line feedback with fix recommendations
   - Positive feedback for well-implemented patterns
   - Clear verdict (Approved / Needs Revision)

## Usage Examples

### Example 1: Review Apex Class

```
/cg-tpm-code-reviewer Review this PromotionService class for TPM best practices and Layer compliance

Expected Response:
- Structured review report
- Layer 1 + Layer 4 compliance checklist
- TPM-specific validation (Processing Service, Promotion lifecycle)
- Actionable feedback with code examples
- Verdict: Approved / Needs Revision
```

### Example 2: Validate LWC

```
/cg-tpm-code-reviewer Check this custom promotion LWC for cgcloud-tpm-promotion integration patterns

Expected Response:
- Event handling validation (onpromotionchange, ontacticschange)
- Pre-save validation pattern check
- setPromotionField/setTacticField usage
- Security and accessibility review
```

### Example 3: Processing Service Integration

```
/cg-tpm-code-reviewer Review the Processing Service integration and Batch Chain code

Expected Response:
- SF Data Sync pattern validation
- Batch chain configuration review
- Integration API usage (50 records/chunk for BO API)
- Error handling and retry logic
- Batch Run Status monitoring
```

## Integration with Other Skills

### Extends: `/cg-tpm-dev`
Inherits full TPM development expertise:
- 10 core competencies (Master Data, Promotion, CBP, Claims, KPI, RTR, etc.)
- NotebookLM integration (Tier 1) + Pre-trained knowledge (Tier 2)
- TPM data models and Processing Service patterns
- Best practices (data integrity, performance, security, error handling)

### Works With
- **`/apex-developer`**: For implementation fixes after review
- **`/lwc-developer`**: For frontend fixes after review
- **`/cg-tpm-dev`**: For development (Shikha reviews the output)

### Orchestrated By
- **`/astro`**: Multi-skill workflows, pre-merge quality gates

## When to Use

✅ **Use `/cg-tpm-code-reviewer` for**:
- Pre-merge code review of TPM implementations
- Validating Layer 1 + Layer 4 compliance
- Security and performance review of TPM code
- Best practices validation for Promotion, Claim, KPI code
- Quality gate before production deployment

❌ **Don't use for**:
- Writing new code → Use `/cg-tpm-dev` or `/apex-developer`/`/lwc-developer`
- Generic Salesforce code review → Use `/qa-engineer` for test strategy
- Architecture design → Use `/solution-architect` or `/technical-architect`

## Review Report Format

Shikha delivers structured reports with:
- **Summary**: 2-3 sentence overall assessment
- **Critical Issues**: Must fix before approval
- **High Priority**: Should fix
- **Medium Priority**: Consider
- **Positive Feedback**: What was done well
- **Compliance Checklist**: Layer 1, Layer 4, TPM
- **Verdict**: ✅ Approved / ❌ Needs Revision

## Version History

### 1.0.0 (2026-03-09)
- Initial release
- Shikha onboarded as CG TPM Code Reviewer
- Extends cg-tpm-dev with code review specialization
- 10 years experience, best practices focus

---

**Quick Reference**:
- Command: `/cg-tpm-code-reviewer`
- Extends: `/cg-tpm-dev`
- Role: Shikha - CG TPM Code Reviewer
- Experience: 10 years
- Focus: Best practices, Layer 1+4 compliance, TPM patterns
