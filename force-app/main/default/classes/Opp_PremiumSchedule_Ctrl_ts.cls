/**********************************************************************************
 * @filename      : Opp_PremiumSchedule_Ctrl_ts.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-02-15
 * @description   : Opp_PremiumSchedule_Ctrl 클래스의 테스트 클래스
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-15      i2max              Create
 **********************************************************************************/
@IsTest
private class Opp_PremiumSchedule_Ctrl_ts {
    /**
     * @description 공통 테스트 데이터 생성
     */
    @TestSetup
    static void setupTestData() {
        // Account 생성
        Account acc = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Test Account', 'OwnerId' => UserInfo.getUserId() },
        true
            );
        
        // RecordType 조회
        Id rtId = null;
        for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
            if (rti.isAvailable() && !rti.isMaster() && rti.getName() == 'Reinsurance') {
                rtId = rti.getRecordTypeId();
                break;
            }
        }
        
        // Reinsurance RecordType이 없으면 첫 번째 사용 가능한 RecordType 사용
        if (rtId == null) {
            for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
                if (rti.isAvailable() && !rti.isMaster()) {
                    rtId = rti.getRecordTypeId();
                    break;
                }
            }
        }
        
        // Opportunity 생성
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Test Opportunity', rtId, false);
        opp.PeriodFrom__c = Date.today();
        insert opp;
        
        // Premium Schedule 레코드 생성 (USD - Install 타입)
        insert new List<OPP_PremiumSchedule__c>{
            new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Prem_Currency__c = 'USD',
            PaymentType__c = 'Install',
            DaysFromInception__c = 0,
            Percentage__c = 50,
            OwnerId = UserInfo.getUserId()
                ),
            new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Prem_Currency__c = 'USD',
            PaymentType__c = 'Install',
            DaysFromInception__c = 30,
            Percentage__c = 50,
            OwnerId = UserInfo.getUserId()
                )
        };
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - 정상 케이스
     */
    @IsTest
    static void testGetOpportunityScheduleData_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper result = Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(
            opp.Id,
        'USD'
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(opp.Id, result.opportunityId, 'Opportunity ID가 일치해야 함');
        System.assertNotEquals(null, result.opportunityName, 'Opportunity Name이 null이 아니어야 함');
        System.assertEquals(2, result.totalInstalls, 'Total Installs가 2여야 함');
        System.assertNotEquals(null, result.periodFrom, 'Period From이 null이 아니어야 함');
        System.assertNotEquals(null, result.isClosed, 'isClosed가 null이 아니어야 함');
        System.assertEquals(2, result.schedules.size(), 'Schedule 목록이 2개여야 함');
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - 빈 Currency (매칭 없음)
     */
    @IsTest
    static void testGetOpportunityScheduleData_BlankCurrency() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper result = Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(
            opp.Id,
        ''
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(0, result.totalInstalls, '빈 Currency는 매칭되는 스케줄이 없어야 함');
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - null Currency (매칭 없음)
     */
    @IsTest
    static void testGetOpportunityScheduleData_NullCurrency() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper result = Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(
            opp.Id,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(0, result.totalInstalls, 'null Currency는 매칭되는 스케줄이 없어야 함');
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - 스케줄이 없는 Currency
     */
    @IsTest
    static void testGetOpportunityScheduleData_NoCurrency() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper result = Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(
            opp.Id,
        'EUR'
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(0, result.totalInstalls, 'EUR에는 스케줄이 없어야 함');
        System.assertEquals(0, result.schedules.size(), 'Schedule 목록이 비어있어야 함');
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - null recordId
     */
    @IsTest
    static void testGetOpportunityScheduleData_NullRecordId() {
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(null, 'USD');
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - 존재하지 않는 Opportunity
     */
    @IsTest
    static void testGetOpportunityScheduleData_InvalidOpportunity() {
        Id fakeOppId = '006000000000000AAA';
        
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(fakeOppId, 'USD');
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - 신규 레코드 생성
     */
    @IsTest
    static void testSavePremiumSchedules_Insert() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Map<String, Object>> schedules = new List<Map<String, Object>>();
        schedules.add(
        new Map<String, Object>{
            'id' => null,
            'daysFromInception' => 0,
            'percentage' => 60,
            'installDate' => Date.today()
        }
        );
        schedules.add(
        new Map<String, Object>{
            'id' => null,
            'daysFromInception' => 60,
            'percentage' => 40,
            'installDate' => Date.today().addDays(60)
        }
        );
        
        Test.startTest();
        String result = Opp_PremiumSchedule_Ctrl.savePremiumSchedules(opp.Id, 'EUR', 'Install', null, schedules);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assert(result.contains('success'), '성공 메시지를 포함해야 함');
        
        // 레코드가 생성되었는지 확인
        List<OPP_PremiumSchedule__c> savedSchedules = [
            SELECT Id, DaysFromInception__c, Percentage__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
            ORDER BY DaysFromInception__c
        ];
        System.assertEquals(2, savedSchedules.size(), '2개의 레코드가 생성되어야 함');
        System.assertEquals(0, savedSchedules[0].DaysFromInception__c, '첫 번째 Days가 0이어야 함');
        System.assertEquals(60, savedSchedules[0].Percentage__c, '첫 번째 Percentage가 60이어야 함');
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - 기존 레코드 업데이트
     */
    @IsTest
    static void testSavePremiumSchedules_Update() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OPP_PremiumSchedule__c> existingSchedules = [
            SELECT Id
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'USD'
            ORDER BY DaysFromInception__c
        ];
        
        List<Map<String, Object>> schedules = new List<Map<String, Object>>();
        schedules.add(
        new Map<String, Object>{
            'id' => existingSchedules[0].Id,
            'daysFromInception' => 0,
            'percentage' => 30,
            'installDate' => Date.today()
        }
        );
        schedules.add(
        new Map<String, Object>{
            'id' => existingSchedules[1].Id,
            'daysFromInception' => 45,
            'percentage' => 70,
            'installDate' => Date.today().addDays(45)
        }
        );
        
        Test.startTest();
        String result = Opp_PremiumSchedule_Ctrl.savePremiumSchedules(opp.Id, 'USD', 'Install', null, schedules);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assert(result.contains('success'), '성공 메시지를 포함해야 함');
        
        // 레코드가 업데이트되었는지 확인
        List<OPP_PremiumSchedule__c> updatedSchedules = [
            SELECT Id, DaysFromInception__c, Percentage__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'USD'
            ORDER BY DaysFromInception__c
        ];
        System.assertEquals(2, updatedSchedules.size(), '2개의 레코드가 있어야 함');
        System.assertEquals(0, updatedSchedules[0].DaysFromInception__c, '첫 번째 Days가 0이어야 함');
        System.assertEquals(30, updatedSchedules[0].Percentage__c, '첫 번째 Percentage가 30으로 업데이트되어야 함');
        System.assertEquals(45, updatedSchedules[1].DaysFromInception__c, '두 번째 Days가 45로 업데이트되어야 함');
        System.assertEquals(70, updatedSchedules[1].Percentage__c, '두 번째 Percentage가 70으로 업데이트되어야 함');
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - Insert와 Update 혼합
     */
    @IsTest
    static void testSavePremiumSchedules_Mixed() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OPP_PremiumSchedule__c> existingSchedules = [
            SELECT Id
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'USD'
            ORDER BY DaysFromInception__c
            LIMIT 1
        ];
        
        List<Map<String, Object>> schedules = new List<Map<String, Object>>();
        // 기존 레코드 업데이트
        schedules.add(
        new Map<String, Object>{
            'id' => existingSchedules[0].Id,
            'daysFromInception' => 0,
            'percentage' => 25,
            'installDate' => Date.today()
        }
        );
        // 새 레코드 추가
        schedules.add(
        new Map<String, Object>{
            'id' => null,
            'daysFromInception' => 30,
            'percentage' => 25,
            'installDate' => Date.today().addDays(30)
        }
        );
        schedules.add(
        new Map<String, Object>{
            'id' => null,
            'daysFromInception' => 60,
            'percentage' => 25,
            'installDate' => Date.today().addDays(60)
        }
        );
        schedules.add(
        new Map<String, Object>{
            'id' => null,
            'daysFromInception' => 90,
            'percentage' => 25,
            'installDate' => Date.today().addDays(90)
        }
        );
        
        Test.startTest();
        String result = Opp_PremiumSchedule_Ctrl.savePremiumSchedules(opp.Id, 'USD', 'Install', null, schedules);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        // 레코드 확인 (기존 2개 중 1개 업데이트 + 1개 그대로 유지 + 3개 신규 = 5개)
        List<OPP_PremiumSchedule__c> savedSchedules = [
            SELECT Id
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'USD'
        ];
        System.assertEquals(5, savedSchedules.size(), '5개의 레코드가 있어야 함 (기존 2개 + 신규 3개)');
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - null opportunityId
     */
    @IsTest
    static void testSavePremiumSchedules_NullOpportunityId() {
        List<Map<String, Object>> schedules = new List<Map<String, Object>>();
        schedules.add(new Map<String, Object>{ 'daysFromInception' => 0, 'percentage' => 100 });
        
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.savePremiumSchedules(null, 'USD', 'Install', null, schedules);
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - 빈 schedules
     */
    @IsTest
    static void testSavePremiumSchedules_EmptySchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Map<String, Object>> schedules = new List<Map<String, Object>>();
        
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.savePremiumSchedules(opp.Id, 'USD', 'Install', null, schedules);
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - null schedules
     */
    @IsTest
    static void testSavePremiumSchedules_NullSchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.savePremiumSchedules(opp.Id, 'USD', 'Install', null, null);
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description savePremiumSchedules 메서드 테스트 - 총 percentage가 100이 아닌 경우
     */
    @IsTest
    static void testSavePremiumSchedules_InvalidPercentage() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Map<String, Object>> schedules = new List<Map<String, Object>>();
        schedules.add(new Map<String, Object>{ 'daysFromInception' => 0, 'percentage' => 40 });
        schedules.add(new Map<String, Object>{ 'daysFromInception' => 30, 'percentage' => 40 });
        
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.savePremiumSchedules(opp.Id, 'EUR', 'Install', null, schedules);
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    
    
    /**
     * @description deletePremiumSchedule 메서드 테스트 - 정상 케이스
     */
    @IsTest
    static void testDeletePremiumSchedule_Success() {
        OPP_PremiumSchedule__c schedule = [SELECT Id FROM OPP_PremiumSchedule__c LIMIT 1];
        
        Test.startTest();
        String result = Opp_PremiumSchedule_Ctrl.deletePremiumSchedule(schedule.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assert(result.contains('deleted successfully'), '성공 메시지를 포함해야 함');
        
        // 레코드가 삭제되었는지 확인
        List<OPP_PremiumSchedule__c> deletedSchedules = [
            SELECT Id
            FROM OPP_PremiumSchedule__c
            WHERE Id = :schedule.Id
        ];
        System.assertEquals(0, deletedSchedules.size(), '레코드가 삭제되어야 함');
    }
    
    /**
     * @description deletePremiumSchedule 메서드 테스트 - null scheduleId
     */
    @IsTest
    static void testDeletePremiumSchedule_NullId() {
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.deletePremiumSchedule(null);
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description deletePremiumSchedule 메서드 테스트 - 존재하지 않는 scheduleId
     */
    @IsTest
    static void testDeletePremiumSchedule_InvalidId() {
        // 가짜 ID 생성
        Id fakeId = 'a00000000000000AAA';
        
        Test.startTest();
        try {
            Opp_PremiumSchedule_Ctrl.deletePremiumSchedule(fakeId);
            System.assert(false, '예외가 발생해야 함');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'AuraHandledException이어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description calculateInstallDate 메서드 테스트 - 정상 케이스
     */
    @IsTest
    static void testCalculateInstallDate_Success() {
        Date periodFrom = Date.today();
        Integer daysFromInception = 30;
        
        Test.startTest();
        Date result = Opp_PremiumSchedule_Ctrl.calculateInstallDate(periodFrom, daysFromInception);
        Test.stopTest();
        
        System.assertEquals(periodFrom.addDays(30), result, '30일 후의 날짜여야 함');
    }
    
    /**
     * @description calculateInstallDate 메서드 테스트 - daysFromInception이 0인 경우
     */
    @IsTest
    static void testCalculateInstallDate_ZeroDays() {
        Date periodFrom = Date.today();
        Integer daysFromInception = 0;
        
        Test.startTest();
        Date result = Opp_PremiumSchedule_Ctrl.calculateInstallDate(periodFrom, daysFromInception);
        Test.stopTest();
        
        System.assertEquals(periodFrom, result, 'PeriodFrom과 같은 날짜여야 함');
    }
    
    /**
     * @description calculateInstallDate 메서드 테스트 - daysFromInception이 null인 경우
     */
    @IsTest
    static void testCalculateInstallDate_NullDays() {
        Date periodFrom = Date.today();
        
        Test.startTest();
        Date result = Opp_PremiumSchedule_Ctrl.calculateInstallDate(periodFrom, null);
        Test.stopTest();
        
        System.assertEquals(periodFrom, result, 'PeriodFrom과 같은 날짜여야 함 (null은 0으로 처리)');
    }
    
    /**
     * @description calculateInstallDate 메서드 테스트 - periodFrom이 null인 경우
     */
    @IsTest
    static void testCalculateInstallDate_NullPeriodFrom() {
        Integer daysFromInception = 30;
        
        Test.startTest();
        Date result = Opp_PremiumSchedule_Ctrl.calculateInstallDate(null, daysFromInception);
        Test.stopTest();
        
        System.assertEquals(null, result, 'null을 반환해야 함');
    }
    
    /**
     * @description calculateInstallDate 메서드 테스트 - 음수 daysFromInception
     */
    @IsTest
    static void testCalculateInstallDate_NegativeDays() {
        Date periodFrom = Date.today();
        Integer daysFromInception = -10;
        
        Test.startTest();
        Date result = Opp_PremiumSchedule_Ctrl.calculateInstallDate(periodFrom, daysFromInception);
        Test.stopTest();
        
        System.assertEquals(periodFrom.addDays(-10), result, '10일 전의 날짜여야 함');
    }
    
    // ============================================================
    // getInitMeta 테스트
    // ============================================================
    
    /**
     * @description getInitMeta 메서드 테스트 - Opportunity Id 전달 시 isPlacement=false 반환 확인
     */
    @IsTest
    static void testGetInitMeta_WithOppId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.InitMetaWrapper w = Opp_PremiumSchedule_Ctrl.getInitMeta(opp.Id);
        Test.stopTest();
        
        Assert.isNotNull(w, '결과가 null이 아니어야 함');
        Assert.areEqual(false, w.isPlacement, 'Opportunity ID 전달 시 isPlacement는 false여야 함');
        Assert.isNotNull(w.hasEditPermission, 'hasEditPermission이 null이 아니어야 함');
    }
    
    /**
     * @description getInitMeta 메서드 테스트 - null Id 전달 시 기본값 반환 확인
     */
    @IsTest
    static void testGetInitMeta_NullId() {
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.InitMetaWrapper w = Opp_PremiumSchedule_Ctrl.getInitMeta(null);
        Test.stopTest();
        
        Assert.isNotNull(w, '결과가 null이 아니어야 함');
        Assert.areEqual(false, w.isPlacement, 'null ID 시 isPlacement 기본값은 false여야 함');
        Assert.areEqual(false, w.hasEditPermission, 'null ID 시 hasEditPermission 기본값은 false여야 함');
    }
    
    /**
     * @description InitMetaWrapper 기본값 테스트
     */
    @IsTest
    static void testInitMetaWrapper_Defaults() {
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.InitMetaWrapper w = new Opp_PremiumSchedule_Ctrl.InitMetaWrapper();
        Test.stopTest();
        
        Assert.areEqual(false, w.isPlacement, '기본값 isPlacement는 false여야 함');
        Assert.areEqual(false, w.hasEditPermission, '기본값 hasEditPermission은 false여야 함');
    }
    
    /**
     * @description getOpportunityScheduleData 메서드 테스트 - Placement__c Id 기준 조회 확인
     */
    @IsTest
    static void testGetOpportunityScheduleData_WithPlacementId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        List<OPP_PremiumSchedule__c> placementSchedules = new List<OPP_PremiumSchedule__c>{
            new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Placement_lk__c = placement.Id,
            Prem_Currency__c = 'USD',
            PaymentType__c = 'Install',
            DaysFromInception__c = 0,
            Percentage__c = 50
                ),
            new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Placement_lk__c = placement.Id,
            Prem_Currency__c = 'USD',
            PaymentType__c = 'Install',
            DaysFromInception__c = 30,
            Percentage__c = 50
                )
        };
        insert placementSchedules;
        
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper result = Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData(
            placement.Id,
        'USD'
            );
        Test.stopTest();
        
        Assert.isNotNull(result, '결과가 null이 아니어야 함');
        Assert.areEqual(opp.Id, result.opportunityId, 'Placement의 Parent Opportunity ID를 반환해야 함');
        Assert.areEqual(2, result.totalInstalls, 'Placement 기준 2개의 스케줄이 있어야 함');
        Assert.areEqual(2, result.schedules.size(), 'Schedule 목록이 2개여야 함');
    }
    
    /**
     * @description OpportunityScheduleWrapper 클래스 테스트
     */
    @IsTest
    static void testOpportunityScheduleWrapper() {
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper wrapper = new Opp_PremiumSchedule_Ctrl.OpportunityScheduleWrapper();
        wrapper.opportunityId = '006000000000000AAA';
        wrapper.opportunityName = 'Test Opp';
        wrapper.totalInstalls = 3;
        wrapper.periodFrom = Date.today();
        wrapper.isClosed = false;
        wrapper.schedules = new List<Opp_PremiumSchedule_Ctrl.PremiumScheduleItem>();
        Test.stopTest();
        
        System.assertEquals('006000000000000AAA', wrapper.opportunityId, 'opportunityId가 설정되어야 함');
        System.assertEquals('Test Opp', wrapper.opportunityName, 'opportunityName이 설정되어야 함');
        System.assertEquals(3, wrapper.totalInstalls, 'totalInstalls가 3이어야 함');
        System.assertEquals(Date.today(), wrapper.periodFrom, 'periodFrom이 설정되어야 함');
        System.assertEquals(false, wrapper.isClosed, 'isClosed가 false여야 함');
        System.assertNotEquals(null, wrapper.schedules, 'schedules가 null이 아니어야 함');
    }
    
    /**
     * @description PremiumScheduleItem 클래스 테스트
     */
    @IsTest
    static void testPremiumScheduleItem() {
        Test.startTest();
        Opp_PremiumSchedule_Ctrl.PremiumScheduleItem item = new Opp_PremiumSchedule_Ctrl.PremiumScheduleItem();
        item.id = 'a00000000000000AAA';
        item.daysFromInception = 30;
        item.percentage = 50.5;
        item.installDate = Date.today();
        Test.stopTest();
        
        System.assertEquals('a00000000000000AAA', item.id, 'id가 설정되어야 함');
        System.assertEquals(30, item.daysFromInception, 'daysFromInception이 30이어야 함');
        System.assertEquals(50.5, item.percentage, 'percentage가 50.5여야 함');
        System.assertEquals(Date.today(), item.installDate, 'installDate가 설정되어야 함');
    }
}