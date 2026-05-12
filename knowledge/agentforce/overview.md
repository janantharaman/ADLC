---
source: developer.salesforce.com/docs/ai/agentforce/ (17 pages, Spring '26); Agentblazer Champion/Innovator/Legend curriculum scope; grounded 2026-05-11
cloud: Agentforce (cross-cutting platform capability)
section: overview
last-updated: 2026-05-11
---

# Agentforce — Overview

## What It Is

Agentforce is the agent-driven layer of the Salesforce Platform. It enables autonomous AI agents that can reason, take actions, and complete multi-step tasks on behalf of users or in automated processes — without requiring a human to orchestrate every step.

Agentforce agents are different from chatbots: they can call tools (actions), make decisions, invoke other agents (subagents), and carry state across a conversation. They run on the Einstein Trust Layer, which provides data masking, toxicity detection, and audit trail for every LLM interaction.

**April 2026 terminology change:** "Topics" were renamed to "Subagents" in the Salesforce UI and documentation. This is a naming-only change — no functional or API changes. Existing metadata using the term `topic` continues to work. The metadata type `GenAiPlugin` continues to represent what are now called subagents in the UI.

---

## Platform Position

Agentforce sits above the Salesforce data and automation platform:

```
User / External System
        ↓
   Agent API (REST) — start session, exchange messages
        ↓
   Agentforce Engine — LLM reasoning + deterministic routing
        ↓
   Actions — Apex, Flow, SOQL, Lightning Types, AuraEnabled
        ↓
   Salesforce Data + Platform
```

Einstein Trust Layer wraps every LLM call:
- Data masking before leaving Salesforce
- Zero data retention with LLM providers
- Toxicity/bias detection
- Audit log for compliance

---

## Agent Types

| Type | Description | When to Use |
|---|---|---|
| Service Agent | Handles customer service interactions; default for Experience Cloud / site deployments | Customer-facing deflection, case handling |
| Sales Agent | SDR / BDR prospecting and qualification workflows | Outreach, lead nurturing, pipeline creation |
| Field Service Agent | Mobile workforce scheduling and dispatch support | FSL integrations, technician dispatch |
| HR Agent | Employee self-service and HR process guidance | Internal HR portals, onboarding |
| Agentforce for Commerce | Product discovery, cart, checkout assistance | B2B/B2C storefront agents |
| Custom (External) | Fully custom agent exposed via Agent API to external systems | Headless, web, mobile deployments |
| Custom (Internal) | Fully custom agent surfaced inside Salesforce UI | Internal productivity, back-office |

For Python SDK, `agent_type` is either `"External"` or `"Internal"`.

---

## Agentblazer Badge Curriculum — Scope Map

| Badge | Level | Scope |
|---|---|---|
| Champion | Foundation | What Agentforce is; agent types; basic action types; Einstein Trust Layer; terminology; no-code setup in Builder |
| Innovator | Intermediate | Agent API (REST sessions); Models API (Apex + REST); Agentforce DX (CLI + VS Code); Testing API (AiEvaluationDefinition + Connect API); advanced action types |
| Legend | Advanced | Agent Script (deterministic + LLM hybrid); custom actions (Citations Apex, Lightning Types); Mobile SDK (iOS + Android); Python SDK; multi-agent orchestration; BYOLLM + LLM Open Connector |

---

## Core Concepts

### Agent
An agent is a combination of:
- **Role / Instructions** — natural language description of what the agent does and how it behaves
- **Subagents (Topics)** — discrete domains of capability; each has a scope, instructions, and a set of actions
- **Actions** — the tools an agent can call (Apex, Flow, SOQL, etc.)
- **Variables** — typed values that persist across a conversation session

### Subagent (formerly Topic)
A subagent is a scoped domain within an agent. When a user message is received, the Agentforce engine classifies it to a subagent based on the subagent's `scope` description. The subagent then selects and calls relevant actions.

Key configuration fields:
- `name` — developer name
- `description` — natural language description of the subagent's purpose
- `scope` — what kinds of user requests this subagent handles
- `instructions` — rules for how the subagent should behave
- `actions` — list of callable actions

### Action
An action is a callable tool exposed to an agent. Five types:

| Type | Description | Invoked Via |
|---|---|---|
| Apex (REST) | Custom Apex logic via REST endpoint | `@AuraEnabled` or `@RestResource` |
| AuraEnabled | Standard AuraEnabled Apex method | Method-level invocation |
| Named Query | SOQL query registered as a callable | Name-based invocation |
| Invocable Method | Apex method with `@InvocableMethod` | Name-based invocation |
| Lightning Types | Structured data input/output actions with schema validation | 12 supported types |

### Einstein Trust Layer
- All LLM calls go through Salesforce infrastructure — LLM providers (Anthropic, Google, OpenAI, BYOLLM) never receive raw Salesforce data
- Data masking replaces PII with tokens before sending to LLM
- Zero retention guarantee: LLM providers cannot store prompts or responses
- Full audit trail in Einstein Activity Log
- Toxicity and bias detection via guardrails

### Einstein Requests
The billing unit for Agentforce. Each agent message exchange consumes Einstein Requests. Track consumption via:
- Salesforce Setup > Einstein > Einstein Requests Usage
- `aiplatform.ModelsAPI` calls also consume Einstein Requests (1 request per API call)

---

## Key Platform Components

| Component | Description |
|---|---|
| Agentforce Builder | No-code UI for creating and testing agents in Setup |
| Agentforce DX | CLI + VS Code tooling for code-first agent development (YAML spec) |
| Agent API | REST API for starting sessions and exchanging messages programmatically |
| Models API | Apex + REST API for direct LLM access within Salesforce |
| Testing API | AiEvaluationDefinition metadata + Connect API for automated agent testing |
| Agent Script | Deterministic-first authoring mode for scripted conversation flows |
| Python SDK | `agentforce-sdk` PyPI package for agent creation from Python |
| Mobile SDK | iOS (SwiftUI, iOS 17+) + Android (Jetpack Compose, API 29+) native integration |

---

## License Types

| Feature | License Required |
|---|---|
| Agentforce (base agents) | Agentforce for Salesforce / Einstein Platform Add-On |
| Models API | Einstein AI Add-On or Platform License with Einstein Requests entitlement |
| Agentforce for Commerce | Commerce Cloud + Agentforce license |
| Mobile SDK | No additional license — uses Agent API |
| BYOLLM | AI Gateway license or equivalent |

---

## API Version Notes

| Feature | Minimum API Version |
|---|---|
| AiEvaluationDefinition (Testing) | v63.0 |
| GenAiFunction metadata type | v59.0+ |
| GenAiPlannerBundle metadata type | v59.0+ |
| GenAiPlugin metadata type (subagents) | v59.0+ |
| Models API Apex (`aiplatform.ModelsAPI`) | v59.0+ |
| Lightning Types action type | v62.0+ |
| Bot / BotVersion metadata type | v47.0+ (predates Agentforce) |

---

## Documentation Sources

All accessible at `developer.salesforce.com/docs/ai/agentforce/` — HTML pages, no JS rendering required. Atlas PDF API has no Agentforce PDFs (confirmed: all slug variants return empty body). Trailhead and help.salesforce.com Agentforce pages are JS-rendered SPAs and not accessible programmatically.
