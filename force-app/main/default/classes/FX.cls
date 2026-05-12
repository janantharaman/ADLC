/**
 * Foreign Exchange Rate utility class.
 *
 * Usage:
 *   FX.rate(Date.today(), 'KR', 'USD')  // → 1452.20 (1 USD = 1452.20 KRW)
 *   FX.rate(Date.today(), 'USD') // → Current user's region is used
 */
public with sharing class FX {
    private static final String CACHE_KEY_DELIMITER = '::';

    /**********************************************************************
     * Public Methods
     **********************************************************************/

    /**
     * Get exchange rate for the given date, region, and currency.
     *
     * @param targetDate
     * @param region
     * @param ccyCode
     * @return           `Decimal`
     */
    public static Decimal rate(Date targetDate, String bizRegion, String ccyCode) {
        String fromCode = ccyCode.toUpperCase();

        String toCode = Util.getRegionCurrency(bizRegion);

        if (String.isBlank(toCode)) {
            throw new FXException('Region Currency not found for biz region: ' + bizRegion);
        }

        if (fromCode == toCode) {
            return 1;
        }

        String cacheKey = cacheKey(targetDate, bizRegion, fromCode);
        COM_Cache cache = COM_Cache.of(FXLoader.class);

        return (Decimal) cache.lookup(cacheKey);
    }

    public static Decimal rate(Date targetDate, String ccyCode) {
        return rate(targetDate, Util.getBizRegion(), ccyCode);
    }

    /**
     * Get exchange rates for the given date range, region, and currency.
     *
     * @param fromDate
     * @param toDate
     * @param region
     * @param ccyCode
     * @return         `Map<Date, Decimal>`
     */
    public static Map<Date, Decimal> rates(Date fromDate, Date toDate, String bizRegion, String ccyCode) {
        return new FXLoader().rates(fromDate, toDate, bizRegion, ccyCode);
    }

    /**********************************************************************
     * FXLoader
     **********************************************************************/
    private static final Integer BUFFER_SIZE = 20;

    public without sharing class FXLoader implements COM_Cache.Loader {
        public Object load(String key) {
            // key format: YYYY-MM-DD_REGION_CCYCODE
            List<String> parts = key.split(CACHE_KEY_DELIMITER);

            if (parts.size() != 3) {
                throw new FXException('Invalid cache key: ' + key);
            }

            // 대상일자
            Date targetDate = Date.valueOf(parts[0]);
            // 법인
            String bizRegion = parts[1];
            // 통화코드
            String ccyCode = parts[2];

            return rates(targetDate, targetDate, bizRegion, ccyCode).get(targetDate);
        }

        public Map<Date, Decimal> rates(Date fromDate, Date toDate, String bizRegion, String ccyCode) {
            String fromCode = ccyCode.toUpperCase();
            String toCode = Util.getRegionCurrency(bizRegion);

            // 동일 통화일 경우 즉시 1.0 반환
            if (fromCode == toCode) {
                Map<Date, Decimal> resultMap = new Map<Date, Decimal>();
                Map<String, Object> cacheDataSource = new Map<String, Object>();
                for (Date dt = fromDate; dt <= toDate; dt = dt.addDays(1)) {
                    resultMap.put(dt, 1.0);
                    cacheDataSource.put(cacheKey(dt, bizRegion, ccyCode), (Object) 1.0);
                }
                COM_Cache.register(cacheDataSource);
                return resultMap;
            }

            // Buffer 20일
            Date bufferFromDate = fromDate.addDays(-BUFFER_SIZE);

            // 공휴일 조회
            Set<Date> publicHolidaySet = new Set<Date>();
            for (Holiday__c holiday : [
                SELECT Date__c
                FROM Holiday__c
                WHERE BizRegion__c = :bizRegion AND Date__c >= :bufferFromDate AND Date__c <= :toDate
                WITH SYSTEM_MODE
            ]) {
                publicHolidaySet.add(holiday.Date__c);
            }

            // Working Day 계산
            Set<Date> workingDays = new Set<Date>();
            for (Integer i = 0; i <= bufferFromDate.daysBetween(toDate); i++) {
                Date dt = bufferFromDate.addDays(i);

                if (!publicHolidaySet.contains(dt) && !Util.isWeekend(dt)) {
                    workingDays.add(dt);
                }
            }

            // 환율 조회
            Map<Date, Decimal> rateMap = new Map<Date, Decimal>();
            for (ExchangeRate__c exRate : [
                SELECT ExchangeRate__c, BaseDate__c
                FROM ExchangeRate__c
                WHERE
                    Currency__c = :ccyCode
                    AND BizRegion__c = :bizRegion
                    AND BaseDate__c IN :workingDays
                    AND Status__c = 'Active'
                WITH SYSTEM_MODE
            ]) {
                rateMap.put(exRate.BaseDate__c, exRate.ExchangeRate__c);
            }

            // 전체 환율 맵 작성
            Map<Date, Decimal> resultMap = new Map<Date, Decimal>();
            Map<String, Object> cacheDataSource = new Map<String, Object>();
            for (Date dt = fromDate; dt <= toDate; dt = dt.addDays(1)) {
                Date lookupDate = dt;

                // 영업일이 아닌 경우, 가장 가까운 이전 영업일로 조정
                while (!workingDays.contains(lookupDate)) {
                    lookupDate = lookupDate.addDays(-1);
                }

                resultMap.put(dt, rateMap.get(lookupDate));
                cacheDataSource.put(
                    cacheKey(dt, bizRegion, ccyCode),
                    (Object) resultMap.get(dt) ?? (Object) COM_Cache.NULL_VALUE
                );
            }

            COM_Cache.register(cacheDataSource);

            return resultMap;
        }
    }

    /**
     * @param targetDate
     * @param bizRegion
     * @param ccyCode
     * @return           `String`
     */
    public static String cacheKey(Date targetDate, String bizRegion, String ccyCode) {
        return String.join(
            new List<String>{ String.valueOf(targetDate), bizRegion, ccyCode.toUpperCase() },
            CACHE_KEY_DELIMITER
        );
    }

    /**********************************************************************
     * FXException
     **********************************************************************/
    public class FXException extends Exception {
    }
}