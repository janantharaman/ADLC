# Salesforce B2C Commerce — Security Model

## Authentication Overview

B2C Commerce uses multiple authentication mechanisms depending on the operation type:

| Operation | Auth Method | Setup Required |
|---|---|---|
| Code deploy/watch (cartridges via WebDAV) | WebDAV Basic Auth OR OAuth | BM WebDAV access key or OAuth client |
| Code list/activate/delete (OCAPI) | OAuth + OCAPI | API Client + OCAPI permissions |
| Jobs/Sites | OAuth + OCAPI | API Client + OCAPI permissions |
| SCAPI shopper operations | SLAS token | SLAS client configuration |
| SCAPI admin/data operations | OAuth client credentials | API Client + SCAPI scopes |
| CIP analytics | OAuth client credentials | API Client + Commerce API role |
| SLAS management | OAuth (user auth or client credentials) | SLAS Organization Administrator role |
| Sandbox (ODS) management | OAuth | Sandbox API User role |
| Account Manager operations | OAuth | Varies by operation type |
| MRT operations | MRT API Key | MRT dashboard key |

---

## SLAS — Shopper Login and API Security

### What SLAS Does

SLAS is the identity provider for shoppers accessing SCAPI endpoints. It issues JWT access tokens and refresh tokens that authorize SCAPI calls.

### SLAS Client Types

| Type | Description | Use Case |
|---|---|---|
| **Public Client** | No client secret; uses PKCE | Single-page apps, mobile apps |
| **Private Client** | Has a client secret | Server-side apps, backend integrations |

### Auth Flows

**Guest Token (Public Client)**:
```
POST /shopper/auth/v1/organizations/{organizationId}/oauth2/token
grant_type=client_credentials
client_id=<slas-client-id>
channel_id=<site-id>
```

**Registered Shopper Login (Authorization Code + PKCE)**:
1. `GET /shopper/auth/v1/organizations/{organizationId}/oauth2/authorize`
   - `response_type=code`, `client_id`, `redirect_uri`, `code_challenge`, `channel_id`
2. User authenticates; SLAS returns `code` to redirect URI
3. `POST /shopper/auth/v1/organizations/{organizationId}/oauth2/token`
   - `grant_type=authorization_code`, `code`, `code_verifier`, `redirect_uri`, `client_id`

**Token Refresh**:
```
POST /shopper/auth/v1/organizations/{organizationId}/oauth2/token
grant_type=refresh_token
refresh_token=<token>
client_id=<slas-client-id>
```

### SLAS Configuration

SLAS clients are configured with:
- `client_id` (UUID)
- `client_secret` (private clients only; shown only once on creation)
- `name`
- Allowed `channels` (site IDs)
- `redirect_uris`
- `scopes`

The **tenant-id** for SLAS = organization ID minus the `f_ecom_` prefix (e.g., if org ID is `f_ecom_abcd_prd`, tenant-id is `abcd_prd`).

### CLI Commands for SLAS

```bash
# List SLAS clients
b2c slas client list --tenant-id abcd_prd

# Create a SLAS client
b2c slas client create --tenant-id abcd_prd

# Get a specific client
b2c slas client get <client-id> --tenant-id abcd_prd

# Update a client (append mode by default; --replace overwrites)
b2c slas client update <client-id> --tenant-id abcd_prd

# Delete a client
b2c slas client delete <client-id> --tenant-id abcd_prd

# Get a shopper token for testing
b2c slas token --tenant-id abcd_prd --site-id RefArch

# Open SLAS Admin UI
b2c slas client open --tenant-id abcd_prd
```

**Required Role**: `SLAS Organization Administrator` on the Account Manager user account.

---

## Account Manager API Client Setup

Account Manager is the identity platform for B2C Commerce developer and admin access. All non-shopper API access routes through Account Manager OAuth.

### Creating an API Client

Steps in Account Manager (`https://account.demandware.com`):

1. Navigate to **API Client** section
2. Select **Add API Client**
3. Provide display name and strong password (this is the `client_secret`)
4. Configure **Token Endpoint Auth Method**: `client_secret_basic` or `private_key_jwt`
5. Add required **Default Scopes**: `mail`, `roles`, `tenantFilter`, `openid`
6. Set **Redirect URLs** for user authentication: `http://localhost:8080`

### Available Roles and Their Purpose

| Role | Purpose | Auth Type Required |
|---|---|---|
| `Salesforce Commerce API` | SCAPI and CIP analytics access | API clients only; requires tenant filter |
| `Sandbox API User` | ODS/sandbox management | API clients; requires realm/org ID tenant filter |
| `SLAS Organization Administrator` | SLAS client management | User auth only |
| `User Administrator` | Manage users in Account Manager | Client credentials or user auth |
| `Account Administrator` | Manage orgs, users, roles | User auth only |
| `API Administrator` | Manage API clients | User auth only |
| `bm-admin` | Business Manager administration | Assigned per instance/tenant |

### Required Scopes by Operation

| Scope | Operation |
|---|---|
| `mail`, `roles`, `tenantFilter`, `openid` | All OAuth operations (default scopes) |
| `sfcc.cdn-zones` | eCDN read operations |
| `sfcc.cdn-zones.rw` | eCDN write operations |
| `sfcc.scapi-schemas` | Schema browsing via SCAPI |
| `sfcc.custom-apis` | Custom API status checks |

### Authentication Methods Supported by B2C CLI

1. **User Authentication (Browser-based)** — Opens browser for login; uses user account roles; suitable for interactive use
2. **Client Credentials** — Non-interactive; uses `client_id` + `client_secret`; suitable for CI/CD
3. **JWT Bearer (Certificate-based)** — Uses public/private key pair; avoids storing client secrets
4. **Stateful User Auth** — Stored browser session; persisted login state
5. **Stateful Client Auth** — Stored client credentials; persisted non-interactive state

### JWT Bearer Setup (Certificate-Based)

Generate certificate pair:
```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -nodes \
  -subj "/CN=B2C CLI"
```

Register in Account Manager:
1. Select API Client
2. Set Token Endpoint Auth Method to `private_key_jwt`
3. Upload `cert.pem` in Certificates section

Use in CLI:
```bash
b2c code list \
  --client-id your-client-id \
  --jwt-cert ./cert.pem \
  --jwt-key ./key.pem
```

---

## OCAPI Permissions

OCAPI permissions are configured in Business Manager under:
`Administration > Site Development > Open Commerce API Settings`

Select **Data API** type. Permissions are set per API client ID with resource-level grants.

### Minimal OCAPI Permissions by Feature

**Code Version Management**:
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
    }
  ]
}
```

**Job Execution**:
```json
{
  "resources": [
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
    }
  ]
}
```

**Site Listing**:
```json
{
  "resources": [
    {
      "resource_id": "/sites",
      "methods": ["get"],
      "read_attributes": "(**)"
    }
  ]
}
```

---

## WebDAV Access

WebDAV is the file transfer protocol used for cartridge deployment and log access.

### Basic Authentication (Recommended)

Use Business Manager username and WebDAV access key:
- Generate an access key in Business Manager: `Administration > Organization > Users > [username] > Access Keys`
- Access keys are NOT the same as BM login passwords

```bash
export SFCC_USERNAME=your-bm-username
export SFCC_PASSWORD=your-webdav-access-key
```

### OAuth-Based WebDAV

Configure **WebDAV Client Permissions** in Business Manager with:
- `client_id`
- Permitted paths: `/cartridges`, `/impex`, `/logs`

### WebDAV URL Convention

```
https://<instance>.demandware.net/on/demandware.servlet/webdav/Sites/Cartridges
https://<instance>.demandware.net/on/demandware.servlet/webdav/Sites/Impex
https://<instance>.demandware.net/on/demandware.servlet/webdav/Sites/Logs
```

---

## Sandbox Access and Permissions

On-Demand Sandboxes (ODS) have different access controls:
- Access requires the **Sandbox API User** role with tenant filtering
- Authentication methods: built-in public client (browser), user auth, or client credentials
- Sandbox IDs can be specified as UUID or realm-instance format (e.g., `zzzv-123`)

---

## Safety Mode

The B2C CLI includes a Safety Mode to prevent unintended destructive operations — especially important when CLI is used by AI agents or in production contexts.

### Safety Levels

| Level | Protection |
|---|---|
| `NONE` | No restrictions (default) |
| `NO_DELETE` | Blocks DELETE HTTP operations |
| `NO_UPDATE` | Blocks DELETE + destructive updates |
| `READ_ONLY` | Blocks all write operations |

### Configuration

**Environment variable** (recommended for AI/automation contexts):
```bash
export SFCC_SAFETY_LEVEL=NO_UPDATE
```

**Per-instance in `dw.json`**:
```json
{
  "hostname": "prod.example.com",
  "safety": {
    "level": "NO_UPDATE",
    "confirm": true
  }
}
```

**Global config** (`safety.json` in platform config directory): Enforces baseline policies across all projects.

### Rule Types

Rules provide granular control with actions `allow`, `block`, or `confirm`. Rules match on HTTP method+path, job IDs, or CLI command IDs. Rules are evaluated first-match-wins; explicit `allow` overrides level restrictions.

### Confirmation Mode

`confirm: true` converts hard blocks into interactive prompts. In non-interactive environments (CI/CD, MCP), confirmations automatically become blocks.

---

## Two-Factor Authentication (mTLS)

The CLI supports PKCS12 certificate-based mTLS for enhanced security when connecting to B2C instances that require mutual TLS.

---

## Supply Chain Security (CLI Tooling)

The B2C CLI project uses pnpm security features:
- **Minimum Release Age**: 48-hour quarantine before package versions can be installed (`minimumReleaseAge: 2880` minutes)
- **Trust Policy**: Downgrade attacks blocked (`trustPolicy: no-downgrade`)
- **Build Script Restrictions**: Only approved packages may execute build scripts during install (`onlyBuiltDependencies`)
- **NPM Trusted Publishing**: Uses OIDC tokens (short-lived) instead of persistent npm tokens; published via GitHub Actions
