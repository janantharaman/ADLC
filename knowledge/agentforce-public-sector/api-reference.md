# Agentforce Public Sector (Public Sector Solutions) — API Reference

## API Access Pattern

PSS objects are standard Salesforce objects — accessible via the same REST API, SOAP API, Bulk API, and SOQL as any other Salesforce org object. There is no separate PSS API endpoint.

**Base URL:** `https://{your-instance}.salesforce.com/services/data/v{api-version}/`

Authentication is via standard OAuth 2.0 (JWT Bearer for server-to-server, Web Server Flow for user-context integrations).

---

## Key SOQL Queries

### Active Program Enrollments by Status
```sql
SELECT Id, Name, Status__c, BenefitProgram__r.Name, IndividualApplication__r.Name
FROM ProgramEnrollment
WHERE Status__c IN ('Active', 'PendingReview')
ORDER BY CreatedDate DESC
LIMIT 200
```

### Overdue Action Plan Items
```sql
SELECT Id, Subject, ActionPlan.Name, Owner.Name, ActivityDate,
       ActionPlan.RelatedRecordId
FROM ActionPlanItem
WHERE ActivityDate < TODAY
AND Status != 'Completed'
ORDER BY ActivityDate ASC
```

### Grant Disbursements Due This Month
```sql
SELECT Id, Name, DisbursementDate__c, Amount__c,
       FundingAward__r.Name, FundingAward__r.Account__r.Name
FROM Disbursement
WHERE CALENDAR_MONTH(DisbursementDate__c) = :currentMonth
AND CALENDAR_YEAR(DisbursementDate__c) = :currentYear
AND Status__c = 'Scheduled'
```

### Inspections Assigned to Inspector (Current User)
```sql
SELECT Id, Name, Status, ScheduledStartTime, ScheduledEndTime,
       InspectionType.Name, ParentRecordId
FROM Inspection
WHERE OwnerId = :currentUserId
AND Status IN ('Scheduled', 'InProgress')
ORDER BY ScheduledStartTime ASC
```

### Constituent Enrollment History
```sql
SELECT Id, Name, Status__c, EnrollmentStartDate__c, EnrollmentEndDate__c,
       BenefitProgram__r.Name
FROM ProgramEnrollment
WHERE IndividualApplication__r.Contact__r.Id = :contactId
ORDER BY EnrollmentStartDate__c DESC
```

### Regulatory Violations by Business License
```sql
SELECT Id, Name, RegulatoryCode__r.Name, ViolationDate__c, Status__c,
       Inspector__r.Name
FROM RegulatoryCodeViolation
WHERE BusinessLicense__c = :licenseId
ORDER BY ViolationDate__c DESC
```

---

## REST API — Create Program Enrollment

```
POST /services/data/v66.0/sobjects/ProgramEnrollment
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "Name": "HousingAssist-2025-00123",
  "BenefitProgram__c": "a0A000000xxxxxxx",
  "IndividualApplication__c": "a0B000000xxxxxxx",
  "Status__c": "PendingReview",
  "EnrollmentStartDate__c": "2025-06-01",
  "EligibilityStatus__c": "Eligible",
  "ApplicationSource__c": "OnlinePortal"
}
```

---

## REST API — Create Grant Application

```
POST /services/data/v66.0/sobjects/GrantApplication
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "Name": "Community Housing Fund 2025 - Acme Nonprofit",
  "Account__c": "0010000000xxxxxxx",
  "FundingSource__c": "a0C000000xxxxxxx",
  "Status": "Submitted",
  "RequestedAmount__c": 150000,
  "ProjectDescription__c": "Construction of 20 affordable housing units",
  "SubmissionDate__c": "2025-05-01"
}
```

---

## Business Rules Engine — Invoke via Connect API

Eligibility checks are invoked via the Business Rules Engine Connect API (available since API v54.0):

```
POST /services/data/v66.0/connect/business-rules-engine/expression-sets/{expressionSetVersionId}/actions/execute
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "inputVariables": [
    { "name": "AnnualIncome", "value": 35000, "type": "Decimal" },
    { "name": "HouseholdSize", "value": 3, "type": "Integer" },
    { "name": "ResidencyState", "value": "CA", "type": "String" }
  ]
}
```

Response:
```json
{
  "outputVariables": [
    { "name": "EligibilityStatus", "value": "Eligible", "type": "String" },
    { "name": "EligiblePrograms", "value": ["HousingAssist", "FoodAssist"], "type": "List" }
  ]
}
```

---

## Bulk API — Loading Historical Case Data

For migration from legacy systems, use the Bulk API v2:

```
POST /services/data/v66.0/jobs/ingest
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "object": "ProgramEnrollment",
  "contentType": "CSV",
  "operation": "insert",
  "lineEnding": "LF"
}
```

Upload CSV:
```
POST /services/data/v66.0/jobs/ingest/{jobId}/batches
Content-Type: text/csv

Name,BenefitProgram__c,Status__c,EnrollmentStartDate__c
"HousingAssist-2023-00001","a0Axxx","Active","2023-01-15"
```

---

## OmniStudio Integration Procedure — REST Invocation

Integration Procedures can be invoked externally (useful for testing):

```
POST /services/apexrest/v1/EPC/CalculateEligibility/
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "input": {
    "IndividualId": "a0B000000xxxxxxx",
    "ProgramType": "HousingAssist"
  },
  "selectorClassName": "omnistudio.DefaultQueryResultSelector",
  "previewPageCount": 0
}
```

---

## Useful Object API Names Reference

| Label | API Name | Notes |
|---|---|---|
| Program Enrollment | `ProgramEnrollment` | Core enrollment record |
| Benefit Program | `BenefitProgram` | Program definition |
| Benefit | `Benefit` | Issued benefit |
| Care Program | `CareProgram` | Care coordination wrapper |
| Grant Application | `GrantApplication` | Grant submission |
| Funding Award | `FundingAward` | Approved grant |
| Disbursement | `Disbursement` | Grant payment |
| Business License | `BusinessLicense` | Issued license |
| Inspection | `Inspection` | Compliance inspection |
| Regulatory Code Violation | `RegulatoryCodeViolation` | Recorded violation |
| Action Plan | `ActionPlan` | Investigation task sequence |
| Action Plan Item | `ActionPlanItem` | Individual task |
| Individual | `Individual` | Constituent privacy record |
| Decision Matrix | `DecisionMatrix` | BRE rule table |
| Expression Set | `ExpressionSet` | BRE complex rules |

> Always verify API names via `mcp__salesforce__run_soql_query` on `EntityDefinition` in the target org. PSS package versions vary and field/object API names can differ.
