---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Implementation Guide

## Prerequisites

Before beginning any CGC implementation:

| Prerequisite | Verification |
|---|---|
| Consumer Goods Cloud license | Setup > Company Information > Licenses |
| TPM license (if required) | Same — verify Trade Promotion Management license |
| Mobile Sync package installed (if offline mobile required) | Setup > Installed Packages — look for `cgc_sync` namespace |
| Base edition is Enterprise or Unlimited | Required for CGC |
| Person Accounts NOT enabled (RE is Account/RetailStore-based, not Person Account) | Setup > Account Settings |
| My Domain configured | Required for Experience Cloud or LWC components |
| Salesforce Field Sales mobile app license | Required for field rep mobile access |

---

## Phase 1: Package Installation and Base Configuration

### Step 1 — Install the CGC Managed Package

1. Install the Consumer Goods Cloud managed package (`cgcloud` namespace) from AppExchange or Salesforce delivery team
2. If mobile offline is in scope: Install the Mobile Sync package (`cgc_sync` namespace) separately
3. If TPM is in scope: Confirm TPM license is provisioned (same package, license-gated features)
4. Verify installation: Setup > Installed Packages — confirm `Consumer Goods Cloud` and namespace `cgcloud`

### Step 2 — Enable RetailExecutionSettings

Enable CGC features via the `RetailExecutionSettings` metadata type.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<RetailExecutionSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableRetailExecution>true</enableRetailExecution>
  <enableProductHierarchy>true</enableProductHierarchy>   <!-- v53.0+ -->
  <enableVisitSharing>false</enableVisitSharing>          <!-- v55.0+ -->
</RetailExecutionSettings>
```

Package manifest reference:
```xml
<types>
  <members>RetailExecution</members>
  <name>Settings</name>
</types>
```

**Note:** `enableRetailExecution` defaults to `false` — must be set to `true` before any CGC mobile features work.

### Step 3 — Configure Sales Organizations

1. Create `cgcloud__Sales_Organization__c` records for each division/sales org
2. Create `cgcloud__Sales_Organization_User__c` records to assign users to sales orgs
3. Create `cgcloud__Account_Template__c` records per sales org (drives account defaults, language, product hierarchy)

### Step 4 — Configure Permission Sets

1. Assign CGC-provided permission sets to users (check Setup > Permission Sets for cgcloud-prefixed sets)
2. Create custom permission sets for org-specific field access
3. For TPM: assign `TPM Calculation Result Export` permission set to the RTR export service user
4. For Sync Management: create sync-specific permission sets controlling `cgc_sync__*` object access

### Step 5 — Set User Language Postfix

For multilingual orgs, populate `cgcloud__Language_Postfix__c` on every User record:
- Valid values: `Language1`, `Language2`, `Language3`, `Language4`
- Determines which description language formula fields display
- Must be set before testing any UI with product/account descriptions

---

## Phase 2: Retail Execution Setup

### Step 6 — Configure Account Templates

`cgcloud__Account_Template__c` is the foundation of the account model:
1. Create one template per sales org
2. Set `cgcloud__Sales_Org__c` on the template
3. Assign template to Account records via `cgcloud__Account_Template__c` field
4. The template drives `cgcloud__Sales_Org__c` formula on Account (calculated, not stored)

### Step 7 — Configure Product Hierarchy

If `enableProductHierarchy = true`:
1. Create `cgcloud__Product_Hierarchy__c` records (Brand, Category, SubCategory levels)
2. Assign products to hierarchy nodes via `cgcloud__Product_Template__c`
3. Keep hierarchy depth to 3–4 levels maximum (performance risk at 5+)

### Step 8 — Set Up Stores and Assortments

1. Create `RetailStore` records linked to Account records
2. Create `RetailLocationGroup` records (group stores by chain, size, tier)
3. Create `RetailStoreGroupAssignment` junction records
4. Create `Assortment` records (one per product list type)
5. Create `AssortmentProduct` records (products in each assortment)
6. Create `StoreAssortment` records (link assortments to stores or store groups)

### Step 9 — Configure Assessment Tasks

1. Create `AssessmentIndicatorDefinition` records (one per KPI to track: Facings, Inventory, etc.)
   - DataType: Number/Percentage/Boolean/String/Picklist/Multi-Select Picklist
2. Create `AssessmentIndDefinedValue` records for picklist-type AIDs
3. Create `AssessmentTaskDefinition` records (one per task type per visit type)
4. Assign AIDs to task definitions via `AssessmentTaskIndDefinition`
5. Create `RetailStoreKpi` records to set targets per store group + AID + product

### Step 10 — Configure Visit Types and Automation

1. Define Visit record types per visit type (standard store visit, DSD visit, audit visit, etc.)
2. Build a Record-Triggered Flow on Visit insert to auto-create `AssessmentTask` records
   - For scale (500+ stores): use Queueable class instead of synchronous Flow
3. Set up `cgcloud__Workflow__c` records if using workflow state machines for orders

---

## Phase 3: Direct Store Delivery (DSD) Setup

### Step 11 — Configure Routes and Tours

1. Create `cgcloud__Route_Template__c` records (route definitions)
2. Create `cgcloud__Route__c` records (active routes)
3. Create `cgcloud__Route_Account__c` records (account stops per route)
4. Create `cgcloud__Tour_Template__c` for recurring tour patterns
5. Create `cgcloud__Vehicle__c` and `cgcloud__Vehicle_Warehouse__c` records
6. Create `VehicleUserAssignment` records to assign vehicles to drivers

---

## Phase 4: Sync Management Setup

### Step 12 — Configure Sync Management

1. Create `cgc_sync__Sync_Config__c` record(s) — one per client app profile:
   - `cgc_sync__Download_Page_Size_Limit__c` — records per sync page
   - `cgc_sync__Batch_Soql_Response_Time_Limit__c` — 4000ms recommended
   - `cgc_sync__CPU_Time_Calculation_Buffer__c` — 6500ms recommended
   - `cgc_sync__Download_Response_Time_Limit__c` — 2000ms recommended
   - `cgc_sync__ClientApp_ID__c` — app installation ID

2. Configure `cgc_sync__Sync_Client_App_Profile_Mapping__c` to map users/profiles to sync configs

3. Configure `cgc_sync__Sync_Tracked_Object_Config__c` for each object to sync:
   - Set `cgc_sync__Object_Api_Name__c`
   - Set `cgc_sync__Max_Records_Before_Full_Sync__c`
   - Set `cgc_sync__On_the_Road_Sync__c` for objects needed during offline delivery
   - Set `cgc_sync__SF_Rest_Enabled__c` if standard REST API should be used

4. Create `cgc_sync__Sync_Named_Query__c` records for SOQL priming queries

5. Create deployment packages (`cgc_sync__Sync_Mobile_App_Depl_Pkg__c`) with RTAs

6. Assign packages to users via `cgc_sync__Sync_Mobile_App_Depl_Pkg_As__c`

---

## Phase 5: Trade Promotion Management Setup

### Step 13 — Create Business Years

1. Create `cgcloud__Business_Year__c` records per sales org:
   - `cgcloud__Date_From__c` / `cgcloud__Date_Thru__c`
   - `cgcloud__Year_Number__c`
   - `cgcloud__Sales_Organization__c`
2. Must be activated before RTR export will produce data

### Step 14 — Configure Promotion Templates

1. Create `cgcloud__Promotion_Template__c` records
2. Define `cgcloud__Tactic_Template__c` records (PriceReduction, Display, Shipment, etc.)
3. Create `cgcloud__Tactic_Template_Fund_Template__c` junctions (valid fund types per tactic template)
4. Optionally create `cgcloud__Promotion_Template_Hierarchy__c` for template organization

### Step 15 — Configure Funds

1. Create `cgcloud__Fund_Template__c` records per fund type
2. Create `cgcloud__Fund__c` records per business period (linked to Business Year + Sales Org)
3. Set up `cgcloud__Fund_Product__c` records for brand/category-level fund restrictions
4. For rate-based funding: create `cgcloud__RBF_Template__c` and `cgcloud__Rate_Based_Funding__c` records

### Step 16 — Configure KPI Sets for RTR

1. Create `cgcloud__KPI_Definition__c` records for each measure to track
2. Create `cgcloud__KPI_Set__c` records grouping related KPIs
3. Create `cgcloud__KPI_Set_KPI_Definition__c` junctions
4. Create `cgcloud__RTR_Report_Configuration__c` records per dimension (Account/Promotion/Tactic/Product) per sales org
5. Save and synchronize dimension meta to Consumer Goods Cloud Processing Service

### Step 17 — Configure Business Object API Workflows (if external integration required)

1. Create Business Object API Workflow records defining entities and mappings
2. Add Workflow Steps (managed package steps + custom Apex steps)
3. Register custom Apex callable classes via Business Object API Workflow Step records
4. Test via View Schema button on workflow header

---

## Phase 6: Retail Order Customization (if required)

### Step 18 — Register Apex Callable Hooks

For order save customization:
1. Create global Apex class implementing `System.Callable`
2. Setup → Custom Metadata Types → `CGCloud Process Customization` → Manage Records
3. Create record: Label=`RE_Order_Save`, DeveloperName=`RE_Order_Save`, Class=your class, Method=`save`, Enabled=checked

For proposal list customization:
1. Same process with DeveloperName=`RE_Order_Proposal_List`, Method=`proposalList`
2. Ensure Order Template has `Consider Listing = Yes`

For LWC order screen customization:
1. Create LWC importing from `cgcloud/orderExtensionUtils`
2. Deploy with `<runtimeNamespace>cgcloud</runtimeNamespace>` in metadata (or enable LWS)
3. Add to `cgcloud__Order__c` record page

---

## Post-Deployment Checklist

After every CGC deployment to production:

- [ ] `RetailExecutionSettings.enableRetailExecution = true` confirmed in target org
- [ ] `cgcloud__Sales_Organization__c` records created for all sales orgs
- [ ] `cgcloud__Account_Template__c` records exist and linked to accounts
- [ ] `cgcloud__Language_Postfix__c` populated on all User records (for multilingual orgs)
- [ ] Sync Config response time limits within recommended ranges (4000/2000ms)
- [ ] `cgc_sync__Ignore_Client_Overrides__c` set correctly at org-level
- [ ] Mobile Sync deployment packages published and assigned to users
- [ ] AssessmentTaskDefinition records deployed and active
- [ ] RetailStoreKpi target records created
- [ ] Business Year records created and activated (for TPM)
- [ ] RTR dimension meta saved and synchronized to Processing Service (for TPM)
- [ ] All `cgcloud__Trigger_Setting__c` records restored to active state after migration
- [ ] Visit Status picklist values match mobile app expectations: New/In Progress/Complete/Cancelled
