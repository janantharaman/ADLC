/**********************************************************************************
 * @filename      : COM_RecordList_Ctrl.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : COM_RecordList_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
public with sharing class COM_RecordList_Ctrl {

    // base64 문자열 기준 약 5MB(원본 약 3.7MB)
    private static final Integer MAX_BASE64_LENGTH = 5 * 1024 * 1024;

    @AuraEnabled
    public static Map<String, Object> getChildRecords(
            Id recordId,
            String childObject,
            String parentRecordField,
            String displayFields,
            String filterCondition
    ) {
        if (String.isBlank(childObject) || String.isBlank(parentRecordField)) {
            throw new AuraHandledException('childObject와 parentRecordField는 필수입니다.');
        }
        if (!COM_MetaUtil.existsObject(childObject)) {
            throw new AuraHandledException('[' + childObject + '] 개체 정보가 조회되지 않습니다.');
        }

        Map<String, SObjectField> displayFieldsInfo = Schema.getGlobalDescribe().get(childObject).getDescribe().fields.getMap();
        String objectLabel = Schema.getGlobalDescribe().get(childObject).getDescribe().getLabelPlural();

        List<String> fields = displayFields.split(',');
        for (Integer i = 0; i < fields.size(); i++) {
            String fieldName = fields[i].trim();
            if(displayFieldsInfo.containsKey(fieldName)) {
                fields[i] = fieldName;
            }
            else {
                throw new AuraHandledException('['+childObject + '] 개체의 ['+fieldName + '] 필드 정보가 조회되지 않습니다.');
            }
        }

        Map<String, String> fieldLabels = new Map<String, String>();
        Map<String, String> fieldTypes = new Map<String, String>();
        List<String> queryFields = new List<String>();
        Set<String> lookupFields = new Set<String>();
        Map<String, String> fieldLookupObjects = new Map<String, String>();

        for (String fieldName : fields) {
            String fieldNm = fieldName.trim();
            queryFields.add(fieldNm);

            if (displayFieldsInfo.containsKey(fieldNm)) {
                Schema.DescribeFieldResult describeFieldResult = displayFieldsInfo.get(fieldNm).getDescribe();
                fieldLabels.put(fieldNm, describeFieldResult.getLabel());
                fieldTypes.put(fieldNm, mapDisplayType(describeFieldResult.getType()));

                if (describeFieldResult.getType() == Schema.DisplayType.REFERENCE && describeFieldResult.getRelationshipName() != null) {
                    queryFields.add(describeFieldResult.getRelationshipName() + '.Name');
                    lookupFields.add(fieldNm);
                    fieldLookupObjects.put(fieldNm, describeFieldResult.getReferenceTo()[0].getDescribe().getName());
                }
            } else {
                fieldLabels.put(fieldNm, fieldNm);
                fieldTypes.put(fieldNm, 'text');
            }
        }

        List<String> query = new List<String>();
        query.add('SELECT Id,');
        query.add(String.join(queryFields, ', '));
        query.add('FROM ' + String.escapeSingleQuotes(childObject));
        query.add('WHERE ' + parentRecordField + ' = :recordId');
        if (String.isNotBlank(filterCondition)) query.add('AND (' + filterCondition + ')');
        query.add('WITH SECURITY_ENFORCED');
        query.add('ORDER BY CreatedDate DESC');
        System.debug('Query=['+ String.join(query, ' ') +']');

        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject rec : Database.query(String.join(query, ' '))) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', rec.Id);
            for (String field : fields) {
                String fieldName = field.trim();
                if (lookupFields.contains(fieldName)) {
                    Schema.DescribeFieldResult describeFieldResult = displayFieldsInfo.get(fieldName).getDescribe();
                    String relName = describeFieldResult.getRelationshipName();
                    SObject related = rec.getSObject(relName);
                    row.put(fieldName, related != null ? (String) related.get('Name') : null);
                    row.put(fieldName + '__id', rec.get(fieldName));
                } else {
                    row.put(fieldName, rec.get(fieldName));
                }
            }
            records.add(row);
        }

        return new Map<String, Object>{
                'records' => records,
                'fieldLabels' => fieldLabels,
                'fieldTypes' => fieldTypes,
                'fieldLookupObjects' => fieldLookupObjects,
                'objectLabel' => objectLabel,
                'childObject' => childObject
        };
    }

    @AuraEnabled
    public static Id saveAsFile(
            Id recordId,
            String fileName,
            String base64Data
    ) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName + '.xlsx';
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.FirstPublishLocationId = recordId;
        insert cv;
        return cv.Id;
    }

    @AuraEnabled
    public static void saveAsFileAndSendEmail2(
            Id recordId,
            String fileName,
            String base64Data
    ) {
        // 1) ContentVersion 생성 (Files 저장)
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName + '.xlsx';
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.FirstPublishLocationId = recordId;
        insert cv;

        // 2) ContentVersion 재조회 (ContentDocumentId 필요)
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // 3) 이메일 템플릿 조회
        EmailTemplate emailTemplate = [
                SELECT Id FROM EmailTemplate
                WHERE DeveloperName = 'SAMPLE_LK_ReinsuranceEmailTemplateAcc_vf'
                LIMIT 1
        ];

        // 4) 이메일 발송 (발신자/수신자 = 현재 사용자)
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(emailTemplate.Id);
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setWhatId(recordId);
        mail.setSaveAsActivity(false);
        mail.setEntityAttachments(new List<String>{ cv.Id });

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    @AuraEnabled
    public static void saveAsFileAndSendEmail(Id recordId, String fileName, String base64Data) {

        if (String.isBlank(base64Data) || base64Data.length() > MAX_BASE64_LENGTH) {
            throw new AuraHandledException('파일 크기가 제한(약 3MB)을 초과합니다.');
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName + '.xlsx';
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.FirstPublishLocationId = recordId;
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // VF 페이지를 렌더링하여 HTML 획득 (헤더/푸터 컴포넌트 포함)
        PageReference page = Page.COM_RecordListEmailPage;
        page.getParameters().put('recipientName', UserInfo.getName());
        page.getParameters().put('recipientId', UserInfo.getUserId());
        page.getParameters().put('recordId', String.valueOf(recordId));
        String htmlBody = page.getContent().toString();

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        mail.setSubject('[LK] 목록 데이터 내보내기');
        mail.setHtmlBody(htmlBody);
        mail.setSaveAsActivity(false);
        mail.setEntityAttachments(new List<String>{ cv.Id });

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    private static String findLookupField(String childObject, String parentObject) {

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(childObject).getDescribe().fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                for (Schema.SObjectType ref : dfr.getReferenceTo()) {
                    if (ref.getDescribe().getName() == parentObject) {
                        return dfr.getName();
                    }
                }
            }
        }
        throw new AuraHandledException(
                childObject + '에서 ' + parentObject + '를 참조하는 Lookup 필드를 찾을 수 없습니다.'
        );
    }

    private static String mapDisplayType(Schema.DisplayType dt) {
        switch on dt {
            when CURRENCY, DOUBLE, INTEGER, LONG, PERCENT {
                return 'number';
            }
            when DATE {
                return 'date';
            }
            when DATETIME {
                return 'datetime';
            }
            when BOOLEAN {
                return 'boolean';
            }
            when REFERENCE {
                return 'lookup';
            }
            when else {
                return 'text';
            }
        }
    }


}