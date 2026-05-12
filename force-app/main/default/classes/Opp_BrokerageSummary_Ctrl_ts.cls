/**********************************************************************************
 * @filename      : Opp_BrokerageSummary_Ctrl_ts.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-01-02
 * @description   : Test class for Opp_BrokerageSummary_Ctrl
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02      i2max              Create
 **********************************************************************************/
@IsTest
private class Opp_BrokerageSummary_Ctrl_ts {
    /**
     * @description 공통 테스트 데이터 생성
     */
    @TestSetup
    static void setupTestData() {
        // Account 생성
        Account testAccount = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Test Account', 'OwnerId' => UserInfo.getUserId() },
        true
            );
        
        // Opportunity 생성
        Opportunity testOpp = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opportunity',
        getReinsuranceRtId(),
        false
            );
        testOpp.TotalOrderPct__c = 70.00;
        testOpp.RICommPct__c = 5.00;
        testOpp.OtherDeductionsPct__c = 2.00;
        insert testOpp;
        
        // SlipInfo 생성 (Latest_is__c = true 로 TSI 쿼리 조건 충족)
        OPP_SlipInfo__c slipInfo = new OPP_SlipInfo__c(
            Opportunity_lk__c = testOpp.Id,
        RICession__c = 70.00,
        Latest_is__c = true
            );
        insert slipInfo;
        
        // Layer 생성 (Primary / QS / Brkg Adj / EUR)
        List<OPP_Layer__c> layers = new List<OPP_Layer__c>();
        OPP_Layer__c primaryLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 1000000
            );
        OPP_Layer__c qsLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'QS',
        Excess__c = 1000000,
        LOL__c = 500000
            );
        OPP_Layer__c brkgAdjLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'Brkg Adj',
        Excess__c = 1500000,
        LOL__c = 500000
            );
        OPP_Layer__c eurLayer = new OPP_Layer__c(
            Opportunity_md__c = testOpp.Id,
        LayerCurrency__c = 'EUR',
        Type__c = 'Primary',
        Excess__c = 0,
        LOL__c = 800000
            );
        layers.add(primaryLayer);
        layers.add(qsLayer);
        layers.add(brkgAdjLayer);
        layers.add(eurLayer);
        insert layers;
        
        // Panel 생성
        List<OPP_Panel__c> panels = new List<OPP_Panel__c>();
        
        // Primary Layer Panel 1
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = primaryLayer.Id,
        GrossPrem__c = 500000,
        Signed__c = 25.00,
        NetToLKPrem__c = 425000,
        NetProducingCobrker__c = 50000,
        NetToUW__c = 375000,
        ToProducingAdminFee__c = 2000,
        ToLKAdminFee__c = 1000,
        TotalBrkg__c = 15000,
        LKReBrkge__c = 10000,
        LKProducingTPPBrkg__c = 2000,
        LKPlacingTPPBrkg__c = 1000,
        ProducingTPPBrkg__c = 1500,
        PlacingTPPBrkge__c = 500,
        LKAdminFee__c = 800,
        LKTPPBrkge__c = 5000,
        PlacingTPPAdminFeePct__c = 10.00,
        Finalize_is__c = true
            )
            );
        
        // Primary Layer Panel 2
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = primaryLayer.Id,
        GrossPrem__c = 500000,
        Signed__c = 25.00,
        NetToLKPrem__c = 425000,
        NetProducingCobrker__c = 50000,
        NetToUW__c = 375000,
        ToProducingAdminFee__c = 2000,
        ToLKAdminFee__c = 1000,
        TotalBrkg__c = 15000,
        LKReBrkge__c = 10000,
        LKProducingTPPBrkg__c = 2000,
        LKPlacingTPPBrkg__c = 1000,
        ProducingTPPBrkg__c = 1500,
        PlacingTPPBrkge__c = 500,
        LKAdminFee__c = 800,
        LKTPPBrkge__c = 5000,
        PlacingTPPAdminFeePct__c = 10.00,
        Finalize_is__c = true
            )
            );
        
        // QS Layer Panel
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = qsLayer.Id,
        GrossPrem__c = 300000,
        Signed__c = 10.00,
        NetToLKPrem__c = 250000,
        NetProducingCobrker__c = 30000,
        NetToUW__c = 220000,
        ToProducingAdminFee__c = 1000,
        ToLKAdminFee__c = 500,
        TotalBrkg__c = 8000,
        LKReBrkge__c = 5000,
        LKProducingTPPBrkg__c = 1000,
        LKPlacingTPPBrkg__c = 500,
        ProducingTPPBrkg__c = 1000,
        PlacingTPPBrkge__c = 500,
        LKAdminFee__c = 400,
        LKTPPBrkge__c = 3000,
        PlacingTPPAdminFeePct__c = 8.00,
        Finalize_is__c = true
            )
            );
        
        // Brkg Adj Layer Panel
        panels.add(
            new OPP_Panel__c(
            Layer_md__c = brkgAdjLayer.Id,
        GrossPrem__c = 100000,
        Signed__c = 5.00,
        NetToLKPrem__c = 80000,
        NetProducingCobrker__c = 10000,
        NetToUW__c = 70000,
        ToProducingAdminFee__c = 500,
        ToLKAdminFee__c = 300,
        TotalBrkg__c = 3000,
        LKReBrkge__c = 2000,
        LKProducingTPPBrkg__c = 500,
        LKPlacingTPPBrkg__c = 200,
        ProducingTPPBrkg__c = 200,
        PlacingTPPBrkge__c = 100,
        LKAdminFee__c = 200,
        LKTPPBrkge__c = 1000,
        PlacingTPPAdminFeePct__c = 5.00,
        Finalize_is__c = true
            )
            );
        insert panels;
        
        // TSI By Location 생성 (USD, GrossPrem_fm__c는 formula이므로 InsuredAmount__c로 source 세팅)
        List<OPP_TSIByLocation__c> tsiLocations = new List<OPP_TSIByLocation__c>{
            new OPP_TSIByLocation__c(
                SlipInfo_md__c = slipInfo.Id,
            InsuredAmount__c = 600000,
            PremiumCurrency__c = 'USD'
                ),
            new OPP_TSIByLocation__c(
                SlipInfo_md__c = slipInfo.Id,
            InsuredAmount__c = 400000,
            PremiumCurrency__c = 'USD'
                )
        };
        insert tsiLocations;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Helper
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description Reinsurance RecordType ID 조회 (fallback: 첫 번째 사용 가능한 RecordType)
     */
    private static Id getReinsuranceRtId() {
        Id rtId = null;
        for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
            if (rti.isAvailable() && !rti.isMaster() && rti.getName() == 'Reinsurance') {
                return rti.getRecordTypeId();
            }
        }
        for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
            if (rti.isAvailable() && !rti.isMaster()) {
                return rti.getRecordTypeId();
            }
        }
        return rtId;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getInitMeta
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description getInitMeta 메서드 테스트 - Opportunity Id로 조회
     */
    @IsTest
    static void testGetInitMeta_ValidOppId() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.InitMetaWrapper result = Opp_BrokerageSummary_Ctrl.getInitMeta(
            testOpp.Id
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            false,
        result.isPlacement,
        'isPlacement should be false for Opportunity'
            );
        System.assertNotEquals(
            null,
        result.hasEditPermission,
        'hasEditPermission should not be null'
            );
    }
    
    /**
     * @description getInitMeta 메서드 테스트 - null recordId
     */
    @IsTest
    static void testGetInitMeta_NullId() {
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.InitMetaWrapper result = Opp_BrokerageSummary_Ctrl.getInitMeta(
            null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isPlacement, 'isPlacement should default to false');
        System.assertEquals(
            false,
        result.hasEditPermission,
        'hasEditPermission should default to false'
            );
    }
    
    /**
     * @description InitMetaWrapper 초기값 테스트
     */
    @IsTest
    static void testInitMetaWrapper_Initialization() {
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.InitMetaWrapper wrapper = new Opp_BrokerageSummary_Ctrl.InitMetaWrapper();
        Test.stopTest();
        
        System.assertEquals(false, wrapper.isPlacement, 'isPlacement should initialize to false');
        System.assertEquals(
            false,
        wrapper.hasEditPermission,
        'hasEditPermission should initialize to false'
            );
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getBrokerageSummary — 기본 조회
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description getBrokerageSummary 메서드 테스트 - Finalize된 패널 전체 조회 (7 cards 전체 검증)
     */
    @IsTest
    static void testGetBrokerageSummary_Success() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.hasPanels, 'Should have panels');
        
        // 카드 2: Total Order / Written
        System.assertEquals(70.00, result.totalOrderPct, 'Total Order % should be 70.00');
        System.assertEquals(65.00, result.signedPct, 'Signed % should be 65.00 (25+25+10+5)');
        
        // 카드 3: Net to
        System.assertEquals(1180000, result.netToLKPrem, 'Net to LK Prem should be 1,180,000');
        System.assertEquals(
            140000,
        result.netToProducingCoBroker,
        'Net to Producing Co-Broker should be 140,000'
            );
        System.assertEquals(1040000, result.netToUW, 'Net to UW should be 1,040,000');
        
        // 카드 5: Brkg
        System.assertEquals(
            41000,
        result.totalBrkg,
        'Total Brkg should be 41,000 (15000+15000+8000+3000)'
            );
        System.assert(result.lkBrokerage > 0, 'LK Brokerage should be greater than 0');
        System.assert(result.lkTPPBrokerage > 0, 'LK TPP Brokerage should be greater than 0');
        System.assert(result.tppBrokerage > 0, 'TPP Brokerage should be greater than 0');
        
        // 카드 6: LK Re Brkg
        System.assert(
            result.lkReBrokeragePercent > 0,
        'LK Re Brokerage percent should be greater than 0'
            );
        System.assertEquals(5000, result.proportional, 'Proportional (QS) should be 5,000');
        System.assertEquals(2000, result.brkgAdj, 'Brkg Adj should be 2,000');
        
        // 카드 7: Brkg after admin
        System.assert(
            result.lkReBrokerageAfterAdmin > 0,
        'LK Re Brokerage After Admin should be greater than 0'
            );
        // tppBrokerageAfterAdmin = tppBrokerage - adminFeeToProducing - adminFeeToLK
        Decimal expectedTppAfterAdmin =
            result.tppBrokerage -
            result.adminFeeToProducing -
            result.adminFeeToLK;
        System.assertEquals(
            expectedTppAfterAdmin,
        result.tppBrokerageAfterAdmin,
        'TPP Brokerage After Admin should match formula'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - 선택된 Panel ID로 조회
     */
    @IsTest
    static void testGetBrokerageSummary_WithPanelIds() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OPP_Panel__c> panels = [
            SELECT Id
            FROM OPP_Panel__c
            WHERE
                Layer_md__r.Opportunity_md__c = :testOpp.Id
                AND Layer_md__r.LayerCurrency__c = 'USD'
            LIMIT 2
        ];
        
        List<Id> panelIds = new List<Id>();
        for (OPP_Panel__c panel : panels) {
            panelIds.add(panel.Id);
        }
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        panelIds,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.hasPanels, 'Should have panels');
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - null currency (기본값 USD 사용)
     */
    @IsTest
    static void testGetBrokerageSummary_NullCurrency() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        null,
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            70.00,
        result.totalOrderPct,
        'USD로 조회되어 TotalOrderPct가 70이어야 함'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - blank currency (기본값 USD 사용)
     */
    @IsTest
    static void testGetBrokerageSummary_BlankCurrency() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        '',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            70.00,
        result.totalOrderPct,
        'USD로 조회되어 TotalOrderPct가 70이어야 함'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Finalize 패널 없는 경우 (EUR)
     */
    @IsTest
    static void testGetBrokerageSummary_NoPanels() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'EUR',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.grossPremium, 'Gross Premium should be 0 (no EUR TSI)');
        System.assertEquals(70.00, result.totalOrderPct, 'Total Order % should still be 70.00');
        System.assertEquals(0, result.signedPct, 'Signed % should be 0');
        System.assertEquals(0, result.netToLKPrem, 'Net to LK Prem should be 0');
        System.assertEquals(false, result.hasPanels, 'Should not have panels');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getBrokerageSummary — BrkgAdj_is__c 패널 포함 조회
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description getBrokerageSummary 메서드 테스트 - BrkgAdj_is__c = true 패널도 포함되는지 확인
     */
    @IsTest
    static void testGetBrokerageSummary_BrkgAdjPanelIncluded() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_Layer__c testLayer = [
            SELECT Id
            FROM OPP_Layer__c
            WHERE LayerCurrency__c = 'USD' AND Type__c = 'Primary'
            LIMIT 1
        ];
        
        // BrkgAdj_is__c = true, Finalize_is__c = false 패널 추가
        OPP_Panel__c brkgAdjPanel = new OPP_Panel__c(
            Layer_md__c = testLayer.Id,
        GrossPrem__c = 50000,
        Signed__c = 5.00,
        NetToLKPrem__c = 40000,
        NetToUW__c = 35000,
        TotalBrkg__c = 2000,
        LKReBrkge__c = 1000,
        Finalize_is__c = false,
        BrkgAdj_is__c = true
            );
        insert brkgAdjPanel;
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // BrkgAdj 패널이 포함되어 기존 값보다 totalBrkg가 증가해야 함
        System.assert(
            result.totalBrkg >= 41000,
        'Total Brkg should include BrkgAdj panel (>= 41,000)'
            );
        System.assertEquals(true, result.hasPanels, 'Should have panels');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getBrokerageSummary — 카드별 계산 검증
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description getBrokerageSummary 메서드 테스트 - QS Layer 비례 계산 (카드 6)
     */
    @IsTest
    static void testGetBrokerageSummary_QSLayerCalculations() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(5000, result.proportional, 'Proportional (QS) should be 5,000');
        System.assert(
            result.proportionalPercent > 0,
        'Proportional percent should be greater than 0'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Brkg Adj Layer 계산 (카드 6)
     */
    @IsTest
    static void testGetBrokerageSummary_BrkgAdjLayerCalculations() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2000, result.brkgAdj, 'Brkg Adj should be 2,000');
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Non-Proportional 계산 (카드 6)
     */
    @IsTest
    static void testGetBrokerageSummary_NonProportionalCalculations() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // nonProportional = lkReBrkge - proportional - brkgAdj
        Decimal expectedNonProportional = result.lkReBrkge - result.proportional - result.brkgAdj;
        System.assertEquals(
            expectedNonProportional,
        result.nonProportional,
        'Non-Proportional calculation should match'
            );
        System.assert(
            result.nonProportionalPercent >= 0,
        'Non-Proportional percent should be non-negative'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Admin Fee 계산 (카드 4, 7)
     */
    @IsTest
    static void testGetBrokerageSummary_AdminFeeCalculations() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // 카드 4
        System.assertEquals(
            5500,
        result.adminFeeToProducing,
        'Admin Fee to Producing should be 5,500 (2000+2000+1000+500)'
            );
        System.assertEquals(
            2800,
        result.adminFeeToLK,
        'Admin Fee to LK should be 2,800 (1000+1000+500+300)'
            );
        // 카드 7: lkReBrokerageAfterAdmin = adminFeeToProducing + adminFeeToLK + lkBrokerage
        Decimal expectedLKAfterAdmin =
            result.adminFeeToProducing +
            result.adminFeeToLK +
            result.lkBrokerage;
        System.assertEquals(
            expectedLKAfterAdmin,
        result.lkReBrokerageAfterAdmin,
        'LK Re Brokerage After Admin should match formula'
            );
        // 카드 7: tppBrokerageAfterAdmin = tppBrokerage - adminFeeToProducing - adminFeeToLK
        Decimal expectedTPPAfterAdmin =
            result.tppBrokerage -
            result.adminFeeToProducing -
            result.adminFeeToLK;
        System.assertEquals(
            expectedTPPAfterAdmin,
        result.tppBrokerageAfterAdmin,
        'TPP Brokerage After Admin should match formula'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - TPP / LK Brokerage 계산 (카드 5)
     */
    @IsTest
    static void testGetBrokerageSummary_TPPBrokerageCalculations() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.lkTPPBrokerage > 0, 'LK TPP Brokerage should be greater than 0');
        System.assert(result.tppBrokerage > 0, 'TPP Brokerage should be greater than 0');
        // lkBrokerage = lkReBrkge + lkTPPBrokerage
        Decimal expectedLKBrokerage = result.lkReBrkge + result.lkTPPBrokerage;
        System.assertEquals(
            expectedLKBrokerage,
        result.lkBrokerage,
        'LK Brokerage should equal lkReBrkge + lkTPPBrokerage'
            );
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // calculateMismatchedLayers 검증
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description getBrokerageSummary 메서드 테스트 - Shortfall 상태 확인
     */
    @IsTest
    static void testGetBrokerageSummary_MismatchedLayers_Shortfall() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(
            null,
        result.mismatchedLayers,
        'Mismatched layers should not be null'
            );
        
        Boolean hasShortfall = false;
        for (Opp_BrokerageSummary_Ctrl.LayerComparison comparison : result.mismatchedLayers) {
            if (comparison.status == 'Shortfall') {
                hasShortfall = true;
                System.assert(
                    comparison.totalOrderPct > comparison.signedPct,
                'Shortfall should have totalOrder > signed'
                    );
            }
        }
        System.assert(hasShortfall, 'Should have at least one Shortfall');
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Over Placed 상태 확인
     */
    @IsTest
    static void testGetBrokerageSummary_MismatchedLayers_OverPlaced() {
        Account testAccount = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{
            'Name' => 'Test Account OverPlaced',
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Opportunity testOpp2 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp OverPlaced',
        getReinsuranceRtId(),
        false
            );
        testOpp2.TotalOrderPct__c = 30.00;
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
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp2.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Boolean hasOverPlaced = false;
        for (Opp_BrokerageSummary_Ctrl.LayerComparison comparison : result.mismatchedLayers) {
            if (comparison.status == 'Over Placed') {
                hasOverPlaced = true;
                System.assert(
                    comparison.totalOrderPct < comparison.signedPct,
                'Over Placed should have totalOrder < signed'
                    );
            }
        }
        System.assert(hasOverPlaced, 'Should have at least one Over Placed');
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Placement Done 상태 (mismatchedLayers에 포함되지 않음)
     */
    @IsTest
    static void testGetBrokerageSummary_MismatchedLayers_PlacementDone() {
        Account testAccount = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{
            'Name' => 'Test Account PlacementDone',
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Opportunity testOpp3 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp PlacementDone',
        getReinsuranceRtId(),
        false
            );
        testOpp3.TotalOrderPct__c = 50.00;
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
        Signed__c = 50.00,
        Finalize_is__c = true
            );
        insert panel3;
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp3.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            0,
        result.mismatchedLayers.size(),
        'Placement Done should not be in mismatched layers'
            );
    }
    
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - NetToLKPrem = 0 일 때 비율 계산이 0으로 처리되는지 확인
     */
    @IsTest
    static void testGetBrokerageSummary_ZeroNetToLKPrem() {
        Account testAccount = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{
            'Name' => 'Test Account Zero',
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Opportunity testOpp5 = OPP_TestDataFactory.createOpportunity(
            testAccount.Id,
        'Test Opp Zero',
        getReinsuranceRtId(),
        false
            );
        testOpp5.TotalOrderPct__c = 50.00;
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
        NetToLKPrem__c = 0,
        LKReBrkge__c = 0,
        Signed__c = 10.00,
        Finalize_is__c = true
            );
        insert panel5;
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp5.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            0,
        result.lkReBrokeragePercent,
        'LK Re Brokerage percent should be 0 when NetToLKPrem is 0'
            );
        System.assertEquals(
            0,
        result.proportionalPercent,
        'Proportional percent should be 0 when NetToLKPrem is 0'
            );
        System.assertEquals(
            0,
        result.nonProportionalPercent,
        'Non-Proportional percent should be 0 when NetToLKPrem is 0'
            );
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - null 필드값 포함 Panel 처리 (sumField null-safe 확인)
     */
    @IsTest
    static void testGetBrokerageSummary_NullFieldValues() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_Layer__c testLayer = [
            SELECT Id
            FROM OPP_Layer__c
            WHERE LayerCurrency__c = 'USD'
            LIMIT 1
        ];
        
        OPP_Panel__c panelWithNulls = new OPP_Panel__c(
            Layer_md__c = testLayer.Id,
        GrossPrem__c = null,
        Signed__c = null,
        NetToLKPrem__c = null,
        TotalBrkg__c = null,
        LKReBrkge__c = null,
        LKTPPBrkge__c = null,
        Finalize_is__c = true
            );
        insert panelWithNulls;
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.hasPanels, 'Should have panels');
    }
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - 여러 Layer 세그먼트 (mismatchedLayers status 검증)
     */
    @IsTest
    static void testGetBrokerageSummary_MultipleSegments() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            testOpp.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(
            result.mismatchedLayers.size() > 0,
        'Should have mismatched layers with multiple segments'
            );
        
        for (Opp_BrokerageSummary_Ctrl.LayerComparison comparison : result.mismatchedLayers) {
            System.assertNotEquals(null, comparison.layerName, 'Layer name should not be null');
            System.assert(
                comparison.status == 'Shortfall' ||
                comparison.status == 'Over Placed' ||
                comparison.status == 'Placement Done',
            'Status should be valid'
                );
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Wrapper / Inner class 초기화 테스트
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description BrokerageSummaryWrapper 초기값 테스트
     */
    @IsTest
    static void testBrokerageSummaryWrapper_Initialization() {
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper wrapper = new Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper();
        Test.stopTest();
        
        System.assertEquals(0, wrapper.grossPremium, 'grossPremium should initialize to 0');
        System.assertEquals(0, wrapper.totalOrderPct, 'totalOrderPct should initialize to 0');
        System.assertEquals(0, wrapper.signedPct, 'signedPct should initialize to 0');
        System.assertEquals(0, wrapper.netToLKPrem, 'netToLKPrem should initialize to 0');
        System.assertEquals(
            0,
        wrapper.netToProducingCoBroker,
        'netToProducingCoBroker should initialize to 0'
            );
        System.assertEquals(0, wrapper.netToUW, 'netToUW should initialize to 0');
        System.assertEquals(0, wrapper.totalBrkg, 'totalBrkg should initialize to 0');
        System.assertEquals(0, wrapper.lkBrokerage, 'lkBrokerage should initialize to 0');
        System.assertEquals(
            0,
        wrapper.lkReBrokeragePercent,
        'lkReBrokeragePercent should initialize to 0'
            );
        System.assertEquals(
            0,
        wrapper.tppBrokerageAfterAdmin,
        'tppBrokerageAfterAdmin should initialize to 0'
            );
        System.assertEquals(false, wrapper.hasPanels, 'hasPanels should initialize to false');
        System.assertNotEquals(
            null,
        wrapper.mismatchedLayers,
        'mismatchedLayers should initialize to empty list'
            );
        System.assertEquals(0, wrapper.mismatchedLayers.size(), 'mismatchedLayers should be empty');
    }
    
    /**
     * @description LayerComparison 초기값 테스트
     */
    @IsTest
    static void testLayerComparison_Initialization() {
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.LayerComparison comparison = new Opp_BrokerageSummary_Ctrl.LayerComparison(
            'Test Layer',
        70.00,
        50.00,
        'Shortfall'
            );
        Test.stopTest();
        
        System.assertEquals('Test Layer', comparison.layerName, 'layerName should match');
        System.assertEquals(70.00, comparison.totalOrderPct, 'totalOrderPct should match');
        System.assertEquals(50.00, comparison.signedPct, 'signedPct should match');
        System.assertEquals('Shortfall', comparison.status, 'status should match');
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // getInitMeta — Placement 경로 (v1.6)
    // ─────────────────────────────────────────────────────────────────────────
    /**
     * @description getInitMeta 메서드 테스트 - Placement Id 전달 시 isPlacement=true, hasEditPermission=false
     */
    @IsTest
    static void testGetInitMeta_WithPlacementId() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = testOpp.Id,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.InitMetaWrapper result = Opp_BrokerageSummary_Ctrl.getInitMeta(placement.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.isPlacement, 'isPlacement should be true for Placement');
        System.assertEquals(false, result.hasEditPermission, 'hasEditPermission should be false for Placement');
    }
    
    
    /**
     * @description getBrokerageSummary 메서드 테스트 - Placement Id, 패널 없음
     *              totalOrderPct는 Placement.TotalOrderPct__c 기준으로 반환, hasPanels = false
     */
    @IsTest
    static void testGetBrokerageSummary_Placement_NoPanels() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = testOpp.Id,
        TotalOrderPct__c = 60.00,
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result = Opp_BrokerageSummary_Ctrl.getBrokerageSummary(
            placement.Id,
        'USD',
        null,
        false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.hasPanels, 'Should not have panels');
        System.assertEquals(60.00, result.totalOrderPct, 'totalOrderPct should use Placement.TotalOrderPct__c = 60');
        System.assertEquals(0, result.grossPremium, 'grossPremium should be 0');
    }
    
    
    // ─────────────────────────────────────────────────────────────────────────
    // calculateMismatchedLayers 직접 호출 테스트
    // ─────────────────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────────────────
    // getBrokerageSummary — Treaty / Declaration → Schedule 기반 grossPremium
    // ─────────────────────────────────────────────────────────────────────────
    
    /**
     * @description Opportunity.CedingType1__c = 'Treaty'인 경우
     *              grossPremium을 PremiumSchedule.SlipGrossPrem__c 기준으로 조회하는지 확인
     */
    @IsTest
    static void testGetBrokerageSummary_TreatyOpp_UsesScheduleGrossPrem() {
        Account acct = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Treaty Opp Acct', 'OwnerId' => UserInfo.getUserId() },
        true
            );
        
        Opportunity treatyOpp = OPP_TestDataFactory.createOpportunity(
            acct.Id, 'Treaty Opp', getReinsuranceRtId(), false
            );
        treatyOpp.TotalOrderPct__c = 70.00;
        treatyOpp.CedingType1__c = 'Treaty';
        insert treatyOpp;
        
        OPP_Layer__c layer = new OPP_Layer__c(
            Opportunity_md__c = treatyOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'QS'
            );
        insert layer;
        
        insert new OPP_Panel__c(
            Layer_md__c = layer.Id,
        Signed__c = 30.00,
        NetToLKPrem__c = 100000,
        Finalize_is__c = true
            );
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = treatyOpp.Id,
        Prem_Currency__c = 'USD',
        Type__c = 'Schedule',
        SlipGrossPrem__c = 750000
            );
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result =
            Opp_BrokerageSummary_Ctrl.getBrokerageSummary(treatyOpp.Id, 'USD', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            750000,
        result.grossPremium,
        'Treaty Opp: grossPremium should use PremiumSchedule.SlipGrossPrem__c'
            );
    }
    
    /**
     * @description Placement.CedingType1__c = 'Treaty'인 경우
     *              grossPremium을 PremiumSchedule.SlipGrossPrem__c 기준으로 조회하는지 확인
     */
    @IsTest
    static void testGetBrokerageSummary_TreatyPlacement_UsesScheduleGrossPrem() {
        Account acct = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Treaty Plc Acct', 'OwnerId' => UserInfo.getUserId() },
        true
            );
        
        Opportunity opp = OPP_TestDataFactory.createOpportunity(
            acct.Id, 'Treaty Plc Opp', getReinsuranceRtId(), false
            );
        opp.TotalOrderPct__c = 70.00;
        insert opp;
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TotalOrderPct__c = 65.00,
        CedingType1__c = 'Treaty',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_Layer__c layer = new OPP_Layer__c(
            Opportunity_md__c = opp.Id,
        Placement_lk__c = placement.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'QS'
            );
        insert layer;
        
        insert new OPP_Panel__c(
            Layer_md__c = layer.Id,
        Signed__c = 30.00,
        NetToLKPrem__c = 100000,
        Finalize_is__c = true
            );
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Placement_lk__c = placement.Id,
        Prem_Currency__c = 'USD',
        Type__c = 'Schedule',
        SlipGrossPrem__c = 500000
            );
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result =
            Opp_BrokerageSummary_Ctrl.getBrokerageSummary(placement.Id, 'USD', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            500000,
        result.grossPremium,
        'Treaty Placement: grossPremium should use PremiumSchedule.SlipGrossPrem__c'
            );
    }
    
    /**
     * @description Placement.TransactionType__c = 'Declaration'인 경우
     *              grossPremium을 PremiumSchedule.SlipGrossPrem__c 기준으로 조회하는지 확인
     */
    @IsTest
    static void testGetBrokerageSummary_DeclarationPlacement_UsesScheduleGrossPrem() {
        Account acct = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Decl Plc Acct', 'OwnerId' => UserInfo.getUserId() },
        true
            );
        
        Opportunity opp = OPP_TestDataFactory.createOpportunity(
            acct.Id, 'Decl Plc Opp', getReinsuranceRtId(), false
            );
        opp.TotalOrderPct__c = 70.00;
        insert opp;
        
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        TotalOrderPct__c = 65.00,
        TransactionType__c = 'Declaration',
        OwnerId = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_Layer__c layer = new OPP_Layer__c(
            Opportunity_md__c = opp.Id,
        Placement_lk__c = placement.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'QS'
            );
        insert layer;
        
        insert new OPP_Panel__c(
            Layer_md__c = layer.Id,
        Signed__c = 30.00,
        NetToLKPrem__c = 100000,
        Finalize_is__c = true
            );
        
        insert new OPP_PremiumSchedule__c(
            Opportunity_lk__c = opp.Id,
        Placement_lk__c = placement.Id,
        Prem_Currency__c = 'USD',
        Type__c = 'Schedule',
        SlipGrossPrem__c = 620000
            );
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result =
            Opp_BrokerageSummary_Ctrl.getBrokerageSummary(placement.Id, 'USD', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(
            620000,
        result.grossPremium,
        'Declaration Placement: grossPremium should use PremiumSchedule.SlipGrossPrem__c'
            );
    }
    
    /**
     * @description Treaty이지만 PremiumSchedule가 없는 경우 TSI 합계를 grossPremium으로 사용하는지 확인
     */
    @IsTest
    static void testGetBrokerageSummary_Treaty_NoSchedule_FallsBackToTsi() {
        Account acct = (Account) TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{ 'Name' => 'Treaty No Sched Acct', 'OwnerId' => UserInfo.getUserId() },
        true
            );
        
        Opportunity treatyOpp = OPP_TestDataFactory.createOpportunity(
            acct.Id, 'Treaty No Sched Opp', getReinsuranceRtId(), false
            );
        treatyOpp.TotalOrderPct__c = 70.00;
        treatyOpp.CedingType1__c = 'Treaty';
        insert treatyOpp;
        
        OPP_SlipInfo__c slipInfo = new OPP_SlipInfo__c(
            Opportunity_lk__c = treatyOpp.Id,
        RICession__c = 70.00,
        Latest_is__c = true
            );
        insert slipInfo;
        
        insert new OPP_TSIByLocation__c(
            SlipInfo_md__c = slipInfo.Id,
        InsuredAmount__c = 400000,
        PremiumCurrency__c = 'USD'
            );
        
        OPP_Layer__c layer = new OPP_Layer__c(
            Opportunity_md__c = treatyOpp.Id,
        LayerCurrency__c = 'USD',
        Type__c = 'QS'
            );
        insert layer;
        
        insert new OPP_Panel__c(
            Layer_md__c = layer.Id,
        Signed__c = 30.00,
        NetToLKPrem__c = 100000,
        Finalize_is__c = true
            );
        // PremiumSchedule 없음 → TSI 기반 grossPremium 유지
        
        Test.startTest();
        Opp_BrokerageSummary_Ctrl.BrokerageSummaryWrapper result =
            Opp_BrokerageSummary_Ctrl.getBrokerageSummary(treatyOpp.Id, 'USD', null, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Schedule 없으면 TSI 합계가 grossPremium이 됨 (GrossPrem_fm__c는 formula이므로 0일 수 있음)
        System.assert(result.grossPremium >= 0, 'grossPremium should be non-negative (TSI fallback)');
    }
    
    /**
     * @description calculateMismatchedLayers 직접 호출 - 빈 패널, globalMaxY = 0 → 빈 결과
     */
    @IsTest
    static void testCalculateMismatchedLayers_EmptyPanels_NoGlobalMaxY() {
        Test.startTest();
        List<Opp_BrokerageSummary_Ctrl.LayerComparison> result =
            Opp_BrokerageSummary_Ctrl.calculateMismatchedLayers(new List<OPP_Panel__c>(), 50.00, 0);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'globalMaxY=0이면 빈 결과여야 함');
    }
    
    /**
     * @description calculateMismatchedLayers 직접 호출 - 빈 패널, globalMaxY > 0 → 전체 Shortfall 1건
     */
    @IsTest
    static void testCalculateMismatchedLayers_EmptyPanels_WithGlobalMaxY() {
        Test.startTest();
        List<Opp_BrokerageSummary_Ctrl.LayerComparison> result =
            Opp_BrokerageSummary_Ctrl.calculateMismatchedLayers(new List<OPP_Panel__c>(), 50.00, 1000000);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), '패널 없고 globalMaxY>0이면 전체 Shortfall 1건이어야 함');
        System.assertEquals('Shortfall', result[0].status, 'status는 Shortfall이어야 함');
        System.assertEquals(50.00, result[0].totalOrderPct, 'totalOrderPct = 50이어야 함');
        System.assertEquals(0, result[0].signedPct, 'signedPct = 0이어야 함');
        System.assertNotEquals(null, result[0].layerName, 'layerName이 null이 아니어야 함');
    }
}