/**********************************************************************************
 * @filename       : OPP_SlipInfoRIClosingModal_Ctrl.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-06 (금)
 * @group         :
 * @group-content :
 * @description   : RI Closing / RI Offer 문서 생성 모달에서 사용되는 유효성 검증 Controller
 *                  1. SlipInfo 와 연결된 Opportunity / Placement 간 주요 필드 (기간, RI Comm, Other Deduction 등)
 *                     불일치 여부 검증 (validateDiff)
 *                     - Placement TransactionType = 'END' 인 경우 END Effective Date 추가 비교
 *                  2. RI Closing / RI Offer Slip 문서 생성 전 필수 필드
 *                     (RIType, TorLsw, PremiumPaymentTermDays) 충족 여부 검증
 *                  3. Placement 또는 SlipInfo 기준으로 'Cedant Endorsement' 타입 SlipInfo 존재 여부 검증
 *                     - 미존재 시 문서 생성 불가 처리 (validateRIEndPlacement / validateRIEndSlipInfo)
 *                  4. 검증 통과 후 문서 생성 실행 (confirmAndGenerate)
 * @test-class    : OPP_SlipInfoRIClosingModal_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-06      i2max            Create
**********************************************************************************/

public with sharing class OPP_SlipInfoRIClosingModal_Ctrl {

    /**
    * @description 유효성 검증 결과를 담는 내부 클래스
    * targetObject : 검증 대상 객체명 (Opportunity / Placement)
    * mismatchFields : 불일치 항목 목록
    * isValid : 검증 통과 여부
    * message : 검증 결과 메시지
    */
    public class ValidationResult {
        @AuraEnabled public String targetObject;
        @AuraEnabled public List<String> mismatchFields;

        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String message;

        public ValidationResult() {}

        public ValidationResult(Boolean isValid, String message) {
            this.isValid = isValid;
            this.message = message;
        }
    }

    /**
     * @description
     * SlipInfo 와 연관된 Opportunity 또는 Placement 간 주요 필드 값 불일치 여부를 검증
     * Opportunity : PeriodFrom, PeriodTo, RI Cession(%), Other Deduction 비교
     * Placement : InceptionDate, ExpirationDate, RI Comm(%), Other Deductions(%) 비교
     * Placement TransactionType = 'END' 인 경우 추가로 END Effective Date 비교
     * @param slipInfoId 검증 대상 OPP_SlipInfo__c 레코드 Id
     * @return ValidationResult 불일치 필드 목록 및 대상 객체명을 포함한 검증 결과
     */
    @AuraEnabled
    public static ValidationResult validateDiff(Id slipInfoId) {

        OPP_SlipInfo__c slip = [
                SELECT PeriodFrom__c,
                        PeriodTo__c,
                        RICession__c,
                        RIComm__c,
                        RIOtherDeduction__c,
                        ENDEffectivedDate__c,
                        Opportunity_lk__c,
                        Placement_lk__c,
                        OtherDeduction__c,
                        Placement_lk__r.TransactionType__c,
                        Placement_lk__r.InceptionDate__c,
                        Placement_lk__r.ExpirationDate__c,
                        Placement_lk__r.RICommPct__c,
                        Placement_lk__r.OtherDeductionsPct__c,
                        Placement_lk__r.ENDEffectivedDate__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ];

        System.debug('### Slip FULL = ' + JSON.serializePretty(slip));
        System.debug('### Placement FULL = ' + JSON.serializePretty(slip.Placement_lk__r));

        List<String> mismatches = new List<String>();


        //Opportunity Slip Validation
        if (slip.Opportunity_lk__c != null) {

            System.debug('### Opportunity Validation START');

            Opportunity opp = [
                    SELECT PeriodFrom__c,
                            PeriodTo__c,
                            RICommPct__c,
                            OtherDeductionsPct__c
                    FROM Opportunity
                    WHERE Id = :slip.Opportunity_lk__c
                    LIMIT 1
            ];

            System.debug('### Opportunity FULL = ' + JSON.serializePretty(opp));

            Date slipFrom = slip.PeriodFrom__c == null ? null : slip.PeriodFrom__c.date();
            Date slipTo   = slip.PeriodTo__c == null ? null : slip.PeriodTo__c.date();

            System.debug('### PeriodFrom Compare -> Slip=' + slipFrom + ' Opp=' + opp.PeriodFrom__c);
            System.debug('### PeriodTo Compare -> Slip=' + slipTo + ' Opp=' + opp.PeriodTo__c);

            if (isDifferent(slipFrom, opp.PeriodFrom__c)) {
                mismatches.add('Period From');
            }

            if (isDifferent(slipTo, opp.PeriodTo__c)) {
                mismatches.add('Period To');
            }

            if (isDifferent(slip.RICession__c, opp.RICommPct__c)) {
                mismatches.add('RI Cession (%)');
            }


            System.debug('### Other Deduction Compare -> Slip=' + slip.RIOtherDeduction__c + ' Opp=' + opp.OtherDeductionsPct__c);

            if (isDifferent(slip.RIOtherDeduction__c, opp.OtherDeductionsPct__c)) {
                mismatches.add('Other Deduction');
            }
        }


        //Placement Slip Validation
        if (slip.Placement_lk__c != null && slip.Placement_lk__r != null) {

            System.debug('### Placement Validation START');

            Date slipFrom = slip.PeriodFrom__c == null ? null : slip.PeriodFrom__c.date();
            Date slipTo   = slip.PeriodTo__c == null ? null : slip.PeriodTo__c.date();

            Date placementFrom = slip.Placement_lk__r.InceptionDate__c;
            Date placementTo   = slip.Placement_lk__r.ExpirationDate__c;

            System.debug('### Inception Compare -> Slip=' + slipFrom + ' Placement=' + placementFrom);
            System.debug('### Expiration Compare -> Slip=' + slipTo + ' Placement=' + placementTo);

            if (isDifferent(slipFrom, placementFrom)) {
                mismatches.add('Inception Date');
            }

            if (isDifferent(slipTo, placementTo)) {
                mismatches.add('Expiration Date');
            }

            if (isDifferent(slip.RIComm__c, slip.Placement_lk__r.RICommPct__c)) {
                mismatches.add('RI Comm (%)');
            }

            System.debug('### Other Deduction Compare -> Slip=' + slip.RIOtherDeduction__c + ' Placement=' + slip.Placement_lk__r.OtherDeductionsPct__c);

            if (isDifferent(slip.RIOtherDeduction__c, slip.Placement_lk__r.OtherDeductionsPct__c)) {
                mismatches.add('Other Deductions (%)');
            }


           // END Transaction Validation (배서인 경우)
            if (slip.Placement_lk__r.TransactionType__c == 'END') {
                System.debug('### END Date Compare -> Slip=' + slip.ENDEffectivedDate__c + ' Placement=' + slip.Placement_lk__r.ENDEffectivedDate__c);

                if (isDifferent(slip.ENDEffectivedDate__c, slip.Placement_lk__r.ENDEffectivedDate__c)) {
                    mismatches.add('END Effective Date');
                }
            }
        }

        System.debug('### FINAL Mismatch Fields = ' + mismatches);

        ValidationResult result = new ValidationResult();

        if (slip.Placement_lk__c != null) {
            result.targetObject = 'Placement';
        } else if (slip.Opportunity_lk__c != null) {
            result.targetObject = 'Opportunity';
        }

        result.mismatchFields = mismatches;

        return result;
    }

    /**
    * @description
    * 두 값의 차이 여부를 반환하는 유틸리티 메서드
    * @param a 비교 대상 값 A
    * @param b 비교 대상 값 B
    * @return Boolean 두 값이 다르면 true, 같으면 false
    */
    private static Boolean isDifferent(Object a, Object b) {

        if (a == null && b == null) return false;
        if (a == null || b == null) return true;

        // Decimal 비교 - 변환 실패 시 문자열 비교로 fallback
        if (a instanceof Decimal || b instanceof Decimal) {
            try {
                Decimal da = Decimal.valueOf(String.valueOf(a));
                Decimal db = Decimal.valueOf(String.valueOf(b));
                return da != db;
            } catch (Exception e) {
                System.debug('### Decimal parse failed, fallback to string compare: ' + e.getMessage());
                return String.valueOf(a) != String.valueOf(b);
            }
        }

        // Date 비교
        if (a instanceof Date && b instanceof Date) {
            return ((Date)a) != ((Date)b);
        }

        if (a instanceof Datetime && b instanceof Date) {
            return ((Datetime)a).date() != ((Date)b);
        }

        if (a instanceof Date && b instanceof Datetime) {
            return ((Date)a) != ((Datetime)b).date();
        }

        return String.valueOf(a) != String.valueOf(b);
    }


    /**
     * @description
     * 유효성 검증 통과 후 문서 생성을 실행하는 메서드
     * @param slipInfoId 문서 생성 대상 OPP_SlipInfo__c 레코드 Id
     */
    @AuraEnabled
    public static void confirmAndGenerate(Id slipInfoId) {

        // validation 재실행
       /* ValidationResult result = validateDiff(slipInfoId);

        if (result.mismatchFields != null && !result.mismatchFields.isEmpty()) {
            String fields = String.join(result.mismatchFields, ',');
            String target = result.targetObject != null ? result.targetObject : '';
            throw new AuraHandledException(
                    '아래 항목이 ' + target + ' 와 일치하지 않습니다' + '||' + fields + '||' + target
            );
        }
*/
        try {

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description
     * RI Closing Slip 문서 생성 전 필수 필드(RIType, TorLsw, PremiumPaymentTermDays) 검증
     * @param slipInfoId 검증 대상 OPP_SlipInfo__c 레코드 Id
     * @return ValidationResult 필수 필드 충족 여부를 포함한 검증 결과
     */
    @AuraEnabled
    public static ValidationResult validateRIClosingSlipFields(Id slipInfoId) {
        return validateRISlipFields(slipInfoId);
    }

    /**
     * @description
     * RI Offer Slip 문서 생성 전 필수 필드(RIType, TorLsw, PremiumPaymentTermDays) 검증
     * @param slipInfoId 검증 대상 OPP_SlipInfo__c 레코드 Id
     * @return ValidationResult 필수 필드 충족 여부를 포함한 검증 결과
     */
    @AuraEnabled
    public static ValidationResult validateRIOfferSlipFields(Id slipInfoId) {
        return validateRISlipFields(slipInfoId);
    }

    /**
     * @description
     * Placement 에 연결된 'Cedant Endorsement' 타입의 SlipInfo 존재 여부 검증
     * Cedant Endorsement Slip 이 없으면 문서 생성 불가 처리
     * @param placementId 검증 대상 Placement 레코드 Id
     * @return ValidationResult Cedant Endorsement Slip 존재 여부를 포함한 검증 결과
     */
    @AuraEnabled(cacheable=true)
    public static ValidationResult validateRIEndPlacement(Id placementId) {
        try {
            if (placementId == null) {
                return new ValidationResult(false, System.Label.PLA_MSG_VALIDATE_CEDANT_FOR_DOC);
            }

            List<OPP_SlipInfo__c> slipList = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    AND Type__c = 'Cedant Endorsement'
                    LIMIT 1
            ];

            if (slipList.isEmpty()) {
                return new ValidationResult(false, System.Label.PLA_MSG_VALIDATE_CEDANT_FOR_DOC);
            }

            return new ValidationResult(true, null);
        } catch (Exception e) {
            System.debug('### validateRIEndPlacement error: ' + e.getMessage());
            return new ValidationResult(false, 'Validation Error');
        }
    }

    /**
     * @description
     * SlipInfo 로부터 연결된 Placement 를 조회한 후 Cedant Endorsement Slip 존재 여부 검증
     * SlipInfo 가 없거나 Placement 연결이 없으면 문서 생성 불가 처리
     * 내부적으로 validateRIEndPlacement 를 재호출
     * @param slipInfoId 검증 대상 OPP_SlipInfo__c 레코드 Id
     * @return ValidationResult Cedant Endorsement Slip 존재 여부를 포함한 검증 결과
     */
    @AuraEnabled(cacheable=true)
    public static ValidationResult validateRIEndSlipInfo(Id slipInfoId) {
        try {
            if (slipInfoId == null) {
                return new ValidationResult(false, 'Document generation is unavailable because no Cedant Endorsement slip exists for this placement.');
            }

            List<OPP_SlipInfo__c> currentSlipList = [
                    SELECT Id, Placement_lk__c
                    FROM OPP_SlipInfo__c
                    WHERE Id = :slipInfoId
                    LIMIT 1
            ];

            if (currentSlipList.isEmpty() || currentSlipList[0].Placement_lk__c == null) {
                return new ValidationResult(false, 'Document generation is unavailable because no Cedant Endorsement slip exists for this placement.');
            }

            return validateRIEndPlacement(currentSlipList[0].Placement_lk__c);
        } catch (Exception e) {
            System.debug('### validateRIEndSlipInfo error: ' + e.getMessage());
            return new ValidationResult(false, 'Validation Error');
        }
    }

    /**
    * @description
    * RI Closing / RI Offer Slip 문서 생성 전 공통 필수 필드 검증 내부 메서드
    * 검증 항목 : RIType__c, TorLsw__c, PremiumPaymentTermDays__c
    * 하나라도 미입력 시 isValid = false 반환
    * @param slipInfoId 검증 대상 OPP_SlipInfo__c 레코드 Id
    * @return ValidationResult 필수 필드 충족 여부를 포함한 검증 결과
    */
    private static ValidationResult validateRISlipFields(Id slipInfoId) {
        try {
            List<OPP_SlipInfo__c> slipList = [
                    SELECT RIType__c, TorLsw__c, PremiumPaymentTermDays__c
                    FROM OPP_SlipInfo__c
                    WHERE Id = :slipInfoId
                    LIMIT 1
            ];

            OPP_SlipInfo__c slip = slipList[0];
            List<String> missingFields = new List<String>();

            if (String.isBlank(slip.RIType__c) ||
                    String.isBlank(slip.TorLsw__c) ||
                    slip.PremiumPaymentTermDays__c == null) {
                return new ValidationResult(false, null);
            }

            return new ValidationResult(true, null);

        } catch (Exception e) {
            System.debug('### validateRISlipFields error: ' + e.getMessage());
            return new ValidationResult(false, null);
        }
    }

}