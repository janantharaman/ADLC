# Salesforce B2C Commerce — Gotchas, Known Issues, and Traps

## Cartridge Path Ordering

### Problem: Wrong Cartridge Resolution
The cartridge path in Business Manager is evaluated **left-to-right**, with the leftmost cartridge taking precedence. A common mistake is placing customization cartridges to the RIGHT of the base cartridge, which means the base version is used instead of your customization.

**Correct pattern**: Custom cartridges go LEFT:
```
app_custom:app_storefront_base:modules
```

**Wrong pattern**: Custom cartridges to the right:
```
app_storefront_base:app_custom:modules
```

### Problem: Missing Cartridge Registration
Deploying a cartridge via WebDAV uploads it to the server, but does NOT register it to any site. You must separately add it to the site cartridge path in Business Manager. Forgetting this step means the cartridge code is present on the server but never executed.

### Problem: Code Version vs. Cartridge Path Mismatch
The active code version contains the deployed cartridges, but the cartridge path is configured independently. If you activate a code version that doesn't contain a cartridge listed in the site's cartridge path, you will get runtime errors.

### Problem: Directory Name Length Limit
Cartridge directory names cannot exceed **50 characters**. Longer names will fail silently or cause deployment errors.

---

## Deployment Traps

### Problem: Deploy Does Not Activate
`b2c code deploy` uploads cartridges but does NOT activate the code version by default. You must either:
- Use `--activate` flag to activate after deploy
- Or separately call `b2c code activate <version>`

### Problem: Activate Without Reload
Activating a code version does not always reload running server processes. For changes to take effect on a running sandbox, use:
```bash
b2c code activate <version> --reload
```
Or toggle with:
```bash
b2c code activate --reload
```

### Problem: Cached Version on Active Code
After deploying changes, the sandbox may serve cached versions. The `--reload` flag forces a toggle (activate old, then re-activate new) to flush the server's code cache.

### Problem: WebDAV Upload vs. OCAPI Operations
Some code commands use WebDAV (deploy, download, watch) while others use OCAPI (list, activate, delete). These require DIFFERENT credentials:
- WebDAV requires: username + WebDAV access key (NOT BM login password)
- OCAPI requires: client_id + client_secret with proper OCAPI permissions

Mixing these up is a very common authentication failure cause.

### Problem: Active Code Version Cannot Be Deleted
You cannot delete the currently active code version. Always activate a different version before deleting.

---

## Sandbox vs. Production Differences

### Caching
- **Sandbox**: Most caching is disabled or reduced for development
- **Development (PIG)**: Simulates production without caching
- **Production**: Full caching enabled

Performance testing on sandboxes gives misleading results. Always performance test on a Development or Staging instance.

### System Jobs
- **Sandbox (SIG)**: Most system jobs are **disabled by default**. Scheduled jobs like search reindex do not run automatically. You must trigger them manually.
- **PIG instances**: Full job scheduling is active

### Data Replication
- Data replication is **one-way: Staging → Production** only
- There is no automated replication to sandboxes; developers must import data manually via IMPEX or use `b2c job import`

### Instance Reset
Sandboxes can be **reset** (wiping all data and code while preserving configuration), which production cannot. Never rely on sandbox data persistence across reset events.

---

## SLAS Gotchas

### Problem: Tenant ID Format
The SLAS tenant-id is **NOT** the same as the organization ID. It is the org ID **minus the `f_ecom_` prefix**:
- Organization ID: `f_ecom_abcd_prd`
- SLAS Tenant ID: `abcd_prd`

### Problem: Client Secret Shown Only Once
When creating a SLAS client, the client secret is displayed **only once** and cannot be retrieved afterward. If you lose it, you must create a new client. Store it securely immediately.

### Problem: Channel Mismatch
SLAS clients must have the correct site ID(s) configured as **channels**. A SLAS client without the matching site ID configured will reject token requests for that site.

### Problem: SLAS Public Client Cannot Store Secrets
Public SLAS clients use PKCE and do not have client secrets. They are appropriate for browser-based or mobile apps but should not be used for server-to-server calls.

---

## OCAPI Configuration Gotchas

### Problem: Missing OCAPI Permission for CLI Operations
The B2C CLI uses OCAPI for code version management and job execution. Without proper OCAPI configuration for your client ID, operations fail with `401 Unauthorized` or `403 Forbidden`:
- Code operations require `/code_versions` permissions
- Job operations require `/jobs/*/executions` and `/job_execution_search` permissions

### Problem: OCAPI Version Pinning
OCAPI endpoints include a version number in the path (e.g., `/v21_3/`). Using the wrong version can result in missing features or deprecated behavior. Always use the latest supported version.

### Problem: API Client Not Assigned to Correct Tenant
In a multi-tenant environment, OCAPI clients must be configured for the correct tenant/instance. A client configured for `prod` will not work on `staging` unless it is also configured there.

---

## Quota Limits

### WebDAV and Code Version Limits
- Number of code versions per instance is limited (typically 10–20). Old versions must be deleted before new ones can be created.
- WebDAV file upload size limits apply; large site archives should be chunked or streamed

### Job Execution Limits
- Concurrent job executions are limited per instance
- Job timeouts apply; long-running jobs may be terminated by the platform
- Rate limits on the OCAPI job execution endpoints

### CIP Analytics Rate Limits
- JDBC query timeouts apply
- Query quotas and rate limits are enforced
- Best practices: query aggregate tables, avoid `SELECT *`, use narrow date ranges, avoid large fact tables

### API Rate Limits
- SCAPI endpoints have per-minute/per-hour rate limits that vary by endpoint and tier
- SLAS token endpoints have rate limits; implement token refresh rather than re-authenticating

---

## Known Issues with Tooling

### Problem: npx PATH Issues on macOS/Linux with MCP
When using the MCP server, `spawn npx ENOENT` errors occur if Node.js is not in PATH when the IDE application is launched. Fix: **launch the IDE application from the terminal** (not from Finder/Spotlight), so it inherits shell PATH:
```bash
code .       # For VS Code
cursor .     # For Cursor
```

### Problem: Cached npm Package in MCP
The MCP server should always use `@latest` tag to avoid stale cached versions:
```json
{
  "command": "npx",
  "args": ["@salesforce/b2c-dx-mcp@latest"]
}
```
Without `@latest`, a cached old version may be used.

### Problem: Windows PATH for npx
On Windows, the Node.js installer must add npm/npx to system PATH. Verify this after installation or add manually.

### Problem: Cursor User-Level vs. Project-Level .env
When using the MCP server at user-level configuration in Cursor, `.env` files in the project root are **not automatically loaded**. Use `dw.json` or system environment variables instead.

### Problem: Non-GA Tools Require Flag
Preview/non-GA MCP tools (e.g., STOREFRONTNEXT toolset) require the `--allow-non-ga-tools` flag to be included in the MCP server configuration. Without it, these tools are not exposed.

---

## SFRA Extension Gotchas

### Problem: server.extend Required Before prepend/append
When overriding a controller in a custom cartridge, you must call `server.extend(module.superModule)` before using `server.prepend()` or `server.append()`. Without it, the custom cartridge creates an entirely new route instead of extending.

### Problem: next() Not Called in Middleware
In controller middleware chains, forgetting to call `next()` will halt the middleware chain and the request will hang or fail. Always call `next()` unless you intend to stop processing.

### Problem: Template require Path Syntax
In SFRA scripts, using `require('*/cartridge/scripts/...')` uses the cartridge path resolution (will find overridden versions). Using a specific cartridge name bypasses the resolution. Use `*` for overrideable requires.

### Problem: Forms Cleared After Navigation
B2C Commerce form objects are session-based and cleared by default after a redirect. Use `session.forms` carefully and ensure forms are prepared before rendering.

---

## Sandbox Management Gotchas

### Problem: Source Sandbox Stopped During Clone
When cloning a sandbox, the **source sandbox automatically transitions to Stopped state** to maintain data integrity. It resumes after the clone is complete. Plan sandbox cloning during off-hours to avoid disrupting active development.

### Problem: Sandbox TTL Expiry
On-demand sandboxes have a TTL (default 24 hours unless extended). Sandboxes expire and are deleted when TTL is reached. Important data must be exported before expiry.

### Problem: Sandbox Reset vs. Delete
- **Reset** clears all data and code but preserves the sandbox configuration (hostname, OCAPI settings, etc.)
- **Delete** permanently removes the sandbox

### Problem: Realm-Level TTL Restrictions
The realm administrator can set a `max-sandbox-ttl` that restricts how long individual sandboxes can live. Setting TTL to `0` makes a sandbox infinite-lived (only if realm allows it).

---

## Data and Import/Export Gotchas

### Problem: IMPEX Directory Cleanup
By default, `b2c job import` deletes the archive after successful import. If you need to keep it, use `--keep-archive`. Archives left on the server consume storage quota.

### Problem: Site Archive Import Job Timing
The `sfcc-site-archive-import` job can take a long time for large archives. Default behavior is to kick off the job and return without waiting. Use `--wait` or `-w` to block until completion, with `--timeout` for large datasets.

### Problem: Data Units in Export
When using `b2c job export`, if you don't specify data units, nothing is exported. You must explicitly specify `--global-data`, `--site`, `--catalog`, `--price-book`, etc.

---

## Authentication Order and Credential Mixing

### Problem: Credential Group Mixing
The CLI treats OAuth credentials (client-id/client-secret) and Basic Auth credentials (username/password) as atomic groups. You cannot mix credentials from different sources:
- If `client-id` comes from a flag and `client-secret` from `dw.json`, this is treated as one group and works
- But mixing OAuth creds from two different sources (flag + env var) may cause unexpected behavior

### Problem: Hostname Mismatch Protection
If the `--server` flag specifies a different hostname than what is in `dw.json`, the `dw.json` values are **ignored** (hostname mismatch protection). This prevents accidentally using production credentials when targeting a sandbox.

### Configuration Priority Order (highest to lowest)

1. CLI flags and environment variables
2. Plugin sources (high priority)
3. `dw.json` file in project root
4. `~/.mobify` home directory file
5. Plugin sources (low priority)
6. `package.json` `b2c` key
