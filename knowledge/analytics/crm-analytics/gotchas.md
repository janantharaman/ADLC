---
source: Salesforce Trailhead — Build and Administer CRM Analytics trail; Quick Start: CRM Analytics; CRM Analytics Data Integration Basics; real-world deployment observations (2026-05-17)
product: CRM Analytics
section: gotchas
last-updated: 2026-05-17
---

# CRM Analytics — Gotchas & Known Issues

## Data Pipeline

### Silent Data Sync Failures
**Symptom:** Dashboard shows stale data; no error visible to end users.  
**Cause:** Data Sync job fails (API limit hit, object schema changed, connected object deleted) but does not surface an error to dashboard viewers.  
**Prevention:** Monitor Data Manager → Job Log daily. Set up a scheduled Flow that queries `AsyncApexJob` or the Analytics job log and posts to Slack if any job has a Failed status. Never assume data freshness without checking the job log.

### Schema Change Breaks Recipe
**Symptom:** Recipe fails after a Salesforce admin adds, renames, or deletes a field on a connected object.  
**Cause:** Recipe references the old field name; the connected object sync now returns a different schema.  
**Fix:** Open the recipe → input node → refresh schema → remap or add the changed field. Update any formula nodes that reference the renamed field.

### Dataset API Name Immutability
**Symptom:** All SAQL queries in dashboards return errors after a dataset was renamed.  
**Cause:** Dashboard widget SAQL references dataset API names. Renaming the dataset in the UI changes the display name only on some Salesforce versions, but can change the API name in others.  
**Prevention:** Treat dataset API names as immutable after first deployment. Document the API name convention at project start and freeze it.

### Dataflow Dependency Order
**Symptom:** Dataflow fails with "source dataset not found."  
**Cause:** Multiple dataflows reference each other's output datasets. The downstream dataflow runs before the upstream one completes.  
**Fix:** In Data Manager → Schedules, sequence dataflows explicitly. Or consolidate into a single dataflow / recipe.

### Incremental Sync Missing Records
**Symptom:** Records updated in Salesforce do not appear in the CRM Analytics dataset.  
**Cause:** Incremental Data Sync uses `SystemModstamp` — records are only picked up if their SystemModstamp changed since the last sync. Bulk data operations that bypass triggers may not update SystemModstamp.  
**Prevention:** For objects where bulk data loads are common, run occasional full syncs (weekly) to catch any missed incremental records.

## Security

### Admin Bypasses Security Predicate
**Symptom:** Admins see all data in embedded dashboards; regular users do not.  
**Cause:** Users with "Manage Analytics" permission bypass all dataset security predicates by design.  
**Prevention:** Always test as a non-admin Viewer persona user before go-live. Create a test user with Viewer permission set only.

### Predicate Not Deployed to Production
**Symptom:** All users see all data after deploying to production.  
**Cause:** Security predicates are stored as dataset metadata. When deploying via change set or SFDX, the `WaveDataset` metadata type must be included, and the predicate must be configured in the production dataset editor post-deployment.  
**Prevention:** Add "Verify predicate set on all datasets" to the deployment checklist. Predicates are configuration, not code — verify manually in Data Manager.

### Permission Set Not Assigned
**Symptom:** User receives "Insufficient privileges" or cannot see Analytics Studio.  
**Cause:** The `CRM Analytics Plus User` (or Growth User) permission set was not assigned.  
**Fix:** Setup → Permission Sets → CRM Analytics Plus User → Manage Assignments → add the user.

## Dashboards

### Faceting Only Works Within Same Dataset
**Symptom:** Clicking a chart does not filter another chart on the same dashboard.  
**Cause:** Automatic faceting only works when both widgets reference the same dataset. Cross-dataset filtering requires explicit bindings.  
**Fix:** Add a binding that passes the selected dimension value from Widget A's query result to Widget B's SAQL filter.

### Template App Customisations Overwritten
**Symptom:** Custom changes to a template app (e.g., Sales Analytics) disappear after a Salesforce release update.  
**Cause:** Salesforce auto-updates managed template apps. Custom edits to the original template app are overwritten.  
**Prevention:** Never edit template app dashboards directly. Always clone the dashboard or the entire app before customising.

### Dashboard Load Slow (Too Many Widgets / SOQL Steps)
**Symptom:** Dashboard takes 10+ seconds to load.  
**Cause 1:** Too many widgets on a single page — all queries run on open.  
**Cause 2:** Multiple SOQL Direct Query steps on large objects hit governor limits.  
**Fix 1:** Split into multiple pages. Use conditional visibility to defer non-critical widget loads.  
**Fix 2:** Replace SOQL steps with Data Sync + recipe for any object with more than 10K records.

### Binding Syntax Errors Are Silent
**Symptom:** Dashboard filter does not respond to user selection. Widget shows all data regardless of selection.  
**Cause:** SAQL binding expression has a typo or incorrect column reference. CRM Analytics does not surface binding errors explicitly.  
**Prevention:** Test bindings after every change using the Dashboard Designer's preview mode. Use `cell(widget_name.result, 0, "column_name")` pattern and verify the column name matches the query output.

## Embedding

### Embedded Dashboard Shows All Data to Non-Owner Users
**Symptom:** Every Salesforce user on a record page sees all data in the embedded dashboard, not just their own.  
**Cause:** No record-context filter was configured in the Lightning component, or the security predicate was not set.  
**Fix:** Configure the CRM Analytics Dashboard Lightning component → Filter → pass the record's Id field to the dataset dimension. Also verify the security predicate is active.

### Embedded Dashboard Empty After Deployment
**Symptom:** The embedded dashboard is empty or shows "no data" immediately after a production deployment.  
**Cause:** Datasets are empty in the new org — data pipeline has not run yet.  
**Fix:** After deploying to production, enable Data Sync → run all connected objects → run all recipes/dataflows → verify datasets are populated before go-live.

## Deployment

### Dataset Data Does Not Deploy
**Symptom:** After deploying to production, dashboards show empty datasets.  
**Cause:** Deployment moves metadata only (schema, configuration). Data stays in the source org.  
**Fix:** This is by design. Always run the data pipeline post-deployment. Include this in every deployment runbook.

### Recipe Input Nodes Reference Non-Existent Connected Objects
**Symptom:** Recipe fails in production with "connected object not found."  
**Cause:** The connected object (Salesforce object enabled for Data Sync) was enabled in the sandbox but not in production.  
**Fix:** Enable the same connected objects in production before running the recipe. Use a deployment checklist that includes "enable all required connected objects in target org."

### WaveRecipe Metadata Deployment Fails
**Symptom:** `WaveRecipe` metadata type fails to deploy via change set.  
**Cause:** Recipe JSON references connected object names or dataset API names that differ between sandbox and production, or the recipe JSON contains sandbox-specific credentials.  
**Fix:** Review recipe JSON before deployment for hardcoded org-specific references. Use relative paths and API names, not sandbox instance URLs.

## Licensing and Features

### Standard Trailhead Playground Orgs Cannot Use CRM Analytics
**Symptom:** Analytics Studio link not visible in App Launcher.  
**Cause:** Standard Trailhead Playgrounds do not include a CRM Analytics license.  
**Fix:** Use the dedicated Analytics Developer Edition: `trailhead.salesforce.com/promo/orgs/analytics-de`.

### Fiscal Year Misconfiguration Causes Wrong Date Groupings
**Symptom:** "FY24" in a dashboard covers calendar year 2024 instead of the organisation's fiscal year.  
**Cause:** Analytics fiscal year setting not configured before first recipe run.  
**Fix:** Setup → Analytics → Settings → Fiscal Year → set start month before running any recipe or dataflow. Datasets created before this change will need to be re-generated.

## SAQL

### SAQL Dataset Load Name Is API Name, Not Label
**Symptom:** `load "My Dataset"` fails.  
**Cause:** SAQL `load` statement uses the dataset API name, not the display label. API names often differ from display names (e.g., display label "Opportunities Pipeline", API name "Opportunities_Pipeline").  
**Fix:** Check the dataset API name in Analytics Studio → Datasets → click dataset → copy the API Name field.

### SAQL Date Filtering Uses Epoch Seconds for Dynamic Dates
**Symptom:** Relative date filter (e.g., "last 90 days") produces incorrect results when using `now()`.  
**Cause:** `now()` returns epoch milliseconds in some CRM Analytics versions; date range filters in SAQL use epoch seconds. Off by a factor of 1000.  
**Fix:** Use `date('CloseDate_Year', 'CloseDate_Month', 'CloseDate_Day') in [...]` syntax for relative date ranges, or test epoch arithmetic carefully.

### Cogroup Join Produces Unexpected Row Count
**Symptom:** Dataset joined via `cogroup` has more rows than expected.  
**Cause:** `cogroup` in SAQL is a full outer join — every non-matching row from both sides is included with nulls. If the datasets have different granularities, row multiplication can occur.  
**Fix:** Pre-aggregate both sides to the same grain before the cogroup, or filter out null-key rows post-cogroup.
