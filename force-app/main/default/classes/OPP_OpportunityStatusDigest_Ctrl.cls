/**********************************************************************************
 * @filename      : OPP_OpportunityStatusDigest_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-02 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : OPP_OpportunityStatusDigest_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-02      i2max     Create
**********************************************************************************/
public with sharing class OPP_OpportunityStatusDigest_Ctrl {

    public Id oppId { get; set; }

    // 쿼리 결과를 저장할 변수 (Lazy Loading)
    private List<OPP_Layer__c> cachedLayers;

    // Layer 목록 (Panel 포함)
    public List<OPP_Layer__c> getLayers() {

        System.debug('>>> [Ctrl] getLayers called. oppId: ' + oppId);

        // 이미 쿼리했으면 재사용
        if (cachedLayers != null) {
            System.debug('>>> [Ctrl] Returning cachedLayers. Size: ' + cachedLayers.size());
            return cachedLayers;
        }

        if (oppId == null) {
            System.debug('>>> [Ctrl] oppId is NULL. Returning empty list.');
            return new List<OPP_Layer__c>();
        }

        cachedLayers = [
                SELECT Id, Type__c, (SELECT Id, MarketType__c, Currency__c FROM Panels__r ORDER BY Currency__c)
                FROM OPP_Layer__c
                WHERE Opportunity_md__c = :oppId
                ORDER BY Name // 정렬 기준
        ];
        System.debug('>>> [Ctrl] Query executed. Result Size: ' + cachedLayers.size());

        return cachedLayers;
    }

    // 데이터 존재 여부 확인
    public Boolean getHasLayers() {
        System.debug('>>> [Ctrl] getHasLayers called.');
        Boolean hasData = !getLayers().isEmpty();
        System.debug('>>> [Ctrl] hasData: ' + hasData);
        return hasData;
    }

}