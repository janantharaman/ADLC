/**
 * REC_ReconciliationLineItemSelector_ts — Test class for REC_ReconciliationLineItemSelector.
 */
@IsTest
private class REC_ReconciliationLineItemSelector_ts {
    private class StatementSelectorContext {
        Reconciliation__c reconciliation;
        SettlementLineItem__c settlementLineItem;
        FiduciaryOthers__c fiduciaryOther;
        StatementLineItem__c statementLineItem;
    }

    private static Reconciliation__c getRecon() {
        return [SELECT Id, Status__c FROM Reconciliation__c LIMIT 1];
    }

    private static BankTransaction__c getBt() {
        return [SELECT Id FROM BankTransaction__c LIMIT 1];
    }

    private static SettlementLineItem__c getDetailSli() {
        return [SELECT Id FROM SettlementLineItem__c WHERE OriginAmount__c > 0 LIMIT 1];
    }

    private static StatementSelectorContext setupStatementSelectorData() {
        StatementSelectorContext ctx = new StatementSelectorContext();
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Settlement__c settlement = REC_TestDataFactory.insertSettlement();
            ctx.settlementLineItem = REC_TestDataFactory.insertSettlementLineItemPair(
                settlement.Id,
                REC_Consts.ClosingType.P_R,
                11000,
                REC_TestDataFactory.DEFAULT_CURRENCY,
                REC_TestDataFactory.DEFAULT_BIZ_REGION
            )[0];
            ctx.fiduciaryOther = REC_TestDataFactory.insertFiduciaryOthers(
                REC_TestDataFactory.DEFAULT_CURRENCY,
                2000,
                REC_TestDataFactory.DEFAULT_BIZ_REGION
            );

            Account insurer = REC_TestDataFactory.insertAccount('Stmt Selector Insurer');
            Account policyHolder = REC_TestDataFactory.insertAccount('Stmt Selector Holder');
            BankTransaction__c bankTransaction = REC_TestDataFactory.insertBankTransaction(
                REC_TestDataFactory.DEFAULT_CURRENCY,
                10000,
                REC_TestDataFactory.DEFAULT_BIZ_REGION
            );
            bankTransaction.AccountName__c = insurer.Id;
            update bankTransaction;

            Map<String, Object> row = new Map<String, Object>();
            row.put(
                REC_Utils.fieldName(StatementLineItem__c.TransactionDate__c),
                String.valueOf(bankTransaction.TransactionDate__c)
            );
            row.put(REC_Utils.fieldName(StatementLineItem__c.Insurer_lk__c), String.valueOf(insurer.Id));
            row.put(REC_Utils.fieldName(StatementLineItem__c.PolicyHolder_lk__c), String.valueOf(policyHolder.Id));
            row.put(REC_Utils.fieldName(StatementLineItem__c.LOB3__c), 'TT81');
            row.put(REC_Utils.fieldName(StatementLineItem__c.Brokerage__c), 10000);
            row.put(REC_Utils.fieldName(StatementLineItem__c.Premium__c), 50000);
            row.put(
                REC_Utils.fieldName(StatementLineItem__c.InceptionDate__c),
                String.valueOf(REC_TestDataFactory.DEFAULT_TX_DATE)
            );
            row.put(REC_Utils.fieldName(StatementLineItem__c.PolicyNo__c), 'POL-SELECTOR-001');
            row.put(REC_Utils.fieldName(StatementLineItem__c.LOBDetails__c), 'Selector LOB');
            row.put(REC_Utils.fieldName(StatementLineItem__c.BrokerageRatePct__c), 10);
            row.put(REC_Utils.fieldName(StatementLineItem__c.Team__c), 'Claim');

            REC_StatementDomain.createStatements(bankTransaction.Id, new List<Map<String, Object>>{ row });

            Statement__c statement = [
                SELECT Id
                FROM Statement__c
                WHERE RefBankTransaction__c = :bankTransaction.Id
                LIMIT 1
            ];
            ctx.reconciliation = [
                SELECT Id
                FROM Reconciliation__c
                WHERE BaseStatement__c = :statement.Id
                LIMIT 1
            ];
            ctx.statementLineItem = [
                SELECT Id
                FROM StatementLineItem__c
                WHERE RefStatement_lk__c = :statement.Id
                LIMIT 1
            ];
        }

        return ctx;
    }

    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupSelectorTestData();
    }

    // ── Singleton & metadata ────────────────────────────────────────────────

    @IsTest
    static void getInstance_returnsSingleton() {
        REC_ReconciliationLineItemSelector s1 = REC_ReconciliationLineItemSelector.getInstance();
        REC_ReconciliationLineItemSelector s2 = REC_ReconciliationLineItemSelector.getInstance();
        Assert.areEqual(s1, s2, 'getInstance should return the same singleton instance');
    }

    @IsTest
    static void getSObjectType_returnsRliType() {
        Assert.areEqual(
            ReconciliationLineItem__c.SObjectType,
            REC_ReconciliationLineItemSelector.getInstance().getSObjectType(),
            'getSObjectType should return ReconciliationLineItem__c.SObjectType'
        );
    }

    @IsTest
    static void getDefaultFields_returnsNonEmptyList() {
        List<Schema.SObjectField> fields = REC_ReconciliationLineItemSelector.getInstance().getDefaultFields();
        Assert.isFalse(fields.isEmpty(), 'getDefaultFields should return a non-empty list');
    }

    // ── queryByReconWithBankTransaction ─────────────────────────────────────

    @IsTest
    static void queryByReconWithBankTransaction_returnsRlis() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryByReconWithBankTransaction(recon.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return BT/FO-referenced RLIs');
    }

    // ── queryByReconWithSettlementLineItem ──────────────────────────────────

    @IsTest
    static void queryByReconWithSettlementLineItem_returnsRlis() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryByReconWithSettlementLineItem(recon.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return SLI-referenced RLIs');
    }

    // ── queryByBaseRecord ───────────────────────────────────────────────────

    @IsTest
    static void queryByBaseRecord_withSliId_returnsRlis() {
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance().queryByBaseRecord(sli.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return RLIs referencing the base SLI');
    }

    @IsTest
    static void queryByBaseRecord_withBtId_returnsRlis() {
        BankTransaction__c bt = getBt();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance().queryByBaseRecord(bt.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return RLIs referencing the BT');
    }

    // ── queryBaseRecordIdsHavingDraftRli ─────────────────────────────────────

    @IsTest
    static void queryBaseRecordIdsHavingDraftRli_withDraftRecon_returnsIds() {
        SettlementLineItem__c sli = getDetailSli();
        BankTransaction__c bt = getBt();

        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance()
            .queryBaseRecordIdsHavingDraftRli(new Set<Id>{ sli.Id }, new Set<Id>{ bt.Id }, null);
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Should return base record Ids that have draft RLIs');
    }

    @IsTest
    static void queryBaseRecordIdsHavingDraftRli_emptyInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance()
            .queryBaseRecordIdsHavingDraftRli(new Set<Id>(), new Set<Id>(), null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should return empty output');
    }

    @IsTest
    static void queryBaseRecordIdsHavingDraftRli_nullInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().queryBaseRecordIdsHavingDraftRli(null, null, null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null input should return empty output');
    }

    // ── querySliIdsHavingRli ────────────────────────────────────────────────

    @IsTest
    static void querySliIdsHavingRli_withReconciledSli_returnsIds() {
        SettlementLineItem__c sli = getDetailSli();

        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().querySliIdsHavingRli(new Set<Id>{ sli.Id }, null);
        Test.stopTest();

        Assert.isTrue(result.contains(sli.Id), 'Should return the SLI Id that has an RLI');
    }

    @IsTest
    static void querySliIdsHavingRli_emptyInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().querySliIdsHavingRli(new Set<Id>(), null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should return empty output');
    }

    @IsTest
    static void querySliIdsHavingRli_nullInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().querySliIdsHavingRli(null, null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null input should return empty output');
    }

    // ── queryForDraft ───────────────────────────────────────────────────────

    @IsTest
    static void queryForDraft_returnsRlis() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance().queryForDraft(recon.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return RLIs for the reconciliation');
    }

    // ── queryForBtBasedDraft ────────────────────────────────────────────────

    @IsTest
    static void queryForBtBasedDraft_returnsRlis() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryForBtBasedDraft(recon.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return RLIs for BT-based draft');
    }

    // ── queryFoIdsHavingDraftRli ────────────────────────────────────────────

    @IsTest
    static void queryFoIdsHavingDraftRli_withDraftRecon_returnsIds() {
        FiduciaryOthers__c fo = [SELECT Id FROM FiduciaryOthers__c LIMIT 1];

        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance()
            .queryFoIdsHavingDraftRli(new Set<Id>{ fo.Id }, null);
        Test.stopTest();

        Assert.isTrue(result.contains(fo.Id), 'Should return FO Id that has a draft RLI');
    }

    @IsTest
    static void queryFoIdsHavingDraftRli_nullInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().queryFoIdsHavingDraftRli(null, null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null input should return empty output');
    }

    @IsTest
    static void queryFoIdsHavingDraftRli_emptyInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().queryFoIdsHavingDraftRli(new Set<Id>(), null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should return empty output');
    }

    // ── queryBtIdsHavingDraftRli ────────────────────────────────────────────

    @IsTest
    static void queryBtIdsHavingDraftRli_withDraftRecon_returnsIds() {
        BankTransaction__c bt = getBt();

        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance()
            .queryBtIdsHavingDraftRli(new Set<Id>{ bt.Id }, null);
        Test.stopTest();

        Assert.isTrue(result.contains(bt.Id), 'Should return BT Id that has a draft RLI');
    }

    @IsTest
    static void queryBtIdsHavingDraftRli_nullInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().queryBtIdsHavingDraftRli(null, null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null input should return empty output');
    }

    @IsTest
    static void queryBtIdsHavingDraftRli_emptyInput_returnsEmpty() {
        Test.startTest();
        Set<Id> result = REC_ReconciliationLineItemSelector.getInstance().queryBtIdsHavingDraftRli(new Set<Id>(), null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should return empty output');
    }

    // ── queryByReconWithStatement ───────────────────────────────────────────

    @IsTest
    static void queryByReconWithStatement_withStatementRli_returnsRlis() {
        Reconciliation__c recon = getRecon();
        BankTransaction__c bt = getBt();

        // Create a Statement linked to the BT
        Statement__c stmt = new Statement__c(RefBankTransaction__c = bt.Id);
        insert stmt;

        // Create an RLI linked to the statement
        insert new ReconciliationLineItem__c(
            RefReconciliation__c = recon.Id,
            RefStatement__c = stmt.Id,
            ReconciledAMT__c = 100000
        );

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryByReconWithStatement(recon.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return Statement-referenced RLIs');
    }

    @IsTest
    static void queryByReconWithStatement_noStatementRli_returnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryByReconWithStatement(recon.Id);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Should return empty when no Statement RLIs exist');
    }

    // ── Statement-based selector methods ───────────────────────────────────

    @IsTest
    static void queryByReconWithFiduciaryOthers_returnsRlis() {
        StatementSelectorContext ctx = setupStatementSelectorData();
        insert new ReconciliationLineItem__c(
            RefReconciliation__c = ctx.reconciliation.Id,
            RefFiduciaryOthers__c = ctx.fiduciaryOther.Id,
            ReconciledAMT__c = 1000
        );

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryByReconWithFiduciaryOthers(ctx.reconciliation.Id);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return the FO-referenced RLI');
        Assert.areEqual(ctx.fiduciaryOther.Id, results[0].RefFiduciaryOthers__c);
    }

    @IsTest
    static void queryForStmtBasedDraft_returnsStatementBasedRlis() {
        StatementSelectorContext ctx = setupStatementSelectorData();
        insert new List<ReconciliationLineItem__c>{
            new ReconciliationLineItem__c(
                RefReconciliation__c = ctx.reconciliation.Id,
                RefSettlementLineItem__c = ctx.settlementLineItem.Id,
                SettlementCurrency__c = REC_TestDataFactory.DEFAULT_CURRENCY,
                FXRateOrigintoSettlement__c = 1,
                FXAmountPremiumLocal__c = 50000
            ),
            new ReconciliationLineItem__c(
                RefReconciliation__c = ctx.reconciliation.Id,
                RefFiduciaryOthers__c = ctx.fiduciaryOther.Id,
                ReconciledAMT__c = 1000
            )
        };

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryForStmtBasedDraft(ctx.reconciliation.Id);
        Test.stopTest();

        Boolean foundBaseStatement = false;
        Boolean foundStatementLineItem = false;
        Boolean foundSettlementLineItem = false;
        Boolean foundFiduciaryOther = false;
        for (ReconciliationLineItem__c result : results) {
            foundBaseStatement = foundBaseStatement || result.RefStatement__c != null;
            foundStatementLineItem = foundStatementLineItem || result.RefStatementLineItem__c != null;
            foundSettlementLineItem =
                foundSettlementLineItem || result.RefSettlementLineItem__c == ctx.settlementLineItem.Id;
            foundFiduciaryOther = foundFiduciaryOther || result.RefFiduciaryOthers__c == ctx.fiduciaryOther.Id;
        }

        Assert.isTrue(foundBaseStatement, 'Should include the base Statement RLI');
        Assert.isTrue(foundStatementLineItem, 'Should include the StatementLineItem RLI');
        Assert.isTrue(foundSettlementLineItem, 'Should include the SLI-referenced RLI');
        Assert.isTrue(foundFiduciaryOther, 'Should include the FO-referenced RLI');
    }

    @IsTest
    static void queryStmtLineItemRlis_returnsStmtLineItemRlis() {
        StatementSelectorContext ctx = setupStatementSelectorData();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryStmtLineItemRlis(ctx.reconciliation.Id);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return the StatementLineItem RLI');
        Assert.areEqual(ctx.statementLineItem.Id, results[0].RefStatementLineItem__c);
    }

    // ── queryPcRlisByRecon ──────────────────────────────────────────────────

    @IsTest
    static void queryPcRlisByRecon_withOtherChargesRli_returnsRlis() {
        Reconciliation__c recon = getRecon();

        // Create an Other Charges RLI
        insert new ReconciliationLineItem__c(
            RefReconciliation__c = recon.Id,
            IsOtherCharges__c = true,
            OriginAmount__c = 5000
        );

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryPcRlisByRecon(recon.Id);
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return Other Charges RLIs');
    }

    @IsTest
    static void queryPcRlisByRecon_noOtherChargesRli_returnsEmpty() {
        Reconciliation__c recon = getRecon();

        Test.startTest();
        List<ReconciliationLineItem__c> results = REC_ReconciliationLineItemSelector.getInstance()
            .queryPcRlisByRecon(recon.Id);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Should return empty when no Other Charges RLIs exist');
    }
}