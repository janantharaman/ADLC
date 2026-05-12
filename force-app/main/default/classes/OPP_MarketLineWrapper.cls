/**********************************************************************************
 * @filename      : OPP_MarketLineWrapper.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-07 (토)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketLineWrapper_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-07      i2max     Create
**********************************************************************************/
public with sharing class OPP_MarketLineWrapper {

    public enum CellType { text, num, picklist, checkbox, multipicklist, lookup, d, dt, button, textarea, richtext, percent }
    public enum CellMode { VIEW, EDIT, HIDDEN }

    public static final Integer WIDTH_DEFAULT = 120;
    public static final Integer WIDTH_LOOKUP = 170;

    // ============================================================================
    // 1. Grid Meta
    // ============================================================================
    public class GridMeta {
        @AuraEnabled public List<ColMeta> columns {get; set;}
        @AuraEnabled public OPP_MarketLineRuleService.RuleSet rules {get; set;}
        @AuraEnabled public Map<String, Object> ctx {get; set;}
        @AuraEnabled public List<LayerItem> rows {get; set;}
        @AuraEnabled public Boolean isOpp {get; set;}
        @AuraEnabled public Boolean isPlacement {get; set;}
        @AuraEnabled public Boolean isClaim {get; set;}
        @AuraEnabled public Boolean isCICase {get; set;}
        @AuraEnabled public Boolean isReadOnly {get; set;}
        @AuraEnabled public Boolean isTreaty {get; set;}
        @AuraEnabled public String claimCurrency {get; set;}
    }

    // ============================================================================
    // 2. Column Meta
    // ============================================================================
    public class ColMeta {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String mode;
        @AuraEnabled public Integer rowSpan;
        @AuraEnabled public String groupName;
        @AuraEnabled public Integer width;
        @AuraEnabled public Integer scale;
        @AuraEnabled public Integer precision;
        @AuraEnabled public Boolean isMulti;
        @AuraEnabled public String lookupObject;
        @AuraEnabled public String lookupLabelField;
        @AuraEnabled public String parentField;
        @AuraEnabled public String formula;
        @AuraEnabled public Boolean required;
        @AuraEnabled public List<String> depends;
        @AuraEnabled public List<COM_Option> options;
        /** 그룹 접기/펼치기 가능 여부 (false면 항상 펼침), false 일때 토글 버튼 숨김 처리  */
        @AuraEnabled public Boolean groupCollapsible = true; //해당 그룹이 접힘 가능한지 여부. false면 접기/펼치기 자체가 불가 (항상 펼쳐짐)
        /** 초기 접힘 상태 (true면 로드 시 접힘) */
        @AuraEnabled public Boolean collapsed = false; //해당 그룹의 초기 접힘 상태. true면 화면 로드 시 접힌 채로 시작
        @AuraEnabled public Boolean groupPrimary = false;
        @AuraEnabled public String zeroDisplayText;
        @AuraEnabled public String filterField;
        @AuraEnabled public Object filterValue;
        @AuraEnabled public Map<String, Object> filters;

        public ColMeta(SObjectField sObjectField, CellMode mode, String groupName) {
            this(null, sObjectField, mode, groupName);
        }

        public ColMeta(String key, SObjectField sObjectField, CellMode mode, String groupName) {
            
            this.mode = String.valueOf(mode).toLowerCase();
            this.groupName = groupName;
            this.width = WIDTH_DEFAULT;
            this.isMulti = false;
            this.rowSpan = 1;
            this.required = false;

            if (sObjectField != null) {
                DescribeFieldResult describeFieldResult = sObjectField.getDescribe();
                this.key = describeFieldResult.getName();
                this.label = describeFieldResult.getLabel();
                this.type = mapSfTypeToCellType(describeFieldResult);
                if (this.type == 'num') {
                    this.scale = describeFieldResult.getScale();
                    this.precision = describeFieldResult.getPrecision();
                }
                if (this.type == 'picklist' || this.type == 'multipicklist') {
                    this.options = COM_Util.makePickListOptions(
                            describeFieldResult.SObjectType.getDescribe().getName(),
                            describeFieldResult.getName(),
                            true
                    );
                }
                if (this.type == 'lookup') {
                    if (!describeFieldResult.getReferenceTo().isEmpty()) {
                        this.lookupObject = describeFieldResult.getReferenceTo()[0].getDescribe().getName();
                        this.lookupLabelField = 'Name';
                    }
                    this.width = WIDTH_LOOKUP;
                }
                return;
            }

            this.key   = key;
            this.type  = CellType.text.toString();
            this.label = key;

            if (String.isBlank(key)) {
                throw new AuraHandledException('ColMeta: key is required for virtual columns. key=['+ key +']');
            }
            if (!Pattern.compile('^[A-Za-z_][A-Za-z0-9_]*$').matcher(key).matches()) {
                throw new AuraHandledException('ColMeta: invalid key "' + key + '". Use [A-Za-z_][A-Za-z0-9_]*.');
            }
        }

        public ColMeta label(String v) { this.label = v; return this; }
        public ColMeta scale(Integer v) { this.scale = v; return this; }
        public ColMeta multi(Boolean v) { this.isMulti = v; return this; }
        public ColMeta parentField(String val) { this.parentField = val; return this; }
        public ColMeta lookup(String obj, String labelField) {
            this.type = String.valueOf(CellType.lookup).toLowerCase();
            this.lookupObject = obj;
            this.lookupLabelField = String.isBlank(labelField) ? 'Name' : labelField;
            this.width = WIDTH_LOOKUP;
            return this;
        }
        public ColMeta lookupLabelField(String v) { this.lookupLabelField = v; return this; }
        public ColMeta formula(String val) { this.type = String.valueOf(CellType.text).toLowerCase(); this.formula = val; return this; }
        public ColMeta dependsOn(List<String> d) { this.depends = d; return this; }
        public ColMeta type(CellType type) { this.type = String.valueOf(type).toLowerCase(); return this; }
        public ColMeta options(List<COM_Option> o) { this.type = String.valueOf(CellType.picklist).toLowerCase(); this.options = (o == null) ? new List<COM_Option>() : o; return this; }
        public ColMeta rowSpan(Integer v) { this.rowSpan = v; return this; }
        public ColMeta width(Integer v) { this.width = v; return this; }
        public ColMeta groupName(String v) { this.groupName = v; return this; }
        public ColMeta groupCollapsible(Boolean v) { this.groupCollapsible = v; return this; }
        public ColMeta collapsed(Boolean v) { this.collapsed = v; return this; }
        public ColMeta groupPrimary() { this.groupPrimary = true; return this; }
        public ColMeta required() { this.required = true; return this; }
        public ColMeta viewMode() { this.mode = String.valueOf(CellMode.VIEW).toLowerCase(); return this; }
        public ColMeta editMode() { this.mode = String.valueOf(CellMode.EDIT).toLowerCase(); return this; }
        public ColMeta hiddenMode() { this.mode = String.valueOf(CellMode.HIDDEN).toLowerCase(); return this; }
        public ColMeta zeroDisplayText(String v) { this.zeroDisplayText = v; return this; }
//        public ColMeta filter(String field, Object value) {
//            this.filterField = field;
//            this.filterValue = value;
//            return this;
//        }
        public ColMeta filter(String field, Object value) {
            if (this.filters == null) {
                this.filters = new Map<String, Object>();
            }
            this.filters.put(field, value);

            // 기존 단일 필터 변수도 업데이트 (마지막 설정값 기준 유지)
            this.filterField = field;
            this.filterValue = value;
            return this;
        }

        public ColMeta filters(Map<String, Object> filterMap) {
            if (this.filters == null) this.filters = new Map<String, Object>();
            if (filterMap != null) this.filters.putAll(filterMap);
            return this;
        }

    }

    // ============================================================================
    // 3. Layer Item
    // ============================================================================
    public class LayerItem {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public Boolean isDeleted { get; set; }
        @AuraEnabled public Integer layerRowSpan {
            get {
                Integer rowCnt = 1;
                for (MarketLineItem item : marketLineItems) {
                    if (item.isDeleted == false) rowCnt++;
                }
                return rowCnt;
            }
            set;
        }
        @AuraEnabled public Map<String, Object> layerValues;
        @AuraEnabled public List<MarketLineItem> marketLineItems { get; set; }

        public LayerItem(OPP_Layer__c layer) {
            this.Id = layer.Id;
            this.isDeleted = false;
            this.layerValues = new Map<String, Object>{
                    'Type__c'          => layer.Type__c,
                    'LayerCurrency__c' => layer.LayerCurrency__c,
                    'LOL__c'           => layer.LOL__c,
                    'Excess__c'        => layer.Excess__c,
                    'Layer_fm__c'      => layer.Layer_fm__c,
                    'Remarks__c'       => layer.Remarks__c
            };
            this.marketLineItems = new List<MarketLineItem>();
        }
    }

    // ============================================================================
    // 4. Market Line Item
    // ============================================================================
    public class MarketLineItem {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String layerId { get; set; }
        @AuraEnabled public Boolean isDeleted { get; set; }
        @AuraEnabled public Map<String, Object> values;

        public MarketLineItem(OPP_Panel__c panel) {
            this.Id = panel.Id;
            this.layerId = panel.Layer_md__c;
            this.isDeleted = false;

            Map<String, Object> items = new Map<String, Object>();

            items.put('CO_is__c', panel.CO_is__c);//Hidden Field
            items.put('BrkgAdj_is__c', panel.BrkgAdj_is__c);//Hidden Field
            items.put('Finalize_is__c', panel.Finalize_is__c);

            items.put('MarketType__c',        panel.MarketType__c);
            items.put('Currency__c',          panel.Currency__c);
            items.put('Facility_lk__c',       panel.Facility_lk__c);
            if (panel.Facility_lk__r != null) {
                items.put('Facility_lk__r', new Map<String, Object>{ 'Name' => panel.Facility_lk__r.Name });
            }
            items.put('MGAName_lk__c',        panel.MGAName_lk__c);
            if (panel.MGAName_lk__r != null) {
                items.put('MGAName_lk__r', new Map<String, Object>{ 'Name' => panel.MGAName_lk__r.Name });
            }
            items.put('LKProducingSharingPct__c', panel.LKProducingSharingPct__c);
            items.put('Leader_is__c',         panel.Leader_is__c);
            items.put('Reinsurer_lk__c',      panel.Reinsurer_lk__c);
            if (panel.Reinsurer_lk__r != null) {
                items.put('Reinsurer_lk__r', new Map<String, Object>{ 'Name' => panel.Reinsurer_lk__r.Name });
            }
            items.put('Security_lk__c',       panel.Security_lk__c);
            if (panel.Security_lk__r != null) {
                items.put('Security_lk__r', new Map<String, Object>{ 'Name' => panel.Security_lk__r.Name });
            }

            items.put('Written__c',           panel.Written__c);
            items.put('Signed__c',            panel.Signed__c);

            items.put('GrossPremDP__c',       panel.GrossPremDP__c);
            items.put('DPPct__c',             panel.DPPct__c);
            items.put('GrossPrem__c',         panel.GrossPrem__c);
            items.put('ActualAdjRatePct__c',     panel.ActualAdjRatePct__c);
            items.put('RICommPct__c',         panel.RICommPct__c);
            items.put('OtherDeductionPct__c', panel.OtherDeductionPct__c);
            items.put('NetToLKPrem__c',       panel.NetToLKPrem__c);

            items.put('BrkgBase__c',          panel.BrkgBase__c);
            items.put('TotalBrkgPct__c',      panel.TotalBrkgPct__c);
            items.put('TotalBrkg__c',         panel.TotalBrkg__c);

            items.put('CoBroker_lk__c',       panel.CoBroker_lk__c);
            items.put('PlacingSharingPct__c',        panel.PlacingSharingPct__c);
            items.put('PlacingTPPAdminFeePct__c',    panel.PlacingTPPAdminFeePct__c);
            items.put('PlacingSettlementType__c',    panel.PlacingSettlementType__c);

            items.put('LKCoBrokingSharing_is__c', panel.LKCoBrokingSharing_is__c);

            items.put('LKReBrkge__c',         panel.LKReBrkge__c);
            items.put('ProducingTPPBrkg__c',  panel.ProducingTPPBrkg__c);
            items.put('PlacingTPPBrkge__c',   panel.PlacingTPPBrkge__c);
            items.put('LKTPPBrkge__c',        panel.LKTPPBrkge__c);
            items.put('LKAdminFee__c',        panel.LKAdminFee__c);

            items.put('NetRI__c',             panel.NetRI__c);
            items.put('NetProducingTPP__c',   panel.NetProducingTPP__c);
            items.put('NetPlacingTPP__c',     panel.NetPlacingTPP__c);
            items.put('NetLKTPP__c',          panel.NetLKTPP__c);

            items.put('ClmNetRI__c',                panel.ClmNetRI__c);
            items.put('ClmNetToPlacingTPP__c',      panel.ClmNetToPlacingTPP__c);
            items.put('ClmNetToPlacingTPPLK__c',    panel.ClmNetToPlacingTPPLK__c);

            items.put('ProducingSharingPct__c',  panel.ProducingSharingPct__c);
            items.put('ProducingTPPAdminFeePct__c', panel.ProducingTPPAdminFeePct__c);
            items.put('CobrokingType__c',     panel.CobrokingType__c);
            items.put('NetProducingCobrker__c', panel.NetProducingCobrker__c);
            items.put('LKPlacingTPPBrkg__c',  panel.LKPlacingTPPBrkg__c);
            items.put('ToProducingAdminFee__c', panel.ToProducingAdminFee__c);
            items.put('ToLKAdminFee__c',      panel.ToLKAdminFee__c);
            items.put('LKNetPlacingTPP__c',   panel.LKNetPlacingTPP__c);
            items.put('LKPlacingSharingPct__c',   panel.LKPlacingSharingPct__c);

            items.put('RIContact_lk__c',      panel.RIContact_lk__c);
            items.put('CoBrokerContact_lk__c',panel.CoBrokerContact_lk__c);

            items.put('Others__c',            panel.Others__c);
            items.put('Subjectivity__c',      panel.Subjectivity__c);
            items.put('NetToUW__c',           panel.NetToUW__c);

            this.values = items;
        }
    }

    private static String mapSfTypeToCellType(DescribeFieldResult describeFieldResult) {
        Schema.DisplayType displayType = describeFieldResult.getType();
        if (displayType == Schema.DisplayType.DATE) return 'd';
        if (displayType == Schema.DisplayType.DATETIME) return 'dt';
        if (displayType == Schema.DisplayType.CURRENCY || displayType == Schema.DisplayType.DOUBLE || displayType == Schema.DisplayType.INTEGER || displayType == Schema.DisplayType.PERCENT) return 'num';
        if (displayType == Schema.DisplayType.PICKLIST) return 'picklist';
        if (displayType == Schema.DisplayType.MULTIPICKLIST) return 'multipicklist';
        if (displayType == Schema.DisplayType.BOOLEAN) return 'checkbox';
        if (displayType == Schema.DisplayType.REFERENCE) return 'lookup';
        if (displayType == Schema.DisplayType.TEXTAREA) {
            return describeFieldResult.isHtmlFormatted() ? 'richtext' : 'textarea';
        }
        return 'text';
    }
}