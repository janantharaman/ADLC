/**********************************************************************************
 * @filename      : Opp_MarketLineContainer_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-09 (월)
 * @group         :
 * @group-content :
 * @description   : Market Line Container LWC용 Apex 컨트롤러.
 *                  객체 타입/권한·통화 옵션·Co-broker 조건을 단일 호출로 조회하여 반환한다.
 *
 * @test-class    :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-09      i2max            Create
 **********************************************************************************/
public with sharing class Opp_MarketLineContainer_Ctrl {
    // ============================================================
    // Public Methods — AuraEnabled
    // ============================================================
    
    /**
     * @description 컨테이너 초기화에 필요한 객체 타입/편집 권한·통화 옵션·Co-broker 조건을 단일 호출로 조회한다.
     *              Placement Declaration/Treaty는 피클리스트 전체를, 그 외는 SlipInfo 기반 통화를 반환한다.
     * @param  recordId  Opportunity 또는 Placement__c 레코드 ID
     * @return ContainerDataWrapper  isPlacement / hasEditPermission / currencyOptions / cobroker 조건 포함
     */
    @AuraEnabled(cacheable=true)
    public static ContainerDataWrapper getContainerData(Id recordId) {
        ContainerDataWrapper result = new ContainerDataWrapper();
        if (String.isBlank(recordId)) return result;
        
        try {
            // ── 1. 객체 타입 판별 ──────────────────────────────────────────────
            Boolean isPlacement      = 'Placement__c'.equalsIgnoreCase(COM_MetaUtil.getObjectNameById(recordId));
            result.isPlacement       = isPlacement;
            result.hasEditPermission = isPlacement ? false : COM_MetaUtil.checkEditPermission(recordId);
            
            // ── 2. Currency 옵션 ───────────────────────────────────────────────
            Set<String> uniqueCurrencies;
            if (isPlacement) {
                Placement__c placement = [SELECT TransactionType__c, CedingType1__c FROM Placement__c WHERE Id = :recordId LIMIT 1];
                uniqueCurrencies = resolvePlacementCurrencies(recordId, placement);
            } else {
                Opportunity oppty = [SELECT Id, CedingType1__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
                uniqueCurrencies  = resolveOpportunityCurrencies(recordId, oppty, result);
            }
            
            List<String> sorted = new List<String>(uniqueCurrencies);
            sorted.sort();
            List<COM_Option> options = new List<COM_Option>();
            for (String curr : sorted) {
                options.add(new COM_Option(curr, curr));
            }
            result.currencyOptions = options;
            
            // ── 3. Co-broker 조건 ──────────────────────────────────────────────
            // Opportunity는 resolveOpportunityCurrencies 내에서 이미 설정됨 — Placement만 여기서 처리
            if (isPlacement) {
                List<OPP_Cobroker__c> cobrokers = [
                    SELECT SettlementType__c, Client__c, LKCobroking_is__c
                    FROM OPP_Cobroker__c
                    WHERE Placement_lk__c = :recordId AND CobrokingType__c = 'Producing'
                    WITH SECURITY_ENFORCED
                ];
                applyCobrokerFlags(cobrokers, result);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error loading container data: ' + e.getMessage());
        }
        
        return result;
    }
    
    // ============================================================
    // Private Helpers — Currency Resolution
    // ============================================================
    
    /**
     * @description Placement의 통화 옵션 결정.
     *
     *  [특이] Declaration / Treaty  → 피클리스트 전체 사용
     *                                  (선물·조약 구조상 통화가 미리 확정되지 않아 전체 제공)
     *  [특이] END (Endorsement)     → Cedant Endorsement 타입 SlipInfo 기반
     *                                  (일반 Closing/Offer 가 아닌 별도 정산 슬립 사용)
     *  [일반] 그 외                 → Cedant Closing 우선, 없으면 Cedant Offer fallback
     *                                  + 하위 OPP_Panel__c Currency__c 병합
     */
    private static Set<String> resolvePlacementCurrencies(Id placementId, Placement__c placement) {
        Set<String> currencies = new Set<String>();
        
        if (placement.TransactionType__c == 'Declaration' || placement.CedingType1__c == 'Treaty') {
            // ── [특이] Declaration / Treaty ───────────────────────────────────
            addPicklistCurrencies(currencies);
            
        } else if (placement.TransactionType__c == 'END') {
            // ── [특이] Endorsement ────────────────────────────────────────────
            addSlipCurrenciesForPlacement(currencies, placementId, 'Cedant Endorsement');
            
        } else {
            // ── [일반] Closing → Offer fallback + Panel Currency 병합 ─────────
            addSlipCurrenciesForPlacement(currencies, placementId, 'Cedant Closing');
            if (currencies.isEmpty()) {
                addSlipCurrenciesForPlacement(currencies, placementId, 'Cedant Offer');
            }
            for (OPP_Panel__c panel : [
                SELECT Currency__c FROM OPP_Panel__c
                WHERE Layer_md__r.Placement_lk__c = :placementId AND Currency__c != NULL AND Currency__c != ''
            ]) {
                currencies.add(panel.Currency__c);
            }
        }
        
        return currencies;
    }
    
    /**
     * @description Opportunity의 통화 옵션 결정. Co-broker 플래그도 이 단계에서 result에 설정한다.
     *
     *  [특이] Treaty / CIDetail 조건 → 피클리스트 전체를 먼저 추가한 뒤 Closing 통화 병합
     *                                    (Treaty 구조상 다양한 통화 허용 + 실제 체결 통화 보완)
     *  [일반] 그 외                  → Cedant Closing 우선, 없으면 Cedant Offer fallback
     *                                    + 하위 OPP_Panel__c Currency__c 병합
     */
    private static Set<String> resolveOpportunityCurrencies(Id oppId, Opportunity oppty, ContainerDataWrapper result) {
        Set<String> currencies = new Set<String>();
        
        // Co-broker 조건 확인 — currency 결정(Treaty/CIDetail 분기)에도 영향을 주므로 먼저 수행
        List<OPP_Cobroker__c> oppCobrokers = [
            SELECT SettlementType__c, Client__c, LKCobroking_is__c
            FROM OPP_Cobroker__c
            WHERE Opportunity_md__c = :oppId AND CobrokingType__c = 'Producing' AND Placement_lk__c = NULL
            WITH SECURITY_ENFORCED
        ];
        applyCobrokerFlags(oppCobrokers, result);
        
        if (oppty.CedingType1__c == 'Treaty' || result.satisfiesCIDetailCondition) {
            // ── [특이] Treaty / CIDetail ──────────────────────────────────────
            addPicklistCurrencies(currencies);
        }
        
        // ── [일반] Closing → Offer fallback ──────────────────────────────────
        // Treaty/CIDetail 여부와 무관하게 Closing SlipInfo 통화를 병합.
        // Treaty 케이스라면 피클리스트에 없는 실제 체결 통화가 추가될 수 있다.
        // Offer fallback은 currencies가 완전히 비어있을 때만 (Treaty 피클리스트가 이미 채워진 경우 스킵).
        addSlipCurrenciesForOpportunity(currencies, oppId, 'Cedant Closing');
        if (currencies.isEmpty()) {
            addSlipCurrenciesForOpportunity(currencies, oppId, 'Cedant Offer');
        }
        for (OPP_Panel__c panel : [
            SELECT Currency__c FROM OPP_Panel__c
            WHERE Layer_md__r.Opportunity_md__c = :oppId AND Currency__c != NULL AND Currency__c != ''
        ]) {
            currencies.add(panel.Currency__c);
        }
        
        return currencies;
    }
    
    // ============================================================
    // Private Helpers — Utility
    // ============================================================
    
    /** PremiumCurrency__c 피클리스트 전체 값을 currencies에 추가한다. */
    private static void addPicklistCurrencies(Set<String> currencies) {
        for (COM_Option opt : COM_Util.makePickListOptions('OPP_PremiumSchedule__c', 'Prem_Currency__c', false)) {
            if (!String.isBlank(opt.value)) currencies.add(opt.value);
        }
    }
    
    /** Placement 기준 지정된 SlipInfo Type의 Prem_Currency__c를 currencies에 추가한다. */
    private static void addSlipCurrenciesForPlacement(Set<String> currencies, Id placementId, String slipType) {
        for (OPP_PremiumSchedule__c rec : [
            SELECT Prem_Currency__c
            FROM OPP_PremiumSchedule__c
            WHERE Type__c = 'Slip' AND Prem_Currency__c != ''
              AND SlipInfo_lk__r.Placement_lk__c = :placementId
              AND SlipInfo_lk__r.Latest_is__c = true
              AND SlipInfo_lk__r.Type__c = :slipType
        ]) {
            currencies.add(rec.Prem_Currency__c);
        }
    }
    
    /** Opportunity 기준 지정된 SlipInfo Type의 Prem_Currency__c를 currencies에 추가한다. */
    private static void addSlipCurrenciesForOpportunity(Set<String> currencies, Id oppId, String slipType) {
        for (OPP_PremiumSchedule__c rec : [
            SELECT Prem_Currency__c
            FROM OPP_PremiumSchedule__c
            WHERE Type__c = 'Slip' AND Prem_Currency__c != ''
              AND SlipInfo_lk__r.Opportunity_lk__c = :oppId
              AND SlipInfo_lk__r.Latest_is__c = true
              AND SlipInfo_lk__r.Type__c = :slipType
        ]) {
            currencies.add(rec.Prem_Currency__c);
        }
    }
    
    /**
     * @description Cobroker 목록을 순회하여 hasProducingCobroker / satisfiesCIDetailCondition 플래그를 설정한다.
     *              Opp · Placement 양쪽에서 동일한 판별 기준을 공유한다.
     */
    private static void applyCobrokerFlags(List<OPP_Cobroker__c> cobrokers, ContainerDataWrapper result) {
        if (cobrokers.isEmpty()) return;
        result.hasProducingCobroker = true;
        for (OPP_Cobroker__c cb : cobrokers) {
            if (cb.SettlementType__c == 'Separate' && cb.Client__c == true && cb.LKCobroking_is__c == false) {
                result.satisfiesCIDetailCondition = true;
                return;
            }
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description getContainerData 반환 Wrapper. LWC 컨테이너 초기화에 사용한다.
     */
    public class ContainerDataWrapper {
        @AuraEnabled public Boolean          isPlacement              { get; set; }
        @AuraEnabled public Boolean          hasEditPermission        { get; set; }
        @AuraEnabled public List<COM_Option> currencyOptions          { get; set; }
        @AuraEnabled public Boolean          hasProducingCobroker     { get; set; }
        @AuraEnabled public Boolean          satisfiesCIDetailCondition { get; set; }
        
        public ContainerDataWrapper() {
            isPlacement              = false;
            hasEditPermission        = false;
            currencyOptions          = new List<COM_Option>();
            hasProducingCobroker     = false;
            satisfiesCIDetailCondition = false;
        }
    }
}