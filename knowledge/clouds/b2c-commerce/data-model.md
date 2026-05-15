# Salesforce B2C Commerce — Data Model

## Core Object Types

B2C Commerce uses a proprietary data model organized around system object types and custom object types. Configuration and extension of these objects occurs in Business Manager under `Administration > Site Development > System Object Types`.

---

## Catalog Structure

### Catalog
The top-level organizational unit for products:
- A **Catalog** contains categories and products
- Multiple catalogs can be assigned to a site
- One catalog is the **storefront catalog** (navigation-facing)
- Separate catalogs can be used for data import (master catalogs)

### Category
Hierarchical grouping of products:
- Categories belong to a catalog
- A category tree forms the site navigation structure
- Products are assigned to categories; one category per product can be the **primary category**

### Product Types

| Type | Description |
|---|---|
| **Simple Product** | A single purchasable SKU with no variations |
| **Variation Master** | A product with multiple variants (e.g., size/color) |
| **Variation Product (Variant)** | A specific SKU within a variation master |
| **Bundle** | Fixed set of products sold together as a single item |
| **Set** | A collection of products that can each be added to cart separately |
| **Option Product** | A product with configurable options (e.g., engraving) |

### Product Attributes
- **System attributes**: `id`, `name`, `description`, `shortDescription`, `longDescription`, `pageTitle`, `pageDescription`, `upc`, `brand`, `ean`, `searchable`, `online`, `available`, `price`, `currencyMnemonic`
- **Custom attributes**: Defined per product type in Business Manager; can be localized
- **Variation attributes**: Define the axes of variation (e.g., `color`, `size`)

---

## Order Objects

### Basket (Cart)
A transient shopping basket before checkout completion:
- Associated with a shopper session or registered customer
- Contains line items, shipping address, billing address, payment instruments
- Has a basket UUID as identifier
- Status: `open`, `closed`, `abandoned`

### Order
A confirmed purchase:
- Generated from a basket upon checkout completion
- Has an order number (string) as identifier
- Status values: `created`, `new`, `open`, `completed`, `cancelled`, `replaced`, `failed`
- Payment status: `not_paid`, `part_paid`, `paid`
- Shipping status: `not_shipped`, `part_shipped`, `shipped`
- Export status: `not_exported`, `exported`, `ready_to_export`

### Order Line Items
- **Product Line Item**: A product purchased; has quantity, price, tax
- **Shipping Line Item**: Shipping method and cost
- **Price Adjustment**: Promotions, coupons, discounts applied at line item or order level
- **Tax Line Item**: Tax amounts

### Payment Instruments
- Credit card, gift card, PayPal, custom payment methods
- Stored on basket/order with masked card data
- Status: `not_paid`, `paid`, `part_paid`

---

## Customer Objects

### Customer
A registered or guest shopper:
- **Customer No**: System-assigned unique identifier
- **Login** (email/username): For registered customers
- **Profile**: firstName, lastName, email, phone, birthday, gender
- **Customer Groups**: Rule-based (system) or manual (custom) groups
- **Addresses**: Stored address book
- **Payment Methods**: Stored payment instruments (tokenized)
- **Order History**: Past orders linked to customer

### Customer Group
Used for promotions, price books, and access control:
- **System Groups**: `Everyone`, `Registered`, `Unregistered`, `OCAPI`, `API` — automatically maintained
- **Custom Groups**: Manually assigned or rule-based (e.g., VIP, wholesale)

### Customer List
A collection of customers; each site is associated with a customer list.

---

## Content Objects

### Content Asset
Static content (HTML, text, images) managed in Business Manager:
- Has an ID, name, body (HTML), and assigned content slots
- Used for banners, landing pages, editorial content

### Content Slot
A placeholder in a template that renders content based on merchandising rules:
- Slot types: `global`, `category`, `folder`, `product`, `checkout`
- Content can be scheduled and targeted by customer group

### Library
A container for content assets and folders:
- **Shared Libraries**: Accessible across sites
- **Site Libraries**: Site-specific

### Page Designer
A drag-and-drop page composition tool:
- **Pages**: Top-level composable units
- **Components**: Reusable UI blocks
- **Regions**: Placeholders within components that accept child components
- Pages and components have JSON-serialized configuration

---

## Catalog/Pricing Objects

### Price Book
Defines product prices for specific contexts:
- Can be site-specific or shared
- Supports multiple currencies
- Price types: `list`, `sale`, `cost`
- Price books can have effective date ranges for sales

### Inventory List
Tracks stock levels:
- One default inventory list per site
- Can have multiple inventory lists (e.g., per warehouse)
- Fields: `ATS` (Available to Ship), `allocation`, `preorderBackorderHandling`, `inStockDate`

### Promotion
Marketing discount rules:
- Linked to **Campaigns**
- Discount types: `amount off`, `percentage off`, `fixed price`, `free`, `bonus product`
- Conditions: `customer group`, `coupon`, `source code`, `date range`
- Can apply to: product, order total, shipping

### Coupon
A specific promotion trigger:
- Single-use or multi-use
- System-generated or custom code
- Must be applied to a promotion

---

## Custom Objects

B2C Commerce supports Custom Objects for storing arbitrary structured data:
- Defined in Business Manager under `Administration > Site Development > Custom Object Types`
- Fields can be: `string`, `integer`, `number`, `boolean`, `date`, `datetime`, `email`, `enum of strings`, `enum of integers`, `HTML`, `text`, `image`, `password`, `set of strings`, `set of integers`, `set of numbers`
- Accessible via OCAPI and server-side scripts
- Can be site-scoped or organization-scoped

---

## SCAPI Data Models

SCAPI (Salesforce Commerce APIs) exposes B2C data through OpenAPI 3.0 specifications. Key resource schemas:

### Shopper Login (SLAS)
- `token-request`: `grant_type`, `code`, `redirect_uri`, `code_verifier`, `client_id`, `channel_id`, `organizationId`
- `token-response`: `access_token`, `refresh_token`, `token_type`, `expires_in`, `usid`, `customer_id`, `enc_user_id`

### Shopper Products
- `Product`: `id`, `name`, `longDescription`, `shortDescription`, `price`, `currency`, `imageGroups`, `variationAttributes`, `variants`, `brand`, `upc`, `stepQuantity`, `minOrderQuantity`, `online`
- `ProductSearchResult`: `hits` (array of `ProductSearchHit`), `refinements`, `selectedRefinements`, `searchPhraseSuggestions`, `total`, `start`, `count`

### Shopper Baskets
- `Basket`: `basketId`, `customerId`, `currency`, `productItems`, `shippingItems`, `paymentInstruments`, `shipments`, `taxTotal`, `orderTotal`, `productTotal`, `shippingTotal`, `adjustedTaxTotal`
- `ProductItem`: `itemId`, `productId`, `quantity`, `price`, `priceAfterItemDiscount`, `priceAfterOrderDiscount`, `adjustedTax`

### Shopper Orders
- `Order`: `orderNo`, `status`, `paymentStatus`, `shippingStatus`, `exportStatus`, `productItems`, `orderTotal`, `currency`, `creationDate`, `customerInfo`
- `OrderAddress`: `firstName`, `lastName`, `address1`, `address2`, `city`, `stateCode`, `postalCode`, `countryCode`, `phone`

### Shopper Customers
- `Customer`: `customerId`, `customerNo`, `login`, `firstName`, `lastName`, `email`, `enabled`, `customerGroups`
- `CustomerAddress`: Standard address fields with `addressId` key

---

## OCAPI Data Models

OCAPI is the legacy API layer using a different endpoint structure:

### Data API Resource Paths
```
/s/-/dw/data/v21_3/products/{product_id}
/s/-/dw/data/v21_3/catalog_search
/s/-/dw/data/v21_3/orders/{order_no}
/s/-/dw/data/v21_3/customers/{customer_no}
/s/-/dw/data/v21_3/code_versions
/s/-/dw/data/v21_3/sites/{site_id}
/s/-/dw/data/v21_3/jobs/{job_id}/executions
```

### Shop API Resource Paths
```
/s/{site_id}/dw/shop/v21_3/baskets
/s/{site_id}/dw/shop/v21_3/orders/{order_no}
/s/{site_id}/dw/shop/v21_3/customers/{customer_id}
/s/{site_id}/dw/shop/v21_3/product_search
/s/{site_id}/dw/shop/v21_3/products/{product_id}
```

---

## IMPEX — Import/Export Data Format

B2C Commerce uses XML-based site archives for data exchange:
- **Catalogs**: `catalog.xml` with product definitions, category assignments, images
- **Inventory**: `inventory.xml` with stock levels per SKU and inventory list
- **Price Books**: `pricebook.xml` with prices per SKU, currency, and date range
- **Customers**: `customers.xml` with customer profiles and addresses
- **Orders**: `orders.xml` for order history import
- **Sites**: `site.xml` for site preferences, payment methods, shipping methods
- **Libraries**: `library.xml` for content assets
- **Metadata**: `meta.xml` for custom attribute and object type definitions

Archives are ZIP files uploaded to WebDAV at `Impex/src/` and processed via the `sfcc-site-archive-import` system job.
