# Salesforce B2C Commerce — Implementation Guide

## Prerequisites

Before starting B2C Commerce development, ensure you have:

1. **Node.js** >= 22.16.0 (required for B2C CLI and MCP server)
2. **B2C Commerce instance access** — either a sandbox (SIG) or production instance (PIG)
3. **Account Manager account** at `https://account.demandware.com`
4. **Business Manager access** on the target instance
5. A code editor (VS Code or Cursor recommended for MCP integration)

---

## Step 1: Install the B2C CLI

### Option A: npm (Recommended)

```bash
npm install -g @salesforce/b2c-cli
```

### Option B: pnpm

```bash
pnpm add -g @salesforce/b2c-cli
```

### Option C: Homebrew (macOS/Linux)

```bash
brew install SalesforceCommerceCloud/tools/b2c-cli
```

### Verify Installation

```bash
b2c --version
```

---

## Step 2: Create an Account Manager API Client

Access Account Manager at `https://account.demandware.com`:

1. Navigate to **API Client** section
2. Click **Add API Client**
3. Provide a display name (e.g., `My Dev CLI Client`)
4. Set a strong password — this is your `client_secret`
5. Configure **Token Endpoint Auth Method**: `client_secret_basic`
6. Add **Default Scopes**: `mail`, `roles`, `tenantFilter`, `openid`
7. Add **Redirect URLs**: `http://localhost:8080`
8. Save the client ID (UUID format) and secret securely

### Assign Required Roles

For full development access, assign to the API client:
- **Salesforce Commerce API** role with tenant filter (your tenant ID, e.g., `abcd_prd`)
- **Sandbox API User** role with realm/org filter

For SLAS management (user auth only, cannot be delegated to API client):
- Log in as a user with **SLAS Organization Administrator** role

---

## Step 3: Configure OCAPI Permissions

In Business Manager on each instance:

1. Go to `Administration > Site Development > Open Commerce API Settings`
2. Select **Data API** type
3. Add your client ID and grant resource permissions:

```json
{
  "client_id": "your-client-id",
  "resources": [
    {
      "resource_id": "/code_versions",
      "methods": ["get"],
      "read_attributes": "(**)"
    },
    {
      "resource_id": "/code_versions/*",
      "methods": ["get", "put", "patch", "delete"],
      "read_attributes": "(**)",
      "write_attributes": "(**)"
    },
    {
      "resource_id": "/jobs/*/executions",
      "methods": ["post"],
      "write_attributes": "(**)"
    },
    {
      "resource_id": "/jobs/*/executions/*",
      "methods": ["get"],
      "read_attributes": "(**)"
    },
    {
      "resource_id": "/job_execution_search",
      "methods": ["post"],
      "read_attributes": "(**)"
    },
    {
      "resource_id": "/sites",
      "methods": ["get"],
      "read_attributes": "(**)"
    }
  ]
}
```

---

## Step 4: Generate a WebDAV Access Key

For cartridge deployment via WebDAV:

1. In Business Manager, go to `Administration > Organization > Users`
2. Click your username
3. Select **Create Access Key**
4. Note the generated key (shown only once)
5. This key is your `SFCC_PASSWORD` for WebDAV operations

---

## Step 5: Configure CLI Credentials

### Option A: dw.json (Project-Level, Recommended)

Create a `dw.json` in your project root:

```json
{
  "hostname": "your-sandbox.dx.commercecloud.salesforce.com",
  "code-version": "version1",
  "client-id": "your-client-id",
  "client-secret": "your-client-secret",
  "username": "your-bm-username",
  "password": "your-webdav-access-key",
  "short-code": "aaaa1234",
  "tenant-id": "abcd_prd"
}
```

**Add `dw.json` to `.gitignore`** — it contains secrets.

### Option B: Environment Variables

```bash
export SFCC_SERVER=your-sandbox.dx.commercecloud.salesforce.com
export SFCC_CLIENT_ID=your-client-id
export SFCC_CLIENT_SECRET=your-client-secret
export SFCC_USERNAME=your-bm-username
export SFCC_PASSWORD=your-webdav-access-key
export SFCC_CODE_VERSION=version1
export SFCC_SHORTCODE=aaaa1234
export SFCC_TENANT_ID=abcd_prd
```

### Option C: Interactive Setup

```bash
b2c setup
```

This prompts for all required values and writes configuration.

### Multiple Instance Configuration

```json
{
  "active": "sandbox",
  "configs": [
    {
      "name": "sandbox",
      "hostname": "my-sandbox.dx.commercecloud.salesforce.com",
      "code-version": "version1",
      "client-id": "your-client-id",
      "client-secret": "your-secret"
    },
    {
      "name": "staging",
      "hostname": "staging.dx.commercecloud.salesforce.com",
      "code-version": "version1",
      "client-id": "your-client-id",
      "client-secret": "your-secret"
    }
  ]
}
```

Switch active instance:
```bash
b2c setup instance set-active staging
```

### Inspect Resolved Configuration

```bash
b2c setup inspect
```

---

## Step 6: Verify CLI Connectivity

Test each connection type:

```bash
# Test OCAPI (code version list)
b2c code list

# Test WebDAV (list impex directory)
b2c webdav ls

# Test SCAPI schema access
b2c scapi schemas list

# Test sandbox access (if using ODS)
b2c sandbox list
```

---

## Step 7: Create an On-Demand Sandbox (Optional)

If you need a fresh development sandbox:

```bash
# Create sandbox in your realm
b2c sandbox create --realm zzzv --wait

# List sandboxes to get hostname
b2c sandbox list
```

After creation, update `dw.json` with the new sandbox hostname.

---

## Step 8: Set Up SLAS Client

Required for PWA Kit / Composable Storefront and any headless storefront using SCAPI shopper APIs:

```bash
# Create a SLAS client (requires user auth with SLAS Organization Administrator role)
b2c slas client create --tenant-id abcd_prd

# Store the client secret immediately — it's shown only once

# Verify creation
b2c slas client list --tenant-id abcd_prd
```

Store the SLAS client ID and secret in your environment:
```bash
export SFCC_SLAS_CLIENT_ID=your-slas-client-id
export SFCC_SLAS_CLIENT_SECRET=your-slas-client-secret
```

---

## Step 9: Deploy Cartridges (SFRA Projects)

### First-Time Setup

Ensure your project has `.project` files in each cartridge directory. The presence of `.project` is how the CLI detects cartridges.

```bash
# Deploy all cartridges from current directory
b2c code deploy

# Deploy and activate
b2c code deploy --activate

# Deploy specific cartridges only
b2c code deploy -c app_custom -c int_myintegration

# Deploy with delete (removes existing cartridges in code version first)
b2c code deploy --delete --activate
```

### Development Workflow (Watch Mode)

```bash
# Watch for changes and auto-upload
b2c code watch

# Watch specific cartridges
b2c code watch -c app_custom
```

### Activate Code Version

```bash
b2c code activate version1
b2c code activate --reload   # Force reload current active version
```

---

## Step 10: Register Cartridges in Business Manager

After deployment, register cartridges to each site:

1. Go to `Administration > Sites > Manage Sites > [Site ID] > Settings`
2. In the **Cartridges** field, enter colon-separated cartridge names:
   ```
   app_custom:app_storefront_base:modules
   ```
3. Save

Custom cartridges must go LEFT of the base cartridge.

---

## Step 11: Import Site Data

For a fresh sandbox, import catalog, inventory, and site configuration:

```bash
# Import from local directory
b2c job import ./site-data-archive

# Import from ZIP
b2c job import ./site-export.zip

# Wait for completion with timeout
b2c job import ./site-data-archive --wait --timeout 600
```

---

## Step 12: Configure MCP Server (AI-Assisted Development)

### Claude Code

From your project directory:

```bash
# Add via plugin marketplace
claude plugin marketplace add SalesforceCommerceCloud/b2c-developer-tooling
claude plugin install b2c-dx-mcp
```

Or add to your Claude Code settings (`.claude/settings.json`):

```json
{
  "mcpServers": {
    "b2c-dx-mcp": {
      "command": "npx",
      "args": ["@salesforce/b2c-dx-mcp@latest"]
    }
  }
}
```

### Cursor (Project-Level)

Create `.cursor/mcp.json` in project root:

```json
{
  "mcpServers": {
    "b2c-dx-mcp": {
      "command": "npx",
      "args": ["@salesforce/b2c-dx-mcp@latest"]
    }
  }
}
```

### GitHub Copilot (VS Code)

Create `.vscode/mcp.json`:

```json
{
  "servers": {
    "b2c-dx-mcp": {
      "type": "stdio",
      "command": "npx",
      "args": ["@salesforce/b2c-dx-mcp@latest"]
    }
  }
}
```

### MCP Configuration (dw.json)

The MCP server reads credentials from `dw.json` in the project root or environment variables. Place `dw.json` in your project root before starting the MCP server.

### Verify MCP Project Detection

The MCP server auto-detects project type:
- **PWA Kit v3**: Detected by dependencies in `package.json` → Activates PWAV3, MRT, SCAPI toolsets
- **Storefront Next**: Detected by workspace package with storefront-next dependency → Activates STOREFRONTNEXT, MRT, CARTRIDGES, SCAPI toolsets
- **Cartridges**: Detected by `.project` file → Activates CARTRIDGES, SCAPI toolsets
- **Generic**: No B2C markers found → SCAPI only

---

## Step 13: Install Agent Skills (Optional)

For AI coding agent integration (Claude Code, Cursor, Copilot):

```bash
# Install all skills via CLI
b2c setup skills

# Install for specific IDE
b2c setup skills --ide cursor
b2c setup skills --ide agentforce-vibes

# Install via Claude Code
claude plugin marketplace add SalesforceCommerceCloud/b2c-developer-tooling
claude plugin install b2c-cli
claude plugin install b2c
```

---

## Step 14: Set Up VS Code Extension (Developer Preview)

1. Download the `.vsix` from [GitHub Releases](https://github.com/SalesforceCommerceCloud/b2c-developer-tooling/releases)
2. Install:
   ```bash
   code --install-extension b2c-vs-extension-0.7.0.vsix
   # Or for Cursor:
   cursor --install-extension b2c-vs-extension-0.7.0.vsix
   ```
3. Configure sandbox connection via the B2C DX activity bar

**Extension features**: Sandbox lifecycle management, cartridge sync, WebDAV browser, SCAPI explorer, server-side script debugger, content library browser, scaffolding

---

## Step 15: Set Up Prophet (Legacy SFRA Development)

For SFRA development with the Prophet VS Code extension:

```bash
# Generate Prophet-compatible bridge script
b2c setup ide prophet

# Force regenerate
b2c setup ide prophet --force
```

This creates a `.vscode/dw.js` script that Prophet uses to load CLI-resolved configuration including hostname, credentials, cartridge path, and code version.

---

## PWA Kit / Composable Storefront Setup

### Prerequisites

- Node.js >= 22.16.0
- MRT API key from `runtime.commercecloud.com`

### Initialize PWA Kit Project

```bash
npx pwa-kit-create-app
```

### Configure MRT Project

```bash
# Save MRT credentials
b2c mrt save-credentials --user email@example.com --api-key your-mrt-api-key

# Create MRT project (or use existing)
b2c mrt project list

# Create environment
b2c mrt env create --slug my-env --project my-project

# Link to B2C instance
b2c mrt env b2c --project my-project --env my-env
```

### Configure Environment Variables

```bash
b2c mrt env vars set COMMERCE_API_CLIENT_ID=your-slas-client-id --project my-project --env my-env
b2c mrt env vars set COMMERCE_API_ORGANIZATION_ID=f_ecom_abcd_prd --project my-project --env my-env
b2c mrt env vars set COMMERCE_API_SITE_ID=RefArch --project my-project --env my-env
b2c mrt env vars set COMMERCE_API_SHORT_CODE=aaaa1234 --project my-project --env my-env
b2c mrt env vars set SLAS_CLIENT_SECRET=your-slas-secret --project my-project --env my-env
```

### Deploy Bundle

```bash
# Build and push
b2c mrt bundle push --project my-project --env my-env

# Tail logs
b2c mrt tail-logs --project my-project --env my-env
```

---

## CI/CD Setup with GitHub Actions

### Store Secrets in GitHub

Required secrets:
- `SFCC_CLIENT_ID`
- `SFCC_CLIENT_SECRET`
- `SFCC_USERNAME`
- `SFCC_PASSWORD`
- `MRT_API_KEY`

Required variables:
- `SFCC_SERVER`
- `MRT_PROJECT`
- `MRT_ENVIRONMENT`

### Example Deployment Workflow

```yaml
name: Deploy to B2C Commerce

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Install B2C CLI
        run: npm install -g @salesforce/b2c-cli
      - name: Deploy cartridges
        env:
          SFCC_SERVER: ${{ vars.SFCC_SERVER }}
          SFCC_CLIENT_ID: ${{ secrets.SFCC_CLIENT_ID }}
          SFCC_CLIENT_SECRET: ${{ secrets.SFCC_CLIENT_SECRET }}
          SFCC_USERNAME: ${{ secrets.SFCC_USERNAME }}
          SFCC_PASSWORD: ${{ secrets.SFCC_PASSWORD }}
          SFCC_CODE_VERSION: ${{ github.sha }}
        run: |
          b2c code deploy --activate
```

### Production Safety in CI/CD

```yaml
- name: Deploy to Production (with safety)
  env:
    SFCC_SAFETY_LEVEL: NO_DELETE
    # ... other vars
  run: b2c code deploy
```

---

## Scaffolding New Components

### Generate Cartridge

```bash
b2c scaffold cartridge --name app_custom
```

Creates standard cartridge structure with:
- `cartridge/controllers/`
- `cartridge/templates/`
- `cartridge/scripts/`
- `cartridge/static/`
- `.project` file
- `package.json`

### Generate Controller

```bash
b2c scaffold controller --name Account
```

### Generate Hook

```bash
b2c scaffold hook --name app.order.created
```

### Generate Custom SCAPI Endpoint

```bash
b2c scaffold custom-api --name MyService
```

### Preview Without Writing

```bash
b2c scaffold cartridge --name app_custom --dry-run
```
