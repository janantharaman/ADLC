/**********************************************************************************
 * @filename      : COM_Note_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-10 (화)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_Note_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-10      i2max     Create
**********************************************************************************/
public with sharing class COM_Note_Ctrl {

    /**
     * @description 텍스트 필드 검색 방식은 Like로
     * @param recordId recordId
     * @param filterCondition 검색 조건
     *
     * @return List<COM_Note__c> 검색결과
     */
    @AuraEnabled(Cacheable=true)
    public static List<COM_Note__c> getNotes(
            Id recordId,
            String filterCondition
    ) {
        System.debug('getNotes 🐶🐶🐶 recordId=['+ recordId +']');
        if (recordId == null) throw new AuraHandledException('recordId is required.');

        Map<String, Object> filterConditions = (Map<String, Object>) JSON.deserializeUntyped(filterCondition);

        System.debug('getNotes 🐶🐶🐶 filterConditions=['+ filterConditions +']');
        List<String> conditions = new List<String>();

        String BDXType = (filterConditions.containsKey('bdxType') ? (String) filterConditions.get('bdxType') : '');
        if(String.isBlank(BDXType)) throw new AuraHandledException('BDX Type is required.');

        Id facilityId;
        String facilityIdStr = COM_Util.getMapStr(filterConditions, 'facilityId');
        if (String.isNotBlank(facilityIdStr)) {
            facilityId = Id.valueOf(facilityIdStr);
            conditions.add('Facility_lk__c = :facilityId');
        }

        String facilityUY = COM_Util.getMapStr(filterConditions, 'facilityUY');
        if (String.isNotBlank(facilityUY)) {
            conditions.add('FacilityUY_fm__c = :facilityUY');
        }

        Id accountId;
        String accountIdStr = COM_Util.getMapStr(filterConditions, 'accountId');
        if (String.isNotBlank(accountIdStr)) {
            accountId = Id.valueOf(accountIdStr);
            conditions.add('Account_lk__c = :accountId');
        }

        Date issueDateFrom;
        String issueDateFromStr = COM_Util.getMapStr(filterConditions, 'issueDateFrom');
        if (String.isNotBlank(issueDateFromStr)) {
            issueDateFrom = Date.valueOf(issueDateFromStr);
            conditions.add('IssueDate__c >= :issueDateFrom');
        }
        Date issueDateTo;
        String issueDateToStr = COM_Util.getMapStr(filterConditions, 'issueDateTo');
        if (String.isNotBlank(issueDateToStr)) {
            issueDateTo = Date.valueOf(issueDateToStr);
            conditions.add('IssueDate__c <= :issueDateTo');
        }

        Date inceptionDateFrom;
        String inceptionDateFromStr = COM_Util.getMapStr(filterConditions, 'inceptionDateFrom');
        if (String.isNotBlank(inceptionDateFromStr)) {
            inceptionDateFrom = Date.valueOf(inceptionDateFromStr);
            conditions.add('PeriodFrom_fm__c >= :inceptionDateFrom');
        }

        Date inceptionDateTo;
        String inceptionDateToStr = COM_Util.getMapStr(filterConditions, 'inceptionDateTo');
        if (String.isNotBlank(inceptionDateToStr)) {
            inceptionDateTo = Date.valueOf(inceptionDateToStr);
            conditions.add('PeriodTo_fm__c <= :inceptionDateTo');
        }

        String transactionTypeStr = COM_Util.getMapStr(filterConditions, 'transactionType');
        System.debug('getNotes 🐶🐶🐶 transactionTypeStr=['+ transactionTypeStr +']');
        if (String.isNotBlank(transactionTypeStr)) {
            List<String> transactionTypes = transactionTypeStr.split(';');
            System.debug('getNotes 🐶🐶🐶 transactionTypes=['+ transactionTypes +']');
            conditions.add('TransactionType_fm__c IN :transactionTypes');
        }

        Id insured;
        String insuredStr = COM_Util.getMapStr(filterConditions, 'insured');
        if (String.isNotBlank(insuredStr)) {
            insured = Id.valueOf(insuredStr);
            conditions.add('Insured_lk__c = :insured');
        }

        Date ppwDateFrom;
        String ppwDateFromStr = COM_Util.getMapStr(filterConditions, 'ppwDateFrom');
        if (String.isNotBlank(ppwDateFromStr)) {
            ppwDateFrom = Date.valueOf(ppwDateFromStr);
            conditions.add('PPWDate__c >= :ppwDateFrom');
        }

        Date ppwDateTo;
        String ppwDateToStr = COM_Util.getMapStr(filterConditions, 'ppwDateTo');
        if (String.isNotBlank(ppwDateToStr)) {
            ppwDateTo = Date.valueOf(ppwDateToStr);
            conditions.add('PPWDate__c <= :ppwDateTo');
        }

        String lob = COM_Util.getMapStr(filterConditions, 'lob');
        System.debug('getNotes 🐶🐶🐶 lob=['+ lob +']');
        if (String.isNotBlank(lob)) {
            System.debug('getNotes 🐶🐶🐶 lob=['+ lob +']');
            conditions.add('LOB_fm__c = :lob');
        }

        if (conditions.isEmpty()) {
            throw new AuraHandledException('검색 조건을 하나 이상 입력해주세요.');
        }

        // ClaimOffset 조회 (BDXType 분기 전에 1회)
        COM_FacilityBDX__c bdx = [
                SELECT FacilityParticipant_lk__r.ClaimOffset_is__c
                FROM COM_FacilityBDX__c
                WHERE Id = :recordId
                LIMIT 1
        ];
        Boolean claimOffset = bdx.FacilityParticipant_lk__r.ClaimOffset_is__c == true;

        if ('Debit Note'.equalsIgnoreCase(BDXType)) {
            if (claimOffset) {
                conditions.add('((TransactionType_fm__c != \'Claim\' AND NoteType__c = \'Debit\') OR (TransactionType_fm__c = \'Claim\' AND NoteType__c = \'Credit\'))');
            } else {
                conditions.add('(TransactionType_fm__c != \'Claim\' AND NoteType__c = \'Debit\')');
            }
        } else if ('SOA'.equalsIgnoreCase(BDXType)) {
            if (claimOffset) {
                conditions.add('((TransactionType_fm__c != \'Claim\' AND NoteType__c = \'Credit\') OR (TransactionType_fm__c = \'Claim\' AND NoteType__c = \'Debit\'))');
            } else {
                conditions.add('(TransactionType_fm__c != \'Claim\' AND NoteType__c = \'Credit\')');
            }
        }
        conditions.add('FacilityBillingCycle_fm__c != \'Separate\'');
        conditions.add('FacilityBDXCycle_fm__c = NULL');
        conditions.add('NoteStatus__c != \'Clear\'');

        for(String condition : conditions) {
            System.debug('getNotes 🐶🐶🐶 condition=[' + condition + ']');
        }
        // SOCSeq__c 확인 필요.
        List<String> query = new List<String>();
        query.add('SELECT Id, Name,');
        query.add('Facility_lk__c, Facility_lk__r.Name, FacilityUY_fm__c,');
        query.add('LKRefNReins__c, CedantFacility_lk__c, CedantFacility_lk__r.Name,');
        query.add('Insured_lk__c, Insured_lk__r.Name,');
        query.add('PeriodFrom_fm__c, PeriodTo_fm__c,');
        query.add('LOB_fm__c, TransactionType_fm__c,');
        query.add('ParentClaimNo_fm__c, CedantClaimNo_fm__c, DateOfLoss_fm__c,');
        query.add('LocationOfLoss_fm__c, ChildClaim_lk__c, ChildClaim_lk__r.Name,');
        query.add('PPWType__c, PPWDays_fm__c, PPWDate__c,');
        query.add('InstallmentNo__c, InstallmentSeq__c, InstallPct__c,');
        query.add('NoteStatus__c, Account_lk__c, Slip_lk__c, OriginCurrency__c');
        query.add('FROM COM_Note__c');
        query.add('WHERE ' + String.join(conditions, ' AND '));
        query.add('AND FacilityBDX_lk__c = Null');
        query.add('WITH SECURITY_ENFORCED');
        query.add('ORDER BY Name DESC');
        query.add('LIMIT 2000');
        query.add('');

        return Database.query(String.join(query, ' '));
    }

    /**
     * @description COM_FacilityBDX__c 생성
     * @param recordId COM_FacilityBDX__c RecordId
     * @param selectedRowsStr 선택된 레코드
     *
     * @return List<COM_FacilityBDXLineItem__c>
     */
    @AuraEnabled
    public static List<COM_FacilityBDXLineItem__c> createRecords(Id recordId, String selectedRowsStr) {

        List<Object> selectedRows = (List<Object>) JSON.deserializeUntyped(selectedRowsStr);
        if (selectedRows == null || selectedRows.isEmpty()) {
            throw new AuraHandledException('선택된 레코드가 없습니다.');
        }

        System.debug('🐶🐶🐶 recordId=['+ recordId +'], selectedRows=['+ selectedRows +']');

        /*
        TSIByLocation_lk__c
        Slip_lk__c와 연결된 TSI by Location 레코드 중, TSI Currency가 COM_Note__c.Origin Currency와 동일 & Type = Slip
        OriginCurrency__c
         */
        Set<Id> slipIdSet = new Set<Id>();
        for (Object obj : selectedRows) {
            Map<String, Object> item = (Map<String, Object>) obj;
            String slipIdStr = COM_Util.getMapStr(item, 'Slip_lk__c');
            if (String.isNotBlank(slipIdStr)) slipIdSet.add(Id.valueOf(slipIdStr));
        }

        Map<String, Id> tsiMap = new Map<String, Id>(); // key: SlipId + '_' + Currency
        if (!slipIdSet.isEmpty()) {
            for (OPP_TSIByLocation__c tsi : [
                    SELECT Id, SlipInfo_md__c, TSICurrency__c
                    FROM OPP_TSIByLocation__c
                    WHERE SlipInfo_md__c IN :slipIdSet
                    AND Type__c = 'Slip'
            ]) {
                tsiMap.put(tsi.SlipInfo_md__c + '_' + tsi.TSICurrency__c, tsi.Id);
            }
        }

        List<COM_FacilityBDXLineItem__c> lineItems = new List<COM_FacilityBDXLineItem__c>();
        List<COM_Note__c> updateNotes = new List<COM_Note__c>();

        for (Object obj : selectedRows) {
            Map<String, Object> item = (Map<String, Object>) obj;

            String noteIdStr = COM_Util.getMapStr(item, 'Id');
            String accountIdStr = COM_Util.getMapStr(item, 'Account_lk__c');
            Id noteId = String.isNotBlank(noteIdStr) ? Id.valueOf(noteIdStr) : null;
            Id accountId = String.isNotBlank(accountIdStr) ? Id.valueOf(accountIdStr) : null;
            
            String slipIdStr = COM_Util.getMapStr(item, 'Slip_lk__c');
            Id slipId = String.isNotBlank(slipIdStr) ? Id.valueOf(slipIdStr) : null;
            String originCurrency = COM_Util.getMapStr(item, 'OriginCurrency__c');
            String tsiKey = slipId != null && originCurrency != null ? slipId + '_' + originCurrency : null;

            lineItems.add(new COM_FacilityBDXLineItem__c(
                    FacilityBDX_md__c = recordId,
                    Note_lk__c = noteId,
                    Slip_lk__c = slipId,
                    TSIByLocation_lk__c = tsiKey != null ? tsiMap.get(tsiKey) : null,
                    Account_lk__c = accountId
            ));
            updateNotes.add(new COM_Note__c(Id = noteId, FacilityBDX_lk__c = recordId));
        }
        insert lineItems;

        if(!updateNotes.isEmpty()) update updateNotes;

        return lineItems;
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> initData() {
        return new Map<String, Object>{
                'Options' => COM_Util.makePickListOptions('Placement__c', 'TransactionType__c', true)
        };
    }


}