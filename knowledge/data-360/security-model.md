# Data 360 — Security Model

## Overview

Data 360 uses a layered security model: org-level provisioning controls who can administer the platform, permission sets control feature access, and data space segmentation isolates data between business units or regions.

---

## Permission Sets

Data 360 ships with managed permission sets. Never modify them — clone and extend if customisation is needed.

| Permission Set | Role |
|---|---|
| `Data Cloud Admin` | Full admin: setup, ingestion, identity resolution, activation |
| `Data Cloud Data Aware Specialist` | Read Data Streams, DMOs, Segments; cannot configure or deploy |
| `Data Cloud Sales` | Access unified profiles on Sales Cloud records |
| `Data Cloud Service` | Access unified profiles on Service Cloud records |
| `Data Cloud Marketing` | Segment builder, activation to Marketing Cloud |
| `Data Cloud for Agentforce` | Query Data Graphs; required for Agentforce grounding |

> Assign the narrowest permission set possible. `Data Cloud Admin` includes the ability to delete Data Streams and run identity resolution — treat it like a System Administrator profile.

---

## Data Spaces

Data Spaces are the primary multi-tenancy mechanism within a single Data 360 org. They function like separate namespaces — Data Streams, DMOs, Segments, and Calculated Insights are scoped to a Data Space.

### When to Use Data Spaces

- Multiple business units with distinct customer populations (e.g., B2C vs B2B)
- Regional data residency requirements (EU vs US customer data must not be combined)
- Sandbox-like isolation for testing new ingestion pipelines without affecting production profiles

### Default Data Space

Every org has a `default` Data Space. All objects created without specifying a Data Space land here. Cannot be deleted or renamed.

### Data Space Access Control

Users are assigned to Data Spaces via the **Data Space Access** page. A user with `Data Cloud Admin` who is not assigned to a Data Space cannot see its objects.

---

## Field-Level Security on Unified Profiles

Unified profile data surfaced on CRM records (via the Profile component) respects the CRM user's field-level security on the underlying DMO fields. If a user's profile cannot see `Contact Point Email`, they will not see email addresses in the profile card.

---

## Consent Management

Data 360 has a built-in consent framework that integrates with Salesforce Privacy Center.

### Consent Objects

| Object | Purpose |
|---|---|
| `Contact Point Type Consent` | Opt-in/out per channel (email, phone, etc.) |
| `Individual` (Consent fields) | GDPR right-to-be-forgotten, data processing basis |
| `Data Use Legal Basis` | Legal basis for processing (consent, legitimate interest, contract) |

### Consent Enforcement

- Segments automatically exclude individuals who have opted out of the relevant channel
- This requires the consent DMO to be correctly mapped and the Segment to reference the correct `Contact Point Type Consent` filter
- **Gotcha:** Consent is only enforced if the Segment is configured with consent filtering. It is NOT automatically applied — you must explicitly add the consent filter to every segment intended for outbound activation.

---

## Data Encryption

- Data at rest: AES-256, managed by Salesforce (Hyperforce)
- Data in transit: TLS 1.2+
- Shield Platform Encryption: Data 360 DMO fields can be encrypted with Shield if the org has Shield licensed — requires separate configuration
- PII fields in DLOs are encrypted at the storage layer but are accessible to any user with Data Cloud Admin

---

## IP Restrictions and Connected App Security

Inbound API ingestion (Pub/Sub API, Bulk Ingestion API) uses Connected Apps for authentication. Apply these controls:

- Enable IP restrictions on the Connected App to allow only known source IPs
- Use `client_credentials` OAuth flow for server-to-server ingestion (no user context)
- Rotate client secrets on the Connected App every 90 days (or per your security policy)
- Never embed client secrets in client-side code — use server-side ingestion pipelines only

---

## Audit and Monitoring

| What | Where |
|---|---|
| Data Stream run history | Data Cloud Setup → Data Streams → Run History |
| Identity Resolution run logs | Identity Resolution → Run History |
| Segment publish logs | Segments → Activation History |
| API access logs | Event Monitoring (requires Event Monitoring license) |
| Data deletion requests | Privacy Center → Individual Erasure Jobs |

---

## GDPR / CCPA Compliance Patterns

**Right to Erasure (GDPR Art. 17):**
1. Identify all `Individual` source records for the person across all DLOs
2. Delete source records via the Bulk Ingestion API delete endpoint
3. Run Identity Resolution — the `Unified Individual` will be removed if all source records are gone
4. Verify via `Individual Identity Link` query that no links remain

**Data Portability:**
- Use the Data Cloud Query API (SOQL-like) to export all DMO records for a given `UnifiedIndividualId`
- Automation via Flow + Data Action is the recommended pattern for handling portability requests at scale

**Data Residency:**
- Hyperforce allows selecting the region where Data 360 data is stored
- Configure at org provisioning time — cannot be changed post-provisioning without a full re-provisioning
