/**
 * REC_ReconciliationSelector_ts — Test class for REC_ReconciliationSelector.
 *
 * Also covers REC_SelectorBase's default (empty) virtual overrides
 * for getUpdatableFields / getCompactFields since REC_ReconciliationSelector
 * does NOT override those methods.
 */
@IsTest
private class REC_ReconciliationSelector_ts {
    private static Reconciliation__c getRecon() {
        return [SELECT Id, Status__c FROM Reconciliation__c LIMIT 1];
    }

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupSelectorTestData();
    }

    // ── Singleton & metadata ────────────────────────────────────────────────

    @IsTest
    static void getInstance_returnsSingleton() {
        REC_ReconciliationSelector s1 = REC_ReconciliationSelector.getInstance();
        REC_ReconciliationSelector s2 = REC_ReconciliationSelector.getInstance();
        Assert.areEqual(s1, s2, 'getInstance should return the same singleton instance');
    }

    @IsTest
    static void getSObjectType_returnsReconciliationType() {
        Assert.areEqual(
            Reconciliation__c.SObjectType,
            REC_ReconciliationSelector.getInstance().getSObjectType(),
            'getSObjectType should return Reconciliation__c.SObjectType'
        );
    }

    @IsTest
    static void getDefaultFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_ReconciliationSelector.getInstance().getDefaultFields();
        Assert.isFalse(fields.isEmpty(), 'getDefaultFields should return a non-empty list');
    }

    // ── SelectorBase default overrides (empty) ──────────────────────────────

    @IsTest
    static void getUpdatableFields_defaultReturnsEmpty() {
        List<Schema.SObjectField> fields = REC_ReconciliationSelector.getInstance().getUpdatableFields();
        Assert.isTrue(fields.isEmpty(), 'Default getUpdatableFields should return empty list');
    }

    @IsTest
    static void getUpdatableFieldNames_defaultReturnsEmpty() {
        List<String> names = REC_ReconciliationSelector.getInstance().getUpdatableFieldNames();
        Assert.isTrue(names.isEmpty(), 'Default getUpdatableFieldNames should return empty list');
    }

    @IsTest
    static void getCompactFields_defaultReturnsEmpty() {
        List<Schema.SObjectField> fields = REC_ReconciliationSelector.getInstance().getCompactFields();
        Assert.isTrue(fields.isEmpty(), 'Default getCompactFields should return empty list');
    }

    @IsTest
    static void getCompactFieldNames_defaultReturnsEmpty() {
        List<String> names = REC_ReconciliationSelector.getInstance().getCompactFieldNames();
        Assert.isTrue(names.isEmpty(), 'Default getCompactFieldNames should return empty list');
    }

    @IsTest
    static void getCompactFieldCsv_defaultReturnsEmptyString() {
        String csv = REC_ReconciliationSelector.getInstance().getCompactFieldCsv();
        Assert.areEqual('', csv, 'Default getCompactFieldCsv should return empty string');
    }

    // ── Custom queries ──────────────────────────────────────────────────────

    @IsTest
    static void queryStatus_returnsStatus() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        String status = REC_ReconciliationSelector.getInstance().queryStatus(recon.Id);
        Test.stopTest();

        Assert.isNotNull(status, 'Status should not be null');
    }
}