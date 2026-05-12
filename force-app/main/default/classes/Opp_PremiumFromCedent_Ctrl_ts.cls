/**********************************************************************************
 * @filename      : Opp_PremiumFromCedent_Ctrl_ts.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-01-30
 * @description   : Opp_PremiumFromCedent_Ctrl 클래스의 테스트 클래스
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-30      i2max              Create
 **********************************************************************************/
@IsTest
private class Opp_PremiumFromCedent_Ctrl_ts {
    /**
     * @description 공통 테스트 데이터 생성
     */
    @TestSetup
    static void setupTestData() {
        // Account 생성
        Account acc = (Account) TestDataFactory.createSObject('Account', new Map<String, Object>{ 'Name' => 'Test Account', 'OwnerId' => UserInfo.getUserId() }, true);
        
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
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Test Opportunity', rtId, true);
        
        // Premium Schedule 레코드 생성 (USD - Install 타입)
        List<OPP_PremiumSchedule__c> schedules = new List<OPP_PremiumSchedule__c>();
        for (Integer i = 0; i < 2; i++) {
            schedules.add(
                new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Prem_Currency__c = 'USD',
            PaymentType__c = 'Install',
            DaysFromInception__c = i * 30,
            Percentage__c = 50,
            OwnerId = UserInfo.getUserId()
                )
                );
        }
        insert schedules;
    }
    
    // ============================================================
    // getInitData 테스트
    // ============================================================
    
    /**
     * @description InitDataWrapper 기본값 테스트
     */
    @IsTest
    static void testInitDataWrapper_Defaults() {
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = new Opp_PremiumFromCedent_Ctrl.InitDataWrapper();
        Test.stopTest();
        
        System.assertNotEquals(null, w.paymentTypeOptions, 'paymentTypeOptions 기본값은 빈 리스트여야 함');
        System.assertEquals(0, w.paymentTypeOptions.size(), 'paymentTypeOptions 기본값은 빈 리스트여야 함');
        System.assertEquals(false, w.isClosed, '기본값 isClosed는 false여야 함');
        System.assertEquals(false, w.isPlacement, '기본값 isPlacement는 false여야 함');
        System.assertEquals(false, w.hasEditPermission, '기본값 hasEditPermission은 false여야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - PaymentTypeOptions 반환 확인
     */
    @IsTest
    static void testGetInitData_PaymentTypeOptions_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w.paymentTypeOptions, '옵션이 null이 아니어야 함');
        System.assert(w.paymentTypeOptions.size() > 0, '최소 1개 이상의 옵션이 있어야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - Premium Schedule이 있는 경우 (Install 타입)
     */
    @IsTest
    static void testGetInitData_WithInstallSchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
        System.assertEquals('Install', w.paymentType, 'Payment Type이 Install이어야 함');
        System.assertNotEquals(null, w.isClosed, 'isClosed가 null이 아니어야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - Single 타입 (SlipGrossPrem__c → grossPrem 반환 확인)
     */
    @IsTest
    static void testGetInitData_WithSingleSchedule() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        OPP_PremiumSchedule__c schedule = (OPP_PremiumSchedule__c) TestDataFactory.createSObject(
            'OPP_PremiumSchedule__c',
        new Map<String, Object>{
            'Opportunity_lk__c' => opp.Id,
            'Prem_Currency__c' => 'EUR',
            'PaymentType__c' => 'Single',
            'SlipGrossPrem__c' => 500000,
            'DaysFromInception__c' => null,
            'Percentage__c' => null,
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, 'EUR');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
        System.assertEquals('Single', w.paymentType, 'Payment Type이 Single이어야 함');
        System.assertEquals(null, w.totalInstalls, 'Total Installs가 null이어야 함');
        System.assertEquals(500000, w.grossPrem, 'grossPrem이 SlipGrossPrem__c에서 반환되어야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - transactionType 필드 반환 확인 (Placement 기준)
     */
    @IsTest
    static void testGetInitData_TransactionType() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TransactionType__c = 'Declaration',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(placement.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
        System.assertEquals('Declaration', w.transactionType, 'transactionType이 Declaration이어야 함');
    }
    
    
    
    /**
     * @description getInitData 메서드 테스트 - Premium Schedule이 없는 경우
     */
    @IsTest
    static void testGetInitData_NoSchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, 'EUR');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
        System.assertNotEquals(null, w.isClosed, 'isClosed가 null이 아니어야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - blank currency
     */
    @IsTest
    static void testGetInitData_BlankCurrency() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, '');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - null currency
     */
    @IsTest
    static void testGetInitData_NullCurrency() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, null);
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
    }
    
    /**
     * @description getInitData 메서드 테스트 - null oppId (예외 발생)
     */
    @IsTest
    static void testGetInitData_NullOppId() {
        Test.startTest();
        try {
            Opp_PremiumFromCedent_Ctrl.getInitData(null, 'USD');
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'AuraHandledException catch 경로 실행 확인: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // ============================================================
    // updatePaymentInfo 테스트
    // ============================================================
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Install 타입
     */
    @IsTest
    static void testUpdatePaymentInfo_Install() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'USD', 'Install', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Single 타입 (새 레코드 생성)
     */
    @IsTest
    static void testUpdatePaymentInfo_Single_NewRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'EUR', 'Single', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> schedules = [
            SELECT Id, PaymentType__c, DaysFromInception__c, Percentage__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, schedules.size(), 'Premium Schedule이 1개 있어야 함');
        System.assertEquals('Single', schedules[0].PaymentType__c, 'Payment Type이 Single이어야 함');
        System.assertEquals(null, schedules[0].DaysFromInception__c, 'DaysFromInception이 null이어야 함');
        System.assertEquals(null, schedules[0].Percentage__c, 'Percentage가 null이어야 함');
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Single 타입 (기존 1개 레코드 업데이트)
     */
    @IsTest
    static void testUpdatePaymentInfo_Single_UpdateExisting() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        OPP_PremiumSchedule__c schedule = (OPP_PremiumSchedule__c) TestDataFactory.createSObject(
            'OPP_PremiumSchedule__c',
        new Map<String, Object>{
            'Opportunity_lk__c' => opp.Id,
            'Prem_Currency__c' => 'EUR',
            'PaymentType__c' => 'SOA',
            'DaysFromInception__c' => 30,
            'Percentage__c' => 50,
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'EUR', 'Single', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> schedules = [
            SELECT Id, PaymentType__c, DaysFromInception__c, Percentage__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, schedules.size(), 'Premium Schedule이 1개 있어야 함');
        System.assertEquals('Single', schedules[0].PaymentType__c, 'Payment Type이 Single로 변경되어야 함');
        System.assertEquals(null, schedules[0].DaysFromInception__c, 'DaysFromInception이 null이어야 함');
        System.assertEquals(null, schedules[0].Percentage__c, 'Percentage가 null이어야 함');
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Single 타입 (여러 레코드를 1개로 축소)
     */
    @IsTest
    static void testUpdatePaymentInfo_Single_ReduceMultiple() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<OPP_PremiumSchedule__c> schedules = new List<OPP_PremiumSchedule__c>();
        for (Integer i = 0; i < 3; i++) {
            schedules.add(
                new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Prem_Currency__c = 'EUR',
            PaymentType__c = 'Install',
            DaysFromInception__c = 30 * i,
            Percentage__c = 33.33,
            OwnerId = UserInfo.getUserId()
                )
                );
        }
        insert schedules;
        
        Integer beforeCount = [
            SELECT COUNT()
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(3, beforeCount, '3개의 레코드가 있어야 함');
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'EUR', 'Single', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> afterSchedules = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, afterSchedules.size(), 'Premium Schedule이 1개로 축소되어야 함');
        System.assertEquals('Single', afterSchedules[0].PaymentType__c, 'Payment Type이 Single이어야 함');
    }
    
    
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - SOA 타입 (여러 레코드를 1개로 축소)
     */
    @IsTest
    static void testUpdatePaymentInfo_SOA_ReduceMultiple() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<OPP_PremiumSchedule__c> schedules = new List<OPP_PremiumSchedule__c>();
        for (Integer i = 0; i < 4; i++) {
            schedules.add(
                new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Prem_Currency__c = 'EUR',
            PaymentType__c = 'Install',
            DaysFromInception__c = 30 * i,
            Percentage__c = 25,
            OwnerId = UserInfo.getUserId()
                )
                );
        }
        insert schedules;
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'EUR', 'SOA', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> afterSchedules = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, afterSchedules.size(), 'Premium Schedule이 1개로 축소되어야 함');
        System.assertEquals('SOA', afterSchedules[0].PaymentType__c, 'Payment Type이 SOA여야 함');
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Declaration 타입 (신규 레코드, Type__c 및 SlipGrossPrem__c 확인)
     *              Declaration은 Placement.TransactionType__c에만 유효한 값이므로 Placement 기반으로 테스트
     */
    @IsTest
    static void testUpdatePaymentInfo_Declaration_NewRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TransactionType__c = 'Declaration',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(placement.Id, 'EUR', 'Single', 1000000.00, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> schedules = [
            SELECT Id, PaymentType__c, SlipGrossPrem__c, Type__c
            FROM OPP_PremiumSchedule__c
            WHERE Placement_lk__c = :placement.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, schedules.size(), 'Premium Schedule이 1개 있어야 함');
        System.assertEquals('Single', schedules[0].PaymentType__c, 'Payment Type이 Single이어야 함');
        System.assertEquals('Declaration', schedules[0].Type__c, 'Type__c가 Declaration이어야 함');
        System.assertEquals(1000000.00, schedules[0].SlipGrossPrem__c, 'SlipGrossPrem__c가 저장되어야 함');
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Declaration 타입 (기존 레코드 업데이트, Type__c 확인)
     *              Declaration은 Placement.TransactionType__c에만 유효한 값이므로 Placement 기반으로 테스트
     */
    @IsTest
    static void testUpdatePaymentInfo_Declaration_UpdateExisting() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TransactionType__c = 'Declaration',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Placement_lk__c = placement.Id,
        Prem_Currency__c = 'EUR',
        PaymentType__c = 'SOA',
        DaysFromInception__c = 30,
        Percentage__c = 50,
        OwnerId = UserInfo.getUserId()
            );
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(placement.Id, 'EUR', 'SOA', 2000000.00, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> schedules = [
            SELECT Id, PaymentType__c, SlipGrossPrem__c, Type__c
            FROM OPP_PremiumSchedule__c
            WHERE Placement_lk__c = :placement.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, schedules.size(), 'Premium Schedule이 1개 있어야 함');
        System.assertEquals('SOA', schedules[0].PaymentType__c, 'Payment Type이 SOA여야 함');
        System.assertEquals('Declaration', schedules[0].Type__c, 'Type__c가 Declaration으로 업데이트되어야 함');
        System.assertEquals(2000000.00, schedules[0].SlipGrossPrem__c, 'SlipGrossPrem__c가 업데이트되어야 함');
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - null recordId
     */
    @IsTest
    static void testUpdatePaymentInfo_NullRecordId() {
        Test.startTest();
        try {
            Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(null, 'USD', 'Single', null, false);
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'AuraHandledException catch 경로 실행 확인: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description updatePaymentInfo 메서드 테스트 - Declaration 타입 GrossPrem 변경 시 NeedRecalculate_is__c = true 설정 (v1.8)
     *              Declaration은 Placement.TransactionType__c에만 유효한 값이므로 Placement 기반으로 테스트
     */
    @IsTest
    static void testUpdatePaymentInfo_Declaration_NeedRecalculate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TransactionType__c = 'Declaration',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Placement_lk__c = placement.Id,
        Prem_Currency__c = 'USD',
        PaymentType__c = 'SOA',
        SlipGrossPrem__c = 500000,
        OwnerId = UserInfo.getUserId()
            );
        
        Test.startTest();
        // GrossPrem을 다른 값으로 저장 → NeedRecalculate_is__c = true
        Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(placement.Id, 'USD', 'SOA', 800000.00, false);
        Test.stopTest();
        
        Opportunity updated = [SELECT NeedRecalculate_is__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updated.NeedRecalculate_is__c, 'GrossPrem 변경 시 NeedRecalculate_is__c가 true여야 함');
    }
    
    // ============================================================
    // ensureSinglePremiumSchedule 안정성 테스트
    // ============================================================
    
    /**
     * @description ensureSinglePremiumSchedule 테스트 - null Opportunity ID
     */
    @IsTest
    static void testEnsureSinglePremiumSchedule_InvalidOpportunityId() {
        Test.startTest();
        try {
            Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(null, 'USD', 'Single', null, false);
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'AuraHandledException catch 경로 실행 확인: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description ensureSinglePremiumSchedule 테스트 - 대량 레코드를 1개로 축소하는 안정성 테스트
     */
    @IsTest
    static void testEnsureSinglePremiumSchedule_MassDelete() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<OPP_PremiumSchedule__c> schedules = new List<OPP_PremiumSchedule__c>();
        for (Integer i = 0; i < 10; i++) {
            schedules.add(
                new OPP_PremiumSchedule__c(
                Opportunity_lk__c = opp.Id,
            Prem_Currency__c = 'GBP',
            PaymentType__c = 'Install',
            DaysFromInception__c = 30 * i,
            Percentage__c = 10,
            OwnerId = UserInfo.getUserId()
                )
                );
        }
        insert schedules;
        
        Integer beforeCount = [
            SELECT COUNT()
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'GBP'
        ];
        System.assertEquals(10, beforeCount, '10개의 레코드가 있어야 함');
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'GBP', 'Single', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> afterSchedules = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'GBP'
        ];
        System.assertEquals(1, afterSchedules.size(), 'Premium Schedule이 1개로 축소되어야 함');
        System.assertEquals('Single', afterSchedules[0].PaymentType__c, 'Payment Type이 Single이어야 함');
    }
    
    /**
     * @description ensureSinglePremiumSchedule 테스트 - 연속 타입 변경 (Single → SOA → Single)
     */
    @IsTest
    static void testEnsureSinglePremiumSchedule_ConsecutiveTypeChanges() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        
        String result1 = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'JPY', 'Single', null, false);
        System.assertNotEquals(null, result1, '첫 번째 결과가 null이 아니어야 함');
        List<OPP_PremiumSchedule__c> schedules1 = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'JPY'
        ];
        System.assertEquals(1, schedules1.size(), 'Single 타입 레코드가 1개여야 함');
        System.assertEquals('Single', schedules1[0].PaymentType__c, 'Payment Type이 Single이어야 함');
        
        String result2 = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'JPY', 'SOA', null, false);
        System.assertNotEquals(null, result2, '두 번째 결과가 null이 아니어야 함');
        List<OPP_PremiumSchedule__c> schedules2 = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'JPY'
        ];
        System.assertEquals(1, schedules2.size(), 'SOA 타입 레코드가 1개여야 함');
        System.assertEquals('SOA', schedules2[0].PaymentType__c, 'Payment Type이 SOA여야 함');
        
        String result3 = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'JPY', 'Single', null, false);
        System.assertNotEquals(null, result3, '세 번째 결과가 null이 아니어야 함');
        List<OPP_PremiumSchedule__c> schedules3 = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'JPY'
        ];
        System.assertEquals(1, schedules3.size(), 'Single 타입 레코드가 1개여야 함');
        System.assertEquals('Single', schedules3[0].PaymentType__c, 'Payment Type이 Single이어야 함');
        
        Test.stopTest();
    }
    
    /**
     * @description ensureSinglePremiumSchedule 테스트 - 동일 Currency 중복 호출 멱등성 확인
     */
    @IsTest
    static void testEnsureSinglePremiumSchedule_IdempotentCalls() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result1 = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'CNY', 'Single', null, false);
        String result2 = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'CNY', 'Single', null, false);
        String result3 = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'CNY', 'Single', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result1, '첫 번째 결과가 null이 아니어야 함');
        System.assertNotEquals(null, result2, '두 번째 결과가 null이 아니어야 함');
        System.assertNotEquals(null, result3, '세 번째 결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> schedules = [
            SELECT Id, PaymentType__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'CNY'
        ];
        System.assertEquals(1, schedules.size(), '중복 호출 후에도 레코드가 1개여야 함');
        System.assertEquals('Single', schedules[0].PaymentType__c, 'Payment Type이 Single이어야 함');
    }
    
    
    
    // ============================================================
    // 권한 테스트
    // ============================================================
    
    // ============================================================
    // filterPaymentTypeOptions / Placement transactionType 테스트 (v2.0)
    // ============================================================
    
    /**
     * @description getInitData - Placement TransactionType=Declaration → paymentTypeOptions에 SOA만 반환
     */
    @IsTest
    static void testGetInitData_Placement_Declaration_SOAOnly() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TransactionType__c = 'Declaration',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(placement.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w.paymentTypeOptions, '옵션이 null이 아니어야 함');
        for (COM_Option opt : w.paymentTypeOptions) {
            System.assertEquals('SOA', opt.value, 'Declaration 타입은 SOA 옵션만 있어야 함');
        }
        System.assert(w.paymentTypeOptions.size() > 0, 'SOA 옵션이 최소 1개 이상 있어야 함');
        System.assertEquals('Declaration', w.transactionType, 'transactionType이 Declaration이어야 함');
    }
    
    /**
     * @description getInitData - Placement TransactionType=END → paymentTypeOptions에 SOA 제외
     */
    @IsTest
    static void testGetInitData_Placement_END_ExcludesSOA() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TransactionType__c = 'END',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(placement.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w.paymentTypeOptions, '옵션이 null이 아니어야 함');
        for (COM_Option opt : w.paymentTypeOptions) {
            System.assertNotEquals('SOA', opt.value, 'END 타입은 SOA 옵션이 없어야 함');
        }
        System.assertEquals('END', w.transactionType, 'transactionType이 END여야 함');
    }
    
    
    // ============================================================
    // hasSoaSchedule → SOA 단일 옵션 제한 테스트 (v2.2)
    // ============================================================
    
    /**
     * @description getInitData - 하위에 SOA 스케줄이 존재하면 paymentTypeOptions를 SOA 단일 옵션으로 제한
     */
    @IsTest
    static void testGetInitData_HasSoaSchedule_LimitsToSOAOnly() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Prem_Currency__c = 'EUR',
        PaymentType__c = 'SOA',
        OwnerId = UserInfo.getUserId()
            );
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w.paymentTypeOptions, '옵션이 null이 아니어야 함');
        for (COM_Option opt : w.paymentTypeOptions) {
            System.assertEquals('SOA', opt.value, 'SOA 스케줄 존재 시 SOA 옵션만 있어야 함');
        }
        System.assert(w.paymentTypeOptions.size() > 0, 'SOA 옵션이 최소 1개 이상 있어야 함');
    }
    
    /**
     * @description getInitData - SOA 스케줄 없으면 전체 옵션 반환
     */
    @IsTest
    static void testGetInitData_NoSoaSchedule_AllOptions() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // USD Install 스케줄만 존재 (setupTestData에서 생성됨), SOA 없음
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.InitDataWrapper w = Opp_PremiumFromCedent_Ctrl.getInitData(opp.Id, 'USD');
        Test.stopTest();
        
        Boolean hasNonSoa = false;
        for (COM_Option opt : w.paymentTypeOptions) {
            if (!'SOA'.equals(opt.value)) {
                hasNonSoa = true;
                break;
            }
        }
        System.assert(hasNonSoa, 'SOA 스케줄 없으면 SOA 외 옵션도 있어야 함');
    }
    
    // ============================================================
    // getSOAChangePreview 테스트 (v2.1)
    // ============================================================
    
    /**
     * @description SOAChangePreviewWrapper 기본값 테스트
     */
    @IsTest
    static void testSOAChangePreviewWrapper_Defaults() {
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.SOAChangePreviewWrapper w = new Opp_PremiumFromCedent_Ctrl.SOAChangePreviewWrapper();
        Test.stopTest();
        
        System.assertNotEquals(null, w.toUpdate, 'toUpdate 기본값은 빈 리스트여야 함');
        System.assertNotEquals(null, w.toDelete, 'toDelete 기본값은 빈 리스트여야 함');
        System.assertEquals(0, w.toUpdate.size(), 'toUpdate 초기 크기는 0이어야 함');
        System.assertEquals(0, w.toDelete.size(), 'toDelete 초기 크기는 0이어야 함');
    }
    
    /**
     * @description getSOAChangePreview - Opportunity 기준 정상 케이스 (첫 번째 → toUpdate, 나머지 → toDelete)
     */
    @IsTest
    static void testGetSOAChangePreview_Opp_MultipleSchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // USD에 Install 스케줄 3개 (setupTestData에서 2개 이미 생성됨)
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Prem_Currency__c = 'USD',
        PaymentType__c = 'Install',
        DaysFromInception__c = 60,
        Percentage__c = 20,
        OwnerId = UserInfo.getUserId()
            );
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.SOAChangePreviewWrapper w = Opp_PremiumFromCedent_Ctrl.getSOAChangePreview(opp.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
        System.assertEquals(1, w.toUpdate.size(), 'USD 첫 번째 레코드만 toUpdate여야 함');
        System.assertEquals(2, w.toDelete.size(), 'USD 나머지 2개가 toDelete여야 함');
    }
    
    /**
     * @description getSOAChangePreview - 이미 SOA인 레코드는 toUpdate에서 제외
     */
    @IsTest
    static void testGetSOAChangePreview_AlreadySOA_ExcludedFromToUpdate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // USD 기존 2개(Install)를 SOA로 변경
        List<OPP_PremiumSchedule__c> schedules = [SELECT Id FROM OPP_PremiumSchedule__c WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'USD' LIMIT 1];
        schedules[0].PaymentType__c = 'SOA';
        update schedules[0];
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.SOAChangePreviewWrapper w = Opp_PremiumFromCedent_Ctrl.getSOAChangePreview(opp.Id, 'USD');
        Test.stopTest();
        
        // 첫 번째 레코드가 이미 SOA → toUpdate에서 제외
        System.assertEquals(0, w.toUpdate.size(), '이미 SOA인 첫 번째 레코드는 toUpdate에서 제외되어야 함');
        System.assertEquals(1, w.toDelete.size(), '두 번째 레코드는 toDelete여야 함');
    }
    
    /**
     * @description getSOAChangePreview - 여러 통화 → 통화별 첫 번째 toUpdate, 나머지 toDelete
     */
    @IsTest
    static void testGetSOAChangePreview_MultipleCurrencies() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // EUR 스케줄 2개 추가
        insert new List<OPP_PremiumSchedule__c>{
            new OPP_PremiumSchedule__c(Opportunity_lk__c = opp.Id, Prem_Currency__c = 'EUR', PaymentType__c = 'Install', DaysFromInception__c = 0, Percentage__c = 50, OwnerId = UserInfo.getUserId()),
            new OPP_PremiumSchedule__c(Opportunity_lk__c = opp.Id, Prem_Currency__c = 'EUR', PaymentType__c = 'Install', DaysFromInception__c = 30, Percentage__c = 50, OwnerId = UserInfo.getUserId())
        };
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.SOAChangePreviewWrapper w = Opp_PremiumFromCedent_Ctrl.getSOAChangePreview(opp.Id, null);
        Test.stopTest();
        
        // USD 2개 중 1→toUpdate, 1→toDelete / EUR 2개 중 1→toUpdate, 1→toDelete
        System.assertEquals(2, w.toUpdate.size(), '통화별 첫 번째 레코드 2건이 toUpdate여야 함');
        System.assertEquals(2, w.toDelete.size(), '통화별 나머지 2건이 toDelete여야 함');
    }
    
    /**
     * @description getSOAChangePreview - Placement 기준 조회
     */
    @IsTest
    static void testGetSOAChangePreview_WithPlacementId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(Opportunity_lk__c = opp.Id, OwnerId = UserInfo.getUserId());
        insert placement;
        
        insert new List<OPP_PremiumSchedule__c>{
            new OPP_PremiumSchedule__c(Opportunity_lk__c = opp.Id, Placement_lk__c = placement.Id, Prem_Currency__c = 'USD', PaymentType__c = 'Install', DaysFromInception__c = 0, Percentage__c = 50, OwnerId = UserInfo.getUserId()),
            new OPP_PremiumSchedule__c(Opportunity_lk__c = opp.Id, Placement_lk__c = placement.Id, Prem_Currency__c = 'USD', PaymentType__c = 'Install', DaysFromInception__c = 30, Percentage__c = 50, OwnerId = UserInfo.getUserId())
        };
        
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.SOAChangePreviewWrapper w = Opp_PremiumFromCedent_Ctrl.getSOAChangePreview(placement.Id, 'USD');
        Test.stopTest();
        
        System.assertNotEquals(null, w, '결과가 null이 아니어야 함');
        System.assertEquals(1, w.toUpdate.size(), 'Placement 기준 첫 번째 레코드가 toUpdate여야 함');
        System.assertEquals(1, w.toDelete.size(), 'Placement 기준 나머지 레코드가 toDelete여야 함');
    }
    
    
    // ============================================================
    // ensureSOAAllCurr 동작 변경 테스트 (v3.1)
    // ============================================================
    
    /**
     * @description ensureSOAAllCurr - 하위 레코드가 전혀 없을 때 targetCurr 기준 1건 신규 생성
     *              Placement 기준으로 테스트 (Opp 기준은 setupTestData USD 레코드가 존재하므로 빈 케이스 아님)
     */
    @IsTest
    static void testUpdatePaymentInfo_SOA_NoRecords_CreatesNewRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(placement.Id, 'USD', 'SOA', 500000.00, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> schedules = [
            SELECT Id, PaymentType__c, SlipGrossPrem__c
            FROM OPP_PremiumSchedule__c
            WHERE Placement_lk__c = :placement.Id AND Prem_Currency__c = 'USD'
        ];
        System.assertEquals(1, schedules.size(), '레코드 없을 때 SOA 저장 시 1건 신규 생성되어야 함');
        System.assertEquals('SOA', schedules[0].PaymentType__c, 'Payment Type이 SOA여야 함');
        System.assertEquals(500000.00, schedules[0].SlipGrossPrem__c, 'SlipGrossPrem__c가 저장되어야 함');
    }
    
    /**
     * @description ensureSOAAllCurr - 기존 레코드에 targetCurr가 없을 때 신규 생성
     *              EUR 레코드가 존재하는 상태에서 GBP로 SOA 저장 → GBP 신규 생성, EUR 유지
     */
    @IsTest
    static void testUpdatePaymentInfo_SOA_TargetCurrNotFound_CreatesNewRecord() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Prem_Currency__c = 'EUR',
        PaymentType__c = 'Install',
        DaysFromInception__c = 0,
        Percentage__c = 100,
        OwnerId = UserInfo.getUserId()
            );
        
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'GBP', 'SOA', 300000.00, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        
        List<OPP_PremiumSchedule__c> gbpSchedules = [
            SELECT Id, PaymentType__c, SlipGrossPrem__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'GBP'
        ];
        System.assertEquals(1, gbpSchedules.size(), 'targetCurr 없을 때 SOA 저장 시 1건 신규 생성되어야 함');
        System.assertEquals('SOA', gbpSchedules[0].PaymentType__c, 'GBP Payment Type이 SOA여야 함');
        System.assertEquals(300000.00, gbpSchedules[0].SlipGrossPrem__c, 'GBP SlipGrossPrem__c가 저장되어야 함');
    }
    
    /**
     * @description ensureSOAAllCurr - 다중 통화 처리 시 targetCurr만 grossPrem 업데이트,
     *              나머지 통화는 기존 SlipGrossPrem__c 값 유지
     */
    @IsTest
    static void testUpdatePaymentInfo_SOA_MultipleCurrencies_OnlyTargetCurrUpdated() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // EUR SOA 레코드 (SlipGrossPrem__c = 200000) 사전 생성
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Prem_Currency__c = 'EUR',
        PaymentType__c = 'SOA',
        SlipGrossPrem__c = 200000,
        OwnerId = UserInfo.getUserId()
            );
        
        // USD로 SOA 저장 (grossPrem = 500000) → USD만 업데이트, EUR SlipGrossPrem__c 유지
        Test.startTest();
        Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(opp.Id, 'USD', 'SOA', 500000.00, false);
        Test.stopTest();
        
        List<OPP_PremiumSchedule__c> usdSchedules = [
            SELECT Id, SlipGrossPrem__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'USD' AND Type__c != 'Slip'
        ];
        System.assertEquals(1, usdSchedules.size(), 'USD 레코드가 1개여야 함');
        System.assertEquals(500000.00, usdSchedules[0].SlipGrossPrem__c, 'USD SlipGrossPrem__c가 업데이트되어야 함');
        
        List<OPP_PremiumSchedule__c> eurSchedules = [
            SELECT Id, SlipGrossPrem__c
            FROM OPP_PremiumSchedule__c
            WHERE Opportunity_lk__c = :opp.Id AND Prem_Currency__c = 'EUR'
        ];
        System.assertEquals(1, eurSchedules.size(), 'EUR 레코드가 1개여야 함');
        System.assertEquals(200000, eurSchedules[0].SlipGrossPrem__c, 'EUR SlipGrossPrem__c는 기존 값이 유지되어야 함');
    }
    
    /**
     * @description ensureSOAAllCurr - Type__c = 'Slip' 레코드는 처리 대상에서 제외
     *              Slip 레코드만 있을 때 allSchedules.isEmpty() = true → 신규 SOA 레코드 생성
     */
    @IsTest
    static void testUpdatePaymentInfo_SOA_SlipTypeExcluded_FromProcessing() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        // Slip 타입만 존재하는 상태
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Placement_lk__c = placement.Id,
        Prem_Currency__c = 'USD',
        PaymentType__c = 'SOA',
        Type__c = 'Slip',
        SlipGrossPrem__c = 999999,
        OwnerId = UserInfo.getUserId()
            );
        
        // Slip 제외 시 레코드 없는 상태 → 신규 SOA 레코드 생성
        Test.startTest();
        String result = Opp_PremiumFromCedent_Ctrl.updatePaymentInfo(placement.Id, 'USD', 'SOA', 100000.00, false);
        Test.stopTest();
        
        List<OPP_PremiumSchedule__c> allSchedules = [
            SELECT Id, Type__c, SlipGrossPrem__c
            FROM OPP_PremiumSchedule__c
            WHERE Placement_lk__c = :placement.Id AND Prem_Currency__c = 'USD'
        ];
        
        Boolean hasSlip = false;
        Boolean hasNewSOA = false;
        for (OPP_PremiumSchedule__c s : allSchedules) {
            if (s.Type__c == 'Slip' && s.SlipGrossPrem__c == 999999) hasSlip = true;
            else if (s.SlipGrossPrem__c == 100000.00) hasNewSOA = true;
        }
        System.assertEquals(true, hasSlip, 'Slip 타입 레코드는 처리 대상 제외로 그대로 존재해야 함');
        System.assertEquals(true, hasNewSOA, 'Slip 제외 후 allSchedules 비어있어 신규 SOA 레코드가 생성되어야 함');
    }
    
    /**
     * @description getSOAChangePreview - null recordId → AuraHandledException
     */
    @IsTest
    static void testGetSOAChangePreview_NullRecordId() {
        Test.startTest();
        try {
            Opp_PremiumFromCedent_Ctrl.getSOAChangePreview(null, 'USD');
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'AuraHandledException catch 경로 실행 확인: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
}