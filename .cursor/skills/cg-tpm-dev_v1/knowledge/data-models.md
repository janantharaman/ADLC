# CG Cloud TPM Data Models

> **Source**: Extracted from NotebookLM (41 sources) on 2026-03-06

## Sales Organization

**Object Name**: Sales Organization

**Purpose**: Allows manufacturers to segment their master data, business processes, and configurations by business unit (e.g., division, geography) on a single Salesforce instance, enabling a multi-market approach.

**Key Fields**:
- Currency
- First Day of Week
- First Week of Year
- Custom Calendar
- Tenant Substrate
- Account Product List Type (Global vs. Time Dependent)

**Relationships**:
- Master data (Accounts and Products) inherit from Sales Org
- Transactional data (Promotions and Claims) belong to Sales Org
- Users and Business Templates are scoped to Sales Org
- KPIs and KPI Sets are independent of Sales Org

---

## Product & Product Hierarchy

### Product2 (Standard Platform Object)

**Purpose**: Handles all product master data, including sellable SKUs, product groups (hierarchy nodes), and advertising materials. The product hierarchy dictates how values are aggregated or disaggregated within P&L sheets and reporting.

**Key Fields**:
- Record Type: "Product" or "Product Group"
- Product Level: e.g., Category, Sub-Category, Brand, SKU
- Consumer Goods Product Code
- CG Cloud External Product ID
- Criterion fields for filtering

**Relationships**:
- Related to Sales Org via Product Templates
- Linked to Product Managers (drives read/write access and security)
- Connected to Bill of Material (BOM) components

### Product Hierarchy Object

**Object Name**: `cgcloud__Product_Hierarchy__c`

**Purpose**: Defines time-stamped parent-child relationships between products.

**Key Fields**:
- Parent Product
- Child Product
- Valid From
- Valid Thru
- Structure Type (e.g., Sales)

---

## Account & Account Hierarchy

### Account Object (Customer)

**Purpose**: The standard Account object tracks core CRM interactions for stores, chains, wholesalers, and vendors. The hierarchy allows Key Account Managers (KAMs) to plan and run promotions at multi-level structures (like a national HQ level or banner level) and aggregates Account P&L data.

**Key Fields**:
- Customer Name
- Customer Number

**Relationships**:
- Linked to Customer Templates (defines available KPI sets)
- Each account has exactly one Customer Extension record
- Can be grouped using Customer Sets
- Indirectly related using Customer Relationships for wholesaler/distributor modeling

### Customer Extension

**Purpose**: Determines TPM-specific roles for each account.

**Key Fields**:
- Promotion Role
- Fund Role
- Plan Role

### Trade Org Hierarchy

**Purpose**: Enables multi-level account planning and aggregation.

**Key Fields**:
- Valid From
- Valid Thru

---

## Promotion

**Object Name**: Advanced Promotion (referred to as `cgcloud.TPM_Promotion` in custom LWC)

**Purpose**: Represents a specific timeframe containing marketing tactics (e.g., price cuts, displays) designed to drive sales, incur costs, or introduce products.

**Key Fields**:
- Slogan
- Promotion Template
- Anchor Customer
- Dates: In-Store, Shipment, Commit
- Phase: Preparation, Planning, For Approval, Committed, Cancelled

**Relationships**:
- Inherits properties from Promotion Template (drives calculation modes and UI types)
- Links to Anchor (Customer, Customer Hierarchy node, or Customer Set)
- Contains list of Products (dynamic or fixed)
- Associated with Tactics
- Connected to Funding sources

---

## Account Product List (APL) / Product Assortment

**Object Name**: Product Assortment (used specifically for Time Dependent lists)

**Purpose**: Determines exactly which products are relevant to and available for a specific account. This filters out irrelevant products from the Account Plan, Customer Business Plan (CBP), and the promotion planning process.

**Key Fields**:
- Name
- Product Assortment Template
- Valid From
- Valid Thru
- Obligatory flag

**Types**:
- **Global APL**: Determined dynamically by batch process checking if a product has a baseline or list price KPI
- **Time Dependent APL**: Tied to exactly one Customer and multiple active products with explicit date ranges

**Relationships**:
- Governed by Sales Org
- Linked to specific Customer (Time Dependent)
- Contains multiple Products with validity dates

---

## Trade Calendar

### Custom Calendar

**Object Names**: Custom Calendar, Custom Period, Business Year

**Purpose**: The Trade Calendar is the primary visual interface allowing a KAM to view, filter, create, and manage promotions on a Gantt chart. The underlying data models enable flexible CPG timeframes, such as custom 4-4-5 aggregation and non-Gregorian business years, to drive the timeframe structure in Account P&L and calculation engine.

**Key Fields** (Custom Period):
- Date From
- Date Thru
- Description
- Type: Week, Month, Quarter

**Relationships**:
- Custom Calendars and Business Years must be linked directly to Sales Org
- Must be activated to be used

---

## KPI (Key Performance Indicators)

### KPI Definition

**Purpose**: KPIs represent the metrics (e.g., Target Volume, Target Revenue, Actual Volume) that drive the entire calculation engine for Account Plans, CBP, Promotions, and Claims.

**Key Fields**:
- Settings
- Formula
- Total Calculation
- Integration API reading/writing measure codes

**KPI Types**:
- **Read KPI**: Pulls values from database
- **Calculated KPI**: Uses JavaScript formulas
- **Editable KPI**: Allows manual user inputs
- **Editable Calculated KPI**: Combination of editable and calculated
- **Compound KPI**: Interdependent formulas
- **Validation KPI**: Evaluates business rules

### KPI Set

**Purpose**: Groups related KPI Definitions together for specific business usage.

**Relationships**:
- Linked to Promotion Template (for promotion-level planning)
- Linked to Customer Template (for Customer Business Plan)

### KPI Map

**Purpose**: Creates a physical link between an object attribute in Salesforce (like a Total Volume field) and a KPI value generated in the backend Processing Service.

---

## Data Synchronization

All master data changes (Sales Org settings, Product configurations, Customer hierarchies, Template Metadata) must be synchronized using the **SF Data Sync** tool so the off-core calculation engine uses the correct updated structures.

**Objects Requiring Sync**:
- Product2
- Product_Hierarchy
- Product Manager
- Customer/Account
- Trade Org Hierarchy
- Product Assortments
- Templates and KPI configurations
