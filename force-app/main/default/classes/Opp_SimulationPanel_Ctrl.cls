/**********************************************************************************
 * @filename      : Opp_SimulationPanel_Ctrl.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-01-12
 * @group         :
 * @group-content :
 * @description   : Opportunity Simulation Panel 데이터 조회 및 Finalize 처리를 담당하는 컨트롤러
 * @test-class    : Opp_SimulationPanel_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-12      i2max            Create
 **********************************************************************************/
public with sharing class Opp_SimulationPanel_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description 레코드 Id로 CedingType1__c를 조회하여 Treaty 여부를 반환한다.
     * @param recordId Opportunity 또는 Placement 레코드 Id
     * @return Boolean Treaty 여부 (CedingType1__c = 'Treaty'이면 true)
     */
    @AuraEnabled(cacheable=true)
    public static Boolean getIsTreaty(Id recordId) {
        if (String.isBlank(recordId)) return false;
        try {
            String sObjectNm = COM_MetaUtil.getObjectNameById(recordId);
            if ('Opportunity'.equalsIgnoreCase(sObjectNm)) {
                Opportunity opp = [SELECT CedingType1__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
                return opp.CedingType1__c == 'Treaty';
            } else {
                Placement__c plc = [SELECT CedingType1__c FROM Placement__c WHERE Id = :recordId LIMIT 1];
                return plc.CedingType1__c == 'Treaty';
            }
        } catch (Exception e) {
            System.debug('Error in getIsTreaty: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description 선택된 Panel Id 목록으로 Simulation Panel 데이터를 조회한다.
     * @param panelIds 조회 대상 Panel Id 목록
     * @return List<PanelWrapper> 선택된 Panel 데이터 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<PanelWrapper> getSelectedPanelData(List<Id> panelIds) {
        try {
            if (panelIds == null || panelIds.isEmpty()) {
                return new List<PanelWrapper>();
            }
            
            List<OPP_Panel__c> panels = [
                SELECT
                    Id,
                    Finalize_is__c,
                    BrkgAdj_is__c,
                    Layer_md__c,
                    Layer_md__r.Type__c,
                    Layer_md__r.LOL__c,
                    Layer_md__r.Excess__c,
                    Layer_md__r.LayerCurrency__c,
                    Layer_md__r.Opportunity_md__r.TotalOrderPct__c,
                    MarketType__c,
                    Written__c,
                    Signed__c,
                    TotalBrkgPct__c,
                    GrossPrem__c,
                    NetToLKPrem__c,
                    TotalBrkg__c,
                    LKReBrkge__c,
                    LKProducingTPPBrkg__c,
                    LKPlacingTPPBrkg__c,
                    ProducingTPPBrkg__c,
                    PlacingTPPBrkge__c,
                    NetToUW__c,
                    NetProducingCobrker__c,
                    NetRI__c,
                    ToProducingAdminFee__c,
                    ToLKAdminFee__c,
                    Reinsurer_lk__r.Name,
                    Facility_lk__r.Name,
                    MGAName_lk__r.Name,
                    Leader_is__c,
                    Security_lk__r.Name,
                    Currency__c,
                    Facility_lk__c,
                    FacilityParticipant_lk__c
                FROM OPP_Panel__c
                WHERE Id IN :panelIds
                ORDER BY BrkgAdj_is__c ASC, Layer_md__r.CreatedDate DESC, CreatedDate DESC
            ];
            
            System.debug('Found ' + panels.size() + ' selected panels');
            
            Integer counter = 1;
            List<PanelWrapper> result = new List<PanelWrapper>();
            for (OPP_Panel__c panel : panels) {
                result.add(new PanelWrapper(panel, counter++));
            }
            return result;
        } catch (Exception e) {
            System.debug('Error in getSelectedPanelData: ' + e.getMessage());
            throw new AuraHandledException('Error loading selected panel data: ' + e.getMessage());
        }
    }
    
    /**
     * @description 선택된 Panel의 Finalize 상태를 갱신하고 관련 QS Layer 및 Brokerage Adjustment 데이터를 저장한다.
     * @param panelIds 선택된 Panel Id 목록
     * @param recordId Opportunity 또는 Placement 레코드 Id
     * @param selectedCurrency 선택된 통화 값
     * @param qsLol QS Layer에 반영할 LOL 값
     * @param brkgAdjData Brokerage Adjustment 계산 결과 데이터
     * @return Boolean 처리 성공 여부
     */
    @AuraEnabled
    public static Boolean updatePanelFinalize(List<Id> panelIds, Id recordId, String selectedCurrency, Decimal qsLol, PanelWrapper brkgAdjData) {
        if (panelIds == null || panelIds.isEmpty()) {
            throw new AuraHandledException('No panels selected.');
        }
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Opportunity ID is required.');
        }
        if (String.isBlank(selectedCurrency)) {
            throw new AuraHandledException('Currency is required.');
        }
        
        Set<Id> selectedSet = new Set<Id>(panelIds);
        
        try {
            // 해당 Currency와 Opportunity의 Panel 조회 (BrkgAdj는 별도 upsert로 처리하므로 제외)
            
            String sObjectNm = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isOpp = 'Opportunity'.equalsIgnoreCase(sObjectNm);
            
            Id opportunityId = recordId;
            Boolean isTreaty = false;
            if (isOpp == false) {
                Placement__c plc = [SELECT Opportunity_lk__c, CedingType1__c FROM Placement__c WHERE Id = :recordId LIMIT 1];
                opportunityId = plc.Opportunity_lk__c;
                isTreaty = plc.CedingType1__c == 'Treaty';
            }
            
            List<String> query = new List<String>();
            query.add('SELECT Id, Finalize_is__c');
            query.add('FROM OPP_Panel__c');
            query.add('WHERE Currency__c = :selectedCurrency');
            query.add('AND BrkgAdj_is__c = FALSE');
            if (isOpp == true)
                query.add('AND Layer_md__r.Opportunity_md__c = :recordId');
            if (isOpp == true)
                query.add('AND Layer_md__r.Placement_lk__c = NULL');
            if (isOpp == false)
                query.add('AND Layer_md__r.Placement_lk__c=:recordId');
            query.add('');
            
            List<OPP_Panel__c> panels = Database.query(String.join(query, ' '));
            
            if (panels.isEmpty()) {
                throw new AuraHandledException('No panels found for the specified currency and record.');
            }
            
            Integer toTrue = 0, toFalse = 0;
            
            // 선택된 panel은 true, 나머지는 false로 설정
            for (OPP_Panel__c p : panels) {
                Boolean newVal = selectedSet.contains(p.Id);
                if (p.Finalize_is__c != newVal) {
                    p.Finalize_is__c = newVal;
                }
                if (newVal) {
                    toTrue++;
                } else {
                    toFalse++;
                }
            }
            
            update panels;
            System.debug('Finalize=true: ' + toTrue + ', Finalize=false: ' + toFalse);
            
            // QS 레이어 LOL 업데이트: 선택된 패널 중 QS 타입 레이어의 LOL__c를 보상한도로 설정
            if (qsLol != null && qsLol > 0) {
                List<OPP_Layer__c> qsLayers = [
                    SELECT Id, LOL__c
                    FROM OPP_Layer__c
                    WHERE
                        Id IN (
                            SELECT Layer_md__c
                            FROM OPP_Panel__c
                            WHERE Id IN :panelIds AND Layer_md__r.Type__c = 'QS'
                        )
                ];
                for (OPP_Layer__c layer : qsLayers) {
                    layer.LOL__c = qsLol;
                }
                if (!qsLayers.isEmpty()) {
                    update qsLayers;
                    System.debug('Updated ' + qsLayers.size() + ' QS layer(s) LOL__c to ' + qsLol);
                }
            }
            
            // Brokerage Adjustment용 Layer 및 Panel 'Upsert' *** Start ***
            Opportunity opp = [
                SELECT Id, InsuredGroup_lk__c, CedantName_lk__c, IsClosed, StageName, CedingType1__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];
            if (isOpp) {
                isTreaty = opp.CedingType1__c == 'Treaty';
            }
            
            // Treaty인 경우 Brkg Adj Layer/Panel 생성 불필요
            if (!isTreaty) {
                query = new List<String>();
                query.add('SELECT Id, Layer_md__c');
                query.add('FROM OPP_Panel__c');
                query.add('WHERE Currency__c = :selectedCurrency');
                query.add('AND BrkgAdj_is__c = TRUE');
                if (isOpp == true)
                    query.add('AND Layer_md__r.Opportunity_md__c = :recordId');
                if (isOpp == true)
                    query.add('AND Layer_md__r.Placement_lk__c = NULL');
                if (isOpp == false)
                    query.add('AND Layer_md__r.Placement_lk__c=:recordId');
                query.add('');
                List<OPP_Panel__c> exPanels = Database.query(String.join(query, ' '));
                
                OPP_Layer__c oppLayer;
                OPP_Panel__c oppPanel;
                if (exPanels.isEmpty()) {
                    if (isOpp) {
                        oppLayer = new OPP_Layer__c(Opportunity_md__c = recordId, LayerCurrency__c = selectedCurrency, Type__c = 'Brkg Adj');
                    } else {
                        oppLayer = new OPP_Layer__c(Opportunity_md__c = opportunityId, Placement_lk__c = recordId, LayerCurrency__c = selectedCurrency, Type__c = 'Brkg Adj');
                    }
                    oppPanel = new OPP_Panel__c(Currency__c = selectedCurrency, BrkgAdj_is__c = true);
                } else {
                    oppLayer = new OPP_Layer__c(Id = exPanels[0].Layer_md__c);
                    oppPanel = new OPP_Panel__c(Id = exPanels[0].Id);
                }
                
                // calculateSpecialRow 계산값 저장
                if (brkgAdjData != null) {
                    oppPanel.TotalBrkg__c = COM_Util.nvl(brkgAdjData.totalBrkg, 0);
                    oppPanel.NetToLKPrem__c = COM_Util.nvl(brkgAdjData.netToLKPrem, 0);
                    oppPanel.LKReBrkge__c = COM_Util.nvl(brkgAdjData.lkReBrkge, 0);
                    oppPanel.ProducingTPPBrkg__c = COM_Util.nvl(brkgAdjData.producingTPPBrkg, 0);
                    oppPanel.PlacingTPPBrkge__c = COM_Util.nvl(brkgAdjData.placingTPPBrkge, 0);
                    oppPanel.LKProducingTPPBrkg__c = COM_Util.nvl(brkgAdjData.lkProducingTPPBrkg, 0);
                    oppPanel.LKPlacingTPPBrkg__c = COM_Util.nvl(brkgAdjData.lkPlacingTPPBrkg, 0);
                    oppPanel.NetToUW__c = COM_Util.nvl(brkgAdjData.netToUW, 0);
                    oppPanel.NetProducingCobrker__c = COM_Util.nvl(brkgAdjData.netToProducingCoBroker, 0);
                    oppPanel.ToProducingAdminFee__c = COM_Util.nvl(brkgAdjData.adminFeeToProducing, 0);
                    oppPanel.ToLKAdminFee__c = COM_Util.nvl(brkgAdjData.adminFeeToLK, 0);
                    oppPanel.NetRI__c = COM_Util.nvl(brkgAdjData.netRI, 0);
                    oppPanel.Facility_lk__c = brkgAdjData.facilityId;
                    oppPanel.FacilityParticipant_lk__c = brkgAdjData.facilityParticipantId;
                    if (oppPanel.Facility_lk__c <> null && oppPanel.MarketType__c <> 'Facility')
                        oppPanel.MarketType__c = 'Facility';
                }
                
                upsert oppLayer;
                if (exPanels.isEmpty())
                    oppPanel.Layer_md__c = oppLayer.Id;
                upsert oppPanel;
            }
            // Brokerage Adjustment용 Layer 및 Panel 'Upsert' *** End ***
            
            // Opportunity Closing Update
            if (isOpp && !opp.IsClosed) {
                opp.StageName = 'Closing';
                update opp;
            }
            // Opportunity Closing Update
            
            return true;
        } catch (Exception e) {
            System.debug('Error in updatePanelFinalize: ' + e.getMessage());
            throw new AuraHandledException('Error updating panel finalize: ' + e.getMessage());
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description Simulation Panel 화면 표시 및 계산 결과 전달을 위한 Wrapper 클래스
     */
    public class PanelWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public Integer no { get; set; }
        @AuraEnabled
        public Boolean finalize { get; set; }
        @AuraEnabled
        public Id layerId { get; set; }
        @AuraEnabled
        public String layerType { get; set; }
        @AuraEnabled
        public String marketType { get; set; }
        @AuraEnabled
        public Decimal linePercent { get; set; }
        @AuraEnabled
        public Decimal netToLKPrem { get; set; }
        @AuraEnabled
        public Decimal totalBrokeragePercent { get; set; }
        @AuraEnabled
        public Decimal grossPremium { get; set; }
        @AuraEnabled
        public String reinsurer { get; set; }
        @AuraEnabled
        public String facilityMGAName { get; set; }
        @AuraEnabled
        public String leader { get; set; }
        @AuraEnabled
        public String security { get; set; }
        @AuraEnabled
        public Decimal signed { get; set; }
        @AuraEnabled
        public String curr { get; set; }
        @AuraEnabled
        public Decimal lol { get; set; }
        @AuraEnabled
        public Decimal excess { get; set; }
        @AuraEnabled
        public Decimal totalOrderPct { get; set; }
        
        @AuraEnabled
        public Decimal totalBrkg { get; set; }
        @AuraEnabled
        public Decimal lkReBrkge { get; set; }
        @AuraEnabled
        public Decimal lkProducingTPPBrkg { get; set; }
        @AuraEnabled
        public Decimal lkPlacingTPPBrkg { get; set; }
        @AuraEnabled
        public Decimal producingTPPBrkg { get; set; }
        @AuraEnabled
        public Decimal placingTPPBrkge { get; set; }
        @AuraEnabled
        public Decimal netToUW { get; set; }
        @AuraEnabled
        public Decimal netToProducingCoBroker { get; set; }
        @AuraEnabled
        public Decimal adminFeeToProducing { get; set; }
        @AuraEnabled
        public Decimal adminFeeToLK { get; set; }
        @AuraEnabled
        public Decimal netRI { get; set; }
        @AuraEnabled
        public Id facilityId { get; set; }
        @AuraEnabled
        public Id facilityParticipantId { get; set; }
        
        // ============================================================
        // Methods
        // ============================================================
        
        /**
         * @description PanelWrapper 기본 생성자이다.
         * @param 없음
         * @return 없음
         */
        public PanelWrapper() {
        }
        
        /**
         * @description Panel 데이터와 순번을 받아 PanelWrapper를 생성한다.
         * @param panel 원본 Panel 레코드
         * @param no 화면 표시용 순번
         * @return 없음
         */
        public PanelWrapper(OPP_Panel__c panel, Integer no) {
            this(panel);
            this.no = no;
        }
        
        /**
         * @description Panel 레코드를 기반으로 PanelWrapper 필드를 초기화한다.
         * @param panel 원본 Panel 레코드
         * @return 없음
         */
        public PanelWrapper(OPP_Panel__c panel) {
            this.id = panel.Id;
            this.finalize = COM_Util.nvl(panel.Finalize_is__c, false);
            this.layerId = panel.Layer_md__c;
            this.layerType = panel.Layer_md__r?.Type__c;
            this.marketType = panel.MarketType__c;
            this.linePercent = panel.Written__c;
            this.netToLKPrem = COM_Util.nvl(panel.NetToLKPrem__c, 0);
            this.totalBrokeragePercent = panel.TotalBrkgPct__c;
            this.grossPremium = COM_Util.nvl(panel.GrossPrem__c, 0);
            this.reinsurer = panel.Reinsurer_lk__r?.Name;
            this.facilityMGAName = panel.Facility_lk__r?.Name != null ? panel.Facility_lk__r.Name : panel.MGAName_lk__r?.Name;
            this.leader = panel.Leader_is__c ? 'Yes' : 'No';
            this.security = panel.Security_lk__r?.Name;
            this.signed = panel.Signed__c;
            this.curr = panel.Currency__c != null ? panel.Currency__c : panel.Layer_md__r?.LayerCurrency__c;
            this.lol = panel.Layer_md__r?.LOL__c;
            this.excess = panel.Layer_md__r?.Excess__c;
            this.totalOrderPct = panel.Layer_md__r?.Opportunity_md__r?.TotalOrderPct__c;
            this.totalBrkg = COM_Util.nvl(panel.TotalBrkg__c, 0);
            this.lkReBrkge = COM_Util.nvl(panel.LKReBrkge__c, 0);
            this.lkProducingTPPBrkg = COM_Util.nvl(panel.LKProducingTPPBrkg__c, 0);
            this.lkPlacingTPPBrkg = COM_Util.nvl(panel.LKPlacingTPPBrkg__c, 0);
            this.producingTPPBrkg = COM_Util.nvl(panel.ProducingTPPBrkg__c, 0);
            this.placingTPPBrkge = COM_Util.nvl(panel.PlacingTPPBrkge__c, 0);
            this.netToUW = COM_Util.nvl(panel.NetToUW__c, 0);
            this.netToProducingCoBroker = COM_Util.nvl(panel.NetProducingCobrker__c, 0);
            this.adminFeeToProducing = COM_Util.nvl(panel.ToProducingAdminFee__c, 0);
            this.adminFeeToLK = COM_Util.nvl(panel.ToLKAdminFee__c, 0);
            this.netRI = COM_Util.nvl(panel.NetRI__c, 0);
            this.facilityId = panel.Facility_lk__c;
            this.facilityParticipantId = panel.FacilityParticipant_lk__c;
        }
    }
}