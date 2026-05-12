/**********************************************************************************
 * @filename      : COM_FileList_Ctrl.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-18 (수)
 * @group         :
 * @group-content :
 * @description   : comFileList LWC용 컨트롤러 (파일 목록 조회/삭제/업로드)
 * @test-class    : COM_FileList_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-18      i2max            Create
**********************************************************************************/
public with sharing class COM_FileList_Ctrl {

    @AuraEnabled
    public static List<Map<String, Object>> getFiles(Id recordId, String category, String searchTitle) {
        if (recordId == null) {
            throw new AuraHandledException('recordId는 필수입니다.');
        }
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
                WITH SECURITY_ENFORCED
        ]) {
            docIds.add(cdl.ContentDocumentId);
        }

        if (docIds.isEmpty()) return new List<Map<String, Object>>();

        List<String> fields = new List<String>{
                'Id', 'Title', 'FileExtension', 'ContentSize', 'ContentDocumentId',
                'OwnerId', 'Owner.Name', 'RelFiles__Category__c', 'CreatedDate', 'LastModifiedDate'
        };

        List<String> clauses = new List<String>{
                'ContentDocumentId IN :docIds',
                'IsLatest = true'
        };
        if(!(String.isNotBlank(category) && 'ALL'.equalsIgnoreCase(category))) {
            clauses.add('RelFiles__Category__c = :category');
        }
        if(String.isNotBlank(searchTitle)) {
            String likeParam = '%' + searchTitle + '%';
            clauses.add('Title LIKE :likeParam');
        }

        String query = 'SELECT ' + String.join(fields, ', ')
                + ' FROM ContentVersion'
                + ' WHERE ' + String.join(clauses, ' AND ')
                + ' WITH SECURITY_ENFORCED ORDER BY LastModifiedDate ASC';

        System.debug(query
                .replace(':docIds', String.valueOf(docIds))
                .replace(':category', '\'' + category + '\'')
        );

        List<ContentVersion> contentVersions = Database.query(query);

        Set<String> fileNm = new Set<String>();
        Set<Id> latestIds = new Set<Id>();

        // 동일 파일명중에서 (확장자 체크하지 않음) 등록 일시가 가장 늦은(최신) 파일 체크
        for(Integer i = contentVersions.size()-1; i >= 0; i--) {
            ContentVersion contentVersion = contentVersions[i];
            if(!fileNm.contains(contentVersion.Title)) {
                latestIds.add(contentVersion.Id);
                fileNm.add((contentVersion.Title));
            }
        }

        List<Map<String, Object>> files = new List<Map<String, Object>>();
        Integer rowNo = 1;
        for (ContentVersion cv : contentVersions) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('rowNo', rowNo++);
            row.put('Id', cv.Id);
            row.put('ContentDocumentId', cv.ContentDocumentId);
            row.put('Title', String.join(new List<String>{ cv.Title, cv.FileExtension }, '.'));
//            row.put('Title', '[' + cv.FileExtension.toUpperCase() + '] ' + cv.Title + '.' + cv.FileExtension);
            row.put('category', cv.RelFiles__Category__c);
            row.put('FileExtension', cv.FileExtension);
            row.put('ContentSize', cv.ContentSize);
            row.put('OwnerName', cv.Owner.Name);
            row.put('OwnerId', cv.OwnerId);
            row.put('isLatest', latestIds.contains(cv.Id));
            row.put('LastModifiedDate', cv.LastModifiedDate.format('MM/dd/yyyy, hh:mma'));
            files.add(row);
        }
        return files;
    }

    @AuraEnabled
    public static void deleteFiles(List<Id> contentDocumentIds) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('삭제할 파일을 선택해주세요.');
        }
        List<ContentDocument> docs = [
                SELECT Id, OwnerId FROM ContentDocument
                WHERE Id IN :contentDocumentIds
                WITH SECURITY_ENFORCED
        ];
        Id currentUserId = UserInfo.getUserId();
        for (ContentDocument doc : docs) {
            if (doc.OwnerId != currentUserId) {
                throw new AuraHandledException('본인이 등록한 파일만 삭제할 수 있습니다.');
            }
        }
        if (!docs.isEmpty()) {
            try {
                delete docs;
            } catch (DmlException e) {
                throw new AuraHandledException('파일 삭제 권한이 없습니다.');
            }
        }
    }

    @AuraEnabled
    public static void updateCategory(List<Id> contentVersionIds, String category) {
        List<ContentVersion> versions = [
                SELECT Id, RelFiles__Category__c
                FROM ContentVersion
                WHERE Id IN :contentVersionIds
                WITH SECURITY_ENFORCED
        ];
        for (ContentVersion cv : versions) {
            cv.RelFiles__Category__c = (String.isNotBlank(category) && 'ALL'.equalsIgnoreCase(category)) ? '' : category;
        }
        update versions;
    }



}