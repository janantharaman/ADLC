---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-legal-adherence.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Compliant — Legal Adherence
---

### Data Privacy Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Legal Adherence](/docs/architect/well-architected/guide/compliant#legal-adherence) → [Data Privacy](/docs/architect/well-architected/guide/compliant#data-privacy)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Einstein Trust Layer | ✅ Mask fields by compliance category The Einstein Trust Layer has been customized to mask fields based on your business rules and a field's compliance category |
| Einstein | Einstein Trust Layer | ✅ Mask fields by sensitivity level The Einstein Trust Layer has been customized to mask fields based on your business rules and a field's sensitivity level |
| Platform | Documentation | ✅ You have an up-to-date data dictionary containing field level names, descriptions, and classifications |
| Platform | Documentation | ✅ You have an up-to-date security matrix that identifies which users have access to what data |
| Platform | Documentation | ✅ You have up-to-date design documentation, including standards and diagrams for any automations created to address regulatory requirements |
| Platform | Org | ✅ All objects and fields that contain sensitive information or are subject to data privacy regulations have Compliance Categorization, Data Owner, Data Sensitivity Level, and Field Usage configured |

### Localization Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Legal Adherence](/docs/architect/well-architected/guide/compliant#legal-adherence) → [Localization](/docs/architect/well-architected/guide/compliant#localization)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Documentation | ✅ You have an org strategy that outlines where data will be stored and maintained to comply with all applicable data residency requirements |
| Platform | Documentation | ✅ You have an integration strategy that outlines acceptable scenarios and processes for replicating data across borders |
| Platform | Documentation | ✅ You have an analytics strategy that outlines the level of granularity reports and dashboards can contain at regional, national, and global levels |

### Data Privacy Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Legal Adherence](/docs/architect/well-architected/guide/compliant#legal-adherence) → [Data Privacy](/docs/architect/well-architected/guide/compliant#data-privacy)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Documentation | ⚠️ A data dictionary does not exist or has not been kept up-to-date |
| Platform | Documentation | ⚠️ Sharing and visibility documentation does not exist or has not been kept up-to-date |
| Platform | Documentation | ⚠️ Design standards, diagrams, and documentation for automations that address regulatory requirements does not exist or has not been kept up-to-date |
| Platform | Org | ⚠️ Objects and fields that contain sensitive information or are subject to data privacy regulations are missing configuration for Compliance Categorization, Data Owner, Data Sensitivity Level, or Field Usage |

### Localization Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Legal Adherence](/docs/architect/well-architected/guide/compliant#legal-adherence) → [Localization](/docs/architect/well-architected/guide/compliant#localization)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Documentation | ⚠️ You do not have an analytics strategy or your analytics strategy does not address data localization and residency requirements |
| Platform | Documentation | ⚠️ You do not have an org strategy or your org strategy does not address data localization and residency requirements |
| Platform | Documentation | ⚠️ You do not have an integration strategy or your integration strategy does not address data localization and residency requirements |
