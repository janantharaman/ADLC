public without sharing class ExchangeRate_tr extends TriggerHandler {
    private static Boolean isFilling = false;

    private Map<Id, ExchangeRate__c> mapNew;
    private Map<Id, ExchangeRate__c> mapOld;
    private List<ExchangeRate__c> listNew;
    private List<ExchangeRate__c> listOld;

    public ExchangeRate_tr() {
        this.mapNew = (Map<Id, ExchangeRate__c>) Trigger.newMap;
        this.mapOld = (Map<Id, ExchangeRate__c>) Trigger.oldMap;
        this.listNew = (List<ExchangeRate__c>) Trigger.new;
        this.listOld = (List<ExchangeRate__c>) Trigger.old;
    }

    public override void beforeInsert() {
        assignName();
        assignBizRegion();
        checkDuplicate();
    }

    public override void beforeUpdate() {
        checkDuplicate();
    }

    public override void afterInsert() {
        publishExchangeRateUpdateEvent(listNew);
        if (!isFilling) {
            fillHolidayAndWeekendRates(listNew);
        }
    }

    public override void afterUpdate() {
        publishExchangeRateUpdateEvent(listNew);
    }

    private void publishExchangeRateUpdateEvent(List<ExchangeRate__c> rates) {
        try {
            ExecuteAsyncJob__e evt = new ExecuteAsyncJob__e(
                ClassName__c = 'ExchangeRateUpdateJob',
                Payload__c = JSON.serialize(rates)
            );
            Database.SaveResult sr = EventBus.publish(evt);
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    Logger.error('Failed to publish ExecuteAsyncJob__e: ' + err.getMessage());
                }
            }
        } catch (Exception e) {
            Logger.error('Error publishing ExecuteAsyncJob__e: ' + e.getMessage(), e);
        }
    }

    private void assignName() {
        for (ExchangeRate__c er : listNew) {
            if (er.Name == null) {
                er.Name = er.BaseDate__c.toString().substring(0, 10) + '_' + er.Currency__c;
            }
        }
    }

    private void assignBizRegion() {
        for (ExchangeRate__c er : listNew) {
            if (er.BizRegion__c == null) {
                er.BizRegion__c = Util.getBizRegion();
            }
        }
    }

    private void fillHolidayAndWeekendRates(List<ExchangeRate__c> insertedRates) {
        Date minDate, maxDate;
        for (ExchangeRate__c rate : insertedRates) {
            if (rate.BaseDate__c == null)
                continue;
            if (minDate == null || rate.BaseDate__c < minDate)
                minDate = rate.BaseDate__c;
            if (maxDate == null || rate.BaseDate__c > maxDate)
                maxDate = rate.BaseDate__c;
        }
        if (minDate == null)
            return;

        Set<Date> holidays = ExchangeRateService.getHolidays(minDate, maxDate.addDays(ExchangeRateService.MAX_FILL_DAYS));

        Set<String> insertedCurrencies = new Set<String>();
        Set<Date> queryDates = new Set<Date>();
        Set<String> rateKeys = new Set<String>();

        for (ExchangeRate__c rate : insertedRates) {
            if (rate.BaseDate__c == null)
                continue;
            rateKeys.add(ExchangeRateService.getExchangeRateKey(rate));
            insertedCurrencies.add(rate.Currency__c);
            for (Integer i = 1; i <= ExchangeRateService.MAX_FILL_DAYS; i++) {
                queryDates.add(rate.BaseDate__c.addDays(i));
            }
        }

        Map<String, ExchangeRate__c> existingRatesMap = ExchangeRateService.getExistingRatesMap(
            new List<String>(insertedCurrencies),
            new List<Date>(queryDates)
        );

        List<ExchangeRate__c> fillRates = new List<ExchangeRate__c>();
        Set<String> processedInBatch = new Set<String>();

        for (ExchangeRate__c rate : insertedRates) {
            if (rate.BaseDate__c == null)
                continue;

            Date nextDay = rate.BaseDate__c.addDays(1);
            Integer safetyCounter = 0;

            while (
                (Util.isWeekend(nextDay) || holidays.contains(nextDay)) && safetyCounter < ExchangeRateService.MAX_FILL_DAYS
            ) {
                ExchangeRate__c fillRate = rate.clone(false, true);
                fillRate.BaseDate__c = nextDay;
                fillRate.Name = String.valueOf(nextDay).left(10) + '_' + rate.Currency__c;

                String fillKey = ExchangeRateService.getExchangeRateKey(fillRate);

                if (
                    !existingRatesMap.containsKey(fillKey) &&
                    !rateKeys.contains(fillKey) &&
                    !processedInBatch.contains(fillKey)
                ) {
                    fillRates.add(fillRate);
                    processedInBatch.add(fillKey);
                }

                nextDay = nextDay.addDays(1);
                safetyCounter++;
            }
        }

        if (!fillRates.isEmpty()) {
            isFilling = true;
            try {
                insert fillRates;
            } finally {
                isFilling = false;
            }
        }
    }

    private void checkDuplicate() {
        Map<String, ExchangeRate__c> mapExistingExchangeRate = ExchangeRateService.getExistingRatesMap(listNew);

        for (ExchangeRate__c rate : listNew) {
            if (
                rate.Status__c == ExchangeRateService.STATUS_ACTIVE &&
                mapExistingExchangeRate.containsKey(ExchangeRateService.getExchangeRateKey(rate))
            ) {
                rate.addError('Cannot Create duplicate record. Key :: ' + ExchangeRateService.getExchangeRateKey(rate));
            }
        }
    }
}