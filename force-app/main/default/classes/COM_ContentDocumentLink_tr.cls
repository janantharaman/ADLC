/**********************************************************************************
 * @filename      : COM_ContentDocumentLink_tr.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-15 (목)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_ContentDocumentLink_tr_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-15      i2max     Create
**********************************************************************************/
public with sharing class COM_ContentDocumentLink_tr extends TriggerHandler {

    public override void beforeInsert() {
        validateSingleFileUploadForSecurity(Trigger.new);
    }


    /**
      * ACC_AdditionalInfo__c 레코드 별 첨부파일은 1개만 허용
     * @param newList {List<SObject>}
     */
    private static void validateSingleFileUploadForSecurity(List<SObject> newList) {

        String targetObjNm = 'ACC_AdditionalInfo__c';
        Id rtId = COM_MetaUtil.getRecordTypeIdByDeveloperName(targetObjNm, 'Security');
        if(rtId == null) return;


        Set<Id> linkedEntityIds = new Set<Id>();
        for(ContentDocumentLink newObj : (List<ContentDocumentLink>) newList){
            linkedEntityIds.add(newObj.LinkedEntityId);
        }
        if (linkedEntityIds.isEmpty()) return;

        // 2. Security RecordType 인 레코드만 필터링
        Set<Id> validSecurityIds = new Map<Id, ACC_AdditionalInfo__c>([
                SELECT Id
                FROM ACC_AdditionalInfo__c
                WHERE Id IN :linkedEntityIds
                AND RecordTypeId = :rtId
        ]).keySet();
        if (validSecurityIds.isEmpty()) return;

        // 3. 기존 파일 개수 조회
        Map<Id, Integer> fileCountByEntity = new Map<Id, Integer>();
        for (AggregateResult ar : [
                SELECT LinkedEntityId entityId, COUNT(Id) cnt
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :validSecurityIds
                GROUP BY LinkedEntityId
        ]) {
            fileCountByEntity.put(
                    (Id) ar.get('entityId'),
                    (Integer) ar.get('cnt')
            );
        }

        // 4. 신규 업로드 차단
        for (ContentDocumentLink newObj : (List<ContentDocumentLink>) newList) {
            if (validSecurityIds.contains(newObj.LinkedEntityId)) {
                Integer existingCnt = fileCountByEntity.get(newObj.LinkedEntityId);
                if (existingCnt != null && existingCnt >= 1) {
                    newObj.addError(System.Label.ACC_MSG_FILE_LIMIT_ONE_ACT_SEC);
                }
            }
        }
    }



}