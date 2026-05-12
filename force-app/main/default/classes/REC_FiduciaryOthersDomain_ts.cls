/**
 * REC_FiduciaryOthersDomain_ts — Test class for REC_FiduciaryOthersDomain.
 *
 * Coverage targets:
 *  - decideStatus
 *  - applyReconciledAmount
 *  - rollbackReconciledAmount
 *  - validate
 */
@IsTest
private class REC_FiduciaryOthersDomain_ts {
    // ═════════════════════════════════════════════════════════════════════════
    //  decideStatus
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void decideStatus_zeroNotReconciled_returnsClear() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(NotReconciledAMT__c = 0);
        Assert.areEqual('Clear', REC_FiduciaryOthersDomain.decideStatus(fo));
    }

    @IsTest
    static void decideStatus_positiveNotReconciled_returnsPartial() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(NotReconciledAMT__c = 500);
        Assert.areEqual('Partial', REC_FiduciaryOthersDomain.decideStatus(fo));
    }

    @IsTest
    static void decideStatus_negativeNotReconciled_returnsNull() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(NotReconciledAMT__c = -100);
        Assert.areEqual(null, REC_FiduciaryOthersDomain.decideStatus(fo));
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  applyReconciledAmount
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void applyReconciledAmount_fullAmount_setsClear() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(
            OriginAmount__c = 1000,
            ReconciledAMT__c = 0,
            NotReconciledAMT__c = 1000
        );

        Test.startTest();
        REC_FiduciaryOthersDomain.applyReconciledAmount(fo, 1000);
        Test.stopTest();

        Assert.areEqual(1000, fo.ReconciledAMT__c, 'ReconciledAMT should be fully applied');
        Assert.areEqual(0, fo.NotReconciledAMT__c, 'NotReconciledAMT should be zero');
        Assert.areEqual('Clear', fo.Status__c, 'Status should be Clear');
    }

    @IsTest
    static void applyReconciledAmount_partialAmount_setsPartial() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(
            OriginAmount__c = 1000,
            ReconciledAMT__c = 0,
            NotReconciledAMT__c = 1000
        );

        Test.startTest();
        REC_FiduciaryOthersDomain.applyReconciledAmount(fo, 400);
        Test.stopTest();

        Assert.areEqual(400, fo.ReconciledAMT__c, 'ReconciledAMT should reflect partial');
        Assert.areEqual(600, fo.NotReconciledAMT__c, 'NotReconciledAMT should be remaining');
        Assert.areEqual('Partial', fo.Status__c, 'Status should be Partial');
    }

    @IsTest
    static void applyReconciledAmount_nullReconciled_treatedAsZero() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(
            OriginAmount__c = 1000,
            ReconciledAMT__c = null,
            NotReconciledAMT__c = 1000
        );

        Test.startTest();
        REC_FiduciaryOthersDomain.applyReconciledAmount(fo, 500);
        Test.stopTest();

        Assert.areEqual(500, fo.ReconciledAMT__c, 'Null ReconciledAMT should be treated as 0');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  rollbackReconciledAmount
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void rollbackReconciledAmount_fullRollback_restoresOriginal() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(
            OriginAmount__c = 1000,
            ReconciledAMT__c = 1000,
            NotReconciledAMT__c = 0
        );

        Test.startTest();
        REC_FiduciaryOthersDomain.rollbackReconciledAmount(fo, 1000);
        Test.stopTest();

        Assert.areEqual(0, fo.ReconciledAMT__c, 'ReconciledAMT should be zero after full rollback');
        Assert.areEqual(1000, fo.NotReconciledAMT__c, 'NotReconciledAMT should be restored');
        Assert.areEqual('Partial', fo.Status__c, 'Status should be Partial (positive not-reconciled)');
    }

    @IsTest
    static void rollbackReconciledAmount_partialRollback_updatesCorrectly() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(
            OriginAmount__c = 1000,
            ReconciledAMT__c = 600,
            NotReconciledAMT__c = 400
        );

        Test.startTest();
        REC_FiduciaryOthersDomain.rollbackReconciledAmount(fo, 600);
        Test.stopTest();

        Assert.areEqual(0, fo.ReconciledAMT__c, 'ReconciledAMT should be zero');
        Assert.areEqual(1000, fo.NotReconciledAMT__c, 'NotReconciledAMT should be fully restored');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  validate
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void validate_emptyList_returnsNoErrors() {
        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_FiduciaryOthersDomain.validate(new List<FiduciaryOthers__c>());
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Empty list should produce no errors');
    }

    @IsTest
    static void validate_validRecord_returnsNoErrors() {
        FiduciaryOthers__c fo = new FiduciaryOthers__c(OriginAmount__c = 1000, Status__c = 'Partial');

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_FiduciaryOthersDomain.validate(new List<FiduciaryOthers__c>{ fo });
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Valid record should produce no errors');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void customException_canBeInstantiated() {
        REC_FiduciaryOthersDomain.REC_FiduciaryOthersDomainException ex = new REC_FiduciaryOthersDomain.REC_FiduciaryOthersDomainException(
            'test'
        );
        Assert.areEqual('test', ex.getMessage());
    }
}