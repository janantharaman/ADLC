---
source: Salesforce Sales Cloud documentation (help.salesforce.com, developer.salesforce.com, Spring '26); sales_core.pdf (Sales Cloud Basics, 603p, Spring '26); grounded 2026-05-11
cloud: Sales Cloud
section: security-model
last-updated: 2026-05-11
---

# Sales Cloud — Security Model

---

## OWD Recommendations

### Recommended OWD Starting Points

| Object | Recommended OWD | Rationale | Common Exceptions |
|---|---|---|---|
| Account | **Private** | Reps see only their accounts; sharing opens access via territory or rules | SMB orgs with flat teams sometimes use Public Read Only |
| Contact | **Controlled by Parent** | Inherits Account OWD; avoids separate Contact sharing rule maintenance | Rarely needs independent OWD in B2B |
| Lead | **Private** | Leads are rep-owned; queues handle shared access | Some orgs use Public Read/Write if all reps can work any lead |
| Opportunity | **Private** | Pipeline is confidential; rep + hierarchy access via role | Never Public in FSI/enterprise; Private is non-negotiable |
| Quote | **Controlled by Parent** | Inherits Opportunity access | |
| OpportunityLineItem | (inherits from Opp) | Master-detail; no OWD of its own | |
| Product2 | **Public Read Only** | All reps need catalog read access; only admins/ops edit | |
| Pricebook2 | **Use** (only option exposed) | Special Pricebook OWD: "Use" means authenticated users can add to Opps | Restrict to specific price books via Apex/Flow |
| Campaign | **Public Read Only** | Marketing team manages; field sales can view ROI | |
| Contract | **Private** or **Read Only** | Finance/legal-sensitive; restrict write access | |
| Order | **Private** | Fulfillment-sensitive | |

**Warning:** Setting Account or Opportunity to Public Read/Write is a HIGH RISK configuration in any org that contains sensitive deal values, margin data, or competitive information. It is a common accidental misconfiguration in orgs set up by developers without sales operations input. Always verify with business stakeholders before accepting Public settings.

### OWD for Contacts to Multiple Accounts
When "Contacts to Multiple Accounts" (AccountContactRelation) is enabled:
- `Contact` OWD applies to the "direct" Account relationship
- `AccountContactRelation` OWD is separate: default Private, typically set to Controlled by Parent (of the Account)
- A user who can see the Account can see the AccountContactRelation records for that Account even if they cannot see the Contact's own record — this can cause confusion. Design and test carefully.

---

## Role Hierarchy

### Mandatory Use in Sales Cloud Forecasting
Collaborative Forecasting **requires** a Role Hierarchy. Without a Role Hierarchy, Forecasting cannot function. The Role Hierarchy defines:
- Who can see whose pipeline (managers see subordinate records)
- Who can adjust whose forecasts (managers adjust subordinates only)
- The rollup path for forecast amounts

**Design principle:** Role Hierarchy in Salesforce models reporting relationships, not job titles. Each role node must have the correct parent to ensure managers can see their reports' records. Roles without a parent are top of their tree — only admins and users above them can see those records.

### Typical Role Hierarchy for Sales Cloud

```
CEO / VP Sales (top of tree)
    ├── Regional VP - East
    │       ├── Regional Manager - Northeast
    │       │       ├── Account Executive - NY
    │       │       └── Account Executive - Boston
    │       └── Regional Manager - Southeast
    │               └── Account Executive - ATL
    ├── Regional VP - West
    │       └── ...
    └── Sales Operations (flat — no reports; View All Data via PermSet)
```

**Overlay roles:** Sales Engineers, Customer Success, Channel Managers typically have their own role branches. If they do not need to see rep pipeline, do not put them in the same hierarchy branch. Use Account Teams or Sharing Rules for selective access instead.

---

## Sharing Rules

### Account Sharing Rules
Account Sharing Rules extend access beyond OWD. Types:
- **Criteria-based**: Share all Accounts where `Industry = 'Healthcare'` with Healthcare_Team queue
- **Owner-based**: Share Accounts owned by "Sales Reps" role with "Specialist Overlay" role

**Pattern: Account Team Sharing Rule**
When Account Teams are enabled, account team members automatically get access at their configured level (`AccountAccessLevel`, `OpportunityAccessLevel`, `CaseAccessLevel`). This is more targeted than a broad sharing rule.

### Opportunity Sharing Rules
Opportunity OWD = Private means reps can only see their own Opportunities. Common sharing patterns:

| Pattern | Implementation |
|---|---|
| Manager sees team opportunities | Role Hierarchy (automatic via OWD + Role Hierarchy) |
| Overlay specialist sees all Opps in territory | Territory2 access + OpportunityAccessLevel on Territory2 |
| Deal desk sees all Opps in approval | Criteria-based Sharing Rule: Status = 'In Approval' → share with Deal_Desk group |
| Finance sees Closed Won | Criteria-based Sharing Rule: IsWon = true → share with Finance role (Read only) |

### Lead Sharing Rules
Leads with OWD = Private are visible only to owner. Sharing patterns:
- Queue access: Leads assigned to a Queue are visible to all Queue members
- SDR manager: Role Hierarchy gives SDR manager visibility into their reps' leads
- Marketing to SDR: If Marketing team creates leads and needs to audit, use Owner-based sharing rule or criteria-based sharing

---

## Opportunity Team vs Account Team

| Dimension | Account Team | Opportunity Team |
|---|---|---|
| Scope | Entire Account (and related Opps/Cases) | Single Opportunity only |
| Object | `AccountTeamMember` | `OpportunityTeamMember` |
| When to use | Persistent multi-stakeholder account coverage (AE + SE + CSM) | Deal-specific collaboration without granting full Account access |
| Access grants | AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel | OpportunityAccessLevel only |
| Durability | Persists until explicitly removed | Removed when Opportunity closes (configurable) |
| Auto-population | Via Flow/Apex trigger, or manual | Via Flow/Apex trigger, or manual |

**Best practice:** Use Account Teams for long-term account coverage (e.g., AE + SE pair). Use Opportunity Teams for deal-specific collaborations (e.g., adding a legal reviewer to a specific deal). Do not use Account Teams as a general-purpose sharing mechanism — it escalates access broadly.

---

## Territory Management 2.0 Sharing Model

### How Territory Sharing Works
When a Territory2 Model is Active and an Account is assigned to a Territory:
1. All users in that Territory (`UserTerritory2Association`) receive access to the Account at the configured `AccountAccessLevel` (Read or Edit)
2. All related Opportunities also receive access at `OpportunityAccessLevel` (Read, Edit, or None)
3. This access is additive — it never restricts existing access from Role Hierarchy or Sharing Rules

### Access Level Configuration per Territory

```
Territory2:
  AccountAccessLevel: Edit     → users can modify Account records in their territory
  OpportunityAccessLevel: Read → users can see (but not edit) related Opportunities
  CaseAccessLevel: None        → no Case access from territory alone
```

### Overlapping Territories and Access
If an Account is in multiple territories (possible with ETM), the user gets the most permissive access across all their territories. If Territory A gives Read and Territory B gives Edit, the user gets Edit.

### Territory Model State and Sharing
Sharing granted by territory is active only when the Territory2Model is in "Active" state. Archiving the model removes all territory-based sharing immediately. Do NOT archive an Active model without a replacement ready.

---

## Field-Level Security for Sensitive Sales Data

### Critical FLS Controls

| Field | Sensitivity | Recommended FLS |
|---|---|---|
| `Opportunity.Amount` | High — deal value | Edit: AE + Manager + RevOps only; Read: all with record access |
| `Opportunity.Probability` | Medium | Edit: AE + Manager; Read: all |
| `Opportunity.Gross_Margin__c` (custom) | High — competitive | Edit: RevOps + Finance; Read: Manager+ only |
| `OpportunityLineItem.UnitPrice` | High | Edit: AE; Read: all with OLI access |
| `OpportunityLineItem.Discount` | High | Edit: RevOps (others via approval process only) |
| `Quote.Discount` | High | Edit: AE (thresholds enforced by Approval Process) |
| `Lead.Email` | PII | Read: Owner + Manager + RevOps; restrict in regulated industries |
| `Lead.Phone` | PII | Read: Owner + Manager |
| `Account.AnnualRevenue` | Sensitive | Read: AE + Manager; restrict from support roles |
| `Contract.*` | Legal | Edit: Legal/Finance roles only; AE gets Read |

**Implementation:** Manage FLS via Permission Sets (not Profiles). Minimum access profile; grant additional field access via Permission Sets. This supports additive access model and is auditable.

### FLS and Apex
Apex runs in system context by default — it bypasses FLS. Explicitly enforce FLS in Apex using `WITH SECURITY_ENFORCED` in SOQL or `Schema.describeFieldResult().isAccessible()` checks. LWC with `@wire` adapter respects FLS automatically (user mode). Apex called from LWC must enforce FLS explicitly.

```apex
// Enforcing FLS in SOQL (Spring '20+)
List<Opportunity> opps = [
    SELECT Id, Name, Amount, StageName
    FROM Opportunity
    WITH SECURITY_ENFORCED
    WHERE AccountId = :accountId
];
```

---

## Profile vs Permission Set Approach for Sales Cloud Personas

### Recommended Model: Minimum-Access Profile + Permission Sets

```
Base Profile: Minimum Access (Salesforce license)
    └── No object permissions at all; just basic org access

Permission Sets:
    ├── Sales_Rep_Core
    │       CRUD: Lead, Opportunity, Contact, Quote, OpportunityLineItem
    │       Read: Account, Product2, Pricebook2
    │       Edit: Account (if needed)
    ├── Sales_Manager_Addons
    │       View All: Opportunity (for reporting)
    │       Edit Forecast
    │       View & Edit: ForecastingAdjustment
    ├── Sales_Ops_Admin
    │       Manage: Product2, Pricebook2, PricebookEntry
    │       Configure: Assignment Rules, Approval Processes, Territory
    │       View All: Leads, Opportunities
    ├── Sales_Engagement_User
    │       Access: Sales Engagement Work Queue, Cadences
    │       (Requires Sales Engagement feature license)
    ├── Pipeline_Inspection_User
    │       Access: Pipeline Inspection view
    └── Revenue_Intelligence_User
            Access: CRM Analytics Revenue Intelligence app
```

### Why Not Profiles for Everything
- Profiles are all-or-nothing per user — one profile per user
- Multiple persona combinations (AE + Sales Engagement + Pipeline Inspection) require separate profiles for each combo, leading to profile sprawl
- Permission Sets are additive — stack as needed per user
- Permission Set Groups (PSG) bundle related Permission Sets for assignment as one unit

### Standard Permission Sets Shipped with Features

| Feature | Permission Set API Name | Notes |
|---|---|---|
| Sales Cloud Einstein | `EinsteinLeadScoring` | Required for Einstein Lead Scoring UI |
| Sales Engagement | `HighVelocitySales` | Required for Work Queue and Cadences |
| Pipeline Inspection | `PipelineInspection` | Grants Pipeline Inspection list view access |
| Revenue Intelligence | `SalesAnalyticsUser` | Grants CRM Analytics RI app access |
| Einstein Activity Capture | `EinsteinActivityCapture` | Required to connect email/calendar |

---

## Sales Engagement (HVS) Permission Sets

| Permission Set | Who Gets It |
|---|---|
| `High Velocity Sales` | All Sales Engagement users (SDRs, BDRs, AEs using cadences) |
| `High Velocity Sales Admin` | RevOps admins who configure cadences and work queue settings |

**Email integration for Sales Engagement:** Users must have Einstein Activity Capture enabled to use email step functionality in cadences. HVS without EAC = calls and manual tasks only (no email step execution from Work Queue).

---

## Connected App Security for Sales Cloud Mobile

### Salesforce Mobile App
The standard Salesforce Mobile App (iOS/Android) uses OAuth 2.0 with the `Salesforce Mobile App` Connected App (pre-installed). Configuration:
- Session timeout: Set to match org security policy (recommended: 12 hours with re-authentication for sensitive data)
- Certificate: Pin to org certificate for certificate-based authentication (high security orgs)
- IP Restrictions: Can enforce IP range restrictions on mobile; consider impact on field sales

### Custom Mobile App (MobileSDK)
For custom mobile applications using Salesforce Mobile SDK:
1. Create a Connected App (Setup > App Manager > New Connected App)
2. Enable OAuth; select scopes: `api`, `refresh_token`, `offline_access` (only what's needed — least privilege)
3. Configure callback URL for your mobile app
4. Require digital signature (pin to certificate) for enterprise deployments
5. Enable "Use Digital Signatures" for client authentication

### Key Security Settings for Connected Apps

| Setting | Recommended Value | Reason |
|---|---|---|
| Session Timeout | 2-12 hours (policy-dependent) | Balance UX and security |
| Require certificates | Yes (enterprise) | Prevent credential theft |
| IP relaxation | Relax IP restrictions (mobile users roam) | Avoid lockouts for field sales |
| Permitted users | Admin approved | Control who can use the app |
| Refresh token policy | Expire on each login | For high-security (FSI) orgs |

---

## Einstein Activity Capture — Data Residency and Privacy

### Standard EAC Data Residency
- Email content and calendar data is processed and stored in **Amazon Web Services** infrastructure managed by Salesforce
- Data is NOT stored in the Salesforce org database — it is surfaced via UI only
- Implications:
  - Not accessible via SOQL
  - Not included in data export or backup tools
  - Subject to Salesforce's EAC data processing addendum, not the standard DPA

### Regulated Industry Considerations (FSI, Healthcare, Government)
- **Financial services:** EAC may not comply with SEC/FINRA email archiving requirements. Evaluate "Einstein Activity Capture with Activity 360 Reporting" (stores activities in Salesforce) or a compliant third-party email integration
- **Healthcare (HIPAA):** EAC standard tier is NOT HIPAA-eligible. If email content includes PHI, standard EAC cannot be used
- **Government:** Data sovereignty requirements may preclude US-region AWS storage. Evaluate Government Cloud + approved email integration alternatives
- **GDPR:** EAC processes personal data (email content, contacts) — include in data mapping / DPIA

### Activity 360 Reporting
An upgrade tier of EAC that writes captured activities as actual Task/Event records into the Salesforce org. Enables SOQL reporting, standard backup, and org-level data governance. Requires higher-tier license.

### User Opt-Out
EAC requires per-user consent/connection. Users can disconnect their email at any time. Admins cannot force-connect on behalf of users (by design — user consent model). Include EAC opt-in in rep onboarding process.

---

## Audit and Monitoring for Sales Cloud

| Capability | Object/Feature | Notes |
|---|---|---|
| Record access audit | "Who Can See This Record?" button | On-demand per-record audit; tests effective sharing |
| Field history tracking | `OpportunityFieldHistory`, `AccountHistory` | Enable for Amount, StageName, CloseDate at minimum; 18-month retention |
| Login history | `LoginHistory` | 6-month retention; query for unusual access patterns |
| Setup audit trail | Setup > Security > View Setup Audit Trail | 180 days; tracks configuration changes |
| Event Monitoring | `EventLogFile` | Premium feature; captures API calls, logins, report exports, record views |
| Shield Platform Encryption | Field Encryption | For PII/sensitive fields at rest; impacts search, SOQL, formula fields |
| Shield Event Monitoring | Extended retention | Full Event Monitoring with 1-year+ retention; required for compliance-heavy orgs |
