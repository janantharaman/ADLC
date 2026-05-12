/**********************************************************************************
 * @filename       : OPP_RISlipInfo_Ctrl.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-28 (수)
 * @group         :
 * @group-content :
 * @description   : RI Slip Info(RI Offer / RI Closing / RI Endorsement) OPP_SlipInfo Detail 화면에서 사용되는 Controller
 *                  1. RI Slip 현재 데이터 조회 및 비교 대상 Cedant Slip 함께 반환 (getRISlipInfo)
 *                     - RI Offer → Cedant Offer 비교
 *                     - RI Closing → Cedant Closing 비교
 *                     - RI Endorsement → 동일 Placement 의 Cedant Endorsement (Latest=true) 비교
 *                  2. RI Slip 저장 처리 (saveSlip)
 *                     - 유효한 PremiumSchedule(PaymentType != Install) 존재 시 PremiumPaymentTerms = 'NULL' 로 저장
 *                  3. Picklist 옵션 목록 반환 (RIType, TorLsw, PremiumPaymentTermDays)
 *                  4. SlipInfo 연결 Opportunity 의 유효한 PremiumSchedule 존재 여부 반환 (hasValidPremiumSchedule)
 *                  5. Country__c API 값을 Picklist Label 로 변환하여 반환 (getCountryOriginLabel)
 *                  6. SlipInfo 에 연결된 TSI(Type=Slip) 목록 조회 (getSlipTSI)
 *                  7. Custom Metadata 다국어 텍스트 조회 (getTexts)
 * @test-class    : OPP_RISlipInfo_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-28      i2max            Create
**********************************************************************************/

public with sharing class OPP_RISlipInfo_Ctrl {

    private static final String NONE_LABEL = '--None--';
    private static final String LABEL_KEY = 'label';
    private static final String VALUE_KEY = 'value';

    /**
     * @description
     * Custom Metadata(MultilingualText__mdt) 에서 키 목록에 해당하는 다국어 텍스트를 조회
     * @param keys 조회할 DeveloperName 목록
     * @return Map<String, String> DeveloperName → Content__c 매핑 결과
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getTexts(List<String> keys) {
        Map<String, String> result = new Map<String, String>();

        for (MultilingualText__mdt m : [
                SELECT DeveloperName, Content__c
                FROM MultilingualText__mdt
                WHERE DeveloperName IN :keys
        ]) {
            result.put(m.DeveloperName, m.Content__c);
        }

        return result;
    }

    /**
     * @description
     * 특정 Opportunity 에 연결된 Cedant Slip 중 가장 최근에 생성된 레코드를 조회
     * RI Offer 비교용 : Cedant Offer
     * RI Closing 비교용 : Cedant Closing
     * @param opportunityId 조회 기준 Opportunity 레코드 Id
     * @param cedantType 조회할 Cedant Slip 의 Type__c 값 ('Cedant Offer', 'Cedant Closing')
     * @return OPP_SlipInfo__c 가장 최근 Cedant Slip, 없으면 null
     */
    private static OPP_SlipInfo__c getLatestCedantSlip (Id opportunityId, String cedantType) {
        List<OPP_SlipInfo__c> slips = [
                SELECT Id, Placement_lk__r.LKRefNoh__c, Placement_lk__r.TransactionType__c, Opportunity_lk__c, Form__c, RIType__c, Reinsured__c, Insured__c, PolicyHolder__c, PolicyNo__c,
                        PeriodFrom__c, PeriodTo__c, ENDEffectivedDate__c, Amendments__c, CoveredRisk__c, Interest__c, Location__c, LimitofLiability__c, Deductible__c,
                        PremPaymentClause_fm__c, Prem100__c, DepositPrem__c, TorLsw__c, TerritoryScope__c, GoverningLaw__c,
                        PremiumPaymentTerms__c, PremiumPaymentTermDays__c, AddPhrase_is__c, TaxPayable__c, TaxPayableReinAdmin__c,
                        OccupancyBiz__c, TSI__c, TermsConds__c, LossRecord__c, RIAddInfo__c,  OrderHereon__c,
                        CountryOrigin_fm__c, TotalDeduction__c, RIOtherDeduction__c, Type__c, ExtensionClauses__c
                FROM OPP_SlipInfo__c
                WHERE Opportunity_lk__c = :opportunityId
                AND Type__c = :cedantType
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        return slips.isEmpty() ? null : slips[0];
    }

    /**
    * @description
    * RI Slip 의 현재(current) 데이터와 비교 대상 Cedant Slip(previous) 데이터를 함께 반환
    * RI Offer → Cedant Offer 와 비교
    * RI Closing → Cedant Closing 과 비교
    * Cedant Slip 이 없는 경우 previous 키는 Map 에 포함되지 않음
    * @param recordId 조회 기준 OPP_SlipInfo__c 레코드 Id
    * @return Map<String, OPP_SlipInfo__c> 'current': 현재 RI Slip, 'previous': 비교 대상 Cedant Slip
    */
    @AuraEnabled(Cacheable=true)
    public static Map<String, OPP_SlipInfo__c> getRISlipInfo (Id recordId) {
        if (recordId == null) return null;

        Map<String, OPP_SlipInfo__c> result = new Map<String, OPP_SlipInfo__c>();

        // current : 현재 RI Slip
        OPP_SlipInfo__c current = [
                SELECT Id, Placement_lk__c, SlipInfo_lk__r.Placement_lk__c, Placement_lk__r.LKRefNoh__c, Placement_lk__r.TransactionType__c, Opportunity_lk__c, Form__c, RIType__c, Reinsured__c, Insured__c, PolicyHolder__c, PolicyNo__c,
                        PeriodFrom__c, PeriodTo__c, ENDEffectivedDate__c, Amendments__c, CoveredRisk__c, Interest__c, Location__c, LimitofLiability__c, Deductible__c,
                        PremPaymentClause_fm__c, Prem100__c, DepositPrem__c, TorLsw__c, TerritoryScope__c, GoverningLaw__c,
                        PremiumPaymentTerms__c, PremiumPaymentTermDays__c, AddPhrase_is__c, TaxPayable__c, ExtensionClauses__c,
                        OccupancyBiz__c, TSI__c, TermsConds__c, LossRecord__c, RIAddInfo__c,  OrderHereon__c,
                        CountryOrigin_fm__c, TotalDeduction__c, RIOtherDeduction__c, Type__c, TaxPayableReinAdmin__c
                FROM OPP_SlipInfo__c
                WHERE Id =: recordId LIMIT 1
        ];

        result.put('current', current);

        OPP_SlipInfo__c previous;

        // Cedant 기준 비교
        if (current.Type__c == 'RI Offer') {
            previous = getLatestCedantSlip(
                    current.Opportunity_lk__c,
                    'Cedant Offer'
            );
        } else if (current.Type__c == 'RI Closing') {
            previous = getLatestCedantSlip(
                    current.Opportunity_lk__c,
                    'Cedant Closing'
            );
        } else if (current.Type__c == 'RI Endorsement') {
            Id targetPlacementId = current.Placement_lk__c;
            if (targetPlacementId == null && current.SlipInfo_lk__r != null) {
                targetPlacementId = current.SlipInfo_lk__r.Placement_lk__c;
            }

            if (targetPlacementId == null) {
                return result;
            }

            // RI Endorsement → 동일 Placement 의 Cedant Endorsement(Latest=true) 와 비교
            List<OPP_SlipInfo__c> cedantEndList = [
                    SELECT Id, Placement_lk__r.TransactionType__c, Placement_lk__c,
                           Type__c, Form__c, Reinsured__c, Insured__c, PeriodTo__c, PeriodFrom__c,
                            ENDEffectivedDate__c, Amendments__c, Prem100__c, Latest_is__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :targetPlacementId
                    AND Type__c = 'Cedant Endorsement'
                    AND Latest_is__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            previous = cedantEndList.isEmpty() ? null : cedantEndList[0];
        }

        if (previous != null) {
            result.put('previous', previous);
        }

        return result;
    }

    /**
     * @description
     * RI Slip 정보를 저장하고 최신 데이터를 반환
     * 유효한 PremiumSchedule(PaymentType__c != 'Install', Type__c = 'Schedule') 이 존재하는 경우
     * PremiumPaymentTerms__c 를 'NULL' 로 저장
     * @param slip 저장할 OPP_SlipInfo__c 레코드 (Id 필수)
     * @return OPP_SlipInfo__c 저장 후 재조회된 최신 SlipInfo 레코드
     */
    @AuraEnabled
    public static OPP_SlipInfo__c saveSlip(OPP_SlipInfo__c slip) {
        if (slip == null || slip.Id == null) {
            throw new AuraHandledException('Invalid Slip data');
        }

        Boolean isScheduleRestricted = hasValidPremiumSchedule(slip.Id);

        if (isScheduleRestricted) {
            slip.PremiumPaymentTerms__c = 'NULL';
        }

        update slip;

        // 최신 데이터 다시 조회해서 반환
        return [
                SELECT Id, Placement_lk__r.LKRefNoh__c, Placement_lk__r.TransactionType__c, Opportunity_lk__c, Form__c, RIType__c, Reinsured__c, Insured__c, PolicyHolder__c, PolicyNo__c,
                        PeriodFrom__c, PeriodTo__c, ENDEffectivedDate__c, Amendments__c, CoveredRisk__c, Interest__c, Location__c, LimitofLiability__c, Deductible__c,
                        PremPaymentClause_fm__c, Prem100__c, DepositPrem__c, TorLsw__c, TerritoryScope__c, GoverningLaw__c,
                        PremiumPaymentTerms__c, PremiumPaymentTermDays__c, AddPhrase_is__c, TaxPayable__c,ExtensionClauses__c,
                        OccupancyBiz__c, TSI__c, TermsConds__c, LossRecord__c, RIAddInfo__c,  OrderHereon__c,
                        CountryOrigin_fm__c, TotalDeduction__c, RIOtherDeduction__c, Type__c, TaxPayableReinAdmin__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slip.Id
                LIMIT 1
        ];
    }

    /**
     * @description
     * SObjectField 로부터 Picklist 옵션 목록을 생성하는 내부 유틸리티 메서드
     * @param field 옵션을 생성할 SObjectField
     * @param includeNone '--None--' 옵션 포함 여부 (true: 포함, false: 미포함)
     * @return List<COM_Option> Picklist 옵션 목록
     */
    private static List<COM_Option> picklistOptions(Schema.SObjectField field, Boolean includeNone) {

        return COM_Util.makePickListOptions(
                field.getDescribe().getSObjectType().getDescribe().getName(),
                field.getDescribe().getName(),
                !includeNone
        );
    }

    /**
     * @description PremiumPaymentTermDays__c 필드의 Picklist 옵션 목록 반환
     * @return List<COM_Option> Picklist 옵션 목록
     */
    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getPremiumPaymentDaysOptions() {
        return picklistOptions(OPP_SlipInfo__c.PremiumPaymentTermDays__c, true);
    }

    /**
    * @description RIType__c 필드의 Picklist 옵션 목록 반환
    * @return List<COM_Option> Picklist 옵션 목록
    */
    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getRITypeOptions() {
        return picklistOptions(OPP_SlipInfo__c.RIType__c, true);
    }

    /**
     * @description TorLsw__c 필드의 Picklist 옵션 목록 반환
     * @return List<COM_Option> Picklist 옵션 목록
     */
    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getTorLswOptions() {
        return picklistOptions(OPP_SlipInfo__c.TorLsw__c, true);
    }

    /**
   * @description
   * SlipInfo 에 연결된 Opportunity 의 유효한 PremiumSchedule 존재 여부를 반환
   * 조건 : Slip Type__c = 'RI Closing' OR 'RI Offer'
   * 조건 : OPP_PremiumSchedule__c.PaymentType__c != 'Install' AND Type__c = 'Schedule'
   * @param slipInfoId 검증 대상 OPP_SlipInfo__c 레코드 Id
   * @return Boolean 유효한 PremiumSchedule 이 존재하면 true, 없으면 false
   */
    @AuraEnabled(Cacheable=true)
    public static Boolean hasValidPremiumSchedule(Id slipInfoId) {

        if (slipInfoId == null) return false;

        // SlipInfo에서 Opportunity 가져오기
        OPP_SlipInfo__c slip = [
                SELECT Id, Opportunity_lk__c, Type__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ];

        // Slip Type 체크
        if (slip.Type__c != 'RI Closing' && slip.Type__c != 'RI Offer') {
            return false;
        }

        if (slip.Opportunity_lk__c == null) {
            return false;
        }

        // PremiumSchedule 존재 여부 체크
        Integer countPS = [
                SELECT COUNT()
                FROM OPP_PremiumSchedule__c
                WHERE Opportunity_lk__c = :slip.Opportunity_lk__c
                AND PaymentType__c != 'Install'
                AND Type__c = 'Schedule'
        ];

        return countPS > 0;
    }

    /**
         * @description
         * SlipInfo 에 연결된 Opportunity → CedantName(Account) 의 Country 필드 값을 Label 로 변환하여 반환
         * Country__c API 값을 Picklist Label 로 변환하기 위해 COM_MetaUtil 활용
         * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
         * @return String Country__c 의 Picklist Label, 값이 없으면 null
         */
    @AuraEnabled(Cacheable=true)
    public static String getCountryOriginLabel(Id slipInfoId) {
        if (slipInfoId == null) return null;

        // SlipInfo → Country(API 값) 가져오기
        OPP_SlipInfo__c slip = [
                SELECT Opportunity_lk__r.CedantName_lk__r.Country__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ];

        String countryValue = slip.Opportunity_lk__r.CedantName_lk__r.Country__c;

        if (String.isBlank(countryValue)) return null;

        return COM_MetaUtil.getLabelByValue('Account', 'Country__c', countryValue);
    }

    /**
     * @description
     * SlipInfo 에 연결된 TSI 목록을 조회
     * 조건 : Type__c = 'Slip'
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id
     * @return List<OPP_TSIByLocation__c> TSI 레코드 목록
     */
    @AuraEnabled
    public static List<OPP_TSIByLocation__c> getSlipTSI(Id slipInfoId) {
        return [
                SELECT Id, TSICurrency__c, SlipTSI__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'Slip'
                ORDER BY CreatedDate
        ];
    }

}