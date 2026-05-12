/**********************************************************************************
 * @filename       : OPP_SlipInfo_tr.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-02 (월)
 * @group         :
 * @group-content :
 * @description   : OPP_SlipInfo__c 트리거 핸들러 클래스
 *                  Before Insert / Update 시 TextArea 타입 필드를 Unicode/HTML 엔티티 정규화하고,
 *                  After Insert 시점에 아래 로직을 수행한다.
 *                  1. RI Offer Slip 생성 시 동일 Opportunity/Placement 의 이전 Latest RI Slip 을 false 처리
 *                  2. Cedant Offer / Cedant Closing Slip 생성 시 동일 Opportunity/Placement 의 이전 Latest Cedant Slip 을 false 처리
 *                     - Placement 전용 생성(Placement != null && Opportunity == null) 인 경우에도 동일하게 처리
 *                  3. RI Offer / RI Closing Slip 생성 시 부모 Opportunity 의 StageName 을 'Negotiating' 으로 변경
 *                  4. RI Offer / RI Closing Slip 생성 시 연결된 OPP_PremiumSchedule(PaymentType=Install, Type=Schedule) 기반으로
 *                     PremiumPaymentTerms__c 텍스트를 자동 생성하여 업데이트
 *                  5. Cedant Offer / Cedant Closing Slip 생성 시 연결된 TSI By Location 레코드의 SlipInfo_md__c 를
 *                     가장 최신 Cedant Slip(Closing 우선, 없으면 Offer)으로 재연결
 * @test-class    : OPP_SlipInfo_tr_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-02      i2max            Create
**********************************************************************************/

public with sharing class OPP_SlipInfo_tr extends TriggerHandler {

    private static Set<String> slipInfoNormalizeTargetFields;

    /**
     * @description OPP_SlipInfo__c 생성 전 텍스트 계열 필드 디코딩/정규화 처리
     */
    public override void beforeInsert() {
        normalizeSlipInfoTextAreas(Trigger.new);
    }

    /**
     * @description OPP_SlipInfo__c 수정 전 텍스트 계열 필드 디코딩/정규화 처리
     */
    public override void beforeUpdate() {
        normalizeSlipInfoTextAreas(Trigger.new);
    }


    /**
     * @description
     * OPP_SlipInfo__c Trigger Handler (after insert)
     *
     * - Slip 생성 시 Type별 후처리 수행
     *   1) Latest Slip 관리 (RI / Cedant)
     *   2) Opportunity Stage 업데이트 (RI Offer)
     *   3) Premium Payment Terms 생성
     *   4) TSI By Location → 최신 Cedant Slip로 재연결
     */
    public override void afterInsert() {
        // 타입별로 분리해서 호출
        List<OPP_SlipInfo__c> riSlips = new List<OPP_SlipInfo__c>();
        List<OPP_SlipInfo__c> cedantSlips = new List<OPP_SlipInfo__c>();

        for (OPP_SlipInfo__c slip : (List<OPP_SlipInfo__c>) Trigger.new) {
            if (slip.Type__c == 'RI Offer') {
                riSlips.add(slip);
            } else if (slip.Type__c == 'Cedant Offer' || slip.Type__c == 'Cedant Closing') {
                cedantSlips.add(slip);
            }
        }

        if (!riSlips.isEmpty()) {
            handleLatestRISlip(riSlips);
        }
        if (!cedantSlips.isEmpty()) {
            handleLatestCedantSlip(cedantSlips);
        }

        this.updateOppStageOnRIOfferSlip(Trigger.new);
        this.updatePremiumPaymentTerms(Trigger.new);
        this.updateTSIToLatestSlip(Trigger.new);
       // this.handleRIClosingDocGen(Trigger.new);
    }

    /**
     * @description OPP_SlipInfo__c의 입력 가능한 텍스트 계열 필드를 COM_NormalizeUnicode로 디코딩/정규화
     * @param slips 정규화 대상 SlipInfo 목록
     */
    private static void normalizeSlipInfoTextAreas(List<OPP_SlipInfo__c> slips) {
        if (slips == null || slips.isEmpty()) return;

        Set<String> targetFields = getSlipInfoNormalizeTargetFields();
        if (targetFields.isEmpty()) return;

        for (OPP_SlipInfo__c slip : slips) {
            for (String fieldName : targetFields) {
                Object rawValue = slip.get(fieldName);
                if (rawValue == null) continue;

                String normalizedValue = COM_NormalizeUnicode.normalizeUnicode(String.valueOf(rawValue));
                slip.put(fieldName, normalizedValue);
            }
        }
    }

    /**
     * @description OPP_SlipInfo__c의 입력 가능한 텍스트 계열 필드 API명 목록 조회
     * @return Set<String>
     */
    private static Set<String> getSlipInfoNormalizeTargetFields() {
        if (slipInfoNormalizeTargetFields != null) {
            return slipInfoNormalizeTargetFields;
        }

        slipInfoNormalizeTargetFields = new Set<String>();

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.OPP_SlipInfo__c.fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (!fieldDescribe.isCalculated()
                    && (fieldDescribe.isCreateable() || fieldDescribe.isUpdateable())
                    && isNormalizeTargetFieldType(fieldDescribe.getType())) {
                slipInfoNormalizeTargetFields.add(fieldName);
            }
        }

        return slipInfoNormalizeTargetFields;
    }

    /**
     * @description COM_NormalizeUnicode 적용 대상 텍스트 계열 필드 타입 여부 반환
     * @param fieldType 필드 DisplayType
     * @return Boolean
     */
    private static Boolean isNormalizeTargetFieldType(Schema.DisplayType fieldType) {
        return fieldType == Schema.DisplayType.STRING
                || fieldType == Schema.DisplayType.TEXTAREA
                || fieldType == Schema.DisplayType.ENCRYPTEDSTRING;
    }

    /**
     * @description
     * RI Slip 생성 시 동일 Opportunity/Placement 기준 기존 Latest Slip을 비활성화
     * (Latest_is__c = false 처리)
     *
     * @param triggerNewList 신규 생성된 RI Slip 목록
     */
    private static void handleLatestRISlip(List<OPP_SlipInfo__c> triggerNewList) {
        if (triggerNewList == null || triggerNewList.isEmpty()) return;

        Set<Id> newIds = new Set<Id>();
        Map<String, Set<Id>> typeToOppIds = new Map<String, Set<Id>>();
        Map<String, Set<Id>> typeToPlacementIds = new Map<String, Set<Id>>();

        for (OPP_SlipInfo__c s : triggerNewList) {
            if (s.Id != null) newIds.add(s.Id);
            if (s.Latest_is__c != true) continue;

            if (s.Opportunity_lk__c != null) {
                if (!typeToOppIds.containsKey(s.Type__c)) {
                    typeToOppIds.put(s.Type__c, new Set<Id>());
                }
                typeToOppIds.get(s.Type__c).add(s.Opportunity_lk__c);
            }

            if (s.Placement_lk__c != null && s.Opportunity_lk__c == null && s.Latest_is__c == true) {
                if (!typeToPlacementIds.containsKey(s.Type__c)) {
                    typeToPlacementIds.put(s.Type__c, new Set<Id>());
                }
                typeToPlacementIds.get(s.Type__c).add(s.Placement_lk__c);
            }
        }

        if (typeToOppIds.isEmpty() && typeToPlacementIds.isEmpty()) return;

        List<OPP_SlipInfo__c> updateList = new List<OPP_SlipInfo__c>();

        for (String typeKey : typeToOppIds.keySet()) {
            Set<Id> oppIds = typeToOppIds.get(typeKey);

            for (OPP_SlipInfo__c oldSlip : [
                    SELECT Id, Latest_is__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c IN :oppIds
                    AND Type__c = :typeKey
                    AND Latest_is__c = TRUE
                    AND Id NOT IN :newIds
            ]) {
                oldSlip.Latest_is__c = false;
                updateList.add(oldSlip);
            }
        }

        for (String typeKey : typeToPlacementIds.keySet()) {
            Set<Id> placementIds = typeToPlacementIds.get(typeKey);

            for (OPP_SlipInfo__c oldSlip : [
                    SELECT Id, Latest_is__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c IN :placementIds
                    AND Type__c = :typeKey
                    AND Opportunity_lk__c = NULL
                    AND Latest_is__c = TRUE
                    AND Id NOT IN :newIds
            ]) {
                oldSlip.Latest_is__c = false;
                updateList.add(oldSlip);
            }
        }

        if (!updateList.isEmpty()) {
            Map<Id, OPP_SlipInfo__c> uniqueMap = new Map<Id, OPP_SlipInfo__c>();
            for (OPP_SlipInfo__c s : updateList) uniqueMap.put(s.Id, s);
            update uniqueMap.values();
        }
    }

    /**
     * @description
     * Cedant Slip 생성 시 동일 Opportunity/Placement 기준 기존 Latest Slip을 비활성화
     * - Cedant Offer / Cedant Closing 대상
     * - Placement-only 케이스 별도 처리
     *
     * @param triggerNewList 신규 생성된 Cedant Slip 목록
     */
    public static void handleLatestCedantSlip(List<OPP_SlipInfo__c> triggerNewList) {
        System.debug('### handleLatestCedantSlip START, types: ');

        if (triggerNewList == null || triggerNewList.isEmpty()) return;

        Set<Id> newIds = new Set<Id>();
        Map<String, Set<Id>> typeToOppIds       = new Map<String, Set<Id>>();
        Map<String, Set<Id>> typeToPlacementIds = new Map<String, Set<Id>>();

        for (OPP_SlipInfo__c slip : triggerNewList) {
            System.debug('### input slip - Id: ' + slip.Id + ' Type: ' + slip.Type__c + ' Latest: ' + slip.Latest_is__c);

            if (slip.Id != null) newIds.add(slip.Id);
            if (slip.Latest_is__c != true) continue;

            if (slip.Opportunity_lk__c != null) {
                if (!typeToOppIds.containsKey(slip.Type__c)) {
                    typeToOppIds.put(slip.Type__c, new Set<Id>());
                }
                typeToOppIds.get(slip.Type__c).add(slip.Opportunity_lk__c);
            }

            // Placement-only 신규 생성(Placement != null && Opportunity == null)인 경우만 Placement 기준 Latest 처리
            if (slip.Placement_lk__c != null && slip.Opportunity_lk__c == null) {
                if (!typeToPlacementIds.containsKey(slip.Type__c)) {
                    typeToPlacementIds.put(slip.Type__c, new Set<Id>());
                }
                typeToPlacementIds.get(slip.Type__c).add(slip.Placement_lk__c);
            }
        }

        if (typeToOppIds.isEmpty() && typeToPlacementIds.isEmpty()) return;

        List<OPP_SlipInfo__c> updateList = new List<OPP_SlipInfo__c>();

        // Opportunity 기준 처리
        for (String typeKey : typeToOppIds.keySet()) {
            for (OPP_SlipInfo__c oldSlip : [
                    SELECT Id, Latest_is__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c IN :typeToOppIds.get(typeKey)
                    AND Type__c = :typeKey
                    AND Latest_is__c = TRUE
                    AND Id NOT IN :newIds
            ]) {
                oldSlip.Latest_is__c = false;
                updateList.add(oldSlip);
            }
        }

        // Placement 기준 처리
        for (String typeKey : typeToPlacementIds.keySet()) {
            for (OPP_SlipInfo__c oldSlip : [
                    SELECT Id, Latest_is__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c IN :typeToPlacementIds.get(typeKey)
                    AND Type__c = :typeKey
                    AND Opportunity_lk__c = NULL
                    AND Latest_is__c = TRUE
                    AND Id NOT IN :newIds
            ]) {
                oldSlip.Latest_is__c = false;
                updateList.add(oldSlip);
            }
        }

        if (!updateList.isEmpty()) {
            Map<Id, OPP_SlipInfo__c> uniqueMap = new Map<Id, OPP_SlipInfo__c>();
            for (OPP_SlipInfo__c s : updateList) uniqueMap.put(s.Id, s);
            update uniqueMap.values();
        }
    }



    /**
     * @description
     * RI Offer Slip 생성 시 부모 Opportunity의 StageName을 'Negotiating'으로 변경ㄴ
     * (조건: Type__c = 'RI Offer' AND RecordType.Name = 'Slip')
     * @param newList Trigger.new
     */
    private void updateOppStageOnRIOfferSlip(List<SObject> newList) {
        Set<Id> oppIds = new Set<Id>();
        Id slipRTId = COM_MetaUtil.getRecordTypeIdByDeveloperName('OPP_SlipInfo__c', 'Slip');

        for (OPP_SlipInfo__c slip : (List<OPP_SlipInfo__c>) newList) {
            if (slip.RecordTypeId == slipRTId && slip.Type__c == 'RI Offer' && slip.Opportunity_lk__c != null && !slip.IsClosingOrClosedByOppIs_fm__c) {
                oppIds.add(slip.Opportunity_lk__c);
            }
        }
        if (oppIds.isEmpty()) return;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Id oppId : oppIds) {
            opportunities.add(new Opportunity(
                    Id = oppId,
                    StageName = 'Negotiating'
            ));
        }

        if (!opportunities.isEmpty()) {
            update opportunities;
        }
    }

    /**
     * @description
     * RI Offer, RI Closing Slip 생성 시 Premium Payment Terms 업데이트
     * (조건: Type__c = 'RI Offer' OR 'RI Closing')
     * OPP_PremSchedule 의 PaymentType__c ='Install' AND Type__c ='Schedule'
     * @param triggerNewList Trigger.new
     */
    private void updatePremiumPaymentTerms (List<OPP_SlipInfo__c> triggerNewList) {
        Set<Id> oppIds = new Set<Id>();
        List<OPP_SlipInfo__c> targetSlips = new List<OPP_SlipInfo__c>();

        for (OPP_SlipInfo__c slip : triggerNewList) {
            if ((slip.Type__c == 'RI Offer' || slip.Type__c == 'RI Closing') && slip.Opportunity_lk__c != null) {
                targetSlips.add(slip);
                oppIds.add(slip.Opportunity_lk__c);
            }
        }

        if (targetSlips.isEmpty()) return;

        // OPP_PremSchedule 조건 레코드 존재 여부 (Payment Type = Install -> 할부인 경우)
        Map<Id, List<OPP_PremiumSchedule__c>> premSchMap = new Map<Id, List<OPP_PremiumSchedule__c>>();

        for (OPP_PremiumSchedule__c oppPs : [
                SELECT Opportunity_lk__c, Percentage__c, InstallDate_fm__c
                FROM OPP_PremiumSchedule__c
                WHERE Opportunity_lk__c IN :oppIds
                AND PaymentType__c = 'Install'
                AND Type__c = 'Schedule'
                ORDER BY InstallDate_fm__c ASC
        ]) {
            if (!premSchMap.containsKey(oppPs.Opportunity_lk__c)) {
                premSchMap.put(oppPs.Opportunity_lk__c, new List<OPP_PremiumSchedule__c>());
            }
            premSchMap.get(oppPs.Opportunity_lk__c).add(oppPs);
        }

        List<OPP_SlipInfo__c> updateList = new List<OPP_SlipInfo__c>();

        for (OPP_SlipInfo__c slip : targetSlips) {

            List<OPP_PremiumSchedule__c> schedules = premSchMap.get(slip.Opportunity_lk__c);

            if (schedules == null || schedules.isEmpty()) {
                continue;
            }

            Integer count = schedules.size();
            String countWord = numberToWord(count);

            String result = 'Payment payable in ' + countWord + ' ' + (count == 1 ? 'Installment.\n' : 'Installments.\n');
            Integer index = 1;

            for (OPP_PremiumSchedule__c sch : schedules) {

                String formattedDate = formatEnglishDate(sch.InstallDate_fm__c);

                result += '   - ' + getOrdinal(index) + ' Installment (' + sch.Percentage__c + '%) : ' + formattedDate + '\n';
                index++;
            }

            updateList.add(new OPP_SlipInfo__c(
                    Id = slip.Id,
                    PremiumPaymentTerms__c = result
            ));
        }

            if (!updateList.isEmpty()) {
                update updateList;
            }
    }

    /**
     * @description
     * 날짜를 'DD Mon YYYY' 형식으로 변환
     * (예: 01 Jan 2025)
     * @param d Date
     * @return String
     */
    private static String formatEnglishDate(Date d) {

        if (d == null) return '';

        String[] months = new String[]{
                'Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'
        };

        return String.valueOf(d.day()).leftPad(2, '0') + ' ' +
                months[d.month() - 1] + ' ' +
                String.valueOf(d.year());
    }

    /**
     * @description
     * 숫자를 서수 형태로 변환 (1st, 2nd, 3rd, ...)
     * @param numbers 순번
     * @return String
     */
    private static String getOrdinal(Integer numbers) {

        if (numbers == 1) return '1st';
        if (numbers == 2) return '2nd';
        if (numbers == 3) return '3rd';
        return numbers + 'th';
    }

    /**
     * @description
     * 숫자를 영문 단어로 변환 (1 → One, 2 → Two ...)
     * @param numbers 숫자
     * @return String
     */
    private static String numberToWord(Integer numbers) {

        Map<Integer, String> words = new Map<Integer, String>{
                1 => 'One',
                2 => 'Two',
                3 => 'Three',
                4 => 'Four',
                5 => 'Five',
                6 => 'Six',
                7 => 'Seven',
                8 => 'Eight',
                9 => 'Nine',
                10 => 'Ten',
                11 => 'Eleven',
                12 => 'Twelve'
        };

        if (words.containsKey(numbers)) {
            return words.get(numbers);
        }

        return String.valueOf(numbers);
    }

    /**
     * @description
     * TSI By Location List 가장 최신의 Cedant Slip 레코드로 업데이트
     * @param triggerNewList Trigger.new
     */
    private void updateTSIToLatestSlip (List<OPP_SlipInfo__c> triggerNewList) {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> placementIds = new Set<Id>();

        for (OPP_SlipInfo__c slip : triggerNewList) {
            if ((slip.Type__c == 'Cedant Offer' || slip.Type__c == 'Cedant Closing')) {
                if (slip.Opportunity_lk__c != null) {
                    oppIds.add(slip.Opportunity_lk__c);
                }

                if (slip.Placement_lk__c != null) {
                    placementIds.add(slip.Placement_lk__c);
                }
            }
        }

        if (oppIds.isEmpty() && placementIds.isEmpty()) return;

        // Latest Cedant Slip 조회
        List<OPP_SlipInfo__c> slips = [
                SELECT Id, Opportunity_lk__c, Placement_lk__c, Type__c
                FROM OPP_SlipInfo__c
                WHERE Latest_is__c = TRUE
                AND Type__c IN ('Cedant Offer', 'Cedant Closing')
                AND (
                        Opportunity_lk__c IN :oppIds
                        OR Placement_lk__c IN :placementIds
                )
        ];

        Map<Id, Id> oppToTargetSlip = new Map<Id, Id>();
        Map<Id, Id> oppToOfferSlip = new Map<Id, Id>();

        Map<Id, Id> placementToTargetSlip = new Map<Id, Id>();
        Map<Id, Id> placementToOfferSlip = new Map<Id, Id>();

        for (OPP_SlipInfo__c slip : slips) {
            // Opportunity
            if (slip.Opportunity_lk__c != null) {
                if (slip.Type__c == 'Cedant Closing') {
                    oppToTargetSlip.put(slip.Opportunity_lk__c, slip.Id);
                }
                if (slip.Type__c == 'Cedant Offer') {
                    oppToOfferSlip.put(slip.Opportunity_lk__c, slip.Id);
                }
            }

            // Placement
            if (slip.Placement_lk__c != null) {
                if (slip.Type__c == 'Cedant Closing') {
                    placementToTargetSlip.put(slip.Placement_lk__c, slip.Id);
                }
                if (slip.Type__c == 'Cedant Offer') {
                    placementToOfferSlip.put(slip.Placement_lk__c, slip.Id);
                }
            }
        }

        // Closing 없으면 Offer 사용 (Opportunity)
        for (Id oppId : oppToOfferSlip.keySet()) {
            if (!oppToTargetSlip.containsKey(oppId)) {
                oppToTargetSlip.put(oppId, oppToOfferSlip.get(oppId));
            }
        }

        // Closing 없으면 Offer 사용 (Placement)
        for (Id placementId : placementToOfferSlip.keySet()) {
            if (!placementToTargetSlip.containsKey(placementId)) {
                placementToTargetSlip.put(placementId, placementToOfferSlip.get(placementId));
            }
        }

        if (oppToTargetSlip.isEmpty() && placementToTargetSlip.isEmpty()) return;

        // 기존 TSI By Location 조회
        List<OPP_TSIByLocation__c> tsiList = [
                SELECT Id, SlipInfo_md__c, SlipInfo_md__r.Opportunity_lk__c, SlipInfo_md__r.Placement_lk__c
                FROM OPP_TSIByLocation__c
                WHERE Type__c = 'TSIByLocation'
                AND (
                        SlipInfo_md__r.Opportunity_lk__c IN :oppIds
                        OR SlipInfo_md__r.Placement_lk__c IN :placementIds
                )
        ];

        for (OPP_TSIByLocation__c tsi : tsiList) {
            // Opportunity
            if (tsi.SlipInfo_md__r.Opportunity_lk__c != null) {
                Id oppId = tsi.SlipInfo_md__r.Opportunity_lk__c;
                if (oppToTargetSlip.containsKey(oppId)) {
                    Id targetSlipId = oppToTargetSlip.get(oppId);
                    if (tsi.SlipInfo_md__c != targetSlipId) {
                        tsi.SlipInfo_md__c = targetSlipId;
                    }
                }
            }

            // Placement
            if (tsi.SlipInfo_md__r.Placement_lk__c != null) {
                Id placementId = tsi.SlipInfo_md__r.Placement_lk__c;
                if (placementToTargetSlip.containsKey(placementId)) {
                    Id targetSlipId = placementToTargetSlip.get(placementId);
                    if (tsi.SlipInfo_md__c != targetSlipId) {
                        tsi.SlipInfo_md__c = targetSlipId;
                    }
                }
            }
        }

        if (!tsiList.isEmpty()) {
            update tsiList;
        }
    }

}