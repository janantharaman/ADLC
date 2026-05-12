/**********************************************************************************
     * @filename      : CLM_QuickAction_Ctrl.cls
     * @project-name  : LK보험중계 신규계약관리시스템 구축
     * @author        : i2max
     * @date          : 2026-01-01 (목)
     * @group         :
     * @group-content :
     * @description   : CLM(Claim) 문서 생성 LWC용 Apex 컨트롤러.
     *                  Claim의 ClaimDocType/LastPLA 조건에 따라 PLA/SOC Allocation을 그룹화하여
     *                  DocumentGenerationProcess(DGP)를 생성하고 Claim 상태를 업데이트한다.
     *
     * @test-class    : CLM_DocGen_Ctrl_ts.cls
     * @reference     :
     * @copyright     : LK Insurance Services
     * @modification  Log
     * ===================================================================
     * ver   date            author           description
     * ===================================================================
     * 1.0   2026-01-01      i2max            Create
     **********************************************************************************/
    public with sharing class CLM_QuickAction_Ctrl {
        // ============================================================
        // Public Methods — AuraEnabled
        // ============================================================
        
        /**
         * @description Claim의 문서 생성 가능 여부 및 타입 정보를 조회하여 반환한다.
         *              Case 1(PLA + LastPLA=FALSE)만 canGenerate=false, 나머지는 true.
         *              편집 권한 없는 경우 hasEditPermission=false.
         * @param  claimId  문서 생성 여부를 확인할 Claim Record ID
         * @return ClaimDocInfoWrapper  문서 생성 가능 여부·타입·권한 정보 Wrapper
         */
        @AuraEnabled(cacheable=true)
        public static ClaimDocInfoWrapper getClaimDocInfo(Id claimId) {
            try {
                System.debug('[getClaimDocInfo] START claimId=' + claimId);
                
                if (String.isBlank(claimId)) {
                    throw new AuraHandledException('claimId is required.');
                }
                
                Claim claim = [
                SELECT ClaimDocType__c, LastPLA_is__c, TotalAmtLK_fm__c, AllocationCompleted_is__c
                FROM Claim
                WHERE Id = :claimId
                LIMIT 1
            ];
                System.debug(
                    '[getClaimDocInfo] claim.ClaimDocType__c=' +
                    claim.ClaimDocType__c +
                    ' LastPLA_is__c=' +
                    claim.LastPLA_is__c +
                    ' TotalAmtLK_fm__c=' +
                    claim.TotalAmtLK_fm__c +
                    ' AllocationCompleted_is__c=' +
                    claim.AllocationCompleted_is__c
                    );
                
                ClaimDocInfoWrapper w = new ClaimDocInfoWrapper();
                w.claimDocType = claim.ClaimDocType__c;
                w.lastPLA = claim.LastPLA_is__c;
                // Case 1 (PLA + LastPLA=FALSE) 만 생성 불가
                w.canGenerate = !(claim.ClaimDocType__c == 'PLA' && claim.LastPLA_is__c == false);
                // Allocation 완료 여부 (null 이면 미완료로 간주)
                w.isAllocated = (claim.AllocationCompleted_is__c == true);
                // 편집 권한 체크
                w.hasEditPermission = COM_MetaUtil.checkEditPermission(claimId);
                System.debug('[getClaimDocInfo] canGenerate=' + w.canGenerate + ' isAllocated=' + w.isAllocated + ' hasEditPermission=' + w.hasEditPermission);
                
                System.debug('[getClaimDocInfo] END result=' + JSON.serialize(w));
                return w;
            } catch (Exception e) {
                System.debug('[getClaimDocInfo] EXCEPTION: ' + e.getMessage() + ' line=' + e.getLineNumber());
                throw new AuraHandledException(e.getMessage());
            }
        }
        
        /**
         * @description getClaimDocInfo 반환 Wrapper. LWC에서 UI 상태 제어에 사용한다.
         */
        public class ClaimDocInfoWrapper {
            @AuraEnabled
            public String claimDocType { get; set; } // Claim의 문서 타입 (PLA / SOC)
            @AuraEnabled
            public Boolean lastPLA { get; set; } // LastPLA_is__c 값
            @AuraEnabled
            public Boolean canGenerate { get; set; } // 문서 생성 가능 여부
            @AuraEnabled
            public Boolean hasEditPermission { get; set; } // Claim 레코드 편집 권한 여부
            @AuraEnabled
            public Boolean isAllocated { get; set; } // AllocationCompleted_is__c 값
            @AuraEnabled
            public String message { get; set; } // UI 표시용 메시지 (선택)
            
            /** 기본값 초기화 — 모든 Boolean 필드를 false로 설정 */
            public ClaimDocInfoWrapper() {
                canGenerate = false;
                lastPLA = false;
                hasEditPermission = false;
                isAllocated = false;
            }
        }
        
        /**
         * @description Claim ID를 받아 PLA/SOC 문서 생성 프로세스(DGP)를 실행한다.
         *              Case별 Allocation 필터: Case2=PLA only, Case3=SOC only, Case4=PLA+SOC.
         *              같은 (ClaimDocType, Panel) 조합은 금액 합산 후 DGP 1건 생성.
         *              FX SOC Allocation은 (SOC_FX, Panel, SettlementCurrency, FXRate) 키로 별도 그룹 생성.
         *              실행 순서: Allocation 일련번호 업데이트 → DGBP insert → DGP insert → Claim 상태 업데이트.
         * @param  claimId  문서를 생성할 Claim Record ID
         */
        @AuraEnabled
        public static void generateClaimDocument(Id claimId) {
            try {
                System.debug('[DocGen] START claimId=' + claimId);
                
                // 1) Claim 조회
                Claim claim = [
                SELECT
                    Id,
                    Name,
                    ClaimDocType__c,
                    LastPLA_is__c,
                    CedantClaimNo__c,
                    IssueDate__c,
                    InsuredEn__c,
                    Placement_lk__c,
                    Placement_lk__r.Name,
                    Placement_lk__r.TransactionType__c,
                    Placement_lk__r.LKRefNoh__c,
                    Placement_lk__r.CedantName_lk__r.Name,
                    CedantPolicyNo__c,
                    InceptionDate__c,
                    ExpirationDate__c,
                    LossDate__c,
                    LossLocation__c,
                    LossParticular__c,
                    ClaimCurrency__c,
                    Remarks__c,
                    CedantName_lk__r.Name
                FROM Claim
                WHERE Id = :claimId
                LIMIT 1
            ];
                
                String claimDocType = claim.ClaimDocType__c;
                Boolean lastPLA = claim.LastPLA_is__c == true;
                System.debug('[DocGen] claim.Name=' + claim.Name + ' claimDocType=' + claimDocType + ' lastPLA=' + lastPLA);
                
                // Case 1 방어: UI에서 이미 막지만 서버에서도 검증
                if (claimDocType == 'PLA' && !lastPLA) {
                    throw new AuraHandledException('문서를 생성 할 수 없습니다.');
                }
                
                // 2) 케이스별 Allocation ClaimDocType__c 필터 결정
                // Case 2: PLA + LastPLA=TRUE  → PLA only
                // Case 3: SOC + LastPLA=FALSE → SOC only
                // Case 4: SOC + LastPLA=TRUE  → PLA & SOC
                Set<String> docTypeFilter = new Set<String>();
                if (claimDocType == 'PLA' && lastPLA) {
                    docTypeFilter.add('PLA');
                } else if (claimDocType == 'SOC' && !lastPLA) {
                    docTypeFilter.add('SOC');
                } else {
                    // SOC + lastPLA=TRUE
                    docTypeFilter.add('PLA');
                    docTypeFilter.add('SOC');
                }
                System.debug('[DocGen] docTypeFilter=' + docTypeFilter);
                
                // 3) Allocation 조회 (FacilityBDXOffset 포함 전체 조회 후 분리)
                List<CLM_Allocation__c> allAllocations = [
                SELECT
                    Id,
                    ClaimDocType__c,
                    Reinsurer_lk__c,
                    Reinsurer_lk__r.Name,
                    Reinsurer_lk__r.Address__Street__s,
                    Panel_lk__c,
                    ClaimSeq_fm__c,
                    ClaimNoteSeqNo__c,
                    LossAmt__c,
                    ExpAmt__c,
                    AllocatedTotalAmt_fm__c,
                    TotalAmtForRI__c,
                    SignedLine__c,
                    FXRatetoSettlementCurrency_fm__c,
                    ClaimCurrency_fm__c,
                    SettlementCurrency__c,
                    TotalAmtForRISettled__c,
                    FacilityBDXOffset_is__c
                FROM CLM_Allocation__c
                WHERE Claim_md__c = :claimId AND ClaimDocType__c IN :docTypeFilter
            ];
                
                // 문서 생성 대상(FacilityBDXOffset=false)과 Offset 대상으로 분리
                List<CLM_Allocation__c> docAllocs = new List<CLM_Allocation__c>();
                List<CLM_Allocation__c> offsetAllocs = new List<CLM_Allocation__c>();
                for (CLM_Allocation__c a : allAllocations) {
                    if (a.FacilityBDXOffset_is__c) {
                        offsetAllocs.add(a);
                    } else {
                        docAllocs.add(a);
                    }
                }
                System.debug('[DocGen] docAllocs=' + docAllocs.size() + ' offsetAllocs=' + offsetAllocs.size());
                
                // 4) 필요한 DocumentTemplate ContentVersion ID를 타입별로 사전 조회
                Map<String, Id> templateContentVersionIdMap = new Map<String, Id>();
                Map<String, Id> templateIdMap = new Map<String, Id>();
                
                //PLA 템플릿 조회
                if (docTypeFilter.contains('PLA')) {
                    List<DocumentTemplate> plaTemplates = [
                    SELECT Id, Name
                    FROM DocumentTemplate
                    WHERE TemplateType__c = 'PLA'
                    LIMIT 1
                ];
                    System.debug('[DocGen] PLA templates found=' + plaTemplates.size() + ' ' + plaTemplates);
                    if (!plaTemplates.isEmpty()) {
                        templateIdMap.put('PLA', plaTemplates[0].Id);
                        List<DocumentTemplateContentDoc> plaContent = [
                        SELECT LatestContentVersion.Id
                        FROM DocumentTemplateContentDoc
                        WHERE DocumentTemplateId = :plaTemplates[0].Id
                            LIMIT 1
                            ];
                        System.debug('[DocGen] PLA content docs found=' + plaContent.size());
                        if (!plaContent.isEmpty() && plaContent[0].LatestContentVersion != null) {
                            templateContentVersionIdMap.put('PLA', plaContent[0].LatestContentVersion.Id);
                            System.debug('[DocGen] PLA templateContentVersionId=' + plaContent[0].LatestContentVersion.Id);
                        } else {
                            System.debug('[DocGen] PLA LatestContentVersion is null or content empty');
                        }
                    }
                }
                
                //SOC 템플릿 조회
                if (docTypeFilter.contains('SOC')) {
                    List<DocumentTemplate> socTemplates = [
                    SELECT Id, Name
                    FROM DocumentTemplate
                    WHERE TemplateType__c = 'SOC'
                    LIMIT 1
                ];
                    System.debug('[DocGen] SOC templates found=' + socTemplates.size() + ' ' + socTemplates);
                    if (!socTemplates.isEmpty()) {
                        templateIdMap.put('SOC', socTemplates[0].Id);
                        List<DocumentTemplateContentDoc> socContent = [
                        SELECT LatestContentVersion.Id
                        FROM DocumentTemplateContentDoc
                        WHERE DocumentTemplateId = :socTemplates[0].Id
                            LIMIT 1
                            ];
                        System.debug('[DocGen] SOC content docs found=' + socContent.size());
                        if (!socContent.isEmpty() && socContent[0].LatestContentVersion != null) {
                            templateContentVersionIdMap.put('SOC', socContent[0].LatestContentVersion.Id);
                            System.debug('[DocGen] SOC templateContentVersionId=' + socContent[0].LatestContentVersion.Id);
                        } else {
                            System.debug('[DocGen] SOC LatestContentVersion is null or content empty');
                        }
                    }
                }
                
                System.debug('[DocGen] templateContentVersionIdMap=' + templateContentVersionIdMap);
                System.debug('[DocGen] templateIdMap=' + templateIdMap);
                
                // 5) Claim 공통 토큰 데이터 구성
                // new_txt_agg_lob_name: OPP_SlipInfo__c.RIType__c 조회 (SOQL 1회로 통합)
                //   - TransactionType='END' → 'RI Endorsement' 슬립 우선
                //   - 그 외               → 'RI Closing' 우선, 없으면 'RI Offer' 폴백
                String lobName = null;
                if (claim.Placement_lk__c != null) {
                    String transactionType = claim.Placement_lk__r != null ? claim.Placement_lk__r.TransactionType__c : null;
                    List<OPP_SlipInfo__c> slips = [
                    SELECT RIType__c, Type__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :claim.Placement_lk__c AND Type__c IN ('RI Endorsement', 'RI Closing', 'RI Offer') AND Latest_is__c = TRUE
                ];
                    Map<String, String> slipTypeMap = new Map<String, String>();
                    for (OPP_SlipInfo__c s : slips) {
                        slipTypeMap.put(s.Type__c, s.RIType__c);
                    }
                    if (transactionType == 'END') {
                        lobName = slipTypeMap.get('RI Endorsement');
                    } else {
                        lobName = slipTypeMap.get('RI Closing');
                        if (lobName == null) {
                            lobName = slipTypeMap.get('RI Offer');
                        }
                    }
                }
                System.debug('[DocGen] lobName=' + lobName);
                
                Map<String, Object> baseTokenData = new Map<String, Object>{
                    'new_txt_lk_claimno' => claim.Name,
                    'new_txt_cedant_claimno' => claim.CedantClaimNo__c,
                    'new_dt_soc_receipt' => Date.today(),
                    'new_txt_agg_insured' => claim.InsuredEn__c,
                    'new_txt_agg_lob_name' => lobName,
                    'new_txt_agg_cedant_name' => (claim.Placement_lk__r.CedantName_lk__r.Name != null ? claim.Placement_lk__r.CedantName_lk__r.Name : null),
                    'new_txt_cedant_policyno' => claim.CedantPolicyNo__c,
                    'new_txt_agg_inception' => claim.InceptionDate__c,
                    'new_txt_agg_expiration' => claim.ExpirationDate__c,
                    'new_dt_loss' => claim.LossDate__c,
                    'new_txt_loss_location' => claim.LossLocation__c,
                    'new_txt_loss_particular' => claim.LossParticular__c,
                    'RTB_new_ntxt_remark' => claim.Remarks__c,
                    'new_currency' => claim.ClaimCurrency__c
                };
                
                // 6) Allocation 그룹화 + 금액 합산
                //    - SOC + FXRatetoSettlementCurrency_fm__c != 1 + ClaimCurrency__c != SettlementCurrency__c
                //      → FX 그룹: docType|reinsurerID|settlementCurrency|fxRate 키로 별도 합산
                //    - 그 외 → 일반 그룹: docType|reinsurerID 키로 합산
                Map<String, AllocationGroup> groupMap = new Map<String, AllocationGroup>();
                for (CLM_Allocation__c a : docAllocs) {
                    System.debug('[DocGen] allocation Id=' + a.Id + ' ClaimDocType__c=' + a.ClaimDocType__c + ' Reinsurer=' + (a.Reinsurer_lk__r != null ? a.Reinsurer_lk__r.Name : 'null'));
                    
                    String panelId = a.Panel_lk__c != null ? String.valueOf(a.Panel_lk__c) : 'null';
                    Boolean isFxAllocation = (a.ClaimDocType__c == 'SOC' &&
                        a.FXRatetoSettlementCurrency_fm__c != null &&
                        a.FXRatetoSettlementCurrency_fm__c != 1 &&
                        a.ClaimCurrency_fm__c != a.SettlementCurrency__c);
                    
                    String groupKey;
                    if (isFxAllocation) {
                        // FX SOC: Panel + SettlementCurrency + FXRate 조합별 별도 그룹
                        groupKey = 'SOC_FX|' + panelId + '|' + a.SettlementCurrency__c + '|' + String.valueOf(a.FXRatetoSettlementCurrency_fm__c);
                    } else {
                        groupKey = a.ClaimDocType__c + '|' + panelId;
                    }
                    
                    if (!groupMap.containsKey(groupKey)) {
                        AllocationGroup grp = new AllocationGroup();
                        grp.docType = a.ClaimDocType__c;
                        grp.panelId = panelId;
                        grp.reinsurerName = a.Reinsurer_lk__r != null ? a.Reinsurer_lk__r.Name : 'NoReinsurer';
                        grp.reinsurerAddress = a.Reinsurer_lk__r != null ? a.Reinsurer_lk__r.Address__Street__s : '';
                        grp.claimSeq = a.ClaimSeq_fm__c;
                        grp.isFX = isFxAllocation;
                        if (isFxAllocation) {
                            grp.fxRate = a.FXRatetoSettlementCurrency_fm__c;
                            grp.settlementCurrency = a.SettlementCurrency__c;
                        }
                        // SignedLine__c: 같은 Panel은 동일 값이므로 첫 번째 값만 설정
                        grp.signedLine = a.SignedLine__c != null ? a.SignedLine__c : 0;
                        // assignedSeq는 assignAndUpdateClaimNoteSeqNo에서 일괄 부여
                        groupMap.put(groupKey, grp);
                    }
                    // FX 여부와 상관없이 같은 그룹키는 같은 문서로 합산
                    AllocationGroup grp = groupMap.get(groupKey);
                    grp.lossAmt += a.LossAmt__c != null ? a.LossAmt__c : 0;
                    grp.expAmt += a.ExpAmt__c != null ? a.ExpAmt__c : 0;
                    grp.totalAmt += a.AllocatedTotalAmt_fm__c != null ? a.AllocatedTotalAmt_fm__c : 0;
                    grp.totalAmtForRI += a.TotalAmtForRI__c != null ? a.TotalAmtForRI__c : 0;
                    if (isFxAllocation) {
                        grp.totalAmtForRISettled += a.TotalAmtForRISettled__c != null ? a.TotalAmtForRISettled__c : 0;
                    }
                }
                System.debug('[DocGen] grouped into ' + groupMap.size() + ' document(s)');
                
                // 7) 일련번호 부여 (PLA/SOC 공통 — groupMap.assignedSeq 설정 포함)
                assignAndUpdateClaimNoteSeqNo(docAllocs, offsetAllocs, groupMap);
                System.debug('[DocGen] assignAndUpdateClaimNoteSeqNo completed');
                
                // 8) Batch Parent 생성
                DocGenerationBatchProcess dgbp = new DocGenerationBatchProcess(Description = 'Generate PLA/SOC Document', Category = 'PLA/SOC');
                insert dgbp;
                System.debug('[DocGen] dgbp inserted Id=' + dgbp.Id);
                
                // 11) 그룹별로 DocumentGenerationProcess 생성 (업데이트된 레코드 기반)
                //     FX SOC 그룹은 templateIdMap 조회 시 'SOC' 키로 SOC 템플릿 사용
                List<DocumentGenerationProcess> dgpList = new List<DocumentGenerationProcess>();
                for (String gKey : groupMap.keySet()) {
                    AllocationGroup grp = groupMap.get(gKey);
                    // FX 그룹도 SOC 템플릿 사용
                    String templateKey = grp.docType; // 'PLA' or 'SOC'
                    Id templateContentVersionId = templateContentVersionIdMap.get(templateKey);
                    if (templateContentVersionId == null) {
                        System.debug('[DocGen] SKIP - No template for docType=' + templateKey);
                        continue;
                    }
                    
                    Map<String, Object> tokenData = baseTokenData.clone();
                    tokenData.put('name', grp.reinsurerName);
                    tokenData.put('new_txt_address', grp.reinsurerAddress);
                    tokenData.put('new_txt_agg_claim_amt', fmtAmt(formatAmountByCurrency(claim.ClaimCurrency__c, grp.lossAmt)));
                    tokenData.put('new_txt_agg_expense', fmtAmt(formatAmountByCurrency(claim.ClaimCurrency__c, grp.expAmt)));
                    tokenData.put('new_txt_agg_total_amt', fmtAmt(formatAmountByCurrency(claim.ClaimCurrency__c, grp.totalAmt)));
                    tokenData.put('new_txt_signed_line', grp.signedLine != null ? grp.signedLine.setScale(2, RoundingMode.HALF_UP).toPlainString() : null);
                    tokenData.put('new_txt_agg_yourshare', fmtAmt(grp.totalAmtForRI));
                    
                    // FX SOC 그룹 전용 토큰 추가
                    if (grp.isFX) {
                        tokenData.put('IF_IsFX', 'True');
                        tokenData.put('new_txt_fx_rate', grp.fxRate);
                        tokenData.put('fx_currency', grp.settlementCurrency);
                        tokenData.put('new_txt_TA', fmtAmt(grp.totalAmtForRISettled));
                    }
                    
                    String refName = claim.placement_lk__r != null ? claim.Placement_lk__r.LKRefNoh__c : '';
                    String nextSeqNo = String.valueOf(grp.assignedSeq).leftPad(3, '0');
                    String docTitle = refName + '–C–' + grp.claimSeq + '–' + nextSeqNo + '–' + grp.reinsurerName;
                String requestText = '{"keepIntermediate":true,"title":"' + docTitle + '","templateContentVersionId":"' + templateContentVersionId + '"}';
                System.debug('[DocGen] Creating DGP docType=' + grp.docType + (grp.isFX ? '(FX)' : '') + ' reinsurer=' + grp.reinsurerName + ' seq=' + grp.assignedSeq);
                
                dgpList.add(
                    new DocumentGenerationProcess(
                    Type = 'GenerateAndConvert',
                Status = 'InProgress',
                RequestText = requestText,
                TokenData = JSON.serialize(tokenData),
                ReferenceObject = claimId,
                DocGenApiVersionType = 'Advanced',
                DocGenerationBatchProcessId = dgbp.Id,
                DocumentTemplateId = templateIdMap.get(templateKey)
                    )
                    );
            }
            
            System.debug('[DocGen] dgpList size=' + dgpList.size());
            
            if (!dgpList.isEmpty()) {
                insert dgpList;
                System.debug('[DocGen] dgpList inserted count=' + dgpList.size());
                dgbp.Status = 'Queued';
                update dgbp;
                System.debug('[DocGen] dgbp status set to Queued');
            } else {
                System.debug('[DocGen] dgpList is EMPTY - no DocumentGenerationProcess created');
            }
            
            // 9) Claim 상태 업데이트
            updateClaim(claimId, claimDocType);
            
            System.debug('[DocGen] END');
        } catch (Exception e) {
            System.debug('[DocGen] EXCEPTION: ' + e.getMessage() + ' line=' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // ============================================================
    // Private Methods
    // ============================================================
    
    /**
     * @description DGP insert 완료 후 Claim 상태 필드를 claimDocType에 따라 업데이트한다.
     *              PLA: PostingDate__c, AccountingDate__c, IssueDate__c, Stage__c='Allocated', Status='Closed'.
     *              SOC: PLA 항목 + ClosingStatus__c='Posting Open'.
     * @param  claimId      업데이트할 Claim Record ID
     * @param  claimDocType 처리 타입 ('PLA' 또는 'SOC')
     */
    private static void updateClaim(Id claimId, String claimDocType) {
        Claim claim = new Claim(Id = claimId);
        Date today = Date.today();
        
        if (claimDocType == 'PLA') {
            claim.PostingDate__c = today;
            claim.AccountingDate__c = today;
            claim.IssueDate__c = today;
            claim.Stage__c = 'Allocated';
            claim.Status = 'Closed';
        } else if (claimDocType == 'SOC') {
            claim.PostingDate__c = today;
            claim.AccountingDate__c = today;
            claim.IssueDate__c = today;
            claim.Stage__c = 'Allocated';
            claim.ClosingStatus__c = 'Posting Open';
            claim.Status = 'Closed';
        }
        
        System.debug('[updateClaim] claimId=' + claimId + ' claimDocType=' + claimDocType);
        update claim;
    }
    
    /**
     * @description docType별 절대 일련번호(1부터)를 계산하여 CLM_Allocation__c.ClaimNoteSeqNo__c를 일괄 업데이트한다.
     *              문서 생성 그룹(FacilityBDXOffset=false) 우선 부여 후 Offset 그룹 후순위 부여.
     *              동일 Panel(또는 FX 그룹 키)에 속한 Allocation은 같은 번호를 공유한다.
     *              groupMap 제공 시 AllocationGroup.assignedSeq도 함께 설정(DGP 제목 생성에 사용).
     * @param  docAllocs    FacilityBDXOffset_is__c = false 인 Allocation 목록
     * @param  offsetAllocs FacilityBDXOffset_is__c = true  인 Allocation 목록
     * @param  groupMap     AllocationGroup 맵 (generateClaimDocument 컨텍스트 시 제공, 그 외 null)
     */
    private static void assignAndUpdateClaimNoteSeqNo(List<CLM_Allocation__c> docAllocs, List<CLM_Allocation__c> offsetAllocs, Map<String, AllocationGroup> groupMap) {
        if ((docAllocs == null || docAllocs.isEmpty()) && (offsetAllocs == null || offsetAllocs.isEmpty()))
            return;
        
        Map<String, Integer> seqByDocType = new Map<String, Integer>();
        
        // 문서 생성 그룹에 일련번호 부여
        // groupMap이 있으면 groupMap 삽입 순서 기준, 없으면 docAllocs 순회 기준
        Map<String, Integer> groupSeqMap = new Map<String, Integer>();
        if (groupMap != null) {
            for (String gKey : groupMap.keySet()) {
                AllocationGroup grp = groupMap.get(gKey);
                String dt = grp.docType;
                if (!seqByDocType.containsKey(dt))
                    seqByDocType.put(dt, 1);
                Integer seq = seqByDocType.get(dt);
                grp.assignedSeq = seq;
                groupSeqMap.put(gKey, seq);
                seqByDocType.put(dt, seq + 1);
            }
        } else {
            for (CLM_Allocation__c a : docAllocs) {
                String dt = a.ClaimDocType__c;
                String panelId = a.Panel_lk__c != null ? String.valueOf(a.Panel_lk__c) : 'null';
                Boolean isFxAlloc = (dt == 'SOC' && a.FXRatetoSettlementCurrency_fm__c != null && a.FXRatetoSettlementCurrency_fm__c != 1 && a.ClaimCurrency_fm__c != a.SettlementCurrency__c);
                String gKey = isFxAlloc ? 'SOC_FX|' + panelId + '|' + a.SettlementCurrency__c + '|' + String.valueOf(a.FXRatetoSettlementCurrency_fm__c) : dt + '|' + panelId;
                if (!groupSeqMap.containsKey(gKey)) {
                    if (!seqByDocType.containsKey(dt))
                        seqByDocType.put(dt, 1);
                    Integer seq = seqByDocType.get(dt);
                    groupSeqMap.put(gKey, seq);
                    seqByDocType.put(dt, seq + 1);
                }
            }
        }
        
        // Offset 그룹에 일련번호 부여 (Panel 기준, docType별 카운터 이어서)
        Map<String, Integer> offsetSeqMap = new Map<String, Integer>();
        for (CLM_Allocation__c a : offsetAllocs) {
            String dt = a.ClaimDocType__c;
            String offsetKey = dt + '|' + (a.Panel_lk__c != null ? String.valueOf(a.Panel_lk__c) : 'null');
            if (!offsetSeqMap.containsKey(offsetKey)) {
                if (!seqByDocType.containsKey(dt))
                    seqByDocType.put(dt, 1);
                Integer seq = seqByDocType.get(dt);
                offsetSeqMap.put(offsetKey, seq);
                seqByDocType.put(dt, seq + 1);
            }
        }
        
        // DB 업데이트
        List<CLM_Allocation__c> toUpdate = new List<CLM_Allocation__c>();
        for (CLM_Allocation__c a : docAllocs) {
            String panelId = a.Panel_lk__c != null ? String.valueOf(a.Panel_lk__c) : 'null';
            Boolean isFxAlloc = (a.ClaimDocType__c == 'SOC' &&
                a.FXRatetoSettlementCurrency_fm__c != null &&
                a.FXRatetoSettlementCurrency_fm__c != 1 &&
                a.ClaimCurrency_fm__c != a.SettlementCurrency__c);
            String gKey = isFxAlloc ? 'SOC_FX|' + panelId + '|' + a.SettlementCurrency__c + '|' + String.valueOf(a.FXRatetoSettlementCurrency_fm__c) : a.ClaimDocType__c + '|' + panelId;
            Integer seq = groupSeqMap.get(gKey);
            if (seq != null)
                toUpdate.add(new CLM_Allocation__c(Id = a.Id, ClaimNoteSeqNo__c = seq));
        }
        for (CLM_Allocation__c a : offsetAllocs) {
            String offsetKey = a.ClaimDocType__c + '|' + (a.Panel_lk__c != null ? String.valueOf(a.Panel_lk__c) : 'null');
            Integer seq = offsetSeqMap.get(offsetKey);
            if (seq != null)
                toUpdate.add(new CLM_Allocation__c(Id = a.Id, ClaimNoteSeqNo__c = seq));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
            System.debug('[assignAndUpdateClaimNoteSeqNo] updated count=' + toUpdate.size());
        }
    }
    /**
     * @description Decimal 값을 천단위 쉼표 포맷 문자열로 반환한다. null이면 빈 문자열을 반환한다.
     * @param  val  포맷할 Decimal 값
     * @return      천단위 쉼표가 포함된 문자열
     */
    @TestVisible
    private static String fmtAmt(Decimal val) {
        if (val == null) {
            return '';
        }
        return val.setScale(2).format();
    }
    
    /**
     * @description KRW/JPY이면 소수점 없이 반올림하고, 그 외 통화는 원본 값을 그대로 반환한다.
     * @param  currencyCode  통화코드
     * @param  amount        원본 금액
     * @return               KRW/JPY이면 0자리 반올림 값, 그 외 원본 값
     */
    private static Decimal formatAmountByCurrency(String currencyCode, Decimal amount) {
        if (amount == null) {
            return null;
        }
        if (currencyCode == 'KRW' || currencyCode == 'JPY') {
            return amount.setScale(0, RoundingMode.HALF_UP);
        }
        return amount;
    }
    
    /**
     * @description Allocation 그룹별 합산 데이터 내부 클래스.
     *              그룹 키: docType+Panel / FX SOC는 SOC_FX+Panel+SettlementCurrency+FXRate.
     *              assignedSeq는 assignAndUpdateClaimNoteSeqNo 호출 후 설정된다.
     */
    private class AllocationGroup {
        String docType;
        String panelId;
        String reinsurerName;
        String reinsurerAddress;
        String claimSeq; // ClaimSeq_fm__c — 문서 제목 사용
        Integer assignedSeq = 0; // assignAndUpdateClaimNoteSeqNo 에서 일괄 설정
        Decimal lossAmt = 0;
        Decimal expAmt = 0;
        Decimal totalAmt = 0; // AllocatedTotalAmt_fm__c 합산
        Decimal signedLine = 0; // 같은 Panel은 동일 값 → 첫 번째 값만 사용
        Decimal totalAmtForRI = 0; // TotalAmtForRI__c 합산
        // FX SOC 전용 필드
        Boolean isFX = false;
        Decimal fxRate; // FXRatetoSettlementCurrency_fm__c
        String settlementCurrency; // SettlementCurrency__c
        Decimal totalAmtForRISettled = 0; // FX SOC 전용: TotalAmtForRISettled__c 합산
    }
}