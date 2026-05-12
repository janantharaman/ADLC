public without sharing class AccountDepositorService {
    public static final String DEPOSITOR_UPDATE_SCOPE_UNRECONCILED_ONLY = 'Unreconciled Only';

    private static Set<String> existingAccountDepositorKey;
    private static List<AccountDepositor__c> existingAccountDepositor;

    public static List<AccountDepositor__c> getExistingAccountDepositor(
        Set<String> setBizRegion,
        Set<String> setDepositorName,
        List<AccountDepositor__c> listExcluded
    ) {
        if (existingAccountDepositor == null || existingAccountDepositor.size() == 0) {
            existingAccountDepositor = new List<AccountDepositor__c>(
                [
                    SELECT BizRegion__c, Depositor__c
                    FROM AccountDepositor__c
                    WHERE
                        IsActive__c = TRUE
                        AND BizRegion__c IN :setBizRegion
                        AND Depositor__c IN :setDepositorName
                        AND Id NOT IN :listExcluded
                ]
            );
        }
        return existingAccountDepositor;
    }

    public static Set<String> getExistingAccountDepositorKey(
        Set<String> setBizRegion,
        Set<String> setDepositorName,
        List<AccountDepositor__c> listExcluded
    ) {
        if (existingAccountDepositorKey == null) {
            existingAccountDepositorKey = new Set<String>();
            for (AccountDepositor__c existing : getExistingAccountDepositor(setBizRegion, setDepositorName, listExcluded)) {
                existingAccountDepositorKey.add(getDepositorKey(existing));
            }
        }
        return existingAccountDepositorKey;
    }

    public static String getDepositorKey(AccountDepositor__c depositor) {
        return depositor.BizRegion__c + '_' + depositor.Depositor__c;
    }

    /**
     * Queries AccountDepositor__c by BizRegion, AccountName (Lookup Id), and Depositor.
     * Used for Save Validation and Account Mapping button.
     */
    public static List<AccountDepositor__c> findActiveByBizRegionAccountDepositor(
        String bizRegion,
        Id accountNameId,
        String depositorName
    ) {
        return [
            SELECT Id, BizRegion__c, Depositor__c, AccountName__c, Remarks__c, UpdateScope__c, IsActive__c
            FROM AccountDepositor__c
            WHERE
                IsActive__c = TRUE
                AND BizRegion__c = :bizRegion
                AND AccountName__c = :accountNameId
                AND Depositor__c = :depositorName
        ];
    }

    /**
     * Bulk version: returns a Set of "BizRegion_Depositor_AccountNameId" keys
     * for which an active AccountDepositor exists.
     */
    public static Set<String> findActiveAccountDepositorKeys(
        Set<String> setBizRegion,
        Set<String> setDepositor,
        Set<Id> setAccountNameId
    ) {
        Set<String> keys = new Set<String>();
        for (AccountDepositor__c ad : [
            SELECT BizRegion__c, Depositor__c, AccountName__c
            FROM AccountDepositor__c
            WHERE
                IsActive__c = TRUE
                AND BizRegion__c IN :setBizRegion
                AND Depositor__c IN :setDepositor
                AND AccountName__c IN :setAccountNameId
        ]) {
            keys.add(ad.BizRegion__c + '_' + ad.Depositor__c + '_' + ad.AccountName__c);
        }
        return keys;
    }

    /**
     * Finds an existing AccountDepositor by BizRegion, Depositor, AccountName, and UpdateScope.
     * Used for modal Save duplicate check.
     */
    public static List<AccountDepositor__c> findActiveByFullKey(
        String bizRegion,
        String depositorName,
        Id accountNameId,
        String updateScope
    ) {
        return [
            SELECT Id, BizRegion__c, Depositor__c, AccountName__c, Remarks__c, UpdateScope__c, IsActive__c
            FROM AccountDepositor__c
            WHERE
                IsActive__c = TRUE
                AND BizRegion__c = :bizRegion
                AND Depositor__c = :depositorName
                AND AccountName__c = :accountNameId
                AND UpdateScope__c = :updateScope
        ];
    }

    /**
     * Finds an active AccountDepositor by BizRegion and Depositor only.
     * Used when AccountName is empty — to auto-fill from existing mapping.
     */
    public static List<AccountDepositor__c> findActiveByBizRegionDepositor(String bizRegion, String depositorName) {
        return [
            SELECT Id, BizRegion__c, Depositor__c, AccountName__c, Remarks__c, UpdateScope__c, IsActive__c
            FROM AccountDepositor__c
            WHERE IsActive__c = TRUE AND BizRegion__c = :bizRegion AND Depositor__c = :depositorName
            LIMIT 1
        ];
    }
}