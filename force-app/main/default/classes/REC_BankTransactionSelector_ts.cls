/**
 * REC_BankTransactionSelector_ts — Test class for REC_BankTransactionSelector.
 *
 * Also covers inherited REC_SelectorBase methods:
 *  getFieldNames, getFieldCsv, getUpdatableFieldNames,
 *  getFieldNamesWithRelationship, queryByFilter
 */
@IsTest
private class REC_BankTransactionSelector_ts {
    private static BankTransaction__c getBt() {
        return [SELECT Id FROM BankTransaction__c LIMIT 1];
    }

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupSelectorTestData();
    }

    // ── Singleton & metadata ────────────────────────────────────────────────

    @IsTest
    static void getInstance_returnsSingleton() {
        Test.startTest();
        REC_BankTransactionSelector s1 = REC_BankTransactionSelector.getInstance();
        REC_BankTransactionSelector s2 = REC_BankTransactionSelector.getInstance();
        Test.stopTest();

        Assert.areEqual(s1, s2, 'getInstance should return the same singleton instance');
    }

    @IsTest
    static void getSObjectType_returnsBankTransactionType() {
        Assert.areEqual(
            BankTransaction__c.SObjectType,
            REC_BankTransactionSelector.getInstance().getSObjectType(),
            'getSObjectType should return BankTransaction__c.SObjectType'
        );
    }

    @IsTest
    static void getDefaultFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_BankTransactionSelector.getInstance().getDefaultFields();
        Assert.isFalse(fields.isEmpty(), 'getDefaultFields should return a non-empty list');
    }

    @IsTest
    static void getUpdatableFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_BankTransactionSelector.getInstance().getUpdatableFields();
        Assert.isFalse(fields.isEmpty(), 'getUpdatableFields should return a non-empty list');
    }

    // ── Inherited SelectorBase field helpers ─────────────────────────────────

    @IsTest
    static void getFieldNames_returnsAccessibleFieldNames() {
        List<String> names = REC_BankTransactionSelector.getInstance().getFieldNames();
        Assert.isFalse(names.isEmpty(), 'getFieldNames should return accessible field names');
        Assert.isTrue(names.contains('Id'), 'Field names should contain Id');
    }

    @IsTest
    static void getFieldCsv_returnsCommaSeparatedString() {
        String csv = REC_BankTransactionSelector.getInstance().getFieldCsv();
        Assert.isTrue(csv.contains('Id'), 'CSV should contain Id');
        Assert.isTrue(csv.contains(','), 'CSV should be comma-separated');
    }

    @IsTest
    static void getUpdatableFieldNames_returnsAccessibleFieldNames() {
        List<String> names = REC_BankTransactionSelector.getInstance().getUpdatableFieldNames();
        Assert.isFalse(names.isEmpty(), 'getUpdatableFieldNames should return accessible field names');
    }

    @IsTest
    static void getFieldNamesWithRelationship_returnsRelationshipPrefixedNames() {
        Test.startTest();
        List<String> names = REC_BankTransactionSelector.getInstance()
            .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefBankTransaction__c);
        Test.stopTest();

        Assert.isFalse(names.isEmpty(), 'Should return prefixed field names');
        for (String name : names) {
            Assert.isTrue(
                name.startsWith('RefBankTransaction__r.'),
                'Each name should be prefixed with the relationship name'
            );
        }
    }

    @IsTest
    static void getFieldNamesWithRelationship_nonRelationshipFieldThrowsException() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BankTransactionSelector.getInstance().getFieldNamesWithRelationship(BankTransaction__c.Name);
            Test.stopTest();
        } catch (REC_SelectorBase.REC_SelectorBaseException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Non-relationship field should throw REC_SelectorBaseException');
    }

    // ── Custom query: queryForReconciliation ────────────────────────────────

    @IsTest
    static void queryForReconciliation_returnsBtRecords() {
        BankTransaction__c bt = getBt();

        Test.startTest();
        List<BankTransaction__c> results = REC_BankTransactionSelector.getInstance()
            .queryForReconciliation(new Set<Id>{ bt.Id });
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return exactly one BT');
        Assert.areEqual(bt.Id, results[0].Id, 'Returned BT should match the queried Id');
    }

    // ── Inherited queries ───────────────────────────────────────────────────

    @IsTest
    static void queryByFilter_returnsResults() {
        String filters = REC_TableHelper.filter().eq('Currency__c', new List<String>{ REC_Consts.CCY.KRW }).toJson();

        Test.startTest();
        List<SObject> results = REC_BankTransactionSelector.getInstance().queryByFilter(filters);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'queryByFilter should return matching BTs');
    }

    @IsTest
    static void queryByFilterWithColumnFields_returnsResults() {
        String filters = REC_TableHelper.filter().eq('Currency__c', new List<String>{ REC_Consts.CCY.KRW }).toJson();
        String columnFields = JSON.serialize(new List<String>{ 'Id', 'Name' });

        Test.startTest();
        List<SObject> results = REC_BankTransactionSelector.getInstance().queryByFilter(filters, columnFields);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'queryByFilter with column fields should return matching BTs');
    }
}