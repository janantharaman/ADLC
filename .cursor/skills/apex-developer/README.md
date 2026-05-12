# Apex Developer Skill

Expert Salesforce Apex developer skill for Cursor IDE.

## Usage

Invoke the skill in Cursor using:
```
/apex-dev
```

## What This Skill Provides

- **Expert Apex Development**: 10+ years experience building enterprise Salesforce solutions
- **Trigger Framework**: Complete trigger handler pattern with bulkification
- **Governor Limits**: Deep awareness of Salesforce limits and optimization strategies
- **Best Practices**: Security (CRUD/FLS), testing (75%+ coverage), async patterns
- **Code Standards**: Service layer pattern, selector pattern, error handling
- **🆕 NotebookLM Integration**: Dynamic knowledge retrieval for Well-Architected patterns, accessibility standards, and security patterns

## Included Resources

### Reference Materials (`./references/`)
- **trigger-framework-pattern.md**: Complete trigger handler implementation
- **bulkification-examples.md**: Before/after bulkification patterns
- **governor-limits-reference.md**: Quick reference for all Salesforce limits

### Utility Scripts (`./scripts/`)
- **analyze-apex-complexity.sh**: Automated code complexity analysis using PMD

### Shared Knowledge (`../_shared/`)
- **notebooklm-knowledge.md**: NotebookLM integration pattern for dynamic knowledge retrieval

## Core Competencies

- Trigger Development (handler pattern, bulkification, recursion prevention)
- Asynchronous Apex (@future, Queueable, Batch, Scheduled)
- Integration (REST/SOAP APIs, callouts, named credentials)
- Database Operations (DML, SOQL/SOSL optimization)
- Testing (75%+ coverage, bulk testing, test data factories)

## Communication Style

This skill is designed for **expert Salesforce developers**:
- Concise responses, no beginner explanations
- Code-first approach with minimal prose
- Best-practice focused
- Proactive warnings about gotchas and performance

## When to Delegate

- Data modeling → `/architect` (Solution Architect)
- LWC integration → `/lwc-dev` (LWC Developer)
- Deployment → `/devops` (DevOps Engineer)
- Security architecture → `/security` (Security Specialist)

## Example Use Cases

1. **Create trigger with bulkification**
   ```
   /apex-dev
   "Create a trigger to update related Contacts when Account rating changes"
   ```

2. **Implement batch job**
   ```
   /apex-dev
   "Create a batch job to process 100,000 Account records and update Industry field"
   ```

3. **Build REST API**
   ```
   /apex-dev
   "Create a REST endpoint to accept JSON and create/update Orders"
   ```

4. **Optimize existing code**
   ```
   /apex-dev
   "Review this trigger and fix any governor limit issues"
   ```

5. **🆕 Create accessible form with best practices**
   ```
   /apex-dev
   "Create an Account form handler with accessibility support"
   ```
   → The skill will query NotebookLM for accessibility patterns and apply them

6. **🆕 Implement secure session management**
   ```
   /apex-dev
   "Implement login tracking with session security"
   ```
   → The skill will query NotebookLM for session security patterns

7. **🆕 Transaction Finalizers for guaranteed logging**
   ```
   /apex-dev
   "Create a Queueable job with guaranteed logging that runs even if the job fails"
   ```
   → Uses Transaction Finalizers (Winter '23+) for reliable post-transaction cleanup

8. **🆕 USER_MODE for HIPAA-compliant data access**
   ```
   /apex-dev
   "Create a service to query patient records with HIPAA-compliant access logging"
   ```
   → Uses WITH USER_MODE (Spring '23+) for compliance auditing

9. **🆕 StubProvider for fast unit tests**
   ```
   /apex-dev
   "Create unit tests for AccountService using StubProvider without DML"
   ```
   → Uses StubProvider (Winter '23+) for 10-100x faster tests

## Running the Complexity Analyzer

```bash
cd /Users/ronit.mukherjee/projects/cursor_workflow_orchestartion
./.cursor/skills/apex-developer/scripts/analyze-apex-complexity.sh force-app
```

This will:
- Install PMD if not present
- Analyze all Apex code for complexity, security, and performance issues
- Check for common anti-patterns (SOQL in loops, DML in loops, hardcoded IDs)
- Provide recommendations

## Testing the Skill

To test this skill:
1. Open Cursor IDE in this project
2. Type `/apex-dev` to invoke the skill
3. Provide a Salesforce Apex development task
4. Verify the agent provides expert-level Apex code with proper bulkification and best practices

## Next Steps

After validating this skill:
1. Create foundation rules (`.cursor/rules/00-salesforce-foundation.md`)
2. Implement additional skills (LWC Developer, Solution Architect)
3. Configure Salesforce MCP server for real-time org metadata access
4. Add company-specific coding standards
