---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-availability.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Reliable — Availability
---

### Failure Mitigation Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Availability](/docs/architect/well-architected/guide/reliable#availability) → [Failure Mitigation](/docs/architect/well-architected/guide/reliable#failure-mitigation)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ Failure mitigation plans are tested often Failure mitigation plans are tested periodically (every 1-2 years), reactively after major incidents as part of post-mortem, and proactively before major business or IT events |
| Platform | Org | ✅ Mitigation controls are put in place immediately, mature over time, and incorporate automation as early as possible |
| Platform | Org | ✅ Asynchronous processes are monitored Asynchronous processes are monitored using Proactive Monitoring or querying AsyncApexJob executed by an external scheduled job. Alerts are in place to catch issues early, resulting in faster Time-to-Detect (TTD) and Time-to-Engage (TTE) |
| Platform | Org | ✅ A subset of trained end users create list views, reports, and dashboards Trained end users create reports, list views, and dashboards as part of an org-wide reporting strategy that includes documented guidelines and regular reviews |
| Platform | Org | ✅ Failure point triggers and their corresponding mitigation plans are categorized by people, process, and technology |

### Risk Management Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Availability](/docs/architect/well-architected/guide/reliable#availability) → [Risk Management](/docs/architect/well-architected/guide/reliable#risk-management)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ An established risk assessment framework is in use |
| Platform | Business | ✅ Risk assessments are signed-off on by a variety of stakeholder groups Risk assessments are reviewed and signed-off on by a variety of business and technical stakeholders |
| Platform | Business | ✅ Risk assessment frameworks follow industry and company standards Your risk assessment framework follows company standards and follows any of the following industry and regulatory standards: ISO/IEC 27001, NIST Cybersecurity Framework (CSF), COBIT (Control Objectives for Information and Related Technologies), ISO/IEC 27005, GDPR (General Data Protection Regulation), OWASP (Open Web Application Security Project), CSA Cloud Controls Matrix (CCM), PCI DSS (Payment Card Industry Data Security Standard), or SOC 2 (System and Organization Controls) |
| Platform | Business | ✅ Risk is assessed before introducing major change Risk is assessed proactively before any major change in your business or implementation. Signature Success customers leverage Key Events Management. |
| Platform | Business | ✅ Seasonal spikes are planned for ahead of time Peak usage events (like seasonal spikes in traffic) are planned for ahead of time. Signature Success customers leverage Key Events Management. |
| Platform | Business | ✅ Risk assessment is reviewed often Risk assessment is reviewed reactively after a major incident or close call, proactively before a new product, feature rollout, or new business unit onboarding, proactively before major business events (seasonal spikes, major business changes), and periodically (every 1-2 years) |
| Platform | Business | ✅ Risks are categorized into people, process, and technology areas |
| Platform | Documentation | ✅ Risk severity is categorized and assessed based on customer impact |
| Platform | Documentation | ✅ Risk mitigation and response plans are prioritized, focusing on highest priority risks first |

### Failure Mitigation Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Availability](/docs/architect/well-architected/guide/reliable#availability) → [Failure Mitigation](/docs/architect/well-architected/guide/reliable#failure-mitigation)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ Failure mitigation plans aren't sufficiently tested Failure mitigations are never tested or only tested after initial design/build phase |
| Platform | Business | ⚠️ Seasonal spikes are not accounted for ahead of time Peak usage events (like seasonal spikes in traffic) aren't planned for ahead of time |
| Platform | Org | ⚠️ Automation is not used in mitigation |
| Platform | Org | ⚠️ Failure point triggers are not classified; mitigation approaches are ad hoc or non-existent |
| Platform | Org | ⚠️ Mitigation controls are not revisited or evolved |
| Platform | Org | ⚠️ Asynchronous processes are not proactively monitored Async processes rely on a custom error logging mechanism that is part of the asynchronous process itself, or are not monitored at all |
| Platform | Org | ⚠️ End users are solely responsible for list views, reports, and dashboards End users are free to create public reports, list views and dashboards, and periodic performance reviews of these metadata items do not exist |

### Risk Management Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Reliable](/docs/architect/well-architected/guide/reliable) → [Availability](/docs/architect/well-architected/guide/reliable#availability) → [Risk Management](/docs/architect/well-architected/guide/reliable#risk-management)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ Risk isn't clearly identified |
| Platform | Business | ⚠️ The risk assessment framework for Salesforce is ad hoc |
| Platform | Business | ⚠️ Risk assessment frameworks are developed in a silo Your risk assessment framework is developed by one team in isolation, and does not align with corporate guidelines or industry standards |
| Platform | Business | ⚠️ Risk management is considered a "one-off" activity Risk assessments are performed once and/or your risk assessment framework is not regularly updated |
| Platform | Documentation | ⚠️ The customer perspective isn't considered when assessing risk severity or category |
| Platform | Documentation | ⚠️ Risk mitigation and response plans try to capture every risk imaginable |
