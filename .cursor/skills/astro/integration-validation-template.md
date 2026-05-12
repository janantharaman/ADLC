# Integration Validation Checklist

Use this checklist after parallel agents complete to verify integration quality.

## API Contract Validation

### Endpoints Match
- [ ] Backend declares endpoint: [METHOD] [PATH]
- [ ] Frontend calls endpoint: [METHOD] [PATH]
- [ ] ✅ Exact match OR ❌ Mismatch → Resolution needed

**Example**:
```
Backend: @HttpGet GET /services/apexrest/cases
Frontend: fetch('/services/apexrest/cases')
✅ Match
```

### Request/Response Schemas
- [ ] Backend expects: {field1: type, field2: type}
- [ ] Frontend sends: {field1: type, field2: type}
- [ ] ✅ Schema compatible OR ❌ Mismatch → Resolution needed

**Example**:
```
Backend expects (POST): {subject: String, description: String, priority: String}
Frontend sends: {subject: string, description: string, priority: string}
✅ Compatible
```

### Response Format
- [ ] Backend returns: {data structure}
- [ ] Frontend parses: {data structure}
- [ ] ✅ Compatible OR ❌ Mismatch → Resolution needed

**Example**:
```
Backend returns: {"cases": [{id, subject, status}], "total": 5}
Frontend expects: {cases: Array, total: number}
✅ Compatible
```

---

## Error Handling Validation

### Error Responses
- [ ] Backend error format: {error: string, code: string}
- [ ] Frontend error parsing: {error: string, code: string}
- [ ] ✅ Consistent OR ❌ Needs alignment

**Example**:
```
Backend (400): {error: "Subject is required", code: "VAL-001"}
Frontend:
  .catch(error => {
    const {error: message, code} = error;
    this.showToast(message, 'error');
  })
✅ Consistent - Frontend handles backend error format
```

### Error Scenarios Covered
- [ ] Validation errors (400)
- [ ] Authentication errors (401)
- [ ] Permission errors (403)
- [ ] Not found errors (404)
- [ ] System errors (500)
- [ ] Network errors (timeout, connection)

**Example**:
```
Backend covers: 400, 401, 403, 404, 500
Frontend handles: All HTTP status codes + network errors
✅ Comprehensive
```

---

## Security Validation

### Authentication/Authorization
- [ ] Backend enforces: [security checks]
- [ ] Frontend respects: [permission model]
- [ ] ✅ Unified approach OR ❌ Gap identified

**Example**:
```
Backend: Checks User.ContactId, filters cases by ContactId
Frontend: No client-side filtering (trusts backend)
✅ Unified - Backend enforces, frontend trusts
```

### CRUD/FLS Consistency
- [ ] Backend checks: CRUD/FLS on [Objects]
- [ ] Frontend hides: UI elements based on permissions
- [ ] ✅ Consistent OR ❌ Needs alignment

**Example**:
```
Backend: Portal users cannot delete cases (no Delete permission)
Frontend: No "Delete" button shown to portal users
✅ Consistent
```

### Session Management
- [ ] Backend: Session validation on all endpoints
- [ ] Frontend: Handles 401 (redirects to login)
- [ ] ✅ Aligned OR ❌ Needs improvement

---

## Testing Validation

### Test Coverage Alignment
- [ ] Backend tests: [scenarios covered]
- [ ] Frontend tests: [scenarios covered]
- [ ] Integration tests: [end-to-end scenarios]
- [ ] ✅ Comprehensive OR ❌ Gaps identified

**Example**:
```
Backend tests:
  - Create case with valid data ✅
  - Create case with missing fields ✅
  - Update case (own) ✅
  - Update case (not own) ✅
  - Bulk operations (200+ records) ✅

Frontend tests:
  - Display case list ✅
  - Submit form with valid data ✅
  - Submit form with errors ✅
  - Handle API errors ✅
  - Keyboard navigation ✅

Integration tests needed:
  - End-to-end: Create case in UI → Verify in backend
  - End-to-end: Backend error → UI displays message

✅ Comprehensive backend/frontend, ❌ Missing integration tests
```

---

## Data Flow Validation

### Data Transformation
- [ ] Backend output format matches frontend input format
- [ ] Date/time formats consistent (ISO 8601)
- [ ] Number formats consistent (decimals, currency)
- [ ] ✅ Consistent OR ❌ Needs transformation layer

**Example**:
```
Backend returns: "createdDate": "2024-01-15T10:30:00.000Z"
Frontend expects: ISO 8601 date string
Frontend displays: new Date(createdDate).toLocaleDateString()
✅ Consistent - No transformation needed
```

### Null/Empty Handling
- [ ] Backend handles: null vs empty string vs missing field
- [ ] Frontend handles: null/undefined/empty appropriately
- [ ] ✅ Aligned OR ❌ Needs clarification

---

## Performance Validation

### Data Volume
- [ ] Backend: Handles bulk operations (200+ records)
- [ ] Frontend: Handles large lists (pagination/virtual scroll)
- [ ] ✅ Scalable OR ❌ Performance issues expected

**Example**:
```
Backend: Bulkified SOQL/DML, tested with 200+ records
Frontend: Pagination (20 per page), lazy loading
✅ Scalable
```

### Loading States
- [ ] Frontend: Shows spinners during API calls
- [ ] Frontend: Disables buttons during submission
- [ ] Frontend: Handles slow networks gracefully
- [ ] ✅ User-friendly OR ❌ Needs improvement

---

## Resolution Options (If Mismatches Found)

### Option 1: Modify Backend
- Adjust API contract to match frontend expectations
- Update response schema
- Update error format
- Update tests
- **Impact**: Backend code changes, may affect other consumers

### Option 2: Modify Frontend
- Adjust API calls to match backend implementation
- Update error handling
- Transform data formats
- Update tests
- **Impact**: Frontend code changes only

### Option 3: Create Adapter Layer
- Transform data between backend/frontend
- Map error formats
- Isolate changes to adapter
- **Impact**: Additional layer, slight performance overhead

### Option 4: Document as Known Limitation
- If mismatch is minor and low-risk
- Document in implementation guide
- Plan to fix in future iteration
- **Impact**: Technical debt, may confuse users

---

## Validation Report Template

Use this template to present validation results to the user:

```markdown
## Integration Validation Results

### ✅ PASSED

**API Contracts**:
- All endpoints match (GET /cases, POST /cases, PUT /cases/{id})
- Request/response schemas compatible
- HTTP status codes consistent

**Error Handling**:
- Backend error format: {error: string, code: string}
- Frontend parses all error types correctly
- All scenarios covered (400, 401, 403, 404, 500, network)

**Security**:
- Backend enforces CRUD/FLS and sharing rules
- Frontend trusts backend (no redundant checks)
- Session management aligned

**Testing**:
- Backend: 82% coverage (exceeds 75% requirement)
- Frontend: Jest tests for all components
- Bulk testing: 200+ records validated

### ⚠️ NEEDS ATTENTION

**Date Format Inconsistency** (Minor):
- Backend returns: "2024-01-15T10:30:00.000Z"
- Frontend displays: "1/15/2024, 10:30 AM"
- **Resolution**: Frontend correctly transforms date for display
- **Action**: None required (working as intended)

### ❌ ISSUES FOUND

None

### RECOMMENDATION

✅ Ready to deploy - All critical validations passed
```

---

## Quick Validation Script

For common scenarios, use this quick checklist:

```
□ Backend endpoint = Frontend fetch URL?
□ Backend response schema = Frontend expects?
□ Backend errors = Frontend handles?
□ Backend security = Frontend respects?
□ Both tested (backend + frontend)?

All ✅? → Ready to deploy
Any ❌? → Review issue and choose resolution option
```

---

## Example: Complete Validation

### Scenario: Customer Portal Case Management

**Backend Agent Delivered**:
- CaseRestController.cls (GET, POST, PUT /cases)
- CaseService.cls (business logic)
- Test coverage: 82%

**Frontend Agent Delivered**:
- caseList.lwc (display cases)
- caseForm.lwc (create case)
- caseDetail.lwc (update status)
- Jest tests for all components

**Validation Process**:

**Step 1: API Contract Check**
```
✅ GET /services/apexrest/cases
   Backend: Returns {cases: [...], total: 5}
   Frontend: Expects {cases: Array, total: number}
   Match ✅

✅ POST /services/apexrest/cases
   Backend: Expects {subject: String, description: String, priority: String}
   Frontend: Sends {subject: string, description: string, priority: string}
   Match ✅

✅ PUT /services/apexrest/cases/{id}
   Backend: Expects {status: String}
   Frontend: Sends {status: string}
   Match ✅
```

**Step 2: Error Handling Check**
```
✅ Backend 400 error: {error: "Subject is required", code: "VAL-001"}
   Frontend catches: error.error, error.code
   Displays: Toast message with error text
   Aligned ✅

✅ Backend 403 error: {error: "Access denied"}
   Frontend catches: error.error
   Displays: Toast error message
   Aligned ✅
```

**Step 3: Security Check**
```
✅ Backend CRUD/FLS: Checks Case object permissions
   Frontend: No redundant checks (trusts backend)
   Consistent ✅

✅ Backend sharing: Filters cases by ContactId
   Frontend: Displays all returned cases (trusts backend filter)
   Consistent ✅
```

**Step 4: Testing Check**
```
✅ Backend tests: 82% coverage (exceeds 75%)
   - Create case (valid/invalid)
   - Update case (own/not own)
   - Bulk operations (200+ records)

✅ Frontend tests: Jest tests for all components
   - Case list display
   - Form submission
   - Error handling
   - Keyboard navigation

⚠️ Integration tests: None (manual testing recommended)
```

**Validation Result**:
```
✅ READY TO DEPLOY

All critical validations passed:
- API contracts match
- Error handling aligned
- Security consistent
- Testing comprehensive (backend + frontend)

Recommendation: Manual integration test before production
```

---

## Summary

Use this checklist to ensure parallel agent outputs are properly integrated:

1. **API Contracts**: Endpoints, schemas, responses match
2. **Error Handling**: Backend errors handled by frontend
3. **Security**: Backend enforces, frontend respects
4. **Testing**: Both agents tested their components
5. **Data Flow**: Formats and transformations work

**If all ✅**: Ready to deploy
**If any ❌**: Present resolution options to user for decision
