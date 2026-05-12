---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/easy-helpful.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Engaging — Helpful
---

### In-App Guidance Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Helpful](/docs/architect/well-architected/guide/engaging#helpful) → [In-App Guidance](/docs/architect/well-architected/guide/engaging#in-app-guidance)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Design Standards | ✅ Design patterns for prompts and walkthroughs |
| Platform | Design Standards | ✅ Approved use cases for in-app guidance |
| Platform | Documentation | ✅ A clear matrix of users, apps, and active in-app guidance |
| Platform | Org | ✅ The setting for "Delay Between In-App Guidance" uses the default value or a custom value that is longer than the default (24-hour) period provided by Salesforce |
| Platform | Org | ✅ No apps have more than one active walkthrough |
| Platform | Org | ✅ No walkthroughs have a "Times to show" setting that is higher than 10 |
| Platform | Org | ✅ No prompts are activated for "Any page, any app" or "This page, any app" |

### Notifications and Messages Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Helpful](/docs/architect/well-architected/guide/engaging#helpful) → [Notifications and Messages](/docs/architect/well-architected/guide/engaging#notifications-and-messages)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Agents | ✅ Your agent welcome message introduces the agent as an AI assistant Your welcome message should inform users that they aren't chatting with a human |
| Einstein | Business | ✅ Employees are asked to give feedback on output generated Employees are asked to give feedback on output generated |
| Platform | Apps | ✅ No generative responses are sent directly to end users without points of human involvement |
| Platform | Design Standards | ✅ Approved use cases for notifications, toasts, and notices |
| Platform | Design Standards | ✅ Design patterns for toast variants and notifications |
| Platform | Design Standards | ✅ Design patterns for error messaging |
| Platform | Org | ✅ AI disclaimers are in clear and understandable language for users |
| Platform | Org | ✅ Bots clearly identify themselves before the first interaction with users |
| Platform | Org | ✅ Generative responses always identify data sources used |
| Platform | Org | ✅ Disclaimers for risks associated with generative AI appear to users before first interaction |
| Platform | Org | ✅ Notifications are the predominant messaging format |
| Platform | Org | ✅ Toast messages use variants |
| Platform | Org | ✅ Toast messages with `mode` set to `sticky` do not exist |
| Platform | Org | ✅ Notices are used rarely, if at all |

### Recognition & Rewards Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Helpful](/docs/architect/well-architected/guide/engaging#helpful) → [Recognition & Rewards](/docs/architect/well-architected/guide/engaging#recognition-rewards)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Org | ✅ Apps use embedded analytics to show users relevant goal progress and productivity stats |
| Platform | Org | ✅ Path celebrations are enabled only with user consent |
| Platform | Org | ✅ Notifications and messaging include user recognition, and reflect user preferences in the design of who is notified and what triggers notifications |

### In-App Guidance Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Helpful](/docs/architect/well-architected/guide/engaging#helpful) → [In-App Guidance](/docs/architect/well-architected/guide/engaging#in-app-guidance)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Documentation does not include a clear matrix showing users, apps, active in-app guidance |
| Platform | Design Standards | ⚠️ Do not address in-app guidance |
| Platform | Org | ⚠️ The setting for "Delay Between In-App Guidance" is set to a period that is shorter than the default (24-hour) period provided by Salesforce |
| Platform | Org | ⚠️ Apps have more than one active walkthrough |
| Platform | Org | ⚠️ Many walkthroughs have a "Times to show" setting that is higher than 10 (and some have the maximum value of 30) |
| Platform | Org | ⚠️ Prompts are activated ad hoc, many with the "Any page, any app" or "This page, any app" setting |

### Notifications and Messages Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Helpful](/docs/architect/well-architected/guide/engaging#helpful) → [Notifications and Messages](/docs/architect/well-architected/guide/engaging#notifications-and-messages)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apps | ⚠️ Generative responses are sent directly to end users without points of human involvement |
| Platform | Design Standards | ⚠️ If design standards are defined at all, they do not address errors and notifications |
| Platform | Org | ⚠️ Toast messages with `mode` set to `sticky` exist |
| Platform | Org | ⚠️ Toast messages do not consistently use variants |
| Platform | Org | ⚠️ Generative responses do not identify data sources used |
| Platform | Org | ⚠️ No disclaimers for generative AI risks appears to users |
| Platform | Org | ⚠️ AI disclaimers are not in clear and understandable language for users |
| Platform | Org | ⚠️ Bots do not clearly identify themselves before the first interaction with users |
| Platform | Org | ⚠️ Emails are the predominant messaging format |
| Platform | Org | ⚠️ There is no consistent approach to message types |
| Platform | Org | ⚠️ Notices are used ad hoc |

### Recognition & Rewards Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Helpful](/docs/architect/well-architected/guide/engaging#helpful) → [Recognition & Rewards](/docs/architect/well-architected/guide/engaging#recognition-rewards)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Org | ⚠️ Analytics related to goal progress and productivity stats are only available in reports or manager dashboards |
| Platform | Org | ⚠️ Path celebrations are enabled without checking for user consent |
| Platform | Org | ⚠️ Notifications and messaging do not include any kind of user recognition or don't reflect the preferences of users and feel noisy or gimmicky |
