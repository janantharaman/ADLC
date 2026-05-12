/**********************************************************************************
 * @filename      : Opp_MarketLineContainer_Ctrl_ts.cls
 * @projectname   : LK_DEV
 * @author        : i2max
 * @date          : 2026-02-15
 * @description   : Test class for Opp_MarketLineContainer_Ctrl
 *                  - [일반] 케이스: Cedant Closing → Offer fallback + OPP_Panel__c Currency 병합
 *                  - [특이] 케이스: Declaration/Treaty → picklist 전체, END → Cedant Endorsement SlipInfo
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-15      i2max            Create
 * 1.1   2026-04-28      i2max            Panel Currency 병합 로직 반영, 케이스 주석 정비
 **********************************************************************************/
@IsTest
private class Opp_MarketLineContainer_Ctrl_ts {
    
    @TestSetup
    static void makeData() {
        Account acc = (Account) COM_TestDataFactory.createSObject(
            'Account',
        new Map<String, Object>{
            'Name'    => 'Test Account',
            'OwnerId' => UserInfo.getUserId()
        },
        true
            );
        
        Id rtId = getOpportunityRtId();
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Test Opportunity', rtId, true);
        
        // Opportunity 기준 fallback 대상이 되도록 Cedant Offer + Latest = true 생성
        OPP_SlipInfo__c slipInfo = new OPP_SlipInfo__c(
            Opportunity_lk__c = opp.Id,
        Type__c           = 'Cedant Offer',
        Latest_is__c      = true
            );
        insert slipInfo;
        
        insert new OPP_PremiumSchedule__c(
            SlipInfo_lk__c = slipInfo.Id,
        Type__c        = 'Slip',
        Prem_Currency__c = 'USD'
            );
        
        // Producing Cobroker - CI Detail 조건 만족
        OPP_Cobroker__c cb1 = OPP_TestDataFactory.createCobroker(
            opp.Id,
        OPP_TestDataFactory.COBROKER_EXT_PRODUCING_SEP_CLIENT,
        false
            );
        insert cb1;
        
        // Producing Cobroker - CI Detail 조건 불만족
        OPP_Cobroker__c cb2 = OPP_TestDataFactory.createCobroker(
            opp.Id,
        OPP_TestDataFactory.COBROKER_EXT_PRODUCING_TOGETHER,
        false
            );
        insert cb2;
    }
    
    // ============================================================
    // Helper
    // ============================================================
    
    private static Id getOpportunityRtId() {
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
    
    private static OPP_SlipInfo__c createSlipInfo(Id oppId, Id placementId, String typeVal, Boolean latestVal) {
        OPP_SlipInfo__c rec = new OPP_SlipInfo__c(
            Opportunity_lk__c = oppId,
        Placement_lk__c   = placementId,
        Type__c           = typeVal,
        Latest_is__c      = latestVal
            );
        insert rec;
        return rec;
    }
    
    private static OPP_PremiumSchedule__c createPremiumSchedule(Id slipInfoId, String curr) {
        OPP_PremiumSchedule__c rec = new OPP_PremiumSchedule__c(
            SlipInfo_lk__c   = slipInfoId,
        Type__c          = 'Slip',
        Prem_Currency__c = curr
            );
        insert rec;
        return rec;
    }
    
    /**
     * @description Opportunity 기준 OPP_Layer__c + OPP_Panel__c 생성 헬퍼.
     *              Layer_md__r.Opportunity_md__c 조건 검증에 사용.
     */
    private static OPP_Panel__c createOppPanel(Id oppId, String curr) {
        OPP_Layer__c layer = OPP_TestDataFactory.createLayer(oppId, true);
        OPP_Panel__c panel = OPP_TestDataFactory.createPanel(layer.Id, false);
        panel.Currency__c = curr;
        insert panel;
        return panel;
    }
    
    /**
     * @description Placement 기준 OPP_Layer__c + OPP_Panel__c 생성 헬퍼.
     *              Layer_md__r.Placement_lk__c 조건 검증에 사용.
     *              OPP_TestDataFactory.createLayer 는 Opportunity 전용이므로 직접 생성.
     */
    private static OPP_Panel__c createPlacementPanel(Id oppId, Id placementId, String curr) {
        OPP_Layer__c layer = new OPP_Layer__c(
            Opportunity_md__c = oppId,
        Placement_lk__c   = placementId,
        Type__c           = 'Primary',
        LayerCurrency__c  = curr,
        LOL__c            = 100,
        Excess__c         = 0
            );
        insert layer;
        OPP_Panel__c panel = OPP_TestDataFactory.createPanel(layer.Id, false);
        panel.Currency__c = curr;
        insert panel;
        return panel;
    }
    
    // ============================================================
    // Wrapper 기본값 / null ID 방어
    // ============================================================
    
    @IsTest
    static void testGetContainerData_NullId() {
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(null);
        Test.stopTest();
        
        Assert.isNotNull(result, '결과가 null이 아니어야 함');
        Assert.areEqual(false, result.isPlacement,         'null ID 시 isPlacement 기본값은 false여야 함');
        Assert.areEqual(false, result.hasEditPermission,   'null ID 시 hasEditPermission 기본값은 false여야 함');
        Assert.isTrue(result.currencyOptions.isEmpty(),    'null ID 시 currencyOptions는 비어야 함');
        Assert.isFalse(result.hasProducingCobroker,        'null ID 시 hasProducingCobroker는 false여야 함');
        Assert.isFalse(result.satisfiesCIDetailCondition,  'null ID 시 satisfiesCIDetailCondition은 false여야 함');
    }
    
    @IsTest
    static void testContainerDataWrapper_Defaults() {
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper w =
            new Opp_MarketLineContainer_Ctrl.ContainerDataWrapper();
        Test.stopTest();
        
        Assert.areEqual(false, w.isPlacement,              '기본값 isPlacement는 false여야 함');
        Assert.areEqual(false, w.hasEditPermission,        '기본값 hasEditPermission은 false여야 함');
        Assert.isNotNull(w.currencyOptions,                '기본값 currencyOptions는 빈 List여야 함');
        Assert.isTrue(w.currencyOptions.isEmpty(),         '기본값 currencyOptions는 비어야 함');
        Assert.areEqual(false, w.hasProducingCobroker,     '기본값 hasProducingCobroker는 false여야 함');
        Assert.areEqual(false, w.satisfiesCIDetailCondition, '기본값 satisfiesCIDetailCondition은 false여야 함');
    }
    
    // ============================================================
    // Opportunity - Co-broker 조건 분기
    // ============================================================
    
    @IsTest
    static void testGetContainerData_HasProducing_CIDetailNotMet() {
        delete [SELECT Id FROM OPP_Cobroker__c];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        OPP_Cobroker__c cb1 = OPP_TestDataFactory.createCobroker(
            opp.Id,
        OPP_TestDataFactory.COBROKER_EXT_PRODUCING_TOGETHER_CLIENT,
        false
            );
        insert cb1;
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(opp.Id);
        Test.stopTest();
        
        Assert.isTrue(result.hasProducingCobroker,        'Producing cobroker가 있어야 함');
        Assert.isFalse(result.satisfiesCIDetailCondition, 'CI Detail 조건은 불만족이어야 함');
    }
    
    @IsTest
    static void testGetContainerData_NoProducingCobroker() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Id rtId = getOpportunityRtId();
        Opportunity newOpp = OPP_TestDataFactory.createOpportunity(acc.Id, 'New Test Opp 2', rtId, true);
        
        OPP_Cobroker__c cb = OPP_TestDataFactory.createCobroker(
            newOpp.Id,
        OPP_TestDataFactory.COBROKER_EXT_PLACING_SEP,
        false
            );
        insert cb;
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(newOpp.Id);
        Test.stopTest();
        
        Assert.isFalse(result.hasProducingCobroker,        'Producing cobroker가 없어야 함');
        Assert.isFalse(result.satisfiesCIDetailCondition,  'CI Detail 조건은 false여야 함');
    }
    
    // ============================================================
    // Placement - 플래그 기본 검증
    // ============================================================
    
    @IsTest
    static void testGetContainerData_PlacementId_Flags() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId()
            );
        insert placement;
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, '결과가 null이 아니어야 함');
        Assert.areEqual(true,  result.isPlacement,       'Placement ID 전달 시 isPlacement는 true여야 함');
        Assert.areEqual(false, result.hasEditPermission, 'Placement는 편집 권한 없음(false)이어야 함');
    }
    
    // ============================================================
    // [특이] Placement Declaration / Treaty → picklist 전체
    // ============================================================
    
    /**
     * @description [특이] Placement.TransactionType__c = 'Declaration' → picklist 기반 currency options 반환
     */
    @IsTest
    static void testGetContainerData_Placement_Declaration_UsePicklist() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c  = opp.Id,
        OwnerId            = UserInfo.getUserId(),
        TransactionType__c = 'Declaration'
            );
        insert placement;
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isTrue(result.isPlacement, 'isPlacement가 true여야 함');
        Assert.isFalse(result.currencyOptions.isEmpty(), 'Declaration Placement는 picklist 기반 currency options를 반환해야 함');
    }
    
    /**
     * @description [특이] Placement.CedingType1__c = 'Treaty' → picklist 기반 currency options 반환
     */
    @IsTest
    static void testGetContainerData_Placement_Treaty_UsePicklist() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId(),
        CedingType1__c    = 'Treaty'
            );
        insert placement;
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isTrue(result.isPlacement, 'isPlacement가 true여야 함');
        Assert.isFalse(result.currencyOptions.isEmpty(), 'CedingType1__c=Treaty Placement는 picklist 기반 currency options를 반환해야 함');
    }
    
    // ============================================================
    // [특이] Placement END (Endorsement) → Cedant Endorsement SlipInfo 기반
    // ============================================================
    
    /**
     * @description [특이] END + Cedant Endorsement 슬립 존재 → 해당 통화 반환
     */
    @IsTest
    static void testGetContainerData_Placement_END_EndorsementSlip() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId(),
        TransactionType__c = 'END'
            );
        insert placement;
        
        OPP_SlipInfo__c slipInfo = createSlipInfo(opp.Id, placement.Id, 'Cedant Endorsement', true);
        createPremiumSchedule(slipInfo.Id, 'SGD');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isFalse(result.currencyOptions.isEmpty(), 'END Placement: Cedant Endorsement 슬립 기반 통화가 반환되어야 함');
        Assert.areEqual(1, result.currencyOptions.size(), '1개 통화가 반환되어야 함');
        Assert.areEqual('SGD', result.currencyOptions[0].value, 'SGD 옵션이 반환되어야 함');
    }
    
    /**
     * @description [특이] END + Cedant Endorsement 슬립 없음 → 빈 목록 반환 (Offer/Closing 사용 안 함)
     */
    @IsTest
    static void testGetContainerData_Placement_END_NoEndorsementSlip_ReturnsEmpty() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c  = opp.Id,
        OwnerId            = UserInfo.getUserId(),
        TransactionType__c = 'END'
            );
        insert placement;
        
        // Cedant Offer 슬립만 존재 → END 케이스에서는 사용 안 함
        OPP_SlipInfo__c slipInfo = createSlipInfo(opp.Id, placement.Id, 'Cedant Offer', true);
        createPremiumSchedule(slipInfo.Id, 'EUR');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isTrue(result.currencyOptions.isEmpty(), 'END 케이스에서 Cedant Endorsement 슬립이 없으면 빈 목록이어야 함');
    }
    
    // ============================================================
    // [일반] Placement - Closing / Offer fallback + Panel Currency 병합
    // ============================================================
    
    /**
     * @description [일반] Placement - Cedant Closing 슬립 존재 시 해당 통화 반환
     */
    @IsTest
    static void testGetContainerData_Placement_General_CedantClosing() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_SlipInfo__c closingSlip = createSlipInfo(opp.Id, placement.Id, 'Cedant Closing', true);
        createPremiumSchedule(closingSlip.Id, 'GBP');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isFalse(result.currencyOptions.isEmpty(), 'Cedant Closing 기반 currency options가 있어야 함');
        Assert.areEqual(1, result.currencyOptions.size(), '1개 통화가 반환되어야 함');
        Assert.areEqual('GBP', result.currencyOptions[0].value, 'GBP가 반환되어야 함');
    }
    
    /**
     * @description [일반] Placement - Cedant Closing 없을 때 Cedant Offer fallback
     */
    @IsTest
    static void testGetContainerData_Placement_General_FallbackToOffer() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_SlipInfo__c offerSlip = createSlipInfo(opp.Id, placement.Id, 'Cedant Offer', true);
        createPremiumSchedule(offerSlip.Id, 'AUD');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isFalse(result.currencyOptions.isEmpty(), 'Cedant Closing 없으면 Cedant Offer fallback 되어야 함');
        Assert.areEqual(1, result.currencyOptions.size(), '1개 통화가 반환되어야 함');
        Assert.areEqual('AUD', result.currencyOptions[0].value, 'AUD가 반환되어야 함');
    }
    
    /**
     * @description [일반] Placement - OPP_Panel__c Currency__c 가 options에 병합되는지 검증
     */
    @IsTest
    static void testGetContainerData_Placement_General_IncludesPanelCurrency() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId()
            );
        insert placement;
        
        // Slip 통화
        OPP_SlipInfo__c closingSlip = createSlipInfo(opp.Id, placement.Id, 'Cedant Closing', true);
        createPremiumSchedule(closingSlip.Id, 'GBP');
        
        // Panel 통화 (다른 통화로 병합 검증)
        createPlacementPanel(opp.Id, placement.Id, 'JPY');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Set<String> returnedCurrencies = new Set<String>();
        for (COM_Option opt : result.currencyOptions) {
            returnedCurrencies.add(opt.value);
        }
        
        Assert.areEqual(2, result.currencyOptions.size(), 'Slip + Panel 통화 합산 2개여야 함');
        Assert.isTrue(returnedCurrencies.contains('GBP'), 'Slip 통화 GBP가 포함되어야 함');
        Assert.isTrue(returnedCurrencies.contains('JPY'), 'Panel 통화 JPY가 포함되어야 함');
    }
    
    /**
     * @description [일반] Placement - Panel 통화가 Slip 통화와 동일할 경우 중복 제거 검증
     */
    @IsTest
    static void testGetContainerData_Placement_General_PanelCurrencyDeduplicated() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_SlipInfo__c closingSlip = createSlipInfo(opp.Id, placement.Id, 'Cedant Closing', true);
        createPremiumSchedule(closingSlip.Id, 'GBP');
        
        // Panel 통화가 Slip 통화와 동일 → Set 중복 제거
        createPlacementPanel(opp.Id, placement.Id, 'GBP');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.currencyOptions.size(), 'Slip·Panel 통화가 동일하면 중복 제거 후 1개여야 함');
        Assert.areEqual('GBP', result.currencyOptions[0].value, 'GBP 1개가 반환되어야 함');
    }
    
    // ============================================================
    // [특이] Opportunity Treaty / CIDetail → picklist 전체
    // ============================================================
    
    /**
     * @description [특이] Opportunity.CedingType1__c = 'Treaty' → picklist 기반 currency options 반환
     */
    @IsTest
    static void testGetContainerData_Opportunity_Treaty_UsePicklist() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.CedingType1__c = 'Treaty';
        update opp;
        
        delete [SELECT Id FROM OPP_PremiumSchedule__c];
        delete [SELECT Id FROM OPP_SlipInfo__c WHERE Opportunity_lk__c = :opp.Id];
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(opp.Id);
        Test.stopTest();
        
        Assert.isFalse(result.isPlacement, 'Opportunity이므로 isPlacement는 false여야 함');
        Assert.isFalse(result.currencyOptions.isEmpty(), 'Treaty Opportunity는 picklist 기반 currency options를 반환해야 함');
    }
    
    // ============================================================
    // [일반] Opportunity - Closing / Offer fallback + Panel Currency 병합
    // ============================================================
    
    /**
     * @description [일반] Opportunity - OPP_Panel__c Currency__c 가 options에 병합되는지 검증
     */
    @IsTest
    static void testGetContainerData_Opportunity_General_IncludesPanelCurrency() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Id rtId = getOpportunityRtId();
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Opp for Panel Test', rtId, true);
        
        // Closing Slip 통화
        OPP_SlipInfo__c closingSlip = new OPP_SlipInfo__c(
            Opportunity_lk__c = opp.Id,
        Type__c           = 'Cedant Closing',
        Latest_is__c      = true
            );
        insert closingSlip;
        createPremiumSchedule(closingSlip.Id, 'EUR');
        
        // Panel 통화 (다른 통화로 병합 검증)
        createOppPanel(opp.Id, 'CHF');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(opp.Id);
        Test.stopTest();
        
        Set<String> returnedCurrencies = new Set<String>();
        for (COM_Option opt : result.currencyOptions) {
            returnedCurrencies.add(opt.value);
        }
        
        Assert.areEqual(2, result.currencyOptions.size(), 'Slip + Panel 통화 합산 2개여야 함');
        Assert.isTrue(returnedCurrencies.contains('EUR'), 'Slip 통화 EUR가 포함되어야 함');
        Assert.isTrue(returnedCurrencies.contains('CHF'), 'Panel 통화 CHF가 포함되어야 함');
    }
    
    /**
     * @description [일반] Opportunity - Panel 통화가 Slip 통화와 동일할 경우 중복 제거 검증
     */
    @IsTest
    static void testGetContainerData_Opportunity_General_PanelCurrencyDeduplicated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Id rtId = getOpportunityRtId();
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Opp for Panel Dedup Test', rtId, true);
        
        OPP_SlipInfo__c closingSlip = new OPP_SlipInfo__c(
            Opportunity_lk__c = opp.Id,
        Type__c           = 'Cedant Closing',
        Latest_is__c      = true
            );
        insert closingSlip;
        createPremiumSchedule(closingSlip.Id, 'EUR');
        
        // Panel 통화 동일 → 중복 제거
        createOppPanel(opp.Id, 'EUR');
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(opp.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.currencyOptions.size(), 'Slip·Panel 통화가 동일하면 중복 제거 후 1개여야 함');
        Assert.areEqual('EUR', result.currencyOptions[0].value, 'EUR 1개가 반환되어야 함');
    }
    
    // ============================================================
    // Placement - Co-broker 조건
    // ============================================================
    
    @IsTest
    static void testGetContainerData_PlacementId_CobrokerConditions() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Placement__c placement = new Placement__c(
            Opportunity_lk__c = opp.Id,
        OwnerId           = UserInfo.getUserId()
            );
        insert placement;
        
        OPP_Cobroker__c cb = OPP_TestDataFactory.createCobroker(
            opp.Id,
        OPP_TestDataFactory.COBROKER_EXT_PRODUCING_SEP_CLIENT,
        false
            );
        cb.Placement_lk__c = placement.Id;
        insert cb;
        
        Test.startTest();
        Opp_MarketLineContainer_Ctrl.ContainerDataWrapper result =
            Opp_MarketLineContainer_Ctrl.getContainerData(placement.Id);
        Test.stopTest();
        
        Assert.isTrue(result.hasProducingCobroker,       'Placement 기준 Producing Cobroker가 있어야 함');
        Assert.isTrue(result.satisfiesCIDetailCondition, 'Placement 기준 CI Detail 조건이 만족되어야 함');
    }
    
    // ============================================================
    // Exception
    // ============================================================
    
    @IsTest
    static void testGetContainerData_throws() {
        User u = COM_TestDataFactory.createMinAccessUser(true);
        Account acc = ACC_TestDataFactory.createAccount('Test Account for Exception', 'General', true);
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, null, true);
        
        Boolean thrown = false;
        System.runAs(u) {
            try {
                Opp_MarketLineContainer_Ctrl.getContainerData(opp.Id);
            } catch (AuraHandledException e) {
                thrown = true;
            }
        }
        
        Assert.isTrue(thrown, 'SECURITY_ENFORCED must throw');
    }
}