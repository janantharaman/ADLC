---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/easy-maintainability.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Intentional — Maintainability
---

### Standard vs Custom Functionality Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Maintainability](/docs/architect/well-architected/guide/intentional#maintainability) → [Standard vs Custom Functionality](/docs/architect/well-architected/guide/intentional#standard-vs-custom-functionality)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Data 360 | Org | ✅ Standard connectors are leveraged whenever possible If a standard connector is available, carefully consider the implications of implementing a custom data stream. Custom streams won't be able to leverage enhancements to standard functionality |
| Einstein | Org | ✅ Start with existing prompts and customize it to fit your needs. Utilize best practices from the Example Prompt Template Library instead of drafting a new prompt from scratch |
| Einstein | Prompt Templates | ✅ Prompt templates use Einstein Search Retrievers for RAG Low-code Search Retrievers are used instead of custom Apex, when using retrieval augmented generation in a prompt template |
| Platform | Apex | ✅ No code exists to override standard page view mechanisms |
| Platform | Aura | ✅ No code exists to override standard page view mechanisms |
| Platform | Aura | ✅ No code attempts to override or circumvent the platform order of execution |
| Platform | Data Model | ✅ No objects have names or functionality that duplicates standard objects |
| Platform | Data Model | ✅ Standard objects are not used for purposes that are far outside their intended scope |
| Platform | Decision Records | ✅ Decision records show calculation for near- and long-term costs when choosing to build or buy solutions |
| Platform | Design Standards | ✅ The guiding principle for solutions uses the following priority: 1. Use built-in platform services 2. Consider AppExchange apps before building a custom solution 3. Use low-code customizations before writing code |
| Platform | Design Standards | ✅ There is a clear guiding principle to keep solutions from unnecessary customization |
| Platform | Lightning Web Components (LWC) | ✅ No code exists to override standard page view mechanisms |
| Platform | Lightning Web Components (LWC) | ✅ No code attempts to override or circumvent the platform order of execution |
| Platform | Visualforce | ✅ No code attempts to override or circumvent the platform order of execution |

### Technical Debt Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Maintainability](/docs/architect/well-architected/guide/intentional#maintainability) → [Technical Debt](/docs/architect/well-architected/guide/intentional#technical-debt)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Decision Records | ✅ KPIs for pre/post tech debt remediation are clearly documented |
| Platform | Decision Records | ✅ Trade-off discussions for action and inaction focus on business costs or benefits |
| Platform | Org | ✅ No unsupported or legacy technology is active Salesforce org connections use Cross-Org Adapter for Salesforce Connect |
| Platform | Org | ✅ No unsupported or legacy technology is active Including: - All users work in Lightning Experience - No or very few uses of `@future` in Apex (Queueable is used) - All third-party Apex belongs to AppExchange packages - No active Workflow Rules (Flow is used) - No active Process Builder processes (Flow is used) - PushTopic Events (Change Data Capture is used) - Generic Events (Platform Events are used) - API versions prior to 30.0 - Salesforce org connections use Cross -Org Adapter for Salesforce Connect |
| Platform | Org | ✅ No unsupported or legacy technology is active No or very few uses of `@future` in Apex (Queueable is used) |
| Platform | Org | ✅ No unsupported or legacy technology is active All third-party Apex belongs to AppExchange packages |
| Platform | Org | ✅ No unsupported or legacy technology is active All users work in Lightning Experience |
| Platform | Org | ✅ No unsupported or legacy technology is active No active Workflow Rules (Flow is used) |
| Platform | Org | ✅ No unsupported or legacy technology is active No active Process Builder processes (Flow is used) |
| Platform | Org | ✅ No unsupported or legacy technology is active PushTopic Events (Change Data Capture is used) |
| Platform | Org | ✅ No unsupported or legacy technology is active API versions prior to 30.0 |
| Platform | Org | ✅ No unsupported or legacy technology is active Generic Events (Platform Events are used) |
| Platform | Roadmap | ✅ Deliverables and begin/end dates are clear |
| Platform | Roadmap | ✅ Work to address tech debt exists |

### Standard vs Custom Functionality Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Maintainability](/docs/architect/well-architected/guide/intentional#maintainability) → [Standard vs Custom Functionality](/docs/architect/well-architected/guide/intentional#standard-vs-custom-functionality)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Data 360 | Org | ⚠️ Infrequent use of standard connectors Implementing a custom data stream with batch or streaming ingestion, when a standard connector will do |
| Einstein | Prompt Templates | ⚠️ Prompt templates are created from scratch Prompt templates are created from scratch with varying styles, phrasing and formatting |
| Einstein | Prompt Templates | ⚠️ Prompt templates leverage custom Apex for RAG A custom Apex resource is used in your prompt templates to implement RAG |
| Platform | Apex | ⚠️ Code attempts to override or circumvent the platform order of execution |
| Platform | Aura | ⚠️ Code exists to override standard page view mechanisms, often in the form of a single page app |
| Platform | Aura | ⚠️ Code attempts to override or circumvent the platform order of execution |
| Platform | Data Model | ⚠️ Objects duplicate the names and/or functionality of standard objects |
| Platform | Data Model | ⚠️ Standard objects are used for purposes far outside their intended scope |
| Platform | Decision Records | ⚠️ Decision records do not consider both near- and long-term costs when choosing to build or buy solutions |
| Platform | Design Standards | ⚠️ Design standards either don't exist or don't have a clear rationale for avoiding unneeded customizations and code |
| Platform | Lightning Web Components (LWC) | ⚠️ Code exists to override standard page view mechanisms, often in the form of a single page app |
| Platform | Lightning Web Components (LWC) | ⚠️ Code attempts to override or circumvent the platform order of execution |
| Platform | Visualforce | ⚠️ Code exists to override standard page view mechanisms, often in the form of a single page app |

### Technical Debt Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Intentional](/docs/architect/well-architected/guide/intentional) → [Maintainability](/docs/architect/well-architected/guide/intentional#maintainability) → [Technical Debt](/docs/architect/well-architected/guide/intentional#technical-debt)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Decision Records | ⚠️ Tech debt remediation has no measurable KPIs |
| Platform | Decision Records | ⚠️ Tech debt is considered in technical or IT-focused terms, with no relevance to the business |
| Platform | Org | ⚠️ Unsupported or legacy technology is active API versions prior to 30.0 |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Workflow Rules |
| Platform | Org | ⚠️ Unsupported or legacy technology is active PushTopic Events |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Process Builder processes |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Generic Events |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Users working in Salesforce Classic |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Salesforce to Salesforce connections |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Including: - Users working in Salesforce Classic - `@future` usage in Apex - Third-party Apex from non-AppExchange sources - Workflow Rules - Process Builder processes - PushTopic Events - Generic Events - API versions prior to 30.0 - Salesforce to Salesforce connections |
| Platform | Org | ⚠️ Unsupported or legacy technology is active `@future` usage in Apex |
| Platform | Org | ⚠️ Unsupported or legacy technology is active Third-party Apex from non-AppExchange sources |
| Platform | Roadmap | ⚠️ No work to address tech debt is planned |
| Platform | Roadmap | ⚠️ Deliverables are vague; begin/end dates are unclear |
