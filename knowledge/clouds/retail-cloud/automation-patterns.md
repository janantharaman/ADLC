---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: automation-patterns
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Automation Patterns

## Architecture Overview

Retail Cloud automation is driven by three integration patterns:
1. **APIs** — inbound calls TO Point of Sale from merchant backend systems
2. **SPIs (Service Provider Interfaces)** — outbound calls FROM Point of Sale to merchant systems; alter transaction journey behavior
3. **Webhooks** — event-triggered outbound calls FROM Point of Sale to external systems

All three are configured through the CMS (Custom Connectors). There is no Apex, Flow, or platform event layer in the traditional Salesforce sense — this is an external retail platform with its own event/integration model.

---

## APIs — Inbound to Point of Sale

### CMS Users API
Used to manage CMS administrative users programmatically.

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/merchant/{version}/users` | Retrieve all CMS users |
| PUT | `/merchant/{version}/users` | Update a CMS user |
| POST | `/merchant/{version}/users` | Create CMS users |
| DELETE | `/merchant/{version}/users` | Delete a CMS user |
| GET | `/merchant/{version}/users/{userId}` | Retrieve CMS user by userId |

### Inventory Management System (IMS) API
Used to manage in-store inventory operations.

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/merchant/{version}/ims/inventory/asn` | Create ASN in IMS |
| PUT | `/merchant/{version}/ims/inventory/cyclecount/cancel` | Cancel a specified cycle count |
| POST | `/merchant/{version}/ims/inventory/cyclecount/full` | Create a full cycle count |
| POST | `/merchant/{version}/ims/inventory/cyclecount/manual` | Create a manual cycle count |
| POST | `/merchant/{version}/ims/inventory/cyclecount/partial` | Create a partial cycle count |

### Notifications API
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/merchant/{version}/notifications` | Schedule immediate notifications to specific target devices (by installation ID or email address) |

### Products API
| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/merchant/{version}/products` | Update products |
| POST | `/merchant/{version}/products` | Create products |
| DELETE | `/merchant/{version}/products` | Delete products |

**Limitation:** Product API does not support multi-region pricing (no "region" field). Use CMS feeds for multi-region pricing updates.

### Promotions API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/merchant/{version}/promotions` | Retrieve all promotions |
| PUT | `/merchant/{version}/promotions` | Update promotions |
| POST | `/merchant/{version}/promotions` | Create promotions |
| GET | `/merchant/{version}/promotions/download/report` | Download report of all CMS-created promotions (active and inactive) |
| POST | `/merchant/{version}/promotions/upload` | Upload promotions via JSON file |
| GET | `/merchant/{version}/promotions/{promotionId}` | Retrieve promotion by ID |
| DELETE | `/merchant/{version}/promotions/{promotionId}` | Delete promotion by ID |
| GET | `/merchant/{version}/promotions/{promotionId}/supc` | Retrieve Single Use Promotion Codes (SUPC) list |
| PUT | `/merchant/{version}/promotions/{promotionId}/supc` | Update redemption status of SUPCs (redeemed by external system) |
| POST | `/merchant/{version}/promotions/{promotionId}/supc` | Create/send new valid SUPCs to Point of Sale |

### Store Associates API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/merchant/{version}/associates` | Retrieve active/inactive associates by `storeId` and `associateId` query params |
| PUT | `/merchant/{version}/associates` | Update a store associate |
| POST | `/merchant/{version}/associates` | Create a store associate |
| DELETE | `/merchant/{version}/associates` | Deactivate associate (sets `active` field to `false`) |
| GET | `/merchant/{version}/associates/{associateId}` | Retrieve associate details by associateId |

### Store Products (Inventory) API
| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/merchant/{version}/storeproducts` | Update store product details (list price, sale price, quantity, promo banner text) |
| GET | `/merchant/{version}/storeproducts/inventory` | Return store inventory for queried store and product ID(s) |
| PUT | `/merchant/{version}/storeproducts/inventory` | Update store or E-comm inventory of products |
| POST | `/merchant/{version}/storeproducts/inventory` | Create store or E-comm inventory (incremental upload) |
| GET | `/merchant/{version}/storeproducts/inventory/{storeId}` | Return URL for CSV file containing store inventory |

**Note:** POST storeproducts/inventory is for incremental uploads only. For full inventory loads, use the Store Inventory & Pricing Feed via CMS.

### Orders API
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/merchant/{version}/sa/orders` | Create order data |
| POST | `/merchant/{version}/sa/orders/repost` | Repost orders to external system by list of order IDs |
| POST | `/merchant/{version}/sa/orders/search` | Search and retrieve orders by input parameters |
| GET | `/merchant/{version}/sa/orders/{id}` | Retrieve order data by order ID |

---

## SPIs — Outbound from Point of Sale

SPIs alter transaction journey behavior for store associates. The merchant must host web servers to receive these requests.

### SPI URL Pattern
```
Staging:    https://<staging_path>/<api_version>/<api_path>?api_key={API_KEY}&<params>
Production: https://<production_path>/<api_version>/<api_path>?api_key={API_KEY}&<params>
```

### Customer SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| POST | `CREATE_CUSTOMER` | HTTP_POST | Create customer in external system |
| PUT | `UPDATE_CUSTOMER` | HTTP_PUT | Update existing customer (existing ID in `profile.customerId`) |
| GET | `GET_CUSTOMER` | HTTP_GET | Retrieve customer by ID |
| GET | `SEARCH_CUSTOMERS` | HTTP_GET | Search customers by input parameters |
| GET | `CUSTOMER_INTERACTION_HISTORY` | HTTP_GET | **LEGACY — Do not use** |
| GET | `GET_ORDER_LIST` | HTTP_GET | **LEGACY — Do not use** |

### Customer Address SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| GET | `GET_CUSTOMER_ADDRESSES` | HTTP_GET | Retrieve address list by customer ID |
| PUT | `UPDATE_CUSTOMER_ADDRESS` | HTTP_PUT | Update address by customer ID and address ID |
| POST | `CREATE_CUSTOMER_ADDRESS` | HTTP_POST | Add new address for a customer |
| DELETE | `DELETE_CUSTOMER_ADDRESS` | HTTP_DELETE | Delete address by customer ID and address ID |

**Address SPI Behavior:** When Address SPI is configured, POS triggers the endpoint and disregards `addressList` from Customer SPI. After adding an address via CREATE_CUSTOMER_ADDRESS, POS relies on the `addressList` from that response for checkout.

### Inventory SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| POST | `INVENTORY_SERVICE` | HTTP_POST | Revert reserved inventory (use on payment failure during checkout) |
| POST | `ONLINE_ITEM_INVENTORY_CHECK` | HTTP_POST | Check external system for product availability (online only) |
| POST | `GET_PRODUCT_INVENTORY_OVERVIEW` | HTTP_POST | Check product availability overview for all stores or by zip code |

### Loyalty SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| POST | `LOYALTY_POINTS_EARNED` | HTTP_POST | Retrieve loyalty points redeemed in transaction at tender time (for receipt printing) — only for customers with loyalty profiles |
| POST | `REWARD_LOOKUP` | HTTP_POST | Retrieve available rewards for a customer (applied as tender) |

### Orders SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| GET | `GET_ORDER_DETAIL` | HTTP_GET | Fetch order from external system during BORIS flow (SPI as order master) |
| GET | `BORIS_GET_ORDER_DETAIL` | HTTP_GET | Fetch order from external system during BORIS flow (Retail Cloud as order master for in-store orders) |
| POST | `SEARCH_ORDERS` | HTTP_POST | Search orders from merchant system by filter criteria |
| POST | `RETURN` | HTTP_POST | Post sale transaction to merchant external system |

**Delivery Group note:** If enabling delivery grouping with GET_ORDER_DETAIL, the SPI response must include a `DeliveryGroup` list.

### Other SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| POST | `CART_VALIDATION` | HTTP_POST | Custom cart validations; can also reserve inventory |
| POST | `DATE_PICKER` | HTTP_POST | Retrieve delivery/pickup dates and time slots for applicable cart items |
| POST | `VERIFY_EMPLOYEE` | HTTP_POST | Verify employee information when applying employee discounts |

### Shipping Methods SPI
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| POST | Merchant-defined | HTTP_POST | Receive applicable shipping methods for cart items marked for shipping/delivery |

### Tax SPIs
| Method | Endpoint Name | Integration Type | Description |
|--------|--------------|-----------------|-------------|
| POST | `TAX_SERVICE` | HTTP_POST | Calculate taxes per merchant's rules |
| GET | `TAX_SERVICE` | HTTP_GET | Retrieve tax rates list for offline transactions |
| POST | `TAX_SERVICE` | HTTP_POST | Finalize taxes applied to sale transactions |
| GET | `TAX_SERVICE` | HTTP_GET | Retrieve tax exemptions from merchant's system |

### New SPIs (Recent Release)
| SPI | API Key | Description |
|-----|---------|-------------|
| Gift Card SPI | `GIFT_CARD_SERVICE` | Balance check, activation, add funds, redemption, void/reversal |
| Warranty SPI | `WARRANTY_LOOKUP` | Retrieve eligible warranty products for cart merchandise |
| Quote SPI | (quote management) | Quote management operations |

---

## Webhooks — Event-Triggered Outbound from Point of Sale

Webhooks are event-triggered outbound calls. Configuration path: CMS > Store Management > Integrations > Custom Connectors > Connector Type: Webhook.

### E-Receipt Webhook
| Endpoint Name | Integration Type | Description |
|--------------|-----------------|-------------|
| `ERECEIPT_CUSTOMER` | HTTP_POST | Send order details to merchant email service instead of POS email service |

**eReceipt Automation Settings:**
- `sendOrderConfirmationEmailAutomatically` — auto-send order confirmation emails
- `sendRefundEmailAutomatically` — auto-send refund emails
- `HideReceiptEmailShare` — hide email share button

### Inventory Event Webhooks
| Endpoint Name | Events | Description |
|--------------|--------|-------------|
| `INVENTORY_EXPORT_ASN` | ASN_RECEIVED_EVENT, ASN_PARTIALLY_RECEIVED_EVENT, ASN_RECEIVE_COMPLETED_EVENT | Send ASN data |
| `INVENTORY_EXPORT_STS` | Store-to-store transfer events | Send STS data |
| `INVENTORY_EXPORT_RTV` | Return-to-vendor events | Send RTV data |
| `INVENTORY_EXPORT_CTS` | Customer-to-store events | Send CTS data |
| `INVENTORY_EXPORT_BLD` | Build/assembly events | Send BLD data |
| `INVENTORY_EXPORT_INA` | INVENTORY_ADJUSTMENT, INVENTORY_BUCKET_ADJUSTMENT | Send inventory adjustment data |
| `INVENTORY_EXPORT_INBA` | INVENTORY_BUCKET_ADJUSTMENT | Send inventory bucket adjustment data |
| `INVENTORY_EXPORT_CYC` | CYC_COUNT_CREATED_EVENT, CYC_COUNT_STARTED_EVENT, CYC_COUNT_COMPLETED_EVENT, CYC_COUNT_CANCELED_EVENT | Send cycle count data |
| `INVENTORY_EXPORT_PO` | PO_TRANSFER_STARTED_EVENT, PO_TRANSFER_COMPLETED_EVENT, PO_TRANSFER_ERRORED_EVENT | Send purchase order data |
| `SALE_INVENTORY` | Sale completed | Item(s) sold — inventory should decrease |
| `RETURN_INVENTORY` | Return/exchange completed | Item(s) returned/exchanged — inventory should increase/adjust |

### Order Webhooks
| Endpoint Name | Integration Type | Description |
|--------------|-----------------|-------------|
| `ORDER` | HTTP_POST | Export sale transaction details |
| `ORDER_UPDATE` | HTTP_POST | Export updated sale transaction details |
| `BOPIS_EXPORT` | HTTP_POST | Export BOPIS transaction details |
| `BOFIS_EXPORT` | HTTP_POST | Export BOFIS transaction details |
| `ROPIS_EXPORT` | HTTP_POST | Export ROPIS transaction details |
| `RETURN` | HTTP_POST | Post return/BORIS transaction to external system |

**New:** `Promotion Events Webhook` — promotion event notifications

### Other Webhooks
| Endpoint Name | Integration Type | Description |
|--------------|-----------------|-------------|
| `VOID_CART` | HTTP_POST | Real-time details when cart is voided (Loss Prevention audit support) |
| `SUSPEND_CART` | HTTP_POST | Real-time details when cart is suspended (Loss Prevention audit support) |
| `POS_CRASH_DATA` | HTTP_POST | Register crash details (app version, device model, OS, store/register IDs, installation ID, environment, region) |
| `POS_VITALS` | HTTP_POST | Real-time register vitals (network connectivity, associate sign-in/out, peripheral status, order syncs, offline feed syncs) |
| `EXPORT_MONITORING_EVENTS` | HTTP_POST or HTTP_PUT | Real-time integration health monitoring (SPI/webhook errors, latency breaches, performance issues) |

---

## Failed Webhook Repost Process

1. CMS: Store Management > Reporting and Analytics > Repost Failed Webhook Events
2. Search for failed webhook by query parameters
3. Click "View Details" to view payload
4. Click "Repost" to manually trigger repost

---

## Setting Up Custom Connectors (Step-by-Step)

### For SPIs:
1. CMS: Store Management > Integrations > Custom Connectors
2. Click Create
3. Connector Type: SPI
4. Endpoint Name: (select from list, e.g., CREATE_CUSTOMER)
5. API Endpoint: external endpoint URL
6. Integration Type: (e.g., HTTP_POST)
7. JSON Headers: set Content-Type and Authorization attributes
8. (Optional) OAuth Config: enable NetSuite OAuth or configure OAuth SPI

### For Webhooks:
1. CMS: Store Management > Integrations > Custom Connectors
2. Click Create
3. Connector Type: Webhook
4. Endpoint Name: (select from list, e.g., ORDER)
5. API Endpoint: external endpoint URL
6. Integration Type: (e.g., HTTP_POST)
7. JSON Headers: set Content-Type and Authorization attributes

### Supported Integration Types:
- HTTP_GET
- HTTP_POST
- HTTP_PUT
- HTTP_DELETE

---

## Offline Mode Behavior

- Voided carts: queued and pushed to POS services once the app regains connectivity
- eReceipt webhook: triggered when the app calls the eReceipt API; no emails sent when an order syncs
- If automatic receipt emails are configured: eReceipts are sent for ALL orders even in offline mode during sync
- Recommendation: if automatic eReceipts are enabled, remove the email CTA from order confirmation layout

---

## Notifications API Pattern
The Notifications API allows scheduling immediate notifications to specific devices:
- Target by installation ID (device-level)
- Target by email address (maps to installation ID in POS if captured on login)
- Use case: order shipped, cart abandoned, etc.
