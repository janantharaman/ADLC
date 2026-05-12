/**
 * REC_SLIInquiryCtrl — Screen controller for the SLI Inquiry page.
 *
 * LWC: recSettlementLineItemInquiry
 *
 * Thin orchestrator: delegates to Selector / Domain / UnitOfWork.
 * All @AuraEnabled methods return REC_Response for consistent LWC handling.
 */
public with sharing class REC_SLIInquiryCtrl {
    private static final REC_SettlementLineItemSelector SEL = REC_SettlementLineItemSelector.getInstance();

    // ═════════════════════════════════════════════════════════════════════════
    //  Inquiry
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<SettlementLineItem__c> inquirySettlementLineItems(String filters, String relFields) {
        try {
            return (List<SettlementLineItem__c>) SEL.queryByFilter(filters, relFields);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SettlementLineItem__c> inquiryEvaluationSLIs(String filters, String relFields) {
        try {
            return SEL.queryByFilterForEvaluation(filters, relFields);
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
    public static REC_TableHelper.SaveResponse saveSettlementLineItems(String rowsJson) {
        try {
            List<SObject> records = REC_UnitOfWork.parseRows(
                rowsJson,
                SettlementLineItem__c.SObjectType,
                SEL.getUpdatableFields()
            );

            List<REC_TableHelper.CellError> valErrors = REC_SettlementLineItemDomain.validate(
                (List<SettlementLineItem__c>) records
            );

            if (!valErrors.isEmpty()) {
                return new REC_TableHelper.SaveResponse(0, valErrors.size(), valErrors);
            }

            return REC_UnitOfWork.updatePartial(records);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Evaluation — Update Evaluation Date
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static void updateSLIEvaluationDate(List<Id> sliIds, Id periodCloseId) {
        try {
            Date evaluationDate = null;
            if (periodCloseId != null) {
                PeriodClose__c pc = [SELECT EndDate__c FROM PeriodClose__c WHERE Id = :periodCloseId WITH USER_MODE];
                evaluationDate = pc.EndDate__c;
            }

            List<SettlementLineItem__c> slis = [
                SELECT Id, EvaluationDate__c
                FROM SettlementLineItem__c
                WHERE Id IN :sliIds
                WITH USER_MODE
            ];

            for (SettlementLineItem__c sli : slis) {
                sli.EvaluationDate__c = evaluationDate;
            }

            update slis;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Split
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<SettlementLineItem__c> splitSettlementLineItem(Id recordId, Decimal amount1, Decimal amount2) {
        try {
            return REC_SettlementLineItemDomain.split(recordId, amount1, amount2);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkSplitConditions(Id sliId) {
        try {
            SettlementLineItem__c sli = [
                SELECT Id, Status__c, SettlementStatus__c, RefSettlement__c, SplitKey__c
                FROM SettlementLineItem__c
                WHERE Id = :sliId
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            validateSliForSplit(sli, false);

            SettlementLineItem__c counterpartySli = [
                SELECT Id, Status__c, SettlementStatus__c, SplitKey__c
                FROM SettlementLineItem__c
                WHERE SplitKey__c = :sli.SplitKey__c AND Id != :sli.Id AND RefSettlement__c = :sli.RefSettlement__c
                WITH SYSTEM_MODE
                LIMIT 1
            ] ?? null;

            if (counterpartySli == null) {
                throw new SplitException(Label.REC_MSG_SPLIT_CPTY_NOT_FOUND);
            }
            validateSliForSplit(counterpartySli, true);

            return true;
        } catch (Exception e) {
            if (!(e instanceof SplitException)) {
                Logger.error(e.getMessage(), e);
                Logger.saveLog();
            }
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void validateSliForSplit(SettlementLineItem__c sli, Boolean isCounterparty) {
        if (sli.SettlementStatus__c != REC_Consts.SettlementStatus.NOT_AVAILABLE) {
            String msg = isCounterparty
                ? Label.REC_MSG_SPLIT_INVALID_CPTY_SETTLE_STATUS
                : Label.REC_MSG_SPLIT_INVALID_SETTLE_STATUS;
            throw new SplitException(
                String.format(msg, new List<Object>{ sli.SettlementStatus__c, REC_Consts.SettlementStatus.NOT_AVAILABLE })
            );
        }
        if (sli.Status__c != REC_Consts.STCStatus.PROVISIONAL && sli.Status__c != REC_Consts.STCStatus.CONFIRM) {
            String msg = isCounterparty ? Label.REC_MSG_SPLIT_INVALID_CPTY_STATUS : Label.REC_MSG_SPLIT_INVALID_STATUS;
            throw new SplitException(
                String.format(
                    msg,
                    new List<Object>{ sli.Status__c, REC_Consts.STCStatus.PROVISIONAL, REC_Consts.STCStatus.CONFIRM }
                )
            );
        }
    }

    public class SplitException extends Exception {
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Confirm STC Status
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Map<String, Integer> confirmSliStatus(List<Id> sliIds) {
        try {
            List<SettlementLineItem__c> slis = [
                SELECT Id, Status__c
                FROM SettlementLineItem__c
                WHERE Id IN :sliIds
                WITH USER_MODE
            ];

            List<SettlementLineItem__c> toUpdate = new List<SettlementLineItem__c>();
            Integer skipped = 0;

            for (SettlementLineItem__c sli : slis) {
                if (sli.Status__c == REC_Consts.STCStatus.PROVISIONAL) {
                    sli.Status__c = REC_Consts.STCStatus.CONFIRM;
                    toUpdate.add(sli);
                } else {
                    skipped++;
                }
            }

            Integer confirmCount = 0;
            Integer errorCount = 0;

            if (!toUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(toUpdate, false);
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        confirmCount++;
                    } else {
                        errorCount++;
                    }
                }
            }

            return new Map<String, Integer>{
                'total' => slis.size(),
                'confirmCount' => confirmCount,
                'errorCount' => errorCount + skipped
            };
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Counterpart Search
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static Map<Id, SettlementLineItem__c> searchCounterparts(List<Id> recordIds) {
        try {
            return REC_SettlementLineItemDomain.searchCounterparts(recordIds);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  PPW Date Update
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static void updatePPWDate(List<Id> sliIds, Date ppwDate) {
        try {
            // 1. Collect Note IDs from the selected SLIs
            List<SettlementLineItem__c> selectedSlis = [
                SELECT Id, Note_lk__c
                FROM SettlementLineItem__c
                WHERE Id IN :sliIds
                WITH USER_MODE
            ];

            Set<Id> noteIds = new Set<Id>();
            for (SettlementLineItem__c sli : selectedSlis) {
                if (sli.Note_lk__c != null) {
                    noteIds.add(sli.Note_lk__c);
                }
            }

            // 2. Query all SLIs sharing the same Notes (union with selected)
            List<SettlementLineItem__c> allSlis = [
                SELECT Id, PPWDate__c
                FROM SettlementLineItem__c
                WHERE Id IN :sliIds OR Note_lk__c IN :noteIds
                WITH USER_MODE
            ];

            for (SettlementLineItem__c sli : allSlis) {
                sli.PPWDate__c = ppwDate;
            }
            update allSlis;

            // 3. Update RevisedPPWDate__c on the related Notes
            if (!noteIds.isEmpty()) {
                List<COM_Note__c> notes = [
                    SELECT Id, RevisedPPWDate__c
                    FROM COM_Note__c
                    WHERE Id IN :noteIds
                    WITH USER_MODE
                ];
                for (COM_Note__c note : notes) {
                    note.RevisedPPWDate__c = ppwDate;
                }
                update notes;
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}