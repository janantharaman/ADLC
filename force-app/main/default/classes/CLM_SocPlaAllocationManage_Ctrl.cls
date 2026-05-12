/**********************************************************************************
 * @filename      : CLM_SocPlaAllocationManage_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-26 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : CLM_SocPlaAllocationManage_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-26      i2max     Create
**********************************************************************************/
public with sharing class CLM_SocPlaAllocationManage_Ctrl {

    public class recordData {
        @AuraEnabled public List<summaryData> records { get; set; }
        @AuraEnabled public List<COM_Option> claimOptions { get; set; }
        @AuraEnabled public List<AllocationData> clmAllocations { get; set; }
        @AuraEnabled public Map<String, Boolean> claimOffsetMap { get; set; }
        @AuraEnabled public Decimal lkSharePct { get; set; }
        @AuraEnabled public Decimal fxRateToSettleCurr { get; set; }
        @AuraEnabled public String settlementCurrency { get; set; }
        @AuraEnabled public String claimName { get; set; }
        @AuraEnabled public Boolean isReadOnly { get; set; }
        public recordData() {
        }
    }

    public class summaryData {
        @AuraEnabled public String type;
        @AuraEnabled public String claimCurrency;
        @AuraEnabled public List<recordItem> items;
        public summaryData() {
        }
        public summaryData(String type, String curr, List<recordItem> items) {
            this.type = type;
            this.claimCurrency = curr;
            this.items = items;
        }
    }

    public class recordItem {
        @AuraEnabled public String type;
        @AuraEnabled public Decimal lossAmt;
        @AuraEnabled public Decimal expAmt;
        @AuraEnabled public Decimal totalAmt;
        @AuraEnabled public Decimal TotalAmtLk;
        public recordItem(String type, Decimal lossAmt, Decimal expAmt, Decimal totalAmt, Decimal TotalAmtLk) {
            this.type = type;
            this.lossAmt = lossAmt;
            this.expAmt = expAmt;
            this.totalAmt = totalAmt;
            this.TotalAmtLk = TotalAmtLk;
        }
    }

    public class AllocationData {
        @AuraEnabled public CLM_Allocation__c allocation { get; set; }
        @AuraEnabled public Boolean claimOffset { get; set; }

        public AllocationData(CLM_Allocation__c allocation, Boolean claimOffset) {
            this.allocation = allocation;
            this.claimOffset = claimOffset;
        }
    }


    @AuraEnabled
    public static recordData getRecords(Id recordId) {

        if (recordId == null) throw new AuraHandledException('recordId is required.');

        List<Claim> claims = [
                SELECT Id, Name,
                        LastPLA_is__c, ClaimCurrency__c, SettlementCurrency__c, ClaimDocType__c,
                        LossAmt__c, ExpAmt__c, TotalAmtLK_fm__c, TotalAmt_fm__c,
                        LossRsvRem__c, ExpRsvRem__c, TotalRsv__c, TotalRsvLK_fm__c, TotalRsv_fm__c,
                        IsAllocationBlocked_fm__c, LKShare__c, FXRateToSettleCurrency__c,
                        Placement_lk__c, Stage__c
                FROM Claim
                WHERE Id = :recordId
                LIMIT 1
        ];
        System.debug('[CLM_SocPlaAllocationManage_Ctrl > getSummary] claims=[' + claims + ']');

        recordData rowData = new recordData();
        List<summaryData> records = new List<summaryData>();

        if (!claims.isEmpty()) {//&& claims[0].IsAllocationBlocked_fm__c
            Claim claim = claims[0];
            //Placement 정보가 누락되었습니다. 클레임이 유효한 Placement와 연결되어 있는지 확인해주세요. COM_MSG_PLACEMENT_MISSING
            if (claim.Placement_lk__c == null) throw new AuraHandledException(Label.COM_MSG_PLACEMENT_MISSING);

            rowData.claimName = claim.Name;
            rowData.isReadOnly = claim.IsAllocationBlocked_fm__c==false; //('Closed'.equalsIgnoreCase(claim.Stage__c));

            rowData.lkSharePct = COM_Util.NVL(claim.LKShare__c);
            rowData.fxRateToSettleCurr = COM_Util.NVL(claim.FXRateToSettleCurrency__c);
            rowData.settlementCurrency = claim.SettlementCurrency__c;

            // 1. Type별 합계 계산 (AggregateResult)
            Map<String, recordItem> sumMap = new Map<String, recordItem>();

            List<CLM_Allocation__c> clmAllocations = [
                    SELECT ClaimDocType__c,
                            PanelGroupSeq__c,
                            LossAmt__c,
                            ExpAmt__c,
                            AllocatedTotalAmt_fm__c,
                            TotalAmtForRI__c
                    FROM CLM_Allocation__c
                    WHERE Claim_md__c = :recordId
                    AND ClaimDocType__c <> ''
                    AND Status__c = 'Allocated'
                    ORDER BY ClaimDocType__c, PanelGroupSeq__c
            ];
            for(CLM_Allocation__c clmAllocation : clmAllocations) {
                String type = clmAllocation.ClaimDocType__c;
                if(!sumMap.containsKey(type)) {
                    sumMap.put(type,
                            new recordItem('Allocated',
                            COM_Util.NVL(clmAllocation.LossAmt__c),
                            COM_Util.NVL(clmAllocation.ExpAmt__c),
                            COM_Util.NVL(clmAllocation.AllocatedTotalAmt_fm__c),
                            COM_Util.NVL(clmAllocation.TotalAmtForRI__c))
                    );
                } else {
                    sumMap.get(type).TotalAmtLk += COM_Util.NVL(clmAllocation.TotalAmtForRI__c);
                }
            }

//            List<AggregateResult> aggs = [
//                    SELECT ClaimDocType__c type,
//                            SUM(LossAmt__c) loss, SUM(ExpAmt__c) exp,
//                            SUM(TotalAmt__c) total, SUM(AllocatedTotalAmt_fm__c) totalLk
//                    FROM CLM_Allocation__c
//                    WHERE Claim_md__c = :recordId
//                    GROUP BY ClaimDocType__c
//            ];
//
//            for (AggregateResult ar : aggs) {
//                String type = (String) ar.get('type');
//                if (String.isBlank(type)) continue;
//
//                sumMap.put(type, new recordItem('Allocated',
//                        COM_Util.NVL((Decimal) ar.get('loss')),
//                        COM_Util.NVL((Decimal) ar.get('exp')),
//                        COM_Util.NVL((Decimal) ar.get('total')),
//                        COM_Util.NVL((Decimal) ar.get('totalLk'))
//                ));
//            }
            if (!sumMap.containsKey('PLA')) sumMap.put('PLA', new recordItem('Allocated', 0, 0, 0, 0));
            if (!sumMap.containsKey('SOC')) sumMap.put('SOC', new recordItem('Allocated', 0, 0, 0, 0));

            /* 2. Case 분기
            Case 1: LastPLA_is__c == False && ClaimDocType__c == 'PLA' => Allocation 불가 ==> 요건 변경 Read Only로 조회는 되고 Allocation 버튼은 비활성화
            Case 2: LastPLA_is__c == True && ClaimDocType__c == 'PLA' => PLA Only
            Case 3: LastPLA_is__c == False && ClaimDocType__c == 'SOC' => SOC Only
            Case 4: LastPLA_is__c == True && ClaimDocType__c == 'SOC' => PLA & SOC Allocation

            Case 1: LastPLA_is__c == False && ClaimDocType__c == 'PLA' =>  PLA Only, Allocation 불가, ClaimOptions 빈 값 없음
            Case 2: LastPLA_is__c == True && ClaimDocType__c == 'PLA' => PLA Only, PLA Edit 및 Allocation 가능, ClaimOptions PLA만 있음
            Case 3: LastPLA_is__c == False && ClaimDocType__c == 'SOC' => SOC Only, SOC Edit 및 Allocation 가능, ClaimOptions SOC만 있음
            Case 4: LastPLA_is__c == True && ClaimDocType__c == 'SOC' => PLA & SOC Edit 및 Allocation 가능, ClaimOptions PLA,SOC 있음
             */

            Set<String> excludeOptions = new Set<String>();

            Boolean isPLA = 'PLA'.equalsIgnoreCase(claim.ClaimDocType__c);
            Boolean isSOC = 'SOC'.equalsIgnoreCase(claim.ClaimDocType__c);
            Boolean isLastPLA = claim.LastPLA_is__c;

            // 1. Last PLA가 아니면 무조건 'PLA' 제외 (Case 1, 3)d
            if (('PLA'.equalsIgnoreCase(claim.ClaimDocType__c) || 'SOC'.equalsIgnoreCase(claim.ClaimDocType__c)) && !claim.LastPLA_is__c) {
                excludeOptions.add('PLA');
            }

            // 2. 문서 타입이 PLA이면 무조건 'SOC' 제외 (Case 1, 2)
            if (claim.ClaimDocType__c == 'PLA') {
                excludeOptions.add('SOC');
            }
            // 1) PLA Table
            //if(claim.LastPLA_is__c) {
            if ('PLA'.equalsIgnoreCase(claim.ClaimDocType__c) || (claim.LastPLA_is__c && 'SOC'.equalsIgnoreCase(claim.ClaimDocType__c))) {

                List<recordItem> items = new List<recordItem>();
//                items.add(new recordItem('Received', claim.LossRsvRem__c, claim.ExpRsvRem__c, claim.TotalAmt_fm__c, claim.TotalRsvLK_fm__c));

                if (isPLA && claim.TotalRsv_fm__c == 0) {
                    items.add(new recordItem('Received', claim.LossAmt__c, claim.ExpAmt__c, claim.TotalAmt_fm__c, claim.TotalAmtLK_fm__c));
                } else {
                    items.add(new recordItem('Received', claim.LossRsvRem__c, claim.ExpRsvRem__c, claim.TotalRsv_fm__c, claim.TotalRsvLK_fm__c));
                }
                items.add(sumMap.get('PLA'));//Allocated
                records.add(new summaryData('PLA', claim.ClaimCurrency__c, items));
            }

            // 2) SOC Table
            if ('SOC'.equalsIgnoreCase(claim.ClaimDocType__c)) {

                List<recordItem> items = new List<recordItem>();
                items.add(new recordItem('Received', claim.LossAmt__c, claim.ExpAmt__c, claim.TotalAmt_fm__c, claim.TotalAmtLK_fm__c));
                items.add(sumMap.get('SOC'));//Allocated
                records.add(new summaryData('SOC', claim.ClaimCurrency__c, items));
            }
            rowData.claimOptions = COM_Util.makePickListOptions('CLM_Allocation__c', 'ClaimDocType__c', true, false, excludeOptions);

            Map<String, Boolean> fpMap = new Map<String, Boolean>();
            for (COM_FacilityParticipant__c fp : [
                    SELECT Facility_lk__c, ReinsurerAccount_lk__c, ClaimOffset_is__c
                    FROM COM_FacilityParticipant__c
                    WHERE Facility_lk__c IN (
                            SELECT Facility_lk__c
                            FROM OPP_Panel__c
                            WHERE Layer_md__r.Placement_lk__c = :claim.Placement_lk__c
                            AND Layer_md__r.Placement_lk__c <> NULL
                    )
            ]) {
                fpMap.put(fp.Facility_lk__c + '_' + fp.ReinsurerAccount_lk__c, fp.ClaimOffset_is__c == true);
            }
            rowData.claimOffsetMap = fpMap;
        }

        rowData.records = records;
        rowData.clmAllocations = getClaimAllocations(recordId);

        System.debug('[CLM_SocPlaAllocationManage_Ctrl > getSummary] Results ##### records=[' + records + ']');
        System.debug('[CLM_SocPlaAllocationManage_Ctrl > getSummary] Results ##### rowData=[' + rowData + ']');
        return rowData;
    }

    @AuraEnabled
    public static List<AllocationData> getClaimAllocations(Id recordId) {

        List<AllocationData> allocationDataList = new List<AllocationData>();
        List<CLM_Allocation__c> clmAllocations = [
                SELECT Id, PanelGroupSeq__c, ClaimDocType__c, LossAmt__c, ExpAmt__c, AllocatedTotalAmt_fm__c,
                        Reinsurer_lk__c, Reinsurer_lk__r.Name,
                        SignedLine__c, TotalAmtForRI__c, SettlementCurrency__c, TotalAmtForRISettled__c,
                        Panel_lk__c, Panel_lk__r.Reinsurer_lk__c, Panel_lk__r.MarketType__c,
                        IssueDate_fm__c, Facility_lk__c, Facility_lk__r.Name,
                        MGAName_lk__c, MGAName_lk__r.Name
                FROM CLM_Allocation__c
                WHERE Claim_md__c = :recordId
                AND Status__c = 'Allocated'
                ORDER BY PanelGroupSeq__c ASC, Panel_lk__r.BrkgAdj_is__c ASC, Panel_lk__r.Layer_md__r.CreatedDate DESC, Panel_lk__r.CreatedDate DESC
        ];

        // 1. Facility Id 수집
        Set<Id> facilityIds = new Set<Id>();
        for (CLM_Allocation__c clmAllocation : clmAllocations) {
            if ('Facility'.equalsIgnoreCase(clmAllocation.Panel_lk__r.MarketType__c) && clmAllocation.Facility_lk__c != null) {
                facilityIds.add(clmAllocation.Facility_lk__c);
            }
        }

        // 2. FacilityParticipant 조회 → Facility+Reinsurer 복합키 매핑
        Map<String, Boolean> fpMap = new Map<String, Boolean>();
        if (!facilityIds.isEmpty()) {
            for (COM_FacilityParticipant__c facilityParticipant : [
                    SELECT Facility_lk__c, ReinsurerAccount_lk__c, ClaimOffset_is__c
                    FROM COM_FacilityParticipant__c
                    WHERE Facility_lk__c IN :facilityIds
            ]) {
                fpMap.put(
                        facilityParticipant.Facility_lk__c + '_' + facilityParticipant.ReinsurerAccount_lk__c,
                        facilityParticipant.ClaimOffset_is__c == true);
            }
        }

        // 3. Allocation별 ClaimOffset 매칭
        for (CLM_Allocation__c clmAllocation : clmAllocations) {
            Boolean isClaimOffset = false;
            if ('Facility'.equalsIgnoreCase(clmAllocation.Panel_lk__r.MarketType__c) && clmAllocation.Facility_lk__c != null) {
                String key = clmAllocation.Facility_lk__c + '_' + clmAllocation.Panel_lk__r.Reinsurer_lk__c;
                isClaimOffset = fpMap.containsKey(key) ? fpMap.get(key) : false;
            }
            allocationDataList.add(new AllocationData(clmAllocation, isClaimOffset));
        }

        return allocationDataList;
    }

    // 저장
    @AuraEnabled
    public static void saveAllocation(Id recordId, List<Map<String, Object>> items, Boolean allocationCompleted) {
        List<CLM_Allocation__c> insertList = new List<CLM_Allocation__c>();
        List<CLM_Allocation__c> deleteList = new List<CLM_Allocation__c>();

        System.debug('[ CLM_SocPlaAllocationManage_Ctrl > saveAllocation] >>>>>>>>>>>>>>> recordId=['+ recordId +'], items=[' + items + ']');

        if(items.isEmpty()) throw new AuraHandledException('No items to save.');

        String claimName = (String) items[0].get('claimName');

        List<CLM_Allocation__c> exAllocations = [
                SELECT Name
                FROM CLM_Allocation__c
                WHERE Claim_md__c=:recordId
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];
        System.debug('[ CLM_SocPlaAllocationManage_Ctrl > saveAllocation] >>>>>>>>>>>>>>> exAllocations=['+ exAllocations + ']');
        Integer clmAllocationSeq = 1;
        if(!exAllocations.isEmpty() && String.isNotBlank(claimName)) {
            String seqStr = exAllocations[0].Name.replace(claimName, '').replace('-', '');
            clmAllocationSeq = seqStr.isNumeric() ? Integer.valueOf(seqStr) + 1 : 1;
        }

        for (Map<String, Object> item : items) {
            String idStr = (String) item.get('Id');
            Boolean isTmp = String.isBlank(idStr) || idStr.startsWith('tmp_');
            Boolean isDeleted = (item.get('isDeleted') == true);

            if (isDeleted) {
                if (!isTmp) {
                    deleteList.add(new CLM_Allocation__c(Id = idStr));
                }
            } else {
                if (isTmp) {
                    CLM_Allocation__c obj = new CLM_Allocation__c();

                    // 필드 매핑
                    obj.Name = claimName + '-' + String.valueOf(clmAllocationSeq).leftPad(3, '0');
                    obj.Claim_md__c = (Id) item.get('Claim_md__c');
                    obj.PanelGroupSeq__c = (String) item.get('PanelGroupSeq__c');
                    obj.LossAmt__c = (Decimal) item.get('LossAmt__c');
                    obj.ExpAmt__c = (Decimal) item.get('ExpAmt__c');
                    obj.Reinsurer_lk__c = (Id) item.get('Reinsurer_lk__c');
                    obj.SignedLine__c = (Decimal) item.get('SignedLine__c');
                    obj.TotalAmtForRI__c = (Decimal) item.get('TotalAmtForRI__c');
                    obj.SettlementCurrency__c = (String) item.get('SettlementCurrency__c');
                    obj.TotalAmtForRISettled__c = (Decimal) item.get('TotalAmtForRISettled__c');
                    //FacilityMGA_lk__c Facility/MGA
                    String marketType = (String) item.get('MarketType__c');
                    String facilityMgaId = (String) item.get('FacilityMGA_lk__c');
                    if (marketType == 'Facility') {
                        obj.Facility_lk__c = (Id) facilityMgaId;
                    } else if (marketType == 'MGA') {
                        obj.MGAName_lk__c = (Id) facilityMgaId;
                    }
                    obj.Panel_lk__c = (Id) item.get('Panel_lk__c');
                    obj.ClaimDocType__c = (String) item.get('Type__c'); // SOC/PLA 타입
                    obj.FacilityBDXOffset_is__c = item.get('ClaimOffset_is__c') == true;
                    insertList.add(obj);
                    clmAllocationSeq++;
//                    System.debug('[ CLM_SocPlaAllocationManage_Ctrl > saveAllocation] >>>>>>>>>>>>>>> item.ClaimOffset_is__c=[' + (Boolean) item.get('ClaimOffset_is__c') + ']');
                }
            }
        }
//
//        System.debug('[ CLM_SocPlaAllocationManage_Ctrl > saveAllocation] >>>>>>>>>>>>>>> deleteList=[' + deleteList + ']');
//        System.debug('[ CLM_SocPlaAllocationManage_Ctrl > saveAllocation] >>>>>>>>>>>>>>> insertList=[' + insertList + ']');

        if (!deleteList.isEmpty()) delete deleteList;
        if (!insertList.isEmpty()) insert insertList;
        // Allocation 완료 여부 업데이트
        update new Claim(Id = recordId, AllocationCompleted_is__c = allocationCompleted);

    }


}