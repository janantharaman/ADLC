/**********************************************************************************
 * @filename      : ACC_NaverNewsFetch_ts.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @target-class  : .cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
@IsTest
private class ACC_NaverNewsFetch_ts {

    // =========================================================================
    // Mock: 네이버 API 응답
    // =========================================================================
    private class NaverNewsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{'
                    + '"lastBuildDate": "Sun, 08 Mar 2026 10:00:00 +0900",'
                    + '"total": 1,'
                    + '"start": 1,'
                    + '"display": 1,'
                    + '"items": [{'
                    + '"title": "<b>테스트</b> 뉴스 제목",'
                    + '"originallink": "https://example.com/news/1",'
                    + '"link": "https://search.naver.com/news/1",'
                    + '"description": "<b>테스트</b> 뉴스 요약입니다.",'
                    + '"pubDate": "' + Datetime.now().format('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US') + '"'
                    + '}]'
                    + '}');
            return res;
        }
    }

    // =========================================================================
    // Mock: API 실패
    // =========================================================================
    private class NaverNewsErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    // =========================================================================
    // 테스트 데이터 생성
    // =========================================================================
    @TestSetup
    static void setupData() {
        Account acc = (Account) COM_TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Name' => 'LK보험',
                'CompanyNameKor__c' => 'LK보험'
        }, true);
    }

    // =========================================================================
    // Service: API 호출 + 파싱
    // =========================================================================
    @IsTest
    static void testFetchNews() {
        Test.setMock(HttpCalloutMock.class, new NaverNewsMock());

        Test.startTest();
        List<ACC_NaverNewsFetch_sv.NewsItem> items = ACC_NaverNewsFetch_sv.fetchNews('LK보험', 10);
        Test.stopTest();

        System.assertEquals(1, items.size(), '뉴스 1건 반환');
        System.assertEquals('테스트 뉴스 제목', items[0].title, 'HTML 태그 제거 확인');
        System.assert(items[0].titleOriginal.contains('<b>'), '원본 HTML 포함 확인');
        System.assertNotEquals(null, items[0].pubDate, '날짜 파싱 확인');
    }

    // =========================================================================
    // Service: toSObject 변환
    // =========================================================================
    @IsTest
    static void testToSObject() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        ACC_NaverNewsFetch_sv.NewsItem item = new ACC_NaverNewsFetch_sv.NewsItem();
        item.title = '테스트 제목';
        item.titleOriginal = '<b>테스트</b> 제목';
        item.description = '테스트 요약';
        item.descriptionOriginal = '<b>테스트</b> 요약';
        item.link = 'https://search.naver.com/news/1';
        item.originalLink = 'https://example.com/news/1';
        item.pubDate = Datetime.now();

        ACC_News__c news = ACC_NaverNewsFetch_sv.toSObject(item, acc.Id);

        System.assertEquals(acc.Id, news.Account_lk__c);
        System.assertNotEquals(null, news.NewsKey__c, 'NewsKey 생성 확인');
    }

    // =========================================================================
    // Service: NewsKey 동일 입력 → 동일 해시
    // =========================================================================
    @IsTest
    static void testGenerateNewsKey() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String key1 = ACC_NaverNewsFetch_sv.generateNewsKey(acc.Id, 'https://example.com/1');
        String key2 = ACC_NaverNewsFetch_sv.generateNewsKey(acc.Id, 'https://example.com/1');
        String key3 = ACC_NaverNewsFetch_sv.generateNewsKey(acc.Id, 'https://example.com/2');

        System.assertEquals(key1, key2, '동일 입력 → 동일 키');
        System.assertNotEquals(key1, key3, '다른 입력 → 다른 키');
    }

    // =========================================================================
    // Batch: 정상 실행
    // =========================================================================
    @IsTest
    static void testBatch() {
        Test.setMock(HttpCalloutMock.class, new NaverNewsMock());

        Test.startTest();
        Database.executeBatch(new ACC_NaverNewsFetch_ba(), 5);
        Test.stopTest();

        Account acc = [SELECT Id, CompanyNameKor__c FROM Account LIMIT 1];
        System.debug('🤖 acc=['+ acc +']');

        List<ACC_News__c> newsList = [SELECT Id, Title__c, Account_lk__c FROM ACC_News__c];
        System.debug('🤖 newsList=['+ newsList +']');
        System.assert(!newsList.isEmpty(), '뉴스 레코드 생성 확인');
    }

    // =========================================================================
    // Batch: API 실패 시 에러 처리
    // =========================================================================
    @IsTest
    static void testBatchWithApiError() {
        Test.setMock(HttpCalloutMock.class, new NaverNewsErrorMock());

        Test.startTest();
        Database.executeBatch(new ACC_NaverNewsFetch_ba(), 5);
        Test.stopTest();

        List<ACC_News__c> newsList = [SELECT Id FROM ACC_News__c];
        System.assertEquals(0, newsList.size(), 'API 실패 시 뉴스 미생성');
    }

    // =========================================================================
    // Scheduler: 등록 + 삭제
    // =========================================================================
    @IsTest
    static void testScheduler() {
        Test.startTest();
        String jobId = ACC_NaverNewsFetch_sc.scheduleJob('0 0 7 * * ?');
        Test.stopTest();

        System.assertNotEquals(null, jobId, '스케줄 등록 확인');

        ACC_NaverNewsFetch_sc.abortJob();
        List<CronTrigger> jobs = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = 'ACC_NaverNewsFetch_Daily'
        ];
        System.assertEquals(0, jobs.size(), '스케줄 삭제 확인');
    }

    // =========================================================================
    // Scheduler: 즉시 실행
    // =========================================================================
    @IsTest
    static void testRunNow() {
        Test.setMock(HttpCalloutMock.class, new NaverNewsMock());

        Test.startTest();
        Id batchId = ACC_NaverNewsFetch_sc.runNow();
        Test.stopTest();

        System.assertNotEquals(null, batchId, '배치 실행 ID 반환 확인');
    }


}