/**
 * REC_ReconciliationLineItemSelector — Selector for ReconciliationLineItem__c.
 *
 * Provides various query patterns for Reconciliation Line Items,
 * including cross-object relationship queries to BankTransaction and
 * SettlementLineItem via their reference lookups.
 */
public inherited sharing class REC_ReconciliationLineItemSelector extends REC_SelectorBase {
    // ── Singleton ────────────────────────────────────────────────────────
    private static final REC_ReconciliationLineItemSelector INSTANCE = new REC_ReconciliationLineItemSelector();
    public static REC_ReconciliationLineItemSelector getInstance() {
        return INSTANCE;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Abstract Overrides
    // ═════════════════════════════════════════════════════════════════════════

    public override Schema.SObjectType getSObjectType() {
        return ReconciliationLineItem__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFields() {
        return new List<Schema.SObjectField>{
            ReconciliationLineItem__c.Id,
            ReconciliationLineItem__c.Name,
            ReconciliationLineItem__c.RefReconciliation__c,
            ReconciliationLineItem__c.RefBankTransaction__c,
            ReconciliationLineItem__c.RefFiduciaryOthers__c,
            ReconciliationLineItem__c.RefSettlementLineItem__c,
            ReconciliationLineItem__c.ReconciledAMT__c,
            ReconciliationLineItem__c.NotReconciledAMT__c,
            ReconciliationLineItem__c.BizRegion__c,
            // Settlement fields (written by draft, displayed on Base SLI table)
            ReconciliationLineItem__c.SettlementCurrency__c,
            ReconciliationLineItem__c.SettlementDate__c,
            ReconciliationLineItem__c.SettlementAmountSLI__c,
            ReconciliationLineItem__c.SettlementAmountTTL__c,
            ReconciliationLineItem__c.SettlementAmountPremium__c,
            ReconciliationLineItem__c.FXRateSettlementAccounting__c,
            ReconciliationLineItem__c.FXRateOrigintoSettlement__c,
            ReconciliationLineItem__c.OtherCharges__c,
            ReconciliationLineItem__c.SettlementType__c,
            // NEW
            ReconciliationLineItem__c.TotalClearedAmount_fm__c,
            ReconciliationLineItem__c.NetBalanceAftCleared_fm__c,
            ReconciliationLineItem__c.BTCurrency_fm__c,
            ReconciliationLineItem__c.BTStatus_fm__c,
            ReconciliationLineItem__c.TransactionDate_fm__c,
            ReconciliationLineItem__c.BTOriginAmount_fm__c,
            ReconciliationLineItem__c.BTAccountName_fm__c,
            ReconciliationLineItem__c.Depositor_fm__c,
            ReconciliationLineItem__c.Balance_fm__c,
            // May Deprecated
            ReconciliationLineItem__c.TotalClearedAmount__c,
            ReconciliationLineItem__c.NetAmountAfterClearing__c,
            ReconciliationLineItem__c.BTCurrency__c,
            ReconciliationLineItem__c.BTStatus__c,
            ReconciliationLineItem__c.TransactionDate__c,
            ReconciliationLineItem__c.BTOriginAmount__c,
            ReconciliationLineItem__c.BTAccountName__c,
            ReconciliationLineItem__c.Balance__c,
            // Editable fields (Exchange / Hold)
            ReconciliationLineItem__c.RemittanceOnHold__c,
            ReconciliationLineItem__c.HoldReason__c,
            ReconciliationLineItem__c.ExchangeDate__c,
            ReconciliationLineItem__c.ExchangeCurrency__c,
            ReconciliationLineItem__c.ExchangeAmount__c,
            ReconciliationLineItem__c.ExchangeRate__c,
            // Reconciliation Inquiry Added
            ReconciliationLineItem__c.RLIStatus__c,
            // Other Charges discriminator
            ReconciliationLineItem__c.IsOtherCharges__c,
            // User-entered fields
            ReconciliationLineItem__c.NeedsVerification__c,
            ReconciliationLineItem__c.Remarks__c,
            ReconciliationLineItem__c.FXAmountPremiumLocal__c
        };
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Queries
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Fetches RLIs by Reconciliation Id — both BT-referenced and FO-referenced items,
     * with cross-object BT / FO fields.
     */
    public List<ReconciliationLineItem__c> queryByReconWithBankTransaction(Id reconciliationId) {
        List<String> fields = new List<String>(getFieldNames());
        fields.addAll(
            REC_BankTransactionSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefBankTransaction__c)
        );
        fields.addAll(
            REC_FiduciaryOthersSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefFiduciaryOthers__c)
        );

        String query = '';
        query += 'SELECT {0} FROM ReconciliationLineItem__c ';
        query += 'WHERE RefReconciliation__c = :reconciliationId ';
        query += 'AND (RefBankTransaction__c != null OR RefFiduciaryOthers__c != null) ';
        query += 'AND IsOtherCharges__c != true ';
        query += 'ORDER BY RefBankTransaction__r.Name DESC, RefFiduciaryOthers__r.Name DESC ';
        query += 'LIMIT 2000';

        String soql = String.format(query, new List<String>{ String.join(fields, ', ') });

        return (List<ReconciliationLineItem__c>) Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'reconciliationId' => reconciliationId },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Fetches RLIs by Reconciliation Id, filtering only SLI-referenced items,
     * with cross-object SLI fields.
     */
    public List<ReconciliationLineItem__c> queryByReconWithSettlementLineItem(Id reconciliationId) {
        List<String> fields = new List<String>(getFieldNames());
        fields.addAll(
            REC_SettlementLineItemSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefSettlementLineItem__c)
        );
        // 2nd-level relationship fields needed by the Selected Items table
        fields.add('RefSettlementLineItem__r.AccountName__r.Name');
        fields.add('RefSettlementLineItem__r.Insured__r.Name');
        fields.add('RefSettlementLineItem__r.PeriodClose__r.Name');
        fields.add('RefSettlementLineItem__r.RefInsurancePolicy__r.Name');

        String query = '';
        query += 'SELECT {0} FROM ReconciliationLineItem__c ';
        query += 'WHERE RefReconciliation__c = :reconciliationId ';
        query += 'AND RefSettlementLineItem__c != null ';
        query += 'AND IsOtherCharges__c != true ';
        query += 'ORDER BY RefSettlementLineItem__r.Name DESC ';
        query += 'LIMIT 2000';

        String soql = String.format(query, new List<String>{ String.join(fields, ', ') });

        return (List<ReconciliationLineItem__c>) Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'reconciliationId' => reconciliationId },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Fetches RLIs by a base record Id (SLI or BT).
     * Used by the Related Reconciliation modal.
     */
    public List<ReconciliationLineItem__c> queryByBaseRecord(Id recordId) {
        return [
            SELECT
                Id,
                Name,
                TransactionDate__c,
                BTCurrency__c,
                ReconciledAMT__c,
                RefReconciliation__c,
                RefReconciliation__r.Status__c
            FROM ReconciliationLineItem__c
            WHERE
                RefSettlementLineItem__c = :recordId
                OR RefBankTransaction__c = :recordId
                OR RefStatement__r.RefBankTransaction__c = :recordId
            WITH SECURITY_ENFORCED
            ORDER BY Name DESC
            LIMIT 10000
        ];
    }

    /**
     * Returns base-record Ids (SLI or BT) that own at least one RLI whose
     * parent Reconciliation is in Draft status.
     *
     * Bulkified — accepts multiple Ids in a single call.
     * @param excludeReconId  Reconciliation to exclude (current recon); null = exclude none
     */
    public Set<Id> queryBaseRecordIdsHavingDraftRli(Set<Id> sliIds, Set<Id> btIds, Id excludeReconId) {
        Set<Id> result = new Set<Id>();

        if ((sliIds == null || sliIds.isEmpty()) && (btIds == null || btIds.isEmpty())) {
            return result;
        }

        for (ReconciliationLineItem__c rli : [
            SELECT RefSettlementLineItem__c, RefBankTransaction__c
            FROM ReconciliationLineItem__c
            WHERE
                RefReconciliation__r.Status__c = 'Draft'
                AND RefReconciliation__c != :excludeReconId
                AND IsOtherCharges__c != TRUE
                AND (RefSettlementLineItem__c IN :sliIds
                OR RefBankTransaction__c IN :btIds)
            WITH SECURITY_ENFORCED
        ]) {
            if (rli.RefSettlementLineItem__c != null && sliIds.contains(rli.RefSettlementLineItem__c)) {
                result.add(rli.RefSettlementLineItem__c);
            }
            if (rli.RefBankTransaction__c != null && btIds.contains(rli.RefBankTransaction__c)) {
                result.add(rli.RefBankTransaction__c);
            }
        }

        return result;
    }

    /**
     * Returns FiduciaryOthers Ids that own at least one RLI whose
     * parent Reconciliation is in Draft status.
     * @param excludeReconId  Reconciliation to exclude (current recon); null = exclude none
     */
    public Set<Id> queryFoIdsHavingDraftRli(Set<Id> foIds, Id excludeReconId) {
        Set<Id> result = new Set<Id>();

        if (foIds == null || foIds.isEmpty()) {
            return result;
        }

        for (ReconciliationLineItem__c rli : [
            SELECT RefFiduciaryOthers__c
            FROM ReconciliationLineItem__c
            WHERE
                RefReconciliation__r.Status__c = 'Draft'
                AND RefReconciliation__c != :excludeReconId
                AND RefFiduciaryOthers__c IN :foIds
            WITH SECURITY_ENFORCED
        ]) {
            if (rli.RefFiduciaryOthers__c != null) {
                result.add(rli.RefFiduciaryOthers__c);
            }
        }

        return result;
    }

    /**
     * Returns BankTransaction Ids that own at least one RLI whose
     * parent Reconciliation is in Draft status.
     * @param excludeReconId  Reconciliation to exclude (current recon); null = exclude none
     */
    public Set<Id> queryBtIdsHavingDraftRli(Set<Id> btIds, Id excludeReconId) {
        Set<Id> result = new Set<Id>();

        if (btIds == null || btIds.isEmpty()) {
            return result;
        }

        for (ReconciliationLineItem__c rli : [
            SELECT RefBankTransaction__c
            FROM ReconciliationLineItem__c
            WHERE
                RefReconciliation__r.Status__c = 'Draft'
                AND RefReconciliation__c != :excludeReconId
                AND IsOtherCharges__c != TRUE
                AND RefBankTransaction__c IN :btIds
            WITH SECURITY_ENFORCED
        ]) {
            if (rli.RefBankTransaction__c != null) {
                result.add(rli.RefBankTransaction__c);
            }
        }

        return result;
    }

    /**
     * Returns the subset of sliIds that already have at least one
     * ReconciliationLineItem referencing them (via RefSettlementLineItem__c).
     * Used to prevent adding already-reconciled SLIs.
     * @param excludeReconId  Reconciliation to exclude (current recon); null = exclude none
     */
    public Set<Id> querySliIdsHavingRli(Set<Id> sliIds, Id excludeReconId) {
        Set<Id> result = new Set<Id>();
        if (sliIds == null || sliIds.isEmpty())
            return result;

        for (AggregateResult ar : [
            SELECT RefSettlementLineItem__c sliId
            FROM ReconciliationLineItem__c
            WHERE
                RefSettlementLineItem__c IN :sliIds
                AND RefReconciliation__r.Status__c = :REC_Consts.ReconciliationStatus.DRAFT
                AND RefReconciliation__c != :excludeReconId
                AND IsOtherCharges__c != TRUE
            WITH SECURITY_ENFORCED
            GROUP BY RefSettlementLineItem__c
        ]) {
            result.add((Id) ar.get('sliId'));
        }
        return result;
    }

    /**
     * Fetches FO-referenced RLIs by Reconciliation Id,
     * with cross-object FiduciaryOthers fields.
     * Used by the Statement-based Selected FO table.
     */
    public List<ReconciliationLineItem__c> queryByReconWithFiduciaryOthers(Id reconciliationId) {
        List<String> fields = new List<String>(getFieldNames());
        fields.addAll(
            REC_FiduciaryOthersSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefFiduciaryOthers__c)
        );
        fields.add('BTAccountName__r.Name');

        String query = '';
        query += 'SELECT {0} FROM ReconciliationLineItem__c ';
        query += 'WHERE RefReconciliation__c = :reconciliationId ';
        query += 'AND RefFiduciaryOthers__c != null ';
        query += 'AND IsOtherCharges__c != true ';
        query += 'ORDER BY Name DESC ';
        query += 'LIMIT 2000';

        String soql = String.format(query, new List<String>{ String.join(fields, ', ') });

        return (List<ReconciliationLineItem__c>) Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'reconciliationId' => reconciliationId },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Fetches RLIs with Statement relationship fields for Statement-based reconciliation page.
     */
    public List<ReconciliationLineItem__c> queryByReconWithStatement(Id reconciliationId) {
        return [
            SELECT
                Id,
                Name,
                ReconciledAMT__c,
                NotReconciledAMT__c,
                NotMatchedPremiumAMT__c,
                TotalPremiumAMT__c,
                MatchingStatus__c,
                RefStatement__c,
                RefStatement__r.Name,
                RefStatement__r.TransactionDate__c,
                RefStatement__r.Insurer__c,
                RefStatement__r.Insurer__r.Name,
                RefStatement__r.PolicyHolder__c,
                RefStatement__r.PolicyHolder__r.Name,
                RefStatement__r.LOB3__c,
                RefStatement__r.Currency__c,
                RefStatement__r.TotalPremiumAMT__c,
                RefStatement__r.TotalBrokerageAMT__c,
                RefStatement__r.Remarks__c,
                RefStatement__r.RefBankTransaction__c,
                RefStatement__r.RefBankTransaction__r.Name
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :reconciliationId AND RefStatement__c != NULL
            WITH USER_MODE
            ORDER BY RefStatement__r.Name ASC
            LIMIT 2000
        ];
    }

    /**
     * Fetches P_C Reconciliation Line Items for a Reconciliation.
     * Used to load Other Charges RLIs on page load and during Draft/Confirm.
     */
    public List<ReconciliationLineItem__c> queryPcRlisByRecon(Id reconciliationId) {
        return [
            SELECT
                Id,
                COA_lk__c,
                COAName_fm__c,
                ClosingType__c,
                OriginAmount__c,
                OriginCurrency__c,
                OriginSettlementLineItem__c,
                OriginSettlementLineItem__r.Name,
                OriginBankTransaction__c,
                OriginBankTransaction__r.Name,
                RefBankTransaction__c,
                RefSettlementLineItem__c,
                RefSettlementLineItem__r.Name,
                Remarks__c,
                BTCurrency__c,
                SettlementCurrency__c,
                FXRateOrigintoSettlement__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :reconciliationId AND IsOtherCharges__c = TRUE
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
        ];
    }

    /**
     * Fetches existing RLIs for a Reconciliation (used by draft process).
     * Includes both BT- and FO-referenced items.
     */
    public List<ReconciliationLineItem__c> queryForDraft(Id reconciliationId) {
        return [
            SELECT
                Id,
                RefSettlementLineItem__r.OtherCharges__c,
                RefSettlementLineItem__r.OriginAmount__c,
                RefSettlementLineItem__r.OriginCurrency__c,
                RefSettlementLineItem__r.BizRegion__c,
                RefBankTransaction__c,
                RefFiduciaryOthers__c,
                ReconciledAMT__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :reconciliationId AND IsOtherCharges__c != TRUE
            WITH SECURITY_ENFORCED
            ORDER BY Name DESC
        ];
    }

    /**
     * Fetches existing RLIs for a BT-based Reconciliation draft process.
     * Returns all RLIs (both BT-referenced base and SLI-referenced details)
     * with fields needed for draft calculation.
     *
     * Uses default fields from RLI, BT, and SLI selectors via relationship prefixing.
     */
    public List<ReconciliationLineItem__c> queryForBtBasedDraft(Id reconciliationId) {
        List<String> fields = new List<String>(getFieldNames());
        fields.addAll(
            REC_BankTransactionSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefBankTransaction__c)
        );
        fields.addAll(
            REC_SettlementLineItemSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefSettlementLineItem__c)
        );

        String query = '';
        query += 'SELECT {0} FROM ReconciliationLineItem__c ';
        query += 'WHERE RefReconciliation__c = :reconciliationId ';
        query += 'AND IsOtherCharges__c != true ';
        query += 'ORDER BY Name DESC';

        String soql = String.format(query, new List<String>{ String.join(fields, ', ') });

        return (List<ReconciliationLineItem__c>) Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'reconciliationId' => reconciliationId },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Fetches existing RLIs for a Statement-based Reconciliation draft process.
     * Returns all non-P_C RLIs (Statement-referenced base + SLI-referenced + FO-referenced details)
     * with fields needed for draft calculation.
     */
    public List<ReconciliationLineItem__c> queryForStmtBasedDraft(Id reconciliationId) {
        List<String> fields = new List<String>(getFieldNames());
        fields.addAll(
            REC_SettlementLineItemSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefSettlementLineItem__c)
        );
        fields.addAll(
            REC_FiduciaryOthersSelector.getInstance()
                .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefFiduciaryOthers__c)
        );
        fields.add('RefStatement__c');
        fields.add('RefStatement__r.BizRegion__c');
        fields.add('RefStatement__r.Currency__c');
        fields.add('RefStatement__r.TotalBrokerageAMT__c');
        fields.add('RefStatement__r.TotalPremiumAMT__c');
        fields.add('RefStatement__r.TransactionDate__c');
        fields.add('RefStatement__r.RefBankTransaction__c');
        fields.add('RefStatementLineItem__c');
        fields.add('TotalPremiumAMT__c');

        String query = '';
        query += 'SELECT {0} FROM ReconciliationLineItem__c ';
        query += 'WHERE RefReconciliation__c = :reconciliationId ';
        query += 'AND IsOtherCharges__c != true ';
        query += 'ORDER BY Name DESC';

        String soql = String.format(query, new List<String>{ String.join(fields, ', ') });

        return (List<ReconciliationLineItem__c>) Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'reconciliationId' => reconciliationId },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Fetches StmtLI RLIs (RefStatementLineItem__c != null) for a Reconciliation.
     * Used by the Statement Line Items accordion table on the Statement-based page.
     */
    public List<ReconciliationLineItem__c> queryStmtLineItemRlis(Id reconciliationId) {
        return [
            SELECT
                Id,
                RefStatementLineItem__c,
                FXAmountPremiumLocal__c,
                Remarks__c,
                RefStatementLineItem__r.Name,
                RefStatementLineItem__r.TransactionDate__c,
                RefStatementLineItem__r.Insurer_lk__c,
                RefStatementLineItem__r.Insurer_lk__r.Name,
                RefStatementLineItem__r.PolicyHolder_lk__c,
                RefStatementLineItem__r.PolicyHolder_lk__r.Name,
                RefStatementLineItem__r.PolicyNo__c,
                RefStatementLineItem__r.LOB3__c,
                RefStatementLineItem__r.LOBDetails__c,
                RefStatementLineItem__r.Brokerage__c,
                RefStatementLineItem__r.BrokerageRatePct__c,
                RefStatementLineItem__r.Currency_fm__c
            FROM ReconciliationLineItem__c
            WHERE RefReconciliation__c = :reconciliationId AND RefStatementLineItem__c != NULL
            WITH USER_MODE
            ORDER BY RefStatementLineItem__r.Name ASC
            LIMIT 2000
        ];
    }
}