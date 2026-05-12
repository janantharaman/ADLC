/**
 * REC_RelatedReconCtrl — Screen controller for the Related Reconciliation modal.
 *
 * LWC: recRelatedReconciliationModal
 *
 * Delegates to REC_ReconciliationDomain for creation and
 * REC_ReconciliationLineItemSelector for querying.
 */
public with sharing class REC_RelatedReconCtrl {
    private static final REC_ReconciliationLineItemSelector RLI_SEL = REC_ReconciliationLineItemSelector.getInstance();

    // ═════════════════════════════════════════════════════════════════════════
    //  Inquiry
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<ReconciliationLineItem__c> inquiryReconciliationLineItems(Id recordId) {
        if (recordId == null) {
            return null;
        }
        try {
            ExceptionSimulator.throwIfActive();
            return RLI_SEL.queryByBaseRecord(recordId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  New Button State
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Boolean checkNewButtonDisabled(Id recordId) {
        try {
            ExceptionSimulator.throwIfActive();

            if (recordId == null) {
                return true;
            }

            Map<Id, Boolean> resultMap = REC_ReconciliationLineItemDomain.checkNewReconciliationDisabled(
                new Set<Id>{ recordId }
            );

            return resultMap.get(recordId) ?? false;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Create New Reconciliation
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Id createNewReconciliation(Id baseRecordId) {
        try {
            ExceptionSimulator.throwIfActive();
            return REC_ReconciliationDomain.createNewReconciliation(baseRecordId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Check Statement Upload Disabled
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Boolean checkStatementUploadDisabled(Id recordId) {
        try {
            ExceptionSimulator.throwIfActive();
            if (recordId == null) {
                return true;
            }

            Map<Id, Boolean> resultMap = REC_BankTransactionDomain.checkStatementUploadDisabled(new Set<Id>{ recordId });

            return resultMap.get(recordId) ?? false;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Resolve Account IDs by ERPCode
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Map<String, Id> resolveAccountsByERPCodes(List<String> erpCodes) {
        try {
            ExceptionSimulator.throwIfActive();
            if (erpCodes == null || erpCodes.isEmpty()) {
                return new Map<String, Id>();
            }

            Map<String, Id> result = new Map<String, Id>();
            List<Account> accounts = [
                SELECT Id, ERPCode__c
                FROM Account
                WHERE ERPCode__c IN :erpCodes
                WITH USER_MODE
            ];
            for (Account acc : accounts) {
                result.put(acc.ERPCode__c, acc.Id);
            }
            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Validate Statement Data against BankTransaction
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static REC_StatementDomain.StatementValidationResult validateStatementData(Id recordId, String rowsJson) {
        try {
            ExceptionSimulator.throwIfActive();

            if (recordId == null || String.isBlank(rowsJson)) {
                throw new AuraHandledException('Invalid parameters');
            }

            List<BankTransaction__c> bts = [
                SELECT Id, AccountName__c, TransactionDate__c, OriginAmount__c
                FROM BankTransaction__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];

            if (bts.isEmpty()) {
                throw new AuraHandledException('BankTransaction not found: ' + recordId);
            }

            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(rowsJson);
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (Object item : rawList) {
                rows.add((Map<String, Object>) item);
            }

            return REC_StatementDomain.validateParsedData(bts[0], rows);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Create Statements from Upload
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Map<String, Integer> createStatementsFromUpload(Id recordId, String rowsJson) {
        try {
            ExceptionSimulator.throwIfActive();

            if (recordId == null || String.isBlank(rowsJson)) {
                throw new AuraHandledException('Invalid parameters');
            }

            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(rowsJson);
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (Object item : rawList) {
                rows.add((Map<String, Object>) item);
            }

            return REC_StatementDomain.createStatements(recordId, rows);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}