/**
 * REC_BankTransactionSelector — Selector for BankTransaction__c.
 *
 * Defines queryable and updatable field sets.  All query logic is inherited
 * from REC_SelectorBase; only field definitions live here.
 */
public inherited sharing class REC_BankTransactionSelector extends REC_SelectorBase {
    // ── Singleton ────────────────────────────────────────────────────────
    private static final REC_BankTransactionSelector INSTANCE = new REC_BankTransactionSelector();
    public static REC_BankTransactionSelector getInstance() {
        return INSTANCE;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Abstract Overrides
    // ═════════════════════════════════════════════════════════════════════════

    public override Schema.SObjectType getSObjectType() {
        return BankTransaction__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFields() {
        return new List<Schema.SObjectField>{
            BankTransaction__c.Id,
            BankTransaction__c.Name,
            BankTransaction__c.Status__c,
            BankTransaction__c.TransactionDate__c,
            BankTransaction__c.Currency__c,
            BankTransaction__c.AccountName__c,
            BankTransaction__c.Depositor__c,
            BankTransaction__c.Balance__c,
            BankTransaction__c.TotalClearedAmount__c,
            BankTransaction__c.NetBalanceAftCleared__c,
            BankTransaction__c.Remarks__c,
            BankTransaction__c.OriginAmount__c,
            BankTransaction__c.BizRegion__c
        };
    }

    public override List<Schema.SObjectField> getUpdatableFields() {
        return new List<Schema.SObjectField>{ BankTransaction__c.Status__c, BankTransaction__c.Remarks__c };
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Queries
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Loads BankTransactions by Ids with the reconciliation-relevant field subset.
     * (Used during RLI draft to read/update cleared amounts.)
     */
    public List<BankTransaction__c> queryForReconciliation(Set<Id> ids) {
        return [
            SELECT
                Id,
                Name,
                Status__c,
                TotalClearedAmount__c,
                NetBalanceAftCleared__c,
                OriginAmount__c,
                Currency__c,
                TransactionDate__c,
                BizRegion__c,
                AccountName__c,
                Balance__c
            FROM BankTransaction__c
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }
}