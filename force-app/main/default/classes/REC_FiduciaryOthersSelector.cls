/**
 * REC_FiduciaryOthersSelector — Selector for FiduciaryOthers__c.
 */
public inherited sharing class REC_FiduciaryOthersSelector extends REC_SelectorBase {
    // ── Singleton ────────────────────────────────────────────────────────
    private static final REC_FiduciaryOthersSelector INSTANCE = new REC_FiduciaryOthersSelector();
    public static REC_FiduciaryOthersSelector getInstance() {
        return INSTANCE;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Abstract Overrides
    // ═════════════════════════════════════════════════════════════════════════

    public override Schema.SObjectType getSObjectType() {
        return FiduciaryOthers__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFields() {
        return new List<Schema.SObjectField>{
            FiduciaryOthers__c.Id,
            FiduciaryOthers__c.Name,
            FiduciaryOthers__c.Status__c,
            FiduciaryOthers__c.TransactionDate__c,
            FiduciaryOthers__c.SettlementCurrency__c,
            FiduciaryOthers__c.AccountName__c,
            FiduciaryOthers__c.Depositor__c,
            FiduciaryOthers__c.ReconciledAMT__c,
            FiduciaryOthers__c.NotReconciledAMT__c,
            FiduciaryOthers__c.Remarks__c,
            FiduciaryOthers__c.OriginAmount__c,
            FiduciaryOthers__c.BizRegion__c
        };
    }

    public override List<Schema.SObjectField> getUpdatableFields() {
        return new List<Schema.SObjectField>{
            FiduciaryOthers__c.AccountName__c,
            FiduciaryOthers__c.Status__c,
            FiduciaryOthers__c.Remarks__c
        };
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Queries
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Loads FiduciaryOthers by Ids with the reconciliation-relevant field subset.
     * (Used during RLI draft to read/update reconciled amounts.)
     */
    public List<FiduciaryOthers__c> queryForReconciliation(Set<Id> ids) {
        return [
            SELECT
                Id,
                Name,
                Status__c,
                ReconciledAMT__c,
                NotReconciledAMT__c,
                OriginAmount__c,
                SettlementCurrency__c,
                TransactionDate__c,
                BizRegion__c,
                AccountName__c
            FROM FiduciaryOthers__c
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }
}