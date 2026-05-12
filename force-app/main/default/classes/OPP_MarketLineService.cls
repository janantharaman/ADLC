/**********************************************************************************
 * @filename      : OPP_MarketLineService.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketLineService_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-07      i2max     Create
 **********************************************************************************/
public with sharing class OPP_MarketLineService {


    public static final String SETT_TYPE_SEPARATE = 'Separate';
    public static final String SETT_TYPE_TOGETHER = 'Together';

    public static Map<String, Object> buildCtx(Id recordId) {
        return buildCtx(new OPP_MarketLineContext(recordId));
    }

    // ctx_* 생성: OPP_Cobroker__c 기반
    public static Map<String, Object> buildCtx(OPP_MarketLineContext mlCtx) {

        Id recordId = mlCtx.recordId;
        Id placementId = mlCtx.placementId;

        List<String> query = new List<String>();
        Map<String, Object> ctx = new Map<String, Object>();

        Boolean isOpp = mlCtx.isOpp;
        Boolean isPlacement = mlCtx.isPlacement;
        Boolean isClaim = mlCtx.isClaim;

        ctx.put('ctx_isOpp', mlCtx.isOpp);
        ctx.put('ctx_isPlacement', mlCtx.isPlacement);
        ctx.put('ctx_isClaim', mlCtx.isClaim);
        ctx.put('ctx_isTreaty', mlCtx.isTreaty);
        ctx.put('ctx_bizRegion', mlCtx.bizRegion);
        ctx.put('ctx_NeedRecalculate', mlCtx.needRecalculate);
        ctx.put('ctx_isOpportunityDeclaration', mlCtx.isOpportunityDeclaration);
        ctx.put('ctx_isPlacementDeclaration', mlCtx.isPlacementDeclaration);
        ctx.put('ctx_isDeclaration', mlCtx.isDeclaration);
        ctx.put('ctx_isPlacementEND', mlCtx.isPlacementEND);
        ctx.put('ctx_isNew', mlCtx.isNew);
        ctx.put('ctx_isSOAByCurrency', new Map<String, Boolean>()); // 기본값
        ctx.put('ctx_masterRICommPct', mlCtx.masterRICommPct);
        ctx.put('ctx_masterOtherDeductionsPct', mlCtx.masterOtherDeductionsPct);
        ctx.put('ctx_masterTotalOrderPct', mlCtx.masterTotalOrderPct);
        ctx.put('ctx_proration', mlCtx.proration);

        // Claim 전용
        if (mlCtx.isClaim) {
            ctx.put('ctx_claimCurrency', mlCtx.claimCurrency);
            ctx.put('ctx_placementId', mlCtx.placementId);
        }
        // Opportunity 전용
        if (mlCtx.isOpp) {
            ctx.put('ctx_facilityId', mlCtx.facilityId);
            ctx.put('ctx_facilityParticipantId', mlCtx.facilityParticipantId);
        }

        // TSI 조회 (통화별 합계)
        Map<String, Decimal> tsiSumByCurrency = new Map<String, Decimal>();
        Map<String, Decimal> tsiSumByGrossPrem = new Map<String, Decimal>();
        // GrossPrem 산출용 DPPct 분기 집계
        Map<String, Decimal> tsiDPAdjustableByCurrency = new Map<String, Decimal>();
        Map<String, Decimal> tsiDPFullByCurrency       = new Map<String, Decimal>();
        Map<String, Decimal> tsiGrossPremDPFullByCurrency       = new Map<String, Decimal>();
        Map<String, Decimal> tsiGrossPremDPAdjustableByCurrency = new Map<String, Decimal>();
        // ActualAdjRatePct 산출용
        Map<String, Decimal> tsiGrossPremBfDPByCurrency        = new Map<String, Decimal>(); // SUM(GrossPremBfDP_fm__c)
        Map<String, Decimal> tsiActualAdjAfterDPByCurrency     = new Map<String, Decimal>(); // SUM(InsuredAmount * DPPct * GrossRate)
        Map<String, Decimal> tsiDPAppliedSumByCurrency         = new Map<String, Decimal>(); // SUM(InsuredAmount * DPPct) = B

        Id slipRTId = COM_MetaUtil.getRecordTypeIdByDeveloperName('OPP_SlipInfo__c', 'Slip');

        if (isOpp || isPlacement) {

            //OPP_PremiumSchedule_r.Type_c = Declaration (OPP_PremiumSchedule_r.PremCurrency__c = Market Line 화면의 Prem Currency)

            query = new List<String>();
            query.add('SELECT DPPct__c,');
            query.add('PremiumCurrency__c,InsuredAmount__c,');
            query.add('GrossRatePct__c, GrossPremBfDP_fm__c,');
            query.add('GrossPrem_fm__c, NetToLKPrem_fm__c');
            query.add('FROM OPP_TSIByLocation__c');
            if(isOpp) query.add('WHERE SlipInfo_md__r.Opportunity_lk__c = :recordId');
            if(isOpp) query.add('AND SlipInfo_md__r.Placement_lk__c = NULL');
            if(isPlacement) query.add('WHERE SlipInfo_md__r.Placement_lk__c = :recordId');
            query.add('AND PremiumCurrency__c != NULL');
            query.add('AND SlipInfo_md__r.Latest_is__c = TRUE');
            query.add('AND SlipInfo_md__r.RecordTypeId = :slipRTId');
            query.add('AND Type__c=\'TSIByLocation\'');
            List<OPP_TSIByLocation__c> tsiAggs = Database.query(String.join(query, ' '));

            Map<String, Decimal> sumDPAppliedByCurrency = new Map<String, Decimal>();
            for (OPP_TSIByLocation__c tsi : tsiAggs) {
                String curr = tsi.PremiumCurrency__c;
                Decimal dpApplied = COM_Util.NVL(tsi.InsuredAmount__c) * (COM_Util.NVL(tsi.DPPct__c) / 100);
                sumDPAppliedByCurrency.put(curr, COM_Util.NVL(sumDPAppliedByCurrency.get(curr)) + dpApplied);
            }

            for (OPP_TSIByLocation__c tsi : tsiAggs) {
                String  curr = tsi.PremiumCurrency__c;
                Decimal dpp  = COM_Util.NVL(tsi.DPPct__c);//[DP (%)]
                Decimal amt  = COM_Util.NVL(tsi.InsuredAmount__c);//[Insured Amount]
                Decimal gp   = COM_Util.NVL(tsi.GrossPrem_fm__c);//[Gross Prem]=GrossPremBfDP_fm__c * (DPPct__c / 100)
                Decimal grossRate = COM_Util.NVL(tsi.GrossRatePct__c);//Gross Rate (%)
                Decimal gpBfDP   = COM_Util.NVL(tsi.GrossPremBfDP_fm__c);//[Gross Prem (Before DP]=InsuredAmount__c * (GrossRatePct__c / 100) * FxRatePremCurrency__c

                // 기존: 통화별 전체 합산
                tsiSumByCurrency.put(curr, COM_Util.NVL(tsiSumByCurrency.get(curr)) + amt);
                tsiSumByGrossPrem.put(curr, COM_Util.NVL(tsiSumByGrossPrem.get(curr)) + gp);

                tsiGrossPremBfDPByCurrency.put(curr, COM_Util.NVL(tsiGrossPremBfDPByCurrency.get(curr)) + gpBfDP);
                Decimal dpApplied = amt * (dpp / 100);
                tsiDPAppliedSumByCurrency.put(curr, COM_Util.NVL(tsiDPAppliedSumByCurrency.get(curr)) + dpApplied);
                Decimal ActualAdjAfterDP = (dpApplied * (grossRate / 100)) / COM_Util.NVL(sumDPAppliedByCurrency.get(curr));
                tsiActualAdjAfterDPByCurrency.put(curr, COM_Util.NVL(tsiActualAdjAfterDPByCurrency.get(curr)) + ActualAdjAfterDP);

                // 신규: DPPct 분기 합산
                if (dpp == 100) {
                    tsiDPFullByCurrency.put(curr, COM_Util.NVL(tsiDPFullByCurrency.get(curr)) + amt);
                    tsiGrossPremDPFullByCurrency.put(curr, COM_Util.NVL(tsiGrossPremDPFullByCurrency.get(curr)) + gp);
                } else {
                    tsiDPAdjustableByCurrency.put(curr, COM_Util.NVL(tsiDPAdjustableByCurrency.get(curr)) + amt);
                    tsiGrossPremDPAdjustableByCurrency.put(curr, COM_Util.NVL(tsiGrossPremDPAdjustableByCurrency.get(curr)) + gp);
                }
            }
            Map<String, Boolean> soaByCurrency = new Map<String, Boolean>();
            query = new List<String>();
            query.add('SELECT Prem_Currency__c FROM OPP_PremiumSchedule__c');
            if (isOpp) query.add('WHERE Opportunity_lk__c = :recordId');
            if (isOpp) query.add('AND Placement_lk__c = NULL');
            if (isPlacement) query.add('WHERE Placement_lk__c = :recordId');
            query.add('AND PaymentType__c = \'SOA\'');
            for (OPP_PremiumSchedule__c ps : Database.query(String.join(query, ' '))) {
                soaByCurrency.put(ps.Prem_Currency__c, true);
            }
            ctx.put('ctx_isSOAByCurrency', soaByCurrency);
        }
        System.debug('🐤🐤🐤🐤🐤 mlCtx.isDeclaration=['+ mlCtx.isDeclaration +']');
        System.debug('🐤🐤🐤🐤🐤 SUM(GrossPremBfDP_fm__c) tsiGrossPremBfDPByCurrency=['+ tsiGrossPremBfDPByCurrency+']');
        System.debug('🐤🐤🐤🐤🐤 SUM(amt * (dpp / 100)) tsiDPAppliedSumByCurrency=['+ tsiDPAppliedSumByCurrency+']');
        System.debug('🐤🐤🐤🐤🐤 SUM((dpApplied * (grossRate / 100)) / SUM(amt * (dpp / 100))) tsiActualAdjAfterDPByCurrency=['+ tsiActualAdjAfterDPByCurrency+']');

        query = new List<String>();
        query.add('SELECT Id,');
        query.add('LKCobroking_is__c, CobrokingType__c, SettlementType__c, Client__c,');
        query.add('SharingPct__c, LKAdminFeePct__c,');
        query.add('CobrokerName_lk__c, LKCobroker_lk__c ');
        query.add('FROM OPP_Cobroker__c');

        if (isOpp) query.add('WHERE Opportunity_md__c=:recordId');
        if (isOpp) query.add('AND Placement_lk__c=NULL');

        if (isPlacement) query.add('WHERE Placement_lk__c=:recordId');

        if (isClaim) query.add('WHERE Placement_lk__c=:placementId');
        if (isClaim || isPlacement) query.add('AND Placement_lk__c!=NULL');

        query.add('WITH SECURITY_ENFORCED');
        query.add('');

        System.debug(String.join(query, ' '));
        System.debug('⛔️ recordId=[' + recordId + ']');
        List<OPP_Cobroker__c> coBrokers = Database.query(String.join(query, ' '));

        Decimal placingSharingPct = 0;
        Decimal placingAdminFeePct = 0;
        Decimal lkPlacingSharingPct = 0;
        Decimal lkPlacingAdminFeePct = 0;

        Decimal producingSharingPct = 0;
        Decimal producingAdminFeePct = 0;
        Decimal lkProducingSharingPct = 0;
        Decimal lkProducingAdminFeePct = 0;

        //Boolean hasPlacingSeparate = false;
        Boolean hasPlacingTogether = false;
        Boolean hasLKPlacingSeparate = false;
        Boolean hasLKPlacingTogether = false;

        // 2026-02-11
        Boolean hasLKProducingSeparateNonClient = false;
        Boolean hasProducingSeparateNonClient = false;

        Boolean isProducingTogetherClient = false; // CobrokingType__c =='Producing' && SettlementType__c ='Together' && Client = true
        Boolean hasProducingTogetherClient = false; // 외부 Producing + Client + Together (Type 8,9)
        Boolean hasProducingSeparateClient = false; // 외부 Producing + Client + Separate (Type 6)
        Boolean hasPlacing = false; // 외부 Placing 존재 (Type 3,7)
        Boolean hasLKPlacing = false; // LK Placing 존재 (Type 4)
        Boolean hasLKProducingSeparateClient = false; // LK Producing + Client + Separate (Type 5)
        Boolean hasLKProducingTogetherClient = false; // LK Producing + Client + Together

        Boolean hasProducing = false; // Producing Co-broking
        Boolean hasLKProducing = false; // LK Producing Co-broking

        Boolean noPlacingRecords = true;// CobrokingType__c==Placing 인 OPP_Cobroker__c 레코드 없음
        Boolean noProducingRecords = true;// CobrokingType__c==Producing 인 OPP_Cobroker__c 레코드 없음

        Boolean hasLKPlacingCoBroker = false; // Save.Valid => LK Placing Co-broker 삭제 확인 용
        Boolean noCoBrokerRecords = coBrokers.isEmpty();// OPP_Cobroker__c 레코드 없음

        for (OPP_Cobroker__c coBroker : coBrokers) {
            Boolean isLKCoBroking = coBroker.LKCobroking_is__c;
            Boolean isClient = coBroker.Client__c;
            Boolean isCoBrokingTypePlacing = coBroker.CobrokingType__c.endsWith('Placing');
            Boolean isCoBrokingTypeProducing = coBroker.CobrokingType__c.endsWith('Producing');
            Boolean isSettTypeTogether = (coBroker.SettlementType__c == SETT_TYPE_TOGETHER);
            Boolean isSettTypeSeparate = (coBroker.SettlementType__c == SETT_TYPE_SEPARATE);
            //////////////////////////////////////////////////////////////////////////////////// start
            if (isLKCoBroking) {
                if (isCoBrokingTypePlacing) {
                    hasLKPlacing = true;

                    if(coBroker.CobrokerName_lk__c != null || coBroker.LKCobroker_lk__c !=null) hasLKPlacingCoBroker = true;

                    lkPlacingSharingPct += COM_Util.nvl(coBroker.SharingPct__c, 0);
                    lkPlacingAdminFeePct += COM_Util.nvl(coBroker.LKAdminFeePct__c, 0);

                    if (isSettTypeTogether) hasLKPlacingTogether = true;
                    if (isSettTypeSeparate) hasLKPlacingSeparate = true;
                }
                if (isCoBrokingTypeProducing) {
                    hasLKProducing = true;
                    lkProducingSharingPct += COM_Util.nvl(coBroker.SharingPct__c, 0);
                    lkProducingAdminFeePct += COM_Util.nvl(coBroker.LKAdminFeePct__c, 0);

                    if (isClient) {
                        if (isSettTypeTogether) hasLKProducingTogetherClient = true;
                        if (isSettTypeSeparate) hasLKProducingSeparateClient = true;
                    }

                    if (isSettTypeSeparate && isClient == false) {
                        hasLKProducingSeparateNonClient = true; // LK Producing Separate 체크
                    }
                }//isLKCoBroking==true END
            } else {
                //Non LK
                if (isCoBrokingTypePlacing) {
                    placingSharingPct += COM_Util.nvl(coBroker.SharingPct__c, 0);
                    placingAdminFeePct += COM_Util.nvl(coBroker.LKAdminFeePct__c, 0);
                    hasPlacing = true;

                    if(isSettTypeTogether) hasPlacingTogether = true;
//                    if(isSettTypeSeparate) hasPlacingSeparate = true;
                }
                if (isCoBrokingTypeProducing) {
                    hasProducing = true;
                    producingSharingPct += COM_Util.nvl(coBroker.SharingPct__c, 0); //Sharing(%)
                    producingAdminFeePct += COM_Util.nvl(coBroker.LKAdminFeePct__c, 0); //LK Admin Fee(%)

                    if (isSettTypeSeparate && isClient == false) {
                        hasProducingSeparateNonClient = true;
                    }

                    if (isClient) {
                        if (isSettTypeTogether) hasProducingTogetherClient = true;
                        if (isSettTypeSeparate) hasProducingSeparateClient = true;
                    }
                }
            }
            //Non LK End

            if(isCoBrokingTypePlacing) noPlacingRecords = false;
            if(isCoBrokingTypeProducing) noProducingRecords = false;

            if(isCoBrokingTypeProducing && isSettTypeTogether && isClient) isProducingTogetherClient = true;
        }

        ctx.put('ctx_producingAdminFeePct', producingAdminFeePct);
        ctx.put('ctx_producingSharingPct', producingSharingPct);

        ctx.put('ctx_lkProducingSharingPct', lkProducingSharingPct);
        ctx.put('ctx_lkProducingAdminFeePct', lkProducingAdminFeePct);

        ctx.put('ctx_placingSharingPct', placingSharingPct);
        ctx.put('ctx_placingAdminFeePct', placingAdminFeePct);

        ctx.put('ctx_lkPlacingSharingPct', lkPlacingSharingPct);
        ctx.put('ctx_lkPlacingAdminFeePct', lkPlacingAdminFeePct);

        ctx.put('ctx_hasPlacingTogether', hasPlacingTogether);
        //ctx.put('ctx_hasPlacingSeparate', hasPlacingSeparate);
        ctx.put('ctx_hasLKPlacingTogether', hasLKPlacingTogether);
        ctx.put('ctx_hasLKPlacingSeparate', hasLKPlacingSeparate);
        ctx.put('ctx_hasLKPlacingCoBroker', hasLKPlacingCoBroker); // Save.Valid => LK Placing Co-broker 삭제 확인

        // 2026-02-11
        ctx.put('ctx_hasProducingTogetherClient', hasProducingTogetherClient); // NetProducingCobrker__c, NetToLKPrem__c
        ctx.put('ctx_hasLKProducingSeparateNonClient', hasLKProducingSeparateNonClient);
        ctx.put('ctx_hasProducingSeparateNonClient', hasProducingSeparateNonClient);
        ctx.put('ctx_tsiSumByCurrency', tsiSumByCurrency); //TSI 조회 (통화별 합계)
        ctx.put('ctx_tsiSumByGrossPrem', tsiSumByGrossPrem); //TSI 조회 (통화별 합계)
        ctx.put('ctx_tsiDPFullByCurrency', tsiDPFullByCurrency); //TSI 조회 (통화별 합계)
        ctx.put('ctx_tsiDPAdjustableByCurrency', tsiDPAdjustableByCurrency); //TSI 조회 (통화별 합계)
        ctx.put('ctx_tsiGrossPremDPFullByCurrency', tsiGrossPremDPFullByCurrency);
        ctx.put('ctx_tsiGrossPremDPAdjustableByCurrency', tsiGrossPremDPAdjustableByCurrency);
        ctx.put('ctx_tsiGrossPremBfDPByCurrency', tsiGrossPremBfDPByCurrency);
        ctx.put('ctx_tsiActualAdjAfterDPByCurrency', tsiActualAdjAfterDPByCurrency);
        ctx.put('ctx_tsiDPAppliedSumByCurrency', tsiDPAppliedSumByCurrency);
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ctx.put('ctx_hasProducingSeparateClient', hasProducingSeparateClient);
        ctx.put('ctx_hasPlacing', hasPlacing);
        ctx.put('ctx_hasProducing', hasProducing);
        ctx.put('ctx_hasLKPlacing', hasLKPlacing);
        ctx.put('ctx_hasLKProducing', hasLKProducing);
        ctx.put('ctx_hasLKProducingSeparateClient', hasLKProducingSeparateClient);
        ctx.put('ctx_hasLKProducingTogetherClient', hasLKProducingTogetherClient);

        ctx.put('ctx_noPlacingRecords', noPlacingRecords);
        ctx.put('ctx_noProducingRecords', noProducingRecords);
        ctx.put('ctx_noCoBrokerRecords', noCoBrokerRecords);
        ctx.put('ctx_isPlacementRecord', isPlacement);
        ctx.put('ctx_isProducingTogetherClient', isProducingTogetherClient);

        Map<String, Decimal> grossPremDeclarationByCurrency = new Map<String, Decimal>();
        if (mlCtx.isDeclaration) { // if (mlCtx.isPlacementDeclaration) {
            // Placement 생성 시 OPP_PremiumSchedule__c 복제여부에 따라서 기회일때 조회 조건문에 Placement_lk__c = null 필요할 수 있음.
            query = new List<String>();
            query.add('SELECT SlipGrossPrem__c, Prem_Currency__c');
            query.add('FROM OPP_PremiumSchedule__c');
            if (mlCtx.isOpp) query.add('WHERE Opportunity_lk__c = :recordId');
            if (mlCtx.isOpp) query.add('AND Placement_lk__c = NULL');
            if (mlCtx.isPlacement) query.add('WHERE Placement_lk__c = :recordId');
            query.add('AND Type__c = \'Declaration\'');
            query.add('AND Prem_Currency__c != NULL');
            for (OPP_PremiumSchedule__c ps : Database.query(String.join(query, ' '))) {
                grossPremDeclarationByCurrency.put(ps.Prem_Currency__c, COM_Util.NVL(ps.SlipGrossPrem__c));
            }
        }
        ctx.put('ctx_grossPremDeclarationByCurrency', grossPremDeclarationByCurrency);

        return ctx;
    }

    //CO, BrkgAdj
    @AuraEnabled
    public static Map<String, SObject> calculateSpecialRow(List<Id> panelIds, String type) {

        if (panelIds.isEmpty()) throw new AuraHandledException('Panel Id is required.');

        System.debug('calculateSpecialRow type=['+ type +'], panelIds=['+ panelIds +']');

        String brkgAdj = 'Brkg Adj';

        //Opp_SimulationPanel_Ctrl.PanelWrapper panelWrapper = new Opp_SimulationPanel_Ctrl.PanelWrapper();
        Map<String, SObject> results = new Map<String, SObject>();
        OPP_Layer__c oppLayer;
        OPP_Panel__c oppPanel;

        List<OPP_Panel__c> oppPanels = [
                SELECT Id, Currency__c, Layer_md__c,
                        Layer_md__r.Opportunity_md__c,
                        Layer_md__r.Opportunity_md__r.InsuredGroup_lk__c,
                        Layer_md__r.Opportunity_md__r.CedantName_lk__c,
                        Layer_md__r.Opportunity_md__r.RICommPct__c,
                        Layer_md__r.Opportunity_md__r.OtherDeductionsPct__c,
                        Layer_md__r.Opportunity_md__r.TotalOrderPct__c,
                        Layer_md__r.Placement_lk__c,
                        Layer_md__r.Placement_lk__r.InsuredGroup_lk__c,
                        Layer_md__r.Placement_lk__r.CedantName_lk__c,
                        Layer_md__r.Placement_lk__r.RICommPct__c,
                        Layer_md__r.Placement_lk__r.OtherDeductionsPct__c,
                        Layer_md__r.Placement_lk__r.TotalOrderPct__c,
                        NetToLKPrem__c,
                        NetProducingCobrker__c,
                        NetToUW__c,
                        LKPlacingTPPBrkg__c
                FROM OPP_Panel__c
                WHERE Id IN :panelIds
        ];
        System.debug('calculateSpecialRow oppPanels.size()=['+ oppPanels.size() +']');
        // 시작 ~
        if (!oppPanels.isEmpty()) {

            OPP_Panel__c refPanel = oppPanels[0];
            String panelCurrency = refPanel.Currency__c;

            Boolean isOpp = (refPanel.Layer_md__r.Opportunity_md__c <> null && refPanel.Layer_md__r.Placement_lk__c==null);
            Boolean isPlacement = (refPanel.Layer_md__r.Opportunity_md__c <> null && refPanel.Layer_md__r.Placement_lk__c <> null);

            SObject masterObj;
            if(isOpp) masterObj = refPanel.Layer_md__r.Opportunity_md__r;
            if(isPlacement) masterObj = refPanel.Layer_md__r.Placement_lk__r;

            Id masterRecordId = (Id) masterObj.get('Id');

            Map<String, Object> ctx = buildCtx(masterRecordId);

//            Boolean isPlacementDeclaration = (Boolean) ctx.get('ctx_isPlacementDeclaration');
            Boolean isDeclaration = (Boolean) ctx.get('ctx_isDeclaration');

            //* Declaration일때는 동일 Prem Currency 값을 지닌 OPP_PremSchedule__c의 SlipGrossPrem__c (where Type__c = Declaration)
            Decimal grossPremDeclaration = 0;
            if(isDeclaration) { // if(isPlacementDeclaration) {

                // Placement 생성 시 OPP_PremiumSchedule__c 복제여부에 따라서 기회일때 조회 조건문에 Placement_lk__c = null 필요할 수 있음.
                List<String> query = new List<String>();
                query.add('SELECT SlipGrossPrem__c');
                query.add('FROM OPP_PremiumSchedule__c');
                if (isOpp) query.add('WHERE Opportunity_lk__c = :masterRecordId');
                if (isPlacement) query.add('WHERE Placement_lk__c = :masterRecordId');
                query.add('AND Type__c = \'Declaration\'');
                query.add('AND Prem_Currency__c = :panelCurrency');
                query.add('LIMIT 1');

                List<OPP_PremiumSchedule__c> decSchedules = Database.query(String.join(query, ' '));
                if (!decSchedules.isEmpty()) grossPremDeclaration = COM_Util.NVL(decSchedules[0].SlipGrossPrem__c);

//                List<OPP_PremiumSchedule__c> decSchedules = [
//                        SELECT SlipGrossPrem__c
//                        FROM OPP_PremiumSchedule__c
//                        WHERE Placement_lk__c = :masterRecordId
//                        AND Type__c = 'Declaration'
//                        AND Prem_Currency__c = :panelCurrency
//                        LIMIT 1
//                ];
//                if (!decSchedules.isEmpty()) grossPremDeclaration = COM_Util.NVL(decSchedules[0].SlipGrossPrem__c);
            }

            Boolean hasLKProducingTogetherClient = (Boolean) ctx.get('ctx_hasLKProducingTogetherClient');
            Boolean hasProducingTogetherClient = (Boolean) ctx.get('ctx_hasProducingTogetherClient');
            Boolean hasLKPlacingTogether = (Boolean) ctx.get('ctx_hasLKPlacingTogether');
            Boolean hasLKProducingSeparateNonClient = (Boolean) ctx.get('ctx_hasLKProducingSeparateNonClient');
            Boolean hasProducingSeparateNonClient = (Boolean) ctx.get('ctx_hasProducingSeparateNonClient');

            Map<String, Decimal> tsiSumByGrossPrem = (Map<String, Decimal>) ctx.get('ctx_tsiSumByGrossPrem');
            Map<String, Decimal> tsiSumByCurrency = (Map<String, Decimal>) ctx.get('ctx_tsiSumByCurrency');

            System.debug('calculateSpecialRow before tsiSumByGrossPrem=['+ tsiSumByGrossPrem +']');
            System.debug('calculateSpecialRow before tsiSumByCurrency=['+ tsiSumByCurrency +']');

            List<String> query = new List<String>();
            query.add('SELECT Id, Layer_md__c');
            query.add('FROM OPP_Panel__c');
            if(isOpp) {
                query.add('WHERE Layer_md__r.Opportunity_md__c =:masterRecordId');
                query.add('AND Layer_md__r.Placement_lk__c=NULL');
            }
            if(isPlacement) {
                query.add('WHERE Layer_md__r.Placement_lk__c=:masterRecordId');
            }
            query.add('AND Currency__c = :panelCurrency');
            query.add('AND BrkgAdj_is__c = TRUE');

            List<OPP_Panel__c> exBrkAdjPanels = Database.query(String.join(query, ' '));
            System.debug('calculateSpecialRow exBrkAdjPanels.size()=['+ exBrkAdjPanels.size() +']');

            Decimal sumNetToLKPrem = 0;
            Decimal sumNetProducingCoBroker = 0;
            Decimal sumNetToUW = 0;
            Decimal sumLKPlacingTPPBrkg = 0;

            for (OPP_Panel__c panel : oppPanels) {
                sumNetToLKPrem += COM_Util.NVL(panel.NetToLKPrem__c);
                sumNetProducingCoBroker += COM_Util.NVL(panel.NetProducingCobrker__c);
                sumNetToUW += COM_Util.NVL(panel.NetToUW__c);
                sumLKPlacingTPPBrkg += COM_Util.NVL(panel.LKPlacingTPPBrkg__c);
            }
//            System.debug('calculateSpecialRow sumNetToLKPrem=['+ sumNetToLKPrem.toPlainString() +'], sumNetProducingCoBroker=['+ sumNetProducingCoBroker.toPlainString() +']');

            if (exBrkAdjPanels.isEmpty()) {
                oppLayer = new OPP_Layer__c(LayerCurrency__c = panelCurrency);
                if(isOpp) oppLayer.Opportunity_md__c = masterRecordId;
                if(isPlacement) oppLayer.Placement_lk__c = masterRecordId;

                oppPanel = new OPP_Panel__c(Currency__c = panelCurrency, BrkgAdj_is__c = true);
            }
            if (!exBrkAdjPanels.isEmpty()) {
                oppLayer = new OPP_Layer__c(Id = exBrkAdjPanels[0].Layer_md__c);
                oppPanel = new OPP_Panel__c(Id = exBrkAdjPanels[0].Id);
            }
// 2026-04-09 하위 로직 제외
//            if (masterObj.get('InsuredGroup_lk__c') != null) {
//                oppPanel.MarketType__c = 'Facility';
//                oppPanel.Facility_lk__c = (Id) masterObj.get('InsuredGroup_lk__c');
//                oppPanel.Reinsurer_lk__c = null;
//            } else {
//                oppPanel.MarketType__c = 'Open Market';
//                oppPanel.Reinsurer_lk__c = (Id) masterObj.get('CedantName_lk__c');
//                oppPanel.Facility_lk__c = null;
//            }

            Boolean isBrkgAdj = type.equalsIgnoreCase(brkgAdj);

            System.debug('calculateSpecialRow isBrkgAdj=['+ isBrkgAdj +']');

            Decimal lkReBrkg = COM_Util.NVL( (Decimal) masterObj.get('RICommPct__c')) / 100;
            Decimal otherDeductionsPct = COM_Util.NVL( (Decimal) masterObj.get('OtherDeductionsPct__c')) / 100;
            Decimal totalOrderPct = COM_Util.NVL( (Decimal) masterObj.get('TotalOrderPct__c') ) / 100;
            Decimal grossPrem = (isDeclaration ? grossPremDeclaration : COM_Util.NVL(tsiSumByGrossPrem.get(panelCurrency)));
            //* Declaration일때는 동일 Prem Currency 값을 지닌 OPP_PremSchedule__c의 SlipGrossPrem__c (where Type__c = Declaration)
            Decimal insuredAmt = COM_Util.NVL(tsiSumByCurrency.get(panelCurrency));
            Decimal netToLKPremFromCedant = grossPrem * (1 - lkReBrkg - otherDeductionsPct) * totalOrderPct;
            Boolean coBrkPlacingTogether_is = (oppPanel.CoBroker_lk__c != null && oppPanel.PlacingSettlementType__c == 'Together');

            System.debug('calculateSpecialRow panelCurrency=['+ panelCurrency +'], grossPrem=['+ grossPrem.toPlainString() +']');
            System.debug('calculateSpecialRow coBrkPlacingTogether_is=['+ coBrkPlacingTogether_is +'], insuredAmt=['+ insuredAmt +']');

            // 초기화
            oppPanel.TotalBrkg__c = 0;
            oppPanel.NetToLKPrem__c = 0;
            oppPanel.ProducingTPPBrkg__c = 0;
            oppPanel.PlacingTPPBrkge__c = 0; // BrkgAdj Row 는 항상 0
            oppPanel.RICommPct__c = 0;
            oppPanel.OtherDeductionPct__c = 0;
            oppPanel.Signed__c = 0;
            oppPanel.NetToUW__c = 0;
            oppPanel.CoBroker_lk__c = null;
            oppPanel.PlacingSettlementType__c = null;
            oppPanel.LKPlacingSharingPct__c = 0;
            oppPanel.PlacingTPPAdminFeePct__c = 0;
            oppPanel.ProducingSharingPct__c = 0;
            oppPanel.ProducingTPPAdminFeePct__c = 0;
            oppPanel.LKProducingSharingPct__c = 0;
            oppPanel.ToLKAdminFee__c = 0;
            oppPanel.NetRI__c = 0;
            oppPanel.NetProducingTPP__c = 0;
            oppPanel.LKNetProducingTPP__c = 0;
            oppPanel.NetPlacingTPP__c = 0;
            oppPanel.LKNetPlacingTPP__c = 0;
            oppPanel.GrossPrem__c = 0;
            oppPanel.BrkgBase__c = null;
            oppPanel.BrkgAdj_is__c = isBrkgAdj;
            oppPanel.CO_is__c = 'CO'.equalsIgnoreCase(type);

            if (isBrkgAdj) {

//                System.debug('calculateSpecialRow before oppPanel.TotalBrkg__c=['+ oppPanel.TotalBrkg__c +']');
//                System.debug('calculateSpecialRow hasLKProducingTogetherClient=['+ hasLKProducingTogetherClient +']');
//                System.debug('calculateSpecialRow hasProducingTogetherClient=['+ hasProducingTogetherClient +']');
//                System.debug('calculateSpecialRow netToLKPremFromCedant=['+ netToLKPremFromCedant.toPlainString() +']');
//                System.debug('calculateSpecialRow sumNetProducingCobrker=['+ sumNetProducingCobrker.toPlainString() +']');
//                System.debug('calculateSpecialRow sumNetToLKPrem=['+ sumNetToLKPrem.toPlainString() +']');
//                System.debug('calculateSpecialRow (hasLKProducingTogetherClient || hasProducingTogetherClient)=['+ (hasLKProducingTogetherClient || hasProducingTogetherClient) +']');

                oppLayer.Type__c = brkgAdj;
                oppPanel.TotalBrkg__c = netToLKPremFromCedant - ((hasLKProducingTogetherClient || hasProducingTogetherClient) ? sumNetProducingCoBroker : sumNetToLKPrem);
                oppPanel.NetProducingCobrker__c = (hasLKProducingTogetherClient || hasProducingTogetherClient) ? oppPanel.TotalBrkg__c : 0;
                oppPanel.ProducingTPPBrkg__c = (oppPanel.TotalBrkg__c * (oppPanel.ProducingSharingPct__c / 100));
//                System.debug('calculateSpecialRow ((hasLKProducingTogetherClient || hasProducingTogetherClient) ? sumNetProducingCobrker : sumNetToLKPrem)=['+ (((hasLKProducingTogetherClient || hasProducingTogetherClient) ? sumNetProducingCobrker : sumNetToLKPrem)) +']');
//                System.debug('calculateSpecialRow after oppPanel.TotalBrkg__c=['+ oppPanel.TotalBrkg__c.toPlainString() +']');
            }
//            System.debug('calculateSpecialRow insuredAmt=['+ insuredAmt.toPlainString() +']');
            oppPanel.ActualAdjRatePct__c = (insuredAmt == 0 ? 0 :
                    ((oppPanel.BrkgBase__c == 'Gross' ?
                            (COM_Util.NVL(oppPanel.GrossPremDP__c) / insuredAmt) :
                            (((1 - (COM_Util.NVL(oppPanel.RICommPct__c) / 100) - (COM_Util.NVL(oppPanel.OtherDeductionPct__c) / 100)) * COM_Util.NVL(oppPanel.GrossPremDP__c)) / insuredAmt))));

            oppPanel.LKProducingTPPBrkg__c = (oppPanel.TotalBrkg__c - oppPanel.PlacingTPPBrkge__c) * (oppPanel.LKProducingSharingPct__c / 100);
            oppPanel.LKPlacingTPPBrkg__c = (oppPanel.TotalBrkg__c - oppPanel.ProducingTPPBrkg__c) * (oppPanel.LKPlacingSharingPct__c / 100);
            oppPanel.LKReBrkge__c = (oppPanel.TotalBrkg__c - oppPanel.ProducingTPPBrkg__c - oppPanel.LKProducingTPPBrkg__c - oppPanel.PlacingTPPBrkge__c - oppPanel.LKPlacingTPPBrkg__c);
            oppPanel.ToProducingAdminFee__c = - (oppPanel.TotalBrkg__c - oppPanel.ProducingTPPBrkg__c) * (oppPanel.ProducingTPPAdminFeePct__c / 100);

            if (isBrkgAdj) {
                oppPanel.NetToLKPrem__c =  (hasLKProducingTogetherClient || hasProducingTogetherClient) ?
                        (oppPanel.NetProducingCobrker__c - oppPanel.ProducingTPPBrkg__c - oppPanel.LKProducingTPPBrkg__c + oppPanel.ToProducingAdminFee__c) :
                        oppPanel.TotalBrkg__c;
                        //((oppPanel.GrossPrem__c * (1 - (oppPanel.RICommPct__c / 100) - (oppPanel.OtherDeductionPct__c / 100))) * (oppPanel.Signed__c / 100));
                oppPanel.Facility_lk__c = (Id) ctx.get('ctx_facilityId');
                oppPanel.FacilityParticipant_lk__c = (Id) ctx.get('ctx_facilityParticipantId');
                if(oppPanel.Facility_lk__c <> null) oppPanel.MarketType__c = 'Facility';
                oppPanel.Reinsurer_lk__c = null;
            }

            oppPanel.ToLKAdminFee__c = (oppPanel.PlacingTPPBrkge__c * (oppPanel.PlacingTPPAdminFeePct__c / 100));
            oppPanel.NetRI__c = (coBrkPlacingTogether_is || hasLKPlacingTogether) ? 0 : oppPanel.NetToUW__c;
            oppPanel.NetProducingTPP__c = (hasProducingSeparateNonClient ? oppPanel.ProducingTPPBrkg__c : 0);
            oppPanel.LKNetProducingTPP__c = (hasLKProducingSeparateNonClient ? oppPanel.LKProducingTPPBrkg__c : 0);
            oppPanel.NetPlacingTPP__c = (coBrkPlacingTogether_is ? oppPanel.NetToUW__c : 0) + oppPanel.PlacingTPPBrkge__c - oppPanel.ToLKAdminFee__c;
            oppPanel.LKNetPlacingTPP__c = (hasLKPlacingTogether ? oppPanel.NetToUW__c : 0) + oppPanel.LKPlacingTPPBrkg__c;

//            System.debug('calculateSpecialRow before oppPanel=['+ oppPanel +']');
//            System.debug('calculateSpecialRow before panelWrapper=['+ panelWrapper +']');
        }
        results.put('Layer', oppLayer);
        results.put('Panel', oppPanel);
        return results;
    }


}