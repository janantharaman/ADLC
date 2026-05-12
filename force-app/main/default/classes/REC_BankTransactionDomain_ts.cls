/**
 * REC_BankTransactionDomain_ts — Test class for REC_BankTransactionDomain.
 *
 * Coverage targets:
 *  - decideStatus(Decimal)
 *  - decideStatus(BankTransaction__c)
 *  - applyReconciledAmount
 *  - rollbackReconciledAmount
 *  - validate
 *  - checkStatementUploadDisabled
 *  - validateAccountMapping
 */
@IsTest
private class REC_BankTransactionDomain_ts {
    // ═════════════════════════════════════════════════════════════════════════
    //  Test Setup & Helpers (for SOQL-based tests)
    // ═════════════════════════════════════════════════════════════════════════

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.insertBankTransaction(
            REC_Consts.CCY.KRW,
            REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT,
            REC_Consts.BizRegion.LK_KR
        );
    }

    private static BankTransaction__c getTestBt() {
        return [
            SELECT Id, BizRegion__c, Depositor__c, OriginAmount__c
            FROM BankTransaction__c
            LIMIT 1
        ];
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  decideStatus(Decimal)
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void decideStatus_zeroNetBalance_returnsClear() {
        Assert.areEqual('Clear', REC_BankTransactionDomain.decideStatus(0), 'Zero net balance should return Clear');
    }

    @IsTest
    static void decideStatus_positiveNetBalance_returnsPartial() {
        Assert.areEqual(
            'Partial',
            REC_BankTransactionDomain.decideStatus(500),
            'Positive net balance should return Partial'
        );
    }

    @IsTest
    static void decideStatus_negativeNetBalance_returnsNull() {
        Assert.areEqual(null, REC_BankTransactionDomain.decideStatus(-100), 'Negative net balance should return null');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  decideStatus(BankTransaction__c)
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void decideStatus_bankTransaction_delegatesToDecimal() {
        BankTransaction__c bt = new BankTransaction__c(NetBalanceAftCleared__c = 0);
        Assert.areEqual('Clear', REC_BankTransactionDomain.decideStatus(bt));
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  applyReconciledAmount
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void applyReconciledAmount_fullAmount_setsClear() {
        BankTransaction__c bt = new BankTransaction__c(
            OriginAmount__c = 1000,
            TotalClearedAmount__c = 0,
            NetBalanceAftCleared__c = 1000
        );

        Test.startTest();
        REC_BankTransactionDomain.applyReconciledAmount(bt, 1000);
        Test.stopTest();

        Assert.areEqual(1000, bt.TotalClearedAmount__c, 'TotalClearedAmount should be fully applied');
        Assert.areEqual(0, bt.NetBalanceAftCleared__c, 'NetBalance should be zero');
        Assert.areEqual('Clear', bt.Status__c, 'Status should be Clear');
    }

    @IsTest
    static void applyReconciledAmount_partialAmount_setsPartial() {
        BankTransaction__c bt = new BankTransaction__c(
            OriginAmount__c = 1000,
            TotalClearedAmount__c = 0,
            NetBalanceAftCleared__c = 1000
        );

        Test.startTest();
        REC_BankTransactionDomain.applyReconciledAmount(bt, 400);
        Test.stopTest();

        Assert.areEqual(400, bt.TotalClearedAmount__c, 'TotalClearedAmount should reflect partial');
        Assert.areEqual(600, bt.NetBalanceAftCleared__c, 'NetBalance should be remaining');
        Assert.areEqual('Partial', bt.Status__c, 'Status should be Partial');
    }

    @IsTest
    static void applyReconciledAmount_nullTotalCleared_treatedAsZero() {
        BankTransaction__c bt = new BankTransaction__c(
            OriginAmount__c = 1000,
            TotalClearedAmount__c = null,
            NetBalanceAftCleared__c = 1000
        );

        Test.startTest();
        REC_BankTransactionDomain.applyReconciledAmount(bt, 500);
        Test.stopTest();

        Assert.areEqual(500, bt.TotalClearedAmount__c, 'Null TotalClearedAmount should be treated as 0');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  rollbackReconciledAmount
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void rollbackReconciledAmount_fullRollback_restoresOriginal() {
        BankTransaction__c bt = new BankTransaction__c(
            OriginAmount__c = 1000,
            TotalClearedAmount__c = 1000,
            NetBalanceAftCleared__c = 0
        );

        Test.startTest();
        REC_BankTransactionDomain.rollbackReconciledAmount(bt, 1000);
        Test.stopTest();

        Assert.areEqual(0, bt.TotalClearedAmount__c, 'TotalClearedAmount should be zero after full rollback');
        Assert.areEqual(1000, bt.NetBalanceAftCleared__c, 'NetBalance should be restored');
        Assert.areEqual('Partial', bt.Status__c, 'Status should be Partial (positive net balance)');
    }

    @IsTest
    static void rollbackReconciledAmount_partialRollback_updatesStatus() {
        BankTransaction__c bt = new BankTransaction__c(
            OriginAmount__c = 1000,
            TotalClearedAmount__c = 600,
            NetBalanceAftCleared__c = 400
        );

        Test.startTest();
        REC_BankTransactionDomain.rollbackReconciledAmount(bt, 600);
        Test.stopTest();

        Assert.areEqual(0, bt.TotalClearedAmount__c, 'TotalClearedAmount should be zero');
        Assert.areEqual(1000, bt.NetBalanceAftCleared__c, 'NetBalance should be fully restored');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  validate
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void validate_emptyList_returnsNoErrors() {
        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validate(new List<BankTransaction__c>());
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Empty list should produce no errors');
    }

    @IsTest
    static void validate_validRecord_returnsNoErrors() {
        BankTransaction__c bt = new BankTransaction__c(OriginAmount__c = 1000, Status__c = 'Partial');

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validate(new List<BankTransaction__c>{ bt });
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Valid record should produce no errors');
    }

    @IsTest
    static void validate_injectedErrors_returnsHookedErrorsAndClearsState() {
        REC_BankTransactionDomain.testValidationErrors = new List<REC_TableHelper.CellError>{
            new REC_TableHelper.CellError('001000000000001AAA', 'Depositor__c', 'Injected error')
        };

        Test.startTest();
        List<REC_TableHelper.CellError> firstErrors = REC_BankTransactionDomain.validate(new List<BankTransaction__c>());
        List<REC_TableHelper.CellError> secondErrors = REC_BankTransactionDomain.validate(new List<BankTransaction__c>());
        Test.stopTest();

        Assert.areEqual(1, firstErrors.size(), 'Injected validation errors should be returned once');
        Assert.areEqual('Injected error', firstErrors[0].message, 'Injected validation message should be preserved');
        Assert.isTrue(secondErrors.isEmpty(), 'Injected validation errors should be cleared after one use');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void customException_canBeInstantiated() {
        REC_BankTransactionDomain.REC_BankTransactionDomainException ex = new REC_BankTransactionDomain.REC_BankTransactionDomainException(
            'test'
        );
        Assert.areEqual('test', ex.getMessage());
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  checkStatementUploadDisabled
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void checkStatementUploadDisabled_nullInput_returnsEmptyMap() {
        Map<Id, Boolean> result = REC_BankTransactionDomain.checkStatementUploadDisabled(null);
        Assert.isTrue(result.isEmpty(), 'Null input should return empty map');
    }

    @IsTest
    static void checkStatementUploadDisabled_emptySet_returnsEmptyMap() {
        Map<Id, Boolean> result = REC_BankTransactionDomain.checkStatementUploadDisabled(new Set<Id>());
        Assert.isTrue(result.isEmpty(), 'Empty set should return empty map');
    }

    @IsTest
    static void checkStatementUploadDisabled_noStatements_returnsFalse() {
        BankTransaction__c bt = getTestBt();

        Test.startTest();
        Map<Id, Boolean> result = REC_BankTransactionDomain.checkStatementUploadDisabled(new Set<Id>{ bt.Id });
        Test.stopTest();

        Assert.areEqual(false, result.get(bt.Id), 'BT without statements should not be disabled');
    }

    @IsTest
    static void checkStatementUploadDisabled_withStatement_returnsTrue() {
        BankTransaction__c bt = getTestBt();
        Statement__c stmt = REC_TestDataFactory.insertStatement(bt.Id);
        insert new Reconciliation__c(BizRegion__c = REC_TestDataFactory.DEFAULT_BIZ_REGION, BaseStatement__c = stmt.Id);

        Test.startTest();
        Map<Id, Boolean> result = REC_BankTransactionDomain.checkStatementUploadDisabled(new Set<Id>{ bt.Id });
        Test.stopTest();

        Assert.areEqual(true, result.get(bt.Id), 'BT with statement should be disabled');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  validateAccountMapping
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void validateAccountMapping_nullChangedIds_returnsEmpty() {
        BankTransaction__c bt = getTestBt();

        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>{ bt },
            null
        );
        Assert.isTrue(errors.isEmpty(), 'Null changedIds should return empty');
    }

    @IsTest
    static void validateAccountMapping_emptyChangedIds_returnsEmpty() {
        BankTransaction__c bt = getTestBt();

        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>{ bt },
            new Set<Id>()
        );
        Assert.isTrue(errors.isEmpty(), 'Empty changedIds should return empty');
    }

    @IsTest
    static void validateAccountMapping_nonMatchingChangedIds_returnsEmpty() {
        BankTransaction__c bt = getTestBt();

        // changedIds has bt.Id, but records list is empty → btIdsToCheck empty → early return
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>(),
            new Set<Id>{ bt.Id }
        );
        Assert.isTrue(errors.isEmpty(), 'Non-matching changedIds should return empty');
    }

    @IsTest
    static void validateAccountMapping_matchingAD_returnsNoError() {
        BankTransaction__c bt = getTestBt();
        Account acc = REC_TestDataFactory.insertAccount('MappedAccount');

        // Create matching AccountDepositor
        REC_TestDataFactory.insertAccountDepositor(bt.Depositor__c, bt.BizRegion__c, acc.Id, true);

        BankTransaction__c parsed = new BankTransaction__c(Id = bt.Id, AccountName__c = acc.Id);

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>{ parsed },
            new Set<Id>{ bt.Id }
        );
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Matching AD should produce no error');
    }

    @IsTest
    static void validateAccountMapping_noMatchingAD_returnsCellError() {
        BankTransaction__c bt = getTestBt();
        Account acc = REC_TestDataFactory.insertAccount('UnmappedAccount');

        // No AccountDepositor created → should produce error
        BankTransaction__c parsed = new BankTransaction__c(Id = bt.Id, AccountName__c = acc.Id);

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>{ parsed },
            new Set<Id>{ bt.Id }
        );
        Test.stopTest();

        Assert.isFalse(errors.isEmpty(), 'No matching AD should produce error');
    }

    @IsTest
    static void validateAccountMapping_clearedAccountName_noError() {
        BankTransaction__c bt = getTestBt();

        // Parsed record with null AccountName (user cleared it)
        BankTransaction__c parsed = new BankTransaction__c(Id = bt.Id, AccountName__c = null);

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>{ parsed },
            new Set<Id>{ bt.Id }
        );
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Cleared AccountName should skip validation');
    }

    @IsTest
    static void validateAccountMapping_deletedBt_handlesGracefully() {
        BankTransaction__c bt = getTestBt();
        Account acc = REC_TestDataFactory.insertAccount('DeleteTestAccount');

        Id btId = bt.Id;
        delete bt;

        BankTransaction__c parsed = new BankTransaction__c(Id = btId, AccountName__c = acc.Id);

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_BankTransactionDomain.validateAccountMapping(
            new List<BankTransaction__c>{ parsed },
            new Set<Id>{ btId }
        );
        Test.stopTest();

        // orig == null → skipped in both loops → no error
        Assert.isTrue(errors.isEmpty(), 'Deleted BT should be skipped gracefully');
    }
}