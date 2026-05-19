# Salesforce B2C Commerce — API Reference

## SCAPI — Salesforce Commerce APIs

SCAPI is the modern REST API layer. All SCAPI endpoints follow this base URL pattern:
```
https://<short-code>.api.commercecloud.salesforce.com
```

Required query parameters for most SCAPI calls:
- `siteId`: The B2C site identifier (e.g., `RefArch`)
- Authorization: `Bearer <access_token>` (SLAS token for shopper APIs; OAuth token for admin APIs)

---

### Shopper Login (SLAS) API

Base path: `/shopper/auth/v1/organizations/{organizationId}`

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/oauth2/authorize` | Authorization endpoint (PKCE flow) | None |
| `POST` | `/oauth2/token` | Get/refresh access token | Client ID in body |
| `POST` | `/oauth2/logout` | Logout shopper | Bearer token |
| `GET` | `/oauth2/userinfo` | Get user info from token | Bearer token |
| `POST` | `/oauth2/trusted-agent/token` | Trusted agent token exchange | OAuth |
| `POST` | `/oauth2/trusted-system/actions/login` | Trusted system login | OAuth |

**Token request body (guest)**:
```
grant_type=client_credentials
&client_id=<slas-client-id>
&channel_id=<site-id>
```

**Token request body (authorization_code)**:
```
grant_type=authorization_code
&code=<auth-code>
&code_verifier=<pkce-verifier>
&redirect_uri=<registered-uri>
&client_id=<slas-client-id>
```

**Token request body (refresh)**:
```
grant_type=refresh_token
&refresh_token=<token>
&client_id=<slas-client-id>
```

**Token response fields**: `access_token`, `refresh_token`, `token_type` (`Bearer`), `expires_in` (seconds), `usid`, `customer_id`, `enc_user_id`

---

### Shopper Customers API

Base path: `/customer/shopper-customers/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `POST` | `/customers` | Register new customer |
| `POST` | `/customers/actions/login` | Login customer (deprecated; use SLAS) |
| `GET` | `/customers/{customerId}` | Get customer profile |
| `PATCH` | `/customers/{customerId}` | Update customer profile |
| `GET` | `/customers/{customerId}/addresses` | List customer addresses |
| `POST` | `/customers/{customerId}/addresses` | Add address |
| `GET` | `/customers/{customerId}/addresses/{addressName}` | Get specific address |
| `PUT` | `/customers/{customerId}/addresses/{addressName}` | Update address |
| `DELETE` | `/customers/{customerId}/addresses/{addressName}` | Delete address |
| `GET` | `/customers/{customerId}/baskets` | Get customer's open baskets |
| `GET` | `/customers/{customerId}/orders` | Get customer order history |
| `GET` | `/customers/{customerId}/payment-instruments` | Get payment instruments |
| `POST` | `/customers/{customerId}/payment-instruments` | Add payment instrument |
| `DELETE` | `/customers/{customerId}/payment-instruments/{paymentInstrumentId}` | Remove payment instrument |

**Customer object key fields**: `customerId`, `customerNo`, `login`, `firstName`, `lastName`, `email`, `enabled`, `customerGroups[]`

---

### Shopper Baskets API

Base path: `/checkout/shopper-baskets/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `POST` | `/baskets` | Create basket |
| `GET` | `/baskets/{basketId}` | Get basket |
| `DELETE` | `/baskets/{basketId}` | Delete basket |
| `PATCH` | `/baskets/{basketId}` | Update basket |
| `POST` | `/baskets/{basketId}/items` | Add item to basket |
| `PATCH` | `/baskets/{basketId}/items/{itemId}` | Update line item |
| `DELETE` | `/baskets/{basketId}/items/{itemId}` | Remove line item |
| `PUT` | `/baskets/{basketId}/billing-address` | Set billing address |
| `GET` | `/baskets/{basketId}/shipments` | Get shipments |
| `POST` | `/baskets/{basketId}/shipments` | Add shipment |
| `PUT` | `/baskets/{basketId}/shipments/{shipmentId}/shipping-address` | Set shipping address |
| `PUT` | `/baskets/{basketId}/shipments/{shipmentId}/shipping-method` | Set shipping method |
| `GET` | `/baskets/{basketId}/shipments/{shipmentId}/shipping-methods` | Get available shipping methods |
| `POST` | `/baskets/{basketId}/payment-instruments` | Add payment instrument |
| `DELETE` | `/baskets/{basketId}/payment-instruments/{paymentInstrumentId}` | Remove payment |
| `POST` | `/baskets/{basketId}/coupons` | Add coupon |
| `DELETE` | `/baskets/{basketId}/coupons/{couponItemId}` | Remove coupon |

**Basket object key fields**: `basketId`, `customerId`, `currency`, `productItems[]`, `shippingItems[]`, `paymentInstruments[]`, `shipments[]`, `taxTotal`, `orderTotal`, `productTotal`, `shippingTotal`, `adjustedTaxTotal`

---

### Shopper Orders API

Base path: `/checkout/shopper-orders/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `POST` | `/orders` | Create order from basket |
| `GET` | `/orders/{orderNo}` | Get order |
| `POST` | `/orders/{orderNo}/payment-instruments` | Add payment to order |
| `DELETE` | `/orders/{orderNo}/payment-instruments/{paymentInstrumentId}` | Remove payment |

**Order object key fields**: `orderNo`, `status`, `paymentStatus`, `shippingStatus`, `exportStatus`, `productItems[]`, `orderTotal`, `currency`, `creationDate`, `customerInfo.customerId`, `customerInfo.email`

---

### Shopper Products API

Base path: `/product/shopper-products/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `GET` | `/products` | Get multiple products (up to 24 IDs) |
| `GET` | `/products/{id}` | Get single product |
| `GET` | `/categories/{id}` | Get category |
| `GET` | `/categories` | Get multiple categories |

**Query parameters**: `siteId` (required), `allImages`, `perPricebook`, `expand[]`, `locale`, `currency`, `inventoryIds[]`

**Product object key fields**: `id`, `name`, `longDescription`, `shortDescription`, `price`, `currency`, `imageGroups[]`, `variationAttributes[]`, `variants[]`, `brand`, `upc`, `stepQuantity`, `minOrderQuantity`, `online`, `searchable`

---

### Shopper Catalog API

Base path: `/product/shopper-catalog/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `GET` | `/categories/{id}` | Get category with locale/depth options |
| `GET` | `/categories` | Get multiple categories |

---

### Shopper Search API

Base path: `/search/shopper-search/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `GET` | `/product-search` | Product search with refinements |
| `GET` | `/search-suggestions` | Typeahead search suggestions |

**Product search query parameters**: `siteId`, `q` (query), `refine[]`, `sort`, `start`, `count`, `expand[]`, `allVariantProperties`, `locale`, `currency`

**ProductSearchResult key fields**: `hits[]`, `refinements[]`, `selectedRefinements`, `searchPhraseSuggestions`, `total`, `start`, `count`, `sortingOptions[]`

---

### Shopper Promotions API

Base path: `/pricing/shopper-promotions/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `GET` | `/promotions` | Get promotions by IDs |
| `GET` | `/promotions/campaigns/{campaignId}` | Get promotions for campaign |

---

### Shopper Experience API (Page Designer)

Base path: `/experience/shopper-experience/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `GET` | `/pages` | Get pages |
| `GET` | `/pages/{pageId}` | Get page by ID |
| `GET` | `/pages/{pageId}/components/{componentId}` | Get component |

---

### Shopper Gift Certificates API

Base path: `/pricing/shopper-gift-certificates/v1/organizations/{organizationId}`

| Method | Path | Description |
|---|---|---|
| `POST` | `/gift-certificate` | Get gift certificate info |

---

## OCAPI — Open Commerce API (Legacy)

OCAPI endpoints are served directly from B2C instances:

### Data API

Base URL: `https://<instance>/s/-/dw/data/v<version>`

Common version: `v21_3` (latest should be used)

| Method | Path | Description |
|---|---|---|
| `GET` | `/sites` | List all sites |
| `GET` | `/sites/{site_id}` | Get site details |
| `GET` | `/code_versions` | List code versions |
| `PUT` | `/code_versions/{version_id}` | Create/upload code version |
| `PATCH` | `/code_versions/{version_id}` | Update (activate) code version |
| `DELETE` | `/code_versions/{version_id}` | Delete code version |
| `POST` | `/jobs/{job_id}/executions` | Run job |
| `GET` | `/jobs/{job_id}/executions/{execution_id}` | Get job execution status |
| `POST` | `/job_execution_search` | Search job executions |
| `GET` | `/products/{product_id}` | Get product (data operations) |
| `PUT` | `/products/{product_id}` | Create/update product |
| `DELETE` | `/products/{product_id}` | Delete product |
| `GET` | `/catalogs/{catalog_id}` | Get catalog |
| `POST` | `/catalog_search` | Search catalog |
| `GET` | `/customers/{customer_no}` | Get customer |
| `POST` | `/customer_search` | Search customers |
| `GET` | `/orders/{order_no}` | Get order |
| `POST` | `/order_search` | Search orders |
| `GET` | `/custom_objects/{object_type}/{key}` | Get custom object |
| `PUT` | `/custom_objects/{object_type}/{key}` | Create/update custom object |

### Shop API

Base URL: `https://<instance>/s/{site_id}/dw/shop/v<version>`

| Method | Path | Description |
|---|---|---|
| `POST` | `/baskets` | Create basket |
| `GET` | `/baskets/{basket_id}` | Get basket |
| `POST` | `/baskets/{basket_id}/items` | Add item |
| `POST` | `/orders` | Create order |
| `GET` | `/orders/{order_no}` | Get order |
| `GET` | `/product_search` | Product search |
| `GET` | `/products/{product_id}` | Get product |
| `POST` | `/customers/auth` | Customer authentication |
| `GET` | `/customers/{customer_id}` | Get customer |

---

## B2C CLI Reference — All Command Topics

### Global Flags (Available on All Commands)

| Flag | Env Var | Description |
|---|---|---|
| `--server`, `-s` | `SFCC_SERVER` | B2C instance hostname |
| `--webdav-server` | `SFCC_WEBDAV_SERVER` | Secure WebDAV hostname |
| `--code-version`, `-v` | `SFCC_CODE_VERSION` | Code version identifier |
| `--client-id` | `SFCC_CLIENT_ID` | OAuth client ID |
| `--client-secret` | `SFCC_CLIENT_SECRET` | OAuth client secret |
| `--username`, `-u` | `SFCC_USERNAME` | BM username for Basic Auth |
| `--password`, `-p` | `SFCC_PASSWORD` | WebDAV access key for Basic Auth |
| `--short-code` | `SFCC_SHORT_CODE` | SCAPI short code |
| `--tenant-id` | `SFCC_TENANT_ID` | B2C tenant ID |
| `--json` | — | Output as JSON |
| `--log-level` | `SFCC_LOG_LEVEL` | trace/debug/info/warn/error/silent |

### Code Commands

| Command | Description |
|---|---|
| `b2c code list` | List all code versions with status |
| `b2c code deploy [CARTRIDGEPATH]` | Deploy cartridges via WebDAV |
| `b2c code download [CARTRIDGEPATH]` | Download cartridges from instance |
| `b2c code activate [CODEVERSION]` | Activate code version |
| `b2c code delete CODEVERSION` | Delete code version |
| `b2c code watch [CARTRIDGEPATH]` | Watch and auto-upload changes |

**code deploy flags**: `--activate/-a`, `--reload/-r`, `--delete`, `--cartridge/-c`, `--exclude-cartridge/-x`

**code watch environment variable**: `SFCC_UPLOAD_DEBOUNCE_TIME` (default: 100ms)

### Job Commands

| Command | Description |
|---|---|
| `b2c job run JOBID` | Execute a job |
| `b2c job wait JOBID EXECUTIONID` | Wait for execution |
| `b2c job search` | Search job executions |
| `b2c job log JOBID [EXECUTIONID]` | Get job log |
| `b2c job import TARGET` | Import site archive |
| `b2c job export` | Export site archive |

**job run flags**: `--wait/-w`, `--timeout/-t`, `--poll-interval`, `--param/-P`, `--body/-B`, `--no-wait-running`, `--show-log`

**job export flags**: `--site`, `--site-data`, `--global-data`, `--catalog`, `--price-book`, `--library`, `--inventory-list`, `--output/-o`, `--keep-archive/-k`, `--no-download`, `--zip-only`

### Sandbox (ODS) Commands

| Command | Description |
|---|---|
| `b2c sandbox list` | List all sandboxes |
| `b2c sandbox create` | Create sandbox |
| `b2c sandbox get SANDBOX_ID` | Get sandbox details |
| `b2c sandbox start SANDBOX_ID` | Start sandbox |
| `b2c sandbox stop SANDBOX_ID` | Stop sandbox |
| `b2c sandbox restart SANDBOX_ID` | Restart sandbox |
| `b2c sandbox reset SANDBOX_ID` | Reset (clear data/code) |
| `b2c sandbox delete SANDBOX_ID` | Delete sandbox |
| `b2c sandbox update SANDBOX_ID` | Update sandbox config |
| `b2c sandbox usage SANDBOX_ID` | Usage metrics |
| `b2c sandbox storage SANDBOX_ID` | Storage metrics |
| `b2c sandbox settings SANDBOX_ID` | OCAPI/WebDAV settings |
| `b2c sandbox ips SANDBOX_ID` | Inbound/outbound IPs |
| `b2c sandbox alias create` | Create custom hostname alias |
| `b2c sandbox alias list` | List aliases |
| `b2c sandbox alias delete` | Delete alias |
| `b2c sandbox clone create` | Clone sandbox |
| `b2c sandbox clone list` | List clones |
| `b2c sandbox realm list` | List realms |
| `b2c sandbox realm get REALM_ID` | Get realm details |
| `b2c sandbox realm update REALM_ID` | Update realm settings |
| `b2c sandbox realm usage REALM_ID` | Realm usage metrics |
| `b2c sandbox operations list` | List sandbox operations |

All `b2c sandbox` commands also work as `b2c ods` (backward compatibility).

**sandbox create flags**: `--realm` (required), `--ttl` (hours, default 24), `--profile` (medium/large/xlarge/xxlarge), `--wait`, `--auto-scheduled`

### SLAS Commands

| Command | Description |
|---|---|
| `b2c slas token` | Get shopper access token |
| `b2c slas client list` | List SLAS clients |
| `b2c slas client create` | Create SLAS client |
| `b2c slas client get CLIENT_ID` | Get client details |
| `b2c slas client update CLIENT_ID` | Update client |
| `b2c slas client delete CLIENT_ID` | Delete client |
| `b2c slas client open` | Open SLAS Admin UI |

**slas token flags**: `--site-id`, `--slas-client-id`, `--slas-client-secret`, `--shopper-login`, `--shopper-password`

### MRT Commands

| Command | Description |
|---|---|
| `b2c mrt project list` | List MRT projects |
| `b2c mrt project create` | Create MRT project |
| `b2c mrt project get PROJECT` | Get project details |
| `b2c mrt project delete PROJECT` | Delete project |
| `b2c mrt env list` | List environments |
| `b2c mrt env create` | Create environment |
| `b2c mrt env get PROJECT ENV` | Get environment |
| `b2c mrt env b2c` | Link environment to B2C instance |
| `b2c mrt env vars list` | List environment variables |
| `b2c mrt env vars set KEY=VALUE` | Set environment variable |
| `b2c mrt bundle push` | Push bundle (build + upload) |
| `b2c mrt bundle deploy` | Deploy existing bundle |
| `b2c mrt tail-logs` | Stream application logs |
| `b2c mrt save-credentials` | Save MRT API key |

**MRT auth**: `MRT_API_KEY`, `MRT_PROJECT`, `MRT_ENVIRONMENT` environment variables

### WebDAV Commands

| Command | Description |
|---|---|
| `b2c webdav ls [PATH]` | List files/directories |
| `b2c webdav get REMOTE [LOCAL]` | Download file |
| `b2c webdav put LOCAL REMOTE` | Upload file |
| `b2c webdav mkdir PATH` | Create directory |
| `b2c webdav rm PATH` | Delete file/directory |
| `b2c webdav zip PATH` | Server-side zip |
| `b2c webdav unzip PATH` | Server-side unzip |

**WebDAV root directories**: `impex` (default), `temp`, `cartridges`, `realmdata`, `catalogs`, `libraries`, `static`, `logs`, `securitylogs`

### eCDN Commands

| Command | Description |
|---|---|
| `b2c ecdn zones list` | List CDN zones |
| `b2c ecdn zones create` | Create zone |
| `b2c ecdn cache purge` | Purge cache by path or tag |
| `b2c ecdn certificates list` | List certificates |
| `b2c ecdn certificates add` | Add certificate |
| `b2c ecdn certificates validate` | Validate certificate |
| `b2c ecdn security get` | Get security settings |
| `b2c ecdn security update` | Update security (HSTS, TLS, WAF, HTTPS) |
| `b2c ecdn speed update` | Configure performance (Brotli, HTTP/3) |
| `b2c ecdn waf groups list` | WAF v1 groups |
| `b2c ecdn waf rules update` | WAF v1 rules |
| `b2c ecdn waf rulesets list` | WAF v2 rulesets |
| `b2c ecdn waf managed-rules update` | WAF v2 managed rules |
| `b2c ecdn waf migrate` | Migrate WAF v1 to v2 |
| `b2c ecdn logpush ownership` | Create logpush ownership token |
| `b2c ecdn logpush jobs create` | Create logpush job |
| `b2c ecdn mrt-rules create` | Create MRT routing rule |
| `b2c ecdn page-shield policies create` | Create Page Shield policy |

**eCDN auth scopes**: `sfcc.cdn-zones` (read), `sfcc.cdn-zones.rw` (write)

### SCAPI Commands

| Command | Description |
|---|---|
| `b2c scapi schemas list` | List SCAPI OpenAPI schemas |
| `b2c scapi custom-apis status` | Check custom API registration |

**SCAPI auth**: `sfcc.scapi-schemas` scope for schema browsing; `sfcc.custom-apis` for custom API status

### CIP Analytics Commands

| Command | Description |
|---|---|
| `b2c cip report REPORT_NAME` | Run curated analytics report |
| `b2c cip query "SQL"` | Execute raw SQL |
| `b2c cip tables` | List available tables |
| `b2c cip describe TABLE_NAME` | Describe table schema |

**cip report flags**: `--tenant-id`, `--site-id`, `--from` (date), `--to` (date)

**cip query flags**: `--tenant-id`, `--from`, `--to`, `--staging`

**CIP auth**: API client with `Salesforce Commerce API` role + tenant filter

### Account Manager Commands

| Command | Description |
|---|---|
| `b2c am users list` | List users |
| `b2c am users get EMAIL` | Get user details |
| `b2c am users create` | Create user |
| `b2c am users delete EMAIL` | Delete user |
| `b2c am roles grant EMAIL` | Grant role to user |
| `b2c am roles revoke EMAIL` | Revoke role from user |
| `b2c am orgs list` | List organizations |
| `b2c am clients list` | List API clients |
| `b2c am clients create` | Create API client |
| `b2c am clients update CLIENT_ID` | Update API client |
| `b2c am clients delete CLIENT_ID` | Delete API client |

### CAP Commands

| Command | Description |
|---|---|
| `b2c cap validate PATH` | Validate CAP structure |
| `b2c cap package PATH` | Package CAP as ZIP |
| `b2c cap install ZIP_PATH` | Install CAP to instance |
| `b2c cap uninstall APP_NAME` | Uninstall CAP |

### Scaffold Commands

| Command | Description |
|---|---|
| `b2c scaffold list` | List available scaffolds |
| `b2c scaffold cartridge --name NAME` | Generate cartridge |
| `b2c scaffold controller --name NAME` | Generate controller |
| `b2c scaffold hook --name NAME` | Generate hook |
| `b2c scaffold service --name NAME` | Generate web service |
| `b2c scaffold custom-api --name NAME` | Generate custom SCAPI endpoint |
| `b2c scaffold job-step --name NAME` | Generate custom job step |
| `b2c scaffold page-designer-component --name NAME` | Generate Page Designer component |
| `b2c scaffold init` | Initialize custom scaffold |

**Scaffold flags**: `--dry-run`, `--force`, `--output`

### Setup Commands

| Command | Description |
|---|---|
| `b2c setup` | Interactive initial setup |
| `b2c setup instance create` | Create instance configuration |
| `b2c setup instance set-active` | Switch active instance |
| `b2c setup instance list` | List configured instances |
| `b2c setup inspect` | Debug resolved config |
| `b2c setup ide prophet` | Configure Prophet VS Code integration |
| `b2c setup skills` | Install agent skills |
| `b2c setup skills --ide cursor` | Install skills for specific IDE |

---

## MCP Server Tools Reference

### CARTRIDGES Toolset

| Tool | Description |
|---|---|
| `cartridge_deploy` | Deploy cartridges to a B2C Commerce instance via WebDAV |

### MRT Toolset

| Tool | Description |
|---|---|
| `mrt_bundle_push` | Build, push bundle (optionally deploy) to Managed Runtime |

### SCAPI Toolset (Always Active)

| Tool | Description |
|---|---|
| `scapi_schemas_list` | List or fetch SCAPI OpenAPI schemas |
| `scapi_custom_api_generate_scaffold` | Generate custom SCAPI endpoint scaffold |
| `scapi_custom_apis_get_status` | Check custom API registration status |

### PWAV3 Toolset

| Tool | Description |
|---|---|
| `pwakit_get_guidelines` | Retrieve PWA Kit development guidelines |
| `scapi_schemas_list` | (shared with SCAPI) |
| `scapi_custom_api_generate_scaffold` | (shared with SCAPI) |
| `scapi_custom_apis_get_status` | (shared with SCAPI) |
| `mrt_bundle_push` | (shared with MRT) |

### STOREFRONTNEXT Toolset (Preview)

| Tool | Description |
|---|---|
| `sfnext_get_guidelines` | Storefront Next development guidelines |
| `sfnext_start_figma_workflow` | Start Figma-to-component workflow |
| `sfnext_analyze_component` | Analyze existing component |
| `sfnext_match_tokens_to_theme` | Match Figma tokens to theme |
| `sfnext_add_page_designer_decorator` | Add Page Designer support to component |
| `sfnext_configure_theme` | Configure storefront theme |

Note: STOREFRONTNEXT tools require `--allow-non-ga-tools` flag in MCP config.

---

## SDK Module Reference

Package: `@salesforce/b2c-tooling-sdk`

### Authentication Strategies

```typescript
import { OAuthStrategy, BasicAuthStrategy, ApiKeyStrategy } from '@salesforce/b2c-tooling-sdk/auth';
```

### Core Clients

```typescript
import { 
  createWebDavClient,
  createOcapiClient,
  createSlasClient,
  createOdsClient,
  createMrtClient,
  createAccountManagerClient
} from '@salesforce/b2c-tooling-sdk/clients';
```

### Configuration

```typescript
import { ConfigResolver } from '@salesforce/b2c-tooling-sdk/config';

const config = new ConfigResolver();
const resolved = await config.resolve();
// Returns: { hostname, clientId, clientSecret, username, password, codeVersion, shortCode, tenantId, ... }
```

### Operations

```typescript
// Code operations
import { deployCartridges, activateCodeVersion, listCodeVersions } from '@salesforce/b2c-tooling-sdk/code';

// Job operations
import { runJob, waitForExecution, searchExecutions } from '@salesforce/b2c-tooling-sdk/jobs';

// MRT operations
import { pushBundle, deployBundle } from '@salesforce/b2c-tooling-sdk/mrt';

// CIP analytics
import { createCipClient, executeCipReport, listCipTables } from '@salesforce/b2c-tooling-sdk';
```

### Safety Guard

```typescript
import { SafetyGuard } from '@salesforce/b2c-tooling-sdk/safety';

const guard = new SafetyGuard({ level: 'NO_DELETE' });
// Middleware that evaluates all HTTP requests against safety rules
```

### Discovery

```typescript
import { detectWorkspaceType } from '@salesforce/b2c-tooling-sdk/discovery';
// Returns: 'cartridges' | 'sfra' | 'pwa-kit' | 'storefront-next' | 'generic'
```

### MRT Utilities Package

Package: `@salesforce/mrt-utilities`

```typescript
import {
  createMRTCommonMiddleware,
  createMRTRequestProcessorMiddleware,
  createMRTProxyMiddlewares,
  createMRTStaticAssetServingMiddleware,
  createMRTCleanUpMiddleware,
  isLocal
} from '@salesforce/mrt-utilities';
```

**Environment variables for local dev**: `MRT_DATA_STORE_DEFAULTS` (JSON map), `MRT_DATA_STORE_WARN_ON_MISSING` (boolean)
