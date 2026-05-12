---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/adaptable-packageability.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Composable — Packageability
---

### Dependency Management Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Packageability](/docs/architect/well-architected/guide/composable#packageability) → [Dependency Management](/docs/architect/well-architected/guide/composable#dependency-management)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Design Standards | ✅ Standards for introducing or modifying dependencies exist |
| Platform | Design Standards | ✅ Standards for declaring dependencies exist |
| Platform | Packages | ✅ No metadata is duplicated across packages |
| Platform | Packages | ✅ For package development, all early-stage development work happens in scratch orgs |
| Platform | Source Control | ✅ Developers can create scratch orgs and deploy package metadata successfully from source control |
| Platform | Source Control | ✅ Package versions for unlocked packages use aliasing (`LATEST`) to declare dependencies in `sfdx-project.json` manifests |

### Loose Coupling Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Packageability](/docs/architect/well-architected/guide/composable#packageability) → [Loose Coupling](/docs/architect/well-architected/guide/composable#loose-coupling)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apex | ✅ Methods dependent on dynamic, run-time information reference appropriate custom metadata types |
| Platform | Apex | ✅ Common services and boilerplate code are defined using abstract or virtual Apex classes |
| Platform | Design Standards | ✅ (Optional) All approved use cases for custom settings are clearly listed (if you have any) |
| Platform | Design Standards | ✅ Naming conventions address how to denote package units |
| Platform | Design Standards | ✅ It's possible to search for and find a list of all currently defined package units (and related naming conventions) |
| Platform | Design Standards | ✅ Standards for proposing package unit additions or changes exist |
| Platform | Org | ✅ Custom metadata types provide dynamic, run-time information for code and declarative customizations |
| Platform | Org | ✅ No custom objects exist in order to provide dynamic, run-time information for code or declarative customizations |
| Platform | Org | ✅ No custom settings exist or few custom settings exist, and none are related to packaged functionality |
| Platform | Packages | ✅ No unmanaged packages are defined in production or sandboxes |
| Platform | Packages | ✅ Org-dependent unlocked packages are used only for early-stage or proof-of-concept experiments |
| Platform | Source Control | ✅ `package.xml` files only appear in early stage or proof-of-concept project manifests |

### Dependency Management Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Packageability](/docs/architect/well-architected/guide/composable#packageability) → [Dependency Management](/docs/architect/well-architected/guide/composable#dependency-management)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not deal with how to declare dependencies |
| Platform | Packages | ⚠️ Dependencies are circumvented by duplicating metadata in different packages |
| Platform | Packages | ⚠️ Early package development happens in developer sandboxes or early package development cannot happen in scratch orgs |
| Platform | Source Control | ⚠️ Developers cannot work successfully with scratch orgs using source control |
| Platform | Source Control | ⚠️ Package versions for unlocked packages are declared explicitly (no `LATEST` aliasing) in `sfdx-project.json` manifests |

### Loose Coupling Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Packageability](/docs/architect/well-architected/guide/composable#packageability) → [Loose Coupling](/docs/architect/well-architected/guide/composable#loose-coupling)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ Common services and boilerplate code are not easily distinguished from other classes |
| Platform | Apex | ⚠️ Methods do not use a consistent approach for accessing dynamic, run-time information, or methods query custom objects for runtime behavior information, or code references custom settings |
| Platform | Apex | ⚠️ Internal references across classes and methods are hard to follow and are inconsistent throughout the codebase |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not deal with package units and use cases |
| Platform | Org | ⚠️ Custom settings are used |
| Platform | Org | ⚠️ Custom objects exist in order to provide dynamic, run-time information for code or declarative customizations |
| Platform | Org | ⚠️ Custom metadata types are not used (or are not used consistently) to provide dynamic, run-time information for code and declarative customizations |
| Platform | Packages | ⚠️ Unmanaged packages are defined in production or sandboxes |
| Platform | Packages | ⚠️ All packages are org-dependent unlocked packages |
| Platform | Source Control | ⚠️ `package.xml` files are used to control metadata deployments |
