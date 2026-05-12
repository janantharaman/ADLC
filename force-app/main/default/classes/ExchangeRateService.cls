public without sharing class ExchangeRateService {
    public static final String STATUS_ACTIVE = 'Active';
    public static final Integer MAX_FILL_DAYS = 30;

    public static Map<String, ExchangeRate__c> getExistingRatesMap(List<ExchangeRate__c> listER) {
        Set<String> setCurrency = new Set<String>();
        Set<Date> setBaseDate = new Set<Date>();
        Set<String> setBizRegion = new Set<String>();

        for (ExchangeRate__c er : listER) {
            setCurrency.add(er.Currency__c);
            setBaseDate.add(er.BaseDate__c);
            setBizRegion.add(er.BizRegion__c);
        }

        return getExistingRatesMap(
            new List<String>(setBizRegion),
            new List<String>(setCurrency),
            new List<Date>(setBaseDate),
            listER
        );
    }
    public static Map<String, ExchangeRate__c> getExistingRatesMap(String bizRegion, String currencyCode, Date baseDate) {
        return getExistingRatesMap(
            new List<String>{ bizRegion },
            new List<String>{ currencyCode },
            new List<Date>{ baseDate },
            new List<ExchangeRate__c>()
        );
    }

    public static Map<String, ExchangeRate__c> getExistingRatesMap(List<String> listCurrency, List<Date> listBaseDate) {
        return getExistingRatesMap(
            new List<String>{ Util.getBizRegion() },
            listCurrency,
            listBaseDate,
            new List<ExchangeRate__c>()
        );
    }

    public static Map<String, ExchangeRate__c> getExistingRatesMap(
        List<String> listBizRegion,
        List<String> listCurrency,
        List<Date> listBaseDate,
        List<ExchangeRate__c> listER
    ) {
        Map<String, ExchangeRate__c> existingMap = new Map<String, ExchangeRate__c>();

        for (ExchangeRate__c er : [
            SELECT BizRegion__c, Currency__c, BaseDate__c, ExchangeRate__c
            FROM ExchangeRate__c
            WHERE
                Status__c = :STATUS_ACTIVE
                AND BizRegion__c IN :listBizRegion
                AND Currency__c IN :listCurrency
                AND BaseDate__c IN :listBaseDate
                AND Id NOT IN :listER
        ]) {
            existingMap.put(getExchangeRateKey(er), er);
        }

        return existingMap;
    }

    public static String getExchangeRateKey(ExchangeRate__c rate) {
        return getExchangeRateKey(rate.BizRegion__c, rate.Currency__c, rate.BaseDate__c);
    }

    public static String getExchangeRateKey(String bizRegion, String currencyCode, Date baseDate) {
        return bizRegion + '_' + currencyCode + '_' + baseDate;
    }

    public static Set<Date> getHolidays(Date minDate, Date maxDate) {
        Set<Date> holidays = new Set<Date>();
        for (HoliDay__c holiday : [
            SELECT Date__c
            FROM HoliDay__c
            WHERE
                BizRegion__c != NULL
                AND BizRegion__c = :Util.getBizRegion()
                AND Date__c >= :minDate
                AND Date__c <= :maxDate
        ]) {
            holidays.add(holiday.Date__c);
        }
        return holidays;
    }

    // --- Related Object Exchange Rate Update Logic --- //
    private static Map<Date, Boolean> mapPeriodCloseStatus;
    private static final String STATUS_CLOSED = 'Closed';

    public static void updateRelatedObjectExchangeRateFields(List<ExchangeRate__c> listExchangeRate) {
        Logger.info('updateRelatedObjectExchangeRateFields run');
        try {
            Logger.info('listExchangeRate :: ' + listExchangeRate);
            if (listExchangeRate == null || listExchangeRate.isEmpty()) {
                return;
            }

            List<ExchangeRate__c> listTargetForUpdate = getTargetForUpdate(listExchangeRate);
            Logger.info('listTargetForUpdate :: ' + listTargetForUpdate);

            if (listTargetForUpdate.isEmpty()) {
                return;
            }

            ExchangeRateContext ctx = new ExchangeRateContext(listTargetForUpdate);

            System.enqueueJob(new UpdateRelatedExchangeRateQueueable(ctx, 0));
        } catch (Exception e) {
            Logger.error(e.getMessage() + ' :: ' + e.getStackTraceString());
        } finally {
            Logger.saveLog();
        }
    }

    private static final Integer FX_CALCULATOR_TOTAL_STEPS = 4;

    private static FXCalculator createCalculator(
        Integer stepIndex,
        String bizRegion,
        String currencyCode,
        Set<Date> setDates
    ) {
        if (stepIndex == 0)
            return new InsurancePolicy_fx(bizRegion, currencyCode, setDates);
        if (stepIndex == 1)
            return new InsurancePolicyLineItem_fx(bizRegion, currencyCode, setDates);
        if (stepIndex == 2)
            return new PlacementLineItem_fx(bizRegion, currencyCode, setDates);
        if (stepIndex == 3)
            return new SettlementLineItem_fx(bizRegion, currencyCode, setDates);
        return null;
    }

    public static void executeRelatedObjectExchangeRateFields(ExchangeRateContext ctx, Integer stepIndex) {
        if (stepIndex >= FX_CALCULATOR_TOTAL_STEPS) {
            return;
        }

        for (String bizCurrKey : ctx.mapBizCurrencyToDates.keySet()) {
            String[] parts = bizCurrKey.split('\\|\\|');
            String bizRegion = parts[0];
            String currencyCode = parts[1];
            Set<Date> setDates = ctx.mapBizCurrencyToDates.get(bizCurrKey);

            FXCalculator calculator = createCalculator(stepIndex, bizRegion, currencyCode, setDates);
            calculator.run();
        }

        Integer nextStep = stepIndex + 1;
        if (nextStep < FX_CALCULATOR_TOTAL_STEPS) {
            if (Test.isRunningTest()) {
                // To avoid Queueable chaining limits in Tests (System.AsyncException: Maximum stack depth has been reached)
                executeRelatedObjectExchangeRateFields(ctx, nextStep);
            } else {
                System.enqueueJob(new UpdateRelatedExchangeRateQueueable(ctx, nextStep));
            }
        }
    }

    public static List<ExchangeRate__c> getTargetForUpdate(List<ExchangeRate__c> listExchangeRate) {
        Set<Date> setDate = new Set<Date>();

        Date minDate = Date.today();
        Date maxDate = Date.today();

        for (ExchangeRate__c er : listExchangeRate) {
            setDate.add(er.BaseDate__c);
            if (minDate == null || er.BaseDate__c < minDate) {
                minDate = er.BaseDate__c;
            }
            if (maxDate == null || er.BaseDate__c > maxDate) {
                maxDate = er.BaseDate__c;
            }
        }

        // 2. 기준일이 속한 Period Close의 Status = Closed 인경우 업데이트 하지 않는다.
        getMapPeriodCloseStatus(minDate, maxDate, setDate);

        List<ExchangeRate__c> listTargetExchangeRate = new List<ExchangeRate__c>();
        for (ExchangeRate__c er : listExchangeRate) {
            if (er.Status__c == STATUS_ACTIVE && isPeriodOpen(er.BaseDate__c)) {
                listTargetExchangeRate.add(er);
            }
        }

        return listTargetExchangeRate;
    }

    private static Map<Date, Boolean> getMapPeriodCloseStatus(Date minDate, Date maxDate, Set<Date> setDate) {
        if (mapPeriodCloseStatus != null) {
            return mapPeriodCloseStatus;
        }

        mapPeriodCloseStatus = new Map<Date, Boolean>();

        List<PeriodClose__c> listPeriodClose = [
            SELECT StartDate__c, EndDate__c, Status__c
            FROM PeriodClose__c
            WHERE StartDate__c <= :maxDate AND EndDate__c >= :minDate
        ];

        Logger.info('listPeriodClose >>' + listPeriodClose);

        for (Date dt : setDate) {
            for (PeriodClose__c pc : listPeriodClose) {
                if (dt >= pc.StartDate__c && dt <= pc.EndDate__c) {
                    mapPeriodCloseStatus.put(dt, pc.Status__c == STATUS_CLOSED ? false : true);
                    break;
                }
            }
        }

        return mapPeriodCloseStatus;
    }

    private static Boolean isPeriodOpen(Date kDate) {
        return mapPeriodCloseStatus.get(kDate) != null ? mapPeriodCloseStatus.get(kDate) : true;
    }

    public class ExchangeRateContext {
        public Set<String> setBizRegion = new Set<String>();
        public Set<Date> setBaseDate = new Set<Date>();
        public Set<String> setCurrency = new Set<String>();
        public Map<String, Decimal> mapKeyToRate = new Map<String, Decimal>();
        // key: bizRegion||currencyCode → 해당 조합의 날짜 집합
        public Map<String, Set<Date>> mapBizCurrencyToDates = new Map<String, Set<Date>>();

        public ExchangeRateContext(List<ExchangeRate__c> listTargetER) {
            for (ExchangeRate__c er : listTargetER) {
                setBizRegion.add(er.BizRegion__c);
                setBaseDate.add(er.BaseDate__c);
                setCurrency.add(er.Currency__c);
                mapKeyToRate.put(er.BizRegion__c + '_' + er.BaseDate__c + '_' + er.Currency__c, er.ExchangeRate__c);

                String bizCurrKey = er.BizRegion__c + '||' + er.Currency__c;
                if (!mapBizCurrencyToDates.containsKey(bizCurrKey)) {
                    mapBizCurrencyToDates.put(bizCurrKey, new Set<Date>());
                }
                mapBizCurrencyToDates.get(bizCurrKey).add(er.BaseDate__c);
            }
        }
    }

    /**
     * FX.rates()를 일괄 호출하여 rateCache를 구성합니다.
     * minDates/maxDates를 직접 구성하는 경우(SettlementLineItem 등)에도 단독으로 사용 가능합니다.
     */
    public static Map<String, Map<Date, Decimal>> buildRateCache(Map<String, Date> minDates, Map<String, Date> maxDates) {
        Map<String, Map<Date, Decimal>> rateCache = new Map<String, Map<Date, Decimal>>();
        for (String key : minDates.keySet()) {
            String[] parts = key.split('\\|\\|');
            String bizRegion = parts[0];
            String ccy = parts[1];
            try {
                rateCache.put(key, FX.rates(minDates.get(key), maxDates.get(key), bizRegion, ccy));
            } catch (Exception e) {
                Logger.error('Failed to load FX rates for ' + key + ': ' + e.getMessage(), e);
            }
        }
        return rateCache;
    }

    @AuraEnabled
    public static void recalculateExchangeRate(Id recordId) {
        String objectName = recordId.getSObjectType().getDescribe().getName();

        Integer calculatorStep = getCalculatorStepByObjectName(objectName);
        if (calculatorStep == null) {
            throw new AuraHandledException('Recalculation not supported for ' + objectName);
        }

        SObject record = queryRecordForRecalculation(objectName, recordId);
        String bizRegion = (String) record.get('BizRegion__c');

        if (bizRegion == null) {
            throw new AuraHandledException('BizRegion__c is empty for this record.');
        }

        Map<String, Set<Date>> mapCurrencyToDates = buildCurrencyToDatesForRecord(objectName, record);

        if (mapCurrencyToDates.isEmpty()) {
            throw new AuraHandledException('Could not find date/currency values to update.');
        }

        for (String currencyCode : mapCurrencyToDates.keySet()) {
            Set<Date> setDates = mapCurrencyToDates.get(currencyCode);
            FXCalculator calculator = createCalculator(calculatorStep, bizRegion, currencyCode, setDates);
            calculator.run();
        }
    }

    private static Integer getCalculatorStepByObjectName(String objectName) {
        if (objectName == 'InsurancePolicy')
            return 0;
        if (objectName == 'InsurancePolicyLineItem__c')
            return 1;
        if (objectName == 'PlacementLineItem__c')
            return 2;
        if (objectName == 'SettlementLineItem__c')
            return 3;
        return null;
    }

    private static SObject queryRecordForRecalculation(String objectName, Id recordId) {
        Set<String> setFields = new Set<String>{ 'Id', 'BizRegion__c' };

        if (objectName == 'SettlementLineItem__c') {
            setFields.addAll(
                new List<String>{
                    'OriginalFXRateDate__c',
                    'OriginCurrency__c',
                    'SettlementDate__c',
                    'SettlementCurrency__c',
                    'EvaluationDate__c'
                }
            );
        } else {
            setFields.addAll(new List<String>{ 'OriginalFXRateDate__c', 'Currency__c' });
        }

        String query =
            'SELECT ' +
            String.join(new List<String>(setFields), ', ') +
            ' FROM ' +
            objectName +
            ' WHERE Id = :recordId';
        List<SObject> records = Database.query(query);

        if (records.isEmpty()) {
            throw new AuraHandledException('Record not found.');
        }
        return records[0];
    }

    private static Map<String, Set<Date>> buildCurrencyToDatesForRecord(String objectName, SObject record) {
        Map<String, Set<Date>> mapCurrencyToDates = new Map<String, Set<Date>>();

        if (objectName == 'SettlementLineItem__c') {
            addCurrencyDate(
                mapCurrencyToDates,
                (String) record.get('OriginCurrency__c'),
                (Date) record.get('OriginalFXRateDate__c')
            );
            addCurrencyDate(
                mapCurrencyToDates,
                (String) record.get('SettlementCurrency__c'),
                (Date) record.get('SettlementDate__c')
            );
            addCurrencyDate(
                mapCurrencyToDates,
                (String) record.get('OriginCurrency__c'),
                (Date) record.get('EvaluationDate__c')
            );
        } else {
            addCurrencyDate(
                mapCurrencyToDates,
                (String) record.get('Currency__c'),
                (Date) record.get('OriginalFXRateDate__c')
            );
        }

        return mapCurrencyToDates;
    }

    private static void addCurrencyDate(Map<String, Set<Date>> mapCurrencyToDates, String currencyCode, Date d) {
        if (currencyCode == null || d == null) {
            return;
        }
        if (!mapCurrencyToDates.containsKey(currencyCode)) {
            mapCurrencyToDates.put(currencyCode, new Set<Date>());
        }
        mapCurrencyToDates.get(currencyCode).add(d);
    }

    public static void recalculateExchangeRateByPeriods(List<PeriodClose__c> periods) {
        Logger.info('recalculateExchangeRateByPeriods run');
        if (periods == null || periods.isEmpty()) {
            return;
        }

        Date minDate = null;
        Date maxDate = null;

        for (PeriodClose__c pc : periods) {
            if (minDate == null || pc.StartDate__c < minDate) {
                minDate = pc.StartDate__c;
            }
            if (maxDate == null || pc.EndDate__c > maxDate) {
                maxDate = pc.EndDate__c;
            }
        }

        List<ExchangeRate__c> listER = [
            SELECT BizRegion__c, BaseDate__c, Currency__c, ExchangeRate__c
            FROM ExchangeRate__c
            WHERE Status__c = :STATUS_ACTIVE AND BaseDate__c >= :minDate AND BaseDate__c <= :maxDate
        ];

        List<ExchangeRate__c> targetERs = new List<ExchangeRate__c>();
        for (ExchangeRate__c er : listER) {
            for (PeriodClose__c pc : periods) {
                if (er.BaseDate__c >= pc.StartDate__c && er.BaseDate__c <= pc.EndDate__c) {
                    targetERs.add(er);
                    break;
                }
            }
        }

        if (targetERs.isEmpty()) {
            Logger.info('No active ExchangeRate records found to recalculate for closed periods.');
            return;
        }

        ExchangeRateContext ctx = new ExchangeRateContext(targetERs);
        Logger.info('ExchangeRateContext: ' + ctx);
        System.enqueueJob(new UpdateRelatedExchangeRateQueueable(ctx, 0));
    }

    @AuraEnabled
    public static void recalculateExchangeRateByPeriod(Id periodCloseId) {
        Logger.info('recalculateExchangeRateByPeriod run');
        Logger.info('periodCloseId :: ' + periodCloseId);
        List<PeriodClose__c> periods = [
            SELECT StartDate__c, EndDate__c, Status__c
            FROM PeriodClose__c
            WHERE Id = :periodCloseId
        ];
        if (periods.isEmpty()) {
            throw new AuraHandledException('Period Close record not found.');
        }

        PeriodClose__c pc = periods[0];
        if (pc.Status__c == STATUS_CLOSED) {
            throw new AuraHandledException('Cannot recalculate exchange rates for a closed period.');
        }

        List<ExchangeRate__c> listER = [
            SELECT BizRegion__c, BaseDate__c, Currency__c, ExchangeRate__c
            FROM ExchangeRate__c
            WHERE Status__c = :STATUS_ACTIVE AND BaseDate__c >= :pc.StartDate__c AND BaseDate__c <= :pc.EndDate__c
        ];

        if (listER.isEmpty()) {
            throw new AuraHandledException('No active ExchangeRate records found in this period.');
        }

        ExchangeRateContext ctx = new ExchangeRateContext(listER);
        Logger.info('ExchangeRateContext: ' + ctx);
        System.enqueueJob(new UpdateRelatedExchangeRateQueueable(ctx, 0));
    }

    public interface FXCalculator {
        void run();
    }
}