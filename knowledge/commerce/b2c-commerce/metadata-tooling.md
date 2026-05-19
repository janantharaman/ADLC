# Salesforce B2C Commerce — Metadata and Tooling

## Cartridge Deployment via CLI and MCP

### CLI-Based Deployment (b2c code deploy)

The `b2c code deploy` command is the primary mechanism for deploying cartridges:

**How it works**:
1. CLI scans the specified directory (default: current directory) for `.project` files
2. For each discovered cartridge directory, a ZIP archive is created
3. Archives are uploaded via WebDAV to `/Cartridges/<code-version>/` on the instance
4. Optionally, the code version is activated after upload

**Authentication**: WebDAV (Basic Auth or OAuth)

```bash
# Basic deploy
b2c code deploy

# Deploy from specific path
b2c code deploy ./my-project

# Deploy and activate
b2c code deploy --activate

# Deploy with force-reload (toggle activation to flush cache)
b2c code deploy --activate --reload

# Deploy specific cartridges
b2c code deploy -c app_custom -c int_myintegration

# Exclude specific cartridges
b2c code deploy --exclude-cartridge app_storefront_base

# Delete existing cartridges in code version before upload
b2c code deploy --delete --activate

# Deploy with explicit instance and code version
b2c code deploy --server my-sandbox.demandware.net --code-version v1

# JSON output for CI/CD parsing
b2c code deploy --json
```

### MCP-Based Deployment (cartridge_deploy tool)

The `cartridge_deploy` MCP tool enables AI agents to deploy cartridges:

```
Use the MCP tool to deploy cartridges to my sandbox
```

The `cartridge_deploy` tool in the CARTRIDGES toolset:
- Auto-detects cartridges via `.project` files
- Uses credentials from `dw.json` or environment variables
- Equivalent to running `b2c code deploy` with appropriate flags

**Project type detection for CARTRIDGES toolset activation**:
- Requires a `.project` file anywhere in the workspace
- If detected, CARTRIDGES toolset is automatically activated

---

## Code Version Management

### Listing Code Versions

```bash
b2c code list
# Output includes: ID, active status, rollback status, modification time, cartridge count

b2c code list --json
```

### Activation and Rollback

```bash
# Activate a specific version
b2c code activate v2

# Activate with reload (toggle to flush cache)
b2c code activate v2 --reload

# Reload current active version (toggle without switching)
b2c code activate --reload
```

**Reload mechanism**: When `--reload` is used, the CLI:
1. Notes the current active code version
2. Activates a different version temporarily
3. Re-activates the original (or new) target version
This forces the application server to reload all code in memory.

### Downloading Code Versions

The inverse of deploy — downloads cartridges from the server to local:

```bash
# Download all cartridges to ./cartridges/ directory
b2c code download

# Download to specific output directory
b2c code download -o ./downloaded

# Mirror mode: extracts to local project paths (preserves project structure)
b2c code download --mirror

# Download specific cartridges
b2c code download -c app_custom -c plugin_applepay
```

**Mirror mode**: Uses `.project` files to determine where each cartridge should be extracted. Unmapped cartridges fall back to the `--output` directory.

### Deleting Code Versions

```bash
# Delete with confirmation prompt
b2c code delete old-version

# Skip confirmation
b2c code delete old-version --force
```

Note: Cannot delete the **active** code version. Activate another version first.

### Real-Time Watch Mode

For development, watch mode detects file changes and auto-uploads:

```bash
# Watch current directory
b2c code watch

# Watch specific cartridges
b2c code watch -c app_custom

# Watch from specific directory
b2c code watch ./my-project
```

**Watch behavior**:
- Batches file changes into ZIP archives
- Deletes removed files from the remote server
- Debounces rapid changes (default: 100ms delay, configurable via `SFCC_UPLOAD_DEBOUNCE_TIME`)
- Continues watching on errors with rate limiting
- Writes status messages to stderr (not stdout) to avoid interfering with piped output

---

## WebDAV Operations

WebDAV provides direct filesystem access to B2C Commerce instances.

### Authentication

**Basic Auth** (recommended):
```bash
export SFCC_USERNAME=my-bm-user
export SFCC_PASSWORD=my-webdav-access-key
```

**OAuth** (via Business Manager WebDAV Client Permissions):
- Configure permitted paths in BM: `/cartridges`, `/impex`, `/logs`

### Available Root Directories

| Root | WebDAV Path | Purpose |
|---|---|---|
| `impex` | `/on/demandware.servlet/webdav/Sites/Impex` | Import/export staging |
| `temp` | — | Temporary files |
| `cartridges` | `/on/demandware.servlet/webdav/Sites/Cartridges` | Code cartridges |
| `realmdata` | — | Realm-level data |
| `catalogs` | `/on/demandware.servlet/webdav/Sites/Catalogs` | Product catalogs |
| `libraries` | `/on/demandware.servlet/webdav/Sites/Libraries` | Content libraries |
| `static` | `/on/demandware.servlet/webdav/Sites/Static` | Static assets |
| `logs` | `/on/demandware.servlet/webdav/Sites/Logs` | Instance logs |
| `securitylogs` | — | Security audit logs |

### WebDAV CLI Commands

```bash
# List files in impex root (default)
b2c webdav ls

# List in specific root
b2c webdav ls --root logs

# List subdirectory
b2c webdav ls Impex/src/instance

# Download a file
b2c webdav get Impex/src/instance/my-archive.zip ./local/my-archive.zip

# Upload a file (parent directory must exist)
b2c webdav put ./local/catalog.xml Impex/src/catalog/catalog.xml

# Create directory
b2c webdav mkdir Impex/src/myproject

# Delete file/directory
b2c webdav rm Impex/src/old-archive.zip
b2c webdav rm Impex/src/old-directory --force

# Server-side zip (create archive on server without downloading)
b2c webdav zip Cartridges/version1/app_custom

# Server-side unzip
b2c webdav unzip Impex/src/instance/my-archive.zip

# JSON output
b2c webdav ls --json
```

---

## CI/CD with b2c-dx-mcp and GitHub Actions

### Official GitHub Actions

The B2C Developer Toolkit provides official composite GitHub Actions:

```yaml
# Install CLI
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/setup@v1
  with:
    version: latest          # CLI version (optional, defaults to latest)
    log-level: info          # Logging level
    plugins: ''              # npm packages or 'owner/repo' references to install
    node-version: '22'       # Node.js version

# Deploy code
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/code-deploy@v1
  with:
    code-version: ${{ github.sha }}
    activate: 'true'
    reload: 'false'
    cartridges: ''           # Space-separated list (blank = all)

# Import site archive
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/data-import@v1
  with:
    archive: ./site-data.zip
    timeout: '300'

# Deploy MRT bundle
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/mrt-deploy@v1
  with:
    project: my-project
    environment: production
    message: ${{ github.ref_name }}

# Run job
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/job-run@v1
  with:
    job-id: sfcc-search-index-product-full-update
    wait: 'true'
    timeout: '600'

# WebDAV upload
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/webdav-upload@v1
  with:
    local: ./my-file.xml
    remote: Impex/src/catalog/my-file.xml
    root: impex

# Run any CLI command
- uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/run@v1
  with:
    command: b2c code list
    json: 'true'
```

### Complete Deployment Workflow Example

```yaml
name: Deploy B2C Commerce

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      SFCC_SERVER: ${{ vars.SFCC_SERVER }}
      SFCC_CLIENT_ID: ${{ secrets.SFCC_CLIENT_ID }}
      SFCC_CLIENT_SECRET: ${{ secrets.SFCC_CLIENT_SECRET }}
      SFCC_USERNAME: ${{ secrets.SFCC_USERNAME }}
      SFCC_PASSWORD: ${{ secrets.SFCC_PASSWORD }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup B2C CLI
        uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/setup@v1
        with:
          node-version: '22'
          
      - name: Deploy Cartridges
        uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/code-deploy@v1
        with:
          code-version: ${{ github.sha }}
          activate: 'true'
          reload: 'true'
          
      - name: Rebuild Search Index
        uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/job-run@v1
        with:
          job-id: sfcc-search-index-product-full-update
          wait: 'true'
          timeout: '600'
```

### MRT Release Deployment

```yaml
name: Deploy MRT Storefront

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          
      - name: Install Dependencies
        run: npm ci
        
      - name: Setup B2C CLI
        uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/setup@v1
        
      - name: Deploy Bundle to MRT
        uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/mrt-deploy@v1
        with:
          project: ${{ vars.MRT_PROJECT }}
          environment: ${{ vars.MRT_ENVIRONMENT }}
          message: ${{ github.ref_name }}
        env:
          MRT_API_KEY: ${{ secrets.MRT_API_KEY }}
```

### Data Import Pipeline

```yaml
name: Import Site Data

on:
  workflow_dispatch:
    inputs:
      archive_path:
        description: 'Path to site archive'
        required: true
        default: './site-data'

jobs:
  import:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/setup@v1
      - name: Import Data
        uses: SalesforceCommerceCloud/b2c-developer-tooling/actions/data-import@v1
        with:
          archive: ${{ github.event.inputs.archive_path }}
          timeout: '600'
        env:
          SFCC_SERVER: ${{ vars.SFCC_SERVER }}
          SFCC_CLIENT_ID: ${{ secrets.SFCC_CLIENT_ID }}
          SFCC_CLIENT_SECRET: ${{ secrets.SFCC_CLIENT_SECRET }}
          SFCC_USERNAME: ${{ secrets.SFCC_USERNAME }}
          SFCC_PASSWORD: ${{ secrets.SFCC_PASSWORD }}
```

### Configuration Notes for Actions

- All actions automatically set `NO_COLOR=1` for clean output in CI
- Failed operations cause step failures by default
- Use `continue-on-error: true` for conditional handling
- High-level actions use stable `@v1` releases of setup and run actions internally
- Plugin installation is cached across runs

---

## MRT Bundle Deployment

### Bundle Structure

MRT bundles consist of:
- **SSR bundle**: Server-side rendering entry point
- **Shared bundle**: Client-side assets (JS, CSS)
- Both are uploaded together as a bundle

### Push and Deploy

```bash
# Build project and push bundle (uses project's build command)
b2c mrt bundle push --project my-project

# Push and immediately deploy to an environment
b2c mrt bundle push --project my-project --deploy my-env

# Push with a descriptive message
b2c mrt bundle push --project my-project --message "Release 1.2.3"

# Deploy an existing bundle by number
b2c mrt bundle deploy --project my-project --env my-env --bundle 42

# Wait for deployment completion
b2c mrt bundle push --project my-project --deploy my-env --wait
```

### MRT Logging

```bash
# Stream real-time application logs
b2c mrt tail-logs --project my-project --env my-env

# Filter by log level
b2c mrt tail-logs --project my-project --env my-env --level error

# Filter by search pattern
b2c mrt tail-logs --project my-project --env my-env --filter "checkout"
```

---

## sfcc-ci Migration Guide

The B2C CLI replaces the deprecated `sfcc-ci` tool.

### Command Mapping

| sfcc-ci | b2c-cli |
|---|---|
| `sfcc-ci client:auth <id> <secret>` | `b2c auth client --client-id <id> --client-secret <secret>` |
| `sfcc-ci client:auth:renew` | `b2c auth client renew` |
| `sfcc-ci client:auth:token` | `b2c auth client token` |
| `sfcc-ci auth:login` | `b2c auth login` |
| `sfcc-ci auth:logout` | `b2c auth logout` |
| `sfcc-ci code:list` | `b2c code list` |
| `sfcc-ci code:deploy --cartridge ./app_custom` | `b2c code deploy -c app_custom` |
| `sfcc-ci code:activate <version>` | `b2c code activate <version>` |
| `sfcc-ci code:delete <version>` | `b2c code delete <version>` |
| `sfcc-ci job:run <id>` | `b2c job run <id>` |
| `sfcc-ci job:run --sync <id>` | `b2c job run <id> --wait` |
| `sfcc-ci instance:upload <file>` | `b2c webdav put <local> <remote>` |
| `sfcc-ci instance:import <file>` | `b2c job import <file>` |
| `sfcc-ci sandbox:list` | `b2c sandbox list` |
| `sfcc-ci sandbox:create` | `b2c sandbox create` |

### Environment Variable Migration

| sfcc-ci Variable | b2c-cli Variable |
|---|---|
| `SFCC_OAUTH_CLIENT_ID` | `SFCC_CLIENT_ID` |
| `SFCC_OAUTH_CLIENT_SECRET` | `SFCC_CLIENT_SECRET` |
| `SFCC_LOGIN_URL` | `SFCC_ACCOUNT_MANAGER_HOST` |

New variables: `SFCC_SERVER`, `SFCC_USERNAME`, `SFCC_PASSWORD`, `SFCC_CODE_VERSION`

### Authentication Change

**sfcc-ci approach**: Stateful — authenticate once, token stored locally, reused for subsequent commands

**b2c-cli approach**: Stateless — environment variables carry credentials, CLI authenticates on each call

Both models are supported, but stateless is recommended for CI/CD.

---

## VS Code Extension Features

The B2C DX VS Code Extension (Developer Preview, v0.7.0) provides:

### Sandbox Realm Explorer
- Create, start, stop, clone, delete ODS sandboxes from a tree view
- Visual indicators for cloned sandboxes
- One-click activation of sandbox operations

### Library Explorer
- Browse Page Designer pages and components
- Export with or without assets
- Live XML editing of content
- Site archive imports
- Filterable tree views for large libraries

### B2C Script Debugger
- Step through server-side code (controllers, jobs, scripts, hooks)
- Full debugging capabilities: breakpoints, log points, variable watching
- Step-in, step-over, step-out controls

### Cartridge Management
- Local editing with automatic sandbox sync
- On-demand deployment
- Code version comparison
- Version management

### SCAPI API Explorer
- Built-in Swagger UI for SCAPI endpoints
- Automatic credential injection

### WebDAV Browser
- Browse catalogs, libraries, IMPEX folders
- Local file editing with automatic sync
- Drag-and-drop uploads
- Workspace folder mounting

### Log Tailing
- Real-time log streaming (error, warning, info levels)
- Active instance status in VS Code status bar

---

## Third-Party Plugins for Extended Functionality

### IntelliJ SFCC Config Plugin

Integrates IntelliJ SFCC plugin configuration with B2C CLI:

```bash
b2c plugins install sfcc-solutions-share/b2c-plugin-intellij-sfcc-config
```

Reads connections from `.idea/misc.xml`. Environment variables:
- `SFCC_INTELLIJ_PROJECT_FILE` (default: `./.idea/misc.xml`)
- `SFCC_INTELLIJ_CREDENTIALS_FILE`
- `SFCC_INTELLIJ_CREDENTIALS_KEY`

### Password Store Plugin (Linux/macOS/WSL)

GPG-encrypted credential storage using `pass`:

```bash
b2c plugins install sfcc-solutions-share/b2c-plugin-password-store

# Store global credentials
pass insert -m b2c-cli/_default
# Enter: client-id and client-secret

# Store instance credentials
pass insert -m b2c-cli/my-sandbox
# Enter: hostname, username, password, code-version
```

### macOS Keychain Plugin

```bash
b2c plugins install sfcc-solutions-share/b2c-plugin-macos-keychain

# Store global credentials
security add-generic-password -s 'b2c-cli' -a '*' \
  -w '{"clientId":"shared-id","clientSecret":"shared-secret"}' -U

# Store instance-specific credentials
security add-generic-password -s 'b2c-cli' -a 'staging' \
  -w '{"username":"user@example.com","password":"access-key"}' -U
```

### Catalog Reducer Plugin

Creates smaller representative catalogs for development:

```bash
b2c plugins install b2c-plugin-catalog-reducer

b2c catalog reduce -i ./catalog.xml -o ./catalog-reduced.xml -c ./catalog-reducer.json
```

### Pipeline Visualizer Plugin

Generates ASCII/SVG previews of legacy SFCC Pipeline XML:

```bash
b2c plugins install b2c-plugin-pipeline-visualizer

# ASCII preview
b2c pipeline ascii path/to/pipeline.xml --out debug/layouts/pipeline.txt

# SVG image
b2c pipeline image path/to/pipeline.xml --out debug/layouts/pipeline.svg
```

### Docs Viewer Plugin

Search Salesforce Help from the terminal:

```bash
b2c plugins install b2c-plugin-help-docs-viewer
npx playwright install chromium

b2c docs search-help-site "b2c commerce roles" --limit 5
b2c docs help-site-article "https://help.salesforce.com/..."
```

---

## Scaffold Discovery Priority

When generating scaffolds, the CLI searches in this order (later = higher priority):

1. **Built-in scaffolds** (in `@salesforce/b2c-cli` package)
2. **Plugin-provided scaffolds** (from installed plugins)
3. **User scaffolds** (`~/.b2c/scaffolds/`)
4. **Project scaffolds** (`.b2c/scaffolds/` in project root)

### Custom Scaffold Manifest (`scaffold.json`)

```json
{
  "id": "my-scaffold",
  "name": "My Custom Scaffold",
  "description": "Generates a custom component",
  "category": "custom",
  "parameters": [
    {
      "name": "componentName",
      "type": "string",
      "description": "Component name",
      "required": true
    },
    {
      "name": "includeTests",
      "type": "boolean",
      "description": "Include test files",
      "default": true
    }
  ],
  "files": [
    {
      "template": "component.js.hbs",
      "output": "cartridge/scripts/components/{{camelCase componentName}}.js"
    }
  ],
  "modifications": [
    {
      "file": "cartridge/scripts/index.js",
      "action": "append",
      "content": "require('./components/{{camelCase componentName}}');\n"
    }
  ]
}
```

### Template Helpers Available

- `kebabCase`, `camelCase`, `pascalCase`, `snakeCase` — string case transformations
- `date` — current date
- `uuid` — generate a UUID
