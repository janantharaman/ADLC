public without sharing class SettlementLineItem_tr extends TriggerHandler {
    private Map<Id, SettlementLineItem__c> mapNew;
    private Map<Id, SettlementLineItem__c> mapOld;
    private List<SettlementLineItem__c> listNew;
    private List<SettlementLineItem__c> listOld;

    public SettlementLineItem_tr() {
        this.mapNew = (Map<Id, SettlementLineItem__c>) Trigger.newMap;
        this.mapOld = (Map<Id, SettlementLineItem__c>) Trigger.oldMap;
        this.listNew = (List<SettlementLineItem__c>) Trigger.new;
        this.listOld = (List<SettlementLineItem__c>) Trigger.old;
    }

    public override void beforeUpdate() {
        updateEvaluationFxRate();
    }

    public override void afterInsert() {
        try {
            ExceptionSimulator.throwIfActive();
            REC_SettlementLineItemDomain.processNoteStatusUpdate(listNew);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();

            throw new SettlementLineItemTriggerException(e.getMessage());
        }
    }

    public override void afterUpdate() {
        try {
            ExceptionSimulator.throwIfActive();
            REC_SettlementLineItemDomain.processFundedPcCreation(listNew, mapOld);
            REC_SettlementLineItemDomain.processNoteStatusUpdate(listNew, mapOld);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();

            throw new SettlementLineItemTriggerException(e.getMessage());
        }
    }

    public override void afterDelete() {
        try {
            ExceptionSimulator.throwIfActive();
            REC_SettlementLineItemDomain.processNoteStatusUpdate(listOld);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();

            throw new SettlementLineItemTriggerException(e.getMessage());
        }
    }

    public override void afterUndelete() {
        try {
            ExceptionSimulator.throwIfActive();
            REC_SettlementLineItemDomain.processNoteStatusUpdate(listNew);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();

            throw new SettlementLineItemTriggerException(e.getMessage());
        }
    }

    private void updateEvaluationFxRate() {
        try {
            // Find min and max Evaluation dates per Region + Currency to minimize FX.rates API calls
            Map<String, Date> minDates = new Map<String, Date>();
            Map<String, Date> maxDates = new Map<String, Date>();

            Boolean hasEvaluationDateChange = false;
            for (SettlementLineItem__c sli : listNew) {
                SettlementLineItem__c oldSli = mapOld.get(sli.Id);
                if (oldSli.EvaluationDate__c != sli.EvaluationDate__c) {
                    hasEvaluationDateChange = true;
                    if (sli.EvaluationDate__c != null && sli.OriginCurrency__c != null && sli.BizRegion__c != null) {
                        Date evaluationDate = sli.EvaluationDate__c;
                        String key = sli.BizRegion__c + '||' + sli.OriginCurrency__c;
                        if (!minDates.containsKey(key) || evaluationDate < minDates.get(key))
                            minDates.put(key, evaluationDate);
                        if (!maxDates.containsKey(key) || evaluationDate > maxDates.get(key))
                            maxDates.put(key, evaluationDate);
                    }
                }
            }

            if (!hasEvaluationDateChange) {
                return;
            }

            ExceptionSimulator.throwIfActive();

            // Cache rates from FX.rates() for each Region+Currency bounds
            Map<String, Map<Date, Decimal>> rateCache = ExchangeRateService.buildRateCache(minDates, maxDates);

            // Apply FX rates directly on Trigger.new (before context — no DML needed)
            for (SettlementLineItem__c sli : listNew) {
                SettlementLineItem__c oldSli = mapOld.get(sli.Id);

                if (oldSli.EvaluationDate__c != sli.EvaluationDate__c) {
                    if (sli.EvaluationDate__c == null) {
                        sli.EvaluationFXRate__c = 0;
                    } else if (sli.OriginCurrency__c != null && sli.BizRegion__c != null) {
                        Date evaluationDate = sli.EvaluationDate__c;
                        String key = sli.BizRegion__c + '||' + sli.OriginCurrency__c;
                        Decimal newRate = 0;
                        if (rateCache.containsKey(key) && rateCache.get(key).containsKey(evaluationDate)) {
                            newRate = rateCache.get(key).get(evaluationDate) ?? 0;
                        }
                        sli.EvaluationFXRate__c = newRate;
                    }
                }
            }
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
        } finally {
            Logger.saveLog();
        }
    }

    private class SettlementLineItemTriggerException extends Exception {
    }
}