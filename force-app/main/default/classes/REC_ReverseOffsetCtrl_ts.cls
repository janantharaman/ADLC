/**
 * REC_ReverseOffsetCtrl_ts — Test class for REC_ReverseOffsetCtrl.
 *
 * Coverage targets:
 *  - processReverseOffset  (@InvocableMethod)
 *  - getOffsetSlis         (@AuraEnabled)
 *
 * Object graph created by @TestSetup (via REC_TestDataFactory.setupReverseOffset):
 *
 *   Settlement__c
 *     ├── SettlementLineItem__c  (detailSli,      +1_000_000, Not-Available, P_R)
 *     └── SettlementLineItem__c  (counterpartSli, -1_000_000, Not-Available, P_R)
 */
@IsTest
private class REC_ReverseOffsetCtrl_ts {
    // ─── Shared query helpers ────────────────────────────────────────────────

    private static List<SettlementLineItem__c> getSlis() {
        return [SELECT Id, OriginAmount__c FROM SettlementLineItem__c ORDER BY OriginAmount__c DESC];
    }

    private static List<Id> getSliIds() {
        List<Id> ids = new List<Id>();
        for (SettlementLineItem__c sli : getSlis()) {
            ids.add(sli.Id);
        }
        return ids;
    }

    // ════════════════════════════════════════════════════════════════════════
    //  @TestSetup
    // ════════════════════════════════════════════════════════════════════════

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupReverseOffset();
    }

    // ════════════════════════════════════════════════════════════════════════
    //  processReverseOffset
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testProcessReverseOffsetWithValidSliIdsCreatesConfirmedRecon() {
        List<Id> sliIds = getSliIds();

        REC_ReverseOffsetCtrl.ReverseOffsetRequest req = new REC_ReverseOffsetCtrl.ReverseOffsetRequest();
        req.sliIds = sliIds;

        Test.startTest();
        List<REC_ReverseOffsetCtrl.ReverseOffsetResult> results = REC_ReverseOffsetCtrl.processReverseOffset(
            new List<REC_ReverseOffsetCtrl.ReverseOffsetRequest>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Expected one result');
        Assert.isNotNull(results[0].reconciliationId, 'Reconciliation ID should be returned');

        Reconciliation__c recon = [SELECT Status__c FROM Reconciliation__c WHERE Id = :results[0].reconciliationId];
        Assert.areEqual(
            REC_Consts.ReconciliationStatus.CONFIRMED,
            recon.Status__c,
            'Reconciliation should be in Confirmed status'
        );

        List<SettlementLineItem__c> updatedSlis = [
            SELECT SettlementStatus__c, SettlementType__c, ReconcileNo__c
            FROM SettlementLineItem__c
            WHERE Id IN :sliIds
        ];
        for (SettlementLineItem__c sli : updatedSlis) {
            Assert.areEqual(REC_Consts.SettlementStatus.CLEAR, sli.SettlementStatus__c, 'SLI should be Clear');
            Assert.areEqual(REC_Consts.SettlementType.OFFSET, sli.SettlementType__c, 'SLI should be Off-set');
            Assert.areEqual(results[0].reconciliationId, sli.ReconcileNo__c, 'SLI should reference the recon');
        }
    }

    @IsTest
    static void testProcessReverseOffsetWithEmptySliIdsThrowsAura() {
        REC_ReverseOffsetCtrl.ReverseOffsetRequest req = new REC_ReverseOffsetCtrl.ReverseOffsetRequest();
        req.sliIds = new List<Id>();

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_ReverseOffsetCtrl.processReverseOffset(new List<REC_ReverseOffsetCtrl.ReverseOffsetRequest>{ req });
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for empty SLI IDs');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getOffsetSlis
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetOffsetSlisWithValidReconIdReturnsSlis() {
        List<Id> sliIds = getSliIds();
        Id reconId = REC_ReconciliationDomain.processReverseOffset(sliIds);

        Test.startTest();
        List<SettlementLineItem__c> result = REC_ReverseOffsetCtrl.getOffsetSlis(reconId);
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Expected offset SLIs to be returned');
        Assert.areEqual(sliIds.size(), result.size(), 'All SLIs should be returned as offsets');
    }

    @IsTest
    static void testGetOffsetSlisWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_ReverseOffsetCtrl.getOffsetSlis('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconId');
    }
}