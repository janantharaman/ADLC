---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: implementation-guide
last-updated: 2026-05-11
---

# Experience Cloud — Implementation Guide

## Prerequisites

Before creating any Experience Cloud site, confirm the following (PDF p.32-33):

### Feature Flag
1. **Enable Digital Experiences:** Setup > Digital Experiences > Settings > Enable Digital Experiences
   - This is irreversible — once enabled, it cannot be disabled
   - Sets up the digital experiences domain: `MyDomainName.my.site.com` for production orgs
   - Requires "Customize Application" permission

### Licenses
2. **Purchase appropriate licenses** before setup:
   - For customer portals: Customer Community or Customer Community Plus
   - For partner portals: Partner Community (at minimum 1 license to enable Partner Central template and partner account functionality)
   - For help centers: Customer Community (lower cost; knowledge self-service)
   - For identity-only: External Identity

### Edition Requirements
- Enterprise, Performance, Unlimited, or Developer Editions
- Classic and Lightning Experience supported

### Org-Level Prerequisites
3. **Enable My Domain** — required for Experience Cloud
4. **Configure org-wide sharing settings** — set External OWD to Private for objects to be shared via Sharing Sets
5. **Verify Chatter is enabled** if using peer-to-peer discussions, reputation, or moderation features

## Site Creation Sequence (PDF p.33, p.358-360)

1. **Open Digital Experiences Setup**
   - From Setup, enter "Digital Experiences" in Quick Find → select "All Sites"

2. **Click New** — the site creation wizard opens

3. **Select a template** appropriate for your use case:
   - Customer Account Portal (Aura) — B2C account management
   - Partner Central (Aura) — B2B channel sales
   - Customer Service (Aura) — self-service with peer discussions
   - Help Center (Aura) — knowledge self-service, public
   - Build Your Own (Aura) — custom Aura experience
   - Build Your Own (LWR) — high-performance custom LWC experience
   - Microsite (LWR) — event/landing page, quick to create and archive
   - Aloha — App Launcher SSO
   - Salesforce Tabs + Visualforce — legacy; developer required

4. **Select your template** and click "Get Started"

5. **Enter a name** for the site

6. **Enter the URL path prefix** (e.g., "customers", "partner", "help")
   - This is appended to your domain: `MyDomain.my.site.com/customers`
   - Treat as immutable after activation — changing breaks all existing links
   - One site can be created without a custom URL (root site)

7. **Click Create** — site is created in Preview status

8. **Configure Administration workspace settings:**
   - Administration > Members: add profiles and permission sets that should have site access
   - Administration > Preferences: configure nicknames, guest access, private messages, direct messages, file limits, reputation, upvotes/downvotes
   - Administration > Login & Registration: configure login flow, self-registration, registration flow, password management, login page type
   - Administration > Emails: configure email templates (welcome, forgot password, change password, lockout)
   - Administration > Reputation Levels: configure if reputation is enabled
   - Administration > Reputation Points: configure point values per action

9. **Build and customize in Experience Builder:**
   - Design pages, themes, navigation
   - Add LWC or Aura components
   - Configure component properties
   - Set up audience targeting (Aura sites)
   - Configure SEO settings

10. **Set up sharing and security:**
    - Configure Sharing Sets for external user data access
    - Review Guest User Profile permissions
    - Set FLS on all objects exposed to external users
    - Configure clickjack protection level

11. **Configure Login & Registration:**
    - Set up Login Flow (if using Screen Flow for login)
    - Configure self-registration flow (standard or custom Apex)
    - Set up SSO providers (SAML or OAuth) if needed

12. **Preview and test:**
    - Share preview URL with stakeholders
    - Test as guest user (open in incognito/private browser)
    - Test as authenticated external user

13. **Publish from Experience Builder** — makes branding and component changes available

14. **Activate the site:**
    - Experience Workspaces > Administration > Settings
    - Change status to Active

15. **Verify post-activation:**
    - Test external user access
    - Confirm email notifications working
    - Validate sharing model (can users see the records they should?)
    - Check CDN / custom domain behavior

## Template Selection Decision Guide

| Use Case | Recommended Template | Framework | Notes |
|---|---|---|---|
| Customer self-service (cases, account info) | Customer Account Portal | Aura | Pre-built account management components |
| B2B channel sales / partner management | Partner Central | Aura | Requires Partner Community license |
| Community-style self-service with discussions | Customer Service | Aura | Multiple theme options; supports Chatter Questions |
| Knowledge-only help center | Help Center | Aura | Public access; no login required |
| High-performance custom portal (dev team available) | Build Your Own (LWR) | LWR | Requires LWC expertise and Salesforce DX |
| Event / landing page (temporary) | Microsite (LWR) | LWR | Easy to archive when done |
| Custom Aura experience from scratch | Build Your Own (Aura) | Aura | Low-code drag-and-drop |
| SSO App Launcher | Aloha | Aura | — |
| Legacy Visualforce migration | Salesforce Tabs + Visualforce | Visualforce | Not recommended for new builds |

## Administration Workspace Key Settings (PDF p.41-42)

Accessed at Experience Workspaces > Administration > Preferences:

### General Settings
| Setting | Purpose |
|---|---|
| Show nicknames instead of full names | Privacy protection; especially for public sites with unregistered visitors |
| Enable Chatter messages | Secure private conversations between Chatter users |
| Enable direct messages | Secure private conversations (Customer Service template only) |
| Optimize cached images for guest users | Faster image loading on all devices; requires Salesforce CDN |
| Let guest users view asset files and CMS content | Required for guest access to topic images, badges, branding |
| Allow guest users to access public APIs | Required to ensure guest users can view CMS collections on LWR public pages |
| Use custom Visualforce error pages | Shows branded error pages to authenticated users |
| Show all settings in Workspaces | Overrides dynamic navigation; shows all settings regardless of template |

### Experience Management Settings
| Setting | Purpose |
|---|---|
| Allow members to flag posts/comments/files | Enables content moderation by members |
| Enable Upvotes and Downvotes | Replaces Like with Up/Downvote system |
| Enable Reputation | Activates reputation point system and reputation levels |
| Enable knowledgeable people | Allows topic endorsements and "knowledgeable people" discovery |
| Set maximum file size in MB | Controls upload limits |
| Specify allowed file types | Prevents inappropriate file uploads |

## Custom Domain & CDN Setup (PDF p.37)

1. **Plan custom domain early** — set up before publishing/indexing to avoid SEO issues with Salesforce-managed domain URLs appearing in search engines
2. From Setup, refer to the Custom Domains documentation to configure your domain
3. **Point your DNS** to the Salesforce CDN endpoint (for Salesforce CDN) or your edge infrastructure (for third-party CDN)
4. **Configure CDN:** Highly recommended when serving on custom domain; required for Apex Caching and image optimization features
5. **Many-to-many domain relationship:** A single custom domain can serve multiple Experience Cloud sites via different path prefixes
6. Custom domain remains constant even if My Domain URL changes — reduces update maintenance

**Professional Edition + Marketing Cloud Account Engagement:** Custom domain must use the Salesforce CDN.

## Self-Registration Setup Sequence (PDF p.510-520)

### Standard Self-Registration (Low Volume)
1. Experience Workspaces > Administration > Login & Registration
2. Enable "Allow customers/partners to self-register"
3. Select default profile for new users
4. Select default account (for business account sites) or enable person accounts
5. Optionally: assign a Registration Flow (Screen Flow) for custom fields/logic

### Custom Apex Controller Self-Registration
1. Create an Apex class `without sharing` implementing the self-registration logic:
   - Check for existing Contact by email (prevent duplicates)
   - Create or find Account
   - Create or update Contact
   - Call `Site.createPortalUser()` (sync) or `Network.createExternalUserAsync()` (async/high-volume)
2. Reference the Apex class in Network settings (Login & Registration > Self-Registration Apex Class)
3. Test in sandbox with representative data volumes

### High-Volume Self-Registration (Micro-Batching)
Use `Network.createExternalUserAsync(user, contact, account)` — see automation-patterns.md for full code.

**Eligible licenses for micro-batching:**
- External Identity
- Customer Community
- Customer Community Plus and Partner Community WITH Account Role Optimization (ARO) enabled

**Post-registration experience:**
- User receives email with login instructions after batch processes
- Error emails go to site admin (configure via `Site.Admin` field)
- Configure error email template at Administration > Emails

## Login & Authentication Setup

### SAML SSO Steps (PDF p.693-695)
1. Obtain metadata from IdP (XML file or metadata URL)
2. Setup > Identity > Single Sign-On Settings > New from Metadata File (or URL)
3. Upload IdP certificate
4. Set SAML Identity Type = "Assertion contains Federation ID from User object"
5. Save; note the Entity ID
6. For site as service provider: expand "For Communities" dropdown to get site-specific Login URL
7. Setup > My Domain > Authentication Configuration > Edit > select IdP authentication service
8. In IdP: create connected app with Entity ID + Login URL (ACS URL) from service provider
9. Assign profiles/permission sets to the connected app
10. Test with a pilot user before broad rollout

### OAuth Provider Setup
1. Setup > Identity > Auth. Providers > New
2. Select provider type (OpenID Connect, Salesforce, Facebook, etc.) or Custom
3. Configure Client ID, Client Secret, Authorization endpoint, Token endpoint, User Info endpoint
4. Set "Registration Handler" Apex class for user provisioning/lookup
5. Save and copy the callback URL for registration in the third-party provider
6. Register the callback URL in the third-party OAuth application
7. Add the auth provider to the site Login page in Login & Registration settings

## Partner Central Setup Sequence (PDF p.637-641)

1. **Purchase Partner Community licenses**
2. **Set the Channel Manager Role:**
   - Create a role for channel managers
   - Assign to internal users who manage partner organizations
   - Grant "Manage External Users" (PermissionsManagePartners) permission
3. **Configure org-wide sharing:**
   - Setup > Sharing Settings > set Default External Access = Private for all objects shared with partners
4. **Clone and customize Partner User profile:**
   - Clone default Partner User profile
   - Add required object permissions (Leads, Accounts, Contacts, Opportunities, etc.)
5. **Create partner accounts:**
   - Create business Account
   - Click "Manage External Account" > "Enable as Partner"
   - Three roles auto-created per account; recommendation: reduce to one role (Partner User)
6. **Create partner contacts and users:**
   - Add contact records to partner account
   - Enable as partner user via "Enable Partner User" button
   - Assign partner license, profile, and role
7. **Create Experience Cloud site using Partner Central template**
8. **Add site members:** Add partner user profiles to site
9. **Configure Experience Builder:**
   - Add Lead Inbox, Quick Create Actions, Deal Registration components
   - Configure navigation menu for partner workflows
10. **Optionally enable PRM features:**
    - Channel Programs and Levels (for tiered partner programs)
    - Market Development Fund (MDF requests and approvals)
    - Campaign Marketplace
    - Deal Registration with approval process
    - Lead Distribution

## Help Center + Knowledge Integration Sequence

1. **Enable Salesforce Knowledge** in Setup > Knowledge > Settings
2. **Create Knowledge article types** and data categories
3. **Grant Knowledge access** on the Guest User Profile or site user profiles:
   - Add Knowledge object to profile with Read access
   - Grant data category visibility as needed
4. **Create or select Experience Cloud site** using Help Center or Customer Service template
5. **Enable Knowledge in the site:**
   - Experience Workspaces > Administration > Guided Setup
   - Or add Knowledge component(s) in Experience Builder
6. **Publish Knowledge articles** — only published articles appear in the site
7. **Set up topic assignments:**
   - Experience Workspaces > Content Management > Topics > Automatic Topic Assignment
   - Map data categories to topics for automatic tagging
   - Assign navigational, featured, and content topics as needed
8. **Configure SEO** for public Help Center:
   - Keep site private until custom domain is configured
   - After go-live: sitemap auto-generated weekly on Sundays; partial refresh every 24 hours
   - Ensure Knowledge articles have at least one navigational, featured, or content topic for sitemap inclusion

## Multilingual Site Setup Sequence

Not fully detailed in extracted PDF pages — verify in Experience Cloud multilingual documentation. Partial content from PDF:

1. Enable Translation Workbench in Setup
2. Supported languages configured at org level
3. For Knowledge: publish translated article variants
4. For topics: translate topic names and descriptions via Translation Workbench (select "Reputation Level" or topic component)
5. For LWR sites: adding a Digital Experience component also adds all translations for that component's variations
6. Sitemap includes entries for each supported language in Google's recommended format

## Post-Deployment Manual Steps Checklist

After every Experience Cloud deployment, manually configure these items (cannot be deployed via change set):

- [ ] Navigational topics and subtopics
- [ ] Featured topic thumbnail images
- [ ] Audience targeting configurations
- [ ] Dashboard mappings in Experience Workspaces
- [ ] Recommendation images
- [ ] Branding panel images
- [ ] The Account field in Login & Registration > Registration section
- [ ] The "Select which login options to display" in Login & Registration > Login section
- [ ] Experience Workspaces > Administration > Settings area
- [ ] Rich Publisher Apps configuration
- [ ] Login Flow assignment (deploy Flow first, then manually assign in Network settings)
- [ ] SSO provider assignment in Authentication Configuration
- [ ] Sharing Set configurations (verify they transferred correctly)
- [ ] Guest User Profile FLS and object permissions review
- [ ] CDN cache purge after deployment (if CDN is enabled)

## Experience Workspaces Navigation Reference (PDF p.38-40)

| Workspace | Purpose |
|---|---|
| **Builder** | Brand and design pages; add/configure LWC/Aura components; customize navigation; manage page settings |
| **Moderation** | View flagged posts/comments/files; configure moderation rules and criteria; review moderation dashboards |
| **Content Management** | Add CMS content; manage topics and recommendations; create navigation menus |
| **Gamification** | Configure recognition badges, reputation levels, missions |
| **Dashboards** | View site analytics dashboards; configure Engagement Insights reports |
| **Administration** | All core site settings: preferences, members, login/registration, emails, URL redirects, reputation |
| **Guided Setup** | Step-by-step wizard for configuring specific features (visibility, processes, workflows, layouts) |

**Permission to access Experience Workspaces:**
- Access Experience Management OR Manage Experiences OR Create and Set Up Experiences
- AND is a member of the site

**Caution:** If an administrator accidentally removes themselves from a site, they lose access to Administration settings in Workspaces. Recovery requires using the API to re-add themselves.
