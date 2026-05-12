---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/compliant.html
date_fetched: 2026-05-01
section: well-architected
page_title: Compliant
---

> Read about our update scheduleshere.

Legal Disclaimer: This document is distributed for informational use only; it does not constitute legal advice and should not be used as such.

## Introduction

A compliant system is designed to adhere to applicable legal and ethical guidelines, with its adherence being both measurable and auditable. This is demonstrated by restricting data access to authorized individuals for intended purposes, adhering to relevant legal regulations, and ensuring equitable access for all authorized users.

Proactive measures are essential for preventing and detecting compliance violations. A reactive approach to regulations and standards can erode customer trust, particularly if changes only occur in response to customer requests or complaints. Such complaints can damage your organization’s brand and reputation, and can lead to revenue losses.

You can build compliance in your Salesforce solutions by focusing on three key habits: legal adherence, ethical standards, and accessibility.

## Legal Adherence

Adhering to legal mandates involves following regional laws and industry regulations. As an architect, once your organization’s legal team or a third-party auditor has determined the specific compliance requirements, your responsibility is to understand these requirements and proactively identify and flag potential compliance issues early in the design process to reduce the risk of fines and lawsuits.

You can improve legal adherence in your Salesforce solutions through data privacy and localization.

### Data Privacy

Data privacy deals with how your solution collects, stores, and processes personally identifiable information (PII), along with the relevant regulations and an individual’s ability to control access to their personal data. Adhering to these regulations may necessitate updates to your [sharing and visibility model](/docs/architect/well-architected/guide/secure#sharing-and-visibility), modifications to metadata configurations to restrict access, implementing field-level encryption, monitoring of logs and events, creating automations to export or delete a customer’s data upon request, and developing policies governing data usage in automations and AI.

Non-compliance with data privacy regulations can lead to substantial fines and lawsuits. Moreover, exposing stakeholder data due to insufficient controls or a security breach can result in lost revenue and eroded customer trust.

Consider the following as you work to ensure adherence to data privacy requirements:

- **Consult regulatory experts**. Work with your legal team or a third-party auditor to evaluate the industry-specific compliance regulations applicable to your business. For instance, healthcare companies must adhere to the Health Insurance Portability and Accountability Act (HIPAA).
- **Classify your data**. Data classification helps project teams understand when the various data elements in your org may or may not be used. It also gives your business the ability to [report](https://help.salesforce.com/s/articleView?id=sf.data_classification_report.htm&type=5) on data management policy compliance. Classify the data in your org by specifying applicable regulations [at the field level](https://help.salesforce.com/s/articleView?id=sf.data_classification_intro.htm&type=5) to capture who the owner is, the sensitivity level, and whether or not the field is currently in use.

During the classification process, it’s important to think about how all of the fields in your data model might be used and not just the ones that seem like they might be sensitive at first glance. In some cases, fields that seem inconsequential can become sensitive if used within the wrong context. For example, postal codes in the United States can be a proxy for race and therefore if used in a predictive mode could unintentionally add bias or cause harm. Names can be used to predict gender, country of origin, race, religion, and even age, as popular names tend to change from generation to generation. Include classifications of all fields and a clear description of how any associated AI functionality will use them in your documentation.

Use tools such as [Data Detect](https://help.salesforce.com/s/articleView?id=sf.einstein_data_detect.htm&type=5) to identify sensitive data within your org. If fields are classified as sensitive or if you know which fields are sensitive, tools like Einstein Content Selection will also identify fields that are [highly correlated](https://help.salesforce.com/s/articleView?language=en_US&type=5&id=sf.mc_pb_manage_einstein_content_selection_attributes_and_bias.htm) and therefore can be proxies for those sensitive fields.

- **Establish best practices for data governance**. Ensure that all relevant documentation is complete, up-to-date, and centrally stored so it’s easily available for all stakeholders. This will add a layer of protection for your organization against legal liability while also maintaining trust with your customers and partners. For example, a data dictionary documents the object and field-level definitions and classifications for all data elements that will be stored in your system, design documents contain details about any automations you’ve created to comply with regulations, and a security matrix outlines what data users have access to. Critically, this comprehensive documentation becomes the authoritative source for Retrieval-Augmented Generation (RAG), directly grounding agentic systems like Agentforce in verified, compliant operational context, thereby preventing inconsistent or hallucinated outputs.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/compliant#legal-adherence-patterns-and-anti-patterns) below shows what proper (and poor) data privacy management looks like within a Salesforce solution. Use these to validate your designs before you build, or identify areas of your system that need to be refactored.

To learn more about Salesforce tools for data privacy, see [Tools Relevant to Be Compliant](/docs/architect/well-architected/guide/compliant#tools-relevant-to-be-compliant).

### Localization

Localization is about adapting a product to align with a specific language, culture, and desired local aesthetic. This also includes adapting to region-specific regulations, such as data residency laws, which can differ significantly across countries and even municipalities. Consequently, your systems might need to satisfy multiple regulatory frameworks, depending on where your customers are located and how your business introduces its products and services to the market.

In addition to variations in data privacy laws, many countries are also enacting data residency laws. At a minimum, data residency laws require all data related to a country’s citizens to be physically stored within that country’s borders. Some laws go further, requiring local storage of all data (including data about products and services) potentially accessible by citizens. In certain cases, regulations require that citizen data be maintained only by other citizens of that country or region.

Non-compliance could lead to large fines and lawsuits. For example, the EU's data protection authorities can impose fines up to €20 million or 4% of global revenue, whichever is higher. In the U.S., the California attorney general's office can seek significant penalties for both intentional and unintentional violations.

Consider the following to better manage localization and data residency requirements:

- **Consult regulatory experts**. Work with your legal team or a third-party auditor to evaluate laws in the regions where your business operates to determine which ones are applicable. Examples include the EU’s General Data Protection Regulation (GDPR) and EU AI Act, and the California Consumer Privacy Act (CCPA).
- **Store data locally**. Ensure that data specific to a region stays in its own, separate org. Use [Hyperforce](https://help.salesforce.com/s/articleView?id=000356459&type=1), Salesforce’s public cloud substrate to host your org in a specific region.
- **Avoid data replication**. Local data storage means that data is stored *at rest* in the country; of course, compliance issues can arise when data is transferred out of the country through standard interfaces. For example, creating and maintaining records locally but replicating them to a data warehouse in another country for reporting will violate data residency laws. If you work for a global business with cross-regional reporting requirements, first aggregate your data within the country where it’s stored, remove all information that could potentially identify the citizens associated with it, and then replicate only the aggregate information. This approach may require you to communicate reporting limitations to your stakeholders so that they know that while more granular data will be available at a country or regional level, only summary data will be available globally.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/compliant#legal-adherence-patterns-and-anti-patterns) below shows what proper (and poor) localization and data residency processes look like within a Salesforce solution. Use these to validate your designs before you build, or identify areas that need to be refactored.

To learn more about Salesforce tools for localization, see [Tools Relevant to Be Compliant](/docs/architect/well-architected/guide/compliant#tools-relevant-to-be-compliant).

### Legal Adherence Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for legal adherence in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-legal-adherence).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Data Privacy** | **In your documentation:**

 - You have an up-to-date data dictionary containing field level names, descriptions, and classifications
            
 - You have an up-to-date security matrix that identifies which users have access to what data
            
 - You have up-to-date design documentation, including standards and diagrams for any automations created to address regulatory requirements | **In your documentation:**

 - A data dictionary does not exist or has not been kept up-to-date
            
 - Sharing and visibility documentation does not exist or has not been kept up-to-date
            
 - Design standards, diagrams, and documentation for automations that address regulatory requirements does not exist or has not been kept up-to-date |
| **In your org:**

 - All objects and fields that contain sensitive information or are subject to data privacy regulations have Compliance Categorization, Data Owner, Data Sensitivity Level, and Field Usage configured | **In your org:**

 - Objects and fields that contain sensitive information or are subject to data privacy regulations are missing configuration for Compliance Categorization, Data Owner, Data Sensitivity Level, or Field Usage |  |
| **Localization** | **In your documentation:**

 - You have an org strategy that outlines where data will be stored and maintained to comply with all applicable data residency requirements
            
 - You have an integration strategy that outlines acceptable scenarios and processes for replicating data across borders
            
 - You have an analytics strategy that outlines the level of granularity reports and dashboards can contain at regional, national, and global levels | **In your documentation:**

 - You do not have an org strategy or your org strategy does not address data localization and residency requirements
            
 - You do not have an integration strategy or your integration strategy does not address data localization and residency requirements
            
 - You do not have an analytics strategy or your analytics strategy does not address data localization and residency requirements |

## Ethical Standards

In business contexts, ethical standards are the guidelines for how companies and individuals conduct themselves from a values-based or moral standpoint. At Salesforce, [our core values](https://trailhead.salesforce.com/content/learn/modules/salesforce-culture-and-values/explore-salesforce-culture-and-values) guide everything we do as a company and as employees. We also have an [ethical use policy](https://www.salesforce.com/company/intentional-innovation/ethical-use-policy/) team that helps to ensure customers are using our software ethically. Our [Acceptable Use Policy (AUP)](https://sfdc.co/AUP) and [AI Acceptable Use Policy (AI AUP)](http://sfdc.co/AI-Policy) are is an extension of our core values, and helps guide our decision-making if questions around usage arise.

Your organization may have an additional set of policies that extend beyond simply complying with local regulations. These policies can take various forms, ranging from adhering to other regions’ regulations, declining to do business with certain organizations or markets, or monitoring employee-customer interactions to prevent discrimination or biased behaviors. To uphold these policies, you may need to update your design standards or system configuration as you would for [legal adherence](/docs/architect/well-architected/guide/compliant#legal-adherence).

To foster greater adherence to ethical standards in your Salesforce solutions, align with company policies and assess your use of artificial intelligence.

### Company Policies

Company policies are guidelines that define how various aspects of the business (including people, processes, and technology) should operate. Customers prefer to do business with organizations they trust. Most company policies are designed to reflect this principle. Customer trust will erode quickly if your systems create user experiences that don’t align with your stated policies.

Effective policies flow naturally from [a culture of ethics](https://www.salesforce.com/blog/new-research-ethical-leadership-business/). Every employee, from engineering and design to data science, marketing, and sales, must be educated on their responsibility for ethical use. In such a culture, employees see clear incentive structures to reward ethical behavior and clear, consistent consequences for unethical behavior.

Consider the following to ensure your organization’s policies are reflected in your designs:

- **Be aware of unintended consequences**. As an architect, it’s your responsibility to anticipate the potential impacts of your solutions and how they will be used. Don’t fall into the trap of only considering or testing for happy paths. Instead, apply your expertise in testing edge cases and evaluating tradeoffs to thoroughly consider the ethical implications of your solutions. Think about everyone that will be affected by the product, especially those who are underrepresented, marginalized, or vulnerable. Evaluate the multitude of ways someone, or something, might interact with your solution and create unintended consequences. Use the [Build With Intention Toolkit](http://sfdc.co/BuildwithIntention) to design with inclusion in mind.
- **Embed ethics into your company's acceptable use policy**. Work with your legal team or a third-party to include ethics in your acceptable use policy to ensure the use of your solutions aligns with your company values. Your documentation should include information about which of your organization’s values and policies are supported by your solutions, whether developed with low-code or pro-code tools. Publish your acceptable use policy to show your commitment to building trust with your employees and customers.
- **Use inclusive language**. Understand the different ways people experience your solution and [refine the language](https://www.salesforce.com/news/stories/salesforce-updates-technical-language-in-ongoing-effort-to-address-implicit-bias/) in your user interface, code, and documentation to more accurately reflect inclusivity. Start by identifying and removing exclusive language first and then commit to understanding the types of habits or practices that can lead to exclusion.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/compliant#ethical-standards-patterns-and-anti-patterns) below shows what proper (and poor) adherence to company policies looks like within a Salesforce solution. Use these to validate your designs before you build, or identify areas in your system that need to be refactored.

To learn more about Salesforce tools for aligning designs with company policies, see [Tools Relevant to Be Compliant](/docs/architect/well-architected/guide/compliant#tools-relevant-to-be-compliant).

### Artificial Intelligence

Artificial intelligence uses computational systems to perform tasks that normally require human intelligence, such as reasoning, perception, and decision-making. The Salesforce platform AI capabilities span predictive, generative, and agentic technologies, offering a comprehensive suite of tools to enhance customer experiences and business operations:

- **Predictive AI** analyzes historical data and forecasts future outcomes, such as sales trends or customer churn. Einstein AI delivers these insights by analyzing patterns in your data to provide recommendations and predict business outcomes.
- **Generative AI** focuses on creating new content by leveraging large language models. Einstein GPT is a core component that works with your CRM data to generate personalized content like emails, chat responses, and customer communications.
- **Agentic AI** takes AI a step further by enabling agents to autonomously reason and act to achieve a specific goal. Agentforce is the platform for building these intelligent agents, which can automate complex business processes like resolving customer cases or optimizing marketing campaigns. These agents can interact with data in real-time via Data 360 and leverage existing workflows and APIs. All of these AI capabilities are secured by the Einstein Trust Layer. which ensures ethical use.

Most of Einstein AI’s core algorithms are not configurable, but for some features, customers may be able to fine-tune the models using their own data as stated in the documentation. Additionally, you can ground AI models in your own CRM, knowledge base articles, and other documents through Retrieval Augmented Grounding (RAG) to make the outputs even more accurate for your organization, customers, and use cases. However, if your underlying data is biased or skewed, your outputs may become biased and inaccurate as well. An example of bias is not including members of a certain race, gender, or ethnicity in your contact list even though your customer base is diverse and includes members of that group. Refer to the Salesforce [Responsible Creation of AI Trailhead module](https://trailhead.salesforce.com/en/content/learn/modules/responsible-creation-of-artificial-intelligence), [Understanding Trusted Agentic AI Trailhead](https://trailhead.salesforce.com/content/learn/modules/trusted-agentic-ai), [AI Ethics Maturity Model](https://www.salesforceairesearch.com/static/ethics/EthicalAIMaturityModel.pdf), Salesforce’s [Trusted AI principles](https://www.salesforceairesearch.com/trusted-ai), [Responsible Generative AI Guidelines](https://www.salesforce.com/news/stories/generative-ai-guidelines/), and [Responsible Agentic AI Guidelines](https://www.salesforce.com/news/stories/responsible-agentic-ai-guidelines/) for more information.

Not accounting for applicable legal regulations and your company’s own ethical standards can lead to biases within your AI, resulting in lawsuits, lost revenue, customer trust issues, and damage to your company’s public image.

Here’s what to consider for the responsible and ethical use of AI:

- **Examine your datasets and documents**. Ensure that your datasets are representative of everyone your AI functionality will impact. This may require user research to understand who they are and confirm that your data accurately represents them all to mitigate any potential biases. It is also critical to review the CRM data, knowledge articles, and any other documentation you ground your models in to ensure that they are up-to-date, accurate, and complete. Grounding your models in loads of data is not helpful, and can result in hallucinations if that data is old, contradictory, or incomplete.
- **Keep a human at the helm**. You don’t want humans to intervene in every individual AI interaction, but instead empower your employees to focus on the high-judgment items that most need their attention. Test your AI systems until you are confident that they can take on more responsibility and monitor the outcomes to ensure they continue to work accurately and effectively. And ensure that your AI systems or agents are instructed to escalate to a human for high-risk use cases and when the AI’s confidence level is low.
- **Prioritize the safety of your model outputs and outcomes**. Conduct bias, explainability, and robustness [assessments](https://www.salesforce.com/news/stories/developing-ethical-ai/), and [ethical red teaming](https://www.salesforce.com/blog/red-teaming-ai/). Prioritize privacy protection through agent responses and actions for any personally identifying information (PII) present in the data used for training and create guardrails to prevent additional harm. If you discover harmful outcomes when testing, add instructions to your system prompts and retest. You may also need to improve the quality or representativeness of the data you are using for Retrieval-Augmented Generation(RAG).
- **Be prepared for regulations**. In addition to ethical concerns with AI, many governments have passed or are passing legislation to regulate the use of AI by organizations that operate within their jurisdictions. This legislation can include the requirement to publish model cards that describe how an AI solution was created and works. Before you implement an artificial intelligence-based solution, be aware of what type of AI-related functionality is or isn’t acceptable in the regions where your systems will be used and make any necessary adjustments to your strategy. You may need to disable certain features in some regions to comply with local regulations; if so, ensure that your systems can continue to operate without those features. Many jurisdictions also require transparency when customers or end users are interacting with AI systems.
- **Monitor your organization’s AI models**. Impacted users should know when an AI has been used and have the opportunity to easily report harm and request remediation. It’s important to note that reporting alone may not be sufficient to determine if your AI functionality is causing harm to users. Continually monitor your models for data drift, changes in fairness/bias scores, accuracy, and robustness. Make sure that you have plans in place to [handle quality alerts](https://help.salesforce.com/s/articleView?id=sf.bi_edd_quality_alert.htm&type=5) and respond quickly when negative impacts are identified.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/compliant#ethical-standards-patterns-and-anti-patterns) below shows what proper (and poor) AI design looks like within a Salesforce solution. Use these to validate your designs before you build, or identify areas of your system that need to be refactored.

To learn more about Salesforce tools for implementing more ethical AI policies, see [Tools Relevant to Be Compliant](/docs/architect/well-architected/guide/compliant#tools-relevant-to-be-compliant).

### Ethical Standards Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for ethical standards in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-ethical-standards).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Company Policies** | **In your design standards:**

 - Standards include clear guidance for areas impacted by company policies | **In your design standards:**

 - Design standards do not exist or do not provide clear guidance about areas that are subject to company policies |
| **In your documentation:**

 - Documentation for configuration and customizations includes references to supported company values | **In your documentation:**

 - Documentation for configuration and customizations does not reference company values or policies |  |
| **In your org:**

 - All objects and fields that are subject to company policy-related compliance have Compliance Categorization, Data Owner, Data Sensitivity Level, and Field Usage configured | **In your org:**

 - Objects and that are subject to company policy-related compliance are missing configuration for Compliance Categorization, Data Owner, Data Sensitivity Level or Field Usage |  |
| **Artificial Intelligence** | **In your design standards:**

 - Policies and approved use cases for AI applications are clear and easy to find
            
 - Ensure the data and documents used for RAG are representative, complete, accurate, and up-to-date. Look for bias, toxic, and other harmful content that could live in your datasets or documentation
            
 - Generative responses always identify data sources used by AI models
            
 - Data sets that can/can not be used for prompt engineering have been documented
            
 - Bots and generative AI responses are clearly identified to users
            
 - Standards for when and how to use disclaimers for generative AI are clearly defined
            
 - Clear requirements for how to document points of human involvement in AI solution designs exist
            
 - Standards for documenting direct and indirect feedback paths in AI solution designs exist
            
 - Points at which AI must be identified for a user are clearly defined
            
 - Keep a human at the helm, especially in regulated or high risk use cases | **In your design standards:**

 - Design standards don't exist or do not include clear policies and approved use cases for AI applications
            
 - Generative responses do not identify data sources used by AI models
            
 - Data sets used for prompt engineering are not documented
            
 - Bots and generative AI responses are not identified to users
            
 - Disclaimers regarding generative responses are missing
            
 - No requirements for documenting points of human involvement in AI solution designs exist
            
 - No standards for documenting direct and indirect feedback paths for AI solution designs exist
            
 - Design standards fail to indicate points at which AI must be identified to users |
| **In your documentation:**

 - Documentation for configuration and customizations involving AI functionality contains a thorough description of all process logic and is stored in a central location that is accessible by legal teams or auditors
            
 - Models that you build or bring to Salesforce are clearly documented, including any applicable data segments
            
 - Conversation logic and agentic conversations are thoroughly documented
            
 - Processes are in place to monitor your organization's AI models for data drift, changes in fairness and bias scores, accuracy, and robustness
            
 - Descriptions are maintained for the training, evaluation, and testing data used for all AI processes
            
 - Descriptions are maintained for any AI-related data cleaning along with bias testing, associated results, and performance/accuracy scores (for example, F1 scores) | **In your documentation:**

 - Documentation for configuration and customizations involving AI functionality is missing, incomplete, or stored in an inaccessible location
            
 - AI models or systems are implemented in your org without documentation of their models
            
 - Agents are implemented in your org without documentation of messages and conversation flow
            
 - AI monitoring processes do not exist or are not documented
            
 - Information about training, evaluation, and testing data used for all AI processes is unclear or unavailable
            
 - Information about AI-related data cleaning, bias testing, and results is unclear or unavailable |  |

## Accessibility

*Accessibility* in technology refers to the usability of systems or solutions for people with different abilities. Designing systems that work for all users, regardless of ability, is a legal mandate in some locations and industries. Beyond legal requirements, building accessible systems helps your organization foster and enhance trust with your stakeholders. For customer-facing applications, this can even increase revenue as customers may opt to use your systems over less accessible alternatives.

Salesforce publishes [Accessibility Conformance Reports (ACRs)](https://www.salesforce.com/company/legal/508_accessibility/), which are industry-standard documents detailing how our software complies with accessibility standards. Most of our UI-based controls, including Lightning Web Components and Experience Cloud Templates, are designed to adhere to these standards. While our baseline accessibility features may be sufficient for many businesses, it's important to review our ACRs and release notes before starting any project. This will help you identify and document any additional accessibility requirements that extend beyond our standards, depending on your product or service's go-to-market approach.

You can improve how accessible your systems are by focusing on two key areas: data entry and navigation.

### Data Entry

Data entry activities happen any time a user needs to input information into a field, form, or another part of a user interface. While keyboards and mice are the most common input methods, some users may rely on speech-to-text or similar devices. Additionally, your users may communicate in different languages.

Solutions not designed with accessibility in mind can exclude individuals with certain disabilities from interacting with them.

Consider the following when designing for accessibility:

- **The language your users prefer**. Depending on where your business operates, you may decide to set a single, standard language for your systems or you may want to offer multilingual capabilities. If displaying text in multiple languages, your design standards should include a list of field labels and other UI elements (like notifications and error messages) requiring translation. Engage a native speaker to review the translations for accuracy and meaning. Use Salesforce [translation features](https://help.salesforce.com/s/articleView?id=sf.workbench_overview.htm&type=5) for real-time metadata and data translations, and thoroughly test all multilingual features.
- **The types of input devices that will be used**. List any tools that may be used for data input beyond a standard keyboard and mouse in your design standards. Include accessibility testing in your test plans and make sure all inputs are tested with multiple types of input devices.
- **The usability of your forms**. Ensure your forms include visible labels, provide helpful error messages, guide the user toward completion, inform the user of their progress, and let them review, confirm, and edit their inputs.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/compliant#accessibility-patterns-and-anti-patterns) below shows what data entry looks like when properly (and poorly) designed for accessibility within a Salesforce solution. Use these to validate your designs before you build, or identify areas in your system that need to be refactored.

To learn more about Salesforce tools for building more accessible data entry, see [Tools Relevant to Be Compliant](/docs/architect/well-architected/guide/compliant#tools-relevant-to-be-compliant).

### Navigation

Navigation involves users moving focus between screens and between fields within a screen. Users may need to navigate through the various UI elements in your system in a variety of ways, including via clicks and keystrokes, while relying on their sight, hearing, and touch. Ensure that your design standards include a list of navigation devices that you plan to support. Implementation teams should refer to this list when testing to make sure that all navigation possibilities are accounted for.

Consider the following questions — and their answers — as you design accessible navigation:

- **How will users navigate your solution?** List any devices that may be used for navigation beyond a standard keyboard and mouse in your design standards.
- **Is your navigation consistent?** Establish design standards for navigation controls to ensure consistency across your entire system. Navigation paths should be similar throughout your entire system. Inconsistent navigation, such as a blue “Next” button in the bottom right of one screen and a green “Next” button in the center of the next, might be a mild annoyance for some users but can render the application unusable for those with disabilities.
- **Do your tests account for accessibility?** Include accessibility testing in your test plans and make sure all navigation flows are tested with multiple types of input devices.
- **Is the keyboard focus consistently visible?** Always visually display the current state of keyboard focus to assist users who rely on a keyboard to navigate.
- **Does your navigation rely on color?** Avoid using color alone to present information or to request an action. Adhere to the [Web Content Accessibility Guidelines (WCAG) 2.0](https://www.w3.org/TR/WCAG20/#visual-audio-contrast) for proper use of color to convey meaning, and apply the right level of contrast.
- **Have your designs been reviewed?** Conduct regular reviews to ensure that your user interface is consistent and easy to comprehend.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/compliant#accessibility-patterns-and-anti-patterns) below shows what navigation looks like when properly (and poorly) designed for accessibility within a Salesforce solution. Use these to validate your designs before you build, or identify areas of your system that need to be refactored.

To learn more about Salesforce tools for building more accessible navigation, see [Tools Relevant to Be Compliant](/docs/architect/well-architected/guide/compliant#tools-relevant-to-be-compliant).

### Accessibility Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for accessibility in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/trusted-accessibility).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Data Entry** | **In your design standards:**

 - All devices that may be used for data input beyond a standard keyboard and mouse are listed
            
 - Text values and their translations into all supported languages are listed | **In your design standards:**

 - Only some, or none, of the devices that may be used for data input beyond a standard keyboard and mouse are listed
            
 - Supported languages are listed along with UI elements to be translated |
| **In your test plans:**

 - Test steps include using multiple types of input devices to enter data
            
 - Test steps include data entry in multiple languages | **In your test plans:**

 - Accessibility testing is not included or testing for accessible data entry is done ad hoc |  |
| **In your org:**

 - Translations for supported languages are stored in Translation Workbench | **In your org:**

 - Translations are stored in custom labels |  |
| **Navigation** | **In your design standards:**

 - All devices that may be used for navigation (not just standard keyboard and mouse) are clearly listed
            
 - UI/UX standards specify the type and style of all navigational controls
            
 - The types of visual cues approved to convey meaning or state are clearly listed, and color is not a primary cue | **In your design standards:**

 - Design standards do not exist or do not account for accessibility requirements for navigational controls
            
 - UI/UX standards for navigation are inconsistent
            
 - Visual cues for meaning or state rely on color or there are no clear lists of visual cues for builders |
| **In your test plans:**

 - Test steps include using multiple types of input devices to navigate
            
 - Test plans include using UI/UX testing to ensure consistent navigational paths | **In your test plans:**

 - Accessibility testing is not included or testing for accessible navigation is done ad hoc |  |

## Tools Relevant to Be Compliant

| Tool | Description | Legal Adherence | Ethical Standards | Accessibility |
| --- | --- | --- | --- | --- |
| [Agentforce Analytics](https://help.salesforce.com/s/articleView?id=ai.copilot_analytics.htm&type=5) | Gain insights into how your agents are performing |  | X |  |
| [Agentforce Testing Center](https://help.salesforce.com/s/articleView?id=ai.agent_testing_center.htm&type=5) | Run up to 10 test jobs with up to 1,000 test cases per test, so you can quickly create and assess multiple scenarios. |  | X |  |
| [Citations](https://help.salesforce.com/s/articleView?id=ai.generative_ai_trust_citations.htm&type=5) | Citations help you identify potential inaccuracies or hallucinations in the generated responses, increasing your confidence in using AI tools. |  | X |  |
| [Consent API](https://developer.salesforce.com/docs/atlas.en-us.236.0.api_rest.meta/api_rest/resources_consent.htm) | Track customer preferences for consent | X |  |  |
| [Consent Event Stream](https://help.salesforce.com/s/articleView?id=sf.consent_event_stream.htm&type=5) | Send notifications for changes to consent or contact info | X |  |  |
| [Consent Management Objects](https://help.salesforce.com/s/articleView?id=sf.consent_mgmt_fields.htm&type=5) | Manage customer privacy and consent preferences | X |  |  |
| [Data Access and Portability](https://help.salesforce.com/s/articleView?id=sf.data_portability.htm&type=5) | Export customer-related data upon request | X |  |  |
| [Data Classification](https://help.salesforce.com/s/articleView?id=sf.data_classification_intro.htm&type=5) | Record key compliance and audit info for object fields | X |  |  |
| [Data 360 Reports](https://help.salesforce.com/s/articleView?id=ai.agent_instruction_adherence_monitor_dc.htm&type=5) | Monitor agent instruction adherence |  | X |  |
| [Data Deletion](https://help.salesforce.com/s/articleView?id=sf.data_deletion.htm&type=5) | Delete data to comply with legal regulations | X |  |  |
| [Data Privacy Preferences](https://help.salesforce.com/s/articleView?id=sf.individuals_store_data_privacy.htm&type=5) | Store customer data privacy preferences | X | X |  |
| [Data Translation](https://help.salesforce.com/s/articleView?id=sf.data_translation.htm&type=5) | Translate data presented to users | X |  | X |
| [Data Detect](https://help.salesforce.com/s/articleView?id=sf.einstein_data_detect.htm&type=5) | Align categories and sensitivity levels to actual data | X |  |  |
| [Data 360 Explorer](https://help.salesforce.com/s/articleView?id=data.c360_a_data_explorer.htm&type=5) | Manage project and object permissions for data scientists | X | X |  |
| [Einstein Data Prism](https://help.salesforce.com/s/articleView?id=ai.generative_ai_prism.htm&type=5) | A grounding solution for generative AI applications within Salesforce, improving the accuracy of AI solutions that use its grounding capabilities |  | X |  |
| [Einstein Trust Layer](https://www.salesforce.com/artificial-intelligence/trusted-ai/) | A collection of features, processes, and policies designed to safeguard data privacy, enhance AI accuracy, and promote responsible use of AI across the Salesforce ecosystem |  | X |  |
| [Enhanced Event Logs](https://help.salesforce.com/s/articleView?id=ai.copilot_setup_enhanced_event_logs.htm&type=5) | Event logs capture the events and user messages in an agent session to review Instruction Adherence, test, and troubleshoot your agent. |  | X |  |
| [Files Connect](https://help.salesforce.com/s/articleView?id=sf.collab_files_connect_parent.htm&type=5) | Browse, search, and share external files from Salesforce | X |  |  |
| [Hyperforce](https://help.salesforce.com/s/articleView?id=000356459&type=1) | Comply with local data storage requirements | X |  |  |
| [Metadata Translation](https://help.salesforce.com/s/articleView?id=sf.workbench_metadata_translation.htm&type=5) | Translate languages to localize applications | X |  | X |
| [Portability API](https://developer.salesforce.com/docs/atlas.en-us.236.0.api_rest.meta/api_rest/resources_portability.htm) | Compile customer data identified in your portability policy | X | X |  |
| [Preference Center](https://help.salesforce.com/s/articleView?id=sf.preference_center_about.htm&type=5) | Gather customer communication preferences | X | X |  |
| [Privacy Center](https://help.salesforce.com/s/articleView?id=sf.privacy_center.htm&type=5) | Satisfy customer requests and data privacy laws | X | X |  |
| [Restriction of Data Processing](https://help.salesforce.com/s/articleView?id=sf.restriction_of_processing.htm&type=5) | Restrict personal data processing methods | X | X |  |
| [Right to Be Forgotten](https://help.salesforce.com/s/articleView?id=sf.rtbf_policies.htm&type=5) | Delete individual customer data upon request | X |  |  |
| [Salesforce Files](https://help.salesforce.com/s/articleView?id=sf.collab_files_overview.htm&type=5) | Share and store files privately | X |  |  |
| [Security Center](https://help.salesforce.com/s/articleView?id=sf.security_center.htm&type=5) | View security and privacy settings across multiple orgs | X |  |  |
| [Shield Platform Encryption](https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/security_pe_overview.htm) | Encrypt data at rest and in transit | X |  |  |
| [Translation Workbench](https://help.salesforce.com/s/articleView?id=sf.workbench.htm&type=5) | Maintain translated values for metadata and data labels | X |  | X |

## Resources Relevant to Be Compliant

| Resource | Description | Legal Adherence | Ethical Standards | Accessibility |
| --- | --- | --- | --- | --- |
| [5 Principles for Responsible AI Design](https://medium.com/p/781b5fd2427) | Design Artificial Intelligence (AI) functionality ethically |  | X |  |
| [Accessibility Basics (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/accessibility-basics?trailmix_creator_id=strailhead&trailmix_slug=prepare-for-your-strategy-designer-credential) | Learn why accessibility is important |  |  | X |
| [Accessibility Conformance Reports (ACRs)](https://www.salesforce.com/company/legal/508_accessibility/) | Understand how Salesforce meets accessibility standards |  |  | X |
| [Accessibility Overview](https://www.lightningdesignsystem.com/2e1ef8501/p/112ac5-accessibility) | Understand accessibility within Salesforce Lightning |  |  | X |
| [AI Ethics Maturity Model](https://www.salesforceairesearch.com/static/ethics/EthicalAIMaturityModel.pdf) | Develop a roadmap to operationalize ethical principles |  | X |  |
| [AI Red Teaming: Testing for Trust](https://www.salesforce.com/blog/red-teaming-ai/) | Find out how Salesforce’s ‘ethical hackers’ develop Responsible AI through red teaming. |  | X |  |
| [Automating the Adversary: Designing a Scalable Framework for Red Teaming AI](https://www.salesforce.com/blog/automated-framework-for-red-teaming-ai/) | Learn how Salesforce automates adversarial prompt generation and response validation, fuzzai helps secure AI interactions while reducing human exposure to harmful content. |  | X |  |
| [Best Practices for Conversation Design](https://help.salesforce.com/s/articleView?id=sf.bots_service_best_practice.htm&type=5) | Follow best practices when designing chatbots |  | X | X |
| [Best Practices for Sustainable Design (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/best-practices-for-sustainable-design?trailmix_creator_id=strailhead&trailmix_slug=prepare-for-your-strategy-designer-credential) | Incorporate sustainability into your designs |  | X |  |
| [Consent Management](https://help.salesforce.com/s/articleView?id=sf.consent_management.htm&type=5) | Track and comply with consent and opt-out requests | X |  |  |
| [Data Policies for Einstein](https://help.salesforce.com/s/articleView?id=sf.aac_manage_data_policies.htm&type=5) | Control data use across Einstein functionality | X | X |  |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization | X | X | X |
| [Ethical Hacking Practices Prove Successful in Building Trusted AI Products](https://www.salesforce.com/blog/red-teaming-ai/) | Learn how Salesforce employs [red teaming practices](https://www.salesforce.com/blog/red-teaming-ai/) to improve the safety of our AI products by testing for malicious use, intentional integrity attacks, benign misuse, and identifying responsible AI issues. |  | X |  |
| [Ethical Leadership and Business](https://www.salesforce.com/content/dam/web/en_us/www/documents/research/salesforce-research-ethical-leadership-and-business.pdf) | Insights on technology, equality, and ethics |  | X |  |
| [Ethical Use Policy](https://www.salesforce.com/company/intentional-innovation/ethical-use-policy/) | Explore Salesforce policy on ethical use of our products and services |  | X |  |
| [Ethics by Design (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/ethics-by-design?trailmix_creator_id=strailhead&trailmix_slug=prepare-for-your-strategy-designer-credential) | Incorporate ethical design into technology development |  | X |  |
| [Explore Salesforce's Culture and Values (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/salesforce-culture-and-values) | Explore Salesforce's core values |  | X | X |
| [Follow Accessible Mobile Design Guidelines](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/mobile_a11y.html) | Follow best practices to make your designs accessible |  | X | X |
| [Get Started with Web Accessibility (Trailhead)](https://trailhead.salesforce.com/en/content/learn/trails/get-started-with-web-accessibility) | Learn the basics of how to make websites and apps accessible |  |  | X |
| [How Salesforce Builds Reproducible Red Teaming Infrastructure](https://www.salesforce.com/blog/how-salesforce-builds-reproducible-red-teaming-infrastructure/) | Four components we recommend when designing, implementing, and executing an adversarial tests |  | X |  |
| [How To Run a Consequence Scanning Workshop](https://medium.com/salesforce-ux/how-to-run-a-consequence-scanning-workshop-4b14792ea987) | Consider all possible outcomes while innovating |  | X |  |
| [Implementing Data Protection and Privacy](https://help.salesforce.com/s/articleView?id=sf.data_protection_and_privacy.htm&type=5) | Evaluate data protection and privacy requirements | X |  |  |
| [Inclusive Design (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/inclusive-design) | Foster innovation with inclusive design principles |  | X | X |
| [KPI Spreadsheet Template](/docs/architect/resources/guide/kpi-spreadsheet-template) | Set Key Performance Indicators (KPIs) for your organization | X |  |  |
| [Legal Information](https://www.salesforce.com/company/legal/) | Explore Salesforce's Legal Information center | X |  |  |
| [LWC Cookie Consent Module](https://developer.salesforce.com/blogs/2021/09/learn-moar-in-winter-22-with-lwc-cookie-consent-module) | Control user cookie access in Experience Cloud sites | X | X |  |
| [Privacy Overview](https://www.salesforce.com/privacy/overview/) | Learn about data privacy by region and industry | X |  |  |
| [Promote Responsible and Ethical Agents](https://trailhead.salesforce.com/content/learn/modules/trusted-agentic-ai/promote-responsible-and-ethical-agents) | Learn how to implement ethical red-teaming and testing strategies and develop guiding principles and standards for your organization. |  | X |  |
| [Responsible Agentic AI Guidelines](https://www.salesforce.com/news/stories/responsible-agentic-ai-guidelines/) |  |  | X |  |
| [Responsible Creation of AI Trailhead module](https://trailhead.salesforce.com/en/content/learn/modules/responsible-creation-of-artificial-intelligence) | Learn how to remove bias from your data and algorithms to create ethical AI systems at your company. |  | X |  |
| [Responsible Generative AI Guidelines](https://www.salesforceairesearch.com/trusted-ai) | We have built on our [Trusted AI Principles](https://www.salesforceairesearch.com/trusted-ai) with a new set of guidelines focused on the responsible development and implementation of generative AI. |  | X |  |
| [Salesforce Compliance Certifications](https://compliance.salesforce.com/) | Review Saleforce's compliance certifications and attestations | X |  |  |
| [Sustainable Design (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/sustainable-design?trailmix_creator_id=strailhead&trailmix_slug=prepare-for-your-strategy-designer-credential) | Strengthen the relationship between business and society |  | X |  |
| [Testing for Web Accessibility (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/testing-for-web-accessibility) | Utilize automated and manual testing to ensure accessibility |  |  | X |
| [Trusted Agentic AI](https://trailhead.salesforce.com/content/learn/modules/trusted-agentic-ai) | Learn how Agentforce uses safeguards and responsible AI principles to create ethical AI. |  | x |  |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you’d like to see next.
