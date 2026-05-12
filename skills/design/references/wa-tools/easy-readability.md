---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/easy-readability.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Intentional — Readability
---

### Design Standards Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Readability](/docs/architect/well-architected/guide/intentional#readability) → [Design Standards](/docs/architect/well-architected/guide/intentional#design-standards)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Agents | ✅ The language setting of your agent matches your company's tone If your company's tone is formal, such as a financial institution, the tone setting of your agent is "formal". If your company is informal, the tone setting is "casual". Otherwise, your tone setting is "neutral" |
| Einstein | Org | ✅ Prompt templates leverage formatting to provide context to the LLM A single hash is used to mark a short block of text as a single unit of prompt template context |
| Einstein | Org | ✅ Prompt templates use a consistent writing style Your word choice, formatting, emojis, and punctuation are consistent across templates |
| Einstein | Org | ✅ Prompt templates are concise, easy to understand and use natural language. Templates avoid industry jargon or technical terms |
| Einstein | Org | ✅ Your prompt templates clearly denote context and instructions. After you have provided context in the prompt, start a new line with the text 'Instructions', followed by the instructions surrounded with triple quotes (""") |
| Platform | Business | ✅ Approved AI models are clearly identified and include an intended purpose |
| Platform | Business | ✅ Approved design patterns are easy to find and identify by use case |
| Platform | Business | ✅ Teams know what tools to use (and not use) to get work done |
| Platform | Org | ✅ Code and declarative customizations have consistent, human-readable names |
| Platform | Org | ✅ Data models have consistent, uniform names for objects and fields |
| Platform | Org | ✅ Audits show fields are consistently filled out and referenced in reports, etc. |

### Documentation Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Readability](/docs/architect/well-architected/guide/intentional#readability) → [Documentation](/docs/architect/well-architected/guide/intentional#documentation)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Documentation | ✅ Source systems are inventoried in a data dictionary Data 360 data sources are documented in the solution design process using a data dictionary that includes the source and target systems and the field mappings between the two |
| Platform | Business | ✅ Diagrams for business capabilities and technical implementation details exist for all solutions |
| Platform | Business | ✅ Key who/when/what information logs exist for code and declarative customizations |
| Platform | Business | ✅ People can search for and find relevant documentation |
| Platform | Org | ✅ Code and declarative customizations have clear descriptions |

### Design Standards Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Readability](/docs/architect/well-architected/guide/intentional#readability) → [Design Standards](/docs/architect/well-architected/guide/intentional#design-standards)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Einstein | Prompt Templates | ⚠️ Prompt templates use jargon and/or technical terms Prompt templates include jargon, acronyms and technical terms instead of concise natural language |
| Platform | Business | ⚠️ Approved AI models are not clearly identified, and their intended purpose is unclear |
| Platform | Business | ⚠️ Teams use many different tools to get similar work done |
| Platform | Business | ⚠️ There are no approved design patterns |
| Platform | Business | ⚠️ It takes a lot of time for vendors or new employees to onboard |
| Platform | Org | ⚠️ Code and declarative customizations do not have consistent names |
| Platform | Org | ⚠️ Data models have inconsistent names and many objects and fields seem to be redundant |
| Platform | Org | ⚠️ Audits show many unused fields or various levels of usage, and there is no consistent link to reporting, etc. |

### Documentation Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Readability](/docs/architect/well-architected/guide/intentional#readability) → [Documentation](/docs/architect/well-architected/guide/intentional#documentation)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Org | ⚠️ Source to target mappings are documented in the data mapping canvas only Data source fields are mapped to data model object fields on the fly during configuration in the data mapping canvas in Data 360 |
| Platform | Business | ⚠️ The what/how/why of solutions is hard to find and may be unavailable to most teams |
| Platform | Business | ⚠️ People struggle to understand solutions and the system they are working with |
| Platform | Business | ⚠️ It takes a lot of time for vendors or new employees to onboard |
| Platform | Org | ⚠️ Code and declarative customizations do not have descriptions, have descriptions that are difficult to understand, or have descriptions that don't seem to match what the customization is actually doing |
