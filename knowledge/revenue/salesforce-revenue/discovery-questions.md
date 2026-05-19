---
source: RCA Discovery Questions (Revenue Cloud Delivery Excellence Practice) + Spring '25 RCB Hands On Exercises + RCB Implementation Best Practices
cloud: Revenue Cloud Advanced (RCA)
section: discovery-questions
last-updated: 2026-05-10
---

# Revenue Cloud — Discovery Questions

This file contains the official RCA discovery question bank from the Revenue Cloud Delivery Excellence Practice. Use these questions to drive structured discovery sessions with the customer. Each section maps to a functional area of Revenue Cloud Advanced.

**Expected outputs per section are noted — leave each discovery session with these outputs in hand.**

---

## How to Use

- Run all applicable sections based on the engagement scope
- Record customer responses in `engagements/{customer}/discovery.md`
- Not every question applies to every customer — use judgment, but never skip a section entirely
- If a customer's answer reveals unusual complexity, flag it in `workflow-memory.md` immediately

---

## 1. Products — Product Catalog Management (PCM) & Product Discovery

**Expected output:** Volume of products, where products will live, how complex bundles are structured, a sample product list and categorization. You should leave with enough to start building the product catalog in RCA. Call out any limits around bundle size or catalog size. Drive customers to simplify the catalog using Attributes.

### Catalog & Storage
- What are the biggest challenges you face in your product catalog management process today?
- How many products are in your product catalog?
- Are the products in Salesforce today?
  - If no: Where is your product information currently stored? How regularly is it updated?
  - Will Salesforce be the Product Master? If not, where are the products stored?
  - If stored externally: how are they kept in sync or entered into Salesforce?

### Product Types & Subscription Model
- How are your products and services sold? (One-Time, Subscription, Evergreen)
- What products are one-time vs. subscription?
- How are subscriptions sold?
  - License subscriptions without equipment/assets
  - License subscriptions with equipment/assets
  - Usage-based, consumption, or metered
- Do you sell Fixed Fee or Percent of Total products?
- What are default subscription terms? (e.g., 12/24/36 months, evergreen)
  - Termed annual/multi-year subscriptions
  - Un-termed / Good until cancelled / Evergreen — annual
  - Un-termed / Good until cancelled / Evergreen — month-to-month
  - Do any subscription-based products have contracts that renew automatically?
  - If renewed, is it the same SKU or a new SKU?
- Do you currently have ramp deals (different pricing year over year)?

### Product Discovery & Search
- What are the biggest challenges you face in your product discovery process today?
- How do users typically search for products when building a quote or order? (keyword search, categories, SKU lookup)
- What key attributes do users need to filter by? (product family, availability, region, price, compatibility)
- Do users need to search across multiple catalogs or business units?
- Do you have seasonal, region-specific, or customer-specific product variations?
- How do you handle out-of-stock or restricted products? (hide, show warnings, suggest alternatives)
- Can all products be sold by all sales persons?
- Should the system suggest compatible products, upsells, or cross-sells based on selections?
- How many Product Families or Product Lines does the business offer?

### Guided Selling
- Do you currently use any guided selling or recommendation logic?
- What questions are asked to drive option selection?
- What is the output of guided selling — create Quote/Order, or just filter products?

### Product Creation & Governance
- What is the biggest pain point in new product creation?
- Who manages product creation?
- Is there an approval process for new products?
- How often are products updated?
- Do you have images available for all product offerings?
- Can you provide an export of your current product catalog with as much detail as possible?

---

## 2. Product Configuration & Bundling

**Expected output:** Bundle structure, complexity, and size. Constraint rules. Configuration attribute requirements.

- Do you have any pre-packaged/pre-configured offerings?
- What are the biggest challenges in your product configuration and bundling process today?
- What type of bundling or product bucketing is needed?
  - How many groupings are needed within the bundle?
  - What are the bundled products/options?
  - Can any bundled products be sold à la carte?
  - How are options visible when quoted?
  - Do all product options need to be shown, or just the parent?
  - When certain SKUs are selected, do they constrain other selections? If so, which? (1:1 or larger scale?)
- Are there attributes that need to be selected and applied to products (not part of the SKU itself)?
- What types of products are often sold together?
- Which bundle components are optional vs. mandatory?
- Which products are dependent on each other during configuration?
- Which products cannot be sold together?
- Are there product configuration rules that automatically select products?
- Are there upselling or co-selling scenarios?
- What are the basic constraints (dependencies, exclusions)?
- What product rules are applied or required? (constraints, validation, filters, selection, prior purchase constraints)
- Does any information/attributes need to be captured during configuration?
- What are the bundle sizes and organization? (child components and groups)
- How many bundles? (gauge data volume)
- What is the complexity of the bundles? How many product options and combinations?
- How many options or configurations are reps managing per product?
- How are quantities managed for different product types? (billable hours, milestones, license-based)
- Can you provide your current bundle structure?

---

## 3. Pricing — Next-Gen Pricing (NGP)

**Expected output:** Types of pricing needed in the pricing procedure and Context Definition. Sample discounts, types of discounts, and any fringe cases requiring customization.

### Pricing Models
- What is your biggest pain point around pricing?
- What kind(s) of pricing models do you currently use? (select all that apply)
  - List Price
  - Cost-plus / Target Margin
  - Volume or Tier-based Pricing
  - Subscription Pricing
  - Usage-Based Pricing
  - Formula Derived Pricing
  - Block Price
  - Percent of Total (e.g., Support is 20% of License cost)
  - Attribute-Based Pricing
  - Promotional Pricing
  - Bundle/Rollup Pricing
  - Floor Pricing
  - Goal Seek Pricing
  - Contracted Pricing

### Discounts
- What kind of discounts do you offer?
  - Discretionary/Custom Discount
  - Partner or Distributor Discounts
  - Volume Discount
  - Contracted Discount
  - Term-based discount (multi-year)
- Do end users need to see the discounts, or is the waterfall enough?
- When reps apply a discount, do they apply per line/product or as a percentage to the overall quote?

### Pricing Rules & Exceptions
- What caveats exist that deviate from the normal model?
- Which products have volume-based pricing? Is it applicable to all or SKU-specific?
- Do you offer discounts by term?
- Do you need to calculate margins?
- What is your current Pricebook structure in Salesforce?
- Are there multiple Pricebooks?
- How often do you update your prices?
- Does pricing vary by region or other factor?
- Are there Attributes that drive Pricing?
- Are there product configuration rules that drive quantity or price?

### Currency
- Do you sell in multiple currencies?
- Do you have a corporate currency (e.g., USD)?
- How do you manage currencies? (by region, country, sales team)
- How do you manage exchange rates?
  - What cadence are these set on?
  - Do you set rates with specific customers at a point in time, or negotiate rates?
  - Do you have systems or third parties that currently set exchange rates? (e.g., D&B)

### Pricing Concepts
- Are products sold via list price, cost, or block price? Can these be edited per quote?
- Can all/any products be discounted? Any restrictions?
- Does any of this vary by currency, region, or sales team?
- Do you have the concept of:
  - T&M (professional services)?
  - Milestone-based pricing?
  - Tiered pricing (e.g., licenses 10/25/100)?
  - Ramp pricing (Y1 - 10 licenses, Y2 - 50 licenses)?
  - Retainers (running fee until cancelled)?
  - Credit checks in the pricing or sales process?
  - Invoice or billing terms set in the sales process — do these influence pricing?

### Amendment & Renewal Pricing
- How should Renewal/Amendment pricing be handled?
  - Price uplift for renewal?
  - Last sold price for amendments?
  - Price as new for renewals/amendments?

### Taxes
- How do you handle tax calculations? (e.g., Avalara, Vertex, internal tax engine)

---

## 4. Quotes & Orders (QOC)

**Expected output:** Data required on opportunity/quote/order, Context Definition shape for twin fields and customizations. Quote/order line shape, typical quote size, potential bundling limit issues.

- What is your biggest pain point when quoting/ordering?
- Are you using Opportunity → Quotes → Orders, or a different path?

### Quoting
- How many products are typically on a quote? (number of quote lines)
- Do you quote based on available inventory? If so, where is inventory managed?
- How are sales users quoting currently? What tool is used?
- What fields do you display to sales reps on the Quote? On the Line Editor? How many fields?
- Do they require grouping of products in the UI?
- Are there additional validations outside of product validations?
- What is the next step after the quote is approved? (auto-ordered? document sent?)
- What are the phases/status of the Quote/Order?
- Do customers like to see the "path" of the Quote?
- Are you planning to customize the existing UI? If so, how?
- Do you need version control or different versions of quotes to send to a customer?

### Opportunity Integration
- Are there fields defaulted from the Opportunity to the Quote?
- Will all products sync back to the Opportunity?
- What data/fields are synced back to the Opportunity?
- Are Quotes/Orders created from the Opportunity or Account?
- Are Opportunity Splits part of this engagement?
- Are commissions managed in Salesforce?

### Orders
- What fields are displayed on the Order? On Order Products?
- What are the Order Stages/Status?
- Do you want to display the Path for the Order?
- Are orders automatically activated, or are there additional steps before activation?
- What data is carried over from the Quote and/or Opportunity to the Order?
- Is Order Fulfillment managed in Salesforce?

---

## 5. Approvals

**Expected output:** Types of approvals, which objects need approval, who approves. Enough to start at least one approval path.

- What is the biggest pain point in your approval process today?
- Do you have approvals based on: products selected, quantities, sales team/level/region, pricing/discounts?
- Do you have an approval matrix in place today?
- Who are the approvers?
- Are there compounding or tiered approvals? (e.g., manager → VP → CEO depending on tiers)
- Can the user hierarchy be used for tiered approvals?
- Does the approver change based on region, business unit, or other attribute?
- Do any approvers need to be grouped? (unanimous or first-to-approve?)
- Do approvals run in parallel? Can they? Should they?
- Do all quote approvers receive notification at the same time?
- How do approvers receive notification? How do they want to? Can they approve from email?
- Do you have a process diagram or flow chart?
- What other reasons require a quote to need approval?
- What parts of the quote should/shouldn't be editable when pending approval?
- What elements do approvers need to see in order to approve/reject?
- What type of tiering is incorporated? (e.g., 10% discount → user A, 20% discount → user B)
- Are approvers set up as users in Salesforce today?
- Do you have a concept of delegated approvers (e.g., for PTO)?
- Are any specific calculations made to drive approvals? (Margin, Total Discounts, MRR, etc.)

### Other Approvals
- Outside of quoting, are there other approval processes? (Product Creation, Product Activation, Pricing Updates)

---

## 6. Output Documents (Doc Gen)

**Expected output:** Number of documents, variations, format. Enough to generate the simplest document in one language.

- What documents do you currently send to customers?
- Which pieces of the current quote template are dynamic?
- Is a cover page or full-page cover letter needed?
- Is branded or marketing material required to be attached? Does this vary by product/sales team/region?
- Do additional documents need to be attached? (BOM, Calculator, etc.)
- What information is needed in the quote header section?
- What type of line item grid is needed? Are all products shown? Does a rollup occur for nested values?
- Is grouping utilized?
- What information is required in the header/footer?
- What type of terms and conditions are used?
  - Are all or some completely static?
  - Do you have standard T&C?
  - Are small portions dynamic, controlled via Salesforce fields?
  - Do sales users need to alter or create any terms?
  - Are any terms conditional or product-specific?
- What does the signature block need to look like?
- Do you use an e-signature vendor today? (DocuSign, Adobe Sign, etc.)
- Do you need to display output in different languages? Translate product names/descriptions?
- Do you provide the output document to the client in a different language (within the same country)?
- What information related to the product do you display in the output document?
- What totals do you display? (Non-Recurring Revenue, ARR, Monthly totals)
- What is displayed to customers vs. internal only?
- Are there specific ordering requirements for products in the quote line editor or output document?

---

## 7. Contracts & Assets (CALM)

**Expected output:** Whether CALM will support their contracting needs inside Revenue Cloud.

### Assets
- How do you currently manage subscription products for tracking?
- How do you currently manage your assets?
- Do you need asset history tracking? (ownership changes, service history, modifications)
- Are assets linked to contracts, subscriptions, or service agreements?
- How do you handle asset transfers between accounts, locations, or business units?
- Do sales and service teams need visibility into customer-owned assets when creating quotes or cases?
- What is your system for tracking inventory today? (e.g., ServiceMax Asset 360) How is it integrated with Salesforce?

### Contracts
- How do you create and manage customer contracts today?
- Do you use standard contract templates, or are contracts highly customized per customer?
- What types of contracts do you manage? (fixed-term, evergreen, subscription-based, usage-based)
- Do you need version control and audit tracking for contract changes and amendments?
- How do you handle contract renewals and expirations? Is this automated?
- Do you need automated alerts or reminders for upcoming renewals, pricing changes, or term expirations?
- How do you track contract obligations and entitlements? (SLAs, support levels, discounts)
- How do you currently link contracts with orders, assets, pricing agreements, and invoicing?

---

## 8. Amendments

**Expected output:** Standard amendment/renewal processes. Drive customer to out-of-box solutions.

- What are your biggest pain points in your amendment process?
- Do customers make changes to contracts mid-term? What sorts of changes?
- Are there requirements around contract extension or price changes during amendment?
- What does an add-on/amendment look like compared to a new business sale?
  - Differences in configuration? In pricing?
- Are most of your amendments add-ons, upgrades, or downgrades?
- Do you currently have price change amendments?
- How do you handle cancellations?
- What team handles amendments? How long does the average amendment take?
- Is it always triggered from Salesforce, or from an external system?
- Do amendments require approvals? What is the workflow?
- Do amendments require re-signing by the customer?
- How do you handle billing adjustments or prorations when amendments are made?
- Do you allow multiple amendments within a single contract period?

---

## 9. Renewals

**Expected output:** Volume of renewals, upsell/downsell, automated renewal support.

- What are your biggest pain points in your renewal process?
- Do you have renewals? What is your renewals process?
- Are there specific pricing rules or discounts for renewals? (loyalty discounts, annual price increases)
- How are renewals quoted?
- Combined renewals with co-terminations?
- Do you offer auto-renewal options, or do customers need to approve each renewal?
- How do you notify customers about upcoming renewals, and at what intervals?
- When are renewals created / when should they be forecasted?
- Is renewal always triggered from Salesforce, or from an external system?
- Are there renewal forecasting or analytics capabilities you currently use or need?

---

## 10. Inventory of Current Systems

Use this checklist to identify the customer's existing tech stack. Check which are in use:

| Category | Options |
|---|---|
| External Configurator | Logik.io, ValorX, KB Max, ThreeKit, FinancialForce Services Estimator, Provus Services CPQ, Custom |
| Pricing Optimization | Zilliant, PODS, Custom pricing service |
| Field Service | Salesforce Field Service, ServiceMax |
| Inventory Management | ServiceMax, Salesforce Field Service, ERP-based, Custom |
| Contracts | Salesforce Contracts |
| Document Generation | DocuSign, Conga, Adobe |
| Electronic Signature | DocuSign, Conga, Adobe |
| Contract Lifecycle Management | DocuSign, Conga, Adobe |
| DevOps / Release Management | Prodly, Gearset, Copado, Flosum, Custom/Source-Driven/SFMDU, None |
| Integration Layer | MuleSoft, Boomi, Workato |
| Professional Services Automation | FinancialForce, Kantata (Mavenlink/Kimble), Oracle Fusion, Planview, Netsuite OpenAir |
| Payment Gateway | Salesforce Payments, Chargent, Cybersource, PayPal/Braintree, Stripe, Adyen |
| Tax | Avalara, FinancialForce Accounting, Vertex |
| Credit Check | Dun & Bradstreet, Transunion |
| Revenue Recognition | Salesforce Billing, RevVue, RevVana, RightRev, FinancialForce Accounting |
| ERP | SAP, Oracle PeopleSoft, Netsuite, Sage Intacct, Workday, Custom |

---

## 11. DevOps

**Expected output:** Whether DevOps will be an enhancement or a hindrance to the engagement.

- What is your biggest pain point with your DevOps process?
- How does your organization currently manage Salesforce development, testing, and deployment?
- What DevOps tools and processes do you use for version control, CI/CD, and release management? (e.g., Git, Copado, Gearset, Jenkins)
- How frequently do you deploy changes to Salesforce? (weekly, bi-weekly, monthly)
- What is your approach to managing Salesforce metadata, configuration changes, and custom development?
- Who manages the DevOps process?
- How do you manage deployments across environments (Dev, QA, UAT, Production)?
- What is your rollback strategy in case a deployment causes issues in production?
- How do you ensure coordination between business users and technical teams when deploying Revenue Cloud changes?
- Do you have governance or approval processes in place before changes go live?
- Do you have development standards we need to be aware of?
- How many sandboxes do you have? Is a full copy sandbox available for Revenue Cloud implementation?

---

## 12. Integrations

**Expected output:** All integration points with Revenue Cloud. Potential issues with middleware or specific systems.

- Will Salesforce be the source of truth for quotes?
- What other systems or processes need to be considered after the sale is closed? (e.g., Order Management)
- What key systems do you integrate with Salesforce Revenue Cloud today? (ERP, billing, finance, e-commerce, CPQ, customer portals)
- What middleware or integration platforms do you use? (MuleSoft, Boomi, Jitterbit, custom APIs)
- Do you primarily use batch processing, real-time APIs, or event-driven integrations?
- What are the biggest integration challenges you face today?
- Are there legacy systems you need to integrate with or migrate from?
- What ERP system are you using? (SAP, NetSuite, Oracle, Microsoft Dynamics)
- How do you sync product, pricing, and contract data between Salesforce and your ERP?
- How are invoices and billing managed? (Salesforce Billing, third-party, or external billing system)
- Do you require real-time synchronization for order fulfillment, revenue recognition, or inventory?
- Do you need Salesforce to send data to external analytics or reporting tools? (Tableau, Power BI, Snowflake)
- How do you track and bill for usage-based or metered services?
- Do you need integration with a third-party usage metering or entitlement system?
- How do you handle subscription renewals across systems? Is that automated?
- Are there external systems responsible for managing customer entitlements or service activations?

---

## 13. Revenue Cloud Billing (RCB) — Billing Configuration & Operations

**Expected output:** Full billing scope for RCB implementation. Charge types, legal entities, tax strategy, GL integration, invoice volume estimate (drives Billing Events sizing), migration from BMP if applicable.

### Migration and Licensing
- Are you currently using the Salesforce Billing Managed Package (BMP/blng__)? If yes, what is the remaining contract duration and total contract value? (Needed to calculate RPO for Dual Billing Model)
- Is this a net-new billing implementation or a migration from BMP?
- What is the expected total invoice amount per month? (Drives Billing Events consumption estimate at $50/event)

### Legal Entities and Multi-Entity
- How many legal entities does your organization have for billing purposes?
- Do billing treatments, tax treatments, or accounting rules differ per legal entity?
- Do you issue invoices under multiple company names or VAT/tax IDs?

### Charge Types and Billing Frequency
- What charge types are in scope? (One-Time, Recurring Monthly, Recurring Annual, Usage-Based, Milestone-Based)
- What billing frequencies are required? (Monthly, Annual, Semi-Annual, custom milestone dates)
- Do you bill in advance (prepaid) or in arrears (postpaid)? Does this differ by product?
- Are any products subject to ramp pricing (different amounts in Year 1 vs Year 2 vs Year 3)?
- Do you have milestone-based billing scenarios? (Projects, professional services, delivery-based invoicing)

### Usage-Based Billing
- Are any products billed based on actual consumption? (API calls, storage, users, etc.)
- How is usage metered and reported? (External metering system, Salesforce-native?)
- What are the overage rules? Is there a committed minimum?
- What are the applicable units of measure?

### Tax
- Are you using an external tax engine? (Avalara, Vertex, or other?)
- What tax jurisdictions must be supported? (Multi-state US, VAT/GST for international?)
- Are any customers or product categories tax-exempt?
- How are tax exemptions documented and maintained?

### Payments and Payment Terms
- What are your standard payment terms? (Net 30, Net 60, EOM + 30, customer-specific?)
- Do you accept automated ACH/credit card payments, or manual payment only?
- Do you need payment schedules (split payment over multiple dates)?
- What is the process for failed payments and retries?

### Invoice Management
- How are invoices currently delivered? (Email PDF, portal, EDI, ERP?)
- Is invoice PDF customization required? (Branding, per-legal-entity templates, PO numbers, etc.)
- How do you handle invoice disputes and credit memos?
- Do you have scenarios where invoices need to be voided and rebilled?
- What is the process for write-offs of uncollectible invoices?
- Do you need to suspend billing for accounts in dispute or non-payment holds?
- Is invoice preview (showing customers upcoming charges before billing) required?

### GL and Financial Accounting
- What ERP are you using for the General Ledger? (SAP, NetSuite, Oracle, Microsoft Dynamics?)
- Is Salesforce the system of record for invoices (Lead-to-Invoice), or does data pass to ERP (Lead-to-Order)?
- What is the chart of accounts structure? How many GL accounts are involved in AR, Revenue, and Tax Liability?
- Do GL account assignments differ by product category, legal entity, or transaction type?
- What is your accounting period structure? (Monthly, Quarterly, custom?)
- Do you need the Salesforce Dual Transaction Journal exported to the ERP in real-time or batch?

### Subscriptions and Amendments
- How are subscription amendments handled today? (Add/remove products, quantity changes, upgrade/downgrade?)
- Do you support early renewals (customer renews before current subscription expires)?
- Are evergreen (auto-renewing) subscriptions in scope?
- How are prorations calculated for mid-cycle amendments?

### Multi-Currency
- Do you invoice customers in multiple currencies?
- What is your corporate reporting currency?
- How are exchange rates managed? (Salesforce daily rates, fixed rate, manual?)

---

## 14. eSign & CLM

**Expected output:** Which eSign package will be used. Whether redlining will be involved.

*(Ask customer stakeholders and/or eSign/CLM tool partners — DocuSign, Conga, Adobe Sign, etc.)*

- How do you generate quotes or contracts today?
- Is there an internal approval process before quotes/contracts can be sent to customers for signature?
- How do you recognize when a quote/contract is signed or approved by customers?
- What happens when a quote/contract is signed?
- When are signatures or approvals required from the customer? (amendments/change orders, additional services, support/service work)
- Are signed contracts stored in Salesforce/CRM?
- How do your eSign tool(s) work with Salesforce/CRM?
- Are there other scenarios where documents need to be signed that would have workflow impact in the CRM?
- Do you have a clause management tool today?
- Do you typically have redlining back and forth with customers?
- Do you have a way to store customer-specific clauses today?
