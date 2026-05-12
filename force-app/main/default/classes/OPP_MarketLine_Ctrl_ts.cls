/**********************************************************************************
 * @filename      : OPP_MarketLine_Ctrl_ts.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-14 (수)
 * @group         :
 * @group-content :
 * @description   : OPP_MarketLine_Ctrl Test Class
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-14      i2max     Create
 **********************************************************************************/
@IsTest
private class OPP_MarketLine_Ctrl_ts {

    final static String SELECTED_CURRENCY = 'USD';

    @TestSetup
    static void setup() {

        Account acc = (Account) COM_TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Name' => 'Test Account'
        }, true);

        // 2. Opportunity 생성
        Opportunity opp = OPP_TestDataFactory.createOpportunity(acc.Id, 'Test Opp', true);

        // 3. Layer 생성
        OPP_Layer__c layer = OPP_TestDataFactory.createLayer(opp.Id, true);

        // 4. Panel 생성
        OPP_TestDataFactory.createPanel(layer.Id, true);

        // 5. Co-broker 생성
        OPP_TestDataFactory.createCobroker(
                opp.Id,
                OPP_TestDataFactory.COBROKER_EXT_PLACING_SEP,
                true
        );
    }

    @IsTest
    static void testInitMeta() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OPP_MarketLineWrapper.GridMeta meta = OPP_MarketLine_Ctrl.initMeta(opp.Id, SELECTED_CURRENCY);
        Test.stopTest();

        System.assertNotEquals(null, meta, 'Meta should not be null');
        System.assertNotEquals(null, meta.columns, 'Columns should not be null');
        System.assertNotEquals(null, meta.rules, 'Rules should not be null');
        System.assertNotEquals(null, meta.ctx, 'Ctx should not be null');
    }

    @IsTest
    static void testRefreshCtx() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> ctx = OPP_MarketLine_Ctrl.refreshCtx(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, ctx, 'Ctx should not be null');
        System.assert(ctx.containsKey('ctx_producingSharingPct'), 'Ctx should contain ctx_producingSharingPct');
    }

    @IsTest
    static void testQueryRows() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<OPP_MarketLineWrapper.LayerItem> items = OPP_MarketLine_Ctrl.queryRows(opp.Id, SELECTED_CURRENCY);
        Test.stopTest();

        System.assertNotEquals(null, items, 'Items should not be null');
        System.assertEquals(1, items.size(), 'Should return 1 layer item');
        System.assertEquals(1, items[0].marketLineItems.size(), 'Should return 1 panel item');
    }
    @IsTest
    static void testSaveRows() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_Layer__c layer = [SELECT Id FROM OPP_Layer__c LIMIT 1];
        OPP_Panel__c panel = [SELECT Id FROM OPP_Panel__c LIMIT 1];

        // Prepare data for save
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Map<String, Object> row = new Map<String, Object>();
        row.put('layerId', layer.Id);
        row.put('panelId', panel.Id);
        row.put('isDeleted', false);
        row.put('Written__c', 50);
        row.put('Signed__c', 50);
        rows.add(row);

        String jsonString = JSON.serialize(rows);

        Test.startTest();
        List<OPP_MarketLineWrapper.LayerItem> items = OPP_MarketLine_Ctrl.saveRows(opp.Id, false, jsonString, SELECTED_CURRENCY, false);
        Test.stopTest();

        System.assertNotEquals(null, items, 'Items should not be null');
        OPP_Panel__c updatedPanel = [SELECT Written__c FROM OPP_Panel__c WHERE Id = :panel.Id];
        System.assertEquals(50, updatedPanel.Written__c, 'Written__c should be updated');

        items = OPP_MarketLine_Ctrl.saveRows(opp.Id, false, jsonString, SELECTED_CURRENCY, true);
    }

    @IsTest
    static void testSaveRows_NewLayerAndPanel() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Prepare data for new layer and panel
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Map<String, Object> row = new Map<String, Object>();
        String tempLayerId = 'tmp_layer_1';
        String tempPanelId = 'tmp_panel_1';

        row.put('layerId', tempLayerId);
        row.put('panelId', tempPanelId);
        row.put('isDeleted', false);
        row.put('Type__c', 'Primary'); // Layer Field
        row.put('MarketType__c', 'Facility'); // Panel Field
        rows.add(row);

        String jsonString = JSON.serialize(rows);

        Test.startTest();
        List<OPP_MarketLineWrapper.LayerItem> items = OPP_MarketLine_Ctrl.saveRows(opp.Id, false, jsonString, SELECTED_CURRENCY, false);
        Test.stopTest();

        System.assertNotEquals(null, items, 'Items should not be null');
        // Expecting 2 layers now (1 existing + 1 new)
        System.assertEquals(2, items.size(), 'Should return 2 layer items');
    }

    @IsTest
    static void testSaveRows_DeletePanel() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_Layer__c layer = [SELECT Id FROM OPP_Layer__c LIMIT 1];
        OPP_Panel__c panel = [SELECT Id FROM OPP_Panel__c LIMIT 1];

        // Prepare data for delete
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Map<String, Object> row = new Map<String, Object>();
        row.put('layerId', layer.Id);
        row.put('panelId', panel.Id);
        row.put('isDeleted', true);
        rows.add(row);

        String jsonString = JSON.serialize(rows);

        Test.startTest();
        List<OPP_MarketLineWrapper.LayerItem> items = OPP_MarketLine_Ctrl.saveRows(opp.Id, false, jsonString, SELECTED_CURRENCY, false);
        Test.stopTest();

        List<OPP_Panel__c> panels = [SELECT Id FROM OPP_Panel__c WHERE Id = :panel.Id];
        System.assertEquals(0, panels.size(), 'Panel should be deleted');
        OPP_MarketLine_Ctrl.checkNeedRecalculate(opp.Id);

        Map<String, SObjectType> sObjectTypeMap = Schema.getGlobalDescribe();
        Map<String, SObjectField> layerFields = sObjectTypeMap.get('OPP_Layer__c').getDescribe().fields.getMap();
        Map<String, SObjectField> panelFields = sObjectTypeMap.get('OPP_Panel__c').getDescribe().fields.getMap();
    }

    @IsTest
    static void testCICase() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_TestDataFactory.createCobroker(
                opp.Id,
                OPP_TestDataFactory.COBROKER_EXT_PRODUCING_SEP_CLIENT,
                true
        );
        delete [SELECT Id FROM OPP_Layer__c WHERE Opportunity_md__c =:opp.Id];

        Test.startTest();
        OPP_MarketLine_Ctrl.initMeta(opp.Id, SELECTED_CURRENCY);
        Test.stopTest();
    }

    @IsTest
    static void testBuildCtx_Placement() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OPP_Layer__c layer = [SELECT Id FROM OPP_Layer__c LIMIT 1];
        OPP_Panel__c panel = [SELECT Id FROM OPP_Panel__c LIMIT 1];

        Placement__c placement = OPP_TestDataFactory.createPlacement(opp.Id, false);
        placement.InceptionDate__c = Date.today().addMonths(3);
        placement.TransactionType__c = 'Declaration';
        insert placement;

        layer.Placement_lk__c = placement.Id;
        update layer;

        // Prepare data for new layer and panel
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Map<String, Object> row = new Map<String, Object>();
        String tempLayerId = 'tmp_layer_1';
        String tempPanelId = 'tmp_panel_1';

        row.put('layerId', tempLayerId);
        row.put('panelId', tempPanelId);
        row.put('isDeleted', false);
        row.put('Type__c', 'Primary'); // Layer Field
        row.put('MarketType__c', 'Facility'); // Panel Field
        rows.add(row);

        String jsonString = JSON.serialize(rows);

        Test.startTest();
        List<OPP_MarketLineWrapper.LayerItem> items = OPP_MarketLine_Ctrl.saveRows(placement.Id, false, jsonString, SELECTED_CURRENCY, false);
        Test.stopTest();

        OPP_MarketLine_Ctrl.checkNeedRecalculate(placement.Id);
    }


    @IsTest
    static void testBuildCtx_Claim() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Claim claim = OPP_TestDataFactory.createClaim('Claim Test', false);
        insert claim;

        Test.startTest();
        OPP_MarketLine_Ctrl.initMeta(claim.Id, SELECTED_CURRENCY);
        OPP_MarketLine_Ctrl.checkNeedRecalculate(claim.Id);
        Test.stopTest();
    }

}