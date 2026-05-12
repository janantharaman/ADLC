---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/adaptable-separation-of-concerns.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Composable — Separation of Concerns
---

### Functional Units Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Separation of Concerns](/docs/architect/well-architected/guide/composable#separation-of-concerns) → [Functional Units](/docs/architect/well-architected/guide/composable#functional-units)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Org | ✅ Iterate on prompt templates to understand what inputs impact the response Iterate on prompt templates to understand how the parts impact the model's response |
| Platform | Design Standards | ✅ A list of all currently defined functional units (and related naming conventions) exists |
| Platform | Design Standards | ✅ Standards for proposing functional unit additions or changes exist |
| Platform | Design Standards | ✅ Naming conventions address how to denote a functional unit |
| Platform | Documentation | ✅ All documentation and implementation diagrams clearly show the functional unit(s) for components |
| Platform | Documentation | ✅ All components within a functional unit are searchable and easy to find |
| Platform | Documentation | ✅ System landscape diagrams clearly show the functional units in an org |
| Platform | Documentation | ✅ Documentation for individual components include functional unit mapping for the component |
| Platform | Org | ✅ It is possible to quickly identify functional unit alignment for a given piece of metadata (for example, a flow, Apex class, or Lightning page) |
| Platform | Org | ✅ Functional units are labelled in business-friendly terms |

### State Management Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Separation of Concerns](/docs/architect/well-architected/guide/composable#separation-of-concerns) → [State Management](/docs/architect/well-architected/guide/composable#state-management)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apex | ✅ Savepoints and rollback behaviors are used in all data operations |
| Platform | Design Standards | ✅ Use cases for stateful vs. stateless designs are clear |
| Platform | Design Standards | ✅ Approved patterns for stateful communication exist |
| Platform | Design Standards | ✅ Approved patterns for stateless communication exist |
| Platform | Design Standards | ✅ Clear categories for state exist |
| Platform | Documentation | ✅ Every component that handles stateful and/or stateless communication indicates what pattern has been implemented |
| Platform | Documentation | ✅ Process and interaction diagrams provide detail about state categories and hand-offs |
| Platform | Documentation | ✅ It is possible to search for and find all components that have implemented a particular stateful/stateless pattern |
| Platform | Flow | ✅ Fault paths and the Roll Back Records element is used |

### Functional Units Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Separation of Concerns](/docs/architect/well-architected/guide/composable#separation-of-concerns) → [Functional Units](/docs/architect/well-architected/guide/composable#functional-units)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not deal with functional units and use cases |
| Platform | Documentation | ⚠️ You cannot search for a particular functional unit and/or searches do not help identify all the components within a functional unit |
| Platform | Documentation | ⚠️ Component documentation describes the functional unit a component belongs to, but that is the only place the definition of that functional unit appears |
| Platform | Documentation | ⚠️ Component documentation does not exist |
| Platform | Org | ⚠️ It is not possible to identify functional unit alignment for any metadata |
| Platform | Org | ⚠️ Functional unit information is inconsistent or inaccurate |
| Platform | Org | ⚠️ Functional unit information is labelled in engineering-focused terms that are meaningless to business users |

### State Management Anti-Pattern

Learn more about Well-Architected [Adaptable](/docs/architect/well-architected/guide/adaptable-overview) → [Composable](/docs/architect/well-architected/guide/composable) → [Separation of Concerns](/docs/architect/well-architected/guide/composable#separation-of-concerns) → [State Management](/docs/architect/well-architected/guide/composable#state-management)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apex | ⚠️ Savepoints and rollback behaviors are not used |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not deal with state/stateless patterns and use cases |
| Platform | Documentation | ⚠️ Component documentation does not exist |
| Platform | Documentation | ⚠️ Component documentation describes the stateful/stateless pattern implemented, but that is the only place the definition appears |
| Platform | Documentation | ⚠️ It is not possible to search for a particular pattern and/or searches do not help identify all the components using that pattern |
| Platform | Flow | ⚠️ The Roll Back Records element is not used |
