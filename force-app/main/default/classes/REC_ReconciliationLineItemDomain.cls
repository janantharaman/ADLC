public with sharing class REC_ReconciliationLineItemDomain {
    private static final REC_ReconciliationLineItemSelector RLI_SEL = REC_ReconciliationLineItemSelector.getInstance();

    private static final SObjectType SLI_TYPE = Schema.SettlementLineItem__c.getSObjectType();
    private static final SObjectType BT_TYPE = Schema.BankTransaction__c.getSObjectType();

    // ═════════════════════════════════════════════════════════════════════════
    //  New Reconciliation — Disabled Check
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Determines whether creating a new Reconciliation should be disabled for
     * each given base-record Id (SettlementLineItem__c or BankTransaction__c).
     *
     * Disabled when ANY of the following is true:
     *   SLI  →  SettlementStatus__c = 'Clear'
     *        OR  any related RLI's parent Reconciliation Status = 'Draft'
     *   BT   →  Status__c = 'Clear'
     *        OR  any related RLI's parent Reconciliation Status = 'Draft'
     *
     * Bulkified — safe to call from triggers or batch contexts.
     *
     * @param recordIds  Set of SettlementLineItem__c / BankTransaction__c Ids
     * @return Map<Id, Boolean>  true = New button should be disabled
     */
    public static Map<Id, Boolean> checkNewReconciliationDisabled(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Boolean>();
        }

        Map<Id, Boolean> result = new Map<Id, Boolean>();
        Set<Id> sliIds = new Set<Id>();
        Set<Id> btIds = new Set<Id>();

        // ── Classify by object type ───────────────────────────────────────
        for (Id recordId : recordIds) {
            SObjectType objType = recordId.getSObjectType();
            if (objType == SLI_TYPE) {
                sliIds.add(recordId);
            } else if (objType == BT_TYPE) {
                btIds.add(recordId);
            }
            result.put(recordId, false);
        }

        // ── Condition 1: SLI SettlementStatus__c = 'Clear' ────────────────
        if (!sliIds.isEmpty()) {
            for (SettlementLineItem__c sli : [
                SELECT Id
                FROM SettlementLineItem__c
                WHERE
                    Id IN :sliIds
                    AND (SettlementStatus__c = :REC_Consts.SettlementStatus.CLEAR
                    OR Status__c != :REC_Consts.STCStatus.CONFIRM)
                WITH SECURITY_ENFORCED
            ]) {
                result.put(sli.Id, true);
            }
        }

        // ── Condition 1: BT Status__c = 'Clear' ──────────────────────────
        if (!btIds.isEmpty()) {
            for (BankTransaction__c bt : [
                SELECT Id
                FROM BankTransaction__c
                WHERE Id IN :btIds AND Status__c = :REC_Consts.BankTransactionStatus.CLEAR
                WITH SECURITY_ENFORCED
            ]) {
                result.put(bt.Id, true);
            }
        }

        // ── Condition 2: Related RLI's Reconciliation Status = 'Draft' ───
        Set<Id> draftBaseIds = RLI_SEL.queryBaseRecordIdsHavingDraftRli(sliIds, btIds, null);
        for (Id baseId : draftBaseIds) {
            result.put(baseId, true);
        }

        return result;
    }
}