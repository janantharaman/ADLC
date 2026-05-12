---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf
cloud: Automotive Cloud
section: security-model
---

# Automotive Cloud — Security Model

## Persona-Based Access

Automotive Cloud implementations typically involve multiple distinct personas, each requiring different object access:

| Persona | Key Objects | Typical Profile Basis |
|---|---|---|
| OEM Administrator | VehicleDefinition, ProductWarrantyTerm, TelemetryDefinition, Codeset | Custom profile or System Admin |
| Dealer Sales Rep | Vehicle, Lead, LeadLineItem, Opportunity, ApplicationForm, SellerProduct | Sales Cloud user + Automotive perm set |
| Dealer Finance Manager | FinancialAccount, FinancialAccountTransaction, ApplicationForm | Service Cloud user + Lending perm set |
| Fleet Manager | Fleet, FleetAsset, FleetParticipant, ServiceAppointment | Custom profile |
| Service Technician | ServiceAppointment, Visit, GenericVisitTask, WorkType | Field Service user |
| Claims Adjuster | Claim, ClaimItem, ClaimCoverage, Appraisal | Service Cloud user + Claims perm set |
| Customer / Portal User | Asset (own vehicle), ServiceAppointment, FinancialAccount (read) | Experience Cloud user |

## OWD Recommendations

| Object | Recommended OWD | Rationale |
|---|---|---|
| `Vehicle` | Private | Vehicles owned by specific dealers/accounts; no cross-dealer visibility |
| `VehicleDefinition` | Public Read Only | Catalog data — all dealers should read, only OEM should write |
| `FinancialAccount` | Private | Sensitive financial data; access via sharing rules to lender users |
| `Claim` | Private | Claims data is sensitive; adjuster access via queue or sharing |
| `Fleet` | Private | Fleet data belongs to specific corporate accounts |
| `Asset` | Controlled by Parent | Inherits from Account; customers can see their own assets |
| `Appraisal` | Private | Appraisal value is commercially sensitive |
| `SellerProduct` | Private | Dealer inventory — only visible within dealer hierarchy |

## Permission Set Strategy

Implement access via permission sets rather than profiles:

| Permission Set | Grant To |
|---|---|
| `Automotive_OEM_Admin` | OEM admins managing product catalog, warranties, telemetry |
| `Automotive_Dealer_Sales` | Sales reps — Vehicle, Lead, Opportunity, ApplicationForm |
| `Automotive_Dealer_Finance` | Finance managers — FinancialAccount objects |
| `Automotive_Fleet_Manager` | Fleet, FleetAsset, FleetParticipant |
| `Automotive_Service_Tech` | ServiceAppointment, Visit, WorkType |
| `Automotive_Claims` | Claim, ClaimItem, ClaimCoverage, Appraisal |
| `Automotive_Telemetry_Admin` | TelemetryDefinition, TelemetryActionDefinition |

## FLS Considerations

Critical fields requiring FLS restriction:
- `FinancialAccount.CurrentBalance__c` / balance fields — restrict to Finance persona
- `PartyCreditProfileInquiry` fields — restrict to Credit/Finance persona only
- `ClaimCoveragePaymentDetail` payment amounts — restrict to Claims Adjuster
- `AppraisalItem.ProviderValue__c` — restrict to Appraisal roles
- `AssetTitle` lien/ownership fields — restrict to title/legal roles

## Sharing Rules

| Scenario | Sharing Rule Type |
|---|---|
| Dealer users see all Assets linked to their dealer Account | Criteria-based: Asset where AccountId = user's AccountId |
| Claims Adjusters see Claims assigned to their queue | Owner-based: Claims owned by adjuster's public group |
| Fleet Managers see Fleet records for their company | Criteria-based: Fleet where OwnerId in Fleet Manager role |

## Apex CRUD/FLS Enforcement

All Automotive Cloud custom Apex must:
- Use `WITH SECURITY_ENFORCED` on SOQL queries or `Security.stripInaccessible()` before DML
- Never hardcode profile names — use permission set checks
- Use the `CanTheUser` pattern (from `knowledge/security-baseline.md`) for conditional UI rendering

## Connected App / Integration Security

- DMS integrations should use Named Credentials with OAuth 2.0
- Telematics/IoT integrations should use the Orchestration Inbound Events API with a dedicated Connected App and IP allowlist
- MuleSoft integrations should authenticate via OAuth client credentials with a dedicated integration user (minimum permissions)
- Never use the `Modify All Data` permission on integration users — scope to specific objects only

## Experience Cloud (Portal) Security

For customer-facing portals showing vehicle/financial data:
- Use `Account` as the portal account — customers see only their own Assets
- Apply `Customer Community` or `Customer Community Plus` license depending on sharing needs
- External OWD for `Asset`: Controlled by Parent — customers inherit access via Account
- External OWD for `FinancialAccount`: Private — grant read access via sharing rule scoped to account owner
