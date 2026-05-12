/**********************************************************************************
 * @filename      : OPP_MarketLineWrapper_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-07 (토)
 * @group         :
 * @group-content :
 * @description   :
 * @target-class  :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-07      i2max     Create
**********************************************************************************/
@IsTest
private class OPP_MarketLineWrapper_ts {

    @IsTest
    static void testGridMeta() {
        OPP_MarketLineWrapper.GridMeta meta = new OPP_MarketLineWrapper.GridMeta();
        meta.columns = new List<OPP_MarketLineWrapper.ColMeta>();
        meta.rows = new List<OPP_MarketLineWrapper.LayerItem>();
        meta.ctx = new Map<String, Object>{ 'oppId' => '006000000000000' };
        meta.isOpp = true;
        meta.isPlacement = true;
        meta.isClaim = false;
        meta.isCICase = false;
        meta.isReadOnly = false;
        meta.claimCurrency = 'USD';

        Assert.isTrue(meta.isOpp);
        Assert.isTrue(meta.isPlacement);
        Assert.isFalse(meta.isClaim);
        Assert.isFalse(meta.isCICase);
        Assert.isFalse(meta.isReadOnly);
        Assert.areEqual('USD', meta.claimCurrency);
        Assert.isNotNull(meta.columns);
        Assert.isNotNull(meta.rows);
        Assert.isNotNull(meta.ctx);
    }

    @IsTest
    static void testColMetaVirtual() {
        OPP_MarketLineWrapper.ColMeta col = new OPP_MarketLineWrapper.ColMeta(
                'VirtualKey', null, OPP_MarketLineWrapper.CellMode.EDIT,
                'Group1'
        ).formula('test');
        Assert.areEqual('VirtualKey', col.key);
        Assert.areEqual('edit', col.mode);
        Assert.areEqual('text', col.type);
        Assert.areEqual(OPP_MarketLineWrapper.WIDTH_DEFAULT, col.width);
        Assert.areEqual(1, col.rowSpan);
        Assert.isFalse(col.required);
        Assert.isTrue(col.groupCollapsible);
        Assert.isFalse(col.collapsed);

        col.label('NewLabel')
                .width(200)
                .rowSpan(2)
                .required()
                .groupPrimary()
                .collapsed(true)
                .groupCollapsible(false)
                .zeroDisplayText('-')
                .filter('Active__c', true)
                .dependsOn(new List<String>{
                        'Reinsurer_lk__c'
                })
                .viewMode();

        Assert.areEqual('NewLabel', col.label);
        Assert.areEqual(200, col.width);
        Assert.areEqual(2, col.rowSpan);
        Assert.isTrue(col.required);
        Assert.isTrue(col.groupPrimary);
        Assert.isTrue(col.collapsed);
        Assert.isFalse(col.groupCollapsible);
        Assert.areEqual('-', col.zeroDisplayText);
        Assert.areEqual('Active__c', col.filterField);
        Assert.areEqual(true, col.filterValue);
        Assert.areEqual(1, col.depends.size());
        Assert.areEqual('view', col.mode);

        col.editMode();
        Assert.areEqual('edit', col.mode);
        col.hiddenMode();
        Assert.areEqual('hidden', col.mode);
    }

    @IsTest
    static void testColMetaSObjectField() {
        OPP_MarketLineWrapper.ColMeta col = new OPP_MarketLineWrapper.ColMeta(
                OPP_Panel__c.GrossPrem__c, OPP_MarketLineWrapper.CellMode.VIEW,
                'GrpPrem'
        ).scale(2);
        Assert.areEqual('GrossPrem__c', col.key);
        Assert.areEqual('view', col.mode);
        Assert.areEqual('num', col.type);
        Assert.isNotNull(col.scale);

        col.type(OPP_MarketLineWrapper.CellType.percent);
        Assert.areEqual('percent', col.type);

        OPP_MarketLineWrapper.ColMeta lookupCol = new
                OPP_MarketLineWrapper.ColMeta(
                        'virtualLookup', null, OPP_MarketLineWrapper.CellMode.EDIT,
                        'Grp'
                );
        lookupCol.lookup('Account',
                'Name').lookupLabelField('Name').parentField('Reinsurer_lk__c');
        Assert.areEqual('lookup', lookupCol.type);
        Assert.areEqual('Account', lookupCol.lookupObject);
        Assert.areEqual('Name', lookupCol.lookupLabelField);
        Assert.areEqual('Reinsurer_lk__c', lookupCol.parentField);
        Assert.areEqual(OPP_MarketLineWrapper.WIDTH_LOOKUP, lookupCol.width);
    }

    @IsTest
    static void testColMetaInvalidKey() {
        Boolean thrown = false;
        try {
            new OPP_MarketLineWrapper.ColMeta(
                    '1InvalidKey', null, OPP_MarketLineWrapper.CellMode.EDIT,
                    'Grp'
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'invalid key pattern should throw');
    }

    @IsTest
    static void testLayerItem() {
        OPP_Layer__c layer = new OPP_Layer__c(
                Type__c = 'LayerType',
                LOL__c = 1000,
                Excess__c = 500,
                LayerCurrency__c = 'USD'
        );

        OPP_MarketLineWrapper.LayerItem item = new
                OPP_MarketLineWrapper.LayerItem(layer);
        item.Id = 'tmp_layer_1';

        Assert.areEqual('tmp_layer_1', item.Id);
        Assert.isFalse(item.isDeleted);
        Assert.areEqual('LayerType', item.layerValues.get('Type__c'));
        Assert.areEqual(1000, item.layerValues.get('LOL__c'));
        Assert.areEqual(500, item.layerValues.get('Excess__c'));
        Assert.areEqual('USD', item.layerValues.get('LayerCurrency__c'));
        Assert.areEqual(1, item.layerRowSpan);
    }

    @IsTest
    static void testMarketLineItem() {
        OPP_Panel__c panel = new OPP_Panel__c(
                Currency__c = 'USD',
                MarketType__c = 'Facility',
                GrossPrem__c = 10000,
                NetToUW__c = 8000,
                ClmNetRI__c = 5000,
                ClmNetToPlacingTPP__c = 1500,
                ClmNetToPlacingTPPLK__c = 1500
        );

        OPP_MarketLineWrapper.MarketLineItem item = new
                OPP_MarketLineWrapper.MarketLineItem(panel);
        item.Id = 'tmp_panel_1';

        Assert.areEqual('tmp_panel_1', item.Id);
        Assert.isFalse(item.isDeleted);
        Assert.areEqual('USD', item.values.get('Currency__c'));
        Assert.areEqual('Facility', item.values.get('MarketType__c'));
        Assert.areEqual(10000, item.values.get('GrossPrem__c'));
        Assert.areEqual(8000, item.values.get('NetToUW__c'));
        Assert.areEqual(5000, item.values.get('ClmNetRI__c'));
        Assert.areEqual(1500, item.values.get('ClmNetToPlacingTPP__c'));
        Assert.areEqual(1500, item.values.get('ClmNetToPlacingTPPLK__c'));
    }

    @IsTest
    static void testColMetaPicklistField() {
        OPP_MarketLineWrapper.ColMeta col = new OPP_MarketLineWrapper.ColMeta(
                OPP_Layer__c.Type__c,
                OPP_MarketLineWrapper.CellMode.EDIT,
                'GrpMarket'
        ).groupName('GrpMarket').options(COM_Util.makePickListOptions('OPP_Layer__c', 'Type__c', true, false, new Set<String>{'Brkg Adj'}));
        Assert.areEqual('Type__c', col.key);
        Assert.areEqual('picklist', col.type);
        Assert.isNotNull(col.options);

        col = new OPP_MarketLineWrapper.ColMeta(
                OPP_Panel__c.Reinsurer_lk__c,
                OPP_MarketLineWrapper.CellMode.EDIT,
                'GrpMarket'
        ).multi(false);
        Assert.areEqual('lookup', col.type);

        col = new OPP_MarketLineWrapper.ColMeta(
                OPP_Panel__c.Others__c,
                OPP_MarketLineWrapper.CellMode.EDIT,
                'GrpMarket'
        ).multi(false);
        Assert.areEqual('richtext', col.type);

        col = new OPP_MarketLineWrapper.ColMeta(
                OPP_Panel__c.Name,
                OPP_MarketLineWrapper.CellMode.EDIT,
                'GrpMarket'
        ).multi(false);
        Assert.areEqual('text', col.type);

    }

}