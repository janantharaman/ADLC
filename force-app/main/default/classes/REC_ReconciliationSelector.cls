/**
 * REC_ReconciliationSelector — Selector for Reconciliation__c.
 */
public inherited sharing class REC_ReconciliationSelector extends REC_SelectorBase {
    // ── Singleton ────────────────────────────────────────────────────────
    private static final REC_ReconciliationSelector INSTANCE = new REC_ReconciliationSelector();
    public static REC_ReconciliationSelector getInstance() {
        return INSTANCE;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Abstract Overrides
    // ═════════════════════════════════════════════════════════════════════════

    public override Schema.SObjectType getSObjectType() {
        return Reconciliation__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFields() {
        return new List<Schema.SObjectField>{
            Reconciliation__c.Id,
            Reconciliation__c.Name,
            Reconciliation__c.BaseSettlementLineItem__c,
            Reconciliation__c.BaseBankTransaction__c,
            Reconciliation__c.BaseType_fm__c
        };
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Queries
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Get the status of a Reconciliation.
     */
    public String queryStatus(Id reconId) {
        Reconciliation__c rec = [
            SELECT Id, Status__c
            FROM Reconciliation__c
            WHERE Id = :reconId
            WITH USER_MODE
            LIMIT 1
        ];
        return rec.Status__c;
    }
}