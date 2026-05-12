/**********************************************************************************
 * @filename      : OPP_Opportunity_tr.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-10 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_Opportunity_tr_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-10      i2max     Create
**********************************************************************************/
public with sharing class OPP_Opportunity_tr extends TriggerHandler {

    public override void beforeUpdate() {
        this.validateBindingDate(Trigger.new, Trigger.oldMap);
    }

//    public override void afterUpdate() {
////        this.createRIOfferSlipOnNegotiating(Trigger.new, Trigger.oldMap);
//    }

    /**
     * @description Reinsurance 배분이 완전히 일치하고, 모든 Reinsurer의 KYC가 완료된 경우에만 Binding Date를 확정 가능
     * BindingDate__c 업데이트 불가 조건
        1. 기회의 BizRegion에 해당하는 법인 KYC 미완료 Reinsurer가 하나라도 존재 (LK_A&G, None은 skip)
        2. Layer 세그먼트별 Signed(%) ≠ Total Order(%) (모든 세그먼트가 Placement Done이어야 통과)
        3. TSI Currency에 해당하는 TSIByLocation(Type=Slip) 레코드가 존재하지 않는 경우
        4. Slip PremCurrency별 PremSchedule(Type=Schedule) 레코드가 존재하지 않는 경우
        5. Slip PremCurrency에 대응하는 Finalize된 Panel이 존재하지 않는 경우
        * Slip 조회: PremiumSchedule(Type=Slip) — 우선순위 1) Cedant Closing(Latest) 2) Cedant Offer(Latest)
        * 예외: CI Case 해당 Validation 제외 (단, 5번만 체크)
     * @param newList List<Opportunity> - Trigger.new에서 넘어온 Opportunity 레코드 목록
     * @param oldMap Map<Id, Opportunity> - Trigger.oldMap에서 넘어온 Opportunity 레코드, 이전 값을 비교할 때 사용
     */
    private void validateBindingDate(List<SObject> newList, Map<Id, SObject> oldMap) {

        Map<Id, Opportunity> opportunitiesByIds = new Map<Id, Opportunity>();
        for (Opportunity newObj : (List<Opportunity>) newList) {
            Opportunity oldObj = (Opportunity) oldMap.get(newObj.Id);
            if (newObj.BindingDate__c <> oldObj.BindingDate__c && newObj.BindingDate__c <> null) opportunitiesByIds.put(newObj.Id, newObj);
        }

        if (!opportunitiesByIds.isEmpty()) {

            Set<Id> oppHasKycIssue = new Set<Id>();
            Set<Id> oppHasPanel = new Set<Id>();

            List<OPP_Panel__c> panels = [
                    SELECT Signed__c, Written__c, Currency__c,
                            Layer_md__c,
                            Layer_md__r.Type__c,
                            Layer_md__r.Opportunity_md__c,
                            Layer_md__r.Excess__c,
                            Layer_md__r.LOL__c,
                            Layer_md__r.LayerCurrency__c,
                            Reinsurer_lk__r.KycCompletedIs_fm__c,
                            Reinsurer_lk__r.KycCompletedKr_is__c,
                            Reinsurer_lk__r.KycCompletedRe_is__c,
                            Reinsurer_lk__r.KycCompletedVn_is__c
                    FROM OPP_Panel__c
                    WHERE Layer_md__r.Opportunity_md__c IN :opportunitiesByIds.keySet()
                    AND Layer_md__r.Placement_lk__c = NULL
                    AND Finalize_is__c = TRUE
                    AND BrkgAdj_is__c = FALSE
                    AND CO_is__c = FALSE
                    AND Currency__c != NULL
            ];

            List<AggregateResult> aggregateResults = [
                    SELECT Opportunity_md__c oppId, COUNT(Id) cnt
                    FROM OPP_Cobroker__c
                    WHERE Opportunity_md__c IN :opportunitiesByIds.keySet()
                    AND Placement_lk__c = NULL
                    AND CobrokingType__c = 'Producing'
                    AND SettlementType__c = 'Separate'
                    AND Client__c = TRUE
                    AND LKCobroking_is__c = FALSE
                    GROUP BY Opportunity_md__c
            ];

            //CI 케이스 체크
            Map<Id, Boolean> isCICaseMap = new Map<Id, Boolean>();
            for (AggregateResult ar : aggregateResults) {
                isCICaseMap.put((Id) ar.get('oppId'), ((Integer) ar.get('cnt')) > 0);
            }

            // 4. Prem Currency별 PremSchedule(Type=Schedule) 존재 여부
            Map<Id, Set<String>> oppScheduleCurrencies = new Map<Id, Set<String>>();
            for (OPP_PremiumSchedule__c ps : [
                    SELECT Opportunity_lk__c, Prem_Currency__c
                    FROM OPP_PremiumSchedule__c
                    WHERE Opportunity_lk__c IN :opportunitiesByIds.keySet()
                    AND Type__c = 'Schedule'
            ]) {
                if (!oppScheduleCurrencies.containsKey(ps.Opportunity_lk__c)) {
                    oppScheduleCurrencies.put(ps.Opportunity_lk__c, new Set<String>());
                }
                oppScheduleCurrencies.get(ps.Opportunity_lk__c).add(ps.Prem_Currency__c);
            }

            // 4,5. Slip(PremiumSchedule Type=Slip)의 PremCurrency__c (Opp별)
            // Slip 조회 우선순위: Cedant Closing → Cedant Offer
            Map<Id, Set<String>> oppSlipCurrencies = new Map<Id, Set<String>>();

            // 1순위: Cedant Closing
            for (OPP_PremiumSchedule__c ps : [
                    SELECT Opportunity_lk__c, Prem_Currency__c
                    FROM OPP_PremiumSchedule__c
                    WHERE Opportunity_lk__c IN :opportunitiesByIds.keySet()
                    AND Type__c = 'Slip'
                    AND SlipInfo_lk__r.Latest_is__c = TRUE
                    AND SlipInfo_lk__r.Type__c = 'Cedant Closing'
            ]) {
                if (!oppSlipCurrencies.containsKey(ps.Opportunity_lk__c)) {
                    oppSlipCurrencies.put(ps.Opportunity_lk__c, new Set<String>());
                }
                oppSlipCurrencies.get(ps.Opportunity_lk__c).add(ps.Prem_Currency__c);
            }

            // 2순위: Cedant Closing이 없는 Opp만 Cedant Offer
            Set<Id> oppWithoutClosing = new Set<Id>(opportunitiesByIds.keySet());
            oppWithoutClosing.removeAll(oppSlipCurrencies.keySet());

            if (!oppWithoutClosing.isEmpty()) {
                for (OPP_PremiumSchedule__c ps : [
                        SELECT Opportunity_lk__c, Prem_Currency__c
                        FROM OPP_PremiumSchedule__c
                        WHERE Opportunity_lk__c IN :oppWithoutClosing
                        AND Type__c = 'Slip'
                        AND SlipInfo_lk__r.Latest_is__c = TRUE
                        AND SlipInfo_lk__r.Type__c = 'Cedant Offer'
                ]) {
                    if (!oppSlipCurrencies.containsKey(ps.Opportunity_lk__c)) {
                        oppSlipCurrencies.put(ps.Opportunity_lk__c, new Set<String>());
                    }
                    oppSlipCurrencies.get(ps.Opportunity_lk__c).add(ps.Prem_Currency__c);
                }
            }

            // Opp별 + Currency별 Panel 그룹핑 & globalMaxY 계산
            Map<Id, Map<String, List<OPP_Panel__c>>> oppCurrPanels = new Map<Id, Map<String, List<OPP_Panel__c>>>();
            Map<Id, Map<String, Decimal>> oppCurrMaxY = new Map<Id, Map<String, Decimal>>();

            for (OPP_Panel__c panel : panels) {
                Id oppId = panel.Layer_md__r.Opportunity_md__c;
                String curr = panel.Currency__c;

                oppHasPanel.add(oppId);

                // KYC 미완료 체크 (기회의 BizRegion에 해당하는 법인 KYC만 판단)
                if (panel.Reinsurer_lk__r != null && opportunitiesByIds.containsKey(oppId)) {
                    String bizRegion = opportunitiesByIds.get(oppId).BizRegion__c;
                    Boolean kycIncomplete = false;
                    if (bizRegion == 'LK_KR') {
                        kycIncomplete = (panel.Reinsurer_lk__r.KycCompletedKr_is__c == false);
                    } else if (bizRegion == 'LK_Re') {
                        kycIncomplete = (panel.Reinsurer_lk__r.KycCompletedRe_is__c == false);
                    } else if (bizRegion == 'LK_VN') {
                        kycIncomplete = (panel.Reinsurer_lk__r.KycCompletedVn_is__c == false);
                    }
                    if (kycIncomplete) {
                        oppHasKycIssue.add(oppId);
                    }
                }

                // Opp+Currency별 Panel 그룹핑
                if (!oppCurrPanels.containsKey(oppId)) {
                    oppCurrPanels.put(oppId, new Map<String, List<OPP_Panel__c>>());
                    oppCurrMaxY.put(oppId, new Map<String, Decimal>());
                }
                if (!oppCurrPanels.get(oppId).containsKey(curr)) {
                    oppCurrPanels.get(oppId).put(curr, new List<OPP_Panel__c>());
                    oppCurrMaxY.get(oppId).put(curr, 0);
                }
                oppCurrPanels.get(oppId).get(curr).add(panel);

                // globalMaxY 계산
                Decimal layerTop = COM_Util.NVL(panel.Layer_md__r.Excess__c) + COM_Util.NVL(panel.Layer_md__r.LOL__c);
                if (layerTop > oppCurrMaxY.get(oppId).get(curr)) {
                    oppCurrMaxY.get(oppId).put(curr, layerTop);
                }
            }

            for (Opportunity opp : opportunitiesByIds.values()) {

                if (isCICaseMap.containsKey(opp.Id) == false) {
                    // 3. CO ROW밖에 없을 때
//                    if(oppHasNormalPanel.contains(opp.Id)==false) {
//                        opp.BindingDate__c.addError('Market Line에 CO만 존재하는 경우, Binding 불가합니다.');
//                        continue;
//                    }
                    // 1. KYC 체크
                    if (oppHasKycIssue.contains(opp.Id)) {
                        opp.BindingDate__c.addError(Label.OPP_MSG_BindingDateValidationFailed);
                        continue;
                    }
                    // 4. Prem Currency별 PremSchedule(Type=Schedule) 존재 여부
                    if (oppSlipCurrencies.containsKey(opp.Id)) {
                        Set<String> scheduleCurrSet = oppScheduleCurrencies.containsKey(opp.Id)
                                ? oppScheduleCurrencies.get(opp.Id) : new Set<String>();
                        for (String premCurr : oppSlipCurrencies.get(opp.Id)) {
                            if (!scheduleCurrSet.contains(premCurr)) {
                                opp.BindingDate__c.addError(Label.OPP_MSG_BindingDateValidationFailed);
                                break;
                            }
                        }
                    }
                    // 5. Slip PremCurrency에 대응하는 Finalize Panel 존재 여부
                    validateTsiPanelCurrency(opp, oppSlipCurrencies, oppCurrPanels);

                    // 2. Layer 세그먼트별 Signed 체크 (모든 세그먼트 Placement Done이어야 통과)
                    Decimal totalOrder = COM_Util.NVL(opp.TotalOrderPct__c);
                    if (oppHasPanel.contains(opp.Id) && oppCurrPanels.containsKey(opp.Id)) {
                        Boolean hasMismatch = false;
                        for (String curr : oppCurrPanels.get(opp.Id).keySet()) {
                            List<OPP_Panel__c> currPanels = oppCurrPanels.get(opp.Id).get(curr);
                            Decimal globalMaxY = oppCurrMaxY.get(opp.Id).get(curr);
                            List<Opp_BrokerageSummary_Ctrl.LayerComparison> mismatches =
                                    Opp_BrokerageSummary_Ctrl.calculateMismatchedLayers(currPanels, totalOrder, globalMaxY);
                            if (!mismatches.isEmpty()) {
                                hasMismatch = true;
                                break;
                            }
                        }
                        if (hasMismatch) {
                            opp.BindingDate__c.addError('2. Layer 세그먼트별 Signed 체크 (모든 세그먼트 Placement Done이어야 통과) && '+Label.OPP_MSG_BindingDateValidationFailed);
                        }
                    } else {
                        if (totalOrder > 0.01) {
                            opp.BindingDate__c.addError(Label.OPP_MSG_MARKETLINEREQUIRED);
                        }
                    }
                    opp.StageName = 'Closed Won';
                } else {
                    // CI CASE 예외

                    // 5. Slip PremCurrency에 대응하는 Finalize Panel 존재 여부
                    validateTsiPanelCurrency(opp, oppSlipCurrencies, oppCurrPanels);
                    opp.StageName = 'Closed Won';
                }
            }
        }
    }

    private static void validateTsiPanelCurrency(Opportunity opp, Map<Id, Set<String>> oppSlipCurrencies, Map<Id, Map<String, List<OPP_Panel__c>>> oppCurrPanels) {
        if (oppSlipCurrencies.containsKey(opp.Id) && oppCurrPanels.containsKey(opp.Id)) {
            Set<String> panelCurrSet = oppCurrPanels.get(opp.Id).keySet();
            for (String premCurr : oppSlipCurrencies.get(opp.Id)) {
                if (!panelCurrSet.contains(premCurr)) {
                    opp.BindingDate__c.addError(Label.OPP_MSG_BindingDateValidationFailed);
                    break;
                }
            }
        }
    }


    /**
     * @description
        1. Negotiating => RI Offer Slip 생성
        -> Opportunity.StateName이 Offered -> Negotiating 으로 변경 시 생성
        - RI Offer Slip 레코드 생성 기본값 -
        1.1. Opportunity_lk__c=recordId
        1.2. Type__c = ‘RI Offer’
        1.3. RecordType.Name = ‘Slip’
     * @param newList List<Opportunity>
     * @param oldMap Map<Id, Opportunity>
     */
//    private void createRIOfferSlipOnNegotiating(List<SObject> newList, Map<Id, SObject> oldMap) {
//
//        List<OPP_SlipInfo__c> oppSlipInfos = new List<OPP_SlipInfo__c>();
//
//        // RecordType ID 조회
//        Id slipRTId = COM_MetaUtil.getRecordTypeIdByDeveloperName('OPP_SlipInfo__c', 'Slip');
//
//        for (Opportunity newObj : (List<Opportunity>) newList) {
//            Opportunity oldObj = (Opportunity) oldMap.get(newObj.Id);
//            // Offered -> Negotiating 변경 체크
//            if (oldObj.StageName == 'Offered' && newObj.StageName == 'Negotiating') {
//                oppSlipInfos.add(new OPP_SlipInfo__c(
//                        Opportunity_lk__c = newObj.Id,
//                        RecordTypeId = slipRTId,
//                        Type__c = 'RI Offer'
//                ));
//            }
//        }
//
//        if(!oppSlipInfos.isEmpty()) {
//            insert oppSlipInfos;
//        }
//    }



}