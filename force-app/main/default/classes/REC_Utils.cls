/**
 * @description       : Reconciliation Utils.
 **/
/**
 * @description       : Reconciliation Utils.
 **/
public inherited sharing class REC_Utils {
    /**
     * Get picklist options for a given object and field.
     *
     * @param objectApiName
     * @param fieldApiName
     * @return              `List<REC_Option>`
     */
    @AuraEnabled(cacheable=true)
    public static List<REC_Option> getPicklistOptions(String objectApiName, String fieldApiName) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            return new List<REC_Option>();
        }

        Schema.DescribeSObjectResult objectDesc = Schema.describeSObjects(new List<String>{ objectApiName })[0];
        Schema.DescribeFieldResult fieldDesc = objectDesc.fields.getMap().get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDesc.getPicklistValues();

        List<REC_Option> options = new List<REC_Option>();

        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            options.add(new REC_Option(picklistEntry.getLabel(), picklistEntry.getValue()));
        }

        return options;
    }

    /**
     * Format for field info in getRequiredFields and getFieldsWithDefaultValues results.
     */
    private static String fieldResultFormat {
        get {
            return '\nLabel: {0}\nApiName: {1}\nType: {2}\nDefaultValue: {3}\n';
        }
    }

    /**
     * This method retrieves a list of required fields for a given SObject type.
     * A field is considered required if it is not nillable or if it is a reference field that is not nillable.
     * The method returns a list of strings containing the label, API name, type, and default value (if any) of each required field.
     *
     * @param sObjType
     * @return         `List<String>`
     */
    public static List<String> getRequiredFields(SObjectType sObjType) {
        List<String> result = new List<String>();
        Map<String, SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

            if (!dfr.isCreateable() || dfr.getType() == DisplayType.BOOLEAN) {
                continue;
            }

            if (!dfr.isNillable()) {
                String defaultValue = dfr.getDefaultValue() != null ? String.valueOf(dfr.getDefaultValue()) : '';

                result.add(
                    String.format(
                        fieldResultFormat,
                        new List<String>{ dfr.getLabel(), dfr.getName(), String.valueOf(dfr.getType()), defaultValue }
                    )
                );
            }
        }

        return result;
    }

    /**
     * This method retrieves a list of fields that have default values for a given SObject type.
     *
     * @param sObjType
     * @return         `List<String>`
     */
    public static List<String> getFieldsWithDefaultValues(SObjectType sObjType) {
        List<String> result = new List<String>();
        Map<String, SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

            if (dfr.getDefaultValue() != null) {
                result.add(
                    String.format(
                        fieldResultFormat,
                        new List<String>{
                            dfr.getLabel(),
                            dfr.getName(),
                            String.valueOf(dfr.getType()),
                            String.valueOf(dfr.getDefaultValue())
                        }
                    )
                );
            }
        }

        return result;
    }

    // =========================================================================
    //  Account & COA lookups
    // =========================================================================

    private static COM_Cache accountCache {
        get {
            if (accountCache == null) {
                accountCache = COM_Cache.of(AccountByRegionLoader.class);
            }
            return accountCache;
        }
        set;
    }

    private static COM_Cache coaCache {
        get {
            if (coaCache == null) {
                coaCache = COM_Cache.of(CoaByNameLoader.class);
            }
            return coaCache;
        }
        set;
    }

    /**
     * Returns the Account Id whose LKInternalRegion__c matches the given BizRegion.
     * Result is cached in Platform Cache (12-hour TTL).
     *
     * @param bizRegion  BizRegion value (e.g. REC_Consts.BizRegion.LK_KR)
     * @return           Account Id, or null if none found
     */
    public static Id getAccountIdByRegion(String bizRegion) {
        return (Id) accountCache.lookup(bizRegion);
    }

    /**
     * Returns a Map of BizRegion → Account Id for the given set of regions.
     * Each region is individually cached.
     *
     * @param bizRegions  Set of BizRegion values
     * @return            Map<String, Id>
     */
    public static Map<String, Id> getAccountIdsByRegions(Set<String> bizRegions) {
        Map<String, Id> result = new Map<String, Id>();
        if (bizRegions == null || bizRegions.isEmpty()) {
            return result;
        }
        for (String region : bizRegions) {
            result.put(region, getAccountIdByRegion(region));
        }
        return result;
    }

    /**
     * Returns the COA__c Id whose Name matches the given COA name.
     * Result is cached in Platform Cache (12-hour TTL).
     *
     * @param coaName  COA Name field value
     * @return         COA__c Id, or null if none found
     */
    public static Id getCoaIdByName(String coaName) {
        return (Id) coaCache.lookup(coaName);
    }

    /**
     * Returns a Map of BizRegion → COA__c Id for the given set of regions.
     * COA names are resolved via REC_Consts.BizRegion_COA and each result is individually cached.
     *
     * @param bizRegions  Set of BizRegion values
     * @return            Map<String, Id> keyed by BizRegion
     */
    public static Map<String, Id> getCoaIdsByRegions(Set<String> bizRegions) {
        Map<String, Id> result = new Map<String, Id>();
        if (bizRegions == null || bizRegions.isEmpty()) {
            return result;
        }
        Map<String, String> coaNameByRegion = REC_Consts.BizRegion_COA;
        for (String region : bizRegions) {
            String coaName = coaNameByRegion.get(region);
            result.put(region, coaName != null ? getCoaIdByName(coaName) : null);
        }
        return result;
    }

    // =========================================================================
    //  Role Check
    // =========================================================================

    private static Boolean isAdminCached;

    /**
     * Returns true if the current user's Profile has Modify All Data permission.
     * Result is cached in a static variable for the duration of the transaction (1 SOQL on first call).
     *
     * @return  true if the running user is a full admin (PermissionsModifyAllData)
     */
    public static Boolean isAdmin() {
        if (isAdminCached == null) {
            isAdminCached = [
                SELECT Profile.PermissionsModifyAllData
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ]
            .Profile.PermissionsModifyAllData;
        }
        return isAdminCached;
    }

    private static Boolean isOperationUserCached;

    private static final Set<String> OPERATION_ROLES = new Set<String>{
        REC_Consts.BizRole.OPERATION,
        REC_Consts.BizRole.FINANCE
    };

    /**
     * Returns true if the current user's Biz_Role__c (Multi-Select Picklist)
     * contains 'Finance' or 'Operation'.
     *
     * @return true if the running user has BizRole 'Finance' or 'Operation'
     */
    @AuraEnabled
    public static Boolean isOperationUser() {
        if (isOperationUserCached == null) {
            String bizRole = [SELECT Biz_Role__c FROM User WHERE Id = :UserInfo.getUserId()].Biz_Role__c ?? '';
            Set<String> userRoles = new Set<String>(bizRole.split(';'));
            userRoles.retainAll(OPERATION_ROLES);
            isOperationUserCached = !userRoles.isEmpty();
        }
        return isOperationUserCached;
    }

    // =========================================================================
    //  Feature Flags
    // =========================================================================

    public class DefaultFeatureFlagProvider implements REC_FeatureFlagProvider {
        public Boolean isEnabled(String featureName) {
            try {
                return [SELECT IsEnabled__c FROM FeatureFlag__mdt WHERE DeveloperName = :featureName LIMIT 1]
                ?.IsEnabled__c ?? false;
            } catch (Exception e) {
                System.debug('Error checking feature flag: ' + e.getMessage());
                return false;
            }
        }
    }

    @TestVisible
    private static REC_FeatureFlagProvider featureFlagProvider = new DefaultFeatureFlagProvider();

    @AuraEnabled
    public static Boolean isFeatureEnabled(String featureName) {
        return featureFlagProvider.isEnabled(featureName);
    }

    // =========================================================================
    //  Schema Helpers
    // =========================================================================

    public static String label(Schema.SObjectField f) {
        return f.getDescribe().getLabel();
    }

    public static String fieldName(Schema.SObjectField f) {
        return String.valueOf(f);
    }

    // =========================================================================
    //  Business Day Calculation
    // =========================================================================

    /**
     * Returns the date that is N business days from the given base date for the given BizRegion.
     * Business days exclude weekends (Sat/Sun) and Holiday__c records matching the BizRegion.
     * A positive offset moves forward; a negative offset moves backward.
     *
     * @param bizRegion  BizRegion__c value (e.g. 'LK_KR')
     * @param baseDate   The reference date to calculate from
     * @param offset     Number of business days to move (negative = past, positive = future)
     * @return           Target business day Date
     */
    public static Date getBusinessDay(String bizRegion, Date baseDate, Integer offset) {
        if (offset == 0) {
            return baseDate;
        }

        Integer direction = offset > 0 ? 1 : -1;
        Integer remaining = Math.abs(offset);

        // Buffer to pre-fetch holidays (generous to reduce chance of re-query)
        Integer bufferDays = remaining * 2 + 10;
        Date rangeStart = direction > 0 ? baseDate : baseDate.addDays(-bufferDays);
        Date rangeEnd = direction > 0 ? baseDate.addDays(bufferDays) : baseDate;

        Set<Date> holidays = new Set<Date>();
        for (Holiday__c h : [
            SELECT Date__c
            FROM Holiday__c
            WHERE BizRegion__c = :bizRegion AND Date__c >= :rangeStart AND Date__c <= :rangeEnd
            WITH SYSTEM_MODE
        ]) {
            holidays.add(h.Date__c);
        }

        Date current = baseDate;
        while (remaining > 0) {
            current = current.addDays(direction);
            if (!Util.isWeekend(current) && !holidays.contains(current)) {
                remaining--;
            }
        }

        return current;
    }

    // =========================================================================
    //  Loader inner classes
    // =========================================================================

    /**
     * COM_Cache.Loader — loads Account Id by LKInternalRegion__c on cache miss.
     */
    public inherited sharing class AccountByRegionLoader implements COM_Cache.Loader {
        public Object load(String key) {
            List<Account> accounts = [
                SELECT Id
                FROM Account
                WHERE LKInternalRegion__c = :key
                WITH USER_MODE
                LIMIT 1
            ];
            return accounts.isEmpty() ? null : accounts[0].Id;
        }
    }

    /**
     * COM_Cache.Loader — loads COA__c Id by Name on cache miss.
     */
    public inherited sharing class CoaByNameLoader implements COM_Cache.Loader {
        public Object load(String key) {
            List<COA__c> coas = [
                SELECT Id
                FROM COA__c
                WHERE Name = :key
                WITH USER_MODE
                LIMIT 1
            ];
            return coas.isEmpty() ? null : coas[0].Id;
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  CurrencyConfig — CMDT access for LWC (symbol) and Apex (rounding)
    // ═════════════════════════════════════════════════════════════════════════

    public class CurrencyConfigDTO {
        @AuraEnabled
        public String symbol;
        @AuraEnabled
        public Integer decimalPlaces;

        public CurrencyConfigDTO(String symbol, Integer decimalPlaces) {
            this.symbol = symbol;
            this.decimalPlaces = decimalPlaces;
        }
    }

    /**
     * Returns all CurrencyConfig__mdt records as a map keyed by currency code.
     * Each value is a CurrencyConfigDTO { symbol, decimalPlaces }.
     * Cacheable — safe for LWC @wire.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, CurrencyConfigDTO> getCurrencyConfigs() {
        Map<String, CurrencyConfigDTO> result = new Map<String, CurrencyConfigDTO>();

        for (CurrencyConfig__mdt cfg : CurrencyConfig__mdt.getAll().values()) {
            result.put(
                cfg.DeveloperName,
                new CurrencyConfigDTO(cfg.Symbol__c, cfg.DecimalPlaces__c != null ? cfg.DecimalPlaces__c.intValue() : 2)
            );
        }

        return result;
    }

    public static CurrencyRounder CCY {
        get {
            if (CCY == null) {
                CCY = new CurrencyRounder();
            }
            return CCY;
        }
        private set;
    }

    public class CurrencyRounder {
        private final Integer DEFAULT_SCALE = 2;

        private final Map<String, Integer> SCALE_BY_CCY;

        public CurrencyRounder() {
            SCALE_BY_CCY = new Map<String, Integer>();
            for (CurrencyConfig__mdt cfg : CurrencyConfig__mdt.getAll().values()) {
                SCALE_BY_CCY.put(
                    cfg.DeveloperName,
                    cfg.DecimalPlaces__c != null ? cfg.DecimalPlaces__c.intValue() : DEFAULT_SCALE
                );
            }
        }

        public Integer getScale(String currencyCode) {
            if (String.isBlank(currencyCode)) {
                return DEFAULT_SCALE;
            }
            return SCALE_BY_CCY.containsKey(currencyCode) ? SCALE_BY_CCY.get(currencyCode) : DEFAULT_SCALE;
        }

        public Decimal round(Decimal value, String currencyCode) {
            if (value == null) {
                return 0;
            }
            return value.setScale(getScale(currencyCode), RoundingMode.HALF_UP);
        }
    }
}