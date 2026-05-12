# CG Cloud TPM Business Processes

> **Source**: Extracted from NotebookLM (41 sources) on 2026-03-06

## 1. Customer Business Planning (CBP)

Customer Business Plans (CBPs) allow Key Account Managers (KAMs) to create comprehensive sales strategies for specific accounts and product categories, replacing manual spreadsheets with a centralized tool. They are used to review sales targets, adjust base volumes (sales expected without promotions), and analyze the impact of promotions.

### Step-by-Step Workflow

**Step 1: Create the CBP**
- Navigate to the Customer Business Plan app
- Click New
- Define the customer, business year, relevant product categories, and description

**Step 2: Adjust Baseline Metrics**
- In the CBP, manually adjust editable KPIs, such as base volumes, to reflect market trends or new product listings
- Manual adjustments are marked with a specific icon and stored against the CBP

**Step 3: Save and Calculate**
- Click the "Save & Calculate" button to process manual inputs
- This recalculates the adjustments and pushes the impact to all underlying promotions and the Account Plan

**Step 4: Scenario Planning (Optional)**
- Create up to 5 different "what-if" scenarios within the CBP
- Include or exclude specific promotions to compare their potential KPI impacts
- Use scenario comparison report to analyze impacts
- Activate the most effective scenario

---

## 2. Promotion Management

Promotions are targeted marketing events defined by specific timeframes and tactics (e.g., displays, price cuts) designed to boost sales volume. Promotion Management in CG Cloud tracks these events through their full lifecycle from planning to post-event analysis.

### Step-by-Step Workflow

**Step 1: Create the Promotion**
- Create a new promotion from scratch
- Copy an existing promotion
- Derive a child promotion
- Use "Push" feature to roll a national promotion down a customer hierarchy

**Step 2: Define Promotion Details**
- Specify timeframe (In-Store, Shipment, Commit dates)
- Define customer anchor
- Select promotion template
- Add products (dynamic filters or static list)

**Step 3: Volume and Spend Planning**
- Add actionable mechanics called "Tactics" (e.g., 50% price cut, $10,000 ad)
- Estimate sales volumes using Volume Planning Card (VPC)
- Estimate tactic costs using Spend Planning Card (SPC)

**Step 4: Link Funds**
- Assign a budget to sponsor the tactic
- CG Cloud can automatically determine the correct tactic fund
- Or manually link an active fund that matches the tactic's products and timeframe

**Step 5: Phase Progression**
- Move promotion through lifecycle phases:
  - Preparation
  - Planning
  - For Approval
  - Committed
  - Cancelled
- Each phase triggers specific system calculations, validations, and visibility in Trade Calendar

---

## 3. Claims Processing

Claims handle the remuneration requested by retailers for executing trade promotion tactics. They can originate directly from the retailer as deductions (short payments on invoices) or be manually initiated as check requests or credit memos.

### Step-by-Step Workflow

**Step 1: Initiate the Claim**
- Deduction is automatically interfaced from external ERP
- Or manually created by KAM or Finance User

**Step 2: Link Tactics**
- Link one or multiple tactics to the claim
- Allocate requested amount against agreed-upon promotional spend

**Step 3: Evaluate and Adjust**
- Optionally reject amounts not related to Trade Spend
- Attach supporting documentation
- Manually override distributed claim amounts at individual product (SKU) level

**Step 4: Submit for Approval**
- Submit claim to route through approval process
- Once approved, claim status changes to "To Be Closed"
- Executes finalization processes

**Step 5: Claim Adjustments (If Needed)**
- **Claim Splitting**: Partially pay claim
- **Claim Replacement**: Correct wrong tactics
- **Claim Reversal**: Cancel the claim

---

## 4. KPI Configuration

KPIs drive the complex calculation engine in CG Cloud TPM, pulling in off-platform data (like baseline volumes and prices) to populate Account P&Ls, Promotions, and Funds.

### Step-by-Step Workflow

**Step 1: Create KPI Definitions**
Define individual KPIs by choosing their type:
- **Read**: From database
- **Calculated**: Formula-based
- **Editable**: Manual input
- **Editable Calculated**: Combination
- **Compound**: Interdependent formulas
- **Validation**: Business rules

**Step 2: Define Mechanics**
Set specific calculation mechanics:
- Object and time scopes
- Aggregation rules across product hierarchies
- Rounding logic

**Step 3: Group into KPI Sets**
- Group created KPI Definitions into a "KPI Set"
- Configure for specific business usage (e.g., "Plan", "Promotion", "Funding")
- Assign KPIs to specific subsets to control visibility:
  - Volume Planning Card
  - Spend Planning Card
  - Account P&L

**Step 4: Assign to Templates**
- Link completed KPI Set to relevant business templates:
  - Customer Template
  - Promotion Template
  - Claim Template

**Step 5: Update Configuration**
- Click "Update Configuration" button
- Validates the set
- Communicates logic to backend Processing Engine

---

## 5. Real-Time Reporting (RTR)

Real-Time Reporting allows KAMs to build flexible, dynamic P&L layouts and analyze the impact of promotions on sales plans immediately without waiting for overnight batch jobs.

### Step-by-Step Workflow

**Step 1: Define Writeback KPIs**
- Ensure all KPIs you want to report on are configured as "Writeback KPIs"
- Calculated values are stored in the Processing Engine

**Step 2: Configure RTR Components**
- Create RTR KPI Set containing specific Writeback KPIs to display
- Define RTR Dimension Files to structure filtering
- Define RTR Metadata Files to structure data display

**Step 3: Set Up the Layout**
- In RTR Metadata Definition object, explicitly map KPIs
- Choose display format:
  - Flat Lists
  - Scorecards
  - Gauges
  - Progress Bars

**Step 4: Embed the Report**
- Use Salesforce Lightning App Builder to create new App Page
- Or embed directly into Promotion page
- Add custom "RTRTemplateComponent"
- Specify RTR Configuration Name
- Set UI Mapping (e.g., "FlatList")
- Activate page for users

---

## Best Practices

### Customer Business Planning
- Review and adjust baselines regularly based on market trends
- Use scenario planning for major promotional events
- Document assumptions behind manual adjustments

### Promotion Management
- Use templates to standardize promotion creation
- Link funds early in the planning process
- Progress phases systematically to trigger proper calculations

### Claims Processing
- Automate claim ingestion from ERP when possible
- Maintain clear documentation for claim adjustments
- Review rejection reasons to identify process improvements

### KPI Configuration
- Test formulas thoroughly before deploying to production
- Use meaningful names for KPIs to improve usability
- Document calculation logic for future reference

### Real-Time Reporting
- Don't writeback percentages or prices directly (causes incorrect aggregation)
- Use underlying components (Volume, Revenue) and let RTR calculate derived metrics
- Test report performance with production data volumes
