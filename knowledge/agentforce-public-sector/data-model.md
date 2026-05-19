# Agentforce Public Sector (Public Sector Solutions) — Data Model

## Architecture Overview

Public Sector Solutions extends the core Salesforce platform with a purpose-built industry data model. Core CRM objects (Account, Contact, Case) are re-used and extended with PSS-specific objects. OmniStudio (DataRaptors, Integration Procedures) mediates between the data model and portal UIs.

---

## Core Objects

### Party and Constituent

| Object | API Name | Description |
|---|---|---|
| Individual | `Individual` | Constituent record (extends Contact) |
| Account | `Account` | Organisation or household |
| Contact | `Contact` | Person associated with a constituent or organisation |
| Party Relationship | `PartyRelationship` | Links between individuals (household, guardian, employer) |
| Party Role Relationship | `PartyRoleRelationship` | Links roles played by a party across programs |

### Benefit Management

| Object | API Name | Description |
|---|---|---|
| Benefit Program | `BenefitProgram` | Definition of a benefit offering (e.g., Housing Assistance Program) |
| Program Enrollment | `ProgramEnrollment` | Enrollment of an Individual in a Benefit Program |
| Benefit | `Benefit` | Specific benefit issued to an enrolled individual |
| Care Program | `CareProgram` | Wrapper for a group of benefit programs |
| Care Program Enrollee | `CareProgramEnrollee` | Person enrolled in a Care Program |
| Program Case | `ProgramCase` | Tracks service delivery for an enrolled individual |
| Visit | `Visit` | Scheduled interaction (home visit, office appointment) |

### Grantmaking

| Object | API Name | Description |
|---|---|---|
| Grant Application | `GrantApplication` | Application submitted by an organisation for funding |
| Funding Award | `FundingAward` | Approved grant award with amount and conditions |
| Funding Award Period | `FundingAwardPeriod` | Reporting period for disbursement tracking |
| Funding Source | `FundingSource` | Budget source from which awards are made |
| Disbursement | `Disbursement` | Individual payment against a Funding Award |
| Grant Application Relationship | `GrantApplicationRelationship` | Links co-applicants and sub-grantees |

### License, Permit & Inspection

| Object | API Name | Description |
|---|---|---|
| Business License | `BusinessLicense` | License record for a regulated activity |
| License Type | `LicenseType` | Category of license (food handler, contractor, etc.) |
| Permit | `Permit` | Permission for a specific project or activity |
| Inspection | `Inspection` | Scheduled or unscheduled compliance inspection |
| Inspection Type | `InspectionType` | Category of inspection |
| Regulatory Code | `RegulatoryCode` | Applicable code or standard for compliance |
| Regulatory Code Violation | `RegulatoryCodeViolation` | Recorded violation against a code |

### Investigative Case Management

| Object | API Name | Description |
|---|---|---|
| Case | `Case` | Core case object (standard Salesforce) |
| Action Plan | `ActionPlan` | Structured sequence of tasks for a case |
| Action Plan Item | `ActionPlanItem` | Individual task within an Action Plan |
| Document | `Document` (via ContentDocument) | Evidence files attached to a case |
| Task | `Task` | Standard Salesforce task, used for investigation steps |

---

## Business Rules Engine (BRE)

Used for eligibility determination and policy rule authoring without code.

| Object | API Name | Description |
|---|---|---|
| Decision Matrix | `DecisionMatrix` | Table-driven rules (inputs → outputs) |
| Decision Matrix Version | `DecisionMatrixVersion` | Versioned rule set |
| Expression Set | `ExpressionSet` | Complex multi-condition rules (when/then logic) |
| Expression Set Version | `ExpressionSetVersion` | Versioned expression set |
| Decision Table | `DecisionTable` | Tabular eligibility rules |

BRE is the recommended approach for eligibility logic — avoids hardcoding rules in Flow or Apex.

---

## OmniStudio Integration Layer

PSS portals and guided workflows run on OmniStudio:

| Component | Purpose |
|---|---|
| OmniScript | Guided step-by-step intake forms (permit applications, benefit enrollment, complaints) |
| FlexCard | Constituent Snapshot cards, case status views, license dashboards |
| DataRaptor | Read/write operations between OmniStudio and Salesforce objects |
| Integration Procedure | Server-side logic for multi-step data lookups and external system calls |

---

## Experience Cloud Integration

Constituent-facing portals are built on Experience Cloud (Customer Community):

- Community type: **Customer Community Plus** or **Customer Community** (lower licence cost)
- OmniStudio components embedded in Lightning Experience Builder pages
- Guest user record access requires careful OWD + sharing rule configuration
- Unauthenticated (pre-login) form submissions use `Guest User` profile with restricted access

---

## Key Relationships

```
Individual (Constituent)
  ↓ ProgramEnrollment
  BenefitProgram
    ↓ Benefit (issued)
    ProgramCase (service tracking)
      ↓ ActionPlan
        ActionPlanItem (tasks)
      Visit (appointments)

Organisation (Account)
  ↓ GrantApplication
    FundingAward
      FundingAwardPeriod
        Disbursement

Property/Location
  ↓ Permit
    Inspection
      RegulatoryCodeViolation
  BusinessLicense
```

---

## Field Naming Conventions

PSS managed package fields use the `sfps__` namespace prefix (for managed objects) or no prefix (for standard platform objects extended by PSS). Custom fields added by implementation teams follow the standard `__c` suffix.

Always verify actual field API names via Schema Builder or `mcp__salesforce__run_soql_query` on `EntityDefinition` — PSS API names vary slightly between package versions.
