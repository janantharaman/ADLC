/**********************************************************************************
 * @filename      : OPP_MarketLine_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketLine_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-07      i2max     Create
 **********************************************************************************/
public with sharing class OPP_MarketLine_Ctrl {

    private static final OPP_MarketLineWrapper.CellMode EDIT_MODE = OPP_MarketLineWrapper.CellMode.EDIT;
    private static final OPP_MarketLineWrapper.CellMode VIEW_MODE = OPP_MarketLineWrapper.CellMode.VIEW;
    private static final OPP_MarketLineWrapper.CellMode HIDDEN_MODE = OPP_MarketLineWrapper.CellMode.HIDDEN;
    private static final OPP_MarketLineWrapper.CellType BUTTON_TYPE = OPP_MarketLineWrapper.CellType.button;
    private static final OPP_MarketLineWrapper.CellType PERCENT_TYPE = OPP_MarketLineWrapper.CellType.percent;

    public static final String SETT_TYPE_SEPARATE = 'Separate';
    public static final String SETT_TYPE_TOGETHER = 'Together';

    private static final String GRP_LAYER = Label.OPP_LBL_GRP_LAYER;
    private static final String GRP_MARKET = Label.OPP_LBL_GRP_MARKET;
    private static final String GRP_LINE = Label.OPP_LBL_GRP_LINE_PCT;
    private static final String GRP_RI_PREMIUM = Label.OPP_LBL_GRP_RI_PREMIUM;
    private static final String GRP_TOTAL_BRKG = Label.OPP_LBL_GRP_TOTAL_BRKG;
    private static final String GRP_PRODUCING = Label.OPP_LBL_GRP_PRODUCING;
    private static final String GRP_PRODUCING_LK = Label.OPP_LBL_GRP_PRODUCING_LK;
    private static final String GRP_PLACING = Label.OPP_LBL_GRP_PLACING;
    private static final String GRP_PLACING_LK = Label.OPP_LBL_GRP_PLACING_LK;
    private static final String GRP_BRKG_AMT = Label.OPP_LBL_GRP_BRKG_AMT;
    private static final String GRP_ADMIN_FEE = Label.OPP_LBL_GRP_ADMIN_FEE;
    private static final String GRP_SETTLEMENT = Label.OPP_LBL_GRP_SETTLEMENT;
    private static final String GRP_SETTLEMENT_CLM = Label.OPP_LBL_GRP_SETTLEMENT_CLM;
    private static final String GRP_CONTACT = Label.OPP_LBL_GRP_CONTACT;

    private static final Map<String, List<String>> CTX_HIDDEN_COLS_MAP = new Map<String, List<String>>{
            'ctx_hasProducing'    => new List<String>{ 'ProducingSharingPct__c', 'ProducingTPPAdminFeePct__c', 'ProducingTPPBrkg__c' },
            'ctx_hasLKProducing'  => new List<String>{ 'LKProducingSharingPct__c', 'LKProducingTPPBrkg__c' },
            'ctx_hasLKPlacing'    => new List<String>{ 'LKPlacingSharingPct__c', 'LKPlacingTPPBrkg__c', 'LKNetPlacingTPP__c' },
            'ctx_hasProducingSeparateNonClient'   => new List<String>{ 'NetProducingTPP__c' },
            'ctx_hasLKProducingSeparateNonClient' => new List<String>{ 'LKNetProducingTPP__c' },
            'ctx_isProducingTogetherClient' => new List<String>{ 'NetProducingCobrker__c' }
    };

    private static final Set<String> TREATY_EDITABLE_FIELDS = new Set<String>{
            'LOL__c', 'Excess__c',
            'Written__c', 'Signed__c',
            'GrossPremDP__c', 'DPPct__c', 'GrossPrem__c', 'RICommPct__c', 'OtherDeductionPct__c',
            'BrkgBase__c', 'TotalBrkgPct__c', 'TotalBrkg__c',
            'NetProducingCobrker__c', 'NetToLKPrem__c', 'NetToUW__c',
            'LKReBrkge__c', 'ProducingTPPBrkg__c', 'LKProducingTPPBrkg__c', 'PlacingTPPBrkge__c',
            'ActualAdjRatePct__c', 'LKReBrkge__c', 'ProducingTPPBrkg__c',
            'LKPlacingTPPBrkg__c', 'ToProducingAdminFee__c', 'ToLKAdminFee__c',
            'NetRI__c', 'NetProducingTPP__c', 'LKNetProducingTPP__c', 'NetPlacingTPP__c', 'LKNetPlacingTPP__c',
            'ClmNetRI__c', 'ClmNetToPlacingTPP__c', 'ClmNetToPlacingTPPLK__c'
    };

    // Co-Broker 조회 시 적용할 공통 필터 (내부사 제외 및 브로커 타입만 조회)
    private static final Map<String, Object> CO_BROKER_FILTER = new Map<String, Object>{
            'LKInternalCompany_is__c' => false,
            'InsuredType__c' => 'broker'
    };

    private static OPP_MarketLineWrapper.ColMeta colMeta(SObjectField field, OPP_MarketLineWrapper.CellMode mode, String groupName) {
        return new OPP_MarketLineWrapper.ColMeta(field, mode, groupName);
    }

    private static OPP_MarketLineWrapper.ColMeta colMeta(String key, SObjectField field, OPP_MarketLineWrapper.CellMode mode, String groupName) {
        return new OPP_MarketLineWrapper.ColMeta(key, field, mode, groupName);
    }
    // LayerItem 생성 팩토리
    private static OPP_MarketLineWrapper.LayerItem layerItem(OPP_Layer__c layer) {
        return new OPP_MarketLineWrapper.LayerItem(layer);
    }

    // MarketLineItem 생성 팩토리
    private static OPP_MarketLineWrapper.MarketLineItem marketLineItem(OPP_Panel__c panel) {
        return new OPP_MarketLineWrapper.MarketLineItem(panel);
    }

    @AuraEnabled(Cacheable=false)
    public static OPP_MarketLineWrapper.GridMeta initMeta(Id recordId, String selectedCurrency) {
        /*
        MarketLineGrid 사용 개체
        1. Opportunity => IsClosed=true 이면 ReadOnly
        2. Placement => PerformanceInputType__c =='Confirm'
        3. Claim => Close??
         */
        if (recordId == null) throw new AuraHandledException('recordId is required.');

        OPP_MarketLineWrapper.GridMeta meta = new OPP_MarketLineWrapper.GridMeta();
        OPP_MarketLineContext mlCtx = new OPP_MarketLineContext(recordId);

        meta.claimCurrency = mlCtx.claimCurrency;
        meta.isOpp = mlCtx.isOpp;
        meta.isPlacement = mlCtx.isPlacement;
        meta.isClaim = mlCtx.isClaim;
        meta.isReadOnly = mlCtx.isReadOnly;
        meta.isCICase = mlCtx.isCICase;
        meta.isTreaty = mlCtx.isTreaty;

        Map<String, SObjectType> sObjectTypeMap = Schema.getGlobalDescribe();
        Map<String, SObjectField> layerFields = sObjectTypeMap.get('OPP_Layer__c').getDescribe().fields.getMap();
        Map<String, SObjectField> panelFields = sObjectTypeMap.get('OPP_Panel__c').getDescribe().fields.getMap();

        List<OPP_MarketLineWrapper.ColMeta> raw = (mlCtx.isClaim ? getClaimColumns(panelFields, layerFields) : (mlCtx.isCICase ? getCICaseColumns(panelFields) : getStandardColumns(panelFields, layerFields)));
        // 기회이고 CI Case이거나 또는 기회가 아니면 LayerAction, MLAction 제거
        // [26-04-12] Placement일 때 Layer 추가/삭제 및 Panel 추가/삭제 가능으로 변경
        Set<String> excludeMeta = new Set<String>{
                'LayerAction', 'MLAction'
        };
        if (!mlCtx.isClaim && ((mlCtx.isOpp && mlCtx.isCICase) || !mlCtx.isOpp) && !mlCtx.isPlacement) {
            for (Integer i = raw.size() - 1; i >= 0; i--) {
                if (excludeMeta.contains(raw[i].key)) raw.remove(i);
            }
        }
        //[26-04-12] Placement 일때도 등록 가능하게 변경
//        if(mlCtx.isPlacement) {
//            String viewMode = VIEW_MODE.toString().toLowerCase();
//            Set<String> viewMeta = new Set<String>{
//                    'DPPct__c', 'GrossPremDP__c',
//                    'MarketType__c', 'Reinsurer_lk__c',
//                    'CoBroker_lk__c', 'PlacingSharingPct__c', 'PlacingTPPAdminFeePct__c', 'PlacingSettlementType__c',
//                    'LKProducingSharingPct__c', 'LKPlacingSharingPct__c'
//            };
//            for (OPP_MarketLineWrapper.ColMeta col : raw) {
//                if (viewMeta.contains(col.key) && !col.mode.equals(viewMode)) col.viewMode();
//            }
//        }

//        Map<String, Object> calcCtx = OPP_MarketLineService.buildCtx(recordId);
        Map<String, Object> calcCtx = OPP_MarketLineService.buildCtx(mlCtx);
        /*
        0. Opportunity.isClosed = true 일 때 => 모든 Cell 수정 불가, Placement는 특정 Status일때 반영 예정
        1. Producing Co-broking 존재(key: ctx_hasProducing): ProducingSharingPct__c, ProducingTPPAdminFeePct__c, ProducingTPPBrkg__c 필드 Visible, 그 외는 Hidden
        2. LK Producing Co-broking 존재(key: ctx_hasLKProducing): LKProducingSharingPct__c, LKProducingTPPBrkg__c 필드 Visible, 그 외는 Hidden
        3. LK Placing Co-broking 존재(key: ctx_hasLKPlacing): LKPlacingSharingPct__c, LKPlacingTPPBrkg__c, LKNetPlacingTPP__c 필드 Visible, 그 외는 Hidden
         */
        String h_mode = HIDDEN_MODE.toString().toLowerCase();
        String v_mode = VIEW_MODE.toString().toLowerCase();

        if (mlCtx.isReadOnly) {
            for (OPP_MarketLineWrapper.ColMeta col : raw) {
                if (!col.mode.equals(h_mode)) col.viewMode();
            }
        }
        //[2026-04-20] 로직 추가, CedingType1__c == 'Treaty'
        if (!mlCtx.isReadOnly && meta.isTreaty) {
            System.debug('★ Treaty editMode block entered');
            for (OPP_MarketLineWrapper.ColMeta col : raw) {
                if (!h_mode.equalsIgnoreCase(col.mode) && v_mode.equalsIgnoreCase(col.mode) && TREATY_EDITABLE_FIELDS.contains(col.key)) {
                    System.debug('★ Treaty editMode: ' + col.key + ' before=' + col.mode);
                    col.editMode();
                    System.debug('★ Treaty editMode: ' + col.key + ' after=' + col.mode);
                }
            }
        }


        Set<String> colsToHide = new Set<String>();
        for (String ctxKey : CTX_HIDDEN_COLS_MAP.keySet()) {
            if (calcCtx.containsKey(ctxKey) && (Boolean) calcCtx.get(ctxKey) == false) {
                colsToHide.addAll(CTX_HIDDEN_COLS_MAP.get(ctxKey));
            }
        }

        for (OPP_MarketLineWrapper.ColMeta col : raw) {
            if (colsToHide.contains(col.key) && !col.mode.equals(h_mode)) {
                col.hiddenMode();
            }
        }

        meta.columns = raw;
        meta.rules = OPP_MarketLineRuleService.getRuleSet(mlCtx.isCICase);
        meta.ctx = calcCtx;
        meta.ctx.put('ctx_hiddenFields', colsToHide); // CTX_HIDDEN_COLS_MAP 기반 동적 hidden만
        meta.rows = queryRows(recordId, selectedCurrency); // 데이터 조회
        return meta;
    }

    // ctx만 갱신하는 엔드포인트: 화면에 "참조값 갱신" 버튼 붙일 때 사용
    @AuraEnabled(Cacheable=false)
    public static Map<String, Object> refreshCtx(Id recordId) {
        if (recordId == null) throw new AuraHandledException('recordId is required.');
        return OPP_MarketLineService.buildCtx(recordId);
    }

    // ========== 데이터 조회 ==========
    @AuraEnabled(Cacheable=false)
    public static List<OPP_MarketLineWrapper.LayerItem> queryRows(Id recordId, String selectedCurrency) {

        if (recordId == null) return new List<OPP_MarketLineWrapper.LayerItem>();

        System.debug('queryRows > init recordId=[' + recordId + '], selectedCurrency=['+ selectedCurrency +']');
        OPP_MarketLineContext mlCtx = new OPP_MarketLineContext(recordId);

        Id placementId = mlCtx.placementId;

        List<String> query = new List<String>();
        query.add('SELECT Id, Layer_md__c, Layer_md__r.Name, Layer_md__r.Type__c,');
        query.add('Layer_md__r.LayerCurrency__c, Layer_md__r.LOL__c, Layer_md__r.Excess__c,');
        query.add('Layer_md__r.Remarks__c, Layer_md__r.Layer_fm__c, Layer_md__r.Opportunity_md__c,');
        query.add('Finalize_is__c, BrkgAdj_is__c, CO_is__c,');
        query.add('Leader_is__c, MarketType__c,');
        query.add('Facility_lk__c, Facility_lk__r.Name, Facility_lk__r.ClaimOffset_is__c,');
        query.add('MGAName_lk__c, MGAName_lk__r.Name,');
        query.add('Reinsurer_lk__c, Reinsurer_lk__r.Name,');
        query.add('FacilityParticipant_lk__c,');
        query.add('Security_lk__c, Security_lk__r.Name,');
        query.add('Currency__c, Written__c, Signed__c,');
        query.add('GrossPremDP__c, DPPct__c, GrossPrem__c, ActualAdjRatePct__c,');
        query.add('RICommPct__c, OtherDeductionPct__c, NetToLKPrem__c,');
        query.add('BrkgBase__c, TotalBrkgPct__c, TotalBrkg__c,');
        query.add('CoBroker_lk__c, PlacingSharingPct__c, PlacingTPPAdminFeePct__c, PlacingSettlementType__c,');
        query.add('LKReBrkge__c, ProducingTPPBrkg__c, PlacingTPPBrkge__c, LKTPPBrkge__c,');
        query.add('LKAdminFee__c, LKCoBrokingSharing_is__c,');
        query.add('NetRI__c, NetProducingTPP__c, NetPlacingTPP__c, NetLKTPP__c,');
        query.add('ProducingSharingPct__c, ProducingTPPAdminFeePct__c,');
        query.add('CobrokingType__c, NetProducingCobrker__c,');
        query.add('LKPlacingTPPBrkg__c, ToProducingAdminFee__c, ToLKAdminFee__c,');
        query.add('LKNetPlacingTPP__c, LKPlacingSharingPct__c,');
        query.add('PPWType__c, PPWDays__c, PPWDate__c,');
        query.add('RIContact_lk__c, CoBrokerContact_lk__c,');
        query.add('Others__c, Subjectivity__c, LKProducingSharingPct__c,');
        query.add('NetToUW__c, ClmNetRI__c, ClmNetToPlacingTPP__c, ClmNetToPlacingTPPLK__c,');
        query.add('Seq__c');

        query.add('FROM OPP_Panel__c');

        if (mlCtx.isOpp) query.add('WHERE Layer_md__r.Opportunity_md__c=:recordId');
        if (mlCtx.isOpp) query.add('AND Layer_md__r.Placement_lk__c=NULL');

        if (mlCtx.isPlacement) query.add('WHERE Layer_md__r.Placement_lk__c=:recordId');
        if (mlCtx.isClaim) query.add('WHERE Layer_md__r.Placement_lk__c=:placementId');
        if (mlCtx.isClaim) query.add('AND Layer_md__r.Placement_lk__c!=NULL');
        //if(isClaim) query.add(' ');//AND CO_is__c = False AND BrkgAdj_is__c = False

//        if (String.isNotBlank(selectedCurrency)) query.add('AND Layer_md__r.LayerCurrency__c=:selectedCurrency');
        if (String.isNotBlank(selectedCurrency)) query.add('AND Currency__c=:selectedCurrency');
        query.add('WITH SECURITY_ENFORCED');
        query.add('ORDER BY BrkgAdj_is__c ASC, Layer_md__r.CreatedDate ASC, CreatedDate ASC');
        query.add('');

        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
        System.debug('queryRows > query=[' + String.join(query, ' ') + ']');
        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
        List<OPP_Panel__c> oppPanels = Database.query(String.join(query, ' '));
        System.debug('queryRows > oppPanels.size()=[' + oppPanels.size() + ']');

        List<OPP_Layer__c> oppLayers = new List<OPP_Layer__c>();
        Map<Id, List<OPP_Panel__c>> oppPanelsByIds = new Map<Id, List<OPP_Panel__c>>();
        for (OPP_Panel__c oppPanel : oppPanels) {
            if (oppPanelsByIds.containsKey(oppPanel.Layer_md__c) == false) {
                oppLayers.add(oppPanel.Layer_md__r);
                oppPanelsByIds.put(oppPanel.Layer_md__c, new List<OPP_Panel__c>());
            }
            if (oppPanelsByIds.containsKey(oppPanel.Layer_md__c)) oppPanelsByIds.get(oppPanel.Layer_md__c).add(oppPanel);
        }

        List<OPP_MarketLineWrapper.LayerItem> layerItems = new List<OPP_MarketLineWrapper.LayerItem>();
        for (OPP_Layer__c layer : oppLayers) {
            OPP_MarketLineWrapper.LayerItem layerItem = layerItem(layer);

            Boolean isCoOrBrkgAdj = false;
            if (oppPanelsByIds.containsKey(layer.Id)) {
                for (OPP_Panel__c panel : oppPanelsByIds.get(layer.Id)) {
                    layerItem.marketLineItems.add(marketLineItem(panel));
                    if (isCoOrBrkgAdj == false && (panel.CO_is__c || panel.BrkgAdj_is__c)) isCoOrBrkgAdj = true;
                }
            }
            if (isCoOrBrkgAdj) layerItem.layerValues.put('Layer_fm__c', '');
            layerItems.add(layerItem);
        }

        // CI Case이고 조회된 데이터가 없으면 빈 Row(Layer+Panel) 1세트 추가
        if (mlCtx.isOpp && mlCtx.isCICase && layerItems.isEmpty()) {
            String tmpLayerId = 'tmp_layer_' + String.valueOf(Datetime.now().getTime());
            String tmpPanelId = 'tmp_panel_' + String.valueOf(Datetime.now().getTime());

            List<OPP_Cobroker__c> oppCobrokers = [
                SELECT Id, SharingPct__c
                FROM OPP_Cobroker__c
                WHERE Opportunity_md__c = :recordId AND CobrokingType__c = 'Placing' AND LKCobroking_is__c = TRUE
            ];
            Decimal sharingPct = oppCobrokers.isEmpty() ? null : oppCobrokers[0].SharingPct__c;

            OPP_Layer__c dummyLayer = new OPP_Layer__c(
                Opportunity_md__c = recordId,
                LayerCurrency__c = selectedCurrency
            );
            OPP_MarketLineWrapper.LayerItem dummyLayerItem = layerItem(dummyLayer);
            dummyLayerItem.Id = tmpLayerId;

            OPP_Panel__c dummyPanel = new OPP_Panel__c(
                CO_is__c = true,
                Currency__c = selectedCurrency,
                MarketType__c = 'Facility',
                CobrokingType__c = 'CI',
                LKPlacingSharingPct__c = COM_Util.NVL(sharingPct)
            );
            OPP_MarketLineWrapper.MarketLineItem dummyPanelItem = marketLineItem(dummyPanel);
            dummyPanelItem.Id = tmpPanelId;
            dummyPanelItem.layerId = tmpLayerId;

            dummyLayerItem.marketLineItems.add(dummyPanelItem);
            layerItems.add(dummyLayerItem);
        }

        return layerItems;
    }

    @AuraEnabled
    public static List<OPP_MarketLineWrapper.LayerItem> saveRows(Id recordId, Boolean isCICase, String jsonString, String selectedCurrency, Boolean deleteLKPlacing) {
        System.debug('&&&&&&&&&&&&& saveRows Start !!!! recordId=[' + recordId + '], selectedCurrency=[' + selectedCurrency + '], jsonString=[' + jsonString + ']');

        List<Object> tmpRawList = (List<Object>) JSON.deserializeUntyped(jsonString);

        if (!tmpRawList.isEmpty() && tmpRawList[0] instanceof List<Object>) {
            tmpRawList = (List<Object>) tmpRawList[0];
        }

        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        for (Object obj : tmpRawList) {
            rows.add((Map<String, Object>) obj);
        }

        String sObjectName = COM_MetaUtil.getObjectNameById(recordId);
        Boolean isOpp = 'Opportunity'.equalsIgnoreCase(sObjectName);
        Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(sObjectName);
        Id oppId = (isPlacement ? [SELECT Opportunity_lk__c FROM Placement__c WHERE Id=:recordId LIMIT 1].Opportunity_lk__c : recordId);

        Map<String, OPP_Layer__c> oppLayerMap = new Map<String, OPP_Layer__c>();
        Map<String, Map<String, OPP_Panel__c>> oppPanelMap = new Map<String, Map<String, OPP_Panel__c>>();

        Map<String, Boolean> panelDeleteMap = new Map<String, Boolean>();

        Map<String, SObjectField> layerFields = Schema.SObjectType.OPP_Layer__c.fields.getMap();
        Map<String, SObjectField> panelFields = Schema.SObjectType.OPP_Panel__c.fields.getMap();
        Set<String> skipKeys = new Set<String>{'id','layerid','panelid','isdeleted'};

        for (Map<String, Object> row : rows) {

            String layerId = String.valueOf(row.get('layerId'));
            String panelId = String.valueOf(row.get('panelId'));
            Boolean isDeleted = (Boolean) row.get('isDeleted');

            if (String.isBlank(layerId)) continue;

            // 1. Layer 생성 + 필드 세팅
            if (!oppLayerMap.containsKey(layerId)) {

                OPP_Layer__c layer = new OPP_Layer__c();

                if (OPP_MarketLineConverter.isSalesforceId(layerId)) {
                    layer.Id = layerId;
                } else {
                    if(isOpp) layer.Opportunity_md__c = recordId;
                    if(isPlacement) layer.Opportunity_md__c = oppId;
                    if(isPlacement) layer.Placement_lk__c = recordId;
                }

                // Layer 필드 세팅
                for (String key : row.keySet()) {

                    if (String.isBlank(key) || skipKeys.contains(key.toLowerCase())) continue;

                    if (layerFields.containsKey(key) && !layerFields.get(key).getDescribe().isCalculated()) {
                        Object value = OPP_MarketLineConverter.normalize(row.get(key));
                        Schema.DisplayType fieldType = layerFields.get(key).getDescribe().getType();
                        layer.put(key, OPP_MarketLineConverter.convertToTyped(value, fieldType));
                    }
                }

                oppLayerMap.put(layerId, layer);
                oppPanelMap.put(layerId, new Map<String, OPP_Panel__c>());
            }

            // 2. Panel 생성
            if (String.isNotBlank(panelId)) {

                if (!oppPanelMap.get(layerId).containsKey(panelId)) {

                    OPP_Panel__c panel = new OPP_Panel__c();
                    if (OPP_MarketLineConverter.isSalesforceId(panelId)) {
                        panel.Id = panelId;
                    }

                    oppPanelMap.get(layerId).put(panelId, panel);
                    panelDeleteMap.put(panelId, isDeleted == true);
                }

                // 3. Panel 필드 세팅 (매 row)
                for (String key : row.keySet()) {

                    if (String.isBlank(key) || skipKeys.contains(key.toLowerCase())) continue;

                    if (panelFields.containsKey(key) && !panelFields.get(key).getDescribe().isCalculated() ) {
                        Object value = OPP_MarketLineConverter.normalize(row.get(key));
                        Schema.DisplayType fieldType = panelFields.get(key).getDescribe().getType();
                        oppPanelMap.get(layerId).get(panelId).put(key, OPP_MarketLineConverter.convertToTyped(value, fieldType));
                    }
                    if(isCICase && key=='Finalize_is__c') oppPanelMap.get(layerId).get(panelId).put(key, true);
                    if(key=='_rowNo') oppPanelMap.get(layerId).get(panelId).put('Seq__c', row.get('_rowNo'));
                }
            }
        }
        if (!oppPanelMap.isEmpty()) {
            for (String layerId : oppPanelMap.keySet()) {
                for (OPP_Panel__c oppPanel : oppPanelMap.get(layerId).values()) {
                    oppPanel.Currency__c = selectedCurrency;
                    if (oppPanel.MarketType__c == 'Facility') {
                        oppPanel.MGAName_lk__c = null;
                        oppPanel.Security_lk__c = null;
                    } else if (oppPanel.MarketType__c == 'MGA') {
                        if(oppPanel.Reinsurer_lk__c <> null) oppPanel.MGAName_lk__c = oppPanel.Reinsurer_lk__c;
                        if(oppPanel.MGAName_lk__c <> oppPanel.Reinsurer_lk__c) oppPanel.Reinsurer_lk__c = oppPanel.MGAName_lk__c;
                        oppPanel.Facility_lk__c = null;
                        oppPanel.FacilityParticipant_lk__c = null;
                    } else if (oppPanel.MarketType__c == 'Open Market') {
                        oppPanel.Facility_lk__c = null;
                        oppPanel.MGAName_lk__c = null;
                        oppPanel.Security_lk__c = null;
                        oppPanel.FacilityParticipant_lk__c = null;
                    }
                    if(oppPanel.BrkgAdj_is__c) {
                        if(oppPanel.Facility_lk__c <> null && oppPanel.MarketType__c <> 'Facility') oppPanel.MarketType__c = 'Facility';
                        oppPanel.Reinsurer_lk__c = null;
                    }
                }
            }
        }
        // Hidden 컬럼 값 초기화 (Co-broker 미존재 시 관련 필드 정리)
        Map<String, Object> ctx = OPP_MarketLineService.buildCtx(recordId);
        Set<String> colsToNull = new Set<String>();
        for (String ctxKey : CTX_HIDDEN_COLS_MAP.keySet()) {
            if (ctx.containsKey(ctxKey) && (Boolean) ctx.get(ctxKey) == false) {
                colsToNull.addAll(CTX_HIDDEN_COLS_MAP.get(ctxKey));
            }
        }
        if (!colsToNull.isEmpty()) {
            for (String layerId : oppPanelMap.keySet()) {
                for (OPP_Panel__c panel : oppPanelMap.get(layerId).values()) {
                    for (String fieldName : colsToNull) {
                        if (panelFields.containsKey(fieldName)) {
                            panel.put(fieldName, null);
                        }
                    }
                }
            }
        }

        // 3. DML 실행 (Upsert / Delete)
        Savepoint sp = Database.setSavepoint();
        try {
            // 3-0. Co-Broke 레코드 삭제 및 관련 계산 필드 초기화
            if (deleteLKPlacing == true) {
                List<OPP_Cobroker__c> toDel = [
                    SELECT Id
                    FROM OPP_Cobroker__c
                    WHERE Opportunity_md__c = :recordId AND CobrokingType__c = 'Placing' AND LKCobroking_is__c = TRUE
                ];
                if (!toDel.isEmpty()) delete toDel;

                for (String layerId : oppPanelMap.keySet()) {
                    for (OPP_Panel__c panel : oppPanelMap.get(layerId).values()) {
                        panel.LKTPPBrkge__c = 0;
                        panel.PlacingTPPAdminFeePct__c = 0; // LKTPPBrkge__c 값 사용
                        panel.LKPlacingTPPBrkg__c = 0;
                        panel.NetLKTPP__c = 0;
                        if (panel.CoBroker_lk__c != null && panel.PlacingSettlementType__c == SETT_TYPE_SEPARATE) panel.NetRI__c = 0; ///////////////////////
                    }
                }
            }

            // 3-1. Panel 삭제
            List<OPP_Panel__c> panelsToDelete = new List<OPP_Panel__c>();
            for (String panelId : panelDeleteMap.keySet()) {
                if (panelDeleteMap.get(panelId) == true && OPP_MarketLineConverter.isSalesforceId(panelId)) {
                    panelsToDelete.add(new OPP_Panel__c(Id = panelId));
                }
            }
            if (!panelsToDelete.isEmpty()) delete panelsToDelete;

            // 3-2. Layer Upsert
            List<OPP_Layer__c> layersToUpsert = new List<OPP_Layer__c>();
            List<String> layerTempIds = new List<String>();

            for (String layerId : oppLayerMap.keySet()) {
                if (!OPP_MarketLineConverter.isSalesforceId(layerId)) {
                    Boolean hasActivePanel = false;
                    if (oppPanelMap.containsKey(layerId)) {
                        for (String pid : oppPanelMap.get(layerId).keySet()) {
                            if (panelDeleteMap.get(pid) != true) {
                                hasActivePanel = true;
                                break;
                            }
                        }
                    }
                    if (!hasActivePanel) continue;
                }
                layersToUpsert.add(oppLayerMap.get(layerId));
                layerTempIds.add(layerId);
            }

            if (!layersToUpsert.isEmpty()) {
                upsert layersToUpsert;
            }

            // 임시 Layer ID -> 실제 Layer ID 매핑
            Map<String, Id> tempLayerToRealId = new Map<String, Id>();
            for (Integer i = 0; i < layersToUpsert.size(); i++) {
                tempLayerToRealId.put(layerTempIds[i], layersToUpsert[i].Id);
            }

            // 3-3. Panel Upsert
            List<OPP_Panel__c> panelsToUpsert = new List<OPP_Panel__c>();
            for (String layerId : oppPanelMap.keySet()) {
                Id realLayerId = tempLayerToRealId.get(layerId); // 실제 ID 가져오기

                for (String panelId : oppPanelMap.get(layerId).keySet()) {
                    if (panelDeleteMap.get(panelId) == true) continue; // 삭제 대상 제외

                    OPP_Panel__c panel = oppPanelMap.get(layerId).get(panelId);

                    if (panel.Id == null) {
                        panel.Layer_md__c = realLayerId;
                    }
                    panelsToUpsert.add(panel);
                }
            }

            if (!panelsToUpsert.isEmpty()) {
                upsert panelsToUpsert;
            }

            // 3-4. 빈 Layer 삭제 (선택 사항: Panel이 없는 Layer 정리)
            // Panel 삭제 및 Upsert 후, 자식 Panel이 하나도 남지 않은 Layer를 찾아 삭제
            List<OPP_Layer__c> layersInOpp = [
                SELECT Id, (SELECT Id FROM Panels__r LIMIT 1)
                FROM OPP_Layer__c
                WHERE Opportunity_md__c = :recordId
            ];
            List<OPP_Layer__c> emptyLayers = new List<OPP_Layer__c>();
            for (OPP_Layer__c lyr : layersInOpp) {
                if (lyr.Panels__r.isEmpty()) emptyLayers.add(lyr);
            }
            if (!emptyLayers.isEmpty()) delete emptyLayers;

            if(isOpp) {
                update new Opportunity(Id=recordId, NeedRecalculate_is__c = false);
            }
            if(isPlacement) {
                update new Placement__c(Id=recordId, NeedRecalculate_is__c = false);
            }

        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Save failed: ' + e.getMessage());
        }

        return queryRows(recordId, selectedCurrency);
    }

    @AuraEnabled(Cacheable=false)
    public static Boolean checkNeedRecalculate(Id recordId) {
        if (recordId == null) return false;

        String sObjectNm = COM_MetaUtil.getObjectNameById(recordId);
        Boolean isOpp = 'Opportunity'.equalsIgnoreCase(sObjectNm);
        Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(sObjectNm);

        if (isOpp) {
            Opportunity opp = [SELECT IsClosed, NeedRecalculate_is__c FROM Opportunity WHERE Id = :recordId];
            return !opp.IsClosed && opp.NeedRecalculate_is__c == true;
        }
        if (isPlacement) {
            Placement__c plc = [SELECT PerformanceInputType__c, NeedRecalculate_is__c FROM Placement__c WHERE Id = :recordId];
            return plc.PerformanceInputType__c != 'Confirm' && plc.NeedRecalculate_is__c == true;
        }
        return false;
    }

    /**
     * @description 기본 MarketLineGrid Columns
     * @param panelFields OPP_Panel__c sObject Fields
     * @param layerFields OPP_Layer__c sObject Fields
     *
     * @return List<OPP_MarketLineWrapper.ColMeta>
     */
    private static List<OPP_MarketLineWrapper.ColMeta> getStandardColumns(
        Map<String, SObjectField> panelFields,
        Map<String, SObjectField> layerFields
    ) {
        return new List<OPP_MarketLineWrapper.ColMeta>{
            colMeta(panelFields.get('Finalize_is__c'), VIEW_MODE, '').width(70),
            // Layer
            colMeta('LayerAction', null, EDIT_MODE, GRP_LAYER).width(40).label('').type(BUTTON_TYPE),
            colMeta(layerFields.get('Type__c'), EDIT_MODE, GRP_LAYER).required().groupPrimary(),//.options(COM_Util.makePickListOptions('OPP_Layer__c', 'Type__c', true, false, new Set<String>{'Brkg Adj'})),
            colMeta(layerFields.get('LayerCurrency__c'), EDIT_MODE, GRP_LAYER).required(),
            colMeta(layerFields.get('LOL__c'), EDIT_MODE, GRP_LAYER).width(150).required(),
            colMeta(layerFields.get('Excess__c'), EDIT_MODE, GRP_LAYER).width(150).required().zeroDisplayText('OPDs'),
            colMeta(layerFields.get('Layer_fm__c'), VIEW_MODE, GRP_LAYER).groupPrimary(),
            colMeta(layerFields.get('Remarks__c'), EDIT_MODE, GRP_LAYER).width(140),
            // Market
            colMeta('MLAction', null, EDIT_MODE, GRP_MARKET).width(40).label('').type(BUTTON_TYPE),
            colMeta(panelFields.get('Currency__c'), HIDDEN_MODE, GRP_MARKET).required(),
            colMeta(panelFields.get('MarketType__c'), EDIT_MODE, GRP_MARKET).width(140).required(),
            colMeta(panelFields.get('Facility_lk__c'), EDIT_MODE, GRP_MARKET).label('Facility Name'),
            colMeta(panelFields.get('MGAName_lk__c'), HIDDEN_MODE, GRP_MARKET).label('Facility Name'),
            colMeta(panelFields.get('Leader_is__c'), EDIT_MODE, GRP_MARKET).width(50),
            colMeta(panelFields.get('Reinsurer_lk__c'), EDIT_MODE, GRP_MARKET).groupPrimary().required(),
            colMeta(panelFields.get('FacilityParticipant_lk__c'), HIDDEN_MODE, GRP_MARKET),
            colMeta(panelFields.get('Security_lk__c'), EDIT_MODE, GRP_MARKET).required().dependsOn(new List<String>{ 'Reinsurer_lk__c' }),
            // line (%)
            colMeta(panelFields.get('Written__c'), EDIT_MODE, GRP_LINE).required().type(PERCENT_TYPE),
            colMeta(panelFields.get('Signed__c'), EDIT_MODE, GRP_LINE).groupPrimary().required().type(PERCENT_TYPE),
            // Net from Cedant  => RI Premium Breakdown
            colMeta(panelFields.get('GrossPremDP__c'), EDIT_MODE, GRP_RI_PREMIUM).width(130).required(),
            colMeta(panelFields.get('DPPct__c'), EDIT_MODE, GRP_RI_PREMIUM).required().type(PERCENT_TYPE),
            colMeta(panelFields.get('GrossPrem__c'), VIEW_MODE, GRP_RI_PREMIUM).width(140).groupPrimary(),
            colMeta(panelFields.get('RICommPct__c'), EDIT_MODE, GRP_RI_PREMIUM).groupPrimary().type(PERCENT_TYPE),
            colMeta(panelFields.get('OtherDeductionPct__c'), EDIT_MODE, GRP_RI_PREMIUM).groupPrimary().type(PERCENT_TYPE),
            // Total Brokerage
            colMeta(panelFields.get('BrkgBase__c'), EDIT_MODE, GRP_TOTAL_BRKG).required(),
            colMeta(panelFields.get('TotalBrkgPct__c'), EDIT_MODE, GRP_TOTAL_BRKG).groupPrimary().required().type(PERCENT_TYPE),
            colMeta(panelFields.get('TotalBrkg__c'), VIEW_MODE, GRP_TOTAL_BRKG).groupPrimary(),
            // Producing Co-broking
            colMeta(panelFields.get('ProducingSharingPct__c'), EDIT_MODE, GRP_PRODUCING).groupPrimary().required().type(PERCENT_TYPE), //Sharing(%)
            colMeta(panelFields.get('ProducingTPPAdminFeePct__c'), EDIT_MODE, GRP_PRODUCING).required().type(PERCENT_TYPE), //TPP Admin Fee(%)
            // Producing Co-broking (LK)
            colMeta(panelFields.get('LKProducingSharingPct__c'), EDIT_MODE, GRP_PRODUCING_LK).groupPrimary().width(150),
            // Placing Co-broking
            colMeta(panelFields.get('CoBroker_lk__c'), EDIT_MODE, GRP_PLACING).groupPrimary().filters(CO_BROKER_FILTER),//.filter('LKInternalCompany_is__c', false),
            colMeta(panelFields.get('PlacingSharingPct__c'), EDIT_MODE, GRP_PLACING).groupPrimary().type(PERCENT_TYPE),
            colMeta(panelFields.get('PlacingTPPAdminFeePct__c'), EDIT_MODE, GRP_PLACING).type(PERCENT_TYPE),
            colMeta(panelFields.get('PlacingSettlementType__c'), EDIT_MODE, GRP_PLACING),
            // Placing Co-broking (LK)
            colMeta(panelFields.get('LKPlacingSharingPct__c'), EDIT_MODE, GRP_PLACING_LK).type(PERCENT_TYPE), // Sharing(%)

            colMeta(panelFields.get('CobrokingType__c'), VIEW_MODE, ''),
            colMeta(panelFields.get('NetProducingCobrker__c'), VIEW_MODE, ''),
            colMeta(panelFields.get('NetToLKPrem__c'), VIEW_MODE, ''),
            colMeta(panelFields.get('NetToUW__c'), VIEW_MODE, ''),
            colMeta(panelFields.get('ActualAdjRatePct__c'), VIEW_MODE, '').scale(6).type(PERCENT_TYPE),
            // Brokerage sharing Amt
            colMeta(panelFields.get('LKReBrkge__c'), VIEW_MODE, GRP_BRKG_AMT).groupCollapsible(false),
            colMeta(panelFields.get('ProducingTPPBrkg__c'), VIEW_MODE, GRP_BRKG_AMT),
            colMeta(panelFields.get('LKProducingTPPBrkg__c'), VIEW_MODE, GRP_BRKG_AMT),
            colMeta(panelFields.get('PlacingTPPBrkge__c'), VIEW_MODE, GRP_BRKG_AMT),
            colMeta(panelFields.get('LKPlacingTPPBrkg__c'), VIEW_MODE, GRP_BRKG_AMT),
            // Group: Admin Fee
            colMeta(panelFields.get('ToProducingAdminFee__c'), VIEW_MODE, GRP_ADMIN_FEE).groupCollapsible(false), //to producing (-)
            colMeta(panelFields.get('ToLKAdminFee__c'), VIEW_MODE, GRP_ADMIN_FEE), //to LK (+)
            // Settlement
            colMeta(panelFields.get('NetRI__c'), VIEW_MODE, GRP_SETTLEMENT).groupCollapsible(false),
            colMeta(panelFields.get('NetProducingTPP__c'), VIEW_MODE, GRP_SETTLEMENT),
            colMeta(panelFields.get('LKNetProducingTPP__c'), VIEW_MODE, GRP_SETTLEMENT).width(150),
            colMeta(panelFields.get('NetPlacingTPP__c'), VIEW_MODE, GRP_SETTLEMENT),
            colMeta(panelFields.get('LKNetPlacingTPP__c'), VIEW_MODE, GRP_SETTLEMENT),
            // Settlement Claim
            colMeta(panelFields.get('ClmNetRI__c'), EDIT_MODE, GRP_SETTLEMENT_CLM).groupCollapsible(false),
            colMeta(panelFields.get('ClmNetToPlacingTPP__c'), EDIT_MODE, GRP_SETTLEMENT_CLM),
            colMeta(panelFields.get('ClmNetToPlacingTPPLK__c'), EDIT_MODE, GRP_SETTLEMENT_CLM).width(150),
            // Contact
            colMeta(panelFields.get('RIContact_lk__c'), EDIT_MODE, GRP_CONTACT).groupCollapsible(false).parentField('Reinsurer_lk__c').dependsOn(new List<String>{ 'Reinsurer_lk__c' }),
            colMeta(panelFields.get('CoBrokerContact_lk__c'), EDIT_MODE, GRP_CONTACT).parentField('CoBroker_lk__c').dependsOn(new List<String>{ 'CoBroker_lk__c' }),
            // Others
            colMeta(panelFields.get('Others__c'), EDIT_MODE, ''),
            colMeta('subAction', null, EDIT_MODE, '').label('Subjectivity').width(120).type(BUTTON_TYPE),
            // Hidden Fields
            colMeta(panelFields.get('CO_is__c'), HIDDEN_MODE, ''),
            colMeta(panelFields.get('BrkgAdj_is__c'), HIDDEN_MODE, '')
        };
    }

    /**
     * @description CI Case MarketLineGrid Columns
     * @param panelFields Panel sObject Fields
     *
     * @return List<ColMeta>
     */
    private static List<OPP_MarketLineWrapper.ColMeta> getCICaseColumns(Map<String, SObjectField> panelFields) {
        // CI Case는 Layer 정보 없이 Panel 정보만 보여줌
        //https://data-momentum-7077--dev2.sandbox.lightning.force.com/lightning/r/Opportunity/006JO00000G9IsYYAV/view#/
        return new List<OPP_MarketLineWrapper.ColMeta>{
            // Total Brokerage
            colMeta(panelFields.get('TotalBrkg__c'), EDIT_MODE, ''),
            // Group: Producing Co-broking
            colMeta(panelFields.get('ProducingSharingPct__c'), VIEW_MODE, GRP_PRODUCING).type(PERCENT_TYPE),
            colMeta(panelFields.get('ProducingTPPAdminFeePct__c'), VIEW_MODE, GRP_PRODUCING),
            // Group: Placing Co-broking
            colMeta(panelFields.get('CoBroker_lk__c'), EDIT_MODE, GRP_PLACING).filters(CO_BROKER_FILTER),//.filter('LKInternalCompany_is__c', false),
            colMeta(panelFields.get('PlacingSharingPct__c'), EDIT_MODE, GRP_PLACING).groupPrimary().type(PERCENT_TYPE),
            colMeta(panelFields.get('PlacingTPPAdminFeePct__c'), EDIT_MODE, GRP_PLACING).type(PERCENT_TYPE),
            colMeta(panelFields.get('PlacingSettlementType__c'), EDIT_MODE, GRP_PLACING).groupPrimary()
                    .options(COM_Util.makePickListOptions('OPP_Panel__c', 'PlacingSettlementType__c', true, false, new Set<String>{ SETT_TYPE_TOGETHER })),
            // Group: Placing Co-broking (LK)
            colMeta(panelFields.get('LKPlacingSharingPct__c'), VIEW_MODE, GRP_PLACING_LK).label('Sharing(%)').type(PERCENT_TYPE),

            colMeta(panelFields.get('CobrokingType__c'), VIEW_MODE, ''),
            colMeta(panelFields.get('NetProducingCobrker__c'), VIEW_MODE, ''),
            colMeta(panelFields.get('NetToLKPrem__c'), VIEW_MODE, ''),
            // Group: Brokerage sharing Amt .label('LK Re Brokerage (after sharing)')
            colMeta(panelFields.get('LKReBrkge__c'), VIEW_MODE, GRP_BRKG_AMT).width(70).groupPrimary(),
            colMeta(panelFields.get('PlacingTPPBrkge__c'), VIEW_MODE, GRP_BRKG_AMT),
            colMeta(panelFields.get('LKPlacingTPPBrkg__c'), VIEW_MODE, GRP_BRKG_AMT),
            // Group: Admin Fee
            colMeta(panelFields.get('ToProducingAdminFee__c'), VIEW_MODE, GRP_ADMIN_FEE).groupCollapsible(false), //to producing (-)
            colMeta(panelFields.get('ToLKAdminFee__c'), VIEW_MODE, GRP_ADMIN_FEE), //to LK (+)
            // Group: Settlement
            colMeta(panelFields.get('NetPlacingTPP__c'), VIEW_MODE, GRP_SETTLEMENT).groupCollapsible(false),
            colMeta(panelFields.get('LKNetPlacingTPP__c'), VIEW_MODE, GRP_SETTLEMENT),
            // Settlement Claim
//            colMeta(panelFields.get('ClmNetRI__c'), EDIT_MODE, GRP_SETTLEMENT_CLM).groupCollapsible(false),
            colMeta(panelFields.get('ClmNetToPlacingTPP__c'), EDIT_MODE, GRP_SETTLEMENT_CLM).groupCollapsible(false),
            colMeta(panelFields.get('ClmNetToPlacingTPPLK__c'), EDIT_MODE, GRP_SETTLEMENT_CLM).width(150),
            // Contact
            colMeta(panelFields.get('CoBrokerContact_lk__c'), EDIT_MODE, GRP_CONTACT).parentField('CoBroker_lk__c').dependsOn(new List<String>{ 'CoBroker_lk__c' }),
            // Others
            colMeta(panelFields.get('Others__c'), EDIT_MODE, ''),
            //Hidden Fields
            colMeta(panelFields.get('CO_is__c'), HIDDEN_MODE, ''),
            colMeta(panelFields.get('BrkgAdj_is__c'), HIDDEN_MODE, ''),
            colMeta(panelFields.get('Currency__c'), HIDDEN_MODE, '')
        };
    } //getCICaseColumns End __*

    /**
     * @description Claim MarketLineGrid Columns
     * @param panelFields OPP_Panel__c sObject Fields
     * @param layerFields OPP_Layer__c sObject Fields
     *
     * @return List<OPP_MarketLineWrapper.ColMeta>
     */
    private static List<OPP_MarketLineWrapper.ColMeta> getClaimColumns(Map<String, SObjectField> panelFields, Map<String, SObjectField> layerFields) {
        return new List<OPP_MarketLineWrapper.ColMeta>{
                // Layer
                colMeta(layerFields.get('Type__c'), EDIT_MODE, GRP_LAYER).required(),
                colMeta(layerFields.get('LayerCurrency__c'), EDIT_MODE, GRP_LAYER).required(),
                colMeta(layerFields.get('LOL__c'), EDIT_MODE, GRP_LAYER).width(150).groupPrimary().required(),
                colMeta(layerFields.get('Excess__c'), EDIT_MODE, GRP_LAYER).width(150).groupPrimary().required().zeroDisplayText('OPDs'),
                colMeta(layerFields.get('Layer_fm__c'), VIEW_MODE, GRP_LAYER),
                colMeta(layerFields.get('Remarks__c'), EDIT_MODE, GRP_LAYER).width(140),
                // Market
                colMeta(panelFields.get('MarketType__c'), EDIT_MODE, GRP_MARKET).width(140).required(),
                colMeta(panelFields.get('Facility_lk__c'), EDIT_MODE, GRP_MARKET).groupPrimary().label('Facility Name'),
                colMeta(panelFields.get('MGAName_lk__c'), HIDDEN_MODE, GRP_MARKET).label('Facility Name'),
                colMeta(panelFields.get('Leader_is__c'), EDIT_MODE, GRP_MARKET).width(50),
                colMeta(panelFields.get('Reinsurer_lk__c'), EDIT_MODE, GRP_MARKET).groupPrimary().required(),
                colMeta(panelFields.get('FacilityParticipant_lk__c'), HIDDEN_MODE, GRP_MARKET),
                colMeta(panelFields.get('Security_lk__c'), EDIT_MODE, GRP_MARKET).required().dependsOn(new List<String>{ 'Reinsurer_lk__c' }),
                // line (%)
                colMeta(panelFields.get('Signed__c'), EDIT_MODE, GRP_LINE).groupPrimary(),
                // Placing Co-broking
                colMeta(panelFields.get('CoBroker_lk__c'), EDIT_MODE, GRP_PLACING).groupPrimary().filters(CO_BROKER_FILTER),//.filter('LKInternalCompany_is__c', false),
                colMeta(panelFields.get('PlacingSettlementType__c'), EDIT_MODE, GRP_PLACING).groupPrimary(),
                // Hidden Fields
                colMeta(panelFields.get('CO_is__c'), HIDDEN_MODE, ''),
                colMeta(panelFields.get('BrkgAdj_is__c'), HIDDEN_MODE, '')
        };
    }


}