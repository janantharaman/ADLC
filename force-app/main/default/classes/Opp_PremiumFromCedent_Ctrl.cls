/**********************************************************************************
 * @filename      : Opp_PremiumFromCedent_Ctrl.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-01-02
 * @group         :
 * @group-content :
 * @description   : Premium From Cedent 데이터 조회 및 저장을 처리하는 컨트롤러
 * @test-class    : Opp_PremiumFromCedent_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-02      i2max            Create
 **********************************************************************************/
public with sharing class Opp_PremiumFromCedent_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description 초기 화면 렌더링에 필요한 Premium From Cedent 데이터를 조회한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @param curr Premium Currency 값
     * @return InitDataWrapper 초기 화면 데이터
     */
    @AuraEnabled
    public static InitDataWrapper getInitData(Id recordId, String curr) {
        try {
            InitDataWrapper w = new InitDataWrapper();
            w.paymentTypeOptions = COM_Util.makePickListOptions('OPP_PremiumSchedule__c', 'PaymentType__c', true);
            
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required.');
            }
            
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            
            w.isPlacement = isPlacement;
            // w.hasEditPermission = isPlacement ? false : COM_MetaUtil.checkEditPermission(recordId);
            w.hasEditPermission = COM_MetaUtil.checkEditPermission(recordId);
            
            Id oppId = recordId;
            Id placementId;
            String oppPaymentType;
            
            if (isPlacement) {
                Placement__c placement = [
                    SELECT Opportunity_lk__c, TransactionType__c,CedingType1__c,PlacementClosingDate__c
                    FROM Placement__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                oppId = placement.Opportunity_lk__c;
                placementId = recordId;
                w.isClosed = placement.PlacementClosingDate__c!=null;
                w.transactionType = placement.TransactionType__c;
                w.cedingType = placement.CedingType1__c;
                
            } else {
                Opportunity opp = [
                    SELECT Id, IsClosed, PaymentType__c, TransactionType__c,CedingType1__c
                    FROM Opportunity
                    WHERE Id = :oppId
                    LIMIT 1
                ];
                w.isClosed = opp.IsClosed;
                w.transactionType = opp.TransactionType__c;
                w.cedingType = opp.CedingType1__c;
                oppPaymentType = opp.PaymentType__c;
            }
            
            System.debug('Transaction Type: ' + w.transactionType);
            
            // Placement인 경우 TransactionType에 따라 paymentTypeOptions 필터링
            // - Declaration : SOA 옵션만 노출
            // - END         : SOA 제외 후 노출
            if (isPlacement) {
                w.paymentTypeOptions = filterPaymentTypeOptions(w.paymentTypeOptions, w.transactionType);
            }
            
            List<OPP_PremiumSchedule__c> schedules = isPlacement
                ? [
                      SELECT Id, PaymentType__c, TotalInstalls__c, SlipGrossPrem__c
                      FROM OPP_PremiumSchedule__c
                      WHERE Placement_lk__c = :placementId AND Prem_Currency__c = :curr AND Type__c != 'Slip'
                      ORDER BY CreatedDate ASC
                  ]
                : [
                      SELECT Id, PaymentType__c, TotalInstalls__c, SlipGrossPrem__c
                      FROM OPP_PremiumSchedule__c
                      WHERE Opportunity_lk__c = :oppId AND Prem_Currency__c = :curr AND Type__c != 'Slip'
                      ORDER BY CreatedDate ASC
                  ];
            
            AggregateResult[] tsiResults = isPlacement
                ? [
                      SELECT SUM(GrossPrem_fm__c) total
                      FROM OPP_TSIByLocation__c
                      WHERE SlipInfo_md__r.Placement_lk__c = :placementId AND PremiumCurrency__c = :curr AND Type__c = 'TSIByLocation' AND SlipInfo_md__r.Latest_is__c = TRUE
                  ]
                : [
                      SELECT SUM(GrossPrem_fm__c) total
                      FROM OPP_TSIByLocation__c
                      WHERE SlipInfo_md__r.Opportunity_lk__c = :oppId AND PremiumCurrency__c = :curr AND Type__c = 'TSIByLocation' AND SlipInfo_md__r.Latest_is__c = TRUE
                  ];
            
            if (!tsiResults.isEmpty() && tsiResults[0].get('total') != null) {
                w.tsiGrossPremSum = (Decimal) tsiResults[0].get('total');
            }
            
            if (!schedules.isEmpty()) {
                w.paymentType = schedules[0].PaymentType__c;
                w.totalInstalls = schedules[0].PaymentType__c == 'Install' ? schedules.size() : null;
                w.grossPrem = schedules[0].SlipGrossPrem__c;
            } else {
                w.paymentType = oppPaymentType;
            }
            
            // 통화 구분 없이 하위에 SOA 레코드가 1건이라도 있으면 SOA 옵션만 표시
            Boolean hasSoaSchedule = isPlacement
                ? ![SELECT Id FROM OPP_PremiumSchedule__c WHERE Placement_lk__c = :placementId AND PaymentType__c = 'SOA' AND Type__c != 'Slip' LIMIT 1].isEmpty()
                : ![SELECT Id FROM OPP_PremiumSchedule__c WHERE Opportunity_lk__c = :oppId AND PaymentType__c = 'SOA' AND Type__c != 'Slip' LIMIT 1].isEmpty();
            
            if (hasSoaSchedule) {
                w.paymentTypeOptions = filterPaymentTypeOptions(w.paymentTypeOptions, 'Declaration');
            }
            
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading init data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Payment Type 및 Gross Premium 정보를 저장한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @param curr Premium Currency 값
     * @param paymentType Payment Type 값
     * @param grossPrem Gross Premium 값
     * @param hasCIDetail CI Detail 조건 충족 여부 (프론트엔드에서 전달)
     * @return String 저장 성공 메시지
     */
    @AuraEnabled
    public static String updatePaymentInfo(Id recordId, String curr, String paymentType, Decimal grossPrem, Boolean hasCIDetail) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required.');
            }
            
            System.debug('curr ' + curr + ' paymentType ' + paymentType);
            
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            
            Id oppId = recordId;
            Id placementId;
            String transactionType;
            
            String cedingType;
            
            if (isPlacement) {
                Placement__c placement = [
                    SELECT Opportunity_lk__c, TransactionType__c, CedingType1__c
                    FROM Placement__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                oppId = placement.Opportunity_lk__c;
                placementId = recordId;
                transactionType = placement.TransactionType__c;
                cedingType = placement.CedingType1__c;
            } else {
                if (!COM_MetaUtil.checkEditPermission(recordId)) {
                    throw new AuraHandledException('You do not have permission to edit this record');
                }
                Opportunity opp = [SELECT TransactionType__c, CedingType1__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
                transactionType = opp.TransactionType__c;
                cedingType = opp.CedingType1__c;
            }
            
            Boolean isTreaty = 'Treaty'.equals(cedingType);
            Boolean isTreatyOrCIDetail = isTreaty || Boolean.valueOf(hasCIDetail);
            
            // Declaration 타입인 경우, 저장 전 기존 GrossPrem 값과 비교하여 변경 시 NeedRecalculate_is__c = true 설정
            if (transactionType == 'Declaration') {
                List<OPP_PremiumSchedule__c> existingSchedules = isPlacement
                    ? [SELECT SlipGrossPrem__c FROM OPP_PremiumSchedule__c WHERE Placement_lk__c = :placementId AND Prem_Currency__c = :curr LIMIT 1]
                    : [SELECT SlipGrossPrem__c FROM OPP_PremiumSchedule__c WHERE Opportunity_lk__c = :oppId AND Prem_Currency__c = :curr LIMIT 1];
                Decimal existingGrossPrem = existingSchedules.isEmpty() ? null : existingSchedules[0].SlipGrossPrem__c;
                
                if (existingGrossPrem != grossPrem) {
                    update new Opportunity(Id = oppId, NeedRecalculate_is__c = true);
                }
            }
            
            if (paymentType == 'SOA') {
                // SOA: Prem_Currency__c 구분 없이 하위 전체 레코드 처리 (통화별 1건 유지, 나머지 삭제)
                ensureSOAPremiumScheduleAllCurrencies(oppId, placementId, isPlacement, curr, grossPrem, transactionType);
            } else if (paymentType == 'Single') {
                ensureSinglePremiumSchedule(oppId, placementId, isPlacement, curr, paymentType, grossPrem, transactionType);
            } else if (paymentType == 'Install' && isTreatyOrCIDetail) {
                // Treaty + Install: 기존 Install 스케줄 레코드 전체의 SlipGrossPrem__c 업데이트
                updateInstallSchedulesGrossPrem(oppId, placementId, isPlacement, curr, grossPrem);
            }
            
            if (transactionType == 'Declaration') {
                updatePanelGrossPrem(oppId, placementId, isPlacement, curr, grossPrem);
            }
            
            return Label.OPP_MSG_PAYMENT_SAVE_SUCCESS;
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating payment information: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error updating payment information: ' + e.getMessage());
        }
    }
    
    /**
     * @description SOA 변경 시 영향받는 Premium Schedule 레코드를 미리 조회한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @param curr 미사용 통화 값
     * @return SOAChangePreviewWrapper 변경 미리보기 데이터
     */
    @AuraEnabled
    public static SOAChangePreviewWrapper getSOAChangePreview(Id recordId, String curr) {
        try {
            SOAChangePreviewWrapper w = new SOAChangePreviewWrapper();
            
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required.');
            }
            
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            
            Id oppId = recordId;
            Id placementId;
            
            if (isPlacement) {
                Placement__c placement = [
                    SELECT Opportunity_lk__c
                    FROM Placement__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                oppId = placement.Opportunity_lk__c;
                placementId = recordId;
            }
            
            // Prem_Currency__c 구분 없이 전체 조회, 통화 → CreatedDate 순 정렬
            List<OPP_PremiumSchedule__c> allSchedules = isPlacement
                ? [
                      SELECT Id, PaymentType__c, Type__c, DaysFromInception__c, Percentage__c, InstallDate_fm__c, Prem_Currency__c
                      FROM OPP_PremiumSchedule__c
                      WHERE Placement_lk__c = :placementId AND Type__c != 'Slip'
                      ORDER BY Prem_Currency__c ASC, CreatedDate ASC
                  ]
                : [
                      SELECT Id, PaymentType__c, Type__c, DaysFromInception__c, Percentage__c, InstallDate_fm__c, Prem_Currency__c
                      FROM OPP_PremiumSchedule__c
                      WHERE Opportunity_lk__c = :oppId AND Type__c != 'Slip'
                      ORDER BY Prem_Currency__c ASC, CreatedDate ASC
                  ];
            
            // 통화별 첫 번째 → toUpdate(이미 SOA인 레코드는 제외), 나머지 → toDelete
            Set<String> seenCurrencies = new Set<String>();
            for (OPP_PremiumSchedule__c s : allSchedules) {
                String key = s.Prem_Currency__c == null ? '' : s.Prem_Currency__c;
                if (!seenCurrencies.contains(key)) {
                    seenCurrencies.add(key);
                    // 이미 SOA인 레코드는 변경 대상에서 제외 (모달에 표시하지 않음)
                    if (!'SOA'.equals(s.PaymentType__c)) {
                        w.toUpdate.add(s);
                    }
                } else {
                    w.toDelete.add(s);
                }
            }
            
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting SOA change preview: ' + e.getMessage());
        }
    }
    
    /**
     * @description SOA 타입 저장 시 Premium Schedule 레코드를 통화 기준으로 정리한다.
     * @param oppId Opportunity Id
     * @param placementId Placement__c Id
     * @param isPlacement Placement 여부
     * @param targetCurr 저장 대상 통화 값
     * @param grossPrem Gross Premium 값
     * @param transactionType Transaction Type 값
     * @return 없음
     */
    private static void ensureSOAPremiumScheduleAllCurrencies(Id oppId, Id placementId, Boolean isPlacement, String targetCurr, Decimal grossPrem, String transactionType) {
        try {
            Boolean isDeclaration = transactionType == 'Declaration';
            System.debug('[ensureSOAAllCurr] START - oppId=' + oppId + ', placementId=' + placementId + ', isPlacement=' + isPlacement + ', targetCurr=' + targetCurr + ', grossPrem=' + grossPrem + ', transactionType=' + transactionType);
            
            List<OPP_PremiumSchedule__c> allSchedules = isPlacement
                ? [SELECT Id, Prem_Currency__c, SlipGrossPrem__c FROM OPP_PremiumSchedule__c WHERE Placement_lk__c = :placementId AND Type__c != 'Slip' ORDER BY Prem_Currency__c ASC, CreatedDate ASC]
                : [SELECT Id, Prem_Currency__c, SlipGrossPrem__c FROM OPP_PremiumSchedule__c WHERE Opportunity_lk__c = :oppId AND Type__c != 'Slip' ORDER BY Prem_Currency__c ASC, CreatedDate ASC];
            System.debug('[ensureSOAAllCurr] allSchedules.size()=' + allSchedules.size());
            
            if (allSchedules.isEmpty()) {
                // 레코드 없을 때 현재 통화 기준 1건 신규 생성
                OPP_PremiumSchedule__c newS = isPlacement
                    ? new OPP_PremiumSchedule__c(Placement_lk__c = placementId, Opportunity_lk__c = oppId, Prem_Currency__c = targetCurr)
                    : new OPP_PremiumSchedule__c(Opportunity_lk__c = oppId, Prem_Currency__c = targetCurr);
                applyScheduleValues(newS, 'SOA', grossPrem, isDeclaration);
                System.debug('[ensureSOAAllCurr] No existing records - inserting new SOA schedule for curr=' + targetCurr);
                insert newS;
                System.debug('[ensureSOAAllCurr] Inserted new schedule Id=' + newS.Id);
                return;
            }
            
            // 통화별로 첫 번째 레코드 → update(SOA), 나머지 → delete
            Map<String, OPP_PremiumSchedule__c> firstByCurrency = new Map<String, OPP_PremiumSchedule__c>();
            List<OPP_PremiumSchedule__c> toDelete = new List<OPP_PremiumSchedule__c>();
            
            for (OPP_PremiumSchedule__c s : allSchedules) {
                String key = s.Prem_Currency__c == null ? '' : s.Prem_Currency__c;
                if (!firstByCurrency.containsKey(key)) {
                    firstByCurrency.put(key, s);
                } else {
                    toDelete.add(s);
                }
            }
            System.debug('[ensureSOAAllCurr] firstByCurrency.keySet()=' + firstByCurrency.keySet() + ', toDelete.size()=' + toDelete.size());
            
            // targetCurr 레코드가 없으면 신규 생성
            if (!firstByCurrency.containsKey(targetCurr)) {
                OPP_PremiumSchedule__c newS = isPlacement
                    ? new OPP_PremiumSchedule__c(Placement_lk__c = placementId, Opportunity_lk__c = oppId, Prem_Currency__c = targetCurr)
                    : new OPP_PremiumSchedule__c(Opportunity_lk__c = oppId, Prem_Currency__c = targetCurr);
                applyScheduleValues(newS, 'SOA', grossPrem, isDeclaration);
                System.debug('[ensureSOAAllCurr] targetCurr=' + targetCurr + ' not found - inserting new SOA schedule');
                insert newS;
                System.debug('[ensureSOAAllCurr] Inserted new schedule Id=' + newS.Id);
            }
            
            List<OPP_PremiumSchedule__c> toUpdate = new List<OPP_PremiumSchedule__c>();
            for (OPP_PremiumSchedule__c s : firstByCurrency.values()) {
                // 현재 저장 중인 통화만 grossPrem 업데이트, 나머지 통화는 기존 값 유지
                Decimal applyGrossPrem = (s.Prem_Currency__c == targetCurr) ? grossPrem : s.SlipGrossPrem__c;
                System.debug('[ensureSOAAllCurr] schedule Id=' + s.Id + ', curr=' + s.Prem_Currency__c + ', applyGrossPrem=' + applyGrossPrem);
                applyScheduleValues(s, 'SOA', applyGrossPrem, isDeclaration);
                toUpdate.add(s);
            }
            
            if (!toUpdate.isEmpty()) update toUpdate;
            if (!toDelete.isEmpty()) delete toDelete;
            System.debug('[ensureSOAAllCurr] DONE - inserted=' + (!firstByCurrency.containsKey(targetCurr) ? 1 : 0) + ', updated=' + toUpdate.size() + ', deleted=' + toDelete.size());
        } catch (Exception e) {
            System.debug('[ensureSOAAllCurr] ERROR - ' + e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException('Error ensuring SOA premium schedule for all currencies: ' + e.getMessage());
        }
    }
    
    /**
     * @description Single 타입 저장 시 동일 통화 기준 Premium Schedule 1건만 유지하도록 처리한다.
     * @param oppId Opportunity Id
     * @param placementId Placement__c Id
     * @param isPlacement Placement 여부
     * @param curr 저장 대상 통화 값
     * @param paymentType Payment Type 값
     * @param grossPrem Gross Premium 값
     * @param transactionType Transaction Type 값
     * @return 없음
     */
    private static void ensureSinglePremiumSchedule(Id oppId, Id placementId, Boolean isPlacement, String curr, String paymentType, Decimal grossPrem, String transactionType) {
        try {
            Boolean isDeclaration = transactionType == 'Declaration';
            
            List<OPP_PremiumSchedule__c> schedules = isPlacement
                ? [SELECT Id FROM OPP_PremiumSchedule__c WHERE Placement_lk__c = :placementId AND Prem_Currency__c = :curr AND Type__c != 'Slip' ORDER BY CreatedDate ASC]
                : [SELECT Id FROM OPP_PremiumSchedule__c WHERE Opportunity_lk__c = :oppId AND Prem_Currency__c = :curr AND Type__c != 'Slip' ORDER BY CreatedDate ASC];
            
            if (schedules.isEmpty()) {
                OPP_PremiumSchedule__c s = isPlacement
                    ? new OPP_PremiumSchedule__c(Placement_lk__c = placementId, Opportunity_lk__c = oppId, Prem_Currency__c = curr)
                    : new OPP_PremiumSchedule__c(Opportunity_lk__c = oppId, Prem_Currency__c = curr);
                applyScheduleValues(s, paymentType, grossPrem, isDeclaration);
                insert s;
            } else {
                applyScheduleValues(schedules[0], paymentType, grossPrem, isDeclaration);
                update schedules[0];
                
                if (schedules.size() > 1) {
                    List<OPP_PremiumSchedule__c> toDelete = new List<OPP_PremiumSchedule__c>();
                    for (Integer i = 1; i < schedules.size(); i++) {
                        toDelete.add(schedules[i]);
                    }
                    delete toDelete;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error ensuring single premium schedule: ' + e.getMessage());
        }
    }
    
    /**
     * @description Premium Schedule 공통 저장값을 설정한다.
     * @param s 저장 대상 Premium Schedule 레코드
     * @param paymentType Payment Type 값
     * @param grossPrem Gross Premium 값
     * @param isDeclaration Declaration 여부
     * @return 없음
     */
    private static void applyScheduleValues(OPP_PremiumSchedule__c s, String paymentType, Decimal grossPrem, Boolean isDeclaration) {
        s.PaymentType__c = paymentType;
        s.SlipGrossPrem__c = grossPrem;
        s.DaysFromInception__c = null;
        s.Percentage__c = null;
        s.Type__c = isDeclaration ? 'Declaration' : 'Schedule';
    }
    
    /**
     * @description Treaty + Install 타입 저장 시 해당 통화의 모든 Install 스케줄 레코드에 SlipGrossPrem__c를 갱신한다.
     * @param oppId Opportunity Id
     * @param placementId Placement__c Id
     * @param isPlacement Placement 여부
     * @param curr 저장 대상 통화 값
     * @param grossPrem Gross Premium 값
     * @return 없음
     */
    private static void updateInstallSchedulesGrossPrem(Id oppId, Id placementId, Boolean isPlacement, String curr, Decimal grossPrem) {
        List<OPP_PremiumSchedule__c> schedules = isPlacement
            ? [SELECT Id FROM OPP_PremiumSchedule__c WHERE Placement_lk__c = :placementId AND Prem_Currency__c = :curr AND Type__c != 'Slip']
            : [SELECT Id FROM OPP_PremiumSchedule__c WHERE Opportunity_lk__c = :oppId AND Prem_Currency__c = :curr AND Type__c != 'Slip'];
        
        for (OPP_PremiumSchedule__c s : schedules) {
            s.SlipGrossPrem__c = grossPrem;
        }
        
        if (!schedules.isEmpty()) {
            update schedules;
        }
    }
    
    /**
     * @description Declaration 타입 저장 시 동일 통화의 Panel Gross Premium 값을 일괄 갱신한다.
     * @param oppId Opportunity Id
     * @param placementId Placement__c Id
     * @param isPlacement Placement 여부
     * @param curr 저장 대상 통화 값
     * @param grossPrem Gross Premium 값
     * @return 없음
     */
    private static void updatePanelGrossPrem(Id oppId, Id placementId, Boolean isPlacement, String curr, Decimal grossPrem) {
        if (grossPrem == null) {
            return;
        }
        
        List<OPP_Panel__c> panels = isPlacement
            ? [SELECT Id FROM OPP_Panel__c WHERE Layer_md__r.Placement_lk__c = :placementId AND Currency__c = :curr]
            : [SELECT Id FROM OPP_Panel__c WHERE Layer_md__r.Opportunity_md__c = :oppId AND Currency__c = :curr];
        
        for (OPP_Panel__c p : panels) {
            p.GrossPrem__c = grossPrem;
        }
        
        if (!panels.isEmpty()) {
            update panels;
        }
        
        System.debug('Updated GrossPrem__c for ' + panels.size() + ' panels with currency: ' + curr);
    }
    
    /**
     * @description Transaction Type에 따라 Payment Type 옵션을 필터링한다.
     * @param options 전체 Payment Type 옵션 목록
     * @param transactionType Transaction Type 값
     * @return List<COM_Option> 필터링된 Payment Type 옵션 목록
     */
    private static List<COM_Option> filterPaymentTypeOptions(List<COM_Option> options, String transactionType) {
        if (options == null || options.isEmpty()) {
            return options;
        }
        
        List<COM_Option> result = new List<COM_Option>();
        
        if ('Declaration'.equals(transactionType)) {
            for (COM_Option opt : options) {
                if ('SOA'.equals(opt.value)) {
                    result.add(opt);
                }
            }
        } else if ('END'.equals(transactionType)) {
            for (COM_Option opt : options) {
                if (!'SOA'.equals(opt.value)) {
                    result.add(opt);
                }
            }
        } else {
            return options;
        }
        
        return result;
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description 초기 화면 로딩 데이터를 전달하는 Wrapper 클래스
     */
    public class InitDataWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public List<COM_Option> paymentTypeOptions { get; set; }
        @AuraEnabled
        public String paymentType { get; set; }
        @AuraEnabled
        public Integer totalInstalls { get; set; }
        @AuraEnabled
        public Boolean isClosed { get; set; }
        @AuraEnabled
        public Decimal grossPrem { get; set; }
        @AuraEnabled
        public Decimal tsiGrossPremSum { get; set; }
        @AuraEnabled
        public String transactionType { get; set; }
        @AuraEnabled
        public String cedingType{ get; set; }
        @AuraEnabled
        public Boolean isPlacement { get; set; }
        @AuraEnabled
        public Boolean hasEditPermission { get; set; }
        
        // ============================================================
        // Methods
        // ============================================================
        
        /**
         * @description InitDataWrapper 기본값을 초기화한다.
         * @param 없음
         * @return 없음
         */
        public InitDataWrapper() {
            paymentTypeOptions = new List<COM_Option>();
            isClosed = false;
            isPlacement = false;
            hasEditPermission = false;
        }
    }
    
    /**
     * @description SOA 변경 미리보기 결과를 전달하는 Wrapper 클래스
     */
    public class SOAChangePreviewWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public List<OPP_PremiumSchedule__c> toUpdate { get; set; }
        @AuraEnabled
        public List<OPP_PremiumSchedule__c> toDelete { get; set; }
        
        // ============================================================
        // Methods
        // ============================================================
        
        /**
         * @description SOAChangePreviewWrapper 기본값을 초기화한다.
         * @param 없음
         * @return 없음
         */
        public SOAChangePreviewWrapper() {
            toUpdate = new List<OPP_PremiumSchedule__c>();
            toDelete = new List<OPP_PremiumSchedule__c>();
        }
    }
}