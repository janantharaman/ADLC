---
source_url: https://architect.salesforce.com/docs/architect/well-architected-tools/guide/trusted-ethical-standards.html
date_fetched: 2026-05-01
section: well-architected-tools
page_title: Compliant — Ethical Standards
---

### Artificial Intelligence Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Ethical Standards](/docs/architect/well-architected/guide/compliant#ethical-standards) → [Artificial Intelligence](/docs/architect/well-architected/guide/compliant#artificial-intelligence)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Einstein | Design Standards | ✅ Generative responses always identify data sources used by AI models |
| Einstein | Design Standards | ✅ Data sets that can/can not be used for prompt enginerring have been documented |
| Einstein | Design Standards | ✅ Bots and generative AI responses are clearly identified to users |
| Einstein | Design Standards | ✅ Points at which AI must be identified for a user are clearly defined |
| Einstein | Design Standards | ✅ Standards for when and how to use disclaimers for generative AI are clearly defined |
| Einstein | Design Standards | ✅ Clear requirements for how to document points of human involvement in AI solution designs exist |
| Einstein | Design Standards | ✅ No generative responses are sent directly to end users without points of human involvement |
| Einstein | Design Standards | ✅ Standards for documenting direct and indirect feedback paths in AI solution designs exist |
| Einstein | Design Standards | ✅ Policies and approved use cases for AI applications are clear and easy to find |
| Einstein | Design Standards | ✅ Standards for chatbot messaging and conversation flow have been documented |
| Einstein | Documentation | ✅ Documentation for configuration and customizations involving AI functionality contains a thorough description of all process logic and is stored in a central location that is accessible by legal teams or auditors |
| Einstein | Documentation | ✅ Models that drive predictions and recommendations are clearly documented, including any applicable data segments |
| Einstein | Documentation | ✅ Conversation logic and chatbot messages are thoroughly documented |
| Einstein | Documentation | ✅ Processes are in place to monitor your organization's AI models for data drift, changes in fairness and bias scores, accuracy, and robustness |
| Einstein | Documentation | ✅ Descriptions are maintained for the training, evaluation, and testing data used for all AI processes |
| Einstein | Documentation | ✅ Descriptions are maintained for any AI-related data cleaning along with bias testing, associated results, and performance/accuracy scores (for example, F1 scores) |
| Einstein | Org | ✅ Prompt templates are tested for quality Prompt templates are tested, and the results of those tests document the relevance, completeness, style/tone, factual accuracy, consistency, toxicity & bias of prompt template responses |
| Einstein | Org | ✅ Generative AI is used as an assistant to a human When starting with generative AI, ensure that there is a "human-at-the-helm", who can review the accuracy and utility of responses. |
| Einstein | Org | ✅ AI models use data you trust Context is provided to Gen AI using zero-party (provided directly by the customer) or first-party (gathered based on a customer's interaction with your business) data |

### Company Policies Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Ethical Standards](/docs/architect/well-architected/guide/compliant#ethical-standards) → [Company Policies](/docs/architect/well-architected/guide/compliant#company-policies)

| Where to look?
Product Area | Location | What does good look like?
Pattern |
| --- | --- |
| Platform | Design Standards | ✅ Standards include clear guidance for areas impacted by company policies |
| Platform | Documentation | ✅ Documentation for configuration and customizations includes references to supported company values |
| Platform | Org | ✅ All objects and fields that are subject to company policy-related compliance have Compliance Categorization, Data Owner, Data Sensitivity Level, and Field Usage configured |

### Artificial Intelligence Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Ethical Standards](/docs/architect/well-architected/guide/compliant#ethical-standards) → [Artificial Intelligence](/docs/architect/well-architected/guide/compliant#artificial-intelligence)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Einstein | Design Standards | ⚠️ Generative responses do not identify data sources used by AI models |
| Einstein | Design Standards | ⚠️ Bots and generative AI responses are not identified to users |
| Einstein | Design Standards | ⚠️ Generative responses are sent directly to end users without points of human involvement |
| Einstein | Design Standards | ⚠️ Data sets used for prompt engineering are not documented |
| Einstein | Design Standards | ⚠️ No requirements for documenting points of human involvement in AI solution designs exist |
| Einstein | Design Standards | ⚠️ Design standards fail to indicate points at which AI must be identified to users |
| Einstein | Design Standards | ⚠️ Disclaimers regarding generative responses are missing |
| Einstein | Design Standards | ⚠️ No standards for documenting direct and indirect feedback paths for AI solution designs exist |
| Einstein | Design Standards | ⚠️ Design standards don't exist or do not include clear policies and approved use cases for AI applications |
| Einstein | Design Standards | ⚠️ Clear standards for chatbot messaging and conversation design do not exist (but chatbots are being used) |
| Einstein | Documentation | ⚠️ AI monitoring processes do not exist or are not documented |
| Einstein | Documentation | ⚠️ Documentation for configuration and customizations involving AI functionality is missing, incomplete, or stored in an inaccessible location |
| Einstein | Documentation | ⚠️ Predictions or recommendations are implemented in your org without documentation of their models |
| Einstein | Documentation | ⚠️ Information about training, evaluation, and testing data used for all AI processes is unclear or unavailable |
| Einstein | Documentation | ⚠️ Information about AI-related data cleaning, bias testing, and results is unclear or unavailable |
| Einstein | Documentation | ⚠️ Chatbots are implemented in your org without documentation of messages and conversation flow |
| Einstein | Prompt Templates | ⚠️ AI relies on third-party data Your prompt templates rely solely on third-party data without any zero or first party data |

### Company Policies Anti-Pattern

Learn more about Well-Architected [Trusted](/docs/architect/well-architected/guide/trusted-overview) → [Compliant](/docs/architect/well-architected/guide/compliant) → [Ethical Standards](/docs/architect/well-architected/guide/compliant#ethical-standards) → [Company Policies](/docs/architect/well-architected/guide/compliant#company-policies)

| Where to look?
Product Area | Location | What to avoid?
Anti-Pattern |
| --- | --- |
| Platform | Design Standards | ⚠️ Design standards do not exist or do not provide clear guidance about areas that are subject to company policies |
| Platform | Documentation | ⚠️ Documentation for configuration and customizations does not reference company values or policies |
| Platform | Org | ⚠️ Objects and that are subject to company policy-related compliance are missing configuration for Compliance Categorization, Data Owner, Data Sensitivity Level or Field Usage |
