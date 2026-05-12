/**********************************************************************************
 * @filename      : Opp_ProducingCoBroking_Ctrl_ts.cls
 * @projectname   : LK_DEV2
 * @author        : i2max
 * @date          : 2026-02-11
 * @description   : Opp_ProducingCoBroking_Ctrl 클래스의 테스트 클래스
 * @test-class    :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-14      i2max            Create
 * 1.1   2026-01-14      i2max            Fix OwnerId issue
 * 1.2   2026-01-14      i2max            Fix SettlementType picklist values
 * 1.3   2026-01-19      i2max            Improve test coverage to 75%+
 * 1.4   2026-01-19      i2max            Fix TestSetup data isolation issue
 * 2.0   2026-02-11      i2max            Add missing test methods and use TestDataFactory
 * 2.1   2026-03-03      i2max            Add null input test for saveWithReplace
 * 3.0   2026-03-05      i2max            Replace old init tests with getInitData
 * 4.0   2026-03-10      i2max            Reflect structural changes
 * 5.0   2026-03-24      i2max            Sync with current controller
 * 5.2   2026-04-20      ChatGPT          Update method signatures and Placement/Claim logic
 **********************************************************************************/
@IsTest
private class Opp_ProducingCoBroking_Ctrl_ts {
    
    // ─────────────────────────────────────────────────────────────────────────
    // Test Setup
    // ─────────────────────────────────────────────────────────────────────────
    @TestSetup
    static void createTestData() {
        Account acc = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{
            'Name' => 'Test Account',
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Contact con = (Contact) TestDataFactory.createSObject(
            'Contact',
        new Map<String, Object>{
            'LastName' => 'Test Contact',
            'AccountId' => acc.Id,
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Id rtId = getOpportunityRecordTypeId();
        
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Test Opportunity', rtId, true);
        
        // 일반 Producing Co-broker 1건
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'CobrokerName_lk__c' => acc.Id,
            'CobrokerContact_lk__c' => con.Id,
            'SharingPct__c' => 30,
            'LKAdminFeePct__c' => 5,
            'SettlementType__c' => 'Together',
            'Client__c' => true,
            'LKCobroking_is__c' => false,
            'CobrokingType__c' => 'Producing',
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────
    private static Id getOpportunityRecordTypeId() {
        Id rtId = null;
        
        Map<String, Schema.RecordTypeInfo> byDevName =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
        
        if (byDevName != null && byDevName.containsKey('Reinsurance')) {
            rtId = byDevName.get('Reinsurance').getRecordTypeId();
        }
        
        if (rtId == null) {
            for (Schema.RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
                if (rti.isAvailable() && !rti.isMaster()) {
                    rtId = rti.getRecordTypeId();
                    break;
                }
            }
        }
        
        return rtId;
    }
    
    private static Opportunity getAnyOpp() {
        return [SELECT Id, NeedRecalculate_is__c FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];
    }
    
    private static Account getAnyAccount() {
        return [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
    }
    
    private static Contact getAnyContact() {
        return [SELECT Id FROM Contact ORDER BY CreatedDate DESC LIMIT 1];
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getInitData
    // ─────────────────────────────────────────────────────────────────────────
    @IsTest
    static void testGetInitData_Success() {
        Opportunity opp = getAnyOpp();
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper result =
            Opp_ProducingCoBroking_Ctrl.getInitData(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertNotEquals(null, result.coBrokerList, 'coBrokerList가 null이 아니어야 함');
        System.assertEquals(1, result.coBrokerList.size(), 'Co-Broker가 1개 있어야 함');
        System.assertEquals(30, result.coBrokerList[0].SharingPct__c, 'Sharing Pct가 30이어야 함');
        
        System.assertNotEquals(null, result.settlementTypeOptions, 'settlementTypeOptions가 null이 아니어야 함');
        System.assert(result.settlementTypeOptions.size() > 0, '최소 1개 이상의 옵션이 있어야 함');
        
        System.assertEquals(false, result.hasExisting, 'LK Co-broking 레코드가 없어야 함');
        System.assertNotEquals(null, result.existingRecords, 'existingRecords가 null이 아니어야 함');
        
        System.assertEquals(false, result.isPlacement, 'Opportunity 컨텍스트에서는 isPlacement=false');
        System.assertEquals(false, result.isClaim, 'Opportunity 컨텍스트에서는 isClaim=false');
        System.assertNotEquals(null, result.hasEditPermission, 'hasEditPermission은 null이 아니어야 함');
        System.assertEquals(null, result.placementClosingDate, 'Opportunity 컨텍스트에서는 placementClosingDate가 null이어야 함');
    }
    
    @IsTest
    static void testGetInitData_WithExistingLK() {
        Account acc = getAnyAccount();
        Opportunity opp = getAnyOpp();
        
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'CobrokerName_lk__c' => acc.Id,
            'SharingPct__c' => 15,
            'LKAdminFeePct__c' => 10,
            'SettlementType__c' => 'Together',
            'Client__c' => false,
            'LKCobroking_is__c' => true,
            'CobrokingType__c' => 'Producing',
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper result =
            Opp_ProducingCoBroking_Ctrl.getInitData(opp.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.hasExisting, 'LK Co-broking 레코드가 존재해야 함');
        System.assertEquals(1, result.existingRecords.size(), 'LK Co-broking 레코드가 1개 있어야 함');
    }
    
    @IsTest
    static void testGetInitData_NullId() {
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper result =
            Opp_ProducingCoBroking_Ctrl.getInitData(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(0, result.coBrokerList.size(), 'null recordId이면 빈 리스트여야 함');
        System.assertEquals(false, result.hasExisting, 'null recordId이면 hasExisting=false');
        System.assertEquals(false, result.isPlacement, 'null recordId이면 isPlacement=false');
        System.assertEquals(false, result.isClaim, 'null recordId이면 isClaim=false');
        System.assertEquals(false, result.hasEditPermission, 'null recordId이면 hasEditPermission=false');
        System.assertEquals(null, result.placementClosingDate, 'null recordId이면 placementClosingDate=null');
    }
    
    @IsTest
    static void testGetInitData_SettlementTypeOptions() {
        Opportunity opp = getAnyOpp();
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper result =
            Opp_ProducingCoBroking_Ctrl.getInitData(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result.settlementTypeOptions, '옵션이 null이 아니어야 함');
        System.assert(result.settlementTypeOptions.size() > 0, '최소 1개 이상의 옵션이 있어야 함');
        
        Boolean hasNone = false;
        for (COM_Option opt : result.settlementTypeOptions) {
            if (opt.label == '--None--') {
                hasNone = true;
                System.assertEquals('', opt.value, '--None-- 옵션의 값은 빈 문자열이어야 함');
                break;
            }
        }
        System.assert(hasNone, '--None-- 옵션이 있어야 함');
        
        Schema.DescribeFieldResult field = OPP_Cobroker__c.SettlementType__c.getDescribe();
        Integer activeCount = 0;
        for (Schema.PicklistEntry entry : field.getPicklistValues()) {
            if (entry.isActive()) {
                activeCount++;
            }
        }
        System.assertEquals(
            activeCount + 1,
        result.settlementTypeOptions.size(),
        '활성화된 picklist 값 + --None-- = 전체 옵션 수'
            );
    }
    
    @IsTest
    static void testGetInitData_PlacementContext() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        Date closingDate = Date.today().addDays(10);
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId(),
        PlacementClosingDate__c = closingDate
            );
        insert placement;
        
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'Placement_lk__c' => placement.Id,
            'CobrokerName_lk__c' => acc.Id,
            'CobrokerContact_lk__c' => con.Id,
            'SharingPct__c' => 25,
            'LKAdminFeePct__c' => 5,
            'SettlementType__c' => 'Together',
            'Client__c' => true,
            'LKCobroking_is__c' => false,
            'CobrokingType__c' => 'Producing',
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper result =
            Opp_ProducingCoBroking_Ctrl.getInitData(placement.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(true, result.isPlacement, 'Placement이면 isPlacement=true');
        System.assertEquals(false, result.isClaim, 'Placement이면 isClaim=false');
        System.assertNotEquals(null, result.hasEditPermission, 'Placement hasEditPermission은 null이 아니어야 함');
        System.assertEquals(1, result.coBrokerList.size(), 'Placement 기준 1개 Co-Broker가 있어야 함');
        System.assertEquals(25, result.coBrokerList[0].SharingPct__c, 'SharingPct__c가 25여야 함');
        System.assertEquals(closingDate, result.placementClosingDate, 'Placement closing date가 반환되어야 함');
    }
    
    @IsTest
    static void testGetInitData_ClaimContext() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        Date closingDate = Date.today().addDays(20);
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId(),
        PlacementClosingDate__c = closingDate
            );
        insert placement;
        
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'Placement_lk__c' => placement.Id,
            'CobrokerName_lk__c' => acc.Id,
            'CobrokerContact_lk__c' => con.Id,
            'SharingPct__c' => 30,
            'LKAdminFeePct__c' => 3,
            'SettlementType__c' => 'Separate',
            'Client__c' => false,
            'LKCobroking_is__c' => false,
            'CobrokingType__c' => 'Producing',
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        
        Claim claim = new Claim(
            Name = 'TEST-CLM-PRODUCING',
        Placement_lk__c = placement.Id
            );
        insert claim;
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper result =
            Opp_ProducingCoBroking_Ctrl.getInitData(claim.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, '결과가 null이 아니어야 함');
        System.assertEquals(false, result.isPlacement, 'Claim이면 isPlacement=false');
        System.assertEquals(true, result.isClaim, 'Claim이면 isClaim=true');
        System.assertEquals(false, result.hasEditPermission, 'Claim 컨텍스트는 편집 권한 없음');
        System.assertEquals(1, result.coBrokerList.size(), 'Placement 기준 1개 Co-Broker가 있어야 함');
        System.assertEquals(30, result.coBrokerList[0].SharingPct__c, 'SharingPct__c가 30이어야 함');
        System.assertEquals(closingDate, result.placementClosingDate, 'Claim 경유 시 placement closing date가 반환되어야 함');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Wrapper
    // ─────────────────────────────────────────────────────────────────────────
    @IsTest
    static void testInitDataWrapper_Initialization() {
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.InitDataWrapper wrapper =
            new Opp_ProducingCoBroking_Ctrl.InitDataWrapper();
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper.coBrokerList, 'coBrokerList should initialize to empty list');
        System.assertEquals(0, wrapper.coBrokerList.size(), 'coBrokerList should be empty');
        System.assertNotEquals(null, wrapper.settlementTypeOptions, 'settlementTypeOptions should initialize to empty list');
        System.assertEquals(0, wrapper.settlementTypeOptions.size(), 'settlementTypeOptions should be empty');
        System.assertEquals(false, wrapper.hasExisting, 'hasExisting should initialize to false');
        System.assertNotEquals(null, wrapper.existingRecords, 'existingRecords should initialize to empty list');
        System.assertEquals(0, wrapper.existingRecords.size(), 'existingRecords should be empty');
        System.assertEquals(false, wrapper.isPlacement, 'isPlacement should initialize to false');
        System.assertEquals(false, wrapper.isClaim, 'isClaim should initialize to false');
        System.assertEquals(false, wrapper.hasEditPermission, 'hasEditPermission should initialize to false');
        System.assertEquals(null, wrapper.placementClosingDate, 'placementClosingDate should initialize to null');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // saveWithReplace
    // ─────────────────────────────────────────────────────────────────────────
    @IsTest
    static void testSaveWithReplace_Success() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'CobrokerName_lk__c' => acc.Id,
            'SharingPct__c' => 15,
            'LKCobroking_is__c' => true,
            'CobrokingType__c' => 'Producing',
            'Client__c' => false,
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        
        Integer beforeCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = TRUE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(1, beforeCount, 'LK Co-broking이 1개 있어야 함');
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 20,
        LKAdminFeePct__c = 8,
        SettlementType__c = 'Together',
        Client__c = true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveWithReplace(
        new List<OPP_Cobroker__c>{ newCoBroker },
        opp.Id,
        null,
        false
            );
        Test.stopTest();
        
        Integer afterLKCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = TRUE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(0, afterLKCount, '기존 LK Co-broking이 삭제되어야 함');
        
        Integer totalNonLKCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(2, totalNonLKCount, '기존 1개 + 새로 추가된 1개 = 2개여야 함');
    }
    
    @IsTest
    static void testSaveWithReplace_EmptyList() {
        Opportunity opp = getAnyOpp();
        
        Test.startTest();
        try {
            Opp_ProducingCoBroking_Ctrl.saveWithReplace(
                new List<OPP_Cobroker__c>(),
            opp.Id,
            null,
            false
                );
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
            'AuraHandledException catch 경로 실행 확인: ' + e.getMessage()
                );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSaveWithReplace_NullInput() {
        Opportunity opp = getAnyOpp();
        
        Test.startTest();
        try {
            Opp_ProducingCoBroking_Ctrl.saveWithReplace(
                null,
            opp.Id,
            null,
            false
                );
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
            'AuraHandledException catch 경로 실행 확인: ' + e.getMessage()
                );
        }
        Test.stopTest();
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // saveCoBrokers
    // ─────────────────────────────────────────────────────────────────────────
    @IsTest
    static void testSaveCoBrokers_Insert() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 20,
        LKAdminFeePct__c = 7,
        SettlementType__c = 'Together',
        Client__c = true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ newCoBroker },
        opp.Id,
        null,
        false
            );
        Test.stopTest();
        
        Integer count = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(2, count, '기존 1개 + 새로 추가된 1개 = 2개여야 함');
    }
    
    @IsTest
    static void testSaveCoBrokers_Update() {
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c existingCoBroker = [
            SELECT Id, CobrokerName_lk__c, CobrokerContact_lk__c, SharingPct__c, LKAdminFeePct__c, SettlementType__c, Client__c
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        existingCoBroker.SharingPct__c = 50;
        existingCoBroker.SettlementType__c = 'Separate';
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ existingCoBroker },
        opp.Id,
        null,
        false
            );
        Test.stopTest();
        
        OPP_Cobroker__c updated = [
            SELECT SharingPct__c, SettlementType__c
            FROM OPP_Cobroker__c
            WHERE Id = :existingCoBroker.Id
        ];
        System.assertEquals(50, updated.SharingPct__c, 'Sharing Pct가 업데이트되어야 함');
        System.assertEquals('Separate', updated.SettlementType__c, 'SettlementType도 업데이트되어야 함');
    }
    
    @IsTest
    static void testSaveCoBrokers_NullValues() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = null,
        LKAdminFeePct__c = null,
        SettlementType__c = 'Together'
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ newCoBroker },
        opp.Id,
        null,
        false
            );
        Test.stopTest();
        
        List<OPP_Cobroker__c> allRecords = [
            SELECT SharingPct__c, LKAdminFeePct__c
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
            ORDER BY CreatedDate DESC
        ];
        System.assertEquals(0, allRecords[0].SharingPct__c, 'null은 0으로 변환되어야 함');
        System.assertEquals(0, allRecords[0].LKAdminFeePct__c, 'null은 0으로 변환되어야 함');
    }
    
    @IsTest
    static void testSaveCoBrokers_InvalidInput() {
        Opportunity opp = getAnyOpp();
        
        Test.startTest();
        
        try {
            Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
                null,
            opp.Id,
            null,
            false
                );
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(true, '예외가 정상적으로 발생함');
        }
        
        try {
            Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
                new List<OPP_Cobroker__c>(),
            opp.Id,
            null,
            false
                );
            System.assert(false, '예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(true, '예외가 정상적으로 발생함');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSaveCoBrokers_Multiple() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c existing = [
            SELECT Id, SharingPct__c, CobrokerName_lk__c, CobrokerContact_lk__c, LKAdminFeePct__c, SettlementType__c, Client__c
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        existing.SharingPct__c = 40;
        
        OPP_Cobroker__c newRecord = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 25,
        SettlementType__c = 'Separate'
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ existing, newRecord },
        opp.Id,
        null,
        false
            );
        Test.stopTest();
        
        Integer count = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(2, count, '2개의 Co-Broker가 있어야 함');
    }
    
    @IsTest
    static void testSaveCoBrokers_DmlError() {
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c invalidRecord = new OPP_Cobroker__c(
            CobrokerName_lk__c = '001000000000000AAA',
        SharingPct__c = 20,
        SettlementType__c = 'Together',
        Client__c = true
            );
        
        Test.startTest();
        try {
            Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
            new List<OPP_Cobroker__c>{ invalidRecord },
            opp.Id,
            null,
            false
                );
            System.assert(false, 'DML 예외가 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
            'AuraHandledException catch 경로 실행 확인: ' + e.getMessage()
                );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSaveCoBrokers_DmlExceptionCatch() {
        Account acc = getAnyAccount();
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c tempRecord = (OPP_Cobroker__c) TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'CobrokerName_lk__c' => acc.Id,
            'SharingPct__c' => 10,
            'SettlementType__c' => 'Together',
            'LKCobroking_is__c' => false,
            'CobrokingType__c' => 'Producing',
            'Client__c' => false,
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        Id deletedId = tempRecord.Id;
        delete tempRecord;
        
        OPP_Cobroker__c recordWithDeletedId = new OPP_Cobroker__c(
            Id = deletedId,
        CobrokerName_lk__c = acc.Id,
        SharingPct__c = 10,
        SettlementType__c = 'Together'
            );
        
        Test.startTest();
        try {
            Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
            new List<OPP_Cobroker__c>{ recordWithDeletedId },
            opp.Id,
            null,
            false
                );
            System.assert(false, 'DmlException이 발생해야 함');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Script-thrown exception'),
            'DmlException catch 경로 실행 확인: ' + e.getMessage()
                );
        }
        Test.stopTest();
    }
    
    // Placement 경로 커버
    @IsTest
    static void testSaveCoBrokers_PlacementContext() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 11,
        LKAdminFeePct__c = 2,
        SettlementType__c = 'Together',
        Client__c = true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ newCoBroker },
        null,
        placement.Id,
        false
            );
        Test.stopTest();
        
        OPP_Cobroker__c insertedCb = [
            SELECT Opportunity_md__c, Placement_lk__c, LKCobroking_is__c, CobrokingType__c
            FROM OPP_Cobroker__c
            WHERE Placement_lk__c = :placement.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        System.assertEquals(placement.Id, insertedCb.Placement_lk__c, 'Placement_lk__c가 세팅되어야 함');
        System.assertEquals(opp.Id, insertedCb.Opportunity_md__c, 'Placement에서 Opportunity를 따라가 세팅해야 함');
        System.assertEquals(false, insertedCb.LKCobroking_is__c, 'LKCobroking_is__c는 false여야 함');
        System.assertEquals('Producing', insertedCb.CobrokingType__c, 'CobrokingType__c는 Producing이어야 함');
    }
    
    @IsTest
    static void testSaveWithReplace_PlacementContext() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'Placement_lk__c' => placement.Id,
            'CobrokerName_lk__c' => acc.Id,
            'SharingPct__c' => 9,
            'LKCobroking_is__c' => true,
            'CobrokingType__c' => 'Producing',
            'Client__c' => false,
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 33,
        SettlementType__c = 'Separate',
        Client__c = true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveWithReplace(
        new List<OPP_Cobroker__c>{ newCoBroker },
        null,
        placement.Id,
        false
            );
        Test.stopTest();
        
        Integer lkCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Placement_lk__c = :placement.Id
              AND LKCobroking_is__c = TRUE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(0, lkCount, 'Placement 기준 기존 LK record가 삭제되어야 함');
        
        Integer nonLkCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Placement_lk__c = :placement.Id
              AND LKCobroking_is__c = FALSE
              AND CobrokingType__c = 'Producing'
        ];
        System.assertEquals(1, nonLkCount, '새 non-LK record가 1개 저장되어야 함');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // deleteCoBrokers
    // ─────────────────────────────────────────────────────────────────────────
    @IsTest
    static void testDeleteCoBrokers_Success() {
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c coBroker = [
            SELECT Id
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.deleteCoBrokers(
        new List<Id>{ coBroker.Id },
        opp.Id,
        null
            );
        Test.stopTest();
        
        List<OPP_Cobroker__c> deleted = [
            SELECT Id
            FROM OPP_Cobroker__c
            WHERE Id = :coBroker.Id
        ];
        System.assertEquals(0, deleted.size(), '레코드가 삭제되어야 함');
    }
    
    @IsTest
    static void testDeleteCoBrokers_InvalidInput() {
        Opportunity opp = getAnyOpp();
        
        Integer beforeCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
        ];
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.deleteCoBrokers(null, opp.Id, null);
        Opp_ProducingCoBroking_Ctrl.deleteCoBrokers(new List<Id>(), opp.Id, null);
        Test.stopTest();
        
        Integer afterCount = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
        ];
        System.assertEquals(beforeCount, afterCount, '레코드가 삭제되지 않아야 함');
    }
    
    @IsTest
    static void testDeleteCoBrokers_Multiple() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        TestDataFactory.createSObject(
            'OPP_Cobroker__c',
        new Map<String, Object>{
            'Opportunity_md__c' => opp.Id,
            'CobrokerName_lk__c' => acc.Id,
            'CobrokerContact_lk__c' => con.Id,
            'SharingPct__c' => 20,
            'LKCobroking_is__c' => false,
            'CobrokingType__c' => 'Producing',
            'Client__c' => true,
            'SharingBrkgAdj_is__c' => false,
            'Sharing_is__c' => false
        },
        true
            );
        
        List<OPP_Cobroker__c> all = [
            SELECT Id
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
        ];
        System.assertEquals(2, all.size(), '2개의 레코드가 있어야 함');
        
        List<Id> ids = new List<Id>();
        for (OPP_Cobroker__c cb : all) {
            ids.add(cb.Id);
        }
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.deleteCoBrokers(ids, opp.Id, null);
        Test.stopTest();
        
        Integer remaining = [
            SELECT COUNT()
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
        ];
        System.assertEquals(0, remaining, '모든 레코드가 삭제되어야 함');
    }
    
    @IsTest
    static void testDeleteCoBrokers_ExceptionCatch() {
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c coBroker = [
            SELECT Id
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :opp.Id
              AND LKCobroking_is__c = FALSE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        User restrictedUser = (User) TestDataFactory.createSObject(
            'User',
        new Map<String, Object>{
            'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            'LastName' => 'RestrictedDeleteTest',
            'Email' => 'restricted_producing_del_test@test.com',
            'Username' => 'restricted_producing_del_test@test.com.testorg',
            'Alias' => 'rpdtst',
            'TimeZoneSidKey' => 'America/Los_Angeles',
            'LocaleSidKey' => 'en_US',
            'EmailEncodingKey' => 'UTF-8',
            'LanguageLocaleKey' => 'en_US'
        },
        true
            );
        
        Test.startTest();
        System.runAs(restrictedUser) {
            try {
                Opp_ProducingCoBroking_Ctrl.deleteCoBrokers(
                new List<Id>{ coBroker.Id },
                opp.Id,
                null
                    );
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('Script-thrown exception'),
                'Exception catch 경로 실행 확인: ' + e.getMessage()
                    );
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetInitData_ExceptionCatch() {
        Opportunity opp = getAnyOpp();
        
        User restrictedUser = (User) TestDataFactory.createSObject(
            'User',
        new Map<String, Object>{
            'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            'LastName' => 'RestrictedTest',
            'Email' => 'restricted_producing_test@test.com',
            'Username' => 'restricted_producing_test@test.com.testorg',
            'Alias' => 'rptst',
            'TimeZoneSidKey' => 'America/Los_Angeles',
            'LocaleSidKey' => 'en_US',
            'EmailEncodingKey' => 'UTF-8',
            'LanguageLocaleKey' => 'en_US'
        },
        true
            );
        
        Test.startTest();
        System.runAs(restrictedUser) {
            try {
                Opp_ProducingCoBroking_Ctrl.getInitData(opp.Id);
            } catch (AuraHandledException e) {
                System.assert(
                    e.getMessage().contains('Script-thrown exception'),
                'Exception catch 경로 실행 확인: ' + e.getMessage()
                    );
            }
        }
        Test.stopTest();
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // needsRecalculate
    // ─────────────────────────────────────────────────────────────────────────
    @IsTest
    static void testSaveCoBrokers_NeedRecalculate() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 25,
        LKAdminFeePct__c = 5,
        SettlementType__c = 'Together',
        Client__c = true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ newCoBroker },
        opp.Id,
        null,
        true
            );
        Test.stopTest();
        
        Opportunity updated = [
            SELECT NeedRecalculate_is__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(true, updated.NeedRecalculate_is__c, 'needsRecalculate=true 시 true여야 함');
    }
    
    @IsTest
    static void testSaveCoBrokers_Placement_NoNeedRecalculateUpdate() {
        Account acc = getAnyAccount();
        Contact con = getAnyContact();
        Opportunity opp = getAnyOpp();
        
        update new Opportunity(Id = opp.Id, NeedRecalculate_is__c = false);
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_Cobroker__c newCoBroker = new OPP_Cobroker__c(
            CobrokerName_lk__c = acc.Id,
        CobrokerContact_lk__c = con.Id,
        SharingPct__c = 12,
        LKAdminFeePct__c = 1,
        SettlementType__c = 'Together',
        Client__c = true
            );
        
        Test.startTest();
        Opp_ProducingCoBroking_Ctrl.saveCoBrokers(
        new List<OPP_Cobroker__c>{ newCoBroker },
        null,
        placement.Id,
        true
            );
        Test.stopTest();
        
        Opportunity refreshed = [
            SELECT NeedRecalculate_is__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(false, refreshed.NeedRecalculate_is__c, 'Placement 경로에서는 NeedRecalculate를 건드리지 않아야 함');
    }
}