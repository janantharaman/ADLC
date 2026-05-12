/**
 * REC_SettlementLineItemSelector_ts — Test class for REC_SettlementLineItemSelector.
 *
 * Also covers inherited REC_SelectorBase queryByFilter column-field validation
 * (relationship columns, missing-field exception).
 */
@IsTest
private class REC_SettlementLineItemSelector_ts {
    private static Reconciliation__c getRecon() {
        return [SELECT Id, Status__c FROM Reconciliation__c LIMIT 1];
    }

    private static SettlementLineItem__c getDetailSli() {
        return [SELECT Id FROM SettlementLineItem__c WHERE OriginAmount__c > 0 LIMIT 1];
    }

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupSelectorTestData();
    }

    // ── Singleton & metadata ────────────────────────────────────────────────

    @IsTest
    static void getInstance_returnsSingleton() {
        REC_SettlementLineItemSelector s1 = REC_SettlementLineItemSelector.getInstance();
        REC_SettlementLineItemSelector s2 = REC_SettlementLineItemSelector.getInstance();
        Assert.areEqual(s1, s2, 'getInstance should return the same singleton instance');
    }

    @IsTest
    static void getSObjectType_returnsSliType() {
        Assert.areEqual(
            SettlementLineItem__c.SObjectType,
            REC_SettlementLineItemSelector.getInstance().getSObjectType(),
            'getSObjectType should return SettlementLineItem__c.SObjectType'
        );
    }

    @IsTest
    static void getDefaultFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_SettlementLineItemSelector.getInstance().getDefaultFields();
        Assert.isFalse(fields.isEmpty(), 'getDefaultFields should return a non-empty list');
    }

    @IsTest
    static void getUpdatableFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_SettlementLineItemSelector.getInstance().getUpdatableFields();
        Assert.isFalse(fields.isEmpty(), 'getUpdatableFields should return a non-empty list');
    }

    // ── Inherited SelectorBase field helpers ─────────────────────────────────

    @IsTest
    static void getFieldNames_returnsAccessibleFieldNames() {
        List<String> names = REC_SettlementLineItemSelector.getInstance().getFieldNames();
        Assert.isFalse(names.isEmpty(), 'getFieldNames should return accessible field names');
    }

    @IsTest
    static void getFieldCsv_returnsCommaSeparatedString() {
        String csv = REC_SettlementLineItemSelector.getInstance().getFieldCsv();
        Assert.isTrue(csv.contains('Id'), 'CSV should contain Id');
    }

    @IsTest
    static void getUpdatableFieldNames_returnsAccessibleFieldNames() {
        List<String> names = REC_SettlementLineItemSelector.getInstance().getUpdatableFieldNames();
        Assert.isFalse(names.isEmpty(), 'getUpdatableFieldNames should return accessible field names');
    }

    // ── Compact fields ──────────────────────────────────────────────────────

    @IsTest
    static void getCompactFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_SettlementLineItemSelector.getInstance().getCompactFields();
        Assert.isFalse(fields.isEmpty(), 'getCompactFields should return a non-empty list');
    }

    @IsTest
    static void getCompactFieldNames_returnsAccessibleNames() {
        List<String> names = REC_SettlementLineItemSelector.getInstance().getCompactFieldNames();
        Assert.isFalse(names.isEmpty(), 'getCompactFieldNames should return accessible field names');
    }

    @IsTest
    static void getCompactFieldCsv_returnsCommaSeparatedString() {
        String csv = REC_SettlementLineItemSelector.getInstance().getCompactFieldCsv();
        Assert.isTrue(csv.contains('Id'), 'Compact CSV should contain Id');
    }

    // ── getCloneableFieldNames ──────────────────────────────────────────────

    @IsTest
    static void getCloneableFieldNames_returnsNonEmptyList() {
        Test.startTest();
        List<String> names = REC_SettlementLineItemSelector.getInstance().getCloneableFieldNames();
        Test.stopTest();

        Assert.isFalse(names.isEmpty(), 'getCloneableFieldNames should return a non-empty list');
        Assert.isTrue(names.contains('Id'), 'Cloneable field names should contain Id');
    }

    // ── queryOtherChargesByRecon ────────────────────────────────────────────

    @IsTest
    static void queryOtherChargesByRecon_returnsOtherCharges() {
        Reconciliation__c recon = getRecon();

        insert REC_TestDataFactory.createOtherChargeSli(
            recon.Id,
            200,
            REC_TestDataFactory.DEFAULT_CURRENCY,
            REC_TestDataFactory.DEFAULT_BIZ_REGION
        );

        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryOtherChargesByRecon(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return one P_C SLI');
    }

    @IsTest
    static void queryOtherChargesByRecon_noMatchReturnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryOtherChargesByRecon(recon.Id);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Should return empty when no P_C SLIs exist');
    }

    // ── queryTargetsForCounterpart ──────────────────────────────────────────

    @IsTest
    static void queryTargetsForCounterpart_returnsMap() {
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();
        Map<Id, SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryTargetsForCounterpart(new List<Id>{ sli.Id });
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return exactly one SLI in the map');
        Assert.isTrue(results.containsKey(sli.Id), 'Map should contain the queried SLI Id');
    }

    // ── queryOffsetSlisByReconId ────────────────────────────────────────────

    @IsTest
    static void queryOffsetSlisByReconId_returnsSlis() {
        Reconciliation__c recon = getRecon();
        SettlementLineItem__c sli = getDetailSli();

        sli.ReconcileNo__c = recon.Id;
        update sli;

        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryOffsetSlisByReconId(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return one SLI linked via ReconcileNo__c');
    }

    @IsTest
    static void queryOffsetSlisByReconId_noMatchReturnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryOffsetSlisByReconId(recon.Id);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Should return empty when no SLIs have ReconcileNo__c set');
    }

    // ── Inherited queries ───────────────────────────────────────────────────

    @IsTest
    static void queryByFilter_returnsResults() {
        String filters = REC_TableHelper.filter()
            .eq('ClosingType__c', new List<String>{ REC_Consts.ClosingType.P_R })
            .toJson();

        Test.startTest();
        List<SObject> results = REC_SettlementLineItemSelector.getInstance().queryByFilter(filters);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'queryByFilter should return matching SLIs');
    }

    // ── queryByFilter column-field validation (SelectorBase coverage) ────────

    @IsTest
    static void queryByFilterWithRelationshipColumnFields_returnsResults() {
        String filters = REC_TableHelper.filter()
            .eq('ClosingType__c', new List<String>{ REC_Consts.ClosingType.P_R })
            .toJson();
        String columnFields = JSON.serialize(new List<String>{ 'RefSettlement__r.Name' });

        Test.startTest();
        List<SObject> results = REC_SettlementLineItemSelector.getInstance().queryByFilter(filters, columnFields);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return matching SLIs with relationship fields');
    }

    @IsTest
    static void queryByFilterWithMissingColumnField_throwsException() {
        String filters = REC_TableHelper.filter()
            .eq('ClosingType__c', new List<String>{ REC_Consts.ClosingType.P_R })
            .toJson();
        String columnFields = JSON.serialize(new List<String>{ 'NonExistentField__c' });

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemSelector.getInstance().queryByFilter(filters, columnFields);
            Test.stopTest();
        } catch (REC_SelectorBase.REC_SelectorBaseException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Missing column field should throw REC_SelectorBaseException');
    }

    // ── queryByFilterForEvaluation ─────────────────────────────────────────

    @IsTest
    static void queryByFilterForEvaluation_withoutFilters_returnsEligibleRows() {
        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryByFilterForEvaluation(null, null);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Evaluation query should return non-P_A/P_B/P_C rows without filters');
    }

    @IsTest
    static void queryByFilterForEvaluation_withPeriodCloseStringAndRelationshipFields_returnsMatches() {
        Date endDate = Date.newInstance(2025, 12, 31);
        PeriodClose__c periodClose = new PeriodClose__c(EndDate__c = endDate);
        insert periodClose;

        SettlementLineItem__c target = [
            SELECT Id, AccountingDate__c, SettlementDate__c
            FROM SettlementLineItem__c
            WHERE ClosingType__c = :REC_Consts.ClosingType.P_R
            LIMIT 1
        ];
        target.AccountingDate__c = endDate;
        target.SettlementDate__c = endDate.addDays(1);
        update target;

        String filters = REC_TableHelper.filter()
            .eq('ClosingType__c', new List<String>{ REC_Consts.ClosingType.P_R })
            .toJson();
        Map<String, Object> filterMap = (Map<String, Object>) JSON.deserializeUntyped(filters);
        filterMap.put('PeriodClose__c', periodClose.Id);

        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryByFilterForEvaluation(
                JSON.serialize(filterMap),
                JSON.serialize(new List<String>{ 'RefSettlement__r.Name' })
            );
        Test.stopTest();

        Assert.isTrue(
            new Map<Id, SettlementLineItem__c>(results).containsKey(target.Id),
            'The SLI matching the PeriodClose window should be returned'
        );
    }

    @IsTest
    static void queryByFilterForEvaluation_withPeriodCloseListAndSimpleColumns_returnsMatches() {
        Date endDate = Date.newInstance(2026, 1, 31);
        PeriodClose__c periodClose = new PeriodClose__c(EndDate__c = endDate);
        insert periodClose;

        SettlementLineItem__c target = [
            SELECT Id, AccountingDate__c, SettlementDate__c
            FROM SettlementLineItem__c
            WHERE ClosingType__c = :REC_Consts.ClosingType.P_R
            LIMIT 1
        ];
        target.AccountingDate__c = endDate.addDays(-1);
        target.SettlementDate__c = null;
        update target;

        String filters = REC_TableHelper.filter().eq('Id', new List<String>{ target.Id }).toJson();
        Map<String, Object> filterMap = (Map<String, Object>) JSON.deserializeUntyped(filters);
        filterMap.put('PeriodClose__c', new List<String>{ String.valueOf(periodClose.Id) });

        Test.startTest();
        List<SettlementLineItem__c> results = REC_SettlementLineItemSelector.getInstance()
            .queryByFilterForEvaluation(JSON.serialize(filterMap), JSON.serialize(new List<String>{ 'ClosingType__c' }));
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'The PeriodClose list filter should keep the matching SLI');
        Assert.areEqual(target.Id, results[0].Id, 'The exact filtered SLI should be returned');
    }
}