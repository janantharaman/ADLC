---
source: Salesforce Apex Hours YouTube series "Salesforce OmniStudio Beginner Tutorials" (19 episodes); playlist: PLaGX-30v1lh2QKI-Ud269FUaFiUtebsQ6; grounded 2026-05-11
cloud: Cross-Cloud (OmniStudio / Salesforce Industries)
section: omnistudio
last-updated: 2026-05-11
---

# OmniStudio — Salesforce Industries

---

## 1. What It Is

OmniStudio is a declarative digital engagement suite for building guided customer and employee interactions on the Salesforce platform. It was formerly the **Velocity Digital Interaction Platform**, developed by Vlocity Inc., which Salesforce acquired in **2020**. After the acquisition, the tooling was rebranded OmniStudio and is now being moved from Vlocity's managed packages into Salesforce core.

**Problem it solves.** Standard Salesforce provides object-metadata-driven UIs that work well for simple CRM tasks. Industries like telecommunications, insurance, financial services, and utilities need guided multi-step processes that pull data from many systems, support pixel-precise consumer branding, and must run in both agent and self-service channels simultaneously. Building this entirely in Apex and custom LWC is expensive and slow. OmniStudio provides click-based tooling that reduces a complex multi-system integration from ~42 developer-days to ~1 day, and a simpler integration from ~2 hours to ~30 minutes.

**Editions / clouds.** OmniStudio is generally available as part of:
- Communications Cloud, Media Cloud, Energy & Utilities Cloud (formerly Vlocity CMT)
- Health Cloud, Insurance Cloud (formerly Vlocity HINS)
- Manufacturing Cloud, Financial Services Cloud (as an add-on)
- Automotive Cloud, Public Sector Solutions
- Available as a standalone add-on SKU for Sales Cloud and Service Cloud

**Architecture principle.** OmniStudio runs on top of the standard Salesforce platform. Components are stored as custom object records (in managed-package orgs) or as standard metadata objects (in OmniStudio-enabled orgs). At activation time, each OmniScript and FlexCard compiles to a Lightning Web Component. OmniStudio does not replace Apex or Flow — it coexists with them and can call Apex classes directly.

**Two packaging modes** (relevant for DevOps):
- **OmniStudio for Velocity** — components stored in Vlocity custom objects (e.g., `%vlocity_cmt%__OmniScript__c`); uses package runtime; requires IDX/VBT for deployment.
- **OmniStudio (standard)** — components stored in standard platform objects (`OmniScript`, `OmniDataTransform`, `OmniIntegrationProcedure`, `OmniUiCard`); supports metadata API and SFDX CLI; can use standard runtime for better performance. Enabled by toggling "OmniStudio Metadata" in Setup > OmniStudio Settings. **This setting cannot be reversed once enabled.**

---

## 2. Component Overview Table

| Component | Type | Purpose | Replaces / Equivalent | When to Use |
|---|---|---|---|---|
| OmniScript | Frontend / UI | Step-based guided interaction wizard | Salesforce Screen Flow | Any multi-step guided process for agents, customers, or partners |
| FlexCard | Frontend / UI | Contextual data display card with actions | Custom LWC record detail component | Displaying summarized record data with contextual actions (e.g., 360 view panels) |
| DataRaptor Extract | Backend / Data | Read data from one or more Salesforce objects | SOQL query + Apex | Fetching Salesforce data for OmniScripts or FlexCards |
| DataRaptor Turbo Extract | Backend / Data | Fast single-object read from Salesforce | Simple SOQL + Apex | High-performance simple queries; no formula/transformation needed |
| DataRaptor Transform | Backend / Data | Reshape/map JSON payloads | Apex JSON manipulation | Converting API response payloads; restructuring JSON nodes |
| DataRaptor Load | Backend / Data | Write data into Salesforce objects (DML) | Apex DML / Data Loader | Inserting or upserting records; parent-child DML in one step |
| Integration Procedure | Backend / Orchestration | Server-side declarative pipeline of actions | Apex service class | Orchestrating multi-step server logic: callouts, transforms, conditional branching, error handling |
| OmniOut | Deployment / Channel | Expose OmniScripts and FlexCards outside Salesforce | Lightning Out (beta) | Consumer-facing external sites, mobile apps, Adobe Experience Manager |
| IDX Workbench / Industry DX CLI (VBT) | DevOps / Tooling | Export, compare, and import OmniStudio metadata as DataPacks | SFDX CLI (for standard metadata) | CI/CD pipelines; migrating components between orgs |
| OmniAnalytics | Analytics | Capture click-stream and performance telemetry from OmniScripts and FlexCards | Custom event logging | Measuring conversion/abandonment, performance tuning, funnel analysis |
| Interaction Console | UI / Framework | Agent-facing console embedding FlexCards and launching OmniScripts | Service Console + custom LWC | Contact center 360-degree customer views |
| OmniSupervisor | UI / Framework | Supervisor-level view for agent and queue monitoring | Standard Omni-Channel supervisor | Contact center management alongside OmniStudio interactions |

---

## 3. OmniScript

### What It Is

OmniScript is OmniStudio's guided interaction framework — a step-based UI flow that walks users through a business process. It is the front-end, client-side component. Think of it as the OmniStudio analog to Salesforce Screen Flow, but optimized for consumer/partner-facing channels with richer UI, external system integration, and multi-channel deployment.

Each OmniScript compiles to a **Lightning Web Component** on activation. Because it is LWC-based, it can be embedded anywhere an LWC can run: Lightning App Builder, Experience Cloud, or off-platform via OmniOut.

### Unique Identifier: Type, SubType, Language

An OmniScript is uniquely identified by **Type + SubType + Language**. The Name field is only a label for a specific version. Only one version per Type/SubType/Language combination can be active at a time. When creating a new OmniScript with an existing Type/SubType/Language, the system assigns the next version number automatically (e.g., version 3 becomes version 4).

**Naming convention.** Type and SubType should describe the domain and action, e.g., `Account / EditPrimary`, `Quote / CreateBusiness`. Use them consistently because they become the unique identifier for calling the OmniScript from FlexCards, Apex, and URLs.

### Element Types

Elements fall into six categories in the Build panel:

| Category | Key Elements |
|---|---|
| **Actions** | Integration Procedure Action, DataRaptor Extract Action, DataRaptor Post Action (Load), HTTP Action, Remote Action (Apex), OmniScript Action (nesting), Navigate Action, Calculation Procedure, Set Values, Set Errors, Message, PDF Action, Email Action, DocuSign Envelope Action |
| **Display** | Text Block (rich text, tables, images), Disclosure |
| **Functions** | Formula, Aggregation |
| **Groups** | Step, Block, Edit Block, Type-Ahead Block, Action Block |
| **Inputs** | Text Input, Text Area, Telephone, URL, Email, Date, DateTime, Number, Currency, Range, Radio, Checkbox, Multi-Select, Select (picklist), Lookup, File Upload, Signature, Password |
| **OmniScripts** | Reusable OmniScript (nesting a child OmniScript) |

### Step vs. Group (Block)

- **Step** — equivalent to one page/screen. Steps appear in the step-chart progress indicator. Each Step has a name that becomes a JSON node in the data object (e.g., a Step named `stepAccount` means all input elements inside it are addressed as `stepAccount:fieldName`).
- **Block** — a sub-container inside a Step. Blocks can be made conditional (show/hide based on data). An Edit Block allows actions to be placed inside it.
- **Action Block** — a container whose enclosed actions execute asynchronously (fire in parallel); waits for all to complete before proceeding to the next step. Useful for fetching data from three APIs simultaneously.

**Placement rule.** Input elements (Text Input, Radio, etc.) can only exist inside a Step or Block. Actions (Integration Procedure, DataRaptor, Navigate) must be placed outside Steps.

### Data Flow: The JSON DOM

OmniScript maintains a live **JSON state object** (called the JSON DOM or Data JSON) throughout execution. Every element's value is stored in this object. The structure mirrors the hierarchy: `StepName:FieldName`.

**Merge variable syntax.** Reference values in the JSON DOM using `%NodeName:FieldName%` notation (or `%ContextId%` for the record ID passed in). Example: `%stepAccount:accountId%`.

**Send/Response Transformations on actions.** Each action element has:
- **Send JSON Path** — filter the outgoing payload to a specific node (e.g., `stepContacts:blockCreateContact` sends only that subtree). In an OmniScript action, the filtered node is still present at its original path in the DOM. In an Integration Procedure action element, the path is stripped to a flat structure.
- **Send JSON Node** — rename the parent node of the outgoing payload.
- **Response JSON Path** — trim the incoming response to a specific node.
- **Response JSON Node** — rename the parent of the incoming response node.
- **Send Only Additional Input** checkbox — when checked, only the key-value pairs defined in Additional Input are sent, not the full JSON DOM. Use this to prevent sending unnecessary data.

### Context ID

When an OmniScript is launched from a FlexCard action or record page, it receives a `ContextId` (the Salesforce record ID). In Preview mode, paste a real record ID into the Context ID field and click Reset Data to test with live data.

### Seed Data and Set Values

**Set Values** elements are used to pre-populate JSON DOM nodes before user interaction, define static variables (e.g., API keys), construct complex structured nodes, or write formula results into the DOM. In testing, Set Values is used to auto-fill steps so you do not have to manually type test data each time.

**Remote Properties (Extra Payload).** On action elements, Extra Payload allows injecting additional key-value parameters into the outgoing request. These are added alongside the filtered payload.

### LWC Custom Components Inside OmniScript

Drag and drop a **Custom Lightning Web Component** element and reference the component's API name. The OmniScript passes data to the LWC via attributes and receives data back via events. Industry-provided components (e.g., `vlocity_ins_os_SingleInstance`, digital commerce catalog LWCs) are invoked this way. For these, properties intended for the underlying service must be configured via **Edit Properties as JSON**, using the `productsAction` wrapper that routes the configuration to the service rather than the LWC itself.

### Reusable OmniScripts

Mark an OmniScript as **Reusable** in its Setup tab. It then appears in the OmniScripts element category and can be dragged into any other OmniScript. A reusable OmniScript cannot call another reusable OmniScript (one level of nesting only, to prevent loops).

### Navigate Action

Place a Navigate Action as the last element. It redirects the user after completion. Configure: Object API Name (e.g., `Account`), Record ID (e.g., `%ContextId%`), and whether to open a new tab or replace the current tab. This is the declarative replacement for the old "Done" action in Angular-based OmniScripts.

### Activation

Activation compiles the OmniScript definition into a Lightning Web Component (four files: XML, HTML, JS, CSS). The LWC is deployed to the org. Only the active version is executed by callers. After activation, a new version must be created to make changes — the active version is locked.

### Preview and Action Debugger

- **Preview mode** — renders the OmniScript live with the current JSON DOM visible on the right. The Data JSON tab shows the live state of all values.
- **Action Debugger tab** — lists every action (Integration Procedure, DataRaptor, HTTP, Remote) with its request parameters and response. Use the debugger to confirm: what was sent, what was received, and what was set. Copy the response JSON from here to build DataRaptor output mappings.

### OmniScript vs. Screen Flow (Decision Guide)

Use OmniScript when: consumer/partner-facing channel, external system data required without code, branding/responsive UI critical, reuse across agent + self-service channels, OmniOut off-platform deployment needed.

Use Screen Flow when: internal employee-only, pure Salesforce data (no external APIs without Apex), simple approval/process use case, development team is unfamiliar with OmniStudio.

---

## 4. FlexCard

### What It Is

FlexCard is OmniStudio's contextual data display component. It is a **read-plus-action** card: it fetches and displays data from any configured source, applies conditional state logic, and provides configurable actions. On activation, it compiles to a Lightning Web Component. FlexCards are the primary building block of the Interaction Console and any 360-degree view.

The FlexCard Designer is a WYSIWYG canvas — changes appear in real time as you drag, drop, resize, and style elements.

### Card Types

- **Standard card** — standalone card placed on a Lightning record page or console.
- **Child card** — a card marked as a child (checkbox in setup). It can be embedded inside another FlexCard and receive data from the parent via attributes (`parent.fieldName` notation). There is no limit on nesting depth.
- **Recursive card** — a child card that embeds itself. Used when data is hierarchically structured (e.g., product bundles with child bundles). Requires a conditional to prevent infinite rendering when the nested records node is undefined.

### Data Sources

| Source | Use Case |
|---|---|
| SOQL | Simple Salesforce object query; supports `{recordId}` parameter |
| Apex | Call a custom Apex class |
| DataRaptor Extract | Full DataRaptor with formulas and multi-object queries |
| Integration Procedure | Orchestrated server-side logic; required when mixing Salesforce data with external API data |
| Streaming API | Real-time platform events |
| Custom JSON | Hardcoded JSON for prototyping or testing before a backend is ready |

**Data Source Wizard.** When creating a new FlexCard, a guided wizard walks through source selection, parameter mapping, and a test fetch. The **Response Solution Path** (node filter) lets you scope the card's data to a specific JSON node (e.g., `account` from a response containing both `account` and `contact` nodes).

**Render Key.** For list cards (repeat enabled), set the Render Key to a unique field (e.g., record Id). On partial re-render, only modified records are updated in the DOM rather than the entire list.

### States

Each FlexCard has one or more **states**. States are evaluated top-to-bottom; the first state whose condition evaluates to true is rendered. Only one state is shown at a time.

- Define conditions on states using any field from the data source.
- **Blank State** — a special state (checkbox) displayed when the data source returns no data. Always configure a blank state.
- Conditions are evaluated only in **Preview mode**, not in the canvas itself.

### Actions

| Action Type | Purpose |
|---|---|
| Card — Select Card | Makes the card selectable (single or multi-select); used with OmniScript integration to pass selected items into the JSON DOM |
| Card — Set Values | Sets key-value data on the card's session object |
| Card — Reload | Re-executes the data source |
| Flyout | Opens a popover or modal showing a child FlexCard, OmniScript, or custom component |
| Navigate | Standard page reference navigation (record detail, external URL, tab) — fully declarative |
| OmniScript | Launches an OmniScript; passes context |
| Data Action | Triggers a backend operation (create/update record) without requiring a response; can ignore response |
| Custom Event | Fires a custom DOM event to a sibling or parent component |
| PubSub | Fires a platform-level pub/sub event across the page (works across console tabs) |
| Update OmniScript | Sends selected data from an embedded FlexCard back into the parent OmniScript's JSON DOM |

### Parent-Child Data Passing

Parent FlexCard passes attributes to child FlexCard using the attribute configuration in the Flex Card element. Inside the child, all passed attributes are accessible via `parent.attributeName`. The child can also have its own independent data source. Both can be active simultaneously.

**Passing from OmniScript to embedded FlexCard.** When a FlexCard is embedded in an OmniScript using the Custom Lightning Web Component element, pass:
- `recordId` — maps to the card's record ID
- `records` — passes an array as the card's data payload (set `parentData: true`)
- `parentObject` — a custom JSON object accessible as `parent.fieldName` inside the child card

### Selectable Items

FlexCards support declarative **selectable items** (no code). Configure:
1. A `Select Card` action with a list name (e.g., `selectedItems`) and select type (single or multi).
2. An event listener capturing the `selectCards_selectedItems` event.
3. An `Update OmniScript` action to persist selections to the parent OmniScript's JSON DOM.

### Styling

- **SLDS** — Salesforce Lightning Design System; recommended for internal agent-facing pages.
- **Newport Design System** — OmniStudio's own open-source design system; recommended for consumer-facing branding; supports global CSS injection.
- **Conditional Styles** — apply different CSS properties (color, font-size, background) based on data field values. Configured on elements under the Style tab.
- **CSS classes** — add SLDS or custom class names at element level or container level.
- **Card-level CSS** — inject a custom CSS file scoped to that specific card.

### Embedding Custom LWC in FlexCard

Reference any custom LWC or OmniStudio base component by its API name. Pass data via attributes. Communicate back to the card via standard DOM events (captured by the FlexCard's declarative event listener framework). Note: `lightning-input` and `lightning-combobox` are **not** included in the OmniOut off-platform package — use OmniStudio base component equivalents.

### OmniScript Support Toggle

In FlexCard Setup, enable **OmniScript Support** if the card will be embedded inside an OmniScript and needs to communicate with it (Update OmniScript actions, selectable items). For standalone cards not inside an OmniScript, leave this off.

### Publishing and Activation

After design, click **Activate**. This generates the LWC. After activation, **Publish Options** controls:
- Component target exposure (record page, home page, app page, community page)
- Component label (visible in App Builder)

Auto-generated LWC components are prefixed `c-cf` (card framework). Do not manually modify these files — they are regenerated on every activation.

### OmniStudio Runtime Consideration

When **OmniStudio Runtime is disabled** (package runtime), each activated FlexCard generates a standalone LWC file. Each LWC file has a **131,072 character limit**. Exceeding it causes activation failure. Mitigation: break large cards into smaller child cards.

When **OmniStudio Runtime is enabled** (standard runtime, requires standard object storage), FlexCards run against Salesforce's native runtime engine — no custom LWC is generated, the limit does not apply, performance is faster, and patch upgrades are automatic.

---

## 5. DataRaptor

### What It Is

DataRaptor is OmniStudio's declarative ETL (Extract, Transform, Load) tool for Salesforce data. It has four types, each purpose-built.

### Four Types

#### DataRaptor Extract
- Reads data from **one or more Salesforce objects** using relationship-aware queries.
- Supports formulas, complex output mappings, pagination, sorting.
- Output is JSON or XML.
- Use when: multi-object data retrieval, formula processing, complex output structure required.
- **Relationship queries**: instead of adding a second extract step for a related object, use dot-notation on the field path (e.g., `Opportunity.Account.BillingCountry`). This avoids an additional query and improves performance.

#### DataRaptor Turbo Extract
- Reads from **one Salesforce object only** (standard, custom, external, or custom metadata).
- Supports fields from related objects (one level via relationship traversal).
- Does **not** support formulas or complex output mappings.
- Output structure mirrors field names as-is — cannot be restructured.
- **Faster than standard Extract** at runtime due to a simpler execution engine.
- Use when: simple single-object read, no formula logic needed, performance is critical.

#### DataRaptor Transform
- Takes a JSON or XML input and maps/reshapes it to a different JSON or XML output.
- No Salesforce DML.
- Use when: reformatting API response payloads before passing to UI, converting XML to JSON, building structured output nodes (e.g., `current` and `forecast` nodes from a weather API), populating DocuSign templates, filling PDF fields.
- **Array item reference in formulas**: use `nodeArray|1:subNode` syntax (1-based index, not 0-based) to reference a specific item in an array within a formula.

#### DataRaptor Load
- Writes (insert, update, upsert) data into **one or more Salesforce objects** from a JSON or XML input.
- Handles parent-child DML in a single operation using **Link Mapping**: after creating a child record, the generated record ID is automatically populated into a field on the parent record within the same Load execution.
- **Upsert Key** — specify which field(s) uniquely identify a record to prevent duplicates (e.g., `LastName + FirstName` for Contact).
- **Required for Upsert** — specify which fields must have values before the DML is attempted. If any Required-for-Upsert field is empty, the record is skipped entirely.
- **Field Level Security**: Load enforces FLS by default (the operation runs as the executing user). Extract does NOT enforce FLS by default — enable "Check Field Security" in Options if FLS is required for reads.

### Input/Output JSON Mapping

The **Output** tab shows the expected vs. current JSON output structure. Use the **JSON Subnode** path notation to group output fields under named nodes (e.g., all account fields under `account`, all contact fields under `contact`). This allows callers to use the Response JSON Path to scope to only the node they need.

**Quick Match**: paste expected input JSON and expected output JSON, then click Match to auto-generate field mappings in seconds.

### Formulas

Available for Extract, Transform, and Load. Not available for Turbo Extract.

Categories: Numerical, Aggregation, Logical, String, Date/Time. Standard functions include `CONCAT`, `IF`, `TODAY`, `ADD`, `DAYMONTH`, `AVERAGE_LIST`, and many others (follows Salesforce formula reference). Custom formulas can also be defined and reused across DataRaptors and Integration Procedures.

**Formula output mapping**: the result of a formula defined in the Formulas tab must be explicitly mapped in the Output tab to appear in the DataRaptor's response. Defining a formula but not mapping it to an output path means the formula result is discarded.

### Caching

Configure in the Options tab: Platform Cache type (Session or Org), Time to Live in minutes. When a cache is warm, the DataRaptor returns cached data instead of executing a new SOQL query. Set **Ignore Cache** during development/testing.

### Bundles

DataRaptors can be grouped into **bundles** for export/import purposes. A bundle is a logical grouping of related DataRaptors (e.g., all DRs for a Quote process).

### DataRaptor Designer — Key Tabs

| Tab | Purpose |
|---|---|
| Extract | Define Salesforce object queries and filters (Extract and Turbo Extract only) |
| Formulas | Define formula expressions |
| Output | Map extraction results / formula results to output JSON nodes |
| Options | Caching, field security, override null inputs |
| Preview | Run live test with sample input; view debug logs and query executed |

### DataRaptors Have No Versions

Unlike Integration Procedures and OmniScripts, DataRaptors have no versioning and no active/inactive state. Changes take effect immediately. For this reason, it is best practice to call DataRaptors from Integration Procedures (which are versioned) rather than directly from OmniScripts, so that changes can be tested in a new IP version before going live.

### When NOT to Use DataRaptor

- External API callouts → use HTTP Action inside an Integration Procedure.
- Complex business logic requiring Apex collections, triggers, or bulkification → use Apex (callable via Remote Action in IP).
- Anything requiring asynchronous execution → wrap in Integration Procedure with chainable/queueable setting.

---

## 6. Integration Procedure

### What It Is

Integration Procedure is OmniStudio's **server-side declarative orchestration** engine. It runs entirely on the server (not in the browser) and executes a sequence of configurable actions in a single Salesforce transaction. Think of it as a declarative Apex service class: it can call external REST APIs, execute DataRaptors, invoke Apex, handle errors, loop, branch, and compose responses — all without code.

Every Integration Procedure is **automatically exposed as a custom Apex REST endpoint** once activated. It can be called from OmniScripts, FlexCards, Apex, other Integration Procedures, or any external system via REST.

Only the **active version** of an Integration Procedure is executed by callers. Creating a new version does not affect callers until that version is activated.

### Key Action Types

| Action | Description |
|---|---|
| **HTTP Action** | External REST callout. Configure URL (or Named Credential), method, headers, body, timeout. Supports send/response path trimming, retry count, certificate, XML escaping. |
| **DataRaptor Extract Action** | Executes a DataRaptor Extract or Turbo Extract. Pass input via filter values; output lands in a node named after the action. |
| **DataRaptor Post Action** | Executes a DataRaptor Load (DML). |
| **DataRaptor Transform Action** | Executes a DataRaptor Transform. |
| **Remote Action** | Invokes a static Apex method. Specify class name and method. |
| **Set Values** | Defines static variables or formula-computed values in the JSON DOM. Avoid overusing — each instance heaps memory. |
| **Response Action** | Terminates the IP and returns output to the caller. Use **Send JSON Path** to return only a named node rather than the entire data JSON. Using Response Action early (with a conditional execution formula) provides an early exit pattern. Multiple response actions with different execution conditions allow the IP to exit under different scenarios. **If Send JSON Path is blank, nothing is returned.** |
| **Conditional Action / Block** | If/else branching. Group related actions inside a Conditional Block and put the condition on the block rather than on each individual action — this improves performance. |
| **Loop Block** | Iterates over an array. The Loop List must be an array. Inside the loop, reference the current iteration item as `loopListName:fieldName`. Iteration count equals array length. |
| **List Action** | Merges two arrays by matching on a common key field. Supports Basic Merge (match by identical node name) and Advanced Merge (match by different node names or nodes at different levels). |
| **Try/Catch Block** | Error handling container. Place actions inside Try; define error response inside Catch. Requires: `Fail on Step Error` on inner actions, `Fail on Block Error` on the Try block, and `Roll Back on Error` on the IP itself for full transactional rollback. |
| **Matrix Action** | Decision matrix lookup. |
| **Cache Block** | Caches the output of enclosed actions. |
| **Integration Procedure Action** | Calls a child Integration Procedure (nesting). |
| **Calculation Procedure** | Calls an OmniStudio Calculation Procedure for pricing/rating logic. |
| **Email Action** | Sends an email. |
| **DocuSign Envelope Action** | Triggers DocuSign signature flow. |
| **Delete Action** | Deletes a Salesforce record. |
| **Batch Action** | Executes in bulk job context. Be cautious: batch + HTTP actions count against API limits. |

### Input/Output Keys

Every action's output is stored as a node in the IP's data JSON, keyed by the action's **Element Name**. Subsequent actions reference earlier actions' output as `elementName:fieldPath`. The Response Action specifies which node(s) to return to the caller.

Use **Send Only Additional Input** + **Additional Input** on individual actions to pass only the data that specific action needs, preventing the entire accumulated data JSON from being forwarded.

### Chaining and Long-Running Transactions

Salesforce governor limits apply to synchronous transactions. Options for long-running IPs:

| Setting | Behavior |
|---|---|
| Default (synchronous) | Runs in the caller's transaction; subject to standard sync Apex limits |
| `chainable: true` | Separates into chained Apex transactions automatically when approaching limits; use when a DataRaptor Post Action follows an HTTP Action (DML-before-callout restriction) |
| `queueable` | Asynchronous Apex queue; caller does not wait for response |
| `queueableChainable` | Asynchronous with chaining; highest governor limits |

From an OmniScript, set **Invoke Mode** on the IP action:
- **Default** — synchronous; caller waits
- **Fire and Forget** — asynchronous; caller does not wait and does not receive a response (use when result is not needed in the UI)
- **Non-blocking** — fires immediately but does not block user interaction; response is captured when available

### Error Handling and Rollback Pattern

To guarantee full transactional rollback on error across multiple DML steps:
1. On each DataRaptor Load action: enable **Roll Back on Error**.
2. On each action inside a Try block: enable **Fail on Step Error**.
3. On the Try/Catch block: enable **Fail on Block Error**.
4. On the Integration Procedure itself: enable **Roll Back on Error**.

Without all four settings, partial commits may occur.

### Caching Integration Procedures

Configure in the IP settings: definition cache (caches the IP metadata so it is not re-fetched on every call) and response cache (caches the IP's output). Requires platform cache partitions to be allocated. Set `resetCache: true` in the options map during development to bypass cache.

**Important**: by default, Velocity metadata and Velocity API Response partition cache have **zero space allocation**. Cache operations are silently skipped unless partitions are allocated.

### Performance Best Practices

- Do not create one-IP-per-action. Bundle related server-side operations into a single IP to minimize client-server round trips.
- Trim input and output at every step: send only what the next step needs, return only what the caller needs.
- Keep synchronous IP execution under 5 seconds to avoid governor limit violations.
- Use Conditional Blocks instead of per-action execution conditions — the block condition is evaluated once, not per action.
- Use named credentials for external callouts rather than hardcoding credentials.
- Disable pricing in CPQ API calls (pass `priceAndValidate: false`) when pricing is not needed; CPQ pricing runs by default and is expensive.

### IP vs. Apex Decision Guide

| Use Integration Procedure | Use Apex |
|---|---|
| Orchestrating multiple DataRaptors and HTTP actions | Complex bulkification, trigger context, batch jobs with millions of records |
| Declarative conditional branching and error handling | Algorithms too complex for formula-based logic |
| Calling existing Apex methods via Remote Action | Custom SOSL, dynamic SOQL with complex binding |
| Versioned iterative development with business user visibility | Performance-critical inner loops |
| Exposing a server endpoint without writing REST API code | Integration with non-REST protocols (SOAP complex scenarios) |

---

## 7. IDX Workbench and Industry DX CLI

### What It Is

IDX Workbench (desktop application) and VBT/Industry DX CLI (command-line tool, formerly called Velocity Build Tool) are OmniStudio's deployment tools. They handle the migration of OmniStudio **DataPack** metadata — the JSON-based representation of OmniStudio components.

For orgs that have enabled OmniStudio metadata API support, SFDX CLI can also retrieve and deploy OmniStudio components as standard metadata (XML format). VBT 1.15+ supports both standard-object OmniStudio orgs and managed-package Velocity orgs.

### DataPack Concept

A DataPack is a JSON file (or folder of JSON files) representing one OmniStudio component and all its dependencies. Each DataPack folder contains a `datapack.json` parent file that VBT uses to parse and deploy child JSON files. DataPack types map to the Vlocity custom objects:

| DataPack Type | Object (Vlocity managed package) | Metadata Type (standard) |
|---|---|---|
| OmniScript | `%vlocity_cmt%__OmniScript__c` | `OmniScript` |
| FlexCard | `%vlocity_cmt%__OmniUiCard__c` | `OmniUiCard` |
| DataRaptor | `%vlocity_cmt%__DRBundle__c` | `OmniDataTransform` |
| IntegrationProcedure | `%vlocity_cmt%__IntegrationProcedure__c` | `OmniIntegrationProcedure` |

### IDX Workbench — Key Operations

- **Project**: group related DataPack components (and Salesforce metadata) into a named collection. Supports both DataPack types and standard metadata types in the same project.
- **Fetch Data Packs**: retrieves all components of a selected DataPack type from the org; displays them for selection.
- **Migrate**: moves selected components from source (org or repo) to target (org or repo).
- **Comparison tab**: shows a visual diff (green = new, amber = modified, no color = unchanged) between source and target. You can discard individual changes or edit the source JSON before migrating.
- **Git integration**: create/switch branches, commit, pull, push — all within the IDX UI.
- **Ignore Dependencies** checkbox: when checked, only the explicitly selected components are fetched without following dependency chains. Use for targeted hotfixes. Leave unchecked when deploying a full feature to ensure all dependencies are included.

### VBT CLI Key Commands

```bash
npm install -g velocity          # install latest VBT
npm install -g velocity@238.0    # install specific version
velocity help                    # list available commands
```

**Job file** (YAML/JSON configuration for automation):
- `projectPath` — local folder where DataPacks are stored
- `gitCheck: true` — enables delta deployment (diffs against last deployed commit ID stored in org's custom settings)
- `autoRetryErrors: true` — automatically retries failed deployments (e.g., deploys child records before parents on second pass)
- `maxDepth: 0` — do not fetch dependencies; `-1` (default) fetches all

**Delta deployment**: VBT stores the last deployed commit hash in the org. On subsequent deployments, `git diff <lastCommit>..HEAD` generates only the changed components. The commit hash is stored in Custom Settings (General Settings) for managed-package orgs, or in OmniStudio Settings for standard-object orgs.

### Local LWC Compilation (VBT 1.15+)

VBT 1.15+ supports **local compilation** of OmniScript and FlexCard LWC components before deployment, using an npm auth key (obtained via Salesforce Support case). Configure in the job file:
```json
{
  "npmAuthKey": "<your-key>",
  "compilerVersion": "238.0"   // optional; VBT auto-detects from org if omitted
}
```
Local compilation significantly reduces activation time because all LWC components are compiled and deployed in a single batch rather than activated one by one.

### Standard Runtime — No LWC Generation Required

When both **OmniStudio Metadata** and **Standard Runtime** are enabled in the org, FlexCards and OmniScripts no longer generate custom LWC components. They run natively against the platform engine. Deployment reduces to seconds. This eliminates the LWC compilation step entirely and removes the 131,072-character file size limit.

### DataPack Import Requires Activation

DataPacks imported via VBT or IDX are **not automatically activated**. After import, each OmniScript and FlexCard must be activated (manually or via pipeline automation) to compile the LWC and make it available.

### CI/CD Integration Pattern

Recommended pipeline:
1. Developer retrieves components from org via IDX or VBT into a feature branch.
2. Pull request triggers CI: validate-only deploy to a scratch/SI org.
3. PR approval merges to develop branch; CD deploys to SIT.
4. Release branch cut; deployed to UAT (manual gate), then production.
5. Post-production: back-merge hotfixes to develop and release branches.

---

## 8. OmniOut

### What It Is

OmniOut is the capability to deploy OmniScripts and FlexCards **outside the Salesforce platform** — to any web server, CMS (e.g., Adobe Experience Manager), or mobile app (React Native, Angular, custom). It leverages **Lightning Web Components Open Source (LWC OSS)**, the open-source variant of LWC that can run in any browser context without Salesforce.

OmniOut is **generally available** (GA since Fall 2020). Lightning Out, by contrast, was in beta since Spring 2016 and does not have native OmniScript/FlexCard support.

### How It Works

1. OmniScript and FlexCard definitions are mastered in Salesforce.
2. Activate the component. In the activation confirmation, choose **Download Off-Platform Lightning Web Component** — this generates a ZIP with the LWC files pre-configured for OmniOut imports.
3. Add the downloaded LWC files to the **starter project** (a Node.js/webpack application provided by Salesforce as a static resource: `velocity_omniout_lwc`).
4. In `index.js`, import the OmniScript module and define its custom tag name (e.g., `velocity-omniscript-myflow`).
5. In `index.html`, embed the tag and set up the connection:

```javascript
// Mandatory: initialize connection after component is ready
element.addEventListener('omniout-component-ready', (event) => {
  event.target.setConnectionConfig({
    accessToken: '<access_token>',
    instanceUrl: 'https://yourorg.salesforce.com',
    namespace: 'omnistudio'   // or 'vlocity_cmt', 'vlocity_ins', etc.
  });
});
```

6. Optionally set `run-mode="localScriptDefinition"` attribute to skip the org check on load (recommended for performance; the component reads its definition from the local JS file).
7. Build (`npm run build`) and deploy to Heroku, any web server, or a CDN.

### Connection and Proxy

All backend calls (Integration Procedures, DataRaptors, Apex) are executed as REST API calls to Salesforce. A **proxy** is strongly recommended for production:
- Routes all calls through a server-side proxy (no token exposure in the browser).
- Allows IP allowlisting.
- Allows defining an approved API allowlist (do not open the proxy to all Salesforce endpoints).

Pass the proxy URL as the third parameter to `setConnectionConfig`.

### Authentication Patterns

- **Guest user** — for fully unauthenticated public-facing journeys.
- **Integration user** — for unauthenticated journeys requiring org data access.
- **Experience Cloud user** (Customer/Partner) — for authenticated customer self-service; obtain OAuth token and pass to connection config.

### Key Attributes on the OmniScript Tag

| Attribute | Purpose |
|---|---|
| `run-mode` | `localScriptDefinition` skips org activation check; omit to verify against org |
| `layout` | `newport` for Newport Design System; default is SLDS |
| `record-id` | Equivalent to ContextId inside the OmniScript |
| `seed-json` | Pass a JSON object to pre-populate the OmniScript's JSON DOM |
| `connection` | Directly set the connection config object (alternative to event listener) |

### FlexCard-specific OmniOut Setup

For FlexCards used in OmniOut, call `initializeDataSourceSDK` before rendering to set up the Salesforce connectivity (different from OmniScript). Also: when FlexCards are embedded in a web app with the Synthetic Shadow DOM polyfill, CSS leaks across the entire page — use the scoped version of Newport/SLDS to prevent bleed.

### Good vs. Poor Use Cases

**Use OmniOut when:**
- A third-party mobile app or web server (not Experience Cloud) needs the same guided flow as internal agents.
- The on-platform and off-platform process are the same (or mostly the same). Reusability is the core value proposition.
- The team can manage the OmniOut deployment in the channel's CI/CD pipeline.

**Do not use OmniOut when:**
- The channel is Experience Cloud (embed OmniScript directly — OmniOut adds no value).
- The channel is Salesforce Mobile or Mobile Publisher.
- The on-platform and off-platform flows are significantly different (95%+ different means no reuse benefit).
- The channel team wants complete independence from Salesforce development cadence.

### Limitations

- Only LWC-mode OmniScripts supported. AngularJS-based Velocity Cards and old OmniScripts are not supported.
- Second-level and deeper LWC dependencies must be explicitly mapped in the OmniScript configuration — they are not auto-detected.
- `lightning-input` and `lightning-combobox` are not included in the OmniOut package (not yet open-sourced). Use OmniStudio base component equivalents.
- Static resources must be served locally on the web server or from a CDN — direct Salesforce static resource URLs do not work off-platform.
- The "Save for Later" feature works off-platform but the resume URL is org-specific; do not reuse URLs across orgs.
- OmniScript definition is always locally available in the compiled JS file; the definition cannot be downloaded at runtime.

---

## 9. Best Practices

The following practices are drawn from EP-11 (Best Practices) and EP-12 (Development Tools, Tips and Tricks).

### DataRaptor Best Practices

1. **Use targeted DataRaptors** — extract only the fields required for the specific operation. Do not build "uber" DataRaptors that pull every field from every related object.
2. **Limit objects to three per DataRaptor** wherever possible. More objects degrade query performance.
3. **Use relationship queries** before adding a second extract object. `Opportunity.Account.BillingCountry` is one query; adding an Account extract step is two queries. Relationship queries apply both to the filter criteria and to the output path.
4. **Use Turbo Extract for simple single-object reads** — faster engine, simpler configuration. Use standard Extract only when formulas or complex output mapping are required.
5. **Minimize formulas** — formulas execute serially. Remove any formula not needed in the current context. Prefer out-of-box functions over custom formulas.
6. **Allocate platform cache partitions** — set metadata cache and response cache allocations in Setup before going live. Cache-based DataRaptors can be orders of magnitude faster for frequently accessed, infrequently changed data.
7. **Ensure filters and sort fields are indexed** — use `Id`, `Name`, or other indexed fields in WHERE clauses. Avoid `NOT IN`, `NOT LIKE`, and full table scans.
8. **Check Field Level Security** for Extract DataRaptors that serve multiple user profiles — the field is unchecked by default.
9. **Server processing under 5 seconds** — for synchronous transactions; any longer risks governor limit violations.

### Integration Procedure Best Practices

10. **Bundle related server-side calls** into one IP rather than calling separate IPs from the OmniScript for each action. Reduces client-server round trips.
11. **Trim input at every step** — enable Send Only Additional Input, or use Send JSON Path to pass only the node the next action needs.
12. **Trim output with Response Action** — return only the JSON node(s) the caller needs. Never leave the Response Action's Send JSON Path blank if you intend to return data.
13. **Use Conditional Blocks** to group actions sharing the same condition — one condition evaluation instead of N.
14. **Use Chain on Step** only when necessary (DML-after-callout scenario, or when a specific step risks hitting governor limits). Do not enable it globally.
15. **Use caching** for frequently accessed, infrequently updated data (e.g., product catalog, reference data lookups).
16. **Use named credentials** for all HTTP callouts.
17. **Disable CPQ pricing** (`priceAndValidate: false`) when the IP step is not performing a price calculation.
18. **Use response actions with conditional execution formulas** to exit the IP early under specific conditions rather than executing all steps regardless of outcome.
19. **Define a naming convention for Type and SubType** — e.g., `Account / GetDetails`, `Quote / Create`. Consistent naming makes callers predictable and the IP library navigable.
20. **Naming convention for element names inside IP** — prefix by action type: `DRA_` (DataRaptor Action), `DTA_` (Turbo Extract), `RA_` (Remote Action), `SV_` (Set Values). Readable in debug logs and execution sequence.

### OmniScript Best Practices

21. **Break guided flows into clear, focused steps** — one logical concept per step; never overcrowd a step with many fields. Users approaching from a beginner perspective should find each step obvious.
22. **Run business logic server-side** — put DataRaptor/IP orchestration on the server; avoid client-side conditional formula chains for complex decisions.
23. **Use Set Values to pre-populate test data** during development — prevents manual re-entry on every preview test run.
24. **Nest reusable processes as child OmniScripts** — common flows (e.g., collect credit card, create account/contact) should be standalone reusable OmniScripts rather than duplicated steps.
25. **Use Action Blocks for parallel server calls** — group three DataRaptor/IP calls in an Action Block to fire them simultaneously and wait for all results before advancing.
26. **Invoke IP asynchronously** (`Fire and Forget` or `Non-blocking`) when the result is not needed to advance the UI — avoids making the user wait.
27. **Remove spaces from all UI element names** — JavaScript errors can result from spaces in element names.
28. **Use the Action Debugger first for troubleshooting** — confirm request params and response before modifying code. Copy the response JSON from the debugger to build DataRaptor mappings.

### FlexCard Best Practices

29. **Use small, modular cards** — create parent cards with minimal logic; delegate detail rendering to child cards. Prevents the 131,072-character LWC file size limit from being hit (when standard runtime is not enabled).
30. **Minimize custom LWC embeds** — each custom LWC increases the generated HTML size. Prefer OmniStudio base components before building custom ones.
31. **Make event listener names unique** — concatenate the record ID into the event name (e.g., `apexHours_${recordId}`) so that the same FlexCard on multiple records does not cross-fire events across rows.
32. **Always add a blank card state** — handle the no-data scenario explicitly. Without it, a data source failure results in a blank card with no user-facing explanation.
33. **Do not modify auto-generated `c-cf-*` LWC files** — they are regenerated on every activation, overwriting manual changes.
34. **Avoid heavy data sources in list (repeat-enabled) cards** — Integration Procedure data sources are the right choice when mixing Salesforce data with external API data; avoid DataRaptor Extract with many objects in a list card.

### Version Management and Activation Workflow

35. **Test in Preview before activating** — activation is irreversible for that version. Verify all actions in the debugger before clicking Activate.
36. **DataRaptors have no versions** — changes are immediate and irreversible. Call DataRaptors from versioned Integration Procedures to provide a rollback path.
37. **OmniScript version lock after activation** — once active, create a new version to make changes. The active version continues to serve callers until replaced.
38. **DataPack imports require activation** — components imported via VBT or IDX are inactive by default. Activation must be part of the deployment pipeline.

---

## 10. Architecture: OmniStudio vs. Pure Apex/LWC

| Scenario | OmniStudio | Custom Apex / LWC |
|---|---|---|
| Multi-step guided interaction for agents or customers | OmniScript | Screen Flow or custom LWC wizard |
| Data display card with contextual actions on record page | FlexCard | Custom LWC component |
| Read Salesforce data for display (single object, no formula) | DataRaptor Turbo Extract | SOQL in Apex or LDS wire adapter |
| Read Salesforce data with multi-object joins and formulas | DataRaptor Extract | Apex query + transformation |
| Write/upsert Salesforce records (declarative) | DataRaptor Load | Apex DML |
| Orchestrate multiple API calls + Salesforce DML in one transaction | Integration Procedure | Apex service class |
| External REST callout with conditional branching | HTTP Action in Integration Procedure | Apex HttpRequest + conditional logic |
| Looping over a list server-side | Loop Block in Integration Procedure | Apex for-loop |
| Error handling with transactional rollback | Try/Catch Block + Roll Back on Error in IP | Apex Savepoint / Database.rollback |
| Off-platform deployment (external site or mobile app) | OmniOut | Lightning Out (beta) or full custom rebuild |
| CI/CD deployment of declarative components | VBT / IDX CLI / SFDX (standard objects) | SFDX CLI for standard metadata |
| Complex bulkification, trigger-context operations | Not suitable — use Apex | Apex trigger / batch |
| Long-running batch over millions of records | Batch Action in IP (caution: API limits) | Apex Batch |
| Persistent message queuing, polling external system | Not suitable | MuleSoft or Apex async |
| Rapid prototyping of a business process (show customer in days) | OmniStudio end-to-end | Custom Apex/LWC — weeks |

---

## 11. Gotchas and Known Issues

### G-1: Activation Required Before Testing in Live Contexts
**Source:** EP-4, EP-9 transcripts  
**Impact:** High  
OmniScripts and FlexCards must be activated before they can be tested on a live Lightning record page or in an Experience Cloud site. Activation compiles the LWC. Without activation, the component does not exist as a deployable LWC. In the OmniScript/FlexCard designer, Preview mode works without activation. Everything else requires an active version.

### G-2: DataRaptors Have No Version Control
**Source:** EP-12 transcript  
**Impact:** High  
DataRaptor changes take effect immediately — there is no draft/active distinction and no rollback. A mistake in a DataRaptor mapping used in production is live the moment you save. Mitigation: always wrap DataRaptors inside an Integration Procedure (which is versioned) so IP versioning provides a rollback path. Never modify DataRaptors directly in production.

### G-3: JSON Path Notation Errors (Element Name Must Match JSON Node)
**Source:** EP-4, EP-12 transcripts  
**Impact:** High  
The name of an OmniScript input element must exactly match the JSON field name that the data source (DataRaptor/IP) returns. If the DataRaptor Extract outputs `phone` but the OmniScript input element is named `Phone`, the value will not populate. This is called **parsing** — the JSON DOM key-matching is case-sensitive and character-sensitive. Validate by checking the Data JSON in Preview after the get-data action fires.

### G-4: DataRaptor List vs. Single Record Handling
**Source:** EP-2, EP-6 transcripts  
**Impact:** Medium  
DataRaptor Extract returns a JSON array by default when multiple records are found. A DataRaptor that returns one record vs. zero vs. many records produces structurally different JSON. In FlexCards, enable the **Repeat Records** toggle for list rendering, and disable it when passing the entire payload to a data table component (the table needs the full array, not individual rows rendered three times). In OmniScripts, the data JSON stores the array under the extract action's element name node.

### G-5: Platform Cache Partitions Default to Zero Allocation
**Source:** EP-7, EP-11 transcripts  
**Impact:** High  
The Velocity Metadata cache and Velocity API Response cache partitions have zero space allocated by default after package installation. All caching calls silently succeed (no error) but do nothing until partitions are allocated in Setup > Platform Cache. Symptom: repeated SOQL queries despite cache settings being configured. Fix: allocate at least 1–2 MB to each partition under Setup > Platform Cache.

### G-6: OmniScript Version Lock After Activation
**Source:** EP-4 transcript  
**Impact:** Medium  
Once an OmniScript version is activated, its definition is compiled and locked. You cannot edit the active version. To make changes, create a new version, modify it, test it in Preview, then activate the new version (which deactivates the previous one automatically). Callers always use the active version. Plan for brief downtime between deactivation of old and activation of new if the OmniScript is used in production.

### G-7: DataPack Import Does Not Activate
**Source:** EP-9 transcript  
**Impact:** High  
Components imported via VBT or IDX Workbench arrive in the org in an inactive state. They will not render on Lightning pages or function in OmniScripts until activated. Activation must be scripted into the CI/CD pipeline using puppeteer or the activation API. Forgetting activation is a common post-deployment gap.

### G-8: Send JSON Path Behavior Differs Between OmniScript Actions and IP Actions
**Source:** EP-12 transcript  
**Impact:** Medium  
When using Send JSON Path on an action element inside an **OmniScript**, the filtered node is included in the outgoing payload but the original path remains intact in the OmniScript JSON DOM. When using Send JSON Path on a step inside an **Integration Procedure**, the path is eliminated from the data context — only the flat fields under that node are passed forward, and the parent path is stripped. This asymmetry causes unexpected results if you assume identical behavior. Test explicitly in the action debugger.

### G-9: FlexCard LWC Size Limit (131,072 Characters)
**Source:** EP-3, EP-11 transcripts  
**Impact:** High (when standard runtime is not enabled)  
Each auto-generated FlexCard LWC file cannot exceed 131,072 characters. A large, complex FlexCard with many custom LWC embeds can exceed this limit and fail activation silently or with a cryptic error. Mitigation: decompose large cards into a parent card and multiple child cards. Each child card generates its own LWC. This limit does not apply when OmniStudio Standard Runtime is enabled.

### G-10: Make Event Listener Names Unique (PubSub Cross-Tab Firing)
**Source:** EP-3, EP-11 transcripts  
**Impact:** Medium  
PubSub events in FlexCards fire across all open console tabs in a Service Console. If a FlexCard is open on three account tabs and all three share the same event name (e.g., `apexHours`), a user action on one card fires the event handler on all three cards simultaneously. Fix: concatenate the record ID into the event name at configuration time (e.g., `apexHours_${recordId}`), making each card's event name unique.

### G-11: OmniStudio Metadata Setting Cannot Be Reversed
**Source:** EP-9 transcript  
**Impact:** High  
Enabling "OmniStudio Metadata API Support" in Setup moves component storage from Vlocity custom objects to standard platform objects. **This toggle cannot be disabled once enabled.** Additionally, after enabling this setting, component names cannot contain spaces or special characters — a naming convention restriction that does not apply in managed-package mode. Plan naming conventions before enabling this setting in any org.

### G-12: Response Action Send JSON Path Required to Return Data
**Source:** EP-11, EP-12 transcripts  
**Impact:** High  
A Response Action with a blank Send JSON Path returns **nothing** to the caller. This is a common cause of OmniScripts receiving empty responses from Integration Procedures. Always set the Send JSON Path to the node name (or leave it pointing to the full data JSON if all data must be returned). Validate by running the IP in Preview and checking the response panel.

### G-13: IDX Alpha Version Required for OmniStudio DataPack Support
**Source:** EP-9 transcript  
**Impact:** Medium  
The IDX Workbench GA (generally available) release does not support OmniStudio components as DataPacks. Only the **alpha version** of IDX Workbench supports OmniStudio DataPack migration. VBT 1.15+ supports OmniStudio migration via CLI. Migrating OmniStudio components stored in standard objects (when metadata API is enabled) back into managed-package custom objects is not supported — migration is one-directional (custom → standard only).

### G-14: Custom LWC Second-Level Dependencies Not Auto-Detected in OmniOut
**Source:** EP-10 transcript  
**Impact:** Medium  
When downloading the off-platform LWC package, only first-level custom LWC dependencies of the OmniScript are included automatically. If a custom component embeds another custom component (second-level dependency), or if a custom component used by a FlexCard within the OmniScript has its own dependencies, those are not auto-detected. They must be manually added to the OmniOut project's `modules` folder and registered in the module resolution config. Failure to do so produces a silent rendering failure off-platform.
