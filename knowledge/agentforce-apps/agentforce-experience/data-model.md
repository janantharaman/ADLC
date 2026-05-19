---
source: Experience Cloud (communities.pdf, 818p); Spring '26; grounded 2026-05-11
cloud: Experience Cloud
section: data-model
last-updated: 2026-05-11
---

# Experience Cloud — Data Model

## Core Objects Table

| Object | API Name | Purpose | Framework | Notes |
|---|---|---|---|---|
| Network | `Network` | Represents a single Experience Cloud site | All | One Network per site; Status must be Live for external access |
| NetworkMember | `NetworkMember` | Tracks user membership, Chatter prefs, reputation points in a site | All | Created automatically on membership; stores PreferencesDisableAllFeedsEmail |
| NetworkMemberGroup | `NetworkMemberGroup` | Links Profile or Permission Set to a Network granting membership | All | Adding a Profile auto-creates NetworkMember for all profile users |
| Site | `Site` | Public-facing site configuration: domain, guest user, page settings | All | GuestUserId links to the Guest User record |
| FeedItem | `FeedItem` | A post or thread in the site/Chatter feed | All | Type field distinguishes QuestionPost, ContentPost, etc.; BestCommentId for best answer |
| FeedComment | `FeedComment` | A comment on a FeedItem | All | ThreadParentId for threaded conversations (3 levels max) |
| FeedLike | `FeedLike` | Tracks who liked a post or comment | All | FeedItemId for post likes; FeedEntityId for comment likes |
| FeedAttachment | `FeedAttachment` | Tracks file/link attachments on a FeedItem | All | Type: Content, InlineImage, Link, FeedEntity |
| FeedPollChoice | `FeedPollChoice` | Shows choices for a poll in the feed | All | — |
| FeedPollVote | `FeedPollVote` | Tracks how users voted on a poll | All | — |
| CollaborationGroup | `CollaborationGroup` | A group in the site | All | Types: Public, Private, Unlisted |
| CollaborationGroupMember | `CollaborationGroupMember` | A member of a CollaborationGroup | All | CollaborationRole: Standard or Admin |
| Topic | `Topic` | A topic (#hashtag) of conversation | All | NetworkId links to the specific site |
| TopicAssignment | `TopicAssignment` | Links a topic to a FeedItem or other entity | All | EntityId = FeedItem ID; TopicId = Topic ID |
| EntitySubscription | `EntitySubscription` | Tracks which records or users someone follows | All | ParentId = followed record; SubscriberId = follower |
| ContentDocument | `ContentDocument` | A file uploaded to the site | All | Child ContentVersion created on upload |
| ContentVersion | `ContentVersion` | Tracks file versioning | All | Child of ContentDocument |

## Network Object

**API name:** `Network`
**Purpose:** Represents the Experience Cloud site itself.

Key fields:
| Field | Type | Notes |
|---|---|---|
| `Name` | Text | Display name of the site |
| `UrlPathPrefix` | Text | Path segment appended to org domain (e.g., `customers`); treat as immutable after go-live |
| `Status` | Picklist | `Live`, `UnderConstruction`, `DownForMaintenance`; must be `Live` for external access |
| `AllowMembersToFlag` | Boolean | Enables content flagging by members |
| `CaseCommentEmailEnabled` | Boolean | Sends email on case comment |
| `EnableGuestChatter` | Boolean | Controls if guest users can post in Chatter |
| `EnableGuestFileAccess` | Boolean | Controls guest file access |
| `EnableNicknameDisplay` | Boolean | Shows nickname instead of full name |
| `EnableReputation` | Boolean | Enables reputation point system |
| `EnableDirectMessages` | Boolean | Allows secure private conversations in Customer Service template |
| `EnablePrivateMessages` | Boolean | Enables Chatter private messages |
| `MaxFileSizeKb` | Integer | Maximum upload file size in KB |
| `SelfRegistration` | Boolean | Allows self-registration on site |
| `SendWelcomeEmail` | Boolean | Sends welcome email to new members |
| `EmailSenderAddress` | Email | From address for system emails |
| `EmailSenderName` | Text | Display name for system emails |
| `networkMemberGroups` | Related | Profiles/Permission Sets with site access |
| `networkPageOverrides` | Related | Custom page settings for login, register, home, etc. |
| `picassoSite` | Text | Links to the Experience Builder site; must match in source and target during deployment |
| `WelcomeTemplate` | Reference | Email template for welcome emails |
| `ForgotPasswordTemplate` | Reference | Email template for password reset |
| `ChangePasswordTemplate` | Reference | Email template for password change |
| `LockoutTemplate` | Reference | Email template for account lockout |

**Querying Networks:**
```soql
SELECT Id, Name, Status, UrlPathPrefix FROM Network
```

**Cannot be deleted via API** — must be archived through the UI.

## NetworkMember Object

**API name:** `NetworkMember`
**Purpose:** Links an internal or external User to a Network; tracks preferences and reputation.

Key fields:
| Field | Type | Notes |
|---|---|---|
| `NetworkId` | Reference | The 18-digit Network (site) ID |
| `MemberId` | Reference | The User ID |
| `PreferencesDisableAllFeedsEmail` | Boolean | Disables all feed email notifications for this member in this site |
| `ReputationPoints` | Integer | The member's accumulated reputation points |

**Notes:**
- NetworkMember records are created automatically when a user is added to a community
- Cannot directly insert NetworkMember — use site membership UI or Profile-to-NetworkMemberGroup assignment
- To disable email notifications during data migration: set `PreferencesDisableAllFeedsEmail = TRUE` for all members, restore to FALSE after migration completes
- To migrate reputation points, update `ReputationPoints` field as the final step of migration

**Query pattern for disabling emails during data migration (PDF p.132):**
```soql
SELECT Id, NetworkId, PreferencesDisableAllFeedsEmail 
FROM NetworkMember 
WHERE NetworkId = 'ENTER YOUR 18-DIGIT SITE ID HERE'
```

**Query pattern for active member count:**
```soql
SELECT COUNT(Id) FROM NetworkMember WHERE NetworkId = :networkId
```

## FeedItem / FeedComment

Experience Cloud uses Chatter behind the scenes for peer-to-peer conversations. Each Chatter post is tied to the Experience Cloud site that it belongs to via `NetworkScope`. This prevents internal org conversations from being visible in external sites, and vice versa.

### FeedItem Fields
| Field | Notes |
|---|---|
| `Body` | Main content; only specific HTML tags supported; clean data before load |
| `Type` | `AdvancedTextPost` (announcements), `ContentPost` (with file), `QuestionPost` (question), `PollPost` (poll), `LinkPost` (URL) |
| `IsRichText` | True = HTML markup; False = plain text |
| `NetworkScope` | The 18-digit site ID — scopes the post to the site |
| `ParentId` | Group ID (if posted to a group) or User ID (if posted to a topic) |
| `Visibility` | `AllUsers` |
| `Title` | Used for `QuestionPost` type only — the question title |
| `BestCommentId` | ID of the FeedComment marked as best answer; set after FeedComments exist (cannot set during initial insert) |

### FeedComment Fields
| Field | Notes |
|---|---|
| `FeedItemId` | The parent post (FeedItem) |
| `CommentBody` | The comment text |
| `ThreadParentId` | Empty if first-level comment; set to parent FeedComment ID for nested replies (max 3 levels) |
| `CommentType` | `ContentComment` (with attachment) or `TextComment` |
| `RelatedRecordId` | ContentVersion ID for ContentComment type |

**Query pattern — find unanswered questions in a site:**
```soql
SELECT Id, Title, Body, CreatedDate, BestCommentId 
FROM FeedItem 
WHERE Type = 'QuestionPost' 
  AND NetworkScope = :networkId 
  AND BestCommentId = null 
  AND CreatedDate < :cutoffDate
```

**Query pattern — find flagged posts:**
```soql
SELECT Id, FeedPost.Body, FlaggedBy.Name, CreatedDate 
FROM NetworkModeration 
WHERE NetworkId = :networkId 
  AND Type = 'FeedPost'
```

## External User Objects

### User (External)
External users are linked to Experience Cloud through their User record.

| UserType | License |
|---|---|
| `PowerPartner` | Partner Community |
| `PowerCustomerSuccess` | Customer Community Plus |
| `CustomerSuccess` | Customer Community |
| `CspLitePortal` | External Identity |

Key relationships:
- External users must have a Contact record as their parent (`User.ContactId`)
- Contact must belong to an Account (`Contact.AccountId`)
- Internal users (employees) do NOT have a ContactId on their User record

### Contact (for portal access)
- Each external user must have an associated Contact (`User.ContactId`)
- For B2B: Contact must belong to a business Account
- For B2C person accounts: person account creates a hybrid Account+Contact record
- Enabling portal access creates the external User record via the "Enable Customer User" or "Enable Partner User" button on the Contact

## Object Relationships

```
Network ──► NetworkMemberGroup ──► Profile / PermissionSet
    │
    └──► NetworkMember ──► User (External or Internal)
                                │
                            Contact (required for external users)
                                │
                            Account (required for external users)

FeedItem ──► FeedComment (BestCommentId back to FeedComment)
    │         │
    │         └──► ContentVersion (for file attachments)
    │
    └──► TopicAssignment ──► Topic (NetworkId = site ID)

CollaborationGroup ──► CollaborationGroupMember ──► User
```

## Data Migration Load Order

When migrating peer-to-peer conversation data (PDF p.132-135), load objects in this order:

1. Accounts (ensure Account Owner has a role assigned)
2. Contacts (AccountId, FirstName, LastName required)
3. Users (ContactId for external users; ProfileId; LanguageLocaleKey; LocaleSidKey; TimeZoneSid; EmailEncodingKey)
4. CollaborationGroup (GroupName; OwnerId; CollaborationType: Public/Private/Unlisted)
5. CollaborationGroupMember (GroupId; CollaborationRole; MemberId)
6. Topics (Name; Description; NetworkId = 18-digit site ID)
7. ContentDocument (files — can leave ParentId blank)
8. FeedItem (Body; Type; IsRichText; NetworkScope; ParentId; Visibility; Title for QuestionPost)
9. FeedComment (FeedItemId; CommentBody; ThreadParentId; CommentType)
10. FeedLike (FeedItemId or FeedEntityId)
11. FeedAttachment (FeedEntityId; RecordId; Title; Type; Value for Link type)
12. TopicAssignment (EntityId; TopicId)
13. EntitySubscription (ParentId; SubscriberId; NetworkId)
14. NetworkMember — update reputation points and email preferences last

**Migration notes:**
- External IDs not available on most objects — keep success files for relationship tracking
- Threaded conversations max 3 levels deep; load in batches by level
- BestCommentId on FeedItem must be set after all FeedComments are loaded
- Profile photos and polls must be migrated via Connect REST API
- Disable email notifications (PreferencesDisableAllFeedsEmail) during load; re-enable after

## File Visibility and Sharing

| Who | What | Visibility |
|---|---|---|
| Site user | Files they own | Always visible |
| Site user | Files shared with them directly | Visible |
| Site user | Files shared to a site they're a member of | Visible |
| Site user | Files shared to a group they can access | Visible |
| Site user | Files in libraries they can access | Visible |
| Guest user | Files shared with records | Visible only if Customer Access toggle enabled on file |
| Guest user | Files shared to site | Requires "Give access to public API requests on Chatter" preference enabled |
| Guest user | File uploads | Requires "Allow site guest users to upload files" in Setup > Salesforce Files > General Settings |

**Library sharing note:** To share a library file to a group in a site, both the library file and the group must be in the same Experience Cloud site. Users with Manage Experiences permission can share library files across sites.

## Partner-Specific Objects

**PartnerFundAllocation, PartnerFundClaim, PartnerFundRequest:** Not found in extracted pages (pp. 126-145, 680-695) — verify separately in PRM documentation or Partner Management object reference.

## Key SOQL Patterns

### Query members by network
```soql
SELECT Id, MemberId, ReputationPoints, PreferencesDisableAllFeedsEmail
FROM NetworkMember
WHERE NetworkId = :networkId
```

### Query by status
```soql
SELECT Id, Name, Status FROM Network WHERE Status = 'Live'
```

### Query active members count
```soql
SELECT COUNT(Id) FROM NetworkMember 
WHERE NetworkId = :networkId
```

### Query posts in a network
```soql
SELECT Id, Body, Type, Title, BestCommentId, CreatedDate, CreatedBy.Name
FROM FeedItem
WHERE NetworkScope = :networkId
ORDER BY CreatedDate DESC
```

### Query unanswered questions
```soql
SELECT Id, Title, Body, CreatedDate
FROM FeedItem
WHERE Type = 'QuestionPost'
  AND NetworkScope = :networkId
  AND BestCommentId = null
```

### Query reputation (NetworkMember)
```soql
SELECT Id, MemberId, ReputationPoints
FROM NetworkMember
WHERE NetworkId = :networkId
  AND ReputationPoints > 0
ORDER BY ReputationPoints DESC
```
