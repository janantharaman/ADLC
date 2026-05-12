---
source: Vlocity Build GitHub; OmniStudio transcripts (Apex Hours); EPC Guide; OM Guide; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: automation-patterns
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Automation Patterns

## OmniStudio as the Primary Automation Layer

E&U Cloud uses OmniStudio as its core automation and UI layer — not standard Flows or custom Apex for guided interactions. All CPQ wizards, enrollment flows, customer service scripts, and data integration patterns are built in OmniStudio components.

**Decision guide:**

| Use Case | Tool |
|---|---|
| Guided multi-step user interaction (quoting, enrollment, service request) | OmniScript |
| UI component / customer 360 view / dashboard card | FlexCard |
| Data extraction from Salesforce (multi-object SOQL) | DataRaptor Extract |
| High-performance single-object SOQL | DataRaptor Turbo Extract |
| Insert/update multiple related records in one transaction | DataRaptor Load |
| JSON-to-JSON transformation / data reshaping | DataRaptor Transform |
| Server-side processing / system integration / backend orchestration | Integration Procedure |
| Simple single-object automation, no user interaction | Standard Flow (Record-Triggered) |
| Complex business logic not achievable declaratively | Apex (via ItemImplementation__c for OM tasks) |

---

## Pattern 1 — OmniScript (Guided Interaction)

OmniScript drives all customer-facing and agent-facing guided flows in E&U Cloud.

**Key configuration:**
```
Type: e.g., "Enrollment"
SubType: e.g., "EnergyEfficiencyProgram"
Language: "English"
IsLwcEnabled: true  (required for new builds; Angular runtime deprecated)
IsActive: true
```

**Unique key format:** `Type_SubType_Language_VersionNumber`

**LWC embedding in Experience Cloud:**
```html
<c-omni-script-wrapper
    omni-script-id="Enrollment_EnergyEfficiencyProgram_English"
    hide-header="true">
</c-omni-script-wrapper>
```

**Calling an Integration Procedure from an OmniScript step:**
- Use "Integration Procedure Action" step type
- Set `Remote: true` for server-side execution
- Map OmniScript context variables to IP input parameters
- Map IP output back to OmniScript context

**Saving in-progress state:** Set `IsReusable: true` on the OmniScript; state is saved to `OmniScriptInstance__c`.

---

## Pattern 2 — DataRaptor Extract (Multi-Object SOQL)

Use when pulling data from multiple related Salesforce objects for an OmniScript step or FlexCard.

```
Type: Extract
Object/Field mappings: SOQL-based
Filter: Account.Id = {contextId}
```

**Best practices:**
- Limit to ≤3 objects per DataRaptor (performance)
- Use indexed/sortable filter fields (Id, ExternalId, lookup fields)
- Use relationship queries instead of separate DataRaptors per object where possible
- For single-object high-volume queries: use **Turbo Extract** (significantly faster; no formula fields)

**Turbo Extract limitations:**
- Does NOT support formula fields in output
- Does NOT support complex output mappings
- Best for: billing account lookup, service point retrieval, simple account data

---

## Pattern 3 — DataRaptor Load (Multi-Record DML)

Use when creating or updating multiple related records in a single transaction (e.g., creating Order + OrderItems + FulfilmentRequest in one step).

```
Type: Load
Operations: Insert / Upsert / Update (auto-detected by presence of record Id)
```

**Logic:** If record Id is present in the input → update/upsert. If no Id → insert. Intelligence is built-in.

**Limitations:**
- Does not enforce FLS automatically — validate field access before loading sensitive fields
- Bulk CalculationMatrixRow operations only process when record count ≥ 2,000

---

## Pattern 4 — Integration Procedure (Server-Side Orchestration)

Integration Procedures are the server-side processing layer — equivalent to an Apex service class but fully declarative.

All steps execute in one Salesforce transaction. Available step types:

| Step Type | Use |
|---|---|
| DataRaptor Extract/Load | Read/write Salesforce data |
| HTTP Action | Call external REST/SOAP API (must use Named Credential) |
| Conditional (IF) | Branch logic |
| Loop | Iterate over collections |
| Set Values | Assign variables or transform data |
| Response Action | Control what data is returned to caller; trim response payload |
| Matrix Action | Call a Calculation Matrix |
| Procedure Action | Call another Integration Procedure |
| Apex Action | Call an Apex class (when declarative options insufficient) |

**Caching:**
```
Enable Cache: true
Cache Scope: Session | Org
TTL: 300 (seconds)
```
Use org-level caching for reference data (product catalog, calculation matrices). Use session-level for user-specific data (account details, basket state).

**Exposing as REST endpoint:**
- Toggle `Remote: true` on the IP
- External systems call: `POST /services/apexrest/v1/EnergyConsumption/GetCurrentRates`
- Authenticate callers via Connected App + OAuth 2.0

**"Chain on Step" feature:**  
When an IP is approaching governor limits (CPU time, SOQL queries), use Chain on Step to spin up a new transaction. Prevents governor limit exceptions in large orchestration flows.

**Governor limit awareness:**
- Each IP runs in one Salesforce transaction — governor limits apply
- HTTP Action steps consume callout quota (100 callouts/transaction)
- Large DataRaptor Loads consume DML operations
- Use Apex Actions only when hitting declarative limits

---

## Pattern 5 — Order Decomposition and Orchestration

The E&U Order Management flow:

```
1. Commercial Order created (Order + OrderItems)
2. Decomposition: OrderItem → FulfilmentRequestLine (via DecompositionRelationship__c)
3. OrchestrationScenario lookup: action + sub-action + product → OrchestrationPlanDefinition
4. OrchestrationPlan assembled from definition
5. OrchestrationItems (tasks) created per OrchestrationItemDefinition
6. OrchestrationDependency enforces execution sequence
7. Each item routed to: ManualQueue (human task) OR automated execution via ItemImplementation__c
8. Custom Apex registered via ItemImplementation__c executes when item is processed
```

**Custom Apex for OM tasks:**
```apex
// Register in ItemImplementation__c: Class = MyFulfilmentAction
global class MyFulfilmentAction implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String,Object> input,
                                Map<String,Object> output, Map<String,Object> options) {
        if (methodName == 'doWork') {
            // Perform fulfilment work
            // Read from input map, write results to output map
        }
        return true;
    }
}
```

---

## Pattern 6 — CPQ Pricing with Calculation Matrix

Calculation Matrices drive pricing rules, eligibility checks, and discount tables.

```
CalculationMatrix__c
  → CalculationMatrixVersion__c (active version)
  → CalculationMatrixColumn__c (input/output columns)
  → CalculationMatrixRow__c (lookup table rows)
```

**Calling from CPQ:**
- CPQ pricing engine evaluates PricingPlan → PricingPlanStep → CalculationMatrix
- `DefaultPricingPlan` custom setting controls which plan runs at runtime
- Switch off pricing in CPQ API calls when pricing computation is not needed (significant performance gain)

**Calling from Integration Procedure:**
```
Step Type: Matrix Action
Matrix: My_Pricing_Matrix
Inputs: { "CustomerSegment": "Residential", "UsageTier": "High" }
Outputs: { "DiscountRate": 0.15 }
```

---

## Pattern 7 — Program Application REST API

The only documented REST API in the E&U Developer Guide. Used for programmatic program enrollment.

**Endpoint:** `POST /services/data/v{version}/connect/energy-utilities/programs/{programId}/applications`

**Request body types:**
- `ProgramApplicationInput` — full application
- `ProgramApplicationItemInput` — line item within an application
- `ProgramApplicationFileInput` — file attachment for an application

**Response:** `ProgramApplicationOutput`

**Use case:** External portals, IVR-driven enrollment, batch enrollment from CIS system.

---

## Pattern 8 — FlexCard for Customer 360

FlexCards compose the Contact Center Console and customer 360 view.

```
VlocityCard / OmniUiCard
  → Data Source: DataRaptor (most common) | SOQL | Integration Procedure | REST
  → Child FlexCards: embedded for hierarchical layouts
  → Actions: OmniScript launch | Navigate | Custom LWC action
```

**Performance pattern:**
- Use DataRaptor Turbo Extract as data source where possible (fastest)
- Enable FlexCard caching for reference data cards (product catalog, rate plans)
- Limit child FlexCard nesting to 3 levels (performance degrades beyond this)

**LWC activation:**
- FlexCards must be "activated" to generate LWC components
- `"enableLwc": true` in card definition
- LWS (Lightning Web Security) required for `@salesforce/` imports within activated FlexCards

---

## Pattern 9 — Trigger Pattern (vlocity_cmt Managed)

E&U Cloud managed package includes pre-built triggers on its managed objects. You cannot modify these triggers. For custom logic on managed objects:

1. Use **Custom Metadata-driven trigger configuration** via `vlocity_cmt__VlocityStateTransitionRule__c`
2. Use **Record-Triggered Flows** on managed objects (does not conflict with managed triggers)
3. Use **Custom triggers on standard objects** extended by E&U (Account, Order, Asset) following the 1-trigger-per-object handler pattern
4. Register custom Apex via **ItemImplementation__c** for OM task execution (not a trigger — called by OM engine)

Never add Apex DML directly on `vlocity_cmt__` objects from custom triggers — use the OM orchestration engine or DataRaptor Load to maintain managed object integrity.
