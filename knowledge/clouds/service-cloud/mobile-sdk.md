---
source: Embedded Service SDK for iOS developer guide (developer.salesforce.com); Embedded Service SDK for Android developer guide (developer.salesforce.com); GitHub release notes forcedotcom/ServiceSDK-iOS (latest: 246.0.1); GitHub release notes forcedotcom/ServiceSDK-Android (latest: 224.2.7); Spring '26; grounded 2026-05-11
cloud: Service Cloud
section: mobile-sdk
last-updated: 2026-05-11
---

# Service Cloud — Mobile SDK (Embedded Service SDK for iOS and Android)

---

## What It Is

The **Embedded Service SDK** (formerly "Service Cloud Snap-ins") provides native iOS and Android libraries that embed Salesforce Service Cloud chat capabilities directly into a mobile app — no webview required. The SDK renders a native UI and connects to the same Omni-Channel routing infrastructure as web-based channels.

> **Critical status:** The SDK is in **maintenance mode** as of its final major release (October 2023). No new features are being added. The legacy Chat component it wraps is scheduled for **retirement February 14, 2026**. All new mobile chat implementations should use **Messaging for In-App** (separate SDK, separate documentation) instead.

---

## Component Lifecycle Status

| Component | iOS (retired/active) | Android (retired/active) | Notes |
|---|---|---|---|
| **Chat** | Active — maintenance mode | Active — maintenance mode | **Retires Feb 14, 2026**; use Messaging for In-App for new builds |
| **Knowledge** | **RETIRED** (Winter '23) | **RETIRED** (Winter '23) | iOS: was 3.5.8; Android: was 4.3.7 |
| **Case Management** | **RETIRED** (Winter '23) | **RETIRED** (Winter '23) | iOS: was 2.2.8; Android: was 4.2.8 |
| **SOS (video chat)** | **REMOVED** from SDK ≥ 234.0.0 (Sept 2021) | Never included | iOS ≤ 224.0.3 still has SOS; Classic only |

As of the current releases, **both SDKs contain only the Chat component**. The `com.salesforce.service:servicesdk` Maven artifact on Android is now equivalent to `com.salesforce.service:chat-ui`.

---

## iOS SDK

### Current Release
- **SDK version:** 246.0.1 (October 2023 patch)
- **Chat component:** 4.1.3
- **ServiceCore component:** 4.2.9
- **Minimum iOS version:** iOS 12
- **Minimum Xcode:** 12.3 (must use XCFramework files)
- **Repository:** github.com/forcedotcom/ServiceSDK-iOS
- **Reference docs:** forcedotcom.github.io/ServiceSDK-iOS/

### Installation

**CocoaPods (recommended):**
```ruby
# Podfile
pod 'ServiceChat'
```

**XCFramework (manual — required for Xcode 12.3+):**
1. Download from GitHub wiki (`Get the iOS SDK`)
2. Add `.xcframework` bundles to Xcode project
3. Run `prepare-framework` script before App Store submission to strip simulator architectures:
   ```
   $SRCROOT/ServiceCore.xcframework/ios-arm64_armv7/ServiceCore.framework/prepare-framework
   ```

### Key Classes

| Class / Protocol | Purpose |
|---|---|
| `SCSChatConfiguration` | Main configuration object for a chat session; holds org URL, org ID, deployment ID, button ID; has `termsAndCondition` (AttributedString) property for T&C checkbox on pre-chat form |
| `SCSPrechatEntity` | Defines a Salesforce object (Case, Contact) to create or update from the chat session; known issue: Case creation via `SCSPrechatEntity` does not work with Omni-Channel routing by default — requires org setup ticket |
| `SCSPrechatTextInputObject` | Pre-chat text field |
| `SCSPrechatPickerObject` | Pre-chat picker field |
| `SCSPrechatPickerOption` | Option within a picker field |
| `SCServiceCloud.chatUI` | Entry point to start a chat session; must be called on the main UI thread |
| `SOSAgentAvailabilityError` | Error enum for SOS agent availability checks; error 3003 = REST API error (check credentials/pod URL) |

### Org-Side Setup Sequence (iOS Chat)

```
1. Setup → Chat Settings → Enable Chat (Lightning Experience)
2. Create Chat Button (Setup → Chat Buttons & Invitations)
   → Note: Button ID, Deployment ID, Org ID, Pod URL — needed in SCSChatConfiguration
3. Create Routing Configuration and assign Queue
4. Assign 'Live Agent' permission set to agents
5. Add Chat component to Service Console
6. In mobile app:
   a. Configure SCSChatConfiguration with org credentials
   b. Add pre-chat fields (SCSPrechatTextInputObject / SCSPrechatPickerObject)
   c. Optionally add SCSPrechatEntity for Case/Contact creation
   d. Call SCServiceCloud.chatUI to launch the chat UI
```

### Known Issues (iOS)

- `SCSPrechatEntity` Case creation fails with Omni-Channel routing without an org config change — Contact creation works fine; Live Agent routing works for both
- VoiceOver: some elements in the chat feed are not read aloud when dragging with VoiceOver active
- `View controller-based status bar appearance` plist key set to `YES` has no effect in the SDK

---

## Android SDK

### Current Release
- **SDK version:** 224.2.7 (April 2024 patch)
- **Chat component:** 4.3.6
- **ServiceCommon component:** 8.0.6
- **Repository:** github.com/forcedotcom/ServiceSDK-Android
- **Reference docs:** forcedotcom.github.io/ServiceSDK-Android/

### Installation

**Gradle (Maven):**
```groovy
// build.gradle (app)
dependencies {
    implementation 'com.salesforce.service:chat-ui:<version>'
    // Note: com.salesforce.service:servicesdk is now equivalent to chat-ui
}
```

The SDK registers a **foreground service** to maintain the chat communication channel while a session is active (required for Android API 34+). Declare `FOREGROUND_SERVICE` permission in your `AndroidManifest.xml`.

### Key Classes

| Class | Purpose |
|---|---|
| `ChatUIConfiguration` | Top-level configuration for the chat UI |
| `ChatUIConfiguration.Builder` | Builder pattern to construct `ChatUIConfiguration`; key method: `defaultToMinimized(boolean)` — **set to `true`** (default) to avoid agent-transfer UI bug |
| `ChatConfiguration` | Core chat session configuration (org URL, org ID, deployment ID, button ID) |
| `ChatEntity` | Defines a Salesforce object (Case, Contact) to create or update from the chat; same Omni-Channel routing issue as iOS `SCSPrechatEntity` |
| `SessionStateListener` | Callback interface for chat session state changes |
| `ChatEndReason` | Enum for how a chat ended; `ChatEndReason.NetworkError` typically means incorrect button ID |

### Known Issues (Android)

- `defaultToMinimized(false)`: when user is transferred to another agent, chat feed hides behind queue UI — **always use `defaultToMinimized(true)`**
- `ChatEndReason.NetworkError` on session start: verify button ID in `ChatConfiguration`
- `ChatEntity` Case creation fails with Omni-Channel routing (same as iOS) — Contact works fine
- **Android API 35**: Edge-to-edge enforcement breaks the Chat UI. Workaround: add `res/values-v35/styles.xml` to override `SalesforceTheme` with `android:windowOptOutEdgeToEdgeEnforcement = true` (see below). This workaround will NOT work on Android API 36+.
- **Android API 36+**: No supported workaround — must migrate to Messaging for In-App before targeting API 36

**Android API 35 edge-to-edge workaround:**
```xml
<!-- res/values-v35/styles.xml -->
<resources>
    <style name="SalesforceTheme" parent="Base.SalesforceTheme">
        <item name="sc_dialogTitleStyle">@style/ServiceChatText.DialogTitle</item>
        <item name="sc_dialogMessageStyle">@style/ServiceChatText.DialogMessage</item>
        <item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>
    </style>
</resources>
```

---

## Replacement: Messaging for In-App (and Web)

The recommended replacement for the legacy Chat SDK on both iOS and Android is **Messaging for In-App**, which is a separate SDK with separate documentation.

| Dimension | Legacy Chat SDK | Messaging for In-App |
|---|---|---|
| Channel object created | `LiveChatTranscript` | `MessagingSession` |
| Conversation type | Synchronous only | Synchronous + **asynchronous** (conversations persist; can be picked up later) |
| Bot support | Einstein Bots | Agentforce Service Agent |
| Status | Maintenance mode; retiring Feb 14, 2026 | GA; actively developed |
| Android API 36 | Incompatible | Supported (edge-to-edge out of the box) |
| iOS SDK package | `ServiceChat` (CocoaPods) | Separate Messaging for In-App SDK |
| Android Maven | `com.salesforce.service:chat-ui` | Separate Messaging for In-App SDK |
| Documentation | developer.salesforce.com/docs/atlas.en-us.service_sdk_ios/android | developer.salesforce.com/docs/service/messaging-in-app/overview |

### Migration Steps

1. Provision **Digital Engagement** add-on (required for Messaging for In-App)
2. Set up **Messaging for In-App and Web** channel in Setup → Messaging Settings
3. Replace `ServiceChat`/`chat-ui` SDK dependency with the Messaging for In-App SDK
4. Replace `LiveChatButton` deployment ID → `MessagingChannel` configuration
5. Replace `SCSPrechatEntity`/`ChatEntity` → Messaging for In-App pre-conversation data model
6. Replace `SessionStateListener`/chat callbacks → Messaging SDK delegate/listener pattern
7. Update org-side agent permissions: replace `Live Agent` → `Messaging Agent` permission set
8. Test end-to-end: customer initiates from mobile → Omni-Channel routes → agent accepts in console

---

## SOS Video Chat (Legacy — iOS Classic Only)

SOS (video chat + screen-sharing for mobile) was **removed from the iOS SDK at version 234.0.0** (September 2021). SOS was never included in the Android SDK.

- To use SOS: install iOS SDK **≤ 224.0.3** only
- SOS is part of Service Cloud Snap-ins for Mobile Apps
- Requires separate **SOS license** (additional cost on Enterprise/Performance/Unlimited/Developer)
- **Salesforce Classic only** — does not work in Lightning Experience
- For new video/screen-sharing requirements: use a third-party ISV solution or Service Cloud Voice with a partner supporting video

---

## Decision Guide: Which Mobile Chat SDK?

```
Is the customer already using the legacy Chat SDK?
  YES → Plan migration to Messaging for In-App before Feb 14, 2026
  NO  → Do NOT implement legacy Chat SDK; use Messaging for In-App

Is the customer targeting Android API 36?
  YES → Must use Messaging for In-App (Chat SDK incompatible)

Does the customer need asynchronous conversations
(customer can leave and resume later)?
  YES → Messaging for In-App only

Does the customer need Knowledge browsing in-app?
  YES → Build custom using Knowledge SOQL/REST API;
        Knowledge SDK component is retired on both platforms

Does the customer need in-app case submission?
  YES → Build custom using Cases REST API;
        Case Management SDK component is retired on both platforms
```
