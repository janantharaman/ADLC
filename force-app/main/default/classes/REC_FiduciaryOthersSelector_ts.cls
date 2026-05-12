/**
 * REC_FiduciaryOthersSelector_ts — Test class for REC_FiduciaryOthersSelector.
 */
@IsTest
private class REC_FiduciaryOthersSelector_ts {
    private static FiduciaryOthers__c getFo() {
        return [SELECT Id FROM FiduciaryOthers__c LIMIT 1];
    }

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupSelectorTestData();
    }

    // ── Singleton & metadata ────────────────────────────────────────────────

    @IsTest
    static void getInstance_returnsSingleton() {
        REC_FiduciaryOthersSelector s1 = REC_FiduciaryOthersSelector.getInstance();
        REC_FiduciaryOthersSelector s2 = REC_FiduciaryOthersSelector.getInstance();
        Assert.areEqual(s1, s2, 'getInstance should return the same singleton instance');
    }

    @IsTest
    static void getSObjectType_returnsFiduciaryOthersType() {
        Assert.areEqual(
            FiduciaryOthers__c.SObjectType,
            REC_FiduciaryOthersSelector.getInstance().getSObjectType(),
            'getSObjectType should return FiduciaryOthers__c.SObjectType'
        );
    }

    @IsTest
    static void getDefaultFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_FiduciaryOthersSelector.getInstance().getDefaultFields();
        Assert.isFalse(fields.isEmpty(), 'getDefaultFields should return a non-empty list');
    }

    @IsTest
    static void getUpdatableFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_FiduciaryOthersSelector.getInstance().getUpdatableFields();
        Assert.isFalse(fields.isEmpty(), 'getUpdatableFields should return a non-empty list');
    }

    // ── Inherited SelectorBase field helpers ─────────────────────────────────

    @IsTest
    static void getFieldNames_returnsAccessibleFieldNames() {
        List<String> names = REC_FiduciaryOthersSelector.getInstance().getFieldNames();
        Assert.isFalse(names.isEmpty(), 'getFieldNames should return accessible field names');
    }

    @IsTest
    static void getFieldCsv_returnsCommaSeparatedString() {
        String csv = REC_FiduciaryOthersSelector.getInstance().getFieldCsv();
        Assert.isTrue(csv.contains('Id'), 'CSV should contain Id');
    }

    @IsTest
    static void getUpdatableFieldNames_returnsAccessibleFieldNames() {
        List<String> names = REC_FiduciaryOthersSelector.getInstance().getUpdatableFieldNames();
        Assert.isFalse(names.isEmpty(), 'getUpdatableFieldNames should return accessible field names');
    }

    // ── Custom query: queryForReconciliation ────────────────────────────────

    @IsTest
    static void queryForReconciliation_returnsFoRecords() {
        FiduciaryOthers__c fo = getFo();

        Test.startTest();
        List<FiduciaryOthers__c> results = REC_FiduciaryOthersSelector.getInstance()
            .queryForReconciliation(new Set<Id>{ fo.Id });
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return exactly one FO');
        Assert.areEqual(fo.Id, results[0].Id, 'Returned FO should match the queried Id');
    }

    // ── Inherited queries ───────────────────────────────────────────────────

    @IsTest
    static void queryByFilter_returnsResults() {
        String filters = REC_TableHelper.filter()
            .eq('SettlementCurrency__c', new List<String>{ REC_Consts.CCY.KRW })
            .toJson();

        Test.startTest();
        List<SObject> results = REC_FiduciaryOthersSelector.getInstance().queryByFilter(filters);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'queryByFilter should return matching FOs');
    }
}