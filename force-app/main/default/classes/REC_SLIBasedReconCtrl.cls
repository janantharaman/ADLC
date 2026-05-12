/**
 * REC_SLIBasedReconCtrl — Screen controller for the SLI-based Reconciliation page.
 *
 * LWC: recSettlementLineItemBased
 *
 * This page orchestrates multiple objects (SLI, BT, FO, Recon, RLI).
 * Each call delegates to the appropriate Selector / Domain layer.
 */
public with sharing class REC_SLIBasedReconCtrl {
    private static final REC_SettlementLineItemSelector SLI_SEL = REC_SettlementLineItemSelector.getInstance();
    private static final REC_BankTransactionSelector BT_SEL = REC_BankTransactionSelector.getInstance();
    private static final REC_FiduciaryOthersSelector FO_SEL = REC_FiduciaryOthersSelector.getInstance();
    private static final REC_ReconciliationSelector REC_SEL = REC_ReconciliationSelector.getInstance();
    private static final REC_ReconciliationLineItemSelector RLI_SEL = REC_ReconciliationLineItemSelector.getInstance();

    // ═════════════════════════════════════════════════════════════════════════
    //  Base SLI (returns the RLI that references the base SettlementLineItem)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static ReconciliationLineItem__c getBaseSettlementLineItem(String reconId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }

            List<ReconciliationLineItem__c> rows = RLI_SEL.queryByReconWithSettlementLineItem(reconId);
            return rows.isEmpty() ? null : rows[0];
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Bank Transaction Inquiry (for BT selection panel)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<BankTransaction__c> inquiryBankTransactions(
        String filters,
        String relFields,
        String reconciliationId
    ) {
        try {
            ExceptionSimulator.throwIfActive();

            List<BankTransaction__c> results = (List<BankTransaction__c>) BT_SEL.queryByFilter(filters, relFields);

            if (results.isEmpty()) {
                return results;
            }

            // Exclude BTs referenced by other Draft Reconciliation RLIs
            Set<Id> btIds = new Set<Id>();
            for (BankTransaction__c bt : results) {
                btIds.add(bt.Id);
            }
            Set<Id> draftBtIds = RLI_SEL.queryBtIdsHavingDraftRli(btIds, reconciliationId);

            if (draftBtIds.isEmpty()) {
                return results;
            }

            List<BankTransaction__c> filtered = new List<BankTransaction__c>();
            for (BankTransaction__c bt : results) {
                if (!draftBtIds.contains(bt.Id)) {
                    filtered.add(bt);
                }
            }
            return filtered;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reconciliation Line Items (BT-referenced, for selected-items table)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<ReconciliationLineItem__c> getRelatedReconciliationLineItems(String reconciliationId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconciliationId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }
            return RLI_SEL.queryByReconWithBankTransaction(reconciliationId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Fiduciary Others Inquiry (for FO panel)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<FiduciaryOthers__c> inquiryFiduciaryOthers(
        String filters,
        String relFields,
        String reconciliationId
    ) {
        try {
            ExceptionSimulator.throwIfActive();

            // 1. Enforce Status__c != 'Clear' — merge with incoming LWC filters
            Map<String, Object> filterMap = String.isNotBlank(filters)
                ? (Map<String, Object>) JSON.deserializeUntyped(filters)
                : new Map<String, Object>();
            filterMap.put('Status__c__exclude', new List<String>{ REC_Consts.FiduciaryOthersStatus.CLEAR });

            List<FiduciaryOthers__c> results = (List<FiduciaryOthers__c>) FO_SEL.queryByFilter(
                JSON.serialize(filterMap),
                relFields
            );

            if (results.isEmpty()) {
                return results;
            }

            // 2. Exclude FOs referenced by Draft Reconciliation RLIs
            Set<Id> foIds = new Set<Id>();
            for (FiduciaryOthers__c fo : results) {
                foIds.add(fo.Id);
            }
            Set<Id> draftFoIds = RLI_SEL.queryFoIdsHavingDraftRli(foIds, reconciliationId);

            if (draftFoIds.isEmpty()) {
                return results;
            }

            List<FiduciaryOthers__c> filtered = new List<FiduciaryOthers__c>();
            for (FiduciaryOthers__c fo : results) {
                if (!draftFoIds.contains(fo.Id)) {
                    filtered.add(fo);
                }
            }
            return filtered;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Draft / Confirm (delegates to REC_ReconciliationDomain)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static void draftSettlementLineItemBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        Decimal otherCharges,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        try {
            ExceptionSimulator.throwIfActive();

            REC_ReconciliationDomain.draftSettlementLineItemBased(
                reconciliationId,
                details,
                otherCharges,
                otherChargeRliItems
            );
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void confirmSettlementLineItemBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        Decimal otherCharges,
        SettlementLineItem__c baseSliInput,
        List<SettlementLineItem__c> otherChargeItems,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        try {
            ExceptionSimulator.throwIfActive();

            REC_ReconciliationDomain.confirmSettlementLineItemBased(
                reconciliationId,
                details,
                otherCharges,
                baseSliInput,
                otherChargeItems,
                otherChargeRliItems
            );
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Other Charges (P_C RLIs + P_C SLIs)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<ReconciliationLineItem__c> getPcOtherChargesRlis(String reconciliationId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconciliationId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }
            return RLI_SEL.queryPcRlisByRecon(reconciliationId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SettlementLineItem__c> getOtherCharges(String reconciliationId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconciliationId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }
            return SLI_SEL.queryOtherChargesByRecon(reconciliationId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getReconciliationStatus(String reconciliationId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconciliationId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }
            return REC_SEL.queryStatus(reconciliationId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}