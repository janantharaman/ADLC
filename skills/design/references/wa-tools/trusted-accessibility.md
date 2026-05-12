---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-accessibility.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Compliant — Accessibility
---

### Data Entry Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Accessibility](/docs/architect/well-architected/guide/compliant#accessibility) → [Data Entry](/docs/architect/well-architected/guide/compliant#data-entry)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Design Standards | ✅ All devices that may be used for data input beyond a standard keyboard and mouse are listed |
| Platform | Design Standards | ✅ Text values and their translations into all supported languages are listed |
| Platform | Org | ✅ Translations for supported languages are stored in Translation Workbench |
| Platform | Test Plans | ✅ Test steps include using multiple types of input devices to enter data |
| Platform | Test Plans | ✅ Test steps include data entry in multiple languages |

### Navigation Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Accessibility](/docs/architect/well-architected/guide/compliant#accessibility) → [Navigation](/docs/architect/well-architected/guide/compliant#navigation)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Design Standards | ✅ All devices that may be used for navigation (not just standard keyboard and mouse) are clearly listed |
| Platform | Design Standards | ✅ UI/UX standards specify the type and style of all navigational controls |
| Platform | Design Standards | ✅ The types of visual cues approved to convey meaning or state are clearly listed, and color is not a primary cue |
| Platform | Test Plans | ✅ Test plans include using UI/UX testing to ensure consistent navigational paths |
| Platform | Test Plans | ✅ Test steps include using multiple types of input devices to navigate |

### Data Entry Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Accessibility](/docs/architect/well-architected/guide/compliant#accessibility) → [Data Entry](/docs/architect/well-architected/guide/compliant#data-entry)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Only some, or none, of the devices that may be used for data input beyond a standard keyboard and mouse are listed |
| Platform | Design Standards | ⚠️ Supported languages are listed along with UI elements to be translated |
| Platform | Org | ⚠️ Translations are stored in custom labels |
| Platform | Test Plans | ⚠️ Accessibility testing is not included or testing for accessible data entry is done ad hoc |

### Navigation Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Accessibility](/docs/architect/well-architected/guide/compliant#accessibility) → [Navigation](/docs/architect/well-architected/guide/compliant#navigation)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not account for accessibility requirements for navigational controls |
| Platform | Design Standards | ⚠️ UI/UX standards for navigation are inconsistent |
| Platform | Design Standards | ⚠️ Visual cues for meaning or state rely on color or there are no clear lists of visual cues for builders |
| Platform | Test Plans | ⚠️ Accessibility testing is not included or testing for accessible navigation is done ad hoc |
