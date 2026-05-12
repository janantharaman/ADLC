/**********************************************************************************
 * @filename      : ACC_AdditionalAccountInfo_tr_ts.cls
 * @project-name  :
 * @author        : i2max
 * @date          : 2026-04-15
 * @group         :
 * @group-content :
 * @description   : Test class for ACC_AdditionalAccountInfo_tr
 *
 *                  ACC_AdditionalInfo__c Before Insert 시 Name 자동 조합 로직을 검증한다.
 *                  Name = Account.CompanyAcronym__c + '_' + Reinsurer.CompanyAcronym__c + '_' + BindingFrom(YYMMDD)
 *
 *                  [검증 전략]
 *                  1) setName_AllFields       : Account / Reinsurer / BindingFrom 모두 설정 →
 *                                              세 값 언더스코어 결합 확인 (정상 경로)
 *
 *                  2) setName_AccountOnly     : Account만 설정, Reinsurer / BindingFrom null →
 *                                              CompanyAcronym__c 단독 Name 확인
 *
 *                  3) setName_ReinsurerOnly   : Reinsurer만 설정, Account / BindingFrom null →
 *                                              CompanyAcronym__c 단독 Name 확인
 *
 *                  4) setName_BindingFromOnly : BindingFrom만 설정, Account / Reinsurer null →
 *                                              날짜 문자열 단독 Name 확인
 *
 *                  5) setName_AccountAndReinsurer_NoDate
 *                                            : Account + Reinsurer, BindingFrom null →
 *                                              두 약어 결합 Name 확인
 *
 *                  6) setName_AccountAndDate_NoReinsurer
 *                                            : Account + BindingFrom, Reinsurer null →
 *                                              약어 + 날짜 결합 Name 확인
 *
 *                  7) setName_ReinsurerAndDate_NoAccount
 *                                            : Reinsurer + BindingFrom, Account null →
 *                                              약어 + 날짜 결합 Name 확인
 *
 *                  8) setName_NoFields       : Account / Reinsurer / BindingFrom 모두 null →
 *                                              Name 자동채움 확인
 *
 *                  9) setName_AccountBlankAcronym
 *                                            : Account.CompanyAcronym__c blank →
 *                                              additionalInfoNames에 미추가, 날짜만 포함 확인
 *
 *                  10) setName_ReinsurerBlankAcronym
 *                                            : Reinsurer.CompanyAcronym__c blank →
 *                                              additionalInfoNames에 미추가, Account만 포함 확인
 *
 *                  11) setName_BulkInsert    : 복수 레코드 일괄 삽입 →
 *                                             각 레코드 Name 독립 조합 확인
 *
 *                  12) testAfterUpdate_Bypassed
 *                                            : bypass 설정 후 run() → beforeInsert 미호출 확인
 *
 * @test-class    : ACC_AdditionalAccountInfo_tr.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-04-15      i2max            Create
 **********************************************************************************/
@IsTest
private class ACC_AdditionalAccountInfo_tr_ts {

    // ============================================================
    // Test Setup
    // ============================================================

    /**
     * @description 테스트 전체에서 공유할 Account 레코드 생성.
     *              MGA 타입 / Reinsurer 타입 각 1건, CompanyAcronym__c 값 지정.
     *              ACC_TestDataFactory 미사용 케이스는 개별 메서드 내에서 생성한다.
     */
    @TestSetup
    static void setup() {
        // MGA Account: CompanyAcronym__c = 'MGA_ACRONYM'
        Account mgaAcc = ACC_TestDataFactory.createAccount('TestMGA', 'MGA', false );
        mgaAcc.CompanyAcronym__c = 'MGA_ACRONYM';
        insert mgaAcc;

        // Reinsurer Account: CompanyAcronym__c = 'REI_ACRONYM'
        Account reinsurerAcc = ACC_TestDataFactory.createAccount('TestReinsurer', 'Reinsurer', false);
        reinsurerAcc.CompanyAcronym__c = 'REI_ACRONYM';
        insert reinsurerAcc;
    }

    // ============================================================
    // Helper - 공통 Account 조회
    // ============================================================

    private static Account getMGA() {
        return [SELECT Id, CompanyAcronym__c FROM Account WHERE isMGAAcc__c = TRUE LIMIT 1];
    }

    private static Account getReinsurer() {
        return [SELECT Id, CompanyAcronym__c FROM Account WHERE isReinsurerAcc__c = TRUE LIMIT 1];
    }

    // ============================================================
    // 1) 정상 경로 - Account / Reinsurer / BindingFrom 모두 설정
    // ============================================================

    /**
     * @description Account, Reinsurer, BindingFrom 세 값 모두 설정 시
     *              Name = 'MGA_ACRONYM_REI_ACRONYM_260101' 형식으로 조합됨을 확인한다.
     *              COM_Util.getDateYYMMDD 는 Date → 'YYMMDD' 변환을 수행한다고 가정한다.
     */
    @IsTest
    static void setName_AllFields() {
        Account mgaAcc = getMGA();
        Account reinsurerAcc = getReinsurer();
        Date bindingFrom = Date.newInstance(2026, 1, 1);

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = mgaAcc.Id;
        rec.Reinsurer_lk__c = reinsurerAcc.Id;
        rec.BindingFrom__c = bindingFrom;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        String expectedName = mgaAcc.CompanyAcronym__c + '_' + reinsurerAcc.CompanyAcronym__c + '_' + COM_Util.getDateYYMMDD(bindingFrom);
        Assert.areEqual(expectedName, result.Name, 'Account + Reinsurer + BindingFrom 조합 Name이어야 함');
    }

    // ============================================================
    // 2) Account만 설정, Reinsurer / BindingFrom null
    // ============================================================

    /**
     * @description Account_lk__c 만 설정하고 Reinsurer / BindingFrom 이 null 일 때
     *              Name = CompanyAcronym__c 단독 값임을 확인한다.
     */
    @IsTest
    static void setName_AccountOnly() {
        Account mgaAcc = getMGA();

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = mgaAcc.Id;
        rec.Reinsurer_lk__c = null;
        rec.BindingFrom__c = null;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        Assert.areEqual(mgaAcc.CompanyAcronym__c, result.Name, 'Account 단독 Name이어야 함');
    }

    // ============================================================
    // 3) Reinsurer만 설정, Account / BindingFrom null
    // ============================================================

    /**
     * @description Reinsurer_lk__c 만 설정하고 Account / BindingFrom 이 null 일 때
     *              Name = Reinsurer.CompanyAcronym__c 단독 값임을 확인한다.
     */
    @IsTest
    static void setName_ReinsurerOnly() {
        Account mgaAcc = getMGA();
        Account reinsurerAcc = getReinsurer();

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = null;
        rec.Reinsurer_lk__c = reinsurerAcc.Id;
        rec.BindingFrom__c = null;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        Assert.areEqual(reinsurerAcc.CompanyAcronym__c, result.Name, 'Reinsurer 단독 Name이어야 함');
    }

    // ============================================================
    // 4) BindingFrom만 설정, Account / Reinsurer null
    // ============================================================

    /**
     * @description BindingFrom__c 만 설정하고 Account / Reinsurer 가 null 일 때
     *              Name = COM_Util.getDateYYMMDD(BindingFrom) 단독 값임을 확인한다.
     */
    @IsTest
    static void setName_BindingFromOnly() {
        Account mgaAcc = getMGA();
        Date bindingFrom = Date.newInstance(2026, 6, 15);

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = null;
        rec.Reinsurer_lk__c = null;
        rec.BindingFrom__c = bindingFrom;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        String expectedName = COM_Util.getDateYYMMDD(bindingFrom);
        Assert.areEqual(expectedName, result.Name, 'BindingFrom 단독 Name이어야 함');
    }

    // ============================================================
    // 5) Account + Reinsurer, BindingFrom null
    // ============================================================

    /**
     * @description Account + Reinsurer 설정, BindingFrom null 일 때
     *              Name = 'MGA_ACRONYM_REI_ACRONYM' 형식임을 확인한다.
     */
    @IsTest
    static void setName_AccountAndReinsurer_NoDate() {
        Account mgaAcc = getMGA();
        Account reinsurerAcc = getReinsurer();

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = mgaAcc.Id;
        rec.Reinsurer_lk__c = reinsurerAcc.Id;
        rec.BindingFrom__c = null;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        String expectedName = mgaAcc.CompanyAcronym__c + '_' + reinsurerAcc.CompanyAcronym__c;
        System.debug('expectedName=['+ expectedName +']');
        System.debug('result.Name=['+ result.Name +']');
        Assert.areEqual(expectedName, result.Name, 'Account + Reinsurer 조합 Name이어야 함');
    }

    // ============================================================
    // 6) Account + BindingFrom, Reinsurer null
    // ============================================================

    /**
     * @description Account + BindingFrom 설정, Reinsurer null 일 때
     *              Name = 'MGA_ACRONYM_YYMMDD' 형식임을 확인한다.
     */
    @IsTest
    static void setName_AccountAndDate_NoReinsurer() {
        Account mgaAcc = getMGA();
        Date bindingFrom = Date.newInstance(2026, 3, 31);

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = mgaAcc.Id;
        rec.Reinsurer_lk__c = null;
        rec.BindingFrom__c = bindingFrom;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        String expectedName = mgaAcc.CompanyAcronym__c + '_' + COM_Util.getDateYYMMDD(bindingFrom);
        Assert.areEqual(expectedName, result.Name, 'Account + BindingFrom 조합 Name이어야 함');
    }

    // ============================================================
    // 7) Reinsurer + BindingFrom, Account null
    // ============================================================

    /**
     * @description Reinsurer + BindingFrom 설정, Account null 일 때
     *              Name = 'REI_ACRONYM_YYMMDD' 형식임을 확인한다.
     */
    @IsTest
    static void setName_ReinsurerAndDate_NoAccount() {
        Account mgaAcc = getMGA();
        Account reinsurerAcc = getReinsurer();
        Date bindingFrom = Date.newInstance(2026, 12, 31);

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = null;
        rec.Reinsurer_lk__c = reinsurerAcc.Id;
        rec.BindingFrom__c = bindingFrom;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        String expectedName = reinsurerAcc.CompanyAcronym__c + '_' + COM_Util.getDateYYMMDD(bindingFrom);
        Assert.areEqual(expectedName, result.Name, 'Reinsurer + BindingFrom 조합 Name이어야 함');
    }

    // ============================================================
    // 8) Account / Reinsurer / BindingFrom 모두 null
    // ============================================================

    /**
     * @description Account_lk__c / Reinsurer_lk__c / BindingFrom__c 모두 null 일 때
     *              additionalInfoNames 리스트가 비어 String.join 결과가 자동값임을 확인한다.
     */
    @IsTest
    static void setName_NoFields() {
        Account mgaAcc = getMGA();

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = null;
        rec.Reinsurer_lk__c = null;
        rec.BindingFrom__c = null;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        Assert.isTrue(String.isNotBlank(result.Name), 'Name = null 이면 Name은 자동값으로 채워짐');
    }

    // ============================================================
    // 9) Account.CompanyAcronym__c blank → additionalInfoNames 미추가
    // ============================================================

    /**
     * @description Account.CompanyAcronym__c 가 blank(공백 / null) 이면
     *              String.isNotBlank 조건 실패로 additionalInfoNames에 추가되지 않고,
     *              Name 에 Account 약어가 포함되지 않음을 확인한다.
     *              (BindingFrom 만 Name에 포함되어야 함)
     */
    @IsTest
    static void setName_AccountBlankAcronym() {
        // CompanyAcronym__c 가 blank 인 별도 Account 생성
        Account blankAcronymAcc = ACC_TestDataFactory.createAccount('BlankAcronymMGA', 'MGA', false);
        blankAcronymAcc.CompanyAcronym__c = '';
        insert blankAcronymAcc;

        Date bindingFrom = Date.newInstance(2026, 7, 4);

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(blankAcronymAcc.Id, 'Security', null, false);
        rec.Account_lk__c = blankAcronymAcc.Id;
        rec.Reinsurer_lk__c = null;
        rec.BindingFrom__c = bindingFrom;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        String expectedName = COM_Util.getDateYYMMDD(bindingFrom);
        Assert.areEqual(expectedName, result.Name, 'Account 약어 blank 시 날짜만 Name에 포함되어야 함');
        Assert.isFalse(result.Name.contains('BlankAcronymMGA'), 'Account Name이 포함되어선 안 됨');
    }

    // ============================================================
    // 10) Reinsurer.CompanyAcronym__c blank → additionalInfoNames 미추가
    // ============================================================

    /**
     * @description Reinsurer.CompanyAcronym__c 가 blank 이면
     *              additionalInfoNames에 추가되지 않으며,
     *              Name에 Account 약어만 포함됨을 확인한다.
     */
    @IsTest
    static void setName_ReinsurerBlankAcronym() {
        Account mgaAcc = getMGA();

        // CompanyAcronym__c 가 blank 인 Reinsurer Account 생성
        Account blankReinsurerAcc = ACC_TestDataFactory.createAccount('BlankReinsurerAcc', 'Reinsurer', false);
        blankReinsurerAcc.CompanyAcronym__c = '   ';
        insert blankReinsurerAcc;

        ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec.Account_lk__c = mgaAcc.Id;
        rec.Reinsurer_lk__c = blankReinsurerAcc.Id;
        rec.BindingFrom__c = null;

        Test.startTest();
        Database.SaveResult sr = Database.insert(rec);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

        ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
        Assert.areEqual(mgaAcc.CompanyAcronym__c, result.Name, 'Reinsurer 약어 blank 시 Account 약어만 Name에 포함되어야 함');
        Assert.isFalse(result.Name.contains('BlankReinsurerAcc'), 'Reinsurer Name이 포함되어선 안 됨');
    }

    // ============================================================
    // 11) Bulk Insert - 복수 레코드 일괄 삽입
    // ============================================================

    /**
     * @description 복수 ACC_AdditionalInfo__c 레코드를 일괄 삽입할 때
     *              각 레코드의 Name 이 독립적으로 올바르게 조합됨을 확인한다.
     *              SOQL을 최소화하는 bulkification 설계가 정상 동작하는지 검증한다.
     */
    @IsTest
    static void setName_BulkInsert() {
        Account mgaAcc = getMGA();
        Account reinsurerAcc = getReinsurer();
        Date bindingFrom1 = Date.newInstance(2026, 1, 1);
        Date bindingFrom2 = Date.newInstance(2026, 6, 30);

        // 레코드 1: Account + Reinsurer + BindingFrom 전체
        ACC_AdditionalInfo__c rec1 = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec1.Account_lk__c = mgaAcc.Id;
        rec1.Reinsurer_lk__c = reinsurerAcc.Id;
        rec1.BindingFrom__c = bindingFrom1;

        // 레코드 2: Account만 (Reinsurer / BindingFrom null)
        ACC_AdditionalInfo__c rec2 = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec2.Account_lk__c = mgaAcc.Id;
        rec2.Reinsurer_lk__c = null;
        rec2.BindingFrom__c = bindingFrom2;

        // 레코드 3: 모두 null
        ACC_AdditionalInfo__c rec3 = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
        rec3.Account_lk__c = null;
        rec3.Reinsurer_lk__c = null;
        rec3.BindingFrom__c = null;

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(new List<ACC_AdditionalInfo__c>{ rec1, rec2, rec3 });
        Test.stopTest();

        for (Database.SaveResult sr : results) {
            Assert.isTrue(sr.isSuccess(), '모든 레코드 삽입이 성공해야 함');
        }

        Map<Id, ACC_AdditionalInfo__c> insertedMap = new Map<Id, ACC_AdditionalInfo__c>(
                [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id IN :new List<Id>{ rec1.Id, rec2.Id, rec3.Id }]
        );

        // rec1: Account + Reinsurer + BindingFrom
        String expectedName1 = mgaAcc.CompanyAcronym__c + '_' + reinsurerAcc.CompanyAcronym__c + '_' + COM_Util.getDateYYMMDD(bindingFrom1);
        Assert.areEqual(expectedName1, insertedMap.get(rec1.Id).Name, 'rec1 Name이 올바르게 조합되어야 함');

        // rec2: Account + BindingFrom (Reinsurer null)
        String expectedName2 = mgaAcc.CompanyAcronym__c + '_' + COM_Util.getDateYYMMDD(bindingFrom2);
        Assert.areEqual(expectedName2, insertedMap.get(rec2.Id).Name, 'rec2 Name이 올바르게 조합되어야 함');

        // rec3: 모두 null → Name은 자동값으로 채워짐
        Assert.isTrue(String.isNotBlank(insertedMap.get(rec3.Id).Name), 'rec3 Name = null이면 Name은 Salesforce 자동값으로 채워짐');
    }

    // ============================================================
    // 12) TriggerHandler bypass 테스트
    // ============================================================

    /**
     * @description ACC_AdditionalAccountInfo_tr 를 bypass 설정하면
     *              beforeInsert 가 호출되지 않아 Name 자동 조합이 실행되지 않음을 확인한다.
     *              bypass 후 clearBypass 로 원복하여 다른 테스트에 영향을 주지 않는다.
     *
     *              ※ bypass 시 Name 필드는 트리거에 의해 설정되지 않으므로
     *                Object 기본값 또는 빈 문자열이 유지된다.
     */
    @IsTest
    static void testBeforeInsert_Bypassed() {
        Account mgaAcc = getMGA();
        Account reinsurerAcc = getReinsurer();

        TriggerHandler.bypass(ACC_AdditionalAccountInfo_tr.class);
        try {
            ACC_AdditionalInfo__c rec = ACC_TestDataFactory.createAdditionalInfo(mgaAcc.Id, 'Security', null, false);
            rec.Account_lk__c = mgaAcc.Id;
            rec.Reinsurer_lk__c = reinsurerAcc.Id;
            rec.BindingFrom__c = Date.newInstance(2026, 1, 1);

            Test.startTest();
            Database.SaveResult sr = Database.insert(rec);
            Test.stopTest();

            Assert.isTrue(sr.isSuccess(), '삽입이 성공해야 함');

            ACC_AdditionalInfo__c result = [SELECT Id, Name FROM ACC_AdditionalInfo__c WHERE Id = :rec.Id];
            String expectedName = mgaAcc.CompanyAcronym__c + '_' + reinsurerAcc.CompanyAcronym__c + '_' + COM_Util.getDateYYMMDD(Date.newInstance(2026, 1, 1));
            // bypass 상태이므로 트리거가 Name을 조합하지 않아야 함
            Assert.areNotEqual(expectedName, result.Name, 'bypass 시 Name 자동 조합이 실행되지 않아야 함');
        } finally {
            TriggerHandler.clearBypass(ACC_AdditionalAccountInfo_tr.class);
        }
    }
}