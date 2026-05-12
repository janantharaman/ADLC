/**********************************************************************************
 * @filename      : Opp_TotalOrderSignedModal_Ctrl.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02
 * @group         :
 * @group-content :
 * @description   : Total Order / Signed 비교 모달 데이터 조회를 처리하는 컨트롤러
 * @test-class    :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-02      i2max            Create
 **********************************************************************************/
public with sharing class Opp_TotalOrderSignedModal_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description Segment 기준으로 Total Order / Signed 비교 데이터를 조회한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @param curr 선택한 통화 값
     * @param refreshKey 화면 refresh 트리거용 값
     * @param panelIds 시뮬레이션에서 선택한 Panel Id 목록 (지정 시 해당 패널만 계산)
     * @return List<LayerPanelWrapper> Segment별 Total Order / Signed 비교 결과 목록
     */
    @AuraEnabled(cacheable=true)
    public static List<LayerPanelWrapper> getTotalOrderSignedData(Id recordId, String curr, Integer refreshKey, List<Id> panelIds) {
        List<LayerPanelWrapper> result = new List<LayerPanelWrapper>();
        
        try {
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            Boolean hasPanelFilter = panelIds != null && !panelIds.isEmpty();
            
            Decimal oppTotalOrderPct = 0;
            // Placement인 경우 parent Opportunity로 TotalOrderPct 조회
            if (isPlacement) {
                Placement__c placement = [
        SELECT Opportunity_lk__c, TotalOrderPct__c
        FROM Placement__c
        WHERE Id = :recordId
        LIMIT 1
    ];
                oppTotalOrderPct = COM_Util.nvl(placement.TotalOrderPct__c, 0);
            } else {
                
                Opportunity opp = [
        SELECT Id, TotalOrderPct__c
        FROM Opportunity
        WHERE Id = :recordId
        LIMIT 1
    ];
                oppTotalOrderPct = COM_Util.nvl(opp.TotalOrderPct__c, 0);
            }
            
            // 전체 Layer의 maxY 계산 (Finalize 여부 무관)
            Decimal globalMaxY = 0;
            List<OPP_Layer__c> allLayers = isPlacement
                ? [
                      SELECT Id, Excess__c, LOL__c
                      FROM OPP_Layer__c
                      WHERE Placement_lk__c = :recordId AND LayerCurrency__c = :curr
                  ]
                : [
                      SELECT Id, Excess__c, LOL__c
                      FROM OPP_Layer__c
                      WHERE Opportunity_md__c = :recordId AND LayerCurrency__c = :curr
                  ];
            
            for (OPP_Layer__c layer : allLayers) {
                Decimal layerLimit = COM_Util.nvl(layer.Excess__c, 0) + COM_Util.nvl(layer.LOL__c, 0);
                if (layerLimit > globalMaxY) {
                    globalMaxY = layerLimit;
                }
            }
            
            // Panel 조회: panelIds가 지정된 경우 해당 Panel만, 아닌 경우 Finalized Panel 전체 조회
            List<OPP_Panel__c> panels;
            if (hasPanelFilter) {
                panels = [
                    SELECT Id, Signed__c, Layer_md__c, Layer_md__r.LOL__c, Layer_md__r.Excess__c
                    FROM OPP_Panel__c
                    WHERE Id IN :panelIds AND BrkgAdj_is__c = FALSE
                ];
            } else {
                panels = isPlacement
                    ? [
                          SELECT Id, Signed__c, Layer_md__c, Layer_md__r.LOL__c, Layer_md__r.Excess__c
                          FROM OPP_Panel__c
                          WHERE Layer_md__r.Placement_lk__c = :recordId AND Layer_md__r.LayerCurrency__c = :curr AND BrkgAdj_is__c = FALSE
                      ]
                    : [
                          SELECT Id, Signed__c, Layer_md__c, Layer_md__r.LOL__c, Layer_md__r.Excess__c
                          FROM OPP_Panel__c
                          WHERE Layer_md__r.Opportunity_md__c = :recordId AND Layer_md__r.LayerCurrency__c = :curr AND Layer_md__r.Placement_lk__c = NULL AND BrkgAdj_is__c = FALSE and Finalize_is__c = TRUE
                      ];
            }
            
            // 1. Layer별 데이터 수집
            Map<Id, LayerSegmentData> layerMap = new Map<Id, LayerSegmentData>();
            for (OPP_Panel__c panel : panels) {
                Id layerId = panel.Layer_md__c;
                if (!layerMap.containsKey(layerId)) {
                    Decimal excess = COM_Util.nvl(panel.Layer_md__r.Excess__c, 0);
                    Decimal lol = COM_Util.nvl(panel.Layer_md__r.LOL__c, 0);
                    layerMap.put(layerId, new LayerSegmentData(layerId, excess, lol));
                }
                layerMap.get(layerId).totalSigned += COM_Util.nvl(panel.Signed__c, 0);
            }
            
            // 2. Breakpoints 생성
            Set<Decimal> breakpointSet = new Set<Decimal>();
            breakpointSet.add(0);
            
            for (LayerSegmentData layer : layerMap.values()) {
                breakpointSet.add(layer.y0);
                breakpointSet.add(layer.y1);
            }
            
            // 전체 Layer의 maxY를 breakpoint에 추가
            breakpointSet.add(globalMaxY);
            
            List<Decimal> breakpoints = new List<Decimal>(breakpointSet);
            breakpoints.sort();
            
            // 3. Segments 생성 및 signed 계산
            Integer rowNum = 1;
            for (Integer i = 0; i < breakpoints.size() - 1; i++) {
                Decimal segMin = breakpoints[i];
                Decimal segMax = breakpoints[i + 1];
                
                if (segMax <= segMin) {
                    continue;
                }
                
                // 이 segment를 커버하는 레이어들의 signed 합계
                Decimal segmentSigned = 0;
                for (LayerSegmentData layer : layerMap.values()) {
                    if (layer.y0 <= segMin && layer.y1 >= segMax) {
                        segmentSigned += layer.totalSigned;
                    }
                }
                
                LayerPanelWrapper wrapper = new LayerPanelWrapper();
                wrapper.rowNumber = rowNum++;
                wrapper.layerId = String.valueOf(segMin) + '-' + String.valueOf(segMax);
                
                // Segment 라벨 생성
                wrapper.layerLimit = getSegmentLabel(segMin, segMax);
                wrapper.signedLine = segmentSigned.setScale(2, RoundingMode.HALF_UP).format() + '%';
                
                // 상태 결정 및 클래스 설정
                wrapper.status = determineStatus(oppTotalOrderPct, segmentSigned);
                wrapper.statusClass = getStatusClass(wrapper.status);
                
                result.add(wrapper);
            }
        } catch (Exception e) {
            System.debug('Error in getTotalOrderSignedData: ' + e.getMessage());
            throw new AuraHandledException('Error loading Total Order/Signed data: ' + e.getMessage());
        }
        
        System.debug('Total Order/Signed Data Result: ' + result);
        return result;
    }
    
    /**
     * @description Segment 구간 표시용 라벨 문자열을 생성한다.
     * @param segMin Segment 시작값
     * @param segMax Segment 종료값
     * @return String Segment 라벨 문자열
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
     * @description Total Order와 Signed 값을 비교하여 상태를 반환한다.
     * @param totalOrderPct Total Order 비율
     * @param signedLine Signed 비율
     * @return String 비교 결과 상태값
     */
    private static String determineStatus(Decimal totalOrderPct, Decimal signedLine) {
        if (totalOrderPct > signedLine) {
            return 'Shortfall';
        } else if (totalOrderPct == signedLine) {
            return 'Placement Done';
        } else {
            return 'Over Placed';
        }
    }
    
    /**
     * @description 상태값에 따라 화면 표시용 CSS 클래스를 반환한다.
     * @param status 상태값
     * @return String 상태별 CSS 클래스명
     */
    private static String getStatusClass(String status) {
        if (status == 'Shortfall') {
            return 'status-shortfall';
        } else if (status == 'Placement Done') {
            return 'status-done';
        } else if (status == 'Over Placed') {
            return 'status-overplaced';
        }
        return '';
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description Segment 계산을 위한 Layer 기준 데이터를 보관하는 내부 클래스
     * @param layerId Layer Id
     * @param excess Layer Excess 값
     * @param lol Layer LOL 값
     * @return 없음
     */
    private class LayerSegmentData {
        public Id layerId;
        public Decimal y0; // excess
        public Decimal y1; // excess + lol
        public Decimal totalSigned;
        
        /**
         * @description Layer Segment 계산용 초기값을 설정한다.
         * @param layerId Layer Id
         * @param excess Layer Excess 값
         * @param lol Layer LOL 값
         * @return 없음
         */
        public LayerSegmentData(Id layerId, Decimal excess, Decimal lol) {
            this.layerId = layerId;
            this.y0 = excess;
            this.y1 = excess + lol;
            this.totalSigned = 0;
        }
    }
    
    /**
     * @description 화면 표시용 Layer Panel 데이터를 전달하는 Wrapper 클래스
     */
    public class LayerPanelWrapper {
        @AuraEnabled
        public Integer rowNumber { get; set; }
        
        @AuraEnabled
        public String layerId { get; set; }
        
        @AuraEnabled
        public String layerLimit { get; set; }
        
        @AuraEnabled
        public String signedLine { get; set; }
        
        @AuraEnabled
        public String status { get; set; }
        
        @AuraEnabled
        public String statusClass { get; set; }
    }
}