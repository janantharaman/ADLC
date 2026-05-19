# Agentforce Public Sector (Public Sector Solutions) — Security Model

## Platform Security Foundation

PSS inherits the full Salesforce platform security model. There is no PSS-specific security layer — all access control is implemented via standard Salesforce mechanisms.

---

## Permission Sets

PSS ships with managed permission sets. Never modify these — create custom permission sets that layer on top.

| Permission Set | Who Gets It | What It Grants |
|---|---|---|
| `Public Sector Access` | All PSS users | Base object CRUD for core PSS objects |
| `Public Sector Admin` | Admins and implementation team | Full configuration access including BRE, OmniStudio |
| `OmniStudio User` | All users who interact with OmniScripts/FlexCards | OmniStudio runtime access |
| `OmniStudio Admin` | Developers building OmniStudio components | OmniStudio design-time access |
| `Business Rules Engine User` | Eligibility officers | BRE rule execution |
| `Business Rules Engine Admin` | Policy analysts, admins | BRE authoring and versioning |

**Custom permission sets** for implementation:
- Create `PSS_Custom_CaseWorker`, `PSS_Custom_Supervisor`, etc. rather than modifying managed sets
- Use Permission Set Groups to bundle base managed + custom sets per role

---

## Object-Level Security (OLS)

Configure per persona. Minimum required access:

| Persona | Typical Object Access |
|---|---|
| Case Worker | Read/Edit on ProgramEnrollment, ProgramCase, Benefit; Read on BenefitProgram |
| Supervisor | Full CRUD on all case/enrollment objects; Read on Inspection |
| Grant Officer | Full CRUD on GrantApplication, FundingAward, Disbursement |
| Inspector | Read/Edit on Inspection, RegulatoryCodeViolation; Read on Permit |
| Constituent (Community) | Read on own Benefit, ProgramEnrollment; Create on GrantApplication |
| Guest (unauthenticated) | No record access — form submissions only via OmniScript-hosted APIs |

---

## Sharing Model

**Organisation-Wide Defaults (OWD) recommendations:**

| Object | OWD | Reason |
|---|---|---|
| Individual / Contact | Private | Constituent PII must not be visible by default |
| ProgramEnrollment | Private | Case worker sees only their assigned cases |
| Case | Private | Standard casework isolation |
| GrantApplication | Private | Competitive grant process confidentiality |
| Inspection | Private | Inspector sees assigned inspections only |
| BusinessLicense | Public Read Only | Licence status is public record in most jurisdictions |

**Sharing rules** for supervisor visibility: use Criteria-Based Sharing Rules to give supervisors access to their team's cases based on ownership hierarchy.

**Territory Management** is not used in most PSS implementations — use Queues + Assignment Rules for case routing instead.

---

## Experience Cloud (Constituent Portal) Security

This is the highest-risk area in PSS implementations:

### Guest User Profile
- Guest users (unauthenticated portal visitors) operate under the Guest User Profile
- Grant minimum necessary access — typically only `Create` on OmniScript submission objects
- Never grant Guest User access to `Individual`, `ProgramEnrollment`, or `Benefit` objects
- Enable **Secure Guest User Record Access** in Experience Cloud settings

### Authenticated Constituent Users
- Licence type: Customer Community or Customer Community Plus
- Use `Owner = Current User` sharing to restrict constituents to their own records
- `Individual` record linked to `Contact` — constituent sees only their Contact's child records
- Never expose `Individual.IndividualId` or SSN-equivalent fields to community users

### Portal Profile vs Permission Set
- Community users require both the Community profile AND a Permission Set granting PSS object access
- The Community profile sets object defaults; the Permission Set adds specific CRUD rights

---

## Government Cloud Plus (FedRAMP High)

Government Cloud Plus is a separate infrastructure SKU — not included in the PSS licence:

- Provides **FedRAMP High** Authorization To Operate (ATO)
- Required for federal agencies and state/local agencies handling CUI (Controlled Unclassified Information)
- Data residency: US-only data centres
- Supports ITAR, CJIS, HIPAA, and DoD IL4/IL5 (with additional configuration)
- Impact on implementation: no external URLs can be called without approval, AppExchange packages must be GovCloud-compatible, third-party integrations require additional vetting

**Not all AppExchange packages are Government Cloud Plus compatible** — verify package compatibility before design phase.

---

## Field-Level Security (FLS)

Critical fields requiring restricted FLS:

| Field | Restriction |
|---|---|
| SSN / National ID (custom) | View restricted to case workers + supervisors only |
| Date of Birth | View restricted; never expose on community pages |
| Income data (custom) | Eligibility officers and supervisors only |
| Benefit payment amounts | Internal users only; not visible to constituent portal |
| Investigation notes | Investigator and supervisor only; never community-visible |

Use **Salesforce Shield Platform Encryption** for fields containing PII at rest if FedRAMP High or state privacy law compliance requires it.

---

## Audit and Compliance

- **Field Audit Trail** — recommended for all PII fields and benefit payment fields (Salesforce Shield add-on)
- **Event Monitoring** — required for FedRAMP — track login, data export, report access
- **Setup Audit Trail** — standard, always enabled; review after every deployment
- **Record Change History** — enable field history tracking on ProgramEnrollment, Benefit, and FundingAward for audit trail

---

## Managed Package Security Notes

- PSS managed package objects come with their own object-level permissions baked in
- Package upgrades can reset or add permission set grants — verify after every package upgrade
- Do not rely on managed permission set assignments persisting across upgrades in sandbox
