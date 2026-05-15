---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: implementation-guide
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Implementation Guide

## Implementation Prerequisites

### General Prerequisites
1. A provisioned Retail Cloud merchant (created in the Salesforce Org for Hyperforce, or a PredictSpring account for non-Hyperforce)
2. Access to the CMS (merchant admin portal)
3. Developer credentials (API keys, OAuth credentials)
4. External web server infrastructure to host SPI endpoints (if implementing SPIs)
5. External endpoint infrastructure to receive webhooks (if implementing webhooks)
6. Staging environment for testing before production deployment

### Hyperforce-Specific Prerequisites
1. Salesforce Org with the merchant configured (tokens must come from this Org)
2. External Client App created in Setup with OAuth and JWT capabilities enabled
3. My Domain configured in the Salesforce Org

---

## Step 1: Obtain Credentials

### Non-Hyperforce Credential Setup
1. Log into the CMS
2. Navigate to Advanced > Merchant Configuration > Developer Credentials
3. Copy the following:
   - `PredictSpring-Secret` (encrypted credential)
   - Merchant API Key (for `X-api-key` header)
   - OAuth2 Client ID
   - OAuth2 Client Secret
4. Note whether you need staging or production environment credentials

### Hyperforce Credential Setup
1. Log into the Salesforce Org where the merchant was created
2. Navigate to Setup > External Client Apps Manager
3. Find the merchant's External Client App
4. Go to Settings tab > OAuth Settings
5. Copy: Consumer Key (Client ID) and Consumer Secret (Client Secret)
6. Navigate to Setup > My Domain
7. Copy the My Domain URL (e.g., `https://yourorg.my.salesforce.com`)

---

## Step 2: Implement Authentication

### Non-Hyperforce OAuth Flow
```
Step 2a: Request OAuth Token
POST https://staging-oauth2.predictspring.com/oauth2/token
  (for staging)
POST https://prod-oauth2.predictspring.com/oauth2/token
  (for production)

Response includes:
- access_token: <token>
- expired_in: <seconds>  ← track this for token refresh

Step 2b: Call API with all required headers
GET/POST/PUT/DELETE https://api.predictspring.com/staging/service/merchant/v1/<endpoint>
Headers:
  PredictSpring-Secret: <encrypted-credential>
  PredictSpring-Token: <access_token from Step 2a>
  X-api-key: <merchant-api-key>
  Content-Type: application/json
```

### Hyperforce OAuth Flow
```
Step 2a: Request JWT Token
POST <my-domain-url>/services/oauth2/token?grant_type=client_credentials
Auth: Consumer Key and Consumer Secret

Response includes:
- access_token: <jwt-token>

Step 2b: Call API with all required headers
Headers:
  Authorization: Bearer <access_token from Step 2a>
  Content-Type: application/json
  x-salesforce-region: <us-east-2 or us-west-2>
  x-locale: <merchant-specific-locale>
  x-region: <merchant-specific-region>
```

---

## Step 3: Configure Custom Connectors for SPIs

For each SPI to be implemented:

1. In CMS, go to Store Management > Integrations > Custom Connectors
2. Click Create
3. Fill in:
   - **Connector Type:** SPI
   - **Endpoint Name:** Select from the SPI list (e.g., CREATE_CUSTOMER, TAX_SERVICE)
   - **API Endpoint:** Your external endpoint URL (staging and production)
   - **Integration Type:** HTTP_POST, HTTP_GET, HTTP_PUT, or HTTP_DELETE
   - **JSON Headers:** Configure Content-Type and Authorization headers
4. (Optional) Configure OAuth:
   - For external OAuth: Set up OAUTH-OAuth connector first (see OAuth SPI setup below)
   - For NetSuite: Ensure ERP configuration is set up first, then enable NetSuite OAuth
5. Save

### OAuth SPI Configuration
If your SPI endpoint requires OAuth authentication:

**First: Create OAUTH-OAuth connector**
1. CMS: Integrations > Custom Connectors > Create
2. Connector Type: SPI
3. Endpoint Name: OAUTH-OAuth
4. API Endpoint: `https://<your-oauth-server>/oauth2/token?grant_type=client_credentials`
5. Integration Type: HTTP_POST
6. JSON Headers:
   ```
   Authorization: Basic <base64(clientId:clientSecret)>
   ```
   Note: "Basic " with trailing space; no colon before the encoded value

**Then: Configure individual SPI to use OAuth**
1. Edit or create the target SPI connector
2. Go to OAuth Config settings
3. Set OAuth Header: (your preferred header name)
4. Set OAuth API Key: `OAuth` or `OAUTH`
5. Configure remaining required fields
6. Save

---

## Step 4: Configure Custom Connectors for Webhooks

For each webhook to be implemented:

1. In CMS, go to Store Management > Integrations > Custom Connectors
2. Click Create
3. Fill in:
   - **Connector Type:** Webhook
   - **Endpoint Name:** Select from the webhook list (e.g., ORDER, ERECEIPT_CUSTOMER)
   - **API Endpoint:** Your external endpoint URL
   - **Integration Type:** HTTP_POST (or HTTP_PUT for EXPORT_MONITORING_EVENTS)
   - **JSON Headers:** Configure Content-Type and Authorization
4. For inventory webhooks: Also select the specific **Events** to subscribe to
5. Save

---

## Step 5: Configure Custom Product Attributes for SPIs

If using the Delivery Group SPI or needing custom product attributes in SPI responses:

1. CMS: Store Management > Store Settings > Product
2. Find the setting: "Merchant-specific product attributes to be provided in SPI request" (`spiCustomProductAttributes`)
3. Enter comma-separated, case-insensitive attribute names from the product collection
   - Example: `variantGroupId, salePrice, manufacturer, brand`
4. Save

---

## Step 6: Implement SPI Endpoints (Merchant Side)

For each SPI the merchant hosts, implement:

1. **Authentication handler:** Validate the `api_key` query parameter
   - Invalid key → return HTTP 401 with empty body
2. **Request processor:** Handle the incoming SPI request
3. **Response builder:** Return JSON response (omit null/unused fields entirely)
4. **Error handler:** Return JSON `{"errorCode": "...", "errorMessage": "..."}` with appropriate HTTP status (400 for exceptions)
5. **Staging endpoint:** Required — provide both staging and production endpoints

**SPI Response Rules:**
- Omit unused fields entirely (do NOT set to null)
- Error messages must be i18n/localized based on request locale
- Dates in epoch milliseconds (integer, not string)
- Consistent `api_version` across all SPI calls

---

## Step 7: Implement Webhook Receivers (Merchant Side)

For each webhook the merchant receives:

1. **Endpoint:** Implement HTTPS endpoint at the configured URL
2. **Authentication:** Configure appropriate auth in JSON Headers (CMS)
3. **Response:** Return HTTP 2xx status with empty or minimal body
4. **CRITICAL:** Do NOT return `errorMessage` or `errorCode` in the response body — even with a 2xx status, this marks the webhook as failed

---

## Step 8: Configure eReceipt Automation (Optional)

If using the ERECEIPT_CUSTOMER webhook:

1. Configure the webhook connector (Step 4)
2. In CMS, enable relevant settings:
   - `sendOrderConfirmationEmailAutomatically` — to auto-send confirmation emails
   - `sendRefundEmailAutomatically` — to auto-send refund emails
   - `HideReceiptEmailShare` — to hide email share button on receipt
3. **Warning:** If automatic eReceipts are enabled, emails will be sent in offline mode during sync. Remove email CTA from order confirmation layout to avoid duplicate communications.

---

## Step 9: Full Inventory Load Setup

For initial/full inventory loads (not incremental updates):

1. Use the Store Inventory & Pricing Feed via CMS (not the API)
2. Reference: Salesforce Help article "Store Inventory & Pricing Feed"
3. Use the POST `/merchant/{version}/storeproducts/inventory` API only for incremental inventory updates

---

## Step 10: Multi-Region Setup

For multi-region deployments:

1. Configure the master region to run the product feed
2. Other regions inherit product metadata from master
3. Provide region-specific pricing and sizing data per country via CMS feeds
4. Do NOT use the Product API for multi-region pricing updates (no "region" field exists)
5. All pricing updates for multi-region must go through CMS feed mechanism

---

## Step 11: Implement Inventory Revert for Payment Failures

If using CART_VALIDATION for inventory reservation:

1. Implement the `INVENTORY_SERVICE` SPI revert endpoint
2. Configure it in CMS as a custom connector
3. POS calls this endpoint when payment fails to release reserved inventory
4. Without this, reserved inventory is never released after payment failures

---

## Step 12: Implement Failed Webhook Monitoring

1. Configure the `EXPORT_MONITORING_EVENTS` webhook to receive real-time integration health data
2. Set up operational processes for reviewing the Repost Failed Webhook Events dashboard in CMS:
   - CMS: Store Management > Reporting and Analytics > Repost Failed Webhook Events
3. To manually repost a failed webhook:
   a. Search by query parameters
   b. Click "View Details" to inspect the payload
   c. Click "Repost" to manually trigger

---

## Implementation Order Recommendation

Recommended sequence for a full integration:

1. Credentials setup (Step 1)
2. Authentication implementation (Step 2)
3. Basic API integration (Step 3 — APIs only)
4. Test with Staging environment first
5. Configure SPI custom connectors (Step 3 — SPIs)
6. Implement SPI endpoints on merchant side (Step 6)
7. Configure webhook custom connectors (Step 4)
8. Implement webhook receivers on merchant side (Step 7)
9. Configure eReceipts if needed (Step 8)
10. Full inventory load (Step 9)
11. Multi-region configuration if needed (Step 10)
12. Monitoring setup (Step 12)
13. Production cutover

---

## Staging vs Production

Always test on staging before deploying to production:
- Staging API: `https://api.predictspring.com/staging/service`
- Staging OAuth: `https://staging-oauth2.predictspring.com/oauth2/token`
- Staging rate limit: 10,000 requests/month — use conservatively
- Provide merchant-side staging and production SPI endpoints

---

## Key CMS Navigation Paths

| Task | CMS Path |
|------|---------|
| Find API credentials | Advanced > Merchant Configuration > Developer Credentials |
| Configure SPI/Webhook connectors | Store Management > Integrations > Custom Connectors |
| Set custom product attributes | Store Management > Store Settings > Product |
| View/repost failed webhooks | Store Management > Reporting and Analytics > Repost Failed Webhook Events |
| Configure ERP for NetSuite OAuth | (ERP Configuration section — set up before enabling NetSuite OAuth) |
