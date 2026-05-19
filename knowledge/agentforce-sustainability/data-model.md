# Agentforce Sustainability (Net Zero Cloud) — Data Model

## Architecture Overview

Net Zero Cloud uses a standard Salesforce object model — all objects are queryable via SOQL, deployable via Metadata API, and visible in Schema Builder. There is no separate data lake layer (unlike Data 360).

```
Emission Sources (what emits)
    └── Carbon Footprint records (measured emissions)
            └── Emission Factor (conversion rates)
                    └── Emission Factor Set (grouped by standard/region)

Organisation Hierarchy
    └── Organisation Unit (business entity)
            └── Value Chain Partner (suppliers, subsidiaries)
                    └── Partner Footprint (submitted Scope 3 data)

Targets and Initiatives
    └── Sustainability Goal (net zero target)
            └── Sustainability Programme (initiative to achieve goal)
```

---

## Core Standard Objects

### Carbon Footprint (`CarbonFootprint`)
The central record — one per emission event or reporting period.

| Field | Type | Description |
|---|---|---|
| `EmissionSource` | Lookup | What generated the emission |
| `OrganisationUnit` | Lookup | Which business unit |
| `ReportingPeriod` | Date Range | Period the footprint covers |
| `Scope` | Picklist | Scope1, Scope2, Scope3 |
| `EmissionCategory` | Picklist | Category per GHG Protocol (e.g., Stationary Combustion) |
| `TotalEmissions` | Number | Total CO₂e (tonnes) |
| `ActivityData` | Number | Raw consumption (kWh, km, litres, etc.) |
| `ActivityDataUnit` | Picklist | Unit of measurement |
| `EmissionFactor` | Lookup | Factor used for calculation |
| `CalculationMethod` | Picklist | Spend-based, Activity-based, Supplier-specific |
| `DataQualityIndicator` | Picklist | Measured, Estimated, Default |

### Emission Source (`EmissionSource`)
Defines what produces emissions (a building, vehicle fleet, production line).

| Field | Type | Description |
|---|---|---|
| `Category` | Picklist | Stationary Combustion, Mobile Combustion, etc. |
| `Scope` | Picklist | Scope1 / Scope2 / Scope3 |
| `OrganisationUnit` | Lookup | Owning business unit |
| `EmissionSubcategory` | Picklist | GHG Protocol sub-category |

### Emission Factor (`EmissionFactor`)
Converts activity data to CO₂e. e.g., 1 kWh electricity = 0.233 kgCO₂e.

| Field | Type | Description |
|---|---|---|
| `EmissionFactorSet` | Lookup | Parent dataset (e.g., UK DEFRA 2024) |
| `ActivityType` | Picklist | Electricity, Natural Gas, Air Travel, etc. |
| `CO2Factor` | Number | kg CO₂ per unit of activity |
| `CH4Factor` | Number | kg CH4 per unit (methane) |
| `N2OFactor` | Number | kg N₂O per unit (nitrous oxide) |
| `Unit` | Picklist | kWh, litre, km, etc. |
| `EffectivePeriod` | Date Range | Validity period |
| `Region` | Text | Geographic scope (UK, US, EU, Global) |

### Emission Factor Set (`EmissionFactorSet`)
Groups emission factors by regulatory source or standard.
Examples: UK DEFRA, US EPA, IEA, GHG Protocol, IPCC AR6.

### Organisation Unit (`OrgUnit__c` / custom)
Represents a business entity (subsidiary, division, plant, office). Forms the hierarchy for footprint aggregation and multi-org consolidation.

### Sustainability Goal (`SustainabilityGoal`)
Net zero targets and interim reduction milestones.

| Field | Type | Description |
|---|---|---|
| `BaselineYear` | Number | Reference year for % reduction |
| `TargetYear` | Number | Year to achieve the goal |
| `ReductionTarget` | Percent | % reduction from baseline |
| `TargetScope` | Picklist | Scope1, Scope2, Scope3, All |
| `Status` | Picklist | On Track, At Risk, Achieved |

### Sustainability Programme (`SustainabilityProgramme`)
Individual initiatives (e.g., solar panel installation, EV fleet transition).

| Field | Type | Description |
|---|---|---|
| `Goal` | Lookup | Parent sustainability goal |
| `ExpectedEmissionsReduction` | Number | Forecasted CO₂e reduction (tonnes) |
| `MarginalAbatementCost` | Currency | Cost per tonne CO₂e reduced |
| `Status` | Picklist | Planned, In Progress, Completed |

### Value Chain Partner (`ValueChainPartner`)
Represents a supplier, subsidiary, franchisee, or distributor contributing to Scope 3.

### Partner Footprint (`PartnerFootprint`)
Scope 3 data submitted by a Value Chain Partner via the external portal.

---

## ESG Reporting Objects

### Disclosure (`Disclosure`)
Stores a complete ESG report instance tied to a specific framework (CSRD, GRI, SASB, CDP).

### Disclosure Topic (`DisclosureTopic`)
A reportable topic within a framework (e.g., GHG emissions, water usage, waste).

### Disclosure Data Point (`DisclosureDataPoint`)
A single quantitative or qualitative data point within a topic.

---

## Emission Category Reference (GHG Protocol)

**Scope 1:**
- Stationary Combustion (boilers, furnaces)
- Mobile Combustion (company vehicles)
- Fugitive Emissions (refrigerants, leaks)
- Process Emissions (industrial processes)

**Scope 2:**
- Purchased Electricity (location-based and market-based methods)
- Purchased Heat/Steam/Cooling

**Scope 3 (15 categories):**
- Cat 1: Purchased Goods & Services
- Cat 2: Capital Goods
- Cat 3: Fuel and Energy-Related Activities
- Cat 4: Upstream Transportation & Distribution
- Cat 5: Waste Generated in Operations
- Cat 6: Business Travel
- Cat 7: Employee Commuting
- Cat 8: Upstream Leased Assets
- Cat 9: Downstream Transportation & Distribution
- Cat 10: Processing of Sold Products
- Cat 11: Use of Sold Products
- Cat 12: End-of-Life Treatment of Sold Products
- Cat 13: Downstream Leased Assets
- Cat 14: Franchises
- Cat 15: Investments

---

## Key Relationships

```
SustainabilityGoal
  └── SustainabilityProgramme (M:1 → Goal)

OrganisationUnit
  └── EmissionSource (M:1 → OrgUnit)
  └── CarbonFootprint (M:1 → OrgUnit)
  └── ValueChainPartner (M:1 → OrgUnit)

EmissionSource
  └── CarbonFootprint (M:1 → EmissionSource)

EmissionFactorSet
  └── EmissionFactor (M:1 → Set)

CarbonFootprint
  └── EmissionFactor (M:1 → Factor)
```
