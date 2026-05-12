---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: security-model
last-updated: 2026-05-11
---

# Experience Cloud — Security Model

## External User Access Model

### Standard Sharing vs. Simple Sharing (PDF p.688)

The type of license determines which sharing model is available:

| Sharing Model | Available Licenses | Includes |
|---|---|---|
| **Standard Sharing** | Customer Community Plus, Partner Community | All internal Salesforce sharing mechanisms PLUS Experience Cloud extras (sharing sets, share groups, super user access); role hierarchy available |
| **Simple Sharing** | Customer Community | No roles, no role hierarchy; designed for high-volume user bases; sharing sets available but no role-based sharing |

### February 2024 Org Boundary (PDF p.33, p.688)

This is a critical boundary for sharing behavior:

**Orgs created BEFORE February 8, 2024 (and non-preview sandboxes):**
- Enabling Digital Experiences automatically extends record access to external members
- Records previously accessible to "Roles and Subordinates" become available to "Roles, Internal and Portal Subordinates"
- This can expose org data to external users inadvertently
- **Required action:** Use the Convert External User Access Wizard to ensure no records or folders are shared with external users

**Orgs created ON OR AFTER February 8, 2024 (and preview sandboxes):**
- Access is secure by default
- Records shared with "Roles and Internal Subordinates" group remain accessible only to internal users
- No wizard remediation required

### Convert External User Access Wizard
- Available in Setup to remediate the pre-Feb 2024 sharing exposure
- Helps ensure no records or folders are inadvertently shared with external/portal subordinates after enabling Digital Experiences

## Sharing Sets vs. Share Groups

### Sharing Sets (PDF p.688-689)
Sharing Sets grant external users access to records linked to their Account or Contact. This is the primary mechanism for "show the customer their own cases."

**How it works:**
- Define a mapping: `RecordField = $User.Field` (e.g., `Case.ContactId = $User.ContactId`)
- All records where the mapping matches are accessible to that user profile
- Only `equals` field mappings on lookup fields are supported
- Cannot span multiple hops (e.g., Case → Account → PartnerAccount)

**Supported for:** Customer Community, Customer Community Plus, Partner Community

**Limitations:**
- Only direct field mapping supported
- Cannot use multi-hop traversal
- For complex access patterns, use Apex Managed Sharing via object Share records (e.g., `CaseShare`) with `RowCause = 'Manual'`

**Example Sharing Set configuration:**
```
Profile: Customer Community User
Object: Case
Access Level: Read/Write
Field Mapping: Case.ContactId = $User.ContactId
```

### Share Groups
- Available for Customer Community and External Identity licenses
- Grants access via groups rather than field mappings
- Used when simple sharing users need access to records owned by a high-volume portal user
- Details: Not found in extracted pages — verify in sharing documentation

### Super User Access (PDF p.35)
- Available for Partner Community license users
- Grants super users access to data owned by other site users with the same role or lower
- Applies to: Cases, Leads, custom objects, Opportunities only
- External users have access to these objects only if exposed via profiles/sharing AND tabs added to the portal
- Enabled in Digital Experiences Settings: "Enable Partner Super User Access"

## Guest User Restrictions

The Guest User Profile is the most scrutinized security surface in Experience Cloud.

### Core Restrictions (PDF p.30, p.688)
- Guest users run as a special Guest User record associated with the Site (`Site.GuestUserId`)
- All unauthenticated site visitors share the same Guest User identity
- Guest users cannot own records
- Guest users cannot be added to groups (no group-based sharing for guests)

### Guest User Security Baseline
From the Digital Experiences security planning guidance (PDF p.30):

**Data Security questions to resolve:**
- What object permissions should the guest user profile have?
- What field-level security should be removed from the guest user profile?
- Which Visualforce pages and Apex controllers do guest users need?
- Should guest users see other site members?
- Should nicknames be used to protect member identities?

**Minimum best practices:**
- Read access to `Lead` only if public form submission creates Leads — otherwise no object read access
- No access to Account, Contact, User, or business objects
- FLS: restrict all sensitive fields (phone, email, financial data) — set FLS Read = false on Guest Profile
- Remove system permissions not required for public browsing

### Guest User File Access
- To give guest users access to files: enable "Give access to public API requests on Chatter" in Workspaces > Administration > Preferences
- To let guests upload files: enable "Allow site guest users to upload files" in Setup > Salesforce Files > General Settings
- Guest users can only download publicly accessible files (not private files)
- Guest users can view Notes and Attachments but NOT the Files Related List

### Guest User in Apex
When Apex runs in a guest user context:
- Must be marked `without sharing` — guest user has no record access via sharing rules
- Always restrict what data is returned manually in the code
- Guest users cannot query records with `$User` merge fields
- Guest users cannot query records with Lookup filters in dynamic SOQL

## License Impact on Data Visibility

| License | Role Hierarchy | Default Data Access | Sharing Options |
|---|---|---|---|
| Customer Community | No | Simple sharing only; no role-based access | Sharing sets; no sharing rules based on roles |
| Customer Community Plus | Yes | Role hierarchy for account data | Sharing sets, sharing rules, role hierarchy |
| Partner Community | Yes (3 roles per account: Partner User, Partner Manager, Partner Executive) | Role hierarchy with channel manager above | Sharing sets, sharing rules, role hierarchy, super user access |

**Partner account role behavior (PDF p.640):**
- All partner users associated with an account fall below the channel manager in the role hierarchy
- All data owned by partner users rolls up to the partner account owner's role
- Disabling a partner user makes their role obsolete — data no longer rolls up to partner account role
- Recommendation: Reduce to ONE role per account (Partner User) and grant super user access to users who need cross-user visibility; avoids role proliferation

## Authentication Options

| Method | Description | Use Case |
|---|---|---|
| **Username/Password** | Default Salesforce authentication with assigned username and password | Simple deployments; fallback option |
| **SAML SSO** | SAML 2.0 single sign-on; Salesforce as service provider; third-party IdP as identity provider | Enterprise SSO with existing corporate identity provider |
| **OAuth/OpenID Connect** | Authentication providers using OAuth 2.0 or OpenID Connect | Social login (Facebook, LinkedIn), third-party IdP |
| **Login Discovery** | Makes authentication easier — user enters email, system discovers correct login method | Mixed authentication environments |
| **Embedded Login** | OAuth-based login embedded within another site or page | Sites embedded in iframes on corporate intranets |

### SAML SSO Configuration Steps (PDF p.693-695)

1. Obtain metadata file or URL from the identity provider
2. In Salesforce Setup: Single Sign-On Settings → New from Metadata File or New from Metadata URL
3. Upload IdP certificate
4. Set SAML Identity Type: "Assertion contains the Federation ID from the User object"
5. Save; copy Entity ID
6. For site as service provider: click dropdown next to "For Communities" to get site-specific SAML Login URL
7. In service provider: Setup > My Domain > Authentication Configuration > Edit > select the IdP authentication service
8. In IdP: create a connected app with Entity ID and ACS URL (Login URL) from service provider
9. Assign profiles/permission sets to the connected app

**Key note:** When implementing SAML SSO for Experience Cloud sites, use the site URL associated with login for the SSO flow. The SAML assertion POST must include `/login` in the site URL.

### Session Cookie Behavior (PDF p.692)
- Session cookies are set at the domain level
- When logging in as a different user during the same browser session, new session cookies replace existing ones for that domain
- The original user is logged out when this happens

### OAuth/Authentication Providers (PDF p.697)
Authentication providers serve dual purpose:
1. Authenticate users for SSO
2. Provide access to third-party user data (to enrich Salesforce profiles)

Types available:
- Predefined authentication providers (Salesforce-managed)
- Salesforce-managed authentication providers
- OpenID Connect authentication providers
- Custom authentication providers

## CSP and Lightning Locker (PDF p.698-706)

### What is CSP?
Content Security Policy (CSP) is a W3C standard that controls sources of content loadable on site pages. It sends a `Content-Security-Policy` HTTP header to the browser. CSP helps protect against cross-site scripting (XSS) attacks by defining what is part of the site ("same origin") vs. third-party content.

### What is Lightning Locker?
A Salesforce architectural layer that allows third-party Lightning components and custom code to run safely on the same page:
- Uses containers to isolate components from different namespaces
- Enforces coding best practices (supported APIs only; no access to unpublished frameworks)
- Turns on native browser security features
- Enabled by default; can be disabled only under Relaxed CSP level

### Security Levels (PDF p.699-706)

| Level | Description | Lightning Locker | When to Use |
|---|---|---|---|
| **Strict CSP: Block Access to Inline Scripts and All Hosts** | Default for sites created Spring '19+; maximum security; blocks all inline scripts and remote JS; blocks non-script resources unless allowlisted | Always on | All new sites; recommended baseline |
| **Relaxed CSP: Permit Access to Inline Scripts and Allowed Hosts** | Moderate security; allows inline scripts and remote JS when hosts are allowlisted; allows Lightning Locker to be disabled | Can be turned off | Sites requiring Google Tag Manager or inline scripts; use with caution |
| **Allow Inline Scripts and Script Access to Any Third-party Host** | No added security; blocks nothing; allows all third-party hosts without allowlisting | Always on; cannot disable | Only visible for pre-Spring '19 sites; REMOVED in Spring '22 |

**Notes on legacy sites (PDF p.698):**
- Sites created before Spring '19 defaulted to "Allow Inline Scripts and Script Access to Any Third-party Host"
- In Spring '22 (February 2022), this option was removed for those sites
- Strongly recommended to update script security level and test before Spring '22 removal

### Allowlisting Third-Party Hosts (PDF p.703)

**Non-script resources** (images, style sheets, fonts, media): 
- Allowlist via Setup > Trusted URLs (CSP directives)
- Applies to all Experience Builder sites in the org

**Script resources** (JavaScript):
- Allowlist in Experience Builder > Settings > Security & Privacy > Trusted Sites for Scripts area
- Only available when Relaxed CSP is selected
- Specific to each individual site (not org-wide)

**Automatically allowed domains (no action needed):**
- All Salesforce-hosted data and files
- Google Analytics required sites (google-analytics.com, stats.g.doubleclick.net, www.googletagmanager.com/gtag/js)
- YouTube image/video addresses for Chatter feed video embeds (img.youtube.com, i.ytimg.com, i.vimeocdn.com)
- Vimeo player (player.vimeo.com)

### Strict CSP Impact Summary

| Impact | Description | Mitigation |
|---|---|---|
| Blocks inline scripts | All `<script>` elements and inline event handlers blocked | Use static resources; avoid inline scripts entirely |
| Blocks remote JavaScript | All remote JS file requests blocked | Upload JS libraries as static resources with relative URL |
| Blocks non-script remote resources | Images, CSS, fonts from external servers blocked | Allowlist in Trusted URLs; or host as static resources |
| Isolates third-party components | Components from different namespaces cannot access each other's DOM | Follow best practices for third-party components |

## Clickjack Protection (PDF p.684-686, p.691)

Clickjacking creates hidden iframes pointing to your site pages to trick users into clicking invisible elements. With clickjack protection, you control whether browsers allow frames pointing to your pages.

### Protection Levels (4 Levels)

| Level | Description | HTTP Header Behavior |
|---|---|---|
| **Allow framing by any page (no protection)** | Least secure; all external domains can frame pages | No restrictions |
| **Allow framing of site pages on external domains (good protection)** | Only explicitly trusted external domains can frame pages; specify in Trusted Domains for Inline Frames | X-Frame-Options: ALLOW-FROM + CSP |
| **Allow framing by the same origin only (recommended)** | Default for Experience Cloud sites; only same domain + protocol can frame pages | X-Frame-Options: SAMEORIGIN |
| **Don't allow framing by any page (most protection)** | Most secure; but prevents Administration pages in Experience Workspaces from opening for Tabs+VF and Experience Builder sites | X-Frame-Options: DENY |

**Warning:** Selecting "most protection" causes Administration workspace pages to appear as blank pages. Use "recommended" as the default.

### Enabling Clickjack Protection

**For Experience Builder sites:**
1. Experience Builder > Settings > Security & Privacy
2. Under Clickjack Protection Level, select level
3. If "good protection" selected: add trusted domains in Trusted Domains for Inline Framing section (up to 100 domains)

**For Salesforce Tabs + Visualforce sites:**
1. Experience Workspaces > Administration > Pages > Go to Force.com, OR Setup > Sites > select site
2. Click Edit on Site Details page
3. Select protection level; add trusted domains (up to 512 domains)

### Internet Explorer Workaround (PDF p.691)

IE supports clickjack protection only through the legacy `X-Frame-Options` HTTP header, which supports only one URI for `allow-from`. For a list of trusted domains with IE users:

The framing site must pass a query parameter in the iframe tag:
```html
<iframe src="https://MyDomainName.my.site.com?_iframeDomain=https://example.com"></iframe>
```

Alternative: Set the trusted domain in the `iframeDomain` cookie:
```apex
Cookie iframeDomainCookie = ApexPages.currentPage().getCookies().get('iframeDomain');
if (iframeDomainCookie == null) {
    iframeDomainCookie = new Cookie('iframeDomain','www.example.com');
    ApexPages.currentPage().setCookies(new Cookie[]{iframeDomainCookie});
}
```

## Cookies (PDF p.707-713)

Experience Cloud uses cookies to improve functionality and accelerate processing times. Salesforce does NOT provide built-in end-user cookie consent management — use third-party solutions compatible with the platform.

**Cookie categories:**
- **Required:** Strictly necessary to browse the site and use its features
- **Functional: Preferences:** Remembers choices made previously (e.g., language settings)
- **Functional: Statistics:** Collects usage information (links clicked, pages visited)
- **Marketing:** Not used by Experience Cloud

**Notes:**
- Experience Cloud can run without functional cookies; site functionality may be reduced
- Experience Cloud cookies apply to LWR and Aura sites only
- Cookies with `LSKEY-c$` prefix are the same as the original cookie but set when Locker Service is enabled; required because Locker Service restricts how cookies are read client-side

### Selected Key Cookies

| Cookie Name | Duration | Type | Description |
|---|---|---|---|
| `__Secure-has-sid` | Session | Required | Detects login state on client side; set during login to Aura or LWR; never set to HttpOnly |
| `_ga` | 2 Years | Functional: Statistics | Third-party Google Analytics cookie; only present if admin adds GA tracking ID |
| `CookieConsent` | 1 Year | Required | Applies end-user cookie consent preferences; stores Boolean for consent |
| `CookieConsentPolicy` | 1 Year | Required | Applies consent preferences set by client-side utility |
| `guest_uuid_essential_<15-char SiteID>` | 1 Year | Required | Unique ID for guest users; expires 1 year after last visit |
| `communityId` | Session | Required | Ties ideas to a specific Experience Cloud site |
| `BrowserId` | 1 Year | Required | Security protections; rendered on .salesforce.com, .force.com, and Experience Cloud site domains |
| `clientSrc` | Session | Required | Security protections |
| `disco` | Session | Required | Tracks last login and active session for bypassing login (e.g., OAuth immediate flow) |
| `idccsrf` | Session | Required | CSRF validation for certain SSO flows |
| `devOverrideCsrfToken` | Session | Required | CSRF Token |
| `inst` | Session | Required | Redirects requests to correct instance after org migration, split, or URL update |
| `language` | Session | Required | Language for custom components, surveys, and flows supporting multiple languages |
| `52609e00b7ee307e` | Session | Required | Browser Fingerprint cookie; detects session security problems |
| `79eb100099b9a8bf` | Session | Required | Browser Fingerprint trigger cookie; detects session security problems |
| `autocomplete` | 60 Days | Functional: Preferences | Determines if login page remembers username |
| `<userId>expid_[site prefix]` | 30 Days | Functional: Statistics | Used to render pages based on specified brand |
| `liveagent_sid` | Session | Required | Identifies Live Agent session; stores unique pseudonymous ID |
| `lloopch_loid` | 1 Year | Required | Determines whether to send user to portal login or app login |
| `force-proxy-stream` | 3 Hours | Required | Ensures client requests hit same proxy hosts for cache retrieval |
| `force-stream` | 180 Minutes | Required | Redirects server requests for sticky sessions |

## Data Encryption (PDF p.697)

- Shield Platform Encryption can be applied to Experience Cloud sites
- Data encryption does not change the external user experience
- Encrypting the Account Name field affects how user roles are displayed to admins (account ID shown instead of account name)
- Beginning Spring '17, encrypted data is no longer masked in presentation layer — use FLS to restrict visibility instead of relying on encryption masking
- Classic Encryption (not Shield): data in encrypted custom fields is still masked

## Permission Sets for External Users

External users CAN have Permission Sets assigned — not limited to Profile-only permissions.

Use cases:
- Grant a subset of partners additional functionality (e.g., `Deal_Registration_PS` for deal registration screen flow)
- Role-based content access via data category visibility in Knowledge

## Account-Based Access for Partners

Partner users automatically have access to records owned by or shared to their Account:
- `Account.IsPartner = true` must be set on the partner's Account
- All Contacts under that Account who are enabled as portal users share Account-level shared records
- To restrict individual partner rep visibility: set OWD = Private on the object and use Sharing Sets or Apex Managed Sharing scoped to individual ContactId
- Channel managers own partner accounts → all partner user data rolls up to channel manager via role hierarchy

## Trusted Domains for Inline Frames

For Experience Builder sites: Up to 100 trusted domains per site.
For Salesforce Tabs + Visualforce sites: Up to 512 trusted domains per site.

Trusted domains only take effect when "Allow framing of site pages on external domains (good protection)" is the selected clickjack level.
