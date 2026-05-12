---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/easy-streamlined.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Engaging — Streamlined
---

### Application Complexity Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Streamlined](/docs/architect/well-architected/guide/engaging#streamlined) → [Application Complexity](/docs/architect/well-architected/guide/engaging#application-complexity)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Org | ✅ Apps have fewer than 10 tabs in the admin-provided default configuration |
| Platform | Org | ✅ No apps have "Disable end user personalization of nav items in this app" set to true |

### Form Factor Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Streamlined](/docs/architect/well-architected/guide/engaging#streamlined) → [Form Factor](/docs/architect/well-architected/guide/engaging#form-factor)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Aura | ✅ Custom Aura components available in App Builder declare supported form factors in their respective design files |
| Platform | Aura | ✅ Custom Aura components available in App Builder implement width-aware styling patterns |
| Platform | Aura | ✅ Custom Lightning page templates use `design:supportedFormFactors` and `design:supportedFormFactor` in Aura component design files |
| Platform | Desktop | ✅ Data input fields and navigation controls fit on the screen and can be interacted with as intended |
| Platform | Desktop | ✅ Record and app pages appear correctly, based on page activation assignment rules |
| Platform | Lightning Web Components (LWC) | ✅ Custom LWCs available in App Builder implement width-aware styling patterns |
| Platform | Lightning Web Components (LWC) | ✅ Custom LWCs available in App Builder declare supported form factors in their respective design files |
| Platform | Mobile Devices | ✅ Mobile navigation menus, optimized for smaller form factors, appear |
| Platform | Mobile Devices | ✅ Data inputs and navigation controls appear correctly |
| Platform | Mobile Devices | ✅ Users can input data easily |
| Platform | Mobile Devices | ✅ Compact layouts appear at the record level |
| Platform | Org | ✅ Salesforce-provided Lightning page templates are used for all or most pages |

### Forms Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Streamlined](/docs/architect/well-architected/guide/engaging#streamlined) → [Forms](/docs/architect/well-architected/guide/engaging#forms)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Apps | ✅ Data entry errors appear before users navigate away or submit data |
| Platform | Apps | ✅ Fields follow logical groupings |
| Platform | Apps | ✅ Data submission happens once |
| Platform | Apps | ✅ Labels for actions and navigation are clear |
| Platform | Apps | ✅ Timely and visual feedback is provided to acknowledge user actions such as button clicks |
| Platform | Apps | ✅ Navigation buttons (for example, "go", "next", and "back") are placed consistently throughout the UI |
| Platform | Apps | ✅ Data input fields appear in groups of five or fewer |
| Platform | Apps | ✅ Data entry errors are clear and appear at the field level |
| Platform | Apps | ✅ Pagination controls enable movement between steps |
| Platform | Form Logic | ✅ Fields are prefilled or autocompleted as much as possible |
| Platform | Form Logic | ✅ Users are not required to wait for long-running server-side actions to complete |
| Platform | Form Logic | ✅ Data operations are carried out once |
| Platform | Form Logic | ✅ Custom components use `cacheable=true` for server-based actions that do not involve data operations |
| Platform | Lightning Web Components (LWC) | ✅ In LWC `@wire` adapters handle all actions not involving data operations |

### Application Complexity Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Streamlined](/docs/architect/well-architected/guide/engaging#streamlined) → [Application Complexity](/docs/architect/well-architected/guide/engaging#application-complexity)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Org | ⚠️ Many apps have "Disable end user personalization of nav items in this app" set to true or permission to customize nav items is disabled org-wide |
| Platform | Org | ⚠️ Apps routinely have more than 10 tabs in the admin-provided default configuration |

### Form Factor Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Streamlined](/docs/architect/well-architected/guide/engaging#streamlined) → [Form Factor](/docs/architect/well-architected/guide/engaging#form-factor)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Aura | ⚠️ Custom Lightning page templates do not uniformly use `design:supportedFormFactors` and `design:supportedFormFactor` in Aura component design files |
| Platform | Aura | ⚠️ Custom Aura components available in App Builder do not consistently declare supported form factors in their respective design files |
| Platform | Aura | ⚠️ In custom Aura components, styling for different form factors is driven purely by hardcoded `px` or `%` values in CSS |
| Platform | Aura | ⚠️ In custom Aura components, width-aware styling is not implemented by Salesforce-provided interfaces. |
| Platform | Desktop | ⚠️ Data input fields and navigation controls do not appear in their intended locations on the screen |
| Platform | Desktop | ⚠️ Interactions with data input fields and navigation controls do not match required behaviors |
| Platform | Desktop | ⚠️ Lack of page activation assignment rules means all users see the same record and app pages |
| Platform | Lightning Web Components (LWC) | ⚠️ In custom LWCs, width-aware styling is not implemented by Salesforce-provided interfaces |
| Platform | Lightning Web Components (LWC) | ⚠️ In custom LWCs, styling for different form factors is driven purely by hardcoded `px` or `%` values in CSS |
| Platform | Lightning Web Components (LWC) | ⚠️ Custom LWCs available in App Builder do not consistently declare supported form factors in their respective design files |
| Platform | Mobile Devices | ⚠️ Data inputs and navigation controls do not render consistently or correctly |
| Platform | Mobile Devices | ⚠️ Users cannot input data easily |
| Platform | Mobile Devices | ⚠️ Compact layouts are not configured at the record level |
| Platform | Mobile Devices | ⚠️ Mobile navigation menus are not distinguishable from desktop navigation |
| Platform | Org | ⚠️ Classic is still active |

### Forms Anti-Pattern

Learn more about Well-Architected [Easy](/docs/architect/well-architected/guide/easy-overview) → [Engaging](/docs/architect/well-architected/guide/engaging) → [Streamlined](/docs/architect/well-architected/guide/engaging#streamlined) → [Forms](/docs/architect/well-architected/guide/engaging#forms)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Apps | ⚠️ Data input fields appear in groups greater than five |
| Platform | Apps | ⚠️ Data input fields are not grouped logically, requiring an extensive amount of context switching by users filling out forms |
| Platform | Apps | ⚠️ Steps and groupings are not clearly defined, making navigation difficult |
| Platform | Apps | ⚠️ Data entry errors only appear when a form's submit button is clicked |
| Platform | Apps | ⚠️ Labels for actions and navigation are confusing to users who aren't familiar with underlying system functionality |
| Platform | Apps | ⚠️ Visual acknowledgement of user actions is not provided |
| Platform | Apps | ⚠️ Navigation buttons appear in arbitrary locations throughout the UI |
| Platform | Apps | ⚠️ Data entry errors contain cryptic information that can only be interpreted by someone who understands the internal workings of the system |
| Platform | Apps | ⚠️ Data submission happens multiple times throughout the data entry process |
| Platform | Form Logic | ⚠️ Fields that could be prefilled or autocompleted require manual entry |
| Platform | Form Logic | ⚠️ Users have to stop working during the submission process to wait for server-side actions to complete |
| Platform | Form Logic | ⚠️ Custom components set `cacheable=false` |
