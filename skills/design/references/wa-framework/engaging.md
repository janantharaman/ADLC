---
source_url: https://architect.salesforce.com/docs/architect/well-architected/guide/engaging.html
date_fetched: 2026-05-01
section: well-architected
page_title: Engaging
---

> Read about our update scheduleshere.

## Introduction

Systems demonstrate engaging behaviors by making it easy for people to access and use apps, making users feel they are getting more high-quality work done, and making people want to use apps in the system.

Delivering engaging behavior matters to the business because it directly correlates to user adoption as well as overall worker and customer satisfaction. Engaging behaviors also help reduce support requests and can help raise the quality of feature requests from users.

One of the challenges of creating engaging behavior is that it is difficult to measure by objective metrics alone. Instead, it is gauged by the subjective experiences of users; users feel that engaging apps provide genuine value. Engaging apps are [accessible](/docs/architect/well-architected/guide/compliant#accessibility), non-intrusive, and easy to understand. They require a minimal amount of onboarding and training. And they use clear methods to proactively prevent user errors.

Another challenge is that engagement goals will often vary with the different types of user interactions in your system. For example, you may have one set of goals for internal users who are managing cases and another for external users who are submitting information through a form on your website. To design engaging systems, you need to carefully consider the type of engagements you’re trying to create, and why users would want to engage before you begin assembling features and pages.

Partnering with user experience (UX) designers will help you make much more effective decisions when it comes to delivering engaging apps. From an architectural perspective, user adoption and retention are crucial components of a healthy system. Engaging architectures reduce the likelihood of data quality issues caused by users hurrying through processes or skipping steps to avoid having to spend time in a system they don’t enjoy using. For external-facing systems, an engaging architecture can increase revenue and customer retention as customers who find your systems easier to work with choose to do more business with your organization.

You can create more engaging apps by focusing on delivering streamlined and helpful experiences.

## Streamlined

Streamlined apps are easy to navigate, present information and data entry tasks clearly, and adapt to fit various form factors. Streamlined apps also feature experience patterns that users have become accustomed to in other commonly used applications. For example, most web browsers present “open in new tab” as the top option when users right-click a link. A streamlined app that contains tabs will follow the same pattern.

The impacts of inefficient app experiences can extend far beyond an individual app. Poor app experiences erode the trust of users. As more kinds of business-critical and customer-facing apps move to digital channels, this can cost companies the loyalty of key stakeholders.

You can better streamline your apps by being intentional in how you approach app complexity, form design, and form factors.

### Application Complexity

Minimizing application complexity means users see only relevant menu items, tabs, and navigation controls. You’ll need to create mappings between user groups, user permissions, and the correct app experience. Use these mappings to understand what app experience to present to a given user and then ensure your app has the logical controls needed to deliver that experience.

Apps that present users with too much complexity can cause a variety of poor experiences:

- Users frequently see unnecessary or irrelevant tabs, navigate to blank screens, and encounter disabled or blocked links.
- Unnecessary or unhelpful instructions like "ignore this tab if your role is X..." appear in training and enablement materials.
- Cluttered navigation menus force users to spend extra time locating the items they need to get work done.

These poor experiences lead to low adoption rates and satisfaction levels.

Consider the following when determining the right level of app complexity:

- Organize menus, tabs, and other navigational controls based on the priority of the work users need to do.
- Avoid introducing new behaviors that a user has to learn solely so they can use your app.
- Don’t remove access to features that enable users to customize aspects of their user interface.
- Use permission sets to provide expanded or reduced navigation options.
- Simplify Lightning page [activation assignments](https://help.salesforce.com/s/articleView?id=sf.lightning_page_getting_into_salesforce1.htm). Minimize the number of active Lightning pages per app. Use dynamic forms, permission sets, and conditional rendering to add items to Lightning pages in your app. Do this instead of maintaining multiple Lightning pages, activated and assigned by profile.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/engaging#streamlined-app-patterns-and-anti-patterns) below shows what proper (and poor) app complexity management looks like in a Salesforce org. You can use these to validate or improve your application designs.

To learn more about Salesforce tools that can help you manage application complexity,see [Tools Relevant to Engaging](/docs/architect/well-architected/guide/engaging#tools-relevant-to-engaging).

### Forms

Streamlined forms organize information into logical sequences, support quick data entry, and minimize required steps. They also allow for [helpful](/docs/architect/well-architected/guide/engaging#helpful) client-side data validation messages and eliminate repeated form submission cycles.

Consider the following when designing forms:

- **Group related fields together**. Group fields related to the same step in a process or data entry task. Eliminate fields that aren’t directly relevant to the task at hand.
- **Put data entry and validation early**. Fields that require users to input data should appear early on your forms. It is a best practice to surface issues with data formatting or missing data at the field-level and as quickly as possible (that is, before a user attempts to navigate to the next step or submit the form). Also, avoid displaying field-level errors before users have had a chance to enter data into the fields.
- **Minimize data input tasks**. Prefill or autocomplete as many fields as possible, to minimize data entry errors and improve efficiency. Only ask users to input data that is essential or critical. Eliminate any data inputs that are not relevant to the business process at hand. Use picklists instead of free form text fields where possible to enforce the selection of valid options and reduce variations of the same answer.
- **Minimize submissions to the server**. Do not have multistep forms submit data to the server multiple times. Ensure all custom [LWC](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.apex_result_caching) or [Aura](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/controllers_server_storable_actions.htm) components use client-side caching to handle navigation or pagination actions. (Salesforce Lightning Experience and the Salesforce mobile app use client-side caching by default.) Design forms so that users submit data to the server only once. Validate user inputs on the client side before forms are submitted. This will minimize unintended user submissions, prevent duplicate or dirty transactions from consuming bandwidth on the back end, and help you design for better [data handling](/docs/architect/well-architected/guide/automated#data-handling).
- **Manage form state**. Client-side caching not only helps with behaviors like navigation and pagination, it also helps minimize data loss from intermittent connectivity issues. Effectively managing state also means apps can appropriately orchestrate data submission to the server and prevent duplicate transactions, along with presenting relevant and timely messages to users based on the status of server-side actions. Streamlined forms submit data operations only once and do not require users to wait for long-running operations on the server to finish.
- **Follow accessibility standards**. To maximize the audience for your apps and help ensure they are inclusive of all your customers, enforce standards for [accessibility](/docs/architect/well-architected/guide/compliant#accessibility) in your form designs.

Streamlined forms help increase [data integrity](/docs/architect/well-architected/guide/automated#data-integrity) in your apps and how [helpful](/docs/architect/well-architected/guide/engaging#helpful) your apps feel to users. They can also reduce support tickets and requests, as users are better able to address errors and clearly understand the state of their form submissions. Further, streamlined forms enable fast and efficient data entry, and ensure that users won’t have to wait for longer-running processes to complete in order to carry out further work.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/engaging#streamlined-app-patterns-and-anti-patterns) below shows what proper (and poor) form design looks like in a Salesforce org. You can use these to validate or improve your form designs.

To learn more about Salesforce tools that can help you build more streamlined forms, see [Tools Relevant to Engaging](/docs/architect/well-architected/guide/engaging#tools-relevant-to-engaging). For more specific guidance on choosing the right form tool for your use case, check out the [Architect’s Decision Guide to Building Forms with Salesforce](/docs/architect/decision-guides/guide/build-forms#key-takeaways).

### Form Factor

Engaging apps adapt gracefully to different devices and interaction types, or form factors. Depending on device type, different kinds of user interactions will be easier (or more difficult), and the readability for forms and fields will change. Keep in mind that in addition to screen dimensions, form factor also refers to how your users interact with the screen. An increasing number of devices now have touch screens and some users may also use special devices for [accessibility](/docs/architect/well-architected/guide/compliant#accessibility). Be sure to take these factors into consideration when designing forms.

Failing to account for form factor variations can lead to a variety of issues, including:

- Poor data quality
- Unusable app interfaces
- More troubleshooting or “order on behalf of” sessions for support agents
- Poor user adoption, low numbers of active users, and high rates of app “abandon”

To design for interoperability across form factors in your Salesforce apps, consider the following:

- **Identify supported form factors for every app**.
- **Identify input methods and the accessibility needs of your users**. See [Accessibility](/docs/architect/well-architected/guide/compliant#accessibility) for more information.
- **Use standard functionality to provide adaptive experiences across devices whenever possible**.

Lightning Page templates provided by Salesforce support different form factors by default. If you choose to develop custom Lightning page templates with Aura, developers will need to incorporate form factor information into the component design file.
Standard page components provided by Salesforce handle rendering across supported form factors for you. If you create custom components with LWC or Aura, developers will need to handle width awareness (there are implementation differences between Aura and LWC) and declare form factor support within the design file of their components.
- **Follow the guidance for streamlined forms on all devices**.
- **Create test plans (and good tests) for key form factors**. Ideally, you would test for all devices and form factors for all of your apps. However, setting up the correct devices (or device simulators) for form factor tests can be a significant investment. If you know that a certain app or set of apps will have a significant set of users on mobile or tablets, prioritize accurate testing for those apps on mobile and tablet form factors.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/engaging#streamlined-app-patterns-and-anti-patterns) below shows what proper (and poor) form factor awareness looks like in a Salesforce org. You can use these to validate your designs before you build, or identify pages that need to be refactored.

To learn more about Salesforce tools for effective form factor design see [Tools Relevant to Engaging](/docs/architect/well-architected/guide/engaging#tools-relevant-to-engaging).

### Streamlined App Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for streamlined apps in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-streamlined).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **App Complexity** | **In your org:**

 - Apps have fewer than 10 tabs in the admin-provided default configuration
            
 - No apps have "Disable end user personalization of nav items in this app" set to true | **In your org:**

 - Apps routinely have more than 10 tabs in the admin-provided default configuration
            
 - Many apps have "Disable end user personalization of nav items in this app" set to true or permission to customize nav items is disabled org-wide |
| **Forms** | **In your apps:**

 - Fields follow logical groupings
 - Data input fields appear together, in groups of five or fewer
            
 - Data entry errors are clear and appear at the field level, before users navigate away or submit data
            
 - Pagination controls enable movement between steps
 - Data submission happens once
            
 - Labels for actions and navigation are clear
            
 - Timely and visual feedback is provided to acknowledge user actions such as button clicks
            
 - Navigation buttons (for example, "go", "next", and "back") are placed consistently throughout the UI | **In your apps:**

 - Data input fields are not grouped logically, requiring an extensive amount of context switching by users filling out forms
            
 - Data entry errors contain cryptic information that can only be interpreted by someone who understands the internal workings of the system
            
 - Data entry errors only appear when a form's submit button is clicked
            
 - Steps and groupings are not clearly defined, making navigation difficult
            
 - Data submission happens multiple times throughout the data entry process
            
 - Labels for actions and navigation are confusing to users who aren't familiar with underlying system functionality
            
 - Visual acknowledgement of user actions is not provided
            
 - Navigation buttons appear in arbitrary locations throughout the UI |
| **In your form logic:**

 - Fields are prefilled or autocompleted as much as possible
            
 - Users are not required to wait for long-running server-side actions to complete
            
 - Custom components use `cacheable=true` for server-based actions that do not involve data operations
            
 - Data operations are carried out once
            
 - In LWC `@wire` adapters handle all actions not involving data operations | **In your form logic:**

 - Fields that could be prefilled or autocompleted require manual entry
            
 - Users have to stop working during the submission process to wait for server-side actions to complete
            
 - Custom components set `cacheable=false` |  |
| **Form Factor** | **In your org:**

 - Salesforce-provided Lightning page templates are used for all or most pages
            
 - Custom Lightning page templates use `design:supportedFormFactors` and `design:supportedFormFactor` in Aura component design files
            
 - Custom LWC or Aura components available in App Builder declare supported form factors in their respective design files and implement width-aware styling patterns | **In your org:**

 - Classic is still active
            
 - Custom Lightning page templates do not uniformly use `design:supportedFormFactors` and `design:supportedFormFactor` in Aura component design files
            
 - Custom LWC or Aura components available in App Builder do not consistently declare supported form factors in their respective design files
            
 - In custom LWC or Aura components, width-aware styling is not implemented by Salesforce-provided interfaces
            
 - In custom LWC or Aura components, styling for different form factors is driven purely by hardcoded `px` or `%` values in CSS |
| **On desktop:**

 - Data input fields and navigation controls fit on the screen and can be interacted with as intended
            
 - Record and app pages appear correctly, based on page activation assignment rules | **On desktop:**

 - Data input fields and navigation controls do not appear in their intended locations on the screen
            
 - Interactions with data input fields and navigation controls do not match required behaviors
            
 - Lack of page activation assignment rules means all users see the same record and app pages |  |
| **On mobile and tablets:**

 - Data inputs and navigation controls appear correctly
            
 - Users can input data easily
            
 - Mobile navigation menus, optimized for smaller form factors, appear
            
 - Compact layouts appear at the record level | **On mobile and tablets:**

 - Data inputs and navigation controls do not render consistently or correctly
            
 - Users cannot input data easily
            
 - Mobile navigation menus are not distinguishable from desktop navigation
            
 - Compact layouts are not configured at the record level |  |

## Helpful

Helpful applications enable users to feel more empowered and effective, with fewer distractions or interruptions.

Helpful applications help maintain [data integrity](/docs/architect/well-architected/guide/automated#data-integrity) by mitigating manual errors and providing feedback to users when and where they need it. They help users understand what actions they need to focus on now and next, and provide relevant information to help users solve their own problems faster. They provide a clear link between a user’s actions and meaningful impact or achievements.

You can build more helpful applications with three key habits: notification and messages, in-app guidance, and recognition and rewards.

### Notifications and Messages

Notifications and messages help users stay informed.

A well-designed notification and messaging system can increase engagement and productivity by providing users with the information they need to make critical decisions in a timely manner. A poorly designed notification and messaging system — one that presents messages that are neither relevant nor timely — will have the opposite effect. Internal users will quickly disable or ignore notifications, causing them to miss out on legitimate messages that may affect essential business processes. Customers or other external users who grow tired of meaningless notifications may decide to stop using your systems altogether.

When deciding how apps will handle sending notifications and messages to users, consider the following:

- **For errors, use notifications and messages as a last resort**. Design the [error handling](/docs/architect/well-architected/guide/automated#error-handling) in your system with back-end processing that can correct certain types of errors without human intervention. Send users only messages about critical errors that will prevent them from completing tasks. Similarly, send business users only error messages when there is some corrective action that they can (and need to) take themselves. Additional error messages or details can be made available via reports and/or sent to technical support staff using async methods for further follow-up.
- **Choose message types based on relevance, urgency, and timeliness**. Different types of messages have different levels of blocking or interruptive behavior. Notices are a “blocking” type of message, as they require users to acknowledge them before being able to continue their work. As with error messages, notices should be used sparingly. Toast notifications are [non-blocking](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/use_toast), can have different persistence behaviors, and support different kinds of message use cases. The least obtrusive messages are [in-app notifications](https://help.salesforce.com/s/articleView?id=sf.notif_builder.htm&type=5) or emails. These are best used to deliver information that users can deal with when and as they choose.
- **Consider what needs to happen next**. While some notifications are informational (such as success messages), others may require users to take some type of action. When designing notifications, make sure to consider not just the notification itself, but any additional information that a user might need to take action. Include clear instructions or links to where users can find additional information or complete follow-up steps in all actionable notifications.
- **Focus on readability**. Make sure that you clearly communicate each notification’s purpose and the next steps a user needs to take in response. Messages should be understandable to business users who aren’t familiar with the inner-workings of the underlying systems. When creating messages, follow [accessibility standards](/docs/architect/well-architected/guide/compliant#accessibility) and ensure they are localized to support users in the regions where they may appear.

Include patterns for when to use notifications or different types of errors in your [design standards](/docs/architect/well-architected/guide/intentional#design-standards) to help ensure app builders follow consistent practices.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/engaging#helpful-app-patterns-and-anti-patterns) below shows what proper (and poor) notifications and messaging looks like in a Salesforce org. You can use these to validate your designs before you build, or identify usages that need to be refactored.

To learn more about Salesforce tools for notifications and messaging, see [Tools Relevant to Engaging](/docs/architect/well-architected/guide/engaging#tools-relevant-to-engaging).

### In-App Guidance

In-app guidance can be a powerful way to demystify complex workflows (though you should make sure you’ve [optimized](/docs/architect/well-architected/guide/automated#process-design) them first) or help onboard new staff. It can be a great way to introduce process changes, highlight new features, or distribute training in an automated and scalable way. If it is not carefully implemented, however, in-app guidance can be overused. Frequent popups or alerts can create a tremendous amount of noise and interruption for users, leading to lost productivity. In-app guidance can also be underused, resulting in more cumbersome release and change management processes (especially for simple features). Ultimately, both overuse and underuse of in-app guidance lead to a number of issues that pose risks to the business, including:

- Lower data integrity
- Increased user errors
- Higher user frustration levels and lower user satisfaction
- Lower user productivity

Keep in mind that you may want to use in-app guidance differently in different scenarios, as a user’s mindset will dictate how much guidance is “too much” versus “not enough”. Users who are being introduced to a new system for the first time will likely require more frequent messaging than users who are simply learning about a new feature in a system they’re already familiar with.

Here are some keys to creating effective in-app guidance:

- **Develop design standards**. It’s important to remember that overexposure to in-app guidance can cause users to begin to routinely dismiss or ignore messages. At this point, in-app guidance becomes an annoyance, rather than a resource. Define [design standards](/docs/architect/well-architected/guide/intentional#design-standards) to make it clear when to use prompts, walkthroughs, field-level help text, validation messages, paths, screen flows, and so on.
- **Create a prioritization system for guidance implementations**. Not every use case for in-app guidance should be implemented. Instead, consider the following questions to prioritize. Where can you simply use better field names, more explicit labels on buttons, better [form design](/docs/architect/well-architected/guide/engaging#forms), and [process optimization](/docs/architect/well-architected/guide/automated#process-design) to create more intuitive workflows? Where can you add more helpful text or links to a path? What [business cost impact](/docs/architect/resources/guide/kpi-spreadsheet-template) will in-app guidance have? How frequently do you want to deliver messages to your users? Also, make sure any implementations are included on your [roadmap](/docs/architect/well-architected/guide/intentional#roadmapping), so all stakeholders have visibility.
- **Map users to active (and proposed) in-app guidance**. Mapping users to in-app guidance will help you identify and prevent “helpfulness overload” due to too much in-app guidance appearing for a user. Often this is the result of siloed development, as teams think too narrowly about their particular use case. Maintaining a holistic view of what users will be exposed to is especially critical for large orgs. Including guidance implementations on your roadmap can also help.
- **Gather and use feedback to improve**. Review data on in-app guidance usage, and use it to judge the efficacy of in-app guidance deployments. Make sure to provide ways for users to also give open-ended feedback to help guidance builders.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/engaging#helpful-app-patterns-and-anti-patterns) below shows what proper (and poor) in-app guidance looks like in a Salesforce org. You can use these to validate designs before you build, and identify implementations that need to be refactored.

To learn more about Salesforce tools for in-app guidance, see [Tools Relevant to Engaging](/docs/architect/well-architected/guide/engaging#tools-relevant-to-engaging).

### Recognition and Rewards

Building recognition and rewards into an app helps the individuals using that app feel more connected to the impact of their work and better understand the value of their contributions, productivity, and performance. It is also a powerful way to unlock loyalty and engagement.

Not designing for recognition or rewarding app experiences can contribute to a variety of problems, including:

- Users who struggle to understand their progress or velocity
- Confusion about progress to goals or unfinished work
- More unproductive users, who don’t see a connection between their tasks and the “bigger picture”
- Management time wasted on manual, low-level goal reporting

Rewarding app experiences can be difficult to design and deliver, because they depend on company culture, policies, and standards as well as the context and preferences of individual users. Features that may help desktop users feel moments of delight or appreciation may become an irritation to a user on mobile or a user trying to work from a noisy, busy home office. People using an app to work with information that is private or highly sensitive may not appreciate communication about milestones in the form of confetti celebrations or badges. A distributed sales team, in contrast, may see such gamification as an appropriately rewarding app experience. Ultimately, the implementation patterns you choose may be best determined by working with user experience (UX) designers on a team.

When it comes to architecture, it’s important to identify how and where apps can implement features that help users feel recognized and rewarded. It’s also key to understand how and where these features could make apps less [reusable](/docs/architect/well-architected/guide/composable) or take away from delivering [real business value](/docs/architect/well-architected/guide/automated#business-value).

Here are some questions to consider when evaluating recognition and rewards in Salesforce apps:

- **How and where can users see their own progress, as well as overall team stats?** Reports are important, but they often contain summary data that can miss the context of day-to-day work. You can use a tool such as Lightning App builder to embed charts or dashboards on record screens within the context of an app, helping users understand their impact or progress as they go about their everyday tasks.
- **How should users be recognized?** This may vary by team or individual preferences. In some cases, supervisors may want to see messages about user progress so they can be shared with a larger group. Recognition can also be an added perk to help with employee morale. And in other cases, users may simply prefer to be the only ones notified about their progress on a certain task or project.

The list of [patterns and anti-patterns](/docs/architect/well-architected/guide/engaging#helpful-app-patterns-and-anti-patterns) below shows what proper (and poor) recognition and rewards looks like in a Salesforce org. You can use these to validate designs before you build, and identify implementations that need to be refactored.

To learn more about Salesforce tools for recognition and rewards, see [Tools Relevant to Engaging](/docs/architect/well-architected/guide/engaging#tools-relevant-to-engaging).

### Helpful App Patterns and Anti-Patterns

The following table shows a selection of patterns to look for (or build) in your org and anti-patterns to avoid or target for remediation.

✨ Discover more patterns for helpful apps in the [Pattern & Anti-Pattern Explorer](/docs/architect/well-architected-tools/guide/easy-helpful).

|  | Patterns | Anti-Patterns |
| --- | --- | --- |
| **Notifications and Messages** | **Your design standards include:**

 - Approved use cases for notifications, toasts, and notices
                
 - Design patterns for toast variants and notifications
                
 - Design patterns for error messaging | If design standards are defined at all, they do not address errors and notifications |
| **In your org:**

 - Notifications are the predominant messaging format
                
 - Toast messages use variants
                
 - Toast messages with `mode` set to `sticky` do not exist
                
 - Notices are used rarely, if at all
                
 - Generative responses always identify data sources used
                
 - Bots clearly identify themselves before the first interaction with users
                
 - Disclaimers for risks associated with generative AI appear to users before first interaction
                
 - AI disclaimers are in clear and understandable language for users | **In your org:**

 - Emails are the predominant messaging format
                
 - There is no consistent approach to message types
                
 - Toast messages do not consistently use variants
                
 - Toast messages with `mode` set to `sticky` exist
                
 - Notices are used ad hoc
                
 - Generative responses do not identify data sources used
                
 - Bots do not clearly identify themselves before the first interaction with users
                
 - No disclaimers for generative AI risks appears to users
                
 - AI disclaimers are not in clear and understandable language for users |  |
| **In your apps:**

 - No generative responses are sent directly to end users without points of human involvement | **In your apps:**

 - Generative responses are sent directly to end users without points of human involvement |  |
| Also see: [Error Handling](../easy/automated#error-handling) |  |  |
| **In-App Guidance** | **Your design standards and documentation include:**

 - Approved use cases for in-app guidance
                
 - Design patterns for prompts and walkthroughs
                
 - A clear matrix of users, apps, and active in-app guidance | If design standards and documentation exist, they:
                
 - Do not address in-app guidance
                
 - Do not include a clear matrix showing users, apps, active in-app guidance |
| **In your org:**

 - The setting for "Delay Between In-App Guidance" uses the default value or a custom value that is *longer* than the default (24-hour) period provided by Salesforce
                
 - No apps have more than one active walkthrough
                
 - No walkthroughs have a "Times to show" setting that is higher than 10
                
 - No prompts are activated for "Any page, any app" or "This page, any app" | **In your org:**

 - The setting for "Delay Between In-App Guidance" is set to a period that is shorter than the default (24-hour) period provided by Salesforce
                
 - Apps have more than one active walkthrough
                
 - Many walkthroughs have a "Times to show" setting that is higher than 10 (and some have the maximum value of 30)
                
 - Prompts are activated ad hoc, many with the "Any page, any app" or "This page, any app" setting |  |
| **Recognition and Rewards** | **In your org:**

 - Apps use embedded analytics to show users relevant goal progress and productivity stats
                
 - Path celebrations are enabled only with user consent
                
 - Notifications and messaging include user recognition, and reflect user preferences in the design of who is notified and what triggers notifications | **In your org:**

 - Analytics related to goal progress and productivity stats are only available in reports or manager dashboards
                
 - Path celebrations are enabled without checking for user consent
                
 - Notifications and messaging do not include any kind of user recognition or don't reflect the preferences of users and feel noisy or gimmicky |

## Tools Relevant to Engaging

| Tool | Description | Streamlined | Helpful |
| --- | --- | --- | --- |
| [Activate Your Lightning App Page](https://help.salesforce.com/s/articleView?id=sf.lightning_page_getting_into_salesforce1.htm&type=5) | Manage page availability, naming, visibility and positioning | X |  |
| [Adoption Dashboards](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000004gHhLEAU) | Review login history, feature adoption, and productivity | X | X |
| [Alert](https://www.lightningdesignsystem.com/components/alert/) | Persist alerts over sessions and display them without user initiation |  | X |
| [Client-side Caching of Apex Method Results](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.apex_result_caching) | Evaluate performance with cached client-side data | X |  |
| [Dynamic Forms](https://help.salesforce.com/s/articleView?id=sf.dynamic_forms_overview.htm&type=5) | Only display required fields and page sections to users | X |  |
| [Engagement Insights](https://help.salesforce.com/s/articleView?id=sf.networks_insights_enable.htm&type=5) | Monitor recent user activity and take action as needed | X | X |
| [In-App Guidance ](https://help.salesforce.com/s/articleView?id=sf.customhelp_lexguid.htm&type=5) | Utilize prompts and walkthroughs for training and onboarding |  | X |
| [Learning Paths](https://help.salesforce.com/s/articleView?id=sf.customhelp_lex_learning_intro.htm&type=5) | Personalize user learning experiences |  | X |
| [Lightning App Builder](https://help.salesforce.com/s/articleView?id=sf.lightning_app_builder_overview.htm&type=5) | Create custom mobile and Lightning pages without code | X |  |
| [Lightning Data Service](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.data_ui_api) | Cache and share data across components | X |  |
| [Lightning Design System Validator for VS Code](https://www.lightningdesignsystem.com/tools/validator/) | Validate markup against SLDS guidelines | X | X |
| [Lightning Page Templates](https://help.salesforce.com/s/articleView?id=sf.lightning_page_templates.htm&type=5) | Build Lightning Pages for different form factors | X |  |
| [Lookup Filters](https://help.salesforce.com/s/articleView?id=sf.fields_lookup_filters.htm&type=5) | Filter values for lookup, master-detail and hierarchical relationships | X |  |
| [Manage Multiple Currencies](https://help.salesforce.com/s/articleView?id=sf.admin_currency.htm&type=5) | Use multiple currencies in transactions |  | X |
| [Messaging ](https://help.salesforce.com/s/articleView?id=livemessage_intro.htm&language=en_US&type=5) | Send SMS, Facebook Messenger or WhatsApp messages |  | X |
| [Mobile Publisher](https://help.salesforce.com/s/articleView?id=s1_branded_apps.htm&language=en_US) | Create mobile versions of Lightning apps and Experience Cloud sites | X |  |
| [Mobile-Ready Components](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.mobile) | Build components that perform well across mobile experiences | X |  |
| [Multilingual Sites](https://help.salesforce.com/s/articleView?id=sf.siteforce_languages_overview.htm&type=5) | Create different language versions of your site | X | X |
| [Notification Builder](https://help.salesforce.com/s/articleView?id=sf.notif_builder.htm&type=5) | Create custom notifications to present information |  | X |
| [Path](https://help.salesforce.com/s/articleView?id=sf.path_overview.htm&type=5) | Guide users through business processes and celebrate success | X | X |
| [Platform Cache](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_cache_namespace_overview.htm) | Improve performance and reliability when caching data | X |  |
| [Preview Mobile App Pages in Lightning App Builder](https://help.salesforce.com/s/articleView?id=sf.lightning_app_builder_mobile_guidance.htm&type=5) | Preview record and app pages on a mobile device | X |  |
| [Prompt](https://www.lightningdesignsystem.com/components/prompt/) | Alert users of system-related issues and updates |  | X |
| [Recognition Badges](https://help.salesforce.com/s/articleView?id=networks_recog_badges.htm&type=5&language=en_US) | Acknowledge and celebrate user accomplishments |  | X |
| [Recognition with WDC](https://help.salesforce.com/s/articleView?id=sf.workcom_overview.htm&type=5) | Endorse skills and give thanks |  | X |
| [Record Types](https://help.salesforce.com/s/articleView?id=customize_recordtype.htm&type=5&language=en_US) | Personalize business processes, picklist values, and page layouts | X | X |
| [Reputation Overview](https://help.salesforce.com/s/articleView?id=networks_reputation_overview.htm&type=5&language=en_US) | Recognize participation and knowledge sharing |  | X |
| [Restriction Rules](https://help.salesforce.com/apex/HTViewHelpDoc?id=sf.security_restriction_rule.htm&language=en_US) | Prevent users from accessing records that can contain unnecessary data | X |  |
| [Standard Page Components](https://help.salesforce.com/s/articleView?id=sf.lightning_page_components.htm&type=5) | Understand the standard Salesforce Lightning components | X |  |
| [Translations](https://help.salesforce.com/s/articleView?id=workbench_overview.htm&type=5&language=en_US) | Manage translations for global users | X | X |
| [Validation Rules](https://help.salesforce.com/s/articleView?id=sf.fields_about_field_validation.htm&type=5) | Verify that data meets specified standards prior to saving | X |  |

## Resources Relevant to Engaging

| Resource | Description | Streamlined | Helpful |
| --- | --- | --- | --- |
| [Architect's Guide to Building Forms](/docs/architect/decision-guides/guide/build-forms) | Evaluate form design considerations and select the best tool | X |  |
| [Configure Your Component for Different Form Factors](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/use_config_form_factors) | Configure components to render in desktops and phones | X |  |
| [Customize Help Content](https://help.salesforce.com/s/articleView?id=customhelp_about.htm&type=5&language=en_US) | Tailor help content to your unique implementation |  | X |
| [Default Field Values](https://help.salesforce.com/s/articleView?id=sf.fields_defining_default_values.htm&type=5) | Define default, dynamic, or static field values | X |  |
| [Design Guidelines](https://www.lightningdesignsystem.com/guidelines/overview/) | Create user interfaces consistent with best practices | X | X |
| [Design Standards Template](/docs/architect/resources/guide/design-standards-template) | Create design standards for your organization | X | X |
| [Design Testing Skills (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/ux-designer-certification-prep/refresh-your-design-testing-skills) | Plan methods for validating and testing a designs | X | X |
| [In-App Feedback Guidelines](https://www.lightningdesignsystem.com/guidelines/in-app-feedback/overview/) | Review guidelines to collect feedback from within your system | X | X |
| [Lightning Design System Android Static Library](https://github.com/salesforce-ux/design-system-android) | Build native Android apps with the look and feel of Lightning pages | X |  |
| [Lightning Design System iOS Static Library](https://github.com/salesforce-ux/design-system-ios) | Build native iOS apps with the look and feel of Lightning pages | X |  |
| [Messaging Guidelines](https://www.lightningdesignsystem.com/guidelines/messaging/overview/) | Communicate relevant information and create moments of delight |  | X |
| [Messaging Types](https://www.lightningdesignsystem.com/guidelines/messaging/types/) | Understand the different messaging types based on user interaction |  | X |
| [Navigation Guidelines](https://www.lightningdesignsystem.com/guidelines/navigation/) | Help users move between pages and situate themselves in an app | X |  |
| [Testing for Web Accessibility (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/testing-for-web-accessibility) | Utilize automated and manual tests to ensure accessibility | X | X |
| [User Engagement Guidelines](https://www.lightningdesignsystem.com/guidelines/user-engagement/overview/) | Review guidelines for onboarding, adoption, assistance, and learning | X | X |

## Tell us what you think

Help us keep Salesforce Well-Architected relevant to you; take our [survey](https://sfdc.co/bxNtvh) to provide feedback on this content and tell us what you’d like to see next.
