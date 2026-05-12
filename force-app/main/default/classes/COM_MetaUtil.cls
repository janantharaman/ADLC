/**********************************************************************************
 * @filename      : COM_MetaUtil.cls
 * @projectname   : 
 * @author        : i2max
 * @date          : 2025-10-28 (화)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_MetaUtil_ts.cls
 * @reference     : 
 * @copyright     : 
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-10-28      i2max            Create
**********************************************************************************/
public with sharing class COM_MetaUtil {

    /**
     * @description 레코드 아이디로 Object Api Name 조회
     * @param recordId(Id)
     * @return String(Object Name)
    */
    public static String getObjectNameById(Id recordId) {
        return (String.isBlank(recordId)) ? '' : recordId.getSobjectType().getDescribe().getName();
    }

    /**
     * @description 레코드 아이디로 Object Api Label 조회
     * @param recordId(Id)
     * @return String(Object Label)
    */
    public static String getObjectLabelById(Id recordId) {
        return (String.isBlank(recordId)) ? '' : recordId.getSobjectType().getDescribe().getLabel();
    }

    /**
     * @description 객체가 존재 여부
     * @param objectApiName {String}
     * @return {Boolean}
     */
    public static Boolean existsObject(String objectApiName) {
        return String.isBlank(objectApiName) ? false : Schema.getGlobalDescribe().containsKey(objectApiName);
    }

    /**
     * @description 필드가 존재 여부
     * @param objectApiName {String}
     * @param fieldApiName {String}
     * @return {Boolean}
     */
    public static Boolean existsField(String objectApiName, String fieldApiName) {
        if (String.isNotBlank(objectApiName) && String.isNotBlank(fieldApiName) && existsObject(objectApiName)) {
            return Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().containsKey(fieldApiName);
        }
        return false;
    }

    /**
     * @description 현재 User가 해당 record의 Edit 권한을 지녔는지 true, false로 반환
     * @param recordId 확인할 record의 Id
     * @return Boolean
     */
    public static Boolean checkEditPermission(String recordId) {
        // 개체 권한 또는 필드 권한 체크
        //Schema.SObjectType.Contact.isDeletable()
        //Schema.SObjectType.Contact.isAccessible()
        //Schema.SObjectType.Contact.fields.Email.isAccessible()
        UserRecordAccess access = [SELECT HasEditAccess, RecordId FROM UserRecordAccess WHERE RecordId = :recordId AND UserId = :UserInfo.getUserId() LIMIT 1];
        return access.HasEditAccess;
    }

    private static final Set<String> ALLOWED_ACCESS_FIELDS = new Set<String>{
        'HasReadAccess', 'HasEditAccess', 'HasDeleteAccess', 'HasTransferAccess', 'HasAllAccess'
    };

    /**
     * @description 현재 User가 해당 record에 대해 지정한 권한을 보유하는지 확인
     * @param recordId 확인할 record의 Id
     * @param accessField UserRecordAccess 필드명 (HasReadAccess, HasEditAccess, HasDeleteAccess, HasTransferAccess, HasAllAccess)
     * @return Boolean
     */
    public static Boolean hasRecordPermission(String recordId, String accessField) {
        if (!ALLOWED_ACCESS_FIELDS.contains(accessField)) {
            throw new IllegalArgumentException('허용되지 않는 accessField: ' + accessField);
        }
        Id userId = UserInfo.getUserId();
        String query = 'SELECT RecordId, ' + accessField + ' FROM UserRecordAccess WHERE RecordId = :recordId AND UserId = :userId LIMIT 1';
        SObject access = Database.query(query);
        return (Boolean) access.get(accessField);
    }

    /**
     * @description RecordType 별 RecordTypeId 조회
     * @param obj SObjectName
     * @return Map<String, String>
     */
    public static Map<String, String> getRTDevNmByRTId(final String obj) {
        Map<String, String> results = new Map<String, String>();
        Map<String, RecordTypeInfo> rtInfos = Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByDeveloperName();
        for (String devNm : rtInfos.keySet()) {
            results.put(rtInfos.get(devNm).recordTypeId, devNm);
        }
        return results;
    }

    /**
     * @description 개체별 RecordTypeDeveloperName 조회
     * @param obj SObjectName
     * @return Map<String, String>
     */
    public static Map<String, String> getRTByRTDevNm(final String obj) {
        Map<String, String> results = new Map<String, String>();
        Map<String, RecordTypeInfo> rtInfos = Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByDeveloperName();
        for (String devNm : rtInfos.keySet()) {
            results.put(devNm, rtInfos.get(devNm).recordTypeId);
        }
        return results;
    }

    /**
     * @description RecordType Id → Label
     * @param sobjectApiNm sobjectApiName
     *
     * @return Map<Id, String>
     */
    public static Map<Id, String> getRecordTypeLabelsById(String sobjectApiNm) {
        Map<Id, String> results = new Map<Id, String>();
        if (!existsObject(sobjectApiNm)) return results;

        for (Schema.RecordTypeInfo rt : Schema.getGlobalDescribe().get(sobjectApiNm).getDescribe().getRecordTypeInfos()) {
            results.put(rt.getRecordTypeId(), rt.getName());
        }
        return results;
    }

    /**
     * @description RecordType Id → DeveloperName
     * @param sobjectApiNm sobjectApiName
     *
     * @return Map<Id, String>
     */
    public static Map<Id, String> getRecordTypeDevNamesById(String sobjectApiNm) {
        Map<Id, String> results = new Map<Id, String>();
        if (!existsObject(sobjectApiNm)) return results;

        for (Schema.RecordTypeInfo rt : Schema.getGlobalDescribe().get(sobjectApiNm).getDescribe().getRecordTypeInfos()) {
            results.put(rt.getRecordTypeId(), rt.getDeveloperName());
        }
        return results;
    }

    /**
     * @description DeveloperName → RecordType Id
     * @param sobjectApiNm sobjectApiName
     * @param rtDeveloperName rtDeveloperName
     *
     * @return Id
     */
    public static Id getRecordTypeIdByDeveloperName(String sobjectApiNm, String rtDeveloperName) {
        if (!existsObject(sobjectApiNm) || String.isBlank(rtDeveloperName)) return null;

        for (Schema.RecordTypeInfo rt : Schema.getGlobalDescribe().get(sobjectApiNm).getDescribe().getRecordTypeInfos()) {
            if (rt.getDeveloperName() == rtDeveloperName) return rt.getRecordTypeId();
        }
        return null;
    }

    /**
     * @description Label → RecordType Id
     * @param sobjectApiNm sobjectApiName
     * @param rtLabel RecordType.Label
     *
     * @return Id
     */
    public static Id getRecordTypeIdByLabel(String sobjectApiNm, String rtLabel) {
        if (!existsObject(sobjectApiNm) || String.isBlank(rtLabel)) return null;

        for (Schema.RecordTypeInfo rt : Schema.getGlobalDescribe().get(sobjectApiNm).getDescribe().getRecordTypeInfos()) {
            if (rt.getName() == rtLabel) return rt.getRecordTypeId();
        }
        return null;
    }

    /**
     * @description Label -> API Value
     * @param objectApi sobject api name
     * @param fieldApi field api name
     *
     * @return Map<String,String>
     */
    public static Map<String,String> getPicklistL2V(String objectApi, String fieldApi) {
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objectApi);
        if (t == null) return new Map<String,String>();
        Map<String, Schema.SObjectField> fmap = t.getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi)) return new Map<String,String>();

        Schema.DescribeFieldResult dfr = fmap.get(fieldApi).getDescribe();
        Schema.DisplayType dt = dfr.getType();
        if (dt != Schema.DisplayType.PICKLIST && dt != Schema.DisplayType.MULTIPICKLIST) return new Map<String,String>();

        Map<String,String> out = new Map<String,String>();
        for (Schema.PicklistEntry e : dfr.getPicklistValues()) {
            if (e.isActive()) out.put(e.getLabel(), e.getValue());
        }
        return out;
    }

    /**
     * @description API Value -> Label
     * @param objectApi
     * @param fieldApi
     *
     * @return Map<String,String>
     */
    public static Map<String,String> getPicklistV2L(String objectApi, String fieldApi) {
        Map<String,String> l2v = getPicklistL2V(objectApi, fieldApi);
        Map<String,String> v2l = new Map<String,String>();
        for (String lab : l2v.keySet()) v2l.put(l2v.get(lab), lab);
        return v2l;
    }

    public static String getLabelByValue(String objectApi, String fieldApi, String apiValue) {
        if (String.isBlank(apiValue)) return null;
        return getPicklistV2L(objectApi, fieldApi).get(apiValue);
    }
    public static String getValueByLabel(String objectApi, String fieldApi, String label) {
        if (String.isBlank(label)) return null;
        return getPicklistL2V(objectApi, fieldApi).get(label);
    }



    /**
     * @description 객체와 필드에서 Picklist 값과 Label 을 Map 형식으로 조회
     * @param objectName
     * @param fieldName
     * @return {Map<String, String>}
     */
    public static Map<String, String> getPicklistLabels(String objectName, String fieldName) {

        if (!existsObject(objectName)) {
            return new Map<String, String>{
                    'Error' => 'Object does not exist.'
            };
        }
        if (!existsField(objectName, fieldName)) {
            return new Map<String, String>{
                    'Error' => 'Field does not exist.'
            };
        }
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();

        Map<String, String> picklistLabels = new Map<String, String>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            picklistLabels.put(entry.getValue(), entry.getLabel());
        }
        return picklistLabels;
    }

    /**
     * @description Dependent Picklist의 Controlling Value별 Dependent Value 목록 조회
     * @param dependToken dependent 필드의 sObjectField 토큰
     * @return Map<Object, List<String>> — key: controlling value, value: dependent values
     */
    public static Map<Object, List<String>> getDependentPicklistValues(
            Schema.SObjectField dependToken
    ) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.SObjectField controlToken = depend.getController();
        if (controlToken == null) return null;

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
                (control.getType() == Schema.DisplayType.BOOLEAN
                        ? null
                        : control.getPicklistValues());

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object, List<String>> dependentPicklistValues = new Map<Object, List<String>>();

        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (!entry.isActive()) continue;

            List<String> base64chars =
                    String.valueOf(
                            ((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry)))
                                    .get('validFor')
                    ).split('');

            for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                Object controlValue =
                        (controlEntries == null
                                ? (Object)(index == 1)
                                : (Object)(controlEntries[index].isActive()
                                        ? controlEntries[index].getLabel()
                                        : null));

                Integer bitIndex = index / 6;
                Integer bitShift = 5 - Math.mod(index, 6);

                if (controlValue == null
                        || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0
                ) continue;

                if (!dependentPicklistValues.containsKey(controlValue)) {
                    dependentPicklistValues.put(controlValue, new List<String>());
                }
                dependentPicklistValues.get(controlValue).add(entry.getLabel());
            }
        }
        return dependentPicklistValues;
    }

    /**
     * @description Dependent Picklist 조회 (objectApiName + fieldApiName 기반)
     * @param objectApiName SObject API Name
     * @param fieldApiName Dependent 필드 API Name
     * @return Map<Object, List<String>>
     */
    public static Map<Object, List<String>> getDependentPicklistValues(
            String objectApiName, String fieldApiName
    ) {
        return getDependentPicklistValues(
                Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().get(fieldApiName)
        );
    }




}