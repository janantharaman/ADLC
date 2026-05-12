/**********************************************************************************
 * @filename       : OPP_SlipInfo_Ctrl.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-12 (월)
 * @group         :
 * @group-content :
 * @description   : Opportunity/Placement/OPP_SlipInfo__c(Slip Info) 화면에서 사용되는 메인 Controller
 *                  1. Opportunity / Placement / SlipInfo Id 기준으로 현재 SlipInfo 및 이전 버전과의
 *                     비교 데이터 조회 (getSlipInfo / getSlipInfoBySlipId / getSlipInfoByPlacementId)
 *                     - Cedant Offer / Cedant Closing / Cedant Endorsement 이전 버전 비교 포함
 *                  2. SlipInfo 신규 생성 및 수정 저장 (saveSlipInfo)
 *                     - Opportunity / Placement 컨텍스트에 따라 Latest 처리 및 연관 필드 자동 세팅
 *                  3. RI Offer SlipInfo 생성 (createRIOfferSlipInfo)
 *                     - Cedant Slip 기반으로 RI Offer 레코드 자동 생성
 *                  4. RI Closing 생성 가능 여부 유효성 검증 (validateRIClosing / validateRIClosingByPlacement)
 *                     - Finalized Panel 존재 여부, PremiumSchedule SOA 여부 등 검증
 *                  5. Placement TransactionType = 'END' 기준 RI END 유효성 검증 (validateRIEndPlacement)
 *                  6. TSI(Type=Slip/TSIByLocation) 조회 및 저장 (getTSIByOpportunity / getTSIBySlipId / saveTSIRecords / validateTSITotal)
 *                  7. Gross Prem(PremiumSchedule) 조회 · 저장 · 삭제 (getPremiumSchedule / savePremiumSchedule)
 *                  8. RI Closing / RI END Flow 호출 (runRIClosingFlow 등)
 *                  9. Platform Event 발행 및 NeedRecalculate 플래그 업데이트 (publishRecordChangedEvent / updateRecalculateRequired)
 * @test-class    : OPP_SlipInfo_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-12      i2max            Create
**********************************************************************************/

public without sharing class OPP_SlipInfo_Ctrl {

    private static final String TYPE_CEDANT_OFFER   = 'Cedant Offer';
    private static final String TYPE_CEDANT_CLOSING = 'Cedant Closing';
    private static final String TYPE_CEDANT_ENDORSEMENT = 'Cedant Endorsement';
    private static final String TYPE_RI_ENDORSEMENT = 'RI Endorsement';

    private static final String RT_DEV_NAME_SLIP = 'Slip';

    /**
    * @description OPP_SlipInfo__c 의 'Slip' RecordType Id 를 조회하여 반환
    * @return Id Slip RecordType Id, 없으면 null
    */
    private static Id getSlipRecordTypeId() {
        Map<String, String> recordTypeName = COM_MetaUtil.getRTDevNmByRTId('OPP_SlipInfo__c');

        for (String recordTypeIdStr : recordTypeName.keySet()) {
            if (recordTypeName.get(recordTypeIdStr) == RT_DEV_NAME_SLIP) {
                return (Id)recordTypeIdStr;
            }
        }
        return null;
    }

    /**
     * @description
     * 현재 사용자의 AI 업로드 권한 여부를 반환
     * - PermissionSet 'Prompt Template User' 또는 'Prompt Template Manager' 보유 여부로 판별
     * @return Boolean 권한이 있으면 true, 없으면 false
     */
    @AuraEnabled(Cacheable=true)
    public static Boolean checkUploadPermission () {
        List<PermissionSetAssignment> assignments = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE PermissionSet.Label IN ('Prompt Template User', 'Prompt Template Manager')
                AND AssigneeId = :UserInfo.getUserId()
                LIMIT 1
        ];
        return !assignments.isEmpty();
    }

    /**
    * @description
    * Opportunity 기준으로 현재 SlipInfo(current) 와 비교 대상 SlipInfo(compareTarget) 를 반환
    * - current 우선순위 : 최신 Cedant Closing(Latest=true) → 최신 Cedant Offer(Latest=true)
    * - compareTarget :
    *   - current 가 Cedant Offer 인 경우 → 이전 버전 Cedant Offer
    *   - current 가 Cedant Closing 인 경우 → 최신 Cedant Offer(Latest=true)
    * @param opportunityId 조회 기준 Opportunity 레코드 Id
    * @return Map<String, OPP_SlipInfo__c> 'current', 'compareTarget' 키로 구성된 SlipInfo Map
    */
    @AuraEnabled(Cacheable=true)
    public static Map<String, OPP_SlipInfo__c> getSlipInfo (Id opportunityId) {
        if (opportunityId == null) return null;

        Map<String, OPP_SlipInfo__c> result = new Map<String, OPP_SlipInfo__c>();

        OPP_SlipInfo__c current;

        // 1순위: 최신 Cedant Closing 조회
        List<OPP_SlipInfo__c> closingList = [
                SELECT Id, Type__c, CreatedDate, PolicyHolder__c,
                        Form__c, Reinsured__c, Insured__c, Latest_is__c,
                        PeriodFrom__c, PeriodTo__c,
                        ENDEffectivedDate__c, Amendments__c, Prem100__c,
                        Location__c, TerritoryScope__c, GoverningLaw__c,
                        OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                        RICession__c, RIComm__c, OtherDeduction__c,
                        LimitofLiability__c, Deductible__c,
                        TermsConds__c, ExtensionClauses__c,
                        LossRecord__c, AddInfo__c
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c =: TYPE_CEDANT_CLOSING
                AND Latest_is__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (!closingList.isEmpty()) {
            current = closingList[0];
        } else {
            // 2순위: 최신 Cedant Offer 조회
            List<OPP_SlipInfo__c> offerList = [
                    SELECT Id, Type__c, CreatedDate, PolicyHolder__c,
                            Form__c, Reinsured__c, Insured__c, Latest_is__c,
                            PeriodFrom__c, PeriodTo__c,
                                ENDEffectivedDate__c, Amendments__c, Prem100__c,
                            Location__c, TerritoryScope__c, GoverningLaw__c,
                            OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                            RICession__c, RIComm__c, OtherDeduction__c,
                            LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    AND Type__c =: TYPE_CEDANT_OFFER
                    AND Latest_is__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            if (!offerList.isEmpty()) {
                current = offerList[0];
            }
        }

        if (current == null) {
            result.put('current', null);
            result.put('compareTarget', null);
            return result;
        }

        result.put('current', current);

        OPP_SlipInfo__c compareTarget = null;

        if (current.Type__c == TYPE_CEDANT_OFFER) {
            // Cedant Offer : 현재보다 이전에 생성된 Cedant Offer 와 비교
            List<OPP_SlipInfo__c> prevOfferList = [
                    SELECT Id,
                            Form__c, Reinsured__c, Insured__c, Latest_is__c,
                            PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                            Location__c, TerritoryScope__c, GoverningLaw__c,
                            OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                            RICession__c, RIComm__c, OtherDeduction__c,
                            LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    AND Type__c = :TYPE_CEDANT_OFFER
                    AND Latest_is__c = FALSE
                    AND CreatedDate < :current.CreatedDate
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            compareTarget = prevOfferList.isEmpty() ? null : prevOfferList[0];

        } else if (current.Type__c ==  TYPE_CEDANT_CLOSING) {
            // Cedant Closing : 최신 Cedant Offer(Latest=true) 와 비교
            List<OPP_SlipInfo__c> latestOfferList = [
                    SELECT Id,
                            Form__c, Reinsured__c, Insured__c,
                            PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                            Location__c, TerritoryScope__c, GoverningLaw__c,
                            OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                            RICession__c, RIComm__c, OtherDeduction__c,
                            LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    AND Type__c = :TYPE_CEDANT_OFFER
                    AND Latest_is__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            compareTarget = latestOfferList.isEmpty() ? null : latestOfferList[0];
        }

        result.put('compareTarget', compareTarget);
        System.debug('Result ==> ' + result);
        return result;
    }

    /**
     * @description
     * SlipInfo Id 기준으로 현재 SlipInfo(current) 와 비교 대상 SlipInfo(compareTarget) 를 반환
     * - compareTarget 비교 기준 :
     *   - Cedant Offer       : 동일 Opportunity 의 이전 버전 Cedant Offer
     *   - Cedant Closing     : 동일 Opportunity 의 최신 Cedant Offer
     *   - Cedant Endorsement : 동일 Placement 의 이전 버전 Cedant Endorsement
     *   - RI Endorsement     : 동일 Placement 의 최신 Cedant Endorsement(Latest=true)
     *   - 그 외              : 동일 Opportunity 의 최신 Cedant/RI Endorsement
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @return Map<String, OPP_SlipInfo__c> 'current', 'compareTarget' 키로 구성된 SlipInfo Map
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String, OPP_SlipInfo__c> getSlipInfoBySlipId(Id slipInfoId) {
        if (slipInfoId == null) return null;

        Map<String, OPP_SlipInfo__c> result = new Map<String, OPP_SlipInfo__c>();

        OPP_SlipInfo__c current = [
                SELECT Id, Type__c, CreatedDate,
                        Form__c, Reinsured__c, Insured__c, Latest_is__c,
                        PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                        ENDEffectivedDate__c, Amendments__c, Prem100__c,
                        Location__c, TerritoryScope__c, GoverningLaw__c,
                        OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                        RICession__c, RIComm__c, OtherDeduction__c,
                        LimitofLiability__c, Deductible__c,
                        TermsConds__c, ExtensionClauses__c,
                        LossRecord__c, AddInfo__c,
                        Opportunity_lk__c, Placement_lk__c,
                        Placement_lk__r.TransactionType__c, Placement_lk__r.LKRefNoh__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                AND Type__c IN (:TYPE_CEDANT_OFFER, :TYPE_CEDANT_CLOSING, :TYPE_CEDANT_ENDORSEMENT, :TYPE_RI_ENDORSEMENT)
        ];

        result.put('current', current);

        OPP_SlipInfo__c compareTarget = null;

        if(current.Type__c == TYPE_CEDANT_OFFER) {
            // Cedant Offer : Placement 연결 건은 동일 Placement의 이전 Offer와 비교, 아니면 Opportunity 기준
            List<OPP_SlipInfo__c> prevOfferList;

            if (current.Placement_lk__c != null) {
                prevOfferList = [
                        SELECT Id, Form__c, Reinsured__c, Latest_is__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Placement_lk__c = :current.Placement_lk__c
                        AND Type__c = :TYPE_CEDANT_OFFER
                        AND CreatedDate < :current.CreatedDate
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
            } else {
                prevOfferList = [
                        SELECT Id, Form__c, Reinsured__c, Latest_is__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Opportunity_lk__c = :current.Opportunity_lk__c
                        AND Type__c = :TYPE_CEDANT_OFFER
                        AND CreatedDate < :current.CreatedDate
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
            }

            compareTarget = prevOfferList.isEmpty() ? null : prevOfferList[0];

        } else if(current.Type__c == TYPE_CEDANT_CLOSING) {
            // Cedant Closing : Placement 연결 건은 동일 Placement의 최신 Offer와 비교, 아니면 Opportunity 기준
            List<OPP_SlipInfo__c> prevOfferList;

            if (current.Placement_lk__c != null) {
                prevOfferList = [
                        SELECT Id, Form__c, Reinsured__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                Latest_is__c, Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Placement_lk__c = :current.Placement_lk__c
                        AND Type__c = :TYPE_CEDANT_OFFER
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
            } else {
                prevOfferList = [
                        SELECT Id, Form__c, Reinsured__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                Latest_is__c, Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Opportunity_lk__c = :current.Opportunity_lk__c
                        AND Type__c = :TYPE_CEDANT_OFFER
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
            }

            compareTarget = prevOfferList.isEmpty() ? null : prevOfferList[0];
        } else if (current.Type__c == TYPE_CEDANT_ENDORSEMENT && current.Placement_lk__c != null) {
            // Cedant Endorsement : 동일 Placement 의 이전 버전 Cedant Endorsement 와 비교
            List<OPP_SlipInfo__c> prevCedantEndList = [
                    SELECT Id, Form__c, Reinsured__c, Insured__c,
                            PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                            Latest_is__c, Location__c, TerritoryScope__c, GoverningLaw__c,
                            OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                            RICession__c, RIComm__c, OtherDeduction__c,
                            LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c,
                            ENDEffectivedDate__c, Amendments__c, Prem100__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :current.Placement_lk__c
                    AND Type__c = :TYPE_CEDANT_ENDORSEMENT
                    AND CreatedDate < :current.CreatedDate
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            compareTarget = prevCedantEndList.isEmpty() ? null : prevCedantEndList[0];
        } else if (current.Type__c == TYPE_RI_ENDORSEMENT && current.Placement_lk__c != null) {
            // RI Endorsement : 동일 Placement 의 최신 Cedant Endorsement(Latest=true) 와 비교
            List<OPP_SlipInfo__c> latestCedantEndList = [
                    SELECT Id, Form__c, Reinsured__c, Insured__c,
                            PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                            Latest_is__c, Location__c, TerritoryScope__c, GoverningLaw__c,
                            OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                            RICession__c, RIComm__c, OtherDeduction__c,
                            LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c,
                            ENDEffectivedDate__c, Amendments__c, Prem100__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :current.Placement_lk__c
                    AND Type__c = :TYPE_CEDANT_ENDORSEMENT
                    AND Latest_is__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            compareTarget = latestCedantEndList.isEmpty() ? null : latestCedantEndList[0];
        } else {
            // 그 외 : 동일 Opportunity 의 최신 Cedant/RI Endorsement 와 비교
            List<OPP_SlipInfo__c> prevOfferList = [
                    SELECT Id, Form__c, Reinsured__c, Insured__c,
                            PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                            Latest_is__c, Location__c, TerritoryScope__c, GoverningLaw__c,
                            OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                            RICession__c, RIComm__c, OtherDeduction__c,
                            LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :current.Opportunity_lk__c
                    AND Type__c IN (:TYPE_CEDANT_ENDORSEMENT, :TYPE_RI_ENDORSEMENT)
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            compareTarget = prevOfferList.isEmpty() ? null : prevOfferList[0];
        }

        result.put('compareTarget', compareTarget);
        return result;
    }

    /**
     * @description
     * SlipInfo Id 기준으로 단일 SlipInfo 레코드를 조회하여 반환
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @return OPP_SlipInfo__c 조회된 SlipInfo 레코드, null 이면 null 반환
     */
    @AuraEnabled(Cacheable=true)
    public static OPP_SlipInfo__c getSlipInfoById(Id slipInfoId) {
        if (slipInfoId == null) return null;

        return [
                SELECT Id, Type__c, CreatedDate, Latest_is__c,
                        Form__c, Reinsured__c, Insured__c,
                        PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                        ENDEffectivedDate__c, Amendments__c, Prem100__c,
                        Location__c, TerritoryScope__c, GoverningLaw__c,
                        OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                        RICession__c, RIComm__c, OtherDeduction__c,
                        LimitofLiability__c, Deductible__c,
                        TermsConds__c, ExtensionClauses__c,
                        LossRecord__c, AddInfo__c,
                        Opportunity_lk__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ];
    }

    /**
    * @description
    * Placement Id 기준으로 현재 SlipInfo(current) 와 비교 대상 SlipInfo(compareTarget) 를 반환
    * - TransactionType = 'END' 인 경우 : Cedant Endorsement(Latest=true) 조회
    * - 그 외 : Cedant Closing(Latest=true) 우선, 없으면 Cedant Offer(Latest=true)
    * - compareTarget 비교 기준 :
    *   - END + Cedant Endorsement  : 이전 버전 Cedant Endorsement
    *   - Cedant Offer              : 이전 버전 Cedant Offer
    *   - Cedant Closing            : 최신 Cedant Offer(Latest=true)
    * @param placementId 조회 기준 Placement 레코드 Id
    * @return Map<String, OPP_SlipInfo__c> 'current', 'compareTarget' 키로 구성된 SlipInfo Map
    */
    @AuraEnabled(Cacheable=true)
    public static Map<String, OPP_SlipInfo__c> getSlipInfoByPlacementId(Id placementId) {

        if (placementId == null) return null;

        final String SELECT_FIELDS = 'Id, Type__c, CreatedDate, ' +
                'Form__c, Reinsured__c, Insured__c, ' +
                'PeriodFrom__c, PeriodTo__c, PolicyHolder__c, ' +
                'ENDEffectivedDate__c, Amendments__c, Prem100__c, ' +
                'Location__c, TerritoryScope__c, GoverningLaw__c, ' +
                'OccupancyBiz__c, CoveredRisk__c, Interest__c, ' +
                'TSI__c,' +
                'RICession__c, RIComm__c, OtherDeduction__c, ' +
                'LimitofLiability__c, Deductible__c, ' +
                'TermsConds__c, ExtensionClauses__c, ' +
                'LossRecord__c, AddInfo__c, ' +
                'Latest_is__c, ' +
                'Placement_lk__r.TransactionType__c, Placement_lk__r.LKRefNoh__c';

        Placement__c placement = [
                SELECT TransactionType__c
                FROM Placement__c
                WHERE Id = :placementId
                LIMIT 1
        ];

        String txType = String.isBlank(placement.TransactionType__c)
                ? ''
                : placement.TransactionType__c.trim().toUpperCase();

        OPP_SlipInfo__c current;

        if (txType == 'END') {
            // END: Cedant Endorsement(Latest=true)만 노출
            List<OPP_SlipInfo__c> latestEndList = Database.query(
                    'SELECT ' + SELECT_FIELDS +
                    ' FROM OPP_SlipInfo__c' +
                    ' WHERE Placement_lk__c = :placementId' +
                    ' AND Type__c = :TYPE_CEDANT_ENDORSEMENT' +
                    ' AND Latest_is__c = TRUE' +
                    ' ORDER BY CreatedDate DESC' +
                    ' LIMIT 1'
            );
            current = latestEndList.isEmpty() ? null : latestEndList[0];
        } else {
            // END 외: Cedant Closing(Latest=true) 우선, 없으면 Cedant Offer(Latest=true)
            List<OPP_SlipInfo__c> latestClosingList = Database.query(
                    'SELECT ' + SELECT_FIELDS +
                    ' FROM OPP_SlipInfo__c' +
                    ' WHERE Placement_lk__c = :placementId' +
                    ' AND Type__c = :TYPE_CEDANT_CLOSING' +
                    ' AND Latest_is__c = TRUE' +
                    ' ORDER BY CreatedDate DESC' +
                    ' LIMIT 1'
            );

            if (!latestClosingList.isEmpty()) {
                current = latestClosingList[0];
            } else {
                List<OPP_SlipInfo__c> latestOfferList = Database.query(
                        'SELECT ' + SELECT_FIELDS +
                        ' FROM OPP_SlipInfo__c' +
                        ' WHERE Placement_lk__c = :placementId' +
                        ' AND Type__c = :TYPE_CEDANT_OFFER' +
                        ' AND Latest_is__c = TRUE' +
                        ' ORDER BY CreatedDate DESC' +
                        ' LIMIT 1'
                );
                current = latestOfferList.isEmpty() ? null : latestOfferList[0];
            }
        }

        Map<String, OPP_SlipInfo__c> resultMap = new Map<String, OPP_SlipInfo__c>();
        resultMap.put('current', current);

        OPP_SlipInfo__c compareTarget;

        if (current != null) {
            if (txType == 'END' && current.Type__c == TYPE_CEDANT_ENDORSEMENT) {
                // END + Cedant Endorsement: 이전 버전 Cedant Endorsement와 비교
                List<OPP_SlipInfo__c> prevEndList = [
                        SELECT Id, Type__c,
                                Form__c, Reinsured__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                ENDEffectivedDate__c, Amendments__c, Prem100__c,
                                Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Placement_lk__c = :placementId
                        AND Type__c = :TYPE_CEDANT_ENDORSEMENT
                        AND CreatedDate < :current.CreatedDate
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
                compareTarget = prevEndList.isEmpty() ? null : prevEndList[0];
            } else if (current.Type__c == TYPE_CEDANT_OFFER) {
                // Cedant Offer: 이전 Cedant Offer와 비교
                List<OPP_SlipInfo__c> prevOfferList = [
                        SELECT Id, Type__c,
                                Form__c, Reinsured__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Placement_lk__c = :placementId
                        AND Type__c = :TYPE_CEDANT_OFFER
                        AND CreatedDate < :current.CreatedDate
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
                compareTarget = prevOfferList.isEmpty() ? null : prevOfferList[0];
            } else if (current.Type__c == TYPE_CEDANT_CLOSING) {
                // Cedant Closing: 최신 Cedant Offer(Latest=true)와 비교
                List<OPP_SlipInfo__c> latestOfferList = [
                        SELECT Id, Type__c,
                                Form__c, Reinsured__c, Insured__c,
                                PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                                Location__c, TerritoryScope__c, GoverningLaw__c,
                                OccupancyBiz__c, CoveredRisk__c, Interest__c, TSI__c,
                                RICession__c, RIComm__c, OtherDeduction__c,
                                LimitofLiability__c, Deductible__c,
                                TermsConds__c, ExtensionClauses__c,
                                LossRecord__c, AddInfo__c
                        FROM OPP_SlipInfo__c
                        WHERE Placement_lk__c = :placementId
                        AND Type__c = :TYPE_CEDANT_OFFER
                        AND Latest_is__c = TRUE
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ];
                compareTarget = latestOfferList.isEmpty() ? null : latestOfferList[0];
            }
        }

        resultMap.put('compareTarget', compareTarget);
        return resultMap;
    }

    /**
     * @description
     * Opportunity 기준으로 TSIByLocation(Type='Slip') 목록을 조회
     * - 조회 기준 SlipInfo 우선순위 : 최신 Cedant Closing → 가장 최근 SlipInfo
     * @param opportunityId 조회 기준 Opportunity 레코드 Id
     * @return List<OPP_TSIByLocation__c> TSIByLocation 레코드 목록 (없으면 빈 리스트)
     */
    @AuraEnabled(Cacheable=true)
    public static List<OPP_TSIByLocation__c> getTSIByOpportunity(Id opportunityId) {

        if (opportunityId == null) {
            return new List<OPP_TSIByLocation__c>();
        }

        OPP_SlipInfo__c targetSlip;

        // 1순위 : 최신 Cedant Closing
        List<OPP_SlipInfo__c> closingSlips = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c =: TYPE_CEDANT_CLOSING
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (!closingSlips.isEmpty()) {
            targetSlip = closingSlips[0];
        } else {
            // 2순위 : 가장 최근 SlipInfo
            List<OPP_SlipInfo__c> latestSlip = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            if (!latestSlip.isEmpty()) {
                targetSlip = latestSlip[0];
            }
        }

        if (targetSlip == null) {
            return new List<OPP_TSIByLocation__c>();
        }

        return [
                SELECT Id,
                        Name,
                        TSICurrency__c,
                        SlipTSI__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :targetSlip.Id
                AND Type__c = 'Slip'
                ORDER BY CreatedDate ASC
        ];
    }

    /**
     * @description
     * SlipInfo Id 기준으로 TSIByLocation(Type='Slip') 목록을 조회
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @return List<OPP_TSIByLocation__c> TSIByLocation 레코드 목록
     */
    @AuraEnabled(Cacheable=true)
    public static List<OPP_TSIByLocation__c> getTSIBySlipId(Id slipInfoId) {
        return [
                SELECT Id, TSICurrency__c, SlipTSI__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'Slip'
                ORDER BY CreatedDate
        ];
    }

    /**
     * @description
     * SlipInfo 레코드를 저장 (INSERT / UPDATE) 하고 레코드 Id 를 반환
     * - Id 가 있으면 UPDATE, 없으면 INSERT
     * - INSERT 시 contextType 에 따라 Opportunity 또는 Placement 에 연결
     * @param slipInfo 저장할 OPP_SlipInfo__c 레코드
     * @param parentId INSERT 시 연결할 부모 레코드 Id (Opportunity 또는 Placement)
     * @param contextType 컨텍스트 타입 ('OPPORTUNITY' 또는 'PLACEMENT')
     * @return Id 저장된 SlipInfo 레코드 Id
     */
    @AuraEnabled
    public static Id saveSlipInfo(OPP_SlipInfo__c slipInfo, Id parentId, String contextType) {
        if (slipInfo == null) {
            throw new AuraHandledException('SlipInfo data is required.');
        }

        System.debug('isUpdateable => ' +
                Schema.sObjectType.OPP_SlipInfo__c.fields.TerritoryScope__c.isUpdateable()
        );

        // UPDATE
        if (slipInfo.Id != null) {
            update slipInfo;
            return slipInfo.Id;
        }

        // INSERT
        if (parentId == null) {
            throw new AuraHandledException('Parent Id is required.');
        }

        if (contextType == 'OPPORTUNITY') {
            slipInfo.Opportunity_lk__c = parentId;
            slipInfo.Latest_is__c = true;
        }
        else if (contextType == 'PLACEMENT') {
            slipInfo.Placement_lk__c = parentId;
            slipInfo.Latest_is__c = true;
        }

        // New 생성(Opportunity/Placement)은 Slip RecordType으로 저장
        if (contextType == 'OPPORTUNITY' || contextType == 'PLACEMENT') {
            Id slipRecordTypeId = getSlipRecordTypeId();
            if (slipRecordTypeId != null) {
                slipInfo.RecordTypeId = slipRecordTypeId;
            }
        }

        insert slipInfo;

        return slipInfo.Id;

    }

    /**
     * @description
     * Cedant Offer Slip 을 기반으로 RI Offer SlipInfo 를 생성하여 Id 반환
     * - placementId 우선, 없으면 opportunityId 기준으로 Cedant Offer 조회
     * - sourceSlipInfoId 가 있으면 해당 SlipInfo 의 데이터를 복사, 없으면 Cedant Offer 데이터 복사
     * - RecordType 은 'Slip' 으로 설정
     * @param opportunityId 연결할 Opportunity 레코드 Id
     * @param sourceSlipInfoId 복사 원본 SlipInfo Id (없으면 null)
     * @param placementId 연결할 Placement 레코드 Id (없으면 null)
     * @return Id 생성된 RI Offer SlipInfo 레코드 Id
     */
    @AuraEnabled
    public static Id createRIOfferSlipInfo(Id opportunityId, Id sourceSlipInfoId, Id placementId) {

        List<OPP_SlipInfo__c> cedantOfferList;

        System.debug('Target Id => ' + placementId);

        // Placement 기준 Cedant Offer 조회
        if (placementId != null) {
            cedantOfferList = [
                    SELECT Id, Type__c, Form__c, Reinsured__c, Insured__c, PeriodFrom__c, PeriodTo__c,
                            PolicyHolder__c, Location__c, OccupancyBiz__c, CoveredRisk__c, TerritoryScope__c,
                            GoverningLaw__c, Interest__c, TSI__c, RICession__c,
                            RIComm__c, OtherDeduction__c, LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c, LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    AND Type__c = :TYPE_CEDANT_OFFER
                    LIMIT 1
            ];
        } else {
            // Opportunity 기준 Cedant Offer 조회
            cedantOfferList = [
                    SELECT Id, Type__c, Form__c, Reinsured__c, Insured__c, PeriodFrom__c, PeriodTo__c,
                            PolicyHolder__c, Location__c, OccupancyBiz__c, CoveredRisk__c, TerritoryScope__c,
                            GoverningLaw__c, Interest__c, TSI__c, RICession__c,
                            RIComm__c, OtherDeduction__c, LimitofLiability__c, Deductible__c,
                            TermsConds__c, ExtensionClauses__c, LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    AND Type__c = :TYPE_CEDANT_OFFER
                    LIMIT 1
            ];
        }

        if (cedantOfferList.isEmpty()) {
            throw new AuraHandledException('Cedant Offer Slip not found.');
        }

        OPP_SlipInfo__c source;
        // sourceSlipInfoId 가 있으면 해당 데이터 복사, 없으면 Cedant Offer 데이터 복사
        if (sourceSlipInfoId != null) {
            source = [
                    SELECT
                            Type__c, Form__c, Reinsured__c, Insured__c, PeriodFrom__c, PeriodTo__c, PolicyHolder__c,
                            Location__c,  OccupancyBiz__c, CoveredRisk__c, TerritoryScope__c, GoverningLaw__c,
                            Interest__c, TSI__c, RICession__c, RIComm__c,
                            OtherDeduction__c, LimitofLiability__c, Deductible__c, TermsConds__c, ExtensionClauses__c,
                            LossRecord__c, AddInfo__c
                    FROM OPP_SlipInfo__c
                    WHERE Id = :sourceSlipInfoId
                    LIMIT 1
            ];
        } else {
            source = cedantOfferList[0];
        }

        // RI Offer SlipInfo 생성 (source 데이터 복사)
        OPP_SlipInfo__c riSlip = new OPP_SlipInfo__c(
                Opportunity_lk__c   = placementId == null ? opportunityId : null,
                Placement_lk__c     = placementId,
                Type__c             = 'RI Offer',
                SlipInfo_lk__c      = source.Id,
                Latest_is__c        = true,

                Form__c             = source.Form__c,
                Reinsured__c        = source.Reinsured__c,
                Insured__c          = source.Insured__c,
                PeriodFrom__c       = source.PeriodFrom__c,
                PeriodTo__c         = source.PeriodTo__c,
                Location__c         = source.Location__c,
                TerritoryScope__c   = source.TerritoryScope__c,
                GoverningLaw__c     = source.GoverningLaw__c,
                OccupancyBiz__c     = source.OccupancyBiz__c,
                CoveredRisk__c      = source.CoveredRisk__c,
                Interest__c         = source.Interest__c,
                TSI__c              = source.TSI__c,
                RICession__c        = source.RICession__c,
                RIComm__c           = source.RIComm__c,
                OtherDeduction__c   = source.OtherDeduction__c,
                LimitofLiability__c = source.LimitofLiability__c,
                Deductible__c       = source.Deductible__c,
                TermsConds__c       = source.TermsConds__c,
                ExtensionClauses__c = source.ExtensionClauses__c,
                LossRecord__c       = source.LossRecord__c,
                AddInfo__c          = source.AddInfo__c
        );

        // Setting RecordTypeId (Slip)
        Id slipRecordTypeId = getSlipRecordTypeId();
        riSlip.RecordTypeId = slipRecordTypeId;

        insert riSlip;
        return riSlip.Id;
    }

    /**
     * @description
     * Placement 기준 RI Closing 생성 가능 여부를 검증하고 오류 메시지 목록을 반환
     * - Cedant Closing 존재 여부 검증
     * - Finalized Panel 1건 이상 존재 여부 검증
     * @param placementId 검증 기준 Placement 레코드 Id
     * @return List<String> 검증 실패 메시지 목록 (없으면 빈 리스트)
     */
    @AuraEnabled
    public static List<String> validateRIClosingByPlacement(Id placementId) {
        List<String> errors = new List<String>();

        // Placement 내 Cedant Closing 존재 여부
        List<OPP_SlipInfo__c> cedantClosingList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Placement_lk__c = :placementId
                AND Type__c = :TYPE_CEDANT_CLOSING
                LIMIT 1
        ];

        if (cedantClosingList.isEmpty()) {
            errors.add(System.Label.SLIP_MSG_GENERATE_RI_CLOSING);
        }

        // Placement 에 연결된 Finalized Panel 존재 여부
        List<OPP_Panel__c> finalizedPanelList = [
                SELECT Id
                FROM OPP_Panel__c
                WHERE Layer_md__r.Placement_lk__c = :placementId
                AND Finalize_is__c = TRUE
                LIMIT 1
        ];

        if (finalizedPanelList.isEmpty()) {
            errors.add(System.Label.SLIP_MSG_MISSING_FINALIZED_PANEL);
        }

        return errors;
    }

    /**
     * @description
     * Opportunity 기준 RI Closing 생성 가능 여부를 검증하고 오류 메시지 목록을 반환
     * - Cedant Closing 존재 여부
     * - Premium Currency 별 PremiumSchedule 존재 여부 (주석 처리)
     * - Opportunity 에 Finalized Panel 1건 이상 존재 여부
     * @param opportunityId 검증 기준 Opportunity 레코드 Id
     * @return List<String> 검증 실패 메시지 목록 (없으면 빈 리스트)
     */
    @AuraEnabled
    public static  List<String> validateRIClosing(Id opportunityId) {
        List<String> errors = new List<String>();

        // Cedant Closing 존재 여부 검증
        String cedantError = validateCedantClosing(opportunityId);
        if (cedantError != null) errors.add(cedantError);

        Set<Id> slipIds = getSlipIds(opportunityId);

        // Prem Currency 별 PremiumSchedule 존재 여부 검증
        /*
        String scheduleError = validatePremSchedule(opportunityId, slipIds);
        if (scheduleError != null) errors.add(scheduleError);*/

        // Prem Currency 별 Finalized Panel 존재 여부 검증
        String panelError = validateFinalizedPanel(opportunityId);
        if (panelError != null) errors.add(panelError);

        // TSI Currency 별 TSIByLocation 존재 여부 검증
        /*
        String tsiError = validateTSIByLocation(slipIds);
        if (tsiError != null) errors.add(tsiError);*/

        return errors;
    }

    /**
     * @description
     * Opportunity 에 Cedant Closing 이 존재하는지 검증
     * @param opportunityId 검증 기준 Opportunity 레코드 Id
     * @return String 없으면 오류 메시지, 있으면 null
     */
    private static String validateCedantClosing(Id opportunityId) {
        List<OPP_SlipInfo__c> cedantClosingList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c = :TYPE_CEDANT_CLOSING
                LIMIT 1
        ];

        return cedantClosingList.isEmpty() ? System.Label.SLIP_MSG_GENERATE_RI_CLOSING : null;
    }

    /**
     * @description
     * Placement 에 Cedant Endorsement 가 존재하는지 검증
     * @param placementId 검증 기준 Placement 레코드 Id
     * @return String 없으면 오류 메시지, 있으면 null
     */
    @AuraEnabled
    public static String validateRIEndPlacement(Id placementId) {

        // Placement 내 Cedant Endorsement 존재 여부
        List<OPP_SlipInfo__c> cedantENDList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Placement_lk__c = :placementId
                AND Type__c = 'Cedant Endorsement'
                LIMIT 1
        ];

        return cedantENDList.isEmpty() ? System.Label.PLA_MSG_VALIDATE_END : null;

    }

    /**
     * @description
     * 유효성 검증에 사용할 SlipInfo Id 를 수집
     * - 우선순위 : 최신 Cedant Closing(Latest=true) → 최신 Cedant Offer(Latest=true)
     * @param opportunityId 조회 기준 Opportunity 레코드 Id
     * @return Set<Id> SlipInfo Id Set (없으면 빈 Set)
     */
    private static Set<Id> getSlipIds(Id opportunityId) {
        // 1순위: 최신 Cedant Closing
        List<OPP_SlipInfo__c> closingList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c = :TYPE_CEDANT_CLOSING
                AND Latest_is__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (!closingList.isEmpty()) {
            return new Set<Id>{ closingList[0].Id };
        }

        // 2순위: 최신 Cedant Offer
        List<OPP_SlipInfo__c> offerList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c = :TYPE_CEDANT_OFFER
                AND Latest_is__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (!offerList.isEmpty()) {
            return new Set<Id>{ offerList[0].Id };
        }

        return new Set<Id>();
    }

    /**
     * @description
     * SlipInfo 에 연결된 TSIByLocation(Type='TSIByLocation') 의 PremiumCurrency 목록을 수집
     * @param slipIds 조회 기준 SlipInfo Id Set
     * @return Set<String> PremiumCurrency 코드 Set
     */
    private static Set<String> getPremCurrencies(Set<Id> slipIds) {
        List<OPP_TSIByLocation__c> tsiByLocationList = [
                SELECT Id, PremiumCurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c IN :slipIds
                AND Type__c = 'TSIByLocation'
        ];

        Set<String> premCurrencies = new Set<String>();
        for (OPP_TSIByLocation__c tsi : tsiByLocationList) {
            if (String.isNotBlank(tsi.PremiumCurrency__c)) {
                premCurrencies.add(tsi.PremiumCurrency__c);
            }
        }
        return premCurrencies;
    }

    /**
     * @description
     * validateRIClosing 에서 주석 처리
     * Premium Currency 별 PremiumSchedule(Type='Schedule') 존재 여부를 검증
     * - TSIByLocation 의 PremiumCurrency 기준으로 Schedule 이 존재하지 않는 Currency 추출
     * @param opportunityId 검증 기준 Opportunity 레코드 Id
     * @param slipIds 검증에 사용할 SlipInfo Id Set
     * @return String 누락된 Currency가 있으면 오류 메시지, 없으면 null
     */
    /*private static String validatePremSchedule(Id opportunityId, Set<Id> slipIds) {
        if (slipIds.isEmpty()) return null;

        Set<String> premCurrencies = getPremCurrencies(slipIds);
        if (premCurrencies.isEmpty()) return null;

        List<OPP_PremiumSchedule__c> scheduleList = [
                SELECT Id, Prem_Currency__c
                FROM OPP_PremiumSchedule__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c = 'Schedule'
                AND Prem_Currency__c IN :premCurrencies
        ];

        Set<String> scheduleCurrencies = new Set<String>();
        for (OPP_PremiumSchedule__c ps : scheduleList) {
            scheduleCurrencies.add(ps.Prem_Currency__c);
        }

        // Schedule 이 없는 Currency 추출
        Set<String> missingCurrencies = new Set<String>(premCurrencies);
        missingCurrencies.removeAll(scheduleCurrencies);

        if (!missingCurrencies.isEmpty()) {
            return String.format(
                    System.Label.SLIP_MSG_MISSING_PREM_SCHEDULE,
                    new List<Object>{ String.join(new List<String>(missingCurrencies), ', ') }
            );
        }
        return null;
    }*/

    /**
     * @description
     * Opportunity 에 Finalized Panel 이 1건 이상 존재하는지 검증
     * @param opportunityId 검증 기준 Opportunity 레코드 Id
     * @return String Finalized Panel 이 없으면 오류 메시지, 있으면 null
     */
    private static String validateFinalizedPanel(Id opportunityId) {
        List<OPP_Panel__c> finalizedPanelList = [
                SELECT Id
                FROM OPP_Panel__c
                WHERE Layer_md__r.Opportunity_md__c = :opportunityId
                AND Finalize_is__c = TRUE
                LIMIT 1
        ];

        return finalizedPanelList.isEmpty() ? System.Label.SLIP_MSG_MISSING_FINALIZED_PANEL : null;
    }

    /**
     * @description
     * validateRIClosing 에서 주석 처리
     * TSI Currency 별 TSIByLocation(Type='TSIByLocation') 존재 여부를 검증
     * - Slip(Type='Slip') 의 TSICurrency 기준으로 TSIByLocation 이 없는 Currency 추출
     * @param slipIds 검증에 사용할 SlipInfo Id Set
     * @return String 누락된 Currency가 있으면 오류 메시지, 없으면 null
     */
   /* private static String validateTSIByLocation(Set<Id> slipIds) {
        if (slipIds.isEmpty()) return null;

        List<OPP_TSIByLocation__c> tsiSlipList = [
                SELECT Id, TSICurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c IN :slipIds
                AND Type__c = 'Slip'
        ];

        Set<String> tsiSlipCurrencies = new Set<String>();
        for (OPP_TSIByLocation__c tsi : tsiSlipList) {
            if (String.isNotBlank(tsi.TSICurrency__c)) {
                tsiSlipCurrencies.add(tsi.TSICurrency__c);
            }
        }

        if (tsiSlipCurrencies.isEmpty()) return null;

        List<OPP_TSIByLocation__c> matchingList = [
                SELECT Id, TSICurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c IN :slipIds
                AND Type__c = 'TSIByLocation'
                AND TSICurrency__c IN :tsiSlipCurrencies
        ];

        Set<String> matchedCurrencies = new Set<String>();
        for (OPP_TSIByLocation__c tsi : matchingList) {
            matchedCurrencies.add(tsi.TSICurrency__c);
        }

        // TSIByLocation 이 없는 Currency 추출
        Set<String> unmatchedCurrencies = new Set<String>(tsiSlipCurrencies);
        unmatchedCurrencies.removeAll(matchedCurrencies);

        if (!unmatchedCurrencies.isEmpty()) {
            return String.format(
                    System.Label.SLIP_MSG_MISSING_TSI_BY_LOCATION,
                    new List<Object>{ String.join(new List<String>(unmatchedCurrencies), ', ') }
            );
        }
        return null;
    }*/

    /**
     * @description
     * TSIByLocation(Type='Slip') 레코드를 저장(INSERT/UPDATE/DELETE) 하고 TSI 정합성 검증 결과를 반환
     * - 삭제 → 등록 → 수정 순서로 처리
     * - 처리 완료 후 재계산 필요 이벤트 발행
     * @param slipInfoId 대상 SlipInfo 레코드 Id
     * @param opportunityId 대상 Opportunity 레코드 Id
     * @param placementId 대상 Placement 레코드 Id
     * @param insertList 등록할 TSIByLocation 레코드 목록
     * @param updateList 수정할 TSIByLocation 레코드 목록
     * @param deleteIds 삭제할 TSIByLocation 레코드 Id 목록
     * @return Map<String, Boolean> 'mismatchSlip': Slip TSI 불일치 여부, 'mismatchLocation': Location TSI 불일치 여부
     */
    @AuraEnabled
    public static Map<String, Boolean>  saveTSIRecords(Id slipInfoId, Id opportunityId, Id placementId,
            List<OPP_TSIByLocation__c> insertList, List<OPP_TSIByLocation__c> updateList, List<Id> deleteIds) {

        Id targetSlipId = resolveSlipId(slipInfoId, opportunityId, placementId);
        Id recordId = (placementId==null?opportunityId:placementId);

        if (targetSlipId == null) {
            return new Map<String, Boolean>{'mismatchSlip' => false, 'mismatchLocation' => false};
        }

        if (deleteIds != null && !deleteIds.isEmpty()) {
            delete [SELECT Id FROM OPP_TSIByLocation__c WHERE Id IN :deleteIds];
        }

        if (insertList != null && !insertList.isEmpty()) {
            for (OPP_TSIByLocation__c rec : insertList) {
                rec.SlipInfo_md__c = targetSlipId;
                rec.Type__c = 'Slip';
            }
            insert insertList;
        }

        if (updateList != null && !updateList.isEmpty()) {
            update updateList;
        }
        updateRecalculateRequired(targetSlipId);
        publishRecordChangedEvent(recordId, 'TSIByLocation', 'TSI_CHANGED');

        return validateTSITotal(targetSlipId);
    }

    /**
     * @description
     * SlipInfo 의 TSI__c 텍스트, Slip TSI 합계, TSIByLocation 합계 간 정합성을 검증
     * - mismatchSlip     : TSI 텍스트 vs Slip(Type='Slip') 합계 불일치 여부
     * - mismatchLocation : Slip 합계 vs TSIByLocation(Type='TSIByLocation') 합계 불일치 여부
     * @param slipId 검증 기준 OPP_SlipInfo__c 레코드 Id
     * @return Map<String, Boolean> 'mismatchSlip', 'mismatchLocation' 불일치 여부
     */
    @AuraEnabled
    public static Map<String, Boolean> validateTSITotal(Id slipId) {
        if (slipId == null) {
            return new Map<String, Boolean>{'mismatchSlip' => false, 'mismatchLocation' => false};
        }

        OPP_SlipInfo__c slip = [
                SELECT Id, TSI__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipId
                LIMIT 1
        ];

        Map<String,Decimal> tsiTextMap = parseTSIText(slip.TSI__c);

        Map<String,Decimal> slipMap = getCurrencySum(slipId,'Slip');
        Map<String,Decimal> locationMap = getCurrencySum(slipId,'TSIByLocation');

        /*Boolean mismatchSlip = compareCurrencyMaps(tsiTextMap, slipMap);

        Boolean mismatchLocation = compareCurrencyMaps(slipMap, locationMap);*/

        Boolean mismatchSlip = compareCurrencyMaps(tsiTextMap, slipMap, 'Slip');
        Boolean mismatchLocation = compareCurrencyMaps(slipMap, locationMap, 'Location');

        System.debug('===== VALIDATION =====');
        System.debug('TSI Text Map: ' + tsiTextMap);
        System.debug('Slip Map: ' + slipMap);
        System.debug('Location Map: ' + locationMap);

        System.debug('mismatchSlip: ' + mismatchSlip);
        System.debug('mismatchLocation: ' + mismatchLocation);

        return new Map<String, Boolean>{
                'mismatchSlip' => mismatchSlip,
                'mismatchLocation' => mismatchLocation
        };
    }

    /**
     * @description
     * SlipInfo 에 연결된 TSIByLocation 의 Currency별 합계를 집계하여 반환
     * - Type='Slip'         : SlipTSI__c 기준 집계
     * - Type='TSIByLocation': InsuredAmount__c 기준 집계
     * @param slipId 집계 기준 OPP_SlipInfo__c 레코드 Id
     * @param typeValue 집계 대상 Type__c 값 ('Slip' 또는 'TSIByLocation')
     * @return Map<String, Decimal> Currency 코드 → 합계 금액 Map
     */
    private static Map<String,Decimal> getCurrencySum(Id slipId, String typeValue) {
        Map<String,Decimal> result = new Map<String,Decimal>();

        String amountField = typeValue == 'Slip' ? 'SlipTSI__c' : 'InsuredAmount__c';
        String query = 'SELECT TSICurrency__c currency,' +
                        ' SUM(' + amountField + ') total ' +
                        'FROM OPP_TSIByLocation__c ' +
                        'WHERE SlipInfo_md__c = :slipId ' +
                        'AND Type__c = :typeValue ' +
                        'GROUP BY TSICurrency__c';

        for (AggregateResult ar : Database.query(query)) {
            result.put(
                    (String) ar.get('currency'),
                    (Decimal) ar.get('total')
            );
        }

        return result;
    }

    /**
     * @description
     * 두 Currency별 합계 Map 을 비교하여 불일치 여부를 반환
     * - targetMap 이 비어있으면 false 반환
     * - targetMap 의 각 Currency에 대해 textMap 과 정수 단위(longValue) 로 비교
     * @param textMap 비교 기준 Map (TSI 텍스트 또는 Slip 합계)
     * @param targetMap 비교 대상 Map (Slip 합계 또는 Location 합계)
     * @param label 디버그 로그용 레이블
     * @return Boolean 불일치 항목이 있으면 true, 모두 일치하면 false
     */
    private static Boolean compareCurrencyMaps(Map<String,Decimal> textMap, Map<String,Decimal> targetMap, String label) {

        System.debug('=== compareCurrencyMaps: ' + label + ' ===');

        if(targetMap.isEmpty()) {
            return false;
        }

        for (String currencyStr : targetMap.keySet()) {
            Decimal textValue = textMap.containsKey(currencyStr) ? textMap.get(currencyStr) : 0;
            Decimal targetValue = targetMap.get(currencyStr) != null ? targetMap.get(currencyStr) : 0;

            Long textLong = textValue.longValue();
            Long targetLong = targetValue.longValue();

            System.debug(currencyStr + ' Text=' + textLong + ' Target=' + targetLong);

            if (textLong != targetLong) {
                return true;
            }
        }
        return false;
    }

    /**
    * @description
    * SlipInfo 의 TSI__c 텍스트(줄바꿈 또는 '/' 구분)를 파싱하여 Currency별 합계 Map 으로 반환
    * - 앞 3자리 : Currency 코드, 나머지 : 금액
    * - 동일 Currency가 여러 줄인 경우 합산
    * @param tsiText SlipInfo.TSI__c 필드 텍스트
    * @return Map<String, Decimal> Currency 코드 → 합계 금액 Map
    */
    private static Map<String,Decimal> parseTSIText(String tsiText) {

        Map<String,Decimal> result = new Map<String,Decimal>();

        if (String.isBlank(tsiText)) {
            return result;
        }

        String normalized = tsiText.replace('\n','/');

        for (String part : normalized.split('/')) {

            part = part.trim();

            if (part.length() < 4) {
                continue;
            }

            String currencyStr = part.substring(0,3);
            String amountStr = part.substring(3).replace(',','').trim();

            try {
                Decimal amount = Decimal.valueOf(amountStr);

                if (!result.containsKey(currencyStr)) {
                    result.put(currencyStr,0);
                }

                result.put(currencyStr, result.get(currencyStr) + amount);

            } catch (Exception e) {
                System.debug('TSI Parse Error: ' + part);
            }
        }

        return result;
    }

    /**
     * @description
     * slipInfoId / opportunityId / placementId 우선순위로 사용할 SlipInfo Id 를 결정하여 반환
     * - slipInfoId 우선, 없으면 placementId → opportunityId 기준 최신 SlipInfo 조회
     * @param slipInfoId SlipInfo 레코드 Id (없으면 null)
     * @param opportunityId Opportunity 레코드 Id (없으면 null)
     * @param placementId Placement 레코드 Id (없으면 null)
     * @return Id 결정된 SlipInfo 레코드 Id, 없으면 null
     */
    private static Id resolveSlipId(Id slipInfoId, Id opportunityId, Id placementId) {

        if (slipInfoId != null) {
            return slipInfoId;
        }

        if (placementId != null) {
            List<OPP_SlipInfo__c> slips = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            if (!slips.isEmpty()) {
                return slips[0].Id;
            }
        }

        if (opportunityId != null) {
            List<OPP_SlipInfo__c> slips = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            if (!slips.isEmpty()) {
                return slips[0].Id;
            }
        }

        return null;
    }

    /**
     * @description
     * SlipInfo 에 연결된 PremiumSchedule(Type='Slip') 목록을 조회
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @return List<OPP_PremiumSchedule__c> PremiumSchedule 레코드 목록 (없으면 빈 리스트)
     */
    @AuraEnabled(Cacheable=true)
    public static List<OPP_PremiumSchedule__c> getPremiumSchedule(Id slipInfoId) {
        if (slipInfoId == null) return new List<OPP_PremiumSchedule__c>();

        return [
                SELECT Id,
                        Prem_Currency__c,
                        SlipGrossPremDP__c,
                        SlipGrossPrem__c,
                        Type__c
                FROM OPP_PremiumSchedule__c
                WHERE SlipInfo_lk__c = :slipInfoId
                AND Type__c = 'Slip'
                ORDER BY CreatedDate ASC
        ];
    }

    /**
     * @description
     * Opportunity 기준으로 PremiumSchedule(Type='Slip') 목록을 조회
     * - SlipInfo 우선순위 : Cedant Closing → Cedant Offer
     * @param opportunityId 조회 기준 Opportunity 레코드 Id
     * @return List<OPP_PremiumSchedule__c> PremiumSchedule 레코드 목록 (없으면 빈 리스트)
     */
    @AuraEnabled(Cacheable=true)
    public static List<OPP_PremiumSchedule__c> getPremiumScheduleByOpp(Id opportunityId) {
        if (opportunityId == null) return new List<OPP_PremiumSchedule__c>();

        // Closing 우선
        List<OPP_SlipInfo__c> closingList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c = :TYPE_CEDANT_CLOSING
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        Id slipId;

        if (!closingList.isEmpty()) {
            slipId = closingList[0].Id;
        } else {
            List<OPP_SlipInfo__c> offerList = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Opportunity_lk__c = :opportunityId
                    AND Type__c = :TYPE_CEDANT_OFFER
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            if (!offerList.isEmpty()) {
                slipId = offerList[0].Id;
            }
        }

        if (slipId == null) return new List<OPP_PremiumSchedule__c>();

        return [
                SELECT Id,
                        Prem_Currency__c,
                        SlipGrossPremDP__c,
                        SlipGrossPrem__c,
                        Type__c
                FROM OPP_PremiumSchedule__c
                WHERE SlipInfo_lk__c = :slipId
                AND Type__c = 'Slip'
                ORDER BY CreatedDate ASC
        ];
    }

    /**
     * @description
     * Placement 기준으로 PremiumSchedule(Type='Slip', Placement_lk__c != null) 목록을 조회
     * - SlipInfo 우선순위 : Cedant Closing → Cedant Offer
     * @param placementId 조회 기준 Placement 레코드 Id
     * @return List<OPP_PremiumSchedule__c> PremiumSchedule 레코드 목록 (없으면 빈 리스트)
     */
    @AuraEnabled(Cacheable=true)
    public static List<OPP_PremiumSchedule__c> getPremiumScheduleByPlacement(Id placementId) {
        if (placementId == null) return new List<OPP_PremiumSchedule__c>();

        // Placement → SlipInfo 조회
        List<OPP_SlipInfo__c> closingList = [
                SELECT Id
                FROM OPP_SlipInfo__c
                WHERE Placement_lk__c = :placementId
                AND Type__c = :TYPE_CEDANT_CLOSING
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        Id slipId;

        if (!closingList.isEmpty()) {
            slipId = closingList[0].Id;
        } else {
            List<OPP_SlipInfo__c> offerList = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    AND Type__c = :TYPE_CEDANT_OFFER
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            if (!offerList.isEmpty()) {
                slipId = offerList[0].Id;
            }
        }

        if (slipId == null) return new List<OPP_PremiumSchedule__c>();

        return [
                SELECT Id,
                        Prem_Currency__c,
                        SlipGrossPremDP__c,
                        SlipGrossPrem__c,
                        Type__c
                FROM OPP_PremiumSchedule__c
                WHERE SlipInfo_lk__c = :slipId
                AND Placement_lk__c != NULL  // Placement 페이지는 이 조건 추가
                AND Type__c = 'Slip'
                ORDER BY CreatedDate ASC
        ];
    }

    /**
     * @description
     * PremiumSchedule 레코드를 저장(INSERT/UPDATE/DELETE) 하고 최신 목록을 반환
     * - 등록 → 수정 → 삭제 순서로 처리
     * - 처리 완료 후 재계산 필요 이벤트 발행
     * @param slipInfoId 대상 SlipInfo 레코드 Id
     * @param insertList 등록할 PremiumSchedule 레코드 목록
     * @param updateList 수정할 PremiumSchedule 레코드 목록
     * @param deleteIds 삭제할 PremiumSchedule 레코드 Id 목록
     * @return List<OPP_PremiumSchedule__c> 저장 후 최신 PremiumSchedule 목록
     */
    @AuraEnabled
    public static List<OPP_PremiumSchedule__c> savePremiumSchedule(Id slipInfoId, List<OPP_PremiumSchedule__c> insertList, List<OPP_PremiumSchedule__c> updateList, List<Id> deleteIds) {
        System.debug('### insertList size: ' + insertList.size());
        System.debug('### insertList data: ' + JSON.serialize(insertList));

        if (!insertList.isEmpty()) {
            insert insertList;
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }

        if (!deleteIds.isEmpty()) {
            delete [SELECT Id FROM OPP_PremiumSchedule__c WHERE Id IN :deleteIds];
        }
        updateRecalculateRequired(slipInfoId);

        if (slipInfoId == null) {
            return new List<OPP_PremiumSchedule__c>();
        }

        return [
                SELECT Id,
                        Prem_Currency__c,
                        SlipGrossPremDP__c,
                        SlipGrossPrem__c,
                        Type__c
                FROM OPP_PremiumSchedule__c
                WHERE SlipInfo_lk__c = :slipInfoId
                AND Type__c = 'Slip'
                ORDER BY CreatedDate ASC
        ];
    }

    /**
     * @description
     * SlipInfo 에 연결된 TSIByLocation(Type='Slip') 목록을 조회
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @return List<OPP_TSIByLocation__c> TSIByLocation 레코드 목록
     */
    @AuraEnabled(Cacheable=true)
    public static List<OPP_TSIByLocation__c> getSlipTSI(Id slipInfoId) {
        return [
                SELECT Id,
                        TSICurrency__c,
                        SlipTSI__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'Slip'
                ORDER BY CreatedDate
        ];
    }

    /**
     * @description
     * Opportunity 기준으로 RI Closing 생성 Flow(LK_AUT_Slip_RIClosingCreate) 를 실행
     * @param opportunityId 대상 Opportunity 레코드 Id
     */
    @AuraEnabled
    public static void runRIClosingFlow(Id opportunityId) {
        System.debug('RUN Flow!! ');

        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id is required.');
        }

        Map<String, Object> inputs = new Map<String, Object>{
                'v_InOpportunityId' => opportunityId
        };

        Flow.Interview flowInterview = Flow.Interview.createInterview('LK_AUT_Slip_RIClosingCreate', inputs);

        flowInterview.start();
    }

    /**
     * @description
     * Placement 기준으로 RI Closing 생성 Flow(LK_AUT_Slip_Placement_RIClosingCreate) 를 실행
     * @param placementId 대상 Placement 레코드 Id
     */
    @AuraEnabled
    public static void runRIClosingFlowByPlacement (Id placementId) {
        System.debug('RUN Flow!! ');

        if (placementId == null) {
            throw new AuraHandledException('Placement Id is required.');
        }

        Map<String, Object> inputs = new Map<String, Object>{
                'v_InPlacementId' => placementId
        };

        Flow.Interview flowInterview = Flow.Interview.createInterview('LK_AUT_Slip_Placement_RIClosingCreate', inputs);

        flowInterview.start();
    }

    /**
     * @description
     * Placement 기준으로 RI Endorsement(END) 생성 Flow(LK_AUT_Placement_END_RISlipCreate) 를 실행
     * @param placementId 대상 Placement 레코드 Id
     */
    @AuraEnabled
    public static void runRIEndFlowByPlacement(Id placementId) {
        System.debug('RUN END Flow!! ');

        if (placementId == null) {
            throw new AuraHandledException('Placement Id is required.');
        }

        Map<String, Object> inputs = new Map<String, Object>{
            'v_InPlacementId' => placementId
        };

        Flow.Interview flowInterview = Flow.Interview.createInterview('LK_AUT_Placement_END_RISlipCreate', inputs);

        flowInterview.start();
    }

    /**
     * @description TerritoryScope__c 필드의 Picklist 옵션 목록 반환 (None 포함)
     * @return List<COM_Option> Picklist 옵션 목록
     */
   @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getTerritoryOptions() {
       return COM_Util.makePickListOptions('OPP_SlipInfo__c', 'TerritoryScope__c', false);
    }

    /**
     * @description GoverningLaw__c 필드의 Picklist 옵션 목록 반환 (None 포함)
     * @return List<COM_Option> Picklist 옵션 목록
     */
    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getGoverningLawOptions() {
        return COM_Util.makePickListOptions('OPP_SlipInfo__c', 'GoverningLaw__c', false);
    }

    /**
     * @description
     * Placement 레코드의 TransactionType__c 를 조회하여 반환
     * @param recordId 조회 기준 Placement 레코드 Id
     * @return String Placement 의 TransactionType__c 값
     */
    @AuraEnabled(Cacheable=true)
    public static String getTransactionType(Id recordId) {

        if(recordId == null) return null;

        Placement__c placement = [
                SELECT TransactionType__c
                FROM Placement__c
                WHERE Id = :recordId
                LIMIT 1
        ];
        return placement.TransactionType__c;
    }

    /**
     * @description
     * Opportunity 또는 Placement 기준으로 SOA 타입의 PremiumSchedule 존재 여부를 반환
     * - PaymentType__c = 'SOA', Type__c = 'Schedule' 조건
     * @param opportunityId 조회 기준 Opportunity 레코드 Id (없으면 null)
     * @param placementId 조회 기준 Placement 레코드 Id (없으면 null)
     * @return Boolean SOA Schedule 이 존재하면 true, 없으면 false
     */
    @AuraEnabled(Cacheable=true)
    public static Boolean hasSoaSchedule(Id opportunityId, Id placementId) {
        if (opportunityId == null && placementId == null) {
            return false;
        }

        Integer cnt;

        if (opportunityId != null && placementId != null) {
            cnt = [
                    SELECT COUNT()
                    FROM OPP_PremiumSchedule__c
                    WHERE Type__c = 'Schedule'
                    AND PaymentType__c = 'SOA'
                    AND (Opportunity_lk__c = :opportunityId OR Placement_lk__c = :placementId)
            ];
        } else if (opportunityId != null) {
            cnt = [
                    SELECT COUNT()
                    FROM OPP_PremiumSchedule__c
                    WHERE Type__c = 'Schedule'
                    AND PaymentType__c = 'SOA'
                    AND Opportunity_lk__c = :opportunityId
            ];
        } else {
            cnt = [
                    SELECT COUNT()
                    FROM OPP_PremiumSchedule__c
                    WHERE Type__c = 'Schedule'
                    AND PaymentType__c = 'SOA'
                    AND Placement_lk__c = :placementId
            ];
        }

        return cnt > 0;
    }

    /**
     * @description
     * SlipInfo 에 연결된 TSIByLocation(Type='TSIByLocation') 을 TSI Currency 기준으로 조회
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @param tsiCurrencies 조회할 TSI Currency 코드 목록
     * @return List<OPP_TSIByLocation__c> TSIByLocation 레코드 목록 (없으면 빈 리스트)
     */
    private static List<OPP_TSIByLocation__c> getTSIByLocationRecords(Id slipInfoId, List<String> tsiCurrencies) {
        if (slipInfoId == null || tsiCurrencies == null || tsiCurrencies.isEmpty()) {
            return new List<OPP_TSIByLocation__c>();
        }

        return [
                SELECT Id, TSICurrency__c, PremiumCurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND TSICurrency__c IN :tsiCurrencies
                AND Type__c = 'TSIByLocation'
        ];
    }

    /**
     * @description
     * Placement 또는 Opportunity 에 연결된 Layer → Panel 목록을 Currency 기준으로 조회
     * @param placementId 조회 기준 Placement 레코드 Id (없으면 null)
     * @param opportunityId 조회 기준 Opportunity 레코드 Id (없으면 null)
     * @param premCurrencies 조회할 Premium Currency 코드 목록
     * @return List<OPP_Panel__c> 조건에 해당하는 Panel 레코드 목록
     */
    private static List<OPP_Panel__c> getPanels (Id placementId, Id opportunityId, List<String> premCurrencies) {
        if (premCurrencies == null || premCurrencies.isEmpty()) {
            return new List<OPP_Panel__c>();
        }

        List<String> conditions = new List<String>();

        if (placementId != null) {
            conditions.add('Placement_lk__c = :placementId');
        }

        if (opportunityId != null) {
            conditions.add('Opportunity_md__c = :opportunityId');
        }

        if (conditions.isEmpty()) {
            return new List<OPP_Panel__c>();
        }

        String layerQuery = 'SELECT Id FROM OPP_Layer__c WHERE ' + String.join(conditions, ' OR ');

        System.debug('### FINAL LAYER SOQL: ' + layerQuery);

        List<OPP_Layer__c> layers = Database.query(layerQuery);

        if (layers.isEmpty()) {
            return new List<OPP_Panel__c>();
        }

        Set<Id> layerIds = new Set<Id>();
        for (OPP_Layer__c l : layers) {
            layerIds.add(l.Id);
        }

        List<OPP_Panel__c> panels = [
                SELECT Id, Currency__c, Layer_md__c
                FROM OPP_Panel__c
                WHERE Layer_md__c IN :layerIds
                AND Currency__c IN :premCurrencies
        ];

        return panels;
    }

    /**
     * @description
     * 특정 Currency의 Panel 이 존재하는지 여부를 반환
     * @param placementId 조회 기준 Placement 레코드 Id
     * @param opportunityId 조회 기준 Opportunity 레코드 Id
     * @param premCurrencies 조회할 Premium Currency 코드 목록
     * @return Boolean Panel 이 존재하면 true, 없으면 false
     */
    @AuraEnabled
    public static Boolean checkPanels(Id placementId, Id opportunityId, List<String> premCurrencies) {
        List<OPP_Panel__c> panels = getPanels(placementId, opportunityId, premCurrencies);

        return !panels.isEmpty();
    }

    /**
     * @description
     * 특정 Currency의 Panel 을 삭제
     * @param placementId 조회 기준 Placement 레코드 Id
     * @param opportunityId 조회 기준 Opportunity 레코드 Id
     * @param premCurrencies 삭제할 Premium Currency 코드 목록
     */
    @AuraEnabled
    public static void deletePanels(Id placementId, Id opportunityId, List<String> premCurrencies) {
        List<OPP_Panel__c> panels = getPanels(placementId, opportunityId, premCurrencies);

        if (!panels.isEmpty()) {
            delete panels;
        }
    }

    /**
     * @description
     * TSI Currency 기준으로 TSIByLocation(Type='TSIByLocation') 및 연관 Panel 을 삭제
     * - TSIByLocation 의 PremiumCurrency 로 Panel 을 조회하여 삭제
     * - doDelete = false : Panel 존재 여부만 반환하고 실제 삭제는 미수행
     * - doDelete = true : Panel 및 TSIByLocation 실제 삭제 수행
     * @param placementId 대상 Placement 레코드 Id
     * @param opportunityId 대상 Opportunity 레코드 Id
     * @param slipInfoId 대상 SlipInfo 레코드 Id
     * @param tsiCurrencies 삭제 기준 TSI Currency 코드 목록
     * @param doDelete true: 실제 삭제 수행, false: Panel 존재 여부만 반환
     * @return Boolean 연관 Panel 이 존재하면 true, 없으면 false
     */
    @AuraEnabled
    public static Boolean deletePanelsAndTSIByCurrency(Id placementId, Id opportunityId, Id slipInfoId, List<String> tsiCurrencies, Boolean doDelete) {
        System.debug('### [START] deletePanelsAndTSIByCurrency');
        System.debug('### tsiCurrencies: ' + tsiCurrencies);

        // TSI Currency 로 TSIByLocation(Type=TSIByLocation) 조회
        List<OPP_TSIByLocation__c> tsiByLocationList = getTSIByLocationRecords(slipInfoId, tsiCurrencies);

        if (tsiByLocationList.isEmpty()) {
            System.debug('### No TSIByLocation records found');
            return false;
        }

        // TSIByLocation 에서 Prem Currency 추출
        Set<String> premCurrencySet = new Set<String>();
        for (OPP_TSIByLocation__c tsi : tsiByLocationList) {
            if (String.isNotBlank(tsi.PremiumCurrency__c)) {
                premCurrencySet.add(tsi.PremiumCurrency__c);
            }
        }

        System.debug('### Extracted Prem Currencies: ' + premCurrencySet);

        // Prem Currency 기준으로 Panel 조회
        List<OPP_Panel__c> panels = new List<OPP_Panel__c>();
        if (!premCurrencySet.isEmpty()) {
            panels = getPanels(placementId, opportunityId, new List<String>(premCurrencySet));
        }

        // Panel 존재 여부 반환 (doDelete = false 인 경우 체크만)
        Boolean hasPanels = !panels.isEmpty();

        if (doDelete) {
            // Panel 삭제
            if (!panels.isEmpty()) {
                System.debug('### Deleting panels: ' + panels.size());
                delete panels;
            }

            // TSIByLocation(Type=TSIByLocation) 삭제
            delete tsiByLocationList;
        }

        return hasPanels;
    }

    /**
     * @description
     * Premium Currency 기준으로 Panel 및 PremiumSchedule(Type='Schedule') 을 삭제
     * - doDelete = false : 관련 데이터 존재 여부만 반환하고 실제 삭제는 미수행
     * - doDelete = true : Panel 및 PremiumSchedule 실제 삭제 수행
     * - PremiumSchedule 삭제 기준 : opportunityId → placementId → slipInfoId 순서
     * @param placementId 대상 Placement 레코드 Id
     * @param opportunityId 대상 Opportunity 레코드 Id
     * @param slipInfoId 대상 SlipInfo 레코드 Id
     * @param premCurrencies 삭제 기준 Premium Currency 코드 목록
     * @param doDelete true: 실제 삭제 수행, false: 관련 데이터 존재 여부만 반환
     * @return Boolean 연관 Panel 또는 PremiumSchedule 이 존재하면 true, 없으면 false
     */
    @AuraEnabled
    public static Boolean deletePanelsAndPremiumByCurrency(Id placementId, Id opportunityId, Id slipInfoId, List<String> premCurrencies, Boolean doDelete) {
        if (premCurrencies == null || premCurrencies.isEmpty()) {
            return false;
        }

        List<String> normalizedCurrencies = new List<String>();
        for (String currencyStr : premCurrencies) {
            if (String.isNotBlank(currencyStr)) {
                normalizedCurrencies.add(currencyStr);
            }
        }

        if (normalizedCurrencies.isEmpty()) {
            return false;
        }

        List<OPP_Panel__c> panels = getPanels(placementId, opportunityId, normalizedCurrencies);

        List<OPP_PremiumSchedule__c> schedules = new List<OPP_PremiumSchedule__c>();

        // validatePremSchedule 처럼 컨텍스트 기준으로 삭제 대상 결정
        if (opportunityId != null) {
            schedules = [
                    SELECT Id
                    FROM OPP_PremiumSchedule__c
                    WHERE Opportunity_lk__c = :opportunityId
                    AND Type__c = 'Schedule'
                    AND Prem_Currency__c IN :normalizedCurrencies
            ];
        } else if (placementId != null) {
            schedules = [
                    SELECT Id
                    FROM OPP_PremiumSchedule__c
                    WHERE Placement_lk__c = :placementId
                    AND Type__c = 'Schedule'
                    AND Prem_Currency__c IN :normalizedCurrencies
            ];
        } else if (slipInfoId != null) {
            schedules = [
                    SELECT Id
                    FROM OPP_PremiumSchedule__c
                    WHERE SlipInfo_lk__c = :slipInfoId
                    AND Type__c = 'Schedule'
                    AND Prem_Currency__c IN :normalizedCurrencies
            ];
        }

        Boolean hasRelatedData = !panels.isEmpty() || !schedules.isEmpty();

        if (doDelete == true) {
            if (!panels.isEmpty()) {
                delete panels;
            }

            if (!schedules.isEmpty()) {
                delete schedules;
            }
        }

        return hasRelatedData;
    }

    /**
     * @description
     * SlipInfo 에 연결된 Opportunity 또는 Placement 에 재계산 필요 이벤트를 발행
     * @param slipInfoId 대상 OPP_SlipInfo__c 레코드 Id
     */
    public static void updateRecalculateRequired(Id slipInfoId) {
        if (slipInfoId == null) return;

        List<OPP_SlipInfo__c> slipInfos = [
                SELECT Opportunity_lk__c, Placement_lk__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ];
        if (!slipInfos.isEmpty()) {
            if (slipInfos[0].Opportunity_lk__c != null) {
                publishRecordChangedEvent(slipInfos[0].Opportunity_lk__c, 'Opportunity', 'NEED_RECALCULATE');
            }
            if (slipInfos[0].Placement_lk__c != null) {
                publishRecordChangedEvent(slipInfos[0].Placement_lk__c, 'Placement', 'NEED_RECALCULATE');
            }
        }
    }

    /**
     * @description
     * OPP_RecordChanged__e Platform Event 를 발행하여 레코드 변경을 알림
     * @param recordId 변경된 레코드 Id
     * @param entity 대상 엔티티 명
     * @param action 액션 명
     */
    public static void publishRecordChangedEvent(Id recordId, String entity, String action) {
        if (recordId == null) return;
        EventBus.publish(new OPP_RecordChanged__e(
                RecordId__c = recordId, Entity__c = entity, Action__c = action
        ));
    }


}