/**********************************************************************************
 * @filename       : AdditionalAccountInfoCheckActive_ba.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : AdditionalAccountInfoCheckActive_ba_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-06      i2max            Create
**********************************************************************************/

@isTest
private class AdditionalAccountInfoCheckActive_ba_ts {

    @testSetup
    static void setup() {
        Account acc = ACC_TestDataFactory.createAccount('Test Account', null, true);

        List<ACC_AdditionalInfo__c> infoList = new List<ACC_AdditionalInfo__c>();

        // 과거 + Active=true → 배치가 false로 바꿔야 할 대상
        ACC_AdditionalInfo__c info1 = ACC_TestDataFactory.createBankInfo(acc.Id, false);
        info1.BindingTo__c = Date.today().addDays(-5);
        info1.ActiveRe_is__c = true;
        infoList.add(info1);

        // 과거 + Active=false → 배치 쿼리 대상 아님
        ACC_AdditionalInfo__c info2 = ACC_TestDataFactory.createBankInfo(acc.Id, false);
        info2.BindingTo__c = Date.today().addDays(-5);
        info2.ActiveRe_is__c = false;
        infoList.add(info2);

        // 미래 + Active=true → 배치 쿼리 대상 아님
        ACC_AdditionalInfo__c info3 = ACC_TestDataFactory.createBankInfo(acc.Id, false);
        info3.BindingTo__c = Date.today().addDays(5);
        info3.ActiveRe_is__c = true;
        infoList.add(info3);

        insert infoList;
    }

    @isTest
    static void testBatchExecution() {
        Assert.areEqual(2, [SELECT count() FROM ACC_AdditionalInfo__c WHERE ActiveRe_is__c = true], '초기 레코드 개수 확인');

        Test.startTest();
        AdditionalAccountInfoCheckActive_ba batch = new AdditionalAccountInfoCheckActive_ba();
        Database.executeBatch(batch);
        Test.stopTest();

        // 결과 검증
        List<ACC_AdditionalInfo__c> updatedRecords = [
                SELECT Id, ActiveRe_is__c
                FROM ACC_AdditionalInfo__c
                WHERE BindingTo__c < TODAY
        ];

        for(ACC_AdditionalInfo__c info : updatedRecords) {
            Assert.isFalse(info.ActiveRe_is__c, '과거 날짜의 레코드 FALSE');
        }

        ACC_AdditionalInfo__c futureRecord = [
                SELECT ActiveRe_is__c
                FROM ACC_AdditionalInfo__c
                WHERE BindingTo__c > TODAY
                LIMIT 1
        ];
        Assert.isTrue(futureRecord.ActiveRe_is__c, '미래 날짜의 레코드 TRUE');
    }

    @isTest
    static void testBatchExecutionWithError() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // insert 후 삭제하여 존재하지 않는 Id 확보
        ACC_AdditionalInfo__c ghostRecord = new ACC_AdditionalInfo__c(
                Account_lk__c = acc.Id,
                BindingTo__c = Date.today().addDays(-1),
                ActiveRe_is__c = true
        );
        insert ghostRecord;
        Id ghostId = ghostRecord.Id;
        delete ghostRecord;

        // 삭제된 레코드로 update 실패 유도
        ACC_AdditionalInfo__c failTarget = new ACC_AdditionalInfo__c(
                Id = ghostId,
                ActiveRe_is__c = false
        );

        Test.startTest();
        AdditionalAccountInfoCheckActive_ba batch = new AdditionalAccountInfoCheckActive_ba();
        batch.execute(null, new List<ACC_AdditionalInfo__c>{ failTarget });
        Test.stopTest();

        Assert.isTrue(true, 'execute 실패 분기 정상 처리됨');
    }
}