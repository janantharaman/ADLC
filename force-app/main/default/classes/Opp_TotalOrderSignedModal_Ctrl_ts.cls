/**********************************************************************************
 * @filename      : Opp_TotalOrderSignedModal_Ctrl_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-15
 * @description   : Test class for Opp_TotalOrderSignedModal_Ctrl
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-15      i2max              Create
 **********************************************************************************/
@IsTest
private class Opp_TotalOrderSignedModal_Ctrl_ts {
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = ACC_TestDataFactory.createAccount('Test Account', 'General', true);
        
        
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
        
        // Create Opportunity
        Opportunity testOpp = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opportunity',
        rtId,
        false
            );
        testOpp.TotalOrderPct__c = 70.00;
        insert testOpp;
        
        // Create Layers
        List<OPP_Layer__c> layers = new List<OPP_Layer__c>();
        
        OPP_Layer__c primaryLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        layers.add(primaryLayer);
        
        OPP_Layer__c secondLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Excess',
        Excess__c = 1000000,
        LOL__c = 500000
            );
        layers.add(secondLayer);
        
        OPP_Layer__c eurLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'EUR',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 800000
            );
        layers.add(eurLayer);
        
        insert layers;
        
        // Create Panels
        List<OPP_Panel__c> panels = new List<OPP_Panel__c>();
        
        // Primary Layer Panels
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = primaryLayer.Id,
        Signed__c = 25.00,
        Finalize_is__c = true
            )
            );
        
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = primaryLayer.Id,
        Signed__c = 25.00,
        Finalize_is__c = true
            )
            );
        
        // Second Layer Panel
        panels.add(
            new OPP_Panel__c(Layer_md__c = secondLayer.Id, Signed__c = 15.00, Finalize_is__c = true)
            );
        
        insert panels;
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_Success() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should have at least one segment');
        
        for (Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.layerId, 'Layer ID should not be null');
            System.assertNotEquals(null, wrapper.layerLimit, 'Layer limit should not be null');
            System.assertNotEquals(null, wrapper.signedLine, 'Signed line should not be null');
            System.assertNotEquals(null, wrapper.status, 'Status should not be null');
            System.assertNotEquals(null, wrapper.statusClass, 'Status class should not be null');
        }
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_NullCurrency() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        null,
        1,
        null
            );
        Test.stopTest();
        
        // null currency는 LayerCurrency__c 필터에 매칭되는 Layer가 없으므로 빈 리스트 반환
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Null currency should return empty list');
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_BlankCurrency() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        '',
        1,
        null
            );
        Test.stopTest();
        
        // blank currency는 LayerCurrency__c 필터에 매칭되는 Layer가 없으므로 빈 리스트 반환
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Blank currency should return empty list');
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_NoPanels() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'EUR',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // EUR Layer는 있지만 Finalized Panel이 없으므로 globalMaxY 기반 Shortfall이 나와야 함
        System.assertEquals(1, result.size(), 'Should have 1 segment (0 - globalMaxY)');
        System.assertEquals(
            'Shortfall',
        result[0].status,
        'Status should be Shortfall when no panels'
            );
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_Shortfall() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        Boolean hasShortfall = false;
        for (Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper wrapper : result) {
            if (wrapper.status == 'Shortfall') {
                hasShortfall = true;
                System.assertEquals(
                    'status-shortfall',
                wrapper.statusClass,
                'Status class should be status-shortfall'
                    );
            }
        }
        System.assert(hasShortfall, 'Should have at least one Shortfall segment');
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_PlacementDone() {
        Account testAccount = ACC_TestDataFactory.createAccount('Test Account PlacementDone', 'General', true);
        
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
        
        Opportunity testOpp2 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp PlacementDone',
        rtId,
        false
            );
        testOpp2.TotalOrderPct__c = 50.00;
        insert testOpp2;
        
        OPP_Layer__c layer2 = new OPP_Layer__c(
            Opportunity_md__c = testOpp2.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        insert layer2;
        
        OPP_Panel__c panel2 = new OPP_Panel__c(
            Layer_md__c = layer2.Id,
        Signed__c = 50.00,
        Finalize_is__c = true
            );
        insert panel2;
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp2.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have 1 segment');
        System.assertEquals('Placement Done', result[0].status, 'Status should be Placement Done');
        System.assertEquals(
            'status-done',
        result[0].statusClass,
        'Status class should be status-done'
            );
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_OverPlaced() {
        Account testAccount = ACC_TestDataFactory.createAccount('Test Account OverPlaced', 'General', true);
        
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
        
        Opportunity testOpp3 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp OverPlaced',
        rtId,
        false
            );
        testOpp3.TotalOrderPct__c = 30.00;
        insert testOpp3;
        
        OPP_Layer__c layer3 = new OPP_Layer__c(
            Opportunity_md__c = testOpp3.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        insert layer3;
        
        OPP_Panel__c panel3 = new OPP_Panel__c(
            Layer_md__c = layer3.Id,
        Signed__c = 60.00,
        Finalize_is__c = true
            );
        insert panel3;
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp3.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have 1 segment');
        System.assertEquals('Over Placed', result[0].status, 'Status should be Over Placed');
        System.assertEquals(
            'status-overplaced',
        result[0].statusClass,
        'Status class should be status-overplaced'
            );
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_MultipleSegments() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Should have multiple segments');
        
        // Verify row numbers are sequential
        for (Integer i = 0; i < result.size(); i++) {
            System.assertEquals(i + 1, result[i].rowNumber, 'Row numbers should be sequential');
        }
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_SegmentLabels() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        Boolean hasFirstSegment = false;
        Boolean hasOtherSegment = false;
        
        for (Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.layerLimit, 'Layer limit should not be null');
            
            // First segment should have format "X xs OPDs"
            if (wrapper.layerLimit.contains('xs OPDs') && !wrapper.layerLimit.contains('xs 0 xs')) {
                hasFirstSegment = true;
            }
            // Other segments should have format "Y xs X xs OPDs"
            if (
                wrapper.layerLimit.contains('xs') &&
                wrapper.layerLimit.indexOf('xs') != wrapper.layerLimit.lastIndexOf('xs')
            ) {
                hasOtherSegment = true;
            }
        }
        
        // At least one type of segment should exist
        System.assert(
            hasFirstSegment || hasOtherSegment,
        'Should have properly formatted segment labels'
            );
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_SignedLineFormat() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        for (Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.signedLine, 'Signed line should not be null');
            System.assert(wrapper.signedLine.contains('%'), 'Signed line should contain % symbol');
        }
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_EmptyPanelsWithGlobalMaxY() {
        Account testAccount = ACC_TestDataFactory.createAccount('Test Account Empty', 'General', true);
        
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
        
        Opportunity testOpp4 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp Empty',
        rtId,
        false
            );
        testOpp4.TotalOrderPct__c = 50.00;
        insert testOpp4;
        
        OPP_Layer__c layer4 = new OPP_Layer__c(
            Opportunity_md__c = testOpp4.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        insert layer4;
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp4.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have 1 segment (0 - globalMaxY)');
        System.assertEquals('Shortfall', result[0].status, 'Empty panels should show Shortfall');
        System.assertEquals('0%', result[0].signedLine, 'Signed line should be 0%');
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_RefreshKey() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result1 = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        1,
        null
            );
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result2 = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp.Id,
        'USD',
        2,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result1, 'Result 1 should not be null');
        System.assertNotEquals(null, result2, 'Result 2 should not be null');
        System.assertEquals(result1.size(), result2.size(), 'Both results should have same size');
    }
    
    @IsTest
    static void testGetTotalOrderSignedData_ZeroTotalOrderPct() {
        Account testAccount = ACC_TestDataFactory.createAccount('Test Account Zero', 'General', true);
        
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
        
        Opportunity testOpp5 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp Zero',
        rtId,
        false
            );
        testOpp5.TotalOrderPct__c = 0;
        insert testOpp5;
        
        OPP_Layer__c layer5 = new OPP_Layer__c(
            Opportunity_md__c = testOpp5.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        insert layer5;
        
        OPP_Panel__c panel5 = new OPP_Panel__c(
            Layer_md__c = layer5.Id,
        Signed__c = 10.00,
        Finalize_is__c = true
            );
        insert panel5;
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            testOpp5.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have 1 segment');
        System.assertEquals(
            'Over Placed',
        result[0].status,
        'Status should be Over Placed when TotalOrder is 0 and Signed > 0'
            );
    }
    
    
    /**
     * @description getTotalOrderSignedData 메서드 테스트 - Placement__c Id 기준 조회 확인
     */
    @IsTest
    static void testGetTotalOrderSignedData_WithPlacementId() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Placement 생성 (부모 Opportunity 연결)
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = testOpp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        // Placement 기준 Layer 생성
        OPP_Layer__c layer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        Placement_lk__c = placement.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        insert layer;
        
        // Finalized Panel 생성
        OPP_Panel__c panel = new OPP_Panel__c(
            Layer_md__c = layer.Id,
        Signed__c = 70.00,
        Finalize_is__c = true
            );
        insert panel;
        
        Test.startTest();
        List<Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper> result = Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData(
            placement.Id,
        'USD',
        1,
        null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Placement 기준 결과가 null이 아니어야 함');
        System.assert(result.size() > 0, 'Placement 기준 Segment가 1개 이상 있어야 함');
        
        for (Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.layerLimit, 'Layer limit이 null이 아니어야 함');
            System.assertNotEquals(null, wrapper.signedLine, 'Signed line이 null이 아니어야 함');
            System.assertNotEquals(null, wrapper.status, 'Status가 null이 아니어야 함');
            System.assert(wrapper.signedLine.contains('%'), 'Signed line이 % 기호를 포함해야 함');
        }
    }
    
    @IsTest
    static void testLayerPanelWrapper_Properties() {
        Test.startTest();
        Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper wrapper = new Opp_TotalOrderSignedModal_Ctrl.LayerPanelWrapper();
        wrapper.rowNumber = 1;
        wrapper.layerId = 'test-id';
        wrapper.layerLimit = '1,000,000 xs OPDs';
        wrapper.signedLine = '50.00%';
        wrapper.status = 'Placement Done';
        wrapper.statusClass = 'status-done';
        Test.stopTest();
        
        System.assertEquals(1, wrapper.rowNumber, 'Row number should match');
        System.assertEquals('test-id', wrapper.layerId, 'Layer ID should match');
        System.assertEquals('1,000,000 xs OPDs', wrapper.layerLimit, 'Layer limit should match');
        System.assertEquals('50.00%', wrapper.signedLine, 'Signed line should match');
        System.assertEquals('Placement Done', wrapper.status, 'Status should match');
        System.assertEquals('status-done', wrapper.statusClass, 'Status class should match');
    }
}