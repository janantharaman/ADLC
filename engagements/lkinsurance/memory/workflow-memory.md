# Workflow Memory — LKInsurance — Knowledge Base Grounding + Pre-Design — 2026-05-11

## Current Engagement State

**Engagement:** LKInsurance (Korean insurance brokerage)
**Org Alias:** LKInsuranceDev
**Current Phase:** Awaiting Discovery APPROVAL → then Design (Phase 2)
**Discovery Artifact:** `engagements/lkinsurance/discovery.md` — Status: **DRAFT** (NOT yet APPROVED)
**Next Gate:** User must respond APPROVED to discovery.md before Design phase can begin
**Blocking Conditions:**
- Discovery.md must be approved by the human stakeholder
- Requirements workshop with customer must occur before Design begins (per Open Questions in discovery.md)
- Design phase cannot start if discovery.md remains in DRAFT or is not present

**What happened this session:** No phase was run. This session was entirely focused on grounding the ADLC knowledge base with Experience Cloud, OmniStudio, FSC supplements, and Health Cloud. No new engagement artifacts were produced. Workflow memory was empty (correctly cleared after Discovery DRAFT was written on 2026-04-29).

---

## Engagement Artifacts (LKInsurance)

| File | Status | Description |
|---|---|---|
| `engagements/lkinsurance/discovery.md` | **DRAFT** | Full org health baseline — 518 lines |
| `engagements/lkinsurance/memory/core-memory.md` | Current | Permanent org facts — last updated 2026-04-29 |
| `engagements/lkinsurance/memory/daily-memory.md` | Current | One entry: 2026-04-29, Discovery complete (DRAFT) |
| `engagements/lkinsurance/docs/index.md` | Empty | Document index header only — no documents registered yet |
| `engagements/lkinsurance/evaluation/` | Not yet created | Will be created at first phase gate evaluation |
| `engagements/lkinsurance/design.md` | **NOT STARTED** | Blocked pending Discovery approval |
| `engagements/lkinsurance/impl-summary.md` | **NOT STARTED** | Blocked pending Design approval |
| `engagements/lkinsurance/testing.md` | **NOT STARTED** | Blocked pending Implementation approval |
| `engagements/lkinsurance/deployment.md` | **NOT STARTED** | Blocked pending Testing approval |

---

## Discovery.md — Key Findings Summary

**Org Profile:**
- 45+ custom objects; key: Policy__c, Claim__c, Customer__c, Agent__c, Product__c, LatestContractNumMgmt__c
- 175 Apex classes, 12 triggers, 80 LWC components, 269 flows, 4 Agentforce agents
- 37 out of 74 users on System Administrator profile — high privilege concentration (SECURITY RISK)
- LatestContractNumMgmt__c OWD = ReadWrite — potential unintended data exposure (SECURITY RISK)
- 10 unmanaged packages installed — no version tracking strategy in place

**Critical Security Findings from Discovery:**
1. 37/74 users on SysAdmin — over-privileged; remediation required before go-live
2. LatestContractNumMgmt__c has ReadWrite OWD — review access model
3. Guest user profile assignments need audit
4. No documented permission set strategy

**Open Questions (must resolve before Design begins):**
1. What is the target go-live date?
2. Which objects require field-level encryption (PII/PHI)?
3. Integration architecture — which external systems connect to the org?
4. Agentforce agents — are they custom-built or managed package templates?
5. LatestContractNumMgmt__c — what is the business intent of ReadWrite OWD?
6. Flows (269) — are all active? How many are legacy/inactive?
7. LWC (80 components) — are these all for internal UI or also Experience Cloud?
8. Unmanaged packages (10) — which are actively used vs. vestigial?
9. Vendor teams (i2max, trestle) — what is their current scope and active work items?
10. Korean/English bilingual requirements — which objects/fields need localization?

---

## Knowledge Base — Artifact Inventory

All knowledge files are in `knowledge/`. The knowledge base was substantially grounded this session. Use this inventory when starting any phase to understand what reference material is available.

### Grounded Clouds (full — all 8 standard sections present)

| Cloud | Directory | Source | Files | Notes |
|---|---|---|---|---|
| Financial Services Cloud | `knowledge/clouds/financial-services-cloud/` | FSC Dev Guide (1396p, Spring '26) + Enablement PDF + org metadata | 8 files | Key cloud for LKInsurance engagement |
| Experience Cloud | `knowledge/clouds/experience-cloud/` | communities.pdf (818p, Spring '26) | 8 files | Grounded this session — includes metadata-tooling.md |
| Health Cloud | `knowledge/clouds/health-cloud/` | Health Cloud Dev Guide (2300p) | 8 files | Grounded this session — includes FHIR/HL7 patterns |
| Service Cloud | `knowledge/clouds/service-cloud/` | Prior session | 9 files | Includes mobile-sdk.md |
| Sales Cloud | `knowledge/clouds/sales-cloud/` | Prior session | ~8 files | |
| Manufacturing Cloud | `knowledge/clouds/manufacturing-cloud/` | Prior session | ~8 files | |
| Revenue Cloud | `knowledge/clouds/revenue-cloud/` | Prior session | ~8 files | |
| Automotive Cloud | `knowledge/clouds/automotive-cloud/` | Prior session | ~8 files | |
| Telco Cloud | `knowledge/clouds/telco-cloud/` | Prior session | ~8 files | |

### All Clouds Now Fully Grounded (as of 2026-05-11)

No stub clouds remain.

| Cloud | Directory | Source | Files | Notes |
|---|---|---|---|---|
| Life Sciences Cloud | `knowledge/clouds/life-sciences-cloud/` | LSC Dev Guide (1869p, Spring '26 / v66.0) | 8 files | Grounded 2026-05-11 |
| Consumer Goods Cloud | `knowledge/clouds/consumer-goods-cloud/` | retail_api.pdf (1840p, Spring '26) | 8 files | Grounded 2026-05-11 — cgcloud + cgc_sync namespaces, RE + TPM |

### Cross-Cloud / Generic Knowledge

| File | Source | Notes |
|---|---|---|
| `knowledge/omnistudio.md` | 17 YouTube VTT transcripts (Apex Hours playlist) | Grounded this session — 720 lines; OmniScript, FlexCard, DataRaptor, Integration Procedure, IDX Workbench |
| `knowledge/naming-conventions.md` | Prior session | Always load at phase start per CLAUDE.md |
| `knowledge/security-baseline.md` | Prior session | Load for Discovery, Design, Implementation, Deployment |
| `knowledge/governor-limits.md` | Prior session | Load for Implementation and Testing |
| `knowledge/agentforce/` (8 files) | developer.salesforce.com/docs/ai/agentforce/ (17 HTML pages, Spring '26) | Grounded 2026-05-11 — Champion/Innovator/Legend scope; Agent API, Models API, DX, Testing API, Agent Script, Citations, Mobile SDK, Python SDK, BYOLLM |

### Knowledge Base — Standard File Structure (per cloud)

Each grounded cloud has these 8 files:
1. `overview.md` — what it is, when to use it, license types, feature domains
2. `data-model.md` — objects, fields, relationships, SOQL patterns, load order
3. `security-model.md` — OWD defaults, sharing, permission sets, platform security
4. `automation-patterns.md` — Flows, Apex, invocable actions, platform events
5. `gotchas.md` — known issues, deployment traps, undocumented behaviors
6. `api-reference.md` — SOQL patterns, REST/SOAP endpoints, Apex signatures
7. `implementation-guide.md` — step-by-step setup, prerequisites, activation sequences
8. `metadata-tooling.md` — metadata types, package.xml patterns, CI/CD considerations

---

## Key Org Facts (from core-memory.md)

- **Org Alias:** LKInsuranceDev
- **Trigger Pattern:** 1 trigger per object → handler class (triggerHandler pattern); all triggers follow this
- **Naming Conventions:** Custom objects use `LK_` prefix; LWC components use camelCase
- **Known Tool Failures:**
  - `OrgLimit` object is NOT queryable via SOQL — use Setup UI instead
  - Retrieving all 642 objects at once causes timeout; retrieve in batches of ~50
  - `mcp__salesforce__retrieve_metadata` with wildcard `*` on large metadata types times out
- **Customer Preferences:**
  - Bilingual org: Korean (primary) and English; field labels often in Korean
  - Two vendor teams: **i2max** (primary build partner) and **trestle** (integration/middleware)
  - Prefers declarative-first solutions; Apex only when Flow/OmniScript cannot handle it

---

## Session Log — 2026-05-11

- [2026-05-11] Session resumed from prior conversation (context compacted)
- [2026-05-11] Task: Ground Experience Cloud from communities.pdf (818p) — COMPLETED
  - Wrote 8 files to `knowledge/clouds/experience-cloud/`; added metadata-tooling.md as new file
  - Updated knowledge-map.html: Experience Cloud card changed from stub to full
- [2026-05-11] Task: Attempted help.salesforce.com URLs for EC license types — FAILED (JS-rendered, no content accessible)
- [2026-05-11] Task: Attempted salesforce.quip.com URL — FAILED (SAML redirect to Okta SSO wall)
- [2026-05-11] Task: Attempted FSC Enablement Guide PDF (`Financial Service Cloud Enablement Guide v 1.0 -Shared.pdf`) — PDF was 5-page training curriculum only, no grounding content; no knowledge files updated
- [2026-05-11] Task: Ground OmniStudio from YouTube playlist (Apex Hours series, 17 videos) — COMPLETED
  - Extracted VTT transcripts via yt-dlp; deduplicated rolling captions
  - Wrote `knowledge/omnistudio.md` (720 lines)
  - Updated knowledge-map.html: omnistudio.md added to Generic Knowledge panel
- [2026-05-11] Task: Attempted Trailhead FSC Basics module — FAILED (JS-rendered SPA, no content accessible)
- [2026-05-11] Task: Attempted Salesforce demo URL — FAILED (post-form thank-you page, no product content)
- [2026-05-11] Task: Attempted Partner Learning Camp URL — FAILED (partner SSO wall)
- [2026-05-11] Task: Assessed FSC knowledge base completeness — identified gaps in security-model.md, automation-patterns.md, overview.md; used fsc_dev_guide.pdf to fill them
- [2026-05-11] Task: Supplement FSC knowledge base from fsc_dev_guide.pdf (1396p, Spring '26) — COMPLETED
  - Updated all 8 FSC files; major additions: FinancialDeal family (6 objects), BranchUnit, Referral (API v66), Compliant Data Sharing, Integration Plan, IndustriesSettings 35-feature activation sequence, 12 metadata types with XML samples
  - Updated knowledge-map.html: FSC card source updated
- [2026-05-11] Task: Ground Health Cloud from health_cloud_dev_guide.pdf (2300p) — COMPLETED
  - Wrote 8 files to `knowledge/clouds/health-cloud/`; 3 new files (api-reference.md, implementation-guide.md, metadata-tooling.md)
  - Key: 34 feature domains, FHIR R4/HL7, OmniStudio required for Assessments, FSL for Home Health, 16 invocable actions, 13 metadata types, 2 platform events
  - Updated knowledge-map.html: Health Cloud card changed from stub to full
- [2026-05-11] Task: Update workflow-memory.md with current state + artifact inventory — COMPLETED
- [2026-05-11] Task: Ground Life Sciences Cloud from LSC Dev Guide PDF (1869p, v66.0, Spring '26) — COMPLETED
  - PDF downloaded from Atlas JSON API: https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/life_sciences_dev_guide.pdf
  - Wrote 8 files to knowledge/clouds/life-sciences-cloud/ (replaced 5 stubs + created 3 new files)
  - Key content: 4 engagement domains (Clinical, Customer, Patient, MedTech), 200+ standard objects, FHIR R4 mapping (30+ resources), 2 platform events, Business APIs (merge, search, Book Slot Chain, Contact Encounter), embeddedai Apex namespace, 5 invocable actions, 14 metadata types with XML samples, IndustriesSettings fields
  - Updated knowledge-map.html: LSC card changed from stub to full; stats: 10 Grounded / 1 Stub / 96 Total files
- [2026-05-11] Task: Ground Consumer Goods Cloud from retail_api.pdf (1840p, Spring '26) — COMPLETED
  - PDF source: /Users/janantharaman/Downloads/retail_api.pdf
  - Wrote 8 files to knowledge/clouds/consumer-goods-cloud/ (replaced 5 stubs + created 3 new files: api-reference.md, implementation-guide.md, metadata-tooling.md)
  - Key content: cgcloud namespace architecture, 37 standard RE objects, ~60 cgcloud custom objects (RE), ~50 cgcloud TPM objects, 25+ cgc_sync Sync Management objects, RetailExecutionSettings metadata type (3 fields), RE_Order Apex class + orderExtensionUtils LWC service (14 methods), System.Callable order hook pattern (RE_Order_Save/RE_Order_Proposal_List), TPM Business Object API (promotion ingest, max 50/call), cgcloud.RTRReportResult class, 20 gotchas documented
  - Updated knowledge-map.html: CGC card changed from stub to full; stats: 11 Grounded / 0 Stubs / 104 Total files
- [2026-05-11] Task: Ground Agentforce platform from Agentblazer Champion/Innovator/Legend curriculum scope using developer.salesforce.com/docs/ai/agentforce/ (17 HTML pages, Spring '26) — COMPLETED
  - Created new directory knowledge/agentforce/ (8 new files — separate from clouds/ as Agentforce is a cross-cutting platform capability, not an industry cloud)
  - Scope anchored to Agentblazer badge tiers: Champion (foundation), Innovator (APIs/DX/testing), Legend (Agent Script/Mobile SDK/Python SDK/BYOLLM)
  - Key content documented:
    - April 2026 terminology: "topics" → "subagents" (naming-only; GenAiPlugin metadata unchanged)
    - 5 action types: Apex REST, AuraEnabled, Named Query, Invocable Method, Lightning Types
    - Agent Script: 3 modes (LLM-only/script-only/hybrid); 8 symbols (#, ->, |, {!expr}, @subagent, @utils.escalate, @utils.end, @utils.repeat)
    - Agentforce DX YAML spec: 9 fields (agentType, companyName, role, maxNumOfTopics [default 5], tone [casual/formal/neutral], agentUser, enrichLogs, promptTemplateName, groundingContext)
    - Agent API: 3 REST endpoints (POST start session, POST send message, DELETE end session)
    - Models API: aiplatform.ModelsAPI (createChatGenerations, createGenerations, createEmbeddings, submitFeedback); 6 standard model identifiers + BYOLLM
    - Testing API: AiEvaluationDefinition (v63.0+); Connect API 3 endpoints; metricScore PASS/FAILED/HIGH/LOW/UNCERTAIN
    - Citations Apex: 7 classes (GenAiActionOutput through GenAiCitedReferenceInfo)
    - Mobile SDK: iOS (SwiftUI, iOS 17+, CocoaPods; AgentforceClient, AgentforceConversation) + Android (Jetpack Compose, API 29+)
    - Python SDK: agentforce-sdk; Agentforce, Agent, Topic, Action, Variable (Text/Boolean ONLY), AttributeMapping, AgentUtils, PromptTemplateUtils
    - 7 metadata types with XML samples; GenAiPlannerBundle wildcard prohibition documented
    - 16 gotchas documented
  - Atlas PDF API confirmed to have NO Agentforce PDFs (all slug variants return empty)
  - developer.salesforce.com/docs/ai/agentforce/ HTML pages ARE directly accessible (not JS-rendered)
  - Updated knowledge-map.html: Agentforce files added to Generic Knowledge panel; header stats: 112 Total Files; added purple AI Platform tag style
  - Final stats: 11 Clouds Grounded / 0 Stubs / 112 Total Files (8 Agentforce + 104 cloud/generic files)

---

## Extraction Patterns Established This Session

These workarounds are confirmed reliable for future grounding sessions:

| Source Type | Tool | Pattern | Notes |
|---|---|---|---|
| Salesforce official PDFs | Python pdfplumber | Scan page headers for section locations → targeted page range extraction | Install: `pip3 install pdfplumber -q`; suppress warnings with `sys.stderr = io.StringIO()` |
| YouTube transcripts | yt-dlp | Download VTT subtitles (`--write-auto-sub --sub-lang en --skip-download`) → strip timestamps → deduplicate rolling caption lines | Install: `pip3 install yt-dlp -q`; dedup: `if line != prev: keep` |
| developer.salesforce.com/docs/ai/agentforce/ | WebFetch | HTML pages directly accessible, no JS rendering required | Use /guide/{page-name} path pattern; 17 pages confirmed accessible |
| help.salesforce.com | — | **NOT ACCESSIBLE** — JS-rendered SPA | No workaround; use PDF download instead |
| trailhead.salesforce.com | — | **NOT ACCESSIBLE** — JS-rendered SPA | No workaround; use YouTube or PDF |
| developer.salesforce.com (general) | — | **NOT ACCESSIBLE** — JS-rendered | Agentforce docs are an exception (see above); other dev pages require PDFs |
| salesforce.quip.com | — | **NOT ACCESSIBLE** — SAML redirect | Must have authenticated session |
| partnerlearningcamp.salesforce.com | — | **NOT ACCESSIBLE** — partner SSO wall | Must have partner credentials |

---

## Context for Multi-Resource Collaboration

**If resuming this engagement as a new resource, read in this order:**
1. `CLAUDE.md` — delivery framework rules (non-negotiable)
2. `engagements/lkinsurance/memory/core-memory.md` — permanent org facts
3. `engagements/lkinsurance/discovery.md` — full org baseline (DRAFT, not yet approved)
4. `knowledge/naming-conventions.md` — always required
5. `knowledge/clouds/financial-services-cloud/overview.md` — primary cloud for this engagement
6. `knowledge/omnistudio.md` — OmniStudio is used in FSC; relevant for any automation decisions

**The engagement is currently blocked at the Discovery gate.** Design cannot begin until:
1. The human stakeholder reviews `engagements/lkinsurance/discovery.md`
2. They respond with `APPROVED` (or `REVISE: [feedback]`)
3. If APPROVED: run memory consolidation, then load `skills/design/SKILL.md` and begin Phase 2

**Do NOT begin Design, Implementation, Testing, or Deployment until Discovery is explicitly APPROVED.**
