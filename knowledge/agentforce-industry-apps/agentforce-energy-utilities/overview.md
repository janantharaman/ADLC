---
source: Salesforce Energy and Utilities Cloud Developer Guide (Atlas JSON API, Summer '26 / API v67.0); salesforceben.com E&U Complete Guide; Vlocity Build GitHub (vlocityinc/vlocity_build); Vlocity Communications Object List Spring '21; EPC Guide; CLM Guide; ASLM Guide; TM Forum alignment docs; grounded 2026-05-12
cloud: Energy and Utilities Cloud
section: overview
last-updated: 2026-05-12
---

# Energy and Utilities Cloud — Overview

## What It Is

Salesforce Energy and Utilities Cloud (E&U Cloud) is a dynamic management platform for the energy and utilities landscape. It serves power utilities, gas utilities, water utilities, oil and gas, and green/renewable energy sectors with unified customer data, personalized service capabilities, and full asset and workforce lifecycle management.

**Formerly:** Vlocity Energy — acquired by Salesforce in 2020.

**Managed package namespace:** `vlocity_cmt` — the same managed package that powers Communications Cloud and Media Cloud. The official package name is "Salesforce Industries Communications, Media, Energy & Utilities (CME)."

---

## Industry Segments Served

| Segment | Use Cases |
|---|---|
| Electric / Power Utilities | Customer service, billing account management, outage management, field operations |
| Gas Utilities | Service agreements, meter reading, safety programs, field dispatch |
| Water Utilities | Usage tracking, service point management, program enrollment |
| Oil & Gas | Contract lifecycle, asset management, partner relationships |
| Green / Renewable Energy | Energy program management, usage impact measurement, sustainability reporting |
| Retail Energy (Deregulated) | Multi-site quote and order capture, competitive rate comparison, CPQ |

---

## Core Capability Domains

| Domain | Description |
|---|---|
| **CPQ (Configure-Price-Quote)** | Multi-site quote and order capture; competitive rate comparison; attribute-based pricing; promotion management |
| **Enterprise Product Catalog (EPC)** | Commercial + technical product catalog; TM Forum PSR model; versioned product specifications and offerings |
| **Order Management (OM)** | End-to-end order fulfillment; orchestration plans; decomposition to technical tasks; manual queue handling |
| **Contract Lifecycle Management (CLM)** | Contract creation from Opp/Quote/Order; document generation; DocuSign integration |
| **Customer Interaction** | Omnichannel contact center console; 360° customer view; digital self-service portal |
| **Energy Programs** | Program enrollment (residential/commercial); benefit disbursement; usage impact measurement; efficiency reporting |
| **Asset Service Lifecycle (ASLM)** | Asset hierarchy; advanced exchange; depot repair; inventory management; product service campaigns |
| **Workforce Management** | Timesheet management; labor cost optimization; union compliance; pay grade/type/period management |
| **Digital Commerce (DC)** | Self-serve portal; shopping cart; online ordering |
| **Document Generation (DocGen)** | Word/PDF document generation from templates; DocuSign integration |

---

## Solution Stack Architecture

```
External Systems (CIS, Billing, IVR, CTI, eSignature, ERP)
        ↓ (Integration Procedures + Named Credentials)
Salesforce Core Platform (Sales Cloud + Service Cloud + FSL)
        ↓
Industry Data Model (vlocity_cmt__ namespace objects)
        ↓
OmniStudio (OmniScript + FlexCard + DataRaptor + Integration Procedure)
        ↓
EPC + CPQ + OM + CLM + DocGen + Digital Commerce
        ↓
Customer-facing: Experience Cloud sites / OmniOut external deployment
```

---

## Package and Licensing

### Namespace
All managed objects use the `vlocity_cmt__` prefix. In source-controlled form, the namespace placeholder `%vlocity_namespace%__` is used and replaced at runtime.

**New customers (Spring '22+):** Permission Set Licenses (PSLs) per module:
| Module | PSL Name |
|---|---|
| CPQ | CPQ PSL |
| EPC | EPC PSL |
| Order Management | OM PSL |
| Contract Lifecycle Management | CLM PSL |
| Document Generation | DocGen PSL |
| Digital Commerce | DC PSL |

**Pre-Spring '22 / upgrading customers:** Continue with managed package licenses until contract renewal.

### Supported Editions
Enterprise, Performance, Unlimited, and Developer Editions with Energy and Utilities Cloud add-on.

### Required Base Features
- Sales Cloud or Service Cloud (core platform)
- Field Service (for ASLM / workforce features)
- OmniStudio (now GA in E&U Cloud; was previously installed separately as Vlocity)

---

## OmniStudio Dependency

OmniStudio is a **required runtime** for Energy and Utilities Cloud. All guided customer interactions (CPQ wizards, enrollment flows, service request scripts) are built as OmniScripts. All UI components (360° views, program dashboards, asset hierarchies) are built as FlexCards. All data integration (billing imports, CIS queries, product catalog enrichment) runs through DataRaptors and Integration Procedures.

OmniStudio is GA in E&U Cloud since Summer '19 (Integration Procedures with secure cache) and fully LWC-based since Spring '22.

---

## TM Forum Alignment

| Certification | Year | Standard |
|---|---|---|
| SID Certification — EPC | 2022 | TM Forum Information Framework (SID) |
| eTOM & SID — Industries CPQ + OM | 2023 | eTOM + SID |
| Gold Badge — Open API | 2025 | TM Forum Open API |
| "Ready for ODA" | 2024 | Open Digital Architecture |
| Product Catalog API | — | TMF620 Product Catalog Management API compliant |

The E&U data model follows the TM Forum **PSR (Product-Service-Resource)** hierarchy for commercial-to-technical decomposition.

---

## Typical Integrations

| System Type | Integration Method |
|---|---|
| CIS / Billing systems | Integration Procedures + Named Credentials + DataRaptor Interface objects |
| Field Service / Dispatch | Salesforce Field Service (native FSL integration) |
| IVR / CTI / SMS | Service Cloud Voice / Open CTI (CTI adapter) |
| Marketing Cloud | Marketing Cloud connector |
| eSignature | DocuSign (VlocityDocuSignTemplate__c) |
| External REST APIs | Integration Procedures with HTTP Action steps + Named Credentials |
| SAP / ERP | DataRaptor Transform + Integration Procedure HTTP callout or middleware |

---

## Prebuilt Vlocity Application Modules

| Module | Description |
|---|---|
| Contact Center Console | Unified agent portal for customer service; 360° account view; interaction logging |
| Customer Acquisition Management | Rate comparison automation; competitive quoting for deregulated markets |
| Large Account Sales Management | Deal acceleration for C&I (commercial and industrial) customers |
| Utility Self-Serve Portal | Customer self-service Experience Cloud site; account management, bills, outage reporting |

---

## API Version Reference

| Release | API Version | E&U Doc Version |
|---|---|---|
| Summer '26 | 67.0 | 262.0 |
| Spring '26 | 66.0 | 260.0 |
| Winter '26 | 65.0 | 258.0 |
| Summer '25 | 64.0 | 256.0 |
| Spring '25 | 63.0 | 254.0 |
| Winter '25 | 62.0 | 252.0 |

Developer Guide PDF (Summer '26): `https://resources.docs.salesforce.com/262/latest/en-us/sfdc/pdf/eu_developer_guide.pdf`
