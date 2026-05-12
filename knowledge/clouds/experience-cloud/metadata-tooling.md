---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Experience Cloud — Metadata & Tooling

## Metadata Types Table (PDF p.722-723)

| Metadata Type | Purpose | Framework | API Version | Notes |
|---|---|---|---|---|
| `Network` | Full site configuration: admin settings, page overrides, email, membership | All | All | One per site; contains status, urlPathPrefix, networkMemberGroups, email templates, preferences |
| `CustomSite` | Domain/DNS config, page settings: indexPage, siteAdmin, URL definitions | All | All | Contains domain and page setting info; examine XML for missing dependencies |
| `DigitalExperienceBundle` | Site elements and settings for enhanced LWR sites; text-based; supports partial deployment | Enhanced LWR | v56.0 (Winter '23+) | New sites only; created from Winter '23 onward |
| `DigitalExperienceConfig` | Site configuration companion to DigitalExperienceBundle | Enhanced LWR | v56.0 (Winter '23+) | Used together with DigitalExperienceBundle |
| `ExperienceBundle` | Pages, branding, themes, components for non-enhanced LWR and Aura sites | LWR (non-enhanced), Aura | v45.0 (Summer '19+) | Recommended over SiteDotCom for Aura; NOT compatible with SiteDotCom in same deployment |
| `SiteDotCom` | Legacy site representation; binary .site file | Visualforce / legacy Tabs+VF | Pre-v45.0 | Not human readable; use ExperienceBundle for Aura instead |
| `NavigationMenu` | Navigation menu component | All | v47.0+ | Replaced `NavigationLinkSet` (deprecated Winter '20 / v47.0) |
| `CommunityTemplateDefinition` | Custom site template definition | Aura | — | Deploy before ExperienceBundle when using custom templates |
| `CommunityThemeDefinition` | Custom theme | Aura | — | Deploy before ExperienceBundle when using custom templates |

### Required Metadata Types by Site Type (PDF p.722)

| Metadata Type | Enhanced LWR | LWR (non-enhanced) | Aura | Visualforce/Tabs+VF |
|---|---|---|---|---|
| `Network` | Required | Required | Required | Required |
| `CustomSite` | Required | Required | Required | Required |
| `DigitalExperienceBundle` | Required | Not used | Not used | Not used |
| `DigitalExperienceConfig` | Required | Not used | Not used | Not used |
| `ExperienceBundle` | Not used | Required | Recommended | Not used |
| `SiteDotCom` | Not used | Not used | Alternative (not recommended) | Required |

## Change Set Capabilities and Limitations (PDF p.720-721)

### What IS Supported in Change Sets

- Network component (full site configuration)
- CustomSite (domain settings)
- ExperienceBundle / DigitalExperienceBundle components (pages, themes, branding sets)
- Profiles and permission sets (must be added manually as dependencies)
- Custom objects, fields, Apex classes, Apex pages, components
- Navigation menu items (static)
- **Partial deployment for enhanced LWR sites** (Winter '23+):
  - Add individual Digital Experience components to outbound change set
  - Target org must have a site with the SAME name as source site
  - Adding a component also adds all its variations (including translations)

### What IS NOT Supported in Change Sets (PDF p.721)

These must be manually configured in the target org after deployment:

| Unsupported Item | Workaround |
|---|---|
| Navigational and featured topics | Manually create in target org via Experience Workspaces |
| Audience targeting configurations | Manually recreate audience targeting rules |
| Dashboards and engagement mappings | Manually map dashboards in Experience Workspaces |
| Recommendation images | Upload manually to target org |
| **Branding panel images in Experience Builder** | Upload manually to target org |
| The Account field in Login & Registration > Registration section | Set manually in target org |
| "Select which login options to display" in Login section | Set manually in target org |
| Administration > Settings area | Configure manually |
| Rich Publisher Apps configuration | Configure manually |

### Change Set Behavioral Notes (PDF p.720-721)

- Deploying an inbound change set **overwrites** the corresponding site content in the target org
- Deleting pages in source sandbox + deploying change set = pages deleted in target org too
- Must update template in target org BEFORE deploying change set if template was updated in source
- Cannot deploy to a target org on an earlier Salesforce release version
- For sites created in sandbox before Summer '17: must resave Administration settings before migration
- Changes to Members area and Login & Registration must be in SEPARATE change sets (Members first, then Login & Registration)
- Navigation menu deployment with additional items deletes existing translations in target
- Recommendation names cannot be renamed; renaming = treated as a new recommendation in target

## Metadata API Deployment Steps (PDF p.722-726)

### Preparation
1. Enable Digital Experiences in the destination org (required before deploying any EC metadata)
2. Use the same domain name in sandbox and production (avoids errors from domain mismatch)
3. Confirm source and target orgs are on the same API version (cannot deploy to earlier release)

### Retrieve Step
```
sf project retrieve start --manifest package.xml --target-org <org-alias>
```
Or with Metadata API:
```
<retrieve request with specified package.xml>
```

The generated XML file name for the Network component is based on the site name. If someone changes the site name in sandbox and then tries to migrate, the API looks for a site with the existing path prefix and may fail.

### Deploy Step
```
sf project deploy start --manifest package.xml --target-org <org-alias>
```
Or validate first:
```
sf project deploy start --manifest package.xml --target-org <org-alias> --dry-run
```

### Critical Deployment Tips (PDF p.723-724)

1. **devName immutability:** devName of existing routes cannot be changed in ExperienceBundle — revert if altered
2. **Configuration mismatch:** Source and target org site configs must match (themes, component names)
3. **Missing isLockerServiceEnabled:** Add `"isRelaxedCSPLevel": false` to `config/mainAppPage.json`
4. **NavigationMenu devName:** Must match in source and target org
5. **Guest user profile:** If changed, include profile in the site migration
6. **Network and Profile deployment in unlocked packages:** Create a separate unlocked package for each and deploy individually
7. **Custom template:** Retrieve and deploy `CommunityTemplateDefinition` and `CommunityThemeDefinition` first, then deploy `ExperienceBundle`
8. **ID values in components:** Deploy succeeds despite ID warnings, but verify referenced IDs are valid in target org; if invalid, update manually or replace with API name in custom components

### Cross-API-Version ExperienceBundle Upgrade Steps (PDF p.723)
When upgrading ExperienceBundle from one API version to a later one (e.g., v48.0 to v49.0):
1. Set API version in package.xml to OLD version (e.g., 48.0)
2. Deploy the package
3. Set API version in package.xml to NEW version (e.g., 49.0)
4. Retrieve the package to get latest ExperienceBundle updates
5. Deploy the updated package

## Sample package.xml for Deploying an LWR Site (PDF p.725-726)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>*</members>
    <name>Network</name>
  </types>
  <types>
    <members>*</members>
    <name>CustomSite</name>
  </types>
  <types>
    <members>*</members>
    <name>ExperienceBundle</name>
  </types>
  <types>
    <members>*</members>
    <name>CustomTab</name>
  </types>
  <types>
    <members>*</members>
    <name>CustomObject</name>
  </types>
  <types>
    <members>*</members>
    <name>ApexClass</name>
  </types>
  <types>
    <members>*</members>
    <name>ApexPage</name>
  </types>
  <types>
    <members>*</members>
    <name>ApexComponent</name>
  </types>
  <types>
    <members>*</members>
    <name>Portal</name>
  </types>
  <types>
    <members>*</members>
    <name>Profile</name>
  </types>
  <types>
    <members>*</members>
    <name>Document</name>
  </types>
  <version>46.0</version>
</Package>
```

**For enhanced LWR site:** Replace `ExperienceBundle` entries with `DigitalExperienceBundle` and `DigitalExperienceConfig`.

## Sample Network XML Snippet (PDF p.724-725)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Network xmlns="http://soap.sforce.com/2006/04/metadata">
  <allowInternalUserLogin>true</allowInternalUserLogin>
  <allowMembersToFlag>true</allowMembersToFlag>
  <allowedExtensions>txt,png,jpg,jpeg,pdf,doc,csv</allowedExtensions>
  <caseCommentEmailTemplate>unfiled$public/ContactFollowUpSAMPLE</caseCommentEmailTemplate>
  <changePasswordTemplate>unfiled$public/CommunityChangePasswordEmailTemplate</changePasswordTemplate>
  <disableReputationRecordConversations>true</disableReputationRecordConversations>
  <emailSenderAddress>admin@myorg.com</emailSenderAddress>
  <emailSenderName>MyCommunity</emailSenderName>
  <enableCustomVFErrorPageOverrides>true</enableCustomVFErrorPageOverrides>
  <enableDirectMessages>true</enableDirectMessages>
  <enableGuestChatter>true</enableGuestChatter>
  <enableGuestFileAccess>false</enableGuestFileAccess>
  <enableInvitation>false</enableInvitation>
  <enableKnowledgeable>true</enableKnowledgeable>
  <enableNicknameDisplay>true</enableNicknameDisplay>
  <enablePrivateMessages>false</enablePrivateMessages>
  <enableReputation>true</enableReputation>
  <enableShowAllNetworkSettings>true</enableShowAllNetworkSettings>
  <enableSiteAsContainer>true</enableSiteAsContainer>
  <enableTalkingAboutStats>true</enableTalkingAboutStats>
  <enableTopicAssignmentRules>true</enableTopicAssignmentRules>
  <enableTopicSuggestions>true</enableTopicSuggestions>
  <enableUpDownVote>true</enableUpDownVote>
  <forgotPasswordTemplate>unfiled$public/CommunityForgotPasswordEmailTemplate</forgotPasswordTemplate>
  <gatherCustomerSentimentData>false</gatherCustomerSentimentData>
  <lockoutTemplate>unfiled$public/CommunityLockoutEmailTemplate</lockoutTemplate>
  <maxFileSizeKb>51200</maxFileSizeKb>
  <networkMemberGroups>
    <permissionSet>MyCommunity_Permissions</permissionSet>
    <profile>Admin</profile>
  </networkMemberGroups>
  <networkPageOverrides>
    <changePasswordPageOverrideSetting>VisualForce</changePasswordPageOverrideSetting>
    <forgotPasswordPageOverrideSetting>Designer</forgotPasswordPageOverrideSetting>
    <homePageOverrideSetting>Designer</homePageOverrideSetting>
    <loginPageOverrideSetting>Designer</loginPageOverrideSetting>
    <selfRegProfilePageOverrideSetting>Designer</selfRegProfilePageOverrideSetting>
  </networkPageOverrides>
  <picassoSite>MyCommunity1</picassoSite>
  <selfRegistration>true</selfRegistration>
  <sendWelcomeEmail>true</sendWelcomeEmail>
  <site>MyCommunity</site>
  <status>Live</status>
  <tabs>
    <defaultTab>home</defaultTab>
    <standardTab>Chatter</standardTab>
  </tabs>
  <urlPathPrefix>mycommunity</urlPathPrefix>
  <welcomeTemplate>unfiled$public/CommunityWelcomeEmailTemplate</welcomeTemplate>
</Network>
```

**Key Network XML fields:**
- `picassoSite` — links to Experience Builder site; must match in source and target during deployment (PDF p.723)
- `site` — site name; must match target's site name for update (vs. create) behavior
- `urlPathPrefix` — site URL path; immutable after go-live
- `networkPageOverrides` — `Designer` = Experience Builder; `VisualForce` = custom VF page
- `networkMemberGroups` — profiles and permission sets with access to the site

## Common Deployment Errors (PDF p.726-727)

| Error Message | Cause | Fix |
|---|---|---|
| `Specify a unique ID for each component in this view.` | In DigitalExperienceBundle, two or more components in a view have the same ID | Retrieve metadata from both source and target orgs; find matching IDs; manually update one ID by altering a few characters |
| `The devName of an existing route can't be changed. Revert the devName of the {route_id} route back to its original value and try again.` | In ExperienceBundle, the auto-generated devName for a route was altered | Review recent modifications; determine how the name was altered; revert to original; alternatively use SiteDotCom for deployment |
| `We couldn't validate {property_name} in {file_path}.json for component {component_id}. Error: {specific_error_information}` | Site configuration mismatch between source and target (e.g., different theme names) | Ensure source and target use the same configuration; check that component names match in both orgs |
| `You seem to be missing the property isLockerServiceEnabled in {site_name}/config/mainAppPage.json with component ID {component_id}.` | The `isLockerServiceEnabled` property is missing from `config/mainAppPage.json` in ExperienceBundle | Add `"isRelaxedCSPLevel": false` to the `config/mainAppPage.json` file |
| `Your site needs a route with route type {route_type}.` | Discrepancy between features/custom objects enabled in source vs. target org; OR required default route type was deleted/renamed | Enable the relevant permission in source org; retrieve ExperienceBundle again; redeploy. Or: disable the permission on target org; or update `{site_name}.site-meta.xml` to include the correct route type |
| ID value warning: `The {topicId} property of component {id} references an object with the ID value {id}. Occasionally, when deployed to a destination org, ID values can become invalid` | Referenced ID (e.g., topic ID) doesn't exist in destination org | Deploy succeeds despite warning; verify in target org that the referenced ID is valid; update manually if invalid; for custom components: replace hardcoded ID with object's API name |

## CI/CD Considerations for Experience Cloud

### General Principles

1. **Retrieve before deploy:** Always retrieve from the target org before deploying; never assume the bundle is in sync
2. **API version pinning:** Pin the Metadata API version in `package.xml`; do not mix API versions within a deployment cycle
3. **No partial ExperienceBundle deploys** (non-enhanced LWR/Aura): The entire ExperienceBundle must be deployed as a unit; a single component change requires full bundle redeploy which briefly disrupts the site
4. **Enhanced LWR partial deployment:** Use DigitalExperienceBundle for partial component-level deploys (Winter '23+)
5. **Off-peak deployments:** Always deploy Experience Cloud changes during off-peak hours to minimize disruption

### CI/CD Pipeline Checklist

- [ ] Enable Digital Experiences in target org before first deploy
- [ ] Domain name must match between source and target org (set up My Domain in target first)
- [ ] Include all dependency metadata (profiles, custom objects, Apex) in the same deployment
- [ ] Run validate-only deploy (`--dry-run` or `checkOnly: true`) before production deployment
- [ ] Treat Guest User Profile changes as high-risk; include profile in the deployment package
- [ ] After deployment: run post-deploy checklist for manually configured items
- [ ] After deployment: clear CDN cache if CDN is enabled
- [ ] After deployment: publish the site in Experience Builder to apply any builder-level changes

### Source Control Strategy

- Experience Cloud ExperienceBundle is stored as XML in source control
- DigitalExperienceBundle is stored as directory structure in source control
- Text content entered in Experience Builder (text blocks, hero image URLs, navigation labels) lives in ExperienceBundle/DigitalExperienceBundle — treat as code
- Never make text content changes directly in sandbox with intent to propagate manually; always use source control deploy workflow
- CMS Content (created in CMS Workspaces) is NOT deployable via standard metadata — managed in the org UI

### Scratch Org / Developer Edition Considerations

- SEO sitemap is only available in production orgs; not in Developer Edition, sandbox, or trial orgs
- Customer Insights is not available in sandbox environments
- Google Analytics integration for testing: can publish from sandbox/Developer Edition for test purposes, but deploy to production before making site public

### SFDX / Salesforce CLI Commands

**Retrieve Network and ExperienceBundle:**
```bash
sf project retrieve start \
  --metadata "Network:*" \
  --metadata "CustomSite:*" \
  --metadata "ExperienceBundle:*" \
  --target-org sandbox-alias
```

**Retrieve Enhanced LWR site:**
```bash
sf project retrieve start \
  --metadata "Network:*" \
  --metadata "CustomSite:*" \
  --metadata "DigitalExperienceBundle:*" \
  --metadata "DigitalExperienceConfig:*" \
  --target-org sandbox-alias
```

**Validate deploy (check-only):**
```bash
sf project deploy start \
  --manifest package.xml \
  --target-org production-alias \
  --dry-run
```

**Deploy to production:**
```bash
sf project deploy start \
  --manifest package.xml \
  --target-org production-alias
```

### Deployment to Production Approval Protocol

Per ADLC security baseline:
- Never deploy to production without explicit human approval
- Always validate in sandbox first with a check-only deploy
- Confirm target org alias before executing mutation deploy
- Schedule production deployments during maintenance windows
- Coordinate with site administrators on CDN cache purge and post-deploy manual steps
