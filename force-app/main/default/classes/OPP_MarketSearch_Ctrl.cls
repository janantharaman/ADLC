/**********************************************************************************
 * @filename      : OPP_MarketSearch_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketSearch_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-07      i2max     Create
**********************************************************************************/
public with sharing class OPP_MarketSearch_Ctrl {

    public class SearchResult {
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
        String searchKey = '%' + (searchText == null ? '' : searchText) + '%';

        System.debug('🎩 searchMarketItems type=['+ type +'], searchText=['+ searchText +'], recordId=['+ recordId +'], parentId=['+ parentId +']');

        // 1. Opportunity PeriodFrom__c 조회
        Opportunity opp = [SELECT PeriodFrom__c FROM Opportunity WHERE Id = :recordId LIMIT 1];

        if (opp.PeriodFrom__c == null || String.isBlank(parentId)) {
            return result;
        }

        if (type == 'Security') {
            // 컬럼 정의
            result.columns.add(new ColumnInfo('Name', 'Name'));
            result.columns.add(new ColumnInfo('Binding From', 'BindingFrom__c'));
            result.columns.add(new ColumnInfo('Binding To', 'BindingTo__c'));

            Id rtId = COM_MetaUtil.getRecordTypeIdByDeveloperName('ACC_AdditionalInfo__c','Security');

            // 2. Security 조회 (ACC_AdditionalInfo__c)
            // 조건: MGA(parentId)와 연결됨 AND 기간 유효
            List<ACC_AdditionalInfo__c> objs = [
                    SELECT Id, Name, BindingFrom__c, BindingTo__c
                    FROM ACC_AdditionalInfo__c
                    WHERE RecordTypeId =:rtId
                    AND Account_lk__c = :parentId
                    AND BindingFrom__c <= :opp.PeriodFrom__c
                    AND BindingTo__c >= :opp.PeriodFrom__c
                    AND Name LIKE :searchKey
                    LIMIT 50
            ];

            for (ACC_AdditionalInfo__c obj : objs) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('Id', obj.Id);
                row.put('Name', obj.Name);
                row.put('BindingFrom__c', obj.BindingFrom__c);
                row.put('BindingTo__c', obj.BindingTo__c);
                result.data.add(row);
            }
        }

        if (type == 'Reinsurer') {
            // 컬럼 정의
            result.columns.add(new ColumnInfo('Reinsurer', 'Name'));
            // 필요 시 추가 컬럼 정의

            List<COM_FacilityParticipant__c> objs = [
                    SELECT Id, ReinsurerAccount_lk__c, ReinsurerAccount_lk__r.Name
                    FROM COM_FacilityParticipant__c
                    WHERE Facility_lk__c = :parentId
                    AND PeriodFrom__c <= :opp.PeriodFrom__c
                    AND PeriodTo__c >= :opp.PeriodFrom__c
            ];

            for (COM_FacilityParticipant__c obj : objs) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('Id', obj.ReinsurerAccount_lk__c); // 선택 시 반환할 ID는 Reinsurer Account ID
                row.put('Name', obj.ReinsurerAccount_lk__r.Name);
                result.data.add(row);
            }
        }
        return result;
    }
}