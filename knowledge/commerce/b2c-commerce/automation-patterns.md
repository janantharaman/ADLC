# Salesforce B2C Commerce — Automation Patterns

## Hooks

Hooks are the primary event-driven extension mechanism in B2C Commerce (SFRA). They allow cartridges to intercept and modify platform behavior without overriding core files.

### How Hooks Work

1. A hook point is defined in a `hooks.json` file at the root of a cartridge
2. The platform calls registered hook functions when specific events occur
3. Multiple cartridges can register to the same hook point; execution order follows cartridge path order

### hooks.json Structure

```json
{
  "hooks": [
    {
      "name": "app.payment.processor.default",
      "script": "~/cartridge/scripts/hooks/payment/paymentProcessorHook"
    },
    {
      "name": "app.order.created",
      "script": "~/cartridge/scripts/hooks/orderCreated"
    }
  ]
}
```

### Common Hook Points

| Hook | When Called |
|---|---|
| `app.payment.processor.default` | Default payment processor |
| `app.payment.processor.credit` | Credit card payment |
| `app.payment.processor.paypal` | PayPal payment |
| `app.fraud.detection` | Fraud screening |
| `app.order.created` | After order creation |
| `app.customer.created` | After customer registration |
| `app.shipping.shippingMethods` | Shipping method filtering |
| `app.storefront.addCartItem` | Adding item to cart |
| `app.order.calculate` | Order totals calculation |

### Hook Script Pattern

```javascript
'use strict';

/**
 * @type {dw.system.HookMgr}
 */

function handle(basket, req) {
    // Your implementation here
    return new Status(Status.OK);
}

module.exports = {
    handle: handle
};
```

---

## Controllers (SFRA)

Controllers replace legacy Pipelines in SFRA and handle HTTP request routing.

### Controller Structure

Controllers are JavaScript files in `cartridge/controllers/` that define route handlers:

```javascript
'use strict';

var server = require('server');
var cache = require('*/cartridge/scripts/middleware/cache');
var consentTracking = require('*/cartridge/scripts/middleware/consentTracking');

// New route (original endpoint)
server.get('Show', cache.applyDefaultCache, consentTracking.consent, function (req, res, next) {
    var viewData = {};
    // ... populate view data
    res.render('account/profile', viewData);
    next();
});

// Override existing route (extend, not replace)
server.prepend('Show', function (req, res, next) {
    // Run before the base controller's Show
    next();
});

server.append('Show', function (req, res, next) {
    // Run after the base controller's Show
    var viewData = res.getViewData();
    // Modify viewData
    res.setViewData(viewData);
    next();
});

module.exports = server.exports();
```

### Controller Extension Pattern

Custom cartridges use `server.prepend()` and `server.append()` to extend base SFRA controllers without overriding them:
- `prepend`: Runs before the base route handler
- `append`: Runs after the base route handler
- The original implementation in the base cartridge is preserved

### Middleware

Middleware functions are chainable request processors:
- `cache.applyDefaultCache` — Sets cache headers
- `consentTracking.consent` — Consent tracking middleware
- `userLoggedIn.validateLoggedIn` — Authentication check
- Custom middleware: Any function matching `(req, res, next)` signature

---

## ISML Templates

ISML (Internet Store Markup Language) is the server-side templating language:

```html
<iscomment>
  Renders a product tile
</iscomment>
<div class="product-tile">
    <isprint value="${pdict.product.name}" encoding="htmlcontent" />
    <isif condition="${pdict.product.price.sales}">
        <span class="price">${pdict.product.price.sales.formatted}</span>
    </isif>
    <isinclude template="product/components/addToCartButton" />
</div>
```

Key ISML tags:
- `<isif>`, `<iselseif>`, `<iselse>` — conditionals
- `<isloop>` — iteration over collections
- `<isinclude>` — include another template
- `<isdecorate>` — wrap content in a layout template
- `<isprint>` — output with encoding
- `<isscript>` — inline server-side JavaScript (use sparingly)
- `<ismodule>` — register a custom tag
- `<iscomment>` — comments (not rendered to HTML)

---

## Pipelines (Legacy)

Pipelines are the legacy request-processing mechanism, replaced by Controllers in SFRA:
- XML-based visual workflow definitions
- Still used in legacy SiteGenesis storefronts
- Pipeline files have `.xml` extension and are stored in the `pipelines/` directory
- The `b2c-plugin-pipeline-visualizer` community plugin generates ASCII/SVG previews of pipeline XML

---

## Jobs and Job Steps

### System Jobs

Built-in jobs provided by Salesforce:

| Job ID | Purpose |
|---|---|
| `sfcc-site-archive-import` | Import site archive (IMPEX) |
| `sfcc-site-archive-export` | Export site archive |
| `sfcc-search-index-product-full-update` | Full product search index rebuild |
| `sfcc-search-index-product-delta-update` | Delta product search index update |
| `sfcc-search-index-category-update` | Category search index update |
| `sfcc-search-index-content-update` | Content search index update |
| `sfcc-sync-global-data` | Sync global data |

### Custom Job Steps

Custom job steps are registered via a `steptypes.json` file in a cartridge:

```json
{
  "step-types": [
    {
      "@type-id": "custom.MyJobStep",
      "description": "My custom job step",
      "module": "int_custom/cartridge/scripts/jobs/myJobStep",
      "transactional": true,
      "parameters": {
        "parameter": [
          {
            "@name": "SiteScope",
            "description": "Site scope",
            "@type": "string",
            "@required": false,
            "@trim": true
          }
        ]
      }
    }
  ]
}
```

Custom job step module pattern:

```javascript
'use strict';

/**
 * execute - main entry point for the job step
 * @param {dw.util.HashMap} parameters - job step parameters
 * @param {dw.job.JobStepExecution} stepExecution - job step execution context
 */
function execute(parameters, stepExecution) {
    var siteScope = parameters.custom.SiteScope;
    // Your logic here
    return new Status(Status.OK);
}

module.exports = {
    execute: execute
};
```

### CLI Job Commands

```bash
# Run a job
b2c job run my-custom-job

# Run with wait
b2c job run my-custom-job --wait

# Run with timeout (seconds)
b2c job run my-custom-job --wait --timeout 600

# Run with parameters
b2c job run my-custom-job -P "SiteScope={\"all_storefront_sites\":true}" -P OtherParam=value

# Run system job with body
b2c job run sfcc-search-index-product-full-update --wait --body '{"site_scope":["RefArch","SiteGenesis"]}'

# Wait for specific execution
b2c job wait my-job abc123-def456

# Search job executions
b2c job search --job-id my-custom-job
b2c job search --status RUNNING,PENDING

# Get job log
b2c job log my-custom-job
b2c job log my-custom-job --failed
b2c job log my-custom-job abc123-def456

# Import a site archive
b2c job import ./my-site-data
b2c job import ./export.zip
b2c job import ./my-site-data --keep-archive

# Export a site archive
b2c job export --global-data meta_data
b2c job export --site RefArch --site-data content,site_preferences
b2c job export --catalog storefront-catalog
b2c job export --output ./exports
```

### Export Data Units

**Site Data Types**: `all`, `content`, `site_preferences`, `campaigns_and_promotions`, `customer_groups`, `payment_methods`

**Global Data Types**: `all`, `meta_data`, `custom_types`, `preferences`, `locales`, `services`

---

## SCAPI Custom APIs

Custom APIs allow developers to create new SCAPI REST endpoints backed by server-side B2C Commerce scripts.

### Registration

Custom APIs are defined via OpenAPI 3.0 specification (OAS 3.0) and registered with SCAPI. The scaffold command generates the skeleton:

```bash
b2c scaffold custom-api --name MyCustomAPI
```

Or via MCP:
```
scapi_custom_api_generate_scaffold
```

### Check Custom API Status

```bash
b2c scapi custom-apis status --tenant-id abcd_prd --short-code aaaa1234
```

### Custom API Endpoint Pattern

Custom APIs follow RESTful conventions and are served under:
```
https://<short-code>.api.commercecloud.salesforce.com/custom/<api-name>/<version>/...
```

---

## SCAPI Endpoints (Key API Families)

SCAPI uses the URL pattern:
```
https://<short-code>.api.commercecloud.salesforce.com/<api-family>/<version>/organizations/<org-id>/...
```

### Shopper Login (SLAS)

| Method | Path | Description |
|---|---|---|
| `POST` | `/shopper/auth/v1/organizations/{organizationId}/oauth2/token` | Get access token |
| `GET` | `/shopper/auth/v1/organizations/{organizationId}/oauth2/authorize` | Authorization endpoint |
| `POST` | `/shopper/auth/v1/organizations/{organizationId}/oauth2/logout` | Logout |
| `POST` | `/shopper/auth/v1/organizations/{organizationId}/oauth2/trusted-agent/token` | Trusted agent token |

### Shopper Customers

| Method | Path | Description |
|---|---|---|
| `POST` | `/customer/shopper-customers/v1/organizations/{organizationId}/customers` | Register customer |
| `GET` | `/customer/shopper-customers/v1/organizations/{organizationId}/customers/{customerId}` | Get customer |
| `PATCH` | `/customer/shopper-customers/v1/organizations/{organizationId}/customers/{customerId}` | Update customer |
| `POST` | `/customer/shopper-customers/v1/organizations/{organizationId}/customers/{customerId}/addresses` | Add address |
| `GET` | `/customer/shopper-customers/v1/organizations/{organizationId}/customers/{customerId}/orders` | Get orders |

### Shopper Baskets

| Method | Path | Description |
|---|---|---|
| `POST` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets` | Create basket |
| `GET` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}` | Get basket |
| `DELETE` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}` | Delete basket |
| `POST` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}/items` | Add item |
| `PATCH` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}/items/{itemId}` | Update item |
| `PUT` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}/shipments/{shipmentId}/shipping-address` | Set shipping address |
| `PUT` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}/billing-address` | Set billing address |
| `POST` | `/checkout/shopper-baskets/v1/organizations/{organizationId}/baskets/{basketId}/payment-instruments` | Add payment |

### Shopper Orders

| Method | Path | Description |
|---|---|---|
| `POST` | `/checkout/shopper-orders/v1/organizations/{organizationId}/orders` | Create order from basket |
| `GET` | `/checkout/shopper-orders/v1/organizations/{organizationId}/orders/{orderNo}` | Get order |
| `POST` | `/checkout/shopper-orders/v1/organizations/{organizationId}/orders/{orderNo}/payment-instruments` | Add payment |

### Shopper Products

| Method | Path | Description |
|---|---|---|
| `GET` | `/product/shopper-products/v1/organizations/{organizationId}/products` | Get multiple products |
| `GET` | `/product/shopper-products/v1/organizations/{organizationId}/products/{id}` | Get product |
| `GET` | `/product/shopper-products/v1/organizations/{organizationId}/categories/{id}` | Get category |

### Shopper Search

| Method | Path | Description |
|---|---|---|
| `GET` | `/search/shopper-search/v1/organizations/{organizationId}/product-search` | Product search |
| `GET` | `/search/shopper-search/v1/organizations/{organizationId}/search-suggestions` | Search suggestions |

### Shopper Experience (Page Designer)

| Method | Path | Description |
|---|---|---|
| `GET` | `/experience/shopper-experience/v1/organizations/{organizationId}/pages` | Get pages |
| `GET` | `/experience/shopper-experience/v1/organizations/{organizationId}/pages/{pageId}` | Get specific page |
| `GET` | `/experience/shopper-experience/v1/organizations/{organizationId}/pages/{pageId}/components/{componentId}` | Get component |

---

## Cartridge Extension Pattern

The B2C Commerce cartridge extension pattern allows customization without forking base code:

### Cartridge Path and Override Mechanism

```
# Business Manager Cartridge Path:
app_custom:app_storefront_base

# Resolution: app_custom is checked first, then app_storefront_base
```

### Override a Template

Create the same relative path in your custom cartridge:
```
app_custom/cartridge/templates/default/product/productTile.isml
# Overrides:
app_storefront_base/cartridge/templates/default/product/productTile.isml
```

### Override a Script

```
app_custom/cartridge/scripts/helpers/productHelpers.js
# Overrides:
app_storefront_base/cartridge/scripts/helpers/productHelpers.js
```

### Extend (Not Override) a Controller

In `app_custom/cartridge/controllers/Product.js`:
```javascript
'use strict';
var server = require('server');
server.extend(module.superModule); // Inherit base controller

server.append('Show', function (req, res, next) {
    var viewData = res.getViewData();
    // Add custom data
    viewData.customData = 'hello';
    res.setViewData(viewData);
    next();
});

module.exports = server.exports();
```

### Site-Specific vs. Organization-Wide Cartridges

- **Site-specific cartridge paths** are configured per site in Business Manager
- **Organization-level BM cartridges** are registered separately in Administration > Global Preferences

---

## Commerce App Packages (CAPs)

CAPs are the standard distribution format for B2C Commerce integrations:

### Directory Structure
```
commerce-{app}-v{version}/
├── commerce-app.json          # Required: app manifest
├── README.md                  # Required: documentation
├── app-configuration/
│   └── tasksList.json         # Required: post-install setup wizard
├── cartridges/
├── icons/
├── impex/
└── storefront-next/
```

### CLI Commands

```bash
# Validate CAP structure
b2c cap validate ./commerce-my-integration-v1.0.0

# Package as distributable ZIP
b2c cap package ./commerce-my-integration-v1.0.0 --output ./dist

# Install to sandbox
b2c cap install ./dist/my-integration-v1.0.0.zip --site RefArch

# Uninstall
b2c cap uninstall my-integration --domain tax --site RefArch
```

---

## Web Services

B2C Commerce supports calling external services via the `dw.svc.LocalServiceRegistry`:

```javascript
var LocalServiceRegistry = require('dw/svc/LocalServiceRegistry');

var myService = LocalServiceRegistry.createService('my.service.name', {
    createRequest: function (svc, params) {
        svc.setRequestMethod('POST');
        svc.addHeader('Content-Type', 'application/json');
        return JSON.stringify(params);
    },
    parseResponse: function (svc, result) {
        return JSON.parse(result.getText());
    },
    mockCall: function (svc, params) {
        return { statusCode: 200, statusMessage: 'OK', text: '{}' };
    }
});

var result = myService.call({ key: 'value' });
if (result.isOk()) {
    var response = result.getObject();
}
```

Services are configured in Business Manager under `Administration > Operations > Services`.
