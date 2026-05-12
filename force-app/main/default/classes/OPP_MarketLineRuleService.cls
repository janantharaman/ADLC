/**********************************************************************************
 * @filename      : OPP_MarketLineRuleService.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-07 (토)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketLineRuleService_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-07      i2max     Create
**********************************************************************************/
public with sharing class OPP_MarketLineRuleService {

    public class RuleSet {
        @AuraEnabled public List<MarketTypeRule> marketTypeRules = new List<MarketTypeRule>();
        @AuraEnabled public List<CalcRule> calcRules = new List<CalcRule>();
    }

    // MarketType별 룰 (Lookup 대상/필드/필터/비활성/초기화필드)
    public class MarketTypeRule {
        @AuraEnabled public String marketType; // Facility / MGA / Open Market
        @AuraEnabled public String uiKey; // UI가 렌더링하는 컬럼 key (예: Facility_lk__c)
        @AuraEnabled public String activeField; // 실제 값이 저장될 필드 (Facility_lk__c or MGAName_lk__c)
        @AuraEnabled public String lookupObject; // COM_Facility__c or Account
        @AuraEnabled public String filterField; // (옵션) isMGAAcc__c 등
        @AuraEnabled public Object filterValue; // (옵션) 'true' 등
        @AuraEnabled public Boolean disabled; // Open Market이면 true
        @AuraEnabled public List<String> clearFields; // MarketType 변경 시 초기화할 필드들

        public MarketTypeRule(
                String marketType,
                String uiKey,
                String activeField,
                String lookupObject,
                Boolean disabled,
                List<String> clearFields,
                String filterField,
                Object filterValue
        ) {
            this.marketType = marketType;
            this.uiKey = uiKey;
            this.activeField = activeField;
            this.lookupObject = lookupObject;
            this.disabled = disabled;
            this.clearFields = (clearFields == null) ? new List<String>() : clearFields;
            this.filterField = filterField;
            this.filterValue = filterValue;
        }
    }

    // ======================
    // CalcRule
    // ======================
    /**
     * @description Market Line의 자동 계산 로직을 정의하는 클래스
     *              UI(JS)의 계산 엔진과 서버의 유효성 검사 및 실행 순서 제어에 사용됨
     */
    public class CalcRule {
        @AuraEnabled public String targetKey; // 계산 결과가 저장될 필드의 API Name
        @AuraEnabled public String expression; // 산술식 (제한된 문법의 문자열 식)
        @AuraEnabled public List<String> dependsOn; // 해당 계산이 의존하는 필드 목록 (변경 감지 대상)
        @AuraEnabled public Integer scale; // 반올림할 소수점 자리수
        @AuraEnabled public String valueType; // 데이터 타입 (예: 'num', 'text' 등)
        @AuraEnabled public Boolean overwriteWhenEmptyOnly; // true일 경우 타겟 필드가 비어있을 때만 계산값 적용
        @AuraEnabled public Integer executionOrder; // 계산 우선순위 (validateCalcRules에서 의존성에 따라 자동 부여)

        public CalcRule(String targetKey, String expression, List<String> dependsOn, Integer scale) {
            this.targetKey = targetKey;
            this.expression = expression;
            this.dependsOn = (dependsOn == null) ? new List<String>() : dependsOn;
            this.scale = scale;
            this.valueType = null;
            this.overwriteWhenEmptyOnly = false;
            this.executionOrder = null;
        }
        public CalcRule(String targetKey, String expression, List<String> dependsOn, String valueType, Integer scale) {
            this(targetKey, expression, dependsOn, scale);
            this.valueType = valueType;
        }
    }

    /**
     * @description Market Line Grid에서 사용할 규칙 세트(RuleSet)를 생성하여 반환
     *              Market Type별 필드 제어 규칙 및 자동 계산 규칙(CalcRule)을 포함하며,
     *              계산 규칙은 필드 간 의존성을 분석하여 실행 순서(executionOrder) 반영
     * @param isCICase CI Case 여부. true일 경우 CI Case 전용 계산 규칙 적용.
     * @return MarketTypeRule 및 정렬된 CalcRule 목록을 포함하는 RuleSet 객체
     */
    @AuraEnabled(Cacheable=true)
    public static RuleSet getRuleSet(Boolean isCICase) {
        RuleSet ruleSet = new RuleSet();

        addMarketTypeRules(ruleSet);
        addCommonCalcRules(ruleSet);

        if (isCICase) {
            addCICaseCalcRules(ruleSet);
        } else {
            addStandardCalcRules(ruleSet);
        }

        validateCalcRules(new List<String>{'OPP_Panel__c', 'OPP_Layer__c'}, ruleSet.calcRules);
        //validateCalcRules('OPP_Panel__c', ruleSet.calcRules);

        return ruleSet;
    }

    /**
     * @description Market Type(Facility, MGA, Open Market)에 따른 UI 필드 제어 규칙을 추가
     *              선택된 마켓 타입에 따라 UI에서 활성화할 필드(activeField), 조회 대상(lookupObject),
     *              필터 조건, 비활성 여부(disabled), 그리고 타입 변경 시 초기화할 필드 목록(clearFields)을 정의
     * @param ruleSet 규칙을 추가할 대상 RuleSet 객체
     */
    private static void addMarketTypeRules(RuleSet ruleSet) {

        List<String> clear = new List<String>{
                'Facility_lk__c', 'MGAName_lk__c', 'Reinsurer_lk__c', 'Security_lk__c'
        };

        ruleSet.marketTypeRules.add(
                new MarketTypeRule('Facility', 'Facility_lk__c', 'Facility_lk__c', 'COM_Facility__c', false, clear, null, null)
        );
        ruleSet.marketTypeRules.add(//new MarketTypeRule('MGA', 'Facility_lk__c', 'MGAName_lk__c', 'Account', false, clear, 'isMGAAcc__c', true)
                new MarketTypeRule('MGA', 'Facility_lk__c', null, null, true, clear, null, null)
        );
        ruleSet.marketTypeRules.add(
                new MarketTypeRule('Open Market', 'Facility_lk__c', null, null, true, clear, null, null)
        );

        // Reinsurer Rules
        ruleSet.marketTypeRules.add(
                new MarketTypeRule('Facility', 'Reinsurer_lk__c', 'Reinsurer_lk__c', 'Account', false, clear, 'isReinsurerAcc__c', true)
        );
        ruleSet.marketTypeRules.add(//new MarketTypeRule('MGA', 'Reinsurer_lk__c', 'Reinsurer_lk__c', 'Account', false, clear, ' ', true)
                new MarketTypeRule('MGA', 'Reinsurer_lk__c', 'Reinsurer_lk__c', 'Account', false, clear, 'isMGAAcc__c', true)
        );
        ruleSet.marketTypeRules.add(
                new MarketTypeRule('Open Market', 'Reinsurer_lk__c', 'Reinsurer_lk__c', 'Account', false, clear, 'isReinsurerAcc__c', true)
        );

        // Security Rules
        ruleSet.marketTypeRules.add(
                new MarketTypeRule('Facility', 'Security_lk__c', null, null, true, clear, null, null)
        );
        ruleSet.marketTypeRules.add(//new MarketTypeRule('MGA', 'Security_lk__c', 'Security_lk__c', 'ACC_AdditionalInfo__c', false, clear, 'Account_lk__c', 'MGAName_lk__c')
                new MarketTypeRule('MGA', 'Security_lk__c', 'Security_lk__c', 'ACC_AdditionalInfo__c', false, clear, 'Account_lk__c', 'Reinsurer_lk__c')
        );
        ruleSet.marketTypeRules.add(
                new MarketTypeRule('Open Market', 'Security_lk__c', null, null, true, clear, null, null)
        );
    }

    /**
     * @description CI Case와 Standard Case에 공통으로 적용되는 계산 규칙
     *              주로 Producing/Placing Sharing %, Admin Fee % 등 기초 비율 관련 수식
     * @param ruleSet 규칙을 담을 RuleSet 객체
     */
    private static void addCommonCalcRules(RuleSet ruleSet) {

        /* 공통
        [Producing Co-broking / Sharing(%)] ProducingSharingPct__c = ctx_producingSharingPct
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'ProducingSharingPct__c',
                        'nvl(ctx_producingSharingPct, 0)',
                        new List<String>{ 'ctx_producingSharingPct' },
                        'num',
                        2
                )
        );
        /* 공통
        [Producing Co-broking / TPP Admin Fee (%)] ProducingTPPAdminFeePct__c = ctx_producingAdminFeePct
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'ProducingTPPAdminFeePct__c',
                        'nvl(ctx_producingAdminFeePct, 0)',
                        new List<String>{ 'ctx_producingAdminFeePct' },
                        'num',
                        2
                )
        );
        /* 공통
        [Producing Co-broking (LK) / LK Producing Sharing(%)] LKProducingSharingPct__c = ctx_lkProducingSharingPct
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKProducingSharingPct__c',
                        'nvl(ctx_lkProducingSharingPct, 0)',
                        new List<String>{ 'ctx_lkProducingSharingPct' },
                        'num',
                        2
                )
        );
        /* 공통
        [Placing Co-broking (LK) / LK Placing Sharing(%)] LKPlacingSharingPct__c = ctx_lkPlacingSharingPct
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKPlacingSharingPct__c',
                        'nvl(ctx_lkPlacingSharingPct, 0)',
                        new List<String>{ 'ctx_lkPlacingSharingPct' },
                        'num',
                        2
                )
        );
        /* CI Case AND Non-CI Case
        [Placing TPP Brokerage]
        Non-CI Case => PlacingTPPBrkge__c = TotalBrkg__c * (PlacingSharingPct__c / 100)
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'PlacingTPPBrkge__c',
                        'ctx_isTreaty == true ? PlacingTPPBrkge__c : round(nvl(TotalBrkg__c,0) * (nvl(PlacingSharingPct__c,0)/100), 2)',
                        new List<String>{ 'ctx_isTreaty', 'TotalBrkg__c', 'PlacingSharingPct__c' },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        CI Case
        producing (-) - 다른 케이스와 동일 수식
        [To Producing Admin Fee] ToProducingAdminFee__c = - (TotalBrkg__c * ProducingTPPAdminFeePct__c(%))
        NON CI Case
        [to Producing (-)] ToProducingAdminFee__c = - (TotalBrkg__c - ProducingTPPBrkg__c) * (ProducingTPPAdminFeePct__c / 100)
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'ToProducingAdminFee__c',
                        'ctx_isTreaty == true ? ToProducingAdminFee__c : round(-1 * (nvl(TotalBrkg__c,0) - nvl(ProducingTPPBrkg__c,0)) * (nvl(ProducingTPPAdminFeePct__c,0)/100), 2)',
                        new List<String>{ 'ctx_isTreaty', 'TotalBrkg__c', 'ProducingTPPBrkg__c', 'ProducingTPPAdminFeePct__c' },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [to LK (+)] ToLKAdminFee__c = [Placing TPP] * [Placing TPP Admin Fee %]
        PlacingTPPBrkge__c * PlacingTPPAdminFeePct__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'ToLKAdminFee__c',
                        'ctx_isTreaty == true ? ToLKAdminFee__c : round(nvl(PlacingTPPBrkge__c,0) * (nvl(PlacingTPPAdminFeePct__c,0)/100), 2)',
                        new List<String>{ 'ctx_isTreaty', 'PlacingTPPBrkge__c', 'PlacingTPPAdminFeePct__c' },
                        'num',
                        2
                )
        );
    }

    /**
     * @description 일반(Non-CICase)에 적용되는 표준 계산 규칙 정의
     *              Gross Prem, Total Brokerage, Net To UW 등 산출식
     * @param ruleSet 규칙을 담을 RuleSet 객체
     */
    private static void addStandardCalcRules(RuleSet ruleSet) {

        /*
        [2026-04-19 산출식 변경] GrossPrem__c
        SUM(TSI Gross Prem) = ctx_tsiGrossPremDPFull + ctx_tsiGrossPremDPAdjustable (통화별)

        1. Transaction Type = END && !SOA
           1.1. Type__c = QS  → SUM(TSI Gross Prem)
           1.2. Type__c ≠ QS  → SUM(TSI Gross Prem) * ActualAdjRatePct__cActualAdjRatePct__c * ctx_proration
        2. Transaction Type = Declaration && SOA
           → ctx_grossPremDeclaration (+ DPPct__c = 100 고정)
        3. Transaction Type contains New
           3.1. !SOA && Type__c = QS   → SUM(TSI Gross Prem)
           3.2. !SOA && Type__c ≠ QS   → 일반 수식: ((ctx_tsiSumDPAdjustable * DPPct/100) + ctx_tsiSumDPFull) * ActualAdjRatePct
           3.3. SOA                    → 0
        4. ELSE (Opportunity 등)       → 일반 수식
         */
        /*

  'ctx_isTreaty == true ? nvl(GrossPrem__c, 0) : (' +
      // 기존 산출식...
  ')' END && <> QS 일때 => (GrossPremDP__c * 100% * (SUM(TSI의 Actual Adj Rate (after DP)) / (TSI의 SUM(Gross Prem Before DP)) * 100

         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'GrossPrem__c',
                        'ctx_isTreaty == true ? GrossPrem__c : ctx_isPlacementEND == true && ctx_isSOA != true ? (' +
                                'Type__c == \'QS\' ? ' +
                                'round(nvl(ctx_tsiGrossPrem,0), 2) : ' +
                                'round(nvl(ctx_tsiGrossPrem,0) * (nvl(ActualAdjRatePct__c,0)/100) * nvl(ctx_proration,0), 2)' +
                                ') : (' +
                                'ctx_isDeclaration == true && ctx_isSOA == true ? ' +
                                'round(nvl(ctx_grossPremDeclaration,0), 2) : (' +
                                'ctx_isNew == true && ctx_isSOA == true ? 0 : (' +
                                'ctx_isNew == true && ctx_isSOA != true && Type__c == \'QS\' ? ' +
                                'round(nvl(ctx_tsiGrossPrem,0), 2) : ' +
//                                'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)),2) ' +
                                'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * (nvl(ActualAdjRatePct__c,0)/100), 2)' +
                                ')' +
                                ')' +
                                ')',

                        new List<String>{
                                'ctx_isTreaty', 'Type__c', 'DPPct__c', 'ActualAdjRatePct__c',
                                'ctx_tsiSumDPAdjustable', 'ctx_tsiSumDPFull',
                                'ctx_tsiGrossPrem',
                                'ctx_isPlacementEND', 'ctx_isNew', 'ctx_isSOA', 'ctx_isDeclaration',
                                'ctx_grossPremDeclaration', 'ctx_proration'
                        },
                        'num',
                        2
                )
        );
/* [2026-04-20]
        ruleSet.calcRules.add(
                new CalcRule(
                        'GrossPrem__c',
                        'ctx_isPlacementEND == true && ctx_isSOA != true ? (' +
                                'Type__c == \'QS\' ? ' +
                                'round(nvl(ctx_tsiGrossPremDPFull,0) + nvl(ctx_tsiGrossPremDPAdjustable,0), 2) : ' +
                                'round((nvl(ctx_tsiGrossPremDPFull,0) + nvl(ctx_tsiGrossPremDPAdjustable,0)) * (nvl(ActualAdjRatePct__c,0)/100) * nvl(ctx_proration,0), 2)' +
                                ') : (' +
                                'ctx_isDeclaration == true && ctx_isSOA == true ? ' +
                                'round(nvl(ctx_grossPremDeclaration,0), 2) : (' +
                                'ctx_isNew == true && ctx_isSOA == true ? 0 : (' +
                                'ctx_isNew == true && ctx_isSOA != true && Type__c == \'QS\' ? ' +
                                'round(nvl(ctx_tsiGrossPremDPFull,0) + nvl(ctx_tsiGrossPremDPAdjustable,0), 2) : ' +
                                'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * (nvl(ActualAdjRatePct__c,0)/100), 2)' +
                                ')' +
                                ')' +
                                ')',

                        new List<String>{
                                'Type__c', 'DPPct__c', 'ActualAdjRatePct__c',
                                'ctx_tsiSumDPAdjustable', 'ctx_tsiSumDPFull',
                                'ctx_tsiGrossPremDPFull', 'ctx_tsiGrossPremDPAdjustable',
                                'ctx_isPlacementEND', 'ctx_isNew', 'ctx_isSOA', 'ctx_isDeclaration',
                                'ctx_grossPremDeclaration', 'ctx_proration'
                        },
                        'num',
                        2
                )
        );
 */
//                        'GrossPrem__c',
//                        'ctx_isPlacementRecord != true ? ' +
//                                'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * nvl(ActualAdjRatePct__c,0), 2) : (' +
//                                'ctx_isPlacementEND == true ? ' +
//                                        'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * nvl(ActualAdjRatePct__c,0) * nvl(ctx_proration,0), 2) : (' +
//                                'ctx_isDeclaration == true ? ' +
//                                        'round(nvl(ctx_grossPremDeclaration,0) * nvl(ActualAdjRatePct__c,0), 2) : ' +
//                                        'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * nvl(ActualAdjRatePct__c,0), 2)' +
//                                ')' +
//                        ')',
//        ruleSet.calcRules.add(
//                new CalcRule(
//                        'GrossPrem__c',
//                        'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * nvl(ActualAdjRatePct__c,0), 2)',
//                        'round(((nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0)/100) + nvl(ctx_tsiSumDPFull,0)) * (nvl(ActualAdjRatePct__c,0)/100), 2)',
//                        new List<String>{
//                                'ctx_tsiSumDPAdjustable', 'ctx_tsiSumDPFull', 'DPPct__c', 'ActualAdjRatePct__c'
//                        },
//                        'num',
//                        2
//                )
//        );
        /* [DPPct__c] Declaration && SOA → 100 고정, ELSE → Key-In */
        ruleSet.calcRules.add(
                new CalcRule(
                        'DPPct__c',
                        'ctx_isTreaty == true ? DPPct__c : ctx_isDeclaration == true && ctx_isSOA == true ? 100 : nvl(DPPct__c, 0)',
                        new List<String>{
                                'ctx_isTreaty', 'ctx_isDeclaration', 'ctx_isSOA'
                        },
                        'num',
                        2
                )
        );
        /* [GrossPremDP__c] Gross Prem (Before DP)
          1. Declaration                          → ctx_grossPremDeclaration
          2. New && SOA                           → null
          3. END && !QS                           → null
          4. (END || (New && !SOA)) && QS         → ctx_tsiGrossPremBfDP
          5. ELSE                                 → nvl(GrossPremDP__c, 0)  (Key-In)
        */
        ruleSet.calcRules.add(
                new CalcRule(
                        'GrossPremDP__c',
                        'ctx_isTreaty == true ? GrossPremDP__c : ctx_isDeclaration == true ? ' +
                                'round(nvl(ctx_grossPremDeclaration, 0), 2) : (' +
                                'ctx_isNew == true && ctx_isSOA == true ? ' +
                                'null : (' +
                                'ctx_isPlacementEND == true && Type__c != \'QS\' ? ' +
                                'null : (' +
                                '(ctx_isPlacementEND == true || (ctx_isNew == true && ctx_isSOA != true)) && Type__c == \'QS\' ? ' +
                                'round(nvl(ctx_tsiGrossPremBfDP, 0), 2) : ' +
                                'nvl(GrossPremDP__c, 0)' +
                                ')' +
                                ')' +
                                ')',
                        new List<String>{
                                'ctx_isTreaty', 'Type__c',
                                'ctx_isPlacementEND', 'ctx_isNew', 'ctx_isSOA', 'ctx_isDeclaration',
                                'ctx_grossPremDeclaration', 'ctx_tsiGrossPremBfDP', 'ctx_isNew', 'ctx_isSOA'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [Total Brokerage] TotalBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'TotalBrkg__c',
                        '(CO_is__c || BrkgAdj_is__c) ? 0 : ctx_isTreaty == true ? TotalBrkg__c : ' +
                                'choose(BrkgBase__c,' +
                                '\'Gross\', round(nvl(GrossPrem__c,0) * (nvl(Signed__c,0)/100) * (nvl(TotalBrkgPct__c,0)/100), 2),' +
                                '\'Net\', round((nvl(GrossPrem__c,0) * (1 - (nvl(RICommPct__c,0)/100) - (nvl(OtherDeductionPct__c,0)/100))) * (nvl(Signed__c,0)/100) * (nvl(TotalBrkgPct__c,0)/100), 2),' +
                                'null) ',
                        new List<String>{
                                'ctx_isTreaty',
                                'CO_is__c',
                                'BrkgAdj_is__c',
                                'BrkgBase__c',
                                'GrossPrem__c',
                                'Signed__c',
                                'TotalBrkgPct__c',
                                'RICommPct__c',
                                'OtherDeductionPct__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [Net to LK Prem]
        IF( ((1 AND 2 AND 3 AND 4) OR (5 AND 6 AND 7 AND 8)) => [Net to Producing Co-broker] - [Producing TPP] - [Producing TPP (LK)] + [to Producing (-)]
        ELSE [Total Brokerage]
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetToLKPrem__c',
                        // 1. CO 또는 BrkgAdj 케이스
                        '(CO_is__c || BrkgAdj_is__c) ? 0 : ctx_isTreaty == true ? NetToLKPrem__c : (' +
                                // 2. 기존 공식
                                'ctx_hasProducingTogetherClient ? ' +
                                '(round(nvl(NetProducingCobrker__c,0) - nvl(ProducingTPPBrkg__c,0) - nvl(LKProducingTPPBrkg__c,0) + nvl(ToProducingAdminFee__c,0), 2)) : ' +
                                '(round(nvl(GrossPrem__c,0) * (1 - (nvl(RICommPct__c,0)/100) - (nvl(OtherDeductionPct__c,0)/100)) * (nvl(Signed__c,0)/100), 2)' +
                                '))',
                        new List<String>{
                                'ctx_isTreaty',
                                'CO_is__c',
                                'BrkgAdj_is__c',
                                'ctx_hasProducingTogetherClient',
                                'NetProducingCobrker__c',
                                'ProducingTPPBrkg__c',
                                'LKProducingTPPBrkg__c',
                                'ToProducingAdminFee__c',
                                'TotalBrkg__c',
                                'GrossPrem__c',
                                'RICommPct__c',
                                'OtherDeductionPct__c',
                                'Signed__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [Net to UW] NetToUW__c = GrossPrem__c * (1 - RICommPct__c/100 - OtherDeductionPct__c/100) * (Signed__c/100) - TotalBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetToUW__c',
                        'ctx_isTreaty == true ? NetToUW__c : (round( ' +
                                '(nvl(GrossPrem__c,0) * (1 - (nvl(RICommPct__c,0)/100) - (nvl(OtherDeductionPct__c,0)/100)) * (nvl(Signed__c,0)/100)) ' +
                                '- nvl(TotalBrkg__c,0), ' +
                                '2' +
                                ') )',
                        new List<String>{
                                'ctx_isTreaty',
                                'GrossPrem__c',
                                'RICommPct__c',
                                'OtherDeductionPct__c',
                                'Signed__c',
                                'TotalBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [LK Re Brokerage] LKReBrkge__c
        i. CI Case: [Total Brokerage] – ([Placing TPP] – [Placing TPP (LK)])
        ii. NON CI Case: TotalBrkg__c - ProducingTPPBrkg__c - LKProducingTPPBrkg__c - PlacingTPPBrkge__c - LKPlacingTPPBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKReBrkge__c',
                        'ctx_isTreaty == true ? LKReBrkge__c : round(nvl(TotalBrkg__c,0) - nvl(ProducingTPPBrkg__c,0) - nvl(LKProducingTPPBrkg__c,0) - nvl(PlacingTPPBrkge__c,0) - nvl(LKPlacingTPPBrkg__c,0), 2)',
                        new List<String>{
                                'ctx_isTreaty',
                                'TotalBrkg__c',
                                'ProducingTPPBrkg__c',
                                'LKProducingTPPBrkg__c',
                                'PlacingTPPBrkge__c',
                                'LKPlacingTPPBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [Producing TPP Brokerage] ProducingTPPBrkg__c = TotalBrkg__c * (ProducingSharingPct__c / 100)
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'ProducingTPPBrkg__c',
                        'ctx_isTreaty == true ? ProducingTPPBrkg__c : round(nvl(TotalBrkg__c,0) * (nvl(ProducingSharingPct__c,0)/100), 2)',
                        new List<String>{
                                'ctx_isTreaty', 'TotalBrkg__c', 'ProducingSharingPct__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [Producing TPP (LK)] LKProducingTPPBrkg__c = (TotalBrkg__c - PlacingTPPBrkge__c) * (LKProducingSharingPct__c / 100)
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKProducingTPPBrkg__c',
                        'ctx_isTreaty == true ? LKProducingTPPBrkg__c : round((nvl(TotalBrkg__c,0) - nvl(PlacingTPPBrkge__c,0)) * (nvl(LKProducingSharingPct__c,0)/100), 2)',
                        new List<String>{
                                'ctx_isTreaty', 'TotalBrkg__c', 'PlacingTPPBrkge__c', 'LKProducingSharingPct__c'
                        },
                        'num',
                        2
                )
        );
        /*
        [LK TPP Brokerage] LKTPPBrkge__c = ( [Total Brokerage] – [Producing TPP Brokerage] – [Placing TPP Brokerage ] ) * [LK Co-brk Shaing%]
        1. Total Brokerage: OPP_Panel__c.TotalBrkg__c (산출값)
        2. Producing TPP Brokerage: OPP_Panel__c.ProducingTPPBrkg__c (산출값)
        3. Placing TPP Brokerage: OPP_Panel__c.PlacingTPPBrkge__c (산출값)
        4. LK Co-brk Shaing%: SUM(OPP_Cobroker__c.SharingPct__c)/100 => ctx_lkPlacingSharingPct
           4.1. OPP_Cobroker__c.LKCobroking_is__c = TRUE
           4.2. OPP_Cobroker__c.CobrokingType__c='Placing'
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKTPPBrkge__c',
                        'ctx_isTreaty == true ? LKTPPBrkge__c : round((nvl(TotalBrkg__c,0) - nvl(ProducingTPPBrkg__c,0) - nvl(PlacingTPPBrkge__c,0)) * (nvl(ctx_lkPlacingSharingPct,0)/100), 2)',
                        new List<String>{
                                'ctx_isTreaty',
                                'TotalBrkg__c',
                                'ProducingTPPBrkg__c',
                                'PlacingTPPBrkge__c',
                                'ctx_lkPlacingSharingPct'
                        },
                        'num',
                        2
                )
        );

        /* 2026-02-11
         * [Net to RI] NetRI__c
            IF( (1 AND 2) OR (3 AND 4 AND 5)) => 0
            ELSE [Net to UW]

            1. OPP_Panel__c.CoBroker_lk__c <> Null
            2. OPP_Panel__C.SettlementType__c → PlacingSettlementType__c = 'Together'

            3. OPP_Cobroker__c.LKCobroking_is__c = TRUE
            4. OPP_Cobroker__c.CobrokingType__c='Placing'
            5. OPP_Cobroker__c.PlacingSettlementType__c = 'Together'

            Net to UW : OPP_Panel__c.NetToUW__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetRI__c',
                        'ctx_isTreaty == true ? NetRI__c : choose(true, ' +
                                '((CoBroker_lk__c != null && PlacingSettlementType__c == \'Together\') || ctx_hasLKPlacingTogether), 0, ' +
                                'nvl(NetToUW__c,0)' +
                                ')',
                        new List<String>{
                                'ctx_isTreaty',
                                'CoBroker_lk__c',
                                'PlacingSettlementType__c',
                                'ctx_hasLKPlacingTogether',
                                'NetToUW__c'
                        },
                        'num',
                        2
                )
        );
        /*
            1. LK Admin Fee: ( [Total Brokerage] – [Producing TPP Brokerage] – [Placing TPP Brokerage] ) * [LK Admin Fee%]
               1.1. Total Brokerage: OPP_Panel__c.TotalBrkg__c (산출값)
               1.2. Producing TPP Brokerage: OPP_Panel__c.ProducingTPPBrkg__c (산출값)
               1.3. Placing TPP Brokerage: OPP_Panel__c.PlacingTPPBrkg__c (산출값)
               1.4. LK Admin Fee%: SUM(OPP_Cobroker__c.LKAdminFeePct__c)/100
                 1.4.1. OPP_Cobroker__c.LKCobroking_is__c = FALSE
                 1.4.2. OPP_Cobroker__c.CobrokingType__c='Producing'"
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKAdminFee__c',
                        'ctx_isTreaty == true ? LKAdminFee__c : round( (nvl(TotalBrkg__c,0) - nvl(ProducingTPPBrkg__c,0) - nvl(PlacingTPPBrkge__c,0)) * (ctx_producingAdminFeePct/100), 2)',
                        new List<String>{
                                'ctx_isTreaty',
                                'TotalBrkg__c',
                                'ProducingTPPBrkg__c',
                                'PlacingTPPBrkge__c',
                                'ctx_producingAdminFeePct'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
            [Net to Producing TPP] NetProducingTPP__c
            IF ( 1 AND 2 AND 3 AND 4) => [Producing TPP]
            ELSE 0

            1. OPP_Cobroker__c.LKCobroking_is__c = FALSE
            2. OPP_Cobroker__c.CobrokingType__c='Producing'
            3. OPP_Cobroker__c.SettlementType__c = "Separate"
            4. OPP_Cobroker__c.Client__c__c = FALSE

            Producing TPP: OPP_Panel__c.ProducingTPPBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetProducingTPP__c',
//                        'choose(ctx_hasProducingSeparateNonClient, nvl(ProducingTPPBrkg__c,0), ' + '0' + ')',
                        'choose(true, ctx_hasProducingSeparateNonClient, nvl(ProducingTPPBrkg__c,0), 0)',
                        new List<String>{
                                'ctx_hasProducingSeparateNonClient', 'ProducingTPPBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
            [Net to Producing TPP (LK)] LKNetProducingTPP__c
            IF( 1 AND 2 AND 3 AND 4) => Producing TPP (LK)
            ELSE 0

            1. OPP_Cobroker__c.LKCobroking_is__c = TRUE
            2. OPP_Cobroker__c.CobrokingType__c='Producing'
            3. OPP_Cobroker__c.SettlementType__c = "Separate"
            4. OPP_Cobroker__c.Client__c__c = FALSE

            Producing TPP (LK) : OPP_Panel__c.LKProducingTPPBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKNetProducingTPP__c',
//                        'choose(ctx_hasLKProducingSeparateNonClient, nvl(LKProducingTPPBrkg__c,0), ' + '0' + ')',
                        'choose(true, ctx_hasLKProducingSeparateNonClient, nvl(LKProducingTPPBrkg__c,0), 0)',
                        new List<String>{
                                'ctx_hasLKProducingSeparateNonClient', 'LKProducingTPPBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        //  CI Case:  PlacingTPPBrkge__c + ToLKAdminFee__c ( Placing TPP - to LK (+))
            NON CI Case:
         * [Net to Placing TPP] NetPlacingTPP__c
            IF( 1 AND 2 ) => [Net to UW] + [Placing TPP] - [to LK (+)]
            ELSE  [Placing TPP] - [to LK (+)]

            1. OPP_Panel__c.CoBroker_lk__c <> Null
            2. OPP_Panel__C.SettlementType__c → PlacingSettlementType__c = 'Together'

            Net to UW : OPP_Panel__c.NetToUW__c
            Placing TPP: OPP_Panel__c.PlacingTPPBrkge
            to LK (+): OPP_Panel__c.ToLKAdminFee__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetPlacingTPP__c',
                        'ctx_isTreaty == true ? NetPlacingTPP__c : choose(true, ' +
                                '(CoBroker_lk__c != null && PlacingSettlementType__c == \'Together\'), ' + // 조건 (케이스1)
                                'round(nvl(NetToUW__c,0) + nvl(PlacingTPPBrkge__c,0) - nvl(ToLKAdminFee__c,0), 2), ' + // 참 결과 (결과1)
                                'round(nvl(PlacingTPPBrkge__c,0) - nvl(ToLKAdminFee__c,0), 2)' + // 거짓 결과 (기본값)
                                ')',
                        new List<String>{
                                'ctx_isTreaty',
                                'CoBroker_lk__c',
                                'PlacingSettlementType__c',
                                'NetToUW__c',
                                'PlacingTPPBrkge__c',
                                'ToLKAdminFee__c'
                        },
                        'num',
                        2
                )
        );
        /*
        NetProducingCobrker__c
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetProducingCobrker__c',
                        // 1. BrkgAdj 케이스
                        'CO_is__c ? 0 : (BrkgAdj_is__c ? ( (ctx_hasLKProducingTogetherClient || ctx_hasProducingTogetherClient ) ? nvl(TotalBrkg__c,0) : 0 ) : ' +
                                '( ctx_hasProducingTogetherClient ? ' +
                                'round(nvl(GrossPrem__c,0) * (1 - (nvl(RICommPct__c,0)/100) - (nvl(OtherDeductionPct__c,0)/100)) * (nvl(Signed__c,0)/100), 2) : 0 ))',
                        new List<String>{
                                'CO_is__c',
                                'BrkgAdj_is__c',
                                'ctx_hasLKProducingTogetherClient',
                                'ctx_hasProducingTogetherClient',
                                'TotalBrkg__c',
                                'GrossPrem__c',
                                'RICommPct__c',
                                'OtherDeductionPct__c',
                                'Signed__c'
                        },
                        'num',
                        2
                )
        );
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetProducingCobrker__c',
                        // 1. BrkgAdj 케이스
                        '(CO_is__c || BrkgAdj_is__c) ? 0 : ctx_isTreaty == true ? NetProducingCobrker__c : ' +
                                '(ctx_hasProducingTogetherClient ? ' +
                                '( round(nvl(GrossPrem__c,0) * (1 - (nvl(RICommPct__c,0)/100) - (nvl(OtherDeductionPct__c,0)/100)) * (nvl(Signed__c,0)/100), 2)) : 0 )',
                        new List<String>{
                                'ctx_isTreaty',
                                'CO_is__c',
                                'BrkgAdj_is__c',
                                'ctx_hasProducingTogetherClient',
                                'GrossPrem__c',
                                'RICommPct__c',
                                'OtherDeductionPct__c',
                                'Signed__c'
                        },
                        'num',
                        2
                )
        );
        /*
        2026-02-11
        LKPlacingTPPBrkg__c
        NON CI CASE: LKPlacingTPPBrkg__c = (TotalBrkg__c - LKProducingTPPBrkg__c) * (LKPlacingSharingPct__c / 100)
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKPlacingTPPBrkg__c',
                        'ctx_isTreaty == true ? LKPlacingTPPBrkg__c : round((nvl(TotalBrkg__c,0) - nvl(LKProducingTPPBrkg__c,0)) * (nvl(LKPlacingSharingPct__c,0)/100), 2)',
                        new List<String>{
                                'ctx_isTreaty', 'TotalBrkg__c', 'LKProducingTPPBrkg__c', 'LKPlacingSharingPct__c'
                        },
                        'num',
                        2
                )
        );
        /*
        [Co-Broking Type] CobrokingType__c
         */
        ruleSet.calcRules.add(new CalcRule(
                'CobrokingType__c',
                'CO_is__c ? \'CO\' : (BrkgAdj_is__c ? null : ' +
                        'choose(true, ' +
                        '(nvl(ctx_hasProducingTogetherClient,false) && CoBroker_lk__c != null && PlacingSettlementType__c == \'Together\'), ' +
                        '\'CPT-CPO\', ' +
                        '(nvl(ctx_hasProducingTogetherClient,false) && CoBroker_lk__c != null && PlacingSettlementType__c == \'Separate\'), ' +
                        '\'CPT-CPS\', ' +
                        '(nvl(ctx_noPlacingRecords,false) && nvl(ctx_hasProducingTogetherClient,false) && CoBroker_lk__c == null), ' +
                        '\'CPT\', ' +
                        '(nvl(ctx_noPlacingRecords,false) && nvl(ctx_hasProducingSeparateClient,false) && CoBroker_lk__c == null), ' +
                        '\'CI\', ' +
                        '(nvl(ctx_noPlacingRecords,false) && nvl(ctx_hasLKProducingSeparateClient,false) && CoBroker_lk__c == null), ' +
                        '\'CI\', ' +
                        '(nvl(ctx_noProducingRecords,false) && PlacingSettlementType__c == \'Together\'), ' +
                        '\'CPO\', ' +
                        '(nvl(ctx_noProducingRecords,false) && nvl(ctx_hasLKPlacingTogether,false)), ' +
                        '\'CPO\', ' +
                        '(nvl(ctx_noProducingRecords,false) && nvl(ctx_hasLKPlacingSeparate,false)), ' +
                        '\'None\', ' +
                        '(nvl(ctx_noCoBrokerRecords,false) && PlacingSettlementType__c == \'Separate\'), ' +
                        '\'CPS\', ' +
                        '(nvl(ctx_noCoBrokerRecords,false) && CoBroker_lk__c == null), ' +
                        '\'None\', ' +
                        'null' +
                        '))',
                new List<String>{
                        'CO_is__c',
                        'BrkgAdj_is__c',
                        'ctx_hasProducingTogetherClient',
                        'ctx_hasProducingSeparateClient',
                        'ctx_hasPlacingTogether',
                        'ctx_hasLKProducingSeparateClient',
                        'ctx_hasLKPlacingSeparate',
                        'ctx_noCoBrokerRecords',
                        'ctx_noPlacingRecords',
                        'ctx_noProducingRecords',
                        'CoBroker_lk__c',
                        'PlacingSettlementType__c',
                        'ctx_hasLKPlacingTogether'
                },
                'text',
                null
        ));
        /* 2026-02-11
        Net to Placing TPP (LK)
        (LKNetPlacingTPP__c(16,2))
        IF( (1 AND 2 AND 3 ) => [Net to UW] + [Placing TPP (LK)]
        ELSE [Placing TPP (LK)]

        1. OPP_Cobroker__c.LKCobroking_is__c = TRUE
        2. OPP_Cobroker__c.CobrokingType__c='Placing'
        3. OPP_Cobroker__c.SettlementType__c = "Together"

        Net to UW : OPP_Panel__c.NetToUW__c
        Placing TPP (LK): OPP_Panel__c.LKPlacingTPPBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKNetPlacingTPP__c',
                        'ctx_isTreaty == true ? LKNetPlacingTPP__c : choose(true, ctx_hasLKPlacingTogether, ' +
                                'round(nvl(NetToUW__c,0) + nvl(LKPlacingTPPBrkg__c,0), 2), ' +
                                'nvl(LKPlacingTPPBrkg__c,0)' +
                                ')',
                        new List<String>{
                                'ctx_isTreaty', 'ctx_hasLKPlacingTogether', 'NetToUW__c', 'LKPlacingTPPBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /* [Actual Adj Rate %] Number(12, 2), 2026-04-08 (수) 로직 변경, % 아님..
        1. Opportunity.TrasnactionType__c <> Declaration OR Placement__c.TrasnactionType__c <> Declaration

        [ (①/②) + (③/④)]*(Panel의 Gross Prem Before DP)/(C+D)
        ActualAdjRatePct__c = (((E*A)/(A+(B * ( OPP_Panel__c.DPPct__c/100)))) + ((F * B * OPP_Panel__c.DPPct__c/100) /(A + (B * (OPP_Panel__c.DPPct__c/100))))) *
(Panel의 Gross Prem Before DP)/(C+D))
(((E*A)/(A+(B * ( OPP_Panel__c.DPPct__c/100)))) + ((F * B * OPP_Panel__c.DPPct__c/100) /(A + (B * (OPP_Panel__c.DPPct__c/100))))) * (Panel의 Gross Prem Before DP)/(C+D))

        ① E * A
        ② A +[B*(Panel의 DP%)]
        ③ F * B*(Panel의 DP%)
        ④ A+[B*(Panel의 DP%)]

        A. TSI Insured Amount (DP=100%) : DP =100%인 Insured Amount SUM
        B. TSI Insured Amount (DP<>100%) : DP<>100%인 Insured Amount SUM

        C. TSI Gross Prem (Before DP) DP= 100% : DP =100%인  Gross Prem (Before DP) SUM
        D. TSI Gross Prem (Before DP) DP<> 100% : DP <>100%인  Gross Prem (Before DP) SUM

        E. Gross Rate(%) [DP =100%] : C/A
        F. Gross Rate(%) [DP <> 100%] : IF B =0, 0 ELSE D/B

        2. Opportunity.TrasnactionType__c = Declaration
        회신대기
         */
        /*
        [2026-04-11(토)] 아래 최신 로직을 배포하지 않기로 결정했음
        혹시 다시 활성화했을때 수정 필요한 곳
          1. OPP_MarketLineRuleService.cls — 747~773 주석 해제, 784~806 주석 처리
          2. OPP_MarketLineService.cls (line 513~516) — 동일 공식으로 변경 + insuredAmt 대신 ctx_tsiSumDPFull, ctx_tsiSumDPAdjustable, ctx_tsiGrossPremDPFull, ctx_tsiGrossPremDPAdjustable 기반 계산
          3. oppMarketLineCalc.js (line 212~215) — JS에서 동일 공식 + context에서 해당 변수 참조
        ruleSet.calcRules.add(
                new CalcRule(
                        'ActualAdjRatePct__c',
                        'ctx_isDeclaration == true ? null : (' +
                                '(nvl(ctx_tsiGrossPremDPFull,0) + nvl(ctx_tsiGrossPremDPAdjustable,0)) == 0 ? 0 : (' +
                                '(nvl(ctx_tsiSumDPFull,0) + nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0) / 100) == 0 ? 0 : ' +
                                'round(' +
                                '(nvl(ctx_tsiGrossPremDPFull,0) + nvl(ctx_tsiGrossPremDPAdjustable,0) * nvl(DPPct__c,0) / 100) ' +
                                '/ (nvl(ctx_tsiSumDPFull,0) + nvl(ctx_tsiSumDPAdjustable,0) * nvl(DPPct__c,0) / 100) ' +
                                '* nvl(GrossPremDP__c,0) ' +
                                '/ (nvl(ctx_tsiGrossPremDPFull,0) + nvl(ctx_tsiGrossPremDPAdjustable,0))' +
                                ', 6)' +
                                ')' +
                                ')',
                        new List<String>{
                                'GrossPremDP__c',
                                'DPPct__c',
                                'ctx_isDeclaration',
                                'ctx_tsiSumDPFull',
                                'ctx_tsiSumDPAdjustable',
                                'ctx_tsiGrossPremDPFull',
                                'ctx_tsiGrossPremDPAdjustable'
                        },
                        'num',
                        6
                )
        );
        */
        /* [Actual Adj Rate (%)]
        ActualAdjRatePct__c= "기회 총액 / ∑패널(NetToLKPrem)"
        IF( Brokerage Base =  Gross ) => Gross Prem(Before DP)/ TSI
        ELSE  [(1-RI Comm(%) - Other Deduction (%) )* Gross Prem(Before DP)] / TSI

        Gross Prem (Before DP) : OPP_Panel__c.GrossPremDP__c (산출값)
        RI Comm%: (OPP_Panel__c.RICommPct__c/100) (User Input)
        Other Deduction%: (OPP_Panel__c.OtherDeductionPct__c/100) (User Input)
        TSI : Prem Currency가 일치하는 TSI by Location의 Insured Amount SUM
         */
        /* [2026-04-09 기존 산출식]
        ruleSet.calcRules.add(
                new CalcRule(
                        'ActualAdjRatePct__c',
                        'ctx_isDeclaration == true ? null : (' +
                                'nvl(ctx_currentTSI,0) == 0 ? 0 : (' +
                                'BrkgBase__c == \'Gross\' ? round(nvl(GrossPremDP__c,0) / ctx_currentTSI, 6) : (' +
                                'BrkgBase__c == \'Net\' ? round((1 - (nvl(RICommPct__c,0)/100) - (nvl(OtherDeductionPct__c,0)/100)) * nvl(GrossPremDP__c,0) / ctx_currentTSI, 6) : ' +
                                '0' +
                                ')' +
                                ')' +
                                ')',
                        new List<String>{
                                'BrkgBase__c',
                                'GrossPremDP__c',
                                'ctx_currentTSI',
                                'RICommPct__c',
                                'OtherDeductionPct__c',
                                'ctx_isDeclaration'
                        },
                        'num',
                        6
                )
        );
        */
        /* [2026-04-19 산출식 변경] ActualAdjRatePct__c
           = GrossPremDP__c * SUM(TSI Actual Adj Rate After DP) / SUM(TSI Gross Prem Before DP)
           - TSI Actual Adj Rate (After DP) = InsuredAmount * DPPct * GrossRatePct / B
           - B = SUM(InsuredAmount * DPPct)

           ctx_tsiActualAdjAfterDP = SUM(InsuredAmount * DPPct/100 * GrossRatePct/100) (통화별)
           ctx_tsiDPAppliedSum     = SUM(InsuredAmount * DPPct/100)                    (통화별)
           ctx_tsiGrossPremBfDP    = SUM(GrossPremBfDP_fm__c)                          (통화별)
        *///
//        ruleSet.calcRules.add(
//                new CalcRule(
//                        'ActualAdjRatePct__c',
//                        'ctx_isTreaty == true ? ActualAdjRatePct__c : ctx_isDeclaration == true ? null : (' +
//                                'nvl(ctx_tsiGrossPremBfDP,0) == 0 || nvl(ctx_tsiDPAppliedSum,0) == 0 ? 0 : ' +
////                                'round((nvl(GrossPremDP__c,0) * nvl(ctx_tsiActualAdjAfterDP,0) / nvl(ctx_tsiDPAppliedSum,0) / (nvl(ctx_tsiGrossPremBfDP,0) * 100)), 6)' +
//                                'round( ( nvl(GrossPremDP__c,0) * nvl(ctx_tsiActualAdjAfterDP,0)) / (nvl(ctx_tsiGrossPremBfDP,0))  * 100 , 6)' +
//                                ')',
//                        new List<String>{
//                                'ctx_isTreaty',
//                                'ctx_isDeclaration',
//                                'ctx_tsiGrossPremBfDP',
//                                'ctx_tsiDPAppliedSum',
//                                'GrossPremDP__c',
//                                'ctx_tsiActualAdjAfterDP'
//                        },
//                        'num',
//                        6
//                )
//        );
        /* [2026-04-19 산출식 변경] ActualAdjRatePct__c
        Market Line의 GrossPremDP__c / SUM(TSI by Location의 Insured Amount)
        [2026-04-28] 산출식 변경
        IF (Transaction Type = END & <> QS인 경우) => GrossPremDP__c  / SUM(TSI by Location의 Insured Amount)
        ELSE => (Market Line의 GrossPremDP__c / SUM(TSI by Location의 Insured Amount))*100

         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'ActualAdjRatePct__c',
                        'ctx_isTreaty == true ? ActualAdjRatePct__c : ctx_isPlacementEND == true && Type__c != \'QS\' ? GrossPremDP__c : (' +
                                'nvl(ctx_currentTSI,0) == 0 ? 0 : round( (nvl(GrossPremDP__c,0) / nvl(ctx_currentTSI,0))*100, 18)' +
                                ')',
                        new List<String>{
                                'ctx_isTreaty',
                                'ctx_isPlacementEND',
                                'Type__c',
                                'GrossPremDP__c',
                                'ctx_currentTSI'
                        },
                        'num',
                        18
                )
        );
    }

    /**
     * @description CI Case 케이스에만 특화된 계산 규칙을 정의함.
     *              공동보험 정산 방식에 따른 Net To LK Prem, LK Re Brokerage 등의 전용 수식을 적용함.
     * @param ruleSet 규칙을 담을 RuleSet 객체
     */
    private static void addCICaseCalcRules(RuleSet ruleSet) {
        /* 2026-02-11
        [Total Brokerage] TotalBrkg__c
         */
//                        ruleSet.calcRules.add(
//                                new CalcRule(
//                                        'TotalBrkg__c',
//                                        'choose(BrkgBase__c,' +
//                                                '\'Gross\', round(nvl(GrossPrem__c,0) * (nvl(Signed__c,0)/100) * (nvl(TotalBrkgPct__c,0)/100), 2),' +
//                                                '\'Net\',   round(nvl(NetToLKPrem__c,0) * (nvl(TotalBrkgPct__c,0)/100), 2),' +
//                                                'null)',
//                                        new List<String>{
//                                                'BrkgBase__c', 'GrossPrem__c', 'Signed__c', 'TotalBrkgPct__c', 'NetToLKPrem__c'
//                                        },
//                                        'num',
//                                        2
//                                )
//                        );
        /* 2026-02-11
        [Net to LK Prem]
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetToLKPrem__c',
                        'ctx_isTreaty == true ? NetToLKPrem__c : round(nvl(TotalBrkg__c,0) + nvl(ToProducingAdminFee__c,0), 2)',
                        new List<String>{
                                'ctx_isTreaty', 'TotalBrkg__c', 'ToProducingAdminFee__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        [LK Re Brokerage] LKReBrkge__c
        i. CI Case: [Total Brokerage] – ([Placing TPP] – [Placing TPP (LK)])
        ii. NON CI Case: TotalBrkg__c - ProducingTPPBrkg__c - LKProducingTPPBrkg__c - PlacingTPPBrkge__c - LKPlacingTPPBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKReBrkge__c',
                        'ctx_isTreaty == true ? LKReBrkge__c : round(nvl(TotalBrkg__c,0) - nvl(PlacingTPPBrkge__c,0) - nvl(LKPlacingTPPBrkg__c,0), 2)',
                        new List<String>{
                                'ctx_isTreaty', 'TotalBrkg__c', 'PlacingTPPBrkge__c', 'LKPlacingTPPBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /* 2026-02-11
        //  CI Case:  PlacingTPPBrkge__c + ToLKAdminFee__c ( Placing TPP - to LK (+))
            NON CI Case:
         * [Net to Placing TPP] NetPlacingTPP__c
            IF( 1 AND 2 ) => [Net to UW] + [Placing TPP] - [to LK (+)]
            ELSE  [Placing TPP] - [to LK (+)]

            1. OPP_Panel__c.CoBroker_lk__c <> Null
            2. OPP_Panel__C.SettlementType__c → PlacingSettlementType__c = 'Together'

            Net to UW : OPP_Panel__c.NetToUW__c
            Placing TPP: OPP_Panel__c.PlacingTPPBrkge
            to LK (+): OPP_Panel__c.ToLKAdminFee__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetPlacingTPP__c',
                        'ctx_isTreaty == true ? NetPlacingTPP__c : round(nvl(PlacingTPPBrkge__c,0) - nvl(ToLKAdminFee__c,0), 2)',
                        new List<String>{
                                'ctx_isTreaty', 'PlacingTPPBrkge__c', 'ToLKAdminFee__c'
                        },
                        'num',
                        2
                )
        );
        /* CI Case: Only
        NetProducingCobrker__c
        Non CI Case:
        IF( ctx_hasProducingClientTogethe)) => GrossPrem__c * (1 - RICommPct__c/100 - OtherDeductionPct__c/100) * (Signed__c/100)
        ELSE 0
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'NetProducingCobrker__c',
                        'ctx_isTreaty == true ? NetProducingCobrker__c : nvl(TotalBrkg__c, 0)',
                        new List<String>{
                                'ctx_isTreaty', 'TotalBrkg__c'
                        },
                        'num',
                        2
                )
        );
        /*
        2026-02-11
        LKPlacingTPPBrkg__c
        NON CI CASE: LKPlacingTPPBrkg__c = (TotalBrkg__c - LKProducingTPPBrkg__c) * (LKPlacingSharingPct__c / 100)
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKPlacingTPPBrkg__c',
                        'ctx_isTreaty == true ? LKPlacingTPPBrkg__c : round(nvl(TotalBrkg__c,0) * (nvl(LKPlacingSharingPct__c,0)/100), 2)',
                        new List<String>{
                               'ctx_isTreaty', 'TotalBrkg__c', 'LKPlacingSharingPct__c'
                        },
                        'num',
                        2
                )
        );
        /* CI Case: Only (Non CI Case: User input)
        [Placing Co-broking (LK)] LKPlacingSharingPct__c = ctx_lkPlacingSharingPct
         */
//            ruleSet.calcRules.add(
//                new CalcRule(
//                    'LKPlacingSharingPct__c',
//                    'nvl(ctx_lkPlacingSharingPct, 0)',
//                    new List<String>{ 'ctx_lkPlacingSharingPct' },
//                    'num',
//                    2
//                )
//            );

        /*
        [Co-Broking Type] CobrokingType__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'CobrokingType__c',
                        '\'CI\'',
                        null,
                        'text',
                        null
                )
        );
        /* 2026-02-11
        Net to Placing TPP (LK)
        (LKNetPlacingTPP__c(16,2))
        IF( (1 AND 2 AND 3 ) => [Net to UW] + [Placing TPP (LK)]
        ELSE [Placing TPP (LK)]

        1. OPP_Cobroker__c.LKCobroking_is__c = TRUE
        2. OPP_Cobroker__c.CobrokingType__c='Placing'
        3. OPP_Cobroker__c.SettlementType__c = "Together"

        Net to UW : OPP_Panel__c.NetToUW__c
        Placing TPP (LK): OPP_Panel__c.LKPlacingTPPBrkg__c
         */
        ruleSet.calcRules.add(
                new CalcRule(
                        'LKNetPlacingTPP__c',
                        'ctx_isTreaty == true ? LKNetPlacingTPP__c : nvl(LKPlacingTPPBrkg__c,0)',
                        new List<String>{
                                'ctx_isTreaty', 'LKPlacingTPPBrkg__c'
                        },
                        'num',
                        2
                )
        );

    }

//    private static void addCORowCalcRules(RuleSet ruleSet) {
//    }

    /**
     * @description 등록된 모든 계산 규칙(CalcRule)의 무결성을 검증하고 실행 순서를 결정
     *              1. 필드 존재 여부 및 접근 권한 확인
     *              2. 수식(expression) 내 참조 키(__c, ctx_*)가 dependsOn에 누락되었는지 검사
     *              3. 위상 정렬(Topological Sort)을 통해 필드 간 의존 관계에 따른 최적의 계산 순서(executionOrder) 부여
     *              4. 순환 참조(Circular Dependency) 감지 시 예외 발생
     * @param sObjectApiNames 검증 대상이 되는 SObject API 명칭 목록
     * @param calcRules 검증 및 정렬할 계산 규칙 목록
     * @throws AuraHandledException 필드 미존재, 참조 누락, 순환 참조 등 유효성 실패 시 발생
     */
    public static void validateCalcRules(List<String> sObjectApiNames, List<CalcRule> calcRules) {
        if (sObjectApiNames == null || sObjectApiNames.isEmpty()) {
            throw new AuraHandledException('validateCalcRules: sObjectApiNames is empty');
        }
        if (calcRules == null || calcRules.isEmpty()) return;

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> objectFieldMap = new Map<String, Schema.SObjectField>();
        for (String sObjectApiName : sObjectApiNames) {
            if (String.isBlank(sObjectApiName)) continue;
            if (!globalDescribe.containsKey(sObjectApiName)) {
                throw new AuraHandledException('validateCalcRules: invalid object ' + sObjectApiName);
            }
            objectFieldMap.putAll(globalDescribe.get(sObjectApiName).getDescribe().fields.getMap());
        }

        Map<String, CalcRule> ruleByTargetKey = new Map<String, CalcRule>();
        List<String> errors = new List<String>();

        for (CalcRule rule : calcRules) {
            if (rule == null) continue;

            if (String.isBlank(rule.targetKey)) {
                errors.add('CalcRule.targetKey is blank');
                continue;
            }
            if (String.isBlank(rule.expression)) {
                errors.add('CalcRule.expression is blank (target=' + rule.targetKey + ')');
            }

            if (ruleByTargetKey.containsKey(rule.targetKey)) {
                errors.add('Duplicate CalcRule targetKey: ' + rule.targetKey);
            } else {
                ruleByTargetKey.put(rule.targetKey, rule);
            }

            if (!objectFieldMap.containsKey(rule.targetKey.toLowerCase())) {
                errors.add('CalcRule targetKey not found on ' + sObjectApiNames + ': ' + rule.targetKey);
            }

            if (rule.dependsOn == null) rule.dependsOn = new List<String>();

            for (String dependencyKey : rule.dependsOn) {
                if (String.isBlank(dependencyKey)) continue;

                // ctx_* 는 외부 참조값이므로 필드 존재 검증 제외
                if (dependencyKey.startsWith('ctx_')) continue;

                if (!objectFieldMap.containsKey(dependencyKey.toLowerCase()) && !ruleByTargetKey.containsKey(dependencyKey)) {
                    errors.add('CalcRule dependsOn not found on ' + sObjectApiNames + ': ' + dependencyKey + ' (target=' + rule.targetKey + ')');
                }
            }

            // expression 내 참조 키(__c, ctx_*) 추출 → dependsOn 누락 검증
            Set<String> referencedKeysInExpression = extractReferencedKeys(rule.expression);
            for (String referencedKey : referencedKeysInExpression) {
                Boolean isCtx = referencedKey != null && referencedKey.startsWith('ctx_');

                Boolean existsAsField = objectFieldMap.containsKey(referencedKey.toLowerCase());
                Boolean existsAsRuleTarget = ruleByTargetKey.containsKey(referencedKey);

                if (!isCtx && !existsAsField && !existsAsRuleTarget) {
                    errors.add('CalcRule expression references unknown key: ' + referencedKey + ' (target=' + rule.targetKey + ')');
                    continue;
                }

                if (referencedKey != rule.targetKey && !rule.dependsOn.contains(referencedKey)) {
                    errors.add('CalcRule dependsOn missing referenced key: ' + referencedKey + ' (target=' + rule.targetKey + ')');
                }
            }
        }

        System.debug('Validation Errors: ' + String.join(errors, '\n'));
        if (!errors.isEmpty()) {
            throw new AuraHandledException('CalcRules validation failed: ' + String.join(errors, ' | '));
        }

        // dependency graph (rule targetKey 간만)
        Map<String, Set<String>> dependencyGraph = new Map<String, Set<String>>();
        Map<String, Integer> inDegreeByTargetKey = new Map<String, Integer>();

        for (String targetKey : ruleByTargetKey.keySet()) {
            dependencyGraph.put(targetKey, new Set<String>());
            inDegreeByTargetKey.put(targetKey, 0);
        }

        for (CalcRule calcRule : calcRules) {
            if (calcRule == null || String.isBlank(calcRule.targetKey)) continue;

            for (String dependencyKey : calcRule.dependsOn) {
                if (String.isBlank(dependencyKey)) continue;

                if (ruleByTargetKey.containsKey(dependencyKey)) {
                    if (dependencyKey == calcRule.targetKey) {
                        throw new AuraHandledException('CalcRules validation failed: self dependency (target=' + calcRule.targetKey + ')');
                    }
                    dependencyGraph.get(dependencyKey).add(calcRule.targetKey);
                    inDegreeByTargetKey.put(calcRule.targetKey, inDegreeByTargetKey.get(calcRule.targetKey) + 1);
                }
            }
        }

        // 입력 순서 최대 유지
        List<String> sortedTargetKeys = new List<String>();
        Set<String> processed = new Set<String>();

        while (sortedTargetKeys.size() < ruleByTargetKey.size()) {
            Boolean progressed = false;

            for (CalcRule rule : calcRules) {
                if (rule == null || String.isBlank(rule.targetKey)) continue;
                if (processed.contains(rule.targetKey)) continue;

                if (inDegreeByTargetKey.get(rule.targetKey) == 0) {
                    processed.add(rule.targetKey);
                    sortedTargetKeys.add(rule.targetKey);
                    progressed = true;

                    for (String nextTargetKey : dependencyGraph.get(rule.targetKey)) {
                        inDegreeByTargetKey.put(nextTargetKey, inDegreeByTargetKey.get(nextTargetKey) - 1);
                    }
                }
            }

            if (!progressed) {
                throw new AuraHandledException('CalcRules validation failed: circular dependency detected');
            }
        }

        Integer orderCounter = 1;
        for (String targetKey : sortedTargetKeys) {
            ruleByTargetKey.get(targetKey).executionOrder = orderCounter;
            orderCounter++;
        }

        List<CalcRule> sortedRules = new List<CalcRule>();
        for (String targetKey : sortedTargetKeys) {
            sortedRules.add(ruleByTargetKey.get(targetKey));
        }
        calcRules.clear();
        calcRules.addAll(sortedRules);
    }

    // expression에서 "__c" / "ctx_*" 토큰만 추출
    private static Set<String> extractReferencedKeys(String expression) {
        Set<String> keys = new Set<String>();
        if (String.isBlank(expression)) return keys;

        Pattern p = Pattern.compile('\\b(?:[A-Za-z_][A-Za-z0-9_]*__c|ctx_[A-Za-z0-9_]+)\\b');
        Matcher m = p.matcher(expression);

        while (m.find()) {
            keys.add(m.group(0));
        }
        return keys;
    }



}