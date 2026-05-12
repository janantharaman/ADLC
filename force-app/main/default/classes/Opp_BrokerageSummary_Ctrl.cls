/**********************************************************************************
 * @filename      : Opp_BrokerageSummary_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02 (금)
 * @group         :
 * @group-content :
 * @description   : Opportunity/Placement Brokerage Summary LWC용 Apex 컨트롤러.
 *                  Panel 데이터 기반으로 7개 카드 요약 및 Layer별 Total Order/Signed 불일치 정보를 반환한다.
 *
 * @test-class    :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-02      i2max            Create
 **********************************************************************************/
public with sharing class Opp_BrokerageSummary_Ctrl {
    // ============================================================
    // Public Methods — AuraEnabled
    // ============================================================
    
    /**
     * @description 레코드 ID로 객체 타입(Placement 여부) 및 편집 권한을 조회하여 반환한다.
     *              Placement__c인 경우 hasEditPermission은 항상 false.
     * @param  recordId  Opportunity 또는 Placement__c 레코드 ID
     * @return InitMetaWrapper  isPlacement / hasEditPermission 포함
     */
    @AuraEnabled(cacheable=true)
    public static InitMetaWrapper getInitMeta(Id recordId) {
        try {
            InitMetaWrapper w = new InitMetaWrapper();
            if (String.isBlank(recordId)) return w;
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            w.isPlacement = objectName == 'Placement__c';
            w.hasEditPermission = w.isPlacement
                ? false
                : COM_MetaUtil.checkEditPermission(recordId);
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading init meta: ' + e.getMessage());
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description getInitMeta 반환 Wrapper. LWC 초기 렌더링 제어에 사용한다.
     */
    public class InitMetaWrapper {
        @AuraEnabled
        public Boolean isPlacement { get; set; }
        @AuraEnabled
        public Boolean hasEditPermission { get; set; }
        public InitMetaWrapper() {
            isPlacement = false;
            hasEditPermission = false;
        }
    }
    
    /**
     * @description Opportunity/Placement의 Panel 데이터를 집계하여 7개 카드 요약 및 Layer 불일치 정보를 반환한다.
     *              Placement인 경우 parent Opportunity를 역조회하여 TotalOrderPct를 사용한다.
     * @param  recordId    Opportunity 또는 Placement__c 레코드 ID
     * @param  curr        선택된 통화 코드
     * @param  panelIds    선택된 Panel ID 목록 (null이면 Finalize/BrkgAdj Panel 전체 대상)
     * @param  hasCIDetail CI Detail 조건 충족 여부 (프론트엔드에서 전달)
     * @return BrokerageSummaryWrapper  7개 카드 요약 + mismatchedLayers 포함
     */
    @AuraEnabled(cacheable=true)
    public static BrokerageSummaryWrapper getBrokerageSummary(
        Id recordId,
    String curr,
    List<Id> panelIds,
    Boolean hasCIDetail
    ) {
        BrokerageSummaryWrapper wrapper = new BrokerageSummaryWrapper();
        
        try {
            System.debug('getBrokerageSummary - recordId: ' + recordId + ', currency: ' + curr);
            
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            
            // Placement인 경우 parent Opportunity 조회
            Id oppId;
            Decimal placementTotalOrderPct = null;
            Placement__c placement = null;
            if (isPlacement) {
                placement = [
                        SELECT Opportunity_lk__c, TotalOrderPct__c, CedingType1__c, TransactionType__c
                        FROM Placement__c
                        WHERE Id = :recordId
                        LIMIT 1
                ];
                oppId = placement.Opportunity_lk__c;
                placementTotalOrderPct = placement.TotalOrderPct__c;
            } else {
                oppId = recordId;
            }
            
            // 1. Gross Premium: TSI by Location의 GrossPrem_fm__c 합계
            List<OPP_TSIByLocation__c> tsiLocations = isPlacement
                ? [
                            SELECT Id, GrossPrem_fm__c, PremiumCurrency__c
                            FROM OPP_TSIByLocation__c
                            WHERE
                                    SlipInfo_md__r.Placement_lk__c = :recordId
                                    AND PremiumCurrency__c = :curr
                                    AND SlipInfo_md__r.Latest_is__c = TRUE
                    ]
                : [
                            SELECT Id, GrossPrem_fm__c, PremiumCurrency__c
                            FROM OPP_TSIByLocation__c
                            WHERE
                                    SlipInfo_md__r.Opportunity_lk__c = :recordId
                                    AND PremiumCurrency__c = :curr
                                    AND SlipInfo_md__r.Latest_is__c = TRUE
                    ];
            
            Decimal grossPremiumFromTSI = 0;
            for (OPP_TSIByLocation__c tsi : tsiLocations) {
                grossPremiumFromTSI += COM_Util.nvl(tsi.GrossPrem_fm__c, 0);
            }
            
            // 선택된 Panel ID가 있으면 해당 Panel들만 조회, 없으면 Finalize된 모든 Panel 조회
            List<String> selectedFields = new List<String>{
                'Id', 'GrossPrem__c', 'Signed__c', 'NetToLKPrem__c',
                'NetProducingCobrker__c', 'NetToUW__c', 'ToProducingAdminFee__c',
                'ToLKAdminFee__c', 'TotalBrkg__c', 'LKReBrkge__c',
                'LKProducingTPPBrkg__c', 'LKPlacingTPPBrkg__c', 'ProducingTPPBrkg__c',
                'PlacingTPPBrkge__c', 'LKAdminFee__c', 'LKTPPBrkge__c',
                'BrkgAdj_is__c', 'Finalize_is__c',
                'Layer_md__c',
                'Layer_md__r.LayerCurrency__c', 'Layer_md__r.Placement_lk__c',
                'Layer_md__r.Type__c', 'Layer_md__r.LOL__c', 'Layer_md__r.Excess__c',
                'Layer_md__r.Opportunity_md__c',
                'Layer_md__r.Opportunity_md__r.TotalOrderPct__c',
                'Layer_md__r.Opportunity_md__r.RICommPct__c', 'Layer_md__r.Opportunity_md__r.OtherDeductionsPct__c',
                'Layer_md__r.Opportunity_md__r.CedingType1__c'
            };
            List<String> query = new List<String>();
            query.add('SELECT ');
            query.add(String.join(selectedFields, ', '));
            query.add('FROM OPP_Panel__c');
            if (isPlacement) query.add('WHERE Layer_md__r.Placement_lk__c = :recordId');
            
            if (!isPlacement) query.add('WHERE Layer_md__r.Opportunity_md__c = :recordId');
            if (!isPlacement) query.add('AND Layer_md__r.Placement_lk__c = NULL');
            
            if (panelIds != null && !panelIds.isEmpty()) {
                query.add('AND Id IN :panelIds');
            } else {
                query.add('AND (Finalize_is__c = TRUE OR BrkgAdj_is__c = TRUE)');
            }
            
            query.add('AND Layer_md__r.LayerCurrency__c = :curr');
            
            // Panel 데이터 조회
            List<OPP_Panel__c> panels = Database.query(String.join(query, ' '));
            System.debug('🔍 [BrokerageSummary] panelIds=' + panelIds + ', isPlacement=' + isPlacement + ', recordId=' + recordId + ', curr=' + curr);
            System.debug('🔍 [BrokerageSummary] SOQL=' + String.join(query, ' '));
            System.debug('🔍 [BrokerageSummary] panels.size()=' + panels.size());
            
            // Opportunity 조회 (Placement인 경우 parent Opp)
            Opportunity opp;
            
            if (panels.isEmpty()) {
                if (oppId == null) {
                    return wrapper; // Opportunity 연결 없으면 빈 결과 반환
                }
                List<Opportunity> opportunities = [
                        SELECT Id, TotalOrderPct__c, RICommPct__c, OtherDeductionsPct__c, CedingType1__c
                        FROM Opportunity
                        WHERE Id = :oppId
                        LIMIT 1
                ];
                if (opportunities.isEmpty()) return wrapper;
                opp = opportunities[0];
            }
            if (!panels.isEmpty()) opp = panels[0].Layer_md__r.Opportunity_md__r;
            
            // Treaty 또는 Declaration인 경우 GrossPrem을 PremiumSchedule.SlipGrossPrem__c 기준으로 조회
            String oppCedingType = !panels.isEmpty()
                ? panels[0].Layer_md__r?.Opportunity_md__r?.CedingType1__c
                : opp?.CedingType1__c;
            Boolean isTreatyOrDeclaration = oppCedingType == 'Treaty'
                || (isPlacement && (placement.CedingType1__c == 'Treaty' || placement.TransactionType__c == 'Declaration'))
                || Boolean.valueOf(hasCIDetail);
            
            if (isTreatyOrDeclaration) {
                List<OPP_PremiumSchedule__c> schedules = isPlacement
                    ? [
                                SELECT SlipGrossPrem__c
                                FROM OPP_PremiumSchedule__c
                                WHERE Placement_lk__c = :recordId AND Prem_Currency__c = :curr AND Type__c != 'Slip'
                                ORDER BY CreatedDate ASC
                          ]
                    : [
                                SELECT SlipGrossPrem__c
                                FROM OPP_PremiumSchedule__c
                                WHERE Opportunity_lk__c = :oppId AND Prem_Currency__c = :curr AND Type__c != 'Slip'
                                ORDER BY CreatedDate ASC
                          ];
                if (!schedules.isEmpty()) {
                    grossPremiumFromTSI = COM_Util.nvl(schedules[0].SlipGrossPrem__c, 0);
                }
            }
            
            // 1번 카드: Gross Prem
            wrapper.grossPremium = grossPremiumFromTSI;
            
            // Placement인 경우 Placement__c.TotalOrderPct__c, 아닌 경우 Opportunity.TotalOrderPct__c 사용
            Decimal effectiveTotalOrderPct = isPlacement
                ? COM_Util.nvl(placementTotalOrderPct, 0)
                : COM_Util.nvl(opp.TotalOrderPct__c, 0);
            
            // 2번 카드: Total Order(%)/Signed(%)
            wrapper.totalOrderPct = effectiveTotalOrderPct;
            wrapper.signedPct = COM_Util.nvl(sumField(panels, 'Signed__c'), 0);
            
            // 3번 카드: Net to
            wrapper.netToProducingCoBroker = sumField(panels, 'NetProducingCobrker__c'); //ok
            wrapper.netToLKPrem = sumField(panels, 'NetToLKPrem__c'); //ok
            wrapper.netToUW = sumField(panels, 'NetToUW__c'); //ok
            
            // 4번 카드: Admin Fee
            wrapper.adminFeeToProducing = sumField(panels, 'ToProducingAdminFee__c'); //A
            wrapper.adminFeeToLK = sumField(panels, 'ToLKAdminFee__c'); //B
            
            // 5번 카드: Brkg
            wrapper.totalBrkg = sumField(panels, 'TotalBrkg__c'); //ok
            wrapper.lkReBrkge = sumField(panels, 'LKReBrkge__c'); //ok (a)
            wrapper.lkTPPBrokerage =
                sumField(panels, 'LKProducingTPPBrkg__c') + sumField(panels, 'LKPlacingTPPBrkg__c'); //ok
            wrapper.lkBrokerage = wrapper.lkReBrkge + wrapper.lkTPPBrokerage; //C
            wrapper.tppBrokerage =
                sumField(panels, 'ProducingTPPBrkg__c') + sumField(panels, 'PlacingTPPBrkge__c'); //(D)
            
            // 6번 카드: LK Re Brkg
            Decimal totalNetToLKPrem = wrapper.netToLKPrem;
            wrapper.lkReBrokeragePercent = totalNetToLKPrem != 0
                ? COM_Util.divide(wrapper.lkReBrkge, totalNetToLKPrem, 4, RoundingMode.HALF_UP) * 100
                : 0; //ok
            
            // Proportional (Type = QS)
            Decimal proportionalBrkge = 0;
            Decimal proportionalNetPrem = 0;
            for (OPP_Panel__c panel : panels) {
                if (panel.Layer_md__r.Type__c == 'QS') {
                    proportionalBrkge += COM_Util.nvl(panel.LKReBrkge__c, 0);
                    proportionalNetPrem += COM_Util.nvl(panel.NetToLKPrem__c, 0); //(1)
                }
            }
            wrapper.proportional = proportionalBrkge; //ok (b)
            wrapper.proportionalPercent =
                COM_Util.divide(proportionalBrkge, proportionalNetPrem, 4, RoundingMode.HALF_UP) * 100; //수정본
            
            // Brkg Adj (Type = 'Brkg Adj'인 Market Line의 LK Re Brokerage 합계)
            Decimal brkgAdjAmount = 0;
            Decimal brkgNetToLKPrem = 0;
            Map<Id, OPP_Layer__c> filteredLayers = new Map<Id, OPP_Layer__c>();
            List<OPP_Panel__c> filteredPanels = new List<OPP_Panel__c>();
            for (OPP_Panel__c panel : panels) {
                if (panel.Layer_md__r.Type__c == 'Brkg Adj') {
                    brkgAdjAmount += COM_Util.nvl(panel.LKReBrkge__c, 0);
                    brkgNetToLKPrem += COM_Util.nvl(panel.NetToLKPrem__c, 0); //(2)
                } else {
                    filteredPanels.add(panel);
                    filteredLayers.put(panel.Layer_md__c, panel.Layer_md__r);
                }
            }
            wrapper.brkgAdj = brkgAdjAmount; //(c)
            
            // Non-Proportional = LK Re Brokerage - Proportional - Brkg Adj
            wrapper.nonProportional = wrapper.lkReBrkge - wrapper.proportional - wrapper.brkgAdj; // (d)
            
            Decimal nonProportionalNetPrem =
                (totalNetToLKPrem - proportionalNetPrem) - brkgNetToLKPrem; //(1)-(2)
            wrapper.nonProportionalPercent = nonProportionalNetPrem != 0
                ? COM_Util.divide(
                wrapper.nonProportional,
            nonProportionalNetPrem,
            4,
            RoundingMode.HALF_UP
                ) * 100
                : 0; //(d)/((1)-(2))
            
            // 7번 카드: Brkg (after admin)
            wrapper.lkReBrokerageAfterAdmin =
                wrapper.adminFeeToProducing +
                wrapper.adminFeeToLK +
                wrapper.lkBrokerage; //A+B+C
            
            wrapper.tppBrokerageAfterAdmin =
                wrapper.tppBrokerage -
                wrapper.adminFeeToProducing -
                wrapper.adminFeeToLK;
            
            // Panel 존재 여부
            wrapper.hasPanels = !panels.isEmpty();
            
            // 전체 Layer의 maxY 계산 (선택 여부 무관)
            Decimal globalMaxY = 0;
            List<OPP_Layer__c> allLayers = filteredLayers.values();
            System.debug('calculateMismatchedLayers 💡💡💡 allLayers.size()=[' + allLayers.size() + ']');
            
            for (OPP_Layer__c layer : allLayers) {
                Decimal layerLimit = COM_Util.toDec(layer.Excess__c) + COM_Util.toDec(layer.LOL__c);
                if (layerLimit > globalMaxY) {
                    globalMaxY = layerLimit;
                }
            }
            
            // Layer별 Total Order/Signed 비교 (불일치만)
            wrapper.mismatchedLayers = calculateMismatchedLayers(
                filteredPanels,
            effectiveTotalOrderPct,
            globalMaxY
                );
            System.debug('Mismatched Layers: ' + wrapper.mismatchedLayers);
        } catch (Exception e) {
            System.debug('Error in getBrokerageSummary: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading brokerage summary: ' + e.getMessage());
        }
        
        return wrapper;
    }
    
    // ============================================================
    // Public Methods
    // ============================================================
    
    /**
     * @description Layer 구간별 Signed(%)와 TotalOrder(%)를 비교하여 불일치 구간 목록을 반환한다.
     *              Breakpoint 기반으로 구간을 분할하고, 'Placement Done' 구간은 결과에서 제외한다.
     *              (단, 모든 패널이 Excess 타입인 경우, 보험 효력이 시작되지 않는 0부터 최소 Excess 미만 구간은 제외)
     * @param  panels           비교 대상 Panel 목록
     * @param  oppTotalOrderPct Opportunity의 Total Order Percent
     * @param  globalMaxY       전체 Layer 중 최대 Y값 (Excess + LOL 최댓값)
     * @return List<LayerComparison>  불일치 구간 목록
     */
    public static List<LayerComparison> calculateMismatchedLayers(
        List<OPP_Panel__c> panels,
    Decimal oppTotalOrderPct,
    Decimal globalMaxY
    ) {
        List<LayerComparison> mismatchedLayers = new List<LayerComparison>();
        //        System.debug('calculateMismatchedLayers 💵💵💵 panels.size()=['+ panels.size() +'], oppTotalOrderPct=['+ oppTotalOrderPct +'], globalMaxY=['+ globalMaxY +']');
        if (panels.isEmpty()) {
            // Panel이 비어있어도 globalMaxY가 있으면 전체 segment를 Shortfall로 표시
            if (globalMaxY > 0) {
                //                System.debug('calculateMismatchedLayers 💡💡💡 Shortfall globalMaxY=['+ globalMaxY +']');
                String segmentLabel = getSegmentLabel(0, globalMaxY);
                mismatchedLayers.add(
                    new LayerComparison(segmentLabel, oppTotalOrderPct, 0, 'Shortfall')
                    );
            }
            return mismatchedLayers;
        }
        
        // QS-only 케이스: Excess/LOL이 모두 0이어서 Breakpoint 로직이 무의미한 경우를 분리 처리
        Boolean allQS = true;
        for (OPP_Panel__c panel : panels) {
            if (panel.Layer_md__r.Type__c != 'QS') {
                allQS = false;
                break;
            }
        }
        if (allQS) {
            //            System.debug('calculateMismatchedLayers 💡💡💡 All QS layers detected — delegating to calculateMismatchedLayersForAllQS');
            return calculateMismatchedLayersForAllQS(panels, oppTotalOrderPct);
        }
        Boolean isExcessOnly = true;
        Decimal minExcess = null;
        Map<Id, LayerSegmentData> layerMap = new Map<Id, LayerSegmentData>();
        for (OPP_Panel__c panel : panels) {
            
            OPP_Layer__c oppLayer = panel.Layer_md__r;
            Decimal excess = COM_Util.nvl(oppLayer.Excess__c, 0);
            
            if(isExcessOnly && oppLayer.Type__c != 'Excess') isExcessOnly = false;
            if(minExcess==null || excess < minExcess) minExcess = excess;
            
            Id layerId = oppLayer.Id;
            if (!layerMap.containsKey(layerId)) {
                layerMap.put(layerId, new LayerSegmentData(layerId, excess, COM_Util.nvl(oppLayer.LOL__c, 0)));
            }
            layerMap.get(layerId).totalSigned += COM_Util.nvl(panel.Signed__c, 0);
        }
        //        System.debug('calculateMismatchedLayers 💡💡💡 layerMap=['+ layerMap +']');
        
        Set<Decimal> breakpointSet = new Set<Decimal>();
        breakpointSet.add(0);
        
        for (LayerSegmentData layer : layerMap.values()) {
            breakpointSet.add(layer.y0);
            breakpointSet.add(layer.y1);
        }
        
        // 전체 Layer의 maxY를 breakpoint에 추가
        breakpointSet.add(globalMaxY);
        System.debug('Breakpoints: ' + breakpointSet);
        List<Decimal> breakpoints = new List<Decimal>(breakpointSet);
        breakpoints.sort();
        
        for (Integer i = 0; i < breakpoints.size() - 1; i++) {
            Decimal segMin = breakpoints[i];
            Decimal segMax = breakpoints[i + 1];
            
            if (segMax <= segMin) {
                continue;
            }
            
            // [2026-04-22] Excess-only일 때 하단 구간 skip
            if (isExcessOnly && minExcess != null && segMax <= minExcess) continue;
            //            System.debug('🌼🌼🌼🌼🌼 isExcessOnly=[' + isExcessOnly+ '], minExcess=[' + minExcess+'], segMax=['+ segMax +']');
            
            Decimal segmentSigned = 0;
            for (LayerSegmentData layer : layerMap.values()) {
                if (layer.y0 <= segMin && layer.y1 >= segMax) {
                    segmentSigned += layer.totalSigned;
                }
            }
            
            String segmentLabel = getSegmentLabel(segMin, segMax);
            String status = determineStatus(oppTotalOrderPct, segmentSigned);
            System.debug('calculateMismatchedLayers >>> segmentLabel=['+ segmentLabel +'], status=['+ status +']');
            
            if (status != 'Placement Done') {
                mismatchedLayers.add(
                    new LayerComparison(segmentLabel, oppTotalOrderPct, segmentSigned, status)
                    );
            }
        }
        return mismatchedLayers;
    }
    
    // ============================================================
    // Private Methods
    // ============================================================
    
    /**
     * @description Layer 구간의 레이블 문자열을 생성한다.
     *              segMin=0이면 "{max} xs OPDs", 아니면 "{diff} xs {min} xs OPDs" 형식.
     * @param  segMin  구간 시작값
     * @param  segMax  구간 종료값
     * @return String  레이블 문자열
     */
    private static String getSegmentLabel(Decimal segMin, Decimal segMax) {
        String minFormatted = segMin.setScale(0, RoundingMode.HALF_UP).format();
        String maxFormatted = segMax.setScale(0, RoundingMode.HALF_UP).format();
        
        if (segMin == 0) {
            return maxFormatted + ' xs OPDs';
        }
        
        Decimal diff = segMax - segMin;
        String diffFormatted = diff.setScale(0, RoundingMode.HALF_UP).format();
        return diffFormatted + ' xs ' + minFormatted + ' xs OPDs';
    }
    
    /**
     * @description filteredPanels가 모두 QS(Quota Share) Type일 때 호출된다.
     *              QS Layer는 Excess/LOL이 0이어서 Breakpoint 방식으로는 구간을 생성할 수 없으므로,
     *              Layer별 Signed(%) 합산 값을 TotalOrder(%)와 직접 비교하여 불일치 목록을 반환한다.
     * @param  panels           비교 대상 Panel 목록 (모두 QS Type)
     * @param  oppTotalOrderPct Opportunity의 Total Order Percent
     * @return List<LayerComparison>  불일치 구간 목록
     */
    private static List<LayerComparison> calculateMismatchedLayersForAllQS(
        List<OPP_Panel__c> panels,
    Decimal oppTotalOrderPct
    ) {
        List<LayerComparison> mismatchedLayers = new List<LayerComparison>();
        
        // QS는 excess=0으로 전체 구간을 커버하므로 Layer 수와 무관하게 Signed 전체 합산 후 1줄 비교
        Decimal totalSigned = 0;
        for (OPP_Panel__c panel : panels) {
            totalSigned += COM_Util.nvl(panel.Signed__c, 0);
        }
        
        String status = determineStatus(oppTotalOrderPct, totalSigned);
        System.debug('calculateMismatchedLayersForAllQS >>> oppTotalOrderPct=[' + oppTotalOrderPct + '], totalSigned=[' + totalSigned + '], status=[' + status + ']');
        
        if (status != 'Placement Done') {
            mismatchedLayers.add(new LayerComparison('QS', oppTotalOrderPct, totalSigned, status));
        }
        
        return mismatchedLayers;
    }
    
    /**
     * @description TotalOrder(%)와 Signed(%)를 비교하여 구간 상태를 반환한다.
     * @param  totalOrderPct  Opportunity TotalOrder Percent
     * @param  signedLine     해당 구간의 합산 Signed Percent
     * @return String         'Shortfall' / 'Placement Done' / 'Over Placed'
     */
    private static String determineStatus(Decimal totalOrderPct, Decimal signedLine) {
        System.debug('determineStatus >>> totalOrderPct=['+ totalOrderPct +'], signedLine=['+ signedLine +']');
        if (totalOrderPct > signedLine) {
            return 'Shortfall';
        } else if (totalOrderPct == signedLine) {
            return 'Placement Done';
        } else {
            return 'Over Placed';
        }
    }
    
    /**
     * @description Panel 목록에서 특정 필드의 합계를 반환한다. null 값은 0으로 처리한다.
     * @param  panels     집계 대상 Panel 목록
     * @param  fieldName  집계할 필드명
     * @return Decimal    필드 합계
     */
    private static Decimal sumField(List<OPP_Panel__c> panels, String fieldName) {
        Decimal total = 0;
        for (OPP_Panel__c panel : panels) {
            Object fieldValue = panel.get(fieldName);
            if (fieldValue != null) {
                total += (Decimal) fieldValue;
            }
        }
        return total;
    }
    
    /**
     * @description calculateMismatchedLayers 내부에서 Layer별 구간 데이터를 집계하는 내부 클래스.
     */
    private class LayerSegmentData {
        public Id layerId;
        public Decimal y0;
        public Decimal y1;
        public Decimal totalSigned;
        
        public LayerSegmentData(Id layerId, Decimal excess, Decimal lol) {
            this.layerId = layerId;
            this.y0 = excess;
            this.y1 = excess + lol;
            this.totalSigned = 0;
        }
    }
    
    /**
     * @description getBrokerageSummary 반환 Wrapper. 7개 카드 지표 및 Layer 불일치 목록을 포함한다.
     */
    public class BrokerageSummaryWrapper {
        @AuraEnabled
        public Decimal grossPremium { get; set; }
        @AuraEnabled
        public Decimal totalOrderPct { get; set; }
        @AuraEnabled
        public Decimal signedPct { get; set; }
        @AuraEnabled
        public Decimal netToProducingCoBroker { get; set; }
        @AuraEnabled
        public Decimal netToLKPrem { get; set; }
        @AuraEnabled
        public Decimal netToUW { get; set; }
        @AuraEnabled
        public Decimal adminFeeToProducing { get; set; }
        @AuraEnabled
        public Decimal adminFeeToLK { get; set; }
        @AuraEnabled
        public Decimal totalBrkg { get; set; }
        @AuraEnabled
        public Decimal lkBrokerage { get; set; }
        @AuraEnabled
        public Decimal lkReBrkge { get; set; }
        @AuraEnabled
        public Decimal lkTPPBrokerage { get; set; }
        @AuraEnabled
        public Decimal tppBrokerage { get; set; }
        @AuraEnabled
        public Decimal lkReBrokeragePercent { get; set; }
        @AuraEnabled
        public Decimal proportional { get; set; }
        @AuraEnabled
        public Decimal proportionalPercent { get; set; }
        @AuraEnabled
        public Decimal nonProportional { get; set; }
        @AuraEnabled
        public Decimal nonProportionalPercent { get; set; }
        @AuraEnabled
        public Decimal brkgAdj { get; set; }
        @AuraEnabled
        public Decimal lkReBrokerageAfterAdmin { get; set; }
        @AuraEnabled
        public Decimal tppBrokerageAfterAdmin { get; set; }
        @AuraEnabled
        public List<LayerComparison> mismatchedLayers { get; set; }
        @AuraEnabled
        public Boolean hasPanels { get; set; }
        
        public BrokerageSummaryWrapper() {
            this.grossPremium = 0;
            this.totalOrderPct = 0;
            this.signedPct = 0;
            this.netToProducingCoBroker = 0;
            this.netToLKPrem = 0;
            this.netToUW = 0;
            this.adminFeeToProducing = 0;
            this.adminFeeToLK = 0;
            this.totalBrkg = 0;
            this.lkBrokerage = 0;
            this.lkReBrkge = 0;
            this.lkTPPBrokerage = 0;
            this.tppBrokerage = 0;
            this.lkReBrokeragePercent = 0;
            this.proportional = 0;
            this.proportionalPercent = 0;
            this.nonProportional = 0;
            this.nonProportionalPercent = 0;
            this.brkgAdj = 0;
            this.lkReBrokerageAfterAdmin = 0;
            this.tppBrokerageAfterAdmin = 0;
            this.mismatchedLayers = new List<LayerComparison>();
            this.hasPanels = false;
        }
    }
    
    /**
     * @description Layer 구간별 TotalOrder/Signed 비교 결과 Wrapper. mismatchedLayers 항목으로 사용된다.
     */
    public class LayerComparison {
        @AuraEnabled
        public String layerName { get; set; }
        @AuraEnabled
        public Decimal totalOrderPct { get; set; }
        @AuraEnabled
        public Decimal signedPct { get; set; }
        @AuraEnabled
        public String status { get; set; }
        
        public LayerComparison(
            String layerName,
        Decimal totalOrderPct,
        Decimal signedPct,
        String status
        ) {
            this.layerName = layerName;
            this.totalOrderPct = totalOrderPct;
            this.signedPct = signedPct;
            this.status = status;
        }
    }
}