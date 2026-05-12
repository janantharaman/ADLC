/**********************************************************************************
 * @filename      : Pol_CreateLineItems_Ctrl.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : LK Insurance Dev Team
 * @date          : 2026-03-18
 * @group         : Policy
 * @description   : polCreateLineItems LWC 컴포넌트의 Apex 컨트롤러
 *                  InsurancePolicyParticipant 조회 및 Line Item 생성 처리
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-18      LK Dev        Create
 * 1.1   2026-03-19      LK Dev        Replace date fields with YYMMDD numeric fields;
 *                                     auto-convert to Date on upsert
 **********************************************************************************/
public with sharing class Pol_CreateLineItems_Ctrl {
    /**
     * @description 초기 데이터 일괄 조회
     *              InsurancePolicyParticipant 목록 + InsurancePolicy 기본 정보 + OPP_PremiumSchedule__c 목록 반환
     * @param policyId InsurancePolicy Id
     * @return InitDataWrapper
     */
    @AuraEnabled(cacheable=true)
    public static InitDataWrapper getInitData(Id policyId) {
        try {
            InsurancePolicy policy = [
                SELECT Total_Premium_Amount__c, TotalInstalment__c
                FROM InsurancePolicy
                WHERE Id = :policyId
                LIMIT 1
            ];

            InitDataWrapper w = new InitDataWrapper();
            w.participants = [
                SELECT Id, Role, Insurer__c, Insurer__r.Name, SignedLine__c, InsurerCommission__c, LeadInsurer__c
                FROM InsurancePolicyParticipant
                WHERE InsurancePolicyId = :policyId
                ORDER BY LeadInsurer__c DESC, CreatedDate ASC
            ];
            w.totalPremiumAmount = policy.Total_Premium_Amount__c != null ? policy.Total_Premium_Amount__c : 0;
            w.totalInstalment = policy.TotalInstalment__c != null ? (Integer) policy.TotalInstalment__c : 0;
            w.schedules = [
                SELECT Id, CRSInstallmentRate__c, CRSInstallPremium__c, CRSPaymentDueDateNum__c, CRSExpPaymentDateNum__c
                FROM OPP_PremiumSchedule__c
                WHERE CRSInsurancePolicy_lk__c = :policyId
                ORDER BY CreatedDate ASC
            ];
            return w;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class InitDataWrapper {
        @AuraEnabled
        public List<InsurancePolicyParticipant> participants { get; set; }
        @AuraEnabled
        public Decimal totalPremiumAmount { get; set; }
        @AuraEnabled
        public Integer totalInstalment { get; set; }
        @AuraEnabled
        public List<OPP_PremiumSchedule__c> schedules { get; set; }

        public InitDataWrapper() {
            participants = new List<InsurancePolicyParticipant>();
            totalPremiumAmount = 0;
            totalInstalment = 0;
            schedules = new List<OPP_PremiumSchedule__c>();
        }
    }

    /**
     * @description InsurancePolicyParticipant 삭제 + Upsert 통합 처리
     *              deletedIds 에 해당하는 레코드 삭제 후 participants upsert 수행
     * @param recordId     InsurancePolicy Id
     * @param participants upsert 대상 Participant sObject 목록
     * @param deletedIds   삭제 대상 Participant Id 목록
     */
    @AuraEnabled
    public static void saveParticipants(Id recordId, List<InsurancePolicyParticipant> participants, List<Id> deletedIds) {
        try {
            // 1. 삭제
            if (deletedIds != null && !deletedIds.isEmpty()) {
                delete [SELECT Id FROM InsurancePolicyParticipant WHERE Id IN :deletedIds];
            }

            // 2. Upsert
            if (participants == null || participants.isEmpty())
                return;

            List<InsurancePolicyParticipant> recordsToUpsert = new List<InsurancePolicyParticipant>();
            for (InsurancePolicyParticipant p : participants) {
                InsurancePolicyParticipant record = new InsurancePolicyParticipant();
                record.Insurer__c = p.Insurer__c;
                record.SignedLine__c = p.SignedLine__c;
                record.InsurerCommission__c = p.InsurerCommission__c;
                record.LeadInsurer__c = p.LeadInsurer__c != null ? p.LeadInsurer__c : false;

                if (p.Id != null) {
                    record.Id = p.Id;
                } else {
                    record.InsurancePolicyId = recordId;
                    record.Role = 'Insurer';
                }
                recordsToUpsert.add(record);
            }
            upsert recordsToUpsert;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Insurer 선택 시 COM_Insurer_Commission__c 에서 약정 수수료율 조회
     *              조회 조건: Insurer_lk__c + 현재 InsurancePolicy 의 LOB1/LOB2/LOB3
     * @param insurerId 선택된 Account Id
     * @param policyId  현재 InsurancePolicy Id
     * @return 약정 수수료율(Decimal), 없으면 null
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getInsurerCommission(Id insurerId, Id policyId) {
        try {
            InsurancePolicy policy = [
                SELECT LOB1__c, LOB2__c, LOB3__c
                FROM InsurancePolicy
                WHERE Id = :policyId
                LIMIT 1
            ];

            List<COM_InsurerCommission__c> commissions = [
                SELECT InsurerCommission__c
                FROM COM_InsurerCommission__c
                WHERE Insurer_lk__c = :insurerId AND LOB1__c = :policy.LOB1__c AND LOB2__c = :policy.LOB2__c AND LOB3__c = :policy.LOB3__c
                LIMIT 1
            ];

            return commissions.isEmpty() ? null : commissions[0].InsurerCommission__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description LK_AUT_PolicyLineItem_NewCreate Flow 실행
     *              Autolaunched Flow를 Apex에서 직접 invoke
     * @param policyId InsurancePolicy Id (inPolicyRecordId 입력 변수로 전달)
     */
    @AuraEnabled
    public static Boolean runPolicyLineItemFlow(Id policyId) {
        try {
            Map<String, Object> params = new Map<String, Object>{ 'inPolicyRecordId' => policyId };
            Flow.Interview interview = Flow.Interview.createInterview('LK_AUT_PolicyLineItem_NewCreate', params);
            interview.start();
            return (Boolean) interview.getVariableValue('var_ReturnValue');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description OPP_PremiumSchedule__c 목록 Upsert
     *              LWC에서 YYMMDD 형식(Decimal 6자리)으로 전달된 날짜를
     *              Date 타입으로 변환하여 CRSPaymentDueDate__c / CRSExpPaymentDate__c 에 저장
     * @param policyId  InsurancePolicy Id
     * @param schedules upsert 대상 Schedule sObject 목록
     */
    @AuraEnabled
    public static void upsertSchedules(Id policyId, List<OPP_PremiumSchedule__c> schedules) {
        if (schedules == null || schedules.isEmpty())
            return;

        List<OPP_PremiumSchedule__c> recordsToUpsert = new List<OPP_PremiumSchedule__c>();

        for (OPP_PremiumSchedule__c s : schedules) {
            OPP_PremiumSchedule__c record = new OPP_PremiumSchedule__c();
            record.CRSInsurancePolicy_lk__c = policyId;
            record.CRSInstallmentRate__c = s.CRSInstallmentRate__c;
            record.CRSInstallPremium__c = s.CRSInstallPremium__c;
            // YYMMDD 숫자 필드 저장
            record.CRSPaymentDueDateNum__c = s.CRSPaymentDueDateNum__c;
            record.CRSExpPaymentDateNum__c = s.CRSExpPaymentDateNum__c;
            // YYMMDD → Date 변환 후 Date 타입 필드에 저장
            record.CRSPaymentDueDate__c = yymmddToDate(s.CRSPaymentDueDateNum__c);
            record.CRSExpPaymentDate__c = yymmddToDate(s.CRSExpPaymentDateNum__c);
            if (s.Id != null) {
                record.Id = s.Id;
            }
            recordsToUpsert.add(record);
        }

        try {
            upsert recordsToUpsert;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description YYMMDD 형식의 Decimal 값을 Date 타입으로 변환
     *              e.g. 260319 → 2026-03-19
     * @param yymmdd YYMMDD 형식의 6자리 숫자 (Decimal)
     * @return 변환된 Date, 입력값이 없거나 유효하지 않으면 null
     */
    private static Date yymmddToDate(Decimal yymmdd) {
        if (yymmdd == null)
            return null;
        Integer num = yymmdd.intValue();
        if (num <= 0 || num > 999999)
            return null;
        Integer yy = num / 10000;
        Integer mm = (num / 100) - (yy * 100);
        Integer dd = num - (num / 100 * 100);
        if (mm < 1 || mm > 12 || dd < 1 || dd > 31)
            return null;
        return Date.newInstance(2000 + yy, mm, dd);
    }
}