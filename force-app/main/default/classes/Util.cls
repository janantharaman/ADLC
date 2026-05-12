public without sharing class Util {
    private static final String BIZ_REGION = 'BizRegion';
    private static final String REGION_CURRENCY = 'RegionCurrency';

    @TestVisible
    private static String userBizRegion;
    @TestVisible
    private static String userRegionCurrency;

    @AuraEnabled
    public static String getBizRegion() {
        if (userBizRegion == null) {
            userBizRegion = MappingTable.getMappingValue(BIZ_REGION, UserService.getUserRegion());
        }
        return userBizRegion;
    }

    public static String getBizRegion(String region) {
        return MappingTable.getMappingValue(BIZ_REGION, region);
    }

    public static String getRegionCurrency() {
        if (userRegionCurrency == null) {
            userRegionCurrency = MappingTable.getMappingValue(REGION_CURRENCY, UserService.getUserRegion());
        }
        return userRegionCurrency;
    }

    public static String getRegionCurrency(String region) {
        return MappingTable.getMappingValue(REGION_CURRENCY, region);
    }

    /**
     * Returns the day of the week for the given date.
     * @param dt
     * @return   `Integer`
     */
    public static Integer getDayOfWeek(Date dt) {
        // 0: 일요일, 1: 월요일, ..., 6: 토요일
        return Math.mod((Integer) Date.newInstance(1900, 1, 7).daysBetween(dt), 7);
    }

    public static Boolean isWeekend(Date targetDate) {
        Integer dayNum = getDayOfWeek(targetDate);
        return (dayNum == 0 || dayNum == 6); // 0=Sun, 6=Sat based on BASE_DATE(2025-01-05 Sun)
    }

    @TestVisible
    private static void resetForTest() {
        userBizRegion = null;
        userRegionCurrency = null;
    }
}