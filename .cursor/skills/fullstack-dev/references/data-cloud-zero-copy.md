# Data Cloud Zero-Copy Patterns

Patterns for querying Salesforce Data Cloud directly without ETL (zero-copy data grounding).

**2026-Forward**: This represents the modern approach to unified customer data for AI and analytics.

---

## Table of Contents
1. [Zero-Copy Architecture](#zero-copy-architecture)
2. [Query Patterns](#query-patterns)
3. [Performance Optimization](#performance-optimization)
4. [Security Considerations](#security-considerations)
5. [Integration with Agentforce](#integration-with-agentforce)

---

## Zero-Copy Architecture

### What Is Zero-Copy?
**Traditional Approach** (ETL):
```
External Data → ETL Job → Salesforce Objects → Query
                ↓
           Latency: Hours/Days
           Storage: Duplicated
           Cost: High
```

**Zero-Copy Approach** (Data Cloud):
```
External Data → Data Cloud → Direct Query
                ↓
           Latency: Real-time
           Storage: No duplication
           Cost: Low
```

### Benefits
1. **Real-Time**: Query live data without waiting for ETL
2. **No Duplication**: Data stays in source systems
3. **Unified Profiles**: Harmonize data from CRM + external sources
4. **AI-Ready**: Perfect for Agentforce RAG patterns
5. **Cost-Effective**: No storage duplication

### Use Cases
- Customer 360 views (CRM + ERP + Marketing + Support)
- AI context retrieval (Agentforce RAG)
- Real-time analytics dashboards
- Personalization engines
- Unified reporting

---

## Query Patterns

### Pattern 1: Unified Customer Profile

**Scenario**: Get complete customer view from CRM + external systems.

```apex
public class CustomerProfileService {
    public static UnifiedProfile getCustomerProfile(Id accountId) {
        // Query Data Cloud for unified profile
        DataCloudQuery query = new DataCloudQuery()
            .from('Unified_Individual')
            .where('sfdc_account_id', accountId)
            .select(
                'customer_id',
                'first_name',
                'last_name',
                'email',
                'phone',
                'engagement_score',      // Calculated in Data Cloud
                'lifetime_value',        // From ERP
                'purchase_history',      // From eCommerce
                'support_tickets',       // From Support system
                'marketing_preferences', // From Marketing automation
                'sentiment_score'        // From Social media
            );

        List<UnifiedProfile> profiles = DataCloud.execute(query);

        if (profiles.isEmpty()) {
            throw new CustomerNotFoundException('No profile found for Account: ' + accountId);
        }

        return profiles[0];
    }
}

public class UnifiedProfile {
    public String customerId;
    public String firstName;
    public String lastName;
    public String email;
    public String phone;
    public Decimal engagementScore;
    public Decimal lifetimeValue;
    public List<Purchase> purchaseHistory;
    public List<Ticket> supportTickets;
    public Map<String, Boolean> marketingPreferences;
    public Decimal sentimentScore;
}
```

---

### Pattern 2: Real-Time Analytics

**Scenario**: Dashboard showing live customer behavior.

```apex
public class CustomerInsightsService {
    public static CustomerInsights getInsights(Id accountId) {
        // Query multiple Data Cloud entities
        DataCloudQuery engagementQuery = new DataCloudQuery()
            .from('Engagement_Events')
            .where('account_id', accountId)
            .where('event_date', '>=', Date.today().addDays(-30))
            .select('event_type', 'event_date', 'channel', 'engagement_score');

        DataCloudQuery purchaseQuery = new DataCloudQuery()
            .from('Purchase_Events')
            .where('account_id', accountId)
            .where('purchase_date', '>=', Date.today().addDays(-90))
            .select('product_id', 'amount', 'purchase_date');

        // Execute queries in parallel
        List<EngagementEvent> engagements = DataCloud.execute(engagementQuery);
        List<PurchaseEvent> purchases = DataCloud.execute(purchaseQuery);

        // Aggregate insights
        return new CustomerInsights(engagements, purchases);
    }
}
```

---

### Pattern 3: Calculated Insights

**Scenario**: Use Data Cloud calculated insights (pre-computed metrics).

```apex
public class CalculatedInsightsService {
    public static ChurnRiskProfile getChurnRisk(Id accountId) {
        // Query calculated insights (computed by Data Cloud)
        DataCloudQuery query = new DataCloudQuery()
            .from('Calculated_Insights')
            .where('account_id', accountId)
            .select(
                'churn_probability',          // ML-predicted churn risk
                'churn_drivers',              // Top factors driving churn
                'recommended_actions',        // Suggested interventions
                'next_best_action',           // Top recommendation
                'customer_lifetime_value_prediction' // Predicted LTV
            );

        List<ChurnRiskProfile> profiles = DataCloud.execute(query);

        return profiles.isEmpty() ? null : profiles[0];
    }
}
```

---

### Pattern 4: Time-Series Queries

**Scenario**: Trend analysis over time.

```apex
public class TrendAnalysisService {
    public static List<DailyMetric> getEngagementTrend(Id accountId, Integer days) {
        DataCloudQuery query = new DataCloudQuery()
            .from('Daily_Engagement_Metrics')
            .where('account_id', accountId)
            .where('metric_date', '>=', Date.today().addDays(-days))
            .orderBy('metric_date', 'ASC')
            .select('metric_date', 'page_views', 'sessions', 'engagement_score');

        return DataCloud.execute(query);
    }
}
```

---

### Pattern 5: Multi-Source Join

**Scenario**: Combine data from Salesforce objects + Data Cloud.

```apex
public class CustomerEnrichmentService {
    public static EnrichedCustomer getEnrichedCustomer(Id accountId) {
        // Step 1: Query Salesforce Account
        Account acc = [
            SELECT Id, Name, Industry, AnnualRevenue, NumberOfEmployees
            FROM Account
            WHERE Id = :accountId
        ];

        // Step 2: Query Data Cloud for external enrichment
        DataCloudQuery query = new DataCloudQuery()
            .from('Enrichment_Data')
            .where('sfdc_account_id', accountId)
            .select(
                'firmographic_data',    // From external data provider
                'technographic_data',   // Technologies used
                'intent_signals',       // Buying intent
                'social_data'           // Social media presence
            );

        List<EnrichmentData> enrichment = DataCloud.execute(query);

        // Step 3: Combine Salesforce + Data Cloud data
        return new EnrichedCustomer(acc, enrichment[0]);
    }
}
```

---

## Performance Optimization

### 1. Query Pushdown (Filter Early)

```apex
// ❌ WRONG: Fetch all, filter in Apex
DataCloudQuery query = new DataCloudQuery()
    .from('Unified_Individual')
    .select('customer_id', 'engagement_score', 'lifetime_value');

List<UnifiedProfile> profiles = DataCloud.execute(query);

// Filter in Apex (slow, wasteful)
List<UnifiedProfile> highValue = new List<UnifiedProfile>();
for (UnifiedProfile p : profiles) {
    if (p.lifetimeValue > 10000) {
        highValue.add(p);
    }
}

// ✅ CORRECT: Filter in Data Cloud (fast)
DataCloudQuery query = new DataCloudQuery()
    .from('Unified_Individual')
    .where('lifetime_value', '>', 10000)  // Pushdown filter
    .select('customer_id', 'engagement_score', 'lifetime_value');

List<UnifiedProfile> highValue = DataCloud.execute(query);
```

**Why**: Data Cloud processes filters server-side (faster, less data transferred).

---

### 2. Select Only Needed Fields

```apex
// ❌ WRONG: Select all fields
DataCloudQuery query = new DataCloudQuery()
    .from('Unified_Individual')
    .select('*'); // Returns all 100+ fields

// ✅ CORRECT: Select specific fields
DataCloudQuery query = new DataCloudQuery()
    .from('Unified_Individual')
    .select('customer_id', 'engagement_score', 'lifetime_value'); // Only 3 fields
```

**Why**: Reduces data transfer, improves latency.

---

### 3. Batch Queries

```apex
// ❌ WRONG: Query in loop (N+1)
for (Account acc : accounts) {
    DataCloudQuery query = new DataCloudQuery()
        .from('Unified_Individual')
        .where('sfdc_account_id', acc.Id)
        .select('engagement_score');

    List<UnifiedProfile> profiles = DataCloud.execute(query); // N queries
}

// ✅ CORRECT: Batch query
Set<Id> accountIds = new Set<Id>();
for (Account acc : accounts) {
    accountIds.add(acc.Id);
}

DataCloudQuery query = new DataCloudQuery()
    .from('Unified_Individual')
    .whereIn('sfdc_account_id', accountIds) // Single query
    .select('sfdc_account_id', 'engagement_score');

List<UnifiedProfile> profiles = DataCloud.execute(query);

// Map results
Map<Id, UnifiedProfile> profileMap = new Map<Id, UnifiedProfile>();
for (UnifiedProfile p : profiles) {
    profileMap.put(p.sfdcAccountId, p);
}
```

**Why**: Reduces query count from N to 1.

---

### 4. Caching

```apex
public class DataCloudCacheService {
    // Platform Cache for frequently accessed data
    private static final String CACHE_PARTITION = 'local.DataCloudCache';
    private static final Integer CACHE_TTL = 300; // 5 minutes

    public static UnifiedProfile getCachedProfile(Id accountId) {
        // Check cache first
        String cacheKey = 'profile_' + accountId;
        UnifiedProfile cachedProfile = (UnifiedProfile) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);

        if (cachedProfile != null) {
            return cachedProfile;
        }

        // Cache miss - query Data Cloud
        DataCloudQuery query = new DataCloudQuery()
            .from('Unified_Individual')
            .where('sfdc_account_id', accountId)
            .select('customer_id', 'engagement_score', 'lifetime_value');

        List<UnifiedProfile> profiles = DataCloud.execute(query);

        if (!profiles.isEmpty()) {
            UnifiedProfile profile = profiles[0];
            // Store in cache
            Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, profile, CACHE_TTL);
            return profile;
        }

        return null;
    }
}
```

**Why**: Reduces Data Cloud queries for frequently accessed data.

---

### 5. Pagination

```apex
public class DataCloudPaginationService {
    public static PagedResult getPagedProfiles(Integer pageNumber, Integer pageSize) {
        Integer offset = (pageNumber - 1) * pageSize;

        DataCloudQuery query = new DataCloudQuery()
            .from('Unified_Individual')
            .select('customer_id', 'first_name', 'last_name', 'engagement_score')
            .orderBy('engagement_score', 'DESC')
            .limit(pageSize)
            .offset(offset);

        List<UnifiedProfile> profiles = DataCloud.execute(query);

        // Get total count (separate query)
        DataCloudQuery countQuery = new DataCloudQuery()
            .from('Unified_Individual')
            .count();

        Integer total = DataCloud.executeCount(countQuery);

        return new PagedResult(profiles, total, pageSize, pageNumber);
    }
}

public class PagedResult {
    public List<UnifiedProfile> profiles;
    public Integer total;
    public Integer pageSize;
    public Integer pageNumber;
    public Boolean hasMore;

    public PagedResult(List<UnifiedProfile> profiles, Integer total, Integer pageSize, Integer pageNumber) {
        this.profiles = profiles;
        this.total = total;
        this.pageSize = pageSize;
        this.pageNumber = pageNumber;
        this.hasMore = (pageNumber * pageSize) < total;
    }
}
```

**Why**: Handles large datasets efficiently.

---

## Security Considerations

### 1. Field-Level Security

```apex
public class SecureDataCloudService {
    public static UnifiedProfile getProfileWithFLS(Id accountId) {
        DataCloudQuery query = new DataCloudQuery()
            .from('Unified_Individual')
            .where('sfdc_account_id', accountId)
            .select('customer_id', 'engagement_score', 'lifetime_value', 'ssn', 'credit_card');

        List<UnifiedProfile> profiles = DataCloud.execute(query);

        if (profiles.isEmpty()) {
            return null;
        }

        UnifiedProfile profile = profiles[0];

        // Enforce FLS: Mask sensitive fields if user doesn't have access
        if (!hasFieldAccess('Unified_Individual', 'ssn')) {
            profile.ssn = '***-**-****';
        }

        if (!hasFieldAccess('Unified_Individual', 'credit_card')) {
            profile.creditCard = '****-****-****-****';
        }

        return profile;
    }

    private static Boolean hasFieldAccess(String objectName, String fieldName) {
        // Check if current user has read access to field
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        if (sObjectType == null) {
            return false;
        }

        Schema.SObjectField field = sObjectType.getDescribe().fields.getMap().get(fieldName);
        if (field == null) {
            return false;
        }

        return field.getDescribe().isAccessible();
    }
}
```

---

### 2. Data Masking

```apex
public class DataMaskingService {
    public static UnifiedProfile maskSensitiveData(UnifiedProfile profile) {
        // Mask PII
        profile.ssn = maskSSN(profile.ssn);
        profile.creditCard = maskCreditCard(profile.creditCard);
        profile.email = maskEmail(profile.email);

        return profile;
    }

    private static String maskSSN(String ssn) {
        if (String.isBlank(ssn) || ssn.length() < 9) {
            return '***-**-****';
        }
        return '***-**-' + ssn.substring(ssn.length() - 4);
    }

    private static String maskCreditCard(String cardNumber) {
        if (String.isBlank(cardNumber) || cardNumber.length() < 13) {
            return '****-****-****-****';
        }
        return '****-****-****-' + cardNumber.substring(cardNumber.length() - 4);
    }

    private static String maskEmail(String email) {
        if (String.isBlank(email) || !email.contains('@')) {
            return '***@***.com';
        }
        String[] parts = email.split('@');
        return parts[0].substring(0, 1) + '***@' + parts[1];
    }
}
```

---

### 3. Audit Logging

```apex
public class DataCloudAuditService {
    public static void logDataAccess(Id userId, String objectName, String query, Integer recordCount) {
        Data_Cloud_Access_Log__c log = new Data_Cloud_Access_Log__c(
            User__c = userId,
            Object_Name__c = objectName,
            Query__c = query,
            Record_Count__c = recordCount,
            Access_Timestamp__c = System.now()
        );
        insert log;
    }
}
```

---

## Integration with Agentforce

### Pattern: RAG with Data Cloud

**Use Case**: Agentforce uses Data Cloud for context retrieval.

```apex
public class AgentforceRAGService {
    public static AgentforceResponse generatePersonalizedResponse(Id customerId, String question) {
        // Step 1: Retrieve context from Data Cloud
        DataCloudQuery query = new DataCloudQuery()
            .from('Unified_Individual')
            .where('customer_id', customerId)
            .select(
                'purchase_history',
                'support_tickets',
                'engagement_score',
                'sentiment_score',
                'preferences'
            );

        List<UnifiedProfile> profiles = DataCloud.execute(query);

        if (profiles.isEmpty()) {
            throw new CustomerNotFoundException('No profile found');
        }

        // Step 2: Build grounded context
        String context = buildRAGContext(profiles[0]);

        // Step 3: Invoke Agentforce with context
        Agentforce.Request req = new Agentforce.Request();
        req.setPrompt(question);
        req.setContext(context); // Grounded in Data Cloud data
        req.setTemperature(0.3); // Lower for factual responses

        Agentforce.Response response = Agentforce.invoke(req);

        return new AgentforceResponse(response);
    }

    private static String buildRAGContext(UnifiedProfile profile) {
        String context = 'Customer Profile:\n';
        context += '- Purchase History: ' + JSON.serialize(profile.purchaseHistory) + '\n';
        context += '- Support Tickets: ' + profile.supportTickets.size() + ' tickets\n';
        context += '- Engagement Score: ' + profile.engagementScore + '\n';
        context += '- Sentiment: ' + profile.sentimentScore + '\n';
        context += '- Preferences: ' + JSON.serialize(profile.preferences) + '\n';

        return context;
    }
}
```

**Reference**: See `./agentforce-patterns.md` for more RAG patterns.

---

## Best Practices

### 1. Query Optimization
- **Filter early**: Use `.where()` to reduce data transfer
- **Select specific fields**: Avoid `SELECT *`
- **Batch queries**: Avoid N+1 queries
- **Cache frequently accessed data**: Use Platform Cache

### 2. Security
- **Enforce FLS**: Check field access before exposing data
- **Mask PII**: Redact sensitive data (SSN, credit cards)
- **Audit access**: Log all Data Cloud queries
- **Data residency**: Comply with GDPR, HIPAA

### 3. Performance
- **Pagination**: Handle large datasets (don't fetch all)
- **Indexing**: Use indexed fields in `.where()` clauses
- **Monitoring**: Track query latency and volume
- **Rate limiting**: Respect Data Cloud query limits

### 4. Error Handling
```apex
try {
    List<UnifiedProfile> profiles = DataCloud.execute(query);
} catch (DataCloudException e) {
    if (e.getCode() == 'TIMEOUT') {
        // Retry with smaller dataset
    } else if (e.getCode() == 'RATE_LIMIT') {
        // Wait and retry
    } else {
        // Log and throw
        throw new CustomerServiceException('Data Cloud error: ' + e.getMessage());
    }
}
```

---

## Summary

**Key Takeaways**:
1. **Zero-Copy**: Query live data without ETL (real-time, no duplication)
2. **Unified Profiles**: Combine CRM + external data sources
3. **Performance**: Filter early, select specific fields, batch queries, cache
4. **Security**: Enforce FLS, mask PII, audit access
5. **AI Integration**: Perfect for Agentforce RAG patterns

**Query Pattern Summary**:
| Pattern | Use Case | Example |
|---------|----------|---------|
| Unified Profile | Customer 360 view | CRM + ERP + Marketing + Support |
| Real-Time Analytics | Live dashboards | Engagement trends, purchase behavior |
| Calculated Insights | ML predictions | Churn risk, LTV prediction |
| Time-Series | Trend analysis | Daily metrics, engagement over time |
| Multi-Source Join | Salesforce + Data Cloud | Account + enrichment data |

**Reference Files**:
- Agentforce RAG: `./agentforce-patterns.md`
- Full-Stack Integration: `./full-stack-integration.md`
- Context Engineering: `./context-engineering.md`
