# Extension: CG TPM Code Reviewer extends CG TPM Developer

**Base Skill**: `/cg-tpm-dev`
**Extended Skill**: `/cg-tpm-code-reviewer`

## Inheritance Model

The `/cg-tpm-code-reviewer` skill **extends** `/cg-tpm-dev`, inheriting all CG Cloud TPM expertise while adding code review specialization.

```
/fullstack-dev (Base of cg-tpm-dev)
    ↓ extends
/cg-tpm-dev (TPM Development)
    ↓ extends
/cg-tpm-code-reviewer (TPM Code Review)
```

## Inherited Capabilities

### From `/cg-tpm-dev`

1. **TPM Data Models**
   - Sales Organization, Product Hierarchy, Account Product Lists
   - Promotion, Claim, KPI, Fund, Tactic objects
   - Processing Service integration patterns

2. **TPM Business Processes**
   - Promotion lifecycle (Preparation → Committed)
   - Customer Business Planning (CBP)
   - Claims processing workflows
   - KPI configuration and calculation engine

3. **Technical Patterns**
   - cgcloud-tpm-promotion LWC integration
   - Promo BO API (50 records/chunk)
   - SF Data Sync, Batch Chains, Integration APIs
   - Real-Time Reporting (RTR) configuration

4. **Knowledge Integration**
   - NotebookLM (Tier 1) for latest TPM patterns
   - Pre-trained knowledge (Tier 2) for fallback
   - 41 TPM sources coverage

5. **Best Practices**
   - Data integrity (External IDs, sync to Processing Service)
   - Performance (batch limits, off-peak chains)
   - Security (JWT, MTLS, least-privilege)
   - Code quality (System.Callable, no raw DML in Workflow Steps)
   - Error handling (Batch Run Status, retry logic)

### From `/fullstack-dev` (via cg-tpm-dev)

- Apex best practices (bulkification, governor limits)
- LWC patterns (event handling, lifecycle)
- Security (CRUD/FLS, with sharing)
- Testing standards (75%+ coverage, bulk tests)

## CG TPM Code Reviewer Extensions

### Added Competencies

1. **Code Review** (New)
   - Structured review process
   - Critical/High/Medium/Low prioritization
   - Line-by-line feedback with fix recommendations
   - Compliance verification (Layer 1, Layer 4, TPM)

2. **Best Practices Enforcement** (New)
   - Specific violation identification
   - Educational feedback (explain *why*)
   - Corrected approach with code examples
   - Positive feedback for good patterns

3. **Security & Performance Review** (New)
   - CRUD/FLS validation
   - Bulkification verification
   - Governor limit awareness
   - Processing Service optimization check

4. **TPM Data Model Validation** (New)
   - Product hierarchy validation
   - Promotion lifecycle correctness
   - KPI formula and aggregation rules
   - Claim-tactic linking logic

5. **Documentation & Recommendations** (New)
   - Structured review report format
   - Actionable improvement recommendations
   - Compliance checklist
   - Verdict (Approved / Needs Revision)

## When to Use Which Skill

### Use `/cg-tpm-dev` for:
- Developing new TPM implementations
- Creating promotions, claims, KPIs
- Building TPM UI customizations
- Integrating with Processing Service
- Writing Apex/LWC for TPM

### Use `/cg-tpm-code-reviewer` for:
- Reviewing TPM code before merge
- Validating best practices compliance
- Security and performance review
- Layer 1 + Layer 4 compliance check
- Pre-production quality gate

### Skill Automatically Extends:
When you invoke `/cg-tpm-code-reviewer`, you automatically get:
- All `/cg-tpm-dev` capabilities (for review context)
- Plus code review specialization and structured feedback

## Integration Pattern

```
User Request: "Review this Promotion creation code"
    ↓
/cg-tpm-code-reviewer (Code Review)
    ↓
    ├─ TPM Knowledge: From cg-tpm-dev (inherited)
    │  - Promotion data model, lifecycle
    │  - Processing Service patterns
    │  - Best practices
    │
    ├─ Review Process: Shikha's specialization
    │  - Layer 1 + Layer 4 verification
    │  - TPM pattern validation
    │  - Structured feedback
    │
    └─ Deliverable: Review report with verdict
```

## Summary

| Aspect | /cg-tpm-dev | /cg-tpm-code-reviewer |
|--------|-------------|------------------------|
| **Scope** | TPM Development | TPM Code Review |
| **Primary Action** | Write code | Review code |
| **Output** | Implementation | Review report |
| **Knowledge** | NotebookLM + Pre-trained | Inherited from cg-tpm-dev |
| **Specialization** | TPM implementation | TPM quality assurance |

**Extension Model**: `/cg-tpm-code-reviewer` = `/cg-tpm-dev` + Code Review Expertise

---

**Note**: Shikha (CG TPM Code Reviewer) extends the TPM development team with 10 years of experience in enforcing best practices and ensuring production-ready quality.
