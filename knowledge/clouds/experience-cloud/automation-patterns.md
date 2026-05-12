---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Experience Cloud — Automation Patterns

## Pattern 1: Self-Registration

### Default vs. Custom Apex Controller (PDF p.510-520)

Experience Cloud supports self-registration through two approaches:

**Standard self-registration:**
- Configure in Experience Workspaces > Administration > Login & Registration
- Enable self-registration and specify a default profile and account for new users
- Salesforce creates the user synchronously when the registration form is submitted

**Custom Apex controller approach:**
- Required when business logic must run during registration (e.g., duplicate account/contact detection, custom field population)
- Must be marked `without sharing` — guest user context has no record access
- Uses `Site.createPortalUser()` or the async variant `Network.createExternalUserAsync()`

### High-Volume Micro-Batching with createExternalUserAsync (PDF p.510-516)

For high-traffic sites, standard synchronous self-registration degrades performance during spikes. Micro-batching processes registrations asynchronously in batches.

**Key facts:**
- Site can handle approximately twice as many self-registration requests per unit time
- Accounts and contacts created by micro-batching are owned and managed by the community administrator
- After batch processes successfully, users receive an email with login instructions
- Error emails for processing failures go to site admin by default; change via `Site.Admin` field

**Licensing requirement:**
- External Identity and Customer Community license users — supported
- Customer Community Plus and Partner Community users WITH Account Role Optimization (ARO) enabled — supported
- Users CANNOT be created for existing accounts using self-registration

**Apex method signature:**
```apex
String uuid = Network.createExternalUserAsync(user, contact, account);
```

**Parameters:**
- `user` — required sObject (User)
- `contact` — for business account sites: Contact sObject (not yet saved); for person account sites: leave blank
- `account` — for business account sites: Account sObject; for person account sites: leave blank

**Example Apex usage (PDF p.516):**
```apex
// For business account self-registration
Contact newContact = new Contact(
    FirstName = firstName,
    LastName = lastName,
    Level__c = 'Primary'
);

Account newAccount = new Account(
    Name = 'Account for ' + lastName,
    Description = 'account description',
    Active__c = 'Yes'
);

// uuid is temporary ID for tracking the batch submission
String uuid = Network.createExternalUserAsync(user, newContact, newAccount);
```

**Error handling:**
- Use Connect REST API to retrieve errors for failed registrations:
  ```
  GET /connect/communities/${communityId}/microbatching/errors
  ?processType=SELF_REGISTRATION
  &earliestDate=2021-11-16T16:17:31.797Z
  ```
- After fixing root cause, reprocess or download and discard errors
- Error emails sent to site admin; configure error email template at Administration > Emails

## Pattern 2: Login/Registration Flows

### Built-in Flow Types (PDF p.688)

Experience Cloud supports the following login and registration flow types configured in Experience Workspaces > Administration > Login & Registration:

| Flow Type | Trigger | Use Case |
|---|---|---|
| **Login Flow** | After successful authentication, before landing page | Collect additional profile info on first login; enforce T&C acknowledgement; re-route users based on permission set |
| **Registration Flow** | During self-registration | Custom form fields; duplicate detection; account/contact matching logic |
| **Forgot Password Flow** | When user requests password reset | Custom security questions; verification steps |
| **Self-Registration Flow** | Public page for new user creation | Complete control over self-registration UX and logic |

### Login Flow Pattern
Configure a Screen Flow as the Login Flow. Assign it in Experience Workspaces > Administration > Login & Registration > Login Flow.

```
Login Flow (Screen Flow):
  Decision: Check if User.Has_Accepted_TnC__c = true
    → False: Screen — display T&Cs, require checkbox agreement
    → True: Skip to end
  Action: Update User.Has_Accepted_TnC__c = true, set datetime
  Action: Redirect to home page
```

**Critical deployment note:** Deploying the Flow alone does NOT activate it. The Flow must be explicitly assigned in the Network's Login & Registration settings after deployment.

### Post-Login Redirect
Configure `LoginRedirectUrl` on the Network OR use a Screen Flow as the Login Flow for conditional routing.

## Pattern 3: High-Volume Record Creation with Micro-Batching (PDF p.517-520)

For high-traffic sites, standard synchronous record creation can be replaced with async batch processing.

**Supported objects:** Cases, Leads, and custom objects (NOT all objects)

**How it works:**
- Records are collected into batches and processed asynchronously by the Automated Process user
- Site admins with "Set Audit Fields upon Record Creation" permission can set the Created By field to the original user
- Without this permission, Created By is set to Automated Process user
- When guest users create records via micro-batching: Created By = Guest User; guest users do NOT own the created records

### Apex Method (PDF p.517)

```apex
// createRecordAsync(processType, sObject, fileAttachmentLinks)
// processType must be 'GENERIC'
// sObject cannot be empty or null
// fileAttachments is optional array of ContentDocumentIDs

Case myCase = new Case(
    Subject = 'sample case',
    Description = 'case description'
);
String uuid = Network.createRecordAsync('GENERIC', myCase);
```

**uuid** is the temporary ID of the submitted record. Use it to identify errors via Connect API.

### Behavior Notes
- Field-level security and record type access are BYPASSED when creating records via micro-batching; they apply AFTER the record is created
- Records created via micro-batching use the DEFAULT record type for the org
- When creating a child record: only Read access on the parent record is required
- The "Use Micro-Batching to Create Records" profile permission is required for authenticated users

### Experience Builder Configuration (PDF p.519)
For the Create Record Form, Contact Support Form, and Lead Form (LWC) components:
1. Click the component
2. In Site Performance section, select "Create records in batches" or "Create cases in batches"
3. Publish the site

**Lead Form (LWC):** Enabled for micro-batching by default; requires no configuration.

### Test Class Pattern (PDF p.518)
```apex
@IsTest
public class MicrobatchCreateRecord_Test {
    @IsTest
    public static void testMicrobatchCreateCase() {
        string newCaseSubject = 'ApexTestCase1';
        MicrobatchCreateRecord controller = new MicrobatchCreateRecord();
        Test.startTest();
        string uuid = controller.microbatchCreateCase(newCaseSubject);
        Assert.isNotNull(uuid);
        Test.getEventBus().deliver();
        Test.stopTest();
        List<Case> testCases = [Select Id, Subject from Case];
        Assert.areEqual(1, testCases.size());
        Assert.areEqual(newCaseSubject, testCases[0].subject);
    }
}
```

## Pattern 4: Partner Central Deal Registration Approval

### Partner Site Setup Sequence (PDF p.637-642)
Partner Central is designed for channel sales workflows. Full setup involves:

**Prerequisite licensing:**
Purchasing Partner Community licenses enables:
- Partner Central template
- Default Partner User profile
- Three standard partner roles: Partner User, Partner Manager, Partner Executive
- Manage External Account / Enable as Partner buttons on Accounts
- Manage External User / Enable Partner User buttons on Contacts

**Sharing setup for partners (PDF p.640):**
1. Set Default External Access = Private for all objects to be shared with partners
2. Clone and customize the Partner User profile
3. Create partner accounts (enable via "Enable as Partner" on Account)
4. Add partner contacts, convert to partner users with partner license, profile, and role
5. Optionally enable super user access for partner users needing cross-user data visibility
6. Consider delegating user administration for large partner networks

**Deal Registration Flow pattern:**
```
Screen Flow on Partner Portal page:
  Screen: Collect deal details (Company, Contact, Expected Value, Product Interest)
  Apex action (or Create Record element): Create Lead or Opportunity in partner's Account context
  Action: Assign to internal Channel Manager queue via assignment rule or process automation
  Screen: Confirmation with deal number
```

**Approval Process for Deal Registration (conceptual — verify exact setup in PRM documentation):**
- Approval Process on Lead or Opportunity record
- Notification sent to channel manager for review
- On approval: update status, notify partner via email alert
- On rejection: notify partner with reason

**MDF (Marketing Development Funds) pattern:**
```
Screen Flow: Partner submits MDF request
  → Create MDF_Request__c owned by partner user
  → Trigger Approval Process on MDF_Request__c
  → On approval: update Approved_Amount__c, notify partner via email
```

**Lead Distribution pattern:**
- Leads distributed to partner via lead queue or direct assignment
- "Lead Inbox" component in Partner Central shows partner user their assigned leads
- Partners accept or reject leads from the inbox

## Pattern 5: Moderation Rules (PDF p.750)

### Moderation Limits
| Limit | Value |
|---|---|
| Keyword list criteria per org | 30 |
| Member criteria per org | 100 |
| Keyword criteria per content rule | 3 |
| Member criteria per content rule | 10 |
| Member criteria per rate rule | 10 |

**Scope:** Moderation rules apply only to feed posts, comments, and polls. Rules do NOT apply to topics that are created.

### Keyword Triggers
Configure in Experience Workspaces > Moderation:
- **Content rules:** keyword criteria → action (Flag, Block, Replace, Notify moderator)
- **Rate rules:** member criteria → action when posting rate exceeds threshold
- Setting "Moderation rules apply to all feed posts" extends rules to posts visible across multiple sites (not just origin site)

### Applying Moderation
- Moderators can review and act on flagged posts, comments, and files
- Actions: delete, remove flag, freeze member, block content
- Insights reports provide moderation dashboards with actionable bulk operations (e.g., select all spam posts, click Delete Post)

## Pattern 6: Reputation & Gamification (PDF p.780-784)

### Enabling Reputation
1. Experience Workspaces > Administration > Preferences
2. Select "Enable setup and display of reputation levels"
3. Default point system and 10 reputation levels are created automatically

### Default Point Events and Values

| Action Category | Action | Default Points |
|---|---|---|
| **Engagement** | Write a post | 1 |
| | Write a comment | 1 |
| | Receive a comment | 5 |
| | Like something | 1 |
| | Receive a like | 5 |
| | Share a post | 1 |
| | Someone shares your post | 5 |
| | Mention someone | 1 (per @mention) |
| | Receive a mention | 5 |
| **Questions & Answers** | Ask a question | 1 |
| | Answer a question | 5 |
| | Receive an answer | 5 |
| | Mark an answer as best | 5 |
| | Your answer is marked as best | 20 |
| **Knowledge** | Endorse someone for knowledge on a topic | 5 |
| | Being endorsed for knowledge on a topic | 20 |

**Note:** "Questions and answers in the feed" is separate from Chatter Answers functionality.

**Reputation levels:** Minimum 3 levels; maximum 50 levels. Default is 10 levels. Point totals are visible on member profiles.

### Missions (Auto-Badging) (PDF p.773-774)
Automatically assign badges when members reach action thresholds:
- Community manager defines: action type + threshold count + badge
- Example: "Nice Work" badge when member answers 10 questions
- Members earn each mission badge ONCE
- Missions count activities that occurred before setup; use Reset Activity Count to restart counters

### Apex Badge Assignment Pattern (PDF p.777)

```apex
// Assign badge and create Chatter post notification
WorkThanks thanks = new WorkThanks(
    NetworkId = networkID,
    GiverID = giverID,
    Message = 'Welcome to the site'
);
insert thanks;

WorkBadge badge = new WorkBadge(
    DefinitionId = badgeDefinitionId,
    NetworkID = networkID,
    RecipientId = recipientID,
    SourceId = thanks.id
);
insert badge;

// Optional: create Chatter post to notify member
FeedItem feedItem = new FeedItem(
    NetworkScope = networkID,
    ParentId = recipientID,
    RelatedRecordId = thanks.id,
    Body = message,
    Type = 'RypplePost',
    Visibility = 'AllUsers'
);
insert feedItem;
```

### Trigger-Based Badge Assignment on Reputation Points (PDF p.778)
```apex
trigger NetworkMemberTrigger on NetworkMember (after update) {
    for (NetworkMember nm : Trigger.New) {
        User user = [select ID, hasBadge__c from User where ID = :nm.MemberID];
        if (nm.ReputationPoints >= 40 && !user.hasBadge__c) {
            WorkThanks thanks = new WorkThanks(
                GiverId = '005B00000036ukY',
                Message = 'inserted by trigger',
                NetworkId = nm.NetworkId
            );
            insert thanks;
            WorkBadge badge = new WorkBadge(
                DefinitionId = '0W1B0000000T1QBKA0',
                NetworkId = nm.NetworkId,
                RecipientId = nm.MemberId,
                SourceId = thanks.id
            );
            insert badge;
            user.hasBadge__c = true;
            update user;
        }
    }
}
```

## Pattern 7: Scale and Performance Tools (PDF p.510-514)

### Which Tools to Use by Use Case

| Use Case | Recommended Tools |
|---|---|
| High guest traffic (B2C help center) | Customer Community License; Salesforce CDN; LWR framework; Progressive Rendering; Page Optimizer; Apex Caching |
| High authenticated traffic (customer portal) | Customer Community License; CDN; LWR; High-Volume Self-Registration Micro-batching; Progressive Rendering; Page Optimizer |
| High transaction loads (lead capture, loan apps) | Customer Community or CC Plus; CDN; Account Role Optimization; High-Volume Self-Registration Micro-batching; High-Volume Record Creation Micro-batching |
| Large-scale B2B with many roles | CC Plus or Partner Community; CDN; Account Role Optimization |

### Account Role Optimization (ARO)
- Delays account role creation until SECOND user is added to a business account
- If account has only one user: roles are not created
- Reduces role proliferation for high-volume sites
- Can be combined with person account owner power users for extreme scale

### Progressive Rendering (Aura sites only)
Priority levels for top-level components:
- **Highest:** Displayed first; use for key above-the-fold content
- **High:** Displayed after Highest group
- **Neutral:** Default; displayed last

## Decision Matrix: Flow vs. Apex vs. Process Builder for EC Automation

| Requirement | Recommended Tool | Notes |
|---|---|---|
| Self-registration (standard, low volume) | Login/Registration Flow | Configure in Network settings; no code required |
| Self-registration (high volume / micro-batching) | Apex (`Network.createExternalUserAsync`) | Required for async batch processing |
| Record creation (high volume) | Apex (`Network.createRecordAsync`) OR LWC component config | Supports Cases, Leads, custom objects |
| Login flow (T&C, profile update, routing) | Screen Flow (Login Flow type) | Assign to Network in Administration; deploy Flow first |
| Registration flow (custom fields, duplicate check) | Screen Flow (Registration Flow type) | Configure in Login & Registration settings |
| Post-registration notification email | Flow with Send Email action OR Apex `Messaging.SingleEmailMessage` | Use OrgWideEmailAddress for from-address |
| Moderation automation (keyword blocking) | Moderation Rules in Experience Workspaces | No code; up to 30 keyword criteria per org |
| Partner deal registration | Screen Flow on Portal page + Approval Process | Apex action for complex logic |
| Reputation badge award | Apex trigger on NetworkMember | For threshold-based automation; use WorkThanks + WorkBadge |
| Content visibility (role-based) | Data Category Visibility (Knowledge) + Permission Sets | Configure via Profile/PermSet data category visibility |
| MDF request approval | Screen Flow + Approval Process | Standard Salesforce approval chain |

**Process Builder:** Not recommended for new Experience Cloud automation. Migrate to Flow where possible. Process Builder is being sunset.
