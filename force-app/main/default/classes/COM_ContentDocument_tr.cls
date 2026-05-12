/**********************************************************************************
 * @filename      : COM_ContentDocument_tr.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-15 (목)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_ContentDocument_tr_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-15      i2max     Create
**********************************************************************************/
public with sharing class COM_ContentDocument_tr extends TriggerHandler {

    public override void beforeDelete() {
        this.validateFileDeletionByLinkedObject(Trigger.oldMap);
    }

    /**
      * ACC_AdditionalInfo__c 레코드의 ActiveSecurity_is__c = true 일 때
      * 첨부파일 삭제 불가
     * @param oldMap {Map<Id, SObject>}
     */
    private void validateFileDeletionByLinkedObject(Map<Id, SObject> oldMap) {

        String targetObjNm = 'ACC_AdditionalInfo__c';
        Id rtId = COM_MetaUtil.getRecordTypeIdByDeveloperName(targetObjNm, 'Security');

        Map<Id, Id> docToEntityMap = new Map<Id, Id>();
        for (ContentDocumentLink obj : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :oldMap.keySet()]) {
            if (COM_MetaUtil.getObjectNameById(obj.LinkedEntityId) == targetObjNm) {
                docToEntityMap.put(obj.ContentDocumentId, obj.LinkedEntityId);
            }
        }
        System.debug('validateFileDeletionByLinkedObject docToEntityMap.isEmpty()=['+ docToEntityMap.isEmpty() +']');
        if (docToEntityMap.isEmpty()) return;

        Set<Id> activeSecurityIds = new Map<Id, ACC_AdditionalInfo__c>([
                SELECT Id
                FROM ACC_AdditionalInfo__c
                WHERE Id IN :docToEntityMap.values()
                AND RecordTypeId=:rtId
                AND ActiveSecurity_is__c = TRUE
        ]).keySet();
        System.debug('validateFileDeletionByLinkedObject activeSecurityIds.isEmpty()=['+ activeSecurityIds.isEmpty() +']');

        if (activeSecurityIds.isEmpty()) return ;

        for (ContentDocument newObj : (List<ContentDocument>) oldMap.values()) {
            if (docToEntityMap.containsKey(newObj.Id) && activeSecurityIds.contains(docToEntityMap.get(newObj.Id))) {
                newObj.addError(Label.ACC_MSG_FILE_DEL_BLOCK_ACT_SEC);
            }
        }
    }


}