/**********************************************************************************
 * @filename      : Opp_LkCoBroking_Ctrl.cls
 * @project-name  : LK_DEV2
 * @author        : i2max
 * @date          : 2025-12-23
 * @group         :
 * @group-content :
 * @description   : LK Co-Broking 데이터 조회, 저장 및 충돌 처리를 담당하는 컨트롤러
 * @test-class    : Opp_LkCoBroking_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-23      i2max            Create
 **********************************************************************************/
public with sharing class Opp_LkCoBroking_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description 초기 화면 로딩에 필요한 LK Co-Broking 데이터를 조회한다.
     * @param recordId Opportunity, Placement__c 또는 Claim 레코드 Id
     * @return InitDataWrapper 초기 화면 데이터
     */
    @AuraEnabled(Cacheable=true)
    public static InitDataWrapper getInitData(Id recordId) {
        try {
            InitDataWrapper w = new InitDataWrapper();
            
            if (String.isBlank(recordId))
                return w;
            
            Id placementId;
            String sObjectName = COM_MetaUtil.getObjectNameById(recordId);
            w.isPlacement = 'Placement__c'.equalsIgnoreCase(sObjectName);
            w.isClaim = 'Claim'.equalsIgnoreCase(sObjectName);
            
            if (w.isClaim) {
                Claim claim = [SELECT Placement_lk__c FROM Claim WHERE Id = :recordId];
                placementId = claim.Placement_lk__c;
            }
            
            if (w.isPlacement || w.isClaim) {
                if (w.isPlacement)
                    placementId = recordId;
                
                // Placement의 PlacementClosingDate__c 조회
                if (placementId != null) {
                    Placement__c placement = [SELECT PlacementClosingDate__c FROM Placement__c WHERE Id = :placementId];
                    w.placementClosingDate = placement.PlacementClosingDate__c;
                }
                
                // Placement / Claim 컨텍스트: Placement_lk__c 기준 조회 (readonly)
                w.coBrokerList = [
                    SELECT
                        Id,
                        Name,
                        CobrokingType__c,
                        LKCobroker_lk__c,
                        LKCobroker_lk__r.Name,
                        CobrokerUser_lk__c,
                        CobrokerUser_lk__r.Name,
                        SettlementType__c,
                        Client__c,
                        Sharing_is__c,
                        SharingPct__c,
                        Opportunity_md__c
                    FROM OPP_Cobroker__c
                    WHERE Placement_lk__c = :placementId AND LKCobroking_is__c = TRUE AND Placement_lk__c != NULL
                    ORDER BY CobrokingType__c, CreatedDate
                ];
            } else {
                // Opportunity 컨텍스트
                w.coBrokerList = [
                    SELECT
                        Id,
                        Name,
                        CobrokingType__c,
                        LKCobroker_lk__c,
                        LKCobroker_lk__r.Name,
                        CobrokerUser_lk__c,
                        CobrokerUser_lk__r.Name,
                        SettlementType__c,
                        Client__c,
                        Sharing_is__c,
                        SharingPct__c,
                        Opportunity_md__c
                    FROM OPP_Cobroker__c
                    WHERE Opportunity_md__c = :recordId AND LKCobroking_is__c = TRUE AND Placement_lk__c = NULL
                    ORDER BY CobrokingType__c, CreatedDate
                ];
                
                Integer count = [
                    SELECT COUNT()
                    FROM OPP_Cobroker__c
                    WHERE Opportunity_md__c = :recordId AND CobrokingType__c = 'Producing' AND SettlementType__c = 'Separate' AND Client__c = TRUE AND LKCobroking_is__c = FALSE
                    LIMIT 1
                ];
                w.producingDisabled = count > 0;
            }
            
            w.settlementTypeOptions = COM_Util.makePickListOptions('OPP_Cobroker__c', 'SettlementType__c', false);
            w.hasEditPermission = w.isClaim ? false : COM_MetaUtil.checkEditPermission(recordId);
            
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading init data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Account의 LKInternalRegion__c 값을 조회한다.
     * @param accountId Account Id
     * @return String LKInternalRegion__c 값
     */
    @AuraEnabled(Cacheable=true)
    public static String getAccountInternalRegion(Id accountId) {
        if (accountId == null) return null;
        List<Account> accounts = [
            SELECT LKInternalRegion__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0].LKInternalRegion__c;
    }
    
    /**
     * @description LK Co-Broker 레코드를 저장하거나 수정한다.
     * @param coBrokers 저장할 Co-Broker 레코드 목록
     * @param oppId Opportunity 컨텍스트의 Opportunity Id
     * @param placementId Placement 컨텍스트의 Placement__c Id
     * @param needsRecalculate 재계산 필요 여부
     * @return 없음
     */
    @AuraEnabled
    public static void saveCoBrokers(List<OPP_Cobroker__c> coBrokers, Id oppId, Id placementId, Boolean needsRecalculate) {
        if (coBrokers == null || coBrokers.isEmpty()) {
            throw new AuraHandledException('No Co-Broker records to save.');
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
            
            record.CobrokingType__c = cb.CobrokingType__c;
            record.LKCobroker_lk__c = cb.LKCobroker_lk__c;
            record.CobrokerUser_lk__c = cb.CobrokerUser_lk__c;
            record.SettlementType__c = cb.SettlementType__c;
            record.Client__c = cb.Client__c == null ? false : cb.Client__c;
            record.SharingPct__c = cb.SharingPct__c == null ? 0 : cb.SharingPct__c;
            record.Sharing_is__c = record.SharingPct__c > 0;
            record.LKCobroking_is__c = true;
            
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
     * @description 지정한 LK Co-Broker 레코드를 삭제한다.
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
            if (placementId != null) {
                delete [SELECT Id FROM OPP_Cobroker__c WHERE Id IN :coBrokerIds AND Placement_lk__c = :placementId AND LKCobroking_is__c = TRUE];
            } else {
                delete [SELECT Id FROM OPP_Cobroker__c WHERE Id IN :coBrokerIds AND Opportunity_md__c = :oppId AND LKCobroking_is__c = TRUE];
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting Co-Brokers: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting Co-Brokers: ' + e.getMessage());
        }
    }
    
    /**
     * @description 저장 전 Producing 및 Placing 충돌 데이터를 조회한다.
     * @param oppId Opportunity 컨텍스트의 Opportunity Id
     * @param placementId Placement 컨텍스트의 Placement__c Id
     * @param checkProducing Producing 충돌 체크 여부
     * @param checkPlacing Placing 충돌 체크 여부
     * @return ConflictCheckWrapper 충돌 조회 결과
     */
    @AuraEnabled
    public static ConflictCheckWrapper checkPreSaveConflicts(Id oppId, Id placementId, Boolean checkProducing, Boolean checkPlacing) {
        try {
            ConflictCheckWrapper w = new ConflictCheckWrapper();
            Boolean isPlacement = placementId != null;
            Id contextId = isPlacement ? placementId : oppId;
            if (String.isBlank(contextId))
                return w;
            
            checkProducing = (checkProducing == true);
            checkPlacing = (checkPlacing == true);
            
            if (checkProducing) {
                w.producingConflicts = isPlacement
                    ? [
                          SELECT Id, Name, CobrokerName_lk__c, CobrokerName_lk__r.Name, CobrokerContact_lk__c, CobrokerContact_lk__r.Name, SharingPct__c, LKAdminFeePct__c, SettlementType__c, Client__c
                          FROM OPP_Cobroker__c
                          WHERE Placement_lk__c = :placementId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = FALSE
                          ORDER BY CreatedDate
                      ]
                    : [
                          SELECT Id, Name, CobrokerName_lk__c, CobrokerName_lk__r.Name, CobrokerContact_lk__c, CobrokerContact_lk__r.Name, SharingPct__c, LKAdminFeePct__c, SettlementType__c, Client__c
                          FROM OPP_Cobroker__c
                          WHERE Opportunity_md__c = :oppId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = FALSE
                          ORDER BY CreatedDate
                      ];
                w.hasProducingConflicts = !w.producingConflicts.isEmpty();
            }
            
            if (checkPlacing) {
                w.placingPanelConflicts = isPlacement
                    ? [
                          SELECT Id, Name, CoBroker_lk__c, CoBroker_lk__r.Name, PlacingTPPAdminFeePct__c, PlacingSharingPct__c, PlacingSettlementType__c
                          FROM OPP_Panel__c
                          WHERE Layer_md__r.Placement_lk__c = :placementId AND CoBroker_lk__c != NULL
                          ORDER BY CreatedDate
                      ]
                    : [
                          SELECT Id, Name, CoBroker_lk__c, CoBroker_lk__r.Name, PlacingTPPAdminFeePct__c, PlacingSharingPct__c, PlacingSettlementType__c
                          FROM OPP_Panel__c
                          WHERE Layer_md__r.Opportunity_md__c = :oppId AND CoBroker_lk__c != NULL
                          ORDER BY CreatedDate
                      ];
                w.hasPlacingConflicts = !w.placingPanelConflicts.isEmpty();
            }
            
            w.hasAny = w.hasProducingConflicts || w.hasPlacingConflicts;
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error checking pre-save conflicts: ' + e.getMessage());
        }
    }
    
    /**
     * @description 저장 전 조회된 Producing 및 Placing 충돌 데이터를 처리한다.
     * @param oppId Opportunity 컨텍스트의 Opportunity Id
     * @param placementId Placement 컨텍스트의 Placement__c Id
     * @param resolveProducing Producing 충돌 해소 여부
     * @param resolvePlacing Placing 충돌 해소 여부
     * @return 없음
     */
    @AuraEnabled
    public static void resolvePreSaveConflicts(Id oppId, Id placementId, Boolean resolveProducing, Boolean resolvePlacing) {
        Boolean isPlacement = placementId != null;
        Savepoint sp = Database.setSavepoint();
        try {
            Id contextId = isPlacement ? placementId : oppId;
            if (String.isBlank(contextId))
                return;
            
            resolveProducing = (resolveProducing == true);
            resolvePlacing = (resolvePlacing == true);
            
            if (resolveProducing) {
                List<OPP_Cobroker__c> toDelete = isPlacement
                    ? [SELECT Id FROM OPP_Cobroker__c WHERE Placement_lk__c = :placementId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = FALSE]
                    : [SELECT Id FROM OPP_Cobroker__c WHERE Opportunity_md__c = :oppId AND CobrokingType__c = 'Producing' AND LKCobroking_is__c = FALSE];
                if (!toDelete.isEmpty())
                    delete toDelete;
            }
            
            if (resolvePlacing) {
                List<OPP_Panel__c> panels = isPlacement
                    ? [
                          SELECT Id, CoBroker_lk__c, PlacingTPPAdminFeePct__c, PlacingSharingPct__c, PlacingSettlementType__c
                          FROM OPP_Panel__c
                          WHERE Layer_md__r.Placement_lk__c = :placementId AND CoBroker_lk__c != NULL
                      ]
                    : [
                          SELECT Id, CoBroker_lk__c, PlacingTPPAdminFeePct__c, PlacingSharingPct__c, PlacingSettlementType__c
                          FROM OPP_Panel__c
                          WHERE Layer_md__r.Opportunity_md__c = :oppId AND CoBroker_lk__c != NULL
                      ];
                if (!panels.isEmpty()) {
                    for (OPP_Panel__c p : panels) {
                        p.CoBroker_lk__c = null;
                        p.PlacingTPPAdminFeePct__c = null;
                        p.PlacingSharingPct__c = null;
                        p.PlacingSettlementType__c = null;
                    }
                    update panels;
                }
            }
        } catch (DmlException e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error resolving conflicts: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error resolving conflicts: ' + e.getMessage());
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description LK Co-Broking 초기 화면 데이터를 전달하는 Wrapper 클래스
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
        public Boolean producingDisabled { get; set; }
        @AuraEnabled
        public Boolean isPlacement { get; set; }
        @AuraEnabled
        public Boolean isClaim { get; set; }
        @AuraEnabled
        public Boolean hasEditPermission { get; set; }
        @AuraEnabled
        public Date placementClosingDate { get; set; }
        
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
            producingDisabled = false;
            isPlacement = false;
            isClaim = false;
            hasEditPermission = false;
            placementClosingDate = null;
        }
    }
    
    /**
     * @description 저장 전 충돌 조회 결과를 전달하는 Wrapper 클래스
     */
    public class ConflictCheckWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public Boolean hasAny { get; set; }
        @AuraEnabled
        public Boolean hasProducingConflicts { get; set; }
        @AuraEnabled
        public Boolean hasPlacingConflicts { get; set; }
        @AuraEnabled
        public List<OPP_Cobroker__c> producingConflicts { get; set; }
        @AuraEnabled
        public List<OPP_Panel__c> placingPanelConflicts { get; set; }
        
        // ============================================================
        // Methods
        // ============================================================
        
        /**
         * @description ConflictCheckWrapper 기본값을 초기화한다.
         * @param 없음
         * @return 없음
         */
        public ConflictCheckWrapper() {
            hasAny = false;
            hasProducingConflicts = false;
            hasPlacingConflicts = false;
            producingConflicts = new List<OPP_Cobroker__c>();
            placingPanelConflicts = new List<OPP_Panel__c>();
        }
    }
}