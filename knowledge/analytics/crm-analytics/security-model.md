---
source: Salesforce Trailhead — CRM Analytics Administration Basics; Build and Administer CRM Analytics trail; trailhead.salesforce.com (2026-05-17)
product: CRM Analytics
section: security-model
last-updated: 2026-05-17
---

# CRM Analytics — Security Model

## How CRM Analytics Security Works

CRM Analytics has its own security layer on top of the Salesforce platform security model. Salesforce object-level security (profiles/permission sets) controls who can access Salesforce records, but it does not automatically restrict what a user sees in a CRM Analytics dataset. Dataset security must be configured explicitly.

Two layers work together:

```
Layer 1: Salesforce Platform Access
  → Profile / Permission Set grants CRM Analytics license and feature access

Layer 2: Dataset Security (Row-Level Security)
  → Security predicate on a dataset limits which rows each user can query
```

## Layer 1 — Platform Access (Permission Sets)

Two permission sets are required for every Analytics user:

| Permission Set | Who Gets It |
|---|---|
| `CRM Analytics Plus User` | All end users who view or interact with dashboards |
| `CRM Analytics Plus Admin` | Admins and developers who create/manage apps, datasets, dataflows |

For Growth-tier orgs, use `CRM Analytics Growth User` and `CRM Analytics Growth Admin` instead.

**Do not use profiles for Analytics access.** Use permission sets only.

### Functional Permissions within CRM Analytics

Additional permissions within the CRM Analytics permission set control specific capabilities:

| Permission | Purpose |
|---|---|
| Manage Analytics | Full admin — create apps, manage dataflows, configure data sync |
| Create CRM Analytics Apps | Create new apps |
| Edit CRM Analytics Dataflows | Modify dataflows |
| Upload External Data to CRM Analytics | Upload CSV files |
| Create and Edit CRM Analytics Datasets | Manage datasets directly |
| View CRM Analytics | Basic view access — minimum for end users |

## Layer 2 — Dataset Row-Level Security (Security Predicates)

A security predicate is a SAQL filter expression attached to a dataset. It is evaluated at query time for every user. The predicate can reference:
- The current user's `$User.Id`
- Any field on the `$User` object (profile, role, custom fields)
- A security dataset (a separate flat dataset that maps user IDs to their allowed dimension values)

### Simple Predicate: Owner-Based

```saql
'OwnerId' == "$User.Id"
```

Users only see rows they own. Admin users with the "Manage Analytics" permission bypass all predicates.

### Role-Hierarchy Predicate

To enforce Salesforce role hierarchy (users see their records + subordinates'), include a flattened role hierarchy in the dataset:

1. In the dataflow/recipe, use a `flatten` node to expand the role hierarchy into a lookup table: each row is a (parent_role_id, child_user_id) pair
2. Join this to the main dataset on `OwnerId`
3. Predicate: `'RoleHierarchyId' == "$User.UserRoleId"`

### Security Dataset Pattern (Most Flexible)

For complex multi-dimensional access (user has access to specific regions, product lines, accounts):

1. Create a security dataset: one row per (UserId, allowed_dimension_value). Example: (005xxx, "West"), (005xxx, "Central"), (005yyy, "East")
2. In the predicate, reference this dataset:

```saql
'Region' in ["West", "Central", "East"]  // simplified — actual pattern uses $User lookup
```

The full pattern uses a `cogroup` in the predicate query referencing the security dataset by UserId.

### Predicate Configuration

Set the predicate in the dataset editor:
1. Analytics Studio → Datasets → select dataset → Edit
2. Security Predicate field → enter the SAQL expression
3. Save

Test by impersonating users in the dataset preview.

## App-Level Sharing

Apps are the sharing unit in CRM Analytics. Access to dashboards and datasets is controlled at the app level.

### App Sharing Modes

| Mode | Who Can Access |
|---|---|
| **Private** | Only the app creator and Admins |
| **Shared** | Specific users, groups, roles, or profiles granted explicit access |
| **Public** | All org users with the Analytics license |

### Access Levels within an App

| Level | Capabilities |
|---|---|
| **Viewer** | View and interact with dashboards; run lenses |
| **Editor** | Create and edit dashboards, lenses; cannot create datasets |
| **Manager** | Full control: create datasets, dataflows, share app, change settings |

Assign via: Analytics Studio → App → Share.

## Embedded Dashboard Security

When a dashboard is embedded in a Lightning record page:
- The viewing user must have the `View CRM Analytics` permission set
- The embedded dashboard respects the dataset security predicate — it does not inherit the record page's sharing model automatically
- The record context filter (e.g., AccountId) narrows the view further, but the predicate is the access gate

**Common Gotcha:** An admin sees data in an embedded dashboard that a regular user does not. This is almost always a predicate issue — admins bypass predicates by default. Test always as the target persona user.

## Data Residency and Org Isolation

CRM Analytics datasets are stored in the Analytics platform within the same Salesforce org. Data does not leave the org boundary. For multi-org deployments (e.g., separate Sales and Service orgs), a dedicated Analytics org or Data Cloud is required for cross-org analytics.

## Audit and Monitoring

- **Analytics Studio → Data Manager → Job log** — all dataflow/recipe runs with success/failure status
- **Setup → Event Monitoring** — Analytics-specific events (DashboardViewed, LensViewed, DatasetExported) available if Event Monitoring is licensed
- **Setup → Setup Audit Trail** — records changes to Analytics settings, permission sets, app sharing

Monitor the job log after every deployment. A failing dataflow or recipe that is not caught means users see stale data with no error message.
