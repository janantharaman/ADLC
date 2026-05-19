---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: data-model
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Data Model

## Overview

Retail Cloud's data model is exposed through its API, SPI, and Webhook layer rather than through native Salesforce objects (it is not a standard Salesforce CRM data model). The core entities are managed within the POS backend and CMS, with integration to external systems via SPIs and webhooks.

---

## Core Entities

### Orders
The order data model was updated in June 2024 to use a transaction data model for exporting and importing store transactions.

**Key order fields:**
- `orderProductList` — all products sold in the order (inclusive of returns/exchanges)
- `productList` — products minus returns/exchanges (remaining products not returned)
- `returnProductList` — returned or exchanged products
- `omniFulfillmentType` — fulfillment classification for omnichannel scenarios
- `fulfillmentType` — fulfillment type for cash/carry/charge scenarios
- `fulfillmentSubType` — sub-classification of fulfillment type

**Field mapping guidance:**
- For ERP integration: use `orderProductList` and `returnProductList` (NOT `productList`) to simplify ingestion logic
- For ERP cash/carry/charge mapping: use `fulfillmentType` and `fulfillmentSubType` (NOT `omniFulfillmentType`)

**Order types supported:**
- Standard sale/return/exchange
- BORIS (Buy Online Return In Store)
- BOPIS (Buy Online Pickup In Store)
- BOFIS (Buy Online Fulfill In Store)
- ROPIS (Reserve Online Pickup In Store)

### Customer (Clienteling SPI Data Model)
The customer entity is managed in the merchant's external system and surfaced via the Clienteling SPI.

**Key customer fields:**
- `profile.customerId` — unique customer identifier (used in UPDATE_CUSTOMER SPI to identify existing customer)
- `currentLoyaltyProfile.currentTier.expiryDate` — loyalty tier expiry in epoch milliseconds
- `addressList` — list of customer addresses (DEPRECATED in CREATE/UPDATE requests; still returned in GET responses)
- `loyaltyProfile` — current loyalty profile (replaces deprecated `customerLoyaltyProfile`)
- `customerLoyaltyProfile` — DEPRECATED (use `loyaltyProfile` instead)

### Products
Products are managed in the POS system via the Product API.

**Product API fields:**
- Standard product metadata (name, description, images, pricing)
- Custom product attributes configurable via `spiCustomProductAttributes` setting in CMS
- Product IDs used across multiple APIs (up to 20 product IDs per inventory query)

**Custom product attributes for SPIs:**
- Configured in CMS: Store Management > Store Settings > Product
- Setting name: `spiCustomProductAttributes`
- Format: comma-separated, case-insensitive list
- Example values: `variantGroupId`, `salePrice`, `manufacturer`, `brand`
- These attributes are included in SPI responses when configured

### Store Products (Store Inventory)
Represents product-store combinations with inventory and pricing.

**Key fields:**
- List price
- Sale price
- Quantity
- Promo banner text
- Store-specific inventory levels

**Inventory query constraints:**
- `productIds`: required, comma-separated, maximum 20 product IDs
- `storeIds`: optional, comma-separated, maximum 1,000 store IDs; defaults to all stores if empty/null

### Store Associates
**Key fields:**
- `associateId` — unique associate identifier
- `storeId` — store assignment
- `active` — boolean; DELETE operation sets this to `false` (deactivation, not physical deletion)

### CMS Users
Managed separately from store associates; represent administrative users of the CMS portal.

---

## Date/Time Format

All date fields use **epoch time in milliseconds** (integer data type):
- Format: number of milliseconds elapsed since January 1, 1970, 00:00:00 UTC
- Example: 2023-01-15 08:30:00 UTC = `1642246200000`
- Applies to: all SPI request and response date fields (e.g., `currentLoyaltyProfile.currentTier.expiryDate`)

---

## SPI Response Data Model Conventions

### Null Field Handling
- Non-nullable or unused fields should be **omitted entirely** from responses
- Do NOT set unused fields to `null` — exclude them from the response
- This applies when a 200 status is returned with an empty or partial result

### Error Response Format
```json
{
  "errorCode": "<error_code>",
  "errorMessage": "<i18n message based on request locale>"
}
```
- Error messages must be internationalized (i18n) based on the region and locale of the app request
- HTTP status 400 for exception conditions
- HTTP status 401 for authentication failures (empty body)
- HTTP status 404 or 200 with error fields are both acceptable for "resource not found" scenarios

### Webhook Failure Detection
A webhook export is considered failed when:
1. HTTP response status code is 4xx or 5xx
2. HTTP response status code is 2xx BUT the payload contains either:
   - `errorMessage` field
   - `errorCode` field

---

## Delivery Group Data Model
When using Delivery Group SPI with GET_ORDER_DETAIL, the SPI response must include a `DeliveryGroup` list.

---

## Single Use Promotion Codes (SUPC) Data Model
- Associated with a specific promotion via `promotionId`
- Status can be "redeemed" (by external system)
- Operations: create SUPCs, retrieve list, update redemption status

---

## Inventory Management System (IMS) Data Model
IMS entities:
- **ASN (Advance Shipping Notice)** — incoming shipment data
- **Cycle Count** — inventory counting operations (full, manual, partial)
  - Full cycle count: complete inventory count of all products in a store
  - Manual cycle count: counting of a specific set of products
  - Partial cycle count: counting products in a specific category, brand, or other attribute
- **Purchase Order (PO)** — purchase order tracking

**Cycle Count States:**
- `CYC_COUNT_CREATED_EVENT`
- `CYC_COUNT_STARTED_EVENT`
- `CYC_COUNT_COMPLETED_EVENT`
- `CYC_COUNT_CANCELED_EVENT`

**ASN States:**
- `ASN_RECEIVED_EVENT`
- `ASN_PARTIALLY_RECEIVED_EVENT`
- `ASN_RECEIVE_COMPLETED_EVENT`

**PO States:**
- `PO_TRANSFER_STARTED_EVENT`
- `PO_TRANSFER_COMPLETED_EVENT`
- `PO_TRANSFER_ERRORED_EVENT`

**Inventory Transfer Types:**
- `INVENTORY_EXPORT_ASN` — ASN data
- `INVENTORY_EXPORT_STS` — Store-to-store transfers
- `INVENTORY_EXPORT_RTV` — Return-to-vendor
- `INVENTORY_EXPORT_CTS` — Customer-to-store
- `INVENTORY_EXPORT_BLD` — Build/assembly
- `INVENTORY_EXPORT_INA` — Inventory adjustments
- `INVENTORY_EXPORT_INBA` — Inventory bucket adjustments
- `INVENTORY_EXPORT_CYC` — Cycle count data
- `INVENTORY_EXPORT_PO` — Purchase order data
- `SALE_INVENTORY` — Sales transaction inventory (sold items → inventory decreases)
- `RETURN_INVENTORY` — Return transaction inventory (returned items → inventory increases/adjusts)

---

## Payment Data Model
- Customer Profile and Wallet: supports card-on-file and payment imprint functionality (added in recent release)
- Payment cards: searchable via the Search Orders SPI using card number mapped to payment card section fields

---

## API Versioning
- Current version: `v1`
- API version is specified in the path: `/merchant/{version}/...`
- SPI version specified as URL prefix: `/<api_version>/...`
- `api_version` must be consistent across all requests to a particular SPI implementation (cannot mix 1.0 and 1.1)
