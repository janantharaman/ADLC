/**********************************************************************************
 * @filename      : OPP_MarketLineSearchModal_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketLineSearchModal_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-07      i2max     Create
**********************************************************************************/
public with sharing class OPP_MarketLineSearchModal_Ctrl {

    public class SearchResult {
        @AuraEnabled public String periodFromLabel;
        @AuraEnabled public Date periodFromDate;

        @AuraEnabled public List<ColumnInfo> columns;
        @AuraEnabled public List<Map<String, Object>> data;

        public SearchResult() {
            this.columns = new List<ColumnInfo>();
            this.data = new List<Map<String, Object>>();
        }
    }

    public class ColumnInfo {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;

        public ColumnInfo(String label, String fieldName) {
            this.label = label;
            this.fieldName = fieldName;
        }
    }

    @AuraEnabled
    public static SearchResult searchMarketItems(String type, String searchText, String recordId, String parentId) {

        SearchResult result = new SearchResult();

        if (String.isBlank(recordId)) {
            return result;
        }

        String searchKey = '%' + (searchText == null ? '' : searchText) + '%';

        System.debug('🎩 searchMarketItems type=['+ type +'], searchText=['+ searchText +'], recordId=['+ recordId +'], parentId=['+ parentId +']');

        String sObjectName = COM_MetaUtil.getObjectNameById(recordId);
        Boolean isOpp = 'Opportunity'.equalsIgnoreCase(sObjectName);
        Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(sObjectName);

        List<String> query = new List<String>();
        query.add('SELECT BizRegion__c,');
        if(isOpp) {
            query.add('PeriodFrom__c');
            query.add('FROM Opportunity');
        }
        if(isPlacement) {
            query.add('InceptionDate__c');
            query.add('FROM Placement__c');
        }
        query.add('WHERE Id = :recordId LIMIT 1');

        SObject masterObj = Database.query(String.join(query, ' '));

        Date baseDate = (Date) (isOpp ? masterObj.get('PeriodFrom__c') : masterObj.get('InceptionDate__c'));
        String bizRegion = COM_Util.toStr((String) masterObj.get('BizRegion__c'));

        if (baseDate == null || String.isBlank(parentId)) {
            return result;
        }

        // 1. Opportunity PeriodFrom__c 조회 //
        //Opportunity opp = [SELECT PeriodFrom__c, BizRegion__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
//        if (opp.PeriodFrom__c == null || String.isBlank(parentId)) {
//            return result;
//        }
//        System.debug('🎩 searchMarketItems type=['+ type +'], searchText=['+ searchText +'], recordId=['+ recordId +'], parentId=['+ parentId +'], PeriodFrom__c=['+ opp.PeriodFrom__c +'], BizRegion__c=['+ opp.BizRegion__c +']');

        Map<String, SObjectType> sObjectTypeMap = Schema.getGlobalDescribe();

        if (type == 'Security') {
            Map<String, SObjectField> targetObjectFields = sObjectTypeMap.get('ACC_AdditionalInfo__c').getDescribe().fields.getMap();
            // 컬럼 정의
            result.columns.add(new ColumnInfo(targetObjectFields.get('Name').getDescribe().label, 'Name'));
            result.columns.add(new ColumnInfo(targetObjectFields.get('BindingFrom__c').getDescribe().label, 'BindingFrom__c'));
            result.columns.add(new ColumnInfo(targetObjectFields.get('BindingTo__c').getDescribe().label, 'BindingTo__c'));

            Id rtId = COM_MetaUtil.getRecordTypeIdByDeveloperName('ACC_AdditionalInfo__c','Security');

            // 2. Security 조회 (ACC_AdditionalInfo__c)
            // 조건: MGA(parentId)와 연결됨 AND 기간 유효
            List<ACC_AdditionalInfo__c> objs = [
                    SELECT Id, Name, BindingFrom__c, BindingTo__c
                    FROM ACC_AdditionalInfo__c
                    WHERE RecordTypeId =:rtId
                    AND Account_lk__c = :parentId
                    AND BindingFrom__c <= :baseDate
                    AND BindingTo__c >= :baseDate
                    AND Name LIKE :searchKey
                    ORDER BY Name DESC, BindingFrom__c
                    LIMIT 100
            ];

            for (ACC_AdditionalInfo__c obj : objs) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('key', obj.Id);
                row.put('Id', obj.Id);
                row.put('Name', obj.Name);
                row.put('BindingFrom__c', obj.BindingFrom__c);
                row.put('BindingTo__c', obj.BindingTo__c);
                result.data.add(row);
            }
        }

        if (type == 'Reinsurer') {
            Map<String, SObjectField> targetObjectFields = sObjectTypeMap.get('COM_FacilityParticipant__c').getDescribe().fields.getMap();
            // 컬럼 정의
            result.columns.add(new ColumnInfo('Reinsurer', 'Name'));
            result.columns.add(new ColumnInfo(targetObjectFields.get('PeriodFrom__c').getDescribe().label, 'PeriodFrom__c'));
            result.columns.add(new ColumnInfo(targetObjectFields.get('PeriodTo__c').getDescribe().label, 'PeriodTo__c'));

            query = new List<String>();
            query.add('SELECT Id, ReinsurerAccount_lk__c, ReinsurerAccount_lk__r.Name, PeriodFrom__c, PeriodTo__c');
            query.add('FROM COM_FacilityParticipant__c');
            query.add('WHERE Facility_lk__c = :parentId');
            query.add('AND PeriodFrom__c <= :baseDate');
            query.add('AND PeriodTo__c >= :baseDate');
            query.add('AND ReinsurerAccount_lk__c != NULL');
            if('LK_KR'.equalsIgnoreCase(bizRegion)) query.add('AND ReinsurerAccount_lk__r.ActiveKr_is__c = TRUE');
            if('LK_Re'.equalsIgnoreCase(bizRegion)) query.add('AND ReinsurerAccount_lk__r.ActiveRe_is__c = TRUE');
            if('LK_VN'.equalsIgnoreCase(bizRegion)) query.add('AND ReinsurerAccount_lk__r.ActiveVn_is__c = TRUE');
            query.add('ORDER BY PeriodFrom__c, PeriodTo__c ');
            query.add('');

            for (COM_FacilityParticipant__c obj : Database.query(String.join(query, ' '))) {
                result.data.add(new Map<String, Object>{
                        'key' => obj.Id,
                        'Id' => obj.ReinsurerAccount_lk__c,
                        'Name' => obj.ReinsurerAccount_lk__r.Name,
                        'PeriodFrom__c' => obj.PeriodFrom__c,
                        'PeriodTo__c' => obj.PeriodTo__c,
                        'FacilityParticipantId' => obj.Id
                });
            }
        }
        result.periodFromLabel = isOpp ? Schema.SObjectType.Opportunity.fields.PeriodFrom__c.getLabel() : Schema.SObjectType.Placement__c.fields.InceptionDate__c.getLabel();
        result.periodFromDate = baseDate;

        return result;
    }
}