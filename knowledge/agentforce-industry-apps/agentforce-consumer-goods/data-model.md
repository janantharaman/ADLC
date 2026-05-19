---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: data-model
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Data Model

## Standard Objects Extended by CGC (RE Module)

All in API version 55.0+ unless noted.

| Object | CGC-Added Fields (examples) | Purpose |
|---|---|---|
| `Account` | `cgcloud__ExternalId__c`, `cgcloud__Account_Number__c`, `cgcloud__Name_2__c`, `cgcloud__Sales_Org__c`, `cgcloud__Account_Template__c` | Retail store/chain account |
| `Asset` | `cgcloud__Asset_Template__c`, `cgcloud__Asset_Type__c`, `cgcloud__ERP_Asset_Number__c`, `cgcloud__Ownership_Type__c` (Leased/Owned), `cgcloud__Valid_From__c`, `cgcloud__Valid_Thru__c`, `cgcloud__Sales_Org__c` | Coolers, dispensers, POS assets |
| `Product2` | Extended with product hierarchy, description in 4 languages, sales org | Product catalog |
| `User` | Extended with language postfix, territory data | Field rep configuration |
| `Task` | Extended with visit-specific fields | Visit activities |
| `OperatingHours` | Standard FSL object extended for CGC store schedules | Store hours for visit planning |

**Multi-language pattern:** Many CGC description fields follow a 4-language pattern:
- `cgcloud__Description_Language_1__c` through `cgcloud__Description_Language_4__c`
- A calculated field `cgcloud__Description__c` uses a CASE formula on `$User.cgcloud__Language_Postfix__c` (Language1/2/3/4) to return the appropriate value

---

## Standard Objects — Retail Execution (v47.0+)

### Visit / Assessment Objects

| Object | API Version | Description |
|---|---|---|
| `AssessmentIndicatorDefinition` | v47.0 | Parameters/markers for compliance (Inventory, Facings, etc.). DataType: Boolean/DateTime/Decimal/Number/Percentage/String/Picklist/Multi-Select Picklist |
| `AssessmentIndDefinedValue` | v49.0 | Acceptable values for single/multi select AID questions |
| `AssessmentIndValue` | v49.0 | Target or captured values per AID |
| `AssessmentTask` | v47.0 | Individual task in a visit. TaskType: ConductInStoreSurveys/InventoryCheck/Other/PlaceOrder/PlanogramCheck/PromotionCheck. Status: Completed/InProgress/NotStarted |
| `AssessmentTaskContentDocument` | v47.0 | Links content documents to tasks/visits/planograms |
| `AssessmentTaskDefinition` | v48.0 | Template: associates AssessmentTask with AID |
| `AssessmentTaskIndDefinition` | v48.0 | Associates AID with AssessmentTaskDefinition |
| `AssessmentTaskOrder` | v47.0 | Order activity performed during a visit |

### Store and Location Objects

| Object | API Version | Description |
|---|---|---|
| `RetailStore` | v47.0 | Physical retail store associated to a business Account |
| `RetailLocationGroup` | v47.0 | Groups stores by shared features (size, chain, location) |
| `RetailStoreGroupAssignment` | v52.0 | Junction: RetailStore ↔ RetailLocationGroup |
| `InStoreLocation` | v47.0 | Locations within a store layout (aisles, shelves, backrooms) |
| `StoreProduct` | v47.0 | Associates a product to a retail store or in-store location |
| `StoreAssortment` | v47.0 | Associates an assortment to a store, store group, or account |
| `StoreActionPlanTemplate` | v48.0 | Associates an action plan template with a store |
| `RetailStoreKpi` | v47.0 | Maps store groups to AID, products, in-store locations; defines compliance targets |
| `RetailVisitKpi` | v47.0 | Captures actual values during a visit against AID targets |

### Product / Assortment Objects

| Object | API Version | Description |
|---|---|---|
| `Assortment` | v47.0 | List of products eligible for sale in a store |
| `AssortmentProduct` | v47.0 | Associates products to an assortment |
| `Promotion` | v47.0 | Promotional activities (targeted or campaign-based) at retail stores |
| `PromotionChannel` | v47.0 | Associates promotion to store, store group, or account |
| `PromotionProduct` | v47.0 | Associates promotion to a product |
| `PromotionProductCategory` | v47.0 | Associates promotion to a product category |

### Visit Personnel Objects

| Object | API Version | Description |
|---|---|---|
| `Visit` | v47.0 | Field rep's visit to a retail store. Central RE object |
| `Visitor` | v49.0 | Sales rep performing visits |
| `VisitedParty` | v49.0 | Contact person at the visited account |
| `VehicleUserAssignment` | v51.0 | Assigns a vehicle to a driver |

### DSD / Delivery Objects

| Object | API Version | Description |
|---|---|---|
| `DeliveryTask` | v50.0 | Shipment/order info to be delivered in a visit |
| `SignatureTask` | v50.0 | Signature information captured during a visit |
| `SignatureTaskLineItem` | v50.0 | Junction: SignatureTask ↔ digital signature |
| `OtherComponentTask` | v50.0 | Component task allowing launch of LWC components from task framework |

---

## Custom Objects — Retail Execution (`cgcloud` namespace)

### Order Objects

| Object | API Version | Description |
|---|---|---|
| `cgcloud__Order__c` | — | Retail order (extended Order); used with RE_Order Apex class |
| `cgcloud__Order_Item__c` | — | Line items for cgcloud orders |
| `cgcloud__Workflow__c` | — | Workflow definition for business objects (OrderEntry/Promotion/DailyReport/etc.) |
| `cgcloud__Workflow_State_Transition__c` | v54.0 | Stores state transition details. From/To status values include: Active/Approved/Cancelled/Committed/Planning/Released/etc. |

### DSD / Route Objects

| Object | Description |
|---|---|
| `cgcloud__Route__c` | Delivery route definition |
| `cgcloud__Route_Template__c` | Template for routes |
| `cgcloud__Tour__c` | Specific delivery run (instance of a route) |
| `cgcloud__Tour_Check__c` | Check/validation step in a tour |
| `cgcloud__Tour_Object_Reference__c` | Links objects to a tour |
| `cgcloud__Tour_Template__c` | Template for tours |
| `cgcloud__Tour_Template_Object_Reference__c` | Template-level tour object reference |
| `cgcloud__Tour_Template_Tour_Check__c` | Template-level tour check |
| `cgcloud__Tour_Tour_Check__c` | Instance-level tour-to-check junction |
| `cgcloud__Vehicle__c` | Vehicle (moving location) |
| `cgcloud__Vehicle_Warehouse__c` | Vehicle-warehouse relationship |
| `cgcloud__Route_Account__c` | Account stops on a route |

### Account / Customer Objects

| Object | Description |
|---|---|
| `cgcloud__Account_Condition__c` | Conditions on an account |
| `cgcloud__Account_Extension__c` | Extended account data (territory, sales org) |
| `cgcloud__Account_Manager__c` | Account manager assignments |
| `cgcloud__Account_Relationship__c` | Account-to-account relationships |
| `cgcloud__Account_Set__c` | Named grouping of accounts |
| `cgcloud__Account_Set_Account__c` | Junction: AccountSet ↔ Account |
| `cgcloud__Account_Set_Manager__c` | Manager assigned to an account set |
| `cgcloud__Account_Template__c` | Template for accounts (drives sales org, language, defaults) |
| `cgcloud__Account_Trade_Org_Hierarchy__c` | Trade org hierarchy membership |
| `cgcloud__Account_Org_Unit__c` | Org unit assignment for accounts |
| `cgcloud__Flatten_Account_Hierarchy__c` | Flattened account hierarchy lookup |

### Product / Catalog Objects

| Object | Description |
|---|---|
| `cgcloud__Product_Hierarchy__c` | Product hierarchy nodes (Brand/Category/SubCategory) |
| `cgcloud__Product_Template__c` | Template for products |
| `cgcloud__Product_Assortment_Template__c` | Assortment configuration template |
| `cgcloud__Product_Category_Share__c` | Shares a product category with an account set |

### Segmentation / Rules

| Object | Description |
|---|---|
| `cgcloud__Segmentation_Rule__c` | Defines account segmentation logic |
| `cgcloud__Segmentation_Rule_Def__c` | Rule definition |
| `cgcloud__Segmentation_Rule_Def_Column__c` | Column-level rule definition |
| `cgcloud__Segmentation_Rule_Template__c` | Template for segmentation rules |

### Configuration Objects

| Object | Description |
|---|---|
| `cgcloud__System_Setting__c` | System-level settings for CGC module |
| `cgcloud__Trigger_Setting__c` | Enable/disable specific CGC triggers |
| `cgcloud__Validation_Rules_Setting__c` | Enable/disable specific CGC validation rules |
| `cgcloud__User_Setting__c` | Per-user preferences and configuration |
| `cgcloud__CGCPS_Service_Settings__c` | Service settings for CGC processing service |
| `cgcloud__Condition_Template__c` | Template for conditions |
| `cgcloud__Custom_Permission_User_Role_Mapping__c` | Maps custom permissions to user roles |
| `cgcloud__Batch_Run_Status__c` | Status tracking for batch jobs |
| `cgcloud__Batch_Run_Status_Detail__c` | Detail records for batch run status |

---

## Custom Objects — Sync Management (`cgc_sync` namespace, v53.0+)

| Object | API Version | Description |
|---|---|---|
| `cgc_sync__Sync_API_Log__c` | v53.0 | Performance info for sync endpoints |
| `cgc_sync__Sync_Client_App_Profile_Mapping__c` | v53.0 | Maps user/role/profile to sync config |
| `cgc_sync__Sync_Client_Registration__c` | v61.0 | Device registration info for offline app |
| `cgc_sync__Sync_Config__c` | v53.0 | Sync engine config: background sync, startup, thresholds |
| `cgc_sync__Sync_ID_Mapping__c` | v53.0 | Local mobile ID → Salesforce ID mappings |
| `cgc_sync__Sync_History__c` | v53.0 | History of every sync with status and KPIs |
| `cgc_sync__Sync_History_Detail__c` | v53.0 | Detailed sync history records |
| `cgc_sync__Sync_Message__c` | v53.0 | Messages exposed to mobile user during sync |
| `cgc_sync__Sync_Message_Translation__c` | v53.0 | Translated sync messages |
| `cgc_sync__Sync_Metadata_Changes__c` | v53.0 | Timestamps for metadata changes |
| `cgc_sync__Sync_Mobile_App_Component__c` | v53.0 | Customizable UI component settings for themes |
| `cgc_sync__Sync_Mobile_App_Domain__c` | v53.0 | Domain dropdown data for mobile app |
| `cgc_sync__Sync_Mobile_App_Depl_Pkg__c` | v53.0 | Deployment packages (RTAs) |
| `cgc_sync__Sync_Mobile_App_Depl_Pkg_As__c` | v53.0 | Deployment package recipient |
| `cgc_sync__Sync_Mobile_App_Depl_Pkg_Inst__c` | v53.0 | Installed deployment package tracking |
| `cgc_sync__Sync_Mobile_App_Installation__c` | v53.0 | App installation info |
| `cgc_sync__Sync_Mobile_App_Log__c` | v53.0 | Error messages from mobile app |
| `cgc_sync__Sync_Mobile_App_Theme__c` | v53.0 | Mobile app themes |
| `cgc_sync__Sync_Named_Query__c` | v53.0 | Named SOQL queries for sync |
| `cgc_sync__Sync_Remote_Request__c` | v53.0 | Remote requests to trigger mobile technical activities |
| `cgc_sync__Sync_Tracked_Object_Config__c` | v53.0 | Per-object sync settings (distribution, schema) |

**Key `cgc_sync__Sync_Tracked_Object_Config__c` fields:**
- `cgc_sync__Object_Api_Name__c` — API name of the tracked object
- `cgc_sync__Max_Records_Before_Full_Sync__c` — threshold before switching to full sync
- `cgc_sync__On_the_Road_Sync__c` — on-road sync only flag
- `cgc_sync__SF_Rest_Enabled__c` — use standard Salesforce REST API for sync

**`cgc_sync__Sync_Config__c` key performance fields:**
- `cgc_sync__Batch_Soql_Response_Time_Limit__c` — batch SOQL response time limit (ms; recommended 4000; range 2000-4000)
- `cgc_sync__CPU_Time_Calculation_Buffer__c` — buffer for Apex CPU limit protection (recommended 6500ms)
- `cgc_sync__Download_Response_Time_Limit__c` — download response limit (ms; recommended 2000)
- `cgc_sync__Encryption_Platforms__c` — comma-separated list of OS platforms that activate encryption

---

## Custom Objects — Trade Promotion Management (`cgcloud` namespace, v54.0+)

### Planning Objects

| Object | Description |
|---|---|
| `cgcloud__Business_Year__c` | Business year definition (Date_From, Date_Thru, Year_Number, Sales_Organization) |
| `cgcloud__Account_Plan__c` | Account plan for one planning account + business year + categories |
| `cgcloud__Account_Plan_Category__c` | Category assigned to an account plan (unique per account/year combo) |
| `cgcloud__Account_Plan_User_Filter__c` | User's filter selections for a planning account |
| `cgcloud__Account_Product_Profile__c` | Weekly distribution profile between customer and category (Mon/Tue/Wed/Thu/Fri/Sat/Sun percentages) |
| `cgcloud__Account_Sub_Account__c` | Account-to-sub-account relationship with volume percent |
| `cgcloud__Custom_Period__c` | Custom period definition |
| `cgcloud__Custom_Calendar__c` | Custom calendar definition |
| `cgcloud__Week_Day_Share_Profile__c` | Statistical weekday distribution profile |

### Promotion Objects

| Object | Description |
|---|---|
| `cgcloud__Promotion__c` | Core promotion record (shared with RE module) |
| `cgcloud__Promotion_Template__c` | Template for promotion creation |
| `cgcloud__Promotion_Template_Hierarchy__c` | Hierarchy of promotion templates |
| `cgcloud__Promotion_Template_Tactic_Template__c` | Template-tactic template junction |
| `cgcloud__Promotion_Attachment__c` | Promotion attachments |
| `cgcloud__Promotion_Attachment_Link__c` | Links attachments to promotions |
| `cgcloud__Promotion_Product_Share__c` | Categories assigned to a promotion |
| `cgcloud__Promotion_Calculation_Server_Offset__c` | Offplatform calculation time range |
| `cgcloud__Promotion_Push_Status__c` | Push process status and statistics |

### Tactic Objects

| Object | Description |
|---|---|
| `cgcloud__Tactic__c` | Individual promotion tactic (price reduction, display, etc.) |
| `cgcloud__Tactic_Product__c` | Product associated to a tactic |
| `cgcloud__Tactic_Template__c` | Tactic template |
| `cgcloud__Tactic_Fund__c` | Fund-to-tactic junction |
| `cgcloud__Tactic_Condition_Creation_Definition__c` | v55.0 — tactic condition creation config |
| `cgcloud__Tactic_Product_Condition__c` | Internal conditions generated from promotions |
| `cgcloud__Tactic_Template_Cond_Creation_Def__c` | v55.0 — template-level condition creation config |
| `cgcloud__Tactic_Template_Fund_Template__c` | Junction: TacticTemplate ↔ FundTemplate (valid fund types) |
| `cgcloud__Condition_Search_Group__c` | v55.0 — condition search group |
| `cgcloud__Condition_Search_Rule__c` | v55.0 — condition search rule |

### Fund / Payment Objects

| Object | Description |
|---|---|
| `cgcloud__Fund__c` | Fund record (budget for a business period/special activity) |
| `cgcloud__Fund_Product__c` | Fund-to-brand/category link |
| `cgcloud__Fund_Template__c` | Template for fund creation |
| `cgcloud__Fund_Transaction__c` | Fund transaction details |
| `cgcloud__Fund_Transaction_Header__c` | Header for multiple fund transactions (Transfer/Drawback/etc.) |
| `cgcloud__Fund_Transaction_Row__c` | Transaction row records |
| `cgcloud__Fund_Transaction_Template__c` | Template for fund transactions |
| `cgcloud__Rate_Based_Funding__c` | RBF record with metadata from RBF Template |
| `cgcloud__RBF_Template__c` | Rate-based funding template |
| `cgcloud__RBF_Category__c` | RBF-to-product junction |
| `cgcloud__RBF_Product_Manual_Input__c` | RBF-product junction with manual inputs |
| `cgcloud__Payment__c` | Retailer compensation value for running promotions |
| `cgcloud__Payment_Template__c` | Payment template |
| `cgcloud__Payment_External_Reference__c` | Hyperlinks related to a payment record |
| `cgcloud__Payment_Tactic__c` | Fund-to-PaymentTactic junction |
| `cgcloud__Payment_Tactic_Fund__c` | Fund-PaymentTactic junction (stores fund relationship) |
| `cgcloud__Payment_Tactic_Product__c` | Payment tactic products at LDP/project-defined level |
| `cgcloud__Payment_Tactic_Product_Manual_Input__c` | Manual inputs per payment tactic product |

### KPI / Reporting Objects

| Object | Description |
|---|---|
| `cgcloud__KPI_Definition__c` | Description of a single measure |
| `cgcloud__KPI_Map__c` | KPI Map configuration info |
| `cgcloud__KPI_Set__c` | KPI Set configuration |
| `cgcloud__KPI_Set_KPI_Definition__c` | Junction: KPISet ↔ KPIDefinition |
| `cgcloud__RTR_Report_Configuration__c` | Real Time Report configuration (dimensions, columns, filters) |

### Product Catalog Objects (TPM)

| Object | Description |
|---|---|
| `cgcloud__Product_Part__c` | Child-parent product relationship (BOM/assembly) |
| `cgcloud__Product_Assortment_Product_Share__c` | Categories assigned to a product assortment |

### Configuration Objects (TPM)

| Object | Description |
|---|---|
| `cgcloud__Auto_Number_Sequence__c` | Auto-number index for transaction log records |
| `cgcloud__Smart_UI_Lightning_Settings__c` | Smart UI configurations |
| `cgcloud__UI_Contract__c` | Contract info for smart UI templates |
| `cgcloud__User_View__c` | User-View relation junction |
| `cgcloud__View__c` | Filter criteria for trade calendar |

---

## Shared Objects (RE + TPM)

These objects appear in the "Custom Objects for Retail Execution and Trade Promotion Management" section (PDF pp.1560+):

| Object | Description |
|---|---|
| `cgcloud__Account_Condition__c` | Account conditions |
| `cgcloud__Account_Extension__c` | Extended account attributes |
| `cgcloud__Account_Manager__c` | Account manager assignments |
| `cgcloud__Account_Relationship__c` | Account relationships |
| `cgcloud__Account_Set__c` | Named account groups |
| `cgcloud__Account_Set_Account__c` | AccountSet-Account junction |
| `cgcloud__Account_Set_Manager__c` | AccountSet manager |
| `cgcloud__Account_Template__c` | Account template (drives sales org, language defaults) |
| `cgcloud__Account_Trade_Org_Hierarchy__c` | Trade org hierarchy |
| `cgcloud__Promotion__c` | Promotion (shared RE+TPM) |
| `cgcloud__Promotion_Template__c` | Promotion template (shared) |
| `cgcloud__Sales_Organization__c` | Sales organization record |
| `cgcloud__Sales_Organization_User__c` | User-SalesOrg junction |
| `cgcloud__Tactic__c` | Tactic (shared RE+TPM) |
| `cgcloud__Tactic_Product__c` | Tactic-product association (shared) |
| `cgcloud__Tactic_Template__c` | Tactic template (shared) |
| `cgcloud__Segmentation_Rule__c` | Account segmentation rule |
| `cgcloud__System_Setting__c` | System settings |
| `cgcloud__Transaction_Log__c` | Transaction log |
| `cgcloud__Trigger_Setting__c` | Trigger on/off config |
| `cgcloud__Update_Activation__c` | Activation update records |
| `cgcloud__User_Setting__c` | User-level settings |
| `cgcloud__Validation_Rules_Setting__c` | Validation rule on/off config |

---

## Objects for Future Use

These objects are present in the managed package but reserved for future features:

| Object | Notes |
|---|---|
| `cgcloud__Contract__c` | Contract management (not yet active) |
| `cgcloud__Contract_Payment__c` | Future |
| `cgcloud__Contract_Payment_Tactic__c` | Future |
| `cgcloud__Contract_Payment_Template__c` | Future |
| `cgcloud__Contract_Product__c` | Future |
| `cgcloud__Contract_Tactic__c` | Future |
| `cgcloud__Contract_Template__c` | Future |
| `Shift` | FSL shift (future use in CGC context) |
| `ShiftTemplate` | Future |
| `TimeSheet` | Future |
| `TimeSheetEntry` | Future |

---

## Key Relationships

```
Account (Retail chain / HQ)
    │
    └──► cgcloud__Account_Extension__c (sales org, territory)
    │
    └──► cgcloud__Account_Template__c (drives language, sales org defaults)
    │
    └──► RetailStore (individual outlet)
              │
              └──► Visit
                     │
              ┌──────┴──────────────┐
              │                      │
        AssessmentTask        cgcloud__Order__c
              │                      │
        RetailVisitKpi         cgcloud__Order_Item__c
```

```
cgcloud__Sales_Organization__c
    │
    └──► cgcloud__Business_Year__c
              │
              └──► cgcloud__Account_Plan__c
                         │
                         └──► cgcloud__Account_Plan_Category__c
                                    │
                                    └──► cgcloud__Promotion__c
                                               │
                                    ┌──────────┴──────────┐
                                    │                       │
                              cgcloud__Tactic__c    cgcloud__Fund__c
                                    │
                              cgcloud__Payment__c
```

---

## SOQL Notes

- Use `cgcloud__External_Id__c` (ExternalId field, idLookup) on Account and other objects for ERP upserts
- The `cgcloud__Sales_Org__c` field on Account is a calculated formula (not a stored field) — cannot filter efficiently
- `cgcloud__Language_Postfix__c` on User controls language display — always set before testing multilingual setups
- `cgc_sync__Sync_Config__c` uses `SetupOwnerId` (polymorphic: Organization/Profile/User) — filter by type for profile-specific config
