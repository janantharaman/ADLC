@IsTest
private class FX_ts {
    private static final String REGION_KR = 'KR';
    private static final String REGION_RE = 'SG'; // User.Region__c value that maps to LK_Re
    private static final String REGION_VN = 'VN';
    private static final String BIZ_REGION_KR = 'LK_KR';
    private static final String BIZ_REGION_RE = 'LK_Re'; // 재보험사 법인 (기준통화: USD)
    private static final String BIZ_REGION_VN = 'LK_VN';
    private static final Date TEST_DATE = Date.newInstance(2026, 2, 2); // 월요일

    /**
     * 테스트 환경 초기화 (기본: KR 지역)
     */
    private static void setupTestEnvironment() {
        setupTestEnvironment(REGION_KR);
    }

    /**
     * 테스트 환경 초기화 (지정된 지역)
     */
    private static void setupTestEnvironment(String region) {
        User testUser = new User(Id = UserInfo.getUserId(), Region__c = region);
        update testUser;
        UserService.resetUserRegion();
        Util.resetForTest();
    }

    @TestSetup
    static void setupTestData() {
        // 환율 데이터 생성
        List<ExchangeRate__c> rates = new List<ExchangeRate__c>();

        // USD -> KRW (KR 법인, 기준통화: KRW)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'USD',
                BizRegion__c = BIZ_REGION_KR,
                ExchangeRate__c = 1450.00,
                BaseDate__c = TEST_DATE,
                Status__c = 'Active'
            )
        );

        // EUR -> KRW (KR 법인)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'EUR',
                BizRegion__c = BIZ_REGION_KR,
                ExchangeRate__c = 1580.00,
                BaseDate__c = TEST_DATE,
                Status__c = 'Active'
            )
        );

        // JPY -> KRW (KR 법인)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'JPY',
                BizRegion__c = BIZ_REGION_KR,
                ExchangeRate__c = 9.50,
                BaseDate__c = TEST_DATE,
                Status__c = 'Active'
            )
        );

        // KRW -> USD (RE 재보험사 법인, 기준통화: USD)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'KRW',
                BizRegion__c = BIZ_REGION_RE,
                ExchangeRate__c = 0.00069,
                BaseDate__c = TEST_DATE,
                Status__c = 'Active'
            )
        );

        // VND -> USD (RE 재보험사 법인)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'VND',
                BizRegion__c = BIZ_REGION_RE,
                ExchangeRate__c = 0.000039,
                BaseDate__c = TEST_DATE,
                Status__c = 'Active'
            )
        );

        // USD -> VND (VN 법인, 기준통화: VND)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'USD',
                BizRegion__c = BIZ_REGION_VN,
                ExchangeRate__c = 25400.00,
                BaseDate__c = TEST_DATE,
                Status__c = 'Active'
            )
        );

        // 주말 전 금요일 환율 (2026-01-30)
        rates.add(
            new ExchangeRate__c(
                Currency__c = 'USD',
                BizRegion__c = BIZ_REGION_KR,
                ExchangeRate__c = 1440.00,
                BaseDate__c = Date.newInstance(2026, 1, 30),
                Status__c = 'Active'
            )
        );

        insert rates;

        // 공휴일 데이터 생성
        List<Holiday__c> holidays = new List<Holiday__c>();
        holidays.add(new Holiday__c(BizRegion__c = BIZ_REGION_KR, Date__c = Date.newInstance(2026, 2, 3)));
        insert holidays;
    }

    @IsTest
    static void testRateWithRegionAndCurrency() {
        setupTestEnvironment();

        // KR 법인 환율 조회 (기준통화: KRW)
        Decimal rate = FX.rate(TEST_DATE, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1450.00, rate, 'USD to KRW rate for KR region');

        Decimal eurRate = FX.rate(TEST_DATE, BIZ_REGION_KR, 'EUR');
        Assert.areEqual(1580.00, eurRate, 'EUR to KRW rate for KR region');

        Decimal jpyRate = FX.rate(TEST_DATE, BIZ_REGION_KR, 'JPY');
        Assert.areEqual(9.50, jpyRate, 'JPY to KRW rate for KR region');

        // RE 재보험사 법인 환율 조회 (기준통화: USD)
        Decimal reKrwRate = FX.rate(TEST_DATE, BIZ_REGION_RE, 'KRW');
        Assert.areEqual(0.00069, reKrwRate, 'KRW to USD rate for RE region');

        // VN 법인 환율 조회 (기준통화: VND)
        Decimal vnRate = FX.rate(TEST_DATE, BIZ_REGION_VN, 'USD');
        Assert.areEqual(25400.00, vnRate, 'USD to VND rate for VN region');
    }

    @IsTest
    static void testRateWithCurrentUserRegion() {
        // User의 Region__c를 직접 설정
        setupTestEnvironment(REGION_KR);

        // 현재 유저의 Region (KR) 사용
        Decimal rate = FX.rate(TEST_DATE, 'USD');
        Assert.areEqual(1450.00, rate, 'USD rate using current user region (KR)');
    }

    @IsTest
    static void testSameCurrencyReturnsOne() {
        setupTestEnvironment();

        // 동일 통화는 환율 1 반환
        Decimal krRate = FX.rate(TEST_DATE, BIZ_REGION_KR, 'KRW');
        Assert.areEqual(1, krRate, 'KRW to KRW should return 1 for KR region');

        Decimal reRate = FX.rate(TEST_DATE, BIZ_REGION_RE, 'USD');
        Assert.areEqual(1, reRate, 'USD to USD should return 1 for RE region');

        Decimal vnRate = FX.rate(TEST_DATE, BIZ_REGION_VN, 'VND');
        Assert.areEqual(1, vnRate, 'VND to VND should return 1 for VN region');
    }

    @IsTest
    static void testWeekendFallback() {
        setupTestEnvironment();

        // 2026-01-31 (토요일) -> 2026-01-30 (금요일)로 조정
        Date saturday = Date.newInstance(2026, 1, 31);
        Decimal rate = FX.rate(saturday, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1440.00, rate, 'Weekend should fallback to Friday rate');

        // 2026-02-01 (일요일) -> 2026-01-30 (금요일)로 조정
        Date sunday = Date.newInstance(2026, 2, 1);
        Decimal sundayRate = FX.rate(sunday, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1440.00, sundayRate, 'Sunday should fallback to Friday rate');
    }

    @IsTest
    static void testHolidayFallback() {
        setupTestEnvironment();

        // 2026-02-03 (화요일, 공휴일) -> 2026-02-02 (월요일)로 조정
        Date holiday = Date.newInstance(2026, 2, 3);
        Decimal rate = FX.rate(holiday, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1450.00, rate, 'Holiday should fallback to previous business day');
    }

    @IsTest
    static void testIsWeekend() {
        // 2026-01-31 (토요일)
        Assert.isTrue(Util.isWeekend(Date.newInstance(2026, 1, 31)), 'Saturday should be weekend');

        // 2026-02-01 (일요일)
        Assert.isTrue(Util.isWeekend(Date.newInstance(2026, 2, 1)), 'Sunday should be weekend');

        // 2026-02-02 (월요일)
        Assert.isFalse(Util.isWeekend(Date.newInstance(2026, 2, 2)), 'Monday should not be weekend');

        // 2026-02-06 (금요일)
        Assert.isFalse(Util.isWeekend(Date.newInstance(2026, 2, 6)), 'Friday should not be weekend');
    }

    @IsTest
    static void testGetDayOfWeek() {
        // 2026-02-01 (일요일) = 0
        Assert.areEqual(0, Util.getDayOfWeek(Date.newInstance(2026, 2, 1)), 'Sunday should be 0');

        // 2026-02-02 (월요일) = 1
        Assert.areEqual(1, Util.getDayOfWeek(Date.newInstance(2026, 2, 2)), 'Monday should be 1');

        // 2026-02-03 (화요일) = 2
        Assert.areEqual(2, Util.getDayOfWeek(Date.newInstance(2026, 2, 3)), 'Tuesday should be 2');

        // 2026-02-04 (수요일) = 3
        Assert.areEqual(3, Util.getDayOfWeek(Date.newInstance(2026, 2, 4)), 'Wednesday should be 3');

        // 2026-02-05 (목요일) = 4
        Assert.areEqual(4, Util.getDayOfWeek(Date.newInstance(2026, 2, 5)), 'Thursday should be 4');

        // 2026-02-06 (금요일) = 5
        Assert.areEqual(5, Util.getDayOfWeek(Date.newInstance(2026, 2, 6)), 'Friday should be 5');

        // 2026-01-31 (토요일) = 6
        Assert.areEqual(6, Util.getDayOfWeek(Date.newInstance(2026, 1, 31)), 'Saturday should be 6');
    }

    @IsTest
    static void testFXLoaderInvalidKey() {
        FX.FXLoader loader = new FX.FXLoader();

        // 잘못된 키 형식
        try {
            loader.load('INVALID');
            Assert.fail('Should throw FXException for invalid key');
        } catch (FX.FXException e) {
            Assert.isTrue(e.getMessage().contains('Invalid cache key'), 'Should contain error message');
        }

        try {
            loader.load('2026-02-02::LK_KR');
            Assert.fail('Should throw FXException for missing currency');
        } catch (FX.FXException e) {
            Assert.isTrue(e.getMessage().contains('Invalid cache key'), 'Should contain error message');
        }
    }

    @IsTest
    static void testFXLoaderValidKey() {
        setupTestEnvironment();
        FX.FXLoader loader = new FX.FXLoader();

        String key = FX.cacheKey(TEST_DATE, BIZ_REGION_KR, 'USD');
        Object result = loader.load(key);

        Assert.isNotNull(result, 'Should return rate for valid key');
        Assert.areEqual(1450.00, (Decimal) result, 'Should return correct rate');
    }

    @IsTest
    static void testFXLoaderNotFoundReturnsNull() {
        setupTestEnvironment();
        FX.FXLoader loader = new FX.FXLoader();

        // 존재하지 않는 환율 - loader는 null 반환
        String key = FX.cacheKey(TEST_DATE, BIZ_REGION_KR, 'GBP');
        Object result = loader.load(key);

        Assert.isNull(result, 'Should return null for non-existent rate');
    }

    @IsTest
    static void testCaching() {
        setupTestEnvironment();

        // 첫 번째 호출 - 캐시 미스
        Decimal rate1 = FX.rate(TEST_DATE, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1450.00, rate1, 'First USD rate');

        // 두 번째 호출 - 캐시 히트
        Decimal rate2 = FX.rate(TEST_DATE, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1450.00, rate2, 'Second USD rate (cached)');

        Assert.areEqual(rate1, rate2, 'Cached rate should match');
    }

    @IsTest
    static void testRateNotFound() {
        setupTestEnvironment();

        // 존재하지 않는 환율 - COM_Cache가 NULL_VALUE로 처리하여 null 반환
        Decimal rate = FX.rate(TEST_DATE, BIZ_REGION_KR, 'GBP');
        Assert.isNull(rate, 'Should return null for non-existent rate');
    }

    @IsTest
    static void testUserRegionNotSet() {
        // currentUserRegion을 null로 설정하여 예외 발생 테스트
        COM_Cache.clear();

        // User의 Region__c가 null이면 Region 추적 실패하여 Region Currency 예외 발생
        setupTestEnvironment(null);

        try {
            FX.rate(TEST_DATE, 'USD');
            Assert.fail('Should throw FXException when user region is not set');
        } catch (FX.FXException e) {
            Assert.isTrue(e.getMessage().contains('Region Currency not found'), 'Should contain error message');
        }
    }

    @IsTest
    static void testDifferentRegions() {
        setupTestEnvironment();

        // KR 법인 - KRW 기준
        Decimal krRate = FX.rate(TEST_DATE, BIZ_REGION_KR, 'USD');
        Assert.areEqual(1450.00, krRate, 'USD to KRW for KR region');

        // RE 재보험사 법인 - USD 기준
        Decimal reKrwRate = FX.rate(TEST_DATE, BIZ_REGION_RE, 'KRW');
        Assert.areEqual(0.00069, reKrwRate, 'KRW to USD for RE region');

        Decimal reVndRate = FX.rate(TEST_DATE, BIZ_REGION_RE, 'VND');
        Assert.areEqual(0.000039, reVndRate, 'VND to USD for RE region');

        // VN 법인 - VND 기준
        Decimal vnRate = FX.rate(TEST_DATE, BIZ_REGION_VN, 'USD');
        Assert.areEqual(25400.00, vnRate, 'USD to VND for VN region');
    }

    @IsTest
    static void testCurrentUserRegionChange() {
        // RE 지역으로 설정 (기준통화: USD)
        setupTestEnvironment(REGION_RE);

        // USD 기준통화이므로 KRW 환율 조회
        Decimal reRate = FX.rate(TEST_DATE, 'KRW');
        Assert.areEqual(0.00069, reRate, 'KRW rate for RE region user');

        // VN 지역으로 변경 (기준통화: VND)
        setupTestEnvironment(REGION_VN);

        Decimal vnRate = FX.rate(TEST_DATE, 'USD');
        Assert.areEqual(25400.00, vnRate, 'USD rate for VN region user');
    }

    @IsTest
    static void testRatesDateRangeSameCurrency() {
        setupTestEnvironment();

        // KRW -> KRW (동일 통화): fromCode == toCode 경로 테스트
        Date fromDate = TEST_DATE; // 2026-02-02 (월)
        Date toDate = TEST_DATE.addDays(2); // 2026-02-04 (수)

        Map<Date, Decimal> result = FX.rates(fromDate, toDate, BIZ_REGION_KR, 'KRW');

        Assert.areEqual(3, result.size(), 'Should return rate for each date in range');
        for (Date dt = fromDate; dt <= toDate; dt = dt.addDays(1)) {
            Assert.areEqual(1.0, result.get(dt), 'Same currency rate should be 1.0 for ' + dt);
        }
    }

    @IsTest
    static void testRatesDateRangeWithWeekendAndHoliday() {
        setupTestEnvironment();

        // 2026-01-30(금) ~ 2026-02-03(화, 공휴일) 범위 조회
        // 기대값:
        //   01-30 (금, 영업일) → 1440.00
        //   01-31 (토, 주말)   → 1440.00 (금요일 fallback)
        //   02-01 (일, 주말)   → 1440.00 (금요일 fallback)
        //   02-02 (월, 영업일) → 1450.00
        //   02-03 (화, 공휴일) → 1450.00 (월요일 fallback)
        Date fromDate = Date.newInstance(2026, 1, 30);
        Date toDate = Date.newInstance(2026, 2, 3);

        Map<Date, Decimal> result = FX.rates(fromDate, toDate, BIZ_REGION_KR, 'USD');

        Assert.areEqual(5, result.size(), 'Should return rate for each date in range');
        Assert.areEqual(1440.00, result.get(Date.newInstance(2026, 1, 30)), 'Friday rate');
        Assert.areEqual(1440.00, result.get(Date.newInstance(2026, 1, 31)), 'Saturday should fallback to Friday');
        Assert.areEqual(1440.00, result.get(Date.newInstance(2026, 2, 1)), 'Sunday should fallback to Friday');
        Assert.areEqual(1450.00, result.get(Date.newInstance(2026, 2, 2)), 'Monday rate');
        Assert.areEqual(1450.00, result.get(Date.newInstance(2026, 2, 3)), 'Holiday should fallback to Monday');
    }

    @IsTest
    static void testRatesSingleDate() {
        setupTestEnvironment();

        // 단일 날짜 범위
        Map<Date, Decimal> result = FX.rates(TEST_DATE, TEST_DATE, BIZ_REGION_KR, 'USD');

        Assert.areEqual(1, result.size(), 'Should return exactly one entry');
        Assert.areEqual(1450.00, result.get(TEST_DATE), 'Single date rate should match');
    }

    @IsTest
    static void testRatesNotFoundReturnsNull() {
        setupTestEnvironment();

        // 존재하지 않는 통화 - null 반환
        Map<Date, Decimal> result = FX.rates(TEST_DATE, TEST_DATE, BIZ_REGION_KR, 'GBP');

        Assert.areEqual(1, result.size(), 'Should return entry even for missing rate');
        Assert.isNull(result.get(TEST_DATE), 'Missing rate should be null');
    }
}