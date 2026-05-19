# Data 360 — Metadata Tooling

## What Is and Isn't Deployable

Data 360 has partial Metadata API support. This is one of the most common surprises for teams used to full SFDX deployments.

| Component | Deployable via Metadata API | Notes |
|---|---|---|
| Calculated Insights | Yes | `CalculatedInsight` metadata type |
| Segments | Yes (Spring '25+) | `Segment` metadata type |
| Data Streams | No | Org-specific connections; recreate manually |
| Activation Targets | No | Credentials are org-specific |
| Identity Resolution Rulesets | No | Must configure manually per org |
| Data Model Object mappings | No | Recreate via UI or API |
| Data Actions | Partial | Action definition yes; trigger config no |
| Data Spaces | No | Org-specific |
| Connected Apps (for ingestion) | Yes | Via standard `ConnectedApp` metadata |

---

## Metadata Types

### CalculatedInsight

Stores the SQL definition and scheduling configuration for a Calculated Insight.

**File path:** `force-app/main/default/calculatedInsights/MyInsight.calculatedInsight-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CalculatedInsight xmlns="http://soap.sforce.com/2006/04/metadata">
    <dataSpaceName>default</dataSpaceName>
    <description>Total lifetime spend per customer</description>
    <expression>
        SELECT
            ssot__UnifiedIndividualId__c,
            SUM(ssot__GrandTotalAmount__c) AS TotalSpend__c
        FROM ssot__SalesOrder__dlm
        GROUP BY ssot__UnifiedIndividualId__c
    </expression>
    <label>Total Lifetime Value</label>
    <outputDmo>
        <outputDmoApiName>CustomerLTV__dlm</outputDmoApiName>
    </outputDmo>
    <targetField>
        <dataType>Number</dataType>
        <fieldLabel>Total Spend</fieldLabel>
        <fieldName>TotalSpend__c</fieldName>
        <isNullable>true</isNullable>
    </targetField>
</CalculatedInsight>
```

### Segment

Available from Spring '25. Stores filter criteria and activation references.

**File path:** `force-app/main/default/segments/HighValueCustomers.segment-meta.xml`

Note: Segment metadata is complex to author by hand. Use the UI to build segments, then retrieve via `sf project retrieve start --metadata Segment` to capture the XML for version control.

---

## SFDX Commands for Data 360

### Retrieve Calculated Insights

```bash
sf project retrieve start --metadata CalculatedInsight
```

### Deploy Calculated Insights

```bash
sf project deploy start --metadata CalculatedInsight
```

### Retrieve Segments

```bash
sf project retrieve start --metadata Segment
```

### List All Data Cloud Metadata in Org

```bash
sf org list metadata --metadata-type CalculatedInsight
sf org list metadata --metadata-type Segment
```

---

## Headless 360 (MCP) Tools for Data 360

Use `mcp__salesforce__run_soql_query` to query DMOs and DLOs directly from the agent context. The SOQL runs against the Data Cloud SOQL endpoint when the org has Data Cloud enabled and the query targets `__dlm` or `__dll` objects.

```
-- Example: query Unified Individual count
SELECT COUNT(Id) FROM ssot__UnifiedIndividual__dlm
```

Use `mcp__salesforce__retrieve_metadata` to pull down Calculated Insights and Segments:

```
{
  "metadataType": "CalculatedInsight",
  "targetDir": "force-app/main/default/calculatedInsights"
}
```

Use `mcp__salesforce__deploy_metadata` to push Calculated Insights to a target org:

```
{
  "sourcePath": "force-app/main/default/calculatedInsights",
  "checkOnly": false
}
```

---

## Version Control Conventions

Follow these conventions for Data 360 assets in the repository:

```
force-app/main/default/
  calculatedInsights/
    {ApiName}.calculatedInsight-meta.xml
  segments/
    {ApiName}.segment-meta.xml
```

For non-deployable components (Data Streams, Identity Resolution, Activation Targets), maintain runbooks in the engagement docs folder:

```
engagements/{customer}/docs/
  data-streams-runbook.md     ← step-by-step config for each Data Stream
  identity-resolution-runbook.md
  activation-targets-runbook.md
```

These runbooks should be detailed enough that another engineer can recreate the configuration from scratch in a new org.

---

## Data Cloud CLI (Preview)

Salesforce is developing a dedicated `sf data-cloud` CLI plugin. As of Spring '26 it is in pilot. Key commands when available:

```bash
# Trigger identity resolution run
sf data-cloud identity-resolution run --ruleset MyRuleset

# Trigger segment publish
sf data-cloud segment publish --name HighValueCustomers

# Query Data Cloud objects
sf data-cloud query --soql "SELECT COUNT() FROM ssot__UnifiedIndividual__dlm"

# Check ingestion job status
sf data-cloud ingest job status --job-id {jobId}
```

Use Headless 360 MCP tools as the preferred mechanism until the CLI plugin reaches GA.

---

## Monitoring and Observability

### Key Pages to Monitor in Setup

| What | Path |
|---|---|
| Data Stream run history | Data Cloud Setup → Data Streams → [Stream] → Run History |
| Identity Resolution status | Data Cloud Setup → Identity Resolution → [Ruleset] → Run History |
| Segment publish status | Segments → [Segment] → Activation History |
| Data Action failures | Data Cloud Setup → Data Actions → [Action] → Error Log |
| Ingestion API jobs | Data Cloud Setup → Ingestion API → Jobs |
| Profile count trends | Data Cloud Setup → Usage and Limits |

### Event Monitoring (if licensed)

The `DataCloudIngestionEvent` and `DataCloudQueryEvent` event types in Event Monitoring capture API-level activity for security and performance auditing. Enable via `Setup → Event Monitoring → Enable`.
