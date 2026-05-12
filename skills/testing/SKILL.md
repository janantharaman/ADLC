# SKILL: Testing
**Phase:** 4 of 6
**Prerequisite artifact:** `engagements/{customer}/impl-summary.md` (status: APPROVED)
**Output artifact:** `engagements/{customer}/testing.md`
**Evaluation output:** `engagements/{customer}/evaluation/testing-evaluation.json`

---

## Purpose

Verify that what was built matches what was designed and that it works correctly at scale. This phase does not find out whether the requirements were right — that is Discovery and Design's job. This phase verifies that the implementation is correct, complete, and safe to deploy to production.

All Salesforce operations use Headless 360 MCP tools exclusively. Never use Bash or the sf CLI for org operations.

---

## Before You Start

1. Read `engagements/{customer}/memory/core-memory.md`
2. Read `engagements/{customer}/impl-summary.md` — know what was built and any known issues
3. Read `engagements/{customer}/design.md` — test acceptance criteria trace back to design decisions
4. Read `knowledge/governor-limits.md` — test execution must not trigger limit violations
5. **Cloud-Specific Context:** Check `core-memory.md` for the cloud(s) in scope. Load the relevant cloud primer(s) — test data factories and test assertions must use correct object and field API names:
   - Sales Cloud → `knowledge/clouds/sales-cloud/*.md`
   - Service Cloud → `knowledge/clouds/service-cloud/*.md`
   - Experience Cloud → `knowledge/clouds/experience-cloud/*.md`
   - Consumer Goods Cloud → `knowledge/clouds/consumer-goods-cloud/*.md`
   - Life Sciences Cloud → `knowledge/clouds/life-sciences-cloud/*.md`
   - Financial Services Cloud → `knowledge/clouds/financial-services-cloud/*.md`
   - Health Cloud → `knowledge/clouds/health-cloud/*.md`
   - Revenue Cloud → `knowledge/clouds/revenue-cloud/*.md`
   - Automotive Cloud → `knowledge/clouds/automotive-cloud/*.md`
   - Manufacturing Cloud → `knowledge/clouds/manufacturing-cloud/*.md`
   Load all cloud primers that apply.
6. **Customer documents:** Check if `engagements/{customer}/docs/` exists. If it does, read `engagements/{customer}/docs/index.md` first, then read any documents marked as relevant to Testing (acceptance criteria docs, UAT scripts, test data specifications).
   Also read `knowledge/sdd-template.md` section **Appendix: Testing** — the `testing.md` artifact populates the SDD Testing appendix (Unit testing methodology, SIT test cases, Regression test cases, UAT plan and results, Go Live Readiness checklists).
7. Confirm the sandbox org alias with the user before running any tests
8. Append to `workflow-memory.md`: session start, test scope, components under test
9. **Knowledge fallback:** If at any point during this phase you need a specific detail not covered by the reference files (e.g., a test framework method, Jest API, coverage calculation behaviour), use `WebSearch` before making an assumption. Prefer results from `trailhead.salesforce.com`, `developer.salesforce.com`, and `github.com/trailheadapps`. Do not guess — search first.

---

## Step 1 — Apex Test Execution

Run all Apex test classes in the org.

**Tool:** `mcp__salesforce__run_apex_test`

```
Run all Apex test classes
Target org: {sandbox alias}
```

Review results:
- Overall code coverage percentage — must be ≥ 75% org-wide (Salesforce minimum) and ≥ 90% for all new classes (GDC standard)
- Any test failures — investigate each failure before proceeding
- Any test classes with 0% coverage on non-test production classes — flag these

For each test failure, append to `workflow-memory.md`:
```
TEST FAILURE: {class}.{method}
Error: {message}
Root cause assessment: {your analysis}
Fix required: yes / no
```

### Test class standards to verify

Reference `skills/testing/references/apex-testing/test-helper.md` and `skills/testing/references/apex-testing/test-double.md` to verify the test classes follow these patterns:

- Test data is created within the test using `@TestSetup` or test data factories — no reliance on org data
- Reference `skills/testing/references/apex-testing/data-factory-for-package-installs.md` for the data factory pattern
- Tests use `Test.startTest()` / `Test.stopTest()` to isolate governor limit consumption
- Async Apex tests call `Test.stopTest()` to force async execution before assertions
- Tests assert specific field values — not just that no exception was thrown
- Negative tests exist for expected error conditions
- Bulk tests exist for any trigger handler (test with 200+ records)

### Stub and mock patterns

For tests that call external services, verify mocks are in place:
- Reference `skills/testing/references/apex-testing/stub-example.md` for the `StubProvider` pattern
- Reference `skills/testing/references/apex-testing/stub-example-consumer.md` for the consumer pattern
- `HttpCalloutMock` must be set for any test covering callout code

---

## Step 2 — Agentforce Agent Tests (if applicable)

If the implementation includes Agentforce Agents:

**Tool:** `mcp__salesforce__run_agent_test`

```
Run agent test suite
Target org: {sandbox alias}
```

Review results:
- All test conversations pass their expected outcomes
- No hallucinated API names or field references
- Topic routing is deterministic for all test inputs

---

## Step 3 — LWC Jest Tests

For each new LWC component, verify Jest test files exist and cover the key paths.

Reference `skills/testing/references/lwc-testing/apex-wire-jest-test.md` and `skills/testing/references/lwc-testing/apex-imperative-jest-test.md` for the expected test structure.

For each component, verify:
- Happy path: component renders correctly with expected data
- Empty/null data: component handles missing wire data gracefully
- Error state: component handles wire/imperative errors and shows user-facing message
- Event handling: dispatched custom events are tested
- Wire mock: `@wire` adapters use `registerLdsTestWireAdapter` or `registerApexTestWireAdapter`

To run Jest tests, ask the user to run:
```
npm run test:unit
```
and share the output. Do not run this via Bash — it requires the Node.js environment in the project.

---

## Step 4 — Code Quality Analysis

**Tool:** `mcp__salesforce__run_code_analyzer`

```
Run code analyzer on all new Apex classes and triggers from this implementation
Target org: {sandbox alias}
```

Any HIGH or CRITICAL findings on new code are blocking — they must be resolved before the gate.

Compare findings to the discovery code quality baseline in `engagements/{customer}/discovery.md` — new code must not introduce findings that did not exist pre-engagement.

---

## Step 5 — Functional Verification

For each requirement in the design, verify the acceptance criteria manually using Headless 360 tools.

**Tool:** `mcp__salesforce__run_soql_query`

For each requirement:
```
Requirement: {REQ-ID} — {Name}
Acceptance criteria: {from design.md}
Verification method: [SOQL query / deploy / manual test]
Result: PASS | FAIL
Evidence: [query result or observation]
```

For trigger logic verification:

**Tool:** `mcp__salesforce__deploy_metadata`

Deploy test data via anonymous Apex (ask user to execute in Developer Console if needed) and query results.

---

## Step 6 — Validation Deploy (Pre-Production Check)

**Tool:** `mcp__salesforce__deploy_metadata` (checkOnly: true)

Run a checkOnly deploy targeting production (or the staging sandbox that mirrors production):

```
checkOnly: true
All components from impl-summary.md
Target org: {production or staging org alias}
```

Present full results to user. Any validation failure is a blocker.

---

## Step 7 — Write Testing Artifact

Write `engagements/{customer}/testing.md`:

```markdown
# Testing — {Customer Name}
**Status:** DRAFT
**Date:** {today}
**Version:** 1
**Org:** {sandbox alias}
**Implementation artifact:** engagements/{customer}/impl-summary.md

## Summary
[2-3 sentences: overall test pass rate, coverage, any open issues]

## Apex Test Results

### Coverage
- Org-wide coverage: {N}%
- New class coverage: {list with %}
- Classes below 90%: {list or "None"}

### Test Failures
| Test Class | Test Method | Error | Status |
|---|---|---|---|

### Test Quality Observations
[Any tests that pass but are weak — no assertions, no bulk coverage, etc.]

## LWC Jest Results
| Component | Tests | Pass | Fail | Notes |
|---|---|---|---|---|

## Code Quality
- New HIGH/CRITICAL findings: {N}
| Finding | Class | Severity | Resolved? |
|---|---|---|---|

## Functional Verification
| REQ-ID | Requirement | Acceptance Criteria | Result | Evidence |
|---|---|---|---|---|

## Validation Deploy
- Target: {org}
- Result: PASS | FAIL
- Errors: [list or "None"]

## Open Issues
[Anything that failed or is unresolved, with severity and proposed resolution]

## Evaluation
- Score: N/100
- Gate: PASS | FAIL
- Blocking findings: [list or "None"]
```

---

## Step 8 — Evaluate and Emit Gate

1. Score the artifact against the evaluation rubric (see CLAUDE.md)
2. Write `engagements/{customer}/evaluation/testing-evaluation.json`
3. Run memory consolidation:
   - Promote durable learnings to `core-memory.md` (test patterns that worked, coverage gaps, deployment issues)
   - Clear `workflow-memory.md` back to empty template
4. Emit the gate:

```
[WAITING_FOR_APPROVAL]

**Testing complete for {Customer Name}**
Artifact: engagements/{customer}/testing.md
Evaluation score: {N}/100 — {PASS/FAIL}

Summary: {1-paragraph summary of test results and open issues}

Blocking issues requiring resolution before Deployment:
{numbered list or "None"}

Please respond:
- APPROVED — to proceed to Phase 5: Deployment
- REVISE: [your feedback] — to address testing issues
```

---

## References

### Apex Testing Patterns
- `skills/testing/references/apex-testing/test-helper.md` — utility for class-type detection in tests
- `skills/testing/references/apex-testing/test-double.md` — test double (mock) pattern using StubProvider
- `skills/testing/references/apex-testing/stub-example.md` — stub implementation pattern
- `skills/testing/references/apex-testing/stub-example-consumer.md` — how consumer classes use stubs
- `skills/testing/references/apex-testing/data-factory-for-package-installs.md` — test data factory pattern

### LWC Testing Patterns
- `skills/testing/references/lwc-testing/apex-wire-jest-test.md` — Jest test for wired Apex method
- `skills/testing/references/lwc-testing/apex-imperative-jest-test.md` — Jest test for imperative Apex call

### Knowledge Base
- `knowledge/governor-limits.md` — limits to verify in test execution
- `knowledge/security-baseline.md` — security assertions to include in tests
