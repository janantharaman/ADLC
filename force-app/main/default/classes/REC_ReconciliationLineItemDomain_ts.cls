/**
 * REC_ReconciliationLineItemDomain_ts — Test class for REC_ReconciliationLineItemDomain.
 *
 * Coverage targets:
 *  - checkNewReconciliationDisabled  (all branches: SLI Clear, BT Clear, Draft RLI, normal)
 */
@IsTest
private class REC_ReconciliationLineItemDomain_ts {
    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupBtBasedRecon();
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static BankTransaction__c getBt() {
        return [SELECT Id, Status__c FROM BankTransaction__c LIMIT 1];
    }

    private static SettlementLineItem__c getPositiveSli() {
        return [
            SELECT Id, SettlementStatus__c
            FROM SettlementLineItem__c
            WHERE OriginAmount__c > 0
            LIMIT 1
        ];
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkNewReconciliationDisabled — Null / Empty
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkNewReconciliationDisabled_nullInput_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null input should return empty map');
    }

    @IsTest
    static void checkNewReconciliationDisabled_emptyInput_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(new Set<Id>());
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should return empty map');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkNewReconciliationDisabled — BT Status = Clear → disabled
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkNewReconciliationDisabled_btClear_returnsTrue() {
        BankTransaction__c bt = getBt();
        bt.Status__c = 'Clear';
        // Wrap update in runAs to satisfy the BankAccount__c lookup filter on UAT
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            update bt;
        }

        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(new Set<Id>{ bt.Id });
        Test.stopTest();

        Assert.isTrue(result.get(bt.Id), 'BT with Clear status should be disabled');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkNewReconciliationDisabled — SLI SettlementStatus = Clear → disabled
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkNewReconciliationDisabled_sliClear_returnsTrue() {
        SettlementLineItem__c sli = getPositiveSli();
        sli.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;
        update sli;

        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(new Set<Id>{ sli.Id });
        Test.stopTest();

        Assert.isTrue(result.get(sli.Id), 'SLI with Clear status should be disabled');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkNewReconciliationDisabled — Draft RLI exists → disabled
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkNewReconciliationDisabled_draftRliExists_returnsTrue() {
        // setupBtBasedRecon creates a Draft reconciliation with an RLI pointing to the BT
        BankTransaction__c bt = getBt();

        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(new Set<Id>{ bt.Id });
        Test.stopTest();

        Assert.isTrue(result.get(bt.Id), 'BT with a Draft RLI should be disabled');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkNewReconciliationDisabled — Normal (not disabled)
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkNewReconciliationDisabled_noDraftNoStatus_returnsFalse() {
        // Create a fresh BT that has no reconciliation relationship
        BankTransaction__c freshBt = REC_TestDataFactory.insertBankTransaction(
            REC_Consts.CCY.KRW,
            500000,
            REC_Consts.BizRegion.LK_KR
        );

        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(new Set<Id>{ freshBt.Id });
        Test.stopTest();

        Assert.isFalse(result.get(freshBt.Id), 'Fresh BT without Draft RLI should not be disabled');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkNewReconciliationDisabled — Mixed SLI + BT
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkNewReconciliationDisabled_mixedSliAndBt_returnsCorrectMap() {
        BankTransaction__c bt = getBt();
        SettlementLineItem__c sli = getPositiveSli();

        Test.startTest();
        Map<Id, Boolean> result = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(
            new Set<Id>{ bt.Id, sli.Id }
        );
        Test.stopTest();

        Assert.isNotNull(result.get(bt.Id), 'BT should be present in result');
        Assert.isNotNull(result.get(sli.Id), 'SLI should be present in result');
    }
}