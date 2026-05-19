---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: api-reference
last-updated: 2026-05-11
---

# Experience Cloud — API Reference

## Network/Member SOQL Patterns

### Query Networks (All Sites)
```soql
SELECT Id, Name, Status, UrlPathPrefix
FROM Network
```

### Query Live Networks
```soql
SELECT Id, Name, Status, UrlPathPrefix
FROM Network
WHERE Status = 'Live'
```

### Query Members by Network
```soql
SELECT Id, MemberId, ReputationPoints, PreferencesDisableAllFeedsEmail
FROM NetworkMember
WHERE NetworkId = :networkId
```

### Query Active Members Count
```soql
SELECT COUNT(Id)
FROM NetworkMember
WHERE NetworkId = :networkId
```

### Query Members by Status — Disable Emails for Data Migration (PDF p.132)
```soql
SELECT Id, NetworkId, PreferencesDisableAllFeedsEmail
FROM NetworkMember
WHERE NetworkId = 'ENTER YOUR 18-DIGIT SITE ID HERE'
```
Set `PreferencesDisableAllFeedsEmail = TRUE` for all records during migration. Reset to FALSE after load.

### Query NetworkMemberGroups (Profiles/PermSets Granting Site Access)
```soql
SELECT Id, NetworkId, SubjectId, MembershipType
FROM NetworkMemberGroup
WHERE NetworkId = :networkId
```

## FeedItem / FeedComment SOQL Patterns

### Query All Posts in a Network
```soql
SELECT Id, Body, Type, Title, BestCommentId, CreatedDate, CreatedBy.Name, NetworkScope
FROM FeedItem
WHERE NetworkScope = :networkId
ORDER BY CreatedDate DESC
```

### Find Unanswered Questions (PDF p.131-135)
```soql
SELECT Id, Title, Body, CreatedDate, ParentId
FROM FeedItem
WHERE Type = 'QuestionPost'
  AND NetworkScope = :networkId
  AND BestCommentId = null
ORDER BY CreatedDate ASC
```

### Find Questions with Best Answers
```soql
SELECT Id, Title, Body, BestCommentId, CreatedDate
FROM FeedItem
WHERE Type = 'QuestionPost'
  AND NetworkScope = :networkId
  AND BestCommentId != null
```

### Query Comments on a Post
```soql
SELECT Id, CommentBody, CommentType, ThreadParentId, CreatedDate, CreatedBy.Name
FROM FeedComment
WHERE FeedItemId = :feedItemId
ORDER BY CreatedDate ASC
```

### Query Flagged Content (Moderation)
```soql
SELECT Id, Type, CreatedDate, NetworkId
FROM NetworkModeration
WHERE NetworkId = :networkId
ORDER BY CreatedDate DESC
```

### Query Moderation Activity
Using custom report type in Salesforce Reports (PDF p.792):
- Primary object: `Networks`
- Child objects for moderation reports:
  - `Network Audits` — all moderation activity and history
  - `Network Members > Network Activity Audit — Moderators` — members who flagged or moderated items
  - `Network Members > Network Activity Audit — User` — members whose items were flagged/blocked/replaced
  - `Network Members > Network Activity Audit — User Login` — frozen members
  - `Network Moderations > Feed Posts` — currently flagged posts
  - `Network Moderations > Feed Comments` — currently flagged comments
  - `Network Moderations > Content Documents` — currently flagged files
  - `Network Moderations > Private Messages` — currently flagged private messages

### Query Reputation (Leaderboard)
```soql
SELECT Id, MemberId, ReputationPoints
FROM NetworkMember
WHERE NetworkId = :networkId
  AND ReputationPoints > 0
ORDER BY ReputationPoints DESC
LIMIT 20
```

### Query User Activity (Daily Metrics)
Using report type `Networks > Network Activity Daily Metrics` for post/comment counts by member type.
Using `Networks > Network Membership Daily Metrics` for active members, new members, external logins.
Using `Networks > Network Unique Contributor Daily Metrics` for unique daily contributors.

## Apex Patterns — Core Experience Cloud Apex

### Get Current Network ID
```apex
Id networkId = Network.getNetworkId();
```

### Get Network URL
```apex
String baseUrl = Network.getLoginUrl(Network.getNetworkId());
```

### Get Site Base URL
```apex
String siteUrl = Site.getBaseUrl();
String masterLabel = Site.getMasterLabel();
```

### Get Current User Info
```apex
Id userId = UserInfo.getUserId();
String userType = UserInfo.getUserType(); // 'PowerPartner', 'CustomerSuccess', etc.
```

### Create Portal User (Synchronous) — Standard Registration
```apex
// Site.createPortalUser(user, accountId, password)
// Returns the new User ID
Contact c = new Contact(
    FirstName = 'John',
    LastName = 'Doe',
    Email = 'john.doe@example.com',
    AccountId = targetAccountId
);
insert c;

User u = new User(
    ContactId = c.Id,
    Username = 'john.doe@example.com.site',
    FirstName = 'John',
    LastName = 'Doe',
    Email = 'john.doe@example.com',
    Alias = 'jdoe',
    ProfileId = customerCommunityProfileId,
    TimeZoneSidKey = 'America/Los_Angeles',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US'
);

Id userId = Site.createPortalUser(u, targetAccountId, 'TempPass123!');
```

### Create External User Async — Micro-Batching (PDF p.516)
```apex
// For business account sites
User newUser = new User(
    FirstName = firstName,
    LastName = lastName,
    Email = emailAddress,
    Username = emailAddress + '.portal',
    Alias = lastName.left(8),
    ProfileId = communityProfileId,
    TimeZoneSidKey = 'America/New_York',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US'
);

Contact newContact = new Contact(
    FirstName = firstName,
    LastName = lastName
);

Account newAccount = new Account(
    Name = 'Account for ' + lastName
);

String uuid = Network.createExternalUserAsync(newUser, newContact, newAccount);
// uuid = temporary ID; use to track errors via Connect REST API
```

### Create Record Async — Micro-Batching (PDF p.517)
```apex
// processType must be 'GENERIC'
// Supported objects: Case, Lead, custom objects
Case myCase = new Case(
    Subject = 'New support request',
    Description = 'Case description'
);
String uuid = Network.createRecordAsync('GENERIC', myCase);

// With file attachments
String uuid2 = Network.createRecordAsync(
    'GENERIC',
    myCase,
    new List<Id>{ contentDocumentId1, contentDocumentId2 }
);
```

### Assign Recognition Badge via Apex (PDF p.777)
```apex
WorkThanks thanks = new WorkThanks(
    NetworkId = networkId,
    GiverID = giverId,
    Message = 'Thank you for your contribution!'
);
insert thanks;

WorkBadge badge = new WorkBadge(
    DefinitionId = badgeDefinitionId,
    NetworkID = networkId,
    RecipientId = recipientId,
    SourceId = thanks.id
);
insert badge;

// Optional: post to recipient's Chatter feed to notify
FeedItem fi = new FeedItem(
    NetworkScope = networkId,
    ParentId = recipientId,
    RelatedRecordId = thanks.id,
    Body = 'You received a badge!',
    Type = 'RypplePost',
    Visibility = 'AllUsers'
);
insert fi;
```

### Trigger: Award Badge When Reputation Threshold Reached (PDF p.778)
```apex
trigger NetworkMemberTrigger on NetworkMember (after update) {
    for (NetworkMember nm : Trigger.New) {
        User user = [SELECT Id, hasBadge__c FROM User WHERE Id = :nm.MemberId];
        if (nm.ReputationPoints >= 40 && !user.hasBadge__c) {
            WorkThanks thanks = new WorkThanks(
                GiverId = System.Label.BadgeGiverUserId, // store in Custom Label
                Message = 'Achievement unlocked',
                NetworkId = nm.NetworkId
            );
            insert thanks;
            WorkBadge badge = new WorkBadge(
                DefinitionId = System.Label.AchievementBadgeId,
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

### Trigger: Track Post Count for Badge (PDF p.778-779)
```apex
// ChatterActivity fields useful for badge assignment:
// CommentCount, CommentReceivedCount, LikeReceivedCount, PostCount

trigger ChatterActivityTrigger on ChatterActivity (after update) {
    for (ChatterActivity ca : Trigger.New) {
        if (ca.PostCount >= 10) {
            // Award badge if not already awarded to this user
        }
    }
}
```

### Apex Caching for LWR Sites (PDF p.532)
For public data from Apex methods used in LWR sites, use caching annotation:
```apex
@AuraEnabled(cacheable=true scope='global')
public static List<Knowledge__kav> getPublicArticles() {
    return [SELECT Id, Title, UrlName FROM Knowledge__kav WHERE PublishStatus = 'Online'];
}
```
Use `@wire` in LWC to invoke publicly cacheable Apex actions.

For managed package Apex caching: enabled by default; disable via Workspaces > Administration > Preferences > "Cache public data from Apex methods in Managed Packages."

## Connect REST API Key Endpoints

The full Connect REST API reference for Experience Cloud is in the Connect REST API Developer Guide. Key patterns confirmed in PDF:

### Get Micro-Batching Errors
```
GET /connect/communities/{communityId}/microbatching/errors
?processType=SELF_REGISTRATION
&earliestDate=2021-11-16T16:17:31.797Z
```
Also applies for `processType=GENERIC` for record creation errors.

### Additional Connect API Notes (PDF p.135-136)
- Chatter profile photos must be uploaded via Connect REST API (not Data Loader)
- Poll creation must be done via Connect REST API
- Translating reputation level images back to default: use Connect REST API
- Creating unique featured topics separate from navigational/member topics: use Connect REST API
- Loading posts and comments in custom format during migration: use Connect REST API

## Governor Limits and Operational Limits

### Site Count Limits
| Limit | Value |
|---|---|
| Maximum Experience Cloud sites per org | 100 |
| Active + Inactive + Preview sites count toward limit | Yes |
| Archived sites count toward limit | No |

### Moderation Limits (PDF p.750)
| Limit | Value |
|---|---|
| Keyword list criteria per org | 30 |
| Member criteria per org | 100 |
| Keyword criteria per content rule | 3 |
| Member criteria per content rule | 10 |
| Member criteria per rate rule | 10 |

### Topics Limits
| Limit | Value |
|---|---|
| Maximum featured topics | 25 |
| Dynamic redirect rules per org | 100 |

### Trusted Domain Limits
| Limit | Value |
|---|---|
| Trusted domains for inline framing — Experience Builder sites | 100 |
| Trusted domains for inline framing — Salesforce Tabs + Visualforce sites | 512 |

### File Size Limits
| Limit | Value |
|---|---|
| Maximum file download size | 2 GB |
| MaxFileSizeKb on Network | Configurable (example in sample XML: 51200 KB = 50 MB) |

### Dashboard Refresh Limits
| Limit | Value |
|---|---|
| Role-based external users — dashboard refreshes per org per day | 1,000 |
| Internal users — dashboard refresh limit | No limit |

### Reputation System
| Limit | Value |
|---|---|
| Minimum reputation levels | 3 |
| Maximum reputation levels | 50 |
| Default reputation levels | 10 |

### Partner Roles
| Limit | Value |
|---|---|
| Default partner roles per account | 3 (Partner User, Partner Manager, Partner Executive) |
| Recommended partner roles per account | 1 (Partner User) — reduce to avoid role proliferation |

### Performance Tool Capabilities
| Tool | Use Case | Framework |
|---|---|---|
| Salesforce CDN | Reduce page load times; required for image optimization, Apex caching | All |
| LWR framework | High-performance sites; natively fast component rendering | LWR |
| Apex Caching on CDN | Cache public Apex method data for guest users | LWR |
| Progressive Rendering | Prioritize above-fold component rendering | Aura |
| Page Optimizer | Identify component-level performance bottlenecks | Aura |
| Micro-batching (self-registration) | 2x throughput for concurrent registrations | All |
| Micro-batching (record creation) | Higher DML throughput for Cases/Leads/custom objects | All |
| Account Role Optimization (ARO) | Delay role creation to reduce role count overhead | All with role-based licenses |

### Page View / License Limits
Page views per license tier and API calls per license: Not found in extracted pages (pp. 126-135, 530-540, 807-815) — verify in Experience Cloud User Licenses documentation or with your Salesforce Account Executive.

The PDF mentions page view billing in context of performance planning (p.511) but specific numerical limits for Enterprise/Unlimited/Developer editions were not in the extracted sections. The 12-month look-back for overage calculation is referenced in the task brief but was not confirmed in the extracted pages.

## Report Object Reference (PDF p.792-793)

Key custom report types for Experience Cloud, using Networks as the primary object:

| Report Objective | Primary → Child Objects |
|---|---|
| Chatter private message activity | Networks → Chatter Messages |
| Post/comment editing history | Networks → Feed Revisions |
| Group activity | Networks → Groups |
| All moderation activity | Networks → Network Audits |
| Moderators and flagged items | Networks → Network Members → Network Activity Audit — Moderators |
| Members whose items were flagged | Networks → Network Members → Network Activity Audit — User |
| Frozen members | Networks → Network Members → User Login |
| Currently flagged posts | Networks → Network Moderations → Feed Posts |
| Currently flagged comments | Networks → Network Moderations → Feed Comments |
| Currently flagged files | Networks → Network Moderations → Content Documents |
| Currently flagged private messages | Networks → Network Moderations → Private Messages |
| Pending review posts | Networks → Unpublished Feed Entities → Feed Posts |
| Daily public page views + unique visitors | Networks → Network Public Usage Daily Metrics |
| Custom recommendation usage | Networks → Recommendation Metric |
| Topic activity | Networks → Topics |
| Topic assignment activity | Networks → Topic Assignments |
| Daily post/comment counts by member type | Networks → Network Activity Daily Metrics |
| Login activity | Networks → Network Members → Login History |
| Daily active/new members + logins | Networks → Network Membership Daily Metrics |
| Unique daily contributors | Networks → Network Unique Contributor Daily Metrics |
| Member profile photos | Networks → Network Members (filter: Has Profile Photo = True/False) |

**Critical note (PDF p.794):** Do NOT filter reports by Network ID. Filtering by Network ID fixes the data to a single site regardless of which site the report is viewed from. Without a Network ID filter, reports automatically show data for the site in which they are viewed — this is the desired behavior for community manager dashboards.
