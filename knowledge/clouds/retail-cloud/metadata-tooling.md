---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: metadata-tooling
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Metadata Tooling

## Overview

Retail Cloud (Point of Sale) is fundamentally different from standard Salesforce clouds in its metadata model. It is NOT a standard Salesforce metadata-driven product — it is an acquired retail POS platform (PredictSpring) that was integrated into Salesforce. Configuration lives in the CMS (merchant admin portal) and is managed through the Retail Cloud admin UI, not through Salesforce DX, package.xml, or the Metadata API.

---

## What Is and Is Not Metadata-Deployable

### NOT Managed via Salesforce Metadata API
- SPI Custom Connectors (managed in CMS: Store Management > Integrations > Custom Connectors)
- Webhook Custom Connectors (managed in CMS)
- Store inventory and product catalog data
- Merchant configuration (CMS: Advanced > Merchant Configuration)
- Custom product attributes (`spiCustomProductAttributes`) — configured in CMS UI
- eReceipt settings (`sendOrderConfirmationEmailAutomatically`, etc.) — configured in CMS
- Promotions — managed via API or CMS UI
- Store associates — managed via API or CMS UI
- ERP configuration for NetSuite OAuth — managed in CMS

### Managed via Salesforce Setup (Hyperforce deployments only)
- **External Client App** — created and configured in Salesforce Setup
  - Path: Setup > External Client Apps Manager
  - Contains: OAuth Settings (Consumer Key, Consumer Secret)
  - This IS a Salesforce metadata object and can be exported as metadata
- **My Domain** — configured in Salesforce Setup
- **Connected App** (if using the legacy Connected App model instead of External Client App)

---

## Salesforce Metadata Types Relevant to Retail Cloud (Hyperforce)

### ExternalClientApplication
The External Client App (OAuth app for Hyperforce API access) is represented in Salesforce metadata.

**Metadata type:** `ExternalClientApplication` (or `ConnectedApp` depending on version)

**Key configuration elements:**
- OAuth Consumer Key (Client ID)
- Consumer Secret
- Grant types: Client Credentials, JWT
- Callback URLs
- OAuth scopes

**package.xml snippet:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>YourRetailCloudApp</members>
        <name>ExternalClientApplication</name>
    </types>
    <version>63.0</version>
</Package>
```

---

## CMS Configuration — No CI/CD Support (Native)

CMS configuration (Custom Connectors, Store Settings) does not have native export/import functionality compatible with standard Salesforce CI/CD tools (sfdx, Salesforce CLI, GitHub Actions with Salesforce Deploy).

**Implications:**
- CMS configuration must be manually recreated in each environment (Staging → Production)
- No standard metadata migration path for SPI/Webhook connector configuration
- Configuration drift between environments is a risk
- All environment-specific configuration (endpoint URLs, API keys) must be separately maintained per environment

---

## API-Driven Configuration Management

Since CMS configuration is not Salesforce metadata, CI/CD-conscious teams can use the following approaches:

### Configuration as Code via API
Several CMS configurations can be managed programmatically:
- Products: PUT/POST `/merchant/{version}/products`
- Promotions: PUT/POST `/merchant/{version}/promotions`
- Store associates: PUT/POST `/merchant/{version}/associates`
- Store inventory: PUT/POST `/merchant/{version}/storeproducts`

### CMS-Only Configuration (Must Be Manual or CMS UI)
- SPI Custom Connectors: no API for connector CRUD
- Webhook Custom Connectors: no API for connector CRUD
- OAuth configuration: must be set up in CMS UI
- Product attribute settings (`spiCustomProductAttributes`): CMS UI only
- eReceipt settings: CMS UI only
- ERP configuration: CMS UI only

---

## Environment Management Considerations

### Endpoint URL Strategy
Each Custom Connector (SPI/Webhook) must point to the correct environment-specific endpoint:
- Staging connector → staging SPI endpoint (e.g., `https://staging.mycompany.com/spi/...`)
- Production connector → production SPI endpoint (e.g., `https://www.mycompany.com/spi/...`)

There is no environment variable injection in CMS connectors — URLs are hardcoded per connector.

### API Key Management
- Staging and production API keys are separate values
- Keys are obtained from CMS: Advanced > Merchant Configuration > Developer Credentials
- No automated key rotation described in documentation
- Keys must be securely stored in environment-specific secret management systems

### Multi-Environment Credential Storage
| Credential | Storage Recommendation |
|------------|----------------------|
| PredictSpring-Secret | Secure vault per environment (non-Hyperforce) |
| Merchant API Key | Secure vault per environment (non-Hyperforce) |
| OAuth2 Client ID/Secret | Secure vault per environment (non-Hyperforce) |
| Consumer Key/Secret (Hyperforce) | Salesforce Connected App metadata or vault |
| SPI API Keys (merchant side) | Secure vault per environment |

---

## Salesforce DX Project Structure (Hyperforce)

For Hyperforce deployments, the Salesforce metadata components are limited:

```
force-app/
└── main/
    └── default/
        └── externalClientApplications/
            └── RetailCloudPOS.externalClientApplication-meta.xml
```

or using ConnectedApp:
```
force-app/
└── main/
    └── default/
        └── connectedApps/
            └── RetailCloudPOS.connectedApp-meta.xml
```

---

## CI/CD Pipeline Considerations

### What Can Be Automated
1. Salesforce org metadata (External Client App) via standard Salesforce CLI deploy
2. Product, promotion, and inventory data via the Retail Cloud API
3. SPI/Webhook endpoint code on the merchant side (independent of Retail Cloud)
4. Automated testing of SPI endpoints using mock POS requests

### What Cannot Be Fully Automated (Manual Steps Required)
1. CMS Custom Connector creation/update (no Connector API available)
2. eReceipt settings activation
3. Custom product attribute configuration
4. ERP/NetSuite OAuth setup in CMS
5. Merchant configuration settings in CMS

### Recommended CI/CD Approach
1. **Stage 1 — Salesforce Org Metadata:** Deploy External Client App via sfdx/Salesforce CLI
2. **Stage 2 — SPI/Webhook Code Deployment:** Deploy merchant-side endpoints via standard web deployment tools
3. **Stage 3 — Data Seeding via API:** Use Retail Cloud API to load products, promotions, associates
4. **Stage 4 — Manual CMS Steps:** Document and execute CMS configuration steps as a manual runbook
5. **Stage 5 — Verification:** Test all SPIs and webhooks end-to-end

---

## Version Management

### API Version
- Current supported version: `v1`
- Specified in path: `/merchant/v1/...`
- Only v1 is documented as supported (prior versions deprecated or undocumented)

### SPI Version
- `api_version` in SPI URL path (e.g., `1.0` or `1.1`)
- Must be consistent across all SPI requests for a given implementation
- Cannot mix versions within a single SPI implementation

---

## Full API Specification Download

The complete POS API OpenAPI/Swagger specification is available for download at:
`https://developer.salesforce.com/docs/commerce/retail-cloud/references/pos-oas?meta=Summary`

This file can be imported into API management tools (e.g., Postman, Insomnia) for:
- API mock server setup
- Automated API contract testing
- SDK generation

**Note:** The reference pages use a JavaScript-rendered UI (Redoc) — download the specification file for offline/tooling use.

---

## Documentation References

| Resource | URL |
|----------|-----|
| Get Started | `https://developer.salesforce.com/docs/commerce/retail-cloud/guide/get-started.html` |
| Non-Hyperforce Developer Guide | `https://developer.salesforce.com/docs/commerce/retail-cloud/guide/retail-cloud-api-developer-guide.html` |
| Hyperforce Access Guide | `https://developer.salesforce.com/docs/commerce/retail-cloud/guide/external-api-access-guide-for-hyperforce-users.html` |
| OAuth Setup Guide | `https://developer.salesforce.com/docs/commerce/retail-cloud/guide/setting-up-oauth-with-retail-cloud-apis.html` |
| API/SPI/Webhook Overview | `https://developer.salesforce.com/docs/commerce/retail-cloud/guide/retail-cloud-api-spi-webhook-specs.html` |
| SPI Error Handling | `https://developer.salesforce.com/docs/commerce/retail-cloud/guide/retail-cloud-spi-error-handling.html` |
| API Release Notes | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/about-retail-cloud-api/about.html` |
| POS API Full Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/pos-oas?meta=Summary` |
| Gift Card SPI Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/gift-card-spi?meta=Summary` |
| Warranty SPI Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/warranty-spi?meta=Summary` |
| Quote SPI Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/quote-spi?meta=Summary` |
| Promotion Events Webhook Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/promotion-events-webhook?meta=Summary` |
| Store Group Management API Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/store-group-management-api?meta=Summary` |
| Clienteling SPI Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/clienteling-spi?meta=Summary` |
| Delivery Group SPI Spec | `https://developer.salesforce.com/docs/commerce/retail-cloud/references/delivery-group-spi?meta=Summary` |
| Store Inventory Feed (Salesforce Help) | `https://help.salesforce.com/s/articleView?id=commerce.rt_adv_config_data_feeds_specs_store_inv_price.htm` |
