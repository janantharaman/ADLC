/**
 * REC_BTInquiryCtrl — Screen controller for the Bank Transaction Inquiry page.
 *
 * LWC: recBankTransactionInquiry
 *
 * Thin orchestrator: delegates to Selector / Domain / UnitOfWork.
 */
public with sharing class REC_BTInquiryCtrl {
    private static final REC_BankTransactionSelector SEL = REC_BankTransactionSelector.getInstance();

    // ═════════════════════════════════════════════════════════════════════════
    //  Inquiry
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<BankTransaction__c> inquiryBankTransactions(String filters, String relFields) {
        try {
            return (List<BankTransaction__c>) SEL.queryByFilter(filters, relFields);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Save
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static REC_TableHelper.SaveResponse saveBankTransactions(String rowsJson) {
        try {
            List<SObject> records = REC_UnitOfWork.parseRows(
                rowsJson,
                BankTransaction__c.SObjectType,
                SEL.getUpdatableFields()
            );

            List<REC_TableHelper.CellError> allErrors = new List<REC_TableHelper.CellError>();

            // Standard validation
            allErrors.addAll(REC_BankTransactionDomain.validate((List<BankTransaction__c>) records));

            // Separate failed rows from saveable rows
            if (!allErrors.isEmpty()) {
                Set<String> failedRowIds = new Set<String>();
                for (REC_TableHelper.CellError ce : allErrors) {
                    failedRowIds.add(ce.rowId);
                }

                List<SObject> saveableRecords = new List<SObject>();
                for (SObject rec : records) {
                    if (!failedRowIds.contains((String) rec.get('Id'))) {
                        saveableRecords.add(rec);
                    }
                }

                if (saveableRecords.isEmpty()) {
                    return new REC_TableHelper.SaveResponse(0, allErrors.size(), allErrors);
                }

                // Partial save: save valid rows, report errors for invalid ones
                REC_TableHelper.SaveResponse partialResult = REC_UnitOfWork.updatePartial(saveableRecords);
                partialResult.cellErrors.addAll(allErrors);
                partialResult.errorCount += failedRowIds.size();
                partialResult.success = false;
                return partialResult;
            }

            return REC_UnitOfWork.updatePartial(records);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Fiduciary Liability Mapping
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Map<Id, String> validateTransactionsForFiduciaryOthers(List<Id> transactionIds) {
        try {
            List<BankTransaction__c> transactions = [
                SELECT Id, Status__c, NetBalanceAftCleared__c, (SELECT RLIStatus__c FROM ReconciliationLineItemsAsRef__r)
                FROM BankTransaction__c
                WHERE Id IN :transactionIds
                WITH SYSTEM_MODE
            ];

            Set<String> acceptedBtStatuses = new Set<String>{
                REC_Consts.BankTransactionStatus.PARTIAL,
                REC_Consts.BankTransactionStatus.NONE
            };
            Set<String> excludedRecStatuses = new Set<String>{ REC_Consts.ReconciliationStatus.DRAFT };
            Map<Id, String> errorMap = new Map<Id, String>();

            for (BankTransaction__c bt : transactions) {
                Boolean isValid = bt.NetBalanceAftCleared__c != 0 && acceptedBtStatuses.contains(bt.Status__c);

                if (isValid) {
                    for (ReconciliationLineItem__c rli : bt.ReconciliationLineItemsAsRef__r) {
                        if (excludedRecStatuses.contains(rli.RLIStatus__c)) {
                            isValid = false;
                            break;
                        }
                    }
                }

                if (!isValid) {
                    errorMap.put(bt.Id, 'This Bank Transaction is already reconciled or referenced elsewhere.');
                }
            }

            return errorMap;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createFiduciaryOthers(List<FiduciaryOthers__c> records) {
        try {
            String userBizRegion = Util.getBizRegion();
            for (FiduciaryOthers__c fo : records) {
                fo.Status__c = REC_Consts.FiduciaryOthersStatus.NONE;
                fo.ReconciledAmt__c = 0;
                fo.BizRegion__c = userBizRegion;
                fo.NotReconciledAmt__c = fo.OriginAmount__c;
            }

            insert records;

            Map<Id, FiduciaryOthers__c> transactionToFiduciaryMap = new Map<Id, FiduciaryOthers__c>();
            for (FiduciaryOthers__c fo : records) {
                transactionToFiduciaryMap.put(fo.RefBankTransaction__c, fo);
            }

            List<BankTransaction__c> transactionsToUpdate = [
                SELECT TotalClearedAmount__c, OriginAmount__c, NetBalanceAftCleared__c, Status__c, RefFiduciaryOthers__c
                FROM BankTransaction__c
                WHERE Id IN :transactionToFiduciaryMap.keySet()
                WITH SYSTEM_MODE
            ];

            for (BankTransaction__c bt : transactionsToUpdate) {
                FiduciaryOthers__c fo = transactionToFiduciaryMap.get(bt.Id);
                bt.RefFiduciaryOthers__c = fo.Id;
                bt.Status__c = REC_Consts.BankTransactionStatus.CLEAR;
                bt.NetBalanceAftCleared__c = 0;
                bt.TotalClearedAmount__c = bt.OriginAmount__c;
            }

            if (!transactionsToUpdate.isEmpty()) {
                update transactionsToUpdate;
            }
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Account Depositor Mapping
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<AccountDepositor__c> findAccountDepositor(String bizRegion, Id accountNameId, String depositorName) {
        try {
            String resolvedBizRegion = String.isNotBlank(bizRegion) ? bizRegion : Util.getBizRegion();
            return AccountDepositorService.findActiveByBizRegionAccountDepositor(
                resolvedBizRegion,
                accountNameId,
                depositorName
            );
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> findAccountDepositorByDepositor(String bizRegion, String depositorName) {
        try {
            String resolvedBizRegion = String.isNotBlank(bizRegion) ? bizRegion : Util.getBizRegion();
            Map<String, Object> result = new Map<String, Object>();

            List<AccountDepositor__c> existing = AccountDepositorService.findActiveByBizRegionDepositor(
                resolvedBizRegion,
                depositorName
            );

            if (!existing.isEmpty()) {
                result.put('found', true);
                result.put('accountNameId', existing[0].AccountName__c);
                result.put('recordId', existing[0].Id);
            } else {
                result.put('found', false);
            }

            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateBankTransactionAccountName(Id bankTransactionId, Id accountNameId) {
        try {
            BankTransaction__c bt = new BankTransaction__c(Id = bankTransactionId, AccountName__c = accountNameId);
            update bt;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> saveAccountDepositorMapping(
        String bizRegion,
        String depositorName,
        Id accountNameId,
        String remarks,
        String updateScope,
        Id bankTransactionId
    ) {
        try {
            String resolvedBizRegion = String.isNotBlank(bizRegion) ? bizRegion : Util.getBizRegion();
            Map<String, Object> result = new Map<String, Object>();

            // Check for existing record with same key (IsActive + BizRegion + Depositor + AccountName + UpdateScope)
            List<AccountDepositor__c> existing = AccountDepositorService.findActiveByFullKey(
                resolvedBizRegion,
                depositorName,
                accountNameId,
                updateScope
            );

            if (!existing.isEmpty()) {
                // Append Remarks to existing record
                AccountDepositor__c existingAd = existing[0];
                if (String.isNotBlank(remarks)) {
                    existingAd.Remarks__c =
                        (String.isNotBlank(existingAd.Remarks__c) ? existingAd.Remarks__c + '\n' : '') + remarks;
                    update existingAd;
                }
                result.put('isExisting', true);
                result.put('recordId', existingAd.Id);
            } else {
                // Create new AccountDepositor
                AccountDepositor__c newAd = new AccountDepositor__c(
                    BizRegion__c = resolvedBizRegion,
                    Depositor__c = depositorName,
                    AccountName__c = accountNameId,
                    Remarks__c = remarks,
                    UpdateScope__c = updateScope,
                    IsActive__c = true
                );
                insert newAd;
                result.put('isExisting', false);
                result.put('recordId', newAd.Id);

                // If UpdateScope is 'None', manually update the BankTransaction
                // (trigger won't auto-update in this case)
                if (updateScope == 'None' && bankTransactionId != null) {
                    BankTransaction__c bt = new BankTransaction__c(Id = bankTransactionId, AccountName__c = accountNameId);
                    update bt;
                }
            }

            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}