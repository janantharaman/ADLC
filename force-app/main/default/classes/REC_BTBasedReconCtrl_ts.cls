/**
 * REC_BTBasedReconCtrl_ts — Test class for REC_BTBasedReconCtrl.
 *
 * Coverage targets:
 *  - getBaseBankTransaction
 *  - inquirySettlementLineItems
 *  - getRelatedReconciliationLineItems
 *  - getSliIdsAlreadyReconciled
 *  - getReconciliationStatus
 *  - draftBankTransactionBased
 *  - confirmBankTransactionBased
 *  - getOtherCharges
 *  - validateSettlementLineItems
 *
 * Object graph created by @TestSetup (via REC_TestDataFactory.setupBtBasedRecon):
 *
 *   Settlement__c
 *     ├── SettlementLineItem__c  (detailSli,      +1_000_000, Not-Available, P_R)
 *     └── SettlementLineItem__c  (counterpartSli, -1_000_000, Not-Available, P_R)
 *   BankTransaction__c   (KRW, 1_000_000)
 *   Reconciliation__c    (linked to BT via BaseBankTransaction__c)
 *     └── ReconciliationLineItem__c  (base BT RLI)
 */
@IsTest
private class REC_BTBasedReconCtrl_ts {
    // ─── Shared query helpers ────────────────────────────────────────────────

    private static Reconciliation__c getRecon() {
        return [SELECT Id, Status__c FROM Reconciliation__c LIMIT 1];
    }

    private static SettlementLineItem__c getDetailSli() {
        // Positive OriginAmount SLI = the "main" side of the counterpart pair
        return [
            SELECT Id, OriginAmount__c, SettlementStatus__c, ClosingType__c
            FROM SettlementLineItem__c
            WHERE OriginAmount__c > 0
            LIMIT 1
        ];
    }

    // ════════════════════════════════════════════════════════════════════════
    //  @TestSetup
    // ════════════════════════════════════════════════════════════════════════

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.BtBasedReconContext ctx = REC_TestDataFactory.setupBtBasedRecon();
        ctx.detailSli.Status__c = REC_Consts.STCStatus.CONFIRM;
        update ctx.detailSli;
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getBaseBankTransaction
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetBaseBankTransactionWithValidIdReturnsBtRli() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        ReconciliationLineItem__c rli = REC_BTBasedReconCtrl.getBaseBankTransaction(recon.Id);
        Test.stopTest();

        Assert.isNotNull(rli, 'Expected an RLI referencing the base BT');
        Assert.isNotNull(rli.RefBankTransaction__c, 'RLI must point to a BankTransaction');
    }

    @IsTest
    static void testGetBaseBankTransactionWithNoRliReturnsNull() {
        // Reconciliation that has no BT-referenced RLI at all
        Reconciliation__c emptyRecon = new Reconciliation__c();
        insert emptyRecon;

        Test.startTest();
        ReconciliationLineItem__c result = REC_BTBasedReconCtrl.getBaseBankTransaction(emptyRecon.Id);
        Test.stopTest();

        Assert.isNull(result, 'Expected null when no BT-linked RLI exists');
    }

    @IsTest
    static void testGetBaseBankTransactionWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BTBasedReconCtrl.getBaseBankTransaction('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  inquirySettlementLineItems
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testInquirySettlementLineItemsNullFiltersReturnsAllSlis() {
        Test.startTest();
        List<SettlementLineItem__c> slis = REC_BTBasedReconCtrl.inquirySettlementLineItems(null, null);
        Test.stopTest();

        // @TestSetup inserts 2 SLIs (the counterpart pair)
        Assert.isFalse(slis.isEmpty(), 'Expected at least one SLI to be returned');
    }

    @IsTest
    static void testInquirySettlementLineItemsClosingTypeFilterReturnsMatchingSlis() {
        String filters = REC_TableHelper.filter()
            .eq('ClosingType__c', new List<String>{ REC_Consts.ClosingType.P_R })
            .toJson();

        Test.startTest();
        List<SettlementLineItem__c> slis = REC_BTBasedReconCtrl.inquirySettlementLineItems(filters, null);
        Test.stopTest();

        Assert.isFalse(slis.isEmpty(), 'Expected P_R SLIs to be returned');
        for (SettlementLineItem__c s : slis) {
            Assert.areEqual(REC_Consts.ClosingType.P_R, s.ClosingType__c, 'Expected P_R ClosingType');
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getRelatedReconciliationLineItems
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetRelatedRlisWithExistingSliRliReturnsSliRlis() {
        Reconciliation__c recon = getRecon();
        SettlementLineItem__c sli = getDetailSli();

        // Simulate a draft-persisted SLI-referenced RLI
        insert new ReconciliationLineItem__c(RefReconciliation__c = recon.Id, RefSettlementLineItem__c = sli.Id);

        Test.startTest();
        List<ReconciliationLineItem__c> rlis = REC_BTBasedReconCtrl.getRelatedReconciliationLineItems(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, rlis.size(), 'Expected exactly one SLI-referenced RLI');
        Assert.areEqual(sli.Id, rlis[0].RefSettlementLineItem__c, 'RLI should reference the correct SLI');
    }

    @IsTest
    static void testGetRelatedRlisWithNoSliRlisReturnsEmpty() {
        Reconciliation__c recon = getRecon();
        // Base BT RLI exists but no SLI-referenced RLIs yet

        Test.startTest();
        List<ReconciliationLineItem__c> rlis = REC_BTBasedReconCtrl.getRelatedReconciliationLineItems(recon.Id);
        Test.stopTest();

        Assert.isTrue(rlis.isEmpty(), 'Expected empty list before any draft has run');
    }

    @IsTest
    static void testGetRelatedRlisWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BTBasedReconCtrl.getRelatedReconciliationLineItems('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getSliIdsAlreadyReconciled
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetSliIdsAlreadyReconciledWithReconciledSliReturnsItsId() {
        Reconciliation__c recon = getRecon();
        SettlementLineItem__c sli = getDetailSli();

        // Create a second Draft Reconciliation with an RLI referencing the same SLI
        Reconciliation__c otherRecon = new Reconciliation__c(Status__c = 'Draft');
        insert otherRecon;
        insert new ReconciliationLineItem__c(RefReconciliation__c = otherRecon.Id, RefSettlementLineItem__c = sli.Id);

        Test.startTest();
        // Exclude current recon — the SLI should still be flagged because of otherRecon
        List<Id> result = REC_BTBasedReconCtrl.getSliIdsAlreadyReconciled(new List<Id>{ sli.Id }, recon.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected one reconciled SLI Id');
        Assert.areEqual(sli.Id, result[0], 'Returned Id should match the reconciled SLI');
    }

    @IsTest
    static void testGetSliIdsAlreadyReconciledWithUnreconciledSliReturnsEmpty() {
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();
        List<Id> result = REC_BTBasedReconCtrl.getSliIdsAlreadyReconciled(new List<Id>{ sli.Id }, null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'SLI without an RLI should not be returned');
    }

    @IsTest
    static void testGetSliIdsAlreadyReconciledEmptyInputReturnsEmpty() {
        Test.startTest();
        List<Id> result = REC_BTBasedReconCtrl.getSliIdsAlreadyReconciled(new List<Id>(), null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should produce empty output');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getReconciliationStatus
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetReconciliationStatusReturnsCurrentStatus() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        String status = REC_BTBasedReconCtrl.getReconciliationStatus(recon.Id);
        Test.stopTest();

        Assert.isNotNull(status, 'Status should not be null');
    }

    @IsTest
    static void testGetReconciliationStatusWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BTBasedReconCtrl.getReconciliationStatus('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  draftBankTransactionBased
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testDraftBankTransactionBasedWithDetailsReturnsOkAndUpdatesBtRli() {
        Reconciliation__c recon = getRecon();
        SettlementLineItem__c sli = getDetailSli();

        List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
            REC_TestDataFactory.createSliDetailRli(sli.Id, REC_TestDataFactory.DEFAULT_FX_RATE)
        };

        Test.startTest();
        REC_Response response = REC_BTBasedReconCtrl.draftBankTransactionBased(recon.Id, details, null);
        Test.stopTest();

        Assert.isTrue(response.success, 'Draft should succeed');

        // Base BT RLI TotalClearedAmount must reflect the selected SLI's SettlementAmountTTL
        ReconciliationLineItem__c btRli = [
            SELECT TotalClearedAmount__c, NetAmountAfterClearing__c, BTStatus__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefBankTransaction__c != NULL
            LIMIT 1
        ];
        Assert.isNotNull(btRli.TotalClearedAmount__c, 'TotalClearedAmount should be set after draft');

        // SLI-referenced RLI should now exist
        Integer sliRliCount = [
            SELECT COUNT()
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefSettlementLineItem__c != NULL
        ];
        Assert.areEqual(1, sliRliCount, 'One SLI-referenced RLI should have been upserted');

        // Recon status should be Draft
        Reconciliation__c reconAfter = [SELECT Status__c FROM Reconciliation__c WHERE Id = :recon.Id];
        Assert.areEqual(
            REC_Consts.ReconciliationStatus.DRAFT,
            reconAfter.Status__c,
            'Recon status should be Draft after draft operation'
        );
    }

    @IsTest
    static void testDraftBankTransactionBasedEmptyDetailsClearsBtRliAndReturnsOk() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        REC_Response response = REC_BTBasedReconCtrl.draftBankTransactionBased(
            recon.Id,
            new List<ReconciliationLineItem__c>(),
            null
        );
        Test.stopTest();

        Assert.isTrue(response.success, 'Empty draft should return OK');

        ReconciliationLineItem__c btRli = [
            SELECT TotalClearedAmount__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :recon.Id AND RefBankTransaction__c != NULL
            LIMIT 1
        ];
        Assert.areEqual(0, btRli.TotalClearedAmount__c, 'TotalClearedAmount should be reset to 0');
    }

    @IsTest
    static void testDraftBankTransactionBasedInvalidSliTypeReturnsValidationErrors() {
        Reconciliation__c recon = getRecon();
        SettlementLineItem__c sli = getDetailSli(); // positive amount, Not-Available

        // Funded type requires negative OriginAmount + Not-Available → invalid for detailSli
        List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
            new ReconciliationLineItem__c(
                RefSettlementLineItem__c = sli.Id,
                FXRateOrigintoSettlement__c = REC_TestDataFactory.DEFAULT_FX_RATE,
                SettlementType__c = REC_Consts.SettlementType.FUNDED
            )
        };

        Test.startTest();
        REC_Response response = REC_BTBasedReconCtrl.draftBankTransactionBased(recon.Id, details, null);
        Test.stopTest();

        Assert.isFalse(response.success, 'Funded type on positive SLI should fail validation');
        Assert.isFalse(response.cellErrors.isEmpty(), 'Expected CellErrors for SettlementType__c violation');
        Assert.areEqual('SettlementType__c', response.cellErrors[0].fieldName, 'CellError should target SettlementType__c');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  confirmBankTransactionBased
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testConfirmBankTransactionBasedNormalSliConfirmsReconAndUpdatesBt() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Reconciliation__c recon = getRecon();
            SettlementLineItem__c sli = getDetailSli();

            List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
                REC_TestDataFactory.createSliDetailRli(sli.Id, REC_TestDataFactory.DEFAULT_FX_RATE)
            };

            Test.startTest();
            REC_Response response = REC_BTBasedReconCtrl.confirmBankTransactionBased(recon.Id, details, null, null);
            Test.stopTest();

            Assert.isTrue(response.success, 'Confirm should succeed');

            // Recon status = Confirmed
            Reconciliation__c reconAfter = [SELECT Status__c FROM Reconciliation__c WHERE Id = :recon.Id];
            Assert.areEqual(
                REC_Consts.ReconciliationStatus.CONFIRMED,
                reconAfter.Status__c,
                'Recon status should be Confirmed'
            );

            // Base BT must have TotalClearedAmount updated
            BankTransaction__c btAfter = [
                SELECT TotalClearedAmount__c, NetBalanceAftCleared__c, Status__c
                FROM BankTransaction__c
                LIMIT 1
            ];
            Assert.isNotNull(btAfter.TotalClearedAmount__c, 'BT TotalClearedAmount should be set');

            // Detail SLI must have SettlementDate set
            SettlementLineItem__c sliAfter = [
                SELECT SettlementDate__c, SettlementCurrency__c
                FROM SettlementLineItem__c
                WHERE Id = :sli.Id
            ];
            Assert.isNotNull(sliAfter.SettlementDate__c, 'SLI SettlementDate should be set after confirm');
        }
    }

    @IsTest
    static void testConfirmBankTransactionBasedWithOtherChargesCreatesPcSlis() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Reconciliation__c recon = getRecon();
            SettlementLineItem__c sli = getDetailSli();

            List<ReconciliationLineItem__c> details = new List<ReconciliationLineItem__c>{
                REC_TestDataFactory.createSliDetailRli(sli.Id, REC_TestDataFactory.DEFAULT_FX_RATE)
            };

            // Other Charge item: user-entered, linked to recon by the domain during Confirm
            List<SettlementLineItem__c> otherChargeItems = new List<SettlementLineItem__c>{
                new SettlementLineItem__c(
                    OriginAmount__c = 500,
                    OriginCurrency__c = REC_TestDataFactory.DEFAULT_CURRENCY,
                    BizRegion__c = REC_TestDataFactory.DEFAULT_BIZ_REGION
                )
            };

            Test.startTest();
            REC_Response response = REC_BTBasedReconCtrl.confirmBankTransactionBased(
                recon.Id,
                details,
                otherChargeItems,
                null
            );
            Test.stopTest();

            Assert.isTrue(response.success, 'Confirm with Other Charges should succeed');

            Integer pcCount = [
                SELECT COUNT()
                FROM SettlementLineItem__c
                WHERE ClosingType__c = 'P_C' AND OriginReconciliationNo__c = :recon.Id
            ];
            Assert.areEqual(1, pcCount, 'Exactly one P_C SLI should be created');
        }
    }

    @IsTest
    static void testConfirmBankTransactionBasedEmptyDetailsThrowsAura() {
        Reconciliation__c recon = getRecon();

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BTBasedReconCtrl.confirmBankTransactionBased(recon.Id, new List<ReconciliationLineItem__c>(), null, null);
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException when details is empty');
    }

    @IsTest
    static void testConfirmBankTransactionBasedBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BTBasedReconCtrl.confirmBankTransactionBased(
                '',
                new List<ReconciliationLineItem__c>{ new ReconciliationLineItem__c() },
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
        List<SettlementLineItem__c> otherCharges = REC_BTBasedReconCtrl.getOtherCharges(recon.Id);
        Test.stopTest();

        Assert.areEqual(1, otherCharges.size(), 'Expected one P_C SLI');
        Assert.areEqual(REC_Consts.ClosingType.P_C, otherCharges[0].ClosingType__c, 'ClosingType should be P_C');
    }

    @IsTest
    static void testGetOtherChargesWithNoPcSlisReturnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<SettlementLineItem__c> otherCharges = REC_BTBasedReconCtrl.getOtherCharges(recon.Id);
        Test.stopTest();

        Assert.isTrue(otherCharges.isEmpty(), 'No P_C SLIs should exist before Confirm');
    }

    @IsTest
    static void testGetOtherChargesWithBlankIdThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_BTBasedReconCtrl.getOtherCharges('');
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for blank reconciliationId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  validateSettlementLineItems
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testValidateSliNormalTypePositiveNotAvailableReturnsEmpty() {
        // Positive OriginAmount + Not-Available → Normal is valid
        SettlementLineItem__c sli = new SettlementLineItem__c(
            SettlementType__c = REC_Consts.SettlementType.NORMAL,
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BTBasedReconCtrl.validateSettlementLineItems(
            new List<SettlementLineItem__c>{ sli }
        );
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Normal type on positive Not-Available SLI should be valid');
    }

    @IsTest
    static void testValidateSliFundedTypePositiveNotAvailableReturnsCellError() {
        // Positive OriginAmount + Not-Available → Funded is INVALID
        // (Funded requires negative OriginAmount + Not-Available)
        SettlementLineItem__c sli = new SettlementLineItem__c(
            SettlementType__c = REC_Consts.SettlementType.FUNDED,
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BTBasedReconCtrl.validateSettlementLineItems(
            new List<SettlementLineItem__c>{ sli }
        );
        Test.stopTest();

        Assert.isFalse(errors.isEmpty(), 'Expected a CellError for invalid Funded type');
        Assert.areEqual('SettlementType__c', errors[0].fieldName, 'CellError should target SettlementType__c');
    }

    @IsTest
    static void testValidateSliFundedTypeNegativeNotAvailableReturnsEmpty() {
        // Negative OriginAmount + Not-Available → Funded is valid
        SettlementLineItem__c sli = new SettlementLineItem__c(
            SettlementType__c = REC_Consts.SettlementType.FUNDED,
            OriginAmount__c = -1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BTBasedReconCtrl.validateSettlementLineItems(
            new List<SettlementLineItem__c>{ sli }
        );
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Funded type on negative Not-Available SLI should be valid');
    }

    @IsTest
    static void testValidateSliNoSettlementTypeReturnsEmpty() {
        // Blank SettlementType__c → validation is skipped
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BTBasedReconCtrl.validateSettlementLineItems(
            new List<SettlementLineItem__c>{ sli }
        );
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Blank SettlementType should produce no errors');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getPcOtherChargesRlis
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetPcOtherChargesRlis_validRecon_returnsRlis() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> result = REC_BTBasedReconCtrl.getPcOtherChargesRlis(recon.Id);
        Test.stopTest();

        // May be empty if no P_C RLIs exist — just verify no exception
        Assert.isNotNull(result);
    }

    @IsTest
    static void testGetPcOtherChargesRlis_blankId_throwsAura() {
        try {
            REC_BTBasedReconCtrl.getPcOtherChargesRlis('');
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    //  inquiryNotes
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testInquiryNotes_nullFilters_returnsNotes() {
        Test.startTest();
        List<COM_Note__c> result = REC_BTBasedReconCtrl.inquiryNotes(null, null);
        Test.stopTest();

        Assert.isNotNull(result);
    }

    // ════════════════════════════════════════════════════════════════════════
    //  getRelatedSlis (by Note IDs)
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testGetRelatedSlis_emptyList_returnsEmpty() {
        Test.startTest();
        List<SettlementLineItem__c> result = REC_BTBasedReconCtrl.getRelatedSlis(new List<Id>());
        Test.stopTest();

        Assert.isNotNull(result);
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
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();

        // getBaseBankTransaction
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getBaseBankTransaction(recon.Id);
            Assert.fail('getBaseBankTransaction should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getBaseBankTransaction exception message should not be null');
        }

        // inquirySettlementLineItems
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.inquirySettlementLineItems(null, null);
            Assert.fail('inquirySettlementLineItems should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'inquirySettlementLineItems exception message should not be null');
        }

        // getRelatedReconciliationLineItems
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getRelatedReconciliationLineItems(recon.Id);
            Assert.fail('getRelatedRlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getRelatedRlis exception message should not be null');
        }

        // getSliIdsAlreadyReconciled
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getSliIdsAlreadyReconciled(new List<Id>{ sli.Id }, null);
            Assert.fail('getSliIdsAlreadyReconciled should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getSliIdsAlreadyReconciled exception message should not be null');
        }

        // getReconciliationStatus
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getReconciliationStatus(recon.Id);
            Assert.fail('getReconciliationStatus should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getReconciliationStatus exception message should not be null');
        }

        // draftBankTransactionBased
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.draftBankTransactionBased(recon.Id, new List<ReconciliationLineItem__c>(), null);
            Assert.fail('draftBtBased should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'draftBtBased exception message should not be null');
        }

        // confirmBankTransactionBased
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.confirmBankTransactionBased(
                recon.Id,
                new List<ReconciliationLineItem__c>{ new ReconciliationLineItem__c() },
                null,
                null
            );
            Assert.fail('confirmBtBased should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'confirmBtBased exception message should not be null');
        }

        // getOtherCharges
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getOtherCharges(recon.Id);
            Assert.fail('getOtherCharges should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getOtherCharges exception message should not be null');
        }

        // validateSettlementLineItems
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.validateSettlementLineItems(new List<SettlementLineItem__c>());
            Assert.fail('validateSlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'validateSlis exception message should not be null');
        }

        // getPcOtherChargesRlis
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getPcOtherChargesRlis(recon.Id);
            Assert.fail('getPcOtherChargesRlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getPcOtherChargesRlis exception message should not be null');
        }

        // inquiryNotes
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.inquiryNotes(null, null);
            Assert.fail('inquiryNotes should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'inquiryNotes exception message should not be null');
        }

        // getRelatedSlis
        ExceptionSimulator.active = true;
        try {
            REC_BTBasedReconCtrl.getRelatedSlis(new List<Id>());
            Assert.fail('getRelatedSlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'getRelatedSlis exception message should not be null');
        }

        Test.stopTest();
    }
}