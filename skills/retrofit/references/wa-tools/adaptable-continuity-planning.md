---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/adaptable-continuity-planning.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Resilient — Continuity Planning
---

### Building Backup and Restore Capabilities Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Continuity Planning](/docs/architect/well-architected/guide/resilient#continuity-planning) → [Building Backup and Restore Capabilities](/docs/architect/well-architected/guide/resilient#building-backup-and-restore-capabilities)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Company | ✅ Test plans and test logs show data restores are tested in a full or partial copy sandbox at least two times each year |
| Platform | Company | ✅ Backups are stored in a secure location accessibly by only authorized users |
| Platform | Documentation | ✅ A backup and restore strategy exists for both data and metadata |

### Business Continuity Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Continuity Planning](/docs/architect/well-architected/guide/resilient#continuity-planning) → [Business Continuity](/docs/architect/well-architected/guide/resilient#business-continuity)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ A "recovery first" mindset is adopted with a focus on bringing the highest priority business functions and capabilities out of impact as soon as possible |
| Platform | Business | ✅ There is a maintenance schedule for the review of BCP test plans |
| Platform | Documentation | ✅ A BCP exists containing: steps to continue processing or triage data if Salesforce becomes unavailable, a list of events that can trigger the use of the BCP, steps and intervals for BCP testing |
| Platform | Documentation | ✅ Your BCP includes upstream and downstream systems and dependencies |

### Technology Continuity Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Continuity Planning](/docs/architect/well-architected/guide/resilient#continuity-planning) → [Technology Continuity](/docs/architect/well-architected/guide/resilient#technology-continuity)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Business | ✅ You have evaluated if you need to build intentional redundancy or fail-over systems |
| Platform | Business | ✅ Incident recovery tactics are automated wherever possible |
| Platform | Documentation | ✅ Your BCP accounts for additional resources or break-glass procedures teams might need to respond to incidents effectively |
| Platform | Test Plans | ✅ The areas of your BCP related to processes and people are accounted for |

### Building Backup and Restore Capabilities Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Continuity Planning](/docs/architect/well-architected/guide/resilient#continuity-planning) → [Building Backup and Restore Capabilities](/docs/architect/well-architected/guide/resilient#building-backup-and-restore-capabilities)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Company | ⚠️ There is no data restoration process or the data restoration process is untested |
| Platform | Company | ⚠️ Backups are not human readable |
| Platform | Company | ⚠️ Backups are stored in locations that unauthorized business users can access |
| Platform | Documentation | ⚠️ A backup and restore strategy does not exist or the strategy is incomplete (it applies to only data or metadata, not both) |

### Business Continuity Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Continuity Planning](/docs/architect/well-architected/guide/resilient#continuity-planning) → [Business Continuity](/docs/architect/well-architected/guide/resilient#business-continuity)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ A "fix-the-problem" mentality is the only approach to incident management |
| Platform | Business | ⚠️ BCP test plans are not refreshed at regular intervals |
| Platform | Documentation | ⚠️ Your BCP only includes Salesforce |
| Platform | Documentation | ⚠️ A BCP does not exist or is incomplete |

### Technology Continuity Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Resilient](/docs/architect/well-architected/guide/resilient) → [Continuity Planning](/docs/architect/well-architected/guide/resilient#continuity-planning) → [Technology Continuity](/docs/architect/well-architected/guide/resilient#technology-continuity)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Business | ⚠️ You have not evaluated the need for intentional redundancy or fail-over systems |
| Platform | Business | ⚠️ Incident recovery tactics are all manual |
| Platform | Documentation | ⚠️ Your BCP does not include operational support needs |
| Platform | Test Plans | ⚠️ The areas of your BCP related to processes and people are not accounted for |
