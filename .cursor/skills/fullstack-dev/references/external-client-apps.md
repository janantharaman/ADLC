# External Client Apps (Spring '26 OAuth 2.0 Transition)

Migration guide from External Credentials and Named Credentials to the new External Client Apps authentication model (Spring '26 release).

**2026-Forward**: This represents Salesforce's unified OAuth 2.0 authentication strategy for external integrations.

---

## Table of Contents
1. [What Changed in Spring '26](#what-changed-in-spring-26)
2. [External Client Apps Overview](#external-client-apps-overview)
3. [Migration Strategy](#migration-strategy)
4. [Code Examples](#code-examples)
5. [Best Practices](#best-practices)

---

## What Changed in Spring '26

### Legacy Authentication (Pre-Spring '26)
```
External Credentials
    ↓
Named Credentials
    ↓
Permission Sets
    ↓
Apex Callouts
```

**Problems**:
- Complex setup (multiple objects)
- Hard to manage at scale
- Inconsistent OAuth flows
- Manual credential rotation

### New Authentication (Spring '26+)
```
External Client Apps
    ↓
OAuth 2.0 (automatic)
    ↓
Apex Callouts
```

**Benefits**:
- Simplified configuration (single object)
- Automatic OAuth 2.0 handling
- Built-in token refresh
- Centralized credential management
- Better security (automatic rotation)

---

## External Client Apps Overview

### What It Is
A unified authentication object that handles OAuth 2.0 flows for external system integrations.

### Supported OAuth Flows
1. **Authorization Code** - User-based authentication
2. **Client Credentials** - System-to-system authentication
3. **JWT Bearer** - Service account authentication
4. **SAML Bearer** - SAML-based authentication

### Key Features
- **Automatic Token Management**: Refresh tokens automatically
- **Centralized Credentials**: Single place for all external auth
- **Audit Logging**: Track credential usage
- **Permission-Based Access**: Control who can use which credentials
- **Multi-Org Support**: Reusable across sandboxes and production

---

## Migration Strategy

### Phase 1: Inventory (Week 1)

**Step 1: List External Credentials**
```bash
# Using Salesforce CLI
sf data query --query "SELECT DeveloperName, MasterLabel, AuthenticationProtocol FROM ExternalCredential" --target-org your-org
```

**Step 2: List Named Credentials**
```bash
sf data query --query "SELECT DeveloperName, Endpoint, AuthenticationProtocol FROM NamedCredential" --target-org your-org
```

**Step 3: Document Dependencies**
```
For each Named Credential:
1. Find Apex classes that reference it
2. Find flows that reference it
3. Find external services that reference it
4. Document usage count
```

**Example Inventory**:
| Named Credential | Type | Used By | Priority |
|------------------|------|---------|----------|
| WarehouseAPI | OAuth 2.0 | OrderService.cls, InventoryBatch.cls | High |
| PaymentGateway | JWT | PaymentService.cls | High |
| ShippingProvider | Basic Auth | ShippingService.cls | Medium |

---

### Phase 2: Create External Client Apps (Week 2)

**For Each Named Credential**:

#### Step 1: Create External Client App
```apex
// Setup → External Client Apps → New

ExternalClientApp app = new ExternalClientApp();
app.Name = 'Warehouse Integration';
app.AuthProvider = 'OAuth2'; // or JWT, SAML
app.ClientId = 'your-client-id';
app.ClientSecret = 'your-client-secret'; // Encrypted
app.TokenEndpoint = 'https://warehouse.example.com/oauth/token';
app.Scope = 'read write';
insert app;
```

#### Step 2: Configure OAuth Flow
```xml
<!-- For OAuth 2.0 Client Credentials -->
<ExternalClientApp>
    <Name>Warehouse Integration</Name>
    <AuthProvider>OAuth2_ClientCredentials</AuthProvider>
    <TokenEndpoint>https://warehouse.example.com/oauth/token</TokenEndpoint>
    <ClientId>abc123</ClientId>
    <ClientSecret>encrypted-secret</ClientSecret>
    <Scope>inventory.read inventory.write</Scope>
</ExternalClientApp>
```

#### Step 3: Test Authentication
```apex
// Test connection
ExternalClientAppService.testConnection('Warehouse Integration');
```

---

### Phase 3: Update Code (Week 3)

**Before (Named Credentials)**:
```apex
public class WarehouseService {
    public static HttpResponse syncInventory() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:WarehouseAPI/inventory');
        req.setMethod('GET');
        // Named Credential handles auth automatically

        Http http = new Http();
        return http.send(req);
    }
}
```

**After (External Client Apps)**:
```apex
public class WarehouseService {
    public static HttpResponse syncInventory() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:WarehouseIntegration/inventory');
        req.setMethod('GET');
        // External Client App handles OAuth automatically
        req.setHeader('Authorization', 'Bearer {!$Credential.ExternalClientApp.WarehouseIntegration}');

        Http http = new Http();
        return http.send(req);
    }
}
```

**Key Changes**:
1. Update `callout:` reference to new External Client App name
2. Use `{!$Credential.ExternalClientApp.AppName}` merge field
3. External Client App handles token refresh automatically

---

### Phase 4: Test (Week 4)

**Test Scenarios**:
1. **Successful callout**: Verify OAuth token obtained
2. **Token expiration**: Verify automatic refresh
3. **Invalid credentials**: Verify error handling
4. **Rate limiting**: Verify retry logic
5. **Sandbox vs Production**: Verify works in both

**Test Code**:
```apex
@isTest
private class WarehouseServiceTest {
    @isTest
    static void testSyncInventory_Success() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new WarehouseHttpMock(200, '{"status": "success"}'));

        // When
        Test.startTest();
        HttpResponse response = WarehouseService.syncInventory();
        Test.stopTest();

        // Then
        System.assertEquals(200, response.getStatusCode(), 'Should return 200');
        System.assert(response.getBody().contains('success'), 'Should be successful');
    }

    @isTest
    static void testSyncInventory_TokenExpired() {
        // Mock token expiration (401) then success (200)
        Test.setMock(HttpCalloutMock.class, new WarehouseHttpMock(401, '{"error": "token_expired"}'));

        // When: External Client App should automatically refresh token
        Test.startTest();
        HttpResponse response = WarehouseService.syncInventory();
        Test.stopTest();

        // Then: Should retry after token refresh
        // Note: Token refresh happens automatically, verify it succeeds
    }
}
```

---

### Phase 5: Deploy (Week 5)

**Deployment Checklist**:
- [ ] Create External Client Apps in sandbox
- [ ] Update Apex code
- [ ] Test thoroughly
- [ ] Document changes
- [ ] Create rollback plan
- [ ] Deploy to production during maintenance window
- [ ] Verify production callouts
- [ ] Monitor for 24 hours
- [ ] Deprecate Named Credentials (after 1 week of stability)

**Rollback Plan**:
```apex
// Keep old Named Credentials for 1 week
// If External Client App fails, revert code to use Named Credential

// OLD (rollback)
req.setEndpoint('callout:WarehouseAPI/inventory');

// NEW (current)
req.setEndpoint('callout:WarehouseIntegration/inventory');
req.setHeader('Authorization', 'Bearer {!$Credential.ExternalClientApp.WarehouseIntegration}');
```

---

## Code Examples

### Example 1: OAuth 2.0 Client Credentials

**Setup**:
```xml
<ExternalClientApp>
    <Name>ERPIntegration</Name>
    <AuthProvider>OAuth2_ClientCredentials</AuthProvider>
    <TokenEndpoint>https://erp.example.com/oauth/token</TokenEndpoint>
    <ClientId>erp-client-id</ClientId>
    <ClientSecret>erp-client-secret</ClientSecret>
    <Scope>orders.read orders.write</Scope>
</ExternalClientApp>
```

**Apex Code**:
```apex
public class ERPService {
    public static HttpResponse getOrders() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ERPIntegration/api/v1/orders');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer {!$Credential.ExternalClientApp.ERPIntegration}');
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse response = http.send(req);

        // External Client App automatically:
        // 1. Obtained OAuth token on first call
        // 2. Caches token until expiration
        // 3. Refreshes token when expired

        return response;
    }
}
```

---

### Example 2: JWT Bearer

**Setup**:
```xml
<ExternalClientApp>
    <Name>GoogleAPIIntegration</Name>
    <AuthProvider>JWT_Bearer</AuthProvider>
    <TokenEndpoint>https://oauth2.googleapis.com/token</TokenEndpoint>
    <Issuer>service-account@project.iam.gserviceaccount.com</Issuer>
    <Subject>service-account@project.iam.gserviceaccount.com</Subject>
    <Audience>https://oauth2.googleapis.com/token</Audience>
    <PrivateKey>-----BEGIN PRIVATE KEY-----...</PrivateKey>
    <Scope>https://www.googleapis.com/auth/drive</Scope>
</ExternalClientApp>
```

**Apex Code**:
```apex
public class GoogleDriveService {
    public static HttpResponse listFiles() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GoogleAPIIntegration/drive/v3/files');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer {!$Credential.ExternalClientApp.GoogleAPIIntegration}');

        Http http = new Http();
        return http.send(req);
    }
}
```

---

### Example 3: Authorization Code (User-Based)

**Setup**:
```xml
<ExternalClientApp>
    <Name>SlackIntegration</Name>
    <AuthProvider>OAuth2_AuthorizationCode</AuthProvider>
    <AuthorizationEndpoint>https://slack.com/oauth/v2/authorize</AuthorizationEndpoint>
    <TokenEndpoint>https://slack.com/api/oauth.v2.access</TokenEndpoint>
    <ClientId>slack-client-id</ClientId>
    <ClientSecret>slack-client-secret</ClientSecret>
    <RedirectUri>https://yourorg.salesforce.com/services/authcallback</RedirectUri>
    <Scope>chat:write channels:read</Scope>
</ExternalClientApp>
```

**Apex Code**:
```apex
public class SlackService {
    public static HttpResponse postMessage(String channel, String message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SlackIntegration/api/chat.postMessage');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer {!$Credential.ExternalClientApp.SlackIntegration}');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{
            'channel' => channel,
            'text' => message
        }));

        Http http = new Http();
        return http.send(req);
    }
}
```

---

## Best Practices

### 1. Credential Management
- **Never hardcode credentials** in Apex code
- **Use External Client Apps** for all external authentication
- **Rotate credentials regularly** (90 days)
- **Monitor credential usage** via audit logs

### 2. Error Handling
```apex
public class ExternalServiceHelper {
    public static HttpResponse callWithRetry(HttpRequest req, Integer maxRetries) {
        Http http = new Http();
        Integer retryCount = 0;

        while (retryCount < maxRetries) {
            try {
                HttpResponse response = http.send(req);

                if (response.getStatusCode() == 200) {
                    return response;
                } else if (response.getStatusCode() == 401) {
                    // Token expired - External Client App will refresh automatically on next call
                    retryCount++;
                    continue;
                } else if (response.getStatusCode() == 429) {
                    // Rate limited - wait and retry
                    retryCount++;
                    // Wait exponentially: 1s, 2s, 4s
                    Integer waitTime = (Integer)Math.pow(2, retryCount);
                    // Note: Can't actually sleep in synchronous Apex, use Queueable for async
                    continue;
                } else {
                    throw new ExternalServiceException('HTTP ' + response.getStatusCode() + ': ' + response.getBody());
                }
            } catch (Exception e) {
                if (retryCount >= maxRetries - 1) {
                    throw e;
                }
                retryCount++;
            }
        }

        throw new ExternalServiceException('Max retries exceeded');
    }
}
```

### 3. Testing
```apex
// Use Test.setMock for all external callouts
@isTest
private class ExternalServiceTest {
    @isTest
    static void testCallout() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"success": true}'));

        Test.startTest();
        HttpResponse response = ExternalService.makeCallout();
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode());
    }
}
```

### 4. Monitoring
```apex
// Log all external callouts for monitoring
public class ExternalServiceLogger {
    public static void logCallout(HttpRequest req, HttpResponse response, Long duration) {
        External_Callout_Log__c log = new External_Callout_Log__c(
            Endpoint__c = req.getEndpoint(),
            Method__c = req.getMethod(),
            Status_Code__c = response.getStatusCode(),
            Duration_Ms__c = duration,
            Request_Body__c = req.getBody(),
            Response_Body__c = response.getBody()
        );
        insert log;
    }
}
```

### 5. Security
- **Use HTTPS only** (never HTTP)
- **Validate SSL certificates**
- **Mask sensitive data** in logs
- **Implement rate limiting** on your side
- **Monitor for suspicious activity**

---

## Migration Checklist

### Pre-Migration
- [ ] Inventory all Named Credentials
- [ ] Document dependencies (Apex, Flows, External Services)
- [ ] Review authentication protocols
- [ ] Test in sandbox

### Migration
- [ ] Create External Client Apps
- [ ] Update Apex code
- [ ] Update Flows
- [ ] Update External Services
- [ ] Test thoroughly

### Post-Migration
- [ ] Deploy to production
- [ ] Monitor for 24 hours
- [ ] Verify all integrations working
- [ ] Deprecate Named Credentials (after 1 week)
- [ ] Update documentation

---

## Common Issues

### Issue 1: Token Not Refreshing
**Symptom**: 401 errors persist
**Solution**: Verify Token Endpoint and Refresh Token Grant Type are correct

### Issue 2: Scope Errors
**Symptom**: 403 Forbidden
**Solution**: Verify OAuth scopes match what external system expects

### Issue 3: Callout Failing in Production
**Symptom**: Works in sandbox, fails in production
**Solution**: Verify External Client App exists in production, credentials are correct

### Issue 4: Rate Limiting
**Symptom**: 429 Too Many Requests
**Solution**: Implement exponential backoff, use Queueable for async retries

---

## Summary

**Key Takeaways**:
1. **Spring '26**: External Client Apps replace Named Credentials + External Credentials
2. **OAuth 2.0**: Automatic token management and refresh
3. **Migration**: 5-week phased approach (inventory → create → update → test → deploy)
4. **Code Changes**: Update `callout:` references and add `Authorization` header
5. **Benefits**: Simplified setup, automatic token refresh, better security

**Reference Files**:
- Full-Stack Integration: `./full-stack-integration.md`
- Agentforce Patterns: `./agentforce-patterns.md`
- Data Cloud: `./data-cloud-zero-copy.md`
