# Session Security Patterns (Well-Architected Framework)

**Source**: architect.salesforce.com → Trusted → Secure → Session Security

**Hierarchy**: Well-Architected → Trusted → Secure → Session Security

---

## Overview

Session security patterns ensure that user sessions are secure, properly managed, and protected against unauthorized access. These patterns are part of the **TRUSTED** pillar of the Well-Architected Framework.

---

## Pattern 1: Device Access Pattern

**Category**: Trusted → Secure → Session Security → Device Access

**Purpose**: Control and secure access from different device types (desktop, mobile, tablets)

### Implementation Checklist

| Where to look? | What does good look like? |
|----------------|---------------------------|
| **Platform \| Documentation** | ✅ Security personas are clearly mapped to appropriate device usages and policies |
| **Platform \| Documentation** | ✅ Device policies are clear and discoverable |
| **Platform \| Org** | ✅ Salesforce mobile connected app configuration requires PIN/passcode unlock after inactivity |
| **Platform \| Org** | ✅ If business needs require strict control of users who can access Salesforce mobile, API Access Control is enabled and permission sets are assigned to all users of Salesforce mobile apps |

### Configuration Steps

#### 1. Map Security Personas to Device Policies

**Setup → Security → Session Settings**

```
Security Persona Examples:
┌────────────────────────┬──────────────────┬──────────────────────┐
│ Persona                │ Device Access    │ Policy               │
├────────────────────────┼──────────────────┼──────────────────────┤
│ Internal Sales Rep     │ Desktop + Mobile │ MFA on login         │
│ External Partner       │ Desktop only     │ MFA + IP restriction │
│ Call Center Agent      │ Desktop only     │ Login hours restrict │
│ Field Service Tech     │ Mobile only      │ MFA + Device trust   │
│ Executive              │ All devices      │ MFA + High security  │
└────────────────────────┴──────────────────┴──────────────────────┘
```

**Implementation**:
```
1. Identify all user personas (sales, service, partners, etc.)
2. Document device needs per persona
3. Create Connected App policies per persona
4. Assign policies via Permission Sets
5. Document policies in internal wiki
```

#### 2. Configure Salesforce Mobile Security

**Setup → Connected Apps → Salesforce Mobile**

**Mobile Session Security**:
```
✅ Require PIN/Passcode after inactivity
   - Setting: "Screen Lock" = Enabled
   - Inactivity Timeout: 5 minutes (adjustable)
   - Minimum PIN Length: 6 digits

✅ Enable Mobile Device Management (MDM)
   - Integrate with Intune/MobileIron/AirWatch
   - Enforce device encryption
   - Remote wipe capability

✅ Mobile App Security Policies
   - Prevent screenshots in app
   - Disable clipboard (copy/paste sensitive data)
   - Require biometric authentication
```

**Setup Example**:
```
Setup → Mobile Apps → Salesforce Mobile App
  ├─ Session Security
  │   ├─ Screen Lock: Enabled
  │   ├─ Timeout: 5 minutes
  │   └─ PIN Length: 6 digits
  │
  ├─ App Security
  │   ├─ Prevent Screenshots: Enabled
  │   ├─ Clipboard: Disabled for sensitive fields
  │   └─ Biometric: Enabled
  │
  └─ MDM Integration
      ├─ Provider: Microsoft Intune
      ├─ Device Encryption: Required
      └─ Remote Wipe: Enabled
```

#### 3. API Access Control for Mobile

**Setup → Permission Sets → Mobile Access**

**When to use**:
- Strict control needed over mobile users
- Compliance requirements (HIPAA, SOX)
- High-security environments
- Partner/external user access

**Implementation**:
```apex
// API Access Control requires permission set assignment

// Step 1: Enable API Access Control
Setup → Session Settings → API Access Control = Enabled

// Step 2: Create permission set for mobile access
Permission Set: Salesforce Mobile Access
  ├─ API Enabled: ✅
  ├─ Salesforce Mobile App Access: ✅
  └─ Object Permissions: (as needed)

// Step 3: Assign to mobile users
Assign "Salesforce Mobile Access" permission set to all users who need mobile access
```

**Verification**:
```
Test Plan:
1. User with permission set → Can access mobile app
2. User without permission set → Cannot access mobile app
3. Desktop access → Still works (not affected)
4. API calls from mobile → Logged and auditable
```

---

## Pattern 2: Session Management Pattern

**Category**: Trusted → Secure → Session Security → Session Management

**Hierarchy**: Well-Architected → Trusted → Secure → Session Security → Session Management

**Purpose**: Properly manage session security, elevated permissions, and custom authentication flows

### Implementation Checklist

| Where to look?<br>Product Area \| Location | What does good look like?<br>Pattern |
|---------------------------------------------|--------------------------------------|
| **Platform \| Apex** | ✅ If custom login flows exist, all related custom code uses appropriate SessionManagement methods to assign session-level security |
| **Platform \| Aura** | ✅ If custom login flows exist, use an Apex controller with the necessary `SessionManagement` methods to assign session-level security |
| **Platform \| Lightning Web Components (LWC)** | ✅ If custom login flows exist, use an Apex controller with the necessary `SessionManagement` methods to assign session-level security |
| **Platform \| Design Standards** | ✅ Security personas clearly list approved session types and timeout/duration settings for each persona |
| **Platform \| Design Standards** | ✅ Standards are defined for the activities that require elevated session-level security |
| **Platform \| Design Standards** | ✅ Standards are defined for the activities that require elevated permissions to be assigned |
| **Platform \| Design Standards** | ✅ Connected app scope and token management policies are clear and discoverable |
| **Platform \| Documentation** | ✅ Connected app scope and token management policies are clear and discoverable |
| **Platform \| Documentation** | ✅ Login hours have been specified (or identified as not needed) |

### Custom Login Flow Session Management

**When Custom Login Flows Exist**:

#### Apex Implementation
```apex
/**
 * Custom login flow controller
 * IMPORTANT: Must use Auth.SessionManagement for session security
 */
public class CustomLoginController {

    /**
     * Custom authentication logic
     * Sets appropriate session-level security
     */
    public static String authenticateUser(String username, String password) {
        // Custom authentication logic
        User authenticatedUser = validateCredentials(username, password);

        if (authenticatedUser != null) {
            // ✅ REQUIRED: Use SessionManagement to set session security
            Auth.SessionManagement.setSessionLevel(
                Auth.SessionLevel.HIGH
            );

            // Set session timeout based on user persona
            Auth.SessionManagement.setSessionTimeout(
                getSessionTimeoutForUser(authenticatedUser)
            );

            // Generate session
            String sessionId = Auth.SessionManagement.generateVerificationUrl(
                Auth.VerificationPolicy.SMS,
                authenticatedUser.Id
            );

            return sessionId;
        }

        return null;
    }

    /**
     * Get session timeout based on user persona
     */
    private static Integer getSessionTimeoutForUser(User user) {
        // Map personas to timeout values
        Map<String, Integer> timeoutByPersona = new Map<String, Integer>{
            'System Administrator' => 30,    // 30 minutes
            'Internal User' => 120,          // 2 hours
            'External User' => 15,           // 15 minutes
            'Partner User' => 60             // 1 hour
        };

        String persona = getUserPersona(user);
        return timeoutByPersona.get(persona);
    }
}
```

#### Aura Component Implementation
```javascript
// CustomLoginAura.cmp
<aura:component controller="CustomLoginController">
    <aura:attribute name="username" type="String"/>
    <aura:attribute name="password" type="String"/>

    <lightning:input label="Username" value="{!v.username}"/>
    <lightning:input label="Password" type="password" value="{!v.password}"/>
    <lightning:button label="Login" onclick="{!c.handleLogin}"/>
</aura:component>

// CustomLoginAuraController.js
({
    handleLogin: function(component, event, helper) {
        var action = component.get("c.authenticateUser");
        action.setParams({
            username: component.get("v.username"),
            password: component.get("v.password")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var sessionId = response.getReturnValue();
                // ✅ Session security set by Apex controller
                window.location.href = '/home';
            } else {
                // Handle error
            }
        });

        $A.enqueueAction(action);
    }
})
```

#### LWC Implementation
```javascript
// customLogin.js
import { LightningElement, track } from 'lwc';
import authenticateUser from '@salesforce/apex/CustomLoginController.authenticateUser';

export default class CustomLogin extends LightningElement {
    @track username = '';
    @track password = '';

    handleUsernameChange(event) {
        this.username = event.target.value;
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
    }

    async handleLogin() {
        try {
            // ✅ Apex controller handles SessionManagement
            const sessionId = await authenticateUser({
                username: this.username,
                password: this.password
            });

            if (sessionId) {
                // Session security set by Apex
                window.location.href = '/home';
            }
        } catch (error) {
            // Handle error
            console.error('Login failed:', error);
        }
    }
}
```

```html
<!-- customLogin.html -->
<template>
    <lightning-card title="Custom Login">
        <div class="slds-p-around_medium">
            <lightning-input
                label="Username"
                value={username}
                onchange={handleUsernameChange}>
            </lightning-input>

            <lightning-input
                label="Password"
                type="password"
                value={password}
                onchange={handlePasswordChange}>
            </lightning-input>

            <lightning-button
                label="Login"
                onclick={handleLogin}>
            </lightning-button>
        </div>
    </lightning-card>
</template>
```

### Security Persona Session Standards

**Document session policies per persona**:

```
Security Persona: System Administrator
├─ Approved Session Types:
│   ├─ UI Session: HIGH security
│   ├─ API Session: HIGH security
│   └─ Mobile Session: Not permitted
├─ Timeout/Duration:
│   ├─ Idle Timeout: 30 minutes
│   ├─ Absolute Timeout: 4 hours
│   └─ Re-authentication: Required after 2 hours
├─ Elevated Security Required:
│   ├─ User management operations
│   ├─ Permission set assignments
│   ├─ Metadata deployments
│   └─ Security settings changes
└─ Elevated Permissions:
    ├─ Modify All Data
    ├─ View Setup and Configuration
    └─ Customize Application

Security Persona: Internal Sales User
├─ Approved Session Types:
│   ├─ UI Session: STANDARD security
│   ├─ API Session: STANDARD security
│   └─ Mobile Session: Permitted (MFA required)
├─ Timeout/Duration:
│   ├─ Idle Timeout: 2 hours
│   ├─ Absolute Timeout: 8 hours
│   └─ Re-authentication: Not required
├─ Elevated Security Required:
│   ├─ Opportunity deletion
│   ├─ Bulk data export
│   └─ Report scheduling
└─ Elevated Permissions:
    ├─ Edit Opportunities (>$1M)
    ├─ Approve Discounts (>20%)
    └─ Transfer Account Ownership

Security Persona: External Partner User
├─ Approved Session Types:
│   ├─ UI Session: STANDARD security
│   ├─ API Session: Not permitted
│   └─ Mobile Session: Not permitted
├─ Timeout/Duration:
│   ├─ Idle Timeout: 15 minutes
│   ├─ Absolute Timeout: 1 hour
│   └─ Re-authentication: Required every hour
├─ Elevated Security Required:
│   ├─ Partner portal data access
│   ├─ Lead creation
│   └─ Case submission
└─ Elevated Permissions:
    ├─ View Partner Leads only
    ├─ Create Cases
    └─ View Knowledge Base
```

### Elevated Session-Level Security

**Activities requiring HIGH session security**:

```apex
public class ElevatedSecurityController {

    /**
     * Require HIGH session level for sensitive operations
     */
    @AuraEnabled
    public static void deleteHighValueOpportunity(Id opportunityId) {
        // Check current session level
        if (Auth.SessionManagement.getCurrentSession().getLevel() !=
            Auth.SessionLevel.HIGH) {
            // Prompt for step-up authentication
            throw new AuraHandledException(
                'This operation requires elevated security. Please verify your identity.'
            );
        }

        // Proceed with deletion
        delete [SELECT Id FROM Opportunity WHERE Id = :opportunityId];
    }

    /**
     * Step-up authentication for elevated access
     */
    @AuraEnabled
    public static String requestElevatedAccess() {
        // Generate verification URL for SMS/Email
        String verificationUrl = Auth.SessionManagement.generateVerificationUrl(
            Auth.VerificationPolicy.EMAIL_AND_SMS,
            UserInfo.getUserId()
        );

        return verificationUrl;
    }

    /**
     * Verify elevated access and upgrade session
     */
    @AuraEnabled
    public static Boolean verifyElevatedAccess(String verificationCode) {
        Boolean verified = Auth.SessionManagement.validateTwoFactorCode(
            verificationCode
        );

        if (verified) {
            // Upgrade session to HIGH security
            Auth.SessionManagement.setSessionLevel(Auth.SessionLevel.HIGH);
        }

        return verified;
    }
}
```

**Standard Activities Requiring Elevated Security**:
```
User Management:
✓ Create/modify users
✓ Assign permission sets with "Modify All Data"
✓ Change user roles
✓ Reset passwords for privileged users

Data Management:
✓ Bulk delete operations (>100 records)
✓ Mass data export
✓ Data loader operations
✓ Backup/restore operations

Configuration:
✓ Metadata deployments to production
✓ Permission set modifications
✓ Sharing rule changes
✓ Security settings updates

Financial:
✓ Opportunity deletion (>$100K)
✓ Invoice modifications
✓ Payment processing
✓ Discount approvals (>20%)
```

### Connected App Scope & Token Management

**Document connected app policies**:

```
Connected App: Salesforce Mobile App
├─ OAuth Scopes:
│   ├─ api (Access and manage data)
│   ├─ refresh_token (Maintain access)
│   ├─ offline_access (Offline access)
│   └─ openid (OpenID Connect)
├─ Token Policies:
│   ├─ Access Token Lifetime: 15 minutes
│   ├─ Refresh Token Lifetime: 90 days
│   ├─ Token Rotation: Enabled
│   └─ Token Revocation: On password change
├─ Security Controls:
│   ├─ IP Relaxation: Not permitted
│   ├─ MFA Required: Yes
│   ├─ Session Security: STANDARD
│   └─ Permitted Users: All internal users
└─ Discovery:
    ├─ Documentation: Internal wiki
    ├─ Policy Owner: IT Security
    └─ Review Frequency: Quarterly

Connected App: Partner Portal API
├─ OAuth Scopes:
│   ├─ api (Access data)
│   └─ refresh_token (Maintain access)
├─ Token Policies:
│   ├─ Access Token Lifetime: 5 minutes
│   ├─ Refresh Token Lifetime: 30 days
│   ├─ Token Rotation: Enabled
│   └─ Token Revocation: On deactivation
├─ Security Controls:
│   ├─ IP Relaxation: Partner IPs only
│   ├─ MFA Required: Yes
│   ├─ Session Security: HIGH
│   └─ Permitted Users: Partner users only
└─ Discovery:
    ├─ Documentation: Partner portal docs
    ├─ Policy Owner: Partner Success
    └─ Review Frequency: Monthly
```

**Token Management Best Practices**:
```apex
public class TokenManagement {

    /**
     * Revoke all tokens for user on security event
     */
    public static void revokeUserTokens(Id userId) {
        // Revoke OAuth tokens
        List<OAuth2.Token> tokens = [
            SELECT Id FROM OAuth2.Token
            WHERE UserId = :userId
        ];

        for (OAuth2.Token token : tokens) {
            OAuth2.revokeToken(token.Id);
        }

        // Terminate all sessions
        Auth.SessionManagement.invalidateAllSessions(userId);
    }

    /**
     * Rotate refresh tokens periodically
     */
    public static void rotateRefreshTokens() {
        // Get tokens older than 30 days
        Date rotationDate = Date.today().addDays(-30);

        List<OAuth2.Token> oldTokens = [
            SELECT Id, UserId
            FROM OAuth2.Token
            WHERE CreatedDate < :rotationDate
            AND Type = 'RefreshToken'
        ];

        for (OAuth2.Token token : oldTokens) {
            // Generate new token
            String newToken = OAuth2.generateToken(token.UserId);

            // Revoke old token
            OAuth2.revokeToken(token.Id);
        }
    }
}
```

### Login Hours Configuration

**Document login hours policy**:

```
Organization Default: No restrictions (24/7 access)

User Profile: System Administrator
├─ Login Hours: Not restricted (24/7)
├─ Rationale: Emergency access required
└─ Override: Not permitted

User Profile: Internal User
├─ Login Hours: Monday-Friday, 6 AM - 8 PM PST
├─ Rationale: Standard business hours + buffer
├─ Override: Available via IT ticket
└─ Exception Process:
    ├─ Submit ticket with business justification
    ├─ Manager approval required
    └─ Temporary (24-48 hours)

User Profile: External Partner
├─ Login Hours: Monday-Friday, 8 AM - 6 PM PST
├─ Rationale: Support hours alignment
├─ Override: Not permitted
└─ Alternative: Submit case for after-hours requests

User Profile: Contractor
├─ Login Hours: Per project schedule
├─ Rationale: Limited engagement period
├─ Override: Not permitted
└─ Review: Weekly access review
```

**Configuration**:
```
Setup → Profiles → [Profile] → Login Hours

Example: Internal User Profile
Monday:    6:00 AM - 8:00 PM
Tuesday:   6:00 AM - 8:00 PM
Wednesday: 6:00 AM - 8:00 PM
Thursday:  6:00 AM - 8:00 PM
Friday:    6:00 AM - 8:00 PM
Saturday:  No access
Sunday:    No access
```

---

## Pattern 3: Session Timeout Pattern

**Category**: Trusted → Secure → Session Security → Session Timeout

**Purpose**: Automatically terminate inactive sessions to prevent unauthorized access

### Implementation Checklist

| Where to look? | What does good look like? |
|----------------|---------------------------|
| **Platform \| Session Settings** | ✅ Session timeout is configured based on security requirements |
| **Platform \| Session Settings** | ✅ Timeout values are different for internal vs external users |
| **Platform \| Profiles** | ✅ High-privilege users have shorter timeout periods |
| **Platform \| Documentation** | ✅ Session timeout policy is documented and communicated |

### Configuration

**Setup → Session Settings**

```
Session Timeout Configuration:
┌─────────────────────┬──────────────┬─────────────────────┐
│ User Type           │ Timeout      │ Rationale           │
├─────────────────────┼──────────────┼─────────────────────┤
│ System Admin        │ 30 minutes   │ High privileges     │
│ Internal Users      │ 2 hours      │ Standard security   │
│ External Users      │ 15 minutes   │ Lower trust         │
│ Partner Users       │ 1 hour       │ Limited scope       │
│ API Integration     │ No timeout   │ Refresh token used  │
└─────────────────────┴──────────────┴─────────────────────┘
```

**Implementation**:
```
1. Profile-based session timeout
   - Setup → Profiles → [Profile Name] → Session Settings
   - Set "Timeout value" based on user type

2. Organization-wide default
   - Setup → Session Settings → Session Timeout
   - Default: 2 hours (120 minutes)

3. Idle session timeout
   - Setup → Session Settings → Disable session timeout warning popup
   - Force logout on timeout (no warning)

4. Remember Me option
   - Setup → Session Settings → Enable "Remember Me"
   - Only for low-risk environments
```

**Code to check session**:
```apex
// Check if session is about to expire
public class SessionMonitor {
    public static Boolean isSessionNearExpiry() {
        // Get session info
        Long sessionSeconds = UserInfo.getSessionId() != null ?
            System.now().getTime() / 1000 : 0;

        // Warn if < 5 minutes remaining
        Long timeoutSeconds = 7200; // 2 hours default
        Long remainingSeconds = timeoutSeconds - sessionSeconds;

        return remainingSeconds < 300; // Less than 5 minutes
    }
}
```

---

## Pattern 3: Multi-Factor Authentication (MFA) Pattern

**Category**: Trusted → Secure → Session Security → MFA

**Purpose**: Add second factor of authentication to verify user identity

### Implementation Checklist

| Where to look? | What does good look like? |
|----------------|---------------------------|
| **Platform \| Identity** | ✅ MFA is required for all users accessing Salesforce |
| **Platform \| Identity** | ✅ MFA policies are enforced at login, not optional |
| **Platform \| Identity** | ✅ Multiple MFA methods are available (Authenticator app, Security Key, SMS) |
| **Platform \| Session Settings** | ✅ MFA required for API access and integrations |
| **Platform \| Reports** | ✅ MFA adoption is tracked and monitored |

### Configuration

**Setup → Identity → Multi-Factor Authentication**

**MFA Policy Levels**:
```
Level 1 - Basic (Minimum):
  ✅ MFA required for all UI logins
  ✅ Salesforce Authenticator app enabled
  ⚠️ SMS backup (less secure, but better than nothing)

Level 2 - Standard (Recommended):
  ✅ MFA required for all UI logins
  ✅ MFA required for API access (OAuth)
  ✅ Salesforce Authenticator app (primary)
  ✅ Security Keys (FIDO2/WebAuthn) allowed
  ⚠️ SMS disabled (vulnerable to SIM swapping)

Level 3 - High Security (Regulated industries):
  ✅ MFA required for all access (UI + API)
  ✅ Hardware security keys required (YubiKey, etc.)
  ✅ Phishing-resistant MFA only
  ✅ MFA re-verification for sensitive actions
  ❌ SMS/Email codes disabled
```

**Implementation Steps**:
```
1. Enable MFA for Organization
   Setup → Identity → Multi-Factor Authentication for User Interface Logins
   ├─ Effective Date: [Set rollout date]
   ├─ MFA Method: Salesforce Authenticator (required)
   └─ Backup Methods: Security Key (optional)

2. Configure MFA Policy
   Setup → Session Settings → Multi-Factor Authentication
   ├─ Require MFA for High Assurance Sessions: ✅
   ├─ Require MFA for API Logins: ✅
   └─ Prompt for MFA on every login: ✅

3. Enable Identity Verification
   Setup → Identity → Identity Verification
   └─ Require identity verification when MFA device is lost

4. Monitor Adoption
   Setup → Identity Verification History
   └─ Track MFA registration and usage
```

**User Enrollment Process**:
```
Step 1: User receives notification
  └─ Email: "MFA Required by [Date]"

Step 2: User downloads Salesforce Authenticator
  └─ iOS App Store / Google Play

Step 3: User registers device
  └─ Login → Prompted to scan QR code

Step 4: User verifies device
  └─ Enter code from Authenticator app

Step 5: User sets up backup method
  └─ Security Key or backup codes
```

**Exception Handling**:
```apex
// MFA verification in Apex
public class MFAHandler {
    public static Boolean isMFAVerified() {
        // Check if current session used MFA
        return Auth.SessionManagement.getCurrentSession()
            .get('MfaType') != null;
    }

    public static void requireMFA() {
        if (!isMFAVerified()) {
            throw new SecurityException('MFA verification required');
        }
    }
}

// Usage in sensitive operations
public class AccountService {
    public static void deleteAccount(Id accountId) {
        // Require MFA for sensitive operation
        MFAHandler.requireMFA();

        // Proceed with deletion
        delete [SELECT Id FROM Account WHERE Id = :accountId];
    }
}
```

---

## Pattern 4: IP Restrictions Pattern

**Category**: Trusted → Secure → Session Security → IP Restrictions

**Purpose**: Limit access to trusted network locations

### Implementation Checklist

| Where to look? | What does good look like? |
|----------------|---------------------------|
| **Platform \| Profiles** | ✅ IP restrictions defined for all non-mobile users |
| **Platform \| Network Access** | ✅ Trusted IP ranges are documented and current |
| **Platform \| Login History** | ✅ Failed login attempts from untrusted IPs are monitored |
| **Platform \| Transaction Security** | ✅ Alerts configured for login from new IP addresses |

### Configuration

**Setup → Profiles → [Profile] → Login IP Ranges**

```
IP Restriction Strategy:
┌─────────────────────┬──────────────────────────┬──────────────────┐
│ User Type           │ IP Restriction           │ Enforcement      │
├─────────────────────┼──────────────────────────┼──────────────────┤
│ System Admin        │ Corporate network only   │ Enforced         │
│ Internal Users      │ Corporate + VPN          │ Enforced         │
│ Remote Workers      │ VPN required             │ Enforced         │
│ External Partners   │ Partner network only     │ Enforced         │
│ Mobile Users        │ No restriction (use MFA) │ Not applicable   │
│ API Integrations    │ Server IP ranges         │ Enforced         │
└─────────────────────┴──────────────────────────┴──────────────────┘
```

**Implementation**:
```
1. Document all trusted IP ranges
   - Corporate offices (HQ, branches)
   - VPN endpoint IPs
   - Partner networks
   - Integration server IPs

2. Configure per profile
   Profile: System Administrator
     Login IP Ranges:
       ├─ 192.168.1.0 - 192.168.1.255 (HQ Office)
       ├─ 10.0.0.0 - 10.0.0.255 (Branch Office)
       └─ 203.0.113.10 - 203.0.113.20 (VPN)

3. Organization-wide trusted IPs
   Setup → Network Access
     Trusted IP Ranges:
       └─ Add ranges for all locations

4. Monitor violations
   Setup → Login History
     Filter: "Status = Invalid IP"
     Alert: Send email on failed attempts
```

**Exception Handling**:
```
Scenario: User traveling or working from home

Option 1: VPN Required
  └─ User connects to corporate VPN first
  └─ Then accesses Salesforce

Option 2: Temporary IP Whitelist
  └─ Submit IT ticket for temporary access
  └─ Add IP range for 24-48 hours
  └─ Require MFA during exception period

Option 3: Mobile App
  └─ Use Salesforce Mobile App (no IP restriction)
  └─ MFA required for mobile access
```

---

## Pattern 5: Single Sign-On (SSO) Pattern

**Category**: Trusted → Secure → Session Security → SSO

**Purpose**: Centralize authentication through identity provider

### Implementation Checklist

| Where to look? | What does good look like? |
|----------------|---------------------------|
| **Platform \| Identity Provider** | ✅ SSO configured with enterprise identity provider (Okta, Azure AD, etc.) |
| **Platform \| SAML Settings** | ✅ SAML 2.0 properly configured with encryption |
| **Platform \| My Domain** | ✅ My Domain deployed (required for SSO) |
| **Platform \| SSO Settings** | ✅ Just-in-Time (JIT) provisioning configured for new users |
| **Platform \| Profiles** | ✅ Profiles mapped correctly from identity provider |

### Configuration

**Setup → Identity → Single Sign-On Settings**

**SSO Architecture**:
```
User → Identity Provider (Okta/Azure AD) → SAML Assertion → Salesforce
  ↑                                                              ↓
  └─────────────────── Seamless Experience ─────────────────────┘

Benefits:
✅ Single set of credentials
✅ Centralized access control
✅ Automatic provisioning/deprovisioning
✅ Password policy enforcement at IdP
✅ Audit trail at identity provider
```

**SAML Configuration**:
```
1. Deploy My Domain (Required)
   Setup → My Domain
   └─ Create custom Salesforce domain
   └─ Example: mycompany.my.salesforce.com

2. Configure Identity Provider
   Setup → Identity → Identity Provider
   └─ Enable Identity Provider: ✅
   └─ Certificate: Upload X.509 certificate
   └─ Download Metadata (for IdP configuration)

3. Configure SSO Settings
   Setup → Identity → Single Sign-On Settings
   ├─ SAML Enabled: ✅
   ├─ SAML Version: 2.0
   ├─ Issuer: https://idp.mycompany.com
   ├─ Entity ID: https://mycompany.my.salesforce.com
   ├─ Identity Provider Certificate: [Upload]
   ├─ Request Signing Certificate: [Generate]
   └─ Identity Location: Subject (NameID)

4. Configure Just-in-Time Provisioning
   Setup → Identity → SAML Single Sign-On Settings → [Config]
   ├─ Just-in-Time User Provisioning: ✅
   ├─ Standard User License: ✅
   ├─ Profile: Standard User (default)
   └─ Attribute Mapping:
       ├─ FirstName → User.FirstName
       ├─ LastName → User.LastName
       ├─ Email → User.Email
       └─ Department → User.Department
```

**Attribute Mapping Example**:
```xml
<!-- SAML Assertion from Identity Provider -->
<Attribute Name="FirstName">
  <AttributeValue>John</AttributeValue>
</Attribute>
<Attribute Name="LastName">
  <AttributeValue>Doe</AttributeValue>
</Attribute>
<Attribute Name="Email">
  <AttributeValue>john.doe@company.com</AttributeValue>
</Attribute>
<Attribute Name="Department">
  <AttributeValue>Sales</AttributeValue>
</Attribute>
<Attribute Name="Profile">
  <AttributeValue>Sales User</AttributeValue>
</Attribute>

<!-- Mapped to Salesforce User Fields -->
User.FirstName = "John"
User.LastName = "Doe"
User.Email = "john.doe@company.com"
User.Department = "Sales"
User.ProfileId = [Sales User Profile ID]
```

**Testing SSO**:
```
Test Scenarios:
1. New User Login
   - User exists in IdP but not Salesforce
   - Expected: JIT provisioning creates user
   - Verify: User created with correct profile/permissions

2. Existing User Login
   - User exists in both IdP and Salesforce
   - Expected: Seamless login
   - Verify: Attributes synced correctly

3. Deactivated User
   - User deactivated in IdP
   - Expected: Login fails
   - Verify: Error message clear

4. Attribute Update
   - User department changed in IdP
   - Expected: Department updates on next login
   - Verify: Salesforce User.Department updated
```

---

## Pattern 6: Threat Detection & Response Pattern

**Category**: Trusted → Secure → Session Security → Threat Detection & Response

**Hierarchy**: Well-Architected → Trusted → Secure → Session Security → Threat Detection & Response

**Purpose**: Detect and respond to security threats in real-time through automated monitoring, audit logging, and response mechanisms

### Implementation Checklist

| Where to look?<br>Product Area \| Location | What does good look like?<br>Pattern |
|---------------------------------------------|--------------------------------------|
| **Einstein \| Agents** | ✅ Agent event logs include conversation data Enable the setting for enriched event logs, unless there is a critical reason why conversation data should be masked |
| **Einstein \| Einstein Trust Layer** | ✅ Generative AI features are regularly audited Einstein Generative AI Audit Data is enabled from the Einstein Feedback setup page. Generative AI conversations, including the prompt and it's response, are regularly audited and reviewed |
| **Platform \| Company** | ✅ Audit data is available in reports business stakeholders can understand and access |
| **Platform \| Company** | ✅ Regular reviews of audit history and reports take place |
| **Platform \| Documentation** | ✅ All automated responses are documented clearly |
| **Platform \| Documentation** | ✅ Steps to review logs available within Salesforce are documented |
| **Platform \| Documentation** | ✅ Audit levels have been specified for all objects in your data model |
| **Platform \| Documentation** | ✅ Security policies contain a list of events that should trigger a response along with the appropriate response type |
| **Platform \| Org** | ✅ Automations are in place to respond to threats by deactivating user accounts or blocking access to resources in real time if abnormal usage is detected |
| **Platform \| Org** | ✅ Notifications and alerts are configured to notify appropriate users about anomalous activity |
| **Platform \| Org** | ✅ Field History tracking is enabled for all fields containing private or sensitive data |

### Einstein Agent Event Logging

**Setup → Einstein → Agents → Event Logging**

**Configuration**:
```
Einstein Agent Event Logs:
├─ Enriched Event Logs: Enabled
├─ Conversation Data: Included
├─ Prompt Logging: Enabled
├─ Response Logging: Enabled
├─ User Context: Captured
└─ Timestamp: UTC

When to Mask Conversation Data:
❌ Never mask unless legally required
✓ Log all agent interactions
✓ Log prompts and responses
✓ Log user feedback
✓ Log error messages

Critical Reasons to Mask:
- PII/PHI in prompts (healthcare)
- Payment card data (PCI-DSS)
- Legal hold requirements
- Regulatory compliance (specific jurisdictions)
```

**Access Event Logs**:
```apex
// Query Einstein Agent event logs
List<AgentEventLog__c> eventLogs = [
    SELECT Id, ConversationId__c, Prompt__c, Response__c,
           UserId__c, Timestamp__c, ErrorMessage__c
    FROM AgentEventLog__c
    WHERE CreatedDate = LAST_N_DAYS:7
    ORDER BY Timestamp__c DESC
];

// Analyze conversation patterns
for (AgentEventLog__c log : eventLogs) {
    // Check for anomalous prompts
    if (containsSensitiveData(log.Prompt__c)) {
        // Alert security team
        notifySecurityTeam(log);
    }

    // Track response quality
    if (log.ErrorMessage__c != null) {
        // Log error for review
        logErrorForReview(log);
    }
}
```

### Einstein Trust Layer Audit

**Setup → Einstein → Trust Layer → Audit Settings**

**Einstein Generative AI Audit Configuration**:
```
Audit Settings:
├─ Einstein Generative AI Audit Data: Enabled
├─ Prompt Audit: All prompts logged
├─ Response Audit: All responses logged
├─ Feedback Audit: User feedback captured
├─ Model Version: Tracked
└─ Token Usage: Monitored

Audit Schedule:
├─ Real-time: Critical security events
├─ Daily: Usage patterns and anomalies
├─ Weekly: Prompt/response quality review
├─ Monthly: Comprehensive audit report
└─ Quarterly: Executive security review
```

**Setup Process**:
```
1. Enable Einstein Generative AI Audit Data
   Setup → Einstein → Einstein Trust Layer
   └─ Einstein Generative AI Audit Data: ✅ Enabled

2. Configure Audit Scope
   Setup → Einstein Feedback
   ├─ Capture all prompts: ✅
   ├─ Capture all responses: ✅
   ├─ Capture user feedback: ✅
   └─ Capture error messages: ✅

3. Set up regular review process
   ├─ Assign audit reviewer role
   ├─ Schedule weekly review meetings
   ├─ Create audit report dashboard
   └─ Document findings and actions

4. Configure alerts
   ├─ Alert on sensitive data in prompts
   ├─ Alert on high error rates
   ├─ Alert on unusual usage patterns
   └─ Alert on policy violations
```

**Regular Audit Process**:
```apex
public class EinsteinAuditReview {

    /**
     * Weekly audit of Einstein Generative AI usage
     */
    public static void conductWeeklyAudit() {
        // Get audit data for past week
        Date startDate = Date.today().addDays(-7);

        AggregateResult[] auditSummary = [
            SELECT COUNT(Id) totalConversations,
                   AVG(TokenUsage__c) avgTokens,
                   COUNT_DISTINCT(UserId__c) uniqueUsers
            FROM Einstein_Audit__c
            WHERE CreatedDate >= :startDate
        ];

        // Identify anomalies
        List<Einstein_Audit__c> anomalies = [
            SELECT Id, Prompt__c, Response__c, UserId__c, Timestamp__c
            FROM Einstein_Audit__c
            WHERE CreatedDate >= :startDate
            AND (
                TokenUsage__c > 10000 OR  // Unusually high tokens
                ErrorCount__c > 5 OR       // Multiple errors
                ContainsSensitiveData__c = true  // Sensitive data detected
            )
        ];

        // Generate audit report
        generateAuditReport(auditSummary, anomalies);

        // Notify audit team
        notifyAuditTeam(auditSummary, anomalies);
    }

    /**
     * Check if prompt/response contains sensitive data
     */
    private static Boolean containsSensitiveData(String text) {
        // Pattern matching for sensitive data
        String ssnPattern = '\\d{3}-\\d{2}-\\d{4}';
        String ccPattern = '\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}';
        String emailPattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}';

        Pattern p = Pattern.compile(ssnPattern + '|' + ccPattern);
        Matcher m = p.matcher(text);

        return m.find();
    }
}
```

### Audit Data Reporting for Business Stakeholders

**Create Accessible Audit Dashboards**:

```
Dashboard: Security Audit Overview
├─ Component 1: Login Activity (Last 30 Days)
│   ├─ Chart Type: Line chart
│   ├─ Metric: Daily login count
│   └─ Filter: By user profile, location
│
├─ Component 2: Failed Login Attempts
│   ├─ Chart Type: Bar chart
│   ├─ Metric: Failed attempts by user
│   └─ Alert: >5 failures in 1 hour
│
├─ Component 3: Data Access Patterns
│   ├─ Chart Type: Heat map
│   ├─ Metric: Records accessed by object
│   └─ Filter: By time of day, user
│
├─ Component 4: Permission Changes
│   ├─ Chart Type: Table
│   ├─ Metric: Recent permission set assignments
│   └─ Alert: High-risk permission granted
│
└─ Component 5: API Usage
    ├─ Chart Type: Gauge
    ├─ Metric: API calls (% of limit)
    └─ Alert: >80% usage

Dashboard: Einstein AI Audit
├─ Component 1: Conversation Volume
│   ├─ Total conversations (7 days)
│   ├─ Avg conversations per user
│   └─ Peak usage times
│
├─ Component 2: Prompt Categories
│   ├─ Breakdown by topic
│   ├─ Most common prompts
│   └─ Error rate by category
│
├─ Component 3: Response Quality
│   ├─ User feedback (thumbs up/down)
│   ├─ Average response time
│   └─ Token usage trends
│
└─ Component 4: Security Alerts
    ├─ Sensitive data detected
    ├─ Policy violations
    └─ Unusual patterns

Access Control:
├─ Executive View: High-level metrics only
├─ Security Team: Full audit data access
├─ Compliance Team: Audit trail and reports
└─ Business Analysts: Anonymized usage data
```

**Report Automation**:
```apex
public class AuditReportScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Generate weekly audit report
        AuditReport report = generateWeeklyReport();

        // Email to stakeholders
        List<String> recipients = getStakeholderEmails();
        EmailManager.send(recipients, 'Weekly Security Audit Report', report);
    }

    private static AuditReport generateWeeklyReport() {
        AuditReport report = new AuditReport();

        // Login activity
        report.loginCount = [
            SELECT COUNT() FROM LoginHistory
            WHERE LoginTime = LAST_N_DAYS:7
        ];

        // Failed login attempts
        report.failedLogins = [
            SELECT COUNT() FROM LoginHistory
            WHERE LoginTime = LAST_N_DAYS:7
            AND Status = 'Failed'
        ];

        // Permission changes
        report.permissionChanges = [
            SELECT COUNT() FROM SetupAuditTrail
            WHERE CreatedDate = LAST_N_DAYS:7
            AND Action LIKE '%Permission%'
        ];

        return report;
    }
}
```

### Regular Audit Reviews

**Establish Review Cadence**:

```
Daily Reviews (Automated):
├─ Failed login attempts (>5 per user)
├─ API usage spikes (>50% above baseline)
├─ After-hours access (non-authorized users)
└─ High-risk permission grants

Weekly Reviews (Security Team):
├─ Audit trail analysis (all changes)
├─ Einstein AI usage patterns
├─ Data access anomalies
├─ User activity reports
└─ Security alert summary

Monthly Reviews (Management):
├─ Executive audit summary
├─ Compliance posture
├─ Trend analysis (YoY, MoM)
├─ Risk assessment updates
└─ Policy effectiveness review

Quarterly Reviews (Executive/Board):
├─ Security metrics dashboard
├─ Major incidents summary
├─ Compliance certification status
├─ Security investment ROI
└─ Strategic security roadmap
```

**Review Documentation**:
```
Audit Review Template:
├─ Review Date: [Date]
├─ Review Period: [Start - End]
├─ Reviewer: [Name/Team]
├─ Scope: [What was reviewed]
├─ Findings:
│   ├─ Critical: [High-risk issues]
│   ├─ High: [Important issues]
│   ├─ Medium: [Moderate issues]
│   └─ Low: [Minor issues]
├─ Actions Taken:
│   ├─ Immediate: [Emergency response]
│   ├─ Short-term: [Within 1 week]
│   └─ Long-term: [Within 1 month]
├─ Recommendations:
│   ├─ Policy updates
│   ├─ Process improvements
│   └─ Technology enhancements
└─ Follow-up: [Next review date]
```

### Automated Response Documentation

**Document All Automated Responses**:

```
Automated Response Inventory:
┌──────────────────────────┬─────────────────────┬──────────────────┐
│ Trigger Event            │ Automated Action    │ Documentation    │
├──────────────────────────┼─────────────────────┼──────────────────┤
│ 5+ failed login attempts │ Lock account        │ Wiki: AR-001     │
│ Login from new country   │ MFA challenge       │ Wiki: AR-002     │
│ API limit exceeded       │ Throttle requests   │ Wiki: AR-003     │
│ After-hours admin login  │ Alert security team │ Wiki: AR-004     │
│ Mass data export         │ Require approval    │ Wiki: AR-005     │
│ Permission set grant     │ Log + notify        │ Wiki: AR-006     │
│ Sensitive data access    │ Log + alert         │ Wiki: AR-007     │
│ Concurrent session       │ Terminate older     │ Wiki: AR-008     │
└──────────────────────────┴─────────────────────┴──────────────────┘
```

**Documentation Template**:
```markdown
# Automated Response: AR-001
## Failed Login Account Lock

**Trigger Event**: 5+ failed login attempts within 10 minutes

**Automated Actions**:
1. Lock user account immediately
2. Send notification to user (email)
3. Send alert to security team (Slack)
4. Log event to security audit trail
5. Create incident ticket (ServiceNow)

**Implementation**:
- Tool: Transaction Security Policy
- Policy Name: "Failed Login Protection"
- Action Type: Block
- Notification: Email template "Account Locked"

**Unlock Process**:
1. User contacts IT support
2. IT verifies identity (MFA required)
3. IT reviews failed login attempts
4. IT unlocks account via Setup
5. User resets password (required)

**Escalation**:
- If >10 failed attempts: Escalate to InfoSec
- If from foreign IP: Investigate further
- If admin account: Immediate InfoSec review

**Last Updated**: 2024-01-15
**Owner**: Security Operations Team
**Review Frequency**: Quarterly
```

### Log Review Documentation

**Document Salesforce Log Review Process**:

```markdown
# Salesforce Log Review Guide

## Available Logs

### 1. Debug Logs
**Location**: Setup → Environments → Logs → Debug Logs
**Retention**: 24 hours
**Use Case**: Troubleshooting code, performance issues

**Review Process**:
```apex
// Set up debug log for user
DebugLog debugLog = new DebugLog();
debugLog.UserId = UserInfo.getUserId();
debugLog.LogType = 'USER_DEBUG';
debugLog.DurationHours = 1;
insert debugLog;
```

### 2. Event Log Files
**Location**: Setup → Security → Event Monitoring → Event Log File
**Retention**: 30 days
**Use Case**: Security analysis, compliance auditing

**Available Event Types**:
- Login
- Logout
- API calls
- Report exports
- List view access
- SOQL queries
- Apex executions

**Download and Analyze**:
```bash
# Download via API
curl https://instance.salesforce.com/services/data/v60.0/query \
  -H "Authorization: Bearer token" \
  -d "q=SELECT+Id,+EventType,+LogDate+FROM+EventLogFile+WHERE+LogDate+=+LAST_N_DAYS:7"

# Analyze with Python/R/Tableau
# Look for anomalies, patterns, security events
```

### 3. Setup Audit Trail
**Location**: Setup → Security → View Setup Audit Trail
**Retention**: 180 days (6 months)
**Use Case**: Configuration changes, compliance

**Review Checklist**:
- [ ] All permission set changes reviewed
- [ ] All profile modifications reviewed
- [ ] All field-level security changes reviewed
- [ ] All user creation/deactivation reviewed
- [ ] All sharing rule changes reviewed

### 4. Field History Tracking
**Location**: Setup → Object Manager → [Object] → Fields & Relationships → Set History Tracking
**Retention**: 18 months
**Use Case**: Data change audit, compliance

**Enable for Critical Fields**:
- Financial fields (Amount, Price, etc.)
- Status fields (Approval_Status__c)
- Owner fields (OwnerId)
- Sensitive data (SSN__c, etc.)

### 5. Login History
**Location**: Setup → Security → Login History
**Retention**: 6 months
**Use Case**: Login monitoring, security analysis

**Weekly Review**:
```apex
// Query failed logins
List<LoginHistory> failedLogins = [
    SELECT Id, UserId, LoginTime, SourceIp, Status
    FROM LoginHistory
    WHERE LoginTime = LAST_N_DAYS:7
    AND Status != 'Success'
    ORDER BY LoginTime DESC
];

// Identify patterns
Map<Id, Integer> failuresByUser = new Map<Id, Integer>();
for (LoginHistory lh : failedLogins) {
    Integer count = failuresByUser.get(lh.UserId);
    failuresByUser.put(lh.UserId, (count == null ? 1 : count + 1));
}

// Alert on >10 failures per user
for (Id userId : failuresByUser.keySet()) {
    if (failuresByUser.get(userId) > 10) {
        alertSecurityTeam(userId, failuresByUser.get(userId));
    }
}
```
```

### Audit Level Specification

**Document Audit Levels for Data Model**:

```
Object: Account
├─ Field History Tracking: Enabled
├─ Tracked Fields:
│   ├─ Name (All changes)
│   ├─ AnnualRevenue (All changes)
│   ├─ Industry (All changes)
│   ├─ OwnerId (All changes)
│   └─ Rating (All changes)
├─ Retention: 18 months
└─ Review Frequency: Monthly

Object: Opportunity
├─ Field History Tracking: Enabled
├─ Tracked Fields:
│   ├─ StageName (All changes)
│   ├─ Amount (All changes)
│   ├─ CloseDate (All changes)
│   ├─ Probability (All changes)
│   └─ OwnerId (All changes)
├─ Retention: 18 months
└─ Review Frequency: Weekly

Object: Custom_Invoice__c
├─ Field History Tracking: Enabled
├─ Tracked Fields:
│   ├─ Total_Amount__c (All changes)
│   ├─ Status__c (All changes)
│   ├─ Payment_Date__c (All changes)
│   └─ Approval_Status__c (All changes)
├─ Retention: 7 years (compliance)
└─ Review Frequency: Daily

Object: Sensitive_Data__c
├─ Field History Tracking: Enabled
├─ Tracked Fields: ALL FIELDS
├─ Retention: 10 years (legal hold)
├─ Review Frequency: Real-time alerts
└─ Encryption: Shield Platform Encryption
```

### Security Event Response Policies

**Document Events and Responses**:

```
Security Event Response Matrix:
┌─────────────────────────────┬──────────────┬────────────────────────┐
│ Event Type                  │ Severity     │ Response Type          │
├─────────────────────────────┼──────────────┼────────────────────────┤
│ Failed Login (>5 attempts)  │ Medium       │ Lock account + Alert   │
│ Login from new country      │ High         │ MFA challenge + Alert  │
│ After-hours admin login     │ High         │ Alert security team    │
│ Mass data export            │ Critical     │ Block + Immediate call │
│ Permission set grant        │ Medium       │ Log + Notify manager   │
│ API limit exceeded          │ Low          │ Throttle + Log         │
│ Concurrent sessions         │ Medium       │ Terminate oldest       │
│ Sensitive data access       │ High         │ Log + Alert + Review   │
│ Profile modification        │ Critical     │ Alert + Approval req   │
│ Sharing rule change         │ High         │ Alert + Audit          │
└─────────────────────────────┴──────────────┴────────────────────────┘
```

**Response Playbooks**:
```markdown
# Playbook: Suspicious Login Activity

**Trigger**: Login from new country not matching user travel schedule

**Immediate Response** (< 5 minutes):
1. Send MFA challenge to user
2. Alert security operations team
3. Log event with full context
4. Monitor for additional suspicious activity

**Investigation** (< 30 minutes):
1. Review user's recent activity
2. Check for data exports or downloads
3. Verify IP address legitimacy
4. Contact user to confirm travel

**Resolution**:
- If legitimate: Document and close
- If suspicious: Lock account, force password reset
- If confirmed breach: Incident response protocol

**Post-Incident**:
1. Review and update IP restrictions
2. Analyze attack pattern
3. Update threat intelligence
4. Report to management
```

### Real-Time Threat Response Automation

**Transaction Security Policies**:

```apex
// Setup → Security → Transaction Security Policies

/**
 * Policy 1: Deactivate User on Suspicious Activity
 */
public class DeactivateUserPolicy implements TxnSecurity.PolicyCondition {

    public boolean evaluate(TxnSecurity.Event e) {
        // Check for suspicious login pattern
        LoginEvent loginEvent = (LoginEvent) e;

        // Criteria for suspicious activity
        Boolean newCountry = isNewCountry(loginEvent.SourceIp);
        Boolean afterHours = isAfterHours(loginEvent.LoginTime);
        Boolean highRiskUser = isHighRiskUser(loginEvent.UserId);

        // Trigger if multiple indicators present
        return (newCountry && afterHours) || highRiskUser;
    }

    private Boolean isNewCountry(String ipAddress) {
        // Check if IP from new country
        String country = IpGeolocation.getCountry(ipAddress);

        List<LoginHistory> recentLogins = [
            SELECT Id, SourceIp
            FROM LoginHistory
            WHERE UserId = :UserInfo.getUserId()
            AND LoginTime = LAST_N_DAYS:30
        ];

        // Check if this country seen before
        for (LoginHistory lh : recentLogins) {
            String prevCountry = IpGeolocation.getCountry(lh.SourceIp);
            if (prevCountry == country) {
                return false; // Known country
            }
        }

        return true; // New country
    }
}

/**
 * Policy 2: Block Resource Access on Anomaly
 */
public class BlockResourceAccessPolicy implements TxnSecurity.PolicyCondition {

    public boolean evaluate(TxnSecurity.Event e) {
        // Check for mass data export
        ReportEvent reportEvent = (ReportEvent) e;

        // Block if exporting >10,000 records
        return reportEvent.RowsProcessed > 10000;
    }
}
```

**Automated Deactivation**:
```apex
public class ThreatResponseAutomation {

    /**
     * Deactivate user account on security threat
     */
    public static void deactivateUserAccount(Id userId, String reason) {
        // Deactivate user
        User user = [SELECT Id, IsActive FROM User WHERE Id = :userId];
        user.IsActive = false;
        update user;

        // Terminate all sessions
        Auth.SessionManagement.invalidateAllSessions(userId);

        // Revoke OAuth tokens
        revokeAllTokens(userId);

        // Log security event
        Security_Event__c event = new Security_Event__c(
            User__c = userId,
            Event_Type__c = 'Account Deactivation',
            Reason__c = reason,
            Timestamp__c = Datetime.now(),
            Automated__c = true
        );
        insert event;

        // Notify security team
        notifySecurityTeam(userId, reason);
    }

    /**
     * Block access to sensitive resource
     */
    public static void blockResourceAccess(Id userId, String resourceId) {
        // Remove permissions
        List<PermissionSetAssignment> assignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            AND PermissionSet.Name LIKE '%Sensitive%'
        ];
        delete assignments;

        // Log event
        logAccessBlock(userId, resourceId);

        // Alert user and security team
        notifyAccessBlock(userId, resourceId);
    }
}
```

### Anomalous Activity Notifications

**Configure Real-Time Alerts**:

```apex
public class AnomalyAlertSystem {

    /**
     * Send real-time alert for anomalous activity
     */
    public static void sendAnomalyAlert(String eventType, Map<String, Object> context) {
        // Determine severity
        String severity = calculateSeverity(eventType, context);

        // Get notification recipients
        List<String> recipients = getAlertRecipients(severity);

        // Create alert message
        String message = buildAlertMessage(eventType, context, severity);

        // Send via multiple channels
        sendEmailAlert(recipients, message);
        sendSlackAlert(message);
        createIncidentTicket(eventType, context, severity);

        // Log alert
        logAlert(eventType, context, severity);
    }

    private static String calculateSeverity(String eventType, Map<String, Object> context) {
        // Severity calculation logic
        if (eventType == 'MASS_DATA_EXPORT') return 'CRITICAL';
        if (eventType == 'ADMIN_AFTER_HOURS') return 'HIGH';
        if (eventType == 'FAILED_LOGIN') return 'MEDIUM';
        return 'LOW';
    }

    private static List<String> getAlertRecipients(String severity) {
        List<String> recipients = new List<String>();

        if (severity == 'CRITICAL') {
            // Alert everyone
            recipients.add('security@company.com');
            recipients.add('ciso@company.com');
            recipients.add('oncall@company.com');
        } else if (severity == 'HIGH') {
            recipients.add('security@company.com');
            recipients.add('oncall@company.com');
        } else {
            recipients.add('security@company.com');
        }

        return recipients;
    }

    private static void sendSlackAlert(String message) {
        // Send to #security-alerts Slack channel
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Slack_Webhook');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{
            'text' => message,
            'channel' => '#security-alerts'
        }));

        Http http = new Http();
        HttpResponse res = http.send(req);
    }
}
```

**Alert Configuration**:
```
Setup → Process Automation → Flows

Flow: Anomalous Activity Alert
├─ Trigger: Platform Event (Security_Event__e)
├─ Condition: Severity = 'High' OR 'Critical'
├─ Actions:
│   ├─ Send Email (Security team)
│   ├─ Create Task (Incident investigation)
│   ├─ Call Apex (Slack notification)
│   └─ Create Case (ServiceNow integration)
└─ Schedule: Real-time (no delay)

Alert Recipients by Severity:
├─ Critical:
│   ├─ CISO (Email + SMS)
│   ├─ Security Operations (Email + Slack)
│   ├─ On-call Engineer (PagerDuty)
│   └─ Incident Manager (Email + Phone)
├─ High:
│   ├─ Security Operations (Email + Slack)
│   ├─ On-call Engineer (Email)
│   └─ System Administrator (Email)
└─ Medium:
    └─ Security Operations (Email)
```

---

## Monitoring & Compliance

### Session Security Metrics

**Key Metrics to Track**:
```
1. MFA Adoption Rate
   - Formula: (Users with MFA / Total Users) × 100
   - Target: 100%
   - Dashboard: Setup → Identity Verification History

2. Failed Login Attempts
   - Track by IP, user, time
   - Alert on spike (>10 in 1 hour)
   - Report: Setup → Login History

3. Session Timeout Violations
   - Users attempting access after timeout
   - Track patterns (time of day, user)
   - Report: Event Log File

4. IP Restriction Violations
   - Login attempts from untrusted IPs
   - Alert on new IP locations
   - Report: Login History (Status = Invalid IP)

5. Mobile App Usage
   - Track active mobile users
   - Monitor PIN/passcode compliance
   - Report: Connected Apps Usage
```

### Automated Monitoring

**Transaction Security Policies**:
```apex
// Setup → Security → Transaction Security Policies

Policy 1: Anomalous Login Location
  └─ Trigger: Login from new country
  └─ Action: Block + Send notification

Policy 2: Multiple Failed Login Attempts
  └─ Trigger: >5 failed attempts in 10 minutes
  └─ Action: Block user + Alert admin

Policy 3: API Access from Untrusted IP
  └─ Trigger: API login from non-whitelisted IP
  └─ Action: Block + Require MFA verification

Policy 4: Concurrent Session Detection
  └─ Trigger: Same user, different locations simultaneously
  └─ Action: Alert admin + Log event
```

### Audit & Compliance Reports

**Required Reports**:
```
1. User Access Report
   - All users with login access
   - Last login date
   - MFA status
   - Profile/Permission Sets

2. Privileged User Report
   - System Admins, Developers
   - Last activity
   - IP ranges configured
   - MFA verification

3. Mobile Access Report
   - Users with mobile access
   - Devices registered
   - Last mobile login
   - Policy compliance

4. SSO Configuration Report
   - Identity provider details
   - Certificate expiration dates
   - Attribute mappings
   - JIT provisioning status
```

---

## Implementation Checklist

**Phase 1: Foundation (Week 1-2)**
- [ ] Deploy My Domain
- [ ] Enable MFA organization-wide
- [ ] Configure session timeouts per profile
- [ ] Document security personas

**Phase 2: Device Access (Week 3-4)**
- [ ] Configure mobile app security policies
- [ ] Enable API Access Control
- [ ] Test device policies per persona
- [ ] Create permission sets for mobile access

**Phase 3: Network Security (Week 5-6)**
- [ ] Document trusted IP ranges
- [ ] Configure IP restrictions per profile
- [ ] Set up organization-wide trusted IPs
- [ ] Test VPN access

**Phase 4: SSO Integration (Week 7-8)**
- [ ] Configure SAML with identity provider
- [ ] Enable Just-in-Time provisioning
- [ ] Map attributes correctly
- [ ] Test user lifecycle (create/update/deactivate)

**Phase 5: Monitoring (Week 9-10)**
- [ ] Set up Transaction Security Policies
- [ ] Create monitoring dashboards
- [ ] Configure alerts for violations
- [ ] Train security team on reports

**Phase 6: Compliance (Ongoing)**
- [ ] Quarterly security review
- [ ] Annual penetration testing
- [ ] Regular user access reviews
- [ ] Update documentation

---

## Resources

- **Official Documentation**: https://architect.salesforce.com/design/well-architected
- **Session Security Guide**: Setup → Help → Search "Session Security"
- **MFA Implementation**: https://help.salesforce.com/s/articleView?id=sf.security_overview_2fa.htm
- **SSO Configuration**: https://help.salesforce.com/s/articleView?id=sf.sso_about.htm

---

**Remember**: Session security is a critical component of the **TRUSTED** pillar. Every pattern here should be implemented based on your organization's security requirements and compliance needs.
