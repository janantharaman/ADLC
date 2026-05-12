/**********************************************************************************
 * @filename      : OPP_MarketLineSubjMgmtModal_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-16 (금)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : OPP_MarketLineSubjMgmtModal_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-16      i2max     Create
**********************************************************************************/
public with sharing class OPP_MarketLineSubjMgmtModal_Ctrl {

    // ========== Subjectivity 팝업 관련 ==========
    @AuraEnabled
    public static Map<String, Object> getSubjectivities(Id recordId, Id panelId, Id reinsurerId) {
        Map<String, Object> results = new Map<String, Object>();

        // 1. 기본 유효성 검사
        if (String.isBlank(recordId) || String.isBlank(panelId) || String.isBlank(reinsurerId)) return new Map<String, Object>{ 'error' => 'Record ID is required.' };

        OPP_Panel__c currentPanel = [SELECT Id, Currency__c FROM OPP_Panel__c WHERE Id=:panelId LIMIT 1];

        String panelCurrency = COM_Util.toStr(currentPanel.Currency__c);

        String sObjectNm = COM_MetaUtil.getObjectNameById(recordId);
        Boolean isOpp = 'Opportunity'.equalsIgnoreCase(sObjectNm);

        // 2. 현재 Panel의 Layer ID 조회 => 기회 또는 Placement 레코드 하위에서 동일 reinsurerId를 가진 Panel 중에서 첫번째 등록된 Panel하위 OPP_Subjectivity__c 검색
        List<String> query = new List<String>();
        query.add('SELECT Id');
        query.add('FROM OPP_Panel__c');

        if(isOpp==true) query.add('WHERE Layer_md__r.Opportunity_md__c=:recordId');
        if(isOpp==true) query.add('AND Layer_md__r.Placement_lk__c=null');

        if(isOpp==false) query.add('WHERE Layer_md__r.Placement_lk__c=:recordId');

        query.add('AND Reinsurer_lk__c = :reinsurerId');
        //query.add('AND Currency__c =:panelCurrency ');
        query.add('ORDER BY CreatedDate ASC');
        query.add('LIMIT 1');

        List<OPP_Panel__c> targetPanels = Database.query(String.join(query, ' '));

        if (targetPanels.isEmpty()) return new Map<String, Object>{ 'error' => 'Panel information not found.' };

        Id targetPanelId = targetPanels.isEmpty() ? panelId : targetPanels[0].Id;

        System.debug('getSubjectivities >> recordId=['+ recordId +'], reinsurerId=['+ reinsurerId +'], panelCurrency=['+ panelCurrency +'], targetPanelId=['+ targetPanelId +']');

        // 4. Subjectivity 조회
        results.put('records', [
                SELECT Id, Name, Type__c, Detail__c, Clear_is__c
                FROM OPP_Subjectivity__c
                WHERE Panel_lk__c = :targetPanelId
                ORDER BY CreatedDate
        ]);

        // 5. 옵션 및 변경된 Panel ID 반환
        results.put('typeOptions', COM_Util.makePickListOptions('OPP_Subjectivity__c', 'Type__c', true));
        results.put('panelId', targetPanelId);

        return results;
    }

    @AuraEnabled
    public static void saveSubjectivities(List<OPP_Subjectivity__c> upsertList, List<OPP_Subjectivity__c> deleteList) {
        if (deleteList != null && !deleteList.isEmpty()) delete deleteList;
        if (upsertList != null && !upsertList.isEmpty()) upsert upsertList;
    }


}