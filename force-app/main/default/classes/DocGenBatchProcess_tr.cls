/**********************************************************************************
 * @filename      : DocGenBatchProcess_tr.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-01 (목)
 * @group         :
 * @group-content :
 * @description   : DocGenerationBatchProcess 트리거 핸들러.
 *                  Status가 Completed로 전이될 때 생성 문서를 첨부하여 CreatedBy에게 이메일을 발송한다.
 *
 * @test-class    : DocGenBatchProcess_tr_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-01      i2max            Create
 **********************************************************************************/
public with sharing class DocGenBatchProcess_tr extends TriggerHandler {
    // ============================================================
    // Constants
    // ============================================================
    
    /** 이메일 발송에 사용할 VF 템플릿 DeveloperName */
    private static final String EMAIL_TEMPLATE_DEV_NAME = 'SAMPLE_DocGen_Batch_Result_vf';
    
    // ============================================================
    // Trigger Override Methods
    // ============================================================
    
    /**
     * @description DocGenerationBatchProcess After Update 진입점.
     *              Status = 'Completed' 전이 레코드에 한해 handleAfterUpdate 에 위임한다.
     */
    protected override void afterUpdate() {
        List<DocGenerationBatchProcess> newTrigger = (List<DocGenerationBatchProcess>) Trigger.new;
        Map<Id, DocGenerationBatchProcess> oldTriggerMap = (Map<Id, DocGenerationBatchProcess>) Trigger.oldMap;
        
        if (newTrigger == null || newTrigger.isEmpty())
            return;
        
        handleAfterUpdate(newTrigger, oldTriggerMap);
    }
    
    // ============================================================
    // Private Methods (@TestVisible)
    // ============================================================
    
    /**
     * @description afterUpdate 실행 본체. Trigger 컨텍스트 의존성을 분리하여 단위 테스트 가능하게 한다.
     *              Status='Completed' 전이 배치 필터링 → 템플릿 조회 → 사용자 조회 → DGP 조회 → 이메일 발송 위임.
     * @param  newList  Trigger.new 캐스팅 목록
     * @param  oldMap   Trigger.oldMap 캐스팅 맵
     */
    @TestVisible
    private static void handleAfterUpdate(List<DocGenerationBatchProcess> newList, Map<Id, DocGenerationBatchProcess> oldMap) {
        // Step 1. Completed 전이 배치 필터링 + CreatedById 수집
        Set<Id> targetCreatorIds = new Set<Id>();
        List<DocGenerationBatchProcess> completedBatches = new List<DocGenerationBatchProcess>();
        Set<Id> completedBatchIds = new Set<Id>();
        
        for (DocGenerationBatchProcess rec : newList) {
            DocGenerationBatchProcess oldRec = oldMap != null ? oldMap.get(rec.Id) : null;
            if (oldRec == null)
                continue;
            
            if (rec.Status == 'Completed' && oldRec.Status != 'Completed') {
                completedBatches.add(rec);
                completedBatchIds.add(rec.Id);
                if (rec.CreatedById != null) {
                    targetCreatorIds.add(rec.CreatedById);
                }
            }
        }
        
        if (completedBatches.isEmpty() || targetCreatorIds.isEmpty())
            return;
        
        // Step 2. VF 이메일 템플릿 Id 조회
        Id templateId = getEmailTemplateId();
        
        // Step 3. CreatedBy 사용자 조회
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email, IsActive FROM User WHERE Id IN :targetCreatorIds]);
        
        // Step 4. 자식 DGP 조회 후 위임
        List<DocumentGenerationProcess> dgpList = [
            SELECT Id, ResponseText, DocGenerationBatchProcessId, DocumentTemplate.TemplateType__c
            FROM DocumentGenerationProcess
            WHERE DocGenerationBatchProcessId IN :completedBatchIds AND ResponseText != NULL
        ];
        
        sendEmailsAndUpdateCvs(completedBatches, userMap, dgpList, templateId);
    }
    
    /**
     * @description DGP ResponseText에서 ContentVersion Id를 추출하여 이메일에 첨부 발송하고,
     *              ContentVersion.RelFiles__Category__c / OwnerId를 일괄 업데이트한다.
     *              VF 템플릿 미존재 시 플레인텍스트 fallback으로 발송한다.
     * @param  completedBatches  Completed 전이된 DocGenerationBatchProcess 목록
     * @param  userMap           CreatedById → User 맵
     * @param  dgpList           자식 DocumentGenerationProcess 목록
     * @param  templateId        VF 이메일 템플릿 Id (미존재 시 null)
     */
    @TestVisible
    private static void sendEmailsAndUpdateCvs(List<DocGenerationBatchProcess> completedBatches, Map<Id, User> userMap, List<DocumentGenerationProcess> dgpList, Id templateId) {
        // Step 5. ResponseText → ContentVersion Id 추출 + 보조 맵 구성
        Map<Id, DocGenerationBatchProcess> batchMap = new Map<Id, DocGenerationBatchProcess>();
        for (DocGenerationBatchProcess rec : completedBatches) {
            batchMap.put(rec.Id, rec);
        }
        
        Map<Id, List<Id>> batchToContentVersionIds = new Map<Id, List<Id>>();
        Map<Id, String> cvIdToTemplateType = new Map<Id, String>(); // cvId → DocumentTemplate.TemplateType__c
        Map<Id, Id> cvIdToOwnerId = new Map<Id, Id>(); // cvId → DocGenerationBatchProcess.OwnerId
        Map<Id, String> cvIdToBatchCategory = new Map<Id, String>(); // cvId → DocGenerationBatchProcess.Category
        
        for (DocumentGenerationProcess dgp : dgpList) {
            List<Id> cvIds = extractContentVersionIds(dgp.ResponseText);
            if (cvIds == null || cvIds.isEmpty())
                continue;
            
            Id batchId = dgp.DocGenerationBatchProcessId;
            if (!batchToContentVersionIds.containsKey(batchId)) {
                batchToContentVersionIds.put(batchId, new List<Id>());
            }
            batchToContentVersionIds.get(batchId).addAll(cvIds);
            
            String templateType = (dgp.DocumentTemplate != null) ? dgp.DocumentTemplate.TemplateType__c : null;
            DocGenerationBatchProcess batch = batchMap.get(batchId);
            for (Id cvId : cvIds) {
                if (String.isNotBlank(templateType)) {
                    cvIdToTemplateType.put(cvId, templateType);
                }
                if (batch != null && batch.OwnerId != null) {
                    cvIdToOwnerId.put(cvId, batch.OwnerId);
                }
                if (batch != null && String.isNotBlank(batch.Category)) {
                    cvIdToBatchCategory.put(cvId, batch.Category);
                }
            }
        }
        
        // Step 6. ContentVersion 일괄 조회 (VersionData 포함)
        Set<Id> allCvIds = new Set<Id>();
        for (List<Id> cvIds : batchToContentVersionIds.values()) {
            allCvIds.addAll(cvIds);
        }
        
        Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>();
        if (!allCvIds.isEmpty()) {
            cvMap = new Map<Id, ContentVersion>([SELECT Id, Title, FileExtension, VersionData FROM ContentVersion WHERE Id IN :allCvIds]);
        }
        
        // Step 7. 이메일 생성 (bulk-safe) + 문서 첨부
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (DocGenerationBatchProcess rec : completedBatches) {
            User creator = userMap.get(rec.CreatedById);
            if (creator == null || String.isBlank(creator.Email))
                continue;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            if (templateId != null) {
                // VF 템플릿 사용: COM_EmailHeader / COM_EmailFooter 컴포넌트 적용
                // setTargetObjectId → {!recipient.*} 머지필드 바인딩 (User)
                // setWhatId        → {!relatedTo.*} 머지필드 바인딩 (DocGenerationBatchProcess)
                mail.setTemplateId(templateId);
                mail.setTargetObjectId(creator.Id);
                mail.setWhatId(rec.Id);
                mail.setSaveAsActivity(false);
            } else {
                // 템플릿 미존재 시 플레인텍스트 fallback
                mail.setToAddresses(new List<String>{ creator.Email });
                mail.setSubject('[LK] 문서 생성이 완료되었습니다.');
                String body =
                    '안녕하세요 ' +
                    creator.Name +
                    '님,\n\n' +
                    '문서 생성 작업이 완료되었습니다.\n\n' +
                    '- 설명(Description): ' +
                    String.valueOf(rec.Description) +
                    '\n' +
                    '- 카테고리(Category): ' +
                    String.valueOf(rec.Category) +
                    '\n' +
                    '- 상태(Status): ' +
                    String.valueOf(rec.Status) +
                    '\n\n' +
                    'Salesforce에서 상세 내용을 확인해 주세요.\n';
                mail.setPlainTextBody(body);
            }
            
            // 생성된 문서 파일 첨부
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            List<Id> cvIds = batchToContentVersionIds.get(rec.Id);
            if (cvIds != null) {
                for (Id cvId : cvIds) {
                    ContentVersion cv = cvMap.get(cvId);
                    if (cv == null || cv.VersionData == null)
                        continue;
                    
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    String ext = String.isNotBlank(cv.FileExtension) ? '.' + cv.FileExtension : '';
                    efa.setFileName(cv.Title + ext);
                    efa.setBody(cv.VersionData);
                    attachments.add(efa);
                }
            }
            
            if (!attachments.isEmpty()) {
                mail.setFileAttachments(attachments);
            }
            
            emails.add(mail);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false); // allOrNothing=false → 일부 실패해도 나머지 발송 계속
        }
        
        // Step 8. ContentVersion.RelFiles__Category__c / OwnerId 업데이트
        Set<Id> allCvIdsToUpdate = new Set<Id>();
        allCvIdsToUpdate.addAll(cvIdToTemplateType.keySet());
        allCvIdsToUpdate.addAll(cvIdToOwnerId.keySet());
        
        if (!allCvIdsToUpdate.isEmpty()) {
            List<ContentVersion> cvsToUpdate = new List<ContentVersion>();
            for (Id cvId : allCvIdsToUpdate) {
                ContentVersion cv = new ContentVersion(Id = cvId);
                if (cvIdToTemplateType.containsKey(cvId)) {
                    String batchCategory = cvIdToBatchCategory.get(cvId);
                    // Category = 'Note' 이면 RelFiles__Category__c 도 'Note', 그 외에는 TemplateType 값 사용
                    cv.RelFiles__Category__c = ('C/D Note' == batchCategory) ? 'C/D Note' : cvIdToTemplateType.get(cvId);
                }
                if (cvIdToOwnerId.containsKey(cvId)) {
                    cv.OwnerId = cvIdToOwnerId.get(cvId);
                }
                cvsToUpdate.add(cv);
            }
            update cvsToUpdate;
        }
    }
    
    /**
     * @description DeveloperName으로 VF 이메일 템플릿 Id를 조회하여 반환한다. 미존재 시 null 반환.
     * @return Id  EmailTemplate.Id (미존재 시 null)
     */
    @TestVisible
    private static Id getEmailTemplateId() {
        List<EmailTemplate> templates = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :EMAIL_TEMPLATE_DEV_NAME
            LIMIT 1
        ];
        return templates.isEmpty() ? null : templates[0].Id;
    }
    
    /**
     * @description DocumentGenerationProcess.ResponseText에서 ContentVersion Id 목록을 추출한다.
     *              지원 형태(우선순위): 1) JSON 객체(contentVersionId/Id 키) 2) 콤마 구분 문자열 3) 단일 Id.
     *              유효하지 않은 토큰은 스킵하며, 파싱 완전 실패 시 null 반환.
     * @param  responseText  DocumentGenerationProcess.ResponseText
     * @return List<Id>      추출된 ContentVersion Id 목록 (파싱 실패 또는 빈 경우 null)
     */
    @TestVisible
    private static List<Id> extractContentVersionIds(String responseText) {
        if (String.isBlank(responseText))
            return null;
        
        List<Id> result = new List<Id>();
        
        // 1) JSON 파싱 시도
        try {
            Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(responseText);
            
            for (String key : new List<String>{ 'contentVersionId', 'ContentVersionId', 'Id', 'id' }) {
                Object val = resp.get(key);
                if (val == null || String.isBlank(String.valueOf(val)))
                    continue;
                
                // JSON 값도 콤마 구분일 수 있으므로 split 후 개별 파싱
                for (String token : String.valueOf(val).split(',')) {
                    try {
                        result.add(Id.valueOf(token.trim()));
                    } catch (Exception e) {
                        // 유효하지 않은 토큰 → 스킵
                    }
                }
                
                if (!result.isEmpty())
                    return result;
            }
            return result.isEmpty() ? null : result;
        } catch (Exception e) {
            // JSON 형식 아님 → 아래 문자열 파싱으로 폴백
        }
        
        // 2) 콤마 구분 문자열 또는 단일 Id 파싱
        for (String token : responseText.split(',')) {
            try {
                result.add(Id.valueOf(token.trim()));
            } catch (Exception e) {
                // 유효하지 않은 토큰 → 스킵
            }
        }
        
        if (result.isEmpty()) {
            System.debug('[DocGenBatchProcess_tr] ResponseText 파싱 실패: ' + responseText);
            return null;
        }
        
        return result;
    }
}