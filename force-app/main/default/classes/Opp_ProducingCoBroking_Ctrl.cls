/**********************************************************************************
 * @filename      : Opp_ProducingCoBroking_Ctrl.cls
 * @project-name  : LK_DEV2
 * @author        : i2max
 * @date          : 2025-12-16
 * @group         :
 * @group-content :
 * @description   : Producing Co-Broking 데이터 조회 및 저장을 처리하는 컨트롤러
 * @test-class    : Opp_ProducingCoBroking_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-16      i2max            Create
 **********************************************************************************/
public with sharing class Opp_ProducingCoBroking_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description 초기 화면 로딩에 필요한 Producing Co-Broking 데이터를 조회한다.
     * @param recordId Opportunity, Placement__c 또는 Claim 레코드 Id
     * @return InitDataWrapper 초기 화면 구성 데이터
     */
    @AuraEnabled(Cacheable=true)
    public static InitDataWrapper getInitData(Id recordId) {
        System.debug('getInitData recordId=[' + recordId + ']');
        
        try {
            InitDataWrapper w = new InitDataWrapper();
            
            if (String.isBlank(recordId))
                return w;
            
            Id placementId;
            String sObjectName = COM_MetaUtil.getObjectNameById(recordId);
            w.isPlacement = 'Placement__c'.equalsIgnoreCase(sObjectName);
            w.isClaim = 'Claim'.equalsIgnoreCase(sObjectName);
            
            System.debug('[getInitData] sObjectName=[' + sObjectName + '], isPlacement=[' + w.isPlacement + '], isClaim=[' + w.isClaim + ']');
            
            if (w.isClaim) {
                Claim claim = [SELECT Placement_lk__c FROM Claim WHERE Id = :recordId];
                placementId = claim.Placement_lk__c;
            }
            
            if (w.isPlacement || w.isClaim) {
                if (w.isPlacement)
                    placementId = recordId;
                
                // Placement의 PlacementClosingDate__c, BizRegion__c 조회
                if (placementId != null) {
                    Placement__c placement = [SELECT PlacementClosingDate__c, BizRegion__c FROM Placement__c WHERE Id = :placementId];
                    w.placementClosingDate = placement.PlacementClosingDate__c;
                    w.bizRegion = placement.BizRegion__c;
                }
                
                // Placement / Claim 컨텍스트: Placement_lk__c 기준 조회
                w.coBrokerList = [
                    SELECT
                        Id,
                        Name,
                        CobrokerName_lk__c,
                        CobrokerName_lk__r.Name,
                        CobrokerContact_lk__c,
                        CobrokerContact_lk__r.Name,
                        SharingPct__c,
                        LKAdminFeePct__c,
                        SettlementType__c,
                        Client__c,
                        Opportunity_md__c
                    FROM OPP_Cobroker__c
                    WHERE Placement_lk__c = :placementId AND LKCobroking_is__c = FALSE AND CobrokingType__c = 'Producing' AND Placement_lk__c != NULL
                    ORDER BY CreatedDate
                ];
                
                List<OPP_Cobroker__c> existingLK = [
                    SELECT Id, Name, CobrokerUser_lk__r.Name, CobrokingType__c, SharingPct__c, SettlementType__c, Client__c, LKAdminFeePct__c, LKCobroking_is__c
                    FROM OPP_Cobroker__c
                    WHERE Placement_lk__c = :placementId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = TRUE
                ];
                w.hasExisting = !existingLK.isEmpty();
                w.existingRecords = existingLK;
            } else {
                // Opportunity 컨텍스트: BizRegion__c 조회
                Opportunity opp = [SELECT BizRegion__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
                w.bizRegion = opp.BizRegion__c;
                
                w.coBrokerList = [
                    SELECT
                        Id,
                        Name,
                        CobrokerName_lk__c,
                        CobrokerName_lk__r.Name,
                        CobrokerContact_lk__c,
                        CobrokerContact_lk__r.Name,
                        SharingPct__c,
                        LKAdminFeePct__c,
                        SettlementType__c,
                        Client__c,
                        Opportunity_md__c
                    FROM OPP_Cobroker__c
                    WHERE Opportunity_md__c = :recordId AND LKCobroking_is__c = FALSE AND Placement_lk__c = NULL
                    ORDER BY CreatedDate
                ];
                
                List<OPP_Cobroker__c> existingLK = [
                    SELECT Id, Name, CobrokerUser_lk__r.Name, CobrokingType__c, SharingPct__c, SettlementType__c, Client__c, LKAdminFeePct__c, LKCobroking_is__c
                    FROM OPP_Cobroker__c
                    WHERE Opportunity_md__c = :recordId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = TRUE AND Placement_lk__c = NULL
                ];
                w.hasExisting = !existingLK.isEmpty();
                w.existingRecords = existingLK;
            }
            
            w.settlementTypeOptions = COM_Util.makePickListOptions('OPP_Cobroker__c', 'SettlementType__c', false, false);
            w.hasEditPermission = w.isClaim ? false : COM_MetaUtil.checkEditPermission(recordId);
            
            System.debug('[getInitData] hasEditPermission=[' + w.hasEditPermission + '], coBrokerList.size=[' + w.coBrokerList.size() + ']');
            
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading initial data: ' + e.getMessage());
        }
    }
    
    /**
     * @description 기존 LK Co-Broking 레코드를 삭제한 뒤 새 레코드로 교체 저장한다.
     * @param coBrokers 저장할 Co-Broker 레코드 목록
     * @param oppId Opportunity 컨텍스트의 Opportunity Id
     * @param placementId Placement 컨텍스트의 Placement__c Id
     * @param needsRecalculate 재계산 필요 여부
     * @return 없음
     */
    @AuraEnabled
    public static void saveWithReplace(List<OPP_Cobroker__c> coBrokers, Id oppId, Id placementId, Boolean needsRecalculate) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (coBrokers == null || coBrokers.isEmpty()) {
                throw new AuraHandledException(System.Label.IPL_MSG_ChangedError);
            }
            
            Boolean isPlacement = placementId != null;
            
            // 기존 LK Co-broking 레코드 삭제
            List<OPP_Cobroker__c> existingRecords = isPlacement
                ? [SELECT Id FROM OPP_Cobroker__c WHERE Placement_lk__c = :placementId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = TRUE]
                : [SELECT Id FROM OPP_Cobroker__c WHERE Opportunity_md__c = :oppId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = TRUE];
            if (!existingRecords.isEmpty())
                delete existingRecords;
            
            saveCoBrokers(coBrokers, oppId, placementId, needsRecalculate);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error replacing Co-Brokers: ' + e.getMessage());
        }
    }
    
    /**
     * @description Co-Broker 레코드를 저장하거나 수정한다.
     * @param coBrokers 저장할 Co-Broker 레코드 목록
     * @param oppId Opportunity 컨텍스트의 Opportunity Id
     * @param placementId Placement 컨텍스트의 Placement__c Id
     * @param needsRecalculate 재계산 필요 여부
     * @return 없음
     */
    @AuraEnabled
    public static void saveCoBrokers(List<OPP_Cobroker__c> coBrokers, Id oppId, Id placementId, Boolean needsRecalculate) {
        if (coBrokers == null || coBrokers.isEmpty()) {
            throw new AuraHandledException(System.Label.IPL_MSG_ChangedError);
        }
        
        Boolean isPlacement = placementId != null;
        
        if (isPlacement) {
            Placement__c placement = [SELECT Opportunity_lk__c FROM Placement__c WHERE Id = :placementId LIMIT 1];
            oppId = placement.Opportunity_lk__c;
        }
        
        List<OPP_Cobroker__c> recordsToUpsert = new List<OPP_Cobroker__c>();
        
        for (OPP_Cobroker__c cb : coBrokers) {
            OPP_Cobroker__c record = new OPP_Cobroker__c();
            
            if (cb.Id != null) {
                record.Id = cb.Id;
            } else if (isPlacement) {
                record.Placement_lk__c = placementId;
                record.Opportunity_md__c = oppId;
            } else {
                record.Opportunity_md__c = oppId;
            }
            
            record.CobrokerName_lk__c = cb.CobrokerName_lk__c;
            record.CobrokerContact_lk__c = cb.CobrokerContact_lk__c;
            record.SharingPct__c = cb.SharingPct__c == null ? 0 : cb.SharingPct__c;
            record.LKAdminFeePct__c = cb.LKAdminFeePct__c == null ? 0 : cb.LKAdminFeePct__c;
            record.SettlementType__c = cb.SettlementType__c;
            record.Client__c = cb.Client__c;
            record.LKCobroking_is__c = false;
            record.CobrokingType__c = 'Producing';
            
            recordsToUpsert.add(record);
        }
        
        try {
            upsert recordsToUpsert;
        } catch (DmlException e) {
            throw new AuraHandledException('Error saving Co-Brokers: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error saving Co-Brokers: ' + e.getMessage());
        }
        
        if (needsRecalculate == true && !isPlacement && oppId != null) {
            update new Opportunity(Id = oppId, NeedRecalculate_is__c = true);
        }
    }
    
    /**
     * @description 지정한 Co-Broker 레코드를 삭제한다.
     * @param coBrokerIds 삭제할 Co-Broker Id 목록
     * @param oppId Opportunity 컨텍스트의 Opportunity Id
     * @param placementId Placement 컨텍스트의 Placement__c Id
     * @return 없음
     */
    @AuraEnabled
    public static void deleteCoBrokers(List<Id> coBrokerIds, Id oppId, Id placementId) {
        if (coBrokerIds == null || coBrokerIds.isEmpty())
            return;
        
        try {
            delete [SELECT Id FROM OPP_Cobroker__c WHERE Id IN :coBrokerIds];
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting Co-Brokers: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting Co-Brokers: ' + e.getMessage());
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description Producing Co-Broking 초기 화면 구성 데이터를 전달하는 Wrapper 클래스
     */
    public class InitDataWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public List<OPP_Cobroker__c> coBrokerList { get; set; }
        @AuraEnabled
        public List<COM_Option> settlementTypeOptions { get; set; }
        @AuraEnabled
        public Boolean hasExisting { get; set; }
        @AuraEnabled
        public List<OPP_Cobroker__c> existingRecords { get; set; }
        @AuraEnabled
        public Boolean isPlacement { get; set; }
        @AuraEnabled
        public Boolean isClaim { get; set; }
        @AuraEnabled
        public Boolean hasEditPermission { get; set; }
        @AuraEnabled
        public Date placementClosingDate { get; set; }
        @AuraEnabled
        public String bizRegion { get; set; }
        
        // ============================================================
        // Methods
        // ============================================================
        
        /**
         * @description InitDataWrapper 기본값을 초기화한다.
         * @param 없음
         * @return 없음
         */
        public InitDataWrapper() {
            coBrokerList = new List<OPP_Cobroker__c>();
            settlementTypeOptions = new List<COM_Option>();
            hasExisting = false;
            existingRecords = new List<OPP_Cobroker__c>();
            isPlacement = false;
            isClaim = false;
            hasEditPermission = false;
            placementClosingDate = null;
            bizRegion = null;
        }
    }
}