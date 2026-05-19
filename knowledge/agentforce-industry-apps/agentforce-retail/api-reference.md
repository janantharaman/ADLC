---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: api-reference
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — API Reference

## API Endpoints (Non-Hyperforce)

### Base URLs
- **Staging:** `https://api.predictspring.com/staging/service`
- **Production:** `https://api.predictspring.com/prod/service`

### OAuth2 Endpoints
- **Staging:** `https://staging-oauth2.predictspring.com/oauth2/token`
- **Production:** `https://prod-oauth2.predictspring.com/oauth2/token`

---

## Hyperforce API Endpoints

Environment-specific URLs with x-salesforce-region values:

| Environment | Type | x-salesforce-region |
|-------------|------|---------------------|
| Production | Non-sandbox | us-east-2 or us-west-2 |
| Production | Sandbox | us-east-2 or us-west-2 |
| Staging | Non-sandbox | us-east-2 or us-west-2 |
| Staging | Sandbox | us-east-2 or us-west-2 |
| Test | — | us-east-2 or us-west-2 |
| Dev | — | us-east-2 or us-west-2 |

**Hyperforce Token Endpoint:**
```
POST <my-domain-url>/services/oauth2/token?grant_type=client_credentials
```

---

## Required Request Headers

### Non-Hyperforce Headers
```
PredictSpring-Secret: <encrypted-credential>
PredictSpring-Token: <oauth-access-token>
X-api-key: <merchant-api-key>
Content-Type: application/json
```

### Hyperforce Headers
```
Authorization: Bearer <access-token>
Content-Type: application/json
x-salesforce-region: <us-east-2 or us-west-2>
x-locale: <merchant-specific-locale>
x-region: <merchant-specific-region>
```

---

## Complete API Endpoint Reference

### CMS Users — `/merchant/{version}/users`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/merchant/{version}/users` | Retrieve all CMS users |
| PUT | `/merchant/{version}/users` | Update a CMS user |
| POST | `/merchant/{version}/users` | Create CMS users |
| DELETE | `/merchant/{version}/users` | Delete a CMS user |
| GET | `/merchant/{version}/users/{userId}` | Retrieve CMS user by userId |

### Inventory Management System — `/merchant/{version}/ims`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/merchant/{version}/ims/inventory/asn` | Create ASN in IMS |
| PUT | `/merchant/{version}/ims/inventory/cyclecount/cancel` | Cancel a cycle count |
| POST | `/merchant/{version}/ims/inventory/cyclecount/full` | Create full cycle count |
| POST | `/merchant/{version}/ims/inventory/cyclecount/manual` | Create manual cycle count |
| POST | `/merchant/{version}/ims/inventory/cyclecount/partial` | Create partial cycle count for category/brand/attribute group |

### Notifications — `/merchant/{version}/notifications`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/merchant/{version}/notifications` | Schedule immediate notifications to target devices |

**Parameters:**
- Target: installation ID or email address
- Events: order shipped, cart abandoned, etc.

### Products — `/merchant/{version}/products`

| Method | Path | Description |
|--------|------|-------------|
| PUT | `/merchant/{version}/products` | Update products |
| POST | `/merchant/{version}/products` | Create products |
| DELETE | `/merchant/{version}/products` | Delete products |

**Constraint:** No "region" field — cannot be used for multi-region pricing.

### Promotions — `/merchant/{version}/promotions`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/merchant/{version}/promotions` | Retrieve all promotions |
| PUT | `/merchant/{version}/promotions` | Update promotions |
| POST | `/merchant/{version}/promotions` | Create promotions |
| GET | `/merchant/{version}/promotions/download/report` | Download all CMS-created promotions report (active + inactive) |
| POST | `/merchant/{version}/promotions/upload` | Upload promotions via JSON file |
| GET | `/merchant/{version}/promotions/{promotionId}` | Retrieve promotion by ID |
| DELETE | `/merchant/{version}/promotions/{promotionId}` | Delete promotion by ID |
| GET | `/merchant/{version}/promotions/{promotionId}/supc` | Retrieve SUPC list for a promotion |
| PUT | `/merchant/{version}/promotions/{promotionId}/supc` | Update SUPC redemption status |
| POST | `/merchant/{version}/promotions/{promotionId}/supc` | Create/send new valid SUPCs |

### Store Associates — `/merchant/{version}/associates`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/merchant/{version}/associates` | Retrieve associates by `storeId` and `associateId` query params |
| PUT | `/merchant/{version}/associates` | Update a store associate |
| POST | `/merchant/{version}/associates` | Create a store associate |
| DELETE | `/merchant/{version}/associates` | Deactivate associate (sets `active` to `false`) |
| GET | `/merchant/{version}/associates/{associateId}` | Retrieve associate by associateId |

### Store Products/Inventory — `/merchant/{version}/storeproducts`

| Method | Path | Description |
|--------|------|-------------|
| PUT | `/merchant/{version}/storeproducts` | Update store product (list price, sale price, quantity, promo banner) |
| GET | `/merchant/{version}/storeproducts/inventory` | Get store inventory for product/store IDs |
| PUT | `/merchant/{version}/storeproducts/inventory` | Update store or E-comm inventory |
| POST | `/merchant/{version}/storeproducts/inventory` | Create store or E-comm inventory (incremental) |
| GET | `/merchant/{version}/storeproducts/inventory/{storeId}` | Get CSV URL for store inventory |

**GET storeproducts/inventory Query Parameters:**
- `productIds` (required): comma-separated, max 20 product IDs
- `storeIds` (optional): comma-separated, max 1,000 store IDs; defaults to all stores if empty/null

### Orders — `/merchant/{version}/sa/orders`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/merchant/{version}/sa/orders` | Create order |
| POST | `/merchant/{version}/sa/orders/repost` | Repost orders to external system by list of order IDs |
| POST | `/merchant/{version}/sa/orders/search` | Search and retrieve orders |
| GET | `/merchant/{version}/sa/orders/{id}` | Retrieve order by ID |

---

## Complete SPI Reference

### SPI Base URL Pattern
```
Staging:    https://<staging_path>/<api_version>/<api_path>?api_key={API_KEY}
Production: https://<production_path>/<api_version>/<api_path>?api_key={API_KEY}

Example:
https://staging.mycompany.com/spi/1.0/customer/1234?api_key=ibafw4ehb2vhibdsih3vbadv
https://www.mycompany.com/spi/1.0/customer/1234?api_key=zmcnv9lzjkxn2vcl8nzcx
```

### Customer SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| POST `/merchant/spi/sample/endpoint/sa/customers` | `CREATE_CUSTOMER` | HTTP_POST |
| PUT `/merchant/spi/sample/endpoint/sa/customers` | `UPDATE_CUSTOMER` | HTTP_PUT |
| GET `/merchant/spi/sample/endpoint/sa/customers/{customerId}` | `GET_CUSTOMER` | HTTP_GET |
| GET `/merchant/spi/sample/endpoint/sa/customers` | `SEARCH_CUSTOMERS` | HTTP_GET |
| GET `/merchant/spi/sample/endpoint/sa/customers` | `CUSTOMER_INTERACTION_HISTORY` | HTTP_GET — **LEGACY, DO NOT USE** |
| GET `/merchant/spi/sample/endpoint/sa/customers` | `GET_ORDER_LIST` | HTTP_GET — **LEGACY, DO NOT USE** |

### Customer Address SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| GET `/merchant/spi/sample/endpoint/sa/customer/address` | `GET_CUSTOMER_ADDRESSES` | HTTP_GET |
| PUT `/merchant/spi/sample/endpoint/sa/customer/address` | `UPDATE_CUSTOMER_ADDRESS` | HTTP_PUT |
| POST `/merchant/spi/sample/endpoint/sa/customer/address` | `CREATE_CUSTOMER_ADDRESS` | HTTP_POST |
| DELETE `/merchant/spi/sample/endpoint/sa/customer/address` | `DELETE_CUSTOMER_ADDRESS` | HTTP_DELETE |

### Inventory SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| POST `/merchant/spi/sample/endpoint/sa/inventoryService/revert` | `INVENTORY_SERVICE` | HTTP_POST |
| POST `/merchant/spi/sample/endpoint/sa/inventory/to/check/inventory/from/external/system` | `ONLINE_ITEM_INVENTORY_CHECK` | HTTP_POST |
| POST `/merchant/spi/sample/endpoint/product/getInventoryOverview` | `GET_PRODUCT_INVENTORY_OVERVIEW` | HTTP_POST |

### Loyalty SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| POST `/merchant/spi/sample/endpoint/sa/getLoyaltyPoints` | `LOYALTY_POINTS_EARNED` | HTTP_POST |
| POST `/merchant/spi/sample/endpoint/reward/lookup` | `REWARD_LOOKUP` | HTTP_POST |

### Orders SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| GET `/merchant/spi/sample/endpoint/sa/orders/to/get/order/from/external/system/{orderId}` | `GET_ORDER_DETAIL` | HTTP_GET |
| GET `/merchant/spi/sample/endpoint/sa/orders/to/get/boris/order/from/external/system/{orderId}` | `BORIS_GET_ORDER_DETAIL` | HTTP_GET |
| POST `/merchant/spi/sample/endpoint/sa/orders/to/search/orders/from/external/system` | `SEARCH_ORDERS` | HTTP_POST |
| POST `/merchant/spi/sample/endpoint/sa/orders/to/export/return/order/to/external/system` | `RETURN` | HTTP_POST |

### Other SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| POST `/merchant/spi/sample/endpoint/sa/cartValidation` | `CART_VALIDATION` | HTTP_POST |
| POST `/merchant/spi/sample/endpoint/sa/datetime/slots/from/external/system` | `DATE_PICKER` | HTTP_POST |
| POST `/merchant/spi/sample/endpoint/sa/employee/verification/to/verify/employee/from/external/system` | `VERIFY_EMPLOYEE` | HTTP_POST |

### Shipping Methods SPI

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| POST `/merchant/spi/sample/endpoint/sa/shipping/methods` | Merchant-defined | HTTP_POST |

### Tax SPIs

| SPI Endpoint | Endpoint Name | Integration Type |
|-------------|--------------|-----------------|
| POST `/merchant/spi/sample/endpoint/taxEngine/calculateTax` | `TAX_SERVICE` | HTTP_POST |
| GET `/merchant/spi/sample/endpoint/taxEngine/downloadTaxRates` | `TAX_SERVICE` | HTTP_GET |
| POST `/merchant/spi/sample/endpoint/taxEngine/finalizeTaxSubmission` | `TAX_SERVICE` | HTTP_POST |
| GET `/merchant/spi/sample/endpoint/taxEngine/getTaxExemptions` | `TAX_SERVICE` | HTTP_GET |

### New SPIs (Recent Release)

| SPI | CMS API Key | Operations |
|-----|------------|------------|
| Gift Card SPI | `GIFT_CARD_SERVICE` | Balance check, activation, add funds, redemption, void, reversal |
| Warranty SPI | `WARRANTY_LOOKUP` | Eligibility check for warranty products in cart |
| Quote SPI | (TBD) | Quote management operations |

---

## Complete Webhook Reference

### Webhook Endpoint Names

| Category | Endpoint Name | Integration Type | Trigger |
|----------|--------------|-----------------|---------|
| eReceipt | `ERECEIPT_CUSTOMER` | HTTP_POST | Order completed |
| Inventory | `INVENTORY_EXPORT_ASN` | HTTP_POST | ASN events |
| Inventory | `INVENTORY_EXPORT_STS` | HTTP_POST | Store-to-store transfer events |
| Inventory | `INVENTORY_EXPORT_RTV` | HTTP_POST | Return-to-vendor events |
| Inventory | `INVENTORY_EXPORT_CTS` | HTTP_POST | Customer-to-store events |
| Inventory | `INVENTORY_EXPORT_BLD` | HTTP_POST | Build/assembly events |
| Inventory | `INVENTORY_EXPORT_INA` | HTTP_POST | Inventory adjustments |
| Inventory | `INVENTORY_EXPORT_INBA` | HTTP_POST | Inventory bucket adjustments |
| Inventory | `INVENTORY_EXPORT_CYC` | HTTP_POST | Cycle count events |
| Inventory | `INVENTORY_EXPORT_PO` | HTTP_POST | Purchase order events |
| Inventory | `SALE_INVENTORY` | HTTP_POST | Item sold |
| Inventory | `RETURN_INVENTORY` | HTTP_POST | Item returned/exchanged |
| Orders | `ORDER` | HTTP_POST | Sale completed |
| Orders | `ORDER_UPDATE` | HTTP_POST | Order updated |
| Orders | `BOPIS_EXPORT` | HTTP_POST | BOPIS order |
| Orders | `BOFIS_EXPORT` | HTTP_POST | BOFIS order |
| Orders | `ROPIS_EXPORT` | HTTP_POST | ROPIS order |
| Orders | `RETURN` | HTTP_POST | Return/BORIS |
| Others | `VOID_CART` | HTTP_POST | Cart voided |
| Others | `SUSPEND_CART` | HTTP_POST | Cart suspended |
| Others | `POS_CRASH_DATA` | HTTP_POST | Register crash |
| Others | `POS_VITALS` | HTTP_POST | Register vitals reporting |
| Others | `EXPORT_MONITORING_EVENTS` | HTTP_POST or HTTP_PUT | Integration health monitoring |
| New | Promotion Events Webhook | HTTP_POST | Promotion events |

---

## SPI Error Response Schema
```json
HTTP/1.1 400 Bad Request
{
  "errorCode": "<error_code>",
  "errorMessage": "<localized error message>"
}
```

SPI Authentication Failure:
```
HTTP/1.1 401 Unauthorized
(empty body)
```

---

## Webhook Failure Detection

A webhook is marked failed when:
1. HTTP response is 4xx or 5xx, OR
2. HTTP response is 2xx BUT payload contains `errorMessage` or `errorCode` fields

Example failure with 200 status:
```json
HTTP 200 OK
{
  "errorCode": "ORDER_EXPORT_FAILED",
  "errorMessage": "Unable to process order"
}
```

---

## Full API Specification Reference

The full POS API OpenAPI specification is available at:
`https://developer.salesforce.com/docs/commerce/retail-cloud/references/pos-oas?meta=Summary`

Individual SPI specifications:
- Gift Card SPI: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/gift-card-spi?meta=Summary`
- Warranty SPI: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/warranty-spi?meta=Summary`
- Quote SPI: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/quote-spi?meta=Summary`
- Promotion Events Webhook: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/promotion-events-webhook?meta=Summary`
- Store Group Management API: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/store-group-management-api?meta=Summary`
- Clienteling SPI: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/clienteling-spi?meta=Summary`
- Delivery Group SPI: `https://developer.salesforce.com/docs/commerce/retail-cloud/references/delivery-group-spi?meta=Summary`

**Note:** These reference pages use a JavaScript-rendered Redoc/Swagger UI and require a browser to view the full API schemas. They are not accessible via static web crawling.

---

## Rate Limits

| Environment | Per-Second | Per-Month |
|-------------|-----------|----------|
| Production | 10 requests/second | 100,000 requests/month |
| Staging | Not specified | 10,000 requests/month |

For higher rate limits, contact Salesforce Customer Support.
