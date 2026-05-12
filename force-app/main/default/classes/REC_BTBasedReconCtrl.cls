/**
 * REC_BTBasedReconCtrl — Screen controller for the BT-based Reconciliation page.
 *
 * LWC: recBankTransactionBased
 *
 * This page orchestrates multiple objects (BT, SLI, Recon, RLI).
 * Each call delegates to the appropriate Selector / Domain layer.
 */
public with sharing class REC_BTBasedReconCtrl {
    private static final REC_BankTransactionSelector BT_SEL = REC_BankTransactionSelector.getInstance();
    private static final REC_SettlementLineItemSelector SLI_SEL = REC_SettlementLineItemSelector.getInstance();
    private static final REC_ReconciliationSelector REC_SEL = REC_ReconciliationSelector.getInstance();
    private static final REC_ReconciliationLineItemSelector RLI_SEL = REC_ReconciliationLineItemSelector.getInstance();
    private static final REC_NoteSelector NOTE_SEL = REC_NoteSelector.getInstance();
    private static final Integer DEFAULT_LIMIT = 2000;

    // ═════════════════════════════════════════════════════════════════════════
    //  Base Bank Transaction (returns the RLI that references the base BT)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static ReconciliationLineItem__c getBaseBankTransaction(String reconId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }

            List<ReconciliationLineItem__c> rows = RLI_SEL.queryByReconWithBankTransaction(reconId);
            return rows.isEmpty() ? null : rows[0];
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Settlement Line Item Inquiry (for SLI selection panel)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<SettlementLineItem__c> inquirySettlementLineItems(String filters, String relFields) {
        try {
            ExceptionSimulator.throwIfActive();

            return (List<SettlementLineItem__c>) SLI_SEL.queryByFilter(filters, relFields);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reconciliation Line Items (SLI-referenced, for selected-items table)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<ReconciliationLineItem__c> getRelatedReconciliationLineItems(String reconciliationId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (String.isBlank(reconciliationId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }
            return RLI_SEL.queryByReconWithSettlementLineItem(reconciliationId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SLI Reconciliation Check
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns the subset of SLI Ids that already have at least one
     * ReconciliationLineItem.  Used by the UI to prevent double-selection.
     */
    @AuraEnabled
    public static List<Id> getSliIdsAlreadyReconciled(List<Id> sliIds, String reconciliationId) {
        try {
            ExceptionSimulator.throwIfActive();

            Set<Id> found = RLI_SEL.querySliIdsHavingRli(new Set<Id>(sliIds), reconciliationId);
            return new List<Id>(found);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reconciliation Status
    // ═════════════════════════════════════════════════════════════════════════

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

    // ═════════════════════════════════════════════════════════════════════════
    //  Draft (delegates to REC_ReconciliationDomain)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static REC_Response draftBankTransactionBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        try {
            ExceptionSimulator.throwIfActive();

            String warning = REC_ReconciliationDomain.draftBankTransactionBased(
                reconciliationId,
                details,
                otherChargeRliItems
            );
            REC_Response r = REC_Response.ok(null);
            r.message = warning;
            return r;
        } catch (REC_ReconciliationDomain.REC_ValidationException e) {
            return REC_Response.fromValidation(e.cellErrors);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Confirm (delegates to REC_ReconciliationDomain)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static REC_Response confirmBankTransactionBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        List<SettlementLineItem__c> otherChargeItems,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        try {
            ExceptionSimulator.throwIfActive();

            String warning = REC_ReconciliationDomain.confirmBankTransactionBased(
                reconciliationId,
                details,
                otherChargeItems,
                otherChargeRliItems
            );
            REC_Response r = REC_Response.ok(null);
            r.message = warning;
            return r;
        } catch (REC_ReconciliationDomain.REC_ValidationException e) {
            return REC_Response.fromValidation(e.cellErrors);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Other Charges (P_C SLIs linked via OriginReconciliationNo__c)
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

    // ═════════════════════════════════════════════════════════════════════════
    //  SLI Validation
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<REC_TableHelper.CellError> validateSettlementLineItems(List<SettlementLineItem__c> records) {
        try {
            ExceptionSimulator.throwIfActive();

            return REC_SettlementLineItemDomain.validate(records);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Note Inquiry
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<COM_Note__c> inquiryNotes(String filters, String relFields) {
        try {
            ExceptionSimulator.throwIfActive();

            return NOTE_SEL.queryByFilter(filters, relFields);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Related SLI Lookup (by Note IDs)
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<SettlementLineItem__c> getRelatedSlis(List<Id> noteIds) {
        try {
            ExceptionSimulator.throwIfActive();

            return NOTE_SEL.queryRelatedSlis(noteIds, false);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}