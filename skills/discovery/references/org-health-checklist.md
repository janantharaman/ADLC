# Org Health Checklist — Discovery Reference

Use this checklist to ensure nothing is missed during the org health baseline step.
Check each item and record findings in the discovery artifact.

## Core Platform
- [ ] Custom objects — count, naming, descriptions present
- [ ] Custom fields — orphaned fields (no automation, no page layout)
- [ ] Record types — per object, active vs inactive
- [ ] Page layouts — count per object, assignments per profile
- [ ] Compact layouts — configured or default
- [ ] List views — shared vs personal

## Automation
- [ ] Active Flows — count by type (Screen, Record-Triggered, Scheduled, Auto-launched)
- [ ] Inactive Flows — flag large numbers as tech debt
- [ ] Apex Triggers — one trigger per object rule in use?
- [ ] Process Builder — any active? Flag for migration to Flow
- [ ] Workflow Rules — any active? Flag for migration to Flow
- [ ] Approval Processes — count and object coverage

## Data Quality
- [ ] Required fields with no default — risk of data entry errors
- [ ] Duplicate rules — configured per key object?
- [ ] Matching rules — active?
- [ ] Data quality (run COUNT on key objects, note nulls on required fields)

## Security
- [ ] Org-Wide Defaults per object — Public Read/Write is a risk flag
- [ ] Profile count — more than 20 is complexity risk
- [ ] Permission set count — document all custom permission sets
- [ ] Connected Apps — what has OAuth access to the org?
- [ ] Named Credentials — what external integrations exist?
- [ ] Auth Providers — SSO configured?
- [ ] Session settings — timeout, IP restrictions

## Integrations
- [ ] Named Credentials — list all
- [ ] External Services — list all
- [ ] Custom Metadata Types with endpoint URLs — note any hardcoded endpoints
- [ ] Outbound Messages — any active?
- [ ] Platform Events — any defined?
- [ ] Change Data Capture — any enabled objects?

## Apex and Code
- [ ] Apex classes — count, coverage %, any < 75% coverage
- [ ] Apex scheduled jobs — count, frequency, last run
- [ ] Batch jobs — any active?
- [ ] Future methods — any in use? Flag for async pattern review

## Agentforce / Einstein
- [ ] Agentforce licenses — assigned?
- [ ] Einstein feature licenses — which are active?
- [ ] Existing Bot definitions — names, status, channels
- [ ] Einstein Copilot — enabled?
- [ ] Agentforce topics — any configured?
- [ ] Prompt Templates — any existing?

## Limits (flag > 80% as HIGH RISK)
- [ ] Daily API calls
- [ ] Concurrent API calls limit
- [ ] SOQL queries per transaction
- [ ] DML statements per transaction
- [ ] Heap size
- [ ] CPU time
- [ ] Storage (data + file)
- [ ] Active Flow interviews

## Packages
- [ ] Managed packages — note namespace, version, support status
- [ ] Unmanaged packages — flag any (upgrade path risk)
- [ ] AppExchange products — note which are active

## DevOps
- [ ] Source control connected? (DevOps Center, Gearset, Copado, etc.)
- [ ] Deployment pipeline exists?
- [ ] Sandbox strategy — how many sandboxes, what types, refresh schedule
- [ ] Change sets in use? (flag as legacy)
