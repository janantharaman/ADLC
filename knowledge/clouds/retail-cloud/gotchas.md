---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: gotchas
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Gotchas

## Authentication Gotchas

### Hyperforce Token Org Mismatch
**Issue:** The API token must come from the same Salesforce Org as the merchant. Tokens generated from a different Org silently fail authentication.
**Impact:** Integration failures that are difficult to debug — no clear error about wrong Org.
**Prevention:** Always confirm you are generating tokens from the exact Org where the merchant was created.

### ERP Configuration Required Before NetSuite OAuth SPI
**Issue:** If NetSuite OAuth is enabled for a Custom Connector before the ERP configuration is set up in CMS, the SPI fails to process and results in an error within the CMS.
**Impact:** Complete SPI failure.
**Prevention:** Always set up the ERP configuration in CMS BEFORE enabling NetSuite OAuth for any Custom Connector.

### Base64 Encoding for OAuth SPI Header
**Issue:** The Basic Authorization header for the OAUTH-OAuth SPI requires a specific format that is easy to misconfigure.
**Rule:** `Basic ` + Base64(`clientId:clientSecret`) — include a SPACE after "Basic", do NOT include a colon before the encoded value.
**Common mistake:** Omitting the space after "Basic", or encoding the string incorrectly.

### Token Expiry
**Issue:** OAuth tokens expire based on the `expired_in` value (in seconds) returned in the token response. Implementations that cache tokens without tracking expiry will fail after the first expiry.
**Prevention:** Always read `expired_in` from the OAuth response and implement token refresh logic.

---

## API Gotchas

### Product API Cannot Handle Multi-Region Pricing
**Issue:** The Product API does not have a "region" field. Multi-region pricing updates MUST go through CMS feeds.
**Impact:** Pricing updates via API in multi-region deployments will not update the correct regional prices.
**Prevention:** In multi-region setups, always use the CMS feed mechanism for pricing. Product API is only suitable for single-region pricing updates.

### POST storeproducts/inventory is Incremental Only
**Issue:** The POST endpoint for store inventory is an incremental upload — it does NOT replace existing inventory.
**Impact:** Using POST for full inventory synchronization leaves stale data in the system.
**Prevention:** For full inventory uploads, use the Store Inventory & Pricing Feed (CMS feed), not the API.

### Query Parameter Limitation for SPIs
**Issue:** Point of Sale does NOT support dynamically populating query parameters in SPI endpoint URLs.
**Impact:** Cannot pass dynamic values (e.g., current locale, current store) as query parameters.
**Behavior:** POS calls the endpoint URL exactly as configured — static query parameters only.
**Workaround:** Merchants can configure static query parameters and process them conditionally on their side. Authentication codes can also be passed as static query parameters.

### Rate Limit on Staging Is Very Low
**Issue:** Staging environment allows only 10,000 requests per month (no per-second limit specified, but production is 10/sec).
**Impact:** Load testing against staging will quickly exhaust the monthly limit.
**Prevention:** Contact Salesforce support before load testing. Be conservative with staging API usage.

---

## Data Model Gotchas

### orderProductList vs productList Confusion
**Issue:** Two fields exist: `orderProductList` (all products sold, inclusive of returns) and `productList` (sold products minus returns — the remaining un-returned items).
**Impact:** ERP integrations that use `productList` for order export will produce incorrect results when returns/exchanges exist.
**Correct pattern for ERP:** Use `orderProductList` + `returnProductList`, NOT `productList`.

### omniFulfillmentType vs fulfillmentType Confusion
**Issue:** Two fulfillment type fields exist with overlapping semantics.
**Correct pattern for ERP cash/carry/charge:** Use `fulfillmentType` + `fulfillmentSubType`, NOT `omniFulfillmentType`.

### Null Field Handling in SPI Responses
**Issue:** Including `null` values for non-nullable or unused fields in SPI responses causes unexpected behavior.
**Rule:** Omit unused fields entirely from SPI responses. Do NOT set them to null.
**Example:** If `loyaltyProfile` is not relevant, exclude it from the response rather than setting it to `null`.

### Date Format is Epoch Milliseconds (Not ISO 8601)
**Issue:** The API spec shows dates as integer data type, which is unintuitive for developers expecting ISO 8601 strings.
**Format:** Epoch time in milliseconds since January 1, 1970, 00:00:00 UTC.
**Example:** 2023-01-15 08:30:00 UTC = `1642246200000` (integer, not string)
**Impact:** Passing ISO 8601 date strings will fail silently or produce incorrect dates.

---

## SPI Gotchas

### Address SPI Overrides Customer SPI addressList
**Issue:** If the Address SPI is configured, POS ALWAYS triggers the address endpoint and completely disregards the `addressList` data returned by the Customer SPI.
**Impact:** If you configure the Address SPI, all address management must go through the Address SPI — Customer SPI address data is ignored.
**Pattern:** After creating an address via CREATE_CUSTOMER_ADDRESS, POS relies on the `addressList` from that response for checkout. The Customer SPI `addressList` is no longer consulted.

### Legacy SPIs — Do Not Use
**Issue:** Two SPIs are marked as legacy and should not be used:
- `CUSTOMER_INTERACTION_HISTORY` (GET customer interaction history)
- `GET_ORDER_LIST` (GET customer order history via Clienteling)
**Impact:** Using these will result in unmaintained behavior and potential future breakage.

### SPI API Version Must Be Consistent
**Issue:** `api_version` must be the same across ALL SPI requests to a particular SPI implementation. Cannot mix version 1.0 and 1.1 calls.
**Impact:** Mixed versions cause undefined behavior.
**Rule:** Choose one api_version (e.g., 1.0) and use it consistently for all SPI calls.

### CART_VALIDATION Can Reserve Inventory — Use Carefully
**Issue:** The CART_VALIDATION SPI can be used to reserve inventory, but if payment fails, the `INVENTORY_SERVICE` SPI must be called to revert reserved inventory.
**Impact:** If INVENTORY_SERVICE is not implemented, reserved inventory will never be released after payment failures.
**Prevention:** Always implement INVENTORY_SERVICE revert endpoint when using CART_VALIDATION for inventory reservation.

### GET_ORDER_DETAIL Requires DeliveryGroup List When Using Delivery Grouping
**Issue:** If delivery grouping is enabled, the GET_ORDER_DETAIL SPI response MUST include a `DeliveryGroup` list in the response JSON.
**Impact:** Delivery grouping breaks if the field is absent.
**Prevention:** When implementing GET_ORDER_DETAIL with delivery grouping, always include the `DeliveryGroup` array.

---

## Webhook Gotchas

### Webhook Failure Detection Has Two Criteria (Not Just HTTP Status)
**Issue:** A webhook is marked as failed not only on 4xx/5xx HTTP status codes but ALSO on 2xx responses that contain `errorMessage` or `errorCode` fields in the payload.
**Impact:** A webhook endpoint that returns HTTP 200 with an error payload will silently mark the order as failed and route it to the Repost Failed Webhook Events report.
**Prevention:** If an operation succeeds, ensure the response payload does NOT contain `errorMessage` or `errorCode` fields.

### eReceipt Webhook in Offline Mode
**Issue:** If automatic eReceipt settings are enabled, eReceipts ARE sent during offline sync for EVERY transaction — even if the customer didn't request an email.
**Impact:** Customers may receive unexpected automated emails for transactions made during offline periods.
**Prevention:** If enabling automatic eReceipts, remove the email CTA from order confirmation layout to avoid duplicate communications.

### No Automatic Retry for Failed Webhooks
**Issue:** Failed webhooks do NOT automatically retry. Manual repost is required via CMS.
**Prevention:** Implement monitoring on `EXPORT_MONITORING_EVENTS` webhook to detect webhook failures in real time. Implement operational processes for regular review of the Repost Failed Webhook Events dashboard.

### VOID_CART Webhook Queued in Offline Mode
**Issue:** When POS is in offline mode, voided carts are QUEUED and only pushed to POS services once the app regains connectivity.
**Impact:** Loss Prevention audit data will have a delay during offline operations. The webhook timestamp will reflect when it was sent (after reconnection), not when the cart was voided.

---

## Deprecation Gotchas

### customerLoyaltyProfile is Deprecated
**Issue:** The field `customerLoyaltyProfile` in Clienteling SPI is deprecated.
**Replacement:** Use `loyaltyProfile` instead.
**Impact:** New integrations using `customerLoyaltyProfile` may break in future releases.

### addressList Deprecated in Clienteling SPI Requests
**Issue:** `addressList` is deprecated in CREATE_CUSTOMER and UPDATE_CUSTOMER SPI requests.
**Note:** `addressList` is still RETURNED in GET responses — it is only deprecated for input.
**Prevention:** Do not send `addressList` in create/update customer SPI requests. Use the Address SPI instead.

---

## CMS Configuration Gotchas

### spiCustomProductAttributes is Case-Insensitive
**Issue:** The `spiCustomProductAttributes` setting (CMS: Store Management > Store Settings > Product) accepts comma-separated attribute names that are case-insensitive.
**Impact:** Attribute name mismatches due to case differences will NOT cause failures — names are matched case-insensitively.

### Store Group Management API Request Bodies Were Undocumented
**Issue:** Until a recent release, the Store Group Management API request bodies were not documented.
**Impact:** Historical integrations may have been implemented by inference or trial-and-error, not from spec.
**Status:** Now documented as of the current release.

---

## General Limitations

### No External GraphQL Access
GraphQL is exclusively for the POS app and CMS internal use. There is no external GraphQL API.

### No Dynamic Query Parameters for SPI URLs
POS sends SPI requests using the exact URL as configured. Dynamic query parameter substitution is not supported.

### Credit Card Search in Order SPI
To search orders by credit card number using the SEARCH_ORDERS SPI, the card number must be mapped to the appropriate fields in the payload under the payment card section — the system does not have a dedicated credit card search parameter.

### Multi-Region Pricing Gap
There is no dedicated pricing API. For multi-region setups, pricing MUST go through CMS feeds. The Product API cannot address multi-region pricing scenarios.

### Order Webhook Response Not Fully Specified
**Issue:** The order webhook response schema does not currently require specific fields in the response payload.
**Current behavior:** Only a success status code response is expected from the webhook endpoint.
**Note:** Schema was to be updated per FAQ entry — verify current spec in POS API (Full Specification).
