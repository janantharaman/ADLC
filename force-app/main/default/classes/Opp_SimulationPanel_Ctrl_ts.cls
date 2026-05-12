/**********************************************************************************
 * @filename      : Opp_SimulationPanel_Ctrl_ts.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-02-15
 * @description   : Test class for Opp_SimulationPanel_Ctrl
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-15      i2max              Create
 **********************************************************************************/
@IsTest
private class Opp_SimulationPanel_Ctrl_ts {
    /**
     * @description 공통 테스트 데이터 설정: Account, Facility, Opportunity, Layer, Panel 생성
     */
    @TestSetup
    static void setupTestData() {
        //User 조회 (OwnerId용)
        User testUser = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];
        // Account 생성
        Account testAccount = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Test Account', 'OwnerId' => testUser.Id },
        true
            );
        
        // COM_Facility__c 생성 (InsuredGroup_lk__c용)
        COM_Facility__c facility = new COM_Facility__c(Name = 'Test Facility', UY__c = '2024');
        insert facility;
        
        // RecordType 조회
        Id rtId = null;
        for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
            if (rti.isAvailable() && !rti.isMaster() && rti.getName() == 'Reinsurance') {
                rtId = rti.getRecordTypeId();
                break;
            }
        }
        
        if (rtId == null) {
            for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
                if (rti.isAvailable() && !rti.isMaster()) {
                    rtId = rti.getRecordTypeId();
                    break;
                }
            }
        }
        
        // Opportunity 생성
        Opportunity testOpp = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opportunity',
        rtId,
        false
            );
        testOpp.TotalOrderPct__c = 80.00;
        testOpp.InsuredGroup_lk__c = facility.Id;
        insert testOpp;
        
        // Layer 생성
        OPP_Layer__c layer1 = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        insert layer1;
        
        OPP_Layer__c layer2 = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Excess',
        Excess__c = 1000000,
        LOL__c = 500000
            );
        insert layer2;
        
        OPP_Layer__c layer3 = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'EUR',
        Type__c = 'QS',
        Excess__c = 0,
        LOL__c = 2000000
            );
        insert layer3;
        
        // ACC_AdditionalInfo__c 생성 (Security_lk__c용)
        ACC_AdditionalInfo__c security = new ACC_AdditionalInfo__c(
            Reinsurer_lk__c = testAccount.Id,
        ActiveSecurity_is__c = true,
        Status__c = 'Approved'
            );
        insert security;
        
        // Panel 생성
        List<OPP_Panel__c> panels = new List<OPP_Panel__c>();
        
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = layer1.Id,
        Finalize_is__c = true,
        MarketType__c = 'Open Market',
        Written__c = 50.00,
        NetToLKPrem__c = 100000,
        TotalBrkgPct__c = 2.5,
        GrossPrem__c = 102500,
        Reinsurer_lk__c = testAccount.Id,
        Leader_is__c = true,
        Security_lk__c = security.Id,
        Signed__c = 50.00,
        Currency__c = 'USD'
            )
            );
        
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = layer1.Id,
        Finalize_is__c = false,
        MarketType__c = 'Facility',
        Written__c = 30.00,
        NetToLKPrem__c = 60000,
        TotalBrkgPct__c = 3.0,
        GrossPrem__c = 61800,
        Facility_lk__c = facility.Id,
        Leader_is__c = false,
        Signed__c = 0,
        Currency__c = 'USD'
            )
            );
        
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = layer2.Id,
        Finalize_is__c = true,
        MarketType__c = 'MGA',
        Written__c = 80.00,
        NetToLKPrem__c = 200000,
        TotalBrkgPct__c = 1.5,
        GrossPrem__c = 203000,
        MGAName_lk__c = testAccount.Id,
        Leader_is__c = false,
        Signed__c = 80.00,
        Currency__c = 'USD'
            )
            );
        
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = layer3.Id,
        Finalize_is__c = false,
        MarketType__c = 'Open Market',
        Written__c = 100.00,
        NetToLKPrem__c = 300000,
        TotalBrkgPct__c = 2.0,
        GrossPrem__c = 306000,
        Reinsurer_lk__c = testAccount.Id,
        Leader_is__c = true,
        Security_lk__c = security.Id,
        Signed__c = 100.00,
        Currency__c = 'EUR'
            )
            );
        
        insert panels;
    }
    
    /**
     * @description Test getSelectedPanelData with valid panel IDs
     */
    @IsTest
    static void testGetSelectedPanelData_Success() {
        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c LIMIT 2];
        List<Id> panelIds = new List<Id>();
        for (OPP_Panel__c p : panels) {
            panelIds.add(p.Id);
        }
        
        Test.startTest();
        List<Opp_SimulationPanel_Ctrl.PanelWrapper> result = Opp_SimulationPanel_Ctrl.getSelectedPanelData(
            panelIds
            );
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return 2 panels');
    }
    
    /**
     * @description Test getSelectedPanelData with empty panel IDs
     */
    @IsTest
    static void testGetSelectedPanelData_EmptyIds() {
        Test.startTest();
        List<Opp_SimulationPanel_Ctrl.PanelWrapper> result = Opp_SimulationPanel_Ctrl.getSelectedPanelData(
            new List<Id>()
            );
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list');
    }
    
    /**
     * @description Test getSelectedPanelData wrapper extended fields
     */
    @IsTest
    static void testGetSelectedPanelData_ExtendedFields() {
        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c LIMIT 1];
        List<Id> panelIds = new List<Id>{ panels[0].Id };
        
        Test.startTest();
        List<Opp_SimulationPanel_Ctrl.PanelWrapper> result = Opp_SimulationPanel_Ctrl.getSelectedPanelData(
            panelIds
            );
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return 1 panel');
        Opp_SimulationPanel_Ctrl.PanelWrapper wrapper = result[0];
        System.assertNotEquals(null, wrapper.layerId, 'Layer ID should not be null');
        System.assertNotEquals(null, wrapper.lol, 'LOL should not be null');
        System.assertNotEquals(null, wrapper.excess, 'Excess should not be null');
        System.assertNotEquals(null, wrapper.totalOrderPct, 'Total Order Pct should not be null');
    }
    
    
    /**
     * @description Test updatePanelFinalize with null panel IDs - AuraHandledException 발생 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_NullPanelIds() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            Opp_SimulationPanel_Ctrl.updatePanelFinalize(null, testOpp.Id, 'USD', null, null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test updatePanelFinalize with empty panel IDs - AuraHandledException 발생 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_EmptyPanelIds() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            Opp_SimulationPanel_Ctrl.updatePanelFinalize(
                new List<Id>(),
            testOpp.Id,
            'USD',
            null,
            null
                );
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test updatePanelFinalize with blank Opportunity ID - AuraHandledException 발생 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_BlankOppId() {
        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c LIMIT 1];
        List<Id> panelIds = new List<Id>{ panels[0].Id };
        
        Test.startTest();
        try {
            Opp_SimulationPanel_Ctrl.updatePanelFinalize(panelIds, null, 'USD', null, null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test updatePanelFinalize with blank currency - AuraHandledException 발생 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_BlankCurrency() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c LIMIT 1];
        List<Id> panelIds = new List<Id>{ panels[0].Id };
        
        Test.startTest();
        try {
            Opp_SimulationPanel_Ctrl.updatePanelFinalize(panelIds, testOpp.Id, null, null, null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    
    /**
     * @description Test updatePanelFinalize with existing Brkg Adj Panel - upsert 시 중복 생성 방지 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_BrkgAdjUpdate() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c WHERE Currency__c = 'USD' LIMIT 1];
        List<Id> panelIds = new List<Id>{ panels[0].Id };
        
        // First call to create Brkg Adj
        Opp_SimulationPanel_Ctrl.updatePanelFinalize(panelIds, testOpp.Id, 'USD', null, null);
        
        Test.startTest();
        // Second call should update existing Brkg Adj (not create duplicate)
        Opp_SimulationPanel_Ctrl.updatePanelFinalize(panelIds, testOpp.Id, 'USD', null, null);
        Test.stopTest();
        
        List<OPP_Layer__c> brkgLayers = [
            SELECT Id
            FROM OPP_Layer__c
            WHERE Opportunity_md__c = :testOpp.Id AND Type__c = 'Brkg Adj'
        ];
        System.assertEquals(1, brkgLayers.size(), 'Should still have only one Brkg Adj layer');
    }
    
    /**
     * @description Test updatePanelFinalize - qsLol 파라미터로 QS Layer의 LOL__c가 갱신되는지 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_WithQsLol() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_Layer__c qsLayer = [
            SELECT Id
            FROM OPP_Layer__c
            WHERE Opportunity_md__c = :testOpp.Id AND Type__c = 'QS'
            LIMIT 1
        ];
        List<OPP_Panel__c> qsPanels = [SELECT Id FROM OPP_Panel__c WHERE Layer_md__c = :qsLayer.Id];
        List<Id> panelIds = new List<Id>();
        for (OPP_Panel__c p : qsPanels) {
            panelIds.add(p.Id);
        }
        
        Decimal newQsLol = 3000000;
        
        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.updatePanelFinalize(
            panelIds,
        testOpp.Id,
        'EUR',
        newQsLol,
        null
            );
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true');
        
        OPP_Layer__c updatedLayer = [SELECT LOL__c FROM OPP_Layer__c WHERE Id = :qsLayer.Id];
        System.assertEquals(
            newQsLol,
        updatedLayer.LOL__c,
        'QS Layer LOL__c should be updated to qsLol value'
            );
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getIsTreaty
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description getIsTreaty - null ID 전달 시 false 반환 확인
     */
    @IsTest
    static void testGetIsTreaty_NullId() {
        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.getIsTreaty(null);
        Test.stopTest();

        System.assertEquals(false, result, 'null ID should return false');
    }

    /**
     * @description getIsTreaty - Opportunity.CedingType1__c = 'Treaty'이면 true 반환 확인
     */
    @IsTest
    static void testGetIsTreaty_Opportunity_Treaty() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        testOpp.CedingType1__c = 'Treaty';
        update testOpp;

        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.getIsTreaty(testOpp.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Opportunity with CedingType1__c = Treaty should return true');
    }

    /**
     * @description getIsTreaty - Opportunity.CedingType1__c != 'Treaty'이면 false 반환 확인
     */
    @IsTest
    static void testGetIsTreaty_Opportunity_NonTreaty() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        // CedingType1__c는 기본값(null 또는 Treaty가 아닌 값) → false

        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.getIsTreaty(testOpp.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Opportunity without Treaty should return false');
    }

    /**
     * @description getIsTreaty - Placement.CedingType1__c = 'Treaty'이면 true 반환 확인
     */
    @IsTest
    static void testGetIsTreaty_Placement_Treaty() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = testOpp.Id,
            CedingType1__c = 'Treaty',
            OwnerId = UserInfo.getUserId()
        );
        insert placement;

        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.getIsTreaty(placement.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Placement with CedingType1__c = Treaty should return true');
    }

    /**
     * @description getIsTreaty - Placement.CedingType1__c != 'Treaty'이면 false 반환 확인
     */
    @IsTest
    static void testGetIsTreaty_Placement_NonTreaty() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = testOpp.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert placement;

        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.getIsTreaty(placement.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Placement without Treaty should return false');
    }

    /**
     * @description Test updatePanelFinalize - brkgAdjData PanelWrapper 값이 BrkgAdj Panel 필드에 저장되는지 확인
     */
    @IsTest
    static void testUpdatePanelFinalize_WithBrkgAdjData() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c WHERE Currency__c = 'USD' LIMIT 1];
        List<Id> panelIds = new List<Id>{ panels[0].Id };
        
        // brkgAdjData 구성
        Opp_SimulationPanel_Ctrl.PanelWrapper brkgAdjData = new Opp_SimulationPanel_Ctrl.PanelWrapper();
        brkgAdjData.totalBrkg = 50000;
        brkgAdjData.netToLKPrem = 200000;
        brkgAdjData.lkReBrkge = 10000;
        brkgAdjData.producingTPPBrkg = 5000;
        brkgAdjData.placingTPPBrkge = 3000;
        brkgAdjData.lkProducingTPPBrkg = 4000;
        brkgAdjData.lkPlacingTPPBrkg = 2000;
        brkgAdjData.netToUW = 150000;
        brkgAdjData.netToProducingCoBroker = 20000;
        brkgAdjData.adminFeeToProducing = 1000;
        brkgAdjData.adminFeeToLK = 500;
        brkgAdjData.netRI = 170000;
        
        Test.startTest();
        Boolean result = Opp_SimulationPanel_Ctrl.updatePanelFinalize(
            panelIds,
        testOpp.Id,
        'USD',
        null,
        brkgAdjData
            );
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true');
        
        List<OPP_Layer__c> brkgLayers = [
            SELECT Id
            FROM OPP_Layer__c
            WHERE Opportunity_md__c = :testOpp.Id AND Type__c = 'Brkg Adj'
        ];
        System.assertEquals(1, brkgLayers.size(), 'Should have one Brkg Adj layer');
        
        OPP_Panel__c brkgPanel = [
            SELECT
                TotalBrkg__c,
                NetToLKPrem__c,
                LKReBrkge__c,
                ProducingTPPBrkg__c,
                PlacingTPPBrkge__c,
                LKProducingTPPBrkg__c,
                LKPlacingTPPBrkg__c,
                NetToUW__c,
                NetProducingCobrker__c,
                ToProducingAdminFee__c,
                ToLKAdminFee__c,
                NetRI__c
            FROM OPP_Panel__c
            WHERE Layer_md__c = :brkgLayers[0].Id
            ];
        System.assertEquals(
            50000,
        brkgPanel.TotalBrkg__c,
        'TotalBrkg__c should match brkgAdjData.totalBrkg'
            );
        System.assertEquals(
            200000,
        brkgPanel.NetToLKPrem__c,
        'NetToLKPrem__c should match brkgAdjData.netToLKPrem'
            );
        System.assertEquals(
            10000,
        brkgPanel.LKReBrkge__c,
        'LKReBrkge__c should match brkgAdjData.lkReBrkge'
            );
        System.assertEquals(
            5000,
        brkgPanel.ProducingTPPBrkg__c,
        'ProducingTPPBrkg__c should match brkgAdjData.producingTPPBrkg'
            );
        System.assertEquals(
            3000,
        brkgPanel.PlacingTPPBrkge__c,
        'PlacingTPPBrkge__c should match brkgAdjData.placingTPPBrkge'
            );
        System.assertEquals(
            4000,
        brkgPanel.LKProducingTPPBrkg__c,
        'LKProducingTPPBrkg__c should match brkgAdjData.lkProducingTPPBrkg'
            );
        System.assertEquals(
            2000,
        brkgPanel.LKPlacingTPPBrkg__c,
        'LKPlacingTPPBrkg__c should match brkgAdjData.lkPlacingTPPBrkg'
            );
        System.assertEquals(
            150000,
        brkgPanel.NetToUW__c,
        'NetToUW__c should match brkgAdjData.netToUW'
            );
        System.assertEquals(
            20000,
        brkgPanel.NetProducingCobrker__c,
        'NetProducingCobrker__c should match brkgAdjData.netToProducingCoBroker'
            );
        System.assertEquals(
            1000,
        brkgPanel.ToProducingAdminFee__c,
        'ToProducingAdminFee__c should match brkgAdjData.adminFeeToProducing'
            );
        System.assertEquals(
            500,
        brkgPanel.ToLKAdminFee__c,
        'ToLKAdminFee__c should match brkgAdjData.adminFeeToLK'
            );
        System.assertEquals(170000, brkgPanel.NetRI__c, 'NetRI__c should match brkgAdjData.netRI');
    }
    
    
}