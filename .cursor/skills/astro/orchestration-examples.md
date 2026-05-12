# Agent Astro: Orchestration Examples

## Example 1: Backend + Frontend (Parallel)

**Scenario**: "Build customer portal"

**Architectural Context**:
- Data model: Case, Contact
- API: GET /cases, POST /cases
- Security: Portal user sharing rules

**Parallel Agents**:
1. /apex-dev → REST API
2. /lwc-dev → Portal UI

**Integration Validation**:
- Verify: API endpoints match LWC calls
- Verify: Error responses handled in UI
- Verify: Security consistent (backend + frontend)

---

## Example 2: Architecture + Implementation (Sequential)

**Scenario**: "Design and build order processing"

**Workflow**:
1. /architect → Solution design
2. [User approval]
3. Parallel: /apex-dev + /lwc-dev → Implementation

**Why sequential first**: Architecture decisions inform implementation

---

## Example 3: Triple Parallel (Advanced)

**Scenario**: "Build integration with testing"

**Parallel Agents**:
1. /apex-dev → Backend integration
2. /lwc-dev → Admin UI for integration
3. /qa → Test automation scripts

**Shared Context**:
- Integration spec (endpoints, auth, error codes)
- UI requirements
- Test scenarios

---

## Integration Validation Patterns

### Pattern 1: API Contract Matching
```
Backend declares: POST /api/orders
Frontend calls:   POST /api/orders
✅ Match

Backend returns: {orderId: "123", status: "success"}
Frontend expects: {orderId: string, status: string}
✅ Match
```

### Pattern 2: Error Handling Alignment
```
Backend throws: OrderValidationException
Backend returns: {error: "Invalid quantity", code: "ORD-001"}
Frontend catches: {error: string, code: string}
Frontend displays: Error message to user
✅ Aligned
```

### Pattern 3: Security Consistency
```
Backend enforces: CRUD/FLS checks on Order
Frontend enforces: Hide "Delete" if no Delete permission
Testing includes: Verify permission checks work
✅ Consistent
```

---

## Detailed Example: Customer Portal for Case Management

### User Request
```
/astro "Build customer portal with case management"
```

### Phase 1: Requirement Analysis
Astro identifies:
- Complexity: High (backend + frontend + security)
- Experts needed: Backend (/apex-dev) + Frontend (/lwc-dev)
- Approach: Parallel execution after architecture approval

### Phase 2: Clarifying Questions
```
Q1: What case operations do portal users need?
    A) View only
    B) View + Create
    C) View + Create + Update

Q2: Who are the portal users?
    A) Customers (external)
    B) Partners (external)
    C) Internal employees

Q3: What security requirements?
    A) Users see only their own cases
    B) Users see cases for their account
    C) Custom sharing rules
```

### Phase 3: Architectural Context Creation

**User answers**: B (View + Create), A (Customers), A (Own cases only)

**Astro creates**:
```markdown
# Architectural Context: Customer Portal - Case Management

## Data Model
- Objects: Case, Contact, User (Portal)
- Relationships: Case.ContactId → Contact.Id
- Custom fields:
  - Case.Portal_Status__c (Text): Open, In Progress, Closed
  - Case.Portal_Priority__c (Picklist): Low, Medium, High
  - Case.Visible_to_Portal__c (Checkbox): true for portal-visible cases

## API Contracts

### GET /services/apexrest/cases
**Purpose**: Retrieve cases for authenticated portal user
**Request**: No body (user context from session)
**Response**:
```json
{
  "cases": [
    {
      "id": "500xxx",
      "caseNumber": "00001234",
      "subject": "Need help with product",
      "status": "Open",
      "priority": "Medium",
      "createdDate": "2024-01-15T10:30:00Z",
      "description": "Product not working as expected"
    }
  ],
  "total": 5
}
```
**Errors**:
- 401: Unauthorized (not logged in)
- 403: Forbidden (no portal access)

### POST /services/apexrest/cases
**Purpose**: Create new case for portal user
**Request**:
```json
{
  "subject": "Case subject",
  "description": "Detailed description",
  "priority": "Medium"
}
```
**Response**:
```json
{
  "id": "500xxx",
  "caseNumber": "00001235",
  "message": "Case created successfully"
}
```
**Errors**:
- 400: Bad Request (validation failed)
- 401: Unauthorized
- 500: Internal error

### PUT /services/apexrest/cases/{caseId}
**Purpose**: Update existing case (status only)
**Request**:
```json
{
  "status": "In Progress"
}
```
**Response**:
```json
{
  "id": "500xxx",
  "status": "In Progress",
  "message": "Case updated successfully"
}
```
**Errors**:
- 400: Bad Request (invalid status)
- 401: Unauthorized
- 403: Forbidden (not case owner)
- 404: Not Found (case doesn't exist)

## Security Requirements

### Sharing Model
- OWD: Private for Case object
- Portal User Access: Contact.AccountId sharing rule
- Visibility: Only cases where Case.ContactId = User.ContactId

### CRUD/FLS
- Portal users can:
  - Create: Case (Subject, Description, Priority fields only)
  - Read: Case (all fields)
  - Update: Case (Status field only, no other fields)
  - Delete: Not allowed

### Session Security
- Portal users: Community license
- Authentication: Standard Salesforce login
- Session timeout: 2 hours
- IP restrictions: None (public portal)

## Business Rules

### Case Creation
- Required fields: Subject (min 5 chars), Description (min 10 chars)
- Priority: Default to "Medium" if not specified
- Status: Auto-set to "Open" on creation
- Owner: Auto-assign to portal support queue

### Case Updates
- Portal users can only update Status field
- Valid status transitions: Open → In Progress → Closed
- Cannot reopen closed cases
- Last Modified By: Track portal user updates

### Case Visibility
- Portal users see only cases where ContactId matches their contact record
- Cases without ContactId are never visible to portal users
- Deleted cases not returned in API

## Error Handling Standards

### Backend (Apex)
- Validation errors: Return 400 with {error: string, code: string}
- Permission errors: Return 403 with {error: string}
- Not found: Return 404 with {error: string}
- System errors: Return 500 with {error: "System error", code: "SYS-001"}

### Frontend (LWC)
- Display error messages using lightning-toast
- Validation errors: Show inline on form fields
- Network errors: Show retry button
- Loading states: Show spinner during API calls
```

### Phase 4: Architecture Approval
```
[AskUserQuestion widget]

"I've created the architectural context for the customer portal.

SUMMARY:
- Data Model: Case with custom fields for portal
- APIs: GET /cases (list), POST /cases (create), PUT /cases/:id (update status)
- Security: Portal users see only their own cases
- Business Rules: Status transitions, validation rules

Review the architectural context above. Ready to proceed with parallel implementation?"

Options:
1. "Approve - proceed with parallel implementation" (Recommended)
2. "Modify architecture first"
3. "Show me more details"
```

### Phase 5: Parallel Agent Execution

**User approves** → Astro spawns 2 agents simultaneously:

**Agent 1 (Backend - /apex-dev)**:
```
Prompt:
"You are acting as the Apex Developer skill (/apex-dev).
Read .cursor/skills/apex-developer/SKILL.md to understand your persona and patterns.

ARCHITECTURAL CONTEXT:
[Full context document from above]

YOUR TASK:
Implement the backend REST API for case management with these endpoints:
1. GET /services/apexrest/cases - List cases for authenticated portal user
2. POST /services/apexrest/cases - Create new case
3. PUT /services/apexrest/cases/{caseId} - Update case status

REQUIREMENTS:
- Follow trigger handler framework
- Bulkify all operations (handle 200+ records)
- Implement CRUD/FLS security checks
- Return proper HTTP status codes and error responses
- 75%+ test coverage including bulk tests
- Handle all error scenarios from architectural context

DELIVERABLES:
1. CaseRestController.cls (REST API class)
2. CaseService.cls (Business logic)
3. CaseRestController_Test.cls (Test class with 75%+ coverage)
4. Error handling for all scenarios
"

Executes independently...
```

**Agent 2 (Frontend - /lwc-dev)**:
```
Prompt:
"You are acting as the LWC Developer skill (/lwc-dev).
Read .cursor/skills/lwc-developer/SKILL.md to understand your persona and patterns.

ARCHITECTURAL CONTEXT:
[Same context document as Agent 1]

YOUR TASK:
Build portal UI components for case management:
1. caseList - Display list of cases for portal user
2. caseForm - Create new case
3. caseDetail - View and update single case

REQUIREMENTS:
- Consume REST APIs: GET /services/apexrest/cases, POST /services/apexrest/cases, PUT /services/apexrest/cases/{id}
- Follow SLDS design patterns
- Implement accessibility (ARIA, keyboard navigation)
- Handle all error responses from backend
- Show loading states during API calls
- Use lightning-toast for success/error messages

DELIVERABLES:
1. caseList component (JS, HTML, CSS)
2. caseForm component (JS, HTML, CSS)
3. caseDetail component (JS, HTML, CSS)
4. Jest tests for all components
5. Error handling for all API scenarios
"

Executes independently...
```

**Both agents run in parallel** ← KEY CAPABILITY

### Phase 6: Integration Validation

**After both agents complete**, Astro validates:

**Check 1: API Contract Matching**
```
Backend CaseRestController:
  @HttpGet
  GET /services/apexrest/cases
  Returns: {"cases": [...], "total": 5}

Frontend caseList.js:
  fetch('/services/apexrest/cases')
  Expects: {cases: [], total: number}

✅ Match - Endpoint and schema compatible
```

**Check 2: Error Response Handling**
```
Backend error format:
  400: {error: "Subject is required", code: "VAL-001"}
  403: {error: "Access denied"}
  500: {error: "System error", code: "SYS-001"}

Frontend caseForm.js:
  .catch(error => {
    const {error: message, code} = error;
    this.showToast(message, 'error');
  })

✅ Aligned - Frontend handles all backend error formats
```

**Check 3: Security Consistency**
```
Backend CaseRestController:
  Checks: CRUD/FLS on Case object
  Filters: Cases where ContactId = currentUser.ContactId

Frontend caseList.js:
  No client-side security (trusts backend)
  Calls API without additional filtering

✅ Consistent - Backend enforces security, frontend trusts backend
```

**Check 4: Business Rules**
```
Backend CaseService:
  Status transitions: Open → In Progress → Closed
  Cannot reopen closed cases

Frontend caseDetail.js:
  Status picklist: Open, In Progress, Closed
  Disables status dropdown when status = "Closed"

✅ Aligned - Frontend UI reflects backend business rules
```

### Phase 7: Implementation Approval

```
[AskUserQuestion widget]

"Implementation complete! Here's what was delivered:

BACKEND (Agent 1 - /apex-dev):
✅ CaseRestController.cls - REST API with 3 endpoints
✅ CaseService.cls - Business logic with validation
✅ CaseRestController_Test.cls - 82% test coverage
✅ Error handling for all scenarios

FRONTEND (Agent 2 - /lwc-dev):
✅ caseList component - Display cases with refresh
✅ caseForm component - Create case with validation
✅ caseDetail component - View and update status
✅ Jest tests for all components
✅ Accessibility compliant (WCAG 2.1 AA)

INTEGRATION VALIDATION:
✅ API contracts match (endpoints and schemas)
✅ Error handling aligned (backend errors handled in UI)
✅ Security consistent (backend enforces, UI reflects)
✅ Business rules aligned (status transitions work)

Ready to deploy?"

Options:
1. "Approve - looks good"
2. "Show me the code"
3. "Make changes to [component]"
```

### Phase 8: Delivery

**User approves** → Astro delivers:

```
✅ SOLUTION READY: Customer Portal - Case Management

BACKEND FILES:
- force-app/main/default/classes/CaseRestController.cls
- force-app/main/default/classes/CaseService.cls
- force-app/main/default/classes/CaseRestController_Test.cls

FRONTEND FILES:
- force-app/main/default/lwc/caseList/
- force-app/main/default/lwc/caseForm/
- force-app/main/default/lwc/caseDetail/

INTEGRATION GUIDE:
1. Deploy backend classes first
2. Run test: CaseRestController_Test (verify 75%+ coverage)
3. Deploy LWC components
4. Add components to Portal page
5. Test end-to-end: Create case → View list → Update status

TESTING CHECKLIST:
Backend:
- [ ] Create case with valid data → Success
- [ ] Create case with missing subject → 400 error
- [ ] Update case status: Open → In Progress → Success
- [ ] Update case you don't own → 403 error
- [ ] Bulk test: Create 200 cases → Success

Frontend:
- [ ] View case list → Displays all user's cases
- [ ] Click "New Case" → Form opens
- [ ] Submit form with valid data → Case created
- [ ] Submit form with missing subject → Inline error
- [ ] Update status on case detail → Status updated
- [ ] Keyboard navigation → All buttons accessible

Integration:
- [ ] Create case in UI → Appears in list
- [ ] Backend error → UI shows toast message
- [ ] Loading state → Spinner shows during API call

DOCUMENTATION:
- API Endpoints: See CaseRestController.cls header
- UI Components: See component JSDoc comments
- Security Model: Portal users see only their cases
- Error Codes: VAL-001 (validation), SYS-001 (system error)

TIME: 35 minutes (parallel execution)
RESULT: Fully integrated customer portal with validated APIs

Need help with deployment or testing? I'm here!
```

---

## Key Takeaways

### Parallel Execution Benefits
- **Time Savings**: 50% faster than sequential (35 min vs 60+ min)
- **Integration Quality**: Validated before delivery
- **User Control**: Approve architecture, approve implementation
- **Complete Solution**: Backend + Frontend + Tests + Documentation

### When to Use Parallel Execution
- Complex tasks requiring multiple experts (backend + frontend)
- Well-defined architecture (data model, APIs, security)
- Independent work streams (agents don't block each other)

### When to Use Sequential Execution
- Architecture decisions needed first
- Implementation depends on design choices
- Simple tasks (single expert sufficient)
