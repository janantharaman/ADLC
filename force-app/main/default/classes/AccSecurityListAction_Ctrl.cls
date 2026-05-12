/**********************************************************************************
 * @filename      : AccSecurityListAction_Ctrl.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2025-12-09 (화)
 * @group         :
 * @group-content :
 * @description   : ACC_AdditionalInfo__c (Security) 관리용 Controller
 *                  - Security 데이터 조회 
 *                  - Account 정보 및 Country 조회
 *                  - Security 레코드 생성 / 수정 / 삭제
 *                  - 파일 첨부 개수 조회
 * @test-class    : AccSecurityListAction_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-09      i2max            Create
**********************************************************************************/

public without sharing class AccSecurityListAction_Ctrl {

    /**
     * @description
     * Security 데이터 조회 (검색 조건 기반 동적 SOQL)
     * @param searchParams accountId, reinsurer, periodFrom, periodTo
     * @return ACC_AdditionalInfo__c 리스트
     */
    @AuraEnabled
    public static List<ACC_AdditionalInfo__c> searchSecurityData(Map<String, Object> searchParams) {
        String accountId = (String) searchParams.get('accountId');
        String reinsurer = (String) searchParams.get('reinsurer');
        String periodFrom = (String) searchParams.get('periodFrom');
        String periodTo = (String) searchParams.get('periodTo');

        List<String> whereList = new List<String>();

        System.debug('searchParams = ' + searchParams);

        Id securityRtId = getSecurityRecordType();
        whereList.add('RecordTypeId = \'' + securityRtId + '\'');

        if (String.isNotBlank(accountId)) {
            whereList.add(
                    '(Account_lk__c = \'' + accountId + '\' ' +
                            ' OR Reinsurer_lk__c = \'' + accountId + '\')'
            );
        }
        if (String.isNotBlank(reinsurer)) {
            whereList.add('Reinsurer_lk__r.Name LIKE \'%' + String.escapeSingleQuotes(reinsurer) + '%\'');
        }
        if (String.isNotBlank(periodFrom)) {
            whereList.add('BindingFrom__c >= ' + periodFrom);
        }
        if (String.isNotBlank(periodTo)) {
            whereList.add('BindingTo__c <= ' + periodTo);
        }

        String whereClause = whereList.isEmpty()
                ? ''
                : ' WHERE ' + String.join(whereList, ' AND ');

        String soql = 'SELECT Id, Name, Account_lk__c, Account_lk__r.Name, Reinsurer_lk__c, Reinsurer_lk__r.Name, Country__c, BindingFrom__c, BindingTo__c, Remarks__c, ActiveSecurity_is__c ' +
                'FROM ACC_AdditionalInfo__c ' + whereClause;

        System.debug('SOQL = ' + soql);

        return Database.query(soql);
    }

    /**
     * @description
     * Account의 InsuredType__c 조회
     * @param accountId Account Id
     * @return Account
     */
    @AuraEnabled(Cacheable=true)
    public static Account getAccountType(Id accountId) {
        return [
                SELECT Id, InsuredType__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];
    }

    /**
     * @description
     * ACC_AdditionalInfo__c의 Security RecordType Id 조회
     * @return RecordType Id
     */
    private static Id getSecurityRecordType() {
        Map<String, String> recordTypeMap = COM_MetaUtil.getRTByRTDevNm('ACC_AdditionalInfo__c');

        if (recordTypeMap.containsKey('Security')) {
            return recordTypeMap.get('Security');
        }

        throw new AuraHandledException('Security record type not found.');
    }

    // Check User Permission
/*    @AuraEnabled(Cacheable=true)
    public static Boolean getSecurityPermission(Id accountId) {

        Boolean hasPermission = [
                SELECT COUNT()
                FROM PermissionSetAssignment
                WHERE AssigneeId =: UserInfo.getUserId()
                AND PermissionSet.Name = 'ACC_Security'
        ] > 0;

        if (String.isBlank(accountId)) {
            return hasPermission;
        }

        Account acc = [
                SELECT OwnerId
                FROM Account
                WHERE Id =: accountId
                LIMIT 1
        ];

        Boolean isOwner = acc.OwnerId == UserInfo.getUserId();

        return isOwner || hasPermission;
    }*/

    /**
     * @description
     * Security 레코드 신규 생성
     * - 필수값(Reinsurer, BindingFrom, BindingTo) 검증
     * - 날짜 String → Date 변환
     * @param records 입력 데이터(Map 형태)
     * @return 생성된 레코드 리스트
     */
    @AuraEnabled
    public static List<ACC_AdditionalInfo__c> insertNewRecords(List<Map<String, Object>> records) {
        System.debug('insertNewRecords records = ' + records);

        if (records == null || records.isEmpty()) {
            return new List<ACC_AdditionalInfo__c>();
        }

        List<ACC_AdditionalInfo__c> insertList = new List<ACC_AdditionalInfo__c>();

        Id securityRTId = getSecurityRecordType();

        for (Map<String, Object> row : records) {
            // 유효한 레코드 값 검증
            if (row.get('Reinsurer_lk__c') == null || row.get('BindingFrom__c') == null || row.get('BindingTo__c') == null) {
                continue; // 건너뜀
            }

            ACC_AdditionalInfo__c rec = new ACC_AdditionalInfo__c();

            rec.Account_lk__c = (String) row.get('Account_lk__c');
            //rec.Name = (String)row.get('Name');
            rec.Reinsurer_lk__c = (String)row.get('Reinsurer_lk__c');
            rec.Country__c = (String)row.get('Country__c');
            rec.Remarks__c = (String)row.get('Remarks__c');
            // record Type 설정
            rec.RecordTypeId = securityRTId;

            // Boolean 값 설정
            Object isActive = row.get('ActiveSecurity_is__c');
            if (isActive == null) {
                rec.ActiveSecurity_is__c = false;
            } else {
                rec.ActiveSecurity_is__c = (Boolean)isActive;
            }

            // 날짜 변환
            if (row.containsKey('BindingFrom__c')) {
                String bf = (String)row.get('BindingFrom__c');
                if (String.isNotBlank(bf)) rec.BindingFrom__c = Date.valueOf(bf);
            }
            if (row.containsKey('BindingTo__c')) {
                String bt = (String)row.get('BindingTo__c');
                if (String.isNotBlank(bt)) rec.BindingTo__c = Date.valueOf(bt);
            }

            insertList.add(rec);
        }

        if (!insertList.isEmpty()) {
            insert insertList;
        }

        return insertList;
    }

    /**
     * @description
     * 선택된 Security 레코드 삭제
     * @param recordIds 삭제 대상 Id 리스트
     */
    @AuraEnabled
    public static void deleteRecords(List<Id> recordIds) {
        System.debug('deleteRecords recordIds = ' + recordIds);

        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        List<ACC_AdditionalInfo__c> deleteList = [
                SELECT Id
                FROM ACC_AdditionalInfo__c
                WHERE Id IN :recordIds
        ];

        if (!deleteList.isEmpty()) {
            delete deleteList;
        }
    }

    /**
     * @description
     * Security 레코드 업데이트
     * @param records 수정 대상 레코드 리스트
     */
    @AuraEnabled
    public static void updateSecurityRecords(List<ACC_AdditionalInfo__c> records) {
        System.debug('updateSecurityRecords records = ' + records);

        if (records == null || records.isEmpty()) {
            return;
        }

        update records;
    }

    /**
     * @description
     * 레코드별 첨부 파일 개수 조회
     * (ContentDocumentLink 기준)
     * @param recordIds 대상 레코드 Id 리스트
     * @return <RecordId, 파일 개수>
     */
    @AuraEnabled(Cacheable=false)
    public static Map<Id, Integer> getFileCounts(List<Id> recordIds) {
        Map<Id, Integer> result = new Map<Id, Integer>();

        for (AggregateResult ar : [
                SELECT LinkedEntityId linkedId, COUNT(Id) cnt
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :recordIds
                GROUP BY LinkedEntityId
        ]) {
            result.put(
                    (Id) ar.get('linkedId'),
                    (Integer) ar.get('cnt')
            );
        }

        return result;
    }

    /**
     * @description
     * Account의 Country__c 조회
     * @param accountId Account Id
     * @return Country 값
     */
    @AuraEnabled(Cacheable=true)
    public static String getCountry(Id accountId) {
        Account acc = [
                SELECT Country__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
        ];

        System.debug('Country__c = ' + acc.Country__c);

        return acc.Country__c;
    }

}