/**********************************************************************************
 * @filename      : ACC_NaverNewsDelete_ts.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : .cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
@IsTest
private class ACC_NaverNewsDelete_ts {

    // =========================================================================
    // 테스트 데이터 생성
    // =========================================================================
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'LK보험');
        insert acc;
    }

    // =========================================================================
    // Cleaner Batch: 보관기간 만료 뉴스 삭제
    // =========================================================================
    @IsTest
    static void testCleanerBatch() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // 보관기간 초과 뉴스 생성 (91일 전)
        ACC_News__c oldNews = new ACC_News__c(
                Account_lk__c = acc.Id,
                Title__c = '오래된 뉴스',
                PubDate__c = Datetime.now().addDays(-91),
                NewsKey__c = 'OLD_NEWS_KEY_001'
        );
        // 보관기간 이내 뉴스 생성 (1일 전)
        ACC_News__c recentNews = new ACC_News__c(
                Account_lk__c = acc.Id,
                Title__c = '최근 뉴스',
                PubDate__c = Datetime.now().addDays(-1),
                NewsKey__c = 'RECENT_NEWS_KEY_001'
        );
        insert new List<ACC_News__c>{ oldNews, recentNews };

        Test.startTest();
        Database.executeBatch(new ACC_NaverNewsDelete_ba(), 200);
        Test.stopTest();

        List<ACC_News__c> remaining = [SELECT Id, Title__c FROM ACC_News__c];
        System.assertEquals(1, remaining.size(), '만료 뉴스 삭제, 최근 뉴스 유지');
        System.assertEquals('최근 뉴스', remaining[0].Title__c);
    }

}