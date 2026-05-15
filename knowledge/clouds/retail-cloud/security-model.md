---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: security-model
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Security Model

## Authentication Architecture

Retail Cloud uses two distinct authentication models depending on whether the deployment is on Hyperforce or the legacy non-Hyperforce infrastructure.

---

## Non-Hyperforce Authentication (Legacy PredictSpring)

### Two-Step Process

**Step 1: Obtain OAuth Token**
```
POST https://staging-oauth2.predictspring.com/oauth2/token
POST https://prod-oauth2.predictspring.com/oauth2/token
```
- Uses OAuth2 client credentials grant
- Response includes `access_token` and `expired_in` (token validity in seconds)

**Step 2: Invoke API with Required Headers**

| Header | Value | Source |
|--------|-------|--------|
| `PredictSpring-Secret` | Encrypted credential string | CMS: Advanced > Merchant Configuration > Developer Credentials |
| `PredictSpring-Token` | OAuth access token from Step 1 | OAuth2 token response |
| `X-api-key` | Merchant API Key | CMS: Advanced > Merchant Configuration > Developer Credentials |
| `Content-Type` | `application/json` | Static |

---

## Hyperforce Authentication

### Prerequisites
- Must create an External Client App in Salesforce Setup with OAuth and JWT capabilities enabled
- Consumer Key and Consumer Secret obtained from External Client Apps Manager (Setup)
- My Domain URL obtained from My Domain settings (Setup)

### JWT Token Request
```
POST <my-domain-url>/services/oauth2/token
```
Body parameters (client credentials grant):
- `grant_type=client_credentials`
- Consumer Key and Secret used for authentication

### Required API Request Headers (Hyperforce)

| Header | Description |
|--------|-------------|
| `Authorization` | Bearer token from JWT response |
| `Content-Type` | `application/json` |
| `x-salesforce-region` | Region value for the environment (e.g., `us-east-2`, `us-west-2`) |
| `x-locale` | Merchant-specific locale (routes to correct merchant) |
| `x-region` | Merchant-specific region (routes to correct merchant) |

### Critical Constraint
**The API token must come from the same Salesforce Org as the merchant. Tokens from a different Org fail authentication.**
- `x-locale` and `x-region` are merchant-specific, not org-specific
- These headers route requests to the correct merchant within the org

---

## SPI Authentication (Outbound Calls from POS to Merchant Systems)

When POS makes outbound SPI calls to merchant-hosted endpoints, the merchant system must authenticate requests using an API key:

```
https://<path>/<api_version>/<api_path>?api_key={API_KEY}
```

- POS provides staging and production API keys
- All SPI requests include the `api_key` request parameter
- If an invalid API key is supplied, the merchant API must respond with **HTTP 401 Unauthorized** with an empty response body

### NetSuite OAuth for SPIs/Webhooks
Point of Sale Custom Connection supports NetSuite OAuth for SPIs and Webhooks:
1. Requires ERP configuration to be set up in CMS first
2. Navigate to CMS: Store Management > Integrations > Custom Connectors
3. Edit or create a connector configuration
4. Enable "NetSuite OAuth" under OAuth Config — this automatically retrieves OAuth credentials from ERP configuration
5. Save changes

**Important:** If ERP configuration is not set up first, the SPI fails to process and results in an error in CMS.

---

## OAuth SPI Configuration (OAuth for External SPI Endpoints)

For SPIs that require OAuth to access external endpoints, configure the OAUTH-OAuth SPI connector:

**Phase 1 — Create the OAuth connector:**
1. CMS: Integrations > Custom Connectors > Create
2. Connector Type: SPI
3. Endpoint Name: OAUTH-OAuth
4. API Endpoint: `https://<oauth-server>/oauth2/token?grant_type=client_credentials`
5. Integration Type: HTTP_POST
6. JSON Headers:
   - Header: `Authorization`
   - Value: `Basic <base64(clientId:clientSecret)>`
   - Note: Include a space after "Basic"; do not include a colon before the token

**Base64 Encoding Rule:**
- Format: `clientId:clientSecret` (colon separator with space: `client_id: client_secret`)
- Encode with Base64
- Add "Basic " prefix (with trailing space)

**Phase 2 — Configure individual SPI to use OAuth:**
1. CMS: Integrations > Custom Connectors > Create
2. Connector Type: SPI
3. Endpoint Name: (target SPI, e.g., SHIPPING_METHOD)
4. Navigate to OAuth Config settings
5. Set OAuth Header to desired header name
6. Set OAuth API Key to `OAuth` or `OAUTH`
7. Configure remaining required fields
8. Save changes

---

## Credential Storage

**Non-Hyperforce:** Credentials stored in CMS
- Location: Advanced > Merchant Configuration > Developer Credentials
- Contains: PredictSpring-Secret, Merchant API Key, OAuth2 Client ID, OAuth2 Client Secret

**Hyperforce:** Credentials stored in Salesforce Org
- Consumer Key and Secret: Setup > External Client Apps Manager > App > Settings > OAuth Settings
- Domain URL: Setup > My Domain

---

## Rate Limiting as Security Control

| Environment | Limit |
|-------------|-------|
| Production | 10 requests/second; 100,000 requests/month |
| Staging | 10,000 requests/month |

Exceeding limits requires contacting Salesforce Customer Support for increased capacity.

---

## SPI API Key Authentication

- Two API keys provided per merchant: one for staging, one for production
- Keys are static (not dynamically rotated in described process)
- `api_key` is passed as a query parameter (static query parameters supported; dynamic query parameter population is NOT supported)

---

## Error Responses for Authentication Failures

| Scenario | HTTP Status | Response Body |
|----------|-------------|---------------|
| Invalid SPI API key | 401 Unauthorized | Empty body |
| Exception condition | 400 Bad Request | JSON with `errorCode` and `errorMessage` |
| Hyperforce: wrong Org token | Authentication fails | Token rejected |

---

## Platform Security Notes

- GraphQL is not available externally — used exclusively for the POS app and CMS
- No external access to CMS GraphQL endpoints
- All external API access goes through the documented REST endpoints
- Webhook failures are logged and visible in CMS for repost (no automatic retry described)
- Offline mode: voided carts are queued and pushed once the app regains connectivity
