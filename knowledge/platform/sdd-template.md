---
source: GDC Professional Services — Solution Design Document Template (internal)
type: delivery-reference
applies-to: Design phase artifact, cross-referenced by Testing and Deployment phases
---

# Solution Design Document (SDD) — GDC Standard Template

The SDD is the canonical delivery artifact for the Design phase. It is the basis for all configuration and development. The project team refers to it repeatedly over development and testing. It provides traceability from design back to User Stories/requirements.

An uninformed party reading only the Introduction section should understand the client's situation, the motivation for the project, and the rationale for the selected solution.

---

## Document Structure (all sections)

### 1. Introduction
- **Project Overview > Project Background** — client company background, project motives, scope, Salesforce approach. Derive from SOW and kick-off deck.
- **Project scope** — people (business units), process (business processes), technology (systems replaced/integrated)
- **Assumptions** — only dependencies specific to the proposed solution (not standard SOW assumptions)
- **Statement of Confidentiality and Disclaimer** — standard legal boilerplate (include verbatim)

### 2. Solution Design Overview (Executive Summary)
- High-level solution covering people, process, and technology — describes changes, not just enumerates them
- Required: high-level Solution Context Diagram and Solution Diagram
- Diagram must show: key systems, key user types, key user communities, key data types, key functions

### 3. Current State (As-Is)
- **Business Model > Business cycle** — process diagram if unusual business model
- **Business Model > Customer Data Model** — conceptual ERD + entity description table
- **Current State Business Processes** — L3 process maps (swim-lane, decision boxes) with descriptions covering:
  - Process overview, pain points, observations, root causes, recommendations, metrics
- **Current State System Architecture** — system-by-system: scope, system of record, pain points, platform assessment

### 4. Future State (To-Be)
- Future state solution architecture diagram
- Future state IT landscape diagram (compare to as-is)
- **Design Considerations** — alternatives considered + reason rejected (pros/cons table). Required for every major architectural decision.
- **Decision Log** — table with date, decision, alternatives, RACI for each key decision
- **Future State Business Processes** — to-be process maps + description (key changes, issues to resolve, change management, metrics)
- **Future State System Architecture** — system-by-system

### 5. Solution Design (5 layers)

#### 5a. Administration Layer
- User Administration — provisioning policies, key User record fields, delegated admin
- Delivery Architecture Board — architects/senior leaders ensuring alignment, feasibility, compliance
- Salesforce Environment Management:
  - Environment landscape (Dev, Test, SIT, UAT, Staging, Production)
  - Platform Strategy
  - Platform Security Design
  - Code Source Control (tool, branching/tagging nomenclature, environments strategy)
  - Release Management (tools, deployment processes)
- Collaboration (Chatter settings, groups, feed tracking; Communities — license type, login method, branding)
- Content Management (libraries, types, permissions)
- Communication/Email (templates, letterheads, DKIM, relay, org-wide addresses)
- Organization Settings (name, calendar, fiscal year, locale, currency, timezone, domains)
- System Access (network, SPF, DNS, API connectivity, login hours, IP ranges, password/session policies, SSO, Connected Apps)
- Security Controls (audit trails, certificate management, CORS, named credentials, platform encryption, session management, transaction security)

#### 5b. Data Layer
- **Data Model** — logical ERD (color-coded standard vs custom objects, crow's feet), data lifecycle diagrams per object
- **Data Migration Considerations** — sources, targets, selection criteria, volumes table; link to Data Migration strategy document
- **Data Management:**
  - Data Dictionary — per object: Display Name, API Name, Data Type, Picklist Values, Profiles (Visible/Read-Only), Page Layouts, Comments; optional: FLH, source system mapping, transformation notes
  - Data Ownership and Stewardship — by system, by object, data cleansing routines
  - Large Data Volume — pricing, limitations for big datasets
  - Data Cleaning — error detection, corrective measures, responsible stakeholders

#### 5c. Business Layer
- **Business Objects** — per object: high-level description, Record Types rationale, custom field descriptions, custom code descriptions (with sequence diagrams, processing outlines, code artifact tables where needed)
  - Standard objects to consider: Accounts, Contacts, Campaigns, Leads, Opportunities, Products, Price Books, Quotes, Orders, Assets, Contracts, Cases, Work Orders, Knowledge Articles, Custom Objects
- **Visibility and Sharing Model:**
  - OWD per object
  - Profiles table (based-on standard profile, console settings, page layouts, FLS, tab settings, record types, permissions)
  - Permission Sets overview and table
  - Role Hierarchy diagram
  - Sharing Rules (criteria-based, ownership-based)
  - Territories
  - Public Groups
- **Business Process Automation:**
  - Assignment rules (Lead, Case, Account queues)
  - Approval Processes (per object — account, contract, opportunity, order, etc.)
  - Sales/Support/Lead/Solution Processes
  - Automated Workflows — per automation: evaluation criteria, validation rules, trigger events, actions (email alerts, field updates, flows, outbound messages, tasks)
  - Case Escalation rules

#### 5d. User Interface Layer
- **Experience Architecture** — end-to-end user journey flowchart (Lucidchart/draw.io)
- **Desktop UX** — screen design specs, Salesforce Console, wireframes, Lightning App Builder, LWC/Aura components, Visualforce pages
- **Mobile UX** — Salesforce1 navigation, offline, adoption manager, mobile wireframes
- **Community UX** — Customer Community wireframes, Partner Community wireframes
- **Languages** — default language, picklist/reports translations

#### 5e. Integration Layer
- **Integration Overview** — high-level description of all integration use cases; integration architecture diagram; summary table
- **Integration Design Considerations** — middleware decision, API type (SOAP/REST), custom vs standard web services
- **Integration Data Error & Exception Handling** — QA validation approach, error handling, exception handling
- **Per Integration Use Case** — description, interface activation, sequence diagram, design considerations, processing steps, data mapping, example request/response

#### 5f. Analytics Layer
- Analytics overview (OOTB reports, custom reports, analytic snapshots)
- Per report: KPIs, specifications, tools, mock-up, access/visibility
- Dashboards — source reports, running user, filters, drilldowns, mobile availability

### 6. Appendices
- **Glossary** — client jargon + Salesforce CRM terms, with definitions
- **Related Documents** — links/embeds to: Epics & Features, User Stories, Data Dictionary, Implementation Plan
- **List of Stakeholders** — full name, title, contact; validates thoroughness of requirements gathering
- **Epics & Features** — reference or copy-paste
- **User Stories** — reference or copy-paste
- **User Story Mapping** — prioritization, end-to-end user story map (Lucidchart/draw.io or table)
- **DevOps Toolchain** — stages (Plan, Code, Build, Test, Release, Deploy, Operate, Monitor) × tools and purposes
- **Testing:**
  - Unit testing methodology
  - SIT test cases and results
  - Regression test cases and results
  - UAT test cases, plan, users, logins, instances, pass/fail, bugs, enhancement requests
  - Go Live Readiness: Pre/Go/Post checklists (Responsible, Environment, Task, Owner, Timeline, Status)
- **Customization Details** — inventory of Apex classes, triggers, VF pages, LWCs, Custom Settings, Custom Metadata Types
- **Deployment Runbook** — step-by-step deployment guide for engineers/ops (same Go Live checklist structure)

---

## Mapping to ADLC Phases

| SDD Section | ADLC Phase |
|---|---|
| Introduction, Current State (As-Is), Business Model | Discovery (Phase 1) |
| Future State, Solution Design (all 5 layers) | Design (Phase 2) |
| Customization Details | Implementation (Phase 3) |
| Testing appendix (Unit, SIT, UAT, Regression) | Testing (Phase 4) |
| Deployment Runbook, Go Live Readiness checklists | Deployment (Phase 5) |

The ADLC `design.md` artifact is the machine-readable form of the SDD. When the engagement requires a client-deliverable SDD Word document, use this template structure to convert the `design.md` artifact into the full SDD. The ADLC artifact structure maps 1:1 to the SDD layers — do not duplicate design decisions between the two; the `design.md` is the source of truth.

---

## Key Writing Standards

- Introduction: derive from SOW and kick-off deck. One paragraph is sufficient if it covers client background, motives, scope, and approach.
- Solution Design Overview: describe changes — do not merely enumerate them. Keep it concise.
- Current State: explicitly list stakeholders interviewed (by name and title) to validate thoroughness.
- Design Considerations: every major architectural decision must list alternatives and reasons rejected.
- Data Dictionary: use a separate tab per object; always include Display Name, API Name, Data Type, Picklist Values, Profiles (Visible/Read-Only), Page Layouts, Comments.
- Process maps: use L3 (swim-lane, logical branching) for most implementation work. L4 for screen flow design. L5 for test scripts.
- Avoid: recapitulating SOW assumptions; re-explaining DRIVE® methodology; "intended audience" boilerplate.
