---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: gotchas
last-updated: 2026-05-11
---

# Experience Cloud — Gotchas and Known Issues

## G-1: Framework Selection Is Permanent
**Source:** PDF p.20 (framework comparison)
**Impact:** High

You can build an Experience Cloud site using one of three frameworks: LWR, Aura, or Visualforce. The framework is selected at site creation time via the template choice. **After a site is created, the framework cannot be changed.** You cannot switch from Aura to LWR (or vice versa) after creation.

The downstream implications are significant:
- An Aura-based Customer Account Portal cannot be migrated to LWR in-place; a new site must be built from scratch
- Customers who choose Aura templates today must plan for future LWR migration as a separate project
- Template selection (not just framework) has long-term implications: "The choices you make at the beginning of your site creation process have long-term downstream implications" (PDF p.20)

**Mitigation:** Always confirm the business requirements, technical skill set, and long-term roadmap before selecting a template. LWR is the strategic direction for new builds; choose it if developer resources are available.

---

## G-2: LWR Route Limits
**Source:** PDF p.46 (redirect rules)
**Impact:** Medium

For LWR sites:
- **Dynamic redirect rules:** Up to 100 per org
- Site route limits: Not found in extracted pages with specific 500-max or 250-recommended figures — verify in LWR Sites for Experience Cloud developer guide separately

Dynamic redirect rules are LWR-only; Aura sites do NOT support dynamic redirects. Static redirects are supported by both Aura and LWR.

**URL redirect types:**

| Redirect Type | Aura | LWR |
|---|---|---|
| Static redirects from registered custom domain URLs | Yes | Yes |
| Redirects to URLs hosted outside Salesforce | Yes | Yes |
| Redirects between site pages on Salesforce domains | Yes | Yes |
| Redirects with query params in source/target | Yes | Yes |
| Dynamic redirect rules | No | Yes |

**LWR dynamic redirect caveats:**
- Dynamic redirects do NOT work for URLs that start with `/secur`
- Dynamic redirects do NOT work for URLs ending with `.css`
- Dynamic redirects do NOT work for URLs with `lastmod=`

---

## G-3: Bandwidth and CDN Limits
**Source:** PDF p.511-512 (scale and performance)
**Impact:** High

Bandwidth limits and CDN behavior affect high-traffic production sites. Specific numbers for 40 GB/day production Enterprise/Unlimited and 1 GB sandbox are not confirmed in extracted pages — verify with Salesforce documentation or your Account Executive.

**Confirmed from PDF:** The Salesforce CDN (Akamai) is the recommended mechanism for high-volume sites. CDN caching details:
- After deploying a site change, old versions may be served for up to the cache TTL
- CDN reduces page load times and is required for optimal performance on high-traffic sites
- The CDN also unlocks access to other features (e.g., Apex Caching for LWR sites)

**High-volume scenario tools (confirmed in PDF p.513-514):**
- Customer portals (high authenticated traffic): CDN + LWR + High-Volume Self-Registration micro-batching
- Lead capture / transaction sites: CDN + Account Role Optimization + High-Volume Record Creation micro-batching
- Large-scale B2B: CDN + Account Role Optimization

---

## G-4: Guest User Cannot Own Records — Sharing Required
**Source:** PDF p.517-518, p.30 (guest user security planning)
**Impact:** High

Guest users running in a guest context have several critical restrictions:

- **Cannot own records** — records created by guest users via micro-batching have `Created By = Guest User` but the guest user does NOT own them
- **Cannot access records via Apex `with sharing`** — any Apex invoked by guest users must be `without sharing` and must manually restrict what data is returned
- **Cannot be added to groups** — no group-based sharing to guest users
- **Cannot query records with `$User` merge fields** in dynamic SOQL
- **Cannot query records with Lookup filters** in dynamic SOQL

**For public form submission (guest creates a record):**
1. Use `Network.createRecordAsync('GENERIC', sObject)` for async batch creation
2. Or use Apex `without sharing` with explicit inserts
3. Never give guest users read access to the record after creation in the same transaction — sharing visibility race condition exists

**Required permission for guest record creation via micro-batching:** The "Use Micro-Batching to Create Records" profile permission on the Guest User profile (for authenticated variants) — verify exact permissions separately.

---

## G-5: Customer Community License Has No Role Hierarchy
**Source:** PDF p.688 (standard sharing vs. simple sharing)
**Impact:** High

**Customer Community license = Simple Sharing = no role hierarchy.**

This means:
- Sharing rules based on roles do NOT apply to Customer Community users
- You cannot use role-based sharing to grant Customer Community users visibility to records
- The only sharing mechanisms available are: Sharing Sets (field mapping) and direct record sharing

**Customer Community Plus license = Standard Sharing = has role hierarchy.**

**Consequence for architects:**
- If your portal users need to share data within an account's user group (e.g., one contact should see cases created by another contact in the same account), you need CC Plus or Partner Community
- If your portal is high-volume (thousands to millions of users) and sharing is simple (each user sees only their own records), use CC and Sharing Sets
- Choosing the wrong license forces a license change AND a sharing architecture redesign later

---

## G-6: DigitalExperienceBundle vs. ExperienceBundle — Wrong Type = Deploy Failure
**Source:** PDF p.722 (Metadata API deployment)
**Impact:** High

The metadata type required for deployment depends on the site type:

| Site Type | Required Metadata Type |
|---|---|
| Enhanced LWR (Winter '23+) | `DigitalExperienceBundle` + `DigitalExperienceConfig` |
| Non-enhanced LWR | `ExperienceBundle` |
| Aura | `ExperienceBundle` (recommended) or `SiteDotCom` |
| Visualforce/Tabs+VF | `SiteDotCom` |

**Critical failure scenarios:**
- Deploying `ExperienceBundle` for an enhanced LWR site → deployment errors
- Deploying `SiteDotCom` alongside `ExperienceBundle` for an Aura site → use `ExperienceBundle` only; do NOT include `SiteDotCom`
- If the site includes pages from Site.com Studio AND you deploy using `ExperienceBundle` → permanently deletes the Site.com Studio pages
- ExperienceBundle does NOT support deploying across different API versions without a specific multi-step process (see PDF p.723)

**API version cross-deployment steps (PDF p.723):**
1. Set API version in package.xml to the OLD version (e.g., 48.0) → deploy
2. Set API version in package.xml to the NEW version (e.g., 49.0) → retrieve updated bundle → then deploy

---

## G-7: Unsupported Items in Change Sets
**Source:** PDF p.721 (change set considerations and limitations)
**Impact:** Medium

The following items are NOT supported by change sets and must be manually configured in the target org after deployment:
- Navigational and featured topics
- Audience targeting / recommendations
- Dashboards and engagement
- Recommendation images
- **Branding panel images in Experience Builder**
- The following Administration settings in Experience Workspaces:
  - The Account field in the Registration section of Login & Registration
  - The "Select which login options to display" option in the Login section
  - The Settings area
  - The Rich Publisher Apps area

**Partial deployment for enhanced LWR sites (PDF p.721):**
- Available for enhanced LWR sites created Winter '23 or later
- Target org must contain an existing site with the SAME name as the source site
- Adding a Digital Experience component automatically adds its variations (including all translations for that view)

**Additional change set limitations (PDF p.720-721):**
- Navigation Menu: custom list views for standard objects are not included as dependencies; deploying nav menu with additional items deletes existing translations in target org
- Recommendation names: cannot be updated via change set; treated as new recommendations if name changes
- Administration settings for sites created in sandbox before Summer '17: must resave administration settings before migration
- Changes to Members area and Login & Registration area must be deployed in SEPARATE change sets (Members first, then Login & Registration)

---

## G-8: devName Is Immutable After Creation
**Source:** PDF p.723 (deployment tips), p.727 (deployment error table)
**Impact:** High

In `ExperienceBundle`, `devName` is automatically generated for a route when created. It is a required value and **must not be changed.**

**Error message when devName is altered:**
```
The devName of an existing route can't be changed. Revert the devName of the 
{generated_route_id} route back to its original value and try again.
```

**Cause:** Someone altered the auto-generated devName value in ExperienceBundle XML.

**Fix:**
1. Review recent modifications to standard component functionality
2. Determine how and why the name was altered
3. Revert the name to its original value

**Alternative:** Use `SiteDotCom` for deployment instead of `ExperienceBundle` (though this has other implications for Aura sites).

---

## G-9: Page View Overage Calculation
**Source:** Not found in extracted pages — verify separately with licensing documentation.
**Impact:** Medium

Page view overage calculation uses a 12-month look-back period rather than a calendar year. This means overages are measured against rolling consumption, not a fixed annual reset. Not confirmed in extracted PDF pages (pp. 720-730, 807-818) — verify with your Salesforce Account Executive or license documentation.

---

## G-10: Default Exposed Visualforce Pages — Guest Access Risk
**Source:** Not found in specific extracted pages — verify in Experience Cloud security documentation.
**Impact:** High

When sites are created, certain Visualforce pages may be exposed to guest users by default, potentially granting unauthorized access to internal VF page functionality. Not confirmed in extracted PDF pages — verify in the Experience Cloud security guide and "Develop Secure Sites" documentation referenced on PDF p.31.

**Remediation steps (general):**
1. Review all VF pages accessible from the Guest User profile
2. Remove Read access on any VF page not required for public access
3. Use the Guest User profile security review checklist

---

## G-11: ExperienceBundle Deployment — Component ID Duplication
**Source:** PDF p.726-727 (troubleshooting metadata deployment errors)
**Impact:** High

In `DigitalExperienceBundle`, each component in a view must have a unique ID. If two or more components share the same ID, deployment fails with:

```
Specify a unique ID for each component in this view.
```

**Fix:**
1. Retrieve metadata from both source and target orgs using DigitalExperienceBundle
2. In the view that caused the error, search for components with matching IDs in both orgs
3. Manually update one ID by altering a couple of characters to ensure uniqueness

---

## G-12: Config Mismatch Between Source and Target Orgs
**Source:** PDF p.727 (deployment error table)
**Impact:** Medium

When the site configuration in the source org does not match the target org (e.g., different theme names), deployment fails with:

```
We couldn't validate {property_name} in {file_path}.json for component {component_id}. 
Error: {specific_error_information}
```

**Cause example:** Source org uses `Default_User_Profile_Menu`; target org uses `Default_User_Profile_Menu1`.

**Fix:** Ensure source and target orgs use the same configuration. If error mentions a missing component, ensure component names match in both orgs.

---

## G-13: Missing isLockerServiceEnabled in Config
**Source:** PDF p.727 (deployment error table)
**Impact:** Medium

When the `isLockerServiceEnabled` property is missing from the site's `config/mainAppPage.json` file in ExperienceBundle:

```
You seem to be missing the property isLockerServiceEnabled in 
{site_name}/config/mainAppPage.json with component ID {component_id}.
```

**Fix:** Add the following to `config/mainAppPage.json`:
```json
"isRelaxedCSPLevel" : false
```

---

## G-14: Digital Experiences Cannot Be Disabled After Enabling
**Source:** PDF p.33 (Enable Digital Experiences section)
**Impact:** High

Once you enable Digital Experiences (the prerequisite step for ALL Experience Cloud sites), **you cannot disable it.** 

Additionally:
- If org access is suspended for non-payment, ALL sites are deactivated, including Preview status sites
- When Experience Cloud is re-enabled after suspension, all sites return to Inactive status
- Sites can be activated again, but they CANNOT return to Preview status
- The production domain format is: `MyDomainName.my.site.com`

---

## G-15: UrlPathPrefix Is Effectively Immutable After Go-Live
**Source:** PDF p.45 (Update Your Experience Cloud Site's Name, Status, and Description)
**Impact:** High

The `UrlPathPrefix` (e.g., `/portal`, `/customers`, `/partner`) is embedded in every URL for the site — bookmarks, email links, deep links, and mobile app configurations all use it.

**What the docs say:** "You can change your site name and URL after the site is activated, but users aren't redirected to the new URL. So be sure to inform your members before changing the name or URL."

**Practical implication:** Changing the URL prefix after go-live breaks all existing bookmarks and links. Treat the URL prefix as immutable after launch. If it must change:
1. Set up URL redirects at the Salesforce site level or CDN level
2. Notify all members of the URL change
3. Update all hardcoded links in emails, documentation, and mobile apps

---

## G-16: NavigationMenu devName Must Match in Source and Target
**Source:** PDF p.723 (deployment tips)
**Impact:** Medium

During deployment, the `NavigationMenu` developer name in the target org must match the developer name in the source org. If they differ, deployment will fail or navigation menus will be mislinked.

Additionally:
- `NavigationLinkSet` was DEPRECATED in Winter '20 (API v47.0) and replaced by `NavigationMenu`
- If `containerType = CommunityTemplateDefinition`, you cannot update an existing NavigationMenu via Metadata API
- Deploying nav menu with additional items deletes any translations applied to existing menu items in the target environment

---

## G-17: Deploying to Target Org on Earlier Release Version Fails
**Source:** PDF p.721, p.723 (change set and Metadata API deployment notes)
**Impact:** Medium

You CANNOT deploy to a target org that is on an earlier Salesforce release version than the source org.

Example: If source org is on Summer '19 (API v46.0), you cannot deploy to a target org on Spring '19 (API v45.0).

---

## G-18: Login Flows Must Be Explicitly Assigned After Deployment
**Source:** PDF p.44-45 (Administration settings), implicit from deployment documentation
**Impact:** Medium

Deploying a Screen Flow that is intended as a Login Flow does NOT automatically activate it. The Flow must be explicitly assigned in Experience Workspaces > Administration > Login & Registration > Login Flow section.

**Similarly for other Network-level settings** — many settings in the Administration workspace are NOT automatically transferred during deployment and require manual post-deploy configuration:
- The Account field in Registration section
- The "Select which login options to display" option in Login section
- The Settings area
- The Rich Publisher Apps area

Always include post-deploy checklists for manual steps in Experience Cloud deployments.

---

## G-19: Guest User Cannot See Records Created in Same Transaction
**Source:** PDF p.517-518 (micro-batching), implicit from guest sharing model
**Impact:** Medium

If an Apex action in a guest user context inserts a record and then immediately queries it in the same transaction, the query may return zero results. This is a sharing visibility issue — guest users cannot see records they just created unless both the DML and the query run `without sharing`.

**Root cause:** The guest user has no record-level access. The sharing evaluation happens at query time. Records created in `with sharing` context are invisible to the guest even immediately after insert.

**Fix:** Use `without sharing` consistently throughout all guest user Apex chains. Any class that runs in a guest context and needs to return data about records must be marked `without sharing`.

---

## G-20: LWC Components Require Correct targets in js-meta.xml to Appear in Builder
**Source:** Implicit from Experience Builder component model
**Impact:** Medium

LWC components must have `targets` that include `lightningCommunity__Page` (or `lightningCommunity__RecordPage`, etc.) in their `.js-meta.xml` to appear in Experience Builder's drag-and-drop interface. Components not configured with the correct targets simply do not show up in Builder.

**Required metadata:**
```xml
<LightningComponentBundle>
  <apiVersion>57.0</apiVersion>
  <isExposed>true</isExposed>
  <targets>
    <target>lightningCommunity__Page</target>
  </targets>
  <targetConfigs>
    <targetConfig targets="lightningCommunity__Page">
      <!-- targetConfig for EC Builder -->
    </targetConfig>
  </targetConfigs>
</LightningComponentBundle>
```

`isExposed: true` is required. This is the number one cause of "where is my component?" issues in Experience Builder.
