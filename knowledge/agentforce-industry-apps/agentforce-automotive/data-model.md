---
source: Automotive Cloud Developer Guide v66.0 Spring '26 (PDF, 425 pages) — https://resources.docs.salesforce.com/260/latest/en-us/sfdc/pdf/automotive_cloud.pdf
cloud: Automotive Cloud
section: data-model
---

# Automotive Cloud — Data Model

## Vehicle Object
`Available in API version 56.0+` | All standard CRUD calls supported

**Special notes:** `VehicleIdentificationNumber` and `SourceSystemIdentifier` are unique within org. Feed, History, and ChangeEvent associated objects available.

| Field | Type | Notes |
|---|---|---|
| `ActiveRecallCount` | int | Number of active recalls for parts |
| `ActiveServiceContractCount` | int | Active service contracts count |
| `ActiveSubscriptionCount` | int | Active subscriptions count |
| `ActiveWarrantyCount` | int | Active warranties count |
| `AssetId` | reference → Asset | Unique; links vehicle to Asset record |
| `AverageMarketValue` | currency | Average market value |
| `ChassisNumber` | string | Unique chassis number |
| `Classification` | string | Auto-populated from VehicleDefinition |
| `ConditionType` | picklist | New / Old / Scrap |
| `CurrentOwnerId` | reference → Account | Current owner of the vehicle |
| `CylinderCount` | string | Engine cylinder count |
| `DrivetrainSystem` | picklist | Auto-populated from VehicleDefinition |
| `EngineName` | string | Auto-populated from VehicleDefinition |
| `EngineNumber` | string | idLookup; unique engine number |
| `ExteriorColor` | string | Exterior colour |
| `FrontRimSize` | string | Front wheel rim size |
| `FrontTireSize` | string | Front tyre size |
| `FuelSource` | picklist | Auto-populated from VehicleDefinition |
| `GearBoxType` | string | Gear box type |
| `HeadUnitName` | string | Head unit (car stereo) name |
| `HeadUnitSecurityCode` | encryptedstring | Anti-theft head unit unlock code |
| `HighestMarketValue` | currency | Highest market value recorded |
| `IgnitionKeyCode` | string | Ignition key unique code |
| `InteriorColor` | string | Interior colour |
| `IsConnectedServiceActive` | boolean | Connected services active (default: false) |
| `IsRecallOpen` | boolean | Recall required flag (default: false) |
| `IsTelematicsServiceActive` | boolean | Telematics subscription active (default: false) |
| `LastOdometerReading` | double | Most recent odometer reading |
| `LastServiceDate` | date | Last serviced date |
| `LatestResidualValue` | currency | Current residual value |
| `LatestResidualValueDate` | date | Date residual value was calculated |
| `Location` | address | Current geolocation of vehicle |
| `LocationCity/Country/State/PostalCode/Street` | string | Location address components |
| `LocationGeocodeAccuracy` | picklist | Address / Block / City / County / Street etc. |
| `LocationLatitude / LocationLongitude` | double | GPS coordinates |
| `LowestMarketValue` | currency | Lowest market value recorded |
| `MakeName` | string | Auto-populated from Product2 via VehicleDefinition |
| `ManufacturedDate` | date | Manufacturing date |
| `ManufacturerWarrantyEndDate` | date | Factory warranty end date |
| `ManufacturerWarrantyStartDt` | date | Factory warranty start date |
| `ManufacturingBatchNumber` | string | Manufacturing batch number |
| `ManufacturingPlantName` | string | Manufacturing plant name |
| `MarketPrice` | currency | Current market price |
| `MarketPriceDate` | date | Date market price was calculated |
| `MarketPriceSource` | picklist | NationalAutomobileDealersAssociation / KellyBluebook |
| `ModelName` | string | Auto-populated from VehicleDefinition |
| `ModelYear` | string | Auto-populated from VehicleDefinition |
| `Name` | string | Vehicle name (idLookup) |
| `OdometerReadingDate` | date | Date of most recent odometer reading |
| `OdometerReadingUomId` | reference → UnitOfMeasure | Odometer UOM |
| `OdometerState` | picklist | Use this; OdometerStatus being deprecated |
| `OdometerStatus` | picklist | Altered / ExceedsMechanicalLimit / Exempt / New / Normal / Replaced / Tampered |
| `RearRimSize / RearTireSize` | string | Rear wheel dimensions |
| `RegistrationRegionCode` | picklist | AZ / CA / IA / NJ / NY / TX |
| `RegistrationValidityDate` | date | Registration expiry date |
| `SourceSystemIdentifier` | string | External system unique ID (idLookup) |
| `SourceSystemName` | string | Source system name |
| `Status` | picklist | At Dealer Location / In Service / In Repair / In Manufacturing |
| `SteeringType` | string | Steering type |
| `StockCode` | string | Dealer inventory stock code |
| `TrimLevel` | string | Auto-populated from VehicleDefinition |
| `UpholsteryColor / UpholsteryType` | string | Interior upholstery details |
| `VehicleDefinitionId` | reference → VehicleDefinition | Required; links to model spec |
| `VehicleIdentificationNumber` | string | VIN — unique, idLookup |
| `VehicleRegistrationNumber` | string | Registration number (idLookup) |

---

## VehicleDefinition Object
`Available in API version 56.0+` — catalog/template record for a vehicle model

| Field | Type | Notes |
|---|---|---|
| `AccelerationTime` | string | 0–100 km/h time |
| `AuxiliaryBatteryType` | string | Auxiliary battery type |
| `BatteryCapacity` | string | Main battery capacity |
| `BodyType` | string | Hatchback, SUV, coupe, etc. |
| `CombinedFuelEconomy` | string | Urban + extra-urban fuel consumption |
| `CurbWeight` | string | Weight without payload |
| `DoorCount` | int | Number of doors |
| `DoorStyle` | picklist | Use this; DoorStyleType being deprecated |
| `DoorStyleType` | picklist | Butterfly / GullWing / Regular / Scissor |
| `DrivetrainSystem` | picklist | Use this; DrivetrainType being deprecated |
| `DrivetrainType` | picklist | AWD / FWD / FourWD / RWD |
| `EmissionStandard` | string | Emission standard |
| `EngineCubicCapacity` | string | Engine capacity |
| `EngineName` | string | Engine model |
| `ExternalReferenceNumber` | string | External ID for the model |
| `ExtraUrbanFuelEconomy` | string | Highway fuel consumption |
| `FuelSource` | picklist | Use this; FuelType being deprecated |
| `FuelTankCapacity` | string | Fuel tank size |
| `FuelType` | picklist | Battery / CNG / Diesel / Gasoline / Hybrid |
| `GeoCountryId` | reference → GeoCountry | Country of vehicle model |
| `Height / Length / Width / Wheelbase` | string | Vehicle dimensions |
| `MainBatteryType` | string | Main battery type |
| `MaximumBatteryRange / MinimumBatteryRange` | string | EV range limits |
| `MaximumGrossWeight` | string | GVWR |
| `MaximumTorque` | string | Peak torque |
| `ModelCode` | string | Model code |
| `Name` | string | Model name (idLookup) |
| `ProductId` | reference → Product2 | Linked product record |
| `TopSpeed` | string | Maximum speed |
| `TotalPower` | string | Maximum power |
| `TransmissionSystem` | picklist | Use this; TransmissionType being deprecated |
| `TransmissionType` | picklist | Automatic / Manual |
| `UrbanFuelEconomy` | string | City fuel consumption |
| `VariantName` | string | Variant name |
| `VehicleClass` | string | Vehicle classification |

---

## FinancialAccount Object
`Available in API version 60.0+` | **Requires:** Automotive and Vehicle and Asset Finance enabled

| Field | Type | Notes |
|---|---|---|
| `AmountDue` | currency | Amount due for payment |
| `AmountPastDue` | currency | Overdue payment amount |
| `BranchUnitId` | reference → BranchUnit | Captive finance unit |
| `ClosingDate` | date | Date account was closed |
| `CreditLimit` | currency | Total credit limit |
| `DaysPastDue` | int | Days past payment due date |
| `DownPaymentAmount` | currency | Initial down payment |
| `FinancialAccountNumber` | string | Account identifier |
| `InsurancePaidYearToDate` | currency | YTD insurance premium paid |
| `InterestPaidYearToDate` | currency | YTD interest paid |
| `InterestRate` | double | Loan/lease interest rate |
| `InterestType` | picklist | Fixed / Variable |
| `IsHeldAway` | boolean | Externally owned (default: false) |
| `IsOverdraftAllowed` | boolean | Overdraft allowed (default: false) |
| `MaturityDate` | date | Fixed-term maturity date |
| `Name` | string | Account name (idLookup) |
| `OpeningDate` | date | Date account was opened |
| `PaymentDueDate` | date | Next payment due date |
| `PrincipalAmount` | currency | Principal loan amount |
| `PrincipalPaidYearToDate` | currency | YTD principal paid |
| `ProductId` | reference → Product2 | Associated financial product |
| `RelatedFinancialAccountId` | reference → FinancialAccount | Parent account |
| `RemainingDuration` | int | Months to maturity/prepayment |
| `RenewalDate` | date | Renewal due date |
| `SourceSystemIdentifier` | string | External system ID (idLookup) |
| `Status` | picklist | Active / Closed / Delinquent / On Hold (default: Active) |
| `Term` | int | Loan/lease term in months |
| `TotalOutstandingAmount` | currency | Total outstanding balance |
| `Type` | picklist | Asset Lease / Asset Loan / Automotive Lease / Automotive Loan |

---

## Fleet Object
`Available in API version 59.0+`

| Field | Type | Notes |
|---|---|---|
| `ActiveAssetCount` | int | Roll-up count of active FleetAsset records (calculated) |
| `CurrentOwnerId` | reference → Account | Fleet owner |
| `EffectiveEndDate / EffectiveStartDate` | date | Fleet operational dates |
| `LocationId` | reference | Location of fleet |
| `Name` | string | Fleet name (idLookup) |
| `ParentFleetId` | reference → Fleet | Parent fleet for hierarchy |
| `Status` | picklist | Active / Inactive (default: Active) |
| `Type` | picklist | Commercial / Employee / Executive / Material |

---

## Claim Object
`Available in API version 58.0+` | **Requires:** Automotive and Warranty Lifecycle Management enabled

| Field | Type | Notes |
|---|---|---|
| `AccountId` | reference → Account | Account related to claim |
| `ClaimReason` | string | Reason for claim |
| `ClaimReasonType` | picklist | Accident / Natural Disaster |
| `ClaimType` | picklist | Pre Warranty Authorization / Warranty Claim (default: Warranty Claim) |
| `ClaimTypeCode` | picklist | PreWarrantyAuthorization / SupplierRecoveryClaim / WarrantyClaim |
| `FinalizedDate` | dateTime | Date claim was marked approved/rejected |
| `FnolChannel` | picklist | Chatbot / Mobile / Phone / Web |
| `IsClosed` | boolean | Claim closed flag (default: false) |
| `Name` | string | Claim number (idLookup) |
| `RelatedClaimId` | reference → Claim | Related claim |
| `Severity` | picklist | High / Low / Medium |
| `Status` | picklist | Approved / Draft / Manual Review Needed / Rejected / Requested Information / Submitted / Under Review (default: Draft) |
| `Summary` | textarea | Claim description |
| `TotalAdjustedAmount` | currency | Approved amount (calculated) |
| `TotalClaimedAmount` | currency | Total claimed amount (calculated) |
| `UsageType` | picklist | Automotive |

---

## Platform Object Extensions (Chapter 3)

### Asset (API v56.0+)
| Field | Type | Description |
|---|---|---|
| `VehicleId` | reference → Vehicle | Links Asset to a Vehicle record |

### Lead (API v56.0+)
| Field | Type | Description |
|---|---|---|
| `EarliestInterestDate` | date | Earliest date lead is interested in transaction |
| `LatestInterestDate` | date | Latest date lead is interested in transaction |

### Product2 (API v56.0+)
| Field | Type | Description |
|---|---|---|
| `AvailabilityDate` | dateTime | Date part is available for sale |
| `BusinessBrandId` | reference → BusinessBrand | Brand associated with vehicle |
| `DiscontinuedDate` | dateTime | Date part can no longer be sold |
| `HarmonizedSystemCode` | string | HS code for vehicle/part |
| `HarmonizedTariffSchedCode` | string | HTS code for vehicle/part |
| `IsCertified` | boolean | Certified accessory (default: false) |
| `IsEnvrPrtcRegCompliant` | boolean | Environment regulation compliant |
| `MakeName` | string | Vehicle make |
| `ManufacturerName` | string | Part manufacturer |
| `ManufacturerPartNumber` | string | Manufacturer part number |
| `ModelName` | string | Vehicle model name |
| `ModelYear` | int | Year model first launched |
| `ModelYearVersion` | int | Iteration within a model year |
| `ProductCategoryCode` | string | Part category code |
| `ProductLineCode` | string | Vehicle category for the part |
| `UniversalProductCode` | string | UPC for the part |
| `VehicleTrimLevel` | string | Supported trim levels |
| `VersionName` | string | Version name of model |

### ApplicationForm
| Field | Type | Description |
|---|---|---|
| `IntakeChannelType` | picklist | Channel application was received through |
| `TierType` | picklist | Bronze / Gold / Platinum / Silver |
| `TotalDebtToIncomePercent` | percent | Cumulative DTI for all applicants |
| `TotalIncomeToExpenseRatio` | double | Cumulative expense/income ratio |
| `TotalLoanToValuePercent` | percent | Cumulative LTV for all applicants |

### ApplicationFormProduct
| Field | Type | Description |
|---|---|---|
| `DownPayment` | currency | Down payment amount |
| `PartnerVisibleStatus` | picklist | Approved / Awaiting Signature / Contract Generation / Lender Approved / Lender Rejected / Loan Booked / Rejected / Submitted for review etc. |
| `RequestedMonthlyPayment` | currency | Requested monthly payment |
| `TotalBrandOwnedItemAmt` | currency | Total value of brand-owned items for financing |
| `TotalVendorOwnedItemAmt` | currency | Total value of vendor-owned items for financing |

### ApplicationFormProductProposal
| Field | Type | Description |
|---|---|---|
| `IsManualReviewRequired` | boolean | Manual review flag (default: false) |
| `ProposalGenerationMethod` | picklist | Automatic / Manual |

### ApplicationFormSellerItem
| Field | Type | Description |
|---|---|---|
| `AddlProductTermInMonths` | int | Additional product term in months |
| `IntendedUse` | picklist | Purpose of use for seller item |
| `IsAdditionalProduct` | boolean | Additional product flag (default: false) |
| `ItemCondition` | picklist | Condition of the seller item |

### BusinessProfile
| Field | Type | Description |
|---|---|---|
| `BusinessPartnerCode` | string | Unique business partner code |
| `BusinessPartnerRegisteredName` | string | Legal registered name |
| `BusinessPartnerType` | picklist | OEM / Sales Dealer / Service Dealer / Customer / Distributor / Financier / Importer / Third-Party Body Shop |
| `ExternalReferenceNumber` | string | Source system ID (idLookup, unique) |
| `RegionName` | picklist | California / Texas / Washington |
| `ServiceType` | multipicklist | Spare Parts Sales / Sales / Repair & Maintenance / Consultation |

---

## Key Relationships

```
VehicleDefinition (1) ──→ (many) Vehicle
Vehicle (1) ──→ (1) Asset [via Asset.VehicleId]
Asset (1) ──→ (many) AssetWarranty
Asset (1) ──→ (many) AssetTitle → AssetTitleParty
FinancialAccount (1) ──→ (many) FinancialAccountTransaction
FinancialAccount (1) ──→ (many) FinancialAccountParty
FinancialAccount (1) ──→ (1) RelatedFinancialAccount (parent)
Fleet (1) ──→ (many) FleetAsset [via FleetAsset.AssetId]
Fleet (1) ──→ (1) ParentFleet (hierarchy)
Lead (1) ──→ (many) LeadLineItem (vehicle interest)
Lead (1) ──→ (many) LeadPreferredSeller
Claim (1) ──→ (many) ClaimItem
Claim (1) ──→ (many) ClaimCoverage → ClaimCoveragePaymentDetail
TelemetryDefinition (1) ──→ (many) TelemetryDefinitionVersion
TelemetryDefinitionVersion (1) ──→ (many) TelemetryActionDefinition
TelemetryActionDefinition (1) ──→ (many) TelemetryActionDefStep → TelemetryActnDefStepAttr
```

---

## Complete Object Inventory (85 objects)

AccountAccountRelation, ActionableEventOrchestration, ActionableEventSubtype, ActionableEventType, ActionableEventTypeDef, ActionableOrchResponseEvent, ActionableOrchSourceEvent, Appraisal, AppraisalAdjustment, AppraisalItem, AppraisalItemAddOn, AppraisalItemProviderVal, AssessmentIndicatorDefinition, AssetAccountParticipant, AssetContactParticipant, AssetMilestone, AssetTitle, AssetTitleParty, AssetWarranty, Claim, ClaimCoverage, ClaimCoveragePaymentDetail, ClaimItem, ClaimParticipant, Codeset, CodesetRelationship, ContactContactRelation, DealerVehDefSearchableField, FinancialAccount, FinancialAccountAddress, FinancialAccountBalance, FinancialAccountFee, FinancialAccountMilestone, FinancialAccountParty, FinancialAccountStatement, FinancialAccountTransaction, FinclAcctPtyFinclAsset, Fleet, FleetAsset, FleetParticipant, GenericVisitTask, GenericVisitTaskContext, GnrcVstKeyPerformanceInd, GnrcVstTaskContextRelation, Holiday, LeadLineItem, LeadPreferredSeller, OpportunityPreferredSeller, PartyCreditPrflFinclAcct, PartyCreditProfileAlert, PartyCreditProfileInquiry, PartyFinancialAsset, PartyFinclAssetAddlOwner, PartyRelationshipGroup, PartyRoleRelation, ProductFaultCode, ProductLaborCode, ProductWarrantyTerm, PtyCrPrflFinclAcctActvty, RebateClaim, SellerProduct, ServiceAppointment, ServiceResourceSkill, ServiceTerritory, ServiceTerritoryMember, Skill, SkillRequirement, TelemetryActionDefinition, TelemetryActionDefStep, TelemetryActionRelatedProcess, TelemetryActnDefStepAttr, TelemetryDefinition, TelemetryDefinitionVersion, TimeSlot, TransactionJournal, Vehicle, VehicleDefinition, VehDefSearchableField, VehicleSearchableField, Visit, WarrantyTerm, WarrantyTermCoverage, WorkType, WorkTypeGroup, WorkTypeGroupMember
