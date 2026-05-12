/**
 * REC_RelatedReconCtrl_ts — Test class for REC_RelatedReconCtrl.
 *
 * Coverage targets:
 *  - inquiryReconciliationLineItems
 *  - checkNewButtonDisabled
 *  - createNewReconciliation
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
private class REC_RelatedReconCtrl_ts {
    // ─── Shared query helpers ────────────────────────────────────────────────

    private static BankTransaction__c getBt() {
        return [SELECT Id FROM BankTransaction__c LIMIT 1];
    }

    private static SettlementLineItem__c getDetailSli() {
        return [
            SELECT Id, OriginAmount__c, SettlementStatus__c
            FROM SettlementLineItem__c
            WHERE OriginAmount__c > 0
            LIMIT 1
        ];
    }

    private class StatementUploadCtx {
        Account insurer;
        Account policyHolder;
        BankTransaction__c bankTransaction;
    }

    private static StatementUploadCtx createStatementUploadCtx() {
        StatementUploadCtx ctx = new StatementUploadCtx();
        ctx.insurer = ACC_TestDataFactory.createAccount('Statement Upload Insurer', false);
        ctx.policyHolder = ACC_TestDataFactory.createAccount('Statement Upload Policy Holder', false);
        insert new List<Account>{ ctx.insurer, ctx.policyHolder };

        ctx.bankTransaction = REC_TestDataFactory.insertBankTransaction(
            REC_TestDataFactory.DEFAULT_CURRENCY,
            REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT,
            REC_TestDataFactory.DEFAULT_BIZ_REGION
        );
        ctx.bankTransaction.AccountName__c = ctx.insurer.Id;
        ctx.bankTransaction.TransactionDate__c = REC_TestDataFactory.DEFAULT_TX_DATE;
        update ctx.bankTransaction;

        return ctx;
    }

    private static Map<String, Object> buildStatementUploadRow(
        Id insurerId,
        Id policyHolderId,
        String lob3,
        Decimal brokerage,
        Decimal premium,
        Date txDate
    ) {
        return new Map<String, Object>{
            REC_Utils.fieldName(StatementLineItem__c.Insurer_lk__c) => String.valueOf(insurerId),
            REC_Utils.fieldName(StatementLineItem__c.PolicyHolder_lk__c) => String.valueOf(policyHolderId),
            REC_Utils.fieldName(StatementLineItem__c.LOB3__c) => lob3,
            REC_Utils.fieldName(StatementLineItem__c.Brokerage__c) => brokerage,
            REC_Utils.fieldName(StatementLineItem__c.Premium__c) => premium,
            REC_Utils.fieldName(StatementLineItem__c.TransactionDate__c) => String.valueOf(txDate),
            REC_Utils.fieldName(StatementLineItem__c.PolicyNo__c) => 'POL-001',
            REC_Utils.fieldName(StatementLineItem__c.InceptionDate__c) => String.valueOf(txDate),
            REC_Utils.fieldName(StatementLineItem__c.LOBDetails__c) => 'Details',
            REC_Utils.fieldName(StatementLineItem__c.BrokerageRatePct__c) => 10,
            REC_Utils.fieldName(StatementLineItem__c.Team__c) => 'Claim',
            REC_Utils.fieldName(StatementLineItem__c.Remarks__c) => 'remarks',
            REC_Utils.fieldName(StatementLineItem__c.PolicyHolder__c) => 'Policy Holder'
        };
    }

    // ════════════════════════════════════════════════════════════════════════
    //  @TestSetup
    // ════════════════════════════════════════════════════════════════════════

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupBtBasedRecon();
    }

    // ════════════════════════════════════════════════════════════════════════
    //  inquiryReconciliationLineItems
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testInquiryRlisWithValidBtReturnsRlis() {
        BankTransaction__c bt = getBt();

        Test.startTest();
        List<ReconciliationLineItem__c> rlis = REC_RelatedReconCtrl.inquiryReconciliationLineItems(bt.Id);
        Test.stopTest();

        Assert.isFalse(rlis.isEmpty(), 'Expected at least one RLI for the base BT');
    }

    @IsTest
    static void testInquiryRlisWithNoRlisReturnsEmpty() {
        // New BT with no reconciliation → no RLIs
        BankTransaction__c newBt = REC_TestDataFactory.insertBankTransaction(
            REC_TestDataFactory.DEFAULT_CURRENCY,
            REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT,
            REC_TestDataFactory.DEFAULT_BIZ_REGION
        );

        Test.startTest();
        List<ReconciliationLineItem__c> rlis = REC_RelatedReconCtrl.inquiryReconciliationLineItems(newBt.Id);
        Test.stopTest();

        Assert.isTrue(rlis.isEmpty(), 'Expected empty list for BT with no RLIs');
    }

    @IsTest
    static void testInquiryRlisWithNullReturnsNull() {
        Test.startTest();
        List<ReconciliationLineItem__c> result = REC_RelatedReconCtrl.inquiryReconciliationLineItems(null);
        Test.stopTest();

        Assert.isNull(result, 'Expected null for null recordId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  checkNewButtonDisabled
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testCheckNewButtonDisabledWithDraftReconReturnsTrue() {
        BankTransaction__c bt = getBt();

        // Set recon to Draft so the domain reports "disabled"
        Reconciliation__c recon = [SELECT Id FROM Reconciliation__c LIMIT 1];
        recon.Status__c = REC_Consts.ReconciliationStatus.DRAFT;
        update recon;

        Test.startTest();
        Boolean result = REC_RelatedReconCtrl.checkNewButtonDisabled(bt.Id);
        Test.stopTest();

        Assert.isTrue(result, 'Expected true when BT has a Draft reconciliation');
    }

    @IsTest
    static void testCheckNewButtonDisabledWithNoReconReturnsFalse() {
        // New BT with no reconciliation → not disabled
        BankTransaction__c newBt = REC_TestDataFactory.insertBankTransaction(
            REC_TestDataFactory.DEFAULT_CURRENCY,
            REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT,
            REC_TestDataFactory.DEFAULT_BIZ_REGION
        );

        Test.startTest();
        Boolean result = REC_RelatedReconCtrl.checkNewButtonDisabled(newBt.Id);
        Test.stopTest();

        Assert.isFalse(result, 'Expected false when BT has no reconciliation');
    }

    @IsTest
    static void testCheckNewButtonDisabledWithNullIdReturnsTrue() {
        Test.startTest();
        Boolean result = REC_RelatedReconCtrl.checkNewButtonDisabled(null);
        Test.stopTest();

        Assert.isTrue(result, 'Expected true for null recordId');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  createNewReconciliation
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testCreateNewReconciliationWithSliReturnsReconId() {
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();
        Id reconId = REC_RelatedReconCtrl.createNewReconciliation(sli.Id);
        Test.stopTest();

        Assert.isNotNull(reconId, 'Reconciliation ID should be returned');

        Reconciliation__c recon = [SELECT Id FROM Reconciliation__c WHERE Id = :reconId];
        Assert.isNotNull(recon, 'Reconciliation record should exist');
    }

    @IsTest
    static void testCreateNewReconciliationWithNullThrowsAura() {
        Boolean thrown = false;
        try {
            Test.startTest();
            REC_RelatedReconCtrl.createNewReconciliation(null);
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'Expected AuraHandledException for null baseRecordId');
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
        BankTransaction__c bt = getBt();
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();

        // inquiryReconciliationLineItems
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.inquiryReconciliationLineItems(bt.Id);
            Assert.fail('inquiryRlis should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'inquiryRlis exception message should not be null');
        }

        // checkNewButtonDisabled
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.checkNewButtonDisabled(bt.Id);
            Assert.fail('checkNewButtonDisabled should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'checkNewButtonDisabled exception message should not be null');
        }

        // createNewReconciliation
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.createNewReconciliation(sli.Id);
            Assert.fail('createNewRecon should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'createNewRecon exception message should not be null');
        }

        Test.stopTest();
    }

    // ════════════════════════════════════════════════════════════════════════
    //  checkStatementUploadDisabled
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testCheckStatementUploadDisabledWithNullId_ReturnsTrue() {
        Test.startTest();
        Boolean result = REC_RelatedReconCtrl.checkStatementUploadDisabled(null);
        Test.stopTest();

        Assert.isTrue(result, 'Expected true for null recordId');
    }

    @IsTest
    static void testCheckStatementUploadDisabledWithNoStatements_ReturnsFalse() {
        BankTransaction__c bt = getBt();

        Test.startTest();
        Boolean result = REC_RelatedReconCtrl.checkStatementUploadDisabled(bt.Id);
        Test.stopTest();

        Assert.isFalse(result, 'Expected false when BT has no linked Statements');
    }

    @IsTest
    static void testCheckStatementUploadDisabledWithStatements_ReturnsTrue() {
        BankTransaction__c bt = getBt();
        Statement__c stmt = REC_TestDataFactory.insertStatement(bt.Id);
        insert new Reconciliation__c(BizRegion__c = REC_TestDataFactory.DEFAULT_BIZ_REGION, BaseStatement__c = stmt.Id);

        Test.startTest();
        Boolean result = REC_RelatedReconCtrl.checkStatementUploadDisabled(bt.Id);
        Test.stopTest();

        Assert.isTrue(result, 'Expected true when BT has at least one linked Statement');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  resolveAccountsByERPCodes
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testResolveAccountsByERPCodes_NullOrEmptyReturnsEmptyMap() {
        Test.startTest();
        Map<String, Id> resultNull = REC_RelatedReconCtrl.resolveAccountsByERPCodes(null);
        Map<String, Id> resultEmpty = REC_RelatedReconCtrl.resolveAccountsByERPCodes(new List<String>());
        Test.stopTest();

        Assert.isTrue(resultNull.isEmpty(), 'Expected empty map for null input');
        Assert.isTrue(resultEmpty.isEmpty(), 'Expected empty map for empty list');
    }

    @IsTest
    static void testResolveAccountsByERPCodes_MatchingCodesReturnsMap() {
        Account acc = ACC_TestDataFactory.createAccount('ERP Test Account', false);
        acc.ERPCode__c = 'ERP001';
        insert acc;

        Test.startTest();
        Map<String, Id> result = REC_RelatedReconCtrl.resolveAccountsByERPCodes(new List<String>{ 'ERP001' });
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected 1 entry in the result map');
        Assert.areEqual(acc.Id, result.get('ERP001'), 'Expected the inserted Account Id');
    }

    @IsTest
    static void testResolveAccountsByERPCodes_NoMatchReturnsEmptyMap() {
        Test.startTest();
        Map<String, Id> result = REC_RelatedReconCtrl.resolveAccountsByERPCodes(new List<String>{ 'NONEXISTENT_CODE' });
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Expected empty map when no Account matches');
    }

    // ════════════════════════════════════════════════════════════════════════
    //  validateStatementData
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testValidateStatementData_NullParamsThrowsAura() {
        Boolean thrown = false;

        Test.startTest();
        try {
            REC_RelatedReconCtrl.validateStatementData(null, null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        Assert.isTrue(thrown, 'Expected AuraHandledException for null parameters');
    }

    @IsTest
    static void testValidateStatementData_InvalidRowsReturnsFailure() {
        BankTransaction__c bt = getBt();
        // Brokerage sum (1) ≠ DEFAULT_ORIGIN_AMOUNT → validation fails
        Map<String, Object> row = new Map<String, Object>{ 'Brokerage__c' => '1' };
        String rowsJson = JSON.serialize(new List<Object>{ row });

        Test.startTest();
        REC_StatementDomain.StatementValidationResult result = REC_RelatedReconCtrl.validateStatementData(bt.Id, rowsJson);
        Test.stopTest();

        Assert.isFalse(result.success, 'Mismatched data should fail validation');
        Assert.isFalse(result.errors.isEmpty(), 'Expected validation errors');
    }

    @IsTest
    static void testValidateStatementData_ValidRowsReturnsSuccess() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Account acc = ACC_TestDataFactory.createAccount('ValidInsurer', true);

            BankTransaction__c bt = REC_TestDataFactory.insertBankTransaction(
                REC_TestDataFactory.DEFAULT_CURRENCY,
                REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT,
                REC_TestDataFactory.DEFAULT_BIZ_REGION
            );
            bt.AccountName__c = acc.Id;
            bt.TransactionDate__c = REC_TestDataFactory.DEFAULT_TX_DATE;
            update bt;

            Map<String, Object> row = new Map<String, Object>{
                'Insurer_lk__c' => String.valueOf(acc.Id),
                'TransactionDate__c' => String.valueOf(REC_TestDataFactory.DEFAULT_TX_DATE),
                'Brokerage__c' => String.valueOf(REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT)
            };
            String rowsJson = JSON.serialize(new List<Object>{ row });

            Test.startTest();
            REC_StatementDomain.StatementValidationResult result = REC_RelatedReconCtrl.validateStatementData(
                bt.Id,
                rowsJson
            );
            Test.stopTest();

            Assert.isTrue(result.success, 'All matching rows should pass validation');
            Assert.isTrue(result.errors.isEmpty(), 'No errors expected for valid data');
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    //  createStatementsFromUpload
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testCreateStatementsFromUpload_NullParamsThrowsAura() {
        Boolean thrown = false;

        Test.startTest();
        try {
            REC_RelatedReconCtrl.createStatementsFromUpload(null, null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        Assert.isTrue(thrown, 'Expected AuraHandledException for null parameters');
    }

    @IsTest
    static void testCreateStatementsFromUpload_ValidRowsCreatesStatements() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            StatementUploadCtx ctx = createStatementUploadCtx();
            Map<String, Object> row = buildStatementUploadRow(
                ctx.insurer.Id,
                ctx.policyHolder.Id,
                'TT81',
                REC_TestDataFactory.DEFAULT_ORIGIN_AMOUNT,
                5000000,
                REC_TestDataFactory.DEFAULT_TX_DATE
            );
            String rowsJson = JSON.serialize(new List<Object>{ row });

            Test.startTest();
            Map<String, Integer> result = REC_RelatedReconCtrl.createStatementsFromUpload(ctx.bankTransaction.Id, rowsJson);
            Test.stopTest();

            Assert.areEqual(1, result.get('statementCount'), 'Expected 1 Statement group to be created');
            Assert.areEqual(1, result.get('lineItemCount'), 'Expected 1 StatementLineItem to be created');

            Integer stmtCount = [SELECT COUNT() FROM Statement__c WHERE RefBankTransaction__c = :ctx.bankTransaction.Id];
            Assert.areEqual(1, stmtCount, 'Expected 1 Statement to be created');
            Integer stmtLineItemCount = [
                SELECT COUNT()
                FROM StatementLineItem__c
                WHERE
                    RefStatement_lk__c IN (
                        SELECT Id
                        FROM Statement__c
                        WHERE RefBankTransaction__c = :ctx.bankTransaction.Id
                    )
            ];
            Assert.areEqual(1, stmtLineItemCount, 'Expected 1 StatementLineItem to be created');
            Integer rliCount = [
                SELECT COUNT()
                FROM ReconciliationLineItem__c
                WHERE
                    RefStatement__c IN (
                        SELECT Id
                        FROM Statement__c
                        WHERE RefBankTransaction__c = :ctx.bankTransaction.Id
                    )
            ];
            Assert.areEqual(1, rliCount, 'Expected 1 ReconciliationLineItem to be created');
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    //  Catch-block coverage — new methods
    // ════════════════════════════════════════════════════════════════════════

    @IsTest
    static void testNewMethodCatchBlocksThrowAuraOnUnexpectedException() {
        BankTransaction__c bt = getBt();

        Test.startTest();

        // checkStatementUploadDisabled
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.checkStatementUploadDisabled(bt.Id);
            Assert.fail('checkStatementUploadDisabled should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'checkStatementUploadDisabled exception message should not be null');
        }

        // resolveAccountsByERPCodes
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.resolveAccountsByERPCodes(new List<String>{ 'ERP001' });
            Assert.fail('resolveAccountsByERPCodes should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'resolveAccountsByERPCodes exception message should not be null');
        }

        // validateStatementData
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.validateStatementData(bt.Id, '[{}]');
            Assert.fail('validateStatementData should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'validateStatementData exception message should not be null');
        }

        // createStatementsFromUpload
        ExceptionSimulator.active = true;
        try {
            REC_RelatedReconCtrl.createStatementsFromUpload(bt.Id, '[{}]');
            Assert.fail('createStatementsFromUpload should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'createStatementsFromUpload exception message should not be null');
        }

        Test.stopTest();
    }
}