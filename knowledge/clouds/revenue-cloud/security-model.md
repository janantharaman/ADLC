---
source: hand-authored + RCA Internal Playbook (May 2025)
cloud: Revenue Cloud
section: security-model
---

# Revenue Cloud — Security Model

## CPQ-Specific Permission Sets

CPQ ships with its own permission sets that must be assigned before users can access CPQ functionality:

| CPQ Permission Set | Who Needs It | What It Grants |
|---|---|---|
| `SBQQ__Quoting_User` | All reps who create quotes | Access to Quote, QuoteLine, CPQ product catalog |
| `SBQQ__Quoting_Admin` | CPQ admins, RevOps | Configure Price Rules, Product Rules, Bundle config |
| `SBQQ__Contracting_User` | Contract managers | Generate and manage Contracts from Quotes |
| `sbaa__Approver` | Deal desk / approval chain | Process CPQ Advanced Approvals |

**Note:** These permission sets are in the `SBQQ__` managed package namespace — they cannot be modified. Grant them as-is; add supplemental access via custom permission sets on top.

## OWD for CPQ Objects

| Object | Internal OWD | Notes |
|---|---|---|
| `SBQQ__Quote__c` | Private | Rep sees own quotes; manager via hierarchy |
| `SBQQ__QuoteLine__c` | Controlled by Parent | Inherits Quote sharing |
| Contract | Private | Contract team + Account Owner + manager |
| `SBQQ__Subscription__c` | Private | CS/Renewals team + Account Owner |
| Order | Private | Order management team + Account Owner |
| Product2 | Public Read Only | All reps need product catalog access |
| Pricebook2 | Public Read Only | Channel-specific pricebooks may need restriction |

## Pricing Data Sensitivity

CPQ pricing data (list prices, discount thresholds, partner multipliers) is often highly confidential:
- `PricebookEntry.UnitPrice` — restrict FLS Edit to RevOps/CPQ Admin only; reps can see list price but not edit it
- `SBQQ__QuoteLine__c.SBQQ__Discount__c` — reps can enter discounts up to their max discount authority; enforce via Price Rule or Validation Rule
- `SBQQ__Quote__c.SBQQ__NetAmount__c` — total deal value; read-only via FLS for non-deal-team users
- Partner pricebooks — if partners have portal access, use separate Pricebook2 records and Sharing Rules to grant access only to the correct pricebook

## Deal Desk Separation of Duties

For deals requiring approval:
- Rep creates quote (SBQQ__Status = 'Draft')
- Rep submits for approval — triggers CPQ Advanced Approval workflow
- Deal Desk reviews and approves — Deal Desk cannot also be the Account Owner for the deal
- Enforce via `SBAA__Approval__c.SBAA__CannotSelfApprove__c = true` in Advanced Approvals config

## Contract and Subscription Lock-Down

Once a Contract is Activated:
- Prevent rep-level edits to Contract Amount or Term via FLS (mark fields as read-only on the Contract page layout for Rep profile)
- `SBQQ__Subscription__c` records must be read-only except to CS/Renewals team — accidental edits cause incorrect renewal quote generation
- Use a Validation Rule on `SBQQ__Subscription__c` to block Status/Quantity/Price changes unless the user has `Contract_Manager` Permission Set

## RLM (Revenue Cloud on Core) Permission Sets & Personas

RLM uses platform-native permission sets — no `SBQQ__` namespace. These are assigned based on persona:

| Persona | Role | Key Access Needed |
|---|---|---|
| Sales Rep | Create and manage quotes and orders | Quote, QuoteLineItem, Order, Product Catalog (read), Pricing (read) |
| Sales Ops / Rev Ops | Manage pricing, products, approvals, renewals | All rep access + Price Management, Advanced Approvals admin, Asset Lifecycle |
| Product/Pricing Admin | Manage product catalog and pricing rules | Product2, ProductCatalog, ProductAttribute, PricingPlan — full CRUD |
| Contract Manager | Create and manage contracts | Contract, Asset — full CRUD; Quote — read |
| Finance | Billing, invoicing, payments, revenue recognition | Invoice, BillingSchedule, Payment — full CRUD; Quote/Order — read |
| IT/DevOps | Deployment, configuration, integration | System admin access; API integration user for headless operations |
| External User (headless/self-service) | Submit orders via storefront or API | Revenue Cloud External User license; no internal UI access required |

**Key distinction from CPQ:** External users in RLM do NOT need a standard user license — they consume Revenue Events via the External Events model. This makes self-service and partner quoting significantly more cost-effective.

## RLM External User Access Model

For omni-channel selling (self-service, partner, in-app):
- External users consume Revenue Events — not user licenses
- Event rate: $10K per 50K events for external operations
- Access scope: Product Catalog (browse), Pricing (execute), Quote (create), Order (place), Contracts (view)
- No Salesforce internal UI access — all via headless API or Experience Cloud
- Must configure OAuth for external authentication

## Agentforce Security for Revenue Cloud

Key security considerations when enabling Agentforce Quoting:
- Agents maintain **role-based access permissions** — an agent cannot do what the human user it's acting on behalf of cannot do
- Agents operate within the same guardrails as sellers — approval thresholds, discount limits, product access
- Data masking must be explicitly enabled — it is NOT on by default
- Einstein Trust Layer is active — prompts and responses do not leave the Salesforce trust boundary (confirmed with Anthropic model option on AWS Bedrock as of March 2025)
- Customers concerned about OpenAI: Anthropic Claude (on AWS Bedrock, inside Salesforce trust boundary) is available as an alternative — raise this proactively with security-sensitive customers

## Billing Security (if blng__ installed)

- `blng__Invoice__c` — Finance team only for Edit; Account Owner + CS team for Read
- `blng__Payment__c` — Finance team only; no rep access
- `blng__BillingAccount__c` — Finance + CS team for Read; Finance only for Edit
- Audit trail: Enable Field History Tracking on all Billing objects — billing records are financial audit evidence
