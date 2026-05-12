/**
 * REC_SLIBasedReconCtrl_ts — Test class for REC_SLIBasedReconCtrl.
 *
 * Coverage targets:
 *  - getBaseSettlementLineItem
 *  - inquiryBankTransactions
 *  - getRelatedReconciliationLineItems
 *  - inquiryFiduciaryOthers
 *  - draftSettlementLineItemBased
 *  - confirmSettlementLineItemBased
 *  - getOtherCharges
 *  - getReconciliationStatus
 *
 * Object graph created by @TestSetup (via REC_TestDataFactory.setupSliBasedRecon):
 *
 *   Settlement__c
 *     ├── SettlementLineItem__c  (baseSli,       +1_000_000, Not-Available, P_R)
 *     └── SettlementLineItem__c  (counterpartSli, -1_000_000, Not-Available, P_R)
 *   BankTransaction__c    (KRW, 1_000_000)
 *   FiduciaryOthers__c    (KRW, 1_000_000)
 *   Reconciliation__c     (linked to baseSli via BaseSettlementLineItem__c)
 *     └── ReconciliationLineItem__c  (base SLI RLI)
 */
@IsTest
private class REC_SLIBasedReconCtrl_ts {
    // ─── Shared query helpers ────────────────────────────────────────────────

    private static Reconciliation__c getRecon() {
        return [SELECT Id, Status__c FROM Reconciliation__c LIMIT 1];
    }

    private static BankTransaction__c getBt() {
        return [SELECT Id, OriginAmount__c FROM BankTransaction__c LIMIT 1];
    }

    private static FiduciaryOthers__c getFo() {
        return [SELECT Id, OriginAmount__c FROM FiduciaryOthers__c LIMIT 1];
    }

    // ════════════════════════════════════════════════════════════════════════
    //  @TestSetup
    // ════════════════════════════════════════════════════════════════════════

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupSliBasedRecon();
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getBaseSettlementLineItem
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetBaseSettlementLineItemWithValidIdReturnsSliRli() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        ReconciliationLineItem__c rli = REC_SLIBasedReconCtrl.getBaseSettlementLineItem(recon.Id);
        Test.stopTest();

        Assert.isNotNull(rli, 'Expected an RLI referencing the base SLI');
        Assert.isNotNull(rli.RefSettlementLineItem__c, 'RLI must point to a SettlementLineItem');
    }

    @IsTest
    static void testGetBaseSettlementLineItemWithNoRliReturnsNull() {
        Reconciliation__c emptyRecon = new Reconciliation__c();
        insert emptyRecon;

        Test.startTest();
        ReconciliationLineItem__c result = REC_SLIBasedReconCtrl.getBaseSettlementLineItem(emptyRecon.Id);
        Test.stopTest();

        Assert.isNull(result, 'Expected null when no SLI-linked RLI exists');
    }

    @IsTest
    static void testGetBaseSettlementLineItemWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.getBaseSettlementLineItem('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  inquiryBankTransactions
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testInquiryBankTransactionsNullFiltersReturnsAllBts() {
        Test.startTest();
        List<BankTransaction__c> bts = REC_SLIBasedReconCtrl.inquiryBankTransactions(null, null, null);
        Test.stopTest();

        Assert.isFalse(bts.isEmpty(), 'Expected at least one BankTransaction to be returned');
    }

    @IsTest
    static void testInquiryBankTransactionsWithFilterReturnsMatchingBts() {
        BankTransaction__c bt = getBt();
        String filters = REC_TableHelper.filter().eq('Id', new List<String>{ bt.Id }).toJson();

        Test.startTest();
        List<BankTransaction__c> bts = REC_SLIBasedReconCtrl.inquiryBankTransactions(filters, null, null);
        Test.stopTest();

        Assert.areEqual(1, bts.size(), 'Expected exactly one matching BT');
        Assert.areEqual(bt.Id, bts[0].Id, 'Returned BT should match the filter');
    }

    @IsTest
    static void testInquiryBankTransactionsWithNoMatchesReturnsEmpty() {
        String filters = REC_TableHelper.filter().eq('Depositor__c', new List<String>{ 'NO_MATCH' }).toJson();

        Test.startTest();
        List<BankTransaction__c> bts = REC_SLIBasedReconCtrl.inquiryBankTransactions(filters, null, getRecon().Id);
        Test.stopTest();

        Assert.isTrue(bts.isEmpty(), 'Expected no BankTransactions when the filters match nothing');
    }

    @IsTest
    static void testInquiryBankTransactionsExcludesDraftReferencedBts() {
        Reconciliation__c recon = getRecon();
        BankTransaction__c excludedBt = getBt();
        BankTransaction__c includedBt = REC_TestDataFactory.insertBankTransaction(
            REC_TestDataFactory.DEFAULT_CURRENCY,
            500000,
            REC_TestDataFactory.DEFAULT_BIZ_REGION
        );

        Reconciliation__c otherDraftRecon = new Reconciliation__c(Status__c = REC_Consts.ReconciliationStatus.DRAFT);
        insert otherDraftRecon;
        insert new ReconciliationLineItem__c(
            RefReconciliation__c = otherDraftRecon.Id,
            RefBankTransaction__c = excludedBt.Id
        );

        Test.startTest();
        List<BankTransaction__c> bts = REC_SLIBasedReconCtrl.inquiryBankTransactions(null, null, recon.Id);
        Test.stopTest();

        Assert.areEqual(1, bts.size(), 'Only non-draft-referenced BTs should remain');
        Assert.areEqual(includedBt.Id, bts[0].Id, 'The BT linked to another draft reconciliation should be excluded');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getRelatedReconciliationLineItems
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetRelatedRlisWithExistingBtRliReturnsBtRlis() {
        Reconciliation__c recon = getRecon();
        BankTransaction__c bt = getBt();

        // Simulate a draft-persisted BT-referenced RLI
        insert new ReconciliationLineItem__c(RefReconciliation__c = recon.Id, RefBankTransaction__c = bt.Id);

        Test.startTest();
        List<ReconciliationLineItem__c> rlis = REC_SLIBasedReconCtrl.getRelatedReconciliationLineItems(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, rlis.size(), 'Expected exactly one BT-referenced RLI');
        Assert.areEqual(bt.Id, rlis[0].RefBankTransaction__c, 'RLI should reference the correct BT');
    }

    @IsTest
    static void testGetRelatedRlisWithNoBtRlisReturnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> rlis = REC_SLIBasedReconCtrl.getRelatedReconciliationLineItems(recon.Id);
        Test.stopTest();

        Assert.isTrue(rlis.isEmpty(), 'Expected empty list before any draft has run');
    }

    @IsTest
    static void testGetRelatedRlisWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.getRelatedReconciliationLineItems('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  inquiryFiduciaryOthers
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testInquiryFiduciaryOthersNullFiltersReturnsAllFos() {
        Test.startTest();
        List<FiduciaryOthers__c> fos = REC_SLIBasedReconCtrl.inquiryFiduciaryOthers(null, null, null);
        Test.stopTest();

        Assert.isFalse(fos.isEmpty(), 'Expected at least one FiduciaryOthers to be returned');
    }

    @IsTest
    static void testInquiryFiduciaryOthersWithFilterReturnsMatchingFos() {
        FiduciaryOthers__c fo = getFo();
        String filters = REC_TableHelper.filter().eq('Id', new List<String>{ fo.Id }).toJson();

        Test.startTest();
        List<FiduciaryOthers__c> fos = REC_SLIBasedReconCtrl.inquiryFiduciaryOthers(filters, null, null);
        Test.stopTest();

        Assert.areEqual(1, fos.size(), 'Expected exactly one matching FO');
        Assert.areEqual(fo.Id, fos[0].Id, 'Returned FO should match the filter');
    }

    @IsTest
    static void testInquiryFiduciaryOthersWithNoMatchesReturnsEmpty() {
        String filters = REC_TableHelper.filter().eq('BizRegion__c', new List<String>{ 'NO_MATCH' }).toJson();

        Test.startTest();
        List<FiduciaryOthers__c> fos = REC_SLIBasedReconCtrl.inquiryFiduciaryOthers(filters, null, getRecon().Id);
        Test.stopTest();

        Assert.isTrue(fos.isEmpty(), 'Expected no FiduciaryOthers when the filters match nothing');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  draftSettlementLineItemBased
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testDraftSliBasedWithBtDetailSucceeds() {
        Reconciliation__c recon = getRecon();
        BankTransaction__c bt = getBt();

        List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
            REC_TestDataFactory.createBtReconDetailRli(bt.Id, bt.OriginAmount__c)
        };

        Test.startTest();
        REC_SLIBasedReconCtrl.draftSettlementLineItemBased(recon.Id, details, 0, null);
        Test.stopTest();

        // Recon status should be Draft
        Reconciliation__c reconAfter = [SELECT Status__c FROM Reconciliation__c WHERE Id = :recon.Id];
        Assert.areEqual(
            REC_Consts.ReconciliationStatus.DRAFT,
            reconAfter.Status__c,
            'Recon status should be Draft after draft operation'
        );

        // BT-referenced RLI should now exist
        Integer btRliCount = [
            SELECT COUNT()
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefBankTransaction__c != NULL
        ];
        Assert.areEqual(1, btRliCount, 'One BT-referenced RLI should have been upserted');
    }

    @IsTest
    static void testDraftSliBasedWithEmptyDetailsClearsBaseSliRli() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        REC_SLIBasedReconCtrl.draftSettlementLineItemBased(recon.Id, new List<ReconciliationLineItem__c>(), null, null);
        Test.stopTest();

        // Base SLI RLI should have settlement fields cleared
        ReconciliationLineItem__c baseSliRli = [
            SELECT SettlementAmountTTL__c, SettlementCurrency__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefSettlementLineItem__c != NULL
            LIMIT 1
        ];
        Assert.isNull(baseSliRli.SettlementAmountTTL__c, 'SettlementAmountTTL should be cleared');
    }

    @IsTest
    static void testDraftSliBasedWithOtherChargesUpdatesBaseSliRli() {
        Reconciliation__c recon = getRecon();
        BankTransaction__c bt = getBt();

        List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
            REC_TestDataFactory.createBtReconDetailRli(bt.Id, bt.OriginAmount__c)
        };

        Test.startTest();
        REC_SLIBasedReconCtrl.draftSettlementLineItemBased(recon.Id, details, 500, null);
        Test.stopTest();

        ReconciliationLineItem__c baseSliRli = [
            SELECT OtherCharges__c, SettlementAmountSLI__c, SettlementAmountTTL__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefSettlementLineItem__c != NULL
            LIMIT 1
        ];
        Assert.areEqual(500, baseSliRli.OtherCharges__c, 'OtherCharges should reflect user-entered value');
    }

    @IsTest
    static void testDraftSliBasedWithFoDetailSucceeds() {
        Reconciliation__c recon = getRecon();
        FiduciaryOthers__c fo = getFo();

        List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
            REC_TestDataFactory.createFoReconDetailRli(fo.Id, fo.OriginAmount__c)
        };

        Test.startTest();
        REC_SLIBasedReconCtrl.draftSettlementLineItemBased(recon.Id, details, null, null);
        Test.stopTest();

        // FO-referenced RLI should exist
        Integer foRliCount = [
            SELECT COUNT()
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefFiduciaryOthers__c != NULL
        ];
        Assert.areEqual(1, foRliCount, 'One FO-referenced RLI should have been upserted');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  confirmSettlementLineItemBased
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testConfirmSliBasedWithBtDetailConfirmsRecon() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Reconciliation__c recon = getRecon();
            BankTransaction__c bt = getBt();

            List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
                REC_TestDataFactory.createBtReconDetailRli(bt.Id, bt.OriginAmount__c)
            };

            Test.startTest();
            REC_SLIBasedReconCtrl.confirmSettlementLineItemBased(recon.Id, details, 0, null, null, null);
            Test.stopTest();

            // Recon status = Confirmed
            Reconciliation__c reconAfter = [SELECT Status__c FROM Reconciliation__c WHERE Id = :recon.Id];
            Assert.areEqual(
                REC_Consts.ReconciliationStatus.CONFIRMED,
                reconAfter.Status__c,
                'Recon status should be Confirmed'
            );

            // Base BT must have TotalClearedAmount updated
            BankTransaction__c btAfter = [
                SELECT TotalClearedAmount__c, NetBalanceAftCleared__c
                FROM BankTransaction__c
                WHERE Id = :bt.Id
            ];
            Assert.isNotNull(btAfter.TotalClearedAmount__c, 'BT TotalClearedAmount should be set');
        }
    }

    @IsTest
    static void testConfirmSliBasedWithOtherChargesCreatesPcSlis() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Reconciliation__c recon = getRecon();
            BankTransaction__c bt = getBt();

            List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
                REC_TestDataFactory.createBtReconDetailRli(bt.Id, bt.OriginAmount__c - 1000)
            };

            List<SettlementLineItem__c> otherChargeItems = new List<SettlementLineItem__c>{
                new SettlementLineItem__c(
                    OriginAmount__c = 500,
                    OriginCurrency__c = REC_TestDataFactory.DEFAULT_CURRENCY,
                    BizRegion__c = REC_TestDataFactory.DEFAULT_BIZ_REGION
                )
            };

            Test.startTest();
            REC_SLIBasedReconCtrl.confirmSettlementLineItemBased(recon.Id, details, 500, null, otherChargeItems, null);
            Test.stopTest();

            Assert.areEqual(
                REC_Consts.ReconciliationStatus.CONFIRMED,
                [SELECT Status__c FROM Reconciliation__c WHERE Id = :recon.Id].Status__c,
                'Recon should be Confirmed'
            );

            Integer pcCount = [
                SELECT COUNT()
                FROM SettlementLineItem__c
                WHERE ClosingType__c = 'P_C' AND OriginReconciliationNo__c = :recon.Id
            ];
            Assert.areEqual(1, pcCount, 'Exactly one P_C SLI should be created');
        }
    }

    @IsTest
    static void testConfirmSliBasedWithBaseSliInputAppliesUserFields() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Reconciliation__c recon = getRecon();
            BankTransaction__c bt = getBt();

            List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
                REC_TestDataFactory.createBtReconDetailRli(bt.Id, bt.OriginAmount__c)
            };

            SettlementLineItem__c baseSliInput = new SettlementLineItem__c(
                ExchangeDate__c = Date.today(),
                ExchangeCurrency__c = REC_TestDataFactory.DEFAULT_CURRENCY,
                ExchangeAmount__c = 500000,
                ExchangeRate__c = 1.0
            );

            Test.startTest();
            REC_SLIBasedReconCtrl.confirmSettlementLineItemBased(recon.Id, details, 0, baseSliInput, null, null);
            Test.stopTest();

            // Base SLI should have exchange fields populated
            SettlementLineItem__c baseSliAfter = [
                SELECT ExchangeDate__c, ExchangeAmount__c
                FROM SettlementLineItem__c
                WHERE OriginAmount__c > 0
                LIMIT 1
            ];
            Assert.areEqual(Date.today(), baseSliAfter.ExchangeDate__c, 'ExchangeDate should be set from baseSliInput');
            Assert.areEqual(500000, baseSliAfter.ExchangeAmount__c, 'ExchangeAmount should be set from baseSliInput');
        }
    }

    @IsTest
    static void testConfirmSliBasedEmptyDetailsThrowsAura() {
        Reconciliation__c recon = getRecon();

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.confirmSettlementLineItemBased(
                recon.Id,
                new List<ReconciliationLineItem__c>(),
                null,
                null,
                null,
                null
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException when details is empty');
    }

    @IsTest
    static void testConfirmSliBasedBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.confirmSettlementLineItemBased(
                '',
                new List<ReconciliationLineItem__c>{ new ReconciliationLineItem__c() },
                null,
                null,
                null,
                null
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getPcOtherChargesRlis
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetPcOtherChargesRlisWithExistingRowsReturnsRlis() {
        Reconciliation__c recon = getRecon();
        BankTransaction__c bt = getBt();

        insert new ReconciliationLineItem__c(
            RefReconciliation__c = recon.Id,
            RefBankTransaction__c = bt.Id,
            IsOtherCharges__c = true
        );

        Test.startTest();
        List<ReconciliationLineItem__c> result = REC_SLIBasedReconCtrl.getPcOtherChargesRlis(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected one P_C RLI to be returned');
        Assert.areEqual(bt.Id, result[0].RefBankTransaction__c, 'The returned RLI should match the inserted BT reference');
    }

    @IsTest
    static void testGetPcOtherChargesRlisWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.getPcOtherChargesRlis('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getOtherCharges
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetOtherChargesWithExistingPcSliReturnsPcSlis() {
        Reconciliation__c recon = getRecon();

        // Insert a P_C SLI directly (simulates post-Confirm state)
        insert REC_TestDataFactory.createOtherChargeSli(
            recon.Id,
            200,
            REC_TestDataFactory.DEFAULT_CURRENCY,
            REC_TestDataFactory.DEFAULT_BIZ_REGION
        );

        Test.startTest();
        List<SettlementLineItem__c> otherCharges = REC_SLIBasedReconCtrl.getOtherCharges(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, otherCharges.size(), 'Expected one P_C SLI');
        Assert.areEqual(REC_Consts.ClosingType.P_C, otherCharges[0].ClosingType__c, 'ClosingType should be P_C');
    }

    @IsTest
    static void testGetOtherChargesWithNoPcSlisReturnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<SettlementLineItem__c> otherCharges = REC_SLIBasedReconCtrl.getOtherCharges(recon.Id);
        Test.stopTest();

        Assert.isTrue(otherCharges.isEmpty(), 'No P_C SLIs should exist before Confirm');
    }

    @IsTest
    static void testGetOtherChargesWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.getOtherCharges('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getReconciliationStatus
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetReconciliationStatusReturnsCurrentStatus() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        String status = REC_SLIBasedReconCtrl.getReconciliationStatus(recon.Id);
        Test.stopTest();

        Assert.isNotNull(status, 'Status should not be null');
    }

    @IsTest
    static void testGetReconciliationStatusWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SLIBasedReconCtrl.getReconciliationStatus('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  Catch-block coverage (generic Exception → AuraHandledException path)
    //
    //  ExceptionSimulator.throwIfActive() fires before business logic,
    //  so the catch (Exception e) block in each method is exercised.
    //  One combined test avoids repetitive boilerplate — the auto-reset
    //  (active = false inside throwIfActive) keeps each sub-call isolated.
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testCatchBlocksThrowAuraOnUnexpectedException() {
        Reconciliation__c recon = getRecon();

        Test.startTest();

        // getBaseSettlementLineItem
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.getBaseSettlementLineItem(recon.Id);
            Assert.fail('getBaseSettlementLineItem should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getBaseSettlementLineItem exception message should not be null');
        }

        // inquiryBankTransactions
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.inquiryBankTransactions(null, null, null);
            Assert.fail('inquiryBankTransactions should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'inquiryBankTransactions exception message should not be null');
        }

        // getRelatedReconciliationLineItems
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.getRelatedReconciliationLineItems(recon.Id);
            Assert.fail('getRelatedRlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getRelatedRlis exception message should not be null');
        }

        // inquiryFiduciaryOthers
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.inquiryFiduciaryOthers(null, null, null);
            Assert.fail('inquiryFiduciaryOthers should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'inquiryFiduciaryOthers exception message should not be null');
        }

        // draftSettlementLineItemBased
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.draftSettlementLineItemBased(recon.Id, new List<ReconciliationLineItem__c>(), null, null);
            Assert.fail('draftSliBased should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'draftSliBased exception message should not be null');
        }

        // confirmSettlementLineItemBased
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.confirmSettlementLineItemBased(
                recon.Id,
                new List<ReconciliationLineItem__c>{ new ReconciliationLineItem__c() },
                null,
                null,
                null,
                null
            );
            Assert.fail('confirmSliBased should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'confirmSliBased exception message should not be null');
        }

        // getPcOtherChargesRlis
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.getPcOtherChargesRlis(recon.Id);
            Assert.fail('getPcOtherChargesRlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getPcOtherChargesRlis exception message should not be null');
        }

        // getOtherCharges
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.getOtherCharges(recon.Id);
            Assert.fail('getOtherCharges should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getOtherCharges exception message should not be null');
        }

        // getReconciliationStatus
        ExceptionSimulator.active = true;
        try {
            REC_SLIBasedReconCtrl.getReconciliationStatus(recon.Id);
            Assert.fail('getReconciliationStatus should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getReconciliationStatus exception message should not be null');
        }

        Test.stopTest();
    }
}