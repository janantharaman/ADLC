---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: overview
last-updated: 2026-05-11
---

# Experience Cloud — Overview

## What It Is

Experience Cloud is the Salesforce platform for building branded digital experiences — customer portals, partner portals, help centers, employee intranets, and public-facing sites — on top of your org's data and business logic. It enables businesses to connect their customers, partners, and employees through personalized, mobile-ready digital experiences without requiring separate infrastructure.

Experience Cloud supports three core frameworks — Lightning Web Runtime (LWR), Aura, and Visualforce — each serving different use cases and technical requirements. Sites are created and managed from the Digital Experiences app in Salesforce Setup, with most configuration done in Experience Builder or Experience Workspaces.

Experience Cloud is available in Enterprise, Performance, Unlimited, and Developer Editions. A Salesforce org can host up to 100 Experience Cloud sites. Active, inactive, and preview sites all count toward this limit. Archived sites do not count.

## When to Use Experience Cloud

Use Experience Cloud when the engagement objective is one or more of:
- Customer self-service portal (view/create cases, track orders, access Knowledge articles)
- Partner portal (deal registration, lead distribution, MDF requests, partner account management)
- Help center (knowledge self-service with case deflection)
- Employee community or HR self-service
- Public-facing website with Salesforce data or forms (unauthenticated guest access)
- B2B channel sales operations (requires Partner Community license)
- Event registration or sign-up flows exposed to external users

## Site Types & Use Cases

| Template | Use Case | Framework | Notes |
|---|---|---|---|
| **Customer Account Portal** | B2C self-service; customers view/pay invoices, update account info, search knowledge | Aura | Pre-built components for account management |
| **Partner Central** | Channel sales workflows; lead distribution, deal registration, marketing campaigns | Aura | Requires Partner Community license |
| **Customer Service** | Self-service with peer-to-peer discussions; supports Knowledge, Chatter Questions, cases | Aura | Multiple prebuilt theme options |
| **Help Center** | Public-access knowledge self-service; reduces support load | Aura | Lower cost; guest access supported |
| **Build Your Own (Aura)** | Custom branded experience with basic starter pages | Aura | Low-code, drag-and-drop component model |
| **Build Your Own (LWR)** | High-performance custom site; pixel-perfect pages | LWR | Requires developer skills; LWC-based |
| **Microsite (LWR)** | Event pages, landing pages, short-lived special-purpose sites | LWR | Easy to create and archive |
| **Aloha** | App Launcher for SSO across multiple applications | Aura | Configurable App Launcher template |
| **Salesforce Tabs + Visualforce** | Full platform access with Visualforce customization | Visualforce | Requires developer experience; no Experience Builder |

## Frameworks

### LWR (Lightning Web Runtime)
- Introduced as GA for all orgs; uses Lightning Web Components (LWC)
- Purpose-built for performance: components run natively in browser (no server-side framework overhead)
- Supports enhanced sites and content platform (Winter '23+) which enables partial deployment, site content search, and DigitalExperienceBundle metadata type
- Required for Microsite and Build Your Own (LWR) templates
- Suitable for developers, consulting partners, and ISVs familiar with LWC, Salesforce DX, UI API, and Apex
- Google Analytics 4 integration available natively in enhanced LWR sites
- **When to use:** New builds where performance is critical, headless-compatible architectures, modern LWC component development

### Aura
- Uses standardized Server-Side JavaScript framework (introduced 2014)
- Supports drag-and-drop in Experience Builder with low-code component model
- LWC and Aura components can coexist and interoperate on the same page
- Templates: Customer Service, Partner Central, Help Center, Build Your Own (Aura), Customer Account Portal
- **When to use:** Existing Aura implementations, teams without LWC expertise, use cases requiring pre-built PRM/customer portal templates
- **Limitation:** Cannot switch from Aura to LWR after site creation — framework selection is permanent

### Visualforce
- Tag-based markup language similar to HTML with server-side standard controllers
- Represented by "Salesforce Tabs + Visualforce" template
- Does not work with Experience Builder
- **When to use:** Legacy migrations only; existing portal implementations; not recommended for new builds

### Enhanced Sites and Content Platform (Winter '23+)
- Applies to new LWR sites created from Winter '23 onward
- Key additions over standard LWR:
  - Partial deployment support via DigitalExperienceBundle + DigitalExperienceConfig metadata types
  - Site content search (content in Rich Content Editor and HTML Editor components is searchable)
  - Simplified CMS workspace integration
  - Google Analytics 4 native support
- Existing non-enhanced LWR sites are unaffected and cannot access enhanced platform features
- Identifiable in the Digital Experiences app by an "Enhanced" badge

## License Types

| License | Access Model | Role Hierarchy | Sharing Model | Objects Accessible | Best For |
|---|---|---|---|---|---|
| **External Identity** | Member or login | No | Simple sharing | Minimal CRM access | Identity/SSO use cases |
| **Customer Community** | Member or login | No (simple sharing) | Simple sharing (no roles) | Limited standard objects | High-volume B2C portals |
| **Customer Community Plus** | Member or login | Yes | Standard sharing + sharing sets | Broader CRM objects, reports/dashboards | B2C portals needing reports or role-based visibility |
| **Partner Community** | Member or login | Yes (3 roles per account) | Standard sharing, sharing sets, super user | Sales objects (Opportunities, Leads, Campaigns) | B2B partner/channel sales portals |
| **Channel Account** | Not found in source — verify separately | Not found in source — verify separately | Not found in source | Not found in source | Not found in source |
| **External Apps** | Member | Not found in source | Not found in source | Not found in source | Not found in source |

**Member vs. Login licensing:**
- Member-based: named user, one license per user regardless of login frequency
- Login-based: pay per login event; more cost-effective for infrequent access users

**Key license questions (from PDF p.21):**
- How many users and how often do they log in?
- Do users need reports and dashboards? (requires CC Plus or Partner Community)
- Do users need role hierarchy for data sharing? (requires CC Plus or Partner Community)
- What objects and access levels are required?
- Does the use case require API calls, data storage, file storage beyond basic limits?

**Customer Community vs. Customer Community Plus:**
- Customer Community: described as "economy ticket" — basic pass, simple sharing, no role hierarchy
- Customer Community Plus: described as "business ticket" — more data access, role hierarchy, reports
- Partner Community: described as "first-class ticket" — full sales object access, role hierarchy, channel management

**Enabling Partner functionality** requires purchasing at least one Partner Community license, which enables:
- Partner Central template
- Default Partner User profile
- Three standard partner roles: Partner User, Partner Manager, Partner Executive
- Manage External Account and Enable as Partner buttons on Accounts
- Manage External User and Enable Partner User buttons on Contacts

## Site Lifecycle

### Status Values
| Status | Description |
|---|---|
| **Preview** | Site created but not yet active; accessible only by site members (internal) via shared preview URL; no public access |
| **Active / Live** | Site is publicly accessible; external users can log in; `Network.Status = 'Live'` |
| **Inactive** | Site is deactivated; external users cannot access; counts toward 100-site limit |
| **Archived** | Site is archived; does not count toward 100-site limit |

### Lifecycle Steps
1. **Create** — wizard selects template, sets name and URL path prefix; site starts in Preview status
2. **Build** — configure in Experience Builder, set up Administration settings (members, login, email templates)
3. **Preview** — share preview URL with stakeholders; site functions as it will when active; members can post/comment
4. **Activate** — change status to Active/Live; external users can now access
5. **Deactivate** — return to Inactive; external users lose access; site persists
6. **Archive** — remove from active site count; site preserved but not accessible

**Critical note (PDF p.33):** After enabling Digital Experiences, you cannot disable it. If org access is suspended for non-payment, all sites are deactivated including Preview status sites. When re-enabled, all sites are Inactive — they can be activated but cannot return to Preview status.

### Changing Name and URL
- Name and URL can be changed after activation
- Users are NOT automatically redirected to the new URL after a name/URL change
- Always inform members before changing name or URL (PDF p.45)

## Key Terminology

| Term | Definition |
|---|---|
| **Network** | Salesforce object representing a single Experience Cloud site; API name `Network` |
| **Site** | Public-facing site configuration including domain and guest user settings; API name `Site` |
| **Experience Workspaces** | One-stop admin hub for building, configuring, and monitoring a site; includes Builder, Moderation, Content Management, Gamification, Dashboards, and Administration workspaces |
| **Experience Builder** | Visual drag-and-drop tool for styling pages, adding LWC/Aura components, and configuring navigation; accessible via Workspaces or profile menu |
| **Digital Experiences** | The Salesforce Setup area for managing Experience Cloud; replaces older "Communities" label |
| **Enhanced LWR Site** | LWR site on the enhanced sites and content platform (Winter '23+); supports partial deployment and site content search |
| **DigitalExperienceBundle** | Metadata type for enhanced LWR sites; replaces ExperienceBundle for new LWR sites |
| **ExperienceBundle** | Metadata type for non-enhanced LWR and Aura sites |
| **SiteDotCom** | Legacy metadata type for Visualforce/Tabs+VF sites; produces binary .site file |
| **Guest User** | The unauthenticated visitor user; all anonymous site visitors run under this user's profile |
| **Sharing Set** | Experience Cloud mechanism granting external users access to records via field mapping (e.g., Case.ContactId = User.ContactId) |
| **NetworkMember** | Tracks a user's membership, Chatter preferences, and reputation points in a specific site |
| **UrlPathPrefix** | The path segment appended to the org domain (e.g., `/customers` in `myorg.my.site.com/customers`) — treat as immutable after go-live |
| **Simple Sharing** | Sharing model for Customer Community licenses: no roles, no role hierarchy |
| **Standard Sharing** | Sharing model for CC Plus and Partner Community: roles, role hierarchy, sharing sets, share groups |
| **LWR** | Lightning Web Runtime framework; uses Lightning Web Components; higher performance than Aura |
| **CDN** | Content Delivery Network (Akamai); reduces page load times for high-traffic sites; available via Salesforce CDN option |
| **Micro-batching** | Async batch processing for self-registration and record creation; handles high-volume traffic spikes |

## Digital Experiences Settings

Key settings available at Setup > Digital Experiences > Settings (PDF p.35):

| Setting | Description |
|---|---|
| Allow editing Partner Account field on Opp/Lead | Lets partner users edit the Partner Account field |
| Enable Partner Super User Access | Grants super users access to data owned by users in same/lower role; applies to Cases, Leads, custom objects, Opportunities |
| Enable report options for external users | Gives CC Plus and Partner Community users with Run Reports permission access to report options |
| Let customer users access notes and attachments | Allows customer users to access Notes and Attachments on accounts/contacts |
| Allow customer users to change case statuses | Lets CC Plus users change case status in Visualforce sites |
| Require unique usernames for partners in this org | Orgs created after Winter '19 have this automatically |
| Allow using standard external profiles for self-registration | Allows self-registration and login with default external profiles |
| Hide badges from guest users | Hides gamification badges from guest users in Aura sites |
| Moderation rules apply to all feed posts | Applies moderation to posts across all sites (not just origin site) |
| Enable Account Relationships | Enables Account Relationship objects and sharing rules; irreversible once enabled |
| Enable External Account Hierarchy | Enables External Account Hierarchy objects; irreversible once enabled |
| Block Redirect to Unknown URL (Embedded Login) | Blocks OAuth redirects to unknown URLs in Embedded Login implementations |

## Release History (Spring '26)

| Feature | Release | Notes |
|---|---|---|
| Enhanced Sites and Content Platform | Winter '23 | DigitalExperienceBundle metadata, partial deployment, site content search |
| Google Analytics 4 | Enhanced LWR sites | GA4 integration natively in Experience Builder |
| LWR GA for all orgs | Spring '25 (per stub; not directly stated in PDF p.19-50 content) | Not directly confirmed in extracted pages — verify separately |
| Allow Inline Scripts option removal | Spring '22 | "Allow Inline Scripts and Script Access to Any Third-party Host" removed for pre-Spring '19 sites |
| Account Role Optimization (ARO) | Available | Delays role creation until second user on account; improves scale for high-volume sites |
| Upvotes/Downvotes default change | Winter '18 | Upvotes/downvotes enabled by default in new sites; disabled by default in Spring '19+ sites |
