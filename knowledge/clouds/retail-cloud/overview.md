---
source: Salesforce Retail Cloud developer documentation (developer.salesforce.com/docs/commerce/retail-cloud); crawled 2026-05-15
cloud: Retail Cloud (Point of Sale)
section: overview
last-updated: 2026-05-15
---

# Retail Cloud (Point of Sale) — Overview

## What Retail Cloud Is

Salesforce Retail Cloud is a Point of Sale (POS) platform that powers in-store retail operations. It was acquired from PredictSpring in 2024 and rebranded progressively: PredictSpring → Retail Cloud → Point of Sale. The product is commonly referred to as "Point of Sale" or "POS" throughout current documentation, though all three names appear interchangeably.

Retail Cloud enables:
- In-store transaction processing (sales, returns, exchanges, BORIS, BOPIS, BOFIS, ROPIS)
- Inventory management (cycle counts, ASN, STS, RTV, CTS, BLD)
- Customer engagement and clienteling (customer profiles, loyalty, order history)
- Associate management
- Product catalog and promotions management
- Store operations monitoring

The platform is composed of:
1. **Point of Sale mobile/tablet app** — used by store associates on the sales floor
2. **CMS (Content Management System)** — the merchant admin console for configuration
3. **API/SPI/Webhook layer** — the developer extensibility surface
4. **Backend services** — hosted on Salesforce infrastructure (Hyperforce or legacy)

---

## Deployment Architectures

### Non-Hyperforce (Legacy PredictSpring)
- APIs hosted at `api.predictspring.com`
- Authentication via OAuth2 at `predictspring.com` OAuth endpoints
- Credentials stored in CMS under Advanced > Merchant Configuration > Developer Credentials
- Required headers: `PredictSpring-Secret`, `PredictSpring-Token`, `X-api-key`, `Content-Type: application/json`

### Hyperforce
- APIs hosted at Salesforce-managed endpoints per environment/region
- Authentication via Salesforce JWT-based OAuth from the Salesforce Org
- Consumer Key and Secret retrieved from External Client Apps Manager in Setup
- My Domain URL required for token generation
- API token must come from the same Salesforce Org as the merchant — tokens from a different Org fail authentication

---

## Feature Domains

| Domain | Description |
|--------|-------------|
| **APIs** | Inbound calls TO Point of Sale: Users, Inventory, Notifications, Products, Promotions, Associates, Store Products, Orders |
| **SPIs** | Outbound calls FROM Point of Sale to merchant systems: Customer, Address, Inventory, Loyalty, Orders, Taxes, Shipping, Cart Validation, Employee Verification |
| **Webhooks** | Event-triggered outbound calls FROM Point of Sale: eReceipt, Inventory Events, Orders (ORDER, ORDER_UPDATE, BOPIS_EXPORT, BOFIS_EXPORT, ROPIS_EXPORT, RETURN), Void/Suspend Cart, Register Crashes, Register Vitals, Monitor Integrations |
| **CMS** | Merchant admin portal for all configuration |

---

## Platform Scale

- 68+ API endpoints
- 20+ SPI definitions
- 13+ webhook types
- Supports single-region and multi-region deployments

---

## Naming History

The product has three names used interchangeably across documentation:
1. PredictSpring (pre-acquisition)
2. Retail Cloud (transition period)
3. Point of Sale (current, as of 2024+)

All three names appear in current documentation. Developer credentials are still labeled "PredictSpring-Secret" and "PredictSpring-Token" in API headers as of Spring 2026.

---

## Environments

### Non-Hyperforce
| Environment | API Base URL | OAuth2 URL |
|-------------|-------------|------------|
| Staging | `https://api.predictspring.com/staging/service` | `https://staging-oauth2.predictspring.com/oauth2/token` |
| Production | `https://api.predictspring.com/prod/service` | `https://prod-oauth2.predictspring.com/oauth2/token` |

### Hyperforce
| Environment | x-salesforce-region |
|-------------|---------------------|
| Production (non-sandbox) | us-east-2 or us-west-2 |
| Production (sandbox) | us-east-2 or us-west-2 |
| Staging (non-sandbox) | us-east-2 or us-west-2 |
| Staging (sandbox) | us-east-2 or us-west-2 |
| Test | us-east-2 or us-west-2 |
| Dev | us-east-2 or us-west-2 |

---

## Rate Limits

| Environment | Rate Limit |
|-------------|-----------|
| Production | 10 requests per second; 100,000 requests per month |
| Staging | 10,000 requests per month |

For higher volumes, contact Salesforce Customer Support.

---

## CMS Architecture

The CMS (merchant admin console) is the primary configuration surface. Key navigation paths:
- `Advanced > Merchant Configuration > Developer Credentials` — API keys and secrets
- `Store Management > Integrations > Custom Connectors` — SPI and Webhook configuration
- `Store Management > Store Settings > Product` — product attribute configuration (including `spiCustomProductAttributes`)
- `Store Management > Reporting and Analytics > Repost Failed Webhook Events` — failed webhook management

---

## Multi-Region Deployments

- Multi-region product feeds: master region runs the feed; other countries inherit product metadata with specific pricing/sizing per country
- Pricing updates in multi-region must use CMS feeds — the Product API does not have a "region" field
- In single-region setups, the Product API can update pricing via POST and PUT
- The `x-locale` and `x-region` headers in Hyperforce API calls are merchant-specific (not org-specific) and route requests to the correct merchant

---

## GraphQL

GraphQL is not available externally. It is used exclusively for the POS app and CMS. Not accessible to customers via the API specification.

---

## Recent API Changes (Release Notes)

**New Features:**
- Gift Card SPI: balance check, activation, adding funds, redemption, void/reversal; API Key `GIFT_CARD_SERVICE`
- Warranty SPI: warranty eligibility checks for cart merchandise; API Key `WARRANTY_LOOKUP`
- Quote SPI: quote management operations
- Promotion Events Webhook: promotion event notifications

**Updates:**
- Merchant API endpoints now document v1 as the only supported version
- Store Group Management API request bodies now documented

**Deprecations:**
- Clienteling SPI: `addressList` deprecated in CREATE/UPDATE requests (still returned in responses)
- Clienteling SPI: `customerLoyaltyProfile` field deprecated — use `loyaltyProfile` instead
- Customer Profile and Wallet: new fields added for card-on-file and payment imprint functionality
